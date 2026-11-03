"""Le hub d'articles (directeur, 03/11/2026) : deux articles publies, relus par la direction avant fusion.

Ces tests gardent ce qui ne doit jamais deriver : la date, l'auteur, les sources, le vocabulaire de l'academie, l'absence de prix
et de promesses, et la regle « une regle n'est publiee dans un article que si le site la publie deja »."""
from __future__ import annotations

import importlib.util
import json
import re
import shutil
import sys
import unittest
from datetime import date
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
OUTPUT = SITE / "tests" / ".qa-articles"
ROUTES = ("/fr/articles/choisir-un-cours-de-coran-en-ligne", "/fr/articles/enfant-fatigue-assiduite")


def _charger(nom: str):
    spec = importlib.util.spec_from_file_location(nom, SITE / f"{nom}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[nom] = module
    spec.loader.exec_module(module)
    return module


BUILDER = _charger("build_site")
PAGES = json.loads((SITE / "content" / "pages.json").read_text(encoding="utf-8"))["pages"]


def texte(page: dict) -> str:
    morceaux = [page["title"], page["description"], page["h1"], page.get("intro", "")]
    for section in page["sections"]:
        morceaux += [section["title"], *section.get("paragraphs", []), *section.get("points", []),
                     *(lien["label"] for lien in section.get("links", []))]
    return "\n".join(morceaux)


class Contenu(unittest.TestCase):
    def test_chaque_article_est_date_indexable_et_pret(self) -> None:
        for route in ROUTES:
            with self.subTest(route=route):
                page = PAGES[route]
                date.fromisoformat(page["date"])
                self.assertTrue(page["indexable"])
                self.assertEqual(page["status"], "ready")
                self.assertLessEqual(len(page["description"]), 160)
                self.assertTrue(page["intro"])

    def test_vocabulaire_et_promesses(self) -> None:
        # mots-rewayah : jamais ces mots ; marque : jamais de promesse, de superlatif, de pays ou de continent.
        interdits = ("meilleur", "garanti", "certifié", "gratuit", "100 %", "devoirs", "groupe", "mode enfant", "échec",
                     "ce n’est pas grave", "ce n'est pas grave", "rattraper", "Occident", "Afrique", "Europe", "Amérique", "Asie")
        for route in ROUTES:
            brut = texte(PAGES[route])
            for mot in interdits:
                with self.subTest(route=route, mot=mot):
                    self.assertNotIn(mot.lower(), brut.lower())
            self.assertNotIn("—", brut)  # pas de tiret long
            self.assertIsNone(re.search(r"\d\s?(\$|€|£|USD|EUR)", brut), "aucun prix dans un article (source unique : DECISION-TARIFS)")

    def test_aucune_regle_de_l_academie_hors_du_site(self) -> None:
        # Les faits sur Rewayah d'un article viennent des pages deja publiees : l'absence et le rattrapage n'y sont pas.
        for route in ROUTES:
            brut = texte(PAGES[route]).lower()
            for mot in ("absence de l’élève", "manque une séance", "remboursé de l’absence"):
                self.assertNotIn(mot, brut, route)

    def test_sources_externes_seulement_des_doi(self) -> None:
        for route in ROUTES:
            for section in PAGES[route]["sections"]:
                for lien in section.get("links", []):
                    if lien["href"].startswith("https://"):
                        self.assertRegex(lien["href"], r"^https://doi\.org/10\.\d{4,}/\S+$", route)

    def test_l_article_sur_l_assiduite_cite_ses_deux_sources(self) -> None:
        liens = [l["href"] for s in PAGES[ROUTES[1]]["sections"] for l in s.get("links", [])]
        self.assertIn("https://doi.org/10.1037/0033-2909.132.3.354", liens)  # Cepeda et coll., 2006
        self.assertIn("https://doi.org/10.1177/1529100612453266", liens)    # Dunlosky et coll., 2013
        self.assertIn("pas sur le Coran", texte(PAGES[ROUTES[1]]))           # la limite est dite

    def test_le_hub_liste_les_deux_articles_et_n_annonce_plus_le_vide(self) -> None:
        hub = PAGES["/fr/articles"]
        self.assertTrue(hub["indexable"])
        liens = [l["href"] for s in hub["sections"] for l in s.get("links", [])]
        for route in ROUTES:
            self.assertIn(route, liens)
        self.assertNotIn("Aucun article", texte(hub))


class Page(unittest.TestCase):
    def construire(self, indexer: bool) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)
        BUILDER.build(OUTPUT, "https://rewayahacademy.com", indexer, env={}, today=date(2026, 11, 3))

    def tearDown(self) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)

    def lire(self, route: str) -> str:
        return (OUTPUT / f"{route.lstrip('/')}.html").read_text(encoding="utf-8")

    def test_balisage_article_auteur_academie_et_date(self) -> None:
        self.construire(True)
        for route in ROUTES:
            with self.subTest(route=route):
                html = self.lire(route)
                blocs = re.findall(r'<script type="application/ld\+json">(.*?)</script>', html)
                self.assertEqual(len(blocs), 1)
                graphe = json.loads(blocs[0])["@graph"]
                self.assertEqual([x["@type"] for x in graphe], ["BreadcrumbList", "Article"])
                article = graphe[1]
                self.assertEqual(article["datePublished"], PAGES[route]["date"])
                self.assertEqual(article["author"]["name"], "Rewayah Academy")  # aucune signature personnelle inventee
                self.assertEqual(len(graphe[0]["itemListElement"]), 3)
                self.assertIn('content="index,follow"', html)
                self.assertNotIn("AggregateRating", html)

    def test_plan_du_site_date_seulement_les_articles(self) -> None:
        self.construire(True)
        plan = (OUTPUT / "sitemap.xml").read_text(encoding="utf-8")
        for route in ROUTES:
            self.assertIn(f"<loc>https://rewayahacademy.com{route}</loc><lastmod>{PAGES[route]['date']}</lastmod>", plan)
        self.assertEqual(plan.count("<lastmod>"), 2)

    def test_apercu_hors_de_l_index(self) -> None:
        self.construire(False)
        for route in ROUTES:
            self.assertIn('content="noindex,nofollow"', self.lire(route))

    def test_mise_en_valeur_des_debuts_de_points(self) -> None:
        self.construire(True)
        html = self.lire(ROUTES[0])
        self.assertIn("<strong>Un enseignant attitré.</strong>", html.replace("\u00a0", " "))
        self.assertNotIn("**", html)

    def test_mise_en_valeur_non_fermee_arrete_le_build(self) -> None:
        with self.assertRaises(ValueError):
            BUILDER.texte_riche("**ouvert sans fin")
        self.assertEqual(BUILDER.texte_riche("**a** b"), "<strong>a</strong> b")


AUTRES_CHEMINS = "/fr/autres-chemins"
# Seuls sites cites, tous lus par l'agent le 03/11/2026. « le-coran.com » n'y est pas : le site a bloque la lecture
# automatique (403), donc rien n'est verifie ; il n'entre qu'apres une lecture par une personne.
SITES_VERIFIES = {"noorelbayanacademy.com", "quranweblearning.com", "institutalrayhan.com", "institut-assahaba.com", "houseofquran.com"}


class AutresChemins(unittest.TestCase):
    """Une page sur d'autres voies : exacte, sans classement ni prix, et jamais plus que ce qui a ete lu."""

    def liens_externes(self) -> list[str]:
        return [l["href"] for s in PAGES[AUTRES_CHEMINS]["sections"] for l in s.get("links", []) if l["href"].startswith("https://")]

    def test_seuls_les_sites_lus_sont_cites(self) -> None:
        from urllib.parse import urlparse
        self.assertEqual({urlparse(h).hostname for h in self.liens_externes()}, SITES_VERIFIES)
        self.assertNotIn("le-coran.com", json.dumps(PAGES[AUTRES_CHEMINS]))

    def test_aucun_classement_aucun_prix_aucune_promesse(self) -> None:
        brut = texte(PAGES[AUTRES_CHEMINS])
        for mot in ("meilleur", "garanti", "certifié", "gratuit", "Occident", "Afrique", "Europe", "Amérique", "Asie", "numéro un", "n°1", "n° 1", "classé"):
            self.assertNotIn(mot.lower(), brut.lower(), mot)
        self.assertNotIn("\u2014", brut)
        self.assertIsNone(re.search(r"\d\s?(\$|€|£|USD|EUR)", brut))

    def test_la_date_de_lecture_et_la_regle_sont_dites(self) -> None:
        brut = texte(PAGES[AUTRES_CHEMINS])
        self.assertIn("consulté le 3 novembre 2026", brut)
        self.assertIn("aucun classement", brut)
        self.assertIn("Nous ne demandons aucun lien en retour", brut)

    def test_ordre_alphabetique_dans_chaque_format(self) -> None:
        for section in PAGES[AUTRES_CHEMINS]["sections"]:
            noms = [re.match(r"\*\*(.+?)\.\*\*", p).group(1) for p in section.get("points", [])]
            self.assertEqual(noms, sorted(noms), section["id"])

    def test_le_presentiel_vient_en_premier(self) -> None:
        self.assertEqual(PAGES[AUTRES_CHEMINS]["sections"][0]["id"], "present-d-abord")
        self.assertIn("commencez par lui", PAGES[AUTRES_CHEMINS]["intro"])

    def test_la_page_est_indexable_et_reliee_depuis_le_hub_et_le_premier_article(self) -> None:
        self.assertTrue(PAGES[AUTRES_CHEMINS]["indexable"])
        for route in ("/fr/articles", ROUTES[0]):
            hrefs = [l["href"] for s in PAGES[route]["sections"] for l in s.get("links", [])]
            self.assertIn(AUTRES_CHEMINS, hrefs, route)


if __name__ == "__main__":
    unittest.main()
