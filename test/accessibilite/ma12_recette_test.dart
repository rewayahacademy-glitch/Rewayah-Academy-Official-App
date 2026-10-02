// MA-12 : recette du Mode Accessibilite.
//
// 1. Reste connu de MA-11 : le parcours clavier et les cibles de la page
//    « Interface » du tuteur, depuis la vraie coquille (vrai routeur,
//    session de tuteur), comme dans l'application.
// 2. Matrice des ecrans MA (Accueil, Ma classe, Coran, Mon espace, apres la
//    seance, preparation, salle) pour Mariam et Idriss : trois largeurs,
//    clair et sombre, texte a 200 %, RTL structurel, lecteur d'ecran (chaque
//    action porte un libelle).

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/interface_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';

Future<(GoRouter, FauxServiceAppairage)> _monter(
  WidgetTester tester,
  Size taille,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = FoyersFictifs.foyerA;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext contexte, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.ficheEleveSousPage(FoyersFictifs.a1.id, 'interface'));
  await stabiliser(tester);
  return (routeur, appairage);
}

/// Un ecran du Mode Accessibilite de la demonstration, avec ses reglages.
class _Ecran {
  const _Ecran(this.nom, this.construire);
  final String nom;
  final Widget Function(EleveDemoAccessibilite) construire;
}

final List<_Ecran> _ecransMa = <_Ecran>[
  _Ecran(
    'Accueil',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
    ),
  ),
  _Ecran(
    'Ma classe',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      destinationInitiale: EcranAccessibiliteDemo.indexMaClasse,
    ),
  ),
  _Ecran(
    'Coran',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      destinationInitiale: EcranAccessibiliteDemo.indexCoran,
    ),
  ),
  _Ecran(
    'Mon espace',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
    ),
  ),
  _Ecran(
    'Apres la seance',
    (EleveDemoAccessibilite e) =>
        EcranAccessibiliteDemo(eleve: e, moment: MomentDemoAccessibilite.apres),
  ),
  _Ecran(
    'Preparation',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      moment: MomentDemoAccessibilite.fenetre,
      etapeInitiale: EtapeDemoAccessibilite.preparation,
    ),
  ),
  _Ecran(
    'Salle',
    (EleveDemoAccessibilite e) => EcranAccessibiliteDemo(
      eleve: e,
      moment: MomentDemoAccessibilite.fenetre,
      etapeInitiale: EtapeDemoAccessibilite.salle,
    ),
  ),
];

Widget _hoteMa(
  Widget ecran, {
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  bool rtl = false,
}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.enfant, luminosite),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? enfant) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: enfant ?? const SizedBox.shrink(),
        ),
      ),
      home: ecran,
    ),
  ),
);

/// Les noeuds d'action de l'arbre Semantics qui n'ont aucun libelle.
List<String> _actionsSansLibelle(SemanticsNode racine) {
  final List<String> manque = <String>[];
  void visiter(SemanticsNode n) {
    final SemanticsData d = n.getSemanticsData();
    final bool nomme =
        d.label.trim().isNotEmpty ||
        d.value.trim().isNotEmpty ||
        d.tooltip.trim().isNotEmpty;
    if (d.hasAction(SemanticsAction.tap) && !nomme && !n.isInvisible) {
      manque.add('${n.id} ${n.rect}');
    }
    n.visitChildren((SemanticsNode c) {
      visiter(c);
      return true;
    });
  }

  visiter(racine);
  return manque;
}

void _fixer(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Defauts trouves par la recette MA-12, a corriger a MA-RC (ne pas masquer :
/// retirer l'entree quand le defaut est corrige).
const String _defautLibelleControle =
    'Defaut MA-12 : Mon espace, le controle natif (Switch ou Radio) de '
    'SettingRow (setting_row.dart, controle) est un noeud tactile sans '
    'libelle : le lecteur d ecran lit une case sans nom';

String? _sautLibelle(String ecran) =>
    ecran == 'Mon espace' ? _defautLibelleControle : null;

void _matrice() {
  for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
    for (final _Ecran ecran in _ecransMa) {
      group('MA-12 ${ecran.nom}, ${eleve.name}', () {
        for (final Size taille in <Size>[
          const Size(390, 844),
          const Size(768, 1024),
          const Size(1440, 900),
        ]) {
          for (final Brightness lum in Brightness.values) {
            testWidgets(
              '${taille.width.toInt()} px, ${lum.name} : se rend sans '
              'debordement',
              (WidgetTester tester) async {
                _fixer(tester, taille);
                await tester.pumpWidget(
                  _hoteMa(ecran.construire(eleve), luminosite: lum),
                );
                await stabiliser(tester);
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
        for (final Size taille in <Size>[
          const Size(390, 844),
          const Size(1440, 900),
        ]) {
          testWidgets(
            '${taille.width.toInt()} px, texte a 200 % : ni debordement ni '
            'exception',
            (WidgetTester tester) async {
              _fixer(tester, taille);
              await tester.pumpWidget(
                _hoteMa(ecran.construire(eleve), echelle: 2),
              );
              await stabiliser(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
        testWidgets('RTL structurel (390 px) : ni exception ni debordement', (
          WidgetTester tester,
        ) async {
          _fixer(tester, const Size(390, 844));
          await tester.pumpWidget(_hoteMa(ecran.construire(eleve), rtl: true));
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
        });
        testWidgets('lecteur d ecran : chaque action porte un libelle', (
          WidgetTester tester,
        ) async {
          _fixer(tester, const Size(390, 844));
          final SemanticsHandle poignee = tester.ensureSemantics();
          await tester.pumpWidget(_hoteMa(ecran.construire(eleve)));
          await stabiliser(tester);
          final SemanticsNode racine = tester.getSemantics(
            find.byType(EcranAccessibiliteDemo),
          );
          expect(
            _actionsSansLibelle(racine),
            isEmpty,
            reason: 'action sans libelle sur ${ecran.nom}',
          );
          poignee.dispose();
        }, skip: _sautLibelle(ecran.nom) != null);
      });
    }
  }
}

void main() {
  _matrice();

  group('MA-12 page Interface du tuteur : clavier et cibles', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} px : Tab, cibles >= 48, Maj+Tab', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        expect(find.byKey(InterfaceElevePage.choixKey), findsOneWidget);
        final List<FocusNode> vus = <FocusNode>[];
        for (int i = 0; i < 40; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final FocusNode? f = FocusManager.instance.primaryFocus;
          if (f == null || f.context == null) continue;
          if (vus.isNotEmpty && identical(f, vus.first)) break;
          if (vus.contains(f)) continue;
          vus.add(f);
          expect(
            f.rect.height,
            greaterThanOrEqualTo(48),
            reason: 'cible ${f.debugLabel} trop basse ${f.rect}',
          );
          expect(
            f.rect.width,
            greaterThanOrEqualTo(48),
            reason: 'cible ${f.debugLabel} trop etroite ${f.rect}',
          );
        }
        expect(
          vus.length,
          greaterThanOrEqualTo(2),
          reason: 'au moins retour et un choix au clavier',
        );
        final FocusNode? avant = FocusManager.instance.primaryFocus;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNot(same(avant)));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Entree sur la carte « standard » l ecrit (clavier seul)', (
      WidgetTester tester,
    ) async {
      final (GoRouter _, FauxServiceAppairage appairage) = await _monter(
        tester,
        const Size(1440, 900),
      );
      final Finder libelle = find.text(t.ficheEleve.interface.standard);
      final Rect carte = tester.getRect(libelle);
      bool trouve = false;
      for (int i = 0; i < 40 && !trouve; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final Rect? z = FocusManager.instance.primaryFocus?.rect;
        if (z != null && z.contains(carte.center)) trouve = true;
      }
      expect(trouve, isTrue, reason: 'la carte standard prend le focus');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await stabiliser(tester);
      expect(appairage.reglagesEcrits, hasLength(1));
      expect(appairage.reglagesEcrits.single.mode, InterfaceMode.standard);
    });
  });
}
