import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import 'liste_comptes.dart';

/// `ADM-08` : les comptes du produit.
///
/// **L'ecran qui manquait, et son absence coutait des personnes.** Mesure en
/// production le 18 septembre 2026 : trois enseignants inscrits les 11 et 15
/// septembre attendaient depuis sept jours, contrats signes, sans avoir depose
/// leur piece d'identite. Aucun ecran de l'administration ne les montrait.
/// `ADM-02` ne listait que les pieces deposees, `ADM-05` que les eleves sans
/// enseignant, et le tableau de bord affichait « 0 dossiers a valider ».
/// L'academie etait bloquee et l'interface annoncait qu'il n'y avait rien a
/// faire.
///
/// Trois choix de rendu, chacun paye par une raison :
///
///   * **ce qui attend une decision passe devant**, et se dit en haut en une
///     phrase. Un compte bloque depuis une semaine ne doit pas se lire apres
///     trente comptes actifs, et le tri vient de la base, pas de l'ecran ;
///   * **l'anciennete est rendue, jamais la seule date**. « Depuis 7 jours »
///     est un fait qui appelle un geste ; « 11/09 » demande un calcul ;
///   * **une piece absente est un etat affiche**, pas une case vide. C'est
///     precisement l'etat qui etait invisible.
///
/// **LISTES-3 (23/10/2026), la page d'un administrateur qui l'ouvre des dizaines
/// de fois par jour.** Plus de paragraphe avant les commandes ; une recherche
/// (nom, identifiant) ; les roles en acces direct ; l'etat en menu ; les filtres
/// actifs retirables ; un compteur « N comptes » ; une table dense a en-tete
/// colle, triable, paginee. `comptes_admin()` rend tout, sans recherche, tri ni
/// total : tout cela se fait ici, sur la liste lue, et un avertissement se montre
/// quand le nombre recu atteint le plafond du serveur ([plafondComptesServeur]).
/// Le role, l'etat, les acces echus et le tri vivent aussi dans l'adresse ; le
/// texte cherche, jamais (c'est le nom d'une personne).
class ComptesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des comptes.
  const ComptesPage({
    super.key,
    this.echusSeulement = false,
    this.requete = const <String, String>{},
  });

  /// Ouvre la page sur les seuls acces echus (DASH-ADM-ECHUS, adresse
  /// `Routes.adminPersonnesComptesEchus`).
  final bool echusSeulement;

  /// Les parametres de l'adresse (`role`, `etat`, `filtre`, `q`, `tri`) : la
  /// page les lit a l'ouverture et chaque fois que l'adresse change sans elle
  /// (retour arriere, entree « Comptes » de la navigation).
  final Map<String, String> requete;

  @override
  ConsumerState<ComptesPage> createState() => _ComptesPageEtat();
}

/// Les parametres d'adresse que cette page possede : les autres sont gardes.
const List<String> _clesAdresse = <String>[
  'role',
  'etat',
  'filtre',
  'q',
  'tri',
];

/// Les tailles de page proposees (pagination du cote de l'ecran : la liste est
/// deja toute en memoire).
const List<int> _taillesPage = <int>[25, 50, 100];

class _ComptesPageEtat extends ConsumerState<ComptesPage> {
  /// Filtres, recherche et tri. L'ecran filtre, cherche et trie la liste deja
  /// lue : `comptes_admin()` n'a ni recherche, ni tri, ni total.
  late FiltreComptes _filtre = _depuisAdresse();

  final TextEditingController _recherche = TextEditingController();

  /// L'attente qui suit la derniere frappe (ce n'est pas un mouvement).
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  int _taillePage = 50;

  /// La page courante, a partir de 0.
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _recherche.text = _filtre.recherche;
  }

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  /// Lit le filtre dans l'adresse. Une valeur inconnue est ignoree : une
  /// adresse partagee et perimee ne doit jamais casser la page.
  FiltreComptes _depuisAdresse() {
    final Map<String, String> q = widget.requete;
    AppRole? role;
    for (final AppRole r in AppRole.values) {
      if (r.valeurSql == q['role']) role = r;
    }
    EtatAffiche? etat;
    for (final EtatAffiche e in EtatAffiche.values) {
      if (e.name == q['etat']) etat = e;
    }
    TriComptes? tri;
    final String? brut = q['tri'];
    if (brut != null) {
      final bool decroissant = brut.startsWith('-');
      final String nom = decroissant ? brut.substring(1) : brut;
      for (final ChampTriComptes c in ChampTriComptes.values) {
        if (c.name == nom) tri = TriComptes(c, !decroissant);
      }
    }
    return FiltreComptes(
      role: role,
      etat: etat,
      echus: widget.echusSeulement || q['filtre'] == 'echus',
      recherche: q['q'] ?? '',
      tri: tri,
    );
  }

  /// Le filtre dit en parametres d'adresse (seulement ce qui est pose).
  ///
  /// **Le texte cherche n'y est pas** (relecture du code R-4) : c'est le nom ou
  /// l'identifiant d'une personne, il n'a rien a faire dans une adresse (journal
  /// du serveur, historique du navigateur, lien copie), et chaque frappe posee
  /// y ajoutait une entree d'historique. Une adresse qui le porte encore (ancien
  /// lien) est lue, et reecrite sans lui a la prochaine action.
  static Map<String, String> _enAdresse(FiltreComptes f) => <String, String>{
    if (f.role != null) 'role': f.role!.valeurSql,
    if (f.etat != null) 'etat': f.etat!.name,
    if (f.echus) 'filtre': 'echus',
    if (f.tri != null)
      'tri': '${f.tri!.croissant ? '' : '-'}${f.tri!.champ.name}',
  };

  /// L'adresse porte le filtre, et go_router garde ce `State` d'une requete a
  /// l'autre (la page est cle sur le chemin seul) : sans ce recalage, passer
  /// d'une adresse filtree a l'adresse nue (entree « Comptes » de la
  /// navigation) laissait l'ecran filtre.
  @override
  void didUpdateWidget(ComptesPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.echusSeulement == widget.echusSeulement &&
        mapEquals(ancien.requete, widget.requete)) {
      return;
    }
    final FiltreComptes nouveau = _depuisAdresse();
    if (mapEquals(_enAdresse(nouveau), _enAdresse(_filtre))) return;
    _attenteSaisie?.cancel();
    _recherche.text = nouveau.recherche;
    setState(() {
      _filtre = nouveau;
      _page = 0;
    });
  }

  /// Pose un nouveau filtre : revient a la premiere page, dit l'adresse.
  void _appliquer(FiltreComptes filtre) {
    setState(() {
      _filtre = filtre;
      _page = 0;
    });
    _ecrireAdresse();
  }

  /// Reporte le filtre dans l'adresse, pour qu'elle dise toujours ce que
  /// montre l'ecran (lien partage, retour arriere, rechargement). Hors
  /// routeur (tests montes sans GoRouter), rien a faire.
  void _ecrireAdresse() {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) return;
    final Uri actuelle = routeur.routerDelegate.currentConfiguration.uri;
    final Map<String, String> requete = <String, String>{
      for (final MapEntry<String, String> e in actuelle.queryParameters.entries)
        if (!_clesAdresse.contains(e.key)) e.key: e.value,
      ..._enAdresse(_filtre),
    };
    if (mapEquals(requete, actuelle.queryParameters)) return;
    routeur.go(
      Uri(
        path: actuelle.path,
        queryParameters: requete.isEmpty ? null : requete,
      ).toString(),
    );
  }

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (mounted) _appliquer(_filtre.avec(recherche: texte));
    });
  }

  void _chercherTout(String texte) {
    _attenteSaisie?.cancel();
    _appliquer(_filtre.avec(recherche: texte));
  }

  void _effacerRecherche() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _appliquer(_filtre.avec(recherche: ''));
  }

  void _toutEffacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _appliquer(_filtre.efface);
  }

  void _trier(ChampTriComptes champ) {
    final TriComptes? suivant = TriComptes.suivant(_filtre.tri, champ);
    _appliquer(
      suivant == null
          ? _filtre.avec(sansTri: true)
          : _filtre.avec(tri: suivant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);

    return PageShell(
      titre: t.admin.comptes.titre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 1),
      // `DataCollection` porte son propre `ListView` : il exige une hauteur
      // bornee, donc l'ecran gere son defilement, comme `ADM-04`.
      defilante: false,
      // FILTRES-1b : des colonnes de corps (ici et dans le corps) qui disent
      // a `PageShell` la hauteur qui leur manque : a 320 px texte x2, la page
      // defile au lieu de deborder sous la liste.
      //
      // LISTES-3 : plus de paragraphe d'introduction avant les commandes. Ce
      // qu'il disait (« un enseignant sans piece reste visible ici ») est
      // porte par la table elle-meme : la colonne « Pièce d'identité » dit
      // « Aucune pièce déposée ».
      child: ColonneCorps(
        children: <Widget>[
          Expanded(
            // Les getters, jamais le type d'execution : Riverpod 3 relance un
            // provider en echec tout seul, et l'etat repasse par `AsyncLoading`
            // en conservant `hasError`. `BlocAsynchrone` porte les etats
            // chargement, chargement prolonge, echec (avec « Reessayer ») et
            // indisponibilite ; le hors ligne est le bandeau de `PageShell`.
            child: BlocAsynchrone<List<CompteAdmin>>(
              valeur: comptes,
              squelette: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints contraintes) {
                  // Autant de barres que la place en laisse, au pas des lignes
                  // du mode : le squelette qui s'efface en fondu ne depasse
                  // jamais la hauteur de la page (1280 x 800, texte x2).
                  final double pas =
                      AppMetriques.of(context).cibleTactile + AppSpacing.sm;
                  final int n = contraintes.hasBoundedHeight
                      ? (contraintes.maxHeight / pas).floor().clamp(2, 10)
                      : 6;
                  return Skeleton.tableDense(lignes: n);
                },
              ),
              titreEchec: t.admin.comptes.erreur,
              onReessayer: () => ref.invalidate(comptesProvider),
              construire: _corps,
            ),
          ),
        ],
      ),
    );
  }

  /// Les commandes, la synthese, puis le tableau.
  Widget _corps(List<CompteAdmin> comptes) {
    final DateTime maintenant = DateTime.now();
    final List<CompteAdmin> visibles = _filtre.appliquer(
      comptes,
      maintenant,
      libelleEtat: _libelleEtat,
    );

    // La page courante : si un filtre a raccourci la liste, on revient en deca.
    final int pages = visibles.isEmpty
        ? 1
        : (visibles.length + _taillePage - 1) ~/ _taillePage;
    final int page = _page.clamp(0, pages - 1);
    final int debut = page * _taillePage;
    final int fin = (debut + _taillePage).clamp(0, visibles.length);

    return ColonneCorps(
      minimumEtire: DataCollection.minimumLisible(context),
      children: <Widget>[
        _commandes(comptes, maintenant),
        Ecart.vSm,
        if (comptes.length >= plafondComptesServeur) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('comptes-plafond'),
            titre: t.admin.comptes.plafondTitre,
            message: t.admin.comptes.plafondMessage(
              nombre: '$plafondComptesServeur',
            ),
            ton: TonEtat.avertissement,
          ),
          Ecart.vSm,
        ],
        _barreRecherche(comptes, visibles.length),
        Ecart.vSm,
        _filtresActifs(),
        if (visibles.isEmpty)
          EmptyState(
            message: t.admin.comptes.aucunAvecCeFiltre,
            invitation: t.admin.comptes.aucunAvecCeFiltreDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        else
          Expanded(
            child: _HauteurLisible(
              child: DataCollection<CompteAdmin>(
                key: ValueKey<String>('comptes-table-$page-$_taillePage'),
                lignes: visibles.sublist(debut, fin),
                cle: (CompteAdmin c) => ValueKey<String>(c.profilId),
                colonnes: _colonnes(visibles),
                // Une colonne d'actions seulement si au moins un compte de la
                // liste en a une (pas de colonne vide), jugee sur toute la
                // liste et non sur la page : la largeur ne saute pas d'une page
                // a l'autre. Une ligne sans action n'a pas de menu vide.
                actionsLigne: visibles.any(_ouvreUnDossier) ? _actions : null,
                // PAS DE SELECTION MULTIPLE ici, volontairement (audit
                // LISTES-1, 3.3) : aucune operation groupee fiable n'existe
                // pour des comptes (pas de RPC de lot, une piece se decide une
                // a une, DEC:24). Une case sans geste groupé serait un faux
                // controle.
                piedCollant: PiedDeListe(
                  debut: debut + 1,
                  fin: fin,
                  total: visibles.length,
                  onPrecedent: page > 0
                      ? () => setState(() => _page = page - 1)
                      : null,
                  onSuivant: fin < visibles.length
                      ? () => setState(() => _page = page + 1)
                      : null,
                  taillePage: _taillePage,
                  taillesProposees: _taillesPage,
                  onTaillePage: (int n) => setState(() {
                    _taillePage = n;
                    _page = 0;
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Les filtres : le role **visible**, en acces direct (c'etait le seul moyen
  /// d'obtenir « les tuteurs » et il se cachait derriere « Plus »), l'etat en
  /// menu (l'axe secondaire), les acces echus. Une seule rangee, pleine
  /// largeur : la recherche vient dessous, a cote du compteur.
  Widget _commandes(List<CompteAdmin> comptes, DateTime maintenant) {
    final Map<AppRole, int> parRole = <AppRole, int>{};
    final Map<EtatAffiche, int> parEtat = <EtatAffiche, int>{};
    for (final CompteAdmin c in comptes) {
      final AppRole? r = c.role;
      if (r != null) parRole[r] = (parRole[r] ?? 0) + 1;
      final EtatAffiche e = EtatAffiche.de(c);
      parEtat[e] = (parEtat[e] ?? 0) + 1;
    }
    final int echus = _nombreEchus(comptes, maintenant);

    // Un seul etat present : le menu n'offrirait aucun choix, et un controle
    // sans choix n'est pas un controle. Il est dans la meme rangee que les
    // roles (une seule rangee de filtres, que les tests de FILTRES-1 gardent) :
    // sur bureau tout tient, sur telephone la rangee defile.
    final Widget? menuEtat = (parEtat.length > 1 || _filtre.etat != null)
        ? MenuFiltre<EtatAffiche>(
            key: const ValueKey<String>('comptes-filtre-etat'),
            libelle: t.admin.comptes.filtreEtat,
            valeur: _filtre.etat,
            onChoix: (EtatAffiche? e) => _appliquer(
              e == null ? _filtre.avec(sansEtat: true) : _filtre.avec(etat: e),
            ),
            entrees: <EntreeFiltre<EtatAffiche>>[
              EntreeFiltre<EtatAffiche>(
                valeur: null,
                libelle: t.admin.comptes.filtreTousLesEtats,
                compteur: comptes.length,
              ),
              for (final EtatAffiche e in EtatAffiche.values)
                if (parEtat.containsKey(e) || _filtre.etat == e)
                  EntreeFiltre<EtatAffiche>(
                    valeur: e,
                    libelle: _libelleEtat(e),
                    compteur: parEtat[e] ?? 0,
                  ),
            ],
          )
        : null;

    final Widget filtres = RangeeFiltres(
      // Tout reste visible : la rangee defile si elle ne tient pas. Les roles
      // ne passent jamais sous « Plus ».
      replier: false,
      filtres: <Widget>[
        FilterPill(
          key: const ValueKey<String>('comptes-role-tous'),
          libelle: t.admin.comptes.filtreTousEtats,
          compteur: comptes.length,
          retenue: _filtre.role == null,
          onPress: () => _appliquer(_filtre.avec(sansRole: true)),
        ),
        // Les roles **presents dans les donnees**, avec leur compte, les
        // personnes de la classe d'abord.
        for (final AppRole r in _ordreRoles)
          if (parRole.containsKey(r) || _filtre.role == r)
            FilterPill(
              key: ValueKey<String>('comptes-role-${r.name}'),
              libelle: _nomRolePluriel(r),
              compteur: parRole[r] ?? 0,
              retenue: _filtre.role == r,
              onPress: () => _appliquer(
                _filtre.role == r
                    ? _filtre.avec(sansRole: true)
                    : _filtre.avec(role: r),
              ),
            ),
        ?menuEtat,
        // DASH-ADM-ECHUS : les acces echus, le meme chiffre que le Centre de
        // commande. Rendu des qu'il y en a, ou quand le filtre est retenu (il
        // doit pouvoir se relacher).
        if (_filtre.echus || echus > 0)
          FilterPill(
            key: const ValueKey<String>('comptes-filtre-echus'),
            libelle: t.admin.tableau.comptes,
            compteur: echus,
            retenue: _filtre.echus,
            onPress: () => _appliquer(_filtre.avec(echus: !_filtre.echus)),
          ),
      ],
    );

    return filtres;
  }

  /// La recherche, a cote du compteur et de l'alerte : la rangee juste au-dessus
  /// du tableau. Etroit, la recherche passe seule sur sa ligne.
  Widget _barreRecherche(List<CompteAdmin> comptes, int nombre) {
    final Widget recherche = ChampRecherche(
      cleChamp: const ValueKey<String>('comptes-recherche'),
      cleEffacer: const ValueKey<String>('comptes-recherche-effacer'),
      controleur: _recherche,
      libelle: t.admin.comptes.recherche,
      aide: t.admin.comptes.rechercheAide,
      onChange: _chercher,
      onValider: _chercherTout,
    );
    final Widget synthese = _synthese(comptes, nombre);
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        if (contraintes.maxWidth >= _largeurUneRangee) {
          return Row(
            children: <Widget>[
              SizedBox(width: _largeurRecherche, child: recherche),
              Ecart.hLg,
              Expanded(child: synthese),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[recherche, Ecart.vSm, synthese],
        );
      },
    );
  }

  /// En dessous, la synthese passe sous la recherche.
  static const double _largeurUneRangee = 900;

  /// La largeur de la recherche quand elle partage sa rangee.
  static const double _largeurRecherche = 320;

  static const List<AppRole> _ordreRoles = <AppRole>[
    AppRole.student,
    AppRole.guardian,
    AppRole.teacher,
    AppRole.admin,
    AppRole.accountant,
    AppRole.controller,
  ];

  /// Les filtres en cours, retirables un a un. Le role n'y est pas : sa
  /// rangee le montre toujours.
  Widget _filtresActifs() => FiltresActifs(
    filtres: <FiltreActif>[
      if (_filtre.etat != null)
        FiltreActif(
          libelle: t.admin.comptes.filtreActifEtat(
            valeur: _libelleEtat(_filtre.etat!),
          ),
          onRetirer: () => _appliquer(_filtre.avec(sansEtat: true)),
        ),
      if (_filtre.echus)
        FiltreActif(
          libelle: t.admin.tableau.comptes,
          onRetirer: () => _appliquer(_filtre.avec(echus: false)),
        ),
      if (_filtre.recherche.trim().isNotEmpty)
        FiltreActif(
          libelle: t.admin.comptes.filtreActifRecherche(
            texte: _filtre.recherche.trim(),
          ),
          onRetirer: _effacerRecherche,
        ),
    ],
    onToutEffacer: _toutEffacer,
  );

  /// La synthese, au ras du tableau : combien de comptes, et ce qui attend une
  /// decision (un toucher applique ce filtre). Le fait d'abord, en une phrase.
  Widget _synthese(List<CompteAdmin> comptes, int nombre) {
    final DateTime maintenant = DateTime.now();
    final List<CompteAdmin> attendent = comptes
        .where((CompteAdmin c) => c.attendUneDecision)
        .toList(growable: false);
    // Un compte en attente dont le role est illisible n'attend « une decision »
    // que dans le doute : il n'est compte nulle part, donc l'ecran le dit.
    final int roleIllisible = comptes
        .where(
          (CompteAdmin c) =>
              c.etat == AccountStatus.pendingKyc && c.role == null,
        )
        .length;
    final TextTheme textes = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            t.admin.comptes.compteur(n: nombre),
            key: const ValueKey<String>('comptes-compteur'),
            style: textes.titleSmall,
          ),
        ),
        if (attendent.isNotEmpty)
          ActionPrincipale(
            key: const ValueKey<String>('comptes-attente'),
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            libelle: attendent.length == 1
                ? switch (attendent.first.joursDAttente(maintenant)) {
                    <= 0 => t.admin.comptes.attenteUneAujourdhui,
                    1 => t.admin.comptes.attenteUneUnJour,
                    final int jours => LibellesGroupe.insecable(
                      t.admin.comptes.attenteUne(jours: jours),
                    ),
                  }
                : t.admin.comptes.attentePlusieurs(nombre: attendent.length),
            onPress: () => _appliquer(
              _filtre.avec(sansRole: true, etat: EtatAffiche.attente),
            ),
          ),
        if (roleIllisible > 0)
          Text(
            roleIllisible == 1
                ? t.admin.comptes.roleIllisibleUn
                : t.admin.comptes.roleIllisiblePlusieurs(
                    nombre: '$roleIllisible',
                  ),
            style: textes.bodySmall,
          ),
      ],
    );
  }

  /// Les colonnes **utiles au filtre de role** : rien de vide, rien d'inutile.
  /// Un eleve ou un tuteur ne depose pas de piece (K-47) : « Sans objet »
  /// repete sur chaque ligne n'apprend rien. Les champs que `comptes_admin()`
  /// sert et que l'ecran ne montrait pas le sont ici : l'enseignant en cours
  /// d'un eleve, les eleves du foyer d'un tuteur.
  List<ColonneDonnees<CompteAdmin>> _colonnes(List<CompteAdmin> visibles) {
    final AppRole? role = _filtre.role;
    // Quand l'identite est masquee, le prenom est nul et le libelle se replie
    // sur l'identifiant : les colonnes « Personne » et « Identifiant »
    // afficheraient alors deux fois la meme valeur.
    final bool identitesConnues = visibles.any(
      (CompteAdmin c) => c.prenom != null,
    );
    final bool pays = visibles.any(
      (CompteAdmin c) => PaysEnseignant.nomAffichable(c.paysEnseignant) != null,
    );
    final bool pieces = visibles.any((CompteAdmin c) => !_pieceSansObjet(c));
    // Tous les roles : les contrats restent (c'est une colonne de lecture
    // generale). Un role filtre : seulement si un compte en a signe.
    final bool contrats =
        role == null || visibles.any((CompteAdmin c) => c.contrats > 0);

    TriColonne tri(ChampTriComptes champ) => TriColonne(
      sens: _filtre.tri?.champ == champ
          ? (_filtre.tri!.croissant ? SensTri.croissant : SensTri.decroissant)
          : null,
      onTrier: () => _trier(champ),
    );

    return <ColonneDonnees<CompteAdmin>>[
      ColonneDonnees<CompteAdmin>(
        titre: t.admin.comptes.colonnePersonne,
        role: RoleColonne.identifiante,
        flex: 2,
        tri: tri(ChampTriComptes.nom),
        // COUPE-MOTS-4 : sous masquage, le libelle est l'identifiant, tenu sur
        // une ligne comme dans sa colonne.
        texte: (CompteAdmin c) => c.libelle == c.identifiant
            ? identifiantInsecable(c.identifiant)
            : c.libelle,
      ),
      // Sous masquage, `libelle` **est** l'identifiant : la colonne dediee
      // afficherait deux fois la meme valeur cote a cote.
      if (identitesConnues)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneIdentifiant,
          // COUPE-MOTS-4 : « TEACHER-AS-000001 » ne se coupe plus a son
          // trait d'union.
          texte: (CompteAdmin c) => identifiantInsecable(c.identifiant),
        ),
      // ENS-PAYS-1 : le pays des comptes enseignants, seulement quand une
      // ligne au moins le porte (pas de colonne vide).
      if (pays)
        ColonneDonnees<CompteAdmin>(
          // « Pays » : la colonne ne porte que des comptes enseignants, et
          // « Pays de l'enseignant » se tronquait a 1440.
          titre: t.enseignant.profil.pays,
          // Sa propre ligne en carte (sous 1200), avec le drapeau : la ligne
          // secondaire jointe ne rendrait que du texte.
          role: RoleColonne.aPart,
          texte: (CompteAdmin c) =>
              PaysEnseignant.nomAffichable(c.paysEnseignant) ?? '',
          rendu: (BuildContext _, CompteAdmin c) =>
              PaysEnseignant(pays: c.paysEnseignant),
        ),
      if (role == null)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneRole,
          texte: (CompteAdmin c) =>
              c.role == null ? t.admin.comptes.roleInconnu : _nomRole(c.role!),
        ),
      ColonneDonnees<CompteAdmin>(
        titre: t.admin.comptes.colonneEtat,
        tri: tri(ChampTriComptes.etat),
        texte: (CompteAdmin c) => _libelleEtat(EtatAffiche.de(c)),
        rendu: (BuildContext _, CompteAdmin c) => StatusPill(
          libelle: _libelleEtat(EtatAffiche.de(c)),
          ton: _tonEtat(EtatAffiche.de(c)),
        ),
      ),
      if (role == AppRole.student)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneEnseignant,
          texte: (CompteAdmin c) => c.aEnseignant
              ? t.admin.comptes.enseignantOui
              : t.admin.comptes.enseignantAucun,
        ),
      if (role == AppRole.guardian)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneEnfants,
          tabulaire: true,
          texte: (CompteAdmin c) => '${c.enfantsDuFoyer}',
        ),
      // K-47 : seul l'enseignant depose une piece. Colonne rendue seulement si
      // une ligne de la liste en a une a dire.
      if (pieces)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonnePiece,
          // « Aucune piece deposee » preterait un manque qui n'existe pas au
          // tuteur, a l'eleve et au personnel. Un role illisible garde le
          // texte reel : on ne sait pas s'il en doit une.
          texte: (CompteAdmin c) => _pieceSansObjet(c)
              ? t.admin.comptes.pieceSansObjet
              : _nomPiece(c.piece),
        ),
      ColonneDonnees<CompteAdmin>(
        titre: t.admin.comptes.colonneAttente,
        tabulaire: true,
        tri: tri(ChampTriComptes.inscrit),
        // L'anciennete, pas la date : c'est elle qui appelle un geste.
        texte: (CompteAdmin c) => _attente(c.joursDAttente(DateTime.now())),
      ),
      if (contrats)
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneContrats,
          tabulaire: true,
          texte: (CompteAdmin c) => '${c.contrats}',
        ),
    ];
  }

  /// Vrai quand un dossier d'identite est a verifier : seule action
  /// **existante** qu'une ligne de compte peut porter (la meme navigation que
  /// le tableau de bord, `Routes.adminPersonnesDossiers` avec l'identifiant du
  /// profil en `extra`, jamais dans l'adresse).
  static bool _ouvreUnDossier(CompteAdmin c) =>
      c.role == AppRole.teacher && c.piece == EtatPiece.aVerifier;

  /// Le menu d'une ligne : rien (pas de menu vide) quand elle n'a pas d'action.
  Widget _actions(BuildContext context, CompteAdmin c) {
    if (!_ouvreUnDossier(c)) return const SizedBox.shrink();
    return MenuActions(
      points: true,
      objet: c.libelle,
      actions: <EntreeAction>[
        EntreeAction(
          libelle: t.admin.comptes.actionOuvrirDossier,
          icone: AppIcons.dossiers,
          onChoix: () =>
              GoRouter.of(context)
                  .go(Routes.adminPersonnesDossiers, extra: c.profilId),
        ),
      ],
    );
  }

  static String _attente(int jours) => switch (jours) {
    0 => t.admin.comptes.attendAujourdhui,
    1 => t.admin.comptes.attendUnJour,
    _ => LibellesGroupe.valeurSeule(t.admin.comptes.attendJours(jours: jours)),
  };
}

String _libelleEtat(EtatAffiche e) => switch (e) {
  EtatAffiche.attente => t.admin.comptes.etatEnAttente,
  EtatAffiche.sansDecision => t.admin.comptes.etatSansDecision,
  EtatAffiche.actif => t.admin.comptes.etatActif,
  EtatAffiche.provisoire => t.admin.comptes.etatProvisoire,
  EtatAffiche.suspendu => t.admin.comptes.etatSuspendu,
  EtatAffiche.inconnu => t.admin.comptes.etatInconnu,
};

TonEtat _tonEtat(EtatAffiche e) => switch (e) {
  EtatAffiche.attente => TonEtat.avertissement,
  EtatAffiche.actif => TonEtat.succes,
  EtatAffiche.suspendu => TonEtat.alerte,
  EtatAffiche.sansDecision ||
  EtatAffiche.provisoire ||
  EtatAffiche.inconnu => TonEtat.neutre,
};

/// Vrai quand la piece d'identite n'a pas de sens pour ce compte : le tuteur
/// (toujours) et les autres roles lisibles tant qu'ils n'en ont depose aucune.
bool _pieceSansObjet(CompteAdmin c) =>
    c.role == AppRole.guardian ||
    (c.role != null &&
        c.role != AppRole.teacher &&
        c.piece == EtatPiece.aucune);

/// Le role au pluriel, pour sa puce de filtre.
String _nomRolePluriel(AppRole role) => switch (role) {
  AppRole.admin => t.admin.comptes.rolesAdministration,
  AppRole.accountant => t.admin.comptes.rolesComptables,
  AppRole.controller => t.admin.comptes.rolesControleurs,
  AppRole.teacher => t.admin.comptes.rolesEnseignants,
  AppRole.guardian => t.admin.comptes.rolesTuteurs,
  AppRole.student => t.admin.comptes.rolesEleves,
};

String _nomRole(AppRole role) => switch (role) {
  AppRole.admin => t.admin.comptes.roleAdmin,
  AppRole.accountant => t.admin.comptes.roleComptable,
  AppRole.controller => t.admin.comptes.roleControleur,
  AppRole.teacher => t.admin.comptes.roleEnseignant,
  AppRole.guardian => t.admin.comptes.roleTuteur,
  AppRole.student => t.admin.comptes.roleEleve,
};

String _nomPiece(EtatPiece piece) => switch (piece) {
  EtatPiece.aucune => t.admin.comptes.pieceAucune,
  EtatPiece.aVerifier => t.admin.comptes.pieceAVerifier,
  EtatPiece.validee => t.admin.comptes.pieceValidee,
  EtatPiece.refusee => t.admin.comptes.pieceRefusee,
  EtatPiece.nonVisible => t.admin.comptes.pieceNonVisible,
};

/// Combien d'acces sont echus parmi [comptes].
int _nombreEchus(List<CompteAdmin> comptes, DateTime maintenant) =>
    comptes.where((CompteAdmin c) => c.accesEchu(maintenant)).length;

/// Donne a [child] au moins la hauteur lisible d'une collection, meme quand la
/// premiere mise en page de la page ne lui laisse que quelques dizaines de
/// points : la collection (en-tete, lignes, pied) deborderait alors le temps
/// d'une image, jusqu'a ce que `PageShell` ait bascule en defilement. Le trop
/// est rogne ; des que la page a donne la hauteur, rien n'est enveloppe.
class _HauteurLisible extends StatelessWidget {
  const _HauteurLisible({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double minimum = DataCollection.minimumLisible(context);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        if (!contraintes.hasBoundedHeight || contraintes.maxHeight >= minimum) {
          return child;
        }
        return ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minHeight: minimum,
            maxHeight: minimum,
            child: child,
          ),
        );
      },
    );
  }
}
