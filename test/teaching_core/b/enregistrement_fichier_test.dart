import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';

import 'faux/faux_ports_b.dart';

void main() {
  group('Nom de fichier propose', () {
    test('il garde la langue et les accents du titre', () {
      expect(
        nomFichierPropose('Règles du meem sâkinah', FormatArtefact.pdf),
        'Règles du meem sâkinah.pdf',
      );
    });

    test('il remplace ce qu un systeme de fichiers refuse', () {
      expect(
        nomFichierPropose('Tajwid / Niveau 2 : les regles', FormatArtefact.pdf),
        'Tajwid Niveau 2 les regles.pdf',
      );
    });

    test('un titre vide ne produit pas un fichier sans nom', () {
      expect(nomFichierPropose('   ', FormatArtefact.pdf), 'ressource.pdf');
    });

    test('un titre tres long est borne', () {
      final String nom = nomFichierPropose(
        'a' * 300,
        FormatArtefact.epub,
      );

      expect(nom.length, lessThanOrEqualTo(85));
      expect(nom.endsWith('.epub'), isTrue);
    });

    test('l extension suit le format', () {
      expect(
        nomFichierPropose('Alphabet', FormatArtefact.audio),
        'Alphabet.mp3',
      );
      expect(
        nomFichierPropose('Alphabet', FormatArtefact.image),
        'Alphabet.png',
      );
    });
  });

  group('Enregistrement : le selecteur systeme, et rien d autre', () {
    test('une renonciation rend null et ne produit aucune erreur', () async {
      final FauxEnregistrementFichier faux = FauxEnregistrementFichier(
        destinationRendue: null,
      );

      final String? destination = await faux.enregistrerCopie(
        octets: <int>[1, 2, 3],
        nomFichierPropose: 'Alphabet.pdf',
        typeMime: FormatArtefact.pdf.typeMime,
      );

      expect(destination, isNull);
      expect(faux.appels.single.nom, 'Alphabet.pdf');
      expect(faux.appels.single.mime, 'application/pdf');
    });

    test('le type MIME vient du format, pas d une chaine ecrite a la main',
        () {
      expect(FormatArtefact.pdf.typeMime, 'application/pdf');
      expect(FormatArtefact.epub.typeMime, 'application/epub+zip');
      expect(FormatArtefact.audio.typeMime, 'audio/mpeg');
      expect(FormatArtefact.image.typeMime, 'image/png');
    });
  });
}
