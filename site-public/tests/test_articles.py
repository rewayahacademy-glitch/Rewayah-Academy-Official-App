"""Le hub d'articles (directeur, 03/11/2026) : quatre articles signes du directeur, relus par lui avant fusion.

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
ROUTES = ("/fr/articles/apprendre-le-coran-a-son-enfant", "/fr/articles/enfant-fatigue-assiduite",
          "/fr/articles/apprendre-le-coran-seul-sans-enseignant", "/fr/articles/apprendre-le-coran-en-groupe")
# Sources externes admises dans un article : references que l'on peut verifier (versets, hadiths, travaux, ouvrages).
HOTES_SOURCES = {"doi.org", "quran.com", "sunnah.com", "hadeethenc.com", "dorar.net", "fr.wikisource.org", "gallica.bnf.fr",
                 "archive.org", "shamela.ws", "arabiclexicon.hawramani.com", "pmc.ncbi.nlm.nih.gov"}


def _charger(nom: str):
    spec = importlib.util.spec_from_file_location(nom, SITE / f"{nom}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[nom] = module
    spec.loader.exec_module(module)
    return module


BUILDER = _charger("build_site")
PAGES = json.loads((SITE / "content" / "pages.json").read_text(encoding="utf-8"))["pages"]
# Le jour ou tous les articles sont parus : les tests du contenu publie se placent apres la derniere parution.
DERNIERE_PARUTION = max(date.fromisoformat(PAGES[r]["date"]) for r in ROUTES)


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
        # Directeur, 03/11/2026 : « groupe » (le pouvoir du groupe) et « Occident » sont demandes ; « meilleur » ne paraît que dans
        # la citation du hadith « Le meilleur d'entre vous est celui qui apprend le Coran et l'enseigne », jamais comme argument.
        interdits = ("meilleure académie", "le meilleur cours", "meilleur prix", "le meilleur choix", "garanti", "certifié",
                     "gratuit", "100 %", "devoirs", "mode enfant", "échec", "ce n’est pas grave", "ce n'est pas grave",
                     "rattraper", "Afrique", "Europe", "Amérique", "Asie")
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

    def test_sources_externes_seulement_des_references(self) -> None:
        from urllib.parse import urlparse
        for route in ROUTES:
            for section in PAGES[route]["sections"]:
                for lien in section.get("links", []):
                    if lien["href"].startswith("https://"):
                        self.assertIn(urlparse(lien["href"]).hostname, HOTES_SOURCES, (route, lien["href"]))

    def test_chaque_article_est_signe_du_directeur_et_cite_ses_sources(self) -> None:
        for route in ROUTES:
            with self.subTest(route=route):
                page = PAGES[route]
                self.assertEqual(page["auteur"]["nom"], "Abdoulaye Mouhidine Sow")
                self.assertEqual(page["sections"][-1]["id"], "sources")
                self.assertTrue(page["sections"][-1].get("links"), "la section Sources donne des liens")

    def test_aucun_autre_site_cite_dans_un_article(self) -> None:
        # Directeur, 03/11/2026 : les articles ne citent pas les autres sites ; ils renvoient a la page « Autres chemins ».
        from urllib.parse import urlparse
        for route in ROUTES:
            brut = json.dumps(PAGES[route], ensure_ascii=False)
            for hote in ("noorelbayanacademy", "quranweblearning", "institutalrayhan", "institut-assahaba", "houseofquran", "le-coran.com"):
                self.assertNotIn(hote, brut, route)

    def test_les_versets_sont_cites_avec_leur_traduction(self) -> None:
        for route in ROUTES:
            brut = texte(PAGES[route])
            for m in re.finditer(r"\(Coran (\d+:\d+(?:-\d+)?)", brut):
                self.assertIn("Hamidullah", brut[m.start():m.start() + 120], (route, m.group(1)))
            self.assertNotIn("⟦", brut, "aucun repere de citation non remplace")

    def test_l_article_sur_l_assiduite_cite_ses_deux_travaux(self) -> None:
        liens = [l["href"] for s in PAGES[ROUTES[1]]["sections"] for l in s.get("links", [])]
        self.assertIn("https://doi.org/10.1037/0033-2909.132.3.354", liens)  # Cepeda et coll., 2006
        self.assertIn("https://doi.org/10.1177/1529100612453266", liens)    # Dunlosky et coll., 2013
        # Directeur, 03/11/2026 : « ne portent pas sur le Coran » est technique, le public n'en a pas besoin.
        self.assertNotIn("pas sur le Coran", texte(PAGES[ROUTES[1]]))
        # Les sources ajoutees le meme soir : al-Ghazali (Ihya, Shamela), Ibn Khaldun (De Slane, p. 290), le sommeil (Paruthi 2016).
        for href in ("https://shamela.ws/book/9472/819", "https://archive.org/details/lesprolgomne03abdauoft/page/290/mode/1up",
                     "https://doi.org/10.5664/jcsm.5866"):
            self.assertIn(href, liens)
        self.assertIn("traduction du sens", texte(PAGES[ROUTES[1]]))  # al-Ghazali : aucune traduction francaise publiee

    def test_le_hub_genere_la_liste_et_n_annonce_plus_le_vide(self) -> None:
        hub = PAGES["/fr/articles"]
        self.assertTrue(hub["indexable"])
        self.assertIn("articles", [s.get("generated") for s in hub["sections"]])
        self.assertNotIn("Aucun article", texte(hub))


class Page(unittest.TestCase):
    def construire(self, indexer: bool) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)
        BUILDER.build(OUTPUT, "https://rewayahacademy.com", indexer, env={}, today=date(2026, 11, 3),
                      parution=DERNIERE_PARUTION)

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
                self.assertEqual(article["author"]["@type"], "Person")
                self.assertEqual(article["author"]["name"], "Abdoulaye Mouhidine Sow")
                self.assertEqual(article["publisher"]["name"], "Rewayah Academy")
                self.assertIn('class="article-signature"', html)
                self.assertEqual(len(graphe[0]["itemListElement"]), 3)
                self.assertIn('content="index,follow"', html)
                self.assertNotIn("AggregateRating", html)

    def test_plan_du_site_date_seulement_les_articles(self) -> None:
        self.construire(True)
        plan = (OUTPUT / "sitemap.xml").read_text(encoding="utf-8")
        for route in ROUTES:
            self.assertIn(f"<loc>https://rewayahacademy.com{route}</loc><lastmod>{PAGES[route]['date']}</lastmod>", plan)
        self.assertEqual(plan.count("<lastmod>"), len(ROUTES))

    def test_apercu_hors_de_l_index(self) -> None:
        self.construire(False)
        for route in ROUTES:
            self.assertIn('content="noindex,nofollow"', self.lire(route))

    def test_mise_en_valeur_des_debuts_de_points(self) -> None:
        self.construire(True)
        html = self.lire(ROUTES[0])
        self.assertNotIn("**", html)
        hub = (OUTPUT / "fr" / "articles.html").read_text(encoding="utf-8")
        self.assertEqual(hub.count('<li class="article-carte'), len(ROUTES))  # la liste du hub est generee, un article par carte

    def test_les_cartes_du_hub_sont_illustrees_et_disent_ou_cliquer(self) -> None:
        # Directeur, 03/11/2026 : « je ne vois pas ou cliquer » ; « couleurs et formes uniformes ». Le plus recent a la une ;
        # chaque carte a son illustration, un seul lien (le titre, etire sur la carte) et le bouton « Lire l'article ».
        self.construire(True)
        hub = (OUTPUT / "fr" / "articles.html").read_text(encoding="utf-8")
        cartes = re.findall(r'<li class="article-carte[^"]*">.*?</li>', hub, re.S)
        self.assertEqual(len(cartes), len(ROUTES))
        self.assertIn("article-carte--une", cartes[0])
        self.assertTrue(all("article-carte--une" not in c for c in cartes[1:]))
        for carte in cartes:
            self.assertIn('class="article-carte__visuel" aria-hidden="true"', carte)
            self.assertIn("Lire l’article", carte)
            self.assertEqual(len(re.findall(r"<a ", carte)), 1)
        self.assertIn('href="#catalogue"', hub)  # le bouton du haut de la page mene a la liste

    def test_mise_en_valeur_non_fermee_arrete_le_build(self) -> None:
        with self.assertRaises(ValueError):
            BUILDER.texte_riche("**ouvert sans fin")
        self.assertEqual(BUILDER.texte_riche("**a** b"), "<strong>a</strong> b")


ARABE = re.compile(r"[؀-ۿݐ-ݿࡰ-ࣿﭐ-﷿ﹰ-﻿]")


def par_date() -> list[str]:
    return sorted(ROUTES, key=lambda r: PAGES[r]["date"])


class Parution(unittest.TestCase):
    """Directeur, 03/11/2026 : « une publication automatique separee par 2 jours minimum ». Un article parait a sa date,
    a la premiere construction de production de ce jour-la ; avant, il n'existe pas en production."""

    def construire(self, indexer: bool, jour: date) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)
        BUILDER.build(OUTPUT, "https://rewayahacademy.com", indexer, env={}, today=date(2026, 11, 3), parution=jour)

    def tearDown(self) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)

    def html(self, route: str) -> str:
        return (OUTPUT / f"{route.lstrip('/')}.html").read_text(encoding="utf-8")

    def test_deux_jours_au_moins_entre_deux_parutions(self) -> None:
        jours = [date.fromisoformat(PAGES[r]["date"]) for r in par_date()]
        for avant, apres in zip(jours, jours[1:]):
            self.assertGreaterEqual((apres - avant).days, 2, (avant, apres))

    def test_la_production_ne_publie_que_les_articles_parus(self) -> None:
        ordre = par_date()
        jour = date.fromisoformat(PAGES[ordre[1]]["date"])
        self.construire(True, jour)
        parus, a_venir = ordre[:2], ordre[2:]
        for route in parus:
            self.assertIn('content="index,follow"', self.html(route))
        for route in a_venir:
            self.assertFalse((OUTPUT / f"{route.lstrip('/')}.html").exists(), route)
        plan = (OUTPUT / "sitemap.xml").read_text(encoding="utf-8")
        hub = self.html("/fr/articles")
        # La configuration d'aiguillage que le build ecrit dans sa sortie (lue ici, jamais ecrite).
        config = (OUTPUT / "vercel.json").read_text(encoding="utf-8")
        self.assertEqual(hub.count('<li class="article-carte'), len(parus))
        for route in a_venir:
            self.assertNotIn(route, plan)
            self.assertNotIn(route, config)
            # Aucun lien ne mene a un article qui n'est pas encore paru : ni depuis un autre article, ni depuis une autre page.
            for fichier in OUTPUT.rglob("*.html"):
                self.assertNotIn(f'href="{route}"', fichier.read_text(encoding="utf-8"), fichier.name)
        self.assertNotIn("À paraître", hub)

    def test_avant_la_premiere_parution_le_hub_reste_hors_de_l_index(self) -> None:
        premier = date.fromisoformat(PAGES[par_date()[0]]["date"])
        self.construire(True, date.fromordinal(premier.toordinal() - 1))
        hub = self.html("/fr/articles")
        self.assertIn("Aucun article n’est encore publié.", hub)
        self.assertIn('content="noindex,follow"', hub)
        self.assertNotIn("/fr/articles</loc>", (OUTPUT / "sitemap.xml").read_text(encoding="utf-8"))
        self.assertFalse((OUTPUT / "fr" / "articles").exists())

    def test_un_apercu_montre_les_articles_a_paraitre_pour_la_relecture(self) -> None:
        premier = date.fromisoformat(PAGES[par_date()[0]]["date"])
        self.construire(False, date.fromordinal(premier.toordinal() - 1))
        for route in ROUTES:
            html = self.html(route)
            self.assertIn("À paraître le ", html)
            self.assertIn('content="noindex,nofollow"', html)
        self.assertEqual(self.html("/fr/articles").count("À paraître le "), len(ROUTES))


def segments_du_mushaf() -> dict[str, str]:
    """Le texte de chaque verset dans les donnees du Mushaf de l'application (KFGQPC UthmanicHafs v3.0, signes de pause
    compris), tel que tool/generer_layout_madina_15.dart l'a ecrit : segments « sourate:verset:drapeaux:texte »."""
    dart = "".join(f.read_text(encoding="utf-8") for f in
                   sorted((SITE.parent / "lib" / "core" / "tc_coran" / "donnees").glob("layout_madina_15_p*.g.dart")))
    morceaux: dict[str, list[str]] = {}
    for sourate, verset, _drapeaux, texte_verset in re.findall(r"(\d+):(\d+):(\d):([^¦\\']*)", dart):
        morceaux.setdefault(f"{sourate}:{verset}", []).append(texte_verset)
    return {cle: " ".join(t) for cle, t in morceaux.items()}


class Arabe(unittest.TestCase):
    """Directeur, 03/11/2026 : « là on a besoin de l'arabe, donc il le faut ». Chaque verset et chaque hadith cite en francais
    est suivi de son texte arabe ; le Coran est celui du Mushaf de l'application, mot pour mot."""

    def blocs(self, route: str):
        for section in PAGES[route]["sections"]:
            for bloc in section.get("citations_arabes", []):
                yield section, bloc

    def test_chaque_citation_francaise_a_son_arabe_et_reciproquement(self) -> None:
        for route in ROUTES:
            for section in PAGES[route]["sections"]:
                if section["id"] == "sources":
                    continue
                for i, paragraphe in enumerate(section.get("paragraphs", [])):
                    blocs = [b for b in section.get("citations_arabes", []) if b["apres"] == i]
                    versets = re.findall(r"\(Coran (\d+:\d+(?:-\d+)?)", paragraphe)
                    hadiths = re.findall(r"\((rapporté par [^;)]+)", paragraphe)
                    with self.subTest(route=route, section=section["id"], paragraphe=i):
                        self.assertEqual([b["legende"].split(",")[0].removeprefix("Coran ") for b in blocs if b["genre"] == "coran"], versets)
                        self.assertEqual(len([b for b in blocs if b["genre"] == "hadith"]), len(hadiths))
                        for bloc in [b for b in blocs if b["genre"] == "hadith"]:
                            # Le numero de la legende arabe est l'un de ceux que le francais cite.
                            numero = re.search(r"n° (\d+(?: [a-z])?)", bloc["legende"]).group(1)
                            self.assertIn(f"n° {numero}", paragraphe)

    def test_les_versets_sont_ceux_du_mushaf_de_l_application(self) -> None:
        mushaf = segments_du_mushaf()
        self.assertEqual(len(mushaf), 6236)
        vus = 0
        for route in ROUTES:
            for _section, bloc in self.blocs(route):
                for verset in bloc.get("versets", []):
                    with self.subTest(route=route, verset=verset["cle"]):
                        self.assertEqual(verset["texte"], mushaf[verset["cle"]])
                        vus += 1
        self.assertGreaterEqual(vus, 17)

    def test_l_arabe_reste_dans_ses_blocs_et_le_francais_reste_francais(self) -> None:
        for route in ROUTES:
            with self.subTest(route=route):
                self.assertIsNone(ARABE.search(texte(PAGES[route])))
                for _section, bloc in self.blocs(route):
                    self.assertIsNone(ARABE.search(bloc["legende"]))

    def test_le_rendu_porte_la_langue_le_sens_et_la_rosace(self) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)
        try:
            BUILDER.build(OUTPUT, "https://rewayahacademy.com", False, env={}, today=date(2026, 11, 3))
            html = (OUTPUT / f"{ROUTES[0].lstrip('/')}.html").read_text(encoding="utf-8")
            self.assertIn('<figure class="citation-arabe citation-arabe--coran"><blockquote lang="ar" dir="rtl">', html)
            self.assertIn('<span class="rosace" aria-hidden="true">٥</span>', html)  # 96:5, en chiffres arabo-indiens
            self.assertIn('citation-arabe--hadith', html)
        finally:
            shutil.rmtree(OUTPUT, ignore_errors=True)

    def test_les_polices_du_complexe_du_roi_fahd_sont_copiees_telles_quelles(self) -> None:
        import hashlib
        shutil.rmtree(OUTPUT, ignore_errors=True)
        try:
            BUILDER.build(OUTPUT, "https://rewayahacademy.com", False, env={}, today=date(2026, 11, 3))
            for nom in BUILDER.POLICES_CITATIONS:
                with self.subTest(nom=nom):
                    self.assertEqual((OUTPUT / "fr" / "assets" / nom).read_bytes(), (BUILDER.POLICES_DEPOT / nom).read_bytes())
            # L'empreinte publiee par le paquet @quran.ws/text 0.1.0 pour UthmanicHafs-v-3.0.ttf (fichier du KFGQPC).
            self.assertEqual(hashlib.sha256((OUTPUT / "fr" / "assets" / "UthmanicHafs-v-3.0.ttf").read_bytes()).hexdigest(),
                             "5c47602425fb4190327ab9e1a2e8ed2f53dceaf595d8ccc29ac32b8b209ad398")
        finally:
            shutil.rmtree(OUTPUT, ignore_errors=True)

    def test_un_bloc_arabe_hors_d_un_article_arrete_le_build(self) -> None:
        with self.assertRaisesRegex(ValueError, "outside an article"):
            BUILDER.valider_citations_arabes("/fr/cours", {"paragraphs": ["x"], "citations_arabes": [
                {"apres": 0, "genre": "hadith", "texte": "خَيْرُكُمْ", "legende": "Texte arabe"}]})
        with self.assertRaisesRegex(ValueError, "not Arabic"):
            BUILDER.valider_citations_arabes(ROUTES[0], {"paragraphs": ["x"], "citations_arabes": [
                {"apres": 0, "genre": "hadith", "texte": "Le meilleur", "legende": "Texte arabe"}]})


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
