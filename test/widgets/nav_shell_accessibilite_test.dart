// MA-NAV-1 : en Mode Accessibilite (guide), la barre de navigation change de
// PRESENTATION sans changer d'ARBORESCENCE.
//
// - memes routes : la liste montree est un sous-ensemble de la liste standard,
//   et chaque onglet rend le chemin qu'il avait ;
// - les destinations essentielles seulement ; pour l'eleve, les quatre
//   (Coran compris, MA-CMD-1, decision deleguee du 02/10) ;
// - icones et libelles plus grands, libelle toujours visible sous l'icone,
//   cibles de 72 au moins et espacees, contraste renforce ;
// - destination active a trois signaux : fond plein, icone pleine, libelle en
//   gras ;
// - 320 et 1440, texte x1 et x2, clair et sombre, RTL.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart'
    show echelleMinimaleLisible;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_compte.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';

Future<void> _monter(
  WidgetTester tester, {
  required InterfaceMode mode,
  required List<Destination> destinations,
  required int? indexActif,
  Size taille = const Size(320, 700),
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  void Function(String chemin)? onAller,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(mode, luminosite),
          builder: (BuildContext context, Widget? app) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          home: Scaffold(
            body: NavShell(
              destinations: destinations,
              indexActif: indexActif,
              onAller: onAller ?? (String _) {},
              libellesDansLeRail: false,
              child: const SizedBox.expand(key: Key('contenu')),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

Finder _onglet(String libelle) =>
    find.ancestor(of: find.text(libelle), matching: find.byType(Pressable));

List<Destination> _eleve(InterfaceMode mode) =>
    destinationsPour(role: AppRole.student, mode: mode);

AppPalette _palette(WidgetTester tester) =>
    AppPalette.of(tester.element(find.byKey(const Key('contenu'))));

double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double haut = la > lb ? la : lb;
  final double bas = la > lb ? lb : la;
  return (haut + 0.05) / (bas + 0.05);
}

/// Les controles de la barre guidee a 320 : chaque libelle entier (aucun mot
/// coupe, jamais tronque, echelle au plancher de lisibilite ou au-dessus),
/// cibles de 72 en largeur comme en hauteur, ecart de 4 au moins entre deux
/// onglets d'une meme rangee et entre deux rangees, rangees alignees (meme
/// haut, meme hauteur), ordre de lecture (de la rangee du haut vers celle du
/// bas, dans le sens de l'ecriture).
void _verifierBarreGuidee(
  WidgetTester tester,
  List<Destination> d, {
  required double echelle,
  TextDirection sens = TextDirection.ltr,
  String? reason,
}) {
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  expect(barre, findsOneWidget, reason: reason);
  expect(motsCoupes(tester, barre), isEmpty, reason: reason);
  final List<(Destination, Rect)> mesures = <(Destination, Rect)>[];
  for (final Destination x in d) {
    // Libelle toujours visible, entier.
    final Finder texte = find.descendant(
      of: barre,
      matching: find.text(x.libelle),
    );
    expect(texte, findsOneWidget, reason: '$reason ${x.libelle}');
    final RenderParagraph p = tester.renderObject<RenderParagraph>(texte);
    expect(p.didExceedMaxLines, isFalse, reason: '$reason ${x.libelle}');
    expect(p.overflow, isNot(TextOverflow.ellipsis));
    expect(
      p.textScaler.scale(10),
      greaterThanOrEqualTo(10 * echelleMinimaleLisible - 0.001),
      reason: '$reason ${x.libelle}',
    );
    final Rect onglet = tester.getRect(_onglet(x.libelle));
    expect(
      onglet.height,
      greaterThanOrEqualTo(AppTouchTarget.enfant),
      reason: '$reason ${x.libelle}',
    );
    expect(
      onglet.width,
      greaterThanOrEqualTo(AppTouchTarget.enfant),
      reason: '$reason ${x.libelle}',
    );
    // Libelle sous l'icone (la tuile Compte porte l'avatar).
    final Rect icone = tester.getRect(
      find.descendant(
        of: _onglet(x.libelle),
        matching: x.compte ? find.byType(AvatarTile) : find.byType(Icon),
      ),
    );
    expect(
      tester.getRect(texte).top,
      greaterThanOrEqualTo(icone.bottom),
      reason: '$reason ${x.libelle}',
    );
    // Tout reste dans l'ecran.
    expect(onglet.left, greaterThanOrEqualTo(0), reason: x.libelle);
    expect(onglet.right, lessThanOrEqualTo(320), reason: x.libelle);
    mesures.add((x, onglet));
  }
  // Le cercle du Compte n'est pas une rangee de la pilule : il se regle seul
  // (dans l'ecran, cible de 72), mais compte pour les ecarts.
  final List<(Destination, Rect)> pilule = <(Destination, Rect)>[
    for (final (Destination, Rect) m in mesures)
      if (!m.$1.compte) m,
  ];
  // Rangees : meme haut a 1 point pres.
  final List<List<(Destination, Rect)>> rangees = <List<(Destination, Rect)>>[];
  for (final (Destination, Rect) m in pilule) {
    final List<(Destination, Rect)>? rangee = rangees
        .where(
          (List<(Destination, Rect)> r) =>
              (r.first.$2.top - m.$2.top).abs() < 1,
        )
        .firstOrNull;
    if (rangee == null) {
      rangees.add(<(Destination, Rect)>[m]);
    } else {
      rangee.add(m);
    }
  }
  expect(rangees.length, lessThanOrEqualTo(2), reason: reason);
  for (final List<(Destination, Rect)> r in rangees) {
    // Rangee alignee : meme haut, meme hauteur.
    for (final (Destination, Rect) m in r) {
      expect(m.$2.height, closeTo(r.first.$2.height, 1), reason: reason);
    }
    // Ecart de 4 au moins entre deux onglets voisins.
    final List<Rect> triees = <Rect>[
      for (final (Destination, Rect) m in r) m.$2,
    ]..sort((Rect a, Rect b) => a.left.compareTo(b.left));
    for (int i = 1; i < triees.length; i++) {
      expect(
        triees[i].left - triees[i - 1].right,
        greaterThanOrEqualTo(AppSpacing.xs - 0.01),
        reason: reason,
      );
    }
  }
  if (rangees.length == 2) {
    rangees.sort(
      (List<(Destination, Rect)> a, List<(Destination, Rect)> b) =>
          a.first.$2.top.compareTo(b.first.$2.top),
    );
    // Ecart de 4 au moins entre les deux rangees.
    final double basHaut = rangees.first
        .map(((Destination, Rect) m) => m.$2.bottom)
        .reduce((double a, double b) => a > b ? a : b);
    expect(
      rangees.last.first.$2.top - basHaut,
      greaterThanOrEqualTo(AppSpacing.xs - 0.01),
      reason: reason,
    );
  }
  // Ordre de lecture : rangee du haut d'abord, puis dans le sens de
  // l'ecriture ; c'est l'ordre des destinations de la pilule.
  final List<String> lus = <String>[
    for (final (Destination, Rect) m
        in (<(Destination, Rect)>[...pilule]..sort((a, b) {
          final int rang = ((a.$2.top - b.$2.top).abs() < 1)
              ? 0
              : a.$2.top.compareTo(b.$2.top);
          if (rang != 0) return rang;
          return sens == TextDirection.rtl
              ? b.$2.left.compareTo(a.$2.left)
              : a.$2.left.compareTo(b.$2.left);
        })))
      m.$1.libelle,
  ];
  expect(lus, <String>[
    for (final Destination x in d)
      if (!x.compte) x.libelle,
  ], reason: 'ordre de lecture $reason');
}

/// L'ordre de tabulation suit l'ordre de lecture : les destinations de la
/// barre recoivent le focus dans l'ordre de la liste.
Future<void> _verifierOrdreTabulation(
  WidgetTester tester,
  List<Destination> d, {
  required TextDirection sens,
}) async {
  final List<String> vus = <String>[];
  final Set<String> noms = <String>{for (final Destination x in d) x.libelle};
  for (int i = 0; i < 12 && vus.length < noms.length; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final BuildContext? c = FocusManager.instance.primaryFocus?.context;
    final Pressable? p = c?.findAncestorWidgetOfExactType<Pressable>();
    final String? nom = p?.libelleSemantique;
    if (nom != null && noms.contains(nom) && !vus.contains(nom)) vus.add(nom);
  }
  expect(vus, <String>[for (final Destination x in d) x.libelle]);
}

void main() {
  // COUPE-MOTS-4 : vraies polices. La police de test (carres de 1 em) rend
  // chaque mot plus large qu'un onglet : la barre passerait a deux rangees
  // pour un defaut que l'application n'a pas.
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La locale arabe est differee : chargee une fois, hors des tests.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('les routes ne changent pas', () {
    test('le Mode Accessibilite est un sous-ensemble de la liste standard', () {
      for (final AppRole role in AppRole.values) {
        final List<String> standard = destinationsPour(
          role: role,
          mode: InterfaceMode.standard,
        ).map((Destination d) => d.chemin).toList();
        final List<String> guide = destinationsPour(
          role: role,
          mode: InterfaceMode.enfant,
        ).map((Destination d) => d.chemin).toList();
        expect(standard, containsAll(guide), reason: role.valeurSql);
        // Ordre conserve.
        expect(
          guide,
          standard.where(guide.contains).toList(),
          reason: role.valeurSql,
        );
      }
    });

    test(
      'l eleve garde ses 4 destinations, Coran compris (MA-CMD-1), les autres '
      'roles gardent les leurs',
      () {
        expect(
          _eleve(InterfaceMode.enfant)
              .map((Destination d) => d.chemin)
              .toList(),
          <String>[
            Routes.eleve,
            Routes.eleveSuivi,
            Routes.eleveApprendre,
            Routes.compte,
          ],
        );
        expect(_eleve(InterfaceMode.standard), hasLength(4));
        for (final AppRole role in AppRole.values) {
          if (role == AppRole.student) continue;
          expect(
            destinationsPour(role: role, mode: InterfaceMode.enfant),
            hasLength(
              destinationsPour(role: role, mode: InterfaceMode.standard).length,
            ),
            reason: role.valeurSql,
          );
        }
      },
    );

    test('Compte et Accueil restent atteignables en Mode Accessibilite', () {
      final List<String> chemins = _eleve(InterfaceMode.enfant)
          .map((Destination d) => d.chemin)
          .toList();
      expect(chemins, contains(Routes.compte));
      expect(chemins.first, Routes.eleve);
    });

    test(
      'indexDansBarre : l index de la branche devient celui de la barre',
      () {
        final List<Destination> completes = _eleve(InterfaceMode.standard);
        final List<Destination> visibles = _eleve(InterfaceMode.enfant);
        int? index(int? complet) => indexDansBarre(
          visibles: visibles,
          completes: completes,
          indexComplet: complet,
        );
        expect(index(0), 0);
        expect(index(1), 1);
        // Coran : dans la barre (MA-CMD-1).
        expect(index(2), 2);
        expect(index(3), 3);
        expect(index(null), isNull);
        expect(index(9), isNull);
        // Standard : identite.
        expect(
          indexDansBarre(
            visibles: completes,
            completes: completes,
            indexComplet: 2,
          ),
          2,
        );
      },
    );
  });

  group('barre basse du Mode Accessibilite', () {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets(
          '320, texte x${echelle.toInt()}, ${luminosite.name} : onglets de 72, '
          'libelle sous l icone, espaces, sans debordement',
          (WidgetTester tester) async {
            final List<Destination> d = _eleve(InterfaceMode.enfant);
            await _monter(
              tester,
              mode: InterfaceMode.enfant,
              destinations: d,
              indexActif: 1,
              echelle: echelle,
              luminosite: luminosite,
            );
            _verifierBarreGuidee(tester, d, echelle: echelle);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    // ESPACE-APPRENDRE (lot 5), contre-lecture de l'architecte du 13/11/2026 :
    // « Apprendre » (104 points a 20) ne tient plus sur une rangee a 320 avec
    // trois autres onglets ; la barre guidee a le droit de passer sur DEUX
    // rangees (MA-NAV-1 : libelle toujours visible, cibles de 72), et ce test
    // est strict pour cette disposition : les QUATRE roles, CHAQUE onglet
    // tour a tour comme onglet actif, francais et arabe (RTL), texte x1, x1,5
    // et x2.
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final AppRole role in <AppRole>[
        AppRole.student,
        AppRole.guardian,
        AppRole.teacher,
        AppRole.controller,
      ]) {
        for (final double echelle in <double>[1, 1.5, 2]) {
          testWidgets(
            '320, ${langue.name}, ${role.valeurSql}, texte x$echelle : '
            'libelles entiers, cibles de 72, ecarts, rangees alignees, ordre '
            'de lecture et de tabulation, chaque onglet actif',
            (WidgetTester tester) async {
              LocaleSettings.setLocaleSync(langue);
              addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
              final List<Destination> d = destinationsPour(
                role: role,
                mode: InterfaceMode.enfant,
              );
              final TextDirection sens = langue == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr;
              for (int actif = 0; actif < d.length; actif++) {
                await _monter(
                  tester,
                  mode: InterfaceMode.enfant,
                  destinations: d,
                  indexActif: actif,
                  echelle: echelle,
                  direction: sens,
                );
                _verifierBarreGuidee(
                  tester,
                  d,
                  echelle: echelle,
                  sens: sens,
                  reason: 'actif $actif',
                );
                await _verifierOrdreTabulation(tester, d, sens: sens);
              }
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('aucun libelle n est tronque a 320, texte x2', (
      WidgetTester tester,
    ) async {
      final List<Destination> d = _eleve(InterfaceMode.enfant);
      await _monter(
        tester,
        mode: InterfaceMode.enfant,
        destinations: d,
        indexActif: 0,
        echelle: 2,
      );
      for (final Destination x in d) {
        final RenderParagraph p = tester.renderObject<RenderParagraph>(
          find.text(x.libelle),
        );
        // Aucun libelle n'est tronque par des points de suspension, meme avec
        // la police de test (Ahem, un em par lettre, bien plus large que les
        // vraies polices) : le libelle passe a la ligne, sans limite de lignes.
        expect(p.didExceedMaxLines, isFalse, reason: x.libelle);
        // Le texte regle a x2 grandit dans la barre, jusqu'au plafond de 1,3 ;
        // il ne recule que si le mot le plus long ne tiendrait pas sur une
        // ligne (MA-NAV-1, TexteSansCoupure), et jamais sous 0,85
        // (`echelleMinimaleLisible`, relecture COUPE-MOTS-1) : la police de
        // test, un em par lettre, l'y amene.
        expect(
          p.textScaler.scale(10),
          inInclusiveRange(10 * echelleMinimaleLisible - 0.001, 13.001),
          reason: x.libelle,
        );
        expect(p.maxLines, isNull, reason: x.libelle);
        expect(p.overflow, isNot(TextOverflow.ellipsis), reason: x.libelle);
      }
    });

    testWidgets(
      'libelles longs en arabe, 320, x2, RTL : entiers, sans ellipse',
      (WidgetTester tester) async {
        final List<Destination> base = _eleve(InterfaceMode.enfant);
        const List<String> longs = <String>[
          'الصفحة الرئيسية للمتعلم',
          'فصلي الدراسي المباشر',
          'تلاوة القرآن الكريم وحفظه',
          'مساحتي الخاصة بي',
        ];
        final List<Destination> d = <Destination>[
          for (int i = 0; i < base.length; i++)
            Destination(
              libelle: longs[i % longs.length],
              icone: base[i].icone,
              chemin: base[i].chemin,
            ),
        ];
        await _monter(
          tester,
          mode: InterfaceMode.enfant,
          destinations: d,
          indexActif: 0,
          direction: TextDirection.rtl,
          echelle: 2,
        );
        expect(tester.takeException(), isNull);
        for (final Destination x in d) {
          final RenderParagraph p = tester.renderObject<RenderParagraph>(
            find.text(x.libelle),
          );
          expect(p.didExceedMaxLines, isFalse, reason: x.libelle);
          expect(p.overflow, isNot(TextOverflow.ellipsis), reason: x.libelle);
          // Le texte entier est mis en page : sa hauteur tient dans l'onglet.
          final double hauteurOnglet = tester
              .getSize(_onglet(x.libelle))
              .height;
          expect(p.size.height, lessThanOrEqualTo(hauteurOnglet));
        }
      },
    );

    testWidgets('plus grande et plus haute que la barre standard', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        mode: InterfaceMode.standard,
        destinations: _eleve(InterfaceMode.standard),
        indexActif: 0,
        taille: const Size(390, 700),
      );
      final double hStandard = tester
          .getSize(find.byKey(NavShell.barreBasseKey))
          .height;
      final Destination d0 = _eleve(InterfaceMode.standard).first;
      final double iconeStandard = tester
          .getSize(
            find.descendant(
              of: _onglet(d0.libelle),
              matching: find.byType(Icon),
            ),
          )
          .height;
      final double texteStandard = tester.getSize(find.text(d0.libelle)).height;

      await _monter(
        tester,
        mode: InterfaceMode.enfant,
        destinations: _eleve(InterfaceMode.enfant),
        indexActif: 0,
        taille: const Size(390, 700),
      );
      final double hGuide = tester
          .getSize(find.byKey(NavShell.barreBasseKey))
          .height;
      final double iconeGuide = tester
          .getSize(
            find.descendant(
              of: _onglet(d0.libelle),
              matching: find.byType(Icon),
            ),
          )
          .height;
      final double texteGuide = tester.getSize(find.text(d0.libelle)).height;
      expect(hGuide, greaterThan(hStandard));
      expect(iconeGuide, greaterThan(iconeStandard));
      expect(texteGuide, greaterThan(texteStandard));
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('destination active : trois signaux, ${luminosite.name}', (
        WidgetTester tester,
      ) async {
        final List<Destination> d = _eleve(InterfaceMode.enfant);
        await _monter(
          tester,
          mode: InterfaceMode.enfant,
          destinations: d,
          indexActif: 1,
          luminosite: luminosite,
        );
        final AppPalette palette = _palette(tester);
        final Destination active = d[1];
        final Destination repos = d[0];

        // 1. fond plein : seul l'onglet actif en porte un.
        Color? fond(Destination x) {
          final Iterable<DecoratedBox> boites = tester.widgetList<DecoratedBox>(
            find.descendant(
              of: _onglet(x.libelle),
              matching: find.byType(DecoratedBox),
            ),
          );
          for (final DecoratedBox b in boites) {
            final Decoration dec = b.decoration;
            if (dec is BoxDecoration && dec.color != null) return dec.color;
          }
          return null;
        }

        expect(fond(active), palette.surfacePrimary.background);
        expect(fond(repos), isNull);

        // 2. icone pleine.
        IconData icone(Destination x) => tester
            .widget<Icon>(
              find.descendant(
                of: _onglet(x.libelle),
                matching: find.byType(Icon),
              ),
            )
            .icon!;
        expect(icone(active), active.icone.resoudre(selectionne: true));
        expect(icone(repos), repos.icone.resoudre(selectionne: false));
        expect(icone(active), isNot(active.icone.resoudre(selectionne: false)));

        // 3. libelle en gras, plus que l'inactif.
        FontWeight? graisse(Destination x) =>
            tester.widget<Text>(find.text(x.libelle)).style?.fontWeight;
        expect(graisse(active), FontWeight.w700);
        expect(graisse(repos)!.value, lessThan(FontWeight.w700.value));

        // Contraste : l'actif lisible sur son fond, l'inactif sur la barre,
        // et mieux qu'en presentation standard (encre attenuee).
        final Color encreActive = tester
            .widget<Text>(find.text(active.libelle))
            .style!
            .color!;
        final Color encreRepos = tester
            .widget<Text>(find.text(repos.libelle))
            .style!
            .color!;
        expect(
          _contraste(encreActive, palette.surfacePrimary.background),
          greaterThanOrEqualTo(4.5),
        );
        final double repo = _contraste(
          encreRepos,
          palette.surfaceRaised.background,
        );
        expect(repo, greaterThanOrEqualTo(7));
        expect(
          repo,
          greaterThan(
            _contraste(
              palette.inkMuted.asBorderSide().color,
              palette.surfaceRaised.background,
            ),
          ),
        );
      });
    }

    testWidgets('chaque onglet rend le chemin de la liste standard', (
      WidgetTester tester,
    ) async {
      final List<String> rendus = <String>[];
      final List<Destination> d = _eleve(InterfaceMode.enfant);
      await _monter(
        tester,
        mode: InterfaceMode.enfant,
        destinations: d,
        indexActif: 0,
        onAller: rendus.add,
      );
      for (final Destination x in d) {
        await tester.tap(_onglet(x.libelle));
        await tester.pump();
      }
      final Set<String> standard = _eleve(InterfaceMode.standard)
          .map((Destination x) => x.chemin)
          .toSet();
      expect(rendus, d.map((Destination x) => x.chemin).toList());
      expect(standard, containsAll(rendus));
    });

    testWidgets('RTL : l ordre s inverse, rien ne deborde, x2', (
      WidgetTester tester,
    ) async {
      final List<Destination> d = _eleve(InterfaceMode.enfant);
      await _monter(
        tester,
        mode: InterfaceMode.enfant,
        destinations: d,
        indexActif: 0,
        direction: TextDirection.rtl,
        echelle: 2,
      );
      final double premier = tester.getCenter(_onglet(d.first.libelle)).dx;
      final double dernier = tester.getCenter(_onglet(d.last.libelle)).dx;
      expect(premier, greaterThan(dernier));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans theme enfant, la barre standard reste inchangee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        mode: InterfaceMode.standard,
        destinations: _eleve(InterfaceMode.standard),
        indexActif: 0,
      );
      final Destination d0 = _eleve(InterfaceMode.standard).first;
      expect(
        tester.getSize(_onglet(d0.libelle)).height,
        lessThan(AppTouchTarget.enfant + AppSpacing.xl),
      );
      // NAV-REFONTE (09/11/2026) : en standard, un onglet ferme n'a que son
      // icone ; son nom reste lu par le lecteur d'ecran.
      expect(
        find.text(_eleve(InterfaceMode.standard)[2].libelle),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(_eleve(InterfaceMode.standard)[2].libelle),
        findsOneWidget,
      );
    });
  });

  group('autres barres : meme regle de presentation', () {
    for (final AppRole role in <AppRole>[
      AppRole.student,
      AppRole.guardian,
      AppRole.teacher,
      AppRole.controller,
    ]) {
      testWidgets('${role.valeurSql}, guide, 320 x2 : cibles de 72', (
        WidgetTester tester,
      ) async {
        final List<Destination> d = destinationsPour(
          role: role,
          mode: InterfaceMode.enfant,
        );
        await _monter(
          tester,
          mode: InterfaceMode.enfant,
          destinations: d,
          indexActif: 0,
          echelle: 2,
        );
        for (final Destination x in d) {
          expect(
            tester.getSize(_onglet(x.libelle)).height,
            greaterThanOrEqualTo(AppTouchTarget.enfant),
            reason: x.libelle,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('${role.valeurSql}, guide, 1440 : barre laterale de 72', (
        WidgetTester tester,
      ) async {
        final List<Destination> d = destinationsPour(
          role: role,
          mode: InterfaceMode.enfant,
        );
        await _monter(
          tester,
          mode: InterfaceMode.enfant,
          destinations: d,
          indexActif: 0,
          taille: const Size(1440, 900),
        );
        expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
        for (final Destination x in d) {
          expect(
            tester.getSize(_onglet(x.libelle)).height,
            greaterThanOrEqualTo(AppTouchTarget.enfant),
            reason: x.libelle,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('${role.valeurSql}, guide, rail 800, x2 : nom visible', (
        WidgetTester tester,
      ) async {
        final List<Destination> d = destinationsPour(
          role: role,
          mode: InterfaceMode.enfant,
        );
        await _monter(
          tester,
          mode: InterfaceMode.enfant,
          destinations: d,
          indexActif: 0,
          taille: const Size(800, 1000),
          echelle: 2,
        );
        expect(find.byKey(NavShell.railKey), findsOneWidget);
        // 96 de base ; plus large seulement si un mot n'y tient pas meme a
        // 0,85 (police de test, un em par lettre) : le rail s'elargit au lieu
        // de couper le mot (relecture COUPE-MOTS-1).
        expect(
          tester.getSize(find.byKey(NavShell.railKey)).width,
          greaterThanOrEqualTo(AppGabarit.largeurRail + AppSpacing.lg),
        );
        verifierAucunMotCoupe(tester, find.byKey(NavShell.railKey));
        for (final Destination x in d) {
          // Le nom est rendu (jamais l'infobulle seule), sous l'icone.
          expect(find.text(x.libelle), findsOneWidget, reason: x.libelle);
          expect(
            tester.getSize(_onglet(x.libelle)).height,
            greaterThanOrEqualTo(AppTouchTarget.enfant),
            reason: x.libelle,
          );
          expect(
            tester.getTopLeft(find.text(x.libelle)).dy,
            greaterThanOrEqualTo(
              tester
                  .getRect(
                    find.descendant(
                      of: _onglet(x.libelle),
                      // NAV-REFONTE etape 3 : le Compte est au pied du
                      // panneau, la photo de la personne a la place de
                      // l'icone, son nom dessous.
                      matching: find.byType(x.compte ? AvatarCompte : Icon),
                    ),
                  )
                  .bottom,
            ),
            reason: x.libelle,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('rail et barre standard : cibles de 48, rien ne change', (
      WidgetTester tester,
    ) async {
      final List<Destination> d = _eleve(InterfaceMode.standard);
      await _monter(
        tester,
        mode: InterfaceMode.standard,
        destinations: d,
        indexActif: 0,
        taille: const Size(800, 1000),
      );
      expect(
        tester.getSize(find.byKey(NavShell.railKey)).width,
        AppGabarit.largeurRail,
      );
    });
  });
}
