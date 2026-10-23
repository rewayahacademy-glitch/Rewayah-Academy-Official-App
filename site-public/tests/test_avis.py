"""Avis publics lus dans la base au build : validation, repli, HTML produit."""

from __future__ import annotations

import copy
import http.server
import importlib.util
import json
import re
import shutil
import sys
import threading
import unittest
from datetime import date
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
OUTPUT = SITE / "tests" / ".qa-avis"


def _charger(nom: str):
    spec = importlib.util.spec_from_file_location(nom, SITE / f"{nom}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[nom] = module
    spec.loader.exec_module(module)
    return module


BUILDER = _charger("build_site")
AVIS = BUILDER.avis_mod


def un_avis(**champs) -> dict:
    a = {"nom": "Salma B.", "qualite": "parent", "pays": "FR", "depuis": "2024-10-01", "note": 5,
         "titre": "Un suivi sérieux", "texte": "Ma fille progresse chaque semaine.\nMerci à l'équipe.",
         "publie_le": "2026-10-19T08:30:00+00:00"}
    a.update(champs)
    return a


def reponse(n: int = 1, **champs) -> dict:
    return {"nombre": n, "moyenne_dixiemes": 48, "avis": [un_avis(**champs)]}


class FauxServeur:
    def __init__(self, statut: int = 200, corps: object = None, redirige: bool = False) -> None:
        self.requetes: list[dict] = []
        outer = self

        class Gestionnaire(http.server.BaseHTTPRequestHandler):
            def do_POST(self) -> None:  # noqa: N802
                longueur = int(self.headers.get("Content-Length", "0"))
                outer.requetes.append({"chemin": self.path, "apikey": self.headers.get("apikey"),
                                       "corps": self.rfile.read(longueur)})
                if redirige:
                    self.send_response(302)
                    self.send_header("Location", "http://127.0.0.1:9/ailleurs")
                    self.end_headers()
                    return
                octets = corps if isinstance(corps, bytes) else json.dumps(corps).encode("utf-8")
                self.send_response(statut)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(octets)))
                self.end_headers()
                self.wfile.write(octets)

            def log_message(self, *args) -> None:
                return

        self.serveur = http.server.HTTPServer(("127.0.0.1", 0), Gestionnaire)
        self.fil = threading.Thread(target=self.serveur.serve_forever, daemon=True)

    def __enter__(self) -> "FauxServeur":
        self.fil.start()
        self.url = f"http://127.0.0.1:{self.serveur.server_address[1]}"
        return self

    def __exit__(self, *args) -> None:
        self.serveur.shutdown()
        self.serveur.server_close()


class Validation(unittest.TestCase):
    def test_formes_valides(self) -> None:
        AVIS.valider_avis({"nombre": 0, "moyenne_dixiemes": None, "avis": []})
        AVIS.valider_avis(reponse())
        AVIS.valider_avis(reponse(titre=None, qualite="eleve_adulte", pays="GN"))
        AVIS.valider_avis({"nombre": 500, "moyenne_dixiemes": 10, "avis": [un_avis()] * 200})

    def test_formes_refusees(self) -> None:
        mauvais = {
            "racine inconnue": {**reponse(), "x": 1},
            "racine incomplète": {"nombre": 0, "avis": []},
            "nombre booléen": {**reponse(), "nombre": True},
            "nombre négatif": {**reponse(), "nombre": -1},
            "moyenne trop basse": {**reponse(), "moyenne_dixiemes": 9},
            "moyenne trop haute": {**reponse(), "moyenne_dixiemes": 51},
            "moyenne décimale": {**reponse(), "moyenne_dixiemes": 4.8},
            "moyenne nulle avec avis": {**reponse(), "moyenne_dixiemes": None},
            "avis avec nombre 0": {"nombre": 0, "moyenne_dixiemes": None, "avis": [un_avis()]},
            "moyenne avec nombre 0": {"nombre": 0, "moyenne_dixiemes": 30, "avis": []},
            "trop d'avis": {"nombre": 300, "moyenne_dixiemes": 40, "avis": [un_avis()] * 201},
            "plus d'avis que nombre": {"nombre": 1, "moyenne_dixiemes": 40, "avis": [un_avis()] * 2},
            "avis pas une liste": {"nombre": 1, "moyenne_dixiemes": 40, "avis": {}},
            "clé en trop": reponse(courriel="a@b.c"),
            "qualité inconnue": reponse(qualite="enseignant"),
            "pays minuscule": reponse(pays="fr"),
            "pays trois lettres": reponse(pays="FRA"),
            "note 0": reponse(note=0),
            "note 6": reponse(note=6),
            "note texte": reponse(note="5"),
            "nom trop court": reponse(nom="A"),
            "nom trop long": reponse(nom="A" * 61),
            "titre trop long": reponse(titre="T" * 81),
            "texte trop court": reponse(texte="Trop court"),
            "texte trop long": reponse(texte="x" * 1501),
            "depuis pas le premier": reponse(depuis="2024-10-15"),
            "depuis avant 2015": reponse(depuis="2014-12-01"),
            "depuis invalide": reponse(depuis="2024-13-01"),
            "publie_le absent de forme": reponse(publie_le="hier"),
        }
        for nom, brut in mauvais.items():
            with self.subTest(nom), self.assertRaises(AVIS.AvisInvalides):
                AVIS.valider_avis(brut)
        manquante = reponse()
        del manquante["avis"][0]["note"]
        with self.assertRaises(AVIS.AvisInvalides):
            AVIS.valider_avis(manquante)

    def test_cle_dupliquee_refusee(self) -> None:
        corps = b'{"nombre":0,"nombre":0,"moyenne_dixiemes":null,"avis":[]}'
        with FauxServeur(corps=corps) as faux:
            with self.assertRaises(ValueError):
                AVIS.avis_depuis_base({"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "k"})

    def test_adresse_non_https_distante_refusee(self) -> None:
        with self.assertRaises(ValueError):
            AVIS.avis_depuis_base({"SUPABASE_URL": "http://exemple.org", "SUPABASE_PUBLISHABLE_KEY": "k"})

    def test_pays_couvrent_les_codes_courants(self) -> None:
        self.assertEqual(AVIS.PAYS["GN"], "Guinée")
        self.assertEqual(AVIS.PAYS["FR"], "France")
        self.assertGreaterEqual(len(AVIS.PAYS), 245)
        self.assertTrue(all(re.fullmatch(r"[A-Z]{2}", c) for c in AVIS.PAYS))


class Lecture(unittest.TestCase):
    def test_lecture_par_faux_serveur(self) -> None:
        with FauxServeur(corps=reponse()) as faux:
            avis, origine = AVIS.charger_avis(
                env={"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "cle-test"}, journal=lambda *_: None)
        self.assertEqual(origine, "base")
        self.assertEqual(faux.requetes[0]["chemin"], "/rest/v1/rpc/avis_publics")
        self.assertEqual(faux.requetes[0]["apikey"], "cle-test")
        self.assertEqual(faux.requetes[0]["corps"], b"{}")
        self.assertEqual(avis["avis"][0]["nom"], "Salma B.")

    def test_repli_sur_toute_erreur(self) -> None:
        cas = {
            "http 500": FauxServeur(statut=500, corps={"message": "boum"}),
            "json invalide": FauxServeur(corps=b"pas du json"),
            "forme invalide": FauxServeur(corps={"nombre": 3}),
            "redirection": FauxServeur(redirige=True),
        }
        for nom, faux in cas.items():
            with self.subTest(nom), faux:
                messages: list[str] = []
                avis, origine = AVIS.charger_avis(
                    env={"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "k"}, journal=messages.append)
                self.assertEqual(origine, "fichier")
                self.assertEqual(avis, {"nombre": 0, "moyenne_dixiemes": None, "avis": []})
                self.assertIn("repli", messages[0])
        messages = []
        _, origine = AVIS.charger_avis(env={}, journal=messages.append)
        self.assertEqual(origine, "fichier")
        self.assertIn("absentes", messages[0])

    def test_le_fichier_de_repli_est_vide(self) -> None:
        brut = json.loads((SITE / "content" / "avis.json").read_text(encoding="utf-8"))
        self.assertEqual(brut, {"nombre": 0, "moyenne_dixiemes": None, "avis": []})


class Rendu(unittest.TestCase):
    def test_moyenne(self) -> None:
        self.assertEqual(AVIS.fmt_resume({"nombre": 37, "moyenne_dixiemes": 48, "avis": []}), "4,8 sur 5, 37 avis")
        self.assertEqual(AVIS.fmt_resume({"nombre": 2, "moyenne_dixiemes": 50, "avis": []}), "5,0 sur 5, 2 avis")
        self.assertEqual(AVIS.fmt_resume({"nombre": 1, "moyenne_dixiemes": 10, "avis": []}), "1,0 sur 5, 1 avis")
        self.assertEqual(AVIS.fmt_resume({"nombre": 0, "moyenne_dixiemes": None, "avis": []}), "")

    def test_dates(self) -> None:
        self.assertEqual(AVIS.fmt_mois("2024-10-01"), "octobre 2024")
        self.assertEqual(AVIS.fmt_date("2026-10-01T08:30:00+00:00"), "1er octobre 2026")
        self.assertEqual(AVIS.fmt_date("2026-02-14T23:59:59Z"), "14 février 2026")

    def test_un_avis(self) -> None:
        corps = AVIS.rendre_avis_section("liste", {**reponse(), "nombre": 37})
        self.assertIn("4,8 sur 5, 37 avis", corps)
        self.assertIn("Salma B.", corps)
        self.assertIn("France", corps)
        self.assertIn("Parent d’élève", corps)
        self.assertIn("avec nous depuis octobre 2024", corps)
        self.assertIn("Publié le 19 octobre 2026", corps)
        self.assertIn('aria-label="5 sur 5">★★★★★<', corps)
        self.assertIn("chaque semaine.<br>Merci", corps)
        corps = AVIS.rendre_avis_section("liste", reponse(qualite="eleve_adulte", note=2, titre=None, pays="ZZ"))
        self.assertIn("Élève adulte", corps)
        self.assertIn('aria-label="2 sur 5">★★☆☆☆<', corps)
        self.assertNotIn("<h3>", corps)
        self.assertIn("ZZ", corps)

    def test_echappement(self) -> None:
        piege = '<script>alert(1)</script> "x" & <img src=x onerror=y>'
        brut = reponse(nom=piege[:60], titre=piege[:80], texte=piege * 2)
        corps = AVIS.rendre_avis_section("liste", brut)
        self.assertNotIn("<script>", corps)
        self.assertNotIn("<img", corps)
        self.assertIn("&lt;script&gt;", corps)
        self.assertIn("&quot;x&quot; &amp;", corps)

    def test_etat_vide_honnete(self) -> None:
        corps = AVIS.rendre_avis_section("liste", {"nombre": 0, "moyenne_dixiemes": None, "avis": []})
        self.assertIn("Les premiers avis seront publiés ici bientôt, après lecture par la direction", corps)
        self.assertNotIn("★", corps)
        self.assertNotIn("sur 5", corps)


class PageProduite(unittest.TestCase):
    def construire(self, avis: dict | None = None, env: dict | None = None) -> str:
        shutil.rmtree(OUTPUT, ignore_errors=True)
        BUILDER.build(OUTPUT, "https://rewayah-academy.vercel.app", False, env=env if env is not None else {},
                      today=date(2026, 10, 19), avis=avis)
        return (OUTPUT / "fr" / "avis.html").read_text(encoding="utf-8")

    def tearDown(self) -> None:
        shutil.rmtree(OUTPUT, ignore_errors=True)

    def test_page_vide_par_defaut(self) -> None:
        page = self.construire()
        self.assertIn("<h1>Avis des familles et des élèves</h1>", page.replace("\u00a0", " "))
        self.assertIn("Les premiers avis seront publiés ici bientôt", page)
        for mot in ('support<span class="arobase"></span>rewayahacademy.com', "insulte", "données personnelles d’un tiers", "publicité",
                    "hors sujet", "doublon", "jamais modifié", "avis négatifs"):
            self.assertIn(mot, page)
        self.assertIn('content="noindex,nofollow"', page)

    def test_pas_de_balisage_pour_moteurs(self) -> None:
        page = self.construire(avis=reponse())
        for interdit in ("schema.org", "AggregateRating", "ratingValue", "itemprop", "application/ld+json"):
            self.assertNotIn(interdit, page)

    def test_lien_dans_le_pied_de_page_et_route_declaree(self) -> None:
        page = self.construire()
        self.assertIn('href="/fr/avis"', page)
        accueil = (OUTPUT / "fr" / "index.html").read_text(encoding="utf-8")
        self.assertIn('href="/fr/avis"', accueil)
        self.assertIn("/fr/avis", json.dumps(json.loads((OUTPUT / "vercel.json").read_text(encoding="utf-8"))))

    def test_avis_lus_dans_la_base_sans_url_ni_cle_dans_le_html(self) -> None:
        brut = {**reponse(), "nombre": 37}
        with FauxServeur(corps=brut) as faux:
            env = {"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "cle-secrete-de-test"}
            self.construire(env=env)
            rendu = "\n".join(p.read_text(encoding="utf-8") for p in OUTPUT.rglob("*.html"))
        page = (OUTPUT / "fr" / "avis.html").read_text(encoding="utf-8")
        self.assertIn("4,8 sur 5, 37 avis", page)
        for interdit in (faux.url, "127.0.0.1", "cle-secrete-de-test", "apikey", "rpc/avis_publics", "SUPABASE_"):
            self.assertNotIn(interdit, rendu)
        self.assertIsNone(re.search(r"supabase\.co(?!m)", rendu))

    def test_texte_injecte_echappe_dans_la_page(self) -> None:
        page = self.construire(avis=reponse(nom="<b>Nom</b>", texte="<script>x()</script> et plus de vingt caractères"))
        self.assertNotIn("<script>x()", page)
        self.assertIn("&lt;b&gt;Nom&lt;/b&gt;", page)

    def test_mots_interdits_absents(self) -> None:
        page = self.construire()
        for interdit in ("avis vérifié", "certifié", "garanti"):
            self.assertNotIn(interdit, page.lower())


if __name__ == "__main__":
    unittest.main()
