import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_comptes.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../classes/carte_classe.dart';
import '../classes/domaine/classe_vm.dart';
import '../classes/domaine/erreur_domaine.dart';
import '../classes/domaine/providers.dart';
import '../classes/libelles_classes.dart';
import 'creation_classe_page.dart';
import 'feuille_observation_groupe.dart';

/// Operations > Classes : le noyau du produit.
///
/// **Une Classe, pas une affectation** : un enseignant, jusqu'a la capacite
/// lue du serveur, un creneau hebdomadaire partage, et c'est la que la visio
/// se tient. Le mot visible est **Classe** ; le backend `groupes` reste tel
/// quel, sans migration de renommage (contrat du sprint, section 2).
///
/// Ce que cet ecran ne montre plus, depuis le sprint noyau 24 h : un champ
/// d'identifiant d'enseignant, un « jour = 1 », une « heure = 16 », une erreur
/// Postgres brute. La creation passe par `CreationClassePage`, page entiere
/// sur toutes les largeurs ; l'inscription d'un eleve se choisit dans une
/// liste, jamais par un identifiant saisi.
///
/// Meme squelette liste+filtre que `ADM-08` (Comptes) : `FilterPill` pour
/// l'axe ferme (le public), `DataCollection` pour les lignes, un tableau dense
/// sur bureau et des cartes ailleurs. Le clic sur une ligne ouvre le detail en
/// feuille, comme le reste du produit.
class GroupesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran des Classes.
  const GroupesPage({super.key});

  @override
  ConsumerState<GroupesPage> createState() => _GroupesPageEtat();
}

class _GroupesPageEtat extends ConsumerState<GroupesPage> {
  /// Le filtre courant. `null` veut dire « tous ».
  PublicClasse? _public;

  /// Le retour local apres une publication.
  String? _retour;

  Future<void> _ouvrirCreation({required bool lot}) async {
    // Une page, poussee sur le navigateur : le bouton precedent du navigateur
    // la ferme, et aucune feuille geante avec poignee ne porte un workflow
    // long (contrat, section 12). La page rend le nombre de Classes publiees.
    final int? publiees = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (BuildContext _) => CreationClassePage(lot: lot),
      ),
    );
    if (publiees != null && mounted) {
      ref.invalidate(classesAdminProvider);
      setState(
        () => _retour = publiees == 1
            ? t.classes.admin.creation.succes
            : t.classes.admin.creation.succesLot(nombre: publiees),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<ClasseVM>> classes = ref.watch(classesAdminProvider);
    final bool large = AppGabarit.de(context).estLarge;

    final List<Widget> boutons = <Widget>[
      ActionPrincipale(
        libelle: t.admin.groupes.creer,
        pleineLargeur: false,
        onPress: () => unawaited(_ouvrirCreation(lot: false)),
      ),
      ActionPrincipale(
        libelle: t.classes.admin.genererEnLot,
        niveau: NiveauAction.secondaire,
        pleineLargeur: false,
        onPress: () => unawaited(_ouvrirCreation(lot: true)),
      ),
    ];

    return PageShell(
      titre: t.admin.groupes.titre,
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.groupes.intro, style: textes.bodyMedium),
          Ecart.vLg,
          // [RESPONSIVE]
          // Deux actions cote a cote quand la place le permet, l'une sous
          // l'autre sur telephone : jamais un bouton etire.
          if (large)
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: boutons,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[boutons[0], Ecart.vSm, boutons[1]],
            ),
          Ecart.vMd,
          LocalFeedback(message: _retour),
          Ecart.vMd,
          switch (classes) {
            AsyncValue<List<ClasseVM>>(hasValue: true) => Expanded(
              child: _Corps(
                classes: classes.requireValue,
                publicClasse: _public,
                onPublic: (PublicClasse? p) => setState(() => _public = p),
                onSelectionner: (ClasseVM c) => _ouvrirDetail(context, ref, c),
                onAjouter: (ClasseVM c) => _ouvrirAjout(context, ref, c),
                onModifierSeuil: (ClasseVM c) =>
                    _ouvrirModifierSeuil(context, ref, c),
                onObservation: (ClasseVM c) =>
                    _ouvrirObservation(context, ref, c),
                onCloturer: (ClasseVM c) => _ouvrirCloture(context, ref, c),
              ),
            ),
            AsyncValue<List<ClasseVM>>(hasError: true) => EmptyState(
              message: t.admin.groupes.erreur,
              invitation: messageHumain(classes.error!),
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(classesAdminProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}

/// Les filtres, puis le tableau des Classes.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.classes,
    required this.publicClasse,
    required this.onPublic,
    required this.onSelectionner,
    required this.onAjouter,
    required this.onModifierSeuil,
    required this.onObservation,
    required this.onCloturer,
  });

  final List<ClasseVM> classes;
  final PublicClasse? publicClasse;
  final void Function(PublicClasse? publicClasse) onPublic;
  final void Function(ClasseVM classe) onSelectionner;
  final void Function(ClasseVM classe) onAjouter;
  final void Function(ClasseVM classe) onModifierSeuil;
  final void Function(ClasseVM classe) onObservation;
  final void Function(ClasseVM classe) onCloturer;

  @override
  Widget build(BuildContext context) {
    final List<ClasseVM> visibles = classes
        .where(
          (ClasseVM c) => publicClasse == null || c.publicClasse == publicClasse,
        )
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
              compteur: classes.length,
              retenue: publicClasse == null,
              onPress: () => onPublic(null),
            ),
            for (final PublicClasse p in PublicClasse.values)
              FilterPill(
                libelle: LibellesClasses.publicClasse(p),
                compteur: classes
                    .where((ClasseVM c) => c.publicClasse == p)
                    .length,
                retenue: publicClasse == p,
                onPress: () => onPublic(p),
              ),
          ],
        ),
        Ecart.vLg,
        if (visibles.isEmpty)
          EmptyState(
            message: classes.isEmpty
                ? t.admin.groupes.aucun
                : t.admin.groupes.aucunAvecCeFiltre,
            invitation: classes.isEmpty
                ? t.admin.groupes.aucunDetail
                : t.admin.groupes.aucunAvecCeFiltreDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        else
          Expanded(
            child: DataCollection<ClasseVM>(
              lignes: visibles,
              cle: (ClasseVM c) => ValueKey<String>(c.id),
              onSelectionner: onSelectionner,
              colonnes: <ColonneDonnees<ClasseVM>>[
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneGroupe,
                  role: RoleColonne.identifiante,
                  flex: 2,
                  texte: (ClasseVM c) => c.libelle,
                ),
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneEnseignant,
                  texte: (ClasseVM c) => c.enseignant == null
                      ? t.classes.carte.enseignantAAffecter
                      : LibellesClasses.enseignantNomme(c.enseignant!),
                ),
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneType,
                  texte: (ClasseVM c) =>
                      LibellesClasses.publicClasse(c.publicClasse),
                ),
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneCreneau,
                  texte: (ClasseVM c) => LibellesClasses.creneau(c.creneau),
                ),
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneMembres,
                  tabulaire: true,
                  texte: (ClasseVM c) => LibellesClasses.capacite(
                    inscrits: c.inscrits,
                    seuil: c.capacite,
                  ),
                ),
                ColonneDonnees<ClasseVM>(
                  titre: t.admin.groupes.colonneEtat,
                  texte: (ClasseVM c) => LibellesClasses.etat(c.etat),
                  rendu: (BuildContext _, ClasseVM c) => StatusPill(
                    libelle: LibellesClasses.etat(c.etat),
                    ton: LibellesClasses.tonEtat(c.etat),
                  ),
                ),
                ColonneDonnees<ClasseVM>(
                  titre: '',
                  role: RoleColonne.aPart,
                  flex: 0,
                  // Vide a dessein : un menu d'actions n'a rien a dire en
                  // texte. `rendreMemeSiTexteVide` fait rendre `rendu` quand
                  // meme, sans faire disparaitre la cellule comme le ferait
                  // un texte vide par defaut.
                  texte: (ClasseVM _) => '',
                  rendreMemeSiTexteVide: true,
                  rendu: (BuildContext _, ClasseVM c) =>
                      c.etat == EtatPublication.cloturee
                      ? const SizedBox.shrink()
                      : MenuActions(
                          tooltip: c.libelle,
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
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

void _ouvrirDetail(BuildContext context, WidgetRef ref, ClasseVM classe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.detailTitre(libelle: classe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleDetail(
      classe: classe,
      onRetirer: (String studentId, String prenom) =>
          _ouvrirRetrait(context, ref, classe, studentId, prenom),
    ),
  );
}

void _ouvrirAjout(BuildContext context, WidgetRef ref, ClasseVM classe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.ajouterTitre(libelle: classe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleAjout(
      classe: classe,
      onAjoute: () {
        ref.invalidate(classesAdminProvider);
        ref.invalidate(membresClasseProvider(classe.id));
      },
    ),
  );
}

void _ouvrirRetrait(
  BuildContext context,
  WidgetRef ref,
  ClasseVM classe,
  String studentId,
  String prenom,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.retirerTitre(prenom: prenom, libelle: classe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.groupes.retirerEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(serviceGroupesProvider)
          .retirerEleve(groupeId: classe.id, studentId: studentId, motif: motif),
      messageErreur: t.admin.groupes.retirerErreur,
      onSucces: () {
        ref.invalidate(classesAdminProvider);
        ref.invalidate(membresClasseProvider(classe.id));
      },
    ),
  );
}

void _ouvrirModifierSeuil(
  BuildContext context,
  WidgetRef ref,
  ClasseVM classe,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.modifierSeuilTitre(libelle: classe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleSeuil(
      classe: classe,
      onModifie: () => ref.invalidate(classesAdminProvider),
    ),
  );
}

/// Le reglage de l'observation par les tuteurs, Classe par Classe.
///
/// **Ici et pas dans Configuration** : la RPC `definir_politique_observation_
/// groupe` prend un `p_groupe_id` et n'ecrit que sur `public.groupes`. Les
/// defauts de l'Academie, eux, vivent dans `app_config` et n'ont aujourd'hui
/// aucune fonction d'ecriture dediee.
void _ouvrirObservation(BuildContext context, WidgetRef ref, ClasseVM classe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.observationTitre(libelle: classe.libelle),
    constructeur: (BuildContext contexte) => FeuilleObservationGroupe(
      groupeId: classe.id,
      onEnregistre: () => ref.invalidate(classesAdminProvider),
    ),
  );
}

void _ouvrirCloture(BuildContext context, WidgetRef ref, ClasseVM classe) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.cloturerTitre(libelle: classe.libelle),
    constructeur: (BuildContext contexte) => _FeuilleMotif(
      libelleEnvoyer: t.admin.groupes.cloturerEnvoyer,
      detail: t.admin.groupes.cloturerDetail,
      onEnvoyer: (String motif) => ref
          .read(serviceGroupesProvider)
          .cloturer(groupeId: classe.id, motif: motif),
      messageErreur: t.admin.groupes.cloturerErreur,
      onSucces: () => ref.invalidate(classesAdminProvider),
    ),
  );
}

/// Le detail d'une Classe : sa carte, detail ouvert, puis ses inscrits.
class _FeuilleDetail extends ConsumerWidget {
  const _FeuilleDetail({required this.classe, required this.onRetirer});

  final ClasseVM classe;
  final void Function(String studentId, String prenom) onRetirer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MembreClasse>> membres = ref.watch(
      membresClasseProvider(classe.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarteClasse(classe: classe, detailOuvert: true),
        Ecart.vLg,
        Text(
          t.admin.groupes.detailMembres,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vMd,
        switch (membres) {
          AsyncValue<List<MembreClasse>>(hasValue: true) =>
            membres.requireValue.isEmpty
                ? Text(t.admin.groupes.detailAucunMembre)
                : Column(
                    children: <Widget>[
                      for (final MembreClasse membre in membres.requireValue)
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
                                    onRetirer(membre.id, membre.libelle),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          AsyncValue<List<MembreClasse>>(hasError: true) => Text(
            t.admin.groupes.erreur,
          ),
          _ => const Skeleton.liste(lignes: 3),
        },
      ],
    );
  }
}

/// L'inscription d'un eleve : un choix dans la liste des eleves, un motif.
///
/// **Aucun identifiant a saisir.** Les eleves viennent de `comptes_admin()`,
/// filtres par un texte libre sur le prenom et le nom d'affichage. La base
/// refuse toujours un eleve deja place ou une Classe au plafond : l'ecran le
/// dit en langage humain, jamais avec le message Postgres.
class _FeuilleAjout extends ConsumerStatefulWidget {
  const _FeuilleAjout({required this.classe, required this.onAjoute});

  final ClasseVM classe;
  final VoidCallback onAjoute;

  @override
  ConsumerState<_FeuilleAjout> createState() => _FeuilleAjoutEtat();
}

class _FeuilleAjoutEtat extends ConsumerState<_FeuilleAjout> {
  final TextEditingController _recherche = TextEditingController();
  final TextEditingController _motif = TextEditingController();
  String? _eleveId;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _recherche.dispose();
    _motif.dispose();
    super.dispose();
  }

  Future<void> _ajouter() async {
    final String? eleveId = _eleveId;
    if (eleveId == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceGroupesProvider)
          .ajouterEleve(
            groupeId: widget.classe.id,
            studentId: eleveId,
            motif: _motif.text.trim(),
          );
      widget.onAjoute();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (erreur) {
      setState(
        () => _erreur = t.admin.groupes.ajouterErreur(
          message: messageHumain(erreur),
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String requete = _recherche.text.trim().toLowerCase();

    final List<CompteAdmin> eleves = (comptes.value ?? const <CompteAdmin>[])
        .where((CompteAdmin c) => c.role == AppRole.student)
        .where(
          (CompteAdmin c) =>
              requete.isEmpty || c.libelle.toLowerCase().contains(requete),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _recherche,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(
            labelText: t.admin.comptes.colonnePersonne,
            prefixIcon: Icon(AppIcons.recherche.repos),
          ),
        ),
        Ecart.vMd,
        if (!comptes.hasValue)
          const Skeleton.texte(lignes: 2)
        else if (eleves.isEmpty)
          Text(t.admin.comptes.aucunAvecCeFiltre, style: textes.bodySmall)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final CompteAdmin eleve in eleves.take(20))
                FilterPill(
                  libelle: eleve.libelle,
                  retenue: eleve.profilId == _eleveId,
                  onPress: () => setState(() => _eleveId = eleve.profilId),
                ),
            ],
          ),
        Ecart.vMd,
        Text(t.admin.groupes.motifRequis, style: textes.bodySmall),
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
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: t.admin.groupes.ajouterEnvoyer,
          enCours: _envoi,
          onPress: _eleveId == null || _motif.text.trim().isEmpty
              ? null
              : () => unawaited(_ajouter()),
        ),
        Ecart.vMd,
        Text(t.admin.groupes.journalisation, style: textes.bodySmall),
      ],
    );
  }
}

/// Le formulaire de la capacite.
class _FeuilleSeuil extends StatefulWidget {
  const _FeuilleSeuil({required this.classe, required this.onModifie});

  final ClasseVM classe;
  final VoidCallback onModifie;

  @override
  State<_FeuilleSeuil> createState() => _FeuilleSeuilEtat();
}

class _FeuilleSeuilEtat extends State<_FeuilleSeuil> {
  late final TextEditingController _seuil = TextEditingController(
    text: '${widget.classe.capacite}',
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
            groupeId: widget.classe.id,
            libelle: widget.classe.libelle,
            seuilMax: int.parse(_seuil.text.trim()),
            creneau: Creneau(
              jour: widget.classe.creneau.jourIso,
              heure: widget.classe.creneau.heure,
              fuseau: widget.classe.creneau.fuseauIana,
            ),
          );
      widget.onModifie();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (erreur) {
      setState(
        () => _erreur = t.admin.groupes.modifierSeuilErreur(
          message: messageHumain(erreur),
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
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
              style: palette.inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.admin.groupes.modifierSeuilEnvoyer,
            enCours: _envoi,
            onPress: int.tryParse(_seuil.text.trim()) == null
                ? null
                : () => unawaited(_modifier(ref)),
          ),
        ],
      ),
    );
  }
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
    } on Object catch (erreur) {
      setState(
        () => _erreur = widget.messageErreur(message: messageHumain(erreur)),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.detail != null) ...<Widget>[
          Text(widget.detail!, style: textes.bodyMedium),
          Ecart.vMd,
        ],
        Text(t.admin.groupes.motifRequis, style: textes.bodySmall),
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
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: widget.libelleEnvoyer,
          enCours: _envoi,
          onPress: _motif.text.trim().isEmpty
              ? null
              : () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}
