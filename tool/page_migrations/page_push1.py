"""La page du directeur pour PUSH-1, la base seulement (07/11/2026, soir).

  python3 -I tool/page_migrations/page_push1.py --sortie <page.html>

Decision du garde-cap du 07/11 : ce soir, la base de production recoit les deux
fichiers de PUSH-1 qui contiennent des mots d'effacement (20261112000000 puis
20261112000100), en UN collage du directeur ; le pilote applique ensuite
20261112000200 lui-meme. L'application (PR 284) n'est mise en ligne que le 08/11,
en tete du train G (regle P5 : deux mises en production Flutter par jour).

Sans le nouveau client, ces fichiers n'ont aucun effet visible : le declencheur
push_notification n'enfile rien sans abonnement d'appareil, et la tache cron
push-envoi n'appelle rien tant que la file est vide (20261112000100, l. 600-602).

Le script lit les fichiers sur origin/claude/push-1, au commit fige ci-dessous,
et refuse de produire la page si leur empreinte n'est pas celle de la seconde
lecture. Meme gabarit que la phase 2 (`modele_phase2.html`) ; enveloppe d'un seul
tenant comme `lots_production.envelopper_lot` (une transaction, sans BEGIN ni
COMMIT, retours chariot de Windows retires a l'execution).
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
COMMIT = 'a6decabc0df290d65be6fb22cf0b483e6bd68e58'
FICHIERS = (
    ('supabase/migrations/20261112000000_push1_contraintes_notifications.sql', 'fd823d58'),
    ('supabase/migrations/20261112000100_push1_file_et_abonnements.sql', '2caea75b'),
)

sys.path.insert(0, str(ICI))
from lots_production import envelopper_lot  # noqa: E402


def lire(chemin: str, empreinte: str) -> str:
    """Le fichier tel qu'il est au commit fige, jamais celui du disque."""
    try:
        brut = subprocess.run(['git', '-C', str(RACINE), 'show', f'{COMMIT}:{chemin}'],
                              check=True, capture_output=True).stdout
    except subprocess.CalledProcessError as erreur:
        raise SystemExit(f'{chemin} illisible au commit {COMMIT[:8]} '
                         f'(faire « git fetch origin claude/push-1 ») : {erreur.stderr.decode().strip()}')
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

    s = '1. Préparer la base des notifications sur téléphone : un seul collage'
    ajoute(s, 'Regarder la sauvegarde du jour',
           f'<p>Ouvrez <a href="{TABLEAU}/database/backups/scheduled" target="_blank" rel="noopener">les sauvegardes '
           'de la production</a>. Il doit y en avoir une d’aujourd’hui ou d’hier. S’il n’y en a aucune, écrivez-le-moi '
           'avant de continuer.</p>')
    ajoute(s, 'Vérifier le nom du projet',
           f'<p>Ouvrez <a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL de la production</a>. '
           f'En haut à gauche, le nom du projet doit être exactement « <strong>{NOM_PROJET}</strong> ». '
           'Si vous voyez un autre nom, arrêtez-vous et écrivez-le-moi.</p>')
    ajoute(s, 'Coller les deux fichiers en une fois',
           '<p>Ce collage prépare la base pour les notifications sur téléphone : les nouvelles sortes de notifications, '
           'la liste des appareils et la file d’envoi. Aucune donnée n’est effacée. Rien ne change pour les utilisateurs '
           'ce soir : les notifications partiront demain, quand la nouvelle application sera en ligne.</p>'
           f'<p class="tech">20261112000000 puis 20261112000100 · {round(taille / 1024)} Ko · une seule transaction : '
           'tout passe ou rien</p>'
           '<p>Copiez, collez dans l’éditeur SQL (<kbd>Ctrl</kbd>+<kbd>A</kbd> puis <kbd>Ctrl</kbd>+<kbd>V</kbd>), '
           '<strong>Run</strong>. Une fenêtre « destructive operation » apparaît : cliquez sur <strong>Run this '
           'query</strong>, c’est prévu (deux règles de la table des notifications sont remplacées par des règles plus '
           'larges). Attendez « Success ». Ce collage se fait une seule fois.</p>',
           collage, 'sql')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez « collage fait », ou le message d’erreur avec une capture. Le pilote pose ensuite le troisième '
           'fichier lui-même. Vous n’avez rien d’autre à faire ce soir.</p>')
    return e


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--sortie', required=True)
    a = p.parse_args()

    corps = [lire(chemin, empreinte) for chemin, empreinte in FICHIERS]
    for (chemin, _), sql in zip(FICHIERS, corps):
        print(f'{pathlib.Path(chemin).name} : mots d’effacement {mots_effacement(sql)}')
    collage = envelopper_lot('\n'.join(corps), 1, 1)
    print(f'collage : mots d’effacement {mots_effacement(collage)}')

    donnees = etapes(collage, len(collage.encode()))
    modele = (ICI / 'modele_phase2.html').read_text()
    for avant, apres in (
        ('<title>Mise en production Rewayah</title>', '<title>Notifications sur téléphone</title>'),
        ('<h1>Mettre Rewayah en production</h1>', '<h1>Préparer les notifications sur téléphone</h1>'),
        ('Comptez environ une heure et demie, surtout pour les 15 lots.',
         'Comptez environ cinq minutes, ce soir seulement.'),
        ('const CLE = "rewayah-phase2-2026-10-23";', 'const CLE = "rewayah-push1-2026-11-07";'),
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
