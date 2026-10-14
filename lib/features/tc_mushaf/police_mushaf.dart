import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/tc_coran/layout_madina_15.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_layout_mushaf.dart';

/// Vrai quand la famille UthmanicHafs est declaree par l'application
/// (`FontManifest.json`, produit par `pubspec.yaml`).
///
/// **Le texte et la police vont toujours ensemble** (MUSHAF-MODES) : le texte
/// KFGQPC v3.0 porte des signes propres a l'ecriture uthmanie (waqf, petite
/// alif suscrite, mim et sin hauts, tanwin decales) que seule UthmanicHafs
/// dessine ; rendu en police generique, il sort en glyphes detaches ou mal
/// places. Quand la police manque, on rend donc le texte Tanzil simple, en
/// police arabe de l'application, jamais le texte KFGQPC.
final FutureProvider<bool> policeMushafDisponibleProvider =
    FutureProvider<bool>((Ref ref) async {
      try {
        final String brut = await rootBundle.loadString('FontManifest.json');
        final Object? liste = json.decode(brut);
        if (liste is! List<Object?>) return false;
        return liste.any(
          (Object? f) =>
              f is Map<String, Object?> && f['family'] == FamilleMushaf15L.nom,
        );
      } on Object {
        return false;
      }
    });

/// Un verset a rendre en texte continu : sa reference et son texte.
class VersetTexte {
  /// Cree un verset.
  const VersetTexte({
    required this.sourate,
    required this.numero,
    required this.texte,
  });

  /// La sourate.
  final int sourate;

  /// Le rang du verset.
  final int numero;

  /// Le texte.
  final String texte;

  /// La reference courte, « 17:105 ».
  String get reference => '$sourate:$numero';
}

/// Les versets de la page, **texte KFGQPC** : ceux des lignes de l'edition,
/// recomposes verset par verset (un verset coupe sur deux lignes se recolle
/// par une espace). A rendre avec UthmanicHafs, et seulement avec elle.
List<VersetTexte> versetsKfgqpc(PageMushafVM vue) {
  final List<String> ordre = <String>[];
  final Map<String, StringBuffer> textes = <String, StringBuffer>{};
  final Map<String, (int, int)> refs = <String, (int, int)>{};
  for (final SectionLigne ligne in vue.lignes) {
    if (ligne.type != TypeLigneMushaf.texte) continue;
    for (final SegmentVersetLigne segment in ligne.segments) {
      final String cle = '${segment.sourate}:${segment.ayah}';
      if (!textes.containsKey(cle)) {
        ordre.add(cle);
        textes[cle] = StringBuffer();
        refs[cle] = (segment.sourate, segment.ayah);
      } else {
        textes[cle]!.write(' ');
      }
      textes[cle]!.write(segment.texte);
    }
  }
  return <VersetTexte>[
    for (final String cle in ordre)
      VersetTexte(
        sourate: refs[cle]!.$1,
        numero: refs[cle]!.$2,
        texte: textes[cle].toString(),
      ),
  ];
}

/// Les versets de la page, **texte Tanzil simple** (le corpus de la base). A
/// rendre en police arabe de l'application, jamais en UthmanicHafs.
List<VersetTexte> versetsTanzil(PageMushafVM vue) => <VersetTexte>[
  for (final VersetCoran v in vue.versets)
    VersetTexte(sourate: v.sourateNumero, numero: v.numero, texte: v.texte),
];
