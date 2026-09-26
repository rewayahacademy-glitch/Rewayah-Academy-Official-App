import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import 'etat_file_dossiers.dart';
import 'file_dossiers.dart';
import 'revue_existante.dart';

/// L'etat « Selectionnez un dossier a examiner. » (deux panneaux seulement).
class AucuneSelection extends StatelessWidget {
  /// Cree l'etat.
  const AucuneSelection({super.key});

  @override
  Widget build(BuildContext context) => EtatSysteme(
    nature: NatureEtat.aucunResultat,
    titre: t.dossiers.file.aucuneSelection,
    phrase: '',
  );
}

/// Le detail d'un dossier selectionne. Jusqu'a AD-6, il lit le service
/// existant (meme cache que la file en production) et montre la revue
/// actuelle, deplacee telle quelle.
class DetailDossier extends ConsumerWidget {
  /// Cree le detail du dossier [id].
  const DetailDossier({required this.id, required this.onDecision, super.key});

  final String id;

  /// Appele apres une decision reussie, avec l'identifiant decide.
  final void Function(String id) onDecision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DossierAValider>> dossiers = ref.watch(
      dossiersEnAttenteProvider,
    );
    final EtatFile? file = ref.watch(fileDossiersProvider).value;

    return FocusTraversalGroup(
      child: BlocAsynchrone<List<DossierAValider>>(
        valeur: dossiers,
        squelette: const SqueletteDetail(),
        titreProlonge: t.dossiers.file.chargementProlonge,
        // File et detail relus ensemble : sinon la file, figee sur l'ancienne
        // lecture, ferait dire a tort « plus disponible ».
        onReessayer: () => actualiserDossiers(ref),
        erreurVersEtat: (Object e, VoidCallback? _) =>
            e is GenreLecteurInconnu ? const GenreManquant() : null,
        construire: (List<DossierAValider> liste) {
          final DossierAValider? d = liste
              .where((DossierAValider x) => x.profilId == id)
              .firstOrNull;
          final bool dansFile =
              file == null ||
              file.elements.any((DossierEnFile e) => e.dossierId == id);
          if (d == null || !dansFile) {
            return _SelectionRetiree(
              onActualiser: () {
                actualiserDossiers(ref);
                ref.read(selectionDossierProvider.notifier).retirer();
              },
            );
          }
          return KeyedSubtree(
            key: ValueKey<String>(id),
            child: RevueExistante(dossier: d, onDecision: () => onDecision(id)),
          );
        },
      ),
    );
  }
}

class _SelectionRetiree extends StatelessWidget {
  const _SelectionRetiree({required this.onActualiser});

  final VoidCallback onActualiser;

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    child: EtatSysteme(
      nature: NatureEtat.ressourceExpiree,
      titre: t.dossiers.file.selectionRetiree,
      phrase: '',
      libelleAction: t.dossiers.file.actualiser,
      onAction: onActualiser,
    ),
  );
}

/// Le squelette du detail, dans l'ordre du contenu : titre, date, constat,
/// verifications, decision.
class SqueletteDetail extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteDetail({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Skeleton(hauteur: AppSpacing.xxl),
        ),
        SizedBox(height: AppSpacing.sm),
        FractionallySizedBox(
          widthFactor: 0.35,
          child: Skeleton(hauteur: AppSpacing.lg),
        ),
        SizedBox(height: AppSpacing.xxl),
        Skeleton(hauteur: 160),
        SizedBox(height: AppSpacing.xxl),
        FractionallySizedBox(
          widthFactor: 0.3,
          child: Skeleton(hauteur: AppSpacing.xl),
        ),
        SizedBox(height: AppSpacing.md),
        Skeleton(hauteur: AppTouchTarget.standard),
        SizedBox(height: AppSpacing.md),
        Skeleton(hauteur: AppTouchTarget.standard),
        SizedBox(height: AppSpacing.md),
        Skeleton(hauteur: AppTouchTarget.standard),
        SizedBox(height: AppSpacing.xxl),
        Skeleton(hauteur: AppPage.hauteurBouton),
      ],
    ),
  );
}
