import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
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

/// Le cours qui occupe le bloc dominant : celui qui se tient maintenant, sinon
/// le prochain a venir.
///
/// **Volontairement non borne a la journee courante.** Un enseignant dont la
/// journee est finie doit lire quand il reprend, pas un bloc vide : la colonne
/// dit ce qu'est aujourd'hui, ce bloc dit ce qui vient. Les seances annulees
/// sont ecartees, comme dans [construireJournee] : ce qui n'aura pas lieu ne
/// peut pas etre le prochain cours.
///
/// Un cours que la base declare `en_cours` l'emporte sur l'heure : un cours qui
/// deborde reste le bloc dominant, sinon l'enseignant lirait le suivant alors
/// qu'il est encore dans le premier.
Seance? prochainCours(List<Seance> seances, DateTime maintenant) {
  final List<Seance> retenues =
      seances
          .where((Seance seance) => (seance.statut?.estAnnulee ?? false) == false)
          .toList()
        ..sort((Seance a, Seance b) => a.debut.compareTo(b.debut));

  for (final Seance seance in retenues) {
    if (seance.statut == StatutSeance.enCours) {
      return seance;
    }
  }
  for (final Seance seance in retenues) {
    if (maintenant.isBefore(seance.fin)) {
      return seance;
    }
  }
  return null;
}

/// La seance annulee qu'on attendait encore aujourd'hui.
///
/// [prochainCours] ecarte les seances annulees, et c'est ce qu'il faut pour un
/// bloc qui dit « ce qui vient ». Mais un enfant qui ouvre son ecran a l'heure
/// de son cours doit apprendre qu'il n'aura pas lieu, sinon il attend devant un
/// ecran qui ne dit rien. C'est le cinquieme etat de `ELV-02`, et l'un des cinq
/// etats par enfant de `TUT-01` : la fonction vit donc ici, avec
/// [prochainCours], et non dans un ecran.
///
/// Ne sont retenues que les seances du jour civil courant qui ne sont pas encore
/// passees : une annulation d'hier n'a plus rien a annoncer. Bornes du jour
/// calculees en composantes de date, jamais par addition de vingt-quatre heures.
Seance? seanceAnnuleeDuJour(List<Seance> seances, DateTime maintenant) {
  final DateTime debutJour = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  final DateTime finJour = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day + 1,
  );

  final List<Seance> retenues =
      seances
          .where(
            (Seance seance) =>
                (seance.statut?.estAnnulee ?? false) &&
                seance.debut.isBefore(finJour) &&
                !seance.debut.isBefore(debutJour) &&
                maintenant.isBefore(seance.fin),
          )
          .toList()
        ..sort((Seance a, Seance b) => a.debut.compareTo(b.debut));

  return retenues.isEmpty ? null : retenues.first;
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
