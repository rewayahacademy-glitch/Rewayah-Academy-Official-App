import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/admin/enseignants_classe.dart';
import '../../core/admin/personnes_proposables.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/capacites/port_creation_classe.dart';
import '../../core/capacites/port_enseignants_classe.dart';
import '../../core/domain/enums.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/selecteur_personne.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_regroupements/regroupements_libelles.dart' show villeDuFuseau;
import '../creneaux/plages.dart' show jourCapitalise, nommerHeure;
import 'bas_de_feuille.dart';
import 'feuille_observation_groupe.dart';
import 'genre_classe_libelles.dart';

/// Operations > Groupes : le noyau du produit depuis le pivot du 19
/// septembre 2026.
///
/// **Un groupe, pas une affectation** : l'enseignant et jusqu'a
/// [GroupeAdmin.seuilMax] eleves partagent un creneau commun, et c'est dans ce
/// groupe que la visio se tiendra (migration `0017`). Cet ecran devient la
/// fonction primaire du domaine Operations -- l'audit gele
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`) y redirigeait jusqu'ici
/// l'Attribution, qui reste atteignable comme fonction secondaire.
///
/// Meme squelette liste+filtre que `ADM-08` (Comptes) : `FilterPill` pour
/// l'axe ferme (le public), `DataCollection` pour les lignes. Le clic sur une
/// ligne ouvre le detail en feuille, comme le reste du produit
/// (`AppBottomSheet`, jamais une boite de dialogue Material).
class GroupesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des groupes.
  const GroupesPage({super.key});

  /// Largeur de l'inspecteur (AD-X) : celle de la file du contrat D.
  static const double largeurInspecteur = 336;

  /// En dessous, le tableau n'aurait plus la place de ses colonnes : la
  /// ligne s'ouvre en feuille, comme sur telephone.
  static const double largeurTableauMin = 600;

  /// L'inspecteur de la classe choisie.
  static const Key cleInspecteur = ValueKey<String>('adm09-inspecteur');

  @override
  ConsumerState<GroupesPage> createState() => _GroupesPageEtat();
}

class _GroupesPageEtat extends ConsumerState<GroupesPage> {
  /// Le filtre courant (R17) : texte, public, etat, jour, heure, fuseau,
  /// genre, enseignant.
  FiltreClasses _filtre = const FiltreClasses();

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre.
  int _page = 1;

  /// La derniere page lue : ses compteurs et ses valeurs de filtre restent
  /// affiches pendant qu'une autre page se charge.
  PageClasses? _derniere;

  /// La classe ouverte dans l'inspecteur (bureau), par son identifiant.
  String? _choisie;

  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _filtrer(FiltreClasses filtre) => setState(() {
    _filtre = filtre;
    _page = 1;
  });

  void _relire() {
    ref
      ..invalidate(groupesProvider)
      ..invalidate(pageClassesAdminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final RequeteClasses requete = RequeteClasses(filtre: _filtre, page: _page);
    final AsyncValue<PageClasses> lecture = ref.watch(
      pageClassesAdminProvider(requete),
    );
    if (lecture.hasValue) _derniere = lecture.requireValue;
    final PageClasses? reference = lecture.value ?? _derniere;
    final bool bureau = DataCollection.enTableau(context);
    final l = t.admin.groupes.liste;

    final Widget creer = ActionPrincipale(
      libelle: t.admin.groupes.creer,
      pleineLargeur: false,
      onPress: () => _ouvrirCreation(context, ref),
    );
    int? compte(EtatClasseListee e) => reference?.compteurs[e];
    // FILTRES-1 : une seule rangee de puces et de menus, qui defile quand
    // elle ne tient pas (porte par JONCTION-LIGNES-1 sur les onglets d'etat
    // d'AD-X). R17 : etat, public, jour, heure, fuseau, genre, enseignant.
    final Widget filtres = RangeeFiltres(
      filtres: <Widget>[
        FilterPill(
          libelle: t.admin.groupes.filtreToutes,
          compteur: reference?.toutesEtats,
          retenue: _filtre.etat == null,
          onPress: () => _filtrer(_filtre.avec(etat: () => null)),
        ),
        FilterPill(
          libelle: t.admin.groupes.filtreActives,
          compteur: compte(EtatClasseListee.active),
          retenue: _filtre.etat == EtatClasseListee.active,
          onPress: () =>
              _filtrer(_filtre.avec(etat: () => EtatClasseListee.active)),
        ),
        FilterPill(
          key: const ValueKey<String>('classes-filtre-attente'),
          libelle: l.filtreAttente,
          compteur: compte(EtatClasseListee.attenteEnseignant),
          retenue: _filtre.etat == EtatClasseListee.attenteEnseignant,
          onPress: () => _filtrer(
            _filtre.avec(etat: () => EtatClasseListee.attenteEnseignant),
          ),
        ),
        FilterPill(
          libelle: t.admin.groupes.filtreCloturees,
          compteur: compte(EtatClasseListee.cloturee),
          retenue: _filtre.etat == EtatClasseListee.cloturee,
          onPress: () =>
              _filtrer(_filtre.avec(etat: () => EtatClasseListee.cloturee)),
        ),
        MenuFiltre<TypePublicGroupe>(
          libelle: t.admin.groupes.filtrePublic,
          valeur: _filtre.type,
          entrees: <EntreeFiltre<TypePublicGroupe>>[
            EntreeFiltre<TypePublicGroupe>(
              valeur: null,
              libelle: t.admin.groupes.filtreTousTypes,
            ),
            for (final TypePublicGroupe valeur in TypePublicGroupe.values)
              EntreeFiltre<TypePublicGroupe>(
                valeur: valeur,
                libelle: _nomType(valeur),
              ),
          ],
          onChoix: (TypePublicGroupe? type) =>
              _filtrer(_filtre.avec(type: () => type)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('classes-filtre-jour'),
          libelle: l.filtreJour,
          valeur: _filtre.jour,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: l.filtreTousJours),
            for (final int jour in reference?.jours ?? const <int>[])
              EntreeFiltre<int>(valeur: jour, libelle: jourCapitalise(jour)),
          ],
          onChoix: (int? jour) => _filtrer(_filtre.avec(jour: () => jour)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('classes-filtre-heure'),
          libelle: l.filtreHeure,
          valeur: _filtre.heure,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: l.filtreToutesHeures),
            for (final int heure in reference?.heures ?? const <int>[])
              EntreeFiltre<int>(valeur: heure, libelle: _heure(heure)),
          ],
          onChoix: (int? heure) => _filtrer(_filtre.avec(heure: () => heure)),
        ),
        MenuFiltre<String>(
          key: const ValueKey<String>('classes-filtre-fuseau'),
          libelle: l.filtreFuseau,
          valeur: _filtre.fuseau,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(valeur: null, libelle: l.filtreTousFuseaux),
            for (final String fuseau in reference?.fuseaux ?? const <String>[])
              EntreeFiltre<String>(
                valeur: fuseau,
                libelle: villeDuFuseau(fuseau),
              ),
          ],
          onChoix: (String? fuseau) =>
              _filtrer(_filtre.avec(fuseau: () => fuseau)),
        ),
        MenuFiltre<GenreClasse>(
          key: const ValueKey<String>('classes-filtre-genre'),
          libelle: l.filtreGenre,
          valeur: _filtre.genre,
          entrees: <EntreeFiltre<GenreClasse>>[
            EntreeFiltre<GenreClasse>(
              valeur: null,
              libelle: l.filtreTousGenres,
            ),
            for (final GenreClasse genre
                in reference?.genres ?? const <GenreClasse>[])
              EntreeFiltre<GenreClasse>(
                valeur: genre,
                libelle: _genre(genre, _filtre.type),
              ),
          ],
          onChoix: (GenreClasse? genre) =>
              _filtrer(_filtre.avec(genre: () => genre)),
        ),
        MenuFiltre<String>(
          key: const ValueKey<String>('classes-filtre-enseignant'),
          libelle: l.filtreEnseignant,
          valeur: _filtre.enseignantId,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(
              valeur: null,
              libelle: l.filtreTousEnseignants,
            ),
            // R7 : les classes sans enseignant se retrouvent d'un geste.
            EntreeFiltre<String>(
              valeur: FiltreClasses.sansEnseignant,
              libelle: l.sansEnseignant,
            ),
            for (final EnseignantFiltre e
                in reference?.enseignants ?? const <EnseignantFiltre>[])
              EntreeFiltre<String>(valeur: e.id, libelle: e.libelle),
          ],
          onChoix: (String? id) =>
              _filtrer(_filtre.avec(enseignantId: () => id)),
        ),
      ],
    );
    final Widget recherche = ChampRecherche(
      cleChamp: const ValueKey<String>('classes-recherche'),
      controleur: _recherche,
      libelle: l.rechercheLibelle,
      aide: l.rechercheAide,
      onChange: (String texte) => _filtrer(_filtre.avec(texte: texte)),
    );

    return PageShell(
      titre: t.admin.groupes.titre,
      // AD-X : la sous-navigation Operations, Espace de traitement et
      // Classes (`ongletsOperations()`).
      entete: SousNavigationDomaine(
        onglets: ongletsOperations(),
        indexActif: 1,
      ),
      defilante: false,
      // FILTRES-1b : une colonne de corps qui dit a `PageShell` la hauteur
      // qui lui manque : a 320 px texte x2, la page defile au lieu de
      // deborder, et la liste garde au moins une ligne lisible.
      child: ColonneCorps(
        minimumEtire: DataCollection.minimumLisible(context),
        children: <Widget>[
          Text(t.admin.groupes.intro, style: textes.bodyMedium),
          Ecart.vLg,
          // AD-X (ADMIN-SHELL-03) : la recherche, et « Creer » au bord de
          // fin de la meme rangee sur bureau ; au-dessus sur telephone.
          if (bureau)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: recherche),
                Ecart.hLg,
                creer,
              ],
            )
          else ...<Widget>[creer, Ecart.vLg, recherche],
          Ecart.vMd,
          filtres,
          Ecart.vXl,
          switch (lecture) {
            AsyncValue<PageClasses>(hasValue: true) => Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints contraintes) {
                  final PageClasses page = lecture.requireValue;
                  // L'inspecteur : bureau, texte sous 200 %, et la place d'un
                  // tableau a cote des 336 du panneau.
                  final bool inspecteur =
                      bureau &&
                      MediaQuery.textScalerOf(context).scale(1) < 2 &&
                      contraintes.maxWidth >=
                          GroupesPage.largeurInspecteur +
                              AppSpacing.xxl +
                              GroupesPage.largeurTableauMin;
                  final ClasseListee? choisie = inspecteur
                      ? page.lignes
                            .where((ClasseListee c) => c.id == _choisie)
                            .firstOrNull
                      : null;
                  final Widget corps = _Corps(
                    page: page,
                    choisie: choisie?.id,
                    onPage: (int numero) => setState(() => _page = numero),
                    onSelectionner: (ClasseListee classe) => inspecteur
                        ? setState(() => _choisie = classe.id)
                        : _ouvrirDetail(
                            context,
                            ref,
                            classe.groupe,
                            nom: classe.nom,
                          ),
                    onAjouter: (ClasseListee c) =>
                        _ouvrirAjout(context, ref, c.groupe, nom: c.nom),
                    onModifierSeuil: (ClasseListee c) => _ouvrirModifierSeuil(
                      context,
                      ref,
                      c.groupe,
                      nom: c.nom,
                    ),
                    onObservation: (ClasseListee c) =>
                        _ouvrirObservation(context, ref, c.groupe, nom: c.nom),
                    onCloturer: (ClasseListee c) =>
                        _ouvrirCloture(context, ref, c.groupe, nom: c.nom),
                  );
                  if (choisie == null) {
                    return corps;
                  }
                  final GroupeAdmin groupe = choisie.groupe;
                  final String nom = choisie.nom;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: corps),
                      Ecart.hXxl,
                      SizedBox(
                        width: GroupesPage.largeurInspecteur,
                        child: SingleChildScrollView(
                          key: ValueKey<String>('inspecteur-${choisie.id}'),
                          child: _Inspecteur(
                            key: GroupesPage.cleInspecteur,
                            classe: choisie,
                            onFermer: () => setState(() => _choisie = null),
                            onRetirer: (String studentId, String prenom) =>
                                _ouvrirRetrait(
                                  context,
                                  ref,
                                  groupe,
                                  studentId,
                                  prenom,
                                  nom: nom,
                                ),
                            onAjouter: () =>
                                _ouvrirAjout(context, ref, groupe, nom: nom),
                            onModifierSeuil: () => _ouvrirModifierSeuil(
                              context,
                              ref,
                              groupe,
                              nom: nom,
                            ),
                            onObservation: () => _ouvrirObservation(
                              context,
                              ref,
                              groupe,
                              nom: nom,
                            ),
                            onCloturer: () =>
                                _ouvrirCloture(context, ref, groupe, nom: nom),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AsyncValue<PageClasses>(hasError: true) => EmptyState(
              message: t.admin.groupes.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: _relire,
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

/// L'inspecteur d'une classe (AD-X, image ADMIN-SHELL-03), au bord de fin du
/// tableau sur bureau : nom et etat ; « Informations generales » ; les
/// eleves (la vraie liste des membres, « Retirer » conserve) ; les actions.
/// Il ne remplace aucune confirmation : ajout, seuil, observation et cloture
/// ouvrent leurs feuilles, motif compris.
class _Inspecteur extends StatelessWidget {
  const _Inspecteur({
    required this.classe,
    required this.onFermer,
    required this.onRetirer,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
    super.key,
  });

  final ClasseListee classe;
  final VoidCallback onFermer;
  final void Function(String studentId, String prenom) onRetirer;
  final VoidCallback onAjouter;
  final VoidCallback onModifierSeuil;
  final VoidCallback onObservation;
  final VoidCallback onCloturer;

  GroupeAdmin get groupe => classe.groupe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(classe.nom, style: textes.titleLarge),
                ),
              ),
              Ecart.hSm,
              BoutonIcone(
                icone: AppIcons.fermer,
                libelle: t.admin.groupes.inspecteurFermer,
                onPress: onFermer,
              ),
            ],
          ),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _PastilleEtat(etat: classe.etat),
          ),
          Ecart.vXxl,
          Text(t.admin.groupes.inspecteurInfos, style: textes.titleMedium),
          Ecart.vSm,
          LigneCleValeur(
            cle: t.admin.groupes.colonneEnseignant,
            valeur: classe.enseignant ?? t.admin.groupes.liste.sansEnseignant,
          ),
          Ecart.vMd,
          LigneCleValeur(
            cle: t.admin.groupes.colonneType,
            valeur: _nomType(groupe.type),
          ),
          Ecart.vMd,
          LigneCleValeur(
            cle: t.admin.groupes.colonneCreneau,
            valeur: _creneau(groupe),
          ),
          Ecart.vMd,
          LigneCleValeur(
            cle: t.admin.groupes.colonneMembres,
            valeur: t.admin.groupes.membresSur(
              actifs: '${groupe.nombreMembres}',
              seuil: '${groupe.seuilMax}',
            ),
            chiffres: true,
          ),
          Ecart.vXxl,
          _FeuilleDetail(groupe: groupe, onRetirer: onRetirer),
          if (groupe.actif) ...<Widget>[
            // Les eleves, 16, puis les actions qui agissent sur la classe.
            Ecart.vLg,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                MenuActions(
                  tooltip: classe.nom,
                  actions: <EntreeAction>[
                    EntreeAction(
                      libelle: t.admin.groupes.actionModifierSeuil,
                      onChoix: onModifierSeuil,
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionObservation,
                      onChoix: onObservation,
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionCloturer,
                      destructif: true,
                      onChoix: onCloturer,
                    ),
                  ],
                ),
                Ecart.hSm,
                Flexible(
                  child: ActionPrincipale(
                    libelle: t.admin.groupes.actionAjouter,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    onPress: onAjouter,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Le tableau des classes : une page de la liste filtree (R17), chaque classe
/// nommee sans ambiguite (R16), les classes sans enseignant visibles (R7).
class _Corps extends StatelessWidget {
  const _Corps({
    required this.page,
    required this.choisie,
    required this.onPage,
    required this.onSelectionner,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
  });

  final PageClasses page;
  final String? choisie;
  final ValueChanged<int> onPage;
  final void Function(ClasseListee classe) onSelectionner;
  final void Function(ClasseListee classe) onAjouter;
  final void Function(ClasseListee classe) onModifierSeuil;
  final void Function(ClasseListee classe) onObservation;
  final void Function(ClasseListee classe) onCloturer;

  @override
  Widget build(BuildContext context) {
    final List<ClasseListee> visibles = page.lignes;
    final l = t.admin.groupes.liste;

    if (visibles.isEmpty) {
      final bool aucune = page.totalSansFiltre == 0;
      return EmptyState(
        message: aucune
            ? t.admin.groupes.aucun
            : t.admin.groupes.aucunAvecCeFiltre,
        invitation: aucune
            ? t.admin.groupes.aucunDetail
            : t.admin.groupes.aucunAvecCeFiltreDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    final String position = l.position(
      page: '${page.page}',
      total: '${page.pages}',
    );
    return DataCollection<ClasseListee>(
      estSelectionnee: choisie == null
          ? null
          : (ClasseListee c) => c.id == choisie,
      lignes: visibles,
      cle: (ClasseListee c) => ValueKey<String>(c.id),
      onSelectionner: onSelectionner,
      // R17 : la position dans la liste, puis la navigation de page (les
      // fleches disparaissent aux bornes, NAV-FLECHES-1).
      piedDePage: Column(
        key: const ValueKey<String>('classes-pagination'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Ecart.vLg,
          TexteSansCoupure(
            l.resume(
              debut: '${page.debut}',
              fin: '${page.fin}',
              total: '${page.total}',
            ),
            key: const ValueKey<String>('classes-resume'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (page.pages > 1) ...<Widget>[
            Ecart.vSm,
            BarrePrecedentSuivant(
              position: position,
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
      ),
      colonnes: <ColonneDonnees<ClasseListee>>[
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneGroupe,
          role: RoleColonne.identifiante,
          // Largeurs en demi-parts : la classe 3, l'etat 3 (« Cloturee »
          // tient sur une ligne dans sa pastille, inspecteur ouvert a
          // 1440), les autres 2.
          flex: 3,
          // R16 : numero dans la famille de classes, code ou enseignant.
          texte: (ClasseListee c) => c.nom,
        ),
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneEnseignant,
          flex: 2,
          texte: (ClasseListee c) => c.enseignant ?? l.sansEnseignant,
        ),
        // ENS-PAYS-1 : le pays de l'enseignant, seulement quand une
        // ligne au moins le porte (pas de colonne vide avant BR-1).
        if (visibles.any(
          (ClasseListee c) =>
              PaysEnseignant.nomAffichable(c.groupe.teacherPays) != null,
        ))
          ColonneDonnees<ClasseListee>(
            titre: t.admin.groupes.colonnePays,
            flex: 2,
            // Sa propre ligne en carte (sous 1200), avec le drapeau :
            // la ligne secondaire jointe ne rendrait que du texte.
            role: RoleColonne.aPart,
            texte: (ClasseListee c) =>
                PaysEnseignant.nomAffichable(c.groupe.teacherPays) ?? '',
            rendu: (BuildContext _, ClasseListee c) =>
                PaysEnseignant(pays: c.groupe.teacherPays),
          ),
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneType,
          flex: 2,
          texte: (ClasseListee c) => _nomType(c.groupe.type),
        ),
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneCreneau,
          flex: 2,
          texte: (ClasseListee c) => _creneau(c.groupe),
        ),
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneMembres,
          flex: 2,
          tabulaire: true,
          texte: (ClasseListee c) => t.admin.groupes.membresSur(
            actifs: '${c.groupe.nombreMembres}',
            seuil: '${c.groupe.seuilMax}',
          ),
        ),
        ColonneDonnees<ClasseListee>(
          titre: t.admin.groupes.colonneEtat,
          flex: 3,
          texte: (ClasseListee c) => _libelleEtat(c.etat),
          rendu: (BuildContext _, ClasseListee c) =>
              _PastilleEtat(etat: c.etat),
        ),
        ColonneDonnees<ClasseListee>(
          titre: '',
          role: RoleColonne.aPart,
          flex: 0,
          // Vide a dessein : un menu d'actions n'a rien a dire en
          // texte. `rendreMemeSiTexteVide` fait rendre `rendu` quand
          // meme, sans faire disparaitre la cellule comme le ferait
          // un texte vide par defaut.
          texte: (ClasseListee _) => '',
          rendreMemeSiTexteVide: true,
          rendu: (BuildContext contexte, ClasseListee c) => c.groupe.actif
              ? MenuActions(
                  tooltip: c.nom,
                  actions: <EntreeAction>[
                    EntreeAction(
                      libelle: t.admin.groupes.actionAjouter,
                      onChoix: () => onAjouter(c),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionModifierSeuil,
                      onChoix: () => onModifierSeuil(c),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionObservation,
                      onChoix: () => onObservation(c),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionCloturer,
                      destructif: true,
                      onChoix: () => onCloturer(c),
                    ),
                  ],
                )
              // Une classe cloturee n'a plus d'actions. En tableau, sa
              // cellule garde la largeur du menu (sa cible tactile) : sans
              // elle, la colonne sans flex retrecit et decale la ligne.
              : DataCollection.enTableau(contexte)
              ? SizedBox.square(
                  dimension: AppMetriques.of(contexte).cibleTactile,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// L'etat d'une classe : le mot et le ton, jamais la couleur seule.
class _PastilleEtat extends StatelessWidget {
  const _PastilleEtat({required this.etat});

  final EtatClasseListee etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: _libelleEtat(etat),
    ton: switch (etat) {
      EtatClasseListee.active => TonEtat.succes,
      EtatClasseListee.attenteEnseignant => TonEtat.avertissement,
      EtatClasseListee.cloturee => TonEtat.neutre,
    },
  );
}

String _libelleEtat(EtatClasseListee etat) => switch (etat) {
  EtatClasseListee.active => t.admin.groupes.etatActif,
  EtatClasseListee.attenteEnseignant => t.admin.groupes.liste.etatAttente,
  EtatClasseListee.cloturee => t.admin.groupes.etatCloture,
};

/// « 18 h », insecable.
String _heure(int heure) =>
    LibellesGroupe.insecable(t.admin.regroupements.heure(heure: '$heure'));

/// Le genre dit selon le public filtre ; sans public, les deux accords.
String _genre(GenreClasse genre, TypePublicGroupe? type) {
  if (type != null) return libelleGenreClasse(genre, type);
  final l = t.admin.groupes.liste;
  return switch (genre) {
    GenreClasse.hommes => l.genreMasculin,
    GenreClasse.femmes => l.genreFeminin,
    GenreClasse.indetermine => t.admin.groupes.formulaire.genreIndetermine,
  };
}

String _nomType(TypePublicGroupe type) => switch (type) {
  TypePublicGroupe.enfant => t.admin.groupes.typeEnfant,
  TypePublicGroupe.adulte => t.admin.groupes.typeAdulte,
};

String _creneau(GroupeAdmin groupe) =>
    '${t.disponibilites.joursLongs[(groupe.creneau.jour - 1).clamp(0, 6)]} '
    '${groupe.creneau.heure}h';

/// Le message metier d'une exception, sans son type.
///
/// Meme forme que `admin_attribution/attribution_page.dart` : les exceptions
/// Postgrest portent le message metier en clair apres le premier « : ».
String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

void _ouvrirCreation(BuildContext context, WidgetRef ref) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.creerTitre,
    constructeur: (BuildContext contexte) => _FeuilleCreation(
      onCree: () {
        ref
          ..invalidate(groupesProvider)
          ..invalidate(pageClassesAdminProvider);
        // Toute la famille : la charge, les creneaux pris et les
        // creneaux libres de l'enseignant changent avec la classe creee
        // (sans cela, la collision D4 ne se verrait plus a la
        // reouverture de la feuille).
        ref.invalidate(enseignantsDuPortProvider);
      },
    ),
  );
}

void _ouvrirDetail(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.detailTitre(libelle: nom ?? groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleDetail(
      groupe: groupe,
      onRetirer: (String studentId, String prenom) =>
          _ouvrirRetrait(context, ref, groupe, studentId, prenom, nom: nom),
    ),
  );
}

void _ouvrirAjout(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.ajouterTitre(libelle: nom ?? groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleAjout(
      groupe: groupe,
      onAjoute: () {
        ref
          ..invalidate(groupesProvider)
          ..invalidate(pageClassesAdminProvider);
        ref.invalidate(membresGroupeProvider(groupe.id));
      },
    ),
  );
}

void _ouvrirRetrait(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe,
  String studentId,
  String prenom, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.retirerTitre(
      prenom: prenom,
      deLibelle: deDevant(nom ?? groupe.libelle),
    ),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      motifs: MotifsProposes.retraitEleve(),
      libelleEnvoyer: t.admin.groupes.retirerEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceGroupesProvider)
          .retirerEleve(
            groupeId: groupe.id,
            studentId: studentId,
            motif: motif,
          ),
      messageErreur: t.admin.groupes.retirerErreur,
      onSucces: () {
        ref
          ..invalidate(groupesProvider)
          ..invalidate(pageClassesAdminProvider);
        ref.invalidate(membresGroupeProvider(groupe.id));
      },
    ),
  );
}

void _ouvrirModifierSeuil(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.modifierSeuilTitre(
      deLibelle: deDevant(nom ?? groupe.libelle),
    ),
    constructeur: (BuildContext contexte) => _FeuilleSeuil(
      groupe: groupe,
      onModifie: () => ref
        ..invalidate(groupesProvider)
        ..invalidate(pageClassesAdminProvider),
    ),
  );
}

/// Le reglage de l'observation par les tuteurs, groupe par groupe.
///
/// **Ici et pas dans Configuration** : la RPC `definir_politique_observation_
/// groupe` prend un `p_groupe_id` et n'ecrit que sur `public.groupes`. Les
/// defauts de l'Academie, eux, vivent dans `app_config` et n'ont aujourd'hui
/// aucune fonction d'ecriture dediee -- les inscrire dans
/// `ongletsConfiguration()` ferait un onglet sans geste possible.
void _ouvrirObservation(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.observationTitre(libelle: nom ?? groupe.libelle),
    constructeur: (BuildContext contexte) => FeuilleObservationGroupe(
      groupeId: groupe.id,
      onEnregistre: () => ref
        ..invalidate(groupesProvider)
        ..invalidate(pageClassesAdminProvider),
    ),
  );
}

void _ouvrirCloture(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.cloturerTitre(libelle: nom ?? groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      motifs: MotifsProposes.clotureClasse(),
      libelleEnvoyer: t.admin.groupes.cloturerEnvoyer,
      detail: t.admin.groupes.cloturerDetail,
      onEnvoyer: (String motif) => ref
          .read(serviceGroupesProvider)
          .cloturer(groupeId: groupe.id, motif: motif),
      messageErreur: t.admin.groupes.cloturerErreur,
      onSucces: () => ref
        ..invalidate(groupesProvider)
        ..invalidate(pageClassesAdminProvider),
    ),
  );
}

/// Le seuil propose par defaut selon le public : celui que `creer_groupe`
/// applique quand on ne lui en donne aucun (5 enfants, 6 adultes, `0033`).
int _seuilParDefaut(TypePublicGroupe type) => switch (type) {
  TypePublicGroupe.enfant => 5,
  TypePublicGroupe.adulte => 6,
};

/// Les seuils proposes : tout le domaine SQL `seuil_max between 1 and 6`.
const List<int> _seuilsProposes = <int>[1, 2, 3, 4, 5, 6];

/// La plage d'heures proposee, celle de la grille de la semaine (6 h - 21 h).
const int _heureDebut = 6;
const int _heureFin = 21;

/// Le formulaire de creation d'une classe (CLASSE-FORM-1).
///
/// Semi-automatique (K-57) : le public et le genre se choisissent, la liste
/// des enseignants se classe d'elle-meme (le plus adapte en premier, D5), le
/// creneau se choisit dans les creneaux libres de l'enseignant ou dans une
/// grille 6 h - 21 h (D6), le seuil est prerempli selon le public (D7) et le
/// nom se deduit du reste (D8), seul champ qui se tape. Le bouton ne se grise
/// jamais (K-56) : presse trop tot, il dit le premier champ qui manque.
class _FeuilleCreation extends ConsumerStatefulWidget {
  const _FeuilleCreation({required this.onCree});

  final VoidCallback onCree;

  @override
  ConsumerState<_FeuilleCreation> createState() => _FeuilleCreationEtat();
}

class _FeuilleCreationEtat extends ConsumerState<_FeuilleCreation> {
  TypePublicGroupe _type = TypePublicGroupe.enfant;
  GenreClasse? _genre;
  String? _enseignantId;
  int? _jour;
  int? _heure;
  late int? _seuil = _seuilParDefaut(_type);
  bool _seuilChoisi = false;
  late final TextEditingController _nom = TextEditingController(
    text: _nomPropose,
  );
  bool _nomSaisi = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  /// Le nom deduit : le genre (ou le public, si le genre n'est pas
  /// determine), puis le creneau des qu'il est choisi (D8).
  String get _nomPropose {
    final GenreClasse? genre = _genre;
    final String base = genre == null || genre == GenreClasse.indetermine
        ? _nomType(_type)
        : libelleGenreClasse(genre, _type);
    final int? jour = _jour;
    final int? heure = _heure;
    if (jour == null || heure == null) return base;
    return t.admin.groupes.formulaire.nomPropose(
      base: base,
      creneau: nommerHeure((jour: jour, heure: heure)),
    );
  }

  /// Applique un choix, efface le message, et repropose le nom tant que
  /// l'admin ne l'a pas ecrit lui-meme.
  void _maj(VoidCallback changement) {
    setState(() {
      changement();
      _erreur = null;
      if (!_nomSaisi) _nom.text = _nomPropose;
    });
  }

  /// Le fuseau du creneau, deduit (D6) : celui de l'enseignant quand
  /// l'adaptateur le transmet, sinon celui que le serveur retient.
  ({String fuseau, String phrase}) _fuseau(
    PortCreationClasse creation,
    EnseignantPropose? enseignant,
  ) {
    final f = t.admin.groupes.formulaire;
    if (!creation.retientFuseau) {
      return (
        fuseau: fuseauServeurParDefaut,
        phrase: f.fuseauNonTransmis(fuseau: fuseauServeurParDefaut),
      );
    }
    final String? propre = enseignant?.fuseauIana;
    return propre == null
        ? (
            fuseau: fuseauServeurParDefaut,
            phrase: f.fuseauDefaut(fuseau: fuseauServeurParDefaut),
          )
        : (fuseau: propre, phrase: f.fuseauEnseignant(fuseau: propre));
  }

  /// Le premier champ qui manque, dans l'ordre de la feuille ; nul quand
  /// tout est la.
  ///
  /// Un enseignant choisi mais absent de la liste classee (elle se recharge
  /// apres un changement de public, ou sa lecture a echoue) n'a pas pu etre
  /// verifie (genre, collision) : rien ne part, et le fuseau n'est pas
  /// devine.
  String? _manque(EnseignantClasse? choisi) {
    final f = t.admin.groupes.formulaire;
    final GenreClasse? genre = _genre;
    if (genre == null) return f.manqueGenre;
    if (_enseignantId == null) return t.admin.groupes.manqueEnseignant;
    if (_jour == null || _heure == null) return f.manqueCreneau;
    if (choisi == null) return f.manqueListeEnseignants;
    if (!choisi.choisissable) {
      return manqueEnseignantClasse(choisi, genre, _type);
    }
    if (_seuil == null) return f.manqueSeuil;
    if (_nom.text.trim().isEmpty) return f.manqueNom;
    return null;
  }

  Future<void> _creer(EnseignantClasse? choisi, String fuseau) async {
    final String? manque = _manque(choisi);
    final GenreClasse? genre = _genre;
    final String? enseignantId = _enseignantId;
    final int? jour = _jour;
    final int? heure = _heure;
    final int? seuil = _seuil;
    if (manque != null ||
        genre == null ||
        enseignantId == null ||
        jour == null ||
        heure == null ||
        seuil == null) {
      setState(() => _erreur = manque);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portCreationClasseProvider)
          .creer(
            teacherId: enseignantId,
            type: _type,
            genre: genre,
            libelle: _nom.text.trim(),
            creneau: Creneau(jour: jour, heure: heure, fuseau: fuseau),
            seuilMax: seuil,
          );
      widget.onCree();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () =>
              _erreur = t.admin.groupes.creerErreur(message: _message(erreur)),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.admin.groupes.formulaire;
    final PortCreationClasse creation = ref.watch(portCreationClasseProvider);
    final AsyncValue<List<EnseignantPropose>> source = ref.watch(
      enseignantsPourClasseProvider(_type),
    );
    final int? jour = _jour;
    final int? heure = _heure;
    final Creneau? creneau = jour == null || heure == null
        ? null
        : Creneau(jour: jour, heure: heure, fuseau: fuseauServeurParDefaut);

    // L'echec d'abord, comme la source : un echec de lecture se voit.
    final AsyncValue<List<EnseignantClasse>> classes = source.hasError
        ? AsyncError<List<EnseignantClasse>>(
            source.error!,
            source.stackTrace ?? StackTrace.empty,
          )
        : source.hasValue
        ? AsyncData<List<EnseignantClasse>>(
            classerEnseignants(
              source.requireValue,
              genre: _genre,
              creneau: creneau,
            ),
          )
        : const AsyncLoading<List<EnseignantClasse>>();
    final EnseignantClasse? choisi = classes.value
        ?.where((EnseignantClasse l) => l.enseignant.id == _enseignantId)
        .firstOrNull;
    final ({String fuseau, String phrase}) fuseau = _fuseau(
      creation,
      choisi?.enseignant,
    );
    // Ce que la source sait vraiment : les phrases qui promettent un filtre
    // par genre ou un classement par creneau libre n'apparaissent que si
    // elle le dit (repli sur les comptes : ni l'un ni l'autre).
    final List<EnseignantPropose> lus =
        source.value ?? const <EnseignantPropose>[];
    final bool genreConnu = lus.any((EnseignantPropose e) => e.genre != null);
    final bool disposConnues = lus.any(
      (EnseignantPropose e) => e.creneauxLibres != null,
    );

    final AsyncValue<List<PersonneProposee>> personnes = classes.hasValue
        ? AsyncData<List<PersonneProposee>>(<PersonneProposee>[
            for (final EnseignantClasse l in classes.requireValue)
              PersonneProposee(
                id: l.enseignant.id,
                nom: l.enseignant.libelle,
                identifiant: l.enseignant.identifiant,
                mention: mentionEnseignant(l, avecCreneau: creneau != null),
                raisonIndisponible: raisonEnseignant(l, _genre, _type),
              ),
          ])
        : classes.hasError
        ? AsyncError<List<PersonneProposee>>(
            classes.error!,
            classes.stackTrace ?? StackTrace.empty,
          )
        : const AsyncLoading<List<PersonneProposee>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // K-58 : une phrase de contexte ouvre la feuille.
        TexteSansCoupure(f.contexte, style: textes.bodyMedium),
        Ecart.vSm,
        TexteSansCoupure(
          t.formulaire.legendeObligatoire,
          style: textes.bodySmall,
        ),
        Ecart.vXxl,

        // 1. Public : choisi, deux cartes qui disent leur consequence.
        TitreChamp(f.titrePublic, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_type.name}),
          options: <OptionChoix>[
            OptionChoix(
              cle: const ValueKey<String>('classe-public-enfant'),
              valeur: TypePublicGroupe.enfant.name,
              libelle: t.admin.groupes.typeEnfant,
              description: f.publicEnfantDetail,
            ),
            OptionChoix(
              cle: const ValueKey<String>('classe-public-adulte'),
              valeur: TypePublicGroupe.adulte.name,
              libelle: t.admin.groupes.typeAdulte,
              description: f.publicAdulteDetail,
            ),
          ],
          onChange: (ReponseChoix r) {
            final TypePublicGroupe? type = TypePublicGroupe.values
                .where((TypePublicGroupe v) => r.valeurs.contains(v.name))
                .firstOrNull;
            if (type == null) return;
            _maj(() {
              _type = type;
              if (!_seuilChoisi) _seuil = _seuilParDefaut(type);
            });
          },
        ),
        Ecart.vXs,

        // 2. Genre : choisi, obligatoire, aucune presélection (D1).
        TitreChamp(f.titreGenre, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final GenreClasse g in GenreClasse.values)
              OptionChoix(
                cle: ValueKey<String>('classe-genre-${g.name}'),
                valeur: g.name,
                libelle: libelleGenreClasse(g, _type),
                description: detailGenreClasse(
                  g,
                  _type,
                  genreConnu: genreConnu,
                ),
              ),
          ],
          onChange: (ReponseChoix r) {
            final GenreClasse? genre = GenreClasse.values
                .where((GenreClasse g) => r.valeurs.contains(g.name))
                .firstOrNull;
            _maj(() => _genre = genre);
          },
        ),
        if (!creation.retientGenre) ...<Widget>[
          TexteSansCoupure(f.genreNonEnregistre, style: textes.bodySmall),
          Ecart.vXl,
        ] else
          Ecart.vXs,

        // 3. Enseignant : choisi dans une liste classee (D2, D4, D5).
        SelecteurPersonne(
          sorte: SortePersonne.enseignant,
          personnes: personnes,
          choisie: _enseignantId,
          obligatoire: true,
          aide: genreConnu && disposConnues
              ? f.aideEnseignant
              : f.aideEnseignantSansSource,
          onChoix: (PersonneProposee p) => _maj(() => _enseignantId = p.id),
          onReessayer: () {
            ref.invalidate(enseignantsDuPortProvider(_type));
            ref.invalidate(comptesProvider);
          },
        ),
        Ecart.vXl,

        // 4. Creneau : choisi, jamais tape (D6).
        TitreChamp(
          f.titreCreneau,
          style: textes.titleMedium,
          obligatoire: true,
        ),
        Ecart.vXs,
        TexteSansCoupure(f.creneauContexte, style: textes.bodySmall),
        Ecart.vMd,
        if (choisi != null) ...<Widget>[
          ..._creneauxLibres(choisi.enseignant, textes),
          Ecart.vLg,
        ],
        TexteSansCoupure(f.jour, style: textes.labelLarge),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : le jour de la classe a creer.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int j = 1; j <= 7; j++)
              FilterPill(
                key: ValueKey<String>('classe-jour-$j'),
                libelle: jourCapitalise(j),
                retenue: _jour == j,
                onPress: () => _maj(() => _jour = j),
              ),
          ],
        ),
        Ecart.vLg,
        TexteSansCoupure(f.heure, style: textes.labelLarge),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('classe-heure'),
            libelle: f.heure,
            valeur: _heure,
            entrees: <EntreeFiltre<int>>[
              for (int h = _heureDebut; h <= _heureFin; h++)
                EntreeFiltre<int>(
                  valeur: h,
                  libelle: LibellesGroupe.insecable(f.heureValeur(heure: '$h')),
                ),
            ],
            onChoix: (int? h) {
              if (h != null) _maj(() => _heure = h);
            },
          ),
        ),
        Ecart.vSm,
        TexteSansCoupure(fuseau.phrase, style: textes.bodySmall),
        Ecart.vXl,

        // 5. Seuil : deduit puis choisi, 1 a 6 (D7).
        TitreChamp(f.titreSeuil, style: textes.titleMedium, obligatoire: true),
        Ecart.vXs,
        TexteSansCoupure(f.seuilDetail, style: textes.bodySmall),
        Ecart.vMd,
        SelecteurEntier(
          // Repart de la valeur du parent quand le public la change.
          key: ValueKey<String>('classe-seuil-$_seuil'),
          proposees: _seuilsProposes,
          min: 1,
          max: 6,
          affichage: (int n) => f.seuilValeur(n: n),
          valeurInitiale: _seuil,
          onChange: (int? v) => _maj(() {
            _seuil = v;
            _seuilChoisi = true;
          }),
        ),
        Ecart.vXl,

        // 6. Nom : deduit, modifiable ; seul champ tape (D8).
        ChampEtiquete(
          key: const ValueKey<String>('classe-nom'),
          libelle: f.titreNom,
          controller: _nom,
          obligatoire: true,
          aide: f.nomDetail,
          onChanged: (String texte) => setState(() {
            _nomSaisi = texte.trim().isNotEmpty && texte != _nomPropose;
            _erreur = null;
          }),
        ),
        if (_erreur case final String erreur) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        BasDeFeuille(
          libelle: t.admin.groupes.creerEnvoyer,
          enCours: _envoi,
          horsLigne: f.horsLigne,
          onPress: () => _creer(choisi, fuseau.fuseau),
        ),
        Ecart.vMd,
        TexteSansCoupure(
          t.admin.groupes.journalisation,
          style: textes.bodySmall,
        ),
      ],
    );
  }

  /// Les creneaux libres de l'enseignant choisi, mis en avant (D6) : une
  /// puce par creneau, qui regle le jour et l'heure d'un coup.
  List<Widget> _creneauxLibres(EnseignantPropose e, TextTheme textes) {
    final f = t.admin.groupes.formulaire;
    final List<Creneau>? libres = e.creneauxLibres;
    if (libres == null) {
      return <Widget>[
        TexteSansCoupure(
          f.disponibilitesInconnues(
            deNom: deDevant(
              e.libelle,
              cle: 'admin.groupes.formulaire.disponibilitesInconnues',
            ),
          ),
          style: textes.bodySmall,
        ),
      ];
    }
    if (libres.isEmpty) {
      return <Widget>[
        TexteSansCoupure(
          f.aucunCreneauLibre(nom: e.libelle),
          style: textes.bodySmall,
        ),
      ];
    }
    final List<Creneau> tries = <Creneau>[...libres]
      ..sort(
        (Creneau a, Creneau b) => a.jour != b.jour
            ? a.jour.compareTo(b.jour)
            : a.heure.compareTo(b.heure),
      );
    return <Widget>[
      TexteSansCoupure(
        f.creneauxLibresDe(
          deNom: deDevant(
            e.libelle,
            cle: 'admin.groupes.formulaire.creneauxLibresDe',
          ),
        ),
        style: textes.labelLarge,
      ),
      Ecart.vSm,
      // Choix de formulaire, pas un filtre : un creneau libre de l'enseignant.
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final Creneau c in tries)
            FilterPill(
              key: ValueKey<String>('classe-libre-${c.jour}-${c.heure}'),
              libelle: nommerHeure((jour: c.jour, heure: c.heure)),
              retenue: _jour == c.jour && _heure == c.heure,
              onPress: () => _maj(() {
                _jour = c.jour;
                _heure = c.heure;
              }),
            ),
        ],
      ),
    ];
  }
}

/// Le detail d'un groupe : ses membres.
class _FeuilleDetail extends ConsumerWidget {
  const _FeuilleDetail({required this.groupe, required this.onRetirer});

  final GroupeAdmin groupe;
  final void Function(String studentId, String prenom) onRetirer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MembreGroupe>> membres = ref.watch(
      membresGroupeProvider(groupe.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.admin.groupes.detailMembres,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vMd,
        switch (membres) {
          AsyncValue<List<MembreGroupe>>(hasValue: true) =>
            membres.requireValue.isEmpty
                ? Text(t.admin.groupes.detailAucunMembre)
                : Column(
                    children: <Widget>[
                      for (final MembreGroupe membre in membres.requireValue)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(membre.libelle),
                          trailing: MenuActions(
                            tooltip: membre.libelle,
                            actions: <EntreeAction>[
                              EntreeAction(
                                libelle: t.admin.groupes.actionRetirer,
                                destructif: true,
                                onChoix: () =>
                                    onRetirer(membre.studentId, membre.libelle),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          AsyncValue<List<MembreGroupe>>(hasError: true) => Text(
            t.admin.groupes.erreur,
          ),
          _ => const Skeleton.liste(lignes: 3),
        },
      ],
    );
  }
}

/// Le formulaire d'ajout d'un eleve a un groupe.
class _FeuilleAjout extends StatefulWidget {
  const _FeuilleAjout({required this.groupe, required this.onAjoute});

  final GroupeAdmin groupe;
  final VoidCallback onAjoute;

  @override
  State<_FeuilleAjout> createState() => _FeuilleAjoutEtat();
}

class _FeuilleAjoutEtat extends State<_FeuilleAjout> {
  final TextEditingController _motif = TextEditingController();

  /// L'eleve choisi dans la liste (FORM-L2) : plus d'identifiant tape.
  String? _eleveId;
  bool _envoi = false;
  String? _erreur;

  /// Vrai quand le motif manque : il se dit sous les puces.
  bool _motifManquant = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _ajouter(WidgetRef ref) async {
    final String? eleveId = _eleveId;
    final bool sansMotif = _motif.text.trim().isEmpty;
    // Bouton jamais grise (K-56) : il dit ce qui manque, chaque chose a sa
    // place (l'eleve sous la liste, le motif sous les puces).
    if (eleveId == null || sansMotif) {
      setState(() {
        _erreur = eleveId == null ? t.admin.groupes.manqueEleve : null;
        _motifManquant = sansMotif;
      });
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _motifManquant = false;
    });
    try {
      await ref
          .read(serviceGroupesProvider)
          .ajouterEleve(
            groupeId: widget.groupe.id,
            studentId: eleveId,
            motif: _motif.text.trim(),
          );
      widget.onAjoute();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () =>
            _erreur = t.admin.groupes.ajouterErreur(message: _message(erreur)),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SelecteurPersonne(
            sorte: SortePersonne.eleve,
            personnes: ref.watch(personnesProposablesProvider(AppRole.student)),
            choisie: _eleveId,
            onChoix: (PersonneProposee p) => setState(() {
              _eleveId = p.id;
              _erreur = null;
            }),
            onReessayer: () => ref.invalidate(comptesProvider),
          ),
          Ecart.vLg,
          Text(
            t.admin.groupes.motifRequis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vSm,
          SelecteurMotif(
            motifs: MotifsProposes.ajoutEleve(),
            controleur: _motif,
            libelleChamp: t.admin.groupes.champMotif,
            erreur: _motifManquant ? t.formulaire.motif.manque : null,
            onChange: (String _) => setState(() => _motifManquant = false),
          ),
          if (_erreur != null) ...<Widget>[
            Ecart.vMd,
            Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.groupes.ajouterEnvoyer,
            enCours: _envoi,
            onPress: () => _ajouter(ref),
          ),
          Ecart.vMd,
          Text(
            t.admin.groupes.journalisation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Le formulaire du seuil maximal : le meme selecteur 1 a 6 que la creation
/// (D7), et un bouton qui ne se grise plus (K-56) : sans valeur, le presser
/// dit ce qui manque.
class _FeuilleSeuil extends ConsumerStatefulWidget {
  const _FeuilleSeuil({required this.groupe, required this.onModifie});

  final GroupeAdmin groupe;
  final VoidCallback onModifie;

  @override
  ConsumerState<_FeuilleSeuil> createState() => _FeuilleSeuilEtat();
}

class _FeuilleSeuilEtat extends ConsumerState<_FeuilleSeuil> {
  // Une valeur hors du domaine 1..6 (donnee ancienne) n'est pas retenue :
  // l'admin en choisit une, rien n'est arrondi en silence.
  late int? _seuil = _seuilsProposes.contains(widget.groupe.seuilMax)
      ? widget.groupe.seuilMax
      : null;
  bool _envoi = false;
  String? _erreur;

  Future<void> _modifier() async {
    final int? seuil = _seuil;
    if (seuil == null) {
      setState(() => _erreur = t.admin.groupes.formulaire.manqueSeuil);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceGroupesProvider)
          .modifier(
            groupeId: widget.groupe.id,
            libelle: widget.groupe.libelle,
            seuilMax: seuil,
            creneau: widget.groupe.creneau,
          );
      widget.onModifie();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.admin.groupes.modifierSeuilErreur(
            message: _message(erreur),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.admin.groupes.formulaire;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(f.seuilDetail, style: textes.bodyMedium),
        Ecart.vMd,
        SelecteurEntier(
          proposees: _seuilsProposes,
          min: 1,
          max: 6,
          affichage: (int n) => f.seuilValeur(n: n),
          valeurInitiale: _seuil,
          onChange: (int? v) => setState(() {
            _seuil = v;
            _erreur = null;
          }),
        ),
        if (_erreur case final String erreur) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        BasDeFeuille(
          libelle: t.admin.groupes.modifierSeuilEnvoyer,
          enCours: _envoi,
          horsLigne: f.seuilHorsLigne,
          onPress: _modifier,
        ),
      ],
    );
  }
}

/// Une feuille generique « motif requis, un bouton » : retrait ou cloture.
class _FeuilleMotif extends StatefulWidget {
  const _FeuilleMotif({
    required this.motifs,
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
    this.detail,
  });

  /// Les motifs proposes en puces (FORM-L1), « Autre » en dernier.
  final List<String> motifs;
  final String libelleEnvoyer;
  final Future<void> Function(String motif) onEnvoyer;
  final String Function({required String message}) messageErreur;
  final VoidCallback onSucces;
  final String? detail;

  @override
  State<_FeuilleMotif> createState() => _FeuilleMotifEtat();
}

class _FeuilleMotifEtat extends State<_FeuilleMotif> {
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  bool _motifManquant = false;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    // Bouton jamais grise (K-56) : sans motif, on dit ce qui manque.
    if (_motif.text.trim().isEmpty) {
      setState(() => _motifManquant = true);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(_motif.text.trim());
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(() => _erreur = widget.messageErreur(message: _message(erreur)));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.detail != null) ...<Widget>[
          Text(widget.detail!, style: Theme.of(context).textTheme.bodyMedium),
          Ecart.vMd,
        ],
        Text(
          t.admin.groupes.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        SelecteurMotif(
          motifs: widget.motifs,
          controleur: _motif,
          libelleChamp: t.admin.groupes.champMotif,
          erreur: _motifManquant ? t.formulaire.motif.manque : null,
          onChange: (String _) => setState(() => _motifManquant = false),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: widget.libelleEnvoyer,
          enCours: _envoi,
          onPress: _envoyer,
        ),
      ],
    );
  }
}
