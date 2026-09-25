import 'dart:convert';
import 'dart:io';

// Usage: dart ecoute.dart <ws-url> <dossier>
// Etiquette courante lue dans <dossier>/phase.txt ; arret si <dossier>/stop existe.
Future<void> main(List<String> a) async {
  final ws = await WebSocket.connect(a[0]);
  final dir = a[1];
  final out = File('$dir/frames.csv').openWrite(mode: FileMode.append);
  ws.add(jsonEncode({'jsonrpc': '2.0', 'id': '1', 'method': 'streamListen', 'params': {'streamId': 'Extension'}}));
  ws.listen((m) {
    final j = jsonDecode(m as String);
    if (j['method'] == 'streamNotify') {
      final e = j['params']['event'];
      if (e['extensionKind'] == 'Flutter.Frame') {
        final d = e['extensionData'];
        String phase = 'aucune';
        try { phase = File('$dir/phase.txt').readAsStringSync().trim(); } catch (_) {}
        out.writeln('$phase,${d['number']},${d['build']},${d['raster']},${d['elapsed']}');
      }
    } else if (j['id'] == '1') {
      stdout.writeln('ECOUTE OK ${j['result'] ?? j['error']}');
    }
  });
  while (!File('$dir/stop').existsSync()) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  await out.flush();
  await out.close();
  await ws.close();
  exit(0);
}
