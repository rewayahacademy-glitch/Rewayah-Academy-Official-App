// Le fil contextuel des Messages metier (COM-M01, COM-W01 ; spec section 3,
// R-COM-01, R-COM-13, R-COM-15).
//
// Il n'y a PAS de second fil : c'est `FilDiscussion` (CT-6), celui des
// Echanges du controleur, avec l'emplacement d'en-tete pose par le socle
// (COM-F) et les textes des communications (`textesFilCommunication`) :
// « Envoye » seulement sur accuse du serveur, « Ce message n'a pas encore
// ete confirme » et « Reessayer » sinon, le texte garde (R-COM-13). Le champ
// reste au-dessus du clavier logiciel et la liste garde le dernier message
// visible (R-COM-15).
//
// Une piece jointe ou un vocal recu se dit dans la bulle par son nom ou sa
// duree ; la carte de la piece est dans le panneau de contexte (« Fichiers
// partages »). La lecture du vocal (COM-VOC) et la bulle a piece jointe se
// branchent a COM-FUS : `FilDiscussion` (socle) ne porte encore que du
// texte.
//
// Un fil ou la personne ne peut pas ecrire (capacite `ecrire` absente du
// fil rendu, COM-BR-16) se lit sans champ ni bouton : une phrase dit la
// limite, aucun bouton grise.

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/communications/carte_piece_jointe.dart';
import '../../core/widgets/communications/composer_texte.dart';
import '../../core/widgets/fil_discussion.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';

/// Le texte d'un message tel qu'il se lit dans le fil : son texte, puis une
/// ligne par piece jointe (« Piece jointe : Devoir.pdf ») ou vocal
/// (« Message vocal de 0:28 »). Jamais une reference ni une adresse.
String texteDuMessage(MessageCommunication m) {
  final f = t.com.messages.fil;
  return <String>[
    if (m.texte.trim().isNotEmpty) m.texte.trim(),
    for (final PieceJointe p in m.piecesJointes)
      if (p.nature == NaturePieceJointe.vocal)
        switch (p.duree) {
          final Duration d => f.vocal(duree: CartePieceJointe.libelleDuree(d)),
          null => f.vocalSansDuree,
        }
      else
        f.pieceJointe(nom: p.nom),
  ].join('\n');
}

/// La date et l'heure d'un message, a l'heure de l'appareil.
String horodatageMessage(DateTime instant) {
  final DateTime local = instant.toLocal();
  return t.com.messages.fil.horodatage(
    date: dateDeLAppareil(local),
    heure: heureDeLAppareil(local),
  );
}

/// Le fil contextuel : en-tete, messages, champ et envoi honnete.
class FilContextuel extends StatefulWidget {
  /// Cree le fil.
  const FilContextuel({required this.fil, required this.onEnvoyer, super.key});

  /// Le fil ouvert.
  final FilMetier fil;

  /// L'envoi d'un texte avec sa cle d'idempotence (COM-BR-02) : le futur se
  /// termine sur l'accuse du serveur, et echoue sinon.
  final Future<void> Function(String texte, String cleIdempotence) onEnvoyer;

  /// La cle de la phrase « lecture seule », pour les tests.
  static const ValueKey<String> cleLectureSeule = ValueKey<String>(
    'fil-lecture-seule',
  );

  @override
  State<FilContextuel> createState() => _FilContextuelState();
}

class _FilContextuelState extends State<FilContextuel>
    with WidgetsBindingObserver {
  /// Les cles des envois pas encore confirmes, par texte : un nouvel essai
  /// (« Reessayer ») rejoue la meme cle, et le serveur ne compte pas deux
  /// fois le meme message. La cle part avec la confirmation.
  final Map<String, String> _clesEnAttente = <String, String>{};
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
  /// message reste au-dessus du champ, au lieu de passer sous le clavier.
  /// Quand il se ferme, elle revient.
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

  /// La premiere zone defilante du fil : la liste des messages (l'en-tete
  /// ne defile pas, le champ vient apres elle).
  ScrollableState? _defilementDesMessages() {
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
    final String cle = _clesEnAttente[texte] ??=
        '${widget.fil.id}-${DateTime.now().microsecondsSinceEpoch}-'
        '${_compteur++}';
    await widget.onEnvoyer(texte, cle);
    _clesEnAttente.remove(texte);
  }

  @override
  Widget build(BuildContext context) {
    final FilMetier fil = widget.fil;
    final Widget entete = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: EnteteFilContexte.duFil(fil),
    );
    if (!fil.peut(CapaciteFil.ecrire)) {
      return _FilEnLecture(fil: fil, entete: entete);
    }
    final String soi = t.com.socle.composants.composer.auteurSoi;
    return FilDiscussion(
      key: ValueKey<String>('fil-metier-${fil.id}'),
      entete: entete,
      messages: <MessageFil>[
        for (final MessageCommunication m in fil.messages)
          MessageFil(
            id: m.id,
            auteur: m.deSoi ? soi : m.auteur.nomAffiche,
            texte: texteDuMessage(m),
            horodatage: horodatageMessage(m.envoyeLe),
            deSoi: m.deSoi,
          ),
      ],
      textes: textesFilCommunication(),
      onEnvoyer: _envoyer,
    );
  }
}

/// Un fil en lecture seule : les messages en une surface a filets, puis la
/// phrase qui dit la limite. Aucun champ, aucun bouton.
class _FilEnLecture extends StatelessWidget {
  const _FilEnLecture({required this.fil, required this.entete});

  final FilMetier fil;
  final Widget entete;

  @override
  Widget build(BuildContext context) {
    final f = t.com.messages.fil;
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
              GroupeReglages(
                lignes: <LigneRubrique>[
                  for (final MessageCommunication m in fil.messages)
                    LigneRubrique(
                      meneur: AvatarTile(
                        prenom: m.auteur.nomAffiche,
                        diametre: AppAvatar.petit,
                      ),
                      libelle: texteDuMessage(m),
                      legende: f.auteurEtMoment(
                        auteur: m.deSoi ? soi : m.auteur.nomAffiche,
                        moment: horodatageMessage(m.envoyeLe),
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
            f.lectureSeule,
            key: FilContextuel.cleLectureSeule,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
