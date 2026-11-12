// PHOTO-TOUCHABLE (directeur, 12/11/2026) : « pour changer la photo ça marche
// mais difficile à deviner, ajoute au moins un petit signe qui fait savoir que
// la photo est touchable ». Un petit badge d'appareil photo au coin de la
// photo, seulement quand le geste existe.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/entete_compte.dart';

import '../../capture/outil_capture.dart' show hoteCapture;
import '../../support/harnais.dart';

const IdentiteCompte _identite = IdentiteCompte(
  nom: 'Maryam Benali',
  role: 'Tuteur',
  matricule: 'RA-26-4817',
);

Future<int> _monter(WidgetTester tester, {required bool geste}) async {
  tester.view.physicalSize = const Size(390, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  int touches = 0;
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: EnteteCompte(
          identite: _identite,
          onChangerPhoto: geste ? () => touches++ : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return touches;
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('avec le geste : un badge crayon, en bas a droite de '
      'la photo, a l interieur de la zone touchable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, geste: true);
    final Finder badge = find.byKey(EnteteCompte.badgePhotoKey);
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.byIcon(AppIcons.crayon.repos)),
      findsOneWidget,
    );
    final Rect photo = tester.getRect(find.byKey(EnteteCompte.photoKey));
    final Rect signe = tester.getRect(badge);
    expect(photo.contains(signe.center), isTrue);
    expect(signe.right, closeTo(photo.right, 0.5));
    expect(signe.bottom, closeTo(photo.bottom, 0.5));
    // L'etiquette du bouton est gardee, le badge n'ajoute rien a lire.
    final noeud = tester.getSemantics(find.byKey(EnteteCompte.photoKey));
    expect(noeud.label, t.compte.page.changerPhoto);
    expect(noeud.flagsCollection.isButton, isTrue);
    semantique.dispose();
  });

  testWidgets('en arabe : le badge passe en bas a gauche', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        Scaffold(
          body: EnteteCompte(identite: _identite, onChangerPhoto: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Rect photo = tester.getRect(find.byKey(EnteteCompte.photoKey));
    final Rect signe = tester.getRect(find.byKey(EnteteCompte.badgePhotoKey));
    expect(signe.left, closeTo(photo.left, 0.5));
    expect(signe.bottom, closeTo(photo.bottom, 0.5));
  });

  testWidgets('la zone touchable ne change pas : toucher la photo ou son '
      'badge ouvre le changement', (WidgetTester tester) async {
    int touches = 0;
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: EnteteCompte(
            identite: _identite,
            onChangerPhoto: () => touches++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EnteteCompte.badgePhotoKey));
    await tester.tap(find.byKey(EnteteCompte.photoKey));
    expect(touches, 2);
  });

  testWidgets('sans le geste (hors ligne, pas de profil) : aucun badge', (
    WidgetTester tester,
  ) async {
    await _monter(tester, geste: false);
    expect(find.byKey(EnteteCompte.badgePhotoKey), findsNothing);
    expect(find.byKey(EnteteCompte.photoKey), findsNothing);
  });
}
