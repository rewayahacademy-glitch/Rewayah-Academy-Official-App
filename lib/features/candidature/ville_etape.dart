// HORLOGE-ET-LIEU, partie B (Q5, architecte, 12/11/2026) : la ville du
// candidat remplace l'etape du fuseau, et devient le lieu de l'enseignant (la
// direction la verifie). Le serveur recopie le nom, le pays, le fuseau et les
// coordonnees ; le questionnaire ne garde que le fuseau de la ville, qui
// commande l'heure de l'entretien comme avant (`fuseauIana`).
//
// Repli : tant que les fonctions du lieu ne sont pas installees sur le serveur
// (ou sans serveur), l'ancienne etape du fuseau reste celle de la personne.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/lieu/choix_ville.dart';
import '../../core/lieu/lieu.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import 'fuseau_etape.dart';

/// L'etape de la ville du candidat.
class VilleEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const VilleEtape({
    required this.options,
    required this.choisi,
    required this.onChange,
    super.key,
  });

  /// Les fuseaux que le serveur accepte pour le questionnaire.
  final List<String> options;

  /// Le fuseau retenu, s'il y en a un.
  final String? choisi;

  /// Appele avec le fuseau de la ville retenue.
  final ValueChanged<String> onChange;

  @override
  ConsumerState<VilleEtape> createState() => _EtatVilleEtape();
}

class _EtatVilleEtape extends ConsumerState<VilleEtape> {
  bool _repli = false;
  bool _echec = false;

  Future<void> _choisir(Ville v) async {
    // Une ville dont le fuseau n'est pas accepte par le questionnaire ne
    // peut pas partir : on le dit, sans rien enregistrer.
    if (!widget.options.contains(v.fuseau)) {
      setState(() => _echec = true);
      return;
    }
    setState(() => _echec = false);
    try {
      await ref.read(portLieuProvider).enregistrer(v.id);
      if (!mounted) return;
      widget.onChange(v.fuseau);
    } on Object {
      if (!mounted) return;
      setState(() => _echec = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_repli || ref.watch(portLieuProvider) is LieuAbsent) {
      return FuseauEtape(
        options: widget.options,
        choisi: widget.choisi,
        onChange: widget.onChange,
      );
    }
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.lieu.consigneEnseignant, style: textes.bodyMedium),
        Ecart.vXl,
        ChoixVille(
          onChoisie: (Ville v) => unawaited(_choisir(v)),
          onIndisponible: () => setState(() => _repli = true),
        ),
        if (_echec) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              t.lieu.echec,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
      ],
    );
  }
}
