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
// Une piece jointe se montre dans la bulle par sa carte (`CartePieceJointe`,
// COM-RC, R-11), et aussi dans le panneau de contexte (« Fichiers
// partages »). Un vocal recu se lit dans la bulle, par le lecteur de COM-VOC
// (`LecteurVocalRecu`, COM-FUS).
//
// Le texte du champ est garde comme brouillon le temps de la session et
// remis a la reouverture du fil (« Brouillon restaure ») : `FilDiscussion`
// le porte seul, sous la cle du fil (COM-RC, R-22).
//
// Le composer vocal (COM-VOC) se pose sous le champ seulement si la page
// donne [FilContextuel.onEnvoyerVocal] : elle ne le fait que si la capacite
// `envoyerVocal` est ouverte (COM-BR-16), donc jamais en production tant que
// le port des capacites est neutre. Aucun envoi automatique : seul
// « Envoyer » du composer envoie, sous une cle par vocal (COM-BR-02).
//
// Un fil ou la personne ne peut pas ecrire se lit sans champ ni bouton : une
// phrase dit la limite, aucun bouton grise. C'est le mode lecture seule de
// `FilDiscussion` (memes bulles, meme etat vide), et le texte et la date
// d'un message viennent de l'adaptateur unique du socle
// (`lecture_fil_communication.dart`) : aucune copie avec le canal du Studio
// (revue COM-R, R-07). Ecrire demande les deux
// capacites de COM-BR-16 : `ecrireDansFil` du port neutre du socle
// (`capacitesCommunicationProvider`, lu par la page et passe ici en
// [FilContextuel.ecritureOuverte]) ET `ecrire` portee par CE fil rendu.

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import '../../core/communications/lecture_fil_communication.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/communications/textes_fil_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/fil_discussion.dart';
import '../com_vocal/composer_vocal.dart';
import '../com_vocal/envoi_vocal.dart';
import '../com_vocal/lecteur_vocal.dart';
import '../com_vocal/port_enregistreur_vocal.dart';
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';

/// La cle du brouillon du champ d'un fil metier.
CleBrouillon cleBrouillonFil(String filId) =>
    CleBrouillon(type: TypeObjetLie.message, objetId: filId);

/// Le fil contextuel : en-tete, messages, champ et envoi honnete.
class FilContextuel extends StatefulWidget {
  /// Cree le fil.
  const FilContextuel({
    required this.fil,
    required this.ecritureOuverte,
    required this.onEnvoyer,
    super.key,
    this.onEnvoyerVocal,
    this.onRetour,
  });

  /// Le fil ouvert.
  final FilMetier fil;

  /// La capacite `ecrireDansFil` de la personne connectee (COM-BR-16), lue
  /// par la page dans `capacitesCommunicationProvider` : fermee, le fil se
  /// lit seulement, quelle que soit la capacite portee par le fil.
  final bool ecritureOuverte;

  /// L'envoi d'un texte avec sa cle d'idempotence (COM-BR-02) : le futur se
  /// termine sur l'accuse du serveur, et echoue sinon.
  final Future<void> Function(String texte, String cleIdempotence) onEnvoyer;

  /// L'envoi d'un vocal avec sa cle d'idempotence (COM-BR-03, COM-BR-02), ou
  /// `null` : aucun composer vocal n'est rendu (capacite `envoyerVocal`
  /// fermee, production).
  final Future<void> Function(EnregistrementVocal vocal, String cleIdempotence)?
  onEnvoyerVocal;

  /// Le retour de la page vers la liste des conversations, ou `null`. A
  /// texte agrandi ou sur une vue basse, la tete de la page (et son disque
  /// retour) defile avec les messages : ce retour se pose alors dans la
  /// ligne compacte, fixe (COM-R-3, constat 8).
  final VoidCallback? onRetour;

  /// La cle du composer vocal du fil, pour les tests.
  static const ValueKey<String> cleComposerVocal = ValueKey<String>(
    'fil-composer-vocal',
  );

  /// La cle de la phrase « lecture seule », pour les tests : celle du fil
  /// (R-07).
  static const Key cleLectureSeule = FilDiscussion.cleLectureSeule;

  @override
  State<FilContextuel> createState() => _FilContextuelState();
}

class _FilContextuelState extends State<FilContextuel>
    with WidgetsBindingObserver {
  /// Les cles d'idempotence, par identifiant local de bulle
  /// (`FilDiscussion.onEnvoyerMessage`, COM-FUS) : chaque bulle a SA cle,
  /// rejouee a son « Reessayer » ; le serveur ne compte pas deux fois le
  /// meme message. Deux bulles au meme texte ont deux cles (R-COM-13). La
  /// cle est oubliee a l'accuse.
  final Map<String, String> _cles = <String, String>{};
  int _compteur = 0;

  /// Les cles des vocaux de ce fil, une par vocal (COM-BR-02).
  late final ClesVocales _clesVocales = ClesVocales(
    DestinationVocal.fil(widget.fil.id),
  );

  /// Les vocaux confirmes depuis l'ouverture du fil (COM-FUS, revue) : la
  /// page ne relit que la liste apres un envoi, le fil ouvert les montre donc
  /// lui-meme, apres les messages connus.
  final List<VocalConfirme> _vocauxConfirmes = <VocalConfirme>[];

  /// La hauteur du clavier logiciel au dernier releve, en points logiques.
  double _clavier = 0;

  /// La liste des messages du fil, donnee a `FilDiscussion` (R-COM-15 :
  /// la lecture suit le clavier). Elle porte aussi l'en-tete du fil et,
  /// a texte agrandi, la tete de la page (R-02) : c'est la meme position.
  final ScrollController _defilement = ScrollController();

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
    _defilement.dispose();
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
          '${widget.fil.id}-${DateTime.now().microsecondsSinceEpoch}-'
          '${_compteur++}',
    );
    await widget.onEnvoyer(texte, cle);
    _cles.remove(idLocal);
  }

  /// Envoie [vocal] par [envoi] sous sa cle ; a l'accuse, sa bulle entre
  /// dans le fil. Un echec remonte au composer (« Reessayer »), sans bulle.
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

  @override
  Widget build(BuildContext context) {
    final FilMetier fil = widget.fil;
    final Widget entete = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: EnteteFilContexte.duFil(fil),
    );
    // N-1 (COM-RC tour 4) : quand l'en-tete defile (texte agrandi, vue
    // basse), la ligne compacte (noms, objets, et (i)) reste fixe ; le
    // badge d'attention defile avec les messages.
    final Widget compacte = EnteteFilContexte.duFil(fil, compacte: true);
    final Widget? suite = EnteteFilContexte.badgeDuFil(fil);
    final List<MessageFil> connus = <MessageFil>[
      for (final MessageCommunication m in fil.messages)
        messageFilDe(m, complement: piecesDuMessage(m.piecesJointes)),
    ];
    final TextesFilDiscussion textes = textesFilCommunication();
    if (!widget.ecritureOuverte || !fil.peut(CapaciteFil.ecrire)) {
      // Lecture seule : le meme fil, sans champ ; la phrase dit la limite.
      return FilDiscussion(
        defilement: _defilement,
        key: ValueKey<String>('fil-metier-lecture-${fil.id}'),
        entete: entete,
        enteteCompacte: compacte,
        enteteSuite: suite,
        retourCompacte: widget.onRetour,
        messages: connus,
        textes: textes,
        lectureSeule: t.com.messages.fil.lectureSeule,
      );
    }
    final String soi = t.com.socle.composants.composer.auteurSoi;
    final Future<void> Function(EnregistrementVocal, String)? vocal =
        widget.onEnvoyerVocal;
    return FilDiscussion(
      defilement: _defilement,
      key: ValueKey<String>('fil-metier-${fil.id}'),
      entete: entete,
      enteteCompacte: compacte,
      enteteSuite: suite,
      retourCompacte: widget.onRetour,
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
      cleBrouillon: cleBrouillonFil(fil.id),
      emplacementVocal: vocal == null
          ? null
          : ComposerVocal(
              key: FilContextuel.cleComposerVocal,
              onEnvoyer: (EnregistrementVocal v) => _envoyerVocal(v, vocal),
            ),
    );
  }
}
