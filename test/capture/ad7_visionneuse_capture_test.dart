// Captures de recette AD-7 (visionneuse de piece), sur la VRAIE coque admin
// et le vrai routeur, en demonstration (`?demo=admin`). Modele :
// `ad6_revue_capture_test.dart`. Chaque ouverture tape le vrai bouton
// « Voir la piece » de la revue (K-07).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement (RepereDemonstration
// visible sur chaque capture, piece « Document fictif »).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
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

/// La demonstration, dont seule la vue de piece (ou le document) est
/// remplacee pour forcer un etat de la visionneuse (HL-A-3). Aucune donnee
/// reelle : le dossier reste celui de la demonstration.
class _PortCapture implements PortRevueDossiers {
  _PortCapture(this._base, {this.vue, this.sansDocument = false});

  final PortRevueDossiers _base;
  final Future<VuePiece> Function()? vue;
  final bool sansDocument;

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => _base.listerDossiers(curseur: curseur, limite: limite, role: role);

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) async {
    final DossierPourRevue d = await _base.dossierPourRevue(dossierId);
    if (!sansDocument) {
      return d;
    }
    return DossierPourRevue(
      dossierId: d.dossierId,
      revision: d.revision,
      prenom: d.prenom,
      nom: d.nom,
      role: d.role,
      soumisLeUtc: d.soumisLeUtc,
      statut: d.statut,
      exigencePiece: d.exigencePiece,
      etatPiece: d.etatPiece,
      verifications: d.verifications,
      accords: d.accords,
      peutValider: d.peutValider,
      peutRefuser: d.peutRefuser,
      peutVoirPiece: d.peutVoirPiece,
      blocagesValidation: d.blocagesValidation,
      blocagesRefus: d.blocagesRefus,
      consequence: d.consequence,
      typePiece: d.typePiece,
      revisionDocument: d.revisionDocument,
      peutResoumettre: d.peutResoumettre,
      blocagesAcces: d.blocagesAcces,
      lectureRequise: d.lectureRequise,
    );
  }

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) =>
      vue?.call() ??
      _base.demanderVuePiece(dossierId: dossierId, documentId: documentId);

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) => _base.decider(
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
  }) => _base.resultatDecision(dossierId: dossierId, commandeId: commandeId);
}

/// Les etats de la visionneuse captures a 390 et 1440 (HL-A-3) : nom, port
/// de capture, surcharges, texte attendu.
List<(String, PortRevueDossiers?, List<Override>, String)> _etats() {
  final RevueDossiersDemo demo = RevueDossiersDemo(EtatRevueDemo.initial());
  Future<VuePiece> erreur(CodeErreurRevue code) =>
      Future<VuePiece>.error(ErreurRevueDossier(code));
  return <(String, PortRevueDossiers?, List<Override>, String)>[
    (
      'chargement',
      _PortCapture(demo, vue: () => Completer<VuePiece>().future),
      const <Override>[],
      t.dossiers.visionneuse.chargement,
    ),
    (
      'format',
      _PortCapture(
        demo,
        vue: () => erreur(CodeErreurRevue.typeNonPrisEnCharge),
      ),
      const <Override>[],
      t.dossiers.visionneuse.formatNonPrisEnCharge,
    ),
    (
      'acces_retire',
      _PortCapture(demo, vue: () => erreur(CodeErreurRevue.interdit)),
      const <Override>[],
      t.dossiers.visionneuse.accesRetire,
    ),
    (
      'hors_ligne',
      null,
      <Override>[
        horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
      ],
      t.dossiers.visionneuse.horsLigne,
    ),
    (
      'aucune_piece',
      _PortCapture(demo, sansDocument: true),
      const <Override>[],
      t.dossiers.visionneuse.aucune,
    ),
  ];
}

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode, {
  List<Override> plus = const <Override>[],
  PortRevueDossiers? port,
}) async {
  final List<Override> demo = surchargesDemoAdmin(environnement: 'staging');
  // surchargesDemoAdmin pose portRevueDossiersProvider en deuxieme : un
  // port de capture le remplace (une surcharge par fournisseur).
  if (port != null) {
    demo[1] = portRevueDossiersProvider.overrideWithValue(port);
  }
  // La taille et la densite viennent de `fixerVueCapture` (390 a @3).
  // `MaterialApp.router` sur le vrai routeur plutot que `RewayahApp` : la
  // persistance des preferences appelle `path_provider`, absent sous
  // `runAsync` (meme choix que `ad6_revue_capture_test.dart`).
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

/// Personnes depuis la coque (tiroir mobile, rail ou barre laterale), la
/// ligne du dossier, puis le VRAI bouton « Voir la piece » (K-07).
Future<void> _voirPiece(WidgetTester tester, String prenom) async {
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
  final Finder bouton = find.text(t.dossiers.revue.voirPiece);
  await tester.ensureVisible(bouton);
  await _stabiliser(tester);
  await tester.tap(bouton);
  await _stabiliser(tester);
}

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

void main() {
  group('Capture : AD-7 visionneuse de piece', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      // 1. Contenu (« Document fictif »), 100 % : 390, 768, 1440.
      for (final (Size taille, String nom) in _tailles) {
        testWidgets('$nom, contenu, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _voirPiece(tester, 'Omar');
          expect(find.byType(VisionneusePiece), findsOneWidget);
          expect(
            find.text(t.dossiers.visionneuse.documentFictif),
            findsOneWidget,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ad7_contenu_${nom}_${mode.name}')}',
          );
        });
      }

      // 2. Zoom a 200 % (4 x Agrandir = 25 x 4 = 100 pts, donc echelle 2.0)
      //    a 390 seulement : verifie la lecture au-dela de 100 %.
      testWidgets('390x844@3, contenu a 200 %, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(390, 844);
        fixerVueCapture(tester, taille, 3);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Omar');
        for (int i = 0; i < 4; i++) {
          await tester.tap(
            find.bySemanticsLabel(t.dossiers.visionneuse.agrandir),
          );
          await tester.pump();
        }
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_contenu_200_390x844@3_${mode.name}')}',
        );
      });

      // 3. Lien expire (Karim), puis renouvellement (zoom conserve) : 1440.
      testWidgets('1440x900@1, lien expire puis renouvele, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(1440, 900);
        fixerVueCapture(tester, taille, 1);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Karim');
        expect(find.text(t.dossiers.visionneuse.expire), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_expire_1440x900@1_${mode.name}')}',
        );
        await tester.tap(find.text(t.dossiers.visionneuse.recharger));
        await _stabiliser(tester);
        expect(
          find.text(t.dossiers.visionneuse.documentFictif),
          findsOneWidget,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_expire_renouvele_1440x900@1_${mode.name}')}',
        );
      });

      // 4. Focus visible sur « Voir la piece » apres Echap : 1440.
      testWidgets('1440x900@1, focus apres Echap, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(1440, 900);
        fixerVueCapture(tester, taille, 1);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Omar');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _stabiliser(tester);
        expect(find.byType(VisionneusePiece), findsNothing);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_focus_echap_1440x900@1_${mode.name}')}',
        );
      });

      // 5. Etats de la visionneuse (HL-A-3) : chargement, format non pris en
      //    charge, acces retire, hors ligne, aucune piece ; 390 et 1440.
      for (final (Size taille, String nom) in <(Size, String)>[
        _tailles.first,
        _tailles.last,
      ]) {
        for (final (
              String etat,
              PortRevueDossiers? port,
              List<Override> plus,
              String texte,
            )
            in _etats()) {
          testWidgets('$nom, etat $etat, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, _densite(nom));
            await _monter(tester, taille, mode, plus: plus, port: port);
            await _voirPiece(tester, 'Omar');
            expect(find.byType(VisionneusePiece), findsOneWidget);
            if (etat == 'chargement') {
              expect(find.bySemanticsLabel(texte), findsWidgets);
            } else {
              expect(find.text(texte), findsOneWidget);
            }
            debugPrint(
              'PNG ${await capturer(tester, 'ad7_${etat}_${nom}_${mode.name}')}',
            );
          });
        }
      }
    }
  });
}
