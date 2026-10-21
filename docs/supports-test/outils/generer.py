#!/usr/bin/env python3
"""Genere les supports de test (PED-SUPPORTS) : Markdown -> HTML -> PDF et PNG.

ECHANTILLON DE TEST - a relire avant usage reel.

Usage, depuis la racine du depot :

    python3 docs/supports-test/outils/generer.py            # verifie puis rend
    python3 docs/supports-test/outils/generer.py --verifier # verifie seulement
    python3 docs/supports-test/outils/generer.py --remplir  # copie le texte
        coranique Tanzil a la place des marqueurs `ar: @TANZIL`, puis s'arrete

Le texte coranique n'est jamais retape : il est lu dans
supabase/migrations/0013_corpus_coranique.sql (Tanzil Uthmani 1.1). Toute ligne
`coran` dont l'arabe differe, meme d'un caractere, fait echouer le script.

Le rendu passe par Chromium (Playwright, deja installe :
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers ; aucun telechargement).
Sorties : docs/supports-test/rendu/<SUPPORT>.pdf et <SUPPORT>-p<N>.png.
Rien n'est televerse.
"""

from __future__ import annotations

import html
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ICI = Path(__file__).resolve().parent
DOSSIER = ICI.parent
RACINE = DOSSIER.parent.parent
CORPUS = RACINE / "supabase" / "migrations" / "0013_corpus_coranique.sql"
POLICES = RACINE / "assets" / "fonts"
RENDU = DOSSIER / "rendu"
SUPPORTS = ["S-ABL", "S-PRI", "S-LEC-1"]
AVERTISSEMENT = "ÉCHANTILLON DE TEST - à relire avant usage réel"
TYPES = {
    "titre", "consigne", "note", "parole", "geste", "coran",
    "illustration", "divergence", "lettre", "lettres",
}
CHAMPS = {"ar", "tr", "fr", "src", "statut", "ref", "lettre", "nom"}


class Erreur(Exception):
    pass


# ---------------------------------------------------------------- corpus

def lire_corpus() -> dict[tuple[int, int], str]:
    motif = re.compile(r"^\s*\((\d+), (\d+), '((?:[^']|'')*)', \d+\)[,;]?\s*$")
    versets: dict[tuple[int, int], str] = {}
    for ligne in CORPUS.read_text(encoding="utf-8").splitlines():
        m = motif.match(ligne)
        if m:
            versets[(int(m.group(1)), int(m.group(2)))] = m.group(3).replace("''", "'")
    if len(versets) != 6236:
        raise Erreur(f"corpus : {len(versets)} versets lus au lieu de 6236")
    return versets


def texte_attendu(ref: str, versets: dict[tuple[int, int], str]) -> str:
    m = re.fullmatch(r"(\d+):(\d+)(?: (sans basmala|mots (\d+)-(\d+)))?", ref)
    if not m:
        raise Erreur(f"ref illisible : {ref!r}")
    texte = versets[(int(m.group(1)), int(m.group(2)))]
    basmala = versets[(1, 1)]  # lue dans le corpus, jamais retapee
    if m.group(3) == "sans basmala":
        if not texte.startswith(basmala + " "):
            raise Erreur(f"{ref} : le verset ne commence pas par la basmala")
        texte = texte[len(basmala) + 1:]
    elif m.group(4):
        mots = texte.split(" ")
        texte = " ".join(mots[int(m.group(4)) - 1:int(m.group(5))])
    return texte


# ---------------------------------------------------------------- analyse

def analyser(support: str) -> dict:
    chemin = DOSSIER / f"{support}.md"
    texte = chemin.read_text(encoding="utf-8")
    if AVERTISSEMENT not in texte.split("\n## ")[0]:
        raise Erreur(f"{support} : avertissement absent de l'en-tete")
    titre = re.search(r"^# (.+)$", texte, re.M).group(1)
    pages: list[dict] = []
    ligne_cour = None
    for n, brut in enumerate(texte.splitlines(), 1):
        if m := re.match(r"^## p\.(\d+) - (.+)$", brut):
            num = int(m.group(1))
            if num != len(pages) + 1:
                raise Erreur(f"{support}:{n} : page {num} hors suite")
            pages.append({"num": num, "titre": m.group(2), "lignes": []})
            ligne_cour = None
        elif m := re.match(r"^### l\.(\d+) \| (\w+)$", brut):
            if not pages:
                raise Erreur(f"{support}:{n} : ligne avant la premiere page")
            lignes = pages[-1]["lignes"]
            num = int(m.group(1))
            if num != len(lignes) + 1:
                raise Erreur(f"{support}:{n} : ligne {num} hors suite")
            if m.group(2) not in TYPES:
                raise Erreur(f"{support}:{n} : type inconnu {m.group(2)!r}")
            ligne_cour = {"num": num, "type": m.group(2), "md": n}
            lignes.append(ligne_cour)
        elif ligne_cour is not None and (m := re.match(r"^(\w+): (.+)$", brut)):
            if m.group(1) not in CHAMPS:
                raise Erreur(f"{support}:{n} : champ inconnu {m.group(1)!r}")
            ligne_cour[m.group(1)] = m.group(2).strip()
        elif brut.startswith("#") and not (n == 1 and brut.startswith("# ")):
            raise Erreur(f"{support}:{n} : titre non reconnu {brut!r}")
    for p in pages:
        if p["lignes"][0]["type"] != "titre":
            raise Erreur(f"{support} p.{p['num']} : la ligne 1 doit etre le titre")
    return {"id": support, "titre": titre, "pages": pages}


def verifier(support: dict, versets) -> int:
    nb = 0
    for p in support["pages"]:
        for l in p["lignes"]:
            ident = f"{support['id']} / p.{p['num']} / l.{l['num']}"
            if l["type"] == "coran":
                if "ref" not in l or "ar" not in l:
                    raise Erreur(f"{ident} : coran sans ref ou sans ar")
                if l["ar"] == "@TANZIL":
                    raise Erreur(f"{ident} : marqueur @TANZIL non rempli (--remplir)")
                attendu = texte_attendu(l["ref"], versets)
                if l["ar"] != attendu:
                    raise Erreur(f"{ident} : texte coranique different de Tanzil {l['ref']}")
                nb += 1
            if l["type"] in {"parole", "coran"} and "src" not in l:
                raise Erreur(f"{ident} : parole sans source")
            if l["type"] in {"parole", "coran", "lettre"} and "ar" not in l:
                raise Erreur(f"{ident} : arabe absent")
            if l["type"] == "illustration" and not l.get("fr", "").startswith("[Illustration à venir : "):
                raise Erreur(f"{ident} : illustration mal formee")
            for champ in ("ar", "tr", "fr", "src"):
                if "—" in l.get(champ, "") or "§" in l.get(champ, ""):
                    raise Erreur(f"{ident} : tiret cadratin ou paragraphe interdit")
    return nb


def remplir(support_id: str, versets) -> int:
    chemin = DOSSIER / f"{support_id}.md"
    lignes = chemin.read_text(encoding="utf-8").split("\n")
    ref = None
    nb = 0
    for i, brut in enumerate(lignes):
        if brut.startswith("### "):
            ref = None
        elif brut.startswith("ref: "):
            ref = brut[5:].strip()
        elif brut == "ar: @TANZIL":
            lignes[i] = "ar: " + texte_attendu(ref, versets)
            nb += 1
    chemin.write_text("\n".join(lignes), encoding="utf-8")
    return nb


# ---------------------------------------------------------------- HTML

def e(s: str) -> str:
    return html.escape(s, quote=True)


LIBELLES = {
    "consigne": "Consigne", "note": "À savoir", "parole": "Parole",
    "geste": "Geste", "coran": "Coran", "illustration": "Illustration",
    "divergence": "Divergence", "lettre": "Lettre", "lettres": "Lecture",
}

CSS = """
@font-face { font-family: 'Hafs'; src: url('%(polices)s/UthmanicHafs-v-3.0.ttf'); }
@font-face { font-family: 'Naskh'; src: url('%(polices)s/UthmanTahaNaskh-Regular.otf'); }
@font-face { font-family: 'DM'; src: url('%(polices)s/DMSans-Variable.ttf'); font-weight: 100 1000; }
@page { size: A4; margin: 0; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: #ffffff; }
body { font-family: 'DM', sans-serif; color: #1f2a27; font-size: 10.5pt; line-height: 1.35; }
.page { width: 210mm; height: 297mm; padding: 12mm 13mm 11mm; position: relative;
        overflow: hidden; page-break-after: always; break-after: page;
        display: flex; flex-direction: column; }
.page:last-child { page-break-after: auto; break-after: auto; }
.tete { display: flex; justify-content: space-between; align-items: baseline;
        border-bottom: 1.5pt solid #1d5c4d; padding-bottom: 2mm; margin-bottom: 3mm; }
.tete .sup { font-weight: 700; color: #1d5c4d; font-size: 10pt; }
.tete .avert { white-space: nowrap; font-weight: 700; color: #a3361f; font-size: 9pt; letter-spacing: .02em; }
.lignes { flex: 1; }
.l { display: grid; grid-template-columns: 27mm 1fr; column-gap: 3mm;
     padding: 1.3mm 0; border-bottom: .5pt solid #dfe6e3; }
.id { font-family: 'DM', monospace; font-size: 7.6pt; color: #4d5d58; font-weight: 600;
      padding-top: 1mm; white-space: nowrap; }
.contenu > * + * { margin-top: .8mm; }
.titre .contenu { font-size: 15pt; font-weight: 750; color: #133f35; }
.etiquette { display: inline-block; font-size: 7pt; font-weight: 700; text-transform: uppercase;
             letter-spacing: .04em; padding: .2mm 1.6mm; border-radius: 2mm;
             background: #e8f0ed; color: #1d5c4d; }
.etiqs { margin-top: 1.2mm; display: flex; flex-direction: column; align-items: flex-start;
         gap: .8mm; white-space: normal; }
.etiqs .ref { font-size: 6.8pt; }
.lec .etiqs { display: none; }
.etiquette.obligatoire { background: #1d5c4d; color: #ffffff; }
.etiquette.sunna { background: #f1ead7; color: #6b5313; }
.etiquette.divergence { background: #f6e3dc; color: #8a2f1b; }
.ar { direction: rtl; text-align: right; font-family: 'Naskh', serif; font-size: 18pt;
      line-height: 1.6; color: #10211c; }
.coran .ar { font-family: 'Hafs', serif; font-size: 20pt; line-height: 1.6; }
.coran .ar.naskh { font-family: 'Naskh', serif; }
.ref { font-size: 7.5pt; color: #1d5c4d; font-weight: 700; }
.tr { font-style: italic; color: #33433e; }
.src { font-size: 8pt; color: #5b6964; }
.src::before { content: 'Source : '; font-weight: 700; }
.divergence .contenu .fr { font-size: 9pt; color: #5c2a1d; }
.illustration .fr { border: 1pt dashed #9fb3ac; padding: 1.2mm 2mm; color: #4d5d58;
                    font-size: 9pt; border-radius: 1.5mm; }
.pied { display: flex; justify-content: space-between; font-size: 7.5pt; color: #5b6964;
        border-top: .5pt solid #c9d5d1; padding-top: 1.6mm; margin-top: 2mm; gap: 4mm; }
.lec .ar { font-size: 27pt; line-height: 1.4; }
.lec .lettres .ar, .lec .lettre .ar { word-spacing: 5mm; }
.lec .l { padding: .4mm 0; }
.lec .titre .contenu { font-size: 14pt; }
.carte { display: grid; grid-template-columns: 1fr auto 17mm; align-items: center; gap: 4mm; }
.carte.deux { grid-template-columns: 1fr auto; }
.carte .grande { font-family: 'Naskh', serif; font-size: 30pt; line-height: 1.3; direction: rtl;
                 text-align: center; background: #f3f7f5; border-radius: 2mm; }
.carte .nom { font-weight: 700; color: #133f35; font-size: 11pt; }
.carte .aide { font-size: 8.5pt; color: #4d5d58; }
.carte .info > * + * { margin-top: .5mm; }
"""


def rendre_ligne(sup: dict, page: dict, l: dict) -> str:
    ident = f"{sup['id']} / p.{page['num']} / l.{l['num']}"
    t = l["type"]
    morceaux: list[str] = []
    gauche_etiq = ""
    if t == "titre":
        morceaux.append(e(l["fr"]))
    elif t == "lettre":
        info = [f'<div class="nom">{e(l["nom"])}</div>']
        if "tr" in l:
            info.append(f'<div class="tr">{e(l["tr"])}</div>')
        if "fr" in l:
            info.append(f'<div class="aide">{e(l["fr"])}</div>')
        morceaux.append('<div class="carte">'
                        f'<div class="info">{"".join(info)}</div>'
                        f'<div class="ar" lang="ar">{e(l["ar"])}</div>'
                        f'<div class="grande" lang="ar">{e(l["lettre"])}</div></div>')
    elif t == "lettres":
        info = []
        if "tr" in l:
            info.append(f'<div class="tr">{e(l["tr"])}</div>')
        if "fr" in l:
            info.append(f'<div class="aide">{e(l["fr"])}</div>')
        morceaux.append('<div class="carte deux">'
                        f'<div class="info">{"".join(info)}</div>'
                        f'<div class="ar" lang="ar">{e(l["ar"])}</div></div>')
    else:
        etiq = f'<span class="etiquette{" divergence" if t == "divergence" else ""}">{LIBELLES[t]}</span>'
        if "statut" in l:
            etiq += f'<span class="etiquette {e(l["statut"])}">{e(l["statut"])}</span>'
        if t == "coran":
            etiq += f'<span class="ref">Texte Tanzil {e(l["ref"])}</span>'
        if t != "illustration":
            gauche_etiq = etiq
        if "ar" in l:
            # UthmanicHafs v3 n'a pas de dessin pour U+06DF (petit zero haut
            # arrondi du texte Tanzil) : il afficherait un cercle pointille.
            # Ces lignes passent en Uthman Taha Naskh, qui le dessine. Le texte
            # n'est pas touche, seule la police change.
            classe = " naskh" if t == "coran" and "\u06df" in l["ar"] else ""
            morceaux.append(f'<div class="ar{classe}" lang="ar">{e(l["ar"])}</div>')
        if "tr" in l:
            morceaux.append(f'<div class="tr">{e(l["tr"])}</div>')
        if "fr" in l:
            morceaux.append(f'<div class="fr">{e(l["fr"])}</div>')
        if "src" in l:
            morceaux.append(f'<div class="src">{e(l["src"])}</div>')
    return (f'<div class="l {t}" data-id="{e(ident)}"><div class="id">{e(ident)}'
            f'<div class="etiqs">{gauche_etiq}</div></div>'
            f'<div class="contenu">{"".join(morceaux)}</div></div>')


def rendre_html(sup: dict) -> str:
    total = len(sup["pages"])
    corps = []
    for p in sup["pages"]:
        coran = any(l["type"] == "coran" for l in p["lignes"])
        pied_g = (f"Texte coranique : Tanzil Quran Text (Uthmani 1.1), CC BY 3.0, tanzil.net"
                  if coran else "Rewayah Academy - support de test")
        corps.append(
            f'<section class="page" id="p{p["num"]}">'
            f'<div class="tete"><span class="sup">{e(sup["titre"])}</span>'
            f'<span class="avert">{e(AVERTISSEMENT)}</span></div>'
            f'<div class="lignes">{"".join(rendre_ligne(sup, p, l) for l in p["lignes"])}</div>'
            f'<div class="pied"><span>{e(pied_g)}</span>'
            f'<span>{e(sup["id"])} / p.{p["num"]} - page {p["num"]} sur {total}</span></div>'
            f'</section>')
    classe = "lec" if sup["id"].startswith("S-LEC") else ""
    return (f'<!doctype html><html lang="fr"><head><meta charset="utf-8">'
            f'<title>{e(sup["id"])}</title><style>{CSS % {"polices": POLICES.as_uri()}}</style>'
            f'</head><body class="{classe}">{"".join(corps)}</body></html>')


# ---------------------------------------------------------------- main

def main() -> int:
    versets = lire_corpus()
    if "--remplir" in sys.argv:
        for s in SUPPORTS:
            print(f"{s} : {remplir(s, versets)} ligne(s) coranique(s) copiee(s) depuis Tanzil")
        return 0
    supports = [analyser(s) for s in SUPPORTS]
    for sup in supports:
        nb_l = sum(len(p["lignes"]) for p in sup["pages"])
        nb_c = verifier(sup, versets)
        print(f"{sup['id']} : {len(sup['pages'])} page(s), {nb_l} lignes, "
              f"{nb_c} ligne(s) coranique(s) identiques a Tanzil")
    if "--verifier" in sys.argv:
        return 0
    RENDU.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        travaux = []
        for sup in supports:
            h = Path(tmp) / f"{sup['id']}.html"
            h.write_text(rendre_html(sup), encoding="utf-8")
            travaux.append({"id": sup["id"], "html": str(h), "pages": len(sup["pages"]),
                            "sortie": str(RENDU)})
        env = dict(os.environ)
        env.setdefault("PLAYWRIGHT_BROWSERS_PATH", "/opt/pw-browsers")
        env.setdefault("NODE_PATH", "/opt/node22/lib/node_modules")
        subprocess.run(["node", str(ICI / "rendre.cjs"), json.dumps(travaux)],
                       check=True, env=env)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Erreur as err:
        print(f"ERREUR : {err}", file=sys.stderr)
        sys.exit(1)
