// COM-ANN-2 : l'Administration des communications (COM-W04), onglet
// Annonces. La VRAIE coquille Admin, les quatre indicateurs venus seulement
// de lectures (ou de demonstration marquee), les annonces publiees et
// planifiees, la matrice des regles de portee sans ligne inventee, la
// capacite qui ouvre « Nouvelle annonce ». Rendu verifie a 390, 768 et
// 1440, clair et sombre, et en arabe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_planifiees.dart';
import 'package:rewayah_academy/features/com_annonces/matrice_audience.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_annonces/port_regles_audience.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';

import '../../support/garde_interface.dart';
import 'admin_banc.dart';
import 'faux_annonces.dart';

int _valeurTuile(WidgetTester tester, String libelle) => tester
    .widget<StatTile>(
      find.byWidgetPredicate(
        (Widget w) => w is StatTile && w.libelle == libelle,
      ),
    )
    .valeur;

void main() {
  final i = t.com.annonces.administration.indicateurs;
  final a = t.com.annonces.administration;

  group('Annonces : demonstration marquee', () {
    for (final Size taille in const <Size>[
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets(
          '${taille.width.toInt()} ${luminosite.name} : quatre indicateurs lus, '
          'une seule action pleine',
          (WidgetTester tester) async {
            await monterAdministration(
              tester,
              taille: taille,
              luminosite: luminosite,
            );
            expect(find.byType(AdminShell), findsOneWidget);
            expect(find.byType(StatTile), findsNWidgets(4));
            expect(_valeurTuile(tester, i.publiees), 3);
            expect(_valeurTuile(tester, i.planifiees), 1);
            expect(_valeurTuile(tester, i.moderation), 3);
            expect(_valeurTuile(tester, i.regles), 5);
            // Les chiffres viennent de fixtures : la page le dit.
            expect(find.byType(MarqueDemonstration), findsWidgets);
            expect(find.text(a.demo), findsWidgets);
            expect(
              find.byKey(AdministrationCommunicationsPage.cleNouvelle),
              findsOneWidget,
            );
            verifierUnSeulBoutonPlein(tester);
            // Pas de tendance, de vues ni de commentaires (section 13.3).
            expect(find.textContaining('↑'), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('1440 : publiees, planifiees et matrice en tableau', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester);
      expect(
        find.byKey(
          SectionAnnoncesAdministration.cleSection(EtatAnnonce.publiee),
        ),
        findsOneWidget,
      );
      expect(find.text(a.publiees.pastille), findsNWidgets(3));
      expect(find.text(a.planifiees.pastille), findsOneWidget);
      expect(
        find.text(t.com.annonces.demoPublication.vacancesTitre),
        findsOneWidget,
      );
      // Publiees et planifiees cote a cote sur ordinateur.
      final Rect publiees = tester.getRect(
        find.byKey(
          SectionAnnoncesAdministration.cleSection(EtatAnnonce.publiee),
        ),
      );
      final Rect planifiees = tester.getRect(
        find.byKey(
          SectionAnnoncesAdministration.cleSection(EtatAnnonce.planifiee),
        ),
      );
      expect(planifiees.left, greaterThan(publiees.right));
      expect(planifiees.top, publiees.top);

      // La matrice : les cinq lignes du port, rien de l'image.
      await tester.ensureVisible(find.byKey(MatriceAudience.cle));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((Widget w) => w is DataCollection),
        findsOneWidget,
      );
      for (final String id in <String>[
        'direction',
        'enseignants',
        'familles',
        'eleves',
        'controleurs',
      ]) {
        expect(find.byKey(MatriceAudience.cleLigne(id)), findsOneWidget);
      }
      final Finder ligneFamilles = find.byKey(
        MatriceAudience.cleLigne('familles'),
      );
      expect(
        find.descendant(of: ligneFamilles, matching: find.text(a.matrice.non)),
        findsWidgets,
      );
      expect(
        find.descendant(of: ligneFamilles, matching: find.text(a.matrice.oui)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : les indicateurs deux par deux, jamais ecrases', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, taille: const Size(390, 844));
      final Rect publiees = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) => w is StatTile && w.libelle == i.publiees,
        ),
      );
      final Rect moderation = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) => w is StatTile && w.libelle == i.moderation,
        ),
      );
      expect(moderation.top, greaterThanOrEqualTo(publiees.bottom + 16 - 1));
      expect(publiees.width, greaterThan(150));
    });

    testWidgets('l indicateur de moderation mene a l onglet Moderation', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAdministration(tester);
      await taper(
        tester,
        find.byWidgetPredicate(
          (Widget w) => w is StatTile && w.libelle == i.moderation,
        ),
      );
      expect(routeur.state.uri.path, Routes.adminCommunicationsModeration);
    });

    testWidgets('arabe, de droite a gauche, a 1440 et a 390', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, arabe: true);
      expect(
        Directionality.of(tester.element(find.byType(StatTile).first)),
        TextDirection.rtl,
      );
      expect(find.byType(StatTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await demonter(tester);
      await monterAdministration(
        tester,
        arabe: true,
        taille: const Size(390, 844),
        echelleTexte: 2,
      );
      expect(find.byType(StatTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('Matrice des regles de portee', () {
    testWidgets('demonstration : pas de colonne Validation sans source', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester);
      await tester.ensureVisible(find.byKey(MatriceAudience.cle));
      await tester.pumpAndSettle();
      expect(find.text(a.matrice.validation), findsNothing);
    });

    testWidgets('le serveur la renseigne : la colonne apparait', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, regles: const _ReglesAvecValidation());
      await tester.ensureVisible(find.byKey(MatriceAudience.cle));
      await tester.pumpAndSettle();
      expect(find.text(a.matrice.validation), findsOneWidget);
    });

    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        testWidgets(
          '${taille.width.toInt()} texte x${echelle.toInt()} : hauteur '
          'naturelle, aucun defilement imbrique',
          (WidgetTester tester) async {
            await monterAdministration(
              tester,
              taille: taille,
              echelleTexte: echelle,
            );
            final Finder liste = find.descendant(
              of: find.byKey(MatriceAudience.cleCollection),
              matching: find.byType(Scrollable),
            );
            await tester.ensureVisible(find.byKey(MatriceAudience.cle));
            await tester.pumpAndSettle();
            final ScrollPosition position = tester
                .state<ScrollableState>(liste.first)
                .position;
            expect(position.maxScrollExtent, 0);
          },
        );
      }
    }
  });

  group('Annonces : production et etats', () {
    testWidgets('ports neutres : aucun chiffre, aucune action, aucune marque', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, neutre: true);
      expect(find.byType(StatTile), findsNothing);
      for (final String libelle in <String>[
        i.publiees,
        i.planifiees,
        i.moderation,
        i.regles,
      ]) {
        expect(find.text(i.indisponible(libelle: libelle)), findsOneWidget);
      }
      expect(
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
        findsNothing,
      );
      expect(find.byType(MarqueDemonstration), findsNothing);
      expect(
        find.byWidgetPredicate((Widget w) => w is DataCollection),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans la capacite de publier, pas de « Nouvelle annonce »', (
      WidgetTester tester,
    ) async {
      await monterAdministration(
        tester,
        capacites: const <CapaciteCommunication>{CapaciteCommunication.moderer},
      );
      expect(find.byType(StatTile), findsNWidgets(4));
      expect(
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
        findsNothing,
      );
    });

    List<Override> surFaux(FauxAnnonces faux) => <Override>[
      ...surchargesDemoSansAnnonces(),
      portAnnoncesProvider.overrideWithValue(faux),
    ];

    testWidgets('vide : chaque section le dit, le zero s affiche', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, surcharges: surFaux(FauxAnnonces()));
      expect(_valeurTuile(tester, i.publiees), 0);
      expect(_valeurTuile(tester, i.planifiees), 0);
      expect(find.text(a.publiees.vide), findsOneWidget);
      expect(find.text(a.planifiees.vide), findsOneWidget);
    });

    testWidgets('erreur hors ligne : la phrase de la spec, avec Reessayer', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux = FauxAnnonces()
        ..erreurAdministration = Exception('reseau');
      await monterAdministration(
        tester,
        surcharges: surFaux(faux),
        horsLigne: true,
      );
      expect(
        find.text(t.com.socle.composants.etats.horsLigne),
        findsNWidgets(2),
      );
      expect(find.text(i.echec(libelle: i.publiees)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('erreur en ligne : echec de bloc, la page reste', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux = FauxAnnonces()
        ..erreurAdministration = Exception('panne');
      await monterAdministration(tester, surcharges: surFaux(faux));
      expect(find.text(i.echec(libelle: i.planifiees)), findsOneWidget);
      // Les autres sources restent lues.
      expect(_valeurTuile(tester, i.regles), 5);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsNothing);
    });

    testWidgets('echec de lecture : la tuile offre Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces faux = FauxAnnonces()
        ..erreurAdministration = Exception('panne');
      await monterAdministration(tester, surcharges: surFaux(faux));
      final Finder reessayer = find.byKey(
        AdministrationCommunicationsPage.cleReessayerIndicateur(i.publiees),
      );
      expect(reessayer, findsOneWidget);
      expect(find.textContaining('actualisez'), findsNothing);
      faux.erreurAdministration = null;
      await taper(tester, reessayer);
      expect(_valeurTuile(tester, i.publiees), 0);
      expect(reessayer, findsNothing);
    });

    testWidgets('sans la capacite de moderer : ni compte ni lien', (
      WidgetTester tester,
    ) async {
      final _ModerationComptee moderation = _ModerationComptee();
      final GoRouter routeur = await monterAdministration(
        tester,
        moderation: moderation,
      );
      expect(moderation.lectures, 0);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is StatTile && w.libelle == i.moderation,
        ),
        findsNothing,
      );
      expect(find.text(i.reserve(libelle: i.moderation)), findsOneWidget);
      await taper(tester, find.text(i.reserve(libelle: i.moderation)));
      expect(routeur.state.uri.path, Routes.adminCommunicationsAnnonces);
      // Les autres indicateurs restent lus.
      expect(_valeurTuile(tester, i.publiees), 3);
    });

    testWidgets('onglet Messages : la voie COM-MSG-2, pas encore disponible', (
      WidgetTester tester,
    ) async {
      await monterAdministration(tester, onglet: OngletCommunications.messages);
      expect(
        find.text(t.com.socle.navigation.provisoire.administrationDetail),
        findsOneWidget,
      );
      expect(find.byType(StatTile), findsNothing);
    });
  });
}

/// Une moderation sans capacite de moderer, qui compte les lectures de sa
/// file.
class _ModerationComptee extends ModerationAdministrationDemo {
  _ModerationComptee()
    : super(maintenant: maintenantBanc, actions: const <ActionModeration>{});

  int lectures = 0;

  @override
  Future<List<ElementModeration>> file() {
    lectures++;
    return super.file();
  }
}

/// Une matrice dont le serveur renseigne la validation.
class _ReglesAvecValidation implements PortReglesAudience {
  const _ReglesAvecValidation();

  @override
  Future<ReglesAudience> regles() async => const ReglesAudience(
    regles: <RegleAudience>[
      RegleAudience(
        id: 'enseignants',
        auteurs: 'Enseignants',
        peutPublier: true,
        audiences: 'Sa Classe seulement',
        validationRequise: true,
      ),
    ],
  );
}
