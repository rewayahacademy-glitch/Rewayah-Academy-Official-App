// CARTES-PERSO-1 : les cartes de la Classe en demonstration. Donnees fictives,
// aucun appel serveur ; les modifications vivent le temps de la page.

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/tc_groupe/cartes_classe.dart';

/// Le port de demonstration : une Classe en memoire.
class PortCartesClasseDemo implements PortCartesClasse {
  /// Cree le port. [peutModifier] est la capacite que le serveur rendrait :
  /// vraie pour l'enseignant de la Classe, fausse pour les autres.
  PortCartesClasseDemo({required this.peutModifier, List<CarteClasse>? cartes})
    : _cartes = <CarteClasse>[...?cartes];

  /// La capacite rendue a la lecture.
  final bool peutModifier;

  final List<CarteClasse> _cartes;
  int _suivant = 0;

  @override
  Future<CartesClasseVM> lire(String groupeId) async =>
      CartesClasseVM(cartes: trierCartes(_cartes), peutModifier: peutModifier);

  @override
  Future<CarteClasse> enregistrer(
    String groupeId,
    BrouillonCarte brouillon, {
    String? carteId,
  }) async {
    // La barriere est cote serveur (RLS) : la demonstration la rejoue.
    if (!peutModifier) {
      throw StateError('ecriture refusee');
    }
    final int index = carteId == null
        ? -1
        : _cartes.indexWhere((CarteClasse c) => c.id == carteId);
    final String texte = brouillon.texte.trim();
    final String lien = brouillon.lien.trim();
    final CarteClasse carte = CarteClasse(
      id: index >= 0 ? carteId! : 'demo-carte-nouvelle-${_suivant++}',
      position: index >= 0
          ? _cartes[index].position
          : _cartes.fold<int>(
                  -1,
                  (int m, CarteClasse c) => c.position > m ? c.position : m,
                ) +
                1,
      type: brouillon.type,
      titre: brouillon.titre.trim(),
      texte: texte.isEmpty ? null : texte,
      lien: lien.isEmpty ? null : lien,
      echeance: brouillon.echeance,
    );
    if (index >= 0) {
      _cartes[index] = carte;
    } else {
      _cartes.add(carte);
    }
    return carte;
  }

  @override
  Future<void> retirer(String groupeId, String carteId) async {
    if (!peutModifier) {
      throw StateError('ecriture refusee');
    }
    _cartes.removeWhere((CarteClasse c) => c.id == carteId);
  }
}

/// Les cartes de la Classe de demonstration, datees depuis [aujourdhui].
List<CarteClasse> cartesClasseDemo(DateTime aujourdhui) {
  final DateTime jour = dateSeule(aujourdhui);
  return <CarteClasse>[
    CarteClasse(
      id: 'demo-carte-devoir',
      position: 0,
      type: TypeCarteClasse.devoir,
      titre: 'Réviser la sourate Al-Fil',
      texte: 'Lire la sourate trois fois à voix haute, en suivant le doigt.',
      echeance: jour.add(const Duration(days: 4)),
    ),
    const CarteClasse(
      id: 'demo-carte-lien',
      position: 1,
      type: TypeCarteClasse.lien,
      titre: 'Récitation modèle',
      texte: "L'enregistrement de la séance de lundi.",
      lien: 'https://rewayah.academy/demo/recitation',
    ),
    CarteClasse(
      id: 'demo-carte-rappel',
      position: 2,
      type: TypeCarteClasse.rappel,
      titre: 'Pas de séance pendant les vacances',
      echeance: jour.add(const Duration(days: 18)),
    ),
  ];
}

/// Les surcharges des cartes d'une Classe de demonstration. Le port est cree
/// une fois par conteneur : une carte modifiee le reste tant que la page
/// vit. La famille est surchargee elle aussi : sous un `ProviderScope`
/// imbrique, elle se resoudrait sinon dans le conteneur racine.
List<Override> surchargesCartesClasseDemo(
  String groupeId, {
  required bool peutModifier,
}) => <Override>[
  portCartesClasseProvider.overrideWith(
    (Ref _) => PortCartesClasseDemo(
      peutModifier: peutModifier,
      cartes: cartesClasseDemo(DateTime.now()),
    ),
  ),
  cartesClasseProvider(groupeId).overrideWith(
    (Ref ref) => ref.watch(portCartesClasseProvider).lire(groupeId),
  ),
];
