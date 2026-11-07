// La feuille « Noter un versement fait » (lot FINANCE-ENSEIGNANT,
// 06/11/2026), ouverte depuis « Paie des enseignants par Wise »
// (`paie_wise.dart`). Le versement deja parti (Wise ou autre) est note ;
// l'enseignant le voit dans « Versements recus ». Une cle d'idempotence est
// tiree une fois par feuille : « Reessayer » ne note jamais deux versements.
//
// K-57 : deduit (date du jour, mois termine, virement bancaire, devise
// source), choisi (enseignant, mois, moyen), saisi (montant, reference de
// l'operation, note : seule la personne qui a verse les connait).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_coordonnees_versement.dart';
import '../../../core/capacites/port_versements_paie.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart' show TonEtat;
import '../../paiements_recus/etat_coordonnees.dart'
    show caracteresInterditsVersement, libelleMoyenVersement;
import 'paie_wise.dart' show ChoixMoisPaie, moisPaieParDefaut;
import 'paiements_page.dart' show mineurDepuisSaisie;

/// La feuille « Noter un versement fait ».
class FeuilleNoterVersement extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleNoterVersement({super.key});

  /// La cle du bouton plein.
  static const Key cleAction = ValueKey<String>('paie-wise-noter-action');

  /// La cle du champ du montant.
  static const Key cleMontant = ValueKey<String>('paie-wise-noter-montant');

  /// La cle du champ de la date.
  static const Key cleDate = ValueKey<String>('paie-wise-noter-date');

  /// La cle du champ de la reference.
  static const Key cleReference = ValueKey<String>('paie-wise-noter-reference');

  /// La cle de l'option d'un enseignant.
  static Key cleEnseignant(String id) =>
      ValueKey<String>('paie-wise-noter-enseignant-$id');

  /// La cle du message de reussite.
  static const Key cleFait = ValueKey<String>('paie-wise-noter-fait');

  @override
  ConsumerState<FeuilleNoterVersement> createState() =>
      _FeuilleNoterVersementEtat();
}

class _FeuilleNoterVersementEtat extends ConsumerState<FeuilleNoterVersement> {
  // Une cle par feuille : « Reessayer » ne note jamais deux versements.
  final String _cle = const Uuid().v4();
  final TextEditingController _montant = TextEditingController();
  final TextEditingController _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late final Future<List<EnseignantVersement>> _enseignants = ref
      .read(portCoordonneesVersementProvider)
      .enseignants();
  String? _enseignant;
  DateTime _mois = moisPaieParDefaut(DateTime.now());
  MoyenVersement _moyen = MoyenVersement.virementBancaire;
  final Set<String> _erreurs = <String>{};
  bool _enCours = false;
  bool _echec = false;
  bool _fait = false;

  // La devise source du fichier Wise ; un versement dans une autre devise se
  // note par le meme champ des que le reglage change.
  static const String _devise = 'USD';

  @override
  void dispose() {
    _montant.dispose();
    _date.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _noter() async {
    if (_enCours) return;
    final int? mineur = mineurDepuisSaisie(_montant.text, _devise);
    final DateTime? date = DateTime.tryParse(_date.text.trim());
    final String reference = _reference.text.trim();
    final String note = _note.text.trim();
    final Set<String> erreurs = <String>{
      if (_enseignant == null) 'enseignant',
      if (mineur == null) 'montant',
      if (date == null ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_date.text.trim()))
        'date',
      if (reference.isNotEmpty &&
          !RegExp(r'^[A-Za-z0-9_\-:./#]{1,60}$').hasMatch(reference))
        'reference',
      if (caracteresInterditsVersement.hasMatch(note)) 'note',
    };
    setState(() {
      _erreurs
        ..clear()
        ..addAll(erreurs);
      _echec = false;
    });
    if (erreurs.isNotEmpty) return;
    setState(() => _enCours = true);
    try {
      await ref
          .read(portVersementsPaieProvider)
          .noter(
            VersementANoter(
              enseignantId: _enseignant!,
              montant: Montant(mineur!, _devise),
              verseLe: date!,
              mois: _mois,
              moyen: _moyen,
              cle: _cle,
              reference: reference.isEmpty ? null : reference,
              note: note.isEmpty ? null : note,
            ),
          );
      if (mounted) setState(() => _fait = true);
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.paieWise;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    if (_fait) {
      return BandeauAttention(
        key: FeuilleNoterVersement.cleFait,
        titre: a.versementNote,
        message: a.noterIntro,
        ton: TonEtat.succes,
      );
    }
    String aide(String champ, String sinon) =>
        _erreurs.contains(champ) ? a.erreurChamp : sinon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(a.noterIntro, style: attenue),
        Ecart.vLg,
        SectionHeader(titre: a.enseignant),
        FutureBuilder<List<EnseignantVersement>>(
          future: _enseignants,
          builder:
              (BuildContext _, AsyncSnapshot<List<EnseignantVersement>> s) {
                final List<EnseignantVersement>? liste = s.data;
                if (liste == null) {
                  return s.hasError
                      ? Text(a.erreurNoter, style: attenue)
                      : const SizedBox(height: AppSpacing.xl);
                }
                if (liste.isEmpty) {
                  return Text(a.aucunEnseignant, style: attenue);
                }
                return ChoiceCardGroup(
                  autoriserSaisieLibre: false,
                  options: <OptionChoix>[
                    for (final EnseignantVersement e in liste)
                      OptionChoix(
                        valeur: e.enseignantId,
                        libelle: e.nom,
                        description: e.matricule,
                        cle: FeuilleNoterVersement.cleEnseignant(
                          e.enseignantId,
                        ),
                      ),
                  ],
                  onChange: (ReponseChoix r) => setState(
                    () => _enseignant = r.valeurs.isEmpty
                        ? null
                        : r.valeurs.first,
                  ),
                );
              },
        ),
        if (_erreurs.contains('enseignant')) ...<Widget>[
          Ecart.vSm,
          Text(
            a.erreurChamp,
            style: palette.inkAlert.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        ChampEtiquete(
          key: FeuilleNoterVersement.cleMontant,
          libelle: a.montant(devise: _devise),
          controller: _montant,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          obligatoire: true,
          aide: aide('montant', a.montantAide),
        ),
        Ecart.vLg,
        ChampEtiquete(
          key: FeuilleNoterVersement.cleDate,
          libelle: a.date,
          controller: _date,
          obligatoire: true,
          aide: aide('date', a.dateAide),
        ),
        Ecart.vLg,
        SectionHeader(titre: a.mois),
        ChoixMoisPaie(
          valeur: _mois,
          onChange: (DateTime m) => setState(() => _mois = m),
        ),
        Ecart.vLg,
        SectionHeader(titre: a.moyenVersement),
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_moyen.name}),
          options: <OptionChoix>[
            for (final MoyenVersement m in MoyenVersement.values)
              OptionChoix(valeur: m.name, libelle: libelleMoyenVersement(m)),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            setState(
              () => _moyen = MoyenVersement.values.byName(r.valeurs.first),
            );
          },
        ),
        Ecart.vLg,
        ChampEtiquete(
          key: FeuilleNoterVersement.cleReference,
          libelle: a.reference,
          controller: _reference,
          aide: aide('reference', a.referenceAide),
        ),
        Ecart.vLg,
        ChampEtiquete(
          libelle: a.note,
          controller: _note,
          maxLines: 3,
          aide: aide('note', a.noteAide),
        ),
        Ecart.vLg,
        if (_echec) ...<Widget>[
          BandeauAttention(
            titre: a.noterTitre,
            message: a.erreurNoter,
            ton: TonEtat.alerte,
          ),
          Ecart.vLg,
        ],
        ActionPrincipale(
          key: FeuilleNoterVersement.cleAction,
          libelle: a.noterAction,
          enCours: _enCours,
          onPress: () => unawaited(_noter()),
        ),
      ],
    );
  }
}
