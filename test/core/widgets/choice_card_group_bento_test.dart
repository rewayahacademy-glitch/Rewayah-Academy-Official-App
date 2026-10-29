// Lot E2 (decision du directeur du 17/10/2026) : sur grand ecran, les choix
// passent en bento. Jamais plusieurs cartes de meme taille cote a cote ;
// chaque choix est explique, parfois avec un exemple, et illustre ; toute la
// carte reste la cible (E1). Sous 900 px, la liste du telephone reste, avec
// son explication.
//
// Contre-epreuve : sur le code d'avant E2, ce fichier ne compile pas
// (`OptionChoix.explication`, `IllustrationChoix`, `etenduesBento` absents) ;
// a 1440 les deux cartes de l'etape « usage » y font toutes deux 1136 x 112.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../../support/harnais.dart';
import '../../support/hote_theme.dart';

const List<AppIcon> _icones = <AppIcon>[
  AppIcons.profil,
  AppIcons.foyer,
  AppIcons.eleves,
  AppIcons.livreOuvert,
  AppIcons.horloge,
  AppIcons.classes,
  AppIcons.suivi,
  AppIcons.cours,
];

Key _cle(int i) => Key('opt-$i');

List<OptionChoix> _options(int n) => <OptionChoix>[
  for (int i = 0; i < n; i++)
    OptionChoix(
      valeur: 'v$i',
      libelle: 'Option $i',
      explication: 'Explication de l option $i, quand la choisir.',
      exemple: i.isEven ? 'un cas concret pour l option $i.' : null,
      icone: _icones[i % _icones.length],
      illustration: IllustrationChoix(
        _icones[i % _icones.length],
        autour: <AppIcon>[_icones[(i + 1) % _icones.length]],
      ),
      cle: _cle(i),
    ),
];

Future<List<ReponseChoix>> _monter(
  WidgetTester tester, {
  required int n,
  Size taille = const Size(1440, 900),
  bool coteACote = false,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (echelle != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = echelle;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final List<ReponseChoix> recues = <ReponseChoix>[];
  await tester.pumpWidget(
    hoteTheme(
      Directionality(
        textDirection: sens,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ChoiceCardGroup(
            options: _options(n),
            autoriserSaisieLibre: false,
            coteACote: coteACote,
            onChange: recues.add,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return recues;
}

/// Vrai quand deux places se touchent sur un cote (meme ligne, colonnes
/// voisines, ou meme colonne, lignes voisines).
bool _voisines(PlacementBento a, PlacementBento b) {
  final bool memeBande =
      a.ligne < b.ligne + b.lignes && b.ligne < a.ligne + a.lignes;
  final bool memeColonne =
      a.colonne < b.colonne + b.colonnes && b.colonne < a.colonne + a.colonnes;
  return (memeBande &&
          (a.colonne + a.colonnes == b.colonne ||
              b.colonne + b.colonnes == a.colonne)) ||
      (memeColonne &&
          (a.ligne + a.lignes == b.ligne || b.ligne + b.lignes == a.ligne));
}

void main() {
  group('etenduesBento', () {
    for (int n = 1; n <= 9; n++) {
      test('$n options : grille pleine, aucune carte identique voisine', () {
        final List<EtendueBento> e = ChoiceCardGroup.etenduesBento(n);
        expect(e, hasLength(n));
        final List<PlacementBento> p = placerBento(e, 4);
        // Les etendues demandees sont tenues : le comblement des trous n'a
        // rien etire.
        for (int i = 0; i < n; i++) {
          expect(p[i].colonnes, e[i].colonnes, reason: 'tuile $i');
          expect(p[i].lignes, e[i].lignes, reason: 'tuile $i');
        }
        if (n <= 5) {
          expect(e.toSet(), hasLength(n), reason: 'tailles toutes distinctes');
        }
        for (int i = 0; i < n; i++) {
          for (int j = i + 1; j < n; j++) {
            // Jusqu'a 5 : aucune voisine de meme taille, dans aucun sens.
            // Au-dela : jamais deux cartes identiques cote a cote dans une
            // meme rangee (demande du directeur).
            final bool touche = n <= 5
                ? _voisines(p[i], p[j])
                : _voisines(p[i], p[j]) && p[i].ligne == p[j].ligne;
            if (touche) {
              expect(e[i], isNot(e[j]), reason: 'tuiles $i et $j voisines');
            }
          }
        }
      });
    }
  });

  for (int n = 2; n <= 5; n++) {
    testWidgets('1440, $n options : bento, tailles variees, illustrees', (
      WidgetTester tester,
    ) async {
      await _monter(tester, n: n);
      expect(find.byType(GrilleBento), findsOneWidget);
      expect(find.byType(VueIllustrationChoix), findsNWidgets(n));
      final Set<Size> tailles = <Size>{
        for (int i = 0; i < n; i++) tester.getSize(find.byKey(_cle(i))),
      };
      expect(tailles.length, greaterThan(1), reason: 'pas toutes identiques');
      if (n <= 5) {
        expect(tailles, hasLength(n), reason: '$tailles');
      }
      for (int i = 0; i < n; i++) {
        expect(
          find.text('Explication de l option $i, quand la choisir.'),
          findsOneWidget,
        );
      }
      expect(
        find.text(t.choix.exemple(texte: 'un cas concret pour l option 0.')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final bool coteACote in <bool>[false, true]) {
    testWidgets('1440 ${coteACote ? 'cote a cote' : 'liste'} : toute la '
        'carte est la cible', (WidgetTester tester) async {
      const int n = 4;
      final List<ReponseChoix> recues = await _monter(
        tester,
        n: n,
        coteACote: coteACote,
      );
      for (int i = 0; i < n; i++) {
        final Rect carte = tester.getRect(find.byKey(_cle(i)));
        for (final Offset point in <Offset>[
          carte.center,
          carte.topLeft + const Offset(6, 6),
          carte.bottomRight - const Offset(6, 6),
          carte.centerRight - const Offset(6, 0),
        ]) {
          await tester.tapAt(point);
          await tester.pumpAndSettle();
          expect(recues.last.valeurs, <String>{'v$i'}, reason: 'carte $i');
          // Revenir a une autre carte.
          await tester.tap(find.byKey(_cle((i + 1) % n)));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets('1440 texte x2 et arabe : rien ne deborde, repere cote start', (
    WidgetTester tester,
  ) async {
    await _monter(tester, n: 5, echelle: 2, sens: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final Rect carte = tester.getRect(find.byKey(_cle(0)));
    final Rect repere = tester.getRect(
      find.descendant(
        of: find.byKey(_cle(0)),
        matching: find.byType(RadioChoix),
      ),
    );
    expect(carte.right - repere.right, lessThanOrEqualTo(24));
  });

  testWidgets('390 : liste du telephone, explication visible, pas de bento', (
    WidgetTester tester,
  ) async {
    await _monter(tester, n: 3, taille: const Size(390, 844));
    expect(find.byType(GrilleBento), findsNothing);
    expect(find.byType(VueIllustrationChoix), findsNothing);
    final Set<double> largeurs = <double>{
      for (int i = 0; i < 3; i++) tester.getSize(find.byKey(_cle(i))).width,
    };
    expect(largeurs, hasLength(1));
    for (int i = 0; i < 3; i++) {
      expect(
        find.text('Explication de l option $i, quand la choisir.'),
        findsOneWidget,
      );
    }
  });

  group('inscription a 1440', () {
    Future<void> monterInscription(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.inscription,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.inscription,
              builder: (BuildContext _, GoRouterState _) =>
                  const InscriptionPage(),
            ),
            GoRoute(
              path: Routes.inscriptionUsage,
              builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
            ),
            GoRoute(
              path: Routes.inscriptionIdentite,
              builder: (BuildContext _, GoRouterState _) =>
                  const IdentiteEtape(),
            ),
            GoRoute(
              path: Routes.inscriptionGenre,
              builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> taper(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    /// Les cartes d'un groupe : la boite de chaque option, dans l'ordre.
    List<Size> cartes(WidgetTester tester, Key groupe) => <Size>[
      for (final Element e
          in find
              .descendant(
                of: find.byKey(groupe),
                matching: find.byType(VueIllustrationChoix),
              )
              .evaluate())
        tester.getSize(
          find
              .ancestor(
                of: find.byWidget(e.widget),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        ),
    ];

    testWidgets('usage : deux choix egaux, explications, exemples, carte '
        'entiere cliquable', (WidgetTester tester) async {
      await monterInscription(tester);
      const Key usage = Key('inscription-usage');
      Size carte(String titre) => tester.getSize(
        find
            .ancestor(
              of: find.descendant(
                of: find.byKey(usage),
                matching: find.text(titre),
              ),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final List<Size> tailles = <Size>[
        carte(t.inscription.usage.moiTitre),
        carte(t.inscription.usage.familleTitre),
      ];
      // Admission, lot B (directeur, 29/10/2026) : « Je m'inscris pour moi »
      // et « J'inscris mon enfant », deux grands choix de meme taille, jamais
      // le bento inegal.
      expect(tailles.first, tailles.last);
      expect(find.text(t.inscription.usage.moiDescription), findsOneWidget);
      expect(
        find.text(t.choix.exemple(texte: t.inscription.usage.familleExemple)),
        findsOneWidget,
      );
      // Un appui dans la marge de la carte « J'inscris mon enfant », loin du
      // texte, la retient et ouvre la sous-question.
      final Rect famille = tester.getRect(
        find
            .ancestor(
              of: find.text(t.inscription.usage.familleTitre),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      await tester.tapAt(famille.bottomLeft + const Offset(6, -6));
      await tester.pumpAndSettle();
      expect(find.text(t.inscription.usage.coursQuestion), findsOneWidget);
      const Key cours = Key('inscription-parent-suit-des-cours');
      final List<Size> taillesCours = cartes(tester, cours);
      expect(taillesCours, hasLength(2));
      expect(taillesCours.first, isNot(taillesCours.last));
      expect(
        find.text(t.inscription.usage.coursNonExplication),
        findsOneWidget,
      );
    });

    testWidgets('genre : tailles differentes, explication pour le tuteur', (
      WidgetTester tester,
    ) async {
      await monterInscription(tester);
      await taper(tester, find.text(t.inscription.usage.moiTitre));
      await taper(tester, find.text(t.commun.continuer));
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const Key('inscription-nom')),
        'Diallo',
      );
      await taper(tester, find.text(t.commun.continuer));
      final List<Size> tailles = cartes(tester, const Key('inscription-genre'));
      expect(tailles, hasLength(2));
      expect(tailles.first, isNot(tailles.last));
      expect(find.text(t.inscription.genreFemmeExplication), findsOneWidget);
      final Rect femme = tester.getRect(
        find
            .ancestor(
              of: find.text(t.inscription.genreFemme),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      await tester.tapAt(femme.topRight + const Offset(-6, 6));
      await tester.pumpAndSettle();
      final RadioChoix radio = tester.widget<RadioChoix>(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(t.inscription.genreFemme),
                matching: find.byType(AnimatedContainer),
              )
              .first,
          matching: find.byType(RadioChoix),
        ),
      );
      expect(radio.retenue, isTrue);
    });
  });
}
