"""Langues du site public (decision K-41 : francais, arabe, anglais, espagnol, portugais ; fiche docs/current/SITE-LANGUES-2026-11-05.md).

Une adresse par langue (/fr/, /ar/, /en/, /es/, /pt/), des pages statiques produites a la construction, aucun script de
traduction. Les pages de chaque langue sont lues dans content/pages.<langue>.json, qui reprend les memes routes francaises
comme cles : tout le reste de la construction (direction artistique, images, tarifs) reste commun. Une langue n'existe dans
une construction que si son fichier existe ; en production, seulement si elle est dans « publiees » de content/langues.json
(une langue n'est mise en ligne que lorsque toutes ses pages sont faites : jamais de page a moitie traduite).
"""
from __future__ import annotations

import json
import os
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

# Ce qui peut rester en lettres latines dans une page d'une autre langue : la raison sociale, le nom des langues dans leur
# ecriture, les references de sources (titres d'etudes et de revues, noms de recueils en ligne) et les adresses.
AUTORISES = {"AR", "EN", "ES", "PT", "FR", "Français", "English", "Español", "Português", "REWAYAH ACADEMY LTD", "As-Sahaba",
             "Bulletin", "Central)", "Interest", "Medicine", "Rewayah Academy Ltd", "Dynamahinyessow", "Facebook", "Instagram"}


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
    force = os.environ.get("RA_LANGUES")   # ex. « fr » : une construction restreinte (les tests du site francais)
    if force:
        voulues = [l for l in force.split(",") if l in NOMS]
    return [l for l in cfg["ordre"] if l in voulues and (l == "fr" or fichier_pages(l).exists())]


def textes_code(langue: str) -> dict[str, str]:
    """Les phrases ecrites dans le code, traduites : content/ui.<langue>.json = { phrase francaise : traduction }."""
    fichier = ROOT / "content" / f"ui.{langue}.json"
    if langue == "fr" or not fichier.exists():
        return {}
    donnees = json.loads(fichier.read_text(encoding="utf-8"))
    return {k: v for k, v in donnees.items() if not k.startswith("_")}


def textes_js(langue: str) -> dict[str, str]:
    """Les textes du simulateur (styles/site.js) dans une autre langue : content/textes_js.<langue>.json."""
    fichier = ROOT / "content" / f"textes_js.{langue}.json"
    if langue == "fr" or not fichier.exists():
        return {}
    return {k: v for k, v in json.loads(fichier.read_text(encoding="utf-8")).items() if not k.startswith("_")}


_CONNUS: dict[str, tuple[str, dict[str, bool]]] = {}


def deja_traduit(texte: str, langue: str) -> bool:
    """Vrai si ce texte est ecrit dans la langue de la page : il se trouve, mot pour mot, dans ses pages ou son dictionnaire.
    Pour une langue en lettres latines (anglais, espagnol, portugais), c'est ce qui distingue une phrase traduite d'une
    phrase francaise oubliee, que l'ecriture ne suffit pas a reconnaitre."""
    if langue == "fr":
        return True
    if langue not in _CONNUS:
        morceaux: list[str] = []

        def tous(x) -> None:
            if isinstance(x, dict):
                for v in x.values():
                    tous(v)
            elif isinstance(x, list):
                for v in x:
                    tous(v)
            elif isinstance(x, str):
                morceaux.append(_cle(x.replace("**", "")))
        if fichier_pages(langue).exists():
            tous(json.loads(fichier_pages(langue).read_text(encoding="utf-8")).get("pages"))
        tous(list(textes_code(langue).values()))
        _CONNUS[langue] = ("\n" + "\n".join(morceaux) + "\n", {})
    tout, cache = _CONNUS[langue]
    cle = _cle(texte.replace("**", ""))
    if cle not in cache:
        tout_code = tout + "\n" + LIBELLE_SELECTEUR[langue] + "\n" + LIBELLE_PIED[langue] + "\n"

        def connu(bout: str) -> bool:
            return re.search(r"(?<![\w’'])" + re.escape(bout) + r"(?![\w’'])", tout_code) is not None
        # Une phrase assemblee par le code (« Publie le » + une date, un nom + « · » + une duree, une citation entre
        # guillemets, deux paragraphes colles) : chaque morceau, entre deux signes de ponctuation, est deja de cette langue.
        bouts = [b.strip() for b in re.split(r"[·“”«»():;,.!?]|\d+\S*", cle)]
        bouts = [b for b in bouts if re.search(r"[A-Za-zÀ-ÿ]{3,}", b) and not re.fullmatch(r"[A-Za-z]{1,3}", b)]   # « min », « h »
        if len(bouts) > 0 and not connu(cle) and all(connu(b) for b in bouts):
            cache[cle] = True
            return True
        cache[cle] = bool(cle) and connu(cle)
    return cache[cle]


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
        if langue == "ar":   # la police arabe (37 Ko) n'est annoncee que sur les pages arabes
            h = h.replace('<link rel="stylesheet"', '<link rel="preload" href="/fr/assets/noto-sans-arabic-site.woff2" as="font" type="font/woff2" crossorigin>\n  <link rel="preload" href="/fr/assets/reem-kufi-titres.woff2" as="font" type="font/woff2" crossorigin>\n  <link rel="stylesheet"', 1)
    else:
        h = h.replace('<html lang="fr"', '<html lang="fr" dir="ltr"', 1)
    if langue != "fr":
        textes = textes_js(langue)
        if textes and 'id="tarifs-data"' in h:   # le simulateur ne se trouve que sur les pages qui portent les tarifs
            h = h.replace("</body>", '<script type="application/json" id="textes-js">' + json.dumps(textes, ensure_ascii=False).replace("</", "<\\/") + "</script>\n</body>", 1)
    # Autres versions de la page.
    if disponibles and len(disponibles) > 1:
        h = h.replace("</title>", "</title>\n  " + alternates(route_fr, disponibles, origin), 1)
        og = "".join(f'<meta property="og:locale:alternate" content="{LOCALES[l]}">' for l in disponibles if l != langue)
        h = h.replace('<meta property="og:title"', og + '<meta property="og:title"', 1)
    return h


_SEGMENTS = re.compile(r"(<script\b.*?</script>|<style\b.*?</style>|<!--.*?-->|<[^>]+>)", re.S | re.I)
_ATTRIBUTS = re.compile(r'(\b(?:alt|aria-label|title)=")([^"]*)(")')
_PHRASE = re.compile(r"[A-Za-zÀ-ÿ]{2,}")


def _cle(texte: str) -> str:
    return re.sub(r"\s+", " ", texte.replace(" ", " ").replace(" ", " ")).strip()


def traduire_noeuds(page_html: str, dictionnaire: dict[str, str], manques: set[str], langue: str = "ar") -> str:
    """Seconde passe : les phrases francaises ecrites dans le code hors de tout appel de traduction (gabarits de prix,
    simulateur, pied de page) sont traduites noeud de texte par noeud de texte, mot pour mot, d'apres le meme dictionnaire.
    Ce qui reste en lettres latines est note dans « manques » (rapport de construction, test de completude)."""
    import html as _html

    def une(texte: str, est_attribut: bool = False) -> str:
        brut = _html.unescape(texte) if est_attribut else texte
        cle = _cle(_html.unescape(brut) if not est_attribut else brut)
        if not cle or not _PHRASE.search(cle) or "\n" in cle:
            return texte
        trad = dictionnaire.get(cle)
        if trad is None and re.search(r"\d%", cle):   # « 25% » en anglais : la cle francaise ecrit « 25 % »
            trad = dictionnaire.get(re.sub(r"(\d)%", "\\1 %", cle))
        if trad is None:
            # Une phrase du code suivie d'un texte deja traduit (« Aux cotes du directeur, <nom> : ») : on traduit son debut.
            for debut_fr in sorted((k for k in dictionnaire if len(k) >= 12 and cle.startswith(k) and len(cle) > len(k)), key=len, reverse=True)[:1]:
                reste = cle[len(debut_fr):]
                if re.search(r"[\u0600-\u06FF]", reste) and not _PHRASE.search(re.sub(r"[\u0600-\u06FF]", "", reste).replace("rewayahacademy", "")):
                    trad = dictionnaire[debut_fr] + reste
        if trad is None:
            if not re.search(r"[؀-ۿ]", cle) and not deja_traduit(cle, langue):
                manques.add(cle)
            return texte
        debut = texte[: len(texte) - len(texte.lstrip())]
        fin = texte[len(texte.rstrip()):]
        return debut + _html.escape(trad, quote=False) + fin

    morceaux = _SEGMENTS.split(page_html)
    for i, m in enumerate(morceaux):
        if i % 2:
            if m.startswith("<") and not m.lower().startswith(("<script", "<style", "<!--")):
                morceaux[i] = _ATTRIBUTS.sub(lambda a: a.group(1) + _html.escape(une(a.group(2), True), quote=True) + a.group(3), m)
        else:
            morceaux[i] = une(m)
    return "".join(morceaux)
