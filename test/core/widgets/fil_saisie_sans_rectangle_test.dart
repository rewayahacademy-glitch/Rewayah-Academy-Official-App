// CONVERSATIONS-PARTOUT (directeur, 16/11/2026, « supprime le rectangle ») :
// le champ de saisie et le bouton image flottent directement sur le fond de la
// conversation : ni boite, ni bande, ni filet, ni ombre derriere eux.
//
// Garde de rendu : on remonte de la zone de saisie et du bouton image jusqu'au
// fil ; tout ancetre qui peint un fond, un bord ou une ombre echoue, SAUF le
// fond du fil lui-meme (`fondFil`), qui prolonge la liste des messages derriere
// la saisie : c'est le meme fond, donc aucun rectangle visible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';

import '../../support/hote_theme.dart';

/// Vrai si un ancetre, entre [depart] et le fil, peint le fond du fil : le champ
/// repose sur le fond de la conversation (et non sur le fond de la page, sous
/// un rectangle gris qui s'arreterait au-dessus de lui).
bool _surFondDuFil(Element depart, Color fondFil) {
  bool trouve = false;
  depart.visitAncestorElements((Element e) {
    final Widget w = e.widget;
    if (w is FilDiscussion) return false;
    if (w is ColoredBox && w.color == fondFil) trouve = true;
    return true;
  });
  return trouve;
}

/// Ce que peint un ancetre entre la saisie et le fil, hors du fond du fil.
List<String> _intrus(Element depart, Color fondFil) {
  final List<String> intrus = <String>[];
  depart.visitAncestorElements((Element e) {
    final Widget w = e.widget;
    if (w is FilDiscussion) return false;
    bool fondDuFil(Color? c) => c == null || c == fondFil;
    if (w is ColoredBox && !fondDuFil(w.color)) {
      intrus.add('ColoredBox ${w.color}');
    }
    if (w is DecoratedBox) {
      final Decoration d = w.decoration;
      if (d is BoxDecoration) {
        if (!fondDuFil(d.color)) intrus.add('DecoratedBox fond ${d.color}');
        if (d.border != null) intrus.add('DecoratedBox bord');
        if (d.gradient != null) intrus.add('DecoratedBox degrade');
        if (d.boxShadow != null && d.boxShadow!.isNotEmpty) {
          intrus.add('DecoratedBox ombre');
        }
      } else {
        intrus.add('DecoratedBox ${d.runtimeType}');
      }
    }
    if (w is Material &&
        w.type != MaterialType.transparency &&
        !(w.color == null || w.color == Colors.transparent)) {
      intrus.add('Material ${w.color}');
    }
    if (w is PhysicalModel || w is PhysicalShape || w is Card) {
      intrus.add(w.runtimeType.toString());
    }
    return true;
  });
  return intrus;
}

Future<void> _monter(
  WidgetTester tester, {
  required Size vue,
  required bool pleinEcran,
  double echelle = 1,
}) async {
  fixerVue(tester, vue);
  await tester.pumpWidget(
    hoteTheme(
      FilDiscussion(
        messages: const <MessageFil>[],
        textes: textesFilCommunication(),
        onEnvoyer: (String _) async {},
        onEnvoyerImage: (
          String _,
          String _,
          ImagePrete _,
          ProgressionImage _,
        ) async {},
        deuxChoixPhoto: false,
        pleinEcran: pleinEcran,
      ),
      echelleTexte: echelle,
      defilant: false,
    ),
  );
  await tester.pump();
}

void main() {
  final List<(String, Size, bool, double)> cas = <(String, Size, bool, double)>[
    ('telephone plein ecran', const Size(390, 844), true, 1),
    ('ordinateur', const Size(1440, 900), false, 1),
    ('tablette', const Size(768, 1024), false, 1),
    ('telephone en page a titre', const Size(390, 844), false, 1),
    (
      'telephone texte x2 (saisie dans la liste)',
      const Size(390, 844),
      false,
      2,
    ),
  ];
  for (final (String nom, Size vue, bool plein, double echelle) in cas) {
    testWidgets('$nom : rien ne peint derriere le champ ni le bouton image', (
      WidgetTester tester,
    ) async {
      await _monter(tester, vue: vue, pleinEcran: plein, echelle: echelle);
      final Color fondFil = AppPalette.of(
        tester.element(find.byType(FilDiscussion)),
      ).fondFil.background;
      expect(find.byType(ZoneSaisie), findsOneWidget);
      expect(find.byKey(FilDiscussion.cleImage), findsOneWidget);
      expect(
        _intrus(tester.element(find.byType(ZoneSaisie)), fondFil),
        isEmpty,
        reason: 'le champ',
      );
      expect(
        _intrus(tester.element(find.byKey(FilDiscussion.cleImage)), fondFil),
        isEmpty,
        reason: 'le bouton image',
      );
      expect(
        _surFondDuFil(tester.element(find.byType(ZoneSaisie)), fondFil),
        isTrue,
        reason: 'le champ repose sur le fond de la conversation',
      );
      expect(
        _surFondDuFil(
          tester.element(find.byKey(FilDiscussion.cleImage)),
          fondFil,
        ),
        isTrue,
        reason: 'le bouton image repose sur le fond de la conversation',
      );
    });
  }

  testWidgets('la garde voit un rectangle (contre-epreuve)', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(1440, 900));
    late Color fond;
    await tester.pumpWidget(
      hoteTheme(
        Builder(
          builder: (BuildContext context) {
            fond = AppPalette.of(context).fondFil.background;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      hoteTheme(
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(top: BorderSide()),
          ),
          child: SizedBox(key: ValueKey<String>('sous'), height: 10),
        ),
      ),
    );
    final List<String> intrus = _intrus(
      tester.element(find.byKey(const ValueKey<String>('sous'))),
      fond,
    );
    expect(intrus, containsAll(<String>['DecoratedBox bord']));
  });
}
