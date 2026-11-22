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
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
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

final DemandeAdmission _nouvelOnboarding = DemandeAdmission(
  id: 'c9',
  reference: 'CAND-2026-0009',
  nom: 'Fatou Diop',
  courriel: 'fatou@example.org',
  recueLe: DateTime.utc(2026, 11, 22, 10),
  etat: EtatDemandeAdmission.aTraiter,
  version: 1,
  source: 'mosquee',
  suivi: 'chingford-londres',
  apprenants: <ApprenantAdmission>[
    const ApprenantAdmission(
      prenom: 'Enfant Un',
      titulaire: false,
      age: 8,
      genre: 'male',
      niveau: 'debut_lettres',
      objectif: 'priere_invocations',
      langue: 'francais',
      langueSecours: 'ha',
      langueAutre: 'Tamoul',
    ),
    const ApprenantAdmission(
      prenom: 'Enfant Deux',
      titulaire: false,
      age: 12,
      genre: 'female',
      niveau: 'memorisation_partielle',
      objectif: 'memoriser',
      riwaya: 'warsh',
      memorise: 'quelques_sourates',
      sourates: <String>['fatiha', 'nas', 'ikhlas'],
      langue: 'francais',
    ),
    const ApprenantAdmission(
      prenom: 'Fatou',
      titulaire: true,
      genre: 'female',
      niveau: 'memorisation_partielle',
      objectif: 'memoriser',
      riwaya: 'autre',
      riwayaAutre: 'Qalun',
      memorise: '1_5_juz',
      juz: <int>[30, 29],
      langue: 'xx',
    ),
  ],
);

Widget _bloc([DemandeAdmission? demande]) =>
    ReponsesAdmission(demande: demande ?? _demande, date: '28 octobre');

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
    for (final String brut in <String>[
      'female',
      'lecture_lente',
      'memoriser',
    ]) {
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
      LibellesGroupe.insecable(r.ageValeur(age: 9)),
      r.fille,
      r.non,
    ]) {
      expect(
        find.descendant(of: carte, matching: find.text(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    // Niveau, objectif et langue manquent : dits, pas masques. Les moments
    // (le nouvel onboarding n'en demande pas) et les lignes sans objet
    // (lecture, memorise) ne sont pas montres.
    expect(
      find.descendant(of: carte, matching: find.text(r.nonRenseigne)),
      findsNWidgets(3),
    );
    for (final String ligne in <String>[r.moments, r.lecture, r.memorise]) {
      expect(
        find.descendant(of: carte, matching: find.text(ligne)),
        findsNothing,
        reason: ligne,
      );
    }
  });

  testWidgets('titulaire : source en mots et lien de suivi', (tester) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc(_nouvelOnboarding)));
    final Finder carte = find.byKey(ReponsesAdmission.cleTitulaire);
    expect(
      find.descendant(
        of: carte,
        matching: find.text(t.onboarding.recap.sources.mosquee),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: carte,
        matching: find.textContaining('chingford-londres'),
      ),
      findsOneWidget,
    );
    expect(find.text('mosquee'), findsNothing);
    // Sans source ni lien : « Non renseigne », et pas de ligne de lien.
    await tester.pumpWidget(hoteTheme(_bloc(_demande)));
    expect(
      find.descendant(of: carte, matching: find.text(r.nonRenseigne)),
      findsOneWidget,
    );
    expect(find.text(r.suivi), findsNothing);
  });

  testWidgets('debutant : priere, langue, secours et langue absente', (
    tester,
  ) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc(_nouvelOnboarding)));
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(0));
    for (final String texte in <String>[
      t.onboarding.recap.objectifs.priere,
      t.onboarding.langues.francais,
      r.langueSecours,
      t.onboarding.langues.ha,
      r.langueAutre,
      'Tamoul',
    ]) {
      expect(
        find.descendant(of: carte, matching: find.textContaining(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    // Un debutant n'a ni lecture ni memorise.
    expect(
      find.descendant(of: carte, matching: find.text(r.lecture)),
      findsNothing,
    );
    expect(
      find.descendant(of: carte, matching: find.text(r.memorise)),
      findsNothing,
    );
    for (final String brut in <String>['priere_invocations', 'francais']) {
      expect(find.textContaining(brut), findsNothing, reason: brut);
    }
  });

  testWidgets('memorise : lecture, quantite, sourates en noms', (tester) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc(_nouvelOnboarding)));
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(1));
    for (final String texte in <String>[
      t.onboarding.lecture.warsh,
      t.onboarding.memorise.quelques,
      '${t.onboarding.sourates.fatiha}, ${t.onboarding.sourates.nas}',
      r.sourates,
    ]) {
      expect(
        find.descendant(of: carte, matching: find.textContaining(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    for (final String brut in <String>[
      'warsh',
      'quelques_sourates',
      'fatiha',
    ]) {
      expect(find.textContaining(brut), findsNothing, reason: brut);
    }
  });

  testWidgets('parent : autre lecture ecrite, juz tries, langue inconnue', (
    tester,
  ) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(hoteTheme(_bloc(_nouvelOnboarding)));
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(2));
    for (final String texte in <String>[
      'Qalun',
      t.onboarding.memorise.unACinq,
      '${t.onboarding.detail.juz(n: 29)}, ${t.onboarding.detail.juz(n: 30)}',
      r.langueHorsListe,
    ]) {
      expect(
        find.descendant(of: carte, matching: find.textContaining(texte)),
        findsWidgets,
        reason: texte,
      );
    }
    // Un code de langue inconnu ne s'affiche jamais.
    expect(find.textContaining('xx'), findsNothing);
  });

  testWidgets('memorise sans detail : Non renseigne, pas de ligne vide', (
    tester,
  ) async {
    fixerVue(tester, vueBureau);
    await tester.pumpWidget(
      hoteTheme(
        _bloc(
          DemandeAdmission(
            id: 'c3',
            reference: 'CAND-2026-0003',
            nom: 'Omar Sy',
            recueLe: DateTime.utc(2026, 11, 22),
            etat: EtatDemandeAdmission.aTraiter,
            version: 1,
            apprenants: const <ApprenantAdmission>[
              ApprenantAdmission(
                prenom: 'Omar',
                titulaire: true,
                niveau: 'memorisation_partielle',
                memorise: 'quelques_sourates',
              ),
            ],
          ),
        ),
      ),
    );
    final Finder carte = find.byKey(ReponsesAdmission.cleApprenant(0));
    expect(
      find.descendant(of: carte, matching: find.text(r.sourates)),
      findsOne,
    );
    expect(
      find.descendant(of: carte, matching: find.text(r.juz)),
      findsNothing,
    );
    // Lecture, sourates, objectif, langue : absents, dits.
    expect(
      find.descendant(of: carte, matching: find.text(r.nonRenseigne)),
      findsAtLeastNWidgets(4),
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
        testWidgets('sans debordement a ${vue.width.toInt()} px, '
            'texte x${echelle.toInt()}, ${lum.name}', (tester) async {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              _bloc(_nouvelOnboarding),
              echelleTexte: echelle,
              luminosite: lum,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
