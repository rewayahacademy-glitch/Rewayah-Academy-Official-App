import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_outils/masquage.dart';

import 'support/hote_d.dart';

void main() {
  ContentPosition ayah(int numero) => ContentPosition.ayah(
    resourceId: ressourceTest,
    sourate: 1,
    ayah: numero,
  );

  ContentRange plage(int debut, int fin) => ContentRange(
    resourceId: ressourceTest,
    debut: ayah(debut),
    fin: ayah(fin),
  );

  group('masquer puis reveler', () {
    test('rien n est masque au depart', () {
      expect(PlanMasquage.aucun.estVide, isTrue);
      expect(PlanMasquage.aucun.estMasque(ayah(1)), isFalse);
    });

    test('une plage masquee cache ses bornes et ce qu il y a entre elles', () {
      final PlanMasquage plan = PlanMasquage.aucun.masquer(plage(2, 4));
      expect(plan.estMasque(ayah(1)), isFalse);
      expect(plan.estMasque(ayah(2)), isTrue);
      expect(plan.estMasque(ayah(3)), isTrue);
      expect(plan.estMasque(ayah(4)), isTrue);
      expect(plan.estMasque(ayah(5)), isFalse);
    });

    test('reveler decouvre sans detruire le masquage', () {
      final PlanMasquage masque = PlanMasquage.aucun.masquer(plage(2, 4));
      final PlanMasquage revele = masque.reveler(plage(2, 4));

      expect(revele.estMasque(ayah(3)), isFalse);
      expect(
        revele.plages,
        masque.plages,
        reason: 'la plage reste masquee, elle est seulement ouverte : '
            'refermer ne doit pas obliger a la redesigner',
      );

      expect(revele.toutRefermer().estMasque(ayah(3)), isTrue);
    });

    test('masquer de nouveau une plage revelee la referme', () {
      final PlanMasquage plan = PlanMasquage.aucun
          .masquer(plage(2, 4))
          .reveler(plage(2, 4))
          .masquer(plage(2, 4));
      expect(plan.estMasque(ayah(3)), isTrue);
      expect(plan.plages.length, 1, reason: 'aucun doublon de plage');
    });

    test('reveler une plage qui n est pas masquee ne fait rien', () {
      final PlanMasquage plan = PlanMasquage.aucun.reveler(plage(2, 4));
      expect(plan, PlanMasquage.aucun);
    });

    test('demasquer retire la plage et sa revelation', () {
      final PlanMasquage plan = PlanMasquage.aucun
          .masquer(plage(2, 4))
          .reveler(plage(2, 4))
          .demasquer(plage(2, 4));
      expect(plan.estVide, isTrue);
      expect(plan.revelees, isEmpty);
    });

    test('deux plages masquees vivent independamment', () {
      final PlanMasquage plan = PlanMasquage.aucun
          .masquer(plage(2, 3))
          .masquer(plage(6, 7))
          .reveler(plage(2, 3));
      expect(plan.estMasque(ayah(2)), isFalse);
      expect(plan.estMasque(ayah(6)), isTrue);

      expect(plan.toutReveler().estMasque(ayah(6)), isFalse);
    });

    test('un masquage ne deborde pas sur une autre ressource', () {
      final PlanMasquage plan = PlanMasquage.aucun.masquer(plage(2, 4));
      const ContentPosition ailleurs = ContentPosition.ayah(
        resourceId: 'res-autre',
        sourate: 1,
        ayah: 3,
      );
      expect(plan.estMasque(ailleurs), isFalse);
    });

    test('un plan de masquage ne copie rien du support', () {
      final PlanMasquage plan = PlanMasquage.aucun.masquer(plage(2, 4));
      // Il ne porte que des plages, c'est-a-dire des references.
      expect(plan.plages.single.resourceId, ressourceTest);
      expect(plan.plages.single.debut.typeAncrage, TypeAncrage.ayah);
    });
  });
}
