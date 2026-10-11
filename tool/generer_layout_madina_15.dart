// Genere la mise en page du Mushaf de Medine en 15 lignes (MUSHAF-15L) :
//
//   dart run tool/generer_layout_madina_15.dart \
//     --hafs=<chemin>/hafs.json --hizb=<chemin>/hizb.json
//
// Entrees (voir lib/core/tc_coran/donnees/LISEZMOI.md pour l'origine, les
// versions et les empreintes) :
//   - `hafs.json` du paquet npm @quran.ws/text 0.1.0 (CC-BY-4.0) : texte KFGQPC
//     UthmanicHafs v3.0, `page_starts`, `line_starts`, `surah_starts`,
//     `ayah_starts`, `juz_starts`, `marks` ; lignes validees par son auteur
//     contre hafsData_v2-0.csv du KFGQPC (6 236 versets sur 6 236) ;
//   - `hizb.json` : les 240 quarts de hizb (ids globaux de verset) extraits de
//     quran-meta 7.0.0 (MIT).
//
// Sorties (ne contiennent que la structure et le texte, aucun asset) :
//   lib/core/tc_coran/donnees/layout_madina_15_p1..p6.g.dart  (101 pages)
//   lib/core/tc_coran/donnees/layout_madina_15.g.dart         (index + sourates)
//
// Format d'une page : `juz;hizb;rub;quarts` puis une ligne par ligne imprimee,
// separees par `\n`.
//   `H;<sourate>`               cadre de sourate (centre)
//   `B;<sourate>`               basmala (centree)
//   `T;<flags>;<segment>¦...`   ligne de texte ; flags : bit0 = page 1 (lignes
//                               centrees), bit1 = la ligne termine une sourate
//   segment : `<sourate>:<verset>:<f>:<texte>` ; f : bit0 = le verset commence
//   ici, bit1 = il se termine ici (la rosace se pose apres).
// Le texte re-attache les signes de pause (`marks`) comme l'edition les imprime.
import 'dart:convert';
import 'dart:io';

const int _pagesParFichier = 101;

int _rang(List<int> croissant, int valeur) {
  // Dernier indice i tel que croissant[i] <= valeur.
  int bas = 0;
  int haut = croissant.length - 1;
  while (bas < haut) {
    final int milieu = (bas + haut + 1) >> 1;
    if (croissant[milieu] <= valeur) {
      bas = milieu;
    } else {
      haut = milieu - 1;
    }
  }
  return bas;
}

String? _arg(List<String> args, String nom) {
  for (final String a in args) {
    if (a.startsWith('--$nom=')) return a.substring(nom.length + 3);
  }
  return null;
}

void main(List<String> args) {
  final String? cheminHafs = _arg(args, 'hafs');
  final String? cheminHizb = _arg(args, 'hizb');
  if (cheminHafs == null || cheminHizb == null) {
    stderr.writeln('usage : --hafs=hafs.json --hizb=hizb.json');
    exit(64);
  }
  final Map<String, dynamic> d =
      jsonDecode(File(cheminHafs).readAsStringSync()) as Map<String, dynamic>;
  final List<int> quarts =
      ((jsonDecode(File(cheminHizb).readAsStringSync())
                  as Map<String, dynamic>)['quarters']
              as List<dynamic>)
          .cast<int>();

  final List<String> mots = (d['words'] as List<dynamic>).cast<String>();
  final List<int> debutsSourates = (d['surah_starts'] as List<dynamic>)
      .cast<int>();
  final List<int> debutsVersets = (d['ayah_starts'] as List<dynamic>)
      .cast<int>();
  final List<int> debutsPages = (d['page_starts'] as List<dynamic>).cast<int>();
  final List<int> debutsLignes = (d['line_starts'] as List<dynamic>)
      .cast<int>();
  final List<int> debutsJuz = (d['juz_starts'] as List<dynamic>).cast<int>();
  final List<dynamic> typesSignes = d['mark_types'] as List<dynamic>;
  final List<dynamic> signes = d['marks'] as List<dynamic>;
  final List<dynamic> sourates = d['surahs'] as List<dynamic>;

  // Signes de pause par mot, dans l'ordre de la source.
  final Map<int, List<Map<String, dynamic>>> signesParMot =
      <int, List<Map<String, dynamic>>>{};
  for (final dynamic m in signes) {
    final List<dynamic> p = m as List<dynamic>;
    signesParMot
        .putIfAbsent(p[0] as int, () => <Map<String, dynamic>>[])
        .add(typesSignes[p[1] as int] as Map<String, dynamic>);
  }

  String texteMot(int i) {
    final StringBuffer s = StringBuffer();
    final List<Map<String, dynamic>> avant = <Map<String, dynamic>>[
      for (final Map<String, dynamic> m
          in signesParMot[i] ?? const <Map<String, dynamic>>[])
        if (m['side'] == 'before') m,
    ];
    for (final Map<String, dynamic> m in avant) {
      s
        ..write(m['sign'])
        ..write(' ');
    }
    s.write(mots[i]);
    for (final Map<String, dynamic> m
        in signesParMot[i] ?? const <Map<String, dynamic>>[]) {
      if (m['side'] == 'after') s.write(m['sign']);
    }
    return s.toString();
  }

  // Identifiant de verset (sourate, rang) de chaque debut de verset.
  final List<int> sourateDeVerset = <int>[];
  final List<int> rangDeVerset = <int>[];
  for (int s = 0; s < sourates.length; s++) {
    final Map<String, dynamic> info = sourates[s] as Map<String, dynamic>;
    for (int a = 1; a <= (info['ayah_count'] as int); a++) {
      sourateDeVerset.add(s + 1);
      rangDeVerset.add(a);
    }
  }
  if (sourateDeVerset.length != 6236 || debutsVersets.length != 6236) {
    throw StateError('6236 versets attendus');
  }
  // Debut de sourate -> index du premier verset (mot de debut de sourate).
  final Set<int> motsDebutSourate = debutsSourates.toSet();

  // Fin de sourate : mot dernier de la sourate.
  final Set<int> motsFinSourate = <int>{
    for (int s = 1; s < debutsSourates.length; s++) debutsSourates[s] - 1,
    mots.length - 1,
  };

  final int nbLignes = debutsLignes.length;
  // Pages -> liste de lignes de texte (index dans debutsLignes).
  final List<List<int>> lignesParPage = List<List<int>>.generate(
    604,
    (_) => <int>[],
  );
  for (int l = 0; l < nbLignes; l++) {
    lignesParPage[_rang(debutsPages, debutsLignes[l])].add(l);
  }

  final List<String> pages = <String>[];
  int totalFinsVerset = 0;
  final Set<String> versetsVus = <String>{};
  for (int p = 0; p < 604; p++) {
    final int premierMot = debutsPages[p];
    final int idVerset = _rang(debutsVersets, premierMot);
    final int idGlobal = idVerset + 1; // 1-based
    final int juz = _rang(debutsJuz, premierMot) + 1;
    int q = 1;
    for (int k = 1; k <= 240; k++) {
      if (quarts[k] <= idGlobal) q = k;
    }
    final int hizb = (q - 1) ~/ 4 + 1;
    final int rub = (q - 1) % 4;
    final int motFin = p == 603 ? mots.length : debutsPages[p + 1];
    final List<int> quartsDeLaPage = <int>[
      for (int k = 1; k <= 240; k++)
        if (debutsVersets[quarts[k] - 1] >= premierMot &&
            debutsVersets[quarts[k] - 1] < motFin)
          k,
    ];
    final StringBuffer page = StringBuffer(
      '$juz;$hizb;$rub;${quartsDeLaPage.join(',')}',
    );

    for (final int l in lignesParPage[p]) {
      final int debut = debutsLignes[l];
      final int fin = l + 1 < nbLignes ? debutsLignes[l + 1] : mots.length;
      // Une sourate commence sur cette ligne : cadre, puis basmala.
      if (motsDebutSourate.contains(debut)) {
        final int numero = debutsSourates.indexOf(debut) + 1;
        page.write('\nH;$numero');
        if (numero != 1 && numero != 9) page.write('\nB;$numero');
      }
      final bool termineSourate = motsFinSourate.contains(fin - 1);
      final int flags = (p == 0 ? 1 : 0) | (termineSourate ? 2 : 0);
      final List<String> segments = <String>[];
      int i = debut;
      while (i < fin) {
        final int v = _rang(debutsVersets, i);
        final int finVerset = v + 1 < debutsVersets.length
            ? debutsVersets[v + 1]
            : mots.length;
        final int jusqua = finVerset < fin ? finVerset : fin;
        final bool commence = debutsVersets[v] == i;
        final bool termine = jusqua == finVerset;
        final String texte = <String>[
          for (int m = i; m < jusqua; m++) texteMot(m),
        ].join(' ');
        if (termine) {
          totalFinsVerset++;
          versetsVus.add('${sourateDeVerset[v]}:${rangDeVerset[v]}');
        }
        segments.add(
          '${sourateDeVerset[v]}:${rangDeVerset[v]}:'
          '${(commence ? 1 : 0) | (termine ? 2 : 0)}:$texte',
        );
        i = jusqua;
      }
      page.write('\nT;$flags;${segments.join('¦')}');
    }
    pages.add(page.toString());
  }
  if (totalFinsVerset != 6236 || versetsVus.length != 6236) {
    throw StateError('fins de verset : $totalFinsVerset');
  }

  for (final String p in pages) {
    if (p.contains("'") || p.contains(r'$') || p.contains(r'\')) {
      throw StateError('caractere interdit dans une chaine Dart');
    }
  }

  final Directory sortie = Directory('lib/core/tc_coran/donnees')
    ..createSync(recursive: true);
  const String entete =
      '// GENERE par tool/generer_layout_madina_15.dart : ne pas modifier a la main.\n'
      '// Origine, versions, empreintes et licences : donnees/LISEZMOI.md.\n'
      '// ignore_for_file: lines_longer_than_80_chars\n\n';
  final int fichiers = (604 / _pagesParFichier).ceil();
  for (int f = 0; f < fichiers; f++) {
    final StringBuffer s = StringBuffer(entete)
      ..writeln(
        '/// Pages ${f * _pagesParFichier + 1} a '
        '${((f + 1) * _pagesParFichier).clamp(1, 604)}.',
      )
      ..writeln('const List<String> layoutMadina15Pages${f + 1} = <String>[');
    for (
      int p = f * _pagesParFichier;
      p < ((f + 1) * _pagesParFichier).clamp(0, 604);
      p++
    ) {
      s.writeln("  '${pages[p].replaceAll('\n', r'\n')}',");
    }
    s.writeln('];');
    File('${sortie.path}/layout_madina_15_p${f + 1}.g.dart')
        .writeAsStringSync(s.toString());
  }

  final StringBuffer idx = StringBuffer(entete);
  for (int f = 1; f <= fichiers; f++) {
    idx.writeln("import 'layout_madina_15_p$f.g.dart';");
  }
  idx
    ..writeln()
    ..writeln('/// Les 604 pages, de la page 1 a la page 604.')
    ..writeln('const List<String> layoutMadina15Pages = <String>[');
  for (int f = 1; f <= fichiers; f++) {
    idx.writeln('  ...layoutMadina15Pages$f,');
  }
  idx
    ..writeln('];')
    ..writeln()
    ..writeln(
      '/// Les noms arabes des 114 sourates (KFGQPC), du rang 1 au rang 114.',
    )
    ..writeln('const List<String> layoutMadina15NomsSourates = <String>[');
  for (final dynamic s in sourates) {
    final String nom = (s as Map<String, dynamic>)['name_ar'] as String;
    idx.writeln("  '$nom',");
  }
  idx.writeln('];');
  File('${sortie.path}/layout_madina_15.g.dart')
      .writeAsStringSync(idx.toString());
  stdout.writeln(
    '604 pages, $nbLignes lignes de texte, $totalFinsVerset fins de verset',
  );
}
