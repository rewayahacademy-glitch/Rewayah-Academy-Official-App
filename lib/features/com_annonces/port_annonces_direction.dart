// Les annonces de la direction vers des publics (ANNONCES-SIMPLES, directeur,
// 14/11/2026 ; migration 20261126900000).
//
// Les publics et leurs nombres sont CALCULES PAR LE SERVEUR : l'ecran ne
// compose aucun public et ne compte personne. Il envoie des codes, il recoit
// des nombres et une raison quand un public est vide. La separation des cotes
// (CAND-Q07) et la protection des mineurs vivent dans la fonction serveur,
// jamais ici.
//
// Le port de production est NEUTRE (`CapaciteIndisponible`) tant que
// l'adaptateur Supabase n'est pas branche (main.dart).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import 'port_annonces.dart';

/// Les codes des publics, dans l'ordre de l'ecran (le serveur rend les siens,
/// dans ce meme ordre).
abstract final class CodesPublics {
  /// Tout le monde inscrit.
  static const String tous = 'tous';

  /// Tous les enseignants.
  static const String enseignants = 'enseignants';

  /// Les candidats en cours.
  static const String candidats = 'candidats';

  /// Les candidats admis (« Bienvenue dans l'equipe »).
  static const String candidatsAdmis = 'candidats_admis';

  /// Les familles (parents et tuteurs).
  static const String familles = 'familles';

  /// Les eleves (adultes, et le parent de chaque enfant).
  static const String eleves = 'eleves';

  /// Les eleves adultes.
  static const String elevesAdultes = 'eleves_adultes';

  /// Les femmes (filtre).
  static const String femmes = 'femmes';

  /// Les hommes (filtre).
  static const String hommes = 'hommes';

  /// Vrai pour un filtre de genre, qui restreint les autres publics.
  static bool estFiltre(String code) => code == femmes || code == hommes;
}

/// L'ordre des publics a l'ecran (le meme que celui du serveur).
const List<String> ordrePublics = <String>[
  CodesPublics.tous,
  CodesPublics.enseignants,
  CodesPublics.candidats,
  CodesPublics.candidatsAdmis,
  CodesPublics.familles,
  CodesPublics.eleves,
  CodesPublics.elevesAdultes,
  CodesPublics.femmes,
  CodesPublics.hommes,
];

/// Un public ouvert a la direction, avec son nombre reel de destinataires.
@immutable
class PublicAnnonce {
  /// Cree le public.
  const PublicAnnonce({required this.code, required this.destinataires});

  /// Le code du public ([CodesPublics]).
  final String code;

  /// Le nombre de personnes qu'il atteint, dans les cotes de la direction.
  final int destinataires;
}

/// Pourquoi une combinaison de publics n'atteint personne.
enum RaisonVide {
  /// Personne ne correspond.
  personne,

  /// Le profil de la direction ne dit pas son cote (CAND-Q07).
  coteInconnu,
}

/// Ce que couterait le courriel, calcule par le serveur.
@immutable
class EstimationCourriel {
  /// Cree l'estimation.
  const EstimationCourriel({
    required this.adresses,
    required this.jours,
    required this.parJour,
  });

  /// Les adresses joignables (desinscriptions exclues).
  final int adresses;

  /// Les jours que prendra l'envoi, file d'attente comprise (0 : aucun).
  final int jours;

  /// Le plafond du jour des courriels non essentiels.
  final int parJour;
}

/// Le nombre exact de destinataires d'une combinaison de publics.
@immutable
class AudienceAnnonce {
  /// Cree l'audience.
  const AudienceAnnonce({
    required this.destinataires,
    required this.courriel,
    this.raison,
  });

  /// Le nombre de personnes atteintes.
  final int destinataires;

  /// Pourquoi personne n'est atteint ; `null` quand quelqu'un l'est.
  final RaisonVide? raison;

  /// Ce que couterait le courriel.
  final EstimationCourriel courriel;
}

/// Une annonce prete a partir vers des publics.
@immutable
class EnvoiAnnonce {
  /// Cree l'envoi.
  const EnvoiAnnonce({
    required this.publics,
    required this.titre,
    required this.texte,
    this.programmeeLe,
    this.courriel = false,
  });

  /// Les codes des publics choisis.
  final Set<String> publics;

  /// Le titre, facultatif (vide : le serveur prend le debut du texte).
  final String titre;

  /// Le texte.
  final String texte;

  /// L'instant de diffusion demande (UTC) ; `null` : tout de suite.
  final DateTime? programmeeLe;

  /// Vrai : un courriel part aussi a chaque destinataire.
  final bool courriel;
}

/// Une annonce recue par la personne (fil d'annonces).
///
/// ANNONCES-SERVEUR (21/11/2026, DECISION-ANNONCES-NOTIFS-2026-11-21.md §2) :
/// [titre] et [texte] sont dans la langue du lecteur quand le serveur a la
/// traduction ([traduite]), sinon l'original ; jamais vides. L'original est
/// toujours a cote ([titreOriginal], [texteOriginal]) pour « عرض النص الأصلي ».
@immutable
class AnnonceRecue {
  /// Cree l'annonce. Sans original fourni, l'original est le texte affiche.
  const AnnonceRecue({
    required this.id,
    required this.titre,
    required this.texte,
    required this.publieeLe,
    this.vue = false,
    String? titreOriginal,
    String? texteOriginal,
    this.langueOriginale,
    this.traduite = false,
    this.fermee = false,
  }) : titreOriginal = titreOriginal ?? titre,
       texteOriginal = texteOriginal ?? texte;

  /// Identifiant.
  final String id;

  /// Le titre, dans la langue du lecteur si traduit, sinon l'original.
  final String titre;

  /// Le texte, dans la langue du lecteur si traduit, sinon l'original.
  final String texte;

  /// L'instant de diffusion (UTC).
  final DateTime publieeLe;

  /// Vrai si la personne l'a deja vue.
  final bool vue;

  /// Le titre tel que la direction l'a ecrit.
  final String titreOriginal;

  /// Le texte tel que la direction l'a ecrit.
  final String texteOriginal;

  /// La langue d'ecriture detectee par le serveur (`fr`, `en`, `ar`...) ;
  /// `null` tant que la traduction n'a pas tourne.
  final String? langueOriginale;

  /// Vrai si [titre] et [texte] sont une traduction (l'original differe).
  final bool traduite;

  /// Vrai si la personne a ferme l'annonce (elle reste lisible dans
  /// « الإعلانات », jamais dans « الكل » ni sur l'accueil).
  final bool fermee;

  /// La meme annonce, fermee ou rouverte.
  AnnonceRecue avecFermee(bool valeur) => AnnonceRecue(
    id: id,
    titre: titre,
    texte: texte,
    publieeLe: publieeLe,
    vue: vue,
    titreOriginal: titreOriginal,
    texteOriginal: texteOriginal,
    langueOriginale: langueOriginale,
    traduite: traduite,
    fermee: valeur,
  );
}

/// Une page du fil d'annonces (20 par defaut, 50 au plus).
@immutable
class PageAnnonces {
  /// Cree la page.
  const PageAnnonces({required this.annonces, this.suite});

  /// Une page vide, sans suite.
  static const PageAnnonces vide = PageAnnonces(annonces: <AnnonceRecue>[]);

  /// Les annonces, de la plus recente a la plus ancienne.
  final List<AnnonceRecue> annonces;

  /// Le curseur de la page suivante (a passer en `avant`) ; `null` : fin.
  final DateTime? suite;
}

/// Les annonces de la direction vers des publics, et le fil de la personne.
abstract interface class PortAnnoncesDirection {
  /// Les publics ouverts a la direction, avec leurs nombres.
  Future<List<PublicAnnonce>> publics();

  /// Le nombre exact de destinataires de [publics].
  Future<AudienceAnnonce> audience(Set<String> publics);

  /// Envoie (ou programme) [envoi]. Le futur ne se termine qu'a l'accuse du
  /// serveur ; [cleIdempotence] est rejouee telle quelle a chaque essai.
  Future<AnnonceConfirmee> envoyer({
    required EnvoiAnnonce envoi,
    required String cleIdempotence,
  });

  /// Une page des annonces recues par la personne connectee (adulte ou
  /// candidat) : [limite] (20, 50 au plus) annonces publiees avant [avant]
  /// (`null` : les plus recentes). [fermees] faux : seulement les annonces
  /// non fermees (« الكل », accueil) ; vrai : toutes (« الإعلانات »).
  Future<PageAnnonces> mesAnnonces({
    int limite = 20,
    DateTime? avant,
    bool fermees = false,
  });

  /// Enregistre que la personne a vu l'annonce [id].
  Future<void> marquerVue(String id);

  /// Ferme l'annonce [id] pour la personne (idempotent).
  Future<void> fermer(String id);

  /// Rouvre l'annonce [id] (« تراجع » ; idempotent).
  Future<void> rouvrir(String id);
}

/// Le port tant qu'aucune source n'existe.
class AnnoncesDirectionIndisponibles implements PortAnnoncesDirection {
  /// Cree l'implementation.
  const AnnoncesDirectionIndisponibles();

  /// Ce qui manque.
  static const CapaciteIndisponible manque = CapaciteIndisponible(
    'ANNONCES-SIMPLES',
  );

  @override
  Future<List<PublicAnnonce>> publics() =>
      Future<List<PublicAnnonce>>.error(manque);

  @override
  Future<AudienceAnnonce> audience(Set<String> publics) =>
      Future<AudienceAnnonce>.error(manque);

  @override
  Future<AnnonceConfirmee> envoyer({
    required EnvoiAnnonce envoi,
    required String cleIdempotence,
  }) => Future<AnnonceConfirmee>.error(manque);

  @override
  Future<PageAnnonces> mesAnnonces({
    int limite = 20,
    DateTime? avant,
    bool fermees = false,
  }) => Future<PageAnnonces>.error(manque);

  @override
  Future<void> marquerVue(String id) => Future<void>.error(manque);

  @override
  Future<void> fermer(String id) => Future<void>.error(manque);

  @override
  Future<void> rouvrir(String id) => Future<void>.error(manque);
}

/// Le port employe par l'application : neutre par defaut.
final Provider<PortAnnoncesDirection> portAnnoncesDirectionProvider =
    Provider<PortAnnoncesDirection>(
      (Ref ref) => const AnnoncesDirectionIndisponibles(),
    );

/// Les publics ouverts a la direction.
final FutureProvider<List<PublicAnnonce>> publicsAnnonceProvider =
    FutureProvider<List<PublicAnnonce>>(
      (Ref ref) => ref.watch(portAnnoncesDirectionProvider).publics(),
    );

/// L'audience d'une combinaison, par sa cle triee (`a,b`).
final FutureProviderFamily<AudienceAnnonce, String> audienceAnnonceProvider =
    FutureProvider.family<AudienceAnnonce, String>(
      (Ref ref, String cle) => ref
          .watch(portAnnoncesDirectionProvider)
          .audience(cle.split(',').where((String c) => c.isNotEmpty).toSet()),
    );

/// La cle stable d'une combinaison de publics.
String clePublics(Set<String> publics) => (publics.toList()..sort()).join(',');

/// Les annonces recues par la personne connectee : la premiere page des
/// annonces non fermees (accueil, « الكل »). Les ecrans qui paginent ou
/// montrent les annonces fermees appellent [PortAnnoncesDirection.mesAnnonces].
final FutureProvider<List<AnnonceRecue>>
mesAnnoncesProvider = FutureProvider<List<AnnonceRecue>>(
  (Ref ref) async =>
      (await ref.watch(portAnnoncesDirectionProvider).mesAnnonces()).annonces,
);

/// Le nom d'un public, dans la langue courante.
String libellePublic(String code) {
  final p = t.com.annonces.simple.publics;
  return switch (code) {
    CodesPublics.tous => p.tous,
    CodesPublics.enseignants => p.enseignants,
    CodesPublics.candidats => p.candidats,
    CodesPublics.candidatsAdmis => p.candidatsAdmis,
    CodesPublics.familles => p.familles,
    CodesPublics.eleves => p.eleves,
    CodesPublics.elevesAdultes => p.elevesAdultes,
    CodesPublics.femmes => p.femmes,
    CodesPublics.hommes => p.hommes,
    _ => code,
  };
}

/// Les noms de plusieurs publics, dans l'ordre du serveur, separes par des
/// virgules.
String libellesPublics(Iterable<String> codes, List<String> ordre) {
  final List<String> tries = <String>[
    for (final String c in ordre)
      if (codes.contains(c)) c,
    for (final String c in codes)
      if (!ordre.contains(c)) c,
  ];
  return tries.map(libellePublic).join(', ');
}
