// COUPE-MOTS-1 (part 2/2) : aucun mot coupe, mesure par mot
// (getBoxesForSelection), en VRAIES polices, dans les composants partages
// corriges par la part 2 : titre de feuille (AppBottomSheet), photo publique
// (ENS-05A), ligne de GroupeReglages (offre « Assurer ce remplacement ? »),
// carte « Remplacement », LienFleche (« Ecrire a l'administration ») et cle
// de LigneCleValeur (« Reconnexions » a 100 %). LTR et RTL.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';

void _vue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _dans(Widget enfant, TextDirection sens, {double largeur = 288}) =>
    Directionality(
      textDirection: sens,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: largeur, child: enfant),
          ),
        ),
      ),
    );

final OffreRemplacement _offre = OffreRemplacement(
  seanceId: 's1',
  classe: 'Al-Fatiha',
  debut: DateTime(2026, 9, 29, 17),
  fin: DateTime(2026, 9, 29, 17, 45),
  nbEleves: 4,
);

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final TextDirection sens in TextDirection.values) {
    group(sens.name, () {
      testWidgets('photo publique a 320 x2 : « obligatoire » entier, '
          'point au bord de debut', (WidgetTester tester) async {
        _vue(tester, const Size(320, 1400));
        await tester.pumpWidget(
          hoteCapture(
            _dans(const EditeurPhotoPublique(prenom: 'Ibrahim'), sens),
            echelleTexte: 2,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(EditeurPhotoPublique));
        // Le point se pose au bord de debut du paragraphe, pas apres lui.
        final Rect point = tester.getRect(
          find.byKey(const ValueKey<String>('photo-obligatoire')),
        );
        final Rect aide = tester.getRect(
          find.textContaining('Votre photo est obligatoire'),
        );
        if (sens == TextDirection.ltr) {
          expect(point.right, lessThanOrEqualTo(aide.left));
        } else {
          expect(point.left, greaterThanOrEqualTo(aide.right));
        }
        expect(point.left, greaterThanOrEqualTo(0));
        expect(point.right, lessThanOrEqualTo(320));
      });

      testWidgets('photo publique a 390 x1 : portrait a cote des textes', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(390, 1000));
        await tester.pumpWidget(
          hoteCapture(
            _dans(
              const EditeurPhotoPublique(prenom: 'Ibrahim'),
              sens,
              largeur: 358,
            ),
          ),
        );
        await stabiliser(tester);
        verifierAucunMotCoupe(tester, find.byType(EditeurPhotoPublique));
        final Rect portrait = tester.getRect(find.byType(PortraitPublic));
        final Rect aide = tester.getRect(
          find.textContaining('Votre photo est obligatoire'),
        );
        // Meme bande horizontale : cote a cote, pas empiles.
        expect(portrait.bottom, greaterThan(aide.top));
      });

      for (final double echelle in <double>[1, 2]) {
        testWidgets('ligne d offre « Assurer ce remplacement ? » x$echelle', (
          WidgetTester tester,
        ) async {
          _vue(tester, const Size(320, 800));
          await tester.pumpWidget(
            hoteCapture(
              _dans(
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    LigneRubrique(
                      icone: AppIcons.cours,
                      libelle: 'Assurer ce remplacement ?',
                      legende: 'Al-Fatiha · mardi 29 septembre · 17:00',
                      onPress: () {},
                    ),
                  ],
                ),
                sens,
              ),
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(GroupeReglages));
        });

        testWidgets('carte « Remplacement » a 320 x$echelle', (
          WidgetTester tester,
        ) async {
          _vue(tester, const Size(320, 1200));
          await tester.pumpWidget(
            hoteCapture(
              _dans(
                CarteRemplacement(offre: _offre, date: 'mardi 29 septembre'),
                sens,
              ),
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(CarteRemplacement));
          final Rect carte = tester.getRect(find.byType(CarteRemplacement));
          expect(carte.left, greaterThanOrEqualTo(0));
          expect(carte.right, lessThanOrEqualTo(320));
        });

        testWidgets('LienFleche « Ecrire a l administration » x$echelle', (
          WidgetTester tester,
        ) async {
          _vue(tester, const Size(320, 600));
          await tester.pumpWidget(
            hoteCapture(
              _dans(
                LienFleche(
                  libelle: "Écrire à l'administration",
                  icone: AppIcons.discussion,
                  onPress: () {},
                ),
                sens,
                largeur: 224,
              ),
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(LienFleche));
        });
      }

      testWidgets('LigneCleValeur « Reconnexions » dans 240 px, x1', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(320, 400));
        await tester.pumpWidget(
          hoteCapture(
            _dans(
              const LigneCleValeur(cle: 'Reconnexions', valeur: 'Aucune'),
              sens,
              largeur: 240,
            ),
          ),
        );
        await stabiliser(tester);
        verifierAucunMotCoupe(tester, find.byType(LigneCleValeur));
      });
    });
  }
}
