// DOSSIER-DIRECTION : captures R3 de la synthese en tete du dossier (PE-C2 ;
// fr 360 et 1440, ar 360) et du complement deja coche (PE-C10 ; fr 1440, fr
// 360). Ne tourne que sur demande :
//   CAPTURE_R3=1 flutter test test/features/admin_candidature/dossier_direction_captures_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
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
    final File f = File('docs/current/captures/E2E/DOSSIER-DIRECTION/$nom.png')
      ..createSync(recursive: true);
    f.writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

/// Un dossier fictif en Salle de verification : la piece attend d'etre
/// verifiee, la photo et l'accord de publication manquent.
DetailCandidature _dossier({required bool verification}) {
  final DetailCandidature base = detailTest(
    etape: verification
        ? EtapeCandidature.verifications
        : EtapeCandidature.prequalification,
    etat: verification
        ? EtatCandidature.decisionEnAttente
        : EtatCandidature.enExamen,
    controles: const <ControleCandidature>[
      ControleCandidature(
        nom: 'piece_validee',
        valeur: false,
        cause: 'piece_a_verifier',
      ),
    ],
  );
  return DetailCandidature(
    ligne: base.ligne,
    version: base.version,
    documents: base.documents,
    provenance: base.provenance,
    controles: base.controles,
    majorite: base.majorite,
    manquants: const <String>['photo', 'accord_publication', 'pays_versement'],
    derniereConnexionServie: true,
    derniereConnexion: DateTime.now().subtract(const Duration(days: 1)),
  );
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

  for (final (String, double, double) c in <(String, double, double)>[
    ('fr', 360, 1400),
    ('ar', 360, 1400),
    ('fr', 1440, 1000),
  ]) {
    testWidgets('capture synthese ${c.$1} ${c.$2.toInt()}', (
      WidgetTester tester,
    ) async {
      final bool ar = c.$1 == 'ar';
      await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[_dossier(verification: true)],
        ),
        largeur: c.$2,
        hauteur: c.$3,
        direction: ar ? TextDirection.rtl : TextDirection.ltr,
        ouvrirRubriques: false,
      );
      await laisser(tester);
      await _capturer(tester, 'synthese-${c.$1}-${c.$2.toInt()}');
    }, skip: !actif);
  }

  for (final (double, double) c in <(double, double)>[
    (1440, 1000),
    (360, 1400),
  ]) {
    testWidgets('capture complement coche ${c.$1.toInt()}', (
      WidgetTester tester,
    ) async {
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[_dossier(verification: false)],
        ),
        largeur: c.$1,
        hauteur: c.$2,
        ouvrirRubriques: false,
      );
      final Finder bouton = find.byKey(
        const ValueKey<String>('candidature-decision-demanderComplement'),
      );
      await tester.ensureVisible(bouton);
      await laisser(tester, fois: 2);
      await tester.tap(bouton, warnIfMissed: false);
      await laisser(tester, fois: 3);
      await _capturer(tester, 'complement-coche-fr-${c.$1.toInt()}');
    }, skip: !actif);
  }
}
