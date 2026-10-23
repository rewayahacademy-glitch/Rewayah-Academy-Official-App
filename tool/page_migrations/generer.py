# Fabrique la page que le directeur suit pour coller des migrations dans
# l'editeur SQL de la base de test (regle du directeur du 23/10/2026,
# docs/orchestration/LECONS-MIGRATIONS-STAGING.md, section « La page de
# collage »). Une page privee, publiee par l'outil Artifact : consignes en mots
# simples, un bouton Copier par fichier, une coche par fichier, le fichier
# suivant entoure, chaque fichier enveloppe contre les fins de ligne de Windows.
#
#   python3 -I tool/page_migrations/generer.py --sortie <page.html> \
#     [--titre "Installer les 3 migrations sur la base de test"] [--debut 1] \
#     supabase/migrations/<fichier>.sql::"Ce que le fichier fait, en une phrase." ...
#
# La phrase apres « :: » est celle que lit le directeur : la dire en mots de
# tous les jours, jamais le nom technique. Sans phrase, la premiere ligne de
# commentaire du fichier est reprise (a eviter).
import argparse
import json
import pathlib
import re
import sys

ICI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ICI.parent))
from envelopper_pour_editeur_sql import envelopper  # noqa: E402

EFFACEMENT = re.compile(r'\b(delete from|drop |truncate)\b', re.IGNORECASE)


def phrase_par_defaut(sql: str) -> str:
    for ligne in sql.splitlines():
        if ligne.startswith('--'):
            return ligne.lstrip('- ').strip()
    return ''


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--sortie', required=True)
    p.add_argument('--titre')
    p.add_argument('--debut', type=int, default=1)
    p.add_argument('fichiers', nargs='+')
    a = p.parse_args()

    entrees = []
    for arg in a.fichiers:
        chemin, _, phrase = arg.partition('::')
        entrees.append((pathlib.Path(chemin), phrase.strip()))
    total = a.debut + len(entrees) - 1

    donnees, destructifs = [], []
    for i, (chemin, phrase) in enumerate(entrees, a.debut):
        sql = chemin.read_text()
        if EFFACEMENT.search(sql):
            destructifs.append(i)
        texte = envelopper(sql, chemin.stem, i, total)
        donnees.append({
            'n': i,
            'fichier': chemin.name,
            'quoi': phrase or phrase_par_defaut(sql),
            'sql': texte,
            'ko': round(len(texte.encode()) / 1024),
        })

    n = len(entrees)
    titre = a.titre or (
        'Installer la migration sur la base de test' if n == 1
        else f'Installer les {n} migrations sur la base de test')
    if destructifs:
        liste = ', '.join(str(x) for x in destructifs[:-1])
        liste = f'{liste} et {destructifs[-1]}' if liste else str(destructifs[-1])
        mot = 'le fichier' if len(destructifs) == 1 else 'les fichiers'
        note = f' : c\'est normal pour {mot} {liste}.'
    else:
        note = '. Aucun de ces fichiers ne devrait la montrer : si elle apparaît, arrêtez-vous et écrivez-moi.'
    minutes = max(5, round(n * 1.2))
    cle = 'rewayah-migrations-' + '-'.join(e[0].stem.split('_')[0] for e in entrees[:1] + entrees[-1:])

    modele = (ICI / 'modele.html').read_text()
    page = (modele
            .replace('__TITRE__', titre)
            .replace('__MINUTES__', str(minutes))
            .replace('__DESTRUCTIFS__', note)
            .replace('__NOMBRE__', str(n))
            .replace('__CLE__', cle)
            .replace('__DONNEES__', json.dumps(donnees, ensure_ascii=False).replace('</', '<\\/')))
    pathlib.Path(a.sortie).write_text(page)
    print(f'{a.sortie} : {n} fichier(s), {len(page.encode()) // 1024} Ko, effacement dans : {destructifs or "aucun"}')


if __name__ == '__main__':
    main()
