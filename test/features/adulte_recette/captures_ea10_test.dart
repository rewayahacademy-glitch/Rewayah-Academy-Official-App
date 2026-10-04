// EA-10 : les captures de la recharge du foyer (planches 4.2 et 4.3), depuis
// la VRAIE route /demo/adulte (`adresseDemoAdulte`), comme
// `captures_ea9_test.dart` : 390x844, 768x1024 et 1440x900, clair et sombre,
// plus le texte a 200 % en 390. Etape 1 (vide, puis deux beneficiaires coches
// et leurs offres), etape 2 (deux beneficiaires), l'etat apres « Payer » et
// le paiement non confirme (D5).
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea9_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (avant != null) await avant(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de la recharge, titulaire par defaut (etape 1).
String get _adresseRecharge => adresseDemoAdulte(EcranDemoAdulte.recharge);

/// Choisit un beneficiaire et son offre, pour atteindre l'etape 2
/// (« Verifier la recharge ») avant la capture.
Future<void> _taper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Etape 1 avec deux beneficiaires coches : Mamadou a choisi le second
/// montant propose, Aicha pas encore (les deux etats du montant).
Future<void> _deuxCoches(WidgetTester tester) async {
  await _taper(
    tester,
    find.byKey(RechargeFoyerPage.caseDe(DonneesAdulteDemo.mamadouId)),
  );
  for (int i = 0; i < 2; i++) {
    await _taper(
      tester,
      find.byKey(RechargeFoyerPage.plusDe(DonneesAdulteDemo.mamadouId)),
    );
  }
  await _taper(
    tester,
    find.byKey(RechargeFoyerPage.caseDe(DonneesAdulteDemo.aichaId)),
  );
  // La capture part du haut de la page.
  await tester.ensureVisible(find.text(t.adulte.recharge.titre));
  await tester.pumpAndSettle();
}

/// A 200 %, la ligne de Mamadou en haut de l'ecran, son montant dessous.
Future<void> _deuxCochesAgrandi(WidgetTester tester) async {
  await _deuxCoches(tester);
  await tester.ensureVisible(
    find.byKey(RechargeFoyerPage.profilDe(DonneesAdulteDemo.mamadouId)),
  );
  await tester.pumpAndSettle();
}

/// Deux beneficiaires et leurs montants, puis l'etape 2 : le recapitulatif
/// separe de plusieurs beneficiaires.
Future<void> _jusquALEtape2(WidgetTester tester) async {
  await _deuxCoches(tester);
  await _taper(
    tester,
    find.byKey(RechargeFoyerPage.plusDe(DonneesAdulteDemo.aichaId)),
  );
  await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
}

/// L'etape 2, puis « Payer » : l'etat honnete (ou, selon l'etat de la
/// demonstration, le paiement non confirme de D5).
Future<void> _apresPayer(WidgetTester tester) async {
  await _jusquALEtape2(tester);
  await _taper(tester, find.byKey(RechargeFoyerPage.payerKey));
}

void main() {
  group('Capture : EA-10', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Etape 1, « Nouvelle recharge » : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea10_etape1_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseRecharge,
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 1, en 390.
    testWidgets('ea10_etape1_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea10_etape1_390_light_200pc',
        _adresseRecharge,
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Etape 2, « Verifier la recharge » : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea10_etape2_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseRecharge,
            taille,
            mode: mode,
            avant: _jusquALEtape2,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 2, en 390 : deux beneficiaires.
    testWidgets('ea10_etape2_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea10_etape2_390_light_200pc',
        _adresseRecharge,
        const Size(390, 844),
        echelle: 2,
        avant: _jusquALEtape2,
      );
    });

    // Etape 1, deux beneficiaires coches et leurs offres sous leur ligne :
    // 390 clair et sombre, puis 200 %.
    for (final (String fichier, ThemeMode mode, double echelle)
        in <(String, ThemeMode, double)>[
          ('ea10_etape1_choix_390_light', ThemeMode.light, 1),
          ('ea10_etape1_choix_390_dark', ThemeMode.dark, 1),
          ('ea10_etape1_choix_390_light_200pc', ThemeMode.light, 2),
        ]) {
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          _adresseRecharge,
          const Size(390, 844),
          mode: mode,
          echelle: echelle,
          avant: echelle > 1 ? _deuxCochesAgrandi : _deuxCoches,
        );
      });
    }

    // L'etat final apres « Payer » (F13) : 390 clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier = 'ea10_paiement_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          _adresseRecharge,
          const Size(390, 844),
          mode: mode,
          avant: _apresPayer,
        );
      });
    }

    // Le paiement non confirme (D5), sans Modifier : 390 clair.
    testWidgets('ea10_d5_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea10_d5_390_light',
        adresseDemoAdulte(
          EcranDemoAdulte.recharge,
          etat: EtatDemoAdulte.erreurReseau,
        ),
        const Size(390, 844),
        avant: _apresPayer,
      );
    });
  });
}
