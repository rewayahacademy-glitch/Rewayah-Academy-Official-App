import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/admin/enseignants_classe.dart';
import '../../core/admin/personnes_proposables.dart';
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
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_etiquete.dart';
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
import '../creneaux/plages.dart' show jourCapitalise, nommerHeure;
import 'feuille_observation_groupe.dart';

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
  /// Le filtre de public. `null` veut dire « tous ».
  TypePublicGroupe? _type;

  /// Le filtre d'etat (AD-X, onglets de l'image ADMIN-SHELL-03) : `null`
  /// toutes les classes, vrai les actives, faux les cloturees.
  bool? _actives;

  /// La classe ouverte dans l'inspecteur (bureau), par son identifiant.
  String? _choisie;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<GroupeAdmin>> groupes = ref.watch(groupesProvider);
    final List<GroupeAdmin> tous = groupes.value ?? const <GroupeAdmin>[];
    final bool bureau = DataCollection.enTableau(context);

    final Widget creer = ActionPrincipale(
      libelle: t.admin.groupes.creer,
      pleineLargeur: false,
      onPress: () => _ouvrirCreation(context, ref),
    );
    // FILTRES-1 : une seule rangee de puces, qui defile quand elle ne tient
    // pas (porte par JONCTION-LIGNES-1 sur les onglets d'etat d'AD-X).
    final Widget statuts = RangeeFiltres(
      filtres: <Widget>[
        FilterPill(
          libelle: t.admin.groupes.filtreToutes,
          compteur: tous.length,
          retenue: _actives == null,
          onPress: () => setState(() => _actives = null),
        ),
        FilterPill(
          libelle: t.admin.groupes.filtreActives,
          compteur: tous.where((GroupeAdmin g) => g.actif).length,
          retenue: _actives ?? false,
          onPress: () => setState(() => _actives = true),
        ),
        FilterPill(
          libelle: t.admin.groupes.filtreCloturees,
          compteur: tous.where((GroupeAdmin g) => !g.actif).length,
          retenue: _actives == false,
          onPress: () => setState(() => _actives = false),
        ),
        // Le public de la classe, dans la meme rangee (FILTRES-1 : une seule
        // rangee de filtres par ecran).
        MenuFiltre<TypePublicGroupe>(
          libelle: t.admin.groupes.filtrePublic,
          valeur: _type,
          entrees: <EntreeFiltre<TypePublicGroupe>>[
            EntreeFiltre<TypePublicGroupe>(
              valeur: null,
              libelle: t.admin.groupes.filtreTousTypes,
              compteur: tous.length,
            ),
            for (final TypePublicGroupe valeur in TypePublicGroupe.values)
              EntreeFiltre<TypePublicGroupe>(
                valeur: valeur,
                libelle: _nomType(valeur),
                compteur: tous
                    .where((GroupeAdmin g) => g.type == valeur)
                    .length,
              ),
          ],
          onChoix: (TypePublicGroupe? type) => setState(() => _type = type),
        ),
      ],
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
          // AD-X (ADMIN-SHELL-03) : les onglets d'etat, et « Creer » au bord
          // de fin de la meme rangee sur bureau ; au-dessus sur telephone.
          if (bureau)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: statuts),
                Ecart.hLg,
                creer,
              ],
            )
          else ...<Widget>[creer, Ecart.vLg, statuts],
          Ecart.vXl,
          switch (groupes) {
            AsyncValue<List<GroupeAdmin>>(hasValue: true) => Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints contraintes) {
                  // L'inspecteur : bureau, texte sous 200 %, et la place d'un
                  // tableau a cote des 336 du panneau.
                  final bool inspecteur =
                      bureau &&
                      MediaQuery.textScalerOf(context).scale(1) < 2 &&
                      contraintes.maxWidth >=
                          GroupesPage.largeurInspecteur +
                              AppSpacing.xxl +
                              GroupesPage.largeurTableauMin;
                  final GroupeAdmin? choisie = inspecteur
                      ? groupes.requireValue
                            .where((GroupeAdmin g) => g.id == _choisie)
                            .firstOrNull
                      : null;
                  final Widget corps = _Corps(
                    groupes: groupes.requireValue,
                    type: _type,
                    actives: _actives,
                    choisie: choisie?.id,
                    onSelectionner: (GroupeAdmin groupe) => inspecteur
                        ? setState(() => _choisie = groupe.id)
                        : _ouvrirDetail(context, ref, groupe),
                    onAjouter: (GroupeAdmin groupe) =>
                        _ouvrirAjout(context, ref, groupe),
                    onModifierSeuil: (GroupeAdmin groupe) =>
                        _ouvrirModifierSeuil(context, ref, groupe),
                    onObservation: (GroupeAdmin groupe) =>
                        _ouvrirObservation(context, ref, groupe),
                    onCloturer: (GroupeAdmin groupe) =>
                        _ouvrirCloture(context, ref, groupe),
                  );
                  if (choisie == null) {
                    return corps;
                  }
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
                            groupe: choisie,
                            onFermer: () => setState(() => _choisie = null),
                            onRetirer: (String studentId, String prenom) =>
                                _ouvrirRetrait(
                                  context,
                                  ref,
                                  choisie,
                                  studentId,
                                  prenom,
                                ),
                            onAjouter: () =>
                                _ouvrirAjout(context, ref, choisie),
                            onModifierSeuil: () =>
                                _ouvrirModifierSeuil(context, ref, choisie),
                            onObservation: () =>
                                _ouvrirObservation(context, ref, choisie),
                            onCloturer: () =>
                                _ouvrirCloture(context, ref, choisie),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AsyncValue<List<GroupeAdmin>>(hasError: true) => EmptyState(
              message: t.admin.groupes.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(groupesProvider),
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
    required this.groupe,
    required this.onFermer,
    required this.onRetirer,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
    super.key,
  });

  final GroupeAdmin groupe;
  final VoidCallback onFermer;
  final void Function(String studentId, String prenom) onRetirer;
  final VoidCallback onAjouter;
  final VoidCallback onModifierSeuil;
  final VoidCallback onObservation;
  final VoidCallback onCloturer;

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
                  child: Text(groupe.libelle, style: textes.titleLarge),
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
            child: StatusPill(
              libelle: groupe.actif
                  ? t.admin.groupes.etatActif
                  : t.admin.groupes.etatCloture,
              ton: groupe.actif ? TonEtat.succes : TonEtat.neutre,
            ),
          ),
          Ecart.vXxl,
          Text(t.admin.groupes.inspecteurInfos, style: textes.titleMedium),
          Ecart.vSm,
          LigneCleValeur(
            cle: t.admin.groupes.colonneEnseignant,
            valeur: groupe.teacherLibelle,
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
                  tooltip: groupe.libelle,
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

/// Le tableau des classes, filtre par public et par etat.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.groupes,
    required this.type,
    required this.actives,
    required this.choisie,
    required this.onSelectionner,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
  });

  final List<GroupeAdmin> groupes;
  final TypePublicGroupe? type;
  final bool? actives;
  final String? choisie;
  final void Function(GroupeAdmin groupe) onSelectionner;
  final void Function(GroupeAdmin groupe) onAjouter;
  final void Function(GroupeAdmin groupe) onModifierSeuil;
  final void Function(GroupeAdmin groupe) onObservation;
  final void Function(GroupeAdmin groupe) onCloturer;

  @override
  Widget build(BuildContext context) {
    final List<GroupeAdmin> visibles = groupes
        .where(
          (GroupeAdmin g) =>
              (type == null || g.type == type) &&
              (actives == null || g.actif == actives),
        )
        .toList(growable: false);

    if (visibles.isEmpty) {
      return EmptyState(
        message: groupes.isEmpty
            ? t.admin.groupes.aucun
            : t.admin.groupes.aucunAvecCeFiltre,
        invitation: groupes.isEmpty
            ? t.admin.groupes.aucunDetail
            : t.admin.groupes.aucunAvecCeFiltreDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    return DataCollection<GroupeAdmin>(
      estSelectionnee: choisie == null
          ? null
          : (GroupeAdmin g) => g.id == choisie,
      lignes: visibles,
      cle: (GroupeAdmin g) => ValueKey<String>(g.id),
      onSelectionner: onSelectionner,
      colonnes: <ColonneDonnees<GroupeAdmin>>[
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneGroupe,
          role: RoleColonne.identifiante,
          // Largeurs en demi-parts : la classe 3, l'etat 3 (« Cloturee »
          // tient sur une ligne dans sa pastille, inspecteur ouvert a
          // 1440), les autres 2.
          flex: 3,
          texte: (GroupeAdmin g) => g.libelle,
        ),
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneEnseignant,
          flex: 2,
          texte: (GroupeAdmin g) => g.teacherLibelle,
        ),
        // ENS-PAYS-1 : le pays de l'enseignant, seulement quand une
        // ligne au moins le porte (pas de colonne vide avant BR-1).
        if (visibles.any(
          (GroupeAdmin g) =>
              PaysEnseignant.nomAffichable(g.teacherPays) != null,
        ))
          ColonneDonnees<GroupeAdmin>(
            titre: t.admin.groupes.colonnePays,
            flex: 2,
            // Sa propre ligne en carte (sous 1200), avec le drapeau :
            // la ligne secondaire jointe ne rendrait que du texte.
            role: RoleColonne.aPart,
            texte: (GroupeAdmin g) =>
                PaysEnseignant.nomAffichable(g.teacherPays) ?? '',
            rendu: (BuildContext _, GroupeAdmin g) =>
                PaysEnseignant(pays: g.teacherPays),
          ),
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneType,
          flex: 2,
          texte: (GroupeAdmin g) => _nomType(g.type),
        ),
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneCreneau,
          flex: 2,
          texte: _creneau,
        ),
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneMembres,
          flex: 2,
          tabulaire: true,
          texte: (GroupeAdmin g) => t.admin.groupes.membresSur(
            actifs: '${g.nombreMembres}',
            seuil: '${g.seuilMax}',
          ),
        ),
        ColonneDonnees<GroupeAdmin>(
          titre: t.admin.groupes.colonneEtat,
          flex: 3,
          texte: (GroupeAdmin g) =>
              g.actif ? t.admin.groupes.etatActif : t.admin.groupes.etatCloture,
          rendu: (BuildContext _, GroupeAdmin g) => StatusPill(
            libelle: g.actif
                ? t.admin.groupes.etatActif
                : t.admin.groupes.etatCloture,
            ton: g.actif ? TonEtat.succes : TonEtat.neutre,
          ),
        ),
        ColonneDonnees<GroupeAdmin>(
          titre: '',
          role: RoleColonne.aPart,
          flex: 0,
          // Vide a dessein : un menu d'actions n'a rien a dire en
          // texte. `rendreMemeSiTexteVide` fait rendre `rendu` quand
          // meme, sans faire disparaitre la cellule comme le ferait
          // un texte vide par defaut.
          texte: (GroupeAdmin _) => '',
          rendreMemeSiTexteVide: true,
          rendu: (BuildContext contexte, GroupeAdmin g) => g.actif
              ? MenuActions(
                  tooltip: g.libelle,
                  actions: <EntreeAction>[
                    EntreeAction(
                      libelle: t.admin.groupes.actionAjouter,
                      onChoix: () => onAjouter(g),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionModifierSeuil,
                      onChoix: () => onModifierSeuil(g),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionObservation,
                      onChoix: () => onObservation(g),
                    ),
                    EntreeAction(
                      libelle: t.admin.groupes.actionCloturer,
                      destructif: true,
                      onChoix: () => onCloturer(g),
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
        ref.invalidate(groupesProvider);
        // Toute la famille : la charge, les creneaux pris et les
        // creneaux libres de l'enseignant changent avec la classe creee
        // (sans cela, la collision D4 ne se verrait plus a la
        // reouverture de la feuille).
        ref.invalidate(enseignantsDuPortProvider);
      },
    ),
  );
}

void _ouvrirDetail(BuildContext context, WidgetRef ref, GroupeAdmin groupe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.detailTitre(libelle: groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleDetail(
      groupe: groupe,
      onRetirer: (String studentId, String prenom) =>
          _ouvrirRetrait(context, ref, groupe, studentId, prenom),
    ),
  );
}

void _ouvrirAjout(BuildContext context, WidgetRef ref, GroupeAdmin groupe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.ajouterTitre(libelle: groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleAjout(
      groupe: groupe,
      onAjoute: () {
        ref.invalidate(groupesProvider);
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
  String prenom,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.retirerTitre(
      prenom: prenom,
      deLibelle: deDevant(groupe.libelle),
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
        ref.invalidate(groupesProvider);
        ref.invalidate(membresGroupeProvider(groupe.id));
      },
    ),
  );
}

void _ouvrirModifierSeuil(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.modifierSeuilTitre(
      deLibelle: deDevant(groupe.libelle),
    ),
    constructeur: (BuildContext contexte) => _FeuilleSeuil(
      groupe: groupe,
      onModifie: () => ref.invalidate(groupesProvider),
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
  GroupeAdmin groupe,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.observationTitre(libelle: groupe.libelle),
    constructeur: (BuildContext contexte) => FeuilleObservationGroupe(
      groupeId: groupe.id,
      onEnregistre: () => ref.invalidate(groupesProvider),
    ),
  );
}

void _ouvrirCloture(BuildContext context, WidgetRef ref, GroupeAdmin groupe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.cloturerTitre(libelle: groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      motifs: MotifsProposes.clotureClasse(),
      libelleEnvoyer: t.admin.groupes.cloturerEnvoyer,
      detail: t.admin.groupes.cloturerDetail,
      onEnvoyer: (String motif) => ref
          .read(serviceGroupesProvider)
          .cloturer(groupeId: groupe.id, motif: motif),
      messageErreur: t.admin.groupes.cloturerErreur,
      onSucces: () => ref.invalidate(groupesProvider),
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

/// Le genre de la classe dit selon le public (accord par contexte).
String _libelleGenre(GenreClasse genre, TypePublicGroupe type) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch (genre) {
    GenreClasse.hommes => enfants ? f.genreGarcons : f.genreHommes,
    GenreClasse.femmes => enfants ? f.genreFilles : f.genreFemmes,
    GenreClasse.indetermine => f.genreIndetermine,
  };
}

/// Quand choisir ce genre, et ce qu'il change (K-58).
///
/// La consequence annoncee est celle qui se produit : quand la source ne dit
/// le genre d'aucun enseignant ([genreConnu] faux, repli sur les comptes),
/// la liste n'ecarte personne, et la phrase le dit au lieu de promettre un
/// filtre qui n'a pas lieu (D1 : ne rien pretendre).
String _detailGenre(
  GenreClasse genre,
  TypePublicGroupe type, {
  required bool genreConnu,
}) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch ((genre, genreConnu)) {
    (GenreClasse.hommes, true) =>
      enfants ? f.genreGarconsDetail : f.genreHommesDetail,
    (GenreClasse.hommes, false) =>
      enfants ? f.genreGarconsDetailSansSource : f.genreHommesDetailSansSource,
    (GenreClasse.femmes, true) =>
      enfants ? f.genreFillesDetail : f.genreFemmesDetail,
    (GenreClasse.femmes, false) =>
      enfants ? f.genreFillesDetailSansSource : f.genreFemmesDetailSansSource,
    (GenreClasse.indetermine, _) => f.genreIndetermineDetail,
  };
}

/// Pourquoi un enseignant ne peut pas prendre une classe de ce genre (D4).
String _raisonGenre(GenreClasse genre, TypePublicGroupe type) {
  final f = t.admin.groupes.formulaire;
  final bool enfants = type == TypePublicGroupe.enfant;
  return switch (genre) {
    GenreClasse.hommes => enfants ? f.raisonGarcons : f.raisonHommes,
    GenreClasse.femmes => enfants ? f.raisonFilles : f.raisonFemmes,
    // Un genre non determine accepte tout le monde (D2) : aucune raison
    // d'indisponibilite n'existe, et aucune phrase hors sujet ne s'affiche.
    GenreClasse.indetermine => throw StateError(
      'Aucun enseignant n est incompatible avec une classe sans genre (D2).',
    ),
  };
}

/// Le message qui dit pourquoi l'enseignant choisi ne peut pas prendre la
/// classe, et quoi faire : une phrase complete par cause, avec son nom (pas
/// d'accord a deviner, K-41).
String _manqueEnseignant(
  EnseignantClasse choisi,
  GenreClasse genre,
  TypePublicGroupe type,
) {
  final f = t.admin.groupes.formulaire;
  final String nom = choisi.enseignant.libelle;
  final bool enfants = type == TypePublicGroupe.enfant;
  if (choisi.genreCompatible == false) {
    return switch (genre) {
      GenreClasse.hommes =>
        enfants
            ? f.manqueEnseignantGarcons(nom: nom)
            : f.manqueEnseignantHommes(nom: nom),
      GenreClasse.femmes =>
        enfants
            ? f.manqueEnseignantFilles(nom: nom)
            : f.manqueEnseignantFemmes(nom: nom),
      GenreClasse.indetermine => throw StateError(
        'Aucun enseignant n est incompatible avec une classe sans genre (D2).',
      ),
    };
  }
  return f.manqueEnseignantPris(nom: nom);
}

/// « 2 classes en cours », « aucune classe en cours ».
String _charge(int classes) => classes == 0
    ? t.admin.groupes.formulaire.aucuneClasse
    : t.admin.groupes.formulaire.classesEnCours(n: classes);

/// Le message d'un echec ou d'un champ manquant, a l'encre d'alerte, lu des
/// qu'il parait.
class _MessageAlerte extends StatelessWidget {
  const _MessageAlerte(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: TexteSansCoupure(
      message,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

/// Le seul bouton plein d'une feuille, en bas, au bord de fin ; pleine
/// largeur sur telephone et tablette seulement (contrat B). Hors ligne, il
/// n'est pas rendu : une phrase dit pourquoi (pieges deja payes).
class _BasDeFeuille extends ConsumerWidget {
  const _BasDeFeuille({
    required this.libelle,
    required this.enCours,
    required this.onPress,
    required this.horsLigne,
  });

  final String libelle;
  final bool enCours;
  final VoidCallback onPress;
  final String horsLigne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(horsLigneProvider).value ?? false) {
      return TexteSansCoupure(
        horsLigne,
        style: AppPalette.of(context).inkWarning.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      );
    }
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ActionPrincipale(
        libelle: libelle,
        enCours: enCours,
        pleineLargeur: !bureau,
        onPress: onPress,
      ),
    );
  }
}

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
        : _libelleGenre(genre, _type);
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

  /// La raison pour laquelle cet enseignant ne se choisit pas, ou nul.
  String? _raison(EnseignantClasse l) {
    final GenreClasse? genre = _genre;
    if (l.genreCompatible == false && genre != null) {
      return _raisonGenre(genre, _type);
    }
    if (l.pris) return t.admin.groupes.formulaire.raisonPris;
    return null;
  }

  /// La mention sous le nom : « le plus adapte » et sa raison (D5), ou
  /// « pas libre a ce creneau » pour un enseignant qui reste choisissable.
  String? _mention(EnseignantClasse l, {required bool avecCreneau}) {
    final f = t.admin.groupes.formulaire;
    final String charge = _charge(l.enseignant.classesActives);
    if (l.plusAdapte) {
      return avecCreneau
          ? f.plusAdapteCreneau(charge: charge)
          : f.plusAdapteSansCreneau(
              libres: f.creneauxLibres(
                n: l.enseignant.creneauxLibres?.length ?? 0,
              ),
              charge: charge,
            );
    }
    if (avecCreneau && l.choisissable && l.libre == false) return f.pasLibre;
    return null;
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
    if (!choisi.choisissable) return _manqueEnseignant(choisi, genre, _type);
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
                mention: _mention(l, avecCreneau: creneau != null),
                raisonIndisponible: _raison(l),
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
                libelle: _libelleGenre(g, _type),
                description: _detailGenre(g, _type, genreConnu: genreConnu),
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
          _MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        _BasDeFeuille(
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
          f.disponibilitesInconnues(deNom: deDevant(e.libelle)),
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
        f.creneauxLibresDe(deNom: deDevant(e.libelle)),
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
          _MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        _BasDeFeuille(
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
