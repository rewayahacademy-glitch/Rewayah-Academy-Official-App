/// La feuille « Confier la classe … à un autre enseignant » de la direction
/// (regle du directeur du 31/10/2026 : « la direction peut retirer la
/// classe »), ouverte depuis une ligne du bilan des remplacements.
///
/// Le serveur decide de tout (`reaffecter_enseignant_classe`, migration
/// `20261103100000`) : il ne propose que les enseignants que les regles de
/// l'affectation acceptent (unicite a l'heure, genre du public, langue,
/// plafond), il confie les seances a venir, garde les seances passees et leur
/// paie, journalise la decision et previent les deux enseignants et les
/// familles. La consequence est dite avant le choix (K-58).
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
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/selecteur_personne.dart';
import '../admin_groupes/bas_de_feuille.dart';

/// Ouvre la feuille de reaffectation de la Classe de [ligne].
void ouvrirReaffectationClasse(
  BuildContext context,
  RemplacementsTitulaire ligne, {
  required String classe,
}) {
  unawaited(
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.planning.remplacement.reaffecter.titre(classe: classe),
      constructeur: (BuildContext _) => FeuilleReaffectation(ligne: ligne),
    ),
  );
}

/// Le contenu de la feuille.
class FeuilleReaffectation extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleReaffectation({required this.ligne, super.key});

  /// Le titulaire et la Classe concernes.
  final RemplacementsTitulaire ligne;

  @override
  ConsumerState<FeuilleReaffectation> createState() =>
      _FeuilleReaffectationEtat();
}

class _FeuilleReaffectationEtat extends ConsumerState<FeuilleReaffectation> {
  String? _choisie;
  bool _envoi = false;
  String? _message;
  String? _fait;

  Future<void> _confirmer(List<RemplacantPossible> possibles) async {
    final r = t.admin.planning.remplacement.reaffecter;
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
    ResultatReaffectation? resultat;
    try {
      resultat = await port.reaffecter(
        groupeId: widget.ligne.groupeId,
        enseignantId: choisi.id,
      );
    } on Object {
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case ResultatReaffectation.reaffecte:
          _fait = r.fait(nom: choisi.nom);
        case ResultatReaffectation.dejaEnPlace:
          _fait = r.dejaEnPlace(nom: choisi.nom);
        case ResultatReaffectation.occupe:
          _message = r.refusOccupe;
          _choisie = null;
        case ResultatReaffectation.incompatible:
          _message = r.refusIncompatible;
          _choisie = null;
        case ResultatReaffectation.classeIndisponible:
          _message = r.refusClasse;
        case null:
          _message = r.erreur;
      }
    });
    if (resultat == ResultatReaffectation.occupe ||
        resultat == ResultatReaffectation.incompatible) {
      ref.invalidate(enseignantsReaffectationProvider(widget.ligne.groupeId));
      return;
    }
    if (resultat == null) return;
    // Le planning et le bilan relisent ce que le serveur a retenu.
    ref
      ..invalidate(remplacementsSemaineProvider)
      ..invalidate(planningSemaineProvider);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.planning.remplacement.reaffecter;
    if (_fait case final String phrase) {
      return Semantics(
        liveRegion: true,
        child: TexteSansCoupure(
          phrase,
          key: const ValueKey<String>('reaffectation-faite'),
          style: textes.titleMedium,
        ),
      );
    }
    final AsyncValue<List<RemplacantPossible>> lecture = ref.watch(
      enseignantsReaffectationProvider(widget.ligne.groupeId),
    );
    final List<RemplacantPossible> possibles =
        lecture.value ?? const <RemplacantPossible>[];
    final AsyncValue<List<PersonneProposee>> personnes = lecture.whenData(
      (List<RemplacantPossible> liste) => <PersonneProposee>[
        for (final RemplacantPossible p in liste)
          PersonneProposee(
            id: p.id,
            nom: p.nom,
            identifiant: p.identifiant,
            mention: r.mention,
          ),
      ],
    );
    return Column(
      key: const ValueKey<String>('feuille-reaffectation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          r.consequence(titulaire: widget.ligne.titulaire),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        if (lecture.hasValue && possibles.isEmpty)
          TexteSansCoupure(
            r.aucun,
            key: const ValueKey<String>('reaffectation-aucun'),
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
            onReessayer: () => ref.invalidate(
              enseignantsReaffectationProvider(widget.ligne.groupeId),
            ),
          ),
        if (_message case final String message) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(
            message,
            key: const ValueKey<String>('reaffectation-message'),
          ),
        ],
        if (possibles.isNotEmpty) ...<Widget>[
          Ecart.vXxl,
          BasDeFeuille(
            key: const ValueKey<String>('reaffectation-confirmer'),
            libelle: r.confirmer,
            enCours: _envoi,
            horsLigne: r.horsLigne,
            onPress: () => unawaited(_confirmer(possibles)),
          ),
        ],
      ],
    );
  }
}
