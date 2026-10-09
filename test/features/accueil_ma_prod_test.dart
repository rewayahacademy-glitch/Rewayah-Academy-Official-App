// DASH-MA-PROD : l'Accueil du Mode Accessibilite hors demonstration, et
// l'aide de l'eleve sur sa vraie route.
//
// Depuis la VRAIE navigation (K-07) : l'application monte sur son routeur
// (`routeurProvider`), la session est celle d'un eleve dont la presentation
// est le Mode Accessibilite ; il ouvre l'application et arrive sur
// l'Accueil du mode, a `/eleve`. Port neutre de production : l'ecran dit
// « pas encore disponible », sans prenom ni Classe de remplacement (D10).
// Chaque etat (D11) est atteignable, sur la route reelle (port surcharge)
// et sur la route de demonstration (`?accueil=`). L'aide s'ouvre par
// `/eleve/aide`. Aucun mot coupe a 320 px texte x2 et a 1440, LTR et RTL.
//
// Contre-epreuve : sur l'ancien code, `/eleve` rendait `AccueilElevePage`
// quelle que soit la presentation, et `/eleve/aide` n'existait pas.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../router/support_routeur.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/garde_interface.dart' show verifierUnSeulBoutonPlein;
import '../support/harnais.dart';

/// Un port qui echoue d'abord, puis rend la Classe : « Reessayer » relance.
class _PortEchecPuisContenu implements PortAccueilAccessibilite {
  int lectures = 0;

  @override
  Future<DonneesAccueilAccessibilite> lire() {
    lectures++;
    if (lectures == 1) {
      return Future<DonneesAccueilAccessibilite>.error(StateError('reseau'));
    }
    return const PortAccueilAccessibiliteDemo(
      eleve: EleveDemoAccessibilite.mariam,
    ).lire();
  }
}

/// Monte l'application sur son vrai routeur, session eleve en [mode].
Future<GoRouter> _monter(
  WidgetTester tester, {
  InterfaceMode mode = InterfaceMode.enfant,
  PortAccueilAccessibilite? port,
  bool horsLigne = false,
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
        ),
        if (port != null)
          portAccueilAccessibiliteProvider.overrideWithValue(port),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(mode, Brightness.light),
              routerConfig: routeur,
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(textDirection: sens, child: app!),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  return routeur;
}

/// Monte la route de demonstration sur une situation de l'Accueil.
Future<void> _monterDemo(
  WidgetTester tester,
  SituationAccueilDemo situation,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation:
        '${Routes.demoAccessibilite}?eleve=mariam&moment=avant'
        '&accueil=${situation.name}',
    routes: routesDemoAccessibilite('local'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: routeur,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Finder get _salutation => find.textContaining('As-salāmu');

void _coranEtAideRestent() {
  expect(find.text(t.accessibilite.accueil.lireCoran), findsOneWidget);
  expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
}

void main() {
  group('K-07 : l eleve en Mode Accessibilite ouvre l application', () {
    testWidgets('il arrive sur l Accueil du mode, a /eleve, hors '
        'demonstration ; port neutre : « pas encore disponible »', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      expect(lieu(routeur), Routes.eleve);
      expect(find.byType(AccueilAccessibilite), findsOneWidget);
      expect(find.byType(AccueilElevePage), findsNothing);
      expect(find.byType(DemoAccessibilitePage), findsNothing);
      // Le port neutre : la source manque, l'ecran le dit, sans prenom ni
      // Classe inventes (D10), sans « Reessayer ».
      expect(find.byKey(AccueilAccessibilite.cleIndisponible), findsOneWidget);
      expect(
        find.text(t.accessibilite.accueil.indisponibleTitre),
        findsOneWidget,
      );
      expect(_salutation, findsNothing);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      _coranEtAideRestent();
      // « Voir ma classe » mene a Ma classe.
      await tester.ensureVisible(
        find.text(t.accessibilite.accueil.voirMaClasse),
      );
      await tester.tap(find.text(t.accessibilite.accueil.voirMaClasse));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveSuivi);
      expect(tester.takeException(), isNull);
    });

    testWidgets('presentation standard : l Accueil ELV-02, inchange', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        mode: InterfaceMode.standard,
      );
      expect(lieu(routeur), Routes.eleve);
      expect(find.byType(AccueilElevePage), findsOneWidget);
      expect(find.byType(AccueilAccessibilite), findsNothing);
    });

    testWidgets('« Besoin d aide ? » ouvre /eleve/aide, le retour ramene a '
        'l Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      final Finder aide = find.text(t.accessibilite.accueil.aide);
      await tester.ensureVisible(aide);
      await tester.tap(aide);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAide);
      expect(find.byType(AideComptePage), findsOneWidget);
      // Aucun canal publie (DB-CPT-07) : la page le dit.
      expect(
        find.text(t.compte.tuteur.pageAide.indisponibleTitre),
        findsOneWidget,
      );
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleve);
      expect(find.byType(AccueilAccessibilite), findsOneWidget);
    });

    testWidgets('/eleve/aide tapee directement s ouvre aussi', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      routeur.go(Routes.eleveAide);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAide);
      expect(find.byType(AideComptePage), findsOneWidget);
    });
  });

  group('D11 : les cinq etats, sur la route reelle', () {
    testWidgets('contenu : salutation, seance, un seul bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: const PortAccueilAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
        ),
      );
      expect(
        find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
        findsOneWidget,
      );
      expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      _coranEtAideRestent();
    });

    testWidgets('vide : la phrase et le chemin, sans Classe inventee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: const PortAccueilAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          situation: SituationAccueilDemo.vide,
        ),
      );
      expect(find.byKey(AccueilAccessibilite.cleVide), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.videTitre), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.videPhrase), findsOneWidget);
      expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
      _coranEtAideRestent();
    });

    testWidgets('erreur : ce qui manque, puis « Reessayer » relance', (
      WidgetTester tester,
    ) async {
      final _PortEchecPuisContenu port = _PortEchecPuisContenu();
      await _monter(tester, port: port);
      expect(find.byKey(AccueilAccessibilite.cleErreur), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.erreurTitre), findsOneWidget);
      expect(find.text(t.accessibilite.accueil.erreurPhrase), findsOneWidget);
      // Jamais un prenom ni un 0 de remplacement (D10).
      expect(_salutation, findsNothing);
      _coranEtAideRestent();
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(port.lectures, 2);
      expect(
        find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
        findsOneWidget,
      );
      expect(find.byKey(AccueilAccessibilite.cleErreur), findsNothing);
    });

    testWidgets('chargement : le squelette fidele, puis le contenu', (
      WidgetTester tester,
    ) async {
      final Completer<DonneesAccueilAccessibilite> attente =
          Completer<DonneesAccueilAccessibilite>();
      await _monter(tester, port: _PortEnAttente(attente.future));
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsOneWidget);
      // Quatre blocs : salutation, titre de section, carte, lignes.
      expect(
        find.descendant(
          of: find.byKey(AccueilAccessibilite.cleSquelette),
          matching: find.byType(Skeleton),
        ),
        findsNWidgets(4),
      );
      expect(_salutation, findsNothing);
      _coranEtAideRestent();
      attente.complete(
        const PortAccueilAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam)
            .lire(),
      );
      await stabiliser(tester);
      expect(find.byKey(AccueilAccessibilite.cleSquelette), findsNothing);
      expect(
        find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : le bandeau de PageShell, la page reste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        horsLigne: true,
        port: const PortAccueilAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
        ),
      );
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(
        find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
        findsOneWidget,
      );
      _coranEtAideRestent();
    });
  });

  group('DASH-MA-PROD-b : hors ligne, aucun bouton grise (D9)', () {
    testWidgets('chaque ActionPrincipale agit ; « Reessayer » relit le '
        'reseau ; « Voir ma classe » reste', (WidgetTester tester) async {
      // Hors ligne a la premiere lecture du reseau, en ligne a la suivante.
      int lecturesReseau = 0;
      await _monter(
        tester,
        port: const PortAccueilAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
        ),
        surcharges: <Override>[
          horsLigneProvider.overrideWith((Ref _) {
            lecturesReseau++;
            return Stream<bool>.value(lecturesReseau == 1);
          }),
        ],
      );
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      final Iterable<ActionPrincipale> actions = tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale));
      expect(actions, isNotEmpty);
      for (final ActionPrincipale action in actions) {
        expect(
          action.onPress,
          isNotNull,
          reason: '« ${action.libelle} » grise hors ligne',
        );
      }
      final Finder reessayer = find.widgetWithText(
        ActionPrincipale,
        t.classe.entree.reessayer,
      );
      expect(reessayer, findsOneWidget);
      final int avant = lecturesReseau;
      await tester.ensureVisible(reessayer);
      await tester.pumpAndSettle();
      await tester.tap(reessayer);
      await stabiliser(tester);
      expect(lecturesReseau, greaterThan(avant));
      expect(find.text(t.reseau.horsLigne), findsNothing);
      expect(reessayer, findsNothing);
      expect(find.byKey(AccueilAccessibilite.cleVoirClasse), findsOneWidget);
      _coranEtAideRestent();
    });
  });

  group('MA-HORSLIGNE-CLASSE-1 : hors ligne, Ma classe reste atteignable', () {
    // Contre-epreuve : sur l'ancien code, `CarteSession` masquait
    // « Voir ma classe » des que l'emplacement proposait « Reessayer ».
    testWidgets('« Voir ma classe » reste, a cote de « Reessayer », et mene '
        'a Ma classe, bandeau hors ligne compris', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        horsLigne: true,
        port: const PortAccueilAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
        ),
      );
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(
        find.widgetWithText(ActionPrincipale, t.classe.entree.reessayer),
        findsOneWidget,
      );
      final Finder voir = find.byKey(AccueilAccessibilite.cleVoirClasse);
      expect(voir, findsOneWidget);
      expect(tester.widget<ActionPrincipale>(voir).onPress, isNotNull);
      verifierUnSeulBoutonPlein(tester);
      await tester.ensureVisible(voir);
      await tester.pumpAndSettle();
      await tester.tap(voir);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveSuivi);
      // Ma classe s'affiche hors ligne, sous le bandeau.
      expect(find.byType(SuiviElevePage), findsOneWidget);
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DASH-MA-PROD-b : « ; » jamais seul en debut de ligne', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('vide, 320 x2, ${sens.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          port: const PortAccueilAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.idriss,
            situation: SituationAccueilDemo.vide,
          ),
          taille: const Size(320, 3200),
          echelle: 2,
          sens: sens,
        );
        expect(find.byKey(AccueilAccessibilite.cleVide), findsOneWidget);
        expect(
          _ponctuationsOrphelines(tester, find.byType(AccueilAccessibilite)),
          isEmpty,
        );
      });
    }
  });

  group('D11 : chaque etat atteignable en demonstration (?accueil=)', () {
    for (final (SituationAccueilDemo, Key?) cas
        in <(SituationAccueilDemo, Key?)>[
          (SituationAccueilDemo.contenu, AccueilAccessibilite.cleVoirClasse),
          (SituationAccueilDemo.vide, AccueilAccessibilite.cleVide),
          (SituationAccueilDemo.erreur, AccueilAccessibilite.cleErreur),
          (SituationAccueilDemo.chargement, AccueilAccessibilite.cleSquelette),
          (SituationAccueilDemo.horsLigne, null),
        ]) {
      testWidgets(cas.$1.name, (WidgetTester tester) async {
        await _monterDemo(tester, cas.$1);
        expect(find.byType(AccueilAccessibilite), findsOneWidget);
        final Key? cle = cas.$2;
        if (cle != null) expect(find.byKey(cle), findsOneWidget);
        if (cas.$1 == SituationAccueilDemo.horsLigne) {
          // La Classe reste lue ; l'entree est inerte, le bandeau dit
          // pourquoi.
          expect(
            find.text(t.accessibilite.accueil.salutation(prenom: 'Mariam')),
            findsOneWidget,
          );
          expect(find.text(t.reseau.horsLigne), findsOneWidget);
        }
        _coranEtAideRestent();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Aucun mot coupe (lecon 8), 320 x2 et 1440, LTR et RTL', () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, PortAccueilAccessibilite?, bool)> etats =
        <(String, PortAccueilAccessibilite?, bool)>[
          ('indisponible', null, false),
          (
            'contenu',
            const PortAccueilAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
            ),
            false,
          ),
          // DASH-MA-PROD-b : la ligne d'etat hors ligne de la carte de
          // seance (« une conn / exion » a 320 px x2 sur l'ancien code).
          (
            'hors ligne',
            const PortAccueilAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
            ),
            true,
          ),
          (
            'vide',
            const PortAccueilAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.idriss,
              situation: SituationAccueilDemo.vide,
            ),
            false,
          ),
          (
            'erreur',
            const PortAccueilAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              situation: SituationAccueilDemo.erreur,
            ),
            false,
          ),
        ];
    for (final (String nom, PortAccueilAccessibilite? port, bool horsLigne)
        in etats) {
      for (final TextDirection sens in TextDirection.values) {
        for (final (double largeur, double echelle) forme in <(double, double)>[
          (320, 2),
          (1440, 1),
          (1440, 2),
        ]) {
          testWidgets('$nom, ${forme.$1.toInt()} x${forme.$2.toInt()}, '
              '${sens.name}', (WidgetTester tester) async {
            await _monter(
              tester,
              port: port,
              horsLigne: horsLigne,
              taille: Size(forme.$1, 3200),
              echelle: forme.$2,
              sens: sens,
            );
            expect(find.byType(AccueilAccessibilite), findsOneWidget);
            expect(tester.takeException(), isNull);
            verifierEcranSansMotCoupe(tester);
          });
        }
      }
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('aide de l eleve, 320 x2, ${sens.name}', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(
          tester,
          taille: const Size(320, 3200),
          echelle: 2,
          sens: sens,
        );
        routeur.go(Routes.eleveAide);
        await stabiliser(tester);
        expect(find.byType(AideComptePage), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}

/// Les ponctuations hautes (« ; », « : », « ! », « ? », « » ») rendues
/// seules en debut de ligne, sous [ou] : chacune doit rester sur la ligne
/// du dernier caractere qui la precede (espace insecable, typographie
/// francaise).
List<String> _ponctuationsOrphelines(WidgetTester tester, Finder ou) {
  final List<String> fautes = <String>[];
  final RegExp motif = RegExp(r'\S([ \u00a0\u202f])([;:!?»])');
  final Set<RenderParagraph> paragraphes = <RenderParagraph>{};
  void visiter(RenderObject o) {
    if (o is RenderParagraph) paragraphes.add(o);
    o.visitChildren(visiter);
  }

  tester.renderObjectList<RenderObject>(ou).forEach(visiter);
  for (final RenderParagraph p in paragraphes) {
    if (!p.hasSize || !p.attached) continue;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in motif.allMatches(texte)) {
      double haut(int debut) => p
          .getBoxesForSelection(
            TextSelection(baseOffset: debut, extentOffset: debut + 1),
          )
          .first
          .top;
      final int signe = m.end - 1;
      if ((haut(m.start) - haut(signe)).abs() > 1) {
        fautes.add('$texte : « ${m.group(2)} » seul en debut de ligne');
      }
    }
  }
  return fautes;
}

/// Un port dont la reponse arrive quand le test le decide.
class _PortEnAttente implements PortAccueilAccessibilite {
  const _PortEnAttente(this.reponse);

  final Future<DonneesAccueilAccessibilite> reponse;

  @override
  Future<DonneesAccueilAccessibilite> lire() => reponse;
}
