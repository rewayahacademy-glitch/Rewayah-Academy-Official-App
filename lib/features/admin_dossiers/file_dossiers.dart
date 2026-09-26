import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'etat_file_dossiers.dart';
import 'revue_existante.dart';
import 'textes_dossier.dart';

/// Sous cette largeur (file de 336 en maitre-detail), l'en-tete passe sur
/// deux lignes : compteur au debut, Actualiser au bord de fin.
const double _largeurEnTeteSurUneLigne = 352;

/// Relit la file et le service existant (source du detail jusqu'a AD-6).
void actualiserDossiers(WidgetRef ref) {
  ref.invalidate(dossiersEnAttenteProvider);
  ref.read(fileDossiersProvider.notifier).actualiser();
}

/// Les etats d'erreur propres a la file (§9.7, §26 ter), avant le cas par
/// defaut de [BlocAsynchrone].
Widget? etatErreurDossiers(
  BuildContext context,
  WidgetRef ref,
  Object erreur,
  VoidCallback? reessayer,
) {
  if (erreur is ErreurRevueDossier) {
    return switch (erreur.code) {
      CodeErreurRevue.profilACompleter => const GenreManquant(),
      CodeErreurRevue.interdit || CodeErreurRevue.nonAutorise => EtatSysteme(
        nature: NatureEtat.accesRefuse,
        titre: t.dossiers.file.accesRefuse,
        phrase: '',
      ),
      _ => null,
    };
  }
  if (erreur is CapaciteIndisponible) {
    return EtatSysteme(
      nature: NatureEtat.indisponible,
      titre: t.dossiers.file.indisponible,
      phrase: '',
      dependance: erreur.dependance,
      libelleAction: t.commun.etats.actions.retourAccueil,
      onAction: () => context.go('/admin'),
    );
  }
  if (ref.read(horsLigneProvider).value ?? false) {
    return EtatSysteme(
      nature: NatureEtat.horsLigne,
      titre: t.dossiers.file.horsLigne,
      phrase: '',
      libelleAction: t.commun.etats.actions.reessayer,
      onAction: reessayer,
    );
  }
  return null;
}

/// La file `ADM-02A` : en-tete (compteur, Actualiser), une seule surface a
/// filets, pied « Charger les dossiers suivants ».
class FileDossiers extends ConsumerWidget {
  /// Cree la file. [onChoisir] recoit l'identifiant de la ligne pressee.
  const FileDossiers({
    required this.onChoisir,
    required this.selection,
    this.focusSurSelection = false,
    this.marquerSelection = true,
    super.key,
  });

  final void Function(String dossierId) onChoisir;

  /// L'identifiant marque comme selectionne (deux panneaux), ou nul.
  final String? selection;

  /// Rend le focus a la ligne selectionnee (retour du detail).
  final bool focusSurSelection;

  /// Faux en panneau unique : aucune ligne n'est marquee selectionnee.
  final bool marquerSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatFile> file = ref.watch(fileDossiersProvider);
    final bool actualisation = file.hasValue && file.isLoading;
    final EtatFile? etat = file.value;
    final int? total = etat?.total;
    final TextTheme textes = Theme.of(context).textTheme;

    // Une actualisation qui echoue garde la liste deja autorisee (§26 ter) :
    // l'etat d'erreur se pose au-dessus. Seul un refus d'acces ou un profil a
    // completer la remplace.
    final Object? erreur = file.error;
    final bool garderListe =
        file.hasValue &&
        file.hasError &&
        !file.isLoading &&
        erreur is! ErreurRevueDossier;
    final AsyncValue<EtatFile> valeurBloc = garderListe
        ? AsyncData<EtatFile>(file.requireValue)
        : file;
    void reessayer() => actualiserDossiers(ref);

    final Widget compteur = Semantics(
      liveRegion: true,
      child: Text(
        actualisation
            ? t.dossiers.file.actualisation
            : (total == null || file.isLoading
                  ? ''
                  : (total == 1
                        ? t.dossiers.restantUn
                        : t.dossiers.restants(n: total))),
        style: textes.bodySmall,
      ),
    );
    // Largeur du libelle seul : le bouton centre son contenu et s'etirerait
    // sinon sur toute la contrainte.
    final Widget actualiser = IntrinsicWidth(
      child: ActionPrincipale(
        libelle: t.dossiers.file.actualiser,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        enCours: actualisation,
        onPress: reessayer,
      ),
    );

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Compteur au debut, Actualiser au bord de fin (contrat B, Q18) ;
          // a l'etroit (file 336, texte a 200 %), le bouton passe dessous,
          // toujours au bord de fin.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) =>
                c.maxWidth < _largeurEnTeteSurUneLigne
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      compteur,
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: actualiser,
                      ),
                    ],
                  )
                : OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: AppSpacing.sm,
                    overflowSpacing: AppSpacing.sm,
                    children: <Widget>[compteur, actualiser],
                  ),
          ),
          Ecart.vSm,
          if (garderListe) ...<Widget>[
            etatErreurDossiers(context, ref, erreur!, reessayer) ??
                EtatSysteme(
                  nature: NatureEtat.echecServeur,
                  titre: t.dossiers.file.erreur,
                  phrase: '',
                  libelleAction: t.commun.etats.actions.reessayer,
                  onAction: reessayer,
                ),
            Ecart.vLg,
          ],
          BlocAsynchrone<EtatFile>(
            valeur: valeurBloc,
            squelette: const SqueletteFile(),
            titreProlonge: t.dossiers.file.chargementProlonge,
            titreEchec: t.dossiers.file.erreur,
            onReessayer: () => actualiserDossiers(ref),
            erreurVersEtat: (Object e, VoidCallback? r) =>
                etatErreurDossiers(context, ref, e, r),
            estVide: (EtatFile e) => e.elements.isEmpty,
            vide: EmptyState(
              message: t.dossiers.aucun,
              invitation: t.dossiers.aucunDetail,
              icone: AppIcons.dossiers,
            ),
            construire: (EtatFile e) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    for (final DossierEnFile d in e.elements)
                      ligneDossier(
                        d,
                        selectionnee: marquerSelection
                            ? d.dossierId == selection
                            : null,
                        autofocus:
                            focusSurSelection && d.dossierId == selection,
                        onPress: () => onChoisir(d.dossierId),
                      ),
                  ],
                ),
                if (e.erreurSuite) ...<Widget>[
                  Ecart.vLg,
                  EtatSysteme(
                    nature: NatureEtat.echecServeur,
                    titre: t.dossiers.file.suivantsErreur,
                    phrase: '',
                    libelleAction: t.commun.etats.actions.reessayer,
                    onAction: () => unawaited(
                      ref.read(fileDossiersProvider.notifier).chargerSuivants(),
                    ),
                  ),
                ] else if (e.aSuite) ...<Widget>[
                  Ecart.vLg,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ActionPrincipale(
                      libelle: t.dossiers.file.suivants,
                      niveau: NiveauAction.secondaire,
                      pleineLargeur: false,
                      enCours: e.chargeSuite,
                      onPress: () => unawaited(
                        ref
                            .read(fileDossiersProvider.notifier)
                            .chargerSuivants(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de la file : nom, pastille, « type · date », chevron.
LigneRubrique ligneDossier(
  DossierEnFile d, {
  required VoidCallback onPress,
  bool? selectionnee,
  bool autofocus = false,
}) {
  final String nom = nomOuDefaut(d.nomAffiche);
  return LigneRubrique(
    libelle: nom,
    // Sans nom, « Dossier sans nom disponible » seul : aucun texte compose
    // hors spec.
    libelleSemantique: d.nomAffiche.trim().isEmpty ? nom : ouvrirDossier(nom),
    selectionnee: selectionnee,
    autofocus: autofocus,
    pastille: d.aPieceIdentite
        ? StatusPill(
            libelle: t.dossiers.file.enVerification,
            ton: TonEtat.accent,
          )
        : StatusPill(libelle: t.dossiers.sansPiece, ton: TonEtat.avertissement),
    legende: t.dossiers.file.legende(
      type: typeDossier(d.role),
      date: dateRevue(d.soumisLeUtc),
    ),
    onPress: onPress,
  );
}

/// Le squelette de la file : texte visible, puis quatre lignes a la forme
/// d'une vraie ligne (nom, « type · date »), sans carte ni filet.
class SqueletteFile extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteFile({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Semantics(
        liveRegion: true,
        child: Text(
          t.dossiers.file.chargement,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 4; i++) ...<Widget>[
              if (i > 0) Ecart.vXs,
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Skeleton(hauteur: AppSpacing.lg),
                    ),
                    SizedBox(height: AppSpacing.md),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Skeleton(hauteur: AppSpacing.md),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
