// COM-RC tour 7, lot L, apres revue : les defauts que la revue du lot a vus
// sur ses captures (com_annonce_classe_tuteur_390_clair, _390_rtl_clair) et
// dans son jeu de demonstration.
//
// - la date ne se coupe pas entre le jour et le mois (« Dimanche 4 /
//   octobre ») : le nombre est lie au mot suivant par une espace insecable ;
// - en arabe, la carte de seance est entierement en arabe et dans l'ordre de
//   lecture (« 45 د », « 14:10 باريس », plus de « min 45 » ni de « Paris
//   14:10 » ni de point en tete de phrase) ;
// - la demonstration dit la meme enseignante sur la Classe : l'annonce de la
//   Classe An-Nour est signee « Sayyida Mariam », comme la page et la carte ;
// - le compte a rebours arrondit au superieur : a 14:00 et une poussiere pour
//   un cours a 14:10, « Cours dans 10 min », jamais « 9 min » ;
// - le nom « Classe An-Nour » reste entier aussi dans le sous-titre des
//   sous-pages et dans la ligne « Annonce · Classe An-Nour » ;
// - le planning de la Classe An-Nour se lit a 320 px en texte x2 (la
//   pastille passait a cote de la date et la reduisait a « Di / ma / nc »).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/_dev/playground/persona.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/contexte_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/planning_classe_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart'
    show RoleDemoCommunications;

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
  AppLocale langue = AppLocale.fr,
  String? chemin,
}) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
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
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(chemin ?? Routes.classePour(classeA, eleveId: eleveA1));
  await stabiliser(tester);
}

/// Le paragraphe rendu dont le texte contient [morceau], sous [ou].
RenderParagraph _paragraphe(WidgetTester tester, Finder ou, String morceau) =>
    tester
        .renderObjectList<RenderParagraph>(
          find.descendant(of: ou, matching: find.byType(RichText)),
        )
        .firstWhere(
          (RenderParagraph p) => p.text.toPlainText().contains(morceau),
          orElse: () => throw StateError('« $morceau » introuvable'),
        );

/// Les boites de [morceau] dans [p].
List<TextBox> _boites(RenderParagraph p, String morceau) {
  final String texte = p.text.toPlainText();
  final int debut = texte.indexOf(morceau);
  expect(debut, isNonNegative, reason: '« $morceau » dans « $texte »');
  return p.getBoxesForSelection(
    TextSelection(baseOffset: debut, extentOffset: debut + morceau.length),
  );
}

/// Vrai quand toutes les [boites] sont sur la meme ligne : leurs hauteurs se
/// recouvrent (un chiffre et une lettre arabe n'ont pas le meme haut de
/// boite, mais partagent la ligne).
bool _uneLigne(List<TextBox> boites) {
  final double hautMax = boites
      .map((TextBox b) => b.top)
      .reduce((double a, double b) => a > b ? a : b);
  final double basMin = boites
      .map((TextBox b) => b.bottom)
      .reduce((double a, double b) => a < b ? a : b);
  return hautMax < basMin;
}

/// Le bord gauche et le bord droit de [morceau] dans [p].
({double gauche, double droite}) _bords(RenderParagraph p, String morceau) {
  final List<TextBox> boites = _boites(p, morceau);
  return (
    gauche: boites.map((TextBox b) => b.left).reduce((a, b) => a < b ? a : b),
    droite: boites.map((TextBox b) => b.right).reduce((a, b) => a > b ? a : b),
  );
}

/// Les textes rendus sous [ou].
List<String> _textes(WidgetTester tester, Finder ou) => <String>[
  for (final RenderParagraph p in tester.renderObjectList<RenderParagraph>(
    find.descendant(of: ou, matching: find.byType(RichText)),
  ))
    p.text.toPlainText(),
];

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La bibliotheque arabe est differee : chargee une fois hors du
    // `FakeAsync` des tests, pour que `setLocaleSync` la trouve.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('Date : le jour et son mois restent ensemble', () {
    test('le nombre est lie au mot suivant par une espace insecable', () {
      expect(
        nombresLiesAuMotSuivant('Dimanche 4 octobre'),
        'Dimanche 4 octobre',
      );
      expect(nombresLiesAuMotSuivant('الأحد 4 أكتوبر'), 'الأحد 4 أكتوبر');
      // Un nombre en fin de texte ne change rien.
      expect(nombresLiesAuMotSuivant('Niveau 1'), 'Niveau 1');
    });

    for (final (Size taille, double echelle) cas in <(Size, double)>[
      (const Size(390, 844), 1),
      (const Size(320, 640), 1),
      (const Size(320, 640), 2),
      (const Size(768, 1024), 1),
      (const Size(1440, 900), 2),
    ]) {
      final (Size taille, double echelle) = cas;
      testWidgets('carte de seance, ${taille.width.toInt()} px, texte '
          'x${echelle.toInt()} : « 4 octobre » sur une seule ligne', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: taille, echelle: echelle);
        final Finder carte = find.byType(CarteSeanceClasse);
        await tester.ensureVisible(carte);
        await stabiliser(tester);
        final RenderParagraph date = _paragraphe(tester, carte, 'octobre');
        final String texte = date.text.toPlainText();
        final String groupe = texte.substring(texte.indexOf('4'));
        expect(
          _uneLigne(_boites(date, groupe)),
          isTrue,
          reason: '« $texte » : « 4 » seul en fin de ligne',
        );
        // L'heure et sa ville sur une ligne, jamais « 14:10 / Paris ».
        final RenderParagraph heure = _paragraphe(tester, carte, '14:10');
        expect(
          _uneLigne(_boites(heure, heure.text.toPlainText())),
          isTrue,
          reason: heure.text.toPlainText(),
        );
      });
    }
  });

  group('Arabe : la carte de seance se lit de droite a gauche', () {
    testWidgets('aucun mot francais dans la carte (390 px, RTL)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844), langue: AppLocale.ar);
      final Finder carte = find.byType(CarteSeanceClasse);
      expect(carte, findsOneWidget);
      final List<String> latins = <String>[
        for (final String s in _textes(tester, carte))
          if (RegExp('[A-Za-zÀ-ÿ]').hasMatch(s)) s,
      ];
      expect(latins, isEmpty, reason: 'Libelles restes en francais');
    });

    testWidgets('« 45 د », « 14:10 باريس » et le point en fin de phrase', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844), langue: AppLocale.ar);
      final Finder carte = find.byType(CarteSeanceClasse);
      // La duree : le nombre a droite de son unite (lecture de droite a
      // gauche), jamais « min 45 ».
      final RenderParagraph duree = _paragraphe(tester, carte, '45');
      expect(duree.text.toPlainText(), isNot(contains('min')));
      expect(
        _bords(duree, '45').gauche,
        greaterThan(_bords(duree, 'د').droite - 0.5),
      );
      // L'heure puis la ville, lues de droite a gauche.
      final RenderParagraph heure = _paragraphe(tester, carte, '14:10');
      expect(heure.text.toPlainText(), isNot(contains('Paris')));
      expect(
        _bords(heure, '14:10').gauche,
        greaterThan(_bords(heure, 'باريس').droite - 0.5),
      );
      // La phrase d'observation : son point est a gauche, en fin de lecture.
      final String phrase = t.classe.observation.motif.garantieServeurAbsente;
      final RenderParagraph observation = _paragraphe(tester, carte, phrase);
      final int fin = phrase.length - 1;
      expect(phrase[fin], '.');
      expect(
        _bords(observation, '.').droite,
        lessThan(_bords(observation, phrase.substring(0, fin)).gauche + 0.5),
      );
    });
  });

  group('Une seule enseignante dans la demonstration', () {
    testWidgets("l'annonce de la Classe An-Nour est signee Sayyida Mariam", (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      final Finder annonces = find.byType(AnnoncesDeClasse);
      final List<String> textes = _textes(tester, annonces);
      expect(
        textes.where((String s) => s.startsWith('Sayyida Mariam, le ')),
        isNotEmpty,
        reason: textes.join(' | '),
      );
      expect(
        textes.where((String s) => s.contains(t.com.annonces.demo.enseignante)),
        isEmpty,
      );
      // La carte de seance dit la meme personne.
      expect(
        find.descendant(
          of: find.byType(CarteSeanceClasse),
          matching: find.text('Sayyida Mariam'),
        ),
        findsOneWidget,
      );
    });

    test('les annonces de demonstration de la Classe An-Nour', () {
      final List<AnnonceClasse> nour = annoncesDemo(
        RoleDemoCommunications.tuteur,
        _maintenant,
      )[ClassesDemoAnnonces.nour]!;
      for (final AnnonceClasse a in nour) {
        expect(a.auteur?.nomAffiche, ClassesDemoAnnonces.enseignanteNourNommee);
        expect(a.auteur?.fonction, isNull);
      }
    });
  });

  group('Compte a rebours : arrondi au superieur', () {
    test('minutesAvant', () {
      expect(LibellesGroupe.minutesAvant(const Duration(minutes: 10)), 10);
      expect(
        LibellesGroupe.minutesAvant(
          const Duration(minutes: 10) - const Duration(milliseconds: 1),
        ),
        10,
      );
      expect(
        LibellesGroupe.minutesAvant(
          const Duration(minutes: 9, microseconds: 1),
        ),
        10,
      );
      expect(LibellesGroupe.minutesAvant(const Duration(seconds: 59)), 0);
      expect(LibellesGroupe.minutesAvant(const Duration(seconds: 61)), 2);
    });

    test('a 14:00 et une poussiere, un cours a 14:10 est dans 10 min', () {
      expect(
        LibellesGroupe.compteARebours(
          const Duration(minutes: 10) - const Duration(milliseconds: 1),
        ),
        LibellesGroupe.insecable(t.tc.groupe.temps.dansMinutes(minutes: 10)),
      );
      // Sous une minute : imminent, jamais « dans 0 min ».
      expect(
        LibellesGroupe.compteARebours(const Duration(seconds: 30)),
        t.tc.groupe.temps.imminent,
      );
    });

    testWidgets('la carte dit « Cours dans 10 min » a cote de 14:10', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      expect(
        find.descendant(
          of: find.byType(CarteSeanceClasse),
          // Insecable a l'ecran (DUREE-INSECABLE-1, JONCTION-LIGNES-1).
          matching: find.text(
            LibellesGroupe.insecable(
              t.tc.groupe.temps.dansMinutes(minutes: 10),
            ),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('Le nom « Classe An-Nour » reste entier partout', () {
    testWidgets('sous-titre du planning et ligne de l annonce', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      final Finder ligne = find.descendant(
        of: find.byType(AnnoncesDeClasse),
        matching: find.textContaining('An-⁠Nour'),
      );
      expect(ligne, findsWidgets);
      await _monter(
        tester,
        taille: const Size(390, 844),
        chemin: cheminClasse(classeA, eleveA1, 'planning'),
      );
      expect(find.byType(PlanningClassePage), findsOneWidget);
      expect(find.textContaining('An-⁠Nour · '), findsOneWidget);
    });
  });

  group('Libelles du jeu de donnees', () {
    test(
      'banc d essai : plus de « interface enfant » (Mode Accessibilite)',
      () {
        final List<String> libelles = <String>[
          for (final Persona p in personasDuBench(maintenant: _maintenant))
            p.libelle,
        ];
        expect(libelles, contains('Élève (Mode Accessibilité)'));
        expect(
          libelles.where((String l) => l.toLowerCase().contains('enfant')),
          isEmpty,
        );
      },
    );

    test('donnees de test des Messages : « Élève », « Parent d Élève »', () {
      final String source = File(
        'test/features/com_messages/entrees_etats_test.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('Eleve 1')));
      expect(source, isNot(contains(r'Eleve $i')));
      expect(source, isNot(contains('Parent de Eleve')));
      expect(source, contains("Parent d'Élève 1"));
    });
  });

  group('Planning de la Classe An-Nour', () {
    for (final (Size taille, double echelle, AppLocale langue) cas
        in <(Size, double, AppLocale)>[
          (const Size(390, 844), 1, AppLocale.fr),
          (const Size(320, 640), 2, AppLocale.fr),
          (const Size(390, 844), 1, AppLocale.ar),
        ]) {
      final (Size taille, double echelle, AppLocale langue) = cas;
      testWidgets('${taille.width.toInt()} px, texte x${echelle.toInt()}, '
          '${langue.languageCode} : trois seances, aucun mot coupe', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille: taille,
          echelle: echelle,
          langue: langue,
          chemin: cheminClasse(classeA, eleveA1, 'planning'),
        );
        final Finder page = find.byType(PlanningClassePage);
        expect(page, findsOneWidget);
        expect(tester.takeException(), isNull);
        // La meme Classe que la page et l'annonce.
        expect(
          find.textContaining(nomClasseInsecable(libelleAnNour())),
          findsOneWidget,
        );
        final List<String> dates = <String>[
          for (final String s in _textes(tester, page))
            if (s.contains(langue == AppLocale.ar ? 'أكتوبر' : 'octobre')) s,
        ];
        expect(dates, hasLength(3), reason: dates.join(' | '));
        // Chaque ligne, une a une, a l'ecran : aucun mot coupe, jour et
        // mois ensemble.
        for (final String date in dates) {
          final Finder ligne = find.text(date);
          await tester.ensureVisible(ligne);
          await stabiliser(tester);
          verifierAucunMotCoupe(tester, ligne);
          final RenderParagraph p = tester.renderObject<RenderParagraph>(
            find.descendant(of: ligne, matching: find.byType(RichText)),
          );
          final String groupe = date.substring(date.indexOf(RegExp(r'\d')));
          expect(_uneLigne(_boites(p, groupe)), isTrue, reason: date);
        }
        if (langue == AppLocale.fr) {
          final Finder sousTitre = find.textContaining('An-⁠Nour · ');
          await tester.ensureVisible(sousTitre);
          await stabiliser(tester);
          verifierAucunMotCoupe(tester, sousTitre);
        }
      });
    }
  });
}
