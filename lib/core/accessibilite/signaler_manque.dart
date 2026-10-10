import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Un bouton n'est jamais grise (lib/CLAUDE.md, K-56, BOUTONS-GRISES-1) :
/// presse trop tot, il dit ce qui manque. Cette fonction fait les deux gestes
/// qui accompagnent la phrase posee a l'ecran par l'appelant :
///
/// - la phrase est annoncee au lecteur d'ecran (une phrase qui apparait sous
///   un champ n'est pas toujours lue : `liveRegion` ne parle que sur Android) ;
/// - le focus va au champ fautif ([champ]), pour que le clavier et le lecteur
///   d'ecran reprennent la ou il faut agir.
///
/// L'appelant garde l'affichage de la phrase (sous le champ, en encre
/// d'alerte) : l'annonce ne remplace jamais le texte visible.
void signalerManque(BuildContext context, String message, {FocusNode? champ}) {
  champ?.requestFocus();
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}
