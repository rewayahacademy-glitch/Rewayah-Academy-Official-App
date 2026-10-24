// La confirmation du nom en lettres latines dans la Salle d'examen (decision du
// directeur du 23/10/2026). Ce que le test prouve, par les gestes d'une
// personne :
//
// - un dossier dont le nom n'est pas latin et rien de confirme : la question
//   passe avant le questionnaire, le champ est pre-rempli par la proposition,
//   et rien n'est enregistre avant « Confirmer mon nom » ;
// - un dossier sans rien a confirmer (nom deja latin, ou nom latin confirme),
//   sans port, ou dont la lecture echoue : le questionnaire s'ouvre aussitot,
//   jamais bloque ;
// - « Plus tard » ouvre le questionnaire sans rien enregistrer ;
// - un texte non latin est refuse a l'ecran ; un echec reseau dit « non
//   confirme » et laisse la personne reessayer ;
// - les etats : chargement (squelette), contenu, erreur d'envoi, hors ligne
//   (le bandeau de la page), a 390 et 1440, en francais et en arabe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/nom_latin.dart';
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/candidature/coquille_parcours.dart';
import 'package:rewayah_academy/features/candidature/nom_latin_etape.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../fixtures/candidature/faux_nom_latin.dart';
import '../../support/garde_interface.dart';
import 'hote_candidature.dart';

const String _nomArabe = 'محمد الدوسري';

/// Un double dont la lecture attend qu'on la libere.
class _Lent extends FauxNomLatin {
  _Lent() : super(nomComplet: _nomArabe);

  final Completer<void> libere = Completer<void>();

  @override
  Future<EtatNomLatin> lire() async {
    await libere.future;
    return super.lire();
  }
}

Future<void> _monter(
  WidgetTester tester,
  PortNomLatin? nom, {
  Size taille = const Size(390, 844),
  bool horsLigne = false,
  bool attendre = true,
  TextDirection? direction,
}) => monterQuestionnaire(
  tester,
  port: FauxMaCandidature(),
  taille: taille,
  horsLigne: horsLigne,
  attendre: attendre,
  direction: direction,
  surchargesEnPlus: <Override>[portNomLatinProvider.overrideWithValue(nom)],
);

final Finder _champ = find.byKey(NomLatinEtape.champKey);
final Finder _questionnaire = find.byKey(CoquilleParcours.actionKey);

String _texteDuChamp(WidgetTester tester) =>
    tester.widget<TextField>(_champ).controller!.text;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la question passe avant le questionnaire', () {
    testWidgets('nom arabe, rien de confirme : proposition pre-remplie', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe);
      await _monter(tester, nom);
      expect(find.text(t.recrutement.nomLatin.titre), findsWidgets);
      expect(find.text(t.recrutement.nomLatin.explication), findsOneWidget);
      // Le nom d'origine est rappele, isole pour son sens, jamais remplace.
      expect(
        find.text(t.recrutement.nomLatin.origine(nom: isolerSens(_nomArabe))),
        findsOneWidget,
      );
      expect(_texteDuChamp(tester), proposerNomLatin(_nomArabe));
      expect(_questionnaire, findsNothing);
      // Rien n'est enregistre sans le geste de la personne.
      expect(nom.confirmations, isEmpty);
      expect(nom.nomLatin, isNull);
      // Un seul bouton plein ; « Plus tard » est un lien discret.
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets(
      '« Confirmer mon nom » enregistre le texte corrige, puis ouvre',
      (WidgetTester tester) async {
        final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe);
        await _monter(tester, nom);
        await tester.enterText(_champ, '  Muhammad   Al-Dossari ');
        await toucherCle(tester, 'nom-latin-confirmer');
        expect(nom.confirmations, <String>['Muhammad Al-Dossari']);
        expect(nom.nomLatin, 'Muhammad Al-Dossari');
        expect(_questionnaire, findsOneWidget);
        expect(_champ, findsNothing);
      },
    );

    testWidgets('la proposition confirmee telle quelle part telle quelle', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe);
      await _monter(tester, nom);
      await toucherCle(tester, 'nom-latin-confirmer');
      expect(nom.confirmations, <String>[proposerNomLatin(_nomArabe)]);
      expect(_questionnaire, findsOneWidget);
    });

    testWidgets('« Plus tard » ouvre le questionnaire sans rien enregistrer', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe);
      await _monter(tester, nom);
      await toucherCle(tester, 'nom-latin-plus-tard');
      expect(nom.confirmations, isEmpty);
      expect(nom.nomLatin, isNull);
      expect(_questionnaire, findsOneWidget);
    });

    testWidgets(
      'un texte non latin est refuse a l\'ecran, rien n\'est envoye',
      (WidgetTester tester) async {
        final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe);
        await _monter(tester, nom);
        await tester.enterText(_champ, 'Muhammad محمد');
        await toucherCle(tester, 'nom-latin-confirmer');
        expect(find.text(t.recrutement.nomLatin.erreur), findsOneWidget);
        expect(nom.confirmations, isEmpty);
        expect(_questionnaire, findsNothing);
      },
    );

    testWidgets('si le serveur refuse le texte, la meme phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe)
        ..panneConfirmation = const NomNonLatin();
      await _monter(tester, nom);
      await toucherCle(tester, 'nom-latin-confirmer');
      expect(find.text(t.recrutement.nomLatin.erreur), findsOneWidget);
      expect(_questionnaire, findsNothing);
    });

    testWidgets('un echec reseau : « non confirme », on peut reessayer', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe)
        ..panneConfirmation = panneReseauNomLatin;
      await _monter(tester, nom);
      await toucherCle(tester, 'nom-latin-confirmer');
      expect(find.text(t.recrutement.nomLatin.echec), findsOneWidget);
      expect(_questionnaire, findsNothing);
      expect(nom.nomLatin, isNull);
      await toucherCle(tester, 'nom-latin-confirmer');
      expect(find.text(t.recrutement.nomLatin.echec), findsNothing);
      expect(nom.nomLatin, proposerNomLatin(_nomArabe));
      expect(_questionnaire, findsOneWidget);
    });
  });

  group('rien a confirmer : le questionnaire s\'ouvre aussitot', () {
    testWidgets('nom deja latin', (WidgetTester tester) async {
      await _monter(tester, FauxNomLatin(nomComplet: 'Amina Diallo'));
      expect(_champ, findsNothing);
      expect(_questionnaire, findsOneWidget);
    });

    testWidgets('nom latin deja confirme', (WidgetTester tester) async {
      await _monter(
        tester,
        FauxNomLatin(nomComplet: _nomArabe, nomLatin: 'Mohamed Al-Dousari'),
      );
      expect(_champ, findsNothing);
      expect(_questionnaire, findsOneWidget);
    });

    testWidgets('sans port (lot serveur non branche)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(_champ, findsNothing);
      expect(_questionnaire, findsOneWidget);
    });

    testWidgets('une lecture qui echoue ne bloque jamais le questionnaire', (
      WidgetTester tester,
    ) async {
      final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe)
        ..panneLecture = panneReseauNomLatin;
      await _monter(tester, nom);
      expect(_champ, findsNothing);
      expect(_questionnaire, findsOneWidget);
    });
  });

  group('etats et lisibilite', () {
    testWidgets('chargement : un squelette, pas de fausse question', (
      WidgetTester tester,
    ) async {
      final _Lent nom = _Lent();
      await _monter(tester, nom, attendre: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Skeleton), findsWidgets);
      expect(_champ, findsNothing);
      expect(_questionnaire, findsNothing);
      nom.libere.complete();
      await tester.pumpAndSettle();
      expect(_champ, findsOneWidget);
    });

    testWidgets(
      'hors ligne : la question reste, l\'envoi dit « non confirme »',
      (WidgetTester tester) async {
        final FauxNomLatin nom = FauxNomLatin(nomComplet: _nomArabe)
          ..panneConfirmation = panneReseauNomLatin;
        await _monter(tester, nom, horsLigne: true);
        expect(_champ, findsOneWidget);
        await toucherCle(tester, 'nom-latin-confirmer');
        expect(find.text(t.recrutement.nomLatin.echec), findsOneWidget);
      },
    );

    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets('${taille.width.toInt()} : aucun debordement', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          FauxNomLatin(nomComplet: _nomArabe),
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        expect(_champ, findsOneWidget);
      });
    }

    testWidgets(
      'en arabe : la question existe, le champ se lit de gauche a droite',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(
          tester,
          FauxNomLatin(nomComplet: _nomArabe),
          direction: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.recrutement.nomLatin.titre), findsWidgets);
        expect(
          tester.widget<TextField>(_champ).textDirection,
          TextDirection.ltr,
        );
      },
    );
  });
}
