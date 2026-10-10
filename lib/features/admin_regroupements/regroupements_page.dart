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

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart' show PublicOffre;
import '../../core/offres/page_regroupements.dart';
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
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

  Widget _filtres(PageRegroupements? reference) {
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
                libelle: villeDuFuseau(fuseau),
              ),
          ],
          onChoix: (String? fuseau) =>
              _filtrer(_filtre.avec(fuseau: () => fuseau)),
        ),
      ],
    );
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
    final r = t.admin.regroupements;
    final l = r.liste;
    // Les commandes de liste n'ont de sens que si une lecture a abouti ; un
    // port absent ou une premiere lecture en echec n'en montrent aucune.
    final bool commandes = reference != null && reference.totalSansFiltre > 0;

    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (commandes) ...<Widget>[
                ChampRecherche(
                  cleChamp: const ValueKey<String>('regroupements-recherche'),
                  controleur: _recherche,
                  libelle: l.rechercheLibelle,
                  aide: l.rechercheAide,
                  onChange: _chercher,
                ),
                Ecart.vMd,
                _filtres(reference),
                Ecart.vXl,
              ],
              BlocAsynchrone<PageRegroupements>(
                key: const ValueKey<String>('regroupements-bloc'),
                valeur: valeur,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: _relire,
                estVide: (PageRegroupements p) => p.totalSansFiltre == 0,
                vide: EmptyState(
                  key: const ValueKey<String>('regroupements-vide'),
                  message: r.vide,
                  invitation: r.videDetail,
                  icone: AppIcons.classes,
                ),
                erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
                  // Port absent : ni un echec, ni un vide. Rien ne se
                  // reessaie.
                  if (erreur is CapaciteIndisponible) {
                    return EtatSysteme(
                      key: const ValueKey<String>('regroupements-indisponible'),
                      nature: NatureEtat.indisponible,
                      titre: r.indisponibleTitre,
                      phrase: r.indisponiblePhrase,
                      dependance: erreur.dependance,
                    );
                  }
                  return horsLigne
                      ? EtatSansDonnees(
                          key: const ValueKey<String>(
                            'regroupements-sans-donnees',
                          ),
                          quoi: r.sansDonnees,
                          onAction: reessayer,
                        )
                      : EtatSysteme(
                          key: const ValueKey<String>('regroupements-erreur'),
                          nature: NatureEtat.echecServeur,
                          phrase: r.erreur,
                          onAction: reessayer,
                        );
                },
                construire: (PageRegroupements page) => _Contenu(
                  page: page,
                  onPage: (int numero) => setState(() => _page = numero),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les deux sections de la page : les classes qui attendent leur
/// enseignant, puis les demandes reunies, dans l'ordre rendu par le port.
/// Sous la liste, la position et la navigation de page (R17).
class _Contenu extends StatelessWidget {
  const _Contenu({required this.page, required this.onPage});

  final PageRegroupements page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.regroupements;
    final l = r.liste;
    if (page.lignes.isEmpty) {
      return EmptyState(
        key: const ValueKey<String>('regroupements-aucun-filtre'),
        message: l.aucunAvecCeFiltre,
        invitation: l.aucunAvecCeFiltreDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    final List<RegroupementDemandes> aFinir = <RegroupementDemandes>[
      for (final RegroupementDemandes g in page.lignes)
        if (g.classe != null) g,
    ];
    final List<RegroupementDemandes> ouverts = <RegroupementDemandes>[
      for (final RegroupementDemandes g in page.lignes)
        if (g.classe == null) g,
    ];
    // K-56 : un seul bouton plein, sur la premiere carte qui en porte un.
    final String? principal = <RegroupementDemandes>[...aFinir, ...ouverts]
        .where(
          (RegroupementDemandes g) => g.classe == null
              ? g.peutCreerClasse && g.pret
              : g.classe!.peutAffecterEnseignant,
        )
        .firstOrNull
        ?.id;

    final List<Widget> sections = <Widget>[
      if (aFinir.isNotEmpty)
        _Section(
          cle: 'regroupements-a-finir',
          titre: r.sectionAFinir,
          cartes: <Widget>[
            for (final RegroupementDemandes g in aFinir)
              _CarteRegroupement(regroupement: g, principal: g.id == principal),
          ],
        ),
      if (ouverts.isNotEmpty)
        _Section(
          cle: 'regroupements-ouverts',
          titre: r.sectionDemandes,
          sousTitre: r.tri,
          cartes: <Widget>[
            for (final RegroupementDemandes g in ouverts)
              _CarteRegroupement(regroupement: g, principal: g.id == principal),
          ],
        ),
    ];
    return Column(
      key: const ValueKey<String>('regroupements-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          if (i > 0) Ecart.vXxl,
          sections[i],
        ],
        Ecart.vLg,
        TexteSansCoupure(
          l.resume(
            debut: '${page.debut}',
            fin: '${page.fin}',
            total: '${page.total}',
          ),
          key: const ValueKey<String>('regroupements-resume'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (page.pages > 1) ...<Widget>[
          Ecart.vSm,
          BarrePrecedentSuivant(
            key: const ValueKey<String>('regroupements-pagination'),
            position: l.position(page: '${page.page}', total: '${page.pages}'),
            positionSemantique: l.positionSemantique(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            libellePrecedent: l.precedente,
            libelleSuivant: l.suivante,
            onPrecedent: page.page > 1 ? () => onPage(page.page - 1) : null,
            onSuivant: page.page < page.pages
                ? () => onPage(page.page + 1)
                : null,
          ),
        ],
      ],
    );
  }
}

/// Une section : son titre, une phrase eventuelle, ses cartes detachees.
class _Section extends StatelessWidget {
  const _Section({
    required this.cle,
    required this.titre,
    required this.cartes,
    this.sousTitre,
  });

  final String cle;
  final String titre;
  final String? sousTitre;
  final List<Widget> cartes;

  @override
  Widget build(BuildContext context) {
    final String? phrase = sousTitre;
    return Column(
      key: ValueKey<String>(cle),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: titre),
        if (phrase != null) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            phrase,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        Ecart.vMd,
        PileCartes(children: cartes),
      ],
    );
  }
}

/// La carte d'un regroupement.
class _CarteRegroupement extends StatelessWidget {
  const _CarteRegroupement({
    required this.regroupement,
    required this.principal,
  });

  final RegroupementDemandes regroupement;

  /// Vrai pour la seule carte dont le bouton est plein (K-56).
  final bool principal;

  Future<void> _ouvrir(BuildContext context) {
    final FeuilleClasseRegroupement feuille = FeuilleClasseRegroupement(
      regroupement: regroupement,
    );
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: feuille.titre,
      constructeur: (BuildContext _) => feuille,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.regroupements;
    final RegroupementDemandes g = regroupement;
    final ClasseSansEnseignant? classe = g.classe;
    // Un regroupement sous le quota n'a pas de bouton : le serveur refuse sa
    // creation, la phrase du quota dit ce qui manque (jamais un bouton qui
    // ne peut pas aboutir).
    final bool peutAgir = classe == null
        ? g.peutCreerClasse && g.pret
        : classe.peutAffecterEnseignant;
    final String titre = classe == null
        ? libelleCreneau(g)
        : nomClasseRegroupee(classe);

    return AppCard(
      key: ValueKey<String>('regroupement-${g.id}'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(titre, style: textes.titleMedium),
      ),
      actions: peutAgir
          ? ActionPrincipale(
              key: ValueKey<String>('regroupement-action-${g.id}'),
              libelle: classe == null ? r.creer : r.choisirEnseignant,
              niveau: principal
                  ? NiveauAction.principale
                  : NiveauAction.secondaire,
              onPress: () => unawaited(_ouvrir(context)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...espacer(lignesRegroupement(g)),
          Ecart.vLg,
          if (classe != null)
            TexteSansCoupure(
              r.classeAttend(libelle: nomClasseRegroupee(classe)),
              style: textes.bodyMedium,
            )
          else
            EtatQuota(regroupement: g),
          if (!peutAgir && (classe != null || g.pret)) ...<Widget>[
            Ecart.vMd,
            TexteSansCoupure(
              classe == null ? r.nonOuvert : r.affectationNonOuverte,
              key: ValueKey<String>('regroupement-ferme-${g.id}'),
              style: textes.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
