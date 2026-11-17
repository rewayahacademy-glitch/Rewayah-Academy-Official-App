// PX-BD-SUPPORT : l'analyseur du Markdown ferme, cote application. Il rejoue
// les MEMES vecteurs que l'analyseur du serveur
// (`supabase/functions/_shared/support/vecteurs.json`, rejoues par
// `markdown_ferme_test.ts`) : un resultat different d'un cote ou de l'autre
// est rouge.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/markdown_ferme.dart';

const Map<String, CodeRefusMd> _codes = <String, CodeRefusMd>{
  'vide': CodeRefusMd.vide,
  'trop_long': CodeRefusMd.tropLong,
  'ligne_trop_longue': CodeRefusMd.ligneTropLongue,
  'trop_de_blocs': CodeRefusMd.tropDeBlocs,
  'caractere_interdit': CodeRefusMd.caractereInterdit,
  'html': CodeRefusMd.html,
  'lien': CodeRefusMd.lien,
  'image': CodeRefusMd.image,
  'tableau': CodeRefusMd.tableau,
  'code': CodeRefusMd.code,
  'barre': CodeRefusMd.barre,
  'marque_non_fermee': CodeRefusMd.margueNonFermee,
  'imbrication': CodeRefusMd.imbrication,
  'liste_imbriquee': CodeRefusMd.listeImbriquee,
  'titre_trop_profond': CodeRefusMd.titreTropProfond,
};

List<Map<String, Object?>> _inlinesJson(List<InlineMd> l) =>
    <Map<String, Object?>>[
      for (final InlineMd i in l)
        <String, Object?>{
          't': switch (i) {
            TexteMd() => 'texte',
            GrasMd() => 'gras',
            ItaliqueMd() => 'italique',
          },
          'v': i.texte,
        },
    ];

Map<String, Object?> _blocJson(BlocMd b) => switch (b) {
  TitreMd() => <String, Object?>{
    'type': 'titre',
    'niveau': b.niveau,
    'inlines': _inlinesJson(b.inlines),
  },
  ParagrapheMd() => <String, Object?>{
    'type': 'paragraphe',
    'inlines': _inlinesJson(b.inlines),
  },
  PucesMd() => <String, Object?>{
    'type': 'puces',
    'items': <Object?>[for (final List<InlineMd> i in b.items) _inlinesJson(i)],
  },
  NumeroteeMd() => <String, Object?>{
    'type': 'numerotee',
    'debut': b.debut,
    'items': <Object?>[for (final List<InlineMd> i in b.items) _inlinesJson(i)],
  },
  CitationMd() => <String, Object?>{
    'type': 'citation',
    'inlines': _inlinesJson(b.inlines),
  },
  SeparateurMd() => <String, Object?>{'type': 'separateur'},
};

void main() {
  final List<dynamic> vecteurs = jsonDecode(
    File('supabase/functions/_shared/support/vecteurs.json').readAsStringSync(),
  ) as List<dynamic>;

  test('le jeu de vecteurs est lu (43 cas au moins)', () {
    expect(vecteurs.length, greaterThanOrEqualTo(43));
  });

  for (final dynamic v in vecteurs) {
    final Map<String, dynamic> cas = v as Map<String, dynamic>;
    final Map<String, dynamic> attendu = cas['attendu'] as Map<String, dynamic>;
    test('vecteur : ${cas['nom']}', () {
      final ResultatMd r = analyserMarkdownFerme(cas['source'] as String);
      if (attendu['ok'] == true) {
        expect(r.estOk, isTrue, reason: 'refuse (${r.code}) a tort');
        expect(
          jsonDecode(
            jsonEncode(<Object?>[
              for (final BlocMd b in r.blocs!) _blocJson(b),
            ]),
          ),
          attendu['blocs'],
        );
      } else {
        expect(r.estOk, isFalse, reason: 'accepte a tort');
        expect(r.code, _codes[attendu['code']]);
      }
    });
  }

  test('un refus donne la ligne du defaut', () {
    final ResultatMd r = analyserMarkdownFerme('Un.\n\nDeux <b>x</b>.');
    expect(r.code, CodeRefusMd.html);
    expect(r.ligne, 3);
  });
}
