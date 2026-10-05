import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../com_messages/entree_messages_contexte.dart';
import '../com_messages/port_messages_metier.dart' show TypeObjetLie;
import 'etat_file_dossiers.dart';
import 'file_dossiers.dart';
import 'revue_dossier.dart';

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

/// Le detail d'un dossier selectionne (`ADM-02B`, AD-6), lu par le port
/// (`dossierPourRevueProvider`) : en production l'adaptateur d'AD-5 le
/// reconstruit depuis le cache deja charge, sans appel serveur de plus.
class DetailDossier extends ConsumerWidget {
  /// Cree le detail du dossier [id].
  const DetailDossier({
    required this.id,
    required this.onDecision,
    this.avecTitre = true,
    super.key,
  });

  final String id;

  /// Appele apres une decision reussie, avec l'identifiant decide.
  final void Function(String id, String message) onDecision;

  /// Faux en panneau unique : le titre est deja dans l'en-tete de page.
  final bool avecTitre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DossierPourRevue> dossier = ref.watch(
      dossierPourRevueProvider(id),
    );
    final EtatFile? file = ref.watch(fileDossiersProvider).value;

    void retirer() {
      actualiserDossiers(ref);
      ref.read(selectionDossierProvider.notifier).retirer();
    }

    return FocusTraversalGroup(
      child: BlocAsynchrone<DossierPourRevue>(
        valeur: dossier,
        squelette: const SqueletteDetail(),
        titreProlonge: t.dossiers.file.chargementProlonge,
        titreEchec: t.dossiers.revue.erreurChargement,
        // File et detail relus ensemble : sinon la file, figee sur l'ancienne
        // lecture, ferait dire a tort « plus disponible ».
        onReessayer: () => actualiserDossiers(ref),
        erreurVersEtat: (Object e, VoidCallback? _) {
          if (e is CapaciteIndisponible) {
            return EtatSysteme(
              nature: NatureEtat.indisponible,
              titre: t.dossiers.revue.etats.decisionIndisponible,
              phrase: '',
              dependance: e.dependance,
            );
          }
          if (e is! ErreurRevueDossier) {
            return null;
          }
          return switch (e.code) {
            CodeErreurRevue.interdit ||
            CodeErreurRevue.nonAutorise => EtatSysteme(
              nature: NatureEtat.accesRefuse,
              titre: t.dossiers.revue.etats.accesPerdu,
              phrase: '',
              libelleAction: t.dossiers.revue.etats.retourDossiers,
              onAction: retirer,
            ),
            CodeErreurRevue.introuvable => _SelectionRetiree(
              onActualiser: retirer,
            ),
            CodeErreurRevue.profilACompleter => const GenreManquant(),
            _ => null,
          };
        },
        construire: (DossierPourRevue d) {
          final bool dansFile =
              file == null ||
              file.elements.any((DossierEnFile e) => e.dossierId == id);
          if (!dansFile) {
            return _SelectionRetiree(onActualiser: retirer);
          }
          return KeyedSubtree(
            key: ValueKey<String>('$id#${d.revision}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RevueDossier(
                  dossier: d,
                  avecTitre: avecTitre,
                  onDecision: (String message) => onDecision(id, message),
                  onActualiser: () => actualiserDossiers(ref),
                ),
                // COM-MSG-2 : ecrire a la personne du dossier (« Ecrire a la
                // famille » quand le serveur la designe ainsi ; spec section
                // 3.2, Administration / Tuteur ou Enseignant). Rien n'est
                // rendu tant que les Messages n'ont pas de contrat
                // (COM-BR-01).
                EntreeMessagesContexte(
                  type: TypeObjetLie.dossier,
                  objetId: id,
                  ecartAvant: Ecart.vSection,
                ),
              ],
            ),
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

/// Le squelette du detail, a la geometrie du contenu : en-tete, quatre
/// cartes, puis le groupe de deux boutons au bord de fin. Sans shimmer.
class SqueletteDetail extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteDetail({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // Le texte est lu ; les formes, non.
      Text(t.dossiers.revue.etats.chargement),
      Ecart.vSm,
      ExcludeSemantics(
        child: _formes(mobile: AppGabarit.de(context) == Gabarit.mobile),
      ),
    ],
  );

  Widget _formes({required bool mobile}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 0.5,
        child: Skeleton(hauteur: AppSpacing.xxl),
      ),
      Ecart.vSm,
      const FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 0.35,
        child: Skeleton(hauteur: AppSpacing.lg),
      ),
      // La pastille d'etat de l'en-tete.
      Ecart.vSm,
      const FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 0.25,
        child: Skeleton(hauteur: AppSpacing.xxl),
      ),
      for (final double h in const <double>[
        4 * AppTouchTarget.standard,
        AppTouchTarget.standard,
        3 * AppTouchTarget.standard,
        AppTouchTarget.standard,
      ]) ...<Widget>[
        const SizedBox(height: AppSpacing.xxl),
        const FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 0.3,
          child: Skeleton(hauteur: AppSpacing.lg),
        ),
        Ecart.vSm,
        Skeleton(hauteur: h),
      ],
      Ecart.vLg,
      // Un seul emplacement de decision : pleine largeur sur mobile, au
      // bord de fin sur tablette et bureau.
      if (mobile)
        const Skeleton(hauteur: AppPage.hauteurBouton)
      else
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 160,
            child: Skeleton(hauteur: AppPage.hauteurBouton),
          ),
        ),
    ],
  );
}
