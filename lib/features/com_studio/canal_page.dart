// Un canal du Studio (COM-M03, COM-W03 ; spec section 9, section 23,
// R-COM-13, R-COM-15).
//
// Il n'y a PAS de second fil : c'est `FilDiscussion` (CT-6), celui des
// Echanges du controleur et des Messages metier, avec l'emplacement
// d'en-tete pose par le socle (COM-F) et les textes des communications
// (`textesFilCommunication`) : « Envoye » seulement sur accuse du serveur,
// « Ce message n'a pas encore ete confirme » et « Reessayer » sinon, le
// texte garde (R-COM-13). Chaque message ecrit part avec une cle
// d'idempotence, rejouee telle quelle au nouvel essai (COM-BR-02). Le champ
// reste au-dessus du clavier logiciel et la lecture garde le dernier message
// visible (R-COM-15).
//
// Une piece jointe se montre dans la bulle par sa carte (`CartePieceJointe`,
// COM-RC, R-11) ; le fichier est aussi dans le panneau du canal (« Fichiers
// recents »). Un vocal recu se lit
// dans la bulle, par le lecteur de COM-VOC (`LecteurVocalRecu`, COM-FUS).
// Les reactions secondaires (COM-BR-08) ne sont pas encore rendues.
//
// Le composer vocal (COM-VOC) se pose sous le champ, hors Focus comme en
// Focus (`ComposerMinimal`), seulement si la page donne
// [CanalStudio.onEnvoyerVocal] : elle ne le fait que si la capacite
// `envoyerVocal` est ouverte (COM-BR-16), donc jamais en production tant que
// le port des capacites est neutre. Aucun envoi automatique.
//
// Le texte du champ est garde comme brouillon le temps de la session et
// remis a la reouverture du canal, avec la phrase « Brouillon restaure »
// (COM-STU-2, spec section 8.2) : `FilDiscussion` porte seul cette
// persistance, sous la cle du canal (`cleBrouillonCanal`, COM-RC, R-22). Le
// canal tient le controleur du champ, qu'il donne au fil et au restaurateur
// du Focus : aucun parcours de l'arbre pour le retrouver.
//
// Un canal ou la personne ne peut pas ecrire (capacite `ecrire` absente du
// canal rendu, COM-BR-16) se lit sans champ ni bouton : une phrase dit la
// limite, aucun bouton grise. C'est le mode lecture seule de
// `FilDiscussion` (memes bulles, meme etat vide que les Messages metier), et
// le texte et la date d'un message viennent de l'adaptateur unique du socle
// (`lecture_fil_communication.dart`, revue COM-R, R-07).
//
// Mode focus (COM-STU-3, spec section 10) : « Mode focus » est dans
// l'en-tete du canal (`BasculeFocus`). En Focus, l'en-tete ne garde que le
// nom du canal et son statut (sa section et son nombre de membres, compteurs
// non essentiels, s'effacent) ; le fil et son champ restent les MEMES (meme
// controleur, meme brouillon, memes envois en attente), selon la regle du
// champ minimal (`ComposerMinimal`). Le canal inscrit sa position de lecture
// et son champ aupres du restaurateur du Focus (`FocusStateRestorer`).

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import '../../core/communications/lecture_fil_communication.dart';
import '../../core/communications/textes_fil_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/fil_discussion.dart';
import '../com_vocal/composer_vocal.dart';
import '../com_vocal/envoi_vocal.dart';
import '../com_vocal/lecteur_vocal.dart';
import '../com_vocal/port_enregistreur_vocal.dart';
import 'brouillons_studio.dart';
import 'focus/bascule_focus.dart';
import 'focus/composer_minimal.dart';
import 'focus/restauration_focus.dart';
import 'liste_canaux.dart';
import 'panneau_partages.dart' show libelleMembres;
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// Les textes du fil d'un canal : ceux des communications, avec l'aide du
/// champ qui nomme le canal (« Ecrire dans Organisation »).
TextesFilDiscussion textesCanal(ResumeCanal canal) {
  final TextesFilDiscussion base = textesFilCommunication();
  return TextesFilDiscussion(
    aideChamp: t.com.studio.canal.aide(nom: canal.nom),
    libelleChamp: base.libelleChamp,
    envoyer: base.envoyer,
    champVide: base.champVide,
    enCours: base.enCours,
    envoye: base.envoye,
    echec: base.echec,
    reessayer: base.reessayer,
    auteurSoi: base.auteurSoi,
    annonce: base.annonce,
    aucunMessageTitre: t.com.studio.canal.aucunMessageTitre,
    aucunMessage: t.com.studio.canal.aucunMessage,
    brouillonRestaure: t.com.studio.brouillons.restaure,
  );
}

/// L'en-tete d'un canal : son nom, son statut s'il est restreint ou prive,
/// sa section et son nombre de membres.
///
/// Volontairement court (deux lignes) : en taille normale il reste fixe
/// au-dessus du fil, qui doit garder sa place au-dessus du champ ; a texte
/// agrandi ou sur une vue basse, il defile avec les messages (R-02). La
/// description du canal est dans son panneau (« A propos ») ; ses non-lus
/// sont dans la liste, et tombent quand il s'ouvre.
///
/// [minimal] (Mode focus) : le nom et le statut seulement, sans la ligne
/// section et membres.
///
/// [compacte] (COM-RC tour 4, N-1) : le nom seul, sur une ligne, fixe
/// au-dessus du fil quand le reste de l'en-tete defile (texte agrandi, vue
/// basse) ; le statut et la ligne section et membres defilent dessous.
class EnteteCanal extends StatelessWidget {
  /// Cree l'en-tete du canal [canal].
  const EnteteCanal({
    required this.canal,
    super.key,
    this.minimal = false,
    this.compacte = false,
  });

  /// Le canal ouvert.
  final Canal canal;

  /// Vrai en Mode focus : la ligne section et membres s'efface.
  final bool minimal;

  /// Vrai pour la ligne compacte : le nom seul, sur une ligne.
  final bool compacte;

  /// La cle de l'en-tete, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('studio-entete-canal');

  /// La cle de la ligne section et membres, pour les tests.
  static const ValueKey<String> cleLegende = ValueKey<String>(
    'studio-entete-canal-legende',
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ResumeCanal r = canal.resume;
    if (compacte) {
      return Semantics(
        key: cle,
        header: true,
        child: Text(
          r.nom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
      );
    }
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                r.nom,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            MarqueVisibiliteCanal(visibilite: r.visibilite),
          ],
        ),
        if (!minimal) ...<Widget>[Ecart.vXs, LegendeCanal(canal: canal)],
      ],
    );
  }
}

/// La ligne section et membres d'un canal : sous son nom dans l'en-tete,
/// ou, quand l'en-tete defile (texte agrandi, vue basse), sous la ligne
/// compacte fixe, avec les messages (COM-RC tour 4, N-1).
class LegendeCanal extends StatelessWidget {
  /// Cree la ligne du canal [canal].
  const LegendeCanal({required this.canal, super.key});

  /// Le canal ouvert.
  final Canal canal;

  @override
  Widget build(BuildContext context) {
    final String legende = <String>[
      libelleSection(canal.resume.section),
      libelleMembres(canal.membres.length),
    ].join(' · ');
    return Text(
      legende,
      key: EnteteCanal.cleLegende,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle()),
    );
  }
}

/// Un canal ouvert : en-tete, messages, champ et envoi honnete.
class CanalStudio extends StatefulWidget {
  /// Cree le canal.
  const CanalStudio({
    required this.canal,
    required this.onEnvoyer,
    super.key,
    this.onEnvoyerVocal,
  });

  /// Le canal ouvert.
  final Canal canal;

  /// L'envoi d'un texte avec sa cle d'idempotence (COM-BR-02) : le futur se
  /// termine sur l'accuse du serveur, et echoue sinon.
  final Future<void> Function(String texte, String cleIdempotence) onEnvoyer;

  /// L'envoi d'un vocal avec sa cle d'idempotence (COM-BR-03, COM-BR-02), ou
  /// `null` : aucun composer vocal n'est rendu (capacite `envoyerVocal`
  /// fermee, production).
  final Future<void> Function(EnregistrementVocal vocal, String cleIdempotence)?
  onEnvoyerVocal;

  /// La cle du composer vocal du canal, pour les tests.
  static const ValueKey<String> cleComposerVocal = ValueKey<String>(
    'studio-canal-composer-vocal',
  );

  /// La cle de la phrase « lecture seule », pour les tests : celle du fil
  /// (R-07).
  static const Key cleLectureSeule = FilDiscussion.cleLectureSeule;

  /// La cle de la phrase « Brouillon restaure », pour les tests : celle du
  /// fil, qui porte le brouillon (R-22).
  static const Key cleBrouillonRestaure = FilDiscussion.cleBrouillonRestaure;

  /// La cle de l'etat vide du canal, pour les tests : celle du fil (R-07).
  static const Key cleAucunMessage = FilDiscussion.cleAucunMessage;

  @override
  State<CanalStudio> createState() => _CanalStudioState();
}

class _CanalStudioState extends State<CanalStudio> with WidgetsBindingObserver {
  /// Les cles d'idempotence, par identifiant local de bulle
  /// (`FilDiscussion.onEnvoyerMessage`, COM-FUS) : chaque bulle a SA cle,
  /// rejouee a son « Reessayer » ; le serveur ne compte pas deux fois le
  /// meme message (COM-BR-02). Deux bulles au meme texte ont deux cles. La
  /// cle est oubliee a l'accuse.
  final Map<String, String> _cles = <String, String>{};
  int _compteur = 0;

  /// Les cles des vocaux de ce canal, une par vocal (COM-BR-02).
  late final ClesVocales _clesVocales = ClesVocales(
    DestinationVocal.canal(widget.canal.id),
  );

  /// Les vocaux confirmes depuis l'ouverture du canal (COM-FUS, revue) : la
  /// page ne relit que la liste apres un envoi, le canal ouvert les montre
  /// donc lui-meme, apres les messages connus.
  final List<VocalConfirme> _vocauxConfirmes = <VocalConfirme>[];

  /// La hauteur du clavier logiciel au dernier releve, en points logiques.
  double _clavier = 0;

  /// La liste des messages du canal, donnee a `FilDiscussion` : la lecture
  /// suit le clavier (R-COM-15) et le Focus garde sa position. Elle porte
  /// aussi l'en-tete du canal et, a texte agrandi, la tete de la page
  /// (R-02) : c'est la meme position.
  final ScrollController _defilement = ScrollController();

  /// Le Focus du Studio qui entoure le canal ; nul hors d'un Studio.
  EtatFocusStudio? _focus;

  /// Le Focus etait-il actif au dernier changement lu ?
  bool _focusActif = false;

  /// Les entrees dans le Focus : a chacune, le fil ramene sa saisie a
  /// l'ecran quand elle defile avec les messages (N-4, section 23 :
  /// contenu, champ et sortie).
  int _entreesFocus = 0;

  /// La position de lecture du fil, gardee pendant le Focus.
  late final SourceDefilement _sourceDefilement = SourceDefilement(
    () => _defilement.hasClients ? _defilement.position : null,
  );

  /// Le controleur du champ du fil, tenu par le canal (R-22) : le fil
  /// l'emploie, le restaurateur du Focus le garde.
  final TextEditingController _champ = TextEditingController();

  /// Le champ du fil (brouillon et selection), garde pendant le Focus.
  late final SourceChamp _sourceChamp = SourceChamp(_champDuFil);

  /// Les cles des sources du canal aupres du restaurateur du Focus.
  static const String cleSourceDefilement = 'canal-defilement';

  /// La cle de la source « champ » du canal.
  static const String cleSourceChamp = 'canal-champ';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clavier = _hauteurClavier();
    final EtatFocusStudio? focus = PorteeFocusStudio.de(context);
    if (!identical(focus, _focus)) {
      _retirerSources();
      _focus?.removeListener(_surFocus);
      _focus = focus;
      focus?.addListener(_surFocus);
      focus?.restaurateur
        ?..inscrire(cleSourceDefilement, _sourceDefilement)
        ..inscrire(cleSourceChamp, _sourceChamp);
      _focusActif = focus?.actif ?? false;
    }
  }

  /// COM-R-3, constat 6 : une entree dans le Focus se compte ici, au
  /// changement d'`EtatFocusStudio`, jamais pendant la construction.
  void _surFocus() {
    final bool actif = _focus?.actif ?? false;
    if (actif == _focusActif) return;
    _focusActif = actif;
    if (actif && mounted) setState(() => _entreesFocus++);
  }

  @override
  void dispose() {
    _retirerSources();
    _focus?.removeListener(_surFocus);
    WidgetsBinding.instance.removeObserver(this);
    _defilement.dispose();
    _champ.dispose();
    super.dispose();
  }

  void _retirerSources() {
    _focus?.restaurateur
      ?..retirer(cleSourceDefilement, _sourceDefilement)
      ..retirer(cleSourceChamp, _sourceChamp);
  }

  /// Le controleur du champ du fil ; nul sans champ (canal en lecture
  /// seule) ou hors de l'arbre.
  TextEditingController? _champDuFil() =>
      mounted && widget.canal.peut(CapaciteCanal.ecrire) ? _champ : null;

  double _hauteurClavier() {
    final FlutterView vue = View.of(context);
    return vue.viewInsets.bottom / vue.devicePixelRatio;
  }

  /// R-COM-15 : quand le clavier logiciel s'ouvre, la zone des messages
  /// raccourcit par le bas ; la lecture glisse d'autant pour que le dernier
  /// message reste au-dessus du champ. Quand il se ferme, elle revient.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final double nouveau = _hauteurClavier();
    final double ecart = nouveau - _clavier;
    _clavier = nouveau;
    if (ecart == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_defilement.hasClients) return;
      final ScrollPosition position = _defilement.position;
      if (!position.hasContentDimensions) return;
      position.jumpTo(
        (position.pixels + ecart).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  Future<void> _envoyer(String idLocal, String texte) async {
    final String cle = _cles.putIfAbsent(
      idLocal,
      () =>
          '${widget.canal.id}-${DateTime.now().microsecondsSinceEpoch}-'
          '${_compteur++}',
    );
    await widget.onEnvoyer(texte, cle);
    _cles.remove(idLocal);
  }

  /// Envoie [vocal] par [envoi] sous sa cle ; a l'accuse, sa bulle entre
  /// dans le canal. Un echec remonte au composer (« Reessayer »), sans bulle.
  Future<void> _envoyerVocal(
    EnregistrementVocal vocal,
    Future<void> Function(EnregistrementVocal, String) envoi,
  ) async {
    final String cle = await _clesVocales.envoyer(
      vocal,
      (String cle) => envoi(vocal, cle),
    );
    if (!mounted) return;
    setState(() => _vocauxConfirmes.add((cle: cle, duree: vocal.duree)));
  }

  /// L'en-tete du canal. Hors Focus, « Mode focus » au bout de la ligne ;
  /// en Focus, l'en-tete minimal (la sortie est dans le bandeau du Focus).
  /// La phrase « Brouillon restaure » est posee par le fil, sur son champ.
  Widget _entete(Canal canal, {required bool focus}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    // « Mode focus » au bout de la ligne s'il y tient, sinon dessous (a 390
    // en texte double, le nom garde toute la largeur).
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        EnteteCanal(canal: canal, minimal: focus),
        if (!focus && _focus != null) const BasculeFocus(),
      ],
    ),
  );

  /// Ce qui, de l'en-tete, defile sous la ligne compacte (N-1) : le statut
  /// du canal ; hors Focus, la ligne section et membres et « Mode focus ».
  Widget _suiteEntete(Canal canal, {required bool focus}) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      MarqueVisibiliteCanal(visibilite: canal.resume.visibilite),
      if (!focus) LegendeCanal(canal: canal),
      if (!focus && _focus != null) const BasculeFocus(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final Canal canal = widget.canal;
    final bool focus = _focus?.actif ?? false;
    // N-1 (COM-RC tour 4) : quand l'en-tete defile (texte agrandi, vue
    // basse), le nom du canal reste fixe au-dessus du fil ; son statut, sa
    // ligne section et membres et « Mode focus » defilent dessous.
    final Widget compacte = EnteteCanal(canal: canal, compacte: true);
    final Widget suite = _suiteEntete(canal, focus: focus);
    final List<MessageFil> connus = <MessageFil>[
      for (final MessageCommunication m in canal.messages)
        messageFilDe(m, complement: piecesDuMessage(m.piecesJointes)),
    ];
    final TextesFilDiscussion textes = textesCanal(canal.resume);
    if (!canal.peut(CapaciteCanal.ecrire)) {
      // Lecture seule : le meme fil, sans champ ; la phrase dit la limite.
      return FilDiscussion(
        defilement: _defilement,
        key: ValueKey<String>('studio-fil-lecture-${canal.id}'),
        entete: _entete(canal, focus: focus),
        enteteCompacte: compacte,
        enteteSuite: suite,
        messages: connus,
        textes: textes,
        lectureSeule: t.com.studio.canal.lectureSeule,
      );
    }
    // Le champ minimal du Focus : le vocal reste en Focus (section 10.4) ;
    // le canal ne pose pas encore de piece jointe (aucun contrat d'envoi,
    // COM-BR-04).
    final Future<void> Function(EnregistrementVocal, String)? vocal =
        widget.onEnvoyerVocal;
    final ComposerMinimal composer = ComposerMinimal(
      vocal: vocal == null
          ? null
          : ComposerVocal(
              key: CanalStudio.cleComposerVocal,
              onEnvoyer: (EnregistrementVocal v) => _envoyerVocal(v, vocal),
            ),
    );
    final String soi = t.com.socle.composants.composer.auteurSoi;
    // Le texte du champ est garde comme brouillon par le fil (memoire de
    // session, spec section 8.2) et remis a la reouverture du canal
    // (COM-STU-2, R-22).
    return FilDiscussion(
      defilement: _defilement,
      key: ValueKey<String>('studio-fil-${canal.id}'),
      entete: _entete(canal, focus: focus),
      enteteCompacte: compacte,
      enteteSuite: suite,
      demandeSaisieVisible: _entreesFocus,
      // Decision du directeur (Focus a 320, texte x2) : la saisie se reduit
      // a une ligne, une bulle au moins reste a l'ecran.
      saisieReduite: focus,
      controleur: _champ,
      cleBrouillon: cleBrouillonCanal(canal.id),
      messages: <MessageFil>[
        ...connus,
        for (final VocalConfirme v in _vocauxConfirmes)
          bulleVocalConfirme(
            v,
            auteurSoi: soi,
            ligneVocal: ligneVocal,
            envoye: textes.envoye,
          ),
      ],
      textes: textes,
      onEnvoyerMessage: _envoyer,
      emplacementPieceJointe: composer.emplacementPieceJointe(focus: focus),
      emplacementVocal: composer.emplacementVocal(focus: focus),
    );
  }
}
