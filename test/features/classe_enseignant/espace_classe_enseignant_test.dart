// CL-4.4 : l'Espace Classe enseignant (CLS-ENS-01 et 02), par evolution de
// FicheGroupePage, sur les donnees de demonstration. Les tests TOUCHENT les
// elements : « Preparer l'entree » se tape et mene a la preparation, la liste
// des eleves ne porte rien de ce que R15 interdit, reflow a 320 et texte a
// 200 %.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/photo_enseignant.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/a/support/hote_tc_a.dart';

/// Pose la fiche, sans `onPreparer` : le chemin reel vers la preparation.
Future<void> _poser(WidgetTester tester, EtatDemoClasse etat) async {
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.groupePour(DonneesClasseDemo.groupeId),
    routes: <RouteBase>[
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId',
        builder: (BuildContext _, GoRouterState e) =>
            FicheGroupePage(groupeId: e.pathParameters['groupeId'] ?? ''),
      ),
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState e) =>
            Text('preparation:${(e.extra! as BilletSalle).sessionId}'),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesEnseignantDemo(etat),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Finder get _preparer =>
    find.widgetWithText(ActionPrincipale, t.enseignant.journee.rejoindreSalle);

void main() {
  testWidgets('seance annulee : pastille, heures barrees, pourquoi, carte '
      'attenuee, une seule annonce', (WidgetTester tester) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.annulee);
      final Finder carte = find.byType(CarteSession);
      expect(carte, findsOneWidget);
      expect(
        find.descendant(
          of: carte,
          matching: find.byKey(
            const ValueKey<String>('pastille-annulee-icone'),
          ),
        ),
        findsOneWidget,
      );
      final List<TexteHeureSeance> heures = tester
          .widgetList<TexteHeureSeance>(
            find.descendant(of: carte, matching: find.byType(TexteHeureSeance)),
          )
          .toList();
      // Les heures sont barrees (la duree, elle, ne l'est pas) ; une seule
      // annonce « Annulee : ... » pour la carte.
      final List<TexteHeureSeance> barrees = heures
          .where((TexteHeureSeance h) => h.annulee)
          .toList();
      expect(barrees.length, greaterThanOrEqualTo(1));
      expect(barrees.where((TexteHeureSeance h) => h.annoncer), hasLength(1));
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.etat.motifNonCommunique),
        ),
        findsOneWidget,
      );
      final AppCard fond = tester.widget<AppCard>(
        find.descendant(of: carte, matching: find.byType(AppCard)).first,
      );
      expect(fond.surface, isNotNull);
    });
    poignee.dispose();
  });

  testWidgets('avant l ouverture : aucun bouton dans la carte de seance', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      expect(find.byType(CarteSession), findsOneWidget);
      expect(_preparer, findsNothing);
      expect(
        find.descendant(
          of: find.byType(CarteSession),
          matching: find.byType(ActionPrincipale),
        ),
        findsNothing,
      );
      expect(find.textContaining(RegExp(r'^Dans \d')), findsOneWidget);
    });
  });

  testWidgets('a l ouverture : Preparer l entree se tape et mene a la '
      'preparation, jamais directement dans la salle', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.fenetreOuverte);
      expect(_preparer, findsOneWidget);
      await tester.ensureVisible(_preparer);
      await tester.tap(_preparer);
      await tester.pumpAndSettle();
      // `/salle` avec son billet : la salle ouvre d'abord le pre-vol complet
      // de l'enseignant (PreCours) et n'entre qu'apres.
      expect(find.text('preparation:demo-seance-an-nour'), findsOneWidget);
    });
  });

  testWidgets('sur bureau, Preparer l entree garde sa largeur naturelle', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, 1440, () async {
      await _poser(tester, EtatDemoClasse.fenetreOuverte);
      expect(tester.widget<ActionPrincipale>(_preparer).pleineLargeur, isFalse);
      // Largeur naturelle, pas etire sur la carte (rectification 9).
      expect(
        tester.getSize(_preparer).width,
        lessThan(tester.getSize(find.byType(CarteSession)).width * 0.75),
      );
    });
  });

  // EN-3 : la Classe (seance, preparation, progression, ressources) puis les
  // eleves ; sur bureau, deux colonnes (planche 2, rectification 5).
  testWidgets('ordre : identite, seance, preparation, progression, '
      'ressources, eleves', (WidgetTester tester) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      double haut(Finder f) => tester.getTopLeft(f.first).dy;
      final double identite = haut(find.text(DonneesClasseDemo.classe));
      final double seance = haut(find.byType(CarteSession));
      final double preparation = haut(
        find.text(t.enseignant.ficheGroupe.preparationTitre),
      );
      final double progression = haut(
        find.text(t.enseignant.ficheGroupe.progressionTitre),
      );
      final double ressources = haut(
        find.text(t.enseignant.ficheGroupe.ressourcesTitre),
      );
      final double eleves = haut(
        find.text(t.enseignant.ficheGroupe.elevesTitre),
      );
      expect(identite, lessThan(seance));
      expect(seance, lessThan(preparation));
      expect(preparation, lessThan(progression));
      expect(progression, lessThan(ressources));
      expect(ressources, lessThan(eleves));
      // Sans onglets.
      expect(find.byType(TabBar), findsNothing);
    });
  });

  testWidgets('bureau : [la Classe | les eleves]', (WidgetTester tester) async {
    await avecLargeur(tester, 1440, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      final Offset seance = tester.getTopLeft(find.byType(CarteSession));
      final Offset preparation = tester.getTopLeft(
        find.text(t.enseignant.ficheGroupe.preparationTitre),
      );
      final Offset ressources = tester.getTopLeft(
        find.text(t.enseignant.ficheGroupe.ressourcesTitre),
      );
      final Offset eleves = tester.getTopLeft(
        find.text(t.enseignant.ficheGroupe.elevesTitre),
      );
      // La Classe au debut, en une colonne ; les eleves a la fin, en haut.
      expect(preparation.dx, seance.dx);
      expect(ressources.dx, seance.dx);
      expect(eleves.dx, greaterThan(seance.dx));
      expect(eleves.dy, lessThan(preparation.dy));
    });
  });

  testWidgets('preparation : support, reprise, objectif ; aucun Modifier', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      expect(find.text(t.enseignant.ficheGroupe.supportPrevu), findsOneWidget);
      expect(find.text(DonneesClasseDemo.supportPrevu), findsOneWidget);
      expect(
        find.text(t.enseignant.ficheGroupe.positionReprise),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.ficheGroupe.objectif), findsOneWidget);
      // Aucune destination d'edition : aucun lien.
      expect(find.text('Modifier'), findsNothing);
    });
  });

  testWidgets('eleves : prenom, initiales, niveau, reprise, dernier point', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      // CL-4.4b : une seule carte groupee, une ligne par eleve.
      // (« Supports recents » a le sien : on prend celui des eleves, et tous
      // les prenoms doivent y etre.)
      final Finder groupe = find.ancestor(
        of: find.text(DonneesClasseDemo.eleves.first.prenom),
        matching: find.byType(GroupeReglages),
      );
      expect(groupe, findsOneWidget);
      for (final EleveProjectionDemo e in DonneesClasseDemo.eleves) {
        expect(
          find.descendant(of: groupe, matching: find.text(e.prenom)),
          findsOneWidget,
        );
        // Une seule ligne secondaire « niveau · reprise » ; le dernier point
        // reste dans la fiche eleve (K-42 style §4).
        final String reprise = t.enseignant.ficheGroupe.repriseEleve(
          page: e.pageReprise,
        );
        expect(
          find.descendant(
            of: groupe,
            matching: find.text('${e.niveau} · $reprise'),
          ),
          findsNWidgets(
            DonneesClasseDemo.eleves
                .where(
                  (EleveProjectionDemo x) =>
                      x.niveau == e.niveau && x.pageReprise == e.pageReprise,
                )
                .length,
          ),
        );
        expect(
          find.descendant(
            of: groupe,
            matching: find.textContaining(e.dernierPoint),
          ),
          findsNothing,
        );
      }
      // Aucune carte par eleve.
      expect(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.text('Mariam'),
        ),
        findsNothing,
      );
      // Trois initiales d'eleve dans le groupe, plus celles de l'enseignante
      // dans l'identite.
      expect(
        find.descendant(of: groupe, matching: find.byType(AvatarTile)),
        findsNWidgets(3),
      );
      expect(find.byType(AvatarTile), findsNWidgets(4));
      // Jamais de photo, ni d'eleve ni d'enseignante.
      expect(find.byType(Image), findsNothing);
      expect(find.byType(PhotoEnseignant), findsNothing);
      // Le lien vers la revue du groupe est garde, au bord de fin, sous la
      // carte.
      final Finder revue = find.widgetWithText(
        ActionPrincipale,
        t.enseignant.ficheGroupe.revue,
      );
      expect(revue, findsOneWidget);
      expect(
        tester.getTopLeft(revue).dy,
        greaterThan(tester.getBottomLeft(groupe).dy),
      );
      expect(
        tester.getTopRight(revue).dx,
        moreOrLessEquals(tester.getTopRight(groupe).dx, epsilon: 1),
      );
    });
  });

  testWidgets('haut de page : retour au bord de debut, puis le nom de la '
      'Classe en titre ; capacite en pastille, aucune tuile de places', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      // Plus de titre d'ecran « Fiche du groupe ».
      expect(find.text('Fiche du groupe'), findsNothing);
      final Finder titre = find.text(DonneesClasseDemo.classe);
      expect(titre, findsOneWidget);
      final Finder retour = find.text(t.commun.retour);
      expect(
        tester.getTopLeft(retour).dy,
        lessThan(tester.getTopLeft(titre).dy),
      );
      expect(
        tester.getTopLeft(retour).dx,
        lessThan(tester.getSize(find.byType(FicheGroupePage)).width / 3),
      );
      // Le titre, puis le cours et le niveau, puis l'enseignante.
      final Finder cours = find.textContaining(DonneesClasseDemo.cours);
      final Finder enseignante = find.textContaining(
        DonneesClasseDemo.enseignant.nomAffichage,
      );
      expect(
        tester.getTopLeft(titre).dy,
        lessThan(tester.getTopLeft(cours.first).dy),
      );
      expect(
        tester.getTopLeft(cours.first).dy,
        lessThan(tester.getTopLeft(enseignante.first).dy),
      );
      // Le type de groupe tient la ligne de contexte discrete, apres le cours
      // et le niveau (revue CL-4.R, m7).
      expect(
        find.text(
          '${DonneesClasseDemo.cours} · ${DonneesClasseDemo.niveau} · '
          '${t.admin.groupes.typeEnfant}',
        ),
        findsOneWidget,
      );
      // La capacite en petite pastille : « 3 eleves sur 6 places ».
      expect(
        find.widgetWithText(
          StatusPill,
          t.tc.groupe.carte.capacitePhrase(
            membres: DonneesClasseDemo.eleves.length,
            seuil: 6,
          ),
        ),
        findsOneWidget,
      );
      // Aucune tuile « places libres » pleine largeur.
      expect(find.byType(StatTile), findsNothing);
      expect(find.text('places libres'), findsNothing);
      expect(find.text('place libre'), findsNothing);
    });
  });

  testWidgets('R15 : aucun champ prive dans la page', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, 1440, () async {
      await _poser(tester, EtatDemoClasse.aVenir);
      final Iterable<String> textes = tester
          .widgetList<Text>(find.byType(Text))
          .map(
            (Text w) =>
                (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
          );
      const List<String> interdits = <String>[
        '@',
        'courriel',
        'e-mail',
        'adresse',
        'foyer',
        'paiement',
        'tuteur',
        'parent',
        'géolocalisation',
        'irrégulier',
      ];
      for (final String texte in textes) {
        // Aucun numero de telephone.
        expect(RegExp(r'\+?\d[\d .]{8,}\d').hasMatch(texte), isFalse);
        for (final String interdit in interdits) {
          expect(texte.contains(interdit), isFalse, reason: texte);
        }
      }
    });
  });

  for (final EtatDemoClasse etat in <EtatDemoClasse>[
    EtatDemoClasse.aVenir,
    EtatDemoClasse.fenetreOuverte,
    EtatDemoClasse.horsLigne,
  ]) {
    testWidgets('reflow 320 et texte a 200 % : ${etat.name}', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, 320, () async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _poser(tester, etat);
        expect(tester.takeException(), isNull);
        expect(find.byType(FicheGroupePage), findsOneWidget);
      });
    });
  }

  testWidgets('/demo/classe ouvre le vrai ecran enseignant', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await tester.pumpWidget(
        hoteTcA(const EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(FicheGroupePage), findsOneWidget);
      expect(_preparer, findsOneWidget);
    });
  });

  group('Capture : CL-4.4', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EtatDemoClasse etat in <EtatDemoClasse>[
      EtatDemoClasse.aVenir,
      EtatDemoClasse.fenetreOuverte,
    ]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 2000)),
        ('768', const Size(768, 1800)),
        ('1440', const Size(1440, 1100)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'cl44_enseignant_${etat.name}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(EcranEnseignantDemo(etat: etat), themeMode: mode),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
