// LISTES-1 (23/10/2026) : les composants partages des listes d'administration
// qui ne sont pas la table elle-meme :
//
//   * `CaseACocher` : trois etats lisibles sans la couleur, cible du mode,
//     clavier ;
//   * `PiedDeListe` : « 1-50 sur 614 », fleches aux bornes, taille de page
//     SEULEMENT si l'ecran la fournit ;
//   * `BarreSelection.compacte` : une ligne, sans casser la barre complete ;
//   * `PuceFiltreActif` et `FiltresActifs` : filtres retirables un a un,
//     « Tout effacer » ;
//   * `PaysEnseignant.parCode` : nom de la langue de l'interface, drapeau si
//     l'image existe, drapeau decoratif.
//
// Clair et sombre, 390 et 1440, texte x1 et x2, de gauche a droite et de droite
// a gauche.

import 'dart:io';
import 'dart:ui' show PointerDeviceKind, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsData, SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/core/widgets/pied_de_liste.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../../support/sens_et_echelle.dart';

Widget _hote(
  Widget enfant, {
  Brightness luminosite = Brightness.light,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  TextDirection? direction,
}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      darkTheme: AppTheme.pour(mode, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: sensEtEchelle(direction: direction, echelle: echelle),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Align(alignment: AlignmentDirectional.topStart, child: enfant),
        ),
      ),
    ),
  ),
);

void _vue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('CaseACocher', () {
    testWidgets('trois etats, lus par le lecteur d\'ecran', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          Column(
            children: <Widget>[
              CaseACocher(valeur: true, libelle: 'cochee', onChange: (_) {}),
              CaseACocher(valeur: false, libelle: 'vide', onChange: (_) {}),
              CaseACocher(valeur: null, libelle: 'partielle', onChange: (_) {}),
            ],
          ),
        ),
      );
      SemanticsNode noeud(String libelle) =>
          tester.getSemantics(find.bySemanticsLabel(libelle));
      expect(
        noeud('cochee'),
        matchesSemantics(
          label: 'cochee',
          hasCheckedState: true,
          isChecked: true,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      expect(
        noeud('vide'),
        matchesSemantics(
          label: 'vide',
          hasCheckedState: true,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      // Partielle : `mixed`, pas « non cochee ».
      final SemanticsData partielle = noeud('partielle').getSemanticsData();
      // ignore: deprecated_member_use
      expect(partielle.hasFlag(SemanticsFlag.isCheckStateMixed), isTrue);
      semantique.dispose();
    });

    testWidgets('l\'etat se lit sans la couleur : coche, trait, rien', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Column(
            children: <Widget>[
              CaseACocher(valeur: true, libelle: 'a', onChange: (_) {}),
              CaseACocher(valeur: false, libelle: 'b', onChange: (_) {}),
              CaseACocher(valeur: null, libelle: 'c', onChange: (_) {}),
            ],
          ),
        ),
      );
      // Cochee et partielle portent un glyphe ; la vide n'en a pas.
      expect(find.byType(Icon), findsNWidgets(2));
    });

    testWidgets('le toucher donne la valeur suivante', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<bool> recues = <bool>[];
      for (final bool? depart in <bool?>[false, null, true]) {
        await tester.pumpWidget(
          _hote(
            CaseACocher(valeur: depart, libelle: 'x', onChange: recues.add),
          ),
        );
        await tester.tap(find.byType(CaseACocher));
      }
      // vide -> cochee ; partielle -> cochee ; cochee -> vide.
      expect(recues, <bool>[true, true, false]);
    });

    testWidgets('Entree et Espace la basculent, le clavier la focalise', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<bool> recues = <bool>[];
      await tester.pumpWidget(
        _hote(CaseACocher(valeur: false, libelle: 'x', onChange: recues.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(recues, <bool>[true, true]);
    });

    for (final (InterfaceMode mode, double cible) in <(InterfaceMode, double)>[
      (InterfaceMode.standard, 48),
      (InterfaceMode.enfant, 72),
    ]) {
      testWidgets('la cible suit le mode : ${mode.name}', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            CaseACocher(valeur: false, libelle: 'x', onChange: (_) {}),
            mode: mode,
          ),
        );
        final Size taille = tester.getSize(find.byType(CaseACocher));
        expect(taille.width, cible);
        expect(taille.height, cible);
      });
    }

    for (final Brightness luminosite in Brightness.values) {
      test('contraste de la case vide et de la case cochee : '
          '${luminosite.name}', () {
        final AppPalette p = luminosite == Brightness.light
            ? AppPalette.claire()
            : AppPalette.sombre();
        // Composant d'interface : 3:1 contre sa surface (WCAG 1.4.11).
        expect(
          _contraste(
            p.borderStrong.asBorderSide().color,
            p.surfaceRaised.background,
          ),
          greaterThanOrEqualTo(3),
        );
        // La coche se lit sur le fond plein.
        expect(
          _contraste(
            p.surfacePrimary.onBackground,
            p.surfacePrimary.background,
          ),
          greaterThanOrEqualTo(3),
        );
        // Le fond plein se detache de la surface.
        expect(
          _contraste(p.surfacePrimary.background, p.surfaceRaised.background),
          greaterThanOrEqualTo(3),
        );
      });
    }

    testWidgets('survol : un disque doux, la case ne bouge pas', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(CaseACocher(valeur: false, libelle: 'x', onChange: (_) {})),
      );
      final Rect avant = tester.getRect(find.byType(CaseACocher));
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      await souris.moveTo(tester.getCenter(find.byType(CaseACocher)));
      await tester.pump();
      expect(tester.getRect(find.byType(CaseACocher)), avant);
    });
  });

  group('PiedDeListe', () {
    testWidgets('« 1-50 sur 614 », seule la fleche suivante au debut', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: PiedDeListe(debut: 1, fin: 50, total: 614, onSuivant: () {}),
          ),
        ),
      );
      expect(find.text('1-50 sur 614'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-suivant')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-precedent')), findsNothing);
      // Aucun selecteur : l'ecran n'a fourni aucune taille de page.
      expect(find.byKey(PiedDeListe.cleTaille), findsNothing);
    });

    testWidgets(
      'la taille imposee par la source est dite a cote de la tranche',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            SizedBox(
              width: 900,
              child: PiedDeListe(
                debut: 1,
                fin: 50,
                total: 614,
                mention: '50 par page',
                onSuivant: () {},
              ),
            ),
          ),
        );
        expect(find.text('50 par page'), findsOneWidget);
        expect(find.byKey(PiedDeListe.cleTaille), findsNothing);
      },
    );

    testWidgets('etroit : la navigation seule, ni mention ni selecteur', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 390,
            child: PiedDeListe(
              debut: 1,
              fin: 50,
              total: 614,
              mention: '50 par page',
              taillePage: 50,
              taillesProposees: const <int>[25, 50, 100],
              onTaillePage: (int _) {},
              onSuivant: () {},
            ),
          ),
        ),
      );
      expect(find.text('50 par page'), findsNothing);
      expect(find.byKey(PiedDeListe.cleTaille), findsNothing);
      expect(find.text('1-50 sur 614'), findsOneWidget);
    });

    testWidgets('a la derniere page, seule la fleche precedente', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: PiedDeListe(
              debut: 601,
              fin: 614,
              total: 614,
              onPrecedent: () {},
            ),
          ),
        ),
      );
      expect(find.text('601-614 sur 614'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('nav-precedent')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('nav-suivant')), findsNothing);
    });

    testWidgets('les fleches appellent l\'ecran, rien d\'autre', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: PiedDeListe(
              debut: 51,
              fin: 100,
              total: 614,
              onPrecedent: () => journal.add('precedent'),
              onSuivant: () => journal.add('suivant'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('nav-suivant')));
      await tester.tap(find.byKey(const ValueKey<String>('nav-precedent')));
      expect(journal, <String>['suivant', 'precedent']);
    });

    testWidgets('la taille de page n\'apparait que si l\'ecran la fournit', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<int> choisies = <int>[];
      // Des tailles sans rappel : pas de selecteur (un faux controle).
      await tester.pumpWidget(
        _hote(
          const SizedBox(
            width: 900,
            child: PiedDeListe(
              debut: 1,
              fin: 50,
              total: 614,
              taillePage: 50,
              taillesProposees: <int>[25, 50, 100],
            ),
          ),
        ),
      );
      expect(find.byKey(PiedDeListe.cleTaille), findsNothing);

      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: PiedDeListe(
              debut: 1,
              fin: 50,
              total: 614,
              taillePage: 50,
              taillesProposees: const <int>[25, 50, 100],
              onTaillePage: choisies.add,
            ),
          ),
        ),
      );
      expect(find.byKey(PiedDeListe.cleTaille), findsOneWidget);
      expect(find.text('50 par page'), findsOneWidget);
      await tester.tap(find.byKey(PiedDeListe.cleTaille));
      await tester.pumpAndSettle();
      await tester.tap(find.text('100 par page'));
      await tester.pumpAndSettle();
      expect(choisies, <int>[100]);

      // Choisir la taille courante ne rappelle pas.
      await tester.tap(find.byKey(PiedDeListe.cleTaille));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 par page').last);
      await tester.pumpAndSettle();
      expect(choisies, <int>[100]);
    });

    testWidgets('une liste vide n\'a pas de pied', (WidgetTester tester) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(const PiedDeListe(debut: 0, fin: 0, total: 0)),
      );
      expect(find.byType(PiedDeListe), findsOneWidget);
      expect(find.text('0-0 sur 0'), findsNothing);
      expect(find.byType(BarrePrecedentSuivant), findsNothing);
    });

    testWidgets('en arabe : la tranche est dite dans la langue', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: PiedDeListe(debut: 1, fin: 50, total: 614, onSuivant: () {}),
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(find.textContaining('614'), findsOneWidget);
      expect(find.textContaining('sur'), findsNothing);
    });
  });

  group('BarreSelection.compacte', () {
    testWidgets('une ligne : le compte, les operations, Deselectionner', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: BarreSelection.compacte(
              titre: '3 sélectionnées',
              onRelacher: () => journal.add('relache'),
              operations: <Widget>[
                ActionPrincipale(
                  libelle: 'Mettre en pause',
                  niveau: NiveauAction.secondaire,
                  compacte: true,
                  pleineLargeur: false,
                  onPress: () => journal.add('pause'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('3 sélectionnées'), findsOneWidget);
      expect(find.text('Mettre en pause'), findsOneWidget);
      expect(find.text('Désélectionner'), findsOneWidget);
      // Une ligne : bien moins que les 140 de la barre complete.
      expect(
        tester.getSize(find.byKey(BarreSelection.cleBarre)).height,
        lessThanOrEqualTo(64),
      );
      await tester.tap(find.text('Mettre en pause'));
      await tester.tap(find.text('Désélectionner'));
      expect(journal, <String>['pause', 'relache']);
    });

    testWidgets('sans operation : la phrase dit la limite', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: BarreSelection.compacte(
              titre: '1 sélectionnée',
              phrase: 'Les autres gestes se font un par un, depuis la fiche.',
              onRelacher: () {},
            ),
          ),
        ),
      );
      expect(find.text('Désélectionner'), findsOneWidget);
      expect(
        find.text('Les autres gestes se font un par un, depuis la fiche.'),
        findsOneWidget,
      );
      expect(find.byType(ActionPrincipale), findsOneWidget);
    });

    testWidgets('la barre complete reste intacte', (WidgetTester tester) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: BarreSelection(
              titre: '3 candidatures retenues',
              phrase: 'Choisissez l\'action.',
              libelleRelacher: 'Tout relâcher',
              onRelacher: () {},
              libelleAction: 'Agir sur la sélection',
              onAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Tout relâcher'), findsOneWidget);
      expect(find.text('Agir sur la sélection'), findsOneWidget);
      expect(find.text('Désélectionner'), findsNothing);
      expect(
        tester.getSize(find.byKey(BarreSelection.cleBarre)).height,
        greaterThan(100),
      );
    });
  });

  group('FiltresActifs', () {
    testWidgets('chaque puce retire son filtre, Tout effacer les retire tous', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: FiltresActifs(
              filtres: <FiltreActif>[
                FiltreActif(
                  libelle: 'État : En examen',
                  onRetirer: () => journal.add('etat'),
                ),
                FiltreActif(
                  libelle: 'Pays : Guinée',
                  onRetirer: () => journal.add('pays'),
                ),
              ],
              onToutEffacer: () => journal.add('tout'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pays : Guinée'));
      expect(journal, <String>['pays']);
      await tester.tap(find.text('État : En examen'));
      expect(journal, <String>['pays', 'etat']);
      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      expect(journal, <String>['pays', 'etat', 'tout']);
    });

    testWidgets('sans filtre : rien, pas meme Tout effacer', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          FiltresActifs(filtres: const <FiltreActif>[], onToutEffacer: () {}),
        ),
      );
      expect(find.byKey(FiltresActifs.cleToutEffacer), findsNothing);
      expect(find.byType(RangeeFiltres), findsNothing);
    });

    testWidgets('la voix dit l\'effet du toucher, retenu ou pas', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          SizedBox(
            width: 900,
            child: FiltresActifs(
              filtres: <FiltreActif>[
                FiltreActif(libelle: 'Pays : Guinée', onRetirer: () {}),
              ],
              onToutEffacer: () {},
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Retirer le filtre : Pays : Guinée'),
        findsOneWidget,
      );
      semantique.dispose();
    });

    testWidgets(
      'une puce se declare retenue : la rangee l\'amene dans la vue',
      (WidgetTester tester) async {
        const PuceFiltreActif puce = PuceFiltreActif(
          libelle: 'x',
          onRetirer: _rien,
        );
        expect(puce, isA<PuceFiltre>());
        expect(puce.retenue, isTrue);
      },
    );

    testWidgets('la voix de l\'ecran prime quand il en donne une', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          PuceFiltreActif(
            libelle: 'Tuteur : Sayyid Ibrahim',
            libelleRetirer: 'Retirer le filtre Tuteur : Sayyid Ibrahim',
            onRetirer: () {},
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Retirer le filtre Tuteur : Sayyid Ibrahim'),
        findsOneWidget,
      );
      semantique.dispose();
    });
  });

  group('PaysEnseignant.parCode', () {
    String? imageDuDrapeau(WidgetTester tester) {
      final Iterable<Image> images = tester.widgetList<Image>(
        find.byType(Image),
      );
      if (images.isEmpty) return null;
      final ImageProvider<Object> source = images.single.image;
      return source is AssetImage ? source.assetName : null;
    }

    testWidgets('un code : le nom de la langue et le drapeau', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(const PaysEnseignant.parCode(codeIso: 'GN')),
      );
      expect(find.text('Guinée'), findsOneWidget);
      expect(imageDuDrapeau(tester), 'assets/flags/gn.png');
    });

    testWidgets('en arabe : le nom arabe et le meme drapeau', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const PaysEnseignant.parCode(codeIso: 'GN'),
          direction: TextDirection.rtl,
        ),
      );
      expect(find.text('غينيا'), findsOneWidget);
      expect(imageDuDrapeau(tester), 'assets/flags/gn.png');
    });

    testWidgets('minuscules acceptees, et 46 pays de plus ont leur image', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      for (final (String code, String nom) in <(String, String)>[
        ('gn', 'Guinée'),
        ('SA', 'Arabie saoudite'),
        ('dz', 'Algérie'),
        ('KE', 'Kenya'),
        ('mx', 'Mexique'),
      ]) {
        await tester.pumpWidget(_hote(PaysEnseignant.parCode(codeIso: code)));
        expect(find.text(nom), findsOneWidget, reason: code);
        expect(
          imageDuDrapeau(tester),
          'assets/flags/${code.toLowerCase()}.png',
          reason: code,
        );
      }
    });

    testWidgets('sans image : le nom seul, jamais deux lettres', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(const PaysEnseignant.parCode(codeIso: 'BV')),
      );
      expect(find.text(nomDuPays('BV')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('BV'), findsNothing);
    });

    testWidgets('code absent ou invalide : rien', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      for (final String? code in <String?>[null, '', 'G', 'GIN', '12', 'G-']) {
        await tester.pumpWidget(_hote(PaysEnseignant.parCode(codeIso: code)));
        expect(find.byType(Text), findsNothing, reason: '$code');
        expect(find.byType(Image), findsNothing, reason: '$code');
      }
    });

    testWidgets('le drapeau est decoratif : la phrase lue est le pays', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(const PaysEnseignant.parCode(codeIso: 'SN')),
      );
      expect(
        find.bySemanticsLabel(t.enseignant.pays.semantique(pays: 'Sénégal')),
        findsOneWidget,
      );
      semantique.dispose();
    });

    testWidgets('la construction par nom ne change pas', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_hote(const PaysEnseignant(pays: 'Guinée')));
      expect(find.text('Guinée'), findsOneWidget);
      expect(imageDuDrapeau(tester), 'assets/flags/gn.png');
      await tester.pumpWidget(_hote(const PaysEnseignant(pays: 'Comores')));
      expect(find.text('Comores'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    test('la liste des drapeaux est celle du dossier, 64 x 48', () {
      final Set<String> disque = Directory('assets/flags')
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last)
          .where((String n) => n.endsWith('.png'))
          .map((String n) => n.substring(0, n.length - 4).toUpperCase())
          .toSet();
      expect(drapeauxEmbarques, disque);
      expect(disque.length, 248);
      for (final String code in disque) {
        // Un vrai code ISO de la table des pays.
        expect(paysDuCode(code), isNotNull, reason: code);
        // PNG : 8 octets de signature, puis IHDR (largeur, hauteur).
        final List<int> octets = File(cheminDrapeau(code))
            .readAsBytesSync()
            .sublist(0, 24);
        expect(octets.sublist(1, 4), <int>[0x50, 0x4E, 0x47], reason: code);
        final ByteData d = ByteData.sublistView(Uint8List.fromList(octets));
        expect(d.getUint32(16), 64, reason: code);
        expect(d.getUint32(20), 48, reason: code);
      }
    });

    test('la licence cite tous les pays ajoutes', () {
      final String licence = File('assets/flags/LICENCE.txt')
          .readAsStringSync();
      for (final String code in drapeauxEmbarques) {
        expect(
          licence.toLowerCase(),
          contains(code.toLowerCase()),
          reason: code,
        );
      }
      expect(licence, contains('flag-icons 7.5.0'));
      expect(licence, contains('MIT'));
    });
  });

  // Les 16 combinaisons (clair, sombre) x (390, 1440) x (x1, x2) x (LTR, RTL)
  // pour les composants de pied, de selection et de filtres : rien ne deborde.
  for (final Brightness luminosite in Brightness.values) {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final TextDirection direction in TextDirection.values) {
          testWidgets(
            'sans debordement : ${luminosite.name} ${taille.width.round()} '
            'x$echelle ${direction.name}',
            (WidgetTester tester) async {
              _vue(tester, taille);
              await tester.pumpWidget(
                _hote(
                  SizedBox(
                    width: taille.width - 16,
                    height: taille.height - 16,
                    // Defilable : a 200 %, la pile entiere depasse l'ecran, ce
                    // que la page absorberait par son defilement.
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FiltresActifs(
                            filtres: <FiltreActif>[
                              FiltreActif(
                                libelle: 'Pays de résidence : Guinée',
                                onRetirer: () {},
                              ),
                              FiltreActif(
                                libelle: 'État : Entretien à planifier',
                                onRetirer: () {},
                              ),
                            ],
                            onToutEffacer: () {},
                          ),
                          BarreSelection.compacte(
                            titre: '12 sélectionnées',
                            onRelacher: () {},
                            operations: <Widget>[
                              ActionPrincipale(
                                libelle: 'Mettre en pause',
                                niveau: NiveauAction.secondaire,
                                compacte: true,
                                pleineLargeur: false,
                                onPress: () {},
                              ),
                              ActionPrincipale(
                                libelle: 'Refuser',
                                niveau: NiveauAction.destructive,
                                compacte: true,
                                pleineLargeur: false,
                                onPress: () {},
                              ),
                            ],
                          ),
                          PiedDeListe(
                            debut: 51,
                            fin: 100,
                            total: 614,
                            onPrecedent: () {},
                            onSuivant: () {},
                            taillePage: 50,
                            taillesProposees: const <int>[25, 50, 100],
                            onTaillePage: (int _) {},
                          ),
                          const PaysEnseignant.parCode(codeIso: 'CI'),
                          CaseACocher(
                            valeur: null,
                            libelle: 'Cocher la page',
                            onChange: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  luminosite: luminosite,
                  echelle: echelle,
                  direction: direction,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(PiedDeListe), findsOneWidget);
            },
          );
        }
      }
    }
  }
}

void _rien() {}
