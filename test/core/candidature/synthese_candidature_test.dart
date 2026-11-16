// La synthese d'une candidature (BE-DOSSIER, coordinateur, 16/11/2026) : la
// table de correspondance reponse vers mot-cle et la fonction qui fabrique les
// lignes du tableau. Les colonnes de la liste la reprendront telle quelle.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/synthese_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/libelles_parcours.dart'
    show libelleHeures;

import '../../fixtures/candidature/faux_candidatures_direction.dart';

DetailCandidature _avec(Map<String, Object?> reponses) => detailTest(
  documents: <DocumentReponses>[
    DocumentReponses(
      questionnaireVersion: 'v',
      reponses: reponses,
      importe: false,
    ),
  ],
);

Map<String, String> _tableau(List<LigneSynthese> lignes) => <String, String>{
  for (final LigneSynthese l in lignes) l.cle: l.valeur,
};

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  final s = t.recrutement.dossier3.synthese;
  final String sep = t.admin.candidatures.historique.separateur;
  const Map<String, String> orange = <String, String>{
    'orange_money': 'Orange Money',
  };

  test('six lignes, dans l\'ordre, en mots-cles', () {
    final List<LigneSynthese> lignes = syntheseDuDossier(
      detailTest(),
      nomsOperateurs: orange,
    );
    expect(lignes.map((LigneSynthese l) => l.cle).toList(), <String>[
      s.langues,
      s.memorisation,
      s.ijaza,
      s.disponibilites,
      s.versement,
      s.public,
    ]);
    final Map<String, String> m = _tableau(lignes);
    expect(m[s.langues], <String>['Poular', 'Français', 'Wolof'].join(sep));
    expect(m[s.memorisation], s.memorisationValeurs.de_10_a_29_juz);
    expect(m[s.ijaza], s.ijazaValeurs.pret_test);
    expect(
      m[s.disponibilites],
      s.heuresDe(
        jours: <String>[s.jours.j1, s.jours.j3].join(sep),
        heures: libelleHeures(<int>[18, 19]),
      ),
    );
    expect(
      m[s.versement],
      <String>[
        'Sénégal',
        t.admin.candidatures.moyens.virement,
        'Orange Money',
      ].join(sep),
    );
    expect(
      m[s.public],
      <String>[s.publicValeurs.k1013, s.publicValeurs.adultes].join(sep),
    );
  });

  test('jamais la phrase du candidat, ni un compteur, ni un code', () {
    final String tout = syntheseDuDossier(detailTest())
        .map((LigneSynthese l) => '${l.cle} ${l.valeur}')
        .join('\n');
    expect(tout, isNot(contains("J'ai mémorisé")));
    expect(tout, isNot(contains('Moyens indiqu')));
    expect(tout, isNot(contains('orange_money')));
    expect(tout, isNot(contains('de_10_a_29_juz')));
    expect(tout, isNot(contains('pret_test')));
  });

  test('une langue qui a un nom entre parentheses se dit sans lui', () {
    final Map<String, String> m = _tableau(
      syntheseDuDossier(_avec(<String, Object?>{'langueMaternelle': 'poular'})),
    );
    expect(m[s.langues], 'Poular');
  });

  test('une reponse absente ou inconnue n\'a pas de ligne', () {
    final List<LigneSynthese> lignes = syntheseDuDossier(
      _avec(<String, Object?>{
        'niveauMemorisationDeclare': 'un_code_que_la_table_ne_connait_pas',
        'publics': <String>['adultes'],
      }),
    );
    expect(lignes, hasLength(1));
    expect(lignes.single.cle, s.public);
    expect(lignes.single.valeur, s.publicValeurs.adultes);
  });

  test('sans reponses : aucune ligne', () {
    expect(
      syntheseDuDossier(detailTest(documents: const <DocumentReponses>[])),
      isEmpty,
    );
  });

  test('versement : le pays de versement, sinon celui de residence', () {
    expect(
      _tableau(
        syntheseDuDossier(_avec(<String, Object?>{'paysResidence': 'SN'})),
      )[s.versement],
      'Sénégal',
    );
  });

  test('versement : un moyen sans nom connu ne se dit pas', () {
    final Map<String, String> m = _tableau(
      syntheseDuDossier(
        _avec(<String, Object?>{
          'paysVersement': 'SN',
          'operateurs': <String>['orange_money', 'wave'],
        }),
        nomsOperateurs: orange,
      ),
    );
    expect(m[s.versement], <String>['Sénégal', 'Orange Money'].join(sep));
  });

  test('les heures sont celles declarees, par groupes de jours', () {
    final Map<String, String> m = _tableau(
      syntheseDuDossier(
        _avec(<String, Object?>{
          'publics': <String>['10_13'],
          'disponitilites_inconnues': true,
          'disponibilitesDeclarees': <Map<String, Object?>>[
            <String, Object?>{'jour': 6, 'debut': '09:00', 'fin': '11:00'},
          ],
        }),
      ),
    );
    final String valeur = m[s.disponibilites]!;
    expect(valeur, contains(s.jours.j6));
    expect(valeur, contains('9'));
  });

  test('en arabe : valeurs a chiffres isolees, chiffres latins', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    final Map<String, String> m = _tableau(syntheseDuDossier(detailTest()));
    final String a = t.recrutement.dossier3.synthese.memorisation;
    expect(m[a], contains('\u2068'));
    expect(m[a], contains('10'));
    expect(m[a], isNot(contains('١')));
    expect(m[t.recrutement.dossier3.synthese.disponibilites], contains('\u2068'));
  });
}
