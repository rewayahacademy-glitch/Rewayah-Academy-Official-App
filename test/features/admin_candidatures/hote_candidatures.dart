// Le harnais d'`ADM-20` : la file des candidatures montee sur un routeur de
// test, avec le double du port de la direction (ou aucun port).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';

import '../../support/demo/recrutement_demo.dart';
import '../../support/monter_recrutement.dart';

/// Monte la file des candidatures.
///
/// [port] nul : aucun port (la capacite indisponible). [ouvrir] est la
/// destination d'`ADM-21` ; nulle, la ligne ne s'ouvre pas. Le traitement
/// groupe vit dans la page (REPRISE-CAND-1). [invitations] pose le port des
/// invitations d'enseignant, [comptable] celui des invitations de comptable.
Future<void> monterCandidatures(
  WidgetTester tester, {
  PortCandidaturesDirection? port,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
  void Function(LigneCandidature ligne)? ouvrir,
  bool invitations = false,
  bool comptable = false,
  List<Override> surcharges = const <Override>[],
  String? depart,
  List<String> autres = const <String>[],
}) => monterRecrutement(
  tester,
  chemin: Routes.adminPersonnesCandidatures,
  depart: depart,
  // BE-LISTE : l'adresse porte le filtre, le tri et la page.
  ecran: (GoRouterState etat) => CandidaturesPage(
    ouvrirCandidature: ouvrir,
    requete: etat.uri.queryParameters,
  ),
  autres: <String>[
    ...autres,
    Routes.adminPersonnesInvitations,
    // CANDIDATS-FLUX : la route de l'import des formulaires.
    RoutesCandidatsFlux.importFormulaires,
  ],
  surcharges: <Override>[
    portCandidaturesDirectionProvider.overrideWithValue(port),
    portInvitationsEnseignantProvider.overrideWithValue(
      invitations ? InvitationsDemo() : null,
    ),
    portInvitationsComptableProvider.overrideWithValue(
      comptable ? InvitationsDemo() : null,
    ),
    ...surcharges,
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  echelle: echelle,
  direction: direction,
);

/// BE-LISTE : les liens de la liste (Invitations, Prevenir, Creneaux, Codes,
/// Importer) sont des entrees du menu « Outils ». Vrai si l'entree
/// [libelle] y est ; le menu est referme apres la lecture.
Future<bool> entreeOutilsPresente(WidgetTester tester, String libelle) async {
  final Finder menu = find.byKey(CandidaturesPage.cleOutils);
  if (menu.evaluate().isEmpty) return false;
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await laisser(tester);
  final bool present = find.text(libelle).evaluate().isNotEmpty;
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await laisser(tester);
  return present;
}

/// BE-LISTE : ouvre le menu « Outils » et touche l'entree [libelle].
Future<void> toucherOutil(WidgetTester tester, String libelle) async {
  final Finder menu = find.byKey(CandidaturesPage.cleOutils);
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await laisser(tester);
  await tester.tap(find.text(libelle));
  await laisser(tester);
}

/// BE-LISTE-2 : ouvre la feuille « Filtres » par son icone.
Future<void> ouvrirFeuilleFiltresDeTest(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(CandidaturesPage.cleFiltres));
  await tester.tap(find.byKey(CandidaturesPage.cleFiltres));
  await laisser(tester);
}

/// BE-LISTE-2 : dans la feuille « Filtres » ouverte, choisit [libelle] dans le
/// menu [cle] (par exemple `etat`), puis ferme la feuille.
Future<void> choisirDansFeuille(
  WidgetTester tester,
  String cle,
  String libelle,
) async {
  final Finder menu = find.byKey(ValueKey<String>('feuille-filtre-$cle'));
  await tester.ensureVisible(menu);
  await laisser(tester);
  await tester.tap(menu);
  await laisser(tester);
  await tester.tap(find.text(libelle).last);
  await laisser(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await laisser(tester);
}

/// BE-LISTE-2 : le tri se choisit dans la feuille « Trier ».
Future<void> choisirTri(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.byKey(CandidaturesPage.cleTri));
  await tester.tap(find.byKey(CandidaturesPage.cleTri));
  await laisser(tester);
  await tester.tap(find.text(libelle).last);
  await laisser(tester);
}
