// EN-8 : ENS-13 absence sur une seance et ENS-13B offre de remplacement,
// dans Aujourd'hui, sur la demonstration (/demo/enseignant). Pas de faux
// succes (E7) : aucun etat sans reponse, jamais « Remplacant confirme » sur
// la seule declaration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester, {
  EtatDemoEnseignant etat = EtatDemoEnseignant.nominal,
}) async {
  fixerVueCapture(tester, const Size(390, 1900), 1);
  await tester.pumpWidget(
    hoteCapture(
      CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui, etat: etat),
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

final Finder _declarerAbsence = find.byKey(
  const ValueKey<String>('journee-declarer-absence'),
);
final Finder _absencePrincipale = find.byKey(
  const ValueKey<String>('absence-principale'),
);
final Finder _absenceSecondaire = find.byKey(
  const ValueKey<String>('absence-secondaire'),
);
final Finder _offre = find.text('Assurer ce remplacement ?');
final Finder _remplacementPrincipale = find.byKey(
  const ValueKey<String>('remplacement-principale'),
);
final Finder _remplacementSecondaire = find.byKey(
  const ValueKey<String>('remplacement-secondaire'),
);
final Finder _carteRemplacement = find.byKey(
  const ValueKey<String>(
    'journee-carte-remplacement-demo-seance-al-fatiha-2909',
  ),
);

void main() {
  test('les six etats serveur, mot pour mot du doc 04 §17.2', () {
    expect(EtatAbsence.values.map(libelleEtatAbsence).toList(), <String>[
      'Absence enregistrée',
      "Recherche d'un remplaçant",
      'Remplaçant confirmé',
      'Aucun remplaçant confirmé',
      'Séance annulée',
      'Demande annulée',
    ]);
  });

  group('ENS-13 absence sur une seance', () {
    testWidgets('la feuille reprend la seance, la notice et les deux actions', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _declarerAbsence);

      expect(find.text('Vous ne pourrez pas assurer cette séance ?'), findsOne);
      expect(
        find.text('Votre affectation à la Classe reste inchangée.'),
        findsOne,
      );
      expect(find.text('Déclarer mon absence'), findsOne);
      expect(find.text('Annuler'), findsOne);
      // Aucune option hors du doc : une seule seance, pas de fausse
      // progression, pas de promesse de notification.
      expect(find.text('Plusieurs séances'), findsNothing);
      expect(find.textContaining('Vous serez notifié'), findsNothing);
      expect(find.textContaining('Analyse des disponibilités'), findsNothing);
    });

    testWidgets("l'etat n'arrive qu'avec la reponse, jamais un faux succes", (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _declarerAbsence);
      await tester.tap(_absencePrincipale);
      await tester.pump(const Duration(milliseconds: 100));
      // Envoi en cours : pas encore d'etat.
      expect(find.text("Recherche d'un remplaçant"), findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      await stabiliser(tester);
      expect(find.text("Recherche d'un remplaçant"), findsOne);
      expect(find.text('Remplaçant confirmé'), findsNothing);
      // L'absence n'est declaree qu'une fois.
      expect(_declarerAbsence, findsNothing);
    });

    testWidgets('sans reponse (hors ligne), la feuille le dit, aucun etat', (
      WidgetTester tester,
    ) async {
      await _monter(tester, etat: EtatDemoEnseignant.horsLigne);
      await _toucher(tester, _declarerAbsence);
      await tester.tap(_absencePrincipale);
      await tester.pump(const Duration(milliseconds: 700));
      await stabiliser(tester);

      expect(find.byKey(const ValueKey<String>('absence-echec')), findsOne);
      for (final EtatAbsence e in EtatAbsence.values) {
        expect(find.text(libelleEtatAbsence(e)), findsNothing);
      }
    });

    testWidgets('Annuler ferme la feuille sans rien declarer', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _declarerAbsence);
      await _toucher(tester, _absenceSecondaire);

      expect(
        find.text('Vous ne pourrez pas assurer cette séance ?'),
        findsNothing,
      );
      expect(_declarerAbsence, findsOne);
      expect(
        find.byKey(const ValueKey<String>('journee-etat-absence')),
        findsNothing,
      );
    });
  });

  group('ENS-13B offre de remplacement', () {
    testWidgets("l'offre est une Alerte utile, la feuille montre la seance", (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.text('Alertes utiles'), findsOne);
      expect(_offre, findsOne);
      expect(_carteRemplacement, findsNothing);

      await _toucher(tester, _offre);
      expect(find.text('Al-Fatiha'), findsWidgets);
      expect(find.text('Heure locale'), findsOne);
      expect(find.text('3 élèves'), findsWidgets);
      expect(find.text('Assurer ce remplacement'), findsOne);
      expect(find.text('Pas cette fois'), findsOne);
    });

    testWidgets('confirme par le serveur : la carte « Remplacement »', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _offre);
      await tester.tap(_remplacementPrincipale);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_carteRemplacement, findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      await stabiliser(tester);
      expect(_carteRemplacement, findsOne);
      expect(
        find.descendant(
          of: _carteRemplacement,
          matching: find.text('Remplacement'),
        ),
        findsOne,
      );
      // E11, doc 04 §17.3 : le remplacant ouvre la Classe remplacee.
      expect(
        find.descendant(
          of: _carteRemplacement,
          matching: find.text('Voir la Classe'),
        ),
        findsOne,
      );
      // L'offre acceptee quitte les alertes.
      expect(_offre, findsNothing);
    });

    testWidgets('sans reponse (hors ligne) : aucune carte', (
      WidgetTester tester,
    ) async {
      await _monter(tester, etat: EtatDemoEnseignant.horsLigne);
      await _toucher(tester, _offre);
      await tester.tap(_remplacementPrincipale);
      await tester.pump(const Duration(milliseconds: 700));
      await stabiliser(tester);

      expect(
        find.byKey(const ValueKey<String>('remplacement-echec')),
        findsOne,
      );
      expect(_carteRemplacement, findsNothing);
    });

    testWidgets("« Pas cette fois » ferme la feuille, l'offre reste", (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _toucher(tester, _offre);
      await _toucher(tester, _remplacementSecondaire);

      expect(_carteRemplacement, findsNothing);
      expect(_offre, findsOne);
    });

    testWidgets('situation vide : aucune offre', (WidgetTester tester) async {
      await _monter(tester, etat: EtatDemoEnseignant.vide);
      expect(_offre, findsNothing);
    });
  });
}
