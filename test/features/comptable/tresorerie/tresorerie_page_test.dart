// CPT-TRES-1 : Tresorerie et coffres (W04, M02 ecran 1). Sept coffres dans
// l'ordre §8.1, montants masques a l'entree, Reserve strategique au titre
// fixe (R-FIN-05), objectif en mois (R-FIN-06) ou en montant (R-FIN-07),
// alimentation automatique de 10 USD comme de 1 000 000 USD (R-FIN-08, 09),
// retrait de la Reserve sans capacite bloque (R-FIN-10), prevision datee,
// historique en lecture, et les cinq etats (chargement, contenu, vide,
// erreur, hors ligne) plus la source absente (« en preparation »).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_tresorerie.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/comptable/carte_reserve_strategique.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/carte_coffre.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/carte_politique_reserve.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_donnees.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_page.dart';

import 'faux_tresorerie.dart';

void main() {
  final tr = t.comptable.tresorerie;
  final c = t.comptable.commun;

  group('Contenu', () {
    testWidgets('les sept coffres, dans l ordre de la spec §8.1', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(tester, tresorerie: FausseTresorerie());
      double? precedent;
      for (final Coffre coffre in Coffre.values) {
        final Finder carte = find.byKey(CarteCoffre.clePour(coffre));
        expect(carte, findsOneWidget, reason: coffre.name);
        final double y = tester.getTopLeft(carte).dy;
        if (precedent != null) expect(y, greaterThan(precedent));
        precedent = y;
        expect(
          find.descendant(
            of: carte,
            matching: find.text(libelleCoffre(coffre)),
          ),
          findsOneWidget,
        );
      }
      // Nature ecrite en toutes lettres, part rendue par la source.
      expect(find.text(tr.coffreProtege), findsNWidgets(5));
      expect(find.text(tr.coffreNonProtege), findsNWidgets(2));
      expect(find.text(tr.partDetenue(part: '12,5')), findsNWidgets(7));
    });

    testWidgets('montants masques a l entree, affiches par la bascule', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(tester, tresorerie: FausseTresorerie());
      expect(find.text(formaterMontant(usd(300))), findsNothing);
      expect(find.text(MontantSensible.masquePour('USD')), findsWidgets);

      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie(),
        montantsAffiches: true,
      );
      // La Tresorerie libre au centre de la synthese.
      expect(find.text(formaterMontant(usd(300))), findsWidgets);
    });

    testWidgets('prevision en lignes datees, triees, sans graphique', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(tester, tresorerie: FausseTresorerie());
      final Finder premiere = find.text('Premiere echeance');
      final Finder deuxieme = find.text('Deuxieme echeance');
      expect(premiere, findsOneWidget);
      expect(
        tester.getTopLeft(premiere).dy,
        lessThan(tester.getTopLeft(deuxieme).dy),
      );
      expect(
        find.text(
          c.activiteInitiateurDate(
            initiateur: tr.entree,
            date: '5 octobre 2026',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          c.activiteInitiateurDate(
            initiateur: tr.sortie,
            date: '20 octobre 2026',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('historique en lecture : aucune allocation modifiable', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(tester, tresorerie: FausseTresorerie());
      expect(
        find.text('Trésorerie libre → Réserve stratégique'),
        findsOneWidget,
      );
      // Aucun champ de saisie sur la page : on ne modifie pas une allocation
      // pour masquer un deficit (§10.4).
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('bureau : coffres a gauche, Reserve a droite (1440)', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie(),
        taille: const Size(1440, 1600),
      );
      final Offset coffre = tester.getTopLeft(
        find.byKey(CarteCoffre.clePour(Coffre.fondsClientsEngages)),
      );
      final Offset reserve = tester.getTopLeft(
        find.byType(CarteReserveStrategique),
      );
      expect(reserve.dx, greaterThan(coffre.dx));
      expect(tester.takeException(), isNull);
    });
  });

  group('Reserve strategique (R-FIN-05 a 09)', () {
    testWidgets('R-FIN-05, 06 : titre fixe, objectif en mois', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie(),
        politique: FaussePolitique(
          politique: politiqueMois(3),
          indic: indicateursMois(3),
        ),
      );
      final Finder carte = find.byType(CarteReserveStrategique);
      expect(
        find.descendant(of: carte, matching: find.text(c.reserveStrategique)),
        findsOneWidget,
      );
      expect(find.text(c.objectifMois(n: 3)), findsOneWidget);
      expect(find.text(c.modeCouvertureMois), findsOneWidget);
      expect(find.textContaining('Réserve 3 mois'), findsNothing);
      expect(find.byType(PastilleEtatReserve), findsOneWidget);
    });

    testWidgets('R-FIN-05 : titre fixe quelle que soit la duree', (
      WidgetTester tester,
    ) async {
      for (final int mois in <int>[1, 6, 12]) {
        await monterTresorerie(
          tester,
          tresorerie: FausseTresorerie(),
          politique: FaussePolitique(
            politique: politiqueMois(mois),
            indic: indicateursMois(mois),
          ),
        );
        expect(find.text(c.objectifMois(n: mois)), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CarteReserveStrategique),
            matching: find.text(c.reserveStrategique),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('R-FIN-07 : objectif fixe, le montant cible s affiche', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie(),
        politique: FaussePolitique(
          indic: indicateursFixes(objectif: usd(5000)),
        ),
        montantsAffiches: true,
      );
      expect(find.text(c.objectifFixe), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CarteReserveStrategique),
          matching: find.text(formaterMontant(usd(5000))),
        ),
        findsOneWidget,
      );
    });

    for (final int unites in <int>[10, 1000000]) {
      testWidgets('R-FIN-08, 09 : allocation automatique fixe de $unites USD', (
        WidgetTester tester,
      ) async {
        await monterTresorerie(
          tester,
          tresorerie: FausseTresorerie(),
          politique: FaussePolitique(
            politique: politiqueFixe(auto: usd(unites), cible: usd(unites)),
            indic: indicateursFixes(objectif: usd(unites)),
          ),
          montantsAffiches: true,
        );
        expect(
          find.descendant(
            of: find.byKey(CartePolitiqueReserve.cleAlimentation),
            matching: find.text(formaterMontant(usd(unites))),
          ),
          findsOneWidget,
        );
        expect(find.text(tr.regle.montantFixe), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('R-FIN-10 : retrait sans capacite bloque, raison ecrite', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(tester, tresorerie: FausseTresorerie());
      expect(find.byKey(TresoreriePage.cleRetirer), findsNothing);
      expect(
        find.text(
          tr.retraitBloque(
            raison: libelleRaisonBlocage(RaisonBlocage.capaciteAbsente),
          ),
        ),
        findsOneWidget,
      );
      // L'action cle reste « Alimenter la Reserve strategique » (§32).
      expect(find.byKey(TresoreriePage.cleAlimenter), findsOneWidget);
      expect(find.text(tr.alimenter), findsOneWidget);
    });
  });

  group('Etats', () {
    testWidgets('chargement : squelettes, aucun chiffre', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie()..enAttente = true,
      );
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CarteCoffre), findsNothing);
    });

    testWidgets('erreur : bloc d echec avec Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final FausseTresorerie port = FausseTresorerie()
        ..erreurLecture = StateError('panne');
      await monterTresorerie(tester, tresorerie: port);
      expect(find.byType(EtatSysteme), findsWidgets);
      expect(find.byType(CarteCoffre), findsNothing);
      final int avant = port.lecturesSynthese;
      port.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(port.lecturesSynthese, greaterThan(avant));
      expect(find.byType(CarteCoffre), findsNWidgets(7));
    });

    testWidgets('vide : coffres, prevision et historique le disent', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie()
          ..soldes = const <SoldeCoffre>[]
          ..lignes = const <LignePrevision>[]
          ..entrees = const <EntreeJournal>[],
      );
      expect(find.text(tr.coffresVide), findsOneWidget);
      expect(find.text(tr.previsionVide), findsOneWidget);
      expect(find.text(tr.historiqueVide), findsOneWidget);
    });

    testWidgets('hors ligne : echec dit hors ligne, aucun mouvement', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie()..erreurLecture = StateError('reseau'),
        horsLigne: true,
      );
      final Iterable<EtatSysteme> etats = tester.widgetList<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etats, isNotEmpty);
      expect(
        etats.every((EtatSysteme e) => e.nature == NatureEtat.horsLigne),
        isTrue,
      );
      expect(find.text(tr.mouvementsHorsLigne), findsOneWidget);
      expect(find.byKey(TresoreriePage.cleAlimenter), findsNothing);
    });

    testWidgets('source absente (production) : en preparation, sans chiffre', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Le vrai port de production.
      await tester.pumpWidget(hotePage(const TresorerieIndisponible()));
      await tester.pump();
      await tester.pump();
      expect(find.text(c.enPreparationTitre), findsOneWidget);
      expect(find.byType(MontantSensible), findsNothing);
    });

    testWidgets('aucun mouvement permis ni refuse : une phrase, aucun bouton', (
      WidgetTester tester,
    ) async {
      await monterTresorerie(
        tester,
        tresorerie: FausseTresorerie()
          ..permis = const <MouvementPermis>[]
          ..bloques = const <MouvementBloque>[],
      );
      expect(find.text(tr.aucunMouvement), findsOneWidget);
      expect(find.byKey(TresoreriePage.cleAlimenter), findsNothing);
      expect(find.byKey(TresoreriePage.clePreparer), findsNothing);
    });
  });

  group('Regles des mouvements (seconde barriere)', () {
    test('les couples interdits §10.4 ne sont jamais offerts', () {
      final MouvementsCoffres m = MouvementsCoffres.depuis(
        permis: const <MouvementPermis>[
          MouvementPermis(
            origine: Coffre.fondsClientsEngages,
            destination: Coffre.tresorerieLibre,
            sensible: true,
          ),
          MouvementPermis(
            origine: Coffre.taxesObligations,
            destination: Coffre.tresorerieLibre,
            sensible: true,
          ),
          MouvementPermis(
            origine: Coffre.tresorerieLibre,
            destination: Coffre.tresorerieLibre,
            sensible: false,
          ),
          MouvementPermis(
            origine: Coffre.tresorerieLibre,
            destination: Coffre.reserveStrategique,
            sensible: false,
          ),
        ],
        bloques: const <MouvementBloque>[],
      );
      expect(m.offerts, hasLength(1));
      expect(m.alimentation?.origine, Coffre.tresorerieLibre);
      expect(m.retrait, isNull);
    });

    test('un couple a la fois permis et refuse reste refuse', () {
      final MouvementsCoffres m = MouvementsCoffres.depuis(
        permis: const <MouvementPermis>[
          MouvementPermis(
            origine: Coffre.reserveStrategique,
            destination: Coffre.tresorerieLibre,
            sensible: true,
          ),
        ],
        bloques: const <MouvementBloque>[
          MouvementBloque(
            origine: Coffre.reserveStrategique,
            destination: Coffre.tresorerieLibre,
            raison: RaisonBlocage.capaciteAbsente,
          ),
        ],
      );
      expect(m.offerts, isEmpty);
      expect(m.retrait, isNull);
      expect(m.retraitBloque?.raison, RaisonBlocage.capaciteAbsente);
    });

    test('une sortie de coffre protege est toujours sensible', () {
      expect(
        estSensible(
          const MouvementPermis(
            origine: Coffre.reserveStrategique,
            destination: Coffre.tresorerieLibre,
            sensible: false,
          ),
        ),
        isTrue,
      );
      expect(
        estSensible(
          const MouvementPermis(
            origine: Coffre.tresorerieLibre,
            destination: Coffre.reserveStrategique,
            sensible: false,
          ),
        ),
        isFalse,
      );
    });

    test('part en pour mille ecrite sans double', () {
      expect(pourcentDepuisPourMille(292), '29,2');
      expect(pourcentDepuisPourMille(150), '15');
      expect(pourcentDepuisPourMille(1000), '100');
      expect(pourcentDepuisPourMille(7), '0,7');
    });
  });
}
