"""Detecte, sur une capture d'ecran a 1440 de large, le filet vertical qui
borde la barre laterale d'une coquille (NavShell, AdminShell) : une colonne de
pixels, entre 200 et 340 px du bord de debut (gauche, ou droite en arabe),
d'une couleur stable sur presque toute la hauteur et differente de ses
voisines. Ecrit le x trouve, ou « aucune ».

Usage : python3 -I tool/e2e/barre_laterale.py capture.png [rtl]
Outil de mesure du robot FIL-ARIANE / WEB-BUREAU (pile locale seulement)."""
import sys

from PIL import Image


def filet(chemin, rtl=False):
    image = Image.open(chemin).convert('RGB')
    largeur, hauteur = image.size
    px = image.load()
    lignes = range(int(hauteur * 0.12), int(hauteur * 0.92), 4)
    xs = range(200, 341) if not rtl else range(largeur - 341, largeur - 199)
    for x in xs:
        stables = 0
        ref = px[x, lignes[0]]
        for y in lignes:
            c = px[x, y]
            gauche = px[x - 2, y]
            droite = px[x + 2, y]
            proche = sum(abs(a - b) for a, b in zip(c, ref)) < 12
            distinct = (sum(abs(a - b) for a, b in zip(c, gauche)) > 6
                        and sum(abs(a - b) for a, b in zip(c, droite)) > 6) or (
                sum(abs(a - b) for a, b in zip(gauche, droite)) > 6)
            if proche and distinct:
                stables += 1
        if stables >= 0.85 * len(lignes):
            return x
    return None


if __name__ == '__main__':
    x = filet(sys.argv[1], len(sys.argv) > 2 and sys.argv[2] == 'rtl')
    print('aucune' if x is None else x)
