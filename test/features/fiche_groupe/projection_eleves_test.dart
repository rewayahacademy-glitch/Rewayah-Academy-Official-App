// PROJECTION-ELEVES (08/11/2026) : la page de reprise et le travail en cours
// de chaque eleve, pour son enseignant (`groupe_roster_enseignant`).
//
// Rouge sans le lot : sur `main` bd5c4e2f, `projectionElevesProvider` rend
// toujours une table vide hors demonstration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/preparation_seance.dart';
import 'package:rewayah_academy/features/fiche_groupe/projection_eleves_supabase.dart';

import '../../support/harnais.dart';
import '../../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;

const String _groupeId = 'g1';

class _Port implements PortProjectionsEleves {
  _Port(this.reponse, {this.panne = false});

  final Map<String, LigneProjectionEleve> reponse;
  final bool panne;
  final List<String> lues = <String>[];

  @override
  Future<Map<String, LigneProjectionEleve>> projectionsDeLaClasse(
    String groupeId,
  ) async {
    lues.add(groupeId);
    if (panne) throw StateError('reseau');
    return reponse;
  }
}

List<Override> _surcharges(PortProjectionsEleves port) => <Override>[
  serviceEnseignantProvider.overrideWithValue(
    FauxServiceEnseignant()
      ..groupesRendus = <GroupeEnseignant>[
        GroupeEnseignant(
          id: _groupeId,
          libelle: 'Perles du Coran',
          type: TypePublicGroupe.enfant,
          seuilMax: 5,
          creneau: const Creneau(jour: 3, heure: 17, fuseau: 'Europe/Paris'),
          nbMembres: 1,
          creeLe: DateTime.now(),
        ),
      ]
      ..membresRendus = <String, List<MembreSeance>>{
        _groupeId: <MembreSeance>[membreDeTest(niveau: 'Debutant')],
      },
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  groupeProvider(_groupeId).overrideWith((Ref _) async => null),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
  portProjectionsElevesProvider.overrideWithValue(port),
];

Future<void> _page(WidgetTester tester, PortProjectionsEleves port) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      FicheGroupePage(groupeId: _groupeId, onOuvrirEleve: (String _) {}),
      surcharges: _surcharges(port),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrirFiche(WidgetTester tester) async {
  await tester.tap(find.text('RA-0001'));
  await tester.pumpAndSettle();
}

String _page24() => t.tc.classe.fiche.page(page: 24);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture : page et intentions ; ligne illisible et intention inconnue '
      'ecartees', () {
    final Map<String, LigneProjectionEleve> lignes = projectionsDepuisReponse(
      <Object?>[
        <String, Object?>{
          'student_id': 'e1',
          'level': 'ignore',
          'curriculum_path': 'ignore',
          'resume_page': 24,
          'active_goals': <Object?>['learn', 'inconnu', null, 'review'],
        },
        <String, Object?>{'student_id': 'e2', 'resume_page': 0},
        <String, Object?>{'resume_page': 3},
        'pas une ligne',
      ],
    );
    expect(lignes.keys, <String>['e1', 'e2']);
    expect(lignes['e1']!.pageReprise, 24);
    expect(lignes['e1']!.intentions, <IntentionPedagogique>[
      IntentionPedagogique.aApprendre,
      IntentionPedagogique.aRevoir,
    ]);
    // Une page 0 n'est pas une page : rien n'est suppose.
    expect(lignes['e2']!.pageReprise, isNull);
    expect(lignes['e2']!.intentions, isEmpty);
    expect(projectionsDepuisReponse(null), isEmpty);
  });

  test('projection : « Page 24 » et les intentions sans doublon ; rien '
      'd invente sans valeur', () {
    final ProjectionEleve p = projectionDepuisLigne(
      const LigneProjectionEleve(
        studentId: 'e1',
        pageReprise: 24,
        intentions: <IntentionPedagogique>[
          IntentionPedagogique.aApprendre,
          IntentionPedagogique.aApprendre,
          IntentionPedagogique.aRevoir,
        ],
      ),
    );
    expect(p.pageReprise, _page24());
    expect(
      p.objectif,
      '${t.tc.parcours.intention.apprendre}${LibellesGroupe.separateur}'
      '${t.tc.parcours.intention.revoir}',
    );
    final ProjectionEleve vide = projectionDepuisLigne(
      const LigneProjectionEleve(studentId: 'e1'),
    );
    expect(vide.pageReprise, isNull);
    expect(vide.objectif, isNull);
    expect(vide.lectureEchouee, isFalse);
  });

  testWidgets('la liste des eleves dit la page de reprise lue au serveur', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(<String, LigneProjectionEleve>{
      'e1': const LigneProjectionEleve(studentId: 'e1', pageReprise: 24),
    });
    await _page(tester, port);
    expect(port.lues, contains(_groupeId));
    expect(
      find.textContaining(
        t.enseignant.ficheGroupe.repriseEleve(page: _page24()),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la fiche de l eleve dit sa reprise et son travail en cours', (
    WidgetTester tester,
  ) async {
    await _page(
      tester,
      _Port(<String, LigneProjectionEleve>{
        'e1': const LigneProjectionEleve(
          studentId: 'e1',
          pageReprise: 24,
          intentions: <IntentionPedagogique>[IntentionPedagogique.aRenforcer],
        ),
      }),
    );
    await _ouvrirFiche(tester);
    expect(
      find.text(
        t.enseignant.eleve.travailReprise(page: _page24().toLowerCase()),
      ),
      findsOneWidget,
    );
    expect(find.text(t.tc.parcours.intention.renforcer), findsOneWidget);
    expect(find.text(t.compte.nonDisponible), findsNothing);
  });

  testWidgets('aucune ligne rendue (un remplacant, par exemple) : « Non '
      'renseigne », jamais une erreur', (WidgetTester tester) async {
    await _page(tester, _Port(const <String, LigneProjectionEleve>{}));
    expect(find.textContaining(_page24()), findsNothing);
    await _ouvrirFiche(tester);
    expect(find.text(t.enseignant.eleve.nonRenseigne), findsWidgets);
    expect(find.text(t.compte.nonDisponible), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lecture en panne : la fiche dit « Non disponible », jamais '
      '« Non renseigne », et la Classe reste lisible', (
    WidgetTester tester,
  ) async {
    await _page(
      tester,
      _Port(const <String, LigneProjectionEleve>{}, panne: true),
    );
    expect(find.text('Khadija'), findsOneWidget);
    await _ouvrirFiche(tester);
    // L'objectif et le travail seulement : le niveau (« Debutant ») vient
    // d'une autre source et reste lu.
    expect(find.text(t.compte.nonDisponible), findsNWidgets(2));
    expect(find.text('Debutant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
