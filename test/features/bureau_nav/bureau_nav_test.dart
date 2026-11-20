// BUREAU-NAV (contrat de navigation du 20/11/2026, §2, §4, §5, §6) : sur le
// VRAI routeur et la vraie application de demonstration de la direction.
//
// - le retour ramene d'ou l'on vient : une page empilee se retire et la liste
//   revient avec son filtre ; apres un lien direct, le parent logique (la
//   liste avec son filtre), jamais l'Accueil d'office ;
// - a la racine d'une rubrique, le retour (touche du systeme) mene a l'Accueil ;
// - l'icone des messages reste dans l'en-tete, compteur a zero compris ;
// - le fil d'Ariane du dossier ramene a la liste dans son etat.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_ariane.dart';
import 'package:rewayah_academy/features/com_messages/non_lus_messages.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/mode_demonstration.dart';
import '../../support/demo/repere_demonstration.dart';

const Key _cleMessages = ValueKey<String>('admin-messages-non-lus');

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1440, 900),
  int nonLus = 0,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        nonLusMessagesProvider.overrideWith((Ref _) async => nonLus),
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await _stabiliser(tester);
  return routeur;
}

/// L'adresse complete de la page du dessus (requete comprise).
String _adresse(GoRouter routeur) {
  final RouteMatchList config = routeur.routerDelegate.currentConfiguration;
  final RouteMatchBase dernier = config.last;
  if (dernier is ImperativeRouteMatch) {
    return dernier.matches.uri.toString();
  }
  return config.uri.toString();
}

const Map<String, String> _file = <String, String>{'etape': 'entretien'};

String get _listeFiltree => Uri(
  path: Routes.adminPersonnesCandidatures,
  queryParameters: _file,
).toString();

String get _dossier => Routes.adminPersonnesCandidaturePour(
  'CAND-2026-0001',
  fileDeLaListe: _file,
);

void main() {
  testWidgets('retour d un dossier empile : la liste revient avec son filtre', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, _listeFiltree);
    expect(_adresse(routeur), _listeFiltree);
    unawaited(routeur.push<void>(_dossier));
    await _stabiliser(tester);
    expect(_adresse(routeur), _dossier);

    await tester.tap(find.byType(DisqueRetour).last);
    await _stabiliser(tester);
    expect(_adresse(routeur), _listeFiltree);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retour apres un lien direct : la liste filtree, pas l Accueil', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, _dossier);
    expect(routeur.canPop(), isFalse);
    await tester.tap(find.byType(DisqueRetour).last);
    await _stabiliser(tester);
    expect(_adresse(routeur), _listeFiltree);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'touche retour du systeme, au bas de la pile : le parent logique, '
    'puis l Accueil a la racine d une rubrique',
    (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, _dossier);
      await tester.binding.handlePopRoute();
      await _stabiliser(tester);
      expect(_adresse(routeur), _listeFiltree);

      await tester.binding.handlePopRoute();
      await _stabiliser(tester);
      expect(_adresse(routeur), Routes.admin);
    },
  );

  testWidgets('fil d Ariane du dossier : la liste dans son etat', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, _dossier);
    final Finder fil = find.byKey(FilAriane.cleFil);
    expect(fil, findsWidgets);
    final FilAriane widget = tester.widget<FilAriane>(fil.last);
    expect(
      widget.segments.map((s) => s.chemin),
      contains(_listeFiltree),
      reason: 'le maillon de la liste garde le filtre',
    );
    expect(_adresse(routeur), _dossier);
  });

  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(390, 844),
  ]) {
    testWidgets('${taille.width.toInt()} : l icone des messages reste, '
        'compteur a zero', (WidgetTester tester) async {
      await _monter(tester, Routes.admin, taille: taille);
      expect(find.byKey(_cleMessages), findsOneWidget);
    });
  }

  // R3 : de vraies images (polices du depot), ecrites seulement quand
  // `CAPTURE_DIR` est pose (docs/current/captures/E2E/pe-bureau-nav/).
  group('Capture : PE bureau-nav', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });
    setUp(() {
      neutraliserStockageAppareil();
      masquerRubanDebug();
    });
    testWidgets('1440 : dossier ouvert par un lien direct', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _dossier);
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturerVue(tester, 'dossier-lien-direct-1440x900')}',
      );
    });
    testWidgets('1440 : retour, la liste filtree', (WidgetTester tester) async {
      await _monter(tester, _dossier);
      await tester.tap(find.byType(DisqueRetour).last);
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturerVue(tester, 'retour-liste-filtree-1440x900')}',
      );
    });
    testWidgets('390 : en-tete, icone des messages a zero', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.admin, taille: const Size(390, 844));
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturerVue(tester, 'entete-messages-zero-390x844')}',
      );
    });
  });
}
