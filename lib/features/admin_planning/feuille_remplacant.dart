/// La feuille « Remplaçant pour la séance de … » de la direction (R12,
/// `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`), ouverte depuis le menu d'une
/// seance du planning.
///
/// Le serveur decide de tout : il ne propose que les enseignants libres a
/// l'heure exacte de la seance (regle stricte), et dit pour chacun si son
/// genre convient a la classe. Un enseignant de l'autre genre reste visible et
/// choisissable (le genre est souple), mais son choix est explicite : une
/// phrase le dit avant le bouton, le bouton le nomme, et le serveur le trace.
///
/// Etats : chargement, liste (`SelecteurPersonne` : squelette, vide, echec
/// avec « Reessayer »), refus du serveur en phrase (K-59), hors ligne par
/// `BasDeFeuille`, confirmation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_planning_direction.dart';
import '../../core/admin/port_remplacements_direction.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/selecteur_personne.dart';
import '../admin_groupes/bas_de_feuille.dart';
import 'planning_libelles.dart';

/// Ouvre la feuille de designation pour [seance].
void ouvrirDesignationRemplacant(
  BuildContext context,
  WidgetRef ref,
  SeancePlanning seance,
) {
  unawaited(
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.planning.remplacement.titre(
        deClasse: deDevant(seance.classe),
      ),
      constructeur: (BuildContext _) => FeuilleRemplacant(seance: seance),
    ),
  );
}

/// Le contenu de la feuille.
class FeuilleRemplacant extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRemplacant({required this.seance, super.key});

  /// La seance a remplacer.
  final SeancePlanning seance;

  @override
  ConsumerState<FeuilleRemplacant> createState() => _FeuilleRemplacantEtat();
}

class _FeuilleRemplacantEtat extends ConsumerState<FeuilleRemplacant> {
  String? _choisie;
  bool _envoi = false;
  String? _message;
  String? _designe;

  Future<void> _designer(List<RemplacantPossible> possibles) async {
    final r = t.admin.planning.remplacement;
    final RemplacantPossible? choisi = possibles
        .where((RemplacantPossible p) => p.id == _choisie)
        .firstOrNull;
    final PortRemplacementsDirection? port = ref.read(
      portRemplacementsDirectionProvider,
    );
    if (choisi == null || port == null) {
      setState(() => _message = r.choixManquant);
      return;
    }
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatDesignation? resultat;
    try {
      resultat = await port.designer(
        seanceId: widget.seance.id,
        remplacantId: choisi.id,
        horsGenre: !choisi.genreCompatible,
      );
    } on Object {
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case ResultatDesignation.designe:
          _designe = choisi.nom;
        case ResultatDesignation.occupe:
          _message = r.refusOccupe;
          _choisie = null;
        case ResultatDesignation.incompatible:
          _message = r.refusIncompatible;
          _choisie = null;
        case ResultatDesignation.dejaPris:
          _message = r.refusDejaPris;
        case ResultatDesignation.seanceIndisponible:
          _message = r.refusSeance;
        case null:
          _message = r.erreur;
      }
    });
    if (resultat != ResultatDesignation.designe &&
        resultat != ResultatDesignation.dejaPris &&
        resultat != ResultatDesignation.seanceIndisponible) {
      if (resultat != null) {
        ref.invalidate(remplacantsPossiblesProvider(widget.seance.id));
      }
      return;
    }
    // Le planning et le bilan relisent ce que le serveur a retenu.
    ref
      ..invalidate(remplacementsSemaineProvider)
      ..invalidate(planningSemaineProvider);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.planning.remplacement;
    final String quand = r.quand(
      jour: libelleJour(widget.seance.debut),
      horaire: libelleHorairePlanning(widget.seance),
    );
    if (_designe case final String nom) {
      return Semantics(
        liveRegion: true,
        child: TexteSansCoupure(
          r.designe(nom: nom),
          key: const ValueKey<String>('remplacant-designe'),
          style: textes.titleMedium,
        ),
      );
    }
    final AsyncValue<List<RemplacantPossible>> lecture = ref.watch(
      remplacantsPossiblesProvider(widget.seance.id),
    );
    final List<RemplacantPossible> possibles =
        lecture.value ?? const <RemplacantPossible>[];
    final RemplacantPossible? choisi = possibles
        .where((RemplacantPossible p) => p.id == _choisie)
        .firstOrNull;
    final bool horsGenre = choisi != null && !choisi.genreCompatible;
    final AsyncValue<List<PersonneProposee>> personnes = lecture.whenData(
      (List<RemplacantPossible> liste) => <PersonneProposee>[
        for (final RemplacantPossible p in liste)
          PersonneProposee(
            id: p.id,
            nom: p.nom,
            identifiant: p.identifiant,
            mention: p.genreCompatible ? r.mentionLibre : r.mentionHorsGenre,
          ),
      ],
    );
    return Column(
      key: const ValueKey<String>('feuille-remplacant'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(quand, style: textes.titleSmall),
        Ecart.vXs,
        TexteSansCoupure(r.contexte, style: textes.bodyMedium),
        Ecart.vLg,
        if (lecture.hasValue && possibles.isEmpty)
          TexteSansCoupure(
            r.aucun,
            key: const ValueKey<String>('remplacant-aucun'),
            style: textes.bodyMedium,
          )
        else
          SelecteurPersonne(
            sorte: SortePersonne.enseignant,
            personnes: personnes,
            choisie: _choisie,
            obligatoire: true,
            onChoix: (PersonneProposee p) => setState(() {
              _choisie = p.id;
              _message = null;
            }),
            onReessayer: () =>
                ref.invalidate(remplacantsPossiblesProvider(widget.seance.id)),
          ),
        if (horsGenre) ...<Widget>[
          Ecart.vMd,
          TexteSansCoupure(
            r.avertissementHorsGenre,
            key: const ValueKey<String>('remplacant-hors-genre'),
            style: textes.bodyMedium,
          ),
        ],
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(
            message,
            key: const ValueKey<String>('remplacant-message'),
          ),
        ],
        if (possibles.isNotEmpty) ...<Widget>[
          Ecart.vXxl,
          BasDeFeuille(
            key: const ValueKey<String>('remplacant-confirmer'),
            libelle: horsGenre ? r.confirmerHorsGenre : r.confirmer,
            enCours: _envoi,
            horsLigne: r.horsLigne,
            onPress: () => unawaited(_designer(possibles)),
          ),
        ],
      ],
    );
  }
}
