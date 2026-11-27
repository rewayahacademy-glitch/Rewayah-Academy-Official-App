#!/usr/bin/env python3
"""Génère explo.html : les cadres des directions explorées (chaque .frame = une image)."""
import re, pathlib

REPO = pathlib.Path('/home/user/Rewayah-Academy-Official-App')
LOGO = REPO / 'assets/brand/logo'
FONTS = REPO / 'assets/fonts'
SITE = REPO / 'site-public/assets'
HERE = pathlib.Path(__file__).parent

def path_d(svg):
    return re.findall(r' d="([^"]+)"', (LOGO / svg).read_text())

ORN = path_d('blanc/ornement-plein.svg')[0]          # viewBox 457 x 744
ORN_C = path_d('blanc/ornement-contour.svg')         # viewBox 494 x 777, stroke 17
SYM_C = path_d('blanc/symbole-contour.svg')          # viewBox 743 x 734

def logo(color, kind='logo-horizontal', h=44, style=''):
    return f'<img class="logo" src="file://{LOGO}/{color}/{kind}.svg" style="height:{h}px;{style}">'

DIR = f'file://{SITE}/scene-portrait-directeur-1600.webp'
ALIM = f'file://{SITE}/scene-portrait-fondateur-alimou-554.webp'
AHMAD = f'file://{SITE}/scene-portrait-fondateur-ahmad-426.webp'
GENERIC = f'file://{SITE}/scene-mere-porte-1024.webp'

SIG_AR = 'بوّابتك نحو القرآن'

CSS = f"""
@font-face {{ font-family: DM; src: url(file://{FONTS}/DMSans-Variable.ttf); font-weight: 100 1000; }}
@font-face {{ font-family: Jak; src: url(file://{FONTS}/PlusJakartaSans-Variable.ttf); font-weight: 200 800; }}
@font-face {{ font-family: Ar; src: url(file://{FONTS}/NotoSansArabic-Variable.ttf); font-weight: 100 900; }}
@font-face {{ font-family: Naskh; src: url(file://{FONTS}/UthmanTahaNaskh-Regular.otf); }}
@font-face {{ font-family: Kufi; src: url(file://{FONTS}/ReemKufi-Variable.ttf); font-weight: 400 700; }}
:root {{
  --nuit:#110E20; --ardoise:#16161E; --violet:#8652E6; --profond:#4E2983; --accent:#6538E4;
  --lavande:#BA98FB; --lilas:#DCCAFD; --pale:#EEE6FA; --papier:#F7F5FE; --filet:#E3DEE9; --doux:#655E70;
}}
* {{ box-sizing:border-box; margin:0; padding:0; }}
body {{ background:#444; padding:40px; display:flex; flex-wrap:wrap; gap:40px; align-items:flex-start; }}
.frame {{ position:relative; overflow:hidden; flex:none; font-family:Jak; }}
.post {{ width:1080px; height:1350px; }}
.story {{ width:1080px; height:1920px; }}
.abs {{ position:absolute; }}
.over {{ font-family:Jak; font-weight:600; font-size:21px; letter-spacing:.22em; text-transform:uppercase; }}
.h {{ font-family:DM; font-weight:600; letter-spacing:-.025em; line-height:1.02; }}
.p {{ font-family:Jak; font-weight:500; line-height:1.45; }}
.naskh {{ font-family:Naskh; direction:rtl; line-height:1.5; }}
.ar {{ font-family:Ar; direction:rtl; }}
.num {{ font-family:Jak; font-weight:700; font-variant-numeric:tabular-nums; }}
.logo {{ display:block; }}
"""

# Duotone ink -> lilas (feComponentTransfer), used for photos inside the arch
DUO = """
<filter id="duo-{id}" color-interpolation-filters="sRGB">
  <feColorMatrix type="saturate" values="0"/>
  <feComponentTransfer>
    <feFuncR type="table" tableValues="{r0} {r1}"/>
    <feFuncG type="table" tableValues="{g0} {g1}"/>
    <feFuncB type="table" tableValues="{b0} {b1}"/>
  </feComponentTransfer>
</filter>"""

def duo(id_, a, b):
    ha = [int(a[i:i+2], 16) / 255 for i in (1, 3, 5)]
    hb = [int(b[i:i+2], 16) / 255 for i in (1, 3, 5)]
    return DUO.format(id=id_, r0=ha[0], g0=ha[1], b0=ha[2], r1=hb[0], g1=hb[1], b1=hb[2])

def arch_window(uid, x, y, h, img, img_box, light=True, duo_from='#110E20', duo_to='#DCCAFD'):
    """L'ornement officiel (porte entrouverte) sert de fenêtre : la photo est derrière l'arche,
    l'entrebâillement de la porte laisse passer la lumière (un seul dégradé)."""
    s = h / 744
    w = 457 * s
    ix, iy, iw, ih = img_box
    return f"""
<svg class="abs" style="left:{x}px;top:{y}px" width="{w:.0f}" height="{h}" viewBox="0 0 457 744">
  <defs>
    <clipPath id="clip-{uid}"><path d="{ORN}"/></clipPath>
    {duo(uid, duo_from, duo_to)}
    <radialGradient id="lum-{uid}" cx="0.36" cy="0.56" r="0.62">
      <stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#EEE6FA"/>
      <stop offset="1" stop-color="#BA98FB" stop-opacity="0"/>
    </radialGradient>
  </defs>
  {'<rect x="-200" y="-100" width="860" height="1000" fill="url(#lum-%s)"/>' % uid if light else ''}
  <g clip-path="url(#clip-{uid})">
    <rect width="457" height="744" fill="{duo_from}"/>
    {f'<image href="{img}" x="{ix}" y="{iy}" width="{iw}" height="{ih}" preserveAspectRatio="xMidYMid slice" filter="url(#duo-{uid})"/>' if img else ''}
  </g>
</svg>"""

def arch_light(uid, x, y, h, glow=1.0):
    """L'arche seule, pleine de lumière : la porte entrouverte reste dans l'ombre."""
    s = h / 744
    w = 457 * s
    return f"""
<svg class="abs" style="left:{x}px;top:{y}px;overflow:visible" width="{w:.0f}" height="{h}" viewBox="0 0 457 744">
  <defs>
    <linearGradient id="g-{uid}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="#EEE6FA"/><stop offset="1" stop-color="#BA98FB"/>
    </linearGradient>
    <radialGradient id="h-{uid}" cx=".5" cy=".55" r=".5">
      <stop offset="0" stop-color="#DCCAFD" stop-opacity="{.55*glow}"/><stop offset="1" stop-color="#8652E6" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <ellipse cx="228" cy="420" rx="760" ry="820" fill="url(#h-{uid})"/>
  <path d="{ORN}" fill="url(#g-{uid})"/>
</svg>"""

def arch_frame(uid, x, y, w, h, img, pos=(0,0,1,1), line='#BA98FB', duo_from='#110E20', duo_to='#DCCAFD'):
    r = w/2
    d = f"M0 {h} L0 {r} A{r} {r} 0 0 1 {w} {r} L{w} {h} Z"
    g = 22; R = r + g
    d2 = f"M{-g} {h} L{-g} {r} A{R} {R} 0 0 1 {w+g} {r} L{w+g} {h}"
    ix, iy, iw, ih = pos
    return f"""
<svg class="abs" style="left:{x}px;top:{y}px;overflow:visible" width="{w}" height="{h}">
  <defs><clipPath id="cf-{uid}"><path d="{d}"/></clipPath>{duo(uid, duo_from, duo_to)}</defs>
  <path d="{d2}" fill="none" stroke="{line}" stroke-width="2" opacity=".55"/>
  <g clip-path="url(#cf-{uid})"><rect width="{w}" height="{h}" fill="{duo_from}"/>
  <image href="{img}" x="{ix*w}" y="{iy*h}" width="{iw*w}" height="{ih*h}" preserveAspectRatio="xMidYMin slice" filter="url(#duo-{uid})"/></g>
</svg>"""

frames = []
def frame(name, cls, style, inner, label):
    frames.append((name, label))
    return f'<div class="frame {cls}" id="{name}" style="{style}">{inner}</div>'

H = []

# ───────────── A. LE SEUIL (nuit, la porte comme fenêtre) ─────────────
A_POST = frame('A1-seuil-post', 'post', 'background:var(--nuit)', f"""
  {arch_frame('a1', 70, 300, 470, 980, DIR, (-0.35, 0, 1.7, 1.15))}
  <div class="abs over" style="left:620px;top:120px;color:var(--lavande)">Les fondateurs · 1/3</div>
  <div class="abs h" style="left:620px;top:190px;width:400px;font-size:66px;color:#fff">Ceux qui enseignent ont d'abord été enseignés.</div>
  <div class="abs p" style="left:620px;top:640px;width:390px;font-size:22px;color:#CFC8DC">
    <b style="color:#fff;font-weight:700">Abdoulaye Mouhidine Sow</b><br>Directeur et fondateur.<br>
    Licence en sciences coraniques et islamiques, Université islamique de Médine.</div>
  <div class="abs" style="left:620px;top:900px;width:390px;height:1px;background:#3A3550"></div>
  <div class="abs naskh" style="right:70px;top:930px;font-size:46px;color:var(--lilas)">{SIG_AR}</div>
  <div class="abs" style="right:70px;bottom:70px">{logo('blanc', h=46)}</div>
""", 'A · Le Seuil · publication 4:5')

A_STORY = frame('A2-seuil-story', 'story', 'background:var(--nuit)', f"""
  {arch_light('a2', 290, 330, 820)}
  <div class="abs naskh" style="left:0;right:0;top:1230px;text-align:center;font-size:64px;color:var(--lilas)">{SIG_AR}</div>
  <div class="abs h" style="left:110px;right:110px;top:1360px;text-align:center;font-size:62px;color:#fff">Une classe stable.<br>Un enseignant attitré.<br>Une heure qui ne bouge pas.</div>
  <div class="abs" style="left:0;right:0;bottom:250px;display:flex;justify-content:center">{logo('blanc', h=44)}</div>
""", 'A · Le Seuil · story 9:16')

# ───────────── B. L'INSTITUTION (papier, éditorial, preuve) ─────────────
def founder(img, name, role, cred, x, w, pos='center 20%'):
    return f"""
  <div class="abs" style="left:{x}px;top:600px;width:{w}px">
    <div style="height:420px;background:url({img}) {pos}/cover;"></div>
    <div style="height:4px;width:44px;background:var(--accent);margin:26px 0 16px"></div>
    <div style="font-family:DM;font-weight:700;font-size:25px;color:var(--nuit);letter-spacing:-.01em">{name}</div>
    <div class="p" style="font-size:18px;color:var(--doux);margin-top:6px">{role}<br>{cred}</div>
  </div>"""

grid = ''.join(f'<div class="abs" style="left:{60+i*240}px;top:0;bottom:0;width:1px;background:var(--filet)"></div>' for i in range(5))
B_POST = frame('B1-institution-post', 'post', 'background:var(--papier)', f"""
  {grid}
  <div class="abs" style="left:60px;top:64px">{logo('violet', h=44)}</div>
  <div class="abs over" style="right:60px;top:78px;color:var(--doux);font-size:18px">N° 01 · L'académie</div>
  <div class="abs" style="left:60px;right:60px;top:150px;height:2px;background:var(--nuit)"></div>
  <div class="abs h" style="left:60px;top:200px;width:900px;font-size:86px;color:var(--nuit)">Trois spécialistes du Coran. Une même exigence.</div>
  {founder(DIR, 'Abdoulaye Mouhidine Sow', 'Directeur, fondateur', 'Université islamique de Médine', 60, 300, 'center 15%')}
  {founder(ALIM, 'Mamadou Alimou Diallo', 'Fondateur', 'Étudiant, Université islamique de Médine', 390, 300)}
  {founder(AHMAD, 'Ahmad Diallo', 'Fondateur', 'Université du roi Abdelaziz, Djeddah', 720, 300)}
  <div class="abs p" style="left:60px;bottom:60px;font-size:18px;color:var(--doux)">Enseignement du Coran en ligne, en classes stables, depuis le 1<sup>er</sup> mai 2024.</div>
""", 'B · L\'Institution · publication 4:5')

def ligne(n, t, s, y):
    return f"""
  <div class="abs" style="left:90px;right:90px;top:{y}px;height:1px;background:var(--filet)"></div>
  <div class="abs num" style="left:90px;top:{y+34}px;font-size:24px;color:var(--accent)">{n}</div>
  <div class="abs h" style="left:200px;top:{y+26}px;font-size:48px;color:var(--nuit)">{t}</div>
  <div class="abs p" style="left:200px;top:{y+92}px;width:760px;font-size:24px;color:var(--doux)">{s}</div>"""

B_STORY = frame('B2-institution-story', 'story', 'background:var(--papier)', f"""
  <div class="abs" style="left:90px;top:250px">{logo('violet', h=46)}</div>
  <div class="abs naskh" style="right:90px;top:400px;font-size:120px;color:var(--nuit);line-height:1.3">{SIG_AR}</div>
  {ligne('01', 'Une classe stable', 'Les mêmes camarades, du début à la fin.', 760)}
  {ligne('02', 'Un enseignant attitré', 'Il connaît chaque élève par son nom et par sa lecture.', 960)}
  {ligne('03', 'Une heure fixe', 'Fixée à l\'heure de La Mecque, affichée à la vôtre.', 1160)}
  <div class="abs" style="left:90px;right:90px;top:1360px;height:1px;background:var(--filet)"></div>
  <div class="abs" style="left:90px;bottom:260px;background:var(--nuit);color:#fff;font-family:DM;font-weight:600;font-size:30px;padding:26px 40px">Voir les classes ouvertes</div>
""", 'B · L\'Institution · story 9:16')

# ───────────── C. LE PLAN DE LA HALQA + silhouettes adultes ─────────────
import math
def plan_halqa(cx, cy, R, stroke='#DCCAFD'):
    out = [f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="{stroke}" stroke-width="2" stroke-dasharray="2 10" stroke-linecap="round"/>']
    n = 7
    for i in range(n):
        a = -math.pi/2 + i*2*math.pi/n
        x, y = cx + R*math.cos(a), cy + R*math.sin(a)
        rot = math.degrees(a) + 90
        big = i == 0
        k = 1.25 if big else 1
        # vue de dessus : épaules (demi-ellipse) + tête (cercle), sans visage
        out.append(f'<g transform="translate({x:.1f},{y:.1f}) rotate({rot:.1f}) scale({k})">'
                   f'<path d="M-44 10 A44 30 0 0 1 44 10 L44 22 L-44 22 Z" fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>'
                   f'<circle cx="0" cy="2" r="19" fill="{stroke if big else "none"}" stroke="{stroke}" stroke-width="3"/>'
                   f'<rect x="-22" y="40" width="44" height="6" rx="3" fill="{stroke}" opacity=".7"/></g>')
    return ''.join(out)

C_POST = frame('C1-halqa-post', 'post', 'background:var(--profond)', f"""
  <svg class="abs" style="left:0;top:0" width="1080" height="1350">
    {plan_halqa(540, 790, 300)}
    <g transform="translate(505,735) scale(.15)"><path d="{ORN}" fill="#BA98FB"/></g>
    <line x1="540" y1="440" x2="820" y2="330" stroke="#DCCAFD" stroke-width="1.5"/>
    <line x1="820" y1="330" x2="1010" y2="330" stroke="#DCCAFD" stroke-width="1.5"/>
    <line x1="801" y1="896" x2="900" y2="1150" stroke="#DCCAFD" stroke-width="1.5"/>
    <line x1="900" y1="1150" x2="1010" y2="1150" stroke="#DCCAFD" stroke-width="1.5"/>
  </svg>
  <div class="abs over" style="left:70px;top:80px;color:var(--lavande)">Le plan d'une classe</div>
  <div class="abs h" style="left:70px;top:140px;width:700px;font-size:70px;color:#fff">La halqa, telle qu'elle a toujours été.</div>
  <div class="abs p" style="left:830px;top:290px;width:190px;font-size:18px;color:var(--lilas)">L'enseignant attitré</div>
  <div class="abs p" style="left:830px;top:1110px;width:190px;font-size:18px;color:var(--lilas)">Les mêmes élèves, chaque semaine</div>
  <div class="abs" style="left:70px;bottom:70px">{logo('blanc', h=42)}</div>
""", 'C · La Halqa · publication 4:5')

def silhouette(x, base, h, w, color='#0B0916'):
    # arche-personne : proportions adultes, sans bras, sans visage ; ombre longue vers nous
    r = w/2
    return (f'<path d="M{x-r} {base} L{x-r} {base-h+r} A{r} {r} 0 0 1 {x+r} {base-h+r} L{x+r} {base} Z" fill="{color}"/>'
            f'<path d="M{x-r} {base} L{x+r} {base} L{x+r*2.6} {base+h*0.9} L{x-r*1.2} {base+h*0.9} Z" fill="#000" opacity=".28"/>')

C_STORY = frame('C2-silhouettes-story', 'story', 'background:var(--nuit)', f"""
  <svg class="abs" style="left:0;top:0" width="1080" height="1920">
    <defs><radialGradient id="sol" cx=".5" cy="0" r=".8"><stop offset="0" stop-color="#BA98FB" stop-opacity=".5"/><stop offset="1" stop-color="#110E20" stop-opacity="0"/></radialGradient></defs>
    <rect x="0" y="1060" width="1080" height="860" fill="url(#sol)"/>
  </svg>
  {arch_light('c2', 440, 560, 500, glow=1.2)}
  <svg class="abs" style="left:0;top:0" width="1080" height="1920">
    {silhouette(250, 1180, 330, 64)}{silhouette(345, 1180, 240, 52)}
    {silhouette(760, 1180, 350, 66)}{silhouette(850, 1180, 300, 60)}
  </svg>
  <div class="abs h" style="left:90px;right:90px;top:1480px;font-size:58px;color:#fff;text-align:center">Chacun à sa place.<br>La porte reste ouverte.</div>
  <div class="abs" style="left:0;right:0;bottom:250px;display:flex;justify-content:center">{logo('blanc', h=42)}</div>
""", 'C · Silhouettes adultes · story 9:16')

# ───────────── PRAXIS : trois doses sur la même mise en page ─────────────
def praxis_dose(n, inner, label):
    return frame(f'P{n}-praxis', 'post', 'background:var(--nuit)', inner, label)

base_txt = lambda t: f'<div class="abs h" style="left:80px;top:150px;width:900px;font-size:76px;color:#fff">{t}</div>'
P1 = praxis_dose(1, f"""{base_txt('Les inscriptions de janvier sont ouvertes.')}
  {arch_light('p1', 330, 520, 640)}
  <div class="abs" style="left:80px;bottom:70px">{logo('blanc', h=44)}</div>""", 'Praxis absent (familles, adultes)')
P2 = praxis_dose(2, f"""{base_txt('Les inscriptions de janvier sont ouvertes.')}
  {arch_light('p2', 330, 520, 640)}
  <div class="abs" style="left:80px;bottom:60px;display:flex;align-items:center;gap:22px">
    <img src="praxis-violet.png" style="width:96px;height:96px;border-radius:50%">
    <div class="p" style="font-size:22px;color:#CFC8DC;width:520px"><b style="color:#fff">Praxis</b>, l'assistant de l'académie, répond à vos questions dans l'application.</div></div>
  <div class="abs" style="right:80px;bottom:80px">{logo('blanc', 'symbole-plein', h=60)}</div>""", 'Praxis signature (la voix, en petit)')
P3 = praxis_dose(3, f"""<div class="abs" style="inset:0;background:var(--violet)"></div>
  <img class="abs" src="praxis-violet.png" style="left:140px;top:380px;width:800px;height:800px;-webkit-mask-image:radial-gradient(circle at 50% 55%,#000 52%,transparent 70%)">
  <div class="abs h" style="left:80px;top:120px;width:900px;font-size:72px;color:#fff">Ton cours commence dans dix minutes.</div>
  <div class="abs" style="left:80px;bottom:70px">{logo('blanc', h=44)}</div>""", 'Praxis en entier (élèves enfants, fin de vidéo)')

# ───────────── TROIS LANGUES (direction A) ─────────────
A_EN = frame('L-en', 'post', 'background:var(--nuit)', f"""
  {arch_frame('en', 70, 300, 470, 980, DIR, (-0.35, 0, 1.7, 1.15))}
  <div class="abs over" style="left:620px;top:120px;color:var(--lavande)">The founders · 1/3</div>
  <div class="abs h" style="left:620px;top:190px;width:400px;font-size:70px;color:#fff">Those who teach were first taught.</div>
  <div class="abs p" style="left:620px;top:600px;width:390px;font-size:22px;color:#CFC8DC">
    <b style="color:#fff;font-weight:700">Abdoulaye Mouhidine Sow</b><br>Director and founder.<br>Degree in Qur'anic and Islamic sciences, Islamic University of Madinah.</div>
  <div class="abs" style="right:70px;bottom:70px">{logo('blanc', h=46)}</div>
""", 'Anglais')
A_AR = frame('L-ar', 'post', 'background:var(--nuit)', f"""
{arch_frame('ar', 540, 300, 470, 980, DIR, (-0.35, 0, 1.7, 1.15))}
  <div class="abs ar" style="right:600px;top:116px;font-size:26px;font-weight:600;color:var(--lavande)">المؤسسون · ١/٣</div>
  <div class="abs ar" style="right:600px;top:180px;width:440px;font-size:62px;font-weight:700;line-height:1.35;color:#fff;text-align:right">مَن يُعلِّم اليوم، تعلَّم بالأمس.</div>
  <div class="abs ar" style="right:600px;top:600px;width:420px;font-size:24px;line-height:1.7;color:#CFC8DC;text-align:right">
    <b style="color:#fff">عبد الله محي الدين صو</b><br>المدير والمؤسس.<br>بكالوريوس كلية القرآن والدراسات الإسلامية، الجامعة الإسلامية بالمدينة المنورة.</div>
  <div class="abs" style="left:70px;bottom:70px">{logo('blanc', h=46)}</div>
""", 'Arabe (droite à gauche)')

# ───────────── Contre-exemple : le gabarit générique ─────────────
GEN = frame('X-generique', 'post', 'background:linear-gradient(160deg,#5B2BD9,#C26DFF 60%,#FF9AD5)', f"""
  <img class="abs" src="{GENERIC}" style="left:120px;top:330px;width:840px;opacity:.95">
  <div class="abs" style="left:0;right:0;top:110px;text-align:center;font-family:DM;font-weight:800;font-size:92px;color:#fff;text-shadow:0 8px 30px rgba(60,0,120,.5)">Learn Quran Online!</div>
  <div class="abs" style="left:0;right:0;top:225px;text-align:center;font-family:Jak;font-weight:600;font-size:34px;color:#FFE9FF">Best teachers · Flexible · All ages</div>
  <div class="abs" style="left:340px;bottom:90px;width:400px;padding:28px;border-radius:60px;text-align:center;background:linear-gradient(90deg,#FFD24D,#FF7AC8);font-family:DM;font-weight:800;font-size:38px;color:#3A0A6B">ENROLL NOW</div>
""", 'Contre-exemple : le gabarit « IA générique »')

html = f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>
{A_POST}{A_STORY}{B_POST}{B_STORY}{C_POST}{C_STORY}{P1}{P2}{P3}{A_EN}{A_AR}{GEN}
</body></html>"""
(HERE / 'explo.html').write_text(html)
import json
(HERE / 'frames.json').write_text(json.dumps(frames, ensure_ascii=False))
print(len(frames), 'cadres')
