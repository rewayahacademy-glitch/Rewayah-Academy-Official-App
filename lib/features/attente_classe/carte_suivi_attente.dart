/// SUIVI-ATTENTE (S6) : la carte compacte des accueils, en tete tant que le
/// suivi n'est pas termine. Elle dit en une ligne ou en est la demande de
/// chaque enfant et ouvre l'ecran complet : **un seul ecran de suivi**, cette
/// carte n'en est que le raccourci.
///
/// Silencieuse tant qu'il n'y a rien a suivre : sans port (production avant
/// branchement) elle rend [repli] (l'ancienne carte, inchangee), pendant la
/// premiere lecture et sans demande elle ne rend rien. Une demande disparait de
/// l'accueil 7 jours apres le premier cours (le serveur rend
/// `visible_accueil`) et reste consultable dans le parcours. En echec de
/// lecture, la carte le dit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pile_cartes.dart';
import 'libelles_attente.dart';
import 'suivi_attente_page.dart' show CheminsAttente;

/// Les suivis a montrer sur l'accueil : visibles, les demandes en cours
/// d'abord, l'ordre du serveur a l'interieur de chaque groupe.
List<SuiviAttente> suivisPourAccueil(List<SuiviAttente> suivis) {
  final List<SuiviAttente> visibles = <SuiviAttente>[
    for (final SuiviAttente s in suivis)
      if (s.visibleAccueil) s,
  ];
  return <SuiviAttente>[
    ...visibles.where((SuiviAttente s) => !s.close),
    ...visibles.where((SuiviAttente s) => s.close),
  ];
}

/// La carte « Votre demande de classe » de l'accueil.
class CarteSuiviAttente extends ConsumerWidget {
  /// Cree la carte. [repli] : ce qui se rend tant que le suivi n'est pas
  /// branche.
  const CarteSuiviAttente({required this.chemins, this.repli, super.key});

  /// Les destinations des liens.
  final CheminsAttente chemins;

  /// L'ancienne carte, rendue sans port.
  final Widget? repli;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portSuiviAttenteProvider) == null) {
      return repli ?? const SizedBox.shrink();
    }
    final AsyncValue<List<SuiviAttente>> lues = ref.watch(
      suivisAttenteProvider,
    );
    // Riverpod 3 relance seul un fournisseur en echec : l'etat repasse par le
    // chargement en gardant l'erreur. On lit hasValue et hasError.
    final bool echec = !lues.hasValue && lues.hasError;
    if (!lues.hasValue && !echec) return const SizedBox.shrink();
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    if (echec) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCard(
            key: const ValueKey<String>('carte-attente-erreur'),
            largeurMax: AppPage.largeurFormulaire,
            child: TexteSansCoupure(
              t.suiviAttente.erreur,
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXl,
        ],
      );
    }
    final List<SuiviAttente> suivis = suivisPourAccueil(
      lues.value ?? const <SuiviAttente>[],
    );
    if (suivis.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey<String>('carte-attente'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PileCartes(
          children: <Widget>[
            for (final SuiviAttente s in suivis)
              AppCard(
                key: ValueKey<String>('carte-attente-${s.demandeId}'),
                largeurMax: AppPage.largeurFormulaire,
                entete: Semantics(
                  header: true,
                  child: TexteSansCoupure(
                    s.versionSimple
                        ? t.suiviAttente.carte.titreSimple
                        : t.suiviAttente.carte.titre,
                    style: textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                actions: LienFleche(
                  key: ValueKey<String>('carte-attente-voir-${s.demandeId}'),
                  libelle: t.suiviAttente.carte.suivre,
                  alignerEnFin: true,
                  onPress: () =>
                      GoRouter.maybeOf(context)
                          ?.go(chemins.detail(s.demandeId)),
                ),
                child: TexteSansCoupure(
                  ligneCarte(s),
                  key: ValueKey<String>('carte-attente-ligne-${s.demandeId}'),
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
          ],
        ),
        Ecart.vXl,
      ],
    );
  }
}
