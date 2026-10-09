// COM-RC, lot C (revue COM-R) : contre-preuves cote Studio.
//
// - R-07 : un canal en lecture seule est le fil partage (`FilDiscussion` en
//   lecture seule) : ses pieces se montrent par leur carte et leur lecteur,
//   comme dans un canal ouvert a l'ecriture ;
// - R-12 : en Focus, le bandeau de sortie est dans la meme colonne centree
//   que le fil (memes bords) ;
// - R-05 : la route du Studio porte la cloche, la bascule clair / sombre,
//   « Mon compte » et l'identite « Administrateur », comme les coquilles
//   admin, sur le vrai routeur.
//
// Chaque test echouait avant le lot C.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/bascule_theme.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/focus/sortie_focus.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../router/support_routeur.dart';
import 'support_focus.dart';
import 'support_studio.dart';

/// Un canal en lecture seule dont le message porte un document et un vocal.
Canal _canalLectureAvecPieces() {
  final Canal base = canalSimple(ecrire: false);
  final MessageCommunication m = base.messages.single;
  return Canal(
    resume: base.resume,
    membres: base.membres,
    messages: <MessageCommunication>[
      MessageCommunication(
        id: m.id,
        auteur: m.auteur,
        texte: m.texte,
        envoyeLe: m.envoyeLe,
        piecesJointes: <PieceJointe>[
          PieceJointe(
            reference: ReferencePieceJointe('pj-lecture'),
            nom: 'Planning_semaine.pdf',
            nature: NaturePieceJointe.document,
            typeLisible: 'PDF',
            tailleOctets: 120000,
            peutOuvrir: true,
          ),
          PieceJointe(
            reference: ReferencePieceJointe('vocal-lecture'),
            nom: 'vocal.m4a',
            nature: NaturePieceJointe.vocal,
            typeLisible: 'Audio',
            duree: const Duration(seconds: 12),
            peutOuvrir: true,
          ),
        ],
      ),
    ],
    capacites: const <CapaciteCanal>{},
  );
}

/// La vraie application en demonstration admin (aucun serveur).
Future<GoRouter> _monterAdmin(
  WidgetTester tester,
  String depart, {
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
        portStudioProvider.overrideWithValue(portDemo()),
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

void main() {
  group('R-07 : le canal en lecture seule est le fil partage', () {
    testWidgets('ses pieces se montrent par leur carte et leur lecteur', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: FauxStudio(canaux: <Canal>[_canalLectureAvecPieces()]),
        depart: Routes.canalStudioPour('c1'),
      );
      expect(find.byType(FilDiscussion), findsOneWidget);
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      // Avant : une ligne « Piece jointe : ... » et « Message vocal de ... »
      // dans une surface a filets, ni carte ni lecteur.
      expect(find.byType(CartePieceJointe), findsWidgets);
      expect(find.byType(LecteurVocalRecu), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.textContaining('Pièce jointe : Planning_semaine.pdf'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('320, texte x2 : la lecture seule ne deborde pas', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: FauxStudio(canaux: <Canal>[_canalLectureAvecPieces()]),
        depart: Routes.canalStudioPour('c1'),
        taille: const Size(320, 640),
        echelleTexte: 2,
      );
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('R-12 : le bandeau de sortie dans la colonne du fil', () {
    for (final Size taille in <Size>[
      const Size(1440, 900),
      const Size(390, 844),
    ]) {
      testWidgets('${taille.width.toInt()} : memes bords que le fil', (
        WidgetTester tester,
      ) async {
        await monterStudio(
          tester,
          port: portFocus(),
          depart: Routes.canalStudioPour('c1'),
          taille: taille,
        );
        await entrer(tester);
        final Rect bandeau = tester.getRect(find.byKey(BandeauSortieFocus.cle));
        final Rect fil = tester.getRect(find.byType(CanalStudio));
        expect(bandeau.left, fil.left);
        expect(bandeau.right, fil.right);
        expect(
          find.descendant(
            of: find.byKey(EspaceStudio.cleCentre),
            matching: find.byKey(BandeauSortieFocus.cle),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('R-05 : la coquille du Studio, comme les coquilles admin', () {
    testWidgets('1440 : cloche, bascule clair / sombre, Mon compte et '
        '« Administrateur » dans la colonne', (WidgetTester tester) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.adminStudio);
      expect(find.byType(CoquilleStudio), findsOneWidget);
      expect(find.byType(ClocheNotifications), findsOneWidget);
      expect(find.byType(BasculeTheme), findsOneWidget);
      expect(find.byKey(cleCompteStudio), findsOneWidget);
      final NavShell nav = tester.widget<NavShell>(find.byType(NavShell));
      expect(nav.secondaires.map((Destination d) => d.libelle), <String>[
        t.compte.roles.admin,
      ]);
      expect(
        find.descendant(
          of: find.byKey(NavShell.barreLateraleKey),
          matching: find.text(t.compte.roles.admin),
        ),
        findsOneWidget,
      );
      // La cloche mene aux notifications de l'admin.
      await tester.tap(find.byType(ClocheNotifications));
      await stabiliser(tester);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.adminNotifications,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : l identite « Administrateur » mene au compte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(tester, Routes.adminStudio);
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.barreLateraleKey),
          matching: find.text(t.compte.roles.admin),
        ),
      );
      await stabiliser(tester);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.compte,
      );
    });

    testWidgets('390 : cloche et Mon compte dans l en-tete d un canal', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterAdmin(
        tester,
        Routes.canalStudioPour('organisation'),
        taille: const Size(390, 844),
      );
      expect(find.byType(ClocheNotifications), findsOneWidget);
      expect(find.byKey(cleCompteStudio), findsOneWidget);
      await tester.tap(find.byKey(cleCompteStudio));
      await stabiliser(tester);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.compte,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('320, texte x2 : l en-tete du Studio ne deborde pas', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monterAdmin(
        tester,
        Routes.adminStudio,
        taille: const Size(320, 640),
      );
      expect(find.byType(ClocheNotifications), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
