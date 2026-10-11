// LOGO-APP (10/10/2026) : ou le logo apparait, et seulement la.
//
// - coquille des roles (NavShell) : logo horizontal en tete de la barre
//   laterale (bureau), symbole en tete du rail (tablette), rien sur telephone
//   (la barre basse n'est pas un en-tete) ; un seul par ecran ; il ramene a
//   l'accueil du role ; au debut de ligne, aussi en arabe ;
// - coquille admin : horizontal (barre laterale, tiroir), symbole (rail),
//   rien dans la barre mobile ;
// - connexion : logo vertical ; demarrage : aucun logo (animation a venir,
//   decision du directeur du 10/10).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../support/harnais.dart';
import '../support/hote_theme.dart';
import '../support/logo.dart';

Future<void> _monterNav(
  WidgetTester tester, {
  required Size taille,
  TextDirection direction = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
  void Function(String chemin)? onAller,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          builder: (BuildContext context, Widget? app) =>
              Directionality(textDirection: direction, child: app!),
          home: Scaffold(
            body: NavShell(
              destinations: destinationsPour(
                role: AppRole.teacher,
                mode: InterfaceMode.standard,
              ),
              indexActif: 1,
              onAller: onAller ?? (String _) {},
              child: const SizedBox.expand(key: Key('contenu')),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('coquille des roles', () {
    testWidgets('bureau : un seul logo horizontal, lien vers l accueil', (
      WidgetTester tester,
    ) async {
      final List<String> allers = <String>[];
      await _monterNav(tester, taille: vueBureau, onAller: allers.add);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(logoRendu(VarianteLogo.horizontal), findsOneWidget);
      await tester.tap(find.byType(BrandLogo));
      expect(allers, <String>[
        destinationsPour(
          role: AppRole.teacher,
          mode: InterfaceMode.standard,
        ).first.chemin,
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bureau sombre : meme violet de marque', (
      WidgetTester tester,
    ) async {
      await _monterNav(tester, taille: vueBureau, luminosite: Brightness.dark);
      expect(
        tester.renderObject<RenduLogo>(find.byType(LogoPeint)).couleur,
        BrandLogo.couleur(FondLogo.page),
      );
    });

    testWidgets('tablette : le symbole seul, en tete du rail', (
      WidgetTester tester,
    ) async {
      await _monterNav(tester, taille: vueTablette);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(logoRendu(VarianteLogo.symbole), findsOneWidget);
      expect(
        tester.renderObject<RenduLogo>(find.byType(LogoPeint)).hauteurDessin,
        greaterThanOrEqualTo(BrandLogo.minimumSymbole),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone : aucun logo dans la barre basse', (
      WidgetTester tester,
    ) async {
      await _monterNav(tester, taille: vueMobile);
      expect(find.byType(BrandLogo), findsNothing);
    });

    testWidgets('arabe : le logo reste au debut de ligne (a droite)', (
      WidgetTester tester,
    ) async {
      await _monterNav(tester, taille: vueBureau, direction: TextDirection.rtl);
      final Rect logo = tester.getRect(logoRendu(VarianteLogo.horizontal));
      final Rect colonne = tester.getRect(
        find.byKey(NavShell.barreLateraleKey),
      );
      // La colonne est a droite, le logo a son bord droit (debut de ligne).
      expect(colonne.right, vueBureau.width);
      expect(logo.center.dx, greaterThan(colonne.center.dx));
    });
  });

  group('coquille admin', () {
    Widget shell(void Function(String) onAller) => AdminShell(
      domaines: domainesAdmin(voitDirection: true),
      domaineActif: AdminDomaine.accueil,
      onAller: onAller,
      onCompte: () {},
      child: const PageShell(child: SizedBox()),
    );

    testWidgets('barre laterale : horizontal, lien vers l accueil admin', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueBureau);
      final List<String> allers = <String>[];
      await tester.pumpWidget(hote(shell(allers.add)));
      await tester.pump();
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(logoRendu(VarianteLogo.horizontal), findsOneWidget);
      await tester.tap(find.byType(BrandLogo));
      expect(allers, <String>[Routes.admin]);
    });

    testWidgets('telephone : rien dans la barre, horizontal dans le tiroir', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      final List<String> allers = <String>[];
      await tester.pumpWidget(hote(shell(allers.add)));
      await tester.pump();
      expect(find.byType(BrandLogo), findsNothing);
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await tester.pumpAndSettle();
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(logoRendu(VarianteLogo.horizontal), findsOneWidget);
      await tester.tap(find.byType(BrandLogo));
      await tester.pumpAndSettle();
      expect(allers, <String>[Routes.admin]);
      expect(find.byKey(AdminShell.tiroirKey), findsNothing);
    });
  });

  for (final Size vue in <Size>[const Size(320, 640), vueBureau]) {
    testWidgets('connexion : logo vertical centre (${vue.width} px)', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vue);
      await tester.pumpWidget(
        hoteTheme(
          const ConnexionPage(),
          defilant: false,
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(logoRendu(VarianteLogo.vertical), findsOneWidget);
      final Rect logo = tester.getRect(logoRendu(VarianteLogo.vertical));
      expect(
        tester.renderObject<RenduLogo>(find.byType(LogoPeint)).hauteurDessin,
        greaterThanOrEqualTo(BrandLogo.minimumVertical),
      );
      expect(logo.center.dx, closeTo(vue.width / 2, 1));
      expect(find.bySemanticsLabel(t.commun.marque), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demarrage : aucun logo (animation a venir)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        const EcranDemarrage(),
        defilant: false,
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      ),
    );
    await tester.pump();
    expect(find.byType(BrandLogo), findsNothing);
  });
}
