"""Tarifs lus dans la base au build, et simulateur de prix.

Trois familles de controles :
- le module bloc_tarifs : validation stricte, lecture par un faux serveur, repli ;
- le HTML produit : prix, donnees injectees, aucune adresse ni cle ;
- le calcul JavaScript (node) compare au calcul de reference Python, cas par cas.
"""

from __future__ import annotations

import copy
import http.server
import importlib.util
import itertools
import json
import re
import shutil
import subprocess
import threading
import unittest
from datetime import date
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
OUTPUT = SITE / "tests" / ".qa-tarifs"


def _charger(nom: str):
    spec = importlib.util.spec_from_file_location(nom, SITE / f"{nom}.py")
    module = importlib.util.module_from_spec(spec)
    import sys
    sys.modules[nom] = module
    spec.loader.exec_module(module)
    return module


BUILDER = _charger("build_site")
TARIFS = BUILDER.tarifs_mod
NODE = shutil.which("node")
NBSP = " "


def politique_valide() -> dict:
    tarifs, _ = TARIFS.charger_tarifs(env={}, journal=lambda *_: None)
    return copy.deepcopy(tarifs["courante"])


def donnees() -> dict:
    tarifs, _ = TARIFS.charger_tarifs(env={}, journal=lambda *_: None)
    return TARIFS.donnees_simulateur_dict(tarifs)


def eleve(age: int, bourse: bool = False) -> dict:
    return {"age": age, "bourse": bourse}


class FauxServeur:
    """Un faux PostgREST local : rend ce qu'on lui demande, note la requete."""

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
                octets = (corps if isinstance(corps, bytes) else json.dumps(corps).encode("utf-8"))
                self.send_response(statut)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(octets)))
                self.end_headers()
                self.wfile.write(octets)

            def log_message(self, *args) -> None:  # silence
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


class ValidationStricte(unittest.TestCase):
    def test_la_reponse_valide_est_acceptee(self) -> None:
        brut = {"courante": politique_valide(), "suivante": None}
        self.assertEqual(TARIFS.valider_tarifs(brut)["courante"]["tarifEnfantMineur"], 5500)

    def test_cle_inconnue_refusee(self) -> None:
        p = politique_valide()
        p["margeEnseignant"] = 1
        with self.assertRaises(TARIFS.TarifsInvalides):
            TARIFS.valider_tarifs({"courante": p, "suivante": None})

    def test_types_et_bornes_refuses(self) -> None:
        for cle, valeur in (("tarifEnfantMineur", "55"), ("tarifEnfantMineur", 0), ("tarifAdulteMineur", True),
                            ("ageAdulte", 3), ("devise", "usd"), ("version", "<b>"), ("dateEffet", "2026-13-40"),
                            ("cumulMaxPourMille", 1001), ("horsTaxes", "oui")):
            with self.subTest(cle=cle, valeur=valeur):
                p = politique_valide()
                p[cle] = valeur
                with self.assertRaises(TARIFS.TarifsInvalides):
                    TARIFS.valider_tarifs({"courante": p, "suivante": None})

    def test_remises_foyer_mal_rangees_refusees(self) -> None:
        p = politique_valide()
        p["remisesFoyer"] = [{"aPartirDuRang": 3, "pourMille": 170}, {"aPartirDuRang": 2, "pourMille": 80}]
        with self.assertRaises(TARIFS.TarifsInvalides):
            TARIFS.valider_tarifs({"courante": p, "suivante": None})

    def test_suivante_doit_etre_posterieure(self) -> None:
        p = politique_valide()
        with self.assertRaises(TARIFS.TarifsInvalides):
            TARIFS.valider_tarifs({"courante": p, "suivante": copy.deepcopy(p)})

    def test_cle_dupliquee_dans_le_json_refusee(self) -> None:
        brut = b'{"courante":null,"courante":null,"suivante":null}'
        with FauxServeur(corps=brut) as faux:
            with self.assertRaises(TARIFS.TarifsInvalides):
                TARIFS.tarifs_depuis_base({"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "cle-test"})


class LectureDeLaBase(unittest.TestCase):
    def reponse_v2(self) -> dict:
        p = politique_valide()
        p["tarifEnfantMineur"] = 6000
        p["dateEffet"] = "2099-01-01"
        p["version"] = "v-futur"
        return {"courante": politique_valide(), "suivante": p}

    def test_lecture_par_faux_serveur_avec_la_cle_publiable(self) -> None:
        with FauxServeur(corps=self.reponse_v2()) as faux:
            tarifs, origine = TARIFS.charger_tarifs(
                env={"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "cle-test"}, journal=lambda *_: None)
        self.assertEqual(origine, "base")
        self.assertEqual(faux.requetes[0]["chemin"], "/rest/v1/rpc/tarifs_publics")
        self.assertEqual(faux.requetes[0]["apikey"], "cle-test")
        self.assertEqual(faux.requetes[0]["corps"], b"{}")
        self.assertEqual(TARIFS.politique_affichee(tarifs)["tarifEnfantMineur"], 6000)

    def test_les_prix_du_html_suivent_la_base_et_ni_url_ni_cle_ne_sortent(self) -> None:
        with FauxServeur(corps=self.reponse_v2()) as faux:
            env = {"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "cle-secrete-de-test"}
            sortie = SITE / "tests" / ".qa-base"
            BUILDER.build(sortie, "https://rewayah-academy.vercel.app", False, env=env, today=date(2026, 10, 19))
        rendu = "\n".join(p.read_text(encoding="utf-8") for p in sortie.rglob("*.html"))
        self.assertIn(f"60{NBSP}$", rendu)
        self.assertIn("à partir du 1er janvier 2099", rendu)
        for interdit in (faux.url, "127.0.0.1", "cle-secrete-de-test", "apikey", "rpc/tarifs_publics"):
            self.assertNotIn(interdit, rendu)
        self.assertIsNone(re.search(r"supabase\.co(?!m)", rendu))
        shutil.rmtree(sortie, ignore_errors=True)

    def test_repli_sur_erreur_http_json_invalide_redirection_et_variables_absentes(self) -> None:
        cas = {
            "http 500": FauxServeur(statut=500, corps={"message": "boum"}),
            "json invalide": FauxServeur(corps=b"pas du json"),
            "schema invalide": FauxServeur(corps={"courante": {"prix": 1}, "suivante": None}),
            "redirection": FauxServeur(redirige=True),
        }
        for nom, faux in cas.items():
            with self.subTest(nom), faux:
                messages: list[str] = []
                tarifs, origine = TARIFS.charger_tarifs(
                    env={"SUPABASE_URL": faux.url, "SUPABASE_PUBLISHABLE_KEY": "k"}, journal=messages.append)
                self.assertEqual(origine, "fichier")
                self.assertTrue(any("repli" in m for m in messages))
                self.assertEqual(tarifs["courante"]["tarifEnfantMineur"], 5500)
        messages = []
        _, origine = TARIFS.charger_tarifs(env={}, journal=messages.append)
        self.assertEqual(origine, "fichier")
        self.assertIn("absentes", messages[0])

    def test_adresse_non_https_distante_refusee(self) -> None:
        with self.assertRaises(ValueError):
            TARIFS.tarifs_depuis_base({"SUPABASE_URL": "http://exemple.org", "SUPABASE_PUBLISHABLE_KEY": "k"})

    def test_le_repli_donne_les_valeurs_en_vigueur(self) -> None:
        tarifs = TARIFS.tarifs_depuis_fichier()
        p = tarifs["courante"]
        self.assertEqual((p["tarifEnfantMineur"], p["tarifAdulteMineur"], p["ageAdulte"], p["horsTaxes"]),
                         (5500, 6500, 18, True))
        self.assertFalse(p["essaiActif"])
        self.assertEqual(p["remisesFoyer"], [{"aPartirDuRang": 2, "pourMille": 80},
                                             {"aPartirDuRang": 3, "pourMille": 170}])
        self.assertEqual(p["cumulMaxPourMille"], 250)

    def test_la_copie_du_repli_est_la_decision(self) -> None:
        decision = SITE.parent / "docs" / "current" / "tarifs-2026-10-18.json"
        if decision.exists():
            self.assertEqual(decision.read_bytes(), (SITE / "content" / "tarifs.json").read_bytes())

    def test_echappement_html_des_valeurs(self) -> None:
        self.assertEqual(TARIFS.esc("<script>"), "&lt;script&gt;")
        self.assertNotIn("<", TARIFS.donnees_simulateur(TARIFS.tarifs_depuis_fichier()))
        self.assertEqual(TARIFS.fmt_montant(10560, "USD"), f"105,60{NBSP}$")
        self.assertEqual(TARIFS.fmt_montant(5500, "USD"), f"55{NBSP}$")


class PageGeneree(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        BUILDER.build(OUTPUT, "https://rewayah-academy.vercel.app", False, env={}, today=date(2026, 10, 19))
        cls.tarifs_html = (OUTPUT / "fr" / "tarifs.html").read_text(encoding="utf-8")
        cls.accueil = (OUTPUT / "fr" / "index.html").read_text(encoding="utf-8")

    def test_la_page_tarifs_affiche_les_valeurs_en_vigueur(self) -> None:
        texte = re.sub(r"<[^>]+>", "|", self.tarifs_html)
        for attendu in (f"55{NBSP}$", f"65{NBSP}$", f"105,60{NBSP}$", f"151,25{NBSP}$", f"196,90{NBSP}$",
                        f"8{NBSP}%", f"17{NBSP}%", f"5{NBSP}%", f"10{NBSP}%", f"30{NBSP}%", f"25{NBSP}%",
                        f"20{NBSP}$", "6 à 17 ans", "18 ans et plus", "hors taxes",
                        "la première semaine est remboursée"):
            self.assertIn(attendu, texte)
        for caduc in ("Aucun montant n'est affiché", "Les deux premiers membres gardent leur tarif",
                      "momentanément indisponibles", "50 $", "60 $"):
            self.assertNotIn(caduc, self.tarifs_html)
        self.assertNotIn("—", self.tarifs_html)

    def test_l_accueil_lit_les_memes_donnees(self) -> None:
        self.assertIn(f"55{NBSP}$", self.accueil)
        self.assertIn("commencent au 2e membre", self.accueil)
        self.assertNotIn("Selon le tarif en vigueur", self.accueil)

    def test_les_donnees_injectees_sont_celles_du_calcul(self) -> None:
        for page in (self.tarifs_html, self.accueil):
            m = re.search(r'<script type="application/json" id="tarifs-data">(.*?)</script>', page, re.S)
            self.assertIsNotNone(m)
            self.assertEqual(json.loads(m.group(1)), donnees())

    def test_aucune_adresse_ni_cle_dans_le_html(self) -> None:
        rendu = "\n".join(p.read_text(encoding="utf-8") for p in OUTPUT.rglob("*") if p.suffix in {".html", ".js", ".css", ".json", ".xml", ".txt"})
        self.assertIsNone(re.search(r"supabase\.co(?!m)", rendu))
        for interdit in ("apikey", "service_role", "sb_publishable", "sb_secret", "SUPABASE_"):
            self.assertNotIn(interdit, rendu)
        self.assertIsNone(re.search(r"eyJ[A-Za-z0-9_-]{20,}", rendu))

    def test_accessibilite_et_repli_sans_javascript(self) -> None:
        self.assertIn('role="status" aria-live="polite"', self.tarifs_html)
        self.assertIn("<noscript>", self.tarifs_html)
        self.assertIn("Le simulateur demande JavaScript", self.tarifs_html)
        for identifiant in ("sim-total", "sim-paiement", "sim-parrainage", "sim-students", "sim-result"):
            self.assertIn(f'id="{identifiant}"', self.tarifs_html)
        for libelle in ("<label>Nombre d’élèves", "<label>Paiement", "<label>Parrainage"):
            self.assertIn(libelle, self.tarifs_html)

    def test_le_simulateur_n_a_aucun_nombre_de_tarif_en_dur(self) -> None:
        source = (SITE / "styles" / "site.js").read_text(encoding="utf-8")
        source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
        source = re.sub(r"//.*", "", source)
        for nombre in ("5500", "6500", "2000", "250", "170", "80", "55", "65", "18", "20", "30", "12", "1000", "100"):
            self.assertIsNone(re.search(rf"(?<![\w.]){nombre}(?![\w.])", source), nombre)

    def test_indexation_toujours_fermee(self) -> None:
        with self.assertRaisesRegex(ValueError, "preview-only"):
            BUILDER.build(OUTPUT, "https://rewayah-academy.vercel.app", True, env={})
        self.assertIn('content="noindex,nofollow"', self.tarifs_html)

    def test_pages_juridiques_sans_repere_a_completer(self) -> None:
        for route in ("legal/mentions", "legal/conditions", "legal/annulation-remboursement",
                      "legal/confidentialite", "legal/cookies", "protection-des-enfants"):
            texte = (OUTPUT / "fr" / f"{route}.html").read_text(encoding="utf-8")
            self.assertNotIn("à compléter", texte.replace(NBSP, " "))
            self.assertNotIn("Cette page est en préparation", texte)
        mentions = (OUTPUT / "fr" / "legal" / "mentions.html").read_text(encoding="utf-8")
        self.assertIn("Supabase Inc.", mentions)
        self.assertIn("Irlande", mentions)


# --- Calcul : reference Python et JavaScript --------------------------------

PAIEMENTS = ("mensuel", "trimestre", "annee")


def lancer_node(d: dict, cas: list[dict]) -> list[dict]:
    script = SITE / "tests" / "calcul_node.js"
    entree = json.dumps({"donnees": d, "cas": cas})
    sortie = subprocess.run([NODE, str(script)], input=entree, capture_output=True, text=True, timeout=60)
    if sortie.returncode != 0:
        raise AssertionError(sortie.stderr)
    return json.loads(sortie.stdout)


class CalculReference(unittest.TestCase):
    """Cas chiffres, a la main : 1 enfant, 1 adulte, 3 enfants, etc."""

    def calcul(self, eleves, paiement="mensuel", parrainage=False) -> dict:
        return TARIFS.calcul_reference(donnees(), eleves, paiement, parrainage)

    def test_un_enfant_un_adulte(self) -> None:
        self.assertEqual(self.calcul([eleve(9)])["totalPeriode"], 5500)
        self.assertEqual(self.calcul([eleve(17)])["totalPeriode"], 5500)
        self.assertEqual(self.calcul([eleve(18)])["totalPeriode"], 6500)
        self.assertEqual(self.calcul([eleve(40)])["totalPeriode"], 6500)

    def test_foyer(self) -> None:
        self.assertEqual(self.calcul([eleve(8)] * 2)["totalPeriode"], 10560)
        self.assertEqual(self.calcul([eleve(8)] * 3)["totalPeriode"], 15125)
        self.assertEqual(self.calcul([eleve(8)] * 4)["totalPeriode"], 19690)
        self.assertEqual(self.calcul([eleve(30)] * 2)["totalPeriode"], 12480)

    def test_prepaiement_seul_un_enfant(self) -> None:
        self.assertEqual(self.calcul([eleve(8)], "trimestre")["totalPeriode"], 15700)
        self.assertEqual(self.calcul([eleve(8)], "annee")["totalPeriode"], 59400)
        self.assertEqual(self.calcul([eleve(30)], "trimestre")["totalPeriode"], 18500)
        self.assertEqual(self.calcul([eleve(30)], "annee")["totalPeriode"], 70200)

    def test_foyer_et_annee_plafond_atteint(self) -> None:
        r = self.calcul([eleve(8)] * 3, "annee")
        self.assertEqual([l["total"] for l in r["lignes"]], [59400, 54100, 49500])
        # 3e : 17 % + 10 % = 27 % du prix, ramene a 25 % (1 320 centimes de moins).
        self.assertEqual(r["lignes"][2]["plafond"], 1320)
        self.assertEqual(r["lignes"][1]["plafond"], 0)
        self.assertEqual(r["totalPeriode"], 163000)

    def test_bourse_seule(self) -> None:
        r = self.calcul([eleve(8, True)])
        self.assertEqual(r["totalPeriode"], 3850)
        self.assertEqual(self.calcul([eleve(30, True)])["totalPeriode"], 4550)

    def test_bourse_non_cumulable(self) -> None:
        # Le 2e est boursier : 30 % et non 8 %, ni 30 % + 8 %.
        r = self.calcul([eleve(8), eleve(8, True)])
        self.assertEqual([l["total"] for l in r["lignes"]], [5500, 3850])
        self.assertEqual(r["lignes"][1]["foyer"], 0)
        # Pas de prepaiement ni de parrainage sur la bourse.
        r = self.calcul([eleve(8, True)], "annee", True)
        self.assertEqual(r["totalPeriode"], 3850 * 12)
        self.assertEqual(r["credit"], 0)

    def test_parrainage_et_plafond(self) -> None:
        # Un enfant : le credit de 20 $ est borne par la marge de 25 % (13,75 $).
        r = self.calcul([eleve(8)], "mensuel", True)
        self.assertEqual((r["credit"], r["totalPeriode"], r["totalSansCredit"]), (1375, 4125, 5500))
        # Trois enfants : la marge restante (27,50 $) laisse passer les 20 $.
        r = self.calcul([eleve(8)] * 3, "mensuel", True)
        self.assertEqual((r["credit"], r["totalPeriode"]), (2000, 13125))
        # Annee : 10 % utilises sur 25 %, le credit passe entier.
        r = self.calcul([eleve(8)], "annee", True)
        self.assertEqual((r["credit"], r["totalPeriode"]), (2000, 57400))

    def test_invariants(self) -> None:
        d = donnees()
        for n, paiement, parrainage in itertools.product(range(1, 6), PAIEMENTS, (False, True)):
            for ages in itertools.product((6, 17, 18, 60), repeat=min(n, 3)):
                eleves = [eleve(a) for a in (list(ages) + [10] * n)[:n]]
                r = TARIFS.calcul_reference(d, eleves, paiement, parrainage)
                base = sum(l["base"] for l in r["lignes"])
                self.assertLessEqual(r["totalPeriode"], base)
                # Foyer + prepaiement + parrainage : au plus 25 % du prix (l'arrondi au dollar peut
                # ajouter au plus un demi-dollar par eleve).
                remise = base - r["totalPeriode"]
                self.assertLessEqual(remise, base * 250 // 1000 + 50 * n)


@unittest.skipUnless(NODE, "node absent : le calcul JavaScript n'est pas compare")
class CalculJavaScript(unittest.TestCase):
    def cas_exhaustifs(self) -> list[dict]:
        cas = []
        ages = (6, 12, 17, 18, 45)
        for n in range(1, 5):
            for combinaison in itertools.product(ages, repeat=n) if n <= 3 else [(8, 8, 30, 12)]:
                for bourses in itertools.product((False, True), repeat=n) if n <= 2 else [(False,) * n, (False, True, False, True)[:n]]:
                    for paiement, parrainage in itertools.product(PAIEMENTS, (False, True)):
                        cas.append({"eleves": [eleve(a, b) for a, b in zip(combinaison, bourses)],
                                    "paiement": paiement, "parrainage": parrainage})
        return cas

    def test_le_javascript_donne_exactement_le_calcul_de_reference(self) -> None:
        d = donnees()
        cas = self.cas_exhaustifs()
        self.assertGreater(len(cas), 1000)
        resultats = lancer_node(d, cas)
        self.assertEqual(len(resultats), len(cas))
        for c, js in zip(cas, resultats):
            attendu = TARIFS.calcul_reference(d, c["eleves"], c["paiement"], c["parrainage"])
            self.assertEqual(js["totalPeriode"], attendu["totalPeriode"], c)
            self.assertEqual(js["totalSansCredit"], attendu["totalSansCredit"], c)
            self.assertEqual(js["credit"], attendu["credit"], c)
            self.assertEqual(js["mois"], attendu["mois"], c)
            self.assertEqual([l["total"] for l in js["lignes"]], [l["total"] for l in attendu["lignes"]], c)
            self.assertEqual([l["plafond"] for l in js["lignes"]], [l["plafond"] for l in attendu["lignes"]], c)
            for valeur in [js["totalPeriode"], js["parMois"], *[l["total"] for l in js["lignes"]]]:
                self.assertIsInstance(valeur, int)

    def test_les_montants_sont_formates_comme_le_serveur_les_ecrit(self) -> None:
        d = donnees()
        valeurs = [0, 5, 100, 5500, 10560, 15125, 1234567, 59400, -1375]
        sortie = lancer_node(d, [{"montant": v} for v in valeurs])
        for v, texte in zip(valeurs, sortie):
            self.assertEqual(texte["texte"], TARIFS.fmt_montant(v, d["devise"]).replace(" ", " "))

    def test_la_fourchette_est_le_min_et_le_max_de_tous_les_ordres(self) -> None:
        d = donnees()
        melanges = [[eleve(8), eleve(30)], [eleve(30), eleve(8), eleve(8)], [eleve(8), eleve(8), eleve(30), eleve(30)],
                    [eleve(30), eleve(30), eleve(9), eleve(9), eleve(9)]]
        cas = [{"fourchette": True, "eleves": e, "paiement": p, "parrainage": False}
               for e in melanges for p in PAIEMENTS]
        for c, js in zip(cas, lancer_node(d, cas)):
            totaux = [TARIFS.calcul_reference(d, list(ordre), c["paiement"], False)["totalPeriode"]
                      for ordre in set(itertools.permutations(tuple(tuple(x.items()) for x in c["eleves"])))
                      for ordre in [[dict(t) for t in ordre]]]
            self.assertEqual((js["min"], js["max"]), (min(totaux), max(totaux)), c)

    def test_exemple_de_la_decision_deux_adultes(self) -> None:
        d = donnees()
        js = lancer_node(d, [{"eleves": [eleve(30), eleve(30)], "paiement": "mensuel", "parrainage": False}])[0]
        self.assertEqual(js["totalPeriode"], 12480)


if __name__ == "__main__":
    unittest.main()
