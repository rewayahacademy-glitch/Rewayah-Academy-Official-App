// Fixtures de Bibliotheque : les cinq types de ressource, leurs versions et
// leurs artefacts telechargeables.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.

import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';

/// L'instant de reference des fixtures de ressource.
final DateTime publicationReference = DateTime.utc(2026, 9, 1, 8);

/// Le Coran : source **canonique structuree et immuable** (decision D-09).
///
/// Son edition est le code du mushaf, jamais un uuid : l'identifiant de
/// `mushaf` est genere par la base et differe d'un environnement a l'autre.
const LibraryResource ressourceCoran = LibraryResource(
  id: 'res-coran',
  title: 'Le Coran - Mushaf de Medine',
  shortTitle: 'Coran',
  coverAsset: 'covers/coran-madina.webp',
  resourceType: TypeRessource.quran,
  edition: 'madina-hafs-604',
  language: 'ar',
  category: 'Coran',
  levelScope: <String>['n1', 'n2', 'n3'],
  accessPolicy: PolitiqueAcces.inscrits,
  offlinePolicy: PolitiqueOffline.automatique,
  currentVersionId: 'ver-coran-1',
  capabilities: <CapaciteRessource>{
    CapaciteRessource.pageable,
    CapaciteRessource.searchable,
    CapaciteRessource.zoomable,
    CapaciteRessource.selectable,
    CapaciteRessource.focusable,
    CapaciteRessource.annotatable,
    CapaciteRessource.assignable,
    CapaciteRessource.presentableInClass,
    CapaciteRessource.supportsStylus,
    CapaciteRessource.supportsOffline,
  },
);

/// Un PDF **importe tel quel** : Rewayah l'habille, il ne le remplace pas.
const LibraryResource ressourcePdf = LibraryResource(
  id: 'res-pdf',
  title: 'Al-Ajurrumiyya - texte et notes',
  shortTitle: 'Ajurrumiyya',
  coverAsset: 'covers/ajurrumiyya.webp',
  resourceType: TypeRessource.pdf,
  language: 'ar',
  category: 'Langue arabe',
  levelScope: <String>['n2'],
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.surDemande,
  currentVersionId: 'ver-pdf-2',
  capabilities: <CapaciteRessource>{
    CapaciteRessource.pageable,
    CapaciteRessource.zoomable,
    CapaciteRessource.annotatable,
    CapaciteRessource.assignable,
    CapaciteRessource.presentableInClass,
    CapaciteRessource.supportsStylus,
    CapaciteRessource.supportsOffline,
  },
);

/// Un texte structure : reflowable, donc **ancre par section**, pas par page.
const LibraryResource ressourceTexteStructure = LibraryResource(
  id: 'res-texte',
  title: 'Les trois fondements - commentaire',
  shortTitle: 'Trois fondements',
  coverAsset: 'covers/trois-fondements.webp',
  resourceType: TypeRessource.texteStructure,
  language: 'fr',
  category: 'Tawhid',
  levelScope: <String>['n1'],
  accessPolicy: PolitiqueAcces.inscrits,
  offlinePolicy: PolitiqueOffline.automatique,
  currentVersionId: 'ver-texte-1',
  capabilities: <CapaciteRessource>{
    CapaciteRessource.searchable,
    CapaciteRessource.selectable,
    CapaciteRessource.focusable,
    CapaciteRessource.annotatable,
    CapaciteRessource.assignable,
    CapaciteRessource.presentableInClass,
    CapaciteRessource.supportsOffline,
  },
);

/// Une image : ni paginable, ni cherchable, et surtout **pas annotable**.
///
/// Elle existe pour que les tests de capacite aient un contre-exemple : une
/// interface qui « devinerait » qu'un support est annotable se trahirait ici.
const LibraryResource ressourceImage = LibraryResource(
  id: 'res-image',
  title: 'Les points d articulation',
  shortTitle: 'Makharij',
  coverAsset: 'covers/makharij.webp',
  resourceType: TypeRessource.image,
  language: 'fr',
  category: 'Tajwid',
  levelScope: <String>['n1', 'n2'],
  accessPolicy: PolitiqueAcces.publique,
  offlinePolicy: PolitiqueOffline.automatique,
  currentVersionId: 'ver-image-1',
  capabilities: <CapaciteRessource>{
    CapaciteRessource.zoomable,
    CapaciteRessource.presentableInClass,
    CapaciteRessource.supportsOffline,
  },
);

/// Une lecon du programme, sans version publiee : le cas « catalogue vide ».
const LibraryResource ressourceLecon = LibraryResource(
  id: 'res-lecon',
  title: 'Lecon 4 - les regles du noun sakinah',
  shortTitle: 'Noun sakinah',
  resourceType: TypeRessource.lecon,
  language: 'fr',
  category: 'Tajwid',
  levelScope: <String>['n2'],
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.jamais,
  capabilities: <CapaciteRessource>{
    CapaciteRessource.selectable,
    CapaciteRessource.assignable,
    CapaciteRessource.presentableInClass,
  },
);

/// Les cinq ressources de fixture.
List<LibraryResource> toutesLesRessources() => <LibraryResource>[
  ressourceCoran,
  ressourcePdf,
  ressourceTexteStructure,
  ressourceImage,
  ressourceLecon,
];

/// La version publiee du PDF, avec son artefact deja genere.
final ResourceVersion versionPdfPubliee = ResourceVersion(
  id: 'ver-pdf-2',
  resourceId: 'res-pdf',
  numeroVersion: 2,
  statut: StatutVersionRessource.publiee,
  publieeLeUtc: publicationReference,
  publieePar: 'admin-001',
  downloadAssetId: 'asset-pdf-2',
  empreinte:
      'a3f1c0d4b9e27856a3f1c0d4b9e27856a3f1c0d4b9e27856a3f1c0d4b9e27856',
);

/// Un brouillon : il n'a ni artefact, ni empreinte, et c'est normal.
final ResourceVersion versionPdfBrouillon = ResourceVersion(
  id: 'ver-pdf-3',
  resourceId: 'res-pdf',
  numeroVersion: 3,
  statut: StatutVersionRessource.brouillon,
);

/// La version publiee du Coran.
final ResourceVersion versionCoranPubliee = ResourceVersion(
  id: 'ver-coran-1',
  resourceId: 'res-coran',
  numeroVersion: 1,
  statut: StatutVersionRessource.publiee,
  publieeLeUtc: publicationReference,
  publieePar: 'admin-001',
  empreinte:
      '77881aaa0000bbbb77881aaa0000bbbb77881aaa0000bbbb77881aaa0000bbbb',
);

/// L'artefact PDF **genere une seule fois a la publication**.
final DownloadAsset artefactPdfGenere = DownloadAsset(
  id: 'asset-pdf-2',
  resourceVersionId: 'ver-pdf-2',
  format: FormatArtefact.pdf,
  // Une CLE de Storage : aucun schema, aucune signature, aucune expiration.
  cleStockage: 'supports/res-pdf/ver-pdf-2.pdf',
  tailleOctets: 1_482_112,
  empreinte:
      'd41d8cd98f00b204e9800998ecf8427ed41d8cd98f00b204e9800998ecf8427e',
  origine: OrigineArtefact.genereALaPublication,
  creeLeUtc: publicationReference,
);

/// L'artefact d'un PDF **importe** : rien ne le regenere, jamais.
final DownloadAsset artefactPdfImporte = DownloadAsset(
  id: 'asset-import-1',
  resourceVersionId: 'ver-texte-1',
  format: FormatArtefact.pdf,
  cleStockage: 'supports/res-texte/original.pdf',
  tailleOctets: 903_311,
  origine: OrigineArtefact.importeTelQuel,
  creeLeUtc: publicationReference,
);

/// Une position de page dans le PDF.
const ContentPosition positionPdfPage12 = ContentPosition.page(
  resourceId: 'res-pdf',
  page: 12,
  resourceVersionId: 'ver-pdf-2',
);

/// La position d'un verset dans le Coran : ayat al-Kursi.
const ContentPosition positionAyatAlKursi = ContentPosition.ayah(
  resourceId: 'res-coran',
  sourate: 2,
  ayah: 255,
  resourceVersionId: 'ver-coran-1',
);

/// Une plage de travail : les trois derniers versets d'Al-Baqara.
final ContentRange plageFinBaqara = ContentRange(
  resourceId: 'res-coran',
  resourceVersionId: 'ver-coran-1',
  debut: const ContentPosition.ayah(
    resourceId: 'res-coran',
    sourate: 2,
    ayah: 284,
    resourceVersionId: 'ver-coran-1',
  ),
  fin: const ContentPosition.ayah(
    resourceId: 'res-coran',
    sourate: 2,
    ayah: 286,
    resourceVersionId: 'ver-coran-1',
  ),
);
