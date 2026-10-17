import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/router/routes.dart';

/// Ce que l'etape d'usage peut repondre.
///
/// L'eleve adulte n'est pas un role de plus : il est **son propre tuteur**, un
/// foyer d'une personne (ADR-009). « Moi uniquement » et « Moi et ma famille »
/// ecrivent donc le meme role en base ; l'enseignant passe par le lien discret.
enum UsageInscription {
  /// « Moi uniquement » : un eleve adulte, son propre tuteur.
  moi(AppRole.guardian),

  /// « Moi et ma famille » : un tuteur de foyer.
  famille(AppRole.guardian),

  /// « J'ai un code d'invitation » : le tunnel enseignant, meme ecran.
  enseignant(AppRole.teacher);

  const UsageInscription(this.role);

  /// Le role declare (borne par la base, jamais accorde par le client).
  final AppRole role;
}

/// Les etapes de l'inscription, dans l'ordre. « n sur N » se calcule ici.
const List<String> etapesInscription = <String>[
  Routes.inscriptionUsage,
  Routes.inscriptionIdentite,
  Routes.inscriptionGenre,
  Routes.inscriptionRecapitulatif,
];

/// Le rang (a partir de 1) d'une etape dans [etapesInscription].
int rangEtape(String route) => etapesInscription.indexOf(route) + 1;

/// Le parametre de requete qui ramene au recapitulatif apres « Modifier ».
const String parametreModifier = 'modifier';

/// Les reponses deja donnees, gardees d'une etape a l'autre.
///
/// Aucune preselection : tout commence a `null`.
class BrouillonInscription {
  /// Cree un brouillon.
  const BrouillonInscription({
    this.usage,
    this.prenom = '',
    this.nom = '',
    this.genre,
    this.profilCree = false,
    this.parentSuitDesCours,
  });

  /// L'usage retenu.
  final UsageInscription? usage;

  /// Le prenom saisi.
  final String prenom;

  /// Le nom saisi.
  final String nom;

  /// Le genre retenu.
  final Genre? genre;

  /// Reponse a « Suivez-vous aussi des cours ? » (« Moi et ma famille »,
  /// PAQ-DIR-EA) ; `null` tant que la question n'est pas repondue. Elle ne
  /// donne aucun droit : l'eleve autonome est une capacite servie (C-24).
  final bool? parentSuitDesCours;

  /// Vrai des que le serveur a cree le profil : une nouvelle tentative ne
  /// rappelle alors que le rafraichissement de session, jamais la creation.
  final bool profilCree;

  /// Vrai quand l'identite est remplie.
  bool get identiteRemplie => prenom.trim().isNotEmpty && nom.trim().isNotEmpty;

  /// La premiere etape encore sans reponse, ou le recapitulatif.
  String get premiereEtapeManquante {
    if (usage == null) {
      return Routes.inscriptionUsage;
    }
    if (!identiteRemplie) {
      return Routes.inscriptionIdentite;
    }
    if (genre == null) {
      return Routes.inscriptionGenre;
    }
    return Routes.inscriptionRecapitulatif;
  }

  /// Une copie modifiee.
  BrouillonInscription copier({
    UsageInscription? usage,
    String? prenom,
    String? nom,
    Genre? genre,
    bool? profilCree,
    bool? parentSuitDesCours,
  }) => BrouillonInscription(
    usage: usage ?? this.usage,
    prenom: prenom ?? this.prenom,
    nom: nom ?? this.nom,
    genre: genre ?? this.genre,
    profilCree: profilCree ?? this.profilCree,
    parentSuitDesCours: parentSuitDesCours ?? this.parentSuitDesCours,
  );
}

/// Tient le brouillon de l'inscription pour toute la duree du parcours.
class BrouillonInscriptionControleur extends Notifier<BrouillonInscription> {
  @override
  BrouillonInscription build() => const BrouillonInscription();

  /// Retient l'usage.
  void choisirUsage(UsageInscription usage) =>
      state = state.copier(usage: usage);

  /// Retient si le parent suit aussi des cours.
  void choisirParentSuitDesCours({required bool suit}) =>
      state = state.copier(parentSuitDesCours: suit);

  /// Retient l'identite.
  void saisirIdentite({required String prenom, required String nom}) =>
      state = state.copier(prenom: prenom.trim(), nom: nom.trim());

  /// Retient le genre.
  void choisirGenre(Genre genre) => state = state.copier(genre: genre);

  /// Note que le profil existe cote serveur.
  void noterProfilCree() => state = state.copier(profilCree: true);
}

/// Le brouillon partage par les quatre etapes.
final NotifierProvider<BrouillonInscriptionControleur, BrouillonInscription>
brouillonInscriptionProvider =
    NotifierProvider<BrouillonInscriptionControleur, BrouillonInscription>(
      BrouillonInscriptionControleur.new,
    );
