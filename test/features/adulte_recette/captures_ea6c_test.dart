// EA-6c : les captures des ecrans corriges de l'invitation du conjoint
// (reponse tardive apres annulation, echecs D5, hors ligne a l'annulation,
// detail a 1440). Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B) ni avec `captures_ea6_test.dart` (matrice EA-6, refus et hors
// ligne a l'etape 2, deja verifiees visuellement).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea6_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390 sur l'etape 1.
//
// Le hors ligne a l'annulation est hors demonstration (sa coquille fixe la
// connexion a « en ligne ») : `InvitationEnvoyeePage` est montee seule avec
// le port et la connexion surcharges, comme `captures_ea6_test.dart` le fait
// deja pour le refus et le hors ligne de l'etape 2.
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
import 'package:rewayah_academy/core/widgets/action_principale.dart';
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

// Le destructif de la feuille de confirmation, pose au-dessus de la page
// (meme predicat que `inviter_conjoint_test.dart`).
Finder _confirmerAnnulation() => find
    .byWidgetPredicate(
      (Widget w) =>
          w is ActionPrincipale &&
          w.niveau == NiveauAction.destructive &&
          w.libelle == t.adulte.invitation.annuler &&
          w.key != InvitationEnvoyeePage.annulerKey,
    )
    .last;

void main() {
  group('Capture : EA-6c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Etape 1, « Inviter ma conjointe » (E4) : 390/768/1440, clair et
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
        final String fichier = 'ea6c_etape1_${l}_${mode.name}';
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
    testWidgets('ea6c_etape1_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea6c_etape1_390_light_200pc',
        adresseDemoAdulte(
          EcranDemoAdulte.inviterConjoint,
          etat: EtatDemoAdulte.titulaireSansConjoint,
        ),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Le detail de l'invitation envoyee : son contenu part du bord de la
    // tete de page, aussi a 1440 (EA-6c).
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea6c_detail_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(
              EcranDemoAdulte.invitationEnvoyee,
              etat: EtatDemoAdulte.invitationEnAttente,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }

    // La ligne « annulee » de Ma famille, apres la reponse tardive : ni
    // « Mariama, votre conjointe », ni photo (EA-6c, MAJEUR 1).
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea6c_ligne_annulee_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(
              EcranDemoAdulte.maFamille,
              etat: EtatDemoAdulte.invitationAnnulee,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }

    // D5 : l'echec de l'annulation (« L'annulation n'a pas ete confirmee. »,
    // « Verifiez avant de reessayer. »), en 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier = 'ea6c_echec_annulation_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(
            EcranDemoAdulte.invitationEnvoyee,
            etat: EtatDemoAdulte.erreurReseau,
          ),
          const Size(390, 844),
          mode: mode,
          avant: (WidgetTester tester) async {
            await tester.tap(find.byKey(InvitationEnvoyeePage.annulerKey));
            await tester.pumpAndSettle();
            await tester.tap(_confirmerAnnulation());
            await tester.pumpAndSettle();
          },
        );
      });
    }

    // Hors ligne a l'annulation (EA-6c, MINEUR) : « Rien n'est annule.
    // Vous pourrez annuler l'invitation vous-meme... » ; hors demonstration,
    // comme le refus et le hors ligne de l'etape 2 dans
    // `captures_ea6_test.dart`.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier = 'ea6c_hors_ligne_annulation_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(true),
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
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: InvitationEnvoyeePage(
                    invitation: DonneesAdulteDemo.invitationEnvoyee(
                      GenreTitulaireDemo.homme,
                    ),
                    onRetour: () {},
                    onAnnulee: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, fichier)}');
      });
    }
  });
}
