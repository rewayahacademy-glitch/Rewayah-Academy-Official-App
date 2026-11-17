-- COM-COMPTE-OFFICIEL (17/11/2026) : private.com_participant rend `officiel` (booleen) pour la nature « profil ».
-- A rejouer sur une base NEUVE apres toutes les migrations ; transaction annulee.
\set ON_ERROR_STOP on
BEGIN;
INSERT INTO auth.users(id, email) VALUES ('e1000000-0000-4000-8000-0000000000a1','co-ens@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES ('e1000000-0000-4000-8000-0000000000a1','CO-ENS-0001','teacher','Maryam','Co','provisional_active','female');

DO $t$
DECLARE
  v_praxis jsonb := private.com_participant('profil', '9ae15000-0000-4000-8000-000000000001'::uuid, 'classe', NULL);
  v_autre  jsonb := private.com_participant('profil', 'e1000000-0000-4000-8000-0000000000a1'::uuid, 'classe', NULL);
  v_equipe jsonb := private.com_participant('equipe', NULL, 'classe', NULL);
BEGIN
  IF v_praxis -> 'officiel' IS DISTINCT FROM 'true'::jsonb THEN RAISE EXCEPTION 'Praxis doit etre officiel : %', v_praxis; END IF;
  IF v_autre -> 'officiel' IS DISTINCT FROM 'false'::jsonb THEN RAISE EXCEPTION 'un enseignant ne doit pas etre officiel : %', v_autre; END IF;
  IF v_praxis ->> 'compte_officiel' IS DISTINCT FROM 'praxis' THEN RAISE EXCEPTION 'Praxis doit porter le code praxis : %', v_praxis; END IF;
  IF NOT (v_autre ? 'compte_officiel') OR v_autre ->> 'compte_officiel' IS NOT NULL THEN RAISE EXCEPTION 'une personne doit porter compte_officiel nul : %', v_autre; END IF;
  IF v_autre ->> 'prenom' <> 'Maryam' OR v_autre ->> 'fonction' <> 'enseignant' OR v_autre ->> 'nature' <> 'profil' THEN
    RAISE EXCEPTION 'cles existantes alterees : %', v_autre;
  END IF;
  IF v_equipe ->> 'nature' <> 'equipe' THEN RAISE EXCEPTION 'participant equipe altere : %', v_equipe; END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure), '''nouveau'',') = 0 THEN
    RAISE EXCEPTION 'la cle nouveau de com_fil_json a disparu';
  END IF;
END
$t$;
ROLLBACK;
\echo OK com_compte_officiel
