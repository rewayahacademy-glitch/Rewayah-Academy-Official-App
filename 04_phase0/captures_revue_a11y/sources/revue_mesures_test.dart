// Revue independante : mesures de rendu (copie de ce qui a tourne dans le
// worktree jetable HEAD 125fe78, test/_revue_tmp/, supprime ensuite).
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

Future<void> _polices() async {
  final List<Object?> familles =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<Object?>;
  for (final Object? entree in familles) {
    final Map<String, Object?> f = entree! as Map<String, Object?>;
    final FontLoader c = FontLoader(f['family']! as String);
    for (final Object? a in f['fonts']! as List<Object?>) {
      c.addFont(rootBundle.load((a! as Map<String, Object?>)['asset']! as String));
    }
    await c.load();
  }
}

double _largeur(TextStyle s, String texte) {
  final TextPainter p = TextPainter(
    text: TextSpan(text: texte, style: s),
    textDirection: TextDirection.ltr,
  )..layout();
  final double l = p.width;
  p.dispose();
  return l;
}

/// Nombre de pixels encres (alpha > 127) du texte rendu en noir.
Future<int> _encre(TextStyle s, String texte) async {
  final TextPainter p = TextPainter(
    text: TextSpan(text: texte, style: s.copyWith(color: const Color(0xFF000000))),
    textDirection: TextDirection.ltr,
  )..layout();
  final ui.PictureRecorder r = ui.PictureRecorder();
  final Canvas c = Canvas(r);
  p.paint(c, Offset.zero);
  final ui.Image img = await r.endRecording().toImage(
    p.width.ceil() + 4,
    p.height.ceil() + 4,
  );
  final ByteData? d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final Uint8List o = d!.buffer.asUint8List();
  int n = 0;
  for (int i = 3; i < o.length; i += 4) {
    if (o[i] > 127) n++;
  }
  img.dispose();
  p.dispose();
  return n;
}

TextStyle _wght(TextStyle s, double w, FontWeight fw) => s.copyWith(
  fontWeight: fw,
  fontVariations: <FontVariation>[
    FontVariation('wght', w),
    ...?s.fontVariations?.where((FontVariation v) => v.axis != 'wght'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_polices);

  test('MESURE poids : copyWith(fontWeight) sans wght (nav_shell 469/733/816)', () async {
    final TextTheme t = AppTheme.pour(InterfaceMode.standard, Brightness.light).textTheme;
    const String mot = 'Accueil Historique Compte Rewayah';
    final Map<String, (TextStyle, FontWeight, double)> cas =
        <String, (TextStyle, FontWeight, double)>{
          'labelMedium (barre basse, 469)': (t.labelMedium!, FontWeight.w600, 600),
          'titleLarge (mot-symbole, 733)': (t.titleLarge!, FontWeight.w700, 700),
          'bodyLarge (colonne, 816)': (t.bodyLarge!, FontWeight.w600, 600),
        };
    for (final MapEntry<String, (TextStyle, FontWeight, double)> e in cas.entries) {
      final TextStyle base = e.value.$1.copyWith(fontSize: 40);
      final TextStyle commeLeCode = base.copyWith(fontWeight: e.value.$2);
      final TextStyle correct = _wght(base, e.value.$3, e.value.$2);
      // ignore: avoid_print
      print(
        'MESURE ${e.key} : base largeur ${_largeur(base, mot).toStringAsFixed(1)} '
        'encre ${await _encre(base, mot)} | copyWith(fontWeight) largeur '
        '${_largeur(commeLeCode, mot).toStringAsFixed(1)} encre ${await _encre(commeLeCode, mot)} | '
        'wght + fontWeight largeur ${_largeur(correct, mot).toStringAsFixed(1)} '
        'encre ${await _encre(correct, mot)}',
      );
    }
  });

  test('MESURE apostrophe droite vs typographique', () async {
    final TextTheme t = AppTheme.pour(InterfaceMode.standard, Brightness.light).textTheme;
    for (final MapEntry<String, TextStyle> e in <String, TextStyle>{
      'bodyMedium Jakarta': t.bodyMedium!.copyWith(fontSize: 40),
      'titleMedium DM Sans': t.titleMedium!.copyWith(fontSize: 40),
    }.entries) {
      final double so = _largeur(e.value, 'so');
      // ignore: avoid_print
      print(
        'MESURE ${e.key} a 40 px : U+0027 ${(_largeur(e.value, "s'o") - so).toStringAsFixed(1)} px, '
        'U+2019 ${(_largeur(e.value, 's’o') - so).toStringAsFixed(1)} px, '
        'espace ${(_largeur(e.value, 's o') - so).toStringAsFixed(1)} px',
      );
    }
  });
}
