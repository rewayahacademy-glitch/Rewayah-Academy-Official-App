// COM-RC tour 7, lot L : la Classe du tuteur sur le jeu de demonstration
// An-Nour (COM-CAPT tour 6, defaut 5 ; REVUE_COM-R §9.2) et les defauts vus a
// sa capture :
// - la page, la carte de seance et l'annonce disent la meme Classe, l'eleve
//   est Adam, aucun « Eleve A1 » ni « Classe fictive A » ; la seance ouverte
//   passe avant les annonces (R-16), visible a l'image ;
// - la carte de seance ne coupe aucun mot (« Diman/che », « Duré/e »,
//   « 14:1/0 » a 320 px en texte x2) et ne casse pas « 45 / min » ;
// - le nom « Classe An-Nour » ne passe pas a la ligne dans « An- / Nour »
//   (titre de la page a 320, titre de la carte a 320 en texte x2) ;
// - le point d'etat reste sur la premiere ligne de « Salle ouverte ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/contexte_classe.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import 'demo_an_nour.dart';
import 'support_classe.dart';

/// L'heure des fixtures des Communications (dimanche 4 octobre, 14 h a
/// Paris).
final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesClasseAnNour(_maintenant),
        ...annoncesClasseAnNour(_maintenant),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
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
  routeur.go(Routes.classePour(classeA, eleveId: eleveA1));
  await stabiliser(tester);
  expect(find.byType(ClasseTuteurPage), findsOneWidget);
}

/// Les textes rendus sous [ou].
List<String> _textes(WidgetTester tester, Finder ou) => <String>[
  for (final Text texte in tester.widgetList<Text>(
    find.descendant(of: ou, matching: find.byType(Text)),
  ))
    texte.data ?? texte.textSpan?.toPlainText() ?? '',
];

void main() {
  // Les vraies polices : un mot coupe se mesure sur les glyphes rendus.
  setUpAll(chargerPolicesDuDepot);

  group('Jeu de demonstration An-Nour : une seule Classe', () {
    testWidgets('page, carte et annonce disent la Classe An-Nour, eleve Adam', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      final String nom = libelleAnNour();
      final Finder page = find.byType(ClasseTuteurPage);
      final Finder carte = find.byType(CarteSeanceClasse);
      final Finder annonces = find.byType(AnnoncesDeClasse);
      expect(carte, findsOneWidget);
      expect(annonces, findsOneWidget);

      // Le titre de la page et celui de la carte : le nom de la Classe
      // (trait d'union insecable a l'affichage).
      expect(find.text(nomClasseInsecable(nom)), findsNWidgets(2));
      // L'annonce dit la meme Classe.
      expect(
        _textes(tester, annonces).where((String s) => s.contains(nom)),
        isNotEmpty,
        reason: "L'annonce doit nommer la Classe de la page",
      );
      // L'eleve et l'enseignante du jeu : Adam, Sayyida Mariam.
      expect(find.textContaining(prenomAdam), findsWidgets);
      expect(find.textContaining(prenomMariam), findsWidgets);
      // Aucune etiquette de fixture a cote de l'annonce.
      final List<String> tout = <String>[
        ..._textes(tester, page),
        ..._textes(tester, find.byType(Scaffold).first),
      ];
      for (final String s in tout) {
        expect(s, isNot(contains('fictive')), reason: s);
        expect(s, isNot(contains('Eleve')), reason: s);
        expect(s, isNot(contains('Enseignant X')), reason: s);
      }
    });

    testWidgets('R-16 : la seance ouverte passe avant les annonces', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      final double carte = tester.getTopLeft(find.byType(CarteSeanceClasse)).dy;
      final double annonces = tester
          .getTopLeft(find.byType(AnnoncesDeClasse))
          .dy;
      expect(carte, lessThan(annonces));
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsOneWidget);
    });
  });

  group('Carte de seance : aucun mot coupe', () {
    for (final (Size taille, double echelle) cas in <(Size, double)>[
      (const Size(320, 640), 1),
      (const Size(320, 640), 2),
      (const Size(390, 844), 1),
      (const Size(390, 844), 2),
      (const Size(1440, 900), 1),
      (const Size(1440, 900), 2),
    ]) {
      final (Size taille, double echelle) = cas;
      testWidgets('${taille.width.toInt()} px, texte x${echelle.toInt()}', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: taille, echelle: echelle);
        final Finder carte = find.byType(CarteSeanceClasse);
        await tester.ensureVisible(carte);
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, carte);
        // La duree sur UNE ligne, jamais « 45 / min ».
        final Finder duree = find.descendant(
          of: carte,
          matching: find.text('45 min'),
        );
        expect(duree, findsOneWidget);
        final RenderBox boite = tester.renderObject<RenderBox>(duree);
        final TextStyle style =
            tester
                .widget<RichText>(
                  find.descendant(of: duree, matching: find.byType(RichText)),
                )
                .text
                .style ??
            const TextStyle();
        final TextPainter une = TextPainter(
          text: TextSpan(text: '45 min', style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(echelle),
        )..layout();
        expect(boite.size.height, lessThan(une.height * 1.5));
        une.dispose();
      });
    }
  });

  group('Le nom « Classe An-Nour » reste entier', () {
    for (final (Size taille, double echelle) cas in <(Size, double)>[
      (const Size(320, 640), 1),
      (const Size(320, 640), 2),
    ]) {
      final (Size taille, double echelle) = cas;
      testWidgets(
        'titre de la page et de la carte a ${taille.width.toInt()} px, '
        'texte x${echelle.toInt()}',
        (WidgetTester tester) async {
          await _monter(tester, taille: taille, echelle: echelle);
          final Finder titres = find.text(nomClasseInsecable(libelleAnNour()));
          expect(titres, findsNWidgets(2));
          for (final Element e in titres.evaluate()) {
            final Finder titre = find.byElementPredicate(
              (Element x) => identical(x, e),
            );
            await tester.ensureVisible(titre);
            await stabiliser(tester);
            verifierAucunMotCoupe(tester, titre);
          }
        },
      );
    }
  });

  testWidgets('le point d etat reste sur la premiere ligne (320 px, x2)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(320, 640), echelle: 2);
    final Finder carte = find.byType(CarteSeanceClasse);
    final Finder etat = find.descendant(
      of: carte,
      matching: find.text(LibellesGroupe.salleOuverteCourt),
    );
    await tester.ensureVisible(etat);
    await stabiliser(tester);
    final Finder point = find.descendant(
      of: carte,
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is SizedBox &&
            w.width == StatusPill.diametrePastille &&
            w.height == StatusPill.diametrePastille,
      ),
    );
    expect(point, findsOneWidget);
    // L'etat et son compte a rebours passent sur deux lignes a cette taille.
    final Finder compte = find.descendant(
      of: carte,
      matching: find.textContaining('min'),
    );
    expect(
      tester.getTopLeft(compte.first).dy,
      greaterThan(tester.getBottomLeft(etat).dy - 1),
      reason: 'Le compte a rebours doit passer sous l etat',
    );
    // Le point est centre sur la ligne de l'etat, pas entre les deux lignes.
    expect(
      tester.getCenter(point).dy,
      moreOrLessEquals(tester.getCenter(etat).dy, epsilon: 2),
    );
  });
}
