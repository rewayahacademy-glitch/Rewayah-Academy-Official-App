// La racine de l'application reelle (lot DEMO-PROD, 04/11/2026).
//
// C'est elle que `main.dart` passe a `runApp` en production : aucune piece de
// la demonstration ne l'enveloppe. Hors production, `RacineDemonstrable`
// (features/demo) la reprend telle quelle et y ajoute seulement le lanceur de
// la demonstration.
//
// La remise a zero (fiche du 27/10/2026, lignes 16 a 18) : chaque appel fait
// avancer le rang de la portee, la `ProviderScope` est renouvelee et tout
// provider repart de zero.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app.dart';
import 'core/i18n/strings.g.dart';
import 'core/session/deconnexion.dart';

/// La racine de l'application reelle, qui sait se remettre a zero.
class RacineReelle extends StatefulWidget {
  /// Cree la racine.
  const RacineReelle({
    super.key,
    this.surcharges = const <Override>[],
    this.themeMode,
  });

  /// Les surcharges de l'application reelle.
  final List<Override> surcharges;

  /// Mode clair/sombre force (captures), ou `null`.
  final ThemeMode? themeMode;

  @override
  State<RacineReelle> createState() => _RacineReelleState();
}

class _RacineReelleState extends State<RacineReelle> {
  /// Le rang de la portee : chaque remise a zero (deconnexion) le fait
  /// avancer.
  int _generation = 0;

  void _remettreAZero() {
    if (!mounted) return;
    setState(() => _generation += 1);
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey<String>('portee-reelle-$_generation'),
    overrides: <Override>[
      ...widget.surcharges,
      remiseAZeroProvider.overrideWithValue(_remettreAZero),
    ],
    child: TranslationProvider(child: RewayahApp(themeMode: widget.themeMode)),
  );
}
