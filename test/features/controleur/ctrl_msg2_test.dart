// CTRL-MSG-2 (revue C1-CTRL-R) :
// - M1 : l'ecran « seance inconnue » du compte rendu et de l'observation
//   n'est plus une impasse : « Ecrire a l'administration » ouvre les
//   Echanges, « Revenir au controle » ramene au Controle ;
// - M2 : a 320 px et texte x2 (densite 1), l'echec d'envoi de l'observation
//   et du complement ne deborde plus et ne coupe plus le bouton, en LTR et en
//   RTL ;
// - m2 : le complement et les Echanges ont leur test « serveur muet ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/controleur/complement_rapport_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

const String _controle = 'ecran-controle';
const String _echanges = 'ecran-echanges';

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
  missionId: 'mission-A',
);

final RapportControle _parent = RapportControle(
  id: 'rapport-parent',
  missionId: 'mission-A',
  classe: 'Al-Badr',
  enseignant: 'Sayyid Karim',
  debut: DateTime(2026, 9, 24, 17),
  dureeObservee: const Duration(minutes: 20),
  statut: StatutRapport.envoye,
  choix: ChoixCompteRendu.rienASignaler,
);

/// Le port du compte rendu : tout echoue tout de suite.
class _PortEchec implements EnvoiCompteRendu {
  @override
  Future<void> transmettreVisite(String seanceId) async {}

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async =>
      throw StateError('pas de reponse');

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async => throw StateError('pas de reponse');
}

/// Le port de l'historique : le complement echoue tout de suite, ou ne
/// recoit jamais de reponse.
class _PortHistorique implements PortHistorique {
  _PortHistorique({required this.muet});

  final bool muet;
  int essais = 0;

  @override
  Future<List<RapportControle>> rapports() async => <RapportControle>[];

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) {
    essais++;
    if (muet) return Completer<ComplementRapport>().future;
    return Future<ComplementRapport>.error(StateError('pas de reponse'));
  }
}

/// Le port des Echanges : le fil s'ouvre, l'envoi ne repond jamais.
class _EchangesMuet implements PortEchanges {
  int envois = 0;

  static final FilEchange _fil = FilEchange(
    id: 'fil-test',
    missionId: 'mission-test',
    classe: 'Classe Test',
    debutMission: DateTime(2026, 9, 24, 17),
    etat: EtatFilEchange.enAttente,
    messages: const <MessageEchange>[],
  );

  @override
  Future<List<FilEchange>> fils() async => <FilEchange>[_fil];

  @override
  Future<FilEchange> filDeMission(String missionId) async => _fil;

  @override
  Future<void> envoyer(String filId, String texte) {
    envois++;
    return Completer<void>().future;
  }
}

/// Monte [initiale] avec les constructeurs de `app_router.dart`, un Controle
/// temoin et des Echanges temoins (liste et fil d'une mission).
Future<GoRouter> _monterRoutes(WidgetTester tester, String initiale) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: initiale,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.controleur,
        builder: (BuildContext _, GoRouterState _) => const Text(_controle),
      ),
      GoRoute(
        path: Routes.controleurEchanges,
        builder: (BuildContext _, GoRouterState etat) => Text(
          '$_echanges ${etat.uri.queryParameters['mission'] ?? 'liste'}',
        ),
      ),
      GoRoute(
        path: Routes.controleurCompteRendu,
        builder: (BuildContext _, GoRouterState etat) =>
            CompteRenduControlePage(
              seanceId: etat.uri.queryParameters['seance'],
            ),
      ),
      GoRoute(
        path: Routes.controleurObservation,
        builder: (BuildContext _, GoRouterState etat) =>
            ObservationControlePage(
              seanceId: etat.uri.queryParameters['seance'],
              choix: choixObservationDepuis(
                etat.uri.queryParameters,
                etat.extra,
              ),
            ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        missionControleProvider.overrideWith((Ref _) async => null),
        envoiCompteRenduProvider.overrideWithValue(_PortEchec()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

/// Monte [ecran] a 320 x 700, densite 1, texte x2, dans la direction voulue.
Future<void> _monter320x2(
  WidgetTester tester,
  Widget ecran, {
  required TextDirection direction,
  List<Override> surcharges = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(textDirection: direction, child: app!),
          ),
          home: ecran,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Le rectangle de [f] tient entier dans la fenetre de 320 x 700.
void _dansLaFenetre(WidgetTester tester, Finder f) {
  final Rect r = tester.getRect(f);
  expect(r.left, greaterThanOrEqualTo(0), reason: '$f');
  expect(r.right, lessThanOrEqualTo(320), reason: '$f');
  expect(r.top, greaterThanOrEqualTo(0), reason: '$f');
  expect(r.bottom, lessThanOrEqualTo(700), reason: '$f');
}

/// Le debut de [f] est dans la fenetre : sa premiere ligne se lit sans
/// defiler.
void _debutALEcran(WidgetTester tester, Finder f) {
  final Rect r = tester.getRect(f);
  expect(r.top, greaterThanOrEqualTo(0), reason: '$f');
  expect(r.top, lessThan(700 - 40), reason: '$f');
}

void main() {
  group('M1 : la seance inconnue a deux sorties', () {
    for (final (String nom, String adresse) in <(String, String)>[
      (
        'compte rendu',
        adresseCompteRendu(Routes.controleurCompteRendu, 'seance-inconnue'),
      ),
      (
        'observation',
        adresseObservation(
          Routes.controleurObservation,
          ChoixCompteRendu.ajouterObservation,
          seanceId: 'seance-inconnue',
        ),
      ),
    ]) {
      testWidgets('$nom : Ecrire a l administration ouvre les Echanges', (
        WidgetTester tester,
      ) async {
        await _monterRoutes(tester, adresse);
        final r = t.controleur.compteRendu;
        expect(find.text(r.visiteInconnue), findsOneWidget);
        // m1 : l'aide ne dit plus « reste transmise » puis « non confirme ».
        expect(find.text(r.visiteInconnueAide), findsOneWidget);
        expect(r.visiteInconnueAide, isNot(contains('reste transmise')));
        expect(r.visiteInconnueAide, contains('ne peut pas le confirmer'));
        final Finder ecrire = find.byKey(VisiteInconnue.ecrireAdminKey);
        expect(ecrire, findsOneWidget);
        expect(find.text(r.ecrireAdmin), findsOneWidget);
        await _toucher(tester, ecrire);
        // La mission de la visite n'est pas connue : la liste des fils.
        expect(find.text('$_echanges liste'), findsOneWidget);
      });

      testWidgets('$nom : Revenir au controle ramene au Controle', (
        WidgetTester tester,
      ) async {
        await _monterRoutes(tester, adresse);
        final Finder revenir = find.text(t.controleur.compteRendu.revenir);
        expect(revenir, findsOneWidget);
        await _toucher(tester, revenir);
        expect(find.text(_controle), findsOneWidget);
      });
    }
  });

  group('M2 : echec d envoi a 320 px, texte x2, densite 1', () {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('observation sans texte, ${direction.name} : rien ne '
          'deborde, bouton et echec entiers', (WidgetTester tester) async {
        await _monter320x2(
          tester,
          ObservationControlePage(seanceId: _visite.seanceId),
          direction: direction,
          surcharges: <Override>[
            visitesObserveesProvider.overrideWith(
              () => VisitesObservees(<String, CompteRenduEnSuspens>{
                _visite.seanceId: _visite,
              }),
            ),
            envoiCompteRenduProvider.overrideWithValue(_PortEchec()),
          ],
        );
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.cleNature(NatureObservation.pointPositif),
          ),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.cleDomaine(DomaineObservation.interaction),
          ),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.clePersonne(
              PersonneConcernee.classeEntiere,
            ),
          ),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        await _toucher(tester, find.text(t.commun.continuer).last);
        final Finder envoyer = find.text(t.controleur.compteRendu.envoyer);
        await _toucher(tester, envoyer.last);

        // Avant la correction : « A RenderFlex overflowed by 60 pixels on
        // the bottom », signale par le testeur, et le bouton coupe.
        expect(tester.takeException(), isNull);
        // Isole dans l'autre sens que l'interface (COUPE-MOTS-3b) : le texte
        // rendu contient la phrase.
        final Finder echec = find.textContaining(
          t.controleur.observation.echecSansTexte,
        );
        expect(echec, findsOneWidget);
        // L'echec est amene a l'ecran par son debut (il est plus haut que la
        // fenetre a texte x2).
        _debutALEcran(tester, echec);
        // Le bouton reste entier dans la fenetre, pour reessayer.
        _dansLaFenetre(tester, envoyer.last);
        // Le recapitulatif reste lisible : la question se retrouve en
        // remontant le corps.
        final Finder question = find.textContaining(
          t.controleur.observation.questionRecap,
        );
        await tester.ensureVisible(question);
        await tester.pumpAndSettle();
        _dansLaFenetre(tester, question);
        expect(tester.takeException(), isNull);
      });

      testWidgets('complement, ${direction.name} : rien ne deborde, bouton '
          'et echec entiers', (WidgetTester tester) async {
        await _monter320x2(
          tester,
          ComplementRapportPage(
            rapport: _parent,
            onRetour: () {},
            onTermine: (RapportControle _) {},
          ),
          direction: direction,
          surcharges: <Override>[
            portHistoriqueProvider.overrideWithValue(
              _PortHistorique(muet: false),
            ),
          ],
        );
        await _toucher(
          tester,
          find.byKey(ComplementRapportPage.cleMotif(MotifComplement.precision)),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        await tester.enterText(
          find.byKey(ComplementRapportPage.texteKey),
          'La Classe a fini plus tot.',
        );
        await tester.pumpAndSettle();
        await _toucher(tester, find.text(t.commun.continuer).last);
        await _toucher(tester, find.text(t.controleur.complement.envoyer).last);

        expect(tester.takeException(), isNull);
        final Finder echec = find.text(t.controleur.complement.echec);
        expect(echec, findsOneWidget);
        _debutALEcran(tester, echec);
        _dansLaFenetre(tester, find.text(t.commun.reessayer).last);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('m2 : serveur muet', () {
    Future<void> auDelaDuDelai(WidgetTester tester) async {
      await tester.pump(AppDelais.requeteMax);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('Complement : non confirme, texte garde, Reessayer', (
      WidgetTester tester,
    ) async {
      final _PortHistorique port = _PortHistorique(muet: true);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[portHistoriqueProvider.overrideWithValue(port)],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: ComplementRapportPage(
                rapport: _parent,
                onRetour: () {},
                onTermine: (RapportControle _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _toucher(tester, find.text(t.commun.continuer).last);
      await tester.enterText(
        find.byKey(ComplementRapportPage.texteKey),
        'Un fait nouveau.',
      );
      await tester.pumpAndSettle();
      await _toucher(tester, find.text(t.commun.continuer).last);
      final Finder envoyer = find.text(t.controleur.complement.envoyer).last;
      await tester.ensureVisible(envoyer);
      await tester.pumpAndSettle();
      await tester.tap(envoyer);
      // Pas de pumpAndSettle : l'indicateur tourne tant que rien ne revient.
      await tester.pump(const Duration(milliseconds: 500));
      expect(port.essais, 1);
      expect(find.text(t.controleur.complement.echec), findsNothing);

      await auDelaDuDelai(tester);

      final c = t.controleur.complement;
      expect(find.text(c.envoyeTitre), findsNothing);
      expect(find.text(c.echec), findsOneWidget);
      expect(c.echec, contains("n'est pas confirmé"));
      // Reessayer repart, avec le meme texte.
      final Finder reessayer = find.text(t.commun.reessayer).last;
      await tester.ensureVisible(reessayer);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(reessayer);
      await tester.pump(const Duration(milliseconds: 500));
      expect(port.essais, 2);
      await auDelaDuDelai(tester);
      expect(find.text(c.echec), findsOneWidget);
      expect(find.textContaining('Un fait nouveau.'), findsWidgets);
    });

    testWidgets('Echanges : le message passe non envoye, avec Reessayer', (
      WidgetTester tester,
    ) async {
      final _EchangesMuet port = _EchangesMuet();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[portEchangesProvider.overrideWithValue(port)],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const EchangesControleurPage(
                missionOuverte: 'mission-test',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final e = t.controleur.echanges;
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour.');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pump(const Duration(milliseconds: 500));
      expect(port.envois, 1);
      expect(find.text(e.enCours), findsOneWidget);

      await auDelaDuDelai(tester);

      expect(find.text(e.enCours), findsNothing);
      expect(find.text(e.envoye), findsNothing);
      expect(find.text(e.echec), findsOneWidget);
      expect(find.text(e.reessayer), findsOneWidget);
      expect(find.text('Bonjour.'), findsOneWidget);
    });
  });
}
