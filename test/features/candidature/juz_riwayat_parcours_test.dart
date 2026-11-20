// PE-B1 et PE-B8 dans le vrai parcours du candidat (questionnaire servi par
// le double du serveur, a la forme de la migration 20261130920000 : juz_1 a
// juz_29 proposes).
//
// Ce que le test prouve :
// - juz : trois cartes ; « un nombre precis » ouvre le compteur (1 juz) et les
//   raccourcis ; le brouillon part avec `juz_N` ; une ancienne tranche se relit,
//   reste retenue telle quelle et se dit au-dessus du compteur ; sans juz_N au
//   serveur (avant la migration), les quatre anciennes cartes restent ;
// - riwayat : les dix (20 codes), les sept (14 codes), une seule (un code),
//   quelques-unes (grille par lecteur) ; une ancienne reponse se relit dans son
//   mode ;
// - l'aide de l'ijaza et celle du juz se deplient.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import 'hote_candidature.dart';

Object? _dernier(FauxMaCandidature port, String champ) =>
    port.brouillons.isEmpty ? null : port.brouillons.last[champ];

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('juz', () {
    testWidgets('trois cartes ; un nombre precis part en juz_N', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireAvecJuz(),
      );
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      for (final String c in <String>['coran_entier', 'nombre', 'aucune']) {
        expect(
          find.byKey(ValueKey<String>('option-$champMemorisation-$c')),
          findsOneWidget,
          reason: c,
        );
      }
      // Les tranches ne sont plus proposees.
      expect(
        find.byKey(
          const ValueKey<String>('option-$champMemorisation-moins_10_juz'),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('juz-compteur')), findsNothing);
      await toucherCle(tester, 'option-$champMemorisation-nombre');
      expect(
        find.byKey(const ValueKey<String>('juz-compteur')),
        findsOneWidget,
      );
      // Aucun nombre par defaut : le compteur attend un choix.
      expect(find.text(t.recrutement.parcours.juz.choisir), findsOneWidget);
      await toucherCle(tester, 'juz-raccourci-15');
      await continuer(tester);
      expect(_dernier(port, champMemorisation), 'juz_15');
    });

    testWidgets('tout le Coran et rien gardent leurs codes', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireAvecJuz(),
      );
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      await toucherCle(tester, 'option-$champMemorisation-coran_entier');
      await continuer(tester);
      expect(_dernier(port, champMemorisation), 'coran_entier');
    });

    testWidgets('une ancienne tranche se relit et reste valable', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireAvecJuz(
          dernieresReponses: <String, Object?>{
            'langueMaternelle': 'poular',
            'languesExplication': <String>['poular'],
            champMemorisation: 'moins_10_juz',
          },
        ),
      );
      await monterQuestionnaire(tester, port: port);
      // Le brouillon reprend a la question suivante : on revient d'un ecran.
      await toucherCle(tester, 'parcours-retour');
      expect(
        find.byKey(const ValueKey<String>('juz-ancienne')),
        findsOneWidget,
      );
      expect(
        find.text(
          t.recrutement.dossier3.synthese.memorisationValeurs.moins_10_juz,
        ),
        findsOneWidget,
      );
      await continuer(tester);
      expect(_dernier(port, champMemorisation), 'moins_10_juz');
    });

    testWidgets('un nombre precis sans nombre : rien n est retenu, Continuer '
        'demande le nombre', (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireAvecJuz(),
      );
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      // « Rien » puis « un nombre precis » : « rien » ne vaut plus.
      await toucherCle(tester, 'option-$champMemorisation-aucune');
      await toucherCle(tester, 'option-$champMemorisation-nombre');
      final int avant = port.brouillons.length;
      await continuer(tester);
      expect(port.brouillons.length, avant);
      expect(
        find.byKey(const ValueKey<String>('juz-compteur')),
        findsOneWidget,
        reason: 'le parcours reste sur la question',
      );
      // « plus » donne 1 juz, un vrai choix.
      await toucherCle(tester, 'choix-nombre-plus');
      await continuer(tester);
      expect(_dernier(port, champMemorisation), 'juz_1');
    });

    for (final (String tranche, String touche, String attendu)
        in <(String, String, String)>[
          ('moins_10_juz', 'choix-nombre-plus', 'juz_6'),
          ('moins_10_juz', 'choix-nombre-moins', 'juz_4'),
          ('de_10_a_29_juz', 'choix-nombre-plus', 'juz_16'),
          ('de_10_a_29_juz', 'choix-nombre-moins', 'juz_14'),
        ]) {
      testWidgets('ancienne tranche $tranche : $touche donne $attendu, dans '
          'la tranche', (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireAvecJuz(
            dernieresReponses: <String, Object?>{
              'langueMaternelle': 'poular',
              'languesExplication': <String>['poular'],
              champMemorisation: tranche,
            },
          ),
        );
        await monterQuestionnaire(tester, port: port);
        await toucherCle(tester, 'parcours-retour');
        await toucherCle(tester, touche);
        await continuer(tester);
        expect(_dernier(port, champMemorisation), attendu);
      });
    }

    testWidgets('un nombre precis puis retour sans nombre : l ancienne '
        'reponse revient', (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireAvecJuz(
          dernieresReponses: <String, Object?>{
            'langueMaternelle': 'poular',
            'languesExplication': <String>['poular'],
            champMemorisation: 'coran_entier',
          },
        ),
      );
      await monterQuestionnaire(tester, port: port);
      await toucherCle(tester, 'parcours-retour');
      await toucherCle(tester, 'option-$champMemorisation-nombre');
      expect(find.text(t.recrutement.parcours.juz.choisir), findsOneWidget);
      // Retour a la question precedente, puis de nouveau la memorisation.
      await toucherCle(tester, 'parcours-retour');
      await continuer(tester);
      expect(
        find.byKey(const ValueKey<String>('juz-compteur')),
        findsNothing,
        reason: 'tout le Coran est de nouveau choisi, pas le compteur vide',
      );
      final int avant = port.brouillons.length;
      await continuer(tester);
      expect(port.brouillons.length, greaterThan(avant));
      expect(_dernier(port, champMemorisation), 'coran_entier');
    });

    testWidgets('sans juz_N au serveur : les quatre anciennes cartes', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      expect(
        find.byKey(
          const ValueKey<String>('option-$champMemorisation-moins_10_juz'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('option-$champMemorisation-nombre')),
        findsNothing,
      );
    });

    testWidgets('l aide du juz se deplie', (WidgetTester tester) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(questionnaireJson: questionnaireAvecJuz()),
      );
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      expect(
        find.byKey(const ValueKey<String>('aide-juz-texte')),
        findsNothing,
      );
      await toucherCle(tester, 'aide-juz');
      expect(find.text(t.recrutement.parcours.aides.juzTexte), findsOneWidget);
    });
  });

  group('riwayat', () {
    Future<FauxMaCandidature> ouvrir(
      WidgetTester tester, {
      Map<String, Object?>? dernieresReponses,
    }) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: dernieresReponses,
        ),
      );
      await monterQuestionnaire(tester, port: port);
      await repondreAvant(tester, 'riwayat');
      return port;
    }

    testWidgets('les dix : les vingt codes', (WidgetTester tester) async {
      final FauxMaCandidature port = await ouvrir(tester);
      await toucherCle(tester, 'option-riwayat-dix');
      await continuer(tester);
      expect((_dernier(port, 'riwayat')! as List<Object?>).toSet(), riwayatDix);
    });

    testWidgets('les sept : les quatorze codes', (WidgetTester tester) async {
      final FauxMaCandidature port = await ouvrir(tester);
      await toucherCle(tester, 'option-riwayat-sept');
      await continuer(tester);
      expect(
        (_dernier(port, 'riwayat')! as List<Object?>).toSet(),
        riwayatSept,
      );
    });

    testWidgets('une seule : un code', (WidgetTester tester) async {
      final FauxMaCandidature port = await ouvrir(tester);
      await toucherCle(tester, 'option-riwayat-une');
      await toucherCle(tester, 'option-riwayat-warsh');
      await continuer(tester);
      expect(_dernier(port, 'riwayat'), <String>['warsh']);
    });

    testWidgets('quelques-unes : la grille par lecteur, l ordre du serveur', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = await ouvrir(tester);
      await toucherCle(tester, 'option-riwayat-quelques');
      expect(
        find.text(t.recrutement.parcours.riwayat.lecteurs.ibnKathir),
        findsOneWidget,
      );
      await toucherCle(tester, 'option-riwayat-warsh');
      await toucherCle(tester, 'option-riwayat-hafs');
      await toucherCle(tester, 'option-riwayat-ruways');
      await continuer(tester);
      expect(_dernier(port, 'riwayat'), <String>['hafs', 'warsh', 'ruways']);
    });

    for (final (String nom, List<String> codes) in <(String, List<String>)>[
      ('vingt codes', <String>[for (final l in lecteursRiwayat) ...l.riwayat]),
      ('quatorze codes des sept', riwayatSept.toList()),
    ]) {
      testWidgets('relue, une reponse de $nom s ouvre sur la grille, jamais '
          'sur une ijaza', (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'langueMaternelle': 'poular',
              'languesExplication': <String>['poular'],
              champMemorisation: 'coran_entier',
              'niveauLectureTajwid': 'tajwid_enseigne',
              'riwayat': codes,
            },
          ),
        );
        await monterQuestionnaire(tester, port: port);
        await toucherCle(tester, 'parcours-retour');
        expect(
          find.text(t.recrutement.parcours.riwayat.titreQuelques),
          findsOneWidget,
        );
        await continuer(tester);
        expect(_dernier(port, 'riwayat'), codes);
      });
    }

    testWidgets('« une seule » ne vide pas plusieurs riwayat ; « quelques-'
        'unes » les retrouve', (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: <String, Object?>{
            'langueMaternelle': 'poular',
            'languesExplication': <String>['poular'],
            champMemorisation: 'coran_entier',
            'niveauLectureTajwid': 'tajwid_enseigne',
            'riwayat': <String>['hafs', 'warsh'],
          },
        ),
      );
      await monterQuestionnaire(tester, port: port);
      await toucherCle(tester, 'parcours-retour');
      await toucherCle(tester, 'option-riwayat-une');
      await toucherCle(tester, 'option-riwayat-quelques');
      await continuer(tester);
      expect(_dernier(port, 'riwayat'), <String>['hafs', 'warsh']);
    });

    testWidgets('« une seule » sans choix : Continuer demande, rien ne part ; '
        'au retour, la grille avec les riwayat gardees', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: <String, Object?>{
            'langueMaternelle': 'poular',
            'languesExplication': <String>['poular'],
            champMemorisation: 'coran_entier',
            'niveauLectureTajwid': 'tajwid_enseigne',
            'riwayat': <String>['hafs', 'warsh'],
          },
        ),
      );
      await monterQuestionnaire(tester, port: port);
      await toucherCle(tester, 'parcours-retour');
      await toucherCle(tester, 'option-riwayat-une');
      final int avant = port.brouillons.length;
      await continuer(tester);
      // L'ecran montre « une seule » sans riwaya : rien ne part, la question
      // reste.
      expect(port.brouillons.length, avant);
      expect(
        find.text(t.recrutement.parcours.riwayat.titreUne),
        findsOneWidget,
      );
      // Quitter la question, y revenir : la grille, les deux riwayat.
      await toucherCle(tester, 'parcours-retour');
      await continuer(tester);
      expect(
        find.text(t.recrutement.parcours.riwayat.titreQuelques),
        findsOneWidget,
      );
      await continuer(tester);
      expect(_dernier(port, 'riwayat'), <String>['hafs', 'warsh']);
    });

    testWidgets('une ancienne reponse se relit dans son mode', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: <String, Object?>{
              'langueMaternelle': 'poular',
              'languesExplication': <String>['poular'],
              champMemorisation: 'coran_entier',
              'niveauLectureTajwid': 'tajwid_enseigne',
              'riwayat': <String>['hafs', 'warsh'],
            },
          ),
        ),
      );
      await toucherCle(tester, 'parcours-retour');
      // Deux riwayat : « quelques-unes », la grille ouverte, les deux retenues.
      expect(
        find.text(t.recrutement.parcours.riwayat.titreQuelques),
        findsOneWidget,
      );
      expect(
        find.text(t.recrutement.parcours.riwayat.lecteurs.asim),
        findsOneWidget,
      );
    });
  });

  testWidgets('l aide de l ijaza se deplie', (WidgetTester tester) async {
    await monterQuestionnaire(tester, port: FauxMaCandidature());
    await repondreAvant(tester, 'ijazaPresentable');
    expect(find.text(t.recrutement.parcours.aides.ijazaTexte), findsNothing);
    await toucherCle(tester, 'aide-ijaza');
    expect(find.text(t.recrutement.parcours.aides.ijazaTexte), findsOneWidget);
  });
}
