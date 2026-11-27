import json, base64, html
from collections import Counter
import lettres as Lt
P = json.load(open('plan_jour1.json'))
e = html.escape
img = {lg: base64.b64encode(open(f'img/prospection-{lg}.png','rb').read()).decode() for lg in ('fr','en','ar')}
NOMS = {'fr':'Français','en':'English','ar':'العربية'}
def lettre(lg, sujet, texte, lien, image):
    corps = Lt.corps(lg, texte, lien)
    d = ' dir="rtl"' if lg=='ar' else ''
    paras = ''.join(f'<p>{e(p).replace(chr(10),"<br>")}</p>' for p in corps.split('\n\n'))
    im = f'<img src="data:image/png;base64,{img[lg]}" alt="{e(Lt.ALT[lg])}" class="mailimg">' if image else ''
    return f'<article class="mail"{d}><div class="subj"><span>Objet</span> {e(sujet)}</div>{im}{paras}<p class="foot">{e(Lt.RAISON[lg])}<br><u>{"Se désinscrire" if lg=="fr" else "Unsubscribe" if lg=="en" else "إلغاء الاشتراك"}</u></p></article>'
blocs=[]
for lg in ('fr','en','ar'):
    lien = f'https://rewayahacademy.com/{lg}/familles?ref=exemple-ville'
    v = ''.join(f'<details{" open" if i==0 else ""}><summary>Variante {"ABCD"[i]} · {e(s)}</summary>{lettre(lg,s,t,lien,i==0)}</details>' for i,(s,t) in enumerate(Lt.L[lg]))
    r = ''.join(f'<details><summary>Relance {"12"[i]} · {e(s)}</summary>{lettre(lg,s,t,lien,False)}</details>' for i,(s,t) in enumerate(Lt.R[lg]))
    blocs.append(f'<section class="lang" id="l-{lg}"><h3>{NOMS[lg]}</h3><div class="vgrid">{v}</div><h4>Relances (une seule, à J+5 au moins, sans image)</h4>{r}</section>')
L = P['lignes']
c = Counter((l['type'],l['langue']) for l in L)
paq = ''.join(f'<tr><td>{p["jour"]} {p["utc"]}</td><td class="n">{p["n"]}</td></tr>' for p in P['paquets'])
rows = ''.join(f'<tr><td>{l["prochaine_tentative"][11:16]}</td><td>{l["heure_locale"]}</td><td>{e(l["nom"][:48])}</td><td>{e(l["ville"].split(",")[-1].strip())}</td><td>{l["langue"]}</td><td>{"lettre "+"ABCD"[l["variante"]] if l["type"]=="lettre" else "relance "+"12"[l["variante"]]}</td><td>{"oui" if l["image"] else "<b>non</b>"}</td></tr>' for l in L)
imgs = ''.join(f'<figure><img src="data:image/png;base64,{img[lg]}" alt="{e(Lt.ALT[lg])}"><figcaption>{NOMS[lg]} · {len(base64.b64decode(img[lg]))//1024} Ko · texte de remplacement : « {e(Lt.ALT[lg])} »</figcaption></figure>' for lg in ('fr','en','ar'))
out = open('page.html','w')
out.write(f'''<title>Prospection, nouvelle lettre</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@500;700&family=Plus+Jakarta+Sans:wght@400;600&family=Noto+Sans+Arabic:wght@400;600&display=swap">
<style>
/* Une colonne de lecture ; les lettres en cartes blanches comme dans la boîte de réception. */
:root{{--bg:#F1EFF4;--card:#FFFFFF;--ink:#110E20;--muted:#655E70;--line:#E3DEE9;--violet:#8652E6;--soft:#EEE6FA;--warn:#FCE8ED;--warnink:#921734;
--display:'DM Sans',system-ui,sans-serif;--body:'Plus Jakarta Sans',system-ui,sans-serif;--ar:'Noto Sans Arabic',Tahoma,sans-serif}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#17141F;--card:#211E28;--ink:#F5F2FA;--muted:#B3ABC0;--line:#383244;--violet:#A57CF0;--soft:#2D2440;--warn:#3A1820;--warnink:#F7B6C4;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#17141F;--card:#211E28;--ink:#F5F2FA;--muted:#B3ABC0;--line:#383244;--violet:#A57CF0;--soft:#2D2440;--warn:#3A1820;--warnink:#F7B6C4;color-scheme:dark}}
body{{background:var(--bg);color:var(--ink);font:400 15px/1.6 var(--body)}}
.wrap{{max-width:960px;margin:0 auto;padding-block:32px 64px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}}
h1,h2,h3,h4{{font-family:var(--display);text-wrap:balance;margin:0}}
h1{{font-size:2rem}} h2{{font-size:1.35rem;margin:40px 0 12px}} h3{{font-size:1.1rem;margin:24px 0 10px}} h4{{font-size:.95rem;margin:18px 0 8px;color:var(--muted)}}
.lead{{color:var(--muted);max-width:65ch}}
.verite{{background:var(--warn);color:var(--warnink);border-radius:12px;padding:16px 20px;margin-top:20px}}
.verite ol{{margin:8px 0 0;padding-left:20px}} .verite li{{margin:4px 0}}
.figs{{display:grid;gap:16px}} figure{{margin:0}} figure img{{width:100%;border-radius:12px;display:block;border:1px solid var(--line)}}
figcaption{{font-size:13px;color:var(--muted);margin-top:6px}}
details{{background:var(--card);border:1px solid var(--line);border-radius:12px;margin:8px 0}}
summary{{cursor:pointer;padding:12px 16px;font-weight:600}} summary:focus-visible{{outline:2px solid var(--violet);outline-offset:2px}}
.mail{{padding:4px 20px 16px;max-width:600px}} .mail[dir=rtl]{{font-family:var(--ar);font-size:16px}}
.mail .subj{{font-weight:600;padding:8px 0 12px;border-bottom:1px solid var(--line);margin-bottom:14px}} .subj span{{color:var(--muted);font-weight:400;margin-inline-end:6px}}
.mail p{{margin:0 0 12px;overflow-wrap:anywhere}} .mailimg{{width:100%;border-radius:12px;margin-bottom:16px}}
.mail .foot{{font-size:12px;color:var(--muted);border-top:1px solid var(--line);padding-top:10px}}
.stats{{display:flex;flex-wrap:wrap;gap:8px}} .chip{{background:var(--soft);border-radius:999px;padding:4px 12px;font-size:13px}}
.tbl{{overflow-x:auto;background:var(--card);border:1px solid var(--line);border-radius:12px}}
table{{border-collapse:collapse;width:100%;font-size:13px;font-variant-numeric:tabular-nums}}
th,td{{text-align:start;padding:6px 10px;border-bottom:1px solid var(--line);white-space:nowrap}} th{{color:var(--muted);font-weight:600}} td.n{{text-align:end}}
.cols{{display:grid;grid-template-columns:minmax(0,220px) minmax(0,1fr);gap:16px;align-items:start}}
@media (max-width:640px){{.cols{{grid-template-columns:1fr}}}}
.ask{{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px 20px}} .ask li{{margin:6px 0}}
</style>
<div class="wrap">
<h1>Prospection : la nouvelle lettre</h1>
<p class="lead">Pour le directeur, 27/11/2026. Trois images, une lettre par langue avec ses variantes, et le plan de la première journée. Rien n’est parti : j’attends votre « vas-y ». Les images et les textes sont des propositions tant que le registre de marque ne les a pas validés.</p>
<div class="verite"><b>À savoir d’abord</b><ol>
<li>La vague du 23 au 26/11 a eu <b>11 rebonds sur 200, soit 5,5 %</b> : au-dessus du seuil d’arrêt de 3 %. Ces adresses sont retirées à vie, avec la seule autre réponse humaine (« non merci » : MWRC Glasgow et El Hidaya).</li>
<li>Ces 200 lettres sont parties <b>en français, traduites automatiquement</b> à l’envoi, alors que la plupart des destinataires sont anglophones. Elles parlaient aussi de PISI, et n’avaient <b>aucun lien de désinscription</b>.</li>
<li>La feuille dit « relance J+3 envoyée le 25/11 » pour la première vague du 22/11 : <b>Gmail n’en montre aucune</b>. Je compte donc ces 48 organisations comme n’ayant reçu qu’une lettre.</li>
<li>L’image n’apparaît qu’après la fusion de la PR #720 et le déploiement de la fonction d’envoi. Les lettres espagnoles et portugaises (28 organisations) attendent votre accord.</li>
</ol></div>

<h2>Les images</h2>
<p class="lead">Un seul message : vos familles peuvent apprendre en attendant, sans perdre leur place chez vous. Une image par langue, 1200 × 630. Une lettre sur cinq part sans image, au hasard, pour comparer les réponses après 7 jours.</p>
<div class="figs">{imgs}</div>

<h2>Les lettres</h2>
<p class="lead">84 à 101 mots. Même fond dans chaque variante : la douleur (des familles sans réponse), l’issue (petites classes en ligne de 3 à 5 enfants, un enseignant attitré, trois séances par semaine, filles avec une enseignante), un seul geste demandé : transmettre un lien suivi par organisation. Aucun prix, aucun chiffre non vérifié, pas de PISI. Le pied dit pourquoi l’organisation reçoit le message et porte un lien de désinscription qui fonctionne.</p>
{''.join(blocs)}

<h2>La première journée : lundi 30/11</h2>
<div class="stats"><span class="chip">100 lettres</span><span class="chip">{sum(v for (t,_),v in c.items() if t=="lettre")} nouvelles (en {c[("lettre","en")]}, ar {c[("lettre","ar")]}, fr {c[("lettre","fr")]})</span><span class="chip">{sum(v for (t,_),v in c.items() if t=="relance")} relances de la vague du 22/11 (J+8)</span><span class="chip">{sum(not l["image"] for l in L)} sans image (témoin)</span><span class="chip">ordre aléatoire</span></div>
<p class="lead">Chaque lettre part entre 9 h et 16 h 30, heure du destinataire, en paquets de taille aléatoire, à 25 à 70 secondes d’intervalle dans un paquet. Les jours suivants : environ 130, puis le reste des relances (236 au total), jamais plus de 150 par jour. Arrêt immédiat et message à vous si les rebonds dépassent 3 % d’un jour ou à la première plainte.</p>
<div class="cols"><div class="tbl"><table><thead><tr><th>Paquet (UTC)</th><th>Lettres</th></tr></thead><tbody>{paq}</tbody></table></div>
<div class="tbl"><table><thead><tr><th>UTC</th><th>Locale</th><th>Organisation</th><th>Pays</th><th>Langue</th><th>Texte</th><th>Image</th></tr></thead><tbody>{rows}</tbody></table></div></div>

<h2>Ce que j’attends de vous</h2>
<div class="ask"><ol>
<li>« Vas-y » pour le plan du lundi 30/11, ou vos corrections.</li>
<li>La salutation : « Assalamu alaykum » partout, y compris en français, et la signature « Directeur, Rewayah Academy » : d’accord ?</li>
<li>Espagnol et portugais (28 organisations) : oui ou non.</li>
</ol></div>
</div>''')
