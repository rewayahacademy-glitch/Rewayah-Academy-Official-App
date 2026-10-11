// Les annonces faites au lecteur d'ecran (BOUTONS-GRISES-1) : un bouton
// presse trop tot dit ce qui manque, et le lecteur d'ecran doit l'entendre.
// `SemanticsService.sendAnnouncement` passe par le canal d'accessibilite ;
// ce harnais l'ecoute et rend les messages, dans l'ordre.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ecoute les annonces jusqu'a la fin du test et rend la liste qui les
/// recoit.
List<String> ecouterAnnonces(WidgetTester tester) {
  final List<String> annonces = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (Object? message) async {
      if (message is Map && message['type'] == 'announce') {
        final Object? donnees = message['data'];
        if (donnees is Map && donnees['message'] is String) {
          annonces.add(donnees['message'] as String);
        }
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return annonces;
}
