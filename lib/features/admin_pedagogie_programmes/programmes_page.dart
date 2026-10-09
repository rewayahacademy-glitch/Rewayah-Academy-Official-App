import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_programme.dart';
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
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';

/// `ADM-13` : Pedagogie > Programmes.
///
/// **Fondation du domaine Pedagogie** : les quatre autres ecrans
/// (Diagnostics, Progression, Evaluations, Qualite) referencent un niveau
/// (`programme_niveaux`) d'une version publiee. Le contenu reel du curriculum
/// existe deja en dehors de l'app et sera importe apres verification -- cet
/// ecran administre seulement le squelette versionne qui l'accueillera
/// (migration `0020`).
///
/// **Le code technique n'est jamais un titre** : le nom humain seul est en
/// premier plan, le code (ex. `F1-PHO-01`) reste en sous-texte discret --
/// interdiction UX explicite de la mission qui a ouvert ce lot.
///
/// **Une version publiee ne se modifie plus** : impose en base (0020), pas
/// seulement ici. Toute evolution academique cree une nouvelle version
/// brouillon, eventuellement copiee depuis une version existante.
class ProgrammesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des programmes.
  const ProgrammesPage({super.key});

  @override
  ConsumerState<ProgrammesPage> createState() => _ProgrammesPageEtat();
}

class _ProgrammesPageEtat extends ConsumerState<ProgrammesPage> {
  /// La version affichee. `null` avant le premier chargement, puis la plus
  /// recente par defaut (`programme_versions_admin()` trie deja ainsi).
  String? _versionId;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<VersionProgramme>> versions = ref.watch(
      versionsProgrammeProvider,
    );

    return PageShell(
      titre: t.admin.programmes.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 3),
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.programmes.intro, style: textes.bodyMedium),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.programmes.creerVersion,
            pleineLargeur: false,
            niveau: NiveauAction.secondaire,
            onPress: () => _ouvrirCreationVersion(context, ref, source: null),
          ),
          Ecart.vXl,
          switch (versions) {
            AsyncValue<List<VersionProgramme>>(hasValue: true) =>
              versions.requireValue.isEmpty
                  ? EmptyState(
                      message: t.admin.programmes.aucuneVersion,
                      invitation: t.admin.programmes.aucuneVersionDetail,
                      icone: AppIcons.rienAAfficher,
                      registre: RegistreVide.subi,
                    )
                  : Expanded(
                      child: _Corps(
                        versions: versions.requireValue,
                        versionId: _versionId ?? versions.requireValue.first.id,
                        onSelectionner: (String id) =>
                            setState(() => _versionId = id),
                        onCreerDepuis: (VersionProgramme source) =>
                            _ouvrirCreationVersion(
                              context,
                              ref,
                              source: source,
                            ),
                        onAjouterNiveau: (VersionProgramme version) =>
                            _ouvrirAjoutNiveau(context, ref, version),
                        onModifierNiveau:
                            (
                              VersionProgramme version,
                              NiveauProgramme niveau,
                            ) => _ouvrirModifierNiveau(
                              context,
                              ref,
                              version,
                              niveau,
                            ),
                        onSupprimerNiveau:
                            (
                              VersionProgramme version,
                              NiveauProgramme niveau,
                            ) => _ouvrirSupprimerNiveau(
                              context,
                              ref,
                              version,
                              niveau,
                            ),
                        onPublier: (VersionProgramme version) =>
                            _ouvrirPublication(context, ref, version),
                      ),
                    ),
            AsyncValue<List<VersionProgramme>>(hasError: true) => EmptyState(
              message: t.admin.programmes.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(versionsProgrammeProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

/// Le selecteur de version, puis les niveaux de la version choisie.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.versions,
    required this.versionId,
    required this.onSelectionner,
    required this.onCreerDepuis,
    required this.onAjouterNiveau,
    required this.onModifierNiveau,
    required this.onSupprimerNiveau,
    required this.onPublier,
  });

  final List<VersionProgramme> versions;
  final String versionId;
  final void Function(String id) onSelectionner;
  final void Function(VersionProgramme source) onCreerDepuis;
  final void Function(VersionProgramme version) onAjouterNiveau;
  final void Function(VersionProgramme version, NiveauProgramme niveau)
  onModifierNiveau;
  final void Function(VersionProgramme version, NiveauProgramme niveau)
  onSupprimerNiveau;
  final void Function(VersionProgramme version) onPublier;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final VersionProgramme selectionnee = versions.firstWhere(
      (VersionProgramme v) => v.id == versionId,
      orElse: () => versions.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RangeeFiltres(
          filtres: <Widget>[
            for (final VersionProgramme v in versions)
              FilterPill(
                libelle: t.admin.programmes.versionNumero(
                  numero: '${v.numeroVersion}',
                ),
                compteur: v.nombreNiveaux,
                retenue: v.id == selectionnee.id,
                onPress: () => onSelectionner(v.id),
              ),
          ],
        ),
        Ecart.vLg,
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                t.admin.programmes.niveauxTitre,
                style: textes.titleMedium,
              ),
            ),
            StatusPill(
              libelle: _libelleStatut(selectionnee.statut),
              ton: switch (selectionnee.statut) {
                StatutVersionProgramme.brouillon => TonEtat.avertissement,
                StatutVersionProgramme.publiee => TonEtat.succes,
                StatutVersionProgramme.archivee => TonEtat.neutre,
              },
            ),
          ],
        ),
        Ecart.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            if (selectionnee.modifiable) ...<Widget>[
              ActionPrincipale(
                libelle: t.admin.programmes.ajouterNiveau,
                pleineLargeur: false,
                niveau: NiveauAction.secondaire,
                onPress: () => onAjouterNiveau(selectionnee),
              ),
              ActionPrincipale(
                libelle: t.admin.programmes.publierVersion,
                pleineLargeur: false,
                onPress: selectionnee.nombreNiveaux == 0
                    ? null
                    : () => onPublier(selectionnee),
              ),
            ] else
              ActionPrincipale(
                libelle: t.admin.programmes.creerVersionDepuisPubliee,
                pleineLargeur: false,
                niveau: NiveauAction.secondaire,
                onPress: () => onCreerDepuis(selectionnee),
              ),
          ],
        ),
        Ecart.vLg,
        Expanded(
          child: _Niveaux(
            version: selectionnee,
            onModifier: (NiveauProgramme n) =>
                onModifierNiveau(selectionnee, n),
            onSupprimer: (NiveauProgramme n) =>
                onSupprimerNiveau(selectionnee, n),
          ),
        ),
      ],
    );
  }
}

/// Les niveaux de la version selectionnee, groupes par cycle a l'affichage
/// (le tri vient deja de la base par `ordre`).
class _Niveaux extends ConsumerWidget {
  const _Niveaux({
    required this.version,
    required this.onModifier,
    required this.onSupprimer,
  });

  final VersionProgramme version;
  final void Function(NiveauProgramme niveau) onModifier;
  final void Function(NiveauProgramme niveau) onSupprimer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NiveauProgramme>> niveaux = ref.watch(
      niveauxProgrammeProvider(version.id),
    );

    return switch (niveaux) {
      AsyncValue<List<NiveauProgramme>>(hasValue: true) =>
        niveaux.requireValue.isEmpty
            ? EmptyState(
                message: t.admin.programmes.niveauAucun,
                invitation: t.admin.programmes.niveauAucunDetail,
                icone: AppIcons.rienAAfficher,
                registre: RegistreVide.subi,
              )
            : DataCollection<NiveauProgramme>(
                lignes: niveaux.requireValue,
                cle: (NiveauProgramme n) => ValueKey<String>(n.id),
                colonnes: <ColonneDonnees<NiveauProgramme>>[
                  ColonneDonnees<NiveauProgramme>(
                    titre: t.admin.programmes.titre,
                    role: RoleColonne.identifiante,
                    flex: 2,
                    texte: (NiveauProgramme n) => n.nomHumain,
                    rendu: (BuildContext context, NiveauProgramme n) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          n.nomHumain,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          t.admin.programmes.codeTechnique(
                            code: n.codeTechnique,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ColonneDonnees<NiveauProgramme>(
                    titre: t.admin.programmes.champCycle,
                    texte: (NiveauProgramme n) => n.cycle,
                  ),
                  ColonneDonnees<NiveauProgramme>(
                    titre: t.admin.programmes.champOrdre,
                    tabulaire: true,
                    texte: (NiveauProgramme n) => '${n.ordre}',
                  ),
                  if (version.modifiable)
                    ColonneDonnees<NiveauProgramme>(
                      titre: '',
                      role: RoleColonne.aPart,
                      flex: 0,
                      // Vide a dessein, meme convention que
                      // `admin_groupes/groupes_page.dart` : un menu d'actions
                      // n'a rien a dire en texte.
                      texte: (NiveauProgramme _) => '',
                      rendreMemeSiTexteVide: true,
                      rendu: (BuildContext _, NiveauProgramme n) => MenuActions(
                        tooltip: n.nomHumain,
                        actions: <EntreeAction>[
                          EntreeAction(
                            libelle: t.admin.programmes.modifierNiveau,
                            onChoix: () => onModifier(n),
                          ),
                          EntreeAction(
                            libelle: t.admin.programmes.supprimerNiveau,
                            destructif: true,
                            onChoix: () => onSupprimer(n),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      AsyncValue<List<NiveauProgramme>>(hasError: true) => EmptyState(
        message: t.admin.programmes.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(niveauxProgrammeProvider(version.id)),
      ),
      _ => const Skeleton.liste(lignes: 4),
    };
  }
}

String _libelleStatut(StatutVersionProgramme statut) => switch (statut) {
  StatutVersionProgramme.brouillon => t.admin.programmes.statutBrouillon,
  StatutVersionProgramme.publiee => t.admin.programmes.statutPubliee,
  StatutVersionProgramme.archivee => t.admin.programmes.statutArchivee,
};

/// Le message metier d'une exception, sans son type.
///
/// Meme forme que `admin_groupes/groupes_page.dart` : les exceptions
/// Postgrest portent le message metier en clair apres le premier « : ».
String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

void _ouvrirCreationVersion(
  BuildContext context,
  WidgetRef ref, {
  required VersionProgramme? source,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: source == null
        ? t.admin.programmes.creerVersionVide
        : t.admin.programmes.creerVersionDepuisPubliee,
    constructeur: (BuildContext contexte) => _FeuilleAction(
      detail: source == null
          ? null
          : t.admin.programmes.versionNumero(numero: '${source.numeroVersion}'),
      libelleEnvoyer: t.admin.programmes.enregistrerVersion,
      onEnvoyer: () => ref
          .read(serviceProgrammeProvider)
          .creerVersion(versionSourceId: source?.id),
      messageErreur: t.admin.programmes.creerVersionErreur,
      onSucces: () => ref.invalidate(versionsProgrammeProvider),
    ),
  );
}

void _ouvrirAjoutNiveau(
  BuildContext context,
  WidgetRef ref,
  VersionProgramme version,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.programmes.ajouterNiveauTitre(
      version: t.admin.programmes.versionNumero(
        numero: '${version.numeroVersion}',
      ),
    ),
    constructeur: (BuildContext contexte) => _FeuilleNiveau(
      libelleEnvoyer: t.admin.programmes.ajouterNiveauEnvoyer,
      avecCodeTechnique: true,
      onEnvoyer:
          ({
            required String codeTechnique,
            required String nomHumain,
            required String cycle,
            required int ordre,
            String? description,
          }) => ref
              .read(serviceProgrammeProvider)
              .ajouterNiveau(
                versionId: version.id,
                codeTechnique: codeTechnique,
                nomHumain: nomHumain,
                cycle: cycle,
                ordre: ordre,
                description: description,
              ),
      messageErreur: t.admin.programmes.ajouterNiveauErreur,
      onSucces: () {
        ref.invalidate(niveauxProgrammeProvider(version.id));
        ref.invalidate(versionsProgrammeProvider);
      },
    ),
  );
}

void _ouvrirModifierNiveau(
  BuildContext context,
  WidgetRef ref,
  VersionProgramme version,
  NiveauProgramme niveau,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.programmes.modifierNiveauTitre(nom: niveau.nomHumain),
    constructeur: (BuildContext contexte) => _FeuilleNiveau(
      libelleEnvoyer: t.admin.programmes.modifierNiveauEnvoyer,
      avecCodeTechnique: false,
      nomHumainInitial: niveau.nomHumain,
      cycleInitial: niveau.cycle,
      ordreInitial: niveau.ordre,
      descriptionInitiale: niveau.description,
      onEnvoyer:
          ({
            required String codeTechnique,
            required String nomHumain,
            required String cycle,
            required int ordre,
            String? description,
          }) => ref
              .read(serviceProgrammeProvider)
              .modifierNiveau(
                niveauId: niveau.id,
                nomHumain: nomHumain,
                cycle: cycle,
                ordre: ordre,
                description: description,
              ),
      messageErreur: t.admin.programmes.modifierNiveauErreur,
      onSucces: () => ref.invalidate(niveauxProgrammeProvider(version.id)),
    ),
  );
}

void _ouvrirSupprimerNiveau(
  BuildContext context,
  WidgetRef ref,
  VersionProgramme version,
  NiveauProgramme niveau,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.programmes.supprimerNiveauTitre(nom: niveau.nomHumain),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.programmes.supprimerNiveauEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceProgrammeProvider)
          .supprimerNiveau(niveauId: niveau.id, motif: motif),
      messageErreur: t.admin.programmes.supprimerNiveauErreur,
      onSucces: () {
        ref.invalidate(niveauxProgrammeProvider(version.id));
        ref.invalidate(versionsProgrammeProvider);
      },
    ),
  );
}

void _ouvrirPublication(
  BuildContext context,
  WidgetRef ref,
  VersionProgramme version,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.programmes.publierVersionTitre(
      version: t.admin.programmes.versionNumero(
        numero: '${version.numeroVersion}',
      ),
    ),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.programmes.publierVersionEnvoyer,
      detail: t.admin.programmes.publierVersionDetail,
      onEnvoyer: (String motif) => ref
          .read(serviceProgrammeProvider)
          .publierVersion(versionId: version.id, motif: motif),
      messageErreur: t.admin.programmes.publierVersionErreur,
      onSucces: () => ref.invalidate(versionsProgrammeProvider),
    ),
  );
}

/// Le formulaire d'un niveau : ajout (avec code technique) ou modification
/// (sans, le code technique n'est jamais modifie).
class _FeuilleNiveau extends StatefulWidget {
  const _FeuilleNiveau({
    required this.libelleEnvoyer,
    required this.avecCodeTechnique,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
    this.nomHumainInitial,
    this.cycleInitial,
    this.ordreInitial,
    this.descriptionInitiale,
  });

  final String libelleEnvoyer;
  final bool avecCodeTechnique;
  final Future<void> Function({
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  })
  onEnvoyer;
  final String Function({required String message}) messageErreur;
  final VoidCallback onSucces;
  final String? nomHumainInitial;
  final String? cycleInitial;
  final int? ordreInitial;
  final String? descriptionInitiale;

  @override
  State<_FeuilleNiveau> createState() => _FeuilleNiveauEtat();
}

class _FeuilleNiveauEtat extends State<_FeuilleNiveau> {
  final TextEditingController _codeTechnique = TextEditingController();
  late final TextEditingController _nomHumain = TextEditingController(
    text: widget.nomHumainInitial ?? '',
  );
  late final TextEditingController _cycle = TextEditingController(
    text: widget.cycleInitial ?? '',
  );
  late final TextEditingController _ordre = TextEditingController(
    text: widget.ordreInitial == null ? '' : '${widget.ordreInitial}',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.descriptionInitiale ?? '',
  );
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _codeTechnique.dispose();
    _nomHumain.dispose();
    _cycle.dispose();
    _ordre.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _valide =>
      (!widget.avecCodeTechnique || _codeTechnique.text.trim().isNotEmpty) &&
      _nomHumain.text.trim().isNotEmpty &&
      _cycle.text.trim().isNotEmpty &&
      int.tryParse(_ordre.text.trim()) != null;

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(
        codeTechnique: _codeTechnique.text.trim(),
        nomHumain: _nomHumain.text.trim(),
        cycle: _cycle.text.trim(),
        ordre: int.parse(_ordre.text.trim()),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
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
        if (widget.avecCodeTechnique) ...<Widget>[
          TextField(
            controller: _codeTechnique,
            onChanged: (String _) => setState(() {}),
            decoration: InputDecoration(
              labelText: t.admin.programmes.champCodeTechnique,
            ),
          ),
          Ecart.vMd,
        ],
        TextField(
          controller: _nomHumain,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(
            labelText: t.admin.programmes.champNomHumain,
          ),
        ),
        Ecart.vMd,
        TextField(
          controller: _cycle,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(labelText: t.admin.programmes.champCycle),
        ),
        Ecart.vMd,
        TextField(
          controller: _ordre,
          keyboardType: TextInputType.number,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(labelText: t.admin.programmes.champOrdre),
        ),
        Ecart.vMd,
        ZoneSaisie(
          controleur: _description,
          minLignes: 2,
          libelle: t.admin.programmes.champDescription,
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
          onPress: _valide ? _envoyer : null,
        ),
      ],
    );
  }
}

/// Une feuille generique « motif requis, un bouton » : suppression ou
/// publication.
///
/// Meme forme que `admin_groupes/groupes_page.dart::_FeuilleMotif`.
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
          t.admin.programmes.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        ZoneSaisie(
          controleur: _motif,
          minLignes: 2,
          libelle: t.admin.programmes.champMotif,
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

/// Une feuille generique « un bouton, sans motif » : creation de version.
class _FeuilleAction extends StatefulWidget {
  const _FeuilleAction({
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
    this.detail,
  });

  final String libelleEnvoyer;
  final Future<void> Function() onEnvoyer;
  final String Function({required String message}) messageErreur;
  final VoidCallback onSucces;
  final String? detail;

  @override
  State<_FeuilleAction> createState() => _FeuilleActionEtat();
}

class _FeuilleActionEtat extends State<_FeuilleAction> {
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
          Ecart.vLg,
        ],
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
}
