import json, sys, hashlib
import lettres as Lt
P = json.load(open('plan_jour1.json'))
def q(s): return "'" + s.replace("'", "''") + "'"
def dq(s, tag='t'):
    assert f'${tag}$' not in s
    return f'${tag}${s}${tag}$'
seg_rows = []
for k,(lg,sujets,texte) in Lt.SEG.items():
    seg_rows.append(f"    ({q(k)}, {q(lg)}, 'lettre', {dq(sujets[0])}, {dq(sujets[1])}, {dq(texte)})")
for lg,(s,t) in Lt.RELANCE.items():
    seg_rows.append(f"    ({q('relance_'+lg)}, {q(lg)}, 'relance', {dq(s)}, {dq(s)}, {dq(t)})")
lang_rows = [f"    ({q(lg)}, {dq(Lt.SIG[lg])}, {dq(Lt.RAISON[lg])}, {dq(Lt.ALT[lg])})" for lg in ('fr','en','ar')]
rows = []; attendu = []
for l in P['lignes']:
    lg = l['langue']; cle = 'relance_'+lg if l['type']=='relance' else l['segment']
    img = l['image'] and l['type']=='lettre'
    rows.append(f"    ({q(l['email'])}, {q(cle)}, {q(l['segment'])}, {l['variante']}, {'true' if img else 'false'}, {'true' if not l['image'] else 'false'}, {q(l['prochaine_tentative'])}::timestamptz, {q(l['ref'])})")
    lien = f"https://rewayahacademy.com/{lg}/familles?ref={l['ref']}"
    if l['type']=='lettre':
        _, sj, tx = Lt.SEG[l['segment']]; sujet = sj[l['variante']]
    else:
        sujet, tx = Lt.RELANCE[lg]
    attendu.append((l['email'], hashlib.md5(sujet.encode()).hexdigest(), hashlib.md5(Lt.corps(lg, tx, lien).encode()).hexdigest(), img))
sql = f"""-- PROSPECTION-V3, jour 1 (lundi 30/11/2026). « Vas-y » du directeur, 27/11/2026.
-- 1. Les 79 lettres longues mises en pause au 31/12 par le pilote (categorie direction, sans lien de
--    desinscription, ancien texte) sont annulees : elles ne partiront jamais.
-- 2. 100 lettres courtes (79 premieres lettres et 21 relances uniques de la vague du 22/11), categorie
--    `nouvelles` (non essentielle) par courriel_enfiler : jeton de desinscription, et rien n'est enfile pour
--    une adresse desinscrite. Langue = langue du texte. Heure d'envoi posee ligne par ligne (paquets de
--    taille aleatoire, heures ouvrables du destinataire). Une lettre sur cinq environ sans image (temoin).
-- Version compacte (27/11/2026) : chaque texte n'est ecrit qu'une fois (textes de docs/prospection/v3/lettres.py),
-- la lettre est composee ici ; le contenu envoye est le meme que celui de la premiere version de ce fichier.
-- Aucune suppression. Rejouable : la cle d'idempotence empeche un doublon.
DO $prospection$
DECLARE
  v_n integer;
  v_id uuid;
  r record;
BEGIN
  SELECT count(*) INTO v_n FROM public.courriels_sortants
   WHERE origine = 'manuel' AND modele = 'message_libre' AND categorie = 'direction'
     AND statut = 'en_attente' AND prochaine_tentative = '2026-12-31 08:00:00+00';
  IF v_n NOT IN (0, 79) THEN
    RAISE EXCEPTION 'prospection-v3 : % lettres en pause au lieu de 79, rien n''est fait', v_n;
  END IF;
  UPDATE public.courriels_sortants
     SET statut = 'annule', derniere_erreur = 'remplacee par la prospection v3 (directeur, 27/11/2026)'
   WHERE origine = 'manuel' AND modele = 'message_libre' AND categorie = 'direction'
     AND statut = 'en_attente' AND prochaine_tentative = '2026-12-31 08:00:00+00';

  FOR r IN
    WITH textes(cle, langue, type, sujet_a, sujet_b, texte) AS (VALUES
{(","+chr(10)).join(seg_rows)}
    ), langues(langue, signature, raison, alt) AS (VALUES
{(","+chr(10)).join(lang_rows)}
    ), plan(adresse, cle, segment, variante, image, temoin, quand, ref) AS (VALUES
{(","+chr(10)).join(rows)}
    )
    SELECT p.adresse, t.langue, p.quand, 'prospection-v3:' || p.adresse AS cle_idem,
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'sujet', CASE WHEN p.variante = 0 THEN t.sujet_a ELSE t.sujet_b END,
        'corps', pg_catalog.replace(t.texte, '{{lien}}',
                   'https://rewayahacademy.com/' || t.langue || '/familles?ref=' || p.ref)
                 || pg_catalog.chr(10) || pg_catalog.chr(10) || l.signature,
        'langue_source', t.langue, 'raison', l.raison, 'campagne', 'prospection-v3',
        'type', t.type, 'segment', p.segment, 'temoin_sans_image', p.temoin,
        'image', CASE WHEN p.image THEN pg_catalog.jsonb_build_object(
                   'src', 'https://rewayahacademy.com/fr/assets/courriel-prospection-' || t.langue || '.png',
                   'alt', l.alt, 'largeur', 600, 'hauteur', 315) END)) AS donnees
      FROM plan p JOIN textes t ON t.cle = p.cle JOIN langues l ON l.langue = t.langue
  LOOP
    v_id := public.courriel_enfiler('nouvelles', 'message_libre', r.adresse, NULL, r.donnees, r.cle_idem, 'manuel', NULL);
    IF v_id IS NOT NULL THEN
      UPDATE public.courriels_sortants SET langue = r.langue, prochaine_tentative = r.quand WHERE id = v_id;
    END IF;
  END LOOP;
END;
$prospection$;
"""
open(sys.argv[1], 'w').write(sql)
json.dump(attendu, open('attendu.json','w'))
print(len(rows), len(sql))
