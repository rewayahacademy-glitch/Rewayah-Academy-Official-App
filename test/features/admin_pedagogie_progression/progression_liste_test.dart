// LISTES-1, lot 4 : Pedagogie > Progression, recherche cote client et compteur.
//
// La liste est lue en entier (`progression_admin()`), la recherche est donc
// faite dans l'ecran, sans aller-retour serveur. Ce que le test prouve :
// - la recherche trouve par le nom, l'identifiant et la classe, sans tenir
//   compte des accents ni de la casse ;
// - le compteur dit « n eleves », puis « n sur total eleves » quand la
//   recherche ou un cycle en retire ;
// - les compteurs des cycles suivent la recherche ;
// - aucune ligne : un etat vide propre, et « Effacer la recherche » ramene
//   la liste ;
// - le menu de la ligne est la colonne d'actions du socle (hors de la ligne),
//   et la ligne mesure 56 ;
// - 390 et 1440 px, texte x1 et x2, LTR et RTL : aucun debordement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

const List<String> _prenoms = <String>[
  'Amina',
  'Yacine',
  'Salma',
  'Idris',
  'Maryam',
  'Bilal',
  'Nour',
  'Zayd',
  'Hana',
  'Omar',
  'Lina',
  'Sami',
];
const List<String> _cycles = <String>[
  'Éveil',
  'Fondations',
  'Approfondissement',
];

List<EleveProgression> _eleves() => <EleveProgression>[
  for (int i = 0; i < _prenoms.length; i++)
    EleveProgression(
      studentId: 'e$i',
      identifiant: 'RA-26-${4800 + i}',
      prenom: _prenoms[i],
      nom: 'Fictif-$i',
      groupeId: 'g${i % 3}',
      groupeLibelle: i % 3 == 0 ? 'Débutants du lundi' : 'Classe An-Nour',
      niveauId: 'n$i',
      niveauNomHumain: 'Niveau ${i % 4 + 1}',
      niveauCycle: _cycles[i % 3],
      niveauDepuis: DateTime(2026, 9, 1 + i),
      exceptionActiveId: i == 3 ? 'x3' : null,
      exceptionActiveType: i == 3 ? TypeExceptionProgression.blocage : null,
    ),
];

Future<void> _monter(
  WidgetTester tester, {
  Size taille = const Size(1440, 1700),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  List<EleveProgression>? eleves,
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
            child: const ProgressionPage(),
          ),
        ),
      ),
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        progressionProvider.overrideWith((Ref _) async => eleves ?? _eleves()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

String _compteur(WidgetTester tester) =>
    tester.widget<Text>(_cle('progression-compteur')).data!;

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(_cle('progression-recherche'), texte);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('sans recherche : tous les eleves, le compteur le dit', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(_cle('progression-recherche'), findsOneWidget);
    expect(_compteur(tester), '12 élèves');
    expect(find.text('Amina Fictif-0'), findsOneWidget);
    expect(find.text('Sami Fictif-11'), findsOneWidget);
  });

  testWidgets('le nom : sans accent, sans casse, tous les termes', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'AMINA');
    expect(_compteur(tester), '1 sur 12 élèves');
    expect(find.text('Amina Fictif-0'), findsOneWidget);
    expect(find.text('Yacine Fictif-1'), findsNothing);
    await _chercher(tester, 'fictif-1');
    // « fictif 1 » : 1, 10 et 11 contiennent le terme « 1 ».
    expect(find.text('Yacine Fictif-1'), findsOneWidget);
    expect(find.text('Lina Fictif-10'), findsOneWidget);
    expect(find.text('Sami Fictif-11'), findsOneWidget);
    expect(_compteur(tester), '3 sur 12 élèves');
  });

  testWidgets('l identifiant et la classe se cherchent aussi', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'ra-26-4805');
    expect(_compteur(tester), '1 sur 12 élèves');
    expect(find.text('Bilal Fictif-5'), findsOneWidget);
    await _chercher(tester, 'debutants lundi');
    // Les eleves 0, 3, 6 et 9.
    expect(_compteur(tester), '4 sur 12 élèves');
  });

  testWidgets('les compteurs des cycles suivent la recherche', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'debutants lundi');
    // 0, 3, 6, 9 : cycles Eveil, Eveil, Eveil, Eveil (i % 3 == 0).
    expect(find.text('4'), findsWidgets);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('aucun resultat : etat vide, effacer ramene la liste', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _chercher(tester, 'zzzz');
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(t.admin.progression.aucunAvecCeFiltre), findsOneWidget);
    expect(find.byType(DataCollection<EleveProgression>), findsNothing);
    // Un seul « Effacer la recherche » : celui du champ.
    await tester.tap(find.bySemanticsLabel(t.commun.recherche.effacer).first);
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsNothing);
    expect(_compteur(tester), '12 élèves');
  });

  testWidgets('le cycle et la recherche se combinent', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.tap(find.textContaining('Fondations').first);
    await tester.pumpAndSettle();
    expect(_compteur(tester), '4 sur 12 élèves');
    await _chercher(tester, 'yacine');
    expect(_compteur(tester), '1 sur 12 élèves');
    await _chercher(tester, 'amina');
    // Amina est en Eveil : rien dans Fondations.
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('un seul eleve : le compteur au singulier', (
    WidgetTester tester,
  ) async {
    await _monter(tester, eleves: _eleves().take(1).toList());
    expect(_compteur(tester), '1 élève');
  });

  testWidgets('lignes de 56, menu hors de la ligne, 10 lignes ou plus en 1000', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 1000));
    final Rect premiere = tester.getRect(find.text('Amina Fictif-0'));
    final Rect deuxieme = tester.getRect(find.text('Yacine Fictif-1'));
    // Les cellules sont centrees : deux lignes de 56 se suivent a 56.
    expect(deuxieme.center.dy - premiere.center.dy, closeTo(56, 1));
    // Titre, onglets, introduction, recherche, filtres et compteur au-dessus :
    // au moins dix lignes restent visibles dans 1000 px.
    final int visibles = find
        .byType(MenuActions)
        .evaluate()
        .where(
          (Element e) => tester.getRect(find.byWidget(e.widget)).bottom <= 1000,
        )
        .length;
    expect(visibles, greaterThanOrEqualTo(10));
    await _monter(tester);
    expect(find.byType(MenuActions), findsNWidgets(12));
  });

  for (final (String nom, Size taille, double echelle, TextDirection sens)
      in <(String, Size, double, TextDirection)>[
        ('390 x1', const Size(390, 800), 1, TextDirection.ltr),
        ('390 x2', const Size(390, 800), 2, TextDirection.ltr),
        ('1440 x2', const Size(1440, 900), 2, TextDirection.ltr),
        ('390 RTL', const Size(390, 800), 1, TextDirection.rtl),
        ('1440 RTL', const Size(1440, 900), 1, TextDirection.rtl),
      ]) {
    testWidgets('$nom : rend la liste et la recherche sans exception', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: taille, echelle: echelle, direction: sens);
      expect(tester.takeException(), isNull);
      expect(_cle('progression-recherche'), findsOneWidget);
      expect(_cle('progression-compteur'), findsOneWidget);
      await _chercher(tester, 'amina');
      expect(tester.takeException(), isNull);
      await _chercher(tester, 'zzzz');
      expect(tester.takeException(), isNull);
      expect(find.byType(EmptyState), findsOneWidget);
    });
  }

  group('en arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));

    testWidgets('en arabe : compteur au pluriel arabe, rien d invente', (
      WidgetTester tester,
    ) async {
      await _monter(tester, direction: TextDirection.rtl);
      expect(_compteur(tester), contains('12'));
      await _chercher(tester, 'amina');
      expect(_compteur(tester), contains('1'));
      expect(_compteur(tester), contains('12'));
      expect(tester.takeException(), isNull);
    });
  });
}
