import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/lecture_invitation_recue_supabase.dart';
import 'package:rewayah_academy/core/foyer/port_reponse_invitation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  late LectureInvitationRecueSupabase adaptateur;
  Object? reponse;
  String? chemin;
  String? corps;

  setUp(() async {
    reponse = <String, Object?>{
      'etat': 'a_repondre',
      'prenom_titulaire': 'Nour',
      'titulaire_feminin': true,
      'validation_requise': false,
      'duree_conservation': null,
    };
    chemin = null;
    corps = null;
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      chemin = requete.uri.path;
      corps = await utf8.decoder.bind(requete).join();
      requete.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reponse));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${serveur.address.address}:${serveur.port}',
      'cle-anon-fictive-de-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    adaptateur = LectureInvitationRecueSupabase(client);
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  test(
    'appelle la RPC sans identifiant et décode l invitation en attente',
    () async {
      final InvitationARepondre etat =
          await adaptateur.lireInvitationEnCours() as InvitationARepondre;

      expect(chemin, '/rest/v1/rpc/mon_invitation_en_cours');
      expect(corps, 'null');
      expect(etat.prenomTitulaire, 'Nour');
      expect(etat.titulaireFeminin, isTrue);
      expect(etat.validationRequise, isFalse);
      expect(etat.dureeConservation, isNull);
    },
  );

  test('mappe les états neutres et préserve la date serveur', () async {
    reponse = <String, Object?>{'etat': 'non_acceptable'};
    expect(
      await adaptateur.lireInvitationEnCours(),
      isA<InvitationNonAcceptable>(),
    );

    reponse = <String, Object?>{
      'etat': 'acceptee',
      'prenom_titulaire': 'Nour',
      'enregistree_le': '2026-10-10T20:00:00Z',
    };
    final InvitationAcceptee etat =
        await adaptateur.lireInvitationEnCours() as InvitationAcceptee;
    expect(etat.enregistreeLe?.toUtc(), DateTime.utc(2026, 10, 10, 20));
  });

  test('refuse une projection nulle, mal formée ou inconnue', () async {
    reponse = null;
    await expectLater(
      adaptateur.lireInvitationEnCours(),
      throwsFormatException,
    );

    reponse = <String, Object?>{'etat': 'a_repondre'};
    await expectLater(
      adaptateur.lireInvitationEnCours(),
      throwsFormatException,
    );

    reponse = <String, Object?>{'etat': 'autre'};
    await expectLater(
      adaptateur.lireInvitationEnCours(),
      throwsFormatException,
    );
  });
}
