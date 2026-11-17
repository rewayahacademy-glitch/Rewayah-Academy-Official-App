// MAJEUR-DIRECTION : captures R3 de la ligne d'age du dossier (fr 360 et 1440, ar 360) et du filtre « Age » de la liste
// (fr 360 et 1440). Ne tourne que sur demande :
//   CAPTURE_R3=1 flutter test test/features/admin_candidature/majeur_direction_captures_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import '../admin_candidatures/hote_candidatures.dart';
import 'hote_candidature.dart';

Future<void> _capturer(WidgetTester tester, String nom) async {
  final RenderView vue = tester.binding.renderViews.first;
  final OffsetLayer couche = vue.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final ui.Image image = await couche.toImage(
      Offset.zero & vue.size,
      pixelRatio: 2,
    );
    final ByteData? octets = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final File f = File('docs/current/captures/E2E/MAJEUR-DIRECTION/$nom.png')
      ..createSync(recursive: true);
    f.writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

void main() {
  final bool actif = Platform.environment['CAPTURE_R3'] == '1';
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  final MajoriteCandidature attestee = MajoriteCandidature(
    servie: true,
    declaree: true,
    attesteeLe: DateTime.utc(2026, 11, 12, 10),
  );

  for (final (String, double, double) c in <(String, double, double)>[
    ('fr', 360, 900),
    ('ar', 360, 900),
    ('fr', 1440, 1000),
  ]) {
    testWidgets('capture fiche ${c.$1} ${c.$2.toInt()}', (
      WidgetTester tester,
    ) async {
      final bool ar = c.$1 == 'ar';
      await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[detailTest(majorite: attestee)],
        ),
        largeur: c.$2,
        hauteur: c.$3,
        direction: ar ? TextDirection.rtl : TextDirection.ltr,
        ouvrirRubriques: false,
      );
      await laisser(tester);
      await _capturer(tester, 'fiche-${c.$1}-${c.$2.toInt()}');
    }, skip: !actif);
  }

  for (final (double, double) c in <(double, double)>[
    (360, 900),
    (1440, 1000),
  ]) {
    testWidgets('capture filtre age ${c.$1.toInt()}', (
      WidgetTester tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: <LigneCandidature>[ligneTest(id: 'a1', nom: 'Amina Diallo')],
        ),
        largeur: c.$1,
        hauteur: c.$2,
      );
      await ouvrirFeuilleFiltresDeTest(tester);
      final Finder menu = find.byKey(
        const ValueKey<String>('feuille-filtre-age'),
      );
      await tester.ensureVisible(menu);
      await laisser(tester, fois: 2);
      await tester.tap(menu);
      await laisser(tester);
      await _capturer(tester, 'filtre-age-fr-${c.$1.toInt()}');
    }, skip: !actif);
  }
}
