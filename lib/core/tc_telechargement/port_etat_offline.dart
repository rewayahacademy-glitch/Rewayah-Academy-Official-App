import 'dart:async';

import 'package:flutter/foundation.dart';

import '../cache/media/cache_media.dart';
import 'download_asset.dart';
import 'port_telechargement.dart';

/// L'etat hors ligne d'une ressource, **par ressource** (spec section 6.1).
///
/// A ne pas confondre avec `horsLigneProvider`, qui dit si l'APPAREIL a du
/// reseau : ce sont deux faits differents, et la Bibliotheque a besoin des
/// deux. Un appareil en ligne affiche des ressources a telecharger ; un
/// appareil hors ligne ouvre celles qui sont deja la.
enum EtatOffline {
  /// Telechargeable, rien de local.
  aTelecharger,

  /// Telechargement en cours.
  enCours,

  /// Presente dans le cache sans demande explicite : elle peut etre purgee.
  enCache,

  /// Telechargee a la demande de la personne. Conservee.
  telecharge,

  /// Aucun hors ligne possible : politique, droits de distribution, ou aucun
  /// artefact.
  indisponible,
}

/// Ce que le calcul d'etat a besoin de savoir d'une ressource.
///
/// Volontairement minuscule, et volontairement **pas** un `LibraryResource` :
/// `port_catalogue.dart` importe deja ce fichier pour [EtatOffline]. Le
/// descripteur evite la dependance en sens inverse et dit exactement ce dont
/// le calcul a besoin, rien de plus.
@immutable
class DescripteurOffline {
  /// Cree un descripteur.
  const DescripteurOffline({
    required this.resourceId,
    required this.possible,
    this.versionId,
  });

  /// La ressource decrite.
  final String resourceId;

  /// Vrai quand le hors ligne est autorise : politique differente de
  /// `jamais`, capacite `supportsOffline`, et une version publiee.
  final bool possible;

  /// La version courante. Elle entre dans la cle de cache : une version
  /// publiee plus recente ne doit jamais etre servie depuis les octets de
  /// l'ancienne.
  final String? versionId;
}

/// Comment le module retrouve le descripteur d'une ressource.
typedef ResolutionOffline =
    Future<DescripteurOffline?> Function(String resourceId);

/// La moitie manquante de `CacheMedia`.
///
/// `CacheMedia` sait **retirer** un fichier et **lister** ses cles ; il ne sait
/// ni en deposer un, ni en relire un. Le PROMPT B interdit d'editer
/// `lib/core/cache/media/cache_media.dart` et impose de l'etendre par un port :
/// c'est ce port.
///
/// Il **herite** du contrat existant plutot que de le doubler : le jour ou
/// Agent Z ajoute `deposer` et `obtenir` a `CacheMedia`, `CacheMediaFichiers`
/// satisfera cette interface sans une ligne de changement ici, et le fichier
/// disparaitra. Les deux signatures attendues sont dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
abstract interface class DepotOctetsLocal implements CacheMedia {
  /// Depose des octets sous une cle.
  Future<void> deposer(String cle, List<int> octets);

  /// Relit les octets d'une cle. `null` quand rien n'est conserve.
  Future<List<int>?> obtenir(String cle);
}

/// Le depot local en memoire.
///
/// **Limite assumee, ecrite ici plutot que decouverte a l'usage** : rien ne
/// survit a un redemarrage. Ce n'est pas une regression par rapport a
/// l'existant -- `CacheMediaFichiers` tient deja ses cles dans un `Set` en
/// memoire -- mais ce n'est pas non plus le hors ligne durable que la spec
/// demande. La persistance exige une table locale, donc une migration Drift 1
/// vers 2 qui n'existe pas : c'est une demande d'Agent Z.
class DepotOctetsMemoire implements DepotOctetsLocal {
  final Map<String, List<int>> _octets = <String, List<int>>{};

  @override
  Future<void> deposer(String cle, List<int> octets) async {
    _octets[cle] = List<int>.unmodifiable(octets);
  }

  @override
  Future<List<int>?> obtenir(String cle) async => _octets[cle];

  @override
  Future<void> retirer(String cle) async {
    _octets.remove(cle);
  }

  @override
  Future<Set<String>> clesConservees() async => Set<String>.of(_octets.keys);
}

/// Un telechargement qui ne peut pas aboutir.
///
/// Un port n'avale jamais une erreur en silence (CONTRACTS section 0) : une
/// carte laissee sur `enCours` ferait croire a une lenteur reseau alors que
/// rien n'est en route.
class EchecTelechargementRessource implements Exception {
  /// Cree l'echec.
  const EchecTelechargementRessource(this.raison);

  /// Ce qui a empeche le telechargement, en une phrase technique.
  final String raison;

  @override
  String toString() => 'EchecTelechargementRessource: $raison';
}

/// L'etat hors ligne par ressource, et les deux gestes qui le changent.
abstract class PortEtatOffline {
  /// L'etat courant d'une ressource.
  Future<EtatOffline> etatDe(String resourceId);

  /// Le flux d'etat d'une ressource.
  ///
  /// Emet l'etat courant a l'abonnement, puis a chaque changement : une carte
  /// montee apres le debut d'un telechargement affiche `enCours` des la
  /// premiere frame. Meme regle que `ServiceReseau.horsLigne()`.
  Stream<EtatOffline> suivre(String resourceId);

  /// Demande le telechargement. Leve [EchecTelechargementRessource] quand
  /// aucun artefact n'est obtenable.
  Future<void> demanderTelechargement(String resourceId);

  /// Libere la place occupee localement.
  Future<void> libererCache(String resourceId);
}

/// L'etat hors ligne, adosse au cache fichier du produit.
///
/// **Aucun second cache, aucun second abonnement reseau.** `CacheMedia` est
/// l'abstraction de cache du produit ; ce module s'y branche au lieu de creer
/// un `ServiceTelechargement` parallele (EXISTING_MAPPING section 9.2). L'etat
/// du reseau, lui, reste celui de `horsLigneProvider`, lu par l'interface :
/// cette classe ne sait que ce qui est local.
class EtatOfflineCache implements PortEtatOffline {
  /// Cree le module d'etat.
  EtatOfflineCache({
    required this.depot,
    required this.resoudre,
    required this.telechargement,
    required this.lecteur,
  });

  /// Le depot d'octets local.
  final DepotOctetsLocal depot;

  /// Comment retrouver le descripteur d'une ressource.
  final ResolutionOffline resoudre;

  /// L'acces aux artefacts.
  final PortTelechargement telechargement;

  /// La lecture des octets d'un artefact.
  final LecteurArtefact lecteur;

  /// Les ressources demandees explicitement par la personne.
  final Set<String> _epinglees = <String>{};

  /// Les telechargements en vol.
  final Set<String> _enCours = <String>{};

  /// Les flux ouverts, un par ressource suivie.
  ///
  /// Ils sont fermes par [fermer], que le provider appelle a la destruction.
  /// La regle `close_sinks` ne sait pas suivre un `Sink` range dans une
  /// collection : l'exception est donc nommee ici, pas subie.
  // ignore: close_sinks
  final Map<String, StreamController<EtatOffline>> _flux =
      <String, StreamController<EtatOffline>>{};

  /// La cle de cache d'une ressource, version comprise.
  static String cleCache(String resourceId, String? versionId) =>
      'tc-bibliotheque/$resourceId/${versionId ?? 'sans-version'}';

  @override
  Future<EtatOffline> etatDe(String resourceId) async {
    final DescripteurOffline? d = await resoudre(resourceId);
    if (d == null || !d.possible) return EtatOffline.indisponible;
    if (_enCours.contains(resourceId)) return EtatOffline.enCours;

    final Set<String> conservees = await depot.clesConservees();
    if (!conservees.contains(cleCache(resourceId, d.versionId))) {
      return EtatOffline.aTelecharger;
    }
    return _epinglees.contains(resourceId)
        ? EtatOffline.telecharge
        : EtatOffline.enCache;
  }

  @override
  Stream<EtatOffline> suivre(String resourceId) async* {
    // Le controleur est range dans `_flux` et ferme par `fermer()`, que le
    // provider appelle a la destruction. `close_sinks` ne sait pas suivre un
    // `Sink` a travers une collection : l'exception est nommee, pas subie.
    // ignore: close_sinks
    final StreamController<EtatOffline> controleur = _flux.putIfAbsent(
      resourceId,
      StreamController<EtatOffline>.broadcast,
    );
    yield await etatDe(resourceId);
    yield* controleur.stream;
  }

  @override
  Future<void> demanderTelechargement(String resourceId) async {
    final DescripteurOffline? d = await resoudre(resourceId);
    if (d == null || !d.possible) {
      throw const EchecTelechargementRessource(
        'la ressource n autorise pas le hors ligne',
      );
    }

    _enCours.add(resourceId);
    _publier(resourceId, EtatOffline.enCours);
    try {
      final DownloadAsset? asset = await telechargement.artefactDe(
        d.versionId ?? '',
        FormatArtefact.pdf,
      );
      if (asset == null) {
        throw const EchecTelechargementRessource('aucun artefact publie');
      }
      final List<int>? octets = await lecteur.octets(asset);
      if (octets == null) {
        throw const EchecTelechargementRessource('artefact non obtenable');
      }
      await depot.deposer(cleCache(resourceId, d.versionId), octets);
      _epinglees.add(resourceId);
    } finally {
      // L'etat se republie dans tous les cas, succes comme echec : une carte
      // laissee sur `enCours` apres une erreur serait le pire des deux mondes.
      _enCours.remove(resourceId);
      _publier(resourceId, await etatDe(resourceId));
    }
  }

  @override
  Future<void> libererCache(String resourceId) async {
    final DescripteurOffline? d = await resoudre(resourceId);
    await depot.retirer(cleCache(resourceId, d?.versionId));
    _epinglees.remove(resourceId);
    _publier(resourceId, await etatDe(resourceId));
  }

  /// Ferme les flux ouverts. Appelee quand le module est jete.
  Future<void> fermer() async {
    for (final StreamController<EtatOffline> c in _flux.values) {
      await c.close();
    }
    _flux.clear();
  }

  void _publier(String resourceId, EtatOffline etat) {
    // Lecture seule d'un controleur deja range : c'est `fermer()` qui le
    // ferme, jamais cette methode.
    // ignore: close_sinks
    final StreamController<EtatOffline>? c = _flux[resourceId];
    if (c != null && !c.isClosed) c.add(etat);
  }
}
