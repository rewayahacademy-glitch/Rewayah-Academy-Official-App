// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : la liste fermee des formats
// que la direction sait afficher, appliquee au depot (application) et sur les
// seaux (serveur), avec la conversion d'une photo HEIC en JPEG.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/fichiers/formats_admis.dart';
import 'package:rewayah_academy/core/fichiers/phrase_refus_fichier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

Uint8List _o(List<int> octets) => Uint8List.fromList(octets);

final Uint8List _jpeg = _o(<int>[0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
final Uint8List _png = _o(<int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0,
]);
final Uint8List _webp = _o(<int>[
  ...'RIFF'.codeUnits,
  0,
  0,
  0,
  0,
  ...'WEBP'.codeUnits,
]);
final Uint8List _heic = _o(<int>[0, 0, 0, 0x18, ...'ftypheic'.codeUnits, 0, 0]);
final Uint8List _pdf = _o('%PDF-1.7\n'.codeUnits);

Future<Uint8List?> _versJpeg(Uint8List _, {required int coteMax}) async =>
    _jpeg;
Future<Uint8List?> _jamais(Uint8List _, {required int coteMax}) async => null;

Future<CauseRefusFichier?> _refus(
  Uint8List octets,
  SorteFichier sorte, {
  ConvertisseurHeic convertir = _versJpeg,
}) async {
  try {
    await preparerFichier(octets, sorte: sorte, convertir: convertir);
    return null;
  } on FichierRefuse catch (r) {
    return r.cause;
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('le format se lit dans les octets, jamais dans le nom', () {
    expect(formatDepuisOctets(_jpeg), FormatFichier.jpeg);
    expect(formatDepuisOctets(_png), FormatFichier.png);
    expect(formatDepuisOctets(_webp), FormatFichier.webp);
    expect(formatDepuisOctets(_heic), FormatFichier.heic);
    expect(formatDepuisOctets(_pdf), FormatFichier.pdf);
    expect(formatDepuisOctets(_o('MZ'.codeUnits)), FormatFichier.inconnu);
    expect(formatDepuisOctets(Uint8List(0)), FormatFichier.inconnu);
  });

  test(
    'piece : JPEG et PNG passent, PDF, WebP et le reste sont refuses',
    () async {
      expect(await _refus(_jpeg, SorteFichier.piece), isNull);
      expect(await _refus(_png, SorteFichier.piece), isNull);
      expect(await _refus(_pdf, SorteFichier.piece), CauseRefusFichier.format);
      expect(await _refus(_webp, SorteFichier.piece), CauseRefusFichier.format);
      expect(
        await _refus(_o('MZ'.codeUnits), SorteFichier.piece),
        CauseRefusFichier.format,
      );
    },
  );

  test('photo : JPEG, PNG et WebP passent, le PDF est refuse', () async {
    expect(await _refus(_webp, SorteFichier.photo), isNull);
    expect(await _refus(_pdf, SorteFichier.photo), CauseRefusFichier.format);
  });

  test('une photo HEIC est convertie en JPEG, et non refusee', () async {
    int? cote;
    final FichierPret pret = await preparerFichier(
      _heic,
      sorte: SorteFichier.piece,
      convertir: (Uint8List _, {required int coteMax}) async {
        cote = coteMax;
        return _jpeg;
      },
    );
    expect(pret.format, FormatFichier.jpeg);
    expect(pret.converti, isTrue);
    expect(pret.octets, _jpeg);
    expect(pret.nomFichier('piece'), 'piece.jpg');
    expect(cote, SorteFichier.piece.coteMaxConversion);
  });

  test(
    'HEIC que l appareil ne sait pas convertir : refus qui dit quoi faire',
    () async {
      expect(
        await _refus(_heic, SorteFichier.piece, convertir: _jamais),
        CauseRefusFichier.heicNonConverti,
      );
      // Une conversion qui rend autre chose qu'un JPEG ne passe pas pour une.
      expect(
        await _refus(
          _heic,
          SorteFichier.photo,
          convertir: (Uint8List _, {required int coteMax}) async => _heic,
        ),
        CauseRefusFichier.heicNonConverti,
      );
      expect(
        await _refus(
          _heic,
          SorteFichier.photo,
          convertir: (Uint8List _, {required int coteMax}) =>
              Future<Uint8List?>.error(StateError('decodeur')),
        ),
        CauseRefusFichier.heicNonConverti,
      );
    },
  );

  test('trop lourd : refuse avant l envoi', () async {
    final Uint8List lourd = Uint8List(SorteFichier.photo.tailleMaxOctets + 1)
      ..setAll(0, _jpeg);
    expect(
      await _refus(lourd, SorteFichier.photo),
      CauseRefusFichier.tropLourd,
    );
    expect(await _refus(lourd, SorteFichier.piece), isNull);
  });

  test('chaque refus a sa phrase (K-59)', () {
    for (final SorteFichier sorte in SorteFichier.values) {
      for (final CauseRefusFichier cause in CauseRefusFichier.values) {
        expect(phraseRefusFichier(FichierRefuse(cause, sorte)), isNotEmpty);
      }
    }
    expect(
      phraseRefusFichier(
        const FichierRefuse(CauseRefusFichier.tropLourd, SorteFichier.piece),
      ),
      contains('8'),
    );
  });

  test('la boite de choix ne propose ni HEIC ni PDF', () {
    expect(SelecteurFichierNatif.extensionsAcceptees, <String>[
      'jpg',
      'jpeg',
      'png',
    ]);
    expect(SelecteurPhotoNatif.extensionsAcceptees, <String>[
      'jpg',
      'jpeg',
      'png',
      'webp',
    ]);
  });

  test(
    'preparerPiece et preparerPhoto nomment le fichier par son format',
    () async {
      final PieceAEnvoyer piece = await preparerPiece(
        _heic,
        TypePiece.passeport,
        _versJpeg,
      );
      expect(piece.extension, 'jpg');
      final PhotoEnfant photo = await preparerPhoto(_webp, _versJpeg);
      expect(photo.typeMime, 'image/webp');
    },
  );

  test('ce qui est admis au depot s affiche dans la visionneuse', () {
    for (final FormatFichier f in SorteFichier.piece.admis) {
      expect(
        RevueDossiersDepuisValidation.typeImage('p/piece.${f.extension}'),
        f.typeMime,
        reason: '${f.name} admis mais non affiche',
      );
    }
  });

  test('les tailles de l application et du serveur sont les memes', () {
    expect(
      SorteFichier.piece.tailleMaxOctets,
      ServiceDossier.tailleMaximaleOctets,
    );
    expect(
      SorteFichier.photo.tailleMaxOctets,
      ServiceAvatar.tailleMaximaleOctets,
    );
    final String sql = File(
      'supabase/migrations/20261126800000_complement_et_formats.sql',
    ).readAsStringSync();
    String liste(SorteFichier s) =>
        "ARRAY[${s.typesMime.map((String m) => "'$m'").join(', ')}]";
    expect(
      sql,
      contains('SET allowed_mime_types = ${liste(SorteFichier.piece)},'),
    );
    expect(
      sql,
      contains('file_size_limit = ${SorteFichier.piece.tailleMaxOctets}'),
    );
    expect(
      sql,
      contains('SET allowed_mime_types = ${liste(SorteFichier.photo)},'),
    );
    expect(
      sql,
      contains('file_size_limit = ${SorteFichier.photo.tailleMaxOctets}'),
    );
  });
}
