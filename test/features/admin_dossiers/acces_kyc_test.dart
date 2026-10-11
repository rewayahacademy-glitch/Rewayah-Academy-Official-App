// BACK-FRONT-KYC-DIR-1 : ce que la revue dit des droits d'ouverture des pieces.
//
// Ce que le test prouve : meme genre (le bouton, rien d'autre) ; exception
// super admin (bandeau, legende « tracee », bouton) ; chaque refus (genre
// different, admin sans genre, profil non autorise) a sa phrase et AUCUN
// bouton « Voir la piece » ; verification en cours et en echec (« Reessayer ») ;
// sans port, la ligne reste celle d'avant ; aucune donnee KYC dans les textes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/dossier/port_acces_pieces_kyc.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

class _Port implements PortAccesPiecesKyc {
  _Port(this.verdict, {this.exception = false, this.echec = false});

  final AccesPieceKyc verdict;
  final bool exception;
  final bool echec;
  Completer<AccesPieceKyc>? retenue;
  int appels = 0;

  @override
  Future<AccesPieceKyc> pour(String dossierId) {
    appels++;
    if (retenue != null) return retenue!.future;
    if (echec && appels == 1) {
      return Future<AccesPieceKyc>.error(StateError('x'));
    }
    return Future<AccesPieceKyc>.value(verdict);
  }

  @override
  Future<bool> exceptionActive() async => exception;
}

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(
  WidgetTester tester,
  PortAccesPiecesKyc? port, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        if (port != null) portAccesPiecesKycProvider.overrideWithValue(port),
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
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
}

void main() {
  final a = t.dossiers.accesKyc;
  final String voir = t.dossiers.revue.voirPiece;

  testWidgets('meme genre : le bouton, ni bandeau ni legende', (tester) async {
    await _monter(tester, _Port(const AccesMemeGenre()));
    expect(find.text(voir), findsOneWidget);
    expect(find.text(a.exceptionTitre), findsNothing);
    expect(find.text(a.exceptionPiece), findsNothing);
  });

  testWidgets('exception super admin : bandeau, legende et bouton', (
    tester,
  ) async {
    await _monter(
      tester,
      _Port(const AccesExceptionSuperAdmin(), exception: true),
    );
    expect(
      find.byKey(const ValueKey<String>('bandeau-exception-kyc')),
      findsOneWidget,
    );
    expect(find.text(a.exceptionTitre), findsOneWidget);
    expect(find.text(a.exceptionPiece), findsOneWidget);
    expect(find.text(voir), findsOneWidget);
  });

  for (final (RefusPieceKyc raison, String phrase) in <(RefusPieceKyc, String)>[
    (RefusPieceKyc.genreDifferent, a.refus.genreDifferent),
    (RefusPieceKyc.adminSansGenre, a.refus.adminSansGenre),
    (RefusPieceKyc.profilNonAutorise, a.refus.profilNonAutorise),
  ]) {
    testWidgets('refus ${raison.name} : sa phrase, aucun bouton', (
      tester,
    ) async {
      await _monter(tester, _Port(AccesRefuse(raison)));
      expect(find.text(phrase), findsOneWidget);
      expect(find.text(voir), findsNothing);
      expect(find.text(a.exceptionTitre), findsNothing);
    });
  }

  testWidgets('verification en cours : pas de bouton', (tester) async {
    final _Port port = _Port(const AccesMemeGenre())
      ..retenue = Completer<AccesPieceKyc>();
    await _monter(tester, port);
    expect(find.text(a.verification), findsOneWidget);
    expect(find.text(voir), findsNothing);
  });

  testWidgets('echec de verification : reessayer, puis le bouton', (
    tester,
  ) async {
    final _Port port = _Port(const AccesMemeGenre(), echec: true);
    await _monter(tester, port);
    expect(find.text(a.verificationEchec), findsOneWidget);
    expect(find.text(voir), findsNothing);
    await tester.tap(find.text(a.reessayer));
    await _stabiliser(tester);
    expect(find.text(voir), findsOneWidget);
    expect(find.text(a.verificationEchec), findsNothing);
  });

  testWidgets('sans port : la ligne reste celle d\'avant', (tester) async {
    await _monter(tester, null);
    expect(find.text(voir), findsOneWidget);
    expect(find.text(a.verification), findsNothing);
  });

  testWidgets('390 px : le refus tient sans rien de coupe', (tester) async {
    await _monter(
      tester,
      _Port(const AccesRefuse(RefusPieceKyc.adminSansGenre)),
      taille: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
  });
}
