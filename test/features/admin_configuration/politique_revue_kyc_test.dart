// AD-9 : politique de genre pour la revue KYC, depuis la VRAIE coque admin et
// le vrai routeur (`?demo=admin`). Chaque parcours tape la barre laterale,
// puis l'onglet, puis l'interrupteur (K-07).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/demo/services_admin_demo.dart';

import '../../support/harnais.dart';
import '../../support/selecteur_section.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final DateTime _fixe = DateTime.utc(2026, 9, 26, 12);

/// Port de test : compte les appels, peut echouer ou retenir la reponse.
class _PortTest implements PortPolitiqueRevueKyc {
  _PortTest(this._base);

  final PortPolitiqueRevueKyc _base;
  int lectures = 0;
  int modifications = 0;
  Exception? erreurLecture;
  Completer<void>? porteLecture;
  Completer<void>? porteModification;

  @override
  Future<PolitiqueRevueKyc> lire() async {
    lectures++;
    final Exception? e = erreurLecture;
    if (e != null) {
      erreurLecture = null;
      throw e;
    }
    await porteLecture?.future;
    return _base.lire();
  }

  @override
  Future<PolitiqueRevueKyc> modifier({
    required bool genreRelecteurApplique,
    required int versionAttendue,
  }) async {
    modifications++;
    await porteModification?.future;
    return _base.modifier(
      genreRelecteurApplique: genreRelecteurApplique,
      versionAttendue: versionAttendue,
    );
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required EtatRevueDemo etat,
  PortPolitiqueRevueKyc? port,
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final List<Override> demo = surchargesDemoAdmin(
    environnement: 'staging',
    etat: etat,
  );
  // surchargesDemoAdmin pose le port de politique en troisieme.
  if (port != null) {
    demo[2] = portPolitiqueRevueKycProvider.overrideWithValue(port);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: demo,
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(Routes.admin);
  await _stabiliser(tester);
  return routeur;
}

EtatRevueDemo _etat({
  bool superAdmin = true,
  bool politiqueGenre = true,
  bool genreRelecteurRenseigne = true,
}) => EtatRevueDemo.initial(
  maintenant: _fixe,
  superAdmin: superAdmin,
  politiqueGenre: politiqueGenre,
  genreRelecteurRenseigne: genreRelecteurRenseigne,
);

Future<void> _domaine(WidgetTester tester, AdminDomaine domaine) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(AdminShell.barreLateraleKey),
      matching: find.text(domaine.libelle),
    ),
  );
  await _stabiliser(tester);
}

Future<void> _ouvrirReglage(WidgetTester tester) async {
  await _domaine(tester, AdminDomaine.configuration);
  // La section de fin : segment ou entree du menu selon la largeur.
  await choisirSection(tester, t.admin.politiqueRevueKyc.titre);
  await _stabiliser(tester);
}

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

Future<void> _visible(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await _stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await _stabiliser(tester);
  await tester.tap(cible);
  await _stabiliser(tester);
}

bool _valeurSwitch(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  testWidgets('G1 : Super Admin, taper l\'onglet puis l\'interrupteur', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    await _monter(tester, etat: etat);
    await _ouvrirReglage(tester);

    expect(find.text(t.admin.politiqueRevueKyc.libelle), findsOneWidget);
    expect(find.text(t.admin.politiqueRevueKyc.aide), findsOneWidget);
    expect(_valeurSwitch(tester), isTrue);
    expect(find.bySemanticsLabel(RegExp('Démonstration')), findsWidgets);
    for (final String absent in <String>[
      'Activée',
      'Désactivée',
      'ADM-02.4',
      'Les changements sont enregistrés et audités.',
    ]) {
      expect(find.text(absent), findsNothing);
    }

    await tester.tap(find.byType(Switch));
    await _stabiliser(tester);
    expect(_valeurSwitch(tester), isFalse);
    expect(etat.politiqueGenre, isFalse);
    expect(etat.versionPolitique, 2);
  });

  testWidgets('G2/G3 : politique activee puis desactivee, dossier 06', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    await _monter(tester, etat: etat);

    // G3 : activee, la piece est hors de portee.
    await _domaine(tester, AdminDomaine.personnes);
    await _visible(tester, _ligne('Adam'));
    expect(find.text('Pièce hors de votre portée'), findsWidgets);

    // G1 puis G2 : desactiver, revenir a la file.
    await _ouvrirReglage(tester);
    await tester.tap(find.byType(Switch));
    await _stabiliser(tester);
    await _domaine(tester, AdminDomaine.personnes);
    await _visible(tester, _ligne('Adam'));
    expect(find.text('Pièce hors de votre portée'), findsNothing);
    await tester.tap(_ligne('Adam'));
    await _stabiliser(tester);
    final Finder voir = find.text('Voir la pièce');
    await _visible(tester, voir);
    await tester.tap(voir);
    await _stabiliser(tester);
    expect(find.text('Document fictif'), findsWidgets);

    // La decision n'est plus bloquee par le genre : fermer, cocher, valider.
    await _toucher(
      tester,
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: find.text(t.commun.fermer),
      ),
    );
    expect(find.byType(VisionneusePiece), findsNothing);
    for (final String point in <String>[
      t.dossiers.pointLisible,
      t.dossiers.pointNom,
      t.dossiers.pointValidite,
    ]) {
      await _toucher(tester, find.text(point).first);
    }
    await _toucher(tester, find.text(t.dossiers.approuver).first);
    expect(find.text(t.dossiers.validation.titre), findsOneWidget);
    expect(etat.nombreDecisions, 0);
    await tester.tap(find.text(t.dossiers.approuver).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(etat.nombreDecisions, 1);
  });

  testWidgets('G4 : genre absent, politique activee : Profil a completer', (
    WidgetTester tester,
  ) async {
    await _monter(tester, etat: _etat(genreRelecteurRenseigne: false));
    await _domaine(tester, AdminDomaine.personnes);
    expect(find.text(t.dossiers.profilACompleter.titre), findsWidgets);
    expect(find.text(t.dossiers.profilACompleter.texte), findsWidgets);
    expect(find.text('Compléter mon profil'), findsNothing);
    expect(find.textContaining('genre'), findsNothing);
  });

  testWidgets('G5/G6 : genre absent, bascule puis retour a la file', (
    WidgetTester tester,
  ) async {
    await _monter(tester, etat: _etat(genreRelecteurRenseigne: false));
    await _domaine(tester, AdminDomaine.personnes);
    expect(find.text(t.dossiers.profilACompleter.titre), findsWidgets);

    await _ouvrirReglage(tester);
    await tester.tap(find.byType(Switch));
    await _stabiliser(tester);
    await _domaine(tester, AdminDomaine.personnes);
    expect(find.text(t.dossiers.profilACompleter.titre), findsNothing);
    await _visible(tester, _ligne('Adam'));
    expect(_ligne('Adam'), findsOneWidget);
    expect(find.textContaining('genre'), findsNothing);
  });

  testWidgets('G7 : sans Super Admin, trois onglets et route refusee', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      etat: _etat(superAdmin: false),
    );
    await _domaine(tester, AdminDomaine.configuration);
    expect(find.text(t.admin.regles.titre), findsWidgets);
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
    expect(find.byType(Switch), findsNothing);

    routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
    await _stabiliser(tester);
    expect(find.text(t.commun.etats.accesRefuse.titre), findsOneWidget);
    expect(find.text(t.admin.politiqueRevueKyc.libelle), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('G8 : conflit de version, valeur serveur relue', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    await _monter(tester, etat: etat);
    await _ouvrirReglage(tester);
    etat.versionPolitique += 1;
    await tester.tap(find.byType(Switch));
    await _stabiliser(tester);
    expect(_valeurSwitch(tester), isTrue);
    expect(etat.politiqueGenre, isTrue);
    expect(
      find.text(t.admin.politiqueRevueKyc.echecEnregistrement),
      findsOneWidget,
    );
  });

  testWidgets('G9 : capacite retiree avant la bascule : acces refuse', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    await _monter(tester, etat: etat);
    await _ouvrirReglage(tester);
    etat.superAdmin = false;
    await tester.tap(find.byType(Switch));
    await _stabiliser(tester);
    expect(find.text(t.commun.etats.accesRefuse.titre), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(etat.politiqueGenre, isTrue);
  });

  testWidgets('G10 : envoi en cours, un seul appel', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    final _PortTest port = _PortTest(PolitiqueRevueKycDemo(etat))
      ..porteModification = Completer<void>();
    await _monter(tester, etat: etat, port: port);
    await _ouvrirReglage(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pump();
    expect(port.modifications, 1);
    port.porteModification!.complete();
    await _stabiliser(tester);
    expect(_valeurSwitch(tester), isFalse);
  });

  testWidgets('G11 : lecture en erreur, Reessayer relit une fois', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    final _PortTest port = _PortTest(PolitiqueRevueKycDemo(etat));
    final GoRouter routeur = await _monter(tester, etat: etat, port: port);
    port.erreurLecture = Exception('panne');
    routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
    await _stabiliser(tester);
    expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
    // AD-9-ONGLET-PROD : capacite inconnue, ni titre ni onglet reserve.
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
    final int avant = port.lectures;
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    await _stabiliser(tester);
    expect(port.lectures, avant + 1);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('G11 bis : chargement, le squelette partage', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = _etat();
    final _PortTest port = _PortTest(PolitiqueRevueKycDemo(etat))
      ..porteLecture = Completer<void>();
    final GoRouter routeur = await _monter(tester, etat: etat, port: port);
    routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
    await _stabiliser(tester);
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(Switch), findsNothing);
    // AD-9-ONGLET-PROD : pendant le chargement, rien du reglage reserve.
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
    port.porteLecture!.complete();
    await _stabiliser(tester);
    expect(find.byType(Switch), findsOneWidget);
    // Capacite connue et vraie : le titre et le 4e onglet reviennent.
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsWidgets);
  });

  testWidgets('G12 : port de production, aucun onglet, pas encore disponible', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      etat: _etat(),
      port: const PolitiqueRevueKycIndisponible(),
    );
    await _domaine(tester, AdminDomaine.configuration);
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
    routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
    await _stabiliser(tester);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    // AD-9-ONGLET-PROD : sur la ROUTE aussi, aucun onglet reserve.
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
  });

  testWidgets('G13 : coque de production (sans ?demo=admin), port par defaut', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // Seule la session admin est simulee ; le port de politique garde
          // sa valeur de production (PolitiqueRevueKycIndisponible).
          sourceSessionProvider.overrideWithValue(
            const SourceSessionDemoAdmin(),
          ),
          stockagePreferencesProvider.overrideWithValue(
            StockagePreferencesMemoire(),
          ),
          serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
          indicateursProvider.overrideWith(
            (Ref ref) async => const IndicateursAdmin(
              dossiersEnAttente: 0,
              foyersSansEnseignant: 0,
              rapportsManquants: 0,
              incidents24h: 0,
              comptesEchus: 0,
              demandesEnAttente: 0,
            ),
          ),
          demandesProvider.overrideWith((Ref ref) async => const <Demande>[]),
          ...surchargesServicesAdminIndisponibles(),
        ],
        child: TranslationProvider(child: const RewayahApp()),
      ),
    );
    await _stabiliser(tester);
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(RewayahApp)),
    );
    expect(
      conteneur.read(portPolitiqueRevueKycProvider),
      isA<PolitiqueRevueKycIndisponible>(),
    );
    final GoRouter routeur = conteneur.read(routeurProvider)..go(Routes.admin);
    await _stabiliser(tester);
    await _domaine(tester, AdminDomaine.configuration);
    expect(find.text(t.admin.regles.titre), findsWidgets);
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);

    routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
    await _stabiliser(tester);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.admin.politiqueRevueKyc.libelle), findsNothing);
    expect(find.byType(Switch), findsNothing);
    // AD-9-ONGLET-PROD : la route tapee a la main ne montre pas l'onglet.
    expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
  });
}
