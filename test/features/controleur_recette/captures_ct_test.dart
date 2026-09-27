// CT-1b : squelette des captures de la vague Controleur. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Chaque lot CT-2 a CT-11
// ajoute ses ecrans ici ; CT-12 en fait la recette.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/compte/espaces_compte.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/espaces_controleur_demo.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(ecran, themeMode: mode));
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Heberge [route] sur la VRAIE route de demonstration
/// (`routesDemoControleur`) : la salle (CTR-02) et le compte rendu (CTR-03)
/// lisent le routeur (Quitter, retour), un `home:` nu ne suffit pas.
Future<void> _capturerRoute(
  WidgetTester tester,
  String fichier,
  String route,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: route,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext contexte) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(contexte).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
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

void main() {
  group('Capture : CT-1b, coquille controleur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // La VRAIE coquille (4 destinations, C13) sur chaque destination, aux
    // trois largeurs de reference, clair et sombre.
    for (final EcranDemoControleur ecran in EcranDemoControleur.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 900)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'ct1b_coquille_${ecran.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleControleurDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });

  group('Capture : CT-2, CTR-01 Controle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Les quatre situations de mission, sur la VRAIE coquille.
    for (final EtatDemoControleur etat in EtatDemoControleur.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'ct2_controle_${etat.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleControleurDemo(
                ecran: EcranDemoControleur.controle,
                etat: etat,
              ),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });

  group(
    'Capture : CT-3, CTR-02 salle et compte rendu',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      // La salle (CTR-02, `SalleControleurDemo(seanceId: 'demo-controle')`) et
      // le compte rendu provisoire (CTR-03), tous deux atteints par la VRAIE
      // route de demonstration `/demo/controleur/salle` et
      // `/demo/controleur/compte-rendu`.
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String s = '${l}_${mode.name}';
          testWidgets('ct3_salle_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct3_salle_$s',
              cheminDemoSalleControleur,
              taille,
              mode: mode,
            );
          });
          testWidgets('ct3_compte_rendu_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct3_compte_rendu_$s',
              cheminDemoCompteRenduControleur,
              taille,
              mode: mode,
            );
          });
        }
      }
    },
  );

  group('Capture : CT-4, CTR-03 compte rendu', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Trois etats par la VRAIE route `/demo/controleur/compte-rendu` :
    // initial (faits replies, aucune preselection), « Rien a signaler »
    // choisi (faits deplies, notice, bouton), resultat apres envoi.
    Future<void> choisir(WidgetTester tester) async {
      await tester.tap(find.text(t.controleur.compteRendu.faits));
      await tester.pumpAndSettle();
      final Finder carte = find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      );
      await tester.ensureVisible(carte);
      await tester.tap(carte);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pumpAndSettle();
    }

    Future<void> envoyer(WidgetTester tester) async {
      await choisir(tester);
      await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s = '${l}_${mode.name}';
        for (final (String nom, Future<void> Function(WidgetTester)? avant)
            in <(String, Future<void> Function(WidgetTester)?)>[
              ('initial', null),
              ('rien_a_signaler', choisir),
              ('resultat', envoyer),
            ]) {
          testWidgets('ct4_compte_rendu_${nom}_$s', (
            WidgetTester tester,
          ) async {
            await _capturerRoute(
              tester,
              'ct4_compte_rendu_${nom}_$s',
              cheminDemoCompteRenduControleur,
              taille,
              mode: mode,
              avant: avant,
            );
          });
        }
      }
    }
  });

  group('Capture : CT-5, CTR-03A observation', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Quatre etats par la VRAIE route `/demo/controleur/compte-rendu/
    // observation` : nature, personne avec le roster, texte requis,
    // recapitulatif avec la notice.
    Future<void> toucher(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    Future<void> continuer(WidgetTester tester) =>
        toucher(tester, find.text(t.commun.continuer).last);

    Future<void> nature(WidgetTester tester) => toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.interventionAdmin),
      ),
    );

    Future<void> personne(WidgetTester tester) async {
      await nature(tester);
      await continuer(tester);
      await toucher(
        tester,
        find.byKey(
          ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
        ),
      );
      await continuer(tester);
      await toucher(
        tester,
        find.byKey(
          ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
        ),
      );
      await toucher(
        tester,
        find.byKey(ObservationControlePage.cleEleve('demo-eleve-0')),
      );
    }

    Future<void> texte(WidgetTester tester) async {
      await personne(tester);
      await continuer(tester);
      await continuer(tester);
    }

    Future<void> recapitulatif(WidgetTester tester) async {
      await texte(tester);
      await tester.enterText(
        find.byKey(ObservationControlePage.texteKey),
        "L'élève n'a pas eu la parole pendant la récitation.",
      );
      await tester.pumpAndSettle();
      await continuer(tester);
    }

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s = '${l}_${mode.name}';
        for (final (String nom, Future<void> Function(WidgetTester) avant)
            in <(String, Future<void> Function(WidgetTester))>[
              ('nature', nature),
              ('personne', personne),
              ('texte_requis', texte),
              ('recapitulatif', recapitulatif),
            ]) {
          testWidgets('ct5_observation_${nom}_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct5_observation_${nom}_$s',
              cheminDemoObservationControleur,
              taille,
              mode: mode,
              avant: avant,
            );
          });
        }
      }
    }
  });

  group('Capture : CT-6, CTR-04 Echanges', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Le port de demonstration repond en 400 ms.
    Future<void> reponse(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    // La liste ; le fil Al-Badr ; le fil de la mission ouvert depuis
    // « Ecrire a l'administration », un message envoye.
    Future<void> envoye(WidgetTester tester) async {
      await reponse(tester);
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Une question sur cette visite.',
      );
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await reponse(tester);
    }

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s = '${l}_${mode.name}';
        for (final (
              String nom,
              String route,
              Future<void> Function(WidgetTester) avant,
            )
            in <(String, String, Future<void> Function(WidgetTester))>[
              (
                'liste',
                adresseDemoControleur(EcranDemoControleur.echanges),
                reponse,
              ),
              (
                'fil',
                adresseDemoControleur(
                  EcranDemoControleur.echanges,
                  fil: 'demo-mission-al-badr-0924',
                ),
                reponse,
              ),
              ('fil_envoye', adresseFilMissionDemoControleur(), envoye),
            ]) {
          testWidgets('ct6_echanges_${nom}_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct6_echanges_${nom}_$s',
              route,
              taille,
              mode: mode,
              avant: avant,
            );
          });
        }
      }
    }
  });
  group(
    'Capture : CT-9, espaces et etats transverses',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      const SituationEspacesDemo enseignant = SituationEspacesDemo(
        profil: ProfilDemoControleur.enseignant,
      );
      Future<void> rien(WidgetTester tester) async {}
      Future<void> feuille(WidgetTester tester) async {
        await tester.tap(find.byKey(RaccourciEspaces.cle));
        await tester.pumpAndSettle();
      }

      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String s = '${l}_${mode.name}';
          for (final (
                String nom,
                String route,
                Future<void> Function(WidgetTester) avant,
              )
              in <(String, String, Future<void> Function(WidgetTester))>[
                (
                  'controle_raccourci',
                  adresseDemoControleur(
                    EcranDemoControleur.controle,
                    espaces: enseignant,
                  ),
                  rien,
                ),
                (
                  'feuille_espaces',
                  adresseDemoControleur(
                    EcranDemoControleur.controle,
                    espaces: enseignant,
                  ),
                  feuille,
                ),
                (
                  'compte_mission_en_cours',
                  adresseDemoControleur(
                    EcranDemoControleur.compte,
                    espaces: enseignant.enMission(),
                  ),
                  rien,
                ),
                (
                  'acces_revoque',
                  adresseDemoControleur(
                    EcranDemoControleur.historique,
                    espaces: const SituationEspacesDemo(
                      profil: ProfilDemoControleur.enseignant,
                      acces: AccesDemoControleur.revoque,
                    ),
                  ),
                  rien,
                ),
                (
                  'compte_rendu_indisponible',
                  Uri(
                    path: cheminDemoCompteRenduControleur,
                    queryParameters: <String, String>{
                      'etat': EtatDemoControleur.indisponible.name,
                    },
                  ).toString(),
                  rien,
                ),
              ]) {
            testWidgets('ct9_${nom}_$s', (WidgetTester tester) async {
              await _capturerRoute(
                tester,
                'ct9_${nom}_$s',
                route,
                taille,
                mode: mode,
                avant: avant,
              );
            });
          }
        }
      }
    },
  );
}
