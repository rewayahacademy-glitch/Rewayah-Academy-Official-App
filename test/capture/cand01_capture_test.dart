// Captures de CAND-01 (parcours du candidat dans la Salle d'examen) : un ecran
// de presentation, une question a cartes, le fuseau confirme par une carte, la
// grille des disponibilites, le recapitulatif avec les conditions de
// remuneration, puis les etats (non ouvert, erreur, hors ligne) et le portail.
// 390x844 et 1440x900, clair ; le sombre ; l'arabe de droite a gauche.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Monte la page sous le vrai theme, dans le cadre de capture.
Future<void> _monter(
  WidgetTester tester, {
  required FauxMaCandidature port,
  Size taille = _telephone,
  ThemeMode mode = ThemeMode.light,
  String depart = Routes.attenteCandidature,
  CandidatureDossier? candidature,
  bool horsLigne = false,
  FauxServiceDossier? dossier,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesCandidature(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesCandidature(
        port: port,
        etat: etatCandidat(candidature: candidature ?? candidatureAFaire()),
        dossier: dossier,
        horsLigne: horsLigne,
      ),
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
  await tester.pumpAndSettle();
}

/// Remonte toutes les listes verticales en haut : `ensureVisible` d'un geste
/// precedent les a fait defiler, et la capture doit montrer le titre.
Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

/// Capture le haut de la page.
Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  await capturer(tester, 'CAND-01/$nom');
}

/// Fait defiler jusqu'au widget de cle [cle] (sans le toucher), puis capture.
Future<void> _photoSur(WidgetTester tester, String cle, String nom) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  // Le widget en haut de la fenetre, pas au ras du pied.
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await tester.pump();
  await capturer(tester, 'CAND-01/$nom');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CAND-01 : captures', skip: sautSansCapture, () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      testWidgets('presentation $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await _photo(tester, 'presentation-1_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'presentation-2_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'presentation-3_${nom}_clair');
      });

      testWidgets('question a cartes $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 2);
        await _photo(tester, 'question-memorisation_${nom}_clair');
        await toucherCle(
          tester,
          'option-niveauMemorisationDeclare-ijaza_lecture_enseignement',
        );
        await _photo(tester, 'question-memorisation-choix_${nom}_clair');
      });

      testWidgets('langues et recherche $nom clair', (
        WidgetTester tester,
      ) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await passerLaPresentation(tester);
        await _photo(tester, 'langues_${nom}_clair');
        await toucherCle(tester, 'choix-recherche-autre');
        await _photo(tester, 'langues-recherche_${nom}_clair');
      });

      testWidgets('fuseau $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 7);
        await _photo(tester, 'fuseau_${nom}_clair');
        await toucherCle(tester, 'fuseau-changer');
        await _photo(tester, 'fuseau-villes_${nom}_clair');
      });

      testWidgets('grille $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 8);
        await toucherCle(tester, 'creneau-1-4');
        await toucherCle(tester, 'creneau-1-5');
        await toucherCle(tester, 'creneau-3-4');
        await _photo(tester, 'grille_${nom}_clair');
      });

      testWidgets('versement $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 15);
        await _photo(tester, 'operateurs_${nom}_clair');
      });

      testWidgets('recapitulatif $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, parcoursComplet.length);
        await _photo(tester, 'recapitulatif-haut_${nom}_clair');
        await toucherCle(tester, 'recap-accord');
        await _photoSur(
          tester,
          'conditions-carte',
          'recapitulatif-conditions_${nom}_clair',
        );
      });

      testWidgets('portail $nom clair', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          depart: Routes.attente,
        );
        await _photo(tester, 'portail-a-completer_${nom}_clair');
      });
    }

    // Le sombre : une capture par ecran cle, aux deux largeurs pour le
    // recapitulatif.
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      testWidgets('sombre $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          mode: ThemeMode.dark,
        );
        await _photo(tester, 'presentation-1_${nom}_sombre');
        await passerLaPresentation(tester);
        await toucherCle(tester, 'option-langueMaternelle-poular');
        await _photo(tester, 'question-langue_${nom}_sombre');
        await continuer(tester);
        await toucherCle(tester, 'option-languesExplication-poular');
        await continuer(tester);
        await _photo(tester, 'question-memorisation_${nom}_sombre');
      });

      testWidgets('sombre grille et recapitulatif $nom', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          mode: ThemeMode.dark,
        );
        await repondreJusqua(tester, 8);
        await toucherCle(tester, 'creneau-1-4');
        await toucherCle(tester, 'creneau-3-4');
        await _photo(tester, 'grille_${nom}_sombre');
        await continuer(tester);
        await repondreJusqua2(tester, 9);
        await toucherCle(tester, 'recap-accord');
        await _photoSur(
          tester,
          'conditions-carte',
          'recapitulatif-conditions_${nom}_sombre',
        );
      });
    }

    testWidgets('texte agrandi 320 x2', (WidgetTester tester) async {
      await _monter(
        tester,
        port: FauxMaCandidature(),
        taille: const Size(320, 568),
        echelle: 2,
      );
      await repondreJusqua(tester, 8);
      await toucherCle(tester, 'creneau-1-4');
      await _photo(tester, 'grille_320_x2_clair');
      await continuer(tester);
      await repondreJusqua2(tester, 9);
      await toucherCle(tester, 'recap-accord');
      await _photoSur(
        tester,
        'conditions-carte',
        'recapitulatif-conditions_320_x2_clair',
      );
    });

    testWidgets('etat non ouvert', (WidgetTester tester) async {
      await _monter(tester, port: FauxMaCandidatureIndisponible());
      await _photo(tester, 'etat-non-ouvert_390_clair');
    });

    testWidgets('etat erreur', (WidgetTester tester) async {
      final FauxMaCandidature casse = FauxMaCandidature()
        ..erreurQuestionnaire = Exception('boum');
      await _monter(tester, port: casse);
      await _photo(tester, 'etat-erreur_390_clair');
    });

    testWidgets('etat hors ligne', (WidgetTester tester) async {
      await _monter(tester, port: FauxMaCandidature(), horsLigne: true);
      await repondreJusqua(tester, parcoursComplet.length);
      await _photo(tester, 'etat-hors-ligne-recapitulatif_390_clair');
    });

    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      testWidgets('portail en examen $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          depart: Routes.attente,
          candidature: CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            version: 4,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
        );
        await _photo(tester, 'portail-en-examen_${nom}_clair');
      });

      testWidgets('portail versement pas encore possible $nom', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          depart: Routes.attente,
          candidature: CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.paiementNonDisponible,
            version: 4,
            paiement: EtatVersement.incompatible,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
        );
        await _photo(tester, 'portail-versement-impossible_${nom}_clair');
      });

      testWidgets('cartes decrites $nom', (WidgetTester tester) async {
        // Chaque carte dit ce qu'elle est, ce qu'elle entraine, un exemple.
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 3);
        await toucherCle(tester, 'option-niveauLectureTajwid-tajwid_enseigne');
        await _photo(tester, 'question-tajwid_${nom}_clair');
      });

      testWidgets('cartes decrites, heures et debut $nom', (
        WidgetTester tester,
      ) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, 9);
        await toucherCle(tester, 'option-heuresParSemaine-de_3_a_5');
        await _photo(tester, 'question-heures_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'question-debut_${nom}_clair');
      });
    }

    testWidgets('arabe de droite a gauche', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature());
      await _photo(tester, 'ar_presentation-1_390');
      await passerLaPresentation(tester);
      await _photo(tester, 'ar_question-langue_390');
      await toucherCle(tester, 'option-langueMaternelle-poular');
      await continuer(tester);
      await toucherCle(tester, 'option-languesExplication-poular');
      await continuer(tester);
      await _photo(tester, 'ar_question-memorisation_390');
    });

    testWidgets('arabe : grille et recapitulatif', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, 8);
      await toucherCle(tester, 'creneau-1-4');
      await toucherCle(tester, 'creneau-3-4');
      await _photo(tester, 'ar_grille_390');
      await continuer(tester);
      await repondreJusqua2(tester, 9);
      await _photo(tester, 'ar_recapitulatif-haut_390');
      await toucherCle(tester, 'recap-accord');
      await _photoSur(
        tester,
        'conditions-carte',
        'ar_recapitulatif-conditions_390',
      );
    });
  });
}

/// Poursuit le parcours complet apres la huitieme question (grille).
Future<void> repondreJusqua2(WidgetTester tester, int depuis) async {
  for (final (String _, List<String> touches) in parcoursComplet.skip(depuis)) {
    for (final String cle in touches) {
      await toucherCle(tester, cle);
    }
    await continuer(tester);
  }
}
