// APRES-CONFIRMEE : captures R3 (fr et ar, 360 px) des feuilles « Demander une verification de la piece » (candidature
// confirmee) et « Lever la restriction » (confirmee, restreinte). Ne tourne que sur demande :
//   CAPTURE_R3=1 flutter test test/features/admin_candidature/apres_confirmee_captures_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import 'hote_candidature.dart';

Future<void> _capturer(WidgetTester tester, String nom) async {
  // Tout l'ecran, surfaces modales comprises : la couche racine de la vue.
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
    final File f = File('docs/current/captures/E2E/APRES-CONFIRMEE/$nom.png')
      ..createSync(recursive: true);
    f.writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

Future<void> _ouvrirParLeMenu(
  WidgetTester tester,
  GesteCandidature geste,
) async {
  for (final Key k in <Key>[
    ValueKey<String>('candidature-decision-${geste.name}'),
    ValueKey<String>('rubrique-geste-${geste.name}'),
  ]) {
    if (find.byKey(k).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byKey(k));
      await laisser(tester, fois: 2);
      await tester.tap(find.byKey(k), warnIfMissed: false);
      await laisser(tester);
      return;
    }
  }
  await tester.ensureVisible(find.byKey(BarreDecisionDossier.cleMenu));
  await laisser(tester, fois: 2);
  await tester.tap(find.byKey(BarreDecisionDossier.cleMenu));
  await laisser(tester);
  final Finder entree = find.text(libelleGeste(geste)).last;
  await tester.ensureVisible(entree);
  await laisser(tester, fois: 2);
  await tester.tap(entree);
  await laisser(tester);
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

  final List<(String, GesteCandidature, DetailCandidature)> cas =
      <(String, GesteCandidature, DetailCandidature)>[
        (
          'verification-piece',
          GesteCandidature.demanderVerificationPiece,
          detailTest(etape: EtapeCandidature.confirmee, etat: null),
        ),
        (
          'lever',
          GesteCandidature.leverRestriction,
          detailTest(
            etape: EtapeCandidature.confirmee,
            etat: null,
            restreinte: true,
            restrictionCause: 'piece',
          ),
        ),
      ];
  for (final (String nom, GesteCandidature geste, DetailCandidature detail)
      in cas) {
    for (final bool ar in <bool>[false, true]) {
      final String lg = ar ? 'ar' : 'fr';
      testWidgets('capture $nom $lg', (WidgetTester tester) async {
        await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
        await monterCandidature(
          tester,
          port: FauxCandidaturesDirection(
            capacitesRendues: capacitesGestes,
            details: <DetailCandidature>[detail],
          ),
          largeur: 360,
          hauteur: 800,
          direction: ar ? TextDirection.rtl : TextDirection.ltr,
          ouvrirRubriques: false,
        );
        await laisser(tester);
        await _ouvrirParLeMenu(tester, geste);
        expect(find.byKey(FeuilleGeste.cle), findsOneWidget);
        await _capturer(tester, 'feuille-$nom-$lg-360');
      }, skip: !actif);
    }
  }
}
