import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/features/revue_groupe/anomalies_revue.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';

import '../support/harnais.dart';

const String _groupe = 'g1';

FauxServiceEnseignant _service({
  List<MembreSeance>? membres,
  Object? erreur,
  Duration? delai,
}) => FauxServiceEnseignant()
  ..membresRendus = <String, List<MembreSeance>>{
    _groupe:
        membres ??
        <MembreSeance>[
          membreDeTest(prenom: 'Khadija'),
          membreDeTest(studentId: 'e2', identifiant: 'RA-e2', prenom: 'Bilal'),
        ],
  }
  ..groupesRendus = <GroupeEnseignant>[
    GroupeEnseignant(
      id: _groupe,
      libelle: 'Perles du Coran',
      type: TypePublicGroupe.enfant,
      seuilMax: 5,
      creneau: const Creneau(jour: 3, heure: 17, fuseau: 'Europe/Paris'),
      nbMembres: 2,
      creeLe: DateTime(2026, 10, 1),
    ),
  ]
  ..erreurLecture = erreur
  ..delai = delai;

List<Override> _surcharges(
  FauxServiceEnseignant service, {
  List<AnomalieRevue>? anomalies,
}) => <Override>[
  serviceEnseignantProvider.overrideWithValue(service),
  if (anomalies != null)
    anomaliesGroupeProvider.overrideWith(
      (Ref ref, String groupeId) async => anomalies,
    ),
];

void _telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceEnseignant service,
  List<AnomalieRevue>? anomalies,
}) async {
  _telephone(tester);
  await tester.pumpWidget(
    hote(
      const RevueGroupePage(groupeId: _groupe),
      surcharges: _surcharges(service, anomalies: anomalies),
    ),
  );
}

void main() {
  group('Une Classe qui n est pas la sienne', () {
    testWidgets('on le dit, au lieu de « rien ne demande votre attention »', (
      WidgetTester tester,
    ) async {
      // La liste des Classes de l'enseignant est lue et ne contient pas g1.
      final FauxServiceEnseignant service = _service()
        ..groupesRendus = const <GroupeEnseignant>[];
      await _monter(tester, service: service);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.ficheGroupe.introuvable), findsOneWidget);
      expect(find.text(t.enseignant.revue.aucuneAnomalie), findsNothing);
    });
  });

  group('ENS-08 : le vide est l etat normal', () {
    testWidgets('rien ne demande votre attention, et aucun bouton ne le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, service: _service());
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.revue.aucuneAnomalie), findsOneWidget);
      // Une seule phrase calme (UX_REVIEW_04 ligne 10) : aucun detail.
      expect(
        tester.widget<EmptyState>(find.byType(EmptyState)).invitation,
        isNull,
      );
      // Rien a faire, donc aucun bouton : proposer une action serait inviter a
      // inventer un probleme.
      // Seul le retour de l'Espace Classe (decision EN-RC).
      expect(find.byType(ActionPrincipale), findsOneWidget);
      expect(
        find.widgetWithText(ActionPrincipale, t.commun.retour),
        findsOneWidget,
      );
      expect(find.text(t.commun.reessayer), findsNothing);
      // Et surtout : aucune carte, aucune colonne, aucun tiret en attendant.
      expect(find.byType(AppCard), findsNothing);
      expect(find.text('—'), findsNothing);
      expect(find.text('-'), findsNothing);
    });

    testWidgets(
      'elle ne resume pas le groupe : ce travail est celui d ENS-07',
      (WidgetTester tester) async {
        await _monter(tester, service: _service());
        await tester.pumpAndSettle();

        // Aucun prenom de membre n'apparait : la revue parle d'anomalies, pas
        // d'effectif.
        expect(find.text('Khadija'), findsNothing);
        expect(find.text('Bilal'), findsNothing);
      },
    );
  });

  group('ENS-08 : les anomalies, quand la source en rendra', () {
    testWidgets(
      'une ligne par anomalie dans un seul groupe, son type dit par un mot',
      (WidgetTester tester) async {
        await _monter(
          tester,
          service: _service(),
          anomalies: const <AnomalieRevue>[
            AnomalieRevue(
              type: TypeAnomalieRevue.transfertPropose,
              studentId: 'e2',
              eleve: 'Bilal',
            ),
            AnomalieRevue(
              type: TypeAnomalieRevue.gateAVenir,
              studentId: 'e1',
              eleve: 'Khadija',
              detail: 'Palier de fin de cycle dans deux semaines.',
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byType(GroupeReglages), findsOneWidget);
        expect(find.text(t.enseignant.revue.typeGate), findsOneWidget);
        expect(find.text(t.enseignant.revue.typeTransfert), findsOneWidget);
        expect(
          find.textContaining('Palier de fin de cycle dans deux semaines.'),
          findsOneWidget,
        );
        // L'enseignant signale, l'academie tranche : aucune action de decision
        // n'est rendue, meme pas grisee.
        // Seul le retour de l'Espace Classe (decision EN-RC).
        expect(find.byType(ActionPrincipale), findsOneWidget);
        expect(
          find.widgetWithText(ActionPrincipale, t.commun.retour),
          findsOneWidget,
        );
        expect(find.text(t.enseignant.revue.pasDeDecision), findsOneWidget);
      },
    );

    test('une anomalie qui vise un ancien membre ne s affiche pas', () {
      final List<AnomalieRevue> retenues = anomaliesDuGroupe(
        anomalies: const <AnomalieRevue>[
          AnomalieRevue(
            type: TypeAnomalieRevue.gateAVenir,
            studentId: 'parti',
            eleve: 'Ancien membre',
          ),
          AnomalieRevue(
            type: TypeAnomalieRevue.horsCorridor,
            studentId: 'e1',
            eleve: 'Khadija',
          ),
        ],
        membres: <MembreSeance>[membreDeTest(prenom: 'Khadija')],
      );

      // Demander un regard sur un eleve qui n'est plus dans le groupe serait
      // demander un regard que l'enseignant ne peut plus porter.
      expect(retenues, hasLength(1));
      expect(retenues.single.studentId, 'e1');
    });

    test('l ordre est celui des types, puis le nom', () {
      final List<AnomalieRevue> retenues = anomaliesDuGroupe(
        anomalies: const <AnomalieRevue>[
          AnomalieRevue(
            type: TypeAnomalieRevue.reorientationProposee,
            studentId: 'e2',
            eleve: 'Bilal',
          ),
          AnomalieRevue(
            type: TypeAnomalieRevue.gateAVenir,
            studentId: 'e3',
            eleve: 'Zayd',
          ),
          AnomalieRevue(
            type: TypeAnomalieRevue.gateAVenir,
            studentId: 'e1',
            eleve: 'Aisha',
          ),
        ],
        membres: <MembreSeance>[
          membreDeTest(prenom: 'Aisha'),
          membreDeTest(studentId: 'e2', identifiant: 'RA-e2', prenom: 'Bilal'),
          membreDeTest(studentId: 'e3', identifiant: 'RA-e3', prenom: 'Zayd'),
        ],
      );

      // Ce qui a une echeance passe devant ce qui attend une decision, et a
      // egalite l'ordre est alphabetique : il ne depend jamais de l'ordre dans
      // lequel la source a rendu ses lignes.
      expect(retenues.map((AnomalieRevue a) => a.eleve), <String>[
        'Aisha',
        'Zayd',
        'Bilal',
      ]);
    });
  });

  group('ENS-08 : les etats de lecture', () {
    testWidgets('chargement : un squelette, jamais un rond qui tourne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        service: _service(delai: const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(t.enseignant.revue.aucuneAnomalie), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.revue.aucuneAnomalie), findsOneWidget);
    });

    testWidgets('erreur : c est elle qui parle quand la lecture echoue', (
      WidgetTester tester,
    ) async {
      // C'est le cas reel d'aujourd'hui : les tables de progression et
      // d'evaluation ne sont pas toutes appliquees, et `mon_groupe_detail`
      // refuse un groupe qui n'est pas celui de l'enseignant. L'ecran ne doit
      // surtout pas repondre « rien ne demande votre attention » a une lecture
      // qui a echoue.
      await _monter(
        tester,
        service: _service(erreur: Exception('42P01 relation absente')),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.revue.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.enseignant.revue.aucuneAnomalie), findsNothing);
    });
  });
}
