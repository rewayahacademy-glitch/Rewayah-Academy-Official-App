// PE-B3 : captures R3 du nom latin et de la ville, des deux cotes : « Votre
// candidature » du candidat (fr 360 clair et sombre, ar 360, fr 1440) et la
// carte de profil du dossier de la direction (fr 360, ar 360, fr 1440).
// Donnees fictives. Ne tourne que sur demande :
//   CAPTURE_R3=1 flutter test test/features/candidature/saisie_sortie_captures_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../fixtures/candidature/faux_nom_latin.dart';
import '../../support/monter_recrutement.dart' show laisser;
import '../admin_candidature/hote_candidature.dart' show monterCandidature;
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
    final File f = File('docs/current/captures/E2E/PE-B3/$nom.png')
      ..createSync(recursive: true);
    f.writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

class _Lieu extends LieuAbsent {
  const _Lieu();

  @override
  Future<LieuChoisi?> monLieu() async => const LieuChoisi(
    ville: 'Casablanca',
    paysCode: 'MA',
    fuseau: 'Africa/Casablanca',
    verifie: false,
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

  for (final (String, double, double, ThemeMode) c
      in <(String, double, double, ThemeMode)>[
        ('fr', 360, 1400, ThemeMode.light),
        ('fr', 360, 1400, ThemeMode.dark),
        ('ar', 360, 1400, ThemeMode.light),
        ('fr', 1440, 1100, ThemeMode.light),
      ]) {
    final String sombre = c.$4 == ThemeMode.dark ? '-sombre' : '';
    testWidgets('capture candidat ${c.$1} ${c.$2.toInt()}$sombre', (
      WidgetTester tester,
    ) async {
      final bool ar = c.$1 == 'ar';
      await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: reponsesCompletesDeTest(),
            brouillon: false,
          ),
        ),
        etat: etatCandidat(
          candidature: CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            version: 4,
            paiement: EtatVersement.aVerifier,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
        ),
        taille: Size(c.$2, c.$3),
        direction: ar ? TextDirection.rtl : TextDirection.ltr,
        themeMode: c.$4,
        surchargesEnPlus: <Override>[
          portLieuProvider.overrideWithValue(const _Lieu()),
          portNomLatinProvider.overrideWithValue(
            FauxNomLatin(nomComplet: 'أمينة ديالو', nomLatin: 'Amina Diallo'),
          ),
        ],
      );
      await laisser(tester);
      await _capturer(tester, 'candidat-${c.$1}-${c.$2.toInt()}$sombre');
    }, skip: !actif);
  }

  for (final (String, double, double) c in <(String, double, double)>[
    ('fr', 360, 900),
    ('ar', 360, 900),
    ('fr', 1440, 1000),
  ]) {
    testWidgets('capture dossier ${c.$1} ${c.$2.toInt()}', (
      WidgetTester tester,
    ) async {
      final bool ar = c.$1 == 'ar';
      await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[
            detailTest(nom: 'أمينة ديالو', nomLatin: 'Amina Diallo'),
          ],
        ),
        largeur: c.$2,
        hauteur: c.$3,
        direction: ar ? TextDirection.rtl : TextDirection.ltr,
        ouvrirRubriques: false,
      );
      await laisser(tester);
      await _capturer(tester, 'dossier-${c.$1}-${c.$2.toInt()}');
    }, skip: !actif);
  }
}
