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
                # Les titres portent des espaces insecables apres les petits mots ; le texte reste le meme.
                self.assertEqual([h.replace("\u00a0", " ") for h in parser.headings], [self.pages[route]["h1"]])
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

    def test_titles_never_hold_an_unbreakable_chunk_wider_than_a_small_phone(self) -> None:
        # Les espaces insécables des titres ne forment jamais un bloc de plus de 18 signes (320 px à 32 px).
        for route, parser in self.parsed_pages().items():
            for titre in parser.headings:
                for bloc in titre.split(" "):
                    with self.subTest(route=route, bloc=bloc):
                        self.assertLessEqual(len(bloc), 18)

    def test_only_approved_public_assets_are_copied(self) -> None:
        copied = {path.name for path in (self.output / "fr" / "assets").iterdir() if path.is_file()}
        # Les illustrations approuvees sont celles du manifeste (content/images.json), a chaque largeur exportee.
        images = json.loads((SITE / "content" / "images.json").read_text(encoding="utf-8"))
        scenes = {fichier for ident in images["images"] for fichier in BUILDER_MODULE.fichiers_scene(images, ident)}
        self.assertEqual(
            copied,
            {
                "site.css",
                "site.js",
                "motion.js",
                "symbole.svg",
                "symbole-white.svg",
                "symbole-contour.svg",
                "logo-horizontal.svg",
                "logo-horizontal-white.svg",
                "logo-vertical.svg",
                "ornement-contour.svg",
                "ornement-contour-white.svg",
                "dm-sans-latin-ext.woff2",
                "dm-sans-latin.woff2",
                "plus-jakarta-sans-latin-ext.woff2",
                "plus-jakarta-sans-latin.woff2",
                "dm-sans-OFL.txt",
                "plus-jakarta-sans-OFL.txt",
                "reem-kufi-OFL.txt",
            } | scenes,
        )
        self.assertFalse((self.output / "fr" / "assets" / "prototype.html").exists())

    def test_logo_files_are_the_official_ones(self) -> None:
        officiels = SITE.parent / "assets" / "brand" / "logo"
        for copie, source in (
            ("symbole.svg", "violet/symbole-plein.svg"),
            ("symbole-white.svg", "blanc/symbole-plein.svg"),
            ("logo-horizontal.svg", "violet/logo-horizontal.svg"),
            ("logo-horizontal-white.svg", "blanc/logo-horizontal.svg"),
            ("ornement-contour.svg", "violet/ornement-contour.svg"),
            ("ornement-contour-white.svg", "blanc/ornement-contour.svg"),
        ):
            with self.subTest(copie=copie):
                self.assertEqual((SITE / "assets" / copie).read_bytes(), (officiels / source).read_bytes())

    def test_approved_brand_placement_and_public_history(self) -> None:
        home = self.page_file("/fr/").read_text(encoding="utf-8")
        # En-tete web : logo horizontal (violet sur clair, blanc sur sombre), symbole seul sur telephone
        # (assets/brand/logo/README.md, M-25). Pied de page sombre : logo horizontal blanc.
        self.assertIn('site-header__brand" href="/fr/"', home)
        ambiance = json.loads((SITE / "content" / "direction.json").read_text(encoding="utf-8")).get("ambiance", "clair")
        self.assertIn(f'<html lang="fr" data-ambiance="{ambiance}">', home)
        if ambiance == "violet":
            # Sur le violet, le logo de l'en-tete est toujours le fichier blanc officiel (M-25).
            entete = home.split('<header', 1)[1].split('</header>', 1)[0]
            self.assertIn('src="/fr/assets/logo-horizontal-white.svg"', entete)
            self.assertIn('srcset="/fr/assets/symbole-white.svg"', entete)
            self.assertNotIn('logo-horizontal.svg"', entete)
        else:
            self.assertIn('src="/fr/assets/logo-horizontal.svg"', home)
            self.assertIn('srcset="/fr/assets/logo-horizontal-white.svg"', home)
            self.assertIn('srcset="/fr/assets/symbole.svg"', home)
        self.assertIn('src="/fr/assets/logo-horizontal-white.svg"', home)
        # Le nom de l'academie est dit dans le premier ecran (sur telephone, l'en-tete ne montre que le symbole) : dans la
        # phrase sous le titre ; la date et les fondateurs sont dits plus bas, dans le bandeau « Accompagné à chaque étape ».
        intro = re.search(r'<p class="hero-intro">(.*?)</p>', home.split('class="porte"', 1)[1], re.S).group(1)
        self.assertIn("Rewayah Academy", intro.replace("\u00a0", " "))
        self.assertIn("Fondée le 1er mai 2024 par trois spécialistes", re.sub(r"<[^>]+>", "", home).replace("\u00a0", " "))
        self.assertNotIn('4 août 2025', "\n".join(path.read_text(encoding="utf-8") for path in self.output.rglob("*.html")))

    def test_every_illustration_is_described_and_declared_once(self) -> None:
        # Decision du directeur du 22/10/2026 (registre de marque, M-30) : pas de legende sous chaque illustration ;
        # une seule mention, dans les mentions legales ; chaque image garde un texte alternatif qui la decrit.
        images = json.loads((SITE / "content" / "images.json").read_text(encoding="utf-8"))
        for route in self.pages:
            source = self.page_file(route).read_text(encoding="utf-8")
            with self.subTest(route=route):
                for figure in re.findall(r'<figure class="scene[^"]*"[^>]*>.*?</figure>', source, re.S):
                    self.assertRegex(figure, r'alt="[^"]{20,}"')
                self.assertNotIn(">Illustration<", source)
        mentions = self.page_file("/fr/legal/mentions").read_text(encoding="utf-8").replace("\u00a0", " ")
        self.assertIn("Les images de ce site sont des illustrations, sauf les photos des fondateurs.", mentions)
        for ident, image in images["images"].items():
            self.assertGreaterEqual(len(image["alt"]), 20, ident)

    def test_portraits_are_named_photos_never_captioned_illustration(self) -> None:
        # Une vraie photo (le directeur) n'est pas une illustration : ni « Illustration » ni texte alternatif vide.
        images = json.loads((SITE / "content" / "images.json").read_text(encoding="utf-8"))
        # Accueil : le visage du directeur. Academie : son mot, puis les deux autres fondateurs, chacun avec son portrait.
        for route, nombre in (("/fr/", 1), ("/fr/academie", 3)):
            source = self.page_file(route).read_text(encoding="utf-8")
            portraits = re.findall(r'<figure class="portrait[^"]*">.*?</figure>', source, re.S)
            with self.subTest(route=route):
                self.assertEqual(len(portraits), nombre)
                for figure in portraits:
                    self.assertNotIn("Illustration", figure)
                    ident = re.search(r'src="/fr/assets/scene-([a-z-]+)-\d+\.webp"', figure).group(1)
                    self.assertIn("legende", images["images"][ident]["photo"])
                    self.assertIn(f'alt="{images["images"][ident]["alt"]}"', figure)
        # Chaque profil de fondateur porte le portrait de la personne qu'il nomme.
        academie = self.page_file("/fr/academie").read_text(encoding="utf-8")
        profils = re.findall(r'<li class="profil">.*?</li>\s*(?=<li class="profil">|</ul></section>)', academie, re.S)
        self.assertEqual(len(profils), 2)
        for profil in profils:
            nom = re.sub(r"<[^>]+>", "", re.search(r"<h3>(.*?)</h3>", profil).group(1)).replace("\u00a0", " ")
            with self.subTest(nom=nom):
                self.assertIn(f'alt="{nom}', profil)

    def test_director_message_and_founders_render_in_french_only(self) -> None:
        academie = self.page_file("/fr/academie").read_text(encoding="utf-8")
        sections = {s["id"]: s for s in self.pages["/fr/academie"]["sections"]}
        fondateurs = academie.split('id="fondateurs"', 1)[1].split("</section>", 1)[0]
        noms = [re.sub(r"<[^>]+>", "", h).replace("\u00a0", " ") for h in re.findall(r"<h3>(.*?)</h3>", fondateurs)]
        # Le directeur est presente par son mot (photo, signature et parcours) ; les deux autres fondateurs ont leur profil.
        directeur = sections["mot"]["signature"]["nom"]
        self.assertEqual(noms, [p["nom"] for p in sections["fondateurs"]["profils"] if p["nom"] != directeur])
        mot = academie.split('id="mot"', 1)[1].split("</section>", 1)[0].replace("\u00a0", " ")
        for ligne in next(p for p in sections["fondateurs"]["profils"] if p["nom"] == directeur)["parcours"]:
            self.assertIn(ligne.replace("\u00a0", " "), mot)
        self.assertIn('<blockquote class="mot__citation">', academie)
        # L'accueil reprend une phrase du mot, signee ; le build refuse un extrait qui n'en vient pas.
        accueil = self.page_file("/fr/").read_text(encoding="utf-8").replace(" ", " ")
        self.assertIn(sections["mot"]["extrait"].replace(" ", " "), accueil)
        # L'arabe attend le site en arabe (registre M-29) : sur les pages francaises, seules les lettres des arches de Cours
        # (et le nom arabe de l'academie dans les donnees structurees, M-27, qui ne s'affiche pas). Les textes
        # alternatifs comptent : un lecteur d'ecran les lit. Toutes les plages de l'arabe, formes de presentation comprises.
        arabe = re.compile(r"[\u0600-\u06FF\u0750-\u077F\u0870-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]")
        for route in self.pages:
            source = re.sub(r'<span class="parcours__arabe"[^>]*>(?:<span[^>]*>[^<]*</span>|[^<])*</span>|<script type="application/ld\+json">.*?</script>', "",
                            self.page_file(route).read_text(encoding="utf-8"), flags=re.S)
            with self.subTest(route=route):
                self.assertIsNone(arabe.search(source))

    def test_a_citation_needs_its_portrait_and_a_true_excerpt(self) -> None:
        mot = dict(next(s for s in self.pages["/fr/academie"]["sections"] if s.get("citation")))
        images = json.loads((SITE / "content" / "images.json").read_text(encoding="utf-8"))
        with self.assertRaisesRegex(ValueError, "portrait"):
            BUILDER_MODULE.section_mot(mot, 1, images, None)
        mot["extrait"] = "Une phrase que le directeur n'a pas dite."
        with self.assertRaisesRegex(ValueError, "extrait"):
            BUILDER_MODULE.section_mot(mot, 1, images, "portrait-directeur")

    def test_page_endings_name_their_link_by_what_they_show(self) -> None:
        # L'accueil et les pages principales se referment sur un titre qui est le lien : le texte visible est le titre,
        # et le libelle de l'action suit pour les lecteurs d'ecran quand il en differe. Les fins en bandeau centre
        # (fin.forme) portent un bouton.
        direction = json.loads((SITE / "content" / "direction.json").read_text(encoding="utf-8"))["pages"]
        accueil = {s["id"]: s for s in self.pages["/fr/"]["sections"]}["footer"]
        fins = {"/fr/": {"titre": accueil["paragraphs"][0], "label": self.pages["/fr/"]["cta"]["label"], "forme": "porte"}}
        fins.update({route: reglage["fin"] for route, reglage in direction.items() if (reglage.get("fin") or {}).get("seuil")})
        self.assertGreaterEqual(len(fins), 6)
        for route, fin in fins.items():
            source = self.page_file(route).read_text(encoding="utf-8")
            with self.subTest(route=route):
                if fin.get("forme") in ("centre", "prix", "image", "note", "porte"):
                    # Bandeau centre, fin sur les prix, sur une arche ou sur une note : le titre, sa phrase, puis un bouton
                    # qui porte le libelle de l'action.
                    fin_page = re.split(rf'class="appel [^"]*appel--{fin["forme"]}[^"]*"', source, maxsplit=1)[1].split("</section>", 1)[0]
                    titre = re.search(r'<h2 id="appel-titre" class="appel__titre"[^>]*>(.*?)</h2>', fin_page, re.S).group(1)
                    self.assertEqual(re.sub(r"<[^>]+>", "", titre).replace("\u00a0", " ").strip(), fin["titre"])
                    self.assertIn(f'href="{fin.get("href", self.pages[route]["cta"]["href"])}"', fin_page)
                    self.assertIn(fin.get("label", self.pages[route]["cta"]["label"]), fin_page.replace("&#x27;", "'"))
                    continue
                titre = re.search(r'<h2 id="appel-titre" class="appel__titre"[^>]*><a class="appel__titre-lien" '
                                  r'href="([^"]+)">(.*?)</a></h2>', source, re.S)
                self.assertIsNotNone(titre)
                self.assertEqual(titre.group(1), fin.get("href", self.pages[route]["cta"]["href"]))
                visible = re.sub(r'<span class="sr-only">.*?</span>', "", titre.group(2))
                self.assertEqual(re.sub(r"<[^>]+>", "", visible).replace("\u00a0", " ").strip(), fin["titre"])
                label = fin.get("label", self.pages[route]["cta"]["label"])
                if label.rstrip(".").casefold() != fin["titre"].rstrip(".").casefold():
                    self.assertIn(f'<span class="sr-only"> ({label})</span>', titre.group(2))

    def test_font_names_are_written_once_in_the_stylesheet(self) -> None:
        # Changer une police du site, c'est changer une ligne : hors des @font-face, la feuille ne nomme jamais une
        # police, elle lit --police-titre, --police-corps ou --police-arabe-ornement (:root).
        css = (SITE / "styles" / "site.css").read_text(encoding="utf-8")
        sans_faces = re.sub(r"@font-face\s*\{[^}]*\}", "", css)
        declarations = re.findall(r"font-family:\s*([^;}]+)", sans_faces)
        self.assertTrue(declarations)
        for valeur in declarations:
            with self.subTest(valeur=valeur):
                self.assertRegex(valeur.strip(), r"^(var\(--police-[a-z-]+\)|inherit)$")
        racine = re.search(r":root\s*\{(.*?)\n\}", css, re.S).group(1)
        for nom in ("--police-titre", "--police-corps", "--police-arabe-ornement"):
            self.assertIn(nom + ":", racine)

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
