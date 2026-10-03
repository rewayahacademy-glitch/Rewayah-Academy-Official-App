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
    for (final TextDirection sens in TextDirection.values)
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
            // Les quatre bords : en arabe, c'est le bord gauche qui deborde.
            for (final Finder f in <Finder>[mot, find.byType(StatusPill)]) {
              final Rect r = tester.getRect(f);
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(largeur));
            }
            // Aucun mot coupe, rien de tronque : mesure par mot.
            verifierAucunMotCoupe(tester, find.byType(StatusPill));
            // CORR-SUITE-2 : au bureau, la marque n'est plus bornee a 200 :
            // « Cahier de transmission a valider » tient sur une ligne.
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
            verifierAucunMotCoupe(
              tester,
              find.byKey(const ValueKey<String>('classes-cahier-a-valider')),
            );
          });
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
}
