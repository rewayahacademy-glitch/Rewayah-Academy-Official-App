// ENTREE-PRAXIS (pilote, 20/11/2026, maquette « Praxis vous accueille ») :
// deux parametres facultatifs d'`ActionPrincipale`, pour la page d'entree
// seulement.
// - `libelleAttente` : pendant l'envoi, le bouton reste plein (peinture de son
//   niveau), dit « Envoi du lien… » qui bat doucement, sans anneau ; il reste
//   inactif (pas de second envoi) et garde son etiquette ; aucun battement
//   sous « Réduire les effets ».
// - `filetPale` : le secondaire prend le filet le plus pale.
// Non-regression : sans ces parametres, rien ne change (anneau, peinture
// inerte, filet fort).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import '../../support/hote_theme.dart';

const ValueKey<String> _cle = ValueKey<String>('bouton');

Widget _hote({
  String? libelleAttente,
  bool enCours = true,
  bool reduit = false,
  VoidCallback? onPress,
  NiveauAction niveau = NiveauAction.principale,
  bool filetPale = false,
}) => hoteTheme(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
      child: Center(
        child: ActionPrincipale(
          key: _cle,
          libelle: 'Recevoir le lien',
          libelleAttente: libelleAttente,
          affirmee: true,
          niveau: niveau,
          filetPale: filetPale,
          pleineLargeur: false,
          enCours: enCours,
          onPress: onPress ?? () {},
        ),
      ),
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(_cle),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((DecoratedBox d) => d.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((BoxDecoration d) => d.color != null);

void main() {
  testWidgets('attente pleine : meme peinture qu au repos, libelle d attente, '
      'aucun anneau, inactif', (WidgetTester tester) async {
    int appuis = 0;
    await tester.pumpWidget(_hote(enCours: false, onPress: () => appuis++));
    final Color? repos = _decoration(tester).color;

    await tester.pumpWidget(
      _hote(libelleAttente: 'Envoi du lien…', onPress: () => appuis++),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(_decoration(tester).color, repos);
    expect(find.text('Envoi du lien…'), findsOneWidget);
    expect(find.text('Recevoir le lien'), findsNothing);
    expect(find.byType(AttenteVivante), findsNothing);
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.tap(find.byKey(_cle), warnIfMissed: false);
    expect(appuis, 0);
    // L'etiquette du bouton reste celle de l'action.
    expect(find.bySemanticsLabel('Recevoir le lien'), findsOneWidget);
  });

  testWidgets('attente pleine sous « Réduire les effets » : aucun battement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hote(libelleAttente: 'Envoi du lien…', reduit: true),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final FadeTransition f = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Envoi du lien…'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(f.opacity.value, 1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(f.opacity.value, 1);
  });

  testWidgets('non-regression : sans libelle d attente, l anneau et la '
      'peinture inerte', (WidgetTester tester) async {
    await tester.pumpWidget(_hote(enCours: false));
    final Color? repos = _decoration(tester).color;
    await tester.pumpWidget(_hote());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AttenteVivante), findsOneWidget);
    expect(find.text('Recevoir le lien'), findsOneWidget);
    expect(_decoration(tester).color, isNot(repos));
  });

  testWidgets(
    'filet pale : borderHairline sur le secondaire, filet fort sinon',
    (WidgetTester tester) async {
      late AppPalette palette;
      await tester.pumpWidget(
        _hote(enCours: false, niveau: NiveauAction.secondaire, filetPale: true),
      );
      palette = AppPalette.of(tester.element(find.byKey(_cle)));
      Border? bord = _decoration(tester).border as Border?;
      expect(bord?.top.color, palette.borderHairline.asBorderSide().color);
      await tester.pumpWidget(
        _hote(enCours: false, niveau: NiveauAction.secondaire),
      );
      bord = _decoration(tester).border as Border?;
      expect(bord?.top.color, palette.borderStrong.asBorderSide().color);
    },
  );
}
