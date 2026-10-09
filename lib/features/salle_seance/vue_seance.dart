// La salle de seance unique : ce que chaque role voit.
//
// Toutes les regles de `10_classe/V/01_MATRICE_ROLES.md` (pilotage) vivent
// ICI, en getters purs : les widgets ne decident rien, ils lisent. Ni LiveKit
// ni Supabase : une `VueSeance` se construit depuis `/salle`, depuis
// `/tc/classe` ou depuis la demonstration (`lib/features/demo/seance_demo.dart`).

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_outils/annotation_layer.dart' show TraitVectoriel;
import '../../core/theme/app_gabarit.dart';
import '../salle/vue_salle.dart';

/// Le role effectif devant l'ecran : colonnes ES, IG et EN de la matrice.
enum RoleSeance {
  /// Eleve en interface standard (CLV-04).
  eleve,

  /// Eleve en Interface guidee (CLV-05), mode `InterfaceMode.enfant`.
  guidee,

  /// Enseignant (CLV-06 a 08, 10).
  enseignant;

  /// Le role du JETON et le mode d'interface lu dans le theme donnent le role
  /// effectif. Tout autre role du jeton (tuteur observateur, controleur,
  /// administration, inconnu) rend `null` : la salle garde son ancien rendu.
  static RoleSeance? resoudre(RoleSalle role, InterfaceMode mode) =>
      switch (role) {
        RoleSalle.enseignant => RoleSeance.enseignant,
        RoleSalle.eleve =>
          mode == InterfaceMode.enfant ? RoleSeance.guidee : RoleSeance.eleve,
        _ => null,
      };

  /// Vrai pour les deux vues d'eleve.
  bool get estEleve => this != RoleSeance.enseignant;
}

/// L'horloge de la seance, vue de l'enseignant seulement.
@immutable
sealed class HorlogeSeance {
  const HorlogeSeance();
}

/// Il reste [minutes] minutes avant l'heure de fin prevue.
///
/// Jamais negatif (P11) : apres l'heure de fin, c'est [HorlogeDepassee]. Les
/// adaptateurs bornent a 0 ce que le moteur leur donne.
final class HorlogeRestante extends HorlogeSeance {
  const HorlogeRestante(this.minutes) : assert(minutes >= 0);
  final int minutes;
}

/// L'heure de fin est passee : « La seance se poursuit. », texte simple.
final class HorlogeDepassee extends HorlogeSeance {
  const HorlogeDepassee();
}

/// L'etat de la connexion de celui qui regarde (P05, P06, lot CL-7).
///
/// Tout vient du moteur ou du serveur (BR-1) : l'ecran ne detecte rien
/// lui-meme et ne tient aucune minuterie.
enum ConnexionSeance {
  /// Lien sain.
  enLigne,

  /// Room connectee, qualite degradee : jamais « hors ligne » (P06.5).
  reseauFaible,

  /// Lien perdu, le moteur retablit la connexion.
  reconnexion,

  /// La coupure vient d'etre refermee (etat transitoire).
  retablie,

  /// Le moteur a renonce a retablir la connexion.
  echec,

  /// L'appareil n'a plus de reseau (confirme par le moteur).
  horsLigne;

  /// La room est connectee : la pastille dit « En ligne ».
  bool get etablie =>
      this == enLigne || this == reseauFaible || this == retablie;
}

/// Statut d'un inscrit pendant la seance. Jamais « present » ni « absent »
/// avant la consolidation par le serveur (I-6).
enum StatutEleveSeance { connecte, pasEncoreConnecte, connexionInterrompue }

/// La fiche d'un eleve, panneau Eleves (CLV-07), enseignant seulement.
@immutable
class FicheEleveSeance {
  const FicheEleveSeance({
    required this.niveau,
    required this.objectifActuel,
    required this.derniereSeance,
    required this.aReprendre,
    required this.presenceRecente,
    required this.travailActuel,
  });

  final String niveau;
  final String objectifActuel;
  final String derniereSeance;
  final String aReprendre;
  final String presenceRecente;
  final String travailActuel;
}

/// Un inscrit de la Classe.
@immutable
class EleveSeance {
  const EleveSeance({
    required this.prenom,
    required this.statut,
    this.fiche,
    this.id,
    this.cleAvatar,
    this.peutEcrire = false,
  });

  /// L'enseignant l'a autorise a ecrire sur le support ou le tableau (plan
  /// V2 §4.3, §12, TB15). Faux par defaut : ecrire demande une autorisation
  /// explicite (TB14). En demonstration seulement : le droit effectif viendra
  /// du serveur (TB-BR-10).
  final bool peutEcrire;

  /// La cle de sa photo (E5, K-44), `null` sans photo : les initiales en
  /// repli. Nulle en demonstration, qui n'a aucune photo stockee.
  final String? cleAvatar;

  /// L'identifiant d'academie (`/tc/classe`) : les actions de la fiche
  /// (rappel, recitation) visent un inscrit par lui, jamais par son prenom.
  /// `null` en demonstration et dans `/salle`.
  final String? id;

  final String prenom;
  final StatutEleveSeance statut;
  final FicheEleveSeance? fiche;

  /// Connecte au moins une fois pendant la seance (recapitulatif de fin).
  bool get aEteConnecte => statut != StatutEleveSeance.pasEncoreConnecte;
}

/// Une visite d'observation en cours.
@immutable
class VisiteSeance {
  const VisiteSeance({required this.prenomEnfant, required this.concerneMoi});

  /// Le prenom de l'enfant dont le tuteur observe.
  final String prenomEnfant;

  /// Vrai si l'eleve devant l'ecran est cet enfant. Sans objet pour
  /// l'enseignant, qui voit toujours la notice.
  final bool concerneMoi;
}

/// Le support partage, tel que l'enseignant le montre.
@immutable
class SupportSeance {
  const SupportSeance({
    required this.chapitre,
    required this.titre,
    required this.encadre,
    required this.points,
    required this.page,
    required this.pages,
    this.ressourceId,
  });

  /// La ressource partagee (`supportActifId`) quand on la connait : deux
  /// ressources sans description restent distinctes (UX_REVIEW_04 n. 17 f).
  final String? ressourceId;
  final String chapitre;
  final String titre;
  final String encadre;
  final List<String> points;
  final int page;
  final int pages;
}

/// L'affichage partage de la surface pedagogique (plan V2 §2, §3, TB3).
///
/// Un AUTRE axe que `ModeAffichagePartage` (page, verset, focus), contrat de
/// base inchange : ce qui est visible (fond du support, calque des notes),
/// pas ce qui est cadre. Pas de colonne en base aujourd'hui (TB-BR-13) :
/// donnee de demonstration jusqu'a BR-1.
enum AffichagePartage {
  /// « Support » : le support seul, les notes cachees, jamais effacees (PED-02).
  support,

  /// « Avec notes » : le support et son calque (PED-03).
  avecNotes,

  /// « Tableau » : la feuille claire et les notes, le support masque (PED-04).
  tableau,
}

/// Ce que montre la surface pedagogique, derive de l'etat partage (plan V2
/// §17, PED-01 a PED-04). Lu par les widgets, jamais calcule par eux.
enum VueSurface {
  /// PED-01 : aucun support presente, le tableau libre.
  tableauLibre,

  /// PED-02 : le support seul.
  supportSeul,

  /// PED-03 : le support avec notes.
  supportAvecNotes,

  /// PED-04 : le tableau, le support retenu et masque.
  tableauSupportMasque,
}

/// L'etat d'enregistrement de la seance, a trois valeurs (UX_REVIEW_TB
/// n. 7, TB12) : le point rouge ne se montre que sur `actif`. Inconnu par
/// defaut : un etat qu'on ne connait pas ne se montre pas (TB-BR-23).
enum EtatEnregistrement { actif, inactif, inconnu }

/// Le controle de la seance, quand la donnee existe (plan V2 §4.3, §19.6,
/// TB12) : l'oeil informe, il ne declenche rien et ne donne aucun droit.
/// Aucune valeur « inconnu » : sans donnee, [VueSeance.controle] est `null`
/// et aucun oeil n'est rendu (jamais un etat fabrique). Donnee de
/// demonstration seulement jusqu'au contrat d'observation (TB-BR-24).
enum EtatControle {
  /// « Controle possible » : une visite peut avoir lieu ; personne n'est
  /// annonce comme observant maintenant.
  possible,

  /// « Controle actif » : le contrat dit qu'une visite a lieu.
  actif,
}

/// Le contexte deplie depuis la capsule (CTX-01, CTX-02) : etat d'interface,
/// jamais diffuse.
enum ContexteOuvert {
  /// La capsule seule (UI-01).
  aucun,

  /// L'avatar touche : le contexte de l'enseignant et de la seance (CTX-01).
  enseignant,

  /// L'oeil touche : le meme contexte, a la section du controle (CTX-02).
  controle,
}

/// Un support a page fixe presente a la classe (plan V2 §8, etat partage) :
/// support, version, page et total. Distinct de `SupportSeance`, diapositive
/// de texte que la salle existante garde, et de `SupportPresente`
/// (`core/tc_outils`), declaration du support a l'hote des outils.
///
/// La page est une image immuable et versionnee (TB-BR-20) ; son ratio est
/// celui des dimensions canoniques fournies par les donnees, jamais celui de
/// l'ecran (TB4, TB19). Aucune page de Coran n'est fabriquee ici (TB27).
@immutable
class SupportPageFixe {
  const SupportPageFixe({
    required this.id,
    required this.version,
    required this.titre,
    required this.page,
    required this.total,
    required this.largeurCanonique,
    required this.hauteurCanonique,
    this.mention,
    this.cleImage,
  }) : assert(page >= 1 && page <= total),
       assert(largeurCanonique > 0 && hauteurCanonique > 0);

  /// L'identifiant de la ressource (celui de `SupportDisponible.id`).
  final String id;

  /// La version de la ressource : un trait reste attache a cette version.
  final String version;
  final String titre;

  /// La page presentee, de 1 a [total].
  final int page;
  final int total;

  /// Les dimensions canoniques de la page, en pixels de la source.
  final int largeurCanonique;
  final int hauteurCanonique;

  /// Une mention portee par la page, ou `null` (« Support illustratif » en
  /// demonstration : un contenu, pas un libelle d'interface).
  final String? mention;

  /// La cle de l'image de la page dans le stockage, ou `null` : aucune image
  /// livree (demonstration ; fournisseur des pages a BR-1, TB-BR-19).
  final String? cleImage;

  /// Le ratio largeur sur hauteur, fixe par les donnees.
  double get ratio => largeurCanonique / hauteurCanonique;

  /// La meme ressource a une autre page.
  SupportPageFixe aLaPage(int autre) => SupportPageFixe(
    id: id,
    version: version,
    titre: titre,
    page: autre,
    total: total,
    largeurCanonique: largeurCanonique,
    hauteurCanonique: hauteurCanonique,
    mention: mention,
    cleImage: cleImage,
  );
}

/// Le tableau libre de la seance, independant de tout support (plan V2 §2,
/// TB5) : les traits d'un support n'y sont jamais copies.
@immutable
class TableauLibre {
  const TableauLibre({
    required this.largeurCanonique,
    required this.hauteurCanonique,
    this.aDesNotes = false,
  }) : assert(largeurCanonique > 0 && hauteurCanonique > 0);

  /// TB-7a : la ressource a laquelle s'ancrent les notes du tableau libre,
  /// distincte de tout support (TB5 : rien n'y est copie).
  static const String idRessource = 'tableau-libre';

  /// Le repere de la feuille. Le plan ne donne pas de ratio au tableau sans
  /// support : choix provisoire, fourni par les donnees (UX_REVIEW_TB n. 15,
  /// TB-BR-14), jamais la taille de l'ecran.
  final int largeurCanonique;
  final int hauteurCanonique;

  /// Des notes existent sur le tableau libre (« Effacer les notes » n'a de
  /// sens qu'alors).
  final bool aDesNotes;

  double get ratio => largeurCanonique / hauteurCanonique;
}

/// La rubrique d'un support dans le panneau Supports (CLV-08). Ordre repris
/// de `VueCatalogue` (Bibliotheque en classe) : continuer, recents, groupe.
enum RubriqueSupport {
  /// « Reprendre » : le support du cours en cours, avec « Ouvrir ».
  reprendre,

  /// « Recents ».
  recent,

  /// « Ressources de la Classe » : un fonds, pas un support ouvrable.
  classe,
}

/// Un support proposable (panneau Supports, CLV-08).
///
/// Forme reduite de `LibraryResource` (Bibliotheque) : ce que la salle
/// affiche, sans manifeste ni droit. Le cablage au catalogue vient a BR-1.
@immutable
class SupportDisponible {
  const SupportDisponible({
    required this.id,
    required this.titre,
    required this.detail,
    required this.rubrique,
    this.surTitre,
    this.type = TypeRessource.pdf,
    this.teinte = 1,
    this.monogramme = '',
    this.contenu,
  });

  /// Identifiant stable (celui de la ressource a BR-1).
  final String id;

  /// « Chapitre 1 » au-dessus du titre (rubrique Reprendre).
  final String? surTitre;
  final String titre;

  /// « PDF · 12 pages · v1.1 », « Support de cours · v2.0 », « 24 ressources ».
  final String detail;
  final RubriqueSupport rubrique;

  /// La couverture (grammaire de `VignetteRessource`). Teinte >= 1 : la
  /// teinte 0 est reservee au Coran.
  final TypeRessource type;
  final int teinte;
  final String monogramme;

  /// Ce que la salle montre une fois le support ouvert. `null` : le support
  /// ne s'ouvre pas dans la salle (fonds de la Classe).
  final SupportSeance? contenu;
}

/// Le recapitulatif de fin (CLV-10), enseignant seulement.
@immutable
class FinSeance {
  const FinSeance({required this.heureFin, required this.cahierACompleter});

  final String heureFin;
  final bool cahierACompleter;
}

/// Le panneau ouvert a cote du support (enseignant seulement).
enum PanneauOuvert {
  aucun,
  eleves,
  supports,

  /// EN-10 : le selecteur de ressources (04 §19).
  ressources,

  /// TB-4 (CMD-01, plan V2 §4.2) : les commandes du support et du tableau,
  /// ouvertes par le seul declencheur « Commandes ». Feuille au telephone,
  /// panneau a droite ailleurs ; un seul panneau secondaire a la fois.
  commandes,
}

/// Une commande du dock, par role (I-4).
enum CommandeDock { micro, camera, agrandir, reseau, quitter }

/// Un compte affiche en haut a droite : celui de la personne devant l'ecran.
@immutable
class CompteSeance {
  const CompteSeance({required this.nom, required this.initiales});

  final String nom;
  final String initiales;
}

/// Tout ce qu'une salle affiche, pour UN role. Immuable et pure.
@immutable
class VueSeance {
  const VueSeance({
    required this.role,
    required this.nomClasse,
    required this.nomEnseignant,
    required this.initialesEnseignant,
    this.prenomEleve,
    this.horloge,
    this.connexion = ConnexionSeance.enLigne,
    this.enregistrementConfirme = true,
    this.visite,
    this.recitation = FileRecitation.vide,
    this.appelRecu = false,
    this.support,
    this.cameraEnseignantActive = true,
    this.cameraAutorisee = true,
    this.microBloque = false,
    this.signalEnseignant = 3,
    this.eleves = const <EleveSeance>[],
    this.elevesConnus = true,
    this.supports = const <SupportDisponible>[],
    this.fin,
    this.panneau = PanneauOuvert.aucun,
    this.notificationsNonLues = 0,
    this.groupeId,
    this.tutoiement,
    this.affichage = AffichagePartage.avecNotes,
    this.supportPresente,
    this.tableauLibre,
    this.enregistrement = EtatEnregistrement.inconnu,
    this.controle,
    this.contexte = ContexteOuvert.aucun,
    this.notesSurface = const <TraitVectoriel>[],
    this.supportsRanges = const <SupportPageFixe>[],
  });

  // --- Reponses retenues aux questions Q1 a Q8 (plan de code section 4) ---
  //
  // Sans reponse du directeur, l'option deja retenue dans les images. Un
  // « non » se change ici, en une ligne.

  /// Q1 : guidee, disques pleins vert (Parler) et violet (Camera).
  static const bool optionQ1 = true;

  /// Q2 : enseignant desktop, carte « Outils d'enseignement » en colonne
  /// droite (CLV-07, 08) ; rangee au-dessus du support sur CLV-06.
  static const bool optionQ2 = true;

  /// Q3 : compte retire du coin haut droit (non : il reste en haut a droite).
  static const bool optionQ3 = false;

  /// Q4 : « Le tuteur de {prenom} observe la seance. » (non : texte de la
  /// spec, « Tuteur de {prenom} observe. »). Sans effet depuis EN-RC : la
  /// notice de l'enseignant est « Un parent observe cette seance » (EN-9).
  static const bool optionQ4 = false;

  /// Q5 : guidee, texte court « Le cours est enregistre. » (non : texte
  /// complet).
  static const bool optionQ5 = false;

  /// Q6 : zoom local de l'eleve standard, qui ne publie rien.
  static const bool optionQ6 = true;

  /// Q7 : l'eleve standard ne voit jamais la video des autres eleves.
  static const bool optionQ7 = true;

  /// Q8 : guidee desktop, video a cote du support, jamais par-dessus.
  static const bool optionQ8 = true;

  /// Q-S1 (lot CL-7) : eleve standard sans camera, le statut « Camera
  /// desactivee pour ce profil. » est visible dans la barre basse (non :
  /// aucun texte visible, libelle d'accessibilite seulement).
  static const bool optionQS1 = true;

  final RoleSeance role;
  final String nomClasse;
  final String nomEnseignant;
  final String initialesEnseignant;

  /// L'eleve devant l'ecran (vues eleve et guidee). `null` pour l'enseignant.
  final String? prenomEleve;

  final HorlogeSeance? horloge;
  final ConnexionSeance connexion;

  /// Le serveur a confirme l'enregistrement (I-1). Sans confirmation, aucune
  /// mention.
  final bool enregistrementConfirme;

  final VisiteSeance? visite;

  /// La file de recitation (EN-9) : identifiants d'academie, ou prenoms en
  /// demonstration (`cleEleveSeance`). Aucun minuteur par eleve ni
  /// evaluation (E8, E9).
  final FileRecitation recitation;

  /// L'enseignant vient d'appeler discretement cet eleve (EN-9, E16).
  final bool appelRecu;

  /// `null` : rien n'est partage.
  final SupportSeance? support;
  final bool cameraEnseignantActive;

  /// La politique du profil autorise la camera de l'eleve (ADR-009).
  final bool cameraAutorisee;

  /// Le micro est refuse par le systeme de l'appareil (P09) : signal du
  /// moteur (BR-1), jamais detecte par l'ecran. Le geste Micro ouvre alors
  /// la feuille « micro bloque » et le micro reste montre coupe (P09.6).
  final bool microBloque;

  /// Barres de signal de la video de l'enseignant (0 a 3), lues seulement
  /// par l'enseignant.
  final int signalEnseignant;

  /// Les inscrits : source unique du compteur, du panneau et du
  /// recapitulatif (I-6).
  final List<EleveSeance> eleves;

  /// Faux quand la liste n'a pas pu etre lue (J3) : aucun compteur, jamais
  /// un zero invente.
  final bool elevesConnus;
  final List<SupportDisponible> supports;

  /// Non nul : la seance est finie.
  final FinSeance? fin;
  final PanneauOuvert panneau;

  /// Notifications non lues de la personne devant l'ecran : le point de la
  /// cloche (CLV-04, CLV-06 desktop). La guidee n'a pas de cloche.
  final int notificationsNonLues;

  /// La Classe de la seance : l'entree « Classes » du rail y mene.
  final String? groupeId;

  /// MA-5 : le tutoiement suit la situation (mineur ou adulte), jamais la
  /// presentation (MA1, deux axes). `null` : le choix par le role (la
  /// guidee tutoie).
  final bool? tutoiement;

  // --- Supports et tableau (TB-1b, plan V2 §2, §8) : donnees pures ---
  //
  // Aucun widget ne les lit encore : la salle s'affiche comme avant. Les
  // etapes TB-2 et suivantes les rendront.

  /// L'affichage partage choisi par l'enseignant. Sans objet sans
  /// [supportPresente] : la surface est alors le tableau libre (PED-01).
  final AffichagePartage affichage;

  /// Le support a page fixe presente a la classe, ou `null` : aucun (un
  /// seul a la fois, TB2).
  final SupportPageFixe? supportPresente;

  /// Le tableau libre de la seance, ou `null` : non connu de cette vue.
  final TableauLibre? tableauLibre;

  /// L'enregistrement, a trois valeurs (inconnu par defaut). La mention
  /// existante (`enregistrementConfirme`) n'est pas touchee (HU-1).
  final EtatEnregistrement enregistrement;

  /// Le controle, ou `null` : la donnee manque, aucun oeil (TB-BR-24).
  final EtatControle? controle;

  /// Le contexte deplie depuis la capsule (TB-3), etat local d'interface.
  final ContexteOuvert contexte;

  /// TB-7a (plan V2 §9) : les traits valides de la surface (etat partage),
  /// chacun ancre a une page de support ou au tableau libre, en
  /// coordonnees normalisees de la page. La surface ne peint que ceux de la
  /// page montree ([notesAffichees]). Vide hors demonstration tant que le
  /// contrat des traits n'est pas branche (TB-BR).
  final List<TraitVectoriel> notesSurface;

  /// TB-9 (plan V2 §2, §3 « Ranger reellement », §19.2) : les supports
  /// ranges pendant la seance, chacun a la page ou il a ete range (son point
  /// de reprise). Ranger n'efface rien : leurs notes restent dans
  /// [notesSurface], attachees a leur page ; « Presenter » les retrouve.
  /// Donnee de la seance seulement, jamais une sauvegarde (TB-BR).
  final List<SupportPageFixe> supportsRanges;

  bool get _tutoie => tutoiement ?? _guidee;

  bool get _enseignant => role == RoleSeance.enseignant;
  bool get _guidee => role == RoleSeance.guidee;
  bool get estFinie => fin != null;

  // --- En-tete (matrice section 1, I-9) ---

  /// « Seance en direct » ou « Ma seance ».
  String get titre =>
      _guidee ? t.salle.seance.titreGuidee : t.salle.seance.titre;

  /// La ligne d'etat sous le titre, ou `null` (guidee : aucun sous-titre).
  ///
  /// Eleve : « Classe · Enseignant », et « La seance se poursuit. » en texte
  /// simple apres l'heure de fin. Enseignant : « Classe · 32 min restantes »
  /// ou « Classe · La seance se poursuit. », jamais son propre nom.
  String? get ligneEtat {
    switch (role) {
      case RoleSeance.guidee:
        return null;
      case RoleSeance.eleve:
        // `/salle` ne connait pas encore le nom de la Classe (BR-1).
        final String base = nomClasse.isEmpty
            ? nomEnseignant
            : t.salle.seance.ligne(debut: nomClasse, fin: nomEnseignant);
        return horloge is HorlogeDepassee
            ? t.salle.seance.ligne(debut: base, fin: t.salle.seance.sePoursuit)
            : base;
      case RoleSeance.enseignant:
        final String? suite = switch (horloge) {
          HorlogeRestante(:final int minutes) =>
            t.salle.seance.minutesRestantes(minutes: minutes),
          HorlogeDepassee() => t.salle.seance.sePoursuit,
          null => null,
        };
        if (nomClasse.isEmpty) return suite;
        return suite == null
            ? nomClasse
            : t.salle.seance.ligne(debut: nomClasse, fin: suite);
    }
  }

  /// La duree restante n'est lue que par l'enseignant.
  bool get voitDureeRestante => _enseignant;

  /// Le libelle de la pastille de connexion : « En ligne » tant que la room
  /// est connectee, meme en reseau faible (P06.5).
  String get texteConnexion =>
      connexion.etablie ? t.salle.seance.enLigne : t.salle.seance.reconnexion;

  // --- Ecrans de secours (lot CL-7, P05, P06, P09 a P12) ---

  /// Le bandeau non bloquant (reseau faible, reconnexion), ou `null`.
  String? get texteBandeau => switch (connexion) {
    ConnexionSeance.reseauFaible =>
      _guidee
          ? t.salle.secours.reseauFaibleGuidee
          : t.salle.secours.reseauFaible,
    ConnexionSeance.reconnexion =>
      _guidee ? t.salle.secours.reconnexionGuidee : t.salle.secours.reconnexion,
    ConnexionSeance.enLigne ||
    ConnexionSeance.retablie ||
    ConnexionSeance.echec ||
    ConnexionSeance.horsLigne => null,
  };

  /// Le sous-texte du bandeau : guidee en reseau faible seulement.
  String? get sousTexteBandeau =>
      _guidee && connexion == ConnexionSeance.reseauFaible
      ? t.salle.secours.reseauFaibleGuideeSuite
      : null;

  /// Le retour bref « Connexion retablie. », ou `null`.
  String? get texteRetabli =>
      connexion == ConnexionSeance.retablie ? t.salle.secours.retablie : null;

  /// Le bloc d'erreur remplace le bandeau : reconnexion impossible ou hors
  /// ligne confirme. La salle reste montee.
  bool get voitBlocEchec =>
      connexion == ConnexionSeance.echec ||
      connexion == ConnexionSeance.horsLigne;

  /// Le titre du bloc d'erreur, ou `null`. La guidee n'a qu'un texte pour
  /// les deux etats (S l.775).
  String? get titreEchec {
    if (!voitBlocEchec) return null;
    if (_guidee) return t.salle.secours.echecGuidee;
    return connexion == ConnexionSeance.echec
        ? t.salle.secours.echec
        : t.salle.secours.horsLigne;
  }

  /// Le bloc d'erreur offre la sortie : toujours en echec ; hors ligne,
  /// seulement en guidee (S l.655 : « Reessayer » seul).
  bool get echecPermetQuitter =>
      connexion == ConnexionSeance.echec ||
      (connexion == ConnexionSeance.horsLigne && _guidee);

  /// La sortie du bloc d'erreur : « Quitter » en guidee, « Quitter la
  /// seance » ailleurs (la confirmation existante suit).
  String get libelleQuitterEchec =>
      _guidee ? t.salle.secours.quitter : t.salle.seance.sortir;

  /// Micro et Camera repondent-ils ? Faux tant que la connexion n'est pas
  /// etablie : les boutons restent rendus, desactives (UX_REVIEW U1).
  bool get commandesPublicationActives =>
      connexion != ConnexionSeance.reconnexion &&
      connexion != ConnexionSeance.echec &&
      connexion != ConnexionSeance.horsLigne;

  /// Le libelle d'accessibilite d'une commande desactivee, ou `null`.
  String? libelleIndisponible(String commande) => commandesPublicationActives
      ? null
      : t.salle.secours.indisponible(commande: commande);

  /// Le statut non interactif de l'eleve standard sans camera (P10.3), ou
  /// `null`. Guidee : ni bouton ni explication ; enseignant : sans objet.
  String? get texteCameraInterdite =>
      role == RoleSeance.eleve && !cameraAutorisee && optionQS1
      ? t.salle.secours.cameraInterdite
      : null;

  /// Le corps de la feuille « micro bloque » (P09).
  String get texteMicroBloque =>
      _guidee ? t.salle.secours.microBloqueGuidee : t.salle.secours.microBloque;

  /// Le compte en haut a droite : TOUJOURS celui de la personne devant
  /// l'ecran (I-9). L'enseignant ne voit jamais le compte d'un eleve.
  CompteSeance get compte => _enseignant || prenomEleve == null
      ? CompteSeance(nom: nomEnseignant, initiales: initialesEnseignant)
      : CompteSeance(
          nom: prenomEleve!,
          // Un grapheme entier (lettre arabe avec haraka) ; vide sans prenom.
          initiales: prenomEleve!.characters.isEmpty
              ? ''
              : prenomEleve!.characters.first.toUpperCase(),
        );

  /// Guidee : ni theme, ni cloche, ni reglages, ni menu de compte.
  bool get voitReglagesEnTete => !_guidee;

  // --- Appel discret (EN-9, E16) ---

  /// Ce que voit l'eleve appele : le titre et le nom de l'enseignant viennent
  /// des donnees (« Sayyid Ibrahim vous appelle »), jamais « Le professeur ».
  String? get texteAppel => !_enseignant && appelRecu && !estFinie
      ? t.salle.seance.vousAppelle(nom: nomEnseignant)
      : null;

  // --- Mention et notice (I-1, I-2) ---

  /// Le texte de la mention d'enregistrement, ou `null` (non confirme, fin).
  String? get texteMention {
    if (!enregistrementConfirme || estFinie) return null;
    return _guidee && optionQ5
        ? t.salle.seance.coursEnregistreCourt
        : t.salle.bandeauPermanent;
  }

  /// La visite est-elle annoncee a ce role ? Toujours a l'enseignant ;
  /// a un eleve seulement si c'est son parent qui observe.
  bool get visiteVisible =>
      visite != null &&
      texteMention != null &&
      (_enseignant || visite!.concerneMoi);

  /// La notice de visite, qui remplace le texte de la mention, ou `null`.
  String? get texteNotice {
    if (!visiteVisible) return null;
    return switch (role) {
      RoleSeance.eleve || RoleSeance.guidee =>
        _tutoie
            ? t.salle.seance.tonParentObserve
            : t.salle.seance.votreParentObserve,
      // Vague Enseignant : « Un parent observe cette seance », sans prenom
      // (02_DECOUPAGE, detail EN-9 ; choix provisoire consigne au directeur).
      RoleSeance.enseignant => t.salle.seance.unParentObserve,
    };
  }

  /// Le point clignote pendant une visite visible, jamais en guidee (S l.781).
  bool get pointClignote => visiteVisible && !_guidee;

  /// L'icone oeil accompagne la notice en guidee seulement.
  bool get voitOeilNotice => visiteVisible && _guidee;

  // --- Commandes reservees a l'enseignant (I-4, I-6, I-10) ---

  bool get voitCompteurEleves => _enseignant;
  bool get voitBoutonsPanneaux => _enseignant;

  /// Les outils d'enseignement (onglet « Outils » des Commandes, TB-4) :
  /// enseignant, un support montre.
  bool get voitOutils => _enseignant && support != null;

  /// TB-4 (CMD-01) : le declencheur « Commandes » et son panneau. Enseignant
  /// seulement : l'eleve ne voit ni Bibliotheque, ni affichages, ni page
  /// partagee (TB14, plan V2 §5) ; son contenu propre (lecture, focus,
  /// ecriture autorisee) vient avec TB-10. Le declencheur n'est rendu que si
  /// une de ses entrees a un rappel (UX_REVIEW_TB §3 bis).
  bool get voitCommandes => _enseignant && !estFinie;

  /// « Support », « Avec notes », « Tableau » : invisibles sans support
  /// presente (plan V2 §4.2) ; jamais chez l'eleve.
  bool get voitAffichagesPartages => _enseignant && supportPresente != null;

  /// TB-9 : « Ranger dans la bibliotheque », au menu du titre du support
  /// presente ; enseignant seulement, jamais chez l'eleve (TB14).
  bool get voitRanger => _enseignant && supportPresente != null && !estFinie;

  /// TB-9 (plan V2 §12) : « Effacer les notes » de la surface montree (la
  /// page du support, ou le tableau libre), quand des notes s'y voient ;
  /// jamais en « Support » (notes cachees), jamais chez l'eleve.
  bool get voitEffacerNotes {
    if (!_enseignant || estFinie) return false;
    final VueSurface surface = vueSurface;
    if (surface == VueSurface.supportSeul) return false;
    if (notesAffichees.isNotEmpty) return true;
    return surface == VueSurface.tableauLibre &&
        (tableauLibre?.aDesNotes ?? false);
  }

  /// TB-9 : l'effacement porte sur le tableau libre (« … du tableau ? »),
  /// sinon sur la page du support (« … de cette page ? »).
  bool get effacementDuTableau => vueSurface == VueSurface.tableauLibre;

  /// TB-9 : le nombre de notes de la seance attachees a un support range
  /// (toutes pages de sa version) : la carte dit qu'elles sont conservees.
  int notesDuSupport(SupportPageFixe range) => notesSurface
      .where(
        (TraitVectoriel trait) =>
            trait.ancrage.resourceId == range.id &&
            trait.ancrage.resourceVersionId == range.version,
      )
      .length;
  bool get voitSignalVideo => _enseignant;

  /// Le rail de navigation enseignant : desktop seulement (image CLV-06).
  bool voitRail(Gabarit gabarit) => _enseignant && gabarit == Gabarit.desktop;

  /// Quitter mene l'enseignant au cahier de transmission (S l.861-863).
  bool get quitterOuvreCahier => _enseignant;

  /// Guidee : la vignette est plus grande (S CLV-05, ≈ 160 a 300 de large).
  bool get vignetteAgrandie => _guidee;

  /// Q8 : guidee desktop, la video dans une colonne a droite du support,
  /// jamais par-dessus. Ailleurs, la vignette reste en coin du support.
  bool videoACoteDuSupport(Gabarit gabarit) =>
      _guidee && optionQ8 && gabarit == Gabarit.desktop;

  /// Guidee : le micro s'appelle « Parler » et les disques Parler et Camera
  /// sont pleins (Q1).
  bool get dockColore => _guidee && optionQ1;

  /// Connectes maintenant, derive de la liste (I-6).
  int get connectes => eleves
      .where((EleveSeance e) => e.statut == StatutEleveSeance.connecte)
      .length;

  /// Inscrits de la Classe.
  int get inscrits => eleves.length;

  /// « Eleves 1/3 », ou `null` hors enseignant.
  String? get compteurEleves => _enseignant && elevesConnus
      ? t.salle.seance.compteurEleves(connectes: connectes, inscrits: inscrits)
      : null;

  /// Le recapitulatif de fin (CLV-10) : enseignant seulement, seance finie.
  /// L'eleve et la guidee ne voient jamais ni presence ni recapitulatif.
  bool get voitRecapitulatifFin => _enseignant && fin != null;

  /// Connectes au moins une fois (recapitulatif de fin, meme source).
  int get connectesAuMoinsUneFois =>
      eleves.where((EleveSeance e) => e.aEteConnecte).length;

  // --- Barre du support (I-5, I-7) ---

  /// « Page {numero} sur {total} » et ses fleches, qui changent la page de
  /// tous : enseignant, dans les Commandes, a toutes les tailles (TB-4,
  /// UX_REVIEW_TB n. 10).
  bool get voitPaginationCommandes =>
      _enseignant && (support != null || supportPresente != null);

  /// La page montree dans les Commandes : celle du support presente, sinon
  /// celle de la diapositive, ou `null` sans support.
  ({int page, int total})? get pageCommandes {
    final SupportPageFixe? fixe = supportPresente;
    if (fixe != null) return (page: fixe.page, total: fixe.total);
    final SupportSeance? diapositive = support;
    if (diapositive != null) {
      return (page: diapositive.page, total: diapositive.pages);
    }
    return null;
  }

  /// Lecture (zoom local, « Ajuster a l'ecran ») et Affichage (Focus) dans
  /// les Commandes : enseignant, un support montre ; rien n'est diffuse.
  bool get voitLectureCommandes => _enseignant && support != null;

  /// « 1 / 12 » en lecture seule : eleve standard, desktop.
  bool voitIndicateurPage(Gabarit gabarit) =>
      role == RoleSeance.eleve && support != null && gabarit == Gabarit.desktop;

  /// Zoom local : enseignant, et eleve standard si Q6 ; jamais en guidee.
  bool voitZoomLocal(Gabarit gabarit) =>
      support != null &&
      gabarit == Gabarit.desktop &&
      (_enseignant || (role == RoleSeance.eleve && optionQ6));

  /// Le dock, dans l'ordre (I-4).
  ///
  /// TB-2 (VIS-01, plan V2 §4.1, UX_REVIEW_TB n. 1) : la barre de l'appel
  /// est Micro, Camera, Quitter, dans cet ordre. Agrandir la quitte (le
  /// Focus est dans Commandes ; la salle garde « Reduire » tant que le focus
  /// local est actif, [DockSeance.agrandi]) ; Reseau la quitte (un
  /// indicateur, D5). TB-4 (CMD-01) : Supports devient la Bibliotheque des
  /// Commandes, les outils leur onglet « Outils » ; Partager, sans effet
  /// avant BR-1, n'est pas repris (« Presenter » de la Bibliotheque, TB-8).
  List<CommandeDock> get commandesDock => switch (role) {
    RoleSeance.enseignant => const <CommandeDock>[
      CommandeDock.micro,
      CommandeDock.camera,
      CommandeDock.quitter,
    ],
    RoleSeance.eleve || RoleSeance.guidee => <CommandeDock>[
      CommandeDock.micro,
      if (cameraAutorisee) CommandeDock.camera,
      CommandeDock.quitter,
    ],
  };

  /// TB-2 (plan V2 §18.1) : la barre de l'appel reste visible, sans
  /// masquage temporise : un panneau ouvert, une erreur critique de
  /// connexion (reconnexion, echec, hors ligne) ou de media (micro refuse
  /// par le systeme, P09).
  bool get visioMaintenue =>
      (voitBoutonsPanneaux && panneau != PanneauOuvert.aucun) ||
      // TB-3 : le contexte deplie est un panneau ouvert (TB7).
      contexteOuvert ||
      !commandesPublicationActives ||
      microBloque;

  // --- Capsule et contexte (TB-3 : UI-01, CTX-01, CTX-02 ; plan V2 §4.3) ---

  /// Pendant le partage, la capsule compacte remplace la vignette video :
  /// avatar statique, temoin d'enregistrement reel, oeil du controle. Hors
  /// partage, la vignette reste (00_REPRISE §6.5).
  ///
  /// Le partage est celui du chantier (plan V2 §8) : un support PRESENTE a
  /// la classe ([supportPresente], TB-1b), affiche par la surface
  /// ([support]). Les etats anterieurs (diapositive seule) et la Classe
  /// Live, qui ne portent pas encore [supportPresente] (TB-BR), gardent la
  /// vignette.
  bool get voitCapsule =>
      supportPresente != null && support != null && !estFinie;

  /// La vignette video de l'enseignant se pose sur la surface : jamais
  /// pendant le partage (la capsule la remplace), et seulement si la camera
  /// de l'enseignant publie.
  bool get voitVignetteSurSupport => cameraEnseignantActive && !voitCapsule;

  /// TB-6 (plan V2 §12) : sur le tableau libre, la phrase « Choisissez un
  /// support ou ecrivez au tableau. » s'adresse a qui peut choisir le
  /// support : l'enseignant ; l'eleve voit le tableau sans consigne.
  bool get voitConsigneTableauLibre => role == RoleSeance.enseignant;

  /// Le contexte deplie se montre : seulement depuis la capsule.
  bool get contexteOuvert => voitCapsule && contexte != ContexteOuvert.aucun;

  /// Le point rouge : seulement si l'enregistrement est ACTIF (UX-12, TB12).
  /// Inactif ou inconnu : aucun point, jamais un voyant qui pretend.
  bool get voitPointEnregistrement =>
      enregistrement == EtatEnregistrement.actif && !estFinie;

  /// L'oeil : seulement si la donnee du controle existe (§4.3).
  bool get voitOeilControle => controle != null;

  /// Le nom lu de l'avatar de la capsule (§20) : « Afficher les informations
  /// de Sayyid Ibrahim » ; le nom n'est jamais ecrit dans la capsule.
  String get libelleAvatarCapsule =>
      t.salle.seance.capsule.avatar(nom: nomEnseignant);

  /// Le nom lu de l'oeil (§20), ou `null` sans donnee.
  String? get libelleOeilCapsule => switch (controle) {
    EtatControle.possible => t.salle.seance.capsule.controlePossible,
    EtatControle.actif => t.salle.seance.capsule.controleActif,
    null => null,
  };

  /// L'etat du controle ecrit dans le contexte, ou `null` sans donnee.
  String? get texteControle => switch (controle) {
    EtatControle.possible => t.salle.seance.contexte.controlePossible,
    EtatControle.actif => t.salle.seance.contexte.controleActif,
    null => null,
  };

  /// L'explication sous l'etat du controle : un controle possible ne dit
  /// pas qu'une personne observe maintenant (§19.6).
  String? get explicationControle => switch (controle) {
    EtatControle.possible => t.salle.seance.contexte.controlePossibleDetail,
    EtatControle.actif => t.salle.seance.contexte.controleActifDetail,
    null => null,
  };

  /// Le nom lu de « Reduire » (§20) : le panneau des participants de
  /// l'enseignant, ou les informations de la seance d'un eleve.
  String get libelleReduireContexte => _enseignant
      ? t.salle.seance.contexte.reduireParticipants
      : t.salle.seance.contexte.reduireInformations;

  // --- Surface pedagogique (TB-1b) ---

  /// Ce que montre la surface (PED-01 a PED-04), derive de l'etat partage.
  VueSurface get vueSurface {
    if (supportPresente == null) return VueSurface.tableauLibre;
    return switch (affichage) {
      AffichagePartage.support => VueSurface.supportSeul,
      AffichagePartage.avecNotes => VueSurface.supportAvecNotes,
      AffichagePartage.tableau => VueSurface.tableauSupportMasque,
    };
  }

  /// TB-7a : l'ancrage des notes de la surface montree : la page presentee
  /// (ressource, version, numero), ou la feuille du tableau libre. Un trait
  /// d'une autre page ou d'une autre version ne s'y peint jamais (§13 :
  /// « ancien trait recu sur une nouvelle page »).
  ContentPosition? get ancrageSurface {
    final SupportPageFixe? page = supportPresente;
    if (page != null) {
      return ContentPosition.page(
        resourceId: page.id,
        resourceVersionId: page.version,
        page: page.page,
      );
    }
    if (tableauLibre != null) {
      return const ContentPosition.page(
        resourceId: TableauLibre.idRessource,
        page: 1,
      );
    }
    return null;
  }

  /// Les notes de la surface montree, et elles seules.
  List<TraitVectoriel> get notesAffichees {
    final ContentPosition? ancrage = ancrageSurface;
    if (ancrage == null) return const <TraitVectoriel>[];
    return <TraitVectoriel>[
      for (final TraitVectoriel trait in notesSurface)
        if (trait.ancrage == ancrage) trait,
    ];
  }

  /// Les inscrits autorises a ecrire (Participants, TB15).
  List<EleveSeance> get elevesAutorisesAEcrire =>
      eleves.where((EleveSeance e) => e.peutEcrire).toList();

  /// La personne devant l'ecran peut-elle ecrire ? L'enseignant toujours ;
  /// un eleve seulement si sa ligne porte l'autorisation (TB14). En
  /// demonstration, l'eleve est retrouve par son prenom.
  bool get peutEcrire =>
      _enseignant ||
      (prenomEleve != null &&
          eleves.any(
            (EleveSeance e) => e.prenom == prenomEleve && e.peutEcrire,
          ));

  /// Copie modifiee.
  VueSeance copyWith({
    RoleSeance? role,
    HorlogeSeance? horloge,
    bool sansHorloge = false,
    ConnexionSeance? connexion,
    VisiteSeance? visite,
    bool sansVisite = false,
    FileRecitation? recitation,
    bool? appelRecu,
    SupportSeance? support,
    bool sansSupport = false,
    bool? enregistrementConfirme,
    bool? cameraAutorisee,
    bool? microBloque,
    List<EleveSeance>? eleves,
    FinSeance? fin,
    PanneauOuvert? panneau,
    bool? tutoiement,
    AffichagePartage? affichage,
    SupportPageFixe? supportPresente,
    bool sansSupportPresente = false,
    TableauLibre? tableauLibre,
    EtatEnregistrement? enregistrement,
    EtatControle? controle,
    bool sansControle = false,
    ContexteOuvert? contexte,
    List<TraitVectoriel>? notesSurface,
    List<SupportPageFixe>? supportsRanges,
  }) => VueSeance(
    role: role ?? this.role,
    nomClasse: nomClasse,
    nomEnseignant: nomEnseignant,
    initialesEnseignant: initialesEnseignant,
    prenomEleve: prenomEleve,
    horloge: sansHorloge ? null : horloge ?? this.horloge,
    connexion: connexion ?? this.connexion,
    enregistrementConfirme:
        enregistrementConfirme ?? this.enregistrementConfirme,
    visite: sansVisite ? null : visite ?? this.visite,
    recitation: recitation ?? this.recitation,
    appelRecu: appelRecu ?? this.appelRecu,
    support: sansSupport ? null : support ?? this.support,
    cameraEnseignantActive: cameraEnseignantActive,
    cameraAutorisee: cameraAutorisee ?? this.cameraAutorisee,
    microBloque: microBloque ?? this.microBloque,
    signalEnseignant: signalEnseignant,
    eleves: eleves ?? this.eleves,
    elevesConnus: elevesConnus,
    supports: supports,
    fin: fin ?? this.fin,
    panneau: panneau ?? this.panneau,
    notificationsNonLues: notificationsNonLues,
    groupeId: groupeId,
    tutoiement: tutoiement ?? this.tutoiement,
    affichage: affichage ?? this.affichage,
    supportPresente: sansSupportPresente
        ? null
        : supportPresente ?? this.supportPresente,
    tableauLibre: tableauLibre ?? this.tableauLibre,
    enregistrement: enregistrement ?? this.enregistrement,
    controle: sansControle ? null : controle ?? this.controle,
    contexte: contexte ?? this.contexte,
    notesSurface: notesSurface ?? this.notesSurface,
    supportsRanges: supportsRanges ?? this.supportsRanges,
  );
}
