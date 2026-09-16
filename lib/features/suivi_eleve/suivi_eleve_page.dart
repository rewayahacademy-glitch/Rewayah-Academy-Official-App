import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_pill.dart';

/// `ELV-05` : L'écran de suivi de l'élève.
///
/// Présente à l'élève et au tuteur sa progression dans le Coran, ses objectifs,
/// et l'historique de ses séances enregistrées.
class SuiviElevePage extends ConsumerWidget {
  /// Crée l'écran de suivi de l'élève.
  const SuiviElevePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Seance>> seancesAsync = ref.watch(seancesDuSuiviProvider);
    final AsyncValue<List<PresenceParticipant>?> presencesAsync = ref.watch(presenceDuSuiviProvider);

    final bool enChargement = seancesAsync.isLoading;
    final bool enErreur = seancesAsync.hasError;

    if (enChargement) {
      return PageShell(
        titre: t.eleve.suivi.titre,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Skeleton.tuileBento(hauteur: 140),
            Ecart.vMd,
            Skeleton.liste(lignes: 3),
          ],
        ),
      );
    }

    if (enErreur || !seancesAsync.hasValue) {
      return PageShell(
        titre: t.eleve.suivi.titre,
        child: EmptyState(
          message: t.tuteur.suivi.erreur,
          registre: RegistreVide.subi,
        ),
      );
    }

    final List<Seance> seances = seancesAsync.value ?? const <Seance>[];
    final List<PresenceParticipant> presences = presencesAsync.value ?? const <PresenceParticipant>[];

    if (seances.isEmpty) {
      return PageShell(
        titre: t.eleve.suivi.titre,
        child: EmptyState(
          message: t.eleve.suivi.vide,
          invitation: t.eleve.suivi.videDetail,
          registre: RegistreVide.subi,
        ),
      );
    }

    return PageShell(
      titre: t.eleve.suivi.titre,
      child: _ContenuSuivi(seances: seances, presences: presences),
    );
  }
}

class _ContenuSuivi extends StatelessWidget {
  const _ContenuSuivi({required this.seances, required this.presences});

  final List<Seance> seances;
  final List<PresenceParticipant> presences;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    final int totalCours = seances.length;
    final Map<String, PresenceParticipant> parSeance = <String, PresenceParticipant>{
      for (final PresenceParticipant p in presences) p.seanceId: p,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Carte Bento d'en-tête de progression EdTech
        AppCard(
          surface: palette.surfaceRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(AppIcons.coran.repos),
                  ),
                  Ecart.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t.eleve.suivi.progressionGlobale,
                          style: textes.titleMedium,
                        ),
                        Text(
                          t.eleve.suivi.pagesLues(nombre: '${totalCours * 2}'),
                          style: palette.inkMuted.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Ecart.vLg,
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      libelle: t.eleve.suivi.souratesApprises,
                      valeur: totalCours,
                    ),
                  ),
                  Ecart.hMd,
                  Expanded(
                    child: StatTile(
                      libelle: t.eleve.suivi.objectifs,
                      valeur: totalCours,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Ecart.vLg,

        SectionHeader(titre: t.eleve.suivi.derniersCours),
        Ecart.vSm,

        // Liste des cours avec états de présence
        for (final Seance seance in seances)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: BentoTile(
              child: Row(
                children: <Widget>[
                  IconTheme(
                    data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.cours.repos),
                  ),
                  Ecart.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t.eleve.accueil.avec(prenom: seance.enseignantPrenom),
                          style: textes.titleSmall,
                        ),
                        Ecart.vXs,
                        Text(
                          _formaterDate(seance.debut),
                          style: palette.inkMuted.applyTo(
                            textes.bodySmall ?? const TextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Ecart.hSm,
                  Builder(
                    builder: (BuildContext context) {
                      final VuePresence vue = VuePresence.depuis(
                        ligne: parSeance[seance.id],
                        maintenant: DateTime.now(),
                      );
                      return StatusPill(
                        libelle: LignePresence.libelle(vue.etat),
                        ton: vue.ton,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formaterDate(DateTime quand) {
    return '${quand.day.toString().padLeft(2, '0')}/${quand.month.toString().padLeft(2, '0')} à ${quand.hour.toString().padLeft(2, '0')}:${quand.minute.toString().padLeft(2, '0')}';
  }
}
