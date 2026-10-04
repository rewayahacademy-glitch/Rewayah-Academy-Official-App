// PT-B-CORAN-ADULTE : l'onglet Coran de l'eleve adulte en demonstration
// (`/demo/adulte?ecran=coran`) ouvre la VRAIE page Coran de l'eleve
// (`MushafPage`, celle de `/eleve/coran`), sans aucun appel serveur (K-28).
//
// Le corpus est celui de la base, recopie mot pour mot de la migration 0013
// (`service_coran_demo.dart`) et charge en DIFFERE : son texte ne pese sur
// aucun autre ecran. Au-dessus de ce service, tout est le code reel :
// l'adaptateur `CorpusDepuisServiceCoran`, la navigation `NavigationCoran`
// (sans profil : aucune position lue ni ecrite), le lecteur et ses trois
// rendus, avec leurs etats (attente, lecture, echec « Reessayer »). Le rendu
// du Coran n'est pas touche.
//
// Deux portees, une seule source :
// - la page vit dans un conteneur ISOLE (`CoranDemoAdulte`) : aucun
//   fournisseur du lecteur ne remonte au service serveur de la racine ;
// - la feuille « Aller a » s'ouvre au-dessus de toute la coquille (dialogue
//   du navigateur racine sur grand ecran) et lit donc la portee RACINE. Au
//   demarrage sur `/demo/adulte` (hors production), `main.dart` y pose
//   `surchargesRacineDemoAdulte` : la recherche lit le meme corpus de
//   demonstration, les positions restent celles de la session reelle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/coran/service_coran.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_coran/corpus_service_coran.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/port_corpus_coran.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../tc_mushaf/mushaf_page.dart';
import 'mode_demonstration.dart' show environnementAutoriseDemo;
import 'service_coran_demo.dart' deferred as corpus_demo;

/// Charge le corpus de la demonstration (bibliotheque differee).
Future<ServiceCoran> chargerServiceCoranDemo() async {
  await corpus_demo.loadLibrary();
  return corpus_demo.creerServiceCoranDemo();
}

/// Le `ServiceCoran` de la demonstration, qui charge son corpus differe a la
/// premiere lecture.
///
/// Il tient le contrat de `ServiceCoran` : un chargement qui echoue rend
/// `null` (« je ne sais pas »), exactement comme une lecture serveur en
/// echec ; le lecteur affiche alors son etat d'echec, et son « Reessayer »
/// relance le chargement.
class ServiceCoranDemoDiffere implements ServiceCoran {
  /// Cree le service. [charger] remplace le chargement differe (tests de
  /// l'attente et de l'echec).
  ServiceCoranDemoDiffere({Future<ServiceCoran> Function()? charger})
    : _charger = charger ?? chargerServiceCoranDemo;

  final Future<ServiceCoran> Function() _charger;
  Future<ServiceCoran>? _chargement;

  Future<ServiceCoran?> _service() async {
    try {
      return await (_chargement ??= _charger());
    } on Object {
      // Le prochain appel retente le chargement.
      _chargement = null;
      return null;
    }
  }

  @override
  Future<String?> editionCourante() async =>
      (await _service())?.editionCourante();

  @override
  Future<List<Sourate>?> sourates() async => (await _service())?.sourates();

  @override
  Future<PageCoran?> page(int numero) async => (await _service())?.page(numero);

  @override
  Future<int?> pageDe(int sourate, int verset) async =>
      (await _service())?.pageDe(sourate, verset);

  /// Aucun profil en demonstration : aucune position.
  @override
  Future<PositionLecture?> position(String profilId) async => null;

  /// Aucun profil en demonstration : rien n'est enregistre.
  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => false;

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async =>
      (await _service())?.debutDeJuz(juz);

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => (await _service())?.rechercher(requete, limite: limite);
}

/// Les surcharges du Coran de la page de demonstration : le service de
/// demonstration, et la navigation reelle sans profil.
List<Override> surchargesCoranDemoAdulte(ServiceCoran service) => <Override>[
  serviceCoranProvider.overrideWithValue(service),
  portNavigationCoranProvider.overrideWith(
    (Ref ref) => NavigationCoran(
      corpus: ref.watch(portCorpusCoranProvider),
      service: service,
      profilCourant: () => null,
    ),
  ),
];

/// Vrai si l'adresse d'ouverture est la demonstration de l'eleve adulte,
/// en chemin (`/demo/adulte`) ou en fragment (`#/demo/adulte`).
bool demoAdulteDemandee(Uri adresse) {
  bool vise(String c) =>
      c == Routes.demoAdulte || c.startsWith('${Routes.demoAdulte}/');
  final String fragment = adresse.fragment;
  final String cheminFragment = fragment.isEmpty
      ? ''
      : Uri.parse(fragment).path;
  return vise(adresse.path) || vise(cheminFragment);
}

/// Les surcharges de la portee RACINE au demarrage sur `/demo/adulte`, hors
/// production ; vide partout ailleurs.
///
/// Elles ne remplacent que la recherche de la feuille « Aller a » (seule
/// lecture qui quitte la page isolee) : `rechercheRapide` et `pageDe` lisent
/// le corpus de demonstration, identique a celui de la base. Les positions
/// restent celles de la navigation reelle, construite a la demande.
List<Override> surchargesRacineDemoAdulte({
  required Uri adresse,
  required String environnement,
}) {
  if (!environnementAutoriseDemo(environnement) ||
      !demoAdulteDemandee(adresse)) {
    return const <Override>[];
  }
  final ServiceCoran service = ServiceCoranDemoDiffere();
  return <Override>[
    portNavigationCoranProvider.overrideWith(
      (Ref ref) => _RechercheDemo(
        demo: NavigationCoran(
          corpus: CorpusDepuisServiceCoran(service),
          service: service,
          profilCourant: () => null,
        ),
        // La navigation reelle, telle que `navigation_coran.dart` la
        // construit, seulement si une position est demandee.
        reelle: () => NavigationCoran(
          corpus: ref.read(portCorpusCoranProvider),
          service: ref.read(serviceCoranProvider),
          profilCourant: () => ref.read(sessionProvider).profileId,
          etatPartage: ref.read(portEtatPartageCoranProvider),
        ),
      ),
    ),
  ];
}

/// La recherche sur le corpus de demonstration, les positions sur la
/// navigation reelle.
class _RechercheDemo implements PortNavigationCoran {
  _RechercheDemo({required this.demo, required this.reelle});

  final PortNavigationCoran demo;
  final PortNavigationCoran Function() reelle;

  @override
  Future<int?> pageDe(CibleCoran cible) => demo.pageDe(cible);

  @override
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete) =>
      demo.rechercheRapide(requete);

  @override
  Future<PositionLecture?> dernierePositionPersonnelle() =>
      reelle().dernierePositionPersonnelle();

  @override
  Future<bool> memoriserPositionPersonnelle(
    PositionLecture position, {
    required OrigineNavigation origine,
  }) => reelle().memoriserPositionPersonnelle(position, origine: origine);

  @override
  Future<PositionLecture?> positionDeGroupe(String sessionId) =>
      reelle().positionDeGroupe(sessionId);
}

/// La page Coran de l'eleve adulte en demonstration : la vraie [MushafPage],
/// dans un conteneur isole, sur le corpus de demonstration.
class CoranDemoAdulte extends StatefulWidget {
  /// Cree la page. [charger] remplace le chargement differe du corpus (tests
  /// de l'attente et de l'echec) ; nul : [chargerServiceCoranDemo].
  const CoranDemoAdulte({super.key, this.charger});

  /// Le chargement du corpus ; nul : [chargerServiceCoranDemo].
  final Future<ServiceCoran> Function()? charger;

  @override
  State<CoranDemoAdulte> createState() => _CoranDemoAdulteEtat();
}

class _CoranDemoAdulteEtat extends State<CoranDemoAdulte> {
  late final ProviderContainer _coran = ProviderContainer(
    overrides: surchargesCoranDemoAdulte(
      ServiceCoranDemoDiffere(charger: widget.charger),
    ),
  );

  @override
  void dispose() {
    _coran.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: _coran, child: const MushafPage());
}
