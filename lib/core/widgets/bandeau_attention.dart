import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

/// Un bandeau qui demande l'attention (`AttentionBanner`, guide Finance V4
/// §1.7, §5.4 ; FI-3b) : « Accès à régulariser / Il manque 8 USD pour
/// financer janvier. », « Paiement en cours de confirmation / Ne payez pas
/// une seconde fois. ».
///
/// Trois signaux, jamais la couleur seule : une icone, un titre, la
/// consequence en une phrase (K-58). La paire douce vient du ton
/// ([PaireDeTonEtat]), jamais d'une couleur choisie par l'ecran. Une seule
/// action au plus, un lien ([action]) : le bandeau n'est jamais l'action
/// principale de l'ecran.
///
/// A un enfant, l'ecran ne passe jamais une cause financiere (guide §1.7 :
/// « Accès à cette classe temporairement indisponible »), ce composant ne
/// redige rien lui-meme.
class BandeauAttention extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauAttention({
    required this.titre,
    required this.message,
    super.key,
    this.ton = TonEtat.avertissement,
    this.action,
  });

  /// Ce qui se passe, en quelques mots.
  final String titre;

  /// La consequence ou la cause utile, en une phrase.
  final String message;

  /// La famille de l'attention : avertissement par defaut, alerte pour un
  /// echec, accent pour une attente sans faute.
  final TonEtat ton;

  /// Un lien vers ce qui regle la situation (`LienFleche`), au plus un.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.paireDe(ton);
    final AppIcon icone = switch (ton) {
      TonEtat.alerte || TonEtat.avertissement => AppIcons.avertissement,
      _ => AppIcons.info,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: paire.decoration(borderRadius: AppRadius.arrondiMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: IconTheme(
                  data: IconThemeData(
                    color: paire.onBackground,
                    size: AppSpacing.xl,
                  ),
                  child: Icon(icone.repos),
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      // R8-03 : entre les mots, jamais dans un mot
                      // (« temporaire / ment »).
                      child: TexteSansCoupure(
                        titre,
                        style: paire.applyTo(
                          textes.titleSmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                    Ecart.vXs,
                    TexteSansCoupure(
                      message,
                      style: paire.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    if (action case final Widget a) ...<Widget>[Ecart.vSm, a],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
