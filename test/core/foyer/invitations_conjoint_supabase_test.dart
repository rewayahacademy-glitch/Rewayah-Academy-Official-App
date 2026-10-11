import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/invitations_conjoint_supabase.dart';
import 'package:rewayah_academy/core/foyer/port_invitation_conjoint.dart';
import 'package:rewayah_academy/core/foyer/port_reponse_invitation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  late InvitationsConjointSupabase adaptateur;
  Object? reponse;
  int statut = HttpStatus.ok;
  String? chemin;
  Map<String, dynamic>? corps;

  setUp(() async {
    reponse = <String, Object?>{'queued': true};
    statut = HttpStatus.ok;
    chemin = null;
    corps = null;
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      chemin = requete.uri.path;
      final String texte = await utf8.decoder.bind(requete).join();
      if (texte.isNotEmpty) {
        final Object? decode = jsonDecode(texte);
        corps = decode is Map<String, dynamic> ? decode : null;
      }
      requete.response
        ..statusCode = statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reponse));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${serveur.address.address}:${serveur.port}',
      'cle-anon-fictive-de-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    adaptateur = InvitationsConjointSupabase(client);
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  test('envoie seulement courriel et cle au RPC titulaire', () async {
    final ResultatInvitation resultat = await adaptateur.envoyer(
      const InvitationConjoint(
        prenom: 'Inutile pour la RPC actuelle',
        nom: '',
        courriel: ' invite@example.test ',
        cle: 'f3dce3be-1979-4d1e-91d3-0c658dd4c63b',
      ),
    );

    expect(chemin, '/rest/v1/rpc/inviter_conjoint');
    expect(corps, <String, dynamic>{
      'p_email': 'invite@example.test',
      'p_cle': 'f3dce3be-1979-4d1e-91d3-0c658dd4c63b',
    });
    expect(resultat, isA<InvitationPartie>());
  });

  test('ne révèle pas la raison si le serveur refuse l invitation', () async {
    reponse = <String, Object?>{
      'queued': false,
      'message': 'texte serveur privé',
    };

    final ResultatInvitation resultat = await adaptateur.envoyer(
      const InvitationConjoint(
        prenom: 'A',
        nom: 'B',
        courriel: 'autre@example.test',
        cle: 'une-cle',
      ),
    );

    expect(resultat, isA<InvitationRefusee>());
  });

  test('traduit un refus SQL en réponse neutre', () async {
    statut = HttpStatus.badRequest;
    reponse = <String, Object?>{
      'code': 'P0001',
      'message': 'invitation indisponible',
      'details': null,
      'hint': null,
    };

    final ResultatInvitation resultat = await adaptateur.envoyer(
      const InvitationConjoint(
        prenom: 'A',
        nom: 'B',
        courriel: 'a@example.test',
        cle: 'une-cle',
      ),
    );

    expect(resultat, isA<InvitationRefusee>());
  });

  test(
    'annule via RPC et ne prétend pas réussir si aucune ligne ne change',
    () async {
      reponse = true;
      expect(await adaptateur.annuler(), isA<AnnulationFaite>());
      expect(chemin, '/rest/v1/rpc/annuler_invitation_conjoint');
      expect(corps, isNull);

      reponse = false;
      expect(await adaptateur.annuler(), isA<AnnulationEchecReseau>());
    },
  );

  test(
    'accepte via RPC avec la clé idempotente et décode le reçu serveur',
    () async {
      reponse = <String, Object?>{
        'etat': 'acceptee',
        'prenom_titulaire': 'Amine',
        'enregistree_le': '2026-10-10T20:00:00Z',
      };

      final ResultatReponseInvitation resultat = await adaptateur.accepter(
        cle: '7c60962e-23af-4191-86a5-10b525f0f0ac',
      );

      expect(chemin, '/rest/v1/rpc/repondre_invitation_conjoint');
      expect(corps, <String, dynamic>{
        'p_decision': 'accepter',
        'p_cle': '7c60962e-23af-4191-86a5-10b525f0f0ac',
      });
      final InvitationAcceptee etat =
          (resultat as ReponseRecue).etat as InvitationAcceptee;
      expect(etat.prenomTitulaire, 'Amine');
      expect(etat.enregistreeLe?.toUtc(), DateTime.utc(2026, 10, 10, 20, 0));
    },
  );

  test('décode le refus et l état périmé sans inventer de date', () async {
    reponse = <String, Object?>{'etat': 'refusee', 'enregistree_le': null};
    final ReponseRecue refusee =
        await adaptateur.refuser(cle: 'cle-1') as ReponseRecue;
    expect(refusee.etat, isA<InvitationRefuseeParVous>());
    expect((refusee.etat as InvitationRefuseeParVous).enregistreeLe, isNull);

    reponse = <String, Object?>{'etat': 'perimee'};
    final ReponseRecue perimee =
        await adaptateur.accepter(cle: 'cle-2') as ReponseRecue;
    expect(perimee.etat, isA<InvitationPerimee>());
  });

  test('décode strictement l état en attente et ses champs publics', () async {
    reponse = <String, Object?>{
      'etat': 'a_repondre',
      'prenom_titulaire': 'Amine',
      'titulaire_feminin': false,
      'validation_requise': false,
      'duree_conservation': null,
    };

    final ReponseRecue resultat =
        await adaptateur.accepter(cle: 'cle') as ReponseRecue;
    final InvitationARepondre etat = resultat.etat as InvitationARepondre;
    expect(etat.prenomTitulaire, 'Amine');
    expect(etat.titulaireFeminin, isFalse);
    expect(etat.dureeConservation, isNull);
  });

  test('refuse une réponse RPC mal formée ou un état inconnu', () async {
    reponse = <String, Object?>{'etat': 'autre'};
    await expectLater(adaptateur.accepter(cle: 'cle'), throwsFormatException);

    reponse = <String, Object?>{
      'etat': 'a_repondre',
      'prenom_titulaire': 'Amine',
      'titulaire_feminin': false,
      'validation_requise': 'false',
    };
    await expectLater(adaptateur.accepter(cle: 'cle'), throwsFormatException);

    reponse = <String, Object?>{'queued': 'oui'};
    await expectLater(
      adaptateur.envoyer(
        const InvitationConjoint(
          prenom: 'A',
          nom: 'B',
          courriel: 'a@example.test',
          cle: 'cle',
        ),
      ),
      throwsFormatException,
    );
  });
}
