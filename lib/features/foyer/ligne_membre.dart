import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/widgets/groupe_reglages.dart';

/// Ce que le Foyer sait de la classe d'un membre.
///
/// Une lecture en cours ou sans service ne dit **rien** de la classe sur la
/// ligne : jamais « pas de classe » faute de savoir. La page dit une seule
/// fois, sous le groupe, que l'information manque
/// ([ClasseMembre.indisponible]). Une lecture **en echec** n'est ni l'une ni
/// l'autre : elle se dit comme un echec, avec un moyen de relire
/// ([ClasseMembre.echec]).
sealed class ClasseMembre {
  const ClasseMembre();

  /// La lecture n'a pas encore abouti.
  static const ClasseMembre inconnue = _Inconnue();

  /// Le port des classes n'a pas de service (contrat K5).
  static const ClasseMembre indisponible = _Indisponible();

  /// Le port a un service, mais la lecture a echoue.
  static const ClasseMembre echec = _Echec();

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

final class _Echec extends ClasseMembre {
  const _Echec();
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

/// Ce que l'ecran dit d'une etape du parcours d'inscription : « A remplir »,
/// « Classe en cours de constitution ». Partage par le Foyer et la page
/// « Parcours et inscription » de la fiche : les deux disent la meme chose du
/// meme eleve.
String libelleEtapeFiche(EtapeParcours etape) => switch (etape) {
  EtapeParcours.aPersonnaliser => t.ficheEleve.inscription.aRemplir,
  EtapeParcours.horaireAChoisir => t.ficheEleve.inscription.horaireAChoisir,
  EtapeParcours.offreIndisponible => t.ficheEleve.inscription.horaireRetire,
  EtapeParcours.diagnosticRequis => t.ficheEleve.inscription.echangeAPrevoir,
  EtapeParcours.diagnosticEnAttente => t.ficheEleve.inscription.echangePrevu,
  EtapeParcours.groupeEnFormation =>
    t.ficheEleve.inscription.classeEnConstitution,
  EtapeParcours.groupeConfirme => t.ficheEleve.inscription.classeConfirmee,
};

/// L'etape d'inscription d'un eleve lue dans `v_parcours_onboarding`, ou
/// `null` quand la lecture n'a pas abouti ou ne connait pas l'eleve.
EtapeParcours? etapeInscriptionLue(
  AsyncValue<List<ParcoursApprenant>> parcours,
  String eleveId,
) {
  if (!parcours.hasValue || parcours.hasError) {
    return null;
  }
  for (final ParcoursApprenant p in parcours.requireValue) {
    if (p.eleveId == eleveId) {
      return etapeParcours(p);
    }
  }
  return null;
}

/// La legende d'un membre : sa classe quand on la connait, sinon son
/// inscription en cours quand on la connait, puis son acces.
String legendeMembre({
  required ProfilEleveFoyer profil,
  required ClasseMembre classe,
  required DateTime maintenant,
  EtapeParcours? inscription,
}) {
  final String? classeLue = classe is _Classes || inscription == null
      ? texteClasse(classe)
      : libelleEtapeFiche(inscription);
  final String acces = statutAcces(profil, maintenant);
  return classeLue == null ? acces : '$classeLue · $acces';
}

/// Ce que la lecture du port des classes dit d'un membre.
ClasseMembre classeMembreLue(AsyncValue<List<ClasseFoyer>> lecture) {
  if (lecture.hasValue && !lecture.hasError) {
    return ClasseMembre.depuis(lecture.requireValue);
  }
  if (lecture.error is CapaciteIndisponible) {
    return ClasseMembre.indisponible;
  }
  if (lecture.hasError) {
    return ClasseMembre.echec;
  }
  return ClasseMembre.inconnue;
}

/// Vrai quand le port des classes n'a pas de service (contrat K5).
bool classeIndisponible(ClasseMembre classe) => classe is _Indisponible;

/// Vrai quand la lecture des classes a echoue alors que le port a un service.
bool classeEnEchec(ClasseMembre classe) => classe is _Echec;

/// Ce que l'ecran dit de la classe d'un membre, ou `null` quand il n'en sait
/// rien (lecture en cours ou sans service) : jamais « pas de classe » faute
/// de savoir. Une lecture en echec se dit « classe non lue ». Partage par le
/// Foyer et la fiche eleve.
String? texteClasse(ClasseMembre classe) => switch (classe) {
  _Classes(:final List<String> libelles) => libelles.join(', '),
  _SansClasse() => t.foyer.membre.sansClasse,
  _Echec() => t.foyer.membre.classeEchec,
  _Inconnue() || _Indisponible() => null,
};

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
  EtapeParcours? inscription,
}) => LigneRubrique(
  icone: AppIcons.profil,
  libelle: profil.prenom,
  legende: legendeMembre(
    profil: profil,
    classe: classe,
    maintenant: maintenant,
    inscription: inscription,
  ),
  onPress: onPress,
);
