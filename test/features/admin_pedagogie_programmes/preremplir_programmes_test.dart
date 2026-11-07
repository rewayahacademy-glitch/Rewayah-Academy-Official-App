// CAHIER-C2 (garde-cap, 07/11/2026) : « Préremplir les bases » n'est proposé
// que sur une version vide ; un brouillon qui a déjà des étapes, sans les
// bases, dit de créer une version vide.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';

import '../../support/harnais.dart';

class _Faux implements ServiceProgramme {
  _Faux(this.etapes);

  final List<NiveauProgramme> etapes;

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v1',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 1,
      creeParIdentifiant: 'x',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: etapes.length,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async => etapes;

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
  }) async => 'n';

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
  }) async {}
}

NiveauProgramme _etape(String code) => NiveauProgramme(
  id: code,
  codeTechnique: code,
  nomHumain: code,
  cycle: 'Les bases',
  ordre: 1,
  description: null,
);

Future<void> _ouvrir(WidgetTester tester, List<NiveauProgramme> etapes) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const ProgrammesPage(),
      surcharges: <Override>[
        serviceProgrammeProvider.overrideWithValue(_Faux(etapes)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('version vide : la proposition est offerte', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, const <NiveauProgramme>[]);
    expect(find.text(t.admin.programmes.contenu.preremplir), findsOneWidget);
    expect(
      find.text(t.admin.programmes.contenu.preremplirVersionVide),
      findsNothing,
    );
  });

  testWidgets('brouillon avec une etape, sans les bases : la phrase dit de '
      'creer une version vide', (WidgetTester tester) async {
    await _ouvrir(tester, <NiveauProgramme>[_etape('F1-PHO-01')]);
    expect(find.text(t.admin.programmes.contenu.preremplir), findsNothing);
    expect(
      find.text(t.admin.programmes.contenu.preremplirVersionVide),
      findsOneWidget,
    );
  });

  testWidgets('brouillon prerempli : ni bouton ni phrase', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, <NiveauProgramme>[_etape('BASES-1')]);
    expect(find.text(t.admin.programmes.contenu.preremplir), findsNothing);
    expect(
      find.text(t.admin.programmes.contenu.preremplirVersionVide),
      findsNothing,
    );
  });
}
