// Le lecteur d'un message vocal (spec Communications V1, section 11.2, etats
// 14 a 17 ; section 24, accessibilite).
//
// Il sert deux fois : pour un vocal recu dans une conversation, et pour la
// pre-ecoute d'un vocal enregistre dans le composer. La lecture vient d'un
// `LectureVocale` ouvert au toucher (jamais avant) : un vocal recu demande sa
// source au serveur par `PortLectureVocale` (lien signe de courte duree,
// COM-BR-03), une pre-ecoute la demande a `PortEnregistreurVocal`.
//
// La barre de progression est decorative (`ExcludeSemantics`) : la position
// est ecrite en toutes lettres (« 0:12 sur 0:28 ») et l'etat se dit en mots
// (« Lecture en cours »). La waveform n'est jamais necessaire pour comprendre.
//
// `LectureVocaleJustAudio` adapte `just_audio` (deja present dans
// `pubspec.yaml`) au contrat `LectureVocale` : l'adaptateur reel de lecture,
// branche quand le serveur fournira la source (BR-1).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/port_pieces_jointes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_piece_jointe.dart';
import '../../core/widgets/status_pill.dart';
import 'etats_vocal.dart';
import 'port_enregistreur_vocal.dart';

/// La duree ecrite en minutes et secondes (« 1:05 »), celle des pieces
/// jointes du socle.
String libelleDureeVocal(Duration duree) =>
    CartePieceJointe.libelleDuree(duree);

/// Le lecteur d'un message vocal : etat en mots, position, une action.
///
/// L'action change de sens avec l'etat, elle ne se grise jamais :
/// « Ecouter » (14), « Pause » (15), « Reprendre » (16), « Reecouter » (17).
class LecteurVocal extends StatefulWidget {
  /// Cree le lecteur.
  const LecteurVocal({
    required this.ouvrir,
    required this.duree,
    super.key,
    this.auteur,
    this.lisible = true,
  });

  /// Ouvre la lecture, au premier toucher seulement.
  final Future<LectureVocale> Function() ouvrir;

  /// Faux quand la lecture n'est pas autorisee a la personne qui lit : la
  /// phrase d'indisponibilite remplace l'action (jamais un bouton grise).
  final bool lisible;

  /// La duree annoncee du vocal.
  final Duration duree;

  /// L'auteur du vocal, dit au lecteur d'ecran ; `null` pour la pre-ecoute.
  final String? auteur;

  /// La cle de l'action du lecteur, pour les tests.
  static const ValueKey<String> cleAction = ValueKey<String>(
    'vocal-lecteur-action',
  );

  /// La cle de l'etat ecrit, pour les tests.
  static const ValueKey<String> cleEtat = ValueKey<String>(
    'vocal-lecteur-etat',
  );

  /// La cle de la position ecrite, pour les tests.
  static const ValueKey<String> clePosition = ValueKey<String>(
    'vocal-lecteur-position',
  );

  /// Le mot d'un etat du lecteur.
  static String libelleEtat(EtatVocal etat) {
    final l = t.com.vocal.lecteur;
    return switch (etat) {
      EtatVocal.lecture => l.lecture,
      EtatVocal.pauseLecture => l.enPause,
      EtatVocal.finLecture => l.fin,
      _ => l.nonEcoute,
    };
  }

  /// Le libelle de l'action dans un etat du lecteur.
  static String libelleAction(EtatVocal etat) {
    final l = t.com.vocal.lecteur;
    return switch (etat) {
      EtatVocal.lecture => l.pause,
      EtatVocal.pauseLecture => l.reprendre,
      EtatVocal.finLecture => l.reecouter,
      _ => l.ecouter,
    };
  }

  @override
  State<LecteurVocal> createState() => _LecteurVocalState();
}

class _LecteurVocalState extends State<LecteurVocal> {
  LectureVocale? _lecture;
  EtatLectureAudio _etat = const EtatLectureAudio();
  bool _ouverture = false;
  Object? _erreur;

  @override
  void dispose() {
    final LectureVocale? lecture = _lecture;
    if (lecture != null) {
      lecture.etat.removeListener(_suivre);
      unawaited(lecture.liberer());
    }
    super.dispose();
  }

  void _suivre() {
    final LectureVocale? lecture = _lecture;
    if (!mounted || lecture == null) return;
    setState(() => _etat = lecture.etat.value);
  }

  EtatVocal get _etatVocal => etatDuLecteur(_etat);

  Duration get _duree => _lecture?.duree ?? widget.duree;

  Future<void> _agir() async {
    final LectureVocale? ouverte = _lecture;
    if (ouverte == null) {
      await _ouvrirPuisLire();
      return;
    }
    if (_erreur != null) setState(() => _erreur = null);
    try {
      switch (_etatVocal) {
        case EtatVocal.lecture:
          await ouverte.mettreEnPause();
        case EtatVocal.finLecture:
          await ouverte.relire();
        case _:
          await ouverte.lire();
      }
    } on Object catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _ouvrirPuisLire() async {
    setState(() {
      _ouverture = true;
      _erreur = null;
    });
    try {
      final LectureVocale lecture = await widget.ouvrir();
      if (!mounted) {
        unawaited(lecture.liberer());
        return;
      }
      _lecture = lecture;
      lecture.etat.addListener(_suivre);
      setState(() {
        _ouverture = false;
        _etat = lecture.etat.value;
      });
      await lecture.lire();
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(() {
        _ouverture = false;
        _erreur = erreur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final l = t.com.vocal.lecteur;
    final Duration duree = _duree;
    final String dureeEcrite = libelleDureeVocal(duree);
    final String? auteur = widget.auteur;
    final String libelle = auteur == null
        ? l.libelle(duree: dureeEcrite)
        : l.libelleAuteur(auteur: auteur, duree: dureeEcrite);
    final EtatVocal etat = _etatVocal;
    final Duration position = _etat.position > duree ? duree : _etat.position;
    final double fraction = duree.inMilliseconds == 0
        ? 0
        : position.inMilliseconds / duree.inMilliseconds;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // Une lecture interrompue apres son lancement se dit comme un echec a
    // l'ouverture : la phrase, puis « Reessayer ».
    final bool enErreur = _erreur != null || _etat.echec;
    final Object? erreur = _erreur;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: libelle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  AppIcons.micro.repos,
                  size: AppSpacing.xxl,
                  color: palette.surfaceRaised.onBackground,
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (auteur != null) ...<Widget>[
                      Text(
                        auteur,
                        style: palette.surfaceRaised.applyTo(
                          textes.titleSmall ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vXs,
                    ],
                    Semantics(
                      liveRegion: true,
                      child: StatusPill(
                        key: LecteurVocal.cleEtat,
                        libelle: LecteurVocal.libelleEtat(etat),
                        ton: switch (etat) {
                          EtatVocal.lecture => TonEtat.accent,
                          EtatVocal.finLecture => TonEtat.succes,
                          _ => TonEtat.neutre,
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Ecart.vMd,
          // Decorative : la position est ecrite juste dessous.
          ExcludeSemantics(child: LinearProgressIndicator(value: fraction)),
          Ecart.vSm,
          Text(
            l.position(
              position: libelleDureeVocal(position),
              duree: dureeEcrite,
            ),
            key: LecteurVocal.clePosition,
            style: discret,
          ),
          if (!widget.lisible || erreur is CapaciteIndisponible) ...<Widget>[
            Ecart.vSm,
            Text(l.indisponible, style: discret),
          ] else ...<Widget>[
            if (enErreur) ...<Widget>[
              Ecart.vSm,
              Semantics(
                liveRegion: true,
                child: Text(
                  l.erreurLectureTitre,
                  style: palette.inkAlert.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
            Ecart.vLg,
            RangeeActions(
              children: <Widget>[
                ActionPrincipale(
                  key: LecteurVocal.cleAction,
                  libelle: enErreur
                      ? l.erreurLectureAction
                      : LecteurVocal.libelleAction(etat),
                  onPress: _agir,
                  enCours: _ouverture,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Le lecteur d'un vocal recu dans une conversation : la piece jointe de
/// nature [NaturePieceJointe.vocal], ouverte par [PortLectureVocale] au
/// toucher. Le port neutre de production dit « indisponible » ; une piece
/// que la personne ne peut pas ouvrir n'offre aucune action.
class LecteurVocalRecu extends ConsumerWidget {
  /// Cree le lecteur de [vocal].
  const LecteurVocalRecu({required this.vocal, super.key, this.auteur});

  /// Le vocal recu.
  final PieceJointe vocal;

  /// Son auteur, dit au lecteur d'ecran.
  final String? auteur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortLectureVocale port = ref.watch(portLectureVocaleProvider);
    return LecteurVocal(
      ouvrir: () => port.ouvrir(vocal),
      duree: vocal.duree ?? Duration.zero,
      auteur: auteur,
      lisible:
          vocal.peutOuvrir &&
          vocal.nature == NaturePieceJointe.vocal &&
          vocal.etat == EtatPieceJointe.envoyee,
    );
  }
}

/// Les pieces d'un message, a poser dans sa bulle (`MessageFil.complement`,
/// COM-RC, R-11) : la carte de chaque piece non vocale (`CartePieceJointe` :
/// nom, type, taille, etat, jamais une adresse) et le lecteur de chaque
/// vocal, dans l'ordre du message ; `null` sans piece. Les cartes sont
/// detachees, a 16 l'une de l'autre (K-55).
Widget? piecesDuMessage(List<PieceJointe> pieces) {
  if (pieces.isEmpty) return null;
  final List<Widget> elements = <Widget>[
    for (final PieceJointe p in pieces)
      if (p.nature == NaturePieceJointe.vocal)
        LecteurVocalRecu(vocal: p)
      else
        CartePieceJointe(piece: p),
  ];
  if (elements.length == 1) return elements.single;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.lg,
    children: elements,
  );
}

/// La lecture d'une source audio par `just_audio`, au contrat [LectureVocale].
///
/// La source (lien signe de courte duree demande au serveur au toucher) est
/// passee a [ouvrir] et confiee au lecteur audio : elle n'est ni gardee dans
/// un modele, ni affichee, ni journalisee.
class LectureVocaleJustAudio implements LectureVocale {
  LectureVocaleJustAudio._(this._lecteur, this.duree);

  /// Adapte un lecteur deja charge (tests de l'adaptateur).
  @visibleForTesting
  factory LectureVocaleJustAudio.surLecteur(
    AudioPlayer lecteur, {
    required Duration duree,
  }) => LectureVocaleJustAudio._(lecteur, duree).._ecouter();

  /// Ouvre [source] ; [duree] sert si le fichier ne dit pas la sienne.
  static Future<LectureVocaleJustAudio> ouvrir(
    Uri source, {
    required Duration duree,
  }) async {
    final AudioPlayer lecteur = AudioPlayer();
    try {
      final Duration? reelle = await lecteur.setUrl(source.toString());
      return LectureVocaleJustAudio._(lecteur, reelle ?? duree).._ecouter();
    } on Object {
      await lecteur.dispose();
      rethrow;
    }
  }

  final AudioPlayer _lecteur;
  final ValueNotifier<EtatLectureAudio> _etat = ValueNotifier<EtatLectureAudio>(
    const EtatLectureAudio(),
  );
  final List<StreamSubscription<Object?>> _abonnements =
      <StreamSubscription<Object?>>[];
  bool _echec = false;
  bool _liberee = false;

  @override
  final Duration duree;

  @override
  ValueListenable<EtatLectureAudio> get etat => _etat;

  void _ecouter() {
    _abonnements
      ..add(_lecteur.positionStream.listen((Duration _) => _maj()))
      ..add(_lecteur.playerStateStream.listen((PlayerState _) => _maj()));
  }

  void _maj() {
    if (_liberee) return;
    final PlayerState etat = _lecteur.playerState;
    final bool termine = etat.processingState == ProcessingState.completed;
    _etat.value = EtatLectureAudio(
      position: termine ? duree : _lecteur.position,
      enLecture: etat.playing && !termine && !_echec,
      termine: termine,
      echec: _echec,
    );
  }

  /// Lance `play` sans l'attendre (il ne se termine qu'a la pause ou a la
  /// fin) ; une erreur survenue ensuite (source expiree, reseau perdu) passe
  /// dans l'etat, jamais en erreur non geree.
  void _jouer() {
    _echec = false;
    _maj();
    unawaited(
      _lecteur.play().then(
        (_) {},
        onError: (Object _) {
          if (_liberee) return;
          _echec = true;
          _maj();
        },
      ),
    );
  }

  @override
  Future<void> lire() async {
    if (_lecteur.playerState.processingState == ProcessingState.completed) {
      await _lecteur.seek(Duration.zero);
    }
    _jouer();
  }

  @override
  Future<void> mettreEnPause() => _lecteur.pause();

  @override
  Future<void> relire() async {
    await _lecteur.seek(Duration.zero);
    _jouer();
  }

  @override
  Future<void> liberer() async {
    // Idempotent : un second appel ne fait rien.
    if (_liberee) return;
    _liberee = true;
    for (final StreamSubscription<Object?> a in _abonnements) {
      await a.cancel();
    }
    _abonnements.clear();
    _etat.dispose();
    await _lecteur.dispose();
  }
}
