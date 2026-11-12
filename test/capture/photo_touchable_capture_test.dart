// Captures R3 de PHOTO-TOUCHABLE : le petit badge crayon sur la photo
// de l'en-tete du Compte, pour l'enseignant, le tuteur et l'eleve adulte ;
// clair et sombre ; francais et arabe ; et sans le geste (hors ligne), sans
// badge. Saute sans CAPTURE_DIR. Donnees d'essai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/entete_compte.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';

import '../teaching_core/a/faux/faux_reseau.dart';
import 'outil_capture.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture : PHOTO-TOUCHABLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    final List<(String, String Function(), String)> roles =
        <(String, String Function(), String)>[
          ('enseignant', () => t.compte.roles.teacher, 'Maryam Benali'),
          ('tuteur', () => t.compte.roles.guardian, 'Maryam Benali'),
          ('adulte', () => t.compte.roles.student, 'Maryam Benali'),
        ];
    for (final (String nomRole, String Function() role, String nom) in roles) {
      for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final bool geste in <bool>[true, false]) {
            if (!geste && nomRole != 'tuteur') continue;
            final String nomImage =
                'photo_${nomRole}_${nomMode}_${langue}_'
                '${geste ? 'touchable' : 'sans_geste'}';
            testWidgets(nomImage, (WidgetTester tester) async {
              if (langue == 'ar') {
                await tester.runAsync(
                  () => LocaleSettings.setLocale(AppLocale.ar),
                );
              }
              fixerVueCapture(tester, const Size(390, 420), 1);
              await tester.pumpWidget(
                hoteCapture(
                  PageCompte(
                    identite: AsyncValue<IdentiteCompte?>.data(
                      IdentiteCompte(
                        nom: nom,
                        role: role(),
                        matricule: 'RA-26-4817',
                      ),
                    ),
                    onDeconnecter: () async {},
                    onChangerPhoto: geste ? () {} : null,
                  ),
                  themeMode: mode,
                  surcharges: <Override>[
                    serviceReseauProvider.overrideWithValue(
                      FauxServiceReseau(horsLigneMaintenant: !geste),
                    ),
                  ],
                ),
              );
              await stabiliser(tester);
              debugPrint('PNG ${await capturerVue(tester, nomImage)}');
            });
          }
        }
      }
    }
  });
}
