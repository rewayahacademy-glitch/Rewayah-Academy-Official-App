// S0 (pilote, 24/10/2026) : ce que `/salle` donne a la salle de seance et
// qu'elle n'avait qu'en demonstration -- la vraie video, la vraie page du
// Coran, et les gestes du zoom.
//
// Meme forme que `PorteeSupportRecu` : la salle de seance reste pure (elle
// ne lit aucun moteur), `/salle` pose la portee autour d'elle. Absente
// (demonstration, tests d'ecran) : rien ne change, l'aplat et la page neutre
// restent.

import 'package:flutter/widgets.dart';

import 'vue_seance.dart';

/// Les paliers du zoom local de la page (directeur, 24/10/2026) : 100, 125,
/// 150 et 200 %.
const List<double> paliersZoom = <double>[1, 1.25, 1.5, 2];

/// Le palier au-dessus de [zoom], ou `null` au dernier : le bouton n'est
/// alors pas rendu (jamais grise).
double? palierSuivant(double zoom) {
  for (final double p in paliersZoom) {
    if (p > zoom + 0.001) return p;
  }
  return null;
}

/// Le palier au-dessous de [zoom], ou `null` au premier.
double? palierPrecedent(double zoom) {
  for (final double p in paliersZoom.reversed) {
    if (p < zoom - 0.001) return p;
  }
  return null;
}

/// Le zoom d'un pincement, borne aux paliers extremes.
double zoomBorne(double zoom) =>
    zoom.clamp(paliersZoom.first, paliersZoom.last).toDouble();

/// La portee des medias reels de `/salle`.
class PorteeMediaSalle extends InheritedWidget {
  const PorteeMediaSalle({
    required super.child,
    this.video,
    this.identiteVignette,
    this.page,
    this.onZoom,
    this.scene,
    this.scenePremierPlan = false,
    this.onBasculerScene,
    this.actionScene,
    this.pastille,
    this.alerte,
    this.pleinCadre = false,
    this.eleves,
    this.onPagePrecedente,
    this.onPageSuivante,
    super.key,
  });

  /// La scene video de `/salle` (les cameras en grand, ADR-001 : les
  /// makharij se lisent sur une bouche), ou `null`.
  final Widget? scene;

  /// La scene prend l'espace principal, a la place de la page.
  final bool scenePremierPlan;

  /// Toucher la vignette met la scene au premier plan ; « Revenir a la
  /// page » la renvoie. `null` : rien a basculer (aucune page derriere).
  final VoidCallback? onBasculerScene;

  /// Le bouton de coin de la scene au premier plan, a la place de
  /// « Revenir a la page » : l'enseignant sans page ouvre le Coran.
  final ({String libelle, VoidCallback onPress})? actionScene;

  /// S0.2 : la pastille posee dans la ligne de l'en-tete (la presence de
  /// l'eleve, section 6.6), ou `null`.
  final Widget? pastille;

  /// S0.2 : ce qui se dit sous l'en-tete, seulement quand il y a lieu (le
  /// refus de la camera, D14), ou `null`.
  final Widget? alerte;

  /// S0.2 : la salle de `/salle` en plein cadre : en-tete sur une ligne,
  /// commandes en surimpression, scene sur toute la hauteur restante.
  final bool pleinCadre;

  /// S0.2 : le contenu du panneau Eleves de l'enseignant (colonne ou
  /// panneau) : la presence (J3) et le roster reel, ou `null`.
  final Widget? eleves;

  /// S0.2 (reference 4 du directeur) : les deux grandes fleches de page, a
  /// mi-hauteur de chaque cote de la page ; `null` aux bornes, ou pour qui
  /// ne tourne pas la page.
  final VoidCallback? onPagePrecedente;
  final VoidCallback? onPageSuivante;

  /// Le rendu reel de la camera d'un participant, par son identite (le
  /// `profile_id`), ou `null` : camera coupee ou pas encore recue.
  final Widget? Function(String identite)? video;

  /// L'identite montree dans la vignette : l'enseignant chez l'eleve, sa
  /// propre image chez l'enseignant.
  final String? identiteVignette;

  /// Le rendu de la page fixe presentee (la page Madina), a la place de la
  /// page neutre.
  final Widget Function(SupportPageFixe page)? page;

  /// Le zoom voulu par un pincement ou un double toucher (retour a 100 %).
  final ValueChanged<double>? onZoom;

  static PorteeMediaSalle? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PorteeMediaSalle>();

  /// La video de la vignette, ou `null`.
  static Widget? videoVignette(BuildContext context) {
    final PorteeMediaSalle? portee = de(context);
    final String? identite = portee?.identiteVignette;
    if (portee == null || identite == null) return null;
    return portee.video?.call(identite);
  }


  // Les pistes changent sans que les rappels changent : la portee se relit
  // a chaque reconstruction de `/salle`.
  @override
  bool updateShouldNotify(PorteeMediaSalle ancien) => true;
}
