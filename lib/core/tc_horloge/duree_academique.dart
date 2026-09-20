/// La duree **academique** reellement creditee a un participant.
///
/// C'est la forme executable de la correction demandee par la decision D-13 :
/// borner le depart a `max(entreLe, debutSeance)`. Sans elle, un eleve entre a
/// T-20 dans un cours commence depuis 18 minutes se verrait crediter 38
/// minutes.
///
/// Rend `Duration.zero` -- jamais une duree negative -- quand l'entree est
/// posterieure a l'instant d'observation, ou quand rien n'a ete lu.
///
/// Promu par Agent Q (TC_CONTRACT_REQUEST_Q.md section 3) : c'est le pendant
/// Dart exact du bornage SQL `greatest(entre_le, started_at)` d'`etat_presence()`.
Duration dureeAcademique({
  required DateTime? entreLe,
  required DateTime debutSeance,
  required DateTime maintenant,
  DateTime? finSeance,
}) {
  if (entreLe == null) return Duration.zero;
  final DateTime depart = entreLe.isAfter(debutSeance) ? entreLe : debutSeance;
  final DateTime arrivee = finSeance != null && finSeance.isBefore(maintenant)
      ? finSeance
      : maintenant;
  if (!arrivee.isAfter(depart)) return Duration.zero;
  return arrivee.difference(depart);
}
