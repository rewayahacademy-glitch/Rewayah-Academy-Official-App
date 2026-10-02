// Revue EA-R (lot L4) : la vague adulte sur le VRAI routeur de l'application
// (`routeurProvider`, hors production), jamais un `GoRouter` monte a la main
// (m16) ; « Refuser l'invitation » tape depuis /demo/adulte (m15) ; et le
// sens droite-a-gauche sur l'acceptation, la recharge et Ma famille (m8).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Monte l'application sur son VRAI routeur (`routeurProvider`), dans le
/// sens [direction], puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  required String depart,
  Size taille = const Size(390, 844),
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
        ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext _, Widget? enfant) => Directionality(
                textDirection: direction,
                child: enfant ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await tester.pumpAndSettle();
  return routeur;
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('m16 : /demo/adulte s\'ouvre par routeurProvider hors '
      'production, et ses ecrans aussi', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester, depart: Routes.demoAdulte);
    expect(lieu(routeur), Routes.demoAdulte);
    expect(find.text(t.adulte.demo.titre), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('lien-ecran-maFamille')),
      findsOneWidget,
    );
    await _taper(
      tester,
      find.byKey(const ValueKey<String>('lien-ecran-maFamille')),
    );
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(lieu(routeur), startsWith(Routes.demoAdulte));
  });

  testWidgets('m15 : depuis /demo/adulte, l\'invitation recue, « Refuser '
      'l\'invitation » tape : « Invitation refusee », plus aucune reponse, '
      'Mon espace sans Forfait famille', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester, depart: Routes.demoAdulte);
    await _taper(
      tester,
      find.byKey(const ValueKey<String>('lien-invitation-recue')),
    );
    await _taper(tester, find.byType(ClocheNotifications).first);
    expect(find.byType(NotificationsPage), findsOneWidget);
    await _taper(
      tester,
      find.byKey(
        const ValueKey<String>('notification-demo-invitation-forfait'),
      ),
    );
    expect(find.byType(InvitationRecuePage), findsOneWidget);
    final Finder refuser = find.byKey(InvitationRecuePage.refuserKey);
    expect(
      find.descendant(
        of: refuser,
        matching: find.text(t.adulte.acceptation.refuser),
      ),
      findsOneWidget,
    );

    await _taper(tester, refuser);
    expect(find.text(t.adulte.acceptation.refuseeTitre), findsOneWidget);
    expect(find.text(t.adulte.acceptation.refus), findsOneWidget);
    expect(find.byKey(InvitationRecuePage.refuserKey), findsNothing);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
    expect(find.textContaining('rejoint'), findsNothing);

    // Le retour lit la situation d'apres : le foyer sans second adulte.
    await _taper(tester, find.byType(DisqueRetour).first);
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.queryParameters['etat'],
      EtatDemoAdulte.titulaireSansConjoint.name,
    );
    expect(
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.forfaitFamille),
      ),
      findsNothing,
    );
  });

  group('m8 : sens droite-a-gauche, sur le vrai routeur', () {
    testWidgets('acceptation a 1440 : « Refuser » au bord de debut (a '
        'droite), « Accepter » a sa gauche, meme largeur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: adresseDemoAdulte(
          EcranDemoAdulte.invitationRecue,
          etat: EtatDemoAdulte.invitationEnAttente,
          vue: VueDemoAdulte.secondAdulte,
        ),
        taille: const Size(1440, 900),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      final Rect refus = tester.getRect(
        find.byKey(InvitationRecuePage.refuserKey),
      );
      final Rect accord = tester.getRect(
        find.byKey(InvitationRecuePage.accepterKey),
      );
      expect(refus.top, accord.top);
      expect(refus.left, greaterThan(accord.left));
      expect(refus.width, accord.width);
    });

    testWidgets('acceptation a 390 : refus d\'abord, sans debordement', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: adresseDemoAdulte(
          EcranDemoAdulte.invitationRecue,
          etat: EtatDemoAdulte.invitationEnAttente,
          vue: VueDemoAdulte.secondAdulte,
        ),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.byKey(InvitationRecuePage.refuserKey)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(InvitationRecuePage.accepterKey)).dy,
        ),
      );
    });

    testWidgets('recharge a 390 : les deux etapes sans debordement, « Payer » '
        'au bord de fin (a gauche)', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: adresseDemoAdulte(EcranDemoAdulte.recharge),
        direction: TextDirection.rtl,
      );
      expect(find.byType(RechargeFoyerPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _taper(
        tester,
        find.byKey(RechargeFoyerPage.caseDe(DonneesAdulteDemo.aichaId)),
      );
      await _taper(
        tester,
        find.byKey(
          RechargeFoyerPage.offreDe(
            DonneesAdulteDemo.aichaId,
            DonneesAdulteDemo.offreA,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await _taper(tester, find.byKey(RechargeFoyerPage.verifierKey));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.byKey(RechargeFoyerPage.payerKey)).dx,
        moreOrLessEquals(
          tester.getTopLeft(find.byKey(RechargeFoyerPage.totalKey)).dx,
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('Ma famille a 390 et a 1440 : sans debordement ; « Faire une '
        'nouvelle demande » au bord de fin (a gauche)', (
      WidgetTester tester,
    ) async {
      final String adresse = adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.validationRefusee,
      );
      await _monter(tester, depart: adresse, direction: TextDirection.rtl);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _monter(
        tester,
        depart: adresse,
        taille: const Size(1440, 900),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.byKey(nouvelleDemandeKey)).dx,
        moreOrLessEquals(
          tester.getTopLeft(find.byKey(lignePlaceAdulteKey)).dx,
          epsilon: 0.5,
        ),
      );
    });
  });
}
