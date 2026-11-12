// La Bibliotheque en tete de la page des Classes (garde-cap, 11/11/2026) :
// « Ma classe » de l'eleve, « Mes classes » de l'enseignant (PROFILS P3). Un
// toucher dans la barre, puis un sur cette ligne. Elle sort du Compte. Lue sur
// la capacite `bibliothequeDansMaClasse`, jamais sur un role ; rien quand la
// capacite manque.

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

/// L'entree de la Bibliotheque, posee en tete de la page des Classes.
class EntreeBibliothequeMaClasse extends ConsumerWidget {
  /// Cree l'entree.
  const EntreeBibliothequeMaClasse({super.key, this.legende});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('ma-classe-bibliotheque');

  /// La legende de la ligne. Nulle : celle de l'eleve
  /// (`t.tc.bibliotheque.detail.entreeDetail`) ; l'enseignant passe la sienne.
  final String? legende;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Une session illisible (ecran monte sans source de session : test,
    // galerie) ne montre rien, comme une capacite absente.
    bool visible;
    try {
      visible = ref.watch(sessionProvider).bibliothequeDansMaClasse;
    } on Object {
      visible = false;
    }
    if (!visible) {
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
            legende: legende ?? t.tc.bibliotheque.detail.entreeDetail,
            onPress: () => unawaited(context.push(Routes.tcBibliotheque)),
          ),
        ],
      ),
    );
  }
}
