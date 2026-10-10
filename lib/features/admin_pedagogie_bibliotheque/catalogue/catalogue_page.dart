/// CAP29-A : le catalogue de la bibliotheque, Pedagogie > Bibliotheque
/// (spec CAP-29 §3.2, maquette M01).
///
/// Une recherche locale au catalogue, des segments (Tous, Brouillons, A
/// verifier, Publies, Retires, Droits expires), des filtres (type, niveau,
/// langue), puis la table (bureau) ou les cartes (telephone, tablette). Une
/// ligne ouvre la fiche. **Jamais de « Publier » depuis la liste** : la
/// publication passe par la verification (CAP29-D).
///
/// - Filtrage et pagination sont du serveur (curseur) : le client ne filtre
///   jamais lui-meme et n'affiche **aucun total** (un nombre global pourrait
///   reveler un support non autorise).
/// - Etat de publication et revue des droits sont deux pastilles distinctes.
/// - L'action « Ajouter un support » n'existe que si le serveur dit
///   `peutImporter` ; sinon elle n'est pas rendue (jamais grisee).
/// - Etats : chargement, contenu, vide, recherche vide, erreur et reessai,
///   hors ligne, non autorise, indisponible (port absent), pagination
///   partielle (la suite echoue, la page deja lue reste), droits echus.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_domaine.dart';
import '../../../core/admin/modeles_bibliotheque_admin.dart';
import '../../../core/admin/port_bibliotheque_admin.dart';
import '../../../core/i18n/dates_appareil.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/mouvement/mouvement.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/menu_filtre.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/rangee_filtres.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';

/// Le rang de « Bibliotheque » dans la sous-navigation Pedagogie.
const int rangBibliotheque = 4;

/// La taille d'une page du catalogue.
const int taillePageCatalogue = 25;

/// L'ecran du catalogue.
class CataloguePage extends StatelessWidget {
  /// Cree l'ecran.
  const CataloguePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      // ONGLETS-COUPE-1 : en cartes, tout defile avec la page ; en tableau,
      // la liste defile seule sous son en-tete colle.
      defilante: !DataCollection.enTableau(context),
      child: PorteBibliotheque(
        construire: (
          BuildContext context,
          PortBibliothequeAdmin port,
          CapacitesBibliotheque capacites,
        ) => _Catalogue(port: port, capacites: capacites),
      ),
    );
  }
}

class _Catalogue extends ConsumerStatefulWidget {
  const _Catalogue({required this.port, required this.capacites});

  final PortBibliothequeAdmin port;
  final CapacitesBibliotheque capacites;

  @override
  ConsumerState<_Catalogue> createState() => _CatalogueEtat();
}

class _CatalogueEtat extends ConsumerState<_Catalogue> {
  final TextEditingController _recherche = TextEditingController();
  Timer? _attente;
  FiltreCatalogue _filtre = const FiltreCatalogue();
  FacettesCatalogue _facettes = const FacettesCatalogue();
  List<SupportAdmin> _lignes = const <SupportAdmin>[];
  String? _curseur;
  bool _chargement = true;
  bool _pageEnCours = false;
  bool _pageEchec = false;
  Object? _erreur;
  // Une reponse perimee (filtre change entre-temps) est ignoree.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
    unawaited(_lireFacettes());
  }

  @override
  void dispose() {
    _attente?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _lireFacettes() async {
    try {
      final FacettesCatalogue f = await widget.port.facettes();
      if (mounted) setState(() => _facettes = f);
    } on Object {
      // Sans facettes, les menus Niveau et Langue ne sont pas rendus : le
      // catalogue lui-meme dit son erreur.
    }
  }

  Future<void> _charger() async {
    final int g = ++_generation;
    setState(() {
      _chargement = true;
      _erreur = null;
      _pageEchec = false;
    });
    try {
      final PageSupports p = await widget.port.lister(
        filtre: _filtre,
        limite: taillePageCatalogue,
      );
      if (!mounted || g != _generation) return;
      setState(() {
        _lignes = p.elements;
        _curseur = p.curseur;
        _chargement = false;
      });
    } on Object catch (e) {
      if (!mounted || g != _generation) return;
      setState(() {
        _erreur = e;
        _chargement = false;
      });
    }
  }

  Future<void> _pageSuivante() async {
    final String? curseur = _curseur;
    if (curseur == null || _pageEnCours) return;
    final int g = _generation;
    setState(() {
      _pageEnCours = true;
      _pageEchec = false;
    });
    try {
      final PageSupports p = await widget.port.lister(
        filtre: _filtre,
        curseur: curseur,
        limite: taillePageCatalogue,
      );
      if (!mounted || g != _generation) return;
      setState(() {
        _lignes = <SupportAdmin>[..._lignes, ...p.elements];
        _curseur = p.curseur;
        _pageEnCours = false;
      });
    } on Object {
      // Pagination partielle : la page deja lue reste, la suite se relance.
      if (!mounted || g != _generation) return;
      setState(() {
        _pageEnCours = false;
        _pageEchec = true;
      });
    }
  }

  void _filtrer(FiltreCatalogue f) {
    _filtre = f;
    unawaited(_charger());
  }

  void _rechercher(String texte) {
    _attente?.cancel();
    _attente = Timer(Mouvement.court, () {
      if (!mounted) return;
      _filtrer(_filtre.avec(recherche: texte));
    });
  }

  void _effacer() {
    _recherche.clear();
    _filtrer(const FiltreCatalogue());
  }

  void _ouvrir(SupportAdmin s) =>
      GoRouter.of(context).go(Routes.adminPedagogieSupport(s.id));

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque;
    final c = a.catalogue;
    final bool enTableau = DataCollection.enTableau(context);
    return ColonneCorps(
      minimumEtire: DataCollection.minimumLisible(context),
      children: <Widget>[
        if (widget.capacites.peutImporter) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('catalogue-ajouter'),
              libelle: a.ajouter,
              pleineLargeur: false,
              onPress: () =>
                  GoRouter.of(context)
                      .go(Routes.adminPedagogieBibliothequeNouveau),
            ),
          ),
          Ecart.vLg,
        ],
        BandeauAttention(
          key: const ValueKey<String>('catalogue-alerte'),
          titre: c.alerteTitre,
          message: a.brouillonAlerte,
          ton: TonEtat.accent,
        ),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _recherche,
          cleChamp: const ValueKey<String>('catalogue-recherche'),
          libelle: c.recherche,
          majuscules: TextCapitalization.none,
          actionClavier: TextInputAction.search,
          maxLignes: 1,
          onChanged: _rechercher,
          onSubmitted: (String texte) {
            _attente?.cancel();
            _filtrer(_filtre.avec(recherche: texte));
          },
        ),
        Ecart.vMd,
        _Filtres(filtre: _filtre, facettes: _facettes, onChange: _filtrer),
        Ecart.vLg,
        if (enTableau)
          Expanded(child: _resultat(context))
        else
          _resultat(context),
      ],
    );
  }

  Widget _resultat(BuildContext context) {
    final a = t.admin.bibliotheque;
    final c = a.catalogue;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (_chargement && _lignes.isEmpty) {
      return const Skeleton.liste(lignes: 6);
    }
    final Object? erreur = _erreur;
    if (erreur != null) {
      if (erreur is BibliothequeNonAutorisee) {
        return EtatSysteme(
          key: const ValueKey<String>('catalogue-non-autorise'),
          nature: NatureEtat.accesRefuse,
          titre: a.titre,
          phrase: a.nonAutorise,
        );
      }
      return horsLigne
          ? EtatSansDonnees(
              key: const ValueKey<String>('catalogue-sans-donnees'),
              quoi: a.sansDonnees,
              onAction: () => unawaited(_charger()),
            )
          : EtatSysteme(
              key: const ValueKey<String>('catalogue-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: a.erreur,
              onAction: () => unawaited(_charger()),
            );
    }
    if (_lignes.isEmpty) {
      return _filtre.vide
          ? EmptyState(
              key: const ValueKey<String>('catalogue-vide'),
              message: a.vide,
              invitation: a.videDetail,
              icone: AppIcons.rienAAfficher,
              registre: widget.capacites.peutImporter
                  ? RegistreVide.actionnable
                  : RegistreVide.subi,
              libelleAction: widget.capacites.peutImporter ? a.ajouter : null,
              onAction: widget.capacites.peutImporter
                  ? () =>
                        GoRouter.of(context)
                            .go(Routes.adminPedagogieBibliothequeNouveau)
                  : null,
            )
          : EmptyState(
              key: const ValueKey<String>('catalogue-recherche-vide'),
              message: c.videRecherche,
              invitation: c.videRechercheDetail,
              icone: AppIcons.rienAAfficher,
              libelleAction: c.effacerFiltres,
              onAction: _effacer,
            );
    }
    return DataCollection<SupportAdmin>(
      key: const ValueKey<String>('catalogue-liste'),
      defileAvecLaPage: !DataCollection.enTableau(context),
      lignes: _lignes,
      cle: (SupportAdmin s) => ValueKey<String>('support-${s.id}'),
      onSelectionner: _ouvrir,
      colonnes: _colonnes(),
      piedDePage: _pied(),
    );
  }

  Widget? _pied() {
    final c = t.admin.bibliotheque.catalogue;
    if (_curseur == null && !_pageEchec) return null;
    final bool enCours = _pageEnCours;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_pageEchec)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                c.pageErreur,
                key: const ValueKey<String>('catalogue-page-erreur'),
              ),
            ),
          ActionPrincipale(
            key: const ValueKey<String>('catalogue-voir-plus'),
            libelle: _pageEchec ? t.commun.reessayer : c.voirPlus,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            enCours: enCours,
            onPress: enCours ? null : () => unawaited(_pageSuivante()),
          ),
        ],
      ),
    );
  }

  List<ColonneDonnees<SupportAdmin>> _colonnes() {
    final co = t.admin.bibliotheque.catalogue.colonnes;
    return <ColonneDonnees<SupportAdmin>>[
      ColonneDonnees<SupportAdmin>(
        titre: co.support,
        role: RoleColonne.identifiante,
        flex: 3,
        texte: (SupportAdmin s) => s.titre,
        rendu: (BuildContext context, SupportAdmin s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(s.titre, style: Theme.of(context).textTheme.titleSmall),
            Text(
              libelleType(s.type),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.langue,
        texte: (SupportAdmin s) => libelleLangue(s.langue),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.categorie,
        flex: 2,
        texte: (SupportAdmin s) =>
            s.niveau == null ? s.categorie : '${s.categorie} · ${s.niveau}',
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.version,
        tabulaire: true,
        texte: (SupportAdmin s) => s.numeroVersion == null
            ? t.admin.bibliotheque.libelles.version.aucune
            : t.admin.bibliotheque.libelles.version.numero(
                numero: '${s.numeroVersion}',
              ),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.publication,
        texte: libelleEtatSupport,
        rendu: (BuildContext _, SupportAdmin s) =>
            StatusPill(libelle: libelleEtatSupport(s), ton: tonEtatSupport(s)),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.droits,
        texte: (SupportAdmin s) => libelleRevue(s.revueDroits),
        rendu: (BuildContext _, SupportAdmin s) => StatusPill(
          libelle: libelleRevue(s.revueDroits),
          ton: tonRevue(s.revueDroits),
        ),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.visibilite,
        texte: (SupportAdmin s) => libelleVisibilite(s.visibilite),
      ),
      ColonneDonnees<SupportAdmin>(
        titre: co.modifie,
        tabulaire: true,
        texte: (SupportAdmin s) => dateDeLAppareil(s.modifieLeUtc.toLocal()),
      ),
    ];
  }
}

class _Filtres extends StatelessWidget {
  const _Filtres({
    required this.filtre,
    required this.facettes,
    required this.onChange,
  });

  final FiltreCatalogue filtre;
  final FacettesCatalogue facettes;
  final void Function(FiltreCatalogue) onChange;

  @override
  Widget build(BuildContext context) {
    final f = t.admin.bibliotheque.catalogue.filtres;
    return RangeeFiltres(
      filtres: <Widget>[
        for (final EtatCatalogue e in EtatCatalogue.values)
          FilterPill(
            key: ValueKey<String>('segment-${e.name}'),
            libelle: libelleSegment(e),
            retenue: filtre.etat == e,
            onPress: () => onChange(filtre.avec(etat: e)),
          ),
        MenuFiltre<TypeRessource>(
          libelle: f.type,
          valeur: filtre.type,
          entrees: <EntreeFiltre<TypeRessource>>[
            EntreeFiltre<TypeRessource>(valeur: null, libelle: f.tous),
            for (final TypeRessource tp in TypeRessource.values)
              EntreeFiltre<TypeRessource>(valeur: tp, libelle: libelleType(tp)),
          ],
          onChoix: (TypeRessource? v) =>
              onChange(filtre.avec(type: v, retirerType: v == null)),
        ),
        if (facettes.niveaux.isNotEmpty)
          MenuFiltre<String>(
            libelle: f.niveau,
            valeur: filtre.niveau,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(valeur: null, libelle: f.tous),
              for (final String n in facettes.niveaux)
                EntreeFiltre<String>(valeur: n, libelle: n),
            ],
            onChoix: (String? v) =>
                onChange(filtre.avec(niveau: v, retirerNiveau: v == null)),
          ),
        if (facettes.langues.isNotEmpty)
          MenuFiltre<String>(
            libelle: f.langue,
            valeur: filtre.langue,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(valeur: null, libelle: f.tous),
              for (final String l in facettes.langues)
                EntreeFiltre<String>(valeur: l, libelle: libelleLangue(l)),
            ],
            onChoix: (String? v) =>
                onChange(filtre.avec(langue: v, retirerLangue: v == null)),
          ),
      ],
    );
  }
}
