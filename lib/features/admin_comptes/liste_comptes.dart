import '../../core/admin/service_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/pays_iso.dart' show formeDeRecherche;

/// L'etat d'un compte tel que la page le montre : le badge de la ligne et le
/// filtre disent la MEME chose, et chaque compte entre dans exactement un etat.
///
/// Decision « pastille-attente » du 05/10 (AD-NETTOYAGE-2, par delegation du
/// directeur) : « En attente » ne compte que les enseignants qui attendent
/// une decision, le chiffre de la tuile « Dossiers a valider ». Un autre
/// compte `pending_kyc` dont le role est lu (tuteur, eleve, personnel)
/// n'attend aucune decision (K-47 : seul l'enseignant depose une piece) : il
/// se dit « Sans décision » (decide par delegation le 08/10, revue croisee de
/// LIB-DIR-1). Un compte `pending_kyc` au role illisible : on ne sait pas
/// s'il attend une decision, il se dit « État inconnu », comme le bandeau
/// qui le signale.
enum EtatAffiche {
  /// Un enseignant qui attend une decision.
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
    AccountStatus.pendingKyc when c.attendUneDecision => EtatAffiche.attente,
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
/// lus**. `comptes_admin()` rend tout, sans recherche, tri ni total : tout se
/// fait ici, sur la liste en memoire (legitime tant qu'elle tient sous le
/// plafond du serveur, [plafondComptesServeur]).
class FiltreComptes {
  /// Cree un filtre.
  const FiltreComptes({
    this.role,
    this.etat,
    this.echus = false,
    this.recherche = '',
    this.tri,
  });

  /// Le role retenu, ou `null` : tous.
  final AppRole? role;

  /// L'etat retenu, ou `null` : tous.
  final EtatAffiche? etat;

  /// Vrai : seuls les acces echus.
  final bool echus;

  /// Le texte cherche (nom, identifiant).
  final String recherche;

  /// Le tri, ou `null`.
  final TriComptes? tri;

  /// Vrai quand ni filtre, ni recherche : le tri n'est pas un filtre.
  bool get estVide =>
      role == null && etat == null && !echus && recherche.trim().isEmpty;

  /// Une copie. Les champs nullables se retirent avec les indicateurs `sans*`.
  FiltreComptes avec({
    AppRole? role,
    bool sansRole = false,
    EtatAffiche? etat,
    bool sansEtat = false,
    bool? echus,
    String? recherche,
    TriComptes? tri,
    bool sansTri = false,
  }) => FiltreComptes(
    role: sansRole ? null : (role ?? this.role),
    etat: sansEtat ? null : (etat ?? this.etat),
    echus: echus ?? this.echus,
    recherche: recherche ?? this.recherche,
    tri: sansTri ? null : (tri ?? this.tri),
  );

  /// Retire ce que les puces de filtres actifs montrent (etat, acces echus,
  /// recherche). **Le role reste** : il se lit dans la rangee des roles,
  /// toujours visible, et se change d'un toucher sur « Tous ». Le tri reste : il
  /// ne reduit rien.
  FiltreComptes get efface => FiltreComptes(role: role, tri: tri);

  /// Les comptes de [tous] qui passent le filtre, dans l'ordre voulu.
  ///
  /// [libelleEtat] donne le mot que la colonne « Etat » affiche : le tri par etat
  /// suit alors **l'ordre alphabetique de ces mots**, celui qu'une personne lit
  /// en haut de la colonne (relecture du code R-9). Sans lui, l'ordre de
  /// l'enumeration (ce qui attend une decision d'abord).
  List<CompteAdmin> appliquer(
    List<CompteAdmin> tous,
    DateTime maintenant, {
    String Function(EtatAffiche etat)? libelleEtat,
  }) {
    final String cherche = formeDeRecherche(recherche.trim());
    final List<CompteAdmin> gardes = tous
        .where(
          (CompteAdmin c) =>
              (role == null || c.role == role) &&
              (etat == null || EtatAffiche.de(c) == etat) &&
              (!echus || c.accesEchu(maintenant)) &&
              (cherche.isEmpty || _correspond(c, cherche)),
        )
        .toList(growable: false);

    final TriComptes? ordre = tri;
    if (ordre == null) {
      // Tri stable : ce qui attend une decision d'abord, le reste dans l'ordre
      // rendu par la base. La base met les tuteurs `pending_kyc` en tete, ce
      // qui repoussait les enseignants sous des lignes sans decision.
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
      formeDeRecherche(c.libelle).contains(cherche) ||
      formeDeRecherche(c.identifiant).contains(cherche);
}
