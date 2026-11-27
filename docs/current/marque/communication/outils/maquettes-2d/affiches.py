#!/usr/bin/env python3
"""Trois affiches fixes (9:16) dans la grammaire des références du directeur (27/11) :
un grand champ froid, une seule lumière (la porte), beaucoup de vide, le minuscule face à l'immense,
la lumière a une forme (projection de l'entrebâillement, en bandes nettes, sans dégradé).
La porte s'ouvre vers l'intérieur : la lumière vient de dedans, nous sommes dehors.
Géométrie de l'arche et du battant : tracé officiel ornement-plein.svg, non redessiné."""
import re, pathlib, json

REPO = pathlib.Path('/home/user/Rewayah-Academy-Official-App')
LOGO = REPO / 'assets/brand/logo'
FONTS = REPO / 'assets/fonts'
HERE = pathlib.Path(__file__).parent
ORN = re.findall(r' d="([^"]+)"', (LOGO / 'blanc/ornement-plein.svg').read_text())[0]
# Le contour extérieur (arche + battant fermé) et la baie, dans le repère de l'ornement (457 x 744).
OUTER = ("M228.502 0C354.698 0.000693714 457 102.213 457 228.299V698.096C408.62 720.609 356.414 736.289 "
         "301.62 743.89L0 704.176V228.299C-1.40788e-06 212.619 -0.114343 187.909 5.70508 173.305L5.70703 "
         "173.306C32.0729 75.7387 122.912 8.41403e-05 228.502 0Z")
H1, H2 = (38.3203, 192.029), (0.0, 704.176)
J1, J2 = (301.62, 237.916), (301.62, 743.89)        # montant droit (côté serrure)
F1, F2 = (220.509, 296.623), (220.509, 642.457)     # rive libre à l'ouverture du logo

PAL = {
  'froid': dict(mur='#17112C', arche='#21183F', battant='#2C2152', rive='#3B2E6B', sol='#0D0A1A', coeur='#FFFFFF',
                baie=['#FFFFFF', '#F5EFFF'],
                bandes=['#F3EDFF', '#DCCAFD', '#BFA5F7', '#9878E6', '#6E4CC4', '#47308A', '#2A1D55'],
                ombre='#0A0815', texte='#FFFFFF', sous='#DCCAFD', liseré='#DCCAFD'),
  'chaud': dict(mur='#17112C', arche='#21183F', battant='#2C2152', rive='#3B2E6B', sol='#0D0A1A', coeur='#FFF7E6',
                baie=['#FFF7E6', '#FFE9C2'],
                bandes=['#FFE7B8', '#FFCF85', '#F7AE5E', '#DC8448', '#A85A45', '#6B3A4E', '#37224A'],
                ombre='#0A0815', texte='#FFFFFF', sous='#FFD9A0', liseré='#FFCF85'),
}

def lerp(a, b, t): return (a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t)
def pts(ps): return ' '.join(f'{x:.1f},{y:.1f}' for x, y in ps)

def scene(tx, ty, k, s_ouvert, pal, faisceau_div=(110, 150), bas=1920):
    """Renvoie (svg, fonctions de placement). s_ouvert : 0 fermé, 1 ouvert comme le logo."""
    P = lambda p: (tx + p[0]*k, ty + p[1]*k)
    t1, t2 = lerp(J1, F1, s_ouvert), lerp(J2, F2, s_ouvert)
    battant = [H1, t1, t2, H2]
    baie = [J1, H1, t1, t2, H2, J2]            # la baie moins le battant : ce qui laisse passer la lumière
    # Au seuil, la lumière sort à droite de la rive libre du battant (le battant, ouvert vers l'intérieur,
    # cache la partie gauche) : le faisceau part du seuil entre la rive et le montant, et vient vers nous.
    gx = t2[0] - 40*s_ouvert
    a = P((gx, H2[1] + (J2[1]-H2[1]) * gx / J2[0]))
    b = P(J2)
    dl, dr = faisceau_div
    L, R = (a[0] - dl, bas), (b[0] + dr, bas)
    bandes = []
    n = len(pal['bandes'])
    for i in range(n):                          # bandes nettes, de plus en plus sombres en s'éloignant
        u0, u1 = i / n, (i + 1) / n
        q = [lerp(a, L, u0), lerp(b, R, u0), lerp(b, R, u1), lerp(a, L, u1)]
        bandes.append(f'<polygon points="{pts(q)}" fill="{pal["bandes"][i]}"/>')
    base_y = ty + 720*k
    g = f"""
  <rect x="0" y="0" width="1080" height="{base_y:.0f}" fill="{pal['mur']}"/>
  <rect x="0" y="{base_y:.0f}" width="1080" height="{1920-base_y:.0f}" fill="{pal['sol']}"/>
  {''.join(bandes)}
  <g transform="translate({tx},{ty}) scale({k})">
    <path d="{OUTER}" fill="{pal['arche']}"/>
    <polygon points="{pts(baie)}" fill="{pal['baie'][0]}"/>
    <polygon points="{pts([J1, H1, t1])}" fill="{pal['baie'][1]}"/>
    <polygon points="{pts(battant)}" fill="{pal['battant']}"/><polyline points="{pts([t1, t2])}" fill="none" stroke="{pal['liseré']}" stroke-width="{2/k:.2f}"/>
    <path d="{OUTER}" fill="none" stroke="{pal['rive']}" stroke-width="{2.2/k*1.6:.2f}"/>
  </g>"""
    return g, P, (a, b, L, R)

def praxis_dos(fx, fy, s, pal):
    """Praxis vu de dos, à contre-jour, d'après les mesures de la fiche (boîte de 200, pieds en (100, 206)).
    Proposition : une nouvelle pose, à montrer au directeur."""
    import math
    T = lambda x, y: (fx + (x-100)*s, fy + (y-206)*s)
    cx, cy = T(100, 108); r = 86*s
    ch = 108 - 0.54*86; hx = (86**2 - (108-ch)**2) ** .5
    c0, c1 = T(100-hx, ch), T(100+hx, ch)
    corners = [T(100 + 68*math.cos(0.2 + i*math.pi/2), 21 + 68*math.sin(0.2 + i*math.pi/2)*0.27) for i in range(4)]
    right = max(corners, key=lambda p: p[0])
    corps = '#2A2150'
    ombre = [T(80, 206), T(120, 206), T(150, 206 + 300), T(50, 206 + 300)]
    return f"""
  <polygon points="{pts(ombre)}" fill="{pal['ombre']}" opacity=".5"/>
  <circle cx="{cx:.1f}" cy="{cy-4.5*s:.1f}" r="{r+2.5*s:.1f}" fill="{pal['liseré']}"/>
  <circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{corps}"/>
  <path d="M{c0[0]:.1f} {c0[1]:.1f} A{r:.1f} {r:.1f} 0 0 1 {c1[0]:.1f} {c1[1]:.1f} Z" fill="#0B0916"/>
  {''.join(f'<circle cx="{T(x,160)[0]:.1f}" cy="{T(x,160)[1]-1.5*s:.1f}" r="{20.5*s:.1f}" fill="{pal["liseré"]}"/><circle cx="{T(x,160)[0]:.1f}" cy="{T(x,160)[1]:.1f}" r="{19*s:.1f}" fill="{corps}"/>' for x in (2, 198))}
  <polygon points="{pts(corners)}" fill="#0B0916" stroke="{pal['liseré']}" stroke-width="{1.6*s:.2f}" stroke-linejoin="round"/>
  <line x1="{right[0]:.1f}" y1="{right[1]:.1f}" x2="{right[0]:.1f}" y2="{right[1]+29*s:.1f}" stroke="#0B0916" stroke-width="{2.5*s:.2f}"/>
  <rect x="{right[0]-6*s:.1f}" y="{right[1]+29*s:.1f}" width="{12*s:.1f}" height="{19*s:.1f}" rx="{3*s:.1f}" fill="#0B0916"/>
  {''.join(f'<ellipse cx="{T(x,203)[0]:.1f}" cy="{T(x,203)[1]:.1f}" rx="{9.75*s:.1f}" ry="{4.4*s:.1f}" fill="#0B0916"/>' for x in (78, 122))}"""

def humain_dos(fx, fy, h, pal):
    """Une silhouette humaine de dos, sans visage, sur le seuil : la place de ta silhouette filmée."""
    s = h / 100
    T = lambda x, y: (fx + (x-50)*s, fy + (y-100)*s)
    robe = None
    ombre = [T(34, 100), T(66, 100), T(84, 100 + 110), T(16, 100 + 110)]
    hx, hy = T(50, 12)
    return f"""
  <polygon points="{pts(ombre)}" fill="{pal['ombre']}" opacity=".55"/>
  <path transform="translate({fx-50*s:.1f},{fy-100*s:.1f}) scale({s:.4f})" d="M50 19 C44 19 40 20 37 21.5 C31 23 28.5 27 28 33 L26.5 62 L25.5 100 L74.5 100 L73.5 62 L72 33 C71.5 27 69 23 63 21.5 C60 20 56 19 50 19 Z" fill="#0B0916" stroke="{pal['liseré']}" stroke-width="{1.4/s:.3f}" stroke-linejoin="round"/>
  <circle cx="{hx:.1f}" cy="{hy:.1f}" r="{6.6*s:.1f}" fill="#0B0916" stroke="{pal['liseré']}" stroke-width="1.4"/>
  <path transform="translate({fx-50*s:.1f},{fy-100*s:.1f}) scale({s:.4f})" d="M44 8.6 L44 4.6 Q50 2.4 56 4.6 L56 8.6 Z" fill="#0B0916" stroke="{pal['liseré']}" stroke-width="{1.2/s:.3f}"/>"""

GRAIN = """<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" stitchTiles="stitch"/>
<feColorMatrix type="saturate" values="0"/></filter>
<rect width="1080" height="1920" filter="url(#grain)" opacity=".07" style="mix-blend-mode:overlay"/>"""

def affiche(id_, corps, textes, pal, logo_pos='br'):
    lx = 'right:70px' if logo_pos == 'br' else 'left:70px'
    return f"""
<div class="frame" id="{id_}">
  <svg width="1080" height="1920" viewBox="0 0 1080 1920">{corps}{GRAIN}</svg>
  {textes}
  <img class="abs" src="file://{LOGO}/blanc/logo-horizontal.svg" style="{lx};bottom:84px;height:46px">
</div>"""

def txt(top, h, sous, pal, left=90, w=820, size=70):
    return (f'<div class="abs h" style="left:{left}px;top:{top}px;width:{w}px;font-size:{size}px;color:{pal["texte"]}">{h}</div>'
            + (f'<div class="abs p" style="left:{left}px;top:{top + int(size*1.12*h.count("<br>")) + int(size*1.25)}px;width:{w}px;font-size:28px;color:{pal["sous"]}">{sous}</div>' if sous else ''))

frames = []
html = []
for nom, pal_n in (('froid', 'froid'), ('chaud', 'chaud')):
    pal = PAL[pal_n]
    # 1. Le premier fil de lumière : la porte se décolle vers l'intérieur.
    if nom == 'froid':
        g, P, _ = scene(323, 1450 - 720*0.95, 0.95, 0.05, pal, faisceau_div=(20, 70))
        html.append(affiche(f'I1-fil-{nom}', g, txt(250, 'Pas d\'école coranique<br>près de chez vous ?', 'Une porte s\'ouvre.', pal), pal))
        frames.append(f'I1-fil-{nom}')
    # 2. Praxis minuscule devant l'arche immense.
    k = 1.6; tx = 175; ty = 1520 - 720*k
    g, P, (a, b, L, R) = scene(tx, ty, k, 1.0, pal, faisceau_div=(60, 120))
    m = lerp(lerp(a, b, .5), lerp(L, R, .5), .16)
    g += praxis_dos(m[0], m[1], 0.62, pal)
    html.append(affiche(f'I2-praxis-{nom}', g, txt(110, 'Chaque semaine,<br>la même porte.', 'La même heure, le même enseignant, la même classe.', pal, size=62), pal))
    frames.append(f'I2-praxis-{nom}')
    # 3. Toi sur le seuil.
    if nom == 'froid':
        k = 1.5; tx = 197; ty = 1476 - 720*k
        g, P, (a, b, L, R) = scene(tx, ty, k, 1.0, pal, faisceau_div=(70, 130))
        sx, sy = P((205, 716))
        g += humain_dos(sx, sy, 560, pal)
        html.append(affiche(f'I3-seuil-{nom}', g, txt(120, 'La porte est ouverte.', 'Le Coran, en classe stable, avec un enseignant attitré.', pal, size=66), pal))
        frames.append(f'I3-seuil-{nom}')

CSS = f"""
@font-face {{ font-family: DM; src: url(file://{FONTS}/DMSans-Variable.ttf); font-weight: 100 1000; }}
@font-face {{ font-family: Jak; src: url(file://{FONTS}/PlusJakartaSans-Variable.ttf); font-weight: 200 800; }}
* {{ box-sizing:border-box; margin:0; padding:0; }}
body {{ background:#333; display:flex; flex-wrap:wrap; gap:30px; padding:30px; }}
.frame {{ position:relative; width:1080px; height:1920px; overflow:hidden; flex:none; }}
.frame svg {{ position:absolute; left:0; top:0; }}
.abs {{ position:absolute; }}
.h {{ font-family:DM; font-weight:500; letter-spacing:-.025em; line-height:1.08; }}
.p {{ font-family:Jak; font-weight:500; line-height:1.45; }}
"""
(HERE / 'affiches.html').write_text(f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>{"".join(html)}</body></html>')
(HERE / 'affiches.json').write_text(json.dumps(frames))
print(frames)
