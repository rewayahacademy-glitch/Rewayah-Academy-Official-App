// TRANSITIONS, regle 9 (DECISION-MOUVEMENT-2026-11-11) : sur le web, un
// retour demande par le navigateur (bouton, geste de Safari) joue un fondu
// court, jamais une seconde animation par-dessus celle du navigateur. Un
// retour par la fleche de l'application joue l'axe partage inverse, comme
// sur les autres plateformes. Ce fichier dit lequel des deux est en cours.

import 'retour_navigateur_aucun.dart'
    if (dart.library.js_interop) 'retour_navigateur_web.dart';

/// Le dernier retour demande par le navigateur, date.
abstract final class RetourNavigateur {
  /// Combien de temps un retour du navigateur colore la transition qui le
  /// suit : plus que la plus longue sortie de page (2/3 de 280 ms).
  static const Duration fenetre = Duration(milliseconds: 600);

  static DateTime? _dernier;
  static bool _ecoute = false;

  /// L'horloge, remplacable par les tests.
  static DateTime Function() horloge = DateTime.now;

  /// Branche l'ecoute du navigateur, une seule fois (`main`, sur le web).
  static void ecouter() {
    if (_ecoute) return;
    _ecoute = true;
    ecouterRetourNavigateur(signaler);
  }

  /// Le navigateur vient de demander un retour.
  static void signaler() => _dernier = horloge();

  /// Vrai pendant [fenetre] apres un retour du navigateur.
  static bool recent() {
    final DateTime? dernier = _dernier;
    return dernier != null && horloge().difference(dernier) < fenetre;
  }

  /// Oublie le dernier retour (tests).
  static void oublier() => _dernier = null;
}

/// La transition d'une page qui part sur le web : vrai pour le fondu court
/// (retour demande par le navigateur), faux pour l'axe partage inverse
/// (fleche de l'application, ou hors web).
bool fonduDeRetourWeb({
  required bool web,
  required bool retourEnCours,
  required bool retourDuNavigateur,
}) => web && retourEnCours && retourDuNavigateur;
