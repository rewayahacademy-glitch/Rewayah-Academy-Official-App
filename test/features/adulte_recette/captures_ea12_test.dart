// EA-12b : jeu de captures complet pour la planche du directeur, comblant
// cinq trous connus (voir 05_recette/EA/RAPPORT.md) :
// 1. EA-10 : l'etat hors ligne de la recharge, jamais capture (la VRAIE
//    route de demonstration force `horsLigneProvider` a `false` pour tout
//    ecran hors Accueil/Ma classe, donc impossible a produire par la route).
// 2. EA-8 : le lien tertiaire « Demande de reprise du foyer » de Forfait
//    famille (ajoute en EA-11, apres les captures EA-8), rendu visible a
//    l'ecran par un defilement explicite.
// 3. EA-4 : Mon espace de l'adulte seul, a 768 et 1440 (seul 390 existait).
// 4. EA-7 : l'invitation recue (acceptee, refusee, erreur reseau) a 768 et
//    1440 (seul 390 existait).
// 5. EA-11 : les cinq etats rendus de la reprise, a 768 et 1440 (seul 390
//    existait).
//
// Depuis la VRAIE route /demo/adulte (`adresseDemoAdulte`), vrais boutons
// tapes, comme les fichiers precedents (K-07). Le hors ligne de la recharge,
// seul cas que la route ne peut pas produire, est monte directement sur
// `RechargeFoyerPage` avec `hoteCapture`, comme `captures_ea11_test.dart`
// (D5) le fait deja pour `RepriseTitulairePage`.
//
// 390x844, 768x1024 et 1440x900, clair et sombre, plus le texte a 200 % en
// 390 clair. Jamais sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea11_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

/// Les trois largeurs de la recette, dans leur ordre habituel.
const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 844)),
  ('768', Size(768, 1024)),
  ('1440', Size(1440, 900)),
];

/// Les deux largeurs qui manquaient aux captures existantes (deja a 390).
const List<(String, Size)> _taillesSauf390 = <(String, Size)>[
  ('768', Size(768, 1024)),
  ('1440', Size(1440, 900)),
];

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// Comme les fichiers precedents (ea7, ea8, ea10, ea11) : la VRAIE coquille,
/// sous un GoRouter sur la route de demonstration.
Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (avant != null) {
    await avant(tester);
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Un port dont la lecture echoue (pas de `CapaciteIndisponible`, pour que
/// l'ecran retienne la branche « hors ligne » plutot que « indisponible »),
/// comme `recharge_foyer_adulte_test.dart` (test « hors ligne : dit comme
/// tel »).
class _PortRechargeHorsLigne implements PortRechargeFoyer {
  const _PortRechargeHorsLigne();

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      Future<List<BeneficiaireRecharge>>.error(StateError('coupure'));

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(StateError('coupure'));

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(StateError('coupure'));
}

/// 1. La recharge hors ligne, montee directement : la route de
/// demonstration force `horsLigneProvider` a `false` pour cet ecran (voir
/// `demo_adulte_page.dart`), donc c'est le seul moyen de produire ce cas.
Future<void> _capturerRechargeHorsLigne(
  WidgetTester tester,
  String fichier,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      RechargeFoyerPage(onAbandon: () {}, onTerminee: () {}),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        portRechargeFoyerProvider.overrideWithValue(
          const _PortRechargeHorsLigne(),
        ),
      ],
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// 2. Adresse de Forfait famille, second adulte (porte le lien « Demande de
/// reprise du foyer » depuis EA-11).
String get _adresseForfait => adresseDemoAdulte(
  EcranDemoAdulte.forfaitFamille,
  vue: VueDemoAdulte.secondAdulte,
);

Future<void> _versLeLienReprise(WidgetTester tester) =>
    tester.ensureVisible(find.byKey(ForfaitFamillePage.repriseKey));

/// 5. Adresse de la reprise, second adulte, dans [etat] (comme
/// `captures_ea11_test.dart`).
String _adresseReprise({EtatDemoAdulte etat = EtatDemoAdulte.conjointActif}) =>
    adresseDemoAdulte(
      EcranDemoAdulte.repriseFoyer,
      etat: etat,
      vue: VueDemoAdulte.secondAdulte,
    );

/// 5. Tape « Deposer la demande » puis confirme (copie de
/// `captures_ea11_test.dart`, pour produire l'etat « deposee »).
Future<void> _deposer(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(RepriseFoyerPage.deposerKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(RepriseFoyerPage.deposerKey));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(ActionPrincipale, t.adulte.reprise.deposer).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  group(
    'Capture : EA-12, trou EA-10 (recharge hors ligne)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _modes) {
          final String fichier = 'ea12_recharge_hors_ligne_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturerRechargeHorsLigne(
              tester,
              fichier,
              taille,
              mode: mode,
            );
          });
        }
      }
      testWidgets('ea12_recharge_hors_ligne_390_light_200pc', (
        WidgetTester tester,
      ) async {
        await _capturerRechargeHorsLigne(
          tester,
          'ea12_recharge_hors_ligne_390_light_200pc',
          const Size(390, 844),
          echelle: 2,
        );
      });
    },
  );

  group(
    'Capture : EA-12, trou EA-8 (lien reprise de Forfait famille)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _modes) {
          final String fichier = 'ea12_forfait_lien_reprise_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              _adresseForfait,
              taille,
              mode: mode,
              avant: _versLeLienReprise,
            );
          });
        }
      }
      testWidgets('ea12_forfait_lien_reprise_390_light_200pc', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea12_forfait_lien_reprise_390_light_200pc',
          _adresseForfait,
          const Size(390, 844),
          echelle: 2,
          avant: _versLeLienReprise,
        );
      });
    },
  );

  group(
    'Capture : EA-12, trou EA-4 (Mon espace, adulte seul, 768/1440)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (String l, Size taille) in _taillesSauf390) {
        for (final ThemeMode mode in _modes) {
          final String fichier =
              'ea12_mon_espace_adulte_seul_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              adresseDemoAdulte(
                EcranDemoAdulte.monEspace,
                etat: EtatDemoAdulte.adulteSeul,
              ),
              taille,
              mode: mode,
            );
          });
        }
      }
    },
  );

  group(
    'Capture : EA-12, trou EA-7 (invitation recue, 768/1440)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      Future<void> accepter(WidgetTester tester) async {
        final Finder cible = find.byKey(InvitationRecuePage.accepterKey);
        await tester.ensureVisible(cible);
        await tester.tap(cible);
        await tester.pumpAndSettle();
      }

      Future<void> refuser(WidgetTester tester) async {
        final Finder cible = find.byKey(InvitationRecuePage.refuserKey);
        await tester.ensureVisible(cible);
        await tester.tap(cible);
        await tester.pumpAndSettle();
      }

      // Acceptee.
      for (final (String l, Size taille) in _taillesSauf390) {
        for (final ThemeMode mode in _modes) {
          final String fichier = 'ea12_invitation_acceptee_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              adresseDemoAdulte(
                EcranDemoAdulte.invitationRecue,
                etat: EtatDemoAdulte.invitationEnAttente,
                vue: VueDemoAdulte.secondAdulte,
              ),
              taille,
              mode: mode,
              avant: accepter,
            );
          });
        }
      }

      // Refusee.
      for (final (String l, Size taille) in _taillesSauf390) {
        for (final ThemeMode mode in _modes) {
          final String fichier = 'ea12_invitation_refusee_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              adresseDemoAdulte(
                EcranDemoAdulte.invitationRecue,
                etat: EtatDemoAdulte.invitationEnAttente,
                vue: VueDemoAdulte.secondAdulte,
              ),
              taille,
              mode: mode,
              avant: refuser,
            );
          });
        }
      }

      // Erreur reseau (D5), a l'acceptation.
      for (final (String l, Size taille) in _taillesSauf390) {
        for (final ThemeMode mode in _modes) {
          final String fichier =
              'ea12_invitation_echec_reseau_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              adresseDemoAdulte(
                EcranDemoAdulte.invitationRecue,
                etat: EtatDemoAdulte.erreurReseau,
                vue: VueDemoAdulte.secondAdulte,
              ),
              taille,
              mode: mode,
              avant: accepter,
            );
          });
        }
      }
    },
  );

  group(
    'Capture : EA-12, trou EA-11 (etats de la reprise, 768/1440)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (String nom, EtatDemoAdulte? etat)
          in <(String, EtatDemoAdulte?)>[
            ('deposee', null),
            (
              'refusee_par_titulaire',
              EtatDemoAdulte.repriseRefuseeParTitulaire,
            ),
            ('attente_administration', EtatDemoAdulte.repriseSansReponse),
            ('validee', EtatDemoAdulte.repriseValidee),
            ('refusee', EtatDemoAdulte.repriseRefusee),
          ]) {
        for (final (String l, Size taille) in _taillesSauf390) {
          for (final ThemeMode mode in _modes) {
            final String fichier = 'ea12_reprise_etat_${nom}_${l}_${mode.name}';
            testWidgets(fichier, (WidgetTester tester) async {
              await _capturer(
                tester,
                fichier,
                _adresseReprise(etat: etat ?? EtatDemoAdulte.conjointActif),
                taille,
                mode: mode,
                avant: etat == null ? _deposer : null,
              );
            });
          }
        }
      }
    },
  );
}
