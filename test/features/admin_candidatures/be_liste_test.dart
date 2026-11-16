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
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_candidatures/adresse_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/carte_alertes.dart';
import 'package:rewayah_academy/features/admin_candidatures/carte_attentes.dart';
import 'package:rewayah_academy/features/admin_candidatures/etat_entete_liste.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';
import '../../support/rangee_plus.dart';
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
    },
    pieceAValider: Attente(nombre: 2),
  );
}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    effacerMemoireAppareil(cleMemoireAttentesRepliees);
    effacerMemoireAppareil(cleMemoireLectureDepliee);
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
      await toucherFiltre(tester, _cle('candidatures-filtre-verification'));
      await laisser(tester);
      expect(_adresse(tester).queryParameters, <String, String>{
        'etape': 'verifications',
      });
      expect(port.appels.last.filtre.etape, EtapeCandidature.verifications);
      // « Toutes » retire le parametre.
      await toucherFiltre(tester, _cle('candidatures-filtre-toutes'));
      await laisser(tester);
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
        await toucherFiltre(tester, _cle('candidatures-filtre-verification'));
        await laisser(tester);
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
      expect(find.text(t.recrutement.file.outils), findsOneWidget);
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
      'le bandeau « Lecture des deux cotes » : une ligne, depliable',
      (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: const CapacitesCandidatures(
              peutLire: true,
              peutLireHorsGenre: true,
            ),
          ),
        );
        final String titre = t.admin.candidatures.exception.titre;
        final String message = t.admin.candidatures.exception.message;
        expect(find.text(titre), findsOneWidget);
        expect(find.text(message), findsNothing);
        await tester.tap(_cle('candidatures-exception-bascule'));
        await laisser(tester);
        expect(find.text(message), findsOneWidget);
        await tester.tap(_cle('candidatures-exception-bascule'));
        await laisser(tester);
        expect(find.text(message), findsNothing);
      },
    );

    testWidgets('« Qui attend quoi » se replie et se souvient', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        surcharges: [
          portAttentesRecrutementProvider.overrideWithValue(_FauxAttentes()),
        ],
      );
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.enExamen)),
        findsOneWidget,
      );
      await tester.tap(find.text(t.recrutement.file.replier));
      await laisser(tester);
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.enExamen)),
        findsNothing,
      );
      // Repliee : une ligne, le titre et ce qui attend l'academie (ici 4).
      expect(
        find.textContaining('${t.admin.candidatures.attentes.titre} · 4'),
        findsOneWidget,
      );
      expect(lireMemoireAppareil(cleMemoireAttentesRepliees), '1');

      // Un nouvel ecran (autre session de la page) la retrouve repliee.
      await tester.pumpWidget(const SizedBox());
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        surcharges: [
          portAttentesRecrutementProvider.overrideWithValue(_FauxAttentes()),
        ],
      );
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.enExamen)),
        findsNothing,
      );
      await tester.tap(find.text(t.recrutement.file.afficher));
      await laisser(tester);
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.enExamen)),
        findsOneWidget,
      );
    });

    testWidgets(
      'telephone 360 x 800 : carte repliee, la premiere ligne monte (mesure reelle : captures)',
      (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(lignes: _lignes()),
          largeur: 360,
          hauteur: 800,
          invitations: true,
          surcharges: [
            portAttentesRecrutementProvider.overrideWithValue(_FauxAttentes()),
          ],
        );
        final Finder ligne = find.byKey(cleCandidature('c0'));
        final double depliee = tester.getTopLeft(ligne).dy;
        await tester.tap(_cle('candidatures-attentes-bascule'));
        await laisser(tester);
        final double repliee = tester.getTopLeft(ligne).dy;
        debugPrint(
          'MESURE 360x800 : premiere ligne a $repliee (repliee), $depliee (depliee)',
        );
        // Les tests rendent en police de substitution (plus large) : le seuil
        // de 640 se mesure dans la capture, avec les vraies polices.
        expect(repliee, lessThan(depliee));
        // Plus de phrase d'introduction, plus de « A traiter » a zero.
        expect(find.text(t.admin.candidatures.sousTitre), findsNothing);
        expect(find.byType(CarteAlertes), findsOneWidget);
        expect(_cle('candidatures-alertes'), findsNothing);
      },
    );

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

    testWidgets(
      'telephone : le nombre, « Selectionner » et le tri sur une rangee',
      (tester) async {
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
        // Une seule rangee (un `Row`) : le nombre, « Selectionner » et le tri.
        final Finder rangee = find
            .ancestor(
              of: _cle('candidatures-total'),
              matching: find.byType(Row),
            )
            .last;
        for (final String cle in <String>[
          'candidatures-selectionner',
          'candidatures-tri',
        ]) {
          expect(
            find.descendant(of: rangee, matching: _cle(cle)),
            findsOneWidget,
            reason: cle,
          );
        }
      },
    );

    testWidgets(
      'la carte « A traiter » compacte montre ses puces quand un compteur est a servir',
      (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: _lignes(),
            alertes: const CompteursAlertes(
              informationsManquantes: 3,
              confirmeesIndisponibles: 0,
            ),
          ),
          largeur: 360,
          hauteur: 800,
        );
        expect(_cle('candidatures-alertes'), findsOneWidget);
        expect(find.text(t.admin.candidatures.aTraiter), findsNothing);
      },
    );

    testWidgets(
      'telephone : le tri est un menu, il part au serveur et revient a la page 1',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(6),
          taillePage: 2,
        );
        await monterCandidatures(
          tester,
          port: port,
          largeur: 360,
          hauteur: 800,
        );
        await tester.ensureVisible(_cle('candidatures-pagination'));
        await tester.tap(
          find.bySemanticsLabel(t.admin.candidatures.pagination.suivante),
        );
        await laisser(tester);
        expect(port.appels.last.page, 2);
        await tester.ensureVisible(_cle('candidatures-tri'));
        await tester.tap(_cle('candidatures-tri'));
        await laisser(tester);
        await tester.tap(find.text(t.admin.candidatures.tri.reception));
        await laisser(tester);
        expect(port.appels.last.tri, TriCandidatures.recente);
        expect(port.appels.last.page, 1);
        expect(_adresse(tester).queryParameters['tri'], 'recente');
      },
    );

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

  group('6. une seule file', () {
    testWidgets(
      '« Piece d\'identite a valider » filtre la meme liste sur pieceEnAttente',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
        );
        await monterCandidatures(
          tester,
          port: port,
          surcharges: [
            portAttentesRecrutementProvider.overrideWithValue(_FauxAttentes()),
          ],
        );
        await tester.ensureVisible(find.byKey(CarteAttentes.clePiece));
        await laisser(tester);
        await tester.tap(find.byKey(CarteAttentes.clePiece));
        await laisser(tester);
        // On est toujours sur la liste, filtree ; aucune autre page.
        expect(find.byType(CandidaturesPage), findsOneWidget);
        final FiltreCandidatures f = port.appels.last.filtre;
        expect(f.pieceEnAttente, isTrue);
        expect(f.issue, IssueCandidature.enCours);
        expect(f.enPause, isFalse);
        expect(f.etape, isNull);
        expect(_adresse(tester).queryParameters, <String, String>{
          'issue': 'enCours',
          'pause': 'non',
          'piece': 'oui',
        });
      },
    );
  });
}

class _FauxPrevenir extends Fake implements PortPrevenirCandidats {}

class _FauxCreneaux extends Fake implements PortCreneauxDirection {}

class _FauxPersonnelles extends Fake implements PortInvitationsPersonnelles {}
