// CL-4.5 : la preparation technique de l'enseignant (CLV-03, PRE-ENS-01).
// Les tests TOUCHENT les elements : le bouton se tape, la raison s'affiche
// au-dessus, le micro reste coupe a l'entree, chaque ligne evolue seule,
// reflow a 320 et texte a 200 %.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/salle/preparation_enseignant.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/tc_classe_live/pre_vol_classe.dart';

import '../../capture/outil_capture.dart';

const ResultatPreVol _pret = ResultatPreVol(
  microDisponible: true,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

const ResultatPreVol _sansMicro = ResultatPreVol(
  microDisponible: false,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

const ContextePreparation _contexte = ContextePreparation(
  classe: 'Classe An-Nour',
  debut: 'Dans 8 min',
  support: 'Sourate Al-Fatiha',
  reprise: 'Page 24',
  eleves: '6',
);

Future<void> _poser(
  WidgetTester tester, {
  required ResultatPreVol? resultat,
  ReseauPreparation? reseau = ReseauPreparation.bonne,
  bool sortieAudio = false,
  VoidCallback? onEntrer,
  VoidCallback? onTesterCamera,
  Size taille = const Size(1440, 1000),
  double texte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(texte),
          ),
          child: Scaffold(
            body: PreparationEnseignant(
              resultat: resultat,
              reseau: reseau,
              sortieAudioChoisissable: sortieAudio,
              contexte: _contexte,
              onEntrer: onEntrer ?? () {},
              onRetour: () {},
              onReessayer: () {},
              onTesterCamera: onTesterCamera,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ActionPrincipale _entrer(WidgetTester tester) =>
    tester.widget<ActionPrincipale>(
      find.byKey(const ValueKey<String>('preparation-entrer')),
    );

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('pret : « Entrer dans la classe » est actif et se tape', (
    WidgetTester tester,
  ) async {
    int entrees = 0;
    await _poser(tester, resultat: _pret, onEntrer: () => entrees++);

    expect(find.text(t.salle.preparation.titre), findsOneWidget);
    expect(find.text(t.salle.preparation.equipement), findsOneWidget);
    expect(find.text(t.salle.preparation.contexte), findsOneWidget);
    expect(find.text('Page 24'), findsOneWidget);
    expect(_entrer(tester).onPress, isNotNull);

    await tester.tap(find.text(t.salle.preparation.entrer));
    await tester.pump();
    expect(entrees, 1);
  });

  testWidgets('micro absent : bouton desactive, raison ecrite au-dessus', (
    WidgetTester tester,
  ) async {
    int entrees = 0;
    await _poser(tester, resultat: _sansMicro, onEntrer: () => entrees++);

    expect(_entrer(tester).onPress, isNull);
    final Finder raison = find.byKey(
      const ValueKey<String>('preparation-raison'),
    );
    expect(raison, findsOneWidget);
    expect(find.text(t.salle.preparation.microAbsentRaison), findsOneWidget);
    expect(find.text(t.salle.preparation.reessayer), findsOneWidget);
    expect(
      tester.getTopLeft(raison).dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('preparation-entrer')),
            )
            .dy,
      ),
    );

    await tester.tap(find.text(t.salle.preparation.entrer));
    await tester.pump();
    expect(entrees, 0);
  });

  testWidgets('permission refusee : message humain, pas de micro pret', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      resultat: const ResultatPreVol(
        microDisponible: false,
        cameraDisponible: false,
        sortieAudioDisponible: false,
        permissionRefusee: true,
      ),
    );
    expect(find.text(t.salle.preparation.permissionRefusee), findsOneWidget);
    expect(find.text(t.salle.preparation.microPret), findsNothing);
    expect(_entrer(tester).onPress, isNull);
  });

  testWidgets('reseau faible : l audio sera prioritaire, entree possible', (
    WidgetTester tester,
  ) async {
    await _poser(tester, resultat: _pret, reseau: ReseauPreparation.instable);
    expect(find.text(t.salle.preparation.reseauFaible), findsOneWidget);
    expect(_entrer(tester).onPress, isNotNull);
  });

  testWidgets('micro et camera coupes a l entree, jamais « activé »', (
    WidgetTester tester,
  ) async {
    await _poser(tester, resultat: _pret);
    expect(find.text(t.salle.preparation.microPret), findsOneWidget);
    expect(find.text(t.salle.preparation.cameraPrete), findsOneWidget);
    expect(find.textContaining('activé'), findsNothing);
    expect(find.text(t.salle.preparation.cameraCoupee), findsOneWidget);
  });

  testWidgets('« Tester la camera » n existe qu avec un vrai test (R10)', (
    WidgetTester tester,
  ) async {
    // Sans rappel branche : aucun bouton, jamais « Test local termine ».
    await _poser(tester, resultat: _pret);
    expect(find.text(t.salle.preparation.testerCamera), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('preparation-tester-camera')),
      findsNothing,
    );
    expect(find.text(t.salle.preparation.testCameraFait), findsNothing);

    // Avec un vrai rappel : le bouton existe, le test a lieu, puis le
    // message local s'affiche.
    int tests = 0;
    await _poser(tester, resultat: _pret, onTesterCamera: () => tests++);
    await tester.tap(find.text(t.salle.preparation.testerCamera));
    await tester.pump();
    expect(tests, 1);
    expect(find.text(t.salle.preparation.testCameraFait), findsOneWidget);
  });

  testWidgets('pas de sortie audio si la plateforme ne la choisit pas', (
    WidgetTester tester,
  ) async {
    await _poser(tester, resultat: _pret);
    expect(find.text(t.salle.preparation.sortieAudio), findsNothing);

    await _poser(tester, resultat: _pret, sortieAudio: true);
    expect(find.text(t.salle.preparation.sortieAudio), findsOneWidget);
  });

  testWidgets('chaque ligne evolue seule pendant la verification', (
    WidgetTester tester,
  ) async {
    // Le reseau a rendu, le materiel pas encore.
    await _poser(tester, resultat: null);
    expect(find.byKey(const ValueKey<String>('etat-connexion-ok')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('etat-micro-verification')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey<String>('etat-camera-verification')),
      findsOne,
    );
    expect(find.text(t.salle.preparation.connexionPrete), findsOneWidget);

    // Le materiel a rendu, le reseau pas encore.
    await _poser(tester, resultat: _pret, reseau: null);
    expect(
      find.byKey(const ValueKey<String>('etat-connexion-verification')),
      findsOne,
    );
    expect(find.byKey(const ValueKey<String>('etat-micro-ok')), findsOne);
    expect(find.byType(GroupeReglages), findsOneWidget);
  });

  testWidgets('verification : une ligne d etat, jamais un bouton grise', (
    WidgetTester tester,
  ) async {
    final Finder ligne = find.byKey(
      const ValueKey<String>('preparation-verification'),
    );
    final Finder bouton = find.byKey(
      const ValueKey<String>('preparation-entrer'),
    );
    for (final (ResultatPreVol? r, ReseauPreparation? n)
        in <(ResultatPreVol?, ReseauPreparation?)>[
          (null, null),
          (null, ReseauPreparation.bonne),
          (_pret, null),
        ]) {
      await _poser(tester, resultat: r, reseau: n);
      expect(bouton, findsNothing, reason: '$r $n');
      expect(ligne, findsOneWidget, reason: '$r $n');
      expect(
        find.descendant(
          of: ligne,
          matching: find.text(t.salle.preparation.verification),
        ),
        findsOneWidget,
      );
    }
    // Verifications rendues : la ligne cede la place au bouton actif.
    await _poser(tester, resultat: _pret);
    expect(ligne, findsNothing);
    expect(_entrer(tester).onPress, isNotNull);
  });

  testWidgets('bureau : deux volets ; sous 840, une colonne', (
    WidgetTester tester,
  ) async {
    await _poser(tester, resultat: _pret);
    final Offset apercu = tester.getTopLeft(
      find.text(t.salle.preparation.cameraCoupee),
    );
    final Offset equipement = tester.getTopLeft(
      find.text(t.salle.preparation.equipement),
    );
    expect(equipement.dx, greaterThan(apercu.dx));

    await _poser(tester, resultat: _pret, taille: const Size(768, 1400));
    expect(
      tester.getTopLeft(find.text(t.salle.preparation.equipement)).dy,
      greaterThan(
        tester.getTopLeft(find.text(t.salle.preparation.cameraCoupee)).dy,
      ),
    );
  });

  testWidgets('reflow a 320 et texte a 200 % : aucun debordement', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      resultat: _sansMicro,
      taille: const Size(320, 2400),
      texte: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text(t.salle.preparation.entrer), findsOneWidget);

    // A 1440 avec un texte a 200 %, 1440 / 2 < 840 : une seule colonne.
    await _poser(tester, resultat: _pret, texte: 2);
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text(t.salle.preparation.equipement)).dy,
      greaterThan(
        tester.getTopLeft(find.text(t.salle.preparation.cameraCoupee)).dy,
      ),
    );
  });

  test('eleve et tuteur ne recoivent pas le rendu complet', () {
    expect(
      VuePreCours.depuis(role: RoleSalle.eleve, resultat: _pret).detail,
      DetailPreCours.silencieux,
    );
    expect(
      VuePreCours.depuis(
        role: RoleSalle.tuteurObservateur,
        resultat: _pret,
      ).detail,
      DetailPreCours.aucun,
    );
    expect(
      VuePreCours.depuis(role: RoleSalle.enseignant, resultat: _pret).detail,
      DetailPreCours.complet,
    );
  });

  testWidgets('eleve : le pre-cours silencieux ne montre pas la preparation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: PreCours(
              vue: VuePreCours.depuis(role: RoleSalle.eleve, resultat: _pret),
              onReessayer: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(PreparationEnseignant), findsNothing);
    expect(find.text(t.salle.preparation.titre), findsNothing);
  });

  testWidgets('demonstration : les quatre etats s ouvrent sans serveur', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final PreparationDemo etat in PreparationDemo.values) {
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              home: EcranPreparationDemo(etat: etat),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(t.salle.preparation.titre), findsOneWidget);
      final bool actif =
          etat == PreparationDemo.pret || etat == PreparationDemo.reseauFaible;
      expect(_entrer(tester).onPress != null, actif, reason: etat.name);
    }
  });

  group('Capture : CL-4.5', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final PreparationDemo etat in <PreparationDemo>[
      PreparationDemo.pret,
      PreparationDemo.microAbsent,
    ]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 1500)),
        ('768', const Size(768, 1400)),
        ('1440', const Size(1440, 1000)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'cl45_preparation_${etat.name}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(EcranPreparationDemo(etat: etat), themeMode: mode),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
