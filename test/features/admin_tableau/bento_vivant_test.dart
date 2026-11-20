// VIVANT : le haut de l'accueil de la direction en bento vivant.
//
// Donnees reelles uniquement : une case sans lecture ne s'affiche pas. Une
// case qui porte un nombre ouvre la liste deja filtree, empilee (contrat de
// navigation §2). La phrase de Praxis suit des regles ecrites.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_prevenir_candidats.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/vivant/niveau_eau.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/bento_vivant.dart';
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
  if (attentes != null)
    attentesRecrutementProvider.overrideWith((_) async => attentes),
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
        'pieces',
        '/admin/personnes/candidatures?issue=enCours&pause=non&piece=oui',
      ),
      (
        BentoVivant.cleEtat(EtatCandidature.enExamen),
        'etat en examen',
        '/admin/personnes/candidatures?etat=enExamen&issue=enCours&pause=non',
      ),
      (BentoVivant.cleMessages, 'messages', Routes.adminCommunicationsMessages),
      (BentoVivant.cleCourriels, 'courriels', Routes.adminOperationsCourriels),
      (
        BentoVivant.cleHeros,
        'Praxis (creneaux)',
        Routes.adminPersonnesCreneauxEntretien,
      ),
    ]) {
      testWidgets('toucher la case ${cas.$2} ouvre ${cas.$3}, empilee', (
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
        await tester.tap(find.byKey(cas.$1));
        await _vivre(tester, 10);
        expect(find.text('ALLE ${cas.$3}'), findsOneWidget);
        // Empilee : le retour ramene a l'accueil.
        final BuildContext contexte = tester.element(
          find.text('ALLE ${cas.$3}'),
        );
        expect(GoRouter.of(contexte).canPop(), isTrue);
      });
    }

    for (final (double, String) cas in <(double, String)>[
      (1440, 'quatre colonnes'),
      (820, 'deux colonnes'),
      (400, 'une colonne'),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.round()} points, ${sens.name} : ${cas.$2}, '
            'rien ne deborde', (WidgetTester tester) async {
          fixerVueCapture(tester, Size(cas.$1, 2600), 1);
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
        (const Size(1440, 1500), ThemeMode.light, 'accueil_1440_clair'),
        (const Size(1440, 1500), ThemeMode.dark, 'accueil_1440_sombre'),
        (const Size(820, 1900), ThemeMode.light, 'accueil_820_clair'),
        (const Size(820, 1900), ThemeMode.dark, 'accueil_820_sombre'),
        (const Size(400, 3000), ThemeMode.light, 'accueil_400_clair'),
        (const Size(400, 3000), ThemeMode.dark, 'accueil_400_sombre'),
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
