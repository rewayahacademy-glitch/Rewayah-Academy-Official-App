// Les disponibilites declarees dans la Salle d'examen (CAND-01), heure par
// heure, dans l'heure LOCALE de la personne.
//
// Ce que le serveur attend (`private.questionnaire_creneaux`, CAND-L2A1, C18)
// est une liste de plages par jour ISO, a bornes en heures entieres :
//
//     [{"jour": 1, "debut": "18:00", "fin": "21:00"}, ...]
//
// jour 1 pour lundi (ISO 8601), `debut` en `HH:00`, `fin` en `HH:00` ou
// `24:00`, fin apres debut, deux plages d'un meme jour sans recouvrement, une
// plage qui ne passe pas minuit (de 22 h a 1 h : deux plages, une par jour),
// 168 plages au plus. **Aucun fuseau dans la liste** : les heures sont celles
// du champ `fuseauIana`, le seul fuseau du questionnaire, jamais converties.
// L'affectation lit ensuite `weekly_availability` : une ligne par heure
// couverte (jour ISO, heure entiere, fuseau IANA).
//
// **Ce que la personne choisit, ce que le serveur recoit.** Une Classe
// commence a une heure entiere et dure 60 minutes (enfants) ou 90 minutes
// (adultes). La personne choisit donc des **heures de debut** ; l'affectation,
// elle, veut que chaque heure entiere touchee par la seance soit declaree. Un
// debut a 18 h pour un cours d'adultes (18 h a 19 h 30) declare les heures 18 et
// 19. Cette conversion est ici, a un seul endroit, et elle est pure.
//
// Une seule limite, inherente a la maille d'une heure : un cours d'adultes
// qui finit a 19 h 30 declare toute l'heure 19, soit 30 minutes de plus que
// ce que la personne enseigne. Les durees ci-dessous reprennent les reglages
// `seance.duree_minutes_*` (60 et 90 par defaut) ; le serveur reste l'autorite
// de l'affectation, ce fichier ne decide jamais d'une Classe.
library;

import 'package:flutter/foundation.dart';

/// La duree d'une seance d'enfants, en minutes (reglage de la direction,
/// `seance.duree_minutes_enfant`, 60 par defaut).
const int dureeSeanceEnfantMinutes = 60;

/// La duree d'une seance d'adultes, en minutes (reglage de la direction,
/// `seance.duree_minutes_adulte`, 90 par defaut).
const int dureeSeanceAdulteMinutes = 90;

/// Le nombre de jours d'une semaine.
const int joursParSemaine = 7;

/// Le nombre d'heures d'un jour.
const int heuresParJour = 24;

/// Le nombre de seances d'une Classe par semaine (decision du directeur : trois
/// seances par semaine, aux memes jours et a la meme heure).
const int seancesParClasse = 3;

/// Un cours dont on connait le debut et la fin, en minutes depuis minuit du
/// jour de debut (la fin peut depasser 24 h : le cours passe minuit).
@immutable
class IntervalleCours {
  /// Cree l'intervalle.
  const IntervalleCours(this.debut, this.fin);

  /// Le debut, en minutes depuis minuit.
  final int debut;

  /// La fin, en minutes depuis minuit (24 h = 1440, au-dela : le lendemain).
  final int fin;

  @override
  bool operator ==(Object other) =>
      other is IntervalleCours && other.debut == debut && other.fin == fin;

  @override
  int get hashCode => Object.hash(debut, fin);

  @override
  String toString() => 'IntervalleCours($debut-$fin)';
}

/// Les heures entieres (0 a 23, ou plus si le cours passe minuit) qu'un cours
/// qui commence a l'heure [debut] et dure [dureeMinutes] touche.
Iterable<int> heuresTouchees(int debut, int dureeMinutes) sync* {
  final int fin = debut * 60 + dureeMinutes;
  for (int h = debut; h * 60 < fin; h++) {
    yield h;
  }
}

/// Les cours qui commencent aux heures [debuts] et durent [dureeMinutes]
/// chacun, fusionnes quand ils se touchent ou se recouvrent.
List<IntervalleCours> intervallesDesCours(
  Iterable<int> debuts,
  int dureeMinutes,
) {
  final List<IntervalleCours> fusion = <IntervalleCours>[];
  for (final int h in debuts.toList()..sort()) {
    final int debut = h * 60;
    final int fin = debut + dureeMinutes;
    if (fusion.isNotEmpty && debut <= fusion.last.fin) {
      final IntervalleCours dernier = fusion.removeLast();
      fusion.add(
        IntervalleCours(dernier.debut, fin > dernier.fin ? fin : dernier.fin),
      );
    } else {
      fusion.add(IntervalleCours(debut, fin));
    }
  }
  return fusion;
}

/// Les disponibilites declarees : pour chaque jour ISO (1 a 7), les heures de
/// debut possibles d'un cours.
@immutable
class DisponibilitesDeclarees {
  /// Cree les disponibilites a partir des heures de debut de chaque jour.
  const DisponibilitesDeclarees([
    this._debuts = const <int, Set<int>>{},
  ]);

  /// Lit les plages que le serveur rend (ou qu'un brouillon a gardees) et en
  /// deduit les heures de debut possibles d'un cours de [dureeMinutes] : un
  /// debut est possible quand chaque heure que le cours touche est declaree.
  /// Une valeur mal formee vaut aucune disponibilite : l'ecran ne devine rien.
  factory DisponibilitesDeclarees.depuisPlages(
    Object? valeur, {
    required int dureeMinutes,
  }) {
    final Set<int>? libres = _heuresLibres(valeur);
    if (libres == null || libres.isEmpty) {
      return const DisponibilitesDeclarees();
    }
    final Map<int, Set<int>> debuts = <int, Set<int>>{};
    for (int jour = 1; jour <= joursParSemaine; jour++) {
      for (int h = 0; h < heuresParJour; h++) {
        final bool possible = heuresTouchees(h, dureeMinutes).every(
          (int touchee) => libres.contains(_indice(jour, touchee)),
        );
        if (possible) {
          (debuts[jour] ??= <int>{}).add(h);
        }
      }
    }
    return DisponibilitesDeclarees(_figer(debuts));
  }

  final Map<int, Set<int>> _debuts;

  /// Vrai quand [valeur] est une liste de plages bien formees et non vide :
  /// ce que le serveur accepte comme forme (jour ISO, heures entieres, fin
  /// apres debut). Les recouvrements ne sont pas examines ici.
  static bool plagesBienFormees(Object? valeur) {
    final Set<int>? libres = _heuresLibres(valeur);
    return libres != null && libres.isNotEmpty;
  }

  /// Les heures de debut possibles du jour [jour] (1 a 7), triees.
  List<int> debuts(int jour) =>
      (_debuts[jour] ?? const <int>{}).toList()..sort();

  /// Vrai quand [heure] est un debut possible le jour [jour].
  bool contient(int jour, int heure) =>
      (_debuts[jour] ?? const <int>{}).contains(heure);

  /// Les jours qui portent au moins un debut, tries (lundi d'abord).
  List<int> get jours => <int>[
    for (int j = 1; j <= joursParSemaine; j++)
      if ((_debuts[j] ?? const <int>{}).isNotEmpty) j,
  ];

  /// Vrai quand aucun jour ne porte de debut.
  bool get estVide => jours.isEmpty;

  /// Le nombre total d'heures de debut, tous jours confondus.
  int get nombreDebuts => _debuts.values.fold(
    0,
    (int total, Set<int> heures) => total + heures.length,
  );

  /// Les plages a envoyer pour un cours de [dureeMinutes] : toutes les heures
  /// entieres que touchent les cours possibles, regroupees par jour quand elles
  /// se suivent. Rien n'est envoye pour un jour sans debut.
  List<Map<String, Object?>> versPlages(int dureeMinutes) {
    final Set<int> libres = <int>{};
    for (final MapEntry<int, Set<int>> e in _debuts.entries) {
      for (final int h in e.value) {
        for (final int touchee in heuresTouchees(h, dureeMinutes)) {
          // Un cours qui passe minuit touche aussi le jour suivant (le
          // dimanche rejoint le lundi).
          libres.add(_indice(e.key, touchee));
        }
      }
    }
    final List<Map<String, Object?>> plages = <Map<String, Object?>>[];
    for (int jour = 1; jour <= joursParSemaine; jour++) {
      int? debut;
      for (int h = 0; h <= heuresParJour; h++) {
        final bool libre =
            h < heuresParJour && libres.contains(_indice(jour, h));
        if (libre && debut == null) {
          debut = h;
        } else if (!libre && debut != null) {
          plages.add(<String, Object?>{
            'jour': jour,
            'debut': _heure(debut),
            'fin': _heure(h),
          });
          debut = null;
        }
      }
    }
    return plages;
  }

  /// Les cours du jour [jour], de [dureeMinutes] chacun, fusionnes quand ils se
  /// touchent : « de 18 h a 21 h 30 » quand les debuts de 18 h, 19 h et 20 h
  /// donnent trois cours de 90 minutes qui se suivent.
  List<IntervalleCours> intervalles(int jour, int dureeMinutes) =>
      intervallesDesCours(debuts(jour), dureeMinutes);

  @override
  bool operator ==(Object other) {
    if (other is! DisponibilitesDeclarees) {
      return false;
    }
    for (int j = 1; j <= joursParSemaine; j++) {
      if (!setEquals(
        _debuts[j] ?? const <int>{},
        other._debuts[j] ?? const <int>{},
      )) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    for (int j = 1; j <= joursParSemaine; j++) Object.hashAllUnordered(debuts(j)),
  ]);
}

Map<int, Set<int>> _figer(Map<int, Set<int>> debuts) => Map<int, Set<int>>.unmodifiable(
  <int, Set<int>>{
    for (final MapEntry<int, Set<int>> e in debuts.entries)
      e.key: Set<int>.unmodifiable(e.value),
  },
);

/// L'indice d'une heure de la semaine : de 0 (lundi 0 h) a 167 (dimanche
/// 23 h). Une heure au-dela de 23 passe au jour suivant, et le dimanche rejoint
/// le lundi.
int _indice(int jour, int heure) =>
    ((jour - 1) * heuresParJour + heure) % (joursParSemaine * heuresParJour);

/// Les heures declarees d'une liste de plages, en indices de la semaine, ou
/// `null` quand la forme est mauvaise.
Set<int>? _heuresLibres(Object? valeur) {
  if (valeur is! List) {
    return null;
  }
  final Set<int> libres = <int>{};
  for (final Object? plage in valeur) {
    if (plage is! Map) {
      return null;
    }
    final Object? jour = plage['jour'];
    final int? debut = _heureEntiere(plage['debut'], fin: false);
    final int? fin = _heureEntiere(plage['fin'], fin: true);
    if (jour is! int || jour < 1 || jour > joursParSemaine) {
      return null;
    }
    if (debut == null || fin == null || fin <= debut) {
      return null;
    }
    for (int h = debut; h < fin; h++) {
      libres.add(_indice(jour, h));
    }
  }
  return libres;
}

/// L'heure d'un `HH:00` (ou `24:00` pour une fin), ou `null`.
int? _heureEntiere(Object? texte, {required bool fin}) {
  if (texte is! String) {
    return null;
  }
  final RegExpMatch? m = RegExp(r'^(\d{2}):00$').firstMatch(texte);
  if (m == null) {
    return null;
  }
  final int h = int.parse(m.group(1)!);
  return h < heuresParJour || (fin && h == heuresParJour) ? h : null;
}

String _heure(int heure) => '${heure.toString().padLeft(2, '0')}:00';
