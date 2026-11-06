"""SITE-LANGUES : la base technique du site en plusieurs langues (adresses, hreflang, selecteur, redirections)."""
import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SITE))
SPEC = importlib.util.spec_from_file_location("langues", SITE / "langues.py")
L = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(L)
SPEC_B = importlib.util.spec_from_file_location("build_site_langues", SITE / "build_site.py")
B = importlib.util.module_from_spec(SPEC_B)
SPEC_B.loader.exec_module(B)

ORIGINE = "https://rewayahacademy.com"


class Base(unittest.TestCase):
    def test_une_adresse_par_langue_et_chaque_langue_dans_son_ecriture(self) -> None:
        self.assertEqual(L.route_langue("/fr/tarifs", "ar"), "/ar/tarifs")
        self.assertEqual(L.route_langue("/fr/", "pt"), "/pt/")
        self.assertEqual(L.route_langue("/fr/legal/cookies", "fr"), "/fr/legal/cookies")
        self.assertEqual(L.NOMS, {"fr": "Français", "ar": "العربية", "en": "English", "es": "Español", "pt": "Português"})
        self.assertEqual(L.DIRECTION["ar"], "rtl")
        self.assertTrue(all(L.DIRECTION[l] == "ltr" for l in ("fr", "en", "es", "pt")))

    def test_le_selecteur_est_absent_tant_qu_une_seule_langue_est_en_ligne(self) -> None:
        self.assertEqual(L.selecteur("fr", "/fr/", ["fr"]), "")
        self.assertEqual(L.selecteur("fr", "/fr/", ["fr"], en_pied=True), "")
        self.assertEqual(L.alternates("/fr/", ["fr"], ORIGINE), "")

    def test_le_selecteur_est_fait_de_liens_sans_script(self) -> None:
        html = L.selecteur("fr", "/fr/tarifs", ["fr", "ar"])
        self.assertNotIn("<script", html)
        self.assertIn('href="/fr/tarifs" hreflang="fr" lang="fr" dir="ltr" aria-current="true"', html)
        self.assertIn('href="/ar/tarifs" hreflang="ar" lang="ar" dir="rtl"', html)
        self.assertIn(">العربية<", html)
        self.assertIn('aria-label="Choisir la langue"', html)
        pied = L.selecteur("ar", "/fr/tarifs", ["fr", "ar"], en_pied=True)
        self.assertIn('<a href="/ar/tarifs" hreflang="ar" lang="ar" aria-current="true">العربية</a>', pied)
        self.assertIn('<a href="/fr/tarifs" hreflang="fr" lang="fr">Français</a>', pied)

    def test_hreflang_reciproques_avec_x_default(self) -> None:
        dispo = ["fr", "ar", "en"]
        for langue in dispo:
            page = L.localiser('<html lang="fr"><head><title>t</title><meta property="og:locale" content="fr_FR"><meta property="og:title" content="t"></head><body></body></html>',
                               langue, "/fr/tarifs", ORIGINE, dispo)
            liens = dict(re.findall(r'<link rel="alternate" hreflang="([\w-]+)" href="([^"]+)">', page))
            self.assertEqual(liens, {"fr": ORIGINE + "/fr/tarifs", "ar": ORIGINE + "/ar/tarifs", "en": ORIGINE + "/en/tarifs", "x-default": ORIGINE + "/fr/tarifs"}, langue)
        plan = L.alternates_plan("/fr/", dispo, ORIGINE)
        self.assertIn('<xhtml:link rel="alternate" hreflang="ar" href="https://rewayahacademy.com/ar/"/>', plan)
        self.assertIn('hreflang="x-default" href="https://rewayahacademy.com/fr/"', plan)

    def test_une_page_arabe_porte_lang_dir_et_ses_propres_adresses(self) -> None:
        francais = ('<html lang="fr" data-x><head><link rel="canonical" href="https://rewayahacademy.com/fr/tarifs"><title>t</title>'
                    '<meta property="og:locale" content="fr_FR"><meta property="og:title" content="t"><link rel="stylesheet" href="/fr/assets/site.css"></head>'
                    '<body><a href="/fr/cours">c</a><a href="/connexion">x</a><img src="/fr/assets/a.webp"></body></html>')
        ar = L.localiser(francais, "ar", "/fr/tarifs", ORIGINE, ["fr", "ar"])
        self.assertIn('<html lang="ar" dir="rtl" data-x>', ar)
        self.assertIn('href="https://rewayahacademy.com/ar/tarifs"', ar.split("<title>")[0])
        self.assertIn('<a href="/ar/cours">', ar)
        self.assertIn('<a href="/connexion">', ar)                 # l'application n'a pas de langue dans l'adresse
        self.assertIn('href="/fr/assets/site.css"', ar)             # les fichiers du site sont communs a toutes les langues
        self.assertIn('src="/fr/assets/a.webp"', ar)
        self.assertIn('property="og:locale" content="ar_AR"', ar)

    def test_une_langue_n_existe_que_complete(self) -> None:
        pages_fr = {"/fr/": {"sections": [{"id": "a"}, {"id": "b"}]}, "/fr/aide": {"sections": [{"id": "c"}]}}
        import tempfile
        with tempfile.TemporaryDirectory() as dossier:
            ancien = B.langues_mod.ROOT
            B.langues_mod.ROOT = Path(dossier)
            (Path(dossier) / "content").mkdir()
            try:
                def ecrire(pages):
                    (Path(dossier) / "content" / "pages.ar.json").write_text(json.dumps({"pages": pages}), encoding="utf-8")
                ecrire({"/fr/": {"sections": [{"id": "a"}, {"id": "b"}]}})
                with self.assertRaisesRegex(ValueError, "pages non traduites"):
                    B.charger_pages_langue("ar", pages_fr)
                ecrire({"/fr/": {"sections": [{"id": "a"}]}, "/fr/aide": {"sections": [{"id": "c"}]}})
                with self.assertRaisesRegex(ValueError, "sections"):
                    B.charger_pages_langue("ar", pages_fr)
                ecrire({"/fr/": {"sections": [{"id": "a"}, {"id": "b"}]}, "/fr/aide": {"sections": [{"id": "c"}]}, "/fr/inconnue": {"sections": []}})
                with self.assertRaisesRegex(ValueError, "routes inconnues"):
                    B.charger_pages_langue("ar", pages_fr)
                ecrire({"/fr/": {"sections": [{"id": "a"}, {"id": "b"}]}, "/fr/aide": {"sections": [{"id": "c"}]}})
                self.assertEqual(list(B.charger_pages_langue("ar", pages_fr)), ["/fr/", "/fr/aide"])
            finally:
                B.langues_mod.ROOT = ancien

    def test_langue_pas_en_ligne_mene_au_francais_langue_en_ligne_est_servie_par_le_site(self) -> None:
        sans = B.aiguillage_domaine(("fr",))
        sources = {r["source"]: r["destination"] for r in sans}
        for l in ("ar", "en", "es", "pt"):
            self.assertEqual(sources[f"/{l}"], "/fr/")
            self.assertEqual(sources[f"/{l}/:path(.*)"], "/fr/:path")
        avec = B.aiguillage_domaine(("fr", "ar"))
        sources = {r["source"]: r["destination"] for r in avec}
        self.assertNotIn("/ar", sources)
        self.assertIn("/en", sources)
        route_app = next(r for r in avec if r["destination"].startswith("https://app."))
        self.assertIn("(?:fr|ar)", route_app["source"])
        self.assertNotIn("/connexion", route_app["source"])

    def test_le_site_en_francais_seul_ne_change_pas(self) -> None:
        # Une seule langue : aucune balise de langue, aucun selecteur, la meme page qu'avant.
        self.assertEqual(L.localiser("<html lang=\"fr\"><head></head></html>", "fr", "/fr/", ORIGINE, ["fr"]), "<html lang=\"fr\"><head></head></html>")


if __name__ == "__main__":
    unittest.main()
