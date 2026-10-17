// L'entree des revenus estimes sur Aujourd'hui (lot F1, demande du directeur
// du 17/10/2026 : les gains de l'enseignant visibles depuis son accueil, pas
// seulement depuis le Profil).
//
// Une LIGNE dans « Ma journee », comme la Communaute enseignants, jamais un
// cinquieme bloc (K-42, « Quatre blocs, pas un de plus ») ni une destination
// de la barre (E10). **Aucun chiffre ici** : la ligne ne lit aucun port. La
// page d'arrivee (`RevenusEnseignantPage`) est la seule lecture des revenus,
// et dit « pas encore publies » tant que le serveur ne rend rien (FI-BR-11).
// La ligne reste donc toujours rendue : son arrivee dit l'etat honnete.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/lien_fleche.dart';

/// L'adresse ouverte par la ligne : les revenus, avec le retour vers
/// Aujourd'hui. La demonstration la remplace par la sienne, hors production.
final Provider<String> destinationRevenusProvider = Provider<String>(
  (Ref ref) => Routes.enseignantRevenusDepuisJournee,
  dependencies: const <ProviderOrFamily>[],
);

/// La ligne « Revenus estimés » d'Aujourd'hui.
class EntreeRevenus extends ConsumerWidget {
  /// Cree la ligne.
  const EntreeRevenus({super.key, this.ecartAvant});

  /// L'ecart a poser avant le contenu, ou `null`.
  final Widget? ecartAvant;

  /// La cle du lien, pour les tests.
  static const ValueKey<String> cleLien = ValueKey<String>(
    'entree-revenus-lien',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?ecartAvant,
        LienFleche(
          key: cleLien,
          libelle: t.enseignant.revenus.titre,
          libelleSemantique: t.enseignant.journee.revenusLecteur,
          icone: AppIcons.finance,
          onPress: () =>
              GoRouter.of(context).go(ref.read(destinationRevenusProvider)),
        ),
        Text(
          t.enseignant.journee.revenusDetail,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
