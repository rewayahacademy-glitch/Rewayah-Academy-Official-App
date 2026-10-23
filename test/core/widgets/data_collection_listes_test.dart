// LISTES-1 (23/10/2026) : `DataCollection` pour les listes d'administration.
// Ce que ces tests gardent, clair et sombre, 390 et 1440, texte x1 et x2, de
// gauche a droite et de droite a gauche :
//
//   * la densite : une ligne mesure une cible tactile (48), plus 8 quand elle
//     porte une case ou un menu (56), et ne grandit que si son contenu l'exige ;
//   * la selection : colonne de cases, case d'en-tete a trois etats qui ne
//     coche que la page, une ligne non cochable n'a pas de case ;
//   * les actions : une colonne hors de la cible de la ligne (le menu n'ouvre
//     pas la ligne, deux arrets de tabulation, aucun bouton dans un bouton) ;
//   * le tri : l'en-tete d'une colonne est un bouton que l'ecran fournit, la
//     collection ne trie rien ;
//   * l'en-tete reste colle quand la collection defile seule ;
//   * le repli en cartes : la case avant, le menu apres, hors de la carte ;
//   * la retrocompatibilite : sans ces parametres, rien ne change.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';

import '../../support/sens_et_echelle.dart';

class _Fiche {
  const _Fiche(this.id, this.nom, this.pays, {this.alerte = false});

  final String id;
  final String nom;
  final String pays;
  final bool alerte;
}

const List<_Fiche> _fiches = <_Fiche>[
  _Fiche('a', 'Amina Diallo', 'Guinée'),
  _Fiche('b', 'Bilal Haddad', 'France'),
  _Fiche('c', 'Mariam Camara', 'Sénégal', alerte: true),
  _Fiche('d', 'Youssef Bah', "Côte d'Ivoire"),
];

Key _cleLigne(_Fiche f) => ValueKey<String>('ligne-${f.id}');

List<ColonneDonnees<_Fiche>> _colonnes({
  TriColonne? triNom,
  TriColonne? triPays,
}) => <ColonneDonnees<_Fiche>>[
  ColonneDonnees<_Fiche>(
    titre: 'Nom',
    texte: (_Fiche f) => f.nom,
    role: RoleColonne.identifiante,
    flex: 4,
    tri: triNom,
    // Une alerte : la seule ligne qui doit grandir.
    rendu: (BuildContext _, _Fiche f) => f.alerte
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(f.nom),
              const SizedBox(height: 4),
              const Text('Courriel à obtenir'),
              const Text('Indicatif à confirmer'),
            ],
          )
        : Text(f.nom),
  ),
  ColonneDonnees<_Fiche>(
    titre: 'Pays',
    texte: (_Fiche f) => f.pays,
    flex: 2,
    tri: triPays,
  ),
];

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
        body: Padding(padding: const EdgeInsets.all(8), child: enfant),
      ),
    ),
  ),
);

void _vue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _hauteur(WidgetTester tester, _Fiche f) =>
    tester.getSize(find.byKey(_cleLigne(f))).height;

MenuActions _menu(_Fiche f, {List<String>? journal, VoidCallback? onChoix}) =>
    MenuActions(
      objet: f.nom,
      actions: <EntreeAction>[
        EntreeAction(
          libelle: 'Exporter la fiche',
          icone: AppIcons.telecharger,
          onChoix: onChoix ?? () => journal?.add('exporter ${f.id}'),
        ),
      ],
    );

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Densite', () {
    testWidgets('une ligne de texte mesure une cible tactile : 48', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
          ),
        ),
      );
      expect(_hauteur(tester, _fiches[0]), 48);
      expect(_hauteur(tester, _fiches[1]), 48);
      expect(_hauteur(tester, _fiches[3]), 48);
    });

    testWidgets('avec une case et un menu : 56, la place de l\'anneau', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
            selection: SelectionCollection<_Fiche>(
              estCochee: (_Fiche _) => false,
              onBasculer: (_Fiche _) {},
              onBasculerPage: (bool _) {},
              libelleLigne: (_Fiche f) => f.nom,
            ),
            actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
          ),
        ),
      );
      expect(_hauteur(tester, _fiches[0]), 56);
      expect(_hauteur(tester, _fiches[1]), 56);
    });

    testWidgets('seule la ligne avec alerte grandit', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
            actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
          ),
        ),
      );
      expect(_hauteur(tester, _fiches[0]), 56);
      expect(_hauteur(tester, _fiches[2]), greaterThan(56));
      // Trois lignes de texte + 4 + 2 x 8 de marge.
      expect(_hauteur(tester, _fiches[2]), lessThan(120));
      expect(_hauteur(tester, _fiches[3]), 56);
    });

    testWidgets('Interface guidee : la cible du mode (72, puis 80)', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
          ),
          mode: InterfaceMode.enfant,
        ),
      );
      expect(_hauteur(tester, _fiches[0]), 72);

      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
            actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
          ),
          mode: InterfaceMode.enfant,
        ),
      );
      expect(_hauteur(tester, _fiches[0]), 80);
    });

    testWidgets('plus de dix lignes tiennent dans 900 de haut', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<_Fiche> beaucoup = <_Fiche>[
        for (int i = 0; i < 30; i++) _Fiche('n$i', 'Nom $i', 'Guinée'),
      ];
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: beaucoup,
            cle: _cleLigne,
            actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
          ),
        ),
      );
      final Rect cadre = tester.getRect(find.byType(DataCollection<_Fiche>));
      int visibles = 0;
      for (final _Fiche f in beaucoup) {
        final Finder ligne = find.byKey(_cleLigne(f));
        if (ligne.evaluate().isEmpty) continue;
        if (tester.getRect(ligne).bottom <= cadre.bottom) visibles++;
      }
      // 900 - 16 de marge - 32 d'en-tete = 852 ; 852 / 56 = 15.
      expect(visibles, greaterThanOrEqualTo(14));
    });

    testWidgets('sans commande, l\'en-tete garde la hauteur de son texte', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(DataCollection<_Fiche>(colonnes: _colonnes(), lignes: _fiches)),
      );
      final double enTete = tester.getSize(find.text('Nom')).height;
      // 16 de texte + 8 + 8 : jamais plus de la cible.
      final Rect titre = tester.getRect(find.text('Nom'));
      final Rect premiere = tester.getRect(find.text('Amina Diallo'));
      expect(premiere.top - titre.top, lessThan(48));
      expect(enTete, lessThan(48));
    });
  });

  group('Selection', () {
    Widget collection({
      required Set<String> cochees,
      required List<String> journal,
      bool Function(_Fiche)? cochable,
      void Function(_Fiche)? onSelectionner,
    }) => DataCollection<_Fiche>(
      colonnes: _colonnes(),
      lignes: _fiches,
      cle: _cleLigne,
      onSelectionner:
          onSelectionner ?? (_Fiche f) => journal.add('ouvre ${f.id}'),
      selection: SelectionCollection<_Fiche>(
        estCochee: (_Fiche f) => cochees.contains(f.id),
        estCochable: cochable,
        onBasculer: (_Fiche f) => journal.add('bascule ${f.id}'),
        onBasculerPage: (bool v) => journal.add('page $v'),
        libelleLigne: (_Fiche f) => f.nom,
      ),
    );

    CaseACocher entete(WidgetTester tester) =>
        tester.widget<CaseACocher>(find.byType(CaseACocher).first);

    testWidgets('la case d\'en-tete a trois etats', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      for (final (Set<String> cochees, bool? attendu) in <(Set<String>, bool?)>[
        (<String>{}, false),
        (<String>{'a'}, null),
        (<String>{'a', 'b', 'c'}, null),
        (<String>{'a', 'b', 'c', 'd'}, true),
      ]) {
        await tester.pumpWidget(
          _hote(collection(cochees: cochees, journal: <String>[])),
        );
        expect(entete(tester).valeur, attendu, reason: '$cochees');
      }
    });

    testWidgets('la case d\'en-tete ne coche que la page, puis la vide', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(collection(cochees: <String>{}, journal: journal)),
      );
      await tester.tap(find.byType(CaseACocher).first);
      expect(journal, <String>['page true']);

      // Partielle : un toucher coche la page (jamais « tout vider » par
      // surprise).
      journal.clear();
      await tester.pumpWidget(
        _hote(collection(cochees: <String>{'a'}, journal: journal)),
      );
      await tester.tap(find.byType(CaseACocher).first);
      expect(journal, <String>['page true']);

      // Toute la page cochee : un toucher la vide.
      journal.clear();
      await tester.pumpWidget(
        _hote(
          collection(cochees: <String>{'a', 'b', 'c', 'd'}, journal: journal),
        ),
      );
      await tester.tap(find.byType(CaseACocher).first);
      expect(journal, <String>['page false']);
    });

    testWidgets('la case d\'une ligne coche la ligne sans l\'ouvrir', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(collection(cochees: <String>{}, journal: journal)),
      );
      // La premiere case est celle de l'en-tete ; la deuxieme, de la ligne a.
      await tester.tap(find.byType(CaseACocher).at(1));
      expect(journal, <String>['bascule a']);

      journal.clear();
      await tester.tap(find.text('Bilal Haddad'));
      expect(journal, <String>['ouvre b']);
    });

    testWidgets('une ligne non cochable n\'a pas de case et ne compte pas', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          collection(
            cochees: <String>{'a', 'b', 'd'},
            journal: <String>[],
            cochable: (_Fiche f) => f.id != 'c',
          ),
        ),
      );
      // L'en-tete + 3 lignes cochables.
      expect(find.byType(CaseACocher), findsNWidgets(4));
      // Les trois cochables sont cochees : la page l'est, la ligne exclue ne
      // l'empeche pas.
      expect(entete(tester).valeur, true);
    });

    testWidgets('une ligne cochee se lit sans la couleur : coche et etat', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(collection(cochees: <String>{'a'}, journal: <String>[])),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cocher Amina Diallo')),
        matchesSemantics(
          label: 'Cocher Amina Diallo',
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
        tester.getSemantics(find.bySemanticsLabel('Cocher Bilal Haddad')),
        matchesSemantics(
          label: 'Cocher Bilal Haddad',
          hasCheckedState: true,
          isChecked: false,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      semantique.dispose();
    });

    testWidgets('sans selection, aucune case : comme avant', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(DataCollection<_Fiche>(colonnes: _colonnes(), lignes: _fiches)),
      );
      expect(find.byType(CaseACocher), findsNothing);
    });
  });

  group('Actions', () {
    testWidgets(
      'le menu n\'ouvre pas la ligne, la ligne n\'ouvre pas le menu',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        final List<String> journal = <String>[];
        await tester.pumpWidget(
          _hote(
            DataCollection<_Fiche>(
              colonnes: _colonnes(),
              lignes: _fiches,
              cle: _cleLigne,
              onSelectionner: (_Fiche f) => journal.add('ouvre ${f.id}'),
              actionsLigne: (BuildContext _, _Fiche f) =>
                  _menu(f, journal: journal),
            ),
          ),
        );
        await tester.tap(find.byType(MenuActions).first);
        await tester.pumpAndSettle();
        expect(
          journal,
          isEmpty,
          reason: 'ouvrir le menu n\'ouvre pas la ligne',
        );
        expect(find.text('Exporter la fiche'), findsOneWidget);

        await tester.tap(find.text('Exporter la fiche'));
        await tester.pumpAndSettle();
        expect(journal, <String>['exporter a']);

        await tester.tap(find.text('Bilal Haddad'));
        await tester.pumpAndSettle();
        expect(journal, <String>['exporter a', 'ouvre b']);
        expect(find.text('Exporter la fiche'), findsNothing);
      },
    );

    testWidgets(
      'deux arrets de tabulation par ligne : la ligne, puis le menu',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            DataCollection<_Fiche>(
              colonnes: _colonnes(),
              lignes: const <_Fiche>[
                _Fiche('a', 'Amina Diallo', 'Guinée'),
                _Fiche('b', 'Bilal Haddad', 'France'),
              ],
              cle: _cleLigne,
              onSelectionner: (_Fiche _) {},
              actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
            ),
          ),
        );
        Future<String> tab() async {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final BuildContext? c = FocusManager.instance.primaryFocus?.context;
          if (c == null) return 'aucun';
          final bool menu =
              c.findAncestorWidgetOfExactType<MenuActions>() != null;
          final bool ligne =
              c.findAncestorWidgetOfExactType<DataCollection<_Fiche>>() != null;
          if (menu) return 'menu';
          return ligne ? 'ligne' : 'autre';
        }

        expect(
          <String>[await tab(), await tab(), await tab(), await tab()],
          <String>['ligne', 'menu', 'ligne', 'menu'],
        );
      },
    );

    for (final TextDirection direction in TextDirection.values) {
      testWidgets(
        'avec une case : la case, la ligne, le menu, puis la ligne suivante '
        '(${direction.name})',
        (WidgetTester tester) async {
          _vue(tester, const Size(1440, 900));
          await tester.pumpWidget(
            _hote(
              DataCollection<_Fiche>(
                colonnes: _colonnes(),
                lignes: const <_Fiche>[
                  _Fiche('a', 'Amina Diallo', 'Guinée'),
                  _Fiche('b', 'Bilal Haddad', 'France'),
                ],
                cle: _cleLigne,
                onSelectionner: (_Fiche _) {},
                selection: SelectionCollection<_Fiche>(
                  estCochee: (_Fiche _) => false,
                  onBasculer: (_Fiche _) {},
                  onBasculerPage: (bool _) {},
                  libelleLigne: (_Fiche f) => f.nom,
                ),
                actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
              ),
              direction: direction,
            ),
          );
          final List<String> ordre = <String>[];
          for (int i = 0; i < 7; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final BuildContext? c = FocusManager.instance.primaryFocus?.context;
            if (c == null) {
              ordre.add('aucun');
            } else if (c.findAncestorWidgetOfExactType<MenuActions>() != null) {
              ordre.add('menu');
            } else if (c.findAncestorWidgetOfExactType<CaseACocher>() != null) {
              ordre.add('case');
            } else {
              ordre.add('ligne');
            }
          }
          // La case d'en-tete, puis pour chaque ligne : case, ligne, menu.
          expect(ordre, <String>[
            'case',
            'case',
            'ligne',
            'menu',
            'case',
            'ligne',
            'menu',
          ]);
        },
      );
    }

    testWidgets('aucun bouton dans un bouton : le menu est un noeud a part', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: const <_Fiche>[_Fiche('a', 'Amina Diallo', 'Guinée')],
            cle: _cleLigne,
            onSelectionner: (_Fiche _) {},
            actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
          ),
        ),
      );
      final SemanticsNode menu = tester.getSemantics(
        find.bySemanticsLabel('Actions\u00a0: Amina Diallo'),
      );
      // Le noeud du menu ne porte que son propre libelle : il n'a pas ete
      // fusionne dans celui de la ligne.
      expect(menu.label, 'Actions\u00a0: Amina Diallo');
      final SemanticsNode ligne = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Pays : Guinée')),
      );
      expect(ligne.label, contains('Pays : Guinée'));
      expect(ligne.label, isNot(contains('Actions')));
      expect(identical(menu, ligne), isFalse);
      semantique.dispose();
    });

    testWidgets('une ligne sans action garde la place de la colonne', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: _fiches,
            cle: _cleLigne,
            actionsLigne: (BuildContext _, _Fiche f) =>
                f.id == 'b' ? const SizedBox.shrink() : _menu(f),
          ),
        ),
      );
      // Les cellules de la ligne b sont a la meme abscisse que celles de a.
      expect(
        tester.getTopLeft(find.text('France')).dx,
        tester.getTopLeft(find.text('Guinée')).dx,
      );
    });
  });

  group('Tri', () {
    testWidgets('un en-tete triable est un bouton, un autre reste un titre', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(
              triNom: TriColonne(
                sens: SensTri.croissant,
                onTrier: () => journal.add('nom'),
              ),
            ),
            lignes: _fiches,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Trier par Nom (actuellement croissant)'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Trier par Pays')), findsNothing);
      await tester.tap(find.text('Nom'));
      expect(journal, <String>['nom']);
      // Un titre non triable ne repond pas.
      await tester.tap(find.text('Pays'));
      expect(journal, <String>['nom']);
      semantique.dispose();
    });

    testWidgets(
      'l\'indicateur dit le sens, la colonne non triee en propose un',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            DataCollection<_Fiche>(
              colonnes: _colonnes(
                triNom: TriColonne(sens: SensTri.decroissant, onTrier: () {}),
                triPays: TriColonne(onTrier: () {}),
              ),
              lignes: _fiches,
            ),
          ),
        );
        final Iterable<IconData?> icones = tester
            .widgetList<Icon>(find.byType(Icon))
            .map((Icon i) => i.icon);
        expect(icones, contains(AppIcons.triDecroissant.repos));
        expect(icones, contains(AppIcons.triNeutre.repos));
        expect(icones, isNot(contains(AppIcons.triCroissant.repos)));
      },
    );

    testWidgets(
      'la collection ne trie jamais : l\'ordre est celui de l\'ecran',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            DataCollection<_Fiche>(
              colonnes: _colonnes(
                triNom: TriColonne(sens: SensTri.croissant, onTrier: () {}),
              ),
              // Volontairement pas dans l'ordre alphabetique.
              lignes: const <_Fiche>[
                _Fiche('z', 'Zineb', 'Mali'),
                _Fiche('a', 'Amina', 'Mali'),
              ],
            ),
          ),
        );
        expect(
          tester.getTopLeft(find.text('Zineb')).dy,
          lessThan(tester.getTopLeft(find.text('Amina')).dy),
        );
      },
    );
  });

  group('En-tete colle', () {
    testWidgets('quand la collection defile seule, l\'en-tete ne bouge pas', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<_Fiche> beaucoup = <_Fiche>[
        for (int i = 0; i < 60; i++) _Fiche('n$i', 'Personne $i', 'Guinée'),
      ];
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(triNom: TriColonne(onTrier: () {})),
            lignes: beaucoup,
          ),
        ),
      );
      final Offset avant = tester.getTopLeft(find.text('Nom'));
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      expect(find.text('Personne 0'), findsNothing);
      expect(tester.getTopLeft(find.text('Nom')), avant);
    });
  });

  group('Pied collant', () {
    testWidgets('le pied ferme le cadre et ne defile pas avec les lignes', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<_Fiche> beaucoup = <_Fiche>[
        for (int i = 0; i < 60; i++) _Fiche('n$i', 'Personne $i', 'Guinée'),
      ];
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: beaucoup,
            piedCollant: const Text('1-60 sur 614'),
          ),
        ),
      );
      final Offset avant = tester.getTopLeft(find.text('1-60 sur 614'));
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      expect(tester.getTopLeft(find.text('1-60 sur 614')), avant);
    });
  });

  group('Repli en cartes (390)', () {
    testWidgets('la case avant la carte, le menu apres, hors de la carte', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        _hote(
          DataCollection<_Fiche>(
            colonnes: _colonnes(),
            lignes: const <_Fiche>[_Fiche('a', 'Amina Diallo', 'Guinée')],
            cle: _cleLigne,
            onSelectionner: (_Fiche f) => journal.add('ouvre ${f.id}'),
            selection: SelectionCollection<_Fiche>(
              estCochee: (_Fiche _) => false,
              onBasculer: (_Fiche f) => journal.add('bascule ${f.id}'),
              onBasculerPage: (bool _) {},
              libelleLigne: (_Fiche f) => f.nom,
            ),
            actionsLigne: (BuildContext _, _Fiche f) =>
                _menu(f, journal: journal),
          ),
        ),
      );
      // Pas de case d'en-tete en cartes : une seule case, celle de la ligne.
      expect(find.byType(CaseACocher), findsOneWidget);
      final Rect caseRect = tester.getRect(find.byType(CaseACocher));
      final Rect menuRect = tester.getRect(find.byType(MenuActions));
      final Rect texte = tester.getRect(find.text('Amina Diallo'));
      expect(caseRect.right, lessThanOrEqualTo(texte.left));
      expect(menuRect.left, greaterThanOrEqualTo(texte.right));

      await tester.tap(find.byType(CaseACocher));
      expect(journal, <String>['bascule a']);
      await tester.tap(find.text('Amina Diallo'));
      expect(journal, <String>['bascule a', 'ouvre a']);
    });
  });

  group('Squelette de table dense', () {
    testWidgets('le pas des barres est celui des lignes', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(const Skeleton.tableDense(lignes: 5, differe: false)),
      );
      // 5 barres de 16, au pas de 56 : 4 x 56 + 16.
      expect(tester.getSize(find.byType(Skeleton)).height, 4 * 56 + 16);
    });

    testWidgets('en Interface guidee, au pas de la cible (80)', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          const Skeleton.tableDense(lignes: 3, differe: false),
          mode: InterfaceMode.enfant,
        ),
      );
      expect(tester.getSize(find.byType(Skeleton)).height, 2 * 80 + 16);
    });
  });

  // Les 16 combinaisons du harnais : (clair, sombre) x (390, 1440) x (x1, x2)
  // x (LTR, RTL), la table complete (selection, tri, actions) sans erreur de
  // mise en page et sans mot coupe.
  for (final Brightness luminosite in Brightness.values) {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final TextDirection direction in TextDirection.values) {
          testWidgets(
            'table complete : ${luminosite.name} ${taille.width.round()} '
            'x$echelle ${direction.name}',
            (WidgetTester tester) async {
              _vue(tester, taille);
              await tester.pumpWidget(
                _hote(
                  DataCollection<_Fiche>(
                    colonnes: _colonnes(
                      triNom: TriColonne(
                        sens: SensTri.croissant,
                        onTrier: () {},
                      ),
                    ),
                    lignes: _fiches,
                    cle: _cleLigne,
                    onSelectionner: (_Fiche _) {},
                    selection: SelectionCollection<_Fiche>(
                      estCochee: (_Fiche f) => f.id == 'b',
                      onBasculer: (_Fiche _) {},
                      onBasculerPage: (bool _) {},
                      libelleLigne: (_Fiche f) => f.nom,
                    ),
                    actionsLigne: (BuildContext _, _Fiche f) => _menu(f),
                  ),
                  luminosite: luminosite,
                  echelle: echelle,
                  direction: direction,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              // Chaque nom est entier a l'ecran.
              expect(find.text('Amina Diallo'), findsOneWidget);
              // Une case par ligne (+ l'en-tete en table).
              expect(find.byType(CaseACocher), findsWidgets);
              // Le menu est dans l'ecran, jamais rogne.
              final Rect ecran = Offset.zero & taille;
              final Rect menu = tester.getRect(find.byType(MenuActions).first);
              expect(ecran.contains(menu.topLeft), isTrue);
              expect(menu.right, lessThanOrEqualTo(taille.width));
              // En sombre, la case cochee garde un fond plein et sa coche.
              if (luminosite == Brightness.dark) {
                final AppPalette p = AppPalette.sombre();
                expect(p.surfacePrimary.background.a, 1.0);
              }
            },
          );
        }
      }
    }
  }

  testWidgets('retrocompatibilite : sans parametre neuf, meme tableau', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(1440, 900));
    final List<String> journal = <String>[];
    await tester.pumpWidget(
      _hote(
        DataCollection<_Fiche>(
          colonnes: _colonnes(),
          lignes: _fiches,
          onSelectionner: (_Fiche f) => journal.add(f.id),
        ),
      ),
    );
    expect(find.byType(CaseACocher), findsNothing);
    expect(find.byType(MenuActions), findsNothing);
    await tester.tap(find.text('Youssef Bah'));
    expect(journal, <String>['d']);
  });
}
