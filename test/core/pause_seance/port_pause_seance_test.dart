// LIVE-PAUSE-01 : le port de la pause programmee, en production et en demo.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_demonstration.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';

void main() {
  group('production : capacite indisponible, jamais un faux succes', () {
    const PortPauseSeance port = PauseSeanceIndisponible();
    for (final (String nom, Future<Object?> Function() appel)
        in <(String, Future<Object?> Function())>[
          ('reglage', () => port.reglage('g1')),
          (
            'enregistrerReglage',
            () => port.enregistrerReglage(
              groupeId: 'g1',
              actif: true,
              apresMinutes: 30,
              dureeMinutes: 10,
              versionAttendue: 'v1',
              cleIdempotence: 'k1',
            ),
          ),
          ('etat', () => port.etat('s1')),
          (
            'demarrer',
            () => port.demarrer(seanceId: 's1', cleIdempotence: 'k'),
          ),
          (
            'terminer',
            () => port.terminer(seanceId: 's1', cleIdempotence: 'k'),
          ),
        ]) {
      test(nom, () async {
        await expectLater(
          appel(),
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible e) => e.dependance,
              'dependance',
              PauseSeanceIndisponible.dependance,
            ),
          ),
        );
      });
    }

    test('sans PLAYGROUND, le port choisi est le port indisponible', () {
      expect(portPauseSeanceSelon(demo: false), isA<PauseSeanceIndisponible>());
      expect(portPauseSeanceSelon(demo: true), isA<PauseSeanceDemonstration>());
    });
  });

  group('demonstration', () {
    late DateTime maintenant;
    late PauseSeanceDemonstration port;
    setUp(() {
      maintenant = DateTime.utc(2026, 10, 12, 18, 10);
      port = PauseSeanceDemonstration(maintenant: () => maintenant);
    });

    test('le reglage reste valable de seance en seance', () async {
      final ReglagePause r = await port.reglage('g1');
      final ReglagePause nouveau = await port.enregistrerReglage(
        groupeId: 'g1',
        actif: true,
        apresMinutes: 45,
        dureeMinutes: 15,
        versionAttendue: r.version,
        cleIdempotence: 'k1',
      );
      expect(nouveau.apresMinutes, 45);
      expect((await port.reglage('g1')).dureeMinutes, 15);
      // Une autre seance de la classe en herite.
      final PauseSeance s2 = await port.etat('seance-suivante');
      expect(s2.statut, StatutPause.programmee);
      expect(s2.dureePrevueMinutes, 15);
    });

    test('version perimee : refusee, rien n\'est ecrase', () async {
      final ReglagePause r = await port.reglage('g1');
      await port.enregistrerReglage(
        groupeId: 'g1',
        actif: false,
        apresMinutes: 30,
        dureeMinutes: 10,
        versionAttendue: r.version,
        cleIdempotence: 'k1',
      );
      await expectLater(
        port.enregistrerReglage(
          groupeId: 'g1',
          actif: true,
          apresMinutes: 60,
          dureeMinutes: 20,
          versionAttendue: r.version,
          cleIdempotence: 'k2',
        ),
        throwsA(isA<ReglagePauseObsolete>()),
      );
      expect((await port.reglage('g1')).actif, isFalse);
    });

    test(
      'rejouer la meme cle et la meme demande rend le meme reglage',
      () async {
        final ReglagePause r = await port.reglage('g1');
        final ReglagePause a = await port.enregistrerReglage(
          groupeId: 'g1',
          actif: true,
          apresMinutes: 40,
          dureeMinutes: 10,
          versionAttendue: r.version,
          cleIdempotence: 'k1',
        );
        final ReglagePause b = await port.enregistrerReglage(
          groupeId: 'g1',
          actif: true,
          apresMinutes: 40,
          dureeMinutes: 10,
          versionAttendue: r.version,
          cleIdempotence: 'k1',
        );
        expect(b, a);
      },
    );

    test('desactive : aucune pause n\'est prevue', () async {
      final ReglagePause r = await port.reglage('g1');
      await port.enregistrerReglage(
        groupeId: 'g1',
        actif: false,
        apresMinutes: 30,
        dureeMinutes: 10,
        versionAttendue: r.version,
        cleIdempotence: 'k1',
      );
      expect((await port.etat('s1')).statut, StatutPause.nonPrevue);
    });

    test('programmee, en cours, puis prise, horodatee', () async {
      expect((await port.etat('s1')).statut, StatutPause.programmee);
      final PauseSeance debut = await port.demarrer(
        seanceId: 's1',
        cleIdempotence: 'a',
      );
      expect(debut.statut, StatutPause.enCours);
      expect(debut.debutUtc, maintenant);
      expect(
        debut.repriseUtc,
        maintenant.add(Duration(minutes: debut.dureePrevueMinutes)),
      );
      // Demarrer deux fois ne change rien.
      maintenant = maintenant.add(const Duration(minutes: 3));
      expect(
        (await port.demarrer(seanceId: 's1', cleIdempotence: 'b')).debutUtc,
        debut.debutUtc,
      );
      maintenant = maintenant.add(const Duration(minutes: 7));
      final PauseSeance fin = await port.terminer(
        seanceId: 's1',
        cleIdempotence: 'c',
      );
      expect(fin.statut, StatutPause.prise);
      expect(fin.dureeReelle, const Duration(minutes: 10));
    });

    test(
      'rien ne porte une identite : aucun champ d\'eleve ni de presence',
      () {
        // Le type ne peut pas transporter une preuve de presence : ses seuls
        // champs sont des horodatages de pause et des durees.
        const PauseSeance p = PauseSeance.nonPrevue();
        expect(p.toString(), isNot(contains('eleve')));
        expect(p.peutPiloter, isFalse);
      },
    );
  });

  group('bornes du reglage', () {
    test('un reglage hors bornes est refuse a la construction', () {
      expect(
        () => ReglagePause(
          actif: true,
          apresMinutes: BornesPause.apresMax + 5,
          dureeMinutes: 10,
          version: 'v',
          peutModifier: true,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ReglagePause(
          actif: true,
          apresMinutes: 30,
          dureeMinutes: BornesPause.dureeMin - 1,
          version: 'v',
          peutModifier: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
