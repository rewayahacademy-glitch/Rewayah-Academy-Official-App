/// SNT (03/11/2026) : la feuille « Fixer la nouvelle date » de la direction,
/// ouverte depuis une ligne de la section « Séances reportées » du planning.
///
/// Decision du directeur du 03/11 : une seance ou aucun enseignant n'a
/// rejoint la salle a T+30 est reportee, puis tenue avec l'enseignant de la
/// classe. La direction choisit le jour (calendrier, jamais une date a taper)
/// et l'heure (menu) ; le serveur cree la seance avec le meme enseignant et la
/// meme duree, refuse un chevauchement de l'enseignant (refus nomme de C1) et
/// previent la classe.
///
/// Champs (K-57) : la classe, l'enseignant et la duree sont deduits (la
/// seance reportee) ; le jour et l'heure sont choisis ; rien n'est saisi.
/// Etats : saisie, envoi (`BasDeFeuille`), hors ligne (`BasDeFeuille`), refus
/// en phrase (K-59), confirmation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_planning_direction.dart';
import '../../core/admin/port_seances_reportees.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/menu_filtre.dart';
import '../admin_groupes/bas_de_feuille.dart';
import '../admin_groupes/refus_creation_classe_libelles.dart' show quandConflit;
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute;
import 'planning_libelles.dart';

/// Ouvre la feuille pour [seance].
void ouvrirNouvelleDate(BuildContext context, SeanceReportee seance) {
  unawaited(
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.snt.planning.feuilleTitre,
      constructeur: (BuildContext _) => FeuilleNouvelleDate(seance: seance),
    ),
  );
}

/// La phrase d'un refus du serveur (K-59 : ce qui bloque, quoi faire).
String phraseRefusNouvelleDate(NouvelleDateRefusee refus) {
  final p = t.snt.planning;
  return switch (refus.motif) {
    MotifNouvelleDateRefusee.chevauchement => switch (refus.conflit) {
      null => p.refusChevauchement,
      final c when c.classe != null => p.refusChevauchementNomme(
        classe: c.classe!,
        quand: quandConflit(c),
      ),
      final c => p.refusChevauchementDate(quand: quandConflit(c)),
    },
    MotifNouvelleDateRefusee.datePassee => p.refusDatePassee,
    MotifNouvelleDateRefusee.dejaFixee => p.refusDejaFixee,
    MotifNouvelleDateRefusee.classeClose => p.refusClasseClose,
    MotifNouvelleDateRefusee.nonAutorisee => p.refusNonAutorisee,
    MotifNouvelleDateRefusee.inconnu => p.erreur,
  };
}

/// « lundi 12 octobre 2026 à 18 h » : un instant, a l'heure de l'appareil.
String quandSeanceReportee(DateTime instant) {
  final DateTime local = instant.toLocal();
  return t.snt.planning.quand(
    jour: libelleJour(local),
    heure: libelleHeure(local),
  );
}

/// Le contenu de la feuille.
class FeuilleNouvelleDate extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleNouvelleDate({required this.seance, super.key});

  /// La seance reportee.
  final SeanceReportee seance;

  @override
  ConsumerState<FeuilleNouvelleDate> createState() =>
      _FeuilleNouvelleDateEtat();
}

class _FeuilleNouvelleDateEtat extends ConsumerState<FeuilleNouvelleDate> {
  /// Les heures proposees, par demi-heure, en minutes depuis minuit.
  static const int _pas = 30;

  DateTime? _jour;
  int? _minutes;
  bool _envoi = false;
  String? _message;
  DateTime? _fixee;

  Future<void> _fixer() async {
    final p = t.snt.planning;
    final DateTime? jour = _jour;
    final int? minutes = _minutes;
    final PortSeancesReportees? port = ref.read(portSeancesReporteesProvider);
    if (jour == null || minutes == null) {
      setState(() => _message = p.choixManquant);
      return;
    }
    if (port == null) {
      setState(() => _message = p.erreur);
      return;
    }
    final DateTime debut = DateTime(
      jour.year,
      jour.month,
      jour.day,
      minutes ~/ 60,
      minutes % 60,
    );
    setState(() {
      _envoi = true;
      _message = null;
    });
    String? message;
    try {
      await port.fixer(reportId: widget.seance.id, debut: debut);
    } on NouvelleDateRefusee catch (refus) {
      message = phraseRefusNouvelleDate(refus);
    } on Object {
      message = p.erreur;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _message = message;
      if (message == null) _fixee = debut;
    });
    if (message == null) {
      // La section et le planning relisent ce que le serveur a retenu.
      ref
        ..invalidate(seancesReporteesProvider)
        ..invalidate(planningSemaineProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.snt.planning;
    final SeanceReportee s = widget.seance;
    if (_fixee case final DateTime fixee) {
      return Semantics(
        liveRegion: true,
        child: TexteSansCoupure(
          p.fixee(quand: quandSeanceReportee(fixee)),
          key: const ValueKey<String>('nouvelle-date-fixee'),
          style: textes.titleMedium,
        ),
      );
    }
    final DateTime aujourdhui = ref.watch(horlogeFormulairesProvider)();
    return Column(
      key: const ValueKey<String>('feuille-nouvelle-date'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          p.feuilleSeance(
            classe: s.classe,
            quand: quandSeanceReportee(s.debut),
          ),
          style: textes.titleSmall,
        ),
        Ecart.vXs,
        TexteSansCoupure(
          s.enseignant.isEmpty
              ? p.feuilleContexteSansNom(minutes: '${s.duree.inMinutes}')
              : p.feuilleContexte(
                  enseignant: s.enseignant,
                  minutes: '${s.duree.inMinutes}',
                ),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        ChampDate(
          key: const ValueKey<String>('nouvelle-date-jour'),
          libelle: p.jour,
          valeur: _jour,
          aujourdhui: aujourdhui,
          onChoix: (DateTime j) => setState(() {
            _jour = j;
            _message = null;
          }),
        ),
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('nouvelle-date-heure'),
            libelle: p.heure,
            valeur: _minutes,
            entrees: <EntreeFiltre<int>>[
              for (int m = 0; m < 24 * 60; m += _pas)
                EntreeFiltre<int>(
                  valeur: m,
                  libelle: libelleHeureMinute(m ~/ 60, m % 60),
                ),
            ],
            onChoix: (int? m) => setState(() {
              _minutes = m;
              _message = null;
            }),
          ),
        ),
        Ecart.vXs,
        TexteSansCoupure(p.heureAppareil, style: textes.bodySmall),
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(
            message,
            key: const ValueKey<String>('nouvelle-date-message'),
          ),
        ],
        Ecart.vXxl,
        BasDeFeuille(
          key: const ValueKey<String>('nouvelle-date-confirmer'),
          libelle: p.confirmer,
          enCours: _envoi,
          horsLigne: p.horsLigne,
          onPress: () => unawaited(_fixer()),
        ),
      ],
    );
  }
}
