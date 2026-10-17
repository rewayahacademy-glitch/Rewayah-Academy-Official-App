// CTRL-DELAI-1 : un serveur muet ne bloque plus le controleur.
// Le port ne repond jamais ; l'horloge factice du testeur avance au-dela de
// `AppDelais.requeteMax` : l'envoi devient « non confirme », Reessayer est
// propose et « Plus tard » (ou « Retour ») redevient disponible (K-59).

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
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

/// Un port dont aucun appel ne recoit jamais de reponse.
class _PortMuet implements EnvoiCompteRendu {
  int transmissions = 0;
  int envois = 0;
  int observations = 0;

  @override
  Future<void> transmettreVisite(String seanceId) {
    transmissions++;
    return Completer<void>().future;
  }

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) {
    envois++;
    return Completer<void>().future;
  }

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) {
    observations++;
    return Completer<void>().future;
  }
}

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
  missionId: 'mission-A',
);

const String _controle = 'ecran-controle';

/// Monte [initiale] avec les memes constructeurs que `app_router.dart`, et
/// un Controle temoin pour « Plus tard ».
Future<void> _monter(
  WidgetTester tester,
  _PortMuet port,
  String initiale,
) async {
  tester.view.physicalSize = const Size(1280, 900);
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
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            _visite.seanceId: _visite,
          }),
        ),
        rosterControleProvider.overrideWith(
          (Ref _, String _) async => const <EleveRoster>[],
        ),
        envoiCompteRenduProvider.overrideWithValue(port),
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
  // Pas de pumpAndSettle : l'indicateur d'envoi tourne tant que rien ne
  // revient.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Au-dela du delai maximal, sur l'horloge factice.
Future<void> _attendreAuDelaDuDelai(WidgetTester tester) async {
  await tester.pump(AppDelais.requeteMax);
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('Compte rendu, serveur muet : non confirme, Reessayer, Plus '
      'tard de nouveau disponible', (WidgetTester tester) async {
    final _PortMuet port = _PortMuet();
    await _monter(
      tester,
      port,
      adresseCompteRendu(Routes.controleurCompteRendu, _visite.seanceId),
    );
    final r = t.controleur.compteRendu;
    expect(port.transmissions, 1);
    expect(find.text(r.visiteEnCours), findsOneWidget);

    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump(const Duration(milliseconds: 500));
    expect(port.envois, 1);
    expect(find.text(r.echecRien), findsNothing);

    await _attendreAuDelaDuDelai(tester);

    // Echec honnete, jamais un succes, jamais « en cours » pour toujours.
    expect(find.text(r.envoyeTitre), findsNothing);
    expect(find.text(r.echecRien), findsOneWidget);
    expect(r.echecRien, contains("n'est pas confirmé"));
    expect(find.text(r.visiteEnCours), findsNothing);
    expect(find.text(r.visiteEchec), findsOneWidget);
    expect(find.byKey(LigneTransmissionVisite.reessayerKey), findsOneWidget);

    // Reessayer : le choix est garde, l'envoi repart.
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump(const Duration(milliseconds: 500));
    expect(port.envois, 2);
    await _attendreAuDelaDuDelai(tester);
    expect(find.text(r.echecRien), findsOneWidget);

    // « Plus tard » ramene au Controle.
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pumpAndSettle();
    expect(find.text(_controle), findsOneWidget);
  });

  testWidgets('Observation, serveur muet : non confirme et Retour de nouveau '
      'disponible', (WidgetTester tester) async {
    final _PortMuet port = _PortMuet();
    await _monter(
      tester,
      port,
      adresseObservation(
        Routes.controleurObservation,
        ChoixCompteRendu.ajouterObservation,
        seanceId: _visite.seanceId,
      ),
    );
    Future<void> toucher(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(f);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await toucher(
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.pointPositif),
      ),
    );
    await toucher(find.text(t.commun.continuer).last);
    await toucher(
      find.byKey(ObservationControlePage.cleDomaine(DomaineObservation.climat)),
    );
    await toucher(find.text(t.commun.continuer).last);
    await toucher(
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.classeEntiere),
      ),
    );
    await toucher(find.text(t.commun.continuer).last);
    await tester.enterText(
      find.byKey(ObservationControlePage.texteKey),
      'Bonne ambiance.',
    );
    await tester.pump();
    await toucher(find.text(t.commun.continuer).last);
    await toucher(find.text(t.controleur.compteRendu.envoyer).last);
    expect(port.observations, 1);

    await _attendreAuDelaDuDelai(tester);

    final o = t.controleur.observation;
    expect(find.text(t.controleur.compteRendu.envoyeTitre), findsNothing);
    expect(find.text(o.echec), findsOneWidget);
    // « Retour » repond de nouveau : il ramene au texte, garde.
    await toucher(find.byType(DisqueRetour).last);
    expect(find.text(o.questionTexte), findsOneWidget);
    expect(find.text('Bonne ambiance.'), findsOneWidget);
  });
}
