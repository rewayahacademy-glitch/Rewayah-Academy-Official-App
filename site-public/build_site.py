"""Build the public site beside the Flutter Web bundle (build/web).

Production (the `main` build, served on rewayahacademy.com) is indexed: robots,
sitemap and canonical URLs on the domain. Any other build is a preview and stays
noindex. Host rules in build/web/vercel.json send the app to app.rewayahacademy.com.

Art direction: one motif, the arch of the brand symbol (an arch shaped like a
book, an open door; decision M-21). It masks every picture, shapes the hero and
opens the home page's scroll scene. Layout per page lives in
content/direction.json; the pictures and their alt text in content/images.json.
"""

from __future__ import annotations

import argparse
import html
import importlib.util
import json
import os
import re
import shutil
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent


def _load_module(name: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(name)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


# Prix lus dans la base au build (public.tarifs_publics), repli sur la decision.
tarifs_mod = _load_module("bloc_tarifs")
porte_mod = _load_module("scene_porte")
# Avis publies lus dans la base au build (public.avis_publics), repli sur content/avis.json.
avis_mod = _load_module("bloc_avis")
# Langues du site (K-41) : une adresse par langue, pages statiques, aucun script de traduction (fiche SITE-LANGUES).
langues_mod = _load_module("langues")
# Contexte de la page en cours de rendu : sa langue, et les langues presentes dans cette construction.
_LANGUE = {"code": "fr", "disponibles": ["fr"]}
CONTENT = ROOT / "content" / "pages.json"
DIRECTION = ROOT / "content" / "direction.json"
IMAGES = ROOT / "content" / "images.json"
REQUIRED = {
    "/fr/",
    "/fr/familles",
    "/fr/cours",
    "/fr/comment-ca-marche",
    "/fr/tarifs",
    "/fr/academie",
    "/fr/articles",
    "/fr/aide",
    "/fr/avis",
    "/fr/recrutement",
    "/fr/contact",
    "/fr/protection-des-enfants",
    "/fr/legal/mentions",
    "/fr/legal/conditions",
    "/fr/legal/annulation-remboursement",
    "/fr/legal/confidentialite",
    "/fr/legal/cookies",
    "/fr/accessibilite",
}
APP_LINKS = {"/connexion"}
# Formule institutionnelle publiable telle quelle (registre de marque M-19, 29/09 et 14/10/2026).
PIED_ACCROCHE = "Rewayah Academy enseigne le Coran en ligne depuis le 1er mai 2024."

NAV = (
    ("Cours", "/fr/cours"),
    ("Familles", "/fr/familles"),
    ("Tarifs", "/fr/tarifs"),
    ("Articles", "/fr/articles"),
    ("Se connecter", "/connexion"),
)
FOOTER = (
    ("Comment ça marche", "/fr/comment-ca-marche"),
    ("Académie", "/fr/academie"),
    ("Recrutement", "/fr/recrutement"),
    ("Aide", "/fr/aide"),
    ("Contact", "/fr/contact"),
    ("Protection des enfants", "/fr/protection-des-enfants"),
    ("Mentions légales", "/fr/legal/mentions"),
    ("Conditions", "/fr/legal/conditions"),
    ("Annulation et remboursement", "/fr/legal/annulation-remboursement"),
    ("Confidentialité", "/fr/legal/confidentialite"),
    ("Cookies", "/fr/legal/cookies"),
    ("Accessibilité", "/fr/accessibilite"),
)
ASSETS = "/fr/assets"
# Domaine (directeur, 23/10/2026) : le site public a la racine du domaine, l'application et sa PWA sur app.
# Un seul projet Vercel sert les deux noms ; build/web/vercel.json aiguille selon le nom demande.
DOMAINE_SITE = "rewayahacademy.com"
DOMAINE_APP = "app." + DOMAINE_SITE
DOMAINE_WWW = "www." + DOMAINE_SITE
ORIGINE_SITE = "https://" + DOMAINE_SITE
ORIGINE_APP = "https://" + DOMAINE_APP
# L'alias de production d'avant le domaine : il reste servi (le workflow le controle), jamais indexe.
ALIAS_VERCEL = "rewayah-academy.vercel.app"
# Les quatre fichiers officiels du logo (assets/brand/logo/), copies telles quelles.
LOGO = {
    "horizontal": ("logo-horizontal.svg", 1027, 287),
    "horizontal-blanc": ("logo-horizontal-white.svg", 1027, 287),
    "horizontal-encre": ("logo-horizontal-ink.svg", 1027, 287),
    "symbole": ("symbole.svg", 716, 707),
    "symbole-blanc": ("symbole-white.svg", 716, 707),
}


# Textes ecrits dans le code (menus, pied de page, questions de l'accueil...) : pour une autre langue, content/ui.<langue>.json
# donne la traduction de chaque phrase francaise, mot pour mot. Un texte absent reste en francais : le test de completude
# d'une langue (tests/test_langues.py) refuse alors la construction de production de cette langue.
_UI: dict[str, str] = {}


_NOMS_FR: dict[str, str] = {}        # nom d'une personne dans la langue de la page -> son nom francais (cle des portraits de direction.json)


def _alias_noms(fr, autre) -> None:
    """Fait correspondre les noms de personnes d'une page traduite (ecrits dans la langue de la page) a ceux du francais."""
    if isinstance(fr, dict) and isinstance(autre, dict):
        for cle, valeur in fr.items():
            if cle == "nom" and isinstance(valeur, str) and isinstance(autre.get(cle), str):
                _NOMS_FR[autre[cle]] = valeur
            elif cle in autre:
                _alias_noms(valeur, autre[cle])
    elif isinstance(fr, list) and isinstance(autre, list):
        for x, y in zip(fr, autre):
            _alias_noms(x, y)


_MANQUES: dict[str, set[str]] = {}   # phrases du code sans traduction, par langue (rapport de construction)
# Une phrase francaise a traduire : des lettres latines, et une majuscule ou une espace ou un accent (ni classe CSS, ni adresse).
_PHRASE = re.compile(r"^(?=.*[A-Za-zÀ-ÿ]{2,})(?:[A-ZÀ-Ý]|.*[ à-ÿ’]).*$", re.S)


def _t(value: str) -> str:
    if _LANGUE["code"] == "fr":
        return value
    # Les espaces insecables du code (« Votre\u00a0classe ») valent des espaces dans le dictionnaire.
    cle = value.replace("\u00a0", " ").replace("\u202f", " ")
    traduit = _UI.get(cle)
    if traduit is not None:
        return traduit
    if _PHRASE.search(cle) and not cle.startswith(("/", "#", "http", "mailto", "(")) and "__" not in cle and "--" not in cle:
        _MANQUES.setdefault(_LANGUE["code"], set()).add(cle)
    return value


def esc(value: object) -> str:
    return html.escape(_t(str(value)), quote=True)


_PETITS = (r"le|la|les|un|une|des|de|du|à|au|aux|en|et|ou|par|pour|sans|son|sa|ses|votre|vos|notre|nos|chaque|dès|"
           r"avec|sur|dans|deux|trois|quatre|cinq|six|qui|que")
# Un petit mot se lie au mot qui le suit (« pour votre enfant » ne se coupe qu'avant « pour »), un nombre a son unite,
# et le nom de l'academie ne se coupe pas. Les titres longs sont dimensionnes pour que ces blocs tiennent.
PETITS_MOTS = re.compile(rf"(?<![\w’'])((?i:{_PETITS})|\d+) (?=\S)")


def titre_html(value: str) -> str:
    """Un titre ne finit pas une ligne sur un article, une preposition ou un nombre : espaces insecables."""
    value = _t(value)
    lie = PETITS_MOTS.sub(lambda m: m.group(1) + "\u00a0", re.sub(r" ([:;?!])", "\u00a0\\1", value))
    lie = PETITS_MOTS.sub(lambda m: m.group(1) + "\u00a0", lie)
    lie = lie.replace("Rewayah Academy", "Rewayah\u00a0Academy")
    # Un bloc insecable plus long que 18 signes ne tiendrait pas sur un telephone de 320 px : on rend ses premieres
    # espaces, en gardant les liens de la fin (« avec Rewayah Academy » se coupe apres « avec »).
    blocs = []
    for bloc in lie.split(" "):
        while len(bloc) > 18 and "\u00a0" in bloc:
            tete, bloc = bloc.split("\u00a0", 1)
            blocs.append(tete)
        blocs.append(bloc)
    return esc(" ".join(blocs))


def _unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def load_content() -> tuple[dict[str, dict], dict]:
    data = json.loads(CONTENT.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    pages = data.get("pages")
    site = data.get("site")
    if not isinstance(pages, dict):
        raise ValueError("pages.json needs a pages object")
    if not isinstance(site, dict) or not isinstance(site.get("contacts"), dict):
        raise ValueError("pages.json needs a site.contacts object")
    expected_contacts = {
        "contact@rewayahacademy.com", "support@rewayahacademy.com",
        "recrutement@rewayahacademy.com", "invoices@rewayahacademy.com",
    }
    if set(site["contacts"].values()) != expected_contacts:
        raise ValueError("Public contacts differ from the four approved aliases")
    social = site.get("social_links")
    if not isinstance(social, list) or {item.get("href") for item in social} != {
        "https://www.facebook.com/share/1CVee2teiN/",
        "https://www.facebook.com/share/1D6H2EYhci/",
        "https://www.instagram.com/rewayahacademy/",
    }:
        raise ValueError("Social destinations differ from the three approved URLs")
    # Directeur, 24/10/2026 : son nom quitte le pied de page (il reste sur sa biographie de fondateur) ; le
    # createur du site signe du nom exact de sa page Facebook.
    if site.get("author_credit") != "Site conçu par Dynamahinyessow.":
        raise ValueError("Site creator credit differs from the approved text")
    missing = REQUIRED - pages.keys()
    if missing:
        raise ValueError(f"Missing required routes: {', '.join(sorted(missing))}")
    titles: set[str] = set()
    for route, page in pages.items():
        if not re.fullmatch(r"/fr(?:/[a-z0-9-]+)*/?", route):
            raise ValueError(f"Invalid route: {route}")
        if not isinstance(page, dict):
            raise ValueError(f"Invalid page: {route}")
        for field in ("title", "description", "h1", "sections", "cta"):
            if not page.get(field):
                raise ValueError(f"Missing {field}: {route}")
        if page["title"] in titles:
            raise ValueError(f"Duplicate SEO title: {page['title']}")
        titles.add(page["title"])
        if not isinstance(page["sections"], list):
            raise ValueError(f"sections must be a list: {route}")
        for section in page["sections"]:
            if not isinstance(section, dict) or not section.get("title"):
                raise ValueError(f"Section without title: {route}")
        if route.startswith("/fr/articles/"):
            # Un article est date : le balisage et le plan du site disent quand il a ete publie (jamais une date inventee).
            if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(page.get("date", ""))):
                raise ValueError(f"Article without a publication date (AAAA-MM-JJ): {route}")
            date.fromisoformat(page["date"])
            auteur = page.get("auteur") or {}
            if not all(isinstance(auteur.get(c), str) and auteur.get(c) for c in ("nom", "role", "href")):
                raise ValueError(f"Article without its author (nom, role, href): {route}")
            validate_link(auteur["href"], pages)
        validate_link(page["cta"]["href"], pages)
        for section in page["sections"]:
            for link in section.get("links", []):
                validate_link(link["href"], pages)
            valider_citations_arabes(route, section)
    return pages, site


ARABE = re.compile(r"[\u0600-\u06FF\u0750-\u077F\u0870-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]")
LATIN = re.compile(r"[A-Za-z\u00C0-\u024F]")


def valider_citations_arabes(route: str, section: dict) -> None:
    """Un bloc arabe n'existe que dans un article, apres un paragraphe qui existe, avec sa legende en francais ; son texte
    est de l'arabe et rien d'autre (une lettre latine y signalerait un collage rate)."""
    blocs = section.get("citations_arabes", [])
    if blocs and not route.startswith("/fr/articles/"):
        raise ValueError(f"Arabic citation outside an article: {route}")
    for bloc in blocs:
        if bloc.get("genre") not in GENRES_CITATION or not isinstance(bloc.get("apres"), int):
            raise ValueError(f"Arabic citation without genre or position: {route}#{section.get('id')}")
        if not 0 <= bloc["apres"] < len(section.get("paragraphs", [])):
            raise ValueError(f"Arabic citation after a missing paragraph: {route}#{section.get('id')}")
        textes = [v["texte"] for v in bloc.get("versets", [])] if bloc["genre"] == "coran" else [bloc.get("texte", "")]
        if bloc["genre"] == "coran" and not all(re.fullmatch(r"\d{1,3}:\d{1,3}", v.get("cle", "")) for v in bloc.get("versets", [])):
            raise ValueError(f"Quran citation without verse keys: {route}#{section.get('id')}")
        if not textes or any(not ARABE.search(t) or LATIN.search(t) for t in textes):
            raise ValueError(f"Arabic citation that is not Arabic text: {route}#{section.get('id')}")
        if not bloc.get("legende") or ARABE.search(bloc["legende"]):
            raise ValueError(f"Arabic citation without a French caption: {route}#{section.get('id')}")


def load_direction(pages: dict[str, dict]) -> tuple[dict, dict]:
    """Direction artistique et images : chaque image citee existe, chaque route est connue."""
    direction = json.loads(DIRECTION.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    images = json.loads(IMAGES.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    connues = images["images"]
    for ident, image in connues.items():
        if not re.fullmatch(r"[a-z][a-z0-9-]*", ident):
            raise ValueError(f"Invalid image id: {ident}")
        for champ in ("largeur", "hauteur", "alt"):
            if not image.get(champ):
                raise ValueError(f"Image {ident} needs {champ}")
        for fichier in fichiers_scene(images, ident):
            if not (ROOT / "assets" / fichier).is_file():
                raise ValueError(f"Missing picture file: {fichier}")
        calques = image.get("calques")
        if calques and calques.get("anime") not in ("tapis", "mains"):
            raise ValueError(f"Image {ident}: unknown animation {calques.get('anime')}")
    if direction.get("ambiance", "clair") not in ("clair", "violet"):
        raise ValueError("direction.json: ambiance must be clair or violet")
    if direction.get("teinte", "violet") not in ("violet", "jour"):
        raise ValueError("direction.json: teinte must be violet or jour")
    if direction.get("teinte", "violet") == "jour" and direction.get("ambiance", "clair") != "violet":
        raise ValueError("direction.json: teinte jour only applies to the violet ambiance")
    if not isinstance(direction.get("dessins", False), bool):
        raise ValueError("direction.json: dessins must be true or false")
    for route, reglage in direction["pages"].items():
        if route not in pages:
            raise ValueError(f"direction.json names an unknown route: {route}")
        for ident in (reglage.get("figures") or {}).values():
            if ident not in connues:
                raise ValueError(f"direction.json names an unknown picture: {ident}")
        for valeur in (reglage.get("portraits") or {}).values():
            # une section a un portrait (le mot) ou un portrait par personne, par son nom (les fondateurs)
            for ident in (valeur.values() if isinstance(valeur, dict) else [valeur]):
                if ident not in connues or not (connues[ident].get("photo") or {}).get("legende"):
                    raise ValueError(f"direction.json: portrait {ident} must be a photo with its legende in images.json")
        for cle in ("image", "bande"):
            valeur = (reglage.get(cle) or {}).get("image") if isinstance(reglage.get(cle), dict) else reglage.get(cle)
            if valeur and valeur not in connues:
                raise ValueError(f"direction.json names an unknown picture: {valeur}")
        image_fin = (reglage.get("fin") or {}).get("image")
        if image_fin and image_fin not in connues:
            raise ValueError(f"direction.json names an unknown picture: {image_fin}")
        if (reglage.get("fin") or {}).get("forme", "") not in ("", "centre", "sombre", "prix", "image", "note"):
            raise ValueError(f"direction.json: {route} fin.forme must be centre, sombre, prix, image or note")
        note = (reglage.get("fin") or {}).get("note")
        if ((reglage.get("fin") or {}).get("forme") == "note") != bool(note) or (
                note and note not in {s["id"] for s in pages[route]["sections"]}):
            raise ValueError(f"direction.json: {route} fin.note names one section of the page, with fin.forme note")
        if (reglage.get("fin") or {}).get("forme") == "image" and not image_fin:
            raise ValueError(f"direction.json: {route} fin.forme image needs fin.image")
        schema = (reglage.get("bande") or {}).get("schema")
        if schema is not None:
            if set(schema) != {"description", "centre", "choix", "etapes"} or len(schema["etapes"]) != 4 or any(
                    set(e) != {"titre", "texte"} for e in schema["etapes"]):
                raise ValueError(f"direction.json: {route} band schema needs description, centre, choix and four etapes")
    return direction, images


def fichiers_scene(images: dict, ident: str) -> list[str]:
    """Tous les fichiers publies d'une illustration : l'image entiere et ses calques animables, a chaque largeur."""
    calques = images["images"][ident].get("calques", {}).get("noms", [])
    noms = [ident] + ([f"{ident}-fond"] if calques else []) + [f"{ident}-{calque}" for calque in calques]
    return [f"scene-{nom}-{largeur}.webp" for nom in noms for largeur in image_largeurs(images, ident)]


def image_largeurs(images: dict, ident: str) -> list[int]:
    """Les largeurs exportees : celles de la liste sous la largeur native, puis la plus grande possible."""
    largeur = images["images"][ident]["largeur"]
    largeurs = [w for w in images["largeurs"] if w < largeur]
    plus_grande = min(largeur, images["largeurs"][-1])
    return largeurs if plus_grande in largeurs else largeurs + [plus_grande]


def validate_link(href: str, pages: dict) -> None:
    if href.startswith("/fr/") and href.split("#", 1)[0] not in pages:
        raise ValueError(f"Unknown internal route: {href}")
    if href.startswith("/") and not href.startswith("/fr/") and href not in APP_LINKS:
        raise ValueError(f"Unknown application route: {href}")
    if not href.startswith(("/", "https://", "mailto:", "#")):
        raise ValueError(f"Unsafe link: {href}")


def anchor(label: str, href: str, css: str = "", current: bool = False) -> str:
    class_attr = f' class="{esc(css)}"' if css else ""
    current_attr = ' aria-current="page"' if current else ""
    return f'<a{class_attr} href="{esc(href)}"{current_attr}>{esc(label)}</a>'


def bouton(label: str, href: str, niveau: str = "plein") -> str:
    """Un seul dessin de bouton sur tout le site : la pilule. Plein, ou contour."""
    css = "cta" if niveau == "plein" else "cta cta--secondary"
    return anchor(label, href, css)


def lien_fleche(label: str, href: str) -> str:
    # La fleche reste collee au dernier mot : un libelle coupe sur deux lignes ne la renvoie pas au bord droit.
    # Une adresse e-mail garde le droit de se couper : sa fleche reste a cote du libelle.
    label = _t(label)   # le libelle entier est traduit avant d'etre coupe en « debut + dernier mot »
    fleche = ('<svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h13m-5-6 6 6-6 6" '
              'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
    tete, espace, dernier = label.rpartition(" ")
    if "@" in dernier or len(dernier) > 18:
        return f'<a class="lien-fleche" href="{esc(href)}"><span>{esc(label)}</span>{fleche}</a>'
    # Un petit mot avant la fin reste avec elle (« des cours », « des enfants »).
    if espace and re.fullmatch(rf"(?i:{_PETITS_TEXTE})", tete.rsplit(" ", 1)[-1]):
        espace = "\u00a0"
    return (f'<a class="lien-fleche" href="{esc(href)}"><span>{esc(tete)}{espace}'
            f'<span class="lien-fleche__fin">{esc(dernier)}{fleche}</span></span></a>')


# --- Images ------------------------------------------------------------------

def scene(images: dict, ident: str, tailles: str, css: str = "", prioritaire: bool = False,
          attributs: str = "") -> str:
    """Une illustration detouree, en WebP a plusieurs largeurs, legendee comme telle (cahier C.4).

    Quand l'image a des calques (content/images.json), elle est posee en deux couches : le fond, puis la partie
    qui bouge. Au repos, les deux couches redonnent exactement l'image entiere ; sans JavaScript ou en mouvement
    reduit, rien ne bouge."""
    image = images["images"][ident]
    largeurs = image_largeurs(images, ident)
    grande = largeurs[-1]
    hauteur = round(image["hauteur"] * grande / image["largeur"])
    chargement = 'fetchpriority="high"' if prioritaire else 'loading="lazy"'
    porte = image.get("porte")
    calques = image.get("calques")
    style = f' style="--fx:{porte[0]};--fy:{porte[1]}"' if porte else ""
    if image.get("forme") in ("cercle", "arche"):
        css = f"{css} scene--{image['forme']}".strip()
    # Un rendu d'un autre style (lot 2) se montre comme un detail, pas comme une scene.
    if image.get("taille") == "detail":
        css = f"{css} scene--detail".strip()

    def img(nom: str, alt: str, extra: str = "", charge: str = chargement) -> str:
        srcset = ", ".join(f"{ASSETS}/scene-{nom}-{w}.webp {w}w" for w in largeurs)
        return (f'<img{extra} src="{ASSETS}/scene-{nom}-{grande}.webp" srcset="{srcset}" sizes="{esc(tailles)}" '
                f'width="{grande}" height="{hauteur}" alt="{esc(alt)}" decoding="async" {charge}>')

    if calques:
        anime = (f' data-anime="{esc(calques["anime"])}" data-libelle-arret="{esc(_t("Arrêter l’animation du tapis"))}"'
                 f' data-libelle-relance="{esc(_t("Relancer l’animation du tapis"))}"')
        zone = calques.get("zone")
        if zone:
            style = (style[:-1] + ";" if style else ' style="') + "--zx:{};--zy:{};--zl:{};--zh:{}\"".format(*zone)
        couches = img(f"{ident}-fond", image["alt"]) + "".join(
            img(f"{ident}-{nom}", "", f' class="scene__calque scene__calque--{esc(nom)}" aria-hidden="true"')
            for nom in calques["noms"])
    else:
        anime = ""
        couches = img(ident, image["alt"])
    # La largeur du fichier le plus grand : un detail cadre ne s'affiche jamais plus grand (il deviendrait flou).
    style = (style[:-1] + ";" if style else ' style="') + f'--natif:{grande}px"'
    return (f'<figure class="scene {esc(css)}"{style}{anime}{attributs}><span class="scene__cadre">{couches}</span>'
            '</figure>')


def teinte_jour(direction: dict) -> bool:
    """Teinte « jour » (directeur, 04/11/2026) : la mise en page de l'ambiance violette sur le fond clair de l'application ;
    le violet ne reste que sur les actions principales et ce qui compte le plus."""
    return direction.get("ambiance", "clair") == "violet" and direction.get("teinte", "violet") == "jour"


def logo_entete(ambiance: str = "clair", jour: bool = False) -> str:
    """En-tete : logo horizontal (violet sur clair, blanc sur sombre ou sur le violet), symbole seul sur telephone."""
    h, hw, hh = LOGO["horizontal"]
    hb = LOGO["horizontal-blanc"][0]
    s, sw, sh = LOGO["symbole"]
    sb = LOGO["symbole-blanc"][0]
    if jour:
        # Teinte jour : toujours clair (color-scheme light), donc toujours le logo violet officiel.
        return ('<picture>'
                f'<source media="(max-width: 599px)" srcset="{ASSETS}/{s}" width="{sw}" height="{sh}">'
                f'<img src="{ASSETS}/{h}" width="{hw}" height="{hh}" alt=""></picture>')
    if ambiance == "violet":
        return ('<picture>'
                f'<source media="(max-width: 599px)" srcset="{ASSETS}/{sb}" width="{sw}" height="{sh}">'
                f'<img src="{ASSETS}/{hb}" width="{hw}" height="{hh}" alt=""></picture>')
    return ('<picture>'
            f'<source media="(max-width: 599px) and (prefers-color-scheme: dark)" srcset="{ASSETS}/{sb}" width="{sw}" height="{sh}">'
            f'<source media="(max-width: 599px)" srcset="{ASSETS}/{s}" width="{sw}" height="{sh}">'
            f'<source media="(prefers-color-scheme: dark)" srcset="{ASSETS}/{hb}">'
            f'<img src="{ASSETS}/{h}" width="{hw}" height="{hh}" alt=""></picture>')


# --- Sections generiques --------------------------------------------------------

NOMS_A_TRAIT = re.compile(r"(?<![\w’'])((?:[dl][’'])?A[lnrsz]-[A-ZÀ-Ý][\wÀ-ÿ’']*)")
MEME = re.compile(r"(?<![\w’'])(\w+-mêmes?)\b")


# Texte courant : seuls les mots d'une ou deux lettres se lient au mot suivant (avec les nombres a leur unite).
# Lier davantage laisse des blocs trop longs et un bord droit tres irregulier dans les colonnes etroites.
_PETITS_TEXTE = r"le|la|de|du|à|au|en|et|ou|un|ne|ce|se|sa|il|on|y|a"
PETITS_MOTS_TEXTE = re.compile(rf"(?<![\w’'])((?i:{_PETITS_TEXTE})|\d+(?:,\d+)?) (?=\S)")


# Derniere passe typographique, sur la page entiere (05/11/2026, avant la mise en production) : certains textes ne passent
# ni par titre_html ni par texte_html (blocs generes, legendes, lignes de tarifs, citations). Dans le texte visible
# seulement (ni balise, ni attribut, ni script, ni style, ni texte arabe), une espace ordinaire avant : ; ? ! » ou apres «
# devient insecable : le signe ne commence jamais une ligne, et le guillemet ne se separe pas de son mot.
_JETONS_HTML = re.compile(r"(<script\b.*?</script>|<style\b.*?</style>|<pre\b.*?</pre>|<textarea\b.*?</textarea>|<!--.*?-->|<[^>]+>)",
                          re.S | re.I)
_VIDES = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}


def typographie_finale(page_html: str) -> str:
    morceaux = _JETONS_HTML.split(page_html)
    pile: list[tuple[str, bool]] = []
    for i, morceau in enumerate(morceaux):
        if i % 2:  # une balise, ou un bloc protege
            m = re.match(r"<(/?)([a-zA-Z][\w:-]*)", morceau)
            if not m or morceau.endswith("/>"):
                continue
            nom = m.group(2).lower()
            if m.group(1):
                for k in range(len(pile) - 1, -1, -1):
                    if pile[k][0] == nom:
                        del pile[k:]
                        break
            elif nom not in _VIDES and not re.match(r"<(script|style|pre|textarea)\b", morceau, re.I):
                pile.append((nom, bool(re.search(r'\blang="ar', morceau))))
            continue
        if not morceau.strip() or any(arabe for _, arabe in pile):
            continue
        morceaux[i] = re.sub(r"« ", "« ", re.sub(r" ([:;?!»])", " \\1", morceau))
    return "".join(morceaux)


def texte_html(value: str) -> str:
    """Texte courant : espace insecable avant les deux-points, le point-virgule et les points d'interrogation et
    d'exclamation ; un petit mot se lie au mot qui le suit et un nombre a son unite (« de 3 à 5 élèves ») ; le
    dernier mot ne reste pas seul sur sa ligne ; un nom comme Az-Zalzalah ne se coupe pas a son trait d'union."""
    value = _t(value)
    fin = re.sub(r" ([:;?!])", "\u00a0\\1", value)
    # « n° 1829 a » (numero d'un hadith) ne se coupe ni apres « n° », ni avant la lettre qui suit le numero.
    fin = re.sub(r"(?<!\w)n° (\d+)(?: ([a-z])(?!\w))?",
                 lambda m: "n°\u00a0" + m.group(1) + (f"\u00a0{m.group(2)}" if m.group(2) else ""), fin)
    fin = PETITS_MOTS_TEXTE.sub(lambda m: m.group(1) + "\u00a0", fin)
    # Une adresse e-mail garde sa place a la ligne : elle ne se colle pas au mot qui la precede.
    fin = re.sub(r"\u00a0(?=\S*@)", " ", fin)
    tete, espace, dernier = fin.rpartition(" ")
    precedent = tete.rsplit(" ", 1)[-1]
    # Le dernier mot rejoint le mot qui le precede si l'ensemble reste tres court (« ne convient pas. ») : au-dela,
    # le bloc laisse une ligne courte au-dessus (mesure du 21/10 : 14 signes au plus, lignes courtes 6 a 15 %).
    if (espace and len(dernier) <= 12 and "@" not in dernier and "@" not in precedent and len(tete.split()) >= 3
            and len(precedent) + 1 + len(dernier) <= 14):
        fin = f"{tete}\u00a0{dernier}"
    # Un bloc insecable de plus de 24 signes laisse une ligne courte avant lui : on rend ses premieres espaces.
    blocs = []
    for bloc in fin.split(" "):
        while len(bloc) > 24 and "\u00a0" in bloc:
            debut, bloc = bloc.split("\u00a0", 1)
            blocs.append(debut)
        blocs.append(bloc)
    fin = " ".join(blocs)
    fin = NOMS_A_TRAIT.sub(r'<span class="insecable">\1</span>', esc(fin))
    # « vous-même » ne se coupe pas a son trait d'union.
    return MEME.sub(r'<span class="insecable">\1</span>', fin)


# Anti-spam (directeur, 23/10/2026) : aucune adresse n'est ecrite telle quelle dans une page, ou un robot
# collecteur la lirait. site.js recompose le lien et l'arobase ; sans script, la feuille dessine l'arobase et
# l'adresse reste lisible a l'ecran.
COURRIEL = re.compile(r"([A-Za-z0-9._%+-]+)@((?:<wbr>)?)([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)")
MAILTO = re.compile(r' href="mailto:([^"@]+)@([^"?]+)((?:\?[^"]*)?)"')


def masquer_courriels(page: str) -> str:
    def lien(m: re.Match) -> str:
        return f' data-u="{m.group(1)}" data-d="{m.group(2)}"' + (f' data-q="{m.group(3)}"' if m.group(3) else "")
    return COURRIEL.sub(r'\1<span class="arobase"></span>\2\3', MAILTO.sub(lien, page))


def texte_riche(value: str) -> str:
    """texte_html, plus la mise en valeur « **debut de point.** » (balise strong), pour les listes que l'on parcourt vite
    (les articles). Une paire non fermee est une erreur de contenu : le build s'arrete plutot que d'afficher des asterisques."""
    if value.count("**") % 2:
        raise ValueError(f"Mise en valeur ** non fermee : {value[:60]}")
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", texte_html(value), flags=re.S)


# Les articles publies, du plus recent au plus ancien : remplie par build() avant le rendu, lue par la section
# generee « articles » du hub (/fr/articles). Un nouvel article y entre seul, sans retouche du hub.
_ARTICLES: list[tuple[str, dict]] = []
# Parution programmee (directeur, 03/11/2026 : « une publication automatique separee par 2 jours minimum ») : la date d'un
# article est celui de sa parution. La construction de production ne publie pas un article date apres le jour de la
# construction (ni sa page, ni sa carte, ni sa place dans le plan du site, ni les liens qui y menent) ; un apercu le montre,
# marque « à paraître », pour la relecture. Remplie par build().
_A_PARAITRE: set[str] = set()
# Pour la liste du hub : l'illustration de chaque article (direction.json) et le catalogue des images. Remplis par build().
_ILLUSTRATIONS_ARTICLES: dict[str, str] = {}
_IMAGES: dict = {}


def article_a_paraitre(route: str, page: dict, jour: date) -> bool:
    return route.startswith("/fr/articles/") and date.fromisoformat(page["date"]) > jour


def sans_articles_a_paraitre(pages: dict[str, dict], retires: set[str]) -> dict[str, dict]:
    """Les pages publiees ce jour-la : les articles a paraitre retires, et chaque lien qui y menait avec eux."""
    publiees = {}
    for route, page in pages.items():
        if route in retires:
            continue
        if any(l["href"] in retires for s in page["sections"] for l in s.get("links", [])):
            page = {**page, "sections": [{**s, "links": [l for l in s["links"] if l["href"] not in retires]}
                                         if s.get("links") else s for s in page["sections"]]}
        publiees[route] = page
    return publiees


def date_de_parution(route: str, page: dict) -> str:
    quand = esc(avis_mod.fmt_date(page["date"]))
    # Aucune note de publication sur le site, aperçu compris (directeur, 05/11) : un article pas encore paru ne porte que sa date.
    return quand if route in _A_PARAITRE else f"{_t('Publié le')} {quand}"


def duree_de_lecture(page: dict) -> str:
    """« 5 min » ; en arabe, le nom suit le nombre (3 a 10 : pluriel, sinon singulier)."""
    n = temps_de_lecture(page)
    if _LANGUE["code"] == "ar":
        return f"{n}\u00a0" + ("دقائق" if 3 <= n <= 10 else "دقيقة")
    return f"{n}\u00a0{_t('min')}"


def temps_de_lecture(page: dict) -> int:
    """Minutes de lecture, a 200 mots par minute (lecture attentive d'un texte qui cite des sources)."""
    morceaux = [page.get("intro", "")] + [t for s in page["sections"]
                                          for t in [s["title"], *s.get("paragraphs", []), *s.get("points", [])]]
    mots = len(re.findall(r"\w+", " ".join(morceaux)))
    return max(1, -(-mots // 200))


def signature_article(page: dict, route: str = "") -> str:
    """Sous le titre d'un article : qui l'a ecrit (lien vers sa presentation), quand, et combien de temps il demande."""
    auteur = page.get("auteur")
    if not auteur:
        return ""
    return (f'<p class="article-signature"><span>Par <a href="{esc(auteur["href"])}">{esc(auteur["nom"])}</a>, {esc(auteur["role"])}</span>'
            f'<span class="article-signature__meta"><time datetime="{esc(page["date"])}">{date_de_parution(route, page)}</time>'
            f' · {_t("Lecture :")} {duree_de_lecture(page)}</span></p>')


FLECHE_CARTE = ('<svg viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h13m-5-6 6 6-6 6" fill="none" '
                'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>')


def liste_articles() -> str:
    """Directeur, 03/11/2026 : « trop moches, couleurs et formes uniformes ». Le plus recent a la une, en grand, sur un fond clair ;
    les suivants en cartes illustrees dont la surface et la forme changent d'une carte a l'autre (verre, violet profond,
    arche). Toute la carte est le lien (le titre s'etire sur elle) ; le bouton « Lire l'article » dit ou aller."""
    if not _ARTICLES:
        return "<p>Aucun article n’est encore publié.</p>"
    cartes = []
    for rang, (route, page) in enumerate(_ARTICLES):
        une = rang == 0
        ident = _ILLUSTRATIONS_ARTICLES.get(route)
        visuel = (f'<div class="article-carte__visuel" aria-hidden="true">'
                  f'{scene(_IMAGES, ident, "(max-width: 839px) 80vw, 440px" if une else "(max-width: 839px) 70vw, 300px", "article-carte__scene")}'
                  f'</div>') if ident and _IMAGES else ""
        quand = date_de_parution(route, page) if route in _A_PARAITRE else esc(avis_mod.fmt_date(page["date"]))
        surtitre = '<p class="article-carte__surtitre">Le plus récent</p>' if une else ""
        cartes.append(
            f'<li class="article-carte{" article-carte--une" if une else ""}">{visuel}<div class="article-carte__texte">{surtitre}'
            f'<h3><a href="{esc(route)}">{titre_html(page["h1"])}</a></h3>'
            f'<p>{texte_html(page["description"])}</p>'
            f'<p class="article-carte__meta">{esc(page["auteur"]["nom"])} · {quand} · {duree_de_lecture(page)}</p>'
            f'<span class="article-carte__lire" aria-hidden="true">Lire l’article{FLECHE_CARTE}</span></div></li>')
    return f'<ul class="articles-liste" data-revele-enfants>{"".join(cartes)}</ul>'


# Citations en arabe des articles (directeur, 03/11/2026 : « là on a besoin de l'arabe, donc il le faut », exception datee
# au registre M-29, qui garde l'arabe hors des pages francaises partout ailleurs). Le Coran s'ecrit dans le texte du Complexe
# du Roi Fahd (KFGQPC UthmanicHafs v3.0, celui du Mushaf de l'application), un hadith dans Uthman Taha Naskh du meme
# editeur ; chacun suit, en bloc, le paragraphe qui le cite en francais.
CHIFFRES_ARABES = "٠١٢٣٤٥٦٧٨٩"
GENRES_CITATION = ("coran", "hadith", "texte")  # texte : un ouvrage savant cite en arabe (al-Ghazali, Ihya)


def chiffres_arabes(nombre: int) -> str:
    return "".join(CHIFFRES_ARABES[int(c)] for c in str(nombre))


def citation_arabe(bloc: dict) -> str:
    if bloc["genre"] == "coran":
        # La rosace du numero, comme dans le Mushaf de l'application (RosaceVerset) : un repere, muet pour un lecteur d'ecran.
        texte = " ".join(f'{esc(v["texte"])} <span class="rosace" aria-hidden="true">'
                         f'{chiffres_arabes(int(v["cle"].split(":")[1]))}</span>' for v in bloc["versets"])
    else:
        texte = esc(bloc["texte"])
    return (f'<figure class="citation-arabe citation-arabe--{bloc["genre"]}"><blockquote lang="ar" dir="rtl"><p>{texte}</p>'
            f'</blockquote><figcaption>{texte_html(bloc["legende"])}</figcaption></figure>')


def paragraphes(section: dict) -> str:
    blocs: dict[int, list[dict]] = {}
    for bloc in section.get("citations_arabes", []):
        blocs.setdefault(bloc["apres"], []).append(bloc)
    return "".join(f"<p>{texte_riche(p)}</p>" + "".join(citation_arabe(b) for b in blocs.get(i, []))
                   for i, p in enumerate(section.get("paragraphs", [])))


def points_liste(section: dict) -> str:
    points = section.get("points", [])
    if not points:
        return ""
    return ('<ul class="points">' + "".join(
        f'<li><span class="puce" aria-hidden="true"></span><span>{texte_riche(p)}</span></li>' for p in points) + "</ul>")


def liens_section(section: dict) -> str:
    liens = section.get("links", [])
    if not liens:
        return ""
    return '<div class="section-links">' + "".join(lien_fleche(l["label"], l["href"]) for l in liens) + "</div>"


def sans_numero(titre: str) -> str:
    """L'ordre se dit par la mise en page (liste ordonnee), pas par un « 1. » dans le titre."""
    return re.sub(r"^\d+\.\s*", "", titre)


def corps_genere(section: dict, sid: str, tarifs: dict | None, today: date | None, avis: dict | None) -> str:
    if section.get("generated", "").startswith("avis-"):
        if avis is None:
            raise ValueError(f"Section generated without avis: {sid}")
        return avis_mod.rendre_avis_section(section["generated"][len("avis-"):], avis)
    if section.get("generated") == "articles":
        return liste_articles()
    if section.get("generated"):
        if tarifs is None:
            raise ValueError(f"Section generated without tarifs: {sid}")
        return tarifs_mod.rendre_tarifs_section(section["generated"], tarifs, today or date.today())
    return ""


def render_section(section: dict, number: int, tarifs: dict | None = None, today: date | None = None,
                   avis: dict | None = None, gabarit: str = "editorial", figure: str = "",
                   cote_figure: str = "droite") -> str:
    sid = section.get("id") or f"section-{number}"
    if not re.fullmatch(r"[a-z][a-z0-9-]*", sid):
        raise ValueError(f"Invalid section id: {sid}")
    titre = sans_numero(section["title"])
    genere = corps_genere(section, sid, tarifs, today, avis)
    corps = f'{paragraphes(section)}{genere}{points_liste(section)}{liens_section(section)}'
    if section.get("generated") == "articles":
        return (f'<section class="section section--articles" id="{esc(sid)}" aria-labelledby="heading-{number}">'
                f'<div class="articles__tete" data-revele-enfants><h2 id="heading-{number}">{titre_html(titre)}</h2>{paragraphes(section)}</div>'
                f'{genere}{liens_section(section)}</section>')
    if gabarit == "question":
        ouvert = " open" if number == 1 else ""
        return (f'<details class="tuile" name="aide" id="{esc(sid)}"{ouvert}><summary><h2 id="heading-{number}">'
                f'{titre_html(titre)}</h2><span class="tuile__signe" aria-hidden="true"></span></summary>'
                f'<div class="tuile__corps">{corps}</div></details>')
    if gabarit == "lecture":
        return (f'<section class="lecture__section" id="{esc(sid)}" aria-labelledby="heading-{number}" data-revele-enfants>'
                f'<h2 id="heading-{number}">{titre_html(titre)}</h2>{corps}</section>')
    if gabarit == "contact":
        return (f'<section class="contact-ligne" id="{esc(sid)}" aria-labelledby="heading-{number}" data-revele-enfants>'
                f'<h2 id="heading-{number}">{titre_html(titre)}</h2><div class="contact-ligne__corps">{corps}</div></section>')
    if gabarit == "parcours":
        etapes = "".join(f'<li class="parcours__etape"><span>{texte_html(p)}</span></li>' for p in section.get("points", []))
        return (f'<section class="section section--parcours" id="{esc(sid)}" aria-labelledby="heading-{number}">'
                f'<div class="parcours__tete" data-revele-enfants><h2 id="heading-{number}">{titre_html(titre)}</h2>'
                f'{paragraphes(section)}{liens_section(section)}</div><ol class="parcours" data-revele-enfants>{etapes}</ol></section>')
    if gabarit == "pleine":
        # Bande pleine : le titre, la grande illustration au centre, puis le texte et ce qui l'accompagne cote a cote.
        plus = f'{genere}{points_liste(section)}'
        ecrit = f'{paragraphes(section)}{liens_section(section)}'
        texte = f'<div class="pleine__texte">{ecrit}</div>' if ecrit else ""
        cote = f'<div class="pleine__plus">{plus}</div>' if plus else ""
        return (f'<section class="section section--pleine" id="{esc(sid)}" aria-labelledby="heading-{number}">'
                f'<div class="pleine__tete" data-revele><h2 id="heading-{number}">{titre_html(titre)}</h2></div>'
                f'{figure}<div class="pleine__corps{" pleine__corps--deux" if plus and ecrit else ""}" data-revele-enfants>{texte}{cote}</div></section>')
    if gabarit == "duo":
        return (f'<section class="duo__carte" id="{esc(sid)}" aria-labelledby="heading-{number}">{figure}'
                f'<div class="duo__texte" data-revele-enfants><h2 id="heading-{number}">{titre_html(titre)}</h2>{corps}</div></section>')
    if gabarit == "carte":
        return (f'<section class="carte" id="{esc(sid)}" aria-labelledby="heading-{number}" data-revele-enfants>'
                f'<h2 id="heading-{number}">{titre_html(titre)}</h2>{corps}</section>')
    if gabarit == "etape":
        return (f'<li class="etape" id="{esc(sid)}" data-revele>{figure}<h2 id="heading-{number}">{titre_html(titre)}</h2>'
                f'<div class="etape__corps" data-revele-enfants>{corps}</div></li>')
    large = " section--large" if genere else ""
    if figure:
        return (f'<section class="section section--figure section--figure-{esc(cote_figure)}{large}" id="{esc(sid)}" '
                f'aria-labelledby="heading-{number}"><div class="section__grille">'
                f'<div class="section__texte" data-revele-enfants><h2 id="heading-{number}">{titre_html(titre)}</h2>{corps}</div>'
                f'{figure}</div></section>')
    return (f'<section class="section{large}" id="{esc(sid)}" aria-labelledby="heading-{number}">'
            f'<div class="section__grille"><div class="section__titre" data-revele><h2 id="heading-{number}">{titre_html(titre)}</h2></div>'
            f'<div class="section__corps" data-revele-enfants>{corps}</div></div></section>')


# --- Accueil ------------------------------------------------------------------

def _sections_par_id(page: dict) -> dict[str, dict]:
    return {s["id"]: s for s in page["sections"]}


def accueil_porte(page: dict, images: dict, cta: str) -> str:
    """Le premier ecran, et la scene signature : on passe la porte, on entre dans le cercle."""
    return f'''<section class="porte" id="haut" data-porte>
  <div class="porte__collant">
    <div class="porte__vue">
      <div class="porte__arche" aria-hidden="true"></div>
      {scene(images, "chemin", "(max-width: 839px) 150vw, 112vw", "porte__scene", prioritaire=True)}
      <div class="porte__rayons" aria-hidden="true"></div>
    </div>
    <div class="porte__texte" data-lignes>
      <h1>{titre_html(page['h1'])}</h1>
      <p class="hero-intro">{texte_html(page.get('intro', ''))}</p>
      <div class="action-row">{cta}{bouton("Voir les tarifs", "/fr/tarifs", "contour")}</div>
      <p class="rassurance">{texte_html("Rien n’est facturé avant l’ouverture de la classe. La première semaine est remboursée si le cours ne convient pas.")}</p>
    </div>
    <div class="porte__cercle">
      <div class="porte__disque" aria-hidden="true"></div>
      <p class="porte__phrase" aria-hidden="true"><span>Une petite classe.</span><br><span>Un enseignant attitré.</span></p>
      {scene(images, "halqa", "(max-width: 839px) 90vw, 50vw", "porte__halqa")}
    </div>
  </div>
</section>'''


def accueil_enonce(images: dict, tarifs: dict) -> str:
    return f'''<section class="enonce" aria-labelledby="enonce-titre">
  <h2 id="enonce-titre" class="sr-only">En bref</h2>
  <p class="enonce__texte" data-revele><span>Votre\u00a0classe commence à\u00a0l’heure.</span> <span>Vous ne\u00a0tenez plus le\u00a0rythme seul.</span></p>
</section>'''


def accueil_chapitres(page: dict, images: dict) -> str:
    """Le fondu lent : la porte reste, ceux qui viennent apprendre changent, au rythme du defilement."""
    s = _sections_par_id(page)
    # Le pere et le fils, la mere a la porte : des details serres ici ; leurs scenes entieres sont a la page Familles.
    chapitres = (("foyer", "detail-main-epaule"), ("cours", "transmission-lavande"), ("suivi", "detail-mere-dos"))
    # Les mains sont recadrees dans l'arche (object-fit et scale) : dessinees a environ 1 220 px, elles demandent le
    # grand fichier, et non celui qui suffit a la largeur de la fenetre.
    figures = "".join(
        scene(images, img, "(max-width: 839px) 92vw, 1220px" if (images["images"][img].get("calques") or {}).get("anime") == "mains"
              else "(max-width: 839px) 92vw, 44vw", "chapitres__image", attributs=f' data-chapitre-image="{i}"')
        for i, (_, img) in enumerate(chapitres))
    textes = []
    for i, (sid, _) in enumerate(chapitres):
        sec = s[sid]
        textes.append(
            f'<article class="chapitre" id="{esc(sid)}" aria-labelledby="chapitre-{sid}" data-chapitre="{i}">'
            f'<div class="chapitre__texte"><h2 id="chapitre-{sid}">{titre_html(sec["title"])}</h2>{paragraphes(sec)}{liens_section(sec)}</div>'
            f'<div class="chapitre__image-mobile">{scene(images, chapitres[i][1], "860px" if (images["images"][chapitres[i][1]].get("calques") or {}).get("anime") == "mains" else "92vw", "chapitres__image-mobile")}</div>'
            '</article>')
    return f'''<section class="chapitres" aria-label="Pour vos enfants et pour vous">
  <div class="chapitres__fenetre" aria-hidden="true"><div class="chapitres__pile">{figures}</div></div>
  <div class="chapitres__textes">{"".join(textes)}</div>
</section>'''


def accueil_etapes(page: dict, images: dict) -> str:
    """Les tuiles qui grandissent : l'ordre se lit a la taille, sans numeros."""
    sec = _sections_par_id(page)["fonctionnement"]
    # Trois details du meme chemin (la boucle de la page Academie) : on avance, les chemins se croisent autour d'un
    # enseignant, puis on passe la porte.
    etapes = (
        ("detail-famille-chemin", "Vous choisissez un horaire", "Parmi les horaires publiés, pour votre enfant ou pour vous."),
        ("detail-croisee", "La direction compose la classe", "Elle nomme l’enseignant et vous écrit à chaque étape."),
        ("detail-entree", "La classe commence", "Vous la rejoignez depuis l’application, à son horaire."),
    )
    tuiles = "".join(
        f'<li class="pousse__etape pousse__etape--{i}" data-revele>'
        f'<div class="pousse__tuile">{scene(images, img, "(max-width: 839px) 90vw, 40vw", "pousse__image")}</div>'
        f'<h3>{titre_html(titre)}</h3><p>{texte_html(texte)}</p></li>'
        for i, (img, titre, texte) in enumerate(etapes))
    return f'''<section class="pousse" id="fonctionnement" aria-labelledby="pousse-titre">
  <div class="pousse__entete" data-revele><h2 id="pousse-titre">{titre_html(sec["title"])}</h2><div class="pousse__corps">{paragraphes(sec)}{liens_section(sec)}</div></div>
  <ol class="pousse__liste">{tuiles}</ol>
</section>'''


def accueil_tarifs(page: dict, tarifs: dict) -> str:
    sec = _sections_par_id(page)["tarifs"]
    p = tarifs_mod.politique_affichee(tarifs)
    devise = p["devise"]
    formules = tarifs_mod.formules_editoriales()
    c = p["classes"]
    rangs = p["remisesFoyer"]
    intro_remise = (f"Les remises du foyer commencent au {tarifs_mod.fmt_rang(rangs[0]['aPartirDuRang'])} membre inscrit."
                    if rangs else "Le tarif est le même pour chaque membre du foyer.")
    hors_taxes = "hors taxes" if p["horsTaxes"] else "taxes comprises"

    def duree(cle: str) -> str:
        f = formules[cle]
        d = f["duree_minutes"]
        texte = f"{d // 60}\u00a0h" + (f"\u00a0{d % 60}" if d % 60 else "") if d >= 60 else f"{d}\u00a0min"
        pause = f", dont {f['pause_minutes']} min de pause" if f["pause_minutes"] else ""
        return f"Trois séances de {texte} par semaine{pause}"

    enfant = tarifs_mod.fmt_montant(p["tarifEnfantMineur"], devise)
    adulte = tarifs_mod.fmt_montant(p["tarifAdulteMineur"], devise)
    age = p["ageAdulte"]
    # Ce qui vaut pour les enfants comme pour les adultes (les deux encarts du 18/10 le disent) n'est dit qu'une fois,
    # sous les deux prix ; seule l'observation d'une seance reste propre aux enfants.
    communs = ("Le compte rendu de l’enseignant chaque fin de semaine", "Une séance annulée par l’académie est remplacée",
               "La première semaine remboursée si le cours ne convient pas", "Résiliable chaque mois")
    return f'''<section class="deux-champs" id="tarifs" aria-labelledby="tarifs-titre">
  <h2 id="tarifs-titre" class="deux-champs__titre" data-revele>{titre_html(sec["title"])}</h2>
  <div class="deux-champs__grille">
    <article class="champ champ--enfant" data-revele>
      <h3>{titre_html("Enfants et adolescents")}</h3>
      <p class="champ__prix"><span class="champ__montant">{esc(enfant)}</span><span class="champ__periode">par mois, {hors_taxes}</span></p>
      <p class="champ__public">{texte_html(f"De {tarifs_mod.AGE_ENFANT_MIN} à {age - 1} ans. {duree('enfant')}, dans une classe de {c['ouvertureMinimum']} à {c['tailleEnfant']} élèves.")}</p>
      <p class="champ__plus">{texte_html("L’observation d’une séance, deux minutes, en silence.")}</p>
    </article>
    <article class="champ champ--adulte" data-revele>
      <h3>Adultes</h3>
      <p class="champ__prix"><span class="champ__montant">{esc(adulte)}</span><span class="champ__periode">par mois, {hors_taxes}</span></p>
      <p class="champ__public">{texte_html(f"{age} ans et plus. {duree('adulte')}, dans une classe de {c['ouvertureMinimum']} à {c['tailleAdulte']} élèves.")}</p>
    </article>
  </div>
  <ul class="deux-champs__communs" data-revele-enfants>{"".join(f"<li>{texte_html(l)}</li>" for l in communs)}</ul>
  <div class="deux-champs__pied" data-revele>
    <p>{texte_html(intro_remise + (" " + sec["paragraphs"][0] if sec.get("paragraphs") else ""))}</p>
    <div class="action-row"><button class="cta cta--secondary" type="button" data-open-simulator>Simuler mon tarif</button>{lien_fleche("Voir les tarifs et les remises", "/fr/tarifs")}</div>
  </div>
</section>'''


def accueil_confiance(page: dict, images: dict, mot: dict | None = None, fondateurs: list | None = None) -> str:
    """Une bande sombre sur toute la largeur. En haut, le visage du directeur, cadre en largeur et cale au bord gauche
    de l'ecran (la photo y est coupee), a la hauteur du titre ; a cote, la date, une phrase de son mot signee et le lien
    vers ce mot. Dessous, les trois engagements cote a cote. La page Academie montre la meme photo en buste. Le titre
    vient avant la photo dans le document : un lecteur d'ecran l'entend d'abord ; la grille place la photo a gauche."""
    sec = _sections_par_id(page)["confiance"]
    # Les deux autres fondateurs sous le lien vers le mot du directeur : la phrase dit trois, la bande en montre trois.
    rangee = "".join(
        f'<li>{portrait(images, ident, "(max-width: 839px) 40vw, 300px", "portrait--vignette")}<p><span class="mot__nom">{esc(nom)}</span>'
        f'<span class="mot__role">{esc(role)}</span></p></li>' for nom, role, ident in (fondateurs or []))
    rangee = f'\n  <ul class="panneau__fondateurs" data-revele-enfants>{rangee}</ul>' if rangee else ""
    return f'''<section class="panneau" id="confiance" aria-labelledby="confiance-titre">
  <div class="panneau__in">
    <div class="panneau__tete" data-revele>
      <h2 id="confiance-titre">{titre_html(sec["title"])}</h2>
      <p class="panneau__depuis">{titre_html("Fondée le 1er mai 2024 par trois spécialistes du Coran.")}</p>
    </div>{citation_accueil(mot)}
    <div class="action-row" data-revele>{bouton("Lire le mot du directeur", "/fr/academie#mot", "contour")}</div>
  </div>
  <div class="panneau__photo" data-revele>{portrait(images, "portrait-directeur-visage", TAILLES_PORTRAIT, "portrait--visage")}</div>{rangee}
  <ul class="panneau__promesses" data-revele-enfants>
    <li><h3>{titre_html("Un programme qui avance")}</h3><p>{texte_html("Chaque étape a son objectif et sa date limite.")}</p></li>
    <li><h3>{titre_html("Un suivi pour les familles")}</h3><p>{texte_html("Retrouvez les séances et le travail à préparer dans votre espace familial.")}</p></li>
    <li><h3>{titre_html("Un tuteur pour chaque enfant")}</h3>{paragraphes(sec)}<p class="panneau__lien">{lien_fleche("Protection des enfants", "/fr/protection-des-enfants")}</p></li>
  </ul>
</section>'''


def citation_accueil(mot: dict | None) -> str:
    """Une phrase du mot du directeur (page Academie), signee hors de la citation : sur l'accueil, la photo n'est pas
    anonyme."""
    if not mot or not mot.get("extrait"):
        return ""
    sig = mot["signature"]
    return (f'\n    <figure class="panneau__citation" data-revele><blockquote><p>« {texte_html(mot["extrait"])} »</p></blockquote>'
            f'<figcaption class="panneau__signature"><span class="mot__nom">{esc(sig["nom"])}</span>'
            f'<span class="mot__role">{esc(sig["role"])}</span></figcaption></figure>')


QUESTIONS_ACCUEIL = (
    ("Mon enfant peut-il commencer sans savoir lire ?",
     "Oui. Les débutants commencent par les bases, avec un parcours adapté à leur niveau."),
    ("Comment est proposée la classe ?",
     "Vous choisissez un horaire parmi ceux que nous publions. La direction compose la classe, nomme l’enseignant"
     " et vous écrit à chaque étape. La classe a ensuite un horaire fixe."),
    ("Puis-je observer une séance ?",
     "Oui, deux minutes par séance, en silence, lorsque l’observation est autorisée : vous écoutez sans activer votre"
     " micro ni votre caméra."
     " L’enfant et l’enseignant sont informés de votre présence."),
    ("Puis-je m’inscrire pour moi-même ?",
     "Oui. Dès {age_adulte} ans, la formule adulte vous est ouverte : vous vous inscrivez dans l’application."),
    ("Que se passe-t-il si le cours ne convient pas ?",
     "La première semaine est remboursée en entier si vous arrêtez pendant la semaine qui suit la première"
     " séance. Ensuite, l’abonnement mensuel s’arrête quand vous le souhaitez, à la fin du mois en cours."),
    ("Payons-nous avant l’ouverture de la classe ?",
     "Non. Une classe ouvre dès trois inscrits. Avant cela, vous êtes en liste d’attente et rien n’est facturé."),
)


def accueil_faq(page: dict, tarifs: dict) -> str:
    """Les questions des familles en accordeon, sur une colonne : la premiere ouverte, les autres se deplient
    (details et summary : sans JavaScript, au clavier et au lecteur d'ecran)."""
    sec = _sections_par_id(page)["faq-articles"]
    age_adulte = str(tarifs_mod.politique_affichee(tarifs)["ageAdulte"])
    questions = "".join(
        f'<li class="faq-ouverte__question"><details{" open" if i == 0 else ""}><summary><h3>{titre_html(q)}</h3></summary>'
        f'<p>{texte_html(r.replace("{age_adulte}", age_adulte))}</p></details></li>'
        for i, (q, r) in enumerate(QUESTIONS_ACCUEIL))
    return f'''<section class="faq-ouverte" id="faq-articles" aria-labelledby="faq-titre">
  <div class="faq-ouverte__tete" data-revele><h2 id="faq-titre">{titre_html(sec["title"])}</h2><div class="faq-ouverte__intro">{paragraphes(sec)}
    <ul class="liste-liens"><li>{lien_fleche("Comprendre le déroulement des cours", "/fr/cours")}</li><li>{lien_fleche("Accompagner son enfant", "/fr/familles")}</li><li>{lien_fleche("Consulter l’aide", "/fr/aide")}</li><li>{lien_fleche("Voir la page des avis", "/fr/avis")}</li></ul></div></div>
  <ul class="faq-ouverte__liste" data-revele-enfants>{questions}</ul>
</section>'''


FLECHE = ('<svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h13m-5-6 6 6-6 6" '
          'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>')


def note_de_fin(section: dict) -> str:
    """Une section reprise dans la fin de page, a cote du titre et de son bouton (Comment ca marche : l'inscription
    d'un enfant)."""
    return (f'<div class="appel__note"><h3>{titre_html(section["title"])}</h3>{paragraphes(section)}'
            f'{liens_section(section)}</div>')


def bande_finale(titre: str, phrase: str, label: str, href: str, identifiant: str = "inscription",
                 seuil: bool = False, arche: str = "", forme: str = "", extra: str = "") -> str:
    """La fin de page, sous deux formes.
    - Accueil et pages principales (seuil, direction.json fin.seuil) : la page se referme sur un titre de la taille de
      son titre d'ouverture, pose sur le fond, et ce titre est le lien ; chaque page finit sur sa propre phrase. Quand le
      libelle de l'action differe du titre, les lecteurs d'ecran l'entendent a la suite. L'accueil (arche) se referme
      sous une arche entiere, sur son titre, sa phrase et un bouton. Pour que les pages ne finissent pas toutes pareil
      (direction.json fin.forme) : « centre », un bandeau lavande, le titre et sa phrase au centre, un bouton ;
      « sombre », le titre lien sur une bande sombre ; « prix », le titre et son bouton a cote des deux prix (la page
      des tarifs finit sur ce qu'elle annonce) ; « image », le titre et son bouton a cote d'une arche entiere (extra),
      « image-gauche » l'arche a gauche ; « note », le titre et son bouton a cote d'une section de la page (fin.note),
      qui n'est plus posee plus haut : une seule fin, et non deux bandes a la suite.
    - Autres pages : une bande sobre et son bouton."""
    externe = href.startswith("mailto:")
    messagerie = '<span class="sr-only"> (ouvre votre messagerie)</span>' if externe else ""
    if forme == "centre":
        return f'''<section class="appel appel--centre" id="{esc(identifiant)}" aria-labelledby="appel-titre">
  <h2 id="appel-titre" class="appel__titre" data-revele>{titre_html(titre)}</h2>
  <p class="appel__phrase" data-revele>{texte_html(phrase)}</p>
  <div class="action-row" data-revele>{bouton(label, href)}</div>
</section>'''
    if forme in ("prix", "image", "note", "image-gauche"):
        classes = f"appel--{forme}" + (" appel--image" if forme == "image-gauche" else "")
        return f'''<section class="appel {classes}" id="{esc(identifiant)}" aria-labelledby="appel-titre">
  <div class="appel__texte">
    <h2 id="appel-titre" class="appel__titre" data-revele>{titre_html(titre)}</h2>
    <p class="appel__phrase" data-revele>{texte_html(phrase)}</p>
    <div class="action-row" data-revele>{bouton(label, href)}</div>
  </div>
  <div class="appel__extra" data-revele-enfants>{extra}</div>
</section>'''
    if seuil and arche:
        # L'accueil se referme sous une arche entiere, sur son titre, sa phrase et un vrai bouton (et non un titre lien).
        return f'''<section class="appel appel--seuil appel--porte" id="{esc(identifiant)}" aria-labelledby="appel-titre">{arche}
  <h2 id="appel-titre" class="appel__titre" data-revele>{titre_html(titre)}</h2>
  <p class="appel__phrase" data-revele>{texte_html(phrase)}</p>
  <div class="action-row" data-revele>{bouton(label, href)}</div>
</section>'''
    if seuil:
        titre = _t(titre)
        debut, _, dernier = titre.rpartition(" ")
        texte = (titre_html(debut) + " " if debut else "") + f'<span class="insecable">{titre_html(dernier)}{FLECHE}</span>'
        action = "" if label.rstrip(".").casefold() == titre.rstrip(".").casefold() else f'<span class="sr-only"> ({esc(label)})</span>'
        return f'''<section class="appel appel--seuil{" appel--sombre" if forme == "sombre" else ""}" id="{esc(identifiant)}" aria-labelledby="appel-titre">
  <h2 id="appel-titre" class="appel__titre" data-revele><a class="appel__titre-lien" href="{esc(href)}">{texte}{action}{messagerie}</a></h2>
  <p class="appel__phrase" data-revele>{texte_html(phrase)}</p>
</section>'''
    return f'''<section class="appel appel--sobre" id="{esc(identifiant)}" aria-labelledby="appel-titre">
  <a class="appel__lien" href="{esc(href)}">
    <div class="appel__haut"><h2 id="appel-titre">{titre_html(titre)}</h2><p class="appel__phrase">{texte_html(phrase)}</p><span class="appel__bouton">{esc(label)}{messagerie}{FLECHE}</span></div>
  </a>
</section>'''


# Les extraits d'avis vivent sur les pages ou une famille hesite (directeur, 03/11/2026) ; la page /fr/avis reste le depot
# central. Rien ne s'affiche tant que bloc_avis.AVIS_APERCU_MIN avis ne sont pas publies.
PAGES_APERCU_AVIS = ("/fr/cours", "/fr/familles", "/fr/tarifs")


def apercu_avis(avis: dict | None) -> str:
    if not avis:
        return ""
    return avis_mod.rendre_avis_apercu(avis, lien_fleche("Lire tous les avis", "/fr/avis"))


def render_home(page: dict, images: dict, tarifs: dict, cta: str, mot: dict | None = None,
                fondateurs: list | None = None, avis: dict | None = None) -> str:
    fin = _sections_par_id(page)["footer"]
    return "".join((
        accueil_porte(page, images, cta),
        accueil_enonce(images, tarifs),
        accueil_chapitres(page, images),
        accueil_etapes(page, images),
        accueil_tarifs(page, tarifs),
        accueil_confiance(page, images, mot, fondateurs),
        apercu_avis(avis),
        accueil_faq(page, tarifs),
        # Comme les pages principales, l'accueil se referme sur une phrase qui est le lien : elle dit pour qui.
        bande_finale((fin.get("paragraphs") or [fin["title"]])[0], "L’inscription se fait dans l’application Rewayah.",
                     page["cta"]["label"], page["cta"]["href"], seuil=True,
                     arche=scene(images, "eleve-enseignante-b", "(max-width: 839px) 72vw, 480px", "appel__arche")),
    ))


# --- Pages interieures -------------------------------------------------------------

def lettres_arabes(texte: str) -> str:
    """Ce qu'une arche de Cours fait lire, pose pour s'ecrire lettre apres lettre (styles/site.css) : des lettres
    separees (« ا ب ت ث ») chacune dans sa balise, dans l'ordre de l'ecriture ; un mot lie (« القُرْآن ») entier, pour ne
    jamais casser la liaison de ses lettres (il s'ecrit d'un trait, de droite a gauche)."""
    morceaux = texte.split(" ")
    if len(morceaux) == 1:
        return f'<span class="parcours__mot">{esc(texte)}</span>'
    return " ".join(f'<span class="parcours__lettre" style="--l:{i}">{esc(m)}</span>' for i, m in enumerate(morceaux))


def libelle_arche(point: str) -> str:
    """Libelle d'une arche du parcours : la precision apres la virgule passe dessous, plus petite et d'un seul tenant
    (« Les sourates courtes, » puis « d'Al-Fatiha à Az-Zalzalah », chaque nom d'un seul tenant)."""
    tete, virgule, precision = point.partition(", ")
    if not virgule:
        return f'<span>{texte_html(point)}</span>'
    return f'<span>{texte_html(tete)},<span class="parcours__precision"> {texte_html(precision)}</span></span>'


def blocs_prix(tarifs: dict) -> str:
    """Les deux prix, enfant et adulte, tels que la grille tarifaire les donne (haut et fin de la page des tarifs)."""
    p = tarifs_mod.politique_affichee(tarifs)
    hors_taxes = "hors taxes" if p["horsTaxes"] else "taxes comprises"
    return "".join(
        f'<p class="entete-prix__bloc"><span class="entete-prix__montant">{esc(tarifs_mod.fmt_montant(montant, p["devise"]))}</span>'
        f'<span class="entete-prix__periode">par mois, {hors_taxes}</span><span class="entete-prix__public">{texte_html(public)}</span></p>'
        for montant, public in ((p["tarifEnfantMineur"], f"Enfants et adolescents, de {tarifs_mod.AGE_ENFANT_MIN} à {p['ageAdulte'] - 1} ans"),
                                (p["tarifAdulteMineur"], f"Adultes, {p['ageAdulte']} ans et plus")))


def hero_interieur(route: str, page: dict, reglage: dict, images: dict, cta: str, status: str,
                   tarifs: dict | None = None, today: date | None = None) -> str:
    intro = signature_article(page, route) + (f'<p class="hero-intro">{texte_html(page["intro"])}</p>' if page.get("intro") else "")
    haut = reglage.get("haut")
    titre_long = (" entete-page__texte--long" if len(page["h1"]) > 22 else "") + (" entete-page__texte--tres-long" if len(page["h1"]) > 33 else "")
    texte = (f'<div class="entete-page__texte{titre_long}" data-lignes><h1>{titre_html(page["h1"])}</h1>'
             f'{intro}{status}<div class="action-row">{cta}</div></div>')
    # Chaque page interieure s'ouvre sur son propre sujet : les etapes, le parcours, ou le prix.
    if haut == "texte":
        return f'<section class="entete-page entete-page--haut-texte">{texte}</section>'
    if haut == "parcours":
        sec = _sections_par_id(page)[reglage["parcours"][0]]
        # Dans chaque arche, ce que l'eleve lit a cette etape, en arabe (decoratif : le libelle francais le dit).
        arabe = reglage.get("parcours_arabe") or [""] * len(sec.get("points", []))
        if len(arabe) != len(sec.get("points", [])):
            raise ValueError(f"direction.json {route}: parcours_arabe needs one entry per step")
        arches = "".join(
            '<li class="parcours__etape">'
            + (f'<span class="parcours__arabe" lang="ar" dir="rtl" aria-hidden="true">{lettres_arabes(a)}</span>' if a else "")
            + libelle_arche(p) + '</li>'
            for p, a in zip(sec.get("points", []), arabe))
        return (f'<section class="entete-page entete-page--haut-parcours">{texte}'
                f'<ol class="parcours parcours--haut" aria-label="{esc(sec["title"])}" data-revele-enfants>{arches}</ol></section>')
    if haut == "chiffres":
        # Comment ca marche s'ouvre aussi sur la taille des classes, en grands chiffres tires de la grille tarifaire :
        # la phrase de sa bande (direction.json) est dite ici, et la bande n'est plus posee plus bas.
        classes = tarifs_mod.politique_affichee(tarifs)["classes"]
        ouverture = classes["ouvertureMinimum"]
        lignes = "".join(f'<p class="entete-chiffres__bloc"><span class="entete-chiffres__nombre">{ouverture}\u00a0{_t("à")}\u00a0{taille}</span>'
                         f'<span class="entete-chiffres__libelle">{libelle}</span></p>'
                         for taille, libelle in ((classes["tailleEnfant"], "enfants par classe"),
                                                 (classes["tailleAdulte"], "adultes par classe")))
        bande = reglage.get("bande") or {}
        sous = f'<p class="entete-chiffres__sous">{texte_html(bande["sous"])}</p>' if bande.get("sous") else ""
        return (f'<section class="entete-page entete-page--haut-chiffres">{texte}'
                f'<div class="entete-chiffres" data-revele-enfants>{lignes}{sous}</div></section>')
    if haut == "prix":
        blocs = blocs_prix(tarifs)
        # Les deux prix ouvrent la page et la referment (fin.forme « prix ») ; leurs mentions ne sont dites qu'une fois :
        # la date d'effet, s'il y en a une, sous les prix du haut ; les monnaies et les taxes dans « À savoir avant de
        # commander », plus bas sur la page.
        date_effet = tarifs_mod.note_date_effet(tarifs, today or date.today())
        notes = f'<p class="entete-prix__note">{esc(date_effet)}</p>' if date_effet else ""
        return (f'<section class="entete-page entete-page--haut-prix">{texte}'
                f'<div class="entete-page__arche">{scene(images, reglage["image"], "(max-width: 839px) 72vw, 480px", "entete-page__image", prioritaire=True)}</div>'
                f'<div class="entete-prix" data-revele-enfants>{blocs}{notes}</div></section>')
    if haut == "gros-plan":
        # Un gros plan dans une grande arche qui deborde du bord droit : les personnes, pas la porte entiere.
        return (f'<section class="entete-page entete-page--haut-gros-plan">{texte}'
                f'<div class="entete-page__panneau">{scene(images, reglage["image"], "(max-width: 839px) 100vw, 56vw", "entete-page__image", prioritaire=True)}</div></section>')
    image = reglage.get("image")
    cote = reglage.get("cote", "droite")
    champ = reglage.get("champ", "lavande")
    cadre = " entete-page--libre" if reglage.get("cadre") == "libre" else ""
    tailles = "(max-width: 839px) 92vw, min(1200px, 92vw)" if cadre else "(max-width: 839px) 92vw, 52vw"
    if not image:
        return (f'<section class="entete-page entete-page--sobre"><div class="entete-page__texte" data-lignes>'
                f'<h1>{titre_html(page["h1"])}</h1>{intro}{status}'
                f'<div class="action-row">{cta}</div></div>'
                f'<img class="entete-page__ornement" src="{ASSETS}/ornement-contour.svg" width="494" height="777" alt=""></section>')
    if reglage.get("gabarit") == "lecture":
        return (f'<section class="entete-page entete-page--document entete-page--{esc(champ)}">'
                f'<div class="entete-page__texte" data-lignes><h1>{titre_html(page["h1"])}</h1></div>'
                f'<div class="entete-page__suite">{intro}{status}<div class="action-row">{cta}</div></div>'
                f'<div class="entete-page__arche" data-parallaxe>{scene(images, image, "(max-width: 839px) 92vw, 40vw", "entete-page__image", prioritaire=True)}</div></section>')
    return (f'<section class="entete-page entete-page--{esc(cote)} entete-page--{esc(champ)}{cadre}">'
            f'<div class="entete-page__texte{titre_long}" data-lignes><h1>{titre_html(page["h1"])}</h1>'
            f'{intro}{status}<div class="action-row">{cta}</div></div>'
            f'<div class="entete-page__arche" data-parallaxe>{scene(images, image, tailles, "entete-page__image", prioritaire=True)}</div></section>')


# Schema « la classe se forme » (planche de style du 21/10) : des points, jamais des personnes dessinees. Les chiffres
# viennent de la politique tarifaire (ouverture, tailles de classe) ; sans JavaScript, la classe complete reste affichee.
SCHEMA_CENTRE, SCHEMA_RAYON = (300, 220), 150


def _places_classe(n: int) -> list[tuple[float, float]]:
    import math
    return [(round(SCHEMA_CENTRE[0] + SCHEMA_RAYON * math.cos(-math.pi / 2 + i * 2 * math.pi / n), 1),
             round(SCHEMA_CENTRE[1] + SCHEMA_RAYON * math.sin(-math.pi / 2 + i * 2 * math.pi / n), 1)) for i in range(n)]


def sans_dessins(reglage: dict, direction: dict) -> dict:
    """Les dessins en code ne passent sur le site qu'apres l'accord du directeur (direction.json, « dessins »)."""
    bande = reglage.get("bande") or {}
    if direction.get("dessins") or "schema" not in bande:
        return reglage
    return {**reglage, "bande": {k: v for k, v in bande.items() if k != "schema"}}


def schema_classe(schema: dict, tarifs: dict) -> str:
    classes = tarifs_mod.politique_affichee(tarifs)["classes"]
    ouverture, enfants, adultes = classes["ouvertureMinimum"], classes["tailleEnfant"], classes["tailleAdulte"]
    places = "".join(f'<circle cx="{x}" cy="{y}" r="22" fill="none" stroke="#BA98FB" stroke-width="2" stroke-dasharray="4 6"/>'
                     for x, y in _places_classe(enfants))
    eleves = "".join(f'<circle r="16" fill="#FFFFFF" style="transform:translate({x}px,{y}px)"/>' for x, y in _places_classe(enfants))
    etapes = "".join(f'<li data-etape="{i}"><strong>{titre_html(e["titre"])}</strong> '
                     f'<span>{texte_html(e["texte"].format(ouverture=ouverture))}</span></li>'
                     for i, e in enumerate(schema["etapes"]))
    return (f'<div class="schema-classe" data-schema="classe" data-ouverture="{ouverture}" data-enfants="{enfants}" '
            f'data-adultes="{adultes}">'
            f'<figure class="schema-classe__figure"><svg viewBox="0 0 600 440" role="img" aria-labelledby="schema-classe-titre">'
            f'<title id="schema-classe-titre">{esc(schema["description"])}</title>'
            f'<circle class="schema-classe__anneau" cx="300" cy="220" r="150" fill="none" stroke="#BA98FB" stroke-width="6" '
            f'stroke-linecap="round"/>'
            f'<g class="schema-classe__places">{places}</g>'
            f'<path d="M262 268V214a38 38 0 0 1 76 0v54z" fill="#EEE6FA"/><circle cx="300" cy="212" r="15" fill="#8652E6"/>'
            f'<text x="300" y="304" text-anchor="middle" fill="#FFFFFF" font-size="20">{esc(schema["centre"])}</text>'
            f'<g class="schema-classe__eleves">{eleves}</g></svg><figcaption>Schéma</figcaption></figure>'
            f'<div class="schema-classe__texte"><ol class="schema-classe__etapes">{etapes}</ol>'
            f'<p class="schema-classe__etat" aria-live="polite">Classe complète : {enfants} enfants</p>'
            f'<div class="schema-classe__choix" role="group" aria-label="{esc(schema["choix"])}">'
            f'<button type="button" data-public="enfants" aria-pressed="true">Enfants</button>'
            f'<button type="button" data-public="adultes" aria-pressed="false">Adultes</button>'
            f'<button type="button" data-rejouer>Rejouer</button></div></div></div>')


def bande_image(reglage: dict, images: dict, tarifs: dict | None = None) -> str:
    bande = reglage.get("bande")
    if not bande:
        return ""
    sous = f'<p class="bande-image__sous">{texte_html(bande["sous"])}</p>' if bande.get("sous") else ""
    if bande.get("schema") and tarifs is not None:
        # La phrase en grand, puis le schema qui la montre : la classe se forme sous les yeux.
        return (f'<div class="fond fond--{esc(bande.get("fond", "lavande"))}"><div class="bande-phrase bande-phrase--schema" data-revele>'
                f'<p class="bande-phrase__phrase">{titre_html(bande["phrase"])}</p>{sous}'
                f'{schema_classe(bande["schema"], tarifs)}</div></div>')
    if not bande.get("image"):
        # Une phrase seule, en grand, sur un champ de couleur : un changement de fond dans la page.
        return (f'<div class="fond fond--{esc(bande.get("fond", "lavande"))}"><div class="bande-phrase" data-revele>'
                f'<p class="bande-phrase__phrase">{titre_html(bande["phrase"])}</p>{sous}</div></div>')
    if bande.get("fond"):
        # Une phrase en grand et un detail cadre, sur un champ de couleur : la phrase a gauche, l'image a droite.
        return (f'<div class="fond fond--{esc(bande["fond"])}"><div class="bande-image bande-image--detail" data-revele>'
                f'{scene(images, bande["image"], "(max-width: 839px) 72vw, 420px", "bande-image__scene")}'
                f'<div class="bande-image__texte"><p class="bande-phrase__phrase">{titre_html(bande["phrase"])}</p>{sous}</div></div></div>')
    return (f'<div class="bande-image bande-image--{esc(bande.get("forme", "large"))}" data-revele>'
            f'{scene(images, bande["image"], "100vw", "bande-image__scene")}'
            + (f'<div class="bande-image__texte"><p class="bande-image__phrase">{titre_html(bande["phrase"])}</p>{sous}</div>'
               if bande.get("phrase") else "") + '</div>')


def figure_section(reglage: dict, images: dict, sid: str) -> str:
    noms = (reglage.get("noms") or {}).get(sid)
    if noms:
        # Des noms en grand a la place d'une image : ils redisent le texte de la section, sans rien ajouter.
        lignes = "".join(f'<li><span class="noms__nom">{esc(n["nom"])}</span>'
                         + (f'<span class="noms__role">{esc(n["role"])}</span>' if n.get("role") else "") + "</li>" for n in noms)
        return f'<div class="section__figure section__figure--noms" data-revele><ul class="noms" aria-hidden="true">{lignes}</ul></div>'
    tuile = (reglage.get("tuiles") or {}).get(sid)
    if tuile:
        # Un chiffre en grand dans une arche, a la place d'une image : il redit le texte de la section (les trois
        # séances de la semaine), sans rien ajouter ; la vue du dessus de la classe reste ainsi a l'accueil seulement.
        return (f'<div class="section__figure section__figure--tuile" data-revele><p class="tuile-chiffre" aria-hidden="true">'
                f'<span class="tuile-chiffre__grand">{esc(tuile["grand"])}</span>'
                f'<span class="tuile-chiffre__petit">{esc(tuile["petit"])}</span></p></div>')
    ident = (reglage.get("figures") or {}).get(sid)
    if not ident:
        return ""
    image = images["images"][ident]
    panorama = " section__figure--panorama" if image["largeur"] / image["hauteur"] > 1.2 else ""
    tailles = "(max-width: 839px) 92vw, 720px" if panorama else "(max-width: 839px) 86vw, 600px"
    return (f'<div class="section__figure{panorama}" data-revele>'
            f'{scene(images, ident, tailles, "section__scene")}</div>')


def figure_pleine(reglage: dict, images: dict, sid: str) -> str:
    """La grande illustration d'une bande pleine, bornee en hauteur pour que tout l'ecran reste lisible."""
    ident = (reglage.get("figures") or {}).get(sid)
    image = images["images"][ident]
    ratio = round(image["largeur"] / image["hauteur"], 4)
    return (f'<div class="pleine__image" style="--ratio:{ratio}" data-revele>'
            f'{scene(images, ident, "(max-width: 839px) 92vw, 1200px", "section__scene")}</div>')


def portrait(images: dict, ident: str, tailles: str, variante: str = "") -> str:
    """Une vraie photo d'une personne, et non une illustration : jamais legendee « Illustration » ; son texte
    alternatif la nomme, et le texte qui l'entoure le redit (signature, citation)."""
    image = images["images"][ident]
    largeurs = image_largeurs(images, ident)
    grande = largeurs[-1]
    hauteur = round(image["hauteur"] * grande / image["largeur"])
    srcset = ", ".join(f"{ASSETS}/scene-{ident}-{w}.webp {w}w" for w in largeurs)
    return (f'<figure class="portrait{" " + variante if variante else ""}"><span class="portrait__cadre"><img src="{ASSETS}/scene-{ident}-{grande}.webp" '
            f'srcset="{srcset}" sizes="{esc(tailles)}" width="{grande}" height="{hauteur}" alt="{esc(image["alt"])}" '
            f'decoding="async" loading="lazy"></span></figure>')


# La photo calee au bord gauche occupe la colonne de gauche : 50vw + 12px - 120px au bureau, 88vw (520 px au plus) dessous.
TAILLES_PORTRAIT = "(max-width: 839px) min(88vw, 520px), calc(50vw - 108px)"


def section_mot(section: dict, number: int, images: dict, ident: str | None, profil: dict | None = None) -> str:
    """Le mot du directeur : sa photo calee au bord gauche de l'ecran (elle est coupee a gauche), sa parole a cote, et
    sous sa signature son parcours (son profil de fondateur : sa photo n'est montree qu'ici, une seule fois)."""
    if not ident:
        raise ValueError(f"Section {section['id']}: a citation needs its portrait in direction.json")
    if section.get("extrait") and section["extrait"] not in section["citation"]:
        raise ValueError(f"Section {section['id']}: extrait must be one of its citation paragraphs")
    sig = section["signature"]
    citation = "".join(f"<p>{texte_html(p)}</p>" for p in section["citation"])
    parcours = ('<ul class="mot__parcours profil__parcours">' + "".join(f"<li>{texte_html(l)}</li>" for l in profil["parcours"])
                + "</ul>") if profil else ""
    return (f'<section class="mot" id="{esc(section["id"])}" aria-labelledby="heading-{number}">'
            f'<div class="mot__photo" data-revele>{portrait(images, ident, TAILLES_PORTRAIT)}</div>'
            f'<div class="mot__texte" data-revele-enfants><h2 id="heading-{number}">{titre_html(section["title"])}</h2>'
            f'<blockquote class="mot__citation">{citation}</blockquote>'
            f'<p class="mot__signature"><span class="mot__nom">{esc(sig["nom"])}</span>'
            f'<span class="mot__role">{esc(sig["role"])}</span></p>{parcours}</div></section>')


# Un portrait de fondateur : une colonne de profil, 300 px au plus.
TAILLES_PROFIL = "(max-width: 431px) calc(100vw - 32px), 400px"


def section_fondateurs(section: dict, number: int, images: dict | None = None, portraits: dict | None = None,
                       deja: str | None = None) -> str:
    """Les fondateurs : le texte de la section, puis un profil par personne (portrait, role et diplomes). Les portraits
    sont traites avec la photo du directeur (meme fond, meme cadrage, meme etalonnage). L'arabe des noms et des
    diplomes attend le site en arabe (registre de marque, M-29) : on ne melange pas les deux langues sur une page."""
    # Le directeur (deja) est presente par son mot, avec sa photo et son parcours : ici, les deux autres fondateurs.
    profils_ici = [p for p in section["profils"] if p["nom"] != deja]
    noms = [_NOMS_FR.get(p["nom"], p["nom"]) for p in profils_ici]
    if portraits and set(portraits) != set(noms):
        raise ValueError(f"direction.json: les portraits des fondateurs doivent nommer {noms}, pas {sorted(portraits)}")
    profils = []
    for p in profils_ici:
        parcours = "".join(f"<li>{texte_html(l)}</li>" for l in p["parcours"])
        photo = portrait(images, portraits[_NOMS_FR.get(p["nom"], p["nom"])], TAILLES_PROFIL, "portrait--profil") if portraits else ""
        profils.append(f'<li class="profil">{photo}<h3>{titre_html(p["nom"])}</h3><p class="profil__role">{esc(p["role"])}</p>'
                       f'<ul class="profil__parcours">{parcours}</ul></li>')
    return (f'<section class="fondateurs" id="{esc(section["id"])}" aria-labelledby="heading-{number}">'
            f'<div class="fondateurs__tete" data-revele><h2 id="heading-{number}">{titre_html(section["title"])}</h2>'
            f'<div class="fondateurs__texte">{paragraphes(section)}{liens_section(section)}</div></div>'
            + (f'<p class="profils__intro">{texte_html(f"Aux côtés du directeur, {deja} :")}</p>' if deja else "")
            + f'<ul class="profils" data-revele-enfants>{"".join(profils)}</ul></section>')


def alternance(reglage: dict):
    """Cote des images de section : la premiere repond au haut de page, les suivantes alternent."""
    cote = "gauche" if reglage.get("cote", "droite") == "droite" else "droite"
    while True:
        yield cote
        cote = "gauche" if cote == "droite" else "droite"


def render_inner(route: str, page: dict, reglage: dict, images: dict, tarifs: dict, today: date | None,
                 avis: dict) -> str:
    gabarit = reglage.get("gabarit", "editorial")
    # Une section que la fin de page reprend (fin.note) n'est dite qu'une fois : dans la fin.
    note = (reglage.get("fin") or {}).get("note")
    sections = [s for s in page["sections"] if s["id"] != note]
    apres = reglage.get("bande", {}).get("apres") if reglage.get("bande") else None
    morceaux = []
    if gabarit == "question":
        tuiles = "".join(render_section(s, i, tarifs, today, avis, "question") for i, s in enumerate(sections, 1))
        return f'<div class="questions" data-revele-enfants>{tuiles}</div>'
    if gabarit == "lecture":
        sommaire = "".join(f'<li><a href="#{esc(s["id"])}">{esc(sans_numero(s["title"]))}</a></li>' for s in sections)
        corps = "".join(render_section(s, i, tarifs, today, avis, "lecture") for i, s in enumerate(sections, 1))
        return (f'<div class="lecture"><nav class="lecture__sommaire" aria-label="Sommaire de la page"><p>Sur cette page</p>'
                f'<ol>{sommaire}</ol></nav><div class="lecture__texte">{corps}</div></div>')
    if gabarit == "contact":
        lignes = "".join(render_section(s, i, tarifs, today, avis, "contact") for i, s in enumerate(sections, 1))
        return f'<div class="contacts">{lignes}</div>'
    if gabarit == "etapes":
        etapes = [s for s in sections if re.match(r"^\d+\.", s["title"])]
        autres = [s for s in sections if s not in etapes]
        liste = "".join(render_section(s, i, tarifs, today, avis, "etape", figure_section(reglage, images, s["id"]))
                        for i, s in enumerate(etapes, 1))
        morceaux.append(f'<ol class="etapes">{liste}</ol>')
        if reglage.get("haut") != "chiffres":
            morceaux.append(bande_image(reglage, images, tarifs))
        cotes = alternance(reglage)
        for i, s in enumerate(autres, 1):
            figure = figure_section(reglage, images, s["id"])
            rendu = render_section(s, len(etapes) + i, tarifs, today, avis, figure=figure,
                                   cote_figure=next(cotes) if figure else "droite")
            fond = reglage.get("fonds", {}).get(s["id"])
            morceaux.append(f'<div class="fond fond--{esc(fond)}">{rendu}</div>' if fond else rendu)
        return "".join(morceaux)
    cotes = alternance(reglage)
    # Deux sections de texte qui se suivent, sans image : on les pose cote a cote plutot que d'en faire deux
    # ecrans presque vides.
    groupe: list[tuple[int, dict]] = []

    def vider() -> None:
        if len(groupe) > 1:
            cartes = "".join(render_section(s, i, tarifs, today, avis, "carte") for i, s in groupe)
            # Deux longueurs tres differentes laisseraient un trou a cote de la carte courte : on les empile.
            longueurs = [len(" ".join(s.get("paragraphs", []) + s.get("points", []))) for _, s in groupe]
            pile = " groupe--pile" if max(longueurs) > 2.5 * max(min(longueurs), 1) else ""
            morceaux.append(f'<div class="groupe groupe--{len(groupe)}{pile}">{cartes}</div>')
        elif groupe:
            morceaux.append(render_section(groupe[0][1], groupe[0][0], tarifs, today, avis))
        groupe.clear()

    fonds = reglage.get("fonds", {})
    ids = [s["id"] for s in sections]
    # Un duo : deux sections voisines de la page, dans l'ordre. Une cle mal saisie ferait disparaitre du texte publie.
    for duo in reglage.get("duos", []):
        if len(duo) != 2 or any(d not in ids for d in duo) or ids.index(duo[1]) != ids.index(duo[0]) + 1:
            raise ValueError(f"direction.json {route}: a duo names two neighbouring sections, in page order: {duo}")
        if any(d in fonds or d == apres for d in duo):
            raise ValueError(f"direction.json {route}: a duo section cannot carry a fond or a bande: {duo}")
    for sid, noms in (reglage.get("noms") or {}).items():
        texte = " ".join(_sections_par_id(page)[sid].get("paragraphs", []))
        for n in noms:
            if n["nom"] not in texte or (n.get("role") and n["role"] not in texte):
                raise ValueError(f"direction.json {route}: noms.{sid} must repeat the section text ({n['nom']})")
    if reglage.get("haut") not in (None, "texte", "parcours", "prix", "gros-plan"):
        raise ValueError(f"direction.json {route}: unknown haut {reglage.get('haut')!r}")
    if reglage.get("haut") in ("prix", "gros-plan") and not reglage.get("image"):
        raise ValueError(f"direction.json {route}: haut = {reglage['haut']} needs an image")
    if reglage.get("haut") == "parcours" and len(reglage.get("parcours", [])) != 1:
        raise ValueError(f"direction.json {route}: haut = parcours shows exactly one parcours")
    premiers_duos = {d[0]: d for d in reglage.get("duos", [])}
    seconds_duos = {d[1] for d in reglage.get("duos", [])}
    for i, s in enumerate(sections, 1):
        figure = figure_section(reglage, images, s["id"])
        fond = fonds.get(s["id"])
        if fond not in (None, "lavande", "prune"):
            raise ValueError(f"direction.json: unknown fond {fond}")
        avant = len(morceaux)
        if reglage.get("haut") == "parcours" and s["id"] in reglage.get("parcours", []):
            # Les arches du parcours sont en haut de page : la section garde son titre et son texte.
            s = {k: v for k, v in s.items() if k != "points"}
        if s["id"] in seconds_duos:
            continue
        if s["id"] in premiers_duos:
            vider()
            voisine = sections[i]
            cartes = (render_section(s, i, tarifs, today, avis, "duo", figure)
                      + render_section(voisine, i + 1, tarifs, today, avis, "duo", figure_section(reglage, images, voisine["id"])))
            morceaux.append(f'<div class="duo">{cartes}</div>')
            continue
        if s.get("citation"):
            vider()
            nom = s["signature"]["nom"]
            profil = next((p for x in page["sections"] for p in x.get("profils", []) if p["nom"] == nom), None)
            morceaux.append(section_mot(s, i, images, (reglage.get("portraits") or {}).get(s["id"]), profil))
        elif s.get("profils"):
            vider()
            mot = next((x for x in page["sections"] if x.get("citation")), None)
            morceaux.append(section_fondateurs(s, i, images, (reglage.get("portraits") or {}).get(s["id"]),
                                               mot["signature"]["nom"] if mot else None))
        elif s["id"] in reglage.get("parcours", []) and reglage.get("haut") != "parcours":
            vider()
            morceaux.append(render_section(s, i, tarifs, today, avis, "parcours"))
        elif not figure and not s.get("generated") and not fond:
            groupe.append((i, s))
        elif figure and s["id"] in reglage.get("pleine", []):
            vider()
            morceaux.append(render_section(s, i, tarifs, today, avis, "pleine", figure_pleine(reglage, images, s["id"])))
        else:
            vider()
            rendu = render_section(s, i, tarifs, today, avis, figure=figure, cote_figure=next(cotes) if figure else "droite")
            if "section__figure--noms" in figure:
                # Avec des noms en grand, le titre de la section passe au-dessus des deux colonnes : il mene.
                rendu = re.sub(r'(<div class="section__texte"[^>]*>)(<h2[^>]*>.*?</h2>)',
                               r'<div class="section__titre-plein" data-revele>\2</div>\1', rendu, count=1, flags=re.S)
            morceaux.append(rendu)
        if fond:
            morceaux[-1] = f'<div class="fond fond--{fond}">{morceaux[-1]}</div>'
            assert len(morceaux) > avant
        if apres and s.get("id") == apres:
            vider()
            morceaux.append(bande_image(reglage, images, tarifs))
    vider()
    return "".join(morceaux)


# --- Page complete ---------------------------------------------------------------

def output_file(output: Path, route: str) -> Path:
    if route in ("/fr/", "/ar/", "/en/", "/es/", "/pt/"):
        return output / route.strip("/") / "index.html"
    return output / f"{route.lstrip('/')}.html"


def donnees_structurees(origin: str) -> str:
    """Organisation educative et site : seulement des faits publies (M-19, M-27). Aucun avis, aucune note, aucune
    adresse e-mail (anti-spam : un robot lit ces donnees comme la page)."""
    base = origin.rstrip("/")
    donnees = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "EducationalOrganization",
                "@id": base + "/#organisation",
                "name": "Rewayah Academy",
                "alternateName": "أكاديمية الرواية",
                "legalName": "REWAYAH ACADEMY LTD",
                "url": base + "/fr/",
                "logo": base + f"{ASSETS}/logo-horizontal.svg",
                # Les comptes officiels de l'academie (directeur, 24/10/2026), pour la fiche de Google.
                "sameAs": [
                    "https://www.facebook.com/share/1CVee2teiN/",
                    "https://www.instagram.com/rewayahacademy/",
                ],
            },
            {
                "@type": "WebSite",
                "@id": base + "/#site",
                "name": "Rewayah Academy",
                "url": base + "/fr/",
                "inLanguage": "fr",
                "publisher": {"@id": base + "/#organisation"},
            },
        ],
    }
    return ('<script type="application/ld+json">'
            + json.dumps(donnees, ensure_ascii=False).replace("</", "<\\/") + "</script>")


def fil_ariane(route: str, page: dict, origin: str, image: str = "") -> str:
    """Fil d'Ariane (accueil, puis la page) pour les pages interieures : Google l'affiche sous le titre, surtout sur
    telephone. Jamais sur /fr/avis : aucun balisage schema.org n'accompagne les avis (decision du 19/10/2026).
    Un article porte en plus son balisage Article : l'auteur est la personne qui le signe (le directeur, 03/11/2026),
    la date est celle du fichier de contenu."""
    if route in ("/fr/", "/fr/avis"):
        return ""
    base = origin.rstrip("/")
    noms = {href: label for label, href in (*NAV, *FOOTER)}
    noms.update({"/fr/comment-ca-marche": "Comment ça marche", "/fr/academie": "L’académie", "/fr/aide": "Aide",
                 "/fr/recrutement": "Recrutement", "/fr/contact": "Contact"})
    article = route.startswith("/fr/articles/")
    chemin = [("Accueil", base + "/fr/")] + ([("Articles", base + "/fr/articles")] if article else []) + [
        (page["h1"] if article else noms.get(route) or page["h1"], base + route)]
    fil = {"@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": i, "name": nom, "item": url} for i, (nom, url) in enumerate(chemin, 1)]}
    if article:
        organisation = {"@type": "Organization", "name": "Rewayah Academy", "url": base + "/fr/"}
        auteur = page.get("auteur")
        personne = ({"@type": "Person", "name": auteur["nom"], "jobTitle": auteur["role"][:1].upper() + auteur["role"][1:],
                     "url": base + auteur["href"], "worksFor": organisation} if auteur else organisation)
        donnees = {"@context": "https://schema.org", "@graph": [fil, {
            "@type": "Article", "headline": page["h1"], "description": page["description"], "inLanguage": "fr",
            "datePublished": page["date"], "dateModified": page["date"], "image": [image],
            "mainEntityOfPage": {"@type": "WebPage", "@id": base + route},
            "author": personne, "publisher": organisation}]}
    else:
        donnees = {"@context": "https://schema.org", **fil}
    return ('<script type="application/ld+json">'
            + json.dumps(donnees, ensure_ascii=False).replace("</", "<\\/") + "</script>")


def page_indexee(route: str, page: dict, allow_indexing: bool, avis: dict | None) -> bool:
    """Production seulement, page prete et indexable ; une page vide ne s'offre pas aux moteurs (les avis tant
    qu'aucun n'est publie, le hub des articles tant qu'aucun n'est paru)."""
    if not (allow_indexing and page.get("status") == "ready" and page.get("indexable", True)):
        return False
    if route == "/fr/articles":
        return any(r not in _A_PARAITRE for r, _ in _ARTICLES)
    return route != "/fr/avis" or bool(avis and avis.get("nombre"))


def render_page(route: str, page: dict, site: dict, origin: str, allow_indexing: bool,
                tarifs: dict | None = None, today: date | None = None, avis: dict | None = None,
                direction: dict | None = None, images: dict | None = None, mot: dict | None = None,
                fondateurs: list | None = None) -> str:
    if tarifs is None:
        tarifs, _ = tarifs_mod.charger_tarifs(env={}, journal=lambda *_: None)
    if avis is None:
        avis, _ = avis_mod.charger_avis(env={}, journal=lambda *_: None)
    if direction is None or images is None:
        direction, images = load_direction(load_content()[0])
    reglage = sans_dessins(direction["pages"].get(route, {}), direction)
    canonical = origin.rstrip("/") + route
    indexed = page_indexee(route, page, allow_indexing, avis)
    # En production, une page vide se tient hors de l'index mais laisse suivre ses liens vers les autres pages.
    robots = "index,follow" if indexed else "noindex,follow" if allow_indexing else "noindex,nofollow"
    nav_items = "".join(anchor(label, href, current=href == route) for label, href in NAV[:-1])
    connexion = anchor(NAV[-1][0], NAV[-1][1], "site-header__connexion")
    selecteur_entete = langues_mod.selecteur(_LANGUE["code"], route, _LANGUE["disponibles"])
    selecteur_pied = langues_mod.selecteur(_LANGUE["code"], route, _LANGUE["disponibles"], en_pied=True)
    nom_langue = langues_mod.NOMS[_LANGUE["code"]]
    contact = anchor("Nous contacter", "/fr/contact", current=route == "/fr/contact")
    footer_links = f'<li class="pied-contact pied-contact--bureau">{contact}</li>' + "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in FOOTER if href.startswith('/fr/legal/') or href in ('/fr/protection-des-enfants', '/fr/accessibilite'))
    discovery_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in (*NAV[:4], ('Comment ça marche', '/fr/comment-ca-marche'), ('L’académie', '/fr/academie'), ('Avis', '/fr/avis'), ('Aide', '/fr/aide'), ('Recrutement', '/fr/recrutement')))
    # Directeur, 23/10/2026 : les quatre adresses quittent le pied de page ; elles restent sur la page Contact (et les
    # mentions legales), que ce lien rend accessible depuis chaque page : dans « Decouvrir » sous 1100 px, en tete des
    # liens legaux au-dessus. Un seul des deux est affiche, et donc lu.
    discovery_links += f'<li class="pied-contact pied-contact--telephone">{contact}</li>'
    social_by_href = {item["href"]: item for item in site["social_links"]}
    academy_facebook = social_by_href["https://www.facebook.com/share/1CVee2teiN/"]
    academy_instagram = social_by_href["https://www.instagram.com/rewayahacademy/"]
    author_facebook = social_by_href["https://www.facebook.com/share/1D6H2EYhci/"]
    cta = bouton(page["cta"]["label"], page["cta"]["href"])
    if route == "/fr/tarifs":
        cta += (lien_fleche("Simuler mon tarif", "#tarif-simulator") +
                '<noscript><p class="price-note">Le simulateur demande JavaScript. Sans lui, les prix et les remises '
                'de cette page suffisent pour calculer le tarif de votre foyer.</p></noscript>')
    status = (
        '<p class="preview-note" role="status">Cette page est en préparation. '
        'Les éléments contractuels non vérifiés ne sont pas publiés.</p>'
        if page.get("status") == "blocked" else ""
    )
    if route == "/fr/":
        main = render_home(page, images, tarifs, cta, mot, fondateurs, avis)
        classe_page = "page-accueil"
    else:
        main = hero_interieur(route, page, reglage, images, cta, status, tarifs, today) + render_inner(route, page, reglage, images, tarifs, today, avis)
        if route in PAGES_APERCU_AVIS:
            main += apercu_avis(avis)
        fin = reglage.get("fin")
        if fin:
            # Une page qui a deja une section « inscription » (l'aide) donne un autre identifiant a sa fin.
            forme = fin.get("forme", "")
            if forme == "image" and fin.get("cote") == "gauche":
                forme = "image-gauche"
            extra = (blocs_prix(tarifs) if forme == "prix" else
                     scene(images, fin["image"], "(max-width: 839px) 72vw, 450px", "appel__image") if forme.startswith("image") else
                     note_de_fin(_sections_par_id(page)[fin["note"]]) if forme == "note" else "")
            main += bande_finale(fin["titre"], fin["phrase"], fin.get("label", page["cta"]["label"]),
                                 fin.get("href", page["cta"]["href"]), seuil=bool(fin.get("seuil")), forme=forme, extra=extra,
                                 identifiant="fin-de-page" if 'id="inscription"' in main else "inscription")
        classe_page = "page-" + (route.strip("/").split("/", 1)[1].replace("/", "-") if "/" in route.strip("/") else "accueil")
    # Sur la page des tarifs, le simulateur est dans la page, sous la grille ; sur l'accueil, une feuille qui s'ouvre.
    en_page = route == "/fr/tarifs"
    ouverture = ('<section class="simulator simulator--page" id="tarif-simulator" aria-labelledby="simulator-title">' if en_page else
                 '<dialog class="simulator" id="tarif-simulator" aria-labelledby="simulator-title">\n'
                 '      <form method="dialog"><button class="simulator__close" aria-label="Fermer le simulateur"><svg aria-hidden="true" viewBox="0 0 24 24" width="22" height="22"><path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg></button></form>')
    simulator = f'''{ouverture}
      <h2 id="simulator-title">Estimez le tarif de votre foyer</h2>
      <p>Indiquez le nombre d’élèves, puis l’âge de chacun, dans l’ordre d’inscription.</p>
      <div class="simulator__fields">
        <div class="simulator__champ"><label for="sim-total">Nombre d’élèves</label><span class="pas"><button type="button" data-pas="-1" aria-label="Un élève de moins">−</button><input type="number" inputmode="numeric" min="1" step="1" value="1" id="sim-total"><button type="button" data-pas="1" aria-label="Un élève de plus">+</button></span></div>
        <label>Paiement <select id="sim-paiement"></select></label>
        <label>Parrainage <input type="checkbox" id="sim-parrainage"></label>
      </div>
      <div class="simulator__fields" id="sim-students"></div>
      <div class="simulator__result" role="status" aria-live="polite" aria-atomic="true" id="sim-result"><p>Le simulateur demande JavaScript.</p></div>
      <script type="application/json" id="tarifs-data">{tarifs_mod.donnees_simulateur(tarifs)}</script>
      <p class="simulator__note">Prix hors taxes, pour un mois complet. Les taxes éventuelles sont indiquées avant paiement.</p>
      <a class="cta" href="/connexion">Commencer mon inscription</a>
    {"</section>" if en_page else "</dialog>"}''' if route in ("/fr/", "/fr/tarifs") else ""
    if en_page:
        # Le simulateur suit les deux prix du haut : on estime son foyer juste apres avoir lu le prix.
        fin_haut = main.index("</section>", main.index("entete-page--haut-prix")) + len("</section>")
        main = main[:fin_haut] + simulator + main[fin_haut:]
        simulator = ""
    # Apercu de partage (reseaux, WhatsApp, messageries) : une carte de marque de 1200 x 630 en JPEG (WhatsApp et Facebook
    # lisent mal le WebP), 70 Ko (WhatsApp demande moins de 300 Ko), la meme pour toutes les pages (directeur, 06/11).
    image_partage = "chemin"
    url_image_partage = origin.rstrip("/") + ASSETS + "/partage.jpg"
    alt_partage = "Rewayah Academy : le Coran en ligne, en petite classe. Une mère et sa fille marchent vers une porte ouverte en forme de livre."
    meta_partage = (
        f'<meta property="og:type" content="website"><meta property="og:site_name" content="Rewayah Academy">'
        f'<meta property="og:locale" content="fr_FR"><meta property="og:title" content="{esc(page["title"])}">'
        f'<meta property="og:description" content="{esc(page["description"])}"><meta property="og:url" content="{esc(canonical)}">'
        f'<meta property="og:image" content="{esc(url_image_partage)}">'
        f'<meta property="og:image:secure_url" content="{esc(url_image_partage)}">'
        f'<meta property="og:image:type" content="image/jpeg">'
        f'<meta property="og:image:width" content="1200">'
        f'<meta property="og:image:height" content="630">'
        f'<meta property="og:image:alt" content="{esc(alt_partage)}">'
        '<meta name="twitter:card" content="summary_large_image">'
        f'<meta name="twitter:title" content="{esc(page["title"])}">'
        f'<meta name="twitter:description" content="{esc(page["description"])}">'
        f'<meta name="twitter:image" content="{esc(url_image_partage)}">'
        f'<meta name="twitter:image:alt" content="{esc(alt_partage)}">'
    )
    jsonld = donnees_structurees(origin) if route == "/fr/" else fil_ariane(route, page, origin, url_image_partage)
    ambiance = direction.get("ambiance", "clair")
    jour = teinte_jour(direction)
    if ambiance == "violet":
        tete_couleurs = ('<meta name="color-scheme" content="light">\n'
                         '  <meta name="theme-color" content="#F7F5FE">') if jour else (
                        '<meta name="color-scheme" content="dark">\n'
                         '  <meta name="theme-color" content="#6538E4">')
        # Le halo qui suit la souris, puis l'arche geante de fond (directeur, 03/11/2026) : deux calques decoratifs.
        halo = ('<div class="halo" aria-hidden="true"></div><div class="fond-arche" aria-hidden="true"></div>'
                '<div class="fond-lumiere" aria-hidden="true"></div>')
    else:
        tete_couleurs = ('<meta name="color-scheme" content="light dark">\n'
                         '  <meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)">\n'
                         '  <meta name="theme-color" content="#16161E" media="(prefers-color-scheme: dark)">')
        halo = ""
    return masquer_courriels(f'''<!doctype html>
<html lang="fr" data-ambiance="{esc(ambiance)}"{' data-teinte="jour"' if jour else ''}>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  {tete_couleurs}
  <meta name="robots" content="{robots}">
  <meta name="description" content="{esc(page['description'])}">
  <link rel="canonical" href="{esc(canonical)}">
  {meta_partage}
  <script>document.documentElement.classList.add('js');setTimeout(function(){{if(!window.__mv)document.documentElement.classList.remove('js')}},2500)</script>
  <link rel="preload" href="{ASSETS}/dm-sans-latin.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="{ASSETS}/site.css">
  <script src="{ASSETS}/motion.js" defer></script>
  <script src="{ASSETS}/site.js" defer></script>
  <link rel="icon" type="image/svg+xml" href="{ASSETS}/symbole.svg">
  <link rel="apple-touch-icon" href="{ASSETS}/apple-touch-icon.png">
  <meta name="application-name" content="Rewayah Academy">
  <meta name="apple-mobile-web-app-title" content="Rewayah">
  <title>{esc(page['title'])}</title>
  {jsonld}
</head>
<body class="{esc(classe_page)}">
  {halo}
  <a class="skip-link" href="#contenu">Aller au contenu</a>
  <header class="site-header" data-entete>
    <div class="site-header__inner">
      <a class="brand site-header__brand" href="/fr/" aria-label="Rewayah Academy, accueil">{logo_entete(ambiance, jour)}</a>
      <nav class="site-nav" aria-label="Navigation principale">{nav_items}</nav>
      {connexion}{selecteur_entete}<a class="site-header__inscription" href="/connexion">S’inscrire</a>
      <details class="mobile-menu"><summary><span class="mobile-menu__libelle sr-only">Menu</span><span class="mobile-menu__icone" aria-hidden="true"></span></summary><nav aria-label="Navigation mobile">{nav_items}{anchor(NAV[-1][0], NAV[-1][1])}</nav></details>
    </div>
  </header>
  <main class="site-main" id="contenu">
    {main}
  </main>
  {simulator}
  <footer class="site-footer"><div class="pied-calques" aria-hidden="true"><div class="pied-carte"><span class="pied-carte__points"></span></div><span class="pied-symbole"></span></div><div class="site-footer__inner">
     <div class="footer-identity"><a class="brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="{ASSETS}/{LOGO["horizontal-encre"][0] if jour else "logo-horizontal-white.svg"}" width="1027" height="287" alt=""></a><p class="pied-accroche">{esc(PIED_ACCROCHE)}</p></div>
    <details class="pied-volet pied-volet--liens" open><summary class="footer-title">Découvrir</summary><nav aria-label="Découvrir Rewayah"><ul>{discovery_links}</ul></nav></details>
    <details class="pied-volet pied-volet--legal" open><summary class="footer-title">Informations légales</summary><div class="pied-legal"><nav class="footer-legal" aria-label="Navigation légale"><ul>{footer_links}</ul></nav>
      <div class="pied-societe"><p><span>REWAYAH ACADEMY LTD</span> <span>Société\u00a0n°\u00a016624644</span></p><address><span>71-75 Shelton Street</span> <span>Covent Garden, London</span> <span>WC2H 9JQ, Royaume-Uni</span></address><p>{anchor(academy_facebook['label'], academy_facebook['href'])}</p><p>{anchor(academy_instagram['label'], academy_instagram['href'])}</p><p>{anchor(author_facebook['label'], author_facebook['href'])}</p><p class="pied-credit"><span>Français</span> <span>{esc(site['author_credit'])}</span></p></div></div></details>
    {selecteur_pied}<p class="footer-bottom"><span>{nom_langue}</span> <span>{esc(site['author_credit'])}</span></p>
  </div></footer>
</body>
</html>
''')


COPIED_ASSETS = {".svg", ".png", ".webp", ".jpg", ".woff2", ".txt"}
# Les polices des citations arabes des articles : les fichiers du Complexe du Roi Fahd (KFGQPC) que l'application emploie
# deja (assets/fonts du depot), copies octet pour octet avec leur licence. Celle-ci permet d'utiliser, de copier et de
# distribuer, jamais de modifier : ni sous-ensemble, ni conversion en woff2.
POLICES_CITATIONS = ("UthmanicHafs-v-3.0.ttf", "LICENSE-UthmanicHafs.txt",
                     "UthmanTahaNaskh-Regular.otf", "LICENSE-UthmanTahaNaskh.txt")
POLICES_DEPOT = ROOT.parent / "assets" / "fonts"


def charger_pages_langue(langue: str, pages_fr: dict[str, dict]) -> dict[str, dict]:
    """Les pages d'une autre langue : memes routes que le francais (en cles), memes sections (memes identifiants, dans le
    meme ordre) : une langue n'existe que complete, jamais de page a moitie traduite. Un article a paraitre, absent du
    francais de cette construction, l'est aussi ici (sa page et les liens qui y menent)."""
    data = json.loads(langues_mod.fichier_pages(langue).read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    toutes = data.get("pages")
    if not isinstance(toutes, dict):
        raise ValueError(f"pages.{langue}.json needs a pages object")
    retires = {r for r in toutes if r not in pages_fr}
    inconnues = {r for r in retires if not r.startswith("/fr/articles/")}
    if inconnues:
        raise ValueError(f"pages.{langue}.json : routes inconnues du francais : {sorted(inconnues)}")
    pages = sans_articles_a_paraitre(toutes, retires)
    manquantes = sorted(set(pages_fr) - set(pages))
    if manquantes:
        raise ValueError(f"pages.{langue}.json : pages non traduites : {manquantes}")
    for route, page_fr in pages_fr.items():
        ids_fr = [sec.get("id") for sec in page_fr["sections"]]
        ids = [sec.get("id") for sec in pages[route]["sections"]]
        if ids != ids_fr:
            raise ValueError(f"pages.{langue}.json {route} : sections {ids} au lieu de {ids_fr}")
    # Les textes arabes originaux des versets et des hadiths (citations_arabes) sont les memes dans toutes les langues, mot pour
    # mot, a la legende pres : on ne retraduit jamais un verset ni un hadith.
    for route, page_fr in pages_fr.items():
        for sec_fr, sec in zip(page_fr["sections"], pages[route]["sections"]):
            blocs_fr = [{k: v for k, v in bloc.items() if k != "legende"} for bloc in sec_fr.get("citations_arabes", [])]
            blocs = [{k: v for k, v in bloc.items() if k != "legende"} for bloc in sec.get("citations_arabes", [])]
            if blocs != blocs_fr:
                raise ValueError(f"pages.{langue}.json {route}#{sec.get('id')} : les citations arabes doivent etre celles du francais, mot pour mot")
            if len(sec.get("paragraphs", [])) != len(sec_fr.get("paragraphs", [])):
                raise ValueError(f"pages.{langue}.json {route}#{sec.get('id')} : meme nombre de paragraphes que le francais")
    return {route: pages[route] for route in pages_fr}


def build(output: Path, origin: str, allow_indexing: bool, tarifs: dict | None = None,
          env: dict[str, str] | None = None, today: date | None = None, avis: dict | None = None,
          parution: date | None = None) -> None:
    """allow_indexing : la construction de production seulement (voir main) ; un apercu reste noindex.
    parution : le jour qui decide quels articles sont parus (par defaut today, sinon le jour de la construction)."""
    if tarifs is None:
        # Lecture a la construction seulement : le HTML produit ne contient ni adresse ni cle.
        tarifs, _origine = tarifs_mod.charger_tarifs(env=env)
    if avis is None:
        avis, _origine_avis = avis_mod.charger_avis(env=env)
    if tarifs_mod.politique_affichee(tarifs)["essaiActif"]:
        raise ValueError("Les textes du site disent « pas d'essai » : la politique publiée porte un essai actif")
    parsed = urlparse(origin)
    if parsed.scheme != "https" or not parsed.netloc or parsed.path not in ("", "/"):
        raise ValueError("Canonical origin must be an HTTPS origin")
    pages, site = load_content()
    contenu = pages  # tout le contenu, articles a paraitre compris : la direction artistique les connait deja
    # Parution programmee : en production, un article date apres le jour de la construction n'existe pas encore (sa page,
    # sa carte du hub, sa place dans le plan du site et les liens qui y menent attendent la premiere construction de ce
    # jour-la) ; un apercu le garde, marque « à paraître ». Le jour est celui du serveur de construction (UTC).
    jour = parution or today or date.today()
    a_paraitre = {r for r, p in pages.items() if article_a_paraitre(r, p, jour)}
    if allow_indexing:
        pages = sans_articles_a_paraitre(pages, a_paraitre)
        a_paraitre = set()
    _A_PARAITRE.clear()
    _A_PARAITRE.update(a_paraitre)
    # Le hub liste les articles du plus recent au plus ancien (a date egale : l'ordre du fichier de contenu).
    _ARTICLES[:] = sorted(((r, p) for r, p in pages.items() if r.startswith("/fr/articles/")),
                          key=lambda article: article[1]["date"], reverse=True)
    direction, images = load_direction(contenu)
    _IMAGES.clear()
    _IMAGES.update(images)
    _ILLUSTRATIONS_ARTICLES.clear()
    _ILLUSTRATIONS_ARTICLES.update({r: d["image"] for r, d in direction["pages"].items() if r.startswith("/fr/articles/") and d.get("image")})
    # Le mot du directeur (page Academie) : l'accueil en reprend une phrase, signee, a cote de sa photo.
    mot = next((s for p in pages.values() for s in p["sections"] if s.get("citation")), None)
    # Les deux autres fondateurs (page Academie), avec leur portrait : l'accueil les montre a cote du directeur.
    profils = next((s["profils"] for p in pages.values() for s in p["sections"] if s.get("profils")), [])
    portraits_f = (direction["pages"].get("/fr/academie", {}).get("portraits") or {}).get("fondateurs") or {}
    deja = mot["signature"]["nom"] if mot else None
    fondateurs = [(f["nom"], f["role"], portraits_f[f["nom"]]) for f in profils if f["nom"] != deja and f["nom"] in portraits_f]
    disponibles = langues_mod.langues_construites(allow_indexing)
    pages_par_langue: dict[str, dict[str, dict]] = {"fr": pages}
    for langue in disponibles[1:]:
        pages_par_langue[langue] = charger_pages_langue(langue, pages)
    _LANGUE["disponibles"] = disponibles
    for langue in disponibles:
        pages_l = pages_par_langue[langue]
        _LANGUE["code"] = langue
        _UI.clear()
        _UI.update(langues_mod.textes_code(langue))
        if langue != "fr":
            _ARTICLES[:] = sorted(((r, p) for r, p in pages_l.items() if r.startswith("/fr/articles/")),
                                  key=lambda article: article[1]["date"], reverse=True)
        mot_l = next((s for p in pages_l.values() for s in p["sections"] if s.get("citation")), None) if langue != "fr" else mot
        profils_l = next((s["profils"] for p in pages_l.values() for s in p["sections"] if s.get("profils")), []) if langue != "fr" else profils
        deja_l = mot_l["signature"]["nom"] if mot_l else None
        _NOMS_FR.clear()
        if langue != "fr":
            _alias_noms(pages, pages_l)
        fondateurs_l = [(f["nom"], f["role"], portraits_f[_NOMS_FR.get(f["nom"], f["nom"])]) for f in profils_l
                        if f["nom"] != deja_l and _NOMS_FR.get(f["nom"], f["nom"]) in portraits_f]
        for route, page in pages_l.items():
            destination = output_file(output, langues_mod.route_langue(route, langue))
            destination.parent.mkdir(parents=True, exist_ok=True)
            rendu = render_page(route, page, site, origin, allow_indexing, tarifs, today, avis, direction, images, mot_l, fondateurs_l)
            if langue != "fr":
                rendu = langues_mod.traduire_noeuds(rendu, _UI, _MANQUES.setdefault(langue, set()))
            rendu = langues_mod.localiser(rendu, langue, route, origin, disponibles, allow_indexing)
            if langues_mod.DIRECTION.get(langue) == "rtl":
                # Logo de droite a gauche : symbole a droite, nom a sa gauche (traces officiels deplaces, logo_rtl.py).
                rendu = re.sub(r'(logo-horizontal(?:-ink|-white)?)\.svg"', r'\1-rtl.svg"', rendu)
            destination.write_text(typographie_finale(rendu), encoding="utf-8")
    _LANGUE["code"] = "fr"
    _UI.clear()
    rapport = os.environ.get("RA_MANQUES")
    if rapport:
        Path(rapport).write_text(json.dumps({l: sorted(v) for l, v in _MANQUES.items()}, ensure_ascii=False, indent=1), encoding="utf-8")
    for l, v in _MANQUES.items():
        print(f"Langue {l} : {len(v)} phrases du code sans traduction (RA_MANQUES=fichier.json pour la liste)")
    assets_out = output / "fr" / "assets"
    assets_out.mkdir(parents=True, exist_ok=True)
    sources = []
    for source_dir in (ROOT / "assets", ROOT / "styles"):
        if source_dir.exists():
            for source in source_dir.iterdir():
                allowed = COPIED_ASSETS if source_dir.name == "assets" else {".css", ".js"}
                if source.is_file() and source.suffix.lower() in allowed:
                    sources.append(source)
    sources += [POLICES_DEPOT / nom for nom in POLICES_CITATIONS]
    # Un dossier de sortie reutilise ne garde pas un fichier retire (illustration re-exportee, police supprimee).
    publies = {source.name for source in sources}
    for ancien in assets_out.iterdir():
        if ancien.is_file() and ancien.name not in publies:
            ancien.unlink()
    for source in sources:
        shutil.copy2(source, assets_out / source.name)
    if not (assets_out / "site.css").exists():
        raise ValueError("Missing site-public/styles/site.css")
    for langue in disponibles:
        for route in pages_par_langue[langue]:
            if not output_file(output, langues_mod.route_langue(route, langue)).exists():
                raise AssertionError(f"Route was not built: {langues_mod.route_langue(route, langue)}")
    sitemap_urls = [(route, langue, page.get("date")) for langue in disponibles for route, page in pages_par_langue[langue].items()
                    if page_indexee(route, page, allow_indexing, avis)]
    # Chaque url liste toutes ses versions, elle-meme comprise, avec un x-default (Google, versions localisees).
    multilingue = len(disponibles) > 1
    sitemap = ('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
               + (' xmlns:xhtml="http://www.w3.org/1999/xhtml"' if multilingue else "") + '>') + ''.join(
        f'<url><loc>{esc(origin.rstrip("/") + langues_mod.route_langue(route, langue))}</loc>'
        + (f'<lastmod>{esc(date_mise_a_jour)}</lastmod>' if date_mise_a_jour else '')
        + (langues_mod.alternates_plan(route, disponibles, origin) if multilingue else "") + '</url>'
        for route, langue, date_mise_a_jour in sitemap_urls) + '</urlset>'
    (output / "sitemap.xml").write_text(sitemap, encoding="utf-8")
    (output / "robots.txt").write_text(
        f"User-agent: *\n{'Allow: /' if allow_indexing else 'Disallow: /'}\n"
        + (f"Sitemap: {origin.rstrip('/')}/sitemap.xml\n" if allow_indexing else ""),
        encoding="utf-8",
    )
    (output / "404.html").write_text(
        page_etat("Page introuvable | Rewayah Academy", "page-404", direction,
                  '<div class="etat__texte"><h1>Cette page est introuvable.</h1>'
                  '<p>Cette porte reste fermée : l’adresse a changé, ou la page n’existe plus. '
                  'Revenez à l’accueil, ou consultez l’aide : nous vous y guidons.</p>'
                  '<div class="action-row"><a class="cta" href="/fr/">Retour à l’accueil</a>'
                  '<a class="cta cta--secondary" href="/fr/aide">Consulter l’aide</a></div></div>',
                  porte_mod.porte_lumiere("attente")),
        encoding="utf-8",
    )
    (output / "fr" / "courriels").mkdir(parents=True, exist_ok=True)
    (output / "fr" / "courriels" / "desinscription.html").write_text(page_desinscription(direction), encoding="utf-8")
    config_path = output / "vercel.json"
    config = json.loads(config_path.read_text(encoding="utf-8")) if config_path.exists() else {}
    # Vercel's documented negative-lookahead syntax leaves unknown /fr paths
    # unmatched, so its static 404.html handles them instead of Flutter. Same for
    # /.well-known/ (kept on the site host): an absent file is a 404, not the app.
    langues_servies = disponibles[0] if len(disponibles) == 1 else "(?:" + "|".join(disponibles) + ")"
    fallback = {"source": rf"/:path((?!{langues_servies}(?:/|$)|\.well-known/).*)", "destination": "/index.html"}
    config["rewrites"] = [
        {"source": langues_mod.route_langue(route, langue).rstrip("/") or "/",
         "destination": "/" + str(output_file(Path(), langues_mod.route_langue(route, langue))).replace("\\", "/")}
        for langue in disponibles for route in sorted(pages_par_langue[langue])
    ] + [{"source": f"/{langue}/", "destination": f"/{langue}/index.html"} for langue in disponibles] + [
         {"source": ROUTE_DESINSCRIPTION, "destination": "/fr/courriels/desinscription.html"}, fallback]
    config["redirects"] = aiguillage_domaine(tuple(disponibles))
    config["headers"] = [*config.get("headers", []), *entetes_domaine(tuple(disponibles))]
    config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(pages)} public routes in {output}")


# Page de desinscription des e-mails : hors pages.json (ni index, ni plan du site, ni navigation). Le lien de l'e-mail
# porte un jeton ; jamais de desinscription sur un simple GET (les scanners de liens l'ouvrent) : la page propose un
# bouton qui envoie le jeton en POST a la fonction, laquelle repond 303 vers cette page (?etat=ok&categorie=... ou ?etat=invalide).
# Le site n'a pas de CSP : aucun form-action a completer.
ROUTE_DESINSCRIPTION = "/fr/courriels/desinscription"
FONCTION_DESINSCRIPTION = "https://gggmtelinlpseweouyav.supabase.co/functions/v1/courriel-desinscription"


def page_etat(titre: str, classe: str, direction: dict, contenu: str, figure: str, script: str = "") -> str:
    """Page d'etat autonome (introuvable, desinscription) : fond de l'ambiance, logo, texte, puis la porte et sa lumiere."""
    ambiance = direction.get("ambiance", "clair")
    jour = teinte_jour(direction)
    couleurs = ('<meta name="color-scheme" content="light"><meta name="theme-color" content="#F7F5FE">' if jour
                else '<meta name="color-scheme" content="dark"><meta name="theme-color" content="#6538E4">' if ambiance == "violet"
                else '<meta name="color-scheme" content="light dark">')
    logo = LOGO["horizontal"][0] if jour else "logo-horizontal-white.svg"
    attribut_teinte = ' data-teinte="jour"' if jour else ""
    return (
        f'<!doctype html><html lang="fr" data-ambiance="{esc(ambiance)}"{attribut_teinte}><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        f'{couleurs}<meta name="robots" content="noindex,nofollow">'
        f'<link rel="stylesheet" href="{ASSETS}/site.css">'
        f'<title>{esc(titre)}</title></head><body class="{classe}">'
        '<main class="etat" id="contenu"><a class="etat__marque" href="/fr/" aria-label="Rewayah Academy, accueil">'
        f'<img src="{ASSETS}/{logo}" width="1027" height="287" alt=""></a>'
        f'{contenu}<div class="etat__scene">{figure}</div></main>{script}</body></html>')


def page_desinscription(direction: dict) -> str:
    etats = (
        '<div data-etat="confirmer" hidden><h1>Ne plus recevoir ces e-mails&nbsp;?</h1>'
        '<p>Vous ne recevrez plus les e-mails de cette catégorie. Les messages liés à votre compte, vos classes '
        'et vos factures continuent d’arriver.</p>'
        f'<form class="action-row" method="post" action="{esc(FONCTION_DESINSCRIPTION)}">'
        '<input type="hidden" name="jeton" value=""><button class="cta" type="submit">Ne plus recevoir ces e-mails</button>'
        '<a class="cta cta--secondary" href="/fr/">Garder mes e-mails</a></form></div>'
        '<div data-etat="ok" hidden><h1>C’est fait.</h1>'
        '<p>Vous ne recevrez plus les e-mails «&nbsp;<span data-categorie>de cette catégorie</span>&nbsp;». '
        'Les messages liés à votre compte, vos classes et vos factures continuent d’arriver.</p>'
        '<div class="action-row"><a class="cta" href="/fr/">Retour à l’accueil</a></div></div>'
        '<div data-etat="invalide" hidden><h1>Ce lien n’est plus valable.</h1>'
        '<p>Il a expiré, ou nous ne le reconnaissons pas. Écrivez-nous depuis la page Contact : nous ferons le nécessaire.</p>'
        '<div class="action-row"><a class="cta" href="/fr/contact">Nous contacter</a>'
        '<a class="cta cta--secondary" href="/fr/">Retour à l’accueil</a></div></div>'
    )
    neutre = (
        '<div data-etat="neutre"><h1>Désinscription des e-mails</h1>'
        '<p>Cette page enregistre le choix de ne plus recevoir une catégorie d’e-mails ; elle a besoin de '
        'JavaScript pour lire votre lien. Sans lui, écrivez-nous depuis la page Contact. '
        'Les messages liés à votre compte, vos classes et vos factures continuent d’arriver.</p>'
        '<div class="action-row"><a class="cta" href="/fr/contact">Nous contacter</a>'
        '<a class="cta cta--secondary" href="/fr/">Retour à l’accueil</a></div></div>'
    )
    # Etat lu dans l'adresse : ?etat=ok&categorie=… / ?etat=invalide / ?jeton=… (a confirmer) ; sans rien : invalide.
    # La categorie passe par textContent, jamais par du HTML ; le jeton quitte l'adresse affichee des qu'il est recopie.
    script = (
        '<script>(function(){var q=new URLSearchParams(location.search),e=q.get("etat"),j=q.get("jeton"),d=document,'
        'k=e==="ok"?"ok":e==="invalide"?"invalide":j?"confirmer":"invalide",c=d.querySelector("[data-categorie]");'
        'd.querySelectorAll("[data-etat]").forEach(function(n){n.hidden=n.dataset.etat!==k});'
        'd.documentElement.dataset.etat=k;'
        'if(k==="ok"){var t=(q.get("categorie")||"").slice(0,80);if(t&&c)c.textContent=t}'
        'if(k==="confirmer"){d.querySelector("input[name=jeton]").value=j.slice(0,200);'
        'if(history.replaceState)history.replaceState(null,"",location.pathname)}'
        'd.title=(k==="ok"?"E-mails désactivés":"Désinscription des e-mails")+" | Rewayah Academy"})()</script>')
    # Deux portes superposees dans le meme cadre : fermee tant qu'on attend, ouverte une fois c'est fait.
    ouverte = porte_mod.porte_lumiere("ouverte").replace("pl-", "po-")
    return page_etat("Désinscription des e-mails | Rewayah Academy", "page-desinscription", direction,
                     f'<div class="etat__texte">{etats}{neutre}</div>',
                     porte_mod.porte_lumiere("attente") + ouverte, script)


def _hote(nom: str) -> list[dict]:
    return [{"type": "host", "value": nom}]


def aiguillage_domaine(langues: tuple[str, ...] = ("fr",)) -> list[dict]:
    """Qui va ou (directeur, 23/10/2026, usage courant des sites et de leurs applications) :
    - rewayahacademy.com : le site public ; sa racine mene a l'accueil /fr/ (redirection temporaire : une autre
      langue pourra s'y ajouter) ; tout autre chemin (/connexion, un ancien lien de l'application) part sur app. ;
    - app.rewayahacademy.com : l'application et sa PWA ; une page du site demandee la renvoie au site ;
    - www. renvoie au domaine nu.
    Ces regles ne jouent que sur ces trois noms : un apercu et l'alias vercel.app servent tout comme avant, ce qui
    garde les controles du workflow (racine, reecriture SPA, wasm) inchanges."""
    site, app = _hote(DOMAINE_SITE), _hote(DOMAINE_APP)
    # Vercel compile ces sources en mode strict : `:path*` ne prend pas un « / » seul apres son prefixe ; `(.*)` si.
    # Une langue pas encore en ligne mene a la meme page en francais (jamais a l'ecran de connexion de l'application) ;
    # une langue en ligne est servie par le site.
    toutes = [l for l in langues_mod.NOMS if l != "fr"]
    en_attente = [l for l in toutes if l not in langues]
    en_ligne = ["fr", *[l for l in toutes if l in langues]]
    servies = en_ligne[0] if len(en_ligne) == 1 else "(?:" + "|".join(en_ligne) + ")"
    vers_francais = []
    for l in en_attente:
        vers_francais += [{"source": f"/{l}", "has": site, "destination": "/fr/", "permanent": False},
                          {"source": f"/{l}/:path(.*)", "has": site, "destination": "/fr/:path", "permanent": False}]
    return [
        {"source": "/:path(.*)", "has": _hote(DOMAINE_WWW), "destination": ORIGINE_SITE + "/:path", "permanent": True},
        {"source": "/", "has": site, "destination": "/fr/", "permanent": False},
        *vers_francais,
        {"source": rf"/:path((?!{servies}(?:/|$)|robots\.txt$|sitemap\.xml$|\.well-known/).+)", "has": site,
         "destination": ORIGINE_APP + "/:path", "permanent": False},
        {"source": "/fr", "has": app, "destination": ORIGINE_SITE + "/fr/", "permanent": False},
        {"source": "/fr/:path(.*)", "has": app, "destination": ORIGINE_SITE + "/fr/:path", "permanent": False},
    ]


def entetes_domaine(langues: tuple[str, ...] = ("fr",)) -> list[dict]:
    """L'application et l'ancien alias ne s'indexent pas ; les pages du site portent les en-tetes de securite
    courants (rien qui touche la camera ou le micro de l'application : ils ne visent que /fr)."""
    noindex = [{"key": "X-Robots-Tag", "value": "noindex"}]
    securite = [
        {"key": "X-Content-Type-Options", "value": "nosniff"},
        {"key": "Referrer-Policy", "value": "strict-origin-when-cross-origin"},
        {"key": "X-Frame-Options", "value": "DENY"},
        {"key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()"},
    ]
    return [
        {"source": "/(.*)", "has": _hote(DOMAINE_APP), "headers": noindex},
        {"source": "/(.*)", "has": _hote(ALIAS_VERCEL), "headers": noindex},
        *[x for l in langues for x in ({"source": f"/{l}", "headers": securite}, {"source": f"/{l}/(.*)", "headers": securite})],
    ]


def production_github(env) -> bool:
    """Meme regle que l'etape « cible » de .github/workflows/flutter-deploy.yml : `main`, hors pull request."""
    return env.get("GITHUB_EVENT_NAME") != "pull_request" and env.get("GITHUB_REF") == "refs/heads/main"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--canonical-origin", default=ORIGINE_SITE)
    # Le workflow appelle ce script sans option : la production s'y reconnait d'elle-meme ; ailleurs, noindex.
    parser.add_argument("--allow-indexing", action="store_true")
    args = parser.parse_args()
    indexer = args.allow_indexing or production_github(os.environ)
    print("Indexation : ouverte (production)" if indexer else "Indexation : fermee (apercu)")
    build(args.output, args.canonical_origin, indexer)


if __name__ == "__main__":
    main()
