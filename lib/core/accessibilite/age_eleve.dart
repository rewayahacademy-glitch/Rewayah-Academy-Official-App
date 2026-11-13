// MA-TUTOIEMENT-1 (decision A4 = a) : le registre suit l'age de l'eleve
// devant l'ecran, jamais la presentation (MA1, deux axes). Un mineur est
// tutoye ; un adulte, ou un age que l'application ne connait pas, est
// vouvoye.
//
// L'age reel vient du serveur a BR-1. D'ici la, le port est neutre (K-09) :
// il dit « inconnu », sans aucun appel (K-28). La demonstration connait
// l'age de ses eleves et le passe directement aux ecrans.
//
// SALLE (garde-cap et pilote, 11/11/2026) : « BR-1 » n'avait pas de date, et
// en production un ENFANT etait vouvoye dans la salle. La donnee existe sur le
// serveur (`student_profiles.student_type`, deja lue pour l'Accueil du Mode
// Accessibilite) : [PortLectureAgeEleve] la lit pour l'eleve devant l'ecran
// (l'eleve connecte, ou l'enfant du foyer pour qui le tuteur ouvre la salle),
// et [ageEleveProvider] la garde le temps de la session. Aucun age n'est
// calcule ici : le serveur dit « mineur » ou « autonome ». Lecture absente ou
// en echec : inconnu, donc vouvoiement, comme avant.

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

/// Lit l'age d'UN eleve sur le serveur (son type : mineur ou autonome).
abstract interface class PortLectureAgeEleve {
  /// L'age de l'eleve [eleveId]. Ne lance jamais : une lecture impossible
  /// rend [AgeEleve.inconnu] (vouvoiement).
  Future<AgeEleve> lire(String eleveId);
}

/// Le port neutre : aucune lecture, age inconnu (tests, demonstration).
class LectureAgeEleveInconnue implements PortLectureAgeEleve {
  /// Cree le port neutre.
  const LectureAgeEleveInconnue();

  @override
  Future<AgeEleve> lire(String eleveId) async => AgeEleve.inconnu;
}

/// Le port de lecture employe par l'application (Supabase en production).
final Provider<PortLectureAgeEleve> portLectureAgeEleveProvider =
    Provider<PortLectureAgeEleve>((Ref ref) => const LectureAgeEleveInconnue());

/// L'age de l'eleve [eleveId], lu une fois puis garde.
final ageEleveProvider = FutureProvider.family<AgeEleve, String>(
  (Ref ref, String eleveId) =>
      ref.watch(portLectureAgeEleveProvider).lire(eleveId),
);
