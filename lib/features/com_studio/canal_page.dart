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
// Une piece jointe ou un vocal recu se dit dans la bulle par son nom ou sa
// duree ; le fichier lui-meme est dans le panneau du canal (« Fichiers
// recents »). La lecture du vocal (COM-VOC), la bulle a piece jointe et les
// reactions secondaires se branchent a COM-FUS : `FilDiscussion` (socle) ne
// porte encore que du texte.
//
// Un canal ou la personne ne peut pas ecrire (capacite `ecrire` absente du
// canal rendu, COM-BR-16) se lit sans champ ni bouton : une phrase dit la
// limite, aucun bouton grise.

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/communications/carte_piece_jointe.dart';
import '../../core/widgets/communications/composer_texte.dart';
import '../../core/widgets/communications/etats_communication.dart';
import '../../core/widgets/fil_discussion.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;
import 'liste_canaux.dart';
import 'panneau_partages.dart' show libelleMembres;
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// Le texte d'un message tel qu'il se lit dans le canal : son texte, puis
/// une ligne par piece jointe (« Piece jointe : Planning.pdf ») ou vocal
/// (« Message vocal de 0:42 »). Jamais une reference ni une adresse.
String texteMessageCanal(MessageCommunication m) {
  final c = t.com.studio.canal;
  return <String>[
    if (m.texte.trim().isNotEmpty) m.texte.trim(),
    for (final PieceJointe p in m.piecesJointes)
      if (p.nature == NaturePieceJointe.vocal)
        switch (p.duree) {
          final Duration d => c.vocal(duree: CartePieceJointe.libelleDuree(d)),
          null => c.vocalSansDuree,
        }
      else
        c.pieceJointe(nom: p.nom),
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
  );
}

/// L'en-tete d'un canal : son nom, son statut s'il est restreint ou prive,
/// sa section et son nombre de membres.
///
/// Volontairement court (deux lignes) : il ne defile pas, et le fil doit
/// garder sa place au-dessus du champ, meme a 390 avec un texte double. La
/// description du canal est dans son panneau (« A propos ») ; ses non-lus
/// sont dans la liste, et tombent quand il s'ouvre.
class EnteteCanal extends StatelessWidget {
  /// Cree l'en-tete du canal [canal].
  const EnteteCanal({required this.canal, super.key});

  /// Le canal ouvert.
  final Canal canal;

  /// La cle de l'en-tete, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('studio-entete-canal');

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
        Ecart.vXs,
        Text(
          legende,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Un canal ouvert : en-tete, messages, champ et envoi honnete.
class CanalStudio extends StatefulWidget {
  /// Cree le canal.
  const CanalStudio({required this.canal, required this.onEnvoyer, super.key});

  /// Le canal ouvert.
  final Canal canal;

  /// L'envoi d'un texte avec sa cle d'idempotence (COM-BR-02) : le futur se
  /// termine sur l'accuse du serveur, et echoue sinon.
  final Future<void> Function(String texte, String cleIdempotence) onEnvoyer;

  /// La cle de la phrase « lecture seule », pour les tests.
  static const ValueKey<String> cleLectureSeule = ValueKey<String>(
    'studio-canal-lecture-seule',
  );

  /// La cle de l'etat vide d'un canal en lecture seule, pour les tests.
  static const ValueKey<String> cleAucunMessage = ValueKey<String>(
    'studio-canal-aucun-message',
  );

  @override
  State<CanalStudio> createState() => _CanalStudioState();
}

class _CanalStudioState extends State<CanalStudio> with WidgetsBindingObserver {
  /// Les cles LIBRES des envois non confirmes, par texte : une cle part
  /// avec un essai, revient ici si l'essai echoue, et disparait avec la
  /// confirmation. Un nouvel essai (« Reessayer ») reprend une cle libre :
  /// le serveur ne compte pas deux fois le meme message (COM-BR-02).
  ///
  /// `FilDiscussion` (socle) ne transmet que le texte, pas l'identite de la
  /// bulle (ligne COM-FUS). Une cle n'est donc jamais attachee a un texte
  /// seul : deux envois simultanes du meme texte prennent deux cles
  /// distinctes, et une cle n'est reprise qu'apres l'echec de son essai.
  /// Ainsi, a tout instant, chaque bulle en attente a SA cle, et deux bulles
  /// au meme texte ne peuvent jamais etre comptees comme un seul message.
  final Map<String, List<String>> _clesLibres = <String, List<String>>{};
  int _compteur = 0;

  /// La hauteur du clavier logiciel au dernier releve, en points logiques.
  double _clavier = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clavier = _hauteurClavier();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  Future<void> _envoyer(String texte) async {
    final List<String>? libres = _clesLibres[texte];
    final String cle = libres != null && libres.isNotEmpty
        ? libres.removeLast()
        : '${widget.canal.id}-${DateTime.now().microsecondsSinceEpoch}-'
              '${_compteur++}';
    if (libres != null && libres.isEmpty) _clesLibres.remove(texte);
    try {
      await widget.onEnvoyer(texte, cle);
    } on Object {
      // Non confirme : la cle redevient libre pour le nouvel essai.
      (_clesLibres[texte] ??= <String>[]).add(cle);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Canal canal = widget.canal;
    final Widget entete = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: EnteteCanal(canal: canal),
    );
    if (!canal.peut(CapaciteCanal.ecrire)) {
      return _CanalEnLecture(canal: canal, entete: entete);
    }
    final String soi = t.com.socle.composants.composer.auteurSoi;
    return FilDiscussion(
      key: ValueKey<String>('studio-fil-${canal.id}'),
      entete: entete,
      messages: <MessageFil>[
        for (final MessageCommunication m in canal.messages)
          MessageFil(
            id: m.id,
            auteur: m.deSoi ? soi : m.auteur.nomAffiche,
            texte: texteMessageCanal(m),
            horodatage: horodatageCanal(m.envoyeLe),
            deSoi: m.deSoi,
          ),
      ],
      textes: textesCanal(canal.resume),
      onEnvoyer: _envoyer,
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
        entete,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
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
