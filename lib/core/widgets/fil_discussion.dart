// Un fil de discussion generique : messages, champ de saisie, envoi honnete
// (CT-6, premier composant de fil du depot, prouve absent dans
// `14_controleur/CONTROLEUR_EXISTING_MAPPING.md`).
//
// Aucune logique de role ici : les textes, les messages et l'envoi viennent
// de l'ecran appelant. Le composant ne promet rien qu'il ne tient : un
// message ecrit reste « en cours » tant que l'envoi n'a pas repondu, passe a
// « envoye » sur reponse, et a « echec » avec « Reessayer » sinon, sa saisie
// gardee (jamais de faux succes).

import 'package:flutter/material.dart';

import '../mouvement/apparition_douce.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'page_shell.dart' show ColonneCorps;
import 'zone_saisie.dart';

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
  /// Cree le fil.
  const FilDiscussion({
    required this.messages,
    required this.textes,
    required this.onEnvoyer,
    super.key,
  });

  /// Les messages connus, du plus ancien au plus recent.
  final List<MessageFil> messages;

  /// Les textes du fil.
  final TextesFilDiscussion textes;

  /// L'envoi d'un texte : le futur se termine sur la reponse, et echoue si
  /// le message n'est pas parti.
  final Future<void> Function(String texte) onEnvoyer;

  /// Le champ de saisie, pour les tests.
  static const Key champKey = ValueKey<String>('fil-discussion-champ');

  /// Le bouton d'envoi, pour les tests.
  static const Key envoyerKey = ValueKey<String>('fil-discussion-envoyer');

  /// La hauteur sous laquelle la liste des messages n'est plus lisible : une
  /// bulle entiere, a l'echelle de texte de [context] (SUPERPOS-1). La bulle
  /// comptee est celle d'un message de deux lignes : son auteur, son texte,
  /// son pied, ses marges, et la respiration sous la liste. Un minimum fixe
  /// (96) ne laissait voir a 320 en texte double qu'une tranche de bulle
  /// (une bulle y mesure environ 200).
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

  @override
  State<FilDiscussion> createState() => _FilDiscussionState();
}

class _FilDiscussionState extends State<FilDiscussion> {
  final TextEditingController _champ = TextEditingController();
  final ScrollController _defilement = ScrollController();
  final List<_MessageLocal> _locaux = <_MessageLocal>[];
  late final Set<String> _presentsALOuverture = <String>{
    for (final MessageFil m in widget.messages) m.id,
  };
  int _compteur = 0;

  /// La zone de saisie, pour la ramener a l'ecran a l'arrivee.
  final GlobalKey _cleSaisie = GlobalKey();

  @override
  void initState() {
    super.initState();
    _champ.addListener(_auChangement);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allerEnBas(false);
      _montrerSaisie();
    });
  }

  /// SUPERPOS-1 : quand la page entiere defile (texte double, vue basse),
  /// l'arrivee dans le fil montre la saisie et le dernier message, l'en-tete
  /// passant au-dessus, comme dans toute messagerie. Sans effet quand tout
  /// tient deja dans l'ecran.
  void _montrerSaisie() {
    final BuildContext? saisie = _cleSaisie.currentContext;
    if (!mounted || saisie == null) return;
    Scrollable.ensureVisible(
      saisie,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
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
      'local-${_compteur++}',
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
      await widget.onEnvoyer(m.texte);
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
          annonce: _presentsALOuverture.contains(m.id)
              ? null
              : x.annonce(m.auteur, m.texte),
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
    // SUPERPOS-1 : une colonne de corps qui dit a `PageShell` la hauteur qui
    // lui manque (clavier ouvert, texte double) : la page defile au lieu de
    // couper la saisie, et la liste garde au moins une bulle entiere.
    return ColonneCorps(
      minimumEtire: FilDiscussion.minimumListe(context),
      children: <Widget>[
        Expanded(
          child: ListView.separated(
            controller: _defilement,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: bulles.length,
            separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
            itemBuilder: (BuildContext _, int i) => bulles[i],
          ),
        ),
        _Saisie(
          key: _cleSaisie,
          champ: _champ,
          vide: _vide,
          textes: x,
          onEnvoyer: _envoyer,
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
          Ecart.vXs,
          Text(
            texte,
            style: fond.applyTo(textes.bodyLarge ?? const TextStyle()),
          ),
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
    super.key,
    required this.vide,
    required this.textes,
    required this.onEnvoyer,
  });

  final TextEditingController champ;
  final bool vide;
  final TextesFilDiscussion textes;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    // SUPERPOS-1 : la zone de saisie partagee du core. L'envoi est une icone
    // nommee DANS le champ, centree en hauteur ; tant que le champ est vide,
    // elle n'est pas rendue (jamais grisee) et la raison est ecrite sous le
    // champ. Le champ prend toute la largeur : a 320 en texte double, il
    // ne cede plus la moitie de la ligne a un bouton a cote.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ZoneSaisie(
        cleChamp: FilDiscussion.champKey,
        controleur: champ,
        libelle: textes.libelleChamp,
        aide: textes.aideChamp,
        explication: vide ? textes.champVide : null,
        maxLignes: 5,
        envoi: EnvoiZoneSaisie(
          cle: FilDiscussion.envoyerKey,
          libelle: textes.envoyer,
          onEnvoyer: onEnvoyer,
        ),
      ),
    );
  }
}
