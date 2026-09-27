// EN-9 : la salle A cote enseignant (panneau Eleves et file de recitation,
// resume mobile, fiche en seance et ses quatre actions), l'appel discret cote
// eleve et la notice du parent, sans fenetre ni minuteur (E8, E9, E16).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_classe/roster_classe_vm.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  RoleSeance role,
  EtatDemoSalle etat,
) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(SalleDemo(role: role, etat: etat, onSortir: () {})),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

final Finder _file = find.byKey(const ValueKey<String>('file-recitation'));

/// Un minuteur « 01:24 » ou une evaluation n'apparait nulle part (E8, E9).
void _sansMinuteurNiEvaluation() {
  expect(
    find.descendant(of: _file, matching: find.textContaining(RegExp(r'\d:\d'))),
    findsNothing,
  );
  expect(find.textContaining('Évaluation'), findsNothing);
  expect(find.textContaining('Très bien'), findsNothing);
}

void main() {
  group('EN-9 salle enseignant', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('mobile', const Size(390, 844)),
      ('desktop', const Size(1440, 900)),
    ]) {
      testWidgets('$nom : file de recitation, en cours puis A suivre', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille,
          RoleSeance.enseignant,
          EtatDemoSalle.eleves,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(PanneauEleves), findsOneWidget);
        expect(_file, findsOneWidget);
        expect(find.text(t.salle.seance.fileRecitation), findsOneWidget);
        expect(
          find.text(t.tc.classe.recitation.actif(prenom: 'Mariam')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _file,
            matching: find.text(t.salle.seance.aSuivre),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _file, matching: find.text('Yusuf')),
          findsOneWidget,
        );
        _sansMinuteurNiEvaluation();
      });
    }

    testWidgets('mobile : le resume des eleves ouvre la feuille', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(390, 844),
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      );
      expect(find.byType(PanneauEleves), findsNothing);
      expect(find.textContaining('1/3'), findsWidgets);
      await tester.tap(find.textContaining('1/3').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PanneauEleves), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('fiche en seance : les quatre actions, Faire reciter agit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        EtatDemoSalle.eleves,
      );
      expect(find.byKey(const ValueKey<String>('fiche-eleve')), findsOneWidget);
      for (final String libelle in <String>[
        t.salle.seance.faireReciter,
        t.salle.seance.rappeler,
        t.tc.classe.action.noter,
        t.salle.seance.signalerBesoin,
      ]) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
      expect(t.salle.seance.rappeler, 'Appeler discrètement');
      expect(t.salle.seance.faireReciter, 'Faire réciter');
      // Deplier Yusuf (A suivre), puis « Faire reciter » : il recite.
      final Finder liste = find
          .descendant(
            of: find.byType(PanneauEleves),
            matching: find.byType(Scrollable),
          )
          .first;
      final Finder yusuf = find.byKey(const ValueKey<String>('eleve-Yusuf'));
      await tester.scrollUntilVisible(yusuf, 80, scrollable: liste);
      await tester.tap(
        find.descendant(of: yusuf, matching: find.text('Yusuf')).first,
      );
      await tester.pump();
      final Finder reciter = find.text(t.salle.seance.faireReciter);
      await tester.scrollUntilVisible(reciter, 80, scrollable: liste);
      await tester.tap(reciter);
      await tester.pump();
      await tester.scrollUntilVisible(_file, -80, scrollable: liste);
      expect(
        find.text(t.tc.classe.recitation.actif(prenom: 'Yusuf')),
        findsOneWidget,
      );
      _sansMinuteurNiEvaluation();
    });

    testWidgets('les quatre actions appellent leur rappel', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(
              RoleSeance.enseignant,
              EtatDemoSalle.eleves,
            ),
            actions: ActionsSeance(
              onEleves: () {},
              onSupports: () {},
              onRappeler: (EleveSeance e) => journal.add('appel ${e.prenom}'),
              onChoisirPourReciter: (EleveSeance e) =>
                  journal.add('reciter ${e.prenom}'),
              onNoter: (EleveSeance e) => journal.add('noter ${e.prenom}'),
              onSignaler: (EleveSeance e) =>
                  journal.add('signaler ${e.prenom}'),
            ),
          ),
        ),
      );
      await tester.pump();
      for (final String libelle in <String>[
        t.salle.seance.faireReciter,
        t.salle.seance.rappeler,
        t.tc.classe.action.noter,
        t.salle.seance.signalerBesoin,
      ]) {
        await tester.tap(find.text(libelle));
        await tester.pump();
      }
      expect(journal, <String>[
        'reciter Mariam',
        'appel Mariam',
        'noter Mariam',
        'signaler Mariam',
      ]);
    });

    test('hors etat Eleves : la file est au repos', () {
      expect(FileRecitation.vide.enCours, isFalse);
      expect(
        DonneesSeanceDemo.vue(
          RoleSeance.enseignant,
          EtatDemoSalle.repos,
        ).recitation.enCours,
        isFalse,
      );
    });
  });

  group('EN-9 appel discret cote eleve', () {
    testWidgets('le titre vient des donnees, annonce sans fenetre', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(
        tester,
        const Size(390, 844),
        RoleSeance.eleve,
        EtatDemoSalle.appel,
      );
      final String attendu = t.salle.seance.vousAppelle(
        nom: DonneesSeanceDemo.enseignante,
      );
      expect(attendu, '${DonneesSeanceDemo.enseignante} vous appelle');
      expect(find.text(attendu), findsOneWidget);
      expect(find.textContaining('Le professeur'), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      final Finder region = find.ancestor(
        of: find.text(attendu),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
      );
      expect(region, findsOneWidget);
      semantique.dispose();
    });

    test('un autre nom : le texte suit la donnee', () {
      const VueSeance autre = VueSeance(
        role: RoleSeance.eleve,
        nomClasse: 'Classe',
        nomEnseignant: 'Sayyid Ibrahim',
        initialesEnseignant: 'SI',
        appelRecu: true,
      );
      expect(autre.texteAppel, 'Sayyid Ibrahim vous appelle');
      expect(autre.copyWith(role: RoleSeance.enseignant).texteAppel, isNull);
      expect(autre.copyWith(appelRecu: false).texteAppel, isNull);
    });

    testWidgets("l'enseignant ne voit jamais l'appel", (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        EtatDemoSalle.appel,
      );
      expect(find.byKey(const ValueKey<String>('appel-discret')), findsNothing);
    });
  });

  group('EN-9 notice du parent', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('mobile', const Size(390, 844)),
      ('desktop', const Size(1440, 900)),
    ]) {
      testWidgets("$nom : ligne d'etat dans l'en-tete, sans popup", (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille,
          RoleSeance.enseignant,
          EtatDemoSalle.visite,
        );
        final String? notice = DonneesSeanceDemo.vue(
          RoleSeance.enseignant,
          EtatDemoSalle.visite,
        ).texteNotice;
        expect(notice, isNotNull);
        expect(find.textContaining(notice!), findsWidgets);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
      });
    }
  });

  group('EN-9b salle enseignant sur bureau', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    testWidgets('sans barre de navigation, Eleves ouvert a droite du support', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('rail-seance')), findsNothing);
      for (final String entree in <String>[
        'Journée',
        'Classes',
        'Ressources',
        'Profil',
      ]) {
        expect(find.text(entree), findsNothing, reason: entree);
      }
      expect(find.byType(PanneauEleves), findsOneWidget);
      final Rect panneau = tester.getRect(
        find.byKey(const ValueKey<String>('panneau-seance-colonne')),
      );
      final Rect support = tester.getRect(
        find.byKey(const ValueKey<String>('zone-support')),
      );
      expect(panneau.left, greaterThan(support.right));
    });

    testWidgets('« Signaler un besoin » ouvre la feuille d\'EN-4', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        EtatDemoSalle.eleves,
      );
      final Finder signaler = find.text(t.salle.seance.signalerBesoin);
      await tester.ensureVisible(signaler);
      await tester.pump();
      await tester.tap(signaler);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text(t.enseignant.signalement.titre), findsWidgets);
    });

    testWidgets('telephone : la file tient en un bloc compact', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(390, 844),
        RoleSeance.enseignant,
        EtatDemoSalle.eleves,
      );
      final Rect file = tester.getRect(_file);
      final Rect mariam = tester.getRect(
        find.text(t.tc.classe.recitation.actif(prenom: 'Mariam')),
      );
      final Rect yusuf = tester.getRect(
        find.descendant(of: _file, matching: find.text('Yusuf')),
      );
      // « Mariam recite · A suivre : Yusuf, Aicha » sur une seule ligne.
      expect(yusuf.top, closeTo(mariam.top, 4));
      expect(file.height, lessThan(80));
    });
  });
}
