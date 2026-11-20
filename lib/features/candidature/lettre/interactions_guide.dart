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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bouton_outil.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/zone_saisie.dart';
import 'port_lettre.dart';

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
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            // Choix de formulaire, pas un filtre : deux avis sur la partie.
            BoutonOutil(
              key: InteractionsPartie.cleJaime(widget.code),
              icone: AppIcons.coeur,
              libelle: '${l.jaime} ${ligne.jaime}',
              avecLibelle: true,
              retenu: ligne.monAvis == AvisGuide.jaime,
              iconeActive: ligne.monAvis == AvisGuide.jaime,
              onPress: () => unawaited(_avis(ligne, AvisGuide.jaime)),
            ),
            BoutonOutil(
              key: InteractionsPartie.clePasClair(widget.code),
              icone: AppIcons.info,
              libelle: '${l.pasClair} ${ligne.pasClair}',
              avecLibelle: true,
              retenu: ligne.monAvis == AvisGuide.pasClair,
              iconeActive: ligne.monAvis == AvisGuide.pasClair,
              onPress: () => unawaited(_avis(ligne, AvisGuide.pasClair)),
            ),
          ],
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
        LienFleche(
          key: InteractionsPartie.cleCommenter(widget.code),
          alignerEnDebut: true,
          libelle: l.commenter,
          onPress: () => unawaited(
            AppBottomSheet.ouvrir<void>(
              context,
              titre: l.filTitre,
              constructeur: (BuildContext _) =>
                  FilCommentaires(code: widget.code),
            ),
          ),
        ),
        if (mesCommentaires > 0)
          Text(l.commentaires(n: mesCommentaires), style: muet),
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
    if (corps.isEmpty) return;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(l.filPrive, style: muet),
        Ecart.vLg,
        if (fil.isEmpty) Text(l.filVide, style: muet),
        for (final CommentaireGuide c in fil) ...<Widget>[
          Text(
            _auteur(c.auteur),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(c.corps, style: corps),
          Ecart.vLg,
        ],
        ZoneSaisie(
          controleur: _texte,
          cleChamp: FilCommentaires.cleChamp,
          libelle: l.champ,
          libelleVisible: true,
          minLignes: 2,
          erreur: _erreur,
        ),
        Ecart.vLg,
        ActionPrincipale(
          key: FilCommentaires.cleEnvoyer,
          libelle: l.envoyer,
          enCours: _envoi,
          onPress: () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}
