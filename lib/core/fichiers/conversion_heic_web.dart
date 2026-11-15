import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

/// `Blob`, reduit a son constructeur.
@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parties, _OptionsBlob options);
}

/// Les options d'un `Blob` (objet litteral).
extension type _OptionsBlob._(JSObject _) implements JSObject {
  external factory _OptionsBlob({String type});
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

/// `HTMLImageElement`, reduit a ce qui sert.
extension type _Image._(JSObject _) implements JSObject {
  external set src(String valeur);
  external int get naturalWidth;
  external int get naturalHeight;
  external JSPromise<JSAny?> decode();
}

/// `HTMLCanvasElement`, reduit a ce qui sert.
extension type _Canevas._(JSObject _) implements JSObject {
  external set width(int valeur);
  external set height(int valeur);
  external _Contexte? getContext(String sorte);
  external String toDataURL(String type, num qualite);
}

/// `CanvasRenderingContext2D`, reduit au dessin d'une image.
extension type _Contexte._(JSObject _) implements JSObject {
  external void drawImage(JSObject image, num x, num y, num l, num h);
}

const String _prefixeJpeg = 'data:image/jpeg;base64,';

/// Dans un navigateur : la photo HEIC est decodee par le navigateur, dessinee
/// dans un canevas (plus grand cote ramene a [coteMax]) puis rendue en JPEG.
/// `null` quand le navigateur ne sait pas la decoder (Chrome hors iPhone).
/// La photo ne quitte jamais l'appareil pendant la conversion.
Future<Uint8List?> convertirHeic(Uint8List heic, {required int coteMax}) async {
  String? adresse;
  try {
    final _Blob blob = _Blob(
      <JSAny>[heic.toJS].toJS,
      _OptionsBlob(type: 'image/heic'),
    );
    adresse = _creerAdresse(blob);
    final _Image image = _Image._(_document.createElement('img'));
    image.src = adresse;
    await image.decode().toDart;
    final int largeur = image.naturalWidth;
    final int hauteur = image.naturalHeight;
    if (largeur <= 0 || hauteur <= 0) return null;
    final int plusGrand = largeur > hauteur ? largeur : hauteur;
    final double echelle = plusGrand > coteMax ? coteMax / plusGrand : 1;
    final int l = (largeur * echelle).round();
    final int h = (hauteur * echelle).round();
    final _Canevas canevas = _Canevas._(_document.createElement('canvas'))
      ..width = l
      ..height = h;
    final _Contexte? contexte = canevas.getContext('2d');
    if (contexte == null) return null;
    contexte.drawImage(image, 0, 0, l, h);
    final String donnees = canevas.toDataURL('image/jpeg', 0.9);
    if (!donnees.startsWith(_prefixeJpeg)) return null;
    return base64Decode(donnees.substring(_prefixeJpeg.length));
  } on Object {
    return null;
  } finally {
    if (adresse != null) _oublierAdresse(adresse);
  }
}
