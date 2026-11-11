// Captures de recette FERMETURE-SALLE (directeur, 11/11/2026, journal D-018) :
// « Votre enseignant n'est plus dans la salle » en tete de la salle de
// l'eleve, quand le serveur vient de fermer son micro.
// Telephone 390 et ordinateur 1440, clair et sombre, une en arabe.
//
// **Captures de test, pas de la vraie application** : la salle est montee avec
// les donnees de demonstration des tests (`DonneesSeanceDemo`), sans serveur ;
// l'annonce et la phrase d'attente du micro sont celles du code livre.
// **Limite du decor** : les donnees de demonstration n'ont pas d'etat « salle
// sans enseignant » ; le reste de la salle est donc celui d'une seance au
// repos. Seules l'annonce de tete et l'absence du bouton du micro sont a lire.
// Saute sans CAPTURE_DIR. Nommage : fermeture_<scene>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/annonce_geste.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// La salle de l'eleve dont le serveur vient de fermer le micro : plus de
/// bouton du micro, la phrase d'attente a sa place, l'annonce en tete.
Widget _salle() => CoucheAnnonceGeste(
  annonce: AnnonceGeste(
    titre: t.salle.fermeture.sansEnseignantTitre,
    message: t.salle.fermeture.microFerme,
  ),
  child: SalleSeance(
    vue: DonneesSeanceDemo.vue(
      RoleSeance.eleve,
      EtatDemoSalle.repos,
    ).copyWith(microEnAttente: true),
    local: const EtatLocalSeance(microOuvert: false, cameraAllumee: false),
    actions: ActionsSeance(onRetour: () {}, onQuitter: () {}),
  ),
);

Future<void> _prendre(
  WidgetTester tester,
  String nom, {
  required Size cadre,
  required double densite,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(hoteCapture(_salle(), themeMode: mode));
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
  expect(find.text(t.salle.fermeture.sansEnseignantTitre), findsOneWidget);
  expect(find.text(t.salle.fermeture.microFerme), findsOneWidget);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : FERMETURE-SALLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in _modes) {
        final String nom = 'fermeture_sans_enseignant_${largeur}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          await _prendre(
            tester,
            nom,
            cadre: cadre,
            densite: densite,
            mode: mode,
          );
        });
      }
    }

    testWidgets('fermeture_sans_enseignant_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _prendre(
        tester,
        'fermeture_sans_enseignant_390_light_ar',
        cadre: const Size(390, 844),
        densite: 3,
      );
    });
  });
}
