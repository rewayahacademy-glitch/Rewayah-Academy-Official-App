// ANTI-ROBOT (03/11/2026) : hors web, aucun widget Turnstile ne se monte.
// Le controleur reste en chargement : un envoi attend, puis part sans jeton.
import 'package:flutter/widgets.dart';

import 'anti_robot.dart';

/// Le widget Turnstile ; ici, rien.
class RenduTurnstile extends StatelessWidget {
  /// Cree le rendu.
  const RenduTurnstile({
    required this.cle,
    required this.langue,
    required this.controleur,
    required this.onVisible,
    super.key,
  });

  /// La cle publique du site.
  final String cle;

  /// La langue de l'ecran (`fr`, `ar`).
  final String langue;

  /// Le controleur qui recoit le jeton.
  final ControleurAntiRobot controleur;

  /// Appele quand Cloudflare demande une interaction (la case apparait).
  final ValueChanged<bool> onVisible;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
