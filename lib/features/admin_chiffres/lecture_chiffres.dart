/// CHIFFRES-ACADEMIE : le rythme de lecture de la page.
///
/// « Temps reel » sans charger la base (directeur, 20/11/2026) :
///
/// - **une seule lecture a la fois** : une lecture en vol n'en lance jamais
///   une seconde ;
/// - **relue toutes les [intervalle]** (une minute), le delai partant de la
///   FIN de la lecture precedente ;
/// - **aucune lecture quand l'onglet est cache** : la minuterie en cours va
///   a son terme une fois, note que la lecture est due, et plus rien ne
///   tourne ;
/// - **tout de suite au retour sur l'onglet**, si la minute est passee
///   pendant qu'il etait cache ; sinon la minuterie suit son cours ;
/// - une lecture sans reponse apres 12 s est tenue pour perdue : elle ne
///   fige ni le rythme ni l'ecran ;
/// - un echec garde les chiffres deja lus : la page ne se vide pas, la minute
///   suivante retente.
///
/// Aucune horloge d'animation, aucun abonnement : une minuterie d'une minute.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_delais.dart';

/// Lit, garde et relit une valeur au rythme de la page.
class LectureRythmee<T> extends ChangeNotifier {
  /// Cree la lecture. Rien n'est lu avant [demarrer].
  LectureRythmee({
    required this.lire,
    this.intervalle = const Duration(minutes: 1),
    Duration? delai,
  }) : delai = delai ?? delaiLecture;

  /// La lecture elle-meme : un appel.
  final Future<T> Function() lire;

  /// Le delai entre la fin d'une lecture et la suivante.
  final Duration intervalle;

  /// Au-dela, une lecture est tenue pour perdue.
  final Duration delai;

  /// 12 s : plus court que le delai apres lequel `BlocAsynchrone` declare lui
  /// meme la tentative perdue ([AppDelais.requeteMax], 20 s). L'echec arrive
  /// ainsi par la lecture, et la relecture de la minute suivante s'affiche
  /// sans que la personne ait a toucher « Reessayer ».
  static final Duration delaiLecture =
      AppDelais.requeteMax - AppDelais.chargementProlonge;

  AsyncValue<T> _etat = AsyncValue<T>.loading();
  Timer? _minuterie;
  bool _enVol = false;
  bool _visible = true;
  bool _ferme = false;

  /// Vrai quand une lecture est due et n'a pas ete faite : l'onglet etait
  /// cache quand la minute est passee, ou la page n'a encore rien lu.
  bool _due = true;
  int _lectures = 0;

  /// Ce que la page affiche.
  AsyncValue<T> get etat => _etat;

  /// Le nombre de lectures lancees (tests et mesure).
  int get lectures => _lectures;

  /// Lance la premiere lecture, si l'onglet est visible.
  void demarrer({required bool visible}) {
    _visible = visible;
    if (visible) unawaited(_lireUneFois());
  }

  /// L'onglet devient visible ou cache.
  ///
  /// Cache : la minuterie en cours va a son terme, une seule fois, et note
  /// que la lecture est due, sans rien lire. Visible : une lecture due part
  /// tout de suite ; sinon la minuterie en cours suit son cours.
  set visible(bool valeur) {
    if (_visible == valeur) return;
    _visible = valeur;
    if (valeur && _due) unawaited(_lireUneFois());
  }

  /// « Reessayer » : relit tout de suite, sauf si une lecture est en vol.
  void relire() {
    if (_enVol) return;
    if (!_etat.hasValue) {
      _etat = AsyncValue<T>.loading();
      notifyListeners();
    }
    unawaited(_lireUneFois());
  }

  void _echeance() {
    _minuterie = null;
    if (_ferme) return;
    if (_visible) {
      unawaited(_lireUneFois());
    } else {
      _due = true;
    }
  }

  Future<void> _lireUneFois() async {
    if (_enVol || _ferme) return;
    _enVol = true;
    _due = false;
    _minuterie?.cancel();
    _minuterie = null;
    _lectures++;
    try {
      // Une lecture qui ne repond pas est tenue pour perdue : elle ne fige
      // ni le rythme ni l'ecran.
      final T valeur = await lire().timeout(delai);
      if (_ferme) return;
      // Une reconstruction par minute : l'heure « A jour a » avance ; les
      // dessins, eux, ne se repeignent que si leur donnee change.
      _etat = AsyncValue<T>.data(valeur);
      notifyListeners();
    } on Object catch (erreur, pile) {
      if (_ferme) return;
      // Des chiffres deja lus restent a l'ecran : seul un premier echec se dit.
      if (!_etat.hasValue) {
        _etat = AsyncValue<T>.error(erreur, pile);
        notifyListeners();
      }
    } finally {
      _enVol = false;
      if (!_ferme) _minuterie = Timer(intervalle, _echeance);
    }
  }

  @override
  void dispose() {
    _ferme = true;
    _minuterie?.cancel();
    _minuterie = null;
    super.dispose();
  }
}
