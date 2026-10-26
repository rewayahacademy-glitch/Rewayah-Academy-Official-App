import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le raccord entre le demarrage et la connexion (PR 2 du parcours d'entree,
/// `docs/current/PARCOURS-ENTREE-2026-10-25.md` §3 A et C) : la porte ne
/// rejoue pas quand on arrive sur la connexion depuis le demarrage, elle
/// reprend la ou le demarrage l'a laissee (image finale si l'entree avait
/// fini), sans coupure.
///
/// L'ecran de demarrage y inscrit l'avancement de son entree a chaque image ;
/// la premiere coquille d'entree qui s'ouvre le **prend** (et le remet a
/// rien) : un retour ou un lien direct plus tard la rejoue du debut. Simple
/// memoire, sans notification : on l'ecrit et on la lit pendant une
/// construction.
class RaccordEntree {
  double? _avancement;

  /// Inscrit l'avancement [p] (0 a 1) de l'entree du demarrage.
  void suivre(double p) => _avancement = p;

  /// Oublie l'entree du demarrage (session active : aucune connexion ne suit).
  void oublier() => _avancement = null;

  /// L'avancement ou reprendre (0 sans demarrage), une seule fois.
  double prendre() {
    final double p = _avancement ?? 0;
    _avancement = null;
    return p;
  }
}

/// Le raccord unique de l'application.
final Provider<RaccordEntree> raccordEntreeProvider = Provider<RaccordEntree>(
  (Ref ref) => RaccordEntree(),
);
