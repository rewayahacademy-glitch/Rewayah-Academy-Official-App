// Mes classes (directeur, 30/10/2026) : le compte a rebours change d'unite a
// l'approche, dans un seul formateur partage par la Classe, l'Accueil
// famille et l'Accueil eleve.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';

/// Le texte sans ses espaces insecables ni ses isolats, pour le lire.
String _brut(String s) =>
    s.replaceAll('\u00A0', ' ').replaceAll(RegExp('[\u2066-\u2069\u200E]'), '');

String _compte(DateTime maintenant, DateTime debut) => _brut(
  LibellesGroupe.compteARebours(debut.difference(maintenant), debut: debut),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final DateTime lundi = DateTime(2026, 11, 2, 14, 55);

  test('les unites suivent l approche', () {
    expect(_compte(lundi, DateTime(2026, 11, 8, 18)), 'Cours dans 6 jours');
    expect(_compte(lundi, DateTime(2026, 11, 4, 9)), 'Cours dans 2 jours');
    expect(_compte(lundi, DateTime(2026, 11, 3, 18)), 'Cours demain à 18:00');
    // Demain, meme a moins de 24 h.
    expect(
      _compte(DateTime(2026, 11, 2, 23), DateTime(2026, 11, 3, 1, 30)),
      'Cours demain à 01:30',
    );
    expect(_compte(lundi, DateTime(2026, 11, 2, 18)), 'Cours dans 3 h 05');
    expect(_compte(lundi, DateTime(2026, 11, 2, 15, 7)), 'Cours dans 12 min');
    // Sous une heure, les minutes, meme si le cours est demain.
    expect(
      _compte(DateTime(2026, 11, 2, 23, 50), DateTime(2026, 11, 3, 0, 20)),
      'Cours dans 30 min',
    );
    expect(
      _compte(lundi, lundi.add(const Duration(seconds: 30))),
      'Cours imminent',
    );
  });

  test('un jour au singulier, sans debut : des jours entiers', () {
    expect(
      _brut(LibellesGroupe.compteARebours(const Duration(hours: 30))),
      'Cours dans 1 jour',
    );
    expect(
      _brut(LibellesGroupe.compteARebours(const Duration(hours: 5))),
      'Cours dans 5 h 00',
    );
  });

  test('le passage a l heure d hiver ne retire pas un jour', () {
    // Nuit du 25 octobre 2026 en Europe : quel que soit le fuseau de la
    // machine, les jours sont des dates civiles.
    expect(
      _compte(DateTime(2026, 10, 24, 20), DateTime(2026, 10, 26, 20)),
      'Cours dans 2 jours',
    );
  });

  test('en arabe : le pluriel slang et « demain »', () async {
    // L'arabe est charge a la demande (import differe) : setLocale attend.
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(_compte(lundi, DateTime(2026, 11, 4, 9)), 'الدرس بعد يومين');
    expect(_compte(lundi, DateTime(2026, 11, 8, 18)), 'الدرس بعد 6 أيام');
    expect(
      _compte(lundi, DateTime(2026, 11, 3, 18)),
      'الدرس غدًا الساعة 18:00',
    );
  });
}
