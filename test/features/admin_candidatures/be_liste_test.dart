// BE-LISTE (16/11/2026) : les retours et l'entree de la liste des candidatures.
//
// Ce que le test prouve, une ligne du cahier apres l'autre :
// 1. un dossier ouvert depuis la liste (ou une page voisine) s'empile : le
//    retour ramene d'ou l'on vient ;
// 2. filtre, tri, page et recherche vivent dans l'adresse : un rechargement,
//    un retour ou un lien partage retrouvent la meme liste ;
// 3. la position de defilement est retrouvee au retour d'un dossier ;
// 4. « Personnes » ouvre Candidatures tant qu'il y a des candidatures en cours ;
// 5. l'en-tete est reduit : un seul menu « Outils », un bandeau sur une ligne,
//    « Qui attend quoi » repliable et qui se souvient ;
// 6. « Piece d'identite a valider » ouvre la meme liste, filtree.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/creneaux_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_invitations_personnelles.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_candidatures/adresse_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/etat_entete_liste.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

List<LigneCandidature> _lignes([int n = 3]) => <LigneCandidature>[
  for (int i = 0; i < n; i++)
    ligneTest(
      id: 'c$i',
      nom: 'Personne Numero$i',
      etat: EtatCandidature.enExamen,
    ),
];

/// L'adresse courante du routeur monte.
Uri _adresse(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(CandidaturesPage)))
        .routerDelegate
        .currentConfiguration
        .uri;

class _FauxAttentes implements PortAttentesRecrutement {
  @override
  Future<AttentesRecrutement> lire() async => const AttentesRecrutement(
    parEtat: <EtatCandidature, Attente>{
      EtatCandidature.enExamen: Attente(nombre: 4),
      EtatCandidature.entretienAPlanifier: Attente(nombre: 2),
      EtatCandidature.aCompleter: Attente(nombre: 3),
    },
    pieceAValider: Attente(nombre: 2),
    enPause: 1,
  );
}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    effacerMemoireAppareil(cleMemoireLectureComprise);
  });

  group('l\'adresse de la liste (fonctions pures)', () {
    test('aller et retour : chaque axe est rendu tel quel', () {
      const RequeteCandidatures r = RequeteCandidatures(
        filtre: FiltreCandidatures(
          pieceEnAttente: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.aCompleter,
          issue: IssueCandidature.enCours,
          enPause: false,
          paysResidence: 'FR',
          genre: 'female',
        ),
        tri: TriCandidatures.recente,
        page: 3,
      );
      final Map<String, String> q = requeteEnAdresse(r);
      expect(requeteDepuisAdresse(q), r);
      expect(q['page'], '3');
      expect(q['tri'], 'recente');
    });

    test('le texte cherche n\'est jamais dans l\'adresse, meme ancien', () {
      final Map<String, String> q = requeteEnAdresse(
        const RequeteCandidatures(
          filtre: FiltreCandidatures(recherche: 'Amina Diallo'),
        ),
      );
      expect(q, isEmpty);
      // Un ancien lien avec `q` ne remplit pas la recherche.
      expect(
        requeteDepuisAdresse(<String, String>{'q': 'amina'}).filtre.recherche,
        isEmpty,
      );
    });

    test('le rappel des filtres dit l\'axe de la piece', () {
      expect(
        rappelFiltres(const FiltreCandidatures(pieceEnAttente: true)),
        contains(t.admin.candidatures.attentes.pieceAValider),
      );
      expect(
        rappelFiltres(const FiltreCandidatures(pieceEnAttente: false)),
        contains(t.recrutement.file.pieceSansAttente),
      );
    });

    test('rien de pose : une adresse nue', () {
      expect(requeteEnAdresse(const RequeteCandidatures()), isEmpty);
      expect(
        requeteDepuisAdresse(const <String, String>{}),
        const RequeteCandidatures(),
      );
    });

    test('une valeur inconnue ou perimee est ignoree, jamais une erreur', () {
      final RequeteCandidatures r = requeteDepuisAdresse(<String, String>{
        'etape': 'nimporte',
        'tri': 'au-hasard',
        'page': '-4',
        'genre': 'autre',
        'pause': 'peut-etre',
      });
      expect(r, const RequeteCandidatures());
    });
  });

  group('2. filtre, tri, page et recherche dans l\'adresse', () {
    testWidgets('une adresse partagee retrouve la meme liste', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(
        tester,
        port: port,
        depart:
            '${Routes.adminPersonnesCandidatures}?etape=verifications&tri=recente',
      );
      final AppelLister a = port.appels.last;
      expect(a.filtre.etape, EtapeCandidature.verifications);
      expect(a.tri, TriCandidatures.recente);
    });

    testWidgets('poser un filtre l\'ecrit dans l\'adresse, sans empiler', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(tester, port: port);
      await ouvrirFeuilleFiltresDeTest(tester);
      await choisirDansFeuille(
        tester,
        'salle',
        t.recrutement.salles.verification,
      );
      expect(_adresse(tester).queryParameters, <String, String>{
        'etape': 'verifications',
      });
      expect(port.appels.last.filtre.etape, EtapeCandidature.verifications);
      // « Tous » retire le parametre.
      await ouvrirFeuilleFiltresDeTest(tester);
      await choisirDansFeuille(
        tester,
        'salle',
        t.admin.candidatures.filtres.tous,
      );
      expect(_adresse(tester).queryParameters, isEmpty);
    });

    testWidgets(
      'la recherche saisie n\'est pas dans l\'adresse, mais la page la garde',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
        );
        await monterCandidatures(tester, port: port);
        await tester.enterText(_cle('candidatures-recherche'), 'Numero1');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await laisser(tester);
        expect(port.appels.last.filtre.recherche, 'Numero1');
        expect(_adresse(tester).queryParameters.containsKey('q'), isFalse);
        expect(_adresse(tester).toString(), isNot(contains('Numero1')));
        // Un autre filtre ecrit l'adresse : la recherche reste celle de la page.
        await ouvrirFeuilleFiltresDeTest(tester);
        await choisirDansFeuille(
          tester,
          'salle',
          t.recrutement.salles.verification,
        );
        expect(port.appels.last.filtre.recherche, 'Numero1');
        expect(port.appels.last.filtre.etape, EtapeCandidature.verifications);
      },
    );

    testWidgets('le tri et la page sont dans l\'adresse', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(6),
        taillePage: 2,
      );
      await monterCandidatures(tester, port: port);
      await tester.ensureVisible(_cle('candidatures-pagination'));
      await tester.tap(
        find.bySemanticsLabel(t.admin.candidatures.pagination.suivante),
      );
      await laisser(tester);
      expect(_adresse(tester).queryParameters['page'], '2');
      expect(port.appels.last.page, 2);
    });

    testWidgets('un changement d\'adresse remet la liste dans l\'etat dit', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(
        tester,
        port: port,
        depart: '${Routes.adminPersonnesCandidatures}?etape=verifications',
      );
      expect(port.appels.last.filtre.etape, EtapeCandidature.verifications);
      GoRouter.of(tester.element(find.byType(CandidaturesPage)))
          .go(Routes.adminPersonnesCandidatures);
      await laisser(tester);
      expect(port.appels.last.filtre.etape, isNull);
    });
  });

  group('1 et 3. le retour ramene d\'ou l\'on vient, a la meme place', () {
    testWidgets('filtres et position gardes apres un dossier ouvert', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(30),
      );
      tester.view.physicalSize = const Size(390, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: '${Routes.adminPersonnesCandidatures}?etape=verifications',
          routes: <RouteBase>[
            GoRoute(
              path: Routes.adminPersonnesCandidatures,
              builder: (BuildContext c, GoRouterState etat) => CandidaturesPage(
                requete: etat.uri.queryParameters,
                ouvrirCandidature: (LigneCandidature l) =>
                    unawaited(GoRouter.of(c).push<void>('/dossier')),
              ),
            ),
            temoin('/dossier'),
          ],
          surcharges: [
            portCandidaturesDirectionProvider.overrideWithValue(port),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
        ),
      );
      await laisser(tester);
      await tester.enterText(_cle('candidatures-recherche'), 'Numero1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await laisser(tester);
      final Finder defile = find.byType(Scrollable).first;
      await tester.drag(defile, const Offset(0, -700));
      await laisser(tester);
      final double avant = tester
          .state<ScrollableState>(defile)
          .position
          .pixels;
      expect(avant, greaterThan(100));

      // Un dossier s'ouvre : on empile, on ne remplace pas.
      final BuildContext c = tester.element(find.byType(CandidaturesPage));
      unawaited(GoRouter.of(c).push<void>('/dossier'));
      await laisser(tester);
      expect(find.text('temoin:/dossier'), findsOneWidget);
      GoRouter.of(tester.element(find.text('temoin:/dossier'))).pop();
      await laisser(tester);

      expect(find.byType(CandidaturesPage), findsOneWidget);
      expect(_adresse(tester).queryParameters['etape'], 'verifications');
      expect(port.appels.last.filtre.etape, EtapeCandidature.verifications);
      // La recherche, hors de l'adresse, est gardee par la page.
      expect(port.appels.last.filtre.recherche, 'Numero1');
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        avant,
      );
    });

    testWidgets(
      '« Invitations » et « Creneaux » s\'empilent : le retour revient',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
        );
        await monterCandidatures(
          tester,
          port: port,
          invitations: true,
          depart: '${Routes.adminPersonnesCandidatures}?etape=verifications',
        );
        await tester.tap(_cle('candidatures-outils'));
        await laisser(tester);
        await tester.tap(find.text(t.recrutement.invitations.onglet));
        await laisser(tester);
        expect(
          find.text('temoin:/admin/personnes/invitations'),
          findsOneWidget,
        );
        GoRouter.of(
          tester.element(find.text('temoin:/admin/personnes/invitations')),
        ).pop();
        await laisser(tester);
        expect(_adresse(tester).queryParameters['etape'], 'verifications');
      },
    );
  });

  group('5. l\'en-tete reduit', () {
    testWidgets('un seul menu « Outils » porte les liens, aucun lien nu', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        invitations: true,
      );
      expect(find.byType(MenuActions), findsOneWidget);
      for (final String cle in <String>[
        'candidatures-invitations',
        'candidatures-prevenir',
        'candidatures-creneaux',
        'candidatures-codes-personnels',
        'candidatures-importer',
      ]) {
        expect(_cle(cle), findsNothing, reason: cle);
      }
      await tester.tap(_cle('candidatures-outils'));
      await laisser(tester);
      expect(find.text(t.recrutement.invitations.onglet), findsOneWidget);
    });

    testWidgets('sans aucun outil : pas de menu', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(find.byType(MenuActions), findsNothing);
    });

    testWidgets(
      '« J\'ai compris » ferme le bandeau, une icone le rappelle, la memoire le garde',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: const CapacitesCandidatures(
            peutLire: true,
            peutLireHorsGenre: true,
          ),
        );
        await monterCandidatures(tester, port: port);
        final String message = t.admin.candidatures.exception.message;
        expect(find.text(message), findsOneWidget);
        expect(_cle('candidatures-rappel-lecture'), findsNothing);
        await tester.tap(_cle('candidatures-jai-compris'));
        await laisser(tester);
        expect(find.text(message), findsNothing);
        expect(_cle('candidatures-rappel-lecture'), findsOneWidget);
        expect(lireMemoireAppareil(cleMemoireLectureComprise), '1');

        // Une autre session de la page : le bandeau ne revient pas.
        await tester.pumpWidget(const SizedBox());
        await monterCandidatures(tester, port: port);
        expect(find.text(message), findsNothing);
        // L'icone le rappelle au toucher.
        await tester.tap(_cle('candidatures-rappel-lecture'));
        await laisser(tester);
        expect(find.text(message), findsOneWidget);
        expect(_cle('candidatures-rappel-lecture'), findsNothing);
      },
    );

    testWidgets('le titre est le selecteur : le mot n\'apparait qu\'une fois', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        largeur: 360,
        hauteur: 800,
      );
      expect(find.text(t.admin.candidatures.titre), findsOneWidget);
    });

    testWidgets('la recherche, « Filtres » et « Trier » sont sur une rangee', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        largeur: 360,
        hauteur: 800,
      );
      final Finder rangees = find.ancestor(
        of: _cle('candidatures-recherche'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rangees, matching: _cle('candidatures-filtres')),
        findsWidgets,
      );
      expect(
        find.descendant(of: rangees, matching: _cle('candidatures-tri')),
        findsWidgets,
      );
    });

    testWidgets('telephone : « Outils » est sur la rangee du selecteur', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        largeur: 360,
        hauteur: 800,
        invitations: true,
      );
      // Meme rangee (un `Row`, qui passe dessous si le texte grandit a plus
      // de 130 %) : la position exacte depend de la police, la parente non.
      final Finder rangees = find.ancestor(
        of: find.byType(SousNavigationDomaine),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rangees, matching: _cle('candidatures-outils')),
        findsWidgets,
      );
    });

    testWidgets('le nombre et « Selectionner » sont sur la meme ligne', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: const CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            gestes: <String, bool>{'agirEnLot': true},
          ),
        ),
        largeur: 360,
        hauteur: 800,
      );
      final Finder rangee = find
          .ancestor(of: _cle('candidatures-total'), matching: find.byType(Wrap))
          .first;
      expect(
        find.descendant(
          of: rangee,
          matching: _cle('candidatures-selectionner'),
        ),
        findsOneWidget,
      );
      // Plus de bouton « Trier » dans cette ligne.
      expect(
        find.descendant(of: rangee, matching: _cle('candidatures-tri')),
        findsNothing,
      );
    });

    testWidgets('les cinq outils apparaissent quand le serveur les accorde', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: const CapacitesCandidatures(
            peutLire: true,
            genreLecteurConnu: true,
            peutDecider: true,
            peutImporter: true,
            gestes: <String, bool>{'consignerPrevenu': true},
          ),
        ),
        invitations: true,
        surcharges: [
          portPrevenirCandidatsProvider.overrideWithValue(_FauxPrevenir()),
          portCreneauxDirectionProvider.overrideWithValue(_FauxCreneaux()),
          portInvitationsPersonnellesProvider.overrideWithValue(
            _FauxPersonnelles(),
          ),
          portImportCandidaturesProvider.overrideWithValue(
            FauxImportCandidatures(
              capacitesRendues: const CapacitesImportCandidatures(
                peutImporter: true,
              ),
            ),
          ),
        ],
      );
      await tester.tap(_cle('candidatures-outils'));
      await laisser(tester);
      for (final String libelle in <String>[
        t.recrutement.invitations.onglet,
        t.candidatsFlux.prevenir.lien,
        t.admin.candidatures.creneaux.lien,
        t.candidatsFlux.invitationsPersonnelles.lien,
        t.candidatsFlux.importFormulaires.lienEntree,
      ]) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
    });
  });

  group('6. les files : un seul systeme', () {
    Future<FauxCandidaturesDirection> monter(
      WidgetTester tester, {
      CompteursAlertes? alertes,
      double largeur = 390,
    }) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        alertes: alertes,
      );
      await monterCandidatures(
        tester,
        port: port,
        largeur: largeur,
        surcharges: [
          portAttentesRecrutementProvider.overrideWithValue(_FauxAttentes()),
        ],
      );
      return port;
    }

    FilterPill puce(WidgetTester tester, String cle) =>
        tester.widget<FilterPill>(_cle('candidatures-file-$cle'));

    testWidgets('les files viennent des attentes, chacune avec son nombre', (
      tester,
    ) async {
      await monter(tester);
      expect(puce(tester, 'etat-en_examen').compteur, 4);
      expect(puce(tester, 'piece').compteur, 2);
      expect(puce(tester, 'etat-entretien_a_planifier').compteur, 2);
      expect(puce(tester, 'etat-a_completer').compteur, 3);
      expect(puce(tester, 'pause').compteur, 1);
      // Un nombre a zero : pas de puce ; « Toutes » reste, avec le total lu
      // sur la liste sans filtre.
      expect(_cle('candidatures-file-etat-decision_en_attente'), findsNothing);
      expect(puce(tester, 'toutes').compteur, 3);
      expect(puce(tester, 'toutes').retenue, isTrue);
      // Les deux anciennes cartes ont disparu.
      expect(find.text(t.admin.candidatures.attentes.titre), findsNothing);
      expect(find.text(t.admin.candidatures.aTraiter), findsNothing);
    });

    testWidgets(
      'une file touchee est la seule choisie ; « Toutes » la relache',
      (tester) async {
        final FauxCandidaturesDirection port = await monter(tester);
        await tester.tap(_cle('candidatures-file-etat-a_completer'));
        await laisser(tester);
        final FiltreCandidatures f = port.appels.last.filtre;
        expect(f.etat, EtatCandidature.aCompleter);
        expect(f.issue, IssueCandidature.enCours);
        expect(f.enPause, isFalse);
        expect(puce(tester, 'etat-a_completer').retenue, isTrue);
        expect(puce(tester, 'etat-en_examen').retenue, isFalse);
        expect(puce(tester, 'toutes').retenue, isFalse);
        // Une autre file remplace la premiere.
        await tester.tap(_cle('candidatures-file-etat-en_examen'));
        await laisser(tester);
        expect(puce(tester, 'etat-en_examen').retenue, isTrue);
        expect(puce(tester, 'etat-a_completer').retenue, isFalse);
        // « Toutes » : plus de file ; son nombre reste celui de la portee.
        await tester.tap(_cle('candidatures-file-toutes'));
        await laisser(tester);
        expect(port.appels.last.filtre.etat, isNull);
        expect(port.appels.last.filtre.issue, isNull);
        expect(puce(tester, 'toutes').retenue, isTrue);
        expect(puce(tester, 'toutes').compteur, 3);
      },
    );

    testWidgets('« Piece a valider » filtre la meme liste sur pieceEnAttente', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = await monter(tester);
      await tester.tap(_cle('candidatures-file-piece'));
      await laisser(tester);
      expect(find.byType(CandidaturesPage), findsOneWidget);
      final FiltreCandidatures f = port.appels.last.filtre;
      expect(f.pieceEnAttente, isTrue);
      expect(f.issue, IssueCandidature.enCours);
      expect(f.enPause, isFalse);
      expect(f.etat, isNull);
      expect(_adresse(tester).queryParameters, <String, String>{
        'issue': 'enCours',
        'pause': 'non',
        'piece': 'oui',
      });
      expect(puce(tester, 'piece').retenue, isTrue);
    });

    testWidgets(
      '« Entretien a planifier » dit par une icone qu\'aucun creneau n\'est ouvert',
      (tester) async {
        await monter(tester);
        expect(puce(tester, 'etat-entretien_a_planifier').apercu, isNotNull);
        expect(puce(tester, 'etat-en_examen').apercu, isNull);
      },
    );

    testWidgets(
      'les alertes que le serveur ne sait pas filtrer : puces a plus de zero, jamais touchables',
      (tester) async {
        await monter(
          tester,
          alertes: const CompteursAlertes(
            confirmeesIndisponibles: 5,
            entretiensEnRetard: 0,
            bloquees: 2,
            informationsManquantes: 9,
          ),
        );
        // Des pastilles d'etat : ni puce, ni bouton, rien ne se touche.
        expect(
          tester
              .widget<StatusPill>(_cle('candidatures-file-alerte-confirmees'))
              .libelle,
          '${t.recrutement.file.confirmeesIndisponibles} 5',
        );
        expect(
          tester
              .widget<StatusPill>(_cle('candidatures-file-alerte-bloquees'))
              .libelle,
          '${t.admin.candidatures.alertes.bloquees} 2',
        );
        // Zero : pas de puce. « Informations manquantes » n'est pas une file
        // (elle repetait « A completer »).
        expect(_cle('candidatures-file-alerte-retard'), findsNothing);
        expect(
          find.text(t.admin.candidatures.alertes.informationsManquantes),
          findsNothing,
        );
      },
    );

    testWidgets(
      'l\'icone « Filtres » dit et montre le nombre de filtres poses',
      (tester) async {
        await monter(tester);
        expect(_cle('candidatures-filtres-nombre'), findsNothing);
        await ouvrirFeuilleFiltresDeTest(tester);
        await choisirDansFeuille(
          tester,
          'genre',
          t.admin.candidatures.genres.male,
        );
        expect(_cle('candidatures-filtres-nombre'), findsOneWidget);
        expect(
          find.bySemanticsLabel(t.recrutement.file.filtresPoses(n: 1)),
          findsOneWidget,
        );
        // Une file choisie n'est pas un filtre de plus.
        await tester.tap(_cle('candidatures-file-etat-en_examen'));
        await laisser(tester);
        expect(
          find.bySemanticsLabel(t.recrutement.file.filtresPoses(n: 1)),
          findsOneWidget,
        );
      },
    );

    testWidgets('la feuille « Filtres » dit les phrases des files, en petit', (
      tester,
    ) async {
      await monter(tester);
      await ouvrirFeuilleFiltresDeTest(tester);
      expect(
        find.descendant(
          of: _cle('feuille-filtres-file-piece'),
          matching: find.text(t.admin.candidatures.attentes.pieceAide),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cle('feuille-filtres-file-etat-entretien_a_planifier'),
          matching: find.text(t.admin.candidatures.attentes.aucunCreneau),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'la feuille « Filtres » porte tous les filtres, « Effacer » les rend',
      (tester) async {
        final FauxCandidaturesDirection port = await monter(tester);
        await ouvrirFeuilleFiltresDeTest(tester);
        for (final String cle in <String>[
          'salle',
          'etat',
          'issue',
          'pause',
          'versement',
          'piece',
          'responsable',
          'genre',
          'pays',
          'ijaza',
          'langue',
          'riwaya',
          'public',
          'heure-de',
          'heure-a',
          'jours-min',
          'competence',
          'competence-niveau',
          'competence-disponibilite',
          'competence-accord',
        ]) {
          expect(_cle('feuille-filtre-$cle'), findsOneWidget, reason: cle);
        }
        // Les jours : un ou plusieurs.
        await tester.ensureVisible(_cle('feuille-jour-3'));
        await tester.tap(_cle('feuille-jour-3'));
        await laisser(tester);
        await tester.tap(_cle('feuille-jour-5'));
        await laisser(tester);
        expect(port.appels.last.filtre.jours, <int>[3, 5]);
        await tester.ensureVisible(_cle('feuille-filtres-effacer'));
        await tester.tap(_cle('feuille-filtres-effacer'));
        await laisser(tester);
        expect(port.appels.last.filtre.jours, isNull);
        expect(port.appels.last.filtre.estVide, isTrue);
      },
    );

    testWidgets('les reponses se filtrent par la feuille : l\'ijaza', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = await monter(tester);
      await ouvrirFeuilleFiltresDeTest(tester);
      await choisirDansFeuille(tester, 'ijaza', 'oui');
      expect(port.appels.last.filtre.ijaza, 'oui');
    });
  });
}

class _FauxPrevenir extends Fake implements PortPrevenirCandidats {}

class _FauxCreneaux extends Fake implements PortCreneauxDirection {}

class _FauxPersonnelles extends Fake implements PortInvitationsPersonnelles {}
