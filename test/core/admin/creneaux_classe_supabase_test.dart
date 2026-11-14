// HORLOGE-ET-LIEU (B2) : l'adaptateur reel des creneaux d'une classe, sur le
// chemin de production, avec le VRAI client Supabase contre un serveur HTTP
// local (comme `service_groupes_supabase_test.dart`).
//
// Les trois etats de l'installation :
// - serveur pas encore migre (la fonction « _fuseau » est absente, PGRST202) :
//   le client retombe sur l'ancienne fonction quand l'heure saisie est celle de
//   la classe ; sinon il refuse lui-meme (« pas encore disponible ») ;
// - serveur migre, ancienne fonction appelee (onglet pas recharge) : le serveur
//   refuse « RechargerPourModifierUnHoraire » ; le client le dit en motif ferme ;
// - serveur migre, application a jour : la fonction « _fuseau » part avec le
//   fuseau de l'heure saisie.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creneaux_classe.dart';
import 'package:rewayah_academy/core/admin/creneaux_classe_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

typedef _Requete = ({String chemin, Object? corps});
typedef _Reponse = ({int statut, Object? corps});

class _Faux {
  final List<_Requete> requetes = <_Requete>[];
  final List<_Reponse> reponses = <_Reponse>[];
  late HttpServer _http;
  late SupabaseClient client;

  Future<void> demarrer() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((HttpRequest r) async {
      final String brut = await utf8.decoder.bind(r).join();
      requetes.add((
        chemin: r.uri.path.replaceFirst('/rest/v1/', ''),
        corps: brut.isEmpty ? null : jsonDecode(brut),
      ));
      final _Reponse rep = reponses.isEmpty
          ? (statut: HttpStatus.ok, corps: 1)
          : reponses.removeAt(0);
      r.response
        ..statusCode = rep.statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(rep.corps));
      await r.response.close();
    });
    client = SupabaseClient(
      'http://${_http.address.address}:${_http.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  Future<void> arreter() async {
    await client.dispose();
    await _http.close(force: true);
  }

  void refuser(int statut, String code, String message) => reponses.add((
    statut: statut,
    corps: <String, Object?>{
      'code': code,
      'details': null,
      'hint': null,
      'message': message,
    },
  ));
}

void main() {
  late _Faux serveur;
  late CreneauxClasseSupabase service;

  setUp(() async {
    serveur = _Faux();
    await serveur.demarrer();
    service = CreneauxClasseSupabase(serveur.client);
  });
  tearDown(() => serveur.arreter());

  List<String> chemins() => serveur.requetes.map((r) => r.chemin).toList();

  Future<int> ajouter({String fuseau = 'Europe/Paris'}) => service.ajouter(
    groupeId: 'c1',
    jour: 2,
    heure: 17,
    fuseau: fuseau,
    fuseauClasse: 'Europe/Paris',
  );

  Future<int> deplacer({String fuseau = 'Europe/Paris'}) => service.modifier(
    groupeId: 'c1',
    ancien: (jour: 2, heure: 17, duree: null),
    nouveau: (jour: 3, heure: 18, duree: null),
    motif: 'deplacement',
    fuseau: fuseau,
    fuseauClasse: 'Europe/Paris',
  );

  group('application a jour, serveur migre', () {
    test(
      'ajouter : la fonction avec fuseau part avec le fuseau saisi',
      () async {
        await ajouter(fuseau: 'America/New_York');
        expect(chemins(), <String>['rpc/ajouter_creneau_classe_fuseau']);
        expect(
          (serveur.requetes.single.corps! as Map<String, Object?>)['p_fuseau'],
          'America/New_York',
        );
      },
    );

    test(
      'modifier : la fonction avec fuseau part avec le fuseau saisi',
      () async {
        await deplacer(fuseau: 'America/New_York');
        expect(chemins(), <String>['rpc/modifier_creneau_classe_fuseau']);
        expect(
          (serveur.requetes.single.corps! as Map<String, Object?>)['p_fuseau'],
          'America/New_York',
        );
      },
    );
  });

  group('application a jour, serveur pas encore migre (PGRST202)', () {
    void absente() => serveur.refuser(
      HttpStatus.notFound,
      'PGRST202',
      'Could not find the function public.x in the schema cache',
    );

    test(
      'ajouter, fuseau de la classe : l\'ancienne fonction fait juste',
      () async {
        absente();
        await ajouter();
        expect(chemins(), <String>[
          'rpc/ajouter_creneau_classe_fuseau',
          'rpc/ajouter_creneau_classe_admin',
        ]);
      },
    );

    test(
      'ajouter, autre fuseau : refus du client, rien d\'ancien n\'est appele',
      () async {
        absente();
        await expectLater(
          ajouter(fuseau: 'America/New_York'),
          throwsA(
            isA<CreneauRefuse>().having(
              (CreneauRefuse r) => r.motif,
              'motif',
              MotifRefusCreneau.conversionIndisponible,
            ),
          ),
        );
        expect(chemins(), <String>['rpc/ajouter_creneau_classe_fuseau']);
      },
    );

    test(
      'modifier, fuseau de la classe : l\'ancienne fonction fait juste',
      () async {
        absente();
        await deplacer();
        expect(chemins(), <String>[
          'rpc/modifier_creneau_classe_fuseau',
          'rpc/modifier_creneau_classe_admin',
        ]);
      },
    );

    test(
      'modifier, autre fuseau : refus du client, rien d\'ancien n\'est appele',
      () async {
        absente();
        await expectLater(
          deplacer(fuseau: 'America/New_York'),
          throwsA(
            isA<CreneauRefuse>().having(
              (CreneauRefuse r) => r.motif,
              'motif',
              MotifRefusCreneau.conversionIndisponible,
            ),
          ),
        );
        expect(chemins(), <String>['rpc/modifier_creneau_classe_fuseau']);
      },
    );
  });

  group('ancienne fonction appelee sur un serveur migre', () {
    test('« RechargerPourModifierUnHoraire » devient un motif ferme', () async {
      serveur.refuser(
        HttpStatus.badRequest,
        'P0001',
        'RechargerPourModifierUnHoraire',
      );
      await expectLater(
        service.ajouter(groupeId: 'c1', jour: 2, heure: 17),
        throwsA(
          isA<CreneauRefuse>().having(
            (CreneauRefuse r) => r.motif,
            'motif',
            MotifRefusCreneau.rechargerApplication,
          ),
        ),
      );
    });
  });
}
