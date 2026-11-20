# planches.py <dossier maquette> <dossier application> <dossier sortie>
#
# ENTREE-PRAXIS : les planches « maquette | application », deux moments par etat.
#
# - maquette : suites d'images de entree-outils/lot.js, nommees
#   <format>-<theme>-<langue>--<etat>-NN.png (une image toutes les 500 ms) ;
# - application : captures de test/features/connexion/entree_praxis_capture_test.dart,
#   <nom>-1.png (la phrase de Praxis posee) et <nom>-2.png (la scene au repos).
#
# L'horloge de la maquette, dans un navigateur, varie d'un essai a l'autre : on
# choisit donc ses images par leur contenu. Le repos est la derniere image de la
# suite ; la phrase posee est l'image qui s'ecarte le plus du repos dans la
# scene (hors formulaire), parmi celles ou Praxis est deja arrive.
#
# Planche : maquette (phrase) | application (phrase) || maquette (repos) | application (repos)
# sur une rangee (telephone) ou deux (large).
import glob
import os
import sys

from PIL import Image, ImageChops

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from planche import ecran  # noqa: E402


def zone_scene(im, fmt, langue):
    w, h = im.size
    if fmt == "tel":
        return im.crop((0, 0, w, int(h * 0.45)))
    return im.crop((int(w * 0.45), 0, w, h)) if langue == "ar" else im.crop((0, 0, int(w * 0.55), h))


def ecart(a, b):
    d = ImageChops.difference(a, b).convert("L").point(lambda v: 255 if v > 60 else 0)
    return sum(d.histogram()[255:])


def choisir(suite, fmt, langue):
    images = [ecran(Image.open(f), fmt) for f in suite]
    repos = images[-1]
    zr = zone_scene(repos, fmt, langue)
    debut = min(3, len(images) - 1)
    meilleur = max(range(debut, len(images) - 1), key=lambda i: ecart(zone_scene(images[i], fmt, langue), zr))
    return images[meilleur], repos


def hauteur(im, H):
    return im.convert("RGB").resize((int(im.width * H / im.height), H), Image.LANCZOS)


def main():
    maq, app, sortie = sys.argv[1:4]
    os.makedirs(sortie, exist_ok=True)
    noms = sorted({os.path.basename(f).rsplit("-", 1)[0] for f in glob.glob(os.path.join(maq, "*-[0-9][0-9].png"))})
    for nom in noms:
        a1, a2 = os.path.join(app, nom + "-1.png"), os.path.join(app, nom + "-2.png")
        if not (os.path.exists(a1) and os.path.exists(a2)):
            continue
        fmt = nom.split("-")[0]
        langue = nom.split("--")[0].split("-")[2]
        suite = sorted(glob.glob(os.path.join(maq, nom + "-[0-9][0-9].png")))
        m1, m2 = choisir(suite, fmt, langue)
        H = 844 if fmt == "tel" else 620
        p = [hauteur(x, H) for x in (m1, Image.open(a1), m2, Image.open(a2))]
        g = 24
        if fmt == "tel":
            W = sum(x.width for x in p) + 6 * g
            o = Image.new("RGB", (W, H + 2 * g), (255, 255, 255))
            x = g
            for i, im in enumerate(p):
                o.paste(im, (x, g))
                x += im.width + (2 * g if i == 1 else g)
        else:
            W = max(p[0].width + p[1].width, p[2].width + p[3].width) + 3 * g
            o = Image.new("RGB", (W, 2 * H + 3 * g), (255, 255, 255))
            o.paste(p[0], (g, g))
            o.paste(p[1], (2 * g + p[0].width, g))
            o.paste(p[2], (g, 2 * g + H))
            o.paste(p[3], (2 * g + p[2].width, 2 * g + H))
        o.save(os.path.join(sortie, nom + ".jpg"), quality=86)
        print(nom)


main()
