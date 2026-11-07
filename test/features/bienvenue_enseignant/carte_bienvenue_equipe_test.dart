// SALLE-3-ACCUEIL : la carte « Bienvenue dans l'equipe » dit ce qu'il reste a
// configurer, d'apres les lectures du serveur, et rien d'autre. Chaque ligne
// disparait quand elle est faite ; une lecture qui echoue ou qui manque n'affiche
// pas sa ligne (on ne dit pas « a configurer » sur un doute).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/carte_bienvenue_equipe.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/reste_a_configurer.dart';
import 'package:rewayah_academy/features/paiements_recus/etat_coordonnees.dart';

import '../../support/harnais.dart';

const String _id = 'prof-1';
const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _id,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

MesCoordonneesVersement _versement({required bool complet}) =>
    MesCoordonneesVersement(
      deviseCible: 'USD',
      champs: const <ChampDemande>[],
      enregistre: complet,
      complet: complet,
    );

const PrerequisEnseignant _tousAFaire = PrerequisEnseignant(
  photo: false,
  langues: false,
  fuseau: false,
  disponibilites: false,
);
const PrerequisEnseignant _toutFait = PrerequisEnseignant(
  photo: true,
  langues: true,
  fuseau: true,
  disponibilites: true,
);

Future<void> _monter(
  WidgetTester tester, {
  Future<MesCoordonneesVersement> Function()? versement,
  PrerequisEnseignant? prerequis = _tousAFaire,
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      echelle: echelle,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) => const Scaffold(
            body: SingleChildScrollView(child: CarteBienvenueEquipe()),
          ),
        ),
        GoRoute(
          path: Routes.comptePaiementsRecus,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('page-paiements')),
        ),
        GoRoute(
          path: Routes.enseignantCreneaux,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('page-creneaux')),
        ),
      ],
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
        mesCoordonneesVersementProvider.overrideWith(
          (Ref _) => (versement ?? () async => _versement(complet: false))(),
        ),
        prerequisEnseignantProvider.overrideWithValue(prerequis),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Finder _ligne(ResteAConfigurer r) =>
    find.byKey(CarteBienvenueEquipe.cleLigne(r));

void main() {
  testWidgets('tout reste a faire : cinq lignes, versement en premier', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    final r = t.enseignant.bienvenue.equipe;
    expect(find.text(r.titre), findsOneWidget);
    expect(find.text(r.intro), findsOneWidget);
    expect(find.text(r.remplacement), findsOneWidget);
    expect(_ligne(ResteAConfigurer.versement), findsOneWidget);
    expect(_ligne(ResteAConfigurer.disponibilites), findsOneWidget);
    for (final ResteAConfigurer x in ResteAConfigurer.values) {
      expect(_ligne(x), findsOneWidget, reason: x.name);
    }
    expect(
      tester.getTopLeft(_ligne(ResteAConfigurer.versement)).dy,
      lessThan(tester.getTopLeft(_ligne(ResteAConfigurer.photo)).dy),
    );

    await tester.tap(_ligne(ResteAConfigurer.versement));
    await tester.pumpAndSettle();
    expect(find.text('page-paiements'), findsOneWidget);
  });

  testWidgets('les disponibilites menent aux creneaux', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.tap(_ligne(ResteAConfigurer.disponibilites));
    await tester.pumpAndSettle();
    expect(find.text('page-creneaux'), findsOneWidget);
  });

  testWidgets('une ligne faite disparait', (WidgetTester tester) async {
    await _monter(
      tester,
      versement: () async => _versement(complet: true),
      prerequis: _toutFait,
    );
    final r = t.enseignant.bienvenue.equipe;
    for (final ResteAConfigurer x in ResteAConfigurer.values) {
      expect(_ligne(x), findsNothing, reason: x.name);
    }
    expect(find.text(r.toutPret), findsOneWidget);
    expect(find.text(r.intro), findsNothing);
    // Le rappel des remplacements reste.
    expect(find.text(r.remplacement), findsOneWidget);
  });

  testWidgets(
    'contre-epreuve : une lecture qui echoue n\'affiche pas sa ligne',
    (WidgetTester tester) async {
      await _monter(
        tester,
        versement: () async => throw const CapaciteIndisponible('versement'),
        prerequis: null,
      );
      for (final ResteAConfigurer x in ResteAConfigurer.values) {
        expect(_ligne(x), findsNothing, reason: x.name);
      }
      expect(find.text(t.enseignant.bienvenue.equipe.titre), findsOneWidget);
    },
  );

  for (final (String nom, Size taille, double echelle) cas
      in <(String, Size, double)>[
        ('320 px, texte x2', const Size(320, 640), 2),
        ('1440 px', const Size(1440, 900), 1),
      ]) {
    testWidgets('rien ne deborde : ${cas.$1}', (WidgetTester tester) async {
      await _monter(tester, taille: cas.$2, echelle: cas.$3);
      expect(tester.takeException(), isNull);
      expect(find.text(t.enseignant.bienvenue.equipe.titre), findsOneWidget);
    });
  }
}
