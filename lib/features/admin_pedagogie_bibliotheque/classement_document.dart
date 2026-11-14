/// Les champs de classement d'un document (BIBLIOTHEQUE-UNE, D1, D2, D3).
///
/// Posés une seule fois et partagés par « Ajouter un document » et la fiche :
/// les tranches d'âge auxquelles il s'adresse, les étapes du programme publié
/// (la direction coche, elle ne tape jamais un code), la lecture du Coran et
/// l'école juridique suivie. Aucun prix ni mot d'achat.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/tranche_age.dart';
import '../../core/tc_bibliotheque/etapes_programme.dart';
import '../../core/tc_bibliotheque/lecture_coran.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/case_a_cocher.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/zone_saisie.dart';

/// Vrai si l'école juridique suivie tient dans la limite de la base (80 caractères).
bool ecoleValide(String texte) => texte.trim().length <= 80;

/// Les tranches d'âge, dans l'ordre de l'académie (une seule liste, celle du
/// document).
const List<String> tranchesProposees = tranchesToutes;

/// Les tranches d'un document donné par un lien : toutes sauf les 6 à 9 ans,
/// qui se cochent explicitement (D1).
const Set<String> tranchesLienParDefaut = <String>{...tranchesParDefautLien};

/// Les quatre tranches.
const Set<String> tranchesTout = <String>{...tranchesToutes};

/// Les tranches d'âge d'un document : une case par tranche, toutes visibles.
class ChoixTranches extends StatelessWidget {
  /// Crée le choix. [lien] : le document est donné par un lien externe, la
  /// phrase dit pourquoi les 6 à 9 ans ne sont pas cochés d'emblée.
  const ChoixTranches({
    required this.choisies,
    required this.onChoix,
    this.lien = false,
    super.key,
  });

  /// Les codes cochés.
  final Set<String> choisies;

  /// Appelé avec le nouvel ensemble.
  final ValueChanged<Set<String>> onChoix;

  /// Vrai pour un lien externe.
  final bool lien;

  @override
  Widget build(BuildContext context) {
    final c = t.admin.bibliotheque.import.classement;
    return Column(
      key: const ValueKey<String>('classement-tranches'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(c.tranchesTitre, style: Theme.of(context).textTheme.titleSmall),
        Ecart.vXs,
        Text(lien ? c.tranchesAideLien : c.tranchesAide),
        for (final String code in tranchesProposees)
          LigneCase(
            cle: ValueKey<String>('classement-tranche-$code'),
            libelle: libelleTranche(code),
            coche: choisies.contains(code),
            onChange: (bool v) {
              final Set<String> suite = <String>{...choisies};
              if (v) {
                suite.add(code);
              } else {
                suite.remove(code);
              }
              onChoix(suite);
            },
          ),
        if (choisies.isEmpty)
          Text(
            c.tranchesAucune,
            key: const ValueKey<String>('classement-tranches-aucune'),
          ),
      ],
    );
  }
}

/// Les étapes du programme publié : des cases, jamais un code à taper. Tant
/// qu'aucun programme n'est publié, une phrase le dit.
class ChoixEtapes extends ConsumerStatefulWidget {
  /// Crée le choix.
  const ChoixEtapes({required this.choisies, required this.onChoix, super.key});

  /// Les codes d'étapes cochés.
  final Set<String> choisies;

  /// Appelé avec le nouvel ensemble.
  final ValueChanged<Set<String>> onChoix;

  @override
  ConsumerState<ChoixEtapes> createState() => _ChoixEtapesEtat();
}

class _ChoixEtapesEtat extends ConsumerState<ChoixEtapes> {
  List<EtapeProgramme>? _etapes;
  bool _echec = false;

  @override
  void initState() {
    super.initState();
    unawaited(_lire());
  }

  Future<void> _lire() async {
    try {
      final List<EtapeProgramme> e = await ref
          .read(portEtapesProgrammeProvider)
          .publiees();
      if (mounted) setState(() => _etapes = e);
    } on Object {
      if (mounted) setState(() => _echec = true);
    }
  }

  void _basculer(String code, bool coche) {
    final Set<String> suite = <String>{...widget.choisies};
    if (coche) {
      suite.add(code);
    } else {
      suite.remove(code);
    }
    widget.onChoix(suite);
  }

  @override
  Widget build(BuildContext context) {
    final c = t.admin.bibliotheque.import.classement;
    final List<EtapeProgramme>? etapes = _etapes;
    // Une étape déjà rattachée mais absente de la liste reste visible et
    // décochable : rien ne se perd en silence.
    final Set<String> connues = <String>{
      for (final EtapeProgramme e in etapes ?? const <EtapeProgramme>[]) e.code,
    };
    final List<String> orphelines = <String>[
      for (final String code in widget.choisies)
        if (!connues.contains(code)) code,
    ];
    return Column(
      key: const ValueKey<String>('classement-etapes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(c.etapesTitre, style: Theme.of(context).textTheme.titleSmall),
        Ecart.vXs,
        Text(c.etapesAide),
        if (_echec)
          Text(
            c.etapesIndisponible,
            key: const ValueKey<String>('classement-etapes-indisponible'),
          )
        else if (etapes != null && etapes.isEmpty && orphelines.isEmpty)
          Text(
            c.etapesVide,
            key: const ValueKey<String>('classement-etapes-vide'),
          ),
        for (final EtapeProgramme e in etapes ?? const <EtapeProgramme>[])
          LigneCase(
            cle: ValueKey<String>('classement-etape-${e.code}'),
            libelle: e.nom,
            precision: e.cycle.isEmpty ? null : e.cycle,
            coche: widget.choisies.contains(e.code),
            onChange: (bool v) => _basculer(e.code, v),
          ),
        for (final String code in orphelines)
          LigneCase(
            cle: ValueKey<String>('classement-etape-$code'),
            libelle: code,
            coche: true,
            onChange: (bool v) => _basculer(code, v),
          ),
      ],
    );
  }
}

/// La lecture du Coran (facultatif) et l'école juridique suivie (facultatif).
class ChampsLectureEcole extends StatelessWidget {
  /// Crée les champs. [ecole] : le texte libre de l'école juridique suivie.
  const ChampsLectureEcole({
    required this.lecture,
    required this.onLecture,
    required this.ecole,
    super.key,
  });

  /// La lecture retenue (`hafs`, `warsh`, `qalun`, `shuba`), ou `null`.
  final String? lecture;

  /// Appelé avec la lecture choisie (`null` : aucune).
  final ValueChanged<String?> onLecture;

  /// Le champ de l'école juridique suivie.
  final TextEditingController ecole;

  @override
  Widget build(BuildContext context) {
    final c = t.admin.bibliotheque.import.classement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Choix de formulaire, pas un filtre : la lecture se choisit parmi
        // celles des candidatures.
        MenuFiltre<String>(
          key: const ValueKey<String>('classement-lecture'),
          libelle: c.lectureTitre,
          valeur: lecture,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(valeur: null, libelle: c.lectureAucune),
            for (final String l in lecturesCoran)
              EntreeFiltre<String>(valeur: l, libelle: libelleLectureCoran(l)),
          ],
          onChoix: onLecture,
        ),
        Ecart.vMd,
        ListenableBuilder(
          listenable: ecole,
          builder: (BuildContext context, Widget? _) => ZoneSaisie(
            controleur: ecole,
            cleChamp: const ValueKey<String>('classement-ecole'),
            libelle: c.ecoleLibelle,
            maxLignes: 1,
            erreur: ecoleValide(ecole.text) ? null : c.ecoleTrop,
            actionClavier: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}

/// Une ligne de choix : la case du produit (`CaseACocher`, cible du mode,
/// anneau de focus, coche visible) et son libellé, lu une seule fois.
/// Une case a cocher et son libelle, sur une ligne.
class LigneCase extends StatelessWidget {
  /// Cree la ligne.
  const LigneCase({
    required this.cle,
    required this.libelle,
    required this.coche,
    required this.onChange,
    this.precision,
    super.key,
  });

  /// La cle de la case.
  final Key cle;

  /// Le libelle, lu avec la case.
  final String libelle;

  /// Une precision sous le libelle.
  final String? precision;

  /// Vrai quand la case est cochee.
  final bool coche;

  /// Appele au changement.
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        CaseACocher(
          key: cle,
          valeur: coche,
          libelle: libelle,
          onChange: onChange,
        ),
        Ecart.hSm,
        Expanded(
          // Le libellé est déjà porté par la case : il n'est pas lu deux fois.
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteSansCoupure(libelle, style: textes.bodyMedium),
                if (precision != null)
                  TexteSansCoupure(precision!, style: textes.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
