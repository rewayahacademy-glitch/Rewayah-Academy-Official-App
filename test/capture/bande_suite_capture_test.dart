// BANDE-SUITE (pilote et garde-cap, 11/11/2026) : les ecrans sous NavShell
// qui portent leur propre defilement passent sous la barre flottante, et leur
// dernier element reste visible au-dessus d'elle ; un element fixe en bas
// (« Nouvelle publication ») se pose au-dessus de la barre. Vrai routeur,
// donnees fictives seulement (demonstrations du depot, seances inventees),
// 320 x 640, clair et sombre, defile tout en bas. Prefixe lu dans
// `CAPTURE_PREFIXE` (« apres » par defaut).
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

import '../router/support_routeur.dart' show sessionActive, surchargesRouteur;
import '../support/harnais.dart' show FausseSourceSession, FauxServiceSuivi;
import '../teaching_core/b/faux/faux_ports_b.dart'
    show ressource, surchargesCatalogue, versionsImplicites;
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

const Size _vue = Size(320, 640);

List<Seance> _seances() {
  final DateTime maintenant = DateTime.now();
  return <Seance>[
    for (int i = 1; i <= 14; i++)
      Seance(
        id: 's$i',
        debut: maintenant.subtract(Duration(days: i)),
        fin: maintenant
            .subtract(Duration(days: i))
            .add(const Duration(hours: 1)),
        statut: StatutSeance.terminee,
        eleveId: 'eleve-1',
        elevePrenom: 'Sofia',
        eleveIdentifiant: 'STUD-000001',
        enseignantId: 'ens-1',
        enseignantPrenom: 'Rachid',
        enseignantIdentifiant: 'TEACH-000001',
      ),
  ];
}

List<Override> _communaute() => <Override>[
  portCommunauteProvider.overrideWithValue(
    DonneesCommunauteDemo.port(SituationDemoCommunaute.nominal),
  ),
  portModerationProvider.overrideWithValue(ModerationDemo()),
  portElementsEnregistresProvider.overrideWithValue(
    ElementsEnregistresMemoire(
      maintenant: () => DonneesCommunauteDemo.maintenant,
    ),
  ),
  portPolitiquePiecesJointesProvider.overrideWithValue(
    const PolitiquePiecesJointesDemo(),
  ),
  choixPieceCommunauteProvider.overrideWithValue(const ChoixPieceDemo()),
  horlogeCommunauteProvider.overrideWithValue(
    () => DonneesCommunauteDemo.maintenant,
  ),
];

List<Override> _bibliotheque() {
  final List<dynamic> liste = <dynamic>[
    for (int i = 1; i <= 12; i++) ressource(id: 'r$i'),
  ];
  // Le catalogue et ses versions seulement : le reseau vient deja des
  // surcharges du routeur (un provider ne se surcharge qu'une fois).
  return surchargesCatalogue(
    ressources: liste.cast(),
    versions: versionsImplicites(liste.cast()),
  ).take(2).toList();
}

final List<(String, AppRole, String, List<Override> Function())> _ecrans =
    <(String, AppRole, String, List<Override> Function())>[
      ('eleve_suivi', AppRole.student, Routes.eleveSuivi, () => <Override>[]),
      (
        'enseignant_messages',
        AppRole.teacher,
        Routes.enseignantMessages,
        () => <Override>[
          portMessagesMetierProvider.overrideWithValue(
            MessagesMetierDemo(
              role: RoleDemoCommunications.enseignant,
              maintenant: DateTime.utc(2026, 10, 4, 12),
            ),
          ),
        ],
      ),
      (
        'enseignant_communaute',
        AppRole.teacher,
        Routes.enseignantCommunaute,
        _communaute,
      ),
      (
        'eleve_bibliotheque',
        AppRole.student,
        RoutesTcB.bibliotheque,
        _bibliotheque,
      ),
    ];

Future<void> _monter(
  WidgetTester tester, {
  required AppRole role,
  required String chemin,
  required ThemeMode theme,
  required List<Override> autres,
}) async {
  tester.view.physicalSize = _vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(role)),
          suivi: FauxServiceSuivi(seancesRendues: _seances()),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...autres,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: theme,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  routeur.go(chemin);
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Capture : bande, suite', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (
          String nom,
          AppRole role,
          String chemin,
          List<Override> Function() autres,
        )
        in _ecrans) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String t = theme == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('$nom $t', (WidgetTester tester) async {
          await _monter(
            tester,
            role: role,
            chemin: chemin,
            theme: theme,
            autres: autres(),
          );
          final Finder defilants = find.byType(Scrollable);
          if (defilants.evaluate().isNotEmpty) {
            // A mi-chemin : le contenu passe sous la barre flottante, ou s'y
            // arrete net (avant).
            await tester.drag(defilants.first, const Offset(0, -160));
            for (int i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            debugPrint(
              'PNG ${await capturerVue(tester, 'suite_${_prefixe}_${nom}_${t}_milieu')}',
            );
            // Tout en bas : le dernier element reste visible au-dessus de la
            // barre flottante.
            await tester.drag(defilants.first, const Offset(0, -8000));
            for (int i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
          }
          debugPrint(
            'PNG ${await capturerVue(tester, 'suite_${_prefixe}_${nom}_${t}_fin')}',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
        });
      }
    }
  });
}
