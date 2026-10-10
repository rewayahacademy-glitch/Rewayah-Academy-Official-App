/// Les libelles du genre d'une classe et de la proposition d'enseignant,
/// communs a la creation d'une classe (CLASSE-FORM-1, `groupes_page.dart`) et
/// a la creation depuis des demandes semblables (OFFRES-ADM-1,
/// `admin_regroupements`).
///
/// Sortis tels quels de `groupes_page.dart` : une seule source pour les
/// cartes de genre, les raisons d'indisponibilite et la mention « Premier
/// choix », jamais deux copies qui finiraient par diverger.
library;

import '../../core/admin/enseignants_classe.dart';
import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/i18n/strings.g.dart';

/// Le genre de la classe dit selon le public (accord par contexte).
String libelleGenreClasse(GenreClasse genre, TypePublicGroupe type) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch (genre) {
    GenreClasse.hommes => enfants ? f.genreGarcons : f.genreHommes,
    GenreClasse.femmes => enfants ? f.genreFilles : f.genreFemmes,
    GenreClasse.indetermine => f.genreIndetermine,
  };
}

/// Quand choisir ce genre, et ce qu'il change (K-58).
///
/// La consequence annoncee est celle qui se produit : quand la source ne dit
/// le genre d'aucun enseignant ([genreConnu] faux, repli sur les comptes),
/// la liste n'ecarte personne, et la phrase le dit au lieu de promettre un
/// filtre qui n'a pas lieu (D1 : ne rien pretendre).
String detailGenreClasse(
  GenreClasse genre,
  TypePublicGroupe type, {
  required bool genreConnu,
}) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch ((genre, genreConnu)) {
    (GenreClasse.hommes, true) =>
      enfants ? f.genreGarconsDetail : f.genreHommesDetail,
    (GenreClasse.hommes, false) =>
      enfants ? f.genreGarconsDetailSansSource : f.genreHommesDetailSansSource,
    (GenreClasse.femmes, true) =>
      enfants ? f.genreFillesDetail : f.genreFemmesDetail,
    (GenreClasse.femmes, false) =>
      enfants ? f.genreFillesDetailSansSource : f.genreFemmesDetailSansSource,
    (GenreClasse.indetermine, _) => f.genreIndetermineDetail,
  };
}

/// Pourquoi un enseignant ne peut pas prendre une classe de ce genre (D4).
String raisonGenreClasse(GenreClasse genre, TypePublicGroupe type) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch (genre) {
    GenreClasse.hommes => enfants ? f.raisonGarcons : f.raisonHommes,
    GenreClasse.femmes => enfants ? f.raisonFilles : f.raisonFemmes,
    // Un genre non determine accepte tout le monde (D2) : aucune raison
    // d'indisponibilite n'existe, et aucune phrase hors sujet ne s'affiche.
    GenreClasse.indetermine => throw StateError(
      'Aucun enseignant n est incompatible avec une classe sans genre (D2).',
    ),
  };
}

/// Le message qui dit pourquoi l'enseignant choisi ne peut pas prendre la
/// classe, et quoi faire : une phrase complete par cause, avec son nom (pas
/// d'accord a deviner, K-41).
String manqueEnseignantClasse(
  EnseignantClasse choisi,
  GenreClasse genre,
  TypePublicGroupe type,
) {
  final f = t.admin.groupes.formulaire;
  final String nom = choisi.enseignant.libelle;
  final bool enfants = type == TypePublicGroupe.enfant;
  if (choisi.genreCompatible == false) {
    return switch (genre) {
      GenreClasse.hommes =>
        enfants
            ? f.manqueEnseignantGarcons(nom: nom)
            : f.manqueEnseignantHommes(nom: nom),
      GenreClasse.femmes =>
        enfants
            ? f.manqueEnseignantFilles(nom: nom)
            : f.manqueEnseignantFemmes(nom: nom),
      GenreClasse.indetermine => throw StateError(
        'Aucun enseignant n est incompatible avec une classe sans genre (D2).',
      ),
    };
  }
  return f.manqueEnseignantPris(nom: nom);
}

/// « 2 classes en cours », « aucune classe en cours ».
String chargeEnseignant(int classes) => classes == 0
    ? t.admin.groupes.formulaire.aucuneClasse
    : t.admin.groupes.formulaire.classesEnCours(n: classes);

/// La raison pour laquelle cet enseignant ne se choisit pas, ou nul.
String? raisonEnseignant(
  EnseignantClasse l,
  GenreClasse? genre,
  TypePublicGroupe type,
) {
  if (l.genreCompatible == false && genre != null) {
    return raisonGenreClasse(genre, type);
  }
  if (l.pris) return t.admin.groupes.formulaire.raisonPris;
  return null;
}

/// La mention sous le nom : « le plus adapte » et sa raison (D5), ou
/// « pas libre a ce creneau » pour un enseignant qui reste choisissable.
String? mentionEnseignant(EnseignantClasse l, {required bool avecCreneau}) {
  final f = t.admin.groupes.formulaire;
  final String charge = chargeEnseignant(l.enseignant.classesActives);
  if (l.plusAdapte) {
    return avecCreneau
        ? f.plusAdapteCreneau(charge: charge)
        : f.plusAdapteSansCreneau(
            libres: f.creneauxLibres(
              n: l.enseignant.creneauxLibres?.length ?? 0,
            ),
            charge: charge,
          );
  }
  if (avecCreneau && l.choisissable && l.libre == false) return f.pasLibre;
  return null;
}
