import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_groupes.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../cache/media/cache_media.dart';
import '../tc_telechargement/download_asset.dart';
import '../tc_telechargement/port_etat_offline.dart';
import '../tc_telechargement/port_telechargement.dart';
import 'catalogue_local.dart';
import 'library_resource.dart';
import 'port_catalogue.dart';
import 'port_versions_ressource.dart';
import 'resource_version.dart';

/// Le point de composition du module Bibliotheque.
///
/// Les providers vivent ici plutot qu'a cote de chaque interface pour une
/// raison precise : `port_catalogue.dart` importe deja
/// `port_etat_offline.dart` pour l'enum `EtatOffline`, et l'etat hors ligne a
/// besoin du catalogue pour resoudre une ressource. Les declarer chacun dans
/// son fichier fermerait un cycle d'imports entre deux contrats. Ce n'est pas
/// une racine d'injection du produit -- le depot n'en a volontairement aucune
/// (EXISTING_MAPPING section 9.6) -- c'est le cablage d'un seul module.

/// Le catalogue employe par l'application.
///
/// Vide par defaut : aucune table de ressource n'existe en base, et livrer un
/// contenu de demonstration ferait passer une maquette pour un produit. Agent Z
/// remplace cette valeur par l'implementation Supabase.
final Provider<PortCatalogue> portCatalogueProvider = Provider<PortCatalogue>(
  (Ref ref) => CatalogueLocal(),
);

/// Les versions de ressources employees par l'application.
final Provider<PortVersionsRessource> portVersionsRessourceProvider =
    Provider<PortVersionsRessource>((Ref ref) => VersionsLocales());

/// Le depot d'artefacts local, **une seule instance**.
///
/// Deux instances rendraient un artefact trouvable par `artefactDe` et ses
/// octets introuvables par `octets` : le meme depot doit repondre aux deux
/// questions.
final Provider<ArtefactsLocaux> _artefactsProvider = Provider<ArtefactsLocaux>(
  (Ref ref) => ArtefactsLocaux(),
);

/// Les artefacts telechargeables employes par l'application.
final Provider<PortTelechargement> portTelechargementProvider =
    Provider<PortTelechargement>((Ref ref) => ref.watch(_artefactsProvider));

/// La lecture des octets d'un artefact.
final Provider<LecteurArtefact> lecteurArtefactProvider =
    Provider<LecteurArtefact>((Ref ref) => ref.watch(_artefactsProvider));

/// Le depot local d'octets.
///
/// Un seul par application : deux depots feraient diverger l'etat hors ligne
/// affiche et les octets reellement conserves. `CacheMediaFichiers`, le cache
/// media reel du produit -- pas un double en memoire -- pour que le hors
/// ligne de la Bibliotheque survive effectivement a un redemarrage.
final Provider<CacheMedia> depotOctetsProvider = Provider<CacheMedia>(
  (Ref ref) => CacheMediaFichiers(),
);

/// L'etat hors ligne par ressource.
///
/// La resolution passe par le catalogue et les versions : c'est la que se
/// decide si une ressource **peut** exister hors ligne. Trois conditions, et
/// les trois sont necessaires -- la politique, la capacite, et une version
/// publiee. Une seule qui manque, et il n'y a rien a telecharger.
final Provider<PortEtatOffline> portEtatOfflineProvider =
    Provider<PortEtatOffline>((Ref ref) {
      final PortCatalogue catalogue = ref.watch(portCatalogueProvider);
      final PortVersionsRessource versions = ref.watch(
        portVersionsRessourceProvider,
      );
      final EtatOfflineCache module = EtatOfflineCache(
        depot: ref.watch(depotOctetsProvider),
        telechargement: ref.watch(portTelechargementProvider),
        lecteur: ref.watch(lecteurArtefactProvider),
        resoudre: (String resourceId) async {
          final LibraryResource? r = await catalogue.parId(resourceId);
          if (r == null) return null;
          final ResourceVersion? v = await versions.versionCourante(
            resourceId,
          );
          return DescripteurOffline(
            resourceId: resourceId,
            versionId: v?.id,
            possible:
                r.offlinePolicy != PolitiqueOffline.jamais &&
                r.peut(CapaciteRessource.supportsOffline) &&
                v != null,
          );
        },
      );
      ref.onDispose(module.fermer);
      return module;
    });

/// Ce dont un ecran de Bibliotheque a besoin, en une seule lecture.
///
/// Une lecture unique et non quatre providers : les quatre sources doivent
/// etre coherentes entre elles a l'instant ou la vue se compose. Quatre
/// `FutureProvider` independants afficheraient « Recents » a jour au-dessus
/// d'un « Tous les supports » d'avant le dernier rafraichissement.
@immutable
class DonneesCatalogue {
  /// Cree un jeu de donnees.
  const DonneesCatalogue({
    required this.tous,
    required this.recents,
    required this.pourGroupe,
    required this.etatsOffline,
    this.reprise,
  });

  /// Tous les supports visibles.
  final List<LibraryResource> tous;

  /// Les ressources recemment ouvertes.
  final List<LibraryResource> recents;

  /// Les ressources du groupe courant. Vide quand aucun groupe n'est donne.
  final List<LibraryResource> pourGroupe;

  /// L'etat hors ligne de chaque ressource citee.
  final Map<String, EtatOffline> etatsOffline;

  /// « Continuer », quand il y a de quoi reprendre.
  final ReprisLecture? reprise;
}

/// Les donnees de la Bibliotheque, pour un groupe donne ou sans groupe.
final FutureProviderFamily<DonneesCatalogue, String?> donneesCatalogueProvider =
    FutureProvider.family<DonneesCatalogue, String?>(
      (Ref ref, String? groupeId) => lireDonneesCatalogue(
        catalogue: ref.watch(portCatalogueProvider),
        offline: ref.watch(portEtatOfflineProvider),
        groupeId: groupeId,
      ),
    );

/// Lit les donnees de la Bibliotheque depuis [catalogue] et [offline].
///
/// Sortie du provider pour qu'un ecran de demonstration surcharge un membre
/// de la famille sous un `ProviderScope` imbrique (TB-8) : la famille, sans
/// `dependencies`, se resoudrait sinon dans le conteneur racine.
Future<DonneesCatalogue> lireDonneesCatalogue({
  required PortCatalogue catalogue,
  required PortEtatOffline offline,
  String? groupeId,
}) async {
  final List<LibraryResource> tous = await catalogue.tous();
  final List<LibraryResource> recents = await catalogue.recents();
  // Des quatre lectures, une seule peut etre REFUSEE : cote serveur,
  // `ressources_du_groupe` (migration 0033) LEVE sur un groupe qui n'est
  // pas celui de l'appelant, elle ne rend pas une liste vide. Et le groupe
  // vient desormais de l'adresse (`?groupe=`), donc d'une valeur que
  // n'importe qui peut ecrire. Sans cette garde, un identifiant falsifie
  // emporterait `tous`, `recents` et `reprise` avec lui : toute la
  // Bibliotheque tomberait pour une seule section. La garde prend tout
  // echec, et pas seulement `EchecCatalogue` : aucun adaptateur serveur
  // n'est encore ecrit, et rien ne garantit la forme de ce qu'il levera.
  // Une section vide disparait, elle ne se remplit pas d'autre chose
  // (`surface_bibliotheque.dart`).
  final List<LibraryResource> pourGroupe = groupeId == null
      ? const <LibraryResource>[]
      : await catalogue
            .pourGroupe(groupeId)
            .onError<Object>(
              (Object erreur, StackTrace trace) => const <LibraryResource>[],
            );
  final ReprisLecture? reprise = await catalogue.derniereLecture();

  // L'etat hors ligne se mesure une fois par ressource citee, pas une fois
  // par carte : la meme ressource apparait dans « Recents » et dans « Tous
  // les supports », et deux mesures pourraient diverger a l'ecran.
  final Map<String, EtatOffline> etats = <String, EtatOffline>{};
  for (final LibraryResource r in <LibraryResource>[
    ...tous,
    ...recents,
    ...pourGroupe,
    if (reprise != null) reprise.ressource,
  ]) {
    if (etats.containsKey(r.id)) continue;
    etats[r.id] = await offline.etatDe(r.id);
  }

  return DonneesCatalogue(
    tous: tous,
    recents: recents,
    pourGroupe: pourGroupe,
    etatsOffline: Map<String, EtatOffline>.unmodifiable(etats),
    reprise: reprise,
  );
}

/// La fiche d'une ressource : son manifeste, sa version, son artefact.
@immutable
class DetailRessource {
  /// Cree une fiche.
  const DetailRessource({
    required this.ressource,
    required this.etatOffline,
    this.version,
    this.artefactPdf,
  });

  /// Le manifeste.
  final LibraryResource ressource;

  /// Son etat hors ligne au moment de la lecture.
  final EtatOffline etatOffline;

  /// La version publiee courante. `null` quand rien n'est publie.
  final ResourceVersion? version;

  /// L'artefact PDF de cette version. `null` quand elle n'en porte pas :
  /// **on n'en fabrique pas un a la volee** (spec section 6.5).
  final DownloadAsset? artefactPdf;

  /// Vrai quand une copie peut reellement etre enregistree.
  bool get copiePossible => artefactPdf != null;
}

/// La fiche d'une ressource, ou `null` quand l'appelant ne la voit pas.
///
/// **`null` n'est pas une erreur** : c'est la reponse normale du serveur quand
/// la ressource a ete retiree ou qu'elle est reservee a un autre groupe. Une
/// absence ouvre un etat explique, un echec ouvre un etat de panne, et les
/// deux ne se disent pas de la meme facon (`lib/CLAUDE.md`, etape 3).
final FutureProviderFamily<DetailRessource?, String> detailRessourceProvider =
    FutureProvider.family<DetailRessource?, String>((
      Ref ref,
      String resourceId,
    ) async {
      final LibraryResource? r = await ref
          .watch(portCatalogueProvider)
          .parId(resourceId);
      if (r == null) return null;

      final ResourceVersion? version = await ref
          .watch(portVersionsRessourceProvider)
          .versionCourante(resourceId);
      final DownloadAsset? pdf = version == null
          ? null
          : await ref
                .watch(portTelechargementProvider)
                .artefactDe(version.id, FormatArtefact.pdf);

      return DetailRessource(
        ressource: r,
        version: version,
        artefactPdf: pdf,
        etatOffline: await ref
            .watch(portEtatOfflineProvider)
            .etatDe(resourceId),
      );
    });
