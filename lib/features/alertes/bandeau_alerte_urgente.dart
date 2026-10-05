import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/signal_row.dart';
import '../../core/widgets/status_pill.dart';
import 'ligne_alerte.dart';

/// Le bandeau d'alerte urgente, en haut de l'ecran ouvert (ALERTE-1).
///
/// **Des son arrivee, sans recharger** : il lit le flux des alertes
/// (`alertesProvider`), et une alerte urgente qui y entre le fait apparaitre
/// sur la page deja ouverte ; traitee, elle en sort et le bandeau disparait.
/// Region vivante : le lecteur d'ecran l'annonce a son apparition.
///
/// Rien quand aucune alerte urgente n'est ouverte, ni quand la source ne
/// rend rien (indisponible, en echec) : le bandeau est un signal, l'etat de
/// la source se dit sur le Centre de commande et la page des alertes. Lit une
/// capacite (le flux), jamais un role.
///
/// Pose par la coquille, rendu par `PageShell` en tete de la page, au-dessus
/// du titre (`ActionsEnteteCoquille.bandeau`) : il defile avec la tete quand
/// la vue est tres basse.
///
/// La ligne de signal (`SignalRow`) au ton d'alerte : registre doux, icone,
/// phrase et chevron, la carte entiere ouvre la page des alertes.
class BandeauAlerteUrgente extends ConsumerWidget {
  /// Cree le bandeau.
  const BandeauAlerteUrgente({required this.onOuvrir, super.key});

  /// Ouvre la page des alertes.
  final VoidCallback onOuvrir;

  /// Cle stable, pour les tests et les captures.
  static const Key cle = ValueKey<String>('bandeau-alerte-urgente');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Alerte>> alertes = ref.watch(alertesProvider);
    final List<Alerte> urgentes = alertes.hasValue
        ? alertes.requireValue.where((Alerte a) => a.urgente).toList()
        : const <Alerte>[];
    if (urgentes.isEmpty) {
      return const SizedBox.shrink();
    }
    // Triees : la premiere urgente est la plus recente.
    final Alerte premiere = urgentes.first;
    final String phrase = urgentes.length == 1
        ? t.alertes.bandeauUne(titre: titreAffiche(premiere.titre))
        : t.alertes.bandeauPlusieurs(
            nombre: urgentes.length,
            titre: titreAffiche(premiere.titre),
          );
    // Pose par `PageShell` en tete de page, dans la gouttiere de la page :
    // 16 au-dessus ; l'espace du titre d'ecran suit.
    return Padding(
      key: cle,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        child: SignalRow(
          phrase: phrase,
          icone: AppIcons.avertissement,
          anciennete: quandAlerte(premiere),
          ton: TonEtat.alerte,
          onPress: onOuvrir,
        ),
      ),
    );
  }
}
