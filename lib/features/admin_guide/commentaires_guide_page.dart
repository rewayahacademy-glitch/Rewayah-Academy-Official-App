import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import 'port_commentaires_guide.dart';

/// GUIDE-COMMENTAIRES (directeur, 21/11/2026 : « il faut ouvrir la page des
/// commentaires cote admin ») : la direction lit les commentaires du guide de
/// l'enseignant, partie par partie, les moins claires d'abord, et repond dans
/// le fil de chaque lecteur. Circuit a part, hors de la messagerie
/// (directeur, 21/11/2026).
class CommentairesGuidePage extends ConsumerWidget {
  /// Cree la page.
  const CommentairesGuidePage({super.key});

  /// A partir de cette largeur de contenu, deux colonnes de cartes.
  static const double largeurDeuxColonnes = 960;

  /// La cle de la carte d'une partie.
  static ValueKey<String> clePartie(String code) =>
      ValueKey<String>('guide-com-partie-$code');

  /// La cle du champ de reponse au fil de [lecteur] sur [code].
  static ValueKey<String> cleChamp(String code, String lecteur) =>
      ValueKey<String>('guide-com-champ-$code-$lecteur');

  /// La cle du bouton « Repondre » du fil de [lecteur] sur [code].
  static ValueKey<String> cleRepondre(String code, String lecteur) =>
      ValueKey<String>('guide-com-repondre-$code-$lecteur');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.guideCommentaires;
    final AsyncValue<List<PartieGuideDirection>> lu = ref.watch(
      commentairesGuideProvider,
    );
    final List<SousLien> pages = pagesOperations();
    final Widget corps;
    if (lu.hasValue) {
      final List<PartieGuideDirection> parties = lu.requireValue;
      // Sur ordinateur, jamais une carte de telephone etiree sur toute la
      // largeur (directeur, 21/11/2026) : deux colonnes, dans l'ordre de
      // lecture, ligne par ligne ; au telephone, une seule.
      corps = LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) {
          final List<Widget> cartes = <Widget>[
            for (final PartieGuideDirection p in parties)
              _CartePartie(key: clePartie(p.code), partie: p),
          ];
          if (c.maxWidth < CommentairesGuidePage.largeurDeuxColonnes) {
            return PileCartes(children: cartes);
          }
          return PileCartes(
            children: <Widget>[
              for (int i = 0; i < cartes.length; i += 2)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: cartes[i]),
                    Ecart.hLg,
                    Expanded(
                      child: i + 1 < cartes.length
                          ? cartes[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
            ],
          );
        },
      );
    } else if (lu.hasError) {
      corps = EmptyState(
        message: lu.error is CapaciteIndisponible ? l.indisponible : l.erreur,
        icone: AppIcons.avertissement,
        libelleAction: lu.error is CapaciteIndisponible
            ? null
            : t.commun.reessayer,
        onAction: lu.error is CapaciteIndisponible
            ? null
            : () => ref.invalidate(commentairesGuideProvider),
      );
    } else {
      corps = const Skeleton.liste(lignes: 4);
    }
    return PageShell(
      titre: l.titre,
      entete: SousNavigationDomaine(
        onglets: pages,
        indexActif: pages.indexWhere(
          (SousLien o) => o.chemin == Routes.adminOperationsGuide,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurLecture,
              ),
              child: Text(
                l.intro,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
          Ecart.vLg,
          corps,
        ],
      ),
    );
  }
}

class _CartePartie extends StatelessWidget {
  const _CartePartie({required this.partie, super.key});

  final PartieGuideDirection partie;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.guideCommentaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final int rang = int.tryParse(partie.code.substring(1)) ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('$rang. ${partie.titre}', style: textes.titleMedium),
          Ecart.vXs,
          Text(
            l.totaux(jaime: partie.jaime, pasClair: partie.pasClair),
            style: muet,
          ),
          Ecart.vLg,
          if (partie.fils.isEmpty)
            Text(l.aucun, style: muet)
          else
            for (final FilGuide f in partie.fils) ...<Widget>[
              _Fil(code: partie.code, fil: f),
              Ecart.vLg,
            ],
        ],
      ),
    );
  }
}

class _Fil extends ConsumerStatefulWidget {
  const _Fil({required this.code, required this.fil});

  final String code;
  final FilGuide fil;

  @override
  ConsumerState<_Fil> createState() => _EtatFil();
}

class _EtatFil extends ConsumerState<_Fil> {
  final TextEditingController _texte = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _repondre() async {
    final String corps = _texte.text.trim();
    if (corps.isEmpty || _envoi || widget.fil.messages.isEmpty) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portCommentairesGuideProvider)
          .repondre(commentaire: widget.fil.messages.last.id, corps: corps);
      if (!mounted) return;
      _texte.clear();
      ref.invalidate(commentairesGuideProvider);
      setState(() => _envoi = false);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = t.admin.guideCommentaires.echec;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.guideCommentaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    String auteur(AuteurMessageGuide a) => switch (a) {
      AuteurMessageGuide.lecteur => widget.fil.lecteur,
      AuteurMessageGuide.direction => l.direction,
      AuteurMessageGuide.praxis => l.praxis,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(widget.fil.lecteur, style: textes.titleSmall)),
            if (widget.fil.attendReponse)
              StatusPill(libelle: l.attend, ton: TonEtat.avertissement),
          ],
        ),
        Ecart.vSm,
        for (final MessageGuide m in widget.fil.messages) ...<Widget>[
          Text(auteur(m.auteur), style: muet),
          Text(m.corps, style: textes.bodyMedium),
          Ecart.vSm,
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: ZoneSaisie(
                controleur: _texte,
                cleChamp: CommentairesGuidePage.cleChamp(
                  widget.code,
                  widget.fil.lecteur,
                ),
                libelle: l.champ(nom: widget.fil.lecteur),
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
                key: CommentairesGuidePage.cleRepondre(
                  widget.code,
                  widget.fil.lecteur,
                ),
                icone: AppIcons.envoyerMessage,
                libelle: l.repondre,
                forme: FormeBoutonIcone.disque,
                onPress: () => unawaited(_repondre()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
