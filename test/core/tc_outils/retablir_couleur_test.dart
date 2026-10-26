// Plan de la salle du 26/10/2026 (§3) : « Retablir » refait la derniere
// operation annulee, par la meme voie que Annuler (le depot, puis la
// classe) ; la pile se vide a tout nouveau trait. La couleur franche
// voyage dans le message du trait, a cote de l'intention.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/operations_personnelles.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/reception_outils.dart';

const ContentPosition _page = ContentPosition.page(resourceId: 'r1', page: 3);

TraitVectoriel _trait(String id, {CouleurFranche? couleur}) => TraitVectoriel(
  id: id,
  ancrage: _page,
  points: const <PointNormalise>[
    PointNormalise(0.1, 0.1),
    PointNormalise(0.4, 0.2),
  ],
  outil: OutilTrait.stylet,
  intention: IntentionPedagogique.aRevoir,
  couleur: couleur,
);

void main() {
  group('Retablir', () {
    late AnnotationsMemoire depot;
    late ProviderContainer c;
    late ControleurHistorique historique;
    final List<EvenementOutil> emis = <EvenementOutil>[];

    Future<List<String>> traitsDuDepot() async {
      final AnnotationLayer? couche = await depot.couche(
        resourceId: 'r1',
        portee: PorteeAnnotation.temporaire,
      );
      return <String>[for (final TraitVectoriel t in couche!.traits) t.id];
    }

    Future<void> poser(String id) async {
      final AnnotationLayer? couche = await depot.couche(
        resourceId: 'r1',
        portee: PorteeAnnotation.temporaire,
      );
      await depot.ajouterTrait(couche!.id, _trait(id));
      historique.traitPose(_trait(id), portee: PorteeAnnotation.temporaire);
    }

    setUp(() {
      depot = AnnotationsMemoire('prof');
      c = ProviderContainer();
      historique = c.read(historiquePersonnelProvider.notifier);
      emis.clear();
    });
    tearDown(() {
      c.dispose();
      depot.liberer();
    });

    test(
      'Annuler puis Retablir rend le trait, au depot et a la classe',
      () async {
        await poser('a');
        final bool Function(ContentPosition) sur = surLaSurface(_page);
        expect(c.read(historiquePersonnelProvider).peutRetablir(sur), isFalse);
        await historique.annuler(sur, depot, emettre: emis.add);
        expect(await traitsDuDepot(), isEmpty);
        expect(c.read(historiquePersonnelProvider).peutRetablir(sur), isTrue);
        emis.clear();
        await historique.retablir(sur, depot, emettre: emis.add);
        expect(await traitsDuDepot(), <String>['a']);
        expect(emis.single, isA<EvenementTraitTermine>());
        expect(c.read(historiquePersonnelProvider).peutRetablir(sur), isFalse);
        // Annuler le defait de nouveau.
        expect(c.read(historiquePersonnelProvider).peutAnnuler(sur), isTrue);
        expect(
          c.read(historiquePersonnelProvider).retires,
          isNot(contains('a')),
        );
      },
    );

    test('un nouveau trait vide la pile de retablissement', () async {
      await poser('a');
      final bool Function(ContentPosition) sur = surLaSurface(_page);
      await historique.annuler(sur, depot);
      expect(c.read(historiquePersonnelProvider).peutRetablir(sur), isTrue);
      await poser('b');
      expect(c.read(historiquePersonnelProvider).peutRetablir(sur), isFalse);
    });

    test('des traits gommes, annules puis retablis, repartent', () async {
      await poser('a');
      final AnnotationLayer? couche = await depot.couche(
        resourceId: 'r1',
        portee: PorteeAnnotation.temporaire,
      );
      await depot.retirerTrait(couche!.id, 'a');
      historique
        ..masquer('a')
        ..traitsGommes(
          <TraitVectoriel>[_trait('a')],
          surface: _page,
          portee: PorteeAnnotation.temporaire,
        );
      final bool Function(ContentPosition) sur = surLaSurface(_page);
      await historique.annuler(sur, depot);
      expect(await traitsDuDepot(), <String>['a']);
      await historique.retablir(sur, depot, emettre: emis.add);
      expect(await traitsDuDepot(), isEmpty);
      expect(emis.single, isA<EvenementTraitRetire>());
    });
  });

  group('Couleur franche', () {
    test('le trait termine la porte dans son message, la reception la lit', () {
      final EvenementTraitTermine e = EvenementTraitTermine(
        coucheId: 'c1',
        trait: _trait('a', couleur: CouleurFranche.bleu),
        portee: PorteeAnnotation.temporaire,
      );
      final Map<String, dynamic> charge = e.charge();
      expect((charge['trait'] as Map<String, dynamic>)['couleur'], 'bleu');
      expect(
        (charge['trait'] as Map<String, dynamic>)['intention'],
        IntentionPedagogique.aRevoir.valeurSql,
      );
      final TraitVectoriel? lu = traitDepuisCharge(charge);
      expect(lu?.couleur, CouleurFranche.bleu);
      expect(lu?.intention, IntentionPedagogique.aRevoir);
    });

    test('un message sans couleur garde la couleur de l intention', () {
      final Map<String, dynamic> charge = EvenementTraitTermine(
        coucheId: 'c1',
        trait: _trait('a'),
        portee: PorteeAnnotation.temporaire,
      ).charge();
      expect(traitDepuisCharge(charge)?.couleur, isNull);
    });

    test('choisir une intention retire la couleur franche', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final ControleurOutils outils = c.read(etatOutilsProvider.notifier);
      outils.choisirCouleur(CouleurFranche.orange);
      expect(c.read(etatOutilsProvider).couleur, CouleurFranche.orange);
      outils.choisirIntention(IntentionPedagogique.aRenforcer);
      expect(c.read(etatOutilsProvider).couleur, isNull);
      expect(
        c.read(etatOutilsProvider).intention,
        IntentionPedagogique.aRenforcer,
      );
    });
  });
}
