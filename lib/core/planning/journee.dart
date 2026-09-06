import 'package:flutter/foundation.dart';

import '../priere/horaires_priere.dart';
import '../priere/reglages_priere.dart';
import 'service_planning.dart';

/// Ce qu'une entree de journee peut etre.
///
/// L'ordre des valeurs est celui du tri a heure egale : une interruption qui
/// commence a la minute ou un cours commence appartient a ce cours, elle vient
/// donc apres lui.
enum SorteEntree {
  /// Un cours.
  cours,

  /// Le temps entre deux cours.
  pause,

  /// Une interruption de priere.
  priere,
}

/// Une ligne de la journee, quel que soit le role qui la lit.
///
/// Les specs produit demandent pour `ENS-02` **une seule colonne du haut vers
/// le bas**, ou les cours, les pauses et les prieres sont des entrees de meme
/// nature. Un bloc « prieres » separe les sortirait du deroule de la journee,
/// et c'est exactement ce que l'ADR-017 refuse : l'interruption doit se voir a
/// sa place, avant le cours et non pendant.
@immutable
class EntreeJournee {
  /// Un cours.
  EntreeJournee.cours(Seance this.seance)
    : sorte = SorteEntree.cours,
      debut = seance.debut,
      fin = seance.fin,
      interruption = null;

  /// Une interruption de priere.
  EntreeJournee.priere(InterruptionPriere this.interruption)
    : sorte = SorteEntree.priere,
      debut = interruption.debut,
      fin = interruption.fin,
      seance = null;

  /// Le temps entre deux cours.
  const EntreeJournee.pause({required this.debut, required this.fin})
    : sorte = SorteEntree.pause,
      seance = null,
      interruption = null;

  /// De quelle nature elle est.
  final SorteEntree sorte;

  /// Quand elle commence, dans le fuseau de l'appareil.
  final DateTime debut;

  /// Quand elle se termine.
  final DateTime fin;

  /// Le cours, quand c'en est un.
  final Seance? seance;

  /// L'interruption, quand c'en est une.
  final InterruptionPriere? interruption;

  /// Combien de temps elle occupe.
  Duration get duree => fin.difference(debut);
}

/// La journee telle que les trois roles la lisent, cours, pauses et prieres
/// dans une seule liste triee.
///
/// [pauseMaximale] vient de `regle_effective()`, jamais d'une constante : c'est
/// elle qui dit a partir de quand un trou entre deux cours cesse d'etre une
/// pause pour devenir du temps libre, et elle peut differer d'un profil a
/// l'autre (ADR-017 section 2.4, invariant I10).
///
/// Les seances annulees sont ecartees : elles n'occupent pas la journee et ne
/// creent donc aucune pause entre elles et la suivante. Leur etat se lit sur
/// l'ecran de l'eleve, pas dans cette colonne.
List<EntreeJournee> construireJournee({
  required List<Seance> seances,
  required ReglagesPriere? reglages,
  required DateTime debut,
  required DateTime fin,
  required Duration pauseMaximale,
}) {
  final List<Seance> retenues =
      seances
          .where(
            (Seance seance) =>
                (seance.statut?.estAnnulee ?? false) == false &&
                seance.debut.isBefore(fin) &&
                seance.fin.isAfter(debut),
          )
          .toList()
        ..sort((Seance a, Seance b) => a.debut.compareTo(b.debut));

  final List<EntreeJournee> entrees = <EntreeJournee>[
    for (final Seance seance in retenues) EntreeJournee.cours(seance),
  ];

  for (int i = 0; i + 1 < retenues.length; i++) {
    final DateTime finPrecedente = retenues[i].fin;
    final DateTime debutSuivante = retenues[i + 1].debut;
    final Duration trou = debutSuivante.difference(finPrecedente);
    if (trou > Duration.zero && trou <= pauseMaximale) {
      entrees.add(
        EntreeJournee.pause(debut: finPrecedente, fin: debutSuivante),
      );
    }
  }

  if (reglages != null) {
    entrees.addAll(
      interruptionsEntre(
        reglages: reglages,
        debut: debut,
        fin: fin,
      ).map(EntreeJournee.priere),
    );
  }

  entrees.sort((EntreeJournee a, EntreeJournee b) {
    final int parHeure = a.debut.compareTo(b.debut);
    return parHeure != 0 ? parHeure : a.sorte.index.compareTo(b.sorte.index);
  });
  return entrees;
}

/// Les interruptions prevues pendant une seance.
///
/// C'est ce que `ELV-02` annonce avant le cours : l'eleve et son tuteur voient
/// les interruptions a l'avance, pas au moment ou elles arrivent.
List<InterruptionPriere> interruptionsDe(
  Seance seance,
  ReglagesPriere? reglages,
) => reglages == null
    ? const <InterruptionPriere>[]
    : interruptionsEntre(
        reglages: reglages,
        debut: seance.debut,
        fin: seance.fin,
      );
