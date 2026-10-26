// Lot demarrage (audit du 25/10/2026, point b) : la nouvelle version prete.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/version/bandeau_nouvelle_version.dart';
import 'package:rewayah_academy/core/version/nouvelle_version.dart';

import '../../capture/outil_capture.dart';

/// Un `version.json` servi, modifiable entre deux lectures.
class _Serveur {
  String corps = '{"version":"1.0.0","build_number":"7"}';
  int lectures = 0;

  Future<String?> lire() async {
    lectures++;
    return empreinteVersion(corps);
  }
}

Future<void> _monter(
  WidgetTester tester,
  _Serveur serveur, {
  bool horsLigne = false,
  VoidCallback? recharger,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(body: BandeauNouvelleVersion(recharger: recharger ?? () {})),
      surcharges: <Override>[
        surveillanceVersionActiveProvider.overrideWithValue(true),
        lecteurVersionProvider.overrideWithValue(serveur.lire),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  test('empreinte : version et numero de build, illisible -> null', () {
    expect(
      empreinteVersion('{"version":"1.0.0","build_number":"7"}'),
      '1.0.0+7',
    );
    expect(empreinteVersion('pas du json'), isNull);
    expect(empreinteVersion('{"app_name":"x"}'), isNull);
  });

  testWidgets('meme version apres 15 minutes : aucun bandeau', (
    WidgetTester tester,
  ) async {
    final _Serveur serveur = _Serveur();
    await _monter(tester, serveur);
    expect(serveur.lectures, 1);
    await tester.pump(cadenceVersion);
    await tester.pump();
    expect(serveur.lectures, 2);
    expect(find.text(t.miseAJour.prete), findsNothing);
  });

  testWidgets('nouveau numero de build : le bandeau et « Recharger »', (
    WidgetTester tester,
  ) async {
    final _Serveur serveur = _Serveur();
    int recharges = 0;
    await _monter(tester, serveur, recharger: () => recharges++);
    serveur.corps = '{"version":"1.0.0","build_number":"8"}';
    await tester.pump(cadenceVersion);
    await tester.pump();
    expect(find.text(t.miseAJour.prete), findsOneWidget);
    await tester.tap(find.text(t.miseAJour.recharger));
    expect(recharges, 1);
  });

  testWidgets('retour au premier plan : relecture immediate', (
    WidgetTester tester,
  ) async {
    final _Serveur serveur = _Serveur();
    await _monter(tester, serveur);
    serveur.corps = '{"version":"1.0.1","build_number":"7"}';
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.miseAJour.prete), findsOneWidget);
  });

  testWidgets('hors ligne : aucune requete', (WidgetTester tester) async {
    final _Serveur serveur = _Serveur();
    await _monter(tester, serveur, horsLigne: true);
    await tester.pump(cadenceVersion);
    await tester.pump();
    expect(serveur.lectures, 0);
    expect(find.text(t.miseAJour.prete), findsNothing);
  });
}
