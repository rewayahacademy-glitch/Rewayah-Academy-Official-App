"""La porte et la lumiere : l'illustration des pages d'etat du site (introuvable, desinscription).

Le symbole est celui du logo, tel quel : les deux chemins de assets/symbole.svg (viewBox 716 x 707), blancs sur le fond
violet, sans retouche. Autour, seulement des formes simples et les teintes des jetons du site : lavande #E8D8FF, blanc.
- etat « attente » : la porte reste fermee, un filet de lumiere passe dessous et se pose sur le sol ; des pas en
  pointilles s'arretent avant le seuil, une lanterne attend a cote. C'est ce qu'on voit quand il faut patienter.
- etat « ouverte » : la lumiere entre franchement, les pas atteignent le seuil.
La lumiere respire tres lentement (mouvement accepte seulement : la regle est dans styles/site.css)."""
from __future__ import annotations

# Les deux chemins de assets/symbole.svg, caractere pour caractere.
CHEMIN_PORTE = ("M358.001 224.899C439.702 224.9 505.934 291.141 505.934 372.856V677.323C474.613 691.913 440.814 702.074 "
                "405.34 707V379.088L234.877 349.349L352.825 417.135V641.266L210.066 681.263V372.856C210.066 362.694 "
                "209.991 346.678 213.759 337.213C230.829 273.982 289.641 224.899 358.001 224.899Z")
CHEMIN_ARCHE = ("M358.001 0C555.719 0.000448656 716 159.979 716 357.32C716 398.175 709.132 437.429 696.482 473.993C696.376 "
                "474.3 696.266 474.608 696.159 474.915C668.13 555.215 612.201 622.469 539.959 665.107V368.416C539.958 "
                "267.907 458.494 186.429 358.001 186.429C257.508 186.429 176.042 267.907 176.041 368.416V665.107C70.6694 "
                "602.915 0.000276088 488.355 0 357.32C0.000131573 159.979 160.283 0.000168623 358.001 0Z")
# Le vide de la porte (l'arche interieure, vantail compris) : c'est la qu'on voit la piece derriere.
VIDE_PORTE = ("M358 224.9C439.7 224.9 505.9 291.1 505.9 372.9V677.3L210.1 681.3V372.9C210.1 291.1 276.3 224.9 358 224.9Z")


def porte_lumiere(etat: str = "attente") -> str:
    """SVG decoratif (aria-hidden) en ligne, 640 x 520. etat : « attente » ou « ouverte »."""
    ouverte = etat == "ouverte"
    # Le symbole : 716 x 707 ramene a 0,54, pose pour que son seuil (y = 707) tombe sur le sol (y = 440).
    # Pas en pointilles : de bas en haut vers le seuil ; en attente ils s'arretent avant.
    pas = "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}"/>'
        for x, y, rx, ry in ((320, 506, 14, 4.2), (320, 486, 11.5, 3.5), (320, 470, 9.5, 2.9), (320, 457, 7.5, 2.3))
        + (((320, 447, 6, 1.9),) if ouverte else ()))
    lanterne = "" if ouverte else (
        '<g class="pl__lanterne">'
        '<circle class="pl__halo" cx="84" cy="420" r="62" fill="url(#pl-l)"/>'
        '<path d="M66 452V414a18 18 0 0 1 36 0V452Z" fill="#E8D8FF"/>'
        '<path d="M76 452V416a8 8 0 0 1 16 0V452Z" fill="#FFFFFF"/>'
        '<path d="M84 388v-12" stroke="#E8D8FF" stroke-width="4" stroke-linecap="round"/></g>')
    return (
        '<svg class="pl" viewBox="0 0 640 520" role="presentation" aria-hidden="true" focusable="false">'
        '<defs>'
        '<linearGradient id="pl-f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="'
        f'{".95" if ouverte else ".8"}"/><stop offset="1" stop-color="#E8D8FF" stop-opacity="0"/></linearGradient>'
        '<linearGradient id="pl-v" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4E2983"/>'
        f'<stop offset=".55" stop-color="{"#BA98FB" if ouverte else "#6538E4"}"/>'
        f'<stop offset="1" stop-color="{"#FFFFFF" if ouverte else "#E8D8FF"}"/></linearGradient>'
        '<radialGradient id="pl-l"><stop offset="0" stop-color="#E8D8FF" stop-opacity=".55"/>'
        '<stop offset="1" stop-color="#E8D8FF" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="pl-s"><stop offset="0" stop-color="#25113F" stop-opacity=".45"/>'
        '<stop offset="1" stop-color="#25113F" stop-opacity="0"/></radialGradient></defs>'
        '<ellipse cx="320" cy="446" rx="300" ry="30" fill="url(#pl-s)"/>'
        # Le faisceau : sort du seuil et s'ouvre sur le sol, vers qui attend.
        f'<path class="pl__faisceau" d="M{"236" if ouverte else "240"} 430H{"404" if ouverte else "400"}L{"610" if ouverte else "480"} 518H'
        f'{"30" if ouverte else "160"}Z" fill="url(#pl-f)"/>'
        '<g transform="translate(127 58) scale(.54)">'
        f'<path d="{VIDE_PORTE}" fill="url(#pl-v)"/>'
        f'<path d="{CHEMIN_PORTE}" fill="#FFFFFF"/><path d="{CHEMIN_ARCHE}" fill="#FFFFFF"/></g>'
        f'<g fill="#FFFFFF" fill-opacity=".8">{pas}</g>{lanterne}</svg>')
