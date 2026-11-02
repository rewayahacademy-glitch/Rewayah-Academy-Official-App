import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_admin.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'etat_file_dossiers.dart';
import 'revue_dossier.dart';

/// Relit la file, le service existant (cache de production partage) et le
/// detail lu par le port (AD-6).
void actualiserDossiers(WidgetRef ref) {
  ref.invalidate(dossiersEnAttenteProvider);
  ref.invalidate(dossierPourRevueProvider);
  // AD-11 : le compteur de l'Accueil (ADM-01) suit la file apres decision.
  ref.invalidate(indicateursProvider);
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
      // Le « wifi barre » est celui du bandeau (EA-HL-DOUBLE-1).
      icone: AppIcons.attente,
      titre: t.dossiers.file.horsLigne,
      phrase: '',
      libelleAction: t.commun.etats.actions.reessayer,
      onAction: reessayer,
    );
  }
  return null;
}

/// La pastille d'une ligne : l'etat de la piece vu par ce relecteur prime
/// (« Pièce hors de votre portée »), sinon presence ou absence de piece.
(String, TonEtat) pastilleDossier(DossierEnFile d) {
  if (d.etatPiece == EtatPieceRevue.nonVisible) {
    return (t.dossiers.pieceNonVisible, TonEtat.avertissement);
  }
  return d.aPieceIdentite
      ? (t.dossiers.file.enVerification, TonEtat.accent)
      : (t.dossiers.sansPiece, TonEtat.avertissement);
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
