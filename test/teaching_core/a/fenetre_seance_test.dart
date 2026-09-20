import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/fenetre_seance.dart';

/// Une seance de 11:00 a 12:00 UTC, salle ouverte vingt minutes avant, quinze
/// minutes de grace apres la fin prevue.
///
/// **Vingt, et non dix.** La specification fixe la fenetre par defaut a T-20,
/// configurable ; la base, elle, refuse encore le jeton avant T-10. L'ecart est
/// reel et chiffre en section 4 de `TC_CONTRACT_REQUEST_A.md` : ces tests
/// mesurent ce que le produit doit faire, pas ce que la base sait faire
/// aujourd'hui.
FenetreSeance _fenetre({
  Duration acces = const Duration(minutes: 20),
  Duration grace = const Duration(minutes: 15),
}) => FenetreSeance(
  debutUtc: DateTime.utc(2026, 9, 21, 11),
  finPrevueUtc: DateTime.utc(2026, 9, 21, 12),
  fenetreAcces: acces,
  graceApresFin: grace,
);

void main() {
  group('FenetreSeance : les bornes', () {
    test('la salle ouvre exactement une fenetre avant le debut', () {
      expect(_fenetre().joinOpensAtUtc, DateTime.utc(2026, 9, 21, 10, 40));
    });

    test('la fenetre est une donnee, pas une constante du client', () {
      // Le meme objet avec une autre fenetre ouvre a une autre heure : rien
      // n'est fige a dix ni a vingt minutes dans ce code.
      final FenetreSeance courte = _fenetre(acces: const Duration(minutes: 5));
      expect(courte.joinOpensAtUtc, DateTime.utc(2026, 9, 21, 10, 55));
    });

    test('la grace borne la fin', () {
      expect(_fenetre().finGraceUtc, DateTime.utc(2026, 9, 21, 12, 15));
    });
  });

  group('FenetreSeance : la machine d etats', () {
    test('avant la fenetre', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 10, 30);
      expect(_fenetre().phaseA(maintenant), PhaseSeance.avantFenetre);
      expect(_fenetre().rejoindreOuvertA(maintenant), isFalse);
    });

    test('la seconde qui precede l ouverture laisse la porte fermee', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 10, 39, 59);
      expect(_fenetre().rejoindreOuvertA(maintenant), isFalse);
    });

    test('a T-20 pile, la salle est ouverte et la porte aussi', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 10, 40);
      expect(_fenetre().phaseA(maintenant), PhaseSeance.salleOuverte);
      expect(_fenetre().rejoindreOuvertA(maintenant), isTrue);
    });

    test('connecte avant T0, la phase est une attente', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 10, 50);
      expect(
        _fenetre().phaseA(maintenant, connecte: true),
        PhaseSeance.attenteAvantT0,
      );
    });

    test('a T0 pile, le cours commence', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 11);
      expect(_fenetre().phaseA(maintenant), PhaseSeance.enCours);
      expect(
        _fenetre().phaseA(maintenant, connecte: true),
        PhaseSeance.enCours,
      );
    });

    test('apres la fin prevue, une seance ouverte est prolongee', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 12, 5);
      expect(
        _fenetre().phaseA(maintenant, seanceOuverte: true),
        PhaseSeance.prolongee,
      );
      expect(_fenetre().rejoindreOuvertA(maintenant), isTrue);
    });

    test('apres la fin prevue, une seance close est terminee', () {
      final DateTime maintenant = DateTime.utc(2026, 9, 21, 12, 5);
      expect(
        _fenetre().phaseA(maintenant, seanceOuverte: false),
        PhaseSeance.terminee,
      );
      expect(
        _fenetre().rejoindreOuvertA(maintenant, seanceOuverte: false),
        isFalse,
      );
    });

    test('sans information du serveur, la grace tranche', () {
      expect(
        _fenetre().phaseA(DateTime.utc(2026, 9, 21, 12, 10)),
        PhaseSeance.prolongee,
      );
      expect(
        _fenetre().phaseA(DateTime.utc(2026, 9, 21, 12, 20)),
        PhaseSeance.terminee,
      );
    });
  });

  group('FenetreSeance : le temps restant', () {
    test('avant le debut, on compte jusqu au debut', () {
      expect(
        _fenetre().restantA(DateTime.utc(2026, 9, 21, 7, 32)),
        const Duration(hours: 3, minutes: 28),
      );
    });

    test('pendant, on compte jusqu a la fin prevue', () {
      expect(
        _fenetre().restantA(DateTime.utc(2026, 9, 21, 11, 32)),
        const Duration(minutes: 28),
      );
    });

    test('en prolongation, il n y a plus de nombre a montrer', () {
      // C'est LA regle : jamais un compte a rebours negatif.
      expect(
        _fenetre().restantA(
          DateTime.utc(2026, 9, 21, 12, 5),
          seanceOuverte: true,
        ),
        isNull,
      );
    });

    test('une fois terminee, il n y a plus de nombre du tout', () {
      expect(
        _fenetre().restantA(
          DateTime.utc(2026, 9, 21, 12, 30),
          seanceOuverte: false,
        ),
        isNull,
      );
    });

    test('aucun restant n est jamais negatif', () {
      for (final DateTime instant in <DateTime>[
        DateTime.utc(2026, 9, 21, 9),
        DateTime.utc(2026, 9, 21, 10, 40),
        DateTime.utc(2026, 9, 21, 11),
        DateTime.utc(2026, 9, 21, 11, 59),
        DateTime.utc(2026, 9, 21, 12),
        DateTime.utc(2026, 9, 21, 13),
      ]) {
        final Duration? reste = _fenetre().restantA(instant);
        expect(
          reste == null || !reste.isNegative,
          isTrue,
          reason: 'restant negatif a $instant',
        );
      }
    });
  });

  group('FenetreSeance : les changements d heure', () {
    test('aucune regle de fuseau n est appliquee ici', () {
      // La nuit du passage a l'heure d'hiver en Europe dure vingt-cinq heures
      // en heure locale, mais vingt-quatre en UTC. Une fenetre ancree en UTC
      // traverse donc la transition sans bouger d'une minute : c'est
      // exactement ce qu'un offset code en dur casserait.
      final FenetreSeance traversante = FenetreSeance(
        debutUtc: DateTime.utc(2026, 10, 25, 0, 30),
        finPrevueUtc: DateTime.utc(2026, 10, 25, 2),
        fenetreAcces: const Duration(minutes: 20),
        graceApresFin: const Duration(minutes: 15),
      );
      expect(traversante.joinOpensAtUtc, DateTime.utc(2026, 10, 25, 0, 10));
      expect(
        traversante.restantA(DateTime.utc(2026, 10, 25, 0, 20)),
        const Duration(minutes: 10),
      );
    });
  });
}
