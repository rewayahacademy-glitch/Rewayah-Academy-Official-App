import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';

import 'support/hote_d.dart';

void main() {
  late AnnotationsMemoire depot;

  TraitVectoriel trait(String id) => TraitVectoriel(
    id: id,
    ancrage: ayah1,
    outil: OutilTrait.stylet,
    points: const <PointNormalise>[
      PointNormalise(0.1, 0.1),
      PointNormalise(0.9, 0.9),
    ],
  );

  MarqueurSemantique marqueur(String id, IntentionPedagogique intention) =>
      MarqueurSemantique(
        id: id,
        plage: ContentRange(
          resourceId: ressourceTest,
          debut: ayah1,
          fin: ayah2,
        ),
        intention: intention,
      );

  setUp(() {
    depot = AnnotationsMemoire(
      'prof-1',
      maintenant: () => DateTime.utc(2026, 9, 20, 10),
    );
  });

  tearDown(() async => depot.liberer());

  group('la source reste immuable', () {
    test('une couche ne porte que des references, jamais du contenu', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        sessionId: 'seance-1',
        portee: PorteeAnnotation.seance,
      ))!;

      expect(couche.resourceId, ressourceTest);
      expect(couche.estVide, isTrue);
      expect(couche.majAUtc.isUtc, isTrue);
      // Les seuls champs de la couche sont des identifiants, une portee, des
      // traits vectoriels et des marqueurs : il n'y a nulle part ou glisser une
      // copie du support.
      expect(couche.traits, isEmpty);
      expect(couche.marqueurs, isEmpty);
    });

    test('un trait est une suite de fractions, pas une image', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      await depot.ajouterTrait(couche.id, trait('t-1'));

      final AnnotationLayer relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.traits.single.points.first.x, 0.1);
      expect(relue.traits.single.ancrage, ayah1);
    });
  });

  group('les trois portees', () {
    test('trois portees donnent trois couches distinctes', () async {
      final Set<String> identifiants = <String>{};
      for (final PorteeAnnotation portee in PorteeAnnotation.values) {
        final AnnotationLayer couche = (await depot.couche(
          resourceId: ressourceTest,
          sessionId: 'seance-1',
          portee: portee,
        ))!;
        identifiants.add(couche.id);
      }
      expect(identifiants.length, 3);
    });

    test('la fin de seance emporte le temporaire et la seance, pas le reste', () async {
      for (final PorteeAnnotation portee in PorteeAnnotation.values) {
        final AnnotationLayer couche = (await depot.couche(
          resourceId: ressourceTest,
          sessionId: 'seance-1',
          portee: portee,
        ))!;
        await depot.ajouterTrait(couche.id, trait('t-${portee.valeurSql}'));
      }
      expect(depot.couches.length, 3);

      depot.fermerSeance('seance-1');

      expect(depot.couches.length, 1);
      expect(depot.couches.single.portee, PorteeAnnotation.enregistree);
      expect(depot.couches.single.traits.single.id, 't-enregistree');
    });

    test('une couche hors classe n a pas de seance', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(couche.sessionId, isNull);
    });
  });

  group('marqueurs de plage', () {
    test('un marqueur est une metadonnee de plage', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      await depot.poserMarqueur(
        couche.id,
        marqueur('m-1', IntentionPedagogique.aRevoir),
      );

      final AnnotationLayer relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.marqueurs.single.intention, IntentionPedagogique.aRevoir);
      expect(relue.marqueurs.single.plage.debut, ayah1);
      expect(
        relue.traits,
        isEmpty,
        reason: 'un marqueur n est pas un dessin : il ne cree aucun trait',
      );
    });

    test('remarquer la meme plage remplace l intention', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      await depot.poserMarqueur(
        couche.id,
        marqueur('m-1', IntentionPedagogique.aRevoir),
      );
      await depot.poserMarqueur(
        couche.id,
        marqueur('m-2', IntentionPedagogique.aRenforcer),
      );

      final AnnotationLayer relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.marqueurs.length, 1);
      expect(relue.marqueurs.single.intention, IntentionPedagogique.aRenforcer);
    });
  });

  group('annuler', () {
    test('annuler retire le dernier trait, puis le dernier marqueur', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      await depot.poserMarqueur(
        couche.id,
        marqueur('m-1', IntentionPedagogique.aRevoir),
      );
      await depot.ajouterTrait(couche.id, trait('t-1'));
      await depot.ajouterTrait(couche.id, trait('t-2'));

      await depot.annulerDernier(couche.id);
      AnnotationLayer relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.traits.map((TraitVectoriel t) => t.id), <String>['t-1']);
      expect(relue.marqueurs.length, 1);

      await depot.annulerDernier(couche.id);
      await depot.annulerDernier(couche.id);
      relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.estVide, isTrue);

      // Annuler sur une couche vide ne jette pas : il n'y a rien a annuler,
      // ce n'est pas une erreur.
      await depot.annulerDernier(couche.id);
    });

    test('la gomme retire un trait precis', () async {
      final AnnotationLayer couche = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      await depot.ajouterTrait(couche.id, trait('t-1'));
      await depot.ajouterTrait(couche.id, trait('t-2'));
      await depot.retirerTrait(couche.id, 't-1');

      final AnnotationLayer relue = (await depot.couche(
        resourceId: ressourceTest,
        portee: PorteeAnnotation.enregistree,
      ))!;
      expect(relue.traits.map((TraitVectoriel t) => t.id), <String>['t-2']);
    });

    test('une couche inconnue est une erreur, pas un silence', () async {
      await expectLater(
        depot.ajouterTrait('couche-fantome', trait('t-1')),
        throwsStateError,
      );
    });
  });

  test('le flux publie chaque changement de couche', () async {
    final AnnotationLayer couche = (await depot.couche(
      resourceId: ressourceTest,
      sessionId: 'seance-1',
      portee: PorteeAnnotation.seance,
    ))!;

    final Future<AnnotationLayer> prochaine = depot
        .suivre(resourceId: ressourceTest, sessionId: 'seance-1')
        .first;
    await depot.ajouterTrait(couche.id, trait('t-1'));

    expect((await prochaine).traits.single.id, 't-1');
  });
}
