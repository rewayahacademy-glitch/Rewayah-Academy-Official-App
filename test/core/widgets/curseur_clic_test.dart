// CURSEUR-CLIC (directeur, 08/11/2026) : « sur web c'est excessif ; [...] sur
// chaque lien, quand tu viens pour cliquer, c'est le curseur de copier qui
// s'affiche, alors que tu as besoin de la fleche pour cliquer vite ».
//
// Sous le `SelectionArea` racine (decision du 07/11), un `Text` s'entoure de
// son propre curseur de texte. Ce qui se touche (`Pressable`, donc boutons,
// liens, lignes, cartes) doit garder la fleche et sortir de la
// selection ; le texte de contenu reste copiable.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../../support/hote_selection.dart';

const String _contenu = 'Le cours de tajwid commence a dix-huit heures';
const String _lien = 'Voir le cahier de Yasmine';
const String _bouton = 'Rejoindre la salle';
const String _ligne = 'Notifications de la classe';

Widget _ecran() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    const Text(_contenu),
    LienFleche(libelle: _lien, onPress: () {}),
    ActionPrincipale(libelle: _bouton, onPress: () {}, pleineLargeur: false),
    SettingRow(title: _ligne, onPress: () {}),
    BoutonIcone(icone: AppIcons.accueil, libelle: 'Accueil', onPress: () {}),
  ],
);

Future<TestGesture> _souris(WidgetTester tester) async {
  final TestGesture souris = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await souris.addPointer(location: Offset.zero);
  addTearDown(souris.removePointer);
  return souris;
}

Future<MouseCursor?> _curseurSur(
  WidgetTester tester,
  TestGesture souris,
  Finder cible,
) async {
  await souris.moveTo(tester.getCenter(cible));
  await tester.pump();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

void main() {
  testWidgets('la fleche sur un lien, un bouton, une ligne et une icone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteSelection(_ecran()));
    await tester.pumpAndSettle();
    final TestGesture souris = await _souris(tester);

    // Le pointeur pose sur le texte meme du libelle : c'est la que le
    // curseur de copie l'emportait.
    expect(
      await _curseurSur(tester, souris, find.text(_lien)),
      SystemMouseCursors.click,
    );
    expect(
      await _curseurSur(tester, souris, find.text(_bouton)),
      SystemMouseCursors.click,
    );
    expect(
      await _curseurSur(tester, souris, find.text(_ligne)),
      SystemMouseCursors.click,
    );
    expect(
      await _curseurSur(tester, souris, find.byType(BoutonIcone)),
      SystemMouseCursors.click,
    );
  });

  testWidgets('le texte de contenu garde le curseur de texte et se copie', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteSelection(_ecran()));
    await tester.pumpAndSettle();
    final TestGesture souris = await _souris(tester);
    expect(
      await _curseurSur(tester, souris, find.text(_contenu)),
      SystemMouseCursors.text,
    );

    final String copie = await toutCopier(tester);
    expect(copie, contains(_contenu));
    // Les libelles de ce qui se touche ne partent pas avec un « Tout
    // selectionner » : un appui ne doit jamais amorcer une selection.
    expect(copie, isNot(contains(_lien)));
    expect(copie, isNot(contains(_bouton)));
    expect(copie, isNot(contains(_ligne)));
  });
}
