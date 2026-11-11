// Captures de recette RESEAU-PREUVE (11/11/2026) : la lecture « En savoir
// plus » du bandeau de la salle, avec la phrase d'information du releve de
// qualite de connexion a la suite du texte existant. Captures de TEST (le
// vrai composant de lecture, ouvert depuis la vraie mention, hors de la
// salle) : 390 et 1440, clair et sombre, plus l'arabe en Interface guidee.
// Saute sans CAPTURE_DIR. Nommage : releve_information_<role>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/mention_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

VueSeance _vue(RoleSeance role) => VueSeance(
  role: role,
  nomClasse: 'Classe',
  nomEnseignant: 'Sayyid Ibrahim',
  initialesEnseignant: 'SI',
  enregistrementConfirme: true,
  tutoiement: role == RoleSeance.guidee,
);

Future<void> _lecture(
  WidgetTester tester,
  RoleSeance role,
  ThemeMode mode,
) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(child: MentionSeance(vue: _vue(role))),
      ),
      themeMode: mode,
      interfaceMode: role == RoleSeance.guidee
          ? InterfaceMode.enfant
          : InterfaceMode.standard,
    ),
  );
  await stabiliser(tester);
  await tester.tap(find.text(t.salle.informationControle.lien));
  await stabiliser(tester);
  // La phrase du releve est a la fin de la lecture : on l'amene a l'ecran.
  final Finder phrase = find.text(
    role == RoleSeance.guidee ? t.salle.releve.guidee : t.salle.releve.adulte,
  );
  await tester.ensureVisible(phrase);
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : RESEAU-PREUVE, information', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur)
        in <(Size, double, String)>[
          (const Size(390, 844), 3, '390'),
          (const Size(1440, 900), 1, '1440'),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'releve_information_eleve_${largeur}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cadre, densite);
          await _lecture(tester, RoleSeance.eleve, mode);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }

    testWidgets('releve_information_guidee_390_light', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await _lecture(tester, RoleSeance.guidee, ThemeMode.light);
      debugPrint(
        'PNG ${await capturer(tester, 'releve_information_guidee_390_light')}',
      );
    });

    testWidgets('releve_information_guidee_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, const Size(390, 844), 3);
      await _lecture(tester, RoleSeance.guidee, ThemeMode.light);
      debugPrint(
        'PNG ${await capturer(tester, 'releve_information_guidee_390_light_ar')}',
      );
    });
  });
}
