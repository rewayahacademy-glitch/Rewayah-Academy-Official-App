import 'dart:async';

// ESPACE-APPRENDRE (lot 5, 12/11/2026) : l'espace « Apprendre » a trois
// onglets, monte par le VRAI routeur de l'application (jamais une page seule),
// pour l'eleve adulte et pour l'eleve mineur (Interface guidee).
//
// Ce que ces tests prouvent : la barre, les trois onglets et leur ordre, la
// planche (grille, liste, filtres, second rayon, lien externe), le Programme
// (qui voit quoi, les cinq etats), « Mon livret », l'arabe, le texte a 200 %.
// Ce qu'ils ne prouvent pas : le serveur (lecture simulee), un lien reellement
// ouvert hors du navigateur de test, la preuve en production.

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
import 'package:rewayah_academy/core/recrutement/ouvreur_lien.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart' show planFilPour;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
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
import 'package:rewayah_academy/features/apprendre/espace_apprendre_page.dart';
import 'package:rewayah_academy/features/apprendre/onglet_bibliotheque.dart';
import 'package:rewayah_academy/features/apprendre/onglet_livret.dart';
import 'package:rewayah_academy/features/apprendre/onglet_programme.dart';
import 'package:rewayah_academy/features/suivi_eleve/entree_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show lieu, sessionActive, stabiliser;
import '../../support/garde_interface.dart';
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

    testWidgets('liens externes : petite carte avec sa description ; '
        'confirmation avant ouverture', (WidgetTester tester) async {
      final List<Uri> ouverts = <Uri>[];
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        autres: <Override>[
          ouvreurOngletProvider.overrideWithValue((Uri lien) {
            ouverts.add(lien);
            return true;
          }),
        ],
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
      // La feuille de confirmation : rien n'est ouvert avant l'accord.
      expect(ouverts, isEmpty);
      expect(find.text(t.apprendre.bibliotheque.lien.titre), findsOneWidget);
      expect(find.text(t.apprendre.bibliotheque.lien.corps), findsOneWidget);
      // Annuler n'ouvre rien.
      await tester.tap(find.text(t.commun.annuler));
      await stabiliser(tester);
      expect(ouverts, isEmpty);
      // Confirmer ouvre le lien publie par l'academie.
      await _toucher(tester, carte);
      await stabiliser(tester);
      await tester.tap(find.text(t.apprendre.bibliotheque.lien.ouvrir));
      await stabiliser(tester);
      expect(ouverts, <Uri>[Uri.parse('https://exemple.org/lettres')]);
    });

    testWidgets('le mineur tutoie et la confirmation dit que l academie a '
        'publie le lien', (WidgetTester tester) async {
      await monterApprendre(
        tester,
        profil: ProfilApprendre.mineurGuide,
        documents: documentsComplets(),
        autres: <Override>[
          ouvreurOngletProvider.overrideWithValue((Uri _) => true),
        ],
      );
      await _toucher(
        tester,
        find.byKey(PlancheDocuments.cleDocument('lien-lettres')),
      );
      await stabiliser(tester);
      expect(find.text(t.apprendre.bibliotheque.lien.corpsTu), findsOneWidget);
      expect(find.textContaining('académie'), findsWidgets);
    });

    testWidgets('sans navigateur, le lien est copie et la phrase le dit', (
      WidgetTester tester,
    ) async {
      await monterApprendre(
        tester,
        documents: documentsComplets(),
        autres: <Override>[
          ouvreurOngletProvider.overrideWithValue(null),
          // Le repli copie le lien dans le presse-papiers : ici, sa reponse.
          ouvreurLienProvider.overrideWithValue(
            (Uri _) async => ResultatOuverture.copie,
          ),
        ],
      );
      await _toucher(
        tester,
        find.byKey(PlancheDocuments.cleDocument('lien-lettres')),
      );
      await stabiliser(tester);
      await tester.tap(find.text(t.apprendre.bibliotheque.lien.ouvrir));
      await stabiliser(tester);
      expect(find.textContaining('Lien copié'), findsOneWidget);
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

  group('une seule Bibliotheque pour l eleve', () {
    for (final ProfilApprendre profil in ProfilApprendre.values) {
      for (final String adresse in <String>[
        Routes.tcBibliotheque,
        '${Routes.tcBibliotheque}?groupe=g1',
      ]) {
        testWidgets('${profil.name} : $adresse mene a Apprendre', (
          WidgetTester tester,
        ) async {
          final GoRouter routeur = await monterApprendre(
            tester,
            profil: profil,
            documents: documentsComplets(),
            depart: adresse,
          );
          expect(lieu(routeur), Routes.eleveApprendre);
          expect(find.byType(EspaceApprendrePage), findsOneWidget);
          expect(find.byType(OngletBibliotheque), findsOneWidget);
        });
      }
    }

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
