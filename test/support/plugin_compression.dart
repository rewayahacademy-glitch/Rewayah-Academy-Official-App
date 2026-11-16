import 'package:flutter/services.dart';
// Le plugin natif est simule : sa mise en oeuvre commune porte le canal.
// ignore: depend_on_referenced_packages
import 'package:flutter_image_compress_common/flutter_image_compress_common.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'image_png.dart';

/// Simule `flutter_image_compress` : chaque demande rend une image de la
/// taille demandee. Retire la simulation a la fin du test.
void simulerPluginCompression() {
  const MethodChannel canal = MethodChannel('flutter_image_compress');
  FlutterImageCompressPlatform.instance = FlutterImageCompressCommon();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, (MethodCall appel) async {
        if (appel.method != 'compressWithList') return true;
        final List<Object?> args = appel.arguments as List<Object?>;
        return fabriquerPng(args[1]! as int, args[2]! as int);
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null),
  );
}
