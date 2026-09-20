-- 0029 — Fermer `dossiers_en_attente()` : une fuite d'identites a `anon`
--
-- ============================================================
-- CE QUI A ETE MESURE, ET CE QUI SORTAIT
-- ============================================================
--
-- Trouve pendant le controle pre-fusion du lot Enseignant, en cherchant si la
-- lecon de `0028` avait des cousines ailleurs dans le schema. Ce n'est PAS un
-- defaut du lot Enseignant : la fonction date de `0015` et la faute est
-- anterieure a `BASELINE_SHA`. Elle est corrigee ici parce qu'une fuite vivante
-- d'identites ne se met pas en file d'attente derriere un decoupage de lots.
--
-- Mesure du 20 septembre 2026, en role `anon` sur `gggmtelinlpseweouyav` :
--
--   set local role anon;
--   select count(*) from public.dossiers_en_attente();   -->  4 lignes
--
-- et le contenu de ces lignes portait `first_name`, `last_name`,
-- `immutable_id`, `role` et `account_status` de chaque personne en attente de
-- verification. La cle publiable `anon` est embarquee dans le bundle web servi :
-- la fonction etait donc joignable par `POST /rest/v1/rpc/dossiers_en_attente`
-- sans aucun compte. `last_name` est precisement ce qu'ADR-008 interdit de
-- montrer meme a un enseignant authentifie.
--
-- ============================================================
-- POURQUOI LA PORTE NE S'EST PAS FERMEE
-- ============================================================
--
-- La porte s'ecrivait comme un refus :
--
--   if public.app_role() <> 'admin' then raise exception ... end if;
--
-- Pour un appelant anonyme, `app_role()` rend NULL. `NULL <> 'admin'` vaut NULL,
-- et `if NULL then` ne se declenche pas : l'execution continue, et la fonction
-- etant `security definer`, elle lit ensuite `profiles` avec les droits du
-- proprietaire, RLS comprise. La porte etait donc grande ouverte precisement
-- pour l'appelant qu'elle devait arreter — un garde-fou qui ne refuse que les
-- gens qui ont un role.
--
-- C'est le MEME defaut que `brouillon_cahier` portait et que `0026` a corrige,
-- a la difference pres qui compte : `brouillon_cahier` ne se fermait que par
-- accident, parce que `app_account_valid()` rend un `false` franc, tandis
-- qu'ici aucune autre condition ne rattrapait le NULL.
--
-- Balayage fait, et c'est le seul cas vivant : 31 fonctions `security definer`
-- du schema portent cette forme de porte (`app_role() <> '...'` en refus), et
-- `dossiers_en_attente()` est la SEULE que `anon` pouvait executer. Les 30
-- autres ne sont protegees que par leur `revoke`, ce qui est une defense de
-- moins que ce que le depot croit avoir. Dette inscrite au lot G-02.
--
-- ============================================================
-- LES DEUX CORRECTIFS, ET POURQUOI LES DEUX
-- ============================================================
--
-- 1. La porte devient une EXIGENCE POSITIVE enveloppee de `coalesce(..., false)`
--    — toute inconnue ferme au lieu d'ouvrir. C'est le correctif de fond : la
--    fonction devient sure quel que soit le role qui peut l'appeler.
-- 2. Le droit d'EXECUTE est retire a `anon` ET a `PUBLIC`, par les deux formules
--    que `0028` a etablies comme necessaires ensemble. C'est la defense en
--    profondeur : si la porte etait un jour reecrite en refus par inadvertance,
--    l'appelant anonyme n'atteindrait meme pas la porte.
--
-- Rien d'autre ne change. Le corps est repris de `pg_get_functiondef()` lu sur
-- la base, a la porte pres, pour que `create or replace` ne fasse pas regresser
-- le masquage d'observation (`agent_identite_masquee()`) ni la lecture bornee
-- des pieces (`read_kyc_documents()`) poses par `0015` et `0016`.
--
-- Aucun ecran ne change de comportement : `admin_dossiers` appelle cette RPC en
-- `authenticated` avec `app_role() = 'admin'`, ce que l'exigence positive
-- autorise exactement comme le refus l'autorisait. `agent_ro` garde son droit,
-- la fonction etant en lecture seule.

create or replace function public.dossiers_en_attente()
returns table (
  profile_id uuid,
  immutable_id text,
  first_name text,
  last_name text,
  role public.app_role,
  account_status public.account_status,
  inscrit_le timestamptz,
  document_id uuid,
  doc_type text,
  document_gender public.gender,
  object_key text,
  depose_le timestamptz,
  etat_piece text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_en_attente int;
  v_masque boolean := public.agent_identite_masquee();
begin
  -- Exigence POSITIVE, jamais un refus : `app_role()` rend NULL pour un
  -- appelant anonyme, et un refus ecrit `<> 'admin'` ne se declenche pas sur
  -- NULL. Le `coalesce` fait que toute inconnue ferme la porte.
  if not coalesce(public.app_role() = 'admin', false) then
    raise exception 'validation des dossiers reservee a l''administration'
      using errcode = '42501';
  end if;

  select count(*) into v_en_attente
  from public.kyc_documents k
  where k.status = 'pending' and k.deleted_at is null;

  if v_en_attente = 0 then
    return query
      select p.id, p.immutable_id,
        case when v_masque then null else p.first_name end,
        case when v_masque then null else p.last_name end,
        p.role, p.account_status, p.created_at,
        null::uuid, null::text, null::public.gender, null::text,
        null::timestamptz, 'aucune'::text
      from public.profiles p
      where p.deleted_at is null and p.account_status = 'pending_kyc'
      order by p.created_at asc;
    return;
  end if;

  return query
    with visibles as (
      select k.* from public.read_kyc_documents() k where k.status = 'pending'
    )
    select p.id, p.immutable_id,
      case when v_masque then null else p.first_name end,
      case when v_masque then null else p.last_name end,
      p.role, p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      case
        when v.id is not null then 'a_verifier'
        when exists (
          select 1 from public.kyc_documents k2
          where k2.profile_id = p.id and k2.status = 'pending'
            and k2.deleted_at is null
        ) then 'non_visible'
        else 'aucune'
      end::text
    from public.profiles p
    left join visibles v on v.profile_id = p.id
    where p.deleted_at is null
      and (p.account_status = 'pending_kyc' or v.id is not null)
    order by coalesce(v.created_at, p.created_at) asc;
end;
$$;

comment on function public.dossiers_en_attente() is
  'ADM-02 : file des dossiers a verifier, reservee a l''administration. Porte ecrite en exigence positive enveloppee de coalesce (0029) : un appelant sans role est refuse, la ou un refus << <> admin >> le laissait passer sur NULL.';

-- Les deux formules sont necessaires ensemble, cf. `0028` :
-- `from public` retire le defaut de PostgreSQL, `from anon` retire le droit
-- nominal pose par `alter default privileges` de Supabase.
revoke all on function public.dossiers_en_attente() from public;
revoke all on function public.dossiers_en_attente() from anon;
grant execute on function public.dossiers_en_attente() to authenticated;
grant execute on function public.dossiers_en_attente() to agent_ro;
grant execute on function public.dossiers_en_attente() to service_role;
