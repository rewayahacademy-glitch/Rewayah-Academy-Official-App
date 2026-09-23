import 'package:flutter/foundation.dart';

import '../tc_horloge/session_clock_vm.dart';

/// Le titre d'un enseignant dans le contexte cours.
///
/// **Sayyid / Sayyida, jamais Ustaz** (decision `D-02`). Les deux formes arabes
/// vivent dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/i18n/tc_i18n_A.json` : c'est la seule
/// exception a la regle « aucun agent ne produit de traduction arabe ».
///
/// Aucune colonne de la base ne porte ce titre aujourd'hui : il est demande en
/// section 6 de `TC_CONTRACT_REQUEST_A.md`.
enum TitreEnseignant {
  /// Titre masculin.
  sayyid('sayyid'),

  /// Titre feminin.
  sayyida('sayyida');

  const TitreEnseignant(this.valeurSql);

  /// La valeur telle que la base l'attendra.
  final String valeurSql;

  /// Lit un titre depuis sa valeur SQL.
  ///
  /// Rend `null` sur valeur inconnue, comme tous les enums de
  /// `lib/core/domain/enums.dart` : **jamais de repli silencieux**. Un titre
  /// illisible se lit comme une absence de titre, pas comme « Sayyid ».
  static TitreEnseignant? depuisSql(String? valeur) {
    for (final TitreEnseignant titre in TitreEnseignant.values) {
      if (titre.valeurSql == valeur) {
        return titre;
      }
    }
    return null;
  }
}

/// Le public d'un groupe, tel que l'Espace Groupe le lit.
///
/// Miroir de `TypePublicGroupe` (`lib/core/admin/service_groupes.dart`), qui est
/// un chemin **administration**. Le seuil de membres ne s'en deduit jamais : il
/// vient de `groupes.seuil_max`, lu du serveur.
enum TypePublicGroupeVM {
  /// Groupe d'enfants.
  enfant('enfant'),

  /// Groupe d'adultes.
  adulte('adulte');

  const TypePublicGroupeVM(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL, `null` si inconnue.
  static TypePublicGroupeVM? depuisSql(String? valeur) {
    for (final TypePublicGroupeVM type in TypePublicGroupeVM.values) {
      if (type.valeurSql == valeur) {
        return type;
      }
    }
    return null;
  }
}

/// La couleur d'identification d'un groupe, par son index dans une palette
/// **administree**.
///
/// **Jamais un hexadecimal libre** (decision `D-18`). Le jeton ne porte pas de
/// couleur : il porte un index et un code stable, et c'est le theme qui decide
/// de la teinte. Un hexadecimal transporte serait une couleur qui echappe au
/// contraste, au mode sombre et a la palette.
///
/// **La couleur n'est jamais le seul identifiant du groupe.** Toute surface qui
/// affiche un jeton affiche aussi `GroupSummaryVM.libelle` : c'est l'invariant
/// `J7` du depot, deja tenu par `StatusPill`.
@immutable
class JetonCouleurGroupe {
  /// Cree un jeton de couleur.
  const JetonCouleurGroupe({required this.index, required this.codeStable})
    : assert(index >= 0, 'un index de palette est positif');

  /// Rang dans la palette administree, de 0 a `tailleDePalette - 1`.
  final int index;

  /// Code stable et administre, par exemple `g17`. Jamais un hexadecimal.
  final String codeStable;

  @override
  bool operator ==(Object other) =>
      other is JetonCouleurGroupe &&
      other.index == index &&
      other.codeStable == codeStable;

  @override
  int get hashCode => Object.hash(index, codeStable);
}

/// L'enseignant du groupe, tel que la carte et l'Espace Groupe le nomment.
///
/// **La photo est obligatoire** (decision `D-01`) : son absence declenche un
/// etat d'erreur ou de migration explicite, jamais un avatar generique
/// silencieux. `teacher_profiles` n'a aujourd'hui **aucune** colonne de photo,
/// c'est la section 5 de `TC_CONTRACT_REQUEST_A.md`.
///
/// `photoUrlOuCle` porte la **cle de stockage**, jamais une URL signee : une URL
/// signee expire, et la lecon est deja inscrite dans
/// `lib/core/appairage/service_avatar.dart`.
@immutable
class EnseignantVM {
  /// Cree l'identite d'un enseignant.
  const EnseignantVM({
    required this.enseignantId,
    required this.titre,
    required this.nomAffichage,
    this.photoUrlOuCle,
  });

  /// Identifiant du profil enseignant.
  final String enseignantId;

  /// Sayyid ou Sayyida.
  final TitreEnseignant titre;

  /// Prenom, ou prenom et nom d'affichage autorise.
  final String nomAffichage;

  /// Cle de stockage de la photo. `null` quand la photo manque.
  final String? photoUrlOuCle;

  /// Vrai quand la photo obligatoire n'est pas la.
  ///
  /// Cette propriete existe pour que l'UI n'ait pas a decider ce qu'est une
  /// absence : une chaine vide est une absence au meme titre qu'un `null`.
  bool get photoManquante =>
      photoUrlOuCle == null || photoUrlOuCle!.trim().isEmpty;
}

/// Une occurrence de seance du groupe.
///
/// [debutUtc] est en UTC, [fuseauReferenceGroupe] est un identifiant IANA :
/// **aucun offset numerique n'apparait jamais dans un contrat**.
///
/// [sessionId] est `null` tant que l'occurrence n'est pas materialisee. C'est
/// l'etat reel du depot aujourd'hui : `public.sessions` n'a pas de `groupe_id`
/// et `materialiser_seances()` raisonne par affectation 1-a-1, donc un groupe
/// cree ne produit aucune seance (section 1 de `TC_CONTRACT_REQUEST_A.md`).
@immutable
class OccurrenceSeance {
  /// Cree une occurrence.
  const OccurrenceSeance({
    required this.debutUtc,
    required this.duree,
    required this.fuseauReferenceGroupe,
    this.sessionId,
  }) : assert(duree > Duration.zero, 'une seance dure un temps positif');

  /// Identifiant de la seance. `null` si l'occurrence n'est pas materialisee.
  final String? sessionId;

  /// Debut, en UTC.
  final DateTime debutUtc;

  /// Duree prevue.
  final Duration duree;

  /// Fuseau IANA de reference du groupe.
  final String fuseauReferenceGroupe;

  /// Fin prevue, en UTC.
  ///
  /// Une addition sur un instant **UTC** ne traverse aucune regle de fuseau :
  /// c'est de l'arithmetique, pas une conversion. Un meme calcul sur une heure
  /// locale rejouerait le bug corrige par la migration `0006`.
  DateTime get finPrevueUtc => debutUtc.add(duree);
}

/// La carte du Groupe : ce qui se lit d'un coup d'oeil.
///
/// **Le Groupe est l'espace pedagogique permanent** ; la Classe Live n'est
/// qu'un etat temporaire du Groupe (decision `D-19`). Cette vue existe donc
/// avant, pendant et apres le cours.
///
/// Trois invariants portes par ce type :
///
/// 1. [seuilMax] vient **toujours** du serveur. La capacite s'affiche par
///    `'$nombreMembres / $seuilMax'`, jamais par une constante : ni `5`, ni `6`.
/// 2. [couleurJeton] n'est jamais le seul identifiant du groupe : toute surface
///    qui l'affiche affiche aussi [libelle].
/// 3. [niveauHumain] n'est jamais un code technique. C'est une regle UX
///    inscrite en commentaire SQL dans `0020_programme_pedagogique.sql`.
@immutable
class GroupSummaryVM {
  /// Cree la carte d'un groupe.
  const GroupSummaryVM({
    required this.groupeId,
    required this.libelle,
    required this.couleurJeton,
    required this.enseignant,
    required this.nombreMembres,
    required this.seuilMax,
    required this.typePublic,
    required this.actif,
    this.nomCours,
    this.niveauHumain,
    this.prochaineSeance,
    this.horloge,
  }) : assert(nombreMembres >= 0, 'un effectif ne peut pas etre negatif'),
       assert(seuilMax > 0, 'un seuil vient du serveur et vaut au moins 1'),
       assert(
         prochaineSeance != null || horloge == null,
         'une horloge sans occurrence ne decrit rien',
       );

  /// Identifiant de `public.groupes.id`.
  final String groupeId;

  /// Nom familier du groupe. **Jamais un code backend.**
  final String libelle;

  /// Repere de couleur, issu d'une palette administree.
  final JetonCouleurGroupe couleurJeton;

  /// L'enseignant assigne.
  final EnseignantVM enseignant;

  /// Nom humain du cours. `null` si aucun cours n'est assigne.
  final String? nomCours;

  /// Nom humain du niveau. **Jamais `code_technique`.**
  final String? niveauHumain;

  /// Effectif actuel, lu du serveur.
  final int nombreMembres;

  /// Plafond du groupe, lu du serveur. **Jamais la valeur 5 en dur.**
  final int seuilMax;

  /// Enfants ou adultes.
  final TypePublicGroupeVM typePublic;

  /// La prochaine occurrence connue, ou `null`.
  final OccurrenceSeance? prochaineSeance;

  /// L'horloge de cette occurrence, ou `null` s'il n'y en a pas.
  final SessionClockVM? horloge;

  /// Faux quand `groupes.ended_at` est renseigne.
  final bool actif;

  /// Vrai quand le groupe est au plafond.
  ///
  /// Derive de la donnee serveur, jamais d'un nombre ecrit ici.
  bool get complet => nombreMembres >= seuilMax;

  /// Le nombre de places encore libres.
  int get placesLibres {
    final int reste = seuilMax - nombreMembres;
    return reste < 0 ? 0 : reste;
  }

  /// La meme carte, avec une horloge rafraichie.
  ///
  /// **Le seul point ou l'horloge d'une carte change.** Le flux du port emet
  /// une nouvelle `SessionClockVM` a sa cadence ; l'identite du groupe, elle,
  /// ne bouge pas. Recomposer la carte entiere a chaque tic ferait croire que
  /// le serveur a ete relu.
  GroupSummaryVM avecHorloge(SessionClockVM? nouvelle) => GroupSummaryVM(
    groupeId: groupeId,
    libelle: libelle,
    couleurJeton: couleurJeton,
    enseignant: enseignant,
    nomCours: nomCours,
    niveauHumain: niveauHumain,
    nombreMembres: nombreMembres,
    seuilMax: seuilMax,
    typePublic: typePublic,
    actif: actif,
    prochaineSeance:
        prochaineSeance ??
        (nouvelle == null
            ? null
            : OccurrenceSeance(
                sessionId: nouvelle.sessionId,
                debutUtc: nouvelle.debutUtc,
                duree: nouvelle.duree,
                fuseauReferenceGroupe:
                    nouvelle.horlogeContrepartie?.fuseauIana ??
                    nouvelle.horlogeUtilisateur.fuseauIana,
              )),
    horloge: nouvelle,
  );

  /// Vrai quand le CTA « Rejoindre » doit etre offert.
  ///
  /// **Une seule source**, celle de l'horloge : un ecran qui deciderait
  /// lui-meme proposerait une porte que `autoriser_jeton_video()` refuserait.
  bool get rejoindreOuvert => horloge?.rejoindreOuvert ?? false;
}

/// L'etat de la photo d'un enseignant.
///
/// **Ce n'est PAS un type de contrat.** C'est la forme executable de la
/// decision D-01 : l'absence de photo declenche un etat d'erreur ou de
/// migration EXPLICITE. L'enumeration ne compte volontairement que deux
/// valeurs : il n'existe aucun `avatarGenerique`, et c'est tout le sujet.
///
/// Promu par Agent Q depuis son double de contrat (TC_CONTRACT_REQUEST_Q.md) :
/// aucun type canonique ne couvrait ce besoin avant l'integration.
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
