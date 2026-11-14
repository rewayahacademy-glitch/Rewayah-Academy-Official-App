-- SERVEUR-PETITS, point A (13/11/2026) : fermer la fuite du matricule par
-- public.session_peers_v (constat SEC-6, docs/current/salle/CONSTAT.md ;
-- journal D-040 fin et D-042).
--
-- Le fait : la definition en vigueur (20261017120100_af_l1_08_reprise_gardes_vues.sql,
-- l. 111-122, aucune migration plus recente ne la redefinit) rend a TOUT
-- participant d'une seance le prenom ET le matricule (immutable_id) des autres
-- participants. L'application ne lit pas cette vue (grep lib/ et
-- supabase/functions/ : rien, hors un commentaire de
-- lib/core/widgets/avatar_tile.dart), mais un appel direct la lit.
--
-- Ce que fait ce fichier, et rien d'autre : CREATE OR REPLACE de la vue, de
-- MEME forme (memes colonnes, memes noms, memes types, meme ordre), memes
-- options (security_barrier = true, pas de security_invoker : la vue reste
-- executee avec les droits de son proprietaire, postgres), memes lignes (meme
-- FROM, meme WHERE). Seule la colonne immutable_id change : elle vaut NULL sauf
-- pour
--   - la direction et le controleur (app_role() lu du JWT, comme la vue
--     presence_seance_v) ;
--   - l'enseignant de la seance : le titulaire (sessions.teacher_id) et
--     l'enseignant effectif d'un remplacement (dernier evenement de
--     remplacements_seance = remplacement_pris ou remplacement_designe_admin,
--     exactement la lecture de private.c29_enseignant_effectif_session, recopiee
--     en sous-requete : une fonction appelee dans une vue s'execute avec les
--     droits du LECTEUR, et authenticated n'a pas EXECUTE sur cette fonction
--     privee ; la table, elle, est lue avec les droits du proprietaire de la vue) ;
--   - la personne elle-meme (p2.id = auth.uid()). La vue n'a aujourd'hui aucune
--     ligne pour soi (sp2.profile_id <> sp.profile_id) : la clause est une
--     garantie, pas un changement de lignes.
-- Le prenom reste (decision du directeur du 12/11/2026, D-040 : les eleves
-- d'une classe se lisent par leur prenom), y compris la substitution par le
-- matricule pour une session agent masquee (0047, inchangee).
--
-- Lecteurs de la vue verifies (13/11/2026) : aucune vue ni fonction des
-- migrations ne la lit ; scenarios_agt01.sql (A8) et scenarios_ctr01.sql
-- (C4, C5) la lisent par first_name et count(*), jamais par immutable_id.
--
-- Aucun droit nouveau, aucun droit retire : les droits de la vue sont compares
-- avant et apres (relacl et has_table_privilege). Additif, rejouable, dans une
-- transaction, aucun mot d'effacement : applicable par apply_migration (retirer
-- BEGIN et COMMIT).

begin;

-- Les noms de la vue ci-dessous sont ecrits sans schema, comme dans sa
-- definition precedente (20261017120100) : le meme chemin de recherche.
set local search_path = public;

-- ------------------------------------------------------------------
-- 0. Avant : la forme, les options, le proprietaire et les droits en vigueur
-- ------------------------------------------------------------------
do $avant$
declare
  v_colonnes text;
  v_options text;
  v_droits text;
begin
  select string_agg(column_name || ':' || data_type, ',' order by ordinal_position)
    into v_colonnes
    from information_schema.columns
   where table_schema = 'public' and table_name = 'session_peers_v';
  if v_colonnes is distinct from 'session_id:uuid,peer_id:uuid,first_name:text,immutable_id:text' then
    raise exception 'SEC-6 preflight : forme inattendue de session_peers_v : %', coalesce(v_colonnes, '(absente)');
  end if;
  select coalesce(array_to_string(c.reloptions, ','), '')
    into v_options
    from pg_catalog.pg_class c where c.oid = 'public.session_peers_v'::pg_catalog.regclass;
  if v_options is distinct from 'security_barrier=true' then
    raise exception 'SEC-6 preflight : options inattendues de session_peers_v : %', v_options;
  end if;
  if (select pg_catalog.pg_get_userbyid(c.relowner) from pg_catalog.pg_class c
       where c.oid = 'public.session_peers_v'::pg_catalog.regclass) <> 'postgres' then
    raise exception 'SEC-6 preflight : session_peers_v n''appartient pas a postgres';
  end if;
  select coalesce(c.relacl::text, '') into v_droits
    from pg_catalog.pg_class c where c.oid = 'public.session_peers_v'::pg_catalog.regclass;
  -- Garde pour le bloc final (meme transaction).
  perform pg_catalog.set_config('sec6.colonnes', v_colonnes, true);
  perform pg_catalog.set_config('sec6.options', v_options, true);
  perform pg_catalog.set_config('sec6.droits', v_droits, true);
  perform pg_catalog.set_config('sec6.lecture',
    concat_ws(',',
      pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('service_role', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'insert'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'update'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'insert'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'update')),
    true);
end
$avant$;

-- ------------------------------------------------------------------
-- 1. La vue : meme forme, memes lignes, matricule borne
-- ------------------------------------------------------------------
create or replace view public.session_peers_v with (security_barrier = true) as
 SELECT DISTINCT sp.session_id,
    p2.id AS peer_id,
        CASE
            WHEN agent_identite_masquee() THEN p2.immutable_id
            ELSE p2.first_name
        END AS first_name,
        CASE
            WHEN (app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role]))
              OR p2.id = auth.uid()
              OR (( SELECT s.teacher_id
                      FROM sessions s
                     WHERE s.id = sp.session_id)) = auth.uid()
              OR (( SELECT
                        CASE
                            WHEN r.evenement = ANY (ARRAY['remplacement_pris'::text, 'remplacement_designe_admin'::text]) THEN r.enseignant_remplacant_id
                            ELSE NULL::uuid
                        END AS enseignant_remplacant_id
                      FROM remplacements_seance r
                     WHERE r.session_id = sp.session_id
                     ORDER BY r.cree_le DESC, r.id DESC
                    LIMIT 1)) = auth.uid()
            THEN p2.immutable_id
            ELSE NULL::text
        END AS immutable_id
   FROM session_participants sp
     JOIN session_participants sp2 USING (session_id)
     JOIN profiles p2 ON p2.id = sp2.profile_id
  WHERE (select public.app_account_valid()) AND sp.profile_id = auth.uid() AND sp.deleted_at IS NULL AND sp2.deleted_at IS NULL AND p2.deleted_at IS NULL AND sp2.profile_id <> sp.profile_id AND ((sp2.role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role, 'guardian_observer'::participant_role])) OR app_role() = 'admin'::app_role);

comment on view public.session_peers_v is
  'Pairs d''une seance pour un participant. SEC-6 (SERVEUR-PETITS, 13/11/2026, D-042) : '
  'le prenom pour tous (D-040) ; le matricule (immutable_id) seulement pour la direction, '
  'le controleur, l''enseignant de la seance (titulaire ou remplacant effectif) et la personne elle-meme, NULL sinon.';

-- ------------------------------------------------------------------
-- 2. Apres : forme, options, proprietaire, droits et gardes inchanges
-- ------------------------------------------------------------------
do $apres$
declare
  v_colonnes text;
  v_options text;
  v_droits text;
  v_lecture text;
  v_def text := pg_catalog.pg_get_viewdef('public.session_peers_v'::pg_catalog.regclass, true);
begin
  select string_agg(column_name || ':' || data_type, ',' order by ordinal_position)
    into v_colonnes
    from information_schema.columns
   where table_schema = 'public' and table_name = 'session_peers_v';
  if v_colonnes is distinct from current_setting('sec6.colonnes') then
    raise exception 'SEC-6 postflight : colonnes changees : % au lieu de %', v_colonnes, current_setting('sec6.colonnes');
  end if;
  select coalesce(array_to_string(c.reloptions, ','), ''), coalesce(c.relacl::text, '')
    into v_options, v_droits
    from pg_catalog.pg_class c where c.oid = 'public.session_peers_v'::pg_catalog.regclass;
  if v_options is distinct from current_setting('sec6.options') then
    raise exception 'SEC-6 postflight : options changees : %', v_options;
  end if;
  if v_droits is distinct from current_setting('sec6.droits') then
    raise exception 'SEC-6 postflight : droits changes : % au lieu de %', v_droits, current_setting('sec6.droits');
  end if;
  v_lecture := concat_ws(',',
      pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('service_role', 'public.session_peers_v', 'select'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'insert'),
      pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'update'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'insert'),
      pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'update'));
  if v_lecture is distinct from current_setting('sec6.lecture') then
    raise exception 'SEC-6 postflight : has_table_privilege change : % au lieu de %', v_lecture, current_setting('sec6.lecture');
  end if;
  if pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select') then
    raise exception 'SEC-6 postflight : anon lit session_peers_v';
  end if;
  if pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'insert')
     or pg_catalog.has_table_privilege('agent_ro', 'public.session_peers_v', 'update') then
    raise exception 'SEC-6 postflight : agent_ro peut ecrire dans session_peers_v';
  end if;
  if (select pg_catalog.pg_get_userbyid(c.relowner) from pg_catalog.pg_class c
       where c.oid = 'public.session_peers_v'::pg_catalog.regclass) <> 'postgres' then
    raise exception 'SEC-6 postflight : proprietaire change';
  end if;
  -- Les gardes des lots precedents (0041, 0047, L1-08) sont toujours la.
  if pg_catalog.strpos(v_def, 'app_account_valid') = 0
     or pg_catalog.strpos(v_def, 'agent_identite_masquee') = 0
     or pg_catalog.strpos(v_def, 'guardian_observer') = 0
     or pg_catalog.strpos(v_def, 'masked_controller') = 0
     or pg_catalog.strpos(v_def, 'admin_masked') = 0
     or pg_catalog.strpos(v_def, 'sp.profile_id = auth.uid()') = 0 then
    raise exception 'SEC-6 postflight : une garde anterieure de la vue a disparu';
  end if;
  -- Le matricule n'est plus rendu sans condition.
  if pg_catalog.strpos(v_def, 'ELSE NULL::text') = 0
     or pg_catalog.strpos(v_def, 'remplacements_seance') = 0 then
    raise exception 'SEC-6 postflight : le matricule n''est pas borne';
  end if;
end
$apres$;

commit;
