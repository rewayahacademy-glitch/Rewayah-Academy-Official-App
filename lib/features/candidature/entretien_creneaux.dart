/// SALLE-2-ENTRETIEN : le choix d'un moment d'entretien par le candidat, puis
/// sa reservation (`reserver_creneau_entretien`, V1-b). Le serveur decide :
/// un moment pris entre-temps, une candidature changee, un entretien deja
/// fixe sont dits tels quels, et rien n'est presume.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/entretien_candidat.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/skeleton.dart';

/// L'horaire d'un moment, heure de l'appareil : « Lundi 10 novembre, de
/// 18:00 a 18:45 ».
String horaireEntretien(DateTime debut, DateTime fin) =>
    t.recrutement.entretien.horaire(
      date: dateDeLAppareil(debut),
      debut: heureDeLAppareil(debut),
      fin: heureDeLAppareil(fin),
    );

/// Les moments ouverts, un choix, puis « Reserver ce moment ».
class ChoixCreneauEntretien extends ConsumerStatefulWidget {
  /// Cree le choix.
  const ChoixCreneauEntretien({required this.candidature, super.key});

  /// La candidature lue dans le dossier (sa version part avec la reservation).
  final CandidatureDossier candidature;

  /// La liste des moments.
  static const Key listeKey = ValueKey<String>('entretien-creneaux');

  /// Le bouton de reservation.
  static const Key reserverKey = ValueKey<String>('entretien-reserver');

  /// L'etat « aucun moment ouvert ».
  static const Key aucunKey = ValueKey<String>('entretien-aucun-creneau');

  /// L'etat d'erreur de lecture.
  static const Key erreurKey = ValueKey<String>('entretien-erreur-lecture');

  @override
  ConsumerState<ChoixCreneauEntretien> createState() => _ChoixEtat();
}

class _ChoixEtat extends ConsumerState<ChoixCreneauEntretien> {
  String? _choisi;
  bool _envoi = false;
  String? _message;

  /// La cle d'idempotence d'une reservation : la meme tant que le choix ne
  /// change pas, pour qu'un second appui ne reserve pas deux fois.
  String? _cle;

  Future<void> _reserver() async {
    final String? choisi = _choisi;
    if (choisi == null) return;
    _cle ??= 'entretien-$choisi-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _envoi = true;
      _message = null;
    });
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    try {
      final IssueReservation issue = await ref
          .read(portEntretienCandidatProvider)
          .reserver(
            creneau: choisi,
            version: widget.candidature.version,
            cle: _cle!,
          );
      if (!mounted) return;
      final RefusReservation? refus = issue.refus;
      if (refus == null) {
        ref
          ..invalidate(monEntretienProvider)
          ..invalidate(creneauxOuvertsProvider)
          ..invalidate(etatDossierProvider);
        return;
      }
      setState(() {
        _message = switch (refus) {
          RefusReservation.creneauIndisponible => t.recrutement.entretien.pris,
          RefusReservation.dejaPlanifie => t.recrutement.entretien.dejaPlanifie,
          RefusReservation.versionPerimee => t.recrutement.entretien.perime,
          RefusReservation.autre => t.recrutement.entretien.erreurReservation,
        };
        if (refus == RefusReservation.creneauIndisponible) {
          _choisi = null;
          _cle = null;
          ref.invalidate(creneauxOuvertsProvider);
        }
        if (refus == RefusReservation.dejaPlanifie) {
          ref.invalidate(monEntretienProvider);
        }
      });
    } on Object {
      if (!mounted) return;
      setState(
        () => _message = horsLigne
            ? t.contrat.horsLigne
            : t.recrutement.entretien.erreurReservation,
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<CreneauOuvert>> lecture = lectureHorsLigne(
      ref.watch(creneauxOuvertsProvider),
      horsLigne: horsLigne,
    );
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    void relire() => ref.invalidate(creneauxOuvertsProvider);

    if (!lecture.hasValue) {
      if (lecture.hasError) {
        return sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
            ? EtatSansDonnees(
                key: ChoixCreneauEntretien.erreurKey,
                quoi: t.recrutement.entretien.erreurLecture,
                onAction: relire,
              )
            : EtatSysteme(
                key: ChoixCreneauEntretien.erreurKey,
                nature: NatureEtat.echecServeur,
                phrase: t.recrutement.entretien.erreurLecture,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              );
      }
      return const Skeleton.liste(lignes: 4);
    }
    final List<CreneauOuvert> creneaux = lecture.requireValue;
    if (creneaux.isEmpty) {
      return EtatSysteme(
        key: ChoixCreneauEntretien.aucunKey,
        nature: NatureEtat.aucunResultat,
        phrase: t.recrutement.entretien.aucunCreneau,
        libelleAction: t.commun.reessayer,
        onAction: relire,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          key: ChoixCreneauEntretien.listeKey,
          titre: t.recrutement.entretien.heureAppareil,
          lignes: <LigneRubrique>[
            for (final CreneauOuvert c in creneaux)
              LigneRubrique(
                icone: AppIcons.horloge,
                libelle: horaireEntretien(c.debut, c.fin),
                selectionnee: _choisi == c.id,
                cochee: _choisi == c.id,
                onPress: _envoi
                    ? null
                    : () => setState(() {
                        if (_choisi != c.id) _cle = null;
                        _choisi = c.id;
                        _message = null;
                      }),
              ),
          ],
        ),
        if (_message != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: palette.inkAlert.applyTo(corps)),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: ChoixCreneauEntretien.reserverKey,
          libelle: t.recrutement.entretien.reserver,
          enCours: _envoi,
          onPress: _choisi == null || _envoi
              ? null
              : () => unawaited(_reserver()),
        ),
      ],
    );
  }
}
