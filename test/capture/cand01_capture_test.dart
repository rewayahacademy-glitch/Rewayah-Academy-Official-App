// Captures de CAND-01 (parcours du candidat dans la Salle d'examen), reprise du
// 22/10/2026 sur les reponses du directeur : les langues (cartes du public,
// recherche en cartes), la memorisation et l'ijaza, les tranches d'age, les
// disponibilites heure par heure (jours, heures de debut, memes heures ?, jour
// par jour, semaine), le nombre de Classes, les moyens de paiement connus, le
// recapitulatif avec la clause de continuite, puis les etats (non ouvert,
// erreur, hors ligne). 390x844 et 1440x900, clair ; le sombre ; l'arabe de
// droite a gauche.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';

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
  bool attendre = true,
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
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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
  await capturer(tester, nom);
}

/// Fait defiler jusqu'au widget de cle [cle] (sans le toucher), puis capture.
Future<void> _photoSur(WidgetTester tester, String cle, String nom) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  // Le widget en haut de la fenetre, pas au ras du pied.
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await tester.pump();
  await capturer(tester, nom);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  /// Des reponses completes avec ces publics, pour ouvrir le recapitulatif.
  FauxMaCandidature avecPublics(List<String> publics) => FauxMaCandidature(
    questionnaireJson: questionnaireJsonDeTest(
      dernieresReponses: <String, Object?>{
        ...reponsesCompletesDeTest(),
        'publics': publics,
      },
    ),
  );

  group('CAND-01 : captures du questionnaire corrige', skip: sautSansCapture, () {
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

      testWidgets('langues $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await passerLaPresentation(tester);
        await _photo(tester, 'langue-maternelle_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'langues-de-cours_${nom}_clair');
        await toucherCle(tester, 'option-languesExplication-poular');
        await toucherCle(tester, 'option-languesExplication-sw');
        await toucherCle(tester, 'option-languesExplication-wo');
        await _photo(tester, 'langues-de-cours-choix_${nom}_clair');
        await toucherCle(tester, 'choix-recherche-autre');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'peul');
        await tester.pumpAndSettle();
        await _photo(tester, 'langues-recherche-peul_${nom}_clair');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'ou');
        await tester.pumpAndSettle();
        await _photo(tester, 'langues-recherche-ou_${nom}_clair');
        await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'zzzz');
        await tester.pumpAndSettle();
        await _photo(tester, 'langues-recherche-vide_${nom}_clair');
      });

      testWidgets('memorisation $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'niveauMemorisationDeclare');
        await _photo(tester, 'memorisation_${nom}_clair');
        // Une carte visible dans la fenetre : le choix se voit sur la capture.
        await toucherCle(
          tester,
          'option-niveauMemorisationDeclare-moins_10_juz',
        );
        await _photo(tester, 'memorisation-choix_${nom}_clair');
      });

      testWidgets('ijaza $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'ijazaPresentable');
        await _photo(tester, 'ijaza_${nom}_clair');
        await toucherCle(tester, 'option-ijazaPresentable-pret_test');
        await _photo(tester, 'ijaza-pret-test_${nom}_clair');
      });

      testWidgets('publics $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'publics');
        await _photo(tester, 'publics_${nom}_clair');
        await toucherCle(tester, 'option-publics-6_9');
        await toucherCle(tester, 'option-publics-adultes');
        await _photo(tester, 'publics-choix_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'fuseau_${nom}_clair');
      });

      testWidgets('disponibilites $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'jours');
        await _photo(tester, 'jours_${nom}_clair');
        await toucherCle(tester, 'dispo-raccourci-lmv');
        await _photo(tester, 'jours-raccourci_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'heures-vide_${nom}_clair');
        await toucherCle(tester, 'heure-1-18');
        await toucherCle(tester, 'heure-1-19');
        await toucherCle(tester, 'heure-1-20');
        await _photo(tester, 'heures_${nom}_clair');
        await continuer(tester);
        await _photo(tester, 'memes-heures_${nom}_clair');
        await toucherCle(tester, 'option-memes-oui');
        await continuer(tester);
        await _photo(tester, 'semaine_${nom}_clair');
      });

      testWidgets('disponibilites jour par jour $nom clair', (
        WidgetTester tester,
      ) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'jours');
        await toucherCle(tester, 'dispo-raccourci-lmv');
        await continuer(tester);
        await toucherCle(tester, 'heure-1-18');
        await continuer(tester);
        await toucherCle(tester, 'option-memes-non');
        await continuer(tester);
        await toucherCle(tester, 'heure-3-20');
        await toucherCle(tester, 'heure-5-9');
        await _photo(tester, 'jour-par-jour_${nom}_clair');
        await toucherCle(tester, 'heure-5-18');
        await toucherCle(tester, 'heure-5-9');
        await continuer(tester);
        await _photo(tester, 'jour-par-jour-manque_${nom}_clair');
      });

      testWidgets('heures pour des adultes $nom clair', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: avecPublics(<String>['adultes']),
          taille: taille,
        );
        await toucherCle(tester, 'recap-disponibilitesDeclarees');
        await continuer(tester);
        await _photo(tester, 'heures-adultes_${nom}_clair');
        await continuer(tester);
        await continuer(tester);
        await _photo(tester, 'semaine-adultes_${nom}_clair');
      });

      testWidgets('nombre de Classes $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'classesSouhaitees');
        await toucherCle(tester, 'option-classesSouhaitees-2');
        await _photo(tester, 'classes-enfants_${nom}_clair');
      });

      testWidgets('nombre de Classes, les deux publics $nom clair', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: avecPublics(<String>['10_13', 'adultes']),
          taille: taille,
        );
        await toucherCle(tester, 'recap-classesSouhaitees');
        await _photo(tester, 'classes-deux-publics_${nom}_clair');
      });

      testWidgets('moyens de paiement connus $nom clair', (
        WidgetTester tester,
      ) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreAvant(tester, 'moyensAccessibles');
        await _photo(tester, 'moyens-paiement_${nom}_clair');
        await toucherCle(tester, 'option-moyensAccessibles-orange_money');
        await _photo(tester, 'moyens-paiement-choix_${nom}_clair');
      });

      testWidgets('recapitulatif $nom clair', (WidgetTester tester) async {
        await _monter(tester, port: FauxMaCandidature(), taille: taille);
        await repondreJusqua(tester, parcoursComplet.length);
        await _photo(tester, 'recapitulatif-haut_${nom}_clair');
        await _photoSur(
          tester,
          'recap-disponibilitesDeclarees',
          'recapitulatif-disponibilites_${nom}_clair',
        );
        await toucherCle(tester, 'recap-accord');
        await _photoSur(
          tester,
          'conditions-carte',
          'recapitulatif-conditions_${nom}_clair',
        );
      });
    }

    // Le sombre : les ecrans neufs, aux deux largeurs.
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
        await repondreAvant(tester, 'publics');
        await toucherCle(tester, 'option-publics-10_13');
        await _photo(tester, 'publics_${nom}_sombre');
        await continuer(tester);
        await toucherCle(tester, 'fuseau-oui');
        await continuer(tester);
        await toucherCle(tester, 'dispo-raccourci-mjs');
        await _photo(tester, 'jours_${nom}_sombre');
        await continuer(tester);
        await toucherCle(tester, 'heure-2-18');
        await toucherCle(tester, 'heure-2-19');
        await _photo(tester, 'heures_${nom}_sombre');
        await continuer(tester);
        await toucherCle(tester, 'option-memes-oui');
        await continuer(tester);
        await _photo(tester, 'semaine_${nom}_sombre');
        await continuer(tester);
        await toucherCle(tester, 'option-classesSouhaitees-3');
        await _photo(tester, 'classes_${nom}_sombre');
      });

      testWidgets('sombre recapitulatif $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          port: FauxMaCandidature(),
          taille: taille,
          mode: ThemeMode.dark,
        );
        await repondreJusqua(tester, parcoursComplet.length);
        await toucherCle(tester, 'recap-accord');
        await _photoSur(
          tester,
          'conditions-carte',
          'recapitulatif-conditions_${nom}_sombre',
        );
      });
    }

    // Les ecrans entiers, sans que la barre du bas en coupe le pied : une
    // fenetre tres haute, pour relire chaque carte de bout en bout.
    const Size haute = Size(390, 2600);
    testWidgets('pleine hauteur : langues de cours', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await passerLaPresentation(tester);
      await continuer(tester);
      await toucherCle(tester, 'option-languesExplication-poular');
      await toucherCle(tester, 'option-languesExplication-francais');
      await _photo(tester, 'haute_langues-de-cours');
    });

    testWidgets('pleine hauteur : publics', (WidgetTester tester) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreAvant(tester, 'publics');
      await toucherCle(tester, 'option-publics-14_17');
      await _photo(tester, 'haute_publics');
    });

    testWidgets('pleine hauteur : memorisation et ijaza', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreAvant(tester, 'niveauMemorisationDeclare');
      await _photo(tester, 'haute_memorisation');
      await toucherCle(
        tester,
        'option-niveauMemorisationDeclare-de_10_a_29_juz',
      );
      await continuer(tester);
      await toucherCle(tester, 'option-niveauLectureTajwid-tajwid_applique');
      await continuer(tester);
      await toucherCle(tester, 'option-riwayat-hafs');
      await continuer(tester);
      await toucherCle(tester, 'option-ijazaPresentable-oui');
      await _photo(tester, 'haute_ijaza');
    });

    testWidgets('pleine hauteur : disponibilites', (WidgetTester tester) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreAvant(tester, 'jours');
      await toucherCle(tester, 'dispo-raccourci-lmv');
      await _photo(tester, 'haute_jours');
      await continuer(tester);
      await toucherCle(tester, 'heure-1-18');
      await toucherCle(tester, 'heure-1-19');
      await _photo(tester, 'haute_heures-enfants');
      await continuer(tester);
      await toucherCle(tester, 'option-memes-non');
      await continuer(tester);
      await _photo(tester, 'haute_jour-par-jour');
    });

    testWidgets('pleine hauteur : heures des adultes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: avecPublics(<String>['adultes']),
        taille: haute,
      );
      await toucherCle(tester, 'recap-disponibilitesDeclarees');
      await continuer(tester);
      await _photo(tester, 'haute_heures-adultes');
      await continuer(tester);
      await continuer(tester);
      await _photo(tester, 'haute_semaine-adultes');
    });

    testWidgets('pleine hauteur : les deux publics', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: avecPublics(<String>['10_13', 'adultes']),
        taille: haute,
      );
      await toucherCle(tester, 'recap-disponibilitesDeclarees');
      await continuer(tester);
      await _photo(tester, 'haute_heures-deux-publics');
    });

    testWidgets('pleine hauteur : classes et moyens', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreAvant(tester, 'classesSouhaitees');
      await toucherCle(tester, 'option-classesSouhaitees-2');
      await _photo(tester, 'haute_classes');
      await continuer(tester);
      await toucherCle(tester, 'option-debutPossible-mois_prochain');
      await continuer(tester);
      await toucherCle(tester, 'option-paysResidence-GN');
      await continuer(tester);
      await continuer(tester);
      await toucherCle(tester, 'option-compteBancaire-non');
      await continuer(tester);
      await toucherCle(tester, 'option-operateurs-orange_money');
      await continuer(tester);
      await _photo(tester, 'haute_moyens-paiement');
    });

    testWidgets('pleine hauteur : recapitulatif', (WidgetTester tester) async {
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreJusqua(tester, parcoursComplet.length);
      await _photo(tester, 'haute_recapitulatif');
    });

    testWidgets('pleine hauteur arabe : langues, publics, classes', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature(), taille: haute);
      await repondreAvant(tester, 'publics');
      await toucherCle(tester, 'option-publics-adultes');
      await _photo(tester, 'ar_haute_publics');
      await continuer(tester);
      await toucherCle(tester, 'fuseau-oui');
      await continuer(tester);
      await toucherCle(tester, 'dispo-raccourci-lmv');
      await continuer(tester);
      await toucherCle(tester, 'heure-1-18');
      await toucherCle(tester, 'heure-1-19');
      await _photo(tester, 'ar_haute_heures-adultes');
      await continuer(tester);
      await _photo(tester, 'ar_haute_memes-heures-vide');
      await toucherCle(tester, 'option-memes-oui');
      await continuer(tester);
      await _photo(tester, 'ar_haute_semaine');
      await continuer(tester);
      await _photo(tester, 'ar_haute_classes');
    });

    testWidgets('texte agrandi 320 x2', (WidgetTester tester) async {
      await _monter(
        tester,
        port: FauxMaCandidature(),
        taille: const Size(320, 568),
        echelle: 2,
      );
      await repondreAvant(tester, 'jours');
      await toucherCle(tester, 'dispo-raccourci-lmv');
      await _photo(tester, 'jours_320_x2_clair');
      await continuer(tester);
      await toucherCle(tester, 'heure-1-18');
      await _photo(tester, 'heures_320_x2_clair');
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

    testWidgets('etat chargement', (WidgetTester tester) async {
      final _Lent port = _Lent();
      await _monter(tester, port: port, attendre: false);
      await tester.pump(const Duration(milliseconds: 400));
      await _photo(tester, 'etat-chargement_390_clair');
      port.libere.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('etat refus du serveur sur les disponibilites', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = const ReponsesInvalides(
          <String>['disponibilitesDeclarees'],
          motifs: <String, String>{
            'disponibilitesDeclarees': 'plages_qui_se_chevauchent',
          },
        );
      await _monter(tester, port: port);
      await repondreJusqua(tester, parcoursComplet.length);
      await toucherCle(tester, 'recap-accord');
      await continuer(tester);
      await _photo(tester, 'etat-refus-disponibilites_390_clair');
    });

    // L'arabe, de droite a gauche : les ecrans neufs.
    testWidgets('arabe de droite a gauche', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature());
      await passerLaPresentation(tester);
      await _photo(tester, 'ar_langue-maternelle_390');
      await continuer(tester);
      await toucherCle(tester, 'option-languesExplication-poular');
      await _photo(tester, 'ar_langues-de-cours_390');
      await continuer(tester);
      await _photo(tester, 'ar_memorisation_390');
    });

    testWidgets('arabe : publics et disponibilites', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature());
      await repondreAvant(tester, 'publics');
      await _photo(tester, 'ar_publics_390');
      await toucherCle(tester, 'option-publics-adultes');
      await continuer(tester);
      await toucherCle(tester, 'fuseau-oui');
      await continuer(tester);
      await toucherCle(tester, 'dispo-raccourci-lmv');
      await _photo(tester, 'ar_jours_390');
      await continuer(tester);
      await toucherCle(tester, 'heure-1-18');
      await _photo(tester, 'ar_heures-adultes_390');
      await continuer(tester);
      await toucherCle(tester, 'option-memes-oui');
      await _photo(tester, 'ar_memes-heures_390');
      await continuer(tester);
      await _photo(tester, 'ar_semaine_390');
      await continuer(tester);
      await _photo(tester, 'ar_classes_390');
    });

    testWidgets('arabe : recapitulatif et conditions', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, port: FauxMaCandidature());
      await repondreJusqua(tester, parcoursComplet.length);
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

/// Un double dont la lecture du questionnaire attend qu'on la libere.
class _Lent extends FauxMaCandidature {
  final Completer<void> libere = Completer<void>();

  @override
  Future<Questionnaire> questionnaire() async {
    await libere.future;
    return super.questionnaire();
  }
}
