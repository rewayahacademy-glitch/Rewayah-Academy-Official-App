// DISPO-1 : la logique pure des plages (lecture des heures pleines,
// chevauchements, plan d'envoi). Aucun widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/creneaux/plages.dart';

Set<HeureSemaine> _h(int jour, int de, int a) => <HeureSemaine>{
  for (int h = de; h < a; h++) (jour: jour, heure: h),
};

void main() {
  group('deduirePlages', () {
    test('17, 18, ..., 22 se lit « de 17 h a 23 h »', () {
      expect(deduirePlages(_h(1, 17, 23)), <Plage>[
        const Plage(jour: 1, de: 17, a: 23),
      ]);
    });

    test('un trou coupe la plage ; tri par jour puis par debut', () {
      expect(
        deduirePlages(<HeureSemaine>{
          ..._h(2, 9, 11),
          ..._h(1, 18, 20),
          ..._h(1, 8, 9),
        }),
        <Plage>[
          const Plage(jour: 1, de: 8, a: 9),
          const Plage(jour: 1, de: 18, a: 20),
          const Plage(jour: 2, de: 9, a: 11),
        ],
      );
    });

    test('23 h finit a minuit (24)', () {
      expect(deduirePlages(_h(7, 22, 24)).single.a, 24);
    });

    test('aucune heure, aucune plage', () {
      expect(deduirePlages(<HeureSemaine>{}), isEmpty);
    });
  });

  group('planifier', () {
    test('ajout simple : une heure par jour choisi, aucune fusion', () {
      final PlanPlage plan = planifier(
        existantes: <HeureSemaine>{},
        jours: <int>{3, 1},
        de: 17,
        a: 19,
      );
      expect(plan.ajouts, <HeureSemaine>[
        (jour: 1, heure: 17),
        (jour: 1, heure: 18),
        (jour: 3, heure: 17),
        (jour: 3, heure: 18),
      ]);
      expect(plan.retraits, isEmpty);
      expect(plan.fusions, isEmpty);
    });

    test('chevauchement : seules les heures manquantes, fusion annoncee', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 17, 20),
        jours: <int>{1},
        de: 19,
        a: 23,
      );
      expect(plan.ajouts.map((HeureSemaine h) => h.heure), <int>[20, 21, 22]);
      expect(plan.fusions, <Plage>[const Plage(jour: 1, de: 17, a: 23)]);
    });

    test('plage voisine (qui touche) : fusion annoncee aussi', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 8, 12),
        jours: <int>{1},
        de: 12,
        a: 14,
      );
      expect(plan.fusions, <Plage>[const Plage(jour: 1, de: 8, a: 14)]);
    });

    test('plage disjointe : aucune fusion', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 8, 10),
        jours: <int>{1},
        de: 17,
        a: 19,
      );
      expect(plan.fusions, isEmpty);
    });

    // DISPO-1b : une saisie qui ne reunit rien ne s'annonce pas comme une
    // fusion ; elle se dit deja posee, dans la plage qui la contient.
    test(
      'saisie contenue dans une plage posee : rien a poser, dite deja posee',
      () {
        final PlanPlage plan = planifier(
          existantes: _h(1, 17, 23),
          jours: <int>{1},
          de: 18,
          a: 20,
        );
        expect(plan.vide, isTrue);
        expect(plan.fusions, isEmpty);
        expect(plan.dejaPosees, <Plage>[const Plage(jour: 1, de: 17, a: 23)]);
      },
    );

    test('saisie identique a une plage posee : aucune fusion annoncee', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 17, 23),
        jours: <int>{1},
        de: 17,
        a: 23,
      );
      expect(plan.vide, isTrue);
      expect(plan.fusions, isEmpty);
      expect(plan.dejaPosees, <Plage>[const Plage(jour: 1, de: 17, a: 23)]);
    });

    test('deux jours : l un deja pose, l autre reuni, chacun dit a part', () {
      final PlanPlage plan = planifier(
        existantes: <HeureSemaine>{..._h(1, 17, 23), ..._h(2, 17, 19)},
        jours: <int>{1, 2},
        de: 17,
        a: 23,
      );
      expect(plan.dejaPosees, <Plage>[const Plage(jour: 1, de: 17, a: 23)]);
      expect(plan.fusions, <Plage>[const Plage(jour: 2, de: 17, a: 23)]);
      expect(plan.ajouts.map((HeureSemaine h) => h.jour).toSet(), <int>{2});
    });

    test('plage posee absorbee par une saisie plus large : fusion dite', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 18, 19),
        jours: <int>{1},
        de: 17,
        a: 20,
      );
      expect(plan.dejaPosees, isEmpty);
      expect(plan.fusions, <Plage>[const Plage(jour: 1, de: 17, a: 20)]);
    });

    test('modifier : on ne retire que les heures de la plage touchee', () {
      final Set<HeureSemaine> existantes = <HeureSemaine>{
        ..._h(1, 17, 23),
        ..._h(2, 17, 23),
      };
      final PlanPlage plan = planifier(
        existantes: existantes,
        jours: <int>{1},
        de: 18,
        a: 21,
        modifiee: const Plage(jour: 1, de: 17, a: 23),
      );
      expect(plan.retraits, <HeureSemaine>[
        (jour: 1, heure: 17),
        (jour: 1, heure: 21),
        (jour: 1, heure: 22),
      ]);
      expect(plan.ajouts, isEmpty);
      // La plage modifiee ne se « fusionne » pas avec elle-meme.
      expect(plan.fusions, isEmpty);
    });

    test(
      'modifier en deplacant le jour : retire l ancien, pose le nouveau',
      () {
        final PlanPlage plan = planifier(
          existantes: _h(1, 17, 19),
          jours: <int>{2},
          de: 17,
          a: 19,
          modifiee: const Plage(jour: 1, de: 17, a: 19),
        );
        expect(plan.retraits.map((HeureSemaine h) => h.jour).toSet(), <int>{1});
        expect(plan.ajouts.map((HeureSemaine h) => h.jour).toSet(), <int>{2});
      },
    );

    // DISPO-1b : apres un echec partiel, la plage touchee n'est plus posee en
    // entier. Seules ses heures ENCORE posees repartent en retrait ; celles
    // dont le retrait est deja confirme ne se renvoient pas (intersection
    // avec `existantes` dans `planifier`).
    test('modifier apres un retrait partiel : seules les heures encore posees '
        'repartent', () {
      // Plage touchee : lundi 17 h-23 h, reduite a 17 h-19 h. Le premier
      // envoi a confirme le retrait de 21 h et 22 h, pas celui de 19 h et
      // 20 h : la relecture ne voit plus que 17 h a 20 h.
      final PlanPlage plan = planifier(
        existantes: _h(1, 17, 21),
        jours: <int>{1},
        de: 17,
        a: 19,
        modifiee: const Plage(jour: 1, de: 17, a: 23),
      );
      expect(plan.retraits, <HeureSemaine>[
        (jour: 1, heure: 19),
        (jour: 1, heure: 20),
      ]);
      expect(plan.ajouts, isEmpty);
      expect(plan.fusions, isEmpty);
      expect(plan.dejaPosees, isEmpty);
    });

    test('modifier quand tous les retraits sont confirmes : plan vide', () {
      final PlanPlage plan = planifier(
        existantes: _h(1, 17, 19),
        jours: <int>{1},
        de: 17,
        a: 19,
        modifiee: const Plage(jour: 1, de: 17, a: 23),
      );
      expect(plan.vide, isTrue);
    });
  });
}
