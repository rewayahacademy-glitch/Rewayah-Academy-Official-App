// Directeur (30/10/2026) : jamais deux fuseaux sur une meme carte. L'heure
// d'ouverture de la salle se dit a l'heure du foyer quand la carte la donne.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/features/classe_tuteur/rejoindre_avec_eleve.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  // 18:00 a Paris le jeudi 29 octobre 2026 (heure d'hiver, UTC+1).
  final DateTime debut = DateTime.utc(2026, 10, 29, 17);

  SeanceFamille seance({String? heureFoyer}) => seanceFictive(
    debutUtc: debut,
    heureFoyer: heureFoyer == null
        ? null
        : heureRendue('Europe/Paris', 'Paris', heureFoyer),
  );

  test('foyer a Paris, cours a 18:00 : 17:40, quel que soit l appareil', () {
    expect(heureOuvertureSalle(seance(heureFoyer: '18:00')), '17:40');
  });

  test('sans fenetre rendue : la fenetre par defaut de 20 min', () {
    final SeanceFamille sansFenetre = seance(heureFoyer: '18:00');
    expect(
      heureOuvertureSalle(
        SeanceFamille(
          seanceId: sansFenetre.seanceId,
          eleveId: sansFenetre.eleveId,
          debutUtc: sansFenetre.debutUtc,
          finPrevueUtc: sansFenetre.finPrevueUtc,
          statutServeur: sansFenetre.statutServeur,
          heureFoyer: sansFenetre.heureFoyer,
          enseignant: sansFenetre.enseignant,
        ),
      ),
      '17:40',
    );
  });

  test('une fenetre de 30 min rendue par le serveur : 17:30', () {
    expect(
      heureOuvertureSalle(
        seanceFictive(
          debutUtc: debut,
          ouvertureAvantDebut: const Duration(minutes: 30),
          heureFoyer: heureRendue('Europe/Paris', 'Paris', '18:00'),
        ),
      ),
      '17:30',
    );
  });

  test('avant minuit : 00:10 donne 23:50', () {
    expect(heureOuvertureSalle(seance(heureFoyer: '00:10')), '23:50');
  });

  test('sans heure du foyer : l heure de l appareil, comme la carte', () {
    expect(
      heureOuvertureSalle(seance()),
      heureDeLAppareil(debut.subtract(const Duration(minutes: 20)).toLocal()),
    );
  });

  test('heure du foyer illisible : rien, plutot qu un autre fuseau', () {
    expect(heureOuvertureSalle(seance(heureFoyer: '6 PM')), isNull);
  });
}
