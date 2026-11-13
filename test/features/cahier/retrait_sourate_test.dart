// CORRIGER-SOURATE (directeur, 11/11/2026 ; decisions du garde-cap, 11/11) :
// une sourate validee par erreur se retire depuis la feuille de l'eleve au
// cahier. Le geste n'est montre que pour ce que le serveur dit retirable par
// la personne connectee ; le retrait attend le serveur ; un refus et une
// erreur se disent ; rien n'est montre comme fait avant la reponse.
// Donnees fictives uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/retrait_sourate.dart';
import 'package:rewayah_academy/features/fiche_groupe/sourates_classe.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/enseignant_demo.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Al-Fatiha et An-Nas validees, Al-Falaq a valider.
const List<SourateBases> _sourates = <SourateBases>[
  SourateBases(
    ordre: 1,
    numero: 1,
    nom: 'Al-Fatiha',
    nomArabe: 'الفاتحة',
    validee: true,
  ),
  SourateBases(
    ordre: 2,
    numero: 114,
    nom: 'An-Nas',
    nomArabe: 'الناس',
    validee: true,
  ),
  SourateBases(
    ordre: 3,
    numero: 113,
    nom: 'Al-Falaq',
    nomArabe: 'الفلق',
    validee: false,
  ),
];

/// Les retraits demandes au serveur, et sa reponse.
class _Serveur {
  _Serveur({this.erreur});

  final Exception? erreur;
  final List<(int, String?)> appels = <(int, String?)>[];

  Future<void> retirer(int numero, String? motif) async {
    appels.add((numero, motif));
    if (erreur case final Exception e) throw e;
  }
}

/// Ouvre la feuille de l'eleve et rend la decision a sa fermeture.
Future<DecisionEleve? Function()> _ouvrir(
  WidgetTester tester, {
  Map<int, DateTime?> retirables = const <int, DateTime?>{},
  _Serveur? serveur,
  ThemeMode theme = ThemeMode.light,
}) async {
  final BrouillonCahier brouillon = DonneesEnseignantDemo.brouillonCahier();
  final ParticipantBrouillon nour = brouillon.participants.first;
  DecisionEleve? rendue;
  await tester.pumpWidget(
    hoteCapture(
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () async {
                rendue = await AppBottomSheet.ouvrir<DecisionEleve>(
                  context,
                  titre: t.enseignant.cahier.ajusterPour(eleve: 'Nour'),
                  constructeur: (BuildContext _) => FeuilleAjusterCahier(
                    participant: nour,
                    brouillon: brouillon,
                    decision: DecisionEleve(studentId: nour.membre.studentId),
                    sourates: _sourates,
                    retirables: retirables,
                    onRetirer: serveur?.retirer,
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
      themeMode: theme,
    ),
  );
  await _toucher(tester, find.text('ouvrir'));
  return () => rendue;
}

final Finder _retirerFatiha = find.byKey(
  const ValueKey<String>('cahier-retirer-1'),
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture des retirables : par eleve et numero, limite ou sans', () {
    final Map<String, Map<int, DateTime?>> lu = retirablesDepuisReponse(
      <Object?>[
        <String, Object?>{
          'student_id': 'e1',
          'numero': 1,
          'retirable_jusqua': '2026-11-12T16:00:00Z',
        },
        <String, Object?>{
          'student_id': 'e1',
          'numero': 114,
          'retirable_jusqua': null,
        },
        <String, Object?>{'student_id': 'e2', 'numero': 'x'},
        'illisible',
      ],
    );
    expect(lu.keys, <String>['e1']);
    expect(lu['e1']![1], DateTime.utc(2026, 11, 12, 16));
    expect(lu['e1']!.containsKey(114), isTrue);
    expect(lu['e1']![114], isNull);
    expect(retirablesDepuisReponse(null), isEmpty);
  });

  test('sans serveur : rien a retirer, et un retrait est refuse', () async {
    const SouratesClasseAbsentes port = SouratesClasseAbsentes();
    expect(await port.souratesRetirables('c1'), isEmpty);
    await expectLater(
      port.retirer(eleveId: 'e1', numero: 1),
      throwsA(isA<RetraitSourateRefuse>()),
    );
  });

  testWidgets('retirable : confirmer avec un motif, la sourate redevient a '
      'valider', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    final _Serveur serveur = _Serveur();
    final DecisionEleve? Function() rendue = await _ouvrir(
      tester,
      retirables: <int, DateTime?>{1: DateTime.utc(2026, 11, 12, 16)},
      serveur: serveur,
    );
    expect(find.text(t.cahierSourates.retirerTitre), findsOneWidget);
    // Seule la sourate que le serveur dit retirable porte le geste.
    expect(_retirerFatiha, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cahier-retirer-114')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('cahier-sourate-1')),
      findsNothing,
    );

    await _toucher(tester, _retirerFatiha);
    expect(
      find.text(t.cahierSourates.retirerQuestion(nom: 'Al-Fatiha')),
      findsOneWidget,
    );
    expect(find.text(t.cahierSourates.retirerConsequence), findsOneWidget);
    // Annuler : rien ne part.
    await _toucher(tester, find.text(t.commun.annuler));
    expect(serveur.appels, isEmpty);
    expect(_retirerFatiha, findsOneWidget);

    await _toucher(tester, _retirerFatiha);
    await tester.enterText(
      find.descendant(
        of: find.byKey(FeuilleRetraitSourate.cleMotif),
        matching: find.byType(EditableText),
      ),
      '  Cochee pour le mauvais eleve  ',
    );
    await _toucher(tester, find.byKey(FeuilleRetraitSourate.cleRetirer));
    expect(serveur.appels, <(int, String?)>[
      (1, 'Cochee pour le mauvais eleve'),
    ]);
    // La confirmation est fermee ; la sourate se propose de nouveau.
    expect(find.byType(FeuilleRetraitSourate), findsNothing);
    expect(
      find.text(t.cahierSourates.retirerFait(nom: 'Al-Fatiha')),
      findsOneWidget,
    );
    expect(_retirerFatiha, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('cahier-sourate-1')),
      findsOneWidget,
    );
    expect(
      find.text(t.cahierSourates.dejaValidees(n: '1', total: '3')),
      findsOneWidget,
    );
    // Une sourate retiree ne repart pas dans le cahier sans etre cochee.
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));
    expect(rendue()!.souratesValidees, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans retirable (delai passe, autre auteur) : aucun geste', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    await _ouvrir(tester, serveur: _Serveur());
    expect(find.text(t.cahierSourates.retirerTitre), findsNothing);
    expect(find.text(t.cahierSourates.retirer), findsNothing);
  });

  testWidgets('sans retrait branche : aucun geste, meme retirable', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    await _ouvrir(tester, retirables: const <int, DateTime?>{1: null});
    expect(find.text(t.cahierSourates.retirer), findsNothing);
  });

  testWidgets('refus du serveur : dit, la sourate reste validee', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    final _Serveur serveur = _Serveur(erreur: const RetraitSourateRefuse());
    await _ouvrir(
      tester,
      retirables: <int, DateTime?>{1: DateTime.utc(2026, 11, 12, 16)},
      serveur: serveur,
    );
    await _toucher(tester, _retirerFatiha);
    await _toucher(tester, find.byKey(FeuilleRetraitSourate.cleRetirer));
    expect(serveur.appels, hasLength(1));
    expect(find.text(t.cahierSourates.retirerRefus), findsOneWidget);
    // Plus de bouton « Retirer » dans la confirmation : seul « Annuler ».
    expect(find.byKey(FeuilleRetraitSourate.cleRetirer), findsNothing);
    await _toucher(tester, find.text(t.commun.annuler));
    expect(
      find.text(t.cahierSourates.retirerFait(nom: 'Al-Fatiha')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('cahier-sourate-1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('erreur : dite, on peut reessayer', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    final _Serveur serveur = _Serveur(erreur: Exception('reseau'));
    await _ouvrir(
      tester,
      retirables: const <int, DateTime?>{1: null},
      serveur: serveur,
    );
    await _toucher(tester, _retirerFatiha);
    await _toucher(tester, find.byKey(FeuilleRetraitSourate.cleRetirer));
    expect(find.text(t.cahierSourates.retirerEchec), findsOneWidget);
    expect(find.byKey(FeuilleRetraitSourate.cleRetirer), findsOneWidget);
    expect(serveur.appels.single, (1, null));
  });

  // R3 : la feuille avec le geste, puis la confirmation, a 390 en clair,
  // sombre et arabe. Donnees fictives. Jamais sans CAPTURE_DIR.
  group('Capture : retirer une sourate', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 2400), 1);
        await _ouvrir(
          tester,
          retirables: <int, DateTime?>{1: DateTime.utc(2026, 11, 12, 16)},
          serveur: _Serveur(),
          theme: theme,
        );
        await tester.ensureVisible(find.text(t.cahierSourates.titre));
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, 'feuille_390_$nom')}');
        await _toucher(tester, _retirerFatiha);
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturerVue(tester, 'confirmation_390_$nom')}');
      });
    }
  });
}
