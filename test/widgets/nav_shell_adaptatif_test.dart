import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

const List<Destination> _destinations = <Destination>[
  Destination(libelle: 'Accueil', icone: AppIcons.accueil, chemin: '/accueil'),
  Destination(libelle: 'Suivi', icone: AppIcons.suivi, chemin: '/suivi'),
  Destination(
    libelle: 'Réglages',
    icone: AppIcons.reglages,
    chemin: '/reglages',
  ),
  Destination(
    libelle: 'Compte',
    icone: AppIcons.profil,
    chemin: '/compte',
    enPied: true,
  ),
];

Widget _shell({
  required void Function(String chemin) onAller,
  bool masquerBarreBasse = false,
  bool libellesDansLeRail = false,
  int? indexActif = 0,
  Widget? contenu,
}) => NavShell(
  destinations: _destinations,
  indexActif: indexActif,
  onAller: onAller,
  masquerBarreBasse: masquerBarreBasse,
  libellesDansLeRail: libellesDansLeRail,
  child: contenu ?? const PageShell(child: SizedBox(key: Key('contenu'))),
);

void _vue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('les seuils du shell correspondent aux quatre classes R2', () {
    expect(AppGabarit.pour(599), Gabarit.mobile);
    expect(AppGabarit.pour(600), Gabarit.tablette);
    expect(AppGabarit.pour(839), Gabarit.tablette);
    expect(AppGabarit.pour(840), Gabarit.tablette);
    expect(AppGabarit.pour(1199), Gabarit.tablette);
    expect(AppGabarit.pour(1200), Gabarit.desktop);

    expect(AppGabarit.margePour(390), AppSpacing.lg);
    expect(AppGabarit.margePour(768), AppSpacing.xxl);
    expect(AppGabarit.margePour(1440), AppSpacing.xxxl);
  });

  testWidgets('le chrome change sans modifier le contenu aux seuils R2', (
    WidgetTester tester,
  ) async {
    for (final ({double largeur, Key chrome, double? largeurChrome}) cas
        in <({double largeur, Key chrome, double? largeurChrome})>[
          (largeur: 599, chrome: NavShell.barreBasseKey, largeurChrome: null),
          (
            largeur: 600,
            chrome: NavShell.railKey,
            largeurChrome: AppGabarit.largeurRail,
          ),
          (
            largeur: 1199,
            chrome: NavShell.railKey,
            largeurChrome: AppGabarit.largeurRail,
          ),
          (
            largeur: 1200,
            chrome: NavShell.barreLateraleKey,
            largeurChrome: AppGabarit.largeurBarreLaterale,
          ),
        ]) {
      _vue(tester, Size(cas.largeur, 720));
      await tester.pumpWidget(hote(_shell(onAller: (_) {})));
      await tester.pump();

      expect(find.byKey(const Key('contenu')), findsOneWidget);
      expect(find.byKey(cas.chrome), findsOneWidget, reason: '${cas.largeur}');
      if (cas.chrome == NavShell.barreBasseKey) {
        expect(
          tester.getSize(find.byKey(cas.chrome)).height,
          greaterThanOrEqualTo(NavShell.hauteurBarre),
        );
        // La barre flotte au-dessus du contenu, jamais dessous.
        expect(
          tester.getTopLeft(find.byKey(cas.chrome)).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byKey(const Key('contenu'))).dy,
          ),
        );
      }
      if (cas.largeurChrome != null) {
        expect(tester.getSize(find.byKey(cas.chrome)).width, cas.largeurChrome);
      }
      expect(tester.takeException(), isNull, reason: '${cas.largeur}');
    }
  });

  testWidgets('barre basse : quatre onglets, l actif annonce et souligne', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(hote(_shell(onAller: (_) {}, indexActif: 2)));
    await tester.pump();

    for (final Destination d in _destinations) {
      expect(find.text(d.libelle), findsOneWidget, reason: d.libelle);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Réglages')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Accueil')),
      isSemantics(isSelected: false, isButton: true),
    );
    // Le soulignement de trois points n'existe que sous l'onglet actif.
    final Iterable<SizedBox> soulignements = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((SizedBox s) => s.height == NavShell.epaisseurSoulignement);
    expect(soulignements, hasLength(_destinations.length));
    expect(soulignements.where((SizedBox s) => s.child != null), hasLength(1));
    semantique.dispose();
  });

  testWidgets('zone sure : la barre prend l encart bas, jamais le haut', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    late EdgeInsets encartContenu;
    await tester.pumpWidget(
      hote(
        _shell(
          onAller: (_) {},
          contenu: Builder(
            builder: (BuildContext context) {
              encartContenu = MediaQuery.paddingOf(context);
              return const PageShell(child: SizedBox(key: Key('contenu')));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // Le contenu garde l'encart haut (barre d'etat) et ne recoit plus le bas,
    // deja consomme par la barre : aucun encart applique deux fois (C11 5.6).
    expect(encartContenu.top, 47);
    expect(encartContenu.bottom, 0);
    final double hauteurBarre = tester
        .getSize(find.byKey(NavShell.barreBasseKey))
        .height;
    // Hauteur de la pilule + marges + encart bas, sans l'encart haut.
    expect(hauteurBarre, lessThan(NavShell.hauteurBarre + 47 + 34));
    expect(tester.getBottomLeft(find.byKey(NavShell.barreBasseKey)).dy, 844);
  });

  testWidgets('tache focalisee : pas de barre basse sur telephone', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hote(_shell(onAller: (_) {}, masquerBarreBasse: true)),
    );
    await tester.pump();
    expect(find.byKey(NavShell.barreBasseKey), findsNothing);
    expect(find.byKey(const Key('contenu')), findsOneWidget);

    // Sur tablette, la colonne reste visible.
    _vue(tester, const Size(768, 1024));
    await tester.pumpWidget(
      hote(_shell(onAller: (_) {}, masquerBarreBasse: true)),
    );
    await tester.pump();
    expect(find.byKey(NavShell.railKey), findsOneWidget);
  });

  testWidgets('rail replie : infobulles et Compte epingle en bas', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(768, 1024));
    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    // Replie, aucun libelle n'est ecrit : chaque icone porte son infobulle.
    expect(find.text('Accueil'), findsNothing);
    for (final Destination d in _destinations) {
      expect(find.byTooltip(d.libelle), findsOneWidget, reason: d.libelle);
    }
    final double compte = tester.getCenter(find.byTooltip('Compte')).dy;
    final double reglages = tester.getCenter(find.byTooltip('Réglages')).dy;
    // Epingle en bas : bien plus bas que les autres destinations.
    expect(compte - reglages, greaterThan(AppSpacing.respiration * 4));
  });

  testWidgets(
    'rail a libelles (eleve, enseignant) : les noms restent visibles',
    (WidgetTester tester) async {
      // Revue phase 0 (jetons D2) : hors tuteur, le rail replie garde la forme
      // d'avant le chantier, un nom lisible sous chaque icone, jusqu'a 200 %.
      for (final double echelle in <double>[1, 2]) {
        const Size taille = Size(768, 1024);
        _vue(tester, taille);
        final SemanticsHandle semantique = tester.ensureSemantics();
        await tester.pumpWidget(
          hote(
            MediaQuery(
              data: MediaQueryData(
                size: taille,
                textScaler: TextScaler.linear(echelle),
              ),
              child: _shell(
                onAller: (_) {},
                indexActif: 2,
                libellesDansLeRail: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(NavShell.railKey), findsOneWidget);
        // 80 de base ; plus large seulement si un mot n'y tient pas meme a
        // 0,85 (police de test, un em par lettre) : le rail s'elargit au lieu
        // de couper le mot (relecture COUPE-MOTS-1).
        expect(
          tester.getSize(find.byKey(NavShell.railKey)).width,
          greaterThanOrEqualTo(AppGabarit.largeurRail),
        );
        for (final Destination d in _destinations) {
          expect(
            find.descendant(
              of: find.byKey(NavShell.railKey),
              matching: find.text(d.libelle),
            ),
            findsOneWidget,
            reason: '${d.libelle} a $echelle',
          );
        }
        expect(
          tester.getSemantics(find.bySemanticsLabel('Réglages')),
          isSemantics(isSelected: true, isButton: true),
        );
        expect(tester.takeException(), isNull, reason: '$echelle');
        semantique.dispose();
      }
    },
  );

  testWidgets('barre laterale : mot-symbole, bouton de repli, choix garde', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(1440, 900));
    final ProviderContainer conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: conteneur,
        child: hote(_shell(onAller: (_) {})),
      ),
    );
    await tester.pump();

    expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
    expect(find.text('Rewayah'), findsOneWidget);
    expect(find.text('Compte'), findsOneWidget);

    await tester.tap(find.byKey(NavShell.boutonRepliKey));
    await tester.pump();
    expect(find.byKey(NavShell.railKey), findsOneWidget);
    expect(tester.getSize(find.byKey(NavShell.railKey)).width, 80);

    await tester.tap(find.byKey(NavShell.boutonRepliKey));
    await tester.pump();
    expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
  });

  testWidgets('le choix de l appareil deplie aussi le rail d une tablette', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(900, 900));
    final ProviderContainer conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);
    conteneur.read(navigationReplieeProvider.notifier).choisir(repliee: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: conteneur,
        child: hote(_shell(onAller: (_) {})),
      ),
    );
    await tester.pump();
    expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
  });

  testWidgets('le rail conserve un defilement vertical', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(768, 240));
    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(NavShell.railKey),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barre laterale conserve un defilement vertical', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(1200, 240));
    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(NavShell.barreLateraleKey),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la destination conserve son contrat de chemin au clavier', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    String? chemin;
    await tester.pumpWidget(
      hote(_shell(onAller: (String valeur) => chemin = valeur)),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(chemin, '/accueil');
  });

  testWidgets('le shell reste sans débordement à 200 % et en RTL', (
    WidgetTester tester,
  ) async {
    for (final Size taille in <Size>[
      const Size(1200, 360),
      const Size(768, 360),
      const Size(360, 640),
    ]) {
      _vue(tester, taille);
      await tester.pumpWidget(
        hote(
          MediaQuery(
            data: MediaQueryData(
              size: taille,
              textScaler: const TextScaler.linear(2),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _shell(onAller: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: '$taille');
    }
  });

  test('le tuteur a quatre destinations, Compte epingle en bas', () {
    final List<Destination> tuteur = destinationsPour(
      role: AppRole.guardian,
      mode: InterfaceMode.standard,
    );
    expect(tuteur.map((Destination d) => d.chemin), <String>[
      Routes.tuteurAccueil,
      Routes.tuteurFoyer,
      Routes.tuteurSuivi,
      Routes.tuteurCompte,
    ]);
    expect(tuteur.map((Destination d) => d.enPied), <bool>[
      false,
      false,
      false,
      true,
    ]);
    expect(tuteur[2].icone, AppIcons.historique);
    for (final AppRole role in AppRole.values) {
      expect(secondairesPour(role: role), isEmpty, reason: role.valeurSql);
    }
  });
}
