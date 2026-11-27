import 'dart:math';

import '../router/reprise_salle_natif.dart'
    if (dart.library.js_interop) '../router/reprise_salle_web.dart'
    as onglet;

/// La cle du stockage de l'onglet.
const String _cle = 'rewayah.appareil_salle';

String? _enMemoire;

/// SALLE-SECOND-APPAREIL : l'identifiant de CET appareil (en navigateur : de cet
/// onglet, qui survit a un rechargement). Il ne designe personne : une valeur au
/// hasard, jamais un droit. Deux onglets ont deux identifiants, donc le second
/// demande la permission du premier.
String identifiantAppareilSalle() {
  final String? vu = _enMemoire ?? onglet.lireDansOnglet(_cle);
  if (vu != null && vu.length == 36) {
    return _enMemoire = vu;
  }
  final Random hasard = Random.secure();
  String hex(int n) => List<String>.generate(
    n,
    (_) => hasard.nextInt(16).toRadixString(16),
  ).join();
  final String variante = '89ab'[hasard.nextInt(4)];
  final String neuf =
      '${hex(8)}-${hex(4)}-4${hex(3)}-$variante${hex(3)}-${hex(12)}';
  onglet.ecrireDansOnglet(_cle, neuf);
  return _enMemoire = neuf;
}
