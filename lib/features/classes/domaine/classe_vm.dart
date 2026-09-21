import 'package:flutter/foundation.dart';

import '../../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../../core/tc_horloge/session_clock_vm.dart';

/// Le public d'une Classe.
///
/// Miroir de `TypePublicGroupe` (`lib/core/admin/service_groupes.dart`) et de
/// `TypePublicGroupeVM` (`lib/core/tc_groupe/`), qui sont des chemins de
/// lecture serveur. La capacite ne s'en deduit **jamais** : elle vient de la
/// donnee serveur ou des regles de l'academie, pas d'un nombre ecrit ici.
enum PublicClasse {
  /// Enfants.
  enfants('enfant'),

  /// Adultes.
  adultes('adulte');

  const PublicClasse(this.valeurSql);

  /// La valeur telle que la base la connait.
  final String valeurSql;

  /// Lit un public depuis sa valeur SQL. Se replie sur [enfants], le public
  /// dont la capacite est la plus basse : un public mal lu ne doit jamais
  /// laisser entrer plus de monde que prevu.
  static PublicClasse depuisSql(String? valeur) =>
      valeur == 'adulte' ? PublicClasse.adultes : PublicClasse.enfants;
}

/// L'etat de publication d'une Classe.
enum EtatPublication {
  /// Preparee, pas encore visible des enseignants ni des familles.
  brouillon,

  /// Visible et ouverte aux candidatures et aux inscriptions.
  publiee,

  /// Fermee : plus personne n'y entre.
  cloturee,
}

/// Ou en est la candidature de l'appelant a une Classe.
enum EtatCandidature {
  /// Aucune candidature.
  aucune,

  /// Envoyee, l'academie n'a pas repondu.
  envoyee,

  /// Acceptee : l'enseignant est affecte.
  acceptee,

  /// Refusee.
  refusee,
}

/// Le creneau hebdomadaire d'une Classe.
///
/// **Un motif, pas un instant** : un jour ISO, une heure locale et un fuseau
/// IANA. Aucun widget ne convertit ce fuseau ; le serveur rend les instants
/// deja convertis (`SessionClockVM`). [libelleVille] est le nom lisible du
/// fuseau, jamais un « UTC+3 ».
@immutable
class CreneauClasse {
  /// Cree un creneau.
  const CreneauClasse({
    required this.jourIso,
    required this.heure,
    required this.fuseauIana,
    this.minute = 0,
    this.libelleVille,
  }) : assert(jourIso >= 1 && jourIso <= 7, 'un jour ISO va de 1 a 7'),
       assert(heure >= 0 && heure <= 23, 'une heure locale va de 0 a 23');

  /// Le jour ISO, 1 pour lundi, 7 pour dimanche.
  final int jourIso;

  /// L'heure locale pleine.
  final int heure;

  /// Les minutes. Zero pour une grille a l'heure.
  final int minute;

  /// Le fuseau IANA de reference de la Classe.
  final String fuseauIana;

  /// Le nom lisible du fuseau, quand le serveur le rend.
  final String? libelleVille;

  /// Une cle stable, pour distinguer deux cases d'une grille.
  String get cle => '$jourIso-$heure-$minute';

  @override
  bool operator ==(Object other) =>
      other is CreneauClasse &&
      other.jourIso == jourIso &&
      other.heure == heure &&
      other.minute == minute &&
      other.fuseauIana == fuseauIana;

  @override
  int get hashCode => Object.hash(jourIso, heure, minute, fuseauIana);
}

/// L'enseignant d'une Classe, tel que les cartes le nomment.
@immutable
class EnseignantClasse {
  /// Cree l'identite d'un enseignant.
  const EnseignantClasse({
    required this.id,
    required this.nomAffichage,
    this.titre,
  });

  /// L'identifiant du profil. Jamais affiche.
  final String id;

  /// Le prenom, ou le nom d'affichage autorise.
  final String nomAffichage;

  /// Sayyid ou Sayyida, quand la base le porte.
  final TitreEnseignant? titre;
}

/// La prochaine seance connue d'une Classe.
///
/// Les chaines arrivent **deja rendues** par le serveur : aucun widget ne
/// convertit un fuseau, et aucun compte a rebours ne se calcule sur l'horloge
/// de l'appareil.
@immutable
class SeanceAVenir {
  /// Cree une seance a venir.
  const SeanceAVenir({
    required this.debutUtc,
    this.sessionId,
    this.dateRendue,
    this.heureRendue,
    this.rejoindreOuvert = false,
  });

  /// L'identifiant de la seance. `null` tant qu'elle n'est pas materialisee.
  final String? sessionId;

  /// Le debut, en UTC.
  final DateTime debutUtc;

  /// La date, deja rendue dans le fuseau de la personne qui regarde.
  final String? dateRendue;

  /// L'heure, deja rendue.
  final String? heureRendue;

  /// Vrai quand le serveur dit que « Rejoindre » peut etre offert.
  final bool rejoindreOuvert;
}

/// Une Classe, telle que toutes les cartes du produit la lisent.
///
/// **Une seule forme pour quatre roles.** L'administration, l'enseignant, le
/// tuteur et l'eleve lisent la meme carte ; ce qui change est le bouton
/// contextuel, jamais la structure. Trois invariants :
///
/// 1. [capacite] et [inscrits] viennent **toujours** du serveur ;
/// 2. [programme] et [niveauHumain] sont des noms humains, jamais un code ;
/// 3. aucun identifiant technique n'est affiche : [id] sert a agir, pas a lire.
@immutable
class ClasseVM {
  /// Cree une Classe.
  const ClasseVM({
    required this.id,
    required this.libelle,
    required this.publicClasse,
    required this.creneau,
    required this.capacite,
    required this.inscrits,
    required this.etat,
    this.programme,
    this.niveauHumain,
    this.duree,
    this.seuilMinimal,
    this.enseignant,
    this.prochaineSeance,
    this.horloge,
    this.inscrit = false,
    this.candidature = EtatCandidature.aucune,
    this.capaciteConnue = true,
  }) : assert(capacite > 0, 'une capacite vient du serveur et vaut au moins 1'),
       assert(inscrits >= 0, 'un effectif ne peut pas etre negatif');

  /// L'identifiant technique. **Jamais affiche.**
  final String id;

  /// Le nom familier de la Classe.
  final String libelle;

  /// Le nom humain du programme ou du cours. `null` si aucun n'est rattache.
  final String? programme;

  /// Le nom humain du niveau. **Jamais `code_technique`.**
  final String? niveauHumain;

  /// Enfants ou adultes.
  final PublicClasse publicClasse;

  /// Le creneau hebdomadaire.
  final CreneauClasse creneau;

  /// La duree d'une seance. `null` quand la regle n'est pas connue.
  final Duration? duree;

  /// Le plafond, lu du serveur.
  final int capacite;

  /// Les inscrits, lus du serveur.
  final int inscrits;

  /// Le seuil minimal d'ouverture, quand il est configure.
  final int? seuilMinimal;

  /// L'etat de publication.
  final EtatPublication etat;

  /// L'enseignant affecte. `null` : enseignant a affecter.
  final EnseignantClasse? enseignant;

  /// La prochaine seance connue, ou `null`.
  final SeanceAVenir? prochaineSeance;

  /// L'horloge de la prochaine seance, quand le port la rend.
  final SessionClockVM? horloge;

  /// Vrai quand l'appelant, ou le membre pour qui il regarde, est inscrit.
  final bool inscrit;

  /// Ou en est la candidature de l'appelant, cote enseignant.
  final EtatCandidature candidature;

  /// Faux pour un brouillon dont la capacite viendra du defaut de l'academie :
  /// la carte dit alors « Defaut de l'academie » au lieu d'un nombre.
  final bool capaciteConnue;

  /// Vrai quand la Classe est au plafond.
  bool get complete => inscrits >= capacite;

  /// Les places encore libres, jamais negatif.
  int get placesLibres {
    final int reste = capacite - inscrits;
    return reste < 0 ? 0 : reste;
  }

  /// Vrai quand aucun enseignant n'est affecte.
  bool get enseignantAAffecter => enseignant == null;

  /// Vrai quand « Rejoindre » peut etre offert.
  ///
  /// **Une seule source, celle du serveur** : l'horloge quand elle existe, la
  /// seance a venir sinon. Un ecran qui deciderait lui-meme proposerait une
  /// porte que `autoriser_jeton_video()` refuserait.
  bool get rejoindreOuvert =>
      horloge?.rejoindreOuvert ?? prochaineSeance?.rejoindreOuvert ?? false;

  /// La meme Classe, avec un autre etat de candidature.
  ClasseVM avecCandidature(EtatCandidature nouvelle) => ClasseVM(
    id: id,
    libelle: libelle,
    programme: programme,
    niveauHumain: niveauHumain,
    publicClasse: publicClasse,
    creneau: creneau,
    duree: duree,
    capacite: capacite,
    inscrits: inscrits,
    seuilMinimal: seuilMinimal,
    etat: etat,
    enseignant: enseignant,
    prochaineSeance: prochaineSeance,
    horloge: horloge,
    inscrit: inscrit,
    candidature: nouvelle,
  );

  /// La meme Classe, avec l'inscription faite.
  ClasseVM inscrite() => ClasseVM(
    id: id,
    libelle: libelle,
    programme: programme,
    niveauHumain: niveauHumain,
    publicClasse: publicClasse,
    creneau: creneau,
    duree: duree,
    capacite: capacite,
    inscrits: inscrits + 1,
    seuilMinimal: seuilMinimal,
    etat: etat,
    enseignant: enseignant,
    prochaineSeance: prochaineSeance,
    horloge: horloge,
    inscrit: true,
    candidature: candidature,
  );
}

/// Les regles de l'academie qui preremplissent une Classe.
///
/// **Chaque valeur est nullable, et c'est volontaire** : `null` signifie
/// « la base applique son propre defaut ». L'interface ne le remplace jamais
/// par un nombre ecrit ici, elle affiche « Defaut de l'academie ».
@immutable
class ReglesClasse {
  /// Cree les regles.
  const ReglesClasse({
    required this.fuseauIana,
    this.dureeMinutes,
    this.capaciteEnfants,
    this.capaciteAdultes,
    this.seuilMinimal,
  });

  /// Le fuseau IANA de reference propose par defaut.
  final String fuseauIana;

  /// La duree d'une seance, en minutes.
  final int? dureeMinutes;

  /// La capacite d'une Classe d'enfants.
  final int? capaciteEnfants;

  /// La capacite d'une Classe d'adultes.
  final int? capaciteAdultes;

  /// Le seuil minimal d'ouverture.
  final int? seuilMinimal;

  /// La capacite par defaut pour un public donne.
  int? capacitePour(PublicClasse publicClasse) => switch (publicClasse) {
    PublicClasse.enfants => capaciteEnfants,
    PublicClasse.adultes => capaciteAdultes,
  };
}

/// Un niveau du programme, propose a la creation d'une Classe.
///
/// **Le nom humain seul se montre** : le code technique n'entre jamais ici.
@immutable
class ProgrammeChoix {
  /// Cree un choix de programme.
  const ProgrammeChoix({
    required this.niveauId,
    required this.nomHumain,
    required this.cycle,
  });

  /// L'identifiant du niveau. Jamais affiche.
  final String niveauId;

  /// Le nom humain du niveau.
  final String nomHumain;

  /// Le cycle auquel il appartient.
  final String cycle;
}

/// Un enseignant reellement eligible a une Classe en preparation.
///
/// La liste vient du serveur, filtree par lui : l'administration ne saisit
/// **jamais** un identifiant.
@immutable
class EnseignantEligible {
  /// Cree un enseignant eligible.
  const EnseignantEligible({
    required this.id,
    required this.nomAffichage,
    this.titre,
  });

  /// L'identifiant du profil. Jamais affiche.
  final String id;

  /// Le nom d'affichage.
  final String nomAffichage;

  /// Sayyid ou Sayyida, quand la base le porte.
  final TitreEnseignant? titre;
}

/// Une Classe en preparation, avant publication.
///
/// C'est ce que l'aperçu montre et ce que le port publie. **Aucun identifiant
/// n'y est saisi a la main** : [enseignantId] vient d'une liste filtree par le
/// serveur, [niveauId] d'un programme publie.
@immutable
class BrouillonClasse {
  /// Cree un brouillon.
  const BrouillonClasse({
    required this.libelle,
    required this.publicClasse,
    required this.creneau,
    this.dureeMinutes,
    this.capacite,
    this.seuilMinimal,
    this.enseignantId,
    this.enseignantNom,
    this.niveauId,
    this.programme,
    this.niveauHumain,
  });

  /// Le nom de la Classe.
  final String libelle;

  /// Le public.
  final PublicClasse publicClasse;

  /// Le creneau hebdomadaire.
  final CreneauClasse creneau;

  /// La duree, en minutes. `null` : defaut de l'academie.
  final int? dureeMinutes;

  /// La capacite. `null` : defaut de l'academie.
  final int? capacite;

  /// Le seuil minimal. `null` : defaut de l'academie.
  final int? seuilMinimal;

  /// L'enseignant retenu, ou `null` pour « a affecter plus tard ».
  final String? enseignantId;

  /// Le nom d'affichage de cet enseignant, pour l'aperçu.
  final String? enseignantNom;

  /// Le niveau du programme, ou `null` pour un nom libre.
  final String? niveauId;

  /// Le nom humain du programme.
  final String? programme;

  /// Le nom humain du niveau.
  final String? niveauHumain;

  /// La Classe telle que l'aperçu la montre, avant publication.
  ///
  /// La capacite affichee est celle du brouillon quand elle est connue, sinon
  /// celle des regles de l'academie ; quand aucune des deux n'est connue, la
  /// carte dit « Defaut de l'academie ». **Jamais un nombre ecrit ici.**
  ClasseVM apercu({int? capaciteAcademie}) {
    final int? connue = capacite ?? capaciteAcademie;
    return ClasseVM(
      id: creneau.cle,
      libelle: libelle,
      programme: programme,
      niveauHumain: niveauHumain,
      publicClasse: publicClasse,
      creneau: creneau,
      duree: dureeMinutes == null ? null : Duration(minutes: dureeMinutes!),
      capacite: connue ?? 1,
      capaciteConnue: connue != null,
      inscrits: 0,
      seuilMinimal: seuilMinimal,
      etat: EtatPublication.brouillon,
      enseignant: enseignantId == null
          ? null
          : EnseignantClasse(
              id: enseignantId!,
              nomAffichage: enseignantNom ?? '',
            ),
    );
  }

  /// Le meme brouillon, sur un autre creneau.
  BrouillonClasse surCreneau(CreneauClasse autre) => BrouillonClasse(
    libelle: libelle,
    publicClasse: publicClasse,
    creneau: autre,
    dureeMinutes: dureeMinutes,
    capacite: capacite,
    seuilMinimal: seuilMinimal,
    enseignantId: enseignantId,
    enseignantNom: enseignantNom,
    niveauId: niveauId,
    programme: programme,
    niveauHumain: niveauHumain,
  );
}

/// Un eleve inscrit a une Classe, vu par l'administration.
@immutable
class MembreClasse {
  /// Cree un membre.
  const MembreClasse({required this.id, required this.libelle});

  /// L'identifiant du profil. Jamais affiche.
  final String id;

  /// Ce qui s'affiche pour nommer l'eleve.
  final String libelle;
}
