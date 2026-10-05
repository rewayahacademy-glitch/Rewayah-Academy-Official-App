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

import 'package:flutter/material.dart';

import '../mouvement/apparition_douce.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';

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

/// Le fil : la liste des messages, puis le champ et le bouton d'envoi.
///
/// A poser dans une zone de hauteur bornee (`PageShell(defilante: false)`) :
/// la liste defile, le champ reste visible au-dessus du clavier (W-2411).
/// Entree fait un retour a la ligne, seul le bouton envoie (UX_REVIEW_08
/// ligne 12 e). Un message arrive ou ecrit apres l'ouverture est annonce une
/// fois (region live polie) ; ceux presents a l'ouverture ne le sont pas.
class FilDiscussion extends StatefulWidget {
  /// Cree le fil, avec [onEnvoyer] ou [onEnvoyerMessage].
  const FilDiscussion({
    required this.messages,
    required this.textes,
    super.key,
    this.onEnvoyer,
    this.onEnvoyerMessage,
    this.entete,
    this.emplacementPieceJointe,
    this.emplacementVocal,
  }) : assert(
         onEnvoyer != null || onEnvoyerMessage != null,
         'FilDiscussion demande onEnvoyer ou onEnvoyerMessage.',
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

  final TextEditingController _champ = TextEditingController();
  final ScrollController _defilement = ScrollController();
  final List<_MessageLocal> _locaux = <_MessageLocal>[];
  late final Set<String> _presentsALOuverture = <String>{
    for (final MessageFil m in widget.messages) m.id,
  };
  @override
  void initState() {
    super.initState();
    _champ.addListener(_auChangement);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allerEnBas(false));
  }

  @override
  void dispose() {
    _champ
      ..removeListener(_auChangement)
      ..dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _auChangement() => setState(() {});

  bool get _vide => _champ.text.trim().isEmpty;

  void _allerEnBas(bool anime) {
    if (!mounted || !_defilement.hasClients) return;
    final double fin = _defilement.position.maxScrollExtent;
    final Duration duree = Mouvement.duree(context, Mouvement.moyen);
    if (anime && duree > Duration.zero) {
      _defilement.animateTo(fin, duration: duree, curve: Mouvement.entree);
    } else {
      _defilement.jumpTo(fin);
    }
  }

  void _envoyer() {
    if (_vide) return;
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
    final Widget? entete = widget.entete;
    final Widget? pieceJointe = widget.emplacementPieceJointe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?entete,
        Expanded(
          child: ListView.separated(
            controller: _defilement,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: bulles.length,
            separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
            itemBuilder: (BuildContext _, int i) => bulles[i],
          ),
        ),
        if (pieceJointe != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: pieceJointe,
          ),
        _Saisie(
          champ: _champ,
          vide: _vide,
          textes: x,
          onEnvoyer: _envoyer,
          vocal: widget.emplacementVocal,
        ),
      ],
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
  });

  final TextEditingController champ;
  final bool vide;
  final TextesFilDiscussion textes;
  final VoidCallback onEnvoyer;
  final Widget? vocal;

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
                rangee,
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: vocal,
                ),
              ],
            ),
    );
  }

  Widget _rangee({required bool empilee}) {
    final Widget saisie = TextField(
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
