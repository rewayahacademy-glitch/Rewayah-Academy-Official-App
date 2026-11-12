// CORRIGER-SOURATE-DIRECTION (garde-cap, 12/11/2026) : les sourates validees
// d'une Classe que la personne connectee peut retirer. La liste vient du
// serveur (capacite par ligne, jamais le role) ; le retrait attend le
// serveur ; vide, erreur et hors ligne se disent. Donnees fictives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/fiche_groupe/retrait_sourate.dart';
import 'package:rewayah_academy/features/fiche_groupe/sourates_classe.dart';
import 'package:rewayah_academy/features/fiche_groupe/sourates_retirables_classe.dart';

import '../../capture/outil_capture.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

const List<SourateBases> _bases = <SourateBases>[
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
];

/// Le serveur des sourates : ce qui se retire, et les retraits demandes.
class _Port implements PortSouratesClasse {
  _Port(this.retirables, {this.erreurRetrait, this.erreurLecture = false});

  Map<String, Map<int, DateTime?>> retirables;
  final Exception? erreurRetrait;
  bool erreurLecture;
  final List<(String, int, String?)> retraits = <(String, int, String?)>[];

  @override
  Future<Map<String, List<SourateBases>>> souratesDeLaClasse(
    String groupeId,
  ) async => <String, List<SourateBases>>{'e1': _bases, 'e2': _bases};

  @override
  Future<Map<String, Map<int, DateTime?>>> souratesRetirables(
    String groupeId,
  ) async {
    if (erreurLecture) throw Exception('lecture');
    return retirables;
  }

  @override
  Future<void> retirer({
    required String eleveId,
    required int numero,
    String? motif,
  }) async {
    retraits.add((eleveId, numero, motif));
    if (erreurRetrait case final Exception e) throw e;
    retirables = <String, Map<int, DateTime?>>{
      for (final MapEntry<String, Map<int, DateTime?>> e in retirables.entries)
        e.key: <int, DateTime?>{...e.value}..remove(numero),
    };
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Port port, {
  bool afficherSiVide = true,
  bool horsLigne = false,
  ThemeMode theme = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SouratesRetirablesClasse(
            groupeId: 'c1',
            afficherSiVide: afficherSiVide,
            noms: const <String, String>{'e1': 'Nour', 'e2': 'Yasmine'},
          ),
        ),
      ),
      surcharges: <Override>[
        portSouratesClasseProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(null);
  });

  testWidgets('direction : chaque sourate retirable, sans limite ; retirer '
      'avec un motif, la ligne part', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    final _Port port = _Port(<String, Map<int, DateTime?>>{
      'e1': <int, DateTime?>{1: null},
      'e2': <int, DateTime?>{114: null},
    });
    await _monter(tester, port);
    expect(find.text(t.souratesRetirables.titre), findsOneWidget);
    expect(
      find.text(
        t.souratesRetirables.ligne(eleve: 'Nour', sourate: 'Al-Fatiha'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        t.souratesRetirables.ligne(eleve: 'Yasmine', sourate: 'An-Nas'),
      ),
      findsOneWidget,
    );
    // Sans limite : aucune heure.
    expect(find.textContaining('Possible'), findsNothing);

    await _toucher(
      tester,
      find.byKey(SouratesRetirablesClasse.cleRetirer('e1', 1)),
    );
    expect(
      find.text(t.cahierSourates.retirerQuestion(nom: 'Al-Fatiha')),
      findsOneWidget,
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(FeuilleRetraitSourate.cleMotif),
        matching: find.byType(EditableText),
      ),
      'Validee pour le mauvais eleve',
    );
    await _toucher(tester, find.byKey(FeuilleRetraitSourate.cleRetirer));
    expect(port.retraits, <(String, int, String?)>[
      ('e1', 1, 'Validee pour le mauvais eleve'),
    ]);
    expect(
      find.text(t.cahierSourates.retirerFait(nom: 'Al-Fatiha')),
      findsOneWidget,
    );
    expect(
      find.byKey(SouratesRetirablesClasse.cleRetirer('e1', 1)),
      findsNothing,
    );
    expect(
      find.byKey(SouratesRetirablesClasse.cleRetirer('e2', 114)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('enseignant : la limite se dit, aujourd hui ou demain', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    final DateTime maintenant = DateTime.now();
    final DateTime apres = maintenant.add(const Duration(hours: 48));
    await _monter(
      tester,
      _Port(<String, Map<int, DateTime?>>{
        'e1': <int, DateTime?>{1: maintenant, 114: apres},
      }),
    );
    expect(
      find.text(t.souratesRetirables.jusqua(heure: heureChezMoi(maintenant))),
      findsOneWidget,
    );
    expect(
      find.text(t.souratesRetirables.jusquaDemain(heure: heureChezMoi(apres))),
      findsOneWidget,
    );
  });

  testWidgets('vide : la phrase pour la direction ; rien pour l enseignant', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    await _monter(tester, _Port(<String, Map<int, DateTime?>>{}));
    expect(find.byKey(SouratesRetirablesClasse.cleVide), findsOneWidget);
    await _monter(
      tester,
      _Port(<String, Map<int, DateTime?>>{}),
      afficherSiVide: false,
    );
    expect(find.text(t.souratesRetirables.titre), findsNothing);
  });

  testWidgets('erreur : dite, et « Reessayer » relit', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    final _Port port = _Port(<String, Map<int, DateTime?>>{
      'e1': <int, DateTime?>{1: null},
    }, erreurLecture: true);
    await _monter(tester, port);
    expect(find.byKey(SouratesRetirablesClasse.cleErreur), findsOneWidget);
    port.erreurLecture = false;
    await _toucher(tester, find.text(t.commun.reessayer));
    expect(find.byKey(SouratesRetirablesClasse.cleErreur), findsNothing);
    expect(
      find.byKey(SouratesRetirablesClasse.cleRetirer('e1', 1)),
      findsOneWidget,
    );
  });

  testWidgets('hors ligne : dit, aucun geste', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    await _monter(
      tester,
      _Port(<String, Map<int, DateTime?>>{
        'e1': <int, DateTime?>{1: null},
      }),
      horsLigne: true,
    );
    expect(find.byKey(SouratesRetirablesClasse.cleHorsLigne), findsOneWidget);
    expect(find.text(t.cahierSourates.retirer), findsNothing);
  });

  testWidgets('refus du serveur : dit dans la confirmation, rien de retire', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 1600), 1);
    final _Port port = _Port(<String, Map<int, DateTime?>>{
      'e1': <int, DateTime?>{1: DateTime.now()},
    }, erreurRetrait: const RetraitSourateRefuse());
    await _monter(tester, port);
    await _toucher(
      tester,
      find.byKey(SouratesRetirablesClasse.cleRetirer('e1', 1)),
    );
    await _toucher(tester, find.byKey(FeuilleRetraitSourate.cleRetirer));
    expect(find.text(t.cahierSourates.retirerRefus), findsOneWidget);
    await _toucher(tester, find.text(t.commun.annuler));
    expect(
      find.text(t.cahierSourates.retirerFait(nom: 'Al-Fatiha')),
      findsNothing,
    );
  });

  // R3 : la section de la fiche de la Classe, 390, clair, sombre et arabe.
  // Donnees fictives. Jamais sans CAPTURE_DIR.
  group('Capture : sourates retirables', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 700), 1);
        await _monter(
          tester,
          _Port(<String, Map<int, DateTime?>>{
            'e1': <int, DateTime?>{1: null},
            'e2': <int, DateTime?>{114: null},
          }),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturerVue(tester, 'section_390_$nom')}');
      });
    }
  });
}
