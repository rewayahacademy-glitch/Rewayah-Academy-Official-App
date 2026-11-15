// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : une photo HEIC d'iPhone est
// convertie en JPEG sur l'appareil avant l'envoi, et non refusee.
//
// Dans un navigateur qui sait decoder le HEIC (Safari sur iPhone, iPad et
// Mac, et tout navigateur d'iPhone, qui utilise le meme moteur), la photo est
// dessinee dans un canevas puis rendue en JPEG. Ailleurs (Chrome sur
// ordinateur ou Android, tests), la conversion rend `null` et la phrase de
// refus dit quoi faire.
library;

import 'dart:typed_data';

import 'conversion_heic_autre.dart'
    if (dart.library.js_interop) 'conversion_heic_web.dart'
    as natif;

/// La conversion de l'appareil (voir `ConvertisseurHeic`).
Future<Uint8List?> convertirHeicNatif(Uint8List heic, {required int coteMax}) =>
    natif.convertirHeic(heic, coteMax: coteMax);
