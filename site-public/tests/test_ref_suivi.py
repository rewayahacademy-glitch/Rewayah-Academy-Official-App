"""REF-SUIVI (22/11/2026) : le script du site garde ?ref= et le porte sur les liens vers la connexion de l'application."""

from __future__ import annotations

import importlib.util
import json
import shutil
import subprocess
import unittest
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("rewayah_site_builder_ref", SITE / "build_site.py")
assert SPEC and SPEC.loader
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)

HARNAIS = """
const script = process.argv[1], search = process.argv[2], stock = JSON.parse(process.argv[3]), casse = process.argv[4] === '1';
const liens = ['/connexion', '/connexion?mode=creer', 'https://app.rewayahacademy.com/x', '/fr/tarifs', 'https://example.org/'].map((h) => ({ h, getAttribute() { return this.h; }, set href(v) { this.h = v; } }));
const mem = Object.assign({}, stock);
global.window = { localStorage: casse ? { getItem() { throw new Error('x'); }, setItem() { throw new Error('x'); } } : { getItem: (k) => (k in mem ? mem[k] : null), setItem: (k, v) => { mem[k] = v; } } };
global.location = new URL('https://rewayahacademy.com/en/familles' + search);
global.document = { addEventListener(_, f) { f(); }, querySelectorAll() { return { forEach: (f) => liens.forEach(f) }; } };
eval(script);
console.log(JSON.stringify({ liens: liens.map((l) => l.h), mem }));
"""


def jouer(search: str, stock: dict | None = None, casse: bool = False) -> dict:
    sortie = subprocess.run(["node", "-e", HARNAIS, MOD.SCRIPT_REF, search, json.dumps(stock or {}), "1" if casse else "0"],
                            check=True, capture_output=True, text=True).stdout
    return json.loads(sortie)


@unittest.skipUnless(shutil.which("node"), "node absent")
class RefSuivi(unittest.TestCase):
    def test_ref_garde_et_porte(self) -> None:
        r = jouer("?ref=chingford-londres")
        self.assertTrue(r["mem"]["rw_ref"].startswith("chingford-londres|"))
        self.assertEqual(r["liens"][0], "https://rewayahacademy.com/connexion?ref=chingford-londres")
        self.assertIn("mode=creer", r["liens"][1])
        self.assertIn("ref=chingford-londres", r["liens"][1])
        self.assertEqual(r["liens"][2], "https://app.rewayahacademy.com/x?ref=chingford-londres")
        self.assertEqual(r["liens"][3], "/fr/tarifs")
        self.assertEqual(r["liens"][4], "https://example.org/")

    def test_ref_invalide_ignore(self) -> None:
        for mauvais in ("?ref=Chingford", "?ref=a_b", "?ref=" + "a" * 49, "?ref="):
            r = jouer(mauvais)
            self.assertEqual(r["mem"], {})
            self.assertEqual(r["liens"][0], "/connexion")

    def test_valeur_gardee_sur_une_autre_page_et_premiere_gagne(self) -> None:
        r = jouer("", {"rw_ref": "mosquee-a|2026-11-20T10:00:00.000Z"})
        self.assertIn("ref=mosquee-a", r["liens"][0])
        r = jouer("?ref=mosquee-b", {"rw_ref": "mosquee-a|2999-01-01T00:00:00.000Z"})
        self.assertIn("ref=mosquee-a", r["liens"][0])

    def test_valeur_trop_vieille_remplacee(self) -> None:
        r = jouer("?ref=mosquee-b", {"rw_ref": "mosquee-a|2020-01-01T00:00:00.000Z"})
        self.assertIn("ref=mosquee-b", r["liens"][0])

    def test_stockage_refuse_ne_casse_rien(self) -> None:
        r = jouer("?ref=mosquee-b", casse=True)
        self.assertIn("ref=mosquee-b", r["liens"][0])

    def test_script_dans_chaque_page(self) -> None:
        self.assertIn("{SCRIPT_REF}", (SITE / "build_site.py").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
