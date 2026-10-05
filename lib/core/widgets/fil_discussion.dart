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
//   messages (premier element de la liste) ; les actions de l'espace de
//   travail (retour, panneau de contexte) se posent dans la rangee de
//   l'en-tete ; la saisie, vocal compris, est bornee a 40 % de la hauteur
//   et defile elle-meme ;
// - R-04 : pendant l'enregistrement et la pre-ecoute d'un vocal, son
//   panneau remplace la rangee texte (un seul « Envoyer » a l'ecran) ;
// - R-22 : le fil porte seul la persistance du brouillon de son champ
//   ([FilDiscussion.cleBrouillon]) et accepte un controleur exterieur ;
// - R-24 : un fil sans message le dit (« Aucun message pour le moment ») ;
// - R-25 : Ctrl+Entree (Cmd+Entree) envoie, Entree garde le saut de ligne ;
// - R-07 : un mode lecture seule ([FilDiscussion.lectureSeule]) : les memes
//   bulles, l'en-tete qui defile avec elles, puis la phrase qui dit la
//   limite ; ni champ ni bouton. Messages metier et canaux du Studio le
//   lisent tous deux, au lieu de leurs deux copies.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communications/port_brouillons.dart';
import '../i18n/strings.g.dart';
import '../mouvement/apparition_douce.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'empty_state.dart';
import 'espace_travail_adaptatif.dart';

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
  _MessageLocal(this.id, this.texte);

  final String id;
  final String texte;
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
/// A texte agrandi (au moins 150 %) ou sous [hauteurBasse], l'en-tete
/// defile avec les messages ; la saisie ne prend jamais plus de
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
    this.emplacementPieceJointe,
    this.emplacementVocal,
    this.controleur,
    this.cleBrouillon,
    this.lectureSeule,
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

  /// Sous cette hauteur recue, l'en-tete defile avec les messages (R-02).
  static const double hauteurBasse = 480;

  /// A partir de cette echelle de texte, l'en-tete defile avec les messages.
  static const double echelleTexteAgrandi = 1.5;

  /// La part de la hauteur de l'ecran que la saisie occupe au plus (R-02).
  static const double partSaisieMax = 0.4;

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

  TextEditingController? _proprio;
  final ScrollController _defilement = ScrollController();
  final List<_MessageLocal> _locaux = <_MessageLocal>[];
  late final Set<String> _presentsALOuverture = <String>{
    for (final MessageFil m in widget.messages) m.id,
  };

  /// Le panneau vocal occupe-t-il la saisie (R-04) ?
  bool _vocalOuvert = false;

  /// Le port des brouillons, lu une fois si le fil en garde un.
  PortBrouillons? _brouillons;
  bool _brouillonsLus = false;

  /// Le dernier texte garde, pour n'ecrire qu'un vrai changement.
  String _dernier = '';

  /// Vrai tant que le brouillon remis n'a pas ete touche.
  bool _restaure = false;

  TextEditingController get _champ => widget.controleur ?? _proprio!;

  @override
  void initState() {
    super.initState();
    if (widget.controleur == null) _proprio = TextEditingController();
    _champ.addListener(_auChangement);
    _dernier = _champ.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final CleBrouillon? cle = widget.lectureSeule == null
        ? widget.cleBrouillon
        : null;
    if (cle != null && !_brouillonsLus) {
      _brouillonsLus = true;
      try {
        _brouillons = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(portBrouillonsProvider);
      } on Object {
        // Aucune memoire de brouillons lisible (pas de session) : le champ
        // fonctionne, rien n'est garde ni remis.
        _brouillons = null;
      }
      if (_brouillons != null) unawaited(_restaurer(cle));
    }
  }

  @override
  void didUpdateWidget(FilDiscussion ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.controleur, widget.controleur)) {
      (ancien.controleur ?? _proprio)?.removeListener(_auChangement);
      if (widget.controleur == null) _proprio ??= TextEditingController();
      _champ.addListener(_auChangement);
      _dernier = _champ.text;
    }
    if (widget.emplacementVocal == null) _vocalOuvert = false;
  }

  @override
  void dispose() {
    // Retirer une ecoute d'un controleur exterieur deja libere est permis.
    _champ.removeListener(_auChangement);
    _proprio?.dispose();
    _defilement.dispose();
    super.dispose();
  }

  /// Remet le brouillon de [cle] dans un champ encore vide.
  Future<void> _restaurer(CleBrouillon cle) async {
    Brouillon? garde;
    try {
      garde = await _brouillons?.lire(cle);
    } on Object {
      garde = null;
    }
    if (!mounted || garde == null || _champ.text.isNotEmpty) return;
    final String texte = garde.texte;
    // Le texte remis est deja garde : l'ecoute ne le reecrit pas.
    _dernier = texte;
    _champ.value = TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
    setState(() => _restaure = true);
  }

  void _auChangement() {
    final String texte = _champ.text;
    final CleBrouillon? cle = widget.cleBrouillon;
    final PortBrouillons? port = _brouillons;
    if (cle != null && port != null && texte != _dernier) {
      _dernier = texte;
      _restaure = false;
      // Un texte vide (apres un envoi, ou tout efface) efface le brouillon.
      unawaited(
        port.enregistrer(cle, texte).catchError((Object _) {
          // Le brouillon n'est pas garde ; le texte reste dans le champ.
        }),
      );
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
    );
    setState(() => _locaux.add(m));
    _champ.clear();
    _tenter(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(true));
  }

  Future<void> _tenter(_MessageLocal m) async {
    setState(() => m.etat = EtatEnvoiMessage.enCours);
    try {
      final Future<void> Function(String, String)? identifie =
          widget.onEnvoyerMessage;
      if (identifie != null) {
        await identifie(m.id, m.texte);
      } else {
        await widget.onEnvoyer!(m.texte);
      }
      if (!mounted) return;
      setState(() => m.etat = EtatEnvoiMessage.envoye);
    } on Object {
      if (!mounted) return;
      setState(() => m.etat = EtatEnvoiMessage.echec);
    }
  }

  bool _surPanneauVocal(PanneauVocalFil avis) {
    if (avis.ouvert != _vocalOuvert) {
      setState(() => _vocalOuvert = avis.ouvert);
    }
    return true;
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
    final Widget? pieceJointe = widget.emplacementPieceJointe;
    final Widget? vocal = widget.emplacementVocal;
    final TextTheme styles = Theme.of(context).textTheme;
    final Widget zoneSaisie = Column(
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
          vide: _vide,
          textes: x,
          onEnvoyer: _envoyer,
          vocalOuvert: vocal != null && _vocalOuvert,
          vocal: vocal == null
              ? null
              : NotificationListener<PanneauVocalFil>(
                  onNotification: _surPanneauVocal,
                  child: vocal,
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
        // En lecture seule, rien ne reste fixe sous la liste : l'en-tete
        // defile toujours avec les messages (R-02, R-07).
        final bool enteteDefilante =
            limite != null ||
            MediaQuery.textScalerOf(context).scale(1) >=
                FilDiscussion.echelleTexteAgrandi ||
            hauteurSansClavier < FilDiscussion.hauteurBasse;
        final List<Widget> elements = <Widget>[
          if (entete != null && enteteDefilante) entete,
          ...bulles,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (entete != null && !enteteDefilante) entete,
            Expanded(
              key: FilDiscussion.cleMessages,
              child: ListView.separated(
                controller: _defilement,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: elements.length,
                separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
                itemBuilder: (BuildContext _, int i) => elements[i],
              ),
            ),
            // La saisie, vocal compris, ne prend jamais plus de 40 % de la
            // hauteur de l'ecran (60 % du fil, clavier ouvert) : au-dela,
            // elle defile elle-meme.
            ConstrainedBox(
              key: FilDiscussion.cleSaisie,
              constraints: BoxConstraints(
                maxHeight: math.min(
                  MediaQuery.sizeOf(context).height *
                      FilDiscussion.partSaisieMax,
                  hauteur.isFinite
                      ? hauteur * FilDiscussion.partSaisieFilMax
                      : double.infinity,
                ),
              ),
              child: SingleChildScrollView(
                child: limite == null
                    ? zoneSaisie
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
          widthFactor: 0.86,
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
    required this.vide,
    required this.textes,
    required this.onEnvoyer,
    this.vocal,
    this.vocalOuvert = false,
  });

  final TextEditingController champ;
  final bool vide;
  final TextesFilDiscussion textes;
  final VoidCallback onEnvoyer;
  final Widget? vocal;

  /// Vrai pendant l'enregistrement et la pre-ecoute : le panneau vocal
  /// remplace la rangee texte (R-04), qui revient ensuite avec son texte.
  final bool vocalOuvert;

  static const Key _cleVocal = ValueKey<String>('fil-discussion-vocal');

  /// En dessous de cette largeur, avec un texte agrandi d'au moins
  /// [_echelleEmpilee], « Envoyer » passe sous le champ : a 390 en texte
  /// double, il prenait la ligne et laissait au champ 86 points de large
  /// (COM-FUS, point COM-MSG-1).
  static const double _largeurEmpilee = 480;
  static const double _echelleEmpilee = 1.5;

  @override
  Widget build(BuildContext context) {
    final Widget? vocal = this.vocal;
    final Widget rangee = LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) => _rangee(
        empilee:
            contraintes.maxWidth < _largeurEmpilee &&
            MediaQuery.textScalerOf(contexte).scale(1) >= _echelleEmpilee,
      ),
    );
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

  Widget _rangee({required bool empilee}) {
    final Widget saisie = raccourciEnvoi(
      onEnvoyer: onEnvoyer,
      child: TextField(
        key: FilDiscussion.champKey,
        controller: champ,
        minLines: 1,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: textes.libelleChamp,
          hintText: textes.aideChamp,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          // La raison du bouton inactif, lisible sous le champ.
          helperText: vide ? textes.champVide : null,
          helperMaxLines: 3,
        ),
      ),
    );
    // Une action se nomme, elle ne s'illustre pas : « Envoyer » en toutes
    // lettres, inerte (et dit comme tel) tant que le champ est vide ; la
    // raison est ecrite sous le champ.
    final Widget envoyer = ActionPrincipale(
      key: FilDiscussion.envoyerKey,
      libelle: textes.envoyer,
      onPress: vide ? null : onEnvoyer,
      pleineLargeur: false,
    );
    if (empilee) {
      // Le meme controleur : le texte reste si la disposition change
      // (rotation, taille du texte).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          saisie,
          Ecart.vSm,
          Align(alignment: AlignmentDirectional.centerEnd, child: envoyer),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: saisie),
        Ecart.hSm,
        envoyer,
      ],
    );
  }
}
