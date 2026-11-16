// Hors du web : pas d'onglet ; l'adresse est copiee (le repli de
// `ouvreurLienProvider`) et le retour dit qu'elle n'est pas ouverte.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre [lien] dans un nouvel onglet ; `true` si elle est ouverte.
typedef OuvreurOnglet = Future<bool> Function(Uri lien);

/// Copie [lien] ; rend `false` (rien n'est ouvert).
Future<bool> ouvrirDansUnOnglet(Uri lien) async {
  await Clipboard.setData(ClipboardData(text: lien.toString()));
  return false;
}

/// L'ouvreur d'onglet employe par les ecrans (surchargeable en test).
final Provider<OuvreurOnglet> ouvreurOngletProvider = Provider<OuvreurOnglet>(
  (Ref _) => ouvrirDansUnOnglet,
);
