// SALLE-1 lot 4 (arbitrage du garde-cap, PLAN-TROIS-SALLES-2026-11-07 §2) :
// en tete des accords et du contrat, UNE ligne discrete « Lisez jusqu'en bas
// pour confirmer ». L'action reste a la fin du texte (on confirme apres avoir
// lu) : aucun bouton repete en tete, aucun bloc.
//
// Ce que le test prouve, par ecran : la ligne est la, une seule fois, au-dessus
// de tout le reste ; il n'y a toujours qu'UN bouton plein, sous le texte ; elle
// n'est pas la quand il n'y a plus rien a confirmer. Captures 390 x 844 avant /
// apres (PHASE=avant|apres) avec CAPTURE_DIR.
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/resignature_contrat.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/dossier/accords_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';

EtatDossier _etat(AppRole role, {bool tout = false}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: tout,
  contratSigne: tout,
  codeConduiteSigne: true,
  pieceDeposee: true,
  statutPiece: StatutPiece.enAttente,
);

Future<void> _monter(
  WidgetTester tester, {
  required Widget page,
  required EtatDossier etat,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..demonstration = true
    ..etatRendu = etat;
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attenteAccords,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attenteAccords,
          builder: (BuildContext _, GoRouterState _) => page,
        ),
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('portail')),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
        resignatureContratEnseignantProvider.overrideWithValue(false),
        portSignatureContratProvider.overrideWithValue(null),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _ligne => find.text(t.commun.lireJusquEnBas);

/// Les boutons pleins : `ActionPrincipale` de niveau principal.
int _boutonsPleins(WidgetTester tester) => tester
    .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
    .where((ActionPrincipale a) => a.niveau == NiveauAction.principale)
    .length;

void main() {
  group('Accords : la ligne en tete, l\'action a la fin', () {
    testWidgets('tuteur : une ligne, au-dessus du reste, un seul bouton plein, '
        'sous le texte', (WidgetTester tester) async {
      await _monter(
        tester,
        page: const AccordsPage(),
        etat: _etat(AppRole.guardian),
      );
      expect(_ligne, findsOneWidget);
      // Au-dessus de l'introduction et de tout texte a lire.
      final double yLigne = tester.getTopLeft(_ligne).dy;
      expect(
        yLigne,
        lessThan(tester.getTopLeft(find.text(t.accords.introCases)).dy),
      );
      // L'action n'est pas repetee en tete : un seul bouton plein, et il est
      // plus bas que la ligne (a la fin du texte).
      expect(_boutonsPleins(tester), 1);
      final Finder suivant = find.byKey(
        const ValueKey<String>('accords-suivant'),
      );
      expect(tester.getTopLeft(suivant).dy, greaterThan(yLigne));
    });

    testWidgets('enseignant : la meme ligne', (WidgetTester tester) async {
      await _monter(
        tester,
        page: const AccordsPage(),
        etat: _etat(AppRole.teacher),
      );
      expect(_ligne, findsOneWidget);
      expect(_boutonsPleins(tester), 1);
    });

    testWidgets('contre-epreuve : plus rien a confirmer, pas de ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        page: const AccordsPage(),
        etat: _etat(AppRole.guardian, tout: true),
      );
      expect(_ligne, findsNothing);
    });
  });

  group('Contrat : la ligne en tete, l\'action a la fin', () {
    testWidgets('une ligne, au-dessus du texte, un seul bouton plein', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        page: const ContratPage(),
        etat: _etat(AppRole.teacher, tout: true),
      );
      expect(_ligne, findsOneWidget);
      final double yLigne = tester.getTopLeft(_ligne).dy;
      expect(
        yLigne,
        lessThan(tester.getTopLeft(find.text(t.contrat.e1.quoi)).dy),
      );
      expect(_boutonsPleins(tester), 1);
      expect(
        tester.getTopLeft(find.text(t.contrat.accepter)).dy,
        greaterThan(yLigne),
      );
    });

    testWidgets('tuteur : la ligne aussi, avant le texte de l\'accuse', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        page: const ContratPage(),
        etat: _etat(AppRole.guardian, tout: true),
      );
      expect(_ligne, findsOneWidget);
      expect(_boutonsPleins(tester), 1);
    });
  });

  group('Capture lot 4 : la ligne en tete', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    final String phase = Platform.environment['PHASE'] ?? 'apres';
    final Map<String, (Widget, EtatDossier)> ecrans =
        <String, (Widget, EtatDossier)>{
          'accords': (const AccordsPage(), _etat(AppRole.guardian)),
          'contrat': (const ContratPage(), _etat(AppRole.teacher, tout: true)),
        };
    for (final MapEntry<String, (Widget, EtatDossier)> e in ecrans.entries) {
      for (final bool arabe in <bool>[false, true]) {
        final String langue = arabe ? 'ar' : 'fr';
        testWidgets('${e.key} $langue 390x844 ($phase)', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(
            () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
          );
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          await _monter(tester, page: e.value.$1, etat: e.value.$2);
          debugPrint(
            'PNG ${await capturerVue(tester, 'lire_bas_${e.key}_${phase}_${langue}_390x844')}',
          );
        });
      }
    }
  });
}
