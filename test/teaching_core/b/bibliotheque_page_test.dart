import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/vue_catalogue.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';
import 'package:rewayah_academy/features/tc_catalogue/carte_ressource.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_catalogue/vignette_ressource.dart';

import '../../support/garde_interface.dart';
import '../../support/hors_ligne_une_fois.dart';

import 'faux/faux_ports_b.dart';
import 'support/hote_b.dart';

/// La surface, posee dans une boite bornee : c'est ce que fait `PageShell` en
/// mode non defilant.
Widget surface({
  String? groupeId,
  ContexteDecouverte contexte = ContexteDecouverte.horsClasse,
  void Function(LibraryResource, ContentPosition?)? onChoisir,
}) => Scaffold(
  body: SurfaceBibliotheque(
    contexte: contexte,
    groupeId: groupeId,
    onChoisir: onChoisir ?? (LibraryResource _, ContentPosition? _) {},
  ),
);

void main() {
  group('Bibliotheque : les etats de la liste', () {
    testWidgets('catalogue vide : un vide subi, sans bouton', (
      WidgetTester tester,
    ) async {
      fenetreTelephone(tester);

      await tester.pumpWidget(
        hoteB(surface(), surcharges: surchargesCatalogue()),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.tc.bibliotheque.vide.message), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.vide.invitation), findsOneWidget);
      expect(find.byType(CarteRessource), findsNothing);
    });

    testWidgets('une ressource : une carte, sa couverture, son etat', (
      WidgetTester tester,
    ) async {
      fenetreTelephone(tester);

      await tester.pumpWidget(
        hoteB(
          surface(),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1', titre: 'Alphabet arabe'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarteRessource), findsOneWidget);
      expect(find.text('Alphabet arabe'), findsOneWidget);
      // La couverture est calculee, pas une icone generique partagee.
      expect(find.byType(VignetteRessource), findsOneWidget);
      // L'etat hors ligne est un mot, pas seulement une couleur.
      expect(find.text(t.tc.bibliotheque.offline.aTelecharger), findsWidgets);
    });

    testWidgets('couverture manquante : la vignette reste distincte', (
      WidgetTester tester,
    ) async {
      fenetreTelephone(tester);

      await tester.pumpWidget(
        hoteB(
          surface(),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(
                id: 'aa',
                titre: 'Premier support',
                titreCourt: 'Premier support',
              ),
              ressource(
                id: 'zz',
                titre: 'Second support',
                titreCourt: 'Second support',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aucune des deux n'a de `cover_asset`, et pourtant les deux portent un
      // monogramme different : c'est le repli controle de la spec 6.1.
      expect(find.text('PS'), findsOneWidget);
      expect(find.text('SS'), findsOneWidget);
    });

    testWidgets('lecture en echec : un etat de panne, pas un catalogue vide', (
      WidgetTester tester,
    ) async {
      fenetreTelephone(tester);

      await tester.pumpWidget(
        hoteB(
          surface(),
          surcharges: surchargesCatalogue(catalogue: CatalogueEnEchec()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.tc.bibliotheque.indisponible.message), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.vide.message), findsNothing);
      // EA-HL-DOUBLE-1f (K-59) : la cause probable est dite sans etre
      // affirmee, et « momentanement indisponible » n'est plus dit.
      expect(
        find.text(t.tc.bibliotheque.indisponible.invitation),
        findsOneWidget,
      );
      expect(causesAffirmees(), findsNothing);
    });
  });

  group('Bibliotheque : cartes separees de 16 (K-55)', () {
    for (final double largeur in <double>[320, 1440]) {
      testWidgets('les cartes de ressource ne se collent pas a $largeur px', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(largeur, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          hoteB(
            surface(),
            surcharges: surchargesCatalogue(
              ressources: <LibraryResource>[
                ressource(id: 'r1', titre: 'Alphabet arabe'),
                ressource(id: 'r2', titre: 'Regles du meem'),
                ressource(id: 'r3', titre: 'Le Coran'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final int n = verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is CarteRessource,
        );
        expect(n, 3);
      });
    }
  });

  group('Bibliotheque : recherche et filtres', () {
    List<LibraryResource> trois() => <LibraryResource>[
      ressource(id: 'r1', titre: 'Alphabet arabe', type: TypeRessource.lecon),
      ressource(id: 'r2', titre: 'Règles du meem', type: TypeRessource.pdf),
      ressource(id: 'r3', titre: 'Le Coran', type: TypeRessource.quran),
    ];

    testWidgets('une recherche sans resultat propose de tout reafficher', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(surface(), surcharges: surchargesCatalogue(ressources: trois())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'biologie');
      await tester.pumpAndSettle();

      expect(
        find.text(t.tc.bibliotheque.aucunResultat.message),
        findsOneWidget,
      );
      expect(find.byType(CarteRessource), findsNothing);

      await tester.tap(find.text(t.tc.bibliotheque.effacerRecherche).last);
      await tester.pumpAndSettle();

      expect(find.byType(CarteRessource), findsNWidgets(3));
    });

    testWidgets('une recherche accentuee trouve sans accent', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(surface(), surcharges: surchargesCatalogue(ressources: trois())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'regles');
      await tester.pumpAndSettle();

      expect(find.byType(CarteRessource), findsOneWidget);
      expect(find.text('Règles du meem'), findsOneWidget);
    });

    testWidgets('un filtre de type restreint la liste', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(surface(), surcharges: surchargesCatalogue(ressources: trois())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.tc.bibliotheque.type.pdf).first);
      await tester.pumpAndSettle();

      expect(find.byType(CarteRessource), findsOneWidget);
      expect(find.text('Règles du meem'), findsOneWidget);
    });
  });

  group('Bibliotheque : hors ligne', () {
    testWidgets(
      'hors ligne, une ressource non telechargee reste visible et dit pourquoi',
      (WidgetTester tester) async {
        fenetreHaute(tester);

        await tester.pumpWidget(
          hoteB(
            surface(),
            surcharges: surchargesCatalogue(
              ressources: <LibraryResource>[ressource(id: 'r1')],
              reseau: FauxServiceReseau(horsLigneRendu: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CarteRessource), findsOneWidget);
        expect(
          find.text(t.tc.bibliotheque.message.horsLigneNonTelecharge),
          findsOneWidget,
        );

        // Et la carte ne mene nulle part : un geste qui ne peut pas aboutir
        // n'est pas offert.
        final CarteRessource carte = tester.widget<CarteRessource>(
          find.byType(CarteRessource),
        );
        expect(carte.onPress, isNull);
      },
    );

    testWidgets('en ligne, la meme ressource s ouvre', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);
      LibraryResource? choisie;

      await tester.pumpWidget(
        hoteB(
          surface(
            onChoisir: (LibraryResource r, ContentPosition? _) => choisie = r,
          ),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[ressource(id: 'r1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CarteRessource));
      await tester.pumpAndSettle();

      expect(choisie?.id, 'r1');
    });
  });

  group('Bibliotheque : plusieurs centaines de ressources', () {
    testWidgets('seules les cartes visibles sont construites', (
      WidgetTester tester,
    ) async {
      fenetreTelephone(tester);

      await tester.pumpWidget(
        hoteB(
          surface(),
          surcharges: surchargesCatalogue(
            ressources: List<LibraryResource>.generate(
              400,
              (int i) => ressource(id: 'r$i', titre: 'Support $i'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // La liste est paresseuse : sans cela, 400 couvertures seraient peintes
      // pour un ecran qui en montre six.
      final int construites = tester
          .widgetList<CarteRessource>(find.byType(CarteRessource))
          .length;
      expect(construites, greaterThan(0));
      expect(construites, lessThan(40));
    });
  });

  group('Fiche : ce qui est possible, et ce qui ne l est pas', () {
    testWidgets('une ressource invisible pour l appelant est expliquee', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'absente'),
          surcharges: surchargesCatalogue(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.tc.bibliotheque.introuvable.message), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.indisponible.message), findsNothing);
    });

    testWidgets('sans artefact, aucun bouton de copie n est rendu', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'r1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1', titre: 'Alphabet arabe'),
            ],
            versions: <String, List<ResourceVersion>>{
              'r1': <ResourceVersion>[version(id: 'v1', resourceId: 'r1')],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bouton n'est pas grise : il n'existe pas, et une phrase prend sa
      // place.
      expect(
        find.text(t.tc.bibliotheque.action.enregistrerCopie),
        findsNothing,
      );
      expect(
        find.text(t.tc.bibliotheque.message.aucunTelechargement),
        findsOneWidget,
      );
    });

    testWidgets('un PDF annonce que son apercu n est pas encore disponible', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'r1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1', type: TypeRessource.pdf),
            ],
            versions: <String, List<ResourceVersion>>{
              'r1': <ResourceVersion>[version(id: 'v1', resourceId: 'r1')],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.tc.bibliotheque.detail.apercuIndisponible),
        findsOneWidget,
      );
    });

    testWidgets('un telechargement impossible est dit, pas tu', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'r1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[ressource(id: 'r1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.tc.bibliotheque.action.telecharger));
      await tester.pumpAndSettle();

      expect(
        find.text(t.tc.bibliotheque.message.telechargementImpossible),
        findsOneWidget,
      );
      // Le retour local se retire seul : on le laisse expirer pour ne pas
      // finir le test sur un minuteur en vol.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('avec un artefact, la copie passe par le selecteur systeme', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);
      final FauxEnregistrementFichier selecteur = FauxEnregistrementFichier();

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'r1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1', titre: 'Règles du meem'),
            ],
            artefacts: <String, List<DownloadAsset>>{
              'v1': <DownloadAsset>[
                artefact(id: 'a1', versionId: 'v1', cle: 'supports/r1.pdf'),
              ],
            },
            octets: <String, List<int>>{
              'supports/r1.pdf': <int>[37, 80, 68, 70],
            },
            enregistrement: selecteur,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.tc.bibliotheque.action.enregistrerCopie));
      await tester.pumpAndSettle();

      // Le nom propose est celui du support, le type MIME celui du format, et
      // aucun chemin n'est fabrique : c'est le systeme qui choisit ou ecrire.
      expect(selecteur.appels.single.nom, 'Règles du meem.pdf');
      expect(selecteur.appels.single.mime, 'application/pdf');
      expect(selecteur.appels.single.taille, 4);
      expect(
        find.text(t.tc.bibliotheque.message.copieEnregistree),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('une ressource sans version publiee le dit', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);

      await tester.pumpWidget(
        hoteB(
          const DetailRessourcePage(resourceId: 'r1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              ressource(id: 'r1', versionCourante: null),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.tc.bibliotheque.detail.sansVersion), findsOneWidget);
    });
  });

  group('Continuer et Pour ce groupe', () {
    testWidgets('la reprise ouvre la liste, avant les autres sections', (
      WidgetTester tester,
    ) async {
      fenetreHaute(tester);
      final LibraryResource r = ressource(id: 'r1', titre: 'Alphabet arabe');

      await tester.pumpWidget(
        hoteB(
          surface(groupeId: 'g1'),
          surcharges: surchargesCatalogue(
            ressources: <LibraryResource>[
              r,
              ressource(id: 'r2'),
            ],
            assignations: <String, List<String>>{
              'g1': <String>['r2'],
            },
            reprise: ReprisLecture(
              ressource: r,
              position: const ContentPosition.page(resourceId: 'r1', page: 12),
              vueLeUtc: DateTime.utc(2026, 9, 19),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final double yContinuer = tester
          .getTopLeft(find.text(t.tc.bibliotheque.sections.continuer))
          .dy;
      final double yGroupe = tester
          .getTopLeft(find.text(t.tc.bibliotheque.sections.pourCeGroupe))
          .dy;

      expect(yContinuer, lessThan(yGroupe));
    });
  });
}
