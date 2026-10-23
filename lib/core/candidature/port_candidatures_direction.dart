// Le port de la direction pour les candidatures : `PortCandidaturesDirection`
// (`docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 1).
//
// - `ADM-20` (la file) : `capacites` et `lister`.
// - `ADM-21` (la candidature) : `lire`, `lireContact`, `historique`, `geste`,
//   `responsablesPossibles` et `moyensConfirmes`. Les lots (`preparerLot`,
//   `executerLot`, `ADM-22`) et les entretiens (`ADM-20E`, L4) s'ajouteront
//   avec l'ecran qui les emploie.
//
// Les refus sont des exceptions typees, jamais un code a l'ecran :
// [PermissionInsuffisante] (acces refuse, sans « Reessayer »), [GenreLecteurInconnu]
// (la fiche du lecteur ne dit pas de quel cote il travaille),
// [CandidatureHorsPortee] et [CandidatureIntrouvable] (deux erreurs, jamais
// l'une pour l'autre), [RefusGeste] (un refus nomme d'un geste) et
// [CapaciteIndisponible] (`CAND-BR-nn` : le serveur ne sert pas encore ce qui
// est demande). Un port absent (le provider vaut `null`) rend la meme capacite
// indisponible : jamais une liste vide, jamais une donnee fictive.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import 'gestes_candidature.dart';
import 'modeles_candidature.dart';
import 'modeles_candidature_detail.dart';
import 'modeles_candidatures_direction.dart';

/// La fiche du lecteur ne dit pas de quel cote (femmes ou hommes) il travaille :
/// le serveur refuse toute lecture de la file, hors exception du super-admin
/// (`CONS` 8.2). Ce n'est ni un acces refuse ni une panne : l'ecran dit quoi
/// faire.
class GenreLecteurInconnu implements Exception {
  /// Cree l'exception.
  const GenreLecteurInconnu();

  @override
  String toString() => 'GenreLecteurInconnu';
}

/// Le port de lecture de la direction.
abstract interface class PortCandidaturesDirection {
  /// Ce que ce lecteur peut faire de la file.
  /// `CapaciteIndisponible('CAND-BR-02')` quand le serveur ne les sert pas.
  Future<CapacitesCandidatures> capacites();

  /// Une page de la file, filtree et triee au serveur, dans la portee de genre
  /// du lecteur. Chaque appel est journalise cote serveur.
  ///
  /// [PermissionInsuffisante] sans droit, [GenreLecteurInconnu] sans genre
  /// connu, `CapaciteIndisponible('CAND-BR-02')` sans lot serveur.
  Future<PageCandidatures> lister({
    required FiltreCandidatures filtre,
    required TriCandidatures tri,
    required int page,
  });

  /// Le dossier d'une candidature, dans la portee de genre du lecteur.
  ///
  /// [CandidatureHorsPortee] quand elle est de l'autre cote (le serveur trace la
  /// tentative et ne rend aucune donnee), [CandidatureIntrouvable] quand elle
  /// n'existe pas ; deux erreurs, jamais l'une pour l'autre.
  Future<DetailCandidature> lire(String candidatureId);

  /// Le contact de la candidature (courriel et telephone), pour la direction
  /// nommee. **Chaque lecture est inscrite au journal.** [PermissionInsuffisante]
  /// sans nomination.
  Future<ContactCandidat> lireContact(String candidatureId);

  /// Une page de l'historique, du plus recent au plus ancien. [curseur] est le
  /// `curseurSuivant` de la page precedente.
  Future<PageHistorique> historique(String candidatureId, {int? curseur});

  /// Fait un geste. Rend la candidature relue au serveur apres l'ecriture :
  /// jamais un succes sans elle. Un refus nomme du serveur est un [RefusGeste] ;
  /// aucune ecriture n'a eu lieu. [GesteNonConfirme] quand le serveur n'a pas
  /// repondu : rejouer la meme [DemandeGeste.cleIdempotence] est sans risque.
  Future<ResultatGeste> geste(DemandeGeste demande);

  /// Les membres de la direction que la candidature peut avoir pour
  /// responsable. `CapaciteIndisponible('CAND-BR-04')` tant que le serveur ne
  /// sert pas la liste.
  Future<List<ResponsablePossible>> responsablesPossibles(String candidatureId);

  /// Les moyens de versement que Rewayah a confirmes pour [paysVersement] (code
  /// ISO) : le virement bancaire, et les operateurs de monnaie mobile avec
  /// leur nom. Sert a nommer les moyens declares par la personne.
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement);
}

/// L'identifiant de la dependance serveur du detail, du contact et des erreurs
/// de portee (`CAND-BR-03`), pour la trace et les tests : jamais affiche.
const String dependanceDetailCandidature = 'CAND-BR-03';

/// L'identifiant de la dependance serveur des gestes et du responsable
/// (`CAND-BR-04`), pour la trace et les tests : jamais affiche.
const String dependanceGestesCandidature = 'CAND-BR-04';

/// L'identifiant de la dependance serveur de l'historique (`CAND-BR-07`), pour
/// la trace et les tests : jamais affiche.
const String dependanceHistoriqueCandidature = 'CAND-BR-07';

/// L'identifiant de la dependance serveur de la file (`CAND-BR-02`), pour la
/// trace et les tests : jamais affiche.
const String dependanceFileCandidatures = 'CAND-BR-02';

/// Le port de la direction : absent avant le branchement serveur.
final Provider<PortCandidaturesDirection?> portCandidaturesDirectionProvider =
    Provider<PortCandidaturesDirection?>((Ref _) => null);

/// Les capacites de la direction sur la file. Sans port :
/// [CapaciteIndisponible]. Relues a chaque ouverture de la page.
final FutureProvider<CapacitesCandidatures> capacitesCandidaturesProvider =
    FutureProvider.autoDispose<CapacitesCandidatures>((Ref ref) {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        return Future<CapacitesCandidatures>.error(
          const CapaciteIndisponible(dependanceFileCandidatures),
        );
      }
      return port.capacites();
    }, retry: (int _, Object _) => null);

/// Une page de la file. Sans port : [CapaciteIndisponible]. Aucune
/// retentative automatique : chaque lecture est journalisee au serveur, un
/// echec se relit par « Reessayer ».
final FutureProviderFamily<PageCandidatures, RequeteCandidatures>
pageCandidaturesProvider = FutureProvider.autoDispose
    .family<PageCandidatures, RequeteCandidatures>((
      Ref ref,
      RequeteCandidatures requete,
    ) {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        return Future<PageCandidatures>.error(
          const CapaciteIndisponible(dependanceFileCandidatures),
        );
      }
      return port.lister(
        filtre: requete.filtre,
        tri: requete.tri,
        page: requete.page,
      );
    }, retry: (int _, Object _) => null);

/// Ce que la page `ADM-21` ouvre : la reference `CAND-…` de l'adresse, et
/// l'identifiant quand la navigation le connait deja (depuis une ligne de la
/// file). Sans identifiant (adresse tapee, page rechargee), la reference est
/// resolue par la recherche exacte de la file, dans la portee du lecteur.
@immutable
class DemandeDossier {
  /// Cree la demande.
  const DemandeDossier(this.reference, {this.id});

  /// La reference `CAND-…`, telle que l'adresse la porte.
  final String reference;

  /// L'identifiant de la candidature, quand il est connu.
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is DemandeDossier && other.reference == reference && other.id == id;

  @override
  int get hashCode => Object.hash(reference, id);
}

/// Le dossier d'une candidature. Sans port : [CapaciteIndisponible]. Aucune
/// retentative automatique : chaque lecture est journalisee au serveur, un
/// echec se relit par « Reessayer ».
final FutureProviderFamily<DetailCandidature, DemandeDossier>
detailCandidatureProvider = FutureProvider.autoDispose
    .family<DetailCandidature, DemandeDossier>((
      Ref ref,
      DemandeDossier demande,
    ) async {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        throw const CapaciteIndisponible(dependanceDetailCandidature);
      }
      final String id =
          demande.id ?? await identifiantDeReference(port, demande.reference);
      return port.lire(id);
    }, retry: (int _, Object _) => null);

/// Retrouve l'identifiant d'une candidature par sa reference exacte, dans la
/// portee du lecteur : la file la rend par sa recherche. Une reference que la
/// file ne rend pas est [CandidatureIntrouvable] (absente, ou hors de la
/// portee de la file ; la lecture par identifiant dit alors laquelle des deux).
Future<String> identifiantDeReference(
  PortCandidaturesDirection port,
  String reference,
) async {
  final FiltreCandidatures filtre = FiltreCandidatures(recherche: reference);
  final PageCandidatures page = await port.lister(
    filtre: filtre,
    tri: TriCandidatures.activite,
    page: 1,
  );
  final String voulue = reference.replaceAll(
    RegExp('[\u2010\u2011\u2012\u2013\u2014\u2212]'),
    '-',
  );
  for (final LigneCandidature l in page.lignes) {
    if (l.reference == voulue) {
      return l.id;
    }
  }
  throw const CandidatureIntrouvable();
}

/// La premiere page de l'historique d'une candidature. Sans port :
/// [CapaciteIndisponible].
final FutureProviderFamily<PageHistorique, String>
historiqueCandidatureProvider = FutureProvider.autoDispose
    .family<PageHistorique, String>((Ref ref, String candidatureId) {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        return Future<PageHistorique>.error(
          const CapaciteIndisponible(dependanceHistoriqueCandidature),
        );
      }
      return port.historique(candidatureId);
    }, retry: (int _, Object _) => null);

/// Les responsables possibles d'une candidature. Sans port :
/// [CapaciteIndisponible].
final FutureProviderFamily<List<ResponsablePossible>, String>
responsablesPossiblesProvider = FutureProvider.autoDispose
    .family<List<ResponsablePossible>, String>((Ref ref, String candidatureId) {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        return Future<List<ResponsablePossible>>.error(
          const CapaciteIndisponible(dependanceGestesCandidature),
        );
      }
      return port.responsablesPossibles(candidatureId);
    }, retry: (int _, Object _) => null);

/// Les moyens de versement confirmes d'un pays, vus par la direction. Sans
/// port : [CapaciteIndisponible].
final FutureProviderFamily<MoyensConfirmes, String>
moyensConfirmesDirectionProvider = FutureProvider.autoDispose
    .family<MoyensConfirmes, String>((Ref ref, String pays) {
      final PortCandidaturesDirection? port = ref.watch(
        portCandidaturesDirectionProvider,
      );
      if (port == null) {
        return Future<MoyensConfirmes>.error(
          const CapaciteIndisponible(dependanceGestesCandidature),
        );
      }
      return port.moyensConfirmes(pays);
    }, retry: (int _, Object _) => null);
