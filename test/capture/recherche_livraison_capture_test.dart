// RECHERCHE-LIVRAISON (08/11/2026) : la recherche servie en production, sur le
// VRAI routeur et le VRAI branchement (`moteursRechercheProduction`), avec des
// ports qui rendent des donnees de test : la loupe visible dans la coque de
// l'enseignant, des resultats, un vide confirme, une panne. En francais et en
// arabe, a 390 et a 1440 de large.
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/recherche-livraison flutter test \
//     --no-pub test/capture/recherche_livraison_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/moteurs_production.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import '../teaching_core/b/faux/faux_ports_b.dart' show CatalogueEnEchec;
import '../teaching_core/fixtures/fixtures_ressources.dart'
    show ressourceCoran, ressourcePdf;
import '../teaching_core/h/faux/faux_ports_externes.dart' show FauxRoster;
import 'outil_capture.dart';

List<Override> _production({required bool panne}) => <Override>[
  moteursRechercheProvider.overrideWith(moteursRechercheProduction),
  if (panne)
    portCatalogueProvider.overrideWithValue(CatalogueEnEchec())
  else
    portCatalogueProvider.overrideWithValue(
      CatalogueLocal(
        ressources: <LibraryResource>[ressourceCoran, ressourcePdf],
      ),
    ),
  portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
];

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await stabiliser(tester);
}

void main() {
  group('Capture RECHERCHE-LIVRAISON', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    int rang = 0;
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String code = langue.languageCode;
        final int largeur = taille.width.toInt();
        final TextDirection direction = langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr;

        Future<void> monter(
          WidgetTester tester,
          String depart, {
          required bool panne,
        }) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterRouteur(
            tester,
            depart,
            source: FausseSourceSession(sessionActive(AppRole.teacher)),
            taille: taille,
            direction: direction,
            surcharges: _production(panne: panne),
          );
          await stabiliser(tester);
        }

        Future<void> photo(WidgetTester tester, String nom) async {
          rang++;
          debugPrint(
            'PNG ${await capturerVue(tester, '${rang.toString().padLeft(2, '0')}_${code}_${largeur}_$nom')}',
          );
        }

        testWidgets('$code $largeur : la loupe est visible', (
          WidgetTester tester,
        ) async {
          await monter(tester, Routes.enseignantJournee, panne: false);
          await photo(tester, 'loupe_visible');
        });

        testWidgets('$code $largeur : des resultats', (
          WidgetTester tester,
        ) async {
          await monter(tester, Routes.recherche, panne: false);
          await _chercher(tester, 'Coran');
          await photo(tester, 'resultats');
        });

        testWidgets('$code $largeur : un vide confirme', (
          WidgetTester tester,
        ) async {
          await monter(tester, Routes.recherche, panne: false);
          await _chercher(tester, 'zzzzzz');
          await photo(tester, 'vide');
        });

        testWidgets('$code $largeur : une panne', (WidgetTester tester) async {
          await monter(tester, Routes.recherche, panne: true);
          await _chercher(tester, 'Coran');
          await photo(tester, 'panne');
        });
      }
    }
  });
}
