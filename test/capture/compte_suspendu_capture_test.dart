// COMPTE-SUSPENDU (11/11/2026) : le portail d'un compte desactive, avec
// « Contacter l'academie » en lien vers les mentions legales et « Se
// deconnecter », et la phrase pour obtenir une copie de ses donnees.
// Donnees fictives. 390 et 1440 : clair, sombre, arabe ; texte x2.
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
    for (final (String nom, AppLocale langue, ThemeMode theme, double echelle)
        in <(String, AppLocale, ThemeMode, double)>[
          ('clair', AppLocale.fr, ThemeMode.light, 1),
          ('sombre', AppLocale.fr, ThemeMode.dark, 1),
          ('arabe', AppLocale.ar, ThemeMode.light, 1),
          ('texte_x2', AppLocale.fr, ThemeMode.light, 2),
        ]) {
      for (final double largeur in <double>[390, 1440]) {
        testWidgets('${largeur.toInt()} $nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(
            tester,
            // Texte x2 : la page defile ; la capture montre tout, pied compris.
            Size(largeur, echelle > 1 ? 1500 : (largeur > 600 ? 900 : 844)),
            largeur > 600 ? 1 : 2,
          );
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
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(find.text(t.attente.suspendu), findsOneWidget);
          expect(find.text(t.attente.copieDonnees), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'compte_suspendu_${largeur.toInt()}_$nom')}',
          );
        });
      }
    }
  });
}
