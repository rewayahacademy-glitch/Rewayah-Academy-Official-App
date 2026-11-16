import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'compression_image.dart';

/// `Blob`, reduit a son constructeur.
@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parties);
}

@JS('URL.createObjectURL')
external String _creerAdresse(_Blob blob);

@JS('URL.revokeObjectURL')
external void _oublierAdresse(String adresse);

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external JSObject createElement(String nom);
}

extension type _Image._(JSObject _) implements JSObject {
  external set src(String valeur);
  external int get naturalWidth;
  external int get naturalHeight;
  external JSPromise<JSAny?> decode();
}

extension type _Canevas._(JSObject _) implements JSObject {
  external set width(int valeur);
  external set height(int valeur);
  external _Contexte? getContext(String sorte);
  external String toDataURL(String type, num qualite);
}

extension type _Contexte._(JSObject _) implements JSObject {
  external void drawImage(JSObject image, num x, num y, num l, num h);
  external _DonneesImage getImageData(num x, num y, num l, num h);
}

extension type _DonneesImage._(JSObject _) implements JSObject {
  external JSUint8ClampedArray get data;
}

const String _prefixeJpeg = 'data:image/jpeg;base64,';

/// Dans un navigateur : JPEG, la qualite se regle.
bool get qualiteReglable => true;

/// Le navigateur decode la photo (l'orientation EXIF est appliquee par lui),
/// la dessine dans un canevas reduit a [coteMax], et la rend en JPEG a
/// [qualite]. Un canevas ne porte ni EXIF ni GPS. La couleur moyenne se lit
/// en dessinant l'image sur un canevas de 1 x 1 point. La photo ne quitte pas
/// l'appareil.
Future<ReductionImage?> reduire(
  Uint8List source, {
  required int coteMax,
  required double qualite,
  required bool couleur,
}) async {
  String? adresse;
  try {
    adresse = _creerAdresse(_Blob(<JSAny>[source.toJS].toJS));
    final _Image image = _Image._(_document.createElement('img'));
    image.src = adresse;
    await image.decode().toDart;
    final int largeur = image.naturalWidth;
    final int hauteur = image.naturalHeight;
    if (largeur <= 0 || hauteur <= 0) return null;
    final int plus = largeur > hauteur ? largeur : hauteur;
    final double echelle = plus > coteMax ? coteMax / plus : 1;
    final int l = (largeur * echelle).round().clamp(1, coteMax);
    final int h = (hauteur * echelle).round().clamp(1, coteMax);
    final _Canevas canevas = _Canevas._(_document.createElement('canvas'))
      ..width = l
      ..height = h;
    final _Contexte? contexte = canevas.getContext('2d');
    if (contexte == null) return null;
    contexte.drawImage(image, 0, 0, l, h);
    final String donnees = canevas.toDataURL('image/jpeg', qualite);
    if (!donnees.startsWith(_prefixeJpeg)) return null;
    String? moyenne;
    if (couleur) {
      final _Canevas un = _Canevas._(_document.createElement('canvas'))
        ..width = 1
        ..height = 1;
      final _Contexte? c1 = un.getContext('2d');
      if (c1 != null) {
        c1.drawImage(image, 0, 0, 1, 1);
        final Uint8ClampedList px = c1.getImageData(0, 0, 1, 1).data.toDart;
        moyenne = couleurHex(px[0], px[1], px[2]);
      }
    }
    return ReductionImage(
      octets: base64Decode(donnees.substring(_prefixeJpeg.length)),
      mime: 'image/jpeg',
      largeur: l,
      hauteur: h,
      couleurMoyenne: moyenne,
    );
  } on Object {
    return null;
  } finally {
    if (adresse != null) _oublierAdresse(adresse);
  }
}
