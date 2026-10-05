// CL-4.3 : l'Espace Classe eleve (CLS-ELV-01 et 02) sur les donnees de
// demonstration. Les tests TOUCHENT les elements : bouton, lecteur d'ecran,
// « Reessayer », reflow a 320 et texte a 200 %.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/photo_enseignant.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/a/support/hote_tc_a.dart';

/// Un port qui rend cinq actions : la page n'en montre que trois (R17).
class _CinqActions implements PortTravailAVenir {
  const _CinqActions();

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => <SlotAction>[
    for (int i = 1; i <= 5; i++) SlotAction(id: 'a$i', libelle: 'Action $i'),
  ];
}

Future<void> _poser(
  WidgetTester tester,
  EtatDemoClasse etat, {
  void Function()? onRejoindre,
  PortTravailAVenir travail = const TravailAVenirDemo(),
}) async {
  await tester.pumpWidget(
    hoteTcA(
      EspaceGroupePage(
        groupeId: DonneesClasseDemo.groupeId,
        onRejoindre: (_) => onRejoindre?.call(),
      ),
      surcharges: surchargesEleveDemo(etat, travail: travail),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Finder get _rejoindre =>
    find.widgetWithText(ActionPrincipale, t.classe.entree.rejoindre);

void main() {
  testWidgets('avant l ouverture : aucun bouton, le texte est la', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      expect(_rejoindre, findsNothing);
      expect(find.textContaining('Cours dans'), findsOneWidget);
      // Aucun bouton grise : pas d'ActionPrincipale dans la carte.
      expect(find.text(t.classe.entree.reessayer), findsNothing);
    });
  });

  testWidgets('a l ouverture : Rejoindre est la et se tape', (
    WidgetTester tester,
  ) async {
    int appuis = 0;
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        EtatDemoClasse.fenetreOuverte,
        onRejoindre: () => appuis++,
      );
      expect(_rejoindre, findsOneWidget);
      await tester.tap(_rejoindre);
      await tester.pump();
      expect(appuis, 1);
      // Mobile : pleine largeur.
      expect(tester.widget<ActionPrincipale>(_rejoindre).pleineLargeur, isTrue);
    });
  });

  testWidgets('sur bureau, le bouton garde sa largeur naturelle', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, 1440, () async {
      await _poser(tester, EtatDemoClasse.fenetreOuverte);
      expect(
        tester.widget<ActionPrincipale>(_rejoindre).pleineLargeur,
        isFalse,
      );
      // Largeur naturelle, pas etire sur la carte (rectification 9).
      expect(tester.getSize(_rejoindre).width, lessThan(300));
    });
  });

  testWidgets('en direct : l etat est dit, Rejoindre reste', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.enDirect);
      expect(find.text(t.classe.entree.enDirect), findsOneWidget);
      expect(_rejoindre, findsOneWidget);
    });
  });

  testWidgets('annulee : le texte, aucun bouton', (WidgetTester tester) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.annulee);
      expect(find.text(t.classe.entree.annulee), findsOneWidget);
      expect(_rejoindre, findsNothing);
    });
  });

  testWidgets('hors ligne : le texte et Reessayer, qui se tape', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.horsLigne);
      expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
      expect(_rejoindre, findsNothing);
      final Finder reessayer = find.widgetWithText(
        ActionPrincipale,
        t.classe.entree.reessayer,
      );
      expect(reessayer, findsOneWidget);
      await tester.tap(reessayer);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('lecteur d ecran : Rejoindre la seance de Classe An-Nour', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    int appuis = 0;
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        EtatDemoClasse.fenetreOuverte,
        onRejoindre: () => appuis++,
      );
      final Finder noeud = find.bySemanticsLabel(
        'Rejoindre la séance de Classe An-Nour',
      );
      expect(noeud, findsOneWidget);
      await tester.tap(noeud);
      await tester.pump();
      expect(appuis, 1);
    });
    semantique.dispose();
  });

  testWidgets('la ligne d etat n est pas focalisable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      final SemanticsNode ligne = tester.getSemantics(
        find.textContaining('Cours dans'),
      );
      expect(ligne, isNot(isSemantics(isFocusable: true)));
      expect(ligne, isNot(isSemantics(isButton: true)));
    });
    semantique.dispose();
  });

  for (final EtatDemoClasse etat in <EtatDemoClasse>[
    EtatDemoClasse.aVenir,
    EtatDemoClasse.fenetreOuverte,
    EtatDemoClasse.horsLigne,
  ]) {
    testWidgets('reflow 320 et texte a 200 % : ${etat.name}', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, 320, () async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _poser(tester, etat);
        expect(tester.takeException(), isNull);
        expect(find.byType(EspaceGroupePage), findsOneWidget);
      });
    });
  }

  testWidgets('Avant le prochain cours : trois actions au plus', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        EtatDemoClasse.aVenir,
        travail: const _CinqActions(),
      );
      final Finder bloc = find.byType(EmplacementAvantProchainCours);
      expect(
        find.descendant(of: bloc, matching: find.textContaining('Action ')),
        findsNWidgets(3),
      );
      expect(find.text('Action 4'), findsNothing);
    });
  });

  testWidgets('progression compacte : une barre et sa valeur ecrite', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      // Pourcentage insecable (COUPE-MOTS-3).
      expect(find.text('Chapitre 1 · 60\u00A0%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('photo absente : initiales, sans « Photo a fournir »', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      // L'enseignante de demonstration n'a pas de photo.
      expect(DonneesClasseDemo.enseignant.photoManquante, isTrue);
      expect(find.text(LibellesGroupe.photoManquante), findsNothing);
      expect(
        find.bySemanticsLabel(LibellesGroupe.photoManquante),
        findsNothing,
      );
      expect(find.byType(PhotoEnseignant), findsNothing);
      expect(
        find.descendant(
          of: find.byType(IdentiteGroupe),
          matching: find.byType(AvatarTile),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('le retour « Mes classes » est au bord de debut', (
    WidgetTester tester,
  ) async {
    for (final double largeur in <double>[largeurMobile, 1440]) {
      await avecLargeur(tester, largeur, () async {
        await _poser(tester, EtatDemoClasse.aVenir);
        final Finder retour = find.widgetWithText(
          ActionPrincipale,
          LibellesGroupe.retour,
        );
        expect(retour, findsOneWidget);
        final Rect r = tester.getRect(retour);
        // Leading : aligne sur le bord de debut du contenu, jamais centre.
        expect(
          r.left,
          closeTo(tester.getTopLeft(find.byType(IdentiteGroupe)).dx, 1),
        );
        expect(r.width, lessThan(largeur - 96));
      });
    }
  });

  testWidgets('mobile : « Voir tout » au bord de fin de l en-tete', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      final Finder voirTout = find.widgetWithText(
        ActionPrincipale,
        LibellesGroupe.bibliothequeVoirTout,
      );
      await tester.ensureVisible(voirTout);
      final Rect lien = tester.getRect(voirTout);
      final Rect titre = tester.getRect(
        find.text(LibellesGroupe.bibliotheque).first,
      );
      // Meme ligne que le titre, et au bord de fin.
      expect(lien.top, lessThan(titre.bottom));
      expect(lien.right, greaterThan(largeurMobile - 48));
      expect(lien.width, lessThan(largeurMobile / 2));
    });
  });

  testWidgets('/demo/classe ouvre le vrai ecran eleve', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await tester.pumpWidget(
        hoteTcA(const EcranEleveDemo(etat: EtatDemoClasse.fenetreOuverte)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(EspaceGroupePage), findsOneWidget);
      expect(_rejoindre, findsOneWidget);
    });
  });

  group('Capture : CL-4.3', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EtatDemoClasse etat in <EtatDemoClasse>[
      EtatDemoClasse.aVenir,
      EtatDemoClasse.fenetreOuverte,
    ]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 1500)),
        ('768', const Size(768, 1400)),
        ('1440', const Size(1440, 1000)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'cl43_eleve_${etat.name}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(EcranEleveDemo(etat: etat), themeMode: mode),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
