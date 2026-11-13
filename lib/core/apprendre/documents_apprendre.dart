/// ESPACE-APPRENDRE (lot 5) : l'adaptateur qui remplit la planche de documents
/// depuis le port du catalogue **existant**, et place le Coran en premier.
///
/// Ce que le catalogue sait dire aujourd'hui : un titre, un type parmi
/// Coran, texte, PDF, image, lecon, une version publiee ou non. Il ne dit ni
/// rayon, ni audio, ni video, ni lien externe, ni vignette, ni description : le
/// lot 3 (BIBLIOTHEQUE-UNE) les ajoute. D'ici la :
///
/// - tout document publie est un document **de l'academie** (rien n'est vendu,
///   la vente n'est pas ouverte), donc du premier rayon ; le second rayon reste
///   vide, honnetement ;
/// - tout type du catalogue est un « document » (le Coran, un PDF, une image,
///   une lecon) ;
/// - une ressource sans version publiee n'est pas listee : il n'y a rien a
///   ouvrir ;
/// - le Coran est une carte posee en tete, qui ouvre le lecteur existant
///   ([Routes.eleveCoran]) : un raccourci, jamais une copie du lecteur. Quand
///   le lot 3 inscrira le Coran au catalogue, sa fiche remplacera cette carte
///   (la ressource de type Coran du catalogue est ecartee ici pour qu'il n'y ait
///   jamais deux Corans).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../i18n/strings.g.dart';
import '../router/routes.dart';
import '../tc_bibliotheque/capacite_lecture_coran.dart';
import '../tc_bibliotheque/couverture_ressource.dart';
import '../tc_bibliotheque/donnees_catalogue.dart';
import '../tc_bibliotheque/library_resource.dart';
import 'document_planche.dart';

/// L'identifiant de la carte du Coran.
const String idDocumentCoran = 'coran';

/// Le parametre de l'adresse qui porte la classe d'ou l'eleve vient
/// (`/eleve/apprendre?groupe=<id>`), le meme que celui de l'ancienne liste
/// (`RoutesTcB.parametreGroupe`).
const String parametreGroupeApprendre = 'groupe';

/// L'adresse d'Apprendre, avec la classe d'ou l'eleve vient quand il y en a
/// une (valeur vide ou blanche : absence).
String cheminApprendre({String? groupe}) {
  final String? propre = groupe?.trim();
  return propre == null || propre.isEmpty
      ? Routes.eleveApprendre
      : Uri(
          path: Routes.eleveApprendre,
          queryParameters: <String, String>{parametreGroupeApprendre: propre},
        ).toString();
}

/// Le chemin de la fiche d'un document du catalogue, avec le retour vers
/// l'espace Apprendre (`?retour=`, que la fiche existante sait lire : son
/// disque retour ramene ici, jamais a l'ancienne liste). Ecrit ici pour ne pas
/// importer `features/` depuis le core ; le chemin doit rester egal a
/// `RoutesTcB.versRessource` (un test le verifie).
String cheminFicheDocument(String resourceId) => Uri(
  path: '${Routes.tcBibliotheque}/$resourceId',
  queryParameters: <String, String>{'retour': Routes.eleveApprendre},
).toString();

/// Les documents de l'espace Apprendre, tels que la planche les montre.
///
/// Une lecture du catalogue qui echoue echoue ici aussi : la planche dit
/// alors « indisponible » avec « Reessayer », elle ne montre pas un catalogue
/// vide a la place.
final FutureProvider<List<DocumentPlanche>> documentsApprendreProvider =
    FutureProvider<List<DocumentPlanche>>((Ref ref) async {
      final List<LibraryResource> ressources = await ref
          .watch(portCatalogueProvider)
          .tous();
      return documentsDepuisCatalogue(
        ressources,
        avecCoran: ref.watch(capaciteLectureCoranProvider),
      );
    }, retry: (int _, Object _) => null);

/// La carte « Coran », ecrite dans la langue COURANTE. Les textes se lisent a
/// l'appel : la planche la reecrit a chaque affichage, pour qu'un changement de
/// langue n'attende pas une relecture du catalogue.
DocumentPlanche documentCoran() {
  final String titre = t.apprendre.bibliotheque.coran.titre;
  return DocumentPlanche(
    id: idDocumentCoran,
    titre: titre,
    description: t.apprendre.bibliotheque.coran.edition,
    type: TypeDocumentPlanche.document,
    rayon: RayonPlanche.documentsDesCours,
    ouverture: const OuvrirDansLApplication(Routes.eleveCoran),
    couverture: CouvertureRessource.coran(titre),
  );
}

/// Les documents de la planche pour [ressources], le Coran en premier quand
/// [avecCoran]. Fonction pure, pour les tests.
List<DocumentPlanche> documentsDepuisCatalogue(
  List<LibraryResource> ressources, {
  required bool avecCoran,
}) {
  return <DocumentPlanche>[
    if (avecCoran) documentCoran(),
    for (final LibraryResource r in ressources)
      if (r.publiee && r.resourceType != TypeRessource.quran)
        _documentDe(r, RayonPlanche.documentsDesCours),
  ];
}

DocumentPlanche _documentDe(LibraryResource r, RayonPlanche rayon) =>
    DocumentPlanche(
      id: r.id,
      titre: r.title,
      type: TypeDocumentPlanche.document,
      rayon: rayon,
      ouverture: OuvrirDansLApplication(cheminFicheDocument(r.id)),
      couverture: CouvertureRessource.pour(r),
    );

/// Les documents epingles ou assignes a la classe [groupeId] (la rubrique
/// « Pour cette classe », celle de l'ancienne Bibliotheque que l'eleve ne
/// voit plus : meme donnee, `PortCatalogue.pourGroupe`).
///
/// **Le groupe vient de l'adresse** (`?groupe=`), donc d'une valeur que
/// n'importe qui peut ecrire : le serveur LEVE pour une classe qui n'est pas
/// celle de l'appelant (`ressources_du_groupe`). Cet echec est une absence
/// ici, comme dans `lireDonneesCatalogue` : la rubrique disparait, le reste
/// de la Bibliotheque ne tombe pas.
final FutureProviderFamily<List<DocumentPlanche>, String>
documentsDeLaClasseProvider =
    FutureProvider.family<List<DocumentPlanche>, String>((
      Ref ref,
      String groupeId,
    ) async {
      final List<LibraryResource> ressources = await ref
          .watch(portCatalogueProvider)
          .pourGroupe(groupeId)
          .onError<Object>(
            (Object _, StackTrace _) => const <LibraryResource>[],
          );
      return <DocumentPlanche>[
        for (final LibraryResource r in ressources)
          if (r.publiee && r.resourceType != TypeRessource.quran)
            _documentDe(r, RayonPlanche.pourCetteClasse),
      ];
    }, retry: (int _, Object _) => null);
