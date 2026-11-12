import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';

/// Un service Enseignant en memoire, borne a ce que le lot H lui demande.
///
/// **Ecrit ici plutot que repris de `test/support/harnais.dart`** : la decision
/// `D-06` interdit aux agents paralleles d'y toucher, et un faux partage entre
/// deux chantiers serait modifie par les deux.
class FauxServiceEnseignant implements ServiceEnseignant {
  /// Ce que [brouillon] renverra.
  BrouillonCahier? brouillonRendu;

  /// Vrai quand la lecture du brouillon doit echouer, comme hors ligne.
  bool lectureIndisponible = false;

  /// Vrai quand le depot d'un cahier doit echouer, comme hors ligne.
  bool envoiIndisponible = false;

  /// Les cahiers reellement acceptes par le serveur.
  final List<({String cle, String seanceId, Map<String, dynamic> contenu})>
  cahiersDeposes =
      <({String cle, String seanceId, Map<String, dynamic> contenu})>[];

  @override
  Future<BrouillonCahier?> brouillon(String seanceId) async {
    if (lectureIndisponible) {
      throw const _PanneReseau();
    }
    return brouillonRendu;
  }

  @override
  Future<void> deposerCahier({
    required String cleIdempotence,
    required Map<String, dynamic> contenu,
    required String seanceId,
  }) async {
    if (envoiIndisponible) {
      throw const _PanneReseau();
    }
    cahiersDeposes.add((
      cle: cleIdempotence,
      seanceId: seanceId,
      contenu: contenu,
    ));
  }

  @override
  Future<List<CahierEnRetard>> cahiersEnRetard() async =>
      const <CahierEnRetard>[];

  @override
  Future<List<GroupeEnseignant>> groupes() async => const <GroupeEnseignant>[];

  @override
  Future<List<MembreSeance>> membresDuGroupe(String groupeId) async =>
      const <MembreSeance>[];

  @override
  Future<List<MembreSeance>> rosterDeSeance(String seanceId) async =>
      const <MembreSeance>[];

  @override
  Future<List<SeanceEnseignant>> seances() async => const <SeanceEnseignant>[];
}

/// Le depot local des rapports en attente, en memoire.
///
/// Il tient la meme promesse que `DepotRapportsDrift` : une cle deja presente
/// n'est pas reecrite.
class FauxDepotRapports implements DepotRapports {
  /// Les rapports en file, du plus ancien au plus recent.
  final List<RapportEnAttente> rapports = <RapportEnAttente>[];

  @override
  Future<List<RapportEnAttente>> enAttente() async =>
      List<RapportEnAttente>.unmodifiable(rapports);

  @override
  Future<void> deposer(RapportEnAttente rapport) async {
    final bool deja = rapports.any(
      (RapportEnAttente r) => r.cleIdempotence == rapport.cleIdempotence,
    );
    if (!deja) {
      rapports.add(rapport);
    }
  }

  @override
  Future<void> majApresEchec(RapportEnAttente rapport) async {
    final int rang = rapports.indexWhere(
      (RapportEnAttente r) => r.cleIdempotence == rapport.cleIdempotence,
    );
    if (rang != -1) {
      rapports[rang] = rapport;
    }
  }

  @override
  Future<void> retirer(String cleIdempotence) async {
    rapports.removeWhere(
      (RapportEnAttente r) => r.cleIdempotence == cleIdempotence,
    );
  }
}

/// Une panne de reseau, du point de vue du client Supabase.
class _PanneReseau implements Exception {
  const _PanneReseau();

  @override
  String toString() => 'reseau indisponible';
}
