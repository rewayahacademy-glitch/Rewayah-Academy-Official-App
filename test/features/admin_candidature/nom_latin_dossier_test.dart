// PE-B3 (directeur, 05/11 et 19/11/2026, PLAN §2.7) : le nom que le candidat a
// confirme en lettres latines sort dans le dossier de la direction, sur la
// carte de profil. Le serveur le rend deja dans la ligne (`nomLatin`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import 'hote_candidature.dart';

Map<String, Object?> _ligneJson({Object? nomLatin}) => <String, Object?>{
  'id': 'c1',
  'reference': 'CAND-00001',
  'nomComplet': 'أمينة ديالو',
  'nomLatin': nomLatin,
  'type': 'enseignant',
  'etape': 'prequalification',
  'etat': 'en_examen',
  'issue': 'en_cours',
  'derniereActivite': '2026-10-20T09:00:00Z',
};

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la ligne lit nomLatin', () {
    test('rendu par le serveur', () {
      expect(
        LigneCandidature.depuisJson(_ligneJson(nomLatin: 'Amina Diallo'))!
            .nomLatin,
        'Amina Diallo',
      );
    });

    test('absent, nul ou vide : null', () {
      expect(LigneCandidature.depuisJson(_ligneJson())!.nomLatin, isNull);
      expect(
        LigneCandidature.depuisJson(_ligneJson(nomLatin: '  '))!.nomLatin,
        isNull,
      );
      final Map<String, Object?> sans = _ligneJson()..remove('nomLatin');
      expect(LigneCandidature.depuisJson(sans)!.nomLatin, isNull);
    });
  });

  group('ligneNomLatinDuDossier', () {
    test('un nom latin confirme : la ligne, isolee dans son sens', () {
      final l = ligneNomLatinDuDossier(
        detailTest(nom: 'أمينة ديالو', nomLatin: 'Amina Diallo').ligne,
      );
      expect(l?.cle, t.inscription.nomLatin.court);
      expect(l?.valeur, isolerSens('Amina Diallo'));
    });

    test('un nom deja latin ne se repete pas', () {
      expect(
        ligneNomLatinDuDossier(
          detailTest(nom: 'Amina Diallo', nomLatin: 'Amina Diallo').ligne,
        ),
        isNull,
      );
    });

    test('rien de confirme : aucune ligne', () {
      expect(ligneNomLatinDuDossier(detailTest(nom: 'أمينة').ligne), isNull);
    });
  });

  group('sur la carte de profil', () {
    Future<void> monter(
      WidgetTester tester,
      DetailCandidature detail, {
      TextDirection? direction,
    }) async {
      await monterCandidature(
        tester,
        port: FauxCandidaturesDirection(
          capacitesRendues: capacitesGestes,
          details: <DetailCandidature>[detail],
        ),
        direction: direction,
        ouvrirRubriques: false,
      );
      await laisser(tester);
    }

    testWidgets('le nom latin est la premiere ligne du profil', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        detailTest(nom: 'أمينة ديالو', nomLatin: 'Amina Diallo'),
      );
      final Finder profil = find.byKey(EtageUnDossier.cleProfil);
      expect(profil, findsOneWidget);
      expect(
        find.descendant(
          of: profil,
          matching: find.text(t.inscription.nomLatin.court),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: profil,
          matching: find.text(isolerSens('Amina Diallo')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('en arabe aussi, de droite a gauche', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monter(
        tester,
        detailTest(nom: 'أمينة ديالو', nomLatin: 'Amina Diallo'),
        direction: TextDirection.rtl,
      );
      expect(find.text(t.inscription.nomLatin.court), findsOneWidget);
      expect(find.text(isolerSens('Amina Diallo')), findsOneWidget);
    });

    testWidgets('un nom deja latin : aucune ligne de plus', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        detailTest(nom: 'Amina Diallo', nomLatin: 'Amina Diallo'),
      );
      expect(find.text(t.inscription.nomLatin.court), findsNothing);
    });
  });
}
