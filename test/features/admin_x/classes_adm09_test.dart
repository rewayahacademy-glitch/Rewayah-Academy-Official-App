// AD-X, ecran 3 : Classes en collection (ADM-09), refondue par L1 des listes
// (directeur, 01/11/2026, DECISION-LISTES-2026-10-23.md §5 quater) et par
// DECISION-DEFILEMENT-2026-11-01 : l'inspecteur de bureau est retire (il
// defilait dans son propre cadre) ; la fiche d'une classe est une PAGE,
// empilee au-dessus de la liste (decision du pilote, 01/11/2026, 16:45 UTC).
//
// Ce que le test tient : la liste s'ouvre sur les classes ouvertes (actives
// et en attente d'enseignant), « Cloturees » par le filtre ; au bureau, les
// filtres sont replies derriere une icone, et un filtre retenu reste dit
// panneau replie ; une ligne ouvre la fiche-page (vrais membres, actions), et
// le retour retrouve la liste avec ses filtres ; au telephone aussi ; un seul
// bouton plein (« Nouvelle classe ») ; aucun texte visible ne dit « groupe »
// (lib/CLAUDE.md : « Classe, jamais groupe ») ; la ligne cloturee, sans menu,
// reste alignee sur les autres.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/formulaires/motifs_proposes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/routes_classes_admin.dart';

GroupeAdmin _g(
  String id,
  String libelle, {
  bool actif = true,
  TypePublicGroupe type = TypePublicGroupe.enfant,
}) => GroupeAdmin(
  id: id,
  libelle: libelle,
  type: type,
  seuilMax: 5,
  teacherId: 't-$id',
  teacherIdentifiant: 'TEACHER-$id',
  teacherPrenom: 'Amina',
  teacherNom: 'Diallo',
  creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  nombreMembres: 2,
  actif: actif,
);

class _Groupes implements ServiceGroupes {
  Object? erreurMembres;

  /// Les classes cloturees pendant le test (le serveur les rend inactives).
  final List<String> clotures = <String>[];

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[
    _g('a', 'Classe An-Nour', actif: !clotures.contains('a')),
    _g('b', 'Classe Al-Furqan', type: TypePublicGroupe.adulte),
    _g('c', 'Classe As-Sabr', actif: false),
  ];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async {
    final Object? e = erreurMembres;
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
    return <MembreGroupe>[
      MembreGroupe(
        studentId: 's1',
        identifiant: 'STUDENT-1',
        prenom: 'Mariam',
        nom: 'Exemple',
        rejointLe: DateTime(2026, 9, 1),
      ),
    ];
  }

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  }) async => 'x';

  @override
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  }) async {}

  @override
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> cloturer({
    required String groupeId,
    required String motif,
  }) async => clotures.add(groupeId);
}

class _GroupesVides extends _Groupes {
  @override
  Future<List<GroupeAdmin>> groupes() async => const <GroupeAdmin>[];
}

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  _Groupes? service,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.adminOperationsGroupes,
      routes: routesClassesAdmin(),
      surcharges: <Override>[
        serviceGroupesProvider.overrideWithValue(service ?? _Groupes()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Tous les textes visibles de l'ecran, en minuscules.
List<String> _textesVisibles(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
];

/// Deplie le panneau des filtres (bureau).
Future<void> _ouvrirFiltres(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('classes-bascule-filtres')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'vue par defaut : les classes ouvertes, cloturees par le filtre',
    (WidgetTester tester) async {
      await _monter(tester, const Size(1440, 900));
      expect(find.text('Classes'), findsWidgets);
      expect(find.text('Classe An-Nour'), findsOneWidget);
      expect(find.text('Classe Al-Furqan'), findsOneWidget);
      // Rien n'est efface : la classe cloturee attend son filtre.
      expect(find.text('Classe As-Sabr'), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      // Les filtres sont replies derriere l'icone (§5 quater).
      expect(find.text(t.admin.groupes.liste.filtreOuvertes), findsNothing);

      await _ouvrirFiltres(tester);
      expect(find.text(t.admin.groupes.liste.filtreOuvertes), findsOneWidget);
      expect(find.text(t.admin.groupes.filtreActives), findsOneWidget);
      expect(find.text(t.admin.groupes.filtreCloturees), findsOneWidget);
      expect(find.text(t.admin.groupes.filtreToutes), findsOneWidget);
      await tester.tap(find.text(t.admin.groupes.filtreCloturees));
      await tester.pumpAndSettle();
      expect(find.text('Classe As-Sabr'), findsOneWidget);
      expect(find.text('Classe An-Nour'), findsNothing);
    },
  );

  testWidgets('filtre Public : Adultes, dit panneau replie', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirFiltres(tester);
    await tester.tap(find.byType(MenuFiltre<TypePublicGroupe>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.groupes.typeAdulte).last);
    await tester.pumpAndSettle();
    expect(find.text('Classe Al-Furqan'), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsNothing);
    // Panneau replie : le filtre retenu reste dit, et se retire.
    await _ouvrirFiltres(tester);
    final String puce = t.commun.filtres.axeValeur(
      axe: t.admin.groupes.filtrePublic,
      valeur: t.admin.groupes.typeAdulte,
    );
    expect(find.text(puce), findsOneWidget);
  });

  testWidgets(
    '1440 : la ligne ouvre la fiche-page ; le retour garde les filtres',
    (WidgetTester tester) async {
      await _monter(tester, const Size(1440, 900));
      // Un filtre, pour verifier qu'il est garde au retour.
      await _ouvrirFiltres(tester);
      await tester.tap(find.byType(MenuFiltre<TypePublicGroupe>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.groupes.typeAdulte).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Classe Al-Furqan'));
      await tester.pumpAndSettle();
      final Finder fiche = find.byKey(FicheClasseAdminPage.cleFiche);
      expect(fiche, findsOneWidget);
      expect(find.byType(GroupesPage), findsNothing);
      // Nom en titre, membres reels, action d'ajout (secondaire).
      expect(find.text('Classe Al-Furqan'), findsWidgets);
      expect(
        find.descendant(of: fiche, matching: find.text('Mariam Exemple')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fiche,
          matching: find.text(t.admin.groupes.actionAjouter),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);

      // Retour : la liste, toujours filtree sur les adultes.
      GoRouter.of(tester.element(fiche)).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(FicheClasseAdminPage.cleFiche), findsNothing);
      expect(find.text('Classe Al-Furqan'), findsOneWidget);
      expect(find.text('Classe An-Nour'), findsNothing);
    },
  );

  testWidgets('fiche : « Clôturer la classe » en dernier ; la classe quitte '
      'la vue Ouvertes', (WidgetTester tester) async {
    final _Groupes service = _Groupes();
    await _monter(tester, const Size(1440, 900), service: service);
    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    final Finder cloturer = find.byKey(FicheClasseAdminPage.cleCloturer);
    expect(cloturer, findsOneWidget);
    // En dernier dans la fiche : sous « Ajouter un élève ».
    expect(
      tester.getRect(cloturer).top,
      greaterThan(
        tester.getRect(find.text(t.admin.groupes.actionAjouter).last).bottom,
      ),
    );
    await tester.ensureVisible(cloturer);
    await tester.tap(cloturer);
    await tester.pumpAndSettle();
    // La confirmation existante : un motif, puis l'envoi.
    await tester.tap(find.text(MotifsProposes.clotureClasse().first));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ActionPrincipale, t.admin.groupes.cloturerEnvoyer),
    );
    await tester.pumpAndSettle();
    expect(service.clotures, <String>['a']);
    // Retour a la liste relue : la classe close n'est plus dans les ouvertes.
    expect(find.byKey(FicheClasseAdminPage.cleFiche), findsNothing);
    expect(find.text('Classe Al-Furqan'), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsNothing);
  });

  testWidgets('cloture sans motif : rien ne part, le message est juste '
      'au-dessus du bouton, le focus va sur les motifs', (
    WidgetTester tester,
  ) async {
    final _Groupes service = _Groupes();
    await _monter(tester, const Size(1366, 768), service: service);
    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    final Finder cloturer = find.byKey(FicheClasseAdminPage.cleCloturer);
    await tester.ensureVisible(cloturer);
    await tester.tap(cloturer);
    await tester.pumpAndSettle();
    final Finder envoyer = find.byKey(
      const ValueKey<String>('feuille-motif-envoyer'),
    );
    // Apparence pleine d'une action destructive active, jamais le violet pale.
    final ActionPrincipale bouton = tester.widget<ActionPrincipale>(envoyer);
    expect(bouton.niveau, NiveauAction.destructive);
    expect(bouton.doux, isTrue);
    expect(bouton.onPress, isNotNull);

    await tester.tap(envoyer);
    await tester.pumpAndSettle();
    expect(service.clotures, isEmpty);
    final Finder message = find.text(t.formulaire.motif.manque);
    expect(message, findsOneWidget);
    // Juste au-dessus du bouton : rien entre les deux.
    final double ecart =
        tester.getRect(envoyer).top - tester.getRect(message).bottom;
    expect(ecart, inInclusiveRange(0, 48));
    // Le filet d'alerte autour des motifs : apres un clic, l'anneau de focus
    // ne se peint pas ; c'est lui qui montre ou agir.
    final DecoratedBox cadre = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('feuille-motif-cadre')),
    );
    expect((cadre.decoration as BoxDecoration).border, isNotNull);
    // Le focus est sur la liste des motifs ; aucun motif choisi a sa place.
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      SelecteurMotif.focusPremierePuce,
    );
  });

  testWidgets('fiche : membres illisibles, une phrase', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const Size(1440, 900),
      service: _Groupes()..erreurMembres = Exception('muet'),
    );
    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(FicheClasseAdminPage.cleFiche),
        matching: find.text(t.admin.groupes.erreur),
      ),
      findsOneWidget,
    );
  });

  testWidgets('390 : la meme fiche-page ; « Nouvelle classe » flotte', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(390, 844));
    expect(find.byKey(GroupesPage.cleCreer), findsOneWidget);
    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    expect(find.byKey(FicheClasseAdminPage.cleFiche), findsOneWidget);
  });

  testWidgets('aucun texte visible ne dit « groupe », liste, fiche, creation', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    expect(find.text(t.admin.groupes.creer), findsOneWidget);
    expect(t.admin.groupes.creer, 'Nouvelle classe');
    expect(
      _textesVisibles(tester).where((String x) => x.contains('groupe')),
      isEmpty,
    );

    // La feuille de creation non plus.
    await tester.tap(find.byKey(GroupesPage.cleCreer));
    await tester.pumpAndSettle();
    expect(find.text(t.admin.groupes.champLibelle), findsWidgets);
    expect(
      _textesVisibles(tester).where((String x) => x.contains('groupe')),
      isEmpty,
    );
    Navigator.of(tester.element(find.text(t.admin.groupes.champLibelle).first))
        .pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    expect(find.byKey(FicheClasseAdminPage.cleFiche), findsOneWidget);
    expect(
      _textesVisibles(tester).where((String x) => x.contains('groupe')),
      isEmpty,
    );
  });

  testWidgets('vide : « Aucune classe créée »', (WidgetTester tester) async {
    await _monter(tester, const Size(1440, 900), service: _GroupesVides());
    expect(find.text(t.admin.groupes.aucun), findsOneWidget);
    expect(
      _textesVisibles(tester).where((String x) => x.contains('groupe')),
      isEmpty,
    );
  });

  testWidgets('1440 : la ligne cloturee reste alignee sur les autres', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirFiltres(tester);
    await tester.tap(find.text(t.admin.groupes.filtreToutes));
    await tester.pumpAndSettle();
    final Finder tableau = find.byType(DataCollection<ClasseListee>);
    // Le nom de chaque classe commence au meme bord, la cloturee (sans menu)
    // comme les actives (avec menu).
    final List<double> bords = <double>[
      for (final String nom in <String>[
        'Classe An-Nour',
        'Classe Al-Furqan',
        'Classe As-Sabr',
      ])
        tester
            .getRect(find.descendant(of: tableau, matching: find.text(nom)))
            .left,
    ];
    expect(bords.toSet(), hasLength(1));
  });
}
