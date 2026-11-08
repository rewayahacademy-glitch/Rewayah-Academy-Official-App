// FI-10 : Mes revenus de l'enseignant (/enseignant/revenus, guide Finance V4
// §1.4, §5.5, §8 F6 ; jeux F6 : plein, 80 %, minimum, essai dans la seance,
// finance absent, remplacement ; tableau a 1440 ; releve indisponible). Le
// chemin part de la VRAIE coquille enseignant (vrai routeur,
// `app_router.dart`) et de la demonstration ; les six etats ; le taux ne
// depasse jamais le plafond de la politique ; aucune donnee de famille ; 320
// a texte x2 et 1440 ; clair et sombre ; LTR et RTL.

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
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
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
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revenus_enseignant/entree_revenus.dart';
import 'package:rewayah_academy/features/revenus_enseignant/revenus_enseignant_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/demo_enseignant_page.dart';
import '../../support/demo/enseignant_demo.dart';
import '../../support/demo/finance_demo.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/mots_coupes.dart';

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

/// Deplie la Classe [classeId] (REVENUS, 07/11/2026) : la ligne se touche,
/// son detail s'ouvre dans la page.
Future<void> _deplierClasse(WidgetTester tester, String classeId) async {
  final Finder ligne = find.byKey(ValueKey<String>('revenus-classe-$classeId'));
  await tester.scrollUntilVisible(
    ligne,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(
    find.descendant(of: ligne, matching: find.byType(Pressable)).first,
  );
  await _attendre(tester);
}

/// Deplie chaque Classe rendue.
Future<void> _deplierToutes(WidgetTester tester, RevenusEnseignant r) async {
  final Set<String> ids = <String>{
    for (final RevenusClasse c in r.classes) c.classeId,
    for (final RevenusSeance s in r.seances) s.classeId,
  };
  for (final String id in ids) {
    await _deplierClasse(tester, id);
  }
}

/// Deplie « Comment c'est calcule ».
Future<void> _deplierCalcul(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(RevenusEnseignantPage.calculKey),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(RevenusEnseignantPage.calculKey));
  await _attendre(tester);
}

void main() {
  // Les vraies polices du depot pour tout le fichier : le tableau de bureau
  // se choisit sur la largeur mesuree des mots, que la police de test
  // (un carre par lettre) fausserait.
  setUpAll(chargerPolicesDuDepot);

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
      // Le profil (ENS-05) nomme les langues par le referentiel.
      referentielLanguesProvider.overrideWith(
        (Ref _) async => DonneesEnseignantDemo.languesCours,
      ),
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

    testWidgets('lot F1 : Aujourd\'hui, « Revenus estimés » ouvre la page, '
        'le retour ramene a Aujourd\'hui', (WidgetTester tester) async {
      final GoRouter routeur = await monter(tester);
      routeur.go(Routes.enseignantJournee);
      await _attendre(tester);
      final Finder lien = find.byKey(EntreeRevenus.cleLien);
      expect(lien, findsOneWidget);
      await tester.ensureVisible(lien);
      await _attendre(tester);
      await tester.tap(lien);
      await _attendre(tester);

      expect(
        routeur.routerDelegate.currentConfiguration.uri.toString(),
        Routes.enseignantRevenusDepuisJournee,
      );
      expect(find.byType(RevenusEnseignantPage), findsOneWidget);
      expect(find.byKey(RevenusEnseignantPage.indisponibleKey), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await _attendre(tester);
      expect(chemin(routeur), Routes.enseignantJournee);
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
      bool sessionALaRacine = true,
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
            if (sessionALaRacine) sansPersonneConnectee(),
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
      // Classe pleine, classe a 80 %, classe au minimum d'ouverture. Une
      // ligne par Classe : son nom et son montant ; le detail au toucher
      // (REVENUS, 07/11/2026).
      for (final RevenusClasse c in r.classes) {
        final Finder section = find.byKey(
          ValueKey<String>('revenus-classe-${c.classeId}'),
        );
        expect(section, findsOneWidget);
        Finder dans(String texte) =>
            find.descendant(of: section, matching: find.text(texte));
        expect(dans('Classe ${c.classe}'), findsOneWidget);
        expect(dans(formaterMontant(c.montantEstime)), findsOneWidget);
        expect(dans(t.enseignant.revenus.type), findsNothing);
        await _deplierClasse(tester, c.classeId);
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
            t.enseignant.revenus.tauxValeur(
              montant: formaterMontant(c.tauxHoraireEffectif),
            ),
          ),
          findsOneWidget,
        );
      }
      // REVENUS-VERITE (06/11/2026) : la regle en vigueur, sans base
      // garantie, sans occupation, sans plafond, sans sieges. « Comment
      // c'est calcule » est replie par defaut (REVENUS, 07/11/2026).
      expect(find.text(t.commun.paieEnseignant.present), findsNothing);
      await _deplierCalcul(tester);
      expect(find.text(t.enseignant.revenus.partielle), findsOneWidget);
      expect(find.text(t.commun.paieEnseignant.present), findsOneWidget);
      expect(find.text(t.commun.paieEnseignant.absent), findsOneWidget);
      expect(find.text(t.commun.paieEnseignant.minimum), findsOneWidget);
      expect(find.text(t.commun.paieEnseignant.absentDetail), findsOneWidget);
      for (final String faux in <String>[
        'garantie',
        'occupation',
        'Plafond',
        'éligible',
      ]) {
        expect(find.textContaining(faux), findsNothing, reason: faux);
      }
      // Aucun autre revenu attribue : aucune n'est inventee (REVENUS-VERITE
      // point 5), et la phrase reste neutre.
      expect(r.allocationInternet, isNull);
      expect(find.text(t.enseignant.revenus.autresVide), findsOneWidget);
      expect(find.textContaining('concerné'), findsNothing);
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
      // Plus aucun tableau, ni sur telephone ni sur bureau.
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

    testWidgets('releve de la demonstration : « pas encore disponible » meme '
        'sans session a la racine, jamais l\'etat d\'erreur (R5-03, '
        'FI-VAGUE-CORR)', (WidgetTester tester) async {
      // L'hote des captures ne fournit aucune session a la racine : le
      // releve doit se lire dans la portee de la demonstration, a son port.
      await monterDemo(
        tester,
        taille: const Size(1440, 1400),
        sessionALaRacine: false,
      );
      expect(
        find.text(t.enseignant.revenus.releveIndisponibleTitre),
        findsOneWidget,
      );
      final Iterable<EtatSysteme> etats = tester.widgetList<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(
        etats.map((EtatSysteme e) => e.nature),
        everyElement(isNot(NatureEtat.echecServeur)),
      );
    });

    testWidgets('hors ligne : le bandeau, et le contenu reste lisible', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, etat: EtatDemoEnseignant.horsLigne);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
    });

    testWidgets('1440 : une ligne par Classe, le detail au toucher, aucun '
        'tableau (REVENUS, 07/11/2026)', (WidgetTester tester) async {
      await monterDemo(tester, taille: const Size(1440, 1400));
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      expect(
        find.byKey(const ValueKey<String>('revenus-tableau')),
        findsNothing,
      );
      for (final RevenusClasse c in r.classes) {
        final Finder ligne = find.byKey(
          ValueKey<String>('revenus-classe-${c.classeId}'),
        );
        expect(ligne, findsOneWidget);
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(formaterMontant(c.montantEstime)),
          ),
          findsOneWidget,
        );
        final Semantics bouton = tester.widget<Semantics>(
          find
              .descendant(
                of: ligne,
                matching: find.byWidgetPredicate(
                  (Widget w) => w is Semantics && w.properties.expanded != null,
                ),
              )
              .first,
        );
        expect(bouton.properties.expanded, isFalse);
      }
      final RevenusClasse premiere = r.classes.first;
      await _deplierClasse(tester, premiere.classeId);
      expect(
        find.text(
          t.enseignant.revenus.capaciteValeur(nombre: premiere.capacite),
        ),
        findsOneWidget,
      );
      final PolitiqueCommerciale pol = DonneesFinanceDemo.politiqueLancement;
      expect(r.total.capacite, 2 * pol.capaciteEnfant + pol.capaciteAdulte);
      expect(r.total.minutesAssurees, 1320);
      // Plus aucune colonne « Sieges eligibles » (REVENUS-VERITE).
      expect(find.textContaining('éligible'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune donnee de famille : ni prenom, ni solde, ni paiement', (
      WidgetTester tester,
    ) async {
      await monterDemo(tester, taille: const Size(1440, 3000));
      await _deplierToutes(tester, DonneesFinanceDemo.revenus());
      expect(_prenomsFamille, isNotEmpty);
      // REVENUS-VERITE (point 3) : le prenom d'un eleve n'apparait que dans
      // le detail par seance de sa Classe, a cote de ce qu'il a rapporte ;
      // nulle part ailleurs (ni solde, ni paiement de sa famille).
      final Finder seances = find.byKey(
        const ValueKey<String>('revenus-detail'),
      );
      for (final String prenom in _prenomsFamille) {
        expect(
          find.textContaining(prenom).evaluate().length,
          find
              .descendant(of: seances, matching: find.textContaining(prenom))
              .evaluate()
              .length,
          reason: prenom,
        );
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
      Size taille = const Size(390, 1600),
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      await tester.pumpWidget(
        hoteCapture(
          RevenusEnseignantPage(onRetour: () {}),
          echelleTexte: echelle,
          surcharges: <Override>[
            sansPersonneConnectee(),
            serviceReseauProvider.overrideWithValue(
              FauxServiceReseau(horsLigneRendu: horsLigne),
            ),
            portRevenusEnseignantProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
    }

    // REVENUS-VERITE (pilote, 06/11/2026, point 2 : « un titre clair »)
    // remplace FI-Q16 (a) du 05/10 (« Revenus estimés », decide par
    // delegation) : « Mes revenus », sur l'ecran et la ligne du Profil ;
    // l'estimation reste dite par la pastille et la mention.
    testWidgets('REVENUS-VERITE : le titre est « Mes revenus », la pastille '
        'dit l estimation', (WidgetTester tester) async {
      await monterPage(tester, const RevenusEnseignantDemo());
      await _attendre(tester);
      expect(t.enseignant.revenus.titre, 'Mes revenus');
      expect(t.enseignant.profil.revenus, 'Mes revenus');
      expect(find.text('Mes revenus'), findsWidgets);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
    });

    testWidgets('FI-Q18 : le choix du mois propose les seuls mois rendus, '
        'relit le mois choisi et reste pose sur un mois vide', (
      WidgetTester tester,
    ) async {
      final _PortDeuxMois port = _PortDeuxMois();
      await monterPage(tester, port, taille: const Size(390, 2400));
      await _attendre(tester);
      final Finder selecteur = find.byKey(
        RevenusEnseignantPage.selecteurMoisKey,
      );
      expect(selecteur, findsOneWidget);
      expect(
        find.descendant(of: selecteur, matching: find.text('octobre 2026')),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
      expect(find.text(t.enseignant.revenus.intro), findsOneWidget);
      expect(find.text(t.enseignant.revenus.introSansChoix), findsNothing);
      await tester.tap(selecteur);
      await tester.pumpAndSettle();
      expect(find.text('septembre 2026'), findsOneWidget);
      expect(find.text('août 2026'), findsNothing);
      await tester.tap(find.text('septembre 2026'));
      await _attendre(tester);
      expect(port.demandes, <DateTime>[DateTime(2026, 9)]);
      // Septembre : aucune heure assuree, l'etat vide, le choix reste.
      expect(find.text(t.enseignant.revenus.vide), findsOneWidget);
      expect(selecteur, findsOneWidget);
      expect(
        find.descendant(of: selecteur, matching: find.text('septembre 2026')),
        findsOneWidget,
      );
    });

    testWidgets('FI-Q18 : production, aucun mois rendu, aucun choix pose', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, const RevenusEnseignantIndisponibles());
      await _attendre(tester);
      expect(find.byKey(RevenusEnseignantPage.selecteurMoisKey), findsNothing);
      // Sans choix, l'intro ne parle pas d'un « mois choisi » (contre-revue
      // FI-DIR-1).
      expect(find.text(t.enseignant.revenus.introSansChoix), findsOneWidget);
      expect(find.text(t.enseignant.revenus.intro), findsNothing);
    });

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
      // Lot F1 : un etat propre aux revenus, « pas encore publies », jamais
      // la phrase generique ni un chiffre.
      expect(find.byKey(RevenusEnseignantPage.indisponibleKey), findsOneWidget);
      expect(find.text(t.enseignant.revenus.indisponibleTitre), findsOneWidget);
      expect(
        find.text(t.enseignant.revenus.indisponiblePhrase),
        findsOneWidget,
      );
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
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('releve en echec : « Reessayer » relit le port', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      int lectures = 0;
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(base),
          lignes: () async {
            lectures++;
            if (lectures == 1) throw Exception('reseau');
            return <LigneReleve>[];
          },
        ),
      );
      await _attendre(tester);
      final Finder reessayer = find.text(t.commun.reessayer);
      await tester.scrollUntilVisible(reessayer, 200);
      expect(find.text(t.enseignant.revenus.releveVide), findsNothing);
      await tester.tap(reessayer);
      await _attendre(tester);
      expect(lectures, 2);
      expect(find.text(t.enseignant.revenus.releveVide), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('releve hors ligne : la section se dit hors ligne, la page '
        'garde son contenu', (WidgetTester tester) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      await monterPage(
        tester,
        _PortFige(
          Future<RevenusEnseignant>.value(base),
          lignes: () async => throw Exception('reseau'),
        ),
        horsLigne: true,
      );
      await _attendre(tester);
      expect(find.text(t.enseignant.revenus.estimation), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(t.enseignant.revenus.releveSection),
        200,
      );
      final Iterable<EtatSysteme> etats = find
          .byType(EtatSysteme, skipOffstage: false)
          .evaluate()
          .map((Element e) => e.widget as EtatSysteme);
      expect(etats, hasLength(1));
      expect(etats.single.nature, NatureEtat.horsLigne);
      expect(etats.single.onAction, isNotNull);
      await tester.pumpWidget(const SizedBox());
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
      expect(pastille, findsWidgets);
      await _deplierClasse(tester, 'demo-fi-classe-fajr');
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
      // La pastille « Remplacement » ne vit que dans la Classe du collegue :
      // les Classes titulaires n'en portent pas.
      expect(
        find.text(t.enseignant.revenus.remplacement).evaluate().length,
        find
            .descendant(
              of: ligne,
              matching: find.text(t.enseignant.revenus.remplacement),
            )
            .evaluate()
            .length,
      );
    });

    group('Mots entiers dans le detail sur bureau (vraies polices)', () {
      Finder detail() => find.byKey(const ValueKey<String>('revenus-detail'));

      for (final JeuRevenusEnseignant jeu in <JeuRevenusEnseignant>[
        JeuRevenusEnseignant.nominal,
        JeuRevenusEnseignant.remplacement,
      ]) {
        for (final double largeur in <double>[1200, 1440]) {
          for (final double echelle in <double>[1, 2]) {
            testWidgets('${jeu.name}, $largeur, texte x$echelle : chaque '
                'Classe depliee, aucun mot coupe', (WidgetTester tester) async {
              await monterPage(
                tester,
                RevenusEnseignantDemo(jeu: jeu),
                taille: Size(largeur, 6000),
                echelle: echelle,
              );
              await _attendre(tester);
              await _deplierToutes(
                tester,
                DonneesFinanceDemo.revenus(jeu: jeu),
              );
              expect(detail(), findsOneWidget);
              expect(motsCoupes(tester, detail()), isEmpty);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    });

    testWidgets('autres revenus : chaque ligne et le total rendus, a part de '
        'la paie des seances (REVENUS-VERITE point 5)', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant base = DonneesFinanceDemo.revenus();
      const Montant aide = Montant(1000, 'USD');
      const Montant mission = Montant(2500, 'USD');
      const Montant total = Montant(3500, 'USD');
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
              autres: const <AutreRevenu>[
                AutreRevenu(
                  id: 'a1',
                  nature: NatureAutreRevenu.aideInternet,
                  libelle: 'Aide Internet',
                  montant: aide,
                ),
                AutreRevenu(
                  id: 'a2',
                  nature: NatureAutreRevenu.mission,
                  libelle: 'Remplacement du 12',
                  montant: mission,
                ),
              ],
              totalAutres: total,
              allocationInternet: aide,
            ),
          ),
        ),
        taille: const Size(390, 4000),
      );
      await _attendre(tester);
      final Finder carte = find.byKey(const ValueKey<String>('revenus-autres'));
      expect(
        find.descendant(of: carte, matching: find.text('Remplacement du 12')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.commun.autresRevenus.mission),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(formaterMontant(mission)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: carte, matching: find.text(formaterMontant(total))),
        findsOneWidget,
      );
      expect(find.byKey(RevenusEnseignantPage.autresKey), findsOneWidget);
      expect(find.text(t.enseignant.revenus.autresVide), findsNothing);
      // Le total de la paie des seances ne change pas.
      expect(find.text(formaterMontant(base.totalEstime)), findsWidgets);
    });
  });

  group('Jeux F6 (guide §8 F6, R5-01)', () {
    RevenusClasse classe(RevenusEnseignant r, String id) =>
        r.classes.singleWhere((RevenusClasse c) => c.classeId == id);

    // REVENUS-VERITE (06/11/2026) : les jeux « sieges eligibles », « essai
    // dans la seance » et « eleve finance absent : il compte » verifiaient la
    // regle abandonnee le 18-19/10 (un absent finance compte, base et
    // plafond). Ils sont retires : un absent n'est jamais paye
    // (DECISION-TARIFS). Le detail par seance est verifie plus bas.
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

    test('taux horaire moyen rendu par la source : total sur heures '
        '(R5-05)', () {
      for (final JeuRevenusEnseignant jeu in JeuRevenusEnseignant.values) {
        final RevenusEnseignant r = DonneesFinanceDemo.revenus(jeu: jeu);
        expect(
          r.total.tauxHoraireMoyen.mineur,
          r.totalEstime.mineur * 60 ~/ r.total.minutesAssurees,
          reason: jeu.name,
        );
      }
      expect(DonneesFinanceDemo.revenus(vide: true).total.minutesAssurees, 0);
    });
  });

  group('Detail par seance et jour de paie (REVENUS-VERITE)', () {
    Future<void> monterPage(
      WidgetTester tester,
      PortRevenusEnseignant port,
    ) async {
      fixerVueCapture(tester, const Size(390, 4000), 1);
      await tester.pumpWidget(
        hoteCapture(
          RevenusEnseignantPage(onRetour: () {}),
          surcharges: <Override>[
            sansPersonneConnectee(),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            portRevenusEnseignantProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
    }

    testWidgets('chaque eleve, present ou absent, et ce qu il a rapporte ; '
        'le jour de paie ; les heures du mois', (WidgetTester tester) async {
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      await monterPage(tester, _PortFige(Future<RevenusEnseignant>.value(r)));
      await _attendre(tester);
      final RevenusSeance s = r.seances.first;
      final Finder seance = find.byKey(
        ValueKey<String>('revenus-seance-${s.seanceId}'),
      );
      // Le detail d'une seance vit dans sa Classe, depliee au toucher.
      expect(seance, findsNothing);
      await _deplierClasse(tester, s.classeId);
      expect(seance, findsOneWidget);
      for (final RevenusEleveSeance e in s.eleves) {
        final Finder ligne = find.byKey(
          ValueKey<String>('revenus-eleve-${s.seanceId}-${e.eleveId}'),
        );
        expect(
          find.descendant(of: ligne, matching: find.text(e.prenom)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(
              e.present
                  ? t.enseignant.revenus.present
                  : t.enseignant.revenus.absent,
            ),
          ),
          findsOneWidget,
        );
        // Une part pour un present ; aucun montant pour un absent, jamais
        // paye (REVENUS, 07/11/2026 : ni « 0 »).
        expect(tester.widget(ligne) is LigneFinance, e.present);
        if (e.present) {
          expect(
            find.descendant(
              of: ligne,
              matching: find.text(formaterMontant(e.montant!)),
            ),
            findsOneWidget,
          );
        }
      }
      final RevenusEleveSeance absent = s.eleves.firstWhere(
        (RevenusEleveSeance e) => !e.present,
      );
      expect(absent.montant!.mineur, 0);
      expect(
        find.descendant(
          of: seance,
          matching: find.text(t.enseignant.revenus.attenteCahier),
        ),
        findsOneWidget,
      );
      expect(find.byKey(RevenusEnseignantPage.versementKey), findsOneWidget);
      expect(find.byKey(RevenusEnseignantPage.heuresKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    /// La demonstration nominale, avec [seances] a la place des siennes.
    RevenusEnseignant avec(List<RevenusSeance> seances) {
      final RevenusEnseignant b = DonneesFinanceDemo.revenus();
      return RevenusEnseignant(
        debut: b.debut,
        fin: b.fin,
        classes: b.classes,
        total: b.total,
        totalEstime: b.totalEstime,
        seances: seances,
        versement: b.versement,
      );
    }

    RevenusSeance seance(
      String id,
      List<RevenusEleveSeance> eleves, {
      Montant? montant,
      bool? payable,
    }) {
      final RevenusClasse c = DonneesFinanceDemo.revenus().classes.first;
      return RevenusSeance(
        seanceId: id,
        debut: DateTime(2026, 10, 14, 18),
        classeId: c.classeId,
        classe: c.classe,
        type: c.type,
        minutes: 60,
        montant: montant,
        eleves: eleves,
        payable: payable,
      );
    }

    testWidgets('REVENUS : un eleve present en partie est dit tel, et paye '
        'comme un present', (WidgetTester tester) async {
      const Montant part = Montant(199, 'USD');
      final RevenusEnseignant r = avec(<RevenusSeance>[
        seance(
          's-partiel',
          const <RevenusEleveSeance>[
            RevenusEleveSeance(
              eleveId: 'e1',
              prenom: 'Lina',
              present: true,
              montant: part,
              presence: PresenceRevenus.partielle,
            ),
            RevenusEleveSeance(
              eleveId: 'e2',
              prenom: 'Omar',
              present: false,
              montant: Montant(0, 'USD'),
              presence: PresenceRevenus.absente,
            ),
          ],
          montant: part,
          payable: true,
        ),
      ]);
      await monterPage(tester, _PortFige(Future<RevenusEnseignant>.value(r)));
      await _attendre(tester);
      await _deplierClasse(tester, r.seances.single.classeId);
      final Finder lina = find.byKey(
        const ValueKey<String>('revenus-eleve-s-partiel-e1'),
      );
      expect(
        find.descendant(
          of: lina,
          matching: find.text(t.enseignant.revenus.presentPartiel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: lina, matching: find.text(formaterMontant(part))),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.revenus.partielleNote), findsOneWidget);
      // L'absent : aucun montant.
      expect(
        tester.widget(
          find.byKey(const ValueKey<String>('revenus-eleve-s-partiel-e2')),
        ),
        isNot(isA<LigneFinance>()),
      );
      expect(find.text(t.enseignant.revenus.nonPayee), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('REVENUS : une seance non payee n affiche aucun montant, ni 0 '
        'ni total, mais le dit', (WidgetTester tester) async {
      final RevenusEnseignant r = avec(<RevenusSeance>[
        seance(
          's-vide',
          const <RevenusEleveSeance>[
            RevenusEleveSeance(
              eleveId: 'e1',
              prenom: 'Lina',
              present: false,
              montant: Montant(0, 'USD'),
              presence: PresenceRevenus.absente,
            ),
          ],
          montant: const Montant(0, 'USD'),
          payable: false,
        ),
      ]);
      await monterPage(tester, _PortFige(Future<RevenusEnseignant>.value(r)));
      await _attendre(tester);
      await _deplierClasse(tester, r.seances.single.classeId);
      final Finder sec = find.byKey(
        const ValueKey<String>('revenus-seance-s-vide'),
      );
      expect(
        find.byKey(const ValueKey<String>('revenus-non-payee-s-vide')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sec, matching: find.byType(LigneFinance)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sec,
          matching: find.text(formaterMontant(const Montant(0, 'USD'))),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sec,
          matching: find.text(t.enseignant.revenus.montantSeance),
        ),
        findsNothing,
      );
    });

    test('REVENUS : un serveur plus ancien (sans presence ni payable) reste '
        'lisible : la presence et la paie se deduisent de « present »', () {
      final RevenusSeance s = seance('s-ancien', const <RevenusEleveSeance>[
        RevenusEleveSeance(
          eleveId: 'e1',
          prenom: 'Lina',
          present: true,
          montant: Montant(199, 'USD'),
        ),
        RevenusEleveSeance(
          eleveId: 'e2',
          prenom: 'Omar',
          present: false,
          montant: Montant(0, 'USD'),
        ),
      ], montant: const Montant(199, 'USD'));
      expect(s.payable, isTrue);
      expect(s.eleves.first.presence, PresenceRevenus.presente);
      expect(s.eleves.last.presence, PresenceRevenus.absente);
      expect(
        seance('s-vide', const <RevenusEleveSeance>[
          RevenusEleveSeance(
            eleveId: 'e1',
            prenom: 'Lina',
            present: false,
            montant: Montant(0, 'USD'),
          ),
        ]).payable,
        isFalse,
      );
      expect(
        PresenceRevenus.depuisJson('partielle'),
        PresenceRevenus.partielle,
      );
      expect(PresenceRevenus.depuisJson('inconnue'), isNull);
    });

    testWidgets('REVENUS : le total a recevoir, hors attentes ; ce qui attend '
        'le cahier sur une ligne a part ; chaque Classe a recevoir', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant b = DonneesFinanceDemo.revenus();
      final RevenusClasse c0 = b.classes.first;
      const Montant aRecevoir = Montant(314, 'USD');
      const Montant cahier = Montant(1194, 'USD');
      final RevenusEnseignant r = RevenusEnseignant(
        debut: b.debut,
        fin: b.fin,
        classes: <RevenusClasse>[
          RevenusClasse(
            classeId: c0.classeId,
            classe: c0.classe,
            type: c0.type,
            minutesAssurees: c0.minutesAssurees,
            capacite: c0.capacite,
            tauxHoraireEffectif: c0.tauxHoraireEffectif,
            montantEstime: const Montant(1508, 'USD'),
            montantARecevoir: aRecevoir,
          ),
        ],
        total: b.total,
        totalEstime: const Montant(1508, 'USD'),
        totalARecevoir: aRecevoir,
        totalAttenteCahier: cahier,
        versement: b.versement,
      );
      await monterPage(tester, _PortFige(Future<RevenusEnseignant>.value(r)));
      await _attendre(tester);
      expect(find.text(t.enseignant.revenus.aRecevoir), findsOneWidget);
      expect(find.text(t.enseignant.revenus.totalEstime), findsNothing);
      expect(
        find.text(
          t.enseignant.revenus.attenteCahierTotal(
            montant: formaterMontant(cahier),
          ),
        ),
        findsOneWidget,
      );
      // L'estimation brute (1 508) n'est plus le chiffre montre.
      expect(
        find.text(formaterMontant(const Montant(1508, 'USD'))),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('revenus-classe-${c0.classeId}')),
          matching: find.text(formaterMontant(aRecevoir)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('REVENUS : un serveur plus ancien (sans total a recevoir) '
        'garde l estimation, sans ligne du cahier', (
      WidgetTester tester,
    ) async {
      final RevenusEnseignant r = DonneesFinanceDemo.revenus();
      await monterPage(tester, _PortFige(Future<RevenusEnseignant>.value(r)));
      await _attendre(tester);
      expect(find.text(t.enseignant.revenus.totalEstime), findsOneWidget);
      expect(find.text(t.enseignant.revenus.aRecevoir), findsNothing);
      expect(find.byKey(RevenusEnseignantPage.attenteCahierKey), findsNothing);
    });

    test('la demonstration partage chaque seance entre ses presents', () {
      for (final RevenusSeance s in DonneesFinanceDemo.revenus().seances) {
        expect(
          s.eleves.fold<int>(
            0,
            (int a, RevenusEleveSeance e) => a + e.montant!.mineur,
          ),
          s.montant!.mineur,
        );
      }
    });
  });

  group('REVENUS-2 : chevron d une Classe depliee', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('${langue.languageCode} : deplie, il pointe vers le bas', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 1600), 1);
        await tester.pumpWidget(
          hoteCapture(
            RevenusEnseignantPage(onRetour: () {}),
            surcharges: <Override>[
              sansPersonneConnectee(),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              portRevenusEnseignantProvider.overrideWithValue(
                const RevenusEnseignantDemo(),
              ),
            ],
          ),
        );
        await _attendre(tester);
        final String id = DonneesFinanceDemo.revenus().classes.first.classeId;
        await _deplierClasse(tester, id);
        final AnimatedRotation rotation = tester.widget<AnimatedRotation>(
          find
              .descendant(
                of: find.byKey(ValueKey<String>('revenus-classe-$id')),
                matching: find.byType(AnimatedRotation),
              )
              .first,
        );
        // Le chevron pointe vers la fin de ligne : a droite en francais, a
        // gauche en arabe. Vers le bas : quart de tour horaire a droite,
        // antihoraire a gauche.
        expect(rotation.turns, langue == AppLocale.ar ? -0.25 : 0.25);
      });
    }
  });

  // Captures R3 REVENUS-2 (donnees de demonstration ; jamais sans
  // CAPTURE_DIR) : contenu (une Classe depliee : un eleve present en partie
  // et paye, un absent ; une seance non payee sans montant ; le total a
  // recevoir et l'attente du cahier a part), vide, panne, hors ligne.
  // Francais et arabe, 390 et 1440.
  group('Captures REVENUS-2', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);

    RevenusEnseignant contenu() {
      final RevenusEnseignant b = DonneesFinanceDemo.revenus();
      final RevenusClasse c = b.classes.first;
      const Montant part = Montant(199, 'USD');
      const Montant zero = Montant(0, 'USD');
      RevenusSeance seance(
        String id,
        int jour,
        List<RevenusEleveSeance> eleves, {
        Montant? montant,
        required bool payable,
        AttenteVersement? attente,
      }) => RevenusSeance(
        seanceId: id,
        debut: DateTime(2026, 10, jour, 18),
        classeId: c.classeId,
        classe: c.classe,
        type: c.type,
        minutes: 60,
        montant: montant,
        eleves: eleves,
        attente: attente,
        payable: payable,
      );
      return RevenusEnseignant(
        debut: b.debut,
        fin: b.fin,
        classes: <RevenusClasse>[
          RevenusClasse(
            classeId: c.classeId,
            classe: c.classe,
            type: c.type,
            minutesAssurees: 180,
            capacite: c.capacite,
            tauxHoraireEffectif: const Montant(133, 'USD'),
            montantEstime: const Montant(398, 'USD'),
            montantARecevoir: part,
          ),
        ],
        total: TotalRevenus(
          minutesAssurees: 180,
          capacite: b.total.capacite,
          tauxHoraireMoyen: const Montant(133, 'USD'),
        ),
        totalEstime: const Montant(398, 'USD'),
        totalARecevoir: part,
        totalAttenteCahier: part,
        seances: <RevenusSeance>[
          seance(
            's-1',
            7,
            const <RevenusEleveSeance>[
              RevenusEleveSeance(
                eleveId: 'e1',
                prenom: 'Lina',
                present: true,
                montant: part,
                presence: PresenceRevenus.partielle,
              ),
              RevenusEleveSeance(
                eleveId: 'e2',
                prenom: 'Omar',
                present: false,
                montant: zero,
                presence: PresenceRevenus.absente,
              ),
            ],
            montant: part,
            payable: true,
          ),
          seance(
            's-2',
            14,
            const <RevenusEleveSeance>[
              RevenusEleveSeance(
                eleveId: 'e1',
                prenom: 'Lina',
                present: true,
                montant: part,
                presence: PresenceRevenus.presente,
              ),
              RevenusEleveSeance(
                eleveId: 'e2',
                prenom: 'Omar',
                present: false,
                montant: zero,
                presence: PresenceRevenus.absente,
              ),
            ],
            montant: part,
            payable: true,
            attente: AttenteVersement.cahier,
          ),
          seance('s-3', 21, const <RevenusEleveSeance>[
            RevenusEleveSeance(
              eleveId: 'e1',
              prenom: 'Lina',
              present: false,
              montant: zero,
              presence: PresenceRevenus.absente,
            ),
            RevenusEleveSeance(
              eleveId: 'e2',
              prenom: 'Omar',
              present: false,
              montant: zero,
              presence: PresenceRevenus.absente,
            ),
          ], payable: false),
        ],
        versement: b.versement,
      );
    }

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final String etat in <String>[
          'contenu',
          'vide',
          'panne',
          'hors_ligne',
        ]) {
          final String nom =
              'revenus_${etat}_${langue.languageCode}_'
              '${taille.width.toInt()}x${taille.height.toInt()}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            final RevenusEnseignant r = contenu();
            final PortRevenusEnseignant port = switch (etat) {
              'contenu' => _PortFige(Future<RevenusEnseignant>.value(r)),
              'vide' => const RevenusEnseignantDemo(vide: true),
              _ => const _PortEnEchec(),
            };
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(
                RevenusEnseignantPage(onRetour: () {}),
                surcharges: <Override>[
                  sansPersonneConnectee(),
                  serviceReseauProvider.overrideWithValue(
                    FauxServiceReseau(horsLigneRendu: etat == 'hors_ligne'),
                  ),
                  portRevenusEnseignantProvider.overrideWithValue(port),
                ],
              ),
            );
            await _attendre(tester);
            if (etat == 'contenu') {
              await _deplierClasse(tester, r.classes.first.classeId);
              // Les seances de la Classe en haut de la vue.
              final BuildContext classe = tester.element(
                find.byKey(
                  ValueKey<String>(
                    'revenus-classe-${r.classes.first.classeId}',
                  ),
                ),
              );
              await tester.runAsync(
                () => Scrollable.ensureVisible(classe, alignment: 0),
              );
              await _attendre(tester);
            }
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturerVue(tester, nom)}');
          });
        }
      }
    }
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
  Future<RevenusEnseignant> duMois(DateTime mois) => reponse;

  @override
  Future<List<DateTime>> moisDisponibles() =>
      Future<List<DateTime>>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<List<LigneReleve>> releve() =>
      lignes?.call() ??
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Deux mois rendus : octobre (le jeu nominal) et septembre (aucune heure
/// assuree) ; les mois demandes sont gardes.
class _PortDeuxMois implements PortRevenusEnseignant {
  _PortDeuxMois();

  final List<DateTime> demandes = <DateTime>[];

  @override
  Future<RevenusEnseignant> moisEnCours() async => DonneesFinanceDemo.revenus();

  @override
  Future<RevenusEnseignant> duMois(DateTime mois) async {
    demandes.add(mois);
    return DonneesFinanceDemo.revenus(vide: mois.month == 9);
  }

  @override
  Future<List<DateTime>> moisDisponibles() async => <DateTime>[
    DateTime(2026, 10),
    DateTime(2026, 9),
  ];

  @override
  Future<List<LigneReleve>> releve() =>
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Un port qui echoue a chaque lecture, comme un reseau qui refuse.
class _PortEnEchec implements PortRevenusEnseignant {
  const _PortEnEchec();

  @override
  Future<RevenusEnseignant> moisEnCours() async => throw Exception('reseau');

  @override
  Future<RevenusEnseignant> duMois(DateTime mois) async =>
      throw Exception('reseau');

  @override
  Future<List<DateTime>> moisDisponibles() async => throw Exception('reseau');

  @override
  Future<List<LigneReleve>> releve() async => throw Exception('reseau');
}
