// Lot RACINE (PE-D8, PE-D9 ; directeur, 19/11/2026) : captures R3. Donnees de
// test seulement. Jamais sans `CAPTURE_DIR`.
//   - l'avis « nouvelle version » (Mettre a jour, Plus tard) et l'avis
//     « Vous avez recu un nouveau message », flottant par-dessus une page
//     qui ne bouge pas (fr, ar ; 390x844 et 1440x900) ;
//   - le signe discret « Messages pas en direct », avec sa croix.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/fraicheur/avis_flottant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/version/bandeau_nouvelle_version.dart';
import 'package:rewayah_academy/core/version/nouvelle_version.dart';
import 'package:rewayah_academy/features/candidature/cadre_religieux_page.dart';

import 'outil_capture.dart';

const String _dossier = 'pe-racine';

class _VersionNouvelle extends SurveillanceVersion {
  @override
  bool build() => true;
}

class _VeilleTombee extends EtatVeilleMessagesControleur {
  @override
  EtatVeilleMessages build() => const EtatVeilleMessages(enDirect: false);
}

Future<void> _langue(WidgetTester tester, AppLocale langue) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('PE-RACINE', skip: sautSansCapture, () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
        final String nom =
            'avis_flottants_${langue.name}_${taille.width.toInt()}x${taille.height.toInt()}';
        testWidgets(nom, (WidgetTester tester) async {
          await _langue(tester, langue);
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteCapture(
              CoucheAvis(
                avis: const <Widget>[
                  BandeauNouvelleVersion(),
                  BandeauAvisEphemere(),
                ],
                child: Scaffold(
                  appBar: AppBar(title: Text(t.com.messages.direct.nouveau)),
                  body: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: <Widget>[
                      for (int i = 0; i < 12; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Text(t.miseAJour.prete),
                        ),
                    ],
                  ),
                ),
              ),
              surcharges: <Override>[
                nouvelleVersionProvider.overrideWith(_VersionNouvelle.new),
                etatVeilleMessagesProvider.overrideWith(_VeilleTombee.new),
                horsLigneProvider.overrideWith(
                  (Ref _) => Stream<bool>.value(false),
                ),
              ],
            ),
          );
          ProviderScope.containerOf(
                tester.element(find.byType(BandeauAvisEphemere)),
              )
              .read(avisEphemereProvider.notifier)
              .dire(t.com.messages.direct.nouveau);
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, '$_dossier/$nom')}');
          ProviderScope.containerOf(
            tester.element(find.byType(BandeauAvisEphemere)),
          ).read(avisEphemereProvider.notifier).effacer();
          await tester.pumpAndSettle();
        });
      }
    }

    // PE-D11 : un texte long de lecture (le cadre), selectionne dans sa
    // seule zone, en arabe (de droite a gauche) puis en francais.
    for (final AppLocale langue in <AppLocale>[AppLocale.ar, AppLocale.fr]) {
      final String nom = 'texte_selectionne_${langue.name}_390x844';
      testWidgets(nom, (WidgetTester tester) async {
        await _langue(tester, langue);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final String texte = langue == AppLocale.ar
            ? 'الإطار الديني والتربوي\n\nنقرأ القرآن بتدبر ونحترم المعلم والطالب.\n\nيلتزم المعلم بالمنهج وبمواعيد الحصة.'
            : 'Le cadre religieux et pedagogique\n\nNous lisons le Coran avec attention et respectons chacun.\n\nL\'enseignant suit le programme et les horaires.';
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TexteCadrePublie(texte: texte),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(TexteCadrePublie));
        await tester.pumpAndSettle();
        tester
            .state<SelectableRegionState>(find.byType(SelectableRegion))
            .selectAll();
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '$_dossier/$nom')}');
      });
    }
  });
}
