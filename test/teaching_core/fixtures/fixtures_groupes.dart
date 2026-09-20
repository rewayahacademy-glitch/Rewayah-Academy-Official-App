// Fixtures de Groupe : plein, partiel, sans photo d'enseignant, et deux
// capacites differentes pour prouver qu'aucune n'est codee en dur.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.

import 'contrats/contrats_a_groupe.dart';
import 'contrats/contrats_a_horloge.dart';
import 'fixtures_horloge.dart';

/// L'etat de la photo d'un enseignant.
///
/// **Ce n'est PAS un type de contrat.** C'est la forme executable de la
/// decision D-01 : l'absence de photo declenche un etat d'erreur ou de
/// migration EXPLICITE. L'enumeration ne compte volontairement que deux
/// valeurs : il n'existe aucun `avatarGenerique`, et c'est tout le sujet.
///
/// Le type canonique manque cote production : demande ouverte dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_Q.md`.
enum EtatPhotoEnseignant {
  /// La cle de photo est presente et exploitable.
  presente,

  /// La cle manque : etat d'erreur ou de migration, jamais un avatar par
  /// defaut.
  manquante,
}

/// Lit l'etat de la photo d'un enseignant.
EtatPhotoEnseignant etatPhoto(EnseignantVM enseignant) {
  final String? cle = enseignant.photoUrlOuCle;
  if (cle == null || cle.trim().isEmpty) return EtatPhotoEnseignant.manquante;
  return EtatPhotoEnseignant.presente;
}

/// Le libelle d'effectif, **toujours derive de la donnee serveur**.
///
/// Jamais `'$nombreMembres / 5'` : la capacite vient du groupe, et elle vaut
/// 5 pour les enfants, 6 pour les adultes, et ce que l'administration decide
/// dans les autres cas.
String libelleEffectif(GroupSummaryVM groupe) =>
    '${groupe.nombreMembres} / ${groupe.seuilMax}';

/// Le nom complet d'un enseignant dans le contexte cours : « Sayyid Yacine ».
String libelleEnseignant(EnseignantVM enseignant) =>
    '${enseignant.titre.libelleFr} ${enseignant.nomAffichage}';

/// Un enseignant avec photo.
const EnseignantVM enseignantAvecPhoto = EnseignantVM(
  enseignantId: 'ens-001',
  titre: TitreEnseignant.sayyid,
  nomAffichage: 'Yacine',
  // Une CLE de Storage, jamais une URL signee : une URL signee expire, la cle
  // non (CONTRACTS section 4, invariant 2).
  photoUrlOuCle: 'teacher-photos/ens-001.jpg',
);

/// Une enseignante avec photo, pour verifier les deux titres.
const EnseignantVM enseignanteAvecPhoto = EnseignantVM(
  enseignantId: 'ens-002',
  titre: TitreEnseignant.sayyida,
  nomAffichage: 'Khadija',
  photoUrlOuCle: 'teacher-photos/ens-002.jpg',
);

/// Un enseignant sans photo : le cas que D-01 oblige a rendre visible.
const EnseignantVM enseignantSansPhoto = EnseignantVM(
  enseignantId: 'ens-003',
  titre: TitreEnseignant.sayyid,
  nomAffichage: 'Idriss',
);

/// Un jeton de couleur de la palette administree.
const JetonCouleurGroupe jetonCouleurG17 = JetonCouleurGroupe(
  index: 17,
  codeStable: 'g17',
);

/// Un second jeton, pour verifier que deux groupes se distinguent.
const JetonCouleurGroupe jetonCouleurG04 = JetonCouleurGroupe(
  index: 4,
  codeStable: 'g04',
);

/// Construit une carte de groupe.
GroupSummaryVM groupe({
  required String groupeId,
  required String libelle,
  required int nombreMembres,
  required int seuilMax,
  EnseignantVM enseignant = enseignantAvecPhoto,
  JetonCouleurGroupe couleur = jetonCouleurG17,
  TypePublicGroupeVM typePublic = TypePublicGroupeVM.enfant,
  String? nomCours = 'Coran - memorisation',
  String? niveauHumain = 'Deuxieme annee',
  bool actif = true,
  OccurrenceSeance? prochaineSeance,
  SessionClockVM? horloge,
}) => GroupSummaryVM(
  groupeId: groupeId,
  libelle: libelle,
  couleurJeton: couleur,
  enseignant: enseignant,
  nomCours: nomCours,
  niveauHumain: niveauHumain,
  nombreMembres: nombreMembres,
  seuilMax: seuilMax,
  typePublic: typePublic,
  prochaineSeance: prochaineSeance,
  horloge: horloge,
  actif: actif,
);

/// L'occurrence de reference, rattachee au fuseau du groupe.
final OccurrenceSeance prochaineOccurrence = OccurrenceSeance(
  sessionId: 'seance-1',
  debutUtc: debutSeanceAvantDst,
  duree: dureeSeance,
  fuseauReferenceGroupe: fuseauParis,
);

/// Un groupe **plein** : cinq enfants sur cinq places.
final GroupSummaryVM groupePlein = groupe(
  groupeId: 'grp-plein',
  libelle: 'Les Lanternes',
  nombreMembres: 5,
  seuilMax: 5,
  prochaineSeance: prochaineOccurrence,
  horloge: horlogeSeance(
    maintenant: instantDe(MomentSeance.tMoins30),
    horlogeContrepartie: horlogeConakryAvantDst,
  ),
);

/// Un groupe **partiel** a 4 / 5.
final GroupSummaryVM groupeQuatreSurCinq = groupe(
  groupeId: 'grp-4-5',
  libelle: 'Les Palmiers',
  nombreMembres: 4,
  seuilMax: 5,
  couleur: jetonCouleurG04,
  prochaineSeance: prochaineOccurrence,
  horloge: horlogeSeance(maintenant: instantDe(MomentSeance.tMoins20)),
);

/// Un groupe **partiel** a 3 / 4.
///
/// Sa seule raison d'exister : prouver qu'un affichage « x / 5 » serait faux.
/// Le seuil de ce groupe-la vaut 4, et il vient du serveur.
final GroupSummaryVM groupeTroisSurQuatre = groupe(
  groupeId: 'grp-3-4',
  libelle: 'Les Sources',
  nombreMembres: 3,
  seuilMax: 4,
  couleur: jetonCouleurG04,
  typePublic: TypePublicGroupeVM.adulte,
  niveauHumain: 'Premiere annee',
);

/// Un groupe dont l'enseignant n'a pas de photo.
final GroupSummaryVM groupeSansPhotoEnseignant = groupe(
  groupeId: 'grp-sans-photo',
  libelle: 'Les Aurores',
  nombreMembres: 2,
  seuilMax: 6,
  enseignant: enseignantSansPhoto,
  typePublic: TypePublicGroupeVM.adulte,
);

/// Un groupe d'adultes plein, a six : la capacite n'est pas la meme partout.
final GroupSummaryVM groupeAdultePlein = groupe(
  groupeId: 'grp-adulte',
  libelle: 'Les Veilleurs',
  nombreMembres: 6,
  seuilMax: 6,
  enseignant: enseignanteAvecPhoto,
  typePublic: TypePublicGroupeVM.adulte,
);

/// Un groupe clos : `groupes.ended_at` est renseigne.
final GroupSummaryVM groupeClos = groupe(
  groupeId: 'grp-clos',
  libelle: 'Les Anciens',
  nombreMembres: 0,
  seuilMax: 5,
  actif: false,
  nomCours: null,
  niveauHumain: null,
);

/// Tous les groupes de fixture, pour les tests qui balayent l'ensemble.
List<GroupSummaryVM> tousLesGroupes() => <GroupSummaryVM>[
  groupePlein,
  groupeQuatreSurCinq,
  groupeTroisSurQuatre,
  groupeSansPhotoEnseignant,
  groupeAdultePlein,
  groupeClos,
];
