/// SNT (03/11/2026) : la section « Séances reportées » du planning de la
/// direction, en tete de page (un geste attendu va en tete, avant le reste).
///
/// Une ligne par seance reportee sans nouvelle date : la classe, la seance
/// non tenue, l'enseignant. Toucher la ligne ouvre « Fixer la nouvelle date ».
/// Rien n'est montre sans port, pendant la premiere lecture, ni quand aucune
/// seance n'est reportee : la section n'apparait que s'il y a un geste a
/// faire. Une lecture en echec le dit, avec « Reessayer » (K-59).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_seances_reportees.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import 'feuille_nouvelle_date.dart';
import 'planning_libelles.dart';

/// La section, ou rien.
class SectionSeancesReportees extends ConsumerWidget {
  /// Cree la section.
  const SectionSeancesReportees({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.snt.planning;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<SeanceReportee>?> lecture = ref.watch(
      seancesReporteesProvider,
    );
    if (lecture.hasError && !lecture.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: EtatSysteme(
          key: const ValueKey<String>('seances-reportees-erreur'),
          nature: NatureEtat.echecServeur,
          phrase: p.erreurLecture,
          onAction: () => ref.invalidate(seancesReporteesProvider),
        ),
      );
    }
    final List<SeanceReportee> seances =
        lecture.value ?? const <SeanceReportee>[];
    if (seances.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        key: const ValueKey<String>('seances-reportees'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: p.section, compteur: seances.length),
          Ecart.vXs,
          TexteSansCoupure(p.intro, style: textes.bodyMedium),
          Ecart.vMd,
          CarteLignes(
            lignes: <Widget>[
              for (final SeanceReportee s in seances)
                SettingRow(
                  key: ValueKey<String>('seance-reportee-${s.id}'),
                  title: p.ligne(classe: s.classe),
                  description: <String>[
                    p.ligneQuand(quand: quandSeanceReportee(s.debut)),
                    libelleEnseignantPlanning(s.enseignant),
                    p.fixer,
                  ].join('\n'),
                  lien: true,
                  onPress: () => ouvrirNouvelleDate(context, s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
