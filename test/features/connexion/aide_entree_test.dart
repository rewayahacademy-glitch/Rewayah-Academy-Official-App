// AUDIT-FAMILLE-1 (22/11/2026) : l'aide pour qui n'arrive pas a entrer. La ligne
// lit le canal sur le serveur sans compte ; sans canal, rien. Elle est posee
// sur la connexion.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/capacites/support_public.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/connexion/aide_entree.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../../support/harnais.dart';

const CanalSupport _courriel = CanalSupport(
  nature: NatureCanalSupport.courriel,
  adresse: 'support@rewayahacademy.com',
);

Override _canal(CanalSupport? canal) =>
    lectureCanalSupportPublicProvider.overrideWithValue(() async => canal);

void main() {
  testWidgets('avec un canal : la phrase et l adresse', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(const AideEntree(), surcharges: <Override>[_canal(_courriel)]),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(t.connexion.aideEntree(adresse: 'support@rewayahacademy.com')),
      findsOneWidget,
    );
  });

  testWidgets('sans canal publie : rien n est rendu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(const AideEntree(), surcharges: <Override>[_canal(null)]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AideEntree.cle), findsNothing);
  });

  testWidgets('lecture en echec : rien n est rendu, aucune adresse inventee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const AideEntree(),
        surcharges: <Override>[
          lectureCanalSupportPublicProvider.overrideWithValue(
            () async => throw StateError('hors ligne'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AideEntree.cle), findsNothing);
  });

  testWidgets('la connexion pose la ligne d aide', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      hote(
        const ConnexionPage(),
        surcharges: <Override>[
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          demoAuthActiveProvider.overrideWithValue(false),
          _canal(_courriel),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AideEntree.cle), findsOneWidget);
  });
}
