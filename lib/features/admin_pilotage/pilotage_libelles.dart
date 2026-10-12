/// ECHELLE-ADM-PILOTAGE-1 : la mise en mots du tableau de pilotage.
///
/// Fonctions pures : l'ecran ne decide rien, il dit ce que le port rend.
library;

import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_pilotage.dart';
import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/tc_groupe/libelles_tc_groupe.dart' show LibellesGroupe;
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute;
import '../creneaux/plages.dart' show jourCapitalise;

/// « Lundi · 18 h · Paris » : l'horaire d'une ligne, sans ambiguite sur le
/// fuseau.
String libelleHoraire(Creneau c) => t.admin.pilotage.horaire(
  jour: jourCapitalise(c.jour),
  heure: libelleHeureMinute(c.heure, 0),
  ville: villeDuFuseauLibelle(c.fuseau),
);

/// « Enfants », « Adultes ».
String libelleCategorie(TypePublicGroupe type) => switch (type) {
  TypePublicGroupe.enfant => t.admin.groupes.typeEnfant,
  TypePublicGroupe.adulte => t.admin.groupes.typeAdulte,
};

/// « 2 enseignantes » : un nombre d'enseignants du [genre] dit au bon accord.
String libelleEnseignantsGenre(GenreClasse genre, int n) => switch (genre) {
  GenreClasse.hommes => t.admin.pilotage.genreHommes(n: n),
  GenreClasse.femmes => t.admin.pilotage.genreFemmes(n: n),
  GenreClasse.indetermine => t.admin.pilotage.genreIndetermine(n: n),
};

/// « 3 (2 enseignantes, 1 enseignant) » : un total et sa part par genre.
/// Zero se dit « Aucun », sans detail. [valeur] choisit ce qu'on compte :
/// les libres ou les manquants.
String libelleCompteParGenre(
  List<EnseignantsGenre> parGenre,
  int Function(EnseignantsGenre g) valeur,
) {
  final List<EnseignantsGenre> presents = <EnseignantsGenre>[
    for (final EnseignantsGenre g in parGenre)
      if (valeur(g) > 0) g,
  ];
  final int total = presents.fold<int>(
    0,
    (int n, EnseignantsGenre g) => n + valeur(g),
  );
  if (total == 0) return t.admin.pilotage.aucun;
  return t.admin.pilotage.nombreEtGenres(
    n: total,
    genres: presents
        .map(
          (EnseignantsGenre g) => libelleEnseignantsGenre(g.genre, valeur(g)),
        )
        .join(', '),
  );
}

/// « 82 % (123 sur 150) », ou « Aucune place ouverte » sans capacite.
String libelleRemplissage(LignePilotage l) {
  final int? taux = l.tauxRemplissage;
  if (taux == null) return t.admin.pilotage.remplissageInconnu;
  return LibellesGroupe.insecable(
    t.admin.pilotage.remplissage(
      taux: '$taux',
      effectif: '${l.effectif}',
      capacite: '${l.capacite}',
    ),
  );
}

/// Le public d'un regroupement, tel que le port des regroupements le connait.
PublicOffre offreDe(TypePublicGroupe type) => switch (type) {
  TypePublicGroupe.enfant => PublicOffre.enfants,
  TypePublicGroupe.adulte => PublicOffre.adultes,
};

/// Le regroupement qui porte une classe sans enseignant, pour reutiliser la
/// feuille « Choisir l'enseignant » : la classe existe, son enseignant reste
/// a confirmer. `null` quand son horaire n'est pas lisible (jour hors de 1 a
/// 7) : aucune action n'est alors proposee.
RegroupementDemandes? regroupementDeClasse(ClasseListee c) {
  final Creneau creneau = c.groupe.creneau;
  if (creneau.jour < 1 ||
      creneau.jour > 7 ||
      creneau.heure < 0 ||
      creneau.heure > 23) {
    return null;
  }
  return RegroupementDemandes(
    id: 'classe-${c.id}',
    public: offreDe(c.groupe.type),
    langueCode: '',
    langueNom: '',
    fuseau: creneau.fuseau,
    occurrences: <OccurrenceCreneau>[
      OccurrenceCreneau(jourIso: creneau.jour, heure: creneau.heure),
    ],
    nombreEleves: c.groupe.nombreMembres,
    quota: c.groupe.seuilMax,
    classe: ClasseSansEnseignant(
      classeId: c.id,
      libelle: c.groupe.libelle,
      genre: c.genre,
      peutAffecterEnseignant: c.peutAffecterEnseignant,
      numeroDansFamille: c.numeroDansFamille,
      codeCourt: c.codeCourt,
    ),
  );
}
