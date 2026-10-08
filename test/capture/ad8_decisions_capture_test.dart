// Captures de recette AD-8 (decisions ADM-02D refus, ADM-02E validation), sur
// la VRAIE coque admin et le vrai routeur, en demonstration (`?demo=admin`).
// Modele : `ad7_visionneuse_capture_test.dart`. Chaque ouverture tape le VRAI
// bouton « Refuser le dossier » / « Valider le dossier » de la revue (K-07).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement (RepereDemonstration
// visible sur chaque capture).
//
// Matrice couverte (item 2 du lot) : refus vide/erreur/saisi, envoi, reussite,
// conflit, inconnu, validation (ouverture, envoi, reussite), refus
// indisponible/interdit/trop long (port de capture), hors ligne (surface
// ouverte puis coupure) ; 390x844, 768x1024, 1440x900, clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/admin_dossiers/textes_dossier.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

late GoRouter _routeur;

/// Enveloppe la demonstration : `decider` attend [porte] avant de
/// transmettre, pour figer « ... en cours... » le temps d'une capture.
class _PortEnvoiControle implements PortRevueDossiers {
  _PortEnvoiControle(this._base, {this.erreur, this.avant});

  final PortRevueDossiers _base;

  /// Levee par `decider` a la place de la decision (etats secondaires).
  final Exception? erreur;

  /// Appele juste avant de lever [erreur] (coupure au moment du clic).
  final VoidCallback? avant;
  final Completer<void> porte = Completer<void>();

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => _base.listerDossiers(curseur: curseur, limite: limite, role: role);

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) =>
      _base.dossierPourRevue(dossierId);

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) => _base.demanderVuePiece(dossierId: dossierId, documentId: documentId);

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async {
    final Exception? e = erreur;
    if (e != null) {
      avant?.call();
      throw e;
    }
    await porte.future;
    return _base.decider(
      dossierId: dossierId,
      revisionAttendue: revisionAttendue,
      decision: decision,
      commandeId: commandeId,
      verificationsFaites: verificationsFaites,
      motif: motif,
    );
  }

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => _base.resultatDecision(dossierId: dossierId, commandeId: commandeId);
}

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode, {
  List<Override> plus = const <Override>[],
  PortRevueDossiers? port,
}) async {
  final List<Override> demo = surchargesDemoAdmin(environnement: 'staging');
  // surchargesDemoAdmin pose portRevueDossiersProvider en deuxieme : un port
  // de capture le remplace (une surcharge par fournisseur, HL-A-3).
  if (port != null) {
    demo[1] = portRevueDossiersProvider.overrideWithValue(port);
  }
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[...demo, ...plus],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              _routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: _routeur,
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  _routeur.go(Routes.admin);
  await _stabiliser(tester);
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// Personnes depuis la coque (tiroir mobile, rail ou barre laterale), puis la
/// ligne du dossier (K-07 : le VRAI dossier de la file, pas un widget isole).
Future<void> _ouvrirLigne(WidgetTester tester, String prenom) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(
              RegExp(AdminDomaine.personnes.libelle),
            ),
          )
          .first,
    );
  } else if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  if (rail.evaluate().isEmpty) {
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
  }
  await _stabiliser(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

/// Le champ de motif de 02D, retrouve par son etiquette (plusieurs
/// `TextField` existent ailleurs dans la coque, K-07 : jamais `byType` seul).
Finder get _champMotif => find
    .ancestor(
      of: find.text(t.dossiers.refus.champ),
      matching: find.byType(TextField),
    )
    .first;

/// FORM-L1 : le motif libre s'ecrit apres « Autre », derniere puce ; le
/// champ doit alors exister et recevoir le texte (jamais un `enterText` dans
/// le vide).
Future<void> _saisirMotif(WidgetTester tester, String texte) async {
  await tester.ensureVisible(find.byKey(SelecteurMotif.cleAutre));
  await _stabiliser(tester);
  await tester.tap(find.byKey(SelecteurMotif.cleAutre));
  await _stabiliser(tester);
  expect(_champMotif, findsOneWidget);
  await tester.enterText(_champMotif, texte);
}

Future<void> _versLabel(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(cible);
  await _stabiliser(tester);
}

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

void main() {
  group('Capture : AD-8 decisions (refus ADM-02D, validation ADM-02E)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, String nom) in _tailles) {
        // 1. Refus : vide -> erreur -> saisi -> envoi -> reussite, en UNE
        //    seule ouverture de 02D (dossier 01, nominal).
        testWidgets('$nom, refus vide/erreur/saisi/envoi/reussite, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final _PortEnvoiControle port = _PortEnvoiControle(
            RevueDossiersDemo(EtatRevueDemo.initial()),
          );
          await _monter(tester, taille, mode, port: port);
          await _ouvrirLigne(tester, 'Omar');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          // FORM-L1 : 02D s'ouvre sur les motifs proposes, « Autre » en
          // dernier ; le champ libre n'existe qu'apres « Autre ». Le focus est
          // dans la zone du motif (premiere puce).
          expect(find.byKey(SelecteurMotif.clePuce(0)), findsOneWidget);
          expect(find.byKey(SelecteurMotif.cleAutre), findsOneWidget);
          expect(find.text(t.dossiers.refus.champ), findsNothing);
          expect(
            FocusManager.instance.primaryFocus?.debugLabel,
            SelecteurMotif.focusPremierePuce,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_vide_${nom}_${mode.name}')}',
          );

          // Erreur : confirmer a vide.
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.erreurVide), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_erreur_${nom}_${mode.name}')}',
          );

          // Saisi : l'erreur disparait.
          await _saisirMotif(tester, 'Photo illisible.');
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.erreurVide), findsNothing);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_saisi_${nom}_${mode.name}')}',
          );

          // Envoi : confirme, mais la porte du port retient la reponse.
          await tester.tap(find.text(t.dossiers.refuser).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.text(t.dossiers.refus.envoi), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_envoi_${nom}_${mode.name}')}',
          );

          // Reussite : la porte s'ouvre, confirmation serveur, retour local.
          port.porte.complete();
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.succes), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_reussite_${nom}_${mode.name}')}',
          );
        });

        // 2. Validation (02E) : ouverture seulement (dossier 01, nominal),
        //    les trois verifications cochees. Focus sur Annuler.
        testWidgets('$nom, validation ouverture, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final _PortEnvoiControle port = _PortEnvoiControle(
            RevueDossiersDemo(EtatRevueDemo.initial()),
          );
          await _monter(tester, taille, mode, port: port);
          await _ouvrirLigne(tester, 'Omar');
          for (final String point in <String>[
            t.dossiers.pointLisible,
            t.dossiers.pointNom,
            t.dossiers.pointValidite,
          ]) {
            await _versLabel(tester, find.text(point));
            await tester.tap(find.text(point));
            await _stabiliser(tester);
          }
          await _versLabel(tester, find.text(t.dossiers.approuver));
          await tester.tap(find.text(t.dossiers.approuver));
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.titre), findsOneWidget);
          expect(
            find.text(corpsValidation('Omar Haddad', activation: true)),
            findsOneWidget,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_validation_${nom}_${mode.name}')}',
          );

          // Envoi puis reussite (« Dossier valide. ») depuis la meme 02E.
          await tester.tap(find.text(t.dossiers.approuver).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.text(t.dossiers.validation.envoi), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_validation_envoi_${nom}_${mode.name}')}',
          );
          port.porte.complete();
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.succes), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_validation_reussite_${nom}_${mode.name}')}',
          );
        });

        // 2 bis. Etats secondaires du refus (dossier 01) : le port de
        //        capture rend le code, la demonstration ne les atteint pas.
        for (final (String cas, Exception erreur, String texte)
            in <(String, Exception, String)>[
              (
                'indisponible',
                const CapaciteIndisponible('capture'),
                t.dossiers.refus.indisponible,
              ),
              (
                'interdit',
                const ErreurRevueDossier(CodeErreurRevue.interdit),
                t.dossiers.refus.interdit,
              ),
              (
                'trop_long',
                const ErreurRevueDossier(CodeErreurRevue.motifTropLong),
                t.dossiers.refus.tropLong,
              ),
            ]) {
          testWidgets('$nom, refus $cas, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, _densite(nom));
            await _monter(
              tester,
              taille,
              mode,
              port: _PortEnvoiControle(
                RevueDossiersDemo(EtatRevueDemo.initial()),
                erreur: erreur,
              ),
            );
            await _ouvrirLigne(tester, 'Omar');
            await _versLabel(tester, find.text(t.dossiers.refuser).first);
            await tester.tap(find.text(t.dossiers.refuser).first);
            await _stabiliser(tester);
            await _saisirMotif(tester, 'Photo illisible.');
            await _stabiliser(tester);
            await tester.tap(find.text(t.dossiers.refuser).last);
            await _stabiliser(tester);
            await _stabiliser(tester);
            expect(find.text(texte), findsOneWidget);
            debugPrint(
              'PNG ${await capturer(tester, 'ad8_refus_${cas}_${nom}_${mode.name}')}',
            );
          });
        }

        // 3. Refus, conflit (dossier 05 : un autre administrateur a tranche).
        testWidgets('$nom, refus conflit, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrirLigne(tester, 'Lina');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await _saisirMotif(tester, 'Photo illisible.');
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.decision.conflit), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_conflit_${nom}_${mode.name}')}',
          );
        });

        // 4. Refus, resultat inconnu (dossier 07 : reponse perdue).
        testWidgets('$nom, refus inconnu, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrirLigne(tester, 'Inès');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await _saisirMotif(tester, 'Photo illisible.');
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_inconnu_${nom}_${mode.name}')}',
          );
        });

        // 5. Hors ligne pendant que 02D est ouverte (surface ouverte AVANT
        //    la coupure : le reseau tombe apres l'ouverture, jamais avant).
        testWidgets('$nom, hors ligne dans la surface, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final StreamController<bool> reseau =
              StreamController<bool>.broadcast();
          addTearDown(reseau.close);
          await _monter(
            tester,
            taille,
            mode,
            plus: <Override>[
              horsLigneProvider.overrideWith((Ref ref) => reseau.stream),
            ],
          );
          await _ouvrirLigne(tester, 'Omar');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          reseau.add(true);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.horsLigne), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_hors_ligne_${nom}_${mode.name}')}',
          );
        });

        // HL-A-4. Hors ligne AU MOMENT DU CLIC : le motif est saisi, le
        //         reseau tombe pendant l'envoi, la requete echoue.
        testWidgets('HL-A-4 $nom, hors ligne au clic, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final StreamController<bool> reseau =
              StreamController<bool>.broadcast();
          addTearDown(reseau.close);
          await _monter(
            tester,
            taille,
            mode,
            port: _PortEnvoiControle(
              RevueDossiersDemo(EtatRevueDemo.initial()),
              erreur: Exception('reseau coupe'),
              avant: () => reseau.add(true),
            ),
            plus: <Override>[
              horsLigneProvider.overrideWith((Ref ref) => reseau.stream),
            ],
          );
          await _ouvrirLigne(tester, 'Omar');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await _saisirMotif(tester, 'Photo illisible.');
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.horsLigne), findsOneWidget);
          expect(find.text('Photo illisible.'), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_hors_ligne_clic_${nom}_${mode.name}')}',
          );
        });

        // HL-A-4. Validation (02E) en resultat inconnu et « plus prete ».
        for (final (String cas, CodeErreurRevue code, String texte)
            in <(String, CodeErreurRevue, String)>[
              (
                'inconnu',
                CodeErreurRevue.reponsePerdue,
                t.dossiers.validation.inconnu,
              ),
              (
                'plus_pret',
                CodeErreurRevue.accordManquant,
                t.dossiers.validation.plusPret,
              ),
            ]) {
          testWidgets('HL-A-4 $nom, validation $cas, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, _densite(nom));
            await _monter(
              tester,
              taille,
              mode,
              port: _PortEnvoiControle(
                RevueDossiersDemo(EtatRevueDemo.initial()),
                erreur: ErreurRevueDossier(code),
              ),
            );
            await _ouvrirLigne(tester, 'Omar');
            await _ouvrirValidationDansRevue(tester);
            await tester.tap(find.text(t.dossiers.approuver).last);
            await _stabiliser(tester);
            await _stabiliser(tester);
            expect(find.text(texte), findsOneWidget);
            debugPrint(
              'PNG ${await capturer(tester, 'ad8_validation_${cas}_${nom}_${mode.name}')}',
            );
          });
        }
      }

      // HL-A-4. Refus (motif saisi) et validation a 200 %, 390 et 1440.
      for (final (Size taille, String nom) in <(Size, String)>[
        _tailles.first,
        _tailles.last,
      ]) {
        testWidgets('HL-A-4 $nom, surfaces a 200 %, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _monter(tester, taille, mode);
          await _ouvrirLigne(tester, 'Omar');
          await _versLabel(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await _saisirMotif(tester, 'Photo illisible.');
          await _stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_refus_saisi_200_${nom}_${mode.name}')}',
          );
          // Echap, puis « Abandonner » : retour a la revue.
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refus.abandonner));
          await _stabiliser(tester);
          await _ouvrirValidationDansRevue(tester);
          expect(find.text(t.dossiers.validation.titre), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad8_validation_200_${nom}_${mode.name}')}',
          );
        });
      }
    }
  });
}

/// Coche les trois verifications puis tape « Valider le dossier » (revue
/// deja ouverte).
Future<void> _ouvrirValidationDansRevue(WidgetTester tester) async {
  for (final String point in <String>[
    t.dossiers.pointLisible,
    t.dossiers.pointNom,
    t.dossiers.pointValidite,
  ]) {
    await _versLabel(tester, find.text(point));
    await tester.tap(find.text(point));
    await _stabiliser(tester);
  }
  await _versLabel(tester, find.text(t.dossiers.approuver));
  await tester.tap(find.text(t.dossiers.approuver));
  await _stabiliser(tester);
}
