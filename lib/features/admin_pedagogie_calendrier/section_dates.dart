// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la section « Dates de l'ecole ».
// Liste, ajout, modification, publication et retrait de la publication. Une
// date publiee agit et se lit ; une fermeture publiee fait reculer la date
// limite de l'etape des eleves concernes et empeche la creation de nouvelles
// seances ces jours-la ; les seances deja creees ne sont pas supprimees
// (le serveur le dit, l'ecran aussi).

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
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

import 'feuille_detail_date.dart';
import 'feuille_saisie_date.dart';

/// La section des dates de l'ecole.
class SectionDates extends ConsumerWidget {
  /// Cree la section.
  const SectionDates({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portCalendrierDirectionProvider) == null) {
      return EmptyState(
        message: t.calendrier.indisponible,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }
    final AsyncValue<List<EvenementCalendrier>?> lecture = ref.watch(
      calendrierDirectionProvider,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.calendrier.dates.intro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('calendrier-ajouter'),
          libelle: t.calendrier.dates.ajouter,
          pleineLargeur: false,
          onPress: () => ouvrirSaisieDate(context, ref, null),
        ),
        Ecart.vXl,
        BlocAsynchrone<List<EvenementCalendrier>?>(
          valeur: lecture,
          squelette: const SqueletteDansZone(child: Skeleton.liste(lignes: 4)),
          titreEchec: t.calendrier.dates.erreur,
          onReessayer: () => ref.invalidate(calendrierDirectionProvider),
          estVide: (List<EvenementCalendrier>? l) => l == null || l.isEmpty,
          vide: EmptyState(
            message: t.calendrier.dates.videTitre,
            invitation: t.calendrier.dates.videDetail,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          construire: (List<EvenementCalendrier>? l) => CarteLignes(
            lignes: <Widget>[
              for (final EvenementCalendrier e
                  in l ?? const <EvenementCalendrier>[])
                _LigneDate(
                  key: ValueKey<String>('date-${e.id}'),
                  evenement: e,
                  onPress: () => ouvrirDetailDate(context, ref, e),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneDate extends StatelessWidget {
  const _LigneDate({required this.evenement, required this.onPress, super.key});

  final EvenementCalendrier evenement;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final EvenementCalendrier e = evenement;
    final List<String> lignes = <String>[
      '${libelleType(e.type)}, ${periodeEnMots(e.du, e.au)}',
      t.calendrier.dates.pour(cible: libelleCible(e)),
      if (e.type == TypeEvenement.fermeture && e.elevesVises != null)
        t.calendrier.dates.elevesVises(n: e.elevesVises!),
      if (e.type == TypeEvenement.fermeture && e.seancesNeutralisees != null)
        e.seancesNeutralisees! > 0
            ? t.calendrier.dates.seancesNeutralisees(n: e.seancesNeutralisees!)
            : t.calendrier.dates.aucuneSeance,
    ];
    return SettingRow(
      title: e.titre,
      description: lignes.join('\n'),
      controle: StatusPill(
        libelle: e.publie
            ? t.calendrier.dates.publiee
            : t.calendrier.dates.nonPubliee,
        ton: e.publie ? TonEtat.succes : TonEtat.neutre,
      ),
      onPress: onPress,
      libelleSemantique: e.titre,
    );
  }
}
