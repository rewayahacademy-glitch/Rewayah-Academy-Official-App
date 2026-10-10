// Composants partages du chantier Tuteur V1 qui lisent des cles `commun.*`
// (phase 0c1) : etat systeme, bloc asynchrone, selecteur de profils, en-tete
// de page et cloche, bascule de theme.
//
// Quatre axes pour chacun : semantique, cible de 48, texte a 200 % sans
// debordement, theme clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_theme.dart';
import 'package:rewayah_academy/core/widgets/bloc_asynchrone.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

import '../support/hote_theme.dart';

Future<void> verifierCibles(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

const Key _squelette = Key('squelette');

Widget _bloc(
  AsyncValue<List<String>> valeur, {
  VoidCallback? onReessayer,
  Widget? vide,
}) => BlocAsynchrone<List<String>>(
  valeur: valeur,
  squelette: const SizedBox(key: _squelette, height: 48),
  construire: (List<String> v) => Text('contenu ${v.join(',')}'),
  onReessayer: onReessayer,
  vide: vide,
);

void main() {
  group('EtatSysteme : un titre humain, jamais un code', () {
    testWidgets('chaque nature a son titre et sa phrase, en bloc et en page', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      for (final NatureEtat nature in NatureEtat.values) {
        for (final PorteeEtat portee in PorteeEtat.values) {
          await tester.pumpWidget(
            hoteTheme(
              EtatSysteme(
                nature: nature,
                portee: portee,
                dependance: 'DB-CPT-03',
                onAction: () {},
              ),
            ),
          );
          final ({String titre, String phrase}) textes = EtatSysteme.textesPar(
            nature,
          );
          expect(find.text(textes.titre), findsOneWidget, reason: '$nature');
          expect(find.text(textes.phrase), findsOneWidget, reason: '$nature');
          expect(
            find.text(EtatSysteme.libelleActionPar(nature)),
            findsOneWidget,
            reason: '$nature',
          );
          // La dependance ne s'affiche jamais.
          expect(find.textContaining('DB-'), findsNothing, reason: '$nature');
          expect(
            find.byType(EcranResultat),
            portee == PorteeEtat.page ? findsOneWidget : findsNothing,
          );
        }
      }
    });

    testWidgets('sans geste, aucun bouton ; la dependance reste en cle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          const EtatSysteme(
            nature: NatureEtat.indisponible,
            dependance: 'DB-CPT-03',
          ),
        ),
      );
      expect(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.indisponible)),
        findsNothing,
      );
      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.dependance, 'DB-CPT-03');
    });

    testWidgets('bloc : region vivante, action de 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int essais = 0;
      await tester.pumpWidget(
        hoteTheme(
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            onAction: () => essais++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text(t.commun.etats.echecServeur.titre)),
        isSemantics(isLiveRegion: true),
      );
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      expect(essais, 1);
      await verifierCibles(tester);
      semantique.dispose();
    });

    // EA-PL : « trop large, trop etire ». La carte garde la largeur de
    // lecture, au bord de debut ; « Reessayer » a la largeur de son libelle,
    // au bord de fin de la carte, en bureau comme sur telephone.
    for (final (String nom, Size vue) in <(String, Size)>[
      ('1440', vueBureau),
      ('390', vueMobile),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('bloc borne et Reessayer au bord de fin, $nom, $sens', (
          WidgetTester tester,
        ) async {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              Directionality(
                textDirection: sens,
                child: Column(
                  key: const Key('colonne'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    EtatSysteme(nature: NatureEtat.horsLigne, onAction: () {}),
                  ],
                ),
              ),
            ),
          );
          final Finder carte = find.descendant(
            of: find.byType(EtatSysteme),
            matching: find.byType(DecoratedBox),
          );
          final Rect cadre = tester.getRect(carte.first);
          expect(cadre.width, lessThanOrEqualTo(AppPage.largeurLecture));
          final Rect ecran = tester.getRect(find.byKey(const Key('colonne')));
          if (sens == TextDirection.ltr) {
            expect(cadre.left, ecran.left);
          } else {
            expect(cadre.right, ecran.right);
          }
          final Rect bouton = tester.getRect(
            find.byKey(const ValueKey<String>('etat-systeme-action')),
          );
          // Jamais toute la colonne de texte de la carte (marges, medaillon
          // et son ecart retires).
          final double colonneTexte =
              cadre.width -
              AppSpacing.lg * 2 -
              AppSpacing.section -
              AppSpacing.md;
          expect(bouton.width, lessThan(colonneTexte));
          final double bordFin = sens == TextDirection.ltr
              ? cadre.right - bouton.right
              : bouton.left - cadre.left;
          expect(bordFin, AppSpacing.lg);
        });
      }
    }

    // EA-PL : titre, phrase et encart centres, dans un bloc borne.
    for (final (String nom, Size vue) in <(String, Size)>[
      ('390', vueMobile),
      ('1440', vueBureau),
    ]) {
      testWidgets('EcranResultat : textes centres et bloc borne, $nom', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            EcranResultat(
              icone: AppIcons.invitationEnvoyee,
              titre: 'Invitation envoyée',
              phrase: "L'invitation est partie vers mariama@example.com.",
              encart: 'Réponse enregistrée le 2 octobre.',
              libelleAction: 'Revenir à Ma famille',
              onAction: () {},
            ),
          ),
        );
        for (final String texte in <String>[
          'Invitation envoyée',
          "L'invitation est partie vers mariama@example.com.",
          'Réponse enregistrée le 2 octobre.',
        ]) {
          expect(
            tester.widget<Text>(find.text(texte)).textAlign,
            TextAlign.center,
            reason: texte,
          );
          // Le texte est centre dans la colonne de l'ecran.
          final Rect r = tester.getRect(find.text(texte));
          final Rect bloc = tester.getRect(find.byType(EcranResultat));
          expect(r.center.dx, closeTo(bloc.center.dx, 1), reason: texte);
        }
        final Rect colonne = tester.getRect(
          find
              .descendant(
                of: find.byType(EcranResultat),
                matching: find.byType(Column),
              )
              .first,
        );
        expect(colonne.width, lessThanOrEqualTo(AppPage.largeurEtatVide));
      });
    }

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('texte a 200 %, $luminosite, bloc et page', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        for (final PorteeEtat portee in PorteeEtat.values) {
          await tester.pumpWidget(
            hoteTheme(
              EtatSysteme(
                nature: NatureEtat.permissionRefusee,
                portee: portee,
                onAction: () {},
                libelleSecondaire: 'Saisir le code',
                onSecondaire: () {},
              ),
              luminosite: luminosite,
              echelleTexte: 2,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            AppPalette.of(tester.element(find.byType(EtatSysteme))),
            luminosite == Brightness.dark
                ? AppPalette.sombre()
                : AppPalette.claire(),
          );
        }
      });
    }
  });

  group('BlocAsynchrone : squelette, prolonge, perdu, contenu', () {
    // MA-2COL-1 : `piedEchec` reste sous tout echec et indisponibilite
    // (erreur typee, erreur par defaut, tentative perdue), jamais sous le
    // squelette ni le contenu.
    testWidgets('piedEchec : sous l echec, l indisponible et la tentative '
        'perdue ; ni sous le squelette ni sous le contenu', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      const Key pied = Key('pied');
      Widget bloc(AsyncValue<List<String>> valeur) =>
          BlocAsynchrone<List<String>>(
            valeur: valeur,
            squelette: const SizedBox(key: _squelette, height: 48),
            construire: (List<String> v) => Text('contenu ${v.join(',')}'),
            onReessayer: () {},
            piedEchec: const SizedBox(key: pied, height: 48),
          );

      await tester.pumpWidget(
        hoteTheme(
          bloc(
            AsyncValue<List<String>>.error(StateError('x'), StackTrace.empty),
          ),
        ),
      );
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      expect(find.byKey(pied), findsOneWidget);
      expect(
        tester.getRect(find.byKey(pied)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text(t.commun.etats.echecServeur.titre)).bottom,
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        hoteTheme(
          bloc(
            const AsyncValue<List<String>>.error(
              CapaciteIndisponible('DB-X'),
              StackTrace.empty,
            ),
          ),
        ),
      );
      expect(find.byKey(pied), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        hoteTheme(bloc(const AsyncData<List<String>>(<String>['a']))),
      );
      expect(find.text('contenu a'), findsOneWidget);
      expect(find.byKey(pied), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        hoteTheme(bloc(const AsyncValue<List<String>>.loading())),
      );
      expect(find.byKey(_squelette), findsOneWidget);
      expect(find.byKey(pied), findsNothing);
      await tester.pump(AppDelais.requeteMax);
      await tester.pump(Mouvement.maximum);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      expect(find.byKey(pied), findsOneWidget);
    });

    testWidgets('le squelette, puis la phrase de chargement prolonge', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          _bloc(const AsyncValue<List<String>>.loading(), onReessayer: () {}),
        ),
      );
      expect(find.byKey(_squelette), findsOneWidget);
      expect(find.text(t.commun.etats.chargementProlonge.titre), findsNothing);

      await tester.pump(AppDelais.chargementProlonge);
      expect(find.byKey(_squelette), findsOneWidget);
      expect(
        find.text(t.commun.etats.chargementProlonge.titre),
        findsOneWidget,
      );
    });

    testWidgets('au-dela de requeteMax : echec, et la reponse tardive attend', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      int essais = 0;
      await tester.pumpWidget(
        hoteTheme(
          _bloc(
            const AsyncValue<List<String>>.loading(),
            onReessayer: () => essais++,
          ),
        ),
      );
      await tester.pump(AppDelais.requeteMax);
      // Le squelette sort en fondu court (P2-16).
      await tester.pump(Mouvement.maximum);
      expect(find.byKey(_squelette), findsNothing);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);

      // La reponse arrive apres coup : elle est ignoree, l'echec reste.
      await tester.pumpWidget(
        hoteTheme(
          _bloc(
            const AsyncData<List<String>>(<String>['a']),
            onReessayer: () => essais++,
          ),
        ),
      );
      expect(find.text('contenu a'), findsNothing);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);

      // La personne reessaie : la valeur deja la s'affiche.
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pump();
      expect(essais, 1);
      expect(find.text('contenu a'), findsOneWidget);
    });

    testWidgets('une capacite indisponible n est pas une erreur', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          _bloc(
            const AsyncError<List<String>>(
              CapaciteIndisponible('DB-CPT-04'),
              StackTrace.empty,
            ),
            onReessayer: () {},
          ),
        ),
      );
      expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
      expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.dependance, 'DB-CPT-04');
    });

    testWidgets('reessayer est borne, jamais en boucle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      int essais = 0;
      const AsyncError<List<String>> erreur = AsyncError<List<String>>(
        FormatException('lecture'),
        StackTrace.empty,
      );
      await tester.pumpWidget(
        hoteTheme(_bloc(erreur, onReessayer: () => essais++)),
      );
      for (int i = 0; i < BlocAsynchrone.reessaisMax; i++) {
        await tester.tap(find.text(t.commun.etats.actions.reessayer));
        await tester.pump();
      }
      expect(essais, BlocAsynchrone.reessaisMax);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.text(t.commun.etats.reessaisEpuises), findsOneWidget);
    });

    testWidgets('contenu et vide', (WidgetTester tester) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          _bloc(
            const AsyncData<List<String>>(<String>[]),
            vide: const EtatSysteme(nature: NatureEtat.aucunResultat),
          ),
        ),
      );
      expect(find.text(t.commun.etats.aucunResultat.titre), findsOneWidget);

      await tester.pumpWidget(
        hoteTheme(_bloc(const AsyncData<List<String>>(<String>['x', 'y']))),
      );
      expect(find.text('contenu x,y'), findsOneWidget);
      expect(find.byKey(_squelette), findsNothing);
    });

    testWidgets('quitter l ecran annule les minuteries', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(_bloc(const AsyncValue<List<String>>.loading())),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      // Une minuterie encore armee ferait echouer le test a sa fin.
      await tester.pump(AppDelais.requeteMax);
      expect(tester.takeException(), isNull);
    });
  });

  group('SelecteurProfils : le point toujours double d un mot', () {
    const List<ProfilSelectionnable> profils = <ProfilSelectionnable>[
      ProfilSelectionnable(
        id: 'e1',
        prenom: 'Mariam',
        etat: 'En séance',
        point: PointStatut.succes,
      ),
      ProfilSelectionnable(
        id: 'e2',
        prenom: 'Yusuf',
        etat: 'Dans 3 h',
        point: PointStatut.attention,
      ),
    ];

    testWidgets('etiquettes, selection, ajout, cibles de 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      final List<String> choisis = <String>[];
      int ajouts = 0;
      await tester.pumpWidget(
        hoteTheme(
          SelecteurProfils(
            profils: profils,
            selectionId: 'e1',
            onSelection: choisis.add,
            onAjouter: () => ajouts++,
          ),
        ),
      );

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            t.commun.selecteurProfils.etiquette(
              prenom: 'Mariam',
              etat: 'En séance',
            ),
          ),
        ),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            t.commun.selecteurProfils.etiquette(
              prenom: 'Yusuf',
              etat: 'Dans 3 h',
            ),
          ),
        ),
        isSemantics(isSelected: false, isButton: true),
      );
      expect(
        find.bySemanticsLabel(t.commun.selecteurProfils.ajouterSemantique),
        findsOneWidget,
      );
      expect(find.text(t.commun.selecteurProfils.ajouter), findsOneWidget);

      await tester.tap(find.text('Yusuf'));
      await tester.tap(find.text(t.commun.selecteurProfils.ajouter));
      expect(choisis, <String>['e2']);
      expect(ajouts, 1);
      await verifierCibles(tester);
      semantique.dispose();
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('anneau de selection du theme, $luminosite, 200 %', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            SelecteurProfils(
              profils: profils,
              selectionId: 'e2',
              onSelection: (String _) {},
              onAjouter: () {},
            ),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(SelecteurProfils)),
        );
        final Iterable<BoxDecoration> anneaux = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((DecoratedBox d) => d.decoration)
            .whereType<BoxDecoration>()
            .where(
              (BoxDecoration d) =>
                  d.shape == BoxShape.circle &&
                  d.border is Border &&
                  (d.border! as Border).top.color ==
                      palette.surfacePrimary.background,
            );
        expect(anneaux.length, 1);
      });
    }
  });

  group('EntetePage et ClocheNotifications', () {
    testWidgets('titre en en-tete, disque retour de 48 lu « Retour »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int retours = 0;
      await tester.pumpWidget(
        hoteTheme(
          EntetePage(
            titre: 'Préférences',
            sousTitre: 'Sur cet appareil',
            onRetour: () => retours++,
            actions: <Widget>[ClocheNotifications(onPress: () {})],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Préférences')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSize(find.byType(DisqueRetour)),
        const Size.square(AppTouchTargetTest.standard),
      );
      await tester.tap(find.bySemanticsLabel(t.commun.entete.retour));
      expect(retours, 1);
      await verifierCibles(tester);
      semantique.dispose();
    });

    // COM-F-Q5-R : sur sa page, la cloche est pleine et a l'encre d'accent ;
    // au repos, contour et encre de la coquille. Clair et sombre.
    for (final Brightness luminosite in Brightness.values) {
      testWidgets(
        'active : icone pleine a l encre d accent (${luminosite.name})',
        (WidgetTester tester) async {
          fixerVue(tester, vueMobile);
          for (final bool actif in <bool>[true, false]) {
            await tester.pumpWidget(
              hoteTheme(
                ClocheNotifications(onPress: () {}, actif: actif),
                luminosite: luminosite,
              ),
            );
            final Finder icone = find.descendant(
              of: find.byType(ClocheNotifications),
              matching: find.byType(Icon),
            );
            expect(
              tester.widget<Icon>(icone).icon,
              AppIcons.notifications.resoudre(selectionne: actif),
            );
            final AppPalette palette = AppPalette.of(tester.element(icone));
            final Color? attendue = actif
                ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl).color
                : palette.inkStrong.asIconTheme(size: AppSpacing.xxl).color;
            expect(IconTheme.of(tester.element(icone)).color, attendue);
            expect(
              palette.inkAccent.asIconTheme(size: AppSpacing.xxl).color,
              isNot(palette.inkStrong.asIconTheme(size: AppSpacing.xxl).color),
            );
          }
        },
      );
    }

    testWidgets('sans retour, pas de disque', (WidgetTester tester) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(hoteTheme(const EntetePage(titre: 'Accueil')));
      expect(find.byType(DisqueRetour), findsNothing);
    });

    testWidgets('le point de non-lus n existe que pour de vrais non-lus', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      for (final (int? nonLues, String libelle, bool point)
          in <(int?, String, bool)>[
            (null, t.commun.entete.notifications, false),
            (0, t.commun.entete.notifications, false),
            (1, t.commun.entete.notificationsUneNonLue, true),
            (4, t.commun.entete.notificationsNonLues(nombre: 4), true),
          ]) {
        await tester.pumpWidget(
          hoteTheme(ClocheNotifications(onPress: () {}, nonLues: nonLues)),
        );
        expect(find.bySemanticsLabel(libelle), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ClocheNotifications),
            matching: find.byType(PositionedDirectional),
          ),
          point ? findsOneWidget : findsNothing,
        );
      }
      semantique.dispose();
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('texte a 200 % sur 390, $luminosite', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            EntetePage(
              titre: 'Mon compte et mes préférences',
              sousTitre: 'Informations, sécurité, accès',
              onRetour: () {},
              actions: <Widget>[
                ClocheNotifications(onPress: () {}, nonLues: 2),
              ],
            ),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BasculeTheme : la meme preference qu Apparence', () {
    Widget appli() => ProviderScope(
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) =>
              MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: ref.watch(modeThemeProvider),
                home: const Scaffold(body: Center(child: BasculeTheme())),
              ),
        ),
      ),
    );

    testWidgets('presser la lune passe l application en sombre', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueBureau);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(appli());

      expect(
        tester.getSemantics(find.bySemanticsLabel(t.commun.theme.clair)),
        isSemantics(isSelected: true, isButton: true),
      );
      await tester.tap(find.bySemanticsLabel(t.commun.theme.sombre));
      await tester.pumpAndSettle();

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(BasculeTheme)),
      );
      expect(
        conteneur.read(preferencesLocalesProvider).theme,
        PreferenceTheme.sombre,
      );
      expect(
        Theme.of(tester.element(find.byType(BasculeTheme))).brightness,
        Brightness.dark,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(t.commun.theme.sombre)),
        isSemantics(isSelected: true),
      );
      await verifierCibles(tester);
      semantique.dispose();
    });

    testWidgets('sous « Systeme » sombre, la lune est le segment actif', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueBureau);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(appli());

      expect(
        tester.getSemantics(find.bySemanticsLabel(t.commun.theme.sombre)),
        isSemantics(isSelected: true),
      );
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(BasculeTheme)),
      );
      expect(palette, AppPalette.sombre());
      final Iterable<Color?> fonds = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(BasculeTheme),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((DecoratedBox d) => (d.decoration as BoxDecoration).color);
      expect(fonds, contains(palette.surfacePrimary.background));
      semantique.dispose();
    });
  });
}

/// La cible tactile standard, lue sans importer le jeton dans les attentes.
abstract final class AppTouchTargetTest {
  static const double standard = 48;
}
