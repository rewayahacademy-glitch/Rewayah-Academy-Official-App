// Catalogue des classes (lot C, sous-paquet 3) : parcours touches depuis la
// barre de navigation, sur le VRAI routeur (Accueil > profil sans classe >
// « Choisir une classe » > carte > confirmation > resultat), puis etats et
// fonctions pures.
//
// Donnees : fixtures isolees et doubles de `support_classe.dart`. Aucun
// service reel ; sans double, le catalogue est celui de la production
// (aucune source, aucun fuseau).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/catalogue_classes_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import 'support_classe.dart';

final _c = t.classe.pageCatalogue;

/// Monte l'application sur son vrai routeur, puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  String depart = Routes.tuteurFoyer,
  PortCatalogueClasses? catalogue,
  PortClassesFoyer? portClasses,
  String? fuseau = 'Europe/Paris',
  bool horsLigne = false,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesClasse(
        portClasses: portClasses,
        catalogueClasses: catalogue,
        fuseauCatalogue: fuseau,
        horsLigne: horsLigne,
      ),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

String _lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

String get _catalogueA2 => '${Routes.tuteurClassesCatalogue}?eleve=$eleveA2';

/// De la barre basse au catalogue : Accueil, profil « Eleve A2 » (sans
/// classe), puis « Choisir une classe ».
Future<void> _ouvrirLeCatalogue(WidgetTester tester, GoRouter routeur) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.accueil),
    ),
  );
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);
  await _toucher(
    tester,
    find.descendant(
      of: find.byType(SelecteurProfils),
      matching: find.text('Eleve A2'),
    ),
  );
  await _toucher(tester, find.text(t.classe.catalogue));
  expect(_lieu(routeur), _catalogueA2);
  expect(find.byType(CatalogueClassesPage), findsOneWidget);
}

/// Le foyer A : A1 dans la classe A, A2 sans classe.
FauxClassesFoyer _classesFoyer() => FauxClassesFoyer(
  classes: <ClasseFoyer>[
    ClasseFoyer(eleveId: eleveA1, classe: classeFictive()),
  ],
);

void main() {
  group('Catalogue : cartes separees de 16 (K-55)', () {
    for (final double largeur in <double>[320, 1440]) {
      testWidgets('les classes proposees ne se collent pas a $largeur px', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          depart: _catalogueA2,
          catalogue: FauxCatalogueClasses(),
          taille: Size(largeur, 4000),
        );
        expect(find.byType(CarteClasseOuverte), findsNWidgets(3));

        final int n = verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is AppCard || w is CarteClasseOuverte,
        );
        expect(n, greaterThanOrEqualTo(3));
      });
    }
  });

  group('Catalogue : parcours touches depuis la barre de navigation', () {
    testWidgets('choisir une classe ouverte, confirmer, puis « Voir la '
        'classe » ouvre la classe de l eleve', (WidgetTester tester) async {
      final FauxClassesFoyer classes = _classesFoyer();
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses(
        classesFoyer: classes,
      );
      final GoRouter routeur = await _monter(
        tester,
        catalogue: catalogue,
        portClasses: classes,
      );
      await _ouvrirLeCatalogue(tester, routeur);

      // Une carte par classe : enseignant nomme, etat, places du serveur.
      expect(find.byType(CarteClasseOuverte), findsNWidgets(3));
      expect(find.text('Classe fictive B'), findsOneWidget);
      expect(
        find.text('${t.tc.groupe.enseignant.sayyida} Enseignante Y'),
        findsOneWidget,
      );
      // Titre non rendu : le prenom seul, jamais un titre devine.
      expect(find.text('Enseignant Z'), findsOneWidget);
      expect(find.text(_c.places(nombre: 2)), findsOneWidget);
      expect(find.text(_c.etat.complete), findsOneWidget);
      // Une action par classe qui peut aboutir : aucune pour la complete.
      expect(find.text(_c.choisir), findsOneWidget);
      expect(find.text(_c.rejoindreAttente), findsOneWidget);
      // Demande C-14 : seances, fuseau et parcours rendus par K6 ; sans
      // seances rendues, la phrase honnete reste.
      expect(
        find.text(
          _c.seanceHebdo(
            jour: t.commun.dates.jours[1],
            heure: '18:30',
            duree: 45,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(_c.fuseauClasse(fuseau: 'Europe/Paris')),
        findsOneWidget,
      );
      expect(find.text('Cours fictif · Niveau fictif'), findsOneWidget);
      expect(find.text(_c.horairesAbsents), findsNWidgets(2));
      // Les heures sont demandees dans le fuseau connu, jamais devine.
      expect(catalogue.fuseaux, everyElement('Europe/Paris'));
      // Onglet Accueil actif, retour visible.
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
      expect(find.byType(DisqueRetour), findsOneWidget);

      await _toucher(tester, find.text(_c.choisir));
      expect(find.text(_c.confirmerTitre), findsWidgets);
      expect(find.text(_c.confirmerPhrase(prenom: 'Eleve A2')), findsOneWidget);
      expect(
        find.text(
          _c.memeEnseignant(
            enseignant: '${t.tc.groupe.enseignant.sayyida} Enseignante Y',
          ),
        ),
        findsOneWidget,
      );
      expect(catalogue.demandes, isEmpty, reason: 'rien avant confirmation');

      await _toucher(tester, find.text(_c.confirmer));
      expect(catalogue.demandes, hasLength(1));
      expect(catalogue.demandes.single.classeId, 'classe-b');
      expect(catalogue.demandes.single.eleveId, eleveA2);
      expect(find.text(_c.resultat.inscritTitre), findsOneWidget);
      expect(
        find.text(
          _c.resultat.inscritPhrase(
            prenom: 'Eleve A2',
            classe: 'Classe fictive B',
          ),
        ),
        findsOneWidget,
      );

      await _toucher(tester, find.text(_c.resultat.voirClasse));
      expect(_lieu(routeur), Routes.classePour('classe-b', eleveId: eleveA2));
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      expect(find.text('Classe fictive B'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('liste d attente : confirmer, puis retour a l Accueil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        catalogue: FauxCatalogueClasses(statut: StatutInscription.listeAttente),
      );
      await _ouvrirLeCatalogue(tester, routeur);

      await _toucher(tester, find.text(_c.rejoindreAttente));
      expect(
        find.text(_c.confirmerAttentePhrase(prenom: 'Eleve A2')),
        findsOneWidget,
      );
      await _toucher(tester, find.text(_c.confirmerAttente));
      expect(find.text(_c.resultat.listeAttenteTitre), findsOneWidget);

      await _toucher(tester, find.text(_c.resultat.retourAccueil));
      expect(_lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('demande a valider : le resultat le dit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        catalogue: FauxCatalogueClasses(
          statut: StatutInscription.enAttenteValidation,
        ),
      );
      await _ouvrirLeCatalogue(tester, routeur);
      await _toucher(tester, find.text(_c.choisir));
      await _toucher(tester, find.text(_c.confirmer));
      expect(find.text(_c.resultat.validationTitre), findsOneWidget);
    });

    testWidgets('inscription refusee (derniere place perdue) : « Voir les '
        'autres classes » relit la liste', (WidgetTester tester) async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses(
        statut: StatutInscription.refuse,
      );
      final GoRouter routeur = await _monter(tester, catalogue: catalogue);
      await _ouvrirLeCatalogue(tester, routeur);
      await _toucher(tester, find.text(_c.choisir));
      await _toucher(tester, find.text(_c.confirmer));
      expect(find.text(_c.resultat.refuseTitre), findsOneWidget);
      expect(
        find.text(_c.resultat.refusePhrase(prenom: 'Eleve A2')),
        findsOneWidget,
      );

      final int lectures = catalogue.fuseaux.length;
      await _toucher(tester, find.text(_c.resultat.autresClasses));
      expect(find.byType(CarteClasseOuverte), findsNWidgets(3));
      expect(catalogue.fuseaux.length, greaterThan(lectures));
    });

    testWidgets('reponse perdue : « Reessayer » reprend la MEME cle', (
      WidgetTester tester,
    ) async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses()
        ..erreurInscription = StateError('reponse perdue');
      final GoRouter routeur = await _monter(tester, catalogue: catalogue);
      await _ouvrirLeCatalogue(tester, routeur);
      await _toucher(tester, find.text(_c.choisir));
      await _toucher(tester, find.text(_c.confirmer));

      expect(find.text(_c.envoiIncertain), findsOneWidget);
      await _toucher(tester, find.text(t.commun.reessayer));
      expect(catalogue.demandes, hasLength(2));
      expect(catalogue.demandes[0].cle, catalogue.demandes[1].cle);
      expect(find.text(_c.resultat.inscritTitre), findsOneWidget);
    });

    testWidgets('double pression : une seule demande', (
      WidgetTester tester,
    ) async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses()
        ..retenue = Completer<void>();
      final GoRouter routeur = await _monter(tester, catalogue: catalogue);
      await _ouvrirLeCatalogue(tester, routeur);
      await _toucher(tester, find.text(_c.choisir));

      await tester.tap(find.text(_c.confirmer));
      await tester.pump();
      // Le libelle cede la place a l'attente : le bouton est touche par type.
      await tester.tap(find.byType(ActionPrincipale).last, warnIfMissed: false);
      await tester.pump();
      catalogue.retenue!.complete();
      await stabiliser(tester);
      expect(catalogue.demandes, hasLength(1));
      expect(find.text(_c.resultat.inscritTitre), findsOneWidget);
    });

    testWidgets('le retour de la confirmation revient a la liste, celui de '
        'la liste a l Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        catalogue: FauxCatalogueClasses(),
      );
      await _ouvrirLeCatalogue(tester, routeur);
      await _toucher(tester, find.text(_c.choisir));
      await _toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(CarteClasseOuverte), findsNWidgets(3));
      expect(_lieu(routeur), _catalogueA2);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(_lieu(routeur), Routes.tuteurAccueil);
    });
  });

  group('Catalogue : etats', () {
    testWidgets('production : aucune source, choix en ligne pas encore '
        'ouvert, aucune action', (WidgetTester tester) async {
      await _monter(tester, depart: _catalogueA2);
      expect(find.text(_c.indisponible), findsOneWidget);
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).dependance,
        'DB-CRS-07',
      );
      expect(find.text(_c.choisir), findsNothing);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('fuseau connu mais catalogue sans source : indisponible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: _catalogueA2,
        catalogue: const CatalogueClassesIndisponible(),
      );
      expect(find.text(_c.indisponible), findsOneWidget);
    });

    testWidgets('inscription sans source : dite, aucune place reservee, '
        'aucun bouton de confirmation', (WidgetTester tester) async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses()
        ..erreurInscription = const CapaciteIndisponible('DB-CRS-08');
      await _monter(tester, depart: _catalogueA2, catalogue: catalogue);
      await _toucher(tester, find.text(_c.choisir));
      await _toucher(tester, find.text(_c.confirmer));
      expect(find.text(_c.envoiIndisponible), findsOneWidget);
      expect(find.text(_c.confirmer), findsNothing);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('aucune classe compatible', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: _catalogueA2,
        catalogue: FauxCatalogueClasses(classes: <ClasseOuverte>[]),
      );
      expect(find.text(_c.aucune), findsOneWidget);
      expect(find.text(_c.aucuneDetail(prenom: 'Eleve A2')), findsOneWidget);
    });

    testWidgets('lecture en echec, puis « Reessayer » relit vraiment', (
      WidgetTester tester,
    ) async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses()
        ..erreurLecture = StateError('lecture fictive en echec');
      await _monter(tester, depart: _catalogueA2, catalogue: catalogue);
      expect(find.byType(CarteClasseOuverte), findsNothing);
      await _toucher(tester, find.text(t.commun.reessayer));
      expect(find.byType(CarteClasseOuverte), findsNWidgets(3));
    });

    testWidgets('profil inconnu du foyer : explique, retour a l Accueil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        depart: '${Routes.tuteurClassesCatalogue}?eleve=autre-foyer',
        catalogue: FauxCatalogueClasses(),
      );
      expect(find.text(_c.eleveInconnuTitre), findsOneWidget);
      expect(find.byType(CarteClasseOuverte), findsNothing);
      await _toucher(tester, find.text(_c.resultat.retourAccueil));
      expect(_lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('hors ligne : bandeau de la coquille, liste lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: _catalogueA2,
        catalogue: FauxCatalogueClasses(),
        horsLigne: true,
      );
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(find.byType(CarteClasseOuverte), findsNWidgets(3));
    });

    testWidgets('bureau 1440 : classes a gauche, precisions a droite', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: _catalogueA2,
        catalogue: FauxCatalogueClasses(),
        taille: const Size(1440, 900),
      );
      final Offset carte = tester.getTopLeft(
        find.byType(CarteClasseOuverte).first,
      );
      final Offset precisions = tester.getTopLeft(
        find.text(_c.precisionsTitre),
      );
      expect(precisions.dx, greaterThan(carte.dx + 400));
      expect((precisions.dy - carte.dy).abs(), lessThan(80));
      expect(tester.takeException(), isNull);
    });
  });

  group('Catalogue : fonctions pures', () {
    test('enseignant : titre rendu, ou prenom seul', () {
      expect(
        enseignantCatalogue(
          const EnseignantSeance(prenom: 'Y', titre: TitreEnseignant.sayyida),
        ),
        '${t.tc.groupe.enseignant.sayyida} Y',
      );
      expect(enseignantCatalogue(const EnseignantSeance(prenom: 'Z')), 'Z');
    });

    test('places : dites seulement quand le serveur les rend et que la '
        'classe est ouverte', () {
      ClasseOuverte classe(int? places, EtatClasseOuverte etat) =>
          ClasseOuverte(
            classeId: 'c',
            libelle: 'C',
            enseignant: const EnseignantSeance(prenom: 'X'),
            etat: etat,
            placesRestantes: places,
          );
      expect(
        placesCatalogue(classe(1, EtatClasseOuverte.ouverte)),
        _c.placeUne,
      );
      expect(
        placesCatalogue(classe(3, EtatClasseOuverte.ouverte)),
        _c.places(nombre: 3),
      );
      expect(placesCatalogue(classe(null, EtatClasseOuverte.ouverte)), isNull);
      expect(placesCatalogue(classe(0, EtatClasseOuverte.ouverte)), isNull);
      expect(placesCatalogue(classe(2, EtatClasseOuverte.complete)), isNull);
    });

    test('etat : une pastille par etat, aucune ne se dit « Ouverte » a '
        'tort', () {
      expect(etatCatalogue(EtatClasseOuverte.ouverte).ton, TonEtat.succes);
      expect(
        etatCatalogue(EtatClasseOuverte.listeAttente).libelle,
        _c.etat.listeAttente,
      );
      expect(
        etatCatalogue(EtatClasseOuverte.complete).libelle,
        _c.etat.complete,
      );
    });
  });
}
