// Le badge « Nouveau » (directeur, 16/11/2026, SPEC-LISTE-PERSONNES §2.1 bis) :
// avec 30 a 100 arrivees par heure ou par jour, on voit d'un coup d'oeil qui
// vient d'arriver.
//
// Un seul composant pour toutes les listes de personnes et le panneau des
// conversations. La regle (arrivee depuis moins de 7 jours ET dossier jamais
// ouvert par l'equipe) est calculee par le serveur et rendue en booleen
// (`nouveau`) : ce composant ne decide rien, il dit « Nouveau ».
//
// Pose sur `StatusPill` : un MOT et une ICONE (une etoile), la couleur ne fait
// que doubler l'information. Sobre : le registre doux de l'accent, jamais un
// aplat sature.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

/// Le badge « Nouveau » / « New » / « جديد ».
class BadgeNouveau extends StatelessWidget {
  /// Cree le badge.
  const BadgeNouveau({super.key});

  /// La cle de la pastille, pour les tests.
  static const ValueKey<String> clePastille = ValueKey<String>(
    'badge-nouveau-pastille',
  );

  @override
  Widget build(BuildContext context) => StatusPill(
    key: clePastille,
    libelle: t.commun.nouveau,
    ton: TonEtat.accent,
    marqueur: Icon(
      AppIcons.etoile.actif,
      size: AppSpacing.lg,
      color: AppPalette.of(context).paireDe(TonEtat.accent).onBackground,
    ),
  );
}
