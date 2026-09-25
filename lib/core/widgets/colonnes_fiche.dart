import 'package:flutter/material.dart';

import '../theme/app_gabarit.dart';
import '../theme/app_spacing.dart';

/// Deux colonnes sur bureau (a partir de 1200), une pile en dessous.
///
/// La composition des pages de la fiche derive du Compte haute fidelite :
/// le sujet principal a gauche, ce qui l'accompagne a droite. Jamais une
/// colonne mobile etiree. Gabarit partage par la fiche eleve et le Compte.
class ColonnesFiche extends StatelessWidget {
  /// Cree la composition.
  const ColonnesFiche({required this.principal, super.key, this.annexe});

  /// Le sujet de la page.
  final Widget principal;

  /// Ce qui l'accompagne : notes, liens.
  final Widget? annexe;

  @override
  Widget build(BuildContext context) {
    final Widget? droite = annexe;
    if (droite == null) {
      return principal;
    }
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: principal),
          Ecart.hXxl,
          Expanded(flex: 2, child: droite),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[principal, Ecart.vXxl, droite],
    );
  }
}
