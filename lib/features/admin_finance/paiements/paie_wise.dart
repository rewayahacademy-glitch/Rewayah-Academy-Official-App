// « Paie des enseignants par Wise », dans l'onglet Paiements de la Finance de
// la direction (lot FINANCE-ENSEIGNANT, 06/11/2026 ; decision du directeur du
// 06/11 : paiement groupe Wise par fichier CSV). Zone confiee par le
// garde-cap : `lib/features/admin_finance/paiements/`.
//
// Deux gestes, chacun dans sa feuille (feuille du bas au telephone, boite a
// l'ordinateur, `AppBottomSheet`) :
//   1. « Preparer le fichier Wise du mois » : le serveur rend colonnes, lignes
//      et enseignants a part (coordonnees manquantes) ; l'app n'ecrit que le
//      CSV et l'enregistre par le selecteur du systeme. Aucun montant calcule
//      ici. Sans modele Wise pose, la feuille le dit et dit quoi faire.
//   2. « Noter un versement fait » : le versement deja parti (Wise ou autre)
//      est note ; l'enseignant le voit dans « Versements recus ». Une cle
//      d'idempotence est tiree une fois par feuille.
// Un bouton plein par feuille ; dans l'onglet, deux lignes qui menent ailleurs.
// La feuille « Noter » vit dans `feuille_noter_versement.dart`.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_coordonnees_versement.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/tc_telechargement/port_enregistrement_fichier.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart' show TonEtat;
import '../../paiements_recus/etat_coordonnees.dart' show libelleMoisPaie;
import 'feuille_noter_versement.dart';
import 'feuille_valider_coordonnees.dart';

/// Le premier jour du mois de [d].
DateTime premierDuMois(DateTime d) => DateTime(d.year, d.month);

/// Le mois de paie par defaut : le mois termine (la paie se verse avant le 5).
DateTime moisPaieParDefaut(DateTime maintenant) =>
    DateTime(maintenant.year, maintenant.month - 1);

/// Le nom du fichier propose : « paie-wise-2026-10.csv ».
String nomFichierWise(DateTime mois) =>
    'paie-wise-${mois.year}-${mois.month.toString().padLeft(2, '0')}.csv';

/// Le bloc de l'onglet Paiements.
class BlocPaieWise extends StatelessWidget {
  /// Cree le bloc.
  const BlocPaieWise({super.key});

  /// La cle de la ligne « Preparer le fichier ».
  static const Key cleExporter = ValueKey<String>('paie-wise-exporter');

  /// La cle de la ligne « Coordonnees a valider ».
  static const Key cleValider = ValueKey<String>('paie-wise-valider');

  /// La cle de la ligne « Noter un versement ».
  static const Key cleNoter = ValueKey<String>('paie-wise-noter');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.paieWise;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: a.titre),
        Text(
          a.phrase,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        CarteLignes(
          lignes: <Widget>[
            SettingRow(
              key: cleExporter,
              title: a.exporter,
              lien: true,
              onPress: () => unawaited(
                _ouvrir(context, a.exportTitre, const FeuilleExportWise()),
              ),
            ),
            SettingRow(
              key: cleValider,
              title: a.valider,
              lien: true,
              onPress: () => unawaited(
                _ouvrir(
                  context,
                  a.validerTitre,
                  const FeuilleValiderCoordonnees(),
                ),
              ),
            ),
            SettingRow(
              key: cleNoter,
              title: a.noter,
              lien: true,
              onPress: () => unawaited(
                _ouvrir(context, a.noterTitre, const FeuilleNoterVersement()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _ouvrir(BuildContext context, String titre, Widget feuille) {
    final ProviderContainer portee = ProviderScope.containerOf(
      context,
      listen: false,
    );
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: titre,
      constructeur: (BuildContext _) =>
          UncontrolledProviderScope(container: portee, child: feuille),
    );
  }
}

/// Le choix du mois : le mois termine, ou le mois en cours.
class ChoixMoisPaie extends StatelessWidget {
  /// Cree le choix.
  const ChoixMoisPaie({
    required this.valeur,
    required this.onChange,
    super.key,
  });

  /// Le mois retenu.
  final DateTime valeur;

  /// Recoit le mois choisi.
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.paieWise;
    final DateTime maintenant = DateTime.now();
    final DateTime precedent = moisPaieParDefaut(maintenant);
    final DateTime courant = premierDuMois(maintenant);
    return ChoiceCardGroup(
      autoriserSaisieLibre: false,
      valeurInitiale: ReponseChoix(
        valeurs: <String>{valeur == courant ? 'courant' : 'precedent'},
      ),
      options: <OptionChoix>[
        OptionChoix(
          valeur: 'precedent',
          libelle: a.moisPrecedent(mois: libelleMoisPaie(precedent)),
          description: a.moisPrecedentDetail,
          cle: const ValueKey<String>('paie-wise-mois-precedent'),
        ),
        OptionChoix(
          valeur: 'courant',
          libelle: a.moisEnCours(mois: libelleMoisPaie(courant)),
          description: a.moisEnCoursDetail,
          cle: const ValueKey<String>('paie-wise-mois-courant'),
        ),
      ],
      onChange: (ReponseChoix r) {
        if (r.valeurs.isEmpty) return;
        onChange(r.valeurs.first == 'courant' ? courant : precedent);
      },
    );
  }
}

enum _PhaseExport { choix, envoi, pret, modeleAbsent, echec }

/// La feuille « Fichier Wise de la paie ».
class FeuilleExportWise extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleExportWise({super.key});

  /// La cle du bouton plein.
  static const Key cleAction = ValueKey<String>('paie-wise-export-action');

  /// La cle de la phrase « n lignes, total ».
  static const Key clePret = ValueKey<String>('paie-wise-export-pret');

  /// La cle du bandeau « modele absent ».
  static const Key cleModeleAbsent = ValueKey<String>('paie-wise-modele');

  @override
  ConsumerState<FeuilleExportWise> createState() => _FeuilleExportWiseEtat();
}

class _FeuilleExportWiseEtat extends ConsumerState<FeuilleExportWise> {
  DateTime _mois = moisPaieParDefaut(DateTime.now());
  _PhaseExport _phase = _PhaseExport.choix;
  ExportWise? _export;
  bool _enregistre = false;
  bool _enregistrement = false;

  Future<void> _preparer() async {
    if (_phase == _PhaseExport.envoi) return;
    setState(() => _phase = _PhaseExport.envoi);
    try {
      final ExportWise e = await ref
          .read(portCoordonneesVersementProvider)
          .exporter(_mois);
      if (!mounted) return;
      setState(() {
        _export = e;
        _phase = _PhaseExport.pret;
      });
    } on ModeleWiseAbsent {
      if (mounted) setState(() => _phase = _PhaseExport.modeleAbsent);
    } on Object {
      if (mounted) setState(() => _phase = _PhaseExport.echec);
    }
  }

  Future<void> _enregistrer(ExportWise e) async {
    if (_enregistrement) return;
    setState(() => _enregistrement = true);
    try {
      final String? destination = await ref
          .read(portEnregistrementFichierProvider)
          .enregistrerCopie(
            octets: utf8.encode(fichierCsvWise(e)),
            nomFichierPropose: nomFichierWise(e.mois),
            typeMime: 'text/csv',
          );
      if (mounted && destination != null) setState(() => _enregistre = true);
    } on Object {
      if (mounted) setState(() => _phase = _PhaseExport.echec);
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.paieWise;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final ExportWise? e = _export;
    final bool pret = _phase == _PhaseExport.pret && e != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(a.exportIntro, style: attenue),
        Ecart.vLg,
        if (!pret) ...<Widget>[
          ChoixMoisPaie(valeur: _mois, onChange: (DateTime m) => _mois = m),
          Ecart.vLg,
        ],
        if (_phase == _PhaseExport.modeleAbsent) ...<Widget>[
          BandeauAttention(
            key: FeuilleExportWise.cleModeleAbsent,
            titre: a.exportTitre,
            message: a.modeleAbsent,
          ),
          Ecart.vLg,
        ],
        if (_phase == _PhaseExport.echec) ...<Widget>[
          BandeauAttention(
            titre: a.exportTitre,
            message: a.erreurExport,
            ton: TonEtat.alerte,
          ),
          Ecart.vLg,
        ],
        if (pret) ...<Widget>[
          Text(
            e.lignes.isEmpty
                ? a.aucuneLigne
                : a.pret(n: e.lignes.length, total: formaterMontant(e.total)),
            key: FeuilleExportWise.clePret,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
            ),
          ),
          if (_enregistre) ...<Widget>[
            Ecart.vSm,
            Text(a.fichierEnregistre, style: attenue),
          ],
          if (e.manquants.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            SectionHeader(titre: a.manquantsTitre),
            Text(a.manquantsPhrase, style: attenue),
            Ecart.vMd,
            CarteLignes(
              lignes: <Widget>[
                for (final EnseignantSansCoordonnees m in e.manquants)
                  SettingRow(
                    key: ValueKey<String>(
                      'paie-wise-manquant-${m.enseignantId}',
                    ),
                    title: m.matricule == null
                        ? m.nom
                        : '${m.nom} · ${m.matricule}',
                    description: m.aucune
                        ? a.manquantAucune
                        : m.aValider
                        ? a.manquantAValider
                        : a.manquantIncompletes,
                    value: formaterMontant(m.montant),
                  ),
              ],
            ),
          ],
          Ecart.vLg,
        ],
        // Un seul bouton plein : « Preparer », puis « Enregistrer le fichier ».
        if (!pret || e.lignes.isNotEmpty)
          ActionPrincipale(
            key: FeuilleExportWise.cleAction,
            libelle: pret ? a.enregistrerFichier : a.preparer,
            enCours: pret ? _enregistrement : _phase == _PhaseExport.envoi,
            onPress: pret
                ? () => unawaited(_enregistrer(e))
                : () => unawaited(_preparer()),
          ),
      ],
    );
  }
}
