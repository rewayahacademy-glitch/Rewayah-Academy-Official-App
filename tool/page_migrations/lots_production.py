"""Regroupe en lots les migrations qui manquent a la base de production (phase 2, 23/10/2026).

  python3 -I tool/page_migrations/lots_production.py --apres 0042_z --sortie <dossier>

Ecrit lotNN.sql (fichiers dans l'ordre, environ 250 Ko par lot, jamais un fichier coupe) et un
dernier lot qui inscrit les migrations dans supabase_migrations.schema_migrations, pour que les
outils de deploiement ne les croient pas manquantes. La page de collage se fabrique ensuite avec
generer.py --production. La repetition : stub + migrations jusqu'a --apres, puis chaque lot d'un
seul tenant, puis les scenarios de la CI (docs/current/PHASE-2-MISE-EN-PRODUCTION.md).
"""
import argparse
import pathlib

RACINE = pathlib.Path(__file__).resolve().parents[2]
MIGRATIONS = RACINE / 'supabase' / 'migrations'
TAILLE = 250_000
MARQUES = ('$rewayah_fichier$', '$rewayah_enveloppe$')


def envelopper_lot(corps: str, n: int, total: int) -> str:
    """Un lot, une transaction : les BEGIN; et COMMIT; des fichiers sont retires (un bloc DO
    n'en accepte pas), les retours chariot de Windows aussi, a l'execution. Meme principe que
    tool/envelopper_pour_editeur_sql.py, mais pour plusieurs fichiers."""
    # Seules les commandes de transaction seules sur leur ligne ; jamais `end;`, qui ferme aussi
    # le corps d'une fonction PL/pgSQL.
    commandes = ('begin;', 'commit;', 'begin transaction;', 'start transaction;')
    lignes = [l for l in corps.split('\n') if l.strip().lower() not in commandes]
    corps = '\n'.join(lignes)
    for m in MARQUES:
        if m in corps:
            raise SystemExit(f'lot {n} : contient deja {m}')
    return (f'-- Lot {n} sur {total}, enveloppe pour l\'editeur SQL : une seule transaction ; tout passe ou rien.\n'
            'DO $rewayah_enveloppe$\nBEGIN\n  EXECUTE pg_catalog.replace($rewayah_fichier$\n'
            f'{corps}\n$rewayah_fichier$, pg_catalog.chr(13), \'\');\nEND\n$rewayah_enveloppe$;\n')


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--apres', required=True, help='dernier fichier deja applique en production (exclu)')
    p.add_argument('--sortie', required=True)
    a = p.parse_args()

    sortie = pathlib.Path(a.sortie)
    sortie.mkdir(parents=True, exist_ok=True)
    fichiers = sorted(f for f in MIGRATIONS.glob('*.sql') if f.name > a.apres)

    lots, courant, taille = [], [], 0
    for f in fichiers:
        t = f.stat().st_size
        if courant and taille + t > TAILLE:
            lots.append(courant)
            courant, taille = [], 0
        courant.append(f)
        taille += t
    if courant:
        lots.append(courant)

    total = len(lots) + 1
    for i, lot in enumerate(lots, 1):
        texte = [f'-- Lot {i}/{total} : {len(lot)} fichier(s), de {lot[0].name} a {lot[-1].name}\n']
        for f in lot:
            # Chaque fichier repart des reglages par defaut, comme dans une session neuve : un
            # SET search_path d'un fichier ne doit pas changer pg_get_functiondef (et les
            # empreintes md5 verifiees) du fichier suivant.
            texte.append(f'\n-- ===== {f.name}\nRESET ALL;\n{f.read_text()}\n')
        (sortie / f'lot{i:02d}.sql').write_text(envelopper_lot(''.join(texte), i, total))
        print(f'lot{i:02d}.sql  {len(lot):3d} fichier(s)  {lot[0].name} .. {lot[-1].name}')

    valeurs = []
    for f in fichiers:
        version, _, nom = f.stem.partition('_')
        valeurs.append(f"('{version}', '{nom}')")
    (sortie / f'lot{total:02d}.sql').write_text(envelopper_lot(
        f'-- Lot {total}/{total} : inscrit les {len(fichiers)} migrations des lots precedents dans l\'historique\n'
        '-- de la base. Aucun changement de schema.\n'
        'INSERT INTO supabase_migrations.schema_migrations (version, name)\nVALUES\n  '
        + ',\n  '.join(valeurs)
        + '\nON CONFLICT (version) DO NOTHING;\n', total, total))
    print(f'lot{total:02d}.sql  historique de {len(fichiers)} migrations')


if __name__ == '__main__':
    main()
