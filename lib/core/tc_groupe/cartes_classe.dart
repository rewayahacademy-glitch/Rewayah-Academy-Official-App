// CARTES-PERSO-1 : les cartes de la Classe, que l'enseignant compose et que
// le tuteur, l'eleve enfant et l'eleve adulte lisent (decision du 05/10,
// deleguee par le directeur ; fiche CLS-CARTES, `docs/current/DASH_STRATEGIE.md`
// annexe A).
//
// Ce fichier ne porte que le modele, sa validation et le port. **Aucune
// source serveur a ce jour** : le port de production rend
// `CapaciteIndisponible('CARTES-BR-01')` (table `class_cards`, RLS, RPC de
// lecture ordonnee et d'ecriture, journal d'audit : besoin consigne, a
// construire a BR-1). La demonstration le surcharge.
//
// **Le droit d'ecrire est une capacite rendue par le serveur**
// ([CartesClasseVM.peutModifier]), jamais deduite d'un role cote client : la
// barriere reste la RLS (ecriture reservee a l'enseignant de la Classe).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';

/// Le modele d'une carte (K-57 : un modele preremplit ce qui se deduit).
enum TypeCarteClasse {
  /// Une information pour la Classe.
  annonce,

  /// Un travail a preparer, avec son echeance.
  devoir,

  /// Un lien utile (support, enregistrement, page a lire).
  lien,

  /// Un rappel date (sortie, examen, changement d'horaire).
  rappel,
}

/// Les bornes que le serveur verifiera aussi (RPC d'ecriture, BR-1) : le
/// client les applique avant l'envoi pour dire tout de suite ce qui depasse.
abstract final class BornesCarteClasse {
  /// Le titre, en caracteres.
  static const int titreMax = 60;

  /// Le texte, en caracteres : une carte se lit d'un coup d'oeil.
  static const int texteMax = 280;

  /// Le lien, en caracteres.
  static const int lienMax = 500;

  /// Le nombre de cartes d'une Classe : au-dela, l'espace redevient une
  /// liste de taches (meme regle que les trois actions R17).
  static const int cartesMax = 6;
}

/// Une carte de la Classe, telle que la lecture ordonnee la rend.
@immutable
class CarteClasse {
  /// Cree une carte.
  const CarteClasse({
    required this.id,
    required this.position,
    required this.type,
    required this.titre,
    this.texte,
    this.lien,
    this.echeance,
  });

  /// L'identifiant stable de la carte.
  final String id;

  /// La place de la carte dans la Classe, de 0 a [BornesCarteClasse.cartesMax].
  final int position;

  /// Le modele de la carte.
  final TypeCarteClasse type;

  /// Le titre, non vide.
  final String titre;

  /// Le texte, `null` quand la carte n'en porte pas.
  final String? texte;

  /// Le lien `https`, `null` quand la carte n'en porte pas.
  final String? lien;

  /// L'echeance, une date sans heure (annee, mois, jour), `null` sans
  /// echeance.
  final DateTime? echeance;

  /// Le brouillon qui reprend cette carte, pour la modifier.
  BrouillonCarte versBrouillon() => BrouillonCarte(
    type: type,
    titre: titre,
    texte: texte ?? '',
    lien: lien ?? '',
    echeance: echeance,
  );
}

/// Les cartes d'une Classe et ce que la personne qui regarde peut en faire.
@immutable
class CartesClasseVM {
  /// Cree la lecture.
  const CartesClasseVM({required this.cartes, this.peutModifier = false});

  /// Les cartes, dans l'ordre de la Classe ([trierCartes]).
  final List<CarteClasse> cartes;

  /// La capacite rendue par le serveur : vrai pour l'enseignant de la
  /// Classe. Un widget lit cette capacite, jamais un role.
  final bool peutModifier;

  /// Vrai quand une carte peut encore etre ajoutee.
  bool get peutAjouter =>
      peutModifier && cartes.length < BornesCarteClasse.cartesMax;
}

/// L'ordre de lecture : la position, puis l'identifiant pour departager deux
/// positions egales (une lecture reste stable d'un rendu a l'autre).
List<CarteClasse> trierCartes(Iterable<CarteClasse> cartes) =>
    List<CarteClasse>.of(cartes)..sort((CarteClasse a, CarteClasse b) {
      final int parPosition = a.position.compareTo(b.position);
      return parPosition != 0 ? parPosition : a.id.compareTo(b.id);
    });

/// Ce que l'enseignant saisit, avant l'envoi.
@immutable
class BrouillonCarte {
  /// Cree un brouillon.
  const BrouillonCarte({
    required this.type,
    this.titre = '',
    this.texte = '',
    this.lien = '',
    this.echeance,
  });

  /// Le modele choisi.
  final TypeCarteClasse type;

  /// Le titre saisi.
  final String titre;

  /// Le texte saisi.
  final String texte;

  /// Le lien saisi.
  final String lien;

  /// L'echeance choisie.
  final DateTime? echeance;

  /// Le brouillon prerempli d'un modele (K-57 : deduit > choisi > saisi).
  /// [titre] vient des libelles (le titre propose du modele) ;
  /// [prochaineSeance] est la date de la prochaine seance de la Classe,
  /// deduite, qui devient l'echeance d'un devoir ou d'un rappel.
  factory BrouillonCarte.modele(
    TypeCarteClasse type, {
    required String titre,
    DateTime? prochaineSeance,
  }) => BrouillonCarte(
    type: type,
    titre: titre,
    echeance: switch (type) {
      TypeCarteClasse.devoir || TypeCarteClasse.rappel =>
        prochaineSeance == null ? null : dateSeule(prochaineSeance),
      TypeCarteClasse.annonce || TypeCarteClasse.lien => null,
    },
  );

  /// Le meme brouillon, un champ change.
  BrouillonCarte copie({
    TypeCarteClasse? type,
    String? titre,
    String? texte,
    String? lien,
    DateTime? echeance,
    bool sansEcheance = false,
  }) => BrouillonCarte(
    type: type ?? this.type,
    titre: titre ?? this.titre,
    texte: texte ?? this.texte,
    lien: lien ?? this.lien,
    echeance: sansEcheance ? null : echeance ?? this.echeance,
  );
}

/// Ce qui empeche d'enregistrer un brouillon.
enum DefautCarte {
  /// Le titre est vide.
  titreVide,

  /// Le titre depasse [BornesCarteClasse.titreMax].
  titreLong,

  /// Le texte depasse [BornesCarteClasse.texteMax].
  texteLong,

  /// Le lien n'est pas une adresse `https` complete, ou il est trop long.
  lienInvalide,

  /// Un devoir sans echeance.
  echeanceManquante,
}

/// Une date sans heure.
DateTime dateSeule(DateTime instant) =>
    DateTime(instant.year, instant.month, instant.day);

/// Vrai pour une adresse `https` complete (un hote, pas d'espace).
bool lienValide(String lien) {
  if (lien.length > BornesCarteClasse.lienMax || lien.contains(' ')) {
    return false;
  }
  final Uri? uri = Uri.tryParse(lien);
  return uri != null && uri.scheme == 'https' && uri.host.contains('.');
}

/// Les defauts d'un brouillon, vides quand il peut etre envoye. Les longueurs
/// se comptent apres retrait des espaces de bord.
Set<DefautCarte> defautsCarte(BrouillonCarte brouillon) {
  final String titre = brouillon.titre.trim();
  final String texte = brouillon.texte.trim();
  final String lien = brouillon.lien.trim();
  return <DefautCarte>{
    if (titre.isEmpty) DefautCarte.titreVide,
    if (titre.length > BornesCarteClasse.titreMax) DefautCarte.titreLong,
    if (texte.length > BornesCarteClasse.texteMax) DefautCarte.texteLong,
    if (lien.isNotEmpty && !lienValide(lien)) DefautCarte.lienInvalide,
    if (brouillon.type == TypeCarteClasse.devoir && brouillon.echeance == null)
      DefautCarte.echeanceManquante,
  };
}

/// Le port des cartes d'une Classe.
abstract interface class PortCartesClasse {
  /// Les cartes de la Classe [groupeId], dans l'ordre, et la capacite de
  /// les modifier.
  Future<CartesClasseVM> lire(String groupeId);

  /// Enregistre [brouillon] : une nouvelle carte quand [carteId] est nul,
  /// sinon la carte [carteId]. Rend la carte telle que le serveur la garde.
  Future<CarteClasse> enregistrer(
    String groupeId,
    BrouillonCarte brouillon, {
    String? carteId,
  });

  /// Retire la carte [carteId] de la Classe (suppression douce cote
  /// serveur, `supprime_le`).
  Future<void> retirer(String groupeId, String carteId);
}

/// Le port de production : **aucune source serveur a ce jour**. Il ne rend
/// aucun faux contenu ; l'ecran dit que les cartes ne sont pas encore
/// ouvertes.
class PortCartesClasseIndisponible implements PortCartesClasse {
  /// Cree le port.
  const PortCartesClasseIndisponible();

  /// Le besoin serveur consigne (fiche CLS-CARTES, registre CARTES-BR).
  static const String dependance = 'CARTES-BR-01';

  @override
  Future<CartesClasseVM> lire(String groupeId) =>
      Future<CartesClasseVM>.error(const CapaciteIndisponible(dependance));

  @override
  Future<CarteClasse> enregistrer(
    String groupeId,
    BrouillonCarte brouillon, {
    String? carteId,
  }) => Future<CarteClasse>.error(const CapaciteIndisponible(dependance));

  @override
  Future<void> retirer(String groupeId, String carteId) =>
      Future<void>.error(const CapaciteIndisponible(dependance));
}

/// Le port des cartes. La demonstration le surcharge.
final Provider<PortCartesClasse> portCartesClasseProvider =
    Provider<PortCartesClasse>((Ref _) => const PortCartesClasseIndisponible());

/// Les cartes d'une Classe, lues par le port. Sous un `ProviderScope`
/// imbrique, la demonstration surcharge aussi cette famille : elle se
/// resoudrait sinon dans le conteneur racine, ou le port est indisponible.
final FutureProviderFamily<CartesClasseVM, String> cartesClasseProvider =
    FutureProvider.family<CartesClasseVM, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portCartesClasseProvider).lire(groupeId),
    );
