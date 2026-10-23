import 'package:flutter/widgets.dart';

import '../../core/accessibilite/commandes_masquables.dart';

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

/// Le sens d'ecriture de la LANGUE DE L'INTERFACE, quel que soit le sens
/// pose au-dessus.
///
/// MUSHAF-DIR-1 (05/10/2026) : le feuilletage du mushaf pose un sens de
/// droite a gauche (on tourne les pages d'un mushaf de droite a gauche).
/// Les phrases francaises posees dans une page (etats sans texte, notice
/// « Composition approchee ») le recevaient aussi, et leur point final
/// passait en tete (« .votre page se rouvre ici »). Elles reprennent ici le
/// sens de la langue choisie (gauche a droite en francais, droite a gauche
/// en arabe), lu dans les localisations et non dans l'arbre. Le texte arabe
/// du Coran garde son propre sens.
TextDirection sensInterface(BuildContext context) =>
    Localizations.of<WidgetsLocalizations>(
      context,
      WidgetsLocalizations,
    )?.textDirection ??
    TextDirection.ltr;

/// L'enrobage d'un etat sans texte des vues de rendu (page non chargee,
/// page vide), autour de son `EmptyState`.
///
/// - MUSHAF-DIR-1 : ses phrases suivent le sens de la langue de l'interface
///   ([sensInterface]), pas celui du feuilletage ;
/// - MA-CORAN-X2-1 : il s'ecarte des commandes du Mode Accessibilite qui le
///   recouvriraient encore (`CommandesMasquables.recouvrementDe` ; d'ordinaire
///   0, la marge de lecture des commandes le loge deja au-dessus d'elles).
class EtatSansTexteLecteur extends StatelessWidget {
  /// Enrobe [etat].
  const EtatSansTexteLecteur(this.etat, {super.key});

  /// L'etat sans texte (un `EmptyState`).
  final Widget etat;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: sensInterface(context),
    child: Padding(
      padding: EdgeInsets.only(
        bottom: CommandesMasquables.recouvrementDe(context),
      ),
      child: Center(child: etat),
    ),
  );
}
