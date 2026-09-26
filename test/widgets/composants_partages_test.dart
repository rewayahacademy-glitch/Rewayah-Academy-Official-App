// Composants partages du chantier Tuteur V1 qui ne dependent d'aucune cle
// i18n nouvelle (phase 0c1) : ecran resultat, lien fleche, ligne cle-valeur,
// groupe de reglages, controle segmente, formes de la surface modale, icones.
//
// Chaque composant est verifie sur les quatre axes demandes : semantique,
// cible de 48, texte a 200 % sans debordement, theme clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../support/hote_theme.dart';
import '../theme/support/lecteur_police.dart';

/// La palette du theme rendu, lue depuis l'arbre.
AppPalette paletteDe(WidgetTester tester, Finder dans) =>
    AppPalette.of(tester.element(dans));

/// Les cibles pressables font au moins 48 sur 48 et portent un libelle.
Future<void> verifierCibles(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  group('EcranResultat : la grammaire de l ecran M5', () {
    Widget ecran({VoidCallback? onAction, VoidCallback? onSecondaire}) =>
        EcranResultat(
          icone: AppIcons.succes,
          titre: 'Visite terminee',
          phrase: 'Vous avez utilise une visite sur deux pour cette seance.',
          encart: 'La seconde visite reste possible tant que la seance dure.',
          ton: TonEtat.succes,
          libelleAction: 'Retour a la classe',
          onAction: onAction,
          libelleSecondaire: 'Voir l historique',
          onSecondaire: onSecondaire,
        );

    testWidgets('titre en en-tete, action et lien, cibles de 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int actions = 0;
      int liens = 0;
      await tester.pumpWidget(
        hoteTheme(
          ecran(onAction: () => actions++, onSecondaire: () => liens++),
        ),
      );

      expect(
        tester.getSemantics(find.text('Visite terminee')),
        isSemantics(label: 'Visite terminee', isHeader: true),
      );
      await tester.tap(find.text('Retour a la classe'));
      await tester.tap(find.text('Voir l historique'));
      expect(actions, 1);
      expect(liens, 1);
      await verifierCibles(tester);
      semantique.dispose();
    });

    testWidgets('une action sans geste n est pas rendue', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(hoteTheme(ecran()));

      expect(find.byType(ActionPrincipale), findsNothing);
      expect(find.text('Retour a la classe'), findsNothing);
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('cercle heros sur la paire douce du ton, $luminosite', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(ecran(onAction: () {}), luminosite: luminosite),
        );
        final AppPalette palette = paletteDe(
          tester,
          find.byType(EcranResultat),
        );
        final DecoratedBox cercle = tester.widget(
          find
              .descendant(
                of: find.byType(EcranResultat),
                matching: find.byWidgetPredicate(
                  (Widget w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).shape == BoxShape.circle,
                ),
              )
              .first,
        );
        expect(
          (cercle.decoration as BoxDecoration).color,
          palette.washSuccess.background,
        );
        expect(
          palette,
          luminosite == Brightness.dark
              ? AppPalette.sombre()
              : AppPalette.claire(),
        );
      });
    }

    testWidgets('texte a 200 % sur 390 : aucun debordement', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(ecran(onAction: () {}, onSecondaire: () {}), echelleTexte: 2),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Visite terminee'), findsOneWidget);
    });
  });

  group('LienFleche : un lien, pas un bouton', () {
    testWidgets('un seul libelle lu, cible de 48, geste', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int presses = 0;
      await tester.pumpWidget(
        hoteTheme(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(libelle: 'Voir tout', onPress: () => presses++),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(LienFleche)),
        isSemantics(label: 'Voir tout', isButton: true, hasTapAction: true),
      );
      expect(tester.getSize(find.byType(LienFleche)).height, 48);
      await tester.tap(find.byType(LienFleche));
      expect(presses, 1);
      await verifierCibles(tester);
      semantique.dispose();
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('encre d accent du theme, $luminosite, texte 200 %', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            LienFleche(
              libelle: 'Voir l historique de toutes les seances',
              onPress: () {},
            ),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final AppPalette palette = paletteDe(tester, find.byType(LienFleche));
        final Text texte = tester.widget(
          find.text('Voir l historique de toutes les seances'),
        );
        expect(
          texte.style!.color,
          palette.inkAccent.applyTo(const TextStyle()).color,
        );
      });
    }
  });

  group('LigneCleValeur : cote a cote, puis empilee', () {
    testWidgets('cle et valeur lues ensemble', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          const LigneCleValeur(
            cle: 'Horaire',
            valeur: '18:00, heure de Paris',
            chiffres: true,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Horaire')),
        isSemantics(label: 'Horaire\n18:00, heure de Paris'),
      );
      expect(find.byType(Row), findsWidgets);
      semantique.dispose();
    });

    testWidgets('a 200 %, la valeur passe sous la cle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          const LigneCleValeur(
            cle: 'Presence',
            valeur: 'En cours de verification',
            complement: StatusPill(libelle: 'Verifiee', ton: TonEtat.succes),
          ),
          echelleTexte: 2,
          luminosite: Brightness.dark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('En cours de verification')).dy,
        greaterThan(tester.getBottomLeft(find.text('Presence')).dy - 1),
      );
      final AppPalette palette = paletteDe(tester, find.byType(LigneCleValeur));
      final Text valeur = tester.widget(find.text('En cours de verification'));
      expect(
        valeur.style!.color,
        palette.inkStrong.applyTo(const TextStyle()).color,
      );
      expect(palette, AppPalette.sombre());
    });
  });

  group('GroupeReglages : une surface, des filets en retrait', () {
    List<LigneRubrique> lignes(List<String> pressees) => <LigneRubrique>[
      LigneRubrique(
        icone: AppIcons.profil,
        libelle: 'Informations personnelles',
        legende: 'Nom, courriel, fuseau',
        onPress: () => pressees.add('infos'),
      ),
      LigneRubrique(
        icone: AppIcons.reglages,
        libelle: 'Preferences',
        valeur: 'Systeme',
        onPress: () => pressees.add('prefs'),
      ),
      const LigneRubrique(
        icone: AppIcons.foyer,
        libelle: 'Membres du foyer',
        valeur: '3',
      ),
    ];

    testWidgets('lignes pressables a libelle fusionne, cibles de 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      final List<String> pressees = <String>[];
      await tester.pumpWidget(
        hoteTheme(GroupeReglages(titre: 'Compte', lignes: lignes(pressees))),
      );

      expect(
        tester.getSemantics(find.text('Informations personnelles')),
        isSemantics(
          label: 'Informations personnelles\nNom, courriel, fuseau',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Compte')),
        isSemantics(label: 'Compte', isHeader: true),
      );
      await tester.tap(find.text('Preferences'));
      expect(pressees, <String>['prefs']);
      // Deux chevrons : la troisieme ligne ne mene nulle part.
      expect(find.byIcon(AppIcons.chevron.repos), findsNWidgets(2));
      for (final String libelle in <String>[
        'Informations personnelles',
        'Preferences',
        'Membres du foyer',
      ]) {
        final double hauteur = tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(libelle),
                    matching: find.byType(ConstrainedBox),
                  )
                  .first,
            )
            .height;
        expect(hauteur, greaterThanOrEqualTo(AppTouchTarget.standard));
      }
      await verifierCibles(tester);
      semantique.dispose();
    });

    testWidgets('filets : un de moins que de lignes', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(GroupeReglages(lignes: lignes(<String>[]))),
      );
      final Iterable<DecoratedBox> filets = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(GroupeReglages),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where(
            (DecoratedBox d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).border is Border &&
                ((d.decoration as BoxDecoration).border! as Border)
                        .bottom
                        .width >
                    0 &&
                ((d.decoration as BoxDecoration).border! as Border).top ==
                    BorderSide.none,
          );
      expect(filets.length, 2);
    });

    testWidgets('meneur (demande B-1) : a la place de l icone, meme retrait', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      const Key cleMeneur = Key('avatar-membre');
      await tester.pumpWidget(
        hoteTheme(
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                meneur: const SizedBox.square(
                  key: cleMeneur,
                  dimension: AppTouchTarget.standard,
                ),
                libelle: 'Yusuf',
                legende: 'Classe du mardi',
                onPress: () {},
              ),
              const LigneRubrique(icone: AppIcons.foyer, libelle: 'Appareils'),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(cleMeneur), findsOneWidget);
      // Une seule icone de tete : celle de la seconde ligne.
      expect(find.byIcon(AppIcons.foyer.repos), findsOneWidget);
      expect(find.byIcon(AppIcons.profil.repos), findsNothing);

      // Le filet de la premiere ligne commence apres le meneur, au meme
      // ecart (12) qu'apres une icone.
      final DecoratedBox filet = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('Yusuf'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .firstWhere(
            (DecoratedBox d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).border is Border,
          );
      final double debutFilet = tester.getTopLeft(find.byWidget(filet)).dx;
      final double finMeneur = tester.getTopRight(find.byKey(cleMeneur)).dx;
      expect(debutFilet - finMeneur, AppSpacing.md);
    });

    test('une rubrique sans icone ni meneur est refusee', () {
      expect(
        () => LigneRubrique(libelle: 'Vide', onPress: () {}),
        throwsAssertionError,
      );
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('surface du theme et texte 200 %, $luminosite', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            GroupeReglages(lignes: lignes(<String>[])),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final AppPalette palette = paletteDe(
          tester,
          find.byType(GroupeReglages),
        );
        // Le fond de ligne est un DecoratedBox (barre de selection, HL-A-1).
        final Iterable<Color?> fonds = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(GroupeReglages),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map(
              (DecoratedBox b) => switch (b.decoration) {
                final BoxDecoration d => d.color,
                _ => null,
              },
            );
        expect(fonds, contains(palette.surfaceRaised.background));
      });
    }
  });

  group('ControleSegmente : Seances / Observations', () {
    Widget controle(String valeur, ValueChanged<String> onChange) =>
        ControleSegmente<String>(
          segments: const <Segment<String>>[
            Segment<String>(valeur: 'seances', libelle: 'Seances'),
            Segment<String>(valeur: 'observations', libelle: 'Observations'),
          ],
          valeur: valeur,
          onChange: onChange,
        );

    testWidgets('segment choisi annonce, autre segment presse', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      final List<String> choix = <String>[];
      await tester.pumpWidget(hoteTheme(controle('seances', choix.add)));

      expect(
        tester.getSemantics(find.text('Seances')),
        isSemantics(
          label: 'Seances',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Seances'));
      expect(choix, isEmpty);
      await tester.tap(find.text('Observations'));
      expect(choix, <String>['observations']);
      expect(
        tester.getSize(find.byType(ControleSegmente<String>)).height,
        greaterThanOrEqualTo(AppTouchTarget.standard),
      );
      await verifierCibles(tester);
      semantique.dispose();
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('actif sur washAccent a filet, $luminosite, 200 %', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            controle('observations', (String _) {}),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final AppPalette palette = paletteDe(
          tester,
          find.byType(ControleSegmente<String>),
        );
        final DecoratedBox actif = tester.widget(
          find
              .ancestor(
                of: find.text('Observations'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final BoxDecoration d = actif.decoration as BoxDecoration;
        expect(d.color, palette.washAccent.background);
        expect(d.border, isNotNull);
      });
    }
  });

  group('Surface modale : feuille, feuille bornee, dialogue', () {
    test('la forme suit le gabarit', () {
      expect(AppBottomSheet.formePour(Gabarit.mobile), FormeModale.feuille);
      expect(
        AppBottomSheet.formePour(Gabarit.tablette),
        FormeModale.feuilleBornee,
      );
      expect(AppBottomSheet.formePour(Gabarit.desktop), FormeModale.dialogue);
    });

    Future<BuildContext> monter(
      WidgetTester tester, {
      Brightness luminosite = Brightness.light,
    }) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        hoteTheme(
          Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox();
            },
          ),
          luminosite: luminosite,
        ),
      );
      return ctx;
    }

    testWidgets('bureau : boite de dialogue centree, bornee, sans poignee', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueBureau);
      final BuildContext ctx = await monter(tester);
      unawaited(
        AppBottomSheet.ouvrir<void>(
          ctx,
          titre: 'Changer d enseignant',
          constructeur: (BuildContext _) => const Text('corps'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      final AppBottomSheet surface = tester.widget(find.byType(AppBottomSheet));
      expect(surface.forme, FormeModale.dialogue);
      final Size taille = tester.getSize(find.byType(AppBottomSheet));
      expect(taille.width, lessThanOrEqualTo(AppPage.largeurDialogue));
      expect(
        tester.getCenter(find.byType(AppBottomSheet)).dx,
        closeTo(vueBureau.width / 2, 1),
      );
      // Pas de poignee de glissement : aucun doigt sur un bureau.
      expect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('Changer d enseignant')),
        isSemantics(label: 'Changer d enseignant', isHeader: true),
      );
    });

    testWidgets('bureau : Echap ferme et rend null', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueBureau);
      final BuildContext ctx = await monter(tester);
      bool? resultat = true;
      bool fini = false;
      unawaited(
        AppBottomSheet.ouvrir<bool>(
          ctx,
          titre: 'Titre',
          constructeur: (BuildContext _) => const Text('corps'),
        ).then((bool? r) {
          resultat = r;
          fini = true;
        }),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fini, isTrue);
      expect(resultat, isNull);
      expect(find.byType(AppBottomSheet), findsNothing);
    });

    testWidgets('bureau : ConfirmDestructive garde son ordre et rend true', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueBureau);
      final BuildContext ctx = await monter(
        tester,
        luminosite: Brightness.dark,
      );
      bool? reponse;
      unawaited(
        ConfirmDestructive.demander(
          ctx,
          question: 'Retirer cet appareil ?',
          consequence: 'Il devra etre associe de nouveau.',
          libelleConfirmer: 'Retirer l appareil',
        ).then((bool r) => reponse = r),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester.getCenter(find.text(t.commun.annuler)).dy,
        greaterThan(tester.getCenter(find.text('Retirer l appareil')).dy),
      );
      // En sombre, la boite de dialogue prend la surface des superpositions.
      final AppPalette palette = paletteDe(tester, find.byType(AppBottomSheet));
      expect(palette, AppPalette.sombre());
      await tester.tap(find.text('Retirer l appareil'));
      await tester.pumpAndSettle();
      expect(reponse, isTrue);
    });

    testWidgets('tablette : feuille bornee a la largeur de dialogue', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueTablette);
      final BuildContext ctx = await monter(tester);
      unawaited(
        AppBottomSheet.ouvrir<void>(
          ctx,
          titre: 'Titre',
          constructeur: (BuildContext _) => const Text('corps'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppBottomSheet)).width,
        lessThanOrEqualTo(AppPage.largeurDialogue),
      );
    });

    testWidgets('telephone : la feuille pleine largeur, inchangee', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      final BuildContext ctx = await monter(tester);
      unawaited(
        AppBottomSheet.ouvrir<void>(
          ctx,
          titre: 'Titre',
          constructeur: (BuildContext _) => const Text('corps'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppBottomSheet)).width,
        vueMobile.width,
      );
    });
  });

  group('Icones ajoutees : presentes dans les deux polices embarquees', () {
    final Map<String, AppIcon> ajoutees = <String, AppIcon>{
      'retour': AppIcons.retour,
      'attente': AppIcons.attente,
      'reconnexion': AppIcons.reconnexion,
      'verrou': AppIcons.verrou,
      'seReconnecter': AppIcons.seReconnecter,
      'interdit': AppIcons.interdit,
      'ressourceRetiree': AppIcons.ressourceRetiree,
    };

    test('chaque point de code est dessine en Regular et en Fill', () {
      final Set<int> regular = LecteurPolice(
        'assets/fonts/Phosphor-Regular.ttf',
      ).couverture;
      final Set<int> fill = LecteurPolice('assets/fonts/Phosphor-Fill.ttf')
          .couverture;
      for (final MapEntry<String, AppIcon> e in ajoutees.entries) {
        expect(regular, contains(e.value.repos.codePoint), reason: e.key);
        expect(fill, contains(e.value.actif.codePoint), reason: e.key);
      }
    });

    test('le retour se miroite en arabe, pas la reconnexion', () {
      expect(AppIcons.retour.repos.matchTextDirection, isTrue);
      expect(AppIcons.reconnexion.repos.matchTextDirection, isFalse);
    });
  });
}
