// Captures du lot DEPOT-NOM-LIBRE (13/11/2026) : apres un depot qui echoue, le
// formulaire de la direction dit la VRAIE cause, plus « la connexion s'est
// interrompue ». Par le vrai routeur, sur le double de demonstration.
//
// CAPTURE_DIR=docs/current/captures/E2E/depot-nom-libre flutter test \
//   test/capture/capture_depot_nom_libre_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';

import '../support/demo/bibliotheque_admin_demo.dart';
import '../support/monter_admin_demo.dart' as admin;
import 'outil_capture.dart';

class _Selecteur implements SelecteurFichierSupport {
  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async => FichierChoisi(
    nom: "Programme d'initiation aux sciences Islamiques - PISI.pdf",
    octets: Uint8List(2048),
    mime: 'application/pdf',
  );
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await admin.stabiliser(tester, fois: 2);
  await tester.tap(f);
  await admin.stabiliser(tester, fois: 3);
}

Future<void> _menu(WidgetTester tester, String menu, String entree) async {
  await _toucher(tester, find.text(menu).first);
  await tester.tap(find.text(entree).last);
  await admin.stabiliser(tester, fois: 3);
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final (String nom, Size taille, ErreurUpload cause)
      in <(String, Size, ErreurUpload)>[
        ('01-envoi-bloque-1440', const Size(1440, 2600), ErreurUpload.envoi),
        ('02-envoi-bloque-390', const Size(390, 3600), ErreurUpload.envoi),
        (
          '03-reglage-serveur-1440',
          const Size(1440, 2600),
          ErreurUpload.reglage,
        ),
        (
          '04-stockage-refuse-390',
          const Size(390, 3600),
          ErreurUpload.stockage,
        ),
      ]) {
    testWidgets(nom, (tester) async {
      final c = t.admin.bibliotheque.import.champs;
      await admin.monterAdminDemo(
        tester,
        route: Routes.adminPedagogieBibliothequeNouveau,
        bibliotheque: BibliothequeAdminDemo(nombre: 0)..echecDepot = cause,
        taille: taille,
        plus: <Override>[
          portCatalogueProvider.overrideWithValue(CatalogueLocal()),
          selecteurFichierSupportProvider.overrideWithValue(_Selecteur()),
        ],
      );
      await tester.enterText(_cle('import-titre'), 'Programme PISI');
      await tester.enterText(_cle('import-categorie'), 'Sciences islamiques');
      await _menu(tester, c.type, 'PDF');
      await _menu(tester, c.langue, 'Français');
      await _toucher(tester, _cle('import-choisir-support'));
      await admin.stabiliser(tester, fois: 40);
      await capturerVue(tester, nom);
    }, skip: sautSansCapture != false);
  }
}
