// La mission de controle (CTR-01, CT-2) : zero ou une mission actionnable
// (doc 08, P-CTR-02), jamais un planning (decision du directeur du
// 27/09/2026, C1 : la visite a lieu SEULEMENT pendant le cours).
//
// Le fournisseur par defaut est neutre : aucune mission, aucun appel serveur
// (K-28). La source reelle (attribution par le serveur, BR-1,
// `14_controleur/CT-BR.md`) se branche dans `main.dart` et nulle part
// ailleurs ; la demonstration surcharge ce fournisseur avec
// `DonneesControleurDemo.mission(etat)`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'etat d'une mission, tel que le serveur le decidera.
enum EtatMissionControle {
  /// La seance n'est pas encore en direct : ligne calme, aucun bouton (R4).
  prevue,

  /// La seance est en direct : « Commencer le controle » (C1, C14).
  enDirect,

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
  });

  /// La seance observee, portee par le billet de salle.
  final String seanceId;

  /// Le nom de la Classe.
  final String classe;

  /// L'enseignant, precede de son titre (« Sayyid Ibrahim »).
  final String enseignant;

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
}

/// La mission du controleur, ou nulle. **Neutre par defaut** : aucune
/// mission, aucun appel reseau.
final FutureProvider<MissionControle?> missionControleProvider =
    FutureProvider<MissionControle?>((Ref _) async => null);
