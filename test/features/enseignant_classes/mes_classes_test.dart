// EN-3 : ENS-09 Mes Classes, sur les donnees de demonstration (K-35).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;

import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('ENS-09 : le tri du doc 04 §12.2', () {
    test(
      'la seance la plus proche d abord, les Classes sans seance a la fin',
      () {
        final List<ClasseListee> lignes = classesTriees(
          groupes: DonneesEnseignantDemo.groupes().reversed.toList(),
          seances: DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
          cahiers: DonneesEnseignantDemo.cahiersEnRetard(
            EtatDemoEnseignant.nominal,
          ),
          details: const <String, DetailClasse>{},
          maintenant: DonneesEnseignantDemo.maintenant,
        );
        expect(
          lignes.map((ClasseListee l) => l.groupe.libelle).toList(),
          <String>['An-Nour', 'Al-Badr', 'Al-Ikhlas'],
        );
        // Le cahier du 24 septembre d'Al-Badr n'est pas valide (K-45).
        expect(
          lignes
              .where((ClasseListee l) => l.cahierAValider)
              .map((ClasseListee l) => l.groupe.libelle),
          <String>['Al-Badr'],
        );
      },
    );

    test('une seance passee ou annulee n est pas une prochaine seance', () {
      final GroupeEnseignant g = DonneesEnseignantDemo.groupes().first;
      final DateTime m = DonneesEnseignantDemo.maintenant;
      final List<ClasseListee> lignes = classesTriees(
        groupes: <GroupeEnseignant>[g],
        seances: <SeanceEnseignant>[
          SeanceEnseignant(
            id: 's1',
            debut: m.subtract(const Duration(days: 1)),
            fin: m.subtract(const Duration(hours: 23)),
            statut: StatutSeance.planifiee,
            nbParticipants: 4,
            cahierDepose: false,
            groupeId: g.id,
          ),
          SeanceEnseignant(
            id: 's2',
            debut: m.add(const Duration(hours: 1)),
            fin: m.add(const Duration(hours: 2)),
            statut: StatutSeance.annulee,
            nbParticipants: 4,
            cahierDepose: false,
            groupeId: g.id,
          ),
        ],
        cahiers: const <CahierEnRetard>[],
        details: const <String, DetailClasse>{},
        maintenant: m,
      );
      expect(lignes.single.prochaine, isNull);
    });
  });

  group('ENS-09 : la page', () {
    testWidgets('une ligne par Classe, les exceptions seulement', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 1200));
      await tester.pumpWidget(
        hote(const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes)),
      );
      await tester.pumpAndSettle();

      // Une seule carte groupee, trois lignes : Al-Fatiha n'est qu'une offre
      // de remplacement, pas encore acceptee (E1, E7).
      expect(find.byType(GroupeReglages), findsOneWidget);
      for (final String nom in <String>['An-Nour', 'Al-Badr', 'Al-Ikhlas']) {
        expect(find.text(nom), findsOneWidget);
      }
      expect(find.text('Al-Fatiha'), findsNothing);
      // Dans l'ordre du tri.
      final double y1 = tester.getTopLeft(find.text('An-Nour')).dy;
      final double y2 = tester.getTopLeft(find.text('Al-Badr')).dy;
      final double y4 = tester.getTopLeft(find.text('Al-Ikhlas')).dy;
      expect(y1 < y2 && y2 < y4, isTrue);
      // Pas de pastille « Remplacement » : l'offre d'Al-Fatiha n'est pas
      // encore acceptee (decision EN-RC).
      expect(
        find.widgetWithText(StatusPill, t.enseignant.classes.remplacement),
        findsNothing,
      );
      // Le point de rappel du cahier d'Al-Badr, et lui seul (K-45).
      expect(find.byType(PointRappel), findsOneWidget);
      expect(
        find.textContaining(t.enseignant.classes.sansProchaine),
        findsOneWidget,
      );
      // Ni creation, ni filtre (E18, rectification ENS-09).
      expect(find.textContaining('Nouvelle'), findsNothing);
      expect(find.text('Toutes'), findsNothing);
    });

    testWidgets('aucune Classe : une phrase calme, aucun bouton', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 900));
      await tester.pumpWidget(
        hote(
          const CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.classes,
            etat: EtatDemoEnseignant.vide,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.classes.vide), findsOneWidget);
      expect(find.text(t.enseignant.classes.videDetail), findsOneWidget);
    });
  });

  // Lecon 8 (K-41.6) : le mot « Cahier de transmission a valider » (LIB-CAHIER-1)
  // et la pastille « Remplacement » sur la meme ligne, de 320 px au bureau,
  // texte a 100 % puis a 200 %, de gauche a droite puis de droite a gauche :
  // rien ne deborde, aucun mot n'est coupe (PASTILLE-COUPE-1 : « Remplacem /
  // ent » a 200 %), rien n'est tronque (CORR-SUITE-2).
  group('ENS-09 : les marques passent a la ligne', () {
    final GroupeEnseignant badr = DonneesEnseignantDemo.groupes().firstWhere(
      (GroupeEnseignant g) => g.libelle == 'Al-Badr',
    );
    for (final TextDirection sens in TextDirection.values) {
      for (final double largeur in <double>[320, 390, 600, 1280]) {
        for (final double echelle in <double>[1, 2]) {
          testWidgets('a $largeur px, texte a ${(echelle * 100).round()} %, '
              '${sens.name}', (WidgetTester tester) async {
            _fenetre(tester, Size(largeur, 1600));
            tester.platformDispatcher.textScaleFactorTestValue = echelle;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpWidget(
              hote(
                Directionality(
                  textDirection: sens,
                  child: const MesClassesPage(),
                ),
                surcharges: <Override>[
                  maintenantJourneeProvider.overrideWithValue(
                    () => DonneesEnseignantDemo.maintenant,
                  ),
                  groupesEnseignantProvider.overrideWith(
                    (Ref _) async => DonneesEnseignantDemo.groupes(),
                  ),
                  seancesEnseignantProvider.overrideWith(
                    (Ref _) async => DonneesEnseignantDemo.seances(
                      EtatDemoEnseignant.nominal,
                    ),
                  ),
                  cahiersEnRetardProvider.overrideWith(
                    (Ref _) async => DonneesEnseignantDemo.cahiersEnRetard(
                      EtatDemoEnseignant.nominal,
                    ),
                  ),
                  detailsClassesProvider.overrideWithValue(
                    <String, DetailClasse>{
                      badr.id: const DetailClasse(
                        niveau: 2,
                        langue: 'Français',
                        remplacement: true,
                      ),
                    },
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            // Le mot entier, lisible, a cote du point, et la pastille.
            final Finder mot = find.text(t.enseignant.classes.cahierAValider);
            expect(mot, findsOneWidget);
            expect(
              find.widgetWithText(
                StatusPill,
                t.enseignant.classes.remplacement,
              ),
              findsOneWidget,
            );
            // Ni coupe ni ellipse : le texte tient dans l'ecran.
            final Text texte = tester.widget<Text>(mot);
            expect(texte.overflow, isNot(TextOverflow.ellipsis));
            // Les quatre bords : en arabe, c'est le bord gauche qui deborde ;
            // le haut et le bas restent dans la fenetre (1600 de haut).
            for (final Finder f in <Finder>[mot, find.byType(StatusPill)]) {
              final Rect r = tester.getRect(f);
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(largeur));
              expect(r.top, greaterThanOrEqualTo(0));
              expect(r.bottom, lessThanOrEqualTo(1600));
            }
            // Aucun mot coupe, rien de tronque : mesure par mot, sur la
            // pastille puis sur l'ecran ENTIER (noms de classe, legendes,
            // corps des cartes, titre), sans exception.
            verifierAucunMotCoupe(tester, find.byType(StatusPill));
            verifierEcranSansMotCoupe(tester);
            // CORR-SUITE-2 : au bureau, la marque n'est plus bornee a 200 :
            // « Cahier de transmission a valider » tient sur une ligne. A
            // 100 %, en fin de ligne ; a 200 %, la marque passe SOUS la
            // legende (GroupeReglages, echelle au-dessus de 1,3), et y tient
            // encore sur une ligne.
            if (largeur >= 1280) {
              final Rect marque = tester.getRect(mot);
              // Le nom de la classe de la MEME ligne : le plus proche au-dessus
              // (ou au niveau) de la marque.
              Rect? libelle;
              for (final Element e in find.text(badr.libelle).evaluate()) {
                final Rect r = tester.getRect(find.byWidget(e.widget).first);
                if (r.top > marque.top + 1) continue;
                if (libelle == null || r.top > libelle.top) libelle = r;
              }
              expect(libelle, isNotNull);
              final Rect nom = libelle!;
              if (echelle == 1) {
                // En fin de ligne : a cote du texte, du cote de fin.
                if (sens == TextDirection.ltr) {
                  expect(marque.left, greaterThan(nom.right));
                } else {
                  expect(marque.right, lessThan(nom.left));
                }
              } else {
                expect(marque.top, greaterThanOrEqualTo(nom.bottom));
              }
            }
            // Une seule ligne a 1280 x1 ici ; a x2, la police de test (un em
            // par lettre) ne le permet pas : la ligne unique a 1280 x2 est
            // verifiee en vraies polices (test/capture/coupe_mots1_capture).
            if (largeur >= 1280 && echelle == 1) {
              final RenderParagraph p = tester.renderObject(mot);
              final Set<int> lignes = <int>{
                for (final TextBox b in p.getBoxesForSelection(
                  TextSelection(
                    baseOffset: 0,
                    extentOffset: p.text.toPlainText().length,
                  ),
                ))
                  b.top.round(),
              };
              expect(lignes, hasLength(1));
            }
            // Ellipse effective : aucune, nulle part (CORR-SUITE-2).
            for (final RenderParagraph p
                in tester.renderObjectList<RenderParagraph>(
                  find.byType(RichText),
                )) {
              expect(
                p.didExceedMaxLines,
                isFalse,
                reason: '« ${p.text.toPlainText()} » tronque',
              );
            }
            verifierAucunMotCoupe(
              tester,
              find.byKey(const ValueKey<String>('classes-cahier-a-valider')),
            );
          });
        }
      }
    }
  });

  group('PointRappel', () {
    testWidgets('fixe d emblee quand les animations sont reduites', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: PointRappel(libelle: 'rappel')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  // COUPE-MOTS-2 (point 3) : en arabe, les libelles encore en francais
  // (repli sur la langue de base) s'affichent de droite a gauche. Sans isolat,
  // la legende « Niveau 2 · Français · 3 élèves » se lisait « élèves 3 » :
  // chaque segment garde son propre sens de lecture, seul leur ordre suit
  // celui de l'ecran.
  group('COUPE-MOTS-2 : la legende garde « 3 élèves » en arabe', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets(sens.name, (WidgetTester tester) async {
        _fenetre(tester, const Size(1280, 1600));
        final GroupeEnseignant nour = DonneesEnseignantDemo.groupes()
            .firstWhere((GroupeEnseignant g) => g.libelle == 'An-Nour');
        await tester.pumpWidget(
          hote(
            Directionality(textDirection: sens, child: const MesClassesPage()),
            surcharges: <Override>[
              maintenantJourneeProvider.overrideWithValue(
                () => DonneesEnseignantDemo.maintenant,
              ),
              groupesEnseignantProvider.overrideWith(
                (Ref _) async => DonneesEnseignantDemo.groupes(),
              ),
              seancesEnseignantProvider.overrideWith(
                (Ref _) async =>
                    DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
              ),
              cahiersEnRetardProvider.overrideWith(
                (Ref _) async => DonneesEnseignantDemo.cahiersEnRetard(
                  EtatDemoEnseignant.nominal,
                ),
              ),
              // Sans niveau ni langue (donnees de demonstration) : la
              // legende commence par le chiffre, cas qui se retournait.
              detailsClassesProvider.overrideWithValue(
                const <String, DetailClasse>{},
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final String effectif = t.enseignant.classes.eleves(
          nombre: '${nour.nbMembres}',
        );
        final RenderParagraph p = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .firstWhere(
              (RenderParagraph r) =>
                  r.text.toPlainText().contains(effectif.split(' ').last) &&
                  r.text.toPlainText().contains('${nour.nbMembres}'),
            );
        final String texte = p.text.toPlainText();
        final int chiffre = texte.indexOf('${nour.nbMembres} ');
        final int mot = texte.indexOf(effectif.split(' ').last);
        Rect boite(int debut, int fin) => p
            .getBoxesForSelection(
              TextSelection(baseOffset: debut, extentOffset: fin),
            )
            .first
            .toRect();
        // Le chiffre avant le mot, dans le sens du francais, quel que soit
        // le sens de l'ecran.
        expect(
          boite(chiffre, chiffre + 1).left,
          lessThan(boite(mot, mot + 1).left),
        );
      });
    }
  });
}
