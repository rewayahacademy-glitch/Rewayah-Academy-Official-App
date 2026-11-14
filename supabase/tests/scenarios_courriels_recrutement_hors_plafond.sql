-- COURRIELS-RECRUTEMENT-HORS-PLAFOND (14/11/2026, migration 20261126100000) :
-- les messages individuels du recrutement ne sont jamais retenus par le
-- plafond des envois non essentiels, et partent avant les envois en nombre
-- (lien_inscription) deja en file.
-- Prouve, plafond regle a 1 par jour (le minimum admis) :
--   1. les cinq modeles du recrutement partent tous, au premier lot ;
--   2. un seul lien_inscription part (le plafond tient pour les envois en
--      nombre) ;
--   3. avec un lot plus petit que la file, les modeles hors plafond passent
--      AVANT les lien_inscription plus anciens.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HORS-PLAFOND ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Reserve un lot comme le travailleur (service_role) et rend les modeles.
CREATE FUNCTION pg_temp.reserver(p_lot integer) RETURNS text[]
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.courriels_reserver(p_lot);
  EXECUTE 'RESET ROLE';
  UPDATE public.courriels_sortants s SET statut = 'envoye', envoye_le = now()
   WHERE s.id IN (SELECT (e->>'id')::uuid FROM jsonb_array_elements(v) e);
  RETURN ARRAY(SELECT e->>'modele' FROM jsonb_array_elements(v) e);
END $$;

UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'courriels.non_essentiels_par_jour';
-- La file reelle : des envois en nombre plus anciens, puis les messages du
-- recrutement.
UPDATE public.courriels_sortants SET statut = 'envoye', reserve_le = now() - interval '2 days'
 WHERE statut IN ('en_attente', 'envoi') OR reserve_le > now() - interval '24 hours';
SELECT public.courriel_enfiler('recrutement', 'lien_inscription', 'hp-' || g || '@test.invalid', NULL,
         '{}'::jsonb, 'hp-lien-' || g)
  FROM generate_series(1, 30) g;
UPDATE public.courriels_sortants SET prochaine_tentative = now() - interval '2 days'
 WHERE modele = 'lien_inscription' AND statut = 'en_attente';
SELECT public.courriel_enfiler('recrutement', m, 'hp-dir-' || m || '@test.invalid', NULL,
         '{}'::jsonb, 'hp-' || m)
  FROM unnest(ARRAY['entretien_reserve', 'entretien_rappel', 'entretien_rappel_direction',
                    'entretien_tenu', 'message_candidat_recu']) AS m;

SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants WHERE statut = 'en_attente') = 35,
  'la file : 30 lien_inscription anciens et 5 messages du recrutement');

-- 3. Un lot de 5 : ce sont les messages du recrutement, pas les anciens liens.
SELECT pg_temp.vrai(
  (SELECT array_agg(x ORDER BY x) FROM unnest(pg_temp.reserver(5)) x)
    = ARRAY['entretien_rappel', 'entretien_rappel_direction', 'entretien_reserve',
            'entretien_tenu', 'message_candidat_recu'],
  '1 et 3. les cinq messages du recrutement partent, avant les liens plus anciens');

-- 2. Le plafond (1) tient pour les envois en nombre : un seul lien part.
SELECT set_config('test.partis', cardinality(pg_temp.reserver(50))::text, true);
SELECT pg_temp.vrai(current_setting('test.partis') = '1'
  AND (SELECT count(*) FROM public.courriels_sortants
        WHERE modele = 'lien_inscription' AND statut = 'en_attente') = 29,
  '2. un seul lien_inscription part : le plafond tient pour les envois en nombre');

ROLLBACK;
