// Captures R3 de PE-LISTE-CANDIDATURES (PE-C4, 20/11/2026) : la liste des
// candidatures traitee par groupes. Donnees fictives uniquement, aucune
// personne reelle.
//
// Scenes, a 390 et 1440 de large :
// 1. le mode selection, la page retenue : « Selectionner les 260 resultats » ;
// 2. les 260 resultats retenus (nombre exact du double du serveur) ; la barre
//    dit que le geste porte sur les 200 premieres ;
// 3. l'apercu du geste groupe « Admettre » : qui sera concerne, qui ne le sera
//    pas, et pourquoi (controle d'admission faux, pause) ;
// 4. l'apercu du geste groupe « Ecrire » (sans compte, en pause) ;
// 5. le tableau de bord : les visages des trois plus anciens d'une file de 120
//    personnes (plus d'une page de 50).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/creneaux_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';
import 'package:rewayah_academy/features/admin_tableau/adresses_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/dernier_non_lu.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/com_messages/non_lus_messages.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/recrutement_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const List<String> _prenoms = <String>[
  'Personne',
  'Exemple',
  'Essai',
  'Modele',
  'Dossier',
  'Candidat',
];

final DateTime _base = DateTime.utc(2026, 11, 20, 8);

/// 260 candidatures fictives en Salle d'examen, de la plus recente a la plus
/// ancienne activite ; quelques-unes en pause.
List<LigneCandidature> _lignes() => <LigneCandidature>[
  for (int i = 0; i < 260; i++)
    ligneTest(
      id: 'p$i',
      reference: 'CAND-${(10000 + i).toString()}',
      nom: '${_prenoms[i % _prenoms.length]} Fictif $i',
      enPause: i % 37 == 5,
      derniereActivite: _base.subtract(Duration(hours: 3 * i)),
    ),
];

FauxCandidaturesDirection _port() =>
    FauxCandidaturesDirection(
        lignes: _lignes(),
        capacitesRendues: capacitesGestes,
      )
      // Deux controles d'admission faux et trois personnes sans compte.
      ..controlesAdmissionFaux.addAll(<String, String>{
        'p1': 'paiement_compatible',
        'p3': 'cadre_religieux',
      })
      ..sansCompte.addAll(<String>{'p2', 'p4', 'p6'});

GoRoute _route(String chemin, Widget ecran) =>
    GoRoute(path: chemin, builder: (BuildContext _, GoRouterState _) => ecran);

Future<void> _monterListe(
  WidgetTester tester,
  Size taille,
  double densite,
) async {
  fixerVueCapture(tester, taille, densite);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesCandidatures,
    routes: <RouteBase>[
      _route(
        Routes.adminPersonnesCandidatures,
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
        portCandidaturesDirectionProvider.overrideWithValue(_port()),
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
      EtatCandidature.enExamen: Attente(nombre: 260),
    },
    pieceAValider: Attente(nombre: 0),
  );
}

/// Une page de la file d'un etat, comme le serveur la rend avec le tri
/// `ancienne` : les plus anciennes d'abord, 50 lignes, le total exact.
PageCandidatures _pageAncienne(int total, int decalageNom) =>
    PageCandidatures.depuisJson(<String, Object?>{
      'total': total,
      'page': 1,
      'taillePage': 50,
      'lignes': <Object?>[
        for (int i = 0; i < (total < 50 ? total : 50); i++)
          <String, Object?>{
            'id': 'id-$decalageNom-$i',
            'reference': 'CAND-${20000 + decalageNom + i}',
            'nomComplet':
                '${_prenoms[(i + decalageNom) % _prenoms.length]} Ancien $i',
            'issue': 'en_cours',
            'paysResidence': 'GN',
            'derniereActivite': _base
                .subtract(Duration(days: 60 - i))
                .toIso8601String(),
          },
      ],
    });

List<Override> _surchargesTableau() => <Override>[
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()
      ..indicateursRendus = const IndicateursAdmin(
        dossiersEnAttente: 0,
        foyersSansEnseignant: 0,
        rapportsManquants: 0,
        incidents24h: 0,
        comptesEchus: 0,
        demandesEnAttente: 0,
      ),
  ),
  serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
  attentesRecrutementProvider.overrideWith(
    (_) async => AttentesRecrutement(
      parEtat: <EtatCandidature, Attente>{
        EtatCandidature.aCompleter: Attente(
          nombre: 64,
          plusAncien: DateTime(2026, 9, 20, 9),
        ),
        EtatCandidature.enExamen: Attente(
          nombre: 260,
          plusAncien: DateTime(2026, 9, 21, 9),
        ),
        EtatCandidature.entretienAPlanifier: Attente(
          nombre: 120,
          plusAncien: DateTime(2026, 9, 22, 9),
        ),
      },
      pieceAValider: const Attente(nombre: 0),
      creneauxOuverts: 2,
    ),
  ),
  creneauxDirectionProvider.overrideWith((_) async => <CreneauDirection>[]),
  pageCandidaturesProvider(requeteEtat(EtatCandidature.aCompleter))
      .overrideWith((_) async => _pageAncienne(64, 0)),
  pageCandidaturesProvider(requeteEtat(EtatCandidature.enExamen))
      .overrideWith((_) async => _pageAncienne(260, 1)),
  pageCandidaturesProvider(requeteEtat(EtatCandidature.entretienAPlanifier))
      .overrideWith((_) async => _pageAncienne(120, 2)),
  dernierNonLuProvider.overrideWith((_) async => null),
  nonLusMessagesProvider.overrideWith((_) async => 0),
];

void main() {
  group('Capture PE-LISTE-CANDIDATURES', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String, Size, double) g in <(String, Size, double)>[
      ('390', const Size(390, 844), 2),
      ('1440', const Size(1440, 900), 1),
    ]) {
      testWidgets('liste ${g.$1}', (WidgetTester tester) async {
        await _monterListe(tester, g.$2, g.$3);
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selectionner')),
        );
        await stabiliser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selection-page')),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '1_page_retenue_${g.$1}')}');
        await tester.tap(
          find.byKey(const ValueKey<String>('candidatures-selection-tous')),
        );
        await stabiliser(tester);
        expect(
          find.text(t.admin.candidatures.selection.tousRetenus(n: 260)),
          findsOneWidget,
        );
        debugPrint('PNG ${await capturer(tester, '2_tous_retenus_${g.$1}')}');
        // La barre de la selection est dans le fil de la page, apres la liste
        // (PageShell, SANS-BARRE-FIXE) : on y descend.
        await tester.ensureVisible(find.byKey(CandidaturesPage.cleBarreLot));
        await stabiliser(tester);
        expect(
          find.text(t.admin.candidatures.lot.parTranche(n: 200, reste: 60)),
          findsOneWidget,
        );
        debugPrint('PNG ${await capturer(tester, '2b_barre_${g.$1}')}');
        await tester.tap(
          find.byKey(CandidaturesPage.cleOperationLot(GesteLot.admettre)),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, '3_apercu_admettre_${g.$1}')}',
        );
        expect(find.byType(FeuilleLot), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await stabiliser(tester);
        await tester.ensureVisible(find.byKey(CandidaturesPage.cleBarreLot));
        await stabiliser(tester);
        await tester.tap(
          find.byKey(CandidaturesPage.cleOperationLot(GesteLot.ecrire)),
        );
        await stabiliser(tester);
        expect(find.byType(FeuilleLot), findsOneWidget);
        debugPrint('PNG ${await capturer(tester, '4_apercu_ecrire_${g.$1}')}');
      });

      testWidgets('tableau de bord ${g.$1}', (WidgetTester tester) async {
        fixerVueCapture(
          tester,
          Size(g.$2.width, g.$2.width < 600 ? 2400 : 1400),
          1,
        );
        await tester.pumpWidget(
          hoteCapture(
            TableauDeBordPage(horloge: () => DateTime(2026, 11, 20, 9)),
            surcharges: _surchargesTableau(),
          ),
        );
        for (int i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        debugPrint(
          'PNG ${await capturer(tester, '5_tableau_visages_${g.$1}')}',
        );
      });
    }
  });
}
