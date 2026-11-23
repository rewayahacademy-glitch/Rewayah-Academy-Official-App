// PARCOURS-BOUT-EN-BOUT (22/11/2026) : la frise de l'inscription et
// l'avertissement de fuseau, 390, 1280 et 1440, clair et sombre, francais et
// arabe. Donnees de test seulement. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/avertissement_fuseau.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/attente_classe/frise_inscription.dart';
import 'package:rewayah_academy/features/dossier/apprenants_demande.dart';

import '../../capture/outil_capture.dart';
import '../../support/monter_recrutement.dart';

final MonHorloge _horloge = MonHorloge.lire(<String, Object?>{
  'maintenant': '2026-11-22T09:00:00Z',
  'moi': <String, Object?>{'fuseau': 'Europe/Paris', 'decalage_secondes': 3600},
  'academie': <String, Object?>{
    'fuseau': 'Asia/Riyadh',
    'decalage_secondes': 10800,
  },
  'lieu_choisi': true,
});

void main() {
  group('Capture : PARCOURS-BOUT-EN-BOUT', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (
          String nom,
          AppLocale locale,
          TextDirection sens,
          double largeur,
          double hauteur,
          ThemeMode theme,
          bool aCompleter,
        )
        in <
          (String, AppLocale, TextDirection, double, double, ThemeMode, bool)
        >[
          (
            'fr_390_clair',
            AppLocale.fr,
            TextDirection.ltr,
            390,
            1500,
            ThemeMode.light,
            false,
          ),
          (
            'fr_1280_clair',
            AppLocale.fr,
            TextDirection.ltr,
            1280,
            900,
            ThemeMode.light,
            false,
          ),
          (
            'fr_1440_clair',
            AppLocale.fr,
            TextDirection.ltr,
            1440,
            900,
            ThemeMode.light,
            false,
          ),
          (
            'fr_390_sombre_a_completer',
            AppLocale.fr,
            TextDirection.ltr,
            390,
            1500,
            ThemeMode.dark,
            true,
          ),
          (
            'fr_1440_sombre_a_completer',
            AppLocale.fr,
            TextDirection.ltr,
            1440,
            900,
            ThemeMode.dark,
            true,
          ),
          (
            'ar_390_clair',
            AppLocale.ar,
            TextDirection.rtl,
            390,
            1500,
            ThemeMode.light,
            false,
          ),
          (
            'ar_1440_clair_a_completer',
            AppLocale.ar,
            TextDirection.rtl,
            1440,
            900,
            ThemeMode.light,
            true,
          ),
        ]) {
      testWidgets('frise $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        poserMonHorlogePourTest(_horloge);
        addTearDown(() => poserMonHorlogePourTest(null));
        await monterRecrutement(
          tester,
          chemin: '/attente',
          ecran: (_) => Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppPage.largeurReglages,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: BlocFriseInscription(),
                  ),
                ),
              ),
            ),
          ),
          surcharges: <Override>[
            lectureDemandeFamilleProvider.overrideWithValue(
              () async => (
                issue: aCompleter
                    ? IssueDemandeFamille.aCompleter
                    : IssueDemandeFamille.enCours,
                precisions: aCompleter ? 'Quel niveau ?' : null,
                motif: null,
              ),
            ),
            lectureDatesAdmissionProvider.overrideWithValue(
              () async => (
                recueLe: DateTime.utc(2026, 11, 20, 18, 30),
                decisionLe: aCompleter ? DateTime.utc(2026, 11, 21, 8) : null,
              ),
            ),
            monHorlogeProvider.overrideWith((Ref _) async => _horloge),
          ],
          largeur: largeur,
          hauteur: hauteur,
          direction: sens,
          themeMode: theme,
        );
        await laisser(tester);
        debugPrint('PNG ${await capturerVue(tester, 'frise_$nom')}');
      });
    }

    for (final (String nom, double largeur, double hauteur)
        in <(String, double, double)>[('390', 390, 400), ('1280', 1280, 300)]) {
      testWidgets('avertissement de fuseau $nom', (WidgetTester tester) async {
        await monterRecrutement(
          tester,
          chemin: '/accueil',
          ecran: (_) => Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppPage.largeurReglages,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AvertissementFuseau(
                    decalageAppareil: const Duration(hours: 3),
                    maintenant: DateTime.utc(2026, 11, 22, 9),
                  ),
                ),
              ),
            ),
          ),
          surcharges: <Override>[
            monHorlogeProvider.overrideWith((Ref _) async {
              poserMonHorlogePourTest(_horloge);
              return _horloge;
            }),
          ],
          largeur: largeur,
          hauteur: hauteur,
        );
        await laisser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'avertissement_fuseau_$nom')}',
        );
      });
    }
  });
}
