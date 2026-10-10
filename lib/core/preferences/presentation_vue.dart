// PUB-1 (decision deleguee du 05/10/2026) : la presentation publique avant la
// connexion n'est montree d'office qu'une fois par appareil.
//
// Une preference d'affichage locale, non sensible : elle ne dit rien du
// compte, ne quitte jamais l'appareil et ne decide d'aucun droit. Elle sert au
// seul routeur, pour choisir ou mene la racine d'un visiteur sans session.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observabilite/journal_dev.dart';
import 'preferences_locales.dart';
import 'stockage_navigateur.dart';

/// Ce que l'appareil sait de la presentation publique.
enum EtatPresentation {
  /// Le stockage n'a pas encore ete lu : le routeur attend, sans rien
  /// montrer d'autre que l'ecran de demarrage (pas de clignotement).
  inconnu,

  /// Premiere visite sur cet appareil, ou stockage illisible : la racine
  /// mene a la presentation.
  aVoir,

  /// La presentation a ete fermee une fois (croix ou bouton de fin) : la
  /// racine mene a la connexion.
  vue,
}

/// Clef de la preference dans le stockage local.
const String clefPresentationVue = 'presentation.vue';

/// La valeur ecrite quand la presentation a ete vue.
const String _valeurVue = 'oui';

/// Le stockage de cette preference.
///
/// Sur le web (PWA), le `localStorage` du navigateur : le stockage commun des
/// preferences y vit en memoire (`stockagePreferencesProvider`), et la
/// presentation reviendrait a chaque visite. Ailleurs, le stockage commun
/// (base locale Drift).
final Provider<StockagePreferences> stockagePresentationProvider =
    Provider<StockagePreferences>(
      (Ref ref) => kIsWeb
          ? StockagePreferencesNavigateur()
          : ref.watch(stockagePreferencesProvider),
    );

/// L'etat de la presentation sur cet appareil.
final NotifierProvider<PresentationControleur, EtatPresentation>
presentationProvider =
    NotifierProvider<PresentationControleur, EtatPresentation>(
      PresentationControleur.new,
    );

/// Lit et ecrit la preference « presentation vue ».
///
/// **La lecture est paresseuse** : elle ne part que lorsque le routeur en a
/// besoin ([charger], visiteur sans session sur la racine). Un compte deja
/// connecte ne touche jamais ce stockage.
class PresentationControleur extends Notifier<EtatPresentation> {
  bool _lectureLancee = false;

  @override
  EtatPresentation build() => EtatPresentation.inconnu;

  /// Lance la lecture du stockage, une seule fois. Sans effet si l'etat est
  /// deja connu.
  void charger() {
    if (_lectureLancee || state != EtatPresentation.inconnu) return;
    _lectureLancee = true;
    unawaited(_lire());
  }

  Future<void> _lire() async {
    EtatPresentation lu;
    try {
      final String? valeur = await ref
          .read(stockagePresentationProvider)
          .lire(clefPresentationVue);
      lu = valeur == _valeurVue ? EtatPresentation.vue : EtatPresentation.aVoir;
    } on Object catch (erreur) {
      // Une panne du stockage ne bloque jamais l'entree : on montre la
      // presentation, comme a une premiere visite.
      journalDev('Preference de presentation illisible : $erreur');
      lu = EtatPresentation.aVoir;
    }
    if (ref.mounted && state == EtatPresentation.inconnu) state = lu;
  }

  /// Note que la presentation a ete vue (croix ou bouton de fin). L'etat
  /// change tout de suite ; l'ecriture suit, et son echec ne bloque rien :
  /// la presentation reviendra simplement a la prochaine visite.
  Future<void> marquerVue() async {
    state = EtatPresentation.vue;
    try {
      await ref
          .read(stockagePresentationProvider)
          .ecrire(clefPresentationVue, _valeurVue);
    } on Object catch (erreur) {
      journalDev('Preference de presentation non ecrite : $erreur');
    }
  }
}
