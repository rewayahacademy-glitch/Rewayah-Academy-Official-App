import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../finance/politique_commerciale.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Un moyen de paiement a choisir (`PaymentMethodRow`, guide Finance V4
/// §1.6, §5.3 ; FI-3b).
///
/// - **La carte entiere se presse** (`AppCard`), retenue par un fond
///   d'accent ET la semantique « selectionne » : jamais la couleur seule ;
/// - **seul le paiement web est rendu au lancement** (`RailPaiement.webStripe`,
///   FI10). Un rail StoreKit ou Play ne rend **rien** : aucun bouton App Store
///   ou Play n'existe dans la version de lancement, meme par erreur d'ecran ;
/// - la phrase dit la consequence (K-58) : aucun debit avant la confirmation.
class LigneMoyenPaiement extends StatelessWidget {
  /// Cree la ligne.
  const LigneMoyenPaiement({
    required this.rail,
    super.key,
    this.retenu = false,
    this.onPress,
  });

  /// Le rail de paiement.
  final RailPaiement rail;

  /// Vrai pour le moyen retenu.
  final bool retenu;

  /// Retient ce moyen ; `null` quand le choix est impossible (hors ligne).
  final VoidCallback? onPress;

  /// Vrai pour un rail montre au lancement.
  static bool estMontre(RailPaiement rail) => rail == RailPaiement.webStripe;

  @override
  Widget build(BuildContext context) {
    if (!estMontre(rail)) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Hors ligne, le choix est impossible (revue FI-3-R m3) : le lecteur
    // d'ecran l'annonce desactive, et l'icone et le nom passent en encre
    // attenuee. Jamais la couleur seule : la semantique le dit aussi.
    final bool actif = onPress != null;
    return Semantics(
      enabled: actif,
      selected: retenu,
      inMutuallyExclusiveGroup: true,
      child: AppCard(
        selectionnee: retenu,
        onPress: onPress,
        child: Row(
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: (actif ? palette.inkAccent : palette.inkMuted)
                    .asIconTheme(size: AppSpacing.xxl),
                child: Icon(AppIcons.finance.repos),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TexteSansCoupure(
                    t.argent.moyen.webStripe,
                    style: (actif ? palette.inkStrong : palette.inkMuted)
                        .applyTo(textes.titleSmall ?? const TextStyle()),
                  ),
                  // R8-03 : « confirmation. » entier a 320 px et 200 %.
                  TexteSansCoupure(
                    t.argent.moyen.webStripeDetail,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            if (retenu) ...<Widget>[
              Ecart.hSm,
              ExcludeSemantics(
                child: IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                  child: Icon(AppIcons.succes.actif),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
