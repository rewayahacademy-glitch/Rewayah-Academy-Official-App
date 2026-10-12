// AR-FUSEAU-VILLE : le nom de la ville d'un fuseau IANA, dans la langue de
// l'interface.
//
// Une table de libelles (`commun.fuseaux.*`) donne le nom des fuseaux reellement
// utilises par l'application (leurs sources sont dans
// `tool/libelles_sources.json`). Un fuseau hors table ne plante jamais : en
// francais, le dernier segment de l'identifiant IANA (« Los Angeles ») ; hors
// du francais, ce meme nom isole (U+2068 ... U+2069) pour qu'un nom latin ne
// renverse pas la phrase arabe qui le porte.

import 'strings.g.dart';

final String _debutIsolat = String.fromCharCode(0x2068);
final String _finIsolat = String.fromCharCode(0x2069);

/// La cle de table d'un identifiant IANA : `Europe/Paris` donne `europeParis`,
/// `America/Los_Angeles` donne `americaLosAngeles`. `null` pour un identifiant
/// vide.
String? cleVilleFuseau(String iana) {
  final List<String> morceaux = iana
      .trim()
      .split(RegExp('[/_]'))
      .map((String m) => m.trim())
      .where((String m) => m.isNotEmpty)
      .toList();
  if (morceaux.isEmpty) {
    return null;
  }
  return <String>[
    for (final (int i, String m) in morceaux.indexed)
      i == 0
          ? m.toLowerCase()
          : m[0].toUpperCase() + m.substring(1).toLowerCase(),
  ].join();
}

/// Le nom de la ville de [iana] dans la langue active : le libelle de la
/// table, sinon le dernier segment de l'identifiant (isole hors du francais).
String villeDuFuseauLibelle(String iana) {
  final String nu = iana.trim();
  final String? cle = cleVilleFuseau(nu);
  if (cle != null) {
    final Object? libelle = t.$meta.getTranslation('commun.fuseaux.$cle');
    if (libelle is String && libelle.isNotEmpty) {
      return libelle;
    }
  }
  final String dernier = nu.split('/').last.replaceAll('_', ' ').trim();
  final String nom = dernier.isEmpty ? nu : dernier;
  if (nom.isEmpty) {
    return nom;
  }
  return LocaleSettings.currentLocale == AppLocale.fr
      ? nom
      : '$_debutIsolat$nom$_finIsolat';
}
