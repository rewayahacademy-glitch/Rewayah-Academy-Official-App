import json, random, re, unicodedata, datetime as dt
from zoneinfo import ZoneInfo
from collections import Counter
random.seed(20261130)
D = json.load(open('destinataires.json'))
JOUR = dt.date(2026, 11, 30)  # lundi
def slug(nom, ville):
    s = unicodedata.normalize('NFKD', f"{nom} {ville.split(',')[0]}").encode('ascii','ignore').decode().lower()
    s = re.sub(r'\(.*?\)', ' ', s); s = re.sub(r'[^a-z0-9]+', '-', s).strip('-')
    return '-'.join(s.split('-')[:4])[:40]
nouv = [d for d in D if d['statut']=='nouvelle' and d['langue'] in ('fr','en','ar') and d['email'].lower()!='info@islamischerbund.de']
rel = [d for d in D if d['statut']=='relance_possible' and (d.get('date_premiere_lettre') or '9')[:10] <= '2026-11-25']
rel.sort(key=lambda d: d['date_premiere_lettre'])
choix = [('lettre', d) for d in nouv] + [('relance', d) for d in rel[:100-len(nouv)]]
random.shuffle(choix)
# 20 % sans image, au hasard (temoin)
temoins = set(random.sample(range(len(choix)), round(len(choix)*0.2)))
# variantes equilibrees par langue et type
compte = Counter()
lignes = []
for i,(t,d) in enumerate(choix):
    lg = d['langue']; k=(t,lg); n = 4 if t=='lettre' else 2
    v = compte[k] % n; compte[k]+=1
    lignes.append(dict(email=d['email'].lower(), nom=d['nom'], ville=d['ville_pays'], langue=lg, type=t,
        variante=v, image=(i not in temoins), fuseau=d['fuseau'], ref=slug(d['nom'], d['ville_pays'])))
random.shuffle(lignes)  # melange les variantes
# paquets de taille aleatoire, heures ouvrables locales (9:00-16:30), lundi
def ouvrable(z, t):
    l = t.astimezone(ZoneInfo(z)); return l.date()==JOUR and l.weekday()<5 and (9*60) <= l.hour*60+l.minute <= 16*60+30
reste = lignes[:]; paquets=[]
debut = dt.datetime(2026,11,29,20,0,tzinfo=dt.timezone.utc); fin = dt.datetime(2026,12,1,8,0,tzinfo=dt.timezone.utc)
essais=0
while reste and essais<5000:
    essais+=1
    t = debut + dt.timedelta(minutes=random.randrange(int((fin-debut).total_seconds()//60)))
    taille = random.choice([8,10,12,15,19,23,27,31,38,49])
    pris = [l for l in reste if ouvrable(l['fuseau'], t)][:taille]
    if not pris: continue
    if any(abs((t-p['t']).total_seconds())<40*60 for p in paquets): continue
    for j,l in enumerate(pris):
        l['prochaine_tentative'] = (t + dt.timedelta(seconds=j*random.randint(25,70))).isoformat()
        l['heure_locale'] = dt.datetime.fromisoformat(l['prochaine_tentative']).astimezone(ZoneInfo(l['fuseau'])).strftime('%H:%M')
        reste.remove(l)
    paquets.append(dict(t=t, n=len(pris)))
assert not reste, len(reste)
paquets.sort(key=lambda p:p['t'])
json.dump(dict(jour=str(JOUR), lignes=sorted(lignes,key=lambda l:l['prochaine_tentative']),
  paquets=[dict(utc=p['t'].strftime('%H:%M'), jour=p['t'].strftime('%d/%m'), n=p['n']) for p in paquets]),
  open('plan_jour1.json','w'), ensure_ascii=False, indent=1)
print(len(lignes), Counter((l['type'],l['langue']) for l in lignes), sum(not l['image'] for l in lignes),'sans image')
print([(p['t'].strftime('%d %H:%M'),p['n']) for p in paquets])
print(Counter(l['fuseau'] for l in lignes).most_common(12))
