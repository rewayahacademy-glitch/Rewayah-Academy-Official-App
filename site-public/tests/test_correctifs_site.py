"""SITE-CORRECTIFS (22/11/2026) : arabe de droite a gauche, referencement arabe, racine, avis repliables."""
import importlib.util
import json
import os
import re
import sys
import tempfile
import unittest
import unittest.mock
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SITE))
SPEC = importlib.util.spec_from_file_location("langues", SITE / "langues.py")
L = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(L)
SPEC_B = importlib.util.spec_from_file_location("build_site_correctifs", SITE / "build_site.py")
B = importlib.util.module_from_spec(SPEC_B)
SPEC_B.loader.exec_module(B)
ORIGINE = "https://rewayahacademy.com"

_SORTIE: dict[str, Path] = {}


def sortie() -> Path:
    """Une seule construction complete (production, cinq langues) pour tous les tests de ce fichier."""
    if "dossier" not in _SORTIE:
        dossier = Path(tempfile.mkdtemp(prefix="site-correctifs-"))
        with unittest.mock.patch.dict(os.environ, {"RA_LANGUES": ""}):
            B.build(dossier, ORIGINE, True)
        _SORTIE["dossier"] = dossier
    return _SORTIE["dossier"]


def lire(chemin: str) -> str:
    return (sortie() / chemin).read_text(encoding="utf-8")


class RapportApresChaqueSeance(unittest.TestCase):
    def test_aucune_langue_ne_promet_un_rapport_de_fin_de_semaine(self) -> None:
        interdits = ("fin de semaine", "end of each week", "weekly report", "fin de semana", "informe semanal",
                     "fim de cada semana", "relatório semanal", "نهاية كل أسبوع", "آخر كلّ أسبوع")
        for fichier in sorted((SITE / "content").glob("*.json")) + [SITE / "build_site.py"]:
            texte = fichier.read_text(encoding="utf-8")
            for mot in interdits:
                self.assertNotIn(mot, texte, f"{fichier.name} : « {mot} »")


class ArabeDeDroiteAGauche(unittest.TestCase):
    def test_titres_descriptions_signature_et_cartes_des_articles_arabes_sont_rtl(self) -> None:
        liste = lire("ar/articles.html")
        for classe in ("article-carte__texte", "article-carte__meta", "articles__tete"):
            self.assertRegex(liste, rf'<(?:div|p) lang="ar" dir="rtl" class="{classe}"', classe)
        article = lire("ar/articles/enfant-fatigue-assiduite.html")
        for classe in ("entete-page__texte", "entete-page__suite", "article-signature"):
            self.assertRegex(article, rf'<(?:div|p) lang="ar" dir="rtl" class="{classe}', classe)

    def test_les_langues_de_gauche_a_droite_ne_changent_pas(self) -> None:
        for page in ("fr/articles.html", "en/articles.html", "es/articles.html", "pt/articles.html"):
            self.assertNotRegex(lire(page), r'dir="rtl" class="(article|entete|articles)', page)

    def test_la_feuille_de_style_pose_rtl_sur_l_entete_et_les_cartes(self) -> None:
        css = (SITE / "styles" / "site.css").read_text(encoding="utf-8")
        self.assertIn('[dir="rtl"] .entete-page__suite', css)
        self.assertIn('[dir="rtl"] :is(.articles__tete, .article-carte__texte', css)


class ReferencementArabe(unittest.TestCase):
    NOM = "أكاديمية الرواية"

    def test_chaque_page_arabe_porte_le_nom_arabe_dans_son_titre_et_sa_description(self) -> None:
        pages = sorted((sortie() / "ar").rglob("*.html"))
        self.assertGreaterEqual(len(pages), 20)
        for page in pages:
            h = page.read_text(encoding="utf-8")
            titre = re.search(r"<title>([^<]*)</title>", h).group(1)
            description = re.search(r'<meta name="description" content="([^"]*)"', h).group(1)
            self.assertIn(self.NOM, titre, page.name)
            self.assertIn(self.NOM, description, page.name)

    def test_le_partage_arabe_est_localise(self) -> None:
        h = lire("ar/index.html")
        self.assertIn(f'property="og:site_name" content="{self.NOM}"', h)
        self.assertIn('property="og:locale" content="ar_AR"', h)
        self.assertRegex(h, r'property="og:title" content="[^"]*' + self.NOM)
        self.assertIn('property="og:site_name" content="Rewayah Academy"', lire("fr/index.html"))

    def test_hreflang_des_cinq_langues_et_x_default_sur_chaque_page(self) -> None:
        for dossier in ("fr", "ar", "en", "es", "pt"):
            for page in sorted((sortie() / dossier).rglob("*.html")):
                h = page.read_text(encoding="utf-8")
                if "noindex" in h:   # pages utilitaires (désinscription) : hors des langues, jamais indexées
                    continue
                langues = set(re.findall(r'<link rel="alternate" hreflang="([\w-]+)"', h))
                self.assertEqual(langues, {"fr", "ar", "en", "es", "pt", "x-default"}, str(page))

    def test_le_plan_du_site_liste_toutes_les_langues(self) -> None:
        plan = lire("sitemap.xml")
        for langue in ("fr", "ar", "en", "es", "pt"):
            self.assertIn(f"<loc>{ORIGINE}/{langue}/</loc>", plan)
            self.assertIn(f"<loc>{ORIGINE}/{langue}/tarifs</loc>", plan)
            self.assertIn(f'hreflang="{langue}"', plan)
        self.assertIn('hreflang="x-default"', plan)

    def test_donnees_structurees_de_l_organisation(self) -> None:
        for dossier in ("fr", "ar"):
            blocs = re.findall(r'<script type="application/ld\+json">(.*?)</script>', lire(f"{dossier}/index.html"), re.S)
            graphe = [n for b in blocs for n in json.loads(b).get("@graph", [])]
            org = next(n for n in graphe if n["@type"] == "EducationalOrganization")
            self.assertEqual(org["name"], "Rewayah Academy")
            self.assertEqual(org["alternateName"], ["أكاديمية الرواية", "Académie Rewayah"])
            self.assertTrue(org["url"].startswith(ORIGINE))
            self.assertTrue(org["logo"].startswith(ORIGINE))
            site = next(n for n in graphe if n["@type"] == "WebSite")
            self.assertEqual(site["inLanguage"], dossier)


class RacineChoisitLaLangue(unittest.TestCase):
    def test_la_page_de_la_racine_redirige_d_apres_navigator_languages(self) -> None:
        h = lire("langue.html")
        script = re.search(r"<script>(.*?)</script>", h, re.S).group(1)
        self.assertIn("navigator.languages", script)
        self.assertIn("location.replace('/'+c+'/')", script)
        self.assertIn("c='fr'", script)   # toute autre langue : le francais
        self.assertIn('["fr", "ar", "en", "es", "pt"]', script)
        self.assertLess(h.index("<script>"), h.index("<body"))   # la redirection part avant le premier affichage

    def test_les_cinq_liens_sont_dans_le_html_sans_script(self) -> None:
        h = lire("langue.html")
        for langue in ("fr", "ar", "en", "es", "pt"):
            self.assertRegex(h, rf'<a class="choix-langue__lien" href="/{langue}/" hreflang="{langue}" lang="{langue}"')
        self.assertIn('hreflang="x-default" href="https://rewayahacademy.com/langue"', h)
        self.assertIn('<link rel="canonical" href="https://rewayahacademy.com/langue">', h)
        self.assertIn("html.auto .choix-langue { visibility: hidden; }", (SITE / "styles" / "site.css").read_text(encoding="utf-8"))

    def test_l_apercu_reste_noindex_et_la_production_comme_avant(self) -> None:
        self.assertIn('content="index,follow"', lire("langue.html"))
        with tempfile.TemporaryDirectory() as dossier, unittest.mock.patch.dict(os.environ, {"RA_LANGUES": ""}):
            B.build(Path(dossier), ORIGINE, False)
            self.assertIn('content="noindex,nofollow"', (Path(dossier) / "langue.html").read_text(encoding="utf-8"))

    def test_la_racine_mene_a_la_page_de_choix_dans_la_configuration_generee(self) -> None:
        config = json.loads(lire("vercel.json"))
        racine = [r for r in config["redirects"] if r["source"] == "/"]
        self.assertTrue(racine and all(r["destination"] == "/langue" for r in racine))


if __name__ == "__main__":
    unittest.main()
