// Un fil de discussion generique : messages, champ de saisie, envoi honnete
// (CT-6, premier composant de fil du depot, prouve absent dans
// `14_controleur/CONTROLEUR_EXISTING_MAPPING.md`).
//
// Aucune logique de role ici : les textes, les messages et l'envoi viennent
// de l'ecran appelant. Le composant ne promet rien qu'il ne tient : un
// message ecrit reste « en cours » tant que l'envoi n'a pas repondu, passe a
// « envoye » sur reponse, et a « echec » avec « Reessayer » sinon, sa saisie
// gardee (jamais de faux succes).
//
// COM-FUS : chaque message ecrit porte un identifiant local unique, transmis
// a l'envoi ([FilDiscussion.onEnvoyerMessage]) : l'ecran y attache sa cle
// d'idempotence (COM-BR-02), rejouee au nouvel essai de CETTE bulle, meme si
// deux bulles ont le meme texte. Un message peut porter un complement sous
// son texte ([MessageFil.complement], par exemple le lecteur d'un vocal).
//
// COM-RC (revue COM-R) :
// - R-02 : a texte agrandi ou sur une vue basse, l'en-tete defile avec les
//   messages (premier element de la liste), et la saisie aussi, apres le
//   dernier message (COM-RC tour 3) ; les actions de l'espace de travail
//   (retour, panneau de contexte) se posent dans la rangee de l'en-tete ;
//   sinon, la saisie, vocal compris, est bornee a 40 % de la hauteur et
//   defile elle-meme ;
// - R-04 : pendant l'enregistrement et la pre-ecoute d'un vocal, son
//   panneau remplace la rangee texte (un seul « Envoyer » a l'ecran) ;
// - R-22 : le fil porte la persistance du brouillon de son champ
//   ([FilDiscussion.cleBrouillon]) et accepte un controleur exterieur ; la
//   persistance (`PersistanceBrouillon`) est celle qu'emploie aussi le
//   composer de reponse de la Communaute (COM-RC tour 2) ;
// - R-24 : un fil sans message le dit (« Aucun message pour le moment ») ;
// - R-25 : Ctrl+Entree (Cmd+Entree) envoie, Entree garde le saut de ligne ;
// - R-07 : un mode lecture seule ([FilDiscussion.lectureSeule]) : les memes
//   bulles, l'en-tete qui defile avec elles, puis la phrase qui dit la
//   limite ; ni champ ni bouton. Messages metier et canaux du Studio le
//   lisent tous deux, au lieu de leurs deux copies.
//
// COM-RC tour 4 (contre-verification COM-R-2) :
// - N-1 : quand l'en-tete defile (texte agrandi, vue basse, lecture seule),
//   une ligne compacte de contexte ([FilDiscussion.enteteCompacte] :
//   interlocuteur, objet, et les actions de l'espace dont (i)) reste fixe
//   au-dessus de la liste ; le reste de l'en-tete
//   ([FilDiscussion.enteteSuite]) defile. Le fil ne s'ouvre plus jamais
//   sans son contexte, a 390 en texte x1 comme a 320 en texte x2 ;
// - N-3 : vider le champ a l'envoi n'efface pas le brouillon ; il n'est
//   efface qu'a l'accuse, si le champ est encore vide et que plus rien
//   n'attend ;
// - N-4 : [FilDiscussion.demandeSaisieVisible] ramene la saisie a l'ecran
//   quand elle defile avec les messages (entree dans le Focus du Studio) ;
// - N-6 : les seuils de bascule viennent de `SeuilsTexteAgrandi` ;
// - N-9 : une marge basse sous la saisie bornee quand le panneau vocal
//   l'occupe : il ne touche plus la barre de navigation ni le bord.
//
// COM-RC tour 5, lot H (COM-R-3, section 7.3, et decisions du directeur) :
// - constat 1 : le brouillon d'un message s'efface a SON accuse, meme
//   arrive apres la fermeture du fil, s'il garde encore ce texte ; un echec
//   ne bloque plus rien, et un texte envoye ne revient jamais dans le champ ;
// - constat 2 : en lecture seule, l'en-tete complet reste fixe hors texte
//   agrandi et hors vue basse ; la ligne compacte n'y sert que quand la
//   hauteur l'exige ;
// - constat 3 (N-9) : quand le panneau vocal occupe la saisie bornee, sa
//   borne monte et la saisie va a son bas : le panneau se lit en entier ;
//   dans la liste, le fil va a son bas ;
// - constat 8 : la ligne compacte porte le retour de la page
//   ([FilDiscussion.retourCompacte]) quand la tete de la page defile ;
// - decision « Focus a 320 » : [FilDiscussion.saisieReduite] reduit la
//   saisie a une ligne a texte agrandi sur un telephone etroit, tant que le
//   champ est vide et sans focus : une bulle au moins reste a l'ecran ;
// - decision R-28 : un micro a cote d'« Envoyer » ouvre l'enregistrement
//   ([MicroVocalFil], [DemandeVocalFil]), a la place du lien sous le champ.
// - contre-verification du lot H : un texte en attente d'accuse est tenu
//   par la persistance (`PersistanceBrouillon.marquerEnAttente`) ; un fil
//   rouvert avant l'accuse ne le remet pas dans son champ, et a l'accuse un
//   fil qui montre encore ce texte remis, sans modification, vide son champ.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accessibilite/sens_du_contenu.dart';
import '../accessibilite/texte_agrandi.dart';
import '../communications/apercu_image.dart';
import '../communications/image_bulle.dart';
import '../communications/image_message.dart';
import '../communications/pastille_coeur.dart';
import '../communications/persistance_brouillon.dart';
import '../communications/phrases_images.dart';
import '../communications/port_brouillons.dart';
import '../fichiers/compression_image.dart';
import '../fichiers/selecteur_image.dart';
import '../fluidite/action_anticipee.dart';
import '../i18n/dates_appareil.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/apparition_douce.dart';
import '../mouvement/mouvement.dart';
import '../tc_horloge/mon_horloge.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';
import 'empty_state.dart';
import 'espace_travail_adaptatif.dart';
import 'menu_actions.dart';
import 'menu_commun.dart' show MenuAncreControleur;
import 'page_shell.dart';
import 'pressable.dart';
import 'zone_saisie.dart';

/// Le raccourci d'envoi au clavier (R-25) : Ctrl+Entree, ou Cmd+Entree sur
/// Mac, declenche [onEnvoyer] quand le focus est dans [child]. Entree seule
/// n'est pas prise : elle garde le saut de ligne du champ.
Widget raccourciEnvoi({
  required VoidCallback onEnvoyer,
  required Widget child,
}) => CallbackShortcuts(
  bindings: <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.enter, control: true): onEnvoyer,
    const SingleActivator(LogicalKeyboardKey.enter, meta: true): onEnvoyer,
    const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
        onEnvoyer,
    const SingleActivator(LogicalKeyboardKey.numpadEnter, meta: true):
        onEnvoyer,
  },
  child: child,
);

/// Ce qu'un panneau vocal pose dans [FilDiscussion.emplacementVocal] dit au
/// fil (R-04) : [ouvert] pendant l'enregistrement, la pre-ecoute et l'envoi,
/// la rangee texte s'efface ; ferme, elle revient, son texte garde.
class PanneauVocalFil extends Notification {
  /// Cree l'avis.
  const PanneauVocalFil({required this.ouvert});

  /// Vrai quand le panneau vocal occupe la saisie.
  final bool ouvert;
}

/// Ce que le composer vocal pose dans [FilDiscussion.emplacementVocal] dit
/// de son micro (decision R-28) : [disponible], le fil pose le bouton micro
/// a cote d'« Envoyer » ; sinon, aucun bouton qui ne peut aboutir.
class MicroVocalFil extends Notification {
  /// Cree l'avis.
  const MicroVocalFil({required this.disponible});

  /// Vrai quand un enregistreur repond et qu'un enregistrement peut partir.
  final bool disponible;
}

/// La portee par laquelle le micro de la rangee d'envoi demande un
/// enregistrement au composer vocal (decision R-28) : chaque toucher
/// incremente [demandes]. Hors d'un fil, le composer garde son entree
/// « Enregistrer un message vocal ».
class DemandeVocalFil extends InheritedWidget {
  /// Cree la portee.
  const DemandeVocalFil({
    required this.demandes,
    required super.child,
    super.key,
  });

  /// Le compteur des touchers du micro.
  final ValueListenable<int> demandes;

  /// Les demandes du fil qui entoure [context], ou `null` hors d'un fil.
  static ValueListenable<int>? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemandeVocalFil>()?.demandes;

  @override
  bool updateShouldNotify(DemandeVocalFil ancien) =>
      !identical(ancien.demandes, demandes);
}

/// Un message deja connu du fil (lu depuis le serveur ou la demonstration).
@immutable
class MessageFil {
  /// Cree le message.
  const MessageFil({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.horodatage,
    required this.deSoi,
    this.complement,
    this.annonceTexte,
    this.remise,
    this.instant,
    this.image,
    this.coeurs = 0,
    this.aimeParMoi = false,
  });

  /// IMAGES-MESSAGERIE : l'image du message, ou `null`.
  final ImageMessage? image;

  /// IMAGES-MESSAGERIE : le nombre de coeurs donnes.
  final int coeurs;

  /// IMAGES-MESSAGERIE : la personne qui lit a donne le sien.
  final bool aimeParMoi;

  /// Identifiant stable, pour qu'un message ne soit jamais annonce deux fois.
  final String id;

  /// Le nom de l'auteur tel qu'il s'affiche : « Vous », « Administration ».
  final String auteur;

  /// Le texte du message.
  final String texte;

  /// La date et l'heure, deja mises en mots par l'ecran.
  final String horodatage;

  /// Vrai pour un message de la personne qui lit le fil.
  final bool deSoi;

  /// Ce qui se pose sous le texte dans la bulle (lecteur d'un vocal recu,
  /// COM-VOC), ou `null` : rien.
  final Widget? complement;

  /// Le texte annonce a l'arrivee du message, quand il differe de [texte]
  /// (un vocal se dit par sa duree) ; `null` : [texte].
  final String? annonceTexte;

  /// MESSAGERIE-LU : pour un message de soi, envoye ou lu par l'autre partie ;
  /// `null` : aucun signe (le fil ne connait pas la lecture de l'autre).
  final RemiseMessage? remise;

  /// BULLES-MESSAGERIE : l'instant du message (UTC), d'ou viennent l'heure
  /// sous la bulle, les groupes de messages rapproches et les separateurs de
  /// jour ; `null` : le fil ne les calcule pas et garde [horodatage] sous la
  /// bulle.
  final DateTime? instant;
}

/// MESSAGERIE-LU (directeur, 14/11/2026, « comme WhatsApp ») : ou en est un
/// message de soi. Trois signaux, jamais la couleur seule : l'icone (horloge,
/// une coche, deux coches), le mot (« Envoi en cours », « Envoye », « Lu ») et
/// l'encre (pale tant qu'il n'est pas lu, foncee une fois lu).
enum RemiseMessage {
  /// L'envoi n'a pas encore repondu.
  enCours,

  /// Le serveur l'a recu ; l'autre partie ne l'a pas encore lu.
  envoye,

  /// L'autre partie l'a lu.
  lu,
}

/// Les textes du fil, fournis par l'ecran (cles i18n de son role).
@immutable
class TextesFilDiscussion {
  /// Cree les textes.
  const TextesFilDiscussion({
    required this.aideChamp,
    required this.libelleChamp,
    required this.envoyer,
    required this.champVide,
    required this.enCours,
    required this.envoye,
    required this.echec,
    required this.reessayer,
    required this.auteurSoi,
    required this.annonce,
    this.aucunMessageTitre,
    this.aucunMessage,
    this.brouillonRestaure,
    this.lu,
  });

  /// L'aide dans le champ vide : « Repondre a l'administration… ».
  final String aideChamp;

  /// L'etiquette du champ, lue par le lecteur d'ecran.
  final String libelleChamp;

  /// Le libelle du bouton d'envoi.
  final String envoyer;

  /// Pourquoi le bouton est inactif quand le champ est vide.
  final String champVide;

  /// Etat d'un message en cours d'envoi.
  final String enCours;

  /// Etat d'un message envoye (sur reponse seulement).
  final String envoye;

  /// Etat d'un message en echec, sa saisie gardee.
  final String echec;

  /// Le libelle du nouvel essai.
  final String reessayer;

  /// Le nom de l'auteur des messages ecrits ici : « Vous ».
  final String auteurSoi;

  /// L'annonce d'un message arrive pendant la lecture du fil.
  final String Function(String auteur, String texte) annonce;

  /// Le titre de l'etat vide (R-24) ; `null` : « Aucun message pour le
  /// moment ».
  final String? aucunMessageTitre;

  /// La phrase de l'etat vide ; `null` : celle du socle.
  final String? aucunMessage;

  /// La phrase dite tant qu'un brouillon remis n'a pas ete touche ; `null` :
  /// « Brouillon restaure ».
  final String? brouillonRestaure;

  /// L'etat d'un message de soi lu par l'autre partie (MESSAGERIE-LU) ;
  /// `null` : « Lu ».
  final String? lu;
}

/// L'etat d'envoi d'un message ecrit dans le fil.
/// Un envoi refuse pour une cause que « Reessayer » ne change pas (une limite
/// du jour, par exemple) : [phrase] dit la cause en mots simples sous le
/// message gardé, sans bouton qui ne pourrait pas aboutir (K-56, K-59).
class EnvoiRefuse implements Exception {
  /// Cree le refus.
  const EnvoiRefuse(this.phrase);

  /// La phrase du refus, deja traduite.
  final String phrase;
}

enum EtatEnvoiMessage {
  /// L'envoi n'a pas encore repondu.
  enCours,

  /// L'envoi a repondu.
  envoye,

  /// L'envoi a echoue : le texte est garde, « Reessayer » est propose.
  echec,
}

class _MessageLocal {
  _MessageLocal(
    this.id,
    this.texte,
    this.brut,
    this.action, {
    required this.cree,
    this.source,
  });

  /// L'heure de l'envoi : la bulle garde sa place dans l'ordre du fil, meme en
  /// echec (IMAGES-CORRECTIF).
  final DateTime cree;

  /// IMAGES-CORRECTIF : l'identifiant du message serveur des qu'il est cree, et
  /// celui du depot de l'image. La bulle locale le garde : la copie serveur du
  /// meme message ne s'affiche pas a cote d'elle.
  String? idMessage;
  String? idImage;

  /// IMAGES-MESSAGERIE : la photo choisie, pour une bulle d'image.
  final Uint8List? source;

  /// Prete (reduite, miniature faite) : la place de l'image est connue.
  ImagePrete? prete;

  /// L'envoi de l'image, de 0 a 1.
  final ValueNotifier<double> progression = ValueNotifier<double>(0);

  /// La phrase d'un echec que « Reessayer » peut changer (panne passagere).
  String? precision;

  final String id;
  final String texte;

  /// Le texte du champ tel qu'il etait a l'envoi, donc tel que le brouillon
  /// le garde (constat 1).
  final String brut;

  /// FLUIDITE-1 : l'envoi passe par l'outil commun d'affichage anticipe
  /// (`lib/core/fluidite/action_anticipee.dart`), sous la cle fixe [id] :
  /// « Reessayer » rejoue la meme. Un message est un CONTENU : en echec, sa
  /// bulle reste a sa place, « non confirme », avec « Reessayer » et
  /// « Supprimer » (menu de la bulle).
  final ActionAnticipee action;

  EtatEnvoiMessage get etat => switch (action.etat) {
    EtatAnticipe.enCours => EtatEnvoiMessage.enCours,
    EtatAnticipe.confirme => EtatEnvoiMessage.envoye,
    EtatAnticipe.echec => EtatEnvoiMessage.echec,
  };

  /// La phrase du refus quand l'envoi est refuse pour une cause que
  /// reessayer ne change pas (K-59) ; `null` : echec ordinaire. Notee par
  /// l'envoi lui-meme (voir `_envoyer`), avant que l'outil ne passe la bulle
  /// en echec.
  String? refus;
}

/// Le fil : la liste des messages, puis le champ et le bouton d'envoi ; ou,
/// en lecture seule ([lectureSeule]), la phrase qui dit la limite.
///
/// A poser dans une zone de hauteur bornee (`PageShell(defilante: false)`) :
/// la liste defile, le champ reste visible au-dessus du clavier (W-2411).
/// Entree fait un retour a la ligne ; le bouton envoie, et Ctrl+Entree
/// (Cmd+Entree) aussi (UX_REVIEW_08 ligne 12 e, R-25). Un message arrive ou
/// ecrit apres l'ouverture est annonce une fois (region live polie) ; ceux
/// presents a l'ouverture ne le sont pas.
///
/// A texte agrandi (au moins 150 %) ou sous 480 points de hauteur
/// (`SeuilsTexteAgrandi`), l'en-tete defile avec les messages, et la saisie
/// aussi, apres le dernier message : le fil s'ouvre sur le bas de la
/// saisie, « Envoyer » entier (R-02, COM-RC tour 3). La ligne compacte de
/// contexte ([enteteCompacte]), elle, reste fixe au-dessus (N-1). Sinon,
/// la saisie reste sous la liste et ne prend jamais plus de
/// [partSaisieMax] de la hauteur de l'ecran, ni plus de [partSaisieFilMax]
/// de celle du fil (clavier ouvert) : au-dela, elle defile (R-02).
class FilDiscussion extends StatefulWidget {
  /// Cree le fil, avec [onEnvoyer] ou [onEnvoyerMessage], ou en lecture
  /// seule avec [lectureSeule].
  const FilDiscussion({
    required this.messages,
    required this.textes,
    super.key,
    this.onEnvoyer,
    this.onEnvoyerMessage,
    this.entete,
    this.enteteCompacte,
    this.enteteSuite,
    this.demandeSaisieVisible = 0,
    this.emplacementPieceJointe,
    this.emplacementVocal,
    this.controleur,
    this.defilement,
    this.cleBrouillon,
    this.lectureSeule,
    this.retourCompacte,
    this.saisieReduite = false,
    this.pleinEcran = false,
    this.afficherAuteur = true,
    this.horloge = DateTime.now,
    this.prendTeteDePage = true,
    this.images,
    this.onAimer,
    this.onEnvoyerImage,
    this.onAnnulerImage,
    this.choisirImage = choisirImageSysteme,
    this.deuxChoixPhoto,
  }) : assert(
         lectureSeule != null || onEnvoyer != null || onEnvoyerMessage != null,
         'FilDiscussion demande onEnvoyer, onEnvoyerMessage ou lectureSeule.',
       );

  /// Les messages connus, du plus ancien au plus recent.
  final List<MessageFil> messages;

  /// IMAGES-MESSAGERIE : les adresses des images du fil (miniatures en UNE
  /// demande par fil, image complete a l'ouverture) ; `null` : aucune image.
  final SourceImagesFil? images;

  /// IMAGES-MESSAGERIE : pose (`true`) ou retire (`false`) son coeur sur le
  /// message ; l'affichage est immediat, retour arriere si l'appel echoue.
  /// `null` : pas de coeur.
  final Future<EtatCoeur> Function(String messageId, bool aime)? onAimer;

  /// IMAGES-MESSAGERIE : envoie un message avec son image (texte, image prete,
  /// progression). `null` : l'icone image n'est pas rendue (fil en lecture
  /// seule, ou compte eleve de moins de 18 ans : le serveur refuse de toute
  /// facon, l'ecran ne montre pas un bouton voue a l'echec).
  final Future<void> Function(
    String idLocal,
    String texte,
    ImagePrete image,
    ProgressionImage progression,
  )?
  onEnvoyerImage;

  /// IMAGES-CORRECTIF : abandonne le depot d'une bulle d'image supprimee
  /// apres un echec (`message_image_annuler`). `null` : la bulle disparait
  /// seule.
  final Future<void> Function(String imageId)? onAnnulerImage;

  /// Le choix d'une photo (le selecteur du systeme ; les tests le remplacent).
  final ChoixImage choisirImage;

  /// Vrai : l'icone image ouvre deux choix (« Prendre une photo », « Choisir
  /// dans la galerie »). `null` : vrai sur Android et iOS hors navigateur.
  final bool? deuxChoixPhoto;

  /// Les textes du fil.
  final TextesFilDiscussion textes;

  /// L'envoi d'un texte : le futur se termine sur la reponse, et echoue si
  /// le message n'est pas parti. Ignore si [onEnvoyerMessage] est donne.
  final Future<void> Function(String texte)? onEnvoyer;

  /// L'envoi d'un message avec son identifiant local, unique et stable
  /// d'un essai a l'autre de la meme bulle (COM-FUS) : l'ecran y attache sa
  /// cle d'idempotence (COM-BR-02).
  final Future<void> Function(String idLocal, String texte)? onEnvoyerMessage;

  /// Un en-tete pose au-dessus des messages (contexte du fil, COM-MSG), ou
  /// `null` : rien n'est rendu, le fil reste celui du controleur.
  final Widget? entete;

  /// La ligne compacte du contexte (interlocuteur, objet), ou `null`. Quand
  /// l'en-tete defile avec les messages (texte agrandi, vue basse, lecture
  /// seule), elle remplace [entete] et reste FIXE au-dessus de la liste, avec
  /// les actions de l'espace (retour, (i)) : le fil s'ouvre toujours sur son
  /// contexte (N-1). Sans elle, [entete] defile, comme avant.
  final Widget? enteteCompacte;

  /// Ce qui, de l'en-tete, defile avec les messages sous [enteteCompacte]
  /// (badge d'attention, « Mode focus »), ou `null` : rien.
  final Widget? enteteSuite;

  /// Un jeton : quand il change et que la saisie defile avec les messages,
  /// le fil va a son bas, la saisie entiere a l'ecran (N-4, entree dans le
  /// Focus du Studio). Hors de ce cas, rien ne bouge.
  final int demandeSaisieVisible;

  /// Ce qui se joint au message en preparation (cartes des pieces, entree
  /// « Joindre un fichier »), pose juste au-dessus du champ ; `null` : rien.
  final Widget? emplacementPieceJointe;

  /// L'emplacement du message vocal (COM-VOC), pose sous le champ ; `null`
  /// par defaut : rien n'est rendu, aucune place n'est reservee.
  final Widget? emplacementVocal;

  /// Le controleur du champ, quand l'ecran doit le tenir (restauration du
  /// Focus) ; `null` : le fil a le sien. Un controleur donne n'est jamais
  /// libere par le fil.
  final TextEditingController? controleur;

  /// Le controleur de la liste des messages, quand l'ecran doit la suivre
  /// (garder la fin du fil visible a l'ouverture du clavier) ; `null` : le
  /// fil a le sien. Un controleur donne n'est jamais libere par le fil.
  final ScrollController? defilement;

  /// L'endroit du brouillon du champ (`PortBrouillons`, COM-BR-12), ou
  /// `null` : aucun brouillon. Le texte est garde a chaque frappe et remis a
  /// la reouverture, avec la phrase « Brouillon restaure » ; un envoi vide
  /// le champ, donc efface le brouillon (R-22).
  final CleBrouillon? cleBrouillon;

  /// La phrase qui dit pourquoi on ne peut pas ecrire ici (« Vous pouvez lire
  /// ce canal. L'ecriture n'y est pas ouverte pour vous. »), ou `null` : le
  /// fil s'ecrit. Donnee, le fil se lit seulement : ni champ, ni bouton
  /// grise, ni brouillon ; l'en-tete defile avec les messages, la phrase se
  /// pose sous eux (R-07).
  final String? lectureSeule;

  /// Le retour de la page (vers la liste des conversations), ou `null`.
  /// Quand la tete de la page defile avec les messages (texte agrandi, vue
  /// basse), son disque retour quitte l'ecran : le fil pose alors ce retour
  /// au debut de la ligne compacte, qui reste fixe (constat 8). Inutile
  /// quand l'espace de travail confie deja son retour a l'en-tete.
  final VoidCallback? retourCompacte;

  /// Vrai en Focus du Studio (decision du directeur, « Focus a 320 ») : a
  /// texte agrandi sur un telephone etroit (ecran de moins de
  /// [largeurReduite]), la saisie se reduit a une ligne (le champ, et le
  /// micro) tant que le champ est vide et n'a pas le focus ; elle reprend sa
  /// forme entiere des qu'on y ecrit ou qu'il prend le focus. Une bulle au
  /// moins reste a l'ecran.
  final bool saisieReduite;

  /// MESSAGERIE-PLEIN-ECRAN (15/11/2026) : le fil est une page a lui, comme
  /// dans toute messagerie. Aucun en-tete ni tete de page : la barre de la
  /// conversation est posee au-dessus par l'appelant. Les messages sont la
  /// seule zone qui defile, en ordre inverse (le dernier message est le bas
  /// de la liste, il y reste quand le clavier s'ouvre) ; la saisie est
  /// fixe en bas, sans phrase d'aide, et grandit jusqu'a cinq lignes puis
  /// defile en elle-meme. Source : `docs/current/UX_REVIEW_MESSAGERIE-PLEIN-ECRAN.md`.
  final bool pleinEcran;

  /// BULLES-MESSAGERIE : vrai (par defaut), le nom de l'auteur se lit sur les
  /// messages recus (conversation de groupe, canal) ; faux dans une
  /// conversation a deux, ou le nom de l'autre est deja dans la barre. Les
  /// messages de soi ne portent jamais de nom ; le lecteur d'ecran annonce
  /// toujours l'auteur.
  final bool afficherAuteur;

  /// BULLES-MESSAGERIE : vrai (par defaut), un fil qui porte son en-tete prend
  /// la tete de la page qui la lui confie (`PageShell(teteAvecLaListe:)`) ;
  /// faux, il la laisse a la page : sur ordinateur et tablette, la liste des
  /// conversations est a cote du fil, la tete reste au-dessus des deux
  /// colonnes, une seule fois.
  final bool prendTeteDePage;

  /// L'heure courante, pour dire « Aujourd'hui » et « Hier » sur les
  /// separateurs de jour.
  final DateTime Function() horloge;

  /// La largeur sous laquelle [saisieReduite] s'applique (320 oui, 360 et
  /// 390 non).
  static const double largeurReduite = 360;

  /// BULLES-MESSAGERIE : la part de la colonne qu'une bulle prend au plus.
  static const double partBulle = 0.75;

  /// BULLES-MESSAGERIE : la largeur qu'une bulle ne depasse jamais sur
  /// ordinateur.
  static const double largeurBulleMax = 560;

  /// BULLES-MESSAGERIE : la marge toujours libre du cote oppose a la bulle.
  static const double margeOpposee = AppSpacing.respiration;

  /// BULLES-MESSAGERIE : l'ecart au plus entre deux messages d'un meme auteur
  /// pour qu'ils forment un groupe.
  static const Duration ecartGroupe = Duration(minutes: 5);

  /// La part de la hauteur de l'ecran que la saisie occupe au plus (R-02).
  static const double partSaisieMax = 0.4;

  /// La part de la hauteur de l'ecran que la saisie occupe au plus quand le
  /// panneau vocal l'occupe (N-9) : le panneau, borne a la moitie de
  /// l'ecran, s'y lit en entier.
  static const double partSaisieVocalMax = 0.6;

  /// La part de la hauteur du fil que la saisie occupe au plus quand le
  /// panneau vocal l'occupe (N-9).
  static const double partSaisieFilVocalMax = 0.75;

  /// La part de la hauteur du fil que la saisie occupe au plus, quand le
  /// clavier logiciel la reduit : les messages gardent le reste.
  static const double partSaisieFilMax = 0.6;

  /// L'etat vide, pour les tests.
  static const Key cleAucunMessage = ValueKey<String>('fil-discussion-vide');

  /// La phrase « Brouillon restaure », pour les tests.
  static const Key cleBrouillonRestaure = ValueKey<String>(
    'fil-discussion-brouillon-restaure',
  );

  /// La zone de saisie (bornee, defilante), pour les tests.
  static const Key cleSaisie = ValueKey<String>('fil-discussion-saisie');

  /// La ligne compacte du contexte, fixe au-dessus de la liste, pour les
  /// tests (N-1).
  static const Key cleEnteteCompacte = ValueKey<String>(
    'fil-discussion-entete-compacte',
  );

  /// La marge sous la saisie bornee quand le panneau vocal l'occupe, pour
  /// les tests (N-9).
  static const Key cleMargeVocal = ValueKey<String>(
    'fil-discussion-marge-vocal',
  );

  /// La liste des messages, pour les tests.
  static const Key cleMessages = ValueKey<String>('fil-discussion-messages');

  /// La phrase de la lecture seule, pour les tests.
  static const Key cleLectureSeule = ValueKey<String>(
    'fil-discussion-lecture-seule',
  );

  /// Le champ de saisie, pour les tests.
  static const Key champKey = ValueKey<String>('fil-discussion-champ');

  /// Le bouton d'envoi, pour les tests.
  static const Key envoyerKey = ValueKey<String>('fil-discussion-envoyer');

  /// La hauteur sous laquelle la liste des messages n'est plus lisible : une
  /// bulle entiere, a l'echelle de texte de [context] (SUPERPOS-1, reunie
  /// par JONCTION-LIGNES-1). La bulle comptee est celle d'un message de deux
  /// lignes : son auteur, son texte, son pied, ses marges, et la respiration
  /// sous la liste. Un minimum fixe (96) ne laissait voir a 320 en texte
  /// double qu'une tranche de bulle (une bulle y mesure environ 200).
  static double minimumListe(BuildContext context) {
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextTheme textes = Theme.of(context).textTheme;
    double ligne(TextStyle? style) {
      final double taille = style?.fontSize ?? 14;
      return echelle.scale(taille) * (style?.height ?? 1.2);
    }

    return AppSpacing.lg * 2 +
        ligne(textes.labelMedium) +
        AppSpacing.xs +
        ligne(textes.bodyLarge) * 2 +
        AppSpacing.sm +
        ligne(textes.bodySmall) +
        AppSpacing.lg;
  }

  /// Le micro a cote d'« Envoyer » (decision R-28), pour les tests.
  /// IMAGES-CORRECTIF : l'icone d'alerte et la ligne « Non confirme » d'une
  /// bulle en echec, qui ouvrent toutes deux le menu (tests).
  static const Key cleIconeEchec = ValueKey<String>(
    'fil-discussion-echec-icone',
  );
  static const Key cleLigneEchec = ValueKey<String>(
    'fil-discussion-echec-ligne',
  );

  /// La cle de l'icone « Joindre une image », pour les tests.
  static const Key cleImage = ValueKey<String>('fil-discussion-image');

  static const Key cleMicro = ValueKey<String>('fil-discussion-micro');

  /// Le retour de la ligne compacte (constat 8), pour les tests.
  static const Key cleRetourCompacte = ValueKey<String>(
    'fil-discussion-retour-compacte',
  );

  @override
  State<FilDiscussion> createState() => _FilDiscussionState();
}

class _FilDiscussionState extends State<FilDiscussion> {
  /// Le compteur des identifiants locaux, commun a tous les fils ouverts
  /// pendant la session : deux bulles, meme de deux fils, n'ont jamais le
  /// meme identifiant (une cle d'idempotence ne passe jamais de l'une a
  /// l'autre).
  static int _compteurSession = 0;

  static const Key _cleEntete = ValueKey<String>('fil-discussion-entete');

  /// La saisie garde son etat (texte, focus, panneau vocal) quand elle passe
  /// de sous la liste a dans la liste (texte agrandi, rotation).
  final GlobalKey _cleZoneSaisie = GlobalKey(
    debugLabel: 'FilDiscussion.saisie',
  );

  TextEditingController? _proprio;
  ScrollController? _defilementPropre;
  ScrollController get _defilement =>
      widget.defilement ?? (_defilementPropre ??= ScrollController());

  /// La tete de page prise par le fil (COM-RC tour 2, R-02) : le relais de
  /// la page ou il s'est declare, et la tete qu'elle lui confie.
  RelaisTetePage? _relaisTete;
  Widget? _teteDePage;
  final List<_MessageLocal> _locaux = <_MessageLocal>[];

  /// IMAGES-MESSAGERIE : les miniatures du fil, lues UNE fois (renouvelees a
  /// l'expiration, ou quand un message a une image que la lecture ne connait
  /// pas encore), et les images deja demandees.
  Map<String, AdresseImage> _miniatures = const <String, AdresseImage>{};
  final Set<String> _idsDemandes = <String>{};
  bool _miniaturesEnCours = false;

  /// Une lecture des miniatures a abouti : une image sans adresse n'en aura
  /// pas, l'image complete prend le relais (IMAGES-CORRECTIF).
  bool _miniaturesLues = false;
  DateTime _derniereLectureMiniatures = DateTime.fromMillisecondsSinceEpoch(0);

  /// IMAGES-MESSAGERIE : les coeurs affiches tout de suite, avant la reponse
  /// du serveur, et les appels en vol.
  final Map<String, EtatCoeur> _coeursLocaux = <String, EtatCoeur>{};
  final Set<String> _coeursEnVol = <String>{};
  bool _coeurEchec = false;
  // DOUBLON-ENVOI (directeur, 16/11/2026) : lu a l'ouverture, dans
  // [initState]. Un `late final` paresseux n'etait lu qu'au premier besoin :
  // dans une conversation vide, ce besoin venait avec le retour du serveur du
  // premier message envoye, qui passait alors pour « present a l'ouverture »
  // et gardait sa bulle locale a cote (deux bulles).
  late final Set<String> _presentsALOuverture;

  /// Le panneau vocal occupe-t-il la saisie (R-04) ?
  bool _vocalOuvert = false;

  /// La saisie defile-t-elle avec les messages, au dernier rendu (N-4) ?
  bool _saisieDansListe = false;

  /// La persistance du brouillon (R-22, commune avec le composer de
  /// reponse de la Communaute), lue une fois si le fil en garde un.
  PersistanceBrouillon? _persistance;

  /// Vrai tant que le brouillon remis n'a pas ete touche.
  bool _restaure = false;

  /// Le texte que le brouillon garde, tel que le fil l'a ecrit ou remis
  /// (constat 1) : un accuse n'efface que le brouillon de SON texte.
  String _garde = '';

  /// Arrete l'ecoute des issues d'envoi (accuse, echec) de la persistance.
  VoidCallback? _arreterIssues;

  /// Le composer vocal dit-il son micro disponible (decision R-28) ?
  bool _microDisponible = false;

  /// Les touchers du micro, ecoutes par le composer vocal (R-28).
  final ValueNotifier<int> _demandesVocal = ValueNotifier<int>(0);

  /// Le focus clavier du champ : la saisie reduite reprend sa forme entiere
  /// quand il le prend (decision « Focus a 320 »).
  final FocusNode _noeudChamp = FocusNode(debugLabel: 'FilDiscussion.champ');

  /// Le champ garde son etat (texte, focus) quand sa rangee change de forme
  /// (reduite, empilee, en ligne).
  final GlobalKey _cleChamp = GlobalKey(debugLabel: 'FilDiscussion.champ');

  /// La saisie bornee sous la liste, qui va a son bas quand le panneau
  /// vocal s'ouvre ou grandit (N-9).
  final ScrollController _defilementSaisie = ScrollController();

  TextEditingController get _champ => widget.controleur ?? _proprio!;

  @override
  void initState() {
    super.initState();
    _presentsALOuverture = <String>{
      for (final MessageFil m in widget.messages) m.id,
    };
    if (widget.controleur == null) _proprio = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lireMiniatures());
    _champ.addListener(_auChangement);
    _noeudChamp.addListener(_auFocusChamp);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allerEnBas(false);
      _montrerSaisie();
    });
  }

  /// SUPERPOS-1 (repris par JONCTION-LIGNES-1) : quand la page entiere
  /// defile (texte double, vue basse) et que le fil n'a pas pris sa tete (le
  /// Controleur), l'arrivee dans le fil montre la saisie et le dernier
  /// message, l'en-tete de la page passant au-dessus, comme dans toute
  /// messagerie. Sans effet quand tout tient deja dans l'ecran, ni pour un
  /// fil qui porte son en-tete (sa saisie est dans la liste, deja au bas).
  void _montrerSaisie() {
    if (widget.pleinEcran) return;
    if (widget.entete != null || widget.enteteCompacte != null) return;
    final BuildContext? saisie = _cleZoneSaisie.currentContext;
    if (!mounted || saisie == null) return;
    Scrollable.ensureVisible(
      saisie,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  void _auFocusChamp() {
    if (!mounted) return;
    // Au focus (clavier qui s'ouvre, « Envoyer » qui revient en saisie
    // reduite), si la fin du fil etait a l'ecran, elle y reste.
    final bool enBas =
        _defilement.hasClients &&
        (widget.pleinEcran
            ? _defilement.position.pixels <= 1
            : _defilement.position.pixels >=
                  _defilement.position.maxScrollExtent - 1);
    setState(() {});
    if (enBas && _noeudChamp.hasFocus) {
      // Une seule fois, a l'image suivante (la disposition du focus) :
      // aucune reprise qui viendrait defaire une position restauree ensuite
      // (sortie du Focus, R-COM-10).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _allerEnBas(false, 0),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // R-02 (COM-RC tour 2) : dans une page non defilante, le fil prend la
    // tete de la page. Quand la page la lui confie (texte agrandi sur
    // telephone, vue basse), elle defile avec les messages, avant l'en-tete
    // du fil ; le premier ecran montre la fin du fil et son champ.
    // JONCTION-LIGNES-1 : seul un fil qui porte son propre en-tete
    // (Messages, Studio : [FilDiscussion.entete] ou
    // [FilDiscussion.enteteCompacte]) prend la tete de la page. Le fil du
    // Controleur n'en a pas : la page garde sa tete, compacte et fixe
    // (SUPERPOS-1), au-dessus du fil et de sa saisie.
    final bool preneur =
        !widget.pleinEcran &&
        widget.prendTeteDePage &&
        (widget.entete != null || widget.enteteCompacte != null);
    final TetePageConfiee? page = preneur ? TetePageConfiee.de(context) : null;
    final RelaisTetePage? relais = page?.relais;
    if (!identical(relais, _relaisTete)) {
      _relaisTete?.rendre(this);
      _relaisTete = relais?..prendre(this);
    }
    // Un seul preneur recoit la tete (COM-RC tour 3) : elle porte une cle
    // globale et ne se monte jamais a deux endroits. Un second fil sous la
    // meme page attend que le premier la rende.
    final Widget? tete = page != null && identical(page.titulaire, this)
        ? page.tete
        : null;
    if ((tete == null) != (_teteDePage == null)) {
      // La liste gagne ou perd la tete en haut : la fin du fil reste a
      // l'ecran.
      WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(false));
    }
    _teteDePage = tete;
    final CleBrouillon? cle = widget.lectureSeule == null
        ? widget.cleBrouillon
        : null;
    if (cle != null && _persistance == null) {
      // Aucune memoire de brouillons lisible (pas de session) : le champ
      // fonctionne, rien n'est garde ni remis.
      final PersistanceBrouillon persistance = PersistanceBrouillon.depuis(
        context,
      )..caler(_champ.text);
      _persistance = persistance;
      _arreterIssues = persistance.ecouterIssues(_aLIssueDUnEnvoi);
      if (persistance.port != null) unawaited(_restaurer(persistance, cle));
    }
  }

  @override
  void didUpdateWidget(FilDiscussion ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.controleur, widget.controleur)) {
      (ancien.controleur ?? _proprio)?.removeListener(_auChangement);
      if (widget.controleur == null) _proprio ??= TextEditingController();
      _champ.addListener(_auChangement);
      _persistance?.caler(_champ.text);
    }
    if (widget.emplacementVocal == null) {
      _vocalOuvert = false;
      _microDisponible = false;
    }
    if (!identical(ancien.messages, widget.messages)) {
      // Un coeur dont l'appel est fini est desormais dans la liste lue.
      _coeursLocaux.removeWhere(
        (String id, EtatCoeur _) => !_coeursEnVol.contains(id),
      );
      _lireMiniatures();
    }
    // MESSAGERIE-TEMPS-REEL (14/11/2026) : un message arrive en direct
    // descend la lecture jusqu'a lui, si elle etait deja en bas (un lecteur
    // remonte dans l'historique n'est pas deplace).
    if (widget.messages.length > ancien.messages.length &&
        _defilement.hasClients) {
      final ScrollPosition p = _defilement.position;
      final double distanceDuBas = widget.pleinEcran
          ? p.pixels
          : p.maxScrollExtent - p.pixels;
      if (p.hasContentDimensions && distanceDuBas <= AppSpacing.xxxl * 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(true));
      }
    }
    if (ancien.demandeSaisieVisible != widget.demandeSaisieVisible) {
      // N-4 : la saisie dans la liste revient a l'ecran (le Focus montre
      // le champ a l'entree). Bornee sous la liste, elle y est deja.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_saisieDansListe) _allerEnBas(false);
      });
    }
  }

  @override
  void dispose() {
    // Un envoi encore en vol se termine (brouillon compris) ; plus personne
    // n'ecoute sa bulle.
    for (final _MessageLocal m in _locaux) {
      m.action.dispose();
      m.progression.dispose();
    }
    // Retirer une ecoute d'un controleur exterieur deja libere est permis.
    _champ.removeListener(_auChangement);
    _arreterIssues?.call();
    _proprio?.dispose();
    _relaisTete?.rendre(this);
    _defilementPropre?.dispose();
    _defilementSaisie.dispose();
    _noeudChamp
      ..removeListener(_auFocusChamp)
      ..dispose();
    _demandesVocal.dispose();
    super.dispose();
  }

  /// Remet le brouillon de [cle] dans un champ encore vide.
  Future<void> _restaurer(
    PersistanceBrouillon persistance,
    CleBrouillon cle,
  ) async {
    final bool remis = await persistance.restaurer(
      cle,
      _champ,
      encoreMonte: () => mounted,
    );
    if (!remis) return;
    _garde = _champ.text;
    if (mounted) setState(() => _restaure = true);
  }

  /// Un envoi de [cle] s'est termine, peut-etre depuis un fil deja ferme.
  /// Accuse : si le champ montre encore ce texte remis, sans modification,
  /// il se vide (le texte est parti, il ne doit pas repartir en double).
  void _aLIssueDUnEnvoi(CleBrouillon cle, String texte, bool accuse) {
    final PersistanceBrouillon? persistance = _persistance;
    if (!accuse || !mounted || persistance == null) return;
    if (cle != widget.cleBrouillon || !_restaure || _champ.text != texte) {
      return;
    }
    persistance.caler('');
    _champ.clear();
    setState(() {
      _restaure = false;
      _garde = '';
    });
  }

  void _auChangement() {
    final CleBrouillon? cle = widget.cleBrouillon;
    // Un texte vide (apres un envoi, ou tout efface) efface le brouillon.
    if (cle != null && (_persistance?.noter(cle, _champ.text) ?? false)) {
      _restaure = false;
      _garde = _champ.text;
    }
    setState(() {});
  }

  bool get _vide => _champ.text.trim().isEmpty;

  void _allerEnBas(bool anime, [int reprises = 3]) {
    if (!mounted || !_defilement.hasClients) return;
    // Liste inversee (plein ecran) : le bas est le point zero, sans estimation
    // a rattraper.
    final bool inverse = widget.pleinEcran;
    final double fin = inverse ? 0 : _defilement.position.maxScrollExtent;
    final Duration duree = Mouvement.duree(context, Mouvement.moyen);
    if (anime && duree > Duration.zero) {
      _defilement.animateTo(fin, duration: duree, curve: Mouvement.entree);
    } else {
      _defilement.jumpTo(fin);
      // La liste est paresseuse : sa fin est estimee tant que les derniers
      // messages (cartes de pieces, lecteurs) ne sont pas mesures. On
      // rejoint la vraie fin une fois ceux-ci poses.
      if (reprises > 0 && !inverse) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_defilement.hasClients) return;
          final ScrollPosition p = _defilement.position;
          if (p.pixels < p.maxScrollExtent) _allerEnBas(false, reprises - 1);
        });
      }
    }
  }

  /// IMAGES-MESSAGERIE : lit les miniatures du fil (UNE demande), seulement si
  /// un message a une image dont l'adresse manque ou est perimee. Une relecture
  /// n'a pas lieu deux fois en moins de trente secondes.
  void _lireMiniatures() {
    final SourceImagesFil? source = widget.images;
    if (source == null || !mounted || _miniaturesEnCours) return;
    final DateTime maintenant = DateTime.now();
    final Set<String> visibles = <String>{
      for (final MessageFil m in widget.messages)
        if (m.image case final ImageMessage i
            when i.etat == EtatImageMessage.confirmee)
          i.id,
    };
    final bool neuves = visibles.any((String id) => !_idsDemandes.contains(id));
    final bool perimees = _miniatures.values.any(
      (AdresseImage a) => !a.expireLe.isAfter(maintenant),
    );
    if (!neuves && !perimees) return;
    if (!neuves &&
        maintenant.difference(_derniereLectureMiniatures) <
            const Duration(seconds: 30)) {
      return;
    }
    _miniaturesEnCours = true;
    _derniereLectureMiniatures = maintenant;
    _idsDemandes.addAll(visibles);
    // IMAGES-CORRECTIF : la liste gardee par le port ne connait pas une image
    // arrivee depuis sa lecture (cache d'une heure). Si une image visible n'y
    // figure pas, on relit une fois le serveur sans le cache.
    Future<Map<String, AdresseImage>> lecture() async {
      final Map<String, AdresseImage> lues = await source.miniatures();
      if (visibles.every(lues.containsKey)) return lues;
      return source.miniatures(frais: true);
    }

    lecture().then<void>(
      (Map<String, AdresseImage> lues) {
        if (!mounted) return;
        setState(() {
          _miniatures = lues;
          _miniaturesLues = true;
          _miniaturesEnCours = false;
        });
      },
      onError: (Object _) {
        // Rien n'est affirme : la couleur moyenne reste, la prochaine
        // ouverture redemande.
        _miniaturesEnCours = false;
        _idsDemandes.removeAll(visibles);
      },
    );
  }

  /// Le texte d'un message qui ne porte qu'une image n'est pas ecrit.
  static String _texteAffiche(MessageFil m) =>
      m.image != null && estTexteImageSeule(m.texte) ? '' : m.texte;

  /// IMAGES-MESSAGERIE : pose ou retire mon coeur. L'affichage est immediat
  /// (action courante, DECISION-FLUIDITE) ; il revient en arriere si l'appel
  /// echoue.
  Future<void> _basculerCoeur(MessageFil m) async {
    final Future<EtatCoeur> Function(String, bool)? aimer = widget.onAimer;
    if (aimer == null || _coeursEnVol.contains(m.id)) return;
    final EtatCoeur? avant = _coeursLocaux[m.id];
    final EtatCoeur actuel =
        avant ?? EtatCoeur(coeurs: m.coeurs, aimeParMoi: m.aimeParMoi);
    final bool veut = !actuel.aimeParMoi;
    setState(() {
      _coeurEchec = false;
      _coeursLocaux[m.id] = EtatCoeur(
        coeurs: math.max(0, actuel.coeurs + (veut ? 1 : -1)),
        aimeParMoi: veut,
      );
    });
    _coeursEnVol.add(m.id);
    try {
      final EtatCoeur rendu = await aimer(m.id, veut);
      if (mounted) setState(() => _coeursLocaux[m.id] = rendu);
    } on Object {
      if (mounted) {
        setState(() {
          if (avant == null) {
            _coeursLocaux.remove(m.id);
          } else {
            _coeursLocaux[m.id] = avant;
          }
          _coeurEchec = true;
        });
      }
    } finally {
      _coeursEnVol.remove(m.id);
    }
  }

  void _ouvrirImage(MessageFil m) {
    final SourceImagesFil? source = widget.images;
    final ImageMessage? image = m.image;
    if (source == null ||
        image == null ||
        image.etat != EtatImageMessage.confirmee) {
      return;
    }
    unawaited(
      ouvrirApercuImage(
        context,
        image: image,
        adresseComplete: () => source.image(image.id),
        miniature: _miniatures[image.id],
        texte: _texteAffiche(m),
      ),
    );
  }

  /// IMAGES-MESSAGERIE : choisit une photo ; sa bulle apparait tout de suite
  /// (cercle de preparation puis d'envoi), la photo est reduite sur l'appareil
  /// avant l'envoi. Le texte du champ part dans le meme message.
  Future<void> _joindreImage([SourceImage source = SourceImage.galerie]) async {
    if (_vocalOuvert || widget.onEnvoyerImage == null) return;
    final Uint8List? octets = await widget.choisirImage(source);
    if (octets == null || !mounted) return;
    final String id = 'local-${_compteurSession++}';
    final String saisi = _champ.text.trim();
    final String texte = saisi.isEmpty ? texteImageSeule : saisi;
    late final _MessageLocal m;
    m = _MessageLocal(
      id,
      texte,
      _champ.text,
      ActionAnticipee(
        nature: NatureAction.instantanee,
        cle: id,
        envoi: (String cle) async {
          m.refus = null;
          m.precision = null;
          try {
            final ImagePrete prete = m.prete ??= await preparerImage(octets);
            if (mounted) setState(() {});
            await widget.onEnvoyerImage!(
              cle,
              texte,
              prete,
              ProgressionImage(
                (double f) => m.progression.value = f,
                surMessage: (String id) {
                  m.idMessage = id;
                  if (mounted) setState(() {});
                },
                surDepot: (String id) => m.idImage = id,
              ),
            );
          } on EchecImage catch (e) {
            final String phrase = phraseRefusImage(e.refus);
            if (e.refus.reessayable) {
              m.precision = phrase;
            } else {
              m.refus = phrase;
            }
            rethrow;
          } on EnvoiRefuse catch (e) {
            m.refus = e.phrase;
            rethrow;
          }
        },
      ),
      cree: widget.horloge(),
      source: octets,
    );
    m.action.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _locaux.add(m));
    _persistance?.caler('');
    _champ.clear();
    unawaited(_tenter(m));
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(true));
  }

  void _envoyer() {
    if (_vide || _vocalOuvert) return;
    final String id = 'local-${_compteurSession++}';
    final String texte = _champ.text.trim();
    // `late` : l'envoi note le refus sur le message, qu'il n'appelle
    // qu'apres sa creation (au premier `tenter`).
    late final _MessageLocal m;
    m = _MessageLocal(
      id,
      texte,
      _champ.text,
      ActionAnticipee(
        // Un message est une action instantanee (DECISION-FLUIDITE §1).
        nature: NatureAction.instantanee,
        cle: id,
        envoi: (String cle) async {
          final Future<void> Function(String, String)? identifie =
              widget.onEnvoyerMessage;
          // K-59 (PR 304) : un refus dont « Reessayer » ne change pas la
          // cause est dit par sa phrase, sans « Reessayer » ; tout autre
          // echec reste ordinaire.
          m.refus = null;
          try {
            await (identifie != null
                ? identifie(cle, texte)
                : widget.onEnvoyer!(texte));
          } on EnvoiRefuse catch (e) {
            m.refus = e.phrase;
            rethrow;
          }
        },
      ),
      cree: widget.horloge(),
    );
    m.action.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _locaux.add(m));
    // N-3 : le champ se vide tout de suite, mais le brouillon reste jusqu'a
    // l'accuse (comme la reponse de la Communaute) : quitter le fil avant
    // lui ne perd pas le message. Le champ vide n'est pas note.
    _persistance?.caler('');
    _champ.clear();
    _tenter(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(true));
  }

  /// IMAGES-CORRECTIF : « Supprimer » sur une bulle en echec. Le depot de
  /// l'image est abandonne cote serveur (sans attendre), puis la bulle
  /// disparait ; le texte n'est pas remis dans le champ.
  void _supprimerLocal(_MessageLocal m) {
    final String? imageId = m.idImage;
    final Future<void> Function(String)? annuler = widget.onAnnulerImage;
    if (imageId != null && annuler != null) {
      unawaited(annuler(imageId).catchError((Object _) {}));
    }
    final CleBrouillon? cle = widget.cleBrouillon;
    if (cle != null && m.source == null) {
      unawaited(_persistance?.effacerSi(cle, m.brut) ?? Future<void>.value());
    }
    setState(() => _locaux.remove(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      m.action.dispose();
      m.progression.dispose();
    });
  }

  Future<void> _tenter(_MessageLocal m) async {
    // Lus avant l'attente : l'accuse peut arriver fil ferme (constat 1).
    final CleBrouillon? cle = widget.cleBrouillon;
    final PersistanceBrouillon? persistance = _persistance;
    // Le texte attend son accuse (premier envoi comme nouvel essai) : un fil
    // rouvert d'ici la ne le remet pas dans son champ.
    if (cle != null) persistance?.marquerEnAttente(cle, m.brut);
    // L'outil passe la bulle a « en cours », puis a « envoye » ou a
    // « echec » ; le brouillon se regle avant, meme fil ferme.
    await m.action.tenter(
      siConfirme: () {
        _effacerBrouillonDe(m, cle, persistance);
        if (cle != null) persistance?.terminerEnvoi(cle, m.brut, accuse: true);
      },
      siEchec: () {
        if (cle != null) {
          persistance?.terminerEnvoi(cle, m.brut, accuse: false);
        }
      },
    );
  }

  /// N-3, constat 1 : a l'accuse de [m], le brouillon s'efface s'il garde
  /// encore le texte de [m] (rien n'a ete ecrit depuis) et que le champ ne
  /// le montre pas a nouveau. Un autre message en echec ou en attente ne
  /// bloque rien : chaque accuse efface le brouillon de SON texte, meme
  /// arrive apres la fermeture du fil. Un texte envoye ne revient donc
  /// jamais dans le champ a la reouverture ; un texte en echec, lui, reste
  /// garde tant que rien ne l'a remplace.
  void _effacerBrouillonDe(
    _MessageLocal m,
    CleBrouillon? cle,
    PersistanceBrouillon? persistance,
  ) {
    if (cle == null || persistance == null || _garde != m.brut) return;
    if (mounted && !_vide) return;
    _garde = '';
    // COM-RC tour 6 (8.3-1) : seulement si le brouillon garde encore ce
    // texte ; un fil rouvert ou l'on a tape autre chose le conserve.
    unawaited(persistance.effacerSi(cle, m.brut));
  }

  /// R-28 : le micro demande un enregistrement au composer vocal.
  void _demanderVocal() => _demandesVocal.value++;

  bool _surMicroVocal(MicroVocalFil avis) {
    if (avis.disponible != _microDisponible) {
      setState(() => _microDisponible = avis.disponible);
    }
    return true;
  }

  /// N-9 : le panneau vocal ouvert (ou qui grandit) se lit jusqu'en bas :
  /// la saisie bornee va a son bas ; dans la liste, le fil va a son bas.
  void _montrerBasDuPanneau() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vocalOuvert) return;
      if (_saisieDansListe) {
        _allerEnBas(false);
      } else if (_defilementSaisie.hasClients) {
        _defilementSaisie.jumpTo(_defilementSaisie.position.maxScrollExtent);
      }
    });
  }

  bool _surPanneauVocal(PanneauVocalFil avis) {
    if (avis.ouvert != _vocalOuvert) {
      setState(() => _vocalOuvert = avis.ouvert);
      if (avis.ouvert) _montrerBasDuPanneau();
    }
    return true;
  }

  bool _surTailleVocal(SizeChangedLayoutNotification _) {
    if (_vocalOuvert) _montrerBasDuPanneau();
    return true;
  }

  /// Constat 8 : quand la tete de la page defile avec les messages, son
  /// disque retour quitte l'ecran ; le retour de la page se pose alors au
  /// debut de la ligne compacte, fixe.
  Widget _avecRetourCompacte(Widget ligne) {
    final VoidCallback? retour = widget.retourCompacte;
    if (retour == null || _teteDePage == null) return ligne;
    final String libelle = t.com.socle.composants.espace.retourListe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BoutonIcone(
          key: FilDiscussion.cleRetourCompacte,
          icone: AppIcons.retour,
          libelle: libelle,
          infobulle: libelle,
          onPress: retour,
        ),
        Ecart.hSm,
        Expanded(child: ligne),
      ],
    );
  }

  /// Le fil plein ecran : les messages (seule zone qui defile, liste
  /// inversee) au-dessus, la saisie fixe en bas. Le clavier raccourcit la
  /// zone des messages par le bas (`resizeToAvoidBottomInset` de la page) ; le
  /// dernier message reste collé au champ, la liste etant ancree en bas.
  Widget _pleinEcran(
    BuildContext context, {
    required List<_Ligne> lignes,
    required Widget Function({required bool reduite}) zoneSaisie,
    required String? limite,
    required TextTheme styles,
  }) {
    final Widget saisie = KeyedSubtree(
      key: _cleZoneSaisie,
      child: zoneSaisie(reduite: false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          key: FilDiscussion.cleMessages,
          // BULLES-MESSAGERIE : le fond du fil, un peu plus sombre que les
          // bulles recues, de bord a bord.
          child: ColoredBox(
            color: AppPalette.of(context).fondFil.background,
            child: CustomScrollView(
              controller: _defilement,
              reverse: true,
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  // Construites au fur et a mesure du defilement ; la liste
                  // etant inversee, l'element 0 est le dernier message.
                  sliver: SliverList.builder(
                    itemCount: lignes.length,
                    itemBuilder: (BuildContext _, int i) =>
                        _item(lignes, lignes.length - 1 - i),
                  ),
                ),
              ],
            ),
          ),
        ),
        // La saisie prend sa hauteur naturelle : le champ grandit jusqu'a cinq
        // lignes puis defile en lui-meme (seule exception admise, comme dans
        // toute messagerie) ; les messages gardent tout le reste.
        // FINITIONS-MESSAGERIE : aucun bandeau derriere la saisie, le champ
        // repose sur le fond du fil.
        KeyedSubtree(
          key: FilDiscussion.cleSaisie,
          child: ColoredBox(
            color: AppPalette.of(context).fondFil.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: limite == null
                  ? saisie
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Text(
                        limite,
                        key: FilDiscussion.cleLectureSeule,
                        style: AppPalette.of(context).inkMuted
                            .applyTo(styles.bodyMedium ?? const TextStyle()),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Une ligne du fil, avec son ecart au-dessus : quatre points dans un
  /// groupe de messages rapproches, douze ailleurs. [apresEntete] : une
  /// ligne precede la premiere (l'en-tete qui defile).
  Widget _item(List<_Ligne> lignes, int i, {bool apresEntete = false}) {
    final _Ligne l = lignes[i];
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: i == 0 && !apresEntete ? 0 : l.ecartAvant,
        start: _retrait(),
        end: _retrait(),
      ),
      child: _contenuLigne(l),
    );
  }

  /// Le retrait des bulles au bord du fil : 16 en plein ecran (la page du
  /// telephone), 12 sur tablette et ordinateur ; aucun sous 600 hors plein
  /// ecran, ou la place se compte (nom d'une piece jointe a 320 en texte x2).
  double _retrait() => widget.pleinEcran
      ? AppSpacing.lg
      : MediaQuery.sizeOf(context).width < AppGabarit.seuilTablette
      ? 0
      : AppSpacing.md;

  Widget _contenuLigne(_Ligne l) {
    final TextesFilDiscussion x = widget.textes;
    if (l.vide) {
      // R-24 : un fil sans message le dit, jamais une zone blanche.
      return EmptyState(
        key: FilDiscussion.cleAucunMessage,
        message:
            x.aucunMessageTitre ??
            t.com.socle.composants.composer.aucunMessageTitre,
        invitation:
            x.aucunMessage ?? t.com.socle.composants.composer.aucunMessage,
        registre: RegistreVide.subi,
      );
    }
    if (l.jour != null) return _PastilleJour(libelle: l.jour!);
    final MessageFil? m = l.message;
    if (m != null) {
      final String heure = m.instant == null
          ? m.horodatage
          : heureChezMoi(m.instant!);
      final String? mot = switch (m.remise) {
        null => null,
        RemiseMessage.lu => x.lu ?? t.com.socle.composants.composer.lu,
        RemiseMessage.envoye || RemiseMessage.enCours => x.envoye,
      };
      return _Bulle(
        key: ValueKey<String>('message-${m.id}'),
        auteur: m.auteur,
        afficherNom: l.avecNom,
        texte: _texteAffiche(m),
        image: m.image,
        adresse: m.image == null ? null : _miniatures[m.image!.id],
        repli: widget.images == null || m.image == null
            ? null
            : () => widget.images!.image(m.image!.id),
        adresseIntrouvable:
            _miniaturesLues &&
            m.image != null &&
            m.image!.etat == EtatImageMessage.confirmee &&
            _miniatures[m.image!.id] == null,
        coeurs: _coeursLocaux[m.id]?.coeurs ?? m.coeurs,
        aime: _coeursLocaux[m.id]?.aimeParMoi ?? m.aimeParMoi,
        groupe: widget.afficherAuteur,
        onOuvrirImage:
            m.image != null &&
                m.image!.etat == EtatImageMessage.confirmee &&
                widget.images != null
            ? () => _ouvrirImage(m)
            : null,
        onAimer: widget.onAimer == null ? null : () => _basculerCoeur(m),
        onCopier: _texteAffiche(m).isEmpty
            ? null
            : () => unawaited(
                Clipboard.setData(ClipboardData(text: _texteAffiche(m))),
              ),
        heure: l.dernier ? heure : null,
        mot: l.dernier ? mot : null,
        remise: l.dernier ? m.remise : null,
        deSoi: m.deSoi,
        coinPetit: l.dernier,
        complement: m.complement,
        // Son propre message, revenu du serveur, a deja ete annonce par sa
        // bulle locale : il ne l'est pas une seconde fois.
        annonce: _presentsALOuverture.contains(m.id) || m.deSoi
            ? null
            : x.annonce(m.auteur, m.annonceTexte ?? m.texte),
      );
    }
    final _MessageLocal local = l.local!;
    final bool echec = local.etat == EtatEnvoiMessage.echec;
    final String mots = t.com.messages.images.nonConfirmeToucher;
    // Une cause que « Reessayer » ne change pas se dit par sa phrase et ne
    // propose que « Supprimer » (K-56, K-59) ; sinon la ligne courte invite a
    // toucher, et la cause connue (stockage, connexion) se lit au-dessus.
    final bool reessayable = echec && local.refus == null;
    return _Bulle(
      key: ValueKey<String>('message-${local.id}'),
      auteur: x.auteurSoi,
      afficherNom: false,
      texte: local.source != null && estTexteImageSeule(local.texte)
          ? ''
          : local.texte,
      // IMAGES-MESSAGERIE : la bulle porte l'image locale des que sa place est
      // connue ; avant, un cercle de preparation sur un cadre 4 / 3.
      image: local.source == null
          ? null
          : ImageMessage(
              id: local.id,
              largeur: local.prete?.largeur ?? 4,
              hauteur: local.prete?.hauteur ?? 3,
              couleurMoyenne: local.prete?.couleurMoyenne,
            ),
      adresse: local.prete == null
          ? null
          : AdresseImage(
              url: local.id,
              expireLe: DateTime.fromMillisecondsSinceEpoch(0),
              octets: local.prete!.miniature,
            ),
      progression:
          local.source == null || local.etat != EtatEnvoiMessage.enCours
          ? null
          : local.progression,
      enPreparation:
          local.source != null &&
          local.prete == null &&
          local.etat == EtatEnvoiMessage.enCours,
      // En cours ou envoye : le mot et l'horloge ou la coche, comme avant ; en
      // echec, la ligne d'echec prend leur place.
      mot: switch (local.etat) {
        EtatEnvoiMessage.enCours => x.enCours,
        EtatEnvoiMessage.envoye => x.envoye,
        EtatEnvoiMessage.echec => null,
      },
      remise: switch (local.etat) {
        EtatEnvoiMessage.enCours => RemiseMessage.enCours,
        EtatEnvoiMessage.envoye => RemiseMessage.envoye,
        EtatEnvoiMessage.echec => null,
      },
      deSoi: true,
      coinPetit: true,
      // L'etat change sous les yeux : il est annonce a chaque etape.
      etatVivant: true,
      attendImage: !echec,
      echec: echec,
      ligneEchec: !echec ? null : (reessayable ? mots : local.refus),
      causeEchec: reessayable ? local.precision : null,
      actionsEchec: !echec
          ? null
          : <EntreeAction>[
              if (reessayable)
                EntreeAction(
                  libelle: x.reessayer,
                  onChoix: () => unawaited(_tenter(local)),
                ),
              EntreeAction(
                libelle: t.com.messages.images.supprimerEchec,
                destructif: true,
                onChoix: () => _supprimerLocal(local),
              ),
            ],
    );
  }

  /// Les lignes du fil (messages, separateurs de jour, groupes), calculees UNE
  /// fois quand la liste des messages ou l'etat d'un envoi change : un nouvel
  /// appel avec les memes messages (frappe dans le champ) rend la liste
  /// gardee. Jamais calculees dans la construction d'une bulle.
  List<_Ligne> _lignesDuFil(List<_MessageLocal> locaux, Set<String> masques) {
    final int empreinteLocaux = Object.hashAll(<Object?>[
      for (final _MessageLocal m in locaux) ...<Object?>[
        m.id,
        m.etat,
        m.refus,
        m.precision,
        m.prete != null,
      ],
      for (final String id in masques) id,
    ]);
    final List<_Ligne>? gardees = _lignesGardees;
    if (gardees != null &&
        identical(_messagesGardes, widget.messages) &&
        _empreinteGardee == empreinteLocaux &&
        _auteurGarde == widget.afficherAuteur &&
        _jourGarde == _aujourdhui()) {
      return gardees;
    }
    // IMAGES-CORRECTIF : UNE seule liste, triee par date. Une bulle locale (en
    // cours ou en echec) garde sa place a l'heure de son envoi ; les messages
    // arrives ensuite passent en dessous. La copie serveur d'un message dont la
    // bulle locale est encore la est ecartee (jamais deux bulles).
    final List<Object> entrees = <Object>[
      for (final MessageFil m in widget.messages)
        if (!masques.contains(m.id)) m,
    ];
    for (final _MessageLocal local in locaux) {
      int place = entrees.length;
      while (place > 0) {
        final Object avant = entrees[place - 1];
        final DateTime? instant = avant is MessageFil
            ? avant.instant
            : (avant as _MessageLocal).cree;
        if (instant == null || !instant.isAfter(local.cree)) break;
        place -= 1;
      }
      entrees.insert(place, local);
    }
    final DateTime aujourdhui = _aujourdhui();
    final List<_Ligne> lignes = <_Ligne>[];
    DateTime? jourPrecedent;
    for (int i = 0; i < entrees.length; i++) {
      final Object e = entrees[i];
      final DateTime? instant = e is MessageFil
          ? e.instant
          : (e as _MessageLocal).cree;
      DateTime? jour;
      if (instant != null) {
        final DateTime ici = chezMoi(instant);
        jour = DateTime(ici.year, ici.month, ici.day);
      }
      final bool nouveauJour = jour != null && jour != jourPrecedent;
      if (nouveauJour) {
        lignes.add(_Ligne.pastilleJour(_libelleJour(jour, aujourdhui)));
      }
      jourPrecedent = jour ?? jourPrecedent;
      if (e is _MessageLocal) {
        lignes.add(_Ligne.local(e, ecartAvant: AppSpacing.md));
        continue;
      }
      final MessageFil m = e as MessageFil;
      final Object? avant = i > 0 ? entrees[i - 1] : null;
      final Object? apres = i + 1 < entrees.length ? entrees[i + 1] : null;
      final bool suitLeGroupe =
          !nouveauJour && avant is MessageFil && _rapproches(avant, m);
      final bool precedeLeGroupe = apres is MessageFil && _rapproches(m, apres);
      lignes.add(
        _Ligne.message(
          m,
          ecartAvant: suitLeGroupe ? AppSpacing.xs : AppSpacing.md,
          dernier: !precedeLeGroupe,
          avecNom: widget.afficherAuteur && !m.deSoi,
        ),
      );
    }
    if (lignes.isEmpty) lignes.add(const _Ligne.videLigne());
    _lignesGardees = lignes;
    _messagesGardes = widget.messages;
    _empreinteGardee = empreinteLocaux;
    _auteurGarde = widget.afficherAuteur;
    _jourGarde = aujourdhui;
    return lignes;
  }

  List<_Ligne>? _lignesGardees;
  List<MessageFil>? _messagesGardes;
  int? _empreinteGardee;
  bool? _auteurGarde;
  DateTime? _jourGarde;

  DateTime _aujourdhui() {
    final DateTime ici = chezMoi(widget.horloge());
    return DateTime(ici.year, ici.month, ici.day);
  }

  DateTime? _jourDe(MessageFil m) {
    final DateTime? instant = m.instant;
    if (instant == null) return null;
    final DateTime ici = chezMoi(instant);
    return DateTime(ici.year, ici.month, ici.day);
  }

  /// Deux messages consecutifs du meme auteur, a cinq minutes au plus l'un de
  /// l'autre et du meme jour, forment un groupe.
  bool _rapproches(MessageFil a, MessageFil b) {
    final DateTime? ia = a.instant;
    final DateTime? ib = b.instant;
    if (ia == null || ib == null) return false;
    return a.deSoi == b.deSoi &&
        a.auteur == b.auteur &&
        ib.difference(ia).abs() <= FilDiscussion.ecartGroupe &&
        _jourDe(a) == _jourDe(b);
  }

  String _libelleJour(DateTime jour, DateTime aujourdhui) {
    final int ecart = aujourdhui.difference(jour).inDays;
    if (ecart == 0) return t.com.socle.lexique.aujourdhui;
    if (ecart == 1) return t.com.socle.lexique.hier;
    return dateDeLAppareil(jour);
  }

  @override
  Widget build(BuildContext context) {
    final TextesFilDiscussion x = widget.textes;
    // MESSAGERIE-TEMPS-REEL (14/11/2026) : le fil ouvert se relit en direct ;
    // un message envoye d'ici revient alors du serveur. Sa bulle locale
    // confirmee s'efface devant lui (meme texte, un pour un) : jamais deux
    // bulles pour un message. Une bulle non confirmee (echec) reste.
    // DOUBLON-ENVOI (directeur, 16/11/2026, capture : le message s'affichait
    // deux fois) : le serveur renvoie souvent le message AVANT que l'envoi
    // ait repondu ; la bulle encore « en cours » s'efface donc aussi devant
    // lui, puisque son retour prouve qu'il est arrive.
    final List<String> revenusDuServeur = <String>[
      for (final MessageFil m in widget.messages)
        if (m.deSoi && m.image == null && !_presentsALOuverture.contains(m.id))
          m.texte.trim(),
    ];
    // IMAGES-CORRECTIF : une bulle d'image garde l'identifiant du message
    // serveur ; elle s'efface devant lui seulement une fois l'image confirmee
    // et relue. Jusque-la (en cours, en echec) la copie serveur est ecartee :
    // une seule bulle a tout moment.
    final Map<String, MessageFil> serveur = <String, MessageFil>{
      for (final MessageFil m in widget.messages) m.id: m,
    };
    final List<_MessageLocal> locauxMontres = <_MessageLocal>[
      for (final _MessageLocal m in _locaux)
        if (m.source != null
            ? !(m.etat == EtatEnvoiMessage.envoye &&
                  serveur[m.idMessage]?.image?.etat ==
                      EtatImageMessage.confirmee)
            : m.etat == EtatEnvoiMessage.echec ||
                  !revenusDuServeur.remove(m.texte.trim()))
          m,
    ];
    final Set<String> masques = <String>{
      for (final _MessageLocal m in locauxMontres)
        if (m.idMessage != null) m.idMessage!,
    };
    final List<_Ligne> lignes = _lignesDuFil(locauxMontres, masques);
    final Widget? enteteDonne = widget.entete;
    final Widget? entete = enteteDonne == null
        ? null
        : KeyedSubtree(
            key: _cleEntete,
            child: RangeeEnteteEspace(child: enteteDonne),
          );
    final Widget? compacteDonnee = widget.enteteCompacte;
    // N-1 : la ligne compacte porte les actions de l'espace (retour, (i)),
    // dans la meme rangee : elles restent a l'ecran avec le contexte.
    final Widget? compacte = compacteDonnee == null
        ? null
        : KeyedSubtree(
            key: FilDiscussion.cleEnteteCompacte,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              // Une ligne, qui ne grandit pas au-dela de 150 % : a texte
              // double, elle prenait le quart de l'ecran a 320. Le contexte
              // entier reste lu (semantique de la ligne) et ecrit dans le
              // panneau (i).
              child: RangeeEnteteEspace(
                child: _avecRetourCompacte(
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: SeuilsTexteAgrandi.echelle,
                    child: compacteDonnee,
                  ),
                ),
              ),
            ),
          );
    final Widget? suite = widget.enteteSuite;
    final Widget? pieceJointe = widget.emplacementPieceJointe;
    final Widget? vocal = widget.emplacementVocal;
    final TextTheme styles = Theme.of(context).textTheme;
    Widget zoneSaisie({required bool reduite}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_coeurEchec)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Text(
                t.com.messages.images.coeurEchec,
                style: AppPalette.of(context).inkAlert
                    .applyTo(styles.bodySmall ?? const TextStyle()),
              ),
            ),
          ),
        if (_restaure)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Text(
                x.brouillonRestaure ??
                    t.com.socle.composants.composer.brouillonRestaure,
                key: FilDiscussion.cleBrouillonRestaure,
                style: AppPalette.of(context).inkMuted
                    .applyTo(styles.bodySmall ?? const TextStyle()),
              ),
            ),
          ),
        if (pieceJointe != null && !_vocalOuvert)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: pieceJointe,
          ),
        _Saisie(
          champ: _champ,
          cleChamp: _cleChamp,
          noeudChamp: _noeudChamp,
          vide: _vide,
          textes: x,
          onEnvoyer: _envoyer,
          reduite: reduite,
          sansExplication: widget.pleinEcran,
          onImage: widget.onEnvoyerImage != null && !_vocalOuvert
              ? _joindreImage
              : null,
          deuxChoixPhoto:
              widget.deuxChoixPhoto ?? appareilPhotoProposeParDefaut,
          onMicro: vocal != null && _microDisponible && !_vocalOuvert
              ? _demanderVocal
              : null,
          vocalOuvert: vocal != null && _vocalOuvert,
          vocal: vocal == null
              ? null
              : DemandeVocalFil(
                  demandes: _demandesVocal,
                  child: NotificationListener<MicroVocalFil>(
                    onNotification: _surMicroVocal,
                    child: NotificationListener<PanneauVocalFil>(
                      onNotification: _surPanneauVocal,
                      child:
                          NotificationListener<SizeChangedLayoutNotification>(
                            onNotification: _surTailleVocal,
                            child: SizeChangedLayoutNotifier(child: vocal),
                          ),
                    ),
                  ),
                ),
        ),
      ],
    );
    final String? limite = widget.lectureSeule;
    if (widget.pleinEcran) {
      return _pleinEcran(
        context,
        lignes: lignes,
        zoneSaisie: zoneSaisie,
        limite: limite,
        styles: styles,
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double hauteur = contraintes.maxHeight;
        // R-02 : a texte agrandi ou sur une vue basse, l'en-tete defile avec
        // les messages au lieu de leur prendre la hauteur. La vue se mesure
        // sans le clavier logiciel : l'ouvrir ne deplace pas l'en-tete. Le
        // `Scaffold` retire le clavier de la `MediaQuery` de son corps : on
        // le lit sur la vue.
        final FlutterView vue = View.of(context);
        final double hauteurSansClavier =
            hauteur + vue.viewInsets.bottom / vue.devicePixelRatio;
        // Constat 2 (COM-R-3) : en lecture seule comme ailleurs, l'en-tete
        // ne defile (et la ligne compacte ne le remplace) que quand la
        // hauteur l'exige : texte agrandi ou vue basse. A 1440, le canal en
        // lecture seule garde son en-tete complet, fixe.
        final bool texteAgrandi = SeuilsTexteAgrandi.texteAgrandi(context);
        final bool enteteDefilante =
            texteAgrandi ||
            hauteurSansClavier < SeuilsTexteAgrandi.hauteurBasse;
        // N-1 : quand l'en-tete defile, sa ligne compacte reste fixe ; le
        // reste de l'en-tete defile, apres la tete de la page.
        final bool compacteFixe = compacte != null && enteteDefilante;
        final Widget? teteDePage = _teteDePage;
        final List<Widget> debut = <Widget>[
          ?teteDePage,
          if (compacteFixe)
            ?suite
          else if (entete != null && enteteDefilante)
            entete,
        ];
        // COM-RC tour 3 (R-02) : quand l'en-tete defile (texte agrandi, vue
        // basse), la saisie defile aussi, apres le dernier message. Bornee
        // sous la liste, elle depassait sa borne a 320 et texte x2 et
        // coupait « Envoyer » au bas de l'ecran ; dans la liste, le
        // defilement initial va jusqu'au bas de la saisie : le dernier
        // message, le champ et « Envoyer » entier au premier ecran. Elle est
        // une tranche a part de la liste : un message ajoute ne la
        // reconstruit pas (le champ garde son focus).
        // JONCTION-LIGNES-1 : un fil sans en-tete (le Controleur) garde sa
        // saisie sous la liste, dans la colonne de corps de SUPERPOS-1, et
        // la page garde sa tete compacte au-dessus.
        final bool saisieDansListe =
            limite == null &&
            enteteDefilante &&
            (widget.entete != null || widget.enteteCompacte != null);
        _saisieDansListe = saisieDansListe;
        // Decision « Focus a 320 » : en Focus, a texte agrandi sur un
        // telephone etroit, la saisie dans la liste se reduit a une ligne
        // tant que le champ est vide et sans focus.
        final bool reduite =
            widget.saisieReduite &&
            saisieDansListe &&
            texteAgrandi &&
            MediaQuery.sizeOf(context).width < FilDiscussion.largeurReduite &&
            _vide &&
            !_noeudChamp.hasFocus &&
            !_vocalOuvert &&
            !_restaure;
        final Widget saisie = KeyedSubtree(
          key: _cleZoneSaisie,
          child: zoneSaisie(reduite: reduite),
        );
        final bool vocalBorne = limite == null && _vocalOuvert;
        // SUPERPOS-1 : une colonne de corps qui dit a `PageShell` la hauteur
        // qui lui manque (clavier ouvert, texte double) : la page defile au
        // lieu d'ecraser la liste, qui garde au moins une bulle entiere.
        return ColonneCorps(
          minimumEtire: FilDiscussion.minimumListe(context),
          children: <Widget>[
            if (compacteFixe)
              compacte
            else if (entete != null && !enteteDefilante)
              entete,
            Expanded(
              key: FilDiscussion.cleMessages,
              child: ColoredBox(
                color: AppPalette.of(context).fondFil.background,
                child: CustomScrollView(
                  controller: _defilement,
                  slivers: <Widget>[
                    // BULLES-MESSAGERIE : les bulles se construisent au fil du
                    // defilement ; l'en-tete qui defile les precede.
                    SliverList.builder(
                      itemCount: debut.length + lignes.length,
                      itemBuilder: (BuildContext _, int i) => i < debut.length
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: debut[i],
                            )
                          : _item(
                              lignes,
                              i - debut.length,
                              apresEntete: debut.isNotEmpty,
                            ),
                    ),
                    SliverToBoxAdapter(
                      child: saisieDansListe
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.lg,
                              ),
                              child: KeyedSubtree(
                                key: FilDiscussion.cleSaisie,
                                child: saisie,
                              ),
                            )
                          : Ecart.vLg,
                    ),
                  ],
                ),
              ),
            ),
            // Hors de ce cas, la saisie, vocal compris, reste sous la liste
            // et ne prend jamais plus de 40 % de la hauteur de l'ecran
            // (60 % du fil, clavier ouvert) : au-dela, elle defile
            // elle-meme.
            if (!saisieDansListe)
              ConstrainedBox(
                key: FilDiscussion.cleSaisie,
                // N-9 : le panneau vocal releve la borne ; la saisie va a son
                // bas a l'ouverture du panneau.
                constraints: BoxConstraints(
                  maxHeight: math.min(
                    MediaQuery.sizeOf(context).height *
                        (vocalBorne
                            ? FilDiscussion.partSaisieVocalMax
                            : FilDiscussion.partSaisieMax),
                    hauteur.isFinite
                        ? hauteur *
                              (vocalBorne
                                  ? FilDiscussion.partSaisieFilVocalMax
                                  : FilDiscussion.partSaisieFilMax)
                        : double.infinity,
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _defilementSaisie,
                  child: limite == null
                      ? saisie
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Text(
                            limite,
                            key: FilDiscussion.cleLectureSeule,
                            style: AppPalette.of(context).inkMuted.applyTo(
                              styles.bodyMedium ?? const TextStyle(),
                            ),
                          ),
                        ),
                ),
              ),
            // N-9 : sous la saisie bornee qu'occupe le panneau vocal, une
            // marge : il ne touche ni la barre de navigation ni le bord.
            if (!saisieDansListe && vocalBorne)
              const SizedBox(
                key: FilDiscussion.cleMargeVocal,
                height: AppSpacing.lg,
              ),
          ],
        );
      },
    );
  }
}

/// Une ligne du fil, calculee une fois (voir `_lignesDuFil`) : un message, un
/// message local, un separateur de jour, ou l'etat vide.
@immutable
class _Ligne {
  const _Ligne.message(
    MessageFil this.message, {
    required this.ecartAvant,
    required this.dernier,
    required this.avecNom,
  }) : local = null,
       jour = null,
       vide = false;

  const _Ligne.local(_MessageLocal this.local, {required this.ecartAvant})
    : message = null,
      jour = null,
      dernier = true,
      avecNom = false,
      vide = false;

  const _Ligne.pastilleJour(String this.jour)
    : message = null,
      local = null,
      ecartAvant = AppSpacing.md,
      dernier = true,
      avecNom = false,
      vide = false;

  const _Ligne.videLigne()
    : message = null,
      local = null,
      jour = null,
      ecartAvant = 0,
      dernier = true,
      avecNom = false,
      vide = true;

  final MessageFil? message;
  final _MessageLocal? local;
  final String? jour;
  final bool vide;

  /// L'espace au-dessus de la ligne.
  final double ecartAvant;

  /// Le dernier message de son groupe : il porte l'heure et le coin a 4.
  final bool dernier;

  /// Le nom de l'auteur se lit sur cette bulle.
  final bool avecNom;
}

/// Le separateur de jour : une pastille centree (« Aujourd'hui », « Hier »,
/// ou la date).
class _PastilleJour extends StatelessWidget {
  const _PastilleJour({required this.libelle});

  final String libelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          borderRadius: AppRadius.arrondiFull,
        ),
        child: Text(
          libelle,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }
}

/// La bulle d'un message (BULLES-MESSAGERIE, directeur, 16/11/2026) : la
/// taille de son contenu sans depasser les trois quarts de la colonne, une
/// marge toujours libre du cote oppose, le recu cote debut sur une carte claire
/// a une ombre legere, le sien cote fin sur un violet profond a texte casse.
/// Aucune bordure ; l'heure se pose sous la bulle, de son cote.
class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.auteur,
    required this.afficherNom,
    required this.texte,
    required this.deSoi,
    required this.coinPetit,
    super.key,
    this.heure,
    this.mot,
    this.complement,
    this.annonce,
    this.etatVivant = false,
    this.echec = false,
    this.ligneEchec,
    this.causeEchec,
    this.actionsEchec,
    this.remise,
    this.image,
    this.adresse,
    this.progression,
    this.enPreparation = false,
    this.repli,
    this.adresseIntrouvable = false,
    this.attendImage = true,
    this.coeurs = 0,
    this.aime = false,
    this.groupe = false,
    this.onOuvrirImage,
    this.onAimer,
    this.onCopier,
  });

  /// IMAGES-MESSAGERIE : l'image, son adresse, l'envoi en cours.
  final ImageMessage? image;
  final AdresseImage? adresse;
  final ValueListenable<double>? progression;
  final bool enPreparation;
  final Future<AdresseImage?> Function()? repli;
  final bool adresseIntrouvable;
  final bool attendImage;

  /// Le coeur : son compte, le mien, et si le fil a plus de deux personnes.
  final int coeurs;
  final bool aime;
  final bool groupe;

  /// Toucher l'image, double toucher, menu « Copier le texte ».
  final VoidCallback? onOuvrirImage;
  final VoidCallback? onAimer;
  final VoidCallback? onCopier;

  final String auteur;
  final bool afficherNom;
  final String texte;

  /// L'heure sous la bulle, ou `null` : aucune (message au milieu d'un groupe).
  final String? heure;

  /// Le mot de l'etat (« Envoye », « Lu », « Envoi en cours »), dit au lecteur
  /// d'ecran ; sous la bulle, quand il n'y a pas d'heure, il s'ecrit.
  final String? mot;
  final bool deSoi;

  /// Le dernier message de son groupe : le coin du cote de celui qui parle
  /// passe au plus petit rayon.
  final bool coinPetit;
  final RemiseMessage? remise;
  final Widget? complement;
  final String? annonce;
  final bool etatVivant;
  final bool echec;

  /// IMAGES-CORRECTIF : en echec, la ligne courte sous la bulle, a la place de
  /// l'heure (« Non confirme · Toucher pour reessayer »), la cause connue
  /// au-dessus d'elle, et le menu que la ligne et l'icone d'alerte ouvrent
  /// (« Reessayer », « Supprimer »).
  final String? ligneEchec;
  final String? causeEchec;
  final List<EntreeAction>? actionsEchec;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair fond = deSoi
        ? palette.surfaceBulleSoi
        : palette.surfaceRaised;
    final TextDirection sens = sensDuContenu(context, texte);
    const Radius grand = Radius.circular(AppRadius.md);
    const Radius petit = Radius.circular(AppRadius.xs);
    final BorderRadiusDirectional forme = BorderRadiusDirectional.only(
      topStart: grand,
      topEnd: grand,
      bottomStart: !deSoi && coinPetit ? petit : grand,
      bottomEnd: deSoi && coinPetit ? petit : grand,
    );
    // Le texte du message : l'encre forte du corps (recu), ou le blanc casse
    // de la paire (le sien), en graisse normale (`bodyLarge`, 400), jamais en gras.
    final TextStyle base = textes.bodyLarge ?? const TextStyle();
    final TextStyle styleTexte = deSoi
        ? fond.applyTo(base)
        : palette.inkStrong.applyTo(base);
    Widget construireBulle(double largeurImageMax) {
      final ImageMessage? image = this.image;
      final bool imageRetiree =
          image != null && image.etat == EtatImageMessage.supprimee;
      final bool imageVisible = image != null && !imageRetiree;
      final TailleImageBulle? tailleImage = !imageVisible
          ? null
          : tailleImageBulle(
              image,
              largeurMax: largeurImageMax,
              hauteurMax: hauteurMaxImageBulle(
                MediaQuery.sizeOf(context).width,
              ),
            );
      final bool aDuContenu =
          afficherNom || texte.isNotEmpty || complement != null || imageRetiree;
      final Widget? contenu = !aDuContenu
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              // Le sens du texte suit la langue du message (premiere lettre
              // forte) : un texte arabe dans l'interface francaise s'aligne a
              // droite, et l'inverse.
              // Le nom n'est pas ecrit quand [afficherNom] est faux, il reste
              // dit : le lecteur d'ecran annonce toujours l'auteur.
              child: Semantics(
                container: !afficherNom,
                label: afficherNom ? null : auteur,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // IMAGES-MESSAGERIE : une image retiree n'est pas un cadre
                    // vide, une fine ligne discrete la dit ; le texte reste
                    // lisible dessous.
                    if (imageRetiree) ...<Widget>[
                      const LigneImageRetiree(),
                      if (afficherNom || texte.isNotEmpty) Ecart.vSm,
                    ],
                    // Seuls le nom et le texte suivent le sens du message : la
                    // piece jointe garde le sens de l'interface.
                    if (afficherNom || texte.isNotEmpty)
                      Directionality(
                        textDirection: sens,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (afficherNom)
                              Text(
                                auteur,
                                style: palette.inkMuted.applyTo(
                                  textes.labelMedium ?? const TextStyle(),
                                ),
                              ),
                            if (texte.isNotEmpty) ...<Widget>[
                              if (afficherNom) Ecart.vXs,
                              Text(
                                texte,
                                textDirection: sens,
                                style: styleTexte,
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (complement case final Widget complement) ...<Widget>[
                      if (afficherNom || texte.isNotEmpty || imageRetiree)
                        Ecart.vSm,
                      complement,
                    ],
                  ],
                ),
              ),
            );
      final DecoratedBox fondBulle = DecoratedBox(
        decoration: BoxDecoration(
          color: fond.background,
          borderRadius: forme,
          boxShadow: deSoi
              ? AppElevation.niveau0
              : AppElevation.bulle(palette.ombre),
        ),
        child: tailleImage == null
            ? contenu
            : ClipRRect(
                borderRadius: forme,
                child: SizedBox(
                  width: tailleImage.largeur,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ImageDeBulle(
                        image: image!,
                        taille: tailleImage,
                        adresse: adresse,
                        progression: progression,
                        enPreparation: enPreparation,
                        repli: repli,
                        adresseIntrouvable: adresseIntrouvable,
                        attend: attendImage,
                      ),
                      ?contenu,
                    ],
                  ),
                ),
              ),
      );
      final bool interactive =
          onAimer != null || onOuvrirImage != null || onCopier != null;
      Widget bulle = !interactive
          ? fondBulle
          : _PorteMenu(
              construire: (BuildContext _, MenuAncreControleur menu) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // IMAGES-MESSAGERIE : toucher l'image l'ouvre ; double toucher =
                  // coeur ; appui long = menu (J'aime, Copier le texte).
                  Pressable(
                    onPress: onOuvrirImage,
                    onDoubleTap: onAimer,
                    onLongPress: menu.ouvrir,
                    respecterCibleTactile: false,
                    arrondiFocus: forme.resolve(Directionality.of(context)),
                    libelleSemantique: onOuvrirImage != null
                        ? t.com.messages.images.imageJointe
                        : null,
                    child: fondBulle,
                  ),
                  // Le menu : un declencheur vide, ouvert par l'appui long.
                  PositionedDirectional(
                    bottom: 0,
                    start: 0,
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: MenuActions(
                          controleur: menu,
                          libelle: t.com.messages.images.actionsMessage,
                          declencheur: (BuildContext _, EtatPression _) =>
                              const SizedBox.shrink(),
                          actions: <EntreeAction>[
                            if (onAimer != null)
                              EntreeAction(
                                libelle: aime
                                    ? t.com.messages.images.nePlusAimer
                                    : t.com.messages.images.jaime,
                                icone: AppIcons.coeur,
                                onChoix: onAimer!,
                              ),
                            if (onCopier != null)
                              EntreeAction(
                                libelle: t.com.messages.images.copierTexte,
                                icone: AppIcons.copier,
                                onChoix: onCopier!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
      if (coeurs > 0) {
        // La pastille de coeur pend au coin bas, cote exterieur ; la place
        // qu'elle prend sous la bulle est reservee.
        bulle = Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: bulle,
            ),
            PositionedDirectional(
              bottom: 0,
              end: deSoi ? AppSpacing.sm : null,
              start: deSoi ? null : AppSpacing.sm,
              child: PastilleCoeur(
                coeurs: coeurs,
                aimeParMoi: aime,
                avecCompte: groupe,
              ),
            ),
          ],
        );
      }
      if (annonce != null) {
        // Arrive pendant la lecture : une annonce polie, sans voler le focus.
        bulle = Semantics(liveRegion: true, label: annonce, child: bulle);
      }
      return bulle;
    }

    final Widget? pied = heure == null && mot == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _PiedMessage(
              heure: heure,
              mot: mot,
              remise: remise,
              echec: echec,
              etatVivant: etatVivant,
              style: textes.bodySmall ?? const TextStyle(),
            ),
          );
    final List<EntreeAction>? menuEchec = actionsEchec;
    final String? ligne = ligneEchec;
    final double cibleEchec = AppMetriques.of(context).cibleTactile;
    final Widget? piedEchec = !echec || menuEchec == null || ligne == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: deSoi
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: <Widget>[
              MenuActions(
                key: FilDiscussion.cleLigneEchec,
                // La cause connue n'est plus ecrite sous la bulle (redondante
                // avec la ligne, directeur 16/11/2026) : elle reste dite au
                // lecteur d'ecran.
                libelle: <String>[ligne, ?causeEchec].join('. '),
                actions: menuEchec,
                declencheur: (BuildContext _, EtatPression _) => ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cibleEchec),
                  child: Align(
                    alignment: deSoi
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    widthFactor: 1,
                    child: Text(
                      ligne,
                      style: palette.inkAlert.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
    // L'icone d'alerte ronde, dans la marge libre du cote de l'autre
    // partie : une cible de 48 qui ouvre le meme menu que la ligne.
    final Widget? iconeEchec = !echec || menuEchec == null
        ? null
        : MenuActions(
            key: FilDiscussion.cleIconeEchec,
            libelle: t.com.messages.images.actionsEchec,
            actions: menuEchec,
            declencheur: (BuildContext _, EtatPression _) => SizedBox.square(
              dimension: cibleEchec,
              child: Center(
                child: Icon(
                  AppIcons.avertissement.repos,
                  size: AppSpacing.xxl,
                  color: palette.inkAlert.asIconTheme().color,
                ),
              ),
            ),
          );
    return ApparitionDouce(
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints colonne) {
          final double l = colonne.maxWidth;
          // Au plus 75 % de la colonne (560 sur ordinateur), et toujours 64
          // de libres du cote oppose.
          final double maxi = math.max(
            0,
            math.min(
              math.min(
                FilDiscussion.largeurBulleMax,
                // Une bulle qui porte une piece (carte, lecteur vocal) prend
                // la colonne moins la marge : le nom d'un fichier garde son
                // debut (R-11).
                l * (complement == null ? FilDiscussion.partBulle : 1),
              ),
              l - FilDiscussion.margeOpposee,
            ),
          );
          return Align(
            alignment: deSoi
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              // Avec l'icone d'alerte, la colonne prend sa place en plus : elle
              // tient dans la marge libre de 64 du cote oppose.
              constraints: BoxConstraints(
                maxWidth: iconeEchec == null
                    ? maxi
                    : math.min(l, maxi + cibleEchec + AppSpacing.xs),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: deSoi
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  if (iconeEchec == null)
                    construireBulle(maxi)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        iconeEchec,
                        Ecart.hXs,
                        Flexible(child: construireBulle(maxi)),
                      ],
                    ),
                  ?pied,
                  ?piedEchec,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Porte le controleur du menu d'une bulle (ouvert par l'appui long).
class _PorteMenu extends StatefulWidget {
  const _PorteMenu({required this.construire});

  final Widget Function(BuildContext context, MenuAncreControleur menu)
  construire;

  @override
  State<_PorteMenu> createState() => _PorteMenuEtat();
}

class _PorteMenuEtat extends State<_PorteMenu> {
  final MenuAncreControleur _menu = MenuAncreControleur();

  @override
  Widget build(BuildContext context) => widget.construire(context, _menu);
}

/// Le pied d'un message : l'heure en petit, et pour un message de soi les
/// coches « envoye / lu » (MESSAGERIE-LU, directeur, 14/11/2026). Trois
/// signaux, jamais la couleur seule : l'icone (horloge, une coche, deux
/// coches), le mot (dit au lecteur d'ecran, ecrit quand il n'y a pas d'heure)
/// et l'encre (discrete tant que le message n'est pas lu, d'accent une fois
/// lu). L'icone reste au trait : la graisse pleine de `checks` dessine un
/// carre plein, illisible a 16.
class _PiedMessage extends StatelessWidget {
  const _PiedMessage({
    required this.heure,
    required this.mot,
    required this.remise,
    required this.echec,
    required this.etatVivant,
    required this.style,
  });

  final String? heure;
  final String? mot;
  final RemiseMessage? remise;
  final bool echec;
  final bool etatVivant;
  final TextStyle style;

  /// La cle du signe, pour les tests.
  static Key cle(RemiseMessage r) => ValueKey<String>('remise-${r.name}');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool lu = remise == RemiseMessage.lu;
    final AppInkColor encre = echec
        ? palette.inkAlert
        : lu
        ? palette.inkAccent
        : palette.inkMuted;
    final AppIcon? icone = switch (remise) {
      null => null,
      RemiseMessage.enCours => AppIcons.horloge,
      RemiseMessage.envoye => AppIcons.messageEnvoye,
      RemiseMessage.lu => AppIcons.messageLu,
    };
    // Le texte ecrit : l'heure ; sans heure (message local), le mot.
    final String ecrit = heure ?? mot ?? '';
    final String dit = <String>[?heure, ?mot].join(', ');
    return Semantics(
      liveRegion: etatVivant,
      label: dit,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: Text(ecrit, style: encre.applyTo(style))),
            if (icone != null) ...<Widget>[
              Ecart.hXs,
              Icon(
                icone.repos,
                key: cle(remise!),
                size: AppSpacing.lg,
                color: encre.asBorderSide().color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.champ,
    required this.cleChamp,
    required this.noeudChamp,
    required this.vide,
    required this.textes,
    required this.onEnvoyer,
    this.reduite = false,
    this.onMicro,
    this.onImage,
    this.deuxChoixPhoto = false,
    this.vocal,
    this.vocalOuvert = false,
    this.sansExplication = false,
  });

  final TextEditingController champ;

  /// La cle globale du champ : il garde son etat (texte, focus) quand sa
  /// rangee change de forme.
  final GlobalKey cleChamp;
  final FocusNode noeudChamp;
  final bool vide;
  final TextesFilDiscussion textes;
  final VoidCallback onEnvoyer;

  /// Vrai quand la saisie est reduite a une ligne (Focus a 320, texte x2) :
  /// le champ seul (et le micro), sans aide ni « Envoyer » inerte.
  final bool reduite;

  /// Le toucher du micro (R-28), ou `null` : aucun micro (pas de composer
  /// vocal, capacite `envoyerVocal` fermee, enregistreur absent).
  final VoidCallback? onMicro;

  /// IMAGES-MESSAGERIE : le choix d'une photo, ou `null` : aucune icone (fil
  /// en lecture seule, ou compte eleve de moins de 18 ans).
  final void Function([SourceImage source])? onImage;

  /// Deux choix au toucher de l'icone : appareil photo ou galerie.
  final bool deuxChoixPhoto;
  final Widget? vocal;

  /// Vrai pendant l'enregistrement et la pre-ecoute : le panneau vocal
  /// remplace la rangee texte (R-04), qui revient ensuite avec son texte.
  final bool vocalOuvert;

  /// Plein ecran : aucune phrase d'aide sous le champ.
  final bool sansExplication;

  static const Key _cleVocal = ValueKey<String>('fil-discussion-vocal');

  @override
  Widget build(BuildContext context) {
    final Widget? vocal = this.vocal;
    final Widget rangee = _rangee();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: vocal == null
          ? rangee
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!vocalOuvert) ...<Widget>[rangee, Ecart.vSm],
                // Toujours le dernier enfant, sous sa cle : le composer vocal
                // garde son etat quand la rangee texte s'efface ou revient.
                KeyedSubtree(
                  key: _cleVocal,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: vocal,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _rangee() {
    // SUPERPOS-1 (decide par delegation le 05/10), repris dans le fil des
    // Communications par JONCTION-LIGNES-1 : la zone de saisie partagee du
    // core. L'envoi est une icone nommee DANS le champ, centree en hauteur ;
    // tant que le champ est vide, elle n'est pas rendue (jamais grisee, ni
    // « Envoyer » inerte) et la raison est ecrite sous le champ. Le champ
    // prend toute la largeur, moins le micro : a 320 en texte double, il ne
    // cede plus la moitie de la ligne a un bouton, et la saisie n'a plus a
    // s'empiler (COM-FUS, lot K).
    final Widget saisie = KeyedSubtree(
      key: cleChamp,
      child: raccourciEnvoi(
        onEnvoyer: onEnvoyer,
        child: LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) {
            // Lot K, point 4 (COM-RC) : l'aide ne se peint que si elle tient
            // entiere sur une ligne du champ, place de l'envoi deduite ; le
            // champ garde une ligne au repos comme au toucher et ne grandit
            // qu'avec le texte saisi. Peinte ou non, le lecteur d'ecran la
            // dit toujours, une seule fois.
            final double placeEnvoi = reduite
                ? 0
                : AppTouchTarget.standard + AppSpacing.xs;
            final bool aidePeinte = _aideTient(
              contexte,
              contraintes.maxWidth - placeEnvoi,
            );
            // Material ne peint l'aide que champ vide et au focus, et la
            // retire alors de la semantique : hors de ce cas, le fil la dit.
            final bool aideVisible =
                aidePeinte && noeudChamp.hasFocus && champ.text.isEmpty;
            return Semantics(
              hint: aideVisible ? null : textes.aideChamp,
              child: _zone(aidePeinte: aidePeinte),
            );
          },
        ),
      ),
    );
    return _avecMicro(saisie);
  }

  /// Vrai quand l'aide du champ tient entiere sur une ligne, dans
  /// [largeur] moins les marges interieures du theme (`AppSpacing.lg` de
  /// part et d'autre), au style et a l'echelle de texte de l'aide.
  bool _aideTient(BuildContext context, double largeur) {
    if (!largeur.isFinite) return true;
    final ThemeData theme = Theme.of(context);
    final TextPainter mesure = TextPainter(
      text: TextSpan(
        text: textes.aideChamp,
        style: DefaultTextStyle.of(context).style
            .merge(theme.textTheme.bodyLarge)
            .merge(theme.inputDecorationTheme.hintStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final bool tient =
        !mesure.didExceedMaxLines &&
        mesure.width <= largeur - 2 * AppSpacing.lg;
    mesure.dispose();
    return tient;
  }

  Widget _zone({required bool aidePeinte}) => ZoneSaisie(
    cleChamp: FilDiscussion.champKey,
    pilule: true,
    controleur: champ,
    noeud: noeudChamp,
    libelle: textes.libelleChamp,
    // Un champ d'envoi ne montre pas son etiquette : l'invite la dit,
    // le lecteur d'ecran la lit (SUPERPOS-1), saisie reduite comprise.
    libelleVisible: false,
    aide: aidePeinte ? textes.aideChamp : null,
    // La raison de l'envoi absent ; la saisie reduite n'a pas d'envoi.
    explication: vide && !reduite && !sansExplication ? textes.champVide : null,
    maxLignes: reduite ? 1 : 5,
    envoi: reduite
        ? null
        : EnvoiZoneSaisie(
            cle: FilDiscussion.envoyerKey,
            libelle: textes.envoyer,
            onEnvoyer: onEnvoyer,
          ),
  );

  /// Decision R-28 : le micro, une icone nommee (cible de 48), a cote du
  /// champ ; il ouvre l'enregistrement du composer vocal.
  Widget _avecMicro(Widget saisie) {
    final VoidCallback? onMicro = this.onMicro;
    final void Function([SourceImage source])? onImage = this.onImage;
    if (onMicro == null && onImage == null) return saisie;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: saisie),
        if (onImage != null) ...<Widget>[
          Ecart.hSm,
          if (deuxChoixPhoto)
            MenuActions(
              key: FilDiscussion.cleImage,
              icone: AppIcons.image,
              libelle: t.com.messages.images.joindre,
              actions: <EntreeAction>[
                EntreeAction(
                  libelle: t.com.messages.images.prendrePhoto,
                  icone: AppIcons.camera,
                  onChoix: () => onImage(SourceImage.camera),
                ),
                EntreeAction(
                  libelle: t.com.messages.images.choisirGalerie,
                  icone: AppIcons.image,
                  onChoix: () => onImage(SourceImage.galerie),
                ),
              ],
            )
          else
            BoutonIcone(
              key: FilDiscussion.cleImage,
              icone: AppIcons.image,
              libelle: t.com.messages.images.joindre,
              onPress: onImage,
              suitTexte: true,
            ),
        ],
        if (onMicro != null) ...<Widget>[
          Ecart.hSm,
          BoutonIcone(
            key: FilDiscussion.cleMicro,
            icone: AppIcons.micro,
            libelle: t.com.socle.composants.composer.enregistrerVocal,
            onPress: onMicro,
            // Lot K, point 2 : a texte agrandi, le micro grandit avec le texte.
            suitTexte: true,
          ),
        ],
      ],
    );
  }
}
