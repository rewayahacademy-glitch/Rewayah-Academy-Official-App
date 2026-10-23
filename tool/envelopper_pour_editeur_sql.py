# Enveloppe une migration pour l'editeur SQL de Supabase (base de test) :
# retire BEGIN; et COMMIT;, et fait executer le texte apres suppression des
# retours chariot que Windows ajoute au copier-coller (lecon du 23/10/2026,
# docs/orchestration/LECONS-MIGRATIONS-STAGING.md).
#   python3 tool/envelopper_pour_editeur_sql.py <fichier.sql> <numero> <total>
# La page du directeur (tool/page_migrations/generer.py) emploie la meme
# fonction : un seul code d'enveloppe.
import pathlib
import sys


def envelopper(sql: str, nom: str, n, total) -> str:
    lignes = sql.split('\n')
    b = [i for i, l in enumerate(lignes) if l.strip() == 'BEGIN;']
    c = [i for i, l in enumerate(lignes) if l.strip() == 'COMMIT;']
    if not (len(b) == 1 and len(c) == 1 and b[0] < c[0]):
        raise SystemExit(f"{nom} : il faut exactement un BEGIN; puis un COMMIT; seuls sur leur ligne")
    del lignes[c[0]]
    del lignes[b[0]]
    corps = '\n'.join(lignes)
    for marque in ('$rewayah_fichier$', '$rewayah_enveloppe$'):
        if marque in corps:
            raise SystemExit(f"{nom} : contient deja {marque}")
    return f"""-- Fichier {n} sur {total} : {nom}
-- Enveloppe pour l'editeur SQL : retire les retours chariot que Windows ajoute
-- au copier-coller, puis execute le fichier tel quel, en une seule transaction.
DO $rewayah_enveloppe$
BEGIN
  EXECUTE pg_catalog.replace($rewayah_fichier$
{corps}
$rewayah_fichier$, pg_catalog.chr(13), '');
END
$rewayah_enveloppe$;"""


if __name__ == '__main__':
    src = pathlib.Path(sys.argv[1])
    print(envelopper(src.read_text(), src.stem, sys.argv[2], sys.argv[3]))
