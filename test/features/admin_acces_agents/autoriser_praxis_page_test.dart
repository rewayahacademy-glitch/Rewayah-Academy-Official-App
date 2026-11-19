// PX-OAUTH 2d : la page de consentement d'une connexion a Praxis.
//
// Ce que les cas prouvent (sur le vrai widget, la base est un double) :
//  - la demande dit QUI demande (le client et l'hote), ce que Praxis pourra et
//    ne pourra pas faire, et la duree ; un seul bouton plein, « Autoriser » ;
//  - la decision est un geste sensible : elle attend le serveur, n'est jamais
//    annoncee comme faite avant sa reponse, et ne renvoie le navigateur que
//    vers l'adresse de rappel de claude.ai (une reponse alteree n'ouvre rien) ;
//  - un refus du serveur faute de double verification se dit par la phrase vraie ;
//  - les etats loading, content, empty (inconnue), error et offline, et les
//    demandes qui ne s'ouvrent plus (deja traitee, expiree) ;
//  - 320 et 1440, texte x2, arabe : rien ne deborde, aucun mot coupe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/aller_adresse.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_acces_agents/autoriser_praxis_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/faux_service_autorisation_praxis.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const String _id = '5a130000-0000-4000-8000-000000000001';

Future<void> _monter(
  WidgetTester tester,
  FauxServiceAutorisationPraxis faux, {
  String demande = _id,
  List<String>? retours,
  List<Override> en = const <Override>[],
  Size taille = const Size(1440, 1000),
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/p',
      echelle: echelle,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: '/p',
          builder: (BuildContext _, GoRouterState _) =>
              AutoriserPraxisPage(demande: demande),
        ),
        GoRoute(
          path: Routes.adminSecuriteAuditAccesAgents,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('acces-agents')),
        ),
      ],
      surcharges: <Override>[
        serviceAutorisationPraxisProvider.overrideWithValue(faux),
        allerAdresseProvider.overrideWithValue(
          (String adresse) => retours?.add(adresse),
        ),
        ...en,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Les vraies polices : sans elles le moteur de test mesure avec une police
  // carree et « coupe » des mots que l'application ne coupe pas. Les langues
  // sont chargees une fois, avant les tests (setLocaleSync ensuite).
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('contenu', () {
    testWidgets(
      'qui demande, ce qu\'il pourra, la duree, un seul bouton plein',
      (tester) async {
        final FauxServiceAutorisationPraxis faux =
            FauxServiceAutorisationPraxis();
        await _monter(tester, faux);
        expect(find.text(t.admin.praxis.autoriser.titre), findsWidgets);
        expect(find.textContaining('Claude'), findsWidgets);
        expect(find.textContaining('claude.ai'), findsWidgets);
        expect(find.text(t.admin.praxis.pourraDetail), findsOneWidget);
        expect(find.text(t.admin.praxis.nePourraPasDetail), findsOneWidget);
        expect(find.text(t.admin.praxis.autoriser.duree), findsOneWidget);
        expect(find.byKey(ClesAutoriserPraxis.autoriser), findsOneWidget);
        expect(find.byKey(ClesAutoriserPraxis.refuser), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        expect(faux.lectures, <String>[_id]);
        // Rien n'est decide a l'ouverture.
        expect(faux.decisions, isEmpty);
      },
    );

    testWidgets(
      'un compte sans cote : la phrase vraie, pas de bouton Autoriser',
      (tester) async {
        await _monter(
          tester,
          FauxServiceAutorisationPraxis(
            demande: const DemandeAutorisationPraxis(
              etat: EtatDemandePraxis.enAttente,
              client: 'Claude',
              hote: 'claude.ai',
            ),
          ),
        );
        expect(find.text(t.admin.praxis.autoriser.sansCote), findsOneWidget);
        expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
        expect(find.byKey(ClesAutoriserPraxis.refuser), findsOneWidget);
      },
    );

    testWidgets('un nom de client vide est dit, pas laisse en blanc', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(
          demande: const DemandeAutorisationPraxis(
            etat: EtatDemandePraxis.enAttente,
            client: '',
            hote: 'claude.ai',
            peutAutoriser: true,
          ),
        ),
      );
      expect(
        find.textContaining(t.admin.praxis.autoriser.clientInconnu),
        findsOneWidget,
      );
    });
  });

  group('la decision', () {
    testWidgets('Autoriser : attend le serveur, puis renvoie vers claude.ai', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux =
          FauxServiceAutorisationPraxis();
      final List<String> retours = <String>[];
      await _monter(tester, faux, retours: retours);
      await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
      await tester.pumpAndSettle();
      expect(faux.decisions, <({String demande, bool accepter})>[
        (demande: _id, accepter: true),
      ]);
      expect(retours, <String>[retourAutorise]);
      expect(
        find.text(t.admin.praxis.autoriser.termineAutorisee),
        findsOneWidget,
      );
      // Plus de bouton Autoriser : la decision ne se rejoue pas.
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
    });

    testWidgets('Refuser : renvoie access_denied, rien d\'autorise', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux =
          FauxServiceAutorisationPraxis();
      final List<String> retours = <String>[];
      await _monter(tester, faux, retours: retours);
      await tester.tap(find.byKey(ClesAutoriserPraxis.refuser));
      await tester.pumpAndSettle();
      expect(faux.decisions.single.accepter, isFalse);
      expect(retours, <String>[retourRefuse]);
      expect(
        find.text(t.admin.praxis.autoriser.termineRefusee),
        findsOneWidget,
      );
    });

    testWidgets(
      'pendant l\'attente le bouton montre l\'attente et un second toucher n\'envoie rien',
      (tester) async {
        final Completer<void> attente = Completer<void>();
        final FauxServiceAutorisationPraxis faux = _FauxLent(attente);
        await _monter(tester, faux);
        await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
        await tester.pump();
        await tester.tap(
          find.byKey(ClesAutoriserPraxis.autoriser),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(ClesAutoriserPraxis.refuser),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(faux.decisions.length, 1);
        // Pas encore annoncee comme faite.
        expect(
          find.text(t.admin.praxis.autoriser.termineAutorisee),
          findsNothing,
        );
        attente.complete();
        await tester.pumpAndSettle();
        expect(
          find.text(t.admin.praxis.autoriser.termineAutorisee),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'une adresse de retour qui n\'est pas celle de claude.ai n\'ouvre rien',
      (tester) async {
        for (final String mauvaise in <String>[
          'https://evil.example/cb?code=${'a' * 64}',
          'https://claude.ai.evil.example/api/mcp/auth_callback?code=${'a' * 64}',
          'http://claude.ai/api/mcp/auth_callback?code=${'a' * 64}',
          'https://claude.ai/api/mcp/auth_callback?code=court',
          'javascript:alert(1)',
        ]) {
          final FauxServiceAutorisationPraxis faux =
              FauxServiceAutorisationPraxis(
                decision: DecisionAutorisationPraxis(redirection: mauvaise),
              );
          final List<String> retours = <String>[];
          await _monter(tester, faux, retours: retours);
          await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
          await tester.pumpAndSettle();
          expect(retours, isEmpty, reason: mauvaise);
          expect(
            find.text(t.admin.praxis.autoriser.erreurDecision),
            findsOneWidget,
          );
          expect(
            find.text(t.admin.praxis.autoriser.termineAutorisee),
            findsNothing,
          );
        }
      },
    );

    testWidgets('un refus de droit (42501) dit la double verification', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        erreurDecision: const PostgrestException(
          message: 'refus',
          code: '42501',
        ),
      );
      final List<String> retours = <String>[];
      await _monter(tester, faux, retours: retours);
      await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(retours, isEmpty);
      // La demande reste ouverte : on peut recommencer.
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsOneWidget);
    });

    testWidgets(
      'une panne du serveur : « rien n\'est autorise », la demande est relue',
      (tester) async {
        final FauxServiceAutorisationPraxis faux =
            FauxServiceAutorisationPraxis(erreurDecision: Exception('panne'));
        await _monter(tester, faux);
        await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
        await tester.pumpAndSettle();
        expect(
          find.text(t.admin.praxis.autoriser.erreurDecision),
          findsOneWidget,
        );
        expect(faux.lectures.length, 2);
      },
    );

    for (final (String cause, String Function() phrase) c
        in <(String, String Function())>[
          ('sans_cote', () => t.admin.praxis.autoriser.sansCote),
          ('deja_decidee', () => t.admin.praxis.autoriser.dejaDecidee),
          ('expiree', () => t.admin.praxis.autoriser.expiree),
          ('inconnue', () => t.admin.praxis.autoriser.inconnue),
        ]) {
      testWidgets('cause « ${c.$1} » de la base : sa phrase, rien ne part', (
        tester,
      ) async {
        final FauxServiceAutorisationPraxis faux =
            FauxServiceAutorisationPraxis(
              decision: DecisionAutorisationPraxis(erreur: c.$1),
            );
        final List<String> retours = <String>[];
        await _monter(tester, faux, retours: retours);
        await tester.tap(find.byKey(ClesAutoriserPraxis.autoriser));
        await tester.pumpAndSettle();
        expect(find.text(c.$2()), findsWidgets);
        expect(retours, isEmpty);
      });
    }
  });

  group('etats', () {
    testWidgets('chargement : un squelette, aucun bouton', (tester) async {
      final Completer<void> attente = Completer<void>();
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        attenteLecture: attente,
      );
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: '/p',
          routes: <RouteBase>[
            GoRoute(
              path: '/p',
              builder: (BuildContext _, GoRouterState _) =>
                  const AutoriserPraxisPage(demande: _id),
            ),
          ],
          surcharges: <Override>[
            serviceAutorisationPraxisProvider.overrideWithValue(faux),
          ],
        ),
      );
      await tester.pump();
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
      attente.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsOneWidget);
    });

    testWidgets('echec de lecture : la phrase vraie et de quoi relire', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        erreurLecture: Exception('panne'),
      );
      await _monter(tester, faux);
      expect(find.text(t.admin.praxis.autoriser.erreurLecture), findsWidgets);
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
    });

    testWidgets('hors ligne sans donnee : le bloc qui dit ce qui manque', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        erreurLecture: Exception('panne'),
      );
      await _monter(
        tester,
        faux,
        en: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      );
      expect(find.byKey(ClesAutoriserPraxis.sansDonnees), findsOneWidget);
      expect(find.text(t.admin.praxis.autoriser.sansDonnees), findsWidgets);
    });

    testWidgets('inconnue : la phrase vraie, rien a decider', (tester) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(
          demande: const DemandeAutorisationPraxis(
            etat: EtatDemandePraxis.inconnue,
          ),
        ),
      );
      expect(find.text(t.admin.praxis.autoriser.inconnue), findsOneWidget);
      expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
      expect(find.byKey(ClesAutoriserPraxis.versAcces), findsOneWidget);
    });

    testWidgets('un identifiant mal forme n\'appelle pas la base', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux =
          FauxServiceAutorisationPraxis();
      await _monter(tester, faux, demande: 'pas-un-identifiant');
      expect(faux.lectures, isEmpty);
      expect(find.text(t.admin.praxis.autoriser.inconnue), findsOneWidget);
      await _monter(tester, faux, demande: '');
      expect(faux.lectures, isEmpty);
    });

    testWidgets(
      'deja traitee et expiree : la phrase vraie, le chemin vers Acces des agents',
      (tester) async {
        for (final (EtatDemandePraxis etat, String phrase) c
            in <(EtatDemandePraxis, String)>[
              (EtatDemandePraxis.decidee, t.admin.praxis.autoriser.dejaDecidee),
              (EtatDemandePraxis.expiree, t.admin.praxis.autoriser.expiree),
            ]) {
          await _monter(
            tester,
            FauxServiceAutorisationPraxis(
              demande: DemandeAutorisationPraxis(
                etat: c.$1,
                client: 'Claude',
                hote: 'claude.ai',
              ),
            ),
          );
          expect(find.text(c.$2), findsOneWidget);
          expect(find.byKey(ClesAutoriserPraxis.autoriser), findsNothing);
          await tester.tap(find.byKey(ClesAutoriserPraxis.versAcces));
          await tester.pumpAndSettle();
          expect(find.text('acces-agents'), findsOneWidget);
        }
      },
    );
  });

  group('rendu', () {
    final List<(String, Size, double, TextDirection?, AppLocale)> cas =
        <(String, Size, double, TextDirection?, AppLocale)>[
          ('320, texte x1', const Size(320, 800), 1, null, AppLocale.fr),
          ('320, texte x2', const Size(320, 1400), 2, null, AppLocale.fr),
          ('1440', const Size(1440, 900), 1, null, AppLocale.fr),
          (
            'arabe, 320',
            const Size(320, 900),
            1,
            TextDirection.rtl,
            AppLocale.ar,
          ),
          (
            'arabe, 1440',
            const Size(1440, 900),
            1,
            TextDirection.rtl,
            AppLocale.ar,
          ),
        ];
    for (final (String, Size, double, TextDirection?, AppLocale) c in cas) {
      testWidgets('${c.$1} : rien ne deborde, aucun mot coupe', (tester) async {
        LocaleSettings.setLocaleSync(c.$5);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          FauxServiceAutorisationPraxis(
            demande: const DemandeAutorisationPraxis(
              etat: EtatDemandePraxis.enAttente,
              client: 'Claude',
              hote: 'claude.ai',
              peutAutoriser: true,
            ),
          ),
          taille: c.$2,
          echelle: c.$3,
          direction: c.$4,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        expect(
          motsCoupes(tester, find.byKey(ClesAutoriserPraxis.carte)),
          isEmpty,
        );
      });
    }
  });
}

/// Un service dont la decision attend [_attente].
class _FauxLent extends FauxServiceAutorisationPraxis {
  _FauxLent(this._attente);

  final Completer<void> _attente;

  @override
  Future<DecisionAutorisationPraxis> decider(
    String demande, {
    required bool accepter,
  }) async {
    decisions.add((demande: demande, accepter: accepter));
    await _attente.future;
    return DecisionAutorisationPraxis(redirection: retourAutorise);
  }
}
