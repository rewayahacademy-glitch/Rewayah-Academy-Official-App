// AR-SALLE-1 / AR-TC-1 (revue du 09/10) : dans la salle et le Teaching Core
// en arabe, aucune donnee latine (prenom, titre, date, compteur venus des
// donnees) ne sort brouillee par le sens de droite a gauche.
//
// Trois mesures sur le rendu : (1) chaque paragraphe RTL de l'ecran, lu dans
// l'arbre de rendu, n'a aucun segment latin non isole a bord faible ;
// (2) aucun paragraphe rendu n'est un libelle francais de `salle.*` ou
// `tc.*` (les donnees de demonstration, en francais, sont l'ecart voulu 1) ;
// (3) la fiche de Mariam est lue a la position des glyphes : « 3 » est a
// gauche de « seances », « ( » a gauche de « les », « 21 » a gauche de
// « sept. ».

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../capture/outil_capture.dart' hide stabiliser;
import '../support/bidi_donnees.dart';
import '../teaching_core/a/support/hote_tc_a.dart';

const List<(String, Size, double)> _cadrages = <(String, Size, double)>[
  ('390 x1', Size(390, 844), 1),
  ('320 x2', Size(320, 700), 2),
  ('1440 x1', Size(1440, 900), 1),
];

/// La position horizontale (au centre) du premier glyphe de [motif] dans
/// [p], ou `null` s'il est absent.
double? _xDe(RenderParagraph p, String motif) {
  final String texte = p.text.toPlainText(includeSemanticsLabels: false);
  final int i = texte.indexOf(motif);
  if (i < 0) return null;
  final List<TextBox> boites = p.getBoxesForSelection(
    TextSelection(baseOffset: i, extentOffset: i + 1),
  );
  if (boites.isEmpty) return null;
  return (boites.first.left + boites.first.right) / 2;
}

RenderParagraph _paragraphe(WidgetTester tester, String motif) =>
    tester.allRenderObjects.whereType<RenderParagraph>().firstWhere(
      (RenderParagraph p) =>
          p.text.toPlainText(includeSemanticsLabels: false).contains(motif),
    );

Map<String, String> _aplatir(Map<String, dynamic> carte, String prefixe) {
  final Map<String, String> sortie = <String, String>{};
  carte.forEach((String cle, dynamic valeur) {
    if (valeur is Map<String, dynamic>) {
      sortie.addAll(_aplatir(valeur, '$prefixe$cle.'));
    } else {
      sortie['$prefixe$cle'] = valeur as String;
    }
  });
  return sortie;
}

Map<String, String> _langue(String langue) {
  final Map<String, dynamic> json = jsonDecode(
    File('assets/i18n/$langue.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return <String, String>{
    for (final String domaine in <String>['salle', 'tc'])
      ..._aplatir(json[domaine] as Map<String, dynamic>, '$domaine.'),
  };
}

/// Les libelles francais de `salle.*` et `tc.*` sans parametre, qui ne
/// doivent jamais etre rendus tels quels en arabe (hors marque et format,
/// identiques dans les deux langues).
final Set<String> _libellesFrancais = () {
  final Map<String, String> fr = _langue('fr');
  final Map<String, String> ar = _langue('ar');
  return <String>{
    for (final MapEntry<String, String> e in fr.entries)
      if (!e.value.contains('{') && e.value != ar[e.key]) e.value,
  };
}();

/// Les paragraphes rendus qui sont un libelle francais.
List<String> _francaisRendu(WidgetTester tester) => <String>[
  for (final RenderParagraph p
      in tester.allRenderObjects.whereType<RenderParagraph>())
    if (_libellesFrancais.contains(
      p.text.toPlainText(includeSemanticsLabels: false),
    ))
      p.text.toPlainText(includeSemanticsLabels: false),
];

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('le detecteur reconnait les formes brouillees', () {
    expect(segmentsLatinsBrouilles('3 séances cette semaine'), isNotEmpty);
    expect(segmentsLatinsBrouilles('Chapitre 1 (les bonnes)'), isNotEmpty);
    expect(segmentsLatinsBrouilles('21 sept. 2026'), isNotEmpty);
    expect(segmentsLatinsBrouilles('\u2068Chapitre 1 (x)\u2069'), isEmpty);
    expect(segmentsLatinsBrouilles('Pages 24 à 26'), isEmpty);
    expect(segmentsLatinsBrouilles('سيدة Amina'), isEmpty);
    expect(segmentsLatinsBrouilles('بقيت 32 دقيقة'), isEmpty);
    expect(segmentsLatinsBrouilles('درس · Bonnes manières'), isEmpty);
    expect(segmentsLatinsBrouilles('درس (les bonnes)'), isNotEmpty);
  });

  for (final RoleSeance role in RoleSeance.values) {
    for (final SituationTb situation in SituationTb.values) {
      if (!situation.concerne(role)) continue;
      for (final (String nom, Size taille, double texte) in _cadrages) {
        testWidgets('salle ${role.name} ${situation.name} $nom', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, 1);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteCapture(
              DemoSallePage(role: role, situation: situation),
              echelleTexte: texte,
            ),
          );
          await tester.pumpAndSettle();
          expect(paragraphesRtlBrouilles(tester), isEmpty);
          expect(_francaisRendu(tester), isEmpty);
        });
      }
    }
  }

  final List<(String, Widget Function())> ecransTc =
      <(String, Widget Function())>[
        ('mes_classes', () => const MesGroupesPage()),
        (
          'espace_eleve',
          () => const EspaceGroupePage(
            groupeId: GroupesDemonstration.alFatiha,
            role: RoleEspaceGroupe.eleve,
          ),
        ),
        (
          'espace_enseignant',
          () => const EspaceGroupePage(
            groupeId: GroupesDemonstration.anNour,
            role: RoleEspaceGroupe.enseignant,
          ),
        ),
      ];
  for (final (String nom, Widget Function() construire) in ecransTc) {
    for (final (String cas, Size taille, double texte) in _cadrages) {
      testWidgets('tc $nom $cas', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            construire(),
            surcharges: surchargesDemonstration(),
            echelleTexte: texte,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(paragraphesRtlBrouilles(tester), isEmpty);
        expect(_francaisRendu(tester), isEmpty);
      });
    }
  }

  testWidgets('fiche de Mariam : chiffres et parentheses a leur place', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(1440, 900), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.enseignant,
          situation: SituationTb.lib01,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderParagraph presence = _paragraphe(tester, 'séances');
    expect(presence.textDirection, TextDirection.rtl);
    expect(_xDe(presence, '3')!, lessThan(_xDe(presence, 's')!));
    final RenderParagraph objectif = _paragraphe(tester, 'les bonnes');
    expect(_xDe(objectif, '(')!, lessThan(_xDe(objectif, 'l')!));
    expect(_xDe(objectif, ')')!, greaterThan(_xDe(objectif, 'm')!));
    final RenderParagraph date = _paragraphe(tester, 'sept.');
    expect(_xDe(date, '21')!, lessThan(_xDe(date, 's')!));
  });
}
