// La mission de controle (CTR-01, CT-2) : zero ou une mission actionnable
// (doc 08, P-CTR-02), jamais un planning (decision du directeur du
// 27/09/2026, C1 : la visite a lieu SEULEMENT pendant le cours).
//
// Le fournisseur par defaut est neutre : aucune mission, aucun appel serveur
// (K-28). La source reelle (`ma_mission_controle`, N3 D3 :
// `mission_controle_supabase.dart`) se branche dans `main.dart` et nulle part
// ailleurs ; la demonstration surcharge ce fournisseur avec
// `DonneesControleurDemo.mission(etat)`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/classes/nom_classe_distinct.dart';

/// L'etat d'une mission, tel que le serveur le decidera.
enum EtatMissionControle {
  /// La seance n'est pas encore en direct : ligne calme, aucun bouton (R4).
  prevue,

  /// La seance est en direct : « Commencer le controle » (C1, C14).
  enDirect,

  /// La seance est en direct, mais un autre controle y est deja en cours
  /// (CTRL-SALLE-1) : un seul controle a la fois par Classe. Aucun bouton
  /// d'entree, un message qui dit quoi faire (K-59). Le refus atomique du
  /// second controle reste au serveur (BR-1, `14_controleur/CT-BR.md`).
  dejaControlee,

  /// Seance annulee, autorisation revoquee, salle fermee (P-CTR-08).
  indisponible,
}

/// La mission affichee par CTR-01 : le strict necessaire (P-CTR-02 point 3),
/// aucun nom de famille d'eleve, aucun contact.
@immutable
class MissionControle {
  /// Cree la mission.
  const MissionControle({
    required this.seanceId,
    required this.classe,
    required this.enseignant,
    required this.nombreEleves,
    required this.debut,
    required this.finPrevue,
    required this.etat,
    this.id,
    this.paysEnseignant,
    this.numeroDansFamille,
    this.codeCourt,
    this.commencee = false,
  });

  /// L'identifiant de la mission, qui nomme son fil d'echanges (un seul fil
  /// par mission, P-CTR-06). Nul tant que le serveur ne le rend pas (BR-1) :
  /// « Ecrire a l'administration » ouvre alors la liste des Echanges.
  final String? id;

  /// La seance observee, portee par le billet de salle.
  final String seanceId;

  /// Le nom de la Classe.
  final String classe;

  /// R16 : le numero de la Classe parmi les classes paralleles en direct a la
  /// meme heure, attribue par le serveur. Nul tant qu'il ne le rend pas.
  final int? numeroDansFamille;

  /// R16 : le code court de la Classe, a defaut de numero.
  final String? codeCourt;

  /// Le nom de la Classe, sans ambiguite parmi les classes paralleles (R16).
  String get classeDistincte =>
      nomClasseDistinct(classe, numero: numeroDansFamille, code: codeCourt);

  /// L'enseignant, precede de son titre (« Sayyid Ibrahim »).
  final String enseignant;

  /// Le pays declare par l'enseignant (ENS-PAYS-1), affiche sous son nom.
  /// Nul s'il ne l'est pas ou tant que le serveur ne le rend pas (BR-1).
  final String? paysEnseignant;

  /// Le nombre d'eleves attendus.
  final int nombreEleves;

  /// Le debut prevu, heure de l'appareil.
  final DateTime debut;

  /// La fin prevue, heure de l'appareil.
  final DateTime finPrevue;

  /// L'etat de la mission.
  final EtatMissionControle etat;

  /// La duree prevue.
  Duration get dureePrevue => finPrevue.difference(debut);

  /// Vrai si le controleur a deja commence cette visite (mission `en_cours`
  /// au serveur) : y revenir ne la recommence pas.
  final bool commencee;
}

/// Le port de la mission (N3, D3) : la lecture `ma_mission_controle` et le
/// debut de la visite `demarrer_mission_controle`.
abstract interface class PortMissionControle {
  /// La mission actionnable du controleur, ou nulle.
  Future<MissionControle?> maMission();

  /// Commence la visite de la mission [missionId] : le serveur la passe
  /// `en_cours` et inscrit le controleur dans la seance. Leve une exception
  /// si le serveur n'a pas confirme.
  Future<void> demarrer(String missionId);
}

/// Sans serveur : aucune mission, et rien ne demarre (K-28).
class MissionControleNeutre implements PortMissionControle {
  /// Cree le port neutre.
  const MissionControleNeutre();

  @override
  Future<MissionControle?> maMission() async => null;

  @override
  Future<void> demarrer(String missionId) async =>
      throw StateError('Aucun serveur branche (BR-1).');
}

/// Le port de la mission ; neutre par defaut, branche dans `main.dart`.
final Provider<PortMissionControle> portMissionControleProvider =
    Provider<PortMissionControle>((Ref _) => const MissionControleNeutre());

/// La mission du controleur, ou nulle, lue par [portMissionControleProvider].
/// **Neutre par defaut** : aucune mission, aucun appel reseau.
final FutureProvider<MissionControle?> missionControleProvider =
    FutureProvider<MissionControle?>(
      (Ref ref) => ref.watch(portMissionControleProvider).maMission(),
    );
