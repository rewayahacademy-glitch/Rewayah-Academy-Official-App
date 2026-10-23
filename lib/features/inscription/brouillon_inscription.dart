import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/indicatifs_telephoniques.dart';
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
  enseignant(AppRole.teacher),

  /// « J'ai un code de comptable » (lot F2) : le tunnel comptable, sur
  /// invitation de la direction (BF1-03).
  comptable(AppRole.accountant);

  const UsageInscription(this.role);

  /// Le role declare (borne par la base, jamais accorde par le client).
  final AppRole role;
}

/// Les etapes de l'inscription du tuteur, de l'eleve adulte et du comptable,
/// dans l'ordre. « n sur N » se calcule ici. Ces trois usages gardent
/// exactement ce parcours.
const List<String> etapesInscription = <String>[
  Routes.inscriptionUsage,
  Routes.inscriptionIdentite,
  Routes.inscriptionGenre,
  Routes.inscriptionRecapitulatif,
];

/// Les etapes du candidat enseignant (CAND-04), avec ou sans code
/// d'invitation : le telephone s'y ajoute avant le recapitulatif, ou se
/// choisissent aussi la langue et l'accord de confidentialite.
const List<String> etapesCandidat = <String>[
  Routes.inscriptionUsage,
  Routes.inscriptionIdentite,
  Routes.inscriptionGenre,
  Routes.inscriptionTelephone,
  Routes.inscriptionRecapitulatif,
];

/// Les etapes de l'inscription pour [usage] : celles du candidat enseignant,
/// ou celles des autres usages tant qu'il n'est pas retenu.
List<String> etapesPour(UsageInscription? usage) =>
    usage == UsageInscription.enseignant ? etapesCandidat : etapesInscription;

/// Le rang (a partir de 1) d'une etape dans [etapesPour] ; 0 quand l'usage
/// retenu n'a pas cette etape (le telephone d'un tuteur).
int rangEtape(String route, [UsageInscription? usage]) =>
    etapesPour(usage).indexOf(route) + 1;

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
    this.paysTelephone,
    this.numeroTelephone = '',
    this.sansCode = false,
    this.confidentialiteAcceptee = false,
    this.inscriptionEnvoyee = false,
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

  /// Le pays (code ISO) dont la personne a choisi l'indicatif telephonique
  /// (candidat enseignant, CAND-04) ; `null` tant qu'elle n'a pas choisi.
  final String? paysTelephone;

  /// Le numero saisi, **sans l'indicatif**, tel que la personne l'a ecrit.
  final String numeroTelephone;

  /// Vrai quand la personne a choisi « Deposer ma candidature » : le lien
  /// public, sans code d'invitation. Faux quand elle passe par un code.
  final bool sansCode;

  /// Vrai quand la case de la politique de confidentialite est cochee. Jamais
  /// precochee, et gardee ici pour survivre a la lecture de la politique.
  final bool confidentialiteAcceptee;

  /// Vrai des que le serveur a repondu « acceptee » a l'inscription du
  /// candidat. **Cela ne dit pas que le compte existe** : au-dela du plafond
  /// horaire, la reponse est la meme sans rien creer (CAND-F03). Seule la
  /// relecture du profil le dit.
  final bool inscriptionEnvoyee;

  /// Vrai quand l'identite est remplie.
  bool get identiteRemplie => prenom.trim().isNotEmpty && nom.trim().isNotEmpty;

  /// L'indicatif (sans « + ») du pays choisi, ou `null`.
  String? get indicatif => indicatifDuPays(paysTelephone);

  /// Le numero international (`+` indicatif et numero), ou `null` tant que le
  /// pays n'est pas choisi ou que le numero ne se lit pas.
  String? get telephone {
    final String? code = indicatif;
    if (code == null) {
      return null;
    }
    return telephoneInternational(indicatif: code, saisie: numeroTelephone);
  }

  /// Vrai quand le candidat a donne un telephone exploitable.
  bool get telephoneRempli => telephone != null;

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
    if (usage == UsageInscription.enseignant && !telephoneRempli) {
      return Routes.inscriptionTelephone;
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
    String? paysTelephone,
    String? numeroTelephone,
    bool? sansCode,
    bool? confidentialiteAcceptee,
    bool? inscriptionEnvoyee,
  }) => BrouillonInscription(
    usage: usage ?? this.usage,
    prenom: prenom ?? this.prenom,
    nom: nom ?? this.nom,
    genre: genre ?? this.genre,
    profilCree: profilCree ?? this.profilCree,
    parentSuitDesCours: parentSuitDesCours ?? this.parentSuitDesCours,
    paysTelephone: paysTelephone ?? this.paysTelephone,
    numeroTelephone: numeroTelephone ?? this.numeroTelephone,
    sansCode: sansCode ?? this.sansCode,
    confidentialiteAcceptee:
        confidentialiteAcceptee ?? this.confidentialiteAcceptee,
    inscriptionEnvoyee: inscriptionEnvoyee ?? this.inscriptionEnvoyee,
  );
}

/// Tient le brouillon de l'inscription pour toute la duree du parcours.
class BrouillonInscriptionControleur extends Notifier<BrouillonInscription> {
  @override
  BrouillonInscription build() => const BrouillonInscription();

  /// Retient l'usage. Choisir un usage par son propre chemin (le code d'une
  /// invitation, une carte) annule « sans code » : celui-ci ne se retient que
  /// par [deposerSansCode].
  void choisirUsage(UsageInscription usage) =>
      state = state.copier(usage: usage, sansCode: false);

  /// « Deposer ma candidature » : le candidat enseignant sans code
  /// d'invitation (CAND-04).
  void deposerSansCode() =>
      state = state.copier(usage: UsageInscription.enseignant, sansCode: true);

  /// Retient le pays de l'indicatif et le numero, sans l'indicatif.
  void saisirTelephone({required String pays, required String numero}) =>
      state = state.copier(paysTelephone: pays, numeroTelephone: numero.trim());

  /// Coche ou decoche la case de la politique de confidentialite.
  void accepterConfidentialite({required bool acceptee}) =>
      state = state.copier(confidentialiteAcceptee: acceptee);

  /// Note que le serveur a repondu « acceptee » (voir
  /// [BrouillonInscription.inscriptionEnvoyee]).
  void noterInscriptionEnvoyee() =>
      state = state.copier(inscriptionEnvoyee: true);

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

/// Le brouillon partage par les etapes.
final NotifierProvider<BrouillonInscriptionControleur, BrouillonInscription>
brouillonInscriptionProvider =
    NotifierProvider<BrouillonInscriptionControleur, BrouillonInscription>(
      BrouillonInscriptionControleur.new,
    );
