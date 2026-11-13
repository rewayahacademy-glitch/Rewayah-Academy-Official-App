import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
import 'horaires_priere.dart';

/// La pause de priere que le serveur a placee dans une seance (PRIERE-1).
///
/// **L'application ne calcule plus aucune heure de priere** : elle lit
/// `pause_prevue_seance(session_id)`, qui rend l'heure, la duree, le motif et le
/// nom de la priere, et jamais le lieu de l'enseignant. L'eleve, son tuteur,
/// l'enseignant et la direction lisent donc le meme chiffre.
@immutable
class PausePrevue {
  /// Cree une pause prevue.
  const PausePrevue({
    required this.seanceId,
    required this.debut,
    required this.duree,
    required this.priere,
    this.motif = 'priere',
  });

  /// Lit une ligne de `pause_prevue_seance`.
  ///
  /// L'instant est rendu dans le fuseau de l'appareil, comme une seance lue :
  /// c'est un instant absolu, que deux personnes de deux continents lisent sous
  /// deux heures locales differentes. Une ligne illisible leve une
  /// [FormatException] : mieux vaut aucune annonce qu'une fausse.
  factory PausePrevue.depuisJson(String seanceId, Map<String, dynamic> json) {
    final Object? debut = json['debut_prevu_utc'];
    final Object? duree = json['duree_minutes'];
    if (debut is! String || duree is! num) {
      throw const FormatException('pause prevue illisible');
    }
    return PausePrevue(
      seanceId: seanceId,
      debut: DateTime.parse(debut).toLocal(),
      duree: Duration(minutes: duree.round()),
      priere: Priere.depuisSql(json['priere'] as String?),
      motif: json['motif'] as String? ?? 'priere',
    );
  }

  /// La seance.
  final String seanceId;

  /// Quand la pause commence, dans le fuseau de l'appareil.
  final DateTime debut;

  /// Combien de temps elle dure.
  final Duration duree;

  /// La priere qui l'occasionne ; `null` si le serveur en nomme une que ce code
  /// ne connait pas (la pause s'annonce quand meme, sans le nom).
  final Priere? priere;

  /// Le motif ; `priere` dans ce lot.
  final String motif;

  /// Quand elle se termine.
  DateTime get fin => debut.add(duree);

  /// La meme pause, sous la forme que lisent la journee et l'accueil.
  ///
  /// Le serveur ne rend aucun preavis : l'annonce est faite par l'ecran, avant
  /// et pendant le cours, jamais par un delai que le client inventerait.
  InterruptionPriere? versInterruption() => priere == null
      ? null
      : InterruptionPriere(
          priere: priere!,
          debut: debut,
          duree: duree,
          preavis: Duration.zero,
        );

  @override
  bool operator ==(Object other) =>
      other is PausePrevue &&
      other.seanceId == seanceId &&
      other.debut == debut &&
      other.duree == duree &&
      other.priere == priere &&
      other.motif == motif;

  @override
  int get hashCode => Object.hash(seanceId, debut, duree, priere, motif);
}
