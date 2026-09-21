-- 0036_observation_defauts_academie_et_plafond_visite_groupe.sql
-- Aligne l'observation du tuteur sur la regle produit dictee le 21/09, et rend
-- le plafond PAR VISITE administrable groupe par groupe.
--
-- LA REGLE PRODUIT. Le tuteur vient verifier que son enfant PARTICIPE. Dans un
-- groupe de cinq, il peut tomber a un instant ou ce n'est pas le tour de son
-- enfant : il doit pouvoir ressortir et revenir, pour augmenter ses chances de
-- tomber sur le moment ou son enfant lit ou repond. D'ou, PAR DEFAUT, deux
-- visites de deux minutes. L'administration reste libre de regler autrement,
-- academie entiere ou groupe par groupe.
--
-- ============================================================================
-- A. LES QUATRE DEFAUTS D'ACADEMIE (public.app_config)
-- ============================================================================
--
--   cle                                  avant   apres
--   observation.max_visits_per_session   1       2
--   observation.max_seconds_per_visit    null    120
--   observation.max_total_seconds        120     240
--   observation.policy_version           "a1"    "a2"
--
-- 0030_tc_socle.sql:33-41 pose ces cles en `on conflict (key) do nothing` :
-- rejouer le meme insert ne changerait donc RIEN sur une base ou elles
-- existent deja (elles existent, mesure faite). Cette migration ecrit en
-- `on conflict (key) do update`.
--
-- POURQUOI 240 ET PAS 120 -- raisonnement relu dans le code avant d'ecrire, et
-- CONFIRME. public.budget_observation, DANS SA VERSION APPLIQUEE
-- (0033_tc_vues_rpc.sql:1001-1073), ne connait pas le plafond par visite : il
-- ne lit que max_visits_per_session et max_total_observation_seconds
-- (0033:1026-1027), rend `restant_secondes = max_total - consomme` et refuse
-- l'entree avec `temps_epuise` des que `consomme >= max_total`. Le plafond par
-- visite n'etait applique que cote client, par
-- GuardianObservationPolicy.plafondDeVisite
-- (lib/core/tc_observation/guardian_observation_policy.dart:161-167), qui
-- retient TOUJOURS le minimum du plafond par visite et du RESTE total. Avec un
-- total de 120 et un plafond de visite de 120, la premiere visite consomme
-- tout : `restant_secondes` tombe a 0, la seconde visite est refusee pour
-- `temps_epuise`, et la deuxieme visite promise naitrait vide. 240 = 2 x 120
-- est le seul total qui rend la regle vraie.
-- CE QUE CE TOTAL OUVRAIT, ET QUE LA SECTION C REFERME : porter le total a 240
-- sans rien faire d'autre allongeait jusqu'a 240 secondes le JETON SIGNE d'une
-- visite unique (le detail du calcul est en section C). La section C apprend
-- donc le plafond par visite a budget_observation, pour que la borne « deux
-- minutes par visite » soit tenue par le serveur et non par le client.
--
-- POURQUOI LA VERSION CHANGE. `policy_version` est journalisee avec chaque
-- visite : sans bump, une visite relue plus tard ne dirait pas sous quelle
-- regle elle a eu lieu. Mesure refaite sur la base avant d'ecrire, en lecture
-- seule : public.guardian_session_visit = 0 ligne, public.groupes = 0 ligne.
-- Aucun historique ne devient donc ambigu ; le bump est pose pour les visites
-- a venir, qui sont tout son objet.
--
-- `updated_by`. La colonne existe (uuid, nullable). Une migration ne s'execute
-- sous aucun compte applicatif : auth.uid() y est nul. Elle est donc ecrite
-- explicitement a NULL plutot que laissee en place -- sinon le declencheur
-- guard_app_config_history (0001_fondations.sql:936-948), qui recopie
-- `coalesce(new.updated_by, auth.uid())`, attribuerait ce changement au dernier
-- administrateur ayant touche la cle. app_config_history.changed_by est
-- nullable (verifie) et un NULL s'y lit : change par une migration.
--
-- ============================================================================
-- B. LE PLAFOND PAR VISITE, GROUPE PAR GROUPE
-- ============================================================================
--
-- LE DEFAUT MESURE. public.politique_observation_effective lit, dans sa branche
-- `groupe`, groupes.observation_max_secondes_par_visite (0033:977). Or cette
-- colonne est `integer` NULLABLE SANS DEFAUT (mesure sur
-- information_schema.columns) et public.definir_politique_observation_groupe
-- (0033:1304-1346) ne l'ecrivait pas : elle ne posait qu'observation_source,
-- observation_max_visites et observation_max_secondes. Consequence chiffree :
-- des qu'un administrateur personnalisait un groupe par cette RPC, le plafond
-- par visite de ce groupe devenait nul ; plafondDeVisite rendait alors le reste
-- total entier, soit 240 secondes d'affilee en UNE seule visite. La regle
-- « deux minutes par visite » disparaissait pour ce groupe, et avec elle la
-- seconde visite qui est toute la raison d'etre du reglage. C'est exactement ce
-- que l'operateur veut eviter.
--
-- LA CORRECTION : un cinquieme parametre, p_max_secondes_par_visite.
--
-- CE QUE FAIT LA FONCTION QUAND CE PARAMETRE EST NUL. Ni effacer, ni laisser
-- tel quel : elle retombe, dans l'ordre, sur la valeur deja posee sur le
-- groupe, puis sur le defaut d'Academie. Justification, prise dans le module de
-- reglages cote Dart (lib/features/tc_observation_ui/etat_reglages_observation
-- .dart) : ce module n'expose que TROIS champs -- source, nombre de visites,
-- temps total (lignes 71-78) -- et n'a aucun champ de plafond par visite ; son
-- apercu `appliquerA` (lignes 135-150) passe par `copieAvec`, qui conserve
-- volontairement maxParVisite de l'Academie
-- (guardian_observation_policy.dart:183). Ce module appellera donc la RPC sans
-- cinquieme valeur, tout en promettant a l'ecran qu'un groupe personnalise
-- garde le plafond de visite de l'Academie. Effacer trahirait cet apercu et
-- rouvrirait le defaut ci-dessus ; laisser tel quel le laisserait nul sur tout
-- groupe neuf, c'est-a-dire ne corrigerait rien. Le cran « valeur deja posee »
-- vient en premier pour qu'un client qui ignore le parametre ne detruise pas en
-- silence un plafond regle ailleurs.
-- CONSEQUENCE ASSUMEE : cette RPC ne permet plus de remettre le plafond a nul,
-- c'est-a-dire a « illimite par visite ». C'est voulu : « illimite par visite »
-- n'est pas un reglage que la regle produit autorise.
--
-- Le resultat est borne par `least(..., p_max_secondes)`, parce que la
-- contrainte groupes_observation_plafond_visite (mesuree sur pg_constraint)
-- exige par_visite <= max_secondes : sans ce bornage, un administrateur reglant
-- un total de 60 secondes recevrait une violation de contrainte au lieu d'un
-- enregistrement. C'est le meme invariant que plafondDeVisite cote Dart, ecrit
-- une seconde fois la ou la donnee est posee. `least` ignore les NULL : quand
-- p_max_secondes est nul (source 'academie' ou 'desactivee', ou la contrainte
-- groupes_observation_complete ne l'exige pas), il ne borne rien.
--
-- SIGNATURE. Ajouter un parametre CHANGE la signature : un `create or replace`
-- creerait une SURCHARGE et laisserait l'ancienne fonction vivante, rendant
-- l'appel ambigu. L'ancienne signature exacte est donc `drop`ee. Un drop
-- DETRUIT LES DROITS : les deux instructions sont reposees a l'identique de
-- 0033:1343-1346, jamais le seul revoke -- retirer EXECUTE a public et a anon
-- ne retire RIEN a `authenticated`, qui le tient d'un chemin Supabase
-- independant. La fonction reste `volatile` (elle ecrit) : `agent_ro` ne doit
-- JAMAIS avoir EXECUTE dessus, et get_advisors ne le detecte pas.
-- Le cinquieme parametre porte `default null` : c'est ce qui laisse les
-- appelants a trois champs (le module Dart ci-dessus, et PostgREST qui resout
-- par noms) continuer d'appeler sans lui. Aucune surcharge n'en nait, puisque
-- l'ancienne fonction est detruite.
--
-- QUI EST AFFECTE. Tous les tuteurs observateurs (deux visites de deux minutes
-- au lieu d'une seule), l'administration (un reglage de plus par groupe),
-- personne d'autre. Aucun code Dart n'appelle encore cette RPC (verifie : zero
-- occurrence de son nom dans lib/ et test/), donc le changement de signature ne
-- casse aucun appel existant.
--
-- ============================================================================
-- C. LE PLAFOND PAR VISITE, TENU PAR LE SERVEUR
-- ============================================================================
--
-- CE QUI A ETE MESURE DANS LE CODE APPLIQUE, ligne a ligne, avant d'ecrire un
-- mot de cette section :
--   * public.budget_observation (0033_tc_vues_rpc.sql:1001-1073) ne lit que
--     deux quotas (0033:1026-1027), max_visits_per_session et
--     max_total_observation_seconds ; `max_seconds_per_visit` n'apparait nulle
--     part dans son corps, et son `restant_secondes` (0033:1068) vaut
--     `greatest(0, max_total - temps_consomme)` ;
--   * public.autoriser_jeton_video (0033:1643-1781) borne l'expiration du
--     jeton d'un guardian_observer a
--     `least(token_ttl_seconds, restant_secondes)` (0033:1733), et
--     public.video_config.token_ttl_seconds vaut 900 par defaut
--     (0010_video_jeton_presence.sql:75).
--   La seule borne PAR VISITE reellement tenue par le serveur etait donc une
--   coincidence arithmetique : le total valant 120, `restant_secondes` ne
--   pouvait pas depasser 120. La section A porte ce total a 240 ; le meme
--   calcul emettrait desormais, pour UNE visite, un jeton signe valable 240
--   secondes. La borne « deux minutes par visite » ne reposerait plus que sur
--   le client, ce que la specification 11.4 refuse en une phrase : « le client
--   ne peut pas prolonger sa visite en modifiant un timer ».
--
-- LA CORRECTION. `restant_secondes` devient le MINIMUM de deux restes :
--   * le reste TOTAL, inchange : max_total moins le temps consomme sur la
--     seance, intervalle ouvert compris ;
--   * le reste de LA VISITE : le plafond par visite moins ce que l'intervalle
--     OUVERT a deja consomme -- ou le plafond entier quand aucun intervalle
--     n'est ouvert, c'est-a-dire pour la visite a venir.
--   C'est mot pour mot l'invariant de plafondDeVisite
--   (guardian_observation_policy.dart:161-167), ecrit une seconde fois la ou
--   il est opposable. Un plafond par visite absent (NULL) ne borne rien : le
--   reste total reste seul, exactement comme aujourd'hui.
--
-- CE QUI N'EST PAS TOUCHE, ET POURQUOI. public.autoriser_jeton_video n'est PAS
-- reecrite. Elle prend deja le minimum de son TTL et de `restant_secondes`
-- (0033:1733) : borner `restant_secondes` borne donc le jeton, sans rouvrir
-- une fonction que quatre roles traversent (eleve, enseignant, controleur,
-- administration) et qui a deja ete reecrite une fois en fusion A+G+Q. La plus
-- petite modification qui tient l'invariant est aussi la seule qui ne risque
-- rien pour ses autres appelants.
--
-- CONSEQUENCE VOULUE. Pendant une visite, `restant_secondes` peut tomber a 0
-- alors que `peut_entrer` reste vrai. Ce n'est pas une contradiction : ce sont
-- deux questions differentes -- « combien de temps reste-t-il A CETTE VISITE »
-- et « une NOUVELLE visite serait-elle acceptee ». Le moteur client ferme la
-- visite sur la premiere (moteur_visite_observation.dart:279-281) et le tuteur
-- peut alors revenir pour sa seconde visite. C'est la regle produit, et c'est
-- ce que `peut_entrer` doit continuer de repondre : ses trois motifs de refus
-- ne bougent pas d'une ligne.
--
-- SIGNATURE INCHANGEE : `create or replace` de meme signature, donc aucun drop
-- et aucun droit detruit. Les deux instructions de droits sont tout de meme
-- reecrites a l'identique de 0033:1075-1076 : les repeter ne coute rien, et
-- s'en remettre a ce qu'un `replace` conserve serait s'en remettre a un
-- souvenir. La fonction reste `stable` : elle ne fait que lire.

-- ============================================================================
-- A. Defauts d'Academie
-- ============================================================================

insert into public.app_config (key, value, updated_by, updated_at) values
  ('observation.max_visits_per_session', '2'::jsonb,     null, now()),
  ('observation.max_seconds_per_visit',  '120'::jsonb,   null, now()),
  ('observation.max_total_seconds',      '240'::jsonb,   null, now()),
  ('observation.policy_version',         '"a2"'::jsonb,  null, now())
on conflict (key) do update
   set value      = excluded.value,
       updated_by = excluded.updated_by,
       updated_at = now();

-- ============================================================================
-- B. Plafond par visite administrable par groupe
-- ============================================================================

drop function if exists public.definir_politique_observation_groupe(uuid, text, smallint, integer);

create function public.definir_politique_observation_groupe(
  p_groupe_id uuid, p_source text,
  p_max_visites smallint, p_max_secondes integer,
  p_max_secondes_par_visite integer default null
) returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_par_visite integer;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  if p_source not in ('academie', 'groupe', 'desactivee') then
    raise exception 'source de politique inconnue : %', p_source using errcode = 'invalid_parameter_value';
  end if;

  -- La revision est bumpee par le declencheur existant
  -- (tc_groupes_observation_bump_revision, 0030) : rien a faire ici. Ce
  -- declencheur surveille deja observation_max_secondes_par_visite, donc un
  -- changement du seul plafond de visite fait bouger policy_version.
  update public.groupes
     set observation_source = p_source,
         observation_max_visites = p_max_visites,
         observation_max_secondes = p_max_secondes,
         -- Nul en entree = retomber sur ce que le groupe porte deja, puis sur
         -- le defaut d'Academie. Jamais nul en sortie : « illimite par visite »
         -- n'est pas un reglage. Le `least` rejoue l'invariant de
         -- plafondDeVisite et satisfait groupes_observation_plafond_visite.
         observation_max_secondes_par_visite = least(
           coalesce(
             p_max_secondes_par_visite,
             groupes.observation_max_secondes_par_visite,
             public.app_config_int('observation.max_seconds_per_visit', 120)
           ),
           p_max_secondes
         )
   where id = p_groupe_id and ended_at is null
   returning observation_max_secondes_par_visite into v_par_visite;

  if not found then
    raise exception 'groupe introuvable ou deja cloture' using errcode = 'no_data_found';
  end if;

  -- La valeur journalisee est celle REELLEMENT ecrite, pas celle demandee :
  -- avec un parametre nul, les deux different.
  perform public.log_sensitive_access(
    'observation_politique_groupe_modifiee', 'groupes', p_groupe_id::text,
    jsonb_build_object('source', p_source, 'max_visites', p_max_visites,
                       'max_secondes', p_max_secondes,
                       'max_secondes_par_visite', v_par_visite)
  );

  return public.politique_observation_effective(p_groupe_id);
end;
$$;

-- Droits : a l'identique de 0033:1343-1346, les DEUX instructions ecrites. Un
-- `create` neuf accorde EXECUTE a PUBLIC : le revoke retire ce defaut, le grant
-- repose le seul droit voulu. `agent_ro` n'apparait que dans le revoke, jamais
-- dans le grant : la fonction est volatile.
revoke execute on function public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer)
  from public, anon, agent_ro;
grant execute on function public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer)
  to authenticated;

-- ============================================================================
-- C. Le plafond par visite, applique par le serveur
-- ============================================================================

create or replace function public.budget_observation(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_seance  public.sessions%rowtype;
  v_pol     jsonb;
  v_ttl     int;
  v_visites int;
  v_temps   int;
  v_max_v   int;
  v_max_t   int;
  v_max_pv  int;
  v_ouverte int;
  v_reste_t int;
  v_reste_v int;
  v_peut    boolean;
  v_motif   text;
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('peut_entrer', false, 'motif_refus', 'seance_non_active');
  end if;

  v_pol   := public.politique_observation_effective(v_seance.groupe_id);
  v_max_v := (v_pol->>'max_visits_per_session')::int;
  v_max_t := (v_pol->>'max_total_observation_seconds')::int;
  -- NULL quand la politique ne pose aucun plafond par visite : `->>` rend SQL
  -- NULL sur un null JSON, et c'est ce cas-la qu'il faut distinguer de zero.
  -- Zero voudrait dire « aucune seconde », NULL veut dire « pas de plafond ».
  v_max_pv := (v_pol->>'max_seconds_per_visit')::int;

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  select count(*) into v_visites
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  -- Intervalle ouvert compte, plafonne au TTL du jeton (arbitrage §1.7).
  select coalesce(sum(
    case
      when v.left_at is not null
        then coalesce(v.duration_seconds, extract(epoch from (v.left_at - v.entered_at))::int)
      when now() - v.entered_at >= make_interval(secs => v_ttl) then v_ttl
      else extract(epoch from (now() - v.entered_at))::int
    end
  ), 0) into v_temps
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer';

  -- Ce que l'intervalle OUVERT a deja consomme, NULL quand il n'y en a pas.
  -- `guardian_visit_ouvert_uidx` (0032_tc_catalogue.sql:478-480) garantit au
  -- plus un intervalle ouvert par (seance, observateur) : le `limit 1` ne
  -- choisit pas entre deux lignes, il lit la seule qui puisse exister. Le meme
  -- plafonnement au TTL que ci-dessus, pour que les deux calculs disent la
  -- meme chose d'un intervalle reste ouvert au-dela de son jeton.
  select case
           when now() - v.entered_at >= make_interval(secs => v_ttl) then v_ttl
           else extract(epoch from (now() - v.entered_at))::int
         end
    into v_ouverte
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.observateur_profile_id = auth.uid()
     and v.role = 'guardian_observer'
     and v.left_at is null
   order by v.entered_at desc
   limit 1;

  v_reste_t := greatest(0, v_max_t - v_temps);
  -- Le reste de la visite : sous le plafond par visite pour l'intervalle
  -- ouvert, le plafond entier pour une visite a venir. Sans plafond par
  -- visite, il n'y a rien a borner et le reste total vaut pour les deux.
  v_reste_v := case
                 when v_max_pv is null then v_reste_t
                 else greatest(0, v_max_pv - coalesce(v_ouverte, 0))
               end;

  -- Les trois motifs de refus sont inchanges : `peut_entrer` repond toujours
  -- « une NOUVELLE visite serait-elle acceptee », question a laquelle le
  -- plafond PAR VISITE ne repond pas.
  if not (v_pol->>'observation_activee')::boolean then
    v_peut := false; v_motif := 'policy_desactivee';
  elsif v_visites >= v_max_v then
    v_peut := false; v_motif := 'quota_visites_atteint';
  elsif v_temps >= v_max_t then
    v_peut := false; v_motif := 'temps_epuise';
  else
    v_peut := true; v_motif := null;
  end if;

  return jsonb_build_object(
    'policy_version', v_pol->>'policy_version',
    'visites_utilisees', v_visites,
    'visites_max', v_max_v,
    'temps_consomme_secondes', v_temps,
    'temps_total_max_secondes', v_max_t,
    -- LE MINIMUM DES DEUX RESTES. C'est ce nombre que le client affiche en
    -- compte a rebours (port_politique_observation.dart:85-87) ET celui qui
    -- borne le jeton signe (0033:1733) : une seule verite, la meme des deux
    -- cotes, decidee ici.
    'restant_secondes', least(v_reste_t, v_reste_v),
    'peut_entrer', v_peut,
    'motif_refus', v_motif
  );
end;
$$;

-- Droits : a l'identique de 0033:1075-1076. `agent_ro` n'apparait que dans le
-- revoke. La fonction est `stable`, mais elle lit sous `security definer` ce
-- que l'appelant a le droit de lire, et pas davantage : un agent qui la
-- lirait lirait le quota d'un tuteur qui n'est pas lui.
revoke execute on function public.budget_observation(uuid) from public, anon, agent_ro;
grant execute on function public.budget_observation(uuid) to authenticated;

-- ============================================================================
-- Controle de sortie -- modele 0030_tc_socle.sql:218-230. Une migration qui ne
-- prend pas doit echouer bruyamment, jamais passer en silence. Chaque controle
-- est ecrit en EXIGENCE POSITIVE : un `if valeur <> attendue` ne se declenche
-- pas quand la ligne manque, puisque NULL n'est pas vrai.
-- ============================================================================
do $$
declare
  v_oid    oid;
  v_oid_b  oid;
  v_nb     int;
  v_source text;
begin
  -- A. Les quatre valeurs d'Academie sont bien celles attendues.
  if (select count(*) from public.app_config
       where (key = 'observation.max_visits_per_session' and value = '2'::jsonb)
          or (key = 'observation.max_seconds_per_visit'  and value = '120'::jsonb)
          or (key = 'observation.max_total_seconds'      and value = '240'::jsonb)
          or (key = 'observation.policy_version'         and value = '"a2"'::jsonb)) <> 4 then
    raise exception '0036 incomplete : les defauts d''observation de l''Academie ne sont pas poses';
  end if;

  -- B. Une seule fonction de ce nom : l'ancienne signature ne doit pas survivre
  -- en surcharge, sinon l'appel devient ambigu.
  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'definir_politique_observation_groupe';
  if v_nb <> 1 then
    raise exception '0036 incomplete : % fonction(s) definir_politique_observation_groupe, 1 attendue', v_nb;
  end if;

  select p.oid into v_oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'definir_politique_observation_groupe';

  if to_regprocedure('public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer)') is null then
    raise exception '0036 incomplete : la signature a cinq arguments est absente';
  end if;

  if (select p.pronargs from pg_catalog.pg_proc p where p.oid = v_oid) <> 5 then
    raise exception '0036 incomplete : definir_politique_observation_groupe n''a pas 5 arguments';
  end if;

  -- Elle ecrit : elle doit rester volatile, c'est ce qui interdit agent_ro.
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 'v' then
    raise exception '0036 incomplete : definir_politique_observation_groupe n''est plus volatile';
  end if;

  -- Le corps doit bien poser le plafond par visite.
  if (select p.prosrc from pg_catalog.pg_proc p where p.oid = v_oid)
     not like '%observation_max_secondes_par_visite = least%' then
    raise exception '0036 incomplete : le plafond par visite n''est pas ecrit par la RPC';
  end if;

  -- EXECUTE arrive par DEUX chemins : verifier chaque role separement, jamais
  -- presumer qu'un revoke de public/anon a touche authenticated.
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0036 incomplete : anon garde EXECUTE sur definir_politique_observation_groupe';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0036 incomplete : authenticated n''a pas EXECUTE sur definir_politique_observation_groupe';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0036 incomplete : agent_ro a EXECUTE sur une fonction volatile';
  end if;

  -- C. budget_observation borne desormais la visite, et pas seulement le
  -- total. Chaque controle exige une presence : aucun ne se contente de ne pas
  -- trouver de faute.
  v_oid_b := to_regprocedure('public.budget_observation(uuid)')::oid;
  if v_oid_b is null then
    raise exception '0036 incomplete : public.budget_observation(uuid) est absente';
  end if;

  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'budget_observation';
  if v_nb <> 1 then
    raise exception '0036 incomplete : % fonction(s) budget_observation, 1 attendue', v_nb;
  end if;

  -- Elle ne fait que lire : `stable` est ce qui le dit au planificateur.
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid_b) <> 's' then
    raise exception '0036 incomplete : budget_observation n''est plus stable';
  end if;

  -- Le corps doit lire le plafond par visite ET rendre le minimum des deux
  -- restes. Les deux sont exiges separement : lire le plafond sans s'en servir
  -- ne bornerait rien.
  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid_b;
  if v_source not like '%max_seconds_per_visit%' then
    raise exception '0036 incomplete : budget_observation ne lit pas le plafond par visite';
  end if;
  if v_source not like '%least(v_reste_t, v_reste_v)%' then
    raise exception '0036 incomplete : restant_secondes n''est pas borne par la visite';
  end if;

  -- Les memes trois roles, verifies un par un : EXECUTE arrive par deux
  -- chemins, et un `create or replace` conserve les droits de la fonction
  -- remplacee -- raison de plus pour les constater plutot que les supposer.
  if pg_catalog.has_function_privilege('anon', v_oid_b, 'execute') then
    raise exception '0036 incomplete : anon garde EXECUTE sur budget_observation';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid_b, 'execute') then
    raise exception '0036 incomplete : authenticated n''a pas EXECUTE sur budget_observation';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid_b, 'execute') then
    raise exception '0036 incomplete : agent_ro a EXECUTE sur budget_observation';
  end if;
end $$;
