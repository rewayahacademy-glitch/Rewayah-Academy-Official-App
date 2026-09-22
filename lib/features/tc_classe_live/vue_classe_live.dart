import 'package:flutter/foundation.dart';

import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/video/video_session_provider.dart';

/// Qui domine l'ecran.
///
/// **Le principe de composition de la spec section 9.1**, et il tient en une
/// phrase : quand un support est actif, le support domine et la video devient
/// secondaire ; sans support presente, la video reprend de l'espace.
enum CompositionClasse {
  /// Un support est presente : il prend la plus grande surface.
  supportDominant,

  /// Aucun support : la scene video reprend la place.
  videoDominante,
}

/// Ou se lit le roster.
enum PlaceRoster {
  /// Colonne secondaire, permanente, a cote du contenu.
  colonne,

  /// Feuille ouverte a la demande, derriere un bouton compact « 4/5 ».
  feuille,

  /// Ce role ne lit pas le roster.
  masque,
}

/// Quelle place prend la video.
enum PoidsVideo {
  /// Elle est la scene : le contenu principal.
  scene,

  /// Une bande secondaire a cote du support.
  bande,

  /// Une vignette, en surimpression discrete.
  vignette,
}

/// Ce que l'etat du lien change pour l'enseignant, en un mot.
///
/// **Un mot, jamais une couleur seule** (invariant J7). Et pas de traduction
/// ici : les libelles vivent dans la facade, l'ecran les choisit d'apres cette
/// valeur. Une fonction pure qui irait chercher les libelles ne serait plus
/// testable hors contexte.
enum MotLien {
  /// Rien a dire : le lien tient.
  aucun,

  /// Le lien se degrade. **La seance continue.**
  instable,

  /// Le lien est perdu, le moteur le retablit.
  reconnexion,

  /// Le lien vient d'etre retabli.
  retabli,

  /// La connexion n'a pas pu etre retablie.
  echec,
}

/// Ce que la Classe Live montre, a un instant donne.
///
/// **Fonction pure, comme `VueSalle.depuis`, `VuePresence.depuis` et
/// `deciderRedirection`.** Les trois gabarits, les deux compositions, les trois
/// poids de video et les cinq mots du lien se verifient sans monter d'ecran,
/// sans reseau et sans SDK.
///
/// Elle **ne recopie pas `VueSalle`** : elle la consomme. `VueSalle` decide de
/// la phase d'entree, du role, des capacites du jeton et de qui occupe le
/// cadre ; celle-ci decide de la **composition** -- qui domine, ou se lit le
/// roster, quelle place prend la video. Deux questions differentes, deux
/// fonctions, aucune duplication.
@immutable
class VueClasseLive {
  const VueClasseLive._({
    required this.composition,
    required this.placeRoster,
    required this.poidsVideo,
    required this.motLien,
    required this.compteurCompact,
    required this.avertitSuspension,
    required this.dockFlottant,
    required this.vignetteLaterale,
  });

  /// En dessous de cette hauteur, l'ecran est « court » : un telephone en
  /// paysage. La largeur y ment -- elle dit « tablette » -- et la composition
  /// de tablette y etranglerait le Coran entre une colonne de roster et une
  /// bande de visages. Ce seuil est le seul de ce fichier, et il est nomme.
  static const double seuilHauteurCourte = 500;

  /// Calcule la composition de l'ecran.
  ///
  /// [voitLeRoster] vient de `VueSalle.voitLesParticipants` : c'est le jeton qui
  /// decide, pas le role du compte. Un eleve ne recoit pas la liste nominative
  /// de ses camarades, et c'est une decision de protection des mineurs, pas un
  /// choix d'interface.
  ///
  /// [peutPiloterSupport] vient de `VueSalle.peutPresenter`, soit
  /// `can_publish_data` dans le jeton signe. **Aucune capacite ne se calcule
  /// ici.**
  factory VueClasseLive.depuis({
    required Gabarit gabarit,
    required SessionLiveVM session,
    required RosterClasseVM roster,
    required bool voitLeRoster,
    required bool peutPiloterSupport,
    bool suspensionNonConfirmee = false,
    bool hauteurCourte = false,
  }) {
    final bool avecSupport = session.avecSupport;

    final CompositionClasse composition = avecSupport
        ? CompositionClasse.supportDominant
        : CompositionClasse.videoDominante;

    // [RESPONSIVE] Un telephone en paysage est large mais court : on le
    // compose comme un telephone, pas comme une tablette (lot 2 section 6,
    // « pas une simple rotation naive »).
    final bool compact = gabarit == Gabarit.mobile || hauteurCourte;

    final PlaceRoster placeRoster = switch ((voitLeRoster, compact)) {
      (false, _) => PlaceRoster.masque,
      // Sur telephone, la colonne prendrait la moitie de la largeur du Coran.
      // La feuille rend la place au texte et se resume a un bouton compact.
      (true, true) => PlaceRoster.feuille,
      (true, false) => PlaceRoster.colonne,
    };

    final PoidsVideo poidsVideo = switch ((avecSupport, compact)) {
      // Sans support, la video EST le contenu, a tous les gabarits.
      (false, _) => PoidsVideo.scene,
      // Avec support sur telephone, le support est plein ecran ou presque :
      // la video se reduit a une vignette.
      (true, true) => PoidsVideo.vignette,
      // Avec support sur tablette et bureau, il reste de la largeur pour une
      // bande de visages a cote du document.
      (true, false) => PoidsVideo.bande,
    };

    return VueClasseLive._(
      composition: composition,
      placeRoster: placeRoster,
      poidsVideo: poidsVideo,
      motLien: _mot(session.etatLien),
      // Le compteur compact n'a de sens que la ou le roster est replie : a cote
      // d'une colonne qui montre les cinq lignes, il ferait doublon, et un
      // doublon finit par diverger.
      compteurCompact: placeRoster == PlaceRoster.feuille
          ? roster.compteurCompact
          : null,
      avertitSuspension: suspensionNonConfirmee,
      // **Le dock ne flotte que sur un support, et que pour qui peut piloter.**
      // Un dock pose sur une scene video n'aurait rien a outiller ; un dock
      // offert a qui n'a pas le droit d'emettre proposerait des gestes que le
      // serveur refuserait.
      dockFlottant: avecSupport && peutPiloterSupport,
      // En paysage court, la vignette se pose a cote du support : en dessous,
      // elle mangerait la seule dimension qui manque.
      vignetteLaterale: hauteurCourte && gabarit != Gabarit.mobile,
    );
  }

  static MotLien _mot(EtatSalle etat) => switch (etat) {
    EtatSalle.instable => MotLien.instable,
    EtatSalle.reconnexion => MotLien.reconnexion,
    EtatSalle.retabli => MotLien.retabli,
    EtatSalle.echec => MotLien.echec,
    EtatSalle.absent ||
    EtatSalle.connexion ||
    EtatSalle.connecte => MotLien.aucun,
  };

  /// Qui domine l'ecran.
  final CompositionClasse composition;

  /// Ou se lit le roster.
  final PlaceRoster placeRoster;

  /// Quelle place prend la video.
  final PoidsVideo poidsVideo;

  /// Ce que l'etat du lien change, en un mot. [MotLien.aucun] = rien a dire.
  final MotLien motLien;

  /// Le compteur du bouton de roster replie, « 4/5 ». `null` ailleurs.
  final String? compteurCompact;

  /// L'application revient d'une suspension et le lien n'est pas reconfirme.
  ///
  /// **On l'affiche sans rien promettre** : quand la plateforme tue le reseau,
  /// aucune machine de reconnexion ne peut tenir parole. Et on ne l'affiche pas
  /// PENDANT la suspension : une application suspendue ne rend aucune image --
  /// `SchedulerBinding` coupe les frames des l'etat `paused`. C'est au retour
  /// que la phrase sert.
  final bool avertitSuspension;

  /// Le Teaching Dock a-t-il lieu d'etre pose sur cet ecran ?
  final bool dockFlottant;

  /// La vignette video se pose-t-elle a cote du support plutot que dessous ?
  ///
  /// Ne vaut que pour [PoidsVideo.vignette]. Vrai en paysage court, ou la
  /// hauteur manque et la largeur abonde.
  final bool vignetteLaterale;

  /// Le support occupe-t-il la plus grande surface ?
  bool get supportDomine => composition == CompositionClasse.supportDominant;

  /// **Aucune barre d'outils ne couvre le Coran** (spec section 9.2).
  ///
  /// Ce getter est une **verite de construction, pas un reglage** : les
  /// commandes de la Classe Live vivent dans `PageImmersive.commandes`, c'est a
  /// dire SOUS le contenu, dans le flux, et jamais en surimpression. Le rendre
  /// lisible permet de le tester ; il n'existe aucun chemin qui le rende faux.
  bool get commandesCouvrentLeSupport => false;
}
