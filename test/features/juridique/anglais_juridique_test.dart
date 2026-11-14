// LANGUES-3 (directeur, 14/11/2026) : les textes juridiques et le contrat en
// anglais, traduction fidele. Le test garde ce que la fidelite interdit de
// changer : les mêmes variables, les mêmes nombres (montants, delais, numeros
// d'articles) cle par cle, aucun reste de francais ; et la mention « la
// version francaise fait foi », seulement dans une traduction.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/mention_traduction.dart';

import '../../capture/outil_capture.dart';

Map<String, String> _aplatir(
  Object? noeud,
  String prefixe,
  Map<String, String> sortie,
) {
  if (noeud is Map<String, dynamic>) {
    noeud.forEach((String k, Object? v) => _aplatir(v, '$prefixe$k.', sortie));
  } else if (noeud is List<dynamic>) {
    for (int i = 0; i < noeud.length; i++) {
      _aplatir(noeud[i], '$prefixe$i.', sortie);
    }
  } else if (noeud is String) {
    sortie[prefixe.substring(0, prefixe.length - 1)] = noeud;
  }
  return sortie;
}

Map<String, String> _lire(String langue) {
  final Map<String, dynamic> json = jsonDecode(
    File('assets/i18n/$langue.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, String> tout = _aplatir(json, '', <String, String>{});
  return <String, String>{
    for (final MapEntry<String, String> e in tout.entries)
      if (e.key.startsWith('juridique.') || e.key.startsWith('contrat.'))
        e.key: e.value,
  };
}

List<String> _nombres(String s) =>
    RegExp(r'\d+').allMatches(s).map((RegExpMatch m) => m.group(0)!).toList()
      ..sort();

List<String> _variables(String s) =>
    RegExp(r'\{(\w+)\}')
        .allMatches(s)
        .map((RegExpMatch m) => m.group(1)!)
        .toList()
      ..sort();

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final Map<String, String> fr = _lire('fr');
  final Map<String, String> en = _lire('en');
  final Map<String, String> ar = _lire('ar');

  test('toutes les cles juridiques et du contrat sont en anglais', () {
    expect(en.length, fr.length);
    for (final String k in fr.keys) {
      expect(en.containsKey(k), isTrue, reason: k);
      expect(en[k]!.trim(), isNotEmpty, reason: k);
    }
  });

  test('l arabe couvre les memes cles (non modifie par ce lot)', () {
    for (final String k in fr.keys) {
      expect(ar.containsKey(k), isTrue, reason: k);
    }
  });

  test('memes variables, memes nombres que le francais, cle par cle', () {
    for (final String k in fr.keys) {
      expect(_variables(en[k]!), _variables(fr[k]!), reason: 'variables $k');
      expect(_nombres(en[k]!), _nombres(fr[k]!), reason: 'nombres $k');
    }
  });

  test('aucun reste de francais dans l anglais juridique', () {
    final RegExp accents = RegExp('[àâçéèêëîïôûùœÀÉÈ]');
    for (final MapEntry<String, String> e in en.entries) {
      if (e.key == 'juridique.traduction') continue;
      expect(accents.hasMatch(e.value), isFalse, reason: e.key);
      expect(e.value.contains('—'), isFalse, reason: e.key);
    }
  });

  group('La mention de traduction', () {
    Future<void> monter(WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(hoteCapture(const JuridiquePage()));
      await stabiliser(tester);
    }

    testWidgets('en anglais, l en-tete dit que la version francaise fait foi', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await monter(tester);
      expect(find.byType(MentionTraduction), findsOneWidget);
      expect(
        find.text(
          'This translation is provided for convenience. In case of '
          'discrepancy, the French version prevails.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('en francais, aucune mention', (WidgetTester tester) async {
      await monter(tester);
      expect(find.text(t.juridique.traduction), findsNothing);
    });
  });
}
