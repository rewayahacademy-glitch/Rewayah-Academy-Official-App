import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/personnes_proposables.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/admin/service_evaluations.dart';
import '../../core/admin/service_programme.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_niveau_programme.dart';
import '../../core/widgets/selecteur_personne.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';

/// `ADM-12` : Pedagogie > Evaluations.
///
/// **Une certification est une evaluation** de type `certification` reussie,
/// jamais un objet separe -- le filtre « Certifications » de cet ecran est
/// une vue sur les memes lignes, pas une seconde liste (migration `0023`).
/// Une reevaluation, de meme, est une nouvelle evaluation planifiee sur le
/// meme niveau apres un `echec`.
class EvaluationsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des evaluations.
  const EvaluationsPage({super.key});

  @override
  ConsumerState<EvaluationsPage> createState() => _EvaluationsPageEtat();
}

enum _Filtre { toutes, planifiees, realisees, annulees, certifications }

class _EvaluationsPageEtat extends ConsumerState<EvaluationsPage> {
  _Filtre _filtre = _Filtre.toutes;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EvaluationAdmin>> evaluations = ref.watch(
      evaluationsProvider,
    );

    return PageShell(
      titre: t.admin.evaluations.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 2),
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.evaluations.intro, style: textes.bodyMedium),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.evaluations.planifier,
            pleineLargeur: false,
            niveau: NiveauAction.secondaire,
            onPress: () => _ouvrirPlanification(context, ref),
          ),
          Ecart.vXl,
          switch (evaluations) {
            AsyncValue<List<EvaluationAdmin>>(hasValue: true) => Expanded(
              child: _Corps(
                evaluations: evaluations.requireValue,
                filtre: _filtre,
                onFiltre: (_Filtre f) => setState(() => _filtre = f),
                onEnregistrerResultat: (EvaluationAdmin e) =>
                    _ouvrirResultat(context, ref, e),
                onAnnuler: (EvaluationAdmin e) =>
                    _ouvrirAnnulation(context, ref, e),
              ),
            ),
            AsyncValue<List<EvaluationAdmin>>(hasError: true) => EmptyState(
              message: t.admin.evaluations.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(evaluationsProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.evaluations,
    required this.filtre,
    required this.onFiltre,
    required this.onEnregistrerResultat,
    required this.onAnnuler,
  });

  final List<EvaluationAdmin> evaluations;
  final _Filtre filtre;
  final void Function(_Filtre filtre) onFiltre;
  final void Function(EvaluationAdmin evaluation) onEnregistrerResultat;
  final void Function(EvaluationAdmin evaluation) onAnnuler;

  bool _correspond(EvaluationAdmin e, _Filtre f) => switch (f) {
    _Filtre.toutes => true,
    _Filtre.planifiees => e.statut == StatutEvaluation.planifiee,
    _Filtre.realisees => e.statut == StatutEvaluation.realisee,
    _Filtre.annulees => e.statut == StatutEvaluation.annulee,
    _Filtre.certifications => e.type == TypeEvaluation.certification,
  };

  String _libelleFiltre(_Filtre f) => switch (f) {
    _Filtre.toutes => t.admin.evaluations.filtreToutes,
    _Filtre.planifiees => t.admin.evaluations.filtrePlanifiees,
    _Filtre.realisees => t.admin.evaluations.filtreRealisees,
    _Filtre.annulees => t.admin.evaluations.filtreAnnulees,
    _Filtre.certifications => t.admin.evaluations.filtreCertifications,
  };

  @override
  Widget build(BuildContext context) {
    final List<EvaluationAdmin> visibles = evaluations
        .where((EvaluationAdmin e) => _correspond(e, filtre))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final _Filtre f in _Filtre.values)
              FilterPill(
                libelle: _libelleFiltre(f),
                compteur: evaluations
                    .where((EvaluationAdmin e) => _correspond(e, f))
                    .length,
                retenue: filtre == f,
                onPress: () => onFiltre(f),
              ),
          ],
        ),
        Ecart.vLg,
        if (visibles.isEmpty)
          EmptyState(
            message: evaluations.isEmpty
                ? t.admin.evaluations.aucune
                : t.admin.evaluations.aucuneAvecCeFiltre,
            invitation: evaluations.isEmpty
                ? t.admin.evaluations.aucuneDetail
                : t.admin.evaluations.aucuneAvecCeFiltreDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        else
          Expanded(
            child: DataCollection<EvaluationAdmin>(
              lignes: visibles,
              cle: (EvaluationAdmin e) => ValueKey<String>(e.id),
              colonnes: <ColonneDonnees<EvaluationAdmin>>[
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneEleve,
                  role: RoleColonne.identifiante,
                  flex: 2,
                  texte: (EvaluationAdmin e) => e.eleveLibelle,
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneNiveau,
                  texte: (EvaluationAdmin e) => e.niveauNomHumain,
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneType,
                  texte: (EvaluationAdmin e) => _libelleType(e.type),
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneDatePrevue,
                  tabulaire: true,
                  texte: (EvaluationAdmin e) => _jour(e.datePrevue),
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneStatut,
                  texte: (EvaluationAdmin e) => _libelleStatut(e.statut),
                  rendu: (BuildContext _, EvaluationAdmin e) => StatusPill(
                    libelle: _libelleStatut(e.statut),
                    ton: switch (e.statut) {
                      StatutEvaluation.planifiee => TonEtat.avertissement,
                      StatutEvaluation.realisee => TonEtat.succes,
                      StatutEvaluation.annulee => TonEtat.neutre,
                    },
                  ),
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: t.admin.evaluations.colonneResultat,
                  texte: (EvaluationAdmin e) =>
                      e.resultat == null ? '' : _libelleResultat(e.resultat!),
                ),
                ColonneDonnees<EvaluationAdmin>(
                  titre: '',
                  role: RoleColonne.aPart,
                  flex: 0,
                  // Vide a dessein, meme convention que
                  // `admin_groupes/groupes_page.dart`.
                  texte: (EvaluationAdmin _) => '',
                  rendreMemeSiTexteVide: true,
                  rendu: (BuildContext _, EvaluationAdmin e) =>
                      e.statut == StatutEvaluation.planifiee
                      ? MenuActions(
                          tooltip: e.eleveLibelle,
                          actions: <EntreeAction>[
                            EntreeAction(
                              libelle:
                                  t.admin.evaluations.actionEnregistrerResultat,
                              onChoix: () => onEnregistrerResultat(e),
                            ),
                            EntreeAction(
                              libelle: t.admin.evaluations.actionAnnuler,
                              destructif: true,
                              onChoix: () => onAnnuler(e),
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

String _libelleType(TypeEvaluation type) => switch (type) {
  TypeEvaluation.initiale => t.admin.evaluations.typeInitiale,
  TypeEvaluation.periodique => t.admin.evaluations.typePeriodique,
  TypeEvaluation.reevaluation => t.admin.evaluations.typeReevaluation,
  TypeEvaluation.certification => t.admin.evaluations.typeCertification,
};

String _libelleStatut(StatutEvaluation statut) => switch (statut) {
  StatutEvaluation.planifiee => t.admin.evaluations.statutPlanifiee,
  StatutEvaluation.realisee => t.admin.evaluations.statutRealisee,
  StatutEvaluation.annulee => t.admin.evaluations.statutAnnulee,
};

String _libelleResultat(ResultatEvaluation resultat) => switch (resultat) {
  ResultatEvaluation.reussi => t.admin.evaluations.resultatReussi,
  ResultatEvaluation.echec => t.admin.evaluations.resultatEchec,
  ResultatEvaluation.aRevoir => t.admin.evaluations.resultatARevoir,
};

String _jour(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';

String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

void _ouvrirPlanification(BuildContext context, WidgetRef ref) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.evaluations.planifierTitre,
    constructeur: (BuildContext contexte) => _FeuillePlanification(
      onCree: () => ref.invalidate(evaluationsProvider),
    ),
  );
}

void _ouvrirResultat(
  BuildContext context,
  WidgetRef ref,
  EvaluationAdmin evaluation,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.evaluations.resultatTitre(eleve: evaluation.eleveLibelle),
    constructeur: (BuildContext contexte) => _FeuilleResultat(
      evaluation: evaluation,
      onEnregistre: () => ref.invalidate(evaluationsProvider),
    ),
  );
}

void _ouvrirAnnulation(
  BuildContext context,
  WidgetRef ref,
  EvaluationAdmin evaluation,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.evaluations.annulerTitre(eleve: evaluation.eleveLibelle),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.evaluations.annulerEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceEvaluationsProvider)
          .annuler(evaluationId: evaluation.id, motif: motif),
      messageErreur: t.admin.evaluations.annulerErreur,
      onSucces: () => ref.invalidate(evaluationsProvider),
    ),
  );
}

/// Le formulaire de planification : eleve, niveau, type, date.
class _FeuillePlanification extends ConsumerStatefulWidget {
  const _FeuillePlanification({required this.onCree});

  final VoidCallback onCree;

  @override
  ConsumerState<_FeuillePlanification> createState() =>
      _FeuillePlanificationEtat();
}

class _FeuillePlanificationEtat extends ConsumerState<_FeuillePlanification> {
  /// Le jour choisi dans le calendrier (FORM-L4) : plus de date tapee.
  DateTime? _datePrevue;

  /// L'eleve choisi dans la liste (FORM-L2) : plus d'identifiant tape.
  String? _eleveId;
  String? _niveauId;
  TypeEvaluation _type = TypeEvaluation.periodique;
  bool _envoi = false;
  String? _erreur;

  /// Ce qui manque encore, nul quand tout est la (bouton jamais grise, K-56).
  String? get _manque => _eleveId == null
      ? t.admin.evaluations.manqueEleve
      : _niveauId == null
      ? t.admin.evaluations.manqueNiveau
      : _datePrevue == null
      ? t.admin.evaluations.manqueDate
      : null;

  Future<void> _envoyer() async {
    final DateTime? date = _datePrevue;
    final String? niveauId = _niveauId;
    final String? eleveId = _eleveId;
    if (date == null || niveauId == null || eleveId == null) {
      setState(() => _erreur = _manque);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceEvaluationsProvider)
          .planifier(
            studentId: eleveId,
            niveauId: niveauId,
            type: _type,
            datePrevue: date,
          );
      widget.onCree();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () => _erreur = t.admin.evaluations.planifierErreur(
          message: _message(erreur),
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<VersionProgramme?> versionActive = ref.watch(
      versionActiveProgrammeProvider,
    );

    return Column(
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
          t.admin.evaluations.champType,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final TypeEvaluation valeur in TypeEvaluation.values)
              FilterPill(
                libelle: _libelleType(valeur),
                retenue: _type == valeur,
                onPress: () => setState(() => _type = valeur),
              ),
          ],
        ),
        Ecart.vLg,
        Text(
          t.admin.evaluations.champNiveau,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vSm,
        switch (versionActive) {
          AsyncValue<VersionProgramme?>(hasValue: true) =>
            versionActive.requireValue == null
                ? Text(t.admin.diagnostics.aucunProgrammeDetail)
                : _NiveauxVersion(
                    versionId: versionActive.requireValue!.id,
                    selectionne: _niveauId,
                    onSelectionner: (String id) =>
                        setState(() => _niveauId = id),
                  ),
          AsyncValue<VersionProgramme?>(hasError: true) => Text(
            t.admin.evaluations.erreur,
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vLg,
        ChampDate(
          libelle: t.admin.evaluations.champDatePrevue,
          valeur: _datePrevue,
          aujourdhui: ref.watch(horlogeFormulairesProvider)(),
          onChoix: (DateTime jour) => setState(() {
            _datePrevue = jour;
            _erreur = null;
          }),
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
          libelle: t.admin.evaluations.planifierEnvoyer,
          enCours: _envoi,
          onPress: _envoyer,
        ),
      ],
    );
  }
}

class _NiveauxVersion extends ConsumerWidget {
  const _NiveauxVersion({
    required this.versionId,
    required this.selectionne,
    required this.onSelectionner,
  });

  final String versionId;
  final String? selectionne;
  final void Function(String niveauId) onSelectionner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NiveauProgramme>> niveaux = ref.watch(
      niveauxProgrammeProvider(versionId),
    );
    return switch (niveaux) {
      AsyncValue<List<NiveauProgramme>>(hasValue: true) =>
        SelecteurNiveauProgramme(
          niveaux: niveaux.requireValue,
          selectionne: selectionne,
          onSelectionner: onSelectionner,
        ),
      AsyncValue<List<NiveauProgramme>>(hasError: true) => Text(
        t.admin.evaluations.erreur,
      ),
      _ => const Skeleton.liste(lignes: 2),
    };
  }
}

/// Le formulaire de resultat : trois valeurs, puis des notes optionnelles.
class _FeuilleResultat extends StatefulWidget {
  const _FeuilleResultat({
    required this.evaluation,
    required this.onEnregistre,
  });

  final EvaluationAdmin evaluation;
  final VoidCallback onEnregistre;

  @override
  State<_FeuilleResultat> createState() => _FeuilleResultatEtat();
}

class _FeuilleResultatEtat extends State<_FeuilleResultat> {
  final TextEditingController _notes = TextEditingController();
  ResultatEvaluation? _resultat;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _envoyer(WidgetRef ref) async {
    final ResultatEvaluation? resultat = _resultat;
    if (resultat == null) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceEvaluationsProvider)
          .enregistrerResultat(
            evaluationId: widget.evaluation.id,
            resultat: resultat,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      widget.onEnregistre();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () => _erreur = t.admin.evaluations.resultatErreur(
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
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final ResultatEvaluation valeur in ResultatEvaluation.values)
                FilterPill(
                  libelle: _libelleResultat(valeur),
                  retenue: _resultat == valeur,
                  onPress: () => setState(() => _resultat = valeur),
                ),
            ],
          ),
          Ecart.vMd,
          ChampEtiquete(
            libelle: t.admin.evaluations.champNotes,
            controller: _notes,
            maxLines: 2,
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
            libelle: t.admin.evaluations.resultatEnvoyer,
            enCours: _envoi,
            onPress: _resultat == null ? null : () => _envoyer(ref),
          ),
        ],
      ),
    );
  }
}

/// Une feuille generique « motif requis, un bouton ».
///
/// Meme forme que `admin_groupes/groupes_page.dart::_FeuilleMotif`.
class _FeuilleMotif extends StatefulWidget {
  const _FeuilleMotif({
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
  });

  final String libelleEnvoyer;
  final Future<void> Function(String motif) onEnvoyer;
  final String Function({required String message}) messageErreur;
  final VoidCallback onSucces;

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
        Text(
          t.admin.evaluations.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        TextField(
          controller: _motif,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t.admin.evaluations.champMotif,
          ),
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
