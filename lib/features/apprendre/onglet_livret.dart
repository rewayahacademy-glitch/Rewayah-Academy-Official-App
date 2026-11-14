/// ESPACE-APPRENDRE (lot 5) : l'onglet « Mon livret » de l'espace Apprendre.
///
/// L'onglet existe, avec son etat vide honnete : les resultats, bilans et
/// attestations viendront avec le lot 8 (EVALUATIONS-ET-LIVRET). **Aucun faux
/// resultat, aucun exemple.** Rien d'autre dans ce lot.
library;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/empty_state.dart';

/// La cle de l'etat vide, pour les tests.
const Key cleLivretVide = ValueKey<String>('apprendre-livret-vide');

/// L'onglet.
class OngletLivret extends StatelessWidget {
  /// Cree l'onglet ; [tutoiement] : « Tes resultats », jamais « Vos
  /// resultats ».
  const OngletLivret({super.key, this.tutoiement = false});

  /// Vrai en Interface guidee.
  final bool tutoiement;

  @override
  Widget build(BuildContext context) => EmptyState(
    key: cleLivretVide,
    message: tutoiement ? t.apprendre.livret.videTu : t.apprendre.livret.vide,
    icone: AppIcons.livret,
    registre: RegistreVide.subi,
  );
}
