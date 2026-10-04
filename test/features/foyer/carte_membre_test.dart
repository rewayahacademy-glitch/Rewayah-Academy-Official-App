// FI-2-CORR (revue FI-2-R) : la carte d'un membre du Foyer pose sa fleche au
// bout de la carte a toute largeur, dans les deux sens de lecture (M1) ; la
// ligne « Couleur du profil » dit l'indisponible en production (m1) ; une
// couleur prise par plusieurs profils les nomme tous (m2).
//
// FI-2-CORR-MINEURS (revue FI-2-CORR-R) : a 320 px et texte a 200 %, aucun
// mot de la carte n'est coupe (« Abdourahmane » entier), dans les deux sens ;
// la legende « Couleur du profil » ne dit « Sans couleur » ni pendant la
// lecture ni sur un echec.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/features/foyer/fiche/couleur_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';
import '../../support/mots_coupes.dart';

const ProfilEleveFoyer _profil = ProfilEleveFoyer(
  eleveId: 'e1',
  prenom: 'Aïcha',
  nature: NatureProfilEleve.membreDuFoyer,
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

void main() {
  group('M1 : la fleche au bout de la carte', () {
    for (final double largeur in const <double>[358, 896, 1312]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('carte de ${largeur.toInt()} px, ${sens.name}', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = Size(largeur + 32, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hote(
              Directionality(
                textDirection: sens,
                child: Material(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: largeur,
                      child: CarteMembre(
                        profil: _profil,
                        legende: 'Coran, niveau 1',
                        accent: AccentProfil.menthe,
                        onPress: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final Finder carte = find.byType(CarteMembre);
          final Rect rCarte = tester.getRect(carte);
          final Finder fleche = find
              .descendant(of: carte, matching: find.byType(Icon))
              .last;
          expect(fleche, findsOneWidget);
          final Rect rFleche = tester.getRect(fleche);
          // La marge interne de la carte, et elle seule, separe la fleche du
          // bord de fin (le filet de la carte compris, a 1,5 px pres).
          final double ecartFin = sens == TextDirection.ltr
              ? rCarte.right - rFleche.right
              : rFleche.left - rCarte.left;
          expect(ecartFin, moreOrLessEquals(CarteMembre.marge, epsilon: 1.5));
        });
      }
    }
  });

  group('mineur 1 : aucun mot coupe a 320 px et 200 %', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('« Abdourahmane » entier, ${sens.name}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const String prenom = 'Abdourahmane';
        expect(prenom.length, 12);
        await tester.pumpWidget(
          hote(
            Builder(
              builder: (BuildContext context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(
                  textDirection: sens,
                  child: Material(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CarteMembre(
                          profil: const ProfilEleveFoyer(
                            eleveId: 'e2',
                            prenom: prenom,
                            nature: NatureProfilEleve.membreDuFoyer,
                            mode: InterfaceMode.standard,
                            camera: CameraPolicy.allowed,
                          ),
                          legende: 'Coran, niveau 1 · Accès actif',
                          accent: AccentProfil.menthe,
                          onPress: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(prenom), findsOneWidget);
        expect(motsCoupes(tester, find.byType(CarteMembre)), isEmpty);
      });
    }
  });

  group('mineur 5 : « Sans couleur » seulement quand c\'est lu', () {
    test('pendant la lecture : aucune legende', () {
      expect(
        legendeCouleur(
          const AsyncValue<Map<String, AccentProfil>>.loading(),
          'e1',
        ),
        isNull,
      );
    });

    test('lecture en echec ordinaire : « Couleur non lue »', () {
      expect(
        legendeCouleur(
          AsyncValue<Map<String, AccentProfil>>.error(
            StateError('reseau'),
            StackTrace.empty,
          ),
          'e1',
        ),
        t.ficheEleve.lignes.couleurEchec,
      );
      expect(
        t.ficheEleve.lignes.couleurEchec,
        isNot(t.ficheEleve.lignes.couleurAucune),
      );
    });
  });

  group('m1 : legende de la ligne « Couleur du profil »', () {
    test('sans source (production) : « Pas encore disponible »', () {
      expect(
        legendeCouleur(
          const AsyncValue<Map<String, AccentProfil>>.error(
            CapaciteIndisponible('FI-BR-19'),
            StackTrace.empty,
          ),
          'e1',
        ),
        t.ficheEleve.lignes.couleurIndisponible,
      );
    });

    test('lue sans choix : « Sans couleur » ; lue avec choix : son nom', () {
      expect(
        legendeCouleur(
          const AsyncValue<Map<String, AccentProfil>>.data(
            <String, AccentProfil>{},
          ),
          'e1',
        ),
        t.ficheEleve.lignes.couleurAucune,
      );
      expect(
        legendeCouleur(
          const AsyncValue<Map<String, AccentProfil>>.data(
            <String, AccentProfil>{'e1': AccentProfil.ciel},
          ),
          'e1',
        ),
        t.ficheEleve.couleur.ciel,
      );
    });
  });

  group('m2 : une couleur prise par plusieurs profils les nomme tous', () {
    test('aucun, un, deux, trois prenoms', () {
      expect(prenomsJoints(const <String>[]), isNull);
      expect(prenomsJoints(const <String>['Yusuf']), 'Yusuf');
      expect(
        prenomsJoints(const <String>['Yusuf', 'Mariam']),
        'Yusuf et Mariam',
      );
      expect(
        prenomsJoints(const <String>['Yusuf', 'Mariam', 'Ibrahim']),
        'Yusuf, Mariam et Ibrahim',
      );
    });
  });
}
