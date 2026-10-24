import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';

import 'support/hote_d.dart';

void main() {
  late AssignationsMemoire depot;

  final ContentRange plage = ContentRange(
    resourceId: ressourceTest,
    debut: ayah1,
    fin: ayah2,
  );

  setUp(() {
    depot = AssignationsMemoire(
      'prof-1',
      maintenant: () => DateTime.utc(2026, 9, 20, 10),
    );
  });

  test('une revision se cree depuis la selection, sans formulaire', () async {
    final LearningAssignment travail = await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      contentRange: plage,
      purpose: IntentionPedagogique.aRenforcer,
    );

    // Tout ce que le systeme sait deja est prerempli : le groupe, la
    // ressource, la plage, l'auteur, l'instant. Rien n'a ete saisi a la main
    // hors l'intention.
    expect(travail.groupId, 'groupe-1');
    expect(travail.contentRange, plage);
    expect(travail.purpose, IntentionPedagogique.aRenforcer);
    expect(travail.createdBy, 'prof-1');
    expect(travail.startsAtUtc.isUtc, isTrue);
    expect(travail.status, StatutAssignation.aFaire);
    expect(travail.instructions, isNull);
  });

  test('le defaut est le groupe entier, pas un eleve', () async {
    final LearningAssignment travail = await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      purpose: IntentionPedagogique.aApprendre,
    );
    expect(travail.studentId, isNull);
    expect(travail.estDeGroupe, isTrue);
  });

  test('le vocabulaire d intention est celui des marqueurs', () {
    // Il n'existe pas un second vocabulaire pour les assignations : le champ
    // `purpose` EST une IntentionPedagogique.
    expect(
      IntentionPedagogique.values.map(
        (IntentionPedagogique intention) => intention.valeurSql,
      ),
      <String>['learn', 'review', 'reinforce', 'maintain', 'assessment'],
    );
  });

  test(
    '« Avant le prochain cours » ne rend jamais plus de trois actions',
    () async {
      for (int i = 0; i < 7; i++) {
        await depot.creerDepuisSelection(
          groupId: 'groupe-1',
          resourceId: ressourceTest,
          purpose: IntentionPedagogique.aRevoir,
          dueAtUtc: DateTime.utc(2026, 9, 21 + i),
        );
      }

      final List<LearningAssignment> aVenir = await depot.aVenir(
        groupId: 'groupe-1',
      );
      expect(aVenir.length, 3);
      // Le plus urgent d'abord.
      expect(aVenir.first.dueAtUtc, DateTime.utc(2026, 9, 21));
      expect(aVenir.last.dueAtUtc, DateTime.utc(2026, 9, 23));
    },
  );

  test('un travail sans echeance passe apres ceux qui en ont une', () async {
    await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      purpose: IntentionPedagogique.aRevoir,
    );
    final LearningAssignment urgent = await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      purpose: IntentionPedagogique.aRevoir,
      dueAtUtc: DateTime.utc(2026, 9, 21),
    );

    final List<LearningAssignment> aVenir = await depot.aVenir(
      groupId: 'groupe-1',
    );
    expect(aVenir.first.id, urgent.id);
  });

  test('un travail annule sort de « Avant le prochain cours »', () async {
    final LearningAssignment travail = await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      purpose: IntentionPedagogique.aRevoir,
    );
    await depot.changerStatut(travail.id, StatutAssignation.annule);

    expect(await depot.aVenir(groupId: 'groupe-1'), isEmpty);
    expect(
      (await depot.pourGroupe('groupe-1')).single.status,
      StatutAssignation.annule,
    );
  });

  test('le travail d un groupe ne fuit pas dans un autre', () async {
    await depot.creerDepuisSelection(
      groupId: 'groupe-1',
      resourceId: ressourceTest,
      purpose: IntentionPedagogique.aRevoir,
    );
    expect(await depot.pourGroupe('groupe-2'), isEmpty);
  });

  test('une echeance anterieure au debut est refusee', () {
    expect(
      () => LearningAssignment(
        id: 'a-1',
        groupId: 'groupe-1',
        resourceId: ressourceTest,
        purpose: IntentionPedagogique.aRevoir,
        startsAtUtc: DateTime.utc(2026, 9, 20),
        dueAtUtc: DateTime.utc(2026, 9, 19),
        createdBy: 'prof-1',
        status: StatutAssignation.aFaire,
      ),
      throwsAssertionError,
    );
  });

  test('un instant local est refuse : les contrats sont en UTC', () {
    expect(
      () => LearningAssignment(
        id: 'a-1',
        groupId: 'groupe-1',
        resourceId: ressourceTest,
        purpose: IntentionPedagogique.aRevoir,
        startsAtUtc: DateTime(2026, 9, 20),
        createdBy: 'prof-1',
        status: StatutAssignation.aFaire,
      ),
      throwsAssertionError,
    );
  });
}
