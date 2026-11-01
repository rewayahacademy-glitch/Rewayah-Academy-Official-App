/// OFFRES-ADM-1 : le tri et la mise en mots des regroupements de demandes.
///
/// Fonctions pures : l'ecran ne decide rien, il ordonne ce que le serveur a
/// regroupe et le dit en clair.
///
/// C-11 bis : un regroupement porte une heure par jour. Quand tous les jours
/// ont la meme heure, on la dit une fois (« Lundi, mardi, jeudi · 18 h ») ;
/// sinon chaque jour avec la sienne (« Lundi 18 h, mercredi 19 h 30 »).
/// Jamais l'heure du premier jour prise pour celle des autres.
library;

import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/classes/nom_classe_distinct.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/offres/affectation_refusee.dart';
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/page_regroupements.dart' show trierParPret;
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../admin_groupes/genre_classe_libelles.dart' show libelleGenreClasse;
import '../creneaux/plages.dart' show jourCapitalise;

/// Le tri de la file (demande du directeur) : les regroupements prets
/// d'abord, puis le plus grand nombre d'eleves. A egalite, le premier jour,
/// puis l'heure de ce premier jour, puis l'identifiant : un ordre stable
/// d'une lecture a l'autre.
List<RegroupementDemandes> trierRegroupements(
  Iterable<RegroupementDemandes> regroupements,
) => trierParPret(regroupements);

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

/// « 18 h », « 18 h 30 », insecables (DUREE-INSECABLE-3).
String libelleHeureMinute(int heure, int minute) => minute == 0
    ? LibellesGroupe.insecable(t.admin.regroupements.heure(heure: '$heure'))
    : LibellesGroupe.insecable(
        t.admin.regroupements.heureMinutes(
          heure: '$heure',
          minutes: minute.toString().padLeft(2, '0'),
        ),
      );

/// « 18 h », « 18 h 30 », pour une heure d'un autre fuseau.
String libelleHeure(HeureDansFuseau h) => libelleHeureMinute(h.heure, h.minute);

/// L'heure commune a tous les jours (« 18 h »), `null` quand les jours n'ont
/// pas tous la meme heure.
String? libelleHeureCommune(RegroupementDemandes g) {
  if (g.occurrences.isEmpty || !g.heuresToutesEgales) return null;
  final OccurrenceCreneau o = g.occurrences.first;
  return libelleHeureMinute(o.heure, o.minute);
}

/// « Lundi 18 h, mercredi 19 h 30 » : chaque jour avec son heure, du lundi
/// au dimanche, le premier en capitale.
String libelleJoursHeures(RegroupementDemandes g) => <String>[
  for (final (int i, OccurrenceCreneau o) in g.occurrences.indexed)
    t.admin.regroupements.jourHeure(
      jour: i == 0
          ? jourCapitalise(o.jourIso)
          : t.disponibilites.joursLongs[o.jourIso - 1],
      heure: libelleHeureMinute(o.heure, o.minute),
    ),
].join(', ');

/// Le titre d'une carte : « Lundi, mardi, jeudi · 18 h » quand l'heure est
/// commune, « Lundi 18 h, mercredi 19 h 30 » sinon.
String libelleCreneau(RegroupementDemandes g) {
  final String? heure = libelleHeureCommune(g);
  return heure == null
      ? libelleJoursHeures(g)
      : '${libelleJours(g.jours)} · $heure';
}

/// « 18 h, heure de Paris » : l'heure de reference commune et son fuseau,
/// `null` quand les jours n'ont pas tous la meme heure.
String? libelleReference(RegroupementDemandes g) {
  final String? heure = libelleHeureCommune(g);
  if (heure == null) return null;
  return t.admin.regroupements.heureFuseau(
    heure: heure,
    deVille: deDevant(
      villeDuFuseauLibelle(g.fuseau),
      cle: 'admin.regroupements.heureFuseau',
    ),
  );
}

/// « Heure de Paris » : le fuseau de reference, dit seul quand chaque jour a
/// son heure.
String libelleFuseau(RegroupementDemandes g) =>
    t.admin.regroupements.fuseauValeur(
      deVille: deDevant(
        villeDuFuseauLibelle(g.fuseau),
        cle: 'admin.regroupements.fuseauValeur',
      ),
    );

/// « 12 h a Toronto », « 5 h le lendemain a Paris ».
String libelleAilleurs(HeureDansFuseau h) {
  final r = t.admin.regroupements;
  final String heure = libelleHeure(h);
  final String ville = villeDuFuseauLibelle(h.fuseau);
  return switch (h.decalageJour) {
    < 0 => r.ailleursVeille(heure: heure, ville: ville),
    > 0 => r.ailleursLendemain(heure: heure, ville: ville),
    _ => r.ailleursMemeJour(heure: heure, ville: ville),
  };
}

/// Les heures des autres fuseaux, separees par « · ». Une heure qui ne vaut
/// que pour un jour le dit (« Mercredi : 18 h a London ») ; celles qui valent
/// pour tous les jours viennent d'abord, puis les autres du lundi au
/// dimanche, dans l'ordre rendu par le serveur a jour egal.
String libelleAutresFuseaux(RegroupementDemandes g) {
  final List<HeureDansFuseau> rangees = <HeureDansFuseau>[
    ...g.autresFuseaux.where((HeureDansFuseau h) => h.jourIso == null),
    for (int jour = 1; jour <= 7; jour++)
      ...g.autresFuseaux.where((HeureDansFuseau h) => h.jourIso == jour),
  ];
  return <String>[
    for (final HeureDansFuseau h in rangees)
      if (h.jourIso case final int jour)
        t.admin.regroupements.ailleursJour(
          jour: jourCapitalise(jour),
          ailleurs: libelleAilleurs(h),
        )
      else
        libelleAilleurs(h),
  ].join(' · ');
}

/// Le nom deduit de la classe (meme forme que CLASSE-FORM-1, D8) : le genre
/// (ou le public si le genre n'est pas determine), puis les jours et l'heure
/// (l'heure de chaque jour quand elles different).
String nomDeduit(RegroupementDemandes r, GenreClasse? genre) {
  final TypePublicGroupe type = typeDe(r.public);
  final String base = genre == null || genre == GenreClasse.indetermine
      ? nomPublic(r.public)
      : libelleGenreClasse(genre, type);
  final String? heure = libelleHeureCommune(r);
  return t.admin.groupes.formulaire.nomPropose(
    base: base,
    creneau: heure == null
        ? libelleJoursHeures(r).toLowerCase()
        : '${libelleJours(r.jours).toLowerCase()} $heure',
  );
}

/// R16 : le nom deduit, suivi du numero que le serveur donnera a la classe
/// parmi les classes paralleles de meme cle (« Garcons, lundi 18 h · n° 4 »).
/// Sans numero rendu, le nom deduit seul. Le libelle envoye au serveur reste
/// [nomDeduit] : le numero est porte a part, il ne s'ecrit pas dans le nom.
String nomDeduitDistinct(RegroupementDemandes r, GenreClasse? genre) =>
    nomClasseDistinct(nomDeduit(r, genre), numero: r.numeroProchaineClasse);

/// R16 : le nom d'une classe creee depuis un regroupement, avec son numero
/// dans la famille de classes paralleles (ou son code court).
String nomClasseRegroupee(ClasseSansEnseignant c) => nomClasseDistinct(
  c.libelle,
  numero: c.numeroDansFamille,
  code: c.codeCourt,
);

/// R3 : « 12 demandes → 2 classes possibles ». Le nombre de classes vient du
/// serveur ([RegroupementDemandes.classesPossiblesLues]).
String libelleDemandesClasses(RegroupementDemandes g) {
  final r = t.admin.regroupements;
  return r.demandesVersClasses(
    demandes: r.demandes(n: g.nombreEleves),
    classes: r.classesPossibles(n: g.classesPossiblesLues),
  );
}

/// Les seances de la semaine du regroupement, dans son fuseau, chacune a
/// l'heure de son jour : ce que la proposition d'enseignant compare a ses
/// creneaux libres.
List<Creneau> creneauxDe(RegroupementDemandes r) => <Creneau>[
  for (final OccurrenceCreneau o in r.occurrences)
    Creneau(jour: o.jourIso, heure: o.heure, fuseau: r.fuseau),
];

/// R3 : « 2 classes de 5, 2 élèves en attente ». Une partie vide ne se dit
/// pas ; sans classe, « aucune classe ».
String libelleDecoupage(DecoupageClasses d) {
  final r = t.admin.regroupements;
  final List<String> parties = <String>[
    if (d.pleines > 0)
      r.decoupagePleines(n: d.pleines, taille: d.tailleMax)
    else if (d.derniere == null)
      r.decoupageAucuneClasse,
    if (d.derniere case final int n) r.decoupageDerniere(n: n),
    if (d.enAttente > 0) r.decoupageAttente(n: d.enAttente),
  ];
  return parties.join(', ');
}

/// C11BIS-AFFECTATION : la phrase d'un refus du serveur a la confirmation de
/// l'enseignant, une par motif. Le texte SQL n'est jamais montre ; un motif
/// inconnu donne la phrase generique.
///
/// FN-113 : pour le maximum de Classes, [actives] et [maximum] viennent du
/// DETAIL du serveur ; sans eux, la phrase sans nombre.
String libelleRefusAffectation(
  MotifRefusAffectation motif, {
  int? actives,
  int? maximum,
}) {
  final r = t.admin.regroupements.refusAffectation;
  return switch (motif) {
    MotifRefusAffectation.plafondClasses =>
      actives != null && maximum != null
          ? r.plafondClasses(n: actives, maximum: maximum)
          : r.plafondClassesSansNombre,
    MotifRefusAffectation.reservee => r.reservee,
    MotifRefusAffectation.classeIndisponible => r.classeIndisponible,
    MotifRefusAffectation.enseignantIndisponible => r.enseignantIndisponible,
    MotifRefusAffectation.genreIncompatible => r.genreIncompatible,
    MotifRefusAffectation.plafond => r.plafond,
    MotifRefusAffectation.nonDisponible => r.nonDisponible,
    MotifRefusAffectation.chevauchementClasse => r.chevauchementClasse,
    MotifRefusAffectation.chevauchementSeance => r.chevauchementSeance,
    MotifRefusAffectation.inconnu => r.inconnu,
  };
}
