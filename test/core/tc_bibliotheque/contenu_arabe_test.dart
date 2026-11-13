// Directeur, 13/11/2026 : tout l'arabe de CONTENU dans la police du Coran. Le
// repere est pur : il lit le texte, jamais la langue de l'interface.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/contenu_arabe.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';

void main() {
  test('l\'arabe est reconnu, le francais et les chiffres non', () {
    expect(contientArabe('القرآن الكريم'), isTrue);
    expect(contientArabe('أحكام التجويد'), isTrue);
    expect(contientArabe('Les règles du Noun sākin'), isFalse);
    expect(contientArabe('Leçon 12'), isFalse);
    expect(contientArabe(''), isFalse);
    // Un titre mixte contient de l'arabe : il passe dans la police du Coran,
    // le latin retombant sur les polices de repli.
    expect(contientArabe('Tajwid : أحكام'), isTrue);
  });

  test('un texte arabe prend la police du Coran, avec un repli', () {
    const TextStyle base = TextStyle(fontSize: 18, fontFamily: 'DMSans');
    final TextStyle? s = styleContenuArabe('القرآن الكريم', base);
    expect(s?.fontFamily, AppFontFamily.arabeMushaf);
    expect(s?.fontFamilyFallback, contains(AppFontFamily.arabeDocument));
    expect(s?.fontFamilyFallback, contains(AppFontFamily.corps));
    expect(s?.fontSize, 18);
  });

  test('un texte sans arabe garde son style, tel quel', () {
    const TextStyle base = TextStyle(fontSize: 18, fontFamily: 'DMSans');
    expect(
      identical(styleContenuArabe('Le livre de lecture', base), base),
      isTrue,
    );
    expect(styleContenuArabe('Le livre', null), isNull);
  });

  test('le sens droite-gauche suit la premiere lettre forte', () {
    expect(commenceParArabe('شرح مبسط.'), isTrue);
    expect(commenceParArabe('  ١٢ أحكام'), isTrue);
    expect(commenceParArabe('Leçon : أحكام'), isFalse);
    expect(commenceParArabe('12 Leçon'), isFalse);
    expect(commenceParArabe(''), isFalse);
  });
}
