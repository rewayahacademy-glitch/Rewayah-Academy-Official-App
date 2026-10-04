// CORAN-CARTE-3 : `SettingRow` posee nue dans une carte (sans icone de tete,
// sans fond ni marge propres), annoncee comme lien. Elle remplace `LigneLien`
// (lib/CLAUDE.md : `SettingRow` est le point d'entree de « la ligne qui se
// touche », on l'ameliore, on n'en recree pas une).
//
// Un seul lien nomme par le titre ; titre au bord de debut, chevron au bord
// de fin (miroir en RTL) ; aucun mot coupe a 200 % ; cible d'au moins la
// cible tactile du mode, texte pose en bas de cette cible ; chevron a la
// taille du mode. Le rendu par defaut ne change pas.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

const Key _ligne = ValueKey<String>('ligne');
const String _titre = 'Le Coran';
const String _legende = 'A lire quand tu veux, chaque jour, sans attendre';

void main() {
  setUpAll(chargerPolicesDuDepot);

  Future<int> monter(
    WidgetTester tester, {
    double echelle = 1,
    TextDirection sens = TextDirection.ltr,
    double largeur = 320,
    InterfaceMode mode = InterfaceMode.standard,
    Widget? ligne,
  }) async {
    int ouvertures = 0;
    fixerVueCapture(tester, Size(largeur, 640), 1);
    await tester.pumpWidget(
      hoteCapture(
        Directionality(
          textDirection: sens,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.topCenter,
                child:
                    ligne ??
                    SettingRow(
                      key: _ligne,
                      title: _titre,
                      description: _legende,
                      nue: true,
                      lien: true,
                      onPress: () => ouvertures++,
                    ),
              ),
            ),
          ),
        ),
        echelleTexte: echelle,
        interfaceMode: mode,
      ),
    );
    await tester.pumpAndSettle();
    if (ligne == null) await tester.tap(find.text(_legende));
    return ouvertures;
  }

  Finder chevron() => find.descendant(
    of: find.byKey(_ligne),
    matching: find.byIcon(AppIcons.chevron.repos),
  );

  testWidgets('un seul lien, nomme par le titre, legende lue a la suite', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    expect(await monter(tester), 1);
    final Finder lien = find.bySemanticsLabel(RegExp('^$_titre'));
    expect(lien, findsOneWidget);
    final SemanticsNode noeud = tester.getSemantics(lien);
    expect(noeud.label, '$_titre\n$_legende');
    expect(noeud.flagsCollection.isLink, isTrue);
    expect(noeud.flagsCollection.isButton, isFalse);
    poignee.dispose();
  });

  for (final TextDirection sens in TextDirection.values) {
    testWidgets(
      '${sens.name} : sans marge, chevron au bord de fin, titre au debut',
      (WidgetTester tester) async {
        await monter(tester, sens: sens);
        final Rect ligne = tester.getRect(find.byKey(_ligne));
        final Rect c = tester.getRect(chevron());
        final Rect titre = tester.getRect(find.text(_titre));
        expect(
          ligne.width,
          320 - 2 * AppSpacing.lg,
          reason: 'la ligne prend toute la largeur',
        );
        expect(ligne.height, greaterThanOrEqualTo(48));
        if (sens == TextDirection.ltr) {
          expect(c.right, ligne.right);
          expect(titre.left, ligne.left);
        } else {
          expect(c.left, ligne.left);
          expect(titre.right, ligne.right);
        }
        // Titre et legende a 8 (DESIGN-GOV, contrat A).
        expect(
          tester.getRect(find.text(_legende)).top - titre.bottom,
          AppSpacing.sm,
        );
      },
    );
  }

  testWidgets('mode enfant : cible de 72, texte en bas, chevron agrandi', (
    WidgetTester tester,
  ) async {
    await monter(tester, mode: InterfaceMode.enfant, largeur: 390);
    final Rect ligne = tester.getRect(find.byKey(_ligne));
    expect(ligne.height, greaterThanOrEqualTo(72));
    // Le texte est pose en bas de la cible : pas d'air propre sous la
    // legende, la carte donne le sien.
    expect(tester.getRect(find.text(_legende)).bottom, ligne.bottom);
    expect(tester.getSize(chevron()).width, AppSpacing.xxl);
  });

  testWidgets('texte x2 a 320 : aucun mot coupe, aucun debordement', (
    WidgetTester tester,
  ) async {
    await monter(tester, echelle: 2);
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(_ligne),
        matching: find.byType(TexteSansCoupure),
      ),
      findsNWidgets(2),
    );
    verifierAucunMotCoupe(tester, find.byKey(_ligne));
    expect(chevron(), findsOneWidget);
  });

  testWidgets('par defaut : rendu inchange (icone, marge, 64, bouton)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    await monter(
      tester,
      ligne: SettingRow(
        key: _ligne,
        title: _titre,
        icon: AppIcons.reglages,
        onPress: () {},
      ),
    );
    final Rect ligne = tester.getRect(find.byKey(_ligne));
    expect(ligne.height, greaterThanOrEqualTo(AppPage.hauteurReglage));
    expect(
      tester.getRect(find.byIcon(AppIcons.reglages.repos)).left - ligne.left,
      AppSpacing.lg,
    );
    expect(tester.getSize(chevron()).width, AppSpacing.xl);
    final SemanticsNode noeud = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^$_titre')),
    );
    expect(noeud.flagsCollection.isButton, isTrue);
    expect(noeud.flagsCollection.isLink, isFalse);
    poignee.dispose();
  });
}
