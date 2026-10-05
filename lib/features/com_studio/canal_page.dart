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
// limite, aucun bouton grise.
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

import '../../core/communications/textes_fil_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/carte_piece_jointe.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/fil_discussion.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;
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

/// Le texte d'un message tel qu'il se lit dans le canal : son texte, puis
/// une ligne par piece jointe (« Piece jointe : Planning.pdf ») ou vocal
/// (« Message vocal de 0:42 »). Jamais une reference ni une adresse.
///
/// Sans [avecVocaux], les vocaux ne sont pas dits ; sans [avecDocuments],
/// les autres pieces non plus : la bulle les montre par leur lecteur et
/// leur carte ([piecesDuMessage]).
String texteMessageCanal(
  MessageCommunication m, {
  bool avecVocaux = true,
  bool avecDocuments = true,
}) {
  final c = t.com.studio.canal;
  return <String>[
    if (m.texte.trim().isNotEmpty) m.texte.trim(),
    for (final PieceJointe p in m.piecesJointes)
      if (p.nature != NaturePieceJointe.vocal) ...<String>[
        if (avecDocuments) c.pieceJointe(nom: p.nom),
      ] else if (avecVocaux)
        switch (p.duree) {
          final Duration d => c.vocal(duree: CartePieceJointe.libelleDuree(d)),
          null => c.vocalSansDuree,
        },
  ].join('\n');
}

/// La date et l'heure d'un message, a l'heure de l'appareil.
String horodatageCanal(DateTime instant) {
  final DateTime local = instant.toLocal();
  return t.com.studio.canal.horodatage(
    date: dateDeLAppareil(local),
    heure: heureDeLAppareil(local),
  );
}

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
/// Volontairement court (deux lignes) : il ne defile pas, et le fil doit
/// garder sa place au-dessus du champ, meme a 390 avec un texte double. La
/// description du canal est dans son panneau (« A propos ») ; ses non-lus
/// sont dans la liste, et tombent quand il s'ouvre.
///
/// [minimal] (Mode focus) : le nom et le statut seulement, sans la ligne
/// section et membres.
class EnteteCanal extends StatelessWidget {
  /// Cree l'en-tete du canal [canal].
  const EnteteCanal({required this.canal, super.key, this.minimal = false});

  /// Le canal ouvert.
  final Canal canal;

  /// Vrai en Mode focus : la ligne section et membres s'efface.
  final bool minimal;

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
    final String legende = <String>[
      libelleSection(r.section),
      libelleMembres(canal.membres.length),
    ].join(' · ');
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
        if (!minimal) ...<Widget>[
          Ecart.vXs,
          Text(
            legende,
            key: cleLegende,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
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

  /// La cle de la phrase « lecture seule », pour les tests.
  static const ValueKey<String> cleLectureSeule = ValueKey<String>(
    'studio-canal-lecture-seule',
  );

  /// La cle de la phrase « Brouillon restaure », pour les tests : celle du
  /// fil, qui porte le brouillon (R-22).
  static const Key cleBrouillonRestaure = FilDiscussion.cleBrouillonRestaure;

  /// La cle de l'etat vide d'un canal en lecture seule, pour les tests.
  static const ValueKey<String> cleAucunMessage = ValueKey<String>(
    'studio-canal-aucun-message',
  );

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

  /// Le Focus du Studio qui entoure le canal ; nul hors d'un Studio.
  EtatFocusStudio? _focus;

  /// La position de lecture du fil, gardee pendant le Focus.
  late final SourceDefilement _sourceDefilement = SourceDefilement(
    () => _defilementDesMessages()?.position,
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
      _focus = focus;
      focus?.restaurateur
        ?..inscrire(cleSourceDefilement, _sourceDefilement)
        ..inscrire(cleSourceChamp, _sourceChamp);
    }
  }

  @override
  void dispose() {
    _retirerSources();
    WidgetsBinding.instance.removeObserver(this);
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
      final ScrollPosition? position = _defilementDesMessages()?.position;
      if (!mounted || position == null || !position.hasContentDimensions) {
        return;
      }
      position.jumpTo(
        (position.pixels + ecart).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  /// La premiere zone defilante du canal : la liste des messages (l'en-tete
  /// ne defile pas, le champ vient apres elle).
  ScrollableState? _defilementDesMessages() {
    if (!mounted) return null;
    ScrollableState? trouve;
    void visiter(Element e) {
      if (trouve != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        trouve = e.state as ScrollableState;
        return;
      }
      e.visitChildren(visiter);
    }

    (context as Element).visitChildren(visiter);
    return trouve;
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

  @override
  Widget build(BuildContext context) {
    final Canal canal = widget.canal;
    final bool focus = _focus?.actif ?? false;
    if (!canal.peut(CapaciteCanal.ecrire)) {
      return _CanalEnLecture(
        canal: canal,
        entete: _entete(canal, focus: focus),
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
    final TextesFilDiscussion textes = textesCanal(canal.resume);
    // Le texte du champ est garde comme brouillon par le fil (memoire de
    // session, spec section 8.2) et remis a la reouverture du canal
    // (COM-STU-2, R-22).
    return FilDiscussion(
      key: ValueKey<String>('studio-fil-${canal.id}'),
      entete: _entete(canal, focus: focus),
      controleur: _champ,
      cleBrouillon: cleBrouillonCanal(canal.id),
      messages: <MessageFil>[
        for (final MessageCommunication m in canal.messages)
          MessageFil(
            id: m.id,
            auteur: m.deSoi ? soi : m.auteur.nomAffiche,
            texte: texteMessageCanal(
              m,
              avecVocaux: false,
              avecDocuments: false,
            ),
            annonceTexte: texteMessageCanal(m),
            complement: piecesDuMessage(m.piecesJointes),
            horodatage: horodatageCanal(m.envoyeLe),
            deSoi: m.deSoi,
          ),
        for (final VocalConfirme v in _vocauxConfirmes)
          bulleVocalConfirme(
            v,
            auteurSoi: soi,
            ligneVocal: (Duration d) => t.com.studio.canal.vocal(
              duree: CartePieceJointe.libelleDuree(d),
            ),
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

/// Un canal en lecture seule : les messages en une surface a filets, puis la
/// phrase qui dit la limite. Aucun champ, aucun bouton.
class _CanalEnLecture extends StatelessWidget {
  const _CanalEnLecture({required this.canal, required this.entete});

  final Canal canal;
  final Widget entete;

  @override
  Widget build(BuildContext context) {
    final c = t.com.studio.canal;
    final String soi = t.com.socle.composants.composer.auteurSoi;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              // R-02 : sans champ, l'en-tete defile avec les messages, ses
              // actions (retour, contexte) dans sa rangee.
              RangeeEnteteEspace(child: entete),
              // Aucun message : l'etat vide le dit, jamais une zone blanche.
              if (canal.messages.isEmpty)
                VueEtatCommunication(
                  key: CanalStudio.cleAucunMessage,
                  etat: EtatCommunication.vide,
                  titreVide: c.aucunMessageTitre,
                  phraseVide: c.aucunMessage,
                )
              else
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    for (final MessageCommunication m in canal.messages)
                      LigneRubrique(
                        meneur: AvatarTile(
                          prenom: m.auteur.nomAffiche,
                          diametre: AppAvatar.petit,
                        ),
                        libelle: texteMessageCanal(m),
                        legende: c.auteurEtMoment(
                          auteur: m.deSoi ? soi : m.auteur.nomAffiche,
                          moment: horodatageCanal(m.envoyeLe),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            c.lectureSeule,
            key: CanalStudio.cleLectureSeule,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
