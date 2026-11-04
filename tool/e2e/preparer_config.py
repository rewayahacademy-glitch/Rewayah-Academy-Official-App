"""Copie supabase/ dans un dossier de travail et adapte config.toml au local.

Le dossier supabase/ du depot n'est jamais modifie (zone interdite). Les ecarts :
- SMTP Gmail coupe : les e-mails partent dans la boite Mailpit de la pile ;
- confirmation d'e-mail activee (parcours 3, lien de confirmation) ;
- adresses de retour sur le serveur local de l'application ;
- limites d'envoi relevees (plusieurs inscriptions par passage) ;
- Google coupe (aucune cle en local), analytics et studio coupes.
Usage : python3 preparer_config.py <depot> <dossier de travail> <url de l'app>
"""
import pathlib, re, shutil, sys

depot, travail, app = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
cible = travail / 'supabase'
if cible.exists():
    shutil.rmtree(cible)
shutil.copytree(depot / 'supabase', cible, ignore=shutil.ignore_patterns('.temp', '.branches'))
cfg = (cible / 'config.toml').read_text()

def section(nom, f):
    global cfg
    m = re.search(r'(?m)^\[' + re.escape(nom) + r'\]\n', cfg)
    assert m, nom
    fin = re.search(r'(?m)^\[', cfg[m.end():])
    stop = m.end() + (fin.start() if fin else len(cfg[m.end():]))
    cfg = cfg[:m.end()] + f(cfg[m.end():stop]) + cfg[stop:]

def cle(corps, k, v):
    nouveau, n = re.subn(r'(?m)^' + re.escape(k) + r'\s*=.*$', f'{k} = {v}', corps)
    return nouveau if n else corps + f'{k} = {v}\n'

cfg = re.sub(r'(?ms)^additional_redirect_urls = \[.*?^\]\n', 'additional_redirect_urls = []\n', cfg)
cfg = re.sub(r'(?m)^project_id = .*$', 'project_id = "rewayah-e2e"', cfg)
section('auth.email.smtp', lambda c: cle(c, 'enabled', 'false'))
section('auth.email', lambda c: cle(cle(c, 'enable_confirmations', 'true'), 'max_frequency', '"1s"'))
section('auth.rate_limit', lambda c: cle(cle(c, 'email_sent', '1000'), 'sign_in_sign_ups', '1000'))
section('auth', lambda c: cle(cle(c, 'site_url', f'"{app}"'), 'additional_redirect_urls',
                              f'["{app}/**", "http://localhost:8090/**"]'))
section('auth.external.google', lambda c: cle(c, 'enabled', 'false'))
section('studio', lambda c: cle(c, 'enabled', 'false'))
if re.search(r'(?m)^\[analytics\]', cfg):
    section('analytics', lambda c: cle(c, 'enabled', 'false'))
# Le depot porte des numeros en double (0030, 0032, 0033) que le CI accepte
# (psql dans l'ordre du glob, octet par octet) et que le CLI refuse (cle
# primaire sur la version). On renumerote la copie dans le meme ordre.
mig = cible / 'migrations'
for i, f in enumerate(sorted(p for p in mig.iterdir() if p.suffix == '.sql')):
    f.rename(mig / f'{i + 1:05d}_{f.stem}.sql')
for f in mig.iterdir():
    if f.suffix != '.sql':
        f.unlink()
# Les fonctions Edge telechargent leurs modules (jsr.io, npm) a travers le
# proxy de l'environnement : le conteneur doit connaitre son certificat.
ca = pathlib.Path('/root/.ccr/ca-bundle.crt')
if ca.exists():
    (cible / 'functions' / '_ca').mkdir(exist_ok=True)
    shutil.copy(ca, cible / 'functions' / '_ca' / 'ca.crt')
# Les chemins des modeles sont relatifs a la racine du projet (dossier de travail).
(cible / 'config.toml').write_text(cfg)
print(f'config locale ecrite dans {cible}/config.toml')
