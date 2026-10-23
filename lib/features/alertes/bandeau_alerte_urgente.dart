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
/// Pose par la coquille admin tout en haut de la page ouverte, au-dessus de
/// son titre et hors de la zone qui defile (`AdminShell.bandeau`,
/// ALERTE-1b) : il reste en vue tant que l'alerte est ouverte et pousse la
/// page sans la recouvrir.
///
/// **Forme courte sur une vue basse** (ALERTE-1b, decide par delegation le
/// 05/10) : fige, le bandeau prend sur la hauteur de la page. Quand la vue
/// compte moins de [hauteurLisible] de haut a taille de texte normale
/// (hauteur de la vue divisee par l'echelle du texte : 320x640 a texte x2,
/// un telephone couche, 1280x1024 a 400 %), il dit seulement qu'une alerte
/// urgente est a traiter (ou combien), sans le titre ni l'heure, qui se
/// lisent sur la page des alertes, a un tap.
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

  /// La hauteur de vue, ramenee a la taille de texte normale, sous laquelle
  /// le bandeau prend sa forme courte.
  static const double hauteurLisible = 480;

  /// Vrai quand [context] demande la forme courte.
  static bool formeCourte(BuildContext context) {
    final double hauteur = MediaQuery.sizeOf(context).height;
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return hauteur / echelle < hauteurLisible;
  }

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
    final bool court = formeCourte(context);
    final String phrase = switch ((court, urgentes.length)) {
      (true, 1) => t.alertes.bandeauCourtUne,
      (true, final int n) => t.alertes.bandeauCourtPlusieurs(nombre: n),
      (false, 1) => t.alertes.bandeauUne(titre: titreAffiche(premiere.titre)),
      (false, final int n) => t.alertes.bandeauPlusieurs(
        nombre: n,
        titre: titreAffiche(premiere.titre),
      ),
    };
    // Pose par la coquille dans la gouttiere de la page : 16 au-dessus ;
    // l'espace du titre d'ecran suit.
    return Padding(
      key: cle,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        child: SignalRow(
          phrase: phrase,
          icone: AppIcons.avertissement,
          anciennete: court ? null : quandAlerte(premiere),
          ton: TonEtat.alerte,
          onPress: onOuvrir,
        ),
      ),
    );
  }
}
