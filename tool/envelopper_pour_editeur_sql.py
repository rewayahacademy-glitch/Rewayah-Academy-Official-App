# Enveloppe une migration pour l'editeur SQL de Supabase (base de test) :
# retire BEGIN; et COMMIT;, et fait executer le texte apres suppression des
# retours chariot que Windows ajoute au copier-coller (lecon du 23/10/2026,
# docs/orchestration/LECONS-MIGRATIONS-STAGING.md).
#   python3 tool/envelopper_pour_editeur_sql.py <fichier.sql> <numero> <total>
import sys, pathlib, re
src = pathlib.Path(sys.argv[1]); n = sys.argv[2]; tot = sys.argv[3]
sql = src.read_text()
lignes = sql.split('\n')
b = [i for i,l in enumerate(lignes) if l.strip() == 'BEGIN;']
c = [i for i,l in enumerate(lignes) if l.strip() == 'COMMIT;']
assert len(b) == 1 and len(c) == 1 and b[0] < c[0], (src, b, c)
del lignes[c[0]]; del lignes[b[0]]
corps = '\n'.join(lignes)
assert '$rewayah_fichier$' not in corps and '$rewayah_enveloppe$' not in corps
nom = src.stem
print(f"""-- Fichier {n} sur {tot} : {nom}
-- Enveloppe pour l'editeur SQL : retire les retours chariot que Windows ajoute
-- au copier-coller, puis execute le fichier tel quel, en une seule transaction.
DO $rewayah_enveloppe$
BEGIN
  EXECUTE pg_catalog.replace($rewayah_fichier$
{corps}
$rewayah_fichier$, pg_catalog.chr(13), '');
END
$rewayah_enveloppe$;""")
