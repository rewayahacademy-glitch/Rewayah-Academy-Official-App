import '../../core/admin/service_comptes.dart';
import '../../core/classes/nom_classe_distinct.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/pays_iso.dart' show formeDeRecherche;

/// Les vues de la page Comptes, une par population (directeur, 30/10/2026,
/// capture de l'ecran Comptes au telephone) : « les eleves doivent etre a
/// part, parce qu'on ne peut pas ajouter les tuteurs directement dans une
/// classe ». Cette decision prevaut, pour cette page, sur LISTES-1 §6 (une
/// seule liste filtree par role).
///
/// Une vue range les **profils** par role : un tuteur qui est aussi eleve a
/// deux profils (deux lignes de roles differents), il est donc une fois dans
/// Familles et une fois dans Eleves, jamais deux fois dans la meme vue.
enum VueComptes {
  /// Les profils d'eleves, enfants et adultes autonomes.
  eleves,

  /// Les tuteurs, avec les eleves qui leur sont rattaches.
  familles,

  /// Les enseignants et l'etat de leur dossier.
  enseignants,

  /// L'administration, la comptabilite et le controle.
  direction;

  /// La vue d'un compte, ou nulle quand son role est illisible (il est alors
  /// signale au-dessus des vues, jamais range au hasard).
  static VueComptes? de(CompteAdmin c) => switch (c.role) {
    AppRole.student => VueComptes.eleves,
    AppRole.guardian => VueComptes.familles,
    AppRole.teacher => VueComptes.enseignants,
    AppRole.admin ||
    AppRole.accountant ||
    AppRole.controller => VueComptes.direction,
    null => null,
  };

  /// La vue ouverte quand l'adresse n'en dit aucune : la premiere, dans
  /// l'ordre des vues, qui contient une decision en attente ; sinon Eleves.
  static VueComptes parDefaut(List<CompteAdmin> comptes) {
    for (final VueComptes vue in VueComptes.values) {
      if (comptes.any(
        (CompteAdmin c) => VueComptes.de(c) == vue && c.attendUneDecision,
      )) {
        return vue;
      }
    }
    return VueComptes.eleves;
  }
}

/// Le nom de la classe d'un eleve, distinct de ses classes paralleles (R16),
/// ou nul quand il n'en a pas.
String? nomClasseEleve(CompteAdmin c) {
  final String? libelle = c.classeLibelle;
  if (libelle == null) return null;
  return nomClasseDistinct(libelle, numero: c.classeNumero);
}

/// L'etat d'un compte tel que la page le montre : le badge de la ligne et le
/// filtre disent la MEME chose, et chaque compte entre dans exactement un etat.
///
/// Decision « pastille-attente » du 05/10 (AD-NETTOYAGE-2, par delegation du
/// directeur) : « En attente » ne compte que les comptes qui attendent une
/// decision (un enseignant en attente ; depuis l'admission du 27/10, une
/// demande d'admission recue). Un autre compte `pending_kyc` dont le role est
/// lu n'attend aucune decision : il se dit « Sans décision ». Un compte
/// `pending_kyc` au role illisible se dit « État inconnu ».
enum EtatAffiche {
  /// Un compte qui attend une decision.
  attente,

  /// Un autre compte en attente, qui n'attend aucune decision.
  sansDecision,

  /// Actif.
  actif,

  /// Provisoire (ADR-014).
  provisoire,

  /// Suspendu.
  suspendu,

  /// Etat ou role illisible.
  inconnu;

  /// L'etat affiche d'un compte.
  static EtatAffiche de(CompteAdmin c) => switch (c.etat) {
    _ when c.attendUneDecision => EtatAffiche.attente,
    AccountStatus.pendingKyc when c.role != null => EtatAffiche.sansDecision,
    AccountStatus.pendingKyc => EtatAffiche.inconnu,
    AccountStatus.active => EtatAffiche.actif,
    AccountStatus.provisionalActive => EtatAffiche.provisoire,
    AccountStatus.disabled => EtatAffiche.suspendu,
    null => EtatAffiche.inconnu,
  };
}

/// La colonne sur laquelle la liste est triee.
enum ChampTriComptes {
  /// Le nom affiche.
  nom,

  /// L'anciennete d'inscription (la valeur de la colonne « Inscrit depuis »).
  inscrit,

  /// L'etat du compte.
  etat,
}

/// Le tri choisi par l'ecran. `null` : l'ordre par defaut (ce qui attend une
/// decision d'abord, puis l'ordre de la base).
class TriComptes {
  /// Cree un tri.
  const TriComptes(this.champ, this.croissant);

  /// La colonne.
  final ChampTriComptes champ;

  /// `true` : croissant, tel que la colonne se lit (A a Z, le plus petit
  /// nombre de jours d'abord).
  final bool croissant;

  /// Le tri qui suit [champ] quand on touche son en-tete : croissant, puis
  /// decroissant, puis plus de tri.
  static TriComptes? suivant(TriComptes? actuel, ChampTriComptes champ) {
    if (actuel == null || actuel.champ != champ) {
      return TriComptes(champ, true);
    }
    return actuel.croissant ? TriComptes(champ, false) : null;
  }
}

/// Ce que l'ecran retient pour filtrer, chercher et trier les comptes **deja
/// lus** d'une vue. La lecture des comptes rend tout, sans recherche, tri ni
/// total : tout se fait ici, sur la liste en memoire (legitime tant qu'elle
/// tient sous le plafond du serveur, [plafondComptesServeur]).
class FiltreComptes {
  /// Cree un filtre.
  const FiltreComptes({
    this.etat,
    this.echus = false,
    this.recherche = '',
    this.tri,
  });

  /// L'etat retenu, ou `null` : tous.
  final EtatAffiche? etat;

  /// Vrai : seuls les acces echus.
  final bool echus;

  /// Le texte cherche (nom, identifiant ; pour un eleve, aussi sa classe et
  /// son tuteur).
  final String recherche;

  /// Le tri, ou `null`.
  final TriComptes? tri;

  /// Vrai quand ni filtre, ni recherche : le tri n'est pas un filtre.
  bool get estVide => etat == null && !echus && recherche.trim().isEmpty;

  /// Une copie. Les champs nullables se retirent avec les indicateurs `sans*`.
  FiltreComptes avec({
    EtatAffiche? etat,
    bool sansEtat = false,
    bool? echus,
    String? recherche,
    TriComptes? tri,
    bool sansTri = false,
  }) => FiltreComptes(
    etat: sansEtat ? null : (etat ?? this.etat),
    echus: echus ?? this.echus,
    recherche: recherche ?? this.recherche,
    tri: sansTri ? null : (tri ?? this.tri),
  );

  /// Retire ce que les puces de filtres actifs montrent (etat, acces echus,
  /// recherche). Le tri reste : il ne reduit rien.
  FiltreComptes get efface => FiltreComptes(tri: tri);

  /// Les comptes de [tous] qui passent le filtre, dans l'ordre voulu.
  ///
  /// [libelleEtat] donne le mot que la colonne « Etat » affiche : le tri par
  /// etat suit alors **l'ordre alphabetique de ces mots**, celui qu'une
  /// personne lit en haut de la colonne. Sans lui, l'ordre de l'enumeration.
  List<CompteAdmin> appliquer(
    List<CompteAdmin> tous,
    DateTime maintenant, {
    String Function(EtatAffiche etat)? libelleEtat,
  }) {
    final String cherche = formeDeRecherche(recherche.trim());
    final List<CompteAdmin> gardes = tous
        .where(
          (CompteAdmin c) =>
              (etat == null || EtatAffiche.de(c) == etat) &&
              (!echus || c.accesEchu(maintenant)) &&
              (cherche.isEmpty || _correspond(c, cherche)),
        )
        .toList(growable: false);

    final TriComptes? ordre = tri;
    if (ordre == null) {
      // Tri stable : ce qui attend une decision d'abord, le reste dans
      // l'ordre rendu par la base.
      return <CompteAdmin>[
        ...gardes.where((CompteAdmin c) => c.attendUneDecision),
        ...gardes.where((CompteAdmin c) => !c.attendUneDecision),
      ];
    }
    // Rang d'origine : a valeur egale, l'ordre de la base est conserve.
    final Map<CompteAdmin, int> rang = <CompteAdmin, int>{
      for (int i = 0; i < gardes.length; i++) gardes[i]: i,
    };
    int comparer(CompteAdmin a, CompteAdmin b) {
      final int sens = switch (ordre.champ) {
        ChampTriComptes.nom => formeDeRecherche(
          a.libelle,
        ).compareTo(formeDeRecherche(b.libelle)),
        // Les jours pleins, comme la colonne : deux inscrits le meme jour sont
        // a egalite, et l'ordre de la base les departage.
        ChampTriComptes.inscrit =>
          a.joursDAttente(maintenant).compareTo(b.joursDAttente(maintenant)),
        ChampTriComptes.etat =>
          libelleEtat == null
              ? EtatAffiche.de(a).index.compareTo(EtatAffiche.de(b).index)
              : formeDeRecherche(
                  libelleEtat(EtatAffiche.de(a)),
                ).compareTo(formeDeRecherche(libelleEtat(EtatAffiche.de(b)))),
      };
      if (sens != 0) return ordre.croissant ? sens : -sens;
      return rang[a]!.compareTo(rang[b]!);
    }

    return gardes.toList()..sort(comparer);
  }

  static bool _correspond(CompteAdmin c, String cherche) =>
      <String?>[c.libelle, c.identifiant, c.tuteurLibelle, nomClasseEleve(c)]
          .whereType<String>()
          .any((String valeur) => formeDeRecherche(valeur).contains(cherche));
}
