import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_pill.dart';

/// `ENS-05` : L'écran de profil de l'enseignant.
///
/// Présente à l'enseignant sa charge pédagogique (nombre d'élèves suivis),
/// ses créneaux d'enseignement posés, et les raccourcis vers ses réglages.
class ProfilEnseignantPage extends ConsumerWidget {
  /// Crée l'écran de profil de l'enseignant.
  const ProfilEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Seance>> seancesAsync = ref.watch(seancesProvider);
    final AsyncValue<List<EleveEnAttente>> enAttenteAsync = ref.watch(elevesEnAttenteProvider);

    final bool enChargement = seancesAsync.isLoading;
    final bool enErreur = seancesAsync.hasError;

    if (enChargement) {
      return PageShell(
        titre: t.enseignant.profil.titre,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Skeleton.tuileBento(hauteur: 120),
            Ecart.vMd,
            Skeleton.liste(lignes: 2),
          ],
        ),
      );
    }

    if (enErreur) {
      return PageShell(
        titre: t.enseignant.profil.titre,
        child: EmptyState(
          message: t.enseignant.journee.erreur,
          registre: RegistreVide.subi,
        ),
      );
    }

    final List<Seance> seances = seancesAsync.value ?? const <Seance>[];
    final List<EleveEnAttente> enAttente = enAttenteAsync.value ?? const <EleveEnAttente>[];

    return PageShell(
      titre: t.enseignant.profil.titre,
      child: _ContenuProfil(seances: seances, enAttente: enAttente),
    );
  }
}

class _ContenuProfil extends StatelessWidget {
  const _ContenuProfil({
    required this.seances,
    required this.enAttente,
  });

  final List<Seance> seances;
  final List<EleveEnAttente> enAttente;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    // Calcul du nombre d'élèves uniques
    final Set<String> elevesUniques = seances.map((Seance s) => s.eleveId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Carte d'identité et de statut de l'enseignant
        AppCard(
          surface: palette.surfaceRaised,
          child: Row(
            children: <Widget>[
              IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xxxl),
                child: Icon(AppIcons.profil.repos),
              ),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t.enseignant.profil.compteValide,
                      style: textes.titleMedium,
                    ),
                    Ecart.vXs,
                    StatusPill(
                      libelle: t.etat.enDirect,
                      ton: TonEtat.succes,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Ecart.vLg,

        SectionHeader(titre: t.enseignant.profil.chargePedagogique),
        Ecart.vSm,

        // Statistiques de charge d'enseignement
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                libelle: t.enseignant.profil.elevesActifs(
                  nombre: '${elevesUniques.length}',
                ),
                valeur: elevesUniques.length,
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: StatTile(
                libelle: t.enseignant.profil.heuresDisponibles(
                  nombre: '${seances.length}',
                ),
                valeur: seances.length,
              ),
            ),
          ],
        ),
        Ecart.vLg,

        // Actions & Raccourcis de gestion
        BentoTile(
          libelleSemantique: t.enseignant.profil.reglagesHeures,
          onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
          child: Row(
            children: <Widget>[
              IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.disponibilites.repos),
              ),
              Ecart.hMd,
              Expanded(
                child: Text(
                  t.enseignant.profil.reglagesHeures,
                  style: textes.titleSmall,
                ),
              ),
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ),
        ),
        Ecart.vLg,

        ActionPrincipale(
          libelle: t.enseignant.journee.voirCreneaux,
          onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
        ),
      ],
    );
  }
}
