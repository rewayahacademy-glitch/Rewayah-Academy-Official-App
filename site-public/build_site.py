"""Build the public HTML preview beside the existing Flutter Web bundle.

The published commercial projection is intentionally absent. This builder only
renders editorial content that the content contract marks as safe for preview.
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


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


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


def render_section(section: dict, number: int, tarifs: dict | None = None, today: date | None = None,
                   avis: dict | None = None) -> str:
    sid = section.get("id") or f"section-{number}"
    if not re.fullmatch(r"[a-z][a-z0-9-]*", sid):
        raise ValueError(f"Invalid section id: {sid}")
    paragraphs = "".join(f"<p>{esc(p)}</p>" for p in section.get("paragraphs", []))
    points = section.get("points", [])
    bullets = "<ul class=\"fact-list\">" + "".join(f"<li><strong>{esc(p)}</strong></li>" for p in points) + "</ul>" if points else ""
    links = " ".join(anchor(item["label"], item["href"], "text-link") for item in section.get("links", []))
    generated = ""
    if section.get("generated", "").startswith("avis-"):
        if avis is None:
            raise ValueError(f"Section generated without avis: {sid}")
        generated = avis_mod.rendre_avis_section(section["generated"][len("avis-"):], avis)
    elif section.get("generated"):
        if tarifs is None:
            raise ValueError(f"Section generated without tarifs: {sid}")
        generated = tarifs_mod.rendre_tarifs_section(section["generated"], tarifs, today or date.today())
    return (
        f'<section class="section section--rule" id="{esc(sid)}" aria-labelledby="heading-{number}">'
        f'<div class="editorial-grid"><div class="section__intro"><p class="eyebrow">{number:02d} / Rewayah</p>'
        f'<h2 id="heading-{number}">{esc(section["title"])}</h2></div>'
        f'<div class="section__body">{paragraphs}{generated}{bullets}<div class="section-links">{links}</div></div></div></section>'
    )


def render_home_section(section: dict, number: int, tarifs: dict | None = None, today: date | None = None,
                        avis: dict | None = None) -> str:
    sid = section["id"]
    paragraphs = "".join(f"<p>{esc(p)}</p>" for p in section.get("paragraphs", []))
    links = " ".join(anchor(item["label"], item["href"], "cta" if i == 0 else "cta cta--secondary") for i, item in enumerate(section.get("links", [])))
    visual = ""
    eyebrow = {"foyer": "L’espace familial", "cours": "Les cours", "suivi": "Le suivi", "fonctionnement": "Votre inscription"}.get(sid, "")
    extra = ""
    if sid == "foyer":
        visual = '''<figure class="family-scene"><div class="family-preview">
          <h3>Foyer</h3><p>Membres du foyer</p>
          <div class="member-row"><span class="member-avatar" aria-hidden="true">S</span><div><strong>Salam</strong><span>8 ans</span><small>Son parcours · ses cours</small></div></div>
          <div class="member-row"><span class="member-avatar member-avatar--second" aria-hidden="true">M</span><div><strong>Mariam</strong><span>10 ans</span><small>Son parcours · son suivi</small></div></div>
          </div><figcaption>Exemple illustratif de l’espace familial.</figcaption></figure>'''
    elif sid == "cours":
        visual = '''<figure class="course-scene"><div class="course-preview">
          <div class="course-preview__support"><h3>Les voyelles courtes</h3>
          <div class="vowel-list" aria-label="Exemples linguistiques : bou, bi, ba">
            <div><span lang="ar" dir="rtl">بُ</span><small>bou</small></div>
            <div class="vowel-list__focus"><span lang="ar" dir="rtl">بِ</span><small>bi</small></div>
            <div><span lang="ar" dir="rtl">بَ</span><small>ba</small></div>
          </div><p>Écouter · Lire · Répéter</p></div>
          <img class="teacher-portrait" src="/fr/assets/enseignant-portrait.png" width="1024" height="1024" alt="Portrait illustratif d’un enseignant à distance" loading="lazy">
          </div><figcaption>Exemple de support pédagogique, hors texte coranique.</figcaption></figure>'''
        extra = '''<table class="course-facts"><caption class="sr-only">Organisation des cours</caption>
          <thead class="sr-only"><tr><th>Public</th><th>Effectif maximal</th><th>Durée</th></tr></thead>
          <tbody><tr><th scope="row">Enfants</th><td>5 élèves maximum</td><td>1 h dont 5 min de pause</td></tr>
          <tr><th scope="row">Adultes</th><td>6 élèves maximum</td><td>1 h 30</td></tr></tbody></table>
          <p class="course-frequency">3 séances par semaine.</p>'''
        links += '<p class="action-note">Français, poular ou anglais selon les horaires proposés.</p>'
    elif sid == "suivi":
        visual = '''<figure class="follow-scene">
          <img class="section-person" src="/fr/assets/suivi-parent-tablette.png" width="1536" height="1024" alt="Mère voilée consultant une tablette, scène illustrative" loading="lazy">
          <div class="history-preview"><h3>Historique</h3><p>Le suivi de votre enfant</p><div><strong>Séances</strong><span>Travail à reprendre</span></div><small>Exemple de suivi</small></div>
          </figure>'''
        paragraphs = f'<p>{esc(section["paragraphs"][0])}</p><div class="observation"><h3>Observer une séance</h3><p>{esc(section["paragraphs"][1])}</p></div>'
    elif sid == "fonctionnement":
        visual = ('<ol class="steps"><li><span>01</span><div><h3>Votre inscription</h3><p>Pour votre enfant ou pour vous.</p></div></li>'
                  '<li><span>02</span><div><h3>Votre créneau</h3><p>Explorez les jours et heures de cours.</p><small>Les horaires proposés s’affichent dans votre espace.</small></div></li>'
                  '<li><span>03</span><div><h3>Votre classe</h3><p>Recevez une proposition de classe avec un enseignant attitré.</p></div></li></ol>')
    elif sid == "tarifs":
        politique = tarifs_mod.politique_affichee(tarifs)
        rang_min = politique["remisesFoyer"][0]["aPartirDuRang"] if politique["remisesFoyer"] else None
        intro_remise = (f"Les remises du foyer commencent au {tarifs_mod.fmt_rang(rang_min)} membre inscrit."
                        if rang_min else "Le tarif est le même pour chaque membre du foyer.")
        jour = today or date.today()
        grille = tarifs_mod.rendre_tarifs_section("grille", tarifs, jour)
        rangs = tarifs_mod._tableau("Par personne et par mois complet", ("Rang d’inscription", "Remise"),
                                    tarifs_mod.lignes_remises_rang(politique))
        famille = tarifs_mod.rendre_tarifs_section("famille", tarifs, jour)
        return f'''<section class="home-section home-section--tarifs" id="tarifs" aria-labelledby="home-heading-{number}">
          <div class="wide-intro"><h2 id="home-heading-{number}">{esc(section['title'])}</h2><p>{esc(intro_remise)}</p></div>
          <div class="pricing-layout"><div>
          {grille}
          {rangs}
          <div class="action-row">{anchor('Voir mon récapitulatif', '/connexion', 'cta')}<button class="cta cta--secondary" type="button" data-open-simulator>Simuler mon tarif</button></div>
          <p class="price-note">Le montant final et les taxes éventuelles sont indiqués avant paiement.</p>
          {anchor('Conditions des remises familiales', '/fr/tarifs', 'text-link')}</div>
          <aside class="price-examples"><h3>Le tarif de votre foyer</h3>{famille}</aside></div></section>'''
    elif sid == "confiance":
        return f'''<section class="home-section home-section--confiance" id="confiance" aria-labelledby="home-heading-{number}">
          <p class="since">Depuis le 1er mai 2024</p><h2 id="home-heading-{number}">{esc(section['title'])}</h2>{paragraphs}
          <div class="academy-benefits"><div><h3>Un enseignant attitré</h3><p>Le même enseignant accompagne la classe au fil des séances.</p></div><div><h3>Un suivi pour les familles</h3><p>Retrouvez les séances et le travail à reprendre dans votre espace familial.</p></div></div>
          <div class="action-row">{anchor('Découvrir l’académie', '/fr/academie', 'cta')}</div>{anchor('Protection des enfants', '/fr/protection-des-enfants', 'text-link')}
          <small class="academy-identity">REWAYAH ACADEMY LTD · Société n° 16624644</small></section>'''
    elif sid == "faq-articles":
        questions = (
            ('Mon enfant peut-il commencer sans savoir lire ?', 'Oui. Les débutants commencent par les bases, avec un parcours adapté à leur niveau.'),
            ('Comment est proposée la classe ?', 'Vous choisissez un créneau proposé. L’académie forme la classe, attribue l’enseignant et vous envoie une proposition.'),
            ('Puis-je observer une séance ?', 'Deux visites de deux minutes par séance, lorsque l’observation est autorisée. Vous écoutez sans activer votre micro ni votre caméra. L’enfant et l’enseignant sont informés de votre présence.'),
            ('Puis-je m’inscrire pour moi-même ?', 'Oui. Vous pouvez vous inscrire à un parcours adulte depuis votre espace familial.'),
        )
        faq = ''.join(f'<details{" open" if i == 0 else ""}><summary>{esc(q)}</summary><p>{esc(a)}</p></details>' for i, (q, a) in enumerate(questions))
        return f'''<section class="home-section home-section--faq" id="faq-articles" aria-labelledby="home-heading-{number}">
          <div class="wide-intro"><h2 id="home-heading-{number}">{esc(section['title'])}</h2>{paragraphs}</div>
          <div class="faq-layout"><div><h3>À découvrir</h3><ul class="reading-list"><li>{anchor('Comprendre le déroulement des cours', '/fr/cours')}</li><li>{anchor('Accompagner son enfant', '/fr/familles')}</li><li>{anchor('Comprendre l’inscription et les horaires', '/fr/comment-ca-marche')}</li></ul>{anchor('Consulter l’aide', '/fr/aide', 'cta')}</div>
          <div class="faq"><h3>Questions fréquentes</h3>{faq}</div></div></section>'''
    elif sid == "footer":
        return f'''<section class="home-section home-section--footer" id="footer" aria-labelledby="home-heading-{number}"><h2 id="home-heading-{number}">{esc(section['title'])}</h2><p>Retrouvez votre espace familial dans Rewayah.</p><div class="action-row">{anchor('Commencer mon inscription', '/connexion', 'cta')}{anchor('Se connecter', '/connexion', 'cta cta--secondary')}</div></section>'''
    return (f'<section class="home-section home-section--{esc(sid)}" id="{esc(sid)}" aria-labelledby="home-heading-{number}">'
            f'<div class="home-section__copy"><p class="eyebrow">{eyebrow}</p>'
            f'<h2 id="home-heading-{number}">{esc(section["title"])}</h2>{paragraphs}{extra}'
            f'<div class="section-links">{links}</div></div><div class="home-section__visual">{visual}</div></section>')


def output_file(output: Path, route: str) -> Path:
    if route == "/fr/":
        return output / "fr" / "index.html"
    return output / f"{route.lstrip('/')}.html"


def render_page(route: str, page: dict, site: dict, origin: str, allow_indexing: bool,
                tarifs: dict | None = None, today: date | None = None, avis: dict | None = None) -> str:
    if tarifs is None:
        tarifs, _ = tarifs_mod.charger_tarifs(env={}, journal=lambda *_: None)
    if avis is None:
        avis, _ = avis_mod.charger_avis(env={}, journal=lambda *_: None)
    canonical = origin.rstrip("/") + route
    indexed = allow_indexing and page.get("status") == "ready" and page.get("indexable", True)
    robots = "index,follow" if indexed else "noindex,nofollow"
    nav_items = "".join(anchor(label, href, current=href == route) for label, href in NAV)
    footer_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in FOOTER if href.startswith('/fr/legal/') or href in ('/fr/protection-des-enfants', '/fr/accessibilite'))
    discovery_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in (*NAV[:4], ('L’académie', '/fr/academie'), ('Avis', '/fr/avis'), ('Aide', '/fr/aide'), ('Recrutement', '/fr/recrutement')))
    contact_links = "".join(
        f"<li><strong>{esc(label)}</strong>{anchor(site['contacts'][key], 'mailto:' + site['contacts'][key])}</li>"
        for label, key in CONTACTS
    )
    social_by_href = {item["href"]: item for item in site["social_links"]}
    academy_facebook = social_by_href["https://www.facebook.com/share/1CVee2teiN/"]
    author_facebook = social_by_href["https://www.facebook.com/share/1D6H2EYhci/"]
    renderer = render_home_section if route == "/fr/" else render_section
    sections = "".join(renderer(section, i, tarifs, today, avis) for i, section in enumerate(page["sections"], 1))
    intro = f'<p class="hero-intro">{esc(page["intro"])}</p>' if page.get("intro") else ""
    cta = anchor(page["cta"]["label"], page["cta"]["href"], "cta")
    if route == "/fr/":
        cta += anchor("Voir comment ça marche", "#fonctionnement", "cta cta--secondary")
    if route == "/fr/tarifs":
        cta += ('<button class="cta cta--secondary" type="button" data-open-simulator>Simuler mon tarif</button>'
                '<noscript><p class="price-note">Le simulateur demande JavaScript. Sans lui, les prix et les remises '
                'de cette page suffisent pour calculer le tarif de votre foyer.</p></noscript>')
    simulator = f'''<dialog class="simulator" id="tarif-simulator" aria-labelledby="simulator-title">
      <form method="dialog"><button class="simulator__close" aria-label="Fermer le simulateur">×</button></form>
      <h2 id="simulator-title">Estimez le tarif de votre foyer</h2>
      <p>Indiquez le nombre d’élèves, puis l’âge de chacun, dans l’ordre d’inscription.</p>
      <div class="simulator__fields">
        <label>Nombre d’élèves <input type="number" inputmode="numeric" min="1" step="1" value="1" id="sim-total"></label>
        <label>Paiement <select id="sim-paiement"></select></label>
        <label>Parrainage <input type="checkbox" id="sim-parrainage"></label>
      </div>
      <div class="simulator__fields" id="sim-students"></div>
      <div class="simulator__result" role="status" aria-live="polite" aria-atomic="true" id="sim-result"><p>Le simulateur demande JavaScript.</p></div>
      <script type="application/json" id="tarifs-data">{tarifs_mod.donnees_simulateur(tarifs)}</script>
      <p class="simulator__note">Prix hors taxes, pour un mois complet. Les taxes éventuelles sont indiquées avant paiement.</p>
      <a class="cta" href="/connexion">Commencer mon inscription</a>
    </dialog>''' if route in ("/fr/", "/fr/tarifs") else ""
    status = (
        '<p class="preview-note" role="status">Cette page est en préparation. '
        'Les éléments contractuels non vérifiés ne sont pas publiés.</p>'
        if page.get("status") == "blocked" else ""
    )
    return f'''<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <meta name="robots" content="{robots}">
  <meta name="description" content="{esc(page['description'])}">
  <link rel="canonical" href="{esc(canonical)}">
  <link rel="stylesheet" href="/fr/assets/site.css">
  <script src="/fr/assets/site.js" defer></script>
  <link rel="icon" type="image/svg+xml" href="/fr/assets/symbole.svg">
  <title>{esc(page['title'])}</title>
</head>
<body>
  <a class="skip-link" href="#contenu">Aller au contenu</a>
  <header class="site-header">
    <div class="site-header__inner">
      <a class="brand site-header__brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="/fr/assets/symbole-white.svg" width="716" height="707" alt=""></a>
      <nav class="site-nav" aria-label="Navigation principale">{nav_items}</nav>
      <details class="mobile-menu"><summary>Menu</summary><nav aria-label="Navigation mobile">{nav_items}</nav></details>
    </div>
  </header>
  <main class="site-main" id="contenu">
    <div class="hero {'hero--home' if route == '/fr/' else ''}"><div class="hero__copy"><p class="eyebrow">Rewayah Academy</p>
      <h1>{esc(page['h1'])}</h1>{intro}{status}<div class="action-row">{cta}</div>
    </div>{'<div class="hero__proof"><img src="/fr/assets/hero-enfant-cours.png" width="1673" height="941" alt="Illustration d’un enfant en cours à distance, avec son enseignant visible sur l’ordinateur"></div>' if route == '/fr/' else ''}</div>
    {sections}
  </main>
  {simulator}
  <footer class="site-footer"><div class="site-footer__inner">
     <div class="footer-identity"><a class="brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="/fr/assets/logo-horizontal-white.svg" width="1027" height="287" alt=""></a><p>REWAYAH ACADEMY LTD<br>Société n° 16624644</p>
      <address>71-75 Shelton Street<br>Covent Garden, London<br>WC2H 9JQ, Royaume-Uni</address>
    </div>
    <nav aria-label="Découvrir Rewayah"><p class="footer-title">Découvrir</p><ul>{discovery_links}</ul></nav>
    <div><p class="footer-title">Nous contacter</p><ul class="footer-contacts">{contact_links}</ul>
    </div>
    <nav class="footer-legal" aria-label="Navigation légale"><ul>{footer_links}</ul></nav>
    <div class="footer-bottom"><span>Français</span><div>{anchor(academy_facebook['label'], academy_facebook['href'])}<span>{esc(site['author_credit'])} {anchor(author_facebook['label'], author_facebook['href'])}</span></div></div>
  </div></footer>
</body>
</html>
'''


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
    for route, page in pages.items():
        destination = output_file(output, route)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(render_page(route, page, site, origin, allow_indexing, tarifs, today, avis), encoding="utf-8")
    assets_out = output / "fr" / "assets"
    assets_out.mkdir(parents=True, exist_ok=True)
    for source_dir in (ROOT / "assets", ROOT / "styles"):
        if source_dir.exists():
            for source in source_dir.iterdir():
                allowed = {".svg", ".png", ".webp", ".woff2", ".txt"} if source_dir.name == "assets" else {".css", ".js"}
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
    (output / "404.html").write_text(
        '<!doctype html><html lang="fr"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        '<meta name="robots" content="noindex,nofollow">'
        '<link rel="stylesheet" href="/fr/assets/site.css">'
        '<title>Page introuvable | Rewayah Academy</title></head><body>'
        '<main class="section"><p class="eyebrow">404</p><h1>Cette page est introuvable.</h1>'
        '<p>Revenez à l’accueil ou consultez les cours et l’aide.</p>'
        '<div class="action-row"><a class="cta" href="/fr/">Retour à l’accueil</a>'
        '<a class="cta cta--secondary" href="/fr/aide">Consulter l’aide</a></div>'
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
