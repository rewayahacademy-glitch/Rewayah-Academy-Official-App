// PAGESHELL-200-1e : reserves de PAGESHELL-200-1d et d'ALERTE-1b.
//
// (1) Sous le bandeau fige de la coquille admin (alerte urgente), la tete de
//     page (titre, onglets et, des 600, Recherche, theme, cloche, compte)
//     reste fixe pendant que la page defile ; le bandeau la pousse sans la
//     recouvrir, sans debordement. Compact, rail (600-1199), large ; LTR et
//     RTL ; Interface guidee. Sans bandeau, une tete plus haute que la vue
//     defile au lieu de deborder.
// (2) En Interface guidee, l'ecart entre le bandeau fige et le titre suit
//     le rythme de l'interface standard (24 sous les 8 du bandeau), et non
//     plus la respiration de 64 (environ 70 de vide).
//
// Chaque cas echoue sur le code d'avant (contre-epreuve faite le 09/10).
// Les cas qui passaient deja (tete trop haute sous le bandeau, telephone a
// 200 %) restent couverts par `test/features/alertes/alerte1b_test.dart`.
// (3) Le retour a la tete fixe, reporte tant qu'une animation tourne, est
//     borne : une animation sans fin ne le reporte plus indefiniment.
// (4) Le titre simple de `PageShell` suit l'echelle compacte HIER-1 a texte
//     agrandi.
// (5) Journal admin : bandeau de la chaine a 320 px texte x2 (17 px de
//     debordement), et Journal en Interface guidee a 390x684 sur la vraie
//     coque (22 px de debordement en bas).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/bascule_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_journal/journal_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

const Key _cleBandeau = ValueKey<String>('bandeau-fige');
const Key _cleOnglets = ValueKey<String>('onglets');
const Key _cleCorps = ValueKey<String>('corps');

/// Une page admin defilante : titre, retour, onglets, longue liste.
Widget _page({double hauteurOnglets = 48}) => PageShell(
  titre: 'Regles',
  entete: SizedBox(key: _cleOnglets, height: hauteurOnglets),
  child: Column(
    key: _cleCorps,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (int i = 0; i < 60; i++) SizedBox(height: 40, child: Text('l $i')),
    ],
  ),
);

Widget _coque(Widget page, {bool bandeau = true}) => AdminShell(
  domaines: domainesAdmin(voitDirection: true),
  domaineActif: AdminDomaine.configuration,
  onAller: (String _) {},
  onCompte: () {},
  onRetour: () {},
  bandeau: bandeau
      ? const SizedBox(key: _cleBandeau, height: 96, child: Text('Alerte'))
      : null,
  child: page,
);

void _vue(WidgetTester tester, Size taille, {double echelle = 1}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (echelle != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = echelle;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  TextDirection sens = TextDirection.ltr,
  InterfaceMode mode = InterfaceMode.standard,
  List<Override> surcharges = const <Override>[],
}) async {
  await tester.pumpWidget(
    hote(
      Directionality(textDirection: sens, child: enfant),
      mode: mode,
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ...surcharges,
      ],
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le defileur vertical le plus haut, sous `PageShell`, qui a quelque chose
/// a defiler.
ScrollableState _defileur(WidgetTester tester) {
  final List<ScrollableState> candidats = tester
      .stateList<ScrollableState>(
        find.descendant(
          of: find.byType(PageShell),
          matching: find.byType(Scrollable),
        ),
      )
      .where(
        (ScrollableState s) =>
            s.position.axis == Axis.vertical &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 0,
      )
      .toList();
  expect(candidats, isNotEmpty, reason: 'la page doit defiler');
  double haut(ScrollableState s) => tester.getRect(find.byWidget(s.widget)).top;
  candidats.sort(
    (ScrollableState a, ScrollableState b) => haut(a).compareTo(haut(b)),
  );
  return candidats.first;
}

Finder get _titre => find.text('Regles');

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('(1) la tete reste fixe sous le bandeau fige, en defilant', () {
    for (final (String, Size) gabarit in const <(String, Size)>[
      ('compact', Size(390, 844)),
      ('rail', Size(800, 600)),
      ('rail', Size(1024, 768)),
      ('large', Size(1440, 900)),
      ('large', Size(1440, 700)),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        for (final InterfaceMode mode in InterfaceMode.values) {
          testWidgets('${gabarit.$1} ${gabarit.$2.width.toInt()}x'
              '${gabarit.$2.height.toInt()}, ${sens.name}, ${mode.name}', (
            WidgetTester tester,
          ) async {
            _vue(tester, gabarit.$2);
            await _monter(tester, _coque(_page()), sens: sens, mode: mode);
            expect(tester.takeException(), isNull);

            final Rect bandeau = tester.getRect(find.byKey(_cleBandeau));
            final Rect titre = tester.getRect(_titre);
            final Rect onglets = tester.getRect(find.byKey(_cleOnglets));
            final bool actions = gabarit.$2.width >= 600;
            final Rect? theme = actions
                ? tester.getRect(find.byType(BasculeTheme))
                : null;
            // Le bandeau pousse la tete, sans la recouvrir.
            expect(titre.top, greaterThanOrEqualTo(bandeau.bottom));
            if (theme != null) {
              expect(theme.top, greaterThanOrEqualTo(bandeau.bottom));
            }

            final ScrollableState page = _defileur(tester);
            // C'est le corps qui defile, sous la tete.
            expect(
              tester.getRect(find.byWidget(page.widget)).top,
              greaterThanOrEqualTo(onglets.bottom - 0.5),
            );
            page.position.jumpTo(page.position.maxScrollExtent);
            await tester.pump();
            expect(tester.takeException(), isNull);

            expect(tester.getRect(find.byKey(_cleBandeau)), bandeau);
            expect(tester.getRect(_titre), titre, reason: 'titre fixe');
            expect(
              tester.getRect(find.byKey(_cleOnglets)),
              onglets,
              reason: 'onglets fixes',
            );
            if (theme != null) {
              expect(
                tester.getRect(find.byType(BasculeTheme)),
                theme,
                reason: 'actions fixes (Recherche, theme, cloche, compte)',
              );
              expect(theme.bottom, lessThanOrEqualTo(gabarit.$2.height));
            }
            // Le bas de la liste est atteint, dans la vue.
            expect(
              tester.getRect(find.text('l 59')).bottom,
              lessThanOrEqualTo(gabarit.$2.height + 0.5),
            );
          });
        }
      }
    }

    testWidgets('sans bandeau, une tete plus haute que la vue defile au lieu '
        'de deborder', (WidgetTester tester) async {
      _vue(tester, const Size(800, 600));
      await _monter(
        tester,
        PageShell(
          titre: 'Regles',
          defilante: false,
          entete: const SizedBox(key: _cleOnglets, height: 700),
          child: ListView(
            key: _cleCorps,
            children: <Widget>[
              for (int i = 0; i < 60; i++)
                SizedBox(height: 40, child: Text('l $i')),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final ScrollableState page = _defileur(tester);
      page.position.jumpTo(page.position.maxScrollExtent);
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Le corps recoit la hauteur de la vue, sous la tete qui a defile.
      expect(tester.getSize(find.byKey(_cleCorps)).height, greaterThan(500));
    });
  });

  group('(2) Interface guidee : ecart du bandeau au titre', () {
    for (final (Size, bool) cas in const <(Size, bool)>[
      (Size(390, 844), true),
      (Size(1440, 900), true),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.width.toInt()}x${cas.$1.height.toInt()}, '
            '${cas.$2 ? 'bandeau' : 'sans bandeau'}, ${sens.name}', (
          WidgetTester tester,
        ) async {
          _vue(tester, cas.$1);
          await _monter(
            tester,
            _coque(_page(), bandeau: cas.$2),
            sens: sens,
            mode: InterfaceMode.enfant,
          );
          expect(tester.takeException(), isNull);
          // Le haut de la ligne de tete (retour, titre, actions).
          final double ligne = tester.getRect(find.byType(EntetePage)).top;
          if (cas.$2) {
            final double bandeau = tester
                .getRect(find.byKey(_cleBandeau))
                .bottom;
            // 8 sous le bandeau, puis 24 : le rythme de l'interface
            // standard, au lieu de 8 + 64.
            expect(
              ligne - bandeau,
              closeTo(AppSpacing.sm + AppSpacing.xxl, 0.5),
            );
          } else {
            // Sans bandeau, la respiration de l'Interface guidee reste.
            final double page = tester.getRect(find.byType(PageShell)).top;
            expect(ligne - page, closeTo(AppSpacing.respiration, 0.5));
          }
        });
      }
    }
  });

  group('(3) retour a la tete fixe sous une animation sans fin', () {
    testWidgets('le report est borne : la page reprend la tete fixe', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<double> hauteur = ValueNotifier<double>(500);
      addTearDown(hauteur.dispose);
      _vue(tester, const Size(800, 600));
      await _monter(
        tester,
        PageShell(
          titre: 'Salle',
          defilante: false,
          entete: const Column(
            children: <Widget>[
              SizedBox(height: 300),
              // Une animation qui tourne sans fin, dans la tete.
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(),
              ),
            ],
          ),
          child: ColonneCorps(
            key: _cleCorps,
            children: <Widget>[
              ValueListenableBuilder<double>(
                valueListenable: hauteur,
                builder: (BuildContext _, double h, Widget? _) =>
                    SizedBox(height: h),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      Finder defileurDuCorps() => find.ancestor(
        of: find.byKey(_cleCorps),
        matching: find.byType(Scrollable),
      );
      expect(defileurDuCorps(), findsOneWidget, reason: 'defilement global');

      hauteur.value = 50;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      expect(
        defileurDuCorps(),
        findsNothing,
        reason: 'retour a la tete fixe malgre l\'animation sans fin',
      );
    });
  });

  group('(4) titre simple a texte agrandi : echelle compacte HIER-1', () {
    for (final (Size, double) cas in const <(Size, double)>[
      (Size(390, 844), 2),
      (Size(320, 640), 2),
      (Size(1440, 900), 2),
      (Size(390, 844), 1.5),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.width.toInt()}x${cas.$1.height.toInt()}, texte '
            'x${cas.$2}, ${sens.name}', (WidgetTester tester) async {
          _vue(tester, cas.$1, echelle: cas.$2);
          await _monter(
            tester,
            const PageShell(
              titre: 'Classe Al-Badr aujourd\'hui',
              child: SizedBox(height: 40),
            ),
            sens: sens,
          );
          expect(tester.takeException(), isNull);
          final Finder titre = find.byKey(PageShell.titreSimpleKey);
          expect(titre, findsOneWidget);
          final BuildContext contexte = tester.element(titre);
          final ThemeData theme = Theme.of(contexte);
          final double taille = theme.textTheme.headlineLarge!.fontSize!;
          final double section = theme.textTheme.titleLarge!.fontSize!;
          final double rendu = MediaQuery.textScalerOf(contexte).scale(taille);
          // Un palier au-dessus d'un titre de section agrandi, jamais plus
          // que l'appareil, jamais sous la taille du theme.
          final double vise =
              TextScaler.linear(cas.$2).scale(section) + EnteteCompact.palier;
          expect(
            rendu,
            lessThanOrEqualTo((vise > taille ? vise : taille) + 0.01),
          );
          // Et plus petit que le titre a l'echelle de l'appareil (36 x2 = 72
          // avant).
          expect(rendu, lessThan(TextScaler.linear(cas.$2).scale(taille)));
          expect(rendu, greaterThanOrEqualTo(taille));
          verifierAucunMotCoupe(tester, titre);
        });
      }
    }
  });

  group('(5) Journal admin', () {
    for (final TextDirection sens in TextDirection.values) {
      for (final double echelle in <double>[2]) {
        testWidgets('bandeau de la chaine a 320 px texte x$echelle, '
            '${sens.name} : aucun debordement, aucun mot coupe', (
          WidgetTester tester,
        ) async {
          _vue(tester, const Size(320, 640), echelle: echelle);
          await _monter(
            tester,
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: <Widget>[BandeauChaineJournal()]),
              ),
            ),
            sens: sens,
            surcharges: <Override>[
              serviceJournalProvider.overrideWithValue(FauxServiceJournal()),
            ],
          );
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(BandeauChaineJournal));
          if (echelle == 2) {
            expect(find.byKey(BandeauChaineJournal.clePile), findsOneWidget);
          }
        });
      }
    }

    // La vraie coque admin (demonstration : barre mobile, repere), ou le
    // Journal en Interface guidee debordait de 22 px en bas sans alerte.
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('coque admin, Journal en Interface guidee a 390x684, '
          'sans alerte, ${sens.name}', (WidgetTester tester) async {
        _vue(tester, const Size(390, 684));
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesDemoAdmin(
                environnement: 'staging',
                avecAlertes: false,
              ),
              modeAccessibiliteActifProvider.overrideWith((Ref _) => true),
            ],
            child: TranslationProvider(
              child: RewayahApp(
                builder: (BuildContext context, Widget? child) =>
                    Directionality(
                      textDirection: sens,
                      child: RepereDemonstration(child: child),
                    ),
              ),
            ),
          ),
        );
        ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
            .read(routeurProvider)
            .go(Routes.adminSecuriteAuditJournal);
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        final ScrollableState page = _defileur(tester);
        page.position.jumpTo(page.position.maxScrollExtent);
        await tester.pump();
        expect(tester.takeException(), isNull);
        // Le corps (l'etat d'erreur de la demonstration) est atteint et se
        // touche : une tete fixe plus haute que la vue l'aurait coupe.
        expect(find.text(t.commun.reessayer).hitTestable(), findsOneWidget);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
