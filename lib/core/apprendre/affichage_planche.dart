/// ESPACE-APPRENDRE (lot 5) : grille ou liste, au choix de l'eleve, **garde
/// sur l'appareil** (charte, partie 11).
///
/// Meme stockage que les autres preferences d'affichage de l'appareil
/// ([stockagePreferencesProvider], jamais sensible). Une lecture qui echoue ou
/// une ecriture qui echoue laisse le choix en memoire : l'ecran marche, le
/// choix ne survit simplement pas au prochain lancement.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observabilite/journal_dev.dart';
import '../preferences/preferences_locales.dart'
    show StockagePreferences, stockagePreferencesProvider;
import 'document_planche.dart';

/// La disposition des documents.
enum AffichagePlanche {
  /// Une grille de couvertures (par defaut).
  grille,

  /// Une liste, une ligne par document.
  liste;

  /// Relit une valeur persistee ; `null` si elle est absente ou inconnue.
  static AffichagePlanche? depuis(String? valeur) {
    for (final AffichagePlanche a in values) {
      if (a.name == valeur) return a;
    }
    return null;
  }
}

/// La clef de la preference sur l'appareil.
const String clefAffichagePlanche = 'apprendre.affichage';

/// Le choix grille ou liste de cet appareil.
final NotifierProvider<AffichagePlancheControleur, AffichagePlanche>
affichagePlancheProvider =
    NotifierProvider<AffichagePlancheControleur, AffichagePlanche>(
      AffichagePlancheControleur.new,
    );

/// Porte le choix, le lit au montage et l'ecrit a chaque changement.
class AffichagePlancheControleur extends Notifier<AffichagePlanche> {
  bool _choisi = false;

  @override
  AffichagePlanche build() {
    unawaited(_restaurer());
    return AffichagePlanche.grille;
  }

  StockagePreferences get _stockage => ref.read(stockagePreferencesProvider);

  Future<void> _restaurer() async {
    try {
      final AffichagePlanche? lu = AffichagePlanche.depuis(
        await _stockage.lire(clefAffichagePlanche),
      );
      // Un choix fait entre-temps l'emporte sur la lecture, qui arrive apres.
      if (ref.mounted && !_choisi && lu != null) state = lu;
    } on Object catch (erreur) {
      journalDev(
        'Affichage de la bibliotheque illisible, en memoire : $erreur',
      );
    }
  }

  /// Choisit la disposition, tout de suite, puis l'ecrit sur l'appareil.
  void choisir(AffichagePlanche affichage) {
    if (affichage == state) return;
    _choisi = true;
    state = affichage;
    unawaited(_ecrire(affichage));
  }

  Future<void> _ecrire(AffichagePlanche affichage) async {
    try {
      await _stockage.ecrire(clefAffichagePlanche, affichage.name);
    } on Object catch (erreur) {
      journalDev('Affichage de la bibliotheque non ecrit : $erreur');
    }
  }
}

/// Les types retenus par le filtre de la planche, gardes pendant la session
/// (changer d'onglet puis revenir retrouve le filtre).
final NotifierProvider<TypesRetenusPlanche, Set<TypeDocumentPlanche>>
typesRetenusPlancheProvider =
    NotifierProvider<TypesRetenusPlanche, Set<TypeDocumentPlanche>>(
      TypesRetenusPlanche.new,
    );

/// Le filtre par type de la planche : cumulable ; vide, tous les types.
class TypesRetenusPlanche extends Notifier<Set<TypeDocumentPlanche>> {
  @override
  Set<TypeDocumentPlanche> build() => const <TypeDocumentPlanche>{};

  /// Retient ou relache [type].
  void basculer(TypeDocumentPlanche type) {
    final Set<TypeDocumentPlanche> suivant = Set<TypeDocumentPlanche>.of(state);
    if (!suivant.remove(type)) suivant.add(type);
    state = Set<TypeDocumentPlanche>.unmodifiable(suivant);
  }

  /// Relache tous les types.
  void toutEffacer() => state = const <TypeDocumentPlanche>{};
}
