import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_outils/learning_assignment.dart';
import '../../core/tc_outils/port_assignations.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/bloc_seance.dart';
import 'contexte_classe.dart';
import 'planning_classe_page.dart' show CleEleveClasse;

/// Le travail d'un eleve dans sa classe, le plus urgent d'abord.
///
/// **Pure.** Un travail retire par l'enseignant (`annule`) n'est pas montre ;
/// les autres gardent leur statut serveur. Ordre : echeance la plus proche,
/// puis sans echeance, puis par date de debut.
List<LearningAssignment> travauxAffiches(
  Iterable<LearningAssignment> travaux,
) =>
    travaux
        .where((LearningAssignment a) => a.status != StatutAssignation.annule)
        .toList()
      ..sort((LearningAssignment a, LearningAssignment b) {
        final DateTime? ea = a.dueAtUtc;
        final DateTime? eb = b.dueAtUtc;
        if (ea != null && eb != null && ea != eb) {
          return ea.compareTo(eb);
        }
        if (ea == null && eb != null) {
          return 1;
        }
        if (ea != null && eb == null) {
          return -1;
        }
        return a.startsAtUtc.compareTo(b.startsAtUtc);
      });

/// Le libelle et le ton d'un statut de travail, tel que le serveur le rend.
({String libelle, TonEtat ton}) statutTravail(StatutAssignation statut) {
  final s = t.classe.pageTravail.statut;
  return switch (statut) {
    StatutAssignation.aFaire => (libelle: s.aFaire, ton: TonEtat.neutre),
    StatutAssignation.enCours => (libelle: s.enCours, ton: TonEtat.accent),
    StatutAssignation.fait => (libelle: s.fait, ton: TonEtat.succes),
    StatutAssignation.expire => (libelle: s.expire, ton: TonEtat.avertissement),
    // Jamais affiche (filtre par [travauxAffiches]) ; nomme pour l'exhaustivite.
    StatutAssignation.annule => (libelle: s.aFaire, ton: TonEtat.neutre),
  };
}

/// Le travail de la classe pour l'eleve, lu par la famille.
///
/// Leve `CapaciteIndisponible('LOT-C')` tant que la lecture famille n'est pas
/// branchee ([assignationsFamilleProvider]) : la source existe
/// (`learning_assignment`, lisible par le foyer), l'adaptateur manque.
final FutureProviderFamily<List<LearningAssignment>, CleEleveClasse>
travailClasseProvider =
    FutureProvider.family<List<LearningAssignment>, CleEleveClasse>((
      Ref ref,
      CleEleveClasse cle,
    ) async {
      final PortAssignations? port = ref.watch(assignationsFamilleProvider);
      if (port == null) {
        throw const CapaciteIndisponible('LOT-C');
      }
      return travauxAffiches(
        await port.pourGroupe(cle.classeId, studentId: cle.eleveId),
      );
    });

/// Le travail a preparer d'une classe (`/tuteur/classes/:classeId/travail`).
///
/// Meme composant que « Avant le prochain cours » de l'Accueil (cercles,
/// filets en retrait), **sans limite de trois** (manifeste, section 2) ; le
/// statut vient du service. Les cercles ne se touchent pas : coches seulement
/// quand le service dit « fait », aucune coche locale, marquer fait attend le
/// serveur (DB-CRS-10), et « fait » ne vaut pas competence acquise.
class TravailClassePage extends ConsumerWidget {
  /// Cree la page.
  const TravailClassePage({required this.classeId, super.key, this.eleveId});

  /// La classe concernee.
  final String classeId;

  /// L'eleve concerne, s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CadreClasse(
    cle: (classeId: classeId, eleveId: eleveId),
    titre: t.classe.travail,
    sousTitre: sousTitreSousPage,
    onRetour: () =>
        GoRouter.of(context).go(Routes.classePour(classeId, eleveId: eleveId)),
    construire: (ContexteClasse c) => _Travail(contexte: c),
  );
}

class _Travail extends ConsumerWidget {
  const _Travail({required this.contexte});

  final ContexteClasse contexte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CleEleveClasse cle = (
      classeId: contexte.classeId,
      eleveId: contexte.eleveId,
    );
    return LectureClasse<List<LearningAssignment>>(
      valeur: ref.watch(travailClasseProvider(cle)),
      phraseIndisponible: t.classe.pageTravail.indisponible,
      onReessayer: () => ref.invalidate(travailClasseProvider(cle)),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.classe.pageTravail.aucun,
        phrase: t.classe.pageTravail.aucunDetail,
      ),
      construire: (List<LearningAssignment> travaux) =>
          _Liste(travaux: travaux),
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.travaux});

  final List<LearningAssignment> travaux;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return ColonnesSousPage(
      principal: AppCard(
        marge: AppSpacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < travaux.length; i++)
              _Ligne(travail: travaux[i], filet: i < travaux.length - 1),
          ],
        ),
      ),
      precisions: Text(
        t.classe.pageTravail.nonCochable,
        style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
      ),
    );
  }
}

/// Un travail : cercle decoratif, consigne, echeance ; a droite, son statut.
/// Filet en retrait sous le texte, pas sous le cercle (V1, V2).
class _Ligne extends StatelessWidget {
  const _Ligne({required this.travail, required this.filet});

  final LearningAssignment travail;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ({String libelle, TonEtat ton}) statut = statutTravail(
      travail.status,
    );
    final DateTime? echeance = travail.dueAtUtc;
    final bool large = classeEnColonnes(context);
    // Le cercle dit le statut RENDU PAR LE SERVICE (fait : coche), jamais une
    // coche locale ; le mot de la pastille le double.
    final bool fait = travail.status == StatutAssignation.fait;
    return MergeSemantics(
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSpacing.xxl,
              child: fait
                  ? IconTheme(
                      data: palette.inkSuccess.asIconTheme(
                        size: AppSpacing.xxl,
                      ),
                      child: Icon(AppIcons.succes.actif),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          palette.borderStrong.asBorderSide(),
                        ),
                      ),
                    ),
            ),
          ),
          Ecart.hMd,
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: filet
                    ? Border(bottom: palette.contourCarte.asBorderSide())
                    : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppTouchTarget.standard,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              libelleTravail(travail),
                              style: palette.inkStrong.applyTo(
                                (large
                                        ? textes.bodyLarge
                                        : textes.bodyMedium) ??
                                    const TextStyle(),
                              ),
                            ),
                            if (echeance != null) ...<Widget>[
                              Ecart.vXs,
                              Text(
                                t.classe.pageTravail.echeance(
                                  date: dateDeLAppareil(echeance.toLocal()),
                                ),
                                style: palette.inkMuted.applyTo(
                                  (large
                                          ? textes.bodyMedium
                                          : textes.bodySmall) ??
                                      const TextStyle(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Ecart.hSm,
                      StatusPill(libelle: statut.libelle, ton: statut.ton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
