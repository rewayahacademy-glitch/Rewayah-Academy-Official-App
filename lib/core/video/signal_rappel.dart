import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observabilite/journal_dev.dart';
import '../theme/app_mouvement.dart';

import 'signal_rappel_natif.dart'
    if (dart.library.js_interop) 'signal_rappel_web.dart'
    as plateforme;

/// Ce que l'appareil de l'eleve fait en plus du message quand l'enseignant
/// l'appelle (rappel discret, consigne du pilote du 30/10/2026) : une
/// vibration courte et un son doux, **quand l'appareil le permet**. Rien ne
/// bloque si c'est refuse : le message a l'ecran reste le signal.
///
/// - Sur telephone ou ordinateur (application) : retour haptique et son
///   systeme d'alerte.
/// - Dans un navigateur (PWA) : `navigator.vibrate` quand il existe, et un
///   son court par Web Audio **seulement si la page a deja ete touchee**
///   (contexte audio actif) ; sinon, le visuel seul.
typedef SignalRappel = void Function();

/// Le signal employe par l'application ; les tests le remplacent.
final Provider<SignalRappel> signalRappelProvider = Provider<SignalRappel>(
  (Ref _) => plateforme.signalerRappel,
);

/// CHRONO-ETAT (directeur, 11/11/2026) : le signal sonore du chrono, cinq
/// minutes avant la fin et a la fin prevue, **chez qui conduit la seance
/// seulement** (un bip chez l'eleve pourrait tomber au milieu d'un verset).
/// Les tests le remplacent par un compteur.
final Provider<SignalRappel> signalChronoProvider = Provider<SignalRappel>(
  (Ref _) => plateforme.signalerChrono,
);

/// DYNAMIQUE-CHRONO-2, point 6 (directeur, 12/11/2026 : « la sonnerie de
/// l'appel d'un eleve est trop courte : l'allonger, repetee, meme espacee ») :
/// le meme motif ([SignalRappel]), joue [repetitions] fois, a
/// [AppMouvement.sonnerieAppelEspace] d'intervalle, et arrete des que
/// l'eleve touche l'ecran ou la barre ([arreter]).
///
/// Aucun son nouveau, aucune bibliotheque de plus : c'est le signal
/// existant, rejoue. Dans un navigateur, un son ne part que si la page
/// l'autorise ; un refus ne casse rien (le signal ne leve pas, et chaque
/// repetition est gardee).
class SonnerieAppel {
  /// Cree la sonnerie sur [signal].
  SonnerieAppel(this.signal);

  /// Le motif joue a chaque repetition.
  final SignalRappel signal;

  /// Le nombre de fois que le motif est joue.
  static const int repetitions = 3;

  final List<Timer> _suite = <Timer>[];

  /// Vrai tant qu'une repetition reste a jouer.
  bool get sonne => _suite.any((Timer m) => m.isActive);

  /// Joue le motif tout de suite, puis le rejoue. Un nouvel appel repart du
  /// debut.
  void lancer() {
    arreter();
    _jouer();
    for (int i = 1; i < repetitions; i++) {
      _suite.add(Timer(AppMouvement.sonnerieAppelEspace * i, _jouer));
    }
  }

  /// Arrete les repetitions qui restent.
  void arreter() {
    for (final Timer m in _suite) {
      m.cancel();
    }
    _suite.clear();
  }

  void _jouer() {
    try {
      signal();
    } on Object catch (e) {
      journalDev('sonnerie de l appel impossible : $e');
    }
  }
}
