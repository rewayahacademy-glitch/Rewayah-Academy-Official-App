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
class RepliAudio {
  /// Le nombre de bonnes mesures consecutives qui ramenent la video.
  static const int mesuresPourRevenir = 2;

  NiveauRepli _niveau = NiveauRepli.aucun;
  int _bonnes = 0;

  /// Le niveau courant.
  NiveauRepli get niveau => _niveau;

  /// Vrai quand l'image est coupee ou reduite (la salle le dit).
  bool get videoSuspendue => _niveau != NiveauRepli.aucun;

  /// Prend une mesure du lien et rend le niveau qui en resulte.
  NiveauRepli mesurer(QualiteLien lien) {
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
  }
}
