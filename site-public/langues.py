"""Langues du site public (decision K-41 : francais, arabe, anglais, espagnol, portugais ; fiche docs/current/SITE-LANGUES-2026-11-05.md).

Une adresse par langue (/fr/, /ar/, /en/, /es/, /pt/), des pages statiques produites a la construction, aucun script de
traduction. Les pages de chaque langue sont lues dans content/pages.<langue>.json, qui reprend les memes routes francaises
comme cles : tout le reste de la construction (direction artistique, images, tarifs) reste commun. Une langue n'existe dans
une construction que si son fichier existe ; en production, seulement si elle est dans « publiees » de content/langues.json
(une langue n'est mise en ligne que lorsque toutes ses pages sont faites : jamais de page a moitie traduite).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIG = ROOT / "content" / "langues.json"

# Nom de chaque langue ecrit dans sa propre ecriture (W3C : https://www.w3.org/International/questions/qa-navigation-select).
NOMS = {"fr": "Français", "ar": "العربية", "en": "English", "es": "Español", "pt": "Português"}
LOCALES = {"fr": "fr_FR", "ar": "ar_AR", "en": "en_US", "es": "es_ES", "pt": "pt_PT"}
DIRECTION = {"fr": "ltr", "ar": "rtl", "en": "ltr", "es": "ltr", "pt": "ltr"}
# Libelle accessible du selecteur, dans la langue de la page.
LIBELLE_SELECTEUR = {"fr": "Choisir la langue", "ar": "اختيار اللغة", "en": "Choose language", "es": "Elegir idioma", "pt": "Escolher idioma"}
LIBELLE_PIED = {"fr": "Langues", "ar": "اللغات", "en": "Languages", "es": "Idiomas", "pt": "Idiomas"}

GLOBE = ('<svg class="langue__globe" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false">'
         '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.7"/>'
         '<path d="M3 12h18M12 3c2.6 2.6 3.9 5.6 3.9 9s-1.3 6.4-3.9 9c-2.6-2.6-3.9-5.6-3.9-9S9.4 5.6 12 3z" fill="none" '
         'stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>')
COCHE = ('<svg class="langue__coche" viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false">'
         '<path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')


def config() -> dict:
    if not CONFIG.exists():
        return {"ordre": ["fr"], "publiees": ["fr"]}
    donnees = json.loads(CONFIG.read_text(encoding="utf-8"))
    for cle in ("ordre", "publiees"):
        if not isinstance(donnees.get(cle), list) or not all(l in NOMS for l in donnees[cle]):
            raise ValueError(f"langues.json : « {cle} » est une liste de langues parmi {sorted(NOMS)}")
    if "fr" not in donnees["publiees"]:
        raise ValueError("langues.json : le francais est toujours publie")
    return donnees


def fichier_pages(langue: str) -> Path:
    return ROOT / "content" / f"pages.{langue}.json"


def langues_construites(allow_indexing: bool) -> list[str]:
    """Les langues presentes dans cette construction, dans l'ordre de langues.json. Le francais d'abord, toujours.
    Production : seulement les langues publiees ; un apercu montre aussi celles en cours (noindex)."""
    cfg = config()
    voulues = cfg["publiees"] if allow_indexing else cfg["ordre"]
    return [l for l in cfg["ordre"] if l in voulues and (l == "fr" or fichier_pages(l).exists())]


def route_langue(route_fr: str, langue: str) -> str:
    """'/fr/tarifs' -> '/ar/tarifs'."""
    return route_fr if langue == "fr" else "/" + langue + route_fr[3:]


def selecteur(langue: str, route_fr: str, disponibles: list[str], en_pied: bool = False) -> str:
    """Le choix de langue : des liens HTML, sans script (le menu s'ouvre par <details>), chaque langue dans son ecriture,
    avec son attribut lang. Absent quand il n'y a qu'une langue : rien a choisir."""
    if len(disponibles) < 2:
        return ""
    if en_pied:
        liens = "".join(
            f'<li><a href="{route_langue(route_fr, l)}" hreflang="{l}" lang="{l}"{" aria-current=" + chr(34) + "true" + chr(34) if l == langue else ""}>{NOMS[l]}</a></li>'
            for l in disponibles)
        return f'<nav class="langues-pied" aria-label="{LIBELLE_PIED[langue]}"><ul>{liens}</ul></nav>'
    items = "".join(
        f'<li><a class="langue__lien" href="{route_langue(route_fr, l)}" hreflang="{l}" lang="{l}" dir="{DIRECTION[l]}"'
        f'{" aria-current=" + chr(34) + "true" + chr(34) if l == langue else ""}><span class="langue__nom">{NOMS[l]}</span>{COCHE if l == langue else ""}</a></li>'
        for l in disponibles)
    return (f'<details class="langue" data-langue><summary class="langue__bouton" aria-label="{LIBELLE_SELECTEUR[langue]}">{GLOBE}'
            f'<span class="langue__code" aria-hidden="true">{langue.upper()}</span></summary>'
            f'<ul class="langue__liste">{items}</ul></details>')


def alternates(route_fr: str, disponibles: list[str], origin: str) -> str:
    """Balises hreflang reciproques : chaque version liste toutes les autres, elle-meme comprise, avec un x-default
    (https://developers.google.com/search/docs/specialty/international/localized-versions)."""
    if len(disponibles) < 2:
        return ""
    base = origin.rstrip("/")
    balises = "".join(f'<link rel="alternate" hreflang="{l}" href="{base}{route_langue(route_fr, l)}">' for l in disponibles)
    return balises + f'<link rel="alternate" hreflang="x-default" href="{base}{route_langue(route_fr, "fr")}">'


def alternates_plan(route_fr: str, disponibles: list[str], origin: str) -> str:
    if len(disponibles) < 2:
        return ""
    base = origin.rstrip("/")
    return "".join(f'<xhtml:link rel="alternate" hreflang="{l}" href="{base}{route_langue(route_fr, l)}"/>' for l in disponibles) + \
        f'<xhtml:link rel="alternate" hreflang="x-default" href="{base}{route_langue(route_fr, "fr")}"/>'


_HREF_INTERNE = re.compile(r'(href|action)="/fr(/|")(?!assets/)')
_ABSOLU = re.compile(r'(https://[^"\'/<> ]+)/fr/(?!assets/)')
_ABSOLU_RACINE = re.compile(r'(https://[^"\'/<> ]+)/fr"')


def localiser(page_html: str, langue: str, route_fr: str, origin: str, disponibles: list[str], allow_indexing: bool = True) -> str:
    """Passe une page francaise rendue dans une autre langue : adresses, lang, dir, balises de langue. Les adresses des
    fichiers du site (/fr/assets/) restent communes a toutes les langues."""
    if langue == "fr" and len(disponibles) < 2:
        return page_html
    h = page_html
    if langue != "fr":
        h = _HREF_INTERNE.sub(lambda m: f'{m.group(1)}="/{langue}{m.group(2)}', h)
        h = _ABSOLU.sub(lambda m: f'{m.group(1)}/{langue}/', h)
        h = _ABSOLU_RACINE.sub(lambda m: f'{m.group(1)}/{langue}"', h)
        h = h.replace('<html lang="fr"', f'<html lang="{langue}" dir="{DIRECTION[langue]}"', 1)
        h = h.replace('property="og:locale" content="fr_FR"', f'property="og:locale" content="{LOCALES[langue]}"', 1)
    else:
        h = h.replace('<html lang="fr"', '<html lang="fr" dir="ltr"', 1)
    # Autres versions de la page.
    if disponibles and len(disponibles) > 1:
        h = h.replace("</title>", "</title>\n  " + alternates(route_fr, disponibles, origin), 1)
        og = "".join(f'<meta property="og:locale:alternate" content="{LOCALES[l]}">' for l in disponibles if l != langue)
        h = h.replace('<meta property="og:title"', og + '<meta property="og:title"', 1)
    return h
