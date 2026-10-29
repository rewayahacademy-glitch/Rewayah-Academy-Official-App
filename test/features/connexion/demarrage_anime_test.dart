// Demarrage et connexion (lot ouverture rapide, 29/10/2026) : le demarrage
// montre le logo d'ouverture, immobile, sans porte ; la connexion qui suit
// joue sa porte une fois ; mouvement reduit : fondus seuls ; le message des
// 8 s sous le logo. Avant ce lot, le demarrage jouait la porte
// (`docs/current/PARCOURS-ENTREE-2026-10-25.md` §3 A et C).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/porte_lumiere.dart';
import 'package:rewayah_academy/features/connexion/coquille_entree.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

/// Une session deja lue active.
class _SessionActive extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'test',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

List<Override> _surcharges({bool active = false}) => <Override>[
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
  if (active) sessionProvider.overrideWith(_SessionActive.new),
];

final Widget _connexion = CoquilleEntree(
  formulaire: (bool _) => const SizedBox.shrink(),
);

/// Le symbole qui se dessine : un `ClipRect` a decoupe, sous la porte.
Finder _symboleQuiSeDessine() => find.descendant(
  of: find.byType(PorteLumiere),
  matching: find.byWidgetPredicate(
    (Widget w) => w is ClipRect && w.clipper != null,
  ),
);

/// Apres le fondu du logo (180 ms), seule la porte peut encore bouger.
const Duration _apresLogo = Duration(milliseconds: 200);

void main() {
  testWidgets('demarrage : le logo seul, aucune porte, aucune animation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteCapture(const EcranDemarrage(), surcharges: _surcharges()),
    );
    await tester.pump();
    expect(find.byType(PorteLumiere), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('demarrage-logo')),
      findsOneWidget,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('session deja active : toujours le logo seul', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteCapture(
        const EcranDemarrage(),
        surcharges: _surcharges(active: true),
      ),
    );
    await tester.pump();
    expect(find.byType(PorteLumiere), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('connexion apres le demarrage : la porte joue une fois', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<bool> connexion = ValueNotifier<bool>(false);
    addTearDown(connexion.dispose);
    await tester.pumpWidget(
      hoteCapture(
        ValueListenableBuilder<bool>(
          valueListenable: connexion,
          builder: (BuildContext _, bool c, Widget? _) =>
              c ? _connexion : const EcranDemarrage(),
        ),
        surcharges: _surcharges(),
      ),
    );
    await tester.pump();
    connexion.value = true;
    await tester.pump();
    await tester.pump(_apresLogo);
    expect(find.byType(PorteLumiere), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(AppMouvement.entreeIllustration);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse, reason: 'jamais de boucle');
  });

  testWidgets('arrivee directe sur la connexion : la porte joue une fois', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteCapture(_connexion, surcharges: _surcharges()));
    await tester.pump(_apresLogo);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(AppMouvement.entreeIllustration);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('connexion, mouvement reduit : fondus seuls', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(hoteCapture(_connexion, surcharges: _surcharges()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_symboleQuiSeDessine(), findsNothing);
    await tester.pump(AppMouvement.entreeIllustration);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('connexion sans mouvement reduit : le symbole se dessine', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteCapture(_connexion, surcharges: _surcharges()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_symboleQuiSeDessine(), findsOneWidget);
    await tester.pump(AppMouvement.entreeIllustration);
  });

  testWidgets('a 8 s, le message sous le logo, qui reste', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteCapture(const EcranDemarrage(), surcharges: _surcharges()),
    );
    await tester.pump(AppDelais.chargementProlonge);
    await tester.pump();
    final Finder message = find.byWidgetPredicate(
      (Widget w) =>
          w is EtatSysteme && w.nature == NatureEtat.chargementProlonge,
    );
    final Finder logo = find.byKey(const ValueKey<String>('demarrage-logo'));
    expect(message, findsOneWidget);
    expect(logo, findsOneWidget);
    expect(
      tester.getRect(message).top,
      greaterThanOrEqualTo(tester.getRect(logo).bottom),
    );
  });
}
