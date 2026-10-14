import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ouvreur_onglet_memoire.dart'
    if (dart.library.js_interop) 'ouvreur_onglet_web.dart';

/// Ouvre un lien dans un nouvel onglet du navigateur : vrai quand il s'est
/// ouvert, faux quand le navigateur l'a bloque. Le lien n'est ni garde ni
/// journalise.
typedef OuvreurOnglet = bool Function(Uri lien);

/// L'ouvreur d'onglet de l'application, ou `null` hors navigateur : sans lui,
/// aucun bouton « Ouvrir » n'est rendu. Surcharge par les tests.
final Provider<OuvreurOnglet?> ouvreurOngletProvider = Provider<OuvreurOnglet?>(
  (Ref _) => ouvreurOngletNatif(),
);
