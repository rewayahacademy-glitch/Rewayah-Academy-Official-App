// PROFILS P1 : captures du gabarit commun du Compte, sur une page de test
// (aucune route de production), avec des lignes fictives. 390 et 1440 ;
// clair, sombre, arabe, texte x2. Jamais lance sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:rewayah_academy/core/compte/entete_compte.dart';
import 'package:rewayah_academy/core/compte/groupe_preferences.dart';
import 'package:rewayah_academy/core/compte/page_compte.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../core/compte/page_compte_test.dart' show FausseLangueCompte;
import 'outil_capture.dart';

PageCompte _page() => PageCompte(
  titre: t.compte.page.monEspace,
  entete: EnteteCompte(
    avatar: const AvatarTile(prenom: 'Amina', diametre: 72),
    nom: 'Amina Test',
    role: 'Tuteur',
    matricule: 'RA-26-4817',
    statut: const StatusPill(libelle: 'Actif', ton: TonEtat.succes),
    onChangerPhoto: () {},
  ),
  version: 'Version 1.0.0',
  preferences: GroupePreferences(
    onNotifications: () {},
    onAccessibilite: () {},
  ),
  lignes: <SectionCompte, List<LigneRubrique>>{
    SectionCompte.monEspace: <LigneRubrique>[
      LigneRubrique(libelle: 'Mes informations', onPress: () {}),
      LigneRubrique(libelle: 'Mon foyer', valeur: '3 profils', onPress: () {}),
    ],
    SectionCompte.paiements: <LigneRubrique>[
      LigneRubrique(libelle: 'Paiements', onPress: () {}),
    ],
    SectionCompte.compteSecurite: <LigneRubrique>[
      LigneRubrique(libelle: 'Sécurité', onPress: () {}),
    ],
    SectionCompte.aideInformations: <LigneRubrique>[
      LigneRubrique(libelle: 'Aide', onPress: () {}),
    ],
  },
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PROFILS P1 : captures du gabarit', skip: sautSansCapture, () {
    for (final Size taille in <Size>[
      const Size(390, 1500),
      const Size(1440, 1300),
    ]) {
      for (final (String nom, ThemeMode theme, AppLocale langue, double x) cas
          in <(String, ThemeMode, AppLocale, double)>[
            ('clair', ThemeMode.light, AppLocale.fr, 1),
            ('sombre', ThemeMode.dark, AppLocale.fr, 1),
            ('arabe', ThemeMode.light, AppLocale.ar, 1),
            ('texte2', ThemeMode.light, AppLocale.fr, 2),
          ]) {
        final String fichier = 'page-compte/${taille.width.toInt()}-${cas.$1}';
        testWidgets(fichier, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(cas.$3));
          masquerRubanDebug();
          fixerVueCapture(tester, taille, 1);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteCapture(
              _page(),
              themeMode: cas.$2,
              echelleTexte: cas.$4,
              surcharges: <Override>[
                portLanguesCommunicationProvider.overrideWithValue(
                  FausseLangueCompte(code: 'fr'),
                ),
                stockagePreferencesProvider.overrideWithValue(
                  StockagePreferencesMemoire(),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capturerVue(tester, fichier);
        });
      }
    }
  });
}
