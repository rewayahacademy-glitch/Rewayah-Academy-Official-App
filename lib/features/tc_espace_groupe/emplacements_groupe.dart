import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/port_catalogue.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';

/// Ce qu'affiche un emplacement dont le port n'est pas encore branche.
///
/// **Un etat explicite, jamais un faux contenu.** Un emplacement qui
/// inventerait trois ressources ou trois taches ferait croire que le port
/// existe, et le manque disparaitrait du radar exactement au moment ou il
/// faudrait le voir.
class EmplacementNonBranche extends StatelessWidget {
  /// Cree l'etat « non branche ».
  const EmplacementNonBranche({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: LibellesGroupe.emplacementNonBranche,
      invitation: LibellesGroupe.emplacementNonBrancheDetail,
      icone: AppIcons.rienAAfficher,
      registre: RegistreVide.subi,
    );
  }
}

/// L'emplacement « Avant le prochain cours ».
///
/// **Coquille d'Agent A.** Le vrai bloc, celui qui lit `PortTravailAVenir`,
/// est `BlocAvantProchainCours` d'Agent H
/// (`lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart`) --
/// deux lots ont choisi le meme nom independamment. Renomme au cablage des
/// slots (plan d'integration Teaching Core section 5.5) pour lever la
/// collision : c'est toujours la coquille qui change de nom, jamais
/// l'implementation reelle.
///
/// **Trois actions au maximum**, tous roles confondus. Le contenu vient
/// d'Agent H par `PortTravailAVenir` ; ce bloc ne fabrique aucune tache.
class EmplacementAvantProchainCours extends StatelessWidget {
  /// Cree le bloc.
  const EmplacementAvantProchainCours({
    required this.actions,
    super.key,
    this.portBranche = false,
  });

  /// Les actions rendues par Agent H.
  final List<SlotAction> actions;

  /// Vrai quand `PortTravailAVenir` est reellement branche.
  final bool portBranche;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.avantProchainCours),
        Ecart.vMd,
        if (!portBranche)
          const EmplacementNonBranche()
        else if (actions.isEmpty)
          EmptyState(
            message: LibellesGroupe.aucuneAction,
            icone: AppIcons.succes,
            registre: RegistreVide.bonneNouvelle,
          )
        else
          // R17 : trois actions au plus, jamais une longue liste.
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final SlotAction action in actions.take(3))
                LigneRubrique(libelle: action.libelle, icone: AppIcons.cours),
            ],
          ),
      ],
    );
  }
}

/// L'emplacement de la Bibliotheque du groupe.
///
/// **Une seule Bibliotheque** (decision `D-20`) : ce bloc n'en implemente
/// aucune. Il lit `PortCatalogue`, produit par Agent B, et se contente de poser
/// les couvertures a l'endroit prevu. Le port est toujours branche
/// (`donneesCatalogueProvider` rend `CatalogueLocal`, jamais `null`) ;
/// `_Couvertures` dit deja l'etat vide quand le groupe n'a aucune ressource.
class BlocBibliotheque extends ConsumerWidget {
  /// Cree l'emplacement.
  const BlocBibliotheque({
    required this.emplacement,
    super.key,
    this.onVoirTout,
    this.titre,
    this.limite,
  });

  /// L'enveloppe de contexte.
  final SlotBibliotheque emplacement;

  /// Le titre de section ; par defaut celui de la Bibliotheque. L'enseignant
  /// lit « Ressources recentes » (EN-3).
  final String? titre;

  /// Le nombre de ressources montrees au plus, ou nul pour toutes.
  /// L'Espace Classe enseignant en montre trois (EN-3, planche 2).
  final int? limite;

  /// L'acces au catalogue complet.
  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortCatalogue catalogue = ref.watch(portCatalogueProvider);
    final Widget entete = SectionHeader(
      titre: titre ?? LibellesGroupe.bibliotheque,
    );
    final Widget? voirTout = onVoirTout == null
        ? null
        : IntrinsicWidth(
            child: ActionPrincipale(
              libelle: LibellesGroupe.bibliothequeVoirTout,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: onVoirTout,
            ),
          );
    // A grande taille de texte, le titre prend toute la largeur et le lien
    // passe dessous, au bord de debut : un titre borne aux deux tiers se
    // couperait au milieu d'un mot (« Ressour / ces », revue EA-2).
    final bool empile =
        MediaQuery.textScalerOf(context).scale(1) >=
        AppGabarit.seuilTexteColonne;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // « Voir tout » au bord de fin de l'en-tete, sur mobile comme sur
        // bureau : `IntrinsicWidth` donne au lien sa largeur naturelle,
        // bornee par la place restante.
        if (empile) ...<Widget>[
          entete,
          if (voirTout != null)
            Align(alignment: AlignmentDirectional.centerStart, child: voirTout),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(flex: 2, child: entete),
              if (voirTout != null) ...<Widget>[
                Ecart.hLg,
                Flexible(child: voirTout),
              ],
            ],
          ),
        Ecart.vMd,
        _Couvertures(
          catalogue: catalogue,
          groupeId: emplacement.groupeId,
          limite: limite,
        ),
      ],
    );
  }
}

/// Les couvertures du groupe, rendues par Agent B.
class _Couvertures extends StatelessWidget {
  const _Couvertures({
    required this.catalogue,
    required this.groupeId,
    this.limite,
  });

  final PortCatalogue catalogue;
  final String groupeId;
  final int? limite;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryResource>>(
      future: catalogue.pourGroupe(groupeId),
      builder:
          (BuildContext contexte, AsyncSnapshot<List<LibraryResource>> etat) {
            if (etat.connectionState != ConnectionState.done) {
              return const Skeleton.liste(lignes: 1);
            }
            final List<LibraryResource> toutes =
                etat.data ?? const <LibraryResource>[];
            final int? max = limite;
            final List<LibraryResource> ressources =
                max == null || toutes.length <= max
                ? toutes
                : toutes.sublist(0, max);
            if (ressources.isEmpty) {
              return const EmplacementNonBranche();
            }
            // Une liste et non un defilement : a 320, rien ne deborde (revue
            // UX n° 14). Une ligne par support, lue d'un bloc.
            return GroupeReglages(
              lignes: <LigneRubrique>[
                for (final LibraryResource ressource in ressources)
                  LigneRubrique(
                    libelle: ressource.shortTitle,
                    icone: AppIcons.bibliotheque,
                  ),
              ],
            );
          },
    );
  }
}

/// L'emplacement de la progression, secondaire par construction.
class BlocProgression extends ConsumerWidget {
  /// Cree l'emplacement.
  const BlocProgression({required this.emplacement, super.key});

  /// L'enveloppe de contexte.
  final SlotProgression emplacement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressionCompacte? valeur = ref.watch(
      progressionGroupeProvider(emplacement.groupeId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.progression),
        Ecart.vMd,
        if (valeur == null)
          const EmplacementNonBranche()
        else
          AppCard(child: _BarreProgression(valeur: valeur)),
      ],
    );
  }
}

/// La progression compacte d'un eleve dans sa Classe (rectification 14) :
/// le chapitre et une fraction, rien d'autre. Les statistiques detaillees
/// appartiennent a la destination Progression.
@immutable
class ProgressionCompacte {
  /// Cree la progression.
  const ProgressionCompacte({required this.chapitre, required this.fraction})
    : assert(fraction >= 0 && fraction <= 1, 'une fraction entre 0 et 1');

  /// Le chapitre en cours, deja rendu : « Chapitre 1 ».
  final String chapitre;

  /// La part faite, entre 0 et 1.
  final double fraction;
}

/// La progression compacte d'un groupe. **`null` = non branche** : aucune
/// source serveur a ce jour (backend reporte a BR-1). La demonstration la
/// surcharge.
final ProviderFamily<ProgressionCompacte?, String> progressionGroupeProvider =
    Provider.family<ProgressionCompacte?, String>((Ref ref, String _) => null);

/// L'annulation de la prochaine seance d'un groupe, selon le serveur.
/// `false` tant que la source n'est pas branchee (BR-1) ; la demonstration la
/// surcharge.
final ProviderFamily<bool, String> seanceAnnuleeProvider =
    Provider.family<bool, String>((Ref ref, String _) => false);

/// Une barre, jamais un anneau, avec sa valeur ecrite a cote, en un seul
/// noeud (revue UX, ajustement n° 6).
class _BarreProgression extends StatelessWidget {
  const _BarreProgression({required this.valeur});

  final ProgressionCompacte valeur;

  @override
  Widget build(BuildContext context) {
    final String texte = t.classe.entree.progressionValeur(
      chapitre: valeur.chapitre,
      pourcentage: (valeur.fraction * 100).round(),
    );
    return Semantics(
      label: texte,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(texte, style: Theme.of(context).textTheme.titleSmall),
            Ecart.vSm,
            LinearProgressIndicator(value: valeur.fraction),
          ],
        ),
      ),
    );
  }
}

/// L'emplacement du roster pedagogique, cote enseignant et administration.
///
/// **Il ne porte aucune donnee privee famille**, et cette garantie ne tient pas
/// a ce widget : elle tient a ce que la vue serveur ne delivre pas ces
/// colonnes. `teacher_roster_v` a retire `last_name` des la migration `0005`
/// (ADR-008), et la desambiguisation se fait par prenom et identifiant
/// immuable, jamais par une initiale de nom (decision `D-08`).
///
/// Le contenu vient d'Agent E par `PortRosterEnseignant`. Agent A pose
/// l'emplacement, il ne compose pas la projection.
class BlocRoster extends StatelessWidget {
  /// Cree l'emplacement.
  const BlocRoster({required this.emplacement, super.key, this.contenu});

  /// L'enveloppe de contexte.
  final SlotRoster emplacement;

  /// La surface d'Agent E, quand l'hote l'a branchee.
  final Widget? contenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.roster),
        Ecart.vMd,
        contenu ?? const EmplacementNonBranche(),
      ],
    );
  }
}
