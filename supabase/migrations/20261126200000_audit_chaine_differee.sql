-- PERF-AUDIT (pilote, 14/11/2026, par delegation du directeur) : plus de
-- verrou de table a chaque ecriture auditee.
--
-- Constat (production, lecture seule, 14/11/2026) : public.log_sensitive_access,
-- appelee par 235 fonctions, faisait
--   LOCK TABLE public.audit_logs IN SHARE ROW EXCLUSIVE MODE
-- pour chainer chaque ligne a la precedente. Ce verrou court jusqu'a la FIN de
-- la transaction appelante : toutes les ecritures auditees de l'application
-- passaient une par une, et une transaction lente bloquait tout le monde
-- (14:45:02 UTC : un enregistrement de reponses de candidat attend 1,4 s ce
-- verrou, apres huit « statement timeout » dans la meme seconde a 14:44:45).
--
-- Conditions du pilote : audit_logs reste append-only ; la chaine reste
-- complete et verifiable par verifier_chaine_audit ; aucun trou ni doublon dans
-- la chaine ; aucune ligne d'audit perdue.
--
-- Methode (une cause, un fichier) :
--   1. app_private.audit_empreinte : l'empreinte du CONTENU d'une ligne, la meme
--      formule qu'avant (acteur, role, action, table, ligne, charge).
--   2. log_sensitive_access insere SANS verrou : hash = empreinte du contenu,
--      prev_hash = 'differe' (jamais un hash hexadecimal : c'est le marqueur
--      d'une ligne chainee plus tard). audit_logs garde ses deux declencheurs
--      append-only, aucun UPDATE n'est jamais fait sur elle.
--   3. app_private.audit_chaine : la chaine, dans une table a part, elle aussi
--      append-only (declencheurs), en RLS sans aucun droit client. Un rang sans
--      trou ; le rang 0 est l'ancre, le dernier hash de l'ancienne chaine (celle
--      qui vit dans audit_logs.prev_hash/hash jusqu'a cette migration).
--   4. private.audit_chainer : chaque minute (pg_cron), un seul executant
--      (pg_try_advisory_xact_lock), chaine les lignes differees validees, dans
--      l'ordre ou il les voit (id croissant dans un lot) ; il recalcule
--      l'empreinte depuis le contenu, sans se fier a la colonne hash.
--   5. verifier_chaine_audit garde sa signature et son contrat : l'ancienne
--      chaine se verifie comme avant ; une ligne differee se verifie par son
--      empreinte de contenu ET par son maillon (lien au rang precedent, hash du
--      maillon) ; une ligne differee non chainee depuis plus de 5 minutes est
--      rompue ; un maillon dont la ligne a disparu est rompu (et nomme la ligne
--      disparue).
--
-- Ce qui change, dit : pendant au plus une minute, une ligne n'est pas encore
-- chainee (seul un superutilisateur pourrait la retoucher dans ce delai ; il
-- peut deja recalculer toute la chaine). « Sans trou » vaut pour le rang de la
-- chaine, pas pour audit_logs.id (une sequence a des trous a chaque annulation,
-- deja avant).
--
-- Mots : cette migration contient le mot DELETE dans la definition d'un
-- declencheur qui INTERDIT l'effacement (BEFORE DELETE), comme audit_logs ;
-- elle n'efface rien. Aucun DROP, aucun TRUNCATE. Sans BEGIN ni COMMIT de
-- premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regnamespace('app_private') IS NULL
     OR pg_catalog.to_regnamespace('private') IS NULL THEN
    RAISE EXCEPTION 'PERF-AUDIT : schemas app_private ou private absents, arret';
  END IF;
  IF pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('public.verifier_chaine_audit(integer)') IS NULL THEN
    RAISE EXCEPTION 'PERF-AUDIT : log_sensitive_access ou verifier_chaine_audit absente, arret';
  END IF;
END;
$preflight$;

-- 1. L'empreinte du contenu.
CREATE OR REPLACE FUNCTION app_private.audit_empreinte(
  p_actor uuid, p_actor_role text, p_action text, p_table_name text, p_row_id text, p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.encode(extensions.digest(pg_catalog.convert_to(
    coalesce(p_actor::text, '') || coalesce(p_actor_role, '') || p_action ||
    p_table_name || coalesce(p_row_id, '') || p_payload::text, 'UTF8'), 'sha256'), 'hex')
$function$;
ALTER FUNCTION app_private.audit_empreinte(uuid, text, text, text, text, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.audit_empreinte(uuid, text, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;
COMMENT ON FUNCTION app_private.audit_empreinte(uuid, text, text, text, text, jsonb) IS
  'PERF-AUDIT : empreinte sha256 du contenu d''une ligne d''audit (meme formule que log_sensitive_access avant le 14/11/2026).';

-- 2. La chaine.
CREATE TABLE IF NOT EXISTS app_private.audit_chaine (
  rang bigint PRIMARY KEY CHECK (rang >= 0),
  audit_id bigint,
  audit_cree_le timestamptz,
  prev_hash text NOT NULL,
  hash text NOT NULL,
  chaine_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CHECK ((audit_id IS NULL) = (audit_cree_le IS NULL)),
  CHECK (rang = 0 OR audit_id IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS audit_chaine_ligne_uq
  ON app_private.audit_chaine (audit_id, audit_cree_le) WHERE rang > 0;
ALTER TABLE app_private.audit_chaine ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.audit_chaine FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON TABLE app_private.audit_chaine IS
  'PERF-AUDIT : chaine de hachage du journal d''audit, append-only, remplie chaque minute par private.audit_chainer. Rang 0 = ancre (dernier hash de l''ancienne chaine dans audit_logs).';

CREATE OR REPLACE FUNCTION app_private.audit_chaine_immuable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'audit_chaine est append-only';
END;
$function$;
ALTER FUNCTION app_private.audit_chaine_immuable() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.audit_chaine_immuable() FROM PUBLIC, anon, authenticated;

DO $declencheurs$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                  WHERE tgrelid = 'app_private.audit_chaine'::pg_catalog.regclass
                    AND tgname = 'audit_chaine_immuable') THEN
    CREATE TRIGGER audit_chaine_immuable
      BEFORE UPDATE OR DELETE ON app_private.audit_chaine
      FOR EACH ROW EXECUTE FUNCTION app_private.audit_chaine_immuable();
  END IF;
END;
$declencheurs$;


-- 3. L'ecriture, sans verrou.
CREATE OR REPLACE FUNCTION public.log_sensitive_access(
  p_action text, p_table_name text, p_row_id text, p_payload jsonb DEFAULT '{}'::jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
declare
  v_actor uuid := auth.uid();
  v_role text := public.app_role()::text;
begin
  -- PERF-AUDIT (14/11/2026) : plus de verrou de table. La ligne porte
  -- l'empreinte de son contenu ; le maillon de chaine est pose dans la minute
  -- par private.audit_chainer (app_private.audit_chaine).
  insert into public.audit_logs (actor, actor_role, action, table_name, row_id, payload, prev_hash, hash)
  values (
    v_actor, v_role, p_action, p_table_name, p_row_id, p_payload, 'differe',
    app_private.audit_empreinte(v_actor, v_role, p_action, p_table_name, p_row_id, p_payload)
  );
end;
$function$;

-- L'ancre : le dernier maillon de l'ancienne chaine (ordre de verifier_chaine_audit).
-- log_sensitive_access est deja remplacee : plus aucune ligne de l'ancienne
-- chaine ne s'ecrit. Le verrou attend la fin d'une ecriture ancienne en cours,
-- pour que l'ancre soit bien le dernier maillon (LOCK dans un DO : une seule
-- transaction, aussi sous psql en validation automatique).
DO $ancre$
BEGIN
  LOCK TABLE public.audit_logs IN SHARE ROW EXCLUSIVE MODE;
  INSERT INTO app_private.audit_chaine (rang, audit_id, audit_cree_le, prev_hash, hash)
  SELECT 0, d.id, d.created_at, 'ancre', coalesce(d.hash, '')
    FROM (SELECT NULL::bigint) AS vide(x)
    LEFT JOIN LATERAL (
      SELECT a.id, a.created_at, a.hash
        FROM public.audit_logs a
       WHERE a.prev_hash <> 'differe'
       ORDER BY a.created_at DESC, a.id DESC
       LIMIT 1) d ON true
  ON CONFLICT (rang) DO NOTHING;
END;
$ancre$;

-- 4. Le chainage, chaque minute.
CREATE OR REPLACE FUNCTION private.audit_chainer()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_rang bigint;
  v_prec text;
  v_depuis timestamptz;
  v_n integer := 0;
  v_digest text;
  r record;
BEGIN
  -- Un seul executant : un second passage simultane ne fait rien.
  IF NOT pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtext('rewayah:audit_chaine')) THEN
    RETURN 0;
  END IF;
  SELECT c.rang, c.hash INTO v_rang, v_prec
    FROM app_private.audit_chaine c ORDER BY c.rang DESC LIMIT 1;
  IF v_rang IS NULL THEN
    RAISE EXCEPTION 'PERF-AUDIT : chaine sans ancre';
  END IF;
  -- Une ligne differee pas encore chainee a un created_at (debut de SA
  -- transaction) au plus une heure avant le dernier maillon pose : on ne relit
  -- que cette fenetre. Une ligne qui y echapperait n'est pas perdue :
  -- verifier_chaine_audit la signale apres 5 minutes.
  SELECT coalesce(pg_catalog.max(c.audit_cree_le), '-infinity'::timestamptz) - interval '1 hour'
    INTO v_depuis FROM app_private.audit_chaine c;
  FOR r IN
    SELECT a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name, a.row_id, a.payload
      FROM public.audit_logs a
     WHERE a.created_at >= v_depuis
       AND a.prev_hash = 'differe'
       AND NOT EXISTS (SELECT 1 FROM app_private.audit_chaine c
                        WHERE c.audit_id = a.id AND c.audit_cree_le = a.created_at AND c.rang > 0)
     ORDER BY a.id
     LIMIT 5000
  LOOP
    v_digest := app_private.audit_empreinte(r.actor, r.actor_role, r.action, r.table_name, r.row_id, r.payload);
    v_rang := v_rang + 1;
    INSERT INTO app_private.audit_chaine (rang, audit_id, audit_cree_le, prev_hash, hash)
    VALUES (v_rang, r.id, r.created_at, v_prec,
            pg_catalog.encode(extensions.digest(pg_catalog.convert_to(v_prec || v_digest, 'UTF8'), 'sha256'), 'hex'))
    RETURNING hash INTO v_prec;
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$function$;
ALTER FUNCTION private.audit_chainer() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.audit_chainer() FROM PUBLIC, anon, authenticated;
COMMENT ON FUNCTION private.audit_chainer() IS
  'PERF-AUDIT : pose les maillons de chaine des lignes d''audit differees (pg_cron, chaque minute, un seul executant).';

-- 5. La verification, meme signature, meme contrat.
CREATE OR REPLACE FUNCTION public.verifier_chaine_audit(p_limite integer DEFAULT 200)
RETURNS TABLE(verifiees integer, rompues integer, premiere_rompue bigint, rompue_le timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 5000 then
    raise exception 'limite hors bornes';
  end if;

  return query
  with fenetre as (
    select a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name,
           a.row_id, a.payload, a.prev_hash, a.hash,
           a.prev_hash = 'differe' as differee,
           app_private.audit_empreinte(a.actor, a.actor_role, a.action, a.table_name,
                                       a.row_id, a.payload) as empreinte
    from public.audit_logs a
    order by a.created_at desc, a.id desc
    limit p_limite + 1
  ),
  -- L'ancienne chaine (lignes d'avant le 14/11/2026), controlee comme avant.
  ancienne as (
    select f.id,
           f.hash = encode(extensions.digest(convert_to(f.prev_hash || f.empreinte, 'UTF8'), 'sha256'), 'hex')
           and (lag(f.hash) over (order by f.created_at, f.id) is null
                or f.prev_hash = lag(f.hash) over (order by f.created_at, f.id)) as intacte
    from fenetre f
    where not f.differee
  ),
  -- Les maillons des lignes de la fenetre, a partir du predecesseur du plus ancien.
  maillons as (
    select c.rang, c.audit_id, c.audit_cree_le, c.prev_hash, c.hash,
           lag(c.hash) over (order by c.rang) as hash_precedent,
           lag(c.rang) over (order by c.rang) as rang_precedent
    from app_private.audit_chaine c
    where c.rang >= coalesce(
      (select pg_catalog.min(c2.rang) - 1 from app_private.audit_chaine c2
         join fenetre f2 on f2.id = c2.audit_id and f2.created_at = c2.audit_cree_le
        where c2.rang > 0),
      (select pg_catalog.max(c3.rang) from app_private.audit_chaine c3))
  ),
  controle_maillons as (
    select m.rang, m.audit_id, m.audit_cree_le, a.id is not null as ligne_presente,
           case
             when m.rang = 0 then
               (m.audit_id is null and m.hash = '') or a.hash = m.hash
             else
               (m.hash_precedent is null
                  or (m.prev_hash = m.hash_precedent and m.rang = m.rang_precedent + 1))
               and m.hash = encode(extensions.digest(convert_to(m.prev_hash ||
                     app_private.audit_empreinte(a.actor, a.actor_role, a.action, a.table_name,
                                                 a.row_id, a.payload), 'UTF8'), 'sha256'), 'hex')
           end as maillon_ok
    from maillons m
    left join public.audit_logs a on a.id = m.audit_id and a.created_at = m.audit_cree_le
  ),
  controle as (
    select f.id, f.created_at,
           case
             when not f.differee then (select an.intacte from ancienne an where an.id = f.id)
             else f.hash = f.empreinte
                  and coalesce(
                        (select cm.maillon_ok from controle_maillons cm
                          where cm.audit_id = f.id and cm.audit_cree_le = f.created_at and cm.rang > 0),
                        -- Pas encore chainee : normale pendant 5 minutes, rompue ensuite.
                        f.created_at > pg_catalog.now() - interval '5 minutes')
           end as intacte
    from (select * from fenetre order by created_at desc, id desc limit p_limite) f
  ),
  -- Un maillon dont la ligne a disparu : la ligne effacee se nomme elle-meme.
  disparues as (
    select cm.audit_id as id, cm.audit_cree_le as created_at
    from controle_maillons cm
    where not cm.ligne_presente and cm.audit_id is not null
  ),
  rompues as (
    select k.id, k.created_at from controle k where not k.intacte
    union all
    select d.id, d.created_at from disparues d
  )
  select
    (select count(*) from controle)::int,
    (select count(*) from rompues)::int,
    (select min(r.id) from rompues r),
    (select min(r.created_at) from rompues r);
end;
$function$;

-- 6. La planification.
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $c$SELECT cron.schedule('audit_chaine', '* * * * *', 'SELECT private.audit_chainer()')$c$;
  ELSE
    RAISE NOTICE 'PERF-AUDIT : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

-- 7. Postflight.
DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.lower(pg_catalog.pg_get_functiondef(
       'public.log_sensitive_access(text,text,text,jsonb)'::pg_catalog.regprocedure)), 'lock table') > 0 THEN
    RAISE EXCEPTION 'PERF-AUDIT : log_sensitive_access verrouille encore la table';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM app_private.audit_chaine WHERE rang = 0) THEN
    RAISE EXCEPTION 'PERF-AUDIT : ancre absente';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'app_private.audit_chaine', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'private.audit_chainer()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.audit_chainer()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PERF-AUDIT : droit client inattendu sur la chaine';
  END IF;
END;
$postflight$;
