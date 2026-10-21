"""Build the public HTML preview beside the existing Flutter Web bundle.

The published commercial projection is intentionally absent. This builder only
renders editorial content that the content contract marks as safe for preview.

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
# Avis publies lus dans la base au build (public.avis_publics), repli sur content/avis.json.
avis_mod = _load_module("bloc_avis")
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
CONTACTS = (
    ("Questions générales", "general"),
    ("Assistance", "support"),
    ("Recrutement", "recruitment"),
    ("Facturation", "billing"),
)
ASSETS = "/fr/assets"
# Les quatre fichiers officiels du logo (assets/brand/logo/), copies telles quelles.
LOGO = {
    "horizontal": ("logo-horizontal.svg", 1027, 287),
    "horizontal-blanc": ("logo-horizontal-white.svg", 1027, 287),
    "symbole": ("symbole.svg", 716, 707),
    "symbole-blanc": ("symbole-white.svg", 716, 707),
}


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


_PETITS = (r"le|la|les|un|une|des|de|du|à|au|aux|en|et|ou|par|pour|sans|son|sa|ses|votre|vos|notre|nos|chaque|dès|"
           r"avec|sur|dans|deux|trois|quatre|cinq|six|qui|que")
# Un petit mot se lie au mot qui le suit (« pour votre enfant » ne se coupe qu'avant « pour »), un nombre a son unite,
# et le nom de l'academie ne se coupe pas. Les titres longs sont dimensionnes pour que ces blocs tiennent.
PETITS_MOTS = re.compile(rf"(?<![\w’'])((?i:{_PETITS})|\d+) (?=\S)")


def titre_html(value: str) -> str:
    """Un titre ne finit pas une ligne sur un article, une preposition ou un nombre : espaces insecables."""
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
        "recrutement@rewayahacademy.com", "invoice@rewayahacademy.com",
    }
    if set(site["contacts"].values()) != expected_contacts:
        raise ValueError("Public contacts differ from the four approved aliases")
    social = site.get("social_links")
    if not isinstance(social, list) or {item.get("href") for item in social} != {
        "https://www.facebook.com/share/1CVee2teiN/",
        "https://www.facebook.com/share/1D6H2EYhci/",
    }:
        raise ValueError("Social destinations differ from the two approved URLs")
    if site.get("author_credit") != "Site conçu par Abdoulaye Mouhidine Sow.":
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
        validate_link(page["cta"]["href"], pages)
        for section in page["sections"]:
            for link in section.get("links", []):
                validate_link(link["href"], pages)
    return pages, site


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
    for route, reglage in direction["pages"].items():
        if route not in pages:
            raise ValueError(f"direction.json names an unknown route: {route}")
        for ident in (reglage.get("figures") or {}).values():
            if ident not in connues:
                raise ValueError(f"direction.json names an unknown picture: {ident}")
        for cle in ("image", "bande"):
            valeur = (reglage.get(cle) or {}).get("image") if isinstance(reglage.get(cle), dict) else reglage.get(cle)
            if valeur and valeur not in connues:
                raise ValueError(f"direction.json names an unknown picture: {valeur}")
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
    return (f'<a class="lien-fleche" href="{esc(href)}"><span>{esc(label)}</span>'
            '<svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h13m-5-6 6 6-6 6" '
            'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></a>')


# --- Images ------------------------------------------------------------------

def scene(images: dict, ident: str, tailles: str, css: str = "", prioritaire: bool = False,
          legende: bool = True, attributs: str = "") -> str:
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

    def img(nom: str, alt: str, extra: str = "", charge: str = chargement) -> str:
        srcset = ", ".join(f"{ASSETS}/scene-{nom}-{w}.webp {w}w" for w in largeurs)
        return (f'<img{extra} src="{ASSETS}/scene-{nom}-{grande}.webp" srcset="{srcset}" sizes="{esc(tailles)}" '
                f'width="{grande}" height="{hauteur}" alt="{esc(alt)}" decoding="async" {charge}>')

    if calques:
        anime = f' data-anime="{esc(calques["anime"])}"'
        zone = calques.get("zone")
        if zone:
            style = (style[:-1] + ";" if style else ' style="') + "--zx:{};--zy:{};--zl:{};--zh:{}\"".format(*zone)
        couches = img(f"{ident}-fond", image["alt"]) + "".join(
            img(f"{ident}-{nom}", "", f' class="scene__calque scene__calque--{esc(nom)}" aria-hidden="true"')
            for nom in calques["noms"])
    else:
        anime = ""
        couches = img(ident, image["alt"])
    figcaption = '<figcaption>Illustration</figcaption>' if legende else ""
    return (f'<figure class="scene {esc(css)}"{style}{anime}{attributs}><span class="scene__cadre">{couches}</span>'
            f'{figcaption}</figure>')


def logo_entete(ambiance: str = "clair") -> str:
    """En-tete : logo horizontal (violet sur clair, blanc sur sombre ou sur le violet), symbole seul sur telephone."""
    h, hw, hh = LOGO["horizontal"]
    hb = LOGO["horizontal-blanc"][0]
    s, sw, sh = LOGO["symbole"]
    sb = LOGO["symbole-blanc"][0]
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

NOMS_A_TRAIT = re.compile(r"\b(A[lnrsz]-[A-ZÀ-Ý][\wÀ-ÿ’']*)")


_PETITS_TEXTE = _PETITS + r"|vous|nous|il|elle|on|ne|ce|ces|cette|leur|leurs|tout|toute|tous|toutes|est|y"
PETITS_MOTS_TEXTE = re.compile(rf"(?<![\w’'])((?i:{_PETITS_TEXTE})|\d+(?:,\d+)?) (?=\S)")


def texte_html(value: str) -> str:
    """Texte courant : espace insecable avant les deux-points, le point-virgule et les points d'interrogation et
    d'exclamation ; un petit mot se lie au mot qui le suit et un nombre a son unite (« de 3 à 5 élèves ») ; le
    dernier mot ne reste pas seul sur sa ligne ; un nom comme Az-Zalzalah ne se coupe pas a son trait d'union."""
    fin = re.sub(r" ([:;?!])", "\u00a0\\1", value)
    fin = PETITS_MOTS_TEXTE.sub(lambda m: m.group(1) + "\u00a0", fin)
    # Une adresse e-mail garde sa place a la ligne : elle ne se colle pas au mot qui la precede.
    fin = re.sub(r"\u00a0(?=\S*@)", " ", fin)
    tete, espace, dernier = fin.rpartition(" ")
    if espace and len(dernier) <= 12 and "@" not in dernier and len(tete.split()) >= 3:
        fin = f"{tete}\u00a0{dernier}"
    return NOMS_A_TRAIT.sub(r'<span class="insecable">\1</span>', esc(fin))


def paragraphes(section: dict) -> str:
    return "".join(f"<p>{texte_html(p)}</p>" for p in section.get("paragraphs", []))


def points_liste(section: dict) -> str:
    points = section.get("points", [])
    if not points:
        return ""
    return ('<ul class="points">' + "".join(
        f'<li><span class="puce" aria-hidden="true"></span><span>{texte_html(p)}</span></li>' for p in points) + "</ul>")


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
    </div>
    <div class="porte__texte" data-lignes>
      <h1>{titre_html(page['h1'])}</h1>
      <p class="hero-intro">{texte_html(page.get('intro', ''))}</p>
      <div class="action-row">{cta}{bouton("Voir les tarifs", "/fr/tarifs", "contour")}</div>
      <p class="rassurance">{texte_html("Rien n’est facturé avant l’ouverture de la classe. La première semaine est remboursée si le cours ne convient pas.")}</p>
      <p class="preuve">{texte_html("Rewayah Academy a été fondée en 2024 par trois spécialistes du Coran et des sciences islamiques.")}</p>
    </div>
    <div class="porte__cercle">
      <div class="porte__disque" aria-hidden="true"></div>
      <p class="porte__phrase" aria-hidden="true"><span>Une petite classe.</span><br><span>Un enseignant attitré.</span></p>
      {scene(images, "halqa", "(max-width: 839px) 90vw, 50vw", "porte__halqa", legende=False)}
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
    figures = "".join(
        scene(images, img, "(max-width: 839px) 92vw, 44vw", "chapitres__image",
              legende=(i == 0), attributs=f' data-chapitre-image="{i}"')
        for i, (_, img) in enumerate(chapitres))
    textes = []
    for i, (sid, _) in enumerate(chapitres):
        sec = s[sid]
        textes.append(
            f'<article class="chapitre" id="{esc(sid)}" aria-labelledby="chapitre-{sid}" data-chapitre="{i}">'
            f'<h2 id="chapitre-{sid}">{titre_html(sec["title"])}</h2>{paragraphes(sec)}{points_liste(sec)}{liens_section(sec)}'
            f'<div class="chapitre__image-mobile">{scene(images, chapitres[i][1], "92vw", "chapitres__image-mobile", legende=True)}</div>'
            '</article>')
    return f'''<section class="chapitres" aria-label="Pour vos enfants et pour vous">
  <div class="chapitres__fenetre" aria-hidden="true"><div class="chapitres__pile">{figures}</div></div>
  <div class="chapitres__textes">{"".join(textes)}</div>
</section>'''


def accueil_etapes(page: dict, images: dict) -> str:
    """Les tuiles qui grandissent : l'ordre se lit a la taille, sans numeros."""
    sec = _sections_par_id(page)["fonctionnement"]
    etapes = (
        ("detail-place", "Vous choisissez un horaire", "Parmi les horaires publiés, pour votre enfant ou pour vous."),
        ("detail-enseignante", "La direction compose la classe", "Elle nomme l’enseignant et vous écrit à chaque étape."),
        ("detail-livre-femme", "La classe commence", "Vous la rejoignez depuis l’application, à son horaire."),
    )
    tuiles = "".join(
        f'<li class="pousse__etape pousse__etape--{i}" data-revele>'
        f'<div class="pousse__tuile">{scene(images, img, "(max-width: 839px) 90vw, 40vw", "pousse__image", legende=(i == 2))}</div>'
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

    # Ce que le prix comprend : les phrases des encarts de la décision du 18/10 (tarifs.json, site_public).
    def inclus(*lignes: str) -> str:
        return '<ul class="champ__inclus">' + "".join(f"<li>{texte_html(l)}</li>" for l in lignes) + "</ul>"

    enfant = tarifs_mod.fmt_montant(p["tarifEnfantMineur"], devise)
    adulte = tarifs_mod.fmt_montant(p["tarifAdulteMineur"], devise)
    age = p["ageAdulte"]
    return f'''<section class="deux-champs" id="tarifs" aria-labelledby="tarifs-titre">
  <h2 id="tarifs-titre" class="deux-champs__titre" data-revele>{titre_html(sec["title"])}</h2>
  <div class="deux-champs__grille">
    <article class="champ champ--enfant" data-revele>
      <h3>{titre_html("Enfants et adolescents")}</h3>
      <p class="champ__prix"><span class="champ__montant">{esc(enfant)}</span><span class="champ__periode">par mois, {hors_taxes}</span></p>
      <p class="champ__public">{texte_html(f"De {tarifs_mod.AGE_ENFANT_MIN} à {age - 1} ans. {duree('enfant')}, dans une classe de {c['ouvertureMinimum']} à {c['tailleEnfant']} élèves.")}</p>
      {inclus("Le compte rendu de l’enseignant chaque fin de semaine", "L’observation d’une séance, deux minutes, en silence",
              "Une séance annulée par l’académie est remplacée", "La première semaine remboursée si le cours ne convient pas")}
    </article>
    <article class="champ champ--adulte" data-revele>
      <h3>Adultes</h3>
      <p class="champ__prix"><span class="champ__montant">{esc(adulte)}</span><span class="champ__periode">par mois, {hors_taxes}</span></p>
      <p class="champ__public">{texte_html(f"{age} ans et plus. {duree('adulte')}, dans une classe de {c['ouvertureMinimum']} à {c['tailleAdulte']} élèves.")}</p>
      {inclus("Le compte rendu de l’enseignant chaque fin de semaine", "Une séance annulée par l’académie est remplacée",
              "La première semaine remboursée si le cours ne convient pas", "Résiliable chaque mois")}
    </article>
  </div>
  <div class="deux-champs__pied" data-revele>
    <p>{texte_html(intro_remise + (" " + sec["paragraphs"][0] if sec.get("paragraphs") else ""))}</p>
    <div class="action-row"><button class="cta cta--secondary" type="button" data-open-simulator>Simuler mon tarif</button>{lien_fleche("Voir les tarifs et les remises", "/fr/tarifs")}</div>
  </div>
</section>'''


def accueil_confiance(page: dict, images: dict) -> str:
    sec = _sections_par_id(page)["confiance"]
    return f'''<section class="panneau" id="confiance" aria-labelledby="confiance-titre">
  <div class="panneau__in">
    <div class="panneau__gauche">
      <h2 id="confiance-titre" data-revele>{titre_html(sec["title"])}</h2>
      <div class="panneau__arche" data-revele>{scene(images, "detail-famille-chemin", "(max-width: 839px) 86vw, 38vw", "panneau__image")}</div>
    </div>
    <div class="panneau__droite">
      <p class="panneau__depuis" data-revele>{titre_html("Rewayah Academy enseigne le Coran depuis le 1er mai 2024.")}</p>
      <div class="panneau__bloc" data-revele><h3>Un programme qui avance</h3><p>{texte_html("Chaque étape a son objectif et sa date limite.")}</p></div>
      <div class="panneau__bloc" data-revele><h3>Un suivi pour les familles</h3><p>{texte_html("Retrouvez les séances et le travail à préparer dans votre espace familial.")}</p></div>
      <div class="panneau__bloc" data-revele><h3>Un tuteur pour chaque enfant</h3>{paragraphes(sec)}</div>
      <div class="action-row" data-revele>{bouton("Découvrir l’académie", "/fr/academie", "contour")}{lien_fleche("Protection des enfants", "/fr/protection-des-enfants")}</div>
      <p class="panneau__societe">REWAYAH ACADEMY LTD · Société n° 16624644</p>
    </div>
  </div>
</section>'''


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
    sec = _sections_par_id(page)["faq-articles"]
    age_adulte = str(tarifs_mod.politique_affichee(tarifs)["ageAdulte"])
    tuiles = "".join(
        f'<details class="tuile" name="faq"{" open" if i == 0 else ""}><summary><h3>{esc(q)}</h3>'
        f'<span class="tuile__signe" aria-hidden="true"></span></summary><div class="tuile__corps"><p>{texte_html(r.replace("{age_adulte}", age_adulte))}</p></div></details>'
        for i, (q, r) in enumerate(QUESTIONS_ACCUEIL))
    return f'''<section class="faq-tuiles" id="faq-articles" aria-labelledby="faq-titre">
  <div class="faq-tuiles__tete" data-revele><h2 id="faq-titre">{titre_html(sec["title"])}</h2>{paragraphes(sec)}
    <ul class="liste-liens"><li>{lien_fleche("Comprendre le déroulement des cours", "/fr/cours")}</li><li>{lien_fleche("Accompagner son enfant", "/fr/familles")}</li><li>{lien_fleche("Consulter l’aide", "/fr/aide")}</li><li>{lien_fleche("Voir la page des avis", "/fr/avis")}</li></ul></div>
  <div class="faq-tuiles__liste">{tuiles}</div>
</section>'''


def bande_finale(titre: str, phrase: str, label: str, href: str, mot: str | None, identifiant: str = "inscription") -> str:
    """La bande d'appel : toute la bande est le lien. Sur l'accueil, un seul mot honnete la porte, en tres grand ;
    les pages interieures gardent une bande sobre, pour que ce mot reste une signature et non un gabarit."""
    externe = href.startswith("mailto:")
    sobre = "" if mot else " appel--sobre"
    grand_mot = f'<span class="appel__mot" aria-hidden="true">{esc(mot)}</span>' if mot else ""
    return f'''<section class="appel{sobre}" id="{esc(identifiant)}" aria-labelledby="appel-titre">
  <a class="appel__lien" href="{esc(href)}">
    <span class="appel__haut"><h2 id="appel-titre">{titre_html(titre)}</h2><span class="appel__phrase">{esc(phrase)}</span><span class="appel__bouton">{esc(label)}{'<span class="sr-only"> (ouvre votre messagerie)</span>' if externe else ""}<svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20"><path d="M5 12h13m-5-6 6 6-6 6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></span></span>
    {grand_mot}
  </a>
</section>'''


def render_home(page: dict, images: dict, tarifs: dict, cta: str) -> str:
    fin = _sections_par_id(page)["footer"]
    return "".join((
        accueil_porte(page, images, cta),
        accueil_enonce(images, tarifs),
        accueil_chapitres(page, images),
        accueil_etapes(page, images),
        accueil_tarifs(page, tarifs),
        accueil_confiance(page, images),
        accueil_faq(page, tarifs),
        bande_finale(fin["title"], (fin.get("paragraphs") or [""])[0] + " Rien n’est facturé avant l’ouverture de la classe.",
                     page["cta"]["label"], page["cta"]["href"], "Commencer"),
    ))


# --- Pages interieures -------------------------------------------------------------

def hero_interieur(route: str, page: dict, reglage: dict, images: dict, cta: str, status: str,
                   tarifs: dict | None = None) -> str:
    intro = f'<p class="hero-intro">{texte_html(page["intro"])}</p>' if page.get("intro") else ""
    haut = reglage.get("haut")
    titre_long = (" entete-page__texte--long" if len(page["h1"]) > 22 else "") + (" entete-page__texte--tres-long" if len(page["h1"]) > 33 else "")
    texte = (f'<div class="entete-page__texte{titre_long}" data-lignes><h1>{titre_html(page["h1"])}</h1>'
             f'{intro}{status}<div class="action-row">{cta}</div></div>')
    # Chaque page interieure s'ouvre sur son propre sujet : les etapes, le parcours, ou le prix.
    if haut == "texte":
        return f'<section class="entete-page entete-page--haut-texte">{texte}</section>'
    if haut == "parcours":
        sec = _sections_par_id(page)[reglage["parcours"][0]]
        arches = "".join(f'<li class="parcours__etape"><span>{texte_html(p)}</span></li>' for p in sec.get("points", []))
        return (f'<section class="entete-page entete-page--haut-parcours">{texte}'
                f'<ol class="parcours parcours--haut" aria-label="{esc(sec["title"])}" data-revele-enfants>{arches}</ol></section>')
    if haut == "prix":
        p = tarifs_mod.politique_affichee(tarifs)
        hors_taxes = "hors taxes" if p["horsTaxes"] else "taxes comprises"
        blocs = "".join(
            f'<p class="entete-prix__bloc"><span class="entete-prix__montant">{esc(tarifs_mod.fmt_montant(montant, p["devise"]))}</span>'
            f'<span class="entete-prix__periode">par mois, {hors_taxes}</span><span class="entete-prix__public">{texte_html(public)}</span></p>'
            for montant, public in ((p["tarifEnfantMineur"], f"Enfants et adolescents, de {tarifs_mod.AGE_ENFANT_MIN} à {p['ageAdulte'] - 1} ans"),
                                    (p["tarifAdulteMineur"], f"Adultes, dès {p['ageAdulte']} ans")))
        return (f'<section class="entete-page entete-page--haut-prix">{texte}'
                f'<div class="entete-page__arche">{scene(images, reglage["image"], "(max-width: 839px) 60vw, 380px", "entete-page__image", prioritaire=True)}</div>'
                f'<div class="entete-prix" data-revele-enfants>{blocs}</div></section>')
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


def bande_image(reglage: dict, images: dict) -> str:
    bande = reglage.get("bande")
    if not bande:
        return ""
    sous = f'<p class="bande-image__sous">{texte_html(bande["sous"])}</p>' if bande.get("sous") else ""
    if not bande.get("image"):
        # Une phrase seule, en grand, sur un champ de couleur : un changement de fond dans la page.
        return (f'<div class="fond fond--{esc(bande.get("fond", "lavande"))}"><div class="bande-phrase" data-revele>'
                f'<p class="bande-phrase__phrase">{titre_html(bande["phrase"])}</p>{sous}</div></div>')
    return (f'<div class="bande-image bande-image--{esc(bande.get("forme", "large"))}" data-revele>'
            f'{scene(images, bande["image"], "100vw", "bande-image__scene")}'
            + (f'<div class="bande-image__texte"><p class="bande-image__phrase">{titre_html(bande["phrase"])}</p>{sous}</div>'
               if bande.get("phrase") else "") + '</div>')


def figure_section(reglage: dict, images: dict, sid: str) -> str:
    ident = (reglage.get("figures") or {}).get(sid)
    if not ident:
        return ""
    image = images["images"][ident]
    panorama = " section__figure--panorama" if image["largeur"] / image["hauteur"] > 1.2 else ""
    return (f'<div class="section__figure{panorama}" data-revele>'
            f'{scene(images, ident, "(max-width: 839px) 86vw, 600px", "section__scene")}</div>')


def figure_pleine(reglage: dict, images: dict, sid: str) -> str:
    """La grande illustration d'une bande pleine, bornee en hauteur pour que tout l'ecran reste lisible."""
    ident = (reglage.get("figures") or {}).get(sid)
    image = images["images"][ident]
    ratio = round(image["largeur"] / image["hauteur"], 4)
    return (f'<div class="pleine__image" style="--ratio:{ratio}" data-revele>'
            f'{scene(images, ident, "(max-width: 839px) 92vw, 1200px", "section__scene")}</div>')


def alternance(reglage: dict):
    """Cote des images de section : la premiere repond au haut de page, les suivantes alternent."""
    cote = "gauche" if reglage.get("cote", "droite") == "droite" else "droite"
    while True:
        yield cote
        cote = "gauche" if cote == "droite" else "droite"


def render_inner(route: str, page: dict, reglage: dict, images: dict, tarifs: dict, today: date | None,
                 avis: dict) -> str:
    gabarit = reglage.get("gabarit", "editorial")
    sections = page["sections"]
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
        morceaux.append(bande_image(reglage, images))
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
    for i, s in enumerate(sections, 1):
        figure = figure_section(reglage, images, s["id"])
        fond = fonds.get(s["id"])
        if fond not in (None, "lavande", "prune"):
            raise ValueError(f"direction.json: unknown fond {fond}")
        avant = len(morceaux)
        if reglage.get("haut") == "parcours" and s["id"] in reglage.get("parcours", []):
            # Les arches du parcours sont en haut de page : la section garde son titre et son texte.
            s = {k: v for k, v in s.items() if k != "points"}
        duo = next((d for d in reglage.get("duos", []) if s["id"] in d), None)
        if duo:
            if s["id"] == duo[0]:
                vider()
                cartes = "".join(
                    render_section(t, i + k, tarifs, today, avis, "duo", figure_section(reglage, images, t["id"]))
                    for k, t in enumerate(x for x in sections if x["id"] in duo))
                morceaux.append(f'<div class="duo">{cartes}</div>')
            continue
        if s["id"] in reglage.get("parcours", []) and reglage.get("haut") != "parcours":
            vider()
            morceaux.append(render_section(s, i, tarifs, today, avis, "parcours"))
        elif not figure and not s.get("generated") and not fond:
            groupe.append((i, s))
        elif figure and s["id"] in reglage.get("pleine", []):
            vider()
            morceaux.append(render_section(s, i, tarifs, today, avis, "pleine", figure_pleine(reglage, images, s["id"])))
        else:
            vider()
            morceaux.append(render_section(s, i, tarifs, today, avis, figure=figure, cote_figure=next(cotes) if figure else "droite"))
        if fond:
            morceaux[-1] = f'<div class="fond fond--{fond}">{morceaux[-1]}</div>'
            assert len(morceaux) > avant
        if apres and s.get("id") == apres:
            vider()
            morceaux.append(bande_image(reglage, images))
    vider()
    return "".join(morceaux)


# --- Page complete ---------------------------------------------------------------

def output_file(output: Path, route: str) -> Path:
    if route == "/fr/":
        return output / "fr" / "index.html"
    return output / f"{route.lstrip('/')}.html"


def donnees_structurees(origin: str) -> str:
    """Organisation educative : seulement des faits publies (M-19, M-27). Aucun avis, aucune note."""
    donnees = {
        "@context": "https://schema.org",
        "@type": "EducationalOrganization",
        "name": "Rewayah Academy",
        "alternateName": "أكاديمية الرواية",
        "url": origin.rstrip("/") + "/fr/",
        "logo": origin.rstrip("/") + f"{ASSETS}/logo-horizontal.svg",
        "email": "contact@rewayahacademy.com",
    }
    return ('<script type="application/ld+json">'
            + json.dumps(donnees, ensure_ascii=False).replace("</", "<\\/") + "</script>")


def render_page(route: str, page: dict, site: dict, origin: str, allow_indexing: bool,
                tarifs: dict | None = None, today: date | None = None, avis: dict | None = None,
                direction: dict | None = None, images: dict | None = None) -> str:
    if tarifs is None:
        tarifs, _ = tarifs_mod.charger_tarifs(env={}, journal=lambda *_: None)
    if avis is None:
        avis, _ = avis_mod.charger_avis(env={}, journal=lambda *_: None)
    if direction is None or images is None:
        direction, images = load_direction(load_content()[0])
    reglage = direction["pages"].get(route, {})
    canonical = origin.rstrip("/") + route
    indexed = allow_indexing and page.get("status") == "ready" and page.get("indexable", True)
    robots = "index,follow" if indexed else "noindex,nofollow"
    nav_items = "".join(anchor(label, href, current=href == route) for label, href in NAV[:-1])
    connexion = anchor(NAV[-1][0], NAV[-1][1], "site-header__connexion")
    footer_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in FOOTER if href.startswith('/fr/legal/') or href in ('/fr/protection-des-enfants', '/fr/accessibilite'))
    discovery_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in (*NAV[:4], ('Comment ça marche', '/fr/comment-ca-marche'), ('L’académie', '/fr/academie'), ('Avis', '/fr/avis'), ('Aide', '/fr/aide'), ('Recrutement', '/fr/recrutement')))
    contact_links = "".join(
        f"<li><strong>{esc(label)}</strong>{anchor(site['contacts'][key], 'mailto:' + site['contacts'][key])}</li>"
        for label, key in CONTACTS
    )
    social_by_href = {item["href"]: item for item in site["social_links"]}
    academy_facebook = social_by_href["https://www.facebook.com/share/1CVee2teiN/"]
    author_facebook = social_by_href["https://www.facebook.com/share/1D6H2EYhci/"]
    cta = bouton(page["cta"]["label"], page["cta"]["href"])
    if route == "/fr/tarifs":
        cta += ('<a class="cta cta--secondary" href="#tarif-simulator">Simuler mon tarif</a>'
                '<noscript><p class="price-note">Le simulateur demande JavaScript. Sans lui, les prix et les remises '
                'de cette page suffisent pour calculer le tarif de votre foyer.</p></noscript>')
    status = (
        '<p class="preview-note" role="status">Cette page est en préparation. '
        'Les éléments contractuels non vérifiés ne sont pas publiés.</p>'
        if page.get("status") == "blocked" else ""
    )
    if route == "/fr/":
        main = render_home(page, images, tarifs, cta)
        classe_page = "page-accueil"
    else:
        main = hero_interieur(route, page, reglage, images, cta, status, tarifs) + render_inner(route, page, reglage, images, tarifs, today, avis)
        fin = reglage.get("fin")
        if fin:
            main += bande_finale(fin["titre"], fin["phrase"], fin.get("label", page["cta"]["label"]),
                                 fin.get("href", page["cta"]["href"]), None)
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
        <label>Nombre d’élèves <span class="pas"><button type="button" data-pas="-1" aria-label="Un élève de moins">−</button><input type="number" inputmode="numeric" min="1" step="1" value="1" id="sim-total"><button type="button" data-pas="1" aria-label="Un élève de plus">+</button></span></label>
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
        fin_grille = main.index("</section>", main.index('id="grille"')) + len("</section>")
        main = main[:fin_grille] + simulator + main[fin_grille:]
        simulator = ""
    image_partage = reglage.get("image") or "chemin"
    largeur_partage = image_largeurs(images, image_partage)[-1]
    meta_partage = (
        f'<meta property="og:type" content="website"><meta property="og:site_name" content="Rewayah Academy">'
        f'<meta property="og:locale" content="fr_FR"><meta property="og:title" content="{esc(page["title"])}">'
        f'<meta property="og:description" content="{esc(page["description"])}"><meta property="og:url" content="{esc(canonical)}">'
        f'<meta property="og:image" content="{esc(origin.rstrip("/") + ASSETS + "/scene-" + image_partage + "-" + str(largeur_partage) + ".webp")}">'
        f'<meta property="og:image:alt" content="{esc(images["images"][image_partage]["alt"])}">'
        '<meta name="twitter:card" content="summary_large_image">'
    )
    jsonld = donnees_structurees(origin) if route == "/fr/" else ""
    ambiance = direction.get("ambiance", "clair")
    if ambiance == "violet":
        tete_couleurs = ('<meta name="color-scheme" content="dark">\n'
                         '  <meta name="theme-color" content="#6538E4">')
        halo = '<div class="halo" aria-hidden="true"></div>'
    else:
        tete_couleurs = ('<meta name="color-scheme" content="light dark">\n'
                         '  <meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)">\n'
                         '  <meta name="theme-color" content="#16161E" media="(prefers-color-scheme: dark)">')
        halo = ""
    return f'''<!doctype html>
<html lang="fr" data-ambiance="{esc(ambiance)}">
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
  <title>{esc(page['title'])}</title>
  {jsonld}
</head>
<body class="{esc(classe_page)}">
  {halo}
  <a class="skip-link" href="#contenu">Aller au contenu</a>
  <header class="site-header" data-entete>
    <div class="site-header__inner">
      <a class="brand site-header__brand" href="/fr/" aria-label="Rewayah Academy, accueil">{logo_entete(ambiance)}</a>
      <nav class="site-nav" aria-label="Navigation principale">{nav_items}</nav>
      {connexion}
      <details class="mobile-menu"><summary><span class="mobile-menu__libelle">Menu</span><span class="mobile-menu__icone" aria-hidden="true"></span></summary><nav aria-label="Navigation mobile">{nav_items}{anchor(NAV[-1][0], NAV[-1][1])}</nav></details>
    </div>
  </header>
  <main class="site-main" id="contenu">
    {main}
  </main>
  {simulator}
  <footer class="site-footer"><div class="site-footer__inner">
     <img class="site-footer__ornement" src="{ASSETS}/ornement-contour-white.svg" width="494" height="777" alt="">
     <div class="footer-identity"><a class="brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="{ASSETS}/logo-horizontal-white.svg" width="1027" height="287" alt=""></a><p>REWAYAH ACADEMY LTD<br>Société n° 16624644</p>
      <address>71-75 Shelton Street<br>Covent Garden, London<br>WC2H 9JQ, Royaume-Uni</address>
    </div>
    <nav aria-label="Découvrir Rewayah"><p class="footer-title">Découvrir</p><ul>{discovery_links}</ul></nav>
    <div><p class="footer-title">Nous contacter</p><ul class="footer-contacts">{contact_links}</ul>
    </div>
    <nav class="footer-legal" aria-label="Navigation légale"><ul>{footer_links}</ul></nav>
    <div class="footer-bottom"><span>Français · Les illustrations du site sont présentées comme telles.</span><div>{anchor(academy_facebook['label'], academy_facebook['href'])}<span>{esc(site['author_credit'])} {anchor(author_facebook['label'], author_facebook['href'])}</span></div></div>
  </div></footer>
</body>
</html>
'''


COPIED_ASSETS = {".svg", ".png", ".webp", ".woff2", ".txt"}


def build(output: Path, origin: str, allow_indexing: bool, tarifs: dict | None = None,
          env: dict[str, str] | None = None, today: date | None = None, avis: dict | None = None) -> None:
    if allow_indexing:
        raise ValueError("This branch is preview-only; publication needs verified commercial and legal data")
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
    direction, images = load_direction(pages)
    for route, page in pages.items():
        destination = output_file(output, route)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(render_page(route, page, site, origin, allow_indexing, tarifs, today, avis,
                                           direction, images), encoding="utf-8")
    assets_out = output / "fr" / "assets"
    assets_out.mkdir(parents=True, exist_ok=True)
    # Un dossier de sortie reutilise ne garde pas une illustration retiree ou re-exportee a une autre largeur.
    publiees = {source.name for source in (ROOT / "assets").glob("scene-*.webp")}
    for ancienne in assets_out.glob("scene-*.webp"):
        if ancienne.name not in publiees:
            ancienne.unlink()
    for source_dir in (ROOT / "assets", ROOT / "styles"):
        if source_dir.exists():
            for source in source_dir.iterdir():
                allowed = COPIED_ASSETS if source_dir.name == "assets" else {".css", ".js"}
                if source.is_file() and source.suffix.lower() in allowed:
                    shutil.copy2(source, assets_out / source.name)
    if not (assets_out / "site.css").exists():
        raise ValueError("Missing site-public/styles/site.css")
    for route in pages:
        if not output_file(output, route).exists():
            raise AssertionError(f"Route was not built: {route}")
    sitemap_urls = [origin.rstrip("/") + route for route, page in pages.items()
                    if allow_indexing and page.get("status") == "ready" and page.get("indexable", True)]
    sitemap = '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + ''.join(
        f'<url><loc>{esc(url)}</loc></url>' for url in sitemap_urls) + '</urlset>'
    (output / "sitemap.xml").write_text(sitemap, encoding="utf-8")
    (output / "robots.txt").write_text(
        f"User-agent: *\n{'Allow: /' if allow_indexing else 'Disallow: /'}\n"
        + (f"Sitemap: {origin.rstrip('/')}/sitemap.xml\n" if allow_indexing else ""),
        encoding="utf-8",
    )
    largeurs_404 = image_largeurs(images, "place")
    (output / "404.html").write_text(
        f'<!doctype html><html lang="fr" data-ambiance="{esc(direction.get("ambiance", "clair"))}"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        '<meta name="color-scheme" content="light dark">'
        '<meta name="robots" content="noindex,nofollow">'
        f'<link rel="stylesheet" href="{ASSETS}/site.css">'
        '<title>Page introuvable | Rewayah Academy</title></head><body class="page-404">'
        '<main class="introuvable"><div class="introuvable__texte"><h1>Cette page est introuvable.</h1>'
        '<p>Revenez à l’accueil ou consultez les cours et l’aide.</p>'
        '<div class="action-row"><a class="cta" href="/fr/">Retour à l’accueil</a>'
        '<a class="cta cta--secondary" href="/fr/aide">Consulter l’aide</a></div></div>'
        f'<figure class="scene introuvable__scene"><img src="{ASSETS}/scene-place-{largeurs_404[-1]}.webp" '
        f'srcset="{", ".join(f"{ASSETS}/scene-place-{w}.webp {w}w" for w in largeurs_404)}" sizes="(max-width: 839px) 90vw, 44vw" '
        f'width="{largeurs_404[-1]}" height="{round(images["images"]["place"]["hauteur"] * largeurs_404[-1] / images["images"]["place"]["largeur"])}" '
        f'alt="{esc(images["images"]["place"]["alt"])}"><figcaption>Illustration</figcaption></figure>'
        '</main></body></html>',
        encoding="utf-8",
    )
    config_path = output / "vercel.json"
    config = json.loads(config_path.read_text(encoding="utf-8")) if config_path.exists() else {}
    # Vercel's documented negative-lookahead syntax leaves unknown /fr paths
    # unmatched, so its static 404.html handles them instead of Flutter.
    fallback = {"source": "/:path((?!fr(?:/|$)).*)", "destination": "/index.html"}
    config["rewrites"] = [
        {"source": route.rstrip("/") or "/", "destination": "/" + str(output_file(Path(), route)).replace("\\", "/")}
        for route in sorted(pages)
    ] + [{"source": "/fr/", "destination": "/fr/index.html"}, fallback]
    config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(pages)} public routes in {output}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--canonical-origin", default="https://rewayah-academy.vercel.app")
    parser.add_argument("--allow-indexing", action="store_true")
    args = parser.parse_args()
    build(args.output, args.canonical_origin, args.allow_indexing)


if __name__ == "__main__":
    main()
