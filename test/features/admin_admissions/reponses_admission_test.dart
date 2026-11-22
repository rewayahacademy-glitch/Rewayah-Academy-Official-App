// ADMISSIONS-REPONSES (directeur, 22/11/2026) : la direction lit tout ce que
// la famille a repondu, sans rien ouvrir d'autre.
//
// Ce que le test prouve : le titulaire (nom, e-mail, date, reference) ; une
// carte par apprenant avec age ou « Adulte », genre en mots (Garcon, Fille,
// Homme, Femme), niveau, objectif, moments et langue en mots, titulaire oui ou
// non ; une reponse absente dit « Non renseigne » ; aucun code brut a
// l'ecran ; 320 et 1440 px, texte x1 et x2, clair et sombre, sans
// debordement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admission/port_admissions_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_admissions/reponses_admission.dart';

import '../../support/hote_theme.dart';

final DemandeAdmission _demande = DemandeAdmission(
  id: 'c1',
  reference: 'CAND-2026-0001',
  nom: 'Awa Bah',
  courriel: 'awa@example.org',
  recueLe: DateTime.utc(2026, 10, 28, 10),
  etat: EtatDemandeAdmission.aTraiter,
  version: 1,
  apprenants: <ApprenantAdmission>[
    const ApprenantAdmission(
      prenom: 'Awa',
      titulaire: true,
      genre: 'female',
      niveau: 'lecture_lente',
      objectif: 'memoriser',
      moments: <String>['matin', 'soir'],
      langue: 'fr',
    ),
    const ApprenantAdmission(
      prenom: 'Yasmine',
      titulaire: false,
      age: 9,
      genre: 'female',
    ),
  ],
);

Widget _bloc() => ReponsesAdmission(demande: _demande, date: '28 octobre');

void main() {
  final r = t.admissions.reponses;

  testWidgets('le titulaire : nom, e-mail, date, reference', (tester) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc()));
    final Finder carte = find.byKey(ReponsesAdmission.cleTitulaire);
    for (final String texte in <String>[
      'Awa Bah',
      'awa@example.org',
      '28 octobre',
      'CAND-2026-0001',
    ]) {
      expect(
        find.descendant(of: carte, matching: find.text(texte)),
        findsOneWidget,
        reason: texte,
      );
    }
  });

  testWidgets('apprenant adulte : toutes les reponses en mots', (tester) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc()));
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(0));
    for (final String texte in <String>[
      'Awa',
      r.adulte,
      r.femme,
      r.moments,
      '${t.parcours.momentMatin}, ${t.parcours.momentSoir}',
      t.parcours.objectifMemoriser,
      t.parcours.niveauLectureLente,
      r.oui,
    ]) {
      expect(
        find.descendant(of: carte, matching: find.text(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    // Aucun code brut.
    for (final String brut in <String>['female', 'lecture_lente', 'memoriser']) {
      expect(find.textContaining(brut), findsNothing, reason: brut);
    }
  });

  testWidgets('enfant : age, fille, titulaire non, reste non renseigne', (
    tester,
  ) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc()));
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(1));
    for (final String texte in <String>[
      'Yasmine',
      r.ageValeur(age: 9),
      r.fille,
      r.non,
    ]) {
      expect(
        find.descendant(of: carte, matching: find.text(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    // Niveau, objectif, moments et langue manquent : dits, pas masques.
    expect(
      find.descendant(of: carte, matching: find.text(r.nonRenseigne)),
      findsNWidgets(4),
    );
  });

  testWidgets('aucun apprenant : une phrase', (tester) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(
      hoteTheme(
        ReponsesAdmission(
          demande: DemandeAdmission(
            id: 'c2',
            reference: 'CAND-2026-0002',
            nom: 'Salma Kone',
            recueLe: DateTime.utc(2026, 10, 28),
            etat: EtatDemandeAdmission.aTraiter,
            version: 1,
          ),
          date: '28 octobre',
        ),
      ),
    );
    expect(find.text(r.aucunApprenant), findsOneWidget);
  });

  for (final Size vue in <Size>[const Size(320, 640), vueBureau]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        testWidgets(
          'sans debordement a ${vue.width.toInt()} px, '
          'texte x${echelle.toInt()}, ${lum.name}',
          (tester) async {
            fixerVue(tester, vue);
            await tester.pumpWidget(
              hoteTheme(_bloc(), echelleTexte: echelle, luminosite: lum),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
