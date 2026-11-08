// SANS-BARRE-FIXE : captures de preuve, avant et apres (prefixe lu dans
// `CAPTURE_PREFIXE`, « apres » par defaut). Sept vrais ecrans qui posent
// `PageShell.actions` : le dossier (/attente), les accords, la piece
// d'identite, le contrat, la candidature (premiere etape du questionnaire,
// gabarit `PageEtape`), le profil de l'enseignant et la file des candidatures
// de la direction (mode selection). Pour chacun : (a) l'ecran a l'ouverture,
// (b) l'ecran defile tout en bas, la ou les actions vivent desormais.
//
// Telephone 390 x 844 a la densite 3, francais, theme clair. Donnees
// fictives seulement. Jamais sans `CAPTURE_DIR` (voir LISEZ-MOI.md).
//
// AVANT : remplacer `lib/core/widgets/page_shell.dart` par la version
// d'`origin/main`, lancer avec `CAPTURE_PREFIXE=avant`, puis le restaurer.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/consentements_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/profil/service_declaration.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';
import 'package:rewayah_academy/features/dossier/accords_page.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../router/support_routeur.dart' show sessionActive;
import '../support/harnais.dart';
import 'outil_capture.dart';

final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

/// SALLE-1-TOUT-ICI : `CAPTURE_LANGUE=ar` rend les ecrans en arabe (de
/// droite a gauche) ; francais par defaut, comme avant.
final bool _arabe = Platform.environment['CAPTURE_LANGUE'] == 'ar';

const Size _telephone = Size(390, 844);
const double _densite = 3;

/// Un temoin de destination : un ecran qui ne dit que son chemin.
GoRoute _temoin(String chemin) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) =>
      Scaffold(body: Text('temoin:$chemin')),
);

GoRoute _route(String chemin, Widget ecran) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) => ecran,
);

/// Monte [depart] dans un routeur minimal, sous le cadre de capture.
Future<void> _monter(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String depart,
  List<Override> surcharges = const <Override>[],
}) async {
  fixerVueCapture(tester, _telephone, _densite);
  final GoRouter routeur = GoRouter(initialLocation: depart, routes: routes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
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

/// Defile la page jusqu'a son extremite basse : le plus grand defileur
/// vertical, ramene a son maximum, jusqu'a ce que ce maximum ne bouge plus
/// (une page peut s'allonger en se construisant).
Future<void> _allerEnBas(WidgetTester tester) async {
  double precedent = -1;
  for (int i = 0; i < 6; i++) {
    final List<ScrollableState> etats = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where(
          (ScrollableState s) =>
              axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
              s.position.hasContentDimensions &&
              s.position.hasViewportDimension,
        )
        .toList()
      ..sort(
        (ScrollableState a, ScrollableState b) => b.position.viewportDimension
            .compareTo(a.position.viewportDimension),
      );
    if (etats.isEmpty) {
      return;
    }
    final ScrollPosition position = etats.first.position;
    if (position.maxScrollExtent == precedent &&
        position.pixels == position.maxScrollExtent) {
      return;
    }
    precedent = position.maxScrollExtent;
    // Un vrai geste d'abord (la tete defilante et les bascules l'ecoutent),
    // puis la position exacte du bas.
    await tester.dragFrom(
      Offset(_telephone.width / 2, _telephone.height * 0.7),
      Offset(0, -_telephone.height * 0.5),
    );
    await stabiliser(tester);
    position.jumpTo(position.maxScrollExtent);
    await stabiliser(tester);
  }
}

/// Dit ou est la zone d'action dans la vue (preuve chiffree a cote du PNG).
void _mesurer(WidgetTester tester, String nom) {
  final Finder zone = find.byKey(PageShell.zoneActionKey);
  if (zone.evaluate().isEmpty) {
    debugPrint('MESURE $nom zone-action absente');
    return;
  }
  final Rect r = tester.getRect(zone.first);
  debugPrint(
    'MESURE $nom zone-action haut=${r.top.toStringAsFixed(1)} '
    'bas=${r.bottom.toStringAsFixed(1)} (vue ${_telephone.height})',
  );
}

Future<void> _capturerAB(
  WidgetTester tester,
  String ecran, {
  Future<void> Function()? avantA,
}) async {
  if (avantA != null) {
    await avantA();
  }
  final String a = 'sbf_${_prefixe}_${ecran}_a';
  _mesurer(tester, a);
  debugPrint('PNG ${await capturer(tester, a)}');
  await _allerEnBas(tester);
  final String b = 'sbf_${_prefixe}_${ecran}_b';
  _mesurer(tester, b);
  debugPrint('PNG ${await capturer(tester, b)}');
}

// ---------------------------------------------------------------- donnees

EtatDossier _etatTuteurIncomplet() => const EtatDossier(
  profilExiste: true,
  role: AppRole.guardian,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: false,
  contratSigne: false,
  pieceDeposee: false,
);

/// Une piece fictive : l'en-tete PNG et des zeros.
PieceAEnvoyer _pieceFictive() => PieceAEnvoyer(
  octets: Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    ...List<int>.filled(1016, 0),
  ]),
  nomFichier: 'piece.png',
  type: TypePiece.passeport,
);

/// La declaration du profil enseignant, en memoire (rien n'est ecrit).
class _FausseDeclaration implements ServiceDeclarationEnseignant {
  @override
  Future<void> declarer({String? pays, List<String>? langues}) async {}
}

const ProfilEnseignant _profilFictif = ProfilEnseignant(
  prenom: 'Prenom',
  identifiant: 'RA-26-0000',
  pays: 'GN',
  langues: <String>['francais', 'poular'],
  plafondHeures: 20,
  statutCompte: AccountStatus.active,
  verification: VerificationEnseignant.validee,
);

void main() {
  group('Capture SANS-BARRE-FIXE ($_prefixe)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      if (_arabe) {
        await LocaleSettings.setLocale(AppLocale.ar);
      }
    });
    tearDownAll(() => LocaleSettings.setLocale(AppLocale.fr));

    testWidgets('1. dossier /attente', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.attente,
        routes: <RouteBase>[
          _route(Routes.attente, const AttentePage()),
          _temoin(Routes.attenteContrat),
          _temoin(Routes.attenteAccords),
          _temoin(Routes.attentePiece),
        ],
        surcharges: <Override>[
          serviceDossierProvider.overrideWithValue(
            FauxServiceDossier()..etatRendu = _etatTuteurIncomplet(),
          ),
        ],
      );
      await _capturerAB(tester, 'attente');
    });

    testWidgets('2. accords', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.attenteAccords,
        routes: <RouteBase>[
          _route(Routes.attenteAccords, const AccordsPage()),
          _temoin(Routes.attente),
          _temoin(Routes.attenteContrat),
        ],
        surcharges: <Override>[
          serviceDossierProvider.overrideWithValue(
            FauxServiceDossier()..etatRendu = _etatTuteurIncomplet(),
          ),
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(sessionActive(AppRole.guardian)),
          ),
        ],
      );
      await _capturerAB(tester, 'accords');
    });

    testWidgets('3. piece d\'identite', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.attentePiece,
        routes: <RouteBase>[
          _route(Routes.attentePiece, const DepotPiecePage()),
          _temoin(Routes.attente),
        ],
        surcharges: <Override>[
          serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          selecteurFichierProvider.overrideWithValue(
            FauxSelecteurFichier(_pieceFictive()),
          ),
        ],
      );
      await _capturerAB(tester, 'piece');
    });

    testWidgets('4. contrat (signature)', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.attenteContrat,
        routes: <RouteBase>[
          _route(Routes.attenteContrat, const ContratPage()),
          _temoin(Routes.attente),
        ],
        surcharges: <Override>[
          serviceDossierProvider.overrideWithValue(
            FauxServiceDossier()..etatRendu = _etatTuteurIncomplet(),
          ),
          consentementsLotAProvider.overrideWithValue(
            FauxPortConsentements()..signeesRendues = <Acceptation>[],
          ),
        ],
      );
      await _capturerAB(tester, 'contrat');
    });

    testWidgets('5. candidature (questionnaire)', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.attenteCandidature,
        routes: routesCandidature(),
        surcharges: surchargesCandidature(
          port: FauxMaCandidature(),
          etat: etatCandidat(candidature: candidatureAFaire()),
        ),
      );
      await _capturerAB(tester, 'candidature');
    });

    testWidgets('6. profil de l\'enseignant', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.enseignantProfil,
        routes: <RouteBase>[
          _route(Routes.enseignantProfil, const ProfilEnseignantPage()),
        ],
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(
              const SessionState(
                resolue: true,
                role: AppRole.teacher,
                profileId: 'ens-1',
                accountStatus: AccountStatus.active,
                lectureProfil: LectureProfil.presente,
              ),
            ),
          ),
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
          baseLocaleEnMemoire(),
          serviceDeclarationProvider.overrideWithValue(_FausseDeclaration()),
          referentielLanguesProvider.overrideWith(
            (_) => Future<List<LangueCours>>.value(const <LangueCours>[
              LangueCours(code: 'poular', nom: 'Poular'),
              LangueCours(code: 'francais', nom: 'Français'),
            ]),
          ),
          servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          profilEnseignantProvider.overrideWith((_) => _profilFictif),
          acceptationsProvider.overrideWith((_) => const <Acceptation>[]),
        ],
      );
      await _capturerAB(tester, 'profil_enseignant');
    });

    testWidgets('7. candidatures de la direction, selection', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.adminPersonnesCandidatures,
        routes: <RouteBase>[
          _route(
            Routes.adminPersonnesCandidatures,
            CandidaturesPage(agirSurSelection: (List<String> _) {}),
          ),
          _temoin(Routes.adminPersonnesInvitations),
          _temoin(RoutesCandidatsFlux.importFormulaires),
        ],
        surcharges: <Override>[
          horsLigneProvider.overrideWith(
            (Ref _) => Stream<bool>.value(false),
          ),
          portCandidaturesDirectionProvider.overrideWithValue(
            FauxCandidaturesDirection(
              lignes: lignesEnMasse(8),
              capacitesRendues: capacitesQuiDecide,
            ),
          ),
          portInvitationsEnseignantProvider.overrideWithValue(null),
          portInvitationsComptableProvider.overrideWithValue(null),
        ],
      );
      await _capturerAB(
        tester,
        'candidatures',
        // La zone d'action n'existe qu'avec une selection : deux lignes
        // retenues, comme le test de widget de la page.
        avantA: () async {
          for (final String cle in <String>[
            'candidatures-selectionner',
            'candidature-m0',
            'candidature-m1',
          ]) {
            final Finder f = find.byKey(ValueKey<String>(cle));
            await tester.ensureVisible(f);
            await stabiliser(tester);
            await tester.tap(f);
            await stabiliser(tester);
          }
          final Finder haut = find.byType(Scrollable).first;
          await tester.drag(haut, const Offset(0, 5000));
          await stabiliser(tester);
        },
      );
    });
  });
}
