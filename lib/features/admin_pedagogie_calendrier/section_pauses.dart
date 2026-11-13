// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la section « Pauses » de la
// direction. Les demandes au-dela du plafond (deux mois sur douze) qu'elle
// accepte ou refuse, les decisions recentes, et la pause d'exception (maladie
// soudaine, interruption accordee : motif, date de fin, son nom). Une demande
// dans la regle est acceptee seule par le serveur et n'apparait pas ici.
// Pedagogie seulement : la date limite recule, la place est gardee ; rien
// d'argent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/chargement_avec_delais.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

import 'feuille_decision_pause.dart';
import 'feuille_exception_pause.dart';

/// La section des pauses.
class SectionPauses extends ConsumerWidget {
  /// Cree la section.
  const SectionPauses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portPausesProvider) == null) {
      return EmptyState(
        message: t.calendrier.indisponible,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }
    final AsyncValue<FilePauses?> lecture = ref.watch(filePausesProvider);
    final p = t.calendrier.pauses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(p.aTraiterIntro, style: Theme.of(context).textTheme.bodyMedium),
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('pause-exception'),
          libelle: p.exceptionAction,
          pleineLargeur: false,
          niveau: NiveauAction.secondaire,
          onPress: () => ouvrirExceptionPause(context, ref),
        ),
        Ecart.vXl,
        BlocAsynchrone<FilePauses?>(
          valeur: lecture,
          squelette: const SqueletteDansZone(child: Skeleton.liste(lignes: 4)),
          titreEchec: p.erreur,
          onReessayer: () => ref.invalidate(filePausesProvider),
          estVide: (FilePauses? f) => f == null,
          vide: EmptyState(
            message: p.videTitre,
            invitation: p.videDetail,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          construire: (FilePauses? f) => _Corps(file: f!),
        ),
      ],
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({required this.file});

  final FilePauses file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.calendrier.pauses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: p.aTraiter, compteur: file.aTraiter.length),
        Ecart.vMd,
        if (file.aTraiter.isEmpty)
          EmptyState(
            message: p.videTitre,
            invitation: p.videDetail,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          )
        else
          CarteLignes(
            lignes: <Widget>[
              for (final DemandePauseDirection d in file.aTraiter)
                SettingRow(
                  key: ValueKey<String>('demande-${d.id}'),
                  title: d.eleveNom,
                  description: <String>[
                    p.ligneDescription(
                      mois: moisEnMots(d.debut),
                      n: d.moisAccordes,
                    ),
                    if (d.repondreAvant != null)
                      p.repondreAvant(date: jourEnMots(d.repondreAvant!)),
                  ].join('\n'),
                  controle: d.enRetard
                      ? StatusPill(
                          libelle: p.enRetard,
                          ton: TonEtat.avertissement,
                        )
                      : null,
                  onPress: () => ouvrirDecisionPause(context, ref, d),
                ),
            ],
          ),
        Ecart.vXl,
        SectionHeader(titre: p.decisionsRecentes),
        Ecart.vMd,
        if (file.recentes.isEmpty)
          Text(p.decisionsVide, style: Theme.of(context).textTheme.bodyMedium)
        else
          CarteLignes(
            lignes: <Widget>[
              for (final DecisionPause d in file.recentes)
                SettingRow(
                  key: ValueKey<String>('decision-${d.id}'),
                  title: d.eleveNom,
                  description: <String>[
                    '${d.type == TypePause.mois ? p.typeMois : p.typeException}, '
                        '${p.periode(du: jourEnMots(d.debut), au: jourEnMots(d.fin))}',
                    if ((d.decideeParNom ?? '').isNotEmpty)
                      p.accordeePar(nom: d.decideeParNom!),
                    if ((d.motif ?? '').isNotEmpty)
                      p.motifLigne(motif: d.motif!),
                    if ((d.motifDecision ?? '').isNotEmpty)
                      p.motifLigne(motif: d.motifDecision!),
                  ].join('\n'),
                  controle: StatusPill(
                    libelle: libelleStatutPause(d.statut, famille: false),
                    ton: switch (d.statut) {
                      StatutPause.acceptee => TonEtat.succes,
                      StatutPause.refusee => TonEtat.alerte,
                      StatutPause.annulee => TonEtat.neutre,
                      StatutPause.demandee => TonEtat.avertissement,
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
