// CAND-01 : la grille des disponibilites et la forme que le serveur attend
// (`private.questionnaire_creneaux`, CAND-L2A1).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/creneaux_declares.dart';

void main() {
  group('CreneauxDeclares', () {
    test('une grille vide ne declare rien', () {
      const CreneauxDeclares c = CreneauxDeclares();
      expect(c.estVide, isTrue);
      expect(c.nombrePleines, 0);
      expect(c.versReponse('Europe/Paris'), <String, Object?>{
        'fuseau': 'Europe/Paris',
        'creneaux': <Object>[],
      });
    });

    test('une cellule touchee se remplit, retouchee elle se vide', () {
      final CreneauxDeclares une = const CreneauxDeclares().bascule(
        jour: 1,
        plage: 2,
      );
      expect(une.etat(jour: 1, plage: 2), EtatCellule.pleine);
      expect(une.etat(jour: 1, plage: 3), EtatCellule.vide);
      expect(une.etat(jour: 2, plage: 2), EtatCellule.vide);
      expect(une.nombrePleines, 1);
      expect(une.bascule(jour: 1, plage: 2).estVide, isTrue);
    });

    test('une plage devient un creneau a la demi-heure, 24:00 permis', () {
      final CreneauxDeclares c = const CreneauxDeclares()
          .bascule(jour: 3, plage: 2)
          .bascule(jour: 7, plage: 5);
      expect(c.versReponse('Asia/Riyadh'), <String, Object?>{
        'fuseau': 'Asia/Riyadh',
        'creneaux': <Map<String, Object?>>[
          <String, Object?>{'jour': 3, 'debut': '08:00', 'fin': '12:00'},
          <String, Object?>{'jour': 7, 'debut': '20:00', 'fin': '24:00'},
        ],
      });
    });

    test('deux plages voisines d un meme jour forment un seul creneau', () {
      final CreneauxDeclares c = const CreneauxDeclares()
          .bascule(jour: 1, plage: 4)
          .bascule(jour: 1, plage: 5);
      final List<Object?> creneaux =
          c.versReponse('Europe/Paris')['creneaux']! as List<Object?>;
      expect(creneaux, <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '16:00', 'fin': '24:00'},
      ]);
    });

    test('jamais plus de 42 creneaux, meme avec une plage sur deux', () {
      CreneauxDeclares c = const CreneauxDeclares();
      for (int jour = 1; jour <= 7; jour++) {
        for (int plage = 0; plage < plagesParJour; plage += 2) {
          c = c.bascule(jour: jour, plage: plage);
        }
      }
      final List<Object?> creneaux =
          c.versReponse('Europe/Paris')['creneaux']! as List<Object?>;
      expect(creneaux.length, 21);
      expect(creneaux.length, lessThanOrEqualTo(42));
    });

    test('toutes les plages font exactement 42 cellules', () {
      expect(plagesParJour * joursParSemaine, 42);
      CreneauxDeclares c = const CreneauxDeclares();
      for (int jour = 1; jour <= 7; jour++) {
        for (int plage = 0; plage < plagesParJour; plage++) {
          c = c.bascule(jour: jour, plage: plage);
        }
      }
      expect(c.nombrePleines, 42);
      // Tout le jour, de 00:00 a 24:00 : un creneau par jour.
      expect(
        (c.versReponse('Europe/Paris')['creneaux']! as List<Object?>).length,
        7,
      );
    });

    test('la lecture d un creneau du serveur retrouve ses plages', () {
      final CreneauxDeclares c = CreneauxDeclares.depuisReponse(
        const <String, Object?>{
          'fuseau': 'Asia/Riyadh',
          'creneaux': <Map<String, Object?>>[
            <String, Object?>{'jour': 2, 'debut': '16:00', 'fin': '24:00'},
          ],
        },
      );
      expect(c.etat(jour: 2, plage: 4), EtatCellule.pleine);
      expect(c.etat(jour: 2, plage: 5), EtatCellule.pleine);
      expect(c.etat(jour: 2, plage: 3), EtatCellule.vide);
      expect(c.nombrePleines, 2);
    });

    test('un creneau a la demi-heure d ailleurs fait une cellule partielle', () {
      final CreneauxDeclares c = CreneauxDeclares.depuisReponse(
        const <String, Object?>{
          'fuseau': 'Asia/Riyadh',
          'creneaux': <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '20:00', 'fin': '22:00'},
          ],
        },
      );
      expect(c.etat(jour: 1, plage: 5), EtatCellule.partielle);
      expect(c.nombrePleines, 0);
      // Toucher une cellule partielle la remplit ; le creneau est alors entier.
      final CreneauxDeclares plein = c.bascule(jour: 1, plage: 5);
      expect(plein.etat(jour: 1, plage: 5), EtatCellule.pleine);
    });

    test('une valeur mal formee ne declare rien', () {
      expect(CreneauxDeclares.depuisReponse(null).estVide, isTrue);
      expect(CreneauxDeclares.depuisReponse('x').estVide, isTrue);
      expect(
        CreneauxDeclares.depuisReponse(const <String, Object?>{
          'creneaux': <Object>[
            <String, Object?>{'jour': 9, 'debut': '08:00', 'fin': '10:00'},
            <String, Object?>{'jour': 1, 'debut': '25:00', 'fin': '26:00'},
            <String, Object?>{'jour': 1, 'debut': '10:00', 'fin': '08:00'},
          ],
        }).estVide,
        isTrue,
      );
    });

    test('les bornes des plages', () {
      expect(heureDebutPlage(0), 0);
      expect(heureFinPlage(5), 24);
    });
  });
}
