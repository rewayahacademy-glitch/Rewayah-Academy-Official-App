// COMPTE-SUSPENDU (11/11/2026) : le portail d'un compte desactive, avec
// « Contacter l'academie » en lien vers les mentions legales et « Se
// deconnecter ». Donnees fictives. 390, clair, sombre et arabe.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : compte suspendu', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 844), 2);
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = const EtatDossier(
            profilExiste: true,
            role: AppRole.guardian,
            statutCompte: AccountStatus.disabled,
            accuseSigne: true,
            contratSigne: true,
            codeConduiteSigne: true,
            pieceDeposee: false,
          );
        await tester.pumpWidget(
          hoteCapture(
            const AttentePage(),
            surcharges: <Override>[
              serviceDossierProvider.overrideWithValue(dossier),
            ],
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(t.attente.suspendu), findsOneWidget);
        debugPrint('PNG ${await capturer(tester, 'compte_suspendu_$nom')}');
      });
    }
  });
}
