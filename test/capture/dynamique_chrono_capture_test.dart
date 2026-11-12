// Captures de recette DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, retours sur
// la salle, points 2, 3, 5 et 15) : la Dynamique chrono a sa place reservee,
// repliee et depliee, dans la vraie page `/salle` (faux moteur, page 42 du
// Coran presentee) ; eleve et enseignant a 390, tablette 834, ordinateur
// 1440 ; la salle reduite a 390. Clair, plus un sombre et l'arabe.
// Captures de test, pas la preuve en production.
// Saute sans CAPTURE_DIR. Nommage : <role>_<largeur>_<etat>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle_seance/barre_seance_en_direct.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';

import '../support/harnais.dart';
import '../support/salle_chrono.dart';
import 'outil_capture.dart';

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
    peutRecevoir: true,
    invisible: false,
    peutModerer: true,
  ),
  expireLe: DateTime.utc(2030),
);

/// La salle reduite (l'enseignant est sorti de la salle, la seance continue) :
/// la meme ligne repliee que la Dynamique chrono, au-dessus de la page.
Future<void> _salleReduite(
  WidgetTester tester,
  String nom, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, const Size(390, 844), 2);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final ControleurSessionPersistante controleur = ControleurSessionPersistante(
    moteur,
    FauxServiceVideo(),
  );
  addTearDown(controleur.liberer);
  controleur.adopter(
    cours: const SessionEnCours(
      sessionId: 's1',
      groupeId: 'g1',
      libelleGroupe: 'Les sourates courtes, mardi 18 h',
    ),
    acces: _acces(),
  );
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.enseignantJournee,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.enseignantJournee,
        builder: (BuildContext _, GoRouterState _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  final DateTime t0 = DateTime.now().toUtc().subtract(
    const Duration(minutes: 52),
  );
  await tester.pumpWidget(
    hoteCapture(
      BarreSeanceEnDirect(
        routeur: routeur,
        child: Builder(
          builder: (BuildContext c) => ColoredBox(
            color: AppPalette.of(c).surfaceCanvas.background,
            child: const SizedBox.expand(),
          ),
        ),
      ),
      surcharges: <Override>[
        signalChronoProvider.overrideWithValue(() {}),
        controleurSessionProvider.overrideWithValue(controleur),
        bornesSalleProvider.overrideWith(
          (Ref _, CleBornesSalle _) => BornesChrono(
            debutUtc: t0,
            finPrevueUtc: t0.add(const Duration(minutes: 90)),
          ),
        ),
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
  await capturer(tester, nom);
}

Future<void> _deplier(WidgetTester tester) async {
  await tester.tap(find.byKey(DynamiqueChrono.cleDeplier).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('captures DYNAMIQUE-CHRONO-1', skip: sautSansCapture, () {
    for (final (String role, Size taille, String nom, double densite)
        in <(String, Size, String, double)>[
          ('student', const Size(390, 844), 'eleve_390', 2),
          ('teacher', const Size(390, 844), 'enseignant_390', 2),
          ('teacher', const Size(834, 1194), 'enseignant_834', 1),
          ('student', const Size(834, 1194), 'eleve_834', 1),
          ('teacher', const Size(1440, 900), 'enseignant_1440', 1),
          ('student', const Size(1440, 900), 'eleve_1440', 1),
          ('teacher', const Size(1024, 768), 'enseignant_1024', 1),
          ('teacher', const Size(1180, 820), 'enseignant_1180', 1),
        ]) {
      testWidgets('$nom, repliee puis depliee', (WidgetTester tester) async {
        await monterSalleChrono(
          tester,
          role: role,
          taille: taille,
          densite: densite,
          etatEleve: EtatPresence.enRetard,
        );
        await capturer(tester, '${nom}_repliee_light');
        await _deplier(tester);
        await capturer(tester, '${nom}_depliee_light');
      });
    }

    testWidgets('eleve 390, sombre', (WidgetTester tester) async {
      await monterSalleChrono(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        densite: 2,
        theme: ThemeMode.dark,
        etatEleve: EtatPresence.enRetard,
      );
      await capturer(tester, 'eleve_390_repliee_dark');
      await _deplier(tester);
      await capturer(tester, 'eleve_390_depliee_dark');
    });

    testWidgets('enseignant 1440, sombre', (WidgetTester tester) async {
      await monterSalleChrono(
        tester,
        role: 'teacher',
        taille: const Size(1440, 900),
        theme: ThemeMode.dark,
      );
      await capturer(tester, 'enseignant_1440_repliee_dark');
    });

    testWidgets('eleve 390, arabe', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterSalleChrono(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        densite: 2,
        etatEleve: EtatPresence.enRetard,
      );
      await capturer(tester, 'eleve_390_repliee_ar');
      await _deplier(tester);
      await capturer(tester, 'eleve_390_depliee_ar');
    });

    testWidgets('salle reduite 390', (WidgetTester tester) async {
      await _salleReduite(tester, 'salle_reduite_390_light');
    });

    testWidgets('salle reduite 390, sombre', (WidgetTester tester) async {
      await _salleReduite(
        tester,
        'salle_reduite_390_dark',
        mode: ThemeMode.dark,
      );
    });

    testWidgets('enseignant 320, texte x2', (WidgetTester tester) async {
      await monterSalleChrono(
        tester,
        role: 'teacher',
        taille: const Size(320, 700),
        densite: 2,
        echelleTexte: 2,
      );
      await capturer(tester, 'enseignant_320x2_repliee_light');
      await _deplier(tester);
      await capturer(tester, 'enseignant_320x2_depliee_light');
    });
  });
}
