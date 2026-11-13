// CALENDRIER-ET-PAUSES (lot 2, revue du 13/11, B-B) : retirer une fermeture est
// refuse tant qu'une seance mise de cote ne peut pas etre retablie (l'enseignant
// a pris un autre cours a sa place). La direction lit la liste des conflits
// (classe, jour, heure de La Mecque, enseignant, l'autre cours), puis libere
// l'enseignant et reessaie, ou confirme explicitement « retirer la fermeture et
// abandonner ces seances » : un geste trace au journal, jamais en silence.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';

/// Ouvre la liste des conflits d'un retrait refuse.
void ouvrirConflitsRetrait(
  BuildContext context,
  WidgetRef ref,
  EvenementCalendrier e,
) {
  ref.invalidate(retraitConflitsProvider(e.id));
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.calendrier.dates.conflits.titre,
    constructeur: (BuildContext _) => _FeuilleConflits(evenement: e),
  );
}

class _FeuilleConflits extends ConsumerStatefulWidget {
  const _FeuilleConflits({required this.evenement});

  final EvenementCalendrier evenement;

  @override
  ConsumerState<_FeuilleConflits> createState() => _FeuilleConflitsEtat();
}

class _FeuilleConflitsEtat extends ConsumerState<_FeuilleConflits> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _abandonner(int nombre) async {
    final PortCalendrierDirection? port = ref.read(
      portCalendrierDirectionProvider,
    );
    if (port == null) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.retirer(widget.evenement.id, abandonner: nombre);
      ref.invalidate(calendrierDirectionProvider);
      if (mounted) Navigator.of(context).pop();
    } on CalendrierRefuse catch (r) {
      // Le nombre a change depuis la lecture : on relit la liste avant de confirmer.
      ref.invalidate(retraitConflitsProvider(widget.evenement.id));
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
    final AsyncValue<ConflitsRetrait?> lecture = ref.watch(
      retraitConflitsProvider(widget.evenement.id),
    );
    final c = t.calendrier.dates.conflits;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(c.intro, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<ConflitsRetrait?>(
          valeur: lecture,
          squelette: const Skeleton.liste(lignes: 3),
          titreEchec: t.calendrier.dates.concernees.erreur,
          onReessayer: () =>
              ref.invalidate(retraitConflitsProvider(widget.evenement.id)),
          estVide: (ConflitsRetrait? l) => l == null || l.nombre == 0,
          vide: EmptyState(
            message: t.calendrier.dates.aucuneSeance,
            icone: AppIcons.rienAAfficher,
            registre: RegistreVide.subi,
          ),
          construire: (ConflitsRetrait? l) => _Corps(
            conflits: l!,
            erreur: _erreur,
            envoi: _envoi,
            onAbandonner: () => _abandonner(l.nombre),
          ),
        ),
      ],
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.conflits,
    required this.erreur,
    required this.envoi,
    required this.onAbandonner,
  });

  final ConflitsRetrait conflits;
  final String? erreur;
  final bool envoi;
  final VoidCallback onAbandonner;

  @override
  Widget build(BuildContext context) {
    final c = t.calendrier.dates.conflits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarteLignes(
          lignes: <Widget>[
            for (final ConflitRetrait x in conflits.conflits)
              SettingRow(
                title: c.ligne(
                  classe: x.classe,
                  quand: jourHeureEnMots(x.jour, x.heure),
                  enseignant: x.enseignant,
                ),
                description: x.autreJour == null || x.autreHeure == null
                    ? null
                    : (x.autreClasse ?? '').isEmpty
                    ? c.autreSansNom(
                        quand: jourHeureEnMots(x.autreJour!, x.autreHeure!),
                      )
                    : c.autre(
                        cours: x.autreClasse!,
                        quand: jourHeureEnMots(x.autreJour!, x.autreHeure!),
                      ),
              ),
          ],
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('calendrier-abandonner'),
          libelle: c.abandonner(n: conflits.nombre),
          enCours: envoi,
          onPress: onAbandonner,
        ),
      ],
    );
  }
}
