import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';

/// Un nombre choisi au pas a pas : « moins », la valeur, « plus ».
///
/// Decision du directeur du 17/10/2026 (`DECISION-ENTREE-2026-10-17.md`,
/// questions de l'onboarding) : tout ce qui peut se choisir se choisit, jamais
/// au clavier. Ce composant remplace les champs numeriques tapes a la main
/// (« Autre » de [SelecteurEntier], frequence du tirage, ordre d'un niveau,
/// reglages entiers sans proposition).
///
/// La valeur reste dans [min] et [max] : le bouton qui sortirait des bornes
/// n'est pas grise, il n'existe pas (K-56). Les deux boutons font 48 de cote
/// et portent un libelle parle ; la valeur est annoncee avec [libelle].
class ChoixNombre extends StatelessWidget {
  /// Cree le choix.
  const ChoixNombre({
    required this.libelle,
    required this.valeur,
    required this.onChange,
    required this.libelleMoins,
    required this.libellePlus,
    super.key,
    this.min = 0,
    this.max,
    this.affichage,
  });

  /// Ce que la valeur represente (« Ordre », « Missions par semaine »).
  final String libelle;

  /// La valeur courante.
  final int valeur;

  /// Appele avec la nouvelle valeur, toujours dans les bornes.
  final ValueChanged<int> onChange;

  /// Le libelle parle du bouton « moins ».
  final String libelleMoins;

  /// Le libelle parle du bouton « plus ».
  final String libellePlus;

  /// La plus petite valeur (0 par defaut).
  final int min;

  /// La plus grande valeur ; nulle : aucun plafond.
  final int? max;

  /// Formate la valeur (unite comprise) ; par defaut, le nombre seul.
  final String Function(int valeur)? affichage;

  /// La cle du bouton « moins ».
  static const Key cleMoins = ValueKey<String>('choix-nombre-moins');

  /// La cle du bouton « plus ».
  static const Key clePlus = ValueKey<String>('choix-nombre-plus');

  /// La cle de la valeur affichee.
  static const Key cleValeur = ValueKey<String>('choix-nombre-valeur');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final int? plafond = max;
    final bool peutMoins = valeur > min;
    final bool peutPlus = plafond == null || valeur < plafond;
    final String texte = affichage?.call(valeur) ?? '$valeur';
    // La place d'un bouton absent reste tenue (sa cible tactile, celle du
    // mode) : la valeur ne saute pas d'un cote a l'autre a une borne.
    final Widget vide = SizedBox(width: AppMetriques.of(context).cibleTactile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          libelle,
          style: AppPalette.of(context).inkMuted
              .applyTo(textes.bodyMedium ?? const TextStyle()),
        ),
        Ecart.vSm,
        Row(
          children: <Widget>[
            if (peutMoins)
              BoutonIcone(
                key: cleMoins,
                icone: AppIcons.moins,
                libelle: libelleMoins,
                onPress: () => onChange(valeur - 1),
              )
            else
              vide,
            Expanded(
              child: Semantics(
                label: libelle,
                value: texte,
                liveRegion: true,
                excludeSemantics: true,
                child: TexteSansCoupure(
                  texte,
                  key: cleValeur,
                  textAlign: TextAlign.center,
                  style: textes.titleLarge ?? const TextStyle(),
                ),
              ),
            ),
            if (peutPlus)
              BoutonIcone(
                key: clePlus,
                icone: AppIcons.ajouter,
                libelle: libellePlus,
                onPress: () => onChange(valeur + 1),
              )
            else
              vide,
          ],
        ),
      ],
    );
  }
}
