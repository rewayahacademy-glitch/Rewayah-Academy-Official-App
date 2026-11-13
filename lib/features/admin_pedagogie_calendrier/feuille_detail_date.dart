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
import '../../core/widgets/lien_fleche.dart';

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
      onModifier: () {
        Navigator.of(contexte).pop();
        ouvrirSaisieDate(context, ref, e);
      },
    ),
  );
}

class _FeuilleDetail extends ConsumerStatefulWidget {
  const _FeuilleDetail({required this.evenement, required this.onModifier});

  final EvenementCalendrier evenement;
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
        if (fermeture && e.seancesDejaPrevues != null) ...<Widget>[
          Ecart.vSm,
          Text(
            e.seancesDejaPrevues! > 0
                ? t.calendrier.dates.seancesDejaPrevues(
                    n: e.seancesDejaPrevues!,
                  )
                : t.calendrier.dates.aucuneSeance,
            style: textes.bodyMedium,
          ),
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
        if (e.publie)
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
