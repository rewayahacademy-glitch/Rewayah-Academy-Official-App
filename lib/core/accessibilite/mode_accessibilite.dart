// MA-1b : socle du Mode Accessibilite.
//
// Une seule source de verite pour les ecrans :
// - la presentation vient de l'`InterfaceMode` existant du profil eleve
//   (`InterfaceMode.enfant`, valeur SQL `child`, jamais renommee), avec une
//   surcharge de demonstration ; aucune ecriture serveur (BR-1) ;
// - le mouvement reduit combine la preference locale « Reduire les
//   animations », `MediaQuery.disableAnimations` (Android, web) et
//   `AccessibilityFeatures.reduceMotion` (iOS). Il est pose UNE fois sous
//   `MaterialApp.builder` par [ReglageMouvement] : `Mouvement.duree`,
//   `AppMouvement.duree` et tout lecteur de `MediaQuery.disableAnimations` le
//   suivent sans toucher un seul ecran (UX_REVIEW_06, constat V1, MA12) ;
// - le facteur de texte n'est jamais plafonne (MA15) : il reste celui de
//   l'appareil, lu par `MediaQuery.textScalerOf`.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderOrFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../domain/enums.dart';
import '../preferences/preferences_locales.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// Surcharge de demonstration de la presentation : `null` (defaut) suit le
/// profil de la session. Seule la demonstration la surcharge.
final Provider<InterfaceMode?> surchargePresentationProvider =
    Provider<InterfaceMode?>(
      (Ref _) => null,
      // Surchargeable dans un ProviderScope imbrique (demonstration).
      dependencies: const <ProviderOrFamily>[],
    );

/// L'etat d'accessibilite lu par les ecrans.
@immutable
class EtatAccessibilite {
  /// Cree l'etat.
  const EtatAccessibilite({
    required this.presentation,
    required this.animationsReduites,
  });

  /// La presentation de l'eleve (`InterfaceMode` existant).
  final InterfaceMode presentation;

  /// La preference locale « Reduire les animations ».
  final bool animationsReduites;

  /// Vrai quand le Mode Accessibilite est actif.
  bool get modeActif => presentation == InterfaceMode.enfant;

  @override
  bool operator ==(Object other) =>
      other is EtatAccessibilite &&
      other.presentation == presentation &&
      other.animationsReduites == animationsReduites;

  @override
  int get hashCode => Object.hash(presentation, animationsReduites);
}

/// Le fournisseur unique de l'etat d'accessibilite.
final Provider<EtatAccessibilite> accessibiliteProvider =
    Provider<EtatAccessibilite>((Ref ref) {
      final InterfaceMode presentation =
          ref.watch(surchargePresentationProvider) ??
          ref.watch(
            sessionProvider.select((SessionState s) => s.interfaceMode),
          );
      final bool animationsReduites = ref.watch(
        preferencesLocalesProvider.select(
          (PreferencesLocales p) => p.animationsReduites,
        ),
      );
      return EtatAccessibilite(
        presentation: presentation,
        animationsReduites: animationsReduites,
      );
    }, dependencies: <ProviderOrFamily>[surchargePresentationProvider]);

/// Vrai quand le Mode Accessibilite est actif.
final Provider<bool> modeAccessibiliteActifProvider = Provider<bool>(
  (Ref ref) => ref.watch(
    accessibiliteProvider.select((EtatAccessibilite e) => e.modeActif),
  ),
  dependencies: <ProviderOrFamily>[accessibiliteProvider],
);

/// La regle de combinaison, pure pour etre testee : il suffit d'une source.
bool mouvementReduitCombine({
  required bool systeme,
  required bool reduceMotion,
  required bool preference,
}) => systeme || reduceMotion || preference;

/// Pose le mouvement reduit combine dans le `MediaQuery`, une seule fois
/// pour toute l'application (sous `MaterialApp.builder`).
class ReglageMouvement extends ConsumerStatefulWidget {
  /// Cree le reglage autour de [child].
  const ReglageMouvement({required this.child, super.key});

  /// Le contenu.
  final Widget child;

  @override
  ConsumerState<ReglageMouvement> createState() => _ReglageMouvementState();
}

class _ReglageMouvementState extends ConsumerState<ReglageMouvement>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // `reduceMotion` (iOS) n'est pas dans `MediaQueryData` : on se reconstruit
  // quand les fonctions d'accessibilite du systeme changent.
  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool preference = ref.watch(
      accessibiliteProvider.select(
        (EtatAccessibilite e) => e.animationsReduites,
      ),
    );
    final MediaQueryData? donnees = MediaQuery.maybeOf(context);
    if (donnees == null) return widget.child;
    final bool reduceMotion =
        View.maybeOf(context)
            ?.platformDispatcher
            .accessibilityFeatures
            .reduceMotion ??
        false;
    final bool reduit = mouvementReduitCombine(
      systeme: donnees.disableAnimations,
      reduceMotion: reduceMotion,
      preference: preference,
    );
    return MediaQuery(
      data: donnees.copyWith(disableAnimations: reduit),
      child: widget.child,
    );
  }
}
