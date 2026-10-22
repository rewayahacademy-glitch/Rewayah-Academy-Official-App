// Le lien de l'offre aux eleves, celui que la carte a partager (CAND-06,
// « Aidez une personne a apprendre la parole d'Allah. ») donne a partager : l'adresse du site
// public, page d'accueil francaise.
//
// **Jamais ecrit en dur.** L'adresse vient de la configuration de compilation
// (`Env.siteUrl`, cle `SITE_URL`) ; sans elle, sur le web, de l'origine de la
// page ouverte, parce que l'application et le site public sont servis par la
// meme origine (`flutter-deploy.yml` construit `fr/` a cote de l'application) :
// meme principe que `lienAvisPour` (`DECISION-AVIS-2026-10-19`). Hors du web et
// sans configuration, il n'y a pas de lien, donc pas de carte : une carte
// sans lien ne ferait rien connaitre.
//
// Le lien ne porte aucun parametre : rien ne dit qui partage, rien ne compte
// les partages (le partage est facultatif et sans effet sur la candidature,
// decision du directeur du 22/10/2026).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// Le chemin de la page d'accueil du site public, en francais : la seule
/// langue du site (`site-public/build_site.py`, dossier `fr/`).
const String cheminOffre = '/fr/';

/// L'origine (`https://hote[:port]`) d'une adresse de site, ou `null` si elle
/// ne peut pas servir : ni `http` ni `https`, ou pas d'hote.
Uri? _origine(Uri adresse) {
  final bool web = adresse.scheme == 'https' || adresse.scheme == 'http';
  if (!web || adresse.host.isEmpty) {
    return null;
  }
  return Uri(
    scheme: adresse.scheme,
    host: adresse.host,
    port: adresse.hasPort ? adresse.port : null,
  );
}

/// Le lien de l'offre, ou `null` quand aucune adresse de site n'est connue.
///
/// [configure] est la valeur de `SITE_URL` (vide : non configuree ; invalide :
/// ignoree, comme si elle etait vide). [base] est l'adresse de la page ouverte
/// (`Uri.base`) : elle n'est un site que sur le web, ou le schema est `http` ou
/// `https` et l'hote existe ; ailleurs, c'est un dossier de travail et elle est
/// ignoree. Pure, testee.
Uri? lienOffre({required String configure, Uri? base}) {
  final String texte = configure.trim();
  final Uri? configuree = texte.isEmpty
      ? null
      : _origine(Uri.tryParse(texte) ?? Uri());
  final Uri? origine = configuree ?? _origine(base ?? Uri());
  return origine?.replace(path: cheminOffre);
}

/// Le lien tel qu'on le lit : sans le schema, pour la carte et pour l'oeil.
String lienLisible(Uri lien) {
  final String port = lien.hasPort ? ':${lien.port}' : '';
  return '${lien.host}$port${lien.path}';
}

/// Le lien de l'offre de cette compilation, ou `null`.
final Provider<Uri?> lienOffreProvider = Provider<Uri?>(
  (Ref _) => lienOffre(configure: Env.siteUrl, base: Uri.base),
);
