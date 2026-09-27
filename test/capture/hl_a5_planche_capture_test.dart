// Captures de planche HL-A-5 : chaque ecran de la portee AD-6 a AD-10, dans
// son etat final, sur la VRAIE coque admin et le vrai routeur, en
// demonstration (`?demo=admin` / `?demo=tuteur`). Modele :
// `ad10_parcours_capture_test.dart`. Chaque etat est ouvert par des tap reels
// (K-07) ; « coque et file » n'est qu'observee, jamais modifiee (AD-S et AD-5
// s'harmonisent en HU-1).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// <ecran>_<telephone|tablette|ordinateur>_<clair|sombre>.png.

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

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  List<Override> surcharges,
  String depart,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surcharges,
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
  _routeur.go(depart);
  await _stabiliser(tester);
}

List<Override> _admin(EtatRevueDemo e) =>
    surchargesDemoAdmin(environnement: 'staging', etat: e);

List<Override> _personne(EtatRevueDemo e, String id) =>
    surchargesDemoTuteur(environnement: 'staging', dossiers: e, titulaire: id);

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

/// Un domaine depuis la coque : rail, barre laterale ou tiroir mobile.
Future<void> _domaine(WidgetTester tester, AdminDomaine domaine) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(RegExp(domaine.libelle)),
          )
          .first,
    );
  } else {
    final bool mobile = barre.evaluate().isEmpty;
    if (mobile) {
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await _stabiliser(tester);
    }
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(domaine.libelle),
      ),
    );
  }
  await _stabiliser(tester);
}

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await _domaine(tester, AdminDomaine.personnes);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

Future<void> _cocherTout(WidgetTester tester) async {
  for (final String point in <String>[
    t.dossiers.pointLisible,
    t.dossiers.pointNom,
    t.dossiers.pointValidite,
  ]) {
    await tester.ensureVisible(find.text(point).first);
    await _stabiliser(tester);
    await tester.tap(find.text(point).first);
    await _stabiliser(tester);
  }
}

Finder get _champMotif => find
    .ancestor(
      of: find.text(t.dossiers.refus.champ),
      matching: find.byType(TextField),
    )
    .first;

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), 'telephone'),
  (Size(768, 1024), 'tablette'),
  (Size(1440, 900), 'ordinateur'),
];

double _densite(String nom) => nom == 'telephone' ? 3 : 1;

const Map<ThemeMode, String> _modes = <ThemeMode, String>{
  ThemeMode.light: 'clair',
  ThemeMode.dark: 'sombre',
};

EtatRevueDemo _etat({bool superAdmin = true}) => EtatRevueDemo.initial(
  maintenant: DateTime.utc(2026, 9, 26, 12),
  superAdmin: superAdmin,
);

const String _amina = DonneesDossiersDemo.tuteurDocumentaire;
const String _hana = DonneesDossiersDemo.familleDispensee;
const String _motif = 'Motif fictif : la photo de la pièce est floue.';

void main() {
  group('Capture : planche HL-A-5', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (Size taille, String tailleNom) in _tailles) {
      for (final MapEntry<ThemeMode, String> mode in _modes.entries) {
        String fichier(String ecran) => '${ecran}_${tailleNom}_${mode.value}';

        // Chaine principale : coque/file, fiche, verifications, visionneuse,
        // refus, erreur de motif, validation, decision reussie.
        testWidgets('$tailleNom, ${mode.value}, chaine principale', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          await _monter(tester, mode.key, _admin(_etat()), Routes.admin);

          // 1. La coque et la file, telles quelles.
          await _domaine(tester, AdminDomaine.personnes);
          await tester.ensureVisible(_ligne('Omar'));
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('coque_et_file'))}');

          // 2. Fiche du dossier (revue nominale, Omar).
          await tester.tap(_ligne('Omar'));
          await _stabiliser(tester);
          // Cadrage propre : defilee jusqu'a l'emplacement de decision (la
          // capture a l'ouverture etait identique a « coque et file »).
          await tester.ensureVisible(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('fiche_dossier'))}');

          // 3. Verifications incompletes.
          const String lien = 'Terminez les vérifications requises.';
          await tester.ensureVisible(find.text(lien));
          await _stabiliser(tester);
          await tester.tap(find.text(lien));
          await _stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, fichier('verifications_incompletes'))}',
          );

          // 4. Visionneuse.
          await tester.ensureVisible(find.text('Voir la pièce'));
          await _stabiliser(tester);
          await tester.tap(find.text('Voir la pièce'));
          await _stabiliser(tester);
          expect(find.byType(VisionneusePiece), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('visionneuse'))}');
          await tester.tap(
            find.descendant(
              of: find.byType(VisionneusePiece),
              matching: find.text(t.commun.fermer),
            ),
          );
          await _stabiliser(tester);

          // 5. Refus (motif vide).
          await tester.ensureVisible(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.champ), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('refus'))}');

          // 6. Erreur de motif (confirmer a vide).
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.erreurVide), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('erreur_motif'))}');
          // Motif encore vide : `canPop` laisse Echap fermer directement,
          // sans la confirmation « Abandonner » (surfaces_decision.dart).
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await _stabiliser(tester);

          // 7. Validation (trois verifications cochees, ouverture 02E).
          await _cocherTout(tester);
          await tester.ensureVisible(find.text(t.dossiers.approuver).first);
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.approuver).first);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.titre), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('validation'))}');

          // 8. Decision reussie (confirmation serveur, retour local).
          await tester.tap(find.text(t.dossiers.approuver).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.succes), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('decision_reussie'))}',
          );
        });

        // 9. Resultat inconnu (dossier Ines : reponse perdue, fixture demo).
        testWidgets('$tailleNom, ${mode.value}, resultat inconnu', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          await _monter(tester, mode.key, _admin(_etat()), Routes.admin);
          await _ouvrir(tester, 'Inès');
          await tester.ensureVisible(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await tester.enterText(_champMotif, 'Photo illisible.');
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.refus.inconnu), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('resultat_inconnu'))}',
          );
        });

        // 10, 11. Politique de genre : activee puis desactivee.
        testWidgets('$tailleNom, ${mode.value}, politique', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          await _monter(tester, mode.key, _admin(_etat()), Routes.admin);
          await _domaine(tester, AdminDomaine.configuration);
          await tester.ensureVisible(
            find.text(t.admin.politiqueRevueKyc.titre),
          );
          await _stabiliser(tester);
          await tester.tap(find.text(t.admin.politiqueRevueKyc.titre));
          await _stabiliser(tester);
          expect(find.byType(Switch), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('politique_activee'))}',
          );
          await tester.tap(find.byType(Switch));
          await _stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, fichier('politique_desactivee'))}',
          );
        });

        // 12. Acces refuse (sans Super Admin, route ouverte directement).
        testWidgets('$tailleNom, ${mode.value}, acces refuse', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          await _monter(
            tester,
            mode.key,
            _admin(_etat(superAdmin: false)),
            Routes.adminConfigurationPolitiqueRevueKyc,
          );
          debugPrint('PNG ${await capturer(tester, fichier('acces_refuse'))}');
        });

        // 13. Portail /attente apres refus (AD-10 : geste admin pose dans
        //     l'etat partage, seul le rendu cote personne est ici prouve).
        testWidgets('$tailleNom, ${mode.value}, portail apres refus', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          final EtatRevueDemo e = _etat();
          await RevueDossiersDemo(e).decider(
            dossierId: _amina,
            revisionAttendue: e.dossiers[_amina]!.revision,
            decision: DecisionDossier.refuser,
            commandeId: 'capture-hl-a5-refus',
            verificationsFaites: const <String>{},
            motif: _motif,
          );
          await _monter(tester, mode.key, _personne(e, _amina), Routes.attente);
          expect(find.text(t.attente.refuse), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('portail_apres_refus'))}',
          );
        });

        // 14. Retour a l'accueil apres validation (AD-10 : reprise en
        //     premier plan, decision posee cote serveur pendant l'absence).
        testWidgets('$tailleNom, ${mode.value}, retour apres validation', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(tailleNom));
          final EtatRevueDemo e = _etat();
          await _monter(tester, mode.key, _personne(e, _hana), Routes.attente);
          await RevueDossiersDemo(e).decider(
            dossierId: _hana,
            revisionAttendue: e.dossiers[_hana]!.revision,
            decision: DecisionDossier.valider,
            commandeId: 'capture-hl-a5-validation',
            verificationsFaites: const <String>{},
          );
          for (final AppLifecycleState s in <AppLifecycleState>[
            AppLifecycleState.inactive,
            AppLifecycleState.hidden,
            AppLifecycleState.paused,
            AppLifecycleState.hidden,
            AppLifecycleState.inactive,
            AppLifecycleState.resumed,
          ]) {
            tester.binding.handleAppLifecycleStateChanged(s);
          }
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(
            _routeur.routerDelegate.currentConfiguration.uri.path,
            startsWith(Routes.tuteurAccueil),
          );
          debugPrint(
            'PNG ${await capturer(tester, fichier('retour_apres_validation_hors_portee'))}',
          );
        });
      }
    }
  });
}
