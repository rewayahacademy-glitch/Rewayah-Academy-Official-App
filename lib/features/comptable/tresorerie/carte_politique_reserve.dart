import 'package:flutter/material.dart';

import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/montant_sensible.dart';
import 'tresorerie_donnees.dart';

/// La politique de la Reserve strategique **en lecture** pour le Comptable
/// (spec §9.2 a §9.6 ; CPT-BR-12) : mode de calcul, alimentation
/// automatique (montant masquable, aucune plage codee : 10 USD comme
/// 1 000 000 USD, R-FIN-08, 09), cadence, seuil, regle de retrait, version.
/// Le Comptable l'applique ; l'ecriture est a la Direction (CPT-DIR-1).
class CartePolitiqueReserve extends StatelessWidget {
  /// Cree la carte.
  const CartePolitiqueReserve(this.politique, {super.key});

  /// La politique rendue par la source.
  final PolitiqueReserve politique;

  /// La cle de la ligne « Alimentation automatique ».
  static const Key cleAlimentation = ValueKey<String>('politique-alimentation');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final tr = t.comptable.tresorerie;
    final c = t.comptable.commun;
    final PolitiqueReserve p = politique;
    final Montant? auto = p.montantAuto;
    final int? pourcent = p.pourcentageAutoPourMille;
    final int? seuil = p.seuilAlertePourMille;
    final DateTime? effet = p.dateEffet;
    final String regle = switch (p.regleAlimentation) {
      RegleAlimentation.desactivee => tr.regle.desactivee,
      RegleAlimentation.montantFixe => tr.regle.montantFixe,
      RegleAlimentation.pourcentage =>
        pourcent == null
            ? c.aucuneValeur
            : tr.regle.pourcentage(pourcent: pourcentDepuisPourMille(pourcent)),
      RegleAlimentation.jusquAObjectif => tr.regle.jusquAObjectif,
      RegleAlimentation.proposee => tr.regle.proposee,
    };
    final String cadence = switch (p.cadence) {
      CadenceAlimentation.clotureCycle => tr.cadences.clotureCycle,
      CadenceAlimentation.hebdomadaire => tr.cadences.hebdomadaire,
      CadenceAlimentation.mensuelle => tr.cadences.mensuelle,
      CadenceAlimentation.apresEncaissementConsolide =>
        tr.cadences.apresEncaissementConsolide,
      CadenceAlimentation.manuelle => tr.cadences.manuelle,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              tr.politiqueTitre,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          Text(
            tr.politiquePhrase,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
          _Ligne(
            libelle: c.modeCalcul,
            valeur: Text(
              p.modeObjectif == ModeObjectifReserve.couvertureMois
                  ? c.modeCouvertureMois
                  : c.modeMontantFixe,
            ),
          ),
          _Ligne(
            key: cleAlimentation,
            libelle: tr.alimentationAuto,
            valeur: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(regle),
                if (p.regleAlimentation == RegleAlimentation.montantFixe &&
                    auto != null)
                  MontantSensible(auto),
              ],
            ),
          ),
          _Ligne(libelle: tr.cadence, valeur: Text(cadence)),
          if (seuil != null)
            _Ligne(
              libelle: tr.alimentationAuto,
              valeur: Text(
                tr.seuilAlerte(pourcent: pourcentDepuisPourMille(seuil)),
              ),
              masquerLibelle: true,
            ),
          Ecart.vSm,
          Text(
            p.retraitSoumisValidation
                ? tr.retraitValidation
                : tr.retraitSansValidation,
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          Text(
            effet == null
                ? tr.version(version: p.version)
                : tr.versionDepuis(
                    version: p.version,
                    date: dateComptable(effet),
                  ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un libelle attenue, puis sa valeur dessous : jamais cote a cote, pour
/// tenir a 320 avec le texte a 200 %.
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.libelle,
    required this.valeur,
    super.key,
    this.masquerLibelle = false,
  });

  final String libelle;
  final Widget valeur;
  final bool masquerLibelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!masquerLibelle) ...<Widget>[
              Text(
                libelle,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              Ecart.vXs,
            ],
            DefaultTextStyle.merge(
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
              child: valeur,
            ),
          ],
        ),
      ),
    );
  }
}
