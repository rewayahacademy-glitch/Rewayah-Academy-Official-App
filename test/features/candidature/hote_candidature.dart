// Le harnais de CAND-01 : la page du questionnaire (`/attente/candidature`) ou
// le portail (`/attente`) montes sur un routeur de test, avec le double du
// port du candidat et un service de dossier en memoire.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/candidature/candidature_page.dart';
import 'package:rewayah_academy/features/candidature/fuseau_etape.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';

/// L'etat d'un compte candidat (enseignant en attente) avec sa candidature.
EtatDossier etatCandidat({
  CandidatureDossier candidature = const CandidatureDossier(
    existe: true,
    etape: EtapeCandidature.prequalification,
    etat: EtatCandidature.aCompleter,
    version: 3,
    aCompleter: <String>['questionnaire'],
  ),
  AccountStatus statut = AccountStatus.pendingKyc,
  AppRole role = AppRole.teacher,
}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: statut,
  candidature: candidature,
);

/// Une candidature en Salle d'examen, a completer, cadre publie ou non.
CandidatureDossier candidatureAFaire({
  bool cadrePublie = true,
  bool cadreAccepte = true,
  List<String> complement = const <String>[],
  bool enPause = false,
  bool peutEnvoyer = true,
}) => CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.aCompleter,
  enPause: enPause,
  version: 3,
  cadre: EtatCadre(
    versionRequise: cadrePublie ? 'cadre-1' : null,
    accepte: cadreAccepte,
  ),
  conditionsDisponibles: true,
  versionConditions: 'v2.0.0',
  aCompleter: <String>[
    'questionnaire',
    if (cadrePublie && !cadreAccepte) 'cadre_religieux',
  ],
  complementDemande: complement,
  peutEnvoyer: peutEnvoyer,
);

/// Les routes de test : le portail, la page des accords (une pastille) et le
/// questionnaire.
List<RouteBase> routesCandidature() => <RouteBase>[
  GoRoute(
    path: Routes.attente,
    builder: (BuildContext _, GoRouterState _) => const AttentePage(),
  ),
  GoRoute(
    path: Routes.attenteAccords,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: Text('PAGE DES ACCORDS')),
  ),
  GoRoute(
    path: Routes.attenteCandidature,
    builder: (BuildContext _, GoRouterState _) => const CandidaturePage(),
  ),
];

/// Les surcharges communes.
List<Override> surchargesCandidature({
  required FauxMaCandidature port,
  required EtatDossier etat,
  FauxServiceDossier? dossier,
  bool horsLigne = false,
  String? fuseauAppareil = 'Europe/Paris',
}) => <Override>[
  serviceDossierProvider.overrideWithValue(
    dossier ?? (FauxServiceDossier()..etatRendu = etat),
  ),
  portMaCandidatureProvider.overrideWithValue(port),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
  fuseauAppareilCandidatureProvider.overrideWithValue(fuseauAppareil),
  horlogeCandidatureProvider.overrideWithValue(
    () => DateTime(2026, 10, 22, 14, 5),
  ),
];

/// Monte la page du questionnaire.
Future<void> monterQuestionnaire(
  WidgetTester tester, {
  required FauxMaCandidature port,
  EtatDossier? etat,
  Size taille = const Size(390, 844),
  double echelle = 1,
  bool horsLigne = false,
  String? fuseauAppareil = 'Europe/Paris',
  String depart = Routes.attenteCandidature,
  bool attendre = true,
  TextDirection? direction,
  ThemeMode themeMode = ThemeMode.light,
  FauxServiceDossier? dossier,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      routes: routesCandidature(),
      echelle: echelle,
      direction: direction,
      themeMode: themeMode,
      surcharges: surchargesCandidature(
        port: port,
        etat: etat ?? etatCandidat(candidature: candidatureAFaire()),
        dossier: dossier,
        horsLigne: horsLigne,
        fuseauAppareil: fuseauAppareil,
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Touche le widget de cle [cle], apres l'avoir rendu visible.
Future<void> toucherCle(WidgetTester tester, String cle) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  expect(f, findsOneWidget, reason: 'cle absente : $cle');
  await tester.ensureVisible(f);
  await tester.pump();
  // Le coin de debut de la carte, pas son centre : une carte decrite (texte,
  // consequence, exemple) peut depasser la zone visible a 320 de large et
  // texte x2, et son centre passe alors sous la barre du bas. Toute la carte se
  // touche (K-58) ; une personne touche ce qu'elle voit.
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

/// Appuie sur « Continuer ».
Future<void> continuer(WidgetTester tester) async {
  await toucherCle(tester, 'parcours-action');
}

/// Les cles des cartes de reponse d'un champ.
String optionCle(String champ, String code) => 'option-$champ-$code';

/// Les reponses d'un parcours complet, dans l'ordre ou le parcours pose les
/// questions : chacune est une suite de touches (cles) puis « Continuer ».
/// Le public est pose avant les disponibilites (la duree d'un cours en depend),
/// le fuseau juste avant elles ; elles tiennent en quatre ecrans quand les
/// heures sont les memes tous les jours (jours, heures, « memes heures ? »,
/// semaine).
const List<(String, List<String>)> parcoursComplet = <(String, List<String>)>[
  ('langueMaternelle', <String>['option-langueMaternelle-poular']),
  (
    'languesExplication',
    <String>[
      'option-languesExplication-poular',
      'option-languesExplication-francais',
    ],
  ),
  (
    'niveauMemorisationDeclare',
    <String>['option-niveauMemorisationDeclare-de_10_a_29_juz'],
  ),
  (
    'niveauLectureTajwid',
    <String>['option-niveauLectureTajwid-tajwid_applique'],
  ),
  ('riwayat', <String>['option-riwayat-hafs']),
  ('ijazaPresentable', <String>['option-ijazaPresentable-non']),
  ('experienceDebutants', <String>['option-experienceDebutants-oui']),
  ('publics', <String>['option-publics-6_9']),
  ('fuseauIana', <String>['fuseau-oui']),
  (
    'jours',
    <String>['option-jour-1', 'option-jour-3', 'option-jour-5'],
  ),
  ('heures', <String>['heure-1-18', 'heure-1-19']),
  ('memes', <String>['option-memes-oui']),
  ('semaine', <String>[]),
  ('classesSouhaitees', <String>['option-classesSouhaitees-1']),
  ('debutPossible', <String>['option-debutPossible-mois_prochain']),
  ('paysResidence', <String>['option-paysResidence-GN']),
  ('paysVersement', <String>[]),
  ('compteBancaire', <String>['option-compteBancaire-non']),
  ('operateurs', <String>['option-operateurs-orange_money']),
  ('moyensAccessibles', <String>['option-moyensAccessibles-wave']),
];

/// Passe la presentation (trois ecrans).
Future<void> passerLaPresentation(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await continuer(tester);
  }
}

/// Repond aux [n] premieres questions de [parcoursComplet], presentation
/// comprise.
Future<void> repondreJusqua(WidgetTester tester, int n) async {
  await passerLaPresentation(tester);
  for (final (String _, List<String> touches) in parcoursComplet.take(n)) {
    for (final String cle in touches) {
      await toucherCle(tester, cle);
    }
    await continuer(tester);
  }
}

/// Passe la presentation, puis repond aux questions de [parcoursComplet] qui
/// precedent celle nommee [champ] (un des noms du tableau) : l'ecran suivant est
/// celui de [champ].
Future<void> repondreAvant(WidgetTester tester, String champ) async {
  await passerLaPresentation(tester);
  for (final (String nom, List<String> touches) in parcoursComplet) {
    if (nom == champ) {
      return;
    }
    for (final String cle in touches) {
      await toucherCle(tester, cle);
    }
    await continuer(tester);
  }
  fail('aucune question nommee $champ dans parcoursComplet');
}
