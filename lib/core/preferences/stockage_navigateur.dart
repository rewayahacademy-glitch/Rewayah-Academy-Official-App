/// Le stockage des preferences d'affichage dans un navigateur.
///
/// `AppDatabase` ne s'ouvre pas sur le web (voir [StockagePreferencesMemoire]) :
/// le `localStorage` du navigateur garde le theme choisi d'une visite a
/// l'autre. Hors du web, ce fichier rend le stockage en memoire (import
/// conditionnel), ce qui garde les tests et les plateformes natives
/// inchanges.
library;

export 'stockage_navigateur_memoire.dart'
    if (dart.library.js_interop) 'stockage_navigateur_web.dart';
