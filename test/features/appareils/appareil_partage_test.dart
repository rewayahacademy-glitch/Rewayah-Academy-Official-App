// Appareil partage et listes d'appareils (lot D, sous-paquet 3), sur le VRAI
// routeur et par des gestes :
// - cote tuteur : onglet Foyer -> profil -> Retirer (confirme) -> retours ;
// - cote eleve : connexion -> feuille -> choix du profil -> code personnel,
//   deuxieme eleve sur le meme appareil, erreurs du pave visibles (code faux,
//   codes differents, appareil retire, hors ligne, echec), code oublie,
//   changer de profil, repli en pile a 200 %, panneau centre sur bureau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/code_local.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pin_pad.dart';
import 'package:rewayah_academy/features/appareils/appareils_eleve_page.dart';
import 'package:rewayah_academy/features/appareils/liste_appareils_eleve.dart';
import 'package:rewayah_academy/features/eleve_connexion/eleve_connexion_page.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import 'faux_appareils.dart';

const String _codeAmina = '1357';
const String _codeYusuf = '2468';

class _Eleve {
  _Eleve(this.routeur, this.service, this.coffre, this.profils);

  final GoRouter routeur;
  final FauxEnfantOuverture service;
  final FauxStockageSecurise coffre;
  final FauxProfilsLocaux profils;

  String get lieu => routeur.routerDelegate.currentConfiguration.uri.toString();
}

/// L'appareil partage d'un foyer : deux profils deja connectes, chacun avec
/// son jeton et son code personnel.
Future<_Eleve> _monterAppareil(
  WidgetTester tester, {
  FauxEnfantOuverture? service,
  bool deuxProfils = true,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  FauxStockageSecurise? coffre,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxEnfantOuverture s = service ?? FauxEnfantOuverture();
  final FauxStockageSecurise c = (coffre ?? FauxStockageSecurise())
    ..jetons['e1'] = 'jeton-e1'
    ..empreintes['e1'] = CodeLocal.sceller(_codeAmina);
  final FauxProfilsLocaux profils = FauxProfilsLocaux()
    ..profils = <ProfilLocal>[
      if (deuxProfils)
        const ProfilLocal(id: 'e2', prenom: 'Yusuf', identifiantImmuable: ''),
      const ProfilLocal(id: 'e1', prenom: 'Amina', identifiantImmuable: ''),
    ];
  if (deuxProfils) {
    c
      ..jetons['e2'] = 'jeton-e2'
      ..empreintes['e2'] = CodeLocal.sceller(_codeYusuf);
  }
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        serviceEnfantProvider.overrideWithValue(s),
        stockageSecuriseProvider.overrideWithValue(c),
        profilsLocauxProvider.overrideWithValue(profils),
        lecteurQrDisponibleProvider.overrideWithValue(false),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelleTexte)),
                child: enfant ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.connexion);
  await stabiliser(tester);
  return _Eleve(routeur, s, c, profils);
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Connexion -> feuille -> « Saisir le code » : l'appareil connait des
/// profils, le choix s'affiche.
Future<void> _versChoix(WidgetTester tester) async {
  await _taper(tester, find.text(t.connexion.appareilEleve));
  await _taper(tester, find.text(t.connexion.feuilleAppareil.saisir));
}

Future<void> _composer(WidgetTester tester, String code) async {
  for (final String chiffre in code.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(PinPad), matching: find.text(chiffre)),
    );
    await tester.pump();
  }
  await stabiliser(tester);
}

Finder _message(String texte) => find.byWidgetPredicate(
  (Widget w) =>
      w is Text && w.key == EleveConnexionPage.messageKey && w.data == texte,
);

void main() {
  group('Tuteur : appareils depuis la navigation (vrai routeur, gestes)', () {
    testWidgets(
      'onglet Foyer -> profil -> Retirer confirme -> retours jusqu au Foyer',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final FauxAppairagePilote service = FauxAppairagePilote()
          ..elevesRendus = <EleveDuFoyer>[eleveDeTest()]
          ..appareilsRendus = <AppareilAppaire>[appareilDeTest()];
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: surchargesRouteur(
              FausseSourceSession(sessionActive(AppRole.guardian)),
              appairage: service,
            ),
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

        // 1. Onglet Foyer de la barre basse : le Foyer.
        await _taper(
          tester,
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.tuteur.foyer),
          ),
        );
        expect(lieu(routeur), Routes.tuteurFoyer);
        expect(find.byType(FoyerPage), findsOneWidget);

        // 2. La ligne du profil ouvre sa fiche ; la ligne Appareils de la
        // fiche ouvre ses appareils (retour visible).
        await _taper(tester, find.text('Amina'));
        expect(lieu(routeur), Routes.ficheElevePour('e1'));
        await _taper(
          tester,
          find.text(t.ficheEleve.lignes.appareils(dePrenom: deDevant('Amina'))),
        );
        expect(
          Uri.parse(lieu(routeur)).path,
          Routes.ficheEleveSousPage('e1', 'appareils'),
        );
        expect(find.byType(AppareilsElevePage), findsOneWidget);
        expect(find.byType(DisqueRetour), findsOneWidget);

        // 3. Retirer : confirmation, puis reponse du service.
        await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
        await _taper(tester, find.text(t.appareils.retrait.confirmer));
        expect(service.revocations, <String>['d1']);
        expect(find.text(t.appareils.retrait.reussi), findsOneWidget);
        expect(find.text(t.appareils.eleve.videTitre), findsOneWidget);

        // 4. Retour : la fiche d ou l on vient, puis le Foyer.
        await _taper(tester, find.byType(DisqueRetour));
        expect(lieu(routeur), Routes.ficheElevePour('e1'));
        expect(find.byType(FicheElevePage), findsOneWidget);
        await _taper(tester, find.byType(DisqueRetour));
        expect(lieu(routeur), Routes.tuteurFoyer);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Eleve : appareil partage (vrai routeur, gestes)', () {
    testWidgets(
      'connexion -> feuille -> choix du profil -> code faux dit -> bon code '
      '-> connexion ouverte par le jeton du profil',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(tester);
        await _versChoix(tester);

        expect(m.lieu, Routes.connexionEleve);
        expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);
        // Profils par prenom : Amina avant Yusuf.
        expect(
          tester.getTopLeft(find.byKey(EleveConnexionPage.carteKey('e1'))).dy,
          lessThanOrEqualTo(
            tester.getTopLeft(find.byKey(EleveConnexionPage.carteKey('e2'))).dy,
          ),
        );
        expect(
          tester.getTopLeft(find.byKey(EleveConnexionPage.carteKey('e1'))).dx,
          lessThan(
            tester.getTopLeft(find.byKey(EleveConnexionPage.carteKey('e2'))).dx,
          ),
          reason: 'deux colonnes',
        );

        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        expect(
          find.text(t.eleveConnexion.pin.bonjour(prenom: 'Amina')),
          findsOneWidget,
        );
        expect(find.byType(PinPad), findsOneWidget);

        await _composer(tester, '0000');
        expect(find.text(t.pin.erreur), findsOneWidget);
        expect(m.service.jetonsOuverts, isEmpty);

        await _composer(tester, _codeAmina);
        expect(m.service.jetonsOuverts, <String>['jeton-e1']);
        expect(find.text(t.eleveConnexion.pin.ouverture), findsOneWidget);
        expect(find.byType(PinPad), findsNothing, reason: 'pave fige');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'deuxieme eleve : Ajouter un profil -> saisie (retour au choix) -> code '
      '-> creation du code personnel -> connexion sans le redemander',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(tester);
        await _versChoix(tester);

        await _taper(tester, find.text(t.eleveConnexion.profils.ajouter));
        expect(Uri.parse(m.lieu).path, Routes.connexionEleveCode);
        expect(find.byType(SaisieCodePage), findsOneWidget);
        // Le retour de la saisie ramene au choix, pas a la connexion.
        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.connexionEleve);
        expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);

        await _taper(tester, find.text(t.eleveConnexion.profils.ajouter));
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'ab23cd');
        await stabiliser(tester);
        await _taper(
          tester,
          find.widgetWithText(
            ActionPrincipale,
            t.eleveConnexion.saisie.valider,
          ),
        );
        expect(m.service.codesRecus, <String>['AB23CD']);
        expect(m.lieu, Routes.connexionEleve);
        expect(
          find.text(t.eleveConnexion.pin.bonjour(prenom: 'Salam')),
          findsOneWidget,
        );
        expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);

        await _composer(tester, '4321');
        expect(find.text(t.eleveConnexion.pin.confirmer), findsOneWidget);
        await _composer(tester, '4321');

        // Le code est scelle localement, jamais en clair, et la connexion
        // s'ouvre aussitot par le jeton du nouveau profil.
        expect(m.coffre.empreintes['e3'], isNotNull);
        expect(m.coffre.empreintes['e3'], isNot(contains('4321')));
        expect(CodeLocal.correspond('4321', m.coffre.empreintes['e3']), isTrue);
        expect(m.service.jetonsOuverts, <String>['jeton-e3']);
        expect(m.profils.profils.map((ProfilLocal p) => p.id), contains('e3'));
      },
    );

    testWidgets('creation : deux codes differents, l erreur est dite', (
      WidgetTester tester,
    ) async {
      final _Eleve m = await _monterAppareil(tester);
      m.coffre.empreintes.remove('e1');
      await _versChoix(tester);
      await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
      expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);

      await _composer(tester, '1111');
      await _composer(tester, '2222');
      expect(_message(t.eleveConnexion.pin.different), findsOneWidget);
      expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);
      expect(m.coffre.empreintes['e1'], isNull);
      expect(m.service.jetonsOuverts, isEmpty);
    });

    testWidgets(
      'appareil retire par le tuteur : profil oublie ici, message sur le choix',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(
          tester,
          service: FauxEnfantOuverture()
            ..refusOuverture = const AppairageRefuse(
              MotifRefusAppairage.revoque,
            ),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);

        expect(
          _message(t.eleveConnexion.profils.retire(prenom: 'Amina')),
          findsOneWidget,
        );
        expect(find.byKey(EleveConnexionPage.carteKey('e1')), findsNothing);
        expect(find.byKey(EleveConnexionPage.carteKey('e2')), findsOneWidget);
        expect(m.coffre.jetons.containsKey('e1'), isFalse);
        expect(m.coffre.empreintes.containsKey('e1'), isFalse);
        expect(m.profils.profils.any((ProfilLocal p) => p.id == 'e1'), isFalse);
      },
    );

    testWidgets(
      'dernier profil retire : etat vide, Saisir un code mene a la saisie',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(
          tester,
          deuxProfils: false,
          service: FauxEnfantOuverture()
            ..refusOuverture = const AppairageRefuse(
              MotifRefusAppairage.revoque,
            ),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);

        expect(find.text(t.eleveConnexion.profils.videTitre), findsOneWidget);
        expect(
          find.text(t.eleveConnexion.profils.retire(prenom: 'Amina')),
          findsOneWidget,
        );
        await _taper(tester, find.text(t.eleveConnexion.profils.videAction));
        expect(m.lieu, Routes.connexionEleveCode);
      },
    );

    testWidgets(
      'jeton absent : profil oublie, message propre qui n accuse pas le tuteur',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(tester);
        m.coffre.jetons.remove('e1');
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);
        expect(
          _message(
            t.eleveConnexion.profils.jetonAbsent(dePrenom: deDevant('Amina')),
          ),
          findsOneWidget,
        );
        // Rien ne dit que le tuteur a retire l'appareil : l'ecran ne
        // l'affirme pas.
        expect(
          find.text(t.eleveConnexion.profils.retire(prenom: 'Amina')),
          findsNothing,
        );
        expect(m.service.jetonsOuverts, isEmpty);
        expect(m.coffre.empreintes.containsKey('e1'), isFalse);
      },
    );

    testWidgets(
      'coffre illisible a l ouverture : le pave revient avec l echec, retour '
      'visible',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(
          tester,
          coffre: _CoffreJetonIllisible(),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);

        expect(_message(t.eleveConnexion.pin.echec), findsOneWidget);
        expect(find.byType(PinPad), findsOneWidget);
        expect(find.text(t.eleveConnexion.pin.ouverture), findsNothing);
        expect(find.byType(DisqueRetour), findsOneWidget);
        expect(m.service.jetonsOuverts, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'serveur muet a l ouverture : apres le delai, le pave revient avec '
      'l echec et le retour',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(
          tester,
          service: FauxEnfantOuverture()..attenteOuverture = Completer<void>(),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);
        expect(find.text(t.eleveConnexion.pin.ouverture), findsOneWidget);
        expect(m.service.jetonsOuverts, <String>['jeton-e1']);

        await tester.pump(EleveConnexionPage.delaiOuverture);
        await stabiliser(tester);
        expect(_message(t.eleveConnexion.pin.echec), findsOneWidget);
        expect(find.byType(PinPad), findsOneWidget);
        expect(find.byType(DisqueRetour), findsOneWidget);
        await _taper(tester, find.byType(DisqueRetour));
        expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);
      },
    );

    testWidgets(
      'code oublie de bout en bout : Saisir un nouveau code -> code du tuteur '
      '-> Choisis ton code personnel',
      (WidgetTester tester) async {
        final _Eleve m = await _monterAppareil(
          tester,
          service: FauxEnfantOuverture()
            ..reponse = const AppairageReussi(
              profilId: 'e1',
              prenom: 'Amina',
              jetonAppareil: 'jeton-e1-neuf',
            ),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));

        // Amina a oublie son code : l'aide mene a la saisie d'un nouveau code.
        await _taper(tester, find.text(t.eleveConnexion.pin.oublie));
        expect(find.text(t.eleveConnexion.pin.oubliePhrase), findsOneWidget);
        await _taper(
          tester,
          find.widgetWithText(
            ActionPrincipale,
            t.eleveConnexion.pin.oublieAction,
          ),
        );
        expect(Uri.parse(m.lieu).path, Routes.connexionEleveCode);

        // Le tuteur affiche un nouveau code ; il est saisi ici.
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'ab23cd');
        await stabiliser(tester);
        await _taper(
          tester,
          find.widgetWithText(
            ActionPrincipale,
            t.eleveConnexion.saisie.valider,
          ),
        );

        // L'ancien code personnel est efface : Amina en choisit un nouveau.
        expect(m.lieu, Routes.connexionEleve);
        expect(
          find.text(t.eleveConnexion.pin.bonjour(prenom: 'Amina')),
          findsOneWidget,
        );
        expect(find.text(t.eleveConnexion.pin.creer), findsOneWidget);
        expect(m.coffre.jetons['e1'], 'jeton-e1-neuf');
        expect(m.coffre.empreintes.containsKey('e1'), isFalse);
        // Le code de Yusuf, lui, reste.
        expect(m.coffre.empreintes['e2'], isNotNull);

        await _composer(tester, '9753');
        await _composer(tester, '9753');
        expect(CodeLocal.correspond('9753', m.coffre.empreintes['e1']), isTrue);
        expect(m.service.jetonsOuverts, <String>['jeton-e1-neuf']);
      },
    );

    for (final (MotifRefusAppairage motif, String Function() attendu)
        in <(MotifRefusAppairage, String Function())>[
          (MotifRefusAppairage.horsLigne, () => t.eleveConnexion.pin.horsLigne),
          (
            MotifRefusAppairage.tropDEssais,
            () => t.eleveConnexion.pin.tropDEssais,
          ),
          (MotifRefusAppairage.generique, () => t.eleveConnexion.pin.echec),
        ]) {
      testWidgets('ouverture refusee (${motif.name}) : dit sous le titre', (
        WidgetTester tester,
      ) async {
        final _Eleve m = await _monterAppareil(
          tester,
          service: FauxEnfantOuverture()
            ..refusOuverture = AppairageRefuse(motif),
        );
        await _versChoix(tester);
        await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
        await _composer(tester, _codeAmina);

        expect(_message(attendu()), findsOneWidget);
        // Le pave revient, le profil reste sur l appareil.
        expect(find.byType(PinPad), findsOneWidget);
        expect(m.coffre.jetons['e1'], 'jeton-e1');
      });
    }

    testWidgets('code oublie : explication ; changer de profil ; retours', (
      WidgetTester tester,
    ) async {
      final _Eleve m = await _monterAppareil(tester);
      await _versChoix(tester);
      await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e2')));

      await _taper(tester, find.text(t.eleveConnexion.pin.oublie));
      expect(find.text(t.eleveConnexion.pin.oubliePhrase), findsOneWidget);

      await _taper(tester, find.text(t.eleveConnexion.pin.changerProfil));
      expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);

      // Disque retour : du pave au choix, du choix a la connexion.
      await _taper(tester, find.byKey(EleveConnexionPage.carteKey('e1')));
      await _taper(tester, find.byType(DisqueRetour));
      expect(find.text(t.eleveConnexion.choisirProfil), findsOneWidget);
      await _taper(tester, find.byType(DisqueRetour));
      expect(m.lieu, Routes.connexion);
    });

    testWidgets('texte a 200 % : les cartes passent en pile', (
      WidgetTester tester,
    ) async {
      await _monterAppareil(tester, echelleTexte: 2);
      await _versChoix(tester);
      final Offset a = tester.getTopLeft(
        find.byKey(EleveConnexionPage.carteKey('e1')),
      );
      final Offset y = tester.getTopLeft(
        find.byKey(EleveConnexionPage.carteKey('e2')),
      );
      expect(y.dy, greaterThan(a.dy));
      expect(y.dx, closeTo(a.dx, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('bureau 1440 : panneau centre, jamais une feuille etiree', (
      WidgetTester tester,
    ) async {
      await _monterAppareil(tester, taille: const Size(1440, 900));
      await _versChoix(tester);
      final Finder panneau = find
          .ancestor(
            of: find.byKey(EleveConnexionPage.carteKey('e1')),
            matching: find.byType(AppCard),
          )
          .last;
      final Rect r = tester.getRect(panneau);
      expect(r.width, lessThanOrEqualTo(560));
      expect(r.center.dx, closeTo(720, 40));
      // Meme composition que la saisie et le scanner : le disque retour et le
      // titre sont alignes sur le panneau, pas en haut a gauche de la page.
      final Rect cadre = tester.getRect(
        find.byKey(PanneauAppareilEleve.panneauKey),
      );
      expect(
        tester.getRect(find.byType(DisqueRetour)).left,
        closeTo(cadre.left, 1),
      );
      final Rect titre = tester.getRect(
        find.text(t.eleveConnexion.choisirProfil),
      );
      expect(titre.left, greaterThan(cadre.left));
      expect(titre.right, lessThanOrEqualTo(cadre.right));
      expect(tester.takeException(), isNull);
    });
  });
}

/// Un coffre dont la lecture du jeton d'appareil echoue (REVUE R-03).
class _CoffreJetonIllisible extends FauxStockageSecurise {
  @override
  Future<String?> jetonAppareil(String profilId) async {
    throw StateError('coffre illisible');
  }
}
