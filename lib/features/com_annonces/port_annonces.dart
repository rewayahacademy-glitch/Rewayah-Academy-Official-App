// Les annonces de Classe (spec Communications V1, section 13.3 ; COM-BR-10).
//
// Une annonce est une communication d'UN sens, vers toute une Classe : elle
// ne devient jamais un fil (section 13.3), et sa lecture ne passe que par ce
// port. Le port de production est NEUTRE : aucune source d'annonces n'existe
// avant BR-1, il leve `CapaciteIndisponible('COM-BR-10')` et l'ecran ne
// promet rien (pas de faux vide). Les donnees de demonstration vivent dans
// `lib/features/demo/communications/com_annonces_demo.dart`, jamais ici.
//
// Aucun role n'est lu : ce que la personne peut faire (publier pour cette
// Classe) est porte par l'objet rendu ([AnnoncesDeLaClasse.peut]), sur le
// modele de `library_resource.dart` (`peut(capacite)`), et le serveur refuse
// quand meme (COM-BR-16).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';

/// Une annonce de Classe, deja autorisee et redigee par le serveur.
@immutable
class AnnonceClasse {
  /// Cree l'annonce. [classe] est l'objet lie de type Classe : son libelle
  /// est deja redige (« Classe An-Nour ») et sa destination, deja validee,
  /// ouvre la Classe dans l'espace de la personne qui lit (R-COM-12).
  AnnonceClasse({
    required this.id,
    required this.titre,
    required this.texte,
    required this.publieeLe,
    required this.classe,
    this.auteur,
    this.niveau = NiveauAttention.aLire,
    this.lue = false,
    this.generale = false,
  }) : assert(id.isNotEmpty, 'Une annonce porte son identifiant.'),
       assert(
         classe.type == TypeObjetLie.classe,
         'Une annonce de Classe est rattachee a une Classe.',
       );

  /// Identifiant de l'annonce.
  final String id;

  /// Le titre, deja redige.
  final String titre;

  /// Le texte complet, deja redige. La carte en montre le debut ; le detail
  /// le montre en entier.
  final String texte;

  /// L'instant de publication confirme par le serveur (UTC).
  final DateTime publieeLe;

  /// La Classe concernee.
  final ObjetLie classe;

  /// Qui l'a publiee, deja autorise (« Enseignante de la Classe ») ; `null`
  /// si le serveur ne le dit pas.
  final Participant? auteur;

  /// Le niveau d'attention : une annonce est au moins « A lire ».
  final NiveauAttention niveau;

  /// Vrai si la personne l'a deja lue (le port le dit).
  final bool lue;

  /// Vrai pour une annonce generale de l'academie (« Toute l'academie »)
  /// rendue dans le contexte d'une Classe : la carte affiche la portee, pas
  /// le nom de la Classe de contexte.
  final bool generale;
}

/// La nature d'une audience d'annonce (spec section 13.4).
enum NatureCible {
  /// Une Classe : la seule audience d'un enseignant, la sienne.
  classe,

  /// Un public (familles, enseignants...), pour l'Administration.
  public,

  /// Toute l'ecole : l'annonce globale, pour l'Administration seulement.
  toutes,
}

/// Une audience vers laquelle la personne PEUT publier : rendue par le
/// serveur ([PortAnnonces.ciblesPublication]), jamais composee par l'ecran.
/// Son [libelle] est deja redige (« Classe An-Nour », « Familles »).
///
/// L'identifiant de l'audience ([id]) n'est PAS celui de la Classe : une
/// audience de nature [NatureCible.classe] dit sa Classe par [classeId]
/// (contrat COM-BR-10), et c'est ce champ que l'ecran de l'enseignant compare
/// a la Classe de son adresse.
@immutable
class CibleAnnonce {
  /// Cree l'audience.
  const CibleAnnonce({
    required this.id,
    required this.libelle,
    required this.nature,
    this.classeId,
  });

  /// Identifiant de l'audience, porte par la publication.
  final String id;

  /// La Classe visee, pour une audience de nature [NatureCible.classe] ;
  /// `null` pour un public ou toute l'ecole.
  final String? classeId;

  /// Le libelle, deja redige.
  final String libelle;

  /// Sa nature.
  final NatureCible nature;

  @override
  bool operator ==(Object other) =>
      other is CibleAnnonce &&
      other.id == id &&
      other.libelle == libelle &&
      other.nature == nature &&
      other.classeId == classeId;

  @override
  int get hashCode => Object.hash(id, libelle, nature, classeId);
}

/// Une annonce prete a partir : contenu, audience et, si la personne peut
/// programmer, la date de diffusion (spec section 20, `AnnouncementPublisher`).
@immutable
class BrouillonAnnonce {
  /// Cree le brouillon.
  const BrouillonAnnonce({
    required this.titre,
    required this.texte,
    required this.cible,
    this.programmeeLe,
  });

  /// Le titre.
  final String titre;

  /// Le texte.
  final String texte;

  /// L'audience choisie parmi celles du serveur.
  final CibleAnnonce cible;

  /// L'instant de diffusion demande (UTC) ; `null` : des que possible.
  final DateTime? programmeeLe;
}

/// L'etat d'une annonce cote administration.
enum EtatAnnonce {
  /// Publiee : le serveur l'a confirme.
  publiee,

  /// Planifiee : le serveur l'a enregistree pour une date future.
  planifiee,
}

/// Une annonce confirmee par le serveur : la SEULE source d'un « Publiee »
/// ou d'un « Planifiee » a l'ecran (spec section 20 : aucune publication
/// affichee comme publiee sans confirmation du contrat reel).
@immutable
class AnnonceConfirmee {
  /// Cree la confirmation.
  const AnnonceConfirmee({
    required this.id,
    required this.etat,
    required this.le,
  });

  /// Identifiant de l'annonce creee.
  final String id;

  /// Publiee ou planifiee.
  final EtatAnnonce etat;

  /// L'instant de publication, ou de diffusion prevue (UTC).
  final DateTime le;
}

/// Une annonce vue par l'Administration (publiee ou planifiee).
@immutable
class AnnonceAdministration {
  /// Cree l'annonce.
  const AnnonceAdministration({
    required this.id,
    required this.titre,
    required this.texte,
    required this.cible,
    required this.etat,
    required this.le,
  });

  /// Identifiant.
  final String id;

  /// Le titre, deja redige.
  final String titre;

  /// Le texte, deja redige.
  final String texte;

  /// L'audience.
  final CibleAnnonce cible;

  /// Publiee ou planifiee.
  final EtatAnnonce etat;

  /// L'instant de publication, ou de diffusion prevue (UTC).
  final DateTime le;
}

/// Les annonces lues par l'Administration (COM-BR-10) : les publiees de la
/// periode du serveur, et les planifiees.
///
/// [demonstration] est vrai quand les donnees sont des fixtures : l'ecran
/// le dit en clair (« Démonstration ») a cote de chaque chiffre et de chaque
/// liste qui en vient (COM-BR-A08). Le port de production ne le pose jamais.
@immutable
class AnnoncesAdministration {
  /// Cree la vue.
  const AnnoncesAdministration({
    required this.publiees,
    required this.planifiees,
    this.demonstration = false,
  });

  /// Les annonces publiees, la plus recente d'abord.
  final List<AnnonceAdministration> publiees;

  /// Les annonces planifiees, la plus proche d'abord.
  final List<AnnonceAdministration> planifiees;

  /// Vrai pour des donnees de demonstration.
  final bool demonstration;
}

/// Ce que la personne peut faire dans l'espace d'annonces d'une Classe.
enum CapaciteAnnonces {
  /// Publier une annonce pour cette Classe (enseignant de la Classe,
  /// Administration). La publication passe par le publieur unique
  /// (`PublieurAnnonce`, COM-ANN-2).
  publier,
}

/// Les annonces d'une Classe, et ce que la personne peut y faire.
@immutable
class AnnoncesDeLaClasse {
  /// Cree la vue.
  const AnnoncesDeLaClasse({
    required this.annonces,
    this.capacites = const <CapaciteAnnonces>{},
  });

  /// Les annonces, la plus recente d'abord (tri du port).
  final List<AnnonceClasse> annonces;

  /// Les capacites projetees par le serveur ; vide par defaut, tout ferme.
  final Set<CapaciteAnnonces> capacites;

  /// Vrai si la personne a [capacite] pour cette Classe.
  bool peut(CapaciteAnnonces capacite) => capacites.contains(capacite);
}

/// Les annonces de Classe (COM-BR-10).
abstract interface class PortAnnonces {
  /// Les annonces de la Classe [classeId] visibles par la personne.
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId);

  /// Une annonce precise ; `null` si elle n'existe plus ou n'est plus
  /// autorisee (jamais un faux contenu).
  Future<AnnonceClasse?> annonce(String id);

  /// Enregistre que la personne a lu l'annonce [annonceId] (COM-BR-A03).
  /// Leve en cas d'echec : l'annonce reste alors non lue a l'ecran.
  Future<void> marquerLue(String annonceId);

  /// Les audiences vers lesquelles la personne peut publier (COM-BR-10).
  /// Avec [classeId], seulement cette Classe si la personne peut y publier
  /// (liste vide sinon) : l'enseignant ne vise jamais que sa Classe, et le
  /// serveur refuse quand meme toute autre audience.
  Future<List<CibleAnnonce>> ciblesPublication({String? classeId});

  /// Publie (ou programme) [brouillon]. Le futur ne se termine qu'a l'accuse
  /// du serveur ; [cleIdempotence] est tiree une fois par annonce et rejouee
  /// telle quelle a chaque nouvelle tentative (COM-BR-02).
  Future<AnnonceConfirmee> publier({
    required BrouillonAnnonce brouillon,
    required String cleIdempotence,
  });

  /// Les annonces publiees et planifiees, pour l'Administration.
  Future<AnnoncesAdministration> annoncesAdministration();
}

/// Les annonces tant qu'aucune source n'existe : chaque lecture et chaque
/// ecriture leve `CapaciteIndisponible('COM-BR-10')`.
class AnnoncesIndisponibles implements PortAnnonces {
  /// Cree l'implementation.
  const AnnoncesIndisponibles();

  /// Ce qui manque.
  static const CapaciteIndisponible manque = CapaciteIndisponible('COM-BR-10');

  @override
  Future<AnnoncesDeLaClasse> annoncesDeClasse(String classeId) =>
      Future<AnnoncesDeLaClasse>.error(manque);

  @override
  Future<AnnonceClasse?> annonce(String id) =>
      Future<AnnonceClasse?>.error(manque);

  @override
  Future<void> marquerLue(String annonceId) => Future<void>.error(manque);

  @override
  Future<List<CibleAnnonce>> ciblesPublication({String? classeId}) =>
      Future<List<CibleAnnonce>>.error(manque);

  @override
  Future<AnnonceConfirmee> publier({
    required BrouillonAnnonce brouillon,
    required String cleIdempotence,
  }) => Future<AnnonceConfirmee>.error(manque);

  @override
  Future<AnnoncesAdministration> annoncesAdministration() =>
      Future<AnnoncesAdministration>.error(manque);
}

/// Le port des annonces employe par l'application : neutre en production.
final Provider<PortAnnonces> portAnnoncesProvider = Provider<PortAnnonces>(
  (Ref ref) => const AnnoncesIndisponibles(),
);

/// Les annonces d'une Classe.
final FutureProviderFamily<AnnoncesDeLaClasse, String>
annoncesDeClasseProvider = FutureProvider.family<AnnoncesDeLaClasse, String>(
  (Ref ref, String classeId) =>
      ref.watch(portAnnoncesProvider).annoncesDeClasse(classeId),
);

/// Une annonce, par son identifiant.
final FutureProviderFamily<AnnonceClasse?, String> annonceProvider =
    FutureProvider.family<AnnonceClasse?, String>(
      (Ref ref, String id) => ref.watch(portAnnoncesProvider).annonce(id),
    );

/// Les audiences de publication : `null` pour l'Administration, l'identifiant
/// d'une Classe pour la publication depuis une Classe.
final FutureProviderFamily<List<CibleAnnonce>, String?>
ciblesPublicationProvider = FutureProvider.family<List<CibleAnnonce>, String?>(
  (Ref ref, String? classeId) =>
      ref.watch(portAnnoncesProvider).ciblesPublication(classeId: classeId),
);

/// Les annonces publiees et planifiees, pour l'Administration.
final FutureProvider<AnnoncesAdministration> annoncesAdministrationProvider =
    FutureProvider<AnnoncesAdministration>(
      (Ref ref) => ref.watch(portAnnoncesProvider).annoncesAdministration(),
    );
