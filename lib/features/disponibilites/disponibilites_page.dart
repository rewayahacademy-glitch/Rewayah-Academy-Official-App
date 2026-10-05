import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import 'grille_semaine.dart';

/// `TUT-04` : les disponibilites du foyer, un enfant a la fois.
///
/// Ecran absent des specs d'origine, et pourtant necessaire : le matching
/// inverse suppose que les creneaux eleves existent, mais rien ne les produisait
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, tableau des ecrans manquants).
///
/// Sous la grille, une phrase dit **ce que cela produit**. Un ecran qui demande
/// un effort sans en montrer l'effet ne l'obtient pas.
class DisponibilitesPage extends ConsumerWidget {
  /// Cree l'ecran des disponibilites du foyer.
  const DisponibilitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveDuFoyer>> eleves = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);

    return PageShell(
      titre: t.disponibilites.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.disponibilites.effet, style: textes.bodySmall),
          Ecart.vXl,
          if (eleves.hasValue && eleves.requireValue.isEmpty)
            EmptyState(
              message: t.enfant.aucun,
              invitation: t.enfant.aucunDetail,
            )
          else
            for (final EleveDuFoyer eleve
                in eleves.value ?? const <EleveDuFoyer>[])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: _BlocEnfant(
                  eleve: eleve,
                  fuseau: fuseau.value ?? 'Europe/Paris',
                ),
              ),
        ],
      ),
    );
  }
}

class _BlocEnfant extends ConsumerStatefulWidget {
  const _BlocEnfant({required this.eleve, required this.fuseau});

  final EleveDuFoyer eleve;
  final String fuseau;

  @override
  ConsumerState<_BlocEnfant> createState() => _BlocEnfantEtat();
}

class _BlocEnfantEtat extends ConsumerState<_BlocEnfant> {
  bool _enCours = false;
  bool _erreur = false;

  Future<void> _basculer(Creneau creneau, bool posee) async {
    setState(() {
      _enCours = true;
      _erreur = false;
    });
    try {
      final ServicePlanning service = ref.read(servicePlanningProvider);
      if (posee) {
        await service.retirer(profilId: widget.eleve.id, creneau: creneau);
      } else {
        await service.poser(profilId: widget.eleve.id, creneau: creneau);
      }
      ref.invalidate(disponibilitesProvider(widget.eleve.id));
    } on Object {
      // Une case qui n'a pas ete enregistree doit le dire : sinon la grille
      // montre un etat que la base ne connait pas.
      if (mounted) {
        setState(() => _erreur = true);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<List<Creneau>> creneaux = ref.watch(
      disponibilitesProvider(widget.eleve.id),
    );
    // Jamais un filtre par type d'execution : Riverpod 3 relance un provider en
    // echec, et l'etat repasse par AsyncLoading en conservant hasError.
    final List<Creneau> poses = creneaux.value ?? const <Creneau>[];

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.eleve.prenom, style: textes.titleMedium),
          Text(
            t.disponibilites.consigne(prenom: widget.eleve.prenom),
            style: textes.bodySmall,
          ),
          Ecart.vMd,
          GrilleSemaine(
            creneaux: poses,
            fuseau: widget.fuseau,
            enCours: _enCours,
            onBasculer: _basculer,
          ),
          Ecart.vSm,
          if (poses.isEmpty && creneaux.hasValue)
            Text(
              t.disponibilites.aucuneDetail(prenom: widget.eleve.prenom),
              style: textes.bodySmall,
            )
          else
            Text(
              poses.length == 1
                  ? t.disponibilites.poseeUne
                  : t.disponibilites.posees(nombre: '${poses.length}'),
              style: textes.bodySmall,
            ),
          if (_erreur || creneaux.hasError) ...<Widget>[
            Ecart.vSm,
            Text(
              t.disponibilites.erreur,
              // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
              // blanc, ce qui est illisible sur la page (etape 3).
              style: palette.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
