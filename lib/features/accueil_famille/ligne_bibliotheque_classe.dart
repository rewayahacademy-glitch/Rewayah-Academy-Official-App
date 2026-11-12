// La Bibliotheque sur l'Accueil du tuteur (PROFILS P2, garde-cap,
// 11/11/2026) : dans le bloc de la classe de l'enfant choisi, donc un
// toucher depuis l'Accueil. Elle sort du Compte. Lue sur la capacite
// `peutOuvrirBibliotheque`, jamais sur un role ; rien quand elle manque.

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

/// La ligne « Ouvrir la bibliotheque », posee sous la carte de la classe.
class LigneBibliothequeClasse extends ConsumerWidget {
  /// Cree la ligne.
  const LigneBibliothequeClasse({super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('accueil-bibliotheque');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).peutOuvrirBibliotheque) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
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
