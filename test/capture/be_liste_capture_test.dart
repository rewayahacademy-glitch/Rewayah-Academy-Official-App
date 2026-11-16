// Captures R3 de BE-LISTE (16/11/2026) : la liste des candidatures avec son
// en-tete reduit. Donnees de test uniquement, aucune personne reelle.
//
// Scenes, a 360 (telephone), 1366 (ordinateur) et en arabe (droite a gauche) :
// 1. la liste a l'arrivee : « Outils », « Qui attend quoi » ;
// 2. « Qui attend quoi » repliee, le premier nom plus haut ;
// 3. le menu « Outils » ouvert ;
// 4. « Piece d'identite a valider » touchee : la meme liste, filtree, et
//    l'adresse qui le dit (ecrite dans le journal).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/carte_attentes.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/recrutement_demo.dart';
import 'outil_capture.dart';

GoRoute _route(String chemin, Widget ecran) =>
    GoRoute(path: chemin, builder: (BuildContext _, GoRouterState _) => ecran);

List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(id: 'a1', nom: 'Amina Diallo'),
  ligneTest(id: 'b2', nom: 'Bilal Haddad'),
  ligneTest(id: 'f6', nom: 'Farah Nasser'),
];

Future<void> _monter(WidgetTester tester, Size taille, double densite) async {
  fixerVueCapture(tester, taille, densite);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesCandidatures,
    routes: <RouteBase>[
      _route(
        Routes.adminPersonnesCandidatures,
        // Comme le routeur : une destination existe, « Ouvrir le dossier »
        // est la premiere entree du menu.
        Builder(
          builder: (BuildContext c) => CandidaturesPage(
            requete: GoRouterState.of(c).uri.queryParameters,
            ouvrirCandidature: (LigneCandidature _) {},
          ),
        ),
      ),
      _route(Routes.adminPersonnesInvitations, const SizedBox()),
      _route(RoutesCandidatsFlux.importFormulaires, const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: capacitesGestes,
            details: <DetailCandidature>[detailTest(id: 'a1')],
          ),
        ),
        portInvitationsEnseignantProvider.overrideWithValue(InvitationsDemo()),
        portAttentesRecrutementProvider.overrideWithValue(_Attentes()),
        portInvitationsComptableProvider.overrideWithValue(null),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              themeMode: ThemeMode.light,
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
}

class _Attentes implements PortAttentesRecrutement {
  @override
  Future<AttentesRecrutement> lire() async => const AttentesRecrutement(
    parEtat: <EtatCandidature, Attente>{
      EtatCandidature.enExamen: Attente(nombre: 41),
      EtatCandidature.entretienAPlanifier: Attente(nombre: 7),
    },
    pieceAValider: Attente(nombre: 12),
  );
}

void main() {
  group('Capture BE-LISTE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.en);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final (String, Size, double, AppLocale) g
        in <(String, Size, double, AppLocale)>[
          ('fr_360', const Size(360, 800), 2, AppLocale.fr),
          ('fr_1366', const Size(1366, 768), 1, AppLocale.fr),
          ('ar_360', const Size(360, 800), 2, AppLocale.ar),
        ]) {
      testWidgets('BE-LISTE ${g.$1}', (WidgetTester tester) async {
        LocaleSettings.setLocaleSync(g.$4);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(tester, g.$2, g.$3);
        debugPrint('PNG ${await capturer(tester, '1_arrivee_${g.$1}')}');
        await tester.tap(find.text(t.recrutement.file.replier));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '2_repliee_${g.$1}')}');
        await tester.tap(find.byKey(CandidaturesPage.cleOutils));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '3_outils_${g.$1}')}');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await stabiliser(tester);
        await tester.tap(find.text(t.recrutement.file.afficher));
        await stabiliser(tester);
        final Finder piece = find.byKey(CarteAttentes.clePiece);
        await tester.ensureVisible(piece);
        await stabiliser(tester);
        await tester.tap(piece);
        await stabiliser(tester);
        final Uri u = GoRouter.of(tester.element(find.byType(CandidaturesPage)))
            .routerDelegate
            .currentConfiguration
            .uri;
        debugPrint('ADRESSE ${g.$1} $u');
        // La puce retenue et le total : ce que la capture doit montrer.
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('candidatures-total')),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '4_piece_filtree_${g.$1}')}');
      });
    }
  });
}
