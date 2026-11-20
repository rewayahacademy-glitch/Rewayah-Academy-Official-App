// LETTRE-CANDIDATS : captures R3 de la lettre aux candidats (le haut avec
// Praxis, la paie, le verrou), sautees sans CAPTURE_DIR.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/candidature/lettre/lettre_candidats_page.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

class _Candidat extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    profileId: 'p1',
    role: AppRole.teacher,
    accountStatus: AccountStatus.pendingKyc,
    lectureProfil: LectureProfil.presente,
  );
}

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  required bool accordsFaits,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.lettreEnseignants,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.lettreEnseignants,
          builder: (BuildContext _, GoRouterState _) =>
              const LettreCandidatsPage(),
        ),
        ...routesCandidature(),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: FauxMaCandidature(),
          etat: etatCandidat(
            candidature: candidatureAFaire(),
            accordsFaits: accordsFaits,
          ),
        ),
        sessionProvider.overrideWith(_Candidat.new),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom = '${taille.width.toInt()}-${langue.languageCode}';
        final TextDirection? sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : null;
        testWidgets('lettre-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(tester, taille, accordsFaits: true, direction: sens);
          await capturerVue(tester, 'lettre-candidats/haut-$nom');
          await tester.scrollUntilVisible(
            find.byKey(ContenuLettre.clePartie(4)),
            400,
            scrollable: find.byType(Scrollable).first,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'lettre-candidats/paie-$nom');
        });
        testWidgets('verrou-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(tester, taille, accordsFaits: false, direction: sens);
          await capturerVue(tester, 'lettre-candidats/verrou-$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
