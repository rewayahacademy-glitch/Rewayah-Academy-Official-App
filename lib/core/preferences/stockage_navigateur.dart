// Le stockage cle/valeur du navigateur, pour les preferences d'affichage
// d'une PWA qui doivent survivre a la fermeture de l'onglet.
//
// Hors web, l'implementation est un stockage en memoire : elle n'y sert pas,
// la base locale Drift y fait ce travail (`StockagePreferencesDrift`).
export 'stockage_navigateur_memoire.dart'
    if (dart.library.js_interop) 'stockage_navigateur_web.dart';
