# Enveloppe une migration pour l'editeur SQL de Supabase (base de test) :
# retire BEGIN; et COMMIT;, et fait executer le texte apres suppression des
# retours chariot que Windows ajoute au copier-coller (lecon du 23/10/2026,
# docs/orchestration/LECONS-MIGRATIONS-STAGING.md).
#   python3 tool/envelopper_pour_editeur_sql.py <fichier.sql> <numero> <total>
# La page du directeur (tool/page_migrations/generer.py) emploie la meme
# fonction : un seul code d'enveloppe.
import pathlib
import sys


# Les commandes de transaction qu'un fichier ne doit pas porter seules sur leur
# ligne (jamais `end;`, qui ferme aussi le corps d'une fonction PL/pgSQL).
COMMANDES_TRANSACTION = ('begin;', 'commit;', 'begin transaction;', 'start transaction;')


def lignes_de_transaction(sql: str) -> list[int]:
    """Les numeros de ligne (a partir de 1) ou une commande de transaction est seule."""
    return [n for n, l in enumerate(sql.split('\n'), 1) if l.strip().lower() in COMMANDES_TRANSACTION]


def envelopper(sql: str, nom: str, n, total, *, sans_transaction: bool = False) -> str:
    """`sans_transaction=False` (ancien mode, pages d'un seul usage) : le fichier porte un
    BEGIN; et un COMMIT; que l'enveloppe retire. `sans_transaction=True` (page generique du
    directeur) : le fichier n'en porte AUCUN, et la page le refuse avec une phrase simple ;
    l'enveloppe suffit a faire passer le fichier en une seule transaction."""
    lignes = sql.split('\n')
    if sans_transaction:
        trouvees = lignes_de_transaction(sql)
        if trouvees:
            ou = ', '.join(str(x) for x in trouvees[:5]) + (' ...' if len(trouvees) > 5 else '')
            raise SystemExit(
                f"{nom} : page refusee. Ce fichier contient BEGIN; ou COMMIT; seul sur une ligne "
                f"(ligne {ou}). La page colle chaque fichier dans une seule transaction qu'elle "
                "ouvre elle-meme : ces mots la casseraient, et le fichier pourrait s'appliquer "
                "a moitie. Retirez ces lignes du fichier, puis relancez la page.")
    else:
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
