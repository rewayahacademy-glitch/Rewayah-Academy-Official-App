// PE-A9, partie ecran (20/11/2026) : apres la connexion d'un compte sans
// profil, `/inscription` ne construit plus « Pour qui creez-vous ce
// compte ? » quand la destination est ailleurs (une invitation en cours mene
// a l'ecran du code). Le test regarde CHAQUE image, de la premiere a la
// derniere : aucune ne montre l'etape d'usage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';

import '../../support/harnais.dart';

Widget _hote() => hoteRoutant(
  depart: Routes.inscription,
  routes: <RouteBase>[
    GoRoute(
      path: Routes.inscription,
      builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
    ),
    GoRoute(
      path: Routes.inscriptionInvitation,
      builder: (BuildContext _, GoRouterState _) =>
          const Scaffold(body: Text('CODE-INVITATION')),
    ),
    GoRoute(
      path: Routes.inscriptionIdentite,
      builder: (BuildContext _, GoRouterState _) =>
          const Scaffold(body: Text('IDENTITE')),
    ),
    GoRoute(
      path: Routes.commencer,
      builder: (BuildContext _, GoRouterState _) =>
          const Scaffold(body: Text('QUESTIONNAIRE')),
    ),
  ],
  surcharges: <Override>[
    portInscriptionCandidatProvider.overrideWithValue(null),
  ],
);

void main() {
  tearDown(oublierInvitationEnCours);

  testWidgets('invitation en cours : aucune image ne montre « Pour qui »', (
    WidgetTester tester,
  ) async {
    retenirInvitationEnCours(code: 'ABCD-EFGH-JKMN');
    await tester.pumpWidget(_hote());
    // La premiere image : le squelette, pas l'etape d'usage.
    expect(find.byType(UsageEtape), findsNothing);
    expect(find.byKey(cleAttenteDestination), findsOneWidget);
    // Chaque image suivante, jusqu'a l'ecran du code.
    for (
      int i = 0;
      i < 60 && find.text('CODE-INVITATION').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(UsageEtape), findsNothing, reason: 'image $i');
    }
    expect(find.text('CODE-INVITATION'), findsOneWidget);
    expect(find.byType(UsageEtape), findsNothing);
  });

  testWidgets('lien du candidat (sans code) : meme regle', (
    WidgetTester tester,
  ) async {
    retenirInvitationEnCours(candidature: true);
    await tester.pumpWidget(_hote());
    expect(find.byType(UsageEtape), findsNothing);
    for (
      int i = 0;
      i < 60 && find.text('CODE-INVITATION').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(UsageEtape), findsNothing, reason: 'image $i');
    }
    expect(find.text('CODE-INVITATION'), findsOneWidget);
  });

  testWidgets('sans invitation : les deux portes, des la premiere image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote());
    expect(find.byType(UsageEtape), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(UsageEtape.portesKey), findsOneWidget);
    expect(find.byKey(cleAttenteDestination), findsNothing);
  });
}
