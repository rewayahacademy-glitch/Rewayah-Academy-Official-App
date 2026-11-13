// Captures du lot DEPOT-SIMPLE (13/11/2026) : « Ajouter un document », reduit au
// strict necessaire. Les trois etats du depot du fichier et de la vignette (en
// cours, reussi, echoue), l'enregistrement, le reglage manquant nomme, le
// document d'un tiers, « Plus de reglages ». Francais et arabe, clair et
// sombre, 1440 et 390. Par le vrai routeur, sur le double de demonstration.
//
// CAPTURE_DIR=docs/current/captures/E2E/depot-simple flutter test \
//   test/capture/capture_depot_simple_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';

import '../support/demo/bibliotheque_admin_demo.dart';
import '../support/monter_admin_demo.dart' as admin;
import 'outil_capture.dart';

/// Une vraie image PNG de 64 x 64 (des bandes), pour que la miniature de la
/// vignette se dessine.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAXklEQVR42u3ZMQ0AIAxE0WpEFBLZWSqCCQ/dmr7kG3jj5WKvbF0AAAAAAAAAAAAAAJQB97zWAQAAAAAAAAAAAADUARYZAAAAAAAAAAAAgH/AIgMAAAAAAAAAAAAYB/gfEnoO0OSGlgAAAABJRU5ErkJggg==',
);

Uint8List _pdf() {
  final Uint8List o = Uint8List(1258291);
  o.setRange(0, 5, <int>[0x25, 0x50, 0x44, 0x46, 0x2d]);
  return o;
}

class _Selecteur implements SelecteurFichierSupport {
  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async =>
      FichierChoisi(nom: 'couverture.png', octets: _png, mime: 'image/png');

  @override
  Future<FichierChoisi?> choisirDocument() async => FichierChoisi(
    nom: 'متن الأخضري-1.pdf',
    octets: _pdf(),
    mime: 'application/octet-stream',
  );
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await admin.stabiliser(tester, fois: 2);
  await tester.tap(f);
  await admin.stabiliser(tester, fois: 2);
}

/// Laisse le decodeur d'image finir, pour que la miniature se dessine.
Future<void> _laisserDecoder(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await admin.stabiliser(tester, fois: 3);
}

typedef _Scene = Future<void> Function(WidgetTester, BibliothequeAdminDemo);

Future<void> _fichierAjoute(WidgetTester tester) async {
  await _toucher(tester, _cle('import-choisir-support'));
  await admin.stabiliser(tester, fois: 40);
}

final Map<String, (BibliothequeAdminDemo Function(), _Scene)> _scenes =
    <String, (BibliothequeAdminDemo Function(), _Scene)>{
      '01-depart': (() => BibliothequeAdminDemo(nombre: 0), (_, _) async {}),
      '02-fichier-en-cours': (
        () => BibliothequeAdminDemo(
          nombre: 0,
          pas: const Duration(milliseconds: 1500),
        ),
        (WidgetTester tester, _) async {
          await _toucher(tester, _cle('import-choisir-support'));
          await tester.pump(const Duration(milliseconds: 3200));
        },
      ),
      '03-fichier-reussi': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, _) => _fichierAjoute(tester),
      ),
      '04-fichier-echoue': (
        () => BibliothequeAdminDemo(nombre: 0)..echecDepot = ErreurUpload.envoi,
        (WidgetTester tester, _) => _fichierAjoute(tester),
      ),
      '05-vignette-en-cours': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, BibliothequeAdminDemo demo) async {
          await _fichierAjoute(tester);
          demo.pas = const Duration(milliseconds: 1500);
          await _toucher(tester, _cle('import-choisir-vignette'));
          await tester.pump(const Duration(milliseconds: 3200));
        },
      ),
      '06-vignette-reussie': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, _) async {
          await _fichierAjoute(tester);
          await _toucher(tester, _cle('import-choisir-vignette'));
          await admin.stabiliser(tester, fois: 40);
          await _laisserDecoder(tester);
        },
      ),
      '07-vignette-echouee': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, BibliothequeAdminDemo demo) async {
          await _fichierAjoute(tester);
          demo
            ..echecDemande = ErreurUpload.stockage
            ..reglageEchec = 'R2_BUCKET_SUPPORTS';
          await _toucher(tester, _cle('import-choisir-vignette'));
          await admin.stabiliser(tester, fois: 12);
        },
      ),
      '08-document-enregistre': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, _) async {
          await _fichierAjoute(tester);
          await _toucher(tester, _cle('import-poursuivre'));
          await admin.stabiliser(tester, fois: 6);
        },
      ),
      '09-reglage-manquant': (
        () => BibliothequeAdminDemo(nombre: 0)
          ..reglagesManquantsServeur = <String>[
            'R2_BUCKET_SUPPORTS',
            'LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY',
          ],
        (_, _) async {},
      ),
      '10-document-d-un-tiers': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, _) async {
          await _fichierAjoute(tester);
          await _toucher(tester, _cle('import-rayon-plus_loin'));
        },
      ),
      '11-plus-de-reglages': (
        () => BibliothequeAdminDemo(nombre: 0),
        (WidgetTester tester, _) async {
          await _fichierAjoute(tester);
          await _toucher(tester, _cle('import-plus-bascule'));
        },
      ),
    };

/// Les trois etats du fichier et de la vignette, et l'enregistrement : pris
/// dans chaque langue, chaque largeur et chaque theme.
const Set<String> _etats = <String>{
  '02-fichier-en-cours',
  '03-fichier-reussi',
  '04-fichier-echoue',
  '05-vignette-en-cours',
  '06-vignette-reussie',
  '07-vignette-echouee',
  '08-document-enregistre',
};

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (
        String suffixe,
        AppLocale langue,
        bool sombre,
        Size taille,
        bool tout,
      )
      in <(String, AppLocale, bool, Size, bool)>[
        ('fr-1440-clair', AppLocale.fr, false, const Size(1440, 1900), true),
        ('fr-390-sombre', AppLocale.fr, true, const Size(390, 2600), false),
        ('ar-1440-sombre', AppLocale.ar, true, const Size(1440, 1900), false),
        ('ar-390-clair', AppLocale.ar, false, const Size(390, 2600), false),
      ]) {
    for (final MapEntry<String, (BibliothequeAdminDemo Function(), _Scene)> e
        in _scenes.entries) {
      if (!tout && !_etats.contains(e.key)) continue;
      final String nom = '${e.key}-$suffixe';
      testWidgets(nom, (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        tester.platformDispatcher.platformBrightnessTestValue = sombre
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final BibliothequeAdminDemo demo = e.value.$1();
        await admin.monterAdminDemo(
          tester,
          route: Routes.adminPedagogieBibliothequeNouveau,
          bibliotheque: demo,
          taille: taille,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          plus: <Override>[
            portCatalogueProvider.overrideWithValue(CatalogueLocal()),
            selecteurFichierSupportProvider.overrideWithValue(_Selecteur()),
          ],
        );
        await e.value.$2(tester, demo);
        await capturerVue(tester, nom);
        // Un depot pris « en cours » se termine avant la fin du test.
        for (int k = 0; k < 12; k++) {
          await tester.pump(const Duration(seconds: 2));
        }
      }, skip: sautSansCapture != false);
    }
  }
}
