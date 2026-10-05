// CTRL-ROSTER-C7-1 (releve VERIF-CT-1) : la liste des eleves de
// l'observation du Controleur montre le prenom et l'initiale du nom
// (decision du directeur C7 = a, 27/09), comme l'Historique, et par la MEME
// fonction (`prenomEtInitiale`). Nom compose, prenom compose, arabe ; a
// 320 px, texte x2, en LTR et en RTL, aucun mot coupe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
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
  TextDirection sens = TextDirection.ltr,
  required Size taille,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
    seanceId: 'seance-A',
    classe: 'Classe Al-Fajr',
    debut: DateTime(2026, 9, 28, 16),
  );
  await tester.pumpWidget(
    hoteCapture(
      Directionality(
        textDirection: sens,
        child: ObservationControlePage(seanceId: visite.seanceId),
      ),
      echelleTexte: echelle,
      surcharges: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            visite.seanceId: visite,
          }),
        ),
        rosterControleProvider.overrideWith((Ref _) async => _roster),
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

void main() {
  setUpAll(chargerPolicesDuDepot);

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

  for (final TextDirection sens in TextDirection.values) {
    testWidgets(
      'liste de l observation en prenom et initiale, 320 px x2 (${sens.name})',
      (WidgetTester tester) async {
        await _jusquAuRoster(
          tester,
          sens: sens,
          taille: const Size(320, 900),
          echelle: 2,
        );
        expect(tester.takeException(), isNull);
        for (final String libelle in _attendus) {
          expect(find.text(libelle), findsOneWidget, reason: libelle);
        }
        // Jamais le prenom seul quand le serveur donne l'initiale.
        expect(find.text('Mariam'), findsNothing);
        expect(find.text('Yusuf'), findsNothing);
        expect(find.textContaining('Ben Salah'), findsNothing);
        expect(Directionality.of(tester.element(find.text('Mariam S.'))), sens);
        // Un nom compose peut passer a la ligne apres son trait d'union,
        // chaque partie entiere (regle du depot, `motsCoupes`).
        expect(
          motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
          isEmpty,
        );
      },
    );
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
    expect(find.textContaining('· Yusuf B.'), findsOneWidget);
  });
}
