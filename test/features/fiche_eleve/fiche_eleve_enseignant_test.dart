// EN-4 : ENS-11 Fiche eleve hors seance, ENS-12 Signaler un besoin, et le mot
// « Cahier a valider » a cote du point de rappel de Mes Classes.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
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
      // Le prenom est le titre de la feuille, sans « Fiche de » ni
      // repetition a cote de la photo (K-42 §5).
      expect(
        find.text(t.enseignant.eleve.titre(dePrenom: deDevant('Mariam'))),
        findsNothing,
      );
      expect(
        find.descendant(of: fiche, matching: find.text('Mariam')),
        findsNothing,
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
      ]) {
        expect(
          find.descendant(of: fiche, matching: find.text(libelle)),
          findsOneWidget,
        );
      }
      // Sans date connue, jamais « Derniere seance » sur un point travaille.
      expect(
        find.descendant(
          of: fiche,
          matching: find.text(t.enseignant.eleve.derniereSeance),
        ),
        findsNothing,
      );
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

    // Contre-epreuve du verificateur (08/10) : sur cde41490, une phrase-type
    // choisie puis la categorie « Autre » ne laissaient ni puce ni champ.
    testWidgets(
      'L7 : phrase-type puis « Autre », le resume reste saisissable',
      (WidgetTester tester) async {
        _fenetre(tester, const Size(390, 1400));
        await _ouvrirMariam(tester);
        await tester.ensureVisible(
          find.byKey(FicheEleveEnseignant.signalerKey),
        );
        await tester.tap(find.byKey(FicheEleveEnseignant.signalerKey));
        await tester.pumpAndSettle();

        Future<void> radio(CategorieBesoin c) async {
          final Finder f = find.byWidgetPredicate(
            (Widget w) => w is Radio<CategorieBesoin> && w.value == c,
          );
          await tester.ensureVisible(f);
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        await radio(CategorieBesoin.pedagogique);
        final Finder phrase = find.text(
          t.motifs.signalement.pedagogique.renforcement,
        );
        await tester.ensureVisible(phrase);
        await tester.tap(phrase);
        await tester.pumpAndSettle();
        expect(find.byKey(SignalerBesoin.resumeKey), findsNothing);

        await radio(CategorieBesoin.autre);
        // Aucune phrase-type : le champ libre du resume s'affiche seul, vide.
        expect(
          find.text(t.motifs.signalement.pedagogique.renforcement),
          findsNothing,
        );
        expect(find.byKey(SignalerBesoin.resumeKey), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(SignalerBesoin.resumeKey))
              .controller!
              .text,
          isEmpty,
        );
      },
    );

    testWidgets('320 a texte x2 : l aide des details passe a la ligne, '
        'jamais en ellipse', (WidgetTester tester) async {
      _fenetre(tester, const Size(320, 1400));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _ouvrirMariam(tester);
      await tester.ensureVisible(find.byKey(FicheEleveEnseignant.signalerKey));
      await tester.tap(find.byKey(FicheEleveEnseignant.signalerKey));
      await tester.pumpAndSettle();
      final Finder aide = find.text(t.enseignant.signalement.detailsAide);
      await tester.ensureVisible(aide);
      await tester.pumpAndSettle();
      final RenderParagraph rendu = tester.renderObject<RenderParagraph>(aide);
      expect(rendu.didExceedMaxLines, isFalse);
    });

    testWidgets('un envoi qui echoue ne passe jamais pour un succes', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 1400));
      int essais = 0;
      await tester.pumpWidget(
        hote(
          Scaffold(
            body: SingleChildScrollView(
              child: SignalerBesoin(
                eleve: const EleveFiche(
                  membre: MembreSeance(
                    studentId: 'e1',
                    identifiantImmuable: 'RA-TEST-001',
                    prenom: 'Mariam',
                  ),
                  classe: 'Hifz A',
                ),
                envoi: (SignalementBesoin _) async {
                  essais++;
                  throw StateError('hors ligne');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(CategorieBesoin.technique.libelle));
      await tester.enterText(find.byKey(SignalerBesoin.detailsKey), 'Micro');
      await tester.pumpAndSettle();
      final Finder envoyer = find.byKey(SignalerBesoin.envoyerKey);
      await tester.ensureVisible(envoyer);
      await tester.tap(envoyer);
      await tester.pumpAndSettle();

      expect(essais, 1);
      expect(find.byKey(SignalerBesoin.confirmationKey), findsNothing);
      expect(find.text(t.tc.parcours.signalement.echec), findsOneWidget);
      expect(find.text('Micro'), findsOneWidget);
      expect(
        find.descendant(of: envoyer, matching: find.text(t.commun.reessayer)),
        findsOneWidget,
      );
      await tester.tap(envoyer);
      await tester.pumpAndSettle();
      expect(essais, 2);
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
