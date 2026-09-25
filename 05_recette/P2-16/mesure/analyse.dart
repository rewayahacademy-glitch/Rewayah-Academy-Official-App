import 'dart:io';

double p90(List<double> v) {
  final s = [...v]..sort();
  return s[((s.length - 1) * 0.9).round()];
}

void main(List<String> a) {
  final lignes = File(a[0]).readAsLinesSync().where((l) => l.trim().isNotEmpty);
  final par = <String, List<List<double>>>{};
  for (final l in lignes) {
    final c = l.split(',');
    par.putIfAbsent(c[0], () => []).add([double.parse(c[2]) / 1000, double.parse(c[3]) / 1000, double.parse(c[4]) / 1000]);
  }
  stdout.writeln('parcours | images | build moy | build p90 | raster moy | raster p90 | max build | max raster | % lentes (build ou raster > 16,7)');
  par.forEach((k, v) {
    final b = v.map((x) => x[0]).toList();
    final r = v.map((x) => x[1]).toList();
    double moy(List<double> x) => x.reduce((p, q) => p + q) / x.length;
    double mx(List<double> x) => x.reduce((p, q) => p > q ? p : q);
    final lentes = v.where((x) => x[0] > 16.7 || x[1] > 16.7).length;
    String f(double x) => x.toStringAsFixed(1);
    stdout.writeln('$k | ${v.length} | ${f(moy(b))} | ${f(p90(b))} | ${f(moy(r))} | ${f(p90(r))} | ${f(mx(b))} | ${f(mx(r))} | ${f(100 * lentes / v.length)} % ($lentes)');
  });
}
