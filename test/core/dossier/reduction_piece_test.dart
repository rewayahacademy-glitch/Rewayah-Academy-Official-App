// PE-B10 : une piece trop lourde est reduite sur l'appareil, aux bornes de
// lisibilite, au lieu d'etre refusee ; une piece qui passe deja part telle
// quelle.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/fichiers/compression_image.dart';
import 'package:rewayah_academy/core/fichiers/formats_admis.dart';

Uint8List _jpegDe(int taille) {
  final Uint8List o = Uint8List(taille);
  o.setAll(0, <int>[0xff, 0xd8, 0xff, 0xe0]);
  return o;
}

Future<Uint8List?> _jamaisHeic(Uint8List _, {required int coteMax}) async =>
    null;

/// Un reducteur temoin : il retient chaque essai et rend une image de la
/// taille que [taillePour] donne pour ce cote.
class _Reducteur {
  _Reducteur(this.taillePour);

  final int? Function(int cote, double qualite) taillePour;
  final List<(int, double)> essais = <(int, double)>[];

  Future<ReductionImage?> call(
    Uint8List source, {
    required int coteMax,
    required double qualite,
    required bool couleur,
  }) async {
    essais.add((coteMax, qualite));
    final int? taille = taillePour(coteMax, qualite);
    if (taille == null) return null;
    return ReductionImage(
      octets: _jpegDe(taille),
      mime: 'image/jpeg',
      largeur: coteMax,
      hauteur: coteMax,
    );
  }
}

void main() {
  final int max = SorteFichier.piece.tailleMaxOctets;

  test('une piece sous la taille maximale part telle quelle', () async {
    final _Reducteur r = _Reducteur((_, _) => 1);
    final Uint8List source = _jpegDe(max);
    final PieceAEnvoyer p = await preparerPiece(
      source,
      TypePiece.passeport,
      _jamaisHeic,
      reduire: r.call,
    );
    expect(identical(p.octets, source), isTrue);
    expect(r.essais, isEmpty, reason: 'aucune reduction');
  });

  test('une piece de 12 Mo est reduite au premier essai qui tient', () async {
    final _Reducteur r = _Reducteur(
      (int cote, _) => cote >= 4000 ? max + 1 : max - 1,
    );
    final PieceAEnvoyer p = await preparerPiece(
      _jpegDe(12 * 1024 * 1024),
      TypePiece.passeport,
      _jamaisHeic,
      reduire: r.call,
    );
    expect(p.octets.length, max - 1);
    expect(p.extension, 'jpg');
    expect(r.essais, <(int, double)>[(4000, 0.9), (3200, 0.85)]);
  });

  test('jamais sous les bornes de lisibilite : refus avec la phrase de la '
      'taille', () async {
    final _Reducteur r = _Reducteur((_, _) => max + 1);
    await expectLater(
      preparerPiece(
        _jpegDe(12 * 1024 * 1024),
        TypePiece.passeport,
        _jamaisHeic,
        reduire: r.call,
      ),
      throwsA(
        isA<FichierRefuse>().having(
          (FichierRefuse f) => f.cause,
          'cause',
          CauseRefusFichier.tropLourd,
        ),
      ),
    );
    expect(r.essais, essaisReductionPiece);
    for (final (int cote, double qualite) in r.essais) {
      expect(cote, greaterThanOrEqualTo(2400));
      expect(qualite, greaterThanOrEqualTo(0.8));
    }
  });

  test('une source demesuree n est pas decodee', () async {
    final _Reducteur r = _Reducteur((_, _) => 1);
    await expectLater(
      preparerPiece(
        _jpegDe(sourcePieceMaxOctets + 1),
        TypePiece.passeport,
        _jamaisHeic,
        reduire: r.call,
      ),
      throwsA(isA<FichierRefuse>()),
    );
    expect(r.essais, isEmpty);
  });

  test(
    'un appareil qui ne sait pas lire la photo : refus de la taille',
    () async {
      final _Reducteur r = _Reducteur((_, _) => null);
      await expectLater(
        preparerPiece(
          _jpegDe(10 * 1024 * 1024),
          TypePiece.passeport,
          _jamaisHeic,
          reduire: r.call,
        ),
        throwsA(isA<FichierRefuse>()),
      );
    },
  );

  test('relecture M4 : une photo HEIC convertie mais trop lourde est reduite '
      'a partir du JPEG converti', () async {
    final Uint8List heic = Uint8List(12 * 1024 * 1024)
      ..setAll(0, 'xxxxftypheic'.codeUnits);
    final Uint8List jpegLourd = _jpegDe(max + 10);
    Uint8List? recu;
    final _Reducteur r = _Reducteur((_, _) => max - 1);
    final PieceAEnvoyer p = await preparerPiece(
      heic,
      TypePiece.passeport,
      (Uint8List _, {required int coteMax}) async => jpegLourd,
      reduire:
          (
            Uint8List source, {
            required int coteMax,
            required double qualite,
            required bool couleur,
          }) {
            recu = source;
            return r.call(
              source,
              coteMax: coteMax,
              qualite: qualite,
              couleur: couleur,
            );
          },
    );
    expect(identical(recu, jpegLourd), isTrue, reason: 'le JPEG converti');
    expect(p.extension, 'jpg');
    expect(p.octets.length, max - 1);
  });
}
