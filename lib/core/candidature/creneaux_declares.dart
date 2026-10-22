// Les disponibilites declarees dans la Salle d'examen (CAND-01) : une grille de
// plages a toucher, jours par plages, convertie vers la forme que le serveur
// attend (`disponibilitesDeclarees`, `type: creneaux`).
//
// Forme serveur (`private.questionnaire_creneaux`, CAND-L2A1) :
// `{"fuseau": "Europe/Paris", "creneaux": [{"jour": 1, "debut": "08:00",
// "fin": "12:00"}]}` ; jour 1 pour lundi (ISO 8601), heures a la demi-heure,
// `24:00` permis en fin, fin apres debut, sans doublon, 42 creneaux au plus.
// L'heure est celle du fuseau declare, jamais convertie (« Fuseaux IANA en
// stockage, UTC pour les instants »).
//
// Une plage de la grille dure quatre heures. Deux plages voisines d'un meme
// jour s'envoient en un seul creneau : six plages par jour et sept jours font
// 42, le maximum du serveur, sans jamais le depasser. Rien ici n'est une regle
// metier : c'est le pas de la grille, qu'un changement de questionnaire peut
// modifier en un seul endroit.
library;

import 'package:flutter/foundation.dart';

/// Le nombre de plages d'une journee.
const int plagesParJour = 6;

/// La duree d'une plage, en heures.
const int heuresParPlage = 4;

/// Le nombre de jours d'une semaine.
const int joursParSemaine = 7;

/// Un demi-heure : le pas des creneaux du serveur.
const int _demiHeuresParJour = 48;

/// Les demi-heures d'une plage.
const int _demiHeuresParPlage = heuresParPlage * 2;

/// L'etat d'une cellule de la grille.
enum EtatCellule {
  /// Aucune demi-heure de la plage n'est declaree.
  vide,

  /// Une partie de la plage est declaree (creneau venu d'ailleurs, d'une
  /// autre granularite) : la cellule le dit, elle ne le cache pas.
  partielle,

  /// Toute la plage est declaree.
  pleine,
}

/// Les disponibilites declarees : un ensemble de demi-heures par jour.
@immutable
class CreneauxDeclares {
  /// Cree les disponibilites a partir de leurs demi-heures. Une demi-heure
  /// est `(jour - 1) * 48 + indice`, l'indice allant de 0 (00:00) a 47
  /// (23:30).
  const CreneauxDeclares([this._demiHeures = const <int>{}]);

  /// Lit la reponse du serveur (`{fuseau, creneaux}`). Une valeur mal formee
  /// vaut aucune disponibilite : l'ecran ne devine rien.
  factory CreneauxDeclares.depuisReponse(Object? valeur) {
    if (valeur is! Map || valeur['creneaux'] is! List) {
      return const CreneauxDeclares();
    }
    final Set<int> demiHeures = <int>{};
    for (final Object? c in valeur['creneaux'] as List) {
      if (c is! Map) {
        continue;
      }
      final Object? jour = c['jour'];
      final int? debut = _indice(c['debut']);
      final int? fin = _indice(c['fin']);
      if (jour is! int || jour < 1 || jour > joursParSemaine) {
        continue;
      }
      if (debut == null || fin == null || fin <= debut) {
        continue;
      }
      for (int h = debut; h < fin; h++) {
        demiHeures.add((jour - 1) * _demiHeuresParJour + h);
      }
    }
    return CreneauxDeclares(Set<int>.unmodifiable(demiHeures));
  }

  final Set<int> _demiHeures;

  /// Vrai quand rien n'est declare.
  bool get estVide => _demiHeures.isEmpty;

  /// Le nombre de plages entierement declarees.
  int get nombrePleines {
    int n = 0;
    for (int jour = 1; jour <= joursParSemaine; jour++) {
      for (int plage = 0; plage < plagesParJour; plage++) {
        if (etat(jour: jour, plage: plage) == EtatCellule.pleine) {
          n++;
        }
      }
    }
    return n;
  }

  /// L'etat de la cellule ([jour] de 1 a 7, [plage] de 0 a 5).
  EtatCellule etat({required int jour, required int plage}) {
    final int debut =
        (jour - 1) * _demiHeuresParJour + plage * _demiHeuresParPlage;
    int pris = 0;
    for (int h = 0; h < _demiHeuresParPlage; h++) {
      if (_demiHeures.contains(debut + h)) {
        pris++;
      }
    }
    if (pris == 0) {
      return EtatCellule.vide;
    }
    return pris == _demiHeuresParPlage
        ? EtatCellule.pleine
        : EtatCellule.partielle;
  }

  /// Touche une cellule : pleine, elle se vide ; sinon elle se remplit.
  CreneauxDeclares bascule({required int jour, required int plage}) {
    final int debut =
        (jour - 1) * _demiHeuresParJour + plage * _demiHeuresParPlage;
    final Set<int> suivant = <int>{..._demiHeures};
    if (etat(jour: jour, plage: plage) == EtatCellule.pleine) {
      for (int h = 0; h < _demiHeuresParPlage; h++) {
        suivant.remove(debut + h);
      }
    } else {
      for (int h = 0; h < _demiHeuresParPlage; h++) {
        suivant.add(debut + h);
      }
    }
    return CreneauxDeclares(Set<int>.unmodifiable(suivant));
  }

  /// La reponse a envoyer, dans le fuseau [fuseau] : les demi-heures voisines
  /// d'un meme jour forment un seul creneau.
  Map<String, Object?> versReponse(String fuseau) {
    final List<Map<String, Object?>> creneaux = <Map<String, Object?>>[];
    for (int jour = 1; jour <= joursParSemaine; jour++) {
      int? debut;
      for (int h = 0; h <= _demiHeuresParJour; h++) {
        final bool pris =
            h < _demiHeuresParJour &&
            _demiHeures.contains((jour - 1) * _demiHeuresParJour + h);
        if (pris && debut == null) {
          debut = h;
        } else if (!pris && debut != null) {
          creneaux.add(<String, Object?>{
            'jour': jour,
            'debut': _heure(debut),
            'fin': _heure(h),
          });
          debut = null;
        }
      }
    }
    return <String, Object?>{'fuseau': fuseau, 'creneaux': creneaux};
  }

  @override
  bool operator ==(Object other) =>
      other is CreneauxDeclares && setEquals(other._demiHeures, _demiHeures);

  @override
  int get hashCode => Object.hashAllUnordered(_demiHeures);
}

/// L'indice de demi-heure d'une heure `HH:MM` (`24:00` vaut 48), ou `null`.
int? _indice(Object? heure) {
  if (heure is! String) {
    return null;
  }
  final RegExpMatch? m = RegExp(r'^(\d{2}):(00|30)$').firstMatch(heure);
  if (m == null) {
    return null;
  }
  final int h = int.parse(m.group(1)!);
  if (h > 24 || (h == 24 && m.group(2) != '00')) {
    return null;
  }
  return h * 2 + (m.group(2) == '30' ? 1 : 0);
}

String _heure(int indice) {
  final int h = indice ~/ 2;
  final String minutes = indice.isEven ? '00' : '30';
  return '${h.toString().padLeft(2, '0')}:$minutes';
}

/// L'heure de debut d'une plage (0 a 5), en heures pleines.
int heureDebutPlage(int plage) => plage * heuresParPlage;

/// L'heure de fin d'une plage (0 a 5), en heures pleines (24 pour la derniere).
int heureFinPlage(int plage) => (plage + 1) * heuresParPlage;
