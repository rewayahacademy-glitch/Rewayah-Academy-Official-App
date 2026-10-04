// MA-APRES-1 (decision A7 = a) : en Mode Accessibilite, UN SEUL ecran de
// fin. On monte la VRAIE salle (`SallePage`, route `Routes.salle`) d'une
// eleve en Mode Accessibilite, on tape « Quitter le cours » puis on confirme :
// c'est l'ecran de MA-6 (ApresSeanceAccessibilite) qui s'affiche, jamais
// l'ancien `ResultatSeance` (« Retour a l'accueil », coche de succes, « La
// seance est terminee. » apres Quitter). La prochaine seance porte son heure,
// et l'ecran a ses cinq etats : chargement, contenu, vide, erreur, hors ligne.
//
// Horloge fixe : la Classe de demonstration « a venir » (instants figes de
// `DonneesClasseDemo`) ; aucun `DateTime.now()` dans ce qui est mesure.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';

import 'support_ma_apres1.dart';

void _ecranUnique(WidgetTester tester) {
  expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
  // L'ancien ecran de fin n'est plus monte en Mode Accessibilite.
  expect(find.byType(ResultatSeance), findsNothing);
  expect(find.text(t.salle.fin.retourAccueil), findsNothing);
  // Apres « Quitter », le resultat dit la sortie, jamais « terminee ».
  expect(find.text(t.salle.fin.titreGuidee), findsNothing);
  expect(find.text(t.accessibilite.apres.quitteTitre), findsOneWidget);
  // « Retour a la Classe » toujours la, seul bouton plein ; aide en dernier.
  expect(find.byKey(ApresSeanceAccessibilite.cleRetourClasse), findsOneWidget);
  expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final (Size taille, double echelle) in <(Size, double)>[
    (const Size(390, 844), 1),
    (const Size(390, 844), 2),
    (const Size(1440, 900), 1),
  ]) {
    testWidgets('MA-APRES-1 : vraie salle, ${taille.width.toInt()} x$echelle, '
        'contenu : ecran unique, heure de la prochaine seance, retour', (
      WidgetTester tester,
    ) async {
      await quitterLaSalleMa(
        tester,
        groupes: GroupesMaApres(classeAVenir),
        taille: taille,
        echelle: echelle,
      );
      _ecranUnique(tester);
      expect(find.byType(ActionPrincipale), findsOneWidget);
      // La prochaine seance porte la date ET l'heure de l'appareil.
      final String prochaine = ApresSeanceAccessibilite.libelleProchaine(
        DonneesClasseDemo.debutUtc,
      );
      final DateTime local = DonneesClasseDemo.debutUtc.toLocal();
      expect(
        prochaine,
        contains(
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}',
        ),
      );
      expect(find.text(prochaine), findsOneWidget);
      // Ordre de MA-6 : resultat, travail, support, prochaine seance, aide.
      final List<Finder> ordre = <Finder>[
        find.byKey(ApresSeanceAccessibilite.cleRetourClasse),
        find.text(LibellesGroupe.avantProchainCours),
        find.text(t.accessibilite.apres.revoirSupport),
        find.text(t.accessibilite.accueil.prochaineSeance),
        find.text(t.accessibilite.accueil.aide),
      ];
      for (int i = 1; i < ordre.length; i++) {
        expect(ordre[i], findsOneWidget);
        expect(
          tester.getTopLeft(ordre[i]).dy,
          greaterThan(tester.getTopLeft(ordre[i - 1]).dy),
        );
      }
      final Finder retour = find.byKey(
        ApresSeanceAccessibilite.cleRetourClasse,
      );
      await tester.ensureVisible(retour);
      await tester.tap(retour);
      await stabiliserMaApres(tester);
      expect(find.text('ma classe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('MA-APRES-1 : chargement, la sortie reste a l ecran', (
    WidgetTester tester,
  ) async {
    final Completer<GroupSummaryVM?> jamais = Completer<GroupSummaryVM?>();
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(() => jamais.future),
    );
    _ecranUnique(tester);
    expect(find.byKey(ApresSeanceAccessibilite.cleChargement), findsOneWidget);
    expect(find.text(t.accessibilite.accueil.prochaineSeance), findsNothing);
  });

  testWidgets('MA-APRES-1b : Classe introuvable, vide : phrase neutre, '
      'jamais « pas encore programmee »', (WidgetTester tester) async {
    await quitterLaSalleMa(tester, groupes: GroupesMaApres(() async => null));
    _ecranUnique(tester);
    expect(find.byKey(ApresSeanceAccessibilite.cleVide), findsOneWidget);
    expect(find.text(t.accessibilite.apres.prochaineInconnue), findsOneWidget);
    expect(find.text(t.accessibilite.apres.vide), findsNothing);
    expect(find.text(t.accessibilite.accueil.prochaineSeance), findsNothing);
  });

  testWidgets('MA-APRES-1 : erreur, ce qui manque et Reessayer relit', (
    WidgetTester tester,
  ) async {
    final GroupesMaApres groupes = GroupesMaApres(
      () => Future<GroupSummaryVM?>.error(StateError('reseau')),
    );
    await quitterLaSalleMa(tester, groupes: groupes);
    _ecranUnique(tester);
    expect(find.byKey(ApresSeanceAccessibilite.cleErreur), findsOneWidget);
    expect(find.text(t.accessibilite.apres.erreur), findsOneWidget);
    final int avant = groupes.lectures;
    final Finder reessayer = find.text(t.commun.reessayer);
    await tester.ensureVisible(reessayer);
    await tester.tap(reessayer);
    await stabiliserMaApres(tester);
    expect(groupes.lectures, greaterThan(avant));
  });

  testWidgets('MA-APRES-1 : hors ligne, dit ce qui attend la connexion', (
    WidgetTester tester,
  ) async {
    await quitterLaSalleMa(
      tester,
      groupes: GroupesMaApres(classeAVenir),
      horsLigne: true,
    );
    _ecranUnique(tester);
    expect(find.byKey(ApresSeanceAccessibilite.cleHorsLigne), findsOneWidget);
    expect(find.text(t.accessibilite.apres.horsLigne), findsOneWidget);
  });
}
