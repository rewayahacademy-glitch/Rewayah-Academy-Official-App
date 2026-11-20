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

import '../../core/communications/communications_supabase.dart' show cleServeur;
import '../../core/communications/lecture_fil_communication.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/communications/textes_fil_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/fil_discussion.dart';
import '../com_vocal/composer_vocal.dart';
import '../com_vocal/envoi_vocal.dart';
import '../com_vocal/lecteur_vocal.dart';
import '../com_vocal/port_enregistreur_vocal.dart';
import 'barre_conversation.dart';
import 'entete_fil_contexte.dart';
import 'liens_message_staff.dart';
import 'memoire_pages_fil.dart';
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
    this.pleinEcran = false,
    this.images,
    this.onAimer,
    this.onEnvoyerImage,
    this.onAnnulerImage,
    this.libelleRetour,
    this.iconeRetour,
    this.onOuvrirMessages,
    this.onFermer,
    this.barreFixe = false,
    this.onPlusAnciens,
    this.memoire,
  });

  /// PE-D1 : la memoire des messages de la conversation, partagee avec le
  /// panneau de contexte (« Fichiers partages ») ; `null` : le fil a la sienne,
  /// qui lit les pages anciennes par [onPlusAnciens].
  final MemoirePagesFil? memoire;

  /// PE-D1 (chargement par pages) : les messages qui precedent le message
  /// [avantId] (le plus ancien montre), ou `null` : le fil rendu est entier.
  final Future<PageMessagesFil> Function(String avantId)? onPlusAnciens;

  /// IMAGES-MESSAGERIE : les adresses des images du fil, ou `null`.
  final SourceImagesFil? images;

  /// IMAGES-MESSAGERIE : poser ou retirer son coeur (le fil lu en garde le
  /// droit, meme en lecture seule), ou `null`.
  final Future<EtatCoeur> Function(String messageId, bool aime)? onAimer;

  /// IMAGES-MESSAGERIE : envoyer un message avec son image, ou `null` : pas
  /// d'icone (compte eleve de moins de 18 ans).
  final EnvoiImageFil? onEnvoyerImage;

  /// IMAGES-CORRECTIF : abandonne le depot d'une bulle supprimee, ou `null`.
  final Future<void> Function(String imageId)? onAnnulerImage;

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

  /// MESSAGERIE-PLEIN-ECRAN : le fil est une page a lui (telephone) : une
  /// barre compacte (`BarreConversation`), les messages en ordre inverse, la
  /// saisie fixe en bas. Faux : le fil a son en-tete dans une page a titre
  /// (tablette et ordinateur, ou le fil vit a cote de la liste).
  final bool pleinEcran;

  /// CONVERSATIONS-PARTOUT : le mot et l'icone du retour de la barre (voir
  /// `BarreConversation`), et le lien « Ouvrir dans Messages » ; passes tels
  /// quels a la barre, jamais recomposes par la page qui pose le fil.
  final String? libelleRetour;
  final AppIcon? iconeRetour;
  final VoidCallback? onOuvrirMessages;

  /// MESSAGERIE-COULEURS : la croix « Fermer la conversation » d'un volet, au
  /// bord de fin de la barre (voir `BarreConversation.onFermer`).
  final VoidCallback? onFermer;

  /// Vrai : la barre ne se replie jamais quand on remonte vers les anciens
  /// messages (un volet n'a pas d'autre moyen d'etre ferme que sa barre).
  final bool barreFixe;

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
  /// meme message. Deux bulles au meme texte ont deux cles (R-COM-13).
  /// PE-D1 : la cle est gardee apres l'accuse (la copie confirmee peut revenir
  /// plus tard), et retrouvee par la cle que le serveur rend
  /// ([_localParCleServeur]) : c'est elle, jamais le texte, qui rapproche la
  /// bulle locale de son message.
  final Map<String, String> _cles = <String, String>{};
  final Map<String, String> _localParCleServeur = <String, String>{};
  int _compteur = 0;

  /// PE-D1 : la memoire des messages de la conversation ouverte (pages
  /// anciennes, et messages sortis de la page la plus recente a une
  /// relecture) : celle de la page, ou la sienne.
  MemoirePagesFil? _memoirePropre;
  MemoirePagesFil get _memoire =>
      widget.memoire ??
      (_memoirePropre ??= MemoirePagesFil(lire: widget.onPlusAnciens));

  String _cleDe(String idLocal) => _cles.putIfAbsent(idLocal, () {
    final String cle =
        '${widget.fil.id}-${DateTime.now().microsecondsSinceEpoch}-'
        '${_compteur++}';
    _localParCleServeur[cleServeur(cle)] = idLocal;
    return cle;
  });

  /// Tous les messages connus, sans doublon : aucun message deja affiche ne
  /// quitte l'ecran tant que la conversation est ouverte.
  List<MessageCommunication> get _tousLesMessages =>
      (_memoire..recevoir(widget.fil)).messages;

  bool get _plusAnciens => (_memoire..recevoir(widget.fil)).plusAnciens;

  bool get _litParPages => _memoire.lire != null;

  Future<void> _chargerAnciens() => _memoire.chargerAnciens();

  void _surMemoire() {
    if (mounted) setState(() {});
  }

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

  /// La barre compacte est repliee : le fil remonte vers les anciens messages.
  bool _barreRepliee = false;

  bool _surDefilement(ScrollNotification n) {
    if (n is! ScrollUpdateNotification || n.depth != 0) return false;
    final double delta = n.scrollDelta ?? 0;
    // Liste inversee : des pixels qui grandissent, ce sont les anciens messages.
    final bool replie =
        n.metrics.pixels > 0 && (delta > 0 || _barreRepliee && delta == 0);
    if (delta != 0 && replie != _barreRepliee) {
      setState(() => _barreRepliee = replie);
    }
    if (n.metrics.pixels <= 0 && _barreRepliee) {
      setState(() => _barreRepliee = false);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _memoire
      ..recevoir(widget.fil)
      ..addListener(_surMemoire);
  }

  @override
  void didUpdateWidget(FilContextuel ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.memoire, widget.memoire)) {
      (ancien.memoire ?? _memoirePropre)?.removeListener(_surMemoire);
      _memoire.addListener(_surMemoire);
    }
    // PE-D1 : la relecture ne rend que la page la plus recente ; les messages
    // qui en sortent restent dans la memoire.
    _memoire.recevoir(widget.fil);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clavier = _hauteurClavier();
  }

  @override
  void dispose() {
    _memoire.removeListener(_surMemoire);
    _memoirePropre?.dispose();
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
    // Liste inversee : elle reste collee au dernier message d'elle-meme.
    if (!mounted || widget.pleinEcran) return;
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

  Future<void> _envoyer(String idLocal, String texte) =>
      widget.onEnvoyer(texte, _cleDe(idLocal));

  /// IMAGES-MESSAGERIE : envoie le message [texte] avec [image], sous la cle
  /// de sa bulle (rejouee au « Reessayer »).
  Future<void> _envoyerImage(
    String idLocal,
    String texte,
    ImagePrete image,
    ProgressionImage progression,
  ) async {
    await widget.onEnvoyerImage!(texte, _cleDe(idLocal), image, progression);
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

  /// BULLES-MESSAGERIE : le nom de l'auteur ne se lit que dans une
  /// conversation de groupe (plus de deux participants) ; a deux, l'autre est
  /// deja nomme dans la barre.
  bool get _estGroupe => widget.fil.participants.length > 2;

  /// BULLES-MESSAGERIE : sur tablette et ordinateur, la liste est a cote du
  /// fil ; la tete de la page reste au-dessus des deux colonnes. Au telephone
  /// (texte agrandi), le fil la prend avec ses messages.
  bool get _prendTete => AppGabarit.de(context) == Gabarit.mobile;

  /// Le fil plein ecran : la barre compacte, puis le fil (messages, saisie).
  Widget _pleinEcran(List<MessageFil> connus, TextesFilDiscussion textes) {
    final FilMetier fil = widget.fil;
    final bool ecriture =
        widget.ecritureOuverte && fil.peut(CapaciteFil.ecrire);
    final String soi = t.com.socle.composants.composer.auteurSoi;
    final Future<void> Function(EnregistrementVocal, String)? vocal =
        widget.onEnvoyerVocal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarreConversation(
          fil: fil,
          onRetour: widget.onRetour,
          replie: !widget.barreFixe && _barreRepliee,
          libelleRetour: widget.libelleRetour,
          iconeRetour: widget.iconeRetour,
          onOuvrirMessages: widget.onOuvrirMessages,
          onFermer: widget.onFermer,
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _surDefilement,
            child: FilDiscussion(
              plusAnciens: _plusAnciens,
              onPlusAnciens: _litParPages ? _chargerAnciens : null,
              pleinEcran: true,
              afficherAuteur: _estGroupe,
              defilement: _defilement,
              key: ValueKey<String>('fil-metier-plein-${fil.id}'),
              messages: <MessageFil>[
                ...connus,
                if (ecriture)
                  for (final VocalConfirme v in _vocauxConfirmes)
                    bulleVocalConfirme(
                      v,
                      auteurSoi: soi,
                      ligneVocal: ligneVocal,
                      envoye: textes.envoye,
                    ),
              ],
              textes: textes,
              lectureSeule: ecriture ? null : t.com.messages.fil.lectureSeule,
              onEnvoyerMessage: ecriture ? _envoyer : null,
              images: widget.images,
              onAimer: widget.onAimer,
              onEnvoyerImage: ecriture && widget.onEnvoyerImage != null
                  ? _envoyerImage
                  : null,
              onAnnulerImage: widget.onAnnulerImage,
              cleBrouillon: ecriture ? cleBrouillonFil(fil.id) : null,
              emplacementVocal: !ecriture || vocal == null
                  ? null
                  : ComposerVocal(
                      key: FilContextuel.cleComposerVocal,
                      onEnvoyer: (EnregistrementVocal v) =>
                          _envoyerVocal(v, vocal),
                    ),
            ),
          ),
        ),
      ],
    );
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
      for (final MessageCommunication m in _tousLesMessages)
        messageFilDe(
          m,
          idLocal: _localParCleServeur[m.cleIdempotence],
          // #Ra_staff (directeur, 14/11/2026) : les liens https d'un message
          // de l'equipe s'ouvrent ; ceux des autres restent du texte.
          complement: complementAvecLiens(
            pieces: piecesDuMessage(m.piecesJointes),
            equipe: m.auteur.equipe,
            texte: m.texte,
          ),
          // MESSAGERIE-LU : envoye (une coche, pale) ou lu (deux coches).
          suiviLecture: true,
          luParAutresLe: fil.luParAutresLe,
        ),
    ];
    final TextesFilDiscussion textes = textesFilCommunication();
    if (widget.pleinEcran) return _pleinEcran(connus, textes);
    if (!widget.ecritureOuverte || !fil.peut(CapaciteFil.ecrire)) {
      // Lecture seule : le meme fil, sans champ ; la phrase dit la limite.
      return FilDiscussion(
        plusAnciens: _plusAnciens,
        onPlusAnciens: _litParPages ? _chargerAnciens : null,
        afficherAuteur: _estGroupe,
        prendTeteDePage: _prendTete,
        defilement: _defilement,
        key: ValueKey<String>('fil-metier-lecture-${fil.id}'),
        entete: entete,
        enteteCompacte: compacte,
        enteteSuite: suite,
        retourCompacte: widget.onRetour,
        messages: connus,
        textes: textes,
        images: widget.images,
        onAimer: widget.onAimer,
        lectureSeule: t.com.messages.fil.lectureSeule,
      );
    }
    final String soi = t.com.socle.composants.composer.auteurSoi;
    final Future<void> Function(EnregistrementVocal, String)? vocal =
        widget.onEnvoyerVocal;
    return FilDiscussion(
      plusAnciens: _plusAnciens,
      onPlusAnciens: _litParPages ? _chargerAnciens : null,
      afficherAuteur: _estGroupe,
      prendTeteDePage: _prendTete,
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
      images: widget.images,
      onAimer: widget.onAimer,
      onEnvoyerImage: widget.onEnvoyerImage == null ? null : _envoyerImage,
      onAnnulerImage: widget.onAnnulerImage,
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
