import 'package:flutter_riverpod/flutter_riverpod.dart';

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
