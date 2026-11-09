import 'dart:io';
import 'dart:typed_data';

/// Un axe variable lu dans la table `fvar` d'un fichier de police.
class AxePolice {
  /// Cree un axe.
  const AxePolice(this.etiquette, this.min, this.defaut, this.max);

  /// Etiquette OpenType, par exemple `wght` ou `opsz`.
  final String etiquette;

  /// Borne basse.
  final double min;

  /// Valeur par defaut, celle que sort un style qui ne pose pas l'axe.
  final double defaut;

  /// Borne haute.
  final double max;
}

/// Lecture minimale des tables OpenType d'un fichier de police embarque.
///
/// Ce n'est pas un analyseur complet : il lit juste ce que les tests de theme
/// doivent prouver sur les binaires, et non sur la foi d'un commentaire. Les
/// axes (`fvar`), les fonctions typographiques (`GSUB`), la couverture des
/// caracteres (`cmap`, formats 4 et 12) et les metriques verticales (`hhea`).
class LecteurPolice {
  /// Lit le fichier [chemin], relatif a la racine du depot.
  LecteurPolice(String chemin) : this._(File(chemin).readAsBytesSync());

  LecteurPolice._(this._octets) : _d = ByteData.sublistView(_octets) {
    final int n = _d.getUint16(4);
    for (int i = 0; i < n; i++) {
      final int r = 12 + 16 * i;
      _tables[String.fromCharCodes(_octets.sublist(r, r + 4))] = _d.getUint32(
        r + 8,
      );
    }
  }

  final Uint8List _octets;
  final ByteData _d;
  final Map<String, int> _tables = <String, int>{};

  double _fixe(int p) => _d.getInt32(p) / 65536.0;

  /// Les axes variables, par etiquette. Vide pour une police statique.
  Map<String, AxePolice> get axes {
    final int? t = _tables['fvar'];
    if (t == null) {
      return const <String, AxePolice>{};
    }
    final int debut = t + _d.getUint16(t + 4);
    final int nombre = _d.getUint16(t + 8);
    final int taille = _d.getUint16(t + 10);
    final Map<String, AxePolice> axes = <String, AxePolice>{};
    for (int i = 0; i < nombre; i++) {
      final int a = debut + i * taille;
      final String etiquette = String.fromCharCodes(_octets.sublist(a, a + 4));
      axes[etiquette] = AxePolice(
        etiquette,
        _fixe(a + 4),
        _fixe(a + 8),
        _fixe(a + 12),
      );
    }
    return axes;
  }

  /// Les etiquettes de fonctions de la table `GSUB` (`tnum`, `liga`...).
  Set<String> get fonctions {
    final int? t = _tables['GSUB'];
    if (t == null) {
      return const <String>{};
    }
    final int liste = t + _d.getUint16(t + 6);
    final int n = _d.getUint16(liste);
    return <String>{
      for (int i = 0; i < n; i++)
        String.fromCharCodes(
          _octets.sublist(liste + 2 + 6 * i, liste + 6 + 6 * i),
        ),
    };
  }

  /// Les points de code couverts par la police.
  Set<int> get couverture {
    final int t = _tables['cmap']!;
    final int n = _d.getUint16(t + 2);
    int? meilleure;
    int format = 0;
    for (int i = 0; i < n; i++) {
      final int r = t + 4 + 8 * i;
      final int sous = t + _d.getUint32(r + 4);
      final int f = _d.getUint16(sous);
      if (f == 12 || (f == 4 && format != 12)) {
        meilleure = sous;
        format = f;
      }
    }
    final int s = meilleure!;
    final Set<int> points = <int>{};
    if (format == 12) {
      final int groupes = _d.getUint32(s + 12);
      for (int g = 0; g < groupes; g++) {
        final int r = s + 16 + 12 * g;
        for (int c = _d.getUint32(r); c <= _d.getUint32(r + 4); c++) {
          points.add(c);
        }
      }
      return points;
    }
    final int segments = _d.getUint16(s + 6) ~/ 2;
    final int fins = s + 14;
    final int debuts = fins + 2 * segments + 2;
    final int deltas = debuts + 2 * segments;
    final int decalages = deltas + 2 * segments;
    for (int i = 0; i < segments; i++) {
      final int fin = _d.getUint16(fins + 2 * i);
      final int debut = _d.getUint16(debuts + 2 * i);
      final int delta = _d.getInt16(deltas + 2 * i);
      final int decalage = _d.getUint16(decalages + 2 * i);
      for (int c = debut; c <= fin && c != 0xFFFF; c++) {
        // Un point de code n'est couvert que s'il mene a un glyphe autre que
        // le glyphe 0 (« .notdef ») : un segment peut en contenir.
        int glyphe;
        if (decalage == 0) {
          glyphe = (c + delta) & 0xFFFF;
        } else {
          glyphe = _d.getUint16(decalages + 2 * i + decalage + 2 * (c - debut));
          if (glyphe != 0) {
            glyphe = (glyphe + delta) & 0xFFFF;
          }
        }
        if (glyphe != 0) {
          points.add(c);
        }
      }
    }
    return points;
  }

  /// Hauteur naturelle d'une ligne, en em : (ascendante - descendante) / UPM,
  /// lue dans `hhea`.
  double get hauteurNaturelle {
    final int h = _tables['hhea']!;
    final int unites = _d.getUint16(_tables['head']! + 18);
    return (_d.getInt16(h + 4) - _d.getInt16(h + 6)) / unites;
  }
}
