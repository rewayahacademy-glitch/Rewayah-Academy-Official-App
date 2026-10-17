// E1 (demande du directeur du 17/10/2026) : la case d'accord est une carte
// pressable entiere. Un appui n'importe ou sur la carte, marge interieure
// comprise, coche puis decoche ; la carte se lit comme une case cochee ; le
// clavier la coche ; sans geste (envoi en cours, accord fige), rien ne bouge.
//
// Contre-epreuve : sur l'ancien code (6b510106), un `CheckboxListTile` pose
// dans une `AppCard` laissait la marge de la carte inerte (appui a 6 px du
// bord : case restee decochee, audit d'entree 1.1).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/consentements/texte_observation.dart';

import '../../support/hote_theme.dart';

const String _libelle = "J'accepte ces modalites pour mon enfant.";

/// Un hote qui tient l'etat de la case, comme un ecran appelant.
class _Hote extends StatefulWidget {
  const _Hote({this.figee = false, this.focusNode});

  final bool figee;
  final FocusNode? focusNode;

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  bool cochee = false;

  @override
  Widget build(BuildContext context) => CaseAccordTexte(
    libelle: _libelle,
    cochee: widget.figee || cochee,
    focusNode: widget.focusNode,
    onChanged: widget.figee
        ? null
        : (bool valeur) => setState(() => cochee = valeur),
  );
}

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  bool figee = false,
  FocusNode? focusNode,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hoteTheme(_Hote(figee: figee, focusNode: focusNode)));
  await tester.pumpAndSettle();
}

bool _cochee(WidgetTester tester) =>
    tester.widget<CaseAccordTexte>(find.byType(CaseAccordTexte)).cochee;

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      '${taille.width.toInt()} : appui n importe ou sur la carte coche puis '
      'decoche',
      (WidgetTester tester) async {
        await _monter(tester, taille: taille);
        final Rect carte = tester.getRect(find.byType(AppCard));
        final List<(String, Offset)> points = <(String, Offset)>[
          ('centre', carte.center),
          ('sur le libelle', tester.getCenter(find.text(_libelle))),
          ('sur la case', tester.getCenter(find.byType(Checkbox))),
          ('marge start', carte.centerLeft + const Offset(6, 0)),
          ('marge end', carte.centerRight - const Offset(6, 0)),
          ('marge haute', carte.topCenter + const Offset(0, 6)),
          ('marge basse', carte.bottomCenter - const Offset(0, 6)),
          ('coin haut start', carte.topLeft + const Offset(12, 12)),
          ('coin bas end', carte.bottomRight - const Offset(12, 12)),
        ];
        for (final (String ou, Offset point) in points) {
          expect(_cochee(tester), isFalse, reason: ou);
          await tester.tapAt(point);
          await tester.pumpAndSettle();
          expect(_cochee(tester), isTrue, reason: ou);
          expect(
            tester.widget<Checkbox>(find.byType(Checkbox)).value,
            isTrue,
            reason: ou,
          );
          await tester.tapAt(point);
          await tester.pumpAndSettle();
          expect(_cochee(tester), isFalse, reason: ou);
        }
      },
    );
  }

  testWidgets('survol : curseur main ; cochee : la carte entiere le montre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 900));
    expect(tester.widget<AppCard>(find.byType(AppCard)).selectionnee, isFalse);
    // Sur ordinateur et sur le Web a la souris, le mode de surbrillance
    // est le mode classique ; le test tourne sous Android (tactile).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final TestGesture souris = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await souris.addPointer(location: Offset.zero);
    addTearDown(souris.removePointer);
    await souris.moveTo(
      tester.getRect(find.byType(AppCard)).centerRight - const Offset(6, 0),
    );
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
    await tester.tap(find.byType(AppCard));
    await tester.pumpAndSettle();
    expect(tester.widget<AppCard>(find.byType(AppCard)).selectionnee, isTrue);
  });

  testWidgets('cible : au moins 48, une case cochable lue avec son libelle', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, taille: const Size(390, 844));
    expect(
      tester.getSize(find.byType(AppCard)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byType(AppCard));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(AppCard)),
      isSemantics(
        label: _libelle,
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    semantique.dispose();
  });

  testWidgets('clavier : le focus de l appelant et Espace cochent', (
    WidgetTester tester,
  ) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    await _monter(tester, taille: const Size(390, 844), focusNode: focus);
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_cochee(tester), isTrue);
  });

  testWidgets('sans geste : la carte ne coche ni ne decoche', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(390, 844), figee: true);
    expect(_cochee(tester), isTrue);
    await tester.tapAt(tester.getCenter(find.byType(AppCard)));
    await tester.pumpAndSettle();
    expect(_cochee(tester), isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
  });
}
