import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';

/// Depot en memoire. Le test porte sur la regle d'idempotence, pas sur SQLite.
class _DepotMemoire implements DepotRapports {
  final Map<String, RapportEnAttente> _lignes = <String, RapportEnAttente>{};

  @override
  Future<List<RapportEnAttente>> enAttente() async => _lignes.values.toList()
    ..sort(
      (RapportEnAttente a, RapportEnAttente b) =>
          a.redigeA.compareTo(b.redigeA),
    );

  @override
  Future<void> deposer(RapportEnAttente rapport) async {
    // Comme la contrainte d'unicite C9 en base : une cle deja presente ne
    // cree pas une seconde ligne.
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

/// Serveur simule appliquant la contrainte C9 : une cle d'idempotence deja vue
/// ne cree pas une seconde ligne.
class _ServeurAvecC9 {
  final Set<String> clesRecues = <String>{};
  int lignesCreees = 0;
  int appels = 0;

  Future<void> recevoir(RapportEnAttente rapport) async {
    appels++;
    if (clesRecues.add(rapport.cleIdempotence)) {
      lignesCreees++;
    }
  }
}

void main() {
  group(
    'Scenario 5 : deux synchronisations accidentelles, une seule ligne',
    () {
      test(
        'un rapport rejoue deux fois ne produit qu une ligne en base',
        () async {
          final _DepotMemoire depot = _DepotMemoire();
          final FileRapports file = FileRapports(depot);
          final _ServeurAvecC9 serveur = _ServeurAvecC9();

          final RapportEnAttente rapport = await file.enregistrer(
            sessionId: 's1',
            contenuJson: '{"travaille":"sourate 1"}',
          );

          // Premier vidage : le rapport part et le serveur cree la ligne.
          expect(await file.vider(serveur.recevoir), 1);
          expect(serveur.lignesCreees, 1);

          // On remet le meme rapport en file, comme le ferait une reprise apres
          // un crash entre l'envoi et l'accuse de reception.
          await depot.deposer(rapport);
          expect(await file.vider(serveur.recevoir), 1);

          // Le serveur a bien ete appele deux fois, et n a cree qu une ligne :
          // c est la cle d idempotence qui a tranche, pas l ecran.
          expect(serveur.appels, 2);
          expect(serveur.lignesCreees, 1);
        },
      );

      test('la cle ne change jamais entre deux tentatives', () async {
        final _DepotMemoire depot = _DepotMemoire();
        final FileRapports file = FileRapports(depot);

        final RapportEnAttente rapport = await file.enregistrer(
          sessionId: 's1',
          contenuJson: '{}',
        );

        // Deux echecs successifs.
        Future<void> echouer(RapportEnAttente _) async =>
            throw const FormatException('reseau indisponible');

        await file.vider(echouer);
        await file.vider(echouer);

        final List<RapportEnAttente> restants = await depot.enAttente();
        expect(restants, hasLength(1));
        expect(restants.single.cleIdempotence, rapport.cleIdempotence);
        expect(restants.single.tentatives, 2);
      });

      test('deux vidages concurrents ne partent pas en meme temps', () async {
        final _DepotMemoire depot = _DepotMemoire();
        final FileRapports file = FileRapports(depot);
        final _ServeurAvecC9 serveur = _ServeurAvecC9();

        await file.enregistrer(sessionId: 's1', contenuJson: '{}');

        final List<int> resultats = await Future.wait(<Future<int>>[
          file.vider(serveur.recevoir),
          file.vider(serveur.recevoir),
        ]);

        // L un des deux a travaille, l autre s est retire sans rien toucher.
        expect(resultats..sort(), <int>[0, 1]);
        expect(serveur.lignesCreees, 1);
      });

      test(
        'deposer deux fois la meme cle ne cree pas deux lignes locales',
        () async {
          final _DepotMemoire depot = _DepotMemoire();
          final RapportEnAttente rapport = RapportEnAttente(
            cleIdempotence: 'cle-fixe',
            sessionId: 's1',
            contenuJson: '{}',
            redigeA: DateTime.utc(2026, 9, 6),
          );

          await depot.deposer(rapport);
          await depot.deposer(rapport);

          expect(await depot.enAttente(), hasLength(1));
        },
      );
    },
  );

  group('Redaction hors ligne', () {
    test('un rapport s enregistre sans reseau et attend son tour', () async {
      final _DepotMemoire depot = _DepotMemoire();
      final FileRapports file = FileRapports(depot);

      await file.enregistrer(sessionId: 's1', contenuJson: '{"a":1}');
      await file.enregistrer(sessionId: 's2', contenuJson: '{"a":2}');

      expect(await depot.enAttente(), hasLength(2));
    });

    test('un echec sur un rapport ne bloque pas les suivants', () async {
      final _DepotMemoire depot = _DepotMemoire();
      final FileRapports file = FileRapports(depot);

      final RapportEnAttente premier = await file.enregistrer(
        sessionId: 's1',
        contenuJson: '{}',
        maintenant: DateTime.utc(2026, 9, 6, 8),
      );
      await file.enregistrer(
        sessionId: 's2',
        contenuJson: '{}',
        maintenant: DateTime.utc(2026, 9, 6, 9),
      );

      final int envoyes = await file.vider((RapportEnAttente r) async {
        if (r.cleIdempotence == premier.cleIdempotence) {
          throw const FormatException('refuse');
        }
      });

      expect(envoyes, 1);
      final List<RapportEnAttente> restants = await depot.enAttente();
      expect(restants, hasLength(1));
      expect(restants.single.cleIdempotence, premier.cleIdempotence);
    });
  });
}
