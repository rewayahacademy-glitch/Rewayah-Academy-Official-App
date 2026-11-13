// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : « Demander une pause d'un mois »,
// montee par le VRAI routeur. La regle se lit avant la demande ; les mois
// proposes disent ceux qui vont a la direction ; le serveur refuse, l'ecran dit
// pourquoi en mots simples. Cinq etats : chargement, contenu, vide, erreur,
// hors ligne. Le tuteur et l'adulte voient l'entree ; l'enfant jamais.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/calendrier/port_calendrier.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/pause_famille/entree_pause.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/calendrier_pauses_faux.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../historique/support_historique.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  FausPauses port, {
  String route = '',
  SessionState Function()? session,
  bool horsLigne = false,
  bool attendre = true,
  List<Override> plus = const <Override>[],
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    route.isEmpty ? Routes.tuteurPause('eleve-mariam') : route,
    source: FausseSourceSession((session ?? _tuteur)()),
    taille: const Size(390, 3200),
    surcharges: <Override>[
      portPausesProvider.overrideWithValue(port),
      horsLigneProvider.overrideWith(
        (Ref ref) => Stream<bool>.value(horsLigne),
      ),
      ...plus,
    ],
  );
  if (attendre) await tester.pump(const Duration(milliseconds: 400));
  return routeur;
}

SessionState _tuteur() => sessionActive(AppRole.guardian);
SessionState _adulte() => sessionActive(AppRole.student);

/// L'adulte est celui que le serveur dit autonome (capacite C-24) : le port de
/// la capacite le dit pour `p-student`, l'enfant n'est pas dans la liste.
final Override _capaciteAdulte = portCapaciteEleveProvider.overrideWithValue(
  const PortCapaciteEleveFactice(autonomes: <String>{'p-student'}),
);
SessionState _enfant() => sessionActive(AppRole.student);

void main() {
  group('la lecture et la regle', () {
    testWidgets(
      'la regle se lit AVANT la demande, avec les valeurs du serveur',
      (WidgetTester tester) async {
        final FausPauses port = FausPauses();
        await _monter(tester, port);
        final r = t.pause.regle;
        expect(find.text(t.pause.titre), findsWidgets);
        expect(
          find.text(t.pause.sousTitre(dePrenom: 'de Mariam')),
          findsOneWidget,
        );
        expect(find.text(t.pause.regleTitre), findsOneWidget);
        expect(find.text(r.moisEntier), findsOneWidget);
        expect(
          find.text(LibellesGroupe.insecable(r.preavis(jours: 7))),
          findsOneWidget,
        );
        expect(
          find.text(
            LibellesGroupe.insecable(r.plafond(mois: 2, fenetre: 12, delai: 3)),
          ),
          findsOneWidget,
        );
        expect(find.text(r.placeGardee), findsOneWidget);
        expect(find.text(r.dateLimite), findsOneWidget);
        // Aucun mot d'argent, aucun mot interdit.
        expect(find.textContaining('geler'), findsNothing);
        expect(find.textContaining('abonnement'), findsNothing);
        expect(find.textContaining('€'), findsNothing);
        expect(find.textContaining(r'$'), findsNothing);
        expect(port.lues, <String>['eleve-mariam']);
      },
    );

    testWidgets('douze mois, ceux qui vont a la direction le disent', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FausPauses(
          lecture: lecturePausesServeur(
            aLaDirection: <int>{3},
            etats: <int, String>{1: 'acceptee', 2: 'demandee'},
          ),
        ),
      );
      expect(find.text('décembre 2026'), findsOneWidget);
      expect(find.text('novembre 2027'), findsOneWidget);
      expect(find.text(t.pause.moisDansRegle), findsWidgets);
      expect(
        find.text(LibellesGroupe.insecable(t.pause.moisALaDirection(delai: 3))),
        findsOneWidget,
      );
      expect(find.text(t.pause.moisDejaAccepte), findsOneWidget);
      expect(find.text(t.pause.moisDejaDemande), findsOneWidget);
    });

    testWidgets('sans mois choisi : une phrase, pas de bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, FausPauses());
      expect(find.text(t.pause.choisirPourDemander), findsOneWidget);
      expect(find.text(t.pause.demander), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('les pauses : etat, reponse de la direction avec son motif', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FausPauses(
          lecture: lecturePausesServeur(
            pauses: <Object?>[
              pauseServeur(
                id: 'a',
                statut: 'demandee',
                debut: '2027-02-01',
                fin: '2027-02-28',
                annulable: true,
                repondreAvant: '2026-11-15',
              ),
              pauseServeur(
                id: 'b',
                statut: 'refusee',
                debut: '2027-03-01',
                fin: '2027-03-31',
                motifDecision: 'Deux pauses ont déjà été accordées',
              ),
              pauseServeur(
                id: 'c',
                statut: 'acceptee',
                type: 'exception',
                debut: '2026-11-10',
                fin: '2026-11-20',
              ),
            ],
          ),
        ),
      );
      expect(find.text(t.pause.statut.demandee), findsOneWidget);
      expect(find.text(t.pause.statut.refusee), findsOneWidget);
      expect(find.text(t.pause.statut.acceptee), findsOneWidget);
      expect(
        find.textContaining(
          t.pause.reponseAvant(date: '15 novembre 2026'),
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Deux pauses ont déjà été accordées'),
        findsOneWidget,
      );
      expect(find.textContaining(t.pause.exceptionAccordee), findsOneWidget);
      // Annuler : seulement la pause qui n'a pas commence.
      expect(find.text(t.pause.annuler(mois: 'février 2027')), findsOneWidget);
      expect(find.textContaining('Annuler la pause de mars'), findsNothing);
    });
  });

  group('la demande', () {
    testWidgets('choisir un mois, demander : acceptee tout de suite', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses();
      await _monter(tester, port);
      await tester.tap(find.text('décembre 2026'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(t.pause.demander), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await tester.tap(find.text(t.pause.demander));
      await tester.pump(const Duration(milliseconds: 400));
      expect(port.demandes, <(String, DateTime)>[
        ('eleve-mariam', DateTime(2026, 12)),
      ]);
      expect(
        find.text(t.pause.reponse.acceptee(mois: 'décembre 2026')),
        findsOneWidget,
      );
      // La lecture est relue : une seconde lecture du serveur.
      expect(port.lues.length, 2);
    });

    testWidgets('au-dela du plafond : transmise a la direction', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses(
        lecture: lecturePausesServeur(aLaDirection: <int>{0}),
        reponseDemande: <String, Object?>{
          'id': 'n',
          'statut': 'demandee',
          'debut': '2026-12-01',
          'fin': '2026-12-31',
          'repondre_avant': '2026-11-15',
        },
      );
      await _monter(tester, port);
      await tester.tap(find.text('décembre 2026'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(t.pause.demander));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text(LibellesGroupe.insecable(t.pause.reponse.demandee(delai: 3))),
        findsOneWidget,
      );
    });

    testWidgets(
      'refus du preavis : dit en mots simples, avec les jours du serveur',
      (WidgetTester tester) async {
        final FausPauses port = FausPauses(
          refusDemande: const PauseRefusee(MotifRefusPause.preavis),
        );
        await _monter(tester, port);
        await tester.tap(find.text('décembre 2026'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(t.pause.demander));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text(LibellesGroupe.insecable(t.pause.refus.preavis(jours: 7))),
          findsOneWidget,
        );
        expect(
          find.textContaining(LibellesGroupe.insecable('au moins 7 jours')),
          findsWidgets,
        );
        expect(port.demandes, isEmpty);
      },
    );

    testWidgets('un refus inconnu : une phrase et quoi faire (K-59)', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses(
        refusDemande: const PauseRefusee(MotifRefusPause.inconnu),
      );
      await _monter(tester, port);
      await tester.tap(find.text('décembre 2026'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(t.pause.demander));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.pause.refus.inconnu), findsOneWidget);
    });

    testWidgets('annuler une pause avant son debut', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses(
        lecture: lecturePausesServeur(
          pauses: <Object?>[
            pauseServeur(
              id: 'a',
              statut: 'acceptee',
              debut: '2027-02-01',
              fin: '2027-02-28',
              annulable: true,
            ),
          ],
        ),
      );
      await _monter(tester, port);
      await tester.tap(find.text(t.pause.annuler(mois: 'février 2027')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(port.annulees, <String>['a']);
    });
  });

  group('les cinq etats', () {
    testWidgets('chargement : un squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(tester, FausPauses(attente: attente));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.pause.regleTitre), findsNothing);
      attente.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.pause.regleTitre), findsOneWidget);
    });

    testWidgets('vide : aucune pause, aucun mois', (WidgetTester tester) async {
      await _monter(
        tester,
        FausPauses(
          lecture: <String, Object?>{
            ...lecturePausesServeur(),
            'mois_proposes': <Object?>[],
          },
        ),
      );
      expect(find.text(t.pause.demandesVide), findsOneWidget);
      expect(find.text(t.pause.aucunMois), findsOneWidget);
    });

    testWidgets('erreur : la phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses(erreurLecture: StateError('reseau'));
      await _monter(tester, port);
      expect(find.text(t.pause.erreur), findsWidgets);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      port.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.pause.regleTitre), findsOneWidget);
    });

    testWidgets('hors ligne : le bandeau le dit, le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FausPauses(erreurLecture: StateError('reseau')),
        horsLigne: true,
      );
      expect(find.text(t.pause.erreur), findsWidgets);
      expect(find.byType(OfflineBanner), findsWidgets);
    });

    testWidgets('sans port : la page dit que les pauses sont indisponibles', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.tuteurPause('eleve-mariam'),
        source: FausseSourceSession(_tuteur()),
        taille: const Size(390, 1200),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.pause.indisponible), findsOneWidget);
    });

    testWidgets(
      'le serveur refuse l autre foyer : la page ne montre rien de la lecture',
      (WidgetTester tester) async {
        await _monter(
          tester,
          FausPauses(
            erreurLecture: const PauseRefusee(MotifRefusPause.nonAutorise),
          ),
        );
        expect(find.text(t.pause.regleTitre), findsNothing);
        expect(find.text(t.pause.erreur), findsWidgets);
      },
    );
  });

  group('l entree du tuteur', () {
    testWidgets(
      'sous la carte de suivi de l enfant choisi, elle mene a la page de cet enfant',
      (WidgetTester tester) async {
        final FausPauses port = FausPauses();
        await monterHistorique(
          tester,
          depart: Routes.tuteurSuivi,
          taille: const Size(390, 3200),
          autres: <Override>[portPausesProvider.overrideWithValue(port)],
        );
        expect(find.byKey(EntreePause.ligneKey), findsOneWidget);
        await tester.tap(find.byKey(EntreePause.ligneKey));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        // La page de l'enfant choisi s'ouvre (la lecture est celle de cet enfant).
        expect(find.text(t.pause.regleTitre), findsOneWidget);
        expect(port.lues, <String>[FoyersFictifs.a1.id]);
      },
    );

    testWidgets('sans port, pas d entree', (WidgetTester tester) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(390, 3200),
      );
      expect(find.byKey(EntreePause.ligneKey), findsNothing);
    });
  });

  group('l adulte, et jamais l enfant', () {
    testWidgets('l adulte demande pour lui-meme', (WidgetTester tester) async {
      final FausPauses port = FausPauses(
        lecture: lecturePausesServeur(prenom: null),
      );
      await _monter(
        tester,
        port,
        route: Routes.elevePause,
        session: _adulte,
        plus: <Override>[_capaciteAdulte],
      );
      expect(find.text(t.pause.regleTitre), findsOneWidget);
      expect(find.textContaining('Pause de'), findsNothing);
      expect(port.lues, <String>['p-student']);
    });

    testWidgets('un enfant qui ouvre l adresse est renvoye au Suivi', (
      WidgetTester tester,
    ) async {
      final FausPauses port = FausPauses();
      final GoRouter routeur = await _monter(
        tester,
        port,
        route: Routes.elevePause,
        session: _enfant,
      );
      expect(
        routeur.routeInformationProvider.value.uri.path,
        Routes.eleveSuivi,
      );
      expect(find.text(t.pause.regleTitre), findsNothing);
      expect(port.lues, isEmpty);
    });

    testWidgets('l entree est montree a l adulte, jamais a l enfant', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FausPauses(),
        route: Routes.eleveSuivi,
        session: _adulte,
        plus: <Override>[_capaciteAdulte],
      );
      expect(find.byKey(EntreePause.ligneKey), findsOneWidget);
      expect(find.text(t.pause.entree), findsOneWidget);
    });

    testWidgets('pas d entree chez l enfant', (WidgetTester tester) async {
      await _monter(
        tester,
        FausPauses(),
        route: Routes.eleveSuivi,
        session: _enfant,
      );
      expect(find.byKey(EntreePause.ligneKey), findsNothing);
    });
  });
}
