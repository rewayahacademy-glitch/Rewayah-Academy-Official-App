// MA-APRES-1b (revue C1-MA-R, majeur M1) : apres « Quitter » dans la VRAIE
// salle (`SallePage`) en Mode Accessibilite, l'ecran de fin ne dit jamais
// « Ta prochaine seance n'est pas encore programmee » sans le savoir.
//
// - Classe hebdomadaire de demonstration EN DIRECT (`EtatDemoClasse.enDirect`),
//   avec et sans travail : l'horloge porte la seance quittee, l'occurrence
//   suivante n'a aucune source cote client ; l'ecran garde « Prochaine
//   seance » et dit la phrase neutre, jamais la date de la seance quittee.
// - Classe de forme production (`groupeDepuisLigne`, sans horloge) et port de
//   travail non branche (`null`) : « non relie », jamais « aucun travail ».
// - Lecture du travail en cours : etat chargement, jamais vide.
// - La regle de la prochaine seance (`prochaineApres`), cas par cas.
//
// Chaque cas echoue sur `d7202977` (contre-epreuve dans le rapport).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';

import 'support_ma_apres1.dart';

void _jamaisPasProgrammee() {
  expect(find.text(t.accessibilite.apres.vide), findsNothing);
  expect(find.text(t.accessibilite.apres.videVous), findsNothing);
  expect(find.byKey(ApresSeanceAccessibilite.cleVide), findsNothing);
}

void main() {
  final String seanceQuittee = ApresSeanceAccessibilite.libelleProchaine(
    DonneesClasseDemo.debutUtc,
  );

  for (final (String nom, bool avecTravail) in <(String, bool)>[
    ('avec travail', true),
    ('sans travail', false),
  ]) {
    testWidgets('MA-APRES-1b : vraie salle, Classe hebdomadaire en direct, '
        '$nom : prochaine seance neutre, jamais « pas encore programmee »', (
      WidgetTester tester,
    ) async {
      await quitterLaSalleMa(
        tester,
        groupes: GroupesMaApres(classeEnDirect),
        travail: avecTravail ? DonneesClasseDemo.actions : const <SlotAction>[],
      );
      expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
      _jamaisPasProgrammee();
      expect(
        find.text(t.accessibilite.accueil.prochaineSeance),
        findsOneWidget,
      );
      expect(
        find.byKey(ApresSeanceAccessibilite.cleProchaineInconnue),
        findsOneWidget,
      );
      expect(
        find.text(t.accessibilite.apres.prochaineInconnue),
        findsOneWidget,
      );
      // La seance quittee n'est jamais annoncee comme la prochaine.
      expect(find.text(seanceQuittee), findsNothing);
      expect(
        find.text(LibellesGroupe.avantProchainCours),
        avecTravail ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(ApresSeanceAccessibilite.cleTravailNonRelie),
        findsNothing,
      );
      // Ordre : support, prochaine seance, aide.
      final double support = tester
          .getTopLeft(find.text(t.accessibilite.apres.revoirSupport))
          .dy;
      final double prochaine = tester
          .getTopLeft(find.text(t.accessibilite.accueil.prochaineSeance))
          .dy;
      final double aide = tester
          .getTopLeft(find.text(t.accessibilite.accueil.aide))
          .dy;
      expect(prochaine, greaterThan(support));
      expect(aide, greaterThan(prochaine));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('MA-APRES-1b : vraie salle, adulte, en direct : phrase neutre '
      'vouvoyee', (WidgetTester tester) async {
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(classeEnDirect),
      age: AgeEleve.adulte,
    );
    _jamaisPasProgrammee();
    expect(
      find.text(t.accessibilite.apres.prochaineInconnueVous),
      findsOneWidget,
    );
    expect(find.text(t.accessibilite.apres.prochaineInconnue), findsNothing);
  });

  testWidgets('MA-APRES-1b : vraie salle, Classe de forme production (sans '
      'horloge), travail non branche : non relie et phrase neutre', (
    WidgetTester tester,
  ) async {
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(classeFormeProduction),
      travail: null,
    );
    expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
    _jamaisPasProgrammee();
    expect(
      find.byKey(ApresSeanceAccessibilite.cleTravailNonRelie),
      findsOneWidget,
    );
    expect(find.text(t.tc.parcours.avant.nonBranche), findsOneWidget);
    expect(find.text(t.accessibilite.apres.prochaineInconnue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MA-APRES-1b : vraie salle, Classe de forme production, aucun '
      'travail (port branche, liste vide) : phrase neutre seule', (
    WidgetTester tester,
  ) async {
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(classeFormeProduction),
      travail: const <SlotAction>[],
    );
    _jamaisPasProgrammee();
    expect(
      find.byKey(ApresSeanceAccessibilite.cleTravailNonRelie),
      findsNothing,
    );
    expect(find.text(LibellesGroupe.avantProchainCours), findsNothing);
    expect(find.text(t.accessibilite.apres.prochaineInconnue), findsOneWidget);
  });

  testWidgets('MA-APRES-1b : travail en cours de lecture : chargement, '
      'jamais vide', (WidgetTester tester) async {
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(classeEnDirect),
      portTravail: TravailJamais(),
    );
    expect(find.byKey(ApresSeanceAccessibilite.cleChargement), findsOneWidget);
    _jamaisPasProgrammee();
    expect(find.text(t.accessibilite.accueil.prochaineSeance), findsNothing);
  });

  group('MA-APRES-1b : regle de la prochaine seance', () {
    test('en direct : la seance quittee n est pas la prochaine', () {
      expect(
        ApresSeanceSalle.prochaineApres(
          DonneesClasseDemo.horloge(EtatDemoClasse.enDirect),
        ),
        isNull,
      );
    });
    test('temps ecoule, encore ouverte : pas la prochaine', () {
      expect(
        ApresSeanceSalle.prochaineApres(
          DonneesClasseDemo.horloge(EtatDemoClasse.tempsEcoule),
        ),
        isNull,
      );
    });
    test('salle ouverte avant T0 (debut a venir) : pas la prochaine', () {
      expect(
        ApresSeanceSalle.prochaineApres(
          DonneesClasseDemo.horloge(EtatDemoClasse.attente),
        ),
        isNull,
      );
    });
    test('sans horloge (production) : inconnue', () {
      expect(ApresSeanceSalle.prochaineApres(null), isNull);
    });
    test('a venir, salle fermee, autre seance : la prochaine', () {
      expect(
        ApresSeanceSalle.prochaineApres(
          DonneesClasseDemo.horloge(EtatDemoClasse.aVenir),
          seanceQuitteeId: 's1',
        ),
        DonneesClasseDemo.debutUtc,
      );
    });
    test('a venir mais c est la seance quittee : pas la prochaine', () {
      expect(
        ApresSeanceSalle.prochaineApres(
          DonneesClasseDemo.horloge(EtatDemoClasse.aVenir),
          seanceQuitteeId: 'demo-seance-an-nour',
        ),
        isNull,
      );
    });
  });
}
