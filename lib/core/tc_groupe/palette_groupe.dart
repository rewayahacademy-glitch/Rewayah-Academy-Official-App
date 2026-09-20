import 'package:flutter/widgets.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import 'group_summary_vm.dart';

/// La resolution d'un jeton de couleur de groupe en teinte affichable.
///
/// **Provisoire, et declare comme tel.** La decision `D-18` demande une palette
/// **administree** de 32 a 40 teintes accessibles. Or :
///
/// - `groupes` n'a **aucune colonne de couleur** ;
/// - `lib/core/theme/app_palette.dart` est le **seul** fichier du depot
///   autorise a poser une couleur litterale, et il est en lecture seule pour
///   les agents du Teaching Core ;
/// - `tool/verifier_jetons.dart` refuse toute couleur nue ecrite ailleurs.
///
/// Cette classe compose donc avec **quatre paires existantes** au lieu des
/// trente-deux attendues. Deux groupes sur cinq partagent leur teinte : c'est
/// un defaut assume, pas une solution. La demande de palette est chiffree en
/// section 3 de `docs/teaching-core/TC_CONTRACT_REQUEST_A.md`.
///
/// **Ce qui, lui, est deja correct : la couleur n'est jamais seule.** Toute
/// surface qui appelle [paire] affiche aussi le nom du groupe. C'est
/// l'invariant `J7` du depot, celui que `StatusPill` tient par construction.
abstract final class PaletteGroupe {
  /// Le nombre de teintes reellement distinctes aujourd'hui.
  static const int tailleProvisoire = 4;

  /// Le nombre de teintes que la decision `D-18` demande, au minimum.
  static const int tailleCible = 32;

  /// La teinte d'un jeton.
  ///
  /// Les quatre paires retenues sont les moins chargees de sens du theme :
  /// aucune d'elles ne signifie « succes », « avertissement » ni « alerte ».
  /// Employer une teinte d'etat comme couleur d'identite ferait lire une
  /// anomalie la ou il n'y a qu'un groupe, et c'est precisement ce que la
  /// palette administree viendra corriger.
  static AppColorPair paire(BuildContext context, JetonCouleurGroupe jeton) {
    final AppPalette palette = AppPalette.of(context);
    final List<AppColorPair> teintes = <AppColorPair>[
      palette.washAccent,
      palette.washFamily,
      palette.surfaceQuran,
      palette.surfaceSunken,
    ];
    return teintes[jeton.index % teintes.length];
  }
}
