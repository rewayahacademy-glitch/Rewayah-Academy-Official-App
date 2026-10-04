// Le port de la Communaute enseignants (COM-COMU-1, spec section 4, section
// 16 COM-M02, section 17 COM-W02 ; contrat serveur COM-BR-05).
//
// Le frontend ne connait que des modeles DEJA NETTOYES par le port : un
// auteur reduit a son nom affiche et a sa fonction autorisee (« Enseignante,
// Classe An-Nour »), jamais un profil, une coordonnee ou un role brut
// (spec section 4.2 : aucun message prive ; COM-BR-05 : aucun profil expose
// au-dela du nom et de la Classe autorises). Aucun compteur de popularite,
// d'abonnes ni de classement (spec section 32) : une publication porte son
// nombre de reponses, rien d'autre.
//
// Production : `CommunauteIndisponible`, chaque appel echoue avec
// `CapaciteIndisponible('COM-BR-05')`, et l'ecran dit « Pas encore
// disponible » sans « Reessayer ». La memoire `CommunauteMemoire` est un
// double de demonstration et de test, pose par `overrideWithValue` sous
// `environnementAutoriseDemo`, jamais en production (K-28).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_pieces_jointes.dart';
import '../../core/router/routes.dart';

/// Une categorie de la Communaute, telle que le port la donne : la spec ne
/// les fixe pas (UX_REVIEW L0, point 17), elles viennent du serveur.
@immutable
class CategorieCommunaute {
  /// Cree la categorie.
  const CategorieCommunaute({required this.id, required this.libelle});

  /// Identifiant stable.
  final String id;

  /// Le nom, deja redige (« Pedagogie »).
  final String libelle;

  @override
  bool operator ==(Object other) =>
      other is CategorieCommunaute && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategorieCommunaute($id)';
}

/// Ce que la personne connectee peut faire dans la Communaute, donne par le
/// serveur (COM-BR-05, COM-BR-16). Une action absente n'est pas rendue,
/// jamais grisee ; elle n'est jamais deduite d'un role.
@immutable
class CapacitesCommunaute {
  /// Cree les capacites ; tout est ferme par defaut.
  const CapacitesCommunaute({
    this.peutPublier = false,
    this.peutRepondre = false,
  });

  /// Aucune capacite.
  static const CapacitesCommunaute aucune = CapacitesCommunaute();

  /// Vrai si la personne peut ecrire une nouvelle publication.
  final bool peutPublier;

  /// Vrai si la personne peut repondre a une publication.
  final bool peutRepondre;
}

/// Une publication de la Communaute.
@immutable
class PublicationCommunaute {
  /// Cree la publication.
  const PublicationCommunaute({
    required this.id,
    required this.auteur,
    required this.titre,
    required this.texte,
    required this.categorie,
    required this.publieeLe,
    this.nombreReponses = 0,
    this.piecesJointes = const <PieceJointe>[],
  }) : assert(nombreReponses >= 0, 'Un nombre de reponses est positif.');

  /// Identifiant stable.
  final String id;

  /// L'auteur, deja autorise (nom affiche et fonction, rien d'autre).
  final Participant auteur;

  /// Le titre.
  final String titre;

  /// Le texte.
  final String texte;

  /// La categorie.
  final CategorieCommunaute categorie;

  /// L'instant de publication (UTC).
  final DateTime publieeLe;

  /// Le nombre de reponses : la seule mesure portee (aucun score, spec
  /// section 32).
  final int nombreReponses;

  /// Les pieces jointes, references opaques seulement (spec section 12).
  final List<PieceJointe> piecesJointes;

  /// L'objet canonique de la publication : ce que portent « Enregistrer » et
  /// « Signaler » (jamais « la publication courante », lecons des roles, 15).
  ObjetLie get objet => ObjetLie(
    type: TypeObjetLie.publication,
    id: id,
    libelle: titre,
    destination: Routes.enseignantPublicationPour(id),
  );

  /// Une copie avec un autre nombre de reponses.
  PublicationCommunaute avecReponses(int nombre) => PublicationCommunaute(
    id: id,
    auteur: auteur,
    titre: titre,
    texte: texte,
    categorie: categorie,
    publieeLe: publieeLe,
    nombreReponses: nombre,
    piecesJointes: piecesJointes,
  );
}

/// Une reponse a une publication (`ReplyThread`).
@immutable
class ReponseCommunaute {
  /// Cree la reponse.
  const ReponseCommunaute({
    required this.id,
    required this.publicationId,
    required this.auteur,
    required this.texte,
    required this.publieeLe,
  });

  /// Identifiant stable.
  final String id;

  /// La publication a laquelle elle repond.
  final String publicationId;

  /// L'auteur, deja autorise.
  final Participant auteur;

  /// Le texte.
  final String texte;

  /// L'instant de publication (UTC).
  final DateTime publieeLe;

  /// L'objet canonique de la reponse, pour « Signaler ».
  ObjetLie get objet => ObjetLie(
    type: TypeObjetLie.message,
    id: id,
    libelle: texte,
    destination: Routes.enseignantPublicationPour(publicationId),
  );
}

/// Ce que le composer envoie (spec section 5.3 : texte, categorie, piece
/// jointe autorisee ; jamais de prix, de produit, de boutique ni de lien de
/// promotion).
@immutable
class BrouillonPublication {
  /// Cree le brouillon.
  const BrouillonPublication({
    required this.categorieId,
    required this.titre,
    required this.texte,
    this.piecesJointes = const <PieceJointe>[],
  });

  /// La categorie choisie.
  final String categorieId;

  /// Le titre.
  final String titre;

  /// Le texte.
  final String texte;

  /// Les pieces jointes retenues, toutes autorisees par la politique.
  final List<PieceJointe> piecesJointes;
}

/// Le serveur ne rend pas cette publication a la personne qui lit : retiree,
/// masquee par la moderation, ou jamais autorisee. Un refus est une
/// publication absente, jamais une publication vide (COM-BR-05).
class PublicationIntrouvable implements Exception {
  /// Cree l'erreur.
  const PublicationIntrouvable(this.publicationId);

  /// La publication demandee.
  final String publicationId;

  @override
  String toString() => 'PublicationIntrouvable($publicationId)';
}

/// La Communaute enseignants (COM-BR-05).
///
/// Chaque action porte l'identifiant de son objet. Un envoi porte une cle
/// d'idempotence generee par l'app et rejouee telle quelle ; son futur ne se
/// termine qu'a l'accuse du serveur, jamais un faux succes (COM-BR-02).
abstract interface class PortCommunaute {
  /// Les capacites de la personne connectee.
  Future<CapacitesCommunaute> capacites();

  /// Les categories, dans l'ordre d'affichage.
  Future<List<CategorieCommunaute>> categories();

  /// Les publications, la plus recente d'abord. [categorieId] nul : toutes ;
  /// [recherche] vide : sans recherche (`CommunitySearch`, spec section 18).
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  });

  /// Une publication ; echoue avec [PublicationIntrouvable] si le serveur ne
  /// la rend pas.
  Future<PublicationCommunaute> publication(String publicationId);

  /// Les reponses d'une publication, la plus ancienne d'abord.
  Future<List<ReponseCommunaute>> reponses(String publicationId);

  /// Publie [brouillon] ; rend la publication confirmee par le serveur.
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  });

  /// Repond a [publicationId] ; rend la reponse confirmee par le serveur.
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  });
}

/// La Communaute tant qu'aucun contrat n'existe (COM-BR-05) : chaque appel
/// echoue avec [CapaciteIndisponible], jamais une liste vide inventee.
class CommunauteIndisponible implements PortCommunaute {
  /// Cree l'implementation.
  const CommunauteIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('COM-BR-05');

  @override
  Future<CapacitesCommunaute> capacites() =>
      Future<CapacitesCommunaute>.error(_manque);

  @override
  Future<List<CategorieCommunaute>> categories() =>
      Future<List<CategorieCommunaute>>.error(_manque);

  @override
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  }) => Future<List<PublicationCommunaute>>.error(_manque);

  @override
  Future<PublicationCommunaute> publication(String publicationId) =>
      Future<PublicationCommunaute>.error(_manque);

  @override
  Future<List<ReponseCommunaute>> reponses(String publicationId) =>
      Future<List<ReponseCommunaute>>.error(_manque);

  @override
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  }) => Future<PublicationCommunaute>.error(_manque);

  @override
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  }) => Future<ReponseCommunaute>.error(_manque);
}

/// La Communaute en memoire : **double de demonstration et de test**, jamais
/// branche en production. Rien ne quitte l'appareil.
///
/// [echecLecture] fait echouer toute lecture (etat d'erreur) ; [echecEnvoi]
/// fait echouer tout envoi (« non confirme »). [attente] simule la latence
/// du serveur. Une cle d'idempotence deja vue rend le meme objet, sans
/// doublon.
class CommunauteMemoire implements PortCommunaute {
  /// Cree la memoire sur des donnees de depart.
  CommunauteMemoire({
    required List<CategorieCommunaute> categories,
    required List<PublicationCommunaute> publications,
    Map<String, List<ReponseCommunaute>> reponses =
        const <String, List<ReponseCommunaute>>{},
    required this.soi,
    this.capacitesRendues = const CapacitesCommunaute(
      peutPublier: true,
      peutRepondre: true,
    ),
    this.echecLecture = false,
    this.echecEnvoi = false,
    this.attente = Duration.zero,
    DateTime Function()? maintenant,
  }) : _categories = List<CategorieCommunaute>.of(categories),
       _publications = List<PublicationCommunaute>.of(publications),
       _reponses = <String, List<ReponseCommunaute>>{
         for (final MapEntry<String, List<ReponseCommunaute>> e
             in reponses.entries)
           e.key: List<ReponseCommunaute>.of(e.value),
       },
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final List<CategorieCommunaute> _categories;
  final List<PublicationCommunaute> _publications;
  final Map<String, List<ReponseCommunaute>> _reponses;
  final DateTime Function() _maintenant;
  final Map<String, Object> _parCle = <String, Object>{};
  int _suivant = 0;

  /// La personne connectee, auteur de ce qui est publie ici.
  final Participant soi;

  /// Les capacites rendues.
  final CapacitesCommunaute capacitesRendues;

  /// Vrai : toute lecture echoue.
  bool echecLecture;

  /// Vrai : tout envoi echoue.
  bool echecEnvoi;

  /// La latence simulee.
  final Duration attente;

  /// Le nombre d'envois de publications acceptes (tests).
  int publicationsAcceptees = 0;

  /// Le nombre d'envois de reponses acceptes (tests).
  int reponsesAcceptees = 0;

  Future<void> _lire() async {
    if (attente > Duration.zero) await Future<void>.delayed(attente);
    if (echecLecture) throw StateError('lecture de la Communaute en echec');
  }

  Future<void> _envoyer() async {
    if (attente > Duration.zero) await Future<void>.delayed(attente);
    if (echecEnvoi) throw StateError('envoi a la Communaute non confirme');
  }

  @override
  Future<CapacitesCommunaute> capacites() async {
    await _lire();
    return capacitesRendues;
  }

  @override
  Future<List<CategorieCommunaute>> categories() async {
    await _lire();
    return List<CategorieCommunaute>.unmodifiable(_categories);
  }

  @override
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  }) async {
    await _lire();
    final String cherche = recherche.trim().toLowerCase();
    final List<PublicationCommunaute> liste =
        _publications
            .where(
              (PublicationCommunaute p) =>
                  (categorieId == null || p.categorie.id == categorieId) &&
                  (cherche.isEmpty ||
                      p.titre.toLowerCase().contains(cherche) ||
                      p.texte.toLowerCase().contains(cherche)),
            )
            .map(
              (PublicationCommunaute p) =>
                  p.avecReponses(_reponses[p.id]?.length ?? p.nombreReponses),
            )
            .toList()
          ..sort(
            (PublicationCommunaute a, PublicationCommunaute b) =>
                b.publieeLe.compareTo(a.publieeLe),
          );
    return List<PublicationCommunaute>.unmodifiable(liste);
  }

  @override
  Future<PublicationCommunaute> publication(String publicationId) async {
    await _lire();
    for (final PublicationCommunaute p in _publications) {
      if (p.id == publicationId) {
        return p.avecReponses(_reponses[p.id]?.length ?? p.nombreReponses);
      }
    }
    throw PublicationIntrouvable(publicationId);
  }

  @override
  Future<List<ReponseCommunaute>> reponses(String publicationId) async {
    await _lire();
    if (!_publications.any(
      (PublicationCommunaute p) => p.id == publicationId,
    )) {
      throw PublicationIntrouvable(publicationId);
    }
    return List<ReponseCommunaute>.unmodifiable(
      _reponses[publicationId] ?? const <ReponseCommunaute>[],
    );
  }

  @override
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  }) async {
    await _envoyer();
    final Object? deja = _parCle[cleIdempotence];
    if (deja is PublicationCommunaute) return deja;
    final CategorieCommunaute categorie = _categories.firstWhere(
      (CategorieCommunaute c) => c.id == brouillon.categorieId,
    );
    final PublicationCommunaute publication = PublicationCommunaute(
      id: 'pub-locale-${++_suivant}',
      auteur: soi,
      titre: brouillon.titre.trim(),
      texte: brouillon.texte.trim(),
      categorie: categorie,
      publieeLe: _maintenant(),
      piecesJointes: List<PieceJointe>.unmodifiable(brouillon.piecesJointes),
    );
    _publications.add(publication);
    _parCle[cleIdempotence] = publication;
    publicationsAcceptees++;
    return publication;
  }

  @override
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  }) async {
    await _envoyer();
    final Object? deja = _parCle[cleIdempotence];
    if (deja is ReponseCommunaute) return deja;
    if (!_publications.any(
      (PublicationCommunaute p) => p.id == publicationId,
    )) {
      throw PublicationIntrouvable(publicationId);
    }
    final ReponseCommunaute reponse = ReponseCommunaute(
      id: 'rep-locale-${++_suivant}',
      publicationId: publicationId,
      auteur: soi,
      texte: texte.trim(),
      publieeLe: _maintenant(),
    );
    (_reponses[publicationId] ??= <ReponseCommunaute>[]).add(reponse);
    _parCle[cleIdempotence] = reponse;
    reponsesAcceptees++;
    return reponse;
  }
}

/// Un fichier choisi pour etre joint a une publication : ce que le
/// selecteur en sait avant tout envoi. Aucune adresse, aucun chemin.
@immutable
class FichierChoisi {
  /// Cree le fichier choisi.
  const FichierChoisi({
    required this.nom,
    required this.typeMime,
    required this.typeLisible,
    required this.tailleOctets,
    this.nature = NaturePieceJointe.document,
  });

  /// Le nom du fichier (reduit a son dernier segment a l'affichage).
  final String nom;

  /// Le type MIME, evalue par la politique du serveur.
  final String typeMime;

  /// Le type, deja redige pour l'affichage (« PDF »).
  final String typeLisible;

  /// La taille en octets.
  final int tailleOctets;

  /// La nature, pour l'icone.
  final NaturePieceJointe nature;
}

/// Le choix d'un fichier a joindre a une publication. Il n'est appele que si
/// la politique des pieces jointes est connue (`EntreePieceJointe`) ; sans
/// contrat (COM-BR-04), il echoue avec [CapaciteIndisponible].
abstract interface class ChoixPieceCommunaute {
  /// Demande un fichier ; `null` si la personne renonce.
  Future<FichierChoisi?> choisir();
}

/// Le choix de fichier tant qu'aucun contrat n'existe (COM-BR-04).
class ChoixPieceIndisponible implements ChoixPieceCommunaute {
  /// Cree l'implementation.
  const ChoixPieceIndisponible();

  @override
  Future<FichierChoisi?> choisir() =>
      Future<FichierChoisi?>.error(const CapaciteIndisponible('COM-BR-04'));
}

/// La Communaute employee par l'application.
final Provider<PortCommunaute> portCommunauteProvider =
    Provider<PortCommunaute>(
      (Ref ref) => const CommunauteIndisponible(),
      // Surchargeable dans un ProviderScope imbrique (demonstration).
      dependencies: const <ProviderOrFamily>[],
    );

/// Le choix de fichier employe par l'application.
final Provider<ChoixPieceCommunaute> choixPieceCommunauteProvider =
    Provider<ChoixPieceCommunaute>(
      (Ref ref) => const ChoixPieceIndisponible(),
      dependencies: const <ProviderOrFamily>[],
    );

// Les lectures de la Communaute. `retry` nul : Riverpod 3 relancerait seul une
// lecture en echec pendant une trentaine de secondes, derriere le
// « Reessayer » de l'ecran, qui est la seule retentative (voir
// `service_validation.dart`). Une capacite absente ne se reessaie jamais.

Duration? _sansRetentative(int essai, Object erreur) => null;

/// Les lectures declarent le port : sous un `ProviderScope` imbrique
/// (demonstration), elles suivent le port surcharge au lieu de lire celui
/// de la racine.
final List<ProviderOrFamily> _dependances = <ProviderOrFamily>[
  portCommunauteProvider,
];

/// Le filtre du flux : la categorie (nulle : toutes) et la recherche.
typedef FiltreFlux = ({String? categorieId, String recherche});

/// Les capacites de la personne connectee dans la Communaute.
final FutureProvider<CapacitesCommunaute> capacitesCommunauteProvider =
    FutureProvider.autoDispose<CapacitesCommunaute>(
      (Ref ref) => ref.watch(portCommunauteProvider).capacites(),
      retry: _sansRetentative,
      dependencies: _dependances,
    );

/// Les categories de la Communaute.
final FutureProvider<List<CategorieCommunaute>> categoriesCommunauteProvider =
    FutureProvider.autoDispose<List<CategorieCommunaute>>(
      (Ref ref) => ref.watch(portCommunauteProvider).categories(),
      retry: _sansRetentative,
      dependencies: _dependances,
    );

/// Les publications d'un filtre.
final publicationsCommunauteProvider = FutureProvider.autoDispose
    .family<List<PublicationCommunaute>, FiltreFlux>(
      (Ref ref, FiltreFlux filtre) => ref
          .watch(portCommunauteProvider)
          .publications(
            categorieId: filtre.categorieId,
            recherche: filtre.recherche.trim(),
          ),
      retry: _sansRetentative,
      dependencies: _dependances,
    );

/// Une publication.
final publicationCommunauteProvider = FutureProvider.autoDispose
    .family<PublicationCommunaute, String>(
      (Ref ref, String id) => ref.watch(portCommunauteProvider).publication(id),
      retry: _sansRetentative,
      dependencies: _dependances,
    );

/// Les reponses d'une publication.
final reponsesCommunauteProvider = FutureProvider.autoDispose
    .family<List<ReponseCommunaute>, String>(
      (Ref ref, String id) => ref.watch(portCommunauteProvider).reponses(id),
      retry: _sansRetentative,
      dependencies: _dependances,
    );

/// L'horloge de la Communaute, pour dire « Il y a 2 h ». La demonstration et
/// les tests la fixent.
final Provider<DateTime Function()> horlogeCommunauteProvider =
    Provider<DateTime Function()>(
      (Ref ref) =>
          () => DateTime.now().toUtc(),
    );
