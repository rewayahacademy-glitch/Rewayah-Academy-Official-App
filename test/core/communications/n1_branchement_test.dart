// N1 (02/11/2026) : les trois adaptateurs branches dans `main.dart`
// (capacites Communications, regles de portee, alertes de la direction).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/alertes_supabase.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/capacites_communication_supabase.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/port_regles_audience.dart';
import 'package:rewayah_academy/features/com_annonces/regles_audience_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un appel RPC qui rend [reponse] (ou leve si c'est une erreur) et note la
/// fonction appelee.
AppelRpc _appel(Object? reponse, List<String> appels) =>
    (String fonction, Map<String, dynamic> _) async {
      appels.add(fonction);
      if (reponse is Exception) throw reponse;
      return reponse;
    };

void main() {
  group('Capacites Communications (com_mes_capacites)', () {
    test('ouvre exactement les capacites rendues vraies', () async {
      final List<String> appels = <String>[];
      final CapacitesCommunication c = await CapacitesCommunicationsSupabase(
        _appel(<String, dynamic>{
          'publier_annonce': true,
          'programmer': false,
          'ecrire_dans_fil': true,
          'envoyer_vocal': false,
        }, appels),
      ).capacites();
      expect(appels, <String>['com_mes_capacites']);
      expect(c.capacites, <CapaciteCommunication>{
        CapaciteCommunication.publierAnnonce,
        CapaciteCommunication.ecrireDansFil,
      });
    });

    test('une valeur qui n est pas true laisse fermee', () {
      final CapacitesCommunication c = capacitesCommunicationJson(
        <String, dynamic>{'publier_annonce': 'true', 'programmer': 1},
      );
      expect(c, CapacitesCommunication.aucune);
    });

    test(
      'un refus du serveur donne l ensemble ferme, pas une erreur',
      () async {
        final ProviderContainer conteneur = ProviderContainer(
          overrides: <Override>[
            portCapacitesCommunicationsProvider.overrideWithValue(
              CapacitesCommunicationsSupabase(
                _appel(
                  const PostgrestException(message: 'refus', code: '42501'),
                  <String>[],
                ),
              ),
            ),
          ],
        );
        addTearDown(conteneur.dispose);
        expect(
          await conteneur.read(capacitesCommunicationProvider.future),
          CapacitesCommunication.aucune,
        );
      },
    );

    test('une panne reste une erreur', () async {
      final Future<CapacitesCommunication> lu = CapacitesCommunicationsSupabase(
        _appel(
          const PostgrestException(message: 'x', code: '57014'),
          <String>[],
        ),
      ).capacites();
      await expectLater(lu, throwsA(isA<PostgrestException>()));
    });
  });

  group('Regles de portee (com_regles_audience)', () {
    test('redige chaque ligne depuis ses codes', () async {
      final ReglesAudience r = await ReglesAudienceSupabase(
        _appel(<Object?>[
          <String, dynamic>{
            'id': 'direction',
            'auteurs': 'direction',
            'peut_publier': true,
            'portee': 'toute_audience',
          },
          <String, dynamic>{
            'id': 'familles',
            'auteurs': 'familles',
            'peut_publier': false,
            'portee': 'aucune',
          },
        ], <String>[]),
      ).regles();
      expect(r.demonstration, isFalse);
      expect(r.regles.map((RegleAudience l) => l.id), <String>[
        'direction',
        'familles',
      ]);
      expect(r.regles.first.auteurs, 'Direction');
      expect(
        r.regles.first.audiences,
        "Toute l'académie, un public ou une Classe",
      );
      expect(r.regles.last.peutPublier, isFalse);
      expect(r.regles.last.audiences, isEmpty);
    });

    test('un code inconnu est une erreur de format, jamais un libelle', () {
      expect(
        () => regleAudienceJson(<String, dynamic>{
          'id': 'x',
          'auteurs': 'inconnus',
          'peut_publier': true,
          'portee': 'aucune',
        }),
        throwsFormatException,
      );
    });

    test('un refus se lit comme indisponible', () async {
      await expectLater(
        ReglesAudienceSupabase(
          _appel(
            const PostgrestException(message: 'refus', code: '42501'),
            <String>[],
          ),
        ).regles(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('Alertes de la direction (signalements_ouverts_direction)', () {
    Map<String, dynamic> ligne({
      required String id,
      required String categorie,
      required bool prioritaire,
      required String le,
    }) => <String, dynamic>{
      'id': id,
      'categorie': categorie,
      'prioritaire': prioritaire,
      'academy_id': 'RA-26-4817',
      'internal_details': '  Une note  ',
      'statut': 'ouvert',
      'cree_le': le,
    };

    test(
      'securite d un enfant urgente, le reste important, titre redige',
      () async {
        final List<String> appels = <String>[];
        final List<Alerte> alertes = await AlertesSupabase(
          _appel(<Object?>[
            ligne(
              id: 'a',
              categorie: 'pedagogique',
              prioritaire: false,
              le: '2026-11-02T10:00:00Z',
            ),
            ligne(
              id: 'b',
              categorie: 'securite_enfant',
              prioritaire: true,
              le: '2026-11-02T09:00:00Z',
            ),
          ], appels),
        ).lire();
        expect(appels, <String>['signalements_ouverts_direction']);
        final List<Alerte> triees = trierAlertes(alertes);
        expect(triees.first.id, 'signalement-b');
        expect(triees.first.urgente, isTrue);
        expect(triees.last.gravite, GraviteAlerte.important);
        expect(
          triees.first.titre,
          "Sécurité d'un enfant : signalement pour l'élève RA-26-4817. "
          'Note interne : « Une note »',
        );
        expect(triees.first.destination, isNull);
        expect(triees.first.creeeLe, DateTime.utc(2026, 11, 2, 9));
      },
    );

    test(
      'la garde de la direction (P0001) se lit comme indisponible',
      () async {
        await expectLater(
          AlertesSupabase(
            _appel(
              const PostgrestException(
                message: 'lecture reservee a la direction',
                code: 'P0001',
              ),
              <String>[],
            ),
          ).lire(),
          throwsA(isA<CapaciteIndisponible>()),
        );
      },
    );

    test(
      'le flux relit a chaque intervalle et s arrete a l annulation',
      () async {
        final List<String> appels = <String>[];
        final AlertesSupabase port = AlertesSupabase(
          _appel(<Object?>[], appels),
          intervalle: const Duration(minutes: 1),
        );
        final List<List<Alerte>> recues = <List<Alerte>>[];
        final StreamSubscription<List<Alerte>> abonnement = port
            .suivre()
            .listen(recues.add);
        await pumpEventQueue();
        expect(recues, hasLength(1));
        expect(appels, hasLength(1));
        await abonnement.cancel();
      },
    );

    test('un compte qui n est pas de la direction : pas de cloche', () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          portAlertesProvider.overrideWithValue(
            AlertesSupabase(
              _appel(
                const PostgrestException(message: 'refus', code: 'P0001'),
                <String>[],
              ),
            ),
          ),
        ],
      );
      addTearDown(conteneur.dispose);
      final ProviderSubscription<int?> s = conteneur.listen(
        alertesUrgentesProvider,
        (_, _) {},
      );
      addTearDown(s.close);
      await pumpEventQueue();
      expect(conteneur.read(alertesUrgentesProvider), isNull);
      expect(conteneur.read(alertesProvider).hasError, isTrue);
    });
  });
}
