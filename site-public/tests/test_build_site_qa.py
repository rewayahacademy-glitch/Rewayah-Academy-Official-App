"""Output-level checks for real public-site release risks."""

from __future__ import annotations

import html.parser
import importlib.util
import json
import re
import unittest
from pathlib import Path


SITE = Path(__file__).resolve().parents[1]
BUILDER = SITE / "build_site.py"
CONTENT = SITE / "content" / "pages.json"
OUTPUT = SITE / "tests" / ".qa-build"
SPEC = importlib.util.spec_from_file_location("rewayah_site_builder", BUILDER)
assert SPEC and SPEC.loader
BUILDER_MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILDER_MODULE)
PUBLIC_EMAILS = {
    "contact@rewayahacademy.com",
    "support@rewayahacademy.com",
    "recrutement@rewayahacademy.com",
    "invoice@rewayahacademy.com",
}


class PageParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.headings: list[str] = []
        self.current_heading: list[str] | None = None
        self.links: list[str] = []
        self.text: list[str] = []
        self.canonicals: list[str] = []
        self.robots: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "h1":
            self.current_heading = []
        elif tag == "a" and values.get("href"):
            self.links.append(values["href"] or "")
        elif tag == "link" and values.get("rel") == "canonical":
            self.canonicals.append(values.get("href") or "")
        elif tag == "meta" and values.get("name") == "robots":
            self.robots.append(values.get("content") or "")

    def handle_endtag(self, tag: str) -> None:
        if tag == "h1" and self.current_heading is not None:
            self.headings.append("".join(self.current_heading).strip())
            self.current_heading = None

    def handle_data(self, data: str) -> None:
        self.text.append(data)
        if self.current_heading is not None:
            self.current_heading.append(data)


class GeneratedSiteQA(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.output = OUTPUT
        BUILDER_MODULE.build(cls.output, "https://rewayah-academy.vercel.app", False)
        cls.data = json.loads(CONTENT.read_text(encoding="utf-8"))
        cls.pages = cls.data["pages"]

    def page_file(self, route: str) -> Path:
        return self.output / "fr" / ("index.html" if route == "/fr/" else route[4:] + ".html")

    def parsed_pages(self) -> dict[str, PageParser]:
        parsed = {}
        for route in self.pages:
            self.assertTrue(self.page_file(route).is_file(), route)
            parser = PageParser()
            parser.feed(self.page_file(route).read_text(encoding="utf-8"))
            parsed[route] = parser
        return parsed

    def test_every_emitted_page_has_one_matching_h1_and_self_canonical(self) -> None:
        origin = "https://rewayah-academy.vercel.app"
        for route, parser in self.parsed_pages().items():
            with self.subTest(route=route):
                self.assertEqual(parser.headings, [self.pages[route]["h1"]])
                self.assertEqual(parser.canonicals, [origin + route])

    def test_rendered_internal_links_resolve_to_emitted_pages_or_app_entry(self) -> None:
        pages = self.parsed_pages()
        for source, parser in pages.items():
            for href in parser.links:
                if href.startswith("/fr/"):
                    self.assertIn(href.split("#", 1)[0], pages, f"{source} -> {href}")
                elif href.startswith("/"):
                    self.assertEqual(href.split("#", 1)[0], "/connexion", f"{source} -> {href}")

    def test_preview_cannot_be_indexed_or_publish_unapproved_contact_data(self) -> None:
        html_files = list(self.output.rglob("*.html"))
        rendered = "\n".join(path.read_text(encoding="utf-8") for path in html_files)
        self.assertTrue(html_files)
        for parser in self.parsed_pages().values():
            self.assertEqual(parser.robots, ["noindex,nofollow"])
        self.assertNotIn("https://rewayah-academy.vercel.app/", (self.output / "sitemap.xml").read_text())
        emails = set(re.findall(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", rendered))
        self.assertLessEqual(emails, PUBLIC_EMAILS)
        self.assertNotIn("\u2014", " ".join(parser_text for parser in self.parsed_pages().values() for parser_text in parser.text))
        for marker in ("sb_secret_", "service_role", "SUPABASE_SERVICE_ROLE_KEY", "VERCEL_TOKEN"):
            self.assertNotIn(marker, rendered)

    def test_only_approved_public_assets_are_copied(self) -> None:
        copied = {path.name for path in (self.output / "fr" / "assets").iterdir() if path.is_file()}
        self.assertEqual(
            copied,
            {
                "site.css",
                "symbole.svg",
                "symbole-contour.svg",
                "logo-horizontal.svg",
                "logo-vertical.svg",
                "dm-sans-latin-ext.woff2",
                "dm-sans-latin.woff2",
                "plus-jakarta-sans-latin-ext.woff2",
                "plus-jakarta-sans-latin.woff2",
                "dm-sans-OFL.txt",
                "plus-jakarta-sans-OFL.txt",
            },
        )
        self.assertFalse((self.output / "fr" / "assets" / "prototype.html").exists())

    def test_bundle_gate_covers_every_local_font_requested_by_css(self) -> None:
        css = (SITE / "styles" / "site.css").read_text(encoding="utf-8")
        fonts = set(re.findall(r"\.\./assets/([a-z0-9-]+\.woff2)", css))
        workflow = (SITE.parent / ".github" / "workflows" / "flutter-deploy.yml").read_text(encoding="utf-8")
        self.assertEqual(len(fonts), 4)
        for font in fonts:
            self.assertIn(f"fr/assets/{font}", workflow)

    def test_vercel_rewrites_cover_emitted_routes_and_leave_unknown_fr_to_404(self) -> None:
        config = json.loads((self.output / "vercel.json").read_text(encoding="utf-8"))
        rewrites = config["rewrites"]
        by_source = {rule["source"]: rule["destination"] for rule in rewrites}
        for route in self.pages:
            source = route.rstrip("/") or "/"
            destination = by_source[source].lstrip("/")
            self.assertTrue((self.output / destination).is_file(), f"{source} -> {destination}")
        self.assertIn("(?!fr", rewrites[-1]["source"])
        self.assertTrue((self.output / "404.html").is_file())

    def test_unknown_public_paths_get_a_non_indexable_404_artifact(self) -> None:
        not_found = self.output / "404.html"
        self.assertTrue(not_found.is_file())
        source = not_found.read_text(encoding="utf-8")
        parser = PageParser()
        parser.feed(source)
        self.assertEqual(parser.headings, ["Cette page est introuvable."])
        self.assertEqual(parser.robots, ["noindex,nofollow"])
        self.assertIn("/fr/", parser.links)

    def test_indexing_flag_stays_closed_until_publication_data_is_verified(self) -> None:
        with self.assertRaisesRegex(ValueError, "preview-only"):
            BUILDER_MODULE.build(self.output, "https://rewayah-academy.vercel.app", True)


if __name__ == "__main__":
    unittest.main()
