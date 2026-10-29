// Mode demonstration tuteur (P2-07) : entree « Essayer la demonstration ».
//
// La racine de l'application reelle, hors production, porte un lanceur : un
// geste sur l'entree remplace la portee des providers par celle de la
// demonstration (donnees fictives, repere permanent). En production, aucun
// lanceur n'est fourni : l'entree ne s'affiche pas et la bascule n'existe pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../app.dart';
import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/session/deconnexion.dart';
import '../../core/widgets/action_principale.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Libelle de l'entree, traduit (`connexion.essayerDemo`, FR et AR). Un getter
/// et non une constante : la traduction se lit au moment du rendu.
String get libelleEntreeDemonstration => t.connexion.essayerDemo;

/// Le lanceur de la demonstration, ou `null` (production, tests ordinaires) :
/// l'entree ne s'affiche que s'il existe.
final Provider<VoidCallback?> lanceurDemoProvider = Provider<VoidCallback?>(
  (Ref ref) => null,
);

/// La racine de l'application qui sait basculer en demonstration.
class RacineDemonstrable extends StatefulWidget {
  /// Cree la racine.
  const RacineDemonstrable({
    super.key,
    this.environnement = Env.environnement,
    this.surchargesReelles = const <Override>[],
    this.surchargesDemoAnnexes = const <Override>[],
    this.themeMode,
  });

  /// L'environnement compile ; `production` ferme la bascule.
  final String environnement;

  /// Les surcharges de l'application reelle.
  final List<Override> surchargesReelles;

  /// Les surcharges ajoutees en demonstration seulement (tests : stockage en
  /// memoire, horloge muette).
  final List<Override> surchargesDemoAnnexes;

  /// Mode clair/sombre force (captures), ou `null`.
  final ThemeMode? themeMode;

  @override
  State<RacineDemonstrable> createState() => _RacineDemonstrableState();
}

class _RacineDemonstrableState extends State<RacineDemonstrable> {
  bool _demo = false;

  /// Le rang de la portee reelle : chaque remise a zero (deconnexion) le
  /// fait avancer, la `ProviderScope` est renouvelee et tout provider repart
  /// de zero (fiche du 27/10/2026, ligne 17).
  int _generation = 0;

  bool get _autorisee =>
      Env.demoCompilee && environnementAutoriseDemo(widget.environnement);

  void _lancer() {
    if (!_autorisee || _demo) return;
    setState(() => _demo = true);
  }

  void _remettreAZero() {
    if (!mounted) return;
    setState(() => _generation += 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_demo && _autorisee) {
      return ProviderScope(
        key: const ValueKey<String>('portee-demonstration'),
        overrides: <Override>[
          ...widget.surchargesDemoAnnexes,
          ...surchargesDemoTuteur(environnement: widget.environnement),
        ],
        child: TranslationProvider(
          child: RewayahApp(
            themeMode: widget.themeMode,
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      );
    }
    return ProviderScope(
      key: ValueKey<String>('portee-reelle-$_generation'),
      overrides: <Override>[
        ...widget.surchargesReelles,
        remiseAZeroProvider.overrideWithValue(_remettreAZero),
        if (_autorisee) lanceurDemoProvider.overrideWithValue(_lancer),
      ],
      child: TranslationProvider(
        child: RewayahApp(themeMode: widget.themeMode),
      ),
    );
  }
}

/// L'entree « Essayer la demonstration » : rien si aucun lanceur n'est fourni.
class EntreeDemonstration extends ConsumerWidget {
  /// Cree l'entree.
  const EntreeDemonstration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VoidCallback? lancer = ref.watch(lanceurDemoProvider);
    if (lancer == null) return const SizedBox.shrink();
    return Align(
      child: ActionPrincipale(
        key: const ValueKey<String>('entree-demonstration'),
        libelle: libelleEntreeDemonstration,
        onPress: lancer,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
    );
  }
}
