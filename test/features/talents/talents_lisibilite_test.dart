// CAND-07 : la lisibilite du parcours « Vos autres talents » entier. A chaque
// etape (introduction, competences par famille avec « Autre domaine » choisi,
// niveaux, disponibilite et accord) puis aux reponses enregistrees et au portail,
// pour chaque configuration (320 a 1440, texte x1 et x2, francais et arabe de
// droite a gauche) : aucun debordement, aucun mot coupe ni tronque, un seul
// bouton plein.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/garde_interface.dart';
import 'hote_talents.dart';

/// Verifie l'ecran courant, defile de haut en bas, en nommant l'etape : la
/// garde du rendu du depot (mots coupes, textes rognes, ponctuation seule,
/// debordements), avec les vraies polices.
Future<void> _verifier(WidgetTester tester, String etape) async {
  final List<String> fautes = await defautsEcranDefile(tester);
  expect(fautes, isEmpty, reason: 'defaut de texte a $etape');
  verifierUnSeulBoutonPlein(tester);
}

String _niveau(NiveauCompetence n) => switch (n) {
  NiveauCompetence.debutant => t.recrutement.talents.niveaux.debutant.libelle,
  NiveauCompetence.experience =>
    t.recrutement.talents.niveaux.experience.libelle,
  NiveauCompetence.metier => t.recrutement.talents.niveaux.metier.libelle,
};

Future<void> _parcourir(
  WidgetTester tester, {
  required Size taille,
  double echelle = 1,
  TextDirection? direction,
}) async {
  await monterTalents(
    tester,
    port: FauxAutresCompetences(),
    taille: taille,
    echelle: echelle,
    direction: direction,
  );
  await _verifier(tester, 'introduction');
  await continuerTalents(tester);
  await _verifier(tester, 'competences');
  // Une competence dans chaque famille, « Autre domaine » compris : le champ.
  for (final String code in <String>[
    'reseaux_sociaux',
    'assistanat',
    'comptabilite',
    'tests_niveau',
    'assistance_technique',
    'autre',
  ]) {
    await toucherTalents(tester, 'talent-$code');
  }
  await tester.enterText(
    find.byType(TextField),
    direction == TextDirection.rtl ? 'سكرتارية طبية' : 'Secrétariat médical',
  );
  await tester.pump();
  await _verifier(tester, 'competences choisies');
  await continuerTalents(tester);
  await _verifier(tester, 'niveaux, aucun niveau choisi');
  // Le message de ce qui manque se lit aussi.
  await continuerTalents(tester);
  await _verifier(tester, 'niveaux, un niveau manque');
  for (final String code in <String>[
    'reseaux_sociaux',
    'assistanat',
    'comptabilite',
    'tests_niveau',
    'assistance_technique',
    'autre',
  ]) {
    await toucherTexteTalents(
      tester,
      find.descendant(
        of: cleTalents('talents-niveau-$code'),
        matching: find.text(_niveau(NiveauCompetence.experience)),
      ),
    );
  }
  await _verifier(tester, 'niveaux choisis');
  await continuerTalents(tester);
  await _verifier(tester, 'disponibilite');
  await toucherTalents(tester, 'talents-dispo-mi_temps');
  await toucherTalents(tester, 'talents-accord');
  await _verifier(tester, 'disponibilite et accord choisis');
  await continuerTalents(tester);
  await _verifier(tester, 'reponses enregistrees');
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('390 x1', const Size(390, 844), 1),
        ('320 x1', const Size(320, 568), 1),
        ('320 x2', const Size(320, 568), 2),
        ('768 x1', const Size(768, 1024), 1),
        ('1440 x1', const Size(1440, 900), 1),
        ('1440 x2', const Size(1440, 900), 2),
      ]) {
    testWidgets('francais, $nom : le parcours entier se lit', (
      WidgetTester tester,
    ) async {
      await _parcourir(tester, taille: taille, echelle: echelle);
    });
  }

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('390 x1', const Size(390, 844), 1),
        ('320 x2', const Size(320, 568), 2),
        ('1440 x1', const Size(1440, 900), 1),
      ]) {
    testWidgets('arabe de droite a gauche, $nom : le parcours entier se lit', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _parcourir(
        tester,
        taille: taille,
        echelle: echelle,
        direction: TextDirection.rtl,
      );
    });
  }

  // Les reponses enregistrees, l'etat de la candidature terminee, la page pas
  // encore ouverte, le portail : aux gabarits les plus durs. Un montage par
  // test (une portee de lecture neuve a chaque fois).
  for (final (String nom, Size taille, double echelle, AppLocale langue)
      in <(String, Size, double, AppLocale)>[
        ('390 x1 francais', const Size(390, 844), 1, AppLocale.fr),
        ('320 x2 francais', const Size(320, 568), 2, AppLocale.fr),
        ('1440 x1 francais', const Size(1440, 900), 1, AppLocale.fr),
        ('320 x2 arabe', const Size(320, 568), 2, AppLocale.ar),
      ]) {
    for (final String etat in <String>[
      'reponses',
      'candidature terminee',
      'pas encore ouvert',
      'portail avec la tuile',
    ]) {
      testWidgets('$etat, $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        final Map<String, Object?> reponses = reponsesJsonDeTest(
          domaines: const <String, String>{
            'reseaux_sociaux': 'experience',
            'comptabilite': 'metier',
            'autre': 'debutant',
            'assistance_technique': 'metier',
          },
          autreTexte: langue == AppLocale.ar
              ? 'سكرتارية طبية'
              : 'Secrétariat médical',
        );
        final Map<String, dynamic> lecture = switch (etat) {
          'reponses' => autresCompetencesJsonDeTest(
            version: 2,
            reponses: reponses,
          ),
          'candidature terminee' => autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'candidature_close',
            version: 2,
            reponses: reponses,
          ),
          'pas encore ouvert' => autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'questionnaire_non_envoye',
          ),
          _ => autresCompetencesJsonDeTest(),
        };
        await monterTalents(
          tester,
          port: FauxAutresCompetences(lectureJson: lecture),
          taille: taille,
          echelle: echelle,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          depart: etat == 'portail avec la tuile'
              ? Routes.attente
              : Routes.attenteTalents,
        );
        await _verifier(tester, '$etat, $nom');
      });
    }
  }
}
