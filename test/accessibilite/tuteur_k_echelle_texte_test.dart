// Accessibilite des ecrans du lot K atteints par le tuteur (revue P2-10,
// constat 1) : « Mes groupes », « Espace groupe » (role tuteur), le bloc
// « Avant le prochain cours » et la porte d'observation. Chacun est monte a
// 390 et 1440, en clair et en sombre, de droite a gauche et a 200 pour cent de
// taille de texte : aucune exception de rendu (donc aucun debordement), et le
// contraste du texte rendu passe `textContrastGuideline`.
//
// La salle de classe en direct (`ClasseLivePage`) n'est pas dans cette liste :
// c'est la salle de l'enseignant et de l'eleve ; le tuteur n'y entre que par la
// porte d'observation, mesuree ici.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/tc_parcours/source_contenu_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_flux_academique/bloc_avant_prochain_cours.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/entree_observation_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';

import '../teaching_core/a/support/hote_tc_a.dart' show surchargesDemonstration;
import '../teaching_core/g/support/hote_tc_g.dart' show surchargesTcG;
import '../teaching_core/h/faux/faux_ports_externes.dart';

/// Un ecran mesure : son nom, son adresse de depart, ses routes, son type et
/// ses surcharges.
class _Ecran {
  const _Ecran(this.nom, this.type, this.routes, this.surcharges);

  final String nom;
  final Type type;
  final List<RouteBase> Function() routes;
  final List<Override> Function() surcharges;
}

GoRoute _seule(Widget Function() ecran) =>
    GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran());

List<Override> _surchargesBloc() => <Override>[
  portTravailAVenirProvider.overrideWithValue(
    TravailAVenir(
      FauxAssignations(
        travaux: <LearningAssignment>[
          LearningAssignment(
            id: 't1',
            groupId: 'g1',
            resourceId: 'res-coran',
            purpose: IntentionPedagogique.aRevoir,
            startsAtUtc: DateTime.utc(2026, 9, 20),
            createdBy: 'ens-1',
            status: StatutAssignation.aFaire,
          ),
        ],
      ),
      const ContenuSeanceIndisponible(),
    ),
  ),
];

final List<_Ecran> _ecrans = <_Ecran>[
  _Ecran(
    'Mes groupes',
    MesGroupesPage,
    () => <RouteBase>[_seule(() => const MesGroupesPage())],
    surchargesDemonstration,
  ),
  _Ecran(
    'Espace groupe (tuteur)',
    EspaceGroupePage,
    () => <RouteBase>[
      _seule(
        () => const EspaceGroupePage(
          groupeId: GroupesDemonstration.alFatiha,
          role: RoleEspaceGroupe.tuteur,
        ),
      ),
    ],
    surchargesDemonstration,
  ),
  _Ecran(
    'Avant le prochain cours',
    BlocAvantProchainCours,
    () => <RouteBase>[
      _seule(
        () => const Scaffold(
          body: SingleChildScrollView(
            child: BlocAvantProchainCours(groupeId: 'g1'),
          ),
        ),
      ),
    ],
    _surchargesBloc,
  ),
  _Ecran(
    'Porte d observation',
    EntreeObservationPage,
    () => <RouteBase>[_seule(() => const SizedBox.shrink()), ...routesTcG()],
    () => surchargesTcG(role: AppRole.guardian),
  ),
];

String _depart(_Ecran ecran) =>
    ecran.type == EntreeObservationPage ? RoutesTcG.versObservation('s1') : '/';

Future<void> _monter(
  WidgetTester tester,
  _Ecran ecran, {
  required Size taille,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: ecran.surcharges(),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          builder: (BuildContext _, Widget? enfant) =>
              Directionality(textDirection: sens, child: enfant!),
          routerConfig: GoRouter(
            initialLocation: _depart(ecran),
            routes: ecran.routes(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(ecran.type), findsOneWidget, reason: ecran.nom);
}

void main() {
  const List<Size> tailles = <Size>[Size(390, 844), Size(1440, 900)];

  group('RTL et 200 pour cent de taille de texte : aucun debordement', () {
    for (final _Ecran ecran in _ecrans) {
      for (final Size taille in tailles) {
        testWidgets('${ecran.nom} a ${taille.width.toInt()}', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            ecran,
            taille: taille,
            echelle: 2,
            sens: TextDirection.rtl,
          );
          expect(tester.takeException(), isNull, reason: ecran.nom);
        });
      }
    }
  });

  group('Contraste du texte en clair et en sombre', () {
    for (final _Ecran ecran in _ecrans) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets('${ecran.nom} en ${luminosite.name}', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle semantique = tester.ensureSemantics();
          await _monter(
            tester,
            ecran,
            taille: tailles.first,
            luminosite: luminosite,
          );
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantique.dispose();
        });
      }
    }
  });
}
