import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_classes_admin.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'feuille_observation_groupe.dart';

/// Operations > Groupes : le noyau du produit depuis le pivot du 19
/// septembre 2026.
///
/// **Un groupe, pas une affectation** : l'enseignant et jusqu'a
/// [GroupeAdmin.seuilMax] eleves partagent un creneau commun, et c'est dans ce
/// groupe que la visio se tiendra (migration `0017`). Cet ecran devient la
/// fonction primaire du domaine Operations -- l'audit gele
/// (`docs/architecture/ADMIN_IA_AUDIT.md`) y redirigeait jusqu'ici
/// l'Attribution, qui reste atteignable comme fonction secondaire.
///
/// Meme squelette liste+filtre que `ADM-08` (Comptes) : `FilterPill` pour
/// l'axe ferme (le public), `DataCollection` pour les lignes. Le clic sur une
/// ligne ouvre le detail en feuille, comme le reste du produit
/// (`AppBottomSheet`, jamais une boite de dialogue Material).
class GroupesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des groupes.
  const GroupesPage({super.key});

  @override
  ConsumerState<GroupesPage> createState() => _GroupesPageEtat();
}

class _GroupesPageEtat extends ConsumerState<GroupesPage> {
  /// Le filtre courant. `null` veut dire « tous ».
  TypePublicGroupe? _type;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<GroupeAdmin>> groupes = ref.watch(groupesProvider);

    return PageShell(
      titre: t.admin.groupes.titre,
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.groupes.intro, style: textes.bodyMedium),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.groupes.creerOffre,
            pleineLargeur: false,
            onPress: () => _ouvrirCreationOffre(context, ref),
          ),
          Ecart.vMd,
          const _PilotageClasses(),
          Ecart.vXl,
          switch (groupes) {
            AsyncValue<List<GroupeAdmin>>(hasValue: true) => Expanded(
              child: _Corps(
                groupes: groupes.requireValue,
                type: _type,
                onType: (TypePublicGroupe? type) =>
                    setState(() => _type = type),
                onSelectionner: (GroupeAdmin groupe) =>
                    _ouvrirDetail(context, ref, groupe),
                onAjouter: (GroupeAdmin groupe) =>
                    _ouvrirAjout(context, ref, groupe),
                onModifierSeuil: (GroupeAdmin groupe) =>
                    _ouvrirModifierSeuil(context, ref, groupe),
                onObservation: (GroupeAdmin groupe) =>
                    _ouvrirObservation(context, ref, groupe),
                onCloturer: (GroupeAdmin groupe) =>
                    _ouvrirCloture(context, ref, groupe),
                onAffecterTitulaire: (GroupeAdmin groupe) =>
                    _ouvrirAffectation(context, ref, groupe),
                onTransitionner: (GroupeAdmin groupe, String etat) =>
                    _ouvrirTransition(context, ref, groupe, etat),
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

/// Les filtres, puis le tableau des groupes.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.groupes,
    required this.type,
    required this.onType,
    required this.onSelectionner,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
    required this.onAffecterTitulaire,
    required this.onTransitionner,
  });

  final List<GroupeAdmin> groupes;
  final TypePublicGroupe? type;
  final void Function(TypePublicGroupe? type) onType;
  final void Function(GroupeAdmin groupe) onSelectionner;
  final void Function(GroupeAdmin groupe) onAjouter;
  final void Function(GroupeAdmin groupe) onModifierSeuil;
  final void Function(GroupeAdmin groupe) onObservation;
  final void Function(GroupeAdmin groupe) onCloturer;
  final void Function(GroupeAdmin groupe) onAffecterTitulaire;
  final void Function(GroupeAdmin groupe, String etat) onTransitionner;

  @override
  Widget build(BuildContext context) {
    final List<GroupeAdmin> visibles = groupes
        .where((GroupeAdmin g) => type == null || g.type == type)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilterPill(
              libelle: t.admin.groupes.filtreTousTypes,
              compteur: groupes.length,
              retenue: type == null,
              onPress: () => onType(null),
            ),
            for (final TypePublicGroupe valeur in TypePublicGroupe.values)
              FilterPill(
                libelle: _nomType(valeur),
                compteur: groupes
                    .where((GroupeAdmin g) => g.type == valeur)
                    .length,
                retenue: type == valeur,
                onPress: () => onType(valeur),
              ),
          ],
        ),
        Ecart.vLg,
        if (visibles.isEmpty)
          EmptyState(
            message: groupes.isEmpty
                ? t.admin.groupes.aucun
                : t.admin.groupes.aucunAvecCeFiltre,
            invitation: groupes.isEmpty
                ? t.admin.groupes.aucunDetail
                : t.admin.groupes.aucunAvecCeFiltreDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        else
          Expanded(
            child: DataCollection<GroupeAdmin>(
              lignes: visibles,
              cle: (GroupeAdmin g) => ValueKey<String>(g.id),
              onSelectionner: onSelectionner,
              colonnes: <ColonneDonnees<GroupeAdmin>>[
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneGroupe,
                  role: RoleColonne.identifiante,
                  flex: 2,
                  texte: (GroupeAdmin g) => g.libelle,
                ),
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneEnseignant,
                  texte: (GroupeAdmin g) => g.teacherId == null
                      ? t.admin.groupes.sansTitulaire
                      : g.teacherLibelle,
                ),
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneType,
                  texte: (GroupeAdmin g) => _nomType(g.type),
                ),
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneCreneau,
                  texte: _creneau,
                ),
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneMembres,
                  tabulaire: true,
                  texte: (GroupeAdmin g) => t.admin.groupes.membresSur(
                    actifs: '${g.nombreMembres}',
                    seuil: '${g.seuilMax}',
                  ),
                ),
                ColonneDonnees<GroupeAdmin>(
                  titre: t.admin.groupes.colonneEtat,
                  texte: _etatLibelle,
                  rendu: (BuildContext _, GroupeAdmin g) => StatusPill(
                    libelle: _etatLibelle(g),
                    ton: g.actif && g.etat != 'brouillon'
                        ? TonEtat.succes
                        : TonEtat.neutre,
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
                  rendu: (BuildContext _, GroupeAdmin g) => g.actif
                      ? MenuActions(
                          tooltip: g.libelle,
                          actions: <EntreeAction>[
                            if (g.teacherId == null)
                              EntreeAction(
                                libelle:
                                    t.admin.groupes.actionAffecterTitulaire,
                                onChoix: () => onAffecterTitulaire(g),
                              ),
                            if (g.etat == 'brouillon' && g.teacherId != null)
                              EntreeAction(
                                libelle: t.admin.groupes.actionPasserReady,
                                onChoix: () => onTransitionner(g, 'ready'),
                              ),
                            if (g.etat == 'ready')
                              EntreeAction(
                                libelle: t.admin.groupes.actionPublier,
                                onChoix: () => onTransitionner(g, 'publiee'),
                              ),
                            if (g.etat == 'publiee')
                              EntreeAction(
                                libelle: t.admin.groupes.actionActiver,
                                onChoix: () => onTransitionner(g, 'active'),
                              ),
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
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PilotageClasses extends ConsumerStatefulWidget {
  const _PilotageClasses();

  @override
  ConsumerState<_PilotageClasses> createState() => _PilotageClassesEtat();
}

class _PilotageClassesEtat extends ConsumerState<_PilotageClasses> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    if (!_ouvert) {
      return Card(
        child: ExpansionTile(
          title: Text(t.admin.groupes.pilotageTitre),
          onExpansionChanged: (bool ouvert) => setState(() => _ouvert = ouvert),
        ),
      );
    }
    final AsyncValue<List<OffreHoraireAdmin>> offres = ref.watch(
      offresHoraireAdminProvider,
    );
    final AsyncValue<List<IntentionPoolAdmin>> pool = ref.watch(
      intentionsPoolAdminProvider,
    );
    return Card(
      child: ExpansionTile(
        title: Text(t.admin.groupes.pilotageTitre),
        initiallyExpanded: true,
        onExpansionChanged: (bool ouvert) => setState(() => _ouvert = ouvert),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: switch (offres) {
              AsyncValue<List<OffreHoraireAdmin>>(hasValue: true) =>
                offres.requireValue.isEmpty
                    ? Text(t.admin.groupes.offresAucune)
                    : Column(
                        children: <Widget>[
                          for (final OffreHoraireAdmin offre
                              in offres.requireValue)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${offre.langueNom} · ${offre.typePublic} · ${offre.heureLocale}h',
                              ),
                              subtitle: Text(
                                '${offre.etat} · ${offre.candidats}',
                              ),
                              trailing: MenuActions(
                                tooltip: offre.langueNom,
                                actions: <EntreeAction>[
                                  if (offre.etat == 'brouillon')
                                    EntreeAction(
                                      libelle: t.admin.groupes.offrePublier,
                                      onChoix: () => _ouvrirOffreOperation(
                                        context,
                                        ref,
                                        offre,
                                        'publier',
                                      ),
                                    ),
                                  if (offre.etat == 'publiee')
                                    EntreeAction(
                                      libelle: t.admin.groupes.offreDispatcher,
                                      onChoix: () => _ouvrirOffreOperation(
                                        context,
                                        ref,
                                        offre,
                                        'dispatcher',
                                      ),
                                    ),
                                  if (offre.etat != 'retiree')
                                    EntreeAction(
                                      libelle: t.admin.groupes.offreRetirer,
                                      destructif: true,
                                      onChoix: () => _ouvrirRetraitOffre(
                                        context,
                                        ref,
                                        offre,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
              AsyncValue<List<OffreHoraireAdmin>>(hasError: true) => Text(
                t.admin.groupes.offresErreur(
                  message: _message(offres.error!),
                ),
              ),
              _ => const Skeleton.liste(lignes: 2),
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: switch (pool) {
              AsyncValue<List<IntentionPoolAdmin>>(hasValue: true) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      t.admin.groupes.poolTitre,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Ecart.vSm,
                    if (pool.requireValue.isEmpty)
                      Text(t.admin.groupes.poolAucun)
                    else
                      for (final IntentionPoolAdmin intention
                          in pool.requireValue)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(intention.eleveLibelle),
                          subtitle: Text(
                            t.admin.groupes.poolLigne(
                              langue: intention.langueCode,
                              cohorte: intention.cohorte,
                              diagnostic: intention.diagnosticStatut,
                            ),
                          ),
                        ),
                  ],
                ),
              AsyncValue<List<IntentionPoolAdmin>>(hasError: true) => Text(
                t.admin.groupes.offresErreur(message: _message(pool.error!)),
              ),
              _ => const Skeleton.liste(lignes: 2),
            },
          ),
        ],
      ),
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

String _etatLibelle(GroupeAdmin groupe) => switch (groupe.etat) {
  'brouillon' => t.admin.groupes.etatBrouillon,
  'ready' => t.admin.groupes.etatReady,
  'publiee' => t.admin.groupes.etatPubliee,
  'active' => t.admin.groupes.etatActif,
  _ => groupe.actif ? t.admin.groupes.etatActif : t.admin.groupes.etatCloture,
};

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
      libelle: groupe.libelle,
    ),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
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
    titre: t.admin.groupes.modifierSeuilTitre(libelle: groupe.libelle),
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

void _ouvrirAffectation(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.affecterTitre(libelle: groupe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleAffectation(
      groupe: groupe,
      onAffecte: () {
        ref.invalidate(groupesProvider);
        ref.invalidate(enseignantsAdmissiblesProvider(groupe.id));
      },
    ),
  );
}

void _ouvrirTransition(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe,
  String etat,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: groupe.libelle,
    constructeur: (BuildContext contexte) => _FeuilleTransition(
      groupe: groupe,
      etat: etat,
      onTransitionne: () => ref.invalidate(groupesProvider),
    ),
  );
}

void _ouvrirCreationOffre(BuildContext context, WidgetRef ref) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.creerOffreTitre,
    constructeur: (BuildContext contexte) => _FeuilleCreationOffre(
      onCree: () => _rafraichirPilotage(ref),
    ),
  );
}

void _rafraichirPilotage(WidgetRef ref) {
  ref.invalidate(offresHoraireAdminProvider);
  ref.invalidate(intentionsPoolAdminProvider);
  ref.invalidate(groupesProvider);
}

void _ouvrirOffreOperation(
  BuildContext context,
  WidgetRef ref,
  OffreHoraireAdmin offre,
  String operation,
) {
  final String libelle = operation == 'publier'
      ? t.admin.groupes.offrePublier
      : t.admin.groupes.offreDispatcher;
  AppBottomSheet.ouvrir<void>(
    context,
    titre: libelle,
    constructeur: (BuildContext contexte) => _FeuilleOperation(
      libelleEnvoyer: libelle,
      onEnvoyer: () async {
        final ServiceClassesAdmin service = ref.read(
          serviceClassesAdminProvider,
        );
        if (operation == 'publier') {
          await service.publierOffre(offre.id);
        } else {
          await service.dispatcherOffre(offre.id);
        }
      },
      messageErreur: ({required String message}) =>
          t.admin.groupes.offresErreur(message: message),
      onSucces: () => _rafraichirPilotage(ref),
    ),
  );
}

void _ouvrirRetraitOffre(
  BuildContext context,
  WidgetRef ref,
  OffreHoraireAdmin offre,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.offreRetirer,
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.groupes.offreRetirer,
      onEnvoyer: (String motif) => ref
          .read(serviceClassesAdminProvider)
          .retirerOffre(offreId: offre.id, motif: motif),
      messageErreur: ({required String message}) =>
          t.admin.groupes.offresErreur(message: message),
      onSucces: () => _rafraichirPilotage(ref),
    ),
  );
}

class _FeuilleAffectation extends ConsumerStatefulWidget {
  const _FeuilleAffectation({required this.groupe, required this.onAffecte});

  final GroupeAdmin groupe;
  final VoidCallback onAffecte;

  @override
  ConsumerState<_FeuilleAffectation> createState() => _FeuilleAffectationEtat();
}

class _FeuilleAffectationEtat extends ConsumerState<_FeuilleAffectation> {
  final TextEditingController _motif = TextEditingController();
  String? _teacherId;
  String? _erreur;
  bool _envoi = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _affecter() async {
    final String? teacherId = _teacherId;
    if (teacherId == null || _motif.text.trim().isEmpty) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceClassesAdminProvider)
          .affecterTitulaire(
            groupeId: widget.groupe.id,
            teacherId: teacherId,
            motif: _motif.text.trim(),
          );
      widget.onAffecte();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.admin.groupes.affecterErreur(
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
    final AsyncValue<List<EnseignantAdmissible>> enseignants = ref.watch(
      enseignantsAdmissiblesProvider(widget.groupe.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.admin.groupes.affecterIntro),
        Ecart.vMd,
        switch (enseignants) {
          AsyncValue<List<EnseignantAdmissible>>(hasValue: true) =>
            enseignants.requireValue.isEmpty
                ? Text(t.admin.groupes.affecterAucun)
                : RadioGroup<String>(
                    groupValue: _teacherId,
                    onChanged: (String? value) =>
                        setState(() => _teacherId = value),
                    child: Column(
                      children: <Widget>[
                        for (final EnseignantAdmissible enseignant
                            in enseignants.requireValue)
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(enseignant.libelle),
                            subtitle: Text(
                              '${enseignant.groupesActifs}/${enseignant.maxPrimaryGroups}',
                            ),
                            value: enseignant.id,
                          ),
                      ],
                    ),
                  ),
          AsyncValue<List<EnseignantAdmissible>>(hasError: true) => Text(
            t.admin.groupes.affecterErreur(
              message: _message(enseignants.error!),
            ),
          ),
          _ => const Skeleton.liste(lignes: 3),
        },
        Ecart.vMd,
        TextField(
          controller: _motif,
          maxLines: 2,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(labelText: t.admin.groupes.affecterMotif),
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
          libelle: t.admin.groupes.affecterEnvoyer,
          enCours: _envoi,
          onPress: _teacherId == null || _motif.text.trim().isEmpty
              ? null
              : _affecter,
        ),
      ],
    );
  }
}

class _FeuilleTransition extends ConsumerStatefulWidget {
  const _FeuilleTransition({
    required this.groupe,
    required this.etat,
    required this.onTransitionne,
  });

  final GroupeAdmin groupe;
  final String etat;
  final VoidCallback onTransitionne;

  @override
  ConsumerState<_FeuilleTransition> createState() => _FeuilleTransitionEtat();
}

class _FeuilleTransitionEtat extends ConsumerState<_FeuilleTransition> {
  bool _envoi = false;
  String? _erreur;

  String get _libelle => switch (widget.etat) {
    'ready' => t.admin.groupes.actionPasserReady,
    'publiee' => t.admin.groupes.actionPublier,
    _ => t.admin.groupes.actionActiver,
  };

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceClassesAdminProvider)
          .transitionner(groupeId: widget.groupe.id, etat: widget.etat);
      widget.onTransitionne();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.admin.groupes.transitionErreur(
            message: _message(erreur),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(widget.groupe.libelle),
      if (_erreur != null) ...<Widget>[
        Ecart.vMd,
        Text(
          _erreur!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      Ecart.vLg,
      ActionPrincipale(libelle: _libelle, enCours: _envoi, onPress: _envoyer),
    ],
  );
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
  final TextEditingController _eleveId = TextEditingController();
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _eleveId.dispose();
    _motif.dispose();
    super.dispose();
  }

  Future<void> _ajouter(WidgetRef ref) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceGroupesProvider)
          .ajouterEleve(
            groupeId: widget.groupe.id,
            studentId: _eleveId.text.trim(),
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
          TextField(
            controller: _eleveId,
            onChanged: (String _) => setState(() {}),
            decoration: InputDecoration(
              labelText: t.admin.groupes.champEleveId,
            ),
          ),
          Ecart.vMd,
          Text(
            t.admin.groupes.motifRequis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vSm,
          TextField(
            controller: _motif,
            maxLines: 2,
            onChanged: (String _) => setState(() {}),
            decoration: InputDecoration(labelText: t.admin.groupes.champMotif),
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
            onPress: _eleveId.text.trim().isEmpty || _motif.text.trim().isEmpty
                ? null
                : () => _ajouter(ref),
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

/// Le formulaire du seuil maximal.
class _FeuilleSeuil extends StatefulWidget {
  const _FeuilleSeuil({required this.groupe, required this.onModifie});

  final GroupeAdmin groupe;
  final VoidCallback onModifie;

  @override
  State<_FeuilleSeuil> createState() => _FeuilleSeuilEtat();
}

class _FeuilleSeuilEtat extends State<_FeuilleSeuil> {
  late final TextEditingController _seuil = TextEditingController(
    text: '${widget.groupe.seuilMax}',
  );
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _seuil.dispose();
    super.dispose();
  }

  Future<void> _modifier(WidgetRef ref) async {
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
            seuilMax: int.parse(_seuil.text.trim()),
            creneau: widget.groupe.creneau,
          );
      widget.onModifie();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () => _erreur = t.admin.groupes.modifierSeuilErreur(
          message: _message(erreur),
        ),
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
          TextField(
            controller: _seuil,
            keyboardType: TextInputType.number,
            onChanged: (String _) => setState(() {}),
            decoration: InputDecoration(labelText: t.admin.groupes.champSeuil),
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
            libelle: t.admin.groupes.modifierSeuilEnvoyer,
            enCours: _envoi,
            onPress: int.tryParse(_seuil.text.trim()) == null
                ? null
                : () => _modifier(ref),
          ),
        ],
      ),
    );
  }
}

class _FeuilleCreationOffre extends ConsumerStatefulWidget {
  const _FeuilleCreationOffre({required this.onCree});

  final VoidCallback onCree;

  @override
  ConsumerState<_FeuilleCreationOffre> createState() =>
      _FeuilleCreationOffreEtat();
}

class _FeuilleCreationOffreEtat
    extends ConsumerState<_FeuilleCreationOffre> {
  final TextEditingController _fuseau = TextEditingController(
    text: 'Europe/Paris',
  );
  final TextEditingController _jours = TextEditingController(text: '1,3,5');
  final TextEditingController _heure = TextEditingController(text: '18');
  final TextEditingController _duree = TextEditingController(text: '60');
  String _typePublic = 'enfant';
  String _langueCode = 'francais';
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _fuseau.dispose();
    _jours.dispose();
    _heure.dispose();
    _duree.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    final List<String> tokens = _jours.text.split(',');
    final List<int?> valeurs = tokens
        .map((String jour) => int.tryParse(jour.trim()))
        .toList(growable: false);
    final int? heure = int.tryParse(_heure.text.trim());
    final int? duree = int.tryParse(_duree.text.trim());
    if (valeurs.isEmpty || valeurs.any((int? jour) => jour == null) ||
        heure == null || duree == null) {
      setState(
        () => _erreur = t.admin.groupes.creerOffreErreur(
          message: t.admin.groupes.parametresInvalides,
        ),
      );
      return;
    }
    final List<int> jours = valeurs.whereType<int>().toList(growable: false);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceClassesAdminProvider).creerOffre(
        typePublic: _typePublic,
        langueCode: _langueCode,
        fuseauIana: _fuseau.text.trim(),
        jours: jours,
        heureLocale: heure,
        dureeMinutes: duree,
      );
      widget.onCree();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.admin.groupes.creerOffreErreur(
            message: _message(erreur),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  String _langueLibelle(String code) => switch (code) {
    'poular' => t.admin.groupes.offreLanguePoular,
    'english' => t.admin.groupes.offreLangueEnglish,
    _ => t.admin.groupes.offreLangueFrancais,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      DropdownButtonFormField<String>(
        initialValue: _typePublic,
        decoration: InputDecoration(labelText: t.admin.groupes.offreType),
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: 'enfant',
            child: Text(t.admin.groupes.typeEnfant),
          ),
          DropdownMenuItem<String>(
            value: 'adulte',
            child: Text(t.admin.groupes.typeAdulte),
          ),
        ],
        onChanged: (String? value) {
          if (value != null) setState(() => _typePublic = value);
        },
      ),
      Ecart.vMd,
      DropdownButtonFormField<String>(
        initialValue: _langueCode,
        decoration: InputDecoration(labelText: t.admin.groupes.offreLangue),
        items: <String>['poular', 'francais', 'english']
            .map(
              (String code) => DropdownMenuItem<String>(
                value: code,
                child: Text(_langueLibelle(code)),
              ),
            )
            .toList(growable: false),
        onChanged: (String? value) {
          if (value != null) setState(() => _langueCode = value);
        },
      ),
      Ecart.vMd,
      TextField(
        controller: _fuseau,
        decoration: InputDecoration(labelText: t.admin.groupes.offreFuseau),
      ),
      Ecart.vMd,
      TextField(
        controller: _jours,
        decoration: InputDecoration(labelText: t.admin.groupes.offreJours),
      ),
      Ecart.vMd,
      Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _heure,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.admin.groupes.offreHeure),
            ),
          ),
          Ecart.hMd,
          Expanded(
            child: TextField(
              controller: _duree,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.admin.groupes.offreDuree),
            ),
          ),
        ],
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
        libelle: t.admin.groupes.creerOffreEnvoyer,
        enCours: _envoi,
        onPress: _creer,
      ),
    ],
  );
}

class _FeuilleOperation extends StatefulWidget {
  const _FeuilleOperation({
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
  });

  final String libelleEnvoyer;
  final Future<void> Function() onEnvoyer;
  final String Function({required String message}) messageErreur;
  final VoidCallback onSucces;

  @override
  State<_FeuilleOperation> createState() => _FeuilleOperationEtat();
}

class _FeuilleOperationEtat extends State<_FeuilleOperation> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer();
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = widget.messageErreur(message: _message(erreur)),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (_erreur != null) ...<Widget>[
        Text(
          _erreur!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        Ecart.vMd,
      ],
      ActionPrincipale(
        libelle: widget.libelleEnvoyer,
        enCours: _envoi,
        onPress: _envoyer,
      ),
    ],
  );
}

/// Une feuille generique « motif requis, un bouton » : retrait ou cloture.
class _FeuilleMotif extends StatefulWidget {
  const _FeuilleMotif({
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
    this.detail,
  });

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
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
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
        TextField(
          controller: _motif,
          maxLines: 2,
          decoration: InputDecoration(labelText: t.admin.groupes.champMotif),
          onChanged: (String _) => setState(() {}),
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
          onPress: _motif.text.trim().isEmpty ? null : _envoyer,
        ),
      ],
    );
  }
}
