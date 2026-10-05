// Outils des tests du message vocal (COM-VOC-1) : une horloge fixe que le
// test avance lui-meme, en meme temps que les minuteries de `flutter_test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';

/// Une horloge fixe : elle ne bouge que quand le test l'avance.
class HorlogeManuelle {
  /// Cree l'horloge, arretee a [depart].
  HorlogeManuelle([DateTime? depart])
    : _maintenant = depart ?? DateTime.utc(2026, 10, 4, 10);

  DateTime _maintenant;

  /// L'heure courante.
  DateTime maintenant() => _maintenant;

  /// L'horloge au format du port.
  HorlogeVocale get horloge => maintenant;

  /// Avance l'horloge de [duree], sans rien declencher.
  void avancer(Duration duree) => _maintenant = _maintenant.add(duree);
}

/// Avance l'horloge et les minuteries du test de [duree], puis laisse les
/// microtaches se terminer.
Future<void> avancer(
  WidgetTester tester,
  HorlogeManuelle horloge,
  Duration duree,
) async {
  horloge.avancer(duree);
  await tester.pump(duree);
  await tester.pump();
}
