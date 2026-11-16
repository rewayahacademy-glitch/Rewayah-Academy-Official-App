// Sur le web : `window.open` dans un nouvel onglet, sans lien de retour
// (`noopener`).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre [lien] dans un nouvel onglet ; `true` si elle est ouverte.
typedef OuvreurOnglet = Future<bool> Function(Uri lien);

/// Ouvre [lien] dans un nouvel onglet.
Future<bool> ouvrirDansUnOnglet(Uri lien) async {
  try {
    globalContext.callMethod<JSAny?>(
      'open'.toJS,
      lien.toString().toJS,
      '_blank'.toJS,
      'noopener'.toJS,
    );
    return true;
  } on Object {
    return false;
  }
}

/// L'ouvreur d'onglet employe par les ecrans (surchargeable en test).
final Provider<OuvreurOnglet> ouvreurOngletProvider = Provider<OuvreurOnglet>(
  (Ref _) => ouvrirDansUnOnglet,
);
