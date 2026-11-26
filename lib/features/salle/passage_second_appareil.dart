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
// [CoucheAutreAppareil] pose la question du premier appareil a la racine de
// l'application (par-dessus la salle reduite aussi) ; le battement qui la
// nourrit vit dans `GardePassage`, avec la connexion video.
// [PasserelleSecondAppareil] pose l'attente du second appareil autour de la
// salle. Tout se decide en base ; l'ecran ne fait que dire.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/garde_passage.dart';
import '../../core/video/second_appareil.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;

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

/// « Vous continuez sur l'autre appareil », dit apres une sortie propre quand
/// la page de la salle n'est pas a l'ecran (salle reduite, autre ecran).
class CarteCessionAppareil extends StatelessWidget {
  /// Cree la carte.
  const CarteCessionAppareil({required this.onCompris, super.key});

  /// Fermer le message.
  final VoidCallback onCompris;

  /// La carte.
  static const Key cle = Key('salle.passage.cession');

  /// « Compris ».
  static const Key comprisKey = Key('salle.passage.compris');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
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
                  t.salle.passage.cede,
                  style: palette.inkStrong.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vSm,
              Text(
                t.salle.passage.cedeDetail,
                style: palette.inkStrong.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
              Ecart.vLg,
              ActionPrincipale(
                key: comprisKey,
                libelle: t.salle.passage.compris,
                onPress: onCompris,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pose a la RACINE de l'application : la question « Laisser passer ? » arrive
/// par-dessus l'ecran ouvert (la salle, ou toute autre page quand la salle est
/// reduite dans l'ile). Le battement qui la nourrit ne vit pas ici : il suit la
/// connexion video ([GardePassage]).
class CoucheAutreAppareil extends ConsumerWidget {
  /// Cree la couche.
  const CoucheAutreAppareil({
    required this.child,
    super.key,
    this.enSalle = _jamais,
  });

  /// L'application.
  final Widget child;

  /// Vrai quand la page de la salle est a l'ecran (elle dit elle-meme la
  /// sortie ; la couche n'ajoute pas de message).
  final bool Function() enSalle;

  static bool _jamais() => false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatGardePassage etat = ref.watch(gardePassageProvider);
    final GardePassage garde = ref.read(gardePassageProvider.notifier);
    final bool cession = etat.cedeSeance != null && !enSalle();
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        if (etat.demande != null)
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
                        libelle: etat.demande!.libelle,
                        enCours: etat.enCours,
                        echec: etat.echec,
                        onAccepter: () =>
                            unawaited(garde.repondre(accepter: true)),
                        onRefuser: () =>
                            unawaited(garde.repondre(accepter: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (cession)
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
                      child: CarteCessionAppareil(
                        onCompris: garde.acquitterCession,
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

/// Pose autour de la page de la salle : l'attente du SECOND appareil (« Nous lui
/// demandons de confirmer… », avec Annuler) et la note « L'autre appareil ne
/// repondait plus ». L'attente vit ici parce qu'elle accompagne l'entree.
class PasserelleSecondAppareil extends ConsumerStatefulWidget {
  /// Cree la passerelle.
  const PasserelleSecondAppareil({required this.child, super.key});

  /// La salle.
  final Widget child;

  @override
  ConsumerState<PasserelleSecondAppareil> createState() => _EtatPasserelle();
}

class _EtatPasserelle extends ConsumerState<PasserelleSecondAppareil> {
  Timer? _effaceNote;

  @override
  void dispose() {
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
      ],
    );
  }
}
