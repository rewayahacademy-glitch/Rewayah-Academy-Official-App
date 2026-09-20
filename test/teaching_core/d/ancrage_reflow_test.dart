import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_outils/ancrage_annotation.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/ports_externes/port_realtime_pedagogique.dart'
    show ModeAffichagePartage;

import 'support/hote_d.dart';

/// Le trait de reference : une diagonale au milieu du bloc ancre.
TraitVectoriel traitSur(ContentPosition ancrage) => TraitVectoriel(
  id: 't-1',
  ancrage: ancrage,
  outil: OutilTrait.stylet,
  intention: IntentionPedagogique.aRenforcer,
  points: const <PointNormalise>[
    PointNormalise(0.25, 0.25),
    PointNormalise(0.75, 0.75),
  ],
);

void main() {
  group('choisir l ancrage', () {
    test('sur page figee, l ancrage spatial est prefere', () {
      final ResultatAncrage resultat = choisirAncrage(
        mode: ModeAffichagePartage.page,
        semantique: ayah1,
        spatial: pageCourante,
      );
      expect(resultat.position, pageCourante);
      expect(resultat.raison, RaisonAncrage.spatialSurPageFigee);
      expect(
        resultat.degrade,
        isFalse,
        reason: 'une page figee ne se recompose pas : rien ne se decalera',
      );
    });

    test('sur rendu reflowable, l ancrage semantique l emporte', () {
      final ResultatAncrage resultat = choisirAncrage(
        mode: ModeAffichagePartage.verse,
        semantique: ayah1,
        spatial: pageCourante,
      );
      expect(resultat.position, ayah1);
      expect(resultat.raison, RaisonAncrage.semantiqueRetenu);
      expect(resultat.degrade, isFalse);
    });

    test('en focus aussi : le focus recompose le texte', () {
      final ResultatAncrage resultat = choisirAncrage(
        mode: ModeAffichagePartage.focus,
        semantique: ayah1,
        spatial: pageCourante,
      );
      expect(resultat.raison, RaisonAncrage.semantiqueRetenu);
    });

    test(
      'sans repere semantique, le repli spatial est retenu ET declare degrade',
      () {
        final ResultatAncrage resultat = choisirAncrage(
          mode: ModeAffichagePartage.verse,
          spatial: pageCourante,
        );
        expect(resultat.position, pageCourante);
        expect(resultat.raison, RaisonAncrage.spatialFauteDeSemantique);
        expect(
          resultat.degrade,
          isTrue,
          reason: "c'est le point que la spec signale comme souvent rate : "
              "l'annotation se decalera, et l'appelant doit le savoir",
        );
      },
    );

    test('sans aucun repere, aucun ancrage n est invente', () {
      final ResultatAncrage resultat = choisirAncrage(
        mode: ModeAffichagePartage.verse,
      );
      expect(resultat.position, isNull);
      expect(resultat.raison, RaisonAncrage.aucunAncrage);
    });
  });

  group('un reflow deplace le texte', () {
    // Avant : les deux versets font 40 points de haut, en tete de page.
    final CarteDesBlocs avant = supportTest().blocs;
    // Apres : la fenetre a change de largeur, la police a grossi, le premier
    // verset est descendu et s'est elargi. C'est exactement ce qui arrive en
    // tournant une tablette.
    final CarteDesBlocs apres = supportTest(
      rectAyah1: const Rect.fromLTWH(20, 120, 400, 90),
      rectAyah2: const Rect.fromLTWH(20, 210, 400, 90),
    ).blocs;

    test('le trait ancre semantiquement suit son verset', () {
      final TraitVectoriel trait = traitSur(ayah1);

      expect(resoudreTrait(trait, avant), <Offset>[
        const Offset(50, 10),
        const Offset(150, 30),
      ]);
      expect(resoudreTrait(trait, apres), <Offset>[
        const Offset(120, 142.5),
        const Offset(320, 187.5),
      ]);

      // Le trait a bouge, et il a bouge AVEC son verset : ses points restent
      // aux memes fractions du bloc.
      final Rect blocApres = apres.rectDe(ayah1)!;
      for (final Offset point in resoudreTrait(trait, apres)!) {
        expect(blocApres.contains(point), isTrue);
      }
    });

    test('le trait ancre spatialement, lui, ne bouge pas', () {
      final TraitVectoriel trait = traitSur(pageCourante);

      // Le cadre de la page est le meme : le trait est rendu au meme endroit
      // de l'ecran, alors que le texte, lui, a bouge.
      expect(resoudreTrait(trait, avant), resoudreTrait(trait, apres));

      // Et il ne recouvre plus le verset qu'il annotait : c'est le decalage
      // que l'ancrage semantique evite.
      final Rect blocApres = apres.rectDe(ayah1)!;
      expect(
        resoudreTrait(trait, apres)!.every(blocApres.contains),
        isFalse,
      );
    });

    test('un trait dont l ancrage n est pas rendu n est pas peint ailleurs', () {
      final TraitVectoriel trait = traitSur(
        const ContentPosition.ayah(
          resourceId: ressourceTest,
          sourate: 2,
          ayah: 255,
        ),
      );
      expect(
        resoudreTrait(trait, avant),
        isNull,
        reason: "le verset n'est pas a l'ecran : on ne peint rien, plutot que "
            'de peindre au mauvais endroit',
      );
    });

    test('le zoom ne change rien aux donnees, seulement au rendu', () {
      final TraitVectoriel trait = traitSur(ayah1);
      final CarteDesBlocs zoome = supportTest(
        rectAyah1: const Rect.fromLTWH(0, 0, 400, 80),
      ).blocs;

      // Memes points normalises, rendu deux fois plus grand : rien n'a ete
      // stocke en pixels.
      expect(resoudreTrait(trait, zoome), <Offset>[
        const Offset(100, 20),
        const Offset(300, 60),
      ]);
    });
  });

  group('la carte des blocs', () {
    test('rend le bloc le plus fin sous le doigt', () {
      final CarteDesBlocs carte = supportTest().blocs;
      expect(carte.blocA(const Offset(10, 10))?.position, ayah1);
      expect(carte.blocA(const Offset(10, 50))?.position, ayah2);
      expect(carte.blocA(const Offset(10, 300)), isNull);
    });

    test('un marqueur de plage emprunte la geometrie des blocs', () {
      final CarteDesBlocs carte = supportTest().blocs;
      final ContentRange plage = ContentRange(
        resourceId: ressourceTest,
        debut: ayah1,
        fin: ayah2,
      );
      expect(
        blocsDansPlage(carte, plage).map((BlocAncre b) => b.position),
        <ContentPosition>[ayah1, ayah2],
      );

      final ContentRange plageCourte = ContentRange(
        resourceId: ressourceTest,
        debut: ayah2,
        fin: ayah2,
      );
      expect(
        blocsDansPlage(carte, plageCourte).map((BlocAncre b) => b.position),
        <ContentPosition>[ayah2],
      );
    });
  });
}
