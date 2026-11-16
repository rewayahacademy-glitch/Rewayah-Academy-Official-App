// IMAGES-CORRECTIF : une bulle en echec ne porte plus de bouton « Reessayer » ;
// la ligne « Non confirme · Toucher pour reessayer » (ou l'icone d'alerte)
// ouvre un menu avec « Reessayer » et « Supprimer ». Un seul geste pour les
// tests qui rejouent ou suppriment une bulle.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

/// La ligne courte d'une bulle en echec.
String get ligneEchec => t.com.messages.images.nonConfirmeToucher;

/// Ouvre le menu de la bulle en echec par sa ligne, puis choisit [libelle].
Future<void> choisirActionEchec(WidgetTester tester, String libelle) async {
  await tester.tap(find.byKey(FilDiscussion.cleLigneEchec));
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle));
  // Pas de pumpAndSettle : un nouvel envoi anime son cercle de progression.
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
