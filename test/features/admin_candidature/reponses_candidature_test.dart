// ADM-21 : les reponses de la candidature, mises en mots pour la direction.
//
// Le serveur rend des codes ; chaque reponse se dit par les textes du
// questionnaire, en francais et en arabe. Ce que le test prouve : chaque champ
// et chaque option de `salle-examen-1` a son texte dans les deux langues, jamais
// le code lui-meme ; un champ ou une option que cette version ne connait pas
// n'est pas montre en code brut ; les operateurs se disent par leur nom quand le
// referentiel les sert, par leur nombre sinon.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/reponses_candidature.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';

DocumentReponses _doc(Map<String, Object?> reponses) => DocumentReponses(
  questionnaireVersion: 'salle-examen-1',
  reponses: reponses,
  importe: false,
);

/// Le texte d'un champ de reponse unique.
String? _texte(String champ, Object? valeur) {
  final List<CarteReponses> cartes = cartesDeReponses(
    _doc(<String, Object?>{champ: valeur}),
  );
  for (final CarteReponses c in cartes) {
    for (final LigneReponse l in c.lignes) {
      if (l.code == champ) {
        return l.valeur ?? l.groupes.join(' / ');
      }
    }
  }
  return null;
}

/// Les valeurs fermees de `salle-examen-1` (migration CAND-L2A1, version 1).
const Map<String, List<String>> _valeurs = <String, List<String>>{
  'niveauMemorisationDeclare': <String>[
    'aucune',
    'moins_10_juz',
    'de_10_a_29_juz',
    'coran_entier',
  ],
  'niveauLectureTajwid': <String>[
    'lecture_sans_regles_tajwid',
    'tajwid_applique',
    'tajwid_enseigne',
  ],
  'ijazaPresentable': <String>['oui', 'pret_test', 'non'],
  'experienceDebutants': <String>['oui', 'non'],
  'debutPossible': <String>[
    'immediat',
    'mois_prochain',
    'sous_3_mois',
    'inconnu',
  ],
  'classesSouhaitees': <String>['1', '2', '3'],
};

const List<String> _riwayat = <String>[
  'hafs',
  'shuba',
  'warsh',
  'qalun',
  'al_bazzi',
  'qunbul',
  'ad_duri_abi_amr',
  'as_susi',
  'hisham',
  'ibn_dhakwan',
  'khalaf_an_hamza',
  'khallad',
  'abu_al_harith',
  'ad_duri_al_kisai',
  'ibn_wardan',
  'ibn_jammaz',
  'ruways',
  'rawh',
  'ishaq',
  'idris',
];

const List<String> _publics = <String>['6_9', '10_13', '14_17', 'adultes'];

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('en ${langue.languageCode}', () {
      setUp(() async {
        await LocaleSettings.setLocale(langue);
      });

      for (final MapEntry<String, List<String>> e in _valeurs.entries) {
        test('${e.key} : chaque option a son texte, jamais son code', () {
          for (final String code in e.value) {
            final String? texte = _texte(e.key, code);
            expect(texte, isNotNull, reason: '${e.key} = $code');
            expect(texte, isNot(code), reason: '${e.key} = $code');
            expect(texte!.trim(), isNotEmpty);
          }
        });
      }

      test('les vingt riwayat', () {
        for (final String code in _riwayat) {
          final String? texte = _texte('riwayat', <String>[code]);
          expect(texte, isNotNull, reason: code);
          expect(texte, isNot(code), reason: code);
        }
      });

      test('les publics', () {
        for (final String code in _publics) {
          final String? texte = _texte('publics', <String>[code]);
          expect(texte, isNotNull, reason: code);
          expect(texte, isNot(code));
        }
      });

      test('les langues, les pays, le fuseau, le compte bancaire', () {
        expect(_texte('langueMaternelle', 'poular'), isNotNull);
        expect(
          _texte('languesExplication', <String>['francais', 'wo']),
          isNotNull,
        );
        expect(_texte('paysResidence', 'SN'), isNot('SN'));
        expect(_texte('paysVersement', 'FR'), isNot('FR'));
        expect(_texte('fuseauIana', 'Africa/Dakar'), isNot('Africa/Dakar'));
        expect(_texte('compteBancaire', true), isNotNull);
        expect(
          _texte('compteBancaire', false),
          isNot(_texte('compteBancaire', true)),
        );
      });

      test('les disponibilites : un groupe de jours par ligne', () {
        final String? texte = _texte(
          'disponibilitesDeclarees',
          <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
            <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '21:00'},
          ],
        );
        expect(texte, isNotNull);
        expect(texte, contains('18'));
      });
    });
  }

  test('en arabe, les textes ne retombent pas sur le francais', () async {
    await LocaleSettings.setLocale(AppLocale.fr);
    final String fr = _texte('niveauMemorisationDeclare', 'coran_entier')!;
    await LocaleSettings.setLocale(AppLocale.ar);
    final String ar = _texte('niveauMemorisationDeclare', 'coran_entier')!;
    expect(ar, isNot(fr));
  });

  test('un champ ou une option inconnus ne s\'affichent jamais en code', () {
    expect(_texte('champInconnu', 'x'), isNull);
    expect(_texte('niveauMemorisationDeclare', 'valeur_inconnue'), isNull);
    expect(_texte('riwayat', <String>['riwaya_inconnue']), isNull);
    expect(_texte('paysResidence', 'ZZ'), isNull);
    expect(_texte('languesExplication', <String>['langue_inconnue']), isNull);
  });

  test('une reponse nulle ou vide n\'est pas montree', () {
    expect(_texte('riwayat', <String>[]), isNull);
    expect(_texte('riwayat', null), isNull);
    expect(_texte('disponibilitesDeclarees', <Object?>[]), isNull);
  });

  test('les champs sont ranges par theme, dans l\'ordre du questionnaire', () {
    final List<CarteReponses> cartes = cartesDeReponses(_doc(reponsesTest()));
    expect(cartes.map((CarteReponses c) => c.code).toList(), <String>[
      'langues',
      'recitation',
      'disponibilites',
      'publics',
      'versement',
    ]);
    expect(cartes.first.lignes.map((LigneReponse l) => l.code), <String>[
      'langueMaternelle',
      'languesExplication',
    ]);
  });

  test('les operateurs : leur nom quand le referentiel les sert, leur nombre sinon', () {
    final DocumentReponses d = _doc(<String, Object?>{
      'paysVersement': 'SN',
      'operateurs': <String>['orange_money', 'wave'],
    });
    LigneReponse operateurs(Map<String, String> noms) => cartesDeReponses(
      d,
      nomsOperateurs: noms,
    ).single.lignes.firstWhere((LigneReponse l) => l.code == 'operateurs');

    final LigneReponse nommes = operateurs(<String, String>{
      'orange_money': 'Orange Money',
      'wave': 'Wave',
    });
    expect(nommes.valeur, contains('Orange Money'));
    expect(nommes.valeur, contains('Wave'));
    // Un seul nom connu sur deux : le nombre, jamais un code a moitie.
    final LigneReponse partiel = operateurs(<String, String>{
      'orange_money': 'Orange Money',
    });
    expect(partiel.valeur, t.admin.candidatures.detail.moyensIndiques(n: 2));
    final LigneReponse aucun = operateurs(const <String, String>{});
    expect(aucun.valeur, t.admin.candidatures.detail.moyensIndiques(n: 2));
    expect(aucun.valeur, isNot(contains('wave')));
  });

  test('la declaration de versement : pays, compte, operateurs', () {
    final DeclarationVersement d = declarationVersement(detailTest());
    expect(d.pays, 'SN');
    expect(d.virement, isTrue);
    expect(d.operateurs, <String>['orange_money']);
    expect(d.vide, isFalse);
    final DeclarationVersement vide = declarationVersement(
      detailTest(documents: const <DocumentReponses>[]),
    );
    expect(vide.vide, isTrue);
    expect(vide.pays, isNull);
  });
}
