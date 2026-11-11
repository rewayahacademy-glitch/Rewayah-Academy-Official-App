// MON-ESPACE-ADULTE-SUPPR (pilote, 11/11/2026) : sur la route de production
// `/tuteur/foyer/invitation`, le bouton sous l'etat rendu dit ou il mene
// (« Retour au Foyer ») et y mene (`/tuteur/foyer`). « Mon espace » n'existe
// plus. Donnees de test seulement ; vrai routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

String _lieu(GoRouter r) =>
    r.routerDelegate.currentConfiguration.matches.last.matchedLocation;

void main() {
  for (final (String nom, EtatInvitationRecue etat)
      in <(String, EtatInvitationRecue)>[
        ('acceptee', const InvitationAcceptee('Karim')),
        ('refusee', const InvitationRefuseeParVous()),
      ]) {
    testWidgets('invitation $nom : « Retour au Foyer » mene au Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter r = await monterRouteur(
        tester,
        '${Routes.tuteurFoyer}/invitation',
        source: FausseSourceSession(sessionActive(AppRole.guardian)),
        taille: const Size(390, 1200),
        surcharges: <Override>[
          invitationRecueProvider.overrideWith((Ref _) async => etat),
        ],
      );
      await tester.pump(const Duration(milliseconds: 400));
      final Finder bouton = find.byKey(InvitationRecuePage.suiteKey);
      expect(bouton, findsOneWidget);
      expect(
        find.descendant(
          of: bouton,
          matching: find.text(t.parcours.retourFoyer),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Mon espace'), findsNothing);
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_lieu(r), Routes.tuteurFoyer);
    });
  }
}
