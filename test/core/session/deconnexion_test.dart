// Fiche « Fraicheur et notifications » (27/10/2026), lignes 16, 17, 18 : la
// deconnexion ferme la session locale d'abord, vide la base locale, remet la
// memoire de l'application a zero, et n'attend jamais le serveur.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
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

Future<int> _lignes(AppDatabase base) async {
  int total = 0;
  for (final TableInfo<Table, dynamic> table in base.allTables) {
    total += (await base.select(table).get()).length;
  }
  return total;
}

void main() {
  late AppDatabase base;

  setUp(() {
    base = AppDatabase.surExecuteur(NativeDatabase.memory());
  });

  tearDown(() => base.close());

  test('ligne 17 : viderTablesDeLAppareil vide les cinq tables', () async {
    await _remplir(base);
    expect(await _lignes(base), 5);

    await viderTablesDeLAppareil(base);

    expect(await _lignes(base), 0);
    expect(base.allTables, hasLength(5));
  });

  test('ligne 16 : session locale fermee d abord, base videe, memoire a zero, sans attendre le serveur', () async {
    final List<String> journal = <String>[];
    final _AuthLente auth = _AuthLente(journal);
    await _remplir(base);
    final Deconnexion deconnexion = Deconnexion(
      auth: auth,
      viderAppareil: () async {
        journal.add('base locale videe');
        await viderTablesDeLAppareil(base);
      },
      remiseAZero: () => journal.add('memoire a zero'),
    );

    await deconnexion.executer();

    expect(journal, <String>[
      'session locale fermee',
      'base locale videe',
      'memoire a zero',
    ]);
    expect(await _lignes(base), 0);
    expect(auth.serveur.isCompleted, isFalse);
  });

  test('la session locale qui ne se ferme pas arrete tout et le dit', () async {
    int vidages = 0;
    int remises = 0;
    final Deconnexion deconnexion = Deconnexion(
      auth: _AuthEnEchec(),
      viderAppareil: () async => vidages++,
      remiseAZero: () => remises++,
    );

    await expectLater(deconnexion.executer(), throwsStateError);

    expect(vidages, 0);
    expect(remises, 0);
  });

  test('une base locale qui ne se vide pas n empeche pas la sortie', () async {
    final FauxServiceAuth auth = FauxServiceAuth();
    int remises = 0;
    final Deconnexion deconnexion = Deconnexion(
      auth: auth,
      viderAppareil: () => throw StateError('base verrouillee'),
      remiseAZero: () => remises++,
    );

    await deconnexion.executer();

    expect(auth.deconnexions, 1);
    expect(remises, 1);
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
          remiseAZeroProvider.overrideWithValue(() => remises++),
        ],
      );
      addTearDown(conteneur.dispose);
      await _remplir(base);

      final Deconnexion deconnexion = conteneur.read(deconnexionProvider);
      expect(ouvertures, 0);

      await deconnexion.executer();

      expect(auth.deconnexions, 1);
      expect(ouvertures, 1);
      expect(await _lignes(base), 0);
      expect(remises, 1);
    },
  );
}
