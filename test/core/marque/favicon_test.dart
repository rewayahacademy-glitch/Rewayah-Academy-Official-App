// LOGO-1 : le favicon du web porte le trace du directeur. `web/favicon.svg`
// est une copie octet pour octet du symbole violet de la marque
// (`assets/brand/logo/violet/symbole-plein.svg`, README du logo : petit
// format, favicon), jamais redessine ni rastérise par un agent, et la page
// d'entree le declare.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web/favicon.svg est le symbole plein violet du directeur, octet pour '
      'octet', () {
    final List<int> favicon = File('web/favicon.svg').readAsBytesSync();
    final List<int> source = File('assets/brand/logo/violet/symbole-plein.svg')
        .readAsBytesSync();
    expect(favicon, source);
  });

  test('web/index.html declare le favicon SVG', () {
    final String page = File('web/index.html').readAsStringSync();
    expect(
      page,
      contains('<link rel="icon" type="image/svg+xml" href="favicon.svg"/>'),
    );
  });
}
