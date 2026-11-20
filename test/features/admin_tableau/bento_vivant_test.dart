// VIVANT : le haut de l'accueil de la direction en bento vivant.
//
// Donnees reelles uniquement : une case sans lecture ne s'affiche pas. Une
// case qui porte un nombre ouvre la liste deja filtree, a son adresse (contrat de
// navigation §2). La phrase de Praxis suit des regles ecrites.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/creneaux_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/vivant/niveau_eau.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/activite_recente.dart';
import 'package:rewayah_academy/features/admin_tableau/bento_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/dernier_non_lu.dart';
import 'package:rewayah_academy/features/admin_tableau/phrase_praxis.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/com_messages/non_lus_messages.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

final DateTime _maintenant = DateTime(2026, 11, 20, 9);

AttentesRecrutement _attentes({int creneaux = 0}) => AttentesRecrutement(
  parEtat: <EtatCandidature, Attente>{
    EtatCandidature.aCompleter: Attente(
      nombre: 40,
      plusAncien: DateTime(2026, 11, 2, 9),
    ),
    EtatCandidature.enExamen: Attente(
      nombre: 12,
      plusAncien: DateTime(2026, 11, 17, 9),
    ),
    EtatCandidature.entretienAPlanifier: Attente(
      nombre: 5,
      plusAncien: DateTime(2026, 11, 18, 9),
    ),
  },
  pieceAValider: Attente(nombre: 3, plusAncien: DateTime(2026, 11, 19, 9)),
  creneauxOuverts: creneaux,
);

const IndicateursAdmin _indicateurs = IndicateursAdmin(
  dossiersEnAttente: 0,
  foyersSansEnseignant: 2,
  rapportsManquants: 1,
  incidents24h: 0,
  comptesEchus: 0,
  demandesEnAttente: 4,
);

List<Override> _surcharges({
  AttentesRecrutement? attentes,
  EtatFileCourriels? courriels,
  int messages = 0,
  IndicateursAdmin indicateurs = _indicateurs,
}) => <Override>[
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()..indicateursRendus = indicateurs,
  ),
  serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
  if (attentes != null) ...<Override>[
    attentesRecrutementProvider.overrideWith((_) async => attentes),
    // Deux creneaux libres demain, un reserve apres-demain (qui ne compte
    // pas), aucun les autres jours.
    creneauxDirectionProvider.overrideWith(
      (_) async => <CreneauDirection>[
        for (final (int, int, EtatCreneau) c in <(int, int, EtatCreneau)>[
          (1, 10, EtatCreneau.libre),
          (1, 15, EtatCreneau.libre),
          (2, 10, EtatCreneau.reserve),
        ])
          CreneauDirection(
            id: 'c${c.$1}-${c.$2}',
            cote: 'male',
            debut: DateTime(2026, 11, 20 + c.$1, c.$2),
            fin: DateTime(2026, 11, 20 + c.$1, c.$2 + 1),
            langues: const <String>['fr'],
            participants: 1,
            fondateurs: 1,
            etat: c.$3,
          ),
      ],
    ),
    pageCandidaturesProvider(requetePieces).overrideWith(
      (_) async => PageCandidatures.depuisJson(const <String, Object?>{
        'total': 3,
        'page': 1,
        'taillePage': 25,
        'lignes': <Object?>[
          <String, Object?>{
            'id': 'cand-1',
            'reference': 'RA-26-4817',
            'nomComplet': 'Personne De Test',
            'issue': 'en_cours',
          },
        ],
      }),
    ),
  ],
  dernierNonLuProvider.overrideWith(
    (_) async => messages > 0 ? ('Personne De Test', 'Premiere ligne') : null,
  ),
  if (courriels != null)
    etatFileCourrielsProvider.overrideWith((_) async => courriels),
  nonLusMessagesProvider.overrideWith((_) async => messages),
];

Future<void> _vivre(WidgetTester tester, [int images = 40]) async {
  for (int i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _page() => TableauDeBordPage(horloge: () => _maintenant);

/// La page dans un routeur minimal : toute autre adresse s'affiche en texte.
Widget _routant(List<Override> surcharges) => hoteRoutant(
  depart: '/',
  surcharges: surcharges,
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, _) => _page()),
    GoRoute(
      path: '/admin/:reste(.*)',
      builder: (_, GoRouterState etat) =>
          Scaffold(body: Text('ALLE ${etat.uri}')),
    ),
  ],
);

void main() {
  group('PhrasePraxis : les regles', () {
    test('des entretiens a planifier sans creneau passent avant tout', () {
      final PhrasePraxis p = PhrasePraxis.depuis(
        calme: false,
        entretiensAPlanifier: 5,
        creneauxOuverts: 0,
        pieces: 30,
        demandes: 50,
      );
      expect(p, const PhrasePraxis(SujetPraxis.creneaux, 5));
      expect(p.humeur, HumeurPraxis.soucieux);
      expect(p.texte, t.admin.tableau.vivant.praxisCreneaux(n: 5));
    });

    test('avec un creneau ouvert, la plus grande file parle', () {
      expect(
        PhrasePraxis.depuis(
          calme: false,
          entretiensAPlanifier: 5,
          creneauxOuverts: 2,
          pieces: 3,
          dossiers: 1,
          demandes: 9,
          messages: 4,
        ),
        const PhrasePraxis(SujetPraxis.demandes, 9),
      );
    });

    test('a egalite : pieces, dossiers, demandes, messages', () {
      expect(
        PhrasePraxis.depuis(
          calme: false,
          pieces: 2,
          dossiers: 2,
          demandes: 2,
          messages: 2,
        ).sujet,
        SujetPraxis.pieces,
      );
    });

    test('creneaux non lus : jamais le blocage des creneaux', () {
      expect(
        PhrasePraxis.depuis(calme: false, entretiensAPlanifier: 5).sujet,
        SujetPraxis.silence,
      );
    });

    test('rien ne bloque : il le dit', () {
      final PhrasePraxis p = PhrasePraxis.depuis(
        calme: true,
        pieces: 0,
        dossiers: 0,
        demandes: 0,
        messages: 0,
      );
      expect(p.sujet, SujetPraxis.calme);
      expect(p.texte, t.admin.tableau.calme);
      expect(p.humeur, HumeurPraxis.heureux);
    });

    test('autre chose attend ailleurs : il se tait', () {
      final PhrasePraxis p = PhrasePraxis.depuis(calme: false, demandes: 0);
      expect(p.sujet, SujetPraxis.silence);
      expect(p.texte, isNull);
    });
  });

  group('Adresses filtrees', () {
    test('un etat : en cours, hors pause, dans l adresse', () {
      final Uri u = Uri.parse(
        adresseCandidaturesFiltree(filtreEtat(EtatCandidature.enExamen)),
      );
      expect(u.path, Routes.adminPersonnesCandidatures);
      expect(u.queryParameters, <String, String>{
        'etat': 'enExamen',
        'issue': 'enCours',
        'pause': 'non',
      });
    });

    test('les pieces a valider', () {
      final Uri u = Uri.parse(adresseCandidaturesFiltree(filtrePieces));
      expect(u.queryParameters, <String, String>{
        'issue': 'enCours',
        'pause': 'non',
        'piece': 'oui',
      });
    });
  });

  group('Tableau de bord : le bento vivant', () {
    testWidgets('sans lecture du recrutement : Praxis seul, aucune case '
        'inventee', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleHeros), findsOneWidget);
      expect(find.byType(PraxisVivant), findsOneWidget);
      expect(find.byKey(BentoVivant.clePieces), findsNothing);
      expect(find.byKey(BentoVivant.cleMessages), findsNothing);
      expect(find.byKey(BentoVivant.cleCourriels), findsNothing);
      expect(find.byType(ParcoursCandidats), findsNothing);
      expect(find.byType(NiveauEau), findsNothing);
      // 4 demandes a trancher : la plus grande file lue.
      expect(
        find.text(t.admin.tableau.vivant.praxisDemandes(n: 4)),
        findsOneWidget,
      );
      expect(find.text(t.admin.tableau.vivant.bonjour), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('avec les lectures : chaque case porte son vrai nombre', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            attentes: _attentes(),
            courriels: const EtatFileCourriels(
              parJour: 900,
              partis24h: 412,
              enAttente: 0,
              joursEstimes: 0,
            ),
            messages: 7,
          ),
        ),
      );
      await _vivre(tester);
      Finder dans(Key cle, String texte) =>
          find.descendant(of: find.byKey(cle), matching: find.text(texte));
      expect(dans(BentoVivant.clePieces, '3'), findsOneWidget);
      expect(dans(BentoVivant.cleMessages, '7'), findsOneWidget);
      expect(dans(BentoVivant.cleCourriels, '412'), findsOneWidget);
      expect(
        dans(
          BentoVivant.cleCourriels,
          t.admin.tableau.vivant.courrielsSur(max: 900),
        ),
        findsOneWidget,
      );
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.aCompleter), '40'),
        findsOneWidget,
      );
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.enExamen), '12'),
        findsOneWidget,
      );
      // Etat sans personne : un zero lu, jamais absent.
      expect(
        dans(BentoVivant.cleEtat(EtatCandidature.entretienPlanifie), '0'),
        findsOneWidget,
      );
      // Le blocage : 5 entretiens a planifier, aucun creneau. Dit par
      // Praxis et par la case, avec des mots (jamais la couleur seule).
      expect(
        find.text(t.admin.tableau.vivant.praxisCreneaux(n: 5)),
        findsOneWidget,
      );
      expect(
        dans(
          BentoVivant.cleEtat(EtatCandidature.entretienAPlanifier),
          t.admin.candidatures.attentes.aucunCreneau,
        ),
        findsOneWidget,
      );
      // Large comme son groupe : 40 personnes prennent plus de place que 12.
      expect(
        tester
            .getSize(
              find.byKey(BentoVivant.cleEtat(EtatCandidature.aCompleter)),
            )
            .width,
        greaterThan(
          tester
              .getSize(
                find.byKey(BentoVivant.cleEtat(EtatCandidature.enExamen)),
              )
              .width,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('rien ne bloque : Praxis le dit, une seule fois', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            indicateurs: const IndicateursAdmin(
              dossiersEnAttente: 0,
              foyersSansEnseignant: 0,
              rapportsManquants: 0,
              incidents24h: 0,
              comptesEchus: 0,
              demandesEnAttente: 0,
            ),
          ),
        ),
      );
      await _vivre(tester);
      expect(find.text(t.admin.tableau.calme), findsOneWidget);
    });

    testWidgets('compteurs en erreur : la phrase et « Reessayer », pas de '
        'Praxis qui parlerait sans chiffres', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(
              FauxServiceAdmin()..erreurIndicateurs = StateError('panne'),
            ),
            serviceValidationProvider.overrideWithValue(
              FauxServiceValidation(),
            ),
            nonLusMessagesProvider.overrideWith((_) async => 0),
          ],
        ),
      );
      await _vivre(tester);
      expect(find.byType(BentoVivant), findsNothing);
      expect(find.text(t.admin.tableau.compteursErreur), findsOneWidget);
    });

    for (final (Key, String, String) cas in <(Key, String, String)>[
      (
        BentoVivant.clePieces,
        'pieces (le dossier de la personne, dans sa file)',
        '/admin/personnes/candidatures/RA-26-4817?issue=enCours&pause=non&piece=oui&depuis=liste',
      ),
      (
        BentoVivant.cleEtat(EtatCandidature.enExamen),
        'etat en examen',
        '/admin/personnes/candidatures?etat=enExamen&issue=enCours&pause=non',
      ),
      (BentoVivant.cleMessages, 'messages', Routes.adminCommunicationsMessages),
      (BentoVivant.cleCourriels, 'courriels', Routes.adminOperationsCourriels),
      (BentoVivant.cleDossiers, 'dossiers', Routes.adminPersonnesDossiers),
      (BentoVivant.cleDemandes, 'demandes', Routes.adminOperationsDemandes),
      (BentoVivant.cleEleves, 'eleves', Routes.adminOperationsRegroupements),
      (BentoVivant.cleCahiers, 'cahiers', Routes.adminPedagogieQualite),
      (
        BentoVivant.cleIncidents,
        'incidents',
        Routes.adminSecuriteAuditIncidents,
      ),
      (BentoVivant.cleEchus, 'acces echus', Routes.adminPersonnesComptesEchus),
    ]) {
      testWidgets('toucher la case ${cas.$2} ouvre ${cas.$3}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        await tester.pumpWidget(
          _routant(
            _surcharges(
              attentes: _attentes(),
              courriels: const EtatFileCourriels(
                parJour: 900,
                partis24h: 412,
                enAttente: 0,
                joursEstimes: 0,
              ),
              messages: 7,
            ),
          ),
        );
        await _vivre(tester);
        await tester.ensureVisible(find.byKey(cas.$1));
        await _vivre(tester, 5);
        await tester.tap(find.byKey(cas.$1));
        await _vivre(tester, 10);
        expect(find.text('ALLE ${cas.$3}'), findsOneWidget);
        // L'adresse du routeur dit la page et son filtre : un rechargement
        // rend le meme ecran (contrat §5).
        final BuildContext contexte = tester.element(
          find.text('ALLE ${cas.$3}'),
        );
        expect(
          GoRouter.of(contexte).routerDelegate.currentConfiguration.uri
              .toString(),
          cas.$3,
        );
      });
    }

    testWidgets('les gestes de Praxis : creneaux, pieces, messages', (
      WidgetTester tester,
    ) async {
      final v = t.admin.tableau.vivant;
      for (final (String, String) cas in <(String, String)>[
        (v.ouvrirCreneaux, Routes.adminPersonnesCreneauxEntretien),
        (
          v.verifierPieces(n: 3),
          '/admin/personnes/candidatures?issue=enCours&pause=non&piece=oui',
        ),
        (v.repondreMessages(n: 7), Routes.adminCommunicationsMessages),
      ]) {
        fixerVueCapture(tester, const Size(1440, 1600), 1);
        await tester.pumpWidget(
          _routant(
            _surcharges(
              attentes: _attentes(),
              courriels: const EtatFileCourriels(
                parJour: 900,
                partis24h: 412,
                enAttente: 0,
                joursEstimes: 0,
              ),
              messages: 7,
            ),
          ),
        );
        await _vivre(tester);
        await tester.tap(find.text(cas.$1));
        await _vivre(tester, 10);
        expect(find.text('ALLE ${cas.$2}'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('la semaine des creneaux : sept jours, pleins seulement ou un '
        'creneau est libre', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await _vivre(tester);
      for (int i = 0; i < 7; i++) {
        expect(find.byKey(BentoVivant.cleJour(i)), findsOneWidget);
      }
      Finder nombre(int jour, String n) => find.descendant(
        of: find.byKey(BentoVivant.cleJour(jour)),
        matching: find.text(n),
      );
      // Demain : deux creneaux libres. Apres-demain : un creneau reserve, qui
      // ne compte pas. Aujourd'hui : rien.
      expect(nombre(1, '2'), findsOneWidget);
      expect(nombre(2, '1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleJour(0)),
          matching: find.byType(Text),
        ),
        findsOneWidget,
        reason: 'un jour vide ne porte que sa lettre',
      );
    });

    testWidgets('sans lecture du recrutement : ni semaine ni geste invente', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1400), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleJour(0)), findsNothing);
      expect(find.text(t.admin.tableau.vivant.ouvrirCreneaux), findsNothing);
      expect(find.byKey(BentoVivant.cleCadenas), findsNothing);
    });

    testWidgets('le cadenas ferme le passage tant qu aucun creneau n est '
        'ouvert', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 1600), 1);
      await tester.pumpWidget(
        hote(_page(), surcharges: _surcharges(attentes: _attentes())),
      );
      await _vivre(tester);
      final Rect cadenas = tester.getRect(find.byKey(BentoVivant.cleCadenas));
      expect(
        cadenas.left,
        greaterThanOrEqualTo(
          tester
              .getRect(
                find.byKey(
                  BentoVivant.cleEtat(EtatCandidature.entretienAPlanifier),
                ),
              )
              .right,
        ),
      );
      expect(
        cadenas.right,
        lessThanOrEqualTo(
          tester
              .getRect(
                find.byKey(
                  BentoVivant.cleEtat(EtatCandidature.entretienPlanifie),
                ),
              )
              .left,
        ),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(attentes: _attentes(creneaux: 2)),
        ),
      );
      await _vivre(tester);
      expect(find.byKey(BentoVivant.cleCadenas), findsNothing);
      expect(find.text(t.admin.tableau.vivant.ouvrirCreneaux), findsNothing);
    });

    testWidgets('une seule page : ni titre d ecran ni liste de raccourcis sur '
        'ordinateur, aucun nombre affiche deux fois', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1800), 1);
      await tester.pumpWidget(
        hote(
          _page(),
          surcharges: _surcharges(
            attentes: _attentes(),
            courriels: const EtatFileCourriels(
              parJour: 900,
              partis24h: 412,
              enAttente: 0,
              joursEstimes: 0,
            ),
            messages: 7,
          ),
        ),
      );
      await _vivre(tester);
      expect(find.text(t.admin.tableau.titre), findsNothing);
      expect(find.text(t.admin.tableau.sousTitre), findsNothing);
      expect(find.text(t.admin.tableau.outilsTraitement), findsNothing);
      // Chaque libelle de compteur une fois, dans sa case.
      for (final (Key, String, String) cas in <(Key, String, String)>[
        (BentoVivant.cleDossiers, t.admin.tableau.dossiers, '0'),
        (BentoVivant.cleDemandes, t.admin.tableau.demandes, '4'),
        (BentoVivant.cleEleves, t.admin.tableau.foyers, '2'),
        (BentoVivant.cleCahiers, t.admin.tableau.rapports, '1'),
        (BentoVivant.cleIncidents, t.admin.tableau.incidents, '0'),
        (BentoVivant.cleEchus, t.admin.tableau.comptes, '0'),
      ]) {
        expect(find.text(cas.$2), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(cas.$1), matching: find.text(cas.$3)),
          findsOneWidget,
        );
      }
      // La personne de la file des pieces, et le dernier message non lu.
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.clePieces),
          matching: find.text('Personne De Test'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(BentoVivant.cleMessages),
          matching: find.text('Personne De Test · Premiere ligne'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ActiviteRecente), findsOneWidget);
      expect(find.text(t.admin.tableau.vivant.activiteTitre), findsOneWidget);
      expect(find.byKey(BentoVivant.cleDate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('au telephone : la liste de raccourcis reste, la date non', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(400, 4000), 1);
      await tester.pumpWidget(hote(_page(), surcharges: _surcharges()));
      await _vivre(tester);
      expect(find.text(t.admin.tableau.outilsTraitement), findsOneWidget);
      expect(find.byKey(BentoVivant.cleDate), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final (double, String) cas in <(double, String)>[
      (1440, 'quatre colonnes'),
      (820, 'deux colonnes'),
      (400, 'une colonne'),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.round()} points, ${sens.name} : ${cas.$2}, '
            'rien ne deborde', (WidgetTester tester) async {
          fixerVueCapture(tester, Size(cas.$1, 4200), 1);
          await tester.pumpWidget(
            hoteRoutant(
              depart: '/',
              direction: sens,
              surcharges: _surcharges(
                attentes: _attentes(),
                courriels: const EtatFileCourriels(
                  parJour: 900,
                  partis24h: 412,
                  enAttente: 0,
                  joursEstimes: 0,
                ),
                messages: 7,
              ),
              routes: <RouteBase>[
                GoRoute(path: '/', builder: (_, _) => _page()),
              ],
            ),
          );
          await _vivre(tester);
          expect(tester.takeException(), isNull);
          final Rect heros = tester.getRect(find.byKey(BentoVivant.cleHeros));
          final Rect pieces = tester.getRect(find.byKey(BentoVivant.clePieces));
          if (cas.$1 >= 1440) {
            // Meme rang ; la grille se retourne en arabe.
            expect(pieces.top, heros.top);
            if (sens == TextDirection.ltr) {
              expect(pieces.left, greaterThan(heros.right));
            } else {
              expect(pieces.right, lessThan(heros.left));
            }
          } else {
            expect(pieces.top, greaterThanOrEqualTo(heros.bottom));
          }
          // Praxis est assis sur le bord de sa case, du cote de la fin.
          final Rect praxis = tester.getRect(find.byType(PraxisVivant));
          expect(praxis.top, lessThan(heros.top));
          expect(praxis.bottom, greaterThan(heros.top));
          if (sens == TextDirection.ltr) {
            expect(praxis.center.dx, greaterThan(heros.center.dx));
          } else {
            expect(praxis.center.dx, lessThan(heros.center.dx));
          }
        });
      }
    }
  });

  group(
    'Capture : PE-VIVANT accueil de la direction',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final (Size, ThemeMode, String) cas in <(Size, ThemeMode, String)>[
        (const Size(1440, 1400), ThemeMode.light, 'accueil_1440_clair'),
        (const Size(1440, 1400), ThemeMode.dark, 'accueil_1440_sombre'),
        (const Size(820, 2000), ThemeMode.light, 'accueil_820_clair'),
        (const Size(820, 2000), ThemeMode.dark, 'accueil_820_sombre'),
        (const Size(400, 4200), ThemeMode.light, 'accueil_400_clair'),
        (const Size(400, 4200), ThemeMode.dark, 'accueil_400_sombre'),
      ]) {
        testWidgets(cas.$3, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              _page(),
              themeMode: cas.$2,
              surcharges: _surcharges(
                attentes: _attentes(),
                courriels: const EtatFileCourriels(
                  parJour: 900,
                  partis24h: 412,
                  enAttente: 0,
                  joursEstimes: 0,
                ),
                messages: 7,
              ),
            ),
          );
          await _vivre(tester, 60);
          debugPrint('PNG ${await capturer(tester, cas.$3)}');
        });
      }
    },
  );
}
