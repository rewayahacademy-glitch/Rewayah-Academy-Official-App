import 'package:flutter/widgets.dart';

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/groupe_reglages.dart';

/// Ce que le Foyer sait de la classe d'un membre.
///
/// Une lecture en cours, en echec ou sans service ne dit **rien** de la
/// classe sur la ligne : jamais « pas de classe » faute de savoir. La page
/// dit une seule fois, sous le groupe, que l'information manque
/// ([ClasseMembre.indisponible]).
sealed class ClasseMembre {
  const ClasseMembre();

  /// La lecture n'a pas encore abouti, ou a echoue.
  static const ClasseMembre inconnue = _Inconnue();

  /// Le port des classes n'a pas de service (contrat K5).
  static const ClasseMembre indisponible = _Indisponible();

  /// Ce que rend le port pour un membre.
  static ClasseMembre depuis(List<ClasseFoyer> classes) => classes.isEmpty
      ? const _SansClasse()
      : _Classes(<String>[
          for (final ClasseFoyer c in classes) c.classe.libelle,
        ]);
}

final class _Inconnue extends ClasseMembre {
  const _Inconnue();
}

final class _Indisponible extends ClasseMembre {
  const _Indisponible();
}

final class _SansClasse extends ClasseMembre {
  const _SansClasse();
}

final class _Classes extends ClasseMembre {
  const _Classes(this.libelles);

  final List<String> libelles;
}

/// La date d'une echeance d'acces, en toutes lettres : « 30 octobre 2026 ».
String dateEcheance(DateTime date) {
  final DateTime locale = date.toLocal();
  return t.foyer.membre.date(
    jour: locale.day.toString(),
    mois: t.commun.dates.mois[locale.month - 1],
    annee: locale.year.toString(),
  );
}

/// Le statut d'acces d'un membre, en texte (jamais la couleur seule).
///
/// Le calcul « expire » est un calcul **d'affichage** (`etatAccesAffiche`,
/// contrat K6) : le serveur fait deja foi, et une date passee ne se dit
/// jamais valide.
String statutAcces(ProfilEleveFoyer profil, DateTime maintenant) {
  final DateTime? fin = profil.finAcces;
  return switch (etatAccesAffiche(
    finAcces: fin,
    maintenantUtc: maintenant.toUtc(),
  )) {
    EtatAccesAffiche.sansEcheance => t.foyer.membre.accesSansEcheance,
    EtatAccesAffiche.actif => t.foyer.membre.accesJusquau(
      date: dateEcheance(fin!),
    ),
    EtatAccesAffiche.expire => t.foyer.membre.accesExpire(
      date: dateEcheance(fin!),
    ),
  };
}

/// La legende d'un membre : sa classe quand on la connait, puis son acces.
String legendeMembre({
  required ProfilEleveFoyer profil,
  required ClasseMembre classe,
  required DateTime maintenant,
}) {
  final String? texteClasse = switch (classe) {
    _Classes(:final List<String> libelles) => libelles.join(', '),
    _SansClasse() => t.foyer.membre.sansClasse,
    _Inconnue() || _Indisponible() => null,
  };
  final String acces = statutAcces(profil, maintenant);
  return texteClasse == null ? acces : '$texteClasse · $acces';
}

/// La ligne d'un membre du foyer dans le groupe des profils eleves.
///
/// Une rubrique du composant partage `GroupeReglages` : une surface pour tout
/// le groupe, un filet en retrait entre les membres, un chevron vers la fiche.
/// L'icone de profil tient la place de l'avatar tant que le composant partage
/// n'accepte pas d'autre tete de ligne (demande B-1 au coordinateur).
LigneRubrique ligneMembre({
  required ProfilEleveFoyer profil,
  required ClasseMembre classe,
  required DateTime maintenant,
  required VoidCallback onPress,
}) => LigneRubrique(
  icone: AppIcons.profil,
  libelle: profil.prenom,
  legende: legendeMembre(
    profil: profil,
    classe: classe,
    maintenant: maintenant,
  ),
  onPress: onPress,
);
