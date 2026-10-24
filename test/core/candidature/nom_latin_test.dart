import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/nom_latin.dart';

void main() {
  group('nomEstLatin (meme definition que le serveur)', () {
    test('des noms latins', () {
      for (final String nom in <String>[
        'Ahmed Ben Ali',
        "Jean-Pierre O'Neil",
        'François Núñez',
        'Łukasz Nowak',
        'Nguyễn Văn An',
        'Abdel Rahman 2',
        'Créme',
      ]) {
        expect(nomEstLatin(nom), isTrue, reason: nom);
      }
    });

    test('des noms qui ne le sont pas', () {
      for (final String nom in <String>[
        'أحمد',
        'Ahmed أحمد',
        'Нина',
        '123 45',
        '',
        '   ',
      ]) {
        expect(nomEstLatin(nom), isFalse, reason: nom);
      }
    });

    test("la question n'est posee que pour une autre ecriture", () {
      expect(nomDemandeEcritureLatine('أحمد بن علي'), isTrue);
      expect(nomDemandeEcritureLatine('Bilal الحبشي'), isTrue);
      expect(nomDemandeEcritureLatine('Ahmed Ben Ali'), isFalse);
      expect(nomDemandeEcritureLatine(''), isFalse);
      expect(nomDemandeEcritureLatine('   '), isFalse);
    });
  });

  group('proposerNomLatin (une proposition, jamais imposee)', () {
    test('un nom deja latin est rendu tel quel, blancs nettoyes', () {
      expect(proposerNomLatin('  Ahmed   Ben  Ali '), 'Ahmed Ben Ali');
      expect(proposerNomLatin(''), '');
    });

    test('les mots courants prennent leur ecriture usuelle', () {
      expect(proposerNomLatin('محمد بن علي'), 'Mohamed Ben Ali');
      expect(proposerNomLatin('أحمد'), 'Ahmed');
      expect(proposerNomLatin('فاطمة الزهراء'), 'Fatima Al-Zahra');
    });

    test("l'article se detache par un trait d'union", () {
      expect(proposerNomLatin('يوسف الدوسري'), 'Youssef Al-Dousari');
    });

    test('un mot sans voyelles breves recoit un « a » entre consonnes', () {
      expect(proposerNomLatin('حبشي'), 'Habashi');
      expect(proposerNomLatin('كريم'), 'Karim');
    });

    test('les voyelles breves, quand elles sont ecrites, sont gardees', () {
      expect(proposerNomLatin('كَرِيم'), 'Karim');
      expect(proposerNomLatin('مُحَمَّد'), 'Mohamed');
    });

    test('un nom mixte garde sa partie latine', () {
      expect(proposerNomLatin('Bilal الحبشي'), 'Bilal Al-Habashi');
    });

    test("la proposition d'un nom arabe est un nom latin", () {
      for (final String nom in <String>[
        'محمد بن علي',
        'فاطمة الزهراء',
        'يوسف الدوسري',
        'عبد الرحمن',
        'نور',
        'سلمى',
      ]) {
        final String proposition = proposerNomLatin(nom);
        expect(nomEstLatin(proposition), isTrue, reason: '$nom : $proposition');
      }
    });

    test("ce qui n'est ni arabe ni latin n'est pas invente", () {
      expect(nomEstLatin(proposerNomLatin('Нина')), isFalse);
    });

    test('nettoyage des blancs', () {
      expect(nomLatinNettoye('  Ahmed   Ben '), 'Ahmed Ben');
    });
  });
}
