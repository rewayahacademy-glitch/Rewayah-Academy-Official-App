import 'dart:async';

import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';

/// Une horloge que le test deplace a sa guise.
///
/// **C'est l'outil de l'attaque autant que celui du confort.** La reculer
/// simule exactement ce que ferait quelqu'un qui voudrait se donner du temps en
/// changeant l'heure de sa machine.
class HorlogeReglable {
  /// Cree une horloge posee a un instant fixe.
  HorlogeReglable([DateTime? depart])
    : _instant = depart ?? DateTime.utc(2026, 9, 20, 10);

  DateTime _instant;

  /// L'instant courant.
  DateTime lire() => _instant;

  /// Avance l'horloge.
  void avancer(Duration duree) => _instant = _instant.add(duree);

  /// Recule l'horloge.
  void reculer(Duration duree) => _instant = _instant.subtract(duree);
}

/// Un budget serveur, ecrit court.
BudgetObservation unBudget({
  Duration restant = const Duration(seconds: 120),
  Duration total = const Duration(seconds: 120),
  int visitesUtilisees = 1,
  int visitesMax = 1,
  bool peutEntrer = true,
  MotifRefusObservation? motifRefus,
  String policyVersion = 'p1',
  bool visiteEnCours = false,
}) => BudgetObservation(
  policyVersion: policyVersion,
  visitesUtilisees: visitesUtilisees,
  visitesMax: visitesMax,
  tempsConsomme: total - restant,
  tempsTotalMax: total,
  restant: restant,
  peutEntrer: peutEntrer,
  motifRefus: motifRefus,
  visiteEnCours: visiteEnCours,
);

/// Un intervalle de visite ouvert par le serveur.
GuardianSessionVisit uneVisite({
  String sessionId = 's1',
  String? enfantConcerneId = 'enfant-1',
  RoleObservateur role = RoleObservateur.tuteur,
  int visitNumber = 1,
}) => GuardianSessionVisit(
  id: 'v1',
  sessionId: sessionId,
  groupeId: 'g1',
  observateurProfilId: 'tuteur-1',
  role: role,
  enfantConcerneId: enfantConcerneId,
  enteredAtUtc: DateTime.utc(2026, 9, 20, 10),
  visitNumber: visitNumber,
  policyVersion: 'p1',
);

/// La porte d'observation, remplacee.
class FauxPortVisite implements PortVisiteObservation {
  /// Cree la porte.
  FauxPortVisite({this.reponse, this.echecEntree, this.echecSortie});

  /// Ce que le serveur repond a une entree.
  ResultatEntreeObservation? reponse;

  /// L'echec leve a l'entree, s'il y en a un.
  EchecObservation? echecEntree;

  /// L'echec leve a la sortie, s'il y en a un.
  EchecObservation? echecSortie;

  /// Les roles demandes, dans l'ordre.
  final List<RoleObservateur> rolesDemandes = <RoleObservateur>[];

  /// Les seances quittees, dans l'ordre.
  final List<String> sorties = <String>[];

  /// Quand il est pose, l'entree attend qu'il soit complete : la demande est
  /// « en vol », comme une reponse serveur qui tarde.
  Completer<void>? entreeSuspendue;

  @override
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  }) async {
    rolesDemandes.add(role);
    final Completer<void>? suspension = entreeSuspendue;
    if (suspension != null) {
      await suspension.future;
    }
    final EchecObservation? echec = echecEntree;
    if (echec != null) {
      throw echec;
    }
    return reponse ??
        ResultatEntreeObservation(
          autorise: true,
          visite: uneVisite(sessionId: sessionId, role: role),
          budget: unBudget(),
        );
  }

  @override
  Future<void> sortir({required String sessionId}) async {
    sorties.add(sessionId);
    final EchecObservation? echec = echecSortie;
    if (echec != null) {
      throw echec;
    }
  }

  @override
  Future<List<GuardianSessionVisit>> visites({
    required String sessionId,
  }) async => <GuardianSessionVisit>[uneVisite(sessionId: sessionId)];
}

/// La politique et le budget, remplaces.
class FauxPortPolitique implements PortPolitiqueObservation {
  /// Cree le port.
  FauxPortPolitique({GuardianObservationPolicy? politique})
    : politique =
          politique ??
          const GuardianObservationPolicy.defautsNormatifs(policyVersion: 'p1');

  /// La politique rendue.
  GuardianObservationPolicy politique;

  /// Le budget rendu par la lecture ponctuelle : celui qu'un parent lit AVANT
  /// d'entrer (verification prealable), deux visites, aucune consommee.
  BudgetObservation dernierBudget = unBudget(
    visitesUtilisees: 0,
    visitesMax: 2,
    total: const Duration(seconds: 240),
  );

  /// Combien de fois le budget ponctuel a ete lu.
  int lecturesBudget = 0;

  /// Le flux que le test pilote a la main.
  final StreamController<BudgetObservation> flux =
      StreamController<BudgetObservation>.broadcast();

  /// Combien de fois le flux a ete ouvert.
  int abonnements = 0;

  /// Les politiques ecrites, dans l'ordre, avec leur groupe.
  final List<({String groupeId, GuardianObservationPolicy politique})> ecrites =
      <({String groupeId, GuardianObservationPolicy politique})>[];

  /// L'echec leve a l'ecriture, s'il y en a un.
  EchecObservation? echecEcriture;

  @override
  Future<GuardianObservationPolicy> politiqueEffective({
    required String groupeId,
  }) async => politique;

  @override
  Future<GuardianObservationPolicy> definirPolitiqueGroupe({
    required String groupeId,
    required GuardianObservationPolicy politique,
  }) async {
    ecrites.add((groupeId: groupeId, politique: politique));
    final EchecObservation? echec = echecEcriture;
    if (echec != null) {
      throw echec;
    }
    return this.politique = politique;
  }

  /// L'echec leve a la lecture ponctuelle du budget, s'il y en a un.
  EchecObservation? echecBudget;

  /// Quand il est pose, la lecture ponctuelle attend qu'il soit complete.
  Completer<void>? budgetSuspendu;

  @override
  Future<BudgetObservation> budget({required String sessionId}) async {
    lecturesBudget++;
    final Completer<void>? suspension = budgetSuspendu;
    if (suspension != null) {
      await suspension.future;
    }
    final EchecObservation? echec = echecBudget;
    if (echec != null) {
      throw echec;
    }
    return dernierBudget;
  }

  @override
  Stream<BudgetObservation> suivreBudget({required String sessionId}) {
    abonnements++;
    return flux.stream;
  }

  /// Ferme le flux.
  Future<void> fermer() => flux.close();
}

/// Laisse tourner les micro-taches en attente.
Future<void> souffler() => Future<void>.delayed(Duration.zero);
