import '../i18n/strings.g.dart';

/// Le nom humain d'une tranche d'age (`cohortes_age.code`).
///
/// Une seule table pour la direction (programme) et la famille (fiche de
/// l'eleve). Un code inconnu est rendu tel quel, jamais devine.
String libelleTranche(String code) => switch (code) {
  'enfant_6_9' => t.admin.programmes.contenu.tranche69,
  'enfant_10_13' => t.admin.programmes.contenu.tranche1013,
  'ado_14_17' => t.admin.programmes.contenu.tranche1417,
  'adulte_18_plus' => t.admin.programmes.contenu.tranche18,
  _ => code,
};
