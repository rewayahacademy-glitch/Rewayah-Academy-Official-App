// BIBLIOTHEQUE-UNE, revue B1 : l'onglet de la classe ne rend plus l'adresse
// d'un lien externe (la base la retire de cette liste). Le toucher doit donc
// ouvrir la fiche, qui relit le document complet (parId), puis la confirmation
// avant de quitter l'application ; un enfant hors tranche ne recoit rien.
// Par le VRAI routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/classe_tuteur/ressources_classe_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';

import '../../router/support_routeur.dart';
import '../../teaching_core/b/faux/faux_ports_b.dart';
import 'support_classe.dart';

const String _lien = 'https://exemple.org/page';

LibraryResource _complet() => const LibraryResource(
  id: 'lien1',
  title: 'Un site de reference',
  shortTitle: 'Un site',
  resourceType: TypeRessource.lienExterne,
  language: 'fr',
  category: 'lecture',
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.jamais,
  description: 'Un site pour aller plus loin.',
  lienExterne: _lien,
  currentVersionId: 'v-lien1',
);

/// Ce que rend `ressources_du_groupe` : la meme ligne, sans l'adresse.
LibraryResource _sansAdresse() => const LibraryResource(
  id: 'lien1',
  title: 'Un site de reference',
  shortTitle: 'Un site',
  resourceType: TypeRessource.lienExterne,
  language: 'fr',
  category: 'lecture',
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.jamais,
  description: 'Un site pour aller plus loin.',
  currentVersionId: 'v-lien1',
);

/// L'onglet rend la ligne SANS adresse ; la fiche relit le document complet.
class _CatalogueClasseLien extends FauxCatalogueClasse {
  const _CatalogueClasseLien({required this.horsTranche})
    : super(const <LibraryResource>[]);

  final bool horsTranche;

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async =>
      horsTranche || groupeId != classeA
      ? const <LibraryResource>[]
      : <LibraryResource>[_sansAdresse()];

  @override
  Future<LibraryResource?> parId(String resourceId) async =>
      horsTranche || resourceId != 'lien1' ? null : _complet();
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required bool horsTranche,
  required List<Uri> ouverts,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesClasse(
          catalogue: _CatalogueClasseLien(horsTranche: horsTranche),
        ),
        portVersionsRessourceProvider.overrideWithValue(
          VersionsLocales(
            parRessource: <String, List<ResourceVersion>>{
              'lien1': <ResourceVersion>[
                version(id: 'v-lien1', resourceId: 'lien1'),
              ],
            },
          ),
        ),
        ouvreurOngletProvider.overrideWithValue((Uri u) {
          ouverts.add(u);
          return true;
        }),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go('${Routes.classeSousPage(classeA, 'ressources')}?eleve=$eleveA1');
  await stabiliser(tester);
  return routeur;
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

void main() {
  testWidgets('un lien sans adresse dans la liste : le toucher ouvre la fiche, '
      'qui relit le document, puis la confirmation, sans erreur', (
    WidgetTester tester,
  ) async {
    final List<Uri> ouverts = <Uri>[];
    final GoRouter routeur = await _monter(
      tester,
      horsTranche: false,
      ouverts: ouverts,
    );
    expect(find.byType(RessourcesClassePage), findsOneWidget);
    expect(find.text('Un site de reference'), findsOneWidget);
    // La liste elle-meme ne montre aucune adresse.
    expect(find.text(_lien), findsNothing);

    await tester.tap(find.text('Un site de reference'));
    await stabiliser(tester);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.toString(),
      startsWith('${Routes.tcBibliotheque}/lien1?retour='),
    );
    expect(find.byType(DetailRessourcePage), findsOneWidget);
    // La fiche a relu le document complet : l'adresse y est, avec le bouton.
    expect(_cle('rendu-lien'), findsOneWidget);
    expect(find.text(_lien), findsOneWidget);
    expect(_cle('rendu-lien-absent'), findsNothing);

    await tester.ensureVisible(_cle('rendu-ouvrir-lien'));
    await tester.tap(_cle('rendu-ouvrir-lien'));
    await stabiliser(tester);
    expect(_cle('rendu-lien-confirmation'), findsOneWidget);
    expect(ouverts, isEmpty);
    await tester.tap(_cle('rendu-lien-confirmer-ouvrir'));
    await stabiliser(tester);
    expect(ouverts, <Uri>[Uri.parse(_lien)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un enfant hors tranche : la liste est vide, aucun lien', (
    WidgetTester tester,
  ) async {
    final List<Uri> ouverts = <Uri>[];
    await _monter(tester, horsTranche: true, ouverts: ouverts);
    expect(find.byType(RessourcesClassePage), findsOneWidget);
    expect(find.text('Un site de reference'), findsNothing);
    expect(find.text(t.classe.pageRessources.aucune), findsOneWidget);
    expect(find.text(_lien), findsNothing);
    expect(ouverts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
