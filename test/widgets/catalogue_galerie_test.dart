import 'dart:io';

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/features/_dev/galerie/catalogue_galerie.dart';

import '../support/harnais.dart';

/// La liste des composants du catalogue, recopiee du document.
///
/// **Elle est ecrite ici et non deduite du code**, et c'est tout l'interet : si
/// on la construisait en listant `lib/core/widgets/`, elle suivrait le code au
/// lieu de le contredire, et un composant ajoute sans entree de galerie ne
/// serait jamais signale.
///
/// Source : `docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md`, sections 1 et 2.
const List<String> composantsDuCatalogue = <String>[
  // Section 2 : les douze P0.
  'PageShell',
  'NavShell',
  'AppCard',
  'SectionHeader',
  'StatusPill',
  'Skeleton',
  'LocalFeedback',
  'StatTile',
  'SignalRow',
  'AppBottomSheet',
  'ConfirmDestructive',
  'ChildCard',
  // Section 1 : ce qui existait deja, plus la grille et la page de parcours.
  'Pressable',
  'BentoTile',
  'AvatarTile',
  'AvatarNom',
  'AudioLabel',
  'PermanentNotice',
  'PinPad',
  'EmptyState',
  'OfflineBanner',
  'ChoiceCardGroup',
  'ActionPrincipale',
  'GrilleSemaine',
  'PageParcours',
  // Section 2 : ce que la refonte a produit en chemin, hors liste d'origine.
  'MarquePage',
  // K-55 (revue du directeur du 01/10) : jamais de cartes collees.
  'PileCartes',
  'CarteGroupee',
  'CarteLignes',
  // Section 2 : le P1 que le lot R3 produit.
  'TimelineRow',
  // Section 2 : les deux que le lot ADM-04 produit. `DataCollection` etait au
  // catalogue en P1 depuis la refonte et n'avait jamais ete construit, faute
  // d'ecran dont la forme naturelle soit un tableau. `FilterPill` n'y etait
  // pas : inscrit comme `MarquePage` avant lui, parce qu'un composant hors
  // catalogue est un composant que personne ne relit.
  'DataCollection',
  'FilterPill',
  'SettingRow',
  'ScheduleOption',
  // Section 2 : la coquille que le lot N3 produit. Elle n'etait pas a la liste
  // d'origine : la refonte n'avait prevu qu'un gabarit de page, et la salle a
  // montre qu'il en manquait un second, pour les ecrans sans page -- ni titre,
  // ni gouttiere, ni colonne bornee.
  'PageImmersive',
  // Les deux que ETATS-BTN-1 et NAV-FLECHES-1 (revue du directeur 01-02/10)
  // produisent : la commande ronde de la salle et la barre precedent / suivant.
  'CommandeSalle',
  'BarrePrecedentSuivant',
  // Section 2 : le composant d'etat que le lot N4 produit. Il porte a lui seul
  // deux invariants de l'etape 5 -- J3, un etat indisponible se dit « inconnu »
  // et jamais « absent », et J7, une couleur seule ne represente jamais un etat
  // critique -- ce qui est exactement la raison de le mettre au catalogue :
  // ecrit dans un ecran, ces deux regles seraient rejouees de memoire au
  // suivant.
  'LignePresence',
  // Section 2 : le composant que le lot N5 produit. Deux decisions y sont
  // enfermees plutot que recopiees dans l'ecran de lecture : le cercle est
  // DESSINE et non tire du glyphe U+06DD, qu'Unicode reserve pourtant a cet
  // usage exact mais que toutes les polices ne portent pas ; et il est MUET
  // pour les technologies d'assistance, parce qu'un numero de verset est un
  // repere de mise en page et non du texte a epeler au milieu d'une phrase.
  'RosaceVerset',
  // Section 2 : le composant que le lot AGT-01 produit (ADR-025). Il ne protege
  // rien -- la lecture seule vient des privileges du role Postgres `agent_ro`,
  // et un agent recevrait le meme refus en rejouant la requete a la main.
  // C'est precisement pour cela qu'il est au catalogue : un composant dont on
  // pourrait croire qu'il applique une regle est un composant qu'il faut
  // relire.
  'BandeauObservation',
  // Section 2 : les cinq composants d'administration que les lots `IA-01`,
  // `ADM-08` et Pedagogie ont produits sans passer par le catalogue.
  // `AdminShell` a ete inscrit a part, apres les quatre autres : c'est le seul
  // a etre une coquille complete, donc le seul dont les axes « 200 pour cent
  // de texte » et « mode enfant » peuvent reellement deborder -- le grouper
  // avec les petits aurait rendu un echec impossible a attribuer.
  'AdminShell',
  'MenuActions',
  'MenuFiltre',
  'SelecteurNiveauProgramme',
  'SousNavigationDomaine',
  // ONGLETS-1 (revue du directeur, 01/10/2026) : le selecteur de section
  // unique, qui remplace les rangees d'onglets et de pilules qui defilent.
  'SelecteurSection',
  // Les composants partages du chantier Tuteur V1 (phase 0c1 du 24/09/2026,
  // manifeste visuel section 3.4 et contrat K5), sans cle i18n nouvelle.
  'EcranResultat',
  'LienFleche',
  // Revue du directeur 01-02/10 (K-54) : les boutons que les ecrans peignaient
  // eux-memes, rendus au core. Voir lib/CLAUDE.md, « Interdits d'interface ».
  'BoutonOutil',
  'BoutonIcone',
  'RaccourciTactile',
  'LigneCleValeur',
  'GroupeReglages',
  'ControleSegmente',
  // Les cinq qui lisent des cles `commun.*` (meme phase).
  'EtatSysteme',
  'BlocAsynchrone',
  'SelecteurProfils',
  'EntetePage',
  'BasculeTheme',
  // THEME-SW-1 : le choix du theme (un rectangle, trois bascules).
  'SelecteurTheme',
  // Le gabarit d'etape partage (demandes B-3 et A-2, 25/09/2026).
  'PageEtape',
  // EN-3 : le point de rappel des cahiers (K-45), sorti de la Journee parce
  // qu'il sert desormais a plusieurs ecrans (Aujourd'hui, Mes Classes).
  'PointRappel',
  // CT-6 : le fil de discussion generique (CTR-04 Echanges).
  'FilDiscussion',
  // ON-AIR-1, ANNUL-VIS-1 : la pastille d'etat de seance.
  'PastilleEtatSeance',
];

/// Les trois largeurs de `docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md` section 8.
///
/// Une valeur au milieu de chaque plage, jamais sa borne : un composant qui ne
/// tiendrait qu'a 599 passerait sinon pour bon.
const List<double> largeurs = <double>[390, 768, 1440];

/// Rejoue tous les etats du catalogue sous des conditions donnees.
///
/// La boucle se termine sur un arbre vide : `Skeleton` et `LocalFeedback`
/// portent des minuteurs, et un minuteur encore arme a la fin d'un test le fait
/// echouer. Les demonter est donc une partie du test, pas une precaution.
Future<void> rejouerTout(
  WidgetTester tester,
  List<EntreeGalerie> entrees, {
  required double largeur,
  required String condition,
  TextDirection direction = TextDirection.ltr,
  double echelleTexte = 1,
  bool mouvementReduit = false,
  InterfaceMode mode = InterfaceMode.standard,
}) async {
  for (final EntreeGalerie entree in entrees) {
    for (final EtatGalerie etat in entree.etats) {
      await tester.pumpWidget(
        sousConditions(
          Builder(builder: etat.construire),
          largeur: largeur,
          direction: direction,
          echelleTexte: echelleTexte,
          mouvementReduit: mouvementReduit,
          mode: mode,
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${entree.nom} / ${etat.nom} a leve $condition',
      );
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Rend un widget sous des conditions donnees, sans reseau reel.
Widget sousConditions(
  Widget enfant, {
  required double largeur,
  TextDirection direction = TextDirection.ltr,
  double echelleTexte = 1,
  bool mouvementReduit = false,
  InterfaceMode mode = InterfaceMode.standard,
}) {
  return hote(
    MediaQuery(
      data: MediaQueryData(
        size: Size(largeur, 2000),
        textScaler: TextScaler.linear(echelleTexte),
        disableAnimations: mouvementReduit,
      ),
      child: Directionality(
        textDirection: direction,
        child: SizedBox(width: largeur, child: enfant),
      ),
    ),
    mode: mode,
    // Le bandeau hors ligne lit le reseau : sans ce faux, chaque rendu
    // tenterait d'interroger la plateforme, qui n'existe pas en test.
    surcharges: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
  );
}

void main() {
  final List<EntreeGalerie> entrees = catalogueGalerie();

  group('La galerie est la preuve du catalogue', () {
    test('elle contient exactement les composants du catalogue', () {
      // « Un composant absent de la galerie est un composant dont personne ne
      // peut verifier les etats sans lancer un ecran metier. »
      final List<String> presents = entrees
          .map((EntreeGalerie e) => e.nom)
          .toList();
      expect(presents.toSet(), composantsDuCatalogue.toSet());
      expect(presents.length, composantsDuCatalogue.length);
    });

    test('aucune entree n est declaree deux fois', () {
      final List<String> noms = entrees
          .map((EntreeGalerie e) => e.nom)
          .toList();
      expect(noms.toSet().length, noms.length);
    });

    test('chaque fichier de lib/core/widgets a son entree', () {
      // La liste ecrite plus haut vient du document ; celle-ci vient du disque.
      // Les deux doivent se rejoindre, sinon un composant a ete ajoute au code
      // sans passer par le catalogue, ce que la constitution interdit.
      final List<String> fichiers =
          Directory('lib/core/widgets')
              .listSync()
              .whereType<File>()
              .map((File f) => f.uri.pathSegments.last)
              .where((String n) => n.endsWith('.dart'))
              .map((String n) => n.replaceAll('.dart', ''))
              .toList()
            ..sort();

      final List<String> attendus =
          composantsDuCatalogue
              .where((String c) => c != 'GrilleSemaine')
              .map(_enSerpent)
              .toList()
            ..sort();

      expect(fichiers, attendus);
    });

    test('un composant livre avec son seul etat nominal n est pas fini', () {
      for (final EntreeGalerie entree in entrees) {
        expect(
          entree.etats.length,
          greaterThanOrEqualTo(2),
          reason: '${entree.nom} ne montre qu un seul etat',
        );
      }
    });

    test('les familles a liste fixe sont couvertes en entier', () {
      for (final EntreeGalerie entree in entrees) {
        final List<String> noms = entree.etats
            .map((EtatGalerie e) => e.nom)
            .toList();
        for (final String obligatoire in entree.famille.etatsObligatoires) {
          expect(
            noms,
            contains(obligatoire),
            reason: '${entree.nom} ne montre pas son etat $obligatoire',
          );
        }
      }
    });

    test('aucun etat n est nomme deux fois dans une meme entree', () {
      for (final EntreeGalerie entree in entrees) {
        final List<String> noms = entree.etats
            .map((EtatGalerie e) => e.nom)
            .toList();
        expect(
          noms.toSet().length,
          noms.length,
          reason: '${entree.nom} nomme deux fois le meme etat',
        );
      }
    });
  });

  group('Chaque etat se rend aux trois largeurs, sans deborder', () {
    for (final double largeur in largeurs) {
      testWidgets('a $largeur', (WidgetTester tester) async {
        tester.view.physicalSize = Size(largeur, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await rejouerTout(
          tester,
          entrees,
          largeur: largeur,
          condition: 'a $largeur',
        );
      });
    }
  });

  group('Les quatre autres axes de verification', () {
    testWidgets('en arabe, tout se rend en miroir sans lever', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await rejouerTout(
        tester,
        entrees,
        largeur: 390,
        direction: TextDirection.rtl,
        condition: 'en RTL',
      );
    });

    testWidgets('a 200 pour cent de taille de texte', (
      WidgetTester tester,
    ) async {
      // L'application doit tenir jusqu'a 200 pour cent sans perte de fonction
      // (`06-accessibilite.md` section 3). Une hauteur fixe sur un conteneur
      // qui porte du texte se voit ici, et nulle part ailleurs.
      tester.view.physicalSize = const Size(390, 8000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await rejouerTout(
        tester,
        entrees,
        largeur: 390,
        echelleTexte: 2,
        condition: 'a 200 pour cent',
      );
    });

    testWidgets('sous reduction du mouvement', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await rejouerTout(
        tester,
        entrees,
        largeur: 390,
        mouvementReduit: true,
        condition: 'en mouvement reduit',
      );
    });

    testWidgets('en mode enfant', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 8000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await rejouerTout(
        tester,
        entrees,
        largeur: 390,
        mode: InterfaceMode.enfant,
        condition: 'en mode enfant',
      );
    });
  });

  group('Les seuils de gabarit', () {
    test('les trois plages sont celles du tableau', () {
      expect(AppGabarit.pour(320), Gabarit.mobile);
      expect(AppGabarit.pour(599), Gabarit.mobile);
      expect(AppGabarit.pour(600), Gabarit.tablette);
      expect(AppGabarit.pour(1199), Gabarit.tablette);
      expect(AppGabarit.pour(1200), Gabarit.desktop);
      expect(AppGabarit.pour(1440), Gabarit.desktop);
    });

    test('chaque gabarit porte sa gouttiere et sa forme de chrome', () {
      expect(Gabarit.mobile.gouttiere, 16);
      expect(Gabarit.tablette.gouttiere, 24);
      expect(Gabarit.desktop.gouttiere, 32);
      expect(Gabarit.mobile.chrome, ChromeNavigation.barreBasse);
      expect(Gabarit.tablette.chrome, ChromeNavigation.rail);
      expect(Gabarit.desktop.chrome, ChromeNavigation.barreLaterale);
    });

    test('les quatre seuils de contenu R1 sont exacts', () {
      expect(AppGabarit.classe(599), ClasseLargeur.compacte);
      expect(AppGabarit.classe(600), ClasseLargeur.moyenne);
      expect(AppGabarit.classe(839), ClasseLargeur.moyenne);
      expect(AppGabarit.classe(840), ClasseLargeur.etendue);
      expect(AppGabarit.classe(1199), ClasseLargeur.etendue);
      expect(AppGabarit.classe(1200), ClasseLargeur.large);
    });

    testWidgets('le gabarit se lit sur la largeur de la fenetre', (
      WidgetTester tester,
    ) async {
      for (final ({double largeur, Gabarit attendu}) cas
          in <({double largeur, Gabarit attendu})>[
            (largeur: 390, attendu: Gabarit.mobile),
            (largeur: 768, attendu: Gabarit.tablette),
            (largeur: 1440, attendu: Gabarit.desktop),
          ]) {
        late Gabarit lu;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(cas.largeur, 800)),
            child: Builder(
              builder: (BuildContext context) {
                lu = AppGabarit.de(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(lu, cas.attendu);
      }
    });
  });
}

/// « AppBottomSheet » vers « app_bottom_sheet ».
String _enSerpent(String nom) {
  final StringBuffer sortie = StringBuffer();
  for (int i = 0; i < nom.length; i++) {
    final String c = nom[i];
    final bool majuscule = c.toUpperCase() == c && c.toLowerCase() != c;
    if (majuscule && i > 0) {
      sortie.write('_');
    }
    sortie.write(c.toLowerCase());
  }
  return sortie.toString();
}
