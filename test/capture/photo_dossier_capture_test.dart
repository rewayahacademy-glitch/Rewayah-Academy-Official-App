// PHOTO-CANDIDATURE-FIGEE (07/11/2026). FR et AR, 390 et 1440 : le bloc
// « Photo envoyee avec la candidature » de la fiche de la direction, photo
// gardee (l'image reseau ne se charge pas en test : la pastille montre les
// initiales) puis aucune photo. Prefixe des PNG : `photo_dossier_`. Saute sans
// CAPTURE_DIR. Ce ne sont pas les captures du robot de la pile locale (R3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/photo_dossier_candidat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

class _Dossier implements PortPhotoDossier {
  const _Dossier(this.p);

  final PhotoDossier p;

  @override
  Future<PhotoDossier> lire(String candidatureId) async => p;
}

class _Photos extends PhotosNeutres {
  const _Photos();

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://photos.exemple/$seau/$cle';
}

void main() {
  group('Capture : PHOTO-CANDIDATURE-FIGEE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String suffixe = '${taille.width.toInt()}_${langue.languageCode}';
        for (final (String nom, PhotoDossier p) in <(String, PhotoDossier)>[
          (
            '1_gardee',
            PhotoDossier(
              seau: 'photos_enseignants',
              cle: 'p1/1.jpg',
              figeeLe: DateTime.utc(2026, 11, 7, 9, 30),
            ),
          ),
          ('2_aucune', const PhotoDossier(seau: 'photos_enseignants')),
        ]) {
          testWidgets('photo_dossier_${nom}_$suffixe', (
            WidgetTester tester,
          ) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: SizedBox(
                        width: 560,
                        child: BlocPhotoDossier(detail: detailTest()),
                      ),
                    ),
                  ),
                ),
                surcharges: <Override>[
                  portPhotoDossierProvider.overrideWithValue(_Dossier(p)),
                  portPhotosProvider.overrideWithValue(const _Photos()),
                ],
              ),
            );
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, 'photo_dossier_${nom}_$suffixe')}',
            );
          });
        }
      }
    }
  });
}
