// Fiche « Fraicheur et notifications » (27/10/2026), lignes 16, 17, 18, et
// revue de la PR 63 : la deconnexion donne une derniere chance aux cahiers en
// file, demande avant de les perdre, retire les donnees de la personne de la
// base locale (les reglages de l'appareil restent) avant de fermer la session
// locale, remet la memoire de l'application a zero, et n'attend jamais le
// serveur. Une base qui ne se vide pas ou une file illisible refusent la
// sortie : la personne reste connectee.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/session/deconnexion.dart';

import '../../support/harnais.dart' show FauxServiceAuth;

/// Une authentification qui note l'ordre des etapes et dont le serveur ne
/// repond jamais : la sortie ne doit pas l'attendre.
class _AuthLente implements ServiceAuth {
  _AuthLente(this.journal);

  final List<String> journal;
  final Completer<void> serveur = Completer<void>();

  @override
  Future<void> deconnexion() async {
    journal.add('session locale fermee');
    // Le serveur est prevenu sans etre attendu, comme ServiceAuthSupabase.
    unawaited(serveur.future);
  }

  @override
  Future<void> connexionGoogle() async {}

  @override
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {}

  @override
  Future<void> envoyerLienCourriel(String courriel) async {}
}

/// Une authentification dont la fermeture locale echoue.
class _AuthEnEchec implements ServiceAuth {
  @override
  Future<void> deconnexion() async => throw StateError('coffre illisible');

  @override
  Future<void> connexionGoogle() async {}

  @override
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {}

  @override
  Future<void> envoyerLienCourriel(String courriel) async {}
}

/// Un depot de cahiers en memoire.
class _DepotMemoire implements DepotRapports {
  _DepotMemoire([
    Iterable<RapportEnAttente> lignes = const <RapportEnAttente>[],
  ]) : _lignes = <String, RapportEnAttente>{
         for (final RapportEnAttente r in lignes) r.cleIdempotence: r,
       };

  final Map<String, RapportEnAttente> _lignes;

  /// Si vrai, la lecture leve (base locale absente).
  bool illisible = false;

  @override
  Future<List<RapportEnAttente>> enAttente() async {
    if (illisible) throw StateError('base locale absente');
    return _lignes.values.toList();
  }

  @override
  Future<void> deposer(RapportEnAttente rapport) async {
    _lignes.putIfAbsent(rapport.cleIdempotence, () => rapport);
  }

  @override
  Future<void> retirer(String cleIdempotence) async {
    _lignes.remove(cleIdempotence);
  }

  @override
  Future<void> majApresEchec(RapportEnAttente rapport) async {
    _lignes[rapport.cleIdempotence] = rapport;
  }
}

/// Un depot dont la lecture ne repond jamais (base locale muette).
class _DepotMuet implements DepotRapports {
  _DepotMuet(this._lecture);

  final Future<List<RapportEnAttente>> _lecture;

  @override
  Future<List<RapportEnAttente>> enAttente() => _lecture;

  @override
  Future<void> deposer(RapportEnAttente rapport) async {}

  @override
  Future<void> retirer(String cleIdempotence) async {}

  @override
  Future<void> majApresEchec(RapportEnAttente rapport) async {}
}

RapportEnAttente _rapport(String cle) => RapportEnAttente(
  cleIdempotence: cle,
  sessionId: 's1',
  contenuJson: '{}',
  redigeA: DateTime.utc(2026, 10, 27),
);

Future<void> _remplir(AppDatabase base) async {
  await base
      .into(base.profilsFoyer)
      .insert(
        ProfilsFoyerCompanion.insert(
          id: 'e1',
          identifiantImmuable: 'RA-26-0001',
          prenom: 'Yasmine',
          synchroniseA: DateTime.utc(2026, 10, 27),
        ),
      );
  await base
      .into(base.sessionsAVenir)
      .insert(
        SessionsAVenirCompanion.insert(
          id: 's1',
          debutUtc: DateTime.utc(2026, 10, 28, 17),
          finUtc: DateTime.utc(2026, 10, 28, 18),
          statut: 'planned',
          profilId: 'e1',
          prenomEnseignant: 'Amina',
          synchroniseA: DateTime.utc(2026, 10, 27),
        ),
      );
  await base
      .into(base.preferenceLocale)
      .insert(
        PreferenceLocaleCompanion.insert(
          clef: 'apparence.theme',
          valeur: 'sombre',
        ),
      );
  await base
      .into(base.rapportsEnAttente)
      .insert(
        RapportsEnAttenteCompanion.insert(
          cleIdempotence: 'k1',
          sessionId: 's1',
          contenuJson: '{}',
          redigeA: DateTime.utc(2026, 10, 27),
        ),
      );
  await base
      .into(base.ressourcesHorsLigne)
      .insert(
        RessourcesHorsLigneCompanion.insert(
          resourceId: 'r1',
          versionId: 'v1',
          cleCache: 'c1',
          deposeeA: DateTime.utc(2026, 10, 27),
        ),
      );
}

Future<Map<String, int>> _lignes(AppDatabase base) async => <String, int>{
  for (final TableInfo<Table, dynamic> table in base.allTables)
    table.actualTableName: (await base.select(table).get()).length,
};

Future<bool> _jamaisDemande(int _) async => fail('confirmation inattendue');

void main() {
  late AppDatabase base;

  setUp(() {
    base = AppDatabase.surExecuteur(NativeDatabase.memory());
  });

  tearDown(() => base.close());

  test('ligne 17 : les tables de la personne sont videes, les reglages de l appareil restent', () async {
    await _remplir(base);
    expect((await _lignes(base)).values.toList(), everyElement(1));

    await viderTablesDeLaPersonne(base);

    final Map<String, int> apres = await _lignes(base);
    expect(apres.remove('preference_locale'), 1);
    expect(apres, hasLength(4));
    expect(apres.values.toList(), everyElement(0));
  });

  test('ligne 16 : base videe, puis session locale fermee, memoire a zero, sans attendre le serveur', () async {
    final List<String> journal = <String>[];
    final _AuthLente auth = _AuthLente(journal);
    await _remplir(base);
    final Deconnexion deconnexion = Deconnexion(
      auth: auth,
      rapportsRestants: () async => 0,
      viderAppareil: () async {
        journal.add('base locale videe');
        await viderTablesDeLaPersonne(base);
      },
      remiseAZero: () => journal.add('memoire a zero'),
    );

    expect(await deconnexion.executer(confirmerPerte: _jamaisDemande), isTrue);

    expect(journal, <String>[
      'base locale videe',
      'session locale fermee',
      'memoire a zero',
    ]);
    expect((await _lignes(base))['profils_foyer'], 0);
    expect(auth.serveur.isCompleted, isFalse);
  });

  test('la session locale qui ne se ferme pas arrete tout et le dit', () async {
    int vidages = 0;
    int remises = 0;
    final Deconnexion deconnexion = Deconnexion(
      auth: _AuthEnEchec(),
      rapportsRestants: () async => 0,
      viderAppareil: () async => vidages++,
      remiseAZero: () => remises++,
    );

    await expectLater(
      deconnexion.executer(confirmerPerte: _jamaisDemande),
      throwsStateError,
    );

    expect(vidages, 1);
    expect(remises, 0);
  });

  test('revue PR 63 : une base locale qui ne se vide pas refuse la sortie, la session reste ouverte', () async {
    final FauxServiceAuth auth = FauxServiceAuth();
    int remises = 0;
    final Deconnexion deconnexion = Deconnexion(
      auth: auth,
      rapportsRestants: () async => 0,
      viderAppareil: () => throw StateError('base verrouillee'),
      remiseAZero: () => remises++,
    );

    await expectLater(
      deconnexion.executer(confirmerPerte: _jamaisDemande),
      throwsStateError,
    );

    expect(auth.deconnexions, 0);
    expect(remises, 0);
  });

  test(
    'revue PR 63 : un vidage qui echoue en transaction ne laisse rien a moitie',
    () async {
      await _remplir(base);
      final Map<String, int> avant = await _lignes(base);

      await expectLater(
        base.transaction(() async {
          await base.delete(base.profilsFoyer).go();
          throw StateError('base verrouillee');
        }),
        throwsStateError,
      );

      expect(await _lignes(base), avant);
    },
  );

  group('cahiers en file (ligne 16, arbitrage du pilote)', () {
    test(
      'sans cahier en file, aucun envoi construit, aucune question',
      () async {
        final _DepotMemoire depot = _DepotMemoire();
        int rejeux = 0;

        final int restants = await rapportsRestantsApresEnvoi(depot, () {
          rejeux++;
          return () async => 0;
        });

        expect(restants, 0);
        expect(rejeux, 0);
      },
    );

    test('les cahiers qui partent ne sont pas comptes', () async {
      final _DepotMemoire depot = _DepotMemoire(<RapportEnAttente>[
        _rapport('a'),
        _rapport('b'),
      ]);

      final int restants = await rapportsRestantsApresEnvoi(depot, () {
        return () async {
          await depot.retirer('a');
          return 1;
        };
      });

      expect(restants, 1);
    });

    test('un envoi qui ne repond pas ne retient pas la sortie', () async {
      final _DepotMemoire depot = _DepotMemoire(<RapportEnAttente>[
        _rapport('a'),
      ]);
      final Completer<int> jamais = Completer<int>();

      final int restants = await rapportsRestantsApresEnvoi(
        depot,
        () =>
            () => jamais.future,
      );

      expect(restants, 1);
    });

    test('revue PR 63 : une file illisible refuse la sortie', () async {
      final _DepotMemoire depot = _DepotMemoire(<RapportEnAttente>[
        _rapport('a'),
      ])..illisible = true;
      int rejeux = 0;

      await expectLater(
        rapportsRestantsApresEnvoi(depot, () {
          rejeux++;
          return () async => 0;
        }),
        throwsStateError,
      );
      expect(rejeux, 0);
    });

    test(
      'revue PR 63 : une file muette au-dela du delai refuse la sortie',
      () async {
        final Completer<List<RapportEnAttente>> jamais =
            Completer<List<RapportEnAttente>>();
        final _DepotMuet depot = _DepotMuet(jamais.future);

        await expectLater(
          rapportsRestantsApresEnvoi(
            depot,
            () =>
                () async => 0,
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('revue PR 63 : une file lue et vide sort sans question', () async {
      final FauxServiceAuth auth = FauxServiceAuth();
      int vidages = 0;
      final Deconnexion deconnexion = Deconnexion(
        auth: auth,
        rapportsRestants: () => rapportsRestantsApresEnvoi(
          _DepotMemoire(),
          () =>
              () async => 0,
        ),
        viderAppareil: () async => vidages++,
        remiseAZero: () {},
      );

      expect(
        await deconnexion.executer(confirmerPerte: _jamaisDemande),
        isTrue,
      );
      expect(auth.deconnexions, 1);
      expect(vidages, 1);
    });

    test(
      'revue PR 63 : une file illisible laisse la session ouverte',
      () async {
        final FauxServiceAuth auth = FauxServiceAuth();
        int vidages = 0;
        int remises = 0;
        final Deconnexion deconnexion = Deconnexion(
          auth: auth,
          rapportsRestants: () => rapportsRestantsApresEnvoi(
            _DepotMemoire(<RapportEnAttente>[_rapport('a')])..illisible = true,
            () =>
                () async => 0,
          ),
          viderAppareil: () async => vidages++,
          remiseAZero: () => remises++,
        );

        await expectLater(
          deconnexion.executer(confirmerPerte: _jamaisDemande),
          throwsStateError,
        );
        expect(auth.deconnexions, 0);
        expect(vidages, 0);
        expect(remises, 0);
      },
    );

    test('il en reste : la personne annule, rien n est touche', () async {
      final FauxServiceAuth auth = FauxServiceAuth();
      int vidages = 0;
      int remises = 0;
      final List<int> demandes = <int>[];
      final Deconnexion deconnexion = Deconnexion(
        auth: auth,
        rapportsRestants: () async => 2,
        viderAppareil: () async => vidages++,
        remiseAZero: () => remises++,
      );

      final bool sortie = await deconnexion.executer(
        confirmerPerte: (int n) async {
          demandes.add(n);
          return false;
        },
      );

      expect(sortie, isFalse);
      expect(demandes, <int>[2]);
      expect(auth.deconnexions, 0);
      expect(vidages, 0);
      expect(remises, 0);
    });

    test('il en reste : la personne confirme, tout est vide', () async {
      final FauxServiceAuth auth = FauxServiceAuth();
      int vidages = 0;
      int remises = 0;
      final Deconnexion deconnexion = Deconnexion(
        auth: auth,
        rapportsRestants: () async => 1,
        viderAppareil: () async => vidages++,
        remiseAZero: () => remises++,
      );

      expect(
        await deconnexion.executer(confirmerPerte: (int _) async => true),
        isTrue,
      );
      expect(auth.deconnexions, 1);
      expect(vidages, 1);
      expect(remises, 1);
    });
  });

  test(
    'deconnexionProvider lit la base locale au moment du geste seulement',
    () async {
      int ouvertures = 0;
      int remises = 0;
      final FauxServiceAuth auth = FauxServiceAuth();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          serviceAuthProvider.overrideWithValue(auth),
          baseLocaleProvider.overrideWith((Ref _) {
            ouvertures++;
            return base;
          }),
          depotRapportsProvider.overrideWithValue(_DepotMemoire()),
          remiseAZeroProvider.overrideWithValue(() => remises++),
        ],
      );
      addTearDown(conteneur.dispose);
      await _remplir(base);

      final Deconnexion deconnexion = conteneur.read(deconnexionProvider);
      expect(ouvertures, 0);

      expect(
        await deconnexion.executer(confirmerPerte: _jamaisDemande),
        isTrue,
      );

      expect(auth.deconnexions, 1);
      expect(ouvertures, 1);
      expect((await _lignes(base))['profils_foyer'], 0);
      expect((await _lignes(base))['preference_locale'], 1);
      expect(remises, 1);
    },
  );
}
