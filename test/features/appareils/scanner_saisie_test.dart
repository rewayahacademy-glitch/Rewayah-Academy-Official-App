// Scanner camera et saisie du code sur l'appareil de l'eleve (lot D,
// sous-paquet 2) : parcours depuis la connexion par des gestes (vrai
// routeur), tous les etats de la camera, refus du serveur differencies,
// contenu non valide jamais ouvert, lectures suspendues apres detection,
// camera rendue a la sortie et en arriere-plan, bureau en panneau centre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';
import 'package:rewayah_academy/features/eleve_connexion/scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionsFetchException, FunctionsHttpException;

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import 'faux_lecteur_qr.dart';

/// Ce que le test a monte, pour l'interroger.
class _Montage {
  _Montage(this.routeur, this.lecteurs, this.service, this.coffre, this.profils);

  final GoRouter routeur;
  final List<FauxLecteurQr> lecteurs;
  final FauxServiceEnfantPilote service;
  final FauxStockageSecurise coffre;
  final FauxProfilsLocaux profils;

  FauxLecteurQr get lecteur => lecteurs.last;

  String get lieu => routeur.routerDelegate.currentConfiguration.uri.path;
}

/// Monte l'application sur son VRAI routeur, sans session (appareil eleve).
Future<_Montage> _monter(
  WidgetTester tester, {
  String? depart,
  FauxLecteurQr Function()? fabrique,
  FauxServiceEnfantPilote? service,
  bool disponible = true,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  FauxStockageSecurise? coffre,
  double echelleTexte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<FauxLecteurQr> lecteurs = <FauxLecteurQr>[];
  final FauxServiceEnfantPilote s = service ?? FauxServiceEnfantPilote();
  final FauxStockageSecurise c = coffre ?? FauxStockageSecurise();
  final FauxProfilsLocaux profils = FauxProfilsLocaux();
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        serviceEnfantProvider.overrideWithValue(s),
        stockageSecuriseProvider.overrideWithValue(c),
        profilsLocauxProvider.overrideWithValue(profils),
        lecteurQrDisponibleProvider.overrideWithValue(disponible),
        fabriqueLecteurQrProvider.overrideWithValue(() {
          final FauxLecteurQr l = fabrique?.call() ?? FauxLecteurQr();
          lecteurs.add(l);
          return l;
        }),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(
                  contexte,
                ).copyWith(textScaler: TextScaler.linear(echelleTexte)),
                child: enfant ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart ?? Routes.connexion);
  await stabiliser(tester);
  return _Montage(routeur, lecteurs, s, c, profils);
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

Finder _action(String libelle) =>
    find.widgetWithText(ActionPrincipale, libelle);

void main() {
  group('Parcours depuis la connexion (vrai routeur, gestes)', () {
    testWidgets(
      'connexion -> feuille -> Saisir le code -> Scanner -> QR lu -> code '
      'personnel',
      (WidgetTester tester) async {
        final _Montage m = await _monter(tester);
        expect(m.lieu, Routes.connexion);

        // 1. L'entree discrete de la connexion ouvre la feuille du tuteur.
        await _taper(tester, find.text(t.connexion.appareilEleve));
        expect(find.text(t.connexion.feuilleAppareil.etape4), findsOneWidget);

        // 2. « Saisir le code » : l'appareil ne connait aucun profil, la
        // saisie du code prend le relais.
        await _taper(tester, find.text(t.connexion.feuilleAppareil.saisir));
        expect(m.lieu, Routes.connexionEleveCode);
        expect(find.byType(SaisieCodePage), findsOneWidget);

        // 3. « Scanner le QR code » ouvre le scanner, qui demande la camera.
        await _taper(tester, _action(t.eleveConnexion.saisie.scanner));
        expect(m.lieu, Routes.connexionEleveScanner);
        expect(find.byType(ScannerPage), findsOneWidget);
        expect(m.lecteur.demarrages, 1);
        expect(find.text(t.eleveConnexion.lecteur.consigne), findsOneWidget);

        // 4. Un QR valide : camera arretee, code verifie, puis code personnel.
        m.lecteur.lire('ab23cd');
        await stabiliser(tester);
        expect(m.service.codesRecus, <String>['AB23CD']);
        expect(m.lecteur.arrets, greaterThanOrEqualTo(1));
        expect(m.lieu, Routes.connexionEleve);
        expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);
        // Le jeton est range, le profil retenu, aucune session ouverte avant
        // le code personnel.
        expect(m.coffre.jetons['e1'], 'jeton-test');
        expect(m.profils.profils.single.id, 'e1');
        expect(m.service.sessionsOuvertes, 0);
        // La camera est rendue a la sortie du scanner.
        expect(m.lecteur.libere, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('les disques retour ramenent : scanner -> saisie -> connexion', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(tester);
      await _taper(tester, find.text(t.connexion.appareilEleve));
      await _taper(tester, find.text(t.connexion.feuilleAppareil.saisir));
      await _taper(tester, _action(t.eleveConnexion.saisie.scanner));
      expect(m.lieu, Routes.connexionEleveScanner);

      await _taper(tester, find.byType(DisqueRetour));
      expect(m.lieu, Routes.connexionEleveCode);
      expect(m.lecteurs.single.libere, isTrue);

      await _taper(tester, find.byType(DisqueRetour));
      expect(m.lieu, Routes.connexion);
    });

    testWidgets('« Saisir le code » du scanner mene a la saisie', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(tester);
      await _taper(tester, find.text(t.connexion.appareilEleve));
      await _taper(tester, find.text(t.connexion.feuilleAppareil.saisir));
      await _taper(tester, _action(t.eleveConnexion.saisie.scanner));

      await _taper(tester, _action(t.eleveConnexion.lecteur.saisir));
      expect(m.lieu, Routes.connexionEleveCode);
      expect(find.byType(SaisieCodePage), findsOneWidget);
    });

    testWidgets('saisie : code tape puis Connecter l appareil -> code personnel', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(tester);
      await _taper(tester, find.text(t.connexion.appareilEleve));
      await _taper(tester, find.text(t.connexion.feuilleAppareil.saisir));

      await tester.enterText(find.byKey(SaisieCodePage.champKey), 'ab23cd');
      await stabiliser(tester);
      await _taper(tester, _action(t.eleveConnexion.saisie.valider));

      expect(m.service.codesRecus, <String>['AB23CD']);
      expect(m.lieu, Routes.connexionEleve);
      expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);
      expect(m.coffre.jetons['e1'], 'jeton-test');
    });
  });

  group('Saisie du code', () {
    TextField champ(WidgetTester tester) =>
        tester.widget<TextField>(find.byKey(SaisieCodePage.champKey));

    ActionPrincipale valider(WidgetTester tester) =>
        tester.widget<ActionPrincipale>(
          _action(t.eleveConnexion.saisie.valider),
        );

    testWidgets('vide : action inactive, aide sous le champ', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.connexionEleveCode);
      expect(valider(tester).onPress, isNull);
      expect(find.text(t.eleveConnexion.saisie.aide), findsOneWidget);
    });

    testWidgets('filtre l alphabet du serveur : ni I, ni O, ni 0, ni 1', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.connexionEleveCode);
      await tester.enterText(find.byKey(SaisieCodePage.champKey), 'a-b 2i3o01');
      await stabiliser(tester);
      expect(champ(tester).controller!.text, 'AB23');
      expect(valider(tester).onPress, isNull);

      await tester.enterText(
        find.byKey(SaisieCodePage.champKey),
        'AB23CDEFGH',
      );
      await stabiliser(tester);
      expect(champ(tester).controller!.text, 'AB23CD');
      expect(valider(tester).onPress, isNotNull);
    });

    for (final MotifRefusAppairage motif in MotifRefusAppairage.values) {
      testWidgets('refus ${motif.name} : dit sous le champ, jamais brut', (
        WidgetTester tester,
      ) async {
        final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
          ..refus = motif;
        final _Montage m = await _monter(
          tester,
          depart: Routes.connexionEleveCode,
          service: service,
        );
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
        await stabiliser(tester);
        await _taper(tester, _action(t.eleveConnexion.saisie.valider));

        expect(m.lieu, Routes.connexionEleveCode);
        expect(
          find.text(libellesRefusAppairage(motif).phrase),
          findsOneWidget,
        );
        expect(m.coffre.jetons, isEmpty);
        // Corriger le code efface le message.
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23C');
        await stabiliser(tester);
        expect(find.text(libellesRefusAppairage(motif).phrase), findsNothing);
      });
    }

    testWidgets('verification : double envoi bloque, champ fige', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
        ..attente = Completer<void>();
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveCode,
        service: service,
      );
      await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
      await stabiliser(tester);
      await tester.tap(_action(t.eleveConnexion.saisie.valider));
      await tester.pump();
      await tester.tap(_action(t.eleveConnexion.saisie.valider));
      await tester.pump();

      expect(m.service.codesRecus, hasLength(1));
      expect(valider(tester).enCours, isTrue);
      expect(champ(tester).enabled, isFalse);
      // Pendant la verification, pas de detour vers le scanner.
      expect(_action(t.eleveConnexion.saisie.scanner), findsNothing);

      service.attente!.complete();
      await stabiliser(tester);
      expect(m.lieu, Routes.connexionEleve);
    });

    testWidgets('hors ligne : action inactive et phrase sous le champ', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.connexionEleveCode,
        horsLigne: true,
      );
      await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
      await stabiliser(tester);
      expect(valider(tester).onPress, isNull);
      expect(find.text(t.eleveConnexion.saisie.horsLigne), findsOneWidget);
    });

    testWidgets('sans lecteur possible (Windows, Linux) : aucun bouton scanner', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.connexionEleveCode,
        disponible: false,
      );
      expect(_action(t.eleveConnexion.saisie.scanner), findsNothing);
    });

    testWidgets('bureau 1440 : panneau centre qui porte son action', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.connexionEleveCode,
        taille: const Size(1440, 900),
      );
      final Finder carte = find.byType(AppCard);
      expect(carte, findsOneWidget);
      expect(
        find.descendant(
          of: carte,
          matching: _action(t.eleveConnexion.saisie.valider),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(carte).width, lessThanOrEqualTo(560));
      expect(tester.takeException(), isNull);
    });
  });

  group('Scanner', () {
    testWidgets('demarrage : autorisation demandee, viseur monte', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        fabrique: () => FauxLecteurQr()..attente = attente,
      );
      expect(find.text(t.eleveConnexion.lecteur.demarrage), findsOneWidget);
      expect(find.byKey(FauxLecteurQr.apercuKey), findsOneWidget);
      attente.complete();
      await stabiliser(tester);
      expect(find.text(t.eleveConnexion.lecteur.consigne), findsOneWidget);
      expect(m.lecteur.enMarche, isTrue);
    });

    testWidgets('contenu non valide (adresse web) : dit, jamais ouvert', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
      );
      m.lecteur.lire('https://exemple.test/AB23CD');
      await stabiliser(tester);
      expect(find.text(t.eleveConnexion.lecteur.contenuInvalide), findsOneWidget);
      expect(m.service.codesRecus, isEmpty);
      expect(m.lieu, Routes.connexionEleveScanner);
      expect(m.lecteur.enMarche, isTrue);

      // Un QR valide ensuite passe normalement.
      m.lecteur.lire('AB23CD');
      await stabiliser(tester);
      expect(m.service.codesRecus, <String>['AB23CD']);
    });

    testWidgets('lectures suspendues apres la premiere detection valide', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
        ..attente = Completer<void>();
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        service: service,
      );
      m.lecteur
        ..lire('AB23CD')
        ..lire('AB23CD')
        ..lire('ZZ99ZZ');
      await tester.pump();
      await tester.pump();
      expect(service.codesRecus, <String>['AB23CD']);
      expect(m.lecteur.arrets, 1);
      expect(m.lecteur.enMarche, isFalse);
      expect(
        find.text(t.eleveConnexion.lecteur.verificationTitre),
        findsOneWidget,
      );
      service.attente!.complete();
      await stabiliser(tester);
      expect(m.lieu, Routes.connexionEleve);
    });

    testWidgets('reponse tardive apres la sortie : ignoree', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
        ..attente = Completer<void>();
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        service: service,
      );
      m.lecteur.lire('AB23CD');
      await tester.pump();
      await _taper(tester, _action(t.eleveConnexion.lecteur.saisir));
      expect(m.lieu, Routes.connexionEleveCode);

      service.attente!.complete();
      await stabiliser(tester);
      expect(m.lieu, Routes.connexionEleveCode);
      expect(m.lecteurs.single.libere, isTrue);
    });

    for (final MotifRefusAppairage motif in MotifRefusAppairage.values) {
      testWidgets('refus ${motif.name} apres lecture : dit, puis rescanner', (
        WidgetTester tester,
      ) async {
        final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
          ..refus = motif;
        final _Montage m = await _monter(
          tester,
          depart: Routes.connexionEleveScanner,
          service: service,
        );
        m.lecteur.lire('AB23CD');
        await stabiliser(tester);
        expect(find.text(libellesRefusAppairage(motif).titre), findsOneWidget);
        expect(
          find.text(libellesRefusAppairage(motif).phrase),
          findsOneWidget,
        );
        expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);

        await _taper(tester, _action(t.eleveConnexion.lecteur.scannerANouveau));
        expect(m.lecteur.demarrages, 2);
        expect(find.text(t.eleveConnexion.lecteur.consigne), findsOneWidget);
      });
    }

    testWidgets('refusee : Autoriser la camera redemande ; puis refus durable', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        fabrique: () => FauxLecteurQr(
          reponses: <EtatCamera>[
            EtatCamera.refusee,
            EtatCamera.refuseeDurablement,
          ],
        ),
      );
      expect(find.text(t.eleveConnexion.lecteur.refuseeTitre), findsOneWidget);
      expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);

      await _taper(tester, _action(t.eleveConnexion.lecteur.refuseeAction));
      expect(m.lecteur.demarrages, 2);
      expect(
        find.text(t.eleveConnexion.lecteur.refuseeDurablementTitre),
        findsOneWidget,
      );
      // Un bouton qui ne peut plus aboutir n'est pas rendu.
      expect(_action(t.eleveConnexion.lecteur.refuseeAction), findsNothing);
      expect(_action(t.commun.reessayer), findsNothing);
      expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);
    });

    final List<(EtatCamera, String, bool)> etatsCamera =
        <(EtatCamera, String, bool)>[
          (EtatCamera.occupee, t.eleveConnexion.lecteur.occupeeTitre, true),
          (EtatCamera.absente, t.eleveConnexion.lecteur.absenteTitre, false),
          (
            EtatCamera.nonSupportee,
            t.eleveConnexion.lecteur.nonSupporteeTitre,
            false,
          ),
          (EtatCamera.erreur, t.eleveConnexion.lecteur.erreurTitre, true),
        ];
    for (final (EtatCamera etat, String titre, bool relance) in etatsCamera) {
      testWidgets('camera ${etat.name} : dit, saisie toujours accessible', (
        WidgetTester tester,
      ) async {
        final _Montage m = await _monter(
          tester,
          depart: Routes.connexionEleveScanner,
          fabrique: () => FauxLecteurQr(defaut: etat),
        );
        expect(find.text(titre), findsOneWidget);
        expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);
        expect(
          _action(t.commun.reessayer),
          relance ? findsOneWidget : findsNothing,
        );
        if (relance) {
          await _taper(tester, _action(t.commun.reessayer));
          expect(m.lecteur.demarrages, 2);
        }
      });
    }

    testWidgets('plateforme sans lecteur : aucun demarrage, saisie proposee', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        disponible: false,
      );
      expect(m.lecteur.demarrages, 0);
      expect(
        find.text(t.eleveConnexion.lecteur.nonSupporteeTitre),
        findsOneWidget,
      );
      expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);
    });

    testWidgets('arriere-plan : camera arretee, puis relancee a la reprise', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
      );
      expect(m.lecteur.enMarche, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await stabiliser(tester);
      expect(m.lecteur.enMarche, isFalse);
      expect(m.lecteur.arrets, greaterThanOrEqualTo(1));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await stabiliser(tester);
      expect(m.lecteur.demarrages, 2);
      expect(m.lecteur.enMarche, isTrue);
    });

    testWidgets('hors ligne : le scanner le dit sous la consigne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        horsLigne: true,
      );
      expect(find.text(t.eleveConnexion.saisie.horsLigne), findsOneWidget);
    });

    testWidgets('bureau 1440 : panneau centre, pas de plein cadre etire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.connexionEleveScanner,
        taille: const Size(1440, 900),
      );
      final Finder carte = find.byType(AppCard);
      expect(carte, findsOneWidget);
      expect(tester.getSize(carte).width, lessThanOrEqualTo(560));
      expect(
        find.descendant(of: carte, matching: find.byKey(ScannerPage.viseurKey)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone : plein cadre sombre dans le theme clair', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.connexionEleveScanner);
      final BuildContext contexte = tester.element(
        find.byKey(ScannerPage.viseurKey),
      );
      expect(Theme.of(contexte).brightness, Brightness.dark);
    });
  });

  group('Revue LD-R : coffre en echec, compositions, texte a 200 %', () {
    testWidgets(
      'scanner : coffre qui refuse le jeton -> refus dit, jamais bloque en '
      'verification',
      (WidgetTester tester) async {
        final _Montage m = await _monter(
          tester,
          depart: Routes.connexionEleveScanner,
          coffre: _CoffreQuiRefuseLeJeton(),
        );
        m.lecteur.lire('AB23CD');
        await stabiliser(tester);

        final r = t.eleveConnexion.refus;
        expect(find.text(r.nonEnregistreTitre), findsOneWidget);
        expect(find.text(r.nonEnregistre), findsOneWidget);
        expect(
          find.text(t.eleveConnexion.lecteur.verificationTitre),
          findsNothing,
        );
        expect(m.lieu, Routes.connexionEleveScanner);
        // Deux issues : scanner a nouveau, ou saisir un code.
        expect(_action(t.eleveConnexion.lecteur.scannerANouveau), findsOneWidget);
        expect(_action(t.eleveConnexion.lecteur.saisir), findsOneWidget);
      },
    );

    testWidgets('saisie : coffre qui refuse le jeton -> message sous le champ', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        depart: Routes.connexionEleveCode,
        coffre: _CoffreQuiRefuseLeJeton(),
      );
      await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
      await stabiliser(tester);
      await _taper(tester, _action(t.eleveConnexion.saisie.valider));

      expect(m.lieu, Routes.connexionEleveCode);
      final TextField champ = tester.widget<TextField>(
        find.byKey(SaisieCodePage.champKey),
      );
      expect(champ.decoration!.errorText, t.eleveConnexion.refus.nonEnregistre);
      expect(champ.enabled, isTrue);
    });

    for (final String route in <String>[
      Routes.connexionEleveScanner,
      Routes.connexionEleveCode,
    ]) {
      testWidgets('bureau 1440 ($route) : retour et titre alignes sur le '
          'panneau centre', (WidgetTester tester) async {
        await _monter(tester, depart: route, taille: const Size(1440, 900));
        final Rect panneau = tester.getRect(
          find.byKey(PanneauAppareilEleve.panneauKey),
        );
        expect(panneau.width, lessThanOrEqualTo(560));
        expect(panneau.center.dx, closeTo(720, 1));
        final Rect retour = tester.getRect(find.byType(DisqueRetour));
        expect(retour.left, closeTo(panneau.left, 1));
        final Rect titre = tester.getRect(
          find.text(
            route == Routes.connexionEleveScanner
                ? t.eleveConnexion.lecteur.titre
                : t.eleveConnexion.saisie.titre,
          ),
        );
        expect(titre.left, greaterThan(panneau.left));
        expect(titre.right, lessThanOrEqualTo(panneau.right));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'telephone : camera sur tout le corps, retour et Saisir le code poses '
      'dessus',
      (WidgetTester tester) async {
        await _monter(tester, depart: Routes.connexionEleveScanner);
        final Rect viseur = tester.getRect(find.byKey(ScannerPage.viseurKey));
        // Tout le corps de la page, gouttiere du gabarit comprise (20).
        expect(viseur.left, lessThanOrEqualTo(20));
        expect(viseur.right, greaterThanOrEqualTo(370));
        expect(viseur.height, greaterThan(844 * 0.8));
        // Aucune zone d'action separee sous le cadre.
        expect(find.text(t.eleveConnexion.lecteur.consigne), findsOneWidget);
        expect(
          viseur.contains(
            tester.getCenter(find.text(t.eleveConnexion.lecteur.consigne)),
          ),
          isTrue,
        );
        final Rect retour = tester.getRect(find.byType(DisqueRetour));
        final Rect saisir = tester.getRect(
          _action(t.eleveConnexion.lecteur.saisir),
        );
        expect(viseur.contains(retour.center), isTrue);
        expect(viseur.contains(saisir.center), isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    for (final String route in <String>[
      Routes.connexionEleveScanner,
      Routes.connexionEleveCode,
    ]) {
      testWidgets('texte a 200 % ($route, 390x844) : aucun debordement, '
          'action et retour touchables', (WidgetTester tester) async {
        final _Montage m = await _monter(
          tester,
          depart: route,
          echelleTexte: 2,
        );
        expect(tester.takeException(), isNull);
        final Finder action = _action(
          route == Routes.connexionEleveScanner
              ? t.eleveConnexion.lecteur.saisir
              : t.eleveConnexion.saisie.valider,
        );
        expect(action.hitTestable(), findsOneWidget);
        expect(find.byType(DisqueRetour).hitTestable(), findsOneWidget);
        if (route == Routes.connexionEleveScanner) {
          await _taper(tester, action);
          expect(m.lieu, Routes.connexionEleveCode);
        }
        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.connexion);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Regles pures', () {
    test('format : normalise, refuse tout le reste sans l ouvrir', () {
      expect(FormatCodeAppairage.normaliser(' ab23cd '), 'AB23CD');
      expect(FormatCodeAppairage.normaliser('AB23C'), isNull);
      expect(FormatCodeAppairage.normaliser('AB23CDE'), isNull);
      expect(FormatCodeAppairage.normaliser('AB23CO'), isNull);
      expect(FormatCodeAppairage.normaliser('AB23CI'), isNull);
      expect(FormatCodeAppairage.normaliser('AB230D'), isNull);
      expect(FormatCodeAppairage.normaliser('AB231D'), isNull);
      expect(FormatCodeAppairage.normaliser('https://x.test/AB23CD'), isNull);
    });

    test('motif du refus lu dans la reponse de session-enfant', () {
      MotifRefusAppairage lu(String texte, [int statut = 403]) =>
          MotifRefusAppairage.depuisReponse(
            statut: statut,
            details: <String, dynamic>{'error': texte},
          );
      expect(lu('code inconnu'), MotifRefusAppairage.inconnu);
      expect(lu('code expire'), MotifRefusAppairage.expire);
      expect(lu('code deja utilise'), MotifRefusAppairage.dejaUtilise);
      expect(lu("plafond d'appareils atteint"), MotifRefusAppairage.plafond);
      expect(
        lu("jeton d'appareil inconnu ou revoque"),
        MotifRefusAppairage.revoque,
      );
      expect(lu('appareil non decrit', 400), MotifRefusAppairage.generique);
      expect(lu('peu importe', 429), MotifRefusAppairage.tropDEssais);
      expect(
        MotifRefusAppairage.depuis(const FunctionsFetchException()),
        MotifRefusAppairage.horsLigne,
      );
      expect(
        MotifRefusAppairage.depuis(
          const FunctionsHttpException(
            status: 403,
            details: <String, dynamic>{'error': 'code expire'},
          ),
        ),
        MotifRefusAppairage.expire,
      );
      expect(
        MotifRefusAppairage.depuis(StateError('x')),
        MotifRefusAppairage.generique,
      );
    });

    test('connecter : jeton range, profil retenu, aucune session', () async {
      final FauxServiceEnfantPilote service = FauxServiceEnfantPilote();
      final FauxStockageSecurise coffre = FauxStockageSecurise();
      final FauxProfilsLocaux profils = FauxProfilsLocaux();
      final ProfilLocal profil = await connecterCetAppareil(
        service: service,
        coffre: coffre,
        profils: profils,
        code: 'AB23CD',
      );
      expect(profil.id, 'e1');
      expect(coffre.jetons['e1'], 'jeton-test');
      expect(profils.profils.single.prenom, 'Amina');
      expect(service.sessionsOuvertes, 0);
    });

    test(
      'connecter : un nouveau jeton efface l ancien code personnel du profil',
      () async {
        final FauxStockageSecurise coffre = FauxStockageSecurise()
          ..jetons['e1'] = 'ancien-jeton'
          ..empreintes['e1'] = 'ancienne-empreinte'
          ..empreintes['e2'] = 'empreinte-e2';
        await connecterCetAppareil(
          service: FauxServiceEnfantPilote(),
          coffre: coffre,
          profils: FauxProfilsLocaux(),
          code: 'AB23CD',
        );
        expect(coffre.jetons['e1'], 'jeton-test');
        expect(coffre.empreintes.containsKey('e1'), isFalse);
        // Les autres profils de l'appareil gardent leur code.
        expect(coffre.empreintes['e2'], 'empreinte-e2');
      },
    );

    test('connecter : coffre qui refuse le jeton -> refus nonEnregistre', () async {
      final FauxProfilsLocaux profils = FauxProfilsLocaux();
      await expectLater(
        connecterCetAppareil(
          service: FauxServiceEnfantPilote(),
          coffre: _CoffreQuiRefuseLeJeton(),
          profils: profils,
          code: 'AB23CD',
        ),
        throwsA(
          isA<AppairageRefuse>().having(
            (AppairageRefuse r) => r.motif,
            'motif',
            MotifRefusAppairage.nonEnregistre,
          ),
        ),
      );
      expect(profils.profils, isEmpty);
    });

    test('connecter : un refus ne range rien', () async {
      final FauxServiceEnfantPilote service = FauxServiceEnfantPilote()
        ..refus = MotifRefusAppairage.expire;
      final FauxStockageSecurise coffre = FauxStockageSecurise();
      final FauxProfilsLocaux profils = FauxProfilsLocaux();
      await expectLater(
        connecterCetAppareil(
          service: service,
          coffre: coffre,
          profils: profils,
          code: 'AB23CD',
        ),
        throwsA(
          isA<AppairageRefuse>().having(
            (AppairageRefuse r) => r.motif,
            'motif',
            MotifRefusAppairage.expire,
          ),
        ),
      );
      expect(coffre.jetons, isEmpty);
      expect(profils.profils, isEmpty);
    });

    test('lecteur possible : Android, iOS, macOS, web ; ni Windows ni Linux', () {
      bool sur(TargetPlatform p, {bool web = false}) =>
          lecteurQrPossibleSur(web: web, plateforme: p);
      expect(sur(TargetPlatform.android), isTrue);
      expect(sur(TargetPlatform.iOS), isTrue);
      expect(sur(TargetPlatform.macOS), isTrue);
      expect(sur(TargetPlatform.windows, web: true), isTrue);
      expect(sur(TargetPlatform.windows), isFalse);
      expect(sur(TargetPlatform.linux), isFalse);
    });

    test('lecteur indisponible : ne demarre jamais', () async {
      expect(
        await const LecteurQrIndisponible().demarrer(),
        EtatCamera.nonSupportee,
      );
    });
  });
}

/// Un coffre qui refuse d'ecrire le jeton d'appareil (stockage securise en
/// echec), apres que le serveur a accepte le code (REVUE R-02).
class _CoffreQuiRefuseLeJeton extends FauxStockageSecurise {
  @override
  Future<void> enregistrerJetonAppareil(String profilId, String jeton) async {
    throw StateError('coffre indisponible');
  }
}