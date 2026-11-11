// Lot salle 3, audit reseau du 25/10/2026 (decision du pilote) : le repli
// audio seul, avec hysteresis. Dart pur, sans SDK : le moteur LiveKit y lit
// ce qu'il doit faire, la salle ce qu'elle doit dire, sur la meme suite de
// mesures.

import 'video_session_provider.dart';

/// Le niveau de repli de la salle.
enum NiveauRepli {
  /// Aucun repli : la video circule normalement.
  aucun,

  /// Lien mediocre : les videos recues passent a la couche basse et la
  /// camera locale se coupe ; la voix continue.
  videoBasse,

  /// Lien perdu : les videos recues ne sont plus recues du tout ; la voix
  /// continue.
  audioSeul,
}

/// L'hysteresis du repli : on descend des la premiere mauvaise mesure, on ne
/// remonte qu'apres [mesuresPourRevenir] bonnes mesures consecutives (bonne
/// ou excellente). Une mesure inconnue ne change rien. Ainsi une suite
/// mauvais, bon, mauvais ne fait jamais clignoter la video.
///
/// **Le battement (11/11/2026, defaut R-3 du constat de la salle).** LiveKit
/// ne publie la qualite du lien que lorsqu'elle **change** : un lien qui
/// passe de mediocre a bon et y reste ne donne qu'UNE bonne mesure, et
/// l'image ne revenait jamais (« Image coupee » restait affiche). Le moteur
/// appelle donc [battre] a intervalle regulier ([intervalleBattement]) : la
/// derniere qualite connue compte alors comme une mesure de plus.
class RepliAudio {
  /// Le nombre de bonnes mesures consecutives qui ramenent la video.
  static const int mesuresPourRevenir = 2;

  /// Le temps entre deux battements.
  static const Duration intervalleBattement = Duration(seconds: 5);

  NiveauRepli _niveau = NiveauRepli.aucun;
  int _bonnes = 0;
  QualiteLien? _derniere;

  /// La derniere qualite mesuree, ou `null` avant la premiere.
  QualiteLien? get derniereMesure => _derniere;

  /// Rejoue la derniere qualite connue comme une nouvelle mesure. Sans
  /// mesure encore, ne change rien.
  NiveauRepli battre() {
    final QualiteLien? derniere = _derniere;
    return derniere == null ? _niveau : mesurer(derniere);
  }

  /// Le niveau courant.
  NiveauRepli get niveau => _niveau;

  /// Vrai quand l'image est coupee ou reduite (la salle le dit).
  bool get videoSuspendue => _niveau != NiveauRepli.aucun;

  /// Prend une mesure du lien et rend le niveau qui en resulte.
  NiveauRepli mesurer(QualiteLien lien) {
    if (lien != QualiteLien.inconnue) {
      _derniere = lien;
    }
    switch (lien) {
      case QualiteLien.perdue:
        _bonnes = 0;
        _niveau = NiveauRepli.audioSeul;
      case QualiteLien.mediocre:
        _bonnes = 0;
        if (_niveau == NiveauRepli.aucun) {
          _niveau = NiveauRepli.videoBasse;
        }
      case QualiteLien.bonne || QualiteLien.excellente:
        if (_niveau != NiveauRepli.aucun) {
          _bonnes++;
          if (_bonnes >= mesuresPourRevenir) {
            _bonnes = 0;
            _niveau = NiveauRepli.aucun;
          }
        }
      case QualiteLien.inconnue:
        break;
    }
    return _niveau;
  }

  /// Revient a l'etat de depart (nouvelle entree en salle).
  void remettre() {
    _niveau = NiveauRepli.aucun;
    _bonnes = 0;
    _derniere = null;
  }
}
