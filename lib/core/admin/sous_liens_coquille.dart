import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// NAV-SOUS-LIENS (14/11/2026) : la coquille de la direction annonce aux
/// pages les adresses qu'elle montre deja dans son panneau (tablette et
/// ordinateur).
///
/// Une page qui porte une sous-navigation (`SousNavigationDomaine`) la
/// retire quand toutes ses sections sont deja des sous-liens du panneau :
/// sur ordinateur, ni onglets ni menu deroulant de telephone (regle 19 des
/// consignes du directeur, « ces onglets ne sont pas pour le web »). Au
/// telephone, la coquille ne pose rien : la page garde sa sous-navigation.
class SousLiensCoquille extends InheritedWidget {
  /// Annonce [chemins] aux pages posees sous [child].
  const SousLiensCoquille({
    required this.chemins,
    required super.child,
    super.key,
  });

  /// Les adresses des sous-liens montres par le panneau.
  final Set<String> chemins;

  /// Les adresses montrees par le panneau, ou nul hors d'un panneau a
  /// sous-liens (telephone, autres roles).
  static Set<String>? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SousLiensCoquille>()?.chemins;

  /// Vrai quand toutes les adresses de [chemins] sont dans le panneau.
  static bool couvre(BuildContext context, Iterable<String> chemins) {
    final Set<String>? panneau = de(context);
    return panneau != null && chemins.every(panneau.contains);
  }

  @override
  bool updateShouldNotify(SousLiensCoquille oldWidget) =>
      !setEquals(oldWidget.chemins, chemins);
}
