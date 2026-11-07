"""La page du directeur pour SALLE-3, l'accueil des enseignants, la base seulement (07/11/2026).

  python3 -I tool/page_migrations/page_salle3.py --sortie <page.html>

Ordre d'installation du garde-cap : PUSH-1 d'abord, puis ce collage (20261119000000,
qui contient un mot d'effacement : DROP CONSTRAINT), puis 20261119000100, que le
pilote applique lui-meme. 20261119000100 est verifie ici (empreinte, transactions,
mots d'effacement) mais n'est PAS dans la page.

Sans le nouvel ecran, ces fichiers n'ont aucun effet visible : ils ajoutent une sorte
de notification (« bienvenue_equipe ») et un declencheur qui ne joue qu'a l'activation
d'un enseignant.

Le script lit les fichiers par `git show` au commit fige ci-dessous et refuse de
produire la page si leur empreinte n'est pas celle de la lecture du garde-cap, ou si
un fichier porte BEGIN;, COMMIT;, BEGIN TRANSACTION; ou START TRANSACTION; seul sur
une ligne. Meme gabarit que PUSH-1 (`modele_phase2.html`) ; enveloppe d'un seul
tenant comme `lots_production.envelopper_lot`.
"""
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
ICI = pathlib.Path(__file__).resolve().parent
PROD = 'gggmtelinlpseweouyav'
NOM_PROJET = 'Rewayah PROD (Real Users)'
TABLEAU = f'https://supabase.com/dashboard/project/{PROD}'
COMMIT = 'f7819a3dbee5dd2b1908b4dc3f053a64ec84717a'
COLLE = ('supabase/migrations/20261119000000_bienvenue_equipe_evenement.sql', '4722f16e')
VERIFIE = ('supabase/migrations/20261119000100_bienvenue_equipe_notification.sql', '6f538912')

sys.path.insert(0, str(ICI))
from lots_production import envelopper_lot  # noqa: E402


def lire(chemin: str, empreinte: str) -> str:
    """Le fichier tel qu'il est au commit fige, jamais celui du disque."""
    try:
        brut = subprocess.run(['git', '-C', str(RACINE), 'show', f'{COMMIT}:{chemin}'],
                              check=True, capture_output=True).stdout
    except subprocess.CalledProcessError as erreur:
        raise SystemExit(f'{chemin} illisible au commit {COMMIT[:8]} '
                         f'(faire « git fetch origin claude/salle-3-accueil ») : {erreur.stderr.decode().strip()}')
    somme = hashlib.sha256(brut).hexdigest()
    if not somme.startswith(empreinte):
        raise SystemExit(f'{chemin} : sha256 {somme[:8]}, attendu {empreinte}. Page refusee.')
    texte = brut.decode()
    # Condition du pilote (07/11) : aucune commande de transaction seule sur sa ligne,
    # au lieu de compter sur envelopper_lot pour la retirer.
    commandes = ('begin;', 'commit;', 'begin transaction;', 'start transaction;')
    interdites = [n for n, l in enumerate(texte.split('\n'), 1) if l.strip().lower() in commandes]
    if interdites:
        raise SystemExit(f'{chemin} : BEGIN; ou COMMIT; seul sur une ligne (l. {interdites}). Page refusee.')
    print(f'{pathlib.Path(chemin).name} : sha256 {somme}')
    return texte


def mots_effacement(sql: str) -> dict[str, int]:
    return {m: len(re.findall(rf'\b{m}\b', sql, re.IGNORECASE)) for m in ('DELETE', 'DROP', 'TRUNCATE')}


def etapes(collage: str, taille: int) -> list[dict]:
    e: list[dict] = []

    def ajoute(section: str, titre: str, html: str, copie: str | None = None, genre: str = 'texte') -> None:
        e.append({'section': section, 'titre': titre, 'html': html, 'copie': copie, 'genre': genre})

    s = '1. Préparer l’accueil des enseignants : un seul collage'
    ajoute(s, 'Regarder la sauvegarde du jour',
           f'<p>Ouvrez <a href="{TABLEAU}/database/backups/scheduled" target="_blank" rel="noopener">les sauvegardes '
           'de la production</a>. Il doit y en avoir une d’aujourd’hui ou d’hier. S’il n’y en a aucune, écrivez-le-moi '
           'avant de continuer.</p>')
    ajoute(s, 'Vérifier le nom du projet',
           f'<p>Ouvrez <a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL de la production</a>. '
           f'En haut à gauche, le nom du projet doit être exactement « <strong>{NOM_PROJET}</strong> ». '
           'Si vous voyez un autre nom, arrêtez-vous et écrivez-le-moi.</p>')
    ajoute(s, 'Coller le fichier',
           '<p>Ce collage prépare l’accueil des enseignants : la base saura dire à un enseignant que son compte est '
           'ouvert et qu’il est le bienvenu dans l’équipe. Aucune donnée n’est effacée. Rien ne change pour les '
           'utilisateurs avant la mise en ligne de l’application.</p>'
           f'<p class="tech">20261119000000 · {round(taille / 1024)} Ko · une seule transaction : '
           'tout passe ou rien</p>'
           '<p>Copiez, collez dans l’éditeur SQL (<kbd>Ctrl</kbd>+<kbd>A</kbd> puis <kbd>Ctrl</kbd>+<kbd>V</kbd>), '
           '<strong>Run</strong>. Une fenêtre « destructive operation » apparaît : cliquez sur <strong>Run this '
           'query</strong>, c’est prévu (une règle de la table des notifications est remplacée par la même règle, '
           'un peu plus large). Attendez « Success ». Ce collage se fait une seule fois.</p>',
           collage, 'sql')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez « collage fait », ou le message d’erreur avec une capture. Le pilote pose ensuite le fichier '
           'suivant lui-même. Vous n’avez rien d’autre à faire.</p>')
    return e


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--sortie', required=True)
    a = p.parse_args()

    sql = lire(*COLLE)
    verifie = lire(*VERIFIE)
    for (chemin, _), texte in ((COLLE, sql), (VERIFIE, verifie)):
        print(f'{pathlib.Path(chemin).name} : mots d’effacement {mots_effacement(texte)}')
    collage = envelopper_lot(sql, 1, 1)
    print(f'collage (20261119000000 seul) : mots d’effacement {mots_effacement(collage)}')

    donnees = etapes(collage, len(collage.encode()))
    modele = (ICI / 'modele_phase2.html').read_text()
    for avant, apres in (
        ('<title>Mise en production Rewayah</title>', '<title>Accueil des enseignants</title>'),
        ('<h1>Mettre Rewayah en production</h1>', '<h1>Préparer l’accueil des enseignants</h1>'),
        ('Comptez environ une heure et demie, surtout pour les 15 lots.',
         'Comptez environ cinq minutes.'),
        ('const CLE = "rewayah-phase2-2026-10-23";', 'const CLE = "rewayah-salle3-2026-11-08";'),
    ):
        if avant not in modele:
            raise SystemExit(f'gabarit change : {avant}')
        modele = modele.replace(avant, apres)
    page = modele.replace('__NOMBRE__', str(len(donnees))).replace(
        '__DONNEES__', json.dumps(donnees, ensure_ascii=False).replace('</', '<\\/'))
    pathlib.Path(a.sortie).write_text(page)
    print(f'{a.sortie} : {len(donnees)} gestes, {len(page.encode()) // 1024} Ko')


if __name__ == '__main__':
    main()
