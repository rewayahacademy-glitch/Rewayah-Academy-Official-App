import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_programme.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_etiquete.dart';
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
      // ONGLETS-COUPE-1 : en cartes (telephone, tablette), l'introduction,
      // les filtres et la liste defilent ensemble ; en tableau, la liste
      // defile seule sous son en-tete colle.
      defilante: !DataCollection.enTableau(context),
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
                  : PlaceCollection(
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

    return ColonneCorps(
      minimumEtire: DataCollection.minimumLisible(context),
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
        if (selectionnee.modifiable)
          _ActionsBrouillon(
            version: selectionnee,
            onAjouterNiveau: onAjouterNiveau,
            onPublier: onPublier,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ActionPrincipale(
                libelle: t.admin.programmes.creerVersionDepuisPubliee,
                pleineLargeur: false,
                niveau: NiveauAction.secondaire,
                onPress: () => onCreerDepuis(selectionnee),
              ),
            ],
          ),
        Ecart.vLg,
        PlaceCollection(
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

/// « Ajouter un niveau » et « Publier la version » d'un brouillon.
///
/// « Publier la version » n'est jamais grise (BOUTONS-GRISES-1) : sans
/// niveau, l'appui dit ce qui manque sous les boutons (region live),
/// l'annonce au lecteur d'ecran et rend le focus a « Ajouter un niveau »,
/// le geste qui comble le manque.
class _ActionsBrouillon extends StatefulWidget {
  const _ActionsBrouillon({
    required this.version,
    required this.onAjouterNiveau,
    required this.onPublier,
  });

  final VersionProgramme version;
  final void Function(VersionProgramme version) onAjouterNiveau;
  final void Function(VersionProgramme version) onPublier;

  @override
  State<_ActionsBrouillon> createState() => _ActionsBrouillonEtat();
}

class _ActionsBrouillonEtat extends State<_ActionsBrouillon> {
  final FocusNode _focusAjouter = FocusNode(debugLabel: 'ajouter-niveau');
  bool _manqueDit = false;

  @override
  void didUpdateWidget(_ActionsBrouillon ancien) {
    super.didUpdateWidget(ancien);
    if (widget.version.nombreNiveaux > 0 ||
        widget.version.id != ancien.version.id) {
      _manqueDit = false;
    }
  }

  @override
  void dispose() {
    _focusAjouter.dispose();
    super.dispose();
  }

  void _publier() {
    if (widget.version.nombreNiveaux == 0) {
      setState(() => _manqueDit = true);
      signalerManque(
        context,
        t.admin.programmes.publierSansNiveau,
        champ: _focusAjouter,
      );
      return;
    }
    widget.onPublier(widget.version);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            ActionPrincipale(
              libelle: t.admin.programmes.ajouterNiveau,
              pleineLargeur: false,
              niveau: NiveauAction.secondaire,
              focusNode: _focusAjouter,
              onPress: () => widget.onAjouterNiveau(widget.version),
            ),
            ActionPrincipale(
              libelle: t.admin.programmes.publierVersion,
              pleineLargeur: false,
              onPress: _publier,
            ),
          ],
        ),
        if (_manqueDit && widget.version.nombreNiveaux == 0) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.admin.programmes.publierSansNiveau,
              key: const ValueKey<String>('programmes-publier-sans-niveau'),
              style: AppPalette.of(context).inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
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
                defileAvecLaPage: !DataCollection.enTableau(context),
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

/// Le code technique propose depuis le nom affiche : minuscules, sans accents,
/// mots separes par des tirets (FORM-L5). L'unicite reste verifiee par
/// `ajouterNiveau`.
String codeDepuisNom(String nom) {
  const String avec = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const String sans = 'aaaaaaceeeeiiiinooooouuuuyy';
  final StringBuffer sortie = StringBuffer();
  for (final String c in nom.toLowerCase().split('')) {
    final int i = avec.indexOf(c);
    sortie.write(
      i >= 0
          ? sans[i]
          : switch (c) {
              'œ' => 'oe',
              'æ' => 'ae',
              _ => c,
            },
    );
  }
  return sortie
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
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
      existants:
          ref.read(niveauxProgrammeProvider(version.id)).value ??
          const <NiveauProgramme>[],
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
      existants:
          ref.read(niveauxProgrammeProvider(version.id)).value ??
          const <NiveauProgramme>[],
      niveauModifieId: niveau.id,
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
    this.existants = const <NiveauProgramme>[],
    this.niveauModifieId,
    this.nomHumainInitial,
    this.cycleInitial,
    this.ordreInitial,
    this.descriptionInitiale,
  });

  /// Les niveaux deja presents dans la version : ils fournissent les cycles
  /// proposes en puces et le dernier ordre de chaque cycle (FORM-L5).
  final List<NiveauProgramme> existants;

  /// Le niveau en cours de modification, exclu du calcul de l'ordre.
  final String? niveauModifieId;

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

  /// Les cycles deja presents dans la version, dans l'ordre ou ils
  /// apparaissent (les niveaux arrivent tries par `ordre`).
  late final List<String> _cyclesExistants = <String>{
    for (final NiveauProgramme n in widget.existants)
      if (n.cycle.isNotEmpty) n.cycle,
  }.toList();

  /// Le cycle retenu parmi les puces, ou `null` en saisie d'un nouveau cycle.
  String? _cycleChoisi;

  /// Vrai quand la saisie d'un nouveau cycle est ouverte.
  late bool _nouveauCycle;

  /// Vrai des que l'utilisateur a modifie lui-meme l'ordre ou le code : plus
  /// rien ne les ecrase.
  bool _codeManuel = false;
  bool _codeAffiche = false;

  @override
  void initState() {
    super.initState();
    final String? initial = widget.cycleInitial;
    if (initial != null && _cyclesExistants.contains(initial)) {
      _cycleChoisi = initial;
    } else if (initial == null && _cyclesExistants.isNotEmpty) {
      // Ajout : on propose le cycle du dernier niveau.
      _cycleChoisi = widget.existants.last.cycle;
    }
    _nouveauCycle = _cycleChoisi == null;
    if (widget.ordreInitial == null) {
      _ordre.text = '${_ordreDeduit()}';
    }
  }

  @override
  void dispose() {
    _codeTechnique.dispose();
    _nomHumain.dispose();
    _cycle.dispose();
    _ordre.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Le cycle effectivement retenu.
  String get _cycleRetenu =>
      _nouveauCycle ? _cycle.text.trim() : (_cycleChoisi ?? '');

  /// Le dernier ordre du cycle retenu, plus un ; plus grand ordre de la
  /// version, plus un, pour un cycle nouveau ; 1 pour une version vide.
  int _ordreDeduit() {
    final String? cycle = _nouveauCycle ? null : _cycleChoisi;
    int dernier = 0;
    for (final NiveauProgramme n in widget.existants) {
      if (n.id == widget.niveauModifieId) continue;
      if ((cycle == null || n.cycle == cycle) && n.ordre > dernier) {
        dernier = n.ordre;
      }
    }
    return dernier + 1;
  }

  void _choisirCycle(String? cycle) {
    setState(() {
      _cycleChoisi = cycle;
      _nouveauCycle = cycle == null;
      _ordre.text = '${_ordreDeduit()}';
    });
  }

  void _pas(int delta) {
    final int courant = int.tryParse(_ordre.text.trim()) ?? 0;
    setState(() => _ordre.text = '${courant + delta}');
  }

  /// Ce qui manque pour envoyer, en mots du directeur.
  List<String> get _manques => <String>[
    if (_nomHumain.text.trim().isEmpty) t.admin.programmes.manqueNom,
    if (_cycleRetenu.isEmpty) t.admin.programmes.manqueCycle,
    if (int.tryParse(_ordre.text.trim()) == null)
      t.admin.programmes.manqueOrdre,
    if (widget.avecCodeTechnique && _codeTechnique.text.trim().isEmpty)
      t.admin.programmes.manqueCode,
  ];

  Future<void> _envoyer() async {
    final List<String> manques = _manques;
    if (manques.isNotEmpty) {
      setState(
        () => _erreur = t.admin.programmes.manque(elements: manques.join(', ')),
      );
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(
        codeTechnique: _codeTechnique.text.trim(),
        nomHumain: _nomHumain.text.trim(),
        cycle: _cycleRetenu,
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
        ChampEtiquete(
          libelle: t.admin.programmes.champNomHumain,
          controller: _nomHumain,
          onChanged: (String nom) => setState(() {
            if (widget.avecCodeTechnique && !_codeManuel) {
              _codeTechnique.text = codeDepuisNom(nom);
            }
          }),
        ),
        Ecart.vMd,
        if (widget.avecCodeTechnique) ...<Widget>[
          if (_codeAffiche)
            ChampEtiquete(
              libelle: t.admin.programmes.champCodeTechnique,
              controller: _codeTechnique,
              onChanged: (String _) => setState(() => _codeManuel = true),
            )
          else ...<Widget>[
            if (_codeTechnique.text.isNotEmpty)
              Text(
                t.admin.programmes.codeGenere(code: _codeTechnique.text),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ActionPrincipale(
              libelle: t.admin.programmes.codeModifier,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => setState(() => _codeAffiche = true),
            ),
          ],
          Ecart.vMd,
        ],
        Text(
          t.admin.programmes.champCycle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : le cycle du niveau a creer.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final String cycle in _cyclesExistants)
              FilterPill(
                libelle: cycle,
                retenue: !_nouveauCycle && _cycleChoisi == cycle,
                onPress: () => _choisirCycle(cycle),
              ),
            if (_cyclesExistants.isNotEmpty)
              FilterPill(
                libelle: t.admin.programmes.nouveauCycle,
                retenue: _nouveauCycle,
                onPress: () => _choisirCycle(null),
              ),
          ],
        ),
        if (_nouveauCycle) ...<Widget>[
          Ecart.vMd,
          ChampEtiquete(
            libelle: t.admin.programmes.champNouveauCycle,
            controller: _cycle,
            onChanged: (String _) => setState(() {}),
          ),
        ],
        Ecart.vMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            BoutonIcone(
              icone: AppIcons.moins,
              libelle: t.admin.programmes.ordreMoins,
              onPress: () => _pas(-1),
            ),
            Ecart.hSm,
            Expanded(
              child: ChampEtiquete(
                libelle: t.admin.programmes.champOrdre,
                controller: _ordre,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (String _) => setState(() {}),
              ),
            ),
            Ecart.hSm,
            BoutonIcone(
              icone: AppIcons.ajouter,
              libelle: t.admin.programmes.ordrePlus,
              onPress: () => _pas(1),
            ),
          ],
        ),
        Ecart.vSm,
        Text(
          t.admin.programmes.ordreDeduit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vMd,
        ChampEtiquete(
          libelle: t.admin.programmes.champDescription,
          controller: _description,
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
          libelle: widget.libelleEnvoyer,
          enCours: _envoi,
          onPress: _envoyer,
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
  final FocusNode _focusMotif = FocusNode(debugLabel: 'motif-programme');
  bool _envoi = false;
  bool _motifManquant = false;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    _focusMotif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    // Jamais grise (BOUTONS-GRISES-1) : sans motif, l'appui le dit sous le
    // champ, l'annonce et rend le focus au champ.
    if (_motif.text.trim().isEmpty) {
      final String message = t.formulaire.motif.manqueSaisi;
      setState(() => _motifManquant = true);
      signalerManque(context, message, champ: _focusMotif);
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
          t.admin.programmes.motifRequis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Ecart.vSm,
        ZoneSaisie(
          controleur: _motif,
          noeud: _focusMotif,
          minLignes: 2,
          libelle: t.admin.programmes.champMotif,
          erreur: _motifManquant ? t.formulaire.motif.manqueSaisi : null,
          onChanged: (String _) => setState(() => _motifManquant = false),
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
