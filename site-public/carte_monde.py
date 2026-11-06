"""Carte du monde en points pour le pied de page du site public (directeur, 03/11/2026).

Ce que fait ce script : il lit les polygones des terres de Natural Earth (domaine public, echelle 1:110 millions,
`ne_110m_land.geojson`) et ecrit `assets/carte-monde-points.svg`, une carte faite de points, sans aucune frontiere et
sans aucun nom. Choix volontaire : une carte de frontieres oblige a trancher des litiges (Sahara occidental, Palestine,
Cachemire, Crimee...), et la marque n'ecrit jamais le nom d'un pays ou d'un continent. Des points posent seulement
la silhouette des terres : la diaspora est partout, sans que le site dise ou.

Le SVG est un masque : sa couleur n'a pas d'importance, c'est le CSS qui le peint avec un jeton de la feuille
(`.pied-carte__points`). Aucune couleur en dur n'entre donc dans le fichier.

Usage (les donnees telechargees sont lues comme des donnees, jamais executees) :

    python3 -I site-public/carte_monde.py chemin/vers/ne_110m_land.geojson

Source des donnees : https://github.com/nvkelso/natural-earth-vector (geojson/ne_110m_land.geojson).
Natural Earth : « Made with Natural Earth. Free vector and raster map data @ naturalearthdata.com. » Domaine public.
Aucune dependance hors bibliotheque standard. Le build du site ne lit jamais ce script : il copie le SVG genere.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SORTIE = ROOT / "assets" / "carte-monde-points.svg"

COLONNES = 170                 # nombre de points d'un bord a l'autre : la finesse de la carte
LAT_NORD, LAT_SUD = 83.0, -57.0  # l'Antarctique est laissee de cote : des points polaires n'apprennent rien ici
RAYON = 0.36                   # rayon d'un point, en unites de grille (le pas vaut 1)


def miller(latitude: float) -> float:
    """Projection de Miller : le monde a l'endroit, sans l'etirement des poles de Mercator."""
    return 1.25 * math.log(math.tan(math.pi / 4 + 0.4 * math.radians(latitude)))


def miller_inverse(y: float) -> float:
    """Latitude (degres) d'une ordonnee de Miller : l'inverse exact de miller()."""
    return math.degrees((math.atan(math.exp(y / 1.25)) - math.pi / 4) / 0.4)


def dans_anneau(x: float, y: float, anneau: list[list[float]]) -> bool:
    """Tir de rayon : le point est-il dans cet anneau ?"""
    dedans = False
    j = len(anneau) - 1
    for i in range(len(anneau)):
        xi, yi = anneau[i][0], anneau[i][1]
        xj, yj = anneau[j][0], anneau[j][1]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            dedans = not dedans
        j = i
    return dedans


def dans_polygone(x: float, y: float, anneaux: list[list[list[float]]]) -> bool:
    """Le premier anneau est le contour, les suivants des trous (lacs interieurs)."""
    if not dans_anneau(x, y, anneaux[0]):
        return False
    return not any(dans_anneau(x, y, trou) for trou in anneaux[1:])


def polygones(geojson: dict) -> list[list[list[list[float]]]]:
    resultat = []
    for objet in geojson["features"]:
        g = objet["geometry"]
        if g["type"] == "Polygon":
            resultat.append(g["coordinates"])
        elif g["type"] == "MultiPolygon":
            resultat.extend(g["coordinates"])
    return resultat


def points(geojson: dict) -> tuple[list[tuple[int, int]], int, int]:
    """Les points de la grille qui tombent sur une terre, et la taille de la grille."""
    terres = polygones(geojson)
    boites = [(min(p[0] for p in a[0]), max(p[0] for p in a[0]), min(p[1] for p in a[0]), max(p[1] for p in a[0])) for a in terres]
    haut, bas = miller(LAT_NORD), miller(LAT_SUD)
    pas_x = 360.0 / COLONNES                    # pas en longitude, en degres
    # Le pas vertical vaut le pas horizontal dans la carte projetee : les points sont a egale distance partout.
    unite = 2 * math.pi / COLONNES              # un pas de grille, exprime dans l'unite de miller() (radians)
    lignes = int(round((haut - bas) / unite))
    retenus = []
    for r in range(lignes):
        y = haut - (r + 0.5) * unite
        latitude = miller_inverse(y)
        for c in range(COLONNES):
            longitude = -180.0 + (c + 0.5) * pas_x
            for (x0, x1, y0, y1), anneaux in zip(boites, terres):
                if x0 <= longitude <= x1 and y0 <= latitude <= y1 and dans_polygone(longitude, latitude, anneaux):
                    retenus.append((c, r))
                    break
    return retenus, COLONNES, lignes


def svg(retenus: list[tuple[int, int]], colonnes: int, lignes: int) -> str:
    # Un seul <path> : chaque point est un segment de longueur nulle au bout rond (« M x y h0 »).
    trace = "".join(f"M{c} {r}h0" for c, r in retenus)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-0.5 -0.5 {colonnes} {lignes}" width="{colonnes * 6}" '
        f'height="{lignes * 6}" fill="none" aria-hidden="true" focusable="false">'
        f'<path d="{trace}" stroke="#000" stroke-width="{RAYON * 2:.2f}" stroke-linecap="round"/></svg>\n'
    )


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    geojson = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    retenus, colonnes, lignes = points(geojson)
    SORTIE.write_text(svg(retenus, colonnes, lignes), encoding="utf-8")
    print(f"{len(retenus)} points, grille {colonnes} x {lignes}, {SORTIE.stat().st_size} octets : {SORTIE}")


if __name__ == "__main__":
    main()
