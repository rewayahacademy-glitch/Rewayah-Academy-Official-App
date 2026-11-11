// La Bibliotheque en tete de « Ma classe » (garde-cap, 11/11/2026) : un
// toucher sur « Ma classe » dans la barre, puis un sur cette ligne. Elle sort
// du Compte pour l'eleve. Lue sur la capacite `bibliothequeDansMaClasse`,
// jamais sur un role ; rien quand la capacite manque.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';

/// L'entree de la Bibliotheque, posee en tete de « Ma classe ».
class EntreeBibliothequeMaClasse extends ConsumerWidget {
  /// Cree l'entree.
  const EntreeBibliothequeMaClasse({super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('ma-classe-bibliotheque');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).bibliothequeDansMaClasse) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            cle: ligneKey,
            icone: AppIcons.bibliotheque,
            libelle: t.tc.bibliotheque.titre,
            legende: t.tc.bibliotheque.detail.entreeDetail,
            onPress: () => unawaited(context.push(Routes.tcBibliotheque)),
          ),
        ],
      ),
    );
  }
}
