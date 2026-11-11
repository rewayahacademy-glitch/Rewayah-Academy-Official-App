import 'dart:async';

import 'package:flutter/foundation.dart';

import 'garde_fermeture_natif.dart'
    if (dart.library.js_interop) 'garde_fermeture_web.dart'
    as plateforme;

/// SORTIE-SALLE (directeur, 11/11/2026) : fermer ou recharger l'onglet
/// pendant une seance coupe l'appel sans rien dire. Tant qu'un appel est en
/// cours, le navigateur pose donc **sa propre** question de confirmation
/// (`beforeunload`) ; rien d'autre (aucun texte a nous : les navigateurs
/// l'ignorent). Hors navigateur, rien ne se passe.
///
/// La garde suit le controleur de session (`controleurSessionProvider`) :
/// armee quand il tient un appel, desarmee des qu'il le rend (Quitter, fin
/// de seance par le serveur, lien perdu pour de bon). Elle ne depend donc
/// pas de l'ecran de la salle, qui peut etre reduit pendant l'appel.
abstract final class GardeFermeture {
  static StreamSubscription<bool>? _suivi;
  static bool _armee = false;

  /// Vrai quand la question du navigateur est armee.
  static bool get armee => _armee;

  /// Suit [appelEnCours] a partir de [initial] ; remplace un suivi
  /// precedent (une seule garde pour l'application).
  static void suivre(Stream<bool> appelEnCours, {required bool initial}) {
    unawaited(_suivi?.cancel());
    _suivi = appelEnCours.listen(_poser);
    _poser(initial);
  }

  static void _poser(bool appel) {
    if (appel == _armee) return;
    _armee = appel;
    plateforme.poserGardeFermeture(armee: appel);
  }

  /// Desarme et oublie le suivi (tests).
  @visibleForTesting
  static void remettre() {
    unawaited(_suivi?.cancel());
    _suivi = null;
    _poser(false);
  }
}
