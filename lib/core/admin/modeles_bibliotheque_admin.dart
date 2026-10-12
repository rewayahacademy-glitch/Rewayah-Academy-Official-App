/// CAP29-0 : les modeles de la bibliotheque, vue de l'administration.
///
/// Spec `REWAYAH_CAP29_BIBLIOTHEQUE_HANDOFF_CANONIQUE_V1.md`, §3 a §5 : le
/// catalogue, la fiche d'un support, ses versions, ses droits, le controle
/// de publication, l'attribution aux classes. Aucun appel serveur ici : ces
/// classes sont rendues par [PortBibliothequeAdmin] (`port_bibliotheque_admin.dart`).
///
/// Trois vocabulaires distincts, **jamais melanges** (spec §3.3) :
/// - la version d'un support : [StatutVersionRessource] (brouillon, publiee,
///   archivee), le triplet SQL existant ;
/// - la revue juridique des droits : [RevueDroits] (a verifier, approuve,
///   refuse, expire) ;
/// - le retrait du catalogue : [SupportAdmin.retire], un fait distinct.
///
/// Les dates sont en UTC cote port ; l'affichage local revient aux ecrans.
/// Aucune URL signee, aucune cle R2, aucun nom de fichier interne n'existe
/// dans ces modeles : le client ne les voit jamais (spec §4.2).
library;

import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/library_resource.dart';
import '../tc_bibliotheque/resource_version.dart';

export '../tc_bibliotheque/library_resource.dart'
    show PolitiqueAcces, PolitiqueOffline, TypeRessource;
export '../tc_bibliotheque/resource_version.dart' show StatutVersionRessource;

/// La revue juridique des droits d'une version (spec §4.3).
enum RevueDroits {
  /// Source ou preuve a controler : bloque la publication.
  aVerifier,

  /// Droits controles et valides.
  approuve,

  /// Droits refuses.
  refuse,

  /// La licence est arrivee a echeance.
  expire,
}

/// Les usages que les droits autorisent, **independants** les uns des autres
/// et des permissions de consultation de l'application (spec §4.3).
enum UsageDroit {
  /// Lecture dans l'application.
  application,

  /// Presentation en classe.
  classe,

  /// Telechargement.
  telechargement,

  /// Lecture hors ligne.
  horsLigne,
}

/// Le segment du catalogue (spec §3.2).
enum EtatCatalogue {
  /// Tous les supports que l'administration peut voir.
  tous,

  /// Sans version publiee.
  brouillons,

  /// Droits a verifier.
  aVerifier,

  /// Version publiee, non retiree.
  publies,

  /// Retires du catalogue.
  retires,

  /// Droits expires.
  droitsExpires,
}

/// Un support dans la liste du catalogue : le strict necessaire a une ligne.
@immutable
class SupportAdmin {
  /// Cree la ligne. [modifieLeUtc] est en UTC.
  SupportAdmin({
    required this.id,
    required this.titre,
    required this.type,
    required this.langue,
    required this.categorie,
    required this.statutVersion,
    required this.revueDroits,
    required this.visibilite,
    required this.modifieLeUtc,
    this.niveau,
    this.numeroVersion,
    this.retire = false,
  }) : assert(modifieLeUtc.isUtc, 'tout DateTime d un contrat est en UTC');

  /// L'identifiant (jamais affiche : le nom humain seul est un titre).
  final String id;

  /// Le titre.
  final String titre;

  /// Le type du support.
  final TypeRessource type;

  /// La langue (code court, `fr`).
  final String langue;

  /// La categorie.
  final String categorie;

  /// Le niveau, s'il y en a un.
  final String? niveau;

  /// Le numero de la derniere version, s'il y en a une.
  final int? numeroVersion;

  /// L'etat de la derniere version.
  final StatutVersionRessource statutVersion;

  /// La revue des droits de la derniere version.
  final RevueDroits revueDroits;

  /// La politique d'acces affichee.
  final PolitiqueAcces visibilite;

  /// La derniere modification.
  final DateTime modifieLeUtc;

  /// Retire du catalogue : plus de nouvelle signature, historique conserve.
  final bool retire;

  /// Vrai quand une version est publiee (et le support non retire).
  bool get publie => !retire && statutVersion == StatutVersionRessource.publiee;
}

/// Les filtres du catalogue, **bornes** : le serveur filtre et pagine, jamais
/// le client (spec §6.1).
@immutable
class FiltreCatalogue {
  /// Cree le filtre.
  const FiltreCatalogue({
    this.etat = EtatCatalogue.tous,
    this.type,
    this.niveau,
    this.langue,
    this.recherche = '',
  });

  /// Le segment.
  final EtatCatalogue etat;

  /// Un type.
  final TypeRessource? type;

  /// Un niveau.
  final String? niveau;

  /// Une langue.
  final String? langue;

  /// La recherche, locale au catalogue (nom, edition, categorie).
  final String recherche;

  /// Vrai quand rien ne filtre.
  bool get vide =>
      etat == EtatCatalogue.tous &&
      type == null &&
      niveau == null &&
      langue == null &&
      recherche.trim().isEmpty;

  /// Le meme filtre, avec les champs donnes remplaces. `type`, `niveau` et
  /// `langue` se retirent par `retirer*`.
  FiltreCatalogue avec({
    EtatCatalogue? etat,
    TypeRessource? type,
    String? niveau,
    String? langue,
    String? recherche,
    bool retirerType = false,
    bool retirerNiveau = false,
    bool retirerLangue = false,
  }) => FiltreCatalogue(
    etat: etat ?? this.etat,
    type: retirerType ? null : (type ?? this.type),
    niveau: retirerNiveau ? null : (niveau ?? this.niveau),
    langue: retirerLangue ? null : (langue ?? this.langue),
    recherche: recherche ?? this.recherche,
  );

  @override
  bool operator ==(Object other) =>
      other is FiltreCatalogue &&
      other.etat == etat &&
      other.type == type &&
      other.niveau == niveau &&
      other.langue == langue &&
      other.recherche == recherche;

  @override
  int get hashCode => Object.hash(etat, type, niveau, langue, recherche);
}

/// Les valeurs que le catalogue propose en filtre : rendues par le serveur,
/// jamais une liste ecrite dans l'ecran.
@immutable
class FacettesCatalogue {
  /// Cree les facettes.
  const FacettesCatalogue({
    this.niveaux = const <String>[],
    this.langues = const <String>[],
  });

  /// Les niveaux presents dans le catalogue.
  final List<String> niveaux;

  /// Les codes de langue presents dans le catalogue.
  final List<String> langues;
}

/// Une page du catalogue, a curseur. **Aucun total** : un compteur global
/// pourrait reveler un support non autorise (spec §3.2).
@immutable
class PageSupports {
  /// Cree la page.
  const PageSupports({required this.elements, this.curseur});

  /// Les lignes.
  final List<SupportAdmin> elements;

  /// Le curseur de la page suivante, ou `null` a la derniere.
  final String? curseur;
}

/// Une version d'un support (spec §3.3).
@immutable
class VersionSupport {
  /// Cree la version.
  VersionSupport({
    required this.id,
    required this.numero,
    required this.statut,
    required this.revueDroits,
    this.publieeLeUtc,
    this.empreinte,
  }) : assert(
         publieeLeUtc == null || publieeLeUtc.isUtc,
         'tout DateTime d un contrat est en UTC',
       );

  /// L'identifiant.
  final String id;

  /// Le numero.
  final int numero;

  /// L'etat de la version.
  final StatutVersionRessource statut;

  /// La revue des droits de cette version.
  final RevueDroits revueDroits;

  /// La publication, si elle a eu lieu.
  final DateTime? publieeLeUtc;

  /// L'empreinte (SHA-256) du fichier, si un fichier est depose.
  final String? empreinte;

  /// Une version publiee est immuable : seul un brouillon se modifie.
  bool get modifiable => statut == StatutVersionRessource.brouillon;
}

/// Les droits d'une version (spec §4.3), non publics : admin seulement.
@immutable
class DroitsSupport {
  /// Cree les droits.
  DroitsSupport({
    required this.revue,
    this.sourceTitre,
    this.titulaire,
    this.preuveFournie = false,
    this.usages = const <UsageDroit>{},
    this.attribution,
    this.expireLeUtc,
  }) : assert(
         expireLeUtc == null || expireLeUtc.isUtc,
         'tout DateTime d un contrat est en UTC',
       );

  /// Le statut de la revue.
  final RevueDroits revue;

  /// Le titre de la source d'origine.
  final String? sourceTitre;

  /// Le titulaire du droit, ou l'origine institutionnelle.
  final String? titulaire;

  /// Une preuve d'autorisation est deposee (son contenu n'est jamais lu ici).
  final bool preuveFournie;

  /// Les usages autorises.
  final Set<UsageDroit> usages;

  /// L'attribution exigee, telle quelle.
  final String? attribution;

  /// L'echeance de la licence.
  final DateTime? expireLeUtc;
}

/// Ce que l'audit d'un support a enregistre (spec §4.2, point 9).
enum ActionAudit {
  /// Brouillon cree.
  creation,

  /// Fichier depose.
  depot,

  /// Droits revus.
  revueDroits,

  /// Version publiee.
  publication,

  /// Attribue a des classes.
  attribution,

  /// Retire du catalogue.
  retrait,

  /// Restaure apres nouvelle verification.
  restauration,
}

/// Une ligne d'audit : qui, quoi, quand, pourquoi. Aucune URL signee, aucune
/// adresse IP.
@immutable
class EvenementAudit {
  /// Cree la ligne.
  EvenementAudit({
    required this.action,
    required this.acteur,
    required this.quandUtc,
    this.motif,
    this.numeroVersion,
  }) : assert(quandUtc.isUtc, 'tout DateTime d un contrat est en UTC');

  /// L'action.
  final ActionAudit action;

  /// Le nom affichable de l'acteur.
  final String acteur;

  /// Le moment.
  final DateTime quandUtc;

  /// Le motif, s'il y en a un (retrait).
  final String? motif;

  /// La version concernee.
  final int? numeroVersion;
}

/// Ce que la personne connectee peut faire d'un support : des capacites
/// rendues par le serveur, lues par l'ecran, jamais deduites d'un role
/// (spec §4.1). Distinctes : voir, modifier, publier, attribuer, retirer.
@immutable
class CapacitesSupport {
  /// Cree les capacites.
  const CapacitesSupport({
    this.peutModifier = false,
    this.peutPublier = false,
    this.peutAttribuer = false,
    this.peutRetirer = false,
  });

  /// Aucune capacite.
  static const CapacitesSupport aucune = CapacitesSupport();

  /// Modifier un brouillon, deposer un fichier, revoir les droits.
  final bool peutModifier;

  /// Publier une version.
  final bool peutPublier;

  /// Associer a des classes.
  final bool peutAttribuer;

  /// Retirer du catalogue.
  final bool peutRetirer;
}

/// La fiche complete d'un support (spec §3.3).
@immutable
class FicheSupport {
  /// Cree la fiche.
  const FicheSupport({
    required this.support,
    required this.revision,
    required this.versions,
    required this.droits,
    required this.historique,
    required this.capacites,
    this.titreCourt = '',
    this.edition,
    this.organisme,
    this.annee,
    this.description,
    this.conditionsAttribution,
    this.politiqueHorsLigne = PolitiqueOffline.jamais,
    this.classesServies = 0,
    this.motifRetrait,
  });

  /// La ligne de catalogue (titre, type, etats).
  final SupportAdmin support;

  /// La revision, pour le controle optimiste : une ecriture la renvoie, le
  /// serveur refuse une revision perimee (conflit d'edition).
  final int revision;

  /// Le titre court.
  final String titreCourt;

  /// L'edition.
  final String? edition;

  /// L'organisme, l'auteur ou l'editeur.
  final String? organisme;

  /// L'annee, si elle est connue.
  final int? annee;

  /// La description pedagogique.
  final String? description;

  /// Les conditions d'attribution.
  final String? conditionsAttribution;

  /// Les contraintes de telechargement et de hors ligne.
  final PolitiqueOffline politiqueHorsLigne;

  /// Les versions, la plus recente d'abord.
  final List<VersionSupport> versions;

  /// Les droits de la derniere version.
  final DroitsSupport droits;

  /// L'historique, le plus recent d'abord.
  final List<EvenementAudit> historique;

  /// Ce que la personne connectee peut faire.
  final CapacitesSupport capacites;

  /// Le nombre de classes servies (sans identite de classe).
  final int classesServies;

  /// Le motif d'un retrait.
  final String? motifRetrait;

  /// La derniere version, ou `null` si aucune.
  VersionSupport? get derniereVersion =>
      versions.isEmpty ? null : versions.first;
}

/// Ce que l'on saisit pour creer un brouillon (spec §3.4, section 1).
@immutable
class NouveauSupport {
  /// Cree la saisie.
  const NouveauSupport({
    required this.titre,
    required this.type,
    required this.langue,
    required this.categorie,
    this.niveau,
  });

  /// Le titre.
  final String titre;

  /// Le type.
  final TypeRessource type;

  /// La langue.
  final String langue;

  /// La categorie.
  final String categorie;

  /// Le niveau.
  final String? niveau;
}

/// Les champs modifiables d'un brouillon : `null` = inchange.
@immutable
class ModificationSupport {
  /// Cree la modification.
  const ModificationSupport({
    this.titre,
    this.titreCourt,
    this.edition,
    this.organisme,
    this.description,
    this.conditionsAttribution,
    this.visibilite,
    this.politiqueHorsLigne,
  });

  /// Le titre.
  final String? titre;

  /// Le titre court.
  final String? titreCourt;

  /// L'edition.
  final String? edition;

  /// L'organisme.
  final String? organisme;

  /// La description.
  final String? description;

  /// Les conditions d'attribution.
  final String? conditionsAttribution;

  /// La politique d'acces.
  final PolitiqueAcces? visibilite;

  /// La politique de hors ligne.
  final PolitiqueOffline? politiqueHorsLigne;
}

/// Ce que l'administrateur saisit en revoyant les droits d'une version
/// (spec §4.3, `admin_library_review_rights`). [approuver] demande
/// l'approbation de la revue ; le serveur decide, il peut la refuser.
@immutable
class SaisieDroits {
  /// Cree la saisie.
  SaisieDroits({
    required this.usages,
    required this.approuver,
    this.sourceTitre,
    this.titulaire,
    this.preuveFournie = false,
    this.attribution,
    this.expireLeUtc,
  }) : assert(
         expireLeUtc == null || expireLeUtc.isUtc,
         'tout DateTime d un contrat est en UTC',
       );

  /// Le titre de la source.
  final String? sourceTitre;

  /// Le titulaire du droit.
  final String? titulaire;

  /// Une preuve est deposee.
  final bool preuveFournie;

  /// Les usages autorises.
  final Set<UsageDroit> usages;

  /// L'attribution exigee.
  final String? attribution;

  /// L'echeance.
  final DateTime? expireLeUtc;

  /// Demande d'approuver la revue.
  final bool approuver;
}

/// L'etat d'un critere de controle, **rendu par le serveur** (spec §3.5).
enum EtatCritere {
  /// Valide.
  valide,

  /// Bloque : la raison est donnee.
  bloque,

  /// Pas encore evalue (aucun test reel : jamais presume valide).
  inconnu,
}

/// Les criteres de controle d'une version avant publication (spec §3.5).
enum CleCritere {
  /// Source confirmee.
  source,

  /// Titulaire du droit connu ou justification.
  titulaire,

  /// Preuve verifiee.
  preuve,

  /// Usage dans l'application permis.
  usageApplication,

  /// Affichage en classe permis.
  usageClasse,

  /// Telechargement et hors ligne : permis, ou explicitement non.
  usageTelechargement,

  /// Date d'expiration et attribution.
  expirationAttribution,

  /// Fichier sain (analyse reelle, jamais fictive).
  fichierSain,

  /// Rendu teste dans le renderer cible.
  renduTeste,

  /// Langue et niveau renseignes.
  langueNiveau,

  /// Version et empreinte figees.
  versionEmpreinte,
}

/// Un critere et son verdict serveur.
@immutable
class CritereControle {
  /// Cree le critere.
  const CritereControle({required this.cle, required this.etat});

  /// Le critere.
  final CleCritere cle;

  /// Le verdict.
  final EtatCritere etat;
}

/// Le controle d'une version : la liste des criteres et la publiabilite,
/// toutes deux rendues par le serveur. Aucun compteur code en dur.
@immutable
class ControleVersion {
  /// Cree le controle.
  const ControleVersion({required this.criteres, required this.publiable});

  /// Les criteres.
  final List<CritereControle> criteres;

  /// Le serveur autorise la publication.
  final bool publiable;

  /// Les criteres qui bloquent (bloque ou pas encore evalue).
  List<CritereControle> get bloquants => <CritereControle>[
    for (final CritereControle c in criteres)
      if (c.etat != EtatCritere.valide) c,
  ];
}

/// L'intention d'un depot de fichier (spec §5.2) : le client ne choisit
/// jamais la cle, le serveur la genere.
@immutable
class IntentionUpload {
  /// Cree l'intention.
  IntentionUpload({required this.id, required this.expireLeUtc})
    : assert(expireLeUtc.isUtc, 'tout DateTime d un contrat est en UTC');

  /// L'identifiant de l'intention.
  final String id;

  /// L'expiration du droit de deposer.
  final DateTime expireLeUtc;
}

/// Ce que le fichier depose est : le support lui-meme, ou la preuve
/// d'autorisation de ses droits (famille de stockage distincte, accessible a
/// des personnes distinctes).
enum FinaliteUpload {
  /// Le fichier du support.
  support,

  /// La preuve d'autorisation (spec §4.3).
  preuve,
}

/// Les phases d'un depot (spec §3.4, §7).
enum PhaseUpload {
  /// Intention creee, rien envoye.
  attente,

  /// Envoi en cours : [ProgressionUpload.partie] mesuree.
  envoi,

  /// Envoi fini, le serveur n'a pas encore confirme.
  enAttenteConfirmation,

  /// Le serveur controle le fichier (format, hash, contenu).
  verification,

  /// Fichier valide : on peut passer aux droits. Jamais « publie ».
  pret,

  /// Annule par l'utilisateur.
  annule,

  /// Echec : [ProgressionUpload.erreur] dit pourquoi.
  echec,
}

/// Pourquoi un depot echoue.
enum ErreurUpload {
  /// Fichier trop gros.
  taille,

  /// Type ou contenu non pris en charge, ou mensonger.
  type,

  /// Connexion perdue.
  reseau,

  /// Le serveur refuse (droit, intention expiree).
  refuse,

  /// Hash different de celui annonce.
  empreinte,
}

/// La progression d'un depot, diffusee par le port.
@immutable
class ProgressionUpload {
  /// Cree la progression. [partie] est entre 0 et 1.
  const ProgressionUpload({required this.phase, this.partie = 0, this.erreur});

  /// La phase.
  final PhaseUpload phase;

  /// La part envoyee, mesuree.
  final double partie;

  /// La cause d'un echec.
  final ErreurUpload? erreur;

  /// Vrai quand le depot est termine, bien ou mal.
  bool get termine =>
      phase == PhaseUpload.pret ||
      phase == PhaseUpload.annule ||
      phase == PhaseUpload.echec;
}

/// Le fichier que l'on depose, tel que l'application le connait : nom,
/// taille et type annonces. Le contenu part par le canal du port.
@immutable
class FichierADeposer {
  /// Cree le descriptif.
  const FichierADeposer({
    required this.nom,
    required this.octets,
    required this.mime,
    required this.sha256,
  });

  /// Le nom, pour l'affichage seulement.
  final String nom;

  /// La taille en octets.
  final int octets;

  /// Le type MIME annonce.
  final String mime;

  /// Empreinte calculee sur le contenu avant la demande de signature.
  final String sha256;
}

/// Une classe a laquelle on peut attribuer un support (spec §3.6).
@immutable
class ClasseAttribuable {
  /// Cree la ligne.
  const ClasseAttribuable({
    required this.id,
    required this.nom,
    this.dejaServie = false,
    this.epinglee = false,
  });

  /// L'identifiant.
  final String id;

  /// Le nom de la classe.
  final String nom;

  /// Le support est deja attribue a cette classe.
  final bool dejaServie;

  /// Il y est epingle.
  final bool epinglee;
}

/// Une page de classes attribuables, a curseur (30 classes paralleles et plus).
@immutable
class PageClasses {
  /// Cree la page.
  const PageClasses({required this.elements, this.curseur});

  /// Les classes.
  final List<ClasseAttribuable> elements;

  /// La page suivante.
  final String? curseur;
}

/// Ce que le serveur repond a une publication.
sealed class ResultatPublication {
  const ResultatPublication();
}

/// La version est publiee : atomique, jamais a moitie.
final class VersionPubliee extends ResultatPublication {
  /// Cree la reponse.
  const VersionPubliee({required this.revision});

  /// La nouvelle revision.
  final int revision;
}

/// Le serveur refuse : les criteres bloquants sont rendus.
final class PublicationBloquee extends ResultatPublication {
  /// Cree la reponse.
  const PublicationBloquee(this.controle);

  /// Le controle a jour.
  final ControleVersion controle;
}

/// Un autre administrateur a modifie le support entre-temps.
final class PublicationEnConflit extends ResultatPublication {
  /// Cree la reponse.
  const PublicationEnConflit();
}

/// Ce que le serveur repond a une ecriture de la fiche (mise a jour,
/// attribution, retrait).
sealed class ResultatEcriture {
  const ResultatEcriture();
}

/// Enregistre, avec la nouvelle revision.
final class EcritureFaite extends ResultatEcriture {
  /// Cree la reponse.
  const EcritureFaite({required this.revision});

  /// La nouvelle revision.
  final int revision;
}

/// Revision perimee : un autre administrateur a ecrit avant.
final class EcritureEnConflit extends ResultatEcriture {
  /// Cree la reponse.
  const EcritureEnConflit();
}
