// AD-X, ecran 1 : l'Accueil de la direction (ADM-01) dans la composition de
// l'image ADMIN-SHELL-01 (docs/current/AD-X_DECOUPAGE.md §2, ecran 1).
//
// Ce que le test tient : la colonne « Activite recente » (source reelle
// `journal_audit()`, trois lignes au plus, « Voir tout le journal ») a cote
// des tuiles sur bureau et dessous sur telephone ; le sous-titre et la date de
// l'en-tete ; ses cinq etats, dont l'erreur qui n'emporte pas les tuiles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_tableau/activite_recente.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Lundi 5 octobre 2026, dix heures.
final DateTime _maintenant = DateTime(2026, 10, 5, 10);

EntreeJournal _entree(
  int id,
  String type, {
  String? acteur = 'a1',
  String? nom = 'Inès Exemple',
  int heures = 1,
}) => EntreeJournal(
  id: id,
  survenuLe: _maintenant.subtract(Duration(hours: heures)),
  typeEvenement: type,
  tableVisee: 'profiles',
  acteur: acteur,
  nomActeur: nom,
  details: const <String, dynamic>{},
);

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  FauxServiceJournal? journal,
  List<Override> plus = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.admin,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.admin,
          builder: (BuildContext _, GoRouterState _) =>
              TableauDeBordPage(horloge: () => _maintenant),
        ),
        GoRoute(
          path: Routes.adminSecuriteAuditJournal,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ADM-04')),
        ),
      ],
      surcharges: <Override>[
        serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
        serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
        serviceJournalProvider.overrideWithValue(
          journal ?? FauxServiceJournal(),
        ),
        ...plus,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

FauxServiceJournal _journalTrois() =>
    FauxServiceJournal()
      ..entreesEnBase = <EntreeJournal>[
        _entree(4, 'profil_cree'),
        _entree(3, 'demande_creee', nom: 'Karim Fictif', heures: 3),
        _entree(2, 'kyc_decision', acteur: null, nom: null, heures: 20),
        _entree(1, 'regle_posee', heures: 30),
      ];

void main() {
  group('ADM-01 (AD-X, ADMIN-SHELL-01) : composition', () {
    testWidgets('1440 : activite recente en colonne de fin, 336 de large', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        journal: _journalTrois(),
      );

      final Rect grille = tester.getRect(find.byType(GrilleBento));
      final Rect activite = tester.getRect(find.byType(ActiviteRecente));
      expect(activite.width, TableauDeBordPage.largeurActivite);
      // A cote, au bord de fin, aligne en haut avec les tuiles.
      expect(activite.left, greaterThan(grille.right));
      expect(activite.top, moinsDe(grille.top + 1));
      // Le sous-titre de l'image du directeur, et la date du jour.
      expect(find.text(t.admin.tableau.sousTitre), findsOneWidget);
      expect(find.byKey(TableauDeBordPage.cleDate), findsOneWidget);
      expect(find.text('lundi 5 octobre 2026'), findsOneWidget);
    });

    testWidgets('390 : activite recente sous les tuiles, sans date', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(390, 844),
        journal: _journalTrois(),
      );

      final Rect grille = tester.getRect(find.byType(GrilleBento));
      final Rect activite = tester.getRect(find.byType(ActiviteRecente));
      expect(activite.top, greaterThan(grille.bottom));
      expect(find.byKey(TableauDeBordPage.cleDate), findsNothing);
      expect(find.text(t.admin.tableau.sousTitre), findsOneWidget);
    });

    testWidgets('1440, texte x2 : une seule colonne', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(
        tester,
        taille: const Size(1440, 900),
        journal: _journalTrois(),
      );
      final Rect grille = tester.getRect(find.byType(GrilleBento));
      final Rect activite = tester.getRect(find.byType(ActiviteRecente));
      expect(activite.top, greaterThan(grille.bottom));
    });
  });

  group('ADM-01 (AD-X) : activite recente, cinq etats', () {
    testWidgets('contenu : trois lignes au plus, les plus recentes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        journal: _journalTrois(),
      );

      expect(find.text(t.admin.journal.evtProfilCree), findsOneWidget);
      expect(find.text(t.admin.journal.evtDemandeCreee), findsOneWidget);
      expect(find.text(t.admin.journal.evtKycTranche), findsOneWidget);
      // La quatrieme entree n'est pas montree (D6, trois lignes).
      expect(find.text(t.admin.journal.evtReglePosee), findsNothing);
      // L'auteur et l'instant ; « Le systeme » sans auteur.
      expect(
        find.text(
          t.admin.tableau.activite.ligne(
            qui: 'Karim Fictif',
            quand: t.admin.journal.horodatage(
              date: '05/10/2026',
              heure: '07:00',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(t.admin.journal.acteurSysteme),
        findsOneWidget,
      );
      // Aucun bouton plein sur l'Accueil (D5 : l'element dominant est la
      // grande tuile).
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('« Voir tout le journal » mene au Journal', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        journal: _journalTrois(),
      );
      await tester.tap(find.text(t.admin.tableau.activite.voirTout));
      await tester.pumpAndSettle();
      expect(find.text('ADM-04'), findsOneWidget);
    });

    testWidgets('vide : une phrase, pas de carte', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 900));
      expect(find.text(t.admin.tableau.activite.vide), findsOneWidget);
    });

    testWidgets('erreur : la phrase et Reessayer, les tuiles restent', (
      WidgetTester tester,
    ) async {
      final FauxServiceJournal journal = FauxServiceJournal()
        ..erreurEntrees = Exception('journal muet');
      await _monter(tester, taille: const Size(1440, 900), journal: journal);

      expect(find.text(t.admin.tableau.activite.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      // Une source en echec n'emporte que ce qu'elle remplit (D11).
      expect(find.text(t.admin.tableau.dossiers), findsOneWidget);

      journal
        ..erreurEntrees = null
        ..entreesEnBase = <EntreeJournal>[_entree(1, 'profil_cree')];
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.journal.evtProfilCree), findsOneWidget);
    });

    testWidgets('chargement : un squelette de lignes, sans texte', (
      WidgetTester tester,
    ) async {
      final Completer<List<EntreeJournal>> reponse =
          Completer<List<EntreeJournal>>();
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          TableauDeBordPage(horloge: () => _maintenant),
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
            serviceValidationProvider.overrideWithValue(
              FauxServiceValidation(),
            ),
            activiteRecenteProvider.overrideWith((_) => reponse.future),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.descendant(
          of: find.byType(ActiviteRecente),
          matching: find.byType(Skeleton),
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.tableau.activite.vide), findsNothing);
      reponse.complete(const <EntreeJournal>[]);
      await tester.pumpAndSettle();
      expect(find.text(t.admin.tableau.activite.vide), findsOneWidget);
    });
  });
}

/// `lessThan`, nomme pour se lire comme la regle : le haut de l'activite ne
/// descend pas sous le haut des tuiles.
Matcher moinsDe(double valeur) => lessThan(valeur);
