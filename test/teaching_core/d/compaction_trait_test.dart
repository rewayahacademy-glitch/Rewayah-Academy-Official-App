import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/compaction_trait.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';

import 'faux/faux_realtime.dart';
import 'support/hote_d.dart';

void main() {
  group('compaction d un trait', () {
    test('une ligne droite se reduit a ses deux extremites', () {
      final List<PointNormalise> ligne = <PointNormalise>[
        for (int i = 0; i <= 20; i++) PointNormalise(i / 20, i / 20),
      ];
      expect(simplifierTrait(ligne), <PointNormalise>[
        const PointNormalise(0, 0),
        const PointNormalise(1, 1),
      ]);
    });

    test('un angle net survit a la compaction', () {
      final List<PointNormalise> angle = <PointNormalise>[
        const PointNormalise(0, 0),
        const PointNormalise(0.5, 0),
        const PointNormalise(0.5, 0.5),
      ];
      expect(simplifierTrait(angle).length, 3);
    });

    test('deux points ou moins passent tels quels', () {
      expect(simplifierTrait(const <PointNormalise>[]), isEmpty);
      expect(
        simplifierTrait(const <PointNormalise>[PointNormalise(0.1, 0.1)])
            .length,
        1,
      );
    });
  });

  group('pendant le geste, puis a la fin', () {
    TraitEnCours ouvrir() => TraitEnCours(
      ancrage: ayah1,
      outil: OutilTrait.stylet,
      intention: IntentionPedagogique.aRevoir,
    );

    test('le paquet ephemere ne porte que les points NOUVEAUX', () {
      final TraitEnCours trait = ouvrir()
        ..ajouter(const PointNormalise(0, 0))
        ..ajouter(const PointNormalise(0.1, 0.1))
        ..ajouter(const PointNormalise(0.2, 0.2));

      expect(trait.paquetPret, isTrue);
      expect(trait.prendrePaquet().length, 3);

      // Rien de neuf : rien a emettre. On n'envoie pas un paquet vide.
      expect(trait.prendrePaquet(), isEmpty);
      expect(trait.paquetPret, isFalse);

      trait.ajouter(const PointNormalise(0.3, 0.3));
      expect(trait.prendrePaquet(), <PointNormalise>[
        const PointNormalise(0.3, 0.3),
      ]);
    });

    test('le trait final est compacte, pas la somme des paquets', () {
      final TraitEnCours trait = ouvrir();
      for (int i = 0; i <= 20; i++) {
        trait.ajouter(PointNormalise(i / 20, i / 20));
      }
      expect(trait.nombreDePoints, 21);

      final TraitVectoriel termine = trait.terminer(id: 't-1');
      expect(termine.points.length, 2);
      expect(termine.ancrage, ayah1);
      expect(termine.outil, OutilTrait.stylet);
      expect(termine.intention, IntentionPedagogique.aRevoir);
    });

    test('la pression et l inclinaison restent nulles sans materiel', () {
      final TraitEnCours trait = ouvrir()
        ..ajouter(const PointNormalise(0, 0))
        ..ajouter(const PointNormalise(1, 1));
      final TraitVectoriel termine = trait.terminer(id: 't-2');
      expect(termine.pression, isNull);
      expect(termine.inclinaison, isNull);
    });

    test('la pression fournie est moyennee, jamais la derniere valeur', () {
      final TraitEnCours trait = ouvrir()
        ..ajouter(const PointNormalise(0, 0), pression: 0.2, inclinaison: 0.5)
        ..ajouter(const PointNormalise(1, 1), pression: 0.8);
      final TraitVectoriel termine = trait.terminer(id: 't-3');
      expect(termine.pression, closeTo(0.5, 0.0001));
      expect(termine.inclinaison, closeTo(0.5, 0.0001));
    });
  });

  group('ce qui part sur le fil', () {
    late FauxRealtime transport;
    late DiffusionOutils diffusion;

    setUp(() {
      transport = FauxRealtime();
      diffusion = DiffusionOutils(
        transport,
        sessionId: 'seance-1',
        emetteurProfilId: 'prof-1',
        maintenant: () => DateTime.utc(2026, 9, 20, 10),
      );
    });

    test(
      'le trait en cours part en ephemere, le trait fini en fiable',
      () async {
        await diffusion.emettre(
          EvenementTraitEnCours(
            traitId: 't-1',
            ancrage: ayah1,
            pointsNouveaux: const <PointNormalise>[PointNormalise(0.1, 0.1)],
            outil: OutilTrait.stylet,
          ),
        );
        await diffusion.emettre(
          EvenementTraitTermine(
            coucheId: 'c-1',
            portee: PorteeAnnotation.seance,
            trait: TraitVectoriel(
              id: 't-1',
              ancrage: ayah1,
              outil: OutilTrait.stylet,
              points: const <PointNormalise>[
                PointNormalise(0.1, 0.1),
                PointNormalise(0.9, 0.9),
              ],
            ),
          ),
        );

        expect(transport.canaux, <CanalFiabilite>[
          CanalFiabilite.ephemere,
          CanalFiabilite.fiable,
        ]);
        expect(transport.types, <String>[
          'tc.outils.trait_en_cours',
          'tc.outils.trait_termine',
        ]);
        expect(transport.emis.first.message.emisLeUtc.isUtc, isTrue);
        expect(transport.emis.first.message.sessionId, 'seance-1');
      },
    );

    test('le pointeur est ephemere, et ne porte aucune persistance', () async {
      await diffusion.emettre(EvenementPointeur(position: ayah1));
      expect(transport.canaux.single, CanalFiabilite.ephemere);
      expect(transport.types.single, 'tc.outils.pointeur');
    });

    test('la charge ne porte que des identifiants et des fractions', () async {
      await diffusion.emettre(
        EvenementTraitEnCours(
          traitId: 't-1',
          ancrage: ayah1,
          pointsNouveaux: const <PointNormalise>[PointNormalise(0.25, 0.5)],
          outil: OutilTrait.surligneur,
          intention: IntentionPedagogique.aRenforcer,
        ),
      );
      final Map<String, dynamic> charge = transport.emis.single.message.charge;
      expect(charge['trait_id'], 't-1');
      expect(charge['outil'], 'surligneur');
      expect(charge['intention'], 'reinforce');
      expect(charge['points'], <Map<String, double>>[
        <String, double>{'x': 0.25, 'y': 0.5},
      ]);
      // Aucun octet du support ne voyage : uniquement des references.
      expect(charge.toString(), isNot(contains('base64')));
    });
  });
}
