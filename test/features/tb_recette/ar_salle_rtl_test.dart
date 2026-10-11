// AR-SALLE-1 : la salle en arabe, de droite a gauche.
//
// Les situations de la salle (eleve, interface guidee, enseignant) se
// montent en arabe sans debordement ni exception, au telephone (390, et 320
// a texte x2) comme au bureau ; le sens est RTL et les libelles sont ceux de
// l'arabe, plus ceux du francais.
//
// Verification TB (10/10, TB-8, TB-9, AR-SALLE-1) : aucun paragraphe rendu
// n'est un libelle francais de l'interface, quel que soit son domaine
// (commun.reessayer, commun.annuler, destructif.*, presence.*...), pour les
// cinq vues de la salle (eleve, interface guidee, enseignant, tuteur,
// controleur), la feuille d'effacement et l'echec de la Bibliotheque. Les
// donnees de demonstration (noms, titres de supports) ne sont pas des
// libelles : elles ne sont pas dans fr.i18n.json.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart' hide stabiliser;

/// Les cles d'un fichier de langue, a plat (`presence.inconnu`).
Map<String, String> _aplatir(Object? valeur, String prefixe) {
  if (valeur is Map<String, dynamic>) {
    return <String, String>{
      for (final MapEntry<String, dynamic> e in valeur.entries)
        ..._aplatir(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}'),
    };
  }
  return valeur is String ? <String, String>{prefixe: valeur} : {};
}

Map<String, String> _langue(String code) => _aplatir(
  jsonDecode(File('assets/i18n/$code.i18n.json').readAsStringSync()),
  '',
);

/// Les cles dont le motif francais coincide avec une DONNEE de
/// demonstration rendue telle quelle (ecart voulu 1 d'AR-SALLE-1), et non
/// avec un libelle : la raison est ecrite pour chacune.
const Map<String, String> _donneesDeDemonstration = <String, String>{
  'enseignant.journee.classeNommee':
      '« Classe {classe} » : le nom de la classe, « Classe An-Nour »',
  'tc.parcours.plage.pages': '« Pages 24 à 26 » : le programme de la seance',
  'salle.seance.fiche.seancesSemaine(param=nombre).other':
      '« 3 séances cette semaine » : la fiche de Mariam (ar_donnees_isolees)',
  'salle.seance.fiche.seancesSemaine':
      '« 3 séances cette semaine » : la fiche de Mariam (ar_donnees_isolees)',
  'enseignant.eleve.titre': '« Fiche de mémorisation » : titre d\'un support',
  'nav.motSymbole': '« Rewayah » : la marque',
  'admin.bibliotheque.libelles.type.pdf': '« PDF » : le nom du format, que la demonstration montre tel quel (typeLisible)',
  'enseignant.revenus.classe':
      '« Classe An-Nour » : le nom de la classe de la demonstration',
  'admin.groupes.detailTitre':
      '« Classe An-Nour » : le nom de la classe de la demonstration',
  'admin.finance.vue.alerte.quiClasse':
      '« Classe An-Nour » : le nom de la classe de la demonstration',
  'identiteProfil.classe':
      '« Classe An-Nour » : le nom de la classe de la demonstration',
  'com.annonces.demo.classeNour':
      '« Classe An-Nour » : le nom de la classe de la demonstration',
  'com.studio.demo.f.mariam':
      '« Mariam » : le prénom d\'une élève de la démonstration',
  'com.messages.demo.f.yusuf':
      '« Yusuf » : le prénom d\'un élève de la démonstration',
};

/// Chaque libelle francais de l'interface (tous domaines) que l'arabe ne
/// reprend pas a l'identique, sous forme de motif entier : un parametre
/// vaut n'importe quel texte. Un motif sans au moins trois lettres fixes
/// (« {jour} {numero} {mois} ») ne designe aucun mot francais : ecarte.
final List<(String, RegExp)> _libellesFrancais = () {
  final Map<String, String> fr = _langue('fr');
  final Map<String, String> ar = _langue('ar');
  final RegExp parametre = RegExp(r'\{\w+\}');
  return <(String, RegExp)>[
    for (final MapEntry<String, String> e in fr.entries)
      if (!_donneesDeDemonstration.containsKey(e.key) &&
          ar[e.key] != e.value &&
          RegExp('[A-Za-zÀ-ÿ]')
                  .allMatches(e.value.replaceAll(parametre, ''))
                  .length >=
              3)
        (
          e.key,
          RegExp(
            '^${e.value.split(parametre).map(RegExp.escape).join('.+?')}\$',
            dotAll: true,
          ),
        ),
  ];
}();

/// Les paragraphes rendus qui sont un libelle francais, avec sa cle.
List<String> _francaisRendu(WidgetTester tester) => <String>[
  for (final RenderParagraph p
      in tester.allRenderObjects.whereType<RenderParagraph>())
    for (final (String cle, RegExp motif) in _libellesFrancais)
      if (motif.hasMatch(
        p.text
            .toPlainText(includeSemanticsLabels: false)
            .replaceAll(RegExp('[\u2066-\u2069]'), ''),
      ))
        '$cle : ${p.text.toPlainText(includeSemanticsLabels: false)}',
];

Future<void> _attendre(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

const Map<RoleSeance, List<SituationTb>> _situations =
    <RoleSeance, List<SituationTb>>{
      RoleSeance.eleve: <SituationTb>[SituationTb.sal00, SituationTb.ped03],
      RoleSeance.guidee: <SituationTb>[SituationTb.sal00],
      RoleSeance.enseignant: <SituationTb>[
        SituationTb.sal00,
        SituationTb.ped01,
        SituationTb.cmd01,
        SituationTb.lib01,
        SituationTb.ctx01,
      ],
    };

const List<(String, Size, double)> _cadrages = <(String, Size, double)>[
  ('390 x1', Size(390, 844), 1),
  ('320 x2', Size(320, 700), 2),
  ('1440 x1', Size(1440, 900), 1),
];

void main() {
  late String introFr;
  setUpAll(() => introFr = t.salle.seance.bibliotheque.intro);
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _situations.forEach((RoleSeance role, List<SituationTb> liste) {
    for (final SituationTb situation in liste) {
      for (final (String nom, Size taille, double texte) in _cadrages) {
        testWidgets('${role.name} ${situation.name} $nom', (
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
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(DemoSallePage))),
            TextDirection.rtl,
          );
        });
      }
    }
  });

  testWidgets('les libelles de la salle sont ceux de l\'arabe', (
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
    expect(find.text(t.salle.seance.bibliotheque.intro), findsOneWidget);
    expect(t.salle.seance.bibliotheque.intro, isNot(introFr));
    expect(find.text(introFr), findsNothing);
  });

  group('aucun libelle francais rendu dans la salle arabe', () {
    test('le detecteur voit un libelle, parametres compris', () {
      bool voit(String texte) =>
          _libellesFrancais.any(((String, RegExp) l) => l.$2.hasMatch(texte));
      expect(voit('Réessayer'), isTrue);
      expect(voit('État inconnu'), isTrue);
      expect(voit('en salle depuis 4 min'), isTrue);
      expect(voit('إعادة المحاولة'), isFalse);
      expect(voit('Les bonnes manières'), isFalse);
    });

    for (final (String nom, Size taille) in <(String, Size)>[
      ('390 x1', const Size(390, 844)),
      ('1440 x1', const Size(1440, 900)),
    ]) {
      for (final RoleSeance role in RoleSeance.values) {
        for (final SituationTb situation in situationsTb(role)) {
          testWidgets('${role.name} ${situation.name} $nom', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, 1);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              hoteCapture(DemoSallePage(role: role, situation: situation)),
            );
            await _attendre(tester);
            expect(_francaisRendu(tester), isEmpty);
          });
        }
      }
      for (final ObservateurDemo o in ObservateurDemo.values) {
        for (final SituationTb situation in situationsObservateur) {
          testWidgets('${o.name} ${situation.name} $nom', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, 1);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              hoteCapture(DemoSallePage(observateur: o, situation: situation)),
            );
            await _attendre(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            expect(_francaisRendu(tester), isEmpty);
          });
        }
      }
    }

    for (final (String nom, Size taille, double texte) in _cadrages) {
      // A 320 px texte x2, la police de test (plus large que celles du
      // depot) fait passer l'entree des Commandes sous la barre de l'appel :
      // la feuille y est capturee avec les vraies polices, pas ici.
      if (texte > 1) continue;
      testWidgets('feuille d\'effacement $nom', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.dlg01,
            ),
            echelleTexte: texte,
          ),
        );
        await tester.pumpAndSettle();
        await _taper(tester, find.byKey(DeclencheurCommandes.cle));
        await _taper(tester, find.byKey(CommandesPedagogiques.cleMenu));
        await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
        expect(find.byType(ConfirmDestructive), findsOneWidget);
        expect(find.text(t.commun.annuler), findsOneWidget);
        expect(find.text(t.destructif.irreversible), findsOneWidget);
        expect(_francaisRendu(tester), isEmpty);
      });

      testWidgets('echec de la Bibliotheque $nom', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.lib01,
            ),
            echelleTexte: texte,
          ),
        );
        await _attendre(tester);
        final Finder carte = find.text("Cahier d'écriture");
        await tester.scrollUntilVisible(
          carte,
          120,
          scrollable: find
              .descendant(
                of: find.byType(BibliothequeSeance),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await _taper(tester, carte.first);
        await _taper(tester, find.byKey(BibliothequeSeance.clePresenter));
        expect(find.byKey(BibliothequeSeance.cleEchec), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(BibliothequeSeance.clePresenter),
            matching: find.text(t.commun.reessayer),
          ),
          findsOneWidget,
        );
        expect(_francaisRendu(tester), isEmpty);
      });
    }
  });
}
