# 00 - Contrats partagés à stabiliser par le coordinateur avant les écritures parallèles

Date : 24/09/2026. Propositions fondées sur les rapports `C01` à `C11` et sur les signatures réelles du dépôt (relues : `service_appairage.dart:91-190, 287-302`, `service_planning.dart:74-155, 319-346`, `port_groupes.dart:20-52`, `port_horloge_seance.dart:21-66`, `fenetre_seance.dart:55-61`, `session_clock_vm.dart:21-25, 132-145`, `group_summary_vm.dart:114-209`, `port_politique_observation.dart:60-120, 307-326`, `port_visite_observation.dart:15-75, 155`, `guardian_session_visit.dart:102-114`, `service_presence.dart:23-67, 278`, `0033_tc_vues_rpc.sql:427-488`).

Principes communs :

- **Un contrat = un fichier possédé par COORD**, écrit et testé avant la phase parallèle ; les lots le consomment en lecture et soumettent une demande courte pour le changer.
- Les signatures suivent le patron du dépôt : interface, implémentation et provider dans le même voisinage, `Ref ref` sans racine d'injection, modèles `@immutable`, parsing strict (`depuisJson`).
- **Aucune constante métier** (quota, fenêtre, capacité, âge, tarif) ; toute valeur vient d'un service ou d'un état « indisponible ».
- **Temps** : instants en UTC, horloge serveur (`maintenant_serveur()`), heures affichées rendues par le serveur ; jamais `DateTime.now()` comme repli d'une date illisible.
- Une capacité absente lève `CapaciteIndisponible` (K5), jamais un faux succès ni une liste vide trompeuse.

Ordre de stabilisation recommandé : K5 → K1 → K2 → K3 → K4 → K6 → K7 (K8 en parallèle, c'est le chantier jetons et shell du coordinateur).

---

## K1 - Contexte de sélection d'élève

**Besoin** : Accueil (sélecteur, carte classe, préparation, dernière séance), Historique (sélecteur), Classe (élève concerné) doivent changer ensemble, sans données croisées (mandat §5 Accueil, §11.4). Aucun modèle d'élève sélectionné n'existe (`GroupHomeVM` n'a pas de `studentId`, `C06` §3.1).

**Fichier cible** : `lib/core/foyer/selection_eleve.dart` (nouveau).

**Services enveloppés** : `elevesDuFoyerProvider` (`profils_du_foyer_v`), `EleveDuFoyer`, `avatarUrlProvider` (`service_avatar.dart`).

```dart
/// Nature d'un profil élève sélectionnable. `titulaire` est réservé : il ne
/// sera produit que par DB-FOY-01, jamais par une fixture de production.
enum NatureProfilEleve { membreDuFoyer, titulaire }

@immutable
class ProfilEleveFoyer {
  const ProfilEleveFoyer({
    required this.eleveId,
    required this.prenom,
    required this.nature,
    required this.mode,
    required this.camera,
    this.cleAvatar,
    this.finAcces,
  });

  factory ProfilEleveFoyer.depuis(EleveDuFoyer e) => ProfilEleveFoyer(
        eleveId: e.id,
        prenom: e.prenom,
        nature: NatureProfilEleve.membreDuFoyer,
        mode: e.mode,
        camera: e.camera,
        cleAvatar: e.cleAvatar,
        finAcces: e.finAcces,
      );

  final String eleveId;
  final String prenom;
  final NatureProfilEleve nature;
  final InterfaceMode mode;
  final CameraPolicy camera;
  final String? cleAvatar;
  final DateTime? finAcces;
}

/// Profils élèves du foyer, dans l'ordre rendu par la vue.
final FutureProvider<List<ProfilEleveFoyer>> profilsElevesFoyerProvider;

/// L'identifiant demandé par l'utilisateur ou par l'URL (`?eleve=`).
class SelectionEleveControleur extends Notifier<String?> {
  @override
  String? build() => null;
  void choisir(String eleveId);
  void effacer();
}
final NotifierProvider<SelectionEleveControleur, String?> selectionEleveProvider;

/// Le profil effectivement sélectionné : l'identifiant demandé s'il figure
/// dans la liste du foyer, sinon le premier profil, sinon `null` (foyer vide).
final Provider<AsyncValue<ProfilEleveFoyer?>> eleveSelectionneProvider;
```

**Règles** :
- Tout bloc dépendant d'un élève lit `eleveSelectionneProvider` puis un provider `.family<_, String>` indexé par `eleveId` : un changement de profil reconstruit chaque bloc, aucune valeur d'un autre élève ne subsiste.
- Un `?eleve=` d'URL inconnu du foyer est ignoré (repli sur le premier) : la sélection n'est **jamais** une autorisation, la RLS décide.
- Mémoire de session seulement (survit aux changements de branche de la coquille, pas au redémarrage) ; aucun stockage persistant nouveau.
- Libellés : jamais « enfant » pour un profil `titulaire`.

**Consommateurs** : C (Accueil, Classe), E (Historique), B (fiche : lecture de la liste).
**Tests COORD** : repli sur le premier, id inconnu ignoré, foyer vide, changement de sélection sans valeur résiduelle (deux élèves fixtures).

---

## K2 - Séance du foyer : occurrence, fenêtre d'ouverture, fuseau

**Besoin** : prochaine séance (« Cours dans 3 h 28 », T-20, prolongée jamais négative), dernière séance, planning, historique, détail, avec « heure locale et fuseau utile » (mandat §5), statut annulé ou reporté distinct d'un cours normal.

**Constats qui fondent le contrat** : `Seance` (`mes_seances_v`) convertit en fuseau de l'appareil et remplace une date illisible par `DateTime.now()` (`service_planning.dart:93-98`) ; `horloge_seance()` rend heures rendues (fuseau du foyer et du groupe), `join_opens_at_utc`, fenêtre, grâce, instant serveur, **sans statut**, et n'autorise le tuteur que pour une séance de groupe (`0033:427-485`) ; le client n'a aucune bibliothèque de fuseaux ; `FenetreSeance`, `SessionClockVM`, `PhaseSeance`, `HorlogeAffichee` existent et sont sains (`C06` §3.3).

**Fichiers cibles** : `lib/core/seance_famille/seance_famille.dart` (modèle et fonction pure), `lib/core/seance_famille/port_seances_famille.dart` (port, adaptateur, providers). Corrections liées, par COORD : `lib/core/planning/service_planning.dart` (ligne illisible écartée au lieu de `DateTime.now()`, fichier partagé avec la journée enseignant) ; adaptateur v0 `lib/core/tc_horloge/horloge_supabase.dart` (lire `join_opens_at_utc`, supprimer `?? 0`, jours et mois en i18n).

**Services enveloppés** : `ServicePlanning.seances()` / `seancesProvider`, `HorlogeSeanceSupabase` (v0 : `horloge_seance`, `maintenant_serveur`), `presenceSeanceProvider`, `PortClassesFoyer` (K6).

[critique] Sur la base, seul `seancesProvider` est réel : `HorlogeSeanceSupabase` n'existe que dans `33503fe`, `portHorlogeSeanceProvider` sert `HorlogeSeanceDemonstration` (`port_horloge_seance.dart:54-55`) et `maintenant_serveur` n'est appelé nulle part dans `lib/`. Tant que P8 n'est pas acté, l'implémentation de production de `maintenantServeurUtc()` lève `CapaciteIndisponible('DB-TRV-07')` et `etatSeanceFamille` rend `horaireIncertain` (heure de l'appareil libellée comme telle) ; jamais le double de démonstration. Le test de table de vérité couvre ce cas.

```dart
/// État affichable d'une séance pour une famille. `reportee` est réservé :
/// jamais produit tant que le serveur ne le rend pas (DB-CRS-05).
enum EtatSeanceFamille {
  aVenir,          // avant la fenêtre
  salleOuverte,    // fenêtre ouverte, avant le début
  enDirect,
  prolongee,       // après la fin prévue, séance encore ouverte : jamais de compteur
  terminee,
  annulee,
  annuleeTardive,
  nonTenue,        // teacher_absent, tech_failure...
  reportee,
  horaireIncertain // aucune horloge serveur : pas d'état d'ouverture affirmé
}

@immutable
class EnseignantSeance {
  const EnseignantSeance({required this.prenom, this.titre, this.clePhoto});
  final String prenom;
  final TitreEnseignant? titre; // null = aucun titre affiché, jamais deviné
  final String? clePhoto;
}

@immutable
class SeanceFamille {
  const SeanceFamille({
    required this.seanceId,
    required this.eleveId,
    required this.debutUtc,
    required this.finPrevueUtc,
    required this.enseignant,
    this.groupeId,
    this.statutServeur,
    this.fenetre,
    this.heureFoyer,
    this.heureGroupe,
    this.minutesInterruption = 0,
  });

  final String seanceId;
  final String eleveId;
  final String? groupeId;              // null : séance hors groupe
  final DateTime debutUtc;
  final DateTime finPrevueUtc;
  final StatutSeance? statutServeur;   // mes_seances_v.status : prime sur l'horloge
  final FenetreSeance? fenetre;        // depuis join_opens_at_utc ; null sans horloge
  final HorlogeAffichee? heureFoyer;   // tz_utilisateur, rendue serveur
  final HorlogeAffichee? heureGroupe;  // tz_groupe, null si identique
  final EnseignantSeance enseignant;
  final int minutesInterruption;

  Duration get dureePrevue => finPrevueUtc.difference(debutUtc);
}

/// Pure, sans horloge d'appareil.
EtatSeanceFamille etatSeanceFamille(
  SeanceFamille s, {
  required DateTime maintenantServeurUtc,
  bool? seanceOuverteServeur,
});

/// Temps avant l'ouverture ou le début ; null si non applicable (jamais négatif).
Duration? restantAvant(SeanceFamille s, {required DateTime maintenantServeurUtc});

abstract interface class PortSeancesFamille {
  Future<SeanceFamille?> prochaine(String eleveId);
  Future<SeanceFamille?> derniere(String eleveId);
  Future<List<SeanceFamille>> historique({String? eleveId, DateTimeRange? periode});
  Future<SeanceFamille?> seance(String seanceId);

  /// Lève CapaciteIndisponible('DB-CRS-03') tant que le planning daté manque.
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  });

  Future<DateTime> maintenantServeurUtc();

  /// Un seul flux de rafraîchissement par séance, cadence décidée par
  /// l'implémentation (aucun Timer dans un widget).
  Stream<SeanceFamille> suivre(String seanceId);
}

final Provider<PortSeancesFamille> portSeancesFamilleProvider;
final FutureProviderFamily<SeanceFamille?, String> prochaineSeanceProvider; // par eleveId
final FutureProviderFamily<SeanceFamille?, String> derniereSeanceProvider;  // par eleveId
```

**Règles** :
- `statutServeur` annulé ou non tenu prime sur toute phase d'horloge (l'horloge ne connaît pas le statut).
- Fenêtre d'ouverture = `join_opens_at_utc` rendu ; jamais `pre_vol.dart:22` (10 min) ni `billet_salle.dart:31` (20 min) côté tuteur.
- Affichage de l'heure : `heureFoyer` avec libellé de ville/fuseau ; `heureGroupe` en second seulement si différente. Sans horloge serveur (séance hors groupe, refus, panne) : heure de l'appareil explicitement libellée « heure de cet appareil », état `horaireIncertain`, pas de « Salle ouverte ».
- « Cours dans {h} h {mm} » via `LibellesGroupe.compteARebours` ; prolongée sans nombre ; aucun libellé « … en cours » (contradiction X5).
- Dernière séance : présence via `presenceSeanceProvider` et la table d'affichage unique de `LignePresence` ; « En cours de vérification » pour une séance terminée non consolidée (DB-HIS-04).

**Consommateurs** : C (Accueil, Classe, planning), E (Historique, détail), C-obs (séance en cours pour l'entrée d'observation).
**Tests COORD** : table de vérité `etatSeanceFamille` (avant fenêtre, T-20, début, en direct, prolongée, fin + grâce, annulée, annulée tardive, horloge absente), changement d'heure (fixture de deux heures rendues), aucune valeur négative.

---

## K3 - Formulaire élève partagé (Admission et Foyer)

**Besoin** : un seul flux d'ajout de profil élève depuis Accueil vide, Foyer, Compte et la fin de l'admission familiale (mandat §6, lot A « utilise le flux commun », lot B « possède le formulaire après contrat stable »), sans dépendance circulaire.

**Constats** : `ServiceAppairage.creerEnfant({prenom, nom, age, niveau})` rend `void` (`service_appairage.dart:159-164`) : l'identifiant créé se relit dans `elevesDuFoyerProvider` ; serveur : compte `active|provisional_active` exigé (`0004:850-858`), âge 3-99, `minor` forcé ; borne client 3-18 (`ajouter_enfant_page.dart:44`) ; pas d'idempotence.

**Fichiers cibles** : `lib/core/foyer/profil_eleve_brouillon.dart` (modèle et validation, COORD) ; `lib/core/foyer/port_creation_profil_eleve.dart` (port et adaptateur, COORD) ; `lib/features/foyer/formulaire_profil_eleve.dart` (widget, **B** dès que les deux premiers sont figés).

**Service enveloppé** : `ServiceAppairage.creerEnfant` (Edge `creer-profil-enfant`).

```dart
enum PourQui { enfantOuMineur, procheAdulte, moiMeme }
enum ChampProfilEleve { pourQui, prenom, nom, age }
enum ErreurChamp { requis, horsBornes }

@immutable
class BornesAge {
  const BornesAge({required this.min, required this.max});
  /// Borne client existante ; la borne serveur fait foi.
  static const BornesAge clientActuelle = BornesAge(min: 3, max: 18);
  final int min;
  final int max;
}

@immutable
class BrouillonProfilEleve {
  const BrouillonProfilEleve({
    this.pourQui = PourQui.enfantOuMineur,
    this.prenom = '',
    this.nom = '',
    this.age,
  });
  final PourQui pourQui;
  final String prenom;
  final String nom;
  final int? age; // date de naissance réservée à DB-ADM-05
  BrouillonProfilEleve copyWith({PourQui? pourQui, String? prenom, String? nom, int? age});
  Map<ChampProfilEleve, ErreurChamp> valider(BornesAge bornes);
}

sealed class ResultatCreationProfil { const ResultatCreationProfil(); }
final class ProfilCree extends ResultatCreationProfil {
  const ProfilCree({this.eleveId}); // null : relire le foyer (l'Edge ne rend pas l'id au client)
  final String? eleveId;
}
final class CreationRefusee extends ResultatCreationProfil {
  const CreationRefusee(this.motif);
  final MotifRefusCreation motif;
}
final class CreationIncertaine extends ResultatCreationProfil {
  const CreationIncertaine(); // réponse perdue : vérifier le foyer avant de réessayer (DB-FOY-06)
}
enum MotifRefusCreation { compteNonValide, ageHorsBornes, refuse }

abstract interface class PortCreationProfilEleve {
  /// Faux pour procheAdulte (DB-FOY-02) et moiMeme (DB-FOY-01), et pour tout
  /// compte non actif (DB-ADM-04).
  bool peutCreer(PourQui pourQui, {required PorteAcces porte});
  Future<ResultatCreationProfil> creer(BrouillonProfilEleve brouillon);
}
final Provider<PortCreationProfilEleve> portCreationProfilEleveProvider;

enum ContexteFormulaire { admission, foyer, compte }

class FormulaireProfilEleve extends ConsumerStatefulWidget {
  const FormulaireProfilEleve({
    super.key,
    required this.contexte,
    required this.onTermine, // (ProfilCree) -> enchaînement (questionnaire, fiche)
    this.onRetour,
    this.initial = const BrouillonProfilEleve(),
  });
  final ContexteFormulaire contexte;
  final ValueChanged<ProfilCree> onTermine;
  final VoidCallback? onRetour;
  final BrouillonProfilEleve initial;
}
```

**Règles** : erreurs sous les champs ; double soumission bloquée (`enCours`) ; `CreationIncertaine` → relecture du foyer puis choix explicite de l'utilisateur ; « Pour moi » et « Pour un proche adulte » visibles mais indisponibles, expliqués ; brouillon en mémoire seulement (données d'un mineur). L'admission n'héberge pas le formulaire avant validation du dossier : elle y enchaîne à l'arrivée en porte `actif` (contradiction X11, point P5).

**Consommateurs** : B (route `/tuteur/foyer/ajouter`), A (enchaînement fin d'admission → formulaire → questionnaire), E (lien depuis Compte).

---

## K4 - Observation : politique, budget, disponibilité, visite, historique

**Besoin** : avant l'entrée « visites disponibles et durée », pendant « Visite 1/2 · 01:42 », après « visites restantes », motifs d'indisponibilité, historique tuteur et admin sans second système (complément §5, §8), sans jamais activer l'observation réelle sur une protection locale (complément §3).

**Existant à stabiliser** : `GuardianObservationPolicy` (+ `defautsNormatifs` périmés 1/120, `guardian_observation_policy.dart:74-80`), `BudgetObservation` (`port_politique_observation.dart:60-120`), `politiqueObservationProvider` (par `groupeId`) et `budgetObservationProvider` (par `seanceId`, inutilisé, `:313-326`), `ResultatEntreeObservation`, `PortVisiteObservation.entrer/sortir/visites` (`port_visite_observation.dart:15-75`), `GuardianSessionVisit` (`guardian_session_visit.dart:102-114`, repli 1970 et rôle tuteur si clés absentes), `FinDeVisite`, `MotifRefusObservation` (6 motifs, `null` sur valeur inconnue), `EtatPresence` (`service_presence.dart:23-67`).

**Fichiers cibles** : existants `lib/core/tc_observation/{guardian_observation_policy,guardian_session_visit,port_politique_observation,port_visite_observation,echec_observation}.dart` (COORD, après reprise de la branche observation) ; nouveaux `lib/core/tc_observation/disponibilite_observation.dart` et `lib/core/tc_observation/port_historique_observations.dart` (COORD).

```dart
enum MotifIndisponibilite {
  visitesEpuisees,
  tempsEpuise,
  seanceNonCommencee,
  seanceTerminee,
  observationDesactivee,
  lienAbsent,
  enfantAbsent,              // réservé : produit seulement par le serveur (DB-OBS-05)
  presenceEnVerification,    // indicatif, depuis presence_seance_v
  visiteDejaOuverte,         // 23505 traduit (DB-OBS-06)
  garantieServeurAbsente,    // activation réelle coupée (point P3)
  reseau,
  capaciteAbsente,
}

sealed class DisponibiliteObservation { const DisponibiliteObservation(); }
final class ObservationPossible extends DisponibiliteObservation {
  const ObservationPossible({
    required this.visitesUtilisees,
    required this.visitesMax,
    required this.dureeProchaineVisite, // = budget.restant (borné par visite côté serveur)
    required this.policyVersion,
  });
  final int visitesUtilisees;
  final int visitesMax;
  final Duration dureeProchaineVisite;
  final String policyVersion;
  int get visitesRestantes => visitesMax - visitesUtilisees;
}
final class ObservationIndisponible extends DisponibiliteObservation {
  const ObservationIndisponible(this.motif, {this.visitesRestantes});
  final MotifIndisponibilite motif;
  final int? visitesRestantes;
}

/// Pure. `activationReelle` vient d'un interrupteur de compilation (Env),
/// faux par défaut jusqu'aux garanties DB-OBS-01, 02, 03, 05.
DisponibiliteObservation disponibiliteObservation({
  required BudgetObservation? budget,
  required GuardianObservationPolicy? politique,
  required EtatPresence? presenceEnfant,
  required bool activationReelle,
});

/// « Visite 1/2 · 01:42 » : rang = visitesUtilisees (0039 compte la visite en
/// cours), temps = dernier restant serveur, jamais allongé localement.
@immutable
class CompteurVisite {
  const CompteurVisite({required this.rang, required this.total, required this.restant, required this.confirmeParServeur});
  final int rang;
  final int total;
  final Duration restant;
  final bool confirmeParServeur; // faux : « Temps restant non confirmé »
}

@immutable
class ObservationsSeance {
  const ObservationsSeance({
    required this.seanceId,
    required this.visites,
    this.enfantId,
    this.groupeId,
  });
  final String seanceId;
  final String? enfantId;
  final String? groupeId;
  final List<GuardianSessionVisit> visites;
  int get nombreVisites => visites.length;
  /// null si une visite n'a pas de sortie : « Durée non confirmée ».
  Duration? get dureeTotaleConfirmee;
}

abstract interface class PortHistoriqueObservations {
  /// Lecture directe de guardian_session_visit sous RLS (observateur = soi),
  /// groupée par (séance, enfant). Ligne incomplète écartée, jamais complétée.
  Future<List<ObservationsSeance>> mesObservations({String? enfantId, DateTimeRange? periode});
  Future<ObservationsSeance?> detail({required String seanceId, String? enfantId});
}

@immutable
class FiltreObservationsAdmin {
  const FiltreObservationsAdmin({this.tuteurId, this.eleveId, this.groupeId, this.periode, this.seulementOuvertes = false});
  final String? tuteurId;
  final String? eleveId;
  final String? groupeId;
  final DateTimeRange? periode;
  final bool seulementOuvertes;
}
abstract interface class PortHistoriqueObservationsAdmin {
  Future<({List<ObservationsSeance> lignes, String? curseur})> rechercher(
    FiltreObservationsAdmin filtre, {String? curseur});
}
```

**Règles** : l'UI n'affiche jamais `defautsNormatifs` (valeurs alignées 2/240/120 à la reprise, mais réservées aux tests) ; sans politique ni budget lisibles : « Durée non disponible » et CTA retiré ; le compteur ne démarre qu'après `entrer` accordé ; sortie de page, arrière-plan et `dispose` appellent `sortir` ; libellé de fin historique générique « Visite terminée » tant que DB-OBS-04 manque ; texte d'aide paramétré par la politique effective (A fournit le texte, C-obs l'intègre).

**Consommateurs** : C-obs (entrée, salle, fin), E (onglet Observations, détail, écran admin), A (texte d'explication et de consentement paramétré).

---

## K5 - Famille d'états système et capacités indisponibles

**Besoin** : mandat §8 (bloc et page, un titre humain, une phrase, une action, un lien secondaire, aucun code technique) ; aujourd'hui seuls `Skeleton`, `OfflineBanner` (binaire), `EmptyState`, `LocalFeedback`, `AttentePage` existent ; aucun `errorBuilder` ; aucune politique de délai (`C02` §14.1).

**Fichiers cibles** (COORD) : `lib/core/widgets/etat_systeme.dart`, `lib/core/widgets/bloc_asynchrone.dart`, `lib/core/theme/app_delais.dart`, `lib/core/capacites/capacite_indisponible.dart`, `errorBuilder` et validation du `retour` dans `lib/core/router/{app_router,redirection}.dart`, clés `commun.etats.*`.

**Composants enveloppés** : `EmptyState` (grammaire icône-titre-phrase-action), `ActionPrincipale`, `Skeleton`, `OfflineBanner` (`horsLigneProvider`), `PageShell`.

```dart
enum NatureEtat {
  chargementProlonge, horsLigne, reconnexion, echecServeur, introuvable,
  accesRefuse, sessionExpiree, dossierEnAttente, aucunResultat,
  permissionRefusee, ressourceExpiree, indisponible,
}
enum PorteeEtat { bloc, page }

class EtatSysteme extends StatelessWidget {
  const EtatSysteme({
    super.key,
    required this.nature,
    this.portee = PorteeEtat.bloc,
    this.titre,            // défaut i18n par nature
    this.phrase,
    this.libelleAction,
    this.onAction,
    this.libelleSecondaire,
    this.onSecondaire,
    this.dependance,       // ex. 'DB-CPT-03' : jamais affiché, seulement en clé de test
  });
}

/// AsyncValue -> squelette, puis « chargement prolongé » après
/// AppDelais.chargementProlonge, erreur de bloc qui conserve la page, contenu.
class BlocAsynchrone<T> extends StatelessWidget {
  const BlocAsynchrone({
    super.key,
    required this.valeur,
    required this.squelette,
    required this.construire,
    this.onReessayer,
    this.vide, // Widget? : état « aucun résultat »
  });
  final AsyncValue<T> valeur;
  final Widget squelette;
  final Widget Function(T valeur) construire;
  final VoidCallback? onReessayer;
  final Widget? vide;
}

/// Seuils frontend documentés (aucune politique réseau serveur n'existe, DB-TRV-03).
abstract final class AppDelais {
  static const Duration chargementProlonge = Duration(seconds: 8); // proposition
  static const Duration requeteMax = Duration(seconds: 20);        // proposition
}

class CapaciteIndisponible implements Exception {
  const CapaciteIndisponible(this.dependance);
  final String dependance; // identifiant DB-xxx
}

/// Chemin interne autorisé comme destination de retour, sinon null.
String? cheminRetourValide(String? brut); // refuse URL absolue, /salle, /tc/classe, /agent
```

**Règles** : `BlocAsynchrone` traduit `CapaciteIndisponible` en `NatureEtat.indisponible` (pas en erreur) ; une réponse arrivée après la sortie d'écran est ignorée (garde de génération ou `ref.onDispose`) ; « Réessayer » borné, jamais de boucle ; aucun libellé « bientôt » qui promet une date. Variantes de dialogue desktop pour `ConfirmDestructive` et `AppBottomSheet` (pas de feuille mobile étirée) livrées dans le même lot COORD.

**Consommateurs** : tous les lots.

[critique] `NatureEtat` ne porte pas « suspendu » (mandat §8 « Dossier en attente / suspendu ») : pas d'oubli bloquant, la porte `PorteAcces.suspendu` renvoie déjà vers `/attente` (`redirection.dart:64-68`) où A affiche le statut exact ; `dossierEnAttente` ne sert qu'aux blocs internes.

---

## K6 - Ports et adaptateurs frontend des capacités

Chaque port : interface fondée sur le besoin de l'écran, **adaptateur réel** quand une source existe, sinon implémentation `…Indisponible` qui lève `CapaciteIndisponible(DB-xxx)` ; provider de production = adaptateur réel ou indisponible, jamais une fixture. Fichier du port : COORD dans `lib/core/capacites/` quand au moins deux lots le consomment ; un port consommé par un seul lot (`LecteurQr`, `PortStatutCodeAppairage`) appartient à ce lot avec son adaptateur. Fichier de l'adaptateur : lot indiqué (voir `00_OWNERSHIP.md` §3).

| Port (fichier proposé) | Signature proposée | Source existante enveloppée | Production | Adaptateur | Dépendance |
|---|---|---|---|---|---|
| `PortClassesFoyer` (`lib/core/capacites/port_classes_foyer.dart`) | `Future<List<ClasseFoyer>> classesDe(String eleveId)` ; `Future<ClasseFoyer?> classe({required String groupeId, required String eleveId})` ; `ClasseFoyer` = `GroupSummaryVM` + `eleveId` | `GroupesSupabase` (v0, `mes_groupes_famille_v`) + lecture `groupe_membres` (RLS foyer, `0019:322-335`) | réel (classes courantes) **après P8 seulement** [critique] : `GroupesSupabase` n'existe pas sur la base (`33503fe`), sinon « indisponible » (DB-TRV-07) | C | DB-CRS-01 (classes quittées), DB-TRV-07 |
| `PortCatalogueClasses` (`lib/core/capacites/port_catalogue_classes.dart`) | `Future<List<ClasseOuverte>> compatibles({required String eleveId, required String fuseauIana})` ; `Future<ResultatInscription> inscrire({required String classeId, required String eleveId, required String cleIdempotence})` | aucune | indisponible | - | DB-CRS-07, 08 (P1) |
| `PortTravailFamille` (réutilise `PortAssignations`, `PortTravailAVenir`) | lecture `Future<List<SlotAction>> travail({required String groupeId, required String eleveId})` ; `Future<void> marquerFait(String assignationId)` | `learning_assignment` (policy famille `0032:385-394`) | lecture réelle, écriture indisponible | C | DB-CRS-10 |
| `PortCatalogue` (existant, `lib/core/tc_bibliotheque/port_catalogue.dart`) | inchangé | RPC `ressources_du_groupe` (visibilité `0035`) | réel à écrire ; lecteur PDF absent | C | - |
| `PortProgressionFamille` | `Future<ProgressionEleve> progression(String eleveId)` | aucune | indisponible | - | DB-CRS-11 |
| `PortResumeSeanceFamille` | `Future<String?> resume({required String seanceId, required String eleveId})` | aucune (jamais `lesson_reports`) | indisponible | - | DB-CRS-12 |
| `PortStatutCodeAppairage` (`lib/core/appairage/statut_code_appairage.dart`) | `Stream<StatutCode> suivre({required String eleveId, required DateTime expireA})` avec `StatutCode {actif, consomme, remplace, expire, inconnu}` ; `Future<void> annuler(String eleveId)` | vue `mes_codes_appairage_v` (scrutation bornée) | réel **si** la lecture est mesurée accordée, sinon `inconnu` ; `annuler` indisponible | D | DB-APP-01, 02 |
| `LecteurQr` (`lib/core/appairage/lecteur_qr.dart`) | `Future<EtatCamera> demarrer()` ; `Future<void> arreter()` ; `Stream<String> get lectures` ; `EtatCamera {pret, refusee, refuseeDurablement, occupee, absente, nonSupportee, erreur}` | `mobile_scanner` (à ajouter par COORD) | réel Android, iOS, web ; `LecteurQrIndisponible` sur Windows et Linux | D | - |
| `PortIdentiteTitulaire` (`lib/core/capacites/port_identite_titulaire.dart`) | `Future<IdentiteTitulaire> lire()` (prénom, nom, courriel, méthode de connexion, statut) ; `Future<void> modifier(...)` | `profiles` self (`profiles_self_select`), `auth.currentUser` | lecture réelle, modification indisponible | E | DB-CPT-01 |
| `PortAccesFoyer` | `Future<List<AccesBeneficiaire>> acces()` ; `AccesBeneficiaire {eleveId, prenom, finAcces?, etatAffiche (sansEcheance, actif, expire), statutServeur? (null), motif? (null)}` | `EleveDuFoyer.finAcces` | réel partiel | E (Compte), B (fiche) lisent le même adaptateur, écrit par E | DB-FOY-05 |
| `PortPaiementsFoyer` | `Future<List<PaiementFoyer>> historique()` ; `Future<PaiementFoyer?> detail(String id)` ; `PaiementFoyer {montant, devise, statut, date, justificatifDisponible}` | aucune | indisponible | - | DB-CPT-03 |
| `PortNotifications` | `Future<List<NotificationTuteur>> liste()` ; `Future<NotificationTuteur?> detail(String id)` ; `NotificationTuteur {id, titre, date, destination (chemin interne validé)}` | aucune | indisponible | - | DB-CPT-04 |
| `PortSupport` | `Future<CanalSupport?> canal()` | aucune | indisponible | - | DB-CPT-07 |
| `PortConsentements` (`lib/core/capacites/port_consentements.dart`) | `Future<List<AcceptationSignee>> signees()` ; `Future<List<ConsentementRequis>> aRenouveler()` ; `Future<void> accepter({required ContractKind sorte, required String version})` | `ServiceAcceptations` (lecture), insert `contract_acceptances` (policy self) | lecture réelle ; `aRenouveler` indisponible ; `accepter` réel mais appelé seulement après décision P2 | A | DB-ADM-02, 03 |
| `PortProfilEleveTitulaire` | `Future<bool> existe()` ; `Future<void> creer()` ; `Future<void> ouvrirEspaceEleve()` | aucune | indisponible | - | DB-FOY-01 |
| `PortPreferencesPersistantes` | `Future<PreferencesLocales?> charger()` ; `Future<void> enregistrer(PreferencesLocales p)` | `PreferencesLocales` (mémoire) | mémoire tant que COORD n'a pas choisi un stockage local | COORD | DB-CPT-09 (frontend) |

---

## K7 - Fixtures isolées

**Règle du mandat** (§3) : les fixtures vivent dans les tests ou un environnement de démonstration explicitement isolé, jamais comme repli silencieux de production.

**Constat** : la production sert aujourd'hui deux doubles sans condition, `GroupesDemonstrationLocale` (`port_groupes.dart:37-39`) et `HorlogeSeanceDemonstration` (`port_horloge_seance.dart:54-55`) ; `33503fe` introduit le bon patron `portGroupesSelon(demo: Env.playgroundActif)`.

**Où** :
- **Tests** : `test/fixtures/tuteur/` (nouveau), un fichier par port : `faux_seances_famille.dart`, `faux_classes_foyer.dart`, `faux_observation.dart` (politique, budget, entrées accordées et refusées, visites ouvertes et fermées), `faux_historique_observations.dart`, `faux_appairage.dart` (codes actif, consommé, remplacé, expiré), `faux_lecteur_qr.dart`, `faux_identite_titulaire.dart` ; profils fictifs sans nom ni photo réels ; deux foyers pour les tests de non-croisement. Horloge serveur injectée (instant figé), jamais `DateTime.now()`.
- **Démonstration** : Playground existant (`lib/features/_dev/playground/`, `Env.playgroundActif`, `PLAYGROUND=true`), étendu par COORD avec des personas tuteur (Accueil jour J, T-20, en direct, prolongée, annulée ; foyer vide ; appairage ; observation 2, 1, 0 visite). Aucune autre voie d'activation.
- **Captures de recette** : `capture_proto_test.dart` de `C11` (hors dépôt, ou `test/capture/` sauté sans `CAPTURE_DIR`), qui charge les vraies polices et monte le vrai routeur avec une session factice.

**Comment** :
- Providers de production = adaptateur réel ou `…Indisponible` ; surcharge **uniquement** par `ProviderScope(overrides: …)` dans les tests, ou par un sélecteur compilé sur `Env.playgroundActif` (patron `33503fe`), appliqué aussi à `portGroupesProvider` et `portHorlogeSeanceProvider`.
- Aucun `catch (_) => fixture`, aucune liste vide renvoyée à la place d'une erreur.
- Contrôle automatique proposé (COORD, `tool/verifier_jetons.dart` ou test) : aucune classe `*Demonstration*`, `*Memoire`, `Faux*` instanciée dans un provider hors `lib/features/_dev/` et hors branche `playgroundActif`.

---

## K8 - Contrats du shell et des jetons consommés par tous (COORD, pour mémoire)

- `destinationsPour(guardian)` : Accueil, Foyer, Historique, Compte ; icônes `AppIcons.accueil`, `foyer`, nouvelle entrée horloge (à relever dans la police Phosphor, jamais devinée), `profil` ; `secondairesPour(guardian)` vide.
- `PageShell` : ajout d'un en-tête à actions (`actionsEntete`, retour rond 48 dp, sous-titre) et d'un mode « tâche focalisée » sans barre basse sur mobile ; correction de la double zone sûre observée par `C11` §5.6 (barre dans une `Column` + `SafeArea` complet du corps).
- Typographie : `AppFontFamily.corps = 'PlusJakartaSans'`, `AppFontFamily.titre = 'DMSans'` (valeurs remplacées, noms de constantes conservés), `_titre()` avec `opsz` explicite, `AppTypography.chiffre(TextStyle)` Jakarta tabulaire ; règle `police-hors-typographie` dans le vérificateur.
- Jetons d'arbitrage visuel du manifeste (`surfaceActionDouce`, `surfaceMiseEnAvant`, points de statut, `inkFaint`, `inkAccent`) ; palette sombre selon P9.
- i18n : un seul fichier `assets/i18n/fr.i18n.json` possédé par COORD ; espaces de noms réservés par lot (voir `00_OWNERSHIP.md` §4).
