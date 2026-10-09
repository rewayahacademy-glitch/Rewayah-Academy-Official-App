/// OFFRES-ADM-1 : le tri et la mise en mots des regroupements de demandes.
///
/// Fonctions pures : l'ecran ne decide rien, il ordonne ce que le serveur a
/// regroupe et le dit en clair.
library;

import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../admin_groupes/genre_classe_libelles.dart' show libelleGenreClasse;
import '../creneaux/plages.dart' show jourCapitalise;

/// Le tri de la file (demande du directeur) : les regroupements prets
/// d'abord, puis le plus grand nombre d'eleves. A egalite, le premier jour,
/// puis l'heure, puis l'identifiant : un ordre stable d'une lecture a
/// l'autre.
List<RegroupementDemandes> trierRegroupements(
  Iterable<RegroupementDemandes> regroupements,
) {
  int premierJour(RegroupementDemandes r) =>
      r.jours.isEmpty ? 8 : r.jours.first;
  return regroupements.toList()
    ..sort((RegroupementDemandes a, RegroupementDemandes b) {
      final int pret = (a.pret ? 0 : 1).compareTo(b.pret ? 0 : 1);
      if (pret != 0) return pret;
      final int nombre = b.nombreEleves.compareTo(a.nombreEleves);
      if (nombre != 0) return nombre;
      final int jour = premierJour(a).compareTo(premierJour(b));
      if (jour != 0) return jour;
      final int heure = (a.reference.heure * 60 + a.reference.minute).compareTo(
        b.reference.heure * 60 + b.reference.minute,
      );
      if (heure != 0) return heure;
      return a.id.compareTo(b.id);
    });
}

/// Le public d'un regroupement, tel que la creation d'une classe le connait.
TypePublicGroupe typeDe(PublicOffre public) => switch (public) {
  PublicOffre.enfants => TypePublicGroupe.enfant,
  PublicOffre.adultes => TypePublicGroupe.adulte,
};

/// « Enfants », « Adultes ».
String nomPublic(PublicOffre public) => switch (public) {
  PublicOffre.enfants => t.admin.groupes.typeEnfant,
  PublicOffre.adultes => t.admin.groupes.typeAdulte,
};

/// « Lundi, mardi, jeudi » : les jours dans l'ordre de la semaine, le premier
/// en capitale.
String libelleJours(List<int> jours) {
  final List<int> tries = jours.toSet().toList()..sort();
  return <String>[
    for (final (int i, int j) in tries.indexed)
      i == 0 ? jourCapitalise(j) : t.disponibilites.joursLongs[j - 1],
  ].join(', ');
}

/// « 18 h », « 18 h 30 ».
String libelleHeure(HeureDansFuseau h) => h.minute == 0
    ? t.admin.regroupements.heure(heure: '${h.heure}')
    : t.admin.regroupements.heureMinutes(
        heure: '${h.heure}',
        minutes: h.minute.toString().padLeft(2, '0'),
      );

/// La ville d'un fuseau IANA, telle qu'on la dit : « Europe/Paris » donne
/// « Paris », « America/Los_Angeles » donne « Los Angeles ». Un identifiant
/// sans ville (`UTC`) reste tel quel. Le nom IANA complet ne tient pas en
/// une ligne a 320 px en texte agrandi, et il n'apprend rien de plus.
String villeDuFuseau(String iana) =>
    iana.substring(iana.lastIndexOf('/') + 1).replaceAll('_', ' ');

/// « 18 h, heure de Paris » : l'heure de reference et son fuseau.
String libelleReference(HeureDansFuseau h) => t.admin.regroupements.heureFuseau(
  heure: libelleHeure(h),
  deVille: deDevant(villeDuFuseau(h.fuseau)),
);

/// « 12 h a Toronto », « 5 h le lendemain a Paris ».
String libelleAilleurs(HeureDansFuseau h) {
  final r = t.admin.regroupements;
  final String heure = libelleHeure(h);
  final String ville = villeDuFuseau(h.fuseau);
  return switch (h.decalageJour) {
    < 0 => r.ailleursVeille(heure: heure, ville: ville),
    > 0 => r.ailleursLendemain(heure: heure, ville: ville),
    _ => r.ailleursMemeJour(heure: heure, ville: ville),
  };
}

/// Le nom deduit de la classe (meme forme que CLASSE-FORM-1, D8) : le genre
/// (ou le public si le genre n'est pas determine), puis les jours et l'heure.
String nomDeduit(RegroupementDemandes r, GenreClasse? genre) {
  final TypePublicGroupe type = typeDe(r.public);
  final String base = genre == null || genre == GenreClasse.indetermine
      ? nomPublic(r.public)
      : libelleGenreClasse(genre, type);
  final String jours = libelleJours(r.jours).toLowerCase();
  return t.admin.groupes.formulaire.nomPropose(
    base: base,
    creneau: '$jours ${libelleHeure(r.reference)}',
  );
}

/// Les seances de la semaine du regroupement, dans son fuseau : ce que la
/// proposition d'enseignant compare a ses creneaux libres.
List<Creneau> creneauxDe(RegroupementDemandes r) => <Creneau>[
  for (final int j in r.jours.toSet().toList()..sort())
    Creneau(jour: j, heure: r.reference.heure, fuseau: r.reference.fuseau),
];
