// Directeur, 30/10/2026 : tout compte a rebours passe par le formateur unique
// (LibellesGroupe.compteAReboursAvec). Le libelle court du selecteur du tuteur
// dit les jours au-dela du jour, jamais « 116 h ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  String etatCourt(Duration avant) => AffichageSeance.depuis(
    seanceFictive(debutUtc: instantServeurFige.add(avant)),
    maintenantServeurUtc: instantServeurFige,
  ).etatCourt;

  test('a plus de 48 h : en jours', () {
    expect(
      etatCourt(const Duration(hours: 116, minutes: 52)),
      LibellesGroupe.insecable(t.tuteur.accueil.etatCourt.dansJours(jours: 4)),
    );
  });

  test('dans l heure et dans la journee : inchange', () {
    expect(
      etatCourt(const Duration(hours: 3, minutes: 5)),
      LibellesGroupe.insecable(
        t.tuteur.accueil.etatCourt.dansHeures(heures: 3, minutes: '05'),
      ),
    );
    expect(
      etatCourt(const Duration(minutes: 25)),
      LibellesGroupe.insecable(
        t.tuteur.accueil.etatCourt.dansMinutes(minutes: 25),
      ),
    );
  });
}
