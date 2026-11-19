// Le renvoi du navigateur vers une adresse externe (PX-OAUTH 2d : le retour
// vers le client apres la decision de la direction). Hors web, il n'y a aucun
// navigateur a renvoyer et l'implementation ne fait rien.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aller_adresse_memoire.dart'
    if (dart.library.js_interop) 'aller_adresse_web.dart'
    as implementation;

/// Le renvoi du navigateur, remplacable dans les tests.
final Provider<void Function(String)> allerAdresseProvider =
    Provider<void Function(String)>((Ref ref) => implementation.allerAdresse);
