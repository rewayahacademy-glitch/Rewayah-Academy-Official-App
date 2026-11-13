// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : le detail d'une date du
// calendrier : ce qu'elle change, puis publier ou retirer de la publication,
// ou la modifier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';

import 'feuille_conflits_retrait.dart';
import 'feuille_saisie_date.dart';

// ---------------------------------------------------------------------------

/// Ouvre le detail d'une date : publier, retirer, modifier.
void ouvrirDetailDate(
  BuildContext context,
  WidgetRef ref,
  EvenementCalendrier e,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: e.titre,
    constructeur: (BuildContext contexte) => _FeuilleDetail(
      evenement: e,
      racine: context,
      onModifier: () {
        Navigator.of(contexte).pop();
        ouvrirSaisieDate(context, ref, e);
      },
    ),
  );
}

class _FeuilleDetail extends ConsumerStatefulWidget {
  const _FeuilleDetail({
    required this.evenement,
    required this.racine,
    required this.onModifier,
  });

  final EvenementCalendrier evenement;

  /// Le contexte de la page, pour ouvrir la liste des conflits apres la fermeture
  /// de cette feuille.
  final BuildContext racine;
  final VoidCallback onModifier;

  @override
  ConsumerState<_FeuilleDetail> createState() => _FeuilleDetailEtat();
}

class _FeuilleDetailEtat extends ConsumerState<_FeuilleDetail> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _publier(bool publie) async {
    final PortCalendrierDirection? port = ref.read(
      portCalendrierDirectionProvider,
    );
    if (port == null) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.publier(widget.evenement.id, publie: publie);
      ref.invalidate(calendrierDirectionProvider);
      if (mounted) Navigator.of(context).pop();
    } on CalendrierRefuse catch (r) {
      if (r.motif == MotifRefusCalendrier.retraitConflits &&
          mounted &&
          widget.racine.mounted) {
        // Le retrait est refuse : la direction lit les conflits et decide.
        Navigator.of(context).pop();
        ouvrirConflitsRetrait(widget.racine, ref, widget.evenement);
        return;
      }
      if (mounted) setState(() => _erreur = messageRefusCalendrier(r.motif));
    } on Object {
      if (mounted) {
        setState(
          () => _erreur = messageRefusCalendrier(MotifRefusCalendrier.inconnu),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EvenementCalendrier e = widget.evenement;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool fermeture = e.type == TypeEvenement.fermeture;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${libelleType(e.type)}, ${periodeEnMots(e.du, e.au)}',
          style: textes.bodyMedium,
        ),
        Ecart.vSm,
        Text(
          t.calendrier.dates.pour(cible: libelleCible(e)),
          style: textes.bodyMedium,
        ),
        if (fermeture && e.elevesVises != null) ...<Widget>[
          Ecart.vSm,
          Text(
            t.calendrier.dates.elevesVises(n: e.elevesVises!),
            style: textes.bodyMedium,
          ),
        ],
        if (fermeture && e.seancesNeutralisees != null) ...<Widget>[
          Ecart.vSm,
          Text(
            e.seancesNeutralisees! > 0
                ? t.calendrier.dates.seancesNeutralisees(
                    n: e.seancesNeutralisees!,
                  )
                : t.calendrier.dates.aucuneSeance,
            style: textes.bodyMedium,
          ),
        ],
        if (fermeture) ...<Widget>[Ecart.vMd, _SeancesConcernees(id: e.id)],
        // Une fermeture commencee ne se retire plus : la phrase le dit, le bouton
        // qui ne peut pas aboutir n'est pas rendu.
        if (fermeture && e.publie && e.commencee) ...<Widget>[
          Ecart.vSm,
          Text(t.calendrier.dates.commencee, style: textes.bodyMedium),
        ],
        // Une consequence se dit avant le geste (K-58).
        if (fermeture && !e.publie) ...<Widget>[
          Ecart.vLg,
          Text(t.calendrier.dates.publication.phrase, style: textes.bodyMedium),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        if (e.publie && fermeture && e.commencee)
          const SizedBox.shrink()
        else if (e.publie)
          ActionPrincipale(
            key: const ValueKey<String>('calendrier-retirer'),
            libelle: t.calendrier.dates.retirer,
            niveau: NiveauAction.secondaire,
            enCours: _envoi,
            onPress: () => _publier(false),
          )
        else
          ActionPrincipale(
            key: const ValueKey<String>('calendrier-publier'),
            libelle: fermeture
                ? t.calendrier.dates.publication.confirmer
                : t.calendrier.dates.publier,
            enCours: _envoi,
            onPress: () => _publier(true),
          ),
        Ecart.vMd,
        LienFleche(
          libelle: t.calendrier.dates.modifier,
          onPress: widget.onModifier,
          alignerEnFin: true,
        ),
      ],
    );
  }
}

/// Les seances reellement concernees (au plus six lignes), avec leur jour et leur
/// heure de La Mecque : la direction les lit AVANT de publier.
class _SeancesConcernees extends ConsumerWidget {
  const _SeancesConcernees({required this.id});

  final String id;

  static const int _lignes = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = t.calendrier.dates.concernees;
    final AsyncValue<ApercuSeances?> lecture = ref.watch(
      seancesConcerneesProvider(id),
    );
    final TextTheme textes = Theme.of(context).textTheme;
    return BlocAsynchrone<ApercuSeances?>(
      valeur: lecture,
      squelette: const Skeleton.liste(lignes: 2),
      titreEchec: c.erreur,
      onReessayer: () => ref.invalidate(seancesConcerneesProvider(id)),
      estVide: (ApercuSeances? a) => a == null || a.total == 0,
      vide: const SizedBox.shrink(),
      construire: (ApercuSeances? a) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(c.titre, style: textes.titleSmall),
          Ecart.vSm,
          for (final SeanceConcernee s in a!.seances.take(_lignes)) ...<Widget>[
            Text(
              s.deCote
                  ? '${c.ligne(classe: s.classe, quand: jourHeureEnMots(s.jour, s.heure), enseignant: s.enseignant)} (${c.deCote})'
                  : c.ligne(
                      classe: s.classe,
                      quand: jourHeureEnMots(s.jour, s.heure),
                      enseignant: s.enseignant,
                    ),
              style: textes.bodyMedium,
            ),
            Ecart.vXs,
          ],
          if (a.total > _lignes)
            Text(c.autres(n: a.total - _lignes), style: textes.bodyMedium),
          Text(c.heureMecque, style: textes.bodySmall),
        ],
      ),
    );
  }
}
