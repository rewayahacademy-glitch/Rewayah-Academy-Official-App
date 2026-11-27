import json, sys
import lettres as Lt
P = json.load(open('plan_jour1.json'))
def q(s): return "'" + s.replace("'", "''") + "'"
rows = []
for l in P['lignes']:
    lg = l['langue']; lien = f"https://rewayahacademy.com/{lg}/familles?ref={l['ref']}"
    if l['type'] == 'lettre':
        _, sujets, texte = Lt.SEG[l['segment']]; sujet = sujets[l['variante']]
    else:
        sujet, texte = Lt.RELANCE[lg]
    d = {'sujet': sujet, 'corps': Lt.corps(lg, texte, lien), 'langue_source': lg, 'raison': Lt.RAISON[lg],
         'campagne': 'prospection-v3', 'type': l['type'], 'segment': l['segment'], 'temoin_sans_image': not l['image']}
    if l['image'] and l['type'] == 'lettre':
        d['image'] = {'src': f'https://rewayahacademy.com/fr/assets/courriel-prospection-{lg}.png', 'alt': Lt.ALT[lg], 'largeur': 600, 'hauteur': 315}
    rows.append(f"    ({q(l['email'])}, {q(lg)}, {q(json.dumps(d, ensure_ascii=False))}::jsonb, {q(l['prochaine_tentative'])}::timestamptz, {q('prospection-v3:'+l['email'])})")
sql = f"""-- PROSPECTION-V3, jour 1 (lundi 30/11/2026). « Vas-y » du directeur, 27/11/2026.
-- 1. Les 79 lettres longues mises en pause au 31/12 par le pilote (categorie direction, sans lien de
--    desinscription, ancien texte) sont annulees : elles ne partiront jamais.
-- 2. 100 lettres courtes (79 premieres lettres et 21 relances uniques de la vague du 22/11), categorie
--    `nouvelles` (non essentielle) par courriel_enfiler : jeton de desinscription, et rien n'est enfile pour
--    une adresse desinscrite. Langue = langue du texte. Heure d'envoi posee ligne par ligne (paquets de
--    taille aleatoire, heures ouvrables du destinataire). 20 % sans image (temoin).
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

  FOR r IN SELECT * FROM (VALUES
{(","+chr(10)).join(rows)}
  ) AS t(adresse, langue, donnees, quand, cle) LOOP
    v_id := public.courriel_enfiler('nouvelles', 'message_libre', r.adresse, NULL, r.donnees, r.cle, 'manuel', NULL);
    IF v_id IS NOT NULL THEN
      UPDATE public.courriels_sortants SET langue = r.langue, prochaine_tentative = r.quand WHERE id = v_id;
    END IF;
  END LOOP;
END;
$prospection$;
"""
open(sys.argv[1], 'w').write(sql)
print(len(rows), len(sql))
