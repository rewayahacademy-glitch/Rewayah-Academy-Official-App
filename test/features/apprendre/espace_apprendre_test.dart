import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/apprendre/affichage_planche.dart';
import 'package:rewayah_academy/core/apprendre/dates_ecole.dart';
import 'package:rewayah_academy/core/apprendre/document_planche.dart';
import 'package:rewayah_academy/core/apprendre/documents_apprendre.dart';
import 'package:rewayah_academy/core/apprendre/planche_documents.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart'
    show MoteurRechercheDomaine, moteursRechercheProvider;
import 'package:rewayah_academy/core/router/fil_ariane.dart' show planFilPour;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart'
    show
        portCatalogueProvider,
        portEtatOfflineProvider,
        portVersionsRessourceProvider;
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart'
    show EchecCatalogue, ReprisLecture;
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart'
    show ResourceVersion;
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart'
    show EtatOffline, PortEtatOffline;
import 'package:rewayah_academy/core/theme/app_typography.dart'
    show AppFontFamily;
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/fil_ariane.dart' show FilAriane;
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart' show StatusPill;
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart'
    show AccueilAdultePage;
import 'package:rewayah_academy/features/apprendre/espace_apprendre_page.dart';
import 'package:rewayah_academy/features/apprendre/onglet_bibliotheque.dart';
import 'package:rewayah_academy/features/apprendre/onglet_livret.dart';
import 'package:rewayah_academy/features/apprendre/onglet_programme.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart'
    show ComptePage;
import 'package:rewayah_academy/features/demo/recherche/moteur_recherche_demo.dart'
    show EntreeCorpusDemo, MoteurRechercheDemo;
import 'package:rewayah_academy/features/foyer/routes_n2_foyer_adulte.dart'
    show RoutesN2;
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart'
    show MaClasseAdultePage;
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/resolveur_cible.dart'
    show cheminPourCible;
import 'package:rewayah_academy/features/suivi_eleve/entree_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_catalogue/bibliotheque_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/carte_ressource.dart'
    show CarteRessource;
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart'
    show DetailRessourcePage;
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show lieu, sessionActive, stabiliser;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart' show hote;
import '../../teaching_core/b/faux/faux_ports_b.dart' show version;
import 'support_apprendre.dart';

/// L'onglet de la barre qui porte [libelle] (la barre flottante n'ecrit que le
/// nom de l'onglet ouvert : les autres se trouvent par leur nom lu).
Finder _onglet(String libelle) => find
    .descendant(
      of: find.byType(NavShell),
      matching: find.bySemanticsLabel(libelle),
    )
    .last;

NavShell _barre(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell));

Finder _section(String libelle) => find.descendant(
  of: find.byKey(EspaceApprendrePage.cleSelecteur),
  matching: find.text(libelle),
);

Future<void> _ouvrirOnglet(WidgetTester tester, String libelle) async {
  // Au telephone, le selecteur se replie en menu (« Bibliotheque » ne tient pas
  // dans un tiers de la largeur) : on l'ouvre, puis on choisit l'entree.
  final Finder direct = _section(libelle);
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct.first);
  } else {
    await tester.tap(find.byKey(EspaceApprendrePage.cleSelecteur));
    await stabiliser(tester);
    await tester.tap(find.text(libelle).last);
  }
  await stabiliser(tester);
}

/// Les puces du filtre par type.
Finder _puce(String libelle) => find.descendant(
  of: find.byType(RangeeFiltres),
  matching: find.text(libelle),
);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
}

/// Les mots d'argent qu'aucun ecran de l'espace ne doit contenir.
final RegExp _argent = RegExp(
  r'(\$|€|prix|payant|acheter|achat|boutique|abonnement|tarif)',
  caseSensitive: false,
);

void expectSansArgent(WidgetTester tester) {
  for (final Text texte in tester.widgetList<Text>(find.byType(Text))) {
    final String contenu = texte.data ?? texte.textSpan?.toPlainText() ?? '';
    expect(
      _argent.hasMatch(contenu),
      isFalse,
      reason: 'mot d argent : $contenu',
    );
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la barre : « Apprendre » pour l adulte et pour le mineur', () {
    testWidgets('adulte : Aujourd hui, Apprendre, Suivi, Profil ; Apprendre '
        'ouvre l espace, onglet Bibliotheque', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        documents: documentsComplets(),
      );
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(
        _barre(tester).destinations.map((Destination d) => d.libelle),
        <String>[
          t.nav.eleve.aujourdhui,
          t.nav.eleve.apprendre,
          t.nav.eleve.suivi,
          t.nav.eleve.profil,
        ],
      );
      expect(_barre(tester).indexActif, 1);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
      expect(find.byType(OngletBibliotheque), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mineur : Apprendre remplace Coran, meme adresse, onglet '
        'Bibliotheque', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
      );
      final List<String> noms = _barre(tester).destinations
          .map((Destination d) => d.libelle)
          .toList();
      expect(noms, contains(t.nav.eleve.apprendre));
      expect(noms, isNot(contains(t.nav.eleve.coran)));
      expect(noms, <String>[
        t.nav.eleve.accueil,
        t.nav.eleve.maClasse,
        t.nav.eleve.apprendre,
        t.nav.eleve.monEspace,
      ]);
      expect(_barre(tester).indexActif, 2);
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(find.byType(OngletBibliotheque), findsOneWidget);
    });

    testWidgets('on y revient en tapant Apprendre depuis Ma classe', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
      );
      await tester.tap(_onglet(t.nav.eleve.maClasse));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveSuivi);
      await tester.tap(_onglet(t.nav.eleve.apprendre));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    testWidgets('toucher Apprendre rend toujours l espace, jamais le dernier '
        'lecteur ouvert', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
      );
      await tester.tap(find.byKey(PlancheDocuments.cleDocument('coran')));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveCoran);
      await tester.tap(_onglet(t.nav.eleve.maClasse));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveSuivi);
      // Sans retour a la racine de la branche, la barre rendrait le Coran.
      await tester.tap(_onglet(t.nav.eleve.apprendre));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    testWidgets('l ancienne adresse /eleve/coran fonctionne encore, dans la '
        'branche Apprendre', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        documents: documentsComplets(),
        depart: Routes.eleveCoran,
      );
      expect(lieu(routeur), Routes.eleveCoran);
      expect(find.byType(EspaceApprendrePage), findsNothing);
      expect(_barre(tester).indexActif, 1);
    });
  });

  group('trois onglets, dans cet ordre, Bibliotheque par defaut', () {
    testWidgets('ordinateur : trois onglets en ligne, dans cet ordre ; le '
        'changement est instantane', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        taille: const Size(1440, 900),
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      final Finder bib = _section(t.apprendre.sections.bibliotheque);
      final Finder pro = _section(t.apprendre.sections.programme);
      final Finder liv = _section(t.apprendre.sections.livret);
      expect(bib, findsOneWidget);
      expect(pro, findsOneWidget);
      expect(liv, findsOneWidget);
      // L'ordre de lecture.
      expect(tester.getTopLeft(bib).dx < tester.getTopLeft(pro).dx, isTrue);
      expect(tester.getTopLeft(pro).dx < tester.getTopLeft(liv).dx, isTrue);
      expect(find.byType(OngletBibliotheque), findsOneWidget);

      // Un seul rendu suffit : le nouvel onglet est deja dans l'arbre.
      await tester.tap(pro);
      await tester.pump();
      expect(find.byType(OngletProgramme), findsOneWidget);
      await tester.tap(liv);
      await tester.pump();
      expect(find.byType(OngletLivret), findsOneWidget);
      await tester.tap(bib);
      await tester.pump();
      expect(find.byType(OngletBibliotheque), findsOneWidget);
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone : le selecteur se replie en menu qui liste les '
        'trois onglets dans l ordre ; le choix est instantane', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      // Le menu montre l'onglet courant.
      expect(_section(t.apprendre.sections.bibliotheque), findsOneWidget);
      await tester.tap(find.byKey(EspaceApprendrePage.cleSelecteur));
      await stabiliser(tester);
      final Finder pro = find.text(t.apprendre.sections.programme);
      final Finder liv = find.text(t.apprendre.sections.livret);
      expect(pro, findsOneWidget);
      expect(liv, findsOneWidget);
      expect(tester.getTopLeft(pro).dy < tester.getTopLeft(liv).dy, isTrue);
      await tester.tap(pro);
      await tester.pump();
      await tester.pump();
      expect(find.byType(OngletProgramme), findsOneWidget);
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('l adresse peut ouvrir un onglet', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
        depart: '${Routes.eleveApprendre}?onglet=programme',
      );
      expect(find.byType(OngletProgramme), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsOneWidget,
      );
    });
  });

  group('Bibliotheque : la planche', () {
    testWidgets('le Coran est un document parmi les autres, en premier, dans '
        '« Documents des cours » ; il ouvre le lecteur existant', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        documents: documentsComplets(),
      );
      final String cours = t.apprendre.bibliotheque.rayonCours;
      expect(find.text(cours), findsOneWidget);
      expect(find.text(t.apprendre.bibliotheque.rayonPlusLoin), findsOneWidget);
      // Le Coran vient en tete, avant le livre de lecture.
      final Finder coran = find.byKey(PlancheDocuments.cleDocument('coran'));
      final Finder livre = find.byKey(
        PlancheDocuments.cleDocument('livre-lecture'),
      );
      expect(coran, findsOneWidget);
      expect(livre, findsOneWidget);
      expect(tester.getTopLeft(coran).dx < tester.getTopLeft(livre).dx, isTrue);
      await tester.tap(coran);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveCoran);
    });

    testWidgets('un document du catalogue ouvre sa fiche existante', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        documents: documentsComplets(),
      );
      await tester.tap(
        find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
      );
      await stabiliser(tester);
      expect(lieu(routeur), cheminFicheDocument('livre-lecture'));
    });

    testWidgets('grille par defaut, puis liste ; le choix est garde sur '
        'l appareil', (WidgetTester tester) async {
      await monterApprendre(tester, documents: documentsComplets());
      final StockagePreferencesMemoire stockage = stockageDeLAppareil(tester);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(EspaceApprendrePage)),
      );
      expect(c.read(affichagePlancheProvider), AffichagePlanche.grille);
      // Grille a 390 : deux tuiles cote a cote.
      final Finder coran = find.byKey(PlancheDocuments.cleDocument('coran'));
      final Finder livre = find.byKey(
        PlancheDocuments.cleDocument('livre-lecture'),
      );
      expect(
        (tester.getTopLeft(coran).dy - tester.getTopLeft(livre).dy).abs(),
        lessThan(1),
      );

      await tester.tap(find.byKey(PlancheDocuments.cleAffichageListe));
      await stabiliser(tester);
      expect(c.read(affichagePlancheProvider), AffichagePlanche.liste);
      expect(stockage.valeurs[clefAffichagePlanche], 'liste');
      // Liste : l'un sous l'autre.
      expect(tester.getTopLeft(livre).dy > tester.getTopLeft(coran).dy, isTrue);
      expect(
        (tester.getTopLeft(coran).dx - tester.getTopLeft(livre).dx).abs(),
        lessThan(1),
      );

      await tester.tap(find.byKey(PlancheDocuments.cleAffichageGrille));
      await stabiliser(tester);
      expect(stockage.valeurs[clefAffichagePlanche], 'grille');
    });

    testWidgets('le choix de l appareil est relu au lancement', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: documentsComplets());
      await preferer(tester, AffichagePlanche.liste);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(EspaceApprendrePage)),
      );
      expect(c.read(affichagePlancheProvider), AffichagePlanche.liste);
      expect(
        tester
                .getTopLeft(
                  find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
                )
                .dy >
            tester
                .getTopLeft(find.byKey(PlancheDocuments.cleDocument('coran')))
                .dy,
        isTrue,
      );
    });

    for (final (String nom, Size taille, int colonnes) cas
        in <(String, Size, int)>[
          ('390', const Size(390, 844), 2),
          ('800', const Size(800, 1000), 3),
          ('1440', const Size(1440, 900), 4),
        ]) {
      testWidgets('grille a ${cas.$1} : ${cas.$3} colonnes', (
        WidgetTester tester,
      ) async {
        await monterApprendre(
          tester,
          taille: cas.$2,
          documents: <DocumentPlanche>[
            coranDemo(),
            for (int i = 1; i <= 8; i++) documentDe('d$i', 'Document $i'),
          ],
        );
        final double haut = tester
            .getTopLeft(find.byKey(PlancheDocuments.cleDocument('coran')))
            .dy;
        int surLaPremiereRangee = 0;
        for (final String id in <String>[
          'coran',
          for (int i = 1; i <= 8; i++) 'd$i',
        ]) {
          final Finder f = find.byKey(PlancheDocuments.cleDocument(id));
          if ((tester.getTopLeft(f).dy - haut).abs() < 1) {
            surLaPremiereRangee++;
          }
        }
        expect(surLaPremiereRangee, cas.$3);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('filtres par type : une puce par type present ; audio ne '
        'laisse que les audios ; tout effacer', (WidgetTester tester) async {
      await monterApprendre(tester, documents: documentsComplets());
      final c = t.apprendre.bibliotheque.type;
      // Les quatre types existent : la rangee montre trois puces puis « Plus ».
      expect(_puce(c.document), findsOneWidget);
      expect(_puce(c.audio), findsOneWidget);
      await tester.tap(_puce(c.audio));
      await stabiliser(tester);
      expect(
        find.byKey(PlancheDocuments.cleDocument('audio-lettres')),
        findsOneWidget,
      );
      expect(find.byKey(PlancheDocuments.cleDocument('coran')), findsNothing);
      expect(
        find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
        findsNothing,
      );
      expect(
        find.byKey(PlancheDocuments.cleDocument('video-priere')),
        findsNothing,
      );
      await tester.tap(find.text(t.commun.listes.toutEffacer));
      await stabiliser(tester);
      expect(find.byKey(PlancheDocuments.cleDocument('coran')), findsOneWidget);
      expect(
        find.byKey(PlancheDocuments.cleDocument('audio-lettres')),
        findsOneWidget,
      );
    });

    testWidgets('un type sans document n a pas de puce ; un seul type : aucun '
        'faux filtre', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: <DocumentPlanche>[coranDemo(), documentDe('d1', 'Livre')],
      );
      // Un seul type present : aucune rangee de filtres, pas de puce
      // « Document » qui ne filtrerait rien, ni de puce d'un type absent.
      expect(find.byType(RangeeFiltres), findsNothing);
      // La bascule grille / liste, elle, est la.
      expect(find.byKey(PlancheDocuments.cleAffichageGrille), findsOneWidget);
    });

    testWidgets('deux types presents : seules leurs puces existent', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: <DocumentPlanche>[
          coranDemo(),
          documentDe('a1', 'Audio un', type: TypeDocumentPlanche.audio),
        ],
      );
      final c = t.apprendre.bibliotheque.type;
      expect(_puce(c.document), findsOneWidget);
      expect(_puce(c.audio), findsOneWidget);
      expect(_puce(c.video), findsNothing);
      expect(_puce(c.lienExterne), findsNothing);
    });

    testWidgets('le second rayon vide dit la verite, sans prix ni mot '
        'd argent', (WidgetTester tester) async {
      await monterApprendre(tester, documents: <DocumentPlanche>[coranDemo()]);
      expect(find.byKey(PlancheDocuments.cleRayonPlusLoinVide), findsOneWidget);
      expect(
        find.text(t.apprendre.bibliotheque.rayonPlusLoinVide),
        findsOneWidget,
      );
      expect(find.text(t.apprendre.bibliotheque.rayonPlusLoin), findsOneWidget);
      expectSansArgent(tester);
    });

    testWidgets('interface anglaise : les rayons du serveur, francais et arabe '
        'seulement, ne passent pas devant l anglais', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          SingleChildScrollView(
            child: PlancheDocuments(
              documents: documentsComplets(),
              rayons: const <RayonBibliotheque>[
                RayonBibliotheque(
                  code: codeRayonCours,
                  titreFr: 'Documents des cours',
                  titreAr: 'وثائق الدروس',
                  ordre: 1,
                ),
                RayonBibliotheque(
                  code: codeRayonPlusLoin,
                  titreFr: 'Pour aller plus loin',
                  titreAr: 'للتعمّق أكثر',
                  ordre: 2,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Documents des cours'), findsNothing);
      expect(find.text('Pour aller plus loin'), findsNothing);
      expect(find.text(t.apprendre.bibliotheque.rayonCours), findsOneWidget);
      expect(find.text(t.apprendre.bibliotheque.rayonPlusLoin), findsOneWidget);
    });

    testWidgets('un document du second rayon s y range, sans prix', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: <DocumentPlanche>[
          coranDemo(),
          documentDe(
            'plus1',
            'Un livre pour aller plus loin',
            rayon: RayonPlanche.pourAllerPlusLoin,
          ),
        ],
      );
      expect(find.byKey(PlancheDocuments.cleRayonPlusLoinVide), findsNothing);
      expect(find.byKey(PlancheDocuments.cleDocument('plus1')), findsOneWidget);
      expectSansArgent(tester);
    });

    testWidgets('liens externes : petite carte avec sa description ; elle '
        's ouvre par SA fiche (la confirmation est celle de la Bibliotheque '
        'une)', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        documents: documentsComplets(),
      );
      final Finder carte = find.byKey(
        PlancheDocuments.cleDocument('lien-lettres'),
      );
      expect(carte, findsOneWidget);
      expect(
        find.text('Une présentation courte des lettres, publiée par Rewayah.'),
        findsOneWidget,
      );
      await _toucher(tester, carte);
      await stabiliser(tester);
      expect(lieu(routeur), cheminFicheDocument('lien-lettres'));
    });

    testWidgets('liste : un lien montre sa description en entier', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: documentsComplets());
      await preferer(tester, AffichagePlanche.liste);
      expect(
        find.text('Une présentation courte des lettres, publiée par Rewayah.'),
        findsOneWidget,
      );
      expect(
        find.text('La voix du directeur, lettre par lettre.'),
        findsOneWidget,
      );
    });

    testWidgets('etat vide : ni document ni Coran', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: <DocumentPlanche>[]);
      expect(
        find.text(t.apprendre.bibliotheque.rayonCoursVide.message),
        findsOneWidget,
      );
      expect(find.byKey(PlancheDocuments.cleRayonPlusLoinVide), findsOneWidget);
      expect(find.byKey(PlancheDocuments.cleAffichageGrille), findsNothing);
    });

    testWidgets('etat de chargement : un squelette', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: () => Completer<List<DocumentPlanche>>().future,
      );
      expect(find.byKey(ClesBibliotheque.chargement), findsOneWidget);
    });

    testWidgets('etat d erreur : « Reessayer » relit', (
      WidgetTester tester,
    ) async {
      int appels = 0;
      await monterApprendre(
        tester,
        documents: () async {
          appels++;
          if (appels == 1) throw StateError('catalogue');
          return documentsComplets();
        },
      );
      expect(find.byKey(ClesBibliotheque.erreur), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.indisponible.message), findsOneWidget);
      await tester.tap(find.text(t.tc.bibliotheque.indisponible.action));
      await stabiliser(tester);
      expect(find.byKey(ClesBibliotheque.erreur), findsNothing);
      expect(find.byKey(PlancheDocuments.cleDocument('coran')), findsOneWidget);
    });

    testWidgets('hors ligne : l echec dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        horsLigne: true,
        documents: () async => throw StateError('hors ligne'),
      );
      expect(find.byKey(ClesBibliotheque.erreur), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.indisponible.message), findsOneWidget);
    });

    testWidgets('un seul bouton plein, aucune carte collee', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: documentsComplets());
      await preferer(tester, AffichagePlanche.liste);
      verifierUnSeulBoutonPlein(tester);
      final int n = verifierAucuneCarteCollee(
        tester,
        estCarte: (Widget w) => w is AppCard,
      );
      expect(n, greaterThan(2));
    });
  });

  group('arabe de contenu dans la police du Coran', () {
    testWidgets('le titre arabe du Coran, sur sa vignette, est en UthmanicHafs '
        '(decision du directeur, 13/11)', (WidgetTester tester) async {
      await monterApprendre(tester, documents: documentsComplets());
      final Text titre = tester.widget<Text>(
        find.byKey(const ValueKey<String>('couverture-coran-titre')),
      );
      expect(titre.style?.fontFamily, AppFontFamily.arabeMushaf);
      // L'arabe d'interface, lui, ne change pas : le libelle de la barre
      // reste en police d'interface.
      expect(AppFontFamily.arabeMushaf, isNot(AppFontFamily.arabeInterface));
    });
  });

  group('arabe de contenu : titres et descriptions de la planche', () {
    const String titreAr = 'تجويد الحروف';
    const String descAr = 'درس قصير عن مخارج الحروف';
    final List<DocumentPlanche> documents = <DocumentPlanche>[
      coranDemo(),
      documentDe('ar', titreAr, description: descAr),
      documentDe(
        'fr',
        'Le livre de lecture',
        description: 'Les premiers mots.',
      ),
      documentDe(
        'lien-ar',
        'موقع مفيد للحروف',
        type: TypeDocumentPlanche.lienExterne,
        description: 'صفحة قصيرة عن الحروف',
      ),
    ];

    String? police(WidgetTester tester, String texte) =>
        tester.widget<Text>(find.text(texte)).style?.fontFamily;

    for (final AffichagePlanche affichage in AffichagePlanche.values) {
      testWidgets('${affichage.name} : un titre et une description arabes '
          'sortent en police du Coran, le francais non', (
        WidgetTester tester,
      ) async {
        await monterApprendre(tester, documents: documents);
        await preferer(tester, affichage);
        expect(police(tester, titreAr), AppFontFamily.arabeMushaf);
        expect(police(tester, descAr), AppFontFamily.arabeMushaf);
        expect(
          police(tester, 'Le livre de lecture'),
          isNot(AppFontFamily.arabeMushaf),
        );
        expect(
          police(tester, 'Les premiers mots.'),
          isNot(AppFontFamily.arabeMushaf),
        );
        // Le titre arabe se lit de droite a gauche, meme dans une interface
        // francaise.
        expect(
          Directionality.of(tester.element(find.text(titreAr))),
          TextDirection.rtl,
        );
        // Le titre francais garde le sens de l'interface.
        expect(
          Directionality.of(tester.element(find.text('Le livre de lecture'))),
          TextDirection.ltr,
        );
        // La carte du lien : meme regle.
        expect(police(tester, 'موقع مفيد للحروف'), AppFontFamily.arabeMushaf);
        expect(
          police(tester, 'صفحة قصيرة عن الحروف'),
          AppFontFamily.arabeMushaf,
        );
      });
    }

    testWidgets('l arabe d interface ne change pas : le nom du type, repli '
        'quand la description manque, reste en police d interface', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: <DocumentPlanche>[documentDe('sans', 'Sans description')],
      );
      expect(
        police(tester, libelleTypeDocument(TypeDocumentPlanche.document)),
        isNot(AppFontFamily.arabeMushaf),
      );
    });
  });

  group('« Continuer » et l\'etat hors ligne (le port du lot 3)', () {
    LibraryResource ressource(
      String id, {
      TypeRessource type = TypeRessource.pdf,
      bool publiee = true,
    }) => LibraryResource(
      id: id,
      title: 'Titre $id',
      shortTitle: id,
      resourceType: type,
      language: 'fr',
      category: 'lecture',
      accessPolicy: PolitiqueAcces.publique,
      offlinePolicy: PolitiqueOffline.jamais,
      currentVersionId: publiee ? 'v-$id' : null,
    );

    ReprisLecture reprise(LibraryResource r) => ReprisLecture(
      ressource: r,
      position: ContentPosition.page(resourceId: r.id, page: 3),
      vueLeUtc: DateTime.utc(2026, 11, 12, 10),
    );

    List<Override> catalogue(
      List<LibraryResource> ressources, {
      LibraryResource? aReprendre,
      Map<String, EtatOffline> etats = const <String, EtatOffline>{},
    }) => <Override>[
      portCatalogueProvider.overrideWithValue(
        CatalogueLocal(
          ressources: ressources,
          reprise: aReprendre == null ? null : reprise(aReprendre),
        ),
      ),
      portEtatOfflineProvider.overrideWithValue(_EtatsFixes(etats)),
    ];

    testWidgets('un document a reprendre : « Continuer » en tete, avec la '
        'carte de la Bibliotheque une ; il s\'ouvre par sa fiche', (
      WidgetTester tester,
    ) async {
      final LibraryResource r = ressource('livre');
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: catalogue(<LibraryResource>[r], aReprendre: r),
      );
      final Finder bloc = find.byKey(ClesBibliotheque.continuer);
      expect(bloc, findsOneWidget);
      expect(
        find.descendant(
          of: bloc,
          matching: find.text(t.tc.bibliotheque.sections.continuer),
        ),
        findsOneWidget,
      );
      final Finder carte = find.descendant(
        of: bloc,
        matching: find.byType(CarteRessource),
      );
      expect(carte, findsOneWidget);
      // En tete : au-dessus de la planche.
      expect(
        tester.getTopLeft(bloc).dy,
        lessThan(tester.getTopLeft(find.byType(PlancheDocuments)).dy),
      );
      // Un mineur : ni date ni duree (le moment de la derniere vue n'est
      // jamais montre).
      expect(find.textContaining('2026'), findsNothing);
      expect(find.textContaining('12/11'), findsNothing);
      await tester.tap(carte);
      await stabiliser(tester);
      expect(lieu(routeur), cheminFicheDocument('livre'));
    });

    testWidgets('rien a reprendre : pas de « Continuer »', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: catalogue(<LibraryResource>[ressource('livre')]),
      );
      expect(find.byKey(ClesBibliotheque.continuer), findsNothing);
    });

    testWidgets('lecture de la reprise en echec : la Bibliotheque s\'affiche '
        'sans elle', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: <Override>[
          portCatalogueProvider.overrideWithValue(
            _CatalogueRepriseEnPanne(<LibraryResource>[ressource('livre')]),
          ),
        ],
      );
      expect(find.byKey(ClesBibliotheque.continuer), findsNothing);
      expect(find.byKey(PlancheDocuments.cleDocument('livre')), findsOneWidget);
    });

    testWidgets('le Coran a reprendre s\'ouvre dans son lecteur', (
      WidgetTester tester,
    ) async {
      final LibraryResource coran = ressource(
        'coran-cat',
        type: TypeRessource.quran,
      );
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: catalogue(<LibraryResource>[coran], aReprendre: coran),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(ClesBibliotheque.continuer),
          matching: find.byType(CarteRessource),
        ),
      );
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveCoran);
    });

    testWidgets('hors ligne, rien de garde sur l\'appareil : la carte dit '
        'pourquoi et ne s\'ouvre pas', (WidgetTester tester) async {
      final LibraryResource r = ressource('livre');
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        horsLigne: true,
        autres: catalogue(<LibraryResource>[r], aReprendre: r),
      );
      expect(
        find.text(t.tc.bibliotheque.message.horsLigneNonTelecharge),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(ClesBibliotheque.continuer),
          matching: find.byType(CarteRessource),
        ),
        warnIfMissed: false,
      );
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
    });

    testWidgets('hors ligne, document telecharge : « Continuer » s\'ouvre', (
      WidgetTester tester,
    ) async {
      final LibraryResource r = ressource('livre');
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        horsLigne: true,
        autres: catalogue(
          <LibraryResource>[r],
          aReprendre: r,
          etats: <String, EtatOffline>{'livre': EtatOffline.telecharge},
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(ClesBibliotheque.continuer),
          matching: find.byType(CarteRessource),
        ),
      );
      await stabiliser(tester);
      expect(lieu(routeur), cheminFicheDocument('livre'));
    });

    testWidgets('l\'etat hors ligne d\'un document garde sur l\'appareil : '
        'un mot et une pastille sur sa tuile (grille et liste) ; rien pour '
        'les autres', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        autres: catalogue(
          <LibraryResource>[ressource('garde'), ressource('autre')],
          etats: <String, EtatOffline>{
            'garde': EtatOffline.telecharge,
            'autre': EtatOffline.aTelecharger,
          },
        ),
      );
      final Finder garde = find.byKey(PlancheDocuments.cleDocument('garde'));
      final Finder autre = find.byKey(PlancheDocuments.cleDocument('autre'));
      for (final AffichagePlanche affichage in AffichagePlanche.values) {
        await preferer(tester, affichage);
        expect(
          find.descendant(
            of: garde,
            matching: find.text(t.tc.bibliotheque.offline.telecharge),
          ),
          findsOneWidget,
          reason: affichage.name,
        );
        expect(
          find.descendant(of: garde, matching: find.byType(StatusPill)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: autre, matching: find.byType(StatusPill)),
          findsNothing,
          reason: affichage.name,
        );
      }
    });
  });

  group(
    'confirmation de sortie d\'un lien externe : la variante de l\'Interface '
    'guidee',
    () {
      const LibraryResource lien = LibraryResource(
        id: 'lien',
        title: 'Un site de reference',
        shortTitle: 'Un site',
        resourceType: TypeRessource.lienExterne,
        language: 'fr',
        category: 'lecture',
        accessPolicy: PolitiqueAcces.publique,
        offlinePolicy: PolitiqueOffline.jamais,
        description: 'Un site pour aller plus loin.',
        lienExterne: 'https://exemple.org/page',
        currentVersionId: 'v-lien',
      );

      Future<void> ouvrirLaConfirmation(
        WidgetTester tester,
        ProfilApprendre profil,
      ) async {
        await monterApprendre(
          tester,
          profil: profil,
          depart: cheminFicheDocument('lien'),
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(
              CatalogueLocal(ressources: <LibraryResource>[lien]),
            ),
            portVersionsRessourceProvider.overrideWithValue(
              VersionsLocales(
                parRessource: <String, List<ResourceVersion>>{
                  'lien': <ResourceVersion>[
                    version(id: 'v-lien', resourceId: 'lien'),
                  ],
                },
              ),
            ),
            ouvreurOngletProvider.overrideWithValue((Uri _) => true),
          ],
        );
        final Finder ouvrir = find.byKey(
          const ValueKey<String>('rendu-ouvrir-lien'),
        );
        await tester.ensureVisible(ouvrir);
        await tester.tap(ouvrir);
        await stabiliser(tester);
        expect(
          find.byKey(const ValueKey<String>('rendu-lien-confirmation')),
          findsOneWidget,
        );
      }

      testWidgets('l\'enfant en Interface guidee est tutoye', (
        WidgetTester tester,
      ) async {
        await ouvrirLaConfirmation(tester, ProfilApprendre.mineurGuide);
        expect(
          find.text(t.tc.bibliotheque.rendu.confirmerPhraseTu),
          findsOneWidget,
        );
        expect(
          find.text(t.tc.bibliotheque.rendu.confirmerPhrase),
          findsNothing,
        );
        expect(find.textContaining('Tu pourras'), findsOneWidget);
        expect(find.textContaining('Vous'), findsNothing);
      });

      testWidgets(
        'l\'adulte garde la phrase des autres espaces (vouvoiement)',
        (WidgetTester tester) async {
          await ouvrirLaConfirmation(tester, ProfilApprendre.adulte);
          expect(
            find.text(t.tc.bibliotheque.rendu.confirmerPhrase),
            findsOneWidget,
          );
          expect(
            find.text(t.tc.bibliotheque.rendu.confirmerPhraseTu),
            findsNothing,
          );
        },
      );

      testWidgets('en arabe aussi : la variante de l\'Interface guidee', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await ouvrirLaConfirmation(tester, ProfilApprendre.mineurGuide);
        expect(
          find.text(t.tc.bibliotheque.rendu.confirmerPhraseTu),
          findsOneWidget,
        );
        expect(
          find.text(t.tc.bibliotheque.rendu.confirmerPhrase),
          findsNothing,
        );
      });
    },
  );

  group('adaptateur du catalogue (types et descriptions du lot 3)', () {
    LibraryResource ressource(
      String id,
      TypeRessource type, {
      String? description,
      String? lien,
      bool vignette = false,
      bool publiee = true,
      String rayon = codeRayonCours,
    }) => LibraryResource(
      id: id,
      title: 'Titre $id',
      shortTitle: id,
      resourceType: type,
      language: 'fr',
      category: 'lecture',
      accessPolicy: PolitiqueAcces.publique,
      offlinePolicy: PolitiqueOffline.jamais,
      description: description,
      lienExterne: lien,
      aVignette: vignette,
      rayon: rayon,
      currentVersionId: publiee ? 'v-$id' : null,
    );

    test('types, description, vignette, ouverture ; Coran du catalogue et '
        'ressources non publiees ecartes ; le Coran de la planche en tete', () {
      final List<DocumentPlanche> d = documentsDepuisCatalogue(
        <LibraryResource>[
          ressource('pdf', TypeRessource.pdf, vignette: true),
          ressource('voix', TypeRessource.audio, description: 'La voix.'),
          ressource('film', TypeRessource.video),
          ressource(
            'site',
            TypeRessource.lienExterne,
            description: 'Un site.',
            lien: 'https://exemple.org/page',
          ),
          ressource('coran-catalogue', TypeRessource.quran),
          ressource('brouillon', TypeRessource.pdf, publiee: false),
        ],
        avecCoran: true,
      );
      expect(d.map((DocumentPlanche x) => x.id).toList(), <String>[
        idDocumentCoran,
        // A `ordre` egal (ici tous a 0) : titre puis identifiant (ordre total,
        // commit 1a141b98) ; titres « Titre film » < « Titre pdf » < … .
        'film',
        'pdf',
        'site',
        'voix',
      ]);
      DocumentPlanche de(String id) =>
          d.firstWhere((DocumentPlanche x) => x.id == id);
      expect(de('pdf').type, TypeDocumentPlanche.document);
      expect(de('pdf').aVignetteDeposee, isTrue);
      expect(de('pdf').description, isNull);
      expect(de('voix').type, TypeDocumentPlanche.audio);
      expect(de('voix').description, 'La voix.');
      expect(de('film').type, TypeDocumentPlanche.video);
      expect(de('site').type, TypeDocumentPlanche.lienExterne);
      expect(de('site').description, 'Un site.');
      // Un lien s'ouvre par SA fiche (le chemin de la Bibliotheque une : la
      // fiche relit l'adresse et demande la confirmation), jamais l'adresse
      // directe.
      expect(
        (de('site').ouverture as OuvrirDansLApplication).chemin,
        cheminFicheDocument('site'),
      );
      expect(de('film').rayon, RayonPlanche.documentsDesCours);
    });

    test('rayon et ordre viennent du serveur : `plus_loin` va au second rayon, '
        'chaque rayon suit `ordre` croissant', () {
      LibraryResource r(
        String id, {
        String rayon = codeRayonCours,
        int ordre = 0,
      }) => LibraryResource(
        id: id,
        title: id,
        shortTitle: id,
        resourceType: TypeRessource.pdf,
        language: 'fr',
        category: 'lecture',
        accessPolicy: PolitiqueAcces.publique,
        offlinePolicy: PolitiqueOffline.jamais,
        rayon: rayon,
        ordre: ordre,
        currentVersionId: 'v-$id',
      );
      final List<DocumentPlanche> d = documentsDepuisCatalogue(
        <LibraryResource>[
          r('c3', ordre: 3),
          r('loin2', rayon: codeRayonPlusLoin, ordre: 2),
          r('c1', ordre: 1),
          r('loin1', rayon: codeRayonPlusLoin, ordre: 1),
          r('c2', ordre: 2),
        ],
        avecCoran: false,
      );
      List<String> de(RayonPlanche rayon) => <String>[
        for (final DocumentPlanche x in d)
          if (x.rayon == rayon) x.id,
      ];
      expect(de(RayonPlanche.documentsDesCours), <String>['c1', 'c2', 'c3']);
      expect(de(RayonPlanche.pourAllerPlusLoin), <String>['loin1', 'loin2']);
    });

    test('a `ordre` egal : par titre puis par identifiant, quel que soit '
        'l\'ordre ou le serveur rend la liste (total et deterministe)', () {
      LibraryResource r(String id, String titre, int ordre) => LibraryResource(
        id: id,
        title: titre,
        shortTitle: titre,
        resourceType: TypeRessource.pdf,
        language: 'fr',
        category: 'lecture',
        accessPolicy: PolitiqueAcces.publique,
        offlinePolicy: PolitiqueOffline.jamais,
        ordre: ordre,
        currentVersionId: 'v-$id',
      );
      List<String> ids(List<LibraryResource> l) => <String>[
        for (final DocumentPlanche d in documentsDepuisCatalogue(
          l,
          avecCoran: false,
        ))
          d.id,
      ];
      // 100 documents au meme `ordre` (au-dela de la taille ou un tri non
      // stable melange), plus un premier ; rendus a l'envers.
      final List<LibraryResource> ressources = <LibraryResource>[
        for (int i = 99; i >= 0; i--)
          r('id$i', 'Titre ${i.toString().padLeft(3, '0')}', 5),
        r('premier', 'Zzz', 1),
      ];
      final List<String> attendu = <String>[
        'premier',
        for (int i = 0; i < 100; i++) 'id$i',
      ];
      expect(ids(ressources), attendu);
      // Le meme resultat, quel que soit l'ordre d'arrivee.
      expect(ids(ressources.reversed.toList()), attendu);
      // Meme ordre et meme titre : l'identifiant departage.
      expect(
        ids(<LibraryResource>[
          r('b', 'Meme titre', 2),
          r('a', 'Meme titre', 2),
          r('c', 'Meme titre', 2),
        ]),
        <String>['a', 'b', 'c'],
      );
    });

    test('cheminFicheDocument n\'encode pas deux fois : `%` et `/` dans un '
        'identifiant', () {
      // `/` reste dans le segment (jamais un autre chemin), `%` est encode
      // une fois, et le chemin se relit identique.
      for (final String id in <String>[
        'a/b',
        'a%2Fb',
        '100%',
        'a b',
        'x%y/z',
      ]) {
        final Uri uri = Uri.parse(cheminFicheDocument(id));
        expect(uri.pathSegments, <String>[
          'tc',
          'bibliotheque',
          id,
        ], reason: id);
        expect(uri.queryParameters['retour'], Routes.eleveApprendre);
      }
      expect(
        cheminFicheDocument('a/b'),
        '/tc/bibliotheque/a%2Fb?retour=%2Feleve%2Fapprendre',
      );
      expect(
        cheminFicheDocument('100%'),
        '/tc/bibliotheque/100%25?retour=%2Feleve%2Fapprendre',
      );
    });

    testWidgets('les intitules des rayons sont ceux du serveur '
        '(PortCatalogue.rayons())', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: <Override>[
          portCatalogueProvider.overrideWithValue(
            _CatalogueAvecRayons(
              <LibraryResource>[
                ressource('cours1', TypeRessource.pdf),
                ressource('loin1', TypeRessource.pdf, rayon: codeRayonPlusLoin),
              ],
              const <RayonBibliotheque>[
                RayonBibliotheque(
                  code: codeRayonCours,
                  titreFr: 'Mes cours du serveur',
                  titreAr: 'دروسي',
                  ordre: 1,
                ),
                RayonBibliotheque(
                  code: codeRayonPlusLoin,
                  titreFr: 'Plus loin du serveur',
                  titreAr: 'أبعد',
                  ordre: 2,
                ),
              ],
            ),
          ),
        ],
      );
      for (final (String titre, RayonPlanche rayon) cas
          in <(String, RayonPlanche)>[
            ('Mes cours du serveur', RayonPlanche.documentsDesCours),
            ('Plus loin du serveur', RayonPlanche.pourAllerPlusLoin),
          ]) {
        expect(
          find.descendant(
            of: find.byKey(PlancheDocuments.cleRayon(cas.$2)),
            matching: find.text(cas.$1),
          ),
          findsOneWidget,
          reason: cas.$1,
        );
      }
      // Chaque document est dans le rayon que le serveur lui donne.
      expect(
        find.descendant(
          of: find.byKey(
            PlancheDocuments.cleRayon(RayonPlanche.pourAllerPlusLoin),
          ),
          matching: find.byKey(PlancheDocuments.cleDocument('loin1')),
        ),
        findsOneWidget,
      );
      expect(find.text(t.apprendre.bibliotheque.rayonCours), findsNothing);
    });

    testWidgets('intitules illisibles (rayons() echoue) : repli sur le texte '
        'ecrit, jamais un trou', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: <Override>[
          portCatalogueProvider.overrideWithValue(
            _CatalogueRayonsEnPanne(<LibraryResource>[
              ressource('cours1', TypeRessource.pdf),
              ressource('loin1', TypeRessource.pdf, rayon: codeRayonPlusLoin),
            ]),
          ),
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(
            PlancheDocuments.cleRayon(RayonPlanche.documentsDesCours),
          ),
          matching: find.text(t.apprendre.bibliotheque.rayonCours),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            PlancheDocuments.cleRayon(RayonPlanche.pourAllerPlusLoin),
          ),
          matching: find.text(t.apprendre.bibliotheque.rayonPlusLoin),
        ),
        findsOneWidget,
      );
    });

    testWidgets('par le vrai adaptateur : les quatre types se filtrent, le '
        'lien est une petite carte', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        autres: <Override>[
          portCatalogueProvider.overrideWithValue(
            CatalogueLocal(
              ressources: <LibraryResource>[
                ressource('pdf', TypeRessource.pdf),
                ressource('voix', TypeRessource.audio, description: 'La voix.'),
                ressource('film', TypeRessource.video),
                ressource(
                  'site',
                  TypeRessource.lienExterne,
                  description: 'Un site.',
                ),
              ],
            ),
          ),
        ],
      );
      for (final String id in <String>['pdf', 'voix', 'film', 'site']) {
        expect(
          find.byKey(PlancheDocuments.cleDocument(id)),
          findsOneWidget,
          reason: id,
        );
      }
      expect(find.text('La voix.'), findsOneWidget);
      expect(find.text('Un site.'), findsOneWidget);
      // Les quatre types sont presents : la rangee de filtres est offerte.
      expect(find.byType(RangeeFiltres), findsOneWidget);
    });
  });

  group('une seule Bibliotheque pour l eleve', () {
    // Le role `student` (le mineur, et l'adulte dont la barre est celle de
    // l'eleve) n'a qu'une Bibliotheque, celle d'Apprendre.
    for (final (String nom, ProfilApprendre profil, AppRole? role) cas
        in <(String, ProfilApprendre, AppRole?)>[
          ('mineur guide', ProfilApprendre.mineurGuide, null),
          ('adulte, role eleve', ProfilApprendre.adulte, AppRole.student),
        ]) {
      for (final String adresse in <String>[
        Routes.tcBibliotheque,
        '${Routes.tcBibliotheque}?groupe=g1',
      ]) {
        testWidgets('${cas.$1} : $adresse mene a Apprendre', (
          WidgetTester tester,
        ) async {
          final GoRouter routeur = await monterApprendre(
            tester,
            profil: cas.$2,
            role: cas.$3,
            documents: documentsComplets(),
            depart: adresse,
          );
          // La classe d'ou il vient voyage avec lui (`?groupe=`).
          expect(
            lieu(routeur),
            adresse.contains('groupe=')
                ? '${Routes.eleveApprendre}?groupe=g1'
                : Routes.eleveApprendre,
          );
          expect(find.byType(EspaceApprendrePage), findsOneWidget);
          expect(find.byType(OngletBibliotheque), findsOneWidget);
        });
      }
    }

    // Revue de l'architecte (13/11, IMPORTANT A) : un compte TUTEUR qui est
    // aussi eleve autonome garde sa Bibliotheque dans l'espace tuteur ; la
    // redirection ne joue que pour l'espace eleve.
    for (final String adresse in <String>[
      Routes.tcBibliotheque,
      '${Routes.tcBibliotheque}?groupe=g1',
    ]) {
      testWidgets('double casquette, espace TUTEUR : $adresse reste la '
          'Bibliotheque du tuteur', (WidgetTester tester) async {
        final GoRouter routeur = await monterApprendre(
          tester,
          profil: ProfilApprendre.adulte,
          documents: documentsComplets(),
          depart: adresse,
        );
        expect(lieu(routeur), adresse);
        expect(find.byType(EspaceApprendrePage), findsNothing);
        expect(find.byType(BibliothequePage), findsOneWidget);
      });
    }

    // Contre-lecture (13/11) : les pages communes (le Compte, l'espace de la
    // classe, le retour par defaut d'une fiche) sont-elles dans l'espace ELEVE
    // du compte a double casquette ? Mesure par le vrai routeur : NON. Le
    // Profil de la barre de l'eleve (`/compte`) et `/tc/groupes/*` sont
    // renvoyes par `deciderRedirection` vers l'espace TUTEUR (`/tuteur/*`, sa
    // barre) ; c'est la que sa Bibliotheque d'origine vit, et elle y reste.
    testWidgets('double casquette : le Profil de la barre eleve mene au Compte '
        'du TUTEUR (`/tuteur/compte`), pas a la page commune `ComptePage` '
        'dont la ligne Bibliotheque menait a l\'ancienne liste', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: Routes.eleveApprendre,
        documents: documentsComplets(),
      );
      await tester.tap(_onglet(t.nav.eleve.profil));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurCompte);
      expect(find.byType(ComptePage), findsNothing);
    });

    testWidgets('double casquette : l\'espace de la classe (`/tc/groupes/*`) '
        'est celui du tuteur, pas de l\'eleve', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: '${Routes.tcGroupes}/g1',
      );
      expect(lieu(routeur), startsWith(Routes.tuteurClasses));
    });

    testWidgets('double casquette, fiche ouverte par un lien direct (sans '
        'retour) : le retour par defaut est la Bibliotheque du TUTEUR', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: RoutesTcB.versRessource('livre-lecture'),
        documents: documentsComplets(),
      );
      await tester.tap(find.byType(DisqueRetour).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tcBibliotheque);
      expect(find.byType(BibliothequePage), findsOneWidget);
    });

    // Contre-lecture finale (13/11) : la RECHERCHE de l'espace eleve de ce
    // compte ouvrait la fiche SANS `retour` : le retour tombait sur l'ancienne
    // liste. Une fiche trouvee dans l'espace eleve porte `?retour=Apprendre`.
    test('un support trouve dans l\'espace eleve ouvre sa fiche avec le retour '
        'vers Apprendre ; la famille garde le chemin d\'origine', () {
      const CibleRecherche cible = CibleRecherche(
        kind: KindCible.support,
        reference: 'livre-lecture',
      );
      for (final EspaceRecherche espace in <EspaceRecherche>[
        EspaceRecherche.eleve,
        EspaceRecherche.eleveGuide,
      ]) {
        expect(
          cheminPourCible(cible, espace),
          cheminFicheDocument('livre-lecture'),
          reason: espace.name,
        );
      }
      expect(
        cheminPourCible(cible, EspaceRecherche.famille),
        RoutesTcB.versRessource('livre-lecture'),
      );
    });

    testWidgets('double casquette, recherche dans l\'espace ELEVE : support, '
        'fiche, disque retour = Apprendre', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: Routes.rechercheAvec(espace: 'eleve'),
        documents: documentsComplets(),
        autres: <Override>[
          moteursRechercheProvider.overrideWithValue(<MoteurRechercheDomaine>[
            MoteurRechercheDemo(
              domaine: DomaineRecherche.supports,
              corpus: <EntreeCorpusDemo>[
                EntreeCorpusDemo(
                  type: TypeResultat.support,
                  reference: 'livre-lecture',
                  titre: 'Le livre de lecture Rewayah',
                  cible: const CibleRecherche(
                    kind: KindCible.support,
                    reference: 'livre-lecture',
                  ),
                ),
              ],
              espaces: const <EspaceRecherche>{EspaceRecherche.eleve},
            ),
          ]),
          portCatalogueProvider.overrideWithValue(
            CatalogueLocal(
              ressources: <LibraryResource>[
                const LibraryResource(
                  id: 'livre-lecture',
                  title: 'Le livre de lecture Rewayah',
                  shortTitle: 'Le livre',
                  resourceType: TypeRessource.pdf,
                  language: 'fr',
                  category: 'lecture',
                  accessPolicy: PolitiqueAcces.publique,
                  offlinePolicy: PolitiqueOffline.jamais,
                  currentVersionId: 'v1',
                ),
              ],
            ),
          ),
        ],
      );
      await tester.enterText(find.byKey(cleChampRecherche), 'livre');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      final Finder resultat = find.text('Le livre de lecture Rewayah');
      expect(resultat, findsWidgets);
      await tester.tap(resultat.first);
      await stabiliser(tester);
      expect(find.byType(DetailRessourcePage), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    // Les entrees de l'espace ELEVE de ce compte (Ma classe adulte, Accueil
    // adulte) menent directement a Apprendre, avec la classe : on appelle le
    // geste que la route de production donne a la page.
    testWidgets('double casquette, espace ELEVE : « Voir tout » de Ma classe '
        'mene a Apprendre, avec la classe', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: RoutesN2.eleveAdulteClasse,
      );
      expect(lieu(routeur), RoutesN2.eleveAdulteClasse);
      final MaClasseAdultePage page = tester.widget<MaClasseAdultePage>(
        find.byType(MaClasseAdultePage),
      );
      page.onVoirRessources!('g1');
      await stabiliser(tester);
      expect(lieu(routeur), '${Routes.eleveApprendre}?groupe=g1');
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    testWidgets('double casquette, espace ELEVE : « Voir tout » de l Accueil '
        'adulte mene a Apprendre, avec la classe', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        depart: Routes.eleveAdulte,
      );
      expect(lieu(routeur), Routes.eleveAdulte);
      final AccueilAdultePage page = tester.widget<AccueilAdultePage>(
        find.byType(AccueilAdultePage),
      );
      page.onVoirRessources!('g1');
      await stabiliser(tester);
      expect(lieu(routeur), '${Routes.eleveApprendre}?groupe=g1');
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    group('« Pour cette classe » (la rubrique de l ancienne liste)', () {
      LibraryResource ressource(String id, String titre) => LibraryResource(
        id: id,
        title: titre,
        shortTitle: titre,
        resourceType: TypeRessource.pdf,
        language: 'fr',
        category: 'lecture',
        accessPolicy: PolitiqueAcces.groupeAssigne,
        offlinePolicy: PolitiqueOffline.jamais,
        currentVersionId: 'v-$id',
      );
      final LibraryResource devoir = ressource(
        'devoir-g1',
        'Le cahier de la classe',
      );
      final LibraryResource autre = ressource('autre', 'Un autre document');

      testWidgets('arrivee de la classe : la rubrique est la, en tete, et le '
          'document n y est montre qu une fois', (WidgetTester tester) async {
        await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          depart: '${Routes.tcBibliotheque}?groupe=g1',
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(
              CatalogueLocal(
                ressources: <LibraryResource>[devoir, autre],
                assignationsParGroupe: <String, List<String>>{
                  'g1': <String>['devoir-g1'],
                },
              ),
            ),
          ],
        );
        final Finder rayon = find.byKey(
          PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse),
        );
        expect(rayon, findsOneWidget);
        expect(
          find.descendant(
            of: rayon,
            matching: find.text(t.apprendre.bibliotheque.rayonClasse),
          ),
          findsOneWidget,
        );
        // En tete : au-dessus du rayon des cours.
        expect(
          tester.getTopLeft(rayon).dy,
          lessThan(
            tester
                .getTopLeft(
                  find.byKey(
                    PlancheDocuments.cleRayon(RayonPlanche.documentsDesCours),
                  ),
                )
                .dy,
          ),
        );
        // Une seule fois, dans la rubrique de la classe.
        expect(
          find.byKey(PlancheDocuments.cleDocument('devoir-g1')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: rayon,
            matching: find.byKey(PlancheDocuments.cleDocument('devoir-g1')),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(PlancheDocuments.cleDocument('autre')),
          findsOneWidget,
        );
      });

      testWidgets('sans classe dans l adresse : pas de rubrique', (
        WidgetTester tester,
      ) async {
        await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(
              CatalogueLocal(
                ressources: <LibraryResource>[devoir, autre],
                assignationsParGroupe: <String, List<String>>{
                  'g1': <String>['devoir-g1'],
                },
              ),
            ),
          ],
        );
        expect(
          find.byKey(PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse)),
          findsNothing,
        );
        expect(
          find.byKey(PlancheDocuments.cleDocument('devoir-g1')),
          findsOneWidget,
        );
      });

      testWidgets('classe sans document : la rubrique disparait, elle ne dit '
          'pas vide', (WidgetTester tester) async {
        await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          depart: '${Routes.tcBibliotheque}?groupe=g2',
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(
              CatalogueLocal(ressources: <LibraryResource>[devoir, autre]),
            ),
          ],
        );
        expect(
          find.byKey(PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse)),
          findsNothing,
        );
        expect(
          find.byKey(PlancheDocuments.cleDocument('autre')),
          findsOneWidget,
        );
      });

      // Une PANNE (reseau, serveur) : la rubrique le DIT, avec Reessayer ; le
      // reste de la Bibliotheque tient.
      for (final bool horsLigne in <bool>[false, true]) {
        testWidgets(
          'panne${horsLigne ? ' (hors ligne)' : ''} : la rubrique le DIT '
          '(jamais « rien »), avec Reessayer, et le reste tient',
          (WidgetTester tester) async {
            await monterApprendre(
              tester,
              profil: ProfilApprendre.mineurGuide,
              depart: '${Routes.tcBibliotheque}?groupe=g1',
              horsLigne: horsLigne,
              autres: <Override>[
                portCatalogueProvider.overrideWithValue(
                  _CatalogueClasseEnPanne(<LibraryResource>[devoir, autre]),
                ),
              ],
            );
            expect(find.byKey(ClesBibliotheque.classeErreur), findsOneWidget);
            expect(
              find.descendant(
                of: find.byKey(ClesBibliotheque.classeErreur),
                matching: find.text(t.apprendre.bibliotheque.rayonClasse),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: find.byKey(ClesBibliotheque.classeErreur),
                matching: find.text(
                  t.apprendre.bibliotheque.classeErreur.message,
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.byKey(
                PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse),
              ),
              findsNothing,
            );
            expect(
              find.byKey(PlancheDocuments.cleDocument('devoir-g1')),
              findsOneWidget,
            );
            expect(find.byKey(ClesBibliotheque.erreur), findsNothing);
          },
        );
      }

      // Un REFUS du serveur (42501 : une classe qui n'est pas la sienne, dans
      // une adresse falsifiee) : la rubrique n'existe pas, sans phrase ni
      // Reessayer ; le reste tient.
      for (final String raison in raisonsRefusClasse) {
        testWidgets('refus du serveur ($raison) : aucune rubrique, aucune '
            'phrase, aucun Reessayer, le reste tient', (
          WidgetTester tester,
        ) async {
          await monterApprendre(
            tester,
            profil: ProfilApprendre.mineurGuide,
            depart: '${Routes.tcBibliotheque}?groupe=pas-la-mienne',
            autres: <Override>[
              portCatalogueProvider.overrideWithValue(
                _CatalogueClasseRefusee(<LibraryResource>[
                  devoir,
                  autre,
                ], raison),
              ),
            ],
          );
          expect(find.byKey(ClesBibliotheque.classeErreur), findsNothing);
          expect(find.byKey(ClesBibliotheque.classeChargement), findsNothing);
          expect(
            find.byKey(PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse)),
            findsNothing,
          );
          expect(find.text(t.apprendre.bibliotheque.rayonClasse), findsNothing);
          expect(find.text(t.commun.reessayer), findsNothing);
          expect(
            find.byKey(PlancheDocuments.cleDocument('devoir-g1')),
            findsOneWidget,
          );
          expect(find.byKey(ClesBibliotheque.erreur), findsNothing);
        });
      }

      testWidgets('lecture refusee : « Reessayer » relit la rubrique', (
        WidgetTester tester,
      ) async {
        final _CatalogueQuiReussitAuSecondEssai catalogue =
            _CatalogueQuiReussitAuSecondEssai(<LibraryResource>[devoir]);
        await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          depart: '${Routes.tcBibliotheque}?groupe=g1',
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(catalogue),
          ],
        );
        expect(find.byKey(ClesBibliotheque.classeErreur), findsOneWidget);
        final Finder reessayer = find.descendant(
          of: find.byKey(ClesBibliotheque.classeErreur),
          matching: find.text(t.commun.reessayer),
        );
        await tester.ensureVisible(reessayer);
        await tester.tap(reessayer);
        await stabiliser(tester);
        expect(find.byKey(ClesBibliotheque.classeErreur), findsNothing);
        expect(
          find.byKey(PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse)),
          findsOneWidget,
        );
      });

      testWidgets('pendant la lecture : sa place est reservee (squelette sous '
          'son titre), le reste s affiche deja', (WidgetTester tester) async {
        final Completer<List<LibraryResource>> attente =
            Completer<List<LibraryResource>>();
        final GoRouter routeur = await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          depart: '${Routes.tcBibliotheque}?groupe=g1',
          documents: documentsComplets(),
          autres: <Override>[
            portCatalogueProvider.overrideWithValue(
              _CatalogueEnAttente(attente.future),
            ),
          ],
        );
        expect(lieu(routeur), '${Routes.eleveApprendre}?groupe=g1');
        expect(find.byKey(ClesBibliotheque.classeChargement), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(ClesBibliotheque.classeChargement),
            matching: find.text(t.apprendre.bibliotheque.rayonClasse),
          ),
          findsOneWidget,
        );
        // Le reste s'affiche pendant l'attente.
        expect(
          find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
          findsOneWidget,
        );
        attente.complete(<LibraryResource>[devoir]);
        await stabiliser(tester);
        expect(find.byKey(ClesBibliotheque.classeChargement), findsNothing);
        expect(
          find.byKey(PlancheDocuments.cleRayon(RayonPlanche.pourCetteClasse)),
          findsOneWidget,
        );
      });
    });

    group('retour depuis une fiche (navigateur, bouton du telephone)', () {
      testWidgets('retour systeme depuis une fiche ouverte d Apprendre : on '
          'revient a Apprendre, jamais a l ancienne liste', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          documents: documentsComplets(),
        );
        await tester.tap(
          find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
        );
        await stabiliser(tester);
        expect(lieu(routeur), cheminFicheDocument('livre-lecture'));
        await tester.binding.handlePopRoute();
        await stabiliser(tester);
        expect(lieu(routeur), Routes.eleveApprendre);
        expect(find.byType(EspaceApprendrePage), findsOneWidget);
      });

      testWidgets('retour systeme depuis une fiche ouverte par un lien direct '
          '(sans historique) : Apprendre aussi', (WidgetTester tester) async {
        final GoRouter routeur = await monterApprendre(
          tester,
          profil: ProfilApprendre.mineurGuide,
          documents: documentsComplets(),
          depart: RoutesTcB.versRessource('livre-lecture'),
        );
        await tester.binding.handlePopRoute();
        await stabiliser(tester);
        expect(lieu(routeur), Routes.eleveApprendre);
        expect(find.byType(EspaceApprendrePage), findsOneWidget);
      });
    });

    testWidgets('le tuteur garde la Bibliotheque d origine', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        autonome: false,
        depart: Routes.tcBibliotheque,
      );
      expect(lieu(routeur), Routes.tcBibliotheque);
      expect(find.byType(EspaceApprendrePage), findsNothing);
    });

    testWidgets('la fiche d un document reste ouverte a l eleve, et son '
        'disque retour ramene a Apprendre', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
      );
      await tester.tap(
        find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
      );
      await stabiliser(tester);
      expect(lieu(routeur), cheminFicheDocument('livre-lecture'));
      await tester.tap(find.byType(DisqueRetour).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });

    testWidgets('sans `retour`, le retour par defaut de la fiche ramene aussi '
        'a Apprendre', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
        depart: RoutesTcB.versRessource('livre-lecture'),
      );
      await tester.tap(find.byType(DisqueRetour).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
    });

    testWidgets('Ma classe, ligne Bibliotheque : Apprendre, puis le retour '
        'd une fiche y revient', (WidgetTester tester) async {
      final GoRouter routeur = await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
        depart: Routes.eleveSuivi,
      );
      final Finder ligne = find.byKey(EntreeBibliothequeMaClasse.ligneKey);
      expect(ligne, findsOneWidget);
      await tester.tap(ligne);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
      await tester.tap(
        find.byKey(PlancheDocuments.cleDocument('livre-lecture')),
      );
      await stabiliser(tester);
      await tester.tap(find.byType(DisqueRetour).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveApprendre);
    });

    testWidgets('grand ecran : le fil de la fiche dit Apprendre > '
        'Bibliotheque, pas Compte', (WidgetTester tester) async {
      final SessionState session = sessionActive(
        AppRole.student,
        mode: InterfaceMode.enfant,
      );
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        taille: const Size(1440, 900),
        documents: documentsComplets(),
        planFil: planFilPour(session),
        depart: cheminFicheDocument('livre-lecture'),
      );
      expect(
        find.byKey(FilAriane.cleSegment(Routes.eleveApprendre)),
        findsOneWidget,
      );
      expect(
        find.byKey(FilAriane.cleSegment(Routes.tcBibliotheque)),
        findsOneWidget,
      );
      expect(find.byKey(FilAriane.cleSegment(Routes.compte)), findsNothing);
      // Le fil mene a Apprendre : un toucher, et l'on y est.
      await tester.tap(find.byKey(FilAriane.cleSegment(Routes.eleveApprendre)));
      await stabiliser(tester);
      expect(find.byType(EspaceApprendrePage), findsOneWidget);
    });
  });

  group('l adaptateur du catalogue existant', () {
    test('la fiche d un document vise la route existante', () {
      final Uri adresse = Uri.parse(cheminFicheDocument('abc'));
      expect(adresse.path, RoutesTcB.versRessource('abc'));
      // Le retour de la fiche ramene a l'espace Apprendre.
      expect(adresse.queryParameters['retour'], Routes.eleveApprendre);
    });

    testWidgets('vrai adaptateur, catalogue vide : le Coran seul, premier '
        'rayon, et le second rayon vide', (WidgetTester tester) async {
      await monterApprendre(tester);
      expect(find.byKey(PlancheDocuments.cleDocument('coran')), findsOneWidget);
      expect(find.byKey(PlancheDocuments.cleRayonPlusLoinVide), findsOneWidget);
      // Le Coran sans description inventee : seule l'edition est ecrite.
      expect(find.text(t.apprendre.bibliotheque.coran.edition), findsOneWidget);
      expectSansArgent(tester);
    });

    testWidgets('le mineur a aussi le Coran dans sa Bibliotheque', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, profil: ProfilApprendre.mineurGuide);
      expect(find.byKey(PlancheDocuments.cleDocument('coran')), findsOneWidget);
    });
  });

  group('Programme', () {
    // L'onglet reutilise l'ecran « Ma progression » de main (hub : le chemin
    // n'est dessine qu'a un endroit) et y ajoute « Dates de l'academie ».
    const Key carte = ValueKey<String>('suivi-pedagogique');
    const Key chemin = ValueKey<String>('suivi-pedagogique-chemin');
    Key etape(int ordre) => ValueKey<String>('suivi-pedagogique-etape-$ordre');
    const Key erreur = ValueKey<String>('suivi-pedagogique-erreur');
    const Key chargement = ValueKey<String>('suivi-pedagogique-chargement');

    Future<void> sur(
      WidgetTester tester, {
      required ProfilApprendre profil,
      required LectureSuivi suivi,
      PortDatesEcole? dates,
      Size taille = const Size(390, 844),
    }) async {
      await monterApprendre(
        tester,
        profil: profil,
        taille: taille,
        documents: documentsComplets(),
        suivi: suivi,
        dates: dates,
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
    }

    testWidgets('adulte : l ecran Ma progression, une seule fois, avec le '
        'chemin entier, les objectifs et les dates', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      final s = t.suiviPedagogique;
      // Un seul ecran du chemin : celui de main, jamais un second dessin.
      expect(find.byKey(carte), findsOneWidget);
      expect(find.byKey(chemin), findsOneWidget);
      expect(find.text(s.chemin(niveau: 'Les bases')), findsOneWidget);
      for (int ordre = 1; ordre <= 4; ordre++) {
        expect(find.byKey(etape(ordre)), findsOneWidget);
      }
      expect(find.text(s.matierePrincipale), findsOneWidget);
      expect(find.text(s.matiereSecondaire), findsOneWidget);
      // Les dates, parce que le serveur dit eleve_voit_dates.
      expect(find.text(s.aFinirAvant), findsOneWidget);
      expect(find.text(s.depuis), findsOneWidget);
      expect(find.text(s.dureePrevue), findsOneWidget);
      expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsOneWidget);
      // Une etape passee dit « Etape precedente », jamais « Etape validee ».
      expect(find.textContaining(s.etapeFranchie), findsOneWidget);
      expect(
        find.textContaining(RegExp('valid', caseSensitive: false)),
        findsNWidgets(1),
        reason: 'seul le titre « Sourates des bases validees » (lot Sourates)',
      );
      expect(find.text(s.sourates), findsOneWidget);
      expect(
        find.textContaining('Lit une lettre avec chacune des trois voyelles'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('mineur de 10 ans et plus : ses dates, avec le chemin et les '
        'dates de l ecole', (WidgetTester tester) async {
      await sur(
        tester,
        profil: ProfilApprendre.mineurGuide,
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      final s = t.suiviPedagogique;
      expect(find.text(s.aFinirAvant), findsOneWidget);
      expect(find.byKey(ClesProgramme.datesEcole), findsOneWidget);
      expect(find.byKey(etape(3)), findsOneWidget);
    });

    testWidgets('mineur de 6 a 9 ans : aucune date, aucune duree, aucun '
        'rythme, pas de section des dates de l ecole', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.mineurGuide,
        suivi: SuiviLu(lectureDemo(dates: false)),
        // Meme si le calendrier publiait des dates, la section n'existe pas.
        dates: DatesEcoleFixes(<DateEcole>[
          DateEcole(
            jour: DateTime(2026, 12, 20),
            genre: GenreDateEcole.evaluation,
          ),
        ]),
      );
      final s = t.suiviPedagogique;
      for (final String interdit in <String>[
        s.aFinirAvant,
        s.depuis,
        s.dureePrevue,
        s.rythme,
        s.horizonNiveau(niveau: 'Les bases'),
        t.apprendre.programme.datesEcole,
      ]) {
        expect(find.text(interdit), findsNothing, reason: interdit);
      }
      expect(find.byKey(ClesProgramme.datesEcole), findsNothing);
      expect(find.textContaining('semaines'), findsNothing);
      expect(find.textContaining(RegExp(r'20\d\d')), findsNothing);
      // Il voit quand meme son niveau, son etape et le chemin.
      expect(find.byKey(carte), findsOneWidget);
      expect(find.byKey(etape(1)), findsOneWidget);
      expect(find.text(s.matierePrincipale), findsOneWidget);
    });

    testWidgets('Dates de l ecole : « rien de publie » dit la verite', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      expect(find.text(t.apprendre.programme.datesEcole), findsOneWidget);
      expect(find.byKey(ClesProgramme.datesEcoleVide), findsOneWidget);
      expect(find.text(t.apprendre.programme.datesEcoleVide), findsOneWidget);
    });

    testWidgets('Dates de l ecole : ce que le calendrier publiera', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: SuiviLu(lectureDemo(dates: true)),
        dates: DatesEcoleFixes(<DateEcole>[
          DateEcole(
            jour: DateTime(2026, 12, 20),
            genre: GenreDateEcole.rencontre,
          ),
        ]),
      );
      expect(find.byKey(ClesProgramme.datesEcoleVide), findsNothing);
      expect(find.text(t.apprendre.programme.genre.rencontre), findsOneWidget);
    });

    testWidgets('en attente de l entretien de lecture : tel que le serveur le '
        'dit, a l adulte', (WidgetTester tester) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: const SuiviLu(<String, Object?>{
          'attente': 'entretien_de_lecture',
        }),
      );
      expect(find.text(t.suiviPedagogique.attenteEntretien), findsOneWidget);
    });

    testWidgets('le mineur est tutoye en attente de l entretien', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.mineurGuide,
        suivi: const SuiviLu(<String, Object?>{
          'attente': 'entretien_de_lecture',
        }),
      );
      expect(find.text(t.suiviPedagogique.attenteEntretienTu), findsOneWidget);
    });

    testWidgets('que des sourates, aucune etape : la carte le dit au lieu de '
        'rester seule', (WidgetTester tester) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: const SuiviLu(<String, Object?>{
          'sourates': <String, Object?>{
            'sourates_validees': 0,
            'sourates_total': 17,
          },
        }),
      );
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique-sourates')),
        findsOneWidget,
      );
      expect(find.byKey(ClesProgramme.sansEtape), findsOneWidget);
      expect(find.text(t.apprendre.programme.sansEtape), findsOneWidget);
      expect(find.byKey(chemin), findsNothing);
    });

    const Object sourates = <String, Object?>{
      'sourates': <String, Object?>{
        'sourates_validees': 0,
        'sourates_total': 17,
      },
    };

    testWidgets('sans etape, le programme de l academie s affiche, avec la '
        'phrase de la place', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviLu(sourates),
        programme: const ProgrammePublieDemo(),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(ClesProgramme.programmePublie), findsOneWidget);
      expect(find.byKey(ClesProgramme.votrePlace), findsOneWidget);
      expect(find.text(t.apprendre.programme.votrePlace), findsOneWidget);
      expect(find.text('Les bases'), findsOneWidget);
      expect(find.text('Reconnaître les lettres'), findsOneWidget);
      expect(find.text('Lire avec les voyelles'), findsOneWidget);
      expect(find.byKey(ClesProgramme.sansEtape), findsNothing);
      // Aucune duree quand le serveur n'en rend pas.
      expect(find.textContaining('9'), findsNothing);
    });

    testWidgets('les durees rendues par le serveur s affichent telles '
        'quelles', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviLu(sourates),
        programme: const ProgrammePublieDemo(avecDurees: true),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(
        find.textContaining(
          LibellesGroupe.insecable(
            t.suiviPedagogique.dureesEtape(prevue: '9', limite: '12'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('programme illisible : l echec le dit et Reessayer relit', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviLu(sourates),
        programme: const ProgrammePublieDemo(echec: true),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.text(t.suiviPedagogique.erreur), findsWidgets);
      expect(find.text(t.commun.reessayer), findsWidgets);
      expect(find.byKey(ClesProgramme.programmePublie), findsNothing);
    });

    testWidgets('programme publie, mais une etape propre : le chemin de la '
        'carte, pas de doublon', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
        programme: const ProgrammePublieDemo(),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(ClesProgramme.programmePublie), findsNothing);
      expect(find.byKey(ClesProgramme.votrePlace), findsNothing);
    });

    testWidgets('une etape publiee : aucun message « sans etape »', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      expect(find.byKey(ClesProgramme.sansEtape), findsNothing);
    });

    testWidgets('pas encore de classe : l etape apparaitra a l entree en '
        'classe', (WidgetTester tester) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: const SuiviLu(null),
      );
      expect(find.byKey(ClesProgramme.vide), findsOneWidget);
      expect(find.text(t.apprendre.programme.vide), findsOneWidget);
      expect(find.byKey(chemin), findsNothing);
      expect(find.byKey(ClesProgramme.datesEcole), findsNothing);
    });

    testWidgets('la phrase « pas encore de classe » ne se dit que si la carte '
        'n a vraiment rien a montrer : un jalon saisi, un niveau declare ou '
        'une sourate la font taire', (WidgetTester tester) async {
      Future<void> avec(
        WidgetTester tester, {
        required LectureSuivi suivi,
        required ProgressionEleve famille,
      }) async {
        await monterApprendre(
          tester,
          documents: documentsComplets(),
          suivi: suivi,
          autres: <Override>[
            progressionFamilleLueProvider.overrideWith(
              (Ref _, String id) async => famille,
            ),
          ],
        );
        await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      }

      await avec(
        tester,
        suivi: const SuiviLu(null),
        famille: const ProgressionEleve(
          eleveId: 'p-guardian',
          jalons: <String>['Il lit les voyelles'],
        ),
      );
      expect(find.byKey(ClesProgramme.vide), findsNothing);
      expect(find.text('Il lit les voyelles'), findsOneWidget);
    });

    testWidgets('un niveau declare fait taire la phrase aussi', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviLu(null),
        autres: <Override>[
          progressionFamilleLueProvider.overrideWith(
            (Ref _, String id) async =>
                ProgressionEleve(eleveId: id, niveauHumain: 'Lit les lettres'),
          ),
        ],
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(ClesProgramme.vide), findsNothing);
      expect(find.text('Lit les lettres'), findsOneWidget);
    });

    testWidgets('des sourates seules font aussi taire la phrase', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviLu(<String, Object?>{
          'etape': null,
          'sourates': <String, Object?>{
            'sourates_validees': 2,
            'sourates_total': 17,
          },
        }),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(ClesProgramme.vide), findsNothing);
      expect(find.text(t.suiviPedagogique.sourates), findsOneWidget);
    });

    testWidgets('6 a 9 ans : le dernier jalon est lu SANS sa date, dans l '
        'onglet comme dans la carte', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: false)),
        autres: <Override>[
          portProgressionFamilleProvider.overrideWithValue(_FamilleAvecJalon()),
        ],
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(find.textContaining('Lit chaque lettre'), findsOneWidget);
      // Aucune date, nulle part dans l'onglet : ni celle du jalon, ni les
      // dates de l'academie (la section n'existe pas).
      expect(find.textContaining('2026'), findsNothing);
      expect(find.byKey(ClesProgramme.datesEcole), findsNothing);
    });

    testWidgets('des 10 ans ou adulte : la date du jalon est lue', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
        autres: <Override>[
          portProgressionFamilleProvider.overrideWithValue(_FamilleAvecJalon()),
        ],
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('reponse SANS `eleve_voit_dates` (serveur d avant le socle) : '
        'la section « Dates de l academie » n existe pas, quel que soit le '
        'mode d interface (refus par defaut)', (WidgetTester tester) async {
      final Map<String, Object?> ancienne = lectureDemo(dates: true)
        ..remove('eleve_voit_dates');
      // Un eleve en presentation STANDARD : le mode ne decide rien.
      await monterApprendre(
        tester,
        profil: ProfilApprendre.adulte,
        role: AppRole.student,
        autonome: false,
        documents: documentsComplets(),
        suivi: SuiviLu(ancienne),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byType(OngletProgramme), findsOneWidget);
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      // Ce que l'onglet ajoute (les dates de l'academie) : refus par defaut.
      // La carte du lot 1 qu'il embarque (`CarteSuiviPedagogique`) garde, elle,
      // sa regle d'avant le socle quand le drapeau manque (`!guidee`) : un
      // eleve en presentation standard y lirait les dates de l'etape. C'est
      // le lot 1 qui la change (signale a l'architecte).
      expect(find.byKey(ClesProgramme.datesEcole), findsNothing);
    });

    testWidgets('sans port branche : meme etat vide honnete', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: documentsComplets());
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(ClesProgramme.vide), findsOneWidget);
    });

    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviEnAttente(),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(chargement), findsOneWidget);
    });

    testWidgets('erreur : la phrase et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: const SuiviEnEchec(),
      );
      expect(find.byKey(erreur), findsOneWidget);
      expect(find.text(t.suiviPedagogique.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('hors ligne : la lecture en echec le dit', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        suivi: const SuiviEnEchec(),
        horsLigne: true,
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(find.byKey(erreur), findsOneWidget);
      expect(find.text(t.suiviPedagogique.erreur), findsOneWidget);
    });

    testWidgets('aucun bouton plein : la page se lit', (
      WidgetTester tester,
    ) async {
      await sur(
        tester,
        profil: ProfilApprendre.adulte,
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is ActionPrincipale && w.niveau == NiveauAction.principale,
        ),
        findsNothing,
      );
    });
  });

  group('Mon livret', () {
    testWidgets('etat vide honnete, au vouvoiement pour l adulte', (
      WidgetTester tester,
    ) async {
      await monterApprendre(tester, documents: documentsComplets());
      await _ouvrirOnglet(tester, t.apprendre.sections.livret);
      expect(find.byKey(cleLivretVide), findsOneWidget);
      expect(find.text(t.apprendre.livret.vide), findsOneWidget);
      expect(
        find.text(
          'Vos résultats, vos bilans et vos attestations apparaîtront ici',
        ),
        findsOneWidget,
      );
    });

    testWidgets('au tutoiement pour l enfant', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.livret);
      expect(
        find.text(
          'Tes résultats, tes bilans et tes attestations apparaîtront ici',
        ),
        findsOneWidget,
      );
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('arabe, de droite a gauche', () {
    testWidgets('les trois onglets, la planche et le Programme', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterApprendre(
        tester,
        taille: const Size(1440, 900),
        direction: TextDirection.rtl,
        documents: documentsComplets(),
        suivi: SuiviLu(lectureDemo(dates: true)),
      );
      expect(t.apprendre.sections.livret, 'سجلّي');
      expect(find.text('سجلّي'), findsOneWidget);
      expect(find.text(t.apprendre.bibliotheque.rayonCours), findsOneWidget);
      expect(find.text('وثائق الدروس'), findsOneWidget);
      expect(find.text('للتعمّق أكثر'), findsOneWidget);
      // L'ordre de lecture est miroite : la Bibliotheque est a droite.
      final Finder bib = _section(t.apprendre.sections.bibliotheque);
      final Finder pro = _section(t.apprendre.sections.programme);
      expect(tester.getTopLeft(bib).dx > tester.getTopLeft(pro).dx, isTrue);
      await _ouvrirOnglet(tester, t.apprendre.sections.programme);
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsOneWidget,
      );
      await _ouvrirOnglet(tester, t.apprendre.sections.livret);
      expect(find.byKey(cleLivretVide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la barre du mineur dit « التعلم »', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        direction: TextDirection.rtl,
        documents: documentsComplets(),
      );
      expect(t.nav.eleve.apprendre, 'التعلم');
      expect(
        _barre(tester).destinations.map((Destination d) => d.libelle),
        contains('التعلم'),
      );
    });
  });

  group('lisible partout : 320, texte a 200 %, clair, sombre, 1440', () {
    for (final ProfilApprendre profil in ProfilApprendre.values) {
      for (final (String nom, Size taille, double echelle, ThemeMode theme) cas
          in <(String, Size, double, ThemeMode)>[
            ('320 x2 clair', const Size(320, 800), 2, ThemeMode.light),
            ('390 sombre', const Size(390, 844), 1, ThemeMode.dark),
            ('1440 clair', const Size(1440, 900), 1, ThemeMode.light),
            ('1440 sombre', const Size(1440, 900), 1, ThemeMode.dark),
          ]) {
        testWidgets(
          '${profil.name} ${cas.$1} : trois onglets sans debordement',
          (WidgetTester tester) async {
            await monterApprendre(
              tester,
              profil: profil,
              taille: cas.$2,
              echelle: cas.$3,
              theme: cas.$4,
              documents: documentsComplets(),
              suivi: SuiviLu(lectureDemo(dates: true)),
            );
            expect(tester.takeException(), isNull);
            for (final String onglet in <String>[
              t.apprendre.sections.programme,
              t.apprendre.sections.livret,
              t.apprendre.sections.bibliotheque,
            ]) {
              await _ouvrirOnglet(tester, onglet);
              expect(tester.takeException(), isNull, reason: onglet);
            }
            // La liste a 200 % : rien ne deborde non plus.
            await tester.tap(find.byKey(PlancheDocuments.cleAffichageListe));
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}

/// Le niveau declare et le dernier jalon, avec sa date (ce que rendrait un
/// adaptateur).
class _FamilleAvecJalon implements PortProgressionFamille {
  @override
  Future<ProgressionEleve> progression(String eleveId) async =>
      ProgressionEleve(
        eleveId: eleveId,
        niveauHumain: 'Les lettres',
        jalons: const <String>['Lit chaque lettre'],
        dernierJalonLe: DateTime(2026, 10, 14),
      );
}

/// Un catalogue dont la lecture par classe attend qu'on la libere.
class _CatalogueEnAttente extends CatalogueLocal {
  _CatalogueEnAttente(this._attente);

  final Future<List<LibraryResource>> _attente;

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) => _attente;
}

/// Un catalogue dont la lecture par classe echoue une fois, puis reussit.
class _CatalogueQuiReussitAuSecondEssai extends CatalogueLocal {
  _CatalogueQuiReussitAuSecondEssai(this._lues);

  final List<LibraryResource> _lues;
  int _appels = 0;

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async {
    _appels++;
    if (_appels == 1) throw const EchecCatalogue('lecture refusee');
    return _lues;
  }
}

/// Un catalogue dont la lecture par classe tombe en PANNE (rien du serveur :
/// reseau coupe), le reste se lisant.
class _CatalogueClasseEnPanne extends CatalogueLocal {
  _CatalogueClasseEnPanne(List<LibraryResource> ressources)
    : super(ressources: ressources);

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) =>
      Future<List<LibraryResource>>.error(const EchecCatalogue('hors ligne'));
}

/// Un catalogue dont la lecture par classe est REFUSEE par le serveur (42501).
class _CatalogueClasseRefusee extends CatalogueLocal {
  _CatalogueClasseRefusee(List<LibraryResource> ressources, this._raison)
    : super(ressources: ressources);

  final String _raison;

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) =>
      Future<List<LibraryResource>>.error(EchecCatalogue(_raison));
}

/// Un catalogue qui donne ses propres rayons (donnee du serveur).
class _CatalogueAvecRayons extends CatalogueLocal {
  _CatalogueAvecRayons(List<LibraryResource> ressources, this._rayons)
    : super(ressources: ressources);

  final List<RayonBibliotheque> _rayons;

  @override
  Future<List<RayonBibliotheque>> rayons() async => _rayons;
}

/// Un catalogue dont la lecture des rayons echoue (les ressources se lisent).
class _CatalogueRayonsEnPanne extends CatalogueLocal {
  _CatalogueRayonsEnPanne(List<LibraryResource> ressources)
    : super(ressources: ressources);

  @override
  Future<List<RayonBibliotheque>> rayons() =>
      Future<List<RayonBibliotheque>>.error(const EchecCatalogue('hors ligne'));
}

/// Un port d'etat hors ligne qui rend des etats fixes (aucun par defaut :
/// `aTelecharger`).
class _EtatsFixes implements PortEtatOffline {
  _EtatsFixes(this._etats);

  final Map<String, EtatOffline> _etats;

  @override
  Future<EtatOffline> etatDe(String resourceId) async =>
      _etats[resourceId] ?? EtatOffline.aTelecharger;

  @override
  Stream<EtatOffline> suivre(String resourceId) async* {
    yield await etatDe(resourceId);
  }

  @override
  Future<void> demanderTelechargement(String resourceId) async {}

  @override
  Future<void> libererCache(String resourceId) async {}
}

/// Un catalogue dont la lecture de la reprise echoue (le reste se lit).
class _CatalogueRepriseEnPanne extends CatalogueLocal {
  _CatalogueRepriseEnPanne(List<LibraryResource> ressources)
    : super(ressources: ressources);

  @override
  Future<ReprisLecture?> derniereLecture() =>
      Future<ReprisLecture?>.error(const EchecCatalogue('hors ligne'));
}
