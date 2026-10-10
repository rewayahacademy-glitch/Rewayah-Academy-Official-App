// Relecture de COUPE-MOTS-FOND-1 (10/10) : `DataCollection.tientEnTableau`
// mesurait chaque cellule par TextPainter a CHAQUE mise en page. Un cache,
// par identite du jeu de lignes, echelle du texte et largeur, evite de
// remesurer ; le rendu ne change pas (tableau ou cartes, meme decision).
//
// Contre-epreuve : sans le cache (la lecture du cache retiree), la seconde
// mise en page des memes lignes remesure et le premier test echoue.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';

/// Une fenetre de bureau de [largeur] px.
void _fenetre(WidgetTester tester, double largeur) {
  tester.view.physicalSize = Size(largeur, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Des colonnes neuves a chaque appel, comme un ecran qui se reconstruit.
List<ColonneDonnees<String>> _colonnes() => <ColonneDonnees<String>>[
  ColonneDonnees<String>(
    titre: 'Nom',
    texte: (String l) => l,
    role: RoleColonne.identifiante,
  ),
  ColonneDonnees<String>(titre: 'Quand', texte: (String _) => '23/09/2026'),
];

Widget _hote(List<String> lignes, {double echelle = 2}) => MaterialApp(
  theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
  builder: (BuildContext c, Widget? enfant) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(echelle)),
    child: enfant!,
  ),
  home: Scaffold(
    body: DataCollection<String>(colonnes: _colonnes(), lignes: lignes),
  ),
);

int _cartes() => find.byType(AppCard).evaluate().length;

void main() {
  testWidgets('une seconde mise en page des memes lignes ne remesure pas', (
    WidgetTester tester,
  ) async {
    _fenetre(tester, 1400);
    final List<String> lignes = <String>['Alif', 'Ba', 'TEACHER-AS-000001'];
    final int avant = DataCollection.mesuresTientEnTableau;
    await tester.pumpWidget(_hote(lignes));
    final int apresPremiere = DataCollection.mesuresTientEnTableau;
    expect(apresPremiere, greaterThan(avant), reason: 'premiere mesure');
    final int cartes = _cartes();

    // Meme jeu de lignes (meme objet), colonnes reconstruites : aucune
    // nouvelle mesure, meme rendu.
    await tester.pumpWidget(_hote(lignes));
    await tester.pump();
    expect(DataCollection.mesuresTientEnTableau, apresPremiere);
    expect(_cartes(), cartes);
  });

  testWidgets('un autre jeu de lignes, une autre largeur ou une autre echelle '
      'remesurent, et decident comme sans cache', (WidgetTester tester) async {
    _fenetre(tester, 1400);
    final List<String> lignes = <String>['Alif', 'Ba', 'TEACHER-AS-000001'];
    await tester.pumpWidget(_hote(lignes));
    final int cartes = _cartes();
    int n = DataCollection.mesuresTientEnTableau;

    // Copie : autre identite, meme contenu, meme decision.
    await tester.pumpWidget(_hote(List<String>.of(lignes)));
    expect(DataCollection.mesuresTientEnTableau, n + 1);
    expect(_cartes(), cartes);
    n = DataCollection.mesuresTientEnTableau;

    // Autre largeur : nouvelle mesure.
    _fenetre(tester, 1300);
    await tester.pumpWidget(_hote(lignes));
    expect(DataCollection.mesuresTientEnTableau, n + 1);
    n = DataCollection.mesuresTientEnTableau;

    // Autre echelle (x3) : nouvelle mesure.
    await tester.pumpWidget(_hote(lignes, echelle: 3));
    expect(DataCollection.mesuresTientEnTableau, n + 1);
  });
}
