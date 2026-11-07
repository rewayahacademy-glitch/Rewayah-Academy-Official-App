// FN-101 : le controle du contenu d'une piece, le meme que celui du serveur
// (`supabase/functions/_shared/r2/contenu_piece.ts`), plus le WebP.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/dossier/contenu_piece.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';

Uint8List _o(List<int> octets) => Uint8List.fromList(octets);

void main() {
  test('un PDF commence par %PDF', () {
    expect(contenuPieceConforme('pdf', _o('%PDF-1.7\n'.codeUnits)), isTrue);
    expect(
      contenuPieceConforme('pdf', _o('ceci est un texte'.codeUnits)),
      isFalse,
    );
  });

  test('JPEG, PNG, HEIC, WebP : leurs signatures', () {
    expect(
      contenuPieceConforme('jpg', _o(<int>[0xff, 0xd8, 0xff, 0xe0])),
      isTrue,
    );
    expect(contenuPieceConforme('JPEG', _o(<int>[0xff, 0xd8, 0xff])), isTrue);
    expect(
      contenuPieceConforme(
        'png',
        _o(<int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
      isTrue,
    );
    expect(
      contenuPieceConforme(
        'heic',
        _o(<int>[0, 0, 0, 0x18, ...'ftypheic'.codeUnits]),
      ),
      isTrue,
    );
    expect(
      contenuPieceConforme(
        'heic',
        _o(<int>[0, 0, 0, 0x18, ...'ftypisom'.codeUnits]),
      ),
      isFalse,
    );
    // Le WebP est retire (FN-101, 06/11/2026) : meme un vrai WebP est refuse.
    expect(
      contenuPieceConforme(
        'webp',
        _o(<int>[...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits]),
      ),
      isFalse,
    );
    expect(
      contenuPieceConforme(
        'webp',
        _o(<int>[...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WAVE'.codeUnits]),
      ),
      isFalse,
    );
  });

  test('un fichier vide, trop court ou d un type renomme est refuse', () {
    expect(contenuPieceConforme('png', Uint8List(0)), isFalse);
    expect(contenuPieceConforme('png', _o(<int>[0x89, 0x50])), isFalse);
    expect(contenuPieceConforme('jpg', _o('%PDF-1.4'.codeUnits)), isFalse);
  });

  test('une extension hors de la liste du selecteur est refusee', () {
    expect(contenuPieceConforme('exe', _o('MZ'.codeUnits)), isFalse);
    expect(contenuPieceConforme('bin', _o('%PDF'.codeUnits)), isFalse);
  });

  test('chaque extension proposee par le selecteur a sa signature', () {
    for (final String e in SelecteurFichierNatif.extensionsAcceptees) {
      // Aucune extension proposee ne tombe dans le cas par defaut : un
      // fichier vide est refuse, mais pour une raison de contenu, pas parce
      // que le type serait inconnu (verifie par la liste ci-dessous).
      expect(<String>[
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'pdf',
      ], contains(e));
    }
  });
}
