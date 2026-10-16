// Garde mecanique : aucun libelle arabe du suivi des demandes ne dit
// « sauvegarde » (حفظ et ses formes : تم حفظ، محفوظ، حفظنا...). Une
// notification ou un motif de cloture n'est pas une sauvegarde : le suivi ne
// promet pas un enregistrement, il dit ou en est la demande. Le garde de
// `synchronisation_test` ne voit que certaines formules ; celui-ci porte sur
// toutes les cles `notification.*` et `close.*` des deux domaines.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _aplatir(
  Map<String, dynamic> carte, [
  String prefixe = '',
]) {
  final Map<String, String> sortie = <String, String>{};
  carte.forEach((String cle, dynamic valeur) {
    if (valeur is Map<String, dynamic>) {
      sortie.addAll(_aplatir(valeur, '$prefixe$cle.'));
    } else if (valeur is String) {
      sortie['$prefixe$cle'] = valeur;
    }
  });
  return sortie;
}

final RegExp _sauvegarde = RegExp('حفظ|محفوظ|حفِظ');

void main() {
  final Map<String, dynamic> ar = jsonDecode(
    File('assets/i18n/ar.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, String> cles = <String, String>{
    for (final String domaine in <String>['suiviFamille', 'suiviDemandes'])
      ..._aplatir(ar[domaine] as Map<String, dynamic>, '$domaine.'),
  };

  test('les domaines du suivi sont lus en arabe', () {
    expect(
      cles.keys.where((String c) => c.startsWith('suiviFamille.')),
      isNotEmpty,
    );
    expect(
      cles.keys.where((String c) => c.startsWith('suiviDemandes.')),
      isNotEmpty,
    );
  });

  test('aucune notification ni motif de cloture ne dit « sauvegarde »', () {
    final Iterable<MapEntry<String, String>> visees = cles.entries.where(
      (MapEntry<String, String> e) =>
          e.key.contains('.notification.') || e.key.contains('.close.'),
    );
    expect(visees, isNotEmpty);
    for (final MapEntry<String, String> e in visees) {
      expect(_sauvegarde.hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test('le detecteur voit les formes de « sauvegarde »', () {
    expect(_sauvegarde.hasMatch('تم حفظ الطلب'), isTrue);
    expect(_sauvegarde.hasMatch('الطلب محفوظ'), isTrue);
    expect(_sauvegarde.hasMatch('أُغلق الطلب'), isFalse);
  });
}
