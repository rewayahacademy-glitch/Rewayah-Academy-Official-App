// TB-7b (plan V2 §4.2 ; revue du verificateur, tour 2) : la palette courte
// mesuree avec les polices du depot.
//
// Panneau ferme pendant l'ecriture, la palette (outil actif, Annuler,
// Terminer) prend la place du declencheur « Commandes », qui devient son
// dernier bouton : une seule rangee. La page garde sa hauteur au moment
// meme ou l'on ecrit (au tour 1, la palette posee au-dessus du declencheur
// la reduisait de moitie a 320 x2).
//
// Chaque cas part de /demo/salle (K-07) et passe par les vrais boutons :
// Commandes, Outils, Ecrire, Reduire. Les mesures portent sur le rendu :
// rectangles de la page et des boutons, widgets montes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart'
    show OutilDock;
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _palette = find.byKey(PaletteEcriture.cle);

Future<void> _attendre(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
}

/// Commandes > Outils > Ecrire > Reduire, par les vrais boutons.
Future<void> _ecrireParLesBoutons(WidgetTester tester) async {
  await _taper(tester, _declencheur);
  await _taper(
    tester,
    find.descendant(
      of: find.byKey(CommandesPedagogiques.cleOnglets),
      matching: find.text(t.salle.seance.commandes.ongletOutils),
    ),
  );
  await _taper(tester, find.byKey(const ValueKey<String>('outil-ecrire')));
  expect(
    ProviderScope.containerOf(
      tester.element(find.byType(SalleSeance)),
    ).read(etatOutilsProvider).outilActif,
    OutilDock.stylet,
  );
  await _taper(tester, find.byKey(PanneauSeance.cleReduire));
  // Un trait : « Annuler » parait, la palette a ses quatre boutons (le cas
  // le plus large).
  final Rect page = tester.getRect(_page);
  final TestPointer doigt = TestPointer(71);
  final Offset a = page.topLeft + Offset(page.width * 0.2, page.height * 0.3);
  final Offset b = page.topLeft + Offset(page.width * 0.8, page.height * 0.35);
  await tester.sendEventToBinding(doigt.down(a));
  for (int i = 1; i <= 6; i++) {
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(doigt.up());
  await _attendre(tester);
}

/// La palette tient dans l'ecran, en une rangee, a la place du declencheur ;
/// la page garde au moins 95 % de la hauteur qu'elle avait en lecture.
void _verifier(
  WidgetTester tester,
  Size ecran,
  Rect pageLecture, {
  bool mots = false,
}) {
  expect(tester.takeException(), isNull);
  expect(_palette, findsOneWidget);
  // La hauteur d'abord : c'est le defaut vise (tour 1, 320 x2 : la moitie).
  final Rect page = tester.getRect(_page);
  expect(
    page.height,
    greaterThanOrEqualTo(pageLecture.height * 0.95),
    reason: 'la page en ecrivant ($page) garde sa hauteur ($pageLecture)',
  );
  expect(_declencheur, findsNothing, reason: 'la palette prend sa place');
  if (mots) {
    // La ou ils tiennent, les mots restent sous les icones.
    expect(
      find.descendant(
        of: _palette,
        matching: find.text(t.salle.seance.commandes.declencheur),
      ),
      findsOneWidget,
    );
  }
  final Rect cadre = Offset.zero & ecran;
  final List<Rect> boutons = <Rect>[
    for (final Key cle in <Key>[
      BarreStylet.cleOutilActif,
      BarreStylet.cleAnnuler,
      BarreStylet.cleTerminer,
      BarreStylet.cleCommandes,
    ])
      tester.getRect(find.descendant(of: _palette, matching: find.byKey(cle))),
  ];
  for (final Rect r in <Rect>[tester.getRect(_palette), ...boutons]) {
    expect(cadre.intersect(r) == r, isTrue, reason: '$r dans l ecran');
  }
  // Une seule rangee : tous les boutons sur la meme ligne.
  for (final Rect r in boutons) {
    expect(
      r.center.dy,
      moreOrLessEquals(boutons.first.center.dy, epsilon: 1),
      reason: 'une rangee : $boutons',
    );
  }
  expect(
    page.bottom,
    lessThanOrEqualTo(tester.getRect(_palette).top),
    reason: 'la palette ne recouvre pas la page',
  );
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Palette courte depuis /demo/salle (polices du depot)', () {
    for (final (Size ecran, double texte) cas in <(Size, double)>[
      (const Size(320, 700), 1),
      (const Size(320, 700), 2),
      (const Size(390, 844), 1),
      (const Size(390, 844), 2),
      (const Size(768, 1024), 2),
      (const Size(1440, 900), 1),
      (const Size(1440, 900), 2),
    ]) {
      testWidgets('${cas.$1.width.toInt()} x${cas.$2.toInt()}', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = cas.$2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await monterRouteur(tester, Routes.demoSalle, taille: cas.$1);
        final Finder lien = find.byKey(
          ValueKey<String>(
            'lien-${RoleSeance.enseignant.name}-tb-${SituationTb.ped03.name}',
          ),
        );
        await tester.ensureVisible(lien);
        await tester.pump();
        await tester.tap(lien);
        await stabiliser(tester);
        final Rect lecture = tester.getRect(_page);
        await _ecrireParLesBoutons(tester);
        _verifier(
          tester,
          cas.$1,
          lecture,
          mots: cas.$2 == 1 && cas.$1.width >= 390,
        );
      });
    }

  });

  group('Palette courte en arabe (RTL)', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    for (final double texte in <double>[1, 2]) {
      testWidgets('RTL (arabe) 390 x${texte.toInt()}', (
        WidgetTester tester,
      ) async {
        const Size ecran = Size(390, 844);
        fixerVueCapture(tester, ecran, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            echelleTexte: texte,
          ),
        );
        await _attendre(tester);
        expect(
          Directionality.of(tester.element(find.byType(SalleSeance))),
          TextDirection.rtl,
        );
        final Rect lecture = tester.getRect(_page);
        await _ecrireParLesBoutons(tester);
        _verifier(tester, ecran, lecture);
      });
    }
  });

  testWidgets('rien d enseignant chez l eleve : ni palette, ni Ecrire, meme '
      'outil retenu', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 844), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.eleve,
          situation: SituationTb.ped03,
        ),
      ),
    );
    await _attendre(tester);
    // L'outil retenu comme par un etat reste d'une autre vue : la vue de
    // l'eleve ne doit rien en rendre (capacite voitEcriture).
    ProviderScope.containerOf(
      tester.element(find.byType(SalleSeance)),
    ).read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
    await _attendre(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(SalleSeance), findsOneWidget);
    expect(_palette, findsNothing);
    expect(find.byKey(EcritureSeance.cle), findsNothing);
    expect(find.byKey(const ValueKey<String>('outil-ecrire')), findsNothing);
    expect(find.byKey(BarreStylet.cleCommandes), findsNothing);
  });
}
