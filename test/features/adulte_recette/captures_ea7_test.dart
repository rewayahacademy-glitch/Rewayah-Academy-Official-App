// EA-7 : les captures de l'invitation recue par le second adulte, depuis la
// VRAIE route /demo/adulte (`adresseDemoAdulte`, `vue=conjoint`), comme
// `captures_ea6_test.dart` : 390x844, 768x1024 et 1440x900, clair et sombre,
// plus le texte a 200 % en 390, sur les notifications, l'etape 1 (« a
// repondre ») et ses deux reponses (la page defilee jusqu'aux boutons) ;
// puis chaque situation rendue, 390 clair et sombre, pour
// verifier qu'aucune n'a de debordement ni de texte coupe. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea6c_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
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
  await stabiliser(tester);
  if (avant != null) {
    await avant(tester);
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de l'invitation recue par le second adulte, pour [etat].
String _adresseInvitation(EtatDemoAdulte etat) => adresseDemoAdulte(
  EcranDemoAdulte.invitationRecue,
  etat: etat,
  vue: VueDemoAdulte.secondAdulte,
);

void main() {
  group('Capture : EA-7', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Les notifications du second adulte, une seule ligne : 390/768/1440,
    // clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea7_notifications_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(
              EcranDemoAdulte.notifications,
              etat: EtatDemoAdulte.invitationEnAttente,
              vue: VueDemoAdulte.secondAdulte,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur les notifications, en 390.
    testWidgets('ea7_notifications_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea7_notifications_390_light_200pc',
        adresseDemoAdulte(
          EcranDemoAdulte.notifications,
          etat: EtatDemoAdulte.invitationEnAttente,
          vue: VueDemoAdulte.secondAdulte,
        ),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // L'invitation « a repondre » (etape 1, T1) : 390/768/1440, clair et
    // sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea7_etape1_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 1, en 390.
    testWidgets('ea7_etape1_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea7_etape1_390_light_200pc',
        _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Les deux reponses, sans taper (revue EA-7) : la page defile jusqu'a
    // « Accepter l'invitation ». L'une sous l'autre sur telephone, cote a
    // cote a 1440, « Refuser » au bord de debut ; meme poids (derogation
    // Q5) ; « Accepter » lisible en entier au-dessus de la barre a 390.
    Future<void> versBoutons(WidgetTester tester) =>
        tester.ensureVisible(find.byKey(InvitationRecuePage.accepterKey));
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea7_boutons_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
            taille,
            mode: mode,
            avant: versBoutons,
          );
        });
      }
    }

    // Les deux reponses a 200 %, en 390.
    testWidgets('ea7_boutons_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea7_boutons_390_light_200pc',
        _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
        const Size(390, 844),
        echelle: 2,
        avant: versBoutons,
      );
    });

    // Remplacement : jusqu'aux deux reponses, 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_remplacement_boutons_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_remplacement_boutons_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.nouvelleDemande),
          const Size(390, 844),
          mode: mode,
          avant: versBoutons,
        );
      });
    }

    // Titulaire femme : « elle doit voir », « Elle saura aussi » (390,
    // clair).
    testWidgets('ea7_etape1_390_light_titulaire_femme', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea7_etape1_390_light_titulaire_femme',
        adresseDemoAdulte(
          EcranDemoAdulte.invitationRecue,
          etat: EtatDemoAdulte.invitationEnAttente,
          vue: VueDemoAdulte.secondAdulte,
          genre: GenreTitulaireDemo.femme,
        ),
        const Size(390, 844),
      );
    });

    // Remplacement : le texte T2, puis l'acceptation en attente de
    // validation (390, clair et sombre).
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_remplacement_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_remplacement_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.nouvelleDemande),
          const Size(390, 844),
          mode: mode,
        );
      });
      testWidgets('ea7_remplacement_validation_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_remplacement_validation_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.nouvelleDemande),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            final Finder cible = find.byKey(InvitationRecuePage.accepterKey);
            await tester.ensureVisible(cible);
            await tester.tap(cible);
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Deja dans un autre foyer / ineligible : la seule forme neutre (F4),
    // 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_ineligible_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_ineligible_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.dejaDansUnAutreFoyer),
          const Size(390, 844),
          mode: mode,
        );
      });
    }

    // Expiree : « Cette invitation n'est plus valable », 390, clair et
    // sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_expiree_390_${mode.name}', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ea7_expiree_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.invitationExpiree),
          const Size(390, 844),
          mode: mode,
        );
      });
    }

    // Reponse tardive apres annulation : l'acceptation ne rattache personne,
    // 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_reponse_tardive_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_reponse_tardive_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.invitationAnnulee),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            final Finder cible = find.byKey(InvitationRecuePage.accepterKey);
            await tester.ensureVisible(cible);
            await tester.tap(cible);
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Validation deja en attente (section 10.4) : l'etat seul, sans bouton,
    // 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_validation_en_attente_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_validation_en_attente_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.validationEnAttente),
          const Size(390, 844),
          mode: mode,
        );
      });
    }

    // Erreur reseau (D5) : l'echec de l'acceptation, 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_echec_acceptation_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea7_echec_acceptation_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.erreurReseau),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            final Finder cible = find.byKey(InvitationRecuePage.accepterKey);
            await tester.ensureVisible(cible);
            await tester.tap(cible);
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Acceptee : « Vous avez rejoint le forfait famille », 390, clair et
    // sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_acceptee_390_${mode.name}', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ea7_acceptee_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            final Finder cible = find.byKey(InvitationRecuePage.accepterKey);
            await tester.ensureVisible(cible);
            await tester.tap(cible);
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Refusee : le texte « Si vous refusez » de T1, 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea7_refusee_390_${mode.name}', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ea7_refusee_390_${mode.name}',
          _adresseInvitation(EtatDemoAdulte.invitationEnAttente),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            final Finder cible = find.byKey(InvitationRecuePage.refuserKey);
            await tester.ensureVisible(cible);
            await tester.tap(cible);
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Sans compte : hors de toute coquille, 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea7_sans_compte_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(EcranDemoAdulte.invitationSansCompte),
            taille,
            mode: mode,
          );
        });
      }
    }
  });
}
