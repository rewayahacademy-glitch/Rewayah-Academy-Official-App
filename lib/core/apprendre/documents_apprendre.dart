/// ESPACE-APPRENDRE (lot 5) : l'adaptateur qui remplit la planche de documents
/// depuis le port du catalogue **existant**, et place le Coran en premier.
///
/// Ce que le catalogue dit (lot 3, BIBLIOTHEQUE-UNE, en production) : un
/// titre, un type (Coran, texte, PDF, image, lecon, audio, video, lien
/// externe), une description, une vignette deposee ou non, une version
/// publiee ou non. L'adaptateur en tire :
///
/// - le **type** de la planche (audio, video, lien externe, sinon document) et
///   la **description** telle que la direction l'a ecrite (jamais inventee) ;
/// - le **rayon** est celui que le serveur donne a la ressource (`cours` ou
///   `plus_loin`), dans l'ordre de la direction ; rien n'est vendu, le second
///   rayon est une place, vide tant que rien n'y est range ;
/// - un lien externe s'ouvre par **sa fiche** (la liste du serveur ne porte pas
///   l'adresse, la fiche la relit et demande la confirmation avant de quitter
///   l'application : le chemin de la Bibliotheque une, un seul) ;
/// - une ressource sans version publiee n'est pas listee : il n'y a rien a
///   ouvrir ;
/// - le Coran est une carte posee en tete, qui ouvre le lecteur existant
///   ([Routes.eleveCoran]) : un raccourci, jamais une copie du lecteur. Quand
///   le lot 3 inscrira le Coran au catalogue, sa fiche remplacera cette carte
///   (la ressource de type Coran du catalogue est ecartee ici pour qu'il n'y ait
///   jamais deux Corans).
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../i18n/strings.g.dart';
import '../router/routes.dart';
import '../tc_bibliotheque/capacite_lecture_coran.dart';
import '../tc_bibliotheque/couverture_ressource.dart';
import '../tc_bibliotheque/donnees_catalogue.dart';
import '../tc_bibliotheque/library_resource.dart';
import '../tc_bibliotheque/port_catalogue.dart'
    show EchecCatalogue, ReprisLecture;
import '../tc_telechargement/port_etat_offline.dart'
    show EtatOffline, PortEtatOffline;
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
  path: '${Routes.tcBibliotheque}/${Uri.encodeComponent(resourceId)}',
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
    // Dans l'ordre que la direction a donne (`ordre`, croissant ; a `ordre`
    // egal, l'ordre de lecture est garde : voir [_parOrdre]).
    for (final LibraryResource r in _parOrdre(ressources))
      if (r.publiee && r.resourceType != TypeRessource.quran)
        _documentDe(r, RayonPlanche.documentsDesCours),
  ];
}

/// Les ressources par `ordre` croissant, **stable** : a `ordre` egal elles
/// gardent l'ordre ou le serveur les a rendues. `List.sort` de Dart n'est pas
/// stable (au-dela d'une trentaine d'elements), le rang d'origine departage
/// donc explicitement.
List<LibraryResource> _parOrdre(List<LibraryResource> ressources) {
  final List<(int, LibraryResource)> rangees =
      <(int, LibraryResource)>[
        for (int i = 0; i < ressources.length; i++) (i, ressources[i]),
      ]..sort(((int, LibraryResource) a, (int, LibraryResource) b) {
        final int ordre = a.$2.ordre.compareTo(b.$2.ordre);
        return ordre != 0 ? ordre : a.$1.compareTo(b.$1);
      });
  return <LibraryResource>[
    for (final (int, LibraryResource) r in rangees) r.$2,
  ];
}

/// Le rayon de la planche pour le code du rayon du serveur (`rayon` de la
/// ressource : `cours` ou `plus_loin`).
RayonPlanche _rayonDe(String code) => code == codeRayonPlusLoin
    ? RayonPlanche.pourAllerPlusLoin
    : RayonPlanche.documentsDesCours;

DocumentPlanche _documentDe(LibraryResource r, RayonPlanche rayon) =>
    DocumentPlanche(
      id: r.id,
      titre: r.title,
      description: r.description,
      type: switch (r.resourceType) {
        TypeRessource.audio => TypeDocumentPlanche.audio,
        TypeRessource.video => TypeDocumentPlanche.video,
        TypeRessource.lienExterne => TypeDocumentPlanche.lienExterne,
        _ => TypeDocumentPlanche.document,
      },
      rayon: rayon == RayonPlanche.documentsDesCours
          ? _rayonDe(r.rayon)
          : rayon,
      ouverture: OuvrirDansLApplication(cheminFicheDocument(r.id)),
      couverture: CouvertureRessource.pour(r),
      aVignetteDeposee: r.aVignette,
    );

/// Les raisons d'un refus d'AUTORISATION du serveur (42501) : celle que rend
/// l'adaptateur Supabase (`non autorise`) et celle du double de test
/// (`insufficient_privilege`).
const Set<String> raisonsRefusClasse = <String>{
  'non autorise',
  'insufficient_privilege',
};

/// Les documents epingles ou assignes a la classe [groupeId] (la rubrique
/// « Pour cette classe », celle de l'ancienne Bibliotheque que l'eleve ne
/// voit plus : meme donnee, `PortCatalogue.pourGroupe`).
///
/// **Deux cas, deux etats** (contre-lecture de l'architecte, 13/11) :
///
/// - le serveur REFUSE (42501, `ressources_du_groupe` leve pour une classe qui
///   n'est pas celle de l'appelant : le groupe vient de l'adresse, donc
///   falsifiable) : la rubrique **n'existe pas**, sans phrase ni « Reessayer »
///   (rien a reessayer, rien a dire d'une classe qui n'est pas la sienne) ;
/// - une PANNE (reseau, serveur) echoue ici aussi : elle ne se confond pas avec
///   « aucun document », la rubrique dit qu'elle ne s'affiche pas, avec
///   « Reessayer ».
///
/// Dans les deux cas le reste de la Bibliotheque est lu a part
/// ([documentsApprendreProvider]) et ne tombe jamais avec elle.
final FutureProviderFamily<List<DocumentPlanche>, String>
documentsDeLaClasseProvider =
    FutureProvider.family<List<DocumentPlanche>, String>((
      Ref ref,
      String groupeId,
    ) async {
      final List<LibraryResource> ressources = await ref
          .watch(portCatalogueProvider)
          .pourGroupe(groupeId)
          .onError<EchecCatalogue>(
            (EchecCatalogue e, StackTrace trace) =>
                raisonsRefusClasse.contains(e.raison)
                ? const <LibraryResource>[]
                : Error.throwWithStackTrace(e, trace),
          );
      return <DocumentPlanche>[
        for (final LibraryResource r in ressources)
          if (r.publiee && r.resourceType != TypeRessource.quran)
            _documentDe(r, RayonPlanche.pourCetteClasse),
      ];
    }, retry: (int _, Object _) => null);

/// Les rayons du catalogue, avec leurs intitules en francais et en arabe
/// (`PortCatalogue.rayons()`, donnee du serveur : aucun ecran n'en code le
/// nom). Une lecture qui echoue rend rien : la planche garde alors ses
/// intitules ecrits (les memes mots), jamais un trou.
final FutureProvider<List<RayonBibliotheque>> rayonsApprendreProvider =
    FutureProvider<List<RayonBibliotheque>>(
      (Ref ref) async => ref
          .watch(portCatalogueProvider)
          .rayons()
          .onError<Object>(
            (Object _, StackTrace _) => const <RayonBibliotheque>[],
          ),
      retry: (int _, Object _) => null,
    );

/// « Continuer » : le dernier document ouvert, avec son etat hors ligne (le
/// port du lot 3, `PortCatalogue.derniereLecture` et `PortEtatOffline`).
@immutable
class RepriseApprendre {
  /// Cree la reprise.
  const RepriseApprendre({required this.reprise, required this.etat});

  /// La ressource a reprendre et sa position.
  final ReprisLecture reprise;

  /// Son etat hors ligne.
  final EtatOffline etat;
}

/// La reprise, ou `null` : rien a reprendre, ou une lecture qui echoue (la
/// reprise est un confort, jamais une condition : la Bibliotheque s'affiche
/// sans elle).
final FutureProvider<RepriseApprendre?> repriseApprendreProvider =
    FutureProvider<RepriseApprendre?>((Ref ref) async {
      try {
        final ReprisLecture? reprise = await ref
            .watch(portCatalogueProvider)
            .derniereLecture();
        if (reprise == null) return null;
        final EtatOffline etat = await ref
            .watch(portEtatOfflineProvider)
            .etatDe(reprise.ressource.id);
        return RepriseApprendre(reprise: reprise, etat: etat);
      } on Object {
        return null;
      }
    }, retry: (int _, Object _) => null);

/// L'etat hors ligne des documents du catalogue : un mot par document que la
/// personne a garde sur l'appareil. Une lecture qui echoue ne rend rien.
final FutureProvider<Map<String, EtatOffline>> etatsHorsLigneApprendreProvider =
    FutureProvider<Map<String, EtatOffline>>((Ref ref) async {
      final List<DocumentPlanche> documents = await ref.watch(
        documentsApprendreProvider.future,
      );
      final PortEtatOffline offline = ref.watch(portEtatOfflineProvider);
      final Map<String, EtatOffline> etats = <String, EtatOffline>{};
      for (final DocumentPlanche d in documents) {
        if (d.id == idDocumentCoran) continue;
        try {
          etats[d.id] = await offline.etatDe(d.id);
        } on Object {
          continue;
        }
      }
      return etats;
    }, retry: (int _, Object _) => null);
