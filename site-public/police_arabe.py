"""Refait la police arabe inscrite dans styles/site.css : Reem Kufi (assets/fonts du depot), une koufi d'ornement qui
place les voyelles (decision du directeur du 22/10/2026, registre de marque M-31), graisse 700 (des voyelles assez epaisses pour se voir), reduite aux lettres
arabes du contenu (content/pages.json et content/direction.json).

A relancer apres tout ajout de texte arabe, sinon ces lettres s'affichent dans une police du systeme.
Demande fontTools et brotli (pip install fonttools brotli) ; le build du site n'en a pas besoin.
Usage : python3 site-public/police_arabe.py"""
import base64
import io
import re
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SITE = Path(__file__).resolve().parent
SOURCE = SITE.parent / "assets" / "fonts" / "ReemKufi-Variable.ttf"
ARABE = r"[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]"


def main() -> None:
    contenu = "".join((SITE / "content" / f).read_text(encoding="utf-8") for f in ("pages.json", "direction.json"))
    lettres = "".join(sorted(set(re.findall(ARABE, contenu))))
    police = instancer.instantiateVariableFont(TTFont(SOURCE), {"wght": 700})
    options = subset.Options()
    options.layout_features = ["*"]  # formes initiales, medianes, finales et ligatures de l'arabe
    options.flavor = "woff2"
    options.notdef_outline = True
    reduction = subset.Subsetter(options)
    reduction.populate(text=lettres + " ")
    reduction.subset(police)
    tampon = io.BytesIO()
    police.flavor = "woff2"
    police.save(tampon)
    feuille = SITE / "styles" / "site.css"
    css, n = re.subn(r"(font-family: 'Reem Kufi';\s*src: url\('data:font/woff2;base64,)[A-Za-z0-9+/=]+('\))",
                     lambda m: m.group(1) + base64.b64encode(tampon.getvalue()).decode() + m.group(2),
                     feuille.read_text(encoding="utf-8"), count=1)
    if n != 1:
        raise SystemExit("La regle @font-face de Reem Kufi est introuvable dans styles/site.css")
    feuille.write_text(css, encoding="utf-8")
    print(f"{len(lettres)} lettres, {len(tampon.getvalue())} octets")


if __name__ == "__main__":
    main()
