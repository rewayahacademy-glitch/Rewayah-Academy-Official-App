// BOUTONS-GRISES-1 : dans les programmes, aucun bouton grise.
// - « Publier la version » sans niveau ne peut pas aboutir : il n'est pas
//   rendu, une phrase dit quoi faire a sa place.
// - « Publier » de la feuille de motif reste actif : sans motif, l'appui le
//   dit sous le champ, l'annonce au lecteur d'ecran et rend le focus au champ.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';

import '../../support/annonces.dart';
import '../../support/harnais.dart';

VersionProgramme _version(int niveaux) => VersionProgramme(
  id: 'v1',
  statut: StatutVersionProgramme.brouillon,
  numeroVersion: 1,
  creeParIdentifiant: 'adm',
  creeParPrenom: null,
  creeParNom: null,
  publieeAt: null,
  nombreNiveaux: niveaux,
  createdAt: DateTime(2026, 10, 10),
);

class _FauxProgramme implements ServiceProgramme {
  _FauxProgramme(this.niveauxRendus);

  final int niveauxRendus;
  int publications = 0;

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    _version(niveauxRendus),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[];

  @override
  Future<String> creerVersion({String? versionSourceId}) async => 'v2';

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async => 'n1';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {
    publications++;
  }
}

Future<_FauxProgramme> _monter(WidgetTester tester, int niveaux) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _FauxProgramme service = _FauxProgramme(niveaux);
  await tester.pumpWidget(
    hote(
      const ProgrammesPage(),
      surcharges: <Override>[
        serviceProgrammeProvider.overrideWithValue(service),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('sans niveau : pas de bouton grise, une phrase a sa place', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 0);
    expect(
      find.widgetWithText(ActionPrincipale, t.admin.programmes.publierVersion),
      findsNothing,
    );
    expect(find.text(t.admin.programmes.publierSansNiveau), findsOneWidget);
  });

  testWidgets('publier sans motif : actif, dit, annonce, focus au champ', (
    WidgetTester tester,
  ) async {
    final List<String> annonces = ecouterAnnonces(tester);
    final _FauxProgramme service = await _monter(tester, 2);
    final Finder publierVersion = find.widgetWithText(
      ActionPrincipale,
      t.admin.programmes.publierVersion,
    );
    expect(tester.widget<ActionPrincipale>(publierVersion).onPress, isNotNull);
    await tester.ensureVisible(publierVersion);
    await tester.tap(publierVersion);
    await tester.pumpAndSettle();

    final Finder publier = find.widgetWithText(
      ActionPrincipale,
      t.admin.programmes.publierVersionEnvoyer,
    );
    expect(tester.widget<ActionPrincipale>(publier).onPress, isNotNull);
    await tester.ensureVisible(publier);
    await tester.tap(publier);
    await tester.pumpAndSettle();

    expect(service.publications, 0);
    expect(find.text(t.formulaire.motif.manqueSaisi), findsOneWidget);
    expect(annonces, <String>[t.formulaire.motif.manqueSaisi]);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'motif-programme');

    await tester.enterText(find.byType(TextField).last, 'Validee en conseil');
    await tester.pumpAndSettle();
    expect(find.text(t.formulaire.motif.manqueSaisi), findsNothing);
    await tester.tap(publier);
    await tester.pumpAndSettle();
    expect(service.publications, 1);
  });
}
