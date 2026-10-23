import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_programme.dart';
import '../../core/admin/service_progression.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recherche/normalisation_recherche.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/chargement_avec_delais.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/selecteur_niveau_programme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';

/// `ADM-11` : Pedagogie > Progression.
///
/// **Vue par groupe et par cycle, avec exceptions et blocages** (mission).
/// Le niveau courant vient de la derniere ligne de `progression_historique`
/// (migration `0021`) ; les exceptions actives viennent de
/// `progression_exceptions` (migration `0022`), un catalogue distinct des
/// regles operationnelles d'`ADM-06`.
class ProgressionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de progression.
  const ProgressionPage({super.key});

  @override
  ConsumerState<ProgressionPage> createState() => _ProgressionPageEtat();
}

class _ProgressionPageEtat extends ConsumerState<ProgressionPage> {
  /// Le cycle retenu. `null` veut dire « tous ».
  String? _cycle;

  /// Le texte cherche (LISTES-1, lot 4). La liste est lue en entier, la
  /// recherche est donc faite ici, sans aller-retour serveur.
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveProgression>> eleves = ref.watch(
      progressionProvider,
    );

    return PageShell(
      titre: t.admin.progression.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 1),
      // ONGLETS-COUPE-1 : en cartes (telephone, tablette), l'introduction,
      // les filtres et la liste defilent ensemble ; en tableau, la liste
      // defile seule sous son en-tete colle.
      defilante: !DataCollection.enTableau(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.progression.intro, style: textes.bodyMedium),
          Ecart.vXl,
          PlaceCollection(
            child: BlocAsynchrone<List<EleveProgression>>(
              valeur: eleves,
              squelette: const SqueletteDansZone(
                child: Skeleton.liste(lignes: 5),
              ),
              titreEchec: t.admin.progression.erreur,
              onReessayer: () => ref.invalidate(progressionProvider),
              vide: EmptyState(
                message: t.admin.progression.aucun,
                invitation: t.admin.progression.aucunDetail,
                icone: AppIcons.rienAAfficher,
                registre: RegistreVide.subi,
              ),
              construire: (List<EleveProgression> v) => _Corps(
                eleves: v,
                cycle: _cycle,
                onCycle: (String? c) => setState(() => _cycle = c),
                recherche: _recherche,
                onRecherche: (String _) => setState(() {}),
                onPoserException: (
                  EleveProgression e,
                  TypeExceptionProgression type,
                ) => _ouvrirPoseException(context, ref, e, type),
                onClorerException: (EleveProgression e) =>
                    _ouvrirClotureException(context, ref, e),
                onPromouvoir: (EleveProgression e) =>
                    _ouvrirPromotion(context, ref, e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.eleves,
    required this.cycle,
    required this.onCycle,
    required this.recherche,
    required this.onRecherche,
    required this.onPoserException,
    required this.onClorerException,
    required this.onPromouvoir,
  });

  final List<EleveProgression> eleves;
  final String? cycle;
  final void Function(String? cycle) onCycle;
  final TextEditingController recherche;
  final ValueChanged<String> onRecherche;
  final void Function(EleveProgression eleve, TypeExceptionProgression type)
  onPoserException;
  final void Function(EleveProgression eleve) onClorerException;
  final void Function(EleveProgression eleve) onPromouvoir;

  @override
  Widget build(BuildContext context) {
    final List<String> cycles =
        eleves
            .map((EleveProgression e) => e.niveauCycle)
            .whereType<String>()
            .toSet()
            .toList(growable: false)
          ..sort();
    // La recherche d'abord : les compteurs des cycles disent ce que la recherche
    // laisse, pas la liste entiere (un « Tous les cycles 16 » au-dessus de trois
    // lignes serait faux).
    final String requete = normaliserPourRecherche(recherche.text);
    final List<EleveProgression> trouves = requete.isEmpty
        ? eleves
        : eleves
              .where(
                (EleveProgression e) => correspondTousLesTermes(
                  normaliserPourRecherche(
                    '${e.libelle} ${e.identifiant} ${e.groupeLibelle ?? ''}',
                  ),
                  requete,
                ),
              )
              .toList(growable: false);
    final List<EleveProgression> visibles = trouves
        .where((EleveProgression e) => cycle == null || e.niveauCycle == cycle)
        .toList(growable: false);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget compteur = Semantics(
      liveRegion: true,
      child: Text(
        visibles.length == eleves.length
            ? t.admin.progression.nombreEleves(n: visibles.length)
            : t.admin.progression.nombreSurTotal(
                n: '${visibles.length}',
                total: '${eleves.length}',
              ),
        key: const ValueKey<String>('progression-compteur'),
        style: textes.bodySmall,
      ),
    );

    return ColonneCorps(
      minimumEtire: DataCollection.minimumLisible(context),
      children: <Widget>[
        ChampRecherche(
          cleChamp: const ValueKey<String>('progression-recherche'),
          controleur: recherche,
          libelle: t.admin.progression.rechercheLibelle,
          aide: t.admin.progression.rechercheAide,
          onChange: onRecherche,
        ),
        Ecart.vMd,
        RangeeFiltres(
          filtres: <Widget>[
            FilterPill(
              libelle: t.admin.progression.filtreTousCycles,
              compteur: trouves.length,
              retenue: cycle == null,
              onPress: () => onCycle(null),
            ),
            for (final String valeur in cycles)
              FilterPill(
                libelle: valeur,
                compteur: trouves
                    .where((EleveProgression e) => e.niveauCycle == valeur)
                    .length,
                retenue: cycle == valeur,
                onPress: () => onCycle(valeur),
              ),
          ],
        ),
        Ecart.vMd,
        compteur,
        Ecart.vSm,
        PlaceCollection(
          child: visibles.isEmpty
              ? EmptyState(
                  message: t.admin.progression.aucunAvecCeFiltre,
                  invitation: t.admin.progression.aucunAvecCeFiltreDetail,
                  icone: AppIcons.rienAAfficher,
                  registre: RegistreVide.subi,
                  // Une recherche ou un cycle qui ne trouve rien se retire d'un
                  // geste (relecture du code R-10).
                  libelleAction: t.commun.listes.toutEffacer,
                  onAction: () {
                    recherche.clear();
                    onRecherche('');
                    onCycle(null);
                  },
                )
              : DataCollection<EleveProgression>(
                  defileAvecLaPage: !DataCollection.enTableau(context),
                  lignes: visibles,
                  cle: (EleveProgression e) => ValueKey<String>(e.studentId),
                  actionsLigne: (BuildContext _, EleveProgression e) =>
                      MenuActions(
                        points: true,
                        objet: e.libelle,
                        actions: <EntreeAction>[
                          if (e.exceptionActiveId == null) ...<EntreeAction>[
                            EntreeAction(
                              libelle: t.admin.progression.actionPoserBlocage,
                              onChoix: () => onPoserException(
                                e,
                                TypeExceptionProgression.blocage,
                              ),
                            ),
                            EntreeAction(
                              libelle:
                                  t.admin.progression.actionPoserDerogation,
                              onChoix: () => onPoserException(
                                e,
                                TypeExceptionProgression.derogation,
                              ),
                            ),
                          ] else
                            EntreeAction(
                              libelle: t.admin.progression.actionCloreException,
                              onChoix: () => onClorerException(e),
                            ),
                          if (e.niveauId != null)
                            EntreeAction(
                              libelle: t.admin.progression.actionPromouvoir,
                              onChoix: () => onPromouvoir(e),
                            ),
                        ],
                      ),
                  colonnes: <ColonneDonnees<EleveProgression>>[
                    ColonneDonnees<EleveProgression>(
                      titre: t.admin.progression.colonneEleve,
                      role: RoleColonne.identifiante,
                      flex: 2,
                      texte: (EleveProgression e) => e.libelle,
                    ),
                    ColonneDonnees<EleveProgression>(
                      titre: t.admin.progression.colonneGroupe,
                      texte: (EleveProgression e) =>
                          e.groupeLibelle ?? t.admin.progression.sansGroupe,
                    ),
                    ColonneDonnees<EleveProgression>(
                      titre: t.admin.progression.colonneNiveau,
                      texte: (EleveProgression e) =>
                          e.niveauNomHumain ?? t.admin.progression.sansNiveau,
                    ),
                    ColonneDonnees<EleveProgression>(
                      titre: t.admin.progression.colonneDepuis,
                      tabulaire: true,
                      texte: (EleveProgression e) => _depuis(e.niveauDepuis),
                    ),
                    ColonneDonnees<EleveProgression>(
                      titre: t.admin.progression.colonneException,
                      role: RoleColonne.aPart,
                      texte: (EleveProgression e) =>
                          e.exceptionActiveType == null
                          ? ''
                          : _libelleType(e.exceptionActiveType!),
                      rendu: (BuildContext _, EleveProgression e) =>
                          e.exceptionActiveType == null
                          ? const SizedBox.shrink()
                          : StatusPill(
                              libelle: _libelleType(e.exceptionActiveType!),
                              ton:
                                  e.exceptionActiveType ==
                                      TypeExceptionProgression.blocage
                                  ? TonEtat.avertissement
                                  : TonEtat.neutre,
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _depuis(DateTime? quand) {
  if (quand == null) return '';
  final int jours = DateTime.now().difference(quand).inDays;
  return switch (jours) {
    <= 0 => t.admin.progression.depuisAujourdhui,
    1 => t.admin.progression.depuisUnJour,
    final int j => LibellesGroupe.valeurSeule(
      t.admin.progression.depuisJours(jours: j),
    ),
  };
}

String _libelleType(TypeExceptionProgression type) => switch (type) {
  TypeExceptionProgression.blocage => t.admin.progression.typeBlocage,
  TypeExceptionProgression.derogation => t.admin.progression.typeDerogation,
};

String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

void _ouvrirPoseException(
  BuildContext context,
  WidgetRef ref,
  EleveProgression eleve,
  TypeExceptionProgression type,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.progression.poserExceptionTitre(
      type: _libelleType(type),
      eleve: eleve.libelle,
    ),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      motifs: type == TypeExceptionProgression.blocage
          ? MotifsProposes.blocage()
          : MotifsProposes.derogation(),
      libelleEnvoyer: t.admin.progression.poserExceptionEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceProgressionProvider)
          .poserException(studentId: eleve.studentId, type: type, motif: motif),
      messageErreur: t.admin.progression.poserExceptionErreur,
      onSucces: () => ref.invalidate(progressionProvider),
    ),
  );
}

void _ouvrirClotureException(
  BuildContext context,
  WidgetRef ref,
  EleveProgression eleve,
) {
  final String? id = eleve.exceptionActiveId;
  if (id == null) return;
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.progression.clorerExceptionTitre(
      deEleve: deDevant(eleve.libelle),
    ),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      motifs: MotifsProposes.cloreException(),
      libelleEnvoyer: t.admin.progression.clorerExceptionEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceProgressionProvider)
          .clorerException(exceptionId: id, motif: motif),
      messageErreur: t.admin.progression.clorerExceptionErreur,
      onSucces: () => ref.invalidate(progressionProvider),
    ),
  );
}

void _ouvrirPromotion(
  BuildContext context,
  WidgetRef ref,
  EleveProgression eleve,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.progression.promouvoirTitre(
      deEleve: deDevant(eleve.libelle),
    ),
    constructeur: (BuildContext contexte) => _FeuillePromotion(eleve: eleve),
  );
}

/// Le formulaire de changement de niveau : selecteur de niveau puis motif.
class _FeuillePromotion extends ConsumerStatefulWidget {
  const _FeuillePromotion({required this.eleve});

  final EleveProgression eleve;

  @override
  ConsumerState<_FeuillePromotion> createState() => _FeuillePromotionEtat();
}

class _FeuillePromotionEtat extends ConsumerState<_FeuillePromotion> {
  String? _niveauId;
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
    final String? niveauId = _niveauId;
    // Bouton jamais grise (K-56) : presse trop tot, il dit ce qui manque.
    if (niveauId == null) {
      setState(() => _erreur = t.admin.progression.manqueNiveau);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      setState(() {
        _erreur = null;
        _motifManquant = true;
      });
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceProgressionProvider)
          .promouvoir(
            studentId: widget.eleve.studentId,
            niveauId: niveauId,
            motif: _motif.text.trim(),
          );
      ref.invalidate(progressionProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(
        () => _erreur = t.admin.progression.promouvoirErreur(
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
        Text(
          t.admin.progression.promouvoirChampNiveau,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vMd,
        switch (versionActive) {
          AsyncValue<VersionProgramme?>(hasValue: true) =>
            versionActive.requireValue == null
                ? Text(t.admin.diagnostics.aucunProgrammeDetail)
                : _NiveauxVersion(
                    versionId: versionActive.requireValue!.id,
                    selectionne: _niveauId,
                    onSelectionner: (String id) => setState(() {
                      _niveauId = id;
                      _erreur = null;
                    }),
                  ),
          AsyncValue<VersionProgramme?>(hasError: true) => Text(
            t.admin.progression.erreur,
          ),
          _ => const Skeleton.liste(lignes: 2),
        },
        Ecart.vLg,
        Text(
          t.admin.progression.champMotif,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vSm,
        Text(
          t.admin.progression.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        SelecteurMotif(
          motifs: MotifsProposes.changementNiveau(),
          controleur: _motif,
          libelleChamp: t.admin.progression.champMotif,
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
          libelle: t.admin.progression.promouvoirEnvoyer,
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
        t.admin.progression.erreur,
      ),
      _ => const Skeleton.liste(lignes: 2),
    };
  }
}

/// Une feuille generique « motif requis, un bouton ».
///
/// Meme forme que `admin_groupes/groupes_page.dart::_FeuilleMotif`.
class _FeuilleMotif extends StatefulWidget {
  const _FeuilleMotif({
    required this.motifs,
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
  });

  /// Les motifs proposes en puces (FORM-L1), « Autre » en dernier.
  final List<String> motifs;
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
        Text(
          t.admin.progression.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        SelecteurMotif(
          motifs: widget.motifs,
          controleur: _motif,
          libelleChamp: t.admin.progression.champMotif,
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
