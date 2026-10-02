import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/port_corpus_coran.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';

/// La feuille « Aller a » : page, sourate, juz, reference.
///
/// **Une seule entree pour les quatre navigations**, parce qu'un lecteur qui
/// cherche « Al-Kahf », « 18 », « juz 15 » ou « 2:255 » fait le meme geste. Le
/// tri se fait a la lecture de ce qu'il a tape, pas par quatre onglets.
///
/// **Ce qu'elle ne sait pas faire, elle le dit.** La recherche dans le texte du
/// Coran n'est pas branchee. L'index existe pourtant en base (mesure le
/// 21/09/2026 : `pg_trgm` installee, colonne generee `verset.texte_recherche`,
/// index trigramme `verset_recherche_idx`), mais aucun code ne l'interroge
/// encore. Afficher « aucun resultat » a un lecteur qui cherche un mot du Coran
/// serait faux : il croirait que le mot n'y est pas.
class FeuilleNavigationCoran extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleNavigationCoran({required this.onAller, super.key});

  /// Appele avec la page choisie.
  final void Function(int page) onAller;

  /// Ouvre la feuille.
  static Future<void> ouvrir(
    BuildContext context, {
    required void Function(int page) onAller,
  }) => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.tc.coran.navigation.titre,
    constructeur: (BuildContext context) =>
        FeuilleNavigationCoran(onAller: onAller),
  );

  @override
  ConsumerState<FeuilleNavigationCoran> createState() =>
      _FeuilleNavigationCoranEtat();
}

class _FeuilleNavigationCoranEtat
    extends ConsumerState<FeuilleNavigationCoran> {
  final TextEditingController _saisie = TextEditingController();
  List<ResultatRechercheCoran> _resultats = const <ResultatRechercheCoran>[];
  bool _aCherche = false;

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  Future<void> _chercher(String requete) async {
    final List<ResultatRechercheCoran> trouves = await ref
        .read(portNavigationCoranProvider)
        .rechercheRapide(requete);
    if (!mounted) {
      return;
    }
    setState(() {
      _resultats = trouves;
      _aCherche = requete.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _saisie,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: t.tc.coran.navigation.champ,
            helperText: t.tc.coran.navigation.indice,
            helperMaxLines: 2,
          ),
          onChanged: _chercher,
          onSubmitted: _chercher,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.tc.coran.navigation.limite,
          style: palette.inkMuted.applyTo(
            textes.labelSmall ?? const TextStyle(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_resultats.isEmpty && _aCherche)
          EmptyState(
            message: t.tc.coran.navigation.aucunResultat,
            invitation: t.tc.coran.navigation.aucunResultatDetail,
            icone: AppIcons.recherche,
          )
        else
          for (final ResultatRechercheCoran resultat in _resultats) ...<Widget>[
            _LigneResultat(
              resultat: resultat,
              onPress: () {
                widget.onAller(resultat.page);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

/// Un resultat de la feuille « Aller a ».
class _LigneResultat extends StatelessWidget {
  const _LigneResultat({required this.resultat, required this.onPress});

  final ResultatRechercheCoran resultat;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      onPress: onPress,
      libelleSemantique: resultat.libelle,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  resultat.libelle,
                  style: palette.inkStrong.applyTo(
                    textes.labelLarge ?? const TextStyle(),
                  ),
                ),
                Text(
                  t.tc.coran.navigation.pageNumero(page: resultat.page),
                  style: palette.inkMuted.applyTo(
                    AppTypography.tabulaire(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevron.repos, size: AppSpacing.xl),
        ],
      ),
    );
  }
}
