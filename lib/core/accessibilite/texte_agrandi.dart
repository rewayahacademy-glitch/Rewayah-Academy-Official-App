// Les seuils de bascule des communications a texte agrandi ou sur une vue
// basse, definis une seule fois (COM-RC tour 4, constat N-6 de la
// contre-verification COM-R-2).
//
// A partir de [SeuilsTexteAgrandi.echelle] (150 %), un ecran de
// communication change de disposition : en-tete qui defile avec le fil,
// date au-dessus du titre d'une notification, une tuile par rangee, entree
// « Nouvelle publication » dans le flux. Sous [SeuilsTexteAgrandi.hauteurBasse]
// de hauteur recue, un fil ou un flux se comporte comme a texte agrandi.
// Ces seuils etaient recopies, parfois en litteral, dans cinq fichiers.

import 'package:flutter/widgets.dart';

/// Les seuils de texte agrandi et de vue basse, communs aux ecrans de
/// communication.
abstract final class SeuilsTexteAgrandi {
  /// L'echelle de texte a partir de laquelle le texte est « agrandi ».
  static const double echelle = 1.5;

  /// Sous cette hauteur recue, la vue est « basse » : ce qui reste fixe
  /// d'ordinaire defile avec le contenu.
  static const double hauteurBasse = 480;

  /// Vrai quand le texte de [context] est agrandi (au moins [echelle]).
  static bool texteAgrandi(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) >= echelle;
}
