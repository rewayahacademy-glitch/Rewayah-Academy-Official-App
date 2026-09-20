-- 0027 — L'enseignant peut corriger les trois champs non sensibles de son profil
--
-- ECRITE APRES COUP, ET C'EST VOULU. Cette migration a ete APPLIQUEE sur le
-- projet `gggmtelinlpseweouyav` le 19 septembre 2026 (version
-- `20260919235846`) par l'agent E du lot Enseignant, sur autorisation explicite
-- de l'operateur. L'agent E ne pouvait pas deposer le fichier ici :
-- `supabase/migrations/**` appartient a l'Agent Z (`TEACHER_FILE_OWNERSHIP.md`
-- §1), et un agent metier n'ouvre pas le perimetre d'un autre, meme pour se
-- debloquer. Le fichier est donc ecrit par l'Agent Z a l'integration, et son
-- contenu est repris de `pg_get_functiondef()` lu sur la base, pas d'une
-- transcription : la CI rejoue les fichiers dans l'ordre sur une base neuve, et
-- une transcription approximative ferait raconter deux histoires differentes a
-- la base et au depot.
--
-- LE DEFAUT QU'ELLE CORRIGE, MESURE.
--
-- `creer_profil_inscription()` recoit `p_timezone` mais ne l'emploie que pour
-- `households` : pour un enseignant elle fait `insert into teacher_profiles
-- (profile_id)` et laisse le defaut de colonne `'Europe/Paris'`. La seule
-- policy du titulaire sur `teacher_profiles` est `teacher_profiles_self`, en
-- SELECT. Un enseignant hors d'Europe ne pouvait donc JAMAIS corriger son
-- fuseau, alors que `mon_fuseau()` fait loi sur sa grille de disponibilites
-- (`ENS-06`) : ses heures lui etaient affichees dans un fuseau qu'il ne
-- choisissait pas.
--
-- POURQUOI UNE FONCTION ET NON UNE POLICY `UPDATE`.
--
-- Une policy borne les LIGNES, pas les COLONNES — la lecon du lot PISI, et elle
-- s'applique telle quelle ici. Bornee a `profile_id = auth.uid()`, une policy
-- d'ecriture aurait laisse l'enseignant relever son propre `weekly_hours_cap`,
-- qui est contractuel, et toucher `kyc_status`. La fonction, elle, nomme les
-- trois colonnes qu'elle ecrit et ne peut pas en ecrire une quatrieme.
--
-- Fonction VOLATILE : aucun `grant execute` a `agent_ro`, jamais (regle maison,
-- `get_advisors` ne la detecte pas). Verifie apres application :
-- `has_function_privilege('agent_ro', ..., 'execute')` rend `false`.

create or replace function public.maj_profil_enseignant(
  p_country text default null,
  p_languages text[] default null,
  p_timezone text default null
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentification requise';
  end if;

  -- Le fuseau fait loi sur la grille de disponibilites : un libelle absent de
  -- la base de fuseaux casserait mon_fuseau() sans erreur visible. Il se
  -- verifie donc ici, pas a l'ecran.
  if p_timezone is not null
     and not exists (
       select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone
     ) then
    raise exception 'fuseau inconnu';
  end if;

  update public.teacher_profiles t
     set country = coalesce(p_country, t.country),
         languages = coalesce(p_languages, t.languages),
         timezone_iana = coalesce(p_timezone, t.timezone_iana)
   where t.profile_id = v_uid
     and t.deleted_at is null;

  if not found then
    raise exception 'aucun profil enseignant';
  end if;
end;
$$;

comment on function public.maj_profil_enseignant(text, text[], text) is
  'ENS-05 : ecriture bornee aux trois champs non sensibles du profil enseignant (pays, langues, fuseau). Jamais weekly_hours_cap ni kyc_status.';

revoke all on function public.maj_profil_enseignant(text, text[], text) from public;
grant execute on function public.maj_profil_enseignant(text, text[], text) to authenticated;
