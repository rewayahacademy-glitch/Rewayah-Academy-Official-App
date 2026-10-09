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
import '../communications/persistance_brouillon.dart';
import '../communications/port_brouillons.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/apparition_douce.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'bouton_icone.dart';
import 'empty_state.dart';
import 'espace_travail_adaptatif.dart';
import 'page_shell.dart';
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
  });

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
}

/// L'etat d'envoi d'un message ecrit dans le fil.
enum EtatEnvoiMessage {
  /// L'envoi n'a pas encore repondu.
  enCours,

  /// L'envoi a repondu.
  envoye,

  /// L'envoi a echoue : le texte est garde, « Reessayer » est propose.
  echec,
}

class _MessageLocal {
  _MessageLocal(this.id, this.texte, this.brut);

  final String id;
  final String texte;

  /// Le texte du champ tel qu'il etait a l'envoi, donc tel que le brouillon
  /// le garde (constat 1).
  final String brut;
  EtatEnvoiMessage etat = EtatEnvoiMessage.enCours;
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
  }) : assert(
         lectureSeule != null || onEnvoyer != null || onEnvoyerMessage != null,
         'FilDiscussion demande onEnvoyer, onEnvoyerMessage ou lectureSeule.',
       );

  /// Les messages connus, du plus ancien au plus recent.
  final List<MessageFil> messages;

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

  /// La largeur sous laquelle [saisieReduite] s'applique (320 oui, 360 et
  /// 390 non).
  static const double largeurReduite = 360;

  /// La largeur d'ecran a partir de laquelle les bulles s'elargissent a la
  /// colonne du fil (COM-RC lot K, point 1) : sur tablette et bureau (canal
  /// du Studio a 768 et 1440, Focus, Messages metier, echanges du
  /// controleur), une bulle a 86 % s'arretait avant la rangee d'ecriture et
  /// « Envoyer » semblait deborder du fil. Un message recu prend alors la
  /// colonne entiere, aux bords du champ et d'« Envoyer » ; un message de
  /// soi garde un leger retrait au debut ([partBulleSoiColonne]), pose a la
  /// fin, au bord d'« Envoyer » : envoyes et recus se distinguent par leur
  /// place, pas seulement par leur teinte et « Vous ». Sur telephone, la
  /// bulle garde son retrait de conversation (86 %, a la fin pour soi).
  /// C'est l'ecran qui decide, pas la colonne : a 768, le fil (344) est plus
  /// etroit qu'a 390 (358).
  static const double largeurColonne = AppGabarit.seuilTablette;

  /// La part de la largeur du fil qu'une bulle prend sur telephone.
  static const double partBulleTelephone = 0.86;

  /// La part de la colonne qu'un message de soi prend sur tablette et
  /// bureau (lot K, point 1) ; un message recu en prend toute la largeur.
  static const double partBulleSoiColonne = 0.92;

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
  late final Set<String> _presentsALOuverture = <String>{
    for (final MessageFil m in widget.messages) m.id,
  };

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
    if (widget.controleur == null) _proprio = TextEditingController();
    _champ.addListener(_auChangement);
    _noeudChamp.addListener(_auFocusChamp);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(false));
  }

  void _auFocusChamp() {
    if (!mounted) return;
    // Au focus (clavier qui s'ouvre, « Envoyer » qui revient en saisie
    // reduite), si la fin du fil etait a l'ecran, elle y reste.
    final bool enBas =
        _defilement.hasClients &&
        _defilement.position.pixels >= _defilement.position.maxScrollExtent - 1;
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
    final TetePageConfiee? page = TetePageConfiee.de(context);
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
    final double fin = _defilement.position.maxScrollExtent;
    final Duration duree = Mouvement.duree(context, Mouvement.moyen);
    if (anime && duree > Duration.zero) {
      _defilement.animateTo(fin, duration: duree, curve: Mouvement.entree);
    } else {
      _defilement.jumpTo(fin);
      // La liste est paresseuse : sa fin est estimee tant que les derniers
      // messages (cartes de pieces, lecteurs) ne sont pas mesures. On
      // rejoint la vraie fin une fois ceux-ci poses.
      if (reprises > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_defilement.hasClients) return;
          final ScrollPosition p = _defilement.position;
          if (p.pixels < p.maxScrollExtent) _allerEnBas(false, reprises - 1);
        });
      }
    }
  }

  void _envoyer() {
    if (_vide || _vocalOuvert) return;
    final _MessageLocal m = _MessageLocal(
      'local-${_compteurSession++}',
      _champ.text.trim(),
      _champ.text,
    );
    setState(() => _locaux.add(m));
    // N-3 : le champ se vide tout de suite, mais le brouillon reste jusqu'a
    // l'accuse (comme la reponse de la Communaute) : quitter le fil avant
    // lui ne perd pas le message. Le champ vide n'est pas note.
    _persistance?.caler('');
    _champ.clear();
    _tenter(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(true));
  }

  Future<void> _tenter(_MessageLocal m) async {
    setState(() => m.etat = EtatEnvoiMessage.enCours);
    // Lus avant l'attente : l'accuse peut arriver fil ferme (constat 1).
    final CleBrouillon? cle = widget.cleBrouillon;
    final PersistanceBrouillon? persistance = _persistance;
    // Le texte attend son accuse (premier envoi comme nouvel essai) : un fil
    // rouvert d'ici la ne le remet pas dans son champ.
    if (cle != null) persistance?.marquerEnAttente(cle, m.brut);
    try {
      final Future<void> Function(String, String)? identifie =
          widget.onEnvoyerMessage;
      if (identifie != null) {
        await identifie(m.id, m.texte);
      } else {
        await widget.onEnvoyer!(m.texte);
      }
      _effacerBrouillonDe(m, cle, persistance);
      if (cle != null) persistance?.terminerEnvoi(cle, m.brut, accuse: true);
      if (!mounted) return;
      setState(() => m.etat = EtatEnvoiMessage.envoye);
    } on Object {
      if (cle != null) persistance?.terminerEnvoi(cle, m.brut, accuse: false);
      if (!mounted) return;
      setState(() => m.etat = EtatEnvoiMessage.echec);
    }
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

  @override
  Widget build(BuildContext context) {
    final TextesFilDiscussion x = widget.textes;
    final List<Widget> bulles = <Widget>[
      for (final MessageFil m in widget.messages)
        _Bulle(
          key: ValueKey<String>('message-${m.id}'),
          auteur: m.auteur,
          texte: m.texte,
          pied: m.horodatage,
          deSoi: m.deSoi,
          complement: m.complement,
          annonce: _presentsALOuverture.contains(m.id)
              ? null
              : x.annonce(m.auteur, m.annonceTexte ?? m.texte),
        ),
      for (final _MessageLocal m in _locaux)
        _Bulle(
          key: ValueKey<String>('message-${m.id}'),
          auteur: x.auteurSoi,
          texte: m.texte,
          pied: switch (m.etat) {
            EtatEnvoiMessage.enCours => x.enCours,
            EtatEnvoiMessage.envoye => x.envoye,
            EtatEnvoiMessage.echec => x.echec,
          },
          deSoi: true,
          // L'etat change sous les yeux : il est annonce a chaque etape.
          etatVivant: true,
          echec: m.etat == EtatEnvoiMessage.echec,
          libelleReessayer: m.etat == EtatEnvoiMessage.echec
              ? x.reessayer
              : null,
          onReessayer: () => _tenter(m),
        ),
    ];
    if (bulles.isEmpty) {
      // R-24 : un fil sans message le dit, jamais une zone blanche.
      bulles.add(
        EmptyState(
          key: FilDiscussion.cleAucunMessage,
          message:
              x.aucunMessageTitre ??
              t.com.socle.composants.composer.aucunMessageTitre,
          invitation:
              x.aucunMessage ?? t.com.socle.composants.composer.aucunMessage,
          registre: RegistreVide.subi,
        ),
      );
    }
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
        final List<Widget> elements = <Widget>[
          ?teteDePage,
          if (compacteFixe)
            ?suite
          else if (entete != null && enteteDefilante)
            entete,
          ...bulles,
        ];
        // COM-RC tour 3 (R-02) : quand l'en-tete defile (texte agrandi, vue
        // basse), la saisie defile aussi, apres le dernier message. Bornee
        // sous la liste, elle depassait sa borne a 320 et texte x2 et
        // coupait « Envoyer » au bas de l'ecran ; dans la liste, le
        // defilement initial va jusqu'au bas de la saisie : le dernier
        // message, le champ et « Envoyer » entier au premier ecran. Elle est
        // une tranche a part de la liste : un message ajoute ne la
        // reconstruit pas (le champ garde son focus).
        final bool saisieDansListe = limite == null && enteteDefilante;
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
              child: CustomScrollView(
                controller: _defilement,
                slivers: <Widget>[
                  SliverList.separated(
                    itemCount: elements.length,
                    separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
                    itemBuilder: (BuildContext _, int i) => elements[i],
                  ),
                  SliverToBoxAdapter(
                    child: saisieDansListe
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
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

class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.auteur,
    required this.texte,
    required this.pied,
    required this.deSoi,
    super.key,
    this.complement,
    this.annonce,
    this.etatVivant = false,
    this.echec = false,
    this.libelleReessayer,
    this.onReessayer,
  });

  final String auteur;
  final String texte;
  final String pied;
  final bool deSoi;
  final Widget? complement;
  final String? annonce;
  final bool etatVivant;
  final bool echec;
  final String? libelleReessayer;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair fond = deSoi
        ? palette.washAccent
        : palette.surfaceRaised;
    Widget bulle = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: fond.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.fromBorderSide(
          (echec ? palette.inkAlert : palette.borderHairline).asBorderSide(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            auteur,
            style: palette.inkMuted.applyTo(
              textes.labelMedium ?? const TextStyle(),
            ),
          ),
          if (texte.isNotEmpty) ...<Widget>[
            Ecart.vXs,
            Text(
              texte,
              // Le message garde le sens de sa langue (COM-RC tour 3).
              textDirection: sensDuContenu(context, texte),
              style: fond.applyTo(textes.bodyLarge ?? const TextStyle()),
            ),
          ],
          if (complement case final Widget complement) ...<Widget>[
            Ecart.vSm,
            complement,
          ],
          Ecart.vSm,
          Semantics(
            liveRegion: etatVivant,
            child: Text(
              pied,
              style: (echec ? palette.inkAlert : palette.inkMuted).applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          if (libelleReessayer != null) ...<Widget>[
            Ecart.vXs,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                libelle: libelleReessayer!,
                onPress: onReessayer,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                // Lot K : « Reessayer » s'aligne sur le texte de la bulle.
                compacte: true,
                affleurant: true,
              ),
            ),
          ],
        ],
      ),
    );
    if (annonce != null) {
      // Arrive pendant la lecture : une annonce polie, sans voler le focus.
      bulle = Semantics(liveRegion: true, label: annonce, child: bulle);
    }
    return ApparitionDouce(
      child: Align(
        alignment: deSoi
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          // Lot K, point 1 : sur tablette et bureau, un message recu prend
          // la colonne entiere (bords du champ et d'« Envoyer ») ; un message
          // de soi garde un leger retrait au debut, pose au bord de fin.
          widthFactor:
              MediaQuery.sizeOf(context).width < FilDiscussion.largeurColonne
              ? FilDiscussion.partBulleTelephone
              : deSoi
              ? FilDiscussion.partBulleSoiColonne
              : 1,
          alignment: deSoi
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: bulle,
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
    this.vocal,
    this.vocalOuvert = false,
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
  final Widget? vocal;

  /// Vrai pendant l'enregistrement et la pre-ecoute : le panneau vocal
  /// remplace la rangee texte (R-04), qui revient ensuite avec son texte.
  final bool vocalOuvert;

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
        child: ZoneSaisie(
          cleChamp: FilDiscussion.champKey,
          controleur: champ,
          noeud: noeudChamp,
          libelle: textes.libelleChamp,
          // Un champ d'envoi ne montre pas son etiquette : l'invite la dit,
          // le lecteur d'ecran la lit (SUPERPOS-1), saisie reduite comprise.
          libelleVisible: false,
          aide: textes.aideChamp,
          // La raison de l'envoi absent ; la saisie reduite n'a pas d'envoi.
          explication: vide && !reduite ? textes.champVide : null,
          maxLignes: reduite ? 1 : 5,
          envoi: reduite
              ? null
              : EnvoiZoneSaisie(
                  cle: FilDiscussion.envoyerKey,
                  libelle: textes.envoyer,
                  onEnvoyer: onEnvoyer,
                ),
        ),
      ),
    );
    // Decision R-28 : le micro, une icone nommee (cible de 48), a cote du
    // champ ; il ouvre l'enregistrement du composer vocal.
    final VoidCallback? onMicro = this.onMicro;
    if (onMicro == null) return saisie;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: saisie),
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
    );
  }
}
