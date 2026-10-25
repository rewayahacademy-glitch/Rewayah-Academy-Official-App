import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/recharger_adresse.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../widgets/lien_fleche.dart';
import '../widgets/offline_banner.dart';
import 'nouvelle_version.dart';

/// Le bandeau « nouvelle version » (lot demarrage, 25/10/2026) : le registre
/// du bandeau hors ligne ([OfflineBanner.message]), jamais recompose, avec un
/// lien « Recharger » qui recharge la page. Rien tant que la version servie
/// est celle du demarrage.
class BandeauNouvelleVersion extends ConsumerWidget {
  /// Cree le bandeau. [recharger] se fixe dans les tests.
  const BandeauNouvelleVersion({super.key, this.recharger = rechargerAdresse});

  /// Le rechargement de la page.
  final VoidCallback recharger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(nouvelleVersionProvider)) {
      return const SizedBox.shrink();
    }
    return OfflineBanner.message(
      message: t.miseAJour.prete,
      icone: AppIcons.info.repos,
      action: LienFleche(
        libelle: t.miseAJour.recharger,
        onPress: recharger,
        fleche: false,
        encre: AppPalette.of(context).washWarning.applyTo,
      ),
    );
  }
}
