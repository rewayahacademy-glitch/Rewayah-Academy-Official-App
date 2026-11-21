// PERSONNES-UNE-PAGE, etape (f) point 3 : « Pieces a verifier » ouvre la revue
// de la piece elle-meme pour un compte sans dossier de candidature (le detail
// de « Dossiers a valider », reutilise) ; la fermer ramene a Personnes, vue
// « Pieces a verifier », jamais a la file des dossiers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/admin_dossiers/detail_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/admin_dossiers/revue_dossier.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/demo/dossiers_demo.dart';
import '../../support/demo/mode_demonstration.dart';
import '../../support/dossiers_production.dart';
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => const <CompteAdmin>[];
}

class _Enseignants implements PortEnseignants {
  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => const PageEnseignants(
    lignes: <LigneEnseignant>[],
    total: 0,
    page: 1,
    taillePage: 50,
    compteurs: CompteursEnseignants(),
  );
}

DossierAValider _piece(String id, String prenom) => DossierAValider(
  documentId: 'doc-$id',
  profilId: 'p-$id',
  type: TypePiece.carteIdentite,
  cleObjet: 'p-$id/piece.webp',
  deposeLe: DateTime.now().subtract(const Duration(days: 3)),
  prenom: prenom,
  nom: 'Essai',
  identifiantImmuable: 'RA-26-77$id',
  role: AppRole.teacher,
);

late GoRouter _routeur;
late FauxServiceValidation _service;
late ProviderContainer _conteneur;

Future<void> _monter(WidgetTester tester, {required String adresse}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  _service = FauxServiceValidation()
    ..file = <DossierAValider>[_piece('1', 'Hind'), _piece('2', 'Ilyes')];
  await tester.pumpWidget(
    hoteRoutant(
      depart: adresse,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminPersonnes,
          builder: (BuildContext contexte, GoRouterState e) {
            _routeur = GoRouter.of(contexte);
            _conteneur = ProviderScope.containerOf(contexte);
            return PersonnesPage(requete: e.uri.queryParameters);
          },
        ),
        GoRoute(
          path: Routes.adminPersonnesDossiers,
          // Le meme branchement que le routeur du bureau.
          builder: (BuildContext _, GoRouterState e) => DossiersPage(
            profilId: switch (e.extra) {
              final String id => id,
              (profilId: final String id, retour: String _) => id,
              _ => null,
            },
            retour: switch (e.extra) {
              (profilId: String _, retour: final String retour) => retour,
              _ => null,
            },
          ),
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Comptes()),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portEnseignantsProvider.overrideWithValue(_Enseignants()),
        serviceValidationProvider.overrideWithValue(_service),
        surchargeRevueDossiersBrancheeBR1,
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

String get _adresse =>
    _routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  const String vuePieces =
      '/admin/personnes?onglet=enseignants&vue=pieces&element=RA-26-772';

  testWidgets('« Verifier la piece » ouvre la revue de cette piece, pas la '
      'file des dossiers ; le retour ramene a Personnes, vue Pieces, meme '
      'personne', (WidgetTester tester) async {
    await _monter(tester, adresse: vuePieces);
    await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
    await tester.pumpAndSettle();
    // La revue de la piece d'Ilyes, et rien de la file.
    expect(find.byType(RevueDossier), findsOneWidget);
    expect(find.byType(DetailDossier), findsOneWidget);
    expect(find.byKey(DossiersPage.cleFile), findsNothing);
    expect(find.textContaining('Ilyes'), findsWidgets);
    expect(find.textContaining('Hind'), findsNothing);
    // Le retour du systeme : Personnes, la vue, la personne.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_adresse, contains('onglet=enseignants'));
    expect(_adresse, contains('vue=pieces'));
    expect(_adresse, contains('element=RA-26-772'));
    expect(find.byKey(PersonnesPage.cleVerifierPiece), findsOneWidget);
    expect(find.byKey(DossiersPage.cleFile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la revue se ferme (decision prise, dossier retire) : on revient '
      'a Personnes et la vue se relit', (WidgetTester tester) async {
    await _monter(tester, adresse: vuePieces);
    await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
    await tester.pumpAndSettle();
    expect(find.byType(RevueDossier), findsOneWidget);
    // Ce que fait la page apres une decision sans dossier suivant : la
    // selection est retiree. La piece n'est plus dans la file du serveur.
    _service.file = <DossierAValider>[_piece('1', 'Hind')];
    _conteneur.read(selectionDossierProvider.notifier).retirer();
    await tester.pumpAndSettle();
    expect(_adresse, contains('vue=pieces'));
    expect(find.byKey(DossiersPage.cleFile), findsNothing);
    // La vue est relue : Ilyes n'y est plus.
    expect(find.textContaining('Ilyes'), findsNothing);
    expect(find.textContaining('Hind'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // La decision reelle, jouee depuis la revue ouverte par Personnes, sur la
  // demonstration de la direction (le faux qui sait valider et refuser).
  group('la decision depuis la revue ouverte par Personnes', () {
    late EtatRevueDemo etat;

    Future<void> monterDemo(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      etat = EtatRevueDemo.initial();
      await tester.pumpWidget(
        hoteRoutant(
          depart: '/admin/personnes?onglet=enseignants&vue=pieces',
          routes: <RouteBase>[
            GoRoute(
              path: Routes.adminPersonnes,
              builder: (BuildContext contexte, GoRouterState e) {
                _routeur = GoRouter.of(contexte);
                return PersonnesPage(requete: e.uri.queryParameters);
              },
            ),
            GoRoute(
              path: Routes.adminPersonnesDossiers,
              builder: (BuildContext _, GoRouterState e) => DossiersPage(
                profilId: switch (e.extra) {
                  (profilId: final String id, retour: String _) => id,
                  _ => null,
                },
                retour: switch (e.extra) {
                  (profilId: String _, retour: final String retour) => retour,
                  _ => null,
                },
              ),
            ),
          ],
          surcharges: surchargesDemoAdmin(environnement: 'staging', etat: etat),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> ouvrirRevue(WidgetTester tester, String nom) async {
      await tester.tap(find.text(nom).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
      await tester.pumpAndSettle();
      expect(find.byType(RevueDossier), findsOneWidget);
    }

    // La decision part au serveur : des images a pas fixe (un bouton en
    // attente empeche `pumpAndSettle` de finir).
    Future<void> laisserDecider(WidgetTester tester) async {
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> toucher(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    testWidgets('valider : la phrase du serveur est dite sur Personnes, la '
        'piece quitte la vue', (WidgetTester tester) async {
      await monterDemo(tester);
      expect(find.text('Omar Haddad'), findsWidgets);
      await ouvrirRevue(tester, 'Omar Haddad');
      for (final String point in <String>[
        t.dossiers.pointLisible,
        t.dossiers.pointNom,
        t.dossiers.pointValidite,
      ]) {
        await toucher(tester, find.text(point));
      }
      await toucher(tester, find.text(t.dossiers.approuver));
      // Rien n'est decide avant la confirmation.
      expect(etat.nombreDecisions, 0);
      await tester.tap(find.text(t.dossiers.approuver).last);
      await laisserDecider(tester);
      expect(etat.nombreDecisions, 1);
      // De retour sur Personnes, vue Pieces : la phrase, la liste relue.
      expect(find.byType(RevueDossier), findsNothing);
      expect(find.byKey(DossiersPage.cleFile), findsNothing);
      expect(find.byKey(PersonnesPage.cleVues), findsOneWidget);
      expect(_adresse, contains('vue=pieces'));
      expect(find.text(t.dossiers.validation.succes), findsOneWidget);
      expect(find.text('Omar Haddad'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refuser avec un motif : la phrase du serveur est dite sur '
        'Personnes, la piece quitte la vue', (WidgetTester tester) async {
      await monterDemo(tester);
      await ouvrirRevue(tester, 'Amina Benali');
      await toucher(tester, find.text(t.dossiers.refuser));
      await toucher(tester, find.byKey(SelecteurMotif.cleAutre));
      await tester.enterText(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(t.dossiers.refus.champ),
                matching: find.byType(ZoneSaisie),
              ),
              matching: find.byType(TextField),
            )
            .first,
        'Motif fictif : photo floue.',
      );
      await tester.pumpAndSettle();
      expect(etat.nombreDecisions, 0);
      await tester.tap(find.text(t.dossiers.refuser).last);
      await laisserDecider(tester);
      expect(etat.nombreDecisions, 1);
      expect(find.byType(RevueDossier), findsNothing);
      expect(find.byKey(DossiersPage.cleFile), findsNothing);
      expect(find.byKey(PersonnesPage.cleVues), findsOneWidget);
      expect(find.text(t.dossiers.refus.succes), findsOneWidget);
      expect(find.text('Amina Benali'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
