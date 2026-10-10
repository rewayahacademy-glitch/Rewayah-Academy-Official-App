// AD-7 : la visionneuse de piece sur la VRAIE coque admin et le vrai routeur,
// en demonstration (`?demo=admin`). Chaque ouverture part du bouton reel
// « Voir la piece » de la revue (K-07).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../support/hors_ligne_une_fois.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  List<Override> plus = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        ...plus,
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
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// Personnes depuis la coque, la ligne du dossier, puis « Voir la piece ».
Future<void> _voirPiece(WidgetTester tester, String prenom) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(
              RegExp(AdminDomaine.personnes.libelle),
            ),
          )
          .first,
    );
  } else if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  if (rail.evaluate().isEmpty) {
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
  }
  await _stabiliser(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
  final Finder bouton = find.text(t.dossiers.revue.voirPiece);
  await tester.ensureVisible(bouton);
  await _stabiliser(tester);
  await tester.tap(bouton);
  await _stabiliser(tester);
}

bool _focusSurVoirPiece() =>
    FocusManager.instance.primaryFocus?.debugLabel == 'adm02b-voir-piece';

double _echelle(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

void main() {
  testWidgets('1440 : dialogue borne, piece fictive, fermer rend le focus', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Omar');

    expect(find.byType(VisionneusePiece), findsOneWidget);
    expect(find.text(t.dossiers.visionneuse.documentFictif), findsOneWidget);
    expect(find.text('Document fictif'), findsOneWidget);
    expect(tester.getSize(find.byType(VisionneusePiece)).width, lessThan(800));
    expect(find.textContaining('http'), findsNothing);
    expect(find.textContaining('République'), findsNothing);
    expect(find.text(t.dossiers.refuser), findsOneWidget); // sous le voile
    expect(
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: find.textContaining('Valider'),
      ),
      findsNothing,
    );

    // Le voile ne ferme pas.
    await tester.tapAt(const Offset(10, 10));
    await _stabiliser(tester);
    expect(find.byType(VisionneusePiece), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: find.text(t.commun.fermer),
      ),
    );
    await _stabiliser(tester);
    expect(find.byType(VisionneusePiece), findsNothing);
    expect(_focusSurVoirPiece(), isTrue);
  });

  testWidgets('1440 : la croix « Fermer la piece » ferme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Omar');
    await tester.tap(find.bySemanticsLabel(t.dossiers.visionneuse.fermerPiece));
    await _stabiliser(tester);
    expect(find.byType(VisionneusePiece), findsNothing);
    expect(_focusSurVoirPiece(), isTrue);
  });

  testWidgets('1440 : Echap ferme et rend le focus', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Omar');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _stabiliser(tester);
    expect(find.byType(VisionneusePiece), findsNothing);
    expect(_focusSurVoirPiece(), isTrue);
  });

  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('${taille.width.toInt()} : plein ecran, disque retour', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille);
      await _voirPiece(tester, 'Omar');
      expect(find.byType(VisionneusePiece), findsOneWidget);
      expect(find.text(t.dossiers.visionneuse.documentFictif), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(t.dossiers.visionneuse.fermerPiece),
      );
      await _stabiliser(tester);
      expect(find.byType(VisionneusePiece), findsNothing);
      expect(_focusSurVoirPiece(), isTrue);
    });
  }

  testWidgets('zoom : paliers de 25 %, bornes 100 et 400 %, raccourcis', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Omar');
    expect(_echelle(tester), closeTo(1, 1e-6));

    final Finder agrandir = find.bySemanticsLabel(
      t.dossiers.visionneuse.agrandir,
    );
    final Finder reduire = find.bySemanticsLabel(
      t.dossiers.visionneuse.reduire,
    );
    expect(tester.getSize(agrandir).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(agrandir).height, greaterThanOrEqualTo(48));
    // BOUTONS-GRISES-1 : a la borne, le bouton disparait (jamais grise),
    // sa place reste reservee (NAV-FLECHES-1).
    bool visible(String libelle) => tester
        .widget<Visibility>(
          find.ancestor(
            of: find.byWidgetPredicate(
              (Widget w) => w is BoutonIcone && w.libelle == libelle,
            ),
            matching: find.byType(Visibility),
          ),
        )
        .visible;
    expect(visible(t.dossiers.visionneuse.reduire), isFalse);
    expect(visible(t.dossiers.visionneuse.agrandir), isTrue);
    for (int i = 0; i < 12; i++) {
      await tester.tap(agrandir);
      await tester.pump();
    }
    expect(_echelle(tester), closeTo(4, 1e-6));
    expect(visible(t.dossiers.visionneuse.agrandir), isFalse);
    expect(visible(t.dossiers.visionneuse.reduire), isTrue);
    await tester.tap(reduire);
    await tester.pump();
    expect(_echelle(tester), closeTo(3.75, 1e-6));

    await tester.tap(find.bySemanticsLabel(t.dossiers.visionneuse.ajuster));
    await tester.pump();
    expect(_echelle(tester), closeTo(1, 1e-6));

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(_echelle(tester), closeTo(1.25, 1e-6));
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(_echelle(tester), closeTo(1, 1e-6));
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.pump();
    expect(_echelle(tester), closeTo(1.5, 1e-6));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pump();
    expect(_echelle(tester), closeTo(1, 1e-6));
  });

  testWidgets('molette et pincement ne descendent jamais sous 100 %', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Omar');
    final Offset centre = tester.getCenter(find.byType(InteractiveViewer));
    // Molette vers le bas : InteractiveViewer reduit l'echelle.
    final TestPointer souris = TestPointer(1, PointerDeviceKind.mouse);
    for (int i = 0; i < 5; i++) {
      await tester.sendEventToBinding(souris.hover(centre));
      await tester.sendEventToBinding(souris.scroll(const Offset(0, 400)));
      await tester.pump();
    }
    expect(_echelle(tester), greaterThanOrEqualTo(1 - 1e-6));
    // Pincement : deux doigts qui se rapprochent.
    final TestGesture a = await tester.startGesture(
      centre - const Offset(80, 0),
    );
    final TestGesture b = await tester.startGesture(
      centre + const Offset(80, 0),
      pointer: 7,
    );
    for (int i = 0; i < 6; i++) {
      await a.moveBy(const Offset(12, 0));
      await b.moveBy(const Offset(-12, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await _stabiliser(tester);
    expect(_echelle(tester), greaterThanOrEqualTo(1 - 1e-6));
    // Les info-bulles disent la touche du raccourci.
    expect(
      find.byTooltip(
        t.dossiers.visionneuse.infoBulle(
          action: t.dossiers.visionneuse.agrandir,
          touche: '+',
        ),
      ),
      findsOneWidget,
    );
    // Seul le texte exact de la spec : aucune phrase generique d'etat.
    expect(find.text(t.commun.etats.ressourceExpiree.phrase), findsNothing);
    // Focus initial visible : sur « Fermer », jamais sur un noeud nu.
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'visionneuse-fermer',
    );
    // « Fermer » au contenu, sur la ligne du zoom, a la fin.
    final Rect fermer = tester.getRect(
      find
          .ancestor(
            of: find.descendant(
              of: find.byType(VisionneusePiece),
              matching: find.text(t.commun.fermer),
            ),
            matching: find.byType(ActionPrincipale),
          )
          .first,
    );
    final Rect zoom = tester.getRect(
      find.bySemanticsLabel(t.dossiers.visionneuse.agrandir),
    );
    final Rect surface = tester.getRect(find.byType(VisionneusePiece));
    expect(fermer.width, lessThan(surface.width / 2));
    expect((fermer.center.dy - zoom.center.dy).abs(), lessThan(8));
    expect(fermer.right, closeTo(surface.right, 1));
  });

  testWidgets('lien expire : texte exact seul, sans phrase generique', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Karim');
    expect(find.text(t.dossiers.visionneuse.expire), findsOneWidget);
    expect(find.text(t.commun.etats.ressourceExpiree.phrase), findsNothing);
  });

  testWidgets('lien expire : « Recharger la piece » redemande la vue', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _voirPiece(tester, 'Karim');
    expect(find.text("L'accès à cette pièce a expiré."), findsOneWidget);
    expect(find.text(t.dossiers.visionneuse.expire), findsOneWidget);
    await tester.tap(find.text(t.dossiers.visionneuse.recharger));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.visionneuse.documentFictif), findsOneWidget);
    expect(find.text(t.dossiers.visionneuse.expire), findsNothing);
  });
  // EA-HL-DOUBLE-1d : hors ligne, la feuille de la piece ne redit pas le
  // reseau. Le « wifi barre » est celui du bandeau ; la piece qui manque
  // prend l'attente (sablier).
  testWidgets('hors ligne : la piece manquante prend le sablier, jamais un '
      'second « wifi barre »', (WidgetTester tester) async {
    await _monter(
      tester,
      const Size(1440, 900),
      plus: <Override>[
        horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
      ],
    );
    await _voirPiece(tester, 'Karim');
    expect(find.text(t.dossiers.visionneuse.horsLigne), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: iconesHorsLigne(),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: find.byIcon(AppIcons.attente.actif),
      ),
      findsOneWidget,
    );
  });
}
