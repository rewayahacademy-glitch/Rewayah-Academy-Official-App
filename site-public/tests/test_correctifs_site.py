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


class DefilementLegerDeLAccueil(unittest.TestCase):
    JS = (SITE / "styles" / "motion.js").read_text(encoding="utf-8")

    def test_les_illustrations_ne_s_attenuent_plus_seuls_les_titres_le_font(self) -> None:
        self.assertIn("contenu.querySelectorAll('h2').forEach", self.JS)
        self.assertNotIn("'h2, figure, .bande-image'", self.JS)

    def test_une_seule_boucle_par_image_et_les_elements_hors_ecran_ne_sont_pas_mesures(self) -> None:
        self.assertEqual(self.JS.count("window.addEventListener('scroll'"), 1)
        self.assertIn("{ passive: true }", self.JS)
        self.assertIn("new IntersectionObserver", self.JS)
        self.assertIn("function dansEcran", self.JS)
        self.assertIn("requestAnimationFrame(image)", self.JS)

    def test_aucune_lecture_de_position_dans_une_boucle_d_ecriture(self) -> None:
        # sceneParallaxes : toutes les ecritures sont rassemblees puis appliquees apres les lectures.
        corps = self.JS[self.JS.index("function sceneParallaxes"):self.JS.index("function enteteSuit")]
        derniere_lecture = corps.rindex("getBoundingClientRect")
        premiere_ecriture = corps.index("style.setProperty")
        self.assertLess(derniere_lecture, premiere_ecriture)

    def test_le_mouvement_reduit_arrete_les_scenes_et_les_images_sont_paresseuses(self) -> None:
        self.assertIn("if (reduit.matches) return;\n    scenePorte(h);", self.JS)
        h = lire("fr/index.html")
        images = re.findall(r"<img [^>]*>", h)
        for img in images:
            if "logo-horizontal" in img or "fetchpriority" in img or "scene-chemin" in img:
                continue
            self.assertIn('loading="lazy"', img)
            self.assertIn('width="', img)
            self.assertIn("srcset=", img)

    def test_pas_de_filtre_sur_les_illustrations_qui_s_attenuent(self) -> None:
        css = (SITE / "styles" / "site.css").read_text(encoding="utf-8")
        self.assertIn(".voyage-actif [data-attenue] { filter: opacity(var(--eclat, 1)); }", css)   # titres seulement, sans image
        accueil = lire("fr/index.html")
        for balise in re.findall(r"<(figure|div)[^>]*data-attenue[^>]*>", accueil):
            self.assertNotEqual(balise, "figure")
        self.assertEqual(re.findall(r"<figure[^>]*data-attenue", accueil), [])


class AvisRepliablesEtParPaquets(unittest.TestCase):
    JS = (SITE / "styles" / "avis-plus.js").read_text(encoding="utf-8")
    ATTENDUS = {
        "fr": ("Lire la suite", "Réduire", "Voir plus d’avis"),
        "ar": ("اقرأ المزيد", "عرض أقل", "عرض المزيد من الآراء"),
        "en": ("Read more", "Show less", "Show more reviews"),
        "es": ("Leer más", "Leer menos", "Ver más opiniones"),
        "pt": ("Ler mais", "Ler menos", "Ver mais opiniões"),
    }

    def test_les_boutons_sont_ecrits_dans_chaque_langue_de_la_page(self) -> None:
        for langue, (lire, reduire, plus) in self.ATTENDUS.items():
            h = lire_fichier(langue)
            balise = re.search(r'<script src="/fr/assets/avis-plus.js" defer ([^>]*)>', h)
            self.assertIsNotNone(balise, langue)
            self.assertIn(f'data-lire="{lire}"', balise.group(1), langue)
            self.assertIn(f'data-reduire="{reduire}"', balise.group(1), langue)
            self.assertIn(f'data-plus="{plus}"', balise.group(1), langue)
            self.assertLess(h.index("avis-plus.js"), h.index("<body"), langue)

    def test_le_script_est_accessible_et_agit_au_clavier(self) -> None:
        for marque in ("document.createElement('button')", "bouton.type = 'button'", "aria-expanded", "aria-controls",
                       "PAR_PAQUET = 6", "premier.focus(", "window.ameliorerAvis = ameliorer"):
            self.assertIn(marque, self.JS)
        self.assertNotIn("innerHTML", self.JS)   # aucun texte d'avis n'est jamais reecrit

    def test_le_repli_est_en_css_sur_l_attribut_pose_par_le_script_seulement(self) -> None:
        css = (SITE / "styles" / "site.css").read_text(encoding="utf-8")
        self.assertIn(".avis-texte[data-court] p { display: -webkit-box;", css)
        self.assertIn("-webkit-line-clamp: 4", css)
        self.assertIn(".avis-lire:focus-visible", css)
        self.assertNotIn("data-court", lire("fr/avis.html"))   # sans JavaScript, tout est entier

    def test_les_avis_remis_a_jour_en_direct_repassent_par_le_script(self) -> None:
        self.assertIn("window.ameliorerAvis()", (SITE / "styles" / "avis.js").read_text(encoding="utf-8"))

    def test_les_cinq_langues_ont_leurs_textes(self) -> None:
        sys.path.insert(0, str(SITE))
        spec = importlib.util.spec_from_file_location("bloc_avis_correctifs", SITE / "bloc_avis.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        self.assertEqual(set(mod.TEXTES_REPLI), {"fr", "ar", "en", "es", "pt"})
        for langue, (lire, reduire, plus) in self.ATTENDUS.items():
            self.assertEqual((mod.TEXTES_REPLI[langue]["lire"], mod.TEXTES_REPLI[langue]["reduire"], mod.TEXTES_REPLI[langue]["plus"]), (lire, reduire, plus))

    def test_avec_quatorze_avis_la_page_en_porte_quatorze_et_le_script_en_montre_six(self) -> None:
        # Le comportement dans un navigateur a ete verifie dans Chrome (6 visibles, puis 12, puis 14 ; avis longs repliés) ;
        # ici, la construction avec quatorze avis garde les quatorze dans le HTML (moteurs de recherche, sans script).
        avis = {"nombre": 14, "moyenne_dixiemes": 50, "avis": [
            {"nom": f"Famille {i}", "qualite": "parent", "pays": "FR", "depuis": "2026-09-01", "note": 5, "titre": f"Avis {i}",
             "texte": "Très bon cours, merci. " * (30 if i % 3 == 0 else 1), "publie_le": f"2026-11-{20 - i:02d}"} for i in range(14)]}
        spec = importlib.util.spec_from_file_location("bloc_avis_quatorze", SITE / "bloc_avis.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        html = mod.rendre_avis_section("liste", mod.valider_avis(avis))
        self.assertEqual(html.count('<article class="avis-carte">'), 14)
        self.assertNotRegex(html, r"\shidden[\s>]")


def lire_fichier(langue: str) -> str:
    return lire(f"{langue}/avis.html")


if __name__ == "__main__":
    unittest.main()
