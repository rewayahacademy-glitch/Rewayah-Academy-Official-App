import 'package:flutter/widgets.dart';

/// Une icone, dans ses deux graisses.
///
/// Les deux sont liees a la construction : un etat actif ne peut pas se
/// retrouver avec une icone differente de son etat inactif, ce qui arriverait
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
/// **C'est le seul fichier du depot autorise a construire un [IconData].** Une
/// seule librairie d'icones dans tout le projet, pas de melange Material,
/// Font Awesome ou autre, et zero emoji
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md` section 3).
/// `tool/verifier_jetons.dart` echoue si un autre fichier de `lib/` en
/// construit un.
///
/// Les polices Phosphor sont **integrees en assets** plutot que tirees du
/// paquet `phosphor_flutter` : sa version 2.1.0 ne compile plus avec
/// Flutter 3.47, ou `IconData` est devenue une classe `final` qu'il ne peut
/// plus etendre, et aucune version corrigee n'est publiee. Deux graisses
/// seulement sont embarquees au lieu des six du paquet.
///
/// Les [IconData] sont declares `const` pour que l'elagage d'icones des
/// versions de production fonctionne : seuls les points de code cites ici sont
/// conserves dans la police livree.
abstract final class AppIcons {
  static const String _repos = 'Phosphor';
  static const String _actif = 'PhosphorFill';

  // --- Navigation, eleve -------------------------------------------------

  /// Accueil de l'eleve.
  static const AppIcon accueil = AppIcon._(
    IconData(0xe2c2, fontFamily: _repos),
    IconData(0xe2c2, fontFamily: _actif),
  );

  /// Le Coran.
  static const AppIcon coran = AppIcon._(
    IconData(0xe8f2, fontFamily: _repos),
    IconData(0xe8f2, fontFamily: _actif),
  );

  /// Suivi et historique.
  static const AppIcon suivi = AppIcon._(
    IconData(0xe154, fontFamily: _repos),
    IconData(0xe154, fontFamily: _actif),
  );

  // --- Navigation, tuteur ------------------------------------------------

  /// Le foyer et ses enfants.
  static const AppIcon foyer = AppIcon._(
    IconData(0xe68e, fontFamily: _repos),
    IconData(0xe68e, fontFamily: _actif),
  );

  /// Disponibilites du foyer ou de l'enseignant.
  static const AppIcon disponibilites = AppIcon._(
    IconData(0xe7b4, fontFamily: _repos),
    IconData(0xe7b4, fontFamily: _actif),
  );

  /// Reglages.
  static const AppIcon reglages = AppIcon._(
    IconData(0xe272, fontFamily: _repos),
    IconData(0xe272, fontFamily: _actif),
  );

  // --- Navigation, enseignant --------------------------------------------

  /// La journee de cours.
  static const AppIcon journee = AppIcon._(
    IconData(0xe712, fontFamily: _repos),
    IconData(0xe712, fontFamily: _actif),
  );

  /// Le feed de creneaux disponibles.
  static const AppIcon creneaux = AppIcon._(
    IconData(0xeadc, fontFamily: _repos),
    IconData(0xeadc, fontFamily: _actif),
  );

  /// Profil personnel.
  static const AppIcon profil = AppIcon._(
    IconData(0xe4c2, fontFamily: _repos),
    IconData(0xe4c2, fontFamily: _actif),
  );

  // --- Navigation, controleur et admin -----------------------------------

  /// Planning global du controleur.
  static const AppIcon planningGlobal = AppIcon._(
    IconData(0xebe0, fontFamily: _repos),
    IconData(0xebe0, fontFamily: _actif),
  );

  /// Tableau de bord de l'administration.
  static const AppIcon tableauDeBord = AppIcon._(
    IconData(0xe464, fontFamily: _repos),
    IconData(0xe464, fontFamily: _actif),
  );

  /// Dossiers d'identite a valider.
  static const AppIcon dossiers = AppIcon._(
    IconData(0xe2c8, fontFamily: _repos),
    IconData(0xe2c8, fontFamily: _actif),
  );

  /// Attribution manuelle enseignant vers foyer.
  static const AppIcon attribution = AppIcon._(
    IconData(0xe67c, fontFamily: _repos),
    IconData(0xe67c, fontFamily: _actif),
  );

  /// Journal d'audit.
  static const AppIcon journal = AppIcon._(
    IconData(0xeb7a, fontFamily: _repos),
    IconData(0xeb7a, fontFamily: _actif),
  );

  // --- Navigation, domaines admin (lot IA-01) -----------------------------

  /// Domaine Pedagogie : feuille de regles par eleve.
  static const AppIcon pedagogie = AppIcon._(
    IconData(0xe62c, fontFamily: _repos),
    IconData(0xe62c, fontFamily: _actif),
  );

  /// Domaine Finance. Reserve, aucun ecran construit (ADR-003).
  static const AppIcon finance = AppIcon._(
    IconData(0xe68a, fontFamily: _repos),
    IconData(0xe68a, fontFamily: _actif),
  );

  /// Domaine Direction. Reserve, aucune fondation de permission encore posee.
  static const AppIcon direction = AppIcon._(
    IconData(0xe1c8, fontFamily: _repos),
    IconData(0xe1c8, fontFamily: _actif),
  );

  /// Recherche globale, barre superieure du panneau admin.
  static const AppIcon recherche = AppIcon._(
    IconData(0xe30c, fontFamily: _repos),
    IconData(0xe30c, fontFamily: _actif),
  );

  /// Notifications, barre superieure du panneau admin.
  static const AppIcon notifications = AppIcon._(
    IconData(0xe0ce, fontFamily: _repos),
    IconData(0xe0ce, fontFamily: _actif),
  );

  /// Ouverture du tiroir de navigation, sur telephone.
  static const AppIcon menu = AppIcon._(
    IconData(0xe2f0, fontFamily: _repos),
    IconData(0xe2f0, fontFamily: _actif),
  );

  /// Changement d'enseignant (reaffectation), tuile du renvoi Operations.
  static const AppIcon reaffectation = AppIcon._(
    IconData(0xe0a0, fontFamily: _repos),
    IconData(0xe0a0, fontFamily: _actif),
  );

  // --- Salle de cours ----------------------------------------------------

  /// Micro ouvert.
  static const AppIcon micro = AppIcon._(
    IconData(0xe326, fontFamily: _repos),
    IconData(0xe326, fontFamily: _actif),
  );

  /// Micro coupe.
  static const AppIcon microCoupe = AppIcon._(
    IconData(0xe328, fontFamily: _repos),
    IconData(0xe328, fontFamily: _actif),
  );

  /// Camera allumee. N'est jamais rendue quand la politique camera du profil
  /// vaut `forbidden` : le bouton n'existe pas, il n'est pas grise (ADR-009).
  static const AppIcon camera = AppIcon._(
    IconData(0xe4da, fontFamily: _repos),
    IconData(0xe4da, fontFamily: _actif),
  );

  /// Camera eteinte.
  static const AppIcon cameraCoupee = AppIcon._(
    IconData(0xe4dc, fontFamily: _repos),
    IconData(0xe4dc, fontFamily: _actif),
  );

  /// Sortie de seance.
  static const AppIcon sortie = AppIcon._(
    IconData(0xe42a, fontFamily: _repos),
    IconData(0xe42a, fontFamily: _actif),
  );

  /// Le bandeau permanent de la salle : cours enregistre, controle possible.
  static const AppIcon controleQualite = AppIcon._(
    IconData(0xe40c, fontFamily: _repos),
    IconData(0xe40c, fontFamily: _actif),
  );

  // --- Journee et interruptions ------------------------------------------

  /// Interruption de priere prevue pendant une seance (ADR-017).
  ///
  /// C'est le pictogramme du mode enfant : a six ans, on ne lit pas « Dhuhr,
  /// vers 13:20 », on reconnait une forme. Le libelle audio l'accompagne.
  static const AppIcon priere = AppIcon._(
    IconData(0xecee, fontFamily: _repos),
    IconData(0xecee, fontFamily: _actif),
  );

  /// Un cours de la journee.
  static const AppIcon cours = AppIcon._(
    IconData(0xe600, fontFamily: _repos),
    IconData(0xe600, fontFamily: _actif),
  );

  /// Le temps entre deux cours.
  static const AppIcon pause = AppIcon._(
    IconData(0xe1c2, fontFamily: _repos),
    IconData(0xe1c2, fontFamily: _actif),
  );

  // --- Composants partages -----------------------------------------------

  /// Haut-parleur du composant `AudioLabel`.
  static const AppIcon libelleAudio = AppIcon._(
    IconData(0xe44a, fontFamily: _repos),
    IconData(0xe44a, fontFamily: _actif),
  );

  /// Reseau indisponible, composant `OfflineBanner`.
  static const AppIcon horsLigne = AppIcon._(
    IconData(0xe4f2, fontFamily: _repos),
    IconData(0xe4f2, fontFamily: _actif),
  );

  /// Synchronisation en attente.
  static const AppIcon enAttenteEnvoi = AppIcon._(
    IconData(0xe1ae, fontFamily: _repos),
    IconData(0xe1ae, fontFamily: _actif),
  );

  /// Etat vide, composant `EmptyState`.
  static const AppIcon rienAAfficher = AppIcon._(
    IconData(0xe580, fontFamily: _repos),
    IconData(0xe580, fontFamily: _actif),
  );

  /// Repli du composant `AvatarTile` quand aucune photo n'est disponible.
  static const AppIcon avatarSansPhoto = AppIcon._(
    IconData(0xe4c2, fontFamily: _repos),
    IconData(0xe4c2, fontFamily: _actif),
  );

  /// Validation, succes.
  static const AppIcon succes = AppIcon._(
    IconData(0xe184, fontFamily: _repos),
    IconData(0xe184, fontFamily: _actif),
  );

  /// Avertissement, erreur.
  static const AppIcon avertissement = AppIcon._(
    IconData(0xe4e2, fontFamily: _repos),
    IconData(0xe4e2, fontFamily: _actif),
  );

  /// Appairage par QR.
  static const AppIcon qr = AppIcon._(
    IconData(0xe3e6, fontFamily: _repos),
    IconData(0xe3e6, fontFamily: _actif),
  );

  /// Appareil appaire.
  static const AppIcon appareil = AppIcon._(
    IconData(0xe1e0, fontFamily: _repos),
    IconData(0xe1e0, fontFamily: _actif),
  );

  /// Cahier de transmission.
  static const AppIcon cahier = AppIcon._(
    IconData(0xe34e, fontFamily: _repos),
    IconData(0xe34e, fontFamily: _actif),
  );

  /// Effacement d'un caractere sur le pave numerique.
  static const AppIcon effacer = AppIcon._(
    IconData(0xe4f6, fontFamily: _repos),
    IconData(0xe4f6, fontFamily: _actif),
  );

  /// Ajout.
  static const AppIcon ajouter = AppIcon._(
    IconData(0xe3d4, fontFamily: _repos),
    IconData(0xe3d4, fontFamily: _actif),
  );

  /// Progression vers l'element suivant.
  static const AppIcon suivant = AppIcon._(
    IconData(0xe13a, fontFamily: _repos),
    IconData(0xe13a, fontFamily: _actif),
  );

  /// Le chevron d'une ligne qui mene ailleurs : `SignalRow`, `ChildCard`,
  /// lignes de liste.
  ///
  /// **Meme glyphe que [suivant], et pourtant une entree separee** : celle-ci
  /// porte `matchTextDirection`, donc elle se miroite en arabe, alors que
  /// [suivant] designe la progression du temps, qui ne se miroite pas
  /// (`docs/archive/2026-09-pre-remise-a-plat/design/06-accessibilite.md` section 5). Les deux ne peuvent donc
  /// pas etre la meme icone, malgre le meme dessin.
  static const AppIcon chevron = AppIcon._(
    IconData(0xe13a, fontFamily: _repos, matchTextDirection: true),
    IconData(0xe13a, fontFamily: _actif, matchTextDirection: true),
  );

  /// Le chevron d'un controle qui ouvre un menu **sous** lui : `MenuFiltre`.
  ///
  /// **Pas [chevron], et c'est tout l'objet de cette entree** : un chevron vers
  /// la droite promet d'emmener ailleurs, alors qu'un menu s'ouvre en dessous
  /// et rend la main sur place. Et [chevron] porte `matchTextDirection`, donc
  /// en arabe il finirait par pointer a gauche : une direction cardinale
  /// fausse pour un menu, qui ne s'ouvre pas plus a gauche qu'a droite. Le bas
  /// ne se miroite pas (`docs/archive/2026-09-pre-remise-a-plat/design/06-accessibilite.md` section 5).
  static const AppIcon menuDeroulant = AppIcon._(
    IconData(0xe136, fontFamily: _repos),
    IconData(0xe136, fontFamily: _actif),
  );

  /// Carte "Autre" du composant `ChoiceCardGroup`.
  static const AppIcon autreChoix = AppIcon._(
    IconData(0xe3b4, fontFamily: _repos),
    IconData(0xe3b4, fontFamily: _actif),
  );

  // --- Teaching Core -------------------------------------------------------
  //
  // Vingt icones, issues du recensement `grep -rn 'TC-ICONE:' lib/` sur les
  // neuf branches teaching-core/*. Chaque site d'appel portait un placeholder
  // emprunte au catalogue existant ; ces vingt entrees le remplacent au moment
  // du merge de leur lot producteur. Voir TEACHING_CORE_INTEGRATION_CONTRACT_PLAN.md §9.1.

  /// Espace Groupe (A) : conseil « rejoignez depuis une tablette ou un
  /// ordinateur ». Remplace le placeholder [appareil].
  static const AppIcon tabletteOuOrdinateur = AppIcon._(
    IconData(0xeba4, fontFamily: _repos),
    IconData(0xeba4, fontFamily: _actif),
  );

  /// Bibliotheque (B) : vignette d'une ressource PDF. Remplace [dossiers].
  static const AppIcon fichierPdf = AppIcon._(
    IconData(0xe702, fontFamily: _repos),
    IconData(0xe702, fontFamily: _actif),
  );

  /// Bibliotheque (B) : vignette d'un texte structure. Remplace [cahier].
  static const AppIcon texteStructure = AppIcon._(
    IconData(0xe0a8, fontFamily: _repos),
    IconData(0xe0a8, fontFamily: _actif),
  );

  /// Bibliotheque (B) : vignette d'une image. Remplace [qr].
  static const AppIcon image = AppIcon._(
    IconData(0xe2ca, fontFamily: _repos),
    IconData(0xe2ca, fontFamily: _actif),
  );

  /// Bibliotheque (B) : vignette d'une lecon. Remplace [pedagogie].
  static const AppIcon lecon = AppIcon._(
    IconData(0xe0e6, fontFamily: _repos),
    IconData(0xe0e6, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil bibliotheque. Remplace [cahier].
  static const AppIcon bibliotheque = AppIcon._(
    IconData(0xe758, fontFamily: _repos),
    IconData(0xe758, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil focus. Remplace [recherche].
  static const AppIcon focus = AppIcon._(
    IconData(0xe47c, fontFamily: _repos),
    IconData(0xe47c, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil marqueur semantique. **Collision de placeholder
  /// avec [surligneur]** (les deux empruntaient [pedagogie]) : les deux
  /// entrees sont livrees ensemble. Remplace [pedagogie].
  static const AppIcon marqueur = AppIcon._(
    IconData(0xe478, fontFamily: _repos),
    IconData(0xe478, fontFamily: _actif),
  );

  /// Teaching Dock (D) : masquer un calque, oeil barre. **Collision de
  /// placeholder avec [observationFermee]** (les deux empruntaient
  /// [cameraCoupee]) : les deux entrees sont livrees ensemble, avec des
  /// glyphes distincts (oeil barre ici, oeil ferme pour l'autre). Remplace
  /// [cameraCoupee].
  static const AppIcon masquer = AppIcon._(
    IconData(0xe224, fontFamily: _repos),
    IconData(0xe224, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil stylet. Remplace [journal].
  static const AppIcon stylet = AppIcon._(
    IconData(0xe3aa, fontFamily: _repos),
    IconData(0xe3aa, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil surligneur. Voir la note de collision sur
  /// [marqueur]. Remplace [pedagogie].
  static const AppIcon surligneur = AppIcon._(
    IconData(0xe632, fontFamily: _repos),
    IconData(0xe632, fontFamily: _actif),
  );

  /// Teaching Dock (D) : outil pointeur, main qui designe. Remplace [suivant].
  static const AppIcon pointeur = AppIcon._(
    IconData(0xe29a, fontFamily: _repos),
    IconData(0xe29a, fontFamily: _actif),
  );

  /// Teaching Dock (D) : annuler le dernier trait. Remplace [reaffectation].
  static const AppIcon annuler = AppIcon._(
    IconData(0xe038, fontFamily: _repos),
    IconData(0xe038, fontFamily: _actif),
  );

  /// Teaching Dock (D) : poignee de deplacement, six points. Remplace
  /// [menuDeroulant].
  static const AppIcon poigneeDock = AppIcon._(
    IconData(0xeae2, fontFamily: _repos),
    IconData(0xeae2, fontFamily: _actif),
  );

  /// Teaching Dock (D) : revision, fleche circulaire. Remplace
  /// [enAttenteEnvoi].
  static const AppIcon revision = AppIcon._(
    IconData(0xe036, fontFamily: _repos),
    IconData(0xe036, fontFamily: _actif),
  );

  /// Observation (G) : entree admin en mode incognito. Remplace
  /// [controleQualite].
  static const AppIcon observationIncognito = AppIcon._(
    IconData(0xe83e, fontFamily: _repos),
    IconData(0xe83e, fontFamily: _actif),
  );

  /// Observation (G) : entree admin visible, rejoint la classe a decouvert.
  /// Remplace [camera].
  static const AppIcon administrationVisible = AppIcon._(
    IconData(0xec38, fontFamily: _repos),
    IconData(0xec38, fontFamily: _actif),
  );

  /// Observation (G) : politique heritee de l'Academie. Remplace [reglages].
  static const AppIcon heritage = AppIcon._(
    IconData(0xe6ec, fontFamily: _repos),
    IconData(0xe6ec, fontFamily: _actif),
  );

  /// Observation (G) : politique personnalisee par groupe. Remplace [foyer].
  static const AppIcon personnalisationGroupe = AppIcon._(
    IconData(0xe434, fontFamily: _repos),
    IconData(0xe434, fontFamily: _actif),
  );

  /// Observation (G) : observation desactivee pour le groupe. Voir la note de
  /// collision sur [masquer]. Remplace [cameraCoupee].
  static const AppIcon observationFermee = AppIcon._(
    IconData(0xe222, fontFamily: _repos),
    IconData(0xe222, fontFamily: _actif),
  );
}
