/// La phrase dite quand le serveur refuse de creer une classe (CAND-Q15, lot
/// creer_groupe, 21/10/2026).
///
/// Une phrase par motif, qui dit quoi, pourquoi et quoi faire (K-59). Jamais
/// le texte SQL du serveur : il est technique, et en francais meme dans
/// l'interface arabe. Le motif inconnu a sa phrase generique.
///
/// C1 (02/11/2026, UX-020) : un chevauchement nomme la classe et l'heure en
/// conflit quand le serveur les donne (DETAIL, migration 20261105200000) ;
/// sinon la phrase d'avant, sans rien inventer.
library;

import '../../core/admin/creation_classe_refusee.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';

/// La phrase du refus [motif].
///
/// FN-113 : pour le maximum de Classes, [actives] et [maximum] viennent du
/// DETAIL du serveur ; sans eux, la phrase sans nombre. C1 : [conflit] nomme
/// la classe et l'heure d'un chevauchement.
String phraseRefusCreationClasse(
  MotifRefusCreationClasse motif, {
  int? actives,
  int? maximum,
  ConflitHoraire? conflit,
}) {
  final r = t.admin.groupes.refusCreation;
  final c1 = t.admin.groupes.c1;
  final String? classe = conflit?.classe;
  return switch (motif) {
    MotifRefusCreationClasse.plafondClasses =>
      actives != null && maximum != null
          ? r.plafondClasses(n: actives, maximum: maximum)
          : r.plafondClassesSansNombre,
    MotifRefusCreationClasse.creneaux => r.creneaux,
    MotifRefusCreationClasse.reservee => r.reservee,
    MotifRefusCreationClasse.compteEnseignant => r.compteEnseignant,
    MotifRefusCreationClasse.enseignantNonEligible => r.enseignantNonEligible,
    MotifRefusCreationClasse.genreIncompatible => r.genreIncompatible,
    MotifRefusCreationClasse.plafond => r.plafond,
    MotifRefusCreationClasse.chevauchementClasse =>
      conflit != null && classe != null
          ? c1.classeNommee(classe: classe, quand: quandConflit(conflit))
          : r.chevauchementClasse,
    MotifRefusCreationClasse.chevauchementSeance => switch (conflit) {
      null => r.chevauchementSeance,
      final ConflitHoraire c when classe != null => c1.seanceNommee(
        classe: classe,
        quand: quandConflit(c),
      ),
      final ConflitHoraire c => c1.seanceDatee(quand: quandConflit(c)),
    },
    MotifRefusCreationClasse.chevauchementCreneauxPropres => c1.creneauxPropres,
    MotifRefusCreationClasse.inconnu => r.inconnu,
  };
}

/// « lundi à 18 h, heure de Paris », ou « lundi 9 novembre à 18 h 30, heure
/// de Paris » pour une seance datee. La ville vient du fuseau
/// ([villeDuFuseauLibelle], jamais l'identifiant IANA brut). Les blancs de
/// l'heure sont insecables.
String quandConflit(ConflitHoraire conflit) {
  final c1 = t.admin.groupes.c1;
  final String jourNom = t.disponibilites.joursLongs[conflit.jour - 1];
  final String jour = _avecDate(jourNom, conflit.date);
  final String heure = LibellesGroupe.insecable(
    conflit.minute == 0
        ? c1.heurePleine(h: '${conflit.heure}')
        : c1.heureMinutes(
            h: '${conflit.heure}',
            mm: conflit.minute.toString().padLeft(2, '0'),
          ),
  );
  final String? fuseau = conflit.fuseau;
  return fuseau == null
      ? c1.quandSansVille(jour: jour, heure: heure)
      : c1.quand(jour: jour, heure: heure, ville: villeDuFuseauLibelle(fuseau));
}

/// « lundi 9 novembre » quand [date] (`AAAA-MM-JJ`) se lit ; sinon le jour
/// seul.
String _avecDate(String jour, String? date) {
  if (date == null) return jour;
  final List<String> morceaux = date.split('-');
  if (morceaux.length != 3) return jour;
  final int? mois = int.tryParse(morceaux[1]);
  final int? numero = int.tryParse(morceaux[2]);
  if (mois == null || numero == null || mois < 1 || mois > 12) return jour;
  return t.admin.groupes.c1.jourDate(
    jour: jour,
    numero: '$numero',
    mois: t.commun.dates.mois[mois - 1],
  );
}
