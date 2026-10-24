// ECHELLE-CORR-ECRANS-1 : la liste des classes de la direction a l'echelle
// de classes paralleles (DECISION-CLASSES-SIMULTANEES-2026-10-10, R7, R16,
// R17).
//
// Ce que le test prouve :
// - 30 classes de meme cle (Garcons debutants, lundi 18 h, Paris) portent 30
//   noms distincts (numero dans la famille de classes) ;
// - la liste est paginee (25 par page), avec un grand volume simule ;
// - recherche et filtres : jour, heure, fuseau, genre, enseignant, etat ;
// - les classes sans enseignant sont visibles et se retrouvent d'un geste ;
// - les etats : chargement, contenu, vide, vide avec ce filtre, erreur ;
// - 320 px, texte a 200 %, LTR et RTL : aucun debordement, un seul bouton
//   plein.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/demo/classes_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/rangee_plus.dart';

List<ClasseListee> _tout() => <ClasseListee>[...familleDemo(), ...volumeDemo()];

PageClasses _page(
  FiltreClasses filtre, {
  int page = 1,
  List<ClasseListee>? classes,
}) => paginerClasses(
  classes ?? _tout(),
  filtre,
  page: page,
  taille: taillePageClasses,
);

const FiltreClasses _famille = FiltreClasses(
  jour: 1,
  heure: 18,
  fuseau: 'Europe/Paris',
  genre: GenreClasse.hommes,
  type: TypePublicGroupe.enfant,
  texte: libelleFamilleDemo,
);

Future<void> _monter(
  WidgetTester tester, {
  required PortClassesAdmin port,
  Size taille = const Size(1440, 1600),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool attendre = true,
  bool horsLigneReseau = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Directionality(
        textDirection: direction,
        child: Builder(
          builder: (BuildContext contexte) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: const GroupesPage(),
          ),
        ),
      ),
      surcharges: <Override>[
        portClassesAdminProvider.overrideWithValue(port),
        if (horsLigneReseau)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
    ),
  );
  if (attendre) await tester.pumpAndSettle();
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  group('R16 : 30 classes paralleles, 30 noms distincts', () {
    test('meme libelle, meme jour, meme heure, meme fuseau : 30 noms', () {
      final List<ClasseListee> famille = familleDemo();
      expect(famille, hasLength(30));
      expect(
        famille.map((ClasseListee c) => c.groupe.libelle).toSet(),
        hasLength(1),
      );
      expect(famille.map((ClasseListee c) => c.nom).toSet(), hasLength(30));
      expect(famille.first.nom, '$libelleFamilleDemo · n° 1');
    });

    test('sans numero rendu : le nom seul, rien d invente', () {
      final ClasseListee c = ClasseListee.depuisGroupe(
        familleDemo().first.groupe,
      );
      expect(c.nom, libelleFamilleDemo);
      // Le code court sert a defaut de numero.
      expect(
        ClasseListee(groupe: c.groupe, codeCourt: 'B7').nom,
        '$libelleFamilleDemo · B7',
      );
    });
  });

  group('R17 : pagination et filtres (port de demonstration)', () {
    test('la famille de 30 : une page de 25, puis une de 5', () {
      final PageClasses p1 = _page(_famille);
      expect(p1.total, 30);
      expect(p1.pages, 2);
      expect(p1.lignes, hasLength(25));
      final PageClasses p2 = _page(_famille, page: 2);
      expect(p2.lignes, hasLength(5));
      expect(p2.debut, 26);
      expect(p2.fin, 30);
      expect(<String>{
        ...p1.lignes.map((ClasseListee c) => c.nom),
        ...p2.lignes.map((ClasseListee c) => c.nom),
      }, hasLength(30));
      // Une page hors bornes revient a la derniere.
      expect(_page(_famille, page: 99).page, 2);
    });

    test('grand volume : pagine, et chaque axe filtre', () {
      final PageClasses tout = _page(const FiltreClasses());
      expect(tout.total, 630);
      expect(tout.pages, 26);
      expect(tout.lignes, hasLength(25));
      for (final ClasseListee c in _page(const FiltreClasses(jour: 3)).lignes) {
        expect(c.groupe.creneau.jour, 3);
      }
      for (final ClasseListee c in _page(
        const FiltreClasses(heure: 12),
      ).lignes) {
        expect(c.groupe.creneau.heure, 12);
      }
      for (final ClasseListee c in _page(
        const FiltreClasses(fuseau: 'America/Toronto'),
      ).lignes) {
        expect(c.fuseau, 'America/Toronto');
      }
      for (final ClasseListee c in _page(
        const FiltreClasses(genre: GenreClasse.femmes),
      ).lignes) {
        expect(c.genre, GenreClasse.femmes);
      }
      final PageClasses cloturees = _page(
        const FiltreClasses(etat: EtatClasseListee.cloturee),
      );
      expect(cloturees.total, greaterThan(0));
      expect(
        cloturees.lignes.every(
          (ClasseListee c) => c.etat == EtatClasseListee.cloturee,
        ),
        isTrue,
      );
      // Les compteurs par etat couvrent toute la liste.
      expect(tout.toutesEtats, 630);
      expect(tout.fuseaux, hasLength(3));
      expect(tout.jours, <int>[1, 2, 3, 4, 5, 6, 7]);
    });

    test('enseignant : par identifiant, ou « sans enseignant » (R7)', () {
      final PageClasses sans = _page(
        _famille.avec(enseignantId: () => FiltreClasses.sansEnseignant),
      );
      expect(
        sans.lignes.map((ClasseListee c) => c.numeroDansFamille).toSet(),
        numerosSansEnseignantDemo,
      );
      expect(
        sans.lignes.every((ClasseListee c) => c.enseignant == null),
        isTrue,
      );
      final PageClasses attente = _page(
        _famille.avec(etat: () => EtatClasseListee.attenteEnseignant),
      );
      expect(attente.total, numerosSansEnseignantDemo.length);
      final String id = familleDemo()[1].groupe.teacherId;
      final PageClasses unSeul = _page(
        const FiltreClasses().avec(enseignantId: () => id),
      );
      expect(unSeul.total, greaterThan(0));
      expect(
        unSeul.lignes.every((ClasseListee c) => c.groupe.teacherId == id),
        isTrue,
      );
    });

    test('recherche : sans accents ni casse, sur le nom, le numero et '
        'l enseignant', () {
      final PageClasses parNom = _page(
        const FiltreClasses(texte: 'garcons debutants'),
      );
      expect(parNom.total, 30);
      final PageClasses parNumero = _page(
        const FiltreClasses(texte: 'débutants · n° 17'),
      );
      expect(parNumero.total, 1);
      expect(parNumero.lignes.single.numeroDansFamille, 17);
      final PageClasses parEnseignant = _page(
        const FiltreClasses(texte: 'sayyida maryam'),
      );
      expect(parEnseignant.total, greaterThan(0));
      final PageClasses rien = _page(const FiltreClasses(texte: 'zzz'));
      expect(rien.total, 0);
      expect(rien.totalSansFiltre, 630);
    });
  });

  group('Ecran Classes, a l echelle', () {
    testWidgets('page de 25, suivante, recherche, classes sans enseignant', (
      WidgetTester tester,
    ) async {
      final ClassesAdminDemo port = ClassesAdminDemo(classes: _tout());
      // Assez haut pour que les 25 lignes et le pied de liste soient poses.
      await _monter(tester, port: port, taille: const Size(1440, 4000));
      expect(
        find.text(t.commun.listes.tranche(debut: 1, fin: 25, total: 630)),
        findsOneWidget,
      );

      // Page suivante.
      final Finder suivante = _cle('nav-suivant');
      // Premiere page : pas de fleche « precedente » (elle disparait, jamais
      // grisee, NAV-FLECHES-1).
      expect(_cle('nav-precedent'), findsNothing);
      await tester.ensureVisible(suivante.first);
      await tester.tap(suivante.first);
      await tester.pumpAndSettle();
      expect(
        find.text(t.commun.listes.tranche(debut: 26, fin: 50, total: 630)),
        findsOneWidget,
      );

      // Recherche : la famille de 30, sur deux pages, 30 noms distincts.
      await tester.enterText(_cle('classes-recherche'), libelleFamilleDemo);
      await tester.pumpAndSettle();
      expect(
        find.text(t.commun.listes.tranche(debut: 1, fin: 25, total: 30)),
        findsOneWidget,
      );
      for (int n = 1; n <= 25; n++) {
        expect(
          find.text('$libelleFamilleDemo · n° $n'),
          findsOneWidget,
          reason: 'n° $n',
        );
      }

      // « En attente d'enseignant » : les classes sans enseignant.
      // L4-07 : selon la place, « En attente » est dans la rangee ou sous
      // « Plus ».
      await toucherFiltre(tester, _cle('classes-filtre-attente'));
      expect(
        find.text(t.commun.listes.tranche(debut: 1, fin: 3, total: 3)),
        findsOneWidget,
      );
      for (final int n in numerosSansEnseignantDemo) {
        expect(find.text('$libelleFamilleDemo · n° $n'), findsOneWidget);
      }
      expect(find.text(t.admin.groupes.liste.sansEnseignant), findsWidgets);
      expect(find.text(t.admin.groupes.liste.etatAttente), findsWidgets);
      verifierUnSeulBoutonPlein(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : le squelette', (WidgetTester tester) async {
      await _monter(
        tester,
        port: ClassesAdminDemo(
          classes: _tout(),
          latence: const Duration(seconds: 1),
        ),
        attendre: false,
      );
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : une phrase et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final ClassesAdminDemo port = ClassesAdminDemo(
        classes: _tout(),
        horsLigne: true,
      );
      await _monter(tester, port: port);
      expect(find.text(t.admin.groupes.erreur), findsOneWidget);
      port.horsLigne = false;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.groupes.erreur), findsNothing);
      expect(port.pagesDemandees, greaterThanOrEqualTo(2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hors ligne sans donnees : ce qui manque, une relecture', (
      WidgetTester tester,
    ) async {
      final ClassesAdminDemo port = ClassesAdminDemo(
        classes: _tout(),
        horsLigne: true,
      );
      await _monter(tester, port: port, horsLigneReseau: true);
      expect(_cle('classes-sans-donnees'), findsOneWidget);
      expect(find.text(t.admin.groupes.sansDonnees), findsOneWidget);
      // Le bandeau dit l'absence de reseau ; le bloc ne la redit pas.
      expect(find.text(t.admin.groupes.erreur), findsNothing);
      expect(find.byType(EtatSansDonnees), findsOneWidget);
      port.horsLigne = false;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(_cle('classes-sans-donnees'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('recherche : une seule requete, 300 ms apres la derniere '
        'frappe', (WidgetTester tester) async {
      final ClassesAdminDemo port = ClassesAdminDemo(classes: _tout());
      await _monter(tester, port: port);
      final int avant = port.pagesDemandees;
      for (final String texte in <String>['a', 'am', 'ama']) {
        await tester.enterText(_cle('classes-recherche'), texte);
        await tester.pump(const Duration(milliseconds: 100));
      }
      // 200 ms depuis la premiere frappe, 100 depuis la derniere : rien.
      expect(port.pagesDemandees, avant);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(port.pagesDemandees, avant + 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide, et vide avec ce filtre', (WidgetTester tester) async {
      await _monter(
        tester,
        port: ClassesAdminDemo(classes: const <ClasseListee>[]),
      );
      expect(find.text(t.admin.groupes.aucun), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      await _monter(tester, port: ClassesAdminDemo(classes: _tout()));
      await tester.enterText(_cle('classes-recherche'), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(t.admin.groupes.aucunAvecCeFiltre), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    group('320 px, texte a 200 %', () {
      setUpAll(chargerPolicesDuDepot);
      for (final TextDirection direction in TextDirection.values) {
        testWidgets('aucun debordement (${direction.name})', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            port: ClassesAdminDemo(classes: _tout()),
            taille: const Size(320, 2400),
            echelle: 2,
            direction: direction,
          );
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(
            tester,
            // L'etiquette et l'indication de `ChampRecherche` (composant
            // partage, inchange) : au-dela de 130 %, elles restent dans le
            // champ (`labelText`, `hintText`), hors de `TexteSansCoupure`,
            // comme pour la recherche des Messages et de `SelecteurPersonne`
            // (meme exception dans classe_form_1_test).
            exceptions: <String>{
              t.admin.groupes.liste.rechercheLibelle,
              t.admin.groupes.liste.rechercheAide,
            },
          );
          verifierUnSeulBoutonPlein(tester);
          await tester.pumpWidget(const SizedBox());
        });
      }
    });
  });
}
