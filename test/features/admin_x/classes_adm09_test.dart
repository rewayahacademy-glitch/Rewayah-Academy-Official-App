// AD-X, ecran 3 : Classes en collection et inspecteur (ADM-09, image
// ADMIN-SHELL-03), docs/current/AD-X_DECOUPAGE.md §2, ecran 3.
//
// Ce que le test tient : le titre « Classes » ; les onglets d'etat avec leur
// nombre ; le filtre Public en menu ; a 1440, la ligne choisie s'ouvre dans
// un inspecteur de 336 au bord de fin (vrais membres, actions), marquee
// `selected`, fermee par sa croix ; a 390, la feuille comme avant ; un seul
// bouton plein (« Creer un groupe »).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

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

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[
    _g('a', 'Classe An-Nour'),
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
  }) async {}
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
    hote(
      const GroupesPage(),
      surcharges: <Override>[
        serviceGroupesProvider.overrideWithValue(service ?? _Groupes()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('titre « Classes », onglets d etat avec leur nombre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    expect(find.text('Classes'), findsWidgets);
    expect(find.text(t.admin.groupes.filtreToutes), findsOneWidget);
    expect(find.text(t.admin.groupes.filtreActives), findsOneWidget);
    expect(find.text(t.admin.groupes.filtreCloturees), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);

    await tester.tap(find.text(t.admin.groupes.filtreCloturees));
    await tester.pumpAndSettle();
    expect(find.text('Classe As-Sabr'), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsNothing);
  });

  testWidgets('filtre Public : Adultes', (WidgetTester tester) async {
    await _monter(tester, const Size(1440, 900));
    await tester.tap(find.byType(MenuFiltre<TypePublicGroupe>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.groupes.typeAdulte).last);
    await tester.pumpAndSettle();
    expect(find.text('Classe Al-Furqan'), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsNothing);
  });

  testWidgets('1440 : la ligne s ouvre dans l inspecteur, au bord de fin', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, const Size(1440, 900));
    expect(find.byKey(GroupesPage.cleInspecteur), findsNothing);

    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    final Finder inspecteur = find.byKey(GroupesPage.cleInspecteur);
    expect(inspecteur, findsOneWidget);
    expect(tester.getSize(inspecteur).width, GroupesPage.largeurInspecteur);
    expect(
      tester.getRect(inspecteur).left,
      greaterThan(tester.getRect(find.text('Classe Al-Furqan')).right),
    );
    // Nom, enseignant, membres reels, action d'ajout (secondaire).
    expect(
      find.descendant(of: inspecteur, matching: find.text('Classe An-Nour')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inspecteur, matching: find.text('Mariam Exemple')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: inspecteur,
        matching: find.text(t.admin.groupes.actionAjouter),
      ),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
    // La ligne choisie est annoncee choisie, pas seulement coloree.
    expect(
      find.descendant(
        of: find.byType(DataCollection<GroupeAdmin>),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && (w.properties.selected ?? false),
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(t.admin.groupes.inspecteurFermer));
    await tester.pumpAndSettle();
    expect(find.byKey(GroupesPage.cleInspecteur), findsNothing);
    semantique.dispose();
  });

  testWidgets('inspecteur : membres illisibles, une phrase', (
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
        of: find.byKey(GroupesPage.cleInspecteur),
        matching: find.text(t.admin.groupes.erreur),
      ),
      findsOneWidget,
    );
  });

  testWidgets('390 : pas d inspecteur, la feuille comme avant', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(390, 844));
    await tester.tap(find.text('Classe An-Nour'));
    await tester.pumpAndSettle();
    expect(find.byKey(GroupesPage.cleInspecteur), findsNothing);
    expect(
      find.text(t.admin.groupes.detailTitre(libelle: 'Classe An-Nour')),
      findsOneWidget,
    );
  });
}
