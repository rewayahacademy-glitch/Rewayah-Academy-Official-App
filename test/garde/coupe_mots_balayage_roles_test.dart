// COUPE-MOTS-FOND-1 : la garde du rendu sur les coquilles des roles en
// demonstration, a chacune de leurs destinations : enseignant (Aujourd'hui,
// Mes Classes, Disponibilites, Profil), controleur (Controle, Historique,
// Echanges, Compte), tuteur (Accueil, Foyer, Historique, Compte), adulte
// (Accueil, Ma classe, Mon espace). Trois gabarits, francais et arabe,
// standard et Interface guidee (`test/support/balayage_ecrans.dart`).
//
// Hors balayage, ecrans d'autres voies de travail (fiche) : la salle et la
// classe en direct (TB), les Echanges du controleur restent mesures (ecran
// de role, pas de la voie COM), le Coran de l'adulte (rendu du Coran, hors
// perimetre de modification).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart';
import '../support/balayage_ecrans.dart';
import '../support/harnais.dart' show FausseSourceSession, FauxServiceAppairage;

List<Override> _aucune() => const <Override>[];

/// Les ecrans des coquilles de role.
List<EcranBalayage> ecransRoles() => <EcranBalayage>[
  for (final EcranDemoEnseignant e in <EcranDemoEnseignant>[
    EcranDemoEnseignant.aujourdhui,
    EcranDemoEnseignant.classes,
    EcranDemoEnseignant.disponibilites,
    EcranDemoEnseignant.profil,
  ])
    (
      nom: 'enseignant ${e.name}',
      page: null,
      routeur: (WidgetRef _) => GoRouter(
        initialLocation: adresseDemoEnseignant(e),
        routes: routesDemoEnseignant('dev'),
      ),
      depart: null,
      surcharges: _aucune,
    ),
  for (final EcranDemoControleur e in EcranDemoControleur.values)
    (
      nom: 'controleur ${e.name}',
      page: null,
      routeur: (WidgetRef _) => GoRouter(
        initialLocation: adresseDemoControleur(e),
        routes: routesDemoControleur('dev'),
      ),
      depart: null,
      surcharges: _aucune,
    ),
  for (final (String nom, String adresse) in <(String, String)>[
    ('accueil', Routes.tuteurAccueil),
    ('foyer', Routes.tuteurFoyer),
    ('historique', Routes.tuteurSuivi),
    ('compte', Routes.tuteurCompte),
  ])
    (
      nom: 'tuteur $nom',
      page: null,
      routeur: (WidgetRef ref) => ref.read(routeurProvider),
      depart: adresse,
      surcharges: () => surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.guardian)),
        appairage: FauxServiceAppairage()..elevesRendus = FoyersFictifs.foyerA,
      ),
    ),
  for (final EcranDemoAdulte e in <EcranDemoAdulte>[
    EcranDemoAdulte.accueil,
    EcranDemoAdulte.maClasse,
    EcranDemoAdulte.monEspace,
  ])
    (
      nom: 'adulte ${e.name}',
      page: null,
      routeur: (WidgetRef _) => GoRouter(
        initialLocation: adresseDemoAdulte(e),
        routes: routesDemoAdulte('dev'),
      ),
      depart: null,
      surcharges: _aucune,
    ),
];

void main() {
  balayer(ecransRoles());
}
