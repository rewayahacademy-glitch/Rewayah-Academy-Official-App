// AD-11 : criteres de recette non prouves jusqu'ici, depuis la VRAIE coque
// admin et le vrai routeur en demonstration (`?demo=admin`) :
//  - tuile compteur de l'Accueil -> route canonique, et le compteur baisse
//    apres une decision reussie ;
//  - etats 02A « Actualisation des dossiers… », « Ce dossier n'est plus
//    disponible dans la file. », « La consultation des dossiers est
//    indisponible pour le moment. » (captures avec CAPTURE_DIR) ;
//  - hover et focus visibles sur ordinateur (22.7) ;
//  - contraste des StatusPill de la file (UX_REVIEW modification 28) ;
//  - purge des donnees controlees : deconnexion, changement de compte,
//    reponse tardive (22.4, 26 quater) ;
//  - date absente : « Date de depot indisponible ».

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/admin_dossiers/textes_dossier.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../capture/outil_capture.dart';

Future<void> _stab(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le port de demonstration, pilotable : retenue, panne, dossier retire.
class _PortPilote implements PortRevueDossiers {
  _PortPilote(this.demo);

  final RevueDossiersDemo demo;
  Completer<void>? retenue;
  Exception? erreurListe;
  final Set<String> introuvables = <String>{};

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) async {
    final Completer<void>? r = retenue;
    if (r != null) await r.future;
    final Exception? e = erreurListe;
    if (e != null) throw e;
    return demo.listerDossiers(curseur: curseur, limite: limite, role: role);
  }

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) =>
      introuvables.contains(dossierId)
      ? Future<DossierPourRevue>.error(
          const ErreurRevueDossier(CodeErreurRevue.introuvable),
        )
      : demo.dossierPourRevue(dossierId);

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) => demo.demanderVuePiece(dossierId: dossierId, documentId: documentId);

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) => demo.decider(
    dossierId: dossierId,
    revisionAttendue: revisionAttendue,
    decision: decision,
    commandeId: commandeId,
    verificationsFaites: verificationsFaites,
    motif: motif,
  );

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => demo.resultatDecision(dossierId: dossierId, commandeId: commandeId);
}

/// Les surcharges de demonstration, le port remplace par [port].
List<Override> _surcharges(EtatRevueDemo etat, {PortRevueDossiers? port}) {
  final List<Override> base = surchargesDemoAdmin(
    environnement: 'staging',
    etat: etat,
  );
  if (port == null) return base;
  final String marque = '$portRevueDossiersProvider.override';
  final List<Override> reste = <Override>[
    for (final Override o in base)
      if (!o.toString().startsWith(marque)) o,
  ];
  expect(reste.length, base.length - 1, reason: 'port de demo introuvable');
  return <Override>[
    ...reste,
    portRevueDossiersProvider.overrideWithValue(port),
  ];
}

Future<GoRouter> _monter(
  WidgetTester tester,
  Size taille, {
  required EtatRevueDemo etat,
  PortRevueDossiers? port,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(etat, port: port),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    ),
  );
  await _stab(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(Routes.admin);
  await _stab(tester);
  return routeur;
}

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

Future<void> _barre(WidgetTester tester, AdminDomaine d) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(AdminShell.barreLateraleKey),
      matching: find.text(d.libelle),
    ),
  );
  await _stab(tester);
}

Finder _tuileDossiers() => find.byWidgetPredicate(
  (Widget w) => w is StatTile && w.libelle == t.admin.tableau.dossiers,
);

Future<void> _capture(WidgetTester tester, String nom) async {
  if (dossierCapture != null) {
    debugPrint('PNG ${await capturer(tester, nom)}');
  }
}

/// Demonte l'arbre : le conteneur annule ses relances en attente.
Future<void> _demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double h = la > lb ? la : lb;
  final double l = la > lb ? lb : la;
  return (h + 0.05) / (l + 0.05);
}

/// Les appels de peinture de la surface (Material) qui porte [ligne] :
/// encre de survol, anneau de focus, fond compris. Deux relevés différents
/// = un changement visible (couleurs et formes sont dans les arguments).
List<String> _peinture(WidgetTester tester, Finder ligne) {
  // Le fond de ligne (DecoratedBox) et tout decor de focus (anneau), dans
  // le sous-arbre de la ligne et jusqu'a sa surface.
  final Finder decors = find.descendant(
    of: find.ancestor(of: ligne, matching: find.byType(Material)).first,
    matching: find.byType(DecoratedBox),
  );
  final Rect zone = tester.getRect(ligne);
  return <String>[
    for (final Element e in decors.evaluate())
      if (e.renderObject is RenderBox &&
          (e.renderObject! as RenderBox).hasSize &&
          zone.inflate(4).contains(tester.getCenter(find.byWidget(e.widget))))
        '${(e.widget as DecoratedBox).decoration}',
  ];
}

class _SourceControlee implements SourceSession {
  // Ferme dans le tearDown du groupe de purge.
  // ignore: close_sinks
  final StreamController<SessionState> flux =
      StreamController<SessionState>.broadcast();

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

SessionState _admin(String id) => SessionState(
  resolue: true,
  role: AppRole.admin,
  profileId: id,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

/// Chaque appel de la file reste en attente jusqu'a sa reponse.
class _PortParAppel extends _PortPilote {
  _PortParAppel() : super(RevueDossiersDemo(EtatRevueDemo.initial()));

  final List<Completer<PageDossiers>> appels = <Completer<PageDossiers>>[];

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) {
    final Completer<PageDossiers> c = Completer<PageDossiers>();
    appels.add(c);
    return c.future;
  }
}

PageDossiers _page(String id) => PageDossiers(
  elements: <DossierEnFile>[
    DossierEnFile(
      dossierId: id,
      nomAffiche: 'Personne $id',
      role: AppRole.teacher,
      soumisLeUtc: DateTime.utc(2026, 9, 20, 8),
      statut: StatutRevue.aVerifier,
      revision: 1,
      aPieceIdentite: true,
      etatPiece: EtatPieceRevue.disponible,
    ),
  ],
  curseurSuivant: null,
  total: 1,
);

void main() {
  setUpAll(() async {
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });

  group('AD-11 Accueil : la tuile compteur des dossiers', () {
    testWidgets('mene a la route canonique, puis baisse apres une decision', (
      WidgetTester tester,
    ) async {
      final EtatRevueDemo etat = EtatRevueDemo.initial();
      final int avant = etat.nombreAVerifier;
      final GoRouter routeur = await _monter(
        tester,
        const Size(1440, 900),
        etat: etat,
      );
      expect(tester.widget<StatTile>(_tuileDossiers()).valeur, avant);
      await tester.ensureVisible(_tuileDossiers());
      await tester.tap(_tuileDossiers());
      await _stab(tester);
      expect(_chemin(routeur), Routes.adminPersonnesDossiers);

      // Decision reussie depuis la revue (Omar, selectionne d'office).
      for (final String p in <String>[
        t.dossiers.pointLisible,
        t.dossiers.pointNom,
        t.dossiers.pointValidite,
      ]) {
        await tester.ensureVisible(find.text(p).first);
        await _stab(tester);
        await tester.tap(find.text(p).first);
        await _stab(tester);
      }
      await tester.ensureVisible(find.text(t.dossiers.approuver));
      await tester.tap(find.text(t.dossiers.approuver));
      await _stab(tester);
      await tester.tap(find.text(t.dossiers.approuver).last);
      await _stab(tester);
      expect(etat.nombreAVerifier, avant - 1);

      await _barre(tester, AdminDomaine.accueil);
      expect(_chemin(routeur), Routes.admin);
      expect(tester.widget<StatTile>(_tuileDossiers()).valeur, avant - 1);
      expect(
        find.bySemanticsLabel(
          RegExp('^${avant - 1} ${RegExp.escape(t.admin.tableau.dossiers)}'),
        ),
        findsOneWidget,
      );
    });
  });

  group('AD-11 02A : etats de la file', () {
    testWidgets('« Actualisation des dossiers… » pendant la relecture', (
      WidgetTester tester,
    ) async {
      final EtatRevueDemo etat = EtatRevueDemo.initial();
      final _PortPilote port = _PortPilote(RevueDossiersDemo(etat));
      await _monter(tester, const Size(1440, 900), etat: etat, port: port);
      await _barre(tester, AdminDomaine.personnes);
      expect(_ligne('Omar'), findsOneWidget);
      port.retenue = Completer<void>();
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is ActionPrincipale && w.libelle == t.dossiers.file.actualiser,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(t.dossiers.file.actualisation), findsOneWidget);
      // La liste deja autorisee reste pendant la relecture.
      expect(_ligne('Omar'), findsOneWidget);
      await _capture(tester, 'ad11_02A_actualisation_1440');
      port.retenue!.complete();
      port.retenue = null;
      await _stab(tester);
      expect(find.text(t.dossiers.file.actualisation), findsNothing);
    });

    testWidgets('« Ce dossier n’est plus disponible dans la file. »', (
      WidgetTester tester,
    ) async {
      final EtatRevueDemo etat = EtatRevueDemo.initial();
      final _PortPilote port = _PortPilote(RevueDossiersDemo(etat))
        ..introuvables.add(DonneesDossiersDemo.enseignantNominal);
      await _monter(tester, const Size(1440, 900), etat: etat, port: port);
      await _barre(tester, AdminDomaine.personnes);
      expect(find.text(t.dossiers.file.selectionRetiree), findsOneWidget);
      await _capture(tester, 'ad11_02A_selection_retiree_1440');
      // L'action du message relit la file et retire la selection.
      port.introuvables.clear();
      await tester.tap(find.text(t.dossiers.file.actualiser).last);
      await _stab(tester);
      expect(find.text(t.dossiers.file.selectionRetiree), findsNothing);
    });

    testWidgets('« La consultation des dossiers est indisponible… »', (
      WidgetTester tester,
    ) async {
      final EtatRevueDemo etat = EtatRevueDemo.initial();
      final _PortPilote port = _PortPilote(RevueDossiersDemo(etat))
        ..erreurListe = const CapaciteIndisponible('AD-BR-01');
      await _monter(tester, const Size(390, 844), etat: etat, port: port);
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await _stab(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(AdminShell.tiroirKey),
          matching: find.text(AdminDomaine.personnes.libelle),
        ),
      );
      await _stab(tester);
      expect(find.text(t.dossiers.file.indisponible), findsOneWidget);
      // Aucune ligne de dossier n'est montree.
      expect(_ligne('Omar'), findsNothing);
      await _capture(tester, 'ad11_02A_indisponible_390');
      await _demonter(tester);
    });

    test('date absente : « Date de depot indisponible »', () {
      expect(dateRevue(null), t.dossiers.revue.dateIndisponible);
      expect(
        dateRevue(DateTime.utc(2026, 9, 5, 9, 7)),
        isNot(t.dossiers.revue.dateIndisponible),
      );
    });
  });

  group('AD-11 22.7 : hover et focus visibles sur ordinateur', () {
    // Tranche au passage 6 : limite du banc, pas defaut de l'ecran. Le banc
    // allait au domaine par un toucher (tester.tap, doigt), ce qui met le
    // FocusManager en mode « touch » ; en ce mode Flutter ne montre aucun
    // survol (FocusableActionDetector), et un simple deplacement de souris ne
    // le rebascule pas. Sur un poste, la barre laterale se clique a la souris
    // (mode « traditional ») : le banc fait de meme.
    for (final bool survolExige in <bool>[false, true]) {
      testWidgets(
        survolExige
            ? 'la ligne Amina change au survol'
            : 'la ligne Amina montre le focus clavier',
        (WidgetTester tester) async {
          await _corps22_7(tester, survolExige: survolExige);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
    }
  });

  _suite();
}

Future<void> _corps22_7(
  WidgetTester tester, {
  required bool survolExige,
}) async {
  {
    {
      await _monter(
        tester,
        const Size(1440, 900),
        etat: EtatRevueDemo.initial(),
      );
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: const Offset(1439, 899));
      addTearDown(souris.removePointer);
      // Le domaine se choisit d'un clic de souris, comme sur un poste.
      final Offset domaine = tester.getCenter(
        find.descendant(
          of: find.byKey(AdminShell.barreLateraleKey),
          matching: find.text(AdminDomaine.personnes.libelle),
        ),
      );
      await souris.moveTo(domaine);
      await souris.down(domaine);
      await souris.up();
      await _stab(tester);
      final Finder ligne = _ligne('Amina');
      final Rect zone = tester.getRect(ligne);
      await souris.moveTo(const Offset(1439, 899));
      await _stab(tester);
      final List<String> repos = _peinture(tester, ligne);

      await souris.moveTo(zone.center);
      await _stab(tester);
      final List<String> survol = _peinture(tester, ligne);
      if (survolExige) {
        expect(
          survol,
          isNot(equals(repos)),
          reason: 'aucun retour visuel au survol de la ligne',
        );
        return;
      }

      await souris.moveTo(const Offset(1439, 899));
      await _stab(tester);
      bool atteint = false;
      for (int i = 0; i < 60 && !atteint; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _stab(tester);
        final FocusNode? n = FocusManager.instance.primaryFocus;
        atteint = n != null && zone.contains(n.rect.center);
      }
      expect(atteint, isTrue, reason: 'la ligne n est pas atteinte au Tab');
      final List<String> focus = _peinture(tester, ligne);
      expect(
        focus,
        isNot(equals(repos)),
        reason: 'aucun indicateur de focus visible sur la ligne',
      );
    }
  }
}

void _suite() {
  group('AD-11 UX 28 : contraste des StatusPill de la file', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('texte >= 4,5:1 et pastille >= 3:1 (${mode.name})', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _monter(
          tester,
          const Size(1440, 900),
          etat: EtatRevueDemo.initial(),
        );
        await _barre(tester, AdminDomaine.personnes);
        final Finder pills = find.descendant(
          of: find.byKey(const PageStorageKey<String>('adm02a-file')),
          matching: find.byType(StatusPill),
        );
        expect(pills, findsWidgets);
        for (final Element p in pills.evaluate()) {
          final Finder f = find.byWidget(p.widget);
          final Container boite = tester.widget<Container>(
            find.descendant(of: f, matching: find.byType(Container)).first,
          );
          final Color fond = (boite.decoration! as BoxDecoration).color!;
          final Color encre = tester
              .renderObject<RenderParagraph>(
                find.descendant(of: f, matching: find.byType(RichText)),
              )
              .text
              .style!
              .color!;
          final String mot = (p.widget as StatusPill).libelle;
          expect(
            _contraste(encre, fond),
            greaterThanOrEqualTo(4.5),
            reason: '« $mot » : texte sur fond',
          );
          final DecoratedBox disque = tester.widget<DecoratedBox>(
            find.descendant(of: f, matching: find.byType(DecoratedBox)).last,
          );
          final Color point = (disque.decoration as BoxDecoration).color!;
          expect(
            _contraste(point, fond),
            greaterThanOrEqualTo(3),
            reason: '« $mot » : pastille sur fond',
          );
        }
      });
    }
  });

  group('AD-11 22.4 : purge des donnees controlees', () {
    late _SourceControlee source;
    late _PortParAppel port;
    late ProviderContainer c;

    setUp(() {
      source = _SourceControlee();
      port = _PortParAppel();
      c = ProviderContainer(
        overrides: <Override>[
          sourceSessionProvider.overrideWithValue(source),
          portRevueDossiersProvider.overrideWithValue(port),
        ],
      );
      c.listen(fileDossiersProvider, (Object? _, Object? _) {});
      c.listen(selectionDossierProvider, (Object? _, Object? _) {});
      c.read(sessionProvider);
    });

    tearDown(() async {
      c.dispose();
      await source.flux.close();
    });

    List<String>? ids() => c
        .read(fileDossiersProvider)
        .value
        ?.elements
        .map((DossierEnFile e) => e.dossierId)
        .toList();

    Future<void> ouvrir(String profil, String dossier) async {
      source.flux.add(_admin(profil));
      await pumpEventQueue();
      port.appels.last.complete(_page(dossier));
      await pumpEventQueue();
      expect(ids(), <String>[dossier]);
    }

    test('deconnexion : la file et la selection sont effacees', () async {
      await ouvrir('admin-A', 'dossier-A');
      c.read(selectionDossierProvider.notifier).choisir('dossier-A');
      source.flux.add(const SessionState.deconnecte());
      await pumpEventQueue();
      expect(
        ids() ?? <String>[],
        isEmpty,
        reason: 'la file de A survit a la deconnexion',
      );
      expect(c.read(selectionDossierProvider).dossierId, isNull);
    });

    test('changement de compte : rien du compte precedent', () async {
      await ouvrir('admin-A', 'dossier-A');
      c.read(selectionDossierProvider.notifier).choisir('dossier-A');
      source.flux.add(_admin('admin-B'));
      await pumpEventQueue();
      expect(
        ids() ?? <String>[],
        isEmpty,
        reason: 'la file de A est vue par B',
      );
      expect(c.read(selectionDossierProvider).dossierId, isNull);
      port.appels.last.complete(_page('dossier-B'));
      await pumpEventQueue();
      expect(ids(), <String>['dossier-B']);
    });

    test('reponse tardive visant le compte precedent : ignoree', () async {
      await ouvrir('admin-A', 'dossier-A');
      source.flux.add(_admin('admin-B'));
      await pumpEventQueue();
      final Completer<PageDossiers> tardive = port.appels.last;
      source.flux.add(_admin('admin-C'));
      await pumpEventQueue();
      tardive.complete(_page('dossier-B'));
      await pumpEventQueue();
      expect(ids(), isNot(contains('dossier-B')));
      port.appels.last.complete(_page('dossier-C'));
      await pumpEventQueue();
      expect(ids(), <String>['dossier-C']);
    });
  });
}
