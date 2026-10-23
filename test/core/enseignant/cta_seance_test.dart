// CTA-FIN-1 : le bouton principal d'une seance selon son moment. Toutes les
// transitions, sans widget : l'etat sort de l'heure, du statut de la salle et
// du cahier. Jamais de bouton grise : chaque etat a un sens.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/cta_seance.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';

import '../../support/harnais.dart';

const Duration _fenetre = Duration(minutes: 10);
const Duration _grace = Duration(minutes: 15);

/// Seance de 45 minutes : 17 h 30 a 18 h 15.
final DateTime _debut = DateTime(2026, 9, 28, 17, 30);
final DateTime _fin = DateTime(2026, 9, 28, 18, 15);

CtaSeance _cta(
  DateTime maintenant, {
  StatutSeance? statut = StatutSeance.planifiee,
  bool cahierDepose = false,
}) => ctaSeance(
  maintenant: maintenant,
  debut: _debut,
  fin: _fin,
  cahierDepose: cahierDepose,
  statut: statut,
  fenetreAcces: _fenetre,
  graceApresFin: _grace,
);

void main() {
  group('ctaSeance : les transitions dans l ordre du temps', () {
    test('avant l ouverture de la salle : Preparer la seance', () {
      final CtaSeance c = _cta(DateTime(2026, 9, 28, 9));
      expect(c.etat, EtatCtaSeance.preparer);
      expect(c.enDirect, isFalse);
      // Une minute avant l'ouverture (T-10) : encore Preparer.
      expect(
        _cta(DateTime(2026, 9, 28, 17, 19, 59)).etat,
        EtatCtaSeance.preparer,
      );
    });

    test(
      'salle ouverte avant T0 : Rejoindre la salle, pas encore en direct',
      () {
        final CtaSeance c = _cta(DateTime(2026, 9, 28, 17, 20));
        expect(c.etat, EtatCtaSeance.rejoindre);
        expect(c.enDirect, isFalse);
        expect(_cta(DateTime(2026, 9, 28, 17, 29)).enDirect, isFalse);
      },
    );

    test('pendant le creneau : Rejoindre la salle et En direct', () {
      for (final DateTime m in <DateTime>[
        _debut,
        DateTime(2026, 9, 28, 17, 50),
        DateTime(2026, 9, 28, 18, 14, 59),
      ]) {
        final CtaSeance c = _cta(m);
        expect(c.etat, EtatCtaSeance.rejoindre, reason: '$m');
        expect(c.enDirect, isTrue, reason: '$m');
      }
    });

    test('temps ecoule, cahier non depose : Remplir le cahier', () {
      final CtaSeance c = _cta(
        DateTime(2026, 9, 28, 18, 40),
        statut: StatutSeance.terminee,
      );
      expect(c.etat, EtatCtaSeance.remplirCahier);
      expect(c.enDirect, isFalse);
    });

    test('temps ecoule, cahier depose : Voir le cahier', () {
      final CtaSeance c = _cta(
        DateTime(2026, 9, 28, 18, 40),
        statut: StatutSeance.terminee,
        cahierDepose: true,
      );
      expect(c.etat, EtatCtaSeance.voirCahier);
    });
  });

  group('ctaSeance : un cours qui deborde', () {
    test(
      'salle ouverte apres la fin prevue : Rejoindre, meme apres la grace',
      () {
        for (final DateTime m in <DateTime>[
          DateTime(2026, 9, 28, 18, 15),
          DateTime(2026, 9, 28, 18, 29),
          DateTime(2026, 9, 28, 19, 30),
        ]) {
          final CtaSeance c = _cta(m, statut: StatutSeance.enCours);
          expect(c.etat, EtatCtaSeance.rejoindre, reason: '$m');
          expect(c.enDirect, isTrue, reason: '$m');
        }
      },
    );

    test('la salle se ferme : le bouton passe au cahier', () {
      final DateTime m = DateTime(2026, 9, 28, 18, 30);
      expect(
        _cta(m, statut: StatutSeance.enCours).etat,
        EtatCtaSeance.rejoindre,
      );
      expect(
        _cta(m, statut: StatutSeance.terminee).etat,
        EtatCtaSeance.remplirCahier,
      );
    });

    test('sans statut lisible, la grace tranche', () {
      expect(
        _cta(DateTime(2026, 9, 28, 18, 20), statut: null).etat,
        EtatCtaSeance.rejoindre,
      );
      expect(
        _cta(DateTime(2026, 9, 28, 18, 31), statut: null).etat,
        EtatCtaSeance.remplirCahier,
      );
    });
  });

  group('ctaSeance : cas limites', () {
    test('un cours clos en avance passe au cahier sans attendre la fin', () {
      final CtaSeance c = _cta(
        DateTime(2026, 9, 28, 17, 50),
        statut: StatutSeance.terminee,
      );
      expect(c.etat, EtatCtaSeance.remplirCahier);
      expect(c.enDirect, isFalse);
    });

    test('eleve absent et incident technique : le cahier reste du', () {
      for (final StatutSeance s in <StatutSeance>[
        StatutSeance.eleveAbsent,
        StatutSeance.incidentTechnique,
      ]) {
        expect(
          _cta(DateTime(2026, 9, 28, 18, 40), statut: s).etat,
          EtatCtaSeance.remplirCahier,
        );
      }
    });

    test('annulee ou enseignant absent : Voir la Classe, a toute heure', () {
      for (final StatutSeance s in <StatutSeance>[
        StatutSeance.annulee,
        StatutSeance.annuleeTard,
        StatutSeance.enseignantAbsent,
      ]) {
        for (final DateTime m in <DateTime>[
          DateTime(2026, 9, 28, 9),
          DateTime(2026, 9, 28, 17, 45),
          DateTime(2026, 9, 28, 20),
        ]) {
          expect(
            _cta(m, statut: s).etat,
            EtatCtaSeance.voirClasse,
            reason: '$s $m',
          );
        }
      }
    });

    test('toujours un sens : aucun instant ne laisse l etat sans reponse', () {
      for (int minute = 0; minute < 24 * 60; minute += 5) {
        final DateTime m = DateTime(2026, 9, 28).add(Duration(minutes: minute));
        for (final StatutSeance? s in <StatutSeance?>[
          null,
          ...StatutSeance.values,
        ]) {
          for (final bool depose in <bool>[false, true]) {
            expect(
              () => _cta(m, statut: s, cahierDepose: depose),
              returnsNormally,
            );
          }
        }
      }
    });
  });

  group('seanceDeLaCarte : la seance dont le bouton agit', () {
    SeanceEnseignant seance(
      String id,
      int heure, {
      StatutSeance statut = StatutSeance.planifiee,
      bool depose = false,
    }) => seanceDeTest(
      id: id,
      debut: DateTime(2026, 9, 28, heure),
      statut: statut,
      cahierDepose: depose,
    );

    SeanceEnseignant? choisir(List<SeanceEnseignant> l, DateTime m) =>
        seanceDeLaCarte(l, m, fenetreAcces: _fenetre, graceApresFin: _grace);

    test('rien a montrer : aucune seance', () {
      expect(
        choisir(const <SeanceEnseignant>[], DateTime(2026, 9, 28, 9)),
        isNull,
      );
    });

    test('la salle ouverte passe avant tout', () {
      final SeanceEnseignant en = seance('a', 9, statut: StatutSeance.enCours);
      final SeanceEnseignant suivante = seance('b', 14);
      expect(
        choisir(<SeanceEnseignant>[
          suivante,
          en,
        ], DateTime(2026, 9, 28, 10, 20))?.id,
        'a',
      );
    });

    test('le cahier manquant passe avant la seance suivante', () {
      final SeanceEnseignant finie = seance(
        'a',
        9,
        statut: StatutSeance.terminee,
      );
      final SeanceEnseignant suivante = seance('b', 14);
      expect(
        choisir(<SeanceEnseignant>[
          finie,
          suivante,
        ], DateTime(2026, 9, 28, 11))?.id,
        'a',
      );
    });

    test('la salle de la suivante ouverte l emporte sur le cahier', () {
      final SeanceEnseignant finie = seance(
        'a',
        9,
        statut: StatutSeance.terminee,
      );
      final SeanceEnseignant suivante = seance('b', 11);
      expect(
        choisir(<SeanceEnseignant>[
          finie,
          suivante,
        ], DateTime(2026, 9, 28, 10, 55))?.id,
        'b',
      );
    });

    test('cahier depose et rien apres : Voir le cahier', () {
      final SeanceEnseignant finie = seance(
        'a',
        9,
        statut: StatutSeance.terminee,
        depose: true,
      );
      expect(
        choisir(<SeanceEnseignant>[finie], DateTime(2026, 9, 28, 11))?.id,
        'a',
      );
    });

    test('cahier depose et une seance a venir : la seance a venir', () {
      final SeanceEnseignant finie = seance(
        'a',
        9,
        statut: StatutSeance.terminee,
        depose: true,
      );
      final SeanceEnseignant suivante = seance('b', 14);
      expect(
        choisir(<SeanceEnseignant>[
          finie,
          suivante,
        ], DateTime(2026, 9, 28, 11))?.id,
        'b',
      );
    });

    test('une seance annulee n est jamais retenue', () {
      final SeanceEnseignant annulee = seance(
        'a',
        9,
        statut: StatutSeance.annulee,
      );
      expect(
        choisir(<SeanceEnseignant>[annulee], DateTime(2026, 9, 28, 8)),
        isNull,
      );
    });

    test('un cahier d un autre jour reste a la rubrique A terminer', () {
      final SeanceEnseignant hier = seanceDeTest(
        id: 'h',
        debut: DateTime(2026, 9, 27, 9),
        statut: StatutSeance.terminee,
      );
      expect(
        choisir(<SeanceEnseignant>[hier], DateTime(2026, 9, 28, 11)),
        isNull,
      );
    });
  });
}
