import 'package:flutter/material.dart';

import '../../comptable/modeles_comptable.dart';
import '../../finance/montant.dart';
import '../../i18n/strings.g.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../montant_argent.dart';
import '../montant_sensible.dart';

/// Une date du Comptable en mots : « 4 octobre 2026 ».
String dateComptable(DateTime date) {
  final DateTime locale = date.toLocal();
  return t.comptable.commun.date(
    jour: locale.day,
    mois: t.commun.dates.mois[locale.month - 1],
    annee: locale.year,
  );
}

/// Une ligne du journal d'une operation (`FinanceActivityRow`, spec §48 ;
/// CPT-F) : l'objet, puis « initiateur · date », puis « ancien etat → nouvel
/// etat » et la reference ; le montant, **masquable**, au bord de fin.
///
/// S'inspire de `LigneTransaction` (fichier de la vague Finance, non
/// modifie) sans la recopier : la difference est le montant sensible et les
/// champs du journal. Le frontend n'invente rien : chaque champ absent de la
/// source n'est simplement pas rendu. Utilisee par W01, W03, W04, W05.
///
/// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).
class LigneActivite extends StatelessWidget {
  /// Cree la ligne.
  const LigneActivite(this.entree, {super.key});

  /// L'entree du journal.
  final EntreeJournal entree;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String? avant = entree.ancienEtat;
    final String? apres = entree.nouvelEtat;
    final String? transition = avant != null && apres != null
        ? t.comptable.commun.activiteTransition(avant: avant, apres: apres)
        : apres ?? avant;
    final String? reference = entree.reference;
    final Montant? montant = entree.montant;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(entree.objet, style: fort),
                  Ecart.vXs,
                  Text(
                    t.comptable.commun.activiteInitiateurDate(
                      initiateur: entree.initiateur,
                      date: dateComptable(entree.date),
                    ),
                    style: attenue,
                  ),
                  if (transition != null) ...<Widget>[
                    Ecart.vXs,
                    Text(transition, style: attenue),
                  ],
                  if (reference != null) ...<Widget>[
                    Ecart.vXs,
                    Text(
                      t.comptable.commun.activiteReference(
                        reference: reference,
                      ),
                      style: attenue,
                    ),
                  ],
                ],
              ),
            ),
            if (montant != null) ...<Widget>[
              Ecart.hLg,
              MontantSensible(
                montant,
                signe: true,
                taille: TailleMontant.corps,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
