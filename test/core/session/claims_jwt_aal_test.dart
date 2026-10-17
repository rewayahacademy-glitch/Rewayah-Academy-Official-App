// L1-10 : le niveau d'assurance se lit dans le jeton, a la racine (`aal`),
// jamais dans `app_metadata` ni dans le hook.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/session/claims_jwt.dart';

String _jeton(Map<String, Object?> charge) {
  String b(Object o) => base64Url.encode(utf8.encode(jsonEncode(o)));
  return '${b(<String, String>{'alg': 'HS256'})}.${b(charge)}.sig';
}

void main() {
  test('aal2 lu a la racine du jeton', () {
    final ClaimsJwt c = ClaimsJwt.depuisJeton(
      _jeton(<String, Object?>{
        'sub': 'u1',
        'aal': 'aal2',
        'app_metadata': <String, String>{'role': 'controller'},
      }),
    );
    expect(c.niveauAssurance, 'aal2');
    expect(c.role, 'controller');
  });

  test('sans claim aal : null, jamais aal2 par defaut', () {
    final ClaimsJwt c = ClaimsJwt.depuisJeton(
      _jeton(<String, Object?>{
        'sub': 'u1',
        'app_metadata': <String, String>{'role': 'controller'},
      }),
    );
    expect(c.niveauAssurance, isNull);
  });

  test('un aal2 glisse dans app_metadata ne compte pas', () {
    final ClaimsJwt c = ClaimsJwt.depuisJeton(
      _jeton(<String, Object?>{
        'sub': 'u1',
        'aal': 'aal1',
        'app_metadata': <String, String>{'role': 'controller', 'aal': 'aal2'},
      }),
    );
    expect(c.niveauAssurance, 'aal1');
  });

  test('jeton illisible : vide', () {
    expect(ClaimsJwt.depuisJeton('x'), const ClaimsJwt.vide());
    expect(ClaimsJwt.depuisJeton(null).niveauAssurance, isNull);
  });
}
