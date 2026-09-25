// Composants partages du chantier Tuteur V1 qui lisent des cles `commun.*`
// (phase 0c1) : etat systeme, bloc asynchrone, selecteur de profils, en-tete
// de page et cloche, selecteur de theme.
//
// Quatre axes pour chacun : semantique, cible de 48, texte a 200 % sans
// debordement, theme clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bloc_asynchrone.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/core/widgets/selecteur_theme.dart';

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

  group('SelecteurTheme : soleil, lune, systeme', () {
    Widget appli(Widget selecteur, [ProviderContainer? conteneur]) =>
        UncontrolledProviderScope(
          container: conteneur ?? ProviderContainer(),
          child: TranslationProvider(
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? _) =>
                  MaterialApp(
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    darkTheme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.dark,
                    ),
                    themeMode: ref.watch(modeThemeProvider),
                    home: Scaffold(body: Center(child: selecteur)),
                  ),
            ),
          ),
        );

    Brightness affichee(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(SelecteurTheme))).brightness;

    for (final (String nom, Widget selecteur) in <(String, Widget)>[
      ('sur carte', const SelecteurTheme()),
      ('en-tete', const SelecteurTheme.entete()),
    ]) {
      testWidgets('$nom : « systeme » par defaut, chaque icone tapee '
          's applique', (WidgetTester tester) async {
        final SemanticsHandle semantique = tester.ensureSemantics();
        fixerVue(tester, vueMobile);
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final ProviderContainer conteneur = ProviderContainer();
        addTearDown(conteneur.dispose);
        await tester.pumpWidget(appli(selecteur, conteneur));

        PreferenceTheme choix() =>
            conteneur.read(preferencesLocalesProvider).theme;
        expect(choix(), PreferenceTheme.systeme);
        expect(
          tester.getSemantics(find.bySemanticsLabel(t.commun.theme.systeme)),
          isSemantics(isSelected: true, isButton: true),
        );
        expect(affichee(tester), Brightness.dark);

        await tester.tap(find.bySemanticsLabel(t.commun.theme.clair));
        await tester.pumpAndSettle();
        expect(choix(), PreferenceTheme.clair);
        expect(affichee(tester), Brightness.light);
        expect(
          tester.getSemantics(find.bySemanticsLabel(t.commun.theme.clair)),
          isSemantics(isSelected: true),
        );

        await tester.tap(find.bySemanticsLabel(t.commun.theme.sombre));
        await tester.pumpAndSettle();
        expect(choix(), PreferenceTheme.sombre);
        expect(affichee(tester), Brightness.dark);

        await tester.tap(find.bySemanticsLabel(t.commun.theme.systeme));
        await tester.pumpAndSettle();
        expect(choix(), PreferenceTheme.systeme);
        expect(affichee(tester), Brightness.dark);

        await verifierCibles(tester);
        expect(tester.takeException(), isNull);
        semantique.dispose();
      });
    }

    testWidgets('sur carte les icones sont empilees, en en-tete alignees', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      Offset centre(String libelle) =>
          tester.getCenter(find.bySemanticsLabel(libelle));

      await tester.pumpWidget(appli(const SelecteurTheme()));
      expect(centre(t.commun.theme.clair).dx, centre(t.commun.theme.sombre).dx);
      expect(
        centre(t.commun.theme.clair).dy,
        lessThan(centre(t.commun.theme.sombre).dy),
      );
      expect(
        centre(t.commun.theme.sombre).dy,
        lessThan(centre(t.commun.theme.systeme).dy),
      );

      await tester.pumpWidget(appli(const SelecteurTheme.entete()));
      expect(centre(t.commun.theme.clair).dy, centre(t.commun.theme.sombre).dy);
      expect(
        centre(t.commun.theme.sombre).dx,
        lessThan(centre(t.commun.theme.systeme).dx),
      );
      semantique.dispose();
    });

    testWidgets('le choix tape est memorise, puis relu au lancement', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      final StockagePreferencesMemoire stockage = StockagePreferencesMemoire();
      ProviderContainer lancer() {
        final ProviderContainer conteneur = ProviderContainer(
          overrides: <Override>[
            stockagePreferencesProvider.overrideWithValue(stockage),
          ],
        )..read(persistanceApparenceProvider);
        addTearDown(conteneur.dispose);
        return conteneur;
      }

      await tester.pumpWidget(appli(const SelecteurTheme(), lancer()));
      await tester.tap(find.bySemanticsLabel(t.commun.theme.sombre));
      await tester.pumpAndSettle();
      expect(stockage.valeurs[clefPreferenceTheme], 'sombre');

      final ProviderContainer relance = lancer();
      await tester.pumpWidget(appli(const SelecteurTheme(), relance));
      await tester.pumpAndSettle();
      expect(
        relance.read(preferencesLocalesProvider).theme,
        PreferenceTheme.sombre,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(t.commun.theme.sombre)),
        isSemantics(isSelected: true),
      );
      semantique.dispose();
    });
  });
}

/// La cible tactile standard, lue sans importer le jeton dans les attentes.
abstract final class AppTouchTargetTest {
  static const double standard = 48;
}
