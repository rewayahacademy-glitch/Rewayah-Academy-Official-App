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
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/controle_segmente.dart';
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
import '../../core/widgets/selecteur_section.dart';
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
///
/// Trois choix de rendu, chacun paye par une raison :
///
///   * **ce qui attend une decision passe devant**, dans sa vue, et la vue
///     qui en contient s'ouvre d'elle-meme ;
///   * **l'anciennete est rendue, jamais la seule date**. « Depuis 7 jours »
///     est un fait qui appelle un geste ; « 11/09 » demande un calcul ;
///   * **une piece absente est un etat affiche**, pas une case vide.
///
/// **Comptes separes par role (directeur, 30/10/2026).** « Sur ce profil, il
/// y a des tuteurs, des enseignants, des eleves, mais l'application ne fait
/// pas de difference. » Quatre vues, choisies en haut ([SelecteurSection],
/// ONGLETS-1), chacune avec sa liste, ses colonnes, sa recherche, son tri et
/// sa page : Eleves (matricule, age, classe, tuteur), Familles (tuteurs et
/// eleves rattaches), Enseignants (pays, piece d'identite, contrats),
/// Direction (seulement si elle a des comptes). Le nombre de chaque vue est
/// compte dans les donnees lues.
///
/// **LISTES-1 (23/10/2026).** Aucun paragraphe avant les commandes ; table
/// dense a en-tete colle, triable, paginee ; filtres actifs retirables. La
/// lecture des comptes rend tout, sans recherche, tri ni total : tout cela se
/// fait ici, et un avertissement se montre quand le nombre recu atteint le
/// plafond du serveur ([plafondComptesServeur]). La vue, l'etat, les acces
/// echus et le tri vivent dans l'adresse ; le texte cherche, jamais (c'est le
/// nom d'une personne).
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

  /// Les parametres de l'adresse (`vue`, `etat`, `filtre`, `tri`) : la page
  /// les lit a l'ouverture et chaque fois que l'adresse change sans elle
  /// (retour arriere, entree « Comptes » de la navigation).
  final Map<String, String> requete;

  @override
  ConsumerState<ComptesPage> createState() => _ComptesPageEtat();
}

/// Les parametres d'adresse que cette page possede : les autres sont gardes.
/// `role` et `q` sont ceux d'anciens liens : lus une fois, puis retires.
const List<String> _clesAdresse = <String>[
  'vue',
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
  /// La vue choisie, ou nulle tant que personne n'en a choisi : la page ouvre
  /// alors celle qui contient une decision en attente.
  VueComptes? _vueChoisie;

  /// Le filtre, la recherche et le tri **de chaque vue** : changer de vue puis
  /// revenir retrouve la liste telle qu'on l'a laissee.
  final Map<VueComptes, FiltreComptes> _filtres = <VueComptes, FiltreComptes>{};

  /// La page courante de chaque vue, a partir de 0.
  final Map<VueComptes, int> _pages = <VueComptes, int>{};

  final TextEditingController _recherche = TextEditingController();

  /// L'attente qui suit la derniere frappe (ce n'est pas un mouvement).
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  int _taillePage = 50;

  /// La vue affichee au dernier rendu (celle que les gestes modifient).
  VueComptes _vue = VueComptes.eleves;

  @override
  void initState() {
    super.initState();
    _lireAdresse();
  }

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  FiltreComptes _filtreDe(VueComptes vue) =>
      _filtres[vue] ?? const FiltreComptes();

  /// Lit la vue et son filtre dans l'adresse. Une valeur inconnue est
  /// ignoree : une adresse partagee et perimee ne doit jamais casser la page.
  void _lireAdresse() {
    final Map<String, String> q = widget.requete;
    VueComptes? vue;
    for (final VueComptes v in VueComptes.values) {
      if (v.name == q['vue']) vue = v;
    }
    // Ancien lien `?role=` : la vue de ce role.
    if (vue == null) {
      for (final AppRole r in AppRole.values) {
        if (r.valeurSql == q['role']) {
          vue = switch (r) {
            AppRole.student => VueComptes.eleves,
            AppRole.guardian => VueComptes.familles,
            AppRole.teacher => VueComptes.enseignants,
            AppRole.admin ||
            AppRole.accountant ||
            AppRole.controller => VueComptes.direction,
          };
        }
      }
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
    final FiltreComptes filtre = FiltreComptes(
      etat: etat,
      echus: widget.echusSeulement || q['filtre'] == 'echus',
      recherche: q['q'] ?? '',
      tri: tri,
    );
    _vueChoisie = vue;
    _vueDefaut = null;
    _filtres.clear();
    _pages.clear();
    // Sans vue dans l'adresse, le filtre lu s'applique a la vue qui s'ouvrira
    // (choisie au premier rendu, une fois les comptes lus).
    _filtreAdresse = filtre;
    _recherche.text = filtre.recherche;
  }

  /// La vue ouverte par defaut, decidee au premier rendu des comptes.
  VueComptes? _vueDefaut;

  /// Le filtre lu dans l'adresse, pose sur la premiere vue rendue.
  FiltreComptes? _filtreAdresse;

  /// Le filtre dit en parametres d'adresse (seulement ce qui est pose).
  /// **Le texte cherche n'y est pas** : c'est le nom ou l'identifiant d'une
  /// personne, il n'a rien a faire dans une adresse.
  static Map<String, String> _enAdresse(VueComptes? vue, FiltreComptes f) =>
      <String, String>{
        'vue': ?vue?.name,
        if (f.etat != null) 'etat': f.etat!.name,
        if (f.echus) 'filtre': 'echus',
        if (f.tri != null)
          'tri': '${f.tri!.croissant ? '' : '-'}${f.tri!.champ.name}',
      };

  /// L'adresse porte la vue et le filtre, et go_router garde ce `State` d'une
  /// requete a l'autre : sans ce recalage, passer d'une adresse filtree a
  /// l'adresse nue (entree « Comptes » de la navigation) laissait l'ecran
  /// filtre.
  @override
  void didUpdateWidget(ComptesPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.echusSeulement == widget.echusSeulement &&
        mapEquals(ancien.requete, widget.requete)) {
      return;
    }
    final Map<String, String> actuelle = _enAdresse(
      _vueChoisie,
      _filtreDe(_vue),
    );
    final Map<String, String> nouvelle = <String, String>{
      for (final MapEntry<String, String> e in widget.requete.entries)
        if (_clesAdresse.contains(e.key) && e.key != 'q') e.key: e.value,
      if (widget.echusSeulement) 'filtre': 'echus',
    };
    if (mapEquals(actuelle, nouvelle)) return;
    _attenteSaisie?.cancel();
    setState(_lireAdresse);
  }

  /// Pose un nouveau filtre sur la vue courante : revient a sa premiere page,
  /// dit l'adresse.
  void _appliquer(FiltreComptes filtre) {
    setState(() {
      _vueChoisie = _vue;
      _filtres[_vue] = filtre;
      _pages[_vue] = 0;
    });
    _ecrireAdresse();
  }

  /// Change de vue : la recherche de l'autre vue revient dans le champ.
  void _choisirVue(VueComptes vue) {
    _attenteSaisie?.cancel();
    setState(() {
      _vueChoisie = vue;
      _vue = vue;
      _recherche.text = _filtreDe(vue).recherche;
    });
    _ecrireAdresse();
  }

  /// Reporte la vue et son filtre dans l'adresse (lien partage, retour
  /// arriere, rechargement). Hors routeur (tests montes sans GoRouter), rien
  /// a faire.
  void _ecrireAdresse() {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) return;
    final Uri actuelle = routeur.routerDelegate.currentConfiguration.uri;
    final Map<String, String> requete = <String, String>{
      for (final MapEntry<String, String> e in actuelle.queryParameters.entries)
        if (!_clesAdresse.contains(e.key)) e.key: e.value,
      ..._enAdresse(_vueChoisie, _filtreDe(_vue)),
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
      if (mounted) _appliquer(_filtreDe(_vue).avec(recherche: texte));
    });
  }

  void _chercherTout(String texte) {
    _attenteSaisie?.cancel();
    _appliquer(_filtreDe(_vue).avec(recherche: texte));
  }

  void _effacerRecherche() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _appliquer(_filtreDe(_vue).avec(recherche: ''));
  }

  void _toutEffacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _appliquer(_filtreDe(_vue).efface);
  }

  void _trier(ChampTriComptes champ) {
    final FiltreComptes f = _filtreDe(_vue);
    final TriComptes? suivant = TriComptes.suivant(f.tri, champ);
    _appliquer(suivant == null ? f.avec(sansTri: true) : f.avec(tri: suivant));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);

    return PageShell(
      titre: t.admin.comptes.titre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 1),
      // LISTES-2 (directeur, 30/10/2026) : la tete de la page (retour,
      // « Comptes ▾ », actions) defile avec la liste, qui la prend
      // (`DataCollection.prendTeteDePage`). Rien de fixe au-dessus des
      // lignes, sauf la barre de l'application.
      teteAvecLaListe: true,
      // `DataCollection` porte son propre defilement.
      defilante: false,
      child: ColonneCorps(
        children: <Widget>[
          Expanded(
            // `BlocAsynchrone` porte les etats chargement, chargement
            // prolonge, echec (avec « Reessayer ») et indisponibilite ; le
            // hors ligne est le bandeau de `PageShell`.
            child: BlocAsynchrone<List<CompteAdmin>>(
              valeur: comptes,
              squelette: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints contraintes) {
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

  /// La vue qui s'ouvre quand personne n'en a choisi : celle des acces echus
  /// si la page est ouverte sur eux, sinon celle qui attend une decision.
  VueComptes _vueParDefaut(List<CompteAdmin> comptes) {
    final FiltreComptes? lu = _filtreAdresse;
    if (lu != null && lu.echus) {
      final DateTime maintenant = DateTime.now();
      for (final VueComptes vue in VueComptes.values) {
        if (comptes.any(
          (CompteAdmin c) =>
              VueComptes.de(c).contains(vue) && c.accesEchu(maintenant),
        )) {
          return vue;
        }
      }
    }
    return VueComptes.parDefaut(comptes);
  }

  /// Les commandes (qui defilent avec la liste), puis les lignes.
  Widget _corps(List<CompteAdmin> comptes) {
    final DateTime maintenant = DateTime.now();
    // La vue par defaut se decide une fois par adresse lue : une relecture
    // des comptes ne fait pas sauter l'ecran d'une vue a l'autre.
    _vue = _vueChoisie ?? (_vueDefaut ??= _vueParDefaut(comptes));
    final FiltreComptes? lu = _filtreAdresse;
    if (lu != null) {
      _filtres[_vue] = lu;
      _filtreAdresse = null;
    }
    final FiltreComptes filtre = _filtreDe(_vue);

    final Map<VueComptes, List<CompteAdmin>> parVue =
        <VueComptes, List<CompteAdmin>>{
          for (final VueComptes v in VueComptes.values) v: <CompteAdmin>[],
        };
    for (final CompteAdmin c in comptes) {
      for (final VueComptes v in VueComptes.de(c)) {
        parVue[v]!.add(c);
      }
    }
    final List<CompteAdmin> deLaVue = parVue[_vue]!;
    final List<CompteAdmin> visibles = filtre.appliquer(
      deLaVue,
      maintenant,
      libelleEtat: _libelleEtat,
    );

    final int taille = _taillePage;
    final int pages = visibles.isEmpty
        ? 1
        : (visibles.length + taille - 1) ~/ taille;
    final int page = (_pages[_vue] ?? 0).clamp(0, pages - 1);
    final int debut = page * taille;
    final int fin = (debut + taille).clamp(0, visibles.length);

    // La vue Direction n'est proposee que si elle a des comptes (ou si elle
    // est ouverte) : une vue toujours vide serait un faux choix.
    final List<VueComptes> vues = <VueComptes>[
      for (final VueComptes v in VueComptes.values)
        if (v != VueComptes.direction ||
            parVue[v]!.isNotEmpty ||
            _vue == VueComptes.direction)
          v,
    ];

    final bool detailsAbsents =
        _vue == VueComptes.eleves &&
        deLaVue.isNotEmpty &&
        deLaVue.any((CompteAdmin c) => !c.detailsServis);

    final Widget? synthese = _synthese(comptes);
    final Widget commandes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
        if (detailsAbsents) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('comptes-details-absents'),
            titre: t.admin.comptes.detailsAbsentsTitre,
            message: t.admin.comptes.detailsAbsentsMessage,
            ton: TonEtat.avertissement,
          ),
          Ecart.vSm,
        ],
        _rangeeCommandes(
          SelecteurSection<VueComptes>(
            key: const ValueKey<String>('comptes-vues'),
            libelle: t.admin.comptes.vues,
            valeur: _vue,
            onChange: _choisirVue,
            sections: <Segment<VueComptes>>[
              for (final VueComptes v in vues)
                Segment<VueComptes>(
                  valeur: v,
                  libelle: t.admin.comptes.vueNombre(
                    vue: _nomVue(v),
                    n: '${parVue[v]!.length}',
                  ),
                ),
            ],
          ),
          (bool etroit) =>
              _filtresVue(deLaVue, maintenant, filtre, etroit: etroit),
          filtre,
        ),
        if (synthese != null) ...<Widget>[Ecart.vSm, synthese],
        _filtresActifs(filtre),
        Ecart.vSm,
      ],
    );

    if (deLaVue.isEmpty || visibles.isEmpty) {
      // Sans ligne, pas de liste pour prendre la tete : la page fait defiler
      // sa tete et ce corps ensemble.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          commandes,
          if (deLaVue.isEmpty)
            EmptyState(
              key: ValueKey<String>('comptes-vide-${_vue.name}'),
              message: _videVue(_vue),
              invitation: t.admin.comptes.videDetail,
              registre: RegistreVide.subi,
              icone: AppIcons.rienAAfficher,
            )
          else
            EmptyState(
              message: t.admin.comptes.aucunAvecCeFiltre,
              invitation: t.admin.comptes.aucunAvecCeFiltreDetail,
              registre: RegistreVide.subi,
              icone: AppIcons.rienAAfficher,
            ),
        ],
      );
    }

    return DataCollection<CompteAdmin>(
      key: ValueKey<String>('comptes-table-${_vue.name}-$page-$taille'),
      prendTeteDePage: true,
      tete: commandes,
      densiteTelephone: true,
      lignes: visibles.sublist(debut, fin),
      cle: (CompteAdmin c) => ValueKey<String>(c.profilId),
      colonnes: _colonnes(visibles, filtre),
      // Une colonne d'actions seulement si au moins un compte de la vue en a
      // une, jugee sur toute la liste (la largeur ne saute pas d'une page a
      // l'autre).
      actionsLigne: visibles.any(_ouvreUnDossier) ? _actions : null,
      // PAS DE SELECTION MULTIPLE (LISTES-1 §5.6) : aucune operation groupee
      // fiable n'existe pour des comptes. Une case sans geste groupe serait un
      // faux controle.
      piedCollant: PiedDeListe(
        debut: debut + 1,
        fin: fin,
        total: visibles.length,
        onPrecedent: page > 0
            ? () => setState(() => _pages[_vue] = page - 1)
            : null,
        onSuivant: fin < visibles.length
            ? () => setState(() => _pages[_vue] = page + 1)
            : null,
        taillePage: taille,
        taillesProposees: _taillesPage,
        onTaillePage: (int n) => setState(() {
          _taillePage = n;
          _pages.clear();
        }),
      ),
    );
  }

  /// Les filtres de la vue : l'etat en menu, les acces echus. Nul quand
  /// aucun n'offre de choix (un controle sans choix n'est pas un controle).
  Widget? _filtresVue(
    List<CompteAdmin> deLaVue,
    DateTime maintenant,
    FiltreComptes filtre, {
    required bool etroit,
  }) {
    final Map<EtatAffiche, int> parEtat = <EtatAffiche, int>{};
    for (final CompteAdmin c in deLaVue) {
      final EtatAffiche e = EtatAffiche.de(c);
      parEtat[e] = (parEtat[e] ?? 0) + 1;
    }
    final int echus = deLaVue
        .where((CompteAdmin c) => c.accesEchu(maintenant))
        .length;
    final bool menuEtat = parEtat.length > 1 || filtre.etat != null;
    final bool puceEchus = filtre.echus || echus > 0;
    // LISTES-2 : l'exception qui appelle un geste (une decision attendue) est
    // une puce, en tete de la rangee : un toucher retient « En attente ».
    final int attendent = parEtat[EtatAffiche.attente] ?? 0;
    // Etroit (telephone), la rangee n'a la place que du menu d'etat : la
    // ligne en attente porte sa puce, passe en tete, et le menu « État »
    // propose « En attente ».
    final bool puceAttente = attendent > 0 && !etroit;
    if (!menuEtat && !puceEchus && !puceAttente) return null;

    return RangeeFiltres(
      replier: false,
      filtres: <Widget>[
        if (puceAttente)
          FilterPill(
            key: const ValueKey<String>('comptes-attente'),
            libelle: t.admin.comptes.etatEnAttente,
            compteur: attendent,
            retenue: filtre.etat == EtatAffiche.attente,
            onPress: () => _appliquer(
              filtre.etat == EtatAffiche.attente
                  ? filtre.avec(sansEtat: true)
                  : filtre.avec(etat: EtatAffiche.attente),
            ),
          ),
        if (menuEtat)
          MenuFiltre<EtatAffiche>(
            key: const ValueKey<String>('comptes-filtre-etat'),
            libelle: t.admin.comptes.filtreEtat,
            valeur: filtre.etat,
            onChoix: (EtatAffiche? e) => _appliquer(
              e == null ? filtre.avec(sansEtat: true) : filtre.avec(etat: e),
            ),
            entrees: <EntreeFiltre<EtatAffiche>>[
              EntreeFiltre<EtatAffiche>(
                valeur: null,
                libelle: t.admin.comptes.filtreTousLesEtats,
                compteur: deLaVue.length,
              ),
              for (final EtatAffiche e in EtatAffiche.values)
                if (parEtat.containsKey(e) || filtre.etat == e)
                  EntreeFiltre<EtatAffiche>(
                    valeur: e,
                    libelle: _libelleEtat(e),
                    compteur: parEtat[e] ?? 0,
                  ),
            ],
          ),
        // DASH-ADM-ECHUS : les acces echus de la vue, rendus des qu'il y en
        // a, ou quand le filtre est retenu (il doit pouvoir se relacher).
        if (puceEchus)
          FilterPill(
            key: const ValueKey<String>('comptes-filtre-echus'),
            libelle: t.admin.tableau.comptes,
            compteur: echus,
            retenue: filtre.echus,
            onPress: () => _appliquer(filtre.avec(echus: !filtre.echus)),
          ),
      ],
    );
  }

  /// LISTES-2 : **une seule rangee de commandes**. Au bureau : les vues
  /// (segmentees si elles tiennent), les filtres, la recherche a droite.
  /// Etroit : les vues (en menu quand elles ne tiennent pas, ONGLETS-1), les
  /// filtres, et une loupe qui ouvre la recherche a la demande, sous la
  /// rangee ; elle reste ouverte tant qu'un texte est cherche.
  Widget _rangeeCommandes(
    Widget vues,
    Widget? Function(bool etroit) filtresSelon,
    FiltreComptes filtre,
  ) {
    final Widget recherche = ChampRecherche(
      cleChamp: const ValueKey<String>('comptes-recherche'),
      cleEffacer: const ValueKey<String>('comptes-recherche-effacer'),
      controleur: _recherche,
      libelle: t.admin.comptes.recherche,
      aide: _vue == VueComptes.eleves
          ? t.admin.comptes.rechercheAideEleves
          : t.admin.comptes.rechercheAide,
      onChange: _chercher,
      onValider: _chercherTout,
    );
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final bool etroit = contraintes.maxWidth < _largeurUneRangee;
        final Widget? filtres = filtresSelon(etroit);
        if (!etroit) {
          return Row(
            children: <Widget>[
              if (filtres != null) ...<Widget>[
                Flexible(flex: 3, child: vues),
                Ecart.hMd,
                Flexible(flex: 2, child: filtres),
              ] else
                Expanded(child: vues),
              Ecart.hMd,
              SizedBox(width: _largeurRecherche, child: recherche),
            ],
          );
        }
        final bool ouverte =
            _rechercheOuverte || filtre.recherche.trim().isNotEmpty;
        // Texte agrandi (au-dela de 130 %) : les filtres passent sous la
        // rangee des vues, qui garderait sinon trop peu de place (320 x2).
        final bool grandTexte =
            MediaQuery.textScalerOf(contexte).scale(1) > 1.3;
        final Widget loupe = BoutonIcone(
          key: const ValueKey<String>('comptes-loupe'),
          icone: AppIcons.recherche,
          libelle: t.admin.comptes.recherche,
          selectionne: ouverte,
          onPress: () => setState(() => _rechercheOuverte = !_rechercheOuverte),
        );
        if (grandTexte) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: vues),
                  Ecart.hSm,
                  loupe,
                ],
              ),
              if (filtres != null) ...<Widget>[Ecart.vSm, filtres],
              if (ouverte) ...<Widget>[Ecart.vSm, recherche],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (filtres != null) ...<Widget>[
                  Flexible(flex: 3, child: vues),
                  Ecart.hSm,
                  Flexible(flex: 2, child: filtres),
                ] else
                  Expanded(child: vues),
                Ecart.hSm,
                loupe,
              ],
            ),
            if (ouverte) ...<Widget>[Ecart.vSm, recherche],
          ],
        );
      },
    );
  }

  /// Vrai quand la loupe a ouvert la recherche (rangee etroite).
  bool _rechercheOuverte = false;

  /// En dessous, la recherche passe derriere la loupe.
  static const double _largeurUneRangee = 900;

  /// La largeur de la recherche quand elle partage sa rangee.
  static const double _largeurRecherche = 320;

  /// Les filtres en cours, retirables un a un.
  Widget _filtresActifs(FiltreComptes filtre) => FiltresActifs(
    filtres: <FiltreActif>[
      if (filtre.etat != null)
        FiltreActif(
          libelle: t.admin.comptes.filtreActifEtat(
            valeur: _libelleEtat(filtre.etat!),
          ),
          onRetirer: () => _appliquer(filtre.avec(sansEtat: true)),
        ),
      if (filtre.echus)
        FiltreActif(
          libelle: t.admin.tableau.comptes,
          onRetirer: () => _appliquer(filtre.avec(echus: false)),
        ),
      if (filtre.recherche.trim().isNotEmpty)
        FiltreActif(
          libelle: t.admin.comptes.filtreActifRecherche(
            texte: filtre.recherche.trim(),
          ),
          onRetirer: _effacerRecherche,
        ),
    ],
    onToutEffacer: _toutEffacer,
  );

  /// La seule phrase qui reste au-dessus des lignes, et seulement quand elle
  /// a lieu d'etre : un compte au role illisible n'entre dans aucune vue.
  /// Le nombre de comptes est dans le choix de la vue et le pied (« 1-28 sur
  /// 28 ») ; ce qui attend une decision est la puce « En attente » de la
  /// rangee des filtres (LISTES-2).
  Widget? _synthese(List<CompteAdmin> comptes) {
    final int roleIllisible = comptes
        .where((CompteAdmin c) => c.role == null)
        .length;
    if (roleIllisible == 0) return null;
    return Text(
      roleIllisible == 1
          ? t.admin.comptes.roleIllisibleUn
          : t.admin.comptes.roleIllisiblePlusieurs(nombre: '$roleIllisible'),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Les colonnes de la vue : chacune dit ce qui sert a cette population,
  /// rien de vide, rien d'inutile.
  List<ColonneDonnees<CompteAdmin>> _colonnes(
    List<CompteAdmin> visibles,
    FiltreComptes filtre,
  ) {
    // Sous masquage d'identite, le libelle est l'identifiant : la colonne
    // « Identifiant » afficherait deux fois la meme valeur.
    final bool identitesConnues = visibles.any(
      (CompteAdmin c) => c.prenom != null,
    );

    TriColonne tri(ChampTriComptes champ) => TriColonne(
      sens: filtre.tri?.champ == champ
          ? (filtre.tri!.croissant ? SensTri.croissant : SensTri.decroissant)
          : null,
      onTrier: () => _trier(champ),
    );

    final ColonneDonnees<CompteAdmin> personne = ColonneDonnees<CompteAdmin>(
      titre: t.admin.comptes.colonnePersonne,
      role: RoleColonne.identifiante,
      flex: 2,
      tri: tri(ChampTriComptes.nom),
      texte: (CompteAdmin c) => c.libelle == c.identifiant
          ? identifiantInsecable(c.identifiant)
          : c.libelle,
    );
    final ColonneDonnees<CompteAdmin>? identifiant = identitesConnues
        ? ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneIdentifiant,
            texte: (CompteAdmin c) => identifiantInsecable(c.identifiant),
          )
        : null;
    // LISTES-2 : seule l'exception s'affiche ; « Actif » ne se repete pas sur
    // chaque ligne (la cellule reste vide, le filtre d'etat le garde).
    String exception(CompteAdmin c) {
      final EtatAffiche e = EtatAffiche.de(c);
      return e == EtatAffiche.actif ? '' : _libelleEtat(e);
    }

    final ColonneDonnees<CompteAdmin> etat = ColonneDonnees<CompteAdmin>(
      titre: t.admin.comptes.colonneEtat,
      tri: tri(ChampTriComptes.etat),
      texte: exception,
      rendu: (BuildContext _, CompteAdmin c) => exception(c).isEmpty
          ? const SizedBox.shrink()
          : StatusPill(libelle: exception(c), ton: _tonEtat(EtatAffiche.de(c))),
    );
    final ColonneDonnees<CompteAdmin> inscrit = ColonneDonnees<CompteAdmin>(
      titre: t.admin.comptes.colonneAttente,
      // LISTES-2 : la ligne dense du telephone garde l'essentiel.
      ligneDense: false,
      tabulaire: true,
      tri: tri(ChampTriComptes.inscrit),
      // L'anciennete, pas la date : c'est elle qui appelle un geste.
      texte: (CompteAdmin c) => _attente(c.joursDAttente(DateTime.now())),
    );

    return switch (_vue) {
      VueComptes.eleves => <ColonneDonnees<CompteAdmin>>[
        personne,
        ?identifiant,
        // Rendues seulement quand le serveur les sert : sinon le bandeau dit
        // ce qui manque, et aucune colonne n'affiche un vide trompeur.
        if (visibles.any(
          (CompteAdmin c) => c.detailsServis,
        )) ...<ColonneDonnees<CompteAdmin>>[
          ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneTranche,
            // Telephone : « matricule · classe · tuteur » (pilote, 30/10).
            ligneDense: false,
            texte: (CompteAdmin c) => switch (c.tranche) {
              TrancheAge.enfant => t.admin.comptes.trancheEnfant,
              TrancheAge.adulte => t.admin.comptes.trancheAdulte,
              null => t.admin.comptes.trancheInconnue,
            },
          ),
          ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneClasse,
            flex: 2,
            texte: _classe,
          ),
          ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneTuteur,
            texte: (CompteAdmin c) =>
                c.tuteurLibelle ??
                (c.tuteurId == null ? t.admin.comptes.tuteurAucun : ''),
          ),
        ],
        etat,
        inscrit,
      ],
      VueComptes.familles => <ColonneDonnees<CompteAdmin>>[
        personne,
        ?identifiant,
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneElevesRattaches,
          tabulaire: true,
          texte: (CompteAdmin c) => '${c.enfantsDuFoyer}',
        ),
        etat,
        inscrit,
      ],
      VueComptes.enseignants => <ColonneDonnees<CompteAdmin>>[
        personne,
        ?identifiant,
        // ENS-PAYS-1 : seulement quand une ligne au moins le porte.
        if (visibles.any(
          (CompteAdmin c) =>
              PaysEnseignant.nomAffichable(c.paysEnseignant) != null,
        ))
          ColonneDonnees<CompteAdmin>(
            titre: t.enseignant.profil.pays,
            role: RoleColonne.aPart,
            texte: (CompteAdmin c) =>
                PaysEnseignant.nomAffichable(c.paysEnseignant) ?? '',
            rendu: (BuildContext _, CompteAdmin c) =>
                PaysEnseignant(pays: c.paysEnseignant),
          ),
        etat,
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonnePiece,
          texte: (CompteAdmin c) => _nomPiece(c.piece),
        ),
        inscrit,
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneContrats,
          tabulaire: true,
          ligneDense: false,
          texte: (CompteAdmin c) => '${c.contrats}',
        ),
      ],
      VueComptes.direction => <ColonneDonnees<CompteAdmin>>[
        personne,
        ?identifiant,
        ColonneDonnees<CompteAdmin>(
          titre: t.admin.comptes.colonneRole,
          texte: (CompteAdmin c) =>
              c.role == null ? t.admin.comptes.roleInconnu : _nomRole(c.role!),
        ),
        etat,
        inscrit,
      ],
    };
  }

  /// La classe d'un eleve, et combien d'autres il suit.
  static String _classe(CompteAdmin c) {
    final String? nom = nomClasseEleve(c);
    if (nom == null) return t.admin.comptes.classeAucune;
    final int autres = c.classesActives - 1;
    return autres > 0
        ? t.admin.comptes.classeEtAutres(n: autres, classe: nom)
        : nom;
  }

  /// Vrai quand un dossier d'identite est a verifier : seule action
  /// **existante** qu'une ligne de compte peut porter (la meme navigation que
  /// le tableau de bord, l'identifiant du profil en `extra`, jamais dans
  /// l'adresse).
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

String _nomVue(VueComptes v) => switch (v) {
  VueComptes.eleves => t.admin.comptes.vueEleves,
  VueComptes.familles => t.admin.comptes.vueFamilles,
  VueComptes.enseignants => t.admin.comptes.vueEnseignants,
  VueComptes.direction => t.admin.comptes.vueDirection,
};

String _videVue(VueComptes v) => switch (v) {
  VueComptes.eleves => t.admin.comptes.videEleves,
  VueComptes.familles => t.admin.comptes.videFamilles,
  VueComptes.enseignants => t.admin.comptes.videEnseignants,
  VueComptes.direction => t.admin.comptes.videDirection,
};

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
