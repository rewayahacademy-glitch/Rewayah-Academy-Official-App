import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/port_catalogue.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
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
    final TextTheme textes = Theme.of(context).textTheme;

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
          for (final SlotAction action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Text(
                  action.libelle,
                  style: textes.titleSmall ?? const TextStyle(),
                ),
              ),
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
  });

  /// L'enveloppe de contexte.
  final SlotBibliotheque emplacement;

  /// L'acces au catalogue complet.
  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortCatalogue catalogue = ref.watch(portCatalogueProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: LibellesGroupe.bibliotheque,
          libelleAction: LibellesGroupe.bibliothequeVoirTout,
          onAction: onVoirTout,
        ),
        Ecart.vMd,
        _Couvertures(catalogue: catalogue, groupeId: emplacement.groupeId),
      ],
    );
  }
}

/// Les couvertures du groupe, rendues par Agent B.
class _Couvertures extends StatelessWidget {
  const _Couvertures({required this.catalogue, required this.groupeId});

  final PortCatalogue catalogue;
  final String groupeId;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return FutureBuilder<List<LibraryResource>>(
      future: catalogue.pourGroupe(groupeId),
      builder:
          (BuildContext contexte, AsyncSnapshot<List<LibraryResource>> etat) {
            if (etat.connectionState != ConnectionState.done) {
              return const Skeleton.liste(lignes: 1);
            }
            final List<LibraryResource> ressources =
                etat.data ?? const <LibraryResource>[];
            if (ressources.isEmpty) {
              return const EmplacementNonBranche();
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final LibraryResource ressource in ressources)
                  AppCard(
                    marge: AppSpacing.md,
                    child: Text(
                      ressource.shortTitle,
                      style: palette.inkStrong.applyTo(
                        textes.labelLarge ?? const TextStyle(),
                      ),
                    ),
                  ),
              ],
            );
          },
    );
  }
}

/// L'emplacement de la progression, secondaire par construction.
class BlocProgression extends StatelessWidget {
  /// Cree l'emplacement.
  const BlocProgression({required this.emplacement, super.key});

  /// L'enveloppe de contexte.
  final SlotProgression emplacement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.progression),
        Ecart.vMd,
        const EmplacementNonBranche(),
      ],
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
