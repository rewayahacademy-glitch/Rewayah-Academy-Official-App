// PE-B1 : le format des reponses juz et riwayat, et tout ce qui les lit.
//
// Ce que le test prouve, en francais et en arabe :
// - le nombre exact de juz se stocke `juz_N` (1 a 29) dans le meme champ ; les
//   quatre anciens codes restent lus tels quels ;
// - chaque lecteur cote application relit l'ancien ET le nouveau format, sans
//   code brut ni ligne perdue : le recapitulatif du candidat et le dossier de
//   la direction (`resumeReponse`, par `cartesDeReponses`), la synthese du
//   dossier (`syntheseDuDossier`) ;
// - les riwayat ne changent pas de format (une liste de codes) : une ancienne
//   reponse se relit dans le mode qui lui correspond (`modeDesRiwayat`).
// Le serveur : supabase/tests/scenarios_juz_nombre_exact.sql.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/synthese_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/reponses_candidature.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';

DocumentReponses _doc(Map<String, Object?> reponses) => DocumentReponses(
  questionnaireVersion: 'salle-examen-2',
  reponses: reponses,
  importe: false,
);

/// Ce que le dossier de la direction affiche pour un champ.
String? _dossier(String champ, Object? valeur) {
  for (final CarteReponses c in cartesDeReponses(
    _doc(<String, Object?>{champ: valeur}),
  )) {
    for (final LigneReponse l in c.lignes) {
      if (l.code == champ) return l.valeur;
    }
  }
  return null;
}

/// Ce que la synthese du dossier affiche pour la memorisation.
String? _synthese(String valeur) {
  final s = t.recrutement.dossier3.synthese;
  for (final LigneSynthese l in syntheseDuDossier(
    detailTest(
      documents: <DocumentReponses>[
        _doc(<String, Object?>{champMemorisation: valeur}),
      ],
    ),
  )) {
    if (l.cle == s.memorisation) return l.valeur;
  }
  return null;
}

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le format juz', () {
    test('juz_1 a juz_29 se lisent, rien d\'autre', () {
      for (int n = 1; n <= juzMaximum; n++) {
        expect(juzExact(codeJuz(n)), n);
      }
      for (final String? c in <String?>[
        'juz_0',
        'juz_30',
        'juz_01',
        'juz_',
        'coran_entier',
        'moins_10_juz',
        null,
      ]) {
        expect(juzExact(c), isNull, reason: '$c');
      }
    });
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('lecteurs en ${langue.languageCode}', () {
      setUp(() => LocaleSettings.setLocale(langue));

      test(
        'dossier de la direction : juz_12 se dit « 12 juz », jamais le code',
        () {
          final String? texte = _dossier(champMemorisation, 'juz_12');
          expect(texte, t.recrutement.parcours.juz.valeur(n: 12));
          expect(texte, isNot(contains('juz_')));
        },
      );

      test('dossier de la direction : les quatre anciens codes inchanges', () {
        final o = t.recrutement.parcours.q.niveauMemorisationDeclare.options;
        expect(_dossier(champMemorisation, 'aucune'), o.aucune.libelle);
        expect(
          _dossier(champMemorisation, 'moins_10_juz'),
          o.moins_10_juz.libelle,
        );
        expect(
          _dossier(champMemorisation, 'de_10_a_29_juz'),
          o.de_10_a_29_juz.libelle,
        );
        expect(
          _dossier(champMemorisation, 'coran_entier'),
          o.coran_entier.libelle,
        );
      });

      test('synthese : juz_12 a sa ligne, les anciens codes aussi', () {
        final v = t.recrutement.dossier3.synthese.memorisationValeurs;
        expect(
          _synthese('juz_12'),
          contains(t.recrutement.parcours.juz.valeur(n: 12)),
        );
        expect(_synthese('moins_10_juz'), contains(v.moins_10_juz));
        expect(_synthese('coran_entier'), contains(v.coran_entier));
        expect(_synthese('juz_30'), isNull);
      });

      test('riwayat : les sept et les dix se relisent en noms', () {
        final String? dix = _dossier('riwayat', riwayatDix.toList());
        expect(dix, isNotNull);
        expect(dix, isNot(contains('_')));
        expect(_dossier('riwayat', <String>['hafs', 'warsh']), isNotNull);
      });
    });
  }

  group('les riwayat', () {
    test('sept lecteurs, quatorze riwayat ; dix lecteurs, vingt', () {
      expect(lecteursRiwayat, hasLength(10));
      expect(riwayatSept, hasLength(14));
      expect(riwayatDix, hasLength(20));
      expect(riwayatDix.containsAll(riwayatSept), isTrue);
      expect(
        riwayatSept.containsAll(<String>['hafs', 'warsh', 'qalun']),
        isTrue,
      );
      expect(
        riwayatSept.intersection(<String>{'ibn_wardan', 'ruways', 'ishaq'}),
        isEmpty,
      );
    });

    test('une reponse deja enregistree se relit dans son mode', () {
      expect(modeDesRiwayat(<String>{}), isNull);
      // Relecture de la PR 660 : jamais « dix » ni « sept » (ijaza) a la
      // relecture, meme pour les vingt ou les quatorze codes.
      expect(modeDesRiwayat(riwayatDix), ModeRiwayat.quelques);
      expect(modeDesRiwayat(riwayatSept), ModeRiwayat.quelques);
      expect(modeDesRiwayat(<String>{'hafs'}), ModeRiwayat.une);
      expect(modeDesRiwayat(<String>{'hafs', 'warsh'}), ModeRiwayat.quelques);
      expect(
        modeDesRiwayat(<String>{...riwayatSept, 'ibn_wardan'}),
        ModeRiwayat.quelques,
      );
    });
  });
}
