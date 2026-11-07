import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/nom_latin.dart';
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

/// Les etapes de l'inscription, dans l'ordre. « n sur N » se calcule ici.
///
/// Admission, lot B (29/10/2026) : le titulaire (« pour moi », « mon
/// enfant ») a repondu a toutes les questions avant le compte
/// (`/commencer`, langue comprise) ; apres la connexion, il ne dit plus que
/// son nom et son genre. L'enseignant et le comptable gardent l'etape
/// d'usage.
///
/// CAND-04 (porte de la PR 50 par CANDIDATS-FLUX, 06/11/2026) : le candidat
/// enseignant, avec ou sans code d'invitation, a en plus l'etape du telephone,
/// avant le recapitulatif (ou se choisissent aussi la langue et l'accord de
/// confidentialite).
List<String> etapesPour(BrouillonInscription brouillon) => <String>[
  if (!brouillon.titulaire) Routes.inscriptionUsage,
  Routes.inscriptionIdentite,
  Routes.inscriptionGenre,
  if (brouillon.usage == UsageInscription.enseignant)
    Routes.inscriptionTelephone,
  Routes.inscriptionRecapitulatif,
];

/// Le rang (a partir de 1) d'une etape dans [etapesPour], 0 si elle n'y est
/// pas.
int rangEtape(BrouillonInscription brouillon, String route) =>
    etapesPour(brouillon).indexOf(route) + 1;

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
    this.nomLatin = '',
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

  /// Le nom en lettres latines que la personne a confirme (candidat
  /// enseignant dont le nom saisi n'est pas en alphabet latin, decision du
  /// directeur du 23/10/2026) ; vide sinon.
  final String nomLatin;

  /// Le genre retenu.
  final Genre? genre;

  /// Reponse a « Suivez-vous aussi des cours ? » (« Moi et ma famille »,
  /// PAQ-DIR-EA) ; `null` tant que la question n'est pas repondue. Elle ne
  /// donne aucun droit : l'eleve autonome est une capacite servie (C-24).
  final bool? parentSuitDesCours;

  /// Vrai pour « pour moi » et « mon enfant ».
  bool get titulaire =>
      usage == UsageInscription.moi || usage == UsageInscription.famille;

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

  /// Vrai quand l'etape d'identite pose une question de plus, « Votre nom en
  /// lettres latines » : le candidat enseignant dont le nom saisi porte une
  /// autre ecriture que l'alphabet latin. Les autres usages n'ont pas de
  /// candidature ni de liste : ils n'en entendent pas parler.
  bool get nomLatinDemande =>
      usage == UsageInscription.enseignant &&
      nomDemandeEcritureLatine('$prenom $nom');

  /// Vrai quand l'identite est complete : remplie et, si la question de plus
  /// est posee, repondue par un nom en lettres latines.
  bool get identiteComplete =>
      identiteRemplie && (!nomLatinDemande || nomEstLatin(nomLatin));

  /// Le nom latin a envoyer au serveur apres l'inscription, ou `null` quand la
  /// question n'a pas ete posee (ou pas repondue).
  String? get nomLatinAEnvoyer => nomLatinDemande && nomEstLatin(nomLatin)
      ? nomLatinNettoye(nomLatin)
      : null;

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
    if (!identiteComplete) {
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
    String? nomLatin,
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
    nomLatin: nomLatin ?? this.nomLatin,
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

  /// Retient l'identite, et le nom en lettres latines quand l'etape l'a
  /// demande (vide sinon : un nom latin ne survit pas a un nom qui n'en
  /// demande plus).
  void saisirIdentite({
    required String prenom,
    required String nom,
    String nomLatin = '',
  }) => state = state.copier(
    prenom: prenom.trim(),
    nom: nom.trim(),
    nomLatin: nomLatinNettoye(nomLatin),
  );

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
