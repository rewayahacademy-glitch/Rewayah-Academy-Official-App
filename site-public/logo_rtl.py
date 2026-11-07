"""Logo horizontal pour les pages de droite a gauche (directeur, 06/11/2026) : symbole a droite, nom a sa gauche.

Rien n'est redessine : les traces officiels (assets/brand/logo/) sont recopies mot pour mot ; le bloc du nom et le bloc
du symbole sont seulement deplaces (translate), meme ecart entre eux, meme viewBox. Relance : python3 logo_rtl.py."""
import re
from pathlib import Path

ICI = Path(__file__).resolve().parent
SYMBOLE = 2            # les deux premiers traces forment le symbole (x 0 a 290) ; les autres, le nom (x 347 a 1026)
NOM_X, ECART, SYMBOLE_L = 347, 57, 290


def version_rtl(svg: str) -> str:
    entete = svg[:svg.index(">") + 1]
    traces = re.findall(r"<path\b[^>]*/>", svg)
    if len(traces) != 34:
        raise ValueError("logo horizontal : 34 traces attendus")
    nom = "".join(traces[SYMBOLE:])
    symbole = "".join(traces[:SYMBOLE])
    decalage = 1026 - NOM_X + ECART
    return (f'{entete}<g transform="translate(-{NOM_X} 0)">{nom}</g>'
            f'<g transform="translate({decalage} 0)">{symbole}</g></svg>\n')


def main() -> None:
    for nom in ("logo-horizontal.svg", "logo-horizontal-ink.svg", "logo-horizontal-white.svg"):
        source = ICI / "assets" / nom
        (ICI / "assets" / nom.replace(".svg", "-rtl.svg")).write_text(version_rtl(source.read_text(encoding="utf-8")), encoding="utf-8")


if __name__ == "__main__":
    main()
