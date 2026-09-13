-- 0012 : `CTR-01`, l'entree d'un controleur -- et les quatre surfaces ou son
-- invisibilite n'existait pas.
--
-- Perimetre fixe par docs/produit/parcours-utilisateurs.md section 4 (« Vue de
-- toutes les seances en cours et a venir [...] Chaque ligne en cours porte un
-- bouton d'entree invisible ») et par l'ADR-011, qui confirme la fonction pour
-- le MVP-0 et ecrit ce que le controleur peut et ne peut pas.
--
-- CE QUE CE LOT A TROUVE, ET QUE RIEN NE SIGNALAIT
--
--   1. **Aucune ligne `masked_controller` n'a jamais pu exister.** L'enum la
--      porte depuis 0001, `autoriser_jeton_video()` en deduit le drapeau
--      `hidden` depuis 0010, `presence_seance_v` la cache depuis 0011 -- mais
--      rien, nulle part, n'en ecrit une. Un controleur qui pressait « Observer »
--      recevait « non inscrit a cette seance » : la fonction confirmee par
--      l'ADR-011 etait inatteignable. C'est la lecon de N3 une troisieme fois :
--      **une plomberie sans ecran est une plomberie non testee.**
--
--   2. **Le plafond de participants comptait les temoins comme des eleves.**
--      `guard_session_participant_cap()` de 0001 compte toutes les lignes, quel
--      que soit le role, et le MVP-0 plafonne a deux. Un cours 1-to-1 est donc
--      plein : le controleur invisible ET le tuteur observateur de `TUT-01`
--      etaient refuses par le declencheur avant meme d'atteindre le jeton. La
--      specification d'etape 5 section 9 dit pourtant « les ecrans decrits ici
--      visent le 1-to-1, **le controleur en plus** » : le plafond borne le
--      groupe pedagogique, pas les temoins. La preuve que le defaut n'etait pas
--      theorique est dans `scenarios_n4.sql`, qui doit lever
--      `allow_multi_participant_sessions` pour poser ses propres fixtures.
--      Consequence non theorique : le bouton « Assister » de `TUT-01` est en
--      production depuis l'etape 4 et **echouait silencieusement** -- le tuteur
--      arrivait dans l'impasse d'acces de la salle, sans rien qui dise pourquoi.
--
--   3. **L'invisibilite s'arretait a la video et a la presence.** N4 a retire le
--      controleur de `presence_seance_v` ; il restait lisible en toutes lettres
--      dans `session_peers_v`, dans `session_participants` (policies enseignant
--      et foyer) et dans `session_events` (memes policies). Ces surfaces
--      n'avaient jamais ete exercees faute de ligne a y lire ; des que ce
--      fichier en ecrit une, elles deviennent la fuite. **Une invisibilite se
--      verifie sur CHAQUE surface**, et la regle retenue est celle de 0011 :
--      seule l'administration voit la visite, pas meme l'interesse.
--
-- LA REGLE DE FENETRE, ET POURQUOI ELLE NE LIT PAS `status`
--
-- « Voir et entendre toute seance en cours » (ADR-011). En cours se mesure sur
-- les heures, jamais sur `sessions.status` : **rien dans le produit ne fait
-- passer une seance a `in_progress`** -- le webhook LiveKit ecrit des evenements
-- (0010), pas un statut, et la seule ecriture de statut du depot est le passage
-- en `canceled` du balayage de 0005. Un bouton conditionne a `in_progress` ne
-- s'afficherait jamais. La porte d'ici refuse donc exactement ce que refuse
-- `autoriser_jeton_video()` -- une seance close -- et borne comme elle : deux
-- portes, une seule regle.
--
-- Ni `begin;` ni `commit;`, comme 0010 et 0011 : ces migrations sont appliquees
-- par un outil qui ouvre lui-meme sa transaction.

-- ============================================================
-- 1. Le plafond borne le groupe pedagogique, pas les temoins
-- ============================================================

-- Reecrite a l'identique de 0001 a deux lignes pres, marquees ci-dessous.
-- `allow_multi_participant_sessions` reste ferme (ADR-004) : ce n'est pas un
-- assouplissement du 1-to-1, c'est la lecture correcte de ce que le plafond
-- compte.
create or replace function public.guard_session_participant_cap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  allow_multi boolean;
  max_participants int;
  current_count int;
begin
  -- >>> Ajout de 0012. <<<
  -- Un temoin n'est pas un participant pedagogique. Ni le controleur invisible
  -- (ADR-011) ni le tuteur qui assiste (`TUT-01`) ne prennent la place d'un
  -- eleve : ils ne publient rien, ils ne sont pas notes, et la seance se
  -- deroulerait a l'identique sans eux.
  if new.role in ('masked_controller', 'guardian_observer') then
    return new;
  end if;

  select (value)::boolean into allow_multi
  from public.app_config where key = 'allow_multi_participant_sessions';
  if allow_multi is null then allow_multi := false; end if;

  select coalesce(value #>> '{}', '2')::int into max_participants
  from public.app_config where key = 'max_participants_per_session';
  if max_participants is null then max_participants := 2; end if;

  if not allow_multi then
    select count(*) into current_count
    from public.session_participants
    where session_id = new.session_id and deleted_at is null
      -- >>> Ajout de 0012 : on compte le groupe, pas l'assistance. <<<
      and role in ('teacher', 'student');
    if current_count >= max_participants then
      raise exception 'plafond de participants atteint';
    end if;
  end if;
  return new;
end;
$$;

-- ============================================================
-- 2. C2 borne le groupe pedagogique, lui aussi
-- ============================================================

-- « Un meme profil ne peut pas participer a deux sessions qui se recoupent » :
-- la regle protege un enseignant ou un eleve d'un double engagement. Un
-- controleur, lui, passe de salle en salle -- c'est meme son metier, et
-- l'ADR-011 demande de surveiller « un volume d'observations anormal sur une
-- journee ». Sans cette borne, la deuxieme visite d'une matinee chargee serait
-- refusee par un declencheur ecrit pour tout autre chose.
--
-- ⚠ LE CORPS REPRIS ICI EST CELUI DE 0005, PAS CELUI DE 0001. La premiere
-- ecriture de ce fichier est repartie de 0001 et a donc **efface le defaut 3.9
-- que 0005 avait corrige** : les bornes fermees `'[]'` font de la fin d'un cours
-- et du debut du suivant un chevauchement. Mesure, pas suppose --
-- `scenarios_etape4.sql` est passe de vert a « S3 ECHEC : 3 prises au lieu de
-- 4 », une prise sur deux refusee, ce qui a l'air d'un plafond et n'en est pas
-- un. **Un `create or replace` part du corps COURANT, jamais de la migration
-- qui a cree l'objet.**
create or replace function public.guard_session_overlap()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- >>> Ajout de 0012. <<<
  if new.role in ('masked_controller', 'guardian_observer') then
    return new;
  end if;

  if exists (
    select 1
    from public.session_participants sp
    join public.sessions s1 on s1.id = sp.session_id
    join public.sessions s2 on s2.id = new.session_id
    where sp.profile_id = new.profile_id
      and sp.deleted_at is null
      -- >>> Ajout de 0012 : une visite passee n'engage pas l'heure suivante. <<<
      and sp.role in ('teacher', 'student')
      and s1.deleted_at is null and s2.deleted_at is null
      and s1.status in ('planned', 'preflight', 'in_progress')
      -- Bornes de 0005 : un intervalle se ferme a gauche et s'ouvre a droite.
      and tstzrange(s1.started_at, s1.ended_at, '[)')
          && tstzrange(s2.started_at, s2.ended_at, '[)')
      and s1.id <> s2.id
  ) then
    raise exception 'chevauchement de sessions pour le meme profil';
  end if;
  return new;
end;
$$;

-- ============================================================
-- 3. La visite ne se lit sur aucune des surfaces de la seance
-- ============================================================

-- `session_peers_v` : les co-participants, lus par l'eleve et par l'enseignant.
-- Meme borne que `presence_seance_v` depuis 0011, et pour la meme raison : sans
-- elle, l'enseignant y lirait une troisieme personne, c'est-a-dire la visite en
-- toutes lettres. Colonnes inchangees -- `create or replace view` l'exige, et
-- c'est tant mieux : ce fichier ne change pas ce que la vue dit, seulement a
-- qui elle le dit.
create or replace view public.session_peers_v
with (security_barrier = true)
as
select distinct
  sp.session_id,
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
  -- >>> Ajout de 0012 (ADR-011). <<<
  and (sp2.role <> 'masked_controller' or public.app_role() = 'admin');

-- `session_participants` : la table elle-meme. `grant select on all tables to
-- authenticated` de 0001 la rend interrogeable depuis le navigateur ; seules
-- les policies la bornent, et deux d'entre elles rendaient la ligne de la
-- visite. Le controleur ne lit pas davantage la sienne : c'est la regle de 0011,
-- et elle evite qu'un ecran de controleur montre une personne de plus que celui
-- de l'enseignant.
drop policy session_participants_controller_read on public.session_participants;
create policy session_participants_controller_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'controller'
    and deleted_at is null
    and role <> 'masked_controller'
  );

drop policy session_participants_teacher_read on public.session_participants;
create policy session_participants_teacher_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'teacher' and deleted_at is null
    and public.session_belongs_to_teacher(session_participants.session_id, auth.uid())
    and role <> 'masked_controller'
  );

drop policy session_participants_family_read on public.session_participants;
create policy session_participants_family_read on public.session_participants
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'guardian' and deleted_at is null
    and role <> 'masked_controller'
    and exists (select 1 from public.profiles p where p.id = session_participants.profile_id
                and p.household_id = public.app_household_id() and p.deleted_at is null)
  );

-- `session_events` : la trace d'entree et de sortie. Elle porte le profil, donc
-- elle dit qui est arrive a 18h12 et reparti a 18h20. La borne se pose sur le
-- ROLE de ce profil dans CETTE seance.
--
-- ⚠ CE PONT DOIT ETRE UNE FONCTION `security definer`, ET LA PREMIERE ECRITURE
-- DE CE FICHIER S'Y EST TROMPEE. Un `not exists (select 1 from
-- session_participants ...)` ecrit directement dans la policy s'execute **avec
-- les droits de l'appelant**, donc sous la RLS de `session_participants` -- que
-- les trois policies ci-dessus viennent justement de fermer sur les lignes de
-- controleur. Le sous-select ne trouvait donc jamais rien, `not exists` rendait
-- toujours vrai, et l'enseignant lisait les evenements de la visite malgre la
-- policy. Mesure, pas supposition : `C4` a lu « 2 participants, 1 pair,
-- 1 evenement » la ou il en attendait zero. C'est exactement la boucle que 0001
-- avait deja resolue ainsi pour `session_belongs_to_teacher` et
-- `session_in_household`. **Une policy qui interroge une table protegee ne voit
-- que ce que l'appelant voit.**
create function public.est_observateur_masque(
  p_session_id uuid,
  p_profile_id uuid
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id
      and sp.profile_id = p_profile_id
      and sp.role = 'masked_controller'
      and sp.deleted_at is null
  );
$$;

-- Un evenement systeme n'a pas de profil : la fonction rend alors faux, et
-- l'evenement reste lisible. Aucun cas particulier a ecrire dans les policies.
revoke execute on function public.est_observateur_masque(uuid, uuid)
  from anon, public;
grant execute on function public.est_observateur_masque(uuid, uuid)
  to authenticated, service_role;

-- La policy admin et la policy controleur etaient une seule policy : elles se
-- separent ici, l'administration gardant l'acces integral que l'ADR-011 lui
-- reconnait (« consultable dans ADM-04, jamais effacable »).
drop policy session_events_admin_controller_read on public.session_events;

create policy session_events_admin_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'admin'
  );

create policy session_events_controller_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'controller'
    and not public.est_observateur_masque(
      session_events.session_id, session_events.profile_id
    )
  );

drop policy session_events_teacher_read on public.session_events;
create policy session_events_teacher_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'teacher' and
    public.session_belongs_to_teacher(session_events.session_id, auth.uid())
    and not public.est_observateur_masque(
      session_events.session_id, session_events.profile_id
    )
  );

drop policy session_events_family_read on public.session_events;
create policy session_events_family_read on public.session_events
  for select to authenticated using (
    public.app_account_valid() and public.app_role() = 'guardian' and
    public.session_in_household(session_events.session_id, public.app_household_id())
    and not public.est_observateur_masque(
      session_events.session_id, session_events.profile_id
    )
  );

-- ============================================================
-- 4. La porte du controleur
-- ============================================================

-- Elle n'ouvre rien par elle-meme : elle inscrit. C'est
-- `autoriser_jeton_video()` qui decide ensuite du jeton, et qui deduira
-- `hidden` du role inscrit ici. Une porte qui emettrait elle-meme le jeton
-- dupliquerait la regle d'ADR-005 a deux endroits.
create function public.rejoindre_observation(p_session_id uuid)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  -- L'exclusion de role de l'ADR-011 (« un meme profil ne peut pas etre a la
  -- fois enseignant et controleur ») tient deja dans `profiles.role` : ce test
  -- la reprend sans la rejouer.
  if public.app_role() <> 'controller' or not public.app_account_valid() then
    raise exception 'observation reservee au controle qualite'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  -- Meme liste de statuts que `autoriser_jeton_video()`, volontairement : deux
  -- portes qui refuseraient des seances differentes finiraient par se
  -- contredire, et c'est l'ecran qui porterait la contradiction.
  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  -- « Toute seance EN COURS » : on n'entre pas avant le debut. L'enseignant, lui,
  -- ouvre la salle dix minutes avant (ADR-005) -- observer son pre-vol n'est pas
  -- observer un cours.
  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  -- ADR-011 : « ne peut pas observer une seance ou il est lui-meme
  -- participant ». La regle se verifie ici, pas a l'ecran.
  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'masked_controller' then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;
  if v_seance.teacher_id = auth.uid() then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;

  -- Idempotente : une visite interrompue par un rechargement de page doit
  -- pouvoir reprendre. Le conflit reveille une ligne soft-supprimee plutot que
  -- d'echouer sur la cle primaire.
  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'masked_controller')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'masked_controller';

  -- « Qui surveille le surveillant » (ADR-011) : identite, seance, horodatage.
  -- La duree se lit dans `session_events`, ou le webhook ecrit `joined` et
  -- `left`. L'emission du jeton se journalise deja (0010) ; cette entree-ci
  -- nomme la VISITE, et c'est elle que `ADM-04` sait filtrer.
  perform public.log_sensitive_access(
    'controller_observation_started',
    'session_participants',
    p_session_id::text,
    jsonb_build_object(
      'teacher_id', v_seance.teacher_id,
      'started_at', v_seance.started_at,
      'hidden', true
    )
  );

  return p_session_id;
end;
$$;

revoke execute on function public.rejoindre_observation(uuid) from anon, public;
grant execute on function public.rejoindre_observation(uuid) to authenticated;

-- ============================================================
-- 5. La porte du tuteur, ouverte depuis l'etape 4 et murée depuis
-- ============================================================

-- `TUT-01` porte un bouton « Assister » depuis l'etape 4, et `N3` a construit
-- le quatrieme role de la salle pour lui. Entre les deux, personne ne
-- l'inscrivait : le tuteur arrivait dans l'impasse d'acces, sans message qui
-- dise pourquoi. Cette porte est la jumelle de celle du controleur, a trois
-- differences pres, toutes voulues :
--
--   * elle se borne au foyer, et non a tout le produit ;
--   * elle n'ecrit pas au journal d'audit : un parent qui regarde le cours de
--     son enfant n'est pas un acces sensible, et l'emission du jeton laisse
--     deja sa trace ;
--   * le role inscrit est `guardian_observer`, qui entre **muet et visible** --
--     l'inverse exact du controleur.
create function public.assister_seance(p_session_id uuid)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  if public.app_role() <> 'guardian' or not public.app_account_valid() then
    raise exception 'assister est reserve au tuteur du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if not public.session_in_household(p_session_id, public.app_household_id()) then
    raise exception 'cette seance n''est pas celle d''un enfant du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;
  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'guardian_observer' then
    raise exception 'ce profil participe deja a cette seance a un autre titre'
      using errcode = 'check_violation';
  end if;

  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'guardian_observer')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'guardian_observer';

  return p_session_id;
end;
$$;

revoke execute on function public.assister_seance(uuid) from anon, public;
grant execute on function public.assister_seance(uuid) to authenticated;
