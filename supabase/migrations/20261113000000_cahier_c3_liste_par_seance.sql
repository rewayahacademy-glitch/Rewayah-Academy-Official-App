-- CAHIER-C3, LISTE « CAHIERS A REMPLIR » PAR SEANCE (07/11/2026).
-- Reservation : plage 20261113000000-20261113999999, accordee par le pilote
-- le 07/11/2026 (regle du garde-cap : toute version reservee avant d'etre
-- ecrite). Plan accepte par le garde-cap le 07/11/2026.
--
-- Pourquoi. La paie d'une seance est liberee par un cahier de CETTE seance
-- (08 §5 bis ligne 126, decision du directeur du 05/11), a partir de la date
-- de coupure `private.cahier_c3_coupure()` (20261110620000). Or la liste de
-- l'enseignant, `public.mes_rapports_en_attente()`, ne montre qu'UNE seance
-- par Classe et par semaine : 20261110620000 ne peut pas s'installer
-- utilement (sa condition : « la liste montre chaque seance qui bloque la
-- paie »).
--
-- Ce que fait cette migration :
--   1. `public.mes_rapports_en_attente()` REMPLACEE, meme signature, memes
--      colonnes, meme garde. Les seances commencees AVANT la coupure gardent la
--      regle d'aujourd'hui (une ligne par Classe et par semaine) ; a partir de
--      la coupure, UNE LIGNE PAR SEANCE non couverte : exactement celles que
--      `private.pai_releve_seances` met « en attente » et que le bouton de
--      seance lit, par la meme regle `private.cahier_semaine_couvert`.
--   2. Le reglage `cahier.echeance_heures` = 24 dans `app_config` (garde-cap,
--      Q1) : un rappel seulement, SANS effet sur la paie.
--   3. `public.mes_cahiers_echeances()` NEUVE (garde-cap, Q2 : RPC voisine,
--      sans suppression de fonction) : pour chaque ligne de la liste, l'echeance du rappel
--      (`ended_at` + `cahier.echeance_heures`) et `par_seance` (Q3 : la seance
--      est soumise a la regle par seance), que le client lit pour ses textes.
--      Lecture seule (STABLE) : AF-LB n'est pas concerne.
--
-- ORDRE D'INSTALLATION (accepte par le garde-cap) :
--   (i)   20261110620000 telle quelle, coupure au 2100-01-01 : aucun effet ;
--   (ii)  cette migration : la liste reste hebdomadaire tant que la coupure
--         est en 2100 ;
--   (iii) le jour de la mise en production, la seule ligne qui remplace
--         `private.cahier_c3_coupure()` par la date reelle : la paie et la
--         liste basculent ENSEMBLE.
-- Le preflight refuse de s'installer sans `private.cahier_c3_coupure()`.
--
-- COUPURE STABLE (garde-cap, 07/11/2026, retouche 1). 20261110620000 cree
-- `private.cahier_c3_coupure()` IMMUTABLE : une fonction IMMUTABLE peut etre
-- evaluee une fois pour toutes au plan, et un plan garde en cache dans une
-- connexion du pool garderait 2100 apres la bascule (paie et liste ne
-- basculeraient pas ensemble). Cette migration la passe STABLE (ALTER
-- FUNCTION, sans changer son corps) et le postflight le verifie.
-- Le geste du jour J reste STABLE. LIGNE EXACTE A COLLER CE JOUR-LA (seule la
-- date change ; la date est celle de la mise en production) :
--   CREATE OR REPLACE FUNCTION private.cahier_c3_coupure() RETURNS timestamptz LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$ SELECT 'AAAA-MM-JJ 00:00:00+00'::timestamptz $function$;
-- (CREATE OR REPLACE garde le proprietaire et les droits ; ecrire IMMUTABLE
-- a la place de STABLE referait le defaut corrige ici.)
--
-- Fonction remplacee : `public.mes_rapports_en_attente()`, preflight
-- md5(prosrc) = 15f60858bab478148f74b4e31bb655d5 (PRODUCTION, lu par le pilote
-- le 07/11/2026 a 11:27 ; meme valeur sur une base nue rejouant le depot).
-- Lecteurs : client `ServiceEnseignantSupabase` (cahiersEnRetardProvider),
-- `mes_cahiers_echeances` (ci-dessous). Memes colonnes, meme sens avant la
-- coupure.
--
-- Fichier SANS mot d'effacement en instruction (B5). Pas de BEGIN/COMMIT de
-- premier niveau.

-- Preflight ---------------------------------------------------------------------

DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  IF pg_catalog.to_regprocedure('private.cahier_c3_coupure()') IS NULL THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : private.cahier_c3_coupure() absente : installer 20261110620000 d''abord';
  END IF;
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.mes_rapports_en_attente()'::pg_catalog.regprocedure;
  IF v_md5 IS DISTINCT FROM '15f60858bab478148f74b4e31bb655d5'
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                      WHERE p.oid = 'public.mes_rapports_en_attente()'::pg_catalog.regprocedure
                        AND p.prosrc LIKE '%CAHIER-C3-LISTE%') THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : mes_rapports_en_attente differe de la production (md5 %), migration a revoir', v_md5;
  END IF;
END;
$preflight$;

-- 0. La coupure STABLE (retouche 1 du garde-cap) ------------------------------------

ALTER FUNCTION private.cahier_c3_coupure() STABLE;

-- 1. Le reglage du rappel ----------------------------------------------------------

INSERT INTO public.app_config (key, value)
VALUES ('cahier.echeance_heures', '24'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- 2. La liste, par seance a partir de la coupure ----------------------------------

CREATE OR REPLACE FUNCTION public.mes_rapports_en_attente()
 RETURNS TABLE(session_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, groupe_id uuid, groupe_libelle text, nb_participants integer, heures_de_retard integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.groupe_id,
    g.libelle,
    count(distinct sp.profile_id) filter (
      where sp.role = 'student' and sp.deleted_at is null
    )::int,
    greatest(0, (extract(epoch from (now() - s.ended_at)) / 3600)::int)
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
    left join public.session_participants sp on sp.session_id = s.id
  where s.deleted_at is null
    -- CAHIER-REMPLACANT : l'enseignant effectif de la seance (C-29).
    and (s.teacher_id = auth.uid()
         or exists (select 1 from public.remplacements_seance x
                     where x.session_id = s.id and x.enseignant_remplacant_id = auth.uid()))
    and private.c29_enseignant_effectif_session(s.id) = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid()
    -- Une seance annulee, ou l'enseignant ne s'est pas presente, ne doit aucun
    -- cahier : il n'y a rien a transmettre.
    and s.status in ('ended', 'student_absent', 'tech_failure')
    and s.ended_at < now()
    -- CAHIER-HEBDOMADAIRE : chaque eleve de la seance figure dans un cahier
    -- de la Classe cette semaine-la (fuseau de la Classe). A partir de la
    -- coupure C3, le cahier de la seance elle-meme (meme regle que la paie).
    and not private.cahier_semaine_couvert(s.id)
    -- CAHIER-C3-LISTE : a partir de la coupure, une ligne PAR SEANCE (chaque
    -- seance qui bloque la paie). Avant la coupure, une ligne par Classe et
    -- par semaine : la derniere seance non couverte parmi celles dont
    -- l'appelant est l'enseignant effectif.
    and (
      s.started_at >= private.cahier_c3_coupure()
      or not exists (
        select 1 from public.sessions s2
         where s.groupe_id is not null
           and s2.groupe_id = s.groupe_id
           and s2.id <> s.id
           and s2.deleted_at is null
           and s2.started_at < private.cahier_c3_coupure()
           and private.c29_enseignant_effectif_session(s2.id) = auth.uid()
           and s2.status in ('ended', 'student_absent', 'tech_failure')
           and s2.ended_at < now()
           and s2.ended_at > s.ended_at
           and pg_catalog.date_trunc('week', s2.started_at at time zone g.timezone_iana)
               = pg_catalog.date_trunc('week', s.started_at at time zone g.timezone_iana)
           and not private.cahier_semaine_couvert(s2.id)
      )
    )
  group by s.id, s.started_at, s.ended_at, s.groupe_id, g.libelle
  order by s.ended_at asc;
$function$;

-- 3. L'echeance du rappel et la regle de chaque ligne ----------------------------------

CREATE OR REPLACE FUNCTION public.mes_cahiers_echeances()
RETURNS TABLE(session_id uuid, echeance timestamptz, par_seance boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  -- Les memes lignes que la liste (meme garde : enseignant effectif, compte
  -- valide), une par seance rendue par `mes_rapports_en_attente`.
  SELECT r.session_id,
         -- Retouche 2 du garde-cap : une valeur non entiere saisie dans la
         -- console ne casse pas la RPC, elle vaut 24.
         r.ended_at + pg_catalog.make_interval(hours => coalesce(
           (SELECT CASE WHEN (c.value #>> '{}') ~ '^[0-9]{1,3}$'
                        THEN (c.value #>> '{}')::integer END
              FROM public.app_config c
             WHERE c.key = 'cahier.echeance_heures'), 24)),
         r.started_at >= private.cahier_c3_coupure()
    FROM public.mes_rapports_en_attente() r;
$function$;

COMMENT ON FUNCTION public.mes_cahiers_echeances() IS
  'CAHIER-C3-LISTE (07/11/2026) : pour chaque seance de mes_rapports_en_attente, l''echeance du rappel (ended_at + app_config cahier.echeance_heures, 24 h ; un rappel, sans effet sur la paie) et par_seance (la seance suit la regle par seance, a partir de private.cahier_c3_coupure()).';

ALTER FUNCTION public.mes_cahiers_echeances() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mes_cahiers_echeances() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_cahiers_echeances() TO authenticated;

-- Postflight ------------------------------------------------------------------------

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.mes_rapports_en_attente()'::pg_catalog.regprocedure
                    AND p.prosecdef
                    AND p.proconfig @> ARRAY['search_path=""']
                    AND p.prosrc LIKE '%CAHIER-C3-LISTE%'
                    AND p.prosrc LIKE '%app_account_valid%'
                    AND p.prosrc LIKE '%c29_enseignant_effectif_session%') THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : mes_rapports_en_attente n''a pas la forme attendue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.mes_cahiers_echeances()'::pg_catalog.regprocedure
                    AND p.prosecdef
                    AND p.provolatile = 's'
                    AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : mes_cahiers_echeances n''a pas la forme attendue';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.mes_cahiers_echeances()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_cahiers_echeances()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : droits de mes_cahiers_echeances inattendus';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.cahier_c3_coupure()'::pg_catalog.regprocedure
                    AND p.provolatile = 's') THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : private.cahier_c3_coupure() doit etre STABLE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'cahier.echeance_heures') THEN
    RAISE EXCEPTION 'CAHIER-C3-LISTE : reglage cahier.echeance_heures absent';
  END IF;
END;
$postflight$;
