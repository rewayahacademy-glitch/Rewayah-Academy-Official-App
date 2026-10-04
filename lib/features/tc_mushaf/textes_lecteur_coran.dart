import 'package:flutter/widgets.dart';

/// Les phrases des etats sans texte du lecteur (« le texte n'a pas pu etre
/// charge », « cette page est vide »), fournies par l'enrobage.
///
/// MA-TUTOIEMENT-1 (decision A4 = a) : le lecteur du Mode Accessibilite
/// vouvoie l'adulte. Les vues de rendu (`VuePageMushaf`, `VueVersetAgrandi`)
/// lisent ces phrases ici quand un enrobage les pose, et gardent sinon leurs
/// libelles d'origine : seul un parametre de texte passe de l'exterieur, le
/// rendu du Coran ne change pas.
class TextesLecteurCoran extends InheritedWidget {
  /// Pose les phrases pour le sous-arbre.
  const TextesLecteurCoran({
    required this.indisponibleDetail,
    required this.absentDetail,
    required super.child,
    super.key,
  });

  /// Sous « Le texte n'a pas pu etre charge ».
  final String indisponibleDetail;

  /// Sous « Cette page est vide ».
  final String absentDetail;

  /// Les phrases posees par l'enrobage, `null` sans enrobage.
  static TextesLecteurCoran? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextesLecteurCoran>();

  @override
  bool updateShouldNotify(TextesLecteurCoran ancien) =>
      indisponibleDetail != ancien.indisponibleDetail ||
      absentDetail != ancien.absentDetail;
}
