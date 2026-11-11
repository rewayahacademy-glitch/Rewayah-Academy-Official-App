// EA-RC : captures de recette des ecrans corriges par la revue EA-R (lots L1 a
// L5), meme mecanisme que `captures_ea12_test.dart` : la VRAIE route
// /demo/adulte (`adresseDemoAdulte`), vrais boutons tapes (K-07).
// Les captures (a), (b) et (h) de Mon espace sont retirees avec lui
// (MON-ESPACE-ADULTE-SUPPR, 11/11/2026).
//
// (a2) Paiements du foyer du titulaire : soldes « Solde de demonstration ... »
//      sans unite (m1 a m3).
// (c)  Accueil adulte hors ligne (M5).
// (d)  Ma classe adulte hors ligne (M5).
// (e)  Invitation envoyee, resultat sur `EcranResultat` (M4).
// (f)  Invitation recue, etat final sur `EcranResultat` (M4) : acceptee et
//      refusee.
// (g)  Ma famille du titulaire, « Faire une nouvelle demande » au bord de fin
//      (m8, validation refusee).
// (i)  « Ajouter ma famille » de l'adulte seul (EA-PL parcours).
//
// 390x844, 768x1024 et 1440x900, clair et sombre. Jamais sans CAPTURE_DIR
// (voir test/capture/LISEZ-MOI.md).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/adulte_demo.dart';
import '../../support/demo/demo_adulte_page.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 844)),
  ('768', Size(768, 1024)),
  ('1440', Size(1440, 900)),
];

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// Comme `captures_ea12_test.dart` : la VRAIE coquille, sous un GoRouter sur
/// la route de demonstration.
Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
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

/// Un groupe par ecran : trois tailles, clair et sombre.
void _groupe(
  String nom,
  String prefixe,
  String adresse, {
  Future<void> Function(WidgetTester tester)? avant,
}) {
  group('Capture : EA-RC, $nom', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _modes) {
        final String fichier = 'earc_${prefixe}_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresse,
            taille,
            mode: mode,
            avant: avant,
          );
        });
      }
    }
  });
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  _groupe(
    '(a2) Paiements du foyer, titulaire, soldes de demonstration',
    'a2_foyer_titulaire_soldes',
    adresseDemoAdulte(EcranDemoAdulte.paiementsFoyer),
  );

  _groupe(
    '(c) Accueil adulte hors ligne',
    'c_accueil_hors_ligne',
    adresseDemoAdulte(EcranDemoAdulte.accueil, reseauCoupe: true),
  );

  _groupe(
    '(d) Ma classe adulte hors ligne',
    'd_ma_classe_hors_ligne',
    adresseDemoAdulte(EcranDemoAdulte.maClasse, reseauCoupe: true),
  );

  _groupe(
    '(e) invitation envoyee, resultat',
    'e_invitation_envoyee',
    adresseDemoAdulte(
      EcranDemoAdulte.inviterConjoint,
      etat: EtatDemoAdulte.titulaireSansConjoint,
    ),
    avant: (WidgetTester tester) async {
      await tester.enterText(
        find.byKey(InviterConjointPage.prenomKey),
        'Mariama',
      );
      await tester.enterText(find.byKey(InviterConjointPage.nomKey), 'Diallo');
      await tester.enterText(
        find.byKey(InviterConjointPage.courrielKey),
        'mariama@example.com',
      );
      await tester.pump();
      await _taper(tester, find.byKey(InviterConjointPage.verifierKey));
      await _taper(tester, find.byKey(InviterConjointPage.envoyerKey));
    },
  );

  final String adresseInvitationRecue = adresseDemoAdulte(
    EcranDemoAdulte.invitationRecue,
    etat: EtatDemoAdulte.invitationEnAttente,
    vue: VueDemoAdulte.secondAdulte,
  );
  _groupe(
    '(f) invitation recue, etat final accepte',
    'f_invitation_recue_acceptee',
    adresseInvitationRecue,
    avant: (WidgetTester tester) =>
        _taper(tester, find.byKey(InvitationRecuePage.accepterKey)),
  );
  _groupe(
    '(f) invitation recue, etat final refuse',
    'f_invitation_recue_refusee',
    adresseInvitationRecue,
    avant: (WidgetTester tester) =>
        _taper(tester, find.byKey(InvitationRecuePage.refuserKey)),
  );

  _groupe(
    '(g) Ma famille, « Faire une nouvelle demande »',
    'g_ma_famille_nouvelle_demande',
    adresseDemoAdulte(
      EcranDemoAdulte.maFamille,
      etat: EtatDemoAdulte.validationRefusee,
    ),
  );

  _groupe(
    '(i) « Ajouter ma famille », adulte seul',
    'i_ajouter_ma_famille',
    adresseDemoAdulte(
      EcranDemoAdulte.ajouterMaFamille,
      etat: EtatDemoAdulte.adulteSeul,
    ),
  );
}
