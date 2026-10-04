// FI-10 : Mes revenus de l'enseignant (/enseignant/revenus, guide Finance V4
// §1.4, §5.5, §8 F6). Le chemin part de la VRAIE coquille enseignant (vrai
// routeur, `app_router.dart`) et de la demonstration ; les six etats ;
// le taux ne depasse jamais le plafond de la politique ; aucune donnee de
// famille ; 320 a texte x2 et 1440 ; clair et sombre ; LTR et RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revenus_enseignant/revenus_enseignant_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Les prenoms des profils du foyer de demonstration Finance : aucun ne
/// s'affiche chez l'enseignant (guide §5.5).
final List<String> _prenomsFamille = <String>[
  for (final FinancesProfil p in DonneesFinanceDemo.profils(
    JeuFoyerFinance.cinqProfils,
  ))
    p.prenom,
];

/// Le vocabulaire d'un solde ou d'un paiement de famille.
const List<String> _motsFamille = <String>[
  'olde',
  'payé',
  'Payé',
  'arif',
  'emise',
  'ensualit',
  'financer',
  'Foyer',
  'foyer',
];

Future<void> _attendre(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Chemin depuis la vraie coquille enseignant', () {
    List<Override> surcharges({PortRevenusEnseignant? port}) => <Override>[
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          const SessionState(
            resolue: true,
            role: AppRole.teacher,
            profileId: 'ens-1',
            householdId: 'h1',
            accountStatus: AccountStatus.active,
            lectureProfil: LectureProfil.presente,
          ),
        ),
      ),
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
      servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
      serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
      serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
      servicePriereProvider.overrideWithValue(FauxServicePriere()),
      profilEnseignantProvider.overrideWith(
        (Ref _) async => DonneesEnseignantDemo.profil,
      ),
      if (port != null) portRevenusEnseignantProvider.overrideWithValue(port),
    ];

    Future<GoRouter> monter(
      WidgetTester tester, {
      PortRevenusEnseignant? port,
    }) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      late GoRouter routeur;
      await tester.pumpWidget(
        ProviderScope(
          overrides: surcharges(port: port),
          child: TranslationProvider(
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? _) {
                routeur = ref.read(routeurProvider);
                routeur.go(Routes.enseignantProfil);
                return MaterialApp.router(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  routerConfig: routeur,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return routeur;
    }

    Future<void> ouvrir(WidgetTester tester) async {
      final Finder ligne = find.text(t.enseignant.profil.revenus);
      await tester.ensureVisible(ligne);
      await tester.pumpAndSettle();
      await tester.tap(ligne);
      await _attendre(tester);
    }

    // Une pose ouverte par `push` est la derniere correspondance de la pile.
    String chemin(GoRouter r) =>
        r.routerDelegate.currentConfiguration.last.matchedLocation;

    testWidgets('Profil, « Mes revenus » : la page, sous la barre, '
        'indisponible en production', (WidgetTester tester) async {
      final GoRouter routeur = await monter(tester);
      expect(find.byType(ProfilEnseignantPage), findsOneWidget);
      await ouvrir(tester);

      expect(chemin(routeur), Routes.enseignantRevenus);
      expect(find.byType(RevenusEnseignantPage), findsOneWidget);
      expect(find.byType(NavShell), findsOneWidget);
      // Le port de production est neutre : « indisponible », sans
      // « Reessayer » ni chiffre invente.
      final EtatSysteme etat =
          find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
      expect(etat.nature, NatureEtat.indisponible);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.text(t.enseignant.revenus.estimation), findsNothing);
    });

    testWidgets('avec une source, le contenu ; le retour ramene au Profil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        port: const RevenusEnseignantDemo(),
      );
      await ouvrir(tester);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
      expect(find.text('Classe An-Nour'), findsOneWidget);

      routeur.pop();
      await tester.pumpAndSettle();
      expect(chemin(routeur), Routes.enseignantProfil);
    });
  });

  group('Demonstration enseignant', () {
    Future<void> monterDemo(
      WidgetTester tester, {
      EcranDemoEnseignant ecran = EcranDemoEnseignant.revenus,
      EtatDemoEnseignant etat = EtatDemoEnseignant.nominal,
      Size taille = const Size(390, 2400),
      double echelle = 1,
      ThemeMode theme = ThemeMode.light,
      TextDirection sens = TextDirection.ltr,
    }) async {
      fixerVueCapture(tester, taille, 1);
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoEnseignant(ecran, etat: etat),
        routes: routesDemoEnseignant('staging'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: theme,
              routerConfig: routeur,
              builder: (BuildContext context, Widget? app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(textDirection: sens, child: app!),
              ),
            ),
          ),
        ),
      );
      await _attendre(tester);
    }

    testWidgets('Profil de la demonstration, « Mes revenus » ouvre la page', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, ecran: EcranDemoEnseignant.profil);
      final Finder ligne = find.text(t.enseignant.profil.revenus);
      await tester.ensureVisible(ligne);
      await _attendre(tester);
      await tester.tap(ligne);
      await _attendre(tester);
      expect(find.byType(RevenusEnseignantPage), findsOneWidget);
      expect(find.byType(NavShell), findsOneWidget);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
    });

    testWidgets('contenu : estimation marquee, les trois Classes du jeu F6, '
        'l explication en trois temps', (WidgetTester tester) async {
      await monterDemo(tester);
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();

      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
      expect(find.text(t.enseignant.revenus.mention), findsOneWidget);
      expect(find.text(formaterMontant(r.totalEstime)), findsOneWidget);
      // Classe pleine, classe a 80 %, classe au minimum d'ouverture.
      for (final RevenusClasse c in r.classes) {
        final Finder section = find.byKey(
          ValueKey<String>('revenus-classe-${c.classeId}'),
        );
        expect(section, findsOneWidget);
        Finder dans(String texte) =>
            find.descendant(of: section, matching: find.text(texte));
        expect(dans('Classe ${c.classe}'), findsOneWidget);
        expect(
          dans(t.enseignant.revenus.capaciteValeur(nombre: c.capacite)),
          findsOneWidget,
        );
        expect(
          dans(
            t.enseignant.revenus.siegesValeur(
              nombre: c.siegesEligibles,
              capacite: c.capacite,
            ),
          ),
          findsOneWidget,
        );
        expect(
          dans(
            t.enseignant.revenus.tauxValeur(
              montant: formaterMontant(c.tauxHoraireEffectif),
            ),
          ),
          findsOneWidget,
        );
        expect(dans(formaterMontant(c.montantEstime)), findsOneWidget);
      }
      expect(
        r.classes.map((RevenusClasse c) => c.siegesEligibles).toList(),
        <int>[5, 4, 4],
      );
      expect(find.text(t.enseignant.revenus.base), findsOneWidget);
      expect(find.text(t.enseignant.revenus.occupation), findsOneWidget);
      expect(find.text(t.enseignant.revenus.plafond), findsOneWidget);
      expect(
        find.text(
          t.enseignant.revenus.plafondDetail(
            plafond: formaterMontant(r.plafondHoraire),
          ),
        ),
        findsOneWidget,
      );
      // La politique ne fixe pas d'aide Internet : aucune n'est inventee.
      expect(r.allocationInternet, isNull);
      expect(find.text(t.enseignant.revenus.internetNon), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      expect(
        verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard),
        greaterThanOrEqualTo(3),
      );
    });

    testWidgets('vide : aucune heure assuree, pas de total a zero', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, etat: EtatDemoEnseignant.vide);
      expect(find.text(t.enseignant.revenus.vide), findsOneWidget);
      expect(find.text(t.enseignant.revenus.totalEstime), findsNothing);
    });

    testWidgets('hors ligne : le bandeau, et le contenu reste lisible', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, etat: EtatDemoEnseignant.horsLigne);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
    });

    testWidgets('aucune donnee de famille : ni prenom, ni solde, ni paiement', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, taille: const Size(1440, 1400));
      expect(_prenomsFamille, isNotEmpty);
      for (final String prenom in _prenomsFamille) {
        expect(find.textContaining(prenom), findsNothing, reason: prenom);
      }
      for (final String mot in _motsFamille) {
        expect(find.textContaining(mot), findsNothing, reason: mot);
      }
    });

    for (final (String nom, Size taille, double echelle)
        in <(String, Size, double)>[
          ('320 texte x2', const Size(320, 6000), 2),
          ('1440', const Size(1440, 1400), 1),
        ]) {
      for (final TextDirection sens in TextDirection.values) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('$nom, ${sens.name}, ${theme.name} : sans debordement', (
            WidgetTester tester,
          ) async {
            await monterDemo(
              tester,
              taille: taille,
              echelle: echelle,
              sens: sens,
              theme: theme,
            );
            expect(tester.takeException(), isNull);
            expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
            expect(find.text('Classe As-Salam'), findsOneWidget);
          });
        }
      }
    }
  });

  group('Etats de la page', () {
    Future<void> monterPage(
      WidgetTester tester,
      PortRevenusEnseignant port,
    ) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(
        hoteCapture(
          RevenusEnseignantPage(onRetour: () {}),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            portRevenusEnseignantProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
    }

    testWidgets('chargement : le squelette, aucun chiffre', (
      WidgetTester tester,
    ) async {
      final Completer<RevenusEnseignant> attente =
          Completer<RevenusEnseignant>();
      await monterPage(tester, _PortFige(attente.future));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.enseignant.revenus.estimation), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un echec qui se reessaye', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, const _PortEnEchec());
      await _attendre(tester);
      final EtatSysteme etat =
          find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('indisponible : le port de production, sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, const RevenusEnseignantIndisponibles());
      await _attendre(tester);
      final EtatSysteme etat =
          find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
      expect(etat.nature, NatureEtat.indisponible);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('aide Internet : a part, une seule ligne, hors total', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      const Montant aide = Montant(1000, 'USD');
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(
            RevenusEnseignant(
              debut: base.debut,
              fin: base.fin,
              classes: base.classes,
              totalEstime: base.totalEstime,
              baseHoraire: base.baseHoraire,
              plafondHoraire: base.plafondHoraire,
              allocationInternet: aide,
            ),
          ),
        ),
      );
      await _attendre(tester);
      expect(find.text(t.enseignant.revenus.internet), findsOneWidget);
      expect(find.text(formaterMontant(aide)), findsOneWidget);
      expect(find.text(t.enseignant.revenus.internetNon), findsNothing);
      // Le total reste celui de la remuneration pedagogique.
      expect(find.text(formaterMontant(base.totalEstime)), findsOneWidget);
    });
  });

  group('Taux plafonne (guide §1.4, §8 F6)', () {
    test('chaque taux de la demonstration reste sous le plafond de 7 USD', () {
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      expect(
        r.plafondHoraire,
        DonneesFinanceDemo.politiqueLancement.plafondHoraire,
      );
      expect(r.plafondHoraire.mineur, 700);
      expect(r.classes, hasLength(3));
      for (final RevenusClasse c in r.classes) {
        expect(c.tauxHoraireEffectif.mineur, lessThanOrEqualTo(700));
        expect(
          c.tauxHoraireEffectif.mineur,
          greaterThanOrEqualTo(r.baseHoraire.mineur),
        );
        expect(c.siegesEligibles, lessThanOrEqualTo(c.capacite));
      }
      // La classe pleine atteint le plafond, jamais au-dela.
      expect(r.classes.first.tauxHoraireEffectif.mineur, 700);
    });

    test('au-dela de la capacite, le taux reste au plafond', () {
      for (int sieges = 0; sieges <= 12; sieges++) {
        final Montant taux = DonneesFinanceDemo.tauxEffectif(
          siegesEligibles: sieges,
          capacite: 5,
        );
        expect(taux.mineur, lessThanOrEqualTo(700), reason: '$sieges');
      }
    });
  });
}

/// Un port qui rend la reponse donnee.
class _PortFige implements PortRevenusEnseignant {
  const _PortFige(this.reponse);

  final Future<RevenusEnseignant> reponse;

  @override
  Future<RevenusEnseignant> moisEnCours() => reponse;
}

/// Un port qui echoue a chaque lecture, comme un reseau qui refuse.
class _PortEnEchec implements PortRevenusEnseignant {
  const _PortEnEchec();

  @override
  Future<RevenusEnseignant> moisEnCours() async => throw Exception('reseau');
}
