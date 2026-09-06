import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Une icone, dans ses deux etats.
///
/// Les deux graisses sont liees a la construction : un etat actif ne peut pas
/// se retrouver avec une icone differente de son etat inactif, ce qui arriverait
/// si chaque ecran choisissait sa paire lui-meme.
@immutable
class AppIcon {
  const AppIcon._(this.repos, this.actif);

  /// Graisse `regular`, etat par defaut.
  final IconData repos;

  /// Graisse `fill`, etats actifs et selectionnes.
  final IconData actif;

  /// Resout la graisse selon l'etat.
  IconData resoudre({bool selectionne = false}) => selectionne ? actif : repos;
}

/// Le catalogue d'icones de l'application.
///
/// **C'est le seul fichier du depot autorise a importer `phosphor_flutter`.**
/// Une seule librairie d'icones dans tout le projet, pas de melange Material,
/// Font Awesome ou autre, et zero emoji
/// (`docs/produit/design-tokens.md` section 3).
/// `tool/verifier_jetons.dart` echoue si un autre fichier de `lib/` importe
/// Phosphor ou utilise `Icons.` de Material.
abstract final class AppIcons {
  // --- Navigation, eleve -------------------------------------------------

  /// Accueil de l'eleve.
  static const AppIcon accueil = AppIcon._(
    PhosphorIconsRegular.house,
    PhosphorIconsFill.house,
  );

  /// Le Coran.
  static const AppIcon coran = AppIcon._(
    PhosphorIconsRegular.bookOpenText,
    PhosphorIconsFill.bookOpenText,
  );

  /// Suivi et historique.
  static const AppIcon suivi = AppIcon._(
    PhosphorIconsRegular.chartLine,
    PhosphorIconsFill.chartLine,
  );

  // --- Navigation, tuteur ------------------------------------------------

  /// Le foyer et ses enfants.
  static const AppIcon foyer = AppIcon._(
    PhosphorIconsRegular.usersThree,
    PhosphorIconsFill.usersThree,
  );

  /// Disponibilites du foyer ou de l'enseignant.
  static const AppIcon disponibilites = AppIcon._(
    PhosphorIconsRegular.calendarDots,
    PhosphorIconsFill.calendarDots,
  );

  /// Reglages.
  static const AppIcon reglages = AppIcon._(
    PhosphorIconsRegular.gearSix,
    PhosphorIconsFill.gearSix,
  );

  // --- Navigation, enseignant --------------------------------------------

  /// La journee de cours.
  static const AppIcon journee = AppIcon._(
    PhosphorIconsRegular.calendarCheck,
    PhosphorIconsFill.calendarCheck,
  );

  /// Le feed de creneaux disponibles.
  static const AppIcon creneaux = AppIcon._(
    PhosphorIconsRegular.listChecks,
    PhosphorIconsFill.listChecks,
  );

  /// Profil personnel.
  static const AppIcon profil = AppIcon._(
    PhosphorIconsRegular.user,
    PhosphorIconsFill.user,
  );

  // --- Navigation, controleur et admin -----------------------------------

  /// Planning global du controleur.
  static const AppIcon planningGlobal = AppIcon._(
    PhosphorIconsRegular.listMagnifyingGlass,
    PhosphorIconsFill.listMagnifyingGlass,
  );

  /// Tableau de bord de l'administration.
  static const AppIcon tableauDeBord = AppIcon._(
    PhosphorIconsRegular.squaresFour,
    PhosphorIconsFill.squaresFour,
  );

  /// Dossiers d'identite a valider.
  static const AppIcon dossiers = AppIcon._(
    PhosphorIconsRegular.identificationCard,
    PhosphorIconsFill.identificationCard,
  );

  /// Attribution manuelle enseignant vers foyer.
  static const AppIcon attribution = AppIcon._(
    PhosphorIconsRegular.treeStructure,
    PhosphorIconsFill.treeStructure,
  );

  /// Journal d'audit.
  static const AppIcon journal = AppIcon._(
    PhosphorIconsRegular.scroll,
    PhosphorIconsFill.scroll,
  );

  // --- Salle de cours ----------------------------------------------------

  /// Micro ouvert.
  static const AppIcon micro = AppIcon._(
    PhosphorIconsRegular.microphone,
    PhosphorIconsFill.microphone,
  );

  /// Micro coupe.
  static const AppIcon microCoupe = AppIcon._(
    PhosphorIconsRegular.microphoneSlash,
    PhosphorIconsFill.microphoneSlash,
  );

  /// Camera allumee. N'est jamais rendue quand la politique camera du profil
  /// vaut `forbidden` : le bouton n'existe pas, il n'est pas grise (ADR-009).
  static const AppIcon camera = AppIcon._(
    PhosphorIconsRegular.videoCamera,
    PhosphorIconsFill.videoCamera,
  );

  /// Camera eteinte.
  static const AppIcon cameraCoupee = AppIcon._(
    PhosphorIconsRegular.videoCameraSlash,
    PhosphorIconsFill.videoCameraSlash,
  );

  /// Sortie de seance.
  static const AppIcon sortie = AppIcon._(
    PhosphorIconsRegular.signOut,
    PhosphorIconsFill.signOut,
  );

  /// Le bandeau permanent de la salle : cours enregistre, controle possible.
  static const AppIcon controleQualite = AppIcon._(
    PhosphorIconsRegular.shieldCheck,
    PhosphorIconsFill.shieldCheck,
  );

  // --- Composants partages -----------------------------------------------

  /// Haut-parleur du composant `AudioLabel`.
  static const AppIcon libelleAudio = AppIcon._(
    PhosphorIconsRegular.speakerHigh,
    PhosphorIconsFill.speakerHigh,
  );

  /// Reseau indisponible, composant `OfflineBanner`.
  static const AppIcon horsLigne = AppIcon._(
    PhosphorIconsRegular.wifiSlash,
    PhosphorIconsFill.wifiSlash,
  );

  /// Synchronisation en attente.
  static const AppIcon enAttenteEnvoi = AppIcon._(
    PhosphorIconsRegular.cloudArrowUp,
    PhosphorIconsFill.cloudArrowUp,
  );

  /// Etat vide, composant `EmptyState`.
  static const AppIcon rienAAfficher = AppIcon._(
    PhosphorIconsRegular.handWaving,
    PhosphorIconsFill.handWaving,
  );

  /// Repli du composant `AvatarTile` quand aucune photo n'est disponible.
  static const AppIcon avatarSansPhoto = AppIcon._(
    PhosphorIconsRegular.user,
    PhosphorIconsFill.user,
  );

  /// Validation, succes.
  static const AppIcon succes = AppIcon._(
    PhosphorIconsRegular.checkCircle,
    PhosphorIconsFill.checkCircle,
  );

  /// Avertissement, erreur.
  static const AppIcon avertissement = AppIcon._(
    PhosphorIconsRegular.warningCircle,
    PhosphorIconsFill.warningCircle,
  );

  /// Appairage par QR.
  static const AppIcon qr = AppIcon._(
    PhosphorIconsRegular.qrCode,
    PhosphorIconsFill.qrCode,
  );

  /// Appareil appaire.
  static const AppIcon appareil = AppIcon._(
    PhosphorIconsRegular.deviceMobile,
    PhosphorIconsFill.deviceMobile,
  );

  /// Cahier de transmission.
  static const AppIcon cahier = AppIcon._(
    PhosphorIconsRegular.notebook,
    PhosphorIconsFill.notebook,
  );

  /// Effacement d'un caractere sur le pave numerique.
  static const AppIcon effacer = AppIcon._(
    PhosphorIconsRegular.x,
    PhosphorIconsFill.x,
  );

  /// Ajout.
  static const AppIcon ajouter = AppIcon._(
    PhosphorIconsRegular.plus,
    PhosphorIconsFill.plus,
  );

  /// Progression vers l'element suivant.
  static const AppIcon suivant = AppIcon._(
    PhosphorIconsRegular.caretRight,
    PhosphorIconsFill.caretRight,
  );

  /// Carte "Autre" du composant `ChoiceCardGroup`.
  static const AppIcon autreChoix = AppIcon._(
    PhosphorIconsRegular.pencilSimple,
    PhosphorIconsFill.pencilSimple,
  );
}
