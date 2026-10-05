import 'package:flutter/material.dart';

import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/status_pill.dart';
import 'tresorerie_donnees.dart';

/// Un coffre de tresorerie (`TreasuryVaultCard`, spec §8.1, §32 ; CPT-TRES-1).
///
/// Le nom canonique, ce que le coffre contient (§8.1), le montant
/// **masquable**, la nature protegee ou non ecrite en toutes lettres (jamais
/// par la seule couleur, §46), la part de la tresorerie detenue **rendue par
/// la source** en pour mille (jamais calculee ici, DR-08) et la regle d'usage
/// quand la source en rend une. En lecture seule : aucune allocation ne se
/// modifie depuis une carte (§10.4, « masquer un deficit »).
class CarteCoffre extends StatelessWidget {
  /// Cree la carte.
  const CarteCoffre(this.solde, {super.key});

  /// Le solde rendu par la source.
  final SoldeCoffre solde;

  /// La cle de la carte d'un coffre, pour les tests et la recette.
  static Key clePour(Coffre coffre) =>
      ValueKey<String>('coffre-${coffre.name}');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final tr = t.comptable.tresorerie;
    final Coffre coffre = solde.coffre;
    final int? part = solde.partPourMille;
    final String? regle = solde.regleUsage;
    return AppCard(
      key: clePour(coffre),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(
                  coffre == Coffre.reserveStrategique
                      ? AppIcons.reserve.repos
                      : AppIcons.coffre.repos,
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    libelleCoffre(coffre),
                    style: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Ecart.vXs,
          Text(_description(coffre), style: attenue),
          Ecart.vMd,
          MontantSensible(solde.montant, taille: TailleMontant.titre),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusPill(
                libelle: coffre.protege
                    ? tr.coffreProtege
                    : tr.coffreNonProtege,
                ton: coffre.protege ? TonEtat.accent : TonEtat.neutre,
              ),
              if (part != null)
                Text(
                  tr.partDetenue(part: pourcentDepuisPourMille(part)),
                  style: attenue,
                ),
            ],
          ),
          if (regle != null) ...<Widget>[
            Ecart.vSm,
            Text(tr.regleUsage(regle: regle), style: attenue),
          ],
        ],
      ),
    );
  }

  static String _description(Coffre coffre) {
    final d = t.comptable.tresorerie.descriptions;
    return switch (coffre) {
      Coffre.fondsClientsEngages => d.fondsClientsEngages,
      Coffre.paieADecaisser => d.paieADecaisser,
      Coffre.chargesEssentielles => d.chargesEssentielles,
      Coffre.taxesObligations => d.taxesObligations,
      Coffre.reserveStrategique => d.reserveStrategique,
      Coffre.enTransit => d.enTransit,
      Coffre.tresorerieLibre => d.tresorerieLibre,
    };
  }
}
