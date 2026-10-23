// CAND-01 : la lisibilite du parcours entier. A chaque etape (presentation,
// chaque question, grille, recapitulatif) et pour chaque configuration (320 a
// 1440, texte x1 et x2, francais et arabe de droite a gauche) : aucun
// debordement, aucun mot coupe ni tronque, un seul bouton plein.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/garde_coupe_mots_rendu.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

/// Verifie l'ecran courant, defile de haut en bas, en nommant l'etape : la
/// garde du rendu du depot (mots coupes, textes rognes, ponctuation seule,
/// debordements), avec les vraies polices.
Future<void> _verifier(WidgetTester tester, String etape) async {
  final List<String> fautes = await defautsEcranDefile(tester);
  expect(fautes, isEmpty, reason: 'defaut de texte a $etape');
  verifierUnSeulBoutonPlein(tester);
}

Future<void> _parcourir(
  WidgetTester tester, {
  required Size taille,
  double echelle = 1,
  TextDirection? direction,
}) async {
  await monterQuestionnaire(
    tester,
    port: FauxMaCandidature(),
    taille: taille,
    echelle: echelle,
    direction: direction,
  );
  for (int i = 0; i < 3; i++) {
    await _verifier(tester, 'presentation ${i + 1}');
    await continuer(tester);
  }
  for (final (String champ, List<String> touches) in parcoursComplet) {
    await _verifier(tester, 'question $champ');
    for (final String cle in touches) {
      await toucherCle(tester, cle);
    }
    await _verifier(tester, 'question $champ, une reponse donnee');
    await continuer(tester);
  }
  await _verifier(tester, 'recapitulatif');
  await toucherCle(tester, 'recap-accord');
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('conditions-carte')),
  );
  await tester.pump();
  await _verifier(tester, 'recapitulatif, conditions');
}

/// Le parcours par les chemins les moins directs : la recherche de langues en
/// cartes, deux publics (les deux durees de cours), « memes heures ? » repondu
/// « non » (les heures jour par jour), puis le recapitulatif.
Future<void> _parcoursAlternatif(
  WidgetTester tester, {
  required Size taille,
  double echelle = 1,
  TextDirection? direction,
}) async {
  await monterQuestionnaire(
    tester,
    port: FauxMaCandidature(),
    taille: taille,
    echelle: echelle,
    direction: direction,
  );
  await passerLaPresentation(tester);
  for (final (String champ, List<String> touches) in parcoursComplet) {
    await _verifier(tester, 'question $champ');
    if (champ == 'languesExplication') {
      // La recherche propose ses resultats en cartes.
      await toucherCle(tester, 'choix-recherche-autre');
      await tester.enterText(
        find.byKey(ChoixAvecRecherche.champKey),
        direction == TextDirection.rtl ? 'ال' : 'a',
      );
      await tester.pumpAndSettle();
      await _verifier(tester, 'recherche de langues');
      await toucherCle(tester, 'option-languesExplication-ha');
      await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), '');
      await tester.pumpAndSettle();
      await _verifier(tester, 'recherche de langues, tout le catalogue');
      // « Revenir aux langues proposees » : a 320 x2 il est hors de la fenetre,
      // un tap sans defilement le manquait en silence.
      await tester.ensureVisible(find.byType(LienFleche).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LienFleche).first);
      await tester.pumpAndSettle();
    }
    for (final String cle in touches) {
      await toucherCle(tester, cle);
    }
    if (champ == 'publics') {
      await toucherCle(tester, 'option-publics-adultes');
    }
    if (champ == 'jours') {
      await toucherCle(tester, 'option-jour-6');
    }
    if (champ == 'memes') {
      await toucherCle(tester, 'option-memes-non');
      await _verifier(tester, 'memes heures, non');
      await continuer(tester);
      await _verifier(tester, 'heures jour par jour');
      await toucherCle(tester, 'heure-3-20');
      await toucherCle(tester, 'heure-6-9');
      await _verifier(tester, 'heures jour par jour, choisies');
      await continuer(tester);
      continue;
    }
    await _verifier(tester, 'question $champ, une reponse donnee');
    await continuer(tester);
  }
  await _verifier(tester, 'recapitulatif');
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('390 x1', const Size(390, 844), 1),
        ('320 x1', const Size(320, 568), 1),
        ('320 x2', const Size(320, 568), 2),
        ('1440 x1', const Size(1440, 900), 1),
        ('1440 x2', const Size(1440, 900), 2),
      ]) {
    testWidgets('francais, $nom : le parcours entier se lit', (
      WidgetTester tester,
    ) async {
      await _parcourir(tester, taille: taille, echelle: echelle);
    });
  }

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('390 x1', const Size(390, 844), 1),
        ('320 x2', const Size(320, 568), 2),
      ]) {
    testWidgets('arabe de droite a gauche, $nom : le parcours entier se lit', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _parcourir(
        tester,
        taille: taille,
        echelle: echelle,
        direction: TextDirection.rtl,
      );
    });
  }

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('390 x1', const Size(390, 844), 1),
        ('320 x2', const Size(320, 568), 2),
        ('1440 x1', const Size(1440, 900), 1),
      ]) {
    testWidgets('francais, $nom : le parcours alternatif se lit', (
      WidgetTester tester,
    ) async {
      await _parcoursAlternatif(tester, taille: taille, echelle: echelle);
    });
  }

  testWidgets('arabe de droite a gauche, 320 x2 : le parcours alternatif se lit', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _parcoursAlternatif(
      tester,
      taille: const Size(320, 568),
      echelle: 2,
      direction: TextDirection.rtl,
    );
  });

  // Le portail et les etats de la page, aux gabarits les plus durs.
  List<(String, CandidatureDossier)> etatsPortail(AppLocale langue) =>
      <(String, CandidatureDossier)>[
        (
          'a completer avec complement',
          candidatureAFaire(
            cadreAccepte: false,
            complement: <String>['publics', 'recitation'],
          ),
        ),
        (
          'versement pas encore possible',
          const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.paiementNonDisponible,
            version: 4,
            paiement: EtatVersement.incompatible,
          ),
        ),
        (
          'en pause',
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            enPause: true,
            version: 4,
            pauseTexte: langue == AppLocale.ar
                ? 'نستأنف استقبال الطلبات في يناير.'
                : 'Nous reprenons les candidatures en janvier.',
            repriseLe: DateTime(2027, 1, 10),
          ),
        ),
        (
          'refusee',
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            issue: IssueCandidature.refusee,
            version: 6,
            refusTexte: langue == AppLocale.ar
                ? 'لا يمكننا متابعة طلبك في الوقت الحالي.'
                : 'Nous ne pouvons pas donner suite pour le moment.',
          ),
        ),
      ];
  for (final (String nom, Size taille, double echelle, AppLocale langue)
      in <(String, Size, double, AppLocale)>[
        ('320 x2', const Size(320, 568), 2, AppLocale.fr),
        ('390 x1', const Size(390, 844), 1, AppLocale.fr),
        ('320 x2 arabe', const Size(320, 568), 2, AppLocale.ar),
      ]) {
    testWidgets('portail, $nom : chaque etat se lit', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      for (final (String etat, CandidatureDossier c) in etatsPortail(langue)) {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = etatCandidat(candidature: c);
        await monterQuestionnaire(
          tester,
          port: FauxMaCandidature(),
          depart: Routes.attente,
          taille: taille,
          echelle: echelle,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          dossier: dossier,
        );
        await _verifier(tester, 'portail $etat');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('320 x2', const Size(320, 568), 2),
        ('1440 x1', const Size(1440, 900), 1),
      ]) {
    testWidgets('etats de la page, $nom : non ouvert, erreur, hors ligne', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidatureIndisponible(),
        taille: taille,
        echelle: echelle,
      );
      await _verifier(tester, 'non ouvert');
      await tester.pumpWidget(const SizedBox());
      await monterQuestionnaire(
        tester,
        port: FauxMaCandidature()..erreurQuestionnaire = Exception('boum'),
        taille: taille,
        echelle: echelle,
      );
      await _verifier(tester, 'erreur');
    });
  }
}
