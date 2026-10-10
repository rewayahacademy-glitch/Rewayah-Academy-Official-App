// CL-4.6 : la preparation de l'eleve (PRE-ELV-01, PRE-ERR-01).
// Les tests TOUCHENT les elements : « Entrer dans la classe », « Autoriser le
// micro » et « Continuer sans micro » se tapent ; aucune entree sans appui ;
// Interface guidee a une seule action principale ; le tuteur n'a aucune
// preparation ; reflow a 320 et texte a 200 %.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/salle/preparation_eleve.dart';
import 'package:rewayah_academy/features/salle/preparation_enseignant.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/chemins_tc_a.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../teaching_core/e/faux/faux_classe.dart';

const ResultatPreVol _pret = ResultatPreVol(
  microDisponible: true,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

const ResultatPreVol _bloque = ResultatPreVol(
  microDisponible: false,
  cameraDisponible: false,
  sortieAudioDisponible: true,
  permissionRefusee: true,
);

const ResultatPreVol _sansMicro = ResultatPreVol(
  microDisponible: false,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

/// Les compteurs d'appui.
class _Appuis {
  int entrer = 0;
  int sansMicro = 0;
  int reessayer = 0;
}

Widget _hote({
  required ResultatPreVol? resultat,
  required ReseauPreparation? reseau,
  required _Appuis appuis,
  bool guidee = false,
  Size taille = const Size(390, 1200),
  double texte = 1,
  VoidCallback? onOuvrirReglages,
}) => TranslationProvider(
  child: MaterialApp(
    theme: AppTheme.pour(
      guidee ? InterfaceMode.enfant : InterfaceMode.standard,
      Brightness.light,
    ),
    home: MediaQuery(
      data: MediaQueryData(size: taille, textScaler: TextScaler.linear(texte)),
      child: Scaffold(
        body: PreparationEleve(
          resultat: resultat,
          reseau: reseau,
          guidee: guidee,
          onEntrer: () => appuis.entrer++,
          onContinuerSansMicro: () => appuis.sansMicro++,
          onReessayer: () => appuis.reessayer++,
          onRetour: () {},
          onOuvrirReglages: onOuvrirReglages,
        ),
      ),
    ),
  ),
);

Future<void> _poser(
  WidgetTester tester, {
  required ResultatPreVol? resultat,
  required ReseauPreparation? reseau,
  _Appuis? appuis,
  bool guidee = false,
  Size taille = const Size(390, 1200),
  double texte = 1,
  VoidCallback? onOuvrirReglages,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _hote(
      resultat: resultat,
      reseau: reseau,
      appuis: appuis ?? _Appuis(),
      guidee: guidee,
      taille: taille,
      texte: texte,
      onOuvrirReglages: onOuvrirReglages,
    ),
  );
  await tester.pump();
}

final Finder _entrer = find.byKey(const ValueKey<String>('preparation-entrer'));
final Finder _autoriser = find.byKey(
  const ValueKey<String>('preparation-autoriser-micro'),
);
final Finder _continuer = find.byKey(
  const ValueKey<String>('preparation-continuer-sans-micro'),
);

/// Les situations : (resultat, reseau).
const List<(ResultatPreVol?, ReseauPreparation?)> _situations =
    <(ResultatPreVol?, ReseauPreparation?)>[
      (null, null),
      (_pret, ReseauPreparation.bonne),
      (_bloque, ReseauPreparation.bonne),
      (_sansMicro, ReseauPreparation.bonne),
      (_pret, ReseauPreparation.horsLigne),
    ];

SessionState _session(AppRole role, {bool guidee = false}) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  interfaceMode: guidee ? InterfaceMode.enfant : InterfaceMode.standard,
);

List<Override> _surcharges({
  required AppRole role,
  required FauxServiceVideo video,
  required FauxServicePreVol preVol,
  bool guidee = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_session(role, guidee: guidee)),
  ),
  servicePreVolProvider.overrideWithValue(preVol),
  serviceVideoProvider.overrideWithValue(video),
  moteurSalleProvider.overrideWithValue(FauxMoteurSalle()),
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(),
  ),
  portAnnonceObservationProvider.overrideWithValue(FauxAnnonceObservation()),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
];

Future<void> _monterSalle(
  WidgetTester tester, {
  required List<Override> surcharges,
  String? groupeId,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.salle,
      surcharges: surcharges,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState _) =>
              SallePage(seanceId: 's1', preparation: true, groupeId: groupeId),
        ),
        GoRoute(
          path: Routes.racinePour(AppRole.student),
          builder: (BuildContext _, GoRouterState _) =>
              const Text('accueil eleve'),
        ),
        GoRoute(
          path: CheminsTcA.espaceGroupe('g1'),
          builder: (BuildContext _, GoRouterState _) =>
              const Text('espace classe'),
        ),
      ],
    ),
  );
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('verification, puis pret, puis « Entrer dans la classe » tape', (
    WidgetTester tester,
  ) async {
    final _Appuis appuis = _Appuis();
    await _poser(tester, resultat: null, reseau: null, appuis: appuis);
    expect(find.text(t.salle.preparation.eleve.verification), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('etat-connexion-verification')),
      findsOneWidget,
    );
    expect(_entrer, findsNothing);

    // Chaque ligne evolue seule : le reseau rend avant le materiel.
    await _poser(
      tester,
      resultat: null,
      reseau: ReseauPreparation.bonne,
      appuis: appuis,
    );
    expect(
      find.byKey(const ValueKey<String>('etat-connexion-ok')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('etat-audio-verification')),
      findsOneWidget,
    );
    expect(find.text(t.salle.preparation.eleve.verification), findsOneWidget);

    await _poser(
      tester,
      resultat: _pret,
      reseau: ReseauPreparation.bonne,
      appuis: appuis,
    );
    expect(find.text(t.salle.preparation.eleve.pret), findsOneWidget);
    expect(find.text(t.salle.preparation.connexion), findsOneWidget);
    expect(find.text(t.salle.preparation.eleve.audio), findsOneWidget);
    expect(find.text(t.salle.preparation.eleve.acces), findsOneWidget);
    expect(find.text(t.salle.preparation.eleve.microCoupe), findsOneWidget);
    // Minimal : ni apercu camera, ni contexte detaille.
    expect(find.text(t.salle.preparation.cameraCoupee), findsNothing);
    expect(find.text(t.salle.preparation.contexte), findsNothing);
    expect(appuis.entrer, 0);

    await tester.tap(_entrer);
    await tester.pump();
    expect(appuis.entrer, 1);
  });

  testWidgets('une seule annonce, a la fin des verifications', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _poser(tester, resultat: null, reseau: null);
    expect(
      tester.getSemantics(find.text(t.salle.preparation.eleve.verification)),
      isNot(matchesSemantics(isLiveRegion: true, isHeader: true)),
    );
    await _poser(tester, resultat: _pret, reseau: ReseauPreparation.bonne);
    expect(
      tester.getSemantics(find.text(t.salle.preparation.eleve.pret)),
      matchesSemantics(
        label: t.salle.preparation.eleve.pret,
        isLiveRegion: true,
        isHeader: true,
      ),
    );
    semantique.dispose();
  });

  testWidgets('salle : jamais d entree sans appui, puis un seul appui', (
    WidgetTester tester,
  ) async {
    final FauxServiceVideo video = FauxServiceVideo();
    await _monterSalle(
      tester,
      surcharges: _surcharges(
        role: AppRole.student,
        video: video,
        preVol: FauxServicePreVol(),
      ),
    );
    expect(find.byType(PreparationEleve), findsOneWidget);
    expect(find.text(t.salle.preparation.eleve.pret), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(video.demandes, isEmpty);

    await tester.tap(_entrer);
    await tester.pump();
    await tester.pump();
    expect(find.byType(PreparationEleve), findsNothing);
    expect(video.demandes, <String>['s1']);
  });

  testWidgets('micro bloque sans action reelle : « Reessayer », jamais '
      '« Autoriser »', (WidgetTester tester) async {
    for (final bool guidee in <bool>[false, true]) {
      final _Appuis appuis = _Appuis();
      await _poser(
        tester,
        resultat: _bloque,
        reseau: ReseauPreparation.bonne,
        appuis: appuis,
        guidee: guidee,
      );
      expect(_autoriser, findsNothing, reason: '$guidee');
      expect(find.text(t.salle.preparation.eleve.autoriserMicro), findsNothing);
      expect(
        find.text(t.salle.preparation.eleve.guidee.microQuestion),
        findsNothing,
      );
      final Finder reessayer = find.byKey(
        const ValueKey<String>('preparation-reessayer'),
      );
      expect(
        tester.widget<ActionPrincipale>(reessayer).niveau,
        NiveauAction.principale,
      );
      await tester.tap(reessayer);
      await tester.tap(_continuer);
      await tester.pump();
      expect(appuis.reessayer, 1);
      expect(appuis.sansMicro, 1);
    }
  });

  testWidgets('micro bloque : « Autoriser le micro » ouvre la feuille CL-7', (
    WidgetTester tester,
  ) async {
    final _Appuis appuis = _Appuis();
    await _poser(
      tester,
      resultat: _bloque,
      reseau: ReseauPreparation.bonne,
      appuis: appuis,
      onOuvrirReglages: () {},
    );
    expect(
      find.text(t.salle.preparation.eleve.microInaccessible),
      findsOneWidget,
    );
    expect(
      find.text(t.salle.preparation.eleve.microInaccessibleDetail),
      findsOneWidget,
    );
    expect(
      tester.widget<ActionPrincipale>(_autoriser).niveau,
      NiveauAction.principale,
    );
    expect(
      tester.widget<ActionPrincipale>(_continuer).niveau,
      NiveauAction.secondaire,
    );
    expect(_entrer, findsNothing);

    // La feuille prend le focus, puis le rend au bouton a la fermeture.
    await tester.tap(_autoriser);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('texte-micro-bloque')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('texte-micro-bloque')),
      findsNothing,
    );
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    expect(focus, isNotNull);
    expect(
      find.descendant(
        of: _autoriser,
        matching: find.byElementPredicate(
          (Element e) => identical(e, focus!.context),
        ),
      ),
      findsOneWidget,
      reason: '$focus',
    );

    // Dans la feuille : « Continuer sans micro ».
    await tester.tap(_autoriser);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('micro-bloque-continuer')),
    );
    await tester.pumpAndSettle();
    expect(appuis.sansMicro, 1);

    // Sur l'ecran : « Continuer sans micro », secondaire.
    await tester.tap(_continuer);
    await tester.pump();
    expect(appuis.sansMicro, 2);
    expect(appuis.entrer, 0);
  });

  testWidgets('aucun micro : « Reessayer » en principal, jamais d impasse', (
    WidgetTester tester,
  ) async {
    final _Appuis appuis = _Appuis();
    await _poser(
      tester,
      resultat: _sansMicro,
      reseau: ReseauPreparation.bonne,
      appuis: appuis,
    );
    expect(_autoriser, findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('preparation-reessayer')),
    );
    await tester.tap(_continuer);
    await tester.pump();
    expect(appuis.reessayer, 1);
    expect(appuis.sansMicro, 1);
  });

  testWidgets('salle : « Continuer sans micro » entre, micro coupe', (
    WidgetTester tester,
  ) async {
    final FauxServiceVideo video = FauxServiceVideo();
    await _monterSalle(
      tester,
      surcharges: _surcharges(
        role: AppRole.student,
        video: video,
        preVol: FauxServicePreVol(
          microDisponible: false,
          permissionRefusee: true,
        ),
      ),
    );
    expect(
      find.text(t.salle.preparation.eleve.microInaccessible),
      findsOneWidget,
    );
    expect(video.demandes, isEmpty);
    await tester.tap(_continuer);
    await tester.pump();
    await tester.pump();
    expect(video.demandes, <String>['s1']);
  });

  testWidgets('aucun terme technique brut, dans aucun etat', (
    WidgetTester tester,
  ) async {
    final RegExp brut = RegExp(
      r'\b(ICE|RTP|SDP|TURN|WebRTC|LiveKit|Exception|Error|null|Mbps)\b',
    );
    for (final bool guidee in <bool>[false, true]) {
      for (final (ResultatPreVol? r, ReseauPreparation? n) in _situations) {
        await _poser(tester, resultat: r, reseau: n, guidee: guidee);
        for (final Text texte in tester.widgetList<Text>(find.byType(Text))) {
          expect(brut.hasMatch(texte.data ?? ''), isFalse, reason: texte.data);
        }
      }
    }
  });

  testWidgets('Interface guidee : une seule action principale, sans liste', (
    WidgetTester tester,
  ) async {
    for (final (ResultatPreVol? r, ReseauPreparation? n) in _situations) {
      await _poser(tester, resultat: r, reseau: n, guidee: true);
      expect(find.byType(GroupeReglages), findsNothing);
      final int principales = tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
          .where((ActionPrincipale a) => a.niveau == NiveauAction.principale)
          .length;
      expect(principales, r == null ? 0 : 1, reason: '$r $n');
    }
    // Micro bloque : une seule question, une seule action principale.
    final _Appuis appuis = _Appuis();
    await _poser(
      tester,
      resultat: _bloque,
      reseau: ReseauPreparation.bonne,
      appuis: appuis,
      guidee: true,
    );
    expect(
      find.text(t.salle.preparation.eleve.guidee.microBloque),
      findsOneWidget,
    );
    expect(
      tester.widget<ActionPrincipale>(_continuer).niveau,
      NiveauAction.tertiaire,
    );
    await tester.tap(_continuer);
    await tester.pump();
    expect(appuis.sansMicro, 1);
  });

  testWidgets('salle, Interface guidee : la preparation guidee s ouvre', (
    WidgetTester tester,
  ) async {
    await _monterSalle(
      tester,
      surcharges: _surcharges(
        role: AppRole.student,
        video: FauxServiceVideo(),
        preVol: FauxServicePreVol(),
        guidee: true,
      ),
    );
    expect(find.text(t.salle.preparation.eleve.guidee.pret), findsOneWidget);
    expect(find.byType(GroupeReglages), findsNothing);
  });

  testWidgets('salle, Interface guidee : « Retour a l accueil » mene a '
      'l accueil de l eleve (spec 02 §2.2)', (WidgetTester tester) async {
    await _monterSalle(
      tester,
      groupeId: 'g1',
      surcharges: _surcharges(
        role: AppRole.student,
        video: FauxServiceVideo(),
        preVol: FauxServicePreVol(),
        guidee: true,
      ),
    );
    expect(find.text(t.salle.retourAccueil), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('preparation-retour')));
    await tester.pumpAndSettle();
    expect(find.text('accueil eleve'), findsOneWidget);
    expect(find.text('espace classe'), findsNothing);
  });

  testWidgets('salle, standard : « Retour a la Classe » mene a la Classe', (
    WidgetTester tester,
  ) async {
    await _monterSalle(
      tester,
      groupeId: 'g1',
      surcharges: _surcharges(
        role: AppRole.student,
        video: FauxServiceVideo(),
        preVol: FauxServicePreVol(),
      ),
    );
    expect(find.text(t.salle.preparation.retour), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('preparation-retour')));
    await tester.pumpAndSettle();
    expect(find.text('espace classe'), findsOneWidget);
  });

  for (final AppRole role in <AppRole>[AppRole.admin, AppRole.controller]) {
    testWidgets('${role.name} avec preparation : jamais la preparation '
        'enseignant, le comportement de son role', (WidgetTester tester) async {
      final FauxServiceVideo video = FauxServiceVideo();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          role: role,
          video: video,
          preVol: FauxServicePreVol(),
        ),
      );
      expect(find.byType(PreparationEnseignant), findsNothing);
      expect(find.byType(PreparationEleve), findsNothing);
      expect(video.demandes, <String>['s1']);
    });
  }

  testWidgets('tuteur observateur : aucune preparation (D-14)', (
    WidgetTester tester,
  ) async {
    final FauxServiceVideo video = FauxServiceVideo();
    await _monterSalle(
      tester,
      surcharges: _surcharges(
        role: AppRole.guardian,
        video: video,
        preVol: FauxServicePreVol(),
      ),
    );
    expect(find.byType(PreparationEleve), findsNothing);
    expect(find.byType(PreparationEnseignant), findsNothing);
    expect(video.demandes, <String>['s1']);
  });

  testWidgets('tuteur adulte + capacite « eleve autonome » : la preparation '
      'de l\'eleve s\'ouvre (EA-ROLE-1)', (WidgetTester tester) async {
    final FauxServiceVideo video = FauxServiceVideo();
    await _monterSalle(
      tester,
      surcharges: <Override>[
        ..._surcharges(
          role: AppRole.guardian,
          video: video,
          preVol: FauxServicePreVol(),
        ),
        portCapaciteEleveProvider.overrideWithValue(
          const PortCapaciteEleveFactice(autonomes: <String>{'p1'}),
        ),
      ],
    );
    expect(find.byType(PreparationEleve), findsOneWidget);
    expect(video.demandes, isEmpty);
  });

  testWidgets('reflow a 320 et texte a 200 % : aucun debordement', (
    WidgetTester tester,
  ) async {
    for (final bool guidee in <bool>[false, true]) {
      for (final (ResultatPreVol? r, ReseauPreparation? n) in _situations) {
        await _poser(
          tester,
          resultat: r,
          reseau: n,
          guidee: guidee,
          taille: const Size(320, 2400),
          texte: 2,
        );
        expect(tester.takeException(), isNull, reason: '$guidee $r $n');
      }
    }
    await _poser(
      tester,
      resultat: _pret,
      reseau: ReseauPreparation.bonne,
      taille: const Size(320, 2400),
      texte: 2,
    );
    // Pleine largeur sur mobile.
    expect(tester.getSize(_entrer).width, greaterThan(320 - 2 * 16 - 64));
  });

  testWidgets('demonstration : les huit etats s ouvrent sans serveur', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final bool guidee in <bool>[false, true]) {
      for (final PreparationEleveDemo etat in PreparationEleveDemo.values) {
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                home: EcranPreparationEleveDemo(etat: etat, guidee: guidee),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(PreparationEleve), findsOneWidget);
        expect(
          _entrer.evaluate().isNotEmpty,
          etat == PreparationEleveDemo.pret,
          reason: '${etat.name} $guidee',
        );
      }
    }
  });

  group('Capture : CL-4.6', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final PreparationEleveDemo etat in <PreparationEleveDemo>[
      PreparationEleveDemo.pret,
      PreparationEleveDemo.microBloque,
    ]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 900)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'cl46_preparation_eleve_${etat.name}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(
                EcranPreparationEleveDemo(etat: etat),
                themeMode: mode,
              ),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
    testWidgets('cl46_preparation_eleve_guidee_pret_390_light', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const EcranPreparationEleveDemo(
            etat: PreparationEleveDemo.pret,
            guidee: true,
          ),
          interfaceMode: InterfaceMode.enfant,
        ),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'cl46_preparation_eleve_guidee_pret_390_light')}',
      );
    });
  });
}
