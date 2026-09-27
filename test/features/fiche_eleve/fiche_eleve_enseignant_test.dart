// EN-4 : ENS-11 Fiche eleve hors seance, ENS-12 Signaler un besoin, et le mot
// « Cahier a valider » a cote du point de rappel de Mes Classes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';

import '../../support/harnais.dart';

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _ouvrirMariam(WidgetTester tester) async {
  await tester.pumpWidget(
    hote(const EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte)),
  );
  await tester.pumpAndSettle();
  final Finder ligne = find.text('Mariam').last;
  await tester.ensureVisible(ligne);
  await tester.pumpAndSettle();
  await tester.tap(ligne);
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-11 : la fiche eleve hors seance', () {
    testWidgets('sur telephone, la ligne de l eleve ouvre une feuille', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 900));
      await _ouvrirMariam(tester);

      final Finder fiche = find.byType(FicheEleveEnseignant);
      expect(fiche, findsOneWidget);
      expect(find.byType(PanneauFicheEleve), findsNothing);
      expect(
        find.text(t.enseignant.eleve.titre(prenom: 'Mariam')),
        findsOneWidget,
      );
      // Photo en tete (initiales en repli), identifiant, les tuiles.
      expect(
        find.descendant(of: fiche, matching: find.byType(PhotoEleve)),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.eleve.identifiant(id: 'RA-DEMO-001')),
        findsOneWidget,
      );
      for (final String libelle in <String>[
        t.enseignant.eleve.niveau,
        t.enseignant.eleve.objectif,
        t.enseignant.eleve.presence,
        t.enseignant.eleve.travail,
        t.enseignant.eleve.derniereSeance,
      ]) {
        expect(
          find.descendant(of: fiche, matching: find.text(libelle)),
          findsOneWidget,
        );
      }
      expect(find.text('Terminer la sourate Al-Mulk'), findsOneWidget);
      // Hors seance, une seule action (E14).
      expect(find.byKey(FicheEleveEnseignant.signalerKey), findsOneWidget);
      expect(find.textContaining('réciter'), findsNothing);
    });

    testWidgets('sur bureau, un panneau a la place des eleves ; Echap le '
        'ferme', (WidgetTester tester) async {
      _fenetre(tester, const Size(1440, 1400));
      await _ouvrirMariam(tester);

      expect(find.byType(PanneauFicheEleve), findsOneWidget);
      // Jamais un troisieme panneau : la colonne des eleves est remplacee.
      expect(find.text('Yusuf'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PanneauFicheEleve), findsNothing);
      expect(find.text('Yusuf'), findsOneWidget);

      await tester.tap(find.text('Mariam').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PanneauFicheEleve.retourKey));
      await tester.pumpAndSettle();
      expect(find.byType(PanneauFicheEleve), findsNothing);
    });
  });

  group('ENS-12 : Signaler un besoin', () {
    testWidgets('categories, deux champs separes, notice, succes honnete', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 1400));
      await _ouvrirMariam(tester);
      await tester.ensureVisible(find.byKey(FicheEleveEnseignant.signalerKey));
      await tester.tap(find.byKey(FicheEleveEnseignant.signalerKey));
      await tester.pumpAndSettle();

      expect(find.byType(SignalerBesoin), findsOneWidget);
      // Eleve et Classe preremplis (W-337).
      expect(find.textContaining('Pour Mariam · '), findsOneWidget);
      for (final CategorieBesoin c in CategorieBesoin.values) {
        expect(find.text(c.libelle), findsOneWidget);
      }
      expect(find.text(t.enseignant.signalement.details), findsOneWidget);
      expect(find.text(t.enseignant.signalement.resume), findsOneWidget);
      expect(find.text(t.enseignant.signalement.notice), findsOneWidget);

      // Sans categorie : une phrase humaine, avec la solution.
      final Finder envoyer = find.byKey(SignalerBesoin.envoyerKey);
      await tester.ensureVisible(envoyer);
      await tester.tap(envoyer);
      await tester.pumpAndSettle();
      expect(
        find.text(t.enseignant.signalement.choisirCategorie),
        findsOneWidget,
      );

      // « Autre » demande un detail ; l'erreur part des la correction.
      await tester.ensureVisible(
        find.text(t.enseignant.signalement.categories.autre),
      );
      // EN-12 : une ligne a radio par categorie ; le radio porte le choix.
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Radio<CategorieBesoin> && w.value == CategorieBesoin.autre,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.enseignant.signalement.choisirCategorie),
        findsNothing,
      );
      await tester.ensureVisible(envoyer);
      await tester.tap(envoyer);
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.signalement.detailsRequis), findsOneWidget);
      await tester.enterText(
        find.byKey(SignalerBesoin.detailsKey),
        'Changement de creneau souhaite',
      );
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.signalement.detailsRequis), findsNothing);

      await tester.ensureVisible(envoyer);
      await tester.tap(envoyer);
      await tester.pumpAndSettle();
      // En demonstration, jamais la pretention d'un envoi reel.
      expect(find.byKey(SignalerBesoin.confirmationKey), findsOneWidget);
      expect(find.text(t.enseignant.signalement.demoSucces), findsOneWidget);
    });
  });

  group('Mes Classes : le point de rappel est double d un mot', () {
    testWidgets('« Cahier a valider » a cote du point, lu une fois', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 1200));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        hote(const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PointRappel), findsOneWidget);
      expect(find.text(t.enseignant.classes.cahierAValider), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(t.enseignant.classes.rappelCahier)),
        findsWidgets,
      );
      semantique.dispose();
    });
  });
}
