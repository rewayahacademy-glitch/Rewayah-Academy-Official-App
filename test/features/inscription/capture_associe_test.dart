// Captures R3 de l'inscription d'un associe invite : la saisie du code, le
// formulaire, un code refuse, une panne. fr et ar, 360 et 1440.
//
// CAPTURE_DIR=docs/current/captures/E2E/ASSOCIE-INSCRIPTION flutter test \
//   test/features/inscription/capture_associe_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/equipe/port_inscription_associe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/inscription/associe_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortInscriptionAssocie {
  _Port(this.verification, [this.erreur]);
  final ResultatCodeAssocie verification;
  final Exception? erreur;

  @override
  Future<ResultatCodeAssocie> verifier(String code) async {
    if (erreur != null) throw erreur!;
    return verification;
  }

  @override
  Future<ResultatInscriptionAssocie> inscrire({
    required String code,
    required String prenom,
    required String nom,
    required String genre,
  }) async => ResultatInscriptionAssocie.consommee;
}

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  bool arabe,
  PortInscriptionAssocie port, {
  String? code,
}) => monterRecrutement(
  tester,
  chemin: Routes.inscriptionAssocie,
  depart: code == null
      ? Routes.inscriptionAssocie
      : '${Routes.inscriptionAssocie}?code=$code',
  autres: <String>[Routes.inscriptionUsage, Routes.connexion],
  ecran: (state) => AssociePage(codeInitial: state.uri.queryParameters['code']),
  surcharges: <Override>[
    portInscriptionAssocieProvider.overrideWithValue(port),
  ],
  largeur: taille.width,
  hauteur: taille.height,
  direction: arabe ? TextDirection.rtl : null,
);

void main() {
  group('captures ASSOCIE-INSCRIPTION', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size taille, AppLocale langue) in <(Size, AppLocale)>[
      (const Size(360, 800), AppLocale.fr),
      (const Size(360, 800), AppLocale.ar),
      (const Size(1440, 900), AppLocale.fr),
      (const Size(1440, 900), AppLocale.ar),
    ]) {
      final String suffixe = '${taille.width.toInt()}-${langue.languageCode}';
      testWidgets('saisie $suffixe', (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          taille,
          langue == AppLocale.ar,
          _Port(const CodeAssocieInconnu()),
        );
        await capturerVue(tester, '1-saisie-$suffixe');
      });
      testWidgets('formulaire $suffixe', (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          taille,
          langue == AppLocale.ar,
          _Port(CodeAssocieValide(DateTime.utc(2026, 12, 1))),
          code: 'ABCD-EFGH-JKMN',
        );
        await capturerVue(tester, '2-formulaire-$suffixe');
      });
      testWidgets('code refuse $suffixe', (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          taille,
          langue == AppLocale.ar,
          _Port(const CodeAssocieExpire()),
          code: 'ABCD-EFGH-JKMN',
        );
        await capturerVue(tester, '3-code-refuse-$suffixe');
      });
      testWidgets('panne $suffixe', (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          taille,
          langue == AppLocale.ar,
          _Port(const CodeAssocieInconnu(), Exception('x')),
          code: 'ABCD-EFGH-JKMN',
        );
        await capturerVue(tester, '4-panne-$suffixe');
      });
    }
  }, skip: sautSansCapture);
}
