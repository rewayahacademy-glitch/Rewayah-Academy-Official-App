// LETTRE-CANDIDATS (directeur, 20/11/2026, 23 h) : les interactions du guide.
//
// Sous chaque partie : « J'aime » et « Pas clair », avec les totaux de tous
// les lecteurs (publics) ; « Commenter cette partie » ouvre le fil du lecteur,
// que seuls lui, la direction et Praxis lisent. L'avis s'affiche tout de suite
// et revient en arriere si le serveur refuse (DECISION-FLUIDITE) ; un
// commentaire attend la confirmation du serveur avant d'entrer dans le fil.
// Tant que le serveur des interactions n'est pas branche, rien ne s'affiche :
// la lecture du guide n'en depend pas.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bouton_icone.dart';
import '../../../core/widgets/zone_saisie.dart';
import 'barre_avis.dart';
import 'port_interactions_guide.dart';

/// L'etat des interactions du lecteur.
class InteractionsGuideNotifier extends AsyncNotifier<InteractionsGuide> {
  @override
  Future<InteractionsGuide> build() =>
      ref.watch(portInteractionsProvider).lire();

  /// Donne [avis] sur [partie] : affiche tout de suite, confirme au serveur,
  /// revient en arriere s'il refuse. Rend vrai quand le serveur a confirme.
  Future<bool> donnerAvis(String partie, AvisGuide? avis) async {
    final InteractionsGuide? avant = state.value;
    final AvisPartie? ligne = avant?.avis[partie];
    if (avant == null || ligne == null) return false;
    state = AsyncData<InteractionsGuide>(_avecLigne(avant, ligne.avec(avis)));
    try {
      final AvisPartie confirmee = await ref
          .read(portInteractionsProvider)
          .donnerAvis(partie: partie, avis: avis);
      final InteractionsGuide? courant = state.value;
      if (courant != null) {
        state = AsyncData<InteractionsGuide>(_avecLigne(courant, confirmee));
      }
      return true;
    } on Exception {
      state = AsyncData<InteractionsGuide>(avant);
      return false;
    }
  }

  /// Ecrit un commentaire ; il entre dans le fil une fois confirme. Rend le
  /// commentaire, ou nul si le serveur ne l'a pas confirme.
  Future<CommentaireGuide?> commenter(String partie, String corps) async {
    try {
      final CommentaireGuide c = await ref
          .read(portInteractionsProvider)
          .commenter(partie: partie, corps: corps);
      final InteractionsGuide? courant = state.value;
      if (courant != null) {
        state = AsyncData<InteractionsGuide>(
          InteractionsGuide(
            avis: courant.avis,
            commentaires: <CommentaireGuide>[...courant.commentaires, c],
          ),
        );
      }
      return c;
    } on Exception {
      return null;
    }
  }

  static InteractionsGuide _avecLigne(InteractionsGuide g, AvisPartie l) =>
      InteractionsGuide(
        avis: <String, AvisPartie>{...g.avis, l.code: l},
        commentaires: g.commentaires,
      );
}

/// Les interactions du lecteur.
final AsyncNotifierProvider<InteractionsGuideNotifier, InteractionsGuide>
interactionsGuideProvider =
    AsyncNotifierProvider<InteractionsGuideNotifier, InteractionsGuide>(
      InteractionsGuideNotifier.new,
    );

/// Les interactions sous une partie.
class InteractionsPartie extends ConsumerStatefulWidget {
  /// Cree le bloc de la partie [code].
  const InteractionsPartie({required this.code, super.key});

  /// Le code de la partie (`p1` a `p14`).
  final String code;

  /// La cle du bouton « J'aime » de la partie [code].
  static Key cleJaime(String code) => ValueKey<String>('guide-jaime-$code');

  /// La cle du bouton « Pas clair » de la partie [code].
  static Key clePasClair(String code) =>
      ValueKey<String>('guide-pas-clair-$code');

  /// La cle du lien « Commenter » de la partie [code].
  static Key cleCommenter(String code) =>
      ValueKey<String>('guide-commenter-$code');

  @override
  ConsumerState<InteractionsPartie> createState() => _EtatInteractions();
}

class _EtatInteractions extends ConsumerState<InteractionsPartie> {
  bool _echec = false;

  Future<void> _avis(AvisPartie ligne, AvisGuide choisi) async {
    // Toucher l'avis deja donne le retire.
    final AvisGuide? avis = ligne.monAvis == choisi ? null : choisi;
    final bool ok = await ref
        .read(interactionsGuideProvider.notifier)
        .donnerAvis(widget.code, avis);
    if (mounted) setState(() => _echec = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final InteractionsGuide? lu = ref.watch(interactionsGuideProvider).value;
    final AvisPartie? ligne = lu?.avis[widget.code];
    // Serveur pas encore branche, en chargement ou en echec : rien. La
    // lecture du guide reste entiere.
    if (lu == null || ligne == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final l = t.recrutement.lettre;
    final int mesCommentaires = lu.commentaires
        .where(
          (CommentaireGuide c) =>
              c.partie == widget.code && c.auteur == AuteurCommentaire.moi,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BarreAvis(
          ligne: ligne,
          mesCommentaires: mesCommentaires,
          cleJaime: InteractionsPartie.cleJaime(widget.code),
          clePasClair: InteractionsPartie.clePasClair(widget.code),
          cleCommenter: InteractionsPartie.cleCommenter(widget.code),
          onAvis: (AvisGuide a) => unawaited(_avis(ligne, a)),
          onCommenter: () => unawaited(
            AppBottomSheet.ouvrir<void>(
              context,
              titre: l.filTitre,
              constructeur: (BuildContext _) =>
                  FilCommentaires(code: widget.code),
            ),
          ),
        ),
        if (_echec)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l.echecAvis,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Le fil du lecteur sur une partie, et le champ pour ecrire.
class FilCommentaires extends ConsumerStatefulWidget {
  /// Cree le fil de la partie [code].
  const FilCommentaires({required this.code, super.key});

  /// Le code de la partie.
  final String code;

  /// La cle du champ.
  static const Key cleChamp = ValueKey<String>('guide-champ');

  /// La cle du bouton d'envoi.
  static const Key cleEnvoyer = ValueKey<String>('guide-envoyer');

  @override
  ConsumerState<FilCommentaires> createState() => _EtatFil();
}

class _EtatFil extends ConsumerState<FilCommentaires> {
  final TextEditingController _texte = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final String corps = _texte.text.trim();
    if (corps.isEmpty || _envoi) return;
    final l = t.recrutement.lettre;
    if (corps.length > longueurMaxCommentaire) {
      setState(() => _erreur = l.tropLong(max: longueurMaxCommentaire));
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final CommentaireGuide? c = await ref
        .read(interactionsGuideProvider.notifier)
        .commenter(widget.code, corps);
    if (!mounted) return;
    setState(() {
      _envoi = false;
      if (c == null) {
        _erreur = l.echecEnvoi;
      } else {
        _texte.clear();
      }
    });
  }

  String _auteur(AuteurCommentaire a) {
    final l = t.recrutement.lettre;
    return switch (a) {
      AuteurCommentaire.moi => l.auteurMoi,
      AuteurCommentaire.direction => l.auteurDirection,
      AuteurCommentaire.praxis => l.auteurPraxis,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final l = t.recrutement.lettre;
    final List<CommentaireGuide> fil =
        (ref.watch(interactionsGuideProvider).value?.commentaires ??
                const <CommentaireGuide>[])
            .where((CommentaireGuide c) => c.partie == widget.code)
            .toList();
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    // Une bulle ne prend jamais toute la largeur : on voit de quel cote elle est.
    final double largeurBulle = math.min(
      AppPage.largeurEtatVide,
      MediaQuery.sizeOf(context).width * 0.78,
    );
    // Les bulles, comme dans la messagerie : les siennes au bord de fin,
    // couleur douce de la marque ; celles de la direction et de Praxis au bord
    // de debut, sur la surface. Aucun contour.
    Widget bulle(CommentaireGuide c) {
      final bool moi = c.auteur == AuteurCommentaire.moi;
      final AppColorPair fond = moi
          ? palette.washAccent
          : palette.surfaceSunken;
      return Semantics(
        // Le lecteur d'ecran dit qui parle, meme quand la bulle ne l'ecrit pas.
        label: '${_auteur(c.auteur)} : ${c.corps}',
        container: true,
        excludeSemantics: true,
        child: Align(
          alignment: moi
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: largeurBulle),
            child: Column(
              crossAxisAlignment: moi
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!moi)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(_auteur(c.auteur), style: muet),
                  ),
                Material(
                  color: fond.background,
                  shape: AppRadius.coinContinu(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(c.corps, style: fond.applyTo(corps)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(
                AppIcons.verrou.resoudre(),
                size: AppSpacing.lg,
                color: palette.inkMuted.asIconTheme().color,
              ),
            ),
            Ecart.hSm,
            Expanded(child: Text(l.filPrive, style: muet)),
          ],
        ),
        Ecart.vLg,
        if (fil.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(l.filVide, style: muet, textAlign: TextAlign.center),
          ),
        for (final CommentaireGuide c in fil) ...<Widget>[bulle(c), Ecart.vSm],
        Ecart.vSm,
        // Le champ et sa fleche d'envoi, sur une seule ligne, comme dans la
        // messagerie de l'application.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: ZoneSaisie(
                controleur: _texte,
                cleChamp: FilCommentaires.cleChamp,
                libelle: l.champ,
                libelleVisible: false,
                minLignes: 1,
                maxLignes: 5,
                erreur: _erreur,
              ),
            ),
            Ecart.hSm,
            Transform.flip(
              flipX: rtl,
              child: BoutonIcone(
                key: FilCommentaires.cleEnvoyer,
                icone: AppIcons.envoyerMessage,
                libelle: l.envoyer,
                forme: FormeBoutonIcone.disque,
                onPress: () => unawaited(_envoyer()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
