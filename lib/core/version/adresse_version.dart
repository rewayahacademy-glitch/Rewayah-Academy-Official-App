// L'adresse de `version.json`, servi a cote de `main.dart.js`. Hors web, il
// n'y a pas de fichier servi : aucune adresse, aucune lecture.
export 'adresse_version_memoire.dart'
    if (dart.library.js_interop) 'adresse_version_web.dart';
