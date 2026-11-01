/// La phrase dite quand le serveur refuse de creer une classe (CAND-Q15, lot
/// creer_groupe, 21/10/2026).
///
/// Une phrase par motif, qui dit quoi, pourquoi et quoi faire (K-59). Jamais
/// le texte SQL du serveur : il est technique, et en francais meme dans
/// l'interface arabe. Le motif inconnu a sa phrase generique.
library;

import '../../core/admin/creation_classe_refusee.dart';
import '../../core/i18n/strings.g.dart';

/// La phrase du refus [motif].
///
/// FN-113 : pour le maximum de Classes, [actives] et [maximum] viennent du
/// DETAIL du serveur ; sans eux, la phrase sans nombre.
String phraseRefusCreationClasse(
  MotifRefusCreationClasse motif, {
  int? actives,
  int? maximum,
}) {
  final r = t.admin.groupes.refusCreation;
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
    MotifRefusCreationClasse.chevauchementClasse => r.chevauchementClasse,
    MotifRefusCreationClasse.chevauchementSeance => r.chevauchementSeance,
    MotifRefusCreationClasse.inconnu => r.inconnu,
  };
}
