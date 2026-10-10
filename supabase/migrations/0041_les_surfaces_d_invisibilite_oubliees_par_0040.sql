-- 0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql
-- Ferme les surfaces d'invisibilite que 0040 a laissees ouvertes.
--
-- CE QUI S'EST PASSE. 0040 a ajoute 'guardian_observer' a la liste des roles
-- masques de `autoriser_jeton_video` : le tuteur observateur a disparu de la
-- GALERIE LIVEKIT. Mais la meme liste a deux elements
-- (`masked_controller`, `admin_masked`) est recopiee dans SEPT autres objets de
-- la base, et 0040 n'en a touche aucun. Le jeton disait « masque » pendant que
-- PostgREST rendait le tuteur en clair.
--
-- `docs/teaching-core/TC_CONTRACT_REQUEST_G.md` nomme ces surfaces « les quatre
-- surfaces d'invisibilite » et ecrit, mot pour mot : « une surface oubliee est
-- une fuite ». Elle l'etait.
--
-- CE QUE CETTE MIGRATION FERME, ET CE QU'ELLE NE FERME PAS. Les sept objets
-- n'exposent pas tous la meme population. Chacun a ete MESURE avant d'etre
-- touche ou laisse :
--
--   | objet                                  | lisible par un AUTRE enfant ? | ici |
--   |----------------------------------------|-------------------------------|-----|
--   | vue session_peers_v                    | OUI -- tout participant       | OUI |
--   | est_observateur_masque (3 policies     | OUI -- un autre TUTEUR du     | OUI |
--   |   de session_events)                   |   groupe, via family_read     |     |
--   | vue presence_seance_v                  | non -- son WHERE n'admet que  | non |
--   |                                        |   admin/controleur/enseignant |     |
--   |                                        |   /foyer/soi-meme             |     |
--   | session_participants_controller_read   | non -- role controleur        | non |
--   | session_participants_teacher_read      | non -- role enseignant        | non |
--   | session_participants_family_read       | non -- deja borne au foyer    | non |
--   | rejoindre_observation                  | non -- pas une liste          | non |
--
-- Les quatre « non » ne sont pas des oublis : aucun n'expose un enfant a un
-- autre foyer, et les rouvrir couterait un risque de regression sans gain de
-- vie privee. Ils sont ecrits ici pour que la prochaine session n'ait pas a
-- refaire la mesure.
--
-- ============================================================================
-- A. session_peers_v -- LA fuite vers les autres enfants
-- ============================================================================
--
-- La vue rend a CHAQUE participant la liste des autres, avec `peer_id`,
-- `first_name` et `immutable_id`. Mesure : proprietaire `postgres`
-- (`rolbypassrls = true`), `reloptions = {security_barrier=true}` SANS
-- `security_invoker` -- la RLS de `session_participants` et de `profiles` ne
-- s'applique donc pas a sa requete. `authenticated` a le SELECT.
--
-- Consequence chiffree : dans un groupe de cinq, le tuteur du foyer A entre en
-- observation, et les quatre autres enfants obtiennent son UUID et son PRENOM
-- par un simple `GET /rest/v1/session_peers_v?session_id=eq.<S>`. C'est
-- l'inverse exact de la regle, et c'est pire que ce que 0040 a corrige : la
-- galerie ne montrait qu'une presence, celle-ci donne une identite.

create or replace view public.session_peers_v as
 select distinct sp.session_id,
    p2.id as peer_id,
    p2.first_name,
    p2.immutable_id
   from public.session_participants sp
     join public.session_participants sp2 using (session_id)
     join public.profiles p2 on p2.id = sp2.profile_id
  where sp.profile_id = auth.uid()
    and sp.deleted_at is null
    and sp2.deleted_at is null
    and p2.deleted_at is null
    and sp2.profile_id <> sp.profile_id
    -- `guardian_observer` REJOINT la liste. Le tuteur observateur n'est pas un
    -- pair : il ne participe pas au cours, il le regarde deux minutes.
    and ((sp2.role <> all (array['masked_controller'::public.participant_role,
                                 'admin_masked'::public.participant_role,
                                 'guardian_observer'::public.participant_role]))
         or public.app_role() = 'admin'::public.app_role);

-- ============================================================================
-- B. est_observateur_masque -- un seul point, trois policies fermees
-- ============================================================================
--
-- Elle repond « cette personne observe-t-elle en masque ? » et trois policies
-- de `session_events` s'en servent en `NOT est_observateur_masque(...)` :
-- `session_events_family_read`, `_teacher_read`, `_controller_read`.
--
-- Le defaut est dans `family_read` : elle ouvre a tout `guardian` pour qui
-- `session_in_household(session_id, app_household_id())` est vrai. Le tuteur du
-- foyer B, dont l'enfant est dans le meme groupe, satisfait cette condition ;
-- les evenements `joined`/`left` du tuteur du foyer A ne lui sont pas masques.
-- Il apprend donc qu'un AUTRE parent observe, et a quelle seconde.
--
-- La regle du 21/09 borne la visibilite a l'enfant concerne et a l'enseignant.
-- Un autre tuteur n'est ni l'un ni l'autre.
--
-- Corriger ICI plutot que dans les trois policies : c'est le meme defaut a un
-- seul endroit, et trois listes recopiees finiraient par diverger -- c'est
-- exactement ce qui a produit celui-la.

create or replace function public.est_observateur_masque(
  p_session_id uuid, p_profile_id uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id
      and sp.profile_id = p_profile_id
      and sp.role in ('masked_controller', 'admin_masked', 'guardian_observer')
      and sp.deleted_at is null
  );
$$;

-- Droits a l'identique de ce qui a ete releve avant d'ecrire : `authenticated`
-- l'a, `anon` ne l'a pas. Les DEUX instructions, jamais le seul revoke.
revoke execute on function public.est_observateur_masque(uuid, uuid) from public, anon;
grant execute on function public.est_observateur_masque(uuid, uuid) to authenticated;

-- ============================================================================
-- C. L'annonce de l'enfant s'allume pour LES DEUX enfants d'un meme foyer
-- ============================================================================
--
-- LE DEFAUT. `entrer_observation` choisit l'enfant annonce par un
-- `select ... limit 1` SANS `order by` (etape 3). Rien n'interdit a un foyer
-- d'avoir deux enfants dans le meme groupe -- le pivot du 19/09 en autorise
-- cinq. Postgres rend alors l'un des deux, arbitrairement : le temoin s'allume
-- chez E1 et JAMAIS chez E2, que le parent regarde tout autant.
--
-- LA CORRECTION EST ICI, PAS DANS `entrer_observation`. Rendre le `limit 1`
-- deterministe ne rendrait pas la reponse juste, seulement stable : il faudrait
-- toujours choisir un enfant la ou le parent en regarde deux. La bonne question
-- n'est pas « suis-je l'enfant DESIGNE de cette visite ? » mais « quelqu'un de
-- MON foyer observe-t-il ce cours ? » -- c'est exactement ce que l'enfant a le
-- droit de savoir, et c'est vrai pour les deux freres.
--
-- LA BORNE DE VIE PRIVEE NE FAIBLIT PAS, elle change de forme :
-- `est_du_foyer(v.observateur_profile_id)` teste `household_id =
-- app_household_id()`, donc un enfant d'un AUTRE foyer obtient faux. L'ancienne
-- clause est conservee en `or` : elle est plus etroite, elle ne peut rien
-- ouvrir, et elle garde lisible l'intention d'origine.
-- Si le jeton ne porte pas de foyer, `app_household_id()` est nul et la porte
-- se FERME -- jamais l'inverse.

create or replace function public.annonce_observation_pour_moi(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_depuis timestamptz;
begin
  -- Porte d'entree, en EXIGENCE POSITIVE. Avec auth.uid() nul, `not exists`
  -- est vrai et la porte se FERME.
  if not exists (
    select 1
      from public.sessions s
      join public.groupe_membres m
        on m.groupe_id = s.groupe_id
       and m.left_at is null
     where s.id = p_session_id
       and s.deleted_at is null
       and m.student_id = auth.uid()
       and public.app_account_valid()
  ) then
    raise exception 'reserve a l''eleve du groupe de cette seance'
      using errcode = 'insufficient_privilege';
  end if;

  -- LE VERROU DE VIE PRIVEE, en deux clauses qui disent la meme chose de deux
  -- facons : la visite me designe, OU son observateur est de mon foyer. La
  -- seconde couvre le cas de deux freres dans le meme groupe, que la premiere
  -- manquait. Aucune des deux n'atteint un autre foyer.
  select v.entered_at into v_depuis
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.role = 'guardian_observer'
     and v.left_at is null
     and (
       v.enfant_profile_id = auth.uid()
       or public.est_du_foyer(v.observateur_profile_id)
     )
   order by v.entered_at desc
   limit 1;

  -- Deux faits, pas un de plus. Ni identite de l'observateur, ni numero de
  -- visite, ni compteur : un compteur renseignerait sur les autres foyers.
  return jsonb_build_object(
    'observe', v_depuis is not null,
    'depuis',  v_depuis
  );
end;
$$;

revoke execute on function public.annonce_observation_pour_moi(uuid) from public, anon, agent_ro;
grant execute on function public.annonce_observation_pour_moi(uuid) to authenticated;

-- ============================================================================
-- D. assister_seance : la seconde porte, fermee
-- ============================================================================
--
-- `assister_seance(uuid)` inscrit l'appelant en `guardian_observer` dans
-- `session_participants` et S'ARRETE LA : elle n'appelle ni
-- `budget_observation`, ni `politique_observation_effective`, et n'insere
-- AUCUNE ligne `guardian_session_visit`. Mesure : son corps en production ne
-- contient aucun de ces trois noms.
--
-- CE QUE CELA DONNE, tant qu'elle reste ouverte a `authenticated` :
--   * les quotas sont contournes -- `budget_observation` compte visites et
--     temps exclusivement depuis `guardian_session_visit`. Sans ligne de
--     visite : 0 visite, 0 seconde, `peut_entrer` vrai a CHAQUE appel. Les
--     « deux visites de deux minutes » de la regle produit ne s'appliquent pas ;
--   * l'observation devient SILENCIEUSE -- `annonces_observation` et
--     `annonce_observation_pour_moi` lisent toutes deux
--     `guardian_session_visit`. Ni l'enseignant ni l'enfant n'apprennent rien ;
--   * et depuis 0040, le jeton pose `hidden = true`. Le tuteur observe donc
--     masque, sans quota et sans que personne ne le sache. La regle est violee
--     dans l'autre sens.
--
-- Elle existait pour le bouton « Assister », qui passe desormais par
-- `entrer_observation` (laquelle fait la meme inscription ET verifie le lien
-- tuteur-enfant, la politique du groupe et le quota). Elle n'a plus AUCUN
-- appelant : `grep assisterEnTuteur` sur `lib/` ne rend que sa declaration.
--
-- La fonction n'est pas SUPPRIMEE, seulement fermee : un `drop` casserait les
-- doubles de test qui l'implementent encore, et le droit est ce qui decide.

revoke execute on function public.assister_seance(uuid) from public, anon, authenticated, agent_ro;

-- ============================================================================
-- Controle de sortie -- chaque controle est ecrit en EXIGENCE POSITIVE.
-- ============================================================================
do $$
declare
  v_def  text;
  v_oid  oid;
begin
  -- A. session_peers_v masque le tuteur observateur.
  v_def := pg_catalog.pg_get_viewdef('public.session_peers_v'::regclass, true);
  if v_def not like '%guardian_observer%' then
    raise exception '0041 incomplete : session_peers_v ne masque pas guardian_observer';
  end if;
  -- Et elle masque TOUJOURS les deux autres : une liste qui perd un role est
  -- une fuite de la meme famille.
  if v_def not like '%masked_controller%' or v_def not like '%admin_masked%' then
    raise exception '0041 incomplete : session_peers_v a PERDU un role masque';
  end if;
  -- L'echappatoire admin doit survivre, sinon l'administration perd la liste.
  if v_def not like '%admin%' then
    raise exception '0041 incomplete : session_peers_v a perdu l''echappatoire admin';
  end if;
  if not pg_catalog.has_table_privilege('authenticated', 'public.session_peers_v', 'select') then
    raise exception '0041 incomplete : authenticated a PERDU le SELECT sur session_peers_v';
  end if;
  if pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select') then
    raise exception '0041 incomplete : anon a gagne le SELECT sur session_peers_v';
  end if;

  -- B. est_observateur_masque reconnait les TROIS roles.
  v_oid := to_regprocedure('public.est_observateur_masque(uuid, uuid)')::oid;
  if v_oid is null then
    raise exception '0041 incomplete : est_observateur_masque est absente';
  end if;
  select p.prosrc into v_def from pg_catalog.pg_proc p where p.oid = v_oid;
  if v_def not like '%guardian_observer%' then
    raise exception '0041 incomplete : est_observateur_masque ignore guardian_observer';
  end if;
  if v_def not like '%masked_controller%' or v_def not like '%admin_masked%' then
    raise exception '0041 incomplete : est_observateur_masque a PERDU un role';
  end if;
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 's' then
    raise exception '0041 incomplete : est_observateur_masque n''est plus stable';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0041 incomplete : authenticated a perdu EXECUTE sur est_observateur_masque';
  end if;
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0041 incomplete : anon garde EXECUTE sur est_observateur_masque';
  end if;
  -- Les trois policies qui s'en servent doivent toujours exister : la corriger
  -- ne sert a rien si plus personne ne l'appelle.
  if (select count(*) from pg_catalog.pg_policy p
       join pg_catalog.pg_class c on c.oid = p.polrelid
      where c.relname = 'session_events'
        and coalesce(pg_catalog.pg_get_expr(p.polqual, p.polrelid), '')
            like '%est_observateur_masque%') <> 3 then
    raise exception '0041 incomplete : les policies de session_events ne consomment plus est_observateur_masque';
  end if;

  -- C. L'annonce de l'enfant couvre le foyer, sans ouvrir aux autres.
  v_oid := to_regprocedure('public.annonce_observation_pour_moi(uuid)')::oid;
  select p.prosrc into v_def from pg_catalog.pg_proc p where p.oid = v_oid;
  if v_def not like '%est_du_foyer(v.observateur_profile_id)%' then
    raise exception '0041 incomplete : l''annonce enfant ne couvre pas le second enfant du foyer';
  end if;
  if v_def not like '%v.enfant_profile_id = auth.uid()%' then
    raise exception '0041 incomplete : l''annonce enfant a perdu son verrou d''origine';
  end if;
  -- Toujours aucun agregat : le nombre d'observateurs reste inaccessible.
  if v_def like '%jsonb_agg%' or v_def like '%count(%' then
    raise exception '0041 incomplete : l''annonce enfant agrege';
  end if;
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0041 incomplete : anon garde EXECUTE sur annonce_observation_pour_moi';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0041 incomplete : authenticated a perdu EXECUTE sur annonce_observation_pour_moi';
  end if;

  -- D. La seconde porte est fermee, des DEUX chemins.
  v_oid := to_regprocedure('public.assister_seance(uuid)')::oid;
  if v_oid is null then
    raise exception '0041 incomplete : assister_seance a disparu -- on la ferme, on ne la supprime pas';
  end if;
  if pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0041 incomplete : assister_seance reste appelable par authenticated';
  end if;
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0041 incomplete : assister_seance reste appelable par anon';
  end if;

  -- E. L'acquis de 0040 survit : le jeton masque toujours le tuteur.
  if (select p.prosrc from pg_catalog.pg_proc p
       join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = 'autoriser_jeton_video')
     not like '%''guardian_observer'')%' then
    raise exception '0041 incomplete : autoriser_jeton_video ne masque plus guardian_observer (acquis 0040)';
  end if;
end $$;
