import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/sommaire_sourates.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/port_corpus_coran.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';

/// La feuille « Aller a » : la table des sourates, et la recherche par page,
/// sourate, juz ou reference.
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
  const FeuilleNavigationCoran({
    required this.onAller,
    this.onAPropos,
    super.key,
  });

  /// Appele avec la page choisie.
  final void Function(int page) onAller;

  /// Ouvre la feuille « A propos de cette edition » (MUSHAF-15L) : `null` hors
  /// de la page du Mushaf de Medine, l'entree n'est alors pas rendue.
  final VoidCallback? onAPropos;

  /// La cle de l'entree « A propos de cette edition ».
  static const Key aProposKey = ValueKey<String>('mushaf-a-propos-entree');

  /// Ouvre la feuille.
  static Future<void> ouvrir(
    BuildContext context, {
    required void Function(int page) onAller,
    VoidCallback? onAPropos,
  }) => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.tc.coran.navigation.titre,
    constructeur: (BuildContext context) =>
        FeuilleNavigationCoran(onAller: onAller, onAPropos: onAPropos),
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
          // SOMMAIRE-SOURATES : plus de clavier ouvert d'office, il cachait
          // la table des sourates au telephone. On touche le champ pour
          // chercher, ou une sourate pour y aller.
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
        if (widget.onAPropos != null)
          ActionPrincipale(
            key: FeuilleNavigationCoran.aProposKey,
            libelle: t.tc.coran.mushaf.page15.aProposOuvrir,
            niveau: NiveauAction.tertiaire,
            onPress: () {
              Navigator.of(context).pop();
              widget.onAPropos!();
            },
          ),
        // SOMMAIRE-SOURATES (directeur, 11/11/2026) : tant que rien n'est
        // cherche, la table des 114 sourates est la, de 1 a 114. Deux gestes
        // depuis le lecteur : ouvrir « Aller a », toucher la sourate. La
        // feuille entiere defile (DEFIL-FEUILLE), la table n'a pas de cadre.
        if (!_aCherche) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(titre: t.tc.coran.sommaire.titre),
          const SizedBox(height: AppSpacing.sm),
          SommaireSourates(
            libelleSemantique: (Sourate sourate, int page) => t
                .tc
                .coran
                .sommaire
                .allerA(sourate: sourate.nomTranslittere, page: page),
            onChoisir: (Sourate _, int page) {
              widget.onAller(page);
              Navigator.of(context).pop();
            },
          ),
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

  /// LANGUES-1 : « Juz 18 » et « Page 18 » viennent du corpus en francais ;
  /// l'ecran les ecrit dans la langue choisie (le nom d'une sourate, lui, est
  /// celui de l'edition).
  String get _libelle {
    switch (resultat.type) {
      case TypeResultatRecherche.juz:
        final int? juz = resultat.juz;
        if (juz != null) return t.eleve.coran.juz(juz: '$juz');
      case TypeResultatRecherche.page:
        return t.tc.coran.navigation.pageNumero(page: '${resultat.page}');
      default:
        break;
    }
    return resultat.libelle;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      onPress: onPress,
      libelleSemantique: _libelle,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _libelle,
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
