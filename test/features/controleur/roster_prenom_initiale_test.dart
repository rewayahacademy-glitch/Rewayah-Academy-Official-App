// CTRL-ROSTER-C7-1 (releve VERIF-CT-1) : la liste des eleves de
// l'observation du Controleur montre le prenom et l'initiale du nom
// (decision du directeur C7 = a, 27/09), comme l'Historique, et par la MEME
// fonction (`prenomEtInitiale`). Nom compose, prenom compose, arabe ; a
// 320 px, texte x2, en LTR et en RTL, aucun mot coupe.
//
// CTRL-ROSTER-C7-1b : chaque libelle est affiche dans un isolat a sens
// detecte (`isolerSens`, U+2068 ... U+2069), partage avec l'Historique et
// « Mes Classes ». Le sens RTL est celui de la vraie locale arabe (et non
// une Directionality posee a la main) ; l'ordre visuel du point final est
// mesure sur le rendu : nom arabe en interface francaise, nom latin en
// interface arabe. Les cles `controleur.*` n'existent pas encore dans
// `ar.i18n.json` : les titres de la page restent en francais (repli slang).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/historique_controleur_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

/// Un roster qui couvre les cas de la regle : nom simple, nom compose,
/// prenom compose, arabe, et un eleve sans initiale donnee.
const List<EleveRoster> _roster = <EleveRoster>[
  EleveRoster(id: 'e1', prenom: 'Mariam', initialeNom: 'S'),
  EleveRoster(id: 'e2', prenom: 'Yusuf', initialeNom: 'Ben Salah'),
  EleveRoster(id: 'e3', prenom: 'Abd  al-Rahman', initialeNom: 'el-Amrani'),
  EleveRoster(id: 'e4', prenom: 'عائشة', initialeNom: 'نور'),
  EleveRoster(id: 'e5', prenom: 'Bilal'),
];

const List<String> _attendus = <String>[
  'Mariam S.',
  'Yusuf B.',
  'Abd al-Rahman E.',
  'عائشة ن.',
  'Bilal',
];

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _jusquAuRoster(
  WidgetTester tester, {
  AppLocale langue = AppLocale.fr,
  required Size taille,
  double echelle = 1,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, taille, 1);
  final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
    seanceId: 'seance-A',
    classe: 'Classe Al-Fajr',
    debut: DateTime(2026, 9, 28, 16),
  );
  await tester.pumpWidget(
    hoteCapture(
      ObservationControlePage(seanceId: visite.seanceId),
      echelleTexte: echelle,
      surcharges: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            visite.seanceId: visite,
          }),
        ),
        rosterControleProvider.overrideWith((Ref _, String _) async => _roster),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await _toucher(
    tester,
    find.byKey(ObservationControlePage.cleNature(NatureObservation.aSuivre)),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
    ),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
    ),
  );
}

/// Le paragraphe rendu qui contient [texte].
RenderParagraph _paragraphe(WidgetTester tester, String texte) {
  final List<RenderParagraph> trouves = <RenderParagraph>[
    for (final RenderParagraph r
        in tester.allRenderObjects.whereType<RenderParagraph>())
      if (r.text.toPlainText().contains(texte)) r,
  ];
  expect(trouves, isNotEmpty, reason: texte);
  return trouves.first;
}

/// La boite rendue du caractere d'indice [i] dans [r].
TextBox _boite(RenderParagraph r, int i) => r
    .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
    .first;

/// Verifie, sur le rendu, que le point final de [nom] (« Prenom N. ») est
/// lu juste apres l'initiale dans le sens d'ecriture du nom : a droite de
/// l'initiale pour un nom latin, a gauche pour un nom arabe, quel que soit
/// le sens de l'interface.
void _pointApresInitiale(WidgetTester tester, String nom, {bool rtl = false}) {
  final RenderParagraph r = _paragraphe(tester, nom);
  final String plein = r.text.toPlainText();
  final int point = plein.indexOf(nom) + nom.length - 1;
  expect(plein[point], '.');
  final TextBox p = _boite(r, point);
  final TextBox initiale = _boite(r, point - 1);
  // Meme ligne (les boites se recouvrent en hauteur ; la police arabe n'a
  // pas la meme hauteur que celle du point) : sinon la comparaison n'a pas
  // de sens.
  expect(
    p.top < initiale.bottom && initiale.top < p.bottom,
    isTrue,
    reason: '$nom : $p / $initiale',
  );
  if (rtl) {
    expect(
      p.right <= initiale.left + 0.5,
      isTrue,
      reason: '$nom : $p / $initiale',
    );
  } else {
    expect(
      p.left >= initiale.right - 0.5,
      isTrue,
      reason: '$nom : $p / $initiale',
    );
  }
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La traduction arabe est differee : chargee ici, hors du temps simule
    // de `testWidgets`, pour que `setLocaleSync(ar)` la trouve.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  test('isolerSens : FSI ... PDI, un texte vide reste vide', () {
    expect(isolerSens('Mariam S.'), '\u2068Mariam S.\u2069');
    expect(isolerSens(''), '');
  });

  group('prenomEtInitiale', () {
    test('prenom et initiale du nom, point final', () {
      expect(prenomEtInitiale('Mariam', 'Saleh'), 'Mariam S.');
      expect(prenomEtInitiale('Mariam', 'S'), 'Mariam S.');
      expect(prenomEtInitiale('Mariam', 'saleh'), 'Mariam S.');
    });

    test('nom compose : une seule initiale', () {
      expect(prenomEtInitiale('Yusuf', 'Ben Salah'), 'Yusuf B.');
      expect(prenomEtInitiale('Yusuf', 'el-Amrani'), 'Yusuf E.');
      expect(prenomEtInitiale('Yusuf', '  Ben  Salah '), 'Yusuf B.');
    });

    test('prenom compose garde, espaces en trop retires', () {
      expect(prenomEtInitiale(' Abd  al-Rahman ', 'K'), 'Abd al-Rahman K.');
      expect(prenomEtInitiale('Marie Claire', 'Noor'), 'Marie Claire N.');
    });

    test('arabe : premiere lettre entiere du nom', () {
      expect(prenomEtInitiale('عائشة', 'نور'), 'عائشة ن.');
      // Un grapheme combine (lettre + voyelle) reste entier.
      expect(prenomEtInitiale('مريم', 'سَالم'), 'مريم سَ.');
    });

    test('sans nom : le prenom seul, jamais un point isole', () {
      expect(prenomEtInitiale('Bilal', null), 'Bilal');
      expect(prenomEtInitiale('Bilal', '   '), 'Bilal');
    });
  });

  test('roster de demonstration : prenom et initiale, jamais le nom', () {
    expect(
      <String>[
        for (final EleveRoster e in rosterDemoControleur()) e.nomAffiche,
      ],
      <String>['Mariam S.', 'Yusuf B.', 'Aïcha N.'],
    );
  });

  test(
    'l Historique et l observation : le meme format, la meme source',
    () async {
      final List<RapportControle> rapports = await const HistoriqueDemo()
          .rapports();
      final RapportControle anNour = rapports.firstWhere(
        (RapportControle r) => r.id == 'demo-rapport-0921',
      );
      expect(anNour.presents, <String>['Aïcha N.', 'Mariam S.', 'Yusuf B.']);
      expect(anNour.presents.toSet(), <String>{
        for (final EleveRoster e in rosterDemoControleur()) e.nomAffiche,
      });
    },
  );

  for (final AppLocale langue in AppLocale.values) {
    final TextDirection sens = langue == AppLocale.ar
        ? TextDirection.rtl
        : TextDirection.ltr;
    testWidgets('liste de l observation en prenom et initiale, 320 px x2 '
        '(${langue.languageCode}, ${sens.name})', (WidgetTester tester) async {
      await _jusquAuRoster(
        tester,
        langue: langue,
        taille: const Size(320, 900),
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      for (final String libelle in _attendus) {
        // COUPE-MOTS-4 : le titre d'une carte de choix garde un nom compose
        // entier (gluon invisible U+2060 apres le trait quand la ligne s'y
        // couperait) ; le texte lu est le meme.
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.data?.replaceAll('\u2060', '') == isolerSens(libelle),
          ),
          findsOneWidget,
          reason: libelle,
        );
      }
      // Jamais le prenom seul quand le serveur donne l'initiale.
      expect(find.text('Mariam'), findsNothing);
      expect(find.text('Yusuf'), findsNothing);
      expect(find.textContaining('Ben Salah'), findsNothing);
      expect(
        Directionality.of(tester.element(find.text(isolerSens('Mariam S.')))),
        sens,
      );
      // Un nom compose peut passer a la ligne apres son trait d'union,
      // chaque partie entiere (regle du depot, `motsCoupes`).
      expect(
        motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
        isEmpty,
      );
    });
  }

  testWidgets('le recapitulatif reprend le meme libelle', (
    WidgetTester tester,
  ) async {
    await _jusquAuRoster(tester, taille: const Size(1280, 900));
    await _toucher(tester, find.byKey(ObservationControlePage.cleEleve('e2')));
    await _toucher(tester, find.text(t.commun.continuer).last);
    // Texte facultatif pour « A suivre ».
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text(t.controleur.observation.questionRecap), findsOneWidget);
    expect(find.textContaining('· ${isolerSens('Yusuf B.')}'), findsOneWidget);
  });

  // CTRL-ROSTER-C7-1b : l'ordre bidi, mesure sur le rendu. Sans isolat, le
  // point de « Mariam S. » passait a gauche en interface arabe (« .Mariam
  // S ») et celui de « عائشة ن. » a droite en interface francaise.
  for (final AppLocale langue in AppLocale.values) {
    for (final Size taille in <Size>[
      const Size(320, 900),
      const Size(1440, 900),
    ]) {
      final double echelle = taille.width < 400 ? 2 : 1;
      testWidgets('bidi : le point suit l initiale dans la liste '
          '(${langue.languageCode}, ${taille.width.toInt()} px x$echelle)', (
        WidgetTester tester,
      ) async {
        await _jusquAuRoster(
          tester,
          langue: langue,
          taille: taille,
          echelle: echelle,
        );
        _pointApresInitiale(tester, 'Mariam S.');
        _pointApresInitiale(tester, 'Yusuf B.');
        _pointApresInitiale(tester, 'عائشة ن.', rtl: true);
      });
    }

    for (final (String id, String nom, bool rtl) in <(String, String, bool)>[
      ('e1', 'Mariam S.', false),
      ('e4', 'عائشة ن.', true),
    ]) {
      testWidgets('bidi : le recapitulatif garde le point apres l initiale '
          '(${langue.languageCode}, $id)', (WidgetTester tester) async {
        await _jusquAuRoster(
          tester,
          langue: langue,
          taille: const Size(1280, 900),
        );
        await _toucher(
          tester,
          find.byKey(ObservationControlePage.cleEleve(id)),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        await _toucher(tester, find.text(t.commun.continuer).last);
        expect(find.textContaining('· ${isolerSens(nom)}'), findsOneWidget);
        _pointApresInitiale(tester, nom, rtl: rtl);
      });
    }

    testWidgets('bidi : l Historique isole chaque nom des presents '
        '(${langue.languageCode})', (WidgetTester tester) async {
      LocaleSettings.setLocaleSync(langue);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      fixerVueCapture(tester, const Size(1280, 1400), 1);
      await tester.pumpWidget(
        hoteCapture(
          HistoriqueControleurPage(maintenant: DateTime(2026, 9, 22)),
          surcharges: <Override>[
            portHistoriqueProvider.overrideWithValue(const _HistoriqueBidi()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await _toucher(
        tester,
        find.byKey(HistoriqueControleurPage.ligneKey('bidi')),
      );
      expect(
        find.textContaining(
          '${isolerSens('Mariam S.')}, ${isolerSens('عائشة ن.')}',
        ),
        findsOneWidget,
      );
      _pointApresInitiale(tester, 'Mariam S.');
      _pointApresInitiale(tester, 'عائشة ن.', rtl: true);
    });
  }
}

/// Un Historique d'un seul rapport, presents latin et arabe.
class _HistoriqueBidi implements PortHistorique {
  const _HistoriqueBidi();

  @override
  Future<List<RapportControle>> rapports() async => <RapportControle>[
    RapportControle(
      id: 'bidi',
      missionId: 'mission-bidi',
      classe: 'Classe An-Nour',
      enseignant: 'Sayyid Karim',
      debut: DateTime(2026, 9, 21, 18),
      dureeObservee: const Duration(minutes: 44),
      statut: StatutRapport.envoye,
      choix: ChoixCompteRendu.rienASignaler,
      presents: <String>[
        prenomEtInitiale('Mariam', 'Saleh'),
        prenomEtInitiale('عائشة', 'نور'),
      ],
    ),
  ];

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async => throw StateError('Hors du test.');
}
