import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/personnes_modifiees.dart';
import '../../core/admin/port_fondateurs.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/admission/port_admissions_direction.dart'
    show PopulationAdmission;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_retraits_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/pays_iso.dart' show nomDuPays;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/lieu/lieu_direction.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/local_feedback.dart';
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
import '../foyer/photo_eleve.dart';
import '../mfa_controleur/double_verification.dart';
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

  /// SUPPRIMER : la barre des comptes choisis.
  static const Key barreSuppressionKey = ValueKey<String>(
    'comptes-barre-suppression',
  );

  /// Le resultat d'une suppression et la limite d'une selection, dans le fil
  /// de la page, au-dessus de la liste (SANS-BARRE-FIXE).
  static const Key avisSuppressionKey = ValueKey<String>(
    'comptes-avis-suppression',
  );

  /// SUPPRIMER : « Supprimer n comptes », dans la barre.
  static const Key supprimerSelectionKey = ValueKey<String>(
    'comptes-supprimer-selection',
  );

  /// SUPPRIMER : ce que la derniere suppression a donne.
  static const Key bilanKey = ValueKey<String>('comptes-bilan-suppression');

  /// SUPPRIMER : « Fermer » sous le resultat.
  static const Key fermerBilanKey = ValueKey<String>('comptes-bilan-fermer');

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

  // 25 par defaut, comme Classes (relecture du pilote, PR 126) ; §5.3 fixe
  // le choix 25, 50 ou 100, pas la valeur de depart.
  int _taillePage = 25;

  /// La vue affichee au dernier rendu (celle que les gestes modifient).
  VueComptes _vue = VueComptes.eleves;

  /// LISTES-3 : au bureau, le panneau des filtres et de la recherche est
  /// deplie.
  bool _filtresOuverts = false;

  /// SUPPRIMER : les comptes choisis (DECISION-LISTES §6). Un changement de
  /// page ou de tri les garde ; un filtre, une recherche ou une vue qui
  /// change les retire, avec un message. Gardes par identifiant, avec leur
  /// nom pour la confirmation et le resultat.
  final Map<String, CompteAdmin> _choisis = <String, CompteAdmin>{};

  /// Le serveur supprime au plus 200 comptes par appel
  /// (`direction_supprimer_comptes`).
  static const int _plafondSuppression = 200;

  /// Une suppression est partie et n'a pas encore de reponse.
  bool _suppressionEnCours = false;

  /// Ce que la derniere suppression a donne, dit en tete de la liste.
  _BilanSuppression? _bilan;

  /// V2-e : les fondateurs connus au dernier rendu, ou `null` tant que le
  /// serveur ne les a pas rendus (alors la coche n'est pas proposee).
  Set<String>? _fondateurs;

  /// Les villes des enseignants et ce qui ne concorde pas (HORLOGE-ET-LIEU) :
  /// lues seulement dans la vue des enseignants.
  Map<String, LieuEnseignantDirection> _lieux =
      const <String, LieuEnseignantDirection>{};
  List<IncoherenceLieu> _incoherences = const <IncoherenceLieu>[];

  /// V2-e : le retour local de la coche fondateur.
  String? _retour;

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
    final FiltreComptes avant = _filtreDe(_vue);
    final bool memesLignes =
        avant.etat == filtre.etat &&
        avant.echus == filtre.echus &&
        avant.recherche == filtre.recherche;
    setState(() {
      if (!memesLignes) _relacherAvecMessage();
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
      if (vue != _vue) _relacherAvecMessage();
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
    _fondateurs = ref.watch(fondateursProvider).value;
    // La selection se recale sur la liste lue avant que la barre (collee en
    // bas, hors du corps) ne la dise.
    if (comptes.hasValue) _tranche(comptes.requireValue);
    // HORLOGE-ET-LIEU : la vue n'est connue qu'apres `_tranche`.
    if (_vue == VueComptes.enseignants) {
      _lieux =
          ref.watch(lieuxEnseignantsProvider).value ??
          const <String, LieuEnseignantDirection>{};
      _incoherences =
          ref.watch(incoherencesLieuProvider).value ??
          const <IncoherenceLieu>[];
    }

    final bool barreCollee = _barreCollee(context);
    return PageShell(
      titre: t.admin.comptes.titre,
      // §5 quater.10 bis : en menu, la sous-navigation prend la largeur de
      // son contenu, pas toute la rangee (pilote, relecture de la PR 126).
      entete: SousNavigationDomaine(
        onglets: ongletsPersonnes(),
        indexActif: 1,
        menuAuContenu: true,
      ),
      // LISTES-2 (directeur, 30/10/2026) : la tete de la page (retour,
      // « Comptes ▾ », actions) defile avec la liste, qui la prend
      // (`DataCollection.prendTeteDePage`). Rien de fixe au-dessus des
      // lignes, sauf la barre de l'application.
      teteAvecLaListe: true,
      // LISTES-3 (§5 quater, lot L2) : pleine largeur au bureau, pas de
      // retour (la barre laterale navigue), filtres derriere une icone.
      listeBureau: true,
      actionsEntete: <Widget>[
        if (DataCollection.enTableau(context))
          RangeeFiltres.bascule(
            key: const ValueKey<String>('comptes-bascule-filtres'),
            ouverts: _filtresOuverts,
            retenus: _retenus(_filtreDe(_vue)),
            onBasculer: () =>
                setState(() => _filtresOuverts = !_filtresOuverts),
          ),
      ],
      // `DataCollection` porte son propre defilement.
      defilante: false,
      // DECISION-LISTES §6 : la barre de selection et le resultat flottent
      // au-dessus du pied de liste ; rien ne pousse le tableau.
      // Option (A) du garde-cap (07/11) : a partir de 640 px, la barre de
      // selection tient sur une ligne et reste collee sous la liste ; sur
      // telephone, ou elle prend deux lignes (BarreSelection C-26), elle
      // vient dans le fil, en tete de la liste.
      actions: barreCollee ? _zoneSuppression() : null,
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

  /// La vue, son filtre et la page affichee, pour [comptes]. Appelee par
  /// `build` avant la page (la barre de selection, collee en bas, dit le
  /// compte de la page) puis par le corps : le meme calcul, sans effet de
  /// plus au second appel.
  _Tranche _tranche(List<CompteAdmin> comptes) {
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
    final List<CompteAdmin> lignesPage = visibles.sublist(debut, fin);
    // Un compte choisi qui n'est plus dans la liste filtree (supprime
    // ailleurs, relu autrement) quitte la selection : jamais un geste sur une
    // ligne que la liste ne contient plus.
    _choisis.removeWhere(
      (String id, CompteAdmin _) =>
          !visibles.any((CompteAdmin c) => c.profilId == id),
    );
    _choisisSurLaPage = lignesPage
        .where((CompteAdmin c) => _choisis.containsKey(c.profilId))
        .length;

    return (
      maintenant: maintenant,
      filtre: filtre,
      parVue: parVue,
      deLaVue: deLaVue,
      visibles: visibles,
      taille: taille,
      page: page,
      debut: debut,
      fin: fin,
      lignesPage: lignesPage,
    );
  }

  /// Les commandes (qui defilent avec la liste), puis les lignes.
  Widget _corps(List<CompteAdmin> comptes) {
    final _Tranche tr = _tranche(comptes);
    final DateTime maintenant = tr.maintenant;
    final FiltreComptes filtre = tr.filtre;
    final Map<VueComptes, List<CompteAdmin>> parVue = tr.parVue;
    final List<CompteAdmin> deLaVue = tr.deLaVue;
    final List<CompteAdmin> visibles = tr.visibles;
    final int taille = tr.taille;
    final int page = tr.page;
    final int debut = tr.debut;
    final int fin = tr.fin;
    final List<CompteAdmin> lignesPage = tr.lignesPage;

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

    final bool bureau = DataCollection.enTableau(context);
    _suppressionOfferte = bureau || !AppMetriques.of(context).estEnfant;
    final int attendent = deLaVue
        .where((CompteAdmin c) => EtatAffiche.de(c) == EtatAffiche.attente)
        .length;
    final Widget? filtresPanneau = bureau && _filtresOuverts
        ? _filtresVue(deLaVue, maintenant, filtre, etroit: false, panneau: true)
        : null;
    final Widget vuesChoix = SelecteurSection<VueComptes>(
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
    );
    final Widget? synthese = _synthese(comptes);
    final Widget commandes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LocalFeedback(message: _retour),
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
        if (_vue == VueComptes.enseignants &&
            _incoherences.isNotEmpty) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('comptes-villes-a-verifier'),
            titre:
                '${t.lieu.incoherencesTitre} \u00b7 '
                '${t.lieu.incoherencesCompte(n: _incoherences.length)}',
            message: _incoherences
                .take(5)
                .map(
                  (IncoherenceLieu i) =>
                      '${i.enseignant}\u00a0: ${_texteIncoherence(i.type)}',
                )
                .join('\n'),
            ton: TonEtat.avertissement,
          ),
          Ecart.vSm,
        ],
        if (bureau) ...<Widget>[
          // LISTES-3 (bureau) : les vues sur la rangee ; recherche et filtres
          // en panneau, derriere l'icone de la tete. LISTES-2 : la decision
          // attendue reste une puce visible, a cote des vues.
          if (attendent > 0)
            Row(
              children: <Widget>[
                Flexible(child: vuesChoix),
                Ecart.hMd,
                _puceAttente(filtre, attendent),
              ],
            )
          else
            vuesChoix,
          if (_filtresOuverts) ...<Widget>[
            Ecart.vMd,
            SizedBox(width: _largeurRecherche, child: _champRecherche()),
            if (filtresPanneau != null) ...<Widget>[Ecart.vMd, filtresPanneau],
          ],
        ] else
          _rangeeCommandes(
            vuesChoix,
            (bool etroit) =>
                _filtresVue(deLaVue, maintenant, filtre, etroit: etroit),
            filtre,
          ),
        if (synthese != null) ...<Widget>[Ecart.vSm, synthese],
        _filtresActifs(filtre),
        Ecart.vSm,
        // SANS-BARRE-FIXE (garde-cap, 07/11) : ce qui se dit de la
        // suppression et, sous 640 px, la barre de selection sont en tete de
        // la liste ET defilent avec elle : rien d'epingle au-dessus des
        // lignes, aucune ligne cachee.
        if (_avisSuppression() case final Widget avis) ...<Widget>[
          avis,
          Ecart.vMd,
        ],
        if (!_barreCollee(context))
          if (_zoneSuppression() case final Widget barre) ...<Widget>[
            barre,
            Ecart.vMd,
          ],
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
      // LISTES-3 (§5 quater) : au bureau, des cartes espacees.
      lignesCartes: true,
      lignes: lignesPage,
      cle: (CompteAdmin c) => ValueKey<String>(c.profilId),
      colonnes: _colonnes(visibles, filtre),
      // Une colonne d'actions seulement si au moins un compte de la vue en a
      // une, jugee sur toute la liste (la largeur ne saute pas d'une page a
      // l'autre).
      actionsLigne: visibles.any(_aUneAction) ? _actions : null,
      // SUPPRIMER (garde-cap, 03/11/2026) : l'operation groupee existe
      // (`direction_supprimer_comptes`), la case aussi (LISTES-1 §5.6). Seule
      // la page visible se coche ; un compte de la direction n'a pas de case.
      selection: lignesPage.any(_supprimableIci)
          ? SelectionCollection<CompteAdmin>(
              estCochee: (CompteAdmin c) => _choisis.containsKey(c.profilId),
              estCochable: _supprimable,
              onBasculer: (CompteAdmin c) => setState(() {
                _bilan = null;
                if (_choisis.remove(c.profilId) == null) {
                  _choisis[c.profilId] = c;
                }
              }),
              // « Cocher la page » : la page visible seulement, jamais tous
              // les resultats du filtre.
              onBasculerPage: (bool cocher) => setState(() {
                _bilan = null;
                for (final CompteAdmin c in lignesPage) {
                  if (!_supprimableIci(c)) continue;
                  if (cocher) {
                    _choisis[c.profilId] = c;
                  } else {
                    _choisis.remove(c.profilId);
                  }
                }
              }),
              libelleLigne: (CompteAdmin c) => c.libelle,
            )
          : null,
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
    bool panneau = false,
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
    // Au bureau (panneau), la puce vit a cote des vues, hors du panneau :
    // elle reste visible panneau ferme (`_puceAttente`).
    final bool puceAttente = attendent > 0 && !etroit && !panneau;
    if (!menuEtat && !puceEchus && !puceAttente) return null;

    return RangeeFiltres(
      replier: false,
      // LISTES-3 : au bureau, les filtres en panneau, derriere l'icone.
      enPanneau: panneau,
      filtres: <Widget>[
        if (puceAttente) _puceAttente(filtre, attendent),
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

  /// LISTES-2 : la decision attendue, une puce ; un toucher retient
  /// « En attente », un second le relache.
  Widget _puceAttente(FiltreComptes filtre, int attendent) => FilterPill(
    key: const ValueKey<String>('comptes-attente'),
    libelle: t.admin.comptes.etatEnAttente,
    compteur: attendent,
    retenue: filtre.etat == EtatAffiche.attente,
    onPress: () => _appliquer(
      filtre.etat == EtatAffiche.attente
          ? filtre.avec(sansEtat: true)
          : filtre.avec(etat: EtatAffiche.attente),
    ),
  );

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
    final Widget recherche = _champRecherche();
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) =>
          _rangeeSelon(
            contexte,
            contraintes,
            vues,
            filtresSelon,
            filtre,
            recherche,
          ),
    );
  }

  /// Le nombre de filtres retenus (l'etat, les acces echus, la recherche),
  /// dit par l'icone des filtres au bureau.
  static int _retenus(FiltreComptes f) =>
      (f.etat != null ? 1 : 0) +
      (f.echus ? 1 : 0) +
      (f.recherche.trim().isNotEmpty ? 1 : 0);

  /// Le champ de recherche de la vue.
  Widget _champRecherche() => ChampRecherche(
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

  /// La rangee de commandes selon la largeur offerte (voir
  /// [_rangeeCommandes]).
  Widget _rangeeSelon(
    BuildContext contexte,
    BoxConstraints contraintes,
    Widget vues,
    Widget? Function(bool etroit) filtresSelon,
    FiltreComptes filtre,
    Widget recherche,
  ) {
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
    final bool grandTexte = MediaQuery.textScalerOf(contexte).scale(1) > 1.3;
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
  }

  /// Vrai a partir de 640 px : la barre de selection tient sur une ligne et
  /// reste collee sous la liste ; sous ce seuil, elle vient en tete de la
  /// liste et defile avec elle (option (A) du garde-cap, 07/11).
  static bool _barreCollee(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= BarreSelection.largeurCoteACote;

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

    // LISTES-2 : seule l'exception s'affiche ; « Actif » ne se repete pas sur
    // chaque ligne (la cellule reste vide, le filtre d'etat le garde).
    String exception(CompteAdmin c) {
      final EtatAffiche e = EtatAffiche.de(c);
      return e == EtatAffiche.actif ? '' : _libelleEtat(e);
    }

    Widget? pastille(CompteAdmin c) => exception(c).isEmpty
        ? null
        : StatusPill(libelle: exception(c), ton: _tonEtat(EtatAffiche.de(c)));
    final bool bureau = DataCollection.enTableau(context);
    final ColonneDonnees<CompteAdmin> personne = ColonneDonnees<CompteAdmin>(
      titre: t.admin.comptes.colonnePersonne,
      role: RoleColonne.identifiante,
      // Au bureau (LISTES-3), le nom prend la largeur qu'il faut pour tenir
      // sur une ligne, comme Classes (relecture du pilote, PR 126).
      flex: bureau ? 3 : 2,
      tri: tri(ChampTriComptes.nom),
      texte: (CompteAdmin c) => c.libelle == c.identifiant
          ? identifiantInsecable(c.identifiant)
          : c.libelle,
      // LISTES-3 (bureau) : le cercle, le nom, l'exception d'etat dessous
      // dans la meme pastille qu'au telephone, comme Classes.
      rendu: bureau
          ? (BuildContext _, CompteAdmin c) => AvatarNom.enLigne(
              prenom: c.prenom ?? '',
              // PHOTOS-2a : la photo de la personne, vue par la direction.
              avatar: PhotoEleve(
                prenom: c.prenom ?? '',
                cleAvatar: null,
                personneId: c.profilId,
                diametre: AppAvatar.petit,
              ),
              nom: c.libelle == c.identifiant
                  ? identifiantInsecable(c.identifiant)
                  : c.libelle,
              diametre: AppAvatar.petit,
              roleWidget: pastille(c),
            )
          : null,
      // PHOTOS-B, arbitrage du pilote (06/11/2026) : au telephone, le meme
      // cercle avant le titre de la carte, qui garde sa taille et son repli
      // d'identifiant (gardes coupe-mots et hierarchie) ; l'etat garde sa
      // colonne de pastilles.
      portrait: bureau
          ? null
          // Une ligne sans nom (identite masquee : l'identifiant seul) n'a
          // pas de portrait : son identifiant garde toute la largeur.
          : (BuildContext _, CompteAdmin c) =>
                c.prenom == null || c.libelle == c.identifiant
                ? null
                : PhotoEleve(
                    prenom: c.prenom!,
                    cleAvatar: null,
                    personneId: c.profilId,
                    diametre: AppAvatar.petit,
                  ),
    );
    final ColonneDonnees<CompteAdmin>? identifiant = identitesConnues
        ? ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneIdentifiant,
            texte: (CompteAdmin c) => identifiantInsecable(c.identifiant),
          )
        : null;
    // Au bureau, l'etat est sous le nom (LISTES-3) ; le filtre « État » du
    // panneau et la puce « En attente » le gardent.
    final ColonneDonnees<CompteAdmin>? etat = bureau
        ? null
        : ColonneDonnees<CompteAdmin>(
            titre: t.admin.comptes.colonneEtat,
            tri: tri(ChampTriComptes.etat),
            texte: exception,
            rendu: (BuildContext _, CompteAdmin c) =>
                pastille(c) ?? const SizedBox.shrink(),
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
        ?etat,
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
        ?etat,
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
        ColonneDonnees<CompteAdmin>(
          titre: t.lieu.colonneVille,
          texte: _villeTexte,
        ),
        ?etat,
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
        ?etat,
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

  /// La ville d'un enseignant, et si la direction l'a verifiee.
  String _villeTexte(CompteAdmin c) {
    final LieuEnseignantDirection? l = _lieux[c.profilId];
    if (l == null) return t.lieu.villeAbsente;
    final String ligne = t.lieu.villeLigne(
      ville: l.ville,
      pays: nomDuPays(l.paysCode),
    );
    return l.verifie ? ligne : '$ligne \u00b7 ${t.lieu.nonVerifiee}';
  }

  /// Vrai quand la ville d'un enseignant attend la verification de la
  /// direction.
  bool _villeAVerifier(CompteAdmin c) =>
      _vue == VueComptes.enseignants &&
      c.role == AppRole.teacher &&
      (_lieux[c.profilId]?.verifie ?? true) == false;

  Future<void> _verifierVille(CompteAdmin c) async {
    String message;
    try {
      await ref.read(portLieuDirectionProvider).verifier(c.profilId);
      ref
        ..invalidate(lieuxEnseignantsProvider)
        ..invalidate(incoherencesLieuProvider);
      message = t.lieu.villeVerifiee(nom: c.libelle);
    } on Object {
      message = t.lieu.verifierEchec;
    }
    if (!mounted) return;
    setState(() => _retour = null);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) setState(() => _retour = message);
    });
  }

  /// Vrai quand un dossier d'identite est a verifier : seule action
  /// **existante** qu'une ligne de compte peut porter (la meme navigation que
  /// le tableau de bord, l'identifiant du profil en `extra`, jamais dans
  /// l'adresse).
  static bool _ouvreUnDossier(CompteAdmin c) =>
      c.role == AppRole.teacher && c.piece == EtatPiece.aVerifier;

  /// L2 des listes (constat du directeur, 01/11/2026) : une ligne « En
  /// attente » d'une demande d'admission porte l'action qui la debloque.
  static bool _ouvreUneDemande(CompteAdmin c) => c.admissionATraiter;

  /// Vrai quand la ligne a au moins une action.
  bool _aUneAction(CompteAdmin c) =>
      _ouvreUnDossier(c) ||
      _villeAVerifier(c) ||
      _ouvreUneDemande(c) ||
      _supprimableIci(c) ||
      _porteLaCoche(c);

  /// Au telephone en Interface guidee (cibles de 72), ni case ni « Supprimer
  /// ce compte » : une colonne de plus sur chaque ligne couperait
  /// l'identifiant (garde coupe-mots). La suppression se fait au bureau, ou
  /// en interface standard. Recalcule a chaque rendu.
  bool _suppressionOfferte = true;

  bool _supprimableIci(CompteAdmin c) => _suppressionOfferte && _supprimable(c);

  /// Les comptes choisis sur la page affichee, compte au dernier rendu.
  int _choisisSurLaPage = 0;

  /// Un filtre, une recherche ou une vue qui change retire la selection, et
  /// le dit (DECISION-LISTES §6 : elle ne change pas en silence).
  void _relacherAvecMessage() {
    if (_choisis.isEmpty) return;
    _choisis.clear();
    _bilan = _BilanSuppression.message(
      t.admin.comptes.retrait.selectionRetiree,
      alerte: false,
    );
  }

  /// SANS-BARRE-FIXE (decision du garde-cap, 07/11) : la barre des comptes
  /// choisis est la seule chose collee en bas, et **seulement pendant une
  /// selection** ; une seule ligne (56 dp au plus) ; elle disparait des que
  /// rien n'est choisi. Le resultat d'une suppression et la limite
  /// (« tropGrand ») vont dans le fil, au-dessus de la liste
  /// ([_avisSuppression]).
  Widget? _zoneSuppression() {
    final r = t.admin.comptes.retrait;
    final int n = _choisis.length;
    if (n == 0) return null;
    final List<CompteAdmin> choisis = _choisis.values.toList();
    return BarreSelection.compacte(
      key: ComptesPage.barreSuppressionKey,
      titre: _choisisSurLaPage == n
          ? r.retenus(n: n)
          : r.retenusPage(n: n, p: '$_choisisSurLaPage'),
      onRelacher: () => setState(_choisis.clear),
      operations: <Widget>[
        if (n <= _plafondSuppression)
          ActionPrincipale(
            key: ComptesPage.supprimerSelectionKey,
            libelle: r.supprimerSelection(n: n),
            niveau: NiveauAction.destructive,
            compacte: true,
            pleineLargeur: false,
            enCours: _suppressionEnCours,
            // Un envoi en cours ignore le second toucher (`_supprimer`).
            onPress: () => unawaited(_supprimer(choisis)),
          ),
      ],
    );
  }

  /// Ce qui se dit de la suppression, dans le fil, au-dessus de la liste :
  /// le resultat de la derniere suppression, et, pendant une selection trop
  /// grande, pourquoi « Supprimer » n'est pas propose ; rien sinon.
  Widget? _avisSuppression() {
    final r = t.admin.comptes.retrait;
    final int n = _choisis.length;
    final _BilanSuppression? bilan = _bilan;
    final bool tropGrand = n > _plafondSuppression;
    if (bilan == null && !tropGrand) return null;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: ComptesPage.avisSuppressionKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (bilan != null)
          _VueBilan(
            bilan: bilan,
            onFermer: () => setState(() => _bilan = null),
          ),
        if (bilan != null && tropGrand) Ecart.vSm,
        if (tropGrand)
          Text(
            r.tropGrand(n: '$_plafondSuppression'),
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
      ],
    );
  }

  /// SUPPRIMER : un compte d'eleve, de tuteur ou d'enseignant se supprime ici.
  /// Un compte de la direction, ou de role illisible, jamais (le serveur
  /// refuse aussi : `compte_direction`).
  static bool _supprimable(CompteAdmin c) => switch (c.role) {
    AppRole.student || AppRole.guardian || AppRole.teacher => true,
    AppRole.admin || AppRole.accountant || AppRole.controller || null => false,
  };

  /// Supprime [comptes] apres une confirmation qui dit leur nombre. Le
  /// serveur rend un resultat par compte ; la liste est relue dans tous les
  /// cas (une reponse perdue apres la suppression ne doit pas laisser une
  /// ligne qui n'existe plus).
  Future<void> _supprimer(List<CompteAdmin> comptes) async {
    if (_suppressionEnCours || comptes.isEmpty) return;
    final r = t.admin.comptes.retrait;
    final bool un = comptes.length == 1;
    final CompteAdmin premier = comptes.first;
    final String? nomDuCompte = un ? premier.libelle : null;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: nomDuCompte != null
          ? r.questionUn(
              deNom: deDevant(
                nomDuCompte,
                cle: 'admin.comptes.retrait.questionUn',
              ),
            )
          : r.questionPlusieurs(n: comptes.length),
      consequence: r.consequence,
      libelleConfirmer: un
          ? r.confirmerUn
          : r.supprimerSelection(n: comptes.length),
      libelleAnnuler: r.rester,
    );
    if (!oui || !mounted) return;
    if (ref.read(horsLigneProvider).value ?? false) {
      setState(() => _bilan = _BilanSuppression.message(r.horsLigne));
      return;
    }
    setState(() {
      _suppressionEnCours = true;
      _bilan = null;
    });
    _BilanSuppression bilan;
    try {
      // MFA-DIRECTION : en aal1, le code est demande puis le geste rejoue.
      final List<String> ids = <String>[
        for (final CompteAdmin c in comptes) c.profilId,
      ];
      final List<ResultatRetrait> resultats = await avecDoubleVerification(
        context,
        ref,
        () => ref.read(portRetraitsComptesProvider).retirer(ids),
      );
      bilan = _BilanSuppression.depuis(resultats, comptes);
    } on PermissionInsuffisante {
      bilan = _BilanSuppression.message(r.refuse);
    } on CapaciteIndisponible {
      bilan = _BilanSuppression.message(r.indisponible);
    } on Object {
      bilan = _BilanSuppression.message(
        (ref.read(horsLigneProvider).value ?? false) ? r.horsLigne : r.echec,
      );
    }
    // D2 : toutes les listes de personnes sont relues, pas seulement
    // celle-ci ; le signal part apres la reponse du serveur (geste sensible).
    ref.read(personnesModifieesProvider.notifier).signaler();
    if (!mounted) return;
    setState(() {
      _suppressionEnCours = false;
      _bilan = bilan;
      _choisis.clear();
    });
  }

  /// V2-e (directeur, 03/11/2026) : la coche « fondateur », tenue par la
  /// direction, sur un membre du personnel au compte actif, dans les vues
  /// Direction et Enseignants. Proposee seulement quand le serveur a rendu
  /// les fondateurs : sans eux, la ligne ne saurait pas quoi proposer.
  bool _porteLaCoche(CompteAdmin c) =>
      _fondateurs != null &&
      (_vue == VueComptes.direction || _vue == VueComptes.enseignants) &&
      c.etat == AccountStatus.active &&
      (c.role == AppRole.admin ||
          c.role == AppRole.teacher ||
          c.role == AppRole.accountant ||
          c.role == AppRole.controller);

  /// Coche ou decoche [c] ; le retour local apres la reponse du serveur
  /// seulement. Remis a nul d'abord : deux gestes de suite rejouent
  /// l'apparition.
  Future<void> _poserFondateur(CompteAdmin c, {required bool fondateur}) async {
    final PortFondateurs? port = ref.read(portFondateursProvider);
    if (port == null) return;
    String message;
    try {
      await port.poser(c.profilId, fondateur: fondateur);
      message = fondateur
          ? t.admin.comptes.fondateurMarque(nom: c.libelle)
          : t.admin.comptes.fondateurRetire(nom: c.libelle);
      ref.invalidate(fondateursProvider);
    } on FondateurRefuse catch (e) {
      message = switch (e.motif) {
        MotifFondateurRefuse.nonAutorise =>
          t.admin.comptes.fondateurRefuseDirection,
        MotifFondateurRefuse.personnelInactif =>
          t.admin.comptes.fondateurRefuseInactif,
        MotifFondateurRefuse.inconnu => t.admin.comptes.fondateurRefuseInconnu,
      };
    } on Object {
      message = t.admin.comptes.fondateurRefuseInconnu;
    }
    if (!mounted) return;
    setState(() => _retour = null);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) setState(() => _retour = message);
    });
  }

  /// La population de la demande d'un compte : un adulte qui apprend pour
  /// lui-meme, sans enfant au foyer, est un eleve adulte ; sinon, une
  /// famille. La page des demandes garde le nom cherche si l'on change de
  /// population.
  static PopulationAdmission _populationDe(CompteAdmin c) =>
      c.role == AppRole.guardian && c.apprenant && c.enfantsDuFoyer == 0
      ? PopulationAdmission.eleveAdulte
      : PopulationAdmission.famille;

  /// Le menu d'une ligne : rien (pas de menu vide) quand elle n'a pas d'action.
  Widget _actions(BuildContext context, CompteAdmin c) {
    if (!_aUneAction(c)) return const SizedBox.shrink();
    return MenuActions(
      points: true,
      objet: c.libelle,
      actions: <EntreeAction>[
        if (_ouvreUneDemande(c))
          EntreeAction(
            libelle: t.admin.comptes.actionVoirDemande,
            icone: AppIcons.dossiers,
            // La demande de cette personne : son nom, en `extra`, jamais dans
            // l'adresse (§5.9).
            onChoix: () => GoRouter.of(context).go(
              Routes.adminPersonnesAdmissions,
              extra: (population: _populationDe(c), recherche: c.libelle),
            ),
          ),
        if (_ouvreUnDossier(c))
          EntreeAction(
            libelle: t.admin.comptes.actionOuvrirDossier,
            icone: AppIcons.dossiers,
            onChoix: () =>
                GoRouter.of(context)
                    .go(Routes.adminPersonnesDossiers, extra: c.profilId),
          ),
        if (_villeAVerifier(c))
          EntreeAction(
            libelle: t.lieu.verifier(nom: c.libelle),
            icone: AppIcons.controleQualite,
            onChoix: () => unawaited(_verifierVille(c)),
          ),
        if (_porteLaCoche(c))
          if (_fondateurs!.contains(c.profilId))
            EntreeAction(
              libelle: t.admin.comptes.actionRetirerFondateur,
              icone: AppIcons.etoile,
              onChoix: () => unawaited(_poserFondateur(c, fondateur: false)),
            )
          else
            EntreeAction(
              libelle: t.admin.comptes.actionMarquerFondateur,
              icone: AppIcons.etoile,
              onChoix: () => unawaited(_poserFondateur(c, fondateur: true)),
            ),
        // Le destructif en dernier, separe (MenuActions).
        if (_supprimableIci(c) && !_suppressionEnCours)
          EntreeAction(
            libelle: t.admin.comptes.retrait.actionLigne,
            destructif: true,
            onChoix: () => unawaited(_supprimer(<CompteAdmin>[c])),
          ),
      ],
    );
  }

  static String _texteIncoherence(TypeIncoherenceLieu type) => switch (type) {
    TypeIncoherenceLieu.sansVille => t.lieu.incSansVille,
    TypeIncoherenceLieu.fuseauDifferentVille => t.lieu.incFuseauDifferent,
    TypeIncoherenceLieu.paysDifferentVille => t.lieu.incPaysDifferent,
    TypeIncoherenceLieu.paysFuseau => t.lieu.incPaysFuseau,
  };

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

/// Ce que la derniere suppression a donne : les comptes supprimes, et pour
/// chaque refus, le nom et la raison (un resultat par compte, rendu par le
/// serveur) ; ou un seul message quand rien n'est parti ou rien n'est sur.
class _BilanSuppression {
  const _BilanSuppression({required this.supprimes, required this.refus})
    : message = null,
      alerte = false;

  const _BilanSuppression.message(String this.message, {this.alerte = true})
    : supprimes = 0,
      refus = const <String>[];

  factory _BilanSuppression.depuis(
    List<ResultatRetrait> resultats,
    List<CompteAdmin> comptes,
  ) {
    final r = t.admin.comptes.retrait;
    String nomDe(String id) {
      for (final CompteAdmin c in comptes) {
        if (c.profilId == id) return c.libelle;
      }
      return id;
    }

    String raison(ResultatRetrait x) => switch (x.raison) {
      RaisonRefusRetrait.introuvable => r.raison.introuvable,
      RaisonRefusRetrait.dejaRetire => r.raison.dejaRetire,
      RaisonRefusRetrait.soiMeme => r.raison.soiMeme,
      RaisonRefusRetrait.compteDirection => r.raison.compteDirection,
      RaisonRefusRetrait.seancesAVenir => r.raison.seancesAVenir(
        n: x.seancesAVenir,
      ),
      _ => r.raison.erreur,
    };

    return _BilanSuppression(
      supprimes: resultats.where((ResultatRetrait x) => x.retire).length,
      refus: <String>[
        for (final ResultatRetrait x in resultats)
          if (!x.retire) r.raisonLigne(nom: nomDe(x.id), raison: raison(x)),
      ],
    );
  }

  final int supprimes;
  final List<String> refus;
  final String? message;

  /// Le [message] dit un echec (encre d'alerte) ; sinon une information.
  final bool alerte;
}

class _VueBilan extends StatelessWidget {
  const _VueBilan({required this.bilan, required this.onFermer});

  final _BilanSuppression bilan;

  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.comptes.retrait;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final String? message = bilan.message;
    return Semantics(
      liveRegion: true,
      child: Column(
        key: ComptesPage.bilanKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (message != null)
            Text(
              message,
              style: (bilan.alerte ? palette.inkAlert : palette.inkStrong)
                  .applyTo(corps),
            ),
          if (bilan.supprimes > 0)
            Text(
              r.supprimes(n: bilan.supprimes),
              style: palette.inkStrong.applyTo(corps),
            ),
          if (bilan.refus.isNotEmpty) ...<Widget>[
            if (bilan.supprimes > 0) Ecart.vSm,
            BandeauAttention(
              titre: r.nonSupprimes(n: bilan.refus.length),
              message: bilan.refus.join('\n'),
            ),
          ],
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: ComptesPage.fermerBilanKey,
              libelle: t.commun.fermer,
              niveau: NiveauAction.tertiaire,
              compacte: true,
              pleineLargeur: false,
              onPress: onFermer,
            ),
          ),
        ],
      ),
    );
  }
}

/// La vue, son filtre et la page affichee (`_tranche`).
typedef _Tranche = ({
  DateTime maintenant,
  FiltreComptes filtre,
  Map<VueComptes, List<CompteAdmin>> parVue,
  List<CompteAdmin> deLaVue,
  List<CompteAdmin> visibles,
  int taille,
  int page,
  int debut,
  int fin,
  List<CompteAdmin> lignesPage,
});
