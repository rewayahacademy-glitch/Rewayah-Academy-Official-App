// EA-6 : les captures d'« Ajouter une conjointe / un conjoint » et de
// « Invitation envoyee ». Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md). Fichier propre a l'agent : ne pas confondre
// avec `captures_ea_test.dart` (poste B).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea5_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390, et l'etape 2
// (« Verifier et envoyer »), le detail de l'invitation envoyee, et les etats
// d'echec (erreur reseau, refus, hors ligne).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';

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

void main() {
  group('Capture : EA-6', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Etape 1, coordonnees : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea6_inviter_conjoint_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(
              EcranDemoAdulte.inviterConjoint,
              etat: EtatDemoAdulte.titulaireSansConjoint,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etape 1, en 390.
    testWidgets('ea6_inviter_conjoint_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea6_inviter_conjoint_390_light_200pc',
        adresseDemoAdulte(
          EcranDemoAdulte.inviterConjoint,
          etat: EtatDemoAdulte.titulaireSansConjoint,
        ),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Etape 2, « Verifier et envoyer » : le recapitulatif rempli.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier = 'ea6_verifier_envoyer_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(
            EcranDemoAdulte.inviterConjoint,
            etat: EtatDemoAdulte.titulaireSansConjoint,
          ),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            await tester.enterText(
              find.byKey(InviterConjointPage.prenomKey),
              'Mariama',
            );
            await tester.enterText(
              find.byKey(InviterConjointPage.courrielKey),
              'mariama@example.com',
            );
            await tester.pump();
            await tester.ensureVisible(
              find.byKey(InviterConjointPage.verifierKey),
            );
            await tester.tap(find.byKey(InviterConjointPage.verifierKey));
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Le detail de l'invitation envoyee.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea6_invitation_envoyee_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(
              EcranDemoAdulte.maFamille,
              etat: EtatDemoAdulte.invitationEnAttente,
            ),
            taille,
            mode: mode,
            avant: (WidgetTester tester) async {
              final Finder ligne = find.descendant(
                of: find.byKey(lignePlaceAdulteKey),
                matching: find.text(t.adulte.famille.place.invitationEnvoyee),
              );
              await tester.ensureVisible(ligne);
              await tester.tap(ligne);
              await tester.pumpAndSettle();
            },
          );
        });
      }
    }

    // Les etats d'echec sur l'etape 2 : erreur reseau, refus, hors ligne.
    for (final (String nom, EtatDemoAdulte etat) in <(String, EtatDemoAdulte)>[
      ('erreur_reseau', EtatDemoAdulte.erreurReseau),
    ]) {
      final String fichier = 'ea6_inviter_conjoint_390_light_$nom';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(EcranDemoAdulte.inviterConjoint, etat: etat),
          const Size(390, 844),
          avant: (WidgetTester tester) async {
            await tester.enterText(
              find.byKey(InviterConjointPage.prenomKey),
              'Mariama',
            );
            await tester.enterText(
              find.byKey(InviterConjointPage.courrielKey),
              'mariama@example.com',
            );
            await tester.pump();
            await tester.tap(find.byKey(InviterConjointPage.verifierKey));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Refus neutre et hors ligne (EA-6c) : la demonstration ne rend ni l'un
    // ni l'autre sur sa route (sa coquille fixe la connexion), la page
    // reelle est donc montee seule avec le port et la connexion surcharges.
    for (final (String nom, bool horsLigne) in <(String, bool)>[
      ('refus', false),
      ('hors_ligne', true),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea6_inviter_conjoint_390_${mode.name}_$nom';
        testWidgets(fichier, (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(390, 844), 1);
          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                horsLigneProvider.overrideWith(
                  (Ref _) => Stream<bool>.value(horsLigne),
                ),
                portInvitationConjointProvider.overrideWithValue(
                  const _PortRefus(),
                ),
              ],
              child: TranslationProvider(
                child: RepaintBoundary(
                  key: cadreCapture,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    darkTheme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.dark,
                    ),
                    themeMode: mode,
                    locale: AppLocale.fr.flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    home: InviterConjointPage(
                      placeFeminine: true,
                      onAbandon: () {},
                      onTerminee: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await stabiliser(tester);
          await tester.enterText(
            find.byKey(InviterConjointPage.prenomKey),
            'Mariama',
          );
          await tester.enterText(
            find.byKey(InviterConjointPage.courrielKey),
            'mariama@example.com',
          );
          await tester.pump();
          await tester.tap(find.byKey(InviterConjointPage.verifierKey));
          await tester.pumpAndSettle();
          if (!horsLigne) {
            await tester.ensureVisible(
              find.byKey(InviterConjointPage.envoyerKey),
            );
            await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
            await tester.pumpAndSettle();
          }
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier)}');
        });
      }
    }
  });
}

/// Un serveur qui refuse l'invitation, sans dire pourquoi (F4).
class _PortRefus implements PortInvitationConjoint {
  const _PortRefus();

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint _) async =>
      const InvitationRefusee();

  @override
  Future<ResultatAnnulation> annuler() async => const AnnulationFaite();
}
