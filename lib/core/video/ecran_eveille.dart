import 'dart:async';

import '../observabilite/journal_dev.dart';
import 'ecran_eveille_natif.dart'
    if (dart.library.js_interop) 'ecran_eveille_web.dart'
    as plateforme;

/// Ce que le navigateur offre pour garder l'ecran allume : l'API Screen Wake
/// Lock (`navigator.wakeLock.request('screen')`), et la visibilite de la page.
///
/// Separe de [EcranEveille] pour que la logique (prendre, reprendre au retour,
/// rendre) se teste sans navigateur : seul `ecran_eveille_web.dart` parle au
/// JavaScript.
abstract interface class VerrouEcranNavigateur {
  /// Vrai quand le navigateur connait l'API (faux, par exemple, sur un Safari
  /// d'avant iOS 16.4 : non bloquant, on journalise et on continue).
  bool get disponible;

  /// Vrai quand la page est visible (`document.visibilityState`). Le
  /// navigateur refuse le verrou a une page cachee.
  bool get visible;

  /// Un evenement a chaque changement de visibilite (`visibilitychange`).
  Stream<void> get changementsDeVisibilite;

  /// Demande le verrou ; rend un jeton opaque (la `WakeLockSentinel`), ou
  /// leve si le navigateur refuse (batterie faible, page cachee, reglage).
  Future<Object> demander();

  /// Vrai quand le navigateur a deja relache ce verrou de lui-meme : il le
  /// fait **toujours** quand la page passe a l'arriere-plan.
  bool estRelache(Object verrou);

  /// Rend le verrou.
  Future<void> relacher(Object verrou);
}

/// L'ecran reste allume pendant toute la seance (ECRAN-EVEILLE, directeur,
/// 11/11/2026 : « quand l'ecran s'eteint, la plupart du temps, la connexion
/// se coupe »).
///
/// [tenir] a l'entree dans l'appel, [rendre] a la sortie. **Le navigateur
/// relache le verrou tout seul des que l'onglet est cache** (specification
/// W3C Screen Wake Lock) : il est donc redemande a chaque retour au premier
/// plan, tant que l'appel est tenu. Aucune erreur visible si le navigateur ne
/// connait pas l'API ou refuse : on journalise et la seance continue.
///
/// Hors navigateur (application installee Android ou iOS), [_navigateur] est
/// nul et tout est sans effet : aucune dependance n'est ajoutee
/// (`pubspec.yaml` est hors de portee de ce lot) ; l'application web est la
/// seule servie en production.
class EcranEveille {
  /// Cree le gardien sur [navigateur] (nul hors navigateur).
  EcranEveille(this._navigateur);

  /// Le gardien de la plateforme courante.
  factory EcranEveille.dePlateforme() =>
      EcranEveille(plateforme.verrouEcranDeLaPlateforme());

  final VerrouEcranNavigateur? _navigateur;

  bool _voulu = false;
  bool _demandeEnCours = false;
  bool _indisponibleDit = false;
  Object? _verrou;
  StreamSubscription<void>? _suiviVisibilite;

  /// Vrai entre [tenir] et [rendre].
  bool get tenu => _voulu;

  /// Vrai quand le navigateur tient reellement le verrou en ce moment.
  bool get actif {
    final VerrouEcranNavigateur? nav = _navigateur;
    final Object? verrou = _verrou;
    return nav != null && verrou != null && !nav.estRelache(verrou);
  }

  /// Garde l'ecran allume, jusqu'a [rendre]. Idempotent.
  void tenir() {
    final VerrouEcranNavigateur? nav = _navigateur;
    if (_voulu || nav == null) {
      return;
    }
    _voulu = true;
    _suiviVisibilite = nav.changementsDeVisibilite.listen((_) {
      if (nav.visible) unawaited(_demander());
    });
    unawaited(_demander());
  }

  Future<void> _demander() async {
    final VerrouEcranNavigateur? nav = _navigateur;
    if (nav == null || !_voulu || _demandeEnCours || actif) {
      return;
    }
    if (!nav.disponible) {
      if (!_indisponibleDit) {
        _indisponibleDit = true;
        journalDev('ecran eveille : API Screen Wake Lock absente');
      }
      return;
    }
    // Une page cachee se voit refuser le verrou : on attend son retour.
    if (!nav.visible) {
      return;
    }
    _demandeEnCours = true;
    try {
      final Object verrou = await nav.demander();
      if (_voulu) {
        _verrou = verrou;
      } else {
        // Rendu pendant la demande : on ne garde rien.
        await nav.relacher(verrou);
      }
    } catch (e) {
      journalDev('ecran eveille : verrou refuse ($e)');
    } finally {
      _demandeEnCours = false;
    }
  }

  /// Laisse l'ecran s'eteindre a nouveau. Idempotent.
  void rendre() {
    if (!_voulu) {
      return;
    }
    _voulu = false;
    unawaited(_suiviVisibilite?.cancel());
    _suiviVisibilite = null;
    final Object? verrou = _verrou;
    _verrou = null;
    final VerrouEcranNavigateur? nav = _navigateur;
    if (verrou != null && nav != null && !nav.estRelache(verrou)) {
      unawaited(
        nav
            .relacher(verrou)
            .catchError(
              (Object e) => journalDev('ecran eveille : rendu imparfait ($e)'),
            ),
      );
    }
  }
}
