// MA-TUTOIEMENT-1 (decision A4 = a) : le registre suit l'age de l'eleve
// devant l'ecran, jamais la presentation (MA1, deux axes). Un mineur est
// tutoye ; un adulte, ou un age que l'application ne connait pas, est
// vouvoye.
//
// L'age reel vient du serveur a BR-1. D'ici la, le port est neutre (K-09) :
// il dit « inconnu », sans aucun appel (K-28). La demonstration connait
// l'age de ses eleves et le passe directement aux ecrans.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'age de l'eleve, tel que l'application le connait.
enum AgeEleve {
  /// Eleve mineur : tutoye.
  mineur,

  /// Eleve adulte : vouvoye.
  adulte,

  /// Age non connu (avant BR-1) : vouvoye par defaut.
  inconnu;

  /// Vrai seulement pour un mineur connu.
  bool get tutoiement => this == AgeEleve.mineur;
}

/// Lit l'age de l'eleve connecte.
abstract interface class PortAgeEleve {
  /// L'age de l'eleve connecte.
  AgeEleve ageDeLEleve();
}

/// Le port neutre (K-09) : l'age n'est pas connu avant BR-1.
class AgeEleveInconnu implements PortAgeEleve {
  /// Cree le port neutre.
  const AgeEleveInconnu();

  @override
  AgeEleve ageDeLEleve() => AgeEleve.inconnu;
}

/// Le port employe par l'application : neutre tant que BR-1 ne l'a pas
/// cable.
final Provider<PortAgeEleve> portAgeEleveProvider = Provider<PortAgeEleve>(
  (Ref ref) => const AgeEleveInconnu(),
);
