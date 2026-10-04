// FI-10 : Mes revenus de l'enseignant (/enseignant/revenus, guide Finance V4
// §1.4, §5.5, §8 F6 ; jeux F6 : plein, 80 %, minimum, essai dans la seance,
// finance absent, remplacement ; tableau a 1440 ; releve indisponible). Le chemin part de la VRAIE coquille enseignant (vrai
// routeur, `app_router.dart`) et de la demonstration ; les six etats ;
// le taux ne depasse jamais le plafond de la politique ; aucune donnee de
// famille ; 320 a texte x2 et 1440 ; clair et sombre ; LTR et RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
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
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
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
          dans(
            c.type == TypeClasseRevenus.adultes
                ? t.enseignant.revenus.typeAdultes
                : t.enseignant.revenus.typeEnfants,
          ),
          findsOneWidget,
        );
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
      expect(find.text(t.enseignant.revenus.internetAucune), findsOneWidget);
      // Un libelle neutre : rien ne dit que l'enseignant n'est pas concerne.
      expect(
        t.enseignant.revenus.internetAucune,
        "Aucune aide Internet n'est prévue ce mois-ci.",
      );
      expect(find.textContaining('concerné'), findsNothing);
      // Les sieges : le nombre du mois tel que la source le rend, et leur
      // definition dite une seule fois, sous « Detail par Classe » (R5-06).
      expect(
        t.enseignant.revenus.siegesDetail,
        contains('Nombre retenu pour le mois'),
      );
      expect(find.text(t.enseignant.revenus.siegesDetail), findsOneWidget);
      // La synthese : le taux horaire moyen rendu par le port (R5-05), et
      // chaque valeur alignee en fin de ligne (R5-08).
      expect(
        find.text(
          t.enseignant.revenus.tauxValeur(
            montant: formaterMontant(r.total.tauxHoraireMoyen),
          ),
        ),
        findsOneWidget,
      );
      final Iterable<LigneCleValeur> lignes = tester.widgetList<LigneCleValeur>(
        find.byType(LigneCleValeur),
      );
      expect(lignes, isNotEmpty);
      for (final LigneCleValeur l in lignes) {
        expect(l.valeurEnFin, isTrue, reason: l.cle);
      }
      // Le telephone groupe les lignes : aucun tableau.
      expect(
        find.byKey(const ValueKey<String>('revenus-tableau')),
        findsNothing,
      );
      // Le releve : indisponible, dit dans sa section, jamais « Paye » (R5-03).
      expect(find.text(t.enseignant.revenus.releveSection), findsOneWidget);
      expect(
        find.text(t.enseignant.revenus.releveIndisponibleTitre),
        findsOneWidget,
      );
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

    testWidgets('1440 : tableau compact, type par Classe, ligne de total '
        'rendue par le port (R5-02)', (WidgetTester tester) async {
      await monterDemo(tester, taille: const Size(1440, 1400));
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      final Finder tableau = find.byKey(
        const ValueKey<String>('revenus-tableau'),
      );
      expect(tableau, findsOneWidget);
      Finder dans(Finder ou, String texte) =>
          find.descendant(of: ou, matching: find.text(texte));
      for (final String titre in <String>[
        t.enseignant.revenus.classeColonne,
        t.enseignant.revenus.type,
        t.enseignant.revenus.capacite,
        t.enseignant.revenus.sieges,
        t.enseignant.revenus.tauxColonne,
        t.enseignant.revenus.montantClasse,
      ]) {
        expect(dans(tableau, titre), findsOneWidget, reason: titre);
      }
      for (final RevenusClasse c in r.classes) {
        final Finder ligne = find.byKey(
          ValueKey<String>('revenus-classe-${c.classeId}'),
        );
        expect(find.descendant(of: tableau, matching: ligne), findsOneWidget);
        expect(dans(ligne, '${c.capacite}'), findsOneWidget);
        expect(dans(ligne, formaterMontant(c.montantEstime)), findsOneWidget);
      }
      expect(dans(tableau, t.enseignant.revenus.typeAdultes), findsOneWidget);
      expect(dans(tableau, t.enseignant.revenus.typeEnfants), findsNWidgets(2));
      final Finder total = find.byKey(const ValueKey<String>('revenus-total'));
      expect(dans(total, t.enseignant.revenus.total), findsOneWidget);
      expect(dans(total, '${r.total.capacite}'), findsOneWidget);
      expect(
        dans(
          total,
          t.enseignant.revenus.siegesValeur(
            nombre: r.total.siegesEligibles,
            capacite: r.total.capacite,
          ),
        ),
        findsOneWidget,
      );
      expect(
        dans(total, formaterMontant(r.total.tauxHoraireMoyen)),
        findsOneWidget,
      );
      expect(dans(total, formaterMontant(r.totalEstime)), findsOneWidget);
      expect(r.total.capacite, 16);
      expect(r.total.siegesEligibles, 13);
      expect(r.total.minutesAssurees, 1320);
      // La definition des sieges, une seule fois aussi sur bureau.
      expect(find.text(t.enseignant.revenus.siegesDetail), findsOneWidget);
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
      PortRevenusEnseignant port, {
      bool horsLigne = false,
    }) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(
        hoteCapture(
          RevenusEnseignantPage(onRetour: () {}),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(
              FauxServiceReseau(horsLigneRendu: horsLigne),
            ),
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

    testWidgets('hors ligne : un echec sans reseau se dit hors ligne', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, const _PortEnEchec(), horsLigne: true);
      await _attendre(tester);
      final EtatSysteme etat =
          find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
      expect(etat.nature, NatureEtat.horsLigne);
      expect(etat.onAction, isNotNull);
    });

    testWidgets('hors ligne : une capacite absente reste indisponible', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        const RevenusEnseignantIndisponibles(),
        horsLigne: true,
      );
      await _attendre(tester);
      final EtatSysteme etat =
          find.byType(EtatSysteme).evaluate().single.widget as EtatSysteme;
      expect(etat.nature, NatureEtat.indisponible);
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

    testWidgets('releve rendu : les mois arretes, sans statut « Paye »', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      final LigneReleve mois = LigneReleve(
        mois: DateTime(2026, 9),
        minutesAssurees: 1200,
        montant: const Montant(14000, 'USD'),
      );
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(base),
          lignes: () => Future<List<LigneReleve>>.value(<LigneReleve>[mois]),
        ),
      );
      await _attendre(tester);
      await tester.scrollUntilVisible(
        find.text(formaterMontant(mois.montant)),
        200,
      );
      expect(
        find.text(
          t.enseignant.revenus.periode(
            mois: t.commun.dates.mois[8],
            annee: 2026,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('ayé'), findsNothing);
      expect(
        find.text(t.enseignant.revenus.releveIndisponibleTitre),
        findsNothing,
      );
    });

    testWidgets('releve vide, puis en echec qui se reessaye', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(base),
          lignes: () => Future<List<LigneReleve>>.value(<LigneReleve>[]),
        ),
      );
      await _attendre(tester);
      expect(find.text(t.enseignant.revenus.releveVide), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(base),
          lignes: () async => throw Exception('reseau'),
        ),
      );
      await _attendre(tester);
      // La page garde son contenu, seul le releve echoue.
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('remplacement : la Classe du collegue, marquee comme telle', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        const RevenusEnseignantDemo(jeu: JeuRevenusEnseignant.remplacement),
      );
      await _attendre(tester);
      final Finder ligne = find.byKey(
        const ValueKey<String>('revenus-classe-demo-fi-classe-fajr'),
      );
      await tester.scrollUntilVisible(ligne, 200);
      final Finder pastille = find.descendant(
        of: ligne,
        matching: find.byType(StatusPill),
      );
      expect(pastille, findsOneWidget);
      expect(
        find.descendant(
          of: ligne,
          matching: find.text(t.enseignant.revenus.remplacement),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: ligne,
          matching: find.text(t.enseignant.revenus.typeDebutants),
        ),
        findsOneWidget,
      );
      // Une seule pastille « Remplacement » : les Classes titulaires n'en
      // portent pas.
      expect(find.text(t.enseignant.revenus.remplacement), findsOneWidget);
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
              total: base.total,
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
      expect(find.text(t.enseignant.revenus.internetAucune), findsNothing);
      // Le total reste celui de la remuneration pedagogique.
      expect(find.text(formaterMontant(base.totalEstime)), findsOneWidget);
    });
  });

  group('Jeux F6 (guide §8 F6, R5-01)', () {
    RevenusClasse classe(RevenusEnseignant r, String id) =>
        r.classes.singleWhere((RevenusClasse c) => c.classeId == id);

    test('sieges eligibles : finance present ou absent, essai present ; '
        'ni essai absent ni place vide ; jamais au-dela de la capacite', () {
      expect(
        DonneesFinanceDemo.siegesEligibles(<SiegeSeance>[
          SiegeSeance.financePresent,
          SiegeSeance.financeAbsent,
          SiegeSeance.essaiPresent,
          SiegeSeance.essaiAbsent,
          SiegeSeance.placeVide,
        ], capacite: 5),
        3,
      );
      expect(
        DonneesFinanceDemo.siegesEligibles(<SiegeSeance>[
          for (int i = 0; i < 7; i++) SiegeSeance.financePresent,
        ], capacite: 5),
        5,
      );
    });

    test('essai dans la seance : l eleve en essai present compte', () {
      final RevenusEnseignant nominal = DonneesFinanceDemo.revenus();
      final RevenusEnseignant essai = DonneesFinanceDemo.revenus(
        jeu: JeuRevenusEnseignant.essaiDansLaSeance,
      );
      final RevenusClasse avant = classe(nominal, 'demo-fi-classe-huda');
      final RevenusClasse apres = classe(essai, 'demo-fi-classe-huda');
      expect(avant.siegesEligibles, 4);
      expect(apres.siegesEligibles, 5);
      expect(apres.tauxHoraireEffectif.mineur, 700);
      expect(
        apres.montantEstime.mineur,
        greaterThan(avant.montantEstime.mineur),
      );
    });

    test('eleve finance absent : il compte, rien n est perdu', () {
      final RevenusEnseignant nominal = DonneesFinanceDemo.revenus();
      final RevenusEnseignant absent = DonneesFinanceDemo.revenus(
        jeu: JeuRevenusEnseignant.financeAbsent,
      );
      final RevenusClasse avant = classe(nominal, 'demo-fi-classe-nour');
      final RevenusClasse apres = classe(absent, 'demo-fi-classe-nour');
      expect(apres.siegesEligibles, avant.siegesEligibles);
      expect(apres.siegesEligibles, apres.capacite);
      expect(apres.montantEstime, avant.montantEstime);
      expect(absent.totalEstime, nominal.totalEstime);
    });

    test('remplacement : la seance est payee a qui l assure, au taux de '
        'la Classe, sans toucher aux Classes titulaires', () {
      final RevenusEnseignant nominal = DonneesFinanceDemo.revenus();
      final RevenusEnseignant r = DonneesFinanceDemo.revenus(
        jeu: JeuRevenusEnseignant.remplacement,
      );
      expect(r.classes, hasLength(nominal.classes.length + 1));
      final RevenusClasse fajr = classe(r, 'demo-fi-classe-fajr');
      expect(fajr.enRemplacement, isTrue);
      expect(fajr.type, TypeClasseRevenus.debutants);
      expect(
        fajr.capacite,
        DonneesFinanceDemo.politiqueLancement.capaciteDebutant,
      );
      expect(fajr.minutesAssurees, 60);
      expect(fajr.siegesEligibles, 3);
      expect(fajr.montantEstime.mineur, fajr.tauxHoraireEffectif.mineur);
      expect(
        r.classes.where((RevenusClasse c) => c.enRemplacement),
        hasLength(1),
      );
      expect(
        r.totalEstime.mineur,
        nominal.totalEstime.mineur + fajr.montantEstime.mineur,
      );
      expect(r.total.minutesAssurees, nominal.total.minutesAssurees + 60);
    });

    test('la vue globale ne lit que le jeu nominal', () {
      expect(
        DonneesFinanceDemo.vueGlobale().paieEnseignants,
        DonneesFinanceDemo.revenus().totalEstime,
      );
    });

    test('taux horaire moyen rendu par la source : total sur heures, '
        'entre la base et le plafond (R5-05)', () {
      for (final JeuRevenusEnseignant jeu in JeuRevenusEnseignant.values) {
        final RevenusEnseignant r = DonneesFinanceDemo.revenus(jeu: jeu);
        expect(
          r.total.tauxHoraireMoyen.mineur,
          r.totalEstime.mineur * 60 ~/ r.total.minutesAssurees,
          reason: jeu.name,
        );
        expect(r.total.tauxHoraireMoyen.mineur, lessThanOrEqualTo(700));
        expect(
          r.total.tauxHoraireMoyen.mineur,
          greaterThanOrEqualTo(r.baseHoraire.mineur),
        );
      }
      expect(DonneesFinanceDemo.revenus(vide: true).total.minutesAssurees, 0);
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

/// Un port qui rend la reponse donnee ; le releve, indisponible sauf
/// [lignes].
class _PortFige implements PortRevenusEnseignant {
  const _PortFige(this.reponse, {this.lignes});

  final Future<RevenusEnseignant> reponse;

  final Future<List<LigneReleve>> Function()? lignes;

  @override
  Future<RevenusEnseignant> moisEnCours() => reponse;

  @override
  Future<List<LigneReleve>> releve() =>
      lignes?.call() ??
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Un port qui echoue a chaque lecture, comme un reseau qui refuse.
class _PortEnEchec implements PortRevenusEnseignant {
  const _PortEnEchec();

  @override
  Future<RevenusEnseignant> moisEnCours() async => throw Exception('reseau');

  @override
  Future<List<LigneReleve>> releve() async => throw Exception('reseau');
}
