// Emetteur QR du tuteur (lot D, sous-paquet 1) : parcours depuis la
// navigation, tous les etats, QR noir sur blanc dans les deux themes, retrait
// du code de l'ecran et de l'arbre semantique a la confirmation, mouvement
// reduit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/statut_code_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';
import 'package:rewayah_academy/features/appareils/emetteur_qr.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';
import 'faux_statut_code.dart';

final DateTime _depart = DateTime(2026, 9, 24, 18);

EleveDuFoyer _eleve() => const EleveDuFoyer(
  id: 'e1',
  prenom: 'Amina',
  identifiantImmuable: 'STUDENT-AD-000001',
  mode: InterfaceMode.enfant,
  camera: CameraPolicy.forbidden,
);

FauxServiceAppairage _service() => FauxServiceAppairage()
  ..elevesRendus = <EleveDuFoyer>[_eleve()]
  ..code = CodeAppairage(
    code: 'AB23CD',
    expireA: _depart.add(const Duration(minutes: 10)),
  );

const String _codeLisible = 'A B 2 3 C D';

/// Monte l'emetteur seul, sur un petit routeur qui porte ses retours.
Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAppairage service,
  required FauxStatutCode statut,
  HorlogePilotee? horloge,
  ServiceReseau? reseau,
  ThemeMode mode = ThemeMode.light,
  String depart = '/tuteur/foyer/appairer/e1',
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final HorlogePilotee h = horloge ?? HorlogePilotee(_depart);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceAppairageProvider.overrideWithValue(service),
        portStatutCodeAppairageProvider.overrideWithValue(statut),
        serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
        horlogeEmetteurProvider.overrideWithValue(h.lire),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: mode,
          routerConfig: GoRouter(
            initialLocation: depart,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.tuteurFoyer,
                builder: (BuildContext _, GoRouterState _) =>
                    const Text('ECRAN FOYER'),
              ),
              GoRoute(
                path: Routes.tuteurFoyerAppareils,
                builder: (BuildContext _, GoRouterState _) =>
                    const Text('ECRAN APPAREILS'),
              ),
              GoRoute(
                path: '${Routes.tuteurAppairer}/:eleveId',
                builder: (BuildContext _, GoRouterState etat) => AppairagePage(
                  eleveId: etat.pathParameters['eleveId'] ?? '',
                ),
              ),
              GoRoute(
                path: '${Routes.tuteurFoyer}/:eleveId/appareils',
                builder: (BuildContext _, GoRouterState etat) => Text(
                  'ECRAN APPAREILS DE ${etat.pathParameters['eleveId']}',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Finder _liveRegion() => find.byWidgetPredicate(
  (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
);

void main() {
  group('Parcours depuis la navigation (vrai routeur)', () {
    testWidgets(
      'Foyer puis profil puis « Connecter un appareil » ouvre l emetteur ; '
      'le retour ramene',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final FauxStatutCode statut = FauxStatutCode();
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesRouteur(
                FausseSourceSession(sessionActive(AppRole.guardian)),
                appairage: _service(),
              ),
              portStatutCodeAppairageProvider.overrideWithValue(statut),
              horlogeEmetteurProvider.overrideWithValue(
                HorlogePilotee(_depart).lire,
              ),
            ],
            child: TranslationProvider(
              child: Consumer(
                builder: (BuildContext _, WidgetRef ref, Widget? _) {
                  routeur = ref.read(routeurProvider);
                  return MaterialApp.router(
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    routerConfig: routeur,
                  );
                },
              ),
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(Routes.tuteurAccueil);
        await stabiliser(tester);

        // 1. Onglet Foyer de la barre basse.
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.tuteur.foyer),
          ),
        );
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurFoyer);

        // 2. La ligne de l eleve ouvre sa fiche ; la ligne Appareils de la
        // fiche, puis « Connecter un appareil » sur ses appareils (LD-3).
        final Finder ligne = find.text('Amina');
        await tester.ensureVisible(ligne);
        await tester.tap(ligne);
        await stabiliser(tester);
        expect(lieu(routeur), Routes.ficheElevePour('e1'));
        final Finder appareils = find.text(
          t.ficheEleve.lignes.appareils(prenom: 'Amina'),
        );
        await tester.ensureVisible(appareils);
        await tester.tap(appareils);
        await stabiliser(tester);
        expect(
          Uri.parse(lieu(routeur)).path,
          Routes.ficheEleveSousPage('e1', 'appareils'),
        );
        final Finder ajouter = find.text(t.appareils.eleve.connecter);
        await tester.ensureVisible(ajouter);
        await tester.tap(ajouter);
        await stabiliser(tester);

        expect(
          lieu(routeur),
          startsWith(Routes.appairerPour('e1')),
          reason: 'le bouton mene a l emetteur de cet eleve',
        );
        expect(find.byType(AppairagePage), findsOneWidget);
        expect(find.byType(EmetteurQr), findsOneWidget);
        expect(find.text(_codeLisible), findsOneWidget);
        expect(find.text(t.appareils.emetteur.consigneTitre), findsOneWidget);
        // Tache focalisee : pas de barre basse sur telephone.
        expect(find.byKey(NavShell.barreBasseKey), findsNothing);

        // 3. Le disque retour ramene aux appareils de l eleve d ou l on vient.
        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(
          Uri.parse(lieu(routeur)).path,
          Routes.ficheEleveSousPage('e1', 'appareils'),
        );
        expect(find.byType(EmetteurQr), findsNothing);

        // 4. Puis la fiche, puis le Foyer : aucune impasse.
        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.ficheElevePour('e1'));
        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurFoyer);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Etats de l emetteur', () {
    testWidgets('preparation : un squelette, jamais un faux QR', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = _AttenteSansFin()
        ..elevesRendus = <EleveDuFoyer>[_eleve()];
      await _monter(tester, service: service, statut: FauxStatutCode());

      expect(find.text(t.appareils.emetteur.preparation), findsOneWidget);
      expect(find.byType(EmetteurQr), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('actif : consigne, QR, code manuel, validite reelle', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = _service();
      await _monter(tester, service: service, statut: FauxStatutCode());

      expect(service.codesDemandes, <String>['e1']);
      expect(find.text(t.appareils.emetteur.consigneTitre), findsOneWidget);
      expect(find.text(t.appareils.emetteur.consigne), findsOneWidget);
      expect(find.byType(EmetteurQr), findsOneWidget);
      expect(find.text(_codeLisible), findsOneWidget);
      // L heure vient de `expires_at`, jamais d une duree codee en dur.
      expect(
        find.text(t.appareils.emetteur.valableJusqua(heure: '18:10')),
        findsOneWidget,
      );
      expect(
        find.text(t.appareils.emetteur.restant(temps: '10:00')),
        findsOneWidget,
      );
      expect(
        find.text(t.appareils.emetteur.sortie(heure: '18:10')),
        findsOneWidget,
      );
      expect(
        find.text(t.appareils.emetteur.pourEleve(prenom: 'Amina')),
        findsOneWidget,
      );
    });

    testWidgets('le compte a rebours ne s annonce pas a chaque seconde', (
      WidgetTester tester,
    ) async {
      await _monter(tester, service: _service(), statut: FauxStatutCode());
      expect(
        find.ancestor(
          of: find.textContaining('Encore'),
          matching: _liveRegion(),
        ),
        findsNothing,
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('QR noir sur blanc en theme ${mode.name}', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          service: _service(),
          statut: FauxStatutCode(),
          mode: mode,
        );
        final QrImageView qr = tester.widget<QrImageView>(
          find.byType(QrImageView),
        );
        // La paire dediee (demande D-1) : la meme en clair et en sombre.
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(EmetteurQr)),
        );
        expect(qr.backgroundColor, const Color(0xFFFFFFFF));
        expect(qr.backgroundColor, palette.contenuQr.background);
        expect(qr.dataModuleStyle.color, palette.contenuQr.onBackground);
        expect(qr.eyeStyle.color, palette.contenuQr.onBackground);
        expect(
          tester.widget<EmetteurQr>(find.byType(EmetteurQr)).code,
          'AB23CD',
          reason: 'le QR ne porte que le code brut',
        );
      });
    }

    testWidgets(
      'confirme : QR et code retires de l ecran ET de l arbre semantique',
      (WidgetTester tester) async {
        final SemanticsHandle semantique = tester.ensureSemantics();
        final FauxStatutCode statut = FauxStatutCode();
        await _monter(tester, service: _service(), statut: statut);
        expect(find.bySemanticsLabel(RegExp(_codeLisible)), findsOneWidget);

        statut.statutRendu = StatutCode.consomme;
        await tester.pump(AppairagePage.intervalleScrutation);
        await stabiliser(tester);

        expect(statut.lectures, greaterThanOrEqualTo(1));
        expect(find.byType(EmetteurQr), findsNothing);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text(_codeLisible), findsNothing);
        expect(find.bySemanticsLabel(RegExp(_codeLisible)), findsNothing);
        expect(find.bySemanticsLabel(RegExp('QR')), findsNothing);
        expect(find.text(t.appareils.emetteur.confirme.titre), findsOneWidget);
        expect(
          find.text(t.appareils.emetteur.confirme.phrase(prenom: 'Amina')),
          findsOneWidget,
        );

        await tester.tap(find.text(t.appareils.emetteur.confirme.action));
        await stabiliser(tester);
        expect(find.text('ECRAN APPAREILS'), findsOneWidget);
        semantique.dispose();
      },
    );

    testWidgets('expire : le code quitte l ecran, un nouveau se demande', (
      WidgetTester tester,
    ) async {
      final HorlogePilotee horloge = HorlogePilotee(_depart);
      final FauxServiceAppairage service = _service();
      await _monter(
        tester,
        service: service,
        statut: FauxStatutCode(),
        horloge: horloge,
      );
      expect(find.byType(EmetteurQr), findsOneWidget);

      horloge.avancer(const Duration(minutes: 11));
      await tester.pump(const Duration(seconds: 1));
      await stabiliser(tester);

      expect(find.text(t.appareils.emetteur.expire.titre), findsOneWidget);
      expect(find.byType(EmetteurQr), findsNothing);
      expect(find.text(_codeLisible), findsNothing);

      service.code = CodeAppairage(
        code: 'XY45ZW',
        expireA: horloge.maintenant.add(const Duration(minutes: 10)),
      );
      await tester.tap(find.text(t.appareils.regenerer));
      await stabiliser(tester);
      expect(service.codesDemandes, <String>['e1', 'e1']);
      expect(find.text('X Y 4 5 Z W'), findsOneWidget);
    });

    testWidgets('remplace : un autre ecran a demande un code', (
      WidgetTester tester,
    ) async {
      final FauxStatutCode statut = FauxStatutCode();
      await _monter(tester, service: _service(), statut: statut);

      statut.statutRendu = StatutCode.remplace;
      await tester.pump(AppairagePage.intervalleScrutation);
      await stabiliser(tester);

      expect(find.text(t.appareils.emetteur.remplace.titre), findsOneWidget);
      expect(find.byType(EmetteurQr), findsNothing);
      expect(find.text(t.appareils.regenerer), findsOneWidget);
    });

    testWidgets(
      'code deja valable : aucun nouveau code sans le geste du tuteur',
      (WidgetTester tester) async {
        final FauxServiceAppairage service = _service();
        final FauxStatutCode statut = FauxStatutCode()
          ..vivant = CodeVivant(
            expireA: _depart.add(const Duration(minutes: 7)),
          );
        await _monter(tester, service: service, statut: statut);

        expect(service.codesDemandes, isEmpty);
        expect(find.text(t.appareils.emetteur.dejaActif.titre), findsOneWidget);
        expect(
          find.text(t.appareils.emetteur.dejaActif.phrase(heure: '18:07')),
          findsOneWidget,
        );
        expect(find.byType(EmetteurQr), findsNothing);

        await tester.tap(find.text(t.appareils.regenerer));
        await stabiliser(tester);
        expect(service.codesDemandes, <String>['e1']);
        expect(find.byType(EmetteurQr), findsOneWidget);
      },
    );

    testWidgets('plafond : message clair et chemin vers les appareils', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = _service()
        ..erreurAJeter = StateError("plafond d'appareils atteint");
      await _monter(tester, service: service, statut: FauxStatutCode());

      expect(
        find.text(t.appareils.emetteur.erreur.plafondTitre),
        findsOneWidget,
      );
      expect(
        find.textContaining('plafond'),
        findsNothing,
        reason: 'jamais le texte brut du serveur',
      );
      await tester.tap(find.text(t.appareils.emetteur.erreur.plafondAction));
      await stabiliser(tester);
      // Le retrait vit sur la page des appareils de cet eleve (LD-3).
      expect(find.text('ECRAN APPAREILS DE e1'), findsOneWidget);
    });

    testWidgets('erreur generale : Reessayer relance la demande', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = _service()
        ..erreurAJeter = StateError('boom');
      await _monter(tester, service: service, statut: FauxStatutCode());

      expect(
        find.text(t.appareils.emetteur.erreur.generiqueTitre),
        findsOneWidget,
      );
      service.erreurAJeter = null;
      await tester.tap(find.text(t.commun.reessayer));
      await stabiliser(tester);
      expect(find.byType(EmetteurQr), findsOneWidget);
    });

    testWidgets('hors ligne : code masque, puis reverifie au retour', (
      WidgetTester tester,
    ) async {
      final ReseauPilote reseau = ReseauPilote();
      final FauxStatutCode statut = FauxStatutCode();
      await _monter(
        tester,
        service: _service(),
        statut: statut,
        reseau: reseau,
      );
      expect(find.byType(EmetteurQr), findsOneWidget);

      reseau.poser(horsLigne: true);
      await stabiliser(tester);
      expect(
        find.text(t.appareils.emetteur.horsLigne.titreAvecCode),
        findsOneWidget,
      );
      expect(
        find.text(
          t.appareils.emetteur.horsLigne.phraseAvecCode(heure: '18:10'),
        ),
        findsOneWidget,
      );
      expect(find.byType(EmetteurQr), findsNothing);
      expect(find.text(_codeLisible), findsNothing);
      // EA-HL-DOUBLE-1 (reprise) : le bandeau seul dit « hors ligne », en
      // mots et en icone ; la carte dit ce qui manque.
      expectHorsLigneUneFois();

      final int avant = statut.lectures;
      reseau.poser(horsLigne: false);
      await stabiliser(tester);
      expect(statut.lectures, greaterThan(avant));
      expect(find.byType(EmetteurQr), findsOneWidget);
    });

    testWidgets('hors ligne des l entree : aucun faux succes', (
      WidgetTester tester,
    ) async {
      final ReseauPilote reseau = ReseauPilote()..poser(horsLigne: true);
      final FauxServiceAppairage service = _service()
        ..erreurAJeter = StateError('reseau');
      await _monter(
        tester,
        service: service,
        statut: FauxStatutCode(),
        reseau: reseau,
      );
      expect(
        find.text(t.appareils.emetteur.horsLigne.titreSansCode),
        findsOneWidget,
      );
      expect(
        find.text(t.appareils.emetteur.horsLigne.phraseSansCode),
        findsOneWidget,
      );
      expect(find.byType(EmetteurQr), findsNothing);
      // EA-HL-DOUBLE-1 (reprise) : le bandeau seul dit « hors ligne ».
      expectHorsLigneUneFois();
    });

    testWidgets(
      'suivi indisponible (DB-APP-02) : le code reste, l ecran le dit',
      (WidgetTester tester) async {
        final FauxStatutCode statut = FauxStatutCode()
          ..erreurVivant = const CapaciteIndisponible('DB-APP-02')
          ..erreurStatut = const CapaciteIndisponible('DB-APP-02');
        await _monter(tester, service: _service(), statut: statut);

        expect(find.byType(EmetteurQr), findsOneWidget);
        expect(
          find.textContaining(t.appareils.emetteur.suiviIndisponible),
          findsOneWidget,
        );
        expect(find.text(t.appareils.emetteur.confirme.titre), findsNothing);
      },
    );

    testWidgets('lecture du code vivant en echec : aucun code cree en silence, '
        'erreur dite puis Reessayer relit', (WidgetTester tester) async {
      final FauxServiceAppairage service = _service();
      final FauxStatutCode statut = FauxStatutCode()
        ..erreurVivant = Exception('delai depasse');
      await _monter(tester, service: service, statut: statut);

      // Rien n'a ete demande : un nouveau code perimerait celui qui est
      // peut-etre en train d'etre saisi sur l'autre appareil.
      expect(service.codesDemandes, isEmpty);
      expect(find.byType(EmetteurQr), findsNothing);
      expect(
        find.text(t.appareils.emetteur.erreur.generiqueTitre),
        findsOneWidget,
      );

      // La lecture repasse : aucun code vivant, le code est alors cree.
      statut.erreurVivant = null;
      await tester.tap(find.text(t.commun.reessayer));
      await stabiliser(tester);
      expect(service.codesDemandes, <String>['e1']);
      expect(find.byType(EmetteurQr), findsOneWidget);
    });

    testWidgets('arriere-plan : code masque, puis reverifie a la reprise', (
      WidgetTester tester,
    ) async {
      final FauxStatutCode statut = FauxStatutCode();
      await _monter(tester, service: _service(), statut: statut);

      // En arriere-plan, le moteur ne dessine plus : ce que l on verifie,
      // c est qu au retour le code n est PAS reaffiche avant d avoir ete
      // reverifie.
      for (final AppLifecycleState etat in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(etat);
      }
      await tester.pump();

      final int avant = statut.lectures;
      final Completer<void> reponse = Completer<void>();
      statut.attente = reponse;
      for (final AppLifecycleState etat in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(etat);
      }
      await tester.pump();
      await tester.pump();
      expect(find.byType(EmetteurQr), findsNothing);
      expect(find.text(_codeLisible), findsNothing);
      expect(
        find.text(t.appareils.emetteur.verification.titre),
        findsOneWidget,
      );
      expect(statut.lectures, greaterThan(avant));

      reponse.complete();
      await stabiliser(tester);
      expect(find.byType(EmetteurQr), findsOneWidget);
    });

    for (final bool reduit in <bool>[true, false]) {
      testWidgets(
        'mouvement ${reduit ? 'reduit : aucun fondu' : 'normal : fondu d entree'}',
        (WidgetTester tester) async {
          if (reduit) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
          }
          final ReseauPilote reseau = ReseauPilote();
          await _monter(
            tester,
            service: _service(),
            statut: FauxStatutCode(),
            reseau: reseau,
          );
          reseau.poser(horsLigne: true);
          await tester.pump();
          await tester.pump();
          final Opacity opacite = tester.widget<Opacity>(
            find
                .ancestor(
                  of: find.text(t.appareils.emetteur.horsLigne.titreAvecCode),
                  matching: find.byType(Opacity),
                )
                .first,
          );
          expect(opacite.opacity, reduit ? 1 : lessThan(1));
        },
      );
    }

    testWidgets('bureau 1440 : deux colonnes, QR a gauche de la consigne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        service: _service(),
        statut: FauxStatutCode(),
        taille: const Size(1440, 900),
      );
      final Rect qr = tester.getRect(find.byType(EmetteurQr));
      final Rect consigne = tester.getRect(
        find.text(t.appareils.emetteur.consigneTitre),
      );
      expect(qr.right, lessThan(consigne.left));
      expect(tester.takeException(), isNull);
    });

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'libelle du QR (${taille.width.toInt()}) : sans position, juste sur '
        'les deux compositions',
        (WidgetTester tester) async {
          final SemanticsHandle semantique = tester.ensureSemantics();
          await _monter(
            tester,
            service: _service(),
            statut: FauxStatutCode(),
            taille: taille,
          );
          final String libelle = t.appareils.emetteur.libelleQr;
          expect(find.bySemanticsLabel(libelle), findsOneWidget);
          // Sur bureau, le code est a DROITE du QR ; sur telephone, en
          // dessous : le libelle ne nomme aucune position.
          for (final String position in <String>[
            'dessous',
            'dessus',
            'droite',
            'gauche',
            'côté',
          ]) {
            expect(libelle, isNot(contains(position)));
          }
          // Le code dit par le libelle est bien a l'ecran.
          expect(find.text(t.appareils.emetteur.codeManuel), findsOneWidget);
          semantique.dispose();
        },
      );
    }
  });

  group('Regles pures', () {
    final DateTime expire = DateTime.utc(2026, 9, 24, 15, 10);
    final DateTime avant = DateTime.utc(2026, 9, 24, 15, 5);

    test('la ligne du code consommee : consomme', () {
      expect(
        statutDepuisLignes(
          lignes: <LigneCodeAppairage>[
            LigneCodeAppairage(expireA: expire, consommeA: avant),
          ],
          expireA: expire,
          maintenant: avant,
        ),
        StatutCode.consomme,
      );
    });

    test('ligne absente avant expiration : remplace', () {
      expect(
        statutDepuisLignes(
          lignes: <LigneCodeAppairage>[
            LigneCodeAppairage(expireA: expire.add(const Duration(minutes: 3))),
          ],
          expireA: expire,
          maintenant: avant,
        ),
        StatutCode.remplace,
      );
    });

    test('ligne presente, non consommee : actif puis expire', () {
      final List<LigneCodeAppairage> lignes = <LigneCodeAppairage>[
        LigneCodeAppairage(expireA: expire),
      ];
      expect(
        statutDepuisLignes(lignes: lignes, expireA: expire, maintenant: avant),
        StatutCode.actif,
      );
      expect(
        statutDepuisLignes(
          lignes: lignes,
          expireA: expire,
          maintenant: expire.add(const Duration(seconds: 1)),
        ),
        StatutCode.expire,
      );
    });

    test('la meme heure, lue avec un autre fuseau, designe le meme code', () {
      expect(
        statutDepuisLignes(
          lignes: <LigneCodeAppairage>[
            LigneCodeAppairage.depuisJson(<String, dynamic>{
              'expires_at': '2026-09-24T18:10:00+03:00',
              'consumed_at': '2026-09-24T18:06:00+03:00',
            })!,
          ],
          expireA: expire,
          maintenant: avant,
        ),
        StatutCode.consomme,
      );
    });

    test('une date illisible ne devient pas une date inventee', () {
      expect(
        LigneCodeAppairage.depuisJson(<String, dynamic>{'expires_at': 'x'}),
        isNull,
      );
    });

    test('motifs d erreur : textes connus du serveur, sinon general', () {
      expect(
        MotifErreurEmetteur.depuis(Exception("plafond d'appareils atteint")),
        MotifErreurEmetteur.plafond,
      );
      expect(
        MotifErreurEmetteur.depuis(
          Exception("cet eleve n'appartient pas a votre foyer"),
        ),
        MotifErreurEmetteur.horsFoyer,
      );
      expect(
        MotifErreurEmetteur.depuis(
          Exception('seul un tuteur au compte valide appaire un appareil'),
        ),
        MotifErreurEmetteur.compte,
      );
      expect(
        MotifErreurEmetteur.depuis(Exception('autre')),
        MotifErreurEmetteur.generique,
      );
    });
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve, hors ligne avec et sans
  // code. Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, ThemeMode, Size) cas in <(String, ThemeMode, Size)>[
      ('avec_code_390_clair', ThemeMode.light, const Size(390, 844)),
      ('avec_code_390_sombre', ThemeMode.dark, const Size(390, 844)),
      ('avec_code_320_clair', ThemeMode.light, const Size(320, 900)),
      ('avec_code_1440_clair', ThemeMode.light, const Size(1440, 900)),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        final ReseauPilote reseau = ReseauPilote();
        await _monter(
          tester,
          service: _service(),
          statut: FauxStatutCode(),
          reseau: reseau,
          mode: cas.$2,
          taille: cas.$3,
        );
        reseau.poser(horsLigne: true);
        await stabiliser(tester);
        expectHorsLigneUneFois();
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_appairage_${cas.$1}')}',
        );
      });
    }
    testWidgets('sans_code_390_clair', (WidgetTester tester) async {
      final ReseauPilote reseau = ReseauPilote()..poser(horsLigne: true);
      await _monter(
        tester,
        service: _service()..erreurAJeter = StateError('reseau'),
        statut: FauxStatutCode(),
        reseau: reseau,
      );
      expectHorsLigneUneFois();
      debugPrint(
        'PNG ${await capturerVue(tester, 'ea_hl_double1_appairage_sans_code_390_clair')}',
      );
    });
  });
}

/// Une demande de code qui ne rend jamais la main : l etat de preparation.
class _AttenteSansFin extends FauxServiceAppairage {
  @override
  Future<CodeAppairage> creerCode(String eleveId) =>
      Completer<CodeAppairage>().future;
}
