// PROFILS-EFFET (directeur, 12/11/2026) : deux effets simples a la place de la
// goutte entre profils : le contenu change par un fondu court, et le profil
// selectionne se reconnait a son rond (grandit, anneau d'accent en douceur).
// La selection est prise des le toucher ; mouvement reduit = instantane ;
// jamais de boucle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/cercle_selectionnable.dart';
import 'package:rewayah_academy/core/widgets/fondu_contenu_profil.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

import '../support/harnais.dart';

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'a', prenom: 'Amina', etat: 'Dans 3 h'),
  ProfilSelectionnable(id: 'b', prenom: 'Bilal', etat: 'Aucune séance'),
];

/// La rangee et son contenu : le toucher change la selection tout de suite ;
/// le contenu (`contenu`) suit la selection, comme sur l'Accueil.
class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _EtatPage();
}

class _EtatPage extends State<_Page> {
  String _choisi = 'a';

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      SelecteurProfils(
        profils: _profils,
        selectionId: _choisi,
        onSelection: (String id) => setState(() => _choisi = id),
      ),
      FonduContenuProfil(
        profilId: _choisi,
        child: Text('Contenu de $_choisi', key: ValueKey<String>('c-$_choisi')),
      ),
    ],
  );
}

Future<void> _monter(WidgetTester tester, {bool reduit = false}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduit),
        child: const Scaffold(body: _Page()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _couleurRond(WidgetTester tester, int index) {
  final Finder rond = find.descendant(
    of: find.byType(CercleSelectionnable).at(index),
    matching: find.byType(DecoratedBox),
  );
  return ((tester.widget<DecoratedBox>(rond.first).decoration) as BoxDecoration)
      .color!;
}

/// Deux couleurs a une fraction de canal pres (la fin du ressort n'est pas
/// exacte au dernier bit).
Matcher _proche(Color attendue) => predicate<Color>(
  (Color c) =>
      (c.r - attendue.r).abs() < 0.01 &&
      (c.g - attendue.g).abs() < 0.01 &&
      (c.b - attendue.b).abs() < 0.01,
  'proche de $attendue',
);

void main() {
  testWidgets('au premier affichage : le contenu est la, sans fondu', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(find.byKey(const ValueKey<String>('c-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('c-b')), findsNothing);
  });

  testWidgets('la selection est prise des le toucher ; le contenu change par '
      'un fondu court, qui finit largement sous le plafond', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.tap(find.text('Bilal'));
    // Une seule image : la selection est deja prise (le rond choisi est B),
    // le contenu est en train de changer (l'ancien s'efface, le nouveau
    // entre).
    await tester.pump();
    expect(
      tester
          .widgetList<CercleSelectionnable>(find.byType(CercleSelectionnable))
          .map((CercleSelectionnable c) => c.choisi),
      <bool>[false, true],
    );
    await tester.pump(AppMouvement.fonduContenuProfil ~/ 2);
    expect(find.byKey(const ValueKey<String>('c-a')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('c-b')), findsOneWidget);
    final double opaciteB = tester
        .widgetList<FadeTransition>(
          find.ancestor(
            of: find.byKey(const ValueKey<String>('c-b')),
            matching: find.byType(FadeTransition),
          ),
        )
        .first
        .opacity
        .value;
    expect(opaciteB, inExclusiveRange(0, 1));
    // Fini apres la duree du jeton : plus que le nouveau contenu.
    await tester.pump(AppMouvement.fonduContenuProfil);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey<String>('c-a')), findsNothing);
    expect(find.byKey(const ValueKey<String>('c-b')), findsOneWidget);
    expect(
      AppMouvement.fonduContenuProfil,
      lessThan(AppMouvement.plafond),
      reason: 'choisir un profil est une action instantanee',
    );
  });

  testWidgets('jamais de boucle : apres le changement, plus rien ne bouge', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.tap(find.text('Bilal'));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('mouvement reduit : le changement est instantane (contenu et '
      'anneau)', (WidgetTester tester) async {
    await _monter(tester, reduit: true);
    final Color accent = AppPalette.of(
      tester.element(find.byType(SelecteurProfils)),
    ).inkAccent.asBorderSide().color;
    final Color avant = _couleurRond(tester, 1);
    expect(avant, isNot(accent));
    await tester.tap(find.text('Bilal'));
    await tester.pump();
    // Une seule image suffit : le contenu est le nouveau, seul, et l'anneau du
    // profil choisi a deja pris l'accent.
    expect(find.byKey(const ValueKey<String>('c-a')), findsNothing);
    expect(find.byKey(const ValueKey<String>('c-b')), findsOneWidget);
    expect(_couleurRond(tester, 1), _proche(accent));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('le profil selectionne se reconnait : son anneau prend l accent '
      'en douceur (pas d un coup), l autre le perd', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    final Color accent = AppPalette.of(
      tester.element(find.byType(SelecteurProfils)),
    ).inkAccent.asBorderSide().color;
    expect(_couleurRond(tester, 0), _proche(accent));
    final Color reposB = _couleurRond(tester, 1);
    await tester.tap(find.text('Bilal'));
    await tester.pump();
    await tester.pump(AppMouvement.micro);
    final Color enRoute = _couleurRond(tester, 1);
    expect(enRoute, isNot(reposB));
    expect(enRoute, isNot(accent));
    await tester.pumpAndSettle();
    expect(_couleurRond(tester, 1), _proche(accent));
    expect(_couleurRond(tester, 0), isNot(_proche(accent)));
  });
}
