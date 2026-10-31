// Defaut du 30/10/2026 : une Classe creee pendant son creneau (« Garcons,
// vendredi 19 h ») n'apparaissait ni sur « Aujourd'hui » ni sur « Classes »,
// faute de seance en base. Le cours du moment, lu sur l'horloge du serveur
// (`cours_du_moment_mes_classes`), y entre sans seance ; « Rejoindre » passe
// par le concierge, qui la cree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance.dart';
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Vendredi 30/10/2026, 19:25 a Paris (18:25 UTC) : le cours de 19:00 dure
/// 90 minutes, la Classe est nee a 18:15 UTC.
final DateTime _debut = DateTime.utc(2026, 10, 30, 18);
final DateTime _maintenant = DateTime.utc(2026, 10, 30, 18, 25).toLocal();

Map<String, dynamic> _ligne(
  String groupe, {
  String? seance,
}) => <String, dynamic>{
  'groupe_id': groupe,
  'groupe_libelle': 'Garcons, vendredi 19 h',
  'type_public': 'adulte',
  'seuil_max': 6,
  'nb_membres': 3,
  'session_id': seance,
  'debut_utc': _debut.toIso8601String(),
  'fin_prevue_utc': _debut.add(const Duration(minutes: 90)).toIso8601String(),
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
  group('avecCoursSansSeance', () {
    final SeanceEnseignant existante = SeanceEnseignant(
      id: 's-autre',
      debut: _debut.add(const Duration(days: 3)).toLocal(),
      fin: _debut.add(const Duration(days: 3, minutes: 45)).toLocal(),
      statut: StatutSeance.planifiee,
      nbParticipants: 2,
      cahierDepose: false,
      groupeId: 'g-autre',
    );

    test('le cours sans seance entre dans la liste, trie par debut', () {
      final List<SeanceEnseignant> r = avecCoursSansSeance(
        <SeanceEnseignant>[existante],
        <Map<String, dynamic>>[_ligne('g-garcons')],
      );
      expect(r.map((SeanceEnseignant s) => s.groupeId), <String>[
        'g-garcons',
        'g-autre',
      ]);
      final SeanceEnseignant cours = r.first;
      expect(cours.aCreer, isTrue);
      expect(cours.statut, StatutSeance.planifiee);
      expect(cours.debut.isAtSameMomentAs(_debut), isTrue);
      expect(cours.duree, const Duration(minutes: 90));
      expect(cours.nbParticipants, 3);
      expect(cours.groupeLibelle, 'Garcons, vendredi 19 h');
      expect(cours.id, isNot(existante.id));
    });

    test('une ligne qui porte sa seance est deja dans la liste', () {
      final List<SeanceEnseignant> r = avecCoursSansSeance(
        <SeanceEnseignant>[existante],
        <Map<String, dynamic>>[_ligne('g-autre', seance: 's-autre')],
      );
      expect(r, <SeanceEnseignant>[existante]);
    });

    test(
      'pas de doublon avec une seance de la meme Classe au meme instant',
      () {
        final SeanceEnseignant creee = SeanceEnseignant(
          id: 's-garcons',
          debut: _debut.toLocal(),
          fin: _debut.add(const Duration(minutes: 90)).toLocal(),
          statut: StatutSeance.planifiee,
          nbParticipants: 3,
          cahierDepose: false,
          groupeId: 'g-garcons',
        );
        final List<SeanceEnseignant> r = avecCoursSansSeance(
          <SeanceEnseignant>[creee],
          <Map<String, dynamic>>[_ligne('g-garcons')],
        );
        expect(r.single.id, 's-garcons');
      },
    );
  });

  group('Classes : le cours en cours sans seance', () {
    final GroupeEnseignant demo = DonneesEnseignantDemo.groupes().first;
    final GroupeEnseignant garcons = GroupeEnseignant(
      id: 'g-garcons',
      libelle: 'Garcons, vendredi 19 h',
      type: demo.type,
      seuilMax: 6,
      creneau: demo.creneau,
      nbMembres: 3,
      creeLe: demo.creeLe,
    );
    final List<GroupeEnseignant> groupes = <GroupeEnseignant>[
      ...DonneesEnseignantDemo.groupes(),
      garcons,
    ];

    Future<_Concierge> monter(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final _Concierge concierge = _Concierge();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantClasses,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.enseignantClasses,
              builder: (BuildContext _, GoRouterState _) =>
                  const MesClassesPage(),
            ),
            GoRoute(
              path: Routes.salle,
              builder: (BuildContext _, GoRouterState etat) =>
                  Text('salle:${(etat.extra! as BilletSalle).sessionId}'),
            ),
          ],
          surcharges: <Override>[
            maintenantJourneeProvider.overrideWithValue(() => _maintenant),
            groupesEnseignantProvider.overrideWith((Ref _) async => groupes),
            seancesEnseignantProvider.overrideWith(
              (Ref _) async => avecCoursSansSeance(
                const <SeanceEnseignant>[],
                <Map<String, dynamic>>[_ligne(garcons.id)],
              ),
            ),
            cahiersEnRetardProvider.overrideWith(
              (Ref _) async => const <CahierEnRetard>[],
            ),
            portConciergeProvider.overrideWithValue(concierge),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      return concierge;
    }

    testWidgets('en tete, en direct, Rejoindre passe par le concierge', (
      WidgetTester tester,
    ) async {
      final _Concierge concierge = await monter(tester);
      final Finder aLaUne = find.byKey(
        const ValueKey<String>('classes-a-la-une'),
      );
      expect(
        find.descendant(of: aLaUne, matching: find.text(garcons.libelle)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: aLaUne, matching: find.byType(PastilleEtatSeance)),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);

      await tester.tap(find.byKey(const ValueKey<String>('classes-rejoindre')));
      await tester.pumpAndSettle();
      expect(concierge.appels, <String>[garcons.id]);
      expect(find.text('salle:seance-creee'), findsOneWidget);
    });
  });
}
