import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/classes/carte_classe.dart';
import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/grille_classes.dart';

import '../../support/harnais.dart';
import 'faux/faux_ports_classes.dart';
import 'support/largeurs.dart';

Future<void> _poser(
  WidgetTester tester,
  ClasseVM classe, {
  ActionCarte? action,
}) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CarteClasse(classe: classe, action: action),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('La carte se lit d un coup d oeil, sur les cinq largeurs', () {
    for (final double largeur in largeursP0) {
      testWidgets('a $largeur : nom, programme, creneau, capacite, un bouton', (
        WidgetTester tester,
      ) async {
        await avecLargeur(tester, largeur, () async {
          await _poser(
            tester,
            classeDeTest(),
            action: ActionCarte(libelle: 'Candidater', onPress: () {}),
          );

          expect(tester.takeException(), isNull, reason: '$largeur');
          expect(find.text('Perles du Coran'), findsOneWidget);
          // Le programme et le niveau en langage humain, jamais un code.
          expect(
            find.textContaining('Fondations de lecture'),
            findsOneWidget,
          );
          // Le creneau en mots, jamais « jour = 1, heure = 17 ».
          expect(
            find.text(t.classes.carte.creneau(jour: 'lundi', heure: '17:00')),
            findsOneWidget,
          );
          expect(find.textContaining('jour = 1'), findsNothing);
          // La capacite vient de la donnee, jamais d'une constante.
          expect(find.text('4 / 5'), findsOneWidget);
          // Aucun identifiant technique a l'ecran.
          expect(find.textContaining('uuid'), findsNothing);
          // Un seul bouton contextuel : le detail est un lien tertiaire.
          expect(
            find.widgetWithText(ActionPrincipale, 'Candidater'),
            findsOneWidget,
          );
          // La carte ne deborde pas de l'ecran.
          final Rect carte = tester.getRect(find.byType(CarteClasse));
          expect(carte.right, lessThanOrEqualTo(largeur));
        });
      });
    }
  });

  testWidgets('sans enseignant, la carte le dit : « Enseignant a affecter »', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, classeDeTest(enseignant: null));

      final StatusPill pastille = tester.widget<StatusPill>(
        find.widgetWithText(StatusPill, t.classes.carte.enseignantAAffecter),
      );
      expect(pastille.ton, TonEtat.avertissement);
      expect(find.text('Amina'), findsNothing);
    });
  });

  testWidgets('avec enseignant, son nom se lit et aucune pastille ne l annonce', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, classeDeTest());
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text(t.classes.carte.enseignantAAffecter), findsNothing);
    });
  });

  testWidgets('complete, la carte le dit par un mot, pas par une couleur', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, classeDeTest(inscrits: 5));
      expect(find.text(t.classes.carte.complet), findsOneWidget);
    });
  });

  testWidgets('le detail attend derriere « Voir le detail »', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, classeDeTest(seuilMinimal: 3));

      expect(find.byKey(CarteClasse.cleDetail), findsNothing);
      await tester.tap(find.text(t.classes.carte.voirDetail));
      await tester.pumpAndSettle();

      expect(find.byKey(CarteClasse.cleDetail), findsOneWidget);
      expect(find.text(t.classes.carte.masquerDetail), findsOneWidget);
      // Le seuil minimal et le fuseau ne vivent que dans le detail.
      expect(find.text(t.classes.carte.seuilMinimal(seuil: 3)), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
      // Sans seance connue, le detail le dit sans inventer une date.
      expect(find.text(t.classes.carte.aucuneSeance), findsOneWidget);
    });
  });

  testWidgets('un brouillon sans capacite connue dit le defaut de l academie', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      const BrouillonClasse brouillon = BrouillonClasse(
        libelle: 'Enfants',
        publicClasse: PublicClasse.enfants,
        creneau: CreneauClasse(jourIso: 3, heure: 18, fuseauIana: 'Europe/Paris'),
      );
      await _poser(tester, brouillon.apercu());

      expect(find.text(t.classes.commun.defautAcademie), findsOneWidget);
      // Aucun nombre invente a la place du serveur.
      expect(find.textContaining('/ 1'), findsNothing);
      expect(find.text(t.classes.carte.brouillon), findsOneWidget);
    });
  });

  group('La grille suit la largeur recue', () {
    Future<void> grille(WidgetTester tester) async {
      await tester.pumpWidget(
        hote(
          Scaffold(
            body: SingleChildScrollView(
              child: GrilleClasses(
                cartes: <Widget>[
                  for (int i = 0; i < 3; i++)
                    CarteClasse(classe: classeDeTest(id: 'c$i', libelle: 'C$i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('telephone : une colonne', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await grille(tester);
        final Offset a = tester.getTopLeft(find.byType(CarteClasse).at(0));
        final Offset b = tester.getTopLeft(find.byType(CarteClasse).at(1));
        expect(b.dy, greaterThan(a.dy));
        expect(b.dx, a.dx);
      });
    });

    testWidgets('tablette : deux colonnes', (WidgetTester tester) async {
      await avecLargeur(tester, largeurTablette, () async {
        await grille(tester);
        final Offset a = tester.getTopLeft(find.byType(CarteClasse).at(0));
        final Offset b = tester.getTopLeft(find.byType(CarteClasse).at(1));
        final Offset c = tester.getTopLeft(find.byType(CarteClasse).at(2));
        expect(b.dy, a.dy);
        expect(b.dx, greaterThan(a.dx));
        expect(c.dy, greaterThan(a.dy));
      });
    });

    testWidgets('bureau : trois colonnes, aucune carte etiree', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurDesktop, () async {
        await grille(tester);
        final Offset a = tester.getTopLeft(find.byType(CarteClasse).at(0));
        final Offset c = tester.getTopLeft(find.byType(CarteClasse).at(2));
        expect(c.dy, a.dy);
        final Rect carte = tester.getRect(find.byType(CarteClasse).at(0));
        expect(carte.width, lessThan(largeurDesktop / 2));
      });
    });
  });
}
