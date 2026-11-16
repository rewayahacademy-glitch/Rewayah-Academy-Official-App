// PAYS-VERSEMENT (directeur, 15/11/2026) : apres l'envoi, le candidat change
// lui-meme le pays de son compte de versement depuis son portail ; la
// candidature n'est jamais refusee pour ce motif.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';
import 'package:rewayah_academy/features/candidature/question_etape.dart'
    show motsClesDuPays, paysCourants;

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

CandidatureDossier _envoyee({
  IssueCandidature issue = IssueCandidature.enCours,
}) => CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.paiementNonDisponible,
  issue: issue,
  version: 4,
  questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 11, 10)),
);

Future<void> _monter(
  WidgetTester tester,
  CandidatureDossier candidature,
  FauxMaCandidature port, {
  Size taille = const Size(1440, 900),
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(candidature: candidature);
  await monterQuestionnaire(
    tester,
    port: port,
    depart: Routes.attente,
    taille: taille,
    dossier: dossier,
  );
}

void main() {
  // PAYS-RECHERCHE (directeur, 16/11/2026) : « Quelqu'un ne retrouve pas le
  // Ghana ». Le pays existait ; la recherche ne lisait que le nom dans la langue
  // de l'interface.
  group('recherche d un pays', () {
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    Future<void> ouvrirEtChercher(
      WidgetTester tester,
      AppLocale langue,
      String frappe,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      await _monter(tester, _envoyee(), FauxMaCandidature());
      await tester.ensureVisible(_cle('pays-versement-lien'));
      await tester.tap(_cle('pays-versement-lien'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), frappe);
      await tester.pumpAndSettle();
    }

    for (final (AppLocale langue, String frappe) in <(AppLocale, String)>[
      (AppLocale.ar, 'Ghana'),
      (AppLocale.ar, 'gh'),
      (AppLocale.ar, 'GH'),
      (AppLocale.fr, 'غانا'),
      (AppLocale.fr, 'Ghana'),
      (AppLocale.en, 'غانا'),
    ]) {
      testWidgets('en ${langue.name}, « $frappe » trouve le Ghana', (
        WidgetTester tester,
      ) async {
        await ouvrirEtChercher(tester, langue, frappe);
        expect(_cle('pays-versement-GH'), findsOneWidget);
      });
    }

    testWidgets('en arabe, une frappe sans rapport ne trouve pas le Ghana', (
      WidgetTester tester,
    ) async {
      await ouvrirEtChercher(tester, AppLocale.ar, 'Japon');
      expect(_cle('pays-versement-GH'), findsNothing);
      expect(_cle('pays-versement-JP'), findsOneWidget);
    });
  });

  test('les mots-cles d un pays : trois noms et le code', () {
    final PaysIso gh = paysIso.firstWhere((PaysIso p) => p.code == 'GH');
    final String m = motsClesDuPays(gh);
    expect(m, contains(gh.fr));
    expect(m, contains(gh.ar));
    expect(m, contains(gh.en));
    expect(m, contains('GH'));
  });

  test('la liste courte suit les vraies candidatures', () {
    expect(paysCourants.take(8), <String>[
      'SA', 'NG', 'YE', 'EG', 'DZ', 'BJ', 'GH', 'TD', //
    ]);
    expect(paysCourants.toSet().length, paysCourants.length);
    expect(
      paysCourants.every((String c) => paysIso.any((PaysIso p) => p.code == c)),
      isTrue,
    );
  });

  testWidgets('les pays courants sont proposes d emblee, le Ghana compris', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _envoyee(), FauxMaCandidature());
    await tester.ensureVisible(_cle('pays-versement-lien'));
    await tester.tap(_cle('pays-versement-lien'));
    await tester.pumpAndSettle();
    for (final String c in <String>['SA', 'NG', 'GH']) {
      expect(_cle('pays-versement-$c'), findsOneWidget);
    }
  });
  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(390, 844),
  ]) {
    testWidgets(
      'apres l envoi, le candidat change le pays de versement (${taille.width.toInt()})',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await _monter(tester, _envoyee(), port, taille: taille);
        expect(_cle('pays-versement-lien'), findsOneWidget);
        await tester.ensureVisible(_cle('pays-versement-lien'));
        await tester.tap(_cle('pays-versement-lien'));
        await tester.pumpAndSettle();
        expect(
          find.text(t.recrutement.portail.paysVersementExplication),
          findsOneWidget,
        );
        // Pas de bouton tant que le compte et le pays ne sont pas choisis.
        expect(_cle('pays-versement-enregistrer'), findsNothing);
        await tester.ensureVisible(_cle('pays-versement-FR'));
        await tester.tap(_cle('pays-versement-FR'));
        await tester.pumpAndSettle();
        expect(_cle('pays-versement-enregistrer'), findsNothing);
        await tester.ensureVisible(_cle('versement-compte-oui'));
        await tester.tap(_cle('versement-compte-oui'));
        await tester.pumpAndSettle();
        await tester.tap(_cle('pays-versement-enregistrer'));
        await tester.pumpAndSettle();
        expect(port.versementsModifies, hasLength(1));
        expect(port.versementsModifies.single.$1, isTrue);
        expect(port.versementsModifies.single.$2, 'FR');
        expect(port.versementsModifies.single.$3, isEmpty);
        expect(_cle('pays-versement-message'), findsOneWidget);
      },
    );
  }

  testWidgets('un refus du serveur se dit, rien n est change', (
    WidgetTester tester,
  ) async {
    final FauxMaCandidature port = FauxMaCandidature()
      ..erreurVersement = const TransitionInterdite();
    await _monter(tester, _envoyee(), port);
    await tester.ensureVisible(_cle('pays-versement-lien'));
    await tester.tap(_cle('pays-versement-lien'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_cle('pays-versement-FR'));
    await tester.tap(_cle('pays-versement-FR'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_cle('versement-compte-oui'));
    await tester.tap(_cle('versement-compte-oui'));
    await tester.pumpAndSettle();
    await tester.tap(_cle('pays-versement-enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text(t.recrutement.portail.paysVersementInterdit),
      findsOneWidget,
    );
  });

  testWidgets(
    'sans compte : le pays du mobile money puis ses services, envoyes avec le reste',
    (WidgetTester tester) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _monter(tester, _envoyee(), port);
      await tester.ensureVisible(_cle('pays-versement-lien'));
      await tester.tap(_cle('pays-versement-lien'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_cle('versement-compte-non'));
      await tester.tap(_cle('versement-compte-non'));
      await tester.pumpAndSettle();
      // Le titre du pays dit « sur votre telephone » sans compte.
      expect(
        find.text(t.recrutement.parcours.q.paysVersementMobile.titre),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'GN');
      await tester.pumpAndSettle();
      await tester.ensureVisible(_cle('pays-versement-GN'));
      await tester.tap(_cle('pays-versement-GN'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_cle('versement-service-wave'));
      await tester.tap(_cle('versement-service-wave'));
      await tester.pumpAndSettle();
      await tester.tap(_cle('pays-versement-enregistrer'));
      await tester.pumpAndSettle();
      expect(port.versementsModifies, hasLength(1));
      expect(port.versementsModifies.single.$1, isFalse);
      expect(port.versementsModifies.single.$2, 'GN');
      expect(port.versementsModifies.single.$3, <String>['wave']);
    },
  );

  testWidgets('avec un compte : aucun service n\'est propose ni envoye', (
    WidgetTester tester,
  ) async {
    final FauxMaCandidature port = FauxMaCandidature();
    await _monter(tester, _envoyee(), port);
    await tester.ensureVisible(_cle('pays-versement-lien'));
    await tester.tap(_cle('pays-versement-lien'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_cle('versement-compte-oui'));
    await tester.tap(_cle('versement-compte-oui'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'GN');
    await tester.pumpAndSettle();
    await tester.ensureVisible(_cle('pays-versement-GN'));
    await tester.tap(_cle('pays-versement-GN'));
    await tester.pumpAndSettle();
    expect(_cle('versement-service-wave'), findsNothing);
    await tester.tap(_cle('pays-versement-enregistrer'));
    await tester.pumpAndSettle();
    expect(port.versementsModifies.single.$1, isTrue);
    expect(port.versementsModifies.single.$2, 'GN');
    expect(port.versementsModifies.single.$3, isEmpty);
  });

  testWidgets(
    'dossier valide : plus de lien, une phrase et le renvoi vers la messagerie',
    (WidgetTester tester) async {
      await _monter(
        tester,
        CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.enExamen,
          version: 6,
          questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 11, 10)),
        ),
        FauxMaCandidature(),
      );
      expect(_cle('pays-versement-lien'), findsNothing);
      expect(_cle('versement-ferme'), findsOneWidget);
      expect(find.text(t.recrutement.portail.versementFerme), findsOneWidget);
      final GoRouter routeur = GoRouter.of(
        tester.element(_cle('versement-ferme-lien')),
      );
      await tester.ensureVisible(_cle('versement-ferme-lien'));
      await tester.tap(_cle('versement-ferme-lien'));
      await tester.pump();
      expect(
        routeur.routeInformationProvider.value.uri.path,
        Routes.attenteMessages,
      );
    },
  );

  testWidgets('candidature refusee : aucun lien', (WidgetTester tester) async {
    await _monter(
      tester,
      _envoyee(issue: IssueCandidature.refusee),
      FauxMaCandidature(),
    );
    expect(_cle('pays-versement-lien'), findsNothing);
  });

  testWidgets('aucune reponse envoyee : aucun lien', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const CandidatureDossier(
        existe: true,
        etape: EtapeCandidature.prequalification,
        etat: EtatCandidature.aCompleter,
        version: 1,
      ),
      FauxMaCandidature(),
    );
    expect(_cle('pays-versement-lien'), findsNothing);
  });

  // Captures R3 (sautees sans CAPTURE_DIR).
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom =
            'pays-versement-${taille.width.toInt()}-${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _envoyee(),
            FauxMaCandidature(),
            taille: taille,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'PAYS-VERSEMENT/$nom-portail');
          await tester.ensureVisible(_cle('pays-versement-lien'));
          await tester.tap(_cle('pays-versement-lien'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(_cle('versement-compte-oui'));
          await tester.tap(_cle('versement-compte-oui'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(_cle('pays-versement-FR'));
          await tester.tap(_cle('pays-versement-FR'));
          await tester.pumpAndSettle();
          await capturerVue(tester, 'PAYS-VERSEMENT/$nom-panneau');
        });
      }
    }
    // PAYS-RECHERCHE (16/11/2026) : l'application en arabe, « Ghana » tape en
    // lettres latines trouve le Ghana ; l'application en francais, « غانا » aussi.
    for (final (AppLocale langue, String frappe) in <(AppLocale, String)>[
      (AppLocale.ar, 'Ghana'),
      (AppLocale.fr, 'غانا'),
    ]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom =
            'recherche-${taille.width.toInt()}-${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _envoyee(),
            FauxMaCandidature(),
            taille: taille,
          );
          await stabiliser(tester);
          await tester.ensureVisible(_cle('pays-versement-lien'));
          await tester.tap(_cle('pays-versement-lien'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(ChoixAvecRecherche.champKey),
            frappe,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(_cle('pays-versement-GH'));
          await capturerVue(tester, 'PAYS-RECHERCHE/$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
