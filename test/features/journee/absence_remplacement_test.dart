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
import 'package:rewayah_academy/features/remplacements/remplacements_page.dart';

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
final Finder _offre = find.text('Assurer ce remplacement\u00A0?');
final Finder _urgentFatiha = find.text(
  titreRemplacementUrgent(DonneesEnseignantDemo.offreRemplacement().debut),
);
final Finder _urgentNour = find.text(
  titreRemplacementUrgent(DateTime(2026, 9, 30, 19)),
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

      expect(
        find.text('Vous ne pourrez pas assurer cette séance\u00A0?'),
        findsOne,
      );
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
        find.text('Vous ne pourrez pas assurer cette séance\u00A0?'),
        findsNothing,
      );
      expect(_declarerAbsence, findsOne);
      expect(
        find.byKey(const ValueKey<String>('journee-etat-absence')),
        findsNothing,
      );
    });
  });

  // REMPL-1b : l'offre arrive en Alerte utile « Remplacement urgent », lue
  // dans le tableau commun (seule source des offres) ; elle s'accepte sur
  // l'ecran commun, ou l'alerte mene (mesure sur la vraie coquille dans
  // `test/router/parcours_enseignant_test.dart`). La feuille « Assurer ce
  // remplacement ? » ne s'ouvre plus depuis la Journee.
  group('ENS-13B offre de remplacement', () {
    testWidgets("les offres ouvertes du tableau commun sont l'Alerte utile", (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.text('Alertes utiles'), findsOne);
      // Al-Fatiha (ouverte a tous) et An-Nour (Classe d'hommes) : le
      // tableau de demonstration filtre par genre comme le serveur.
      expect(_urgentFatiha, findsOne);
      expect(_urgentNour, findsOne);
      expect(find.text('Al-Fatiha'), findsOne);
      expect(find.text('An-Nour'), findsWidgets);
      // Maryam (Classe de femmes) n'est pas vue ; Al-Kawthar est prise.
      expect(find.text('Maryam'), findsNothing);
      expect(find.text('Al-Kawthar'), findsNothing);
      expect(_offre, findsNothing);
      expect(_carteRemplacement, findsNothing);
    });

    testWidgets('situation vide : aucune offre', (WidgetTester tester) async {
      await _monter(tester, etat: EtatDemoEnseignant.vide);
      expect(find.textContaining('Remplacement urgent'), findsNothing);
    });
  });
}
