// « Une difficulte pour entrer ? Ecrivez a support@... » (audit famille,
// 22/11/2026, correctif 1 ; R30, R41, L8). Pose sur la connexion et sur la page
// d'attente : une personne bloquee a l'entree n'a pas de compte valide, donc
// pas l'aide du compte. Le canal vient du serveur (`canal_support_public`),
// jamais ecrit en dur ; sans canal, rien n'est rendu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_support.dart';
import '../../core/capacites/support_public.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';

/// La ligne d'aide a l'entree : la phrase et l'adresse, selectionnable.
class AideEntree extends ConsumerWidget {
  /// Cree la ligne.
  const AideEntree({super.key});

  /// La cle de la ligne, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('aide-entree');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CanalSupport? canal = ref.watch(canalSupportPublicProvider).value;
    if (canal == null) {
      return const SizedBox.shrink();
    }
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return Semantics(
      container: true,
      child: SelectableText(
        t.connexion.aideEntree(adresse: canal.adresse),
        key: cle,
        textAlign: TextAlign.center,
        style: AppPalette.of(context).inkMuted.applyTo(base),
      ),
    );
  }
}
