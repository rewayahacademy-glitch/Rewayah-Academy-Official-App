/// OFFRES-ADM-1 : « Classes a ouvrir », la file des demandes semblables cote
/// administration.
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
/// §3) : le systeme regroupe les demandes qui se ressemblent ; chaque
/// regroupement montre ses jours, son heure (heure de reference et fuseaux
/// utiles), son public, sa langue, son nombre d'eleves, et « Prete » quand le
/// quota est atteint (lu depuis le port, jamais ecrit ici). Le bouton « Creer
/// la classe » ne se grise jamais ; avant le quota, il n'est pas rendu (le
/// serveur refuse la creation) et la phrase du quota dit ce qui manque.
/// Chaque classe deja creee est nommee avec son numero parmi les classes
/// paralleles (R16, [nomClasseRegroupee]).
///
/// Tri : les regroupements prets d'abord, puis le plus grand nombre d'eleves
/// ([trierRegroupements]). Une classe deja creee qui attend son enseignant
/// passe en tete (ALERTE-1 : ce qui attend une decision avant le reste).
///
/// L'ecran lit des capacites, jamais un role : le bouton n'existe que sur un
/// regroupement que le serveur dit creable par la personne connectee
/// ([RegroupementDemandes.peutCreerClasse]). Aucun nom d'eleve n'est affiche.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (le
/// bandeau de `PageShell` ; `EtatSansDonnees` seulement si rien n'a pu etre
/// lu), et port absent (« disponible au branchement serveur »).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/page_regroupements.dart';
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/puce_filtre_actif.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../creneaux/plages.dart' show jourCapitalise;
import 'feuille_classe_regroupement.dart';
import 'regroupements_libelles.dart';

/// L'ecran « Classes a ouvrir ».
class RegroupementsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const RegroupementsPage({super.key});

  @override
  ConsumerState<RegroupementsPage> createState() => _RegroupementsPageEtat();
}

class _RegroupementsPageEtat extends ConsumerState<RegroupementsPage> {
  /// Le filtre courant (R17) : texte, public, etat, jour, heure, fuseau.
  FiltreRegroupements _filtre = const FiltreRegroupements();

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre.
  int _page = 1;

  /// La derniere page lue : ses compteurs et ses valeurs de filtre restent
  /// affiches pendant qu'une autre page se charge.
  PageRegroupements? _derniere;

  /// LISTES-3 : au bureau, le panneau des filtres et de la recherche.
  bool _filtresOuverts = false;

  final TextEditingController _recherche = TextEditingController();

  /// L'attente qui suit la derniere frappe : une page n'est demandee qu'une
  /// fois la saisie posee. Ce n'est pas un mouvement (aucune animation),
  /// donc pas un jeton d'`AppMouvement`.
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (mounted) _filtrer(_filtre.avec(texte: texte));
    });
  }

  void _filtrer(FiltreRegroupements filtre) => setState(() {
    _filtre = filtre;
    _page = 1;
  });

  void _relire() => ref
    ..invalidate(regroupementsAdminProvider)
    ..invalidate(pageRegroupementsAdminProvider);

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  Widget _filtres(PageRegroupements? reference, {bool panneau = false}) {
    final l = t.admin.regroupements.liste;
    final lg = t.admin.groupes.liste;
    int? compte(EtatRegroupement e) => reference?.compteurs[e];
    FilterPill pastille(
      EtatRegroupement? etat,
      String libelle,
      int? compteur,
      String cle,
    ) => FilterPill(
      key: ValueKey<String>(cle),
      libelle: libelle,
      compteur: compteur,
      retenue: _filtre.etat == etat,
      onPress: () => _filtrer(_filtre.avec(etat: () => etat)),
    );
    return RangeeFiltres(
      key: panneau
          ? const ValueKey<String>('regroupements-panneau-filtres')
          : null,
      enPanneau: panneau,
      filtres: <Widget>[
        pastille(
          null,
          l.filtreToutes,
          reference?.toutesEtats,
          'regroupements-filtre-toutes',
        ),
        pastille(
          EtatRegroupement.aFinir,
          l.filtreAFinir,
          compte(EtatRegroupement.aFinir),
          'regroupements-filtre-a-finir',
        ),
        pastille(
          EtatRegroupement.pret,
          l.filtrePrets,
          compte(EtatRegroupement.pret),
          'regroupements-filtre-prets',
        ),
        pastille(
          EtatRegroupement.incomplet,
          l.filtreIncompletes,
          compte(EtatRegroupement.incomplet),
          'regroupements-filtre-incompletes',
        ),
        MenuFiltre<PublicOffre>(
          key: const ValueKey<String>('regroupements-filtre-public'),
          libelle: l.filtrePublic,
          valeur: _filtre.public,
          entrees: <EntreeFiltre<PublicOffre>>[
            EntreeFiltre<PublicOffre>(
              valeur: null,
              libelle: l.filtreTousPublics,
            ),
            for (final PublicOffre p in PublicOffre.values)
              EntreeFiltre<PublicOffre>(valeur: p, libelle: nomPublic(p)),
          ],
          onChoix: (PublicOffre? p) => _filtrer(_filtre.avec(public: () => p)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('regroupements-filtre-jour'),
          libelle: lg.filtreJour,
          valeur: _filtre.jour,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: lg.filtreTousJours),
            for (final int jour in reference?.jours ?? const <int>[])
              EntreeFiltre<int>(valeur: jour, libelle: jourCapitalise(jour)),
          ],
          onChoix: (int? jour) => _filtrer(_filtre.avec(jour: () => jour)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('regroupements-filtre-heure'),
          libelle: lg.filtreHeure,
          valeur: _filtre.heure,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: lg.filtreToutesHeures),
            for (final int heure in reference?.heures ?? const <int>[])
              EntreeFiltre<int>(
                valeur: heure,
                libelle: libelleHeureMinute(heure, 0),
              ),
          ],
          onChoix: (int? heure) => _filtrer(_filtre.avec(heure: () => heure)),
        ),
        MenuFiltre<String>(
          key: const ValueKey<String>('regroupements-filtre-fuseau'),
          libelle: lg.filtreFuseau,
          valeur: _filtre.fuseau,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(valeur: null, libelle: lg.filtreTousFuseaux),
            for (final String fuseau in reference?.fuseaux ?? const <String>[])
              EntreeFiltre<String>(
                valeur: fuseau,
                libelle: villeDuFuseauLibelle(fuseau),
              ),
          ],
          onChoix: (String? fuseau) =>
              _filtrer(_filtre.avec(fuseau: () => fuseau)),
        ),
      ],
    );
  }

  /// La feuille de creation de la classe, ou du choix de l'enseignant.
  Future<void> _ouvrir(RegroupementDemandes g) {
    final FeuilleClasseRegroupement feuille = FeuilleClasseRegroupement(
      regroupement: g,
    );
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: feuille.titre,
      constructeur: (BuildContext _) => feuille,
    );
  }

  /// « Voir la classe » : la fiche de la classe, comme une page (L1). La
  /// ligne de Classes est relue d'abord (nom et etat « en attente
  /// d'enseignant ») et passee a la fiche : sans elle, la fiche relit
  /// `groupes_admin`, qui ne rend pas une classe sans enseignant.
  Future<void> _voirClasse(ClasseSansEnseignant c) async {
    final GoRouter routeur = GoRouter.of(context);
    ClasseListee? ligne;
    try {
      final PageClasses page = await ref.read(
        pageClassesAdminProvider(
          RequeteClasses(
            filtre: FiltreClasses(
              texte: c.libelle,
              etat: EtatClasseListee.attenteEnseignant,
            ),
          ),
        ).future,
      );
      ligne = page.lignes
          .where((ClasseListee l) => l.id == c.classeId)
          .firstOrNull;
    } on Object {
      ligne = null;
    }
    if (!mounted) return;
    unawaited(
      routeur.push(Routes.adminOperationsGroupePour(c.classeId), extra: ligne),
    );
  }

  /// LISTES-3 : les filtres retenus, quand le panneau est replie (bureau) :
  /// rien n'est cache sans le dire.
  List<FiltreActif> _filtresActifs() {
    final l = t.admin.regroupements.liste;
    final lg = t.admin.groupes.liste;
    String axe(String nomAxe, String valeurRetenue) =>
        t.commun.filtres.axeValeur(axe: nomAxe, valeur: valeurRetenue);
    final FiltreRegroupements f = _filtre;
    return <FiltreActif>[
      if (f.texte.trim().isNotEmpty)
        FiltreActif(
          libelle: axe(l.rechercheLibelle, f.texte.trim()),
          onRetirer: () {
            _recherche.clear();
            _filtrer(f.avec(texte: ''));
          },
        ),
      if (f.etat case final EtatRegroupement etat)
        FiltreActif(
          libelle: axe(t.admin.groupes.colonneEtat, switch (etat) {
            EtatRegroupement.aFinir => l.filtreAFinir,
            EtatRegroupement.pret => l.filtrePrets,
            EtatRegroupement.incomplet => l.filtreIncompletes,
          }),
          onRetirer: () => _filtrer(f.avec(etat: () => null)),
        ),
      if (f.public case final PublicOffre public)
        FiltreActif(
          libelle: axe(l.filtrePublic, nomPublic(public)),
          onRetirer: () => _filtrer(f.avec(public: () => null)),
        ),
      if (f.jour case final int jour)
        FiltreActif(
          libelle: axe(lg.filtreJour, jourCapitalise(jour)),
          onRetirer: () => _filtrer(f.avec(jour: () => null)),
        ),
      if (f.heure case final int heure)
        FiltreActif(
          libelle: axe(lg.filtreHeure, libelleHeureMinute(heure, 0)),
          onRetirer: () => _filtrer(f.avec(heure: () => null)),
        ),
      if (f.fuseau case final String fuseau)
        FiltreActif(
          libelle: axe(lg.filtreFuseau, villeDuFuseauLibelle(fuseau)),
          onRetirer: () => _filtrer(f.avec(fuseau: () => null)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final RequeteRegroupements requete = RequeteRegroupements(
      filtre: _filtre,
      page: _page,
    );
    final AsyncValue<PageRegroupements> valeur = ref.watch(
      pageRegroupementsAdminProvider(requete),
    );
    if (valeur.hasValue) _derniere = valeur.requireValue;
    final PageRegroupements? reference = valeur.value ?? _derniere;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool bureau = DataCollection.enTableau(context);
    final r = t.admin.regroupements;
    final l = r.liste;
    // Les commandes de liste n'ont de sens que si une lecture a abouti ; un
    // port absent ou une premiere lecture en echec n'en montrent aucune.
    final bool commandes = reference != null && reference.totalSansFiltre > 0;
    final List<FiltreActif> actifs = _filtresActifs();

    final Widget recherche = ChampRecherche(
      cleChamp: const ValueKey<String>('regroupements-recherche'),
      controleur: _recherche,
      libelle: l.rechercheLibelle,
      aide: l.rechercheAide,
      onChange: _chercher,
    );
    // LISTES-3 (bureau) : le titre et l'icone des filtres en tete ; filtres
    // et recherche en panneau replie, qui defile avec la liste. Au
    // telephone, §5 ter : la recherche et la rangee de filtres defilent avec
    // la liste.
    final Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (commandes)
          if (!bureau) ...<Widget>[
            recherche,
            Ecart.vMd,
            _filtres(reference),
            Ecart.vLg,
          ] else if (_filtresOuverts) ...<Widget>[
            recherche,
            Ecart.vMd,
            _filtres(reference, panneau: true),
            Ecart.vLg,
          ] else if (actifs.isNotEmpty) ...<Widget>[
            FiltresActifs(
              filtres: actifs,
              onToutEffacer: () {
                _recherche.clear();
                _filtrer(const FiltreRegroupements());
              },
            ),
            Ecart.vLg,
          ],
      ],
    );

    return PageShell(
      titre: r.titre,
      // LISTES-2 et LISTES-3 : la tete defile avec la liste, qui prend toute
      // la largeur au bureau, sans retour (la barre laterale navigue).
      teteAvecLaListe: true,
      listeBureau: true,
      actionsEntete: <Widget>[
        if (bureau && commandes)
          RangeeFiltres.bascule(
            key: const ValueKey<String>('regroupements-bascule-filtres'),
            ouverts: _filtresOuverts,
            retenus: actifs.length,
            onBasculer: () =>
                setState(() => _filtresOuverts = !_filtresOuverts),
          ),
      ],
      // `DataCollection` porte le defilement de la page (une seule barre).
      defilante: false,
      child: ColonneCorps(
        children: <Widget>[
          Expanded(
            child: switch (valeur) {
              AsyncValue<PageRegroupements>(hasValue: true)
                  when valeur.requireValue.totalSansFiltre == 0 =>
                _SansListe(
                  tete: tete,
                  child: EmptyState(
                    key: const ValueKey<String>('regroupements-vide'),
                    message: r.vide,
                    invitation: r.videDetail,
                    icone: AppIcons.classes,
                  ),
                ),
              AsyncValue<PageRegroupements>(hasValue: true) => _Corps(
                page: valeur.requireValue,
                tete: tete,
                bureau: bureau,
                onPage: (int numero) => setState(() => _page = numero),
                onAgir: (RegroupementDemandes g) => unawaited(_ouvrir(g)),
                onVoirClasse: (ClasseSansEnseignant c) =>
                    unawaited(_voirClasse(c)),
              ),
              AsyncValue<PageRegroupements>(
                error: final CapaciteIndisponible erreur,
              ) =>
                // Port absent : ni un echec, ni un vide. Rien ne se
                // reessaie.
                _SansListe(
                  tete: tete,
                  child: EtatSysteme(
                    key: const ValueKey<String>('regroupements-indisponible'),
                    nature: NatureEtat.indisponible,
                    titre: r.indisponibleTitre,
                    phrase: r.indisponiblePhrase,
                    dependance: erreur.dependance,
                  ),
                ),
              AsyncValue<PageRegroupements>(hasError: true) => _SansListe(
                tete: tete,
                child: horsLigne
                    ? EtatSansDonnees(
                        key: const ValueKey<String>(
                          'regroupements-sans-donnees',
                        ),
                        quoi: r.sansDonnees,
                        onAction: _relire,
                      )
                    : EtatSysteme(
                        key: const ValueKey<String>('regroupements-erreur'),
                        nature: NatureEtat.echecServeur,
                        phrase: r.erreur,
                        onAction: _relire,
                      ),
              ),
              _ => _SansListe(
                tete: tete,
                child: const Skeleton.tableDense(lignes: 6),
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Sans ligne, pas de liste pour prendre la tete : la page fait defiler sa
/// tete et ce corps ensemble (jamais un cadre de hauteur fixe).
class _SansListe extends StatelessWidget {
  const _SansListe({required this.tete, required this.child});

  final Widget tete;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[tete, child],
    ),
  );
}

/// La liste (L3, §5 quater) : une ligne par regroupement, dans l'ordre rendu
/// par le port (les classes qui attendent leur enseignant d'abord, puis les
/// regroupements prets, puis les plus nombreux). Au bureau, des cartes sous
/// des en-tetes discrets ; au telephone, des lignes denses. Sous la liste,
/// la position et la navigation de page (R17).
class _Corps extends StatelessWidget {
  const _Corps({
    required this.page,
    required this.tete,
    required this.bureau,
    required this.onPage,
    required this.onAgir,
    required this.onVoirClasse,
  });

  final PageRegroupements page;
  final Widget tete;
  final bool bureau;
  final ValueChanged<int> onPage;

  /// Ouvre la feuille de creation (ou de l'enseignant), depuis le contexte
  /// de la page : celui d'une cellule disparait quand la liste se relit.
  final ValueChanged<RegroupementDemandes> onAgir;

  /// Ouvre la fiche de la classe deja creee.
  final ValueChanged<ClasseSansEnseignant> onVoirClasse;

  /// La classe creee qui attend son enseignant : la confirmer ; sinon, le
  /// regroupement pret : creer la classe. Le serveur dit qui le peut.
  static bool _peutAgir(RegroupementDemandes g) => switch (g.classe) {
    null => g.peutCreerClasse && g.pret,
    final ClasseSansEnseignant c => c.peutAffecterEnseignant,
  };

  static String _titre(RegroupementDemandes g) => switch (g.classe) {
    null => libelleCreneau(g),
    final ClasseSansEnseignant c => nomClasseRegroupee(c),
  };

  @override
  Widget build(BuildContext context) {
    final r = t.admin.regroupements;
    final l = r.liste;
    if (page.lignes.isEmpty) {
      return _SansListe(
        tete: tete,
        child: EmptyState(
          key: const ValueKey<String>('regroupements-aucun-filtre'),
          message: l.aucunAvecCeFiltre,
          invitation: l.aucunAvecCeFiltreDetail,
          registre: RegistreVide.subi,
          icone: AppIcons.rienAAfficher,
        ),
      );
    }
    // K-56 : un seul bouton plein, sur la premiere ligne qui en porte un.
    final String? principal = page.lignes.where(_peutAgir).firstOrNull?.id;
    final bool ailleurs = page.lignes.any(
      (RegroupementDemandes g) => g.autresFuseaux.isNotEmpty,
    );

    return DataCollection<RegroupementDemandes>(
      key: ValueKey<String>('regroupements-table-${page.page}'),
      // LISTES-2 et LISTES-3 (§5 quater) : la tete et les filtres defilent
      // avec les lignes.
      prendTeteDePage: true,
      tete: tete,
      // Au telephone, des cartes et non des lignes denses : chaque ligne
      // porte cinq informations et un bouton, qui doivent pouvoir passer a la
      // ligne (« Choisir l'enseignant » et le menu debordaient a 390).
      densiteTelephone: false,
      lignesCartes: true,
      lignes: page.lignes,
      cle: (RegroupementDemandes g) => ValueKey<String>('regroupement-${g.id}'),
      colonnes: <ColonneDonnees<RegroupementDemandes>>[
        ColonneDonnees<RegroupementDemandes>(
          titre: r.cleJoursHeures,
          role: RoleColonne.identifiante,
          flex: 3,
          texte: _titre,
          // Le creneau (ou la classe creee), puis son etat dessous : la meme
          // pastille et la meme phrase que la carte d'avant (rien ne se perd).
          rendu: (BuildContext _, RegroupementDemandes g) =>
              _TitreRegroupement(regroupement: g, peutAgir: _peutAgir(g)),
        ),
        ColonneDonnees<RegroupementDemandes>(
          titre: r.cleHeure,
          flex: 2,
          texte: (RegroupementDemandes g) =>
              libelleReference(g) ?? libelleFuseau(g),
        ),
        if (ailleurs)
          ColonneDonnees<RegroupementDemandes>(
            titre: r.cleAilleurs,
            flex: 3,
            texte: libelleAutresFuseaux,
          ),
        ColonneDonnees<RegroupementDemandes>(
          titre: r.clePublic,
          texte: (RegroupementDemandes g) => nomPublic(g.public),
        ),
        ColonneDonnees<RegroupementDemandes>(
          titre: r.cleLangue,
          texte: (RegroupementDemandes g) => g.langueNom,
        ),
        ColonneDonnees<RegroupementDemandes>(
          titre: r.cleEleves,
          flex: 2,
          tabulaire: true,
          texte: libelleDemandesClasses,
        ),
        // L'action principale de la ligne, visible (pilote, 01/11/2026) :
        // seulement quand elle peut aboutir. Au telephone, elle se pose au
        // bout de la ligne, comme une pastille.
        ColonneDonnees<RegroupementDemandes>(
          titre: t.commun.listes.actions,
          // « Choisir l'enseignant » tient sur une ligne a 1366.
          flex: 3,
          // Un noeud a part du lecteur d'ecran, au tableau comme en carte (sans
          // cela, « Lundi… Creer la classe » ne faisait qu'un, lu par le robot).
          action: true,
          texte: (RegroupementDemandes g) => !_peutAgir(g)
              ? ''
              : g.classe == null
              ? r.creer
              : r.choisirEnseignant,
          rendu: (BuildContext contexte, RegroupementDemandes g) =>
              !_peutAgir(g)
              ? const SizedBox.shrink()
              : ActionPrincipale(
                  key: ValueKey<String>('regroupement-action-${g.id}'),
                  libelle: g.classe == null ? r.creer : r.choisirEnseignant,
                  compacte: true,
                  pleineLargeur: false,
                  niveau: g.id == principal
                      ? NiveauAction.principale
                      : NiveauAction.secondaire,
                  onPress: () => onAgir(g),
                ),
        ),
      ],
      // Le reste dans le menu « ... » : la classe deja creee s'ouvre comme
      // une page (L1). Un regroupement sans classe n'a pas d'autre geste
      // (le port n'en a que deux) : pas de menu vide.
      actionsLigne:
          page.lignes.any((RegroupementDemandes g) => g.classe != null)
          ? (BuildContext contexte, RegroupementDemandes g) =>
                switch (g.classe) {
                  null => const SizedBox.shrink(),
                  final ClasseSansEnseignant c => MenuActions(
                    points: true,
                    objet: _titre(g),
                    actions: <EntreeAction>[
                      EntreeAction(
                        libelle: r.voirClasse,
                        icone: AppIcons.classes,
                        onChoix: () => onVoirClasse(c),
                      ),
                    ],
                  ),
                }
          : null,
      piedCollant: PiedDeListe(
        key: const ValueKey<String>('regroupements-pagination'),
        debut: page.debut,
        fin: page.fin,
        total: page.total,
        onPrecedent: page.page > 1 ? () => onPage(page.page - 1) : null,
        onSuivant: page.page < page.pages ? () => onPage(page.page + 1) : null,
        mention: t.commun.listes.parPage(n: '${page.taille}'),
      ),
    );
  }
}

/// La cellule d'identite : le creneau (ou la classe creee) et son etat
/// dessous. Sans classe : « Prete » ou « Incomplete » et la phrase du quota
/// (`EtatQuota`, inchange) ; avec une classe : « Enseignant a confirmer ».
/// Une creation ou une confirmation qui n'est pas ouverte a la personne
/// connectee le dit en une phrase (jamais un bouton qui ne peut aboutir).
class _TitreRegroupement extends StatelessWidget {
  const _TitreRegroupement({
    required this.regroupement,
    required this.peutAgir,
  });

  final RegroupementDemandes regroupement;
  final bool peutAgir;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final RegroupementDemandes g = regroupement;
    final ClasseSansEnseignant? classe = g.classe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          classe == null ? libelleCreneau(g) : nomClasseRegroupee(classe),
          // C-11 bis : chaque jour avec son heure quand elles different.
          key: classe == null && !g.heuresToutesEgales
              ? ValueKey<String>('regroupement-jours-heures-${g.id}')
              : null,
          style: textes.titleSmall,
        ),
        Ecart.vXs,
        if (classe == null)
          EtatQuota(regroupement: g, phraseSiPret: false)
        else
          StatusPill(
            key: ValueKey<String>('regroupement-a-finir-${g.id}'),
            libelle: r.sectionAFinir,
            ton: TonEtat.avertissement,
          ),
        if (!peutAgir && (classe != null || g.pret)) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            classe == null ? r.nonOuvert : r.affectationNonOuverte,
            key: ValueKey<String>('regroupement-ferme-${g.id}'),
            style: textes.bodySmall,
          ),
        ],
      ],
    );
  }
}
