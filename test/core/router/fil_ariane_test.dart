// FIL-ARIANE (directeur, 06/11/2026) : le fil se calcule depuis l'arbre des
// routes du role et la pile du routeur ; au telephone, une page hors coquille
// garde un disque retour.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_ariane.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

SessionState _session(AppRole role, {bool autonome = false}) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: AccountStatus.active,
  eleveAutonome: autonome,
  lectureProfil: LectureProfil.presente,
);

List<String> _libelles(List<SegmentFil> s) => <String>[
  for (final SegmentFil x in s) '${x.libelle}@${x.chemin}',
];

void main() {
  group('ancetresFil (pur)', () {
    final PlanFil tuteur = planFilPour(_session(AppRole.guardian))!;
    final PlanFil admin = planFilPour(_session(AppRole.admin))!;

    test('une destination de premier niveau n\'a pas de fil', () {
      expect(ancetresFil(plan: tuteur, chemin: Routes.tuteurFoyer), isEmpty);
      expect(ancetresFil(plan: tuteur, chemin: Routes.tuteurAccueil), isEmpty);
      expect(ancetresFil(plan: admin, chemin: Routes.admin), isEmpty);
    });

    test('une page sous une destination la prend pour premier segment', () {
      expect(
        _libelles(
          ancetresFil(
            plan: tuteur,
            chemin: '${Routes.tuteurFoyer}/e1/finances',
          ),
        ),
        <String>['${t.nav.tuteur.foyer}@${Routes.tuteurFoyer}'],
      );
    });

    test('la Bibliotheque poussee depuis le Compte : Compte', () {
      expect(
        _libelles(
          ancetresFil(
            plan: tuteur,
            chemin: Routes.tcBibliotheque,
            precedent: Routes.tuteurCompte,
          ),
        ),
        <String>['${t.nav.tuteur.compte}@${Routes.tuteurCompte}'],
      );
    });

    test('la Bibliotheque ouverte par son adresse : le Compte du role', () {
      expect(
        _libelles(ancetresFil(plan: tuteur, chemin: Routes.tcBibliotheque)),
        <String>['${t.nav.tuteur.compte}@${Routes.tuteurCompte}'],
      );
      final PlanFil enseignant = planFilPour(_session(AppRole.teacher))!;
      expect(
        _libelles(ancetresFil(plan: enseignant, chemin: Routes.tcBibliotheque)),
        <String>['${t.nav.enseignant.profil}@${Routes.enseignantProfil}'],
      );
    });

    test('une page hors de toute destination : l\'accueil du role', () {
      expect(
        _libelles(ancetresFil(plan: tuteur, chemin: '/tuteur/reglages')),
        <String>['${t.nav.tuteur.accueil}@${Routes.tuteurAccueil}'],
      );
    });

    test('une page de la direction : son domaine, puis son onglet', () {
      final List<SegmentFil> fil = ancetresFil(
        plan: admin,
        chemin: '${Routes.adminPedagogieBibliotheque}/nouveau',
      );
      expect(fil.first.chemin, Routes.adminPedagogie);
      expect(fil.last.chemin, Routes.adminPedagogieBibliotheque);
    });

    test('filAriane finit par la page courante, sans chemin', () {
      final List<SegmentFil> fil = filAriane(
        plan: tuteur,
        chemin: Routes.tcBibliotheque,
        titre: 'Bibliotheque',
      );
      expect(fil.last, const SegmentFil(libelle: 'Bibliotheque'));
    });

    test('sans role, aucun plan', () {
      expect(planFilPour(const SessionState(resolue: true)), isNull);
    });
  });

  group('PageShell sous un vrai routeur', () {
    final PlanFil plan = planFilPour(_session(AppRole.guardian))!;

    Widget app({TextDirection sens = TextDirection.ltr}) => ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          builder: (BuildContext _, Widget? enfant) => Directionality(
            textDirection: sens,
            child: ContexteFilAriane(plan: plan, child: enfant!),
          ),
          routerConfig: GoRouter(
            initialLocation: Routes.tuteurCompte,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.tuteurAccueil,
                builder: (BuildContext _, GoRouterState _) =>
                    const PageShell(titre: 'Accueil', child: SizedBox()),
              ),
              GoRoute(
                path: Routes.tuteurCompte,
                builder: (BuildContext contexte, GoRouterState _) => PageShell(
                  titre: 'Compte',
                  child: Builder(
                    builder: (BuildContext c) => TextButton(
                      onPressed: () => c.push(Routes.tcBibliotheque),
                      child: const Text('ouvrir'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: Routes.tcBibliotheque,
                builder: (BuildContext _, GoRouterState _) =>
                    const PageShell(titre: 'Bibliotheque', child: SizedBox()),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('bureau : Compte › Bibliotheque, Compte ramene au Compte', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      // Le Compte est une destination : pas de fil.
      expect(find.byKey(FilAriane.cleFil), findsNothing);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(FilAriane.cleFil), findsOneWidget);
      expect(
        find.text(t.nav.filAriane.suite(libelle: 'Bibliotheque')),
        findsOneWidget,
      );
      // Le fil est au-dessus du titre.
      expect(
        tester.getTopLeft(find.byKey(FilAriane.cleFil)).dy,
        lessThan(tester.getTopLeft(find.text('Bibliotheque')).dy),
      );
      await tester.tap(find.byKey(FilAriane.cleSegment(Routes.tuteurCompte)));
      await tester.pumpAndSettle();
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('telephone hors coquille : le disque retour revient', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(DisqueRetour), findsNothing);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(FilAriane.cleFil), findsNothing);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('telephone, adresse tapee : le retour mene a l\'accueil', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('ouvrir')))
          .go(Routes.tcBibliotheque);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('arabe : le fil se lit de droite a gauche', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(sens: TextDirection.rtl));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      final double compte = tester
          .getCenter(find.byKey(FilAriane.cleSegment(Routes.tuteurCompte)))
          .dx;
      final double page = tester
          .getCenter(find.text(t.nav.filAriane.suite(libelle: 'Bibliotheque')))
          .dx;
      expect(compte, greaterThan(page));
    });
  });
}
