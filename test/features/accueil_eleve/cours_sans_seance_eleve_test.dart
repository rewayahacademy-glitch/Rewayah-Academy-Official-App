// Defaut du 30/10/2026, cote eleve : une Classe nee pendant son creneau n'a
// pas de seance en base ; l'accueil la montre quand meme (cours du moment lu
// sur l'horloge du serveur) et « Rejoindre » passe par le concierge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/cours_du_moment.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance.dart';
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';

import '../../support/harnais.dart';

/// Un vendredi a 19:25 : le cours de 19:00 (90 min) est commence.
final DateTime _debut = DateTime(2026, 10, 30, 19);
final DateTime _maintenant = DateTime(2026, 10, 30, 19, 25);

Map<String, dynamic> _ligne({String? seance}) => <String, dynamic>{
  'groupe_id': 'g-garcons',
  'groupe_libelle': 'Garcons, vendredi 19 h',
  'teacher_id': 't1',
  'teacher_first_name': 'Aminata',
  'session_id': seance,
  'debut_utc': _debut.toUtc().toIso8601String(),
  'fin_prevue_utc': _debut
      .add(const Duration(minutes: 90))
      .toUtc()
      .toIso8601String(),
};

class _Concierge implements PortConcierge {
  final List<String> appels = <String>[];

  @override
  Future<String?> seanceARejoindre(String groupeId) async {
    appels.add(groupeId);
    return 'seance-creee';
  }
}

void main() {
  group('avecCoursSansSeanceEleve', () {
    test('le cours sans seance entre dans la liste', () {
      final List<Seance> r = avecCoursSansSeanceEleve(
        const <Seance>[],
        <Map<String, dynamic>>[_ligne()],
      );
      final Seance cours = r.single;
      expect(cours.aCreer, isTrue);
      expect(cours.groupeId, 'g-garcons');
      expect(cours.enseignantId, 't1');
      expect(cours.enseignantPrenom, 'Aminata');
      expect(cours.debut.isAtSameMomentAs(_debut), isTrue);
      expect(cours.duree, const Duration(minutes: 90));
    });

    test('une ligne qui porte sa seance, ou une seance au meme instant, '
        'n ajoute rien', () {
      expect(
        avecCoursSansSeanceEleve(const <Seance>[], <Map<String, dynamic>>[
          _ligne(seance: 's1'),
        ]),
        isEmpty,
      );
      final Seance creee = Seance(
        id: 's1',
        debut: _debut,
        fin: _debut.add(const Duration(minutes: 90)),
        statut: StatutSeance.planifiee,
        eleveId: 'e1',
        elevePrenom: 'Khadija',
        eleveIdentifiant: 'STUD-KB-000003',
        enseignantId: 't1',
        enseignantPrenom: 'Aminata',
        enseignantIdentifiant: 'TEACH-AD-000001',
      );
      expect(
        avecCoursSansSeanceEleve(
          <Seance>[creee],
          <Map<String, dynamic>>[_ligne()],
        ).single.id,
        's1',
      );
    });
  });

  testWidgets('accueil : en direct sans seance, Rejoindre passe par le '
      'concierge', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Concierge concierge = _Concierge();
    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.eleve,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.eleve,
            builder: (BuildContext _, GoRouterState _) =>
                AccueilElevePage(horloge: () => _maintenant),
          ),
          GoRoute(
            path: Routes.salle,
            builder: (BuildContext _, GoRouterState etat) =>
                Text('salle:${(etat.extra! as BilletSalle).sessionId}'),
          ),
        ],
        surcharges: <Override>[
          servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
          servicePriereProvider.overrideWithValue(FauxServicePriere()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          coursDuMomentProvider.overrideWith(
            (Ref _) async => <Map<String, dynamic>>[_ligne()],
          ),
          portConciergeProvider.overrideWithValue(concierge),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(PastilleEtatSeance), findsOneWidget);
    expect(find.text(t.eleve.accueil.avec(prenom: 'Aminata')), findsOneWidget);

    await tester.tap(find.text(t.eleve.accueil.rejoindre));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(concierge.appels, <String>['g-garcons']);
    expect(find.text('salle:seance-creee'), findsOneWidget);
  });
}
