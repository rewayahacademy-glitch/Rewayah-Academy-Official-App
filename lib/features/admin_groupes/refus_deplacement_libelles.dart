/// La phrase dite quand le serveur refuse de DEPLACER une classe qui a deja son
/// enseignant (CLASSES-DUREE, 23/10/2026).
///
/// Le motif est celui du refus d'affectation (`AffectationRefusee`) : le serveur
/// repasse le meme predicat quand le jour, l'heure ou le fuseau change. Une
/// phrase par motif, qui dit quoi, pourquoi et quoi faire (K-59). Jamais le
/// texte SQL du serveur : il est technique, et en francais meme dans
/// l'interface arabe. Les phrases de la confirmation d'un enseignant
/// (`regroupements`) disent « l'enseignant n'est pas confirme » : elles ne
/// conviennent pas ici, d'ou ces phrases-ci pour le meme type.
library;

import '../../core/i18n/strings.g.dart';
import '../../core/offres/affectation_refusee.dart';

/// La phrase du refus quand la feuille « Seuil maximal » est refusee : elle
/// renvoie l'horaire qu'elle a lu dans la liste, qui peut etre perime (la
/// phrase du motif parlerait d'un horaire que la personne n'a pas touche).
String phraseRefusSeuil() => t.admin.groupes.refusDeplacement.seuil;

/// La phrase du refus de deplacement [motif].
String phraseRefusDeplacement(MotifRefusAffectation motif) {
  final r = t.admin.groupes.refusDeplacement;
  return switch (motif) {
    MotifRefusAffectation.enseignantIndisponible => r.enseignantIndisponible,
    MotifRefusAffectation.genreIncompatible => r.genreIncompatible,
    MotifRefusAffectation.plafond => r.plafond,
    MotifRefusAffectation.nonDisponible => r.nonDisponible,
    MotifRefusAffectation.chevauchementClasse => r.chevauchementClasse,
    MotifRefusAffectation.chevauchementSeance => r.chevauchementSeance,
    MotifRefusAffectation.reservee ||
    MotifRefusAffectation.classeIndisponible ||
    MotifRefusAffectation.inconnu => r.inconnu,
  };
}
