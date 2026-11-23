// SALLE-SECOND-APPAREIL (directeur, 23/11/2026 : « Il faut penser toujours a
// communiquer avec les gens ») : un profil, un appareil a la fois dans la
// classe, jamais de coupure brusque. Quand un second appareil demande a entrer
// avec le meme compte, le premier est prevenu et decide ; le second attend en
// le sachant.
//
// Trois ecrans de parole :
//   * [DialogueAutreAppareil] : sur le premier appareil, « Laisser passer ? » ;
//   * [AttentePassageAppareil] : sur le second, « Nous lui demandons de
//     confirmer », avec « Annuler » ; hors ligne, il le dit ;
//   * [NoteAncienAppareil] : « L'autre appareil ne repondait plus ».
//
// [SurveillanceSecondAppareil] les pose autour de la salle : le battement qui
// garde la place et lit les demandes (toutes les 5 secondes, tant que la
// personne est dans la salle), et l'attente du second appareil. Tout se decide
// en base ; l'ecran ne fait que dire.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/appareil_salle.dart';
import '../../core/video/libelle_appareil.dart';
import '../../core/video/second_appareil.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;

/// Le rythme du battement du premier appareil : assez court pour qu'une
/// demande apparaisse « presque tout de suite », assez long pour ne rien
/// charger. Le serveur tient un appareil pour silencieux apres 30 secondes.
const Duration rythmeBattementSalle = Duration(seconds: 5);

/// Ce que dit la carte : qui demande (l'etiquette de l'appareil).
String phraseDemandeAutreAppareil(String libelle) => libelle.isEmpty
    ? t.salle.passage.demandeSansNom
    : t.salle.passage.demande(appareil: libelle);

/// Sur le PREMIER appareil : un autre appareil, avec le meme compte, demande a
/// entrer. « Accepter » : cet appareil sort proprement ; « Refuser » : il reste.
class DialogueAutreAppareil extends StatelessWidget {
  /// Cree le dialogue.
  const DialogueAutreAppareil({
    required this.libelle,
    required this.onAccepter,
    required this.onRefuser,
    super.key,
    this.enCours = false,
    this.echec = false,
  });

  /// L'etiquette de l'autre appareil (« Chrome · Android »).
  final String libelle;

  /// Accepter : cet appareil cede la place.
  final VoidCallback onAccepter;

  /// Refuser : cet appareil reste.
  final VoidCallback onRefuser;

  /// La reponse part : les boutons attendent (jamais une double reponse).
  final bool enCours;

  /// La reponse n'a pas pu etre envoyee : on le dit, et on peut reessayer.
  final bool echec;

  /// Le dialogue.
  static const Key cle = Key('salle.passage.dialogue');

  /// « Accepter ».
  static const Key accepterKey = Key('salle.passage.accepter');

  /// « Refuser ».
  static const Key refuserKey = Key('salle.passage.refuser');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      container: true,
      scopesRoute: true,
      explicitChildNodes: true,
      label: t.salle.passage.titre,
      child: AppCard(
        key: cle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  t.salle.passage.titre,
                  style: palette.inkStrong.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vSm,
              Text(
                phraseDemandeAutreAppareil(libelle),
                style: palette.inkStrong.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
              if (echec) ...<Widget>[
                Ecart.vMd,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    t.salle.passage.echecReponse,
                    style: palette.inkAlert.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
              Ecart.vLg,
              ActionPrincipale(
                key: accepterKey,
                libelle: t.salle.passage.accepter,
                enCours: enCours,
                onPress: enCours ? null : onAccepter,
              ),
              Ecart.vSm,
              ActionPrincipale(
                key: refuserKey,
                libelle: t.salle.passage.refuser,
                niveau: NiveauAction.secondaire,
                onPress: enCours ? null : onRefuser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sur le SECOND appareil : « Nous lui demandons de confirmer… », avec
/// « Annuler ». Hors ligne, la demande reste posee et on le dit.
class AttentePassageAppareil extends StatelessWidget {
  /// Cree l'attente.
  const AttentePassageAppareil({
    required this.phase,
    required this.onAnnuler,
    super.key,
    this.libelleAutre = '',
  });

  /// [PhasePassage.attente] ou [PhasePassage.horsLigne].
  final PhasePassage phase;

  /// L'etiquette de l'autre appareil, quand le serveur la donne.
  final String libelleAutre;

  /// Renoncer a entrer depuis cet appareil.
  final VoidCallback onAnnuler;

  /// L'attente.
  static const Key cle = Key('salle.passage.attente');

  /// « Annuler ».
  static const Key annulerKey = Key('salle.passage.annuler');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = phase == PhasePassage.horsLigne;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: AppCard(
              key: cle,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        t.salle.passage.attenteTitre,
                        style: palette.inkStrong.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                    Ecart.vSm,
                    Text(
                      t.salle.passage.attente,
                      style: palette.inkStrong.applyTo(
                        textes.bodyLarge ?? const TextStyle(),
                      ),
                    ),
                    if (libelleAutre.isNotEmpty) ...<Widget>[
                      Ecart.vXs,
                      Text(
                        t.salle.passage.surAppareil(appareil: libelleAutre),
                        style: palette.inkMuted.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ],
                    Ecart.vMd,
                    if (horsLigne)
                      Text(
                        t.salle.passage.horsLigne,
                        style: palette.inkAlert.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      )
                    else
                      const Skeleton.liste(lignes: 1),
                    Ecart.vLg,
                    ActionPrincipale(
                      key: annulerKey,
                      libelle: t.commun.annuler,
                      niveau: NiveauAction.secondaire,
                      onPress: onAnnuler,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « L'autre appareil ne repondait plus : vous continuez ici », apres l'entree.
class NoteAncienAppareil extends StatelessWidget {
  /// Cree la note.
  const NoteAncienAppareil({super.key});

  /// La note.
  static const Key cle = Key('salle.passage.note');

  @override
  Widget build(BuildContext context) => BandeauAttention(
    key: cle,
    titre: t.salle.passage.ancienSilencieux,
    message: '',
    ton: TonEtat.accent,
  );
}

/// Pose autour de la salle : le battement (premier appareil), le dialogue, et
/// l'attente (second appareil).
class SurveillanceSecondAppareil extends ConsumerStatefulWidget {
  /// Cree la surveillance.
  const SurveillanceSecondAppareil({
    required this.seanceId,
    required this.profilId,
    required this.actif,
    required this.onCeder,
    required this.child,
    super.key,
    this.rythme = rythmeBattementSalle,
    this.appareil,
    this.libelle,
  });

  /// La seance de la salle.
  final String seanceId;

  /// Le profil dont la place se garde : l'eleve de la salle (D6), sinon la
  /// personne connectee. `null` : rien a garder.
  final String? profilId;

  /// Vrai quand cet appareil est dans la salle (il bat, il peut etre invite a
  /// ceder). Faux avant l'entree et apres la sortie.
  final bool actif;

  /// Cet appareil cede la place : quitter la salle proprement, puis le dire.
  final Future<void> Function() onCeder;

  /// Le rythme du battement (reglable pour les tests).
  final Duration rythme;

  /// L'identifiant de cet appareil (reglable pour les tests).
  final String Function()? appareil;

  /// L'etiquette de cet appareil (reglable pour les tests).
  final String Function()? libelle;

  /// La salle.
  final Widget child;

  @override
  ConsumerState<SurveillanceSecondAppareil> createState() => _Etat();
}

class _Etat extends ConsumerState<SurveillanceSecondAppareil> {
  Timer? _minuteur;
  DemandePassage? _demande;
  bool _enCours = false;
  bool _echec = false;
  bool _cede = false;
  Timer? _effaceNote;

  String get _appareil => (widget.appareil ?? identifiantAppareilSalle)();
  String get _libelle => (widget.libelle ?? libelleAppareilCourant)();

  @override
  void initState() {
    super.initState();
    _armer();
  }

  @override
  void didUpdateWidget(SurveillanceSecondAppareil ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.actif != widget.actif || ancien.profilId != widget.profilId) {
      _armer();
    }
  }

  void _armer() {
    _minuteur?.cancel();
    _minuteur = null;
    if (!widget.actif || widget.profilId == null) {
      if (_demande != null) setState(() => _demande = null);
      return;
    }
    unawaited(_battre());
    _minuteur = Timer.periodic(widget.rythme, (_) => unawaited(_battre()));
  }

  Future<void> _battre() async {
    final String? profil = widget.profilId;
    if (!mounted || !widget.actif || profil == null || _cede) return;
    try {
      final BattementSalle b = await ref
          .read(portSecondAppareilProvider)
          .battement(
            seanceId: widget.seanceId,
            profilId: profil,
            appareilId: _appareil,
            libelle: _libelle,
          );
      if (!mounted) return;
      if (b.cede) {
        await _ceder();
        return;
      }
      if (b.demande != _demande) {
        setState(() {
          _demande = b.demande;
          if (b.demande == null) _echec = false;
        });
      }
    } on Object {
      // Un battement perdu n'est pas une coupure : le serveur ne tient un
      // appareil pour silencieux qu'apres 30 secondes, le suivant rattrape.
    }
  }

  Future<void> _ceder() async {
    if (_cede) return;
    _cede = true;
    _minuteur?.cancel();
    setState(() => _demande = null);
    await widget.onCeder();
  }

  Future<void> _repondre(bool accepter) async {
    final DemandePassage? d = _demande;
    if (d == null || _enCours) return;
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(portSecondAppareilProvider)
          .repondre(d.id, accepter: accepter);
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _demande = null;
      });
      if (accepter) await _ceder();
    } on Object {
      if (mounted) {
        setState(() {
          _enCours = false;
          _echec = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _effaceNote?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PassageSalle passage = ref.watch(passageSalleProvider);
    ref.listen<PassageSalle>(passageSalleProvider, (
      PassageSalle? _,
      PassageSalle suivant,
    ) {
      if (suivant.phase == PhasePassage.ancienSilencieux) {
        _effaceNote?.cancel();
        _effaceNote = Timer(const Duration(seconds: 8), () {
          if (mounted) ref.read(passageSalleProvider.notifier).effacer();
        });
      }
    });
    final bool attend =
        passage.phase == PhasePassage.attente ||
        passage.phase == PhasePassage.horsLigne;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (attend)
          Positioned.fill(
            child: ColoredBox(
              color: AppPalette.of(context).surfaceCanvas.background,
              child: AttentePassageAppareil(
                phase: passage.phase,
                libelleAutre: passage.libelleAutre,
                onAnnuler: () =>
                    ref.read(passageSalleProvider.notifier).annuler(),
              ),
            ),
          ),
        if (passage.phase == PhasePassage.ancienSilencieux)
          const PositionedDirectional(
            top: AppSpacing.lg,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            child: NoteAncienAppareil(),
          ),
        if (_demande != null && widget.actif)
          Positioned.fill(
            child: Stack(
              children: <Widget>[
                ModalBarrier(
                  dismissible: false,
                  color: AppPalette.of(context).surfaceInverse.background
                      .withValues(alpha: 0.6),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: DialogueAutreAppareil(
                        libelle: _demande!.libelle,
                        enCours: _enCours,
                        echec: _echec,
                        onAccepter: () => unawaited(_repondre(true)),
                        onRefuser: () => unawaited(_repondre(false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
