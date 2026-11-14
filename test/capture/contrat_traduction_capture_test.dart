// LANGUES (14/11/2026) : la traduction de courtoisie du contrat d'enseignant
// servi par le serveur, sous le texte francais. Les traductions montrees sont
// les vraies, lues dans la migration 20261125400000 ; le texte francais est
// celui de demonstration (le vrai est celui du serveur).
// 390 clair et 1440 sombre, anglais et arabe.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/recrutement/signature_contrat_page.dart';

import '../support/demo/recrutement_demo.dart';
import '../support/harnais.dart';
import '../support/monter_recrutement.dart';
import 'outil_capture.dart';

String _sha(String texte) =>
    crypto.sha256.convert(utf8.encode(texte)).toString();

String _depuisMigration(String balise) {
  final String sql = File(
    'supabase/migrations/20261125400000_contrat_nda_traductions.sql',
  ).readAsStringSync();
  final int debut = sql.indexOf('\$$balise\$') + balise.length + 2;
  return sql.substring(debut, sql.indexOf('\$$balise\$', debut));
}

class _Port extends SignatureContratDemo implements PortTraductionContrat {
  _Port(this.textes);
  final Map<String, String> textes;

  @override
  Future<TraductionContrat?> traduction(
    SorteContrat kind,
    String version,
    String locale,
  ) async => TraductionContrat(
    locale: locale,
    version: version,
    texte: textes[locale]!,
    sha256: _sha(textes[locale]!),
  );
}

const List<(String, Size, ThemeMode, AppLocale)> _vues =
    <(String, Size, ThemeMode, AppLocale)>[
      ('en_390_clair', Size(390, 844), ThemeMode.light, AppLocale.en),
      ('en_1440_sombre', Size(1440, 900), ThemeMode.dark, AppLocale.en),
      ('ar_390_clair', Size(390, 844), ThemeMode.light, AppLocale.ar),
      ('ar_1440_sombre', Size(1440, 900), ThemeMode.dark, AppLocale.ar),
    ];

void main() {
  group('Capture : traduction du contrat', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final (String nom, Size vue, ThemeMode theme, AppLocale langue)
        in _vues) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        tester.view.physicalSize = vue;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteRoutant(
            depart: Routes.attenteContrat,
            themeMode: theme,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.attenteContrat,
                builder: (BuildContext _, GoRouterState _) =>
                    const SignatureContratPage(),
              ),
              temoin(Routes.attente),
            ],
            surcharges: <Override>[
              portSignatureContratProvider.overrideWithValue(
                _Port(<String, String>{
                  'en': _depuisMigration('contrat_en'),
                  'ar': _depuisMigration('contrat_ar'),
                }),
              ),
              serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            ],
          ),
        );
        await stabiliser(tester);
        await tester.pump(const Duration(seconds: 1));
        debugPrint(
          'PNG ${await capturerVue(tester, 'contrat_traduction_$nom')}',
        );
      });
    }
  });
}
