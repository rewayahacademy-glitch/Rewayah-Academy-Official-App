/// FN-113 : le refus `plafond_classes_atteint` (migration 20261022000200,
/// reglage `enseignant.classes_max`), commun a la creation d'une classe et a
/// l'affectation d'un enseignant.
library;

/// Le debut du message leve par le serveur.
const String messagePlafondClasses = 'plafond_classes_atteint';

/// Les deux nombres du DETAIL du serveur (« classes actives : 3 ; maximum :
/// 3 »), ou `null` pour chacun s'il ne s'y lit pas : rien n'est invente.
({int? actives, int? maximum}) nombresPlafondClasses(String? detail) {
  final String d = (detail ?? '').toLowerCase();
  int? lire(String etiquette) {
    final RegExpMatch? m = RegExp('${RegExp.escape(etiquette)}\\s*:\\s*(\\d+)')
        .firstMatch(d);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  return (actives: lire('classes actives'), maximum: lire('maximum'));
}
