"""Build the public HTML preview beside the existing Flutter Web bundle.

The published commercial projection is intentionally absent. This builder only
renders editorial content that the content contract marks as safe for preview.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
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
    ("Connexion", "/connexion"),
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


def render_section(section: dict, number: int) -> str:
    sid = section.get("id") or f"section-{number}"
    if not re.fullmatch(r"[a-z][a-z0-9-]*", sid):
        raise ValueError(f"Invalid section id: {sid}")
    paragraphs = "".join(f"<p>{esc(p)}</p>" for p in section.get("paragraphs", []))
    points = section.get("points", [])
    bullets = "<ul class=\"fact-list\">" + "".join(f"<li><strong>{esc(p)}</strong></li>" for p in points) + "</ul>" if points else ""
    links = " ".join(anchor(item["label"], item["href"], "text-link") for item in section.get("links", []))
    return (
        f'<section class="section section--rule" id="{esc(sid)}" aria-labelledby="heading-{number}">'
        f'<div class="editorial-grid"><div class="section__intro"><p class="eyebrow">{number:02d} / Rewayah</p>'
        f'<h2 id="heading-{number}">{esc(section["title"])}</h2></div>'
        f'<div class="section__body">{paragraphs}{bullets}<div class="section-links">{links}</div></div></div></section>'
    )


def output_file(output: Path, route: str) -> Path:
    if route == "/fr/":
        return output / "fr" / "index.html"
    return output / f"{route.lstrip('/')}.html"


def render_page(route: str, page: dict, site: dict, origin: str, allow_indexing: bool) -> str:
    canonical = origin.rstrip("/") + route
    indexed = allow_indexing and page.get("status") == "ready" and page.get("indexable", True)
    robots = "index,follow" if indexed else "noindex,nofollow"
    nav_items = "".join(anchor(label, href, current=href == route) for label, href in NAV)
    footer_links = "".join(f"<li>{anchor(label, href, current=href == route)}</li>" for label, href in FOOTER)
    contact_links = "".join(
        f"<li>{esc(label)} : {anchor(site['contacts'][key], 'mailto:' + site['contacts'][key])}</li>"
        for label, key in CONTACTS
    )
    social_by_href = {item["href"]: item for item in site["social_links"]}
    academy_facebook = social_by_href["https://www.facebook.com/share/1CVee2teiN/"]
    author_facebook = social_by_href["https://www.facebook.com/share/1D6H2EYhci/"]
    sections = "".join(render_section(section, i) for i, section in enumerate(page["sections"], 1))
    intro = f'<p class="hero-intro">{esc(page["intro"])}</p>' if page.get("intro") else ""
    cta = anchor(page["cta"]["label"], page["cta"]["href"], "cta")
    if route == "/fr/":
        cta += anchor("Voir comment ça marche", "/fr/comment-ca-marche", "cta cta--secondary")
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
  <meta name="color-scheme" content="light dark">
  <meta name="robots" content="{robots}">
  <meta name="description" content="{esc(page['description'])}">
  <link rel="canonical" href="{esc(canonical)}">
  <link rel="stylesheet" href="/fr/assets/site.css">
  <link rel="icon" type="image/svg+xml" href="/fr/assets/symbole.svg">
  <title>{esc(page['title'])}</title>
</head>
<body>
  <a class="skip-link" href="#contenu">Aller au contenu</a>
  <header class="site-header">
    <div class="site-header__inner">
      <a class="brand site-header__brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="/fr/assets/logo-horizontal.svg" width="1299" height="340" alt=""></a>
      <nav class="site-nav" aria-label="Navigation principale">{nav_items}</nav>
      {anchor('Commencer mon inscription', '/connexion', 'cta header-cta')}
      <details class="mobile-menu"><summary>Menu</summary><nav aria-label="Navigation mobile">{nav_items}</nav></details>
    </div>
  </header>
  <main class="site-main" id="contenu">
    <div class="hero"><div class="hero__copy"><p class="eyebrow">Rewayah Academy</p>
      <h1>{esc(page['h1'])}</h1>{intro}{status}<div class="action-row">{cta}</div>
    </div><div class="hero__proof"><div class="proof-visual proof-visual--pending" aria-hidden="true"><p>Un espace pour apprendre. Un parcours pour chacun.</p></div></div></div>
    {sections}
  </main>
  <footer class="site-footer"><div class="site-footer__inner">
    <div><a class="brand" href="/fr/" aria-label="Rewayah Academy, accueil"><img src="/fr/assets/logo-horizontal.svg" width="1299" height="340" alt=""></a><p>Des cours de Coran en ligne, avec un espace pour chaque élève.</p>
      {anchor(academy_facebook['label'], academy_facebook['href'])}
    </div>
    <nav aria-label="Navigation de pied de page"><ul>{footer_links}</ul></nav>
    <div><p class="footer-title">Nous contacter</p><ul>{contact_links}</ul>
      <p>{esc(site['author_credit'])} {anchor(author_facebook['label'], author_facebook['href'])}</p>
    </div>
  </div></footer>
</body>
</html>
'''


def build(output: Path, origin: str, allow_indexing: bool) -> None:
    if allow_indexing:
        raise ValueError("This branch is preview-only; publication needs verified commercial and legal data")
    parsed = urlparse(origin)
    if parsed.scheme != "https" or not parsed.netloc or parsed.path not in ("", "/"):
        raise ValueError("Canonical origin must be an HTTPS origin")
    pages, site = load_content()
    for route, page in pages.items():
        destination = output_file(output, route)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(render_page(route, page, site, origin, allow_indexing), encoding="utf-8")
    assets_out = output / "fr" / "assets"
    assets_out.mkdir(parents=True, exist_ok=True)
    for source_dir in (ROOT / "assets", ROOT / "styles"):
        if source_dir.exists():
            for source in source_dir.iterdir():
                allowed = {".svg", ".png", ".webp", ".woff2", ".txt"} if source_dir.name == "assets" else {".css"}
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
