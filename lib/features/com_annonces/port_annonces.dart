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
}

/// Ce que la personne peut faire dans l'espace d'annonces d'une Classe.
enum CapaciteAnnonces {
  /// Publier une annonce pour cette Classe (enseignant de la Classe,
  /// Administration). La publication elle-meme est l'etape COM-ANN-2.
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
