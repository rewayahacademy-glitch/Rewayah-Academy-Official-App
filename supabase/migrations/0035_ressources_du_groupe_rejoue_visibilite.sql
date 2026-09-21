-- 0035_ressources_du_groupe_rejoue_visibilite.sql
-- Ferme un trou de visibilite dans le catalogue de la Bibliotheque.
--
-- LE DEFAUT. public.ressources_du_groupe(uuid), posee par 0033_tc_vues_rpc.sql
-- (lignes 742-779), est `security definer`. Aucune migration de ce depot ne pose
-- `force row level security` sur quoi que ce soit (verifie : zero occurrence dans
-- supabase/migrations), donc la fonction s'execute en proprietaire et la RLS de
-- public.library_resource ne s'applique pas a sa requete. Or sa porte d'entree ne
-- verifiait QUE l'appartenance au groupe (0033:750-764), et sa requete
-- (0033:766-774) ne portait aucun predicat sur r.access_policy et ne rejouait pas
-- public.app_account_valid(). Deux consequences :
--
--   1. Un eleve reellement membre du groupe recevait les ressources rattachees a
--      ce groupe en `enseignant_seul` et en `admin`. La policy de la table,
--      library_resource_lecture (0032_tc_catalogue.sql:151-178), reserve
--      `enseignant_seul` au g.teacher_id du groupe (0032:164) et `admin` au seul
--      public.app_role() = 'admin' (0032:154) : `admin` n'apparait meme pas dans
--      la liste des politiques ouvertes aux membres (0032:155 et 0032:157).
--   2. Un compte suspendu, supprime ou expire -- app_account_valid() faux,
--      definie en 0001_fondations.sql:412 -- passait quand meme, tant que sa ligne
--      groupe_membres restait ouverte (left_at nul). La policy, elle, exige
--      app_account_valid() en tete de sa clause USING (0032:153).
--
-- CE QUE LA FONCTION RENDAIT AVANT : toute ressource rattachee au groupe dont la
-- version courante est publiee et qui n'est pas archivee, quelle que soit sa
-- access_policy et quel que soit l'etat du compte appelant.
--
-- CE QU'ELLE REND APRES : la meme liste, filtree par la transcription mot pour
-- mot du predicat de library_resource_lecture (0032:153-177). La porte d'entree
-- exige en plus app_account_valid().
--
-- QUI PERD QUOI :
--   - L'eleve membre et le tuteur du foyer perdent les ressources du groupe en
--     `enseignant_seul` et en `admin`. Ils gardent `publique`, `inscrits` et
--     `groupe_assigne`.
--   - Tout compte dont app_account_valid() est faux perd l'acces entier a cette
--     RPC : il recoit desormais la meme erreur que le non-membre.
--   - L'enseignant du groupe et l'administration ne perdent RIEN.
--
-- LA DECISION. La question posee etait : branche conditionnelle pour que
-- l'enseignant et l'admin continuent de voir les ressources restreintes par cette
-- meme fonction, ou fonction reduite au fonds commun et surfaces enseignantes
-- ailleurs ? Reponse : branche conditionnelle, transcrite de la policy. La policy
-- de la table tranche deja -- elle ouvre `enseignant_seul` au teacher_id
-- (0032:164) et tout au role admin (0032:154) -- et c'est precisement d'avoir
-- deux regles differentes pour la meme donnee que ce defaut est ne. Couper la
-- fonction au fonds commun en creerait une troisieme. Le predicat ci-dessous est
-- donc une copie litterale de 0032:154-176, `library_resource` renomme `r`.
--
-- 0033 n'est PAS modifiee : elle est appliquee en production. On ecrit par-dessus.
-- Signature inchangee, donc `create or replace` conserve les droits existants ;
-- les deux instructions de droits sont neanmoins reecrites explicitement
-- ci-dessous, parce qu'un revoke de public/anon ne retire rien a `authenticated`
-- (Supabase lui accorde EXECUTE par un chemin independant).
-- La fonction reste `stable` et strictement en lecture : aucun ordre d'ecriture,
-- aucun appel volatile. C'est ce qui autorise `agent_ro` a la garder.

create or replace function public.ressources_du_groupe(p_groupe_id uuid)
returns setof public.library_resource
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  -- Porte d'entree, en EXIGENCE POSITIVE (`if not exists ... then raise`) :
  -- avec auth.uid() nul, un `if role <> 'x' then raise` ne se declencherait pas
  -- et ouvrirait la porte a `anon`. On exige en plus app_account_valid(), que
  -- 0033 avait omis et que la policy de la table impose (0032:153).
  if not exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and public.app_account_valid()
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  return query
    select r.*
      from public.library_resource r
      join public.library_resource_groupe lrg on lrg.resource_id = r.id
      join public.resource_version rv on rv.id = r.current_version_id
     where lrg.groupe_id = p_groupe_id
       and rv.statut = 'publiee'
       and r.archived_at is null
       -- Transcription litterale de library_resource_lecture (0032:154-176).
       -- Le sous-EXISTS n'est volontairement PAS borne a p_groupe_id : la policy
       -- ne le borne pas non plus, et deux regles differentes pour la meme
       -- donnee sont ce que cette migration repare.
       and (
         public.app_role() = 'admin'
         or r.access_policy in ('publique', 'inscrits')
         or (
           r.access_policy in ('groupe_assigne', 'enseignant_seul')
           and exists (
             select 1
               from public.library_resource_groupe lrg_policy
               join public.groupes g on g.id = lrg_policy.groupe_id
              where lrg_policy.resource_id = r.id
                and (
                  g.teacher_id = auth.uid()
                  or (
                    r.access_policy = 'groupe_assigne'
                    and exists (
                      select 1 from public.groupe_membres m
                      where m.groupe_id = g.id
                        and m.left_at is null
                        and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
                    )
                  )
                )
           )
         )
       )
     order by lrg.epinglee desc, r.title asc;
end;
$$;

-- Droits : a l'identique de 0033:778-779. Les DEUX instructions sont ecrites,
-- jamais le seul revoke : retirer EXECUTE a public et a anon ne retire rien a
-- `authenticated`, qui le tient d'un chemin independant.
revoke execute on function public.ressources_du_groupe(uuid) from public, anon;
grant execute on function public.ressources_du_groupe(uuid) to authenticated, agent_ro;

-- ============================================================================
-- Controle de sortie -- modele 0030_tc_socle.sql:218-230. Une migration qui ne
-- prend pas doit echouer bruyamment, jamais passer en silence.
-- ============================================================================
do $$
begin
  if to_regprocedure('public.ressources_du_groupe(uuid)') is null then
    raise exception 'ressources_du_groupe manquante apres 0035';
  end if;

  -- Le corps doit porter les deux verrous que cette migration ajoute.
  if not exists (
    select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'ressources_du_groupe'
       and p.prosrc like '%app_account_valid%'
       and p.prosrc like '%access_policy%'
  ) then
    raise exception '0035 incomplete : ressources_du_groupe ne rejoue pas la politique de visibilite';
  end if;

  -- La fonction doit rester en lecture seule : sans cela, agent_ro ne doit plus
  -- l'avoir (jamais de grant a agent_ro sur une fonction volatile).
  if not exists (
    select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'ressources_du_groupe'
       and p.provolatile = 's'
  ) then
    raise exception '0035 incomplete : ressources_du_groupe n''est plus stable';
  end if;

  -- EXECUTE arrive par deux chemins : verifier le retrait, pas seulement l'ecrire.
  if pg_catalog.has_function_privilege('anon', 'public.ressources_du_groupe(uuid)', 'execute') then
    raise exception '0035 incomplete : anon garde EXECUTE sur ressources_du_groupe';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', 'public.ressources_du_groupe(uuid)', 'execute') then
    raise exception '0035 incomplete : authenticated a perdu EXECUTE sur ressources_du_groupe';
  end if;
  if not pg_catalog.has_function_privilege('agent_ro', 'public.ressources_du_groupe(uuid)', 'execute') then
    raise exception '0035 incomplete : agent_ro a perdu EXECUTE sur ressources_du_groupe';
  end if;
end $$;
