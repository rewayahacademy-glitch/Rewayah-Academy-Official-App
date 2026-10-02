// Captures avant / apres du lot l1-boutons (BTN-CENTRE-1, BTN-TESTER-1,
// PHOTO-LIEN-1) : revue du directeur des 01 et 02/10/2026.
//
// N'utilise que des API presentes avant et apres le lot, pour rendre les memes
// ecrans sur les deux versions du code : `CAPTURE_PREFIXE` vaut `avant` ou
// `apres` et prefixe le nom des PNG.
//
// Saute sans CAPTURE_DIR (voir LISEZ-MOI.md du meme dossier).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';
import 'package:rewayah_academy/features/salle/preparation_enseignant.dart';

import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIXE'] ?? 'apres';

class _ChoixTemoin implements ChoixPhotoPublique {
  const _ChoixTemoin();

  @override
  Future<PhotoChoisie?> choisir() async => const PhotoChoisie();
}

const ResultatPreVol _pret = ResultatPreVol(
  microDisponible: true,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

const ContextePreparation _contexte = ContextePreparation(
  classe: 'Classe An-Nour',
  debut: 'Dans 8 min',
  support: 'Sourate Al-Fatiha',
  reprise: 'Page 24',
  eleves: '6',
);

void _rien() {}

void main() {
  group('Capture : lot l1-boutons', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size taille in const <Size>[Size(320, 1100), Size(1440, 1000)]) {
      final String l = '${taille.width.toInt()}';

      testWidgets('preparation enseignant, Tester la camera, $l px', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: PreparationEnseignant(
                resultat: _pret,
                reseau: ReseauPreparation.bonne,
                sortieAudioChoisissable: false,
                contexte: _contexte,
                onEntrer: _rien,
                onRetour: _rien,
                onReessayer: _rien,
                onTesterCamera: _rien,
              ),
            ),
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, '${_prefixe}_preparation_tester_camera_$l')}',
        );
      });

      testWidgets('photo professionnelle, Choisir une photo, $l px', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EditeurPhotoPublique(prenom: 'Ibrahim'),
              ),
            ),
            surcharges: <Override>[
              choixPhotoPubliqueProvider.overrideWithValue(
                const _ChoixTemoin(),
              ),
              horsLigneProvider.overrideWith((_) => Stream<bool>.value(false)),
            ],
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, '${_prefixe}_photo_choisir_$l')}',
        );
      });

      testWidgets('boutons du core, parent qui etire ou non, $l px', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: <Widget>[
                    FilterPill(libelle: 'Tous les eleves', onPress: _rien),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ActionPrincipale(
                        libelle: 'Tester la camera',
                        onPress: _rien,
                        pleineLargeur: false,
                      ),
                    ),
                    LienFleche(libelle: 'Choisir une photo', onPress: _rien),
                    ActionPrincipale(
                      libelle: 'Tester la camera',
                      onPress: _rien,
                      niveau: NiveauAction.secondaire,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, '${_prefixe}_boutons_core_$l')}',
        );
      });
    }
  });
}
