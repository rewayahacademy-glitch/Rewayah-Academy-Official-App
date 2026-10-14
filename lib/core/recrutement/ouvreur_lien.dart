/// RECRUT-ECRANS : ouvrir un lien hors de l'application (la copie signee du
/// contrat, l'adresse de la direction).
///
/// `url_launcher` n'est pas une dependance du projet et `pubspec.yaml` est
/// interdit a ce lot : le repli par defaut **copie le lien dans le
/// presse-papiers** et le dit ([ResultatOuverture.copie]). Une ligne Contrats
/// ouvrira la dependance ; il suffira alors de surcharger
/// [ouvreurLienProvider]. Aucun lien n'est journalise.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ce qui est arrive au lien.
enum ResultatOuverture {
  /// Le lien est ouvert.
  ouvert,

  /// Le lien est copie : la personne le colle elle-meme.
  copie,
}

/// Ouvre (ou copie) un lien.
typedef OuvreurLien = Future<ResultatOuverture> Function(Uri lien);

/// Le repli : copier.
Future<ResultatOuverture> copierLien(Uri lien) async {
  await Clipboard.setData(ClipboardData(text: lien.toString()));
  return ResultatOuverture.copie;
}

/// L'ouvreur employe par les ecrans du recrutement.
final Provider<OuvreurLien> ouvreurLienProvider = Provider<OuvreurLien>(
  (Ref _) => copierLien,
);
