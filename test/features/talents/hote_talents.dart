// Le harnais de CAND-07 : la page « Vos autres talents » (`/attente/talents`) ou
// le portail (`/attente`) montes sur un routeur de test, avec le double du port
// des autres competences et un service de dossier en memoire.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/talents/talents_page.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';
import '../../support/harnais.dart';
import '../candidature/hote_candidature.dart' show etatCandidat;

/// Une candidature envoyee, en Salle d'examen : la direction lit les reponses.
const CandidatureDossier candidatureEnvoyee = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  version: 4,
);

/// Les routes de test : le portail et la page.
List<RouteBase> routesTalents() => <RouteBase>[
  GoRoute(
    path: Routes.attente,
    builder: (BuildContext _, GoRouterState _) => const AttentePage(),
  ),
  GoRoute(
    path: Routes.attenteTalents,
    builder: (BuildContext _, GoRouterState _) => const TalentsPage(),
  ),
];

/// Les surcharges communes. [port] `null` : aucun lot serveur (le port est
/// absent).
List<Override> surchargesTalents({
  required FauxAutresCompetences? port,
  required EtatDossier etat,
  FauxServiceDossier? dossier,
  bool horsLigne = false,
}) => <Override>[
  serviceDossierProvider.overrideWithValue(
    dossier ?? (FauxServiceDossier()..etatRendu = etat),
  ),
  portAutresCompetencesProvider.overrideWithValue(port),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
];

/// L'etat d'un compte candidat dont la candidature est envoyee.
EtatDossier etatEnvoye({CandidatureDossier candidature = candidatureEnvoyee}) =>
    etatCandidat(candidature: candidature);

/// Monte la page (ou le portail) sur le routeur de test.
Future<void> monterTalents(
  WidgetTester tester, {
  required FauxAutresCompetences? port,
  EtatDossier? etat,
  FauxServiceDossier? dossier,
  Size taille = const Size(390, 844),
  double echelle = 1,
  bool horsLigne = false,
  String depart = Routes.attenteTalents,
  bool attendre = true,
  TextDirection? direction,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      routes: routesTalents(),
      echelle: echelle,
      direction: direction,
      themeMode: themeMode,
      surcharges: surchargesTalents(
        port: port,
        etat: etat ?? etatEnvoye(),
        dossier: dossier,
        horsLigne: horsLigne,
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Le finder d'un widget par sa cle.
Finder cleTalents(String cle) => find.byKey(ValueKey<String>(cle));

/// Touche le widget de cle [cle], apres l'avoir rendu visible.
Future<void> toucherTalents(WidgetTester tester, String cle) async {
  final Finder f = cleTalents(cle);
  expect(f, findsOneWidget, reason: 'cle absente : $cle');
  await tester.ensureVisible(f);
  await tester.pump();
  // Le coin de debut de la carte, pas son centre : une carte decrite peut
  // depasser la zone visible et son centre passer sous la barre du bas.
  final Rect zone = tester.getRect(f);
  await tester.tapAt(
    zone.topLeft +
        Offset(
          zone.width < 48 ? zone.width / 2 : 24,
          zone.height < 48 ? zone.height / 2 : 24,
        ),
  );
  await tester.pumpAndSettle();
}

/// Touche un texte, apres l'avoir rendu visible : amene vers le haut de la
/// zone qui defile, pour qu'il ne passe jamais sous la barre du bas (sur
/// 320 de large, texte x2, cette barre prend plus de la moitie de l'ecran).
Future<void> toucherTexteTalents(WidgetTester tester, Finder texte) async {
  expect(texte, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(texte), alignment: 0.1);
  await tester.pump();
  await tester.tap(texte);
  await tester.pumpAndSettle();
}

/// Appuie sur « Continuer » (ou « Enregistrer mes reponses » a la fin).
Future<void> continuerTalents(WidgetTester tester) =>
    toucherTalents(tester, 'parcours-action');

/// Le parcours jusqu'a l'etape des competences (apres l'introduction).
Future<void> passerLIntroduction(WidgetTester tester) =>
    continuerTalents(tester);

/// Les niveaux d'un exemple de parcours.
const Map<String, NiveauCompetence> niveauxDeTest = <String, NiveauCompetence>{
  'comptabilite': NiveauCompetence.metier,
  'reseaux_sociaux': NiveauCompetence.experience,
};
