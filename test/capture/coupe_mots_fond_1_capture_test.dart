// Captures de preuve de COUPE-MOTS-FOND-1, dans
// docs/current/captures/COUPE-MOTS-FOND-1/. Sautees sans CAPTURE_DIR.
//
//   CAPTURE_DIR=docs/current/captures/COUPE-MOTS-FOND-1 \
//     flutter test test/capture/coupe_mots_fond_1_capture_test.dart
//
// Les ecrans de la fiche, sur les memes doubles que la garde du balayage
// (`test/garde/`) : chaque capture est aussi mesuree par la garde du rendu
// (aucun defaut sur la vue capturee).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../garde/coupe_mots_balayage_admin_test.dart' show ecransAdmin;
import '../garde/coupe_mots_balayage_pages_test.dart' show ecransPages;
import '../support/balayage_ecrans.dart';
import '../support/garde_coupe_mots_rendu.dart';
import 'outil_capture.dart';

/// Une capture : ecran, taille, echelle, langue, presentation, defilement.
typedef CasCapture = (
  String ecran,
  Size taille,
  double echelle,
  AppLocale langue,
  InterfaceMode interface,
  double defilement,
);

const List<CasCapture> _cas = <CasCapture>[
  // (1) Observations et Journal a 1440 texte x2 : en-tetes entiers, dates,
  // heures et identifiants jamais coupes (cartes quand le texte ne tient
  // pas en colonnes).
  (
    'admin Observations',
    Size(1440, 900),
    2,
    AppLocale.fr,
    InterfaceMode.standard,
    0,
  ),
  ('admin Journal', Size(1440, 900), 2, AppLocale.fr, InterfaceMode.enfant, 0),
  // (2) et (3) Comptes a 320 texte x2 : fondu de la rangee, titres de
  // carte a la meme taille (identifiant sur deux lignes).
  ('Comptes', Size(320, 568), 2, AppLocale.fr, InterfaceMode.standard, 0),
  ('Comptes', Size(320, 568), 2, AppLocale.fr, InterfaceMode.standard, 700),
  // (4) Interface guidee 320 texte x2 : aide de recherche d'Observations,
  // Bibliotheque.
  (
    'Observations (admin)',
    Size(320, 568),
    2,
    AppLocale.fr,
    InterfaceMode.enfant,
    0,
  ),
  ('Bibliotheque', Size(320, 568), 2, AppLocale.fr, InterfaceMode.enfant, 0),
  ('Bibliotheque', Size(320, 568), 2, AppLocale.ar, InterfaceMode.enfant, 500),
  // (5) Coque admin : actions sur leur rangee quand le titre n'aurait plus
  // de place (rail a 800, Interface guidee ; barre laterale a 1280).
  (
    'admin Diagnostics',
    Size(800, 900),
    1,
    AppLocale.fr,
    InterfaceMode.enfant,
    0,
  ),
  ('admin Accueil', Size(1280, 800), 2, AppLocale.fr, InterfaceMode.enfant, 0),
  // (3) Observations a 700 texte x1 : menus de la rangee sous un fondu.
  (
    'admin Observations',
    Size(700, 900),
    1,
    AppLocale.fr,
    InterfaceMode.standard,
    0,
  ),
];

void main() {
  group('Capture COUPE-MOTS-FOND-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });
    setUp(masquerRubanDebug);

    final List<EcranBalayage> ecrans = <EcranBalayage>[
      ...ecransAdmin(),
      ...ecransPages(),
    ];
    for (final CasCapture c in _cas) {
      final String nom = <String>[
        c.$1.replaceAll(RegExp(r'[^A-Za-z]+'), '_').toLowerCase(),
        '${c.$2.width.toInt()}x${c.$3.toInt()}',
        c.$4.name,
        if (c.$5 == InterfaceMode.enfant) 'guidee' else 'standard',
        if (c.$6 > 0) 'defile',
      ].join('_');
      testWidgets(nom, (WidgetTester tester) async {
        await monterEcranBalayage(
          tester,
          ecrans.firstWhere((EcranBalayage e) => e.nom == c.$1),
          (
            gabarit: (nom: nom, taille: c.$2, echelle: c.$3),
            langue: c.$4,
            interface: c.$5,
          ),
        );
        if (c.$6 > 0) {
          for (final Element e in find.byType(Scrollable).evaluate()) {
            final ScrollableState s =
                (e as StatefulElement).state as ScrollableState;
            if (axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
                s.position.maxScrollExtent > 0) {
              s.position.jumpTo(c.$6.clamp(0, s.position.maxScrollExtent));
            }
          }
          await tester.pump();
        }
        expect(defautsDeTexte(tester), isEmpty);
        await capturer(tester, nom);
      });
    }
  });
}
