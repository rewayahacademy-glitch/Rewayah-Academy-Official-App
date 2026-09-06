import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';

import '../support/harnais.dart';

/// Le lieu de reference de l'enseignant de Paris.
const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: 't1',
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

/// Celui de l'enseignante de Conakry, sur un autre fuseau et un autre
/// continent.
const ReglagesPriere _conakry = ReglagesPriere(
  enseignantId: 't2',
  latitude: 9.64110,
  longitude: -13.57840,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  fuseau: 'Africa/Conakry',
  lieu: 'Conakry',
);

/// Un jour civil fixe : le calcul ne doit dependre ni de la date du jour ni de
/// l'heure a laquelle le test tourne.
final DateTime _jour = DateTime.utc(2026, 3, 11);

void main() {
  group('Scenario 9 : la meme minute pour tout le monde', () {
    test('l eleve et l enseignant lisent la meme source et trouvent le meme '
        'instant', () async {
      final FauxServicePriere service = FauxServicePriere()
        ..parEnseignant['t1'] = _paris;

      // Deux lectures distinctes de la meme ligne : c'est ce que font
      // l'enseignant sur ENS-02 et l'eleve sur ELV-02.
      final ReglagesPriere? coteEnseignant = await service.reglages('t1');
      final ReglagesPriere? coteEleve = await service.reglages('t1');

      final HorairesPriere chezLEnseignant = HorairesPriere.duJour(
        reglages: coteEnseignant!,
        jour: _jour,
      );
      final HorairesPriere chezLEleve = HorairesPriere.duJour(
        reglages: coteEleve!,
        jour: _jour,
      );

      for (final Priere priere in Priere.values) {
        expect(
          chezLEleve[priere]!.isAtSameMomentAs(chezLEnseignant[priere]!),
          isTrue,
          reason: 'les deux roles doivent lire le meme instant pour $priere',
        );
      }
    });

    test('le calcul ne depend pas de la facon dont le jour est exprime', () {
      // Le meme instant, ecrit en local et en UTC. Une seule des deux ecritures
      // passerait si le calcul lisait le fuseau de l'appareil au lieu de
      // travailler en instants absolus.
      final HorairesPriere parUtc = HorairesPriere.duJour(
        reglages: _paris,
        jour: DateTime.utc(2026, 3, 11, 12),
      );
      final HorairesPriere parLocal = HorairesPriere.duJour(
        reglages: _paris,
        jour: DateTime.utc(2026, 3, 11, 12).toLocal(),
      );

      for (final Priere priere in Priere.values) {
        expect(parLocal[priere]!.isAtSameMomentAs(parUtc[priere]!), isTrue);
      }
    });

    test('deux lieux ne donnent pas le meme instant', () {
      final DateTime parisDhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;
      final DateTime conakryDhuhr = HorairesPriere.duJour(
        reglages: _conakry,
        jour: _jour,
      )[Priere.dhuhr]!;

      // Conakry est a l'ouest : son midi solaire tombe plus tard en temps
      // absolu. Sans cela, le calcul ignorerait les coordonnees.
      expect(conakryDhuhr.isAfter(parisDhuhr), isTrue);
    });

    test('les cinq prieres se suivent dans l ordre', () {
      final HorairesPriere horaires = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      );
      final List<DateTime> instants = <DateTime>[
        for (final Priere priere in Priere.values) horaires[priere]!,
      ];
      for (int i = 0; i + 1 < instants.length; i++) {
        expect(instants[i].isBefore(instants[i + 1]), isTrue);
      }
    });

    test('des reglages illisibles n annoncent rien du tout', () {
      // Une methode que ce code ne connait pas : mieux vaut aucune annonce
      // qu'une fausse, faite a tout le monde avec le meme aplomb.
      final ReglagesPriere inconnus = ReglagesPriere.depuisJson(
        const <String, dynamic>{
          'teacher_id': 't1',
          'latitude': 48.85341,
          'longitude': 2.34880,
          'method': 'methode_de_demain',
          'madhab': 'shafi',
        },
      );

      expect(inconnus.calculables, isFalse);
      expect(HorairesPriere.duJour(reglages: inconnus, jour: _jour).vides, isTrue);
      expect(
        interruptionsEntre(
          reglages: inconnus,
          debut: _jour,
          fin: _jour.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
    });
  });

  group('Scenario 10 : un ajustement d une minute deplace l entree', () {
    test('plus une minute deplace la priere de soixante secondes', () {
      final DateTime sansAjustement = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;
      final DateTime avecAjustement = HorairesPriere.duJour(
        reglages: _paris.avecAjustement(Priere.dhuhr, 1),
        jour: _jour,
      )[Priere.dhuhr]!;

      expect(
        avecAjustement.difference(sansAjustement),
        const Duration(minutes: 1),
      );
    });

    test('moins une minute la deplace dans l autre sens', () {
      final DateTime sansAjustement = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.maghrib]!;
      final DateTime avecAjustement = HorairesPriere.duJour(
        reglages: _paris.avecAjustement(Priere.maghrib, -1),
        jour: _jour,
      )[Priere.maghrib]!;

      expect(
        avecAjustement.difference(sansAjustement),
        const Duration(minutes: -1),
      );
    });

    test('l ajustement deplace l entree des deux cotes, et d elle seule', () {
      final ReglagesPriere ajustes = _paris.avecAjustement(Priere.asr, 3);
      final DateTime asr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.asr]!;

      // La meme fenetre, lue par l'ecran de l'eleve et par celui de
      // l'enseignant : les deux partent des memes reglages, donc les deux
      // bougent ensemble.
      final DateTime debut = asr.subtract(const Duration(hours: 1));
      final DateTime fin = asr.add(const Duration(hours: 1));

      final List<InterruptionPriere> avant = interruptionsEntre(
        reglages: _paris,
        debut: debut,
        fin: fin,
      );
      final List<InterruptionPriere> apres = interruptionsEntre(
        reglages: ajustes,
        debut: debut,
        fin: fin,
      );

      final InterruptionPriere asrAvant = avant.firstWhere(
        (InterruptionPriere i) => i.priere == Priere.asr,
      );
      final InterruptionPriere asrApres = apres.firstWhere(
        (InterruptionPriere i) => i.priere == Priere.asr,
      );

      expect(
        asrApres.debut.difference(asrAvant.debut),
        const Duration(minutes: 3),
      );
      // Les autres prieres n'ont pas bouge : un ajustement porte sur une
      // priere, pas sur la journee.
      for (final Priere priere in Priere.values) {
        if (priere == Priere.asr) {
          continue;
        }
        expect(
          HorairesPriere.duJour(reglages: ajustes, jour: _jour)[priere]!
              .isAtSameMomentAs(
                HorairesPriere.duJour(reglages: _paris, jour: _jour)[priere]!,
              ),
          isTrue,
        );
      }
    });
  });

  group('Ce qui interrompt un cours, et ce qui ne l interrompt pas', () {
    test('une priere pendant le cours est retenue', () {
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;

      final List<InterruptionPriere> trouvees = interruptionsEntre(
        reglages: _paris,
        debut: dhuhr.subtract(const Duration(minutes: 10)),
        fin: dhuhr.add(const Duration(minutes: 50)),
      );

      expect(trouvees.map((InterruptionPriere i) => i.priere), <Priere>[
        Priere.dhuhr,
      ]);
      expect(trouvees.single.duree, const Duration(minutes: 15));
    });

    test('un cours qui s acheve a l instant de la priere n est pas interrompu', () {
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;

      // Bornes semi-ouvertes, comme les seances en base depuis le defaut 3.9 :
      // la minute ou le cours finit ne lui appartient plus.
      expect(
        interruptionsEntre(
          reglages: _paris,
          debut: dhuhr.subtract(const Duration(hours: 1)),
          fin: dhuhr,
        ),
        isEmpty,
      );
    });

    test('une priere commencee avant le cours mais qui deborde dedans compte', () {
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;

      final List<InterruptionPriere> trouvees = interruptionsEntre(
        reglages: _paris,
        debut: dhuhr.add(const Duration(minutes: 5)),
        fin: dhuhr.add(const Duration(hours: 1)),
      );

      expect(trouvees.single.priere, Priere.dhuhr);
    });

    test('une fenetre a cheval sur deux jours civils trouve la priere du '
        'lendemain', () {
      // Le fajr du 11 mars, vu depuis une fenetre qui commence la veille en
      // temps universel. Sans le balayage du jour suivant, il serait manque :
      // c'est le cas reel d'un cours du soir en Asie, dont la journee locale
      // deborde sur la journee UTC suivante.
      final DateTime fajr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.fajr]!;
      final DateTime debut = fajr.subtract(const Duration(hours: 6));

      expect(
        debut.toUtc().day,
        isNot(fajr.toUtc().day),
        reason: 'la fenetre doit bien commencer un autre jour civil UTC',
      );
      expect(
        interruptionsEntre(
          reglages: _paris,
          debut: debut,
          fin: fajr.add(const Duration(minutes: 30)),
        ).map((InterruptionPriere i) => i.priere),
        contains(Priere.fajr),
      );
    });

    test('l alerte est visible du preavis jusqu a la fin de l interruption', () {
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;
      final InterruptionPriere interruption = interruptionsEntre(
        reglages: _paris,
        debut: dhuhr.subtract(const Duration(hours: 1)),
        fin: dhuhr.add(const Duration(hours: 1)),
      ).single;

      // Le preavis vient des reglages, pas du code : il vaut dix minutes ici
      // parce que la base le dit, et il vaut la meme chose pour les trois roles.
      expect(interruption.preavis, const Duration(minutes: 10));
      expect(
        interruption.alerteVisibleA(
          dhuhr.subtract(const Duration(minutes: 11)),
        ),
        isFalse,
      );
      expect(
        interruption.alerteVisibleA(dhuhr.subtract(const Duration(minutes: 9))),
        isTrue,
      );
      expect(
        interruption.alerteVisibleA(dhuhr.add(const Duration(minutes: 14))),
        isTrue,
      );
      expect(
        interruption.alerteVisibleA(dhuhr.add(const Duration(minutes: 15))),
        isFalse,
      );
    });
  });

  group('Ce que la base recoit et ce qu elle rend', () {
    test('les cinq cles sont toujours ecrites, meme celles qui valent zero', () {
      final Map<String, dynamic> json = _paris
          .avecAjustement(Priere.dhuhr, 2)
          .versJson();

      // Le declencheur `guard_prayer_adjustments` refuse un objet incomplet :
      // ecrire seulement les prieres ajustees ferait echouer l'enregistrement.
      expect(json['adjustments'], const <String, int>{
        'fajr': 0,
        'dhuhr': 2,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      });
      expect(json['alert_lead_minutes'], 10);
      expect(json['pause_minutes'], 15);
    });

    test('une ligne de la base se relit sans rien perdre', () {
      final ReglagesPriere lus = ReglagesPriere.depuisJson(const <String, dynamic>{
        'teacher_id': 't1',
        // PostgREST rend un numeric sous forme de chaine selon les versions.
        'latitude': '48.85341',
        'longitude': '2.34880',
        'method': 'karachi',
        'madhab': 'hanafi',
        'adjustments': <String, dynamic>{
          'fajr': 0,
          'dhuhr': 2,
          'asr': 0,
          'maghrib': -1,
          'isha': 0,
        },
        'timezone_iana': 'Europe/Paris',
        'pause_minutes': 12,
        'alert_lead_minutes': 5,
        'place_label': 'Paris',
      });

      expect(lus.methode, MethodeCalcul.karachi);
      expect(lus.madhab, Madhab.hanafi);
      expect(lus.latitude, closeTo(48.85341, 0.00001));
      expect(lus.ajustement(Priere.maghrib), -1);
      expect(lus.pause, const Duration(minutes: 12));
      expect(lus.preavis, const Duration(minutes: 5));
      expect(lus.calculables, isTrue);
    });
  });
}
