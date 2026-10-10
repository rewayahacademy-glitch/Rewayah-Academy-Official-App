import 'package:flutter/widgets.dart';

/// Le `builder` d'un `MaterialApp` de test qui impose un sens d'ecriture et
/// une echelle de texte, pour les captures a 320 texte x2 en LTR et RTL
/// (EA-HL-DOUBLE-1d). Nul quand rien n'est impose : le harnais garde alors
/// exactement son arbre d'avant.
TransitionBuilder? sensEtEchelle({
  TextDirection? direction,
  double echelle = 1,
}) {
  if (direction == null && echelle == 1) {
    return null;
  }
  return (BuildContext contexte, Widget? app) {
    Widget rendu = app ?? const SizedBox.shrink();
    if (echelle != 1) {
      rendu = MediaQuery(
        data: MediaQuery.of(contexte)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: rendu,
      );
    }
    if (direction != null) {
      rendu = Directionality(textDirection: direction, child: rendu);
    }
    return rendu;
  };
}
