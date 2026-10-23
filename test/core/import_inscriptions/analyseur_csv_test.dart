// IMM-ACCUEIL-FRONT : le lecteur de CSV (guillemets, point-virgule et
// virgule, BOM, lignes vides) et la reecriture a virgules qui part au serveur.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/import_inscriptions/analyseur_csv.dart';
import 'package:rewayah_academy/features/admin_import_inscriptions/selecteur_csv.dart';

List<String> _cellules(TableCsv t, int i) => t.lignes[i].cellules;

void main() {
  group('separateur', () {
    test('la virgule est lue', () {
      final TableCsv t = AnalyseurCsv.lire('Nom,Prénom,Email\na,b,c@x.fr\n');
      expect(t.separateur, ',');
      expect(t.entetes, <String>['Nom', 'Prénom', 'Email']);
      expect(_cellules(t, 0), <String>['a', 'b', 'c@x.fr']);
    });

    test('le point-virgule d\'un tableur francais est devine', () {
      final TableCsv t = AnalyseurCsv.lire('Nom;Prénom;Email\na;b;c@x.fr\n');
      expect(t.separateur, ';');
      expect(t.entetes, <String>['Nom', 'Prénom', 'Email']);
      expect(_cellules(t, 0), <String>['a', 'b', 'c@x.fr']);
    });

    test(
      'une virgule dans une cellule d\'un fichier a point-virgule reste',
      () {
        final TableCsv t = AnalyseurCsv.lire(
          'Nom;Note\n"Diallo, Aminata";ok\n',
        );
        expect(t.separateur, ';');
        expect(_cellules(t, 0), <String>['Diallo, Aminata', 'ok']);
      },
    );

    test('un point-virgule entre guillemets ne decide pas du separateur', () {
      final TableCsv t = AnalyseurCsv.lire('"a;b",c\n1,2\n');
      expect(t.separateur, ',');
      expect(t.entetes, <String>['a;b', 'c']);
    });
  });

  group('guillemets', () {
    test('guillemet double echappe et saut de ligne dans une cellule', () {
      final TableCsv t = AnalyseurCsv.lire(
        'Nom,Note\r\n"Ali ""le grand""","ligne 1\r\nligne 2"\r\n',
      );
      expect(_cellules(t, 0), <String>['Ali "le grand"', 'ligne 1\r\nligne 2']);
      expect(t.lignes, hasLength(1));
    });

    test('une cellule vide entre guillemets est une cellule', () {
      final TableCsv t = AnalyseurCsv.lire('a,b,c\n"",x,""\n');
      expect(_cellules(t, 0), <String>['', 'x', '']);
    });

    test('un guillemet jamais ferme est signale', () {
      final TableCsv t = AnalyseurCsv.lire('a,b\n"x,y\n');
      expect(t.guillemetNonFerme, isTrue);
    });

    test('un guillemet au milieu d\'une cellule est garde', () {
      final TableCsv t = AnalyseurCsv.lire('a,b\n5" tube,x\n');
      expect(_cellules(t, 0), <String>['5" tube', 'x']);
      expect(t.guillemetNonFerme, isFalse);
    });
  });

  group('BOM et fins de ligne', () {
    test('la marque d\'ordre des octets est retiree de l\'en-tete', () {
      final TableCsv t = AnalyseurCsv.lire('﻿Email,Nom\nx@y.fr,A\n');
      expect(t.entetes.first, 'Email');
    });

    test('CRLF, LF et CR seul', () {
      for (final String fin in <String>['\r\n', '\n', '\r']) {
        final TableCsv t = AnalyseurCsv.lire('a,b${fin}1,2${fin}3,4');
        expect(t.lignes, hasLength(2), reason: 'fin ${fin.codeUnits}');
        expect(_cellules(t, 1), <String>['3', '4']);
      }
    });

    test('decoderCsv : UTF-8 puis Latin-1', () {
      expect(decoderCsv(<int>[0x50, 0xC3, 0xA9]), 'Pé');
      expect(decoderCsv(<int>[0x50, 0xE9]), 'Pé');
    });
  });

  group('lignes vides', () {
    test('ignorees, et la numerotation est celle du serveur', () {
      final TableCsv t = AnalyseurCsv.lire('a,b\n\n1,2\n\n\n3,4\n');
      expect(t.lignes.map((LigneCsv l) => l.numero), <int>[2, 3]);
    });

    test('une ligne de separateurs seuls est gardee mais vide', () {
      final TableCsv t = AnalyseurCsv.lire('a,b\n,\n1,2\n');
      expect(t.lignes, hasLength(2));
      expect(t.lignes.first.estVide, isTrue);
      expect(t.lignes.last.estVide, isFalse);
    });

    test('un texte vide ou fait d\'espaces et de sauts de ligne est vide', () {
      expect(AnalyseurCsv.lire('').estVide, isTrue);
      expect(AnalyseurCsv.lire('  \n\n \r\n').estVide, isTrue);
      expect(AnalyseurCsv.lire('﻿').estVide, isTrue);
    });

    test('seulement un en-tete : aucune ligne', () {
      final TableCsv t = AnalyseurCsv.lire('a,b\n');
      expect(t.estVide, isFalse);
      expect(t.lignes, isEmpty);
    });
  });

  group('reecriture pour le serveur', () {
    test(
      'un fichier a point-virgule repart en virgules, guillemets compris',
      () {
        final TableCsv t = AnalyseurCsv.lire(
          'Nom;Note\n"Diallo, Aminata";"dit ""Ami"""\n',
        );
        expect(t.versCsv(), 'Nom,Note\r\n"Diallo, Aminata","dit ""Ami"""\r\n');
      },
    );

    test('relire ce qui a ete reecrit rend la meme table', () {
      const String source =
          'Email;Nom\n"a@x.fr";"Ali ""l\'aine"""\nb@x.fr;"deux\nlignes"\n';
      final TableCsv une = AnalyseurCsv.lire(source);
      final TableCsv deux = AnalyseurCsv.lire(une.versCsv());
      expect(deux.entetes, une.entetes);
      expect(
        deux.lignes.map((LigneCsv l) => l.cellules).toList(),
        une.lignes.map((LigneCsv l) => l.cellules).toList(),
      );
      expect(deux.separateur, ',');
    });

    test('les lignes vides ne partent pas', () {
      expect(AnalyseurCsv.lire('a,b\n\n1,2\n').versCsv(), 'a,b\r\n1,2\r\n');
    });

    test('une table vide ne produit rien', () {
      expect(TableCsv.vide.versCsv(), '');
    });
  });
}
