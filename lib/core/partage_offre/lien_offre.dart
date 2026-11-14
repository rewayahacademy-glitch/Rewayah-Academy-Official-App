// Le lien de l'offre aux eleves, celui que la carte a partager (CAND-06,
// « Aidez une personne a apprendre la parole d'Allah. ») donne a partager : l'adresse du
// **site public**, page d'accueil dans la langue de la carte.
//
// **Jamais l'application.** Decision du directeur du 14/11/2026 : chaque partage
// mene au site public (`https://rewayahacademy.com/<langue>/`,
// `DECISION-DOMAINE-2026-10-23`), jamais a `app.rewayahacademy.com`. Avant
// cette date, sans `SITE_URL`, le lien reprenait l'origine de la page ouverte :
// en production, celle de l'application, d'ou des cartes portant
// « app.rewayahacademy.com/fr/ ». L'origine vient desormais de la
// configuration de compilation (`Env.siteUrl`, cle `SITE_URL`) quand elle est
// valide et n'est pas l'application ; sinon, du site public de production.
//
// La langue : `fr`, `ar`, `en`, `es`, `pt`, les dossiers publies du site
// (`site-public/content/langues.json`) ; toute autre langue mene a `/fr/`.
//
// Le lien ne porte aucun parametre : rien ne dit qui partage, rien ne compte
// les partages (le partage est facultatif et sans effet sur la candidature,
// decision du directeur du 22/10/2026).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// Le site public de production (`DECISION-DOMAINE-2026-10-23`).
const String sitePublicParDefaut = 'https://rewayahacademy.com';

/// Les langues publiees du site public, un dossier chacune
/// (`site-public/content/langues.json`, « publiees »).
const Set<String> languesSitePublic = <String>{'fr', 'ar', 'en', 'es', 'pt'};

/// La langue du site quand celle demandee n'y a pas de dossier.
const String langueSiteParDefaut = 'fr';

/// Le chemin de la page d'accueil du site public dans [langue] (`/fr/`,
/// `/ar/`...), `/fr/` pour une langue que le site n'a pas.
String cheminOffre(String langue) {
  final String code = langue.trim().toLowerCase();
  return '/${languesSitePublic.contains(code) ? code : langueSiteParDefaut}/';
}

/// L'origine (`https://hote[:port]`) d'une adresse de site, ou `null` si elle
/// ne peut pas servir : ni `http` ni `https`, pas d'hote, ou l'hote de
/// l'application (`app.` en tete) : un partage ne mene jamais a l'application.
Uri? _origine(Uri adresse) {
  final bool web = adresse.scheme == 'https' || adresse.scheme == 'http';
  if (!web || adresse.host.isEmpty || adresse.host.startsWith('app.')) {
    return null;
  }
  return Uri(
    scheme: adresse.scheme,
    host: adresse.host,
    port: adresse.hasPort ? adresse.port : null,
  );
}

/// L'origine du site public : [configure] (la valeur de `SITE_URL`) quand
/// elle est une adresse de site valide qui n'est pas l'application, sinon
/// [sitePublicParDefaut]. Jamais `null`. Pure, testee.
Uri origineSitePublic({required String configure}) {
  final String texte = configure.trim();
  final Uri? configuree = texte.isEmpty
      ? null
      : _origine(Uri.tryParse(texte) ?? Uri());
  return configuree ?? Uri.parse(sitePublicParDefaut);
}

/// Le lien de l'offre dans [langue] : l'accueil du site public de cette langue.
/// Pure, testee.
Uri lienOffre({required String configure, String langue = 'fr'}) =>
    lienOffreDepuis(origineSitePublic(configure: configure), langue);

/// Le lien de l'offre dans [langue], depuis une [origine] deja connue (celle de
/// [lienOffreProvider]).
Uri lienOffreDepuis(Uri origine, String langue) =>
    origine.replace(path: cheminOffre(langue));

/// Le lien tel qu'on le lit : sans le schema, pour la carte et pour l'oeil.
String lienLisible(Uri lien) {
  final String port = lien.hasPort ? ':${lien.port}' : '';
  return '${lien.host}$port${lien.path}';
}

/// L'origine du site public de cette compilation. Le chemin de la langue
/// s'ajoute au moment du partage ([lienOffreDepuis]). Type nullable garde pour
/// les ecrans qui savent dire « indisponible » ; jamais `null` en pratique.
final Provider<Uri?> lienOffreProvider = Provider<Uri?>(
  (Ref _) => origineSitePublic(configure: Env.siteUrl),
);
