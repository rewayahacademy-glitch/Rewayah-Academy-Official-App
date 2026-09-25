import 'package:flutter/material.dart';

import '../capacites/port_finance_foyer.dart';
import '../finance/format_montant.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/apparition_douce.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// La carte resume d'un solde (S01, S02 ; planche « Soldes du foyer ») : le
/// total du foyer, un sous-total par devise, ou le solde d'un profil.
///
/// Les montants sont ceux du serveur, mis en forme, jamais recalcules. Un
/// solde inconnu se dit en mots (« Solde inconnu pour le moment ») : **jamais
/// un « 0 »**, qui passerait pour un solde vide. Un total incomplet le dit
/// aussi, sous les montants.
class ResumeSolde extends StatelessWidget {
  /// Le total du foyer : un sous-total par devise, tel que le serveur les rend.
  const ResumeSolde.foyer({
    required this.totaux,
    required this.complet,
    super.key,
    this.legende,
    this.action,
  }) : prenom = null,
       solde = null;

  /// Le solde d'un profil.
  const ResumeSolde.profil({
    required String this.prenom,
    required SoldeProfil this.solde,
    super.key,
    this.legende,
    this.action,
  }) : totaux = const <TotalSoldes>[],
       complet = true;

  /// Les sous-totaux par devise (foyer) ; vide pour un profil.
  final List<TotalSoldes> totaux;

  /// Faux quand un solde du foyer est inconnu : le total le dit.
  final bool complet;

  /// Le prenom du profil ; `null` pour le foyer.
  final String? prenom;

  /// Le solde du profil ; `null` pour le foyer.
  final SoldeProfil? solde;

  /// Une phrase sous le montant, rendue par l'ecran (« Reparties entre 3
  /// profils »).
  final String? legende;

  /// L'action principale sous le resume (« Recharger »), fournie par l'ecran.
  final Widget? action;

  /// Les montants lisibles, un par devise ; vide si rien n'est connu.
  List<String> get _montants {
    final SoldeProfil? lu = solde;
    if (lu != null) {
      final int? mineur = lu.montantMineur;
      final String? devise = lu.devise;
      return mineur == null || devise == null
          ? const <String>[]
          : <String>[formaterMontant(mineur, devise)];
    }
    return <String>[
      for (final TotalSoldes total in totaux)
        formaterMontant(total.montantMineur, total.devise),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle secondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final List<String> montants = _montants;
    final String? nom = prenom;
    final String titre = nom == null
        ? t.finance.totalFoyer
        : t.finance.soldeDe(prenom: nom);
    final String? inconnu = montants.isNotEmpty
        ? null
        : solde != null
        ? t.finance.soldeInconnu
        : t.finance.aucunTotal;

    return AppCard(
      actions: action,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    titre,
                    style: palette.inkMuted.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  ApparitionDouce(
                    child: inconnu != null
                        ? Text(
                            inconnu,
                            style: palette.inkStrong.applyTo(
                              textes.titleLarge ?? const TextStyle(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (final String montant in montants)
                                Text(
                                  montant,
                                  style: AppTypography.tabulaire(
                                    palette.inkStrong.applyTo(
                                      textes.headlineMedium ??
                                          const TextStyle(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  if (solde != null && inconnu != null) ...<Widget>[
                    Ecart.vXs,
                    Text(t.finance.soldeInconnuDetail, style: secondaire),
                  ],
                  if (legende != null) ...<Widget>[
                    Ecart.vXs,
                    Text(legende!, style: secondaire),
                  ],
                  if (!complet) ...<Widget>[
                    Ecart.vXs,
                    Text(t.finance.totalIncomplet, style: secondaire),
                  ],
                ],
              ),
            ),
          ),
          Ecart.hMd,
          ExcludeSemantics(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xxxl),
              child: Icon(
                prenom == null ? AppIcons.foyer.repos : AppIcons.finance.repos,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
