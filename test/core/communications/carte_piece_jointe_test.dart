// COM-F : carte piece jointe et entree « Joindre un fichier » (spec
// section 12). Chaque etat se dit en mots ; aucune URL, aucun chemin, aucune
// reference opaque n'apparait a l'ecran ; les actions ne sont rendues que si
// elles aboutissent ; l'entree suit PortPolitiquePiecesJointes ; la carte
// tient a 320 px en texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/communications/carte_piece_jointe.dart';

import '../../support/hote_theme.dart';

class _PolitiqueConnue implements PortPolitiquePiecesJointes {
  @override
  Future<PolitiquePiecesJointes> politique() async => PolitiquePiecesJointes(
    tailleMaxOctets: 10 * 1024 * 1024,
    typesAutorises: const <String>{'application/pdf', 'image/*'},
  );
}

PieceJointe _piece({
  EtatPieceJointe etat = EtatPieceJointe.envoyee,
  String nom = 'devoir-sourate-al-mulk.pdf',
  bool peutOuvrir = true,
  int? taille = 655360,
}) => PieceJointe(
  reference: ReferencePieceJointe('pj_7f3a9c'),
  nom: nom,
  nature: NaturePieceJointe.document,
  typeLisible: 'PDF',
  tailleOctets: taille,
  etat: etat,
  peutOuvrir: peutOuvrir,
);

/// Tout le texte rendu, Text et RichText compris.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

void main() {
  final p = t.com.socle.composants.pieceJointe;

  group('chaque etat se dit en mots', () {
    for (final EtatPieceJointe etat in EtatPieceJointe.values) {
      testWidgets(etat.name, (WidgetTester tester) async {
        await tester.pumpWidget(
          hoteTheme(CartePieceJointe(piece: _piece(etat: etat))),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(CartePieceJointe.libelleEtat(etat)), findsOneWidget);
        final String? detail = CartePieceJointe.detailEtat(etat);
        if (detail != null) {
          expect(find.text(detail), findsOneWidget);
        }
        expect(find.text('devoir-sourate-al-mulk.pdf'), findsOneWidget);
        expect(find.text('PDF'), findsOneWidget);
        expect(find.text(p.tailleKo(taille: 640)), findsOneWidget);
      });
    }
  });

  testWidgets('aucune URL, aucun chemin, aucune reference a l ecran', (
    WidgetTester tester,
  ) async {
    final PieceJointe piege = _piece(
      nom:
          'https://r2.rewayah.example/bucket/familles/42/devoir.pdf'
          '?X-Amz-Signature=abc123&token=secret',
    );
    await tester.pumpWidget(
      hoteTheme(CartePieceJointe(piece: piege, onOuvrir: () {})),
    );
    expect(find.text('devoir.pdf'), findsOneWidget);
    for (final String texte in _textes(tester)) {
      expect(texte, isNot(contains('://')), reason: texte);
      expect(texte, isNot(contains('r2.')), reason: texte);
      expect(texte, isNot(contains('bucket')), reason: texte);
      expect(texte, isNot(contains('Signature')), reason: texte);
      expect(texte, isNot(contains('token')), reason: texte);
      expect(texte, isNot(contains('pj_7f3a9c')), reason: texte);
    }
  });

  testWidgets('« Ouvrir » : seulement envoyee, autorisee et branchee', (
    WidgetTester tester,
  ) async {
    int ouvertures = 0;
    await tester.pumpWidget(
      hoteTheme(
        CartePieceJointe(piece: _piece(), onOuvrir: () => ouvertures++),
      ),
    );
    expect(find.byKey(CartePieceJointe.cleOuvrir), findsOneWidget);
    await tester.tap(find.byKey(CartePieceJointe.cleOuvrir));
    expect(ouvertures, 1);

    // Non autorisee : pas de bouton grise, pas de bouton du tout.
    await tester.pumpWidget(
      hoteTheme(
        CartePieceJointe(piece: _piece(peutOuvrir: false), onOuvrir: () {}),
      ),
    );
    expect(find.byKey(CartePieceJointe.cleOuvrir), findsNothing);

    // Indisponible : pas d'ouverture, une phrase dit quoi faire.
    await tester.pumpWidget(
      hoteTheme(
        CartePieceJointe(
          piece: _piece(etat: EtatPieceJointe.indisponible),
          onOuvrir: () {},
        ),
      ),
    );
    expect(find.byKey(CartePieceJointe.cleOuvrir), findsNothing);
    expect(find.text(p.indisponibleDetail), findsOneWidget);
  });

  testWidgets('« Retirer » avant l envoi, « Reessayer » sur non confirme', (
    WidgetTester tester,
  ) async {
    int retraits = 0;
    int essais = 0;
    await tester.pumpWidget(
      hoteTheme(
        CartePieceJointe(
          piece: _piece(etat: EtatPieceJointe.echec),
          onRetirer: () => retraits++,
          onReessayer: () => essais++,
        ),
      ),
    );
    expect(find.text(p.echec), findsOneWidget);
    expect(find.text(p.erreurEnvoi), findsOneWidget);
    await tester.tap(find.byKey(CartePieceJointe.cleReessayer));
    await tester.tap(find.byKey(CartePieceJointe.cleRetirer));
    expect(essais, 1);
    expect(retraits, 1);

    // Envoyee : ni retrait ni nouvel essai.
    await tester.pumpWidget(
      hoteTheme(
        CartePieceJointe(piece: _piece(), onRetirer: () {}, onReessayer: () {}),
      ),
    );
    expect(find.byKey(CartePieceJointe.cleRetirer), findsNothing);
    expect(find.byKey(CartePieceJointe.cleReessayer), findsNothing);
  });

  test('la taille se met en mots, sans politique inventee', () {
    expect(CartePieceJointe.libelleTaille(512), p.tailleOctets(taille: 512));
    expect(CartePieceJointe.libelleTaille(640 * 1024), p.tailleKo(taille: 640));
    expect(CartePieceJointe.libelleTaille(2621440), p.tailleMo(taille: '2,5'));
    expect(CartePieceJointe.libelleDuree(const Duration(seconds: 65)), '1:05');
  });

  group('EntreePieceJointe suit PortPolitiquePiecesJointes', () {
    testWidgets('port de production : une phrase, aucun bouton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteTheme(EntreePieceJointe(onJoindre: (_) {})));
      await tester.pumpAndSettle();
      expect(find.byKey(EntreePieceJointe.cleJoindre), findsNothing);
      expect(find.byKey(EntreePieceJointe.cleIndisponible), findsOneWidget);
      expect(find.text(p.joindreIndisponible), findsOneWidget);
    });

    testWidgets('politique connue : « Joindre un fichier » rend la politique', (
      WidgetTester tester,
    ) async {
      PolitiquePiecesJointes? recue;
      await tester.pumpWidget(
        hoteTheme(
          EntreePieceJointe(onJoindre: (PolitiquePiecesJointes x) => recue = x),
          surcharges: [
            portPolitiquePiecesJointesProvider.overrideWithValue(
              _PolitiqueConnue(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(p.joindre), findsOneWidget);
      await tester.tap(find.byKey(EntreePieceJointe.cleJoindre));
      expect(recue, isNotNull);
      expect(
        recue!.evaluer(typeMime: 'application/zip', tailleOctets: 10),
        EtatPieceJointe.typeInterdit,
      );
      expect(
        recue!.evaluer(typeMime: 'image/png', tailleOctets: 20 * 1024 * 1024),
        EtatPieceJointe.tropVolumineuse,
      );
    });
  });

  for (final Brightness luminosite in Brightness.values) {
    testWidgets('320 px, texte x2, ${luminosite.name} : aucun debordement', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 900));
      await tester.pumpWidget(
        hoteTheme(
          CartePieceJointe(
            piece: _piece(
              etat: EtatPieceJointe.echec,
              nom: 'compte-rendu-de-la-seance-du-vendredi-classe-an-nour.pdf',
            ),
            onRetirer: () {},
            onReessayer: () {},
          ),
          echelleTexte: 2,
          luminosite: luminosite,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(p.echec), findsOneWidget);
      expect(find.byKey(CartePieceJointe.cleReessayer), findsOneWidget);
      final Rect r = tester.getRect(find.byKey(CartePieceJointe.cleReessayer));
      expect(r.right, lessThanOrEqualTo(320));
    });
  }
}
