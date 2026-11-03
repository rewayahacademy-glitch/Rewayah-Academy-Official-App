/// D1-ter (03/11/2026) : la carte « Messages de l'académie sur `prénom` », en
/// tete de l'Historique du tuteur pour l'enfant choisi, et « Messages de
/// l'académie » dans le Suivi de l'eleve adulte (emplacement propose, SM-51).
///
/// Ce que la direction a transmis apres le signalement d'un enseignant : le
/// message ecrit pour la famille, sa nature et sa date, jamais la note
/// interne (le modele ne la porte pas), jamais la securite d'un enfant (le
/// serveur l'exclut). La carte n'est posee que s'il y a au moins un message ;
/// jamais en Interface guidee (le resume est ecrit pour la famille, pas pour
/// l'enfant) ; jamais sans port. Une lecture en echec le dit, avec
/// « Reessayer » (K-59) ; pendant la lecture, rien ne bouge la page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/suivi/port_messages_academie.dart';
import '../../core/tc_parcours/libelles_parcours.dart';
import '../../core/tc_parcours/student_concern.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import 'filtres_historique.dart' show dateLongueHistorique;

/// La carte, ou rien.
class CarteMessagesAcademie extends ConsumerWidget {
  /// Cree la carte pour [eleveId] et [prenom] (le tuteur, l'enfant choisi),
  /// ou, sans eux, pour l'eleve adulte qui lit ses propres messages.
  const CarteMessagesAcademie({this.eleveId, this.prenom, super.key});

  /// L'eleve concerne ; nul : les messages de la personne connectee.
  final String? eleveId;

  /// Le prenom de l'enfant, ou nul quand l'eleve lit pour lui-meme.
  final String? prenom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Interface guidee : jamais de carte, quel que soit le compte.
    if (AppMetriques.of(context).estEnfant) return const SizedBox.shrink();
    final m = t.d1ter.messages;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<ResumeFamilleSignalement>?> lecture = ref.watch(
      messagesAcademieProvider(eleveId),
    );
    if (lecture.hasError && !lecture.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: EtatSysteme(
          key: const ValueKey<String>('messages-academie-erreur'),
          nature: NatureEtat.echecServeur,
          phrase: m.erreur,
          onAction: () => ref.invalidate(messagesAcademieProvider(eleveId)),
        ),
      );
    }
    final List<ResumeFamilleSignalement> messages =
        lecture.value ?? const <ResumeFamilleSignalement>[];
    if (messages.isEmpty) return const SizedBox.shrink();
    final String? p = prenom;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        key: const ValueKey<String>('messages-academie'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(
            titre: p == null ? m.titreSoi : m.titre(prenom: p),
            compteur: messages.length,
          ),
          Ecart.vXs,
          TexteSansCoupure(
            p == null ? m.introSoi : m.intro(prenom: p),
            style: textes.bodyMedium,
          ),
          Ecart.vMd,
          CarteLignes(
            lignes: <Widget>[
              for (final ResumeFamilleSignalement r in messages)
                SettingRow(
                  key: ValueKey<String>('message-academie-${r.concernId}'),
                  title: libelleCategorieSignalement(r.categorie),
                  description: <String>[
                    if (r.transmisLeUtc case final DateTime le)
                      m.transmisLe(date: dateLongueHistorique(le.toLocal())),
                    r.message,
                  ].join('\n'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
