// LUMIERE-RETARD : le client ne compare ni heure ni seuil, il lit la liste de
// `retard_en_direct`. Une lecture qui echoue emet `null` (aucune lumiere), le
// flux ne s'interrompt pas, et sans personne connectee aucune lecture ne part.

// fake_async est la dependance de flutter_test qui porte son horloge simulee
// (version fixee par le SDK) ; aucune dependance n'est ajoutee par ce lot.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/presence/retard_en_direct.dart';
import 'package:rewayah_academy/core/presence/retard_en_direct_supabase.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart'
    show FausseSourceSession, sansPersonneConnectee;

class _Port implements PortRetardEnDirect {
  _Port(this._reponses);
  final List<Object?> _reponses;
  final List<String> appels = <String>[];

  @override
  Future<List<EleveEnRetard>?> pour(String seanceId) async {
    appels.add(seanceId);
    final Object? r = _reponses.removeAt(0);
    if (r is Exception) throw r;
    return r as List<EleveEnRetard>?;
  }
}

void main() {
  group('retardsDepuisLignes', () {
    test('une ligne bien formee devient un eleve en retard', () {
      expect(
        retardsDepuisLignes(<Object?>[
          <String, dynamic>{
            'student_id': 'e1',
            'started_at': '2026-11-11T10:00:00Z',
            'retard_secondes': 612,
          },
        ]),
        const <EleveEnRetard>[
          EleveEnRetard(eleveId: 'e1', retardSecondes: 612),
        ],
      );
    });
    test('une ligne mal formee est ignoree, jamais devinee', () {
      expect(
        retardsDepuisLignes(<Object?>[
          <String, dynamic>{'student_id': '', 'retard_secondes': 5},
          <String, dynamic>{'student_id': 'e2'},
          <String, dynamic>{'student_id': 'e3', 'retard_secondes': '7'},
          'x',
        ]),
        isEmpty,
      );
    });
    test('une reponse qui n est pas une liste est une erreur', () {
      expect(
        () => retardsDepuisLignes(<String, dynamic>{}),
        throwsFormatException,
      );
    });
    test('liste vide : personne n est en retard', () {
      expect(retardsDepuisLignes(<Object?>[]), isEmpty);
    });
  });

  group('retardEnDirectProvider', () {
    ProviderContainer conteneur(
      PortRetardEnDirect port, {
      bool connecte = true,
    }) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          connecte
              ? sourceSessionProvider.overrideWithValue(
                  FausseSourceSession(sessionActive(AppRole.guardian)),
                )
              : sansPersonneConnectee(),
          portRetardEnDirectProvider.overrideWithValue(port),
        ],
      );
      addTearDown(c.dispose);
      // La session se resout par un flux : l'ecouter avant de lire.
      c.listen(sessionProvider, (Object? _, Object? _) {});
      return c;
    }

    test(
      'la premiere lecture est immediate, puis une relecture a la cadence',
      () {
        fakeAsync((FakeAsync async) {
          final _Port port = _Port(<Object?>[
            const <EleveEnRetard>[
              EleveEnRetard(eleveId: 'e1', retardSecondes: 400),
            ],
            const <EleveEnRetard>[],
          ]);
          final ProviderContainer c = conteneur(port);
          final List<List<EleveEnRetard>?> vus = <List<EleveEnRetard>?>[];
          c.listen<AsyncValue<List<EleveEnRetard>?>>(
            retardEnDirectProvider('s1'),
            (
              AsyncValue<List<EleveEnRetard>?>? _,
              AsyncValue<List<EleveEnRetard>?> n,
            ) {
              if (n.hasValue) vus.add(n.value);
            },
            fireImmediately: true,
          );
          async.elapse(const Duration(milliseconds: 1));
          expect(vus.last, hasLength(1));
          async.elapse(cadenceRetardEnDirect);
          expect(vus.last, isEmpty);
          expect(port.appels, <String>['s1', 's1']);
        });
      },
    );

    test('une lecture qui echoue emet null et la suivante reprend', () {
      fakeAsync((FakeAsync async) {
        final _Port port = _Port(<Object?>[
          Exception('reseau'),
          const <EleveEnRetard>[
            EleveEnRetard(eleveId: 'e1', retardSecondes: 400),
          ],
        ]);
        final ProviderContainer c = conteneur(port);
        final List<List<EleveEnRetard>?> vus = <List<EleveEnRetard>?>[];
        c.listen<AsyncValue<List<EleveEnRetard>?>>(
          retardEnDirectProvider('s1'),
          (
            AsyncValue<List<EleveEnRetard>?>? _,
            AsyncValue<List<EleveEnRetard>?> n,
          ) {
            if (n.hasValue) vus.add(n.value);
          },
          fireImmediately: true,
        );
        async.elapse(const Duration(milliseconds: 1));
        expect(vus.last, isNull);
        async.elapse(cadenceRetardEnDirect);
        expect(vus.last, hasLength(1));
      });
    });

    test('sans personne connectee : aucune lecture', () {
      fakeAsync((FakeAsync async) {
        final _Port port = _Port(<Object?>[const <EleveEnRetard>[]]);
        final ProviderContainer c = conteneur(port, connecte: false);
        c.listen<AsyncValue<List<EleveEnRetard>?>>(
          retardEnDirectProvider('s1'),
          (
            AsyncValue<List<EleveEnRetard>?>? _,
            AsyncValue<List<EleveEnRetard>?> _,
          ) {},
          fireImmediately: true,
        );
        async.elapse(cadenceRetardEnDirect * 2);
        expect(port.appels, isEmpty);
      });
    });

    test('sans seance : aucune lecture', () {
      fakeAsync((FakeAsync async) {
        final _Port port = _Port(<Object?>[const <EleveEnRetard>[]]);
        final ProviderContainer c = conteneur(port);
        c.listen<AsyncValue<List<EleveEnRetard>?>>(
          retardEnDirectProvider(' '),
          (
            AsyncValue<List<EleveEnRetard>?>? _,
            AsyncValue<List<EleveEnRetard>?> _,
          ) {},
          fireImmediately: true,
        );
        async.elapse(cadenceRetardEnDirect * 2);
        expect(port.appels, isEmpty);
      });
    });
  });
}
