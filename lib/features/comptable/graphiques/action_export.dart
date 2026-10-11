// « Exporter le rapport » et « Exporter la selection » (COMPTA-GRAPH-1,
// maquettes W02 et Rapports). Le fichier est produit par la source
// (`PortExportRapports`, CPT-BR-19), jamais par Flutter.
//
// Quatre etats, jamais un bouton grise : l'action (la capacite existe),
// l'export en preparation (`enCours`), le resultat (la reference rendue par
// la source) ou l'echec en une phrase qui dit quoi faire (K-59) ; et, sans
// capacite, **une phrase a la place de l'action** qui dit que les exports
// ne sont pas encore disponibles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_export_rapports.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';

/// L'action d'export d'un [perimetre].
class ActionExport extends ConsumerStatefulWidget {
  /// Cree l'action. [identifiants] n'est lu que pour
  /// [PerimetreExport.selection].
  const ActionExport({
    required this.perimetre,
    super.key,
    this.identifiants = const <String>[],
  });

  /// Ce qu'on exporte.
  final PerimetreExport perimetre;

  /// Les lignes retenues, pour une selection.
  final List<String> identifiants;

  @override
  ConsumerState<ActionExport> createState() => _ActionExportEtat();
}

class _ActionExportEtat extends ConsumerState<ActionExport> {
  /// Une cle par demande : deux appuis, ou un appui apres une reponse perdue,
  /// reprennent le meme export cote source.
  String _cle = const Uuid().v4();
  bool _enCours = false;
  ResultatExport? _resultat;
  bool _echec = false;

  Future<void> _exporter() async {
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _echec = false;
      _resultat = null;
    });
    final PortExportRapports port = ref.read(portExportRapportsProvider);
    try {
      final ResultatExport resultat =
          widget.perimetre == PerimetreExport.rapport
          ? await port.exporterRapport(cleIdempotence: _cle)
          : await port.exporterSelection(
              identifiants: widget.identifiants,
              cleIdempotence: _cle,
            );
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _resultat = resultat;
        _cle = const Uuid().v4();
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = t.comptable.graphiques;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle phrase = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    if (!ref.watch(exportDisponibleProvider)) {
      return Text(
        g.exportIndisponible,
        key: const ValueKey<String>('export-indisponible'),
        style: phrase,
      );
    }
    final bool rapport = widget.perimetre == PerimetreExport.rapport;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ActionPrincipale(
          key: ValueKey<String>(
            rapport ? 'export-rapport' : 'export-selection',
          ),
          libelle: rapport ? g.exporterRapport : g.exporterSelection,
          niveau: NiveauAction.secondaire,
          pleineLargeur: false,
          enCours: _enCours,
          onPress: _exporter,
        ),
        if (_enCours) ...<Widget>[
          Ecart.vXs,
          Text(g.exportEnCours, style: phrase),
        ],
        if (_resultat != null) ...<Widget>[
          Ecart.vXs,
          Text(
            g.exportPret(
              reference: _resultat!.reference,
              lignes: _resultat!.lignes,
            ),
            key: const ValueKey<String>('export-resultat'),
            style: phrase,
          ),
        ],
        if (_echec) ...<Widget>[
          Ecart.vXs,
          Text(
            g.exportEchec,
            key: const ValueKey<String>('export-echec'),
            style: palette.inkAlert.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}
