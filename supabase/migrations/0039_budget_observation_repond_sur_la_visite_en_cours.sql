-- 0039_budget_observation_repond_sur_la_visite_en_cours.sql
--
-- CE QUI CHANGE. public.budget_observation ne pose plus la meme question selon
-- qu'une visite est ouverte ou non. Quand un intervalle d'observation est
-- OUVERT pour l'appelant sur cette seance, `peut_entrer` repond desormais
-- « CETTE visite, deja ouverte, a-t-elle encore du temps ? » et non plus
-- « une NOUVELLE visite serait-elle acceptee ? ». Quand aucun intervalle n'est
-- ouvert, la question et les trois motifs de refus restent mot pour mot ceux
-- de 0033 et 0036.
--
-- POURQUOI. Le serveur posait la mauvaise question au mauvais moment, et cela
-- eteignait la fonctionnalite entiere.
--
-- L'ORDRE REEL DES APPELS, lu dans le code de l'ecran
-- (lib/features/tc_observation_ui/entree_observation_page.dart:34-39, qui
-- l'ecrit noir sur blanc) :
--   1. entrer_observation() verifie tout, PUIS inscrit l'appelant dans
--      session_participants et INSERE la ligne guardian_session_visit
--      (0033_tc_vues_rpc.sql:1164-1179) ;
--   2. la salle demande ensuite le jeton a autoriser_jeton_video(), qui ne
--      peut pas etre appelee avant, faute de role a lire.
-- Autrement dit : quand le jeton est demande, l'intervalle de la visite en
-- cours EXISTE DEJA.
--
-- LE DEFAUT, RE-MESURE SUR POSTGRES 17 AVANT D'ECRIRE CETTE LIGNE :
--   * public.budget_observation compte les visites par un `count(*)` qui
--     n'exclut pas l'intervalle ouvert (0033_tc_vues_rpc.sql:1032-1036, repris
--     tel quel en 0036 section C, lignes 319-323) ; la visite en cours se
--     compte donc elle-meme dans son propre quota ;
--   * public.autoriser_jeton_video refuse d'emettre le jeton des que
--     `peut_entrer` est faux (0033_tc_vues_rpc.sql:1696-1702).
--
-- CE QUE CELA DONNE, MESURE :
--   * avec max_visits_per_session = 1, la valeur en production aujourd'hui,
--     entrer_observation rend `autorise: true`, puis budget_observation rend
--     `peut_entrer: false, motif_refus: quota_visites_atteint`, et l'appel
--     reel leve « quota d'observation atteint : quota_visites_atteint ».
--     L'OBSERVATION VIDEO NE PEUT PAS FONCTIONNER DU TOUT AUJOURD'HUI : la
--     premiere visite se refuse son propre jeton.
--   * apres 0036, qui porte le quota a 2, c'est la DEUXIEME visite qui se
--     refuse son jeton -- celle que toute la regle produit existe pour offrir.
--     Le tuteur vient voir si son enfant participe ; dans un groupe de cinq il
--     peut tomber a un moment ou ce n'est pas le tour de son enfant, et c'est
--     le retour qui lui donne sa chance. C'est exactement ce retour qui
--     echouait.
--
-- UN SECOND DEFAUT, TROUVE EN MESURANT, ET FERME PAR LA MEME CORRECTION.
-- Quand le temps DE LA VISITE etait epuise mais le total non (`peut_entrer`
-- vrai, `restant_secondes` a 0 -- l'etat que 0036 section C decrit comme
-- voulu), autoriser_jeton_video calculait
-- `v_expire := now() + least(ttl, 0)` (0033:1733), soit exactement `now()`, et
-- l'insertion dans video_token_grants violait la contrainte
-- `video_token_grants_duree_ok` (CHECK (expire_le > emis_le)). Le tuteur ne
-- recevait donc pas un refus intelligible mais une erreur 23514 brute. Mesure
-- avant correction, sortie reelle :
--   REFUS new row for relation "video_token_grants" violates check constraint
--   "video_token_grants_duree_ok"
-- Apres cette migration, `peut_entrer` est faux des que `restant_secondes`
-- vaut zero : le refus arrive avant l'insertion, avec un motif.
--
-- QUI GAGNE QUOI.
--   * Le tuteur observateur : ses visites obtiennent leur jeton. C'est le
--     seul role dont le comportement change, et il ne change que dans le sens
--     de la regle produit.
--   * L'academie : le plafond n'est pas desserre d'une seconde. Le nombre de
--     visites reste decide a l'ouverture de la visite, par entrer_observation,
--     qui est le seul endroit ou une visite naisse ; la duree reste bornee par
--     `restant_secondes`, que 0036 a deja rendue juste.
--   * Personne d'autre : eleve, enseignant, controleur masque et
--     administration ne passent pas par ce calcul (0033:1696, la branche est
--     gardee par `v_role = 'guardian_observer'`). Mesure faite, les trois
--     roles rendent le meme jeton avant et apres.
--
-- ============================================================================
-- CE QUI N'EST PAS TOUCHE, ET POURQUOI
-- ============================================================================
--
-- public.autoriser_jeton_video n'est PAS rouverte, et c'est delibere. Quatre
-- roles la traversent (eleve, enseignant, tuteur observateur, controleur), elle
-- a deja ete reecrite une fois par fusion de trois lots, et 0036 section C a
-- pose le precedent : elle consomme `budget_observation`, donc rendre
-- `budget_observation` juste suffit a rendre le jeton juste. Elle prend deja
-- `least(ttl, restant_secondes)` pour borner le jeton (0033:1733) et refuse
-- deja sur `peut_entrer` (0033:1698) ; les deux valeurs viennent d'ici. La plus
-- petite modification qui tient l'invariant est aussi la seule qui ne risque
-- rien pour ses autres appelants.
--
-- COMMENT CELA S'ARTICULE AVEC 0036 SECTION C, SANS LA DEFAIRE.
-- 0036 a fait de `restant_secondes` le MINIMUM de deux restes -- le reste total
-- et le reste de la visite -- et a laisse `peut_entrer` repondre sur la
-- NOUVELLE visite. Elle notait la consequence : « Pendant une visite,
-- restant_secondes peut tomber a 0 alors que peut_entrer reste vrai [...] ce
-- sont deux questions differentes » (0036, lignes 171-178). Cette lecture est
-- exacte pour le CLIENT, qui ferme la visite sur `restant_secondes`
-- (moteur_visite_observation.dart:279-281). Elle ne l'est pas pour
-- autoriser_jeton_video, qui n'a que `peut_entrer` sous la main et l'interroge
-- au moment ou la visite est DEJA ouverte. 0039 ne retire donc rien a 0036 :
-- le calcul des deux restes est repris a l'identique, `least(v_reste_t,
-- v_reste_v)` reste la seule verite de la duree. Seul change le moment ou
-- `peut_entrer` bascule, et il ne bascule que la ou 0036 ne regardait pas.
--
-- AUCUN NOUVEAU MOTIF DE REFUS. Le refus d'une visite dont le temps est epuise
-- reutilise `temps_epuise`, qui existe deja cote SQL et cote Dart
-- (MotifRefusObservation.tempsEpuise,
-- lib/core/tc_observation/port_politique_observation.dart:25). Un motif neuf
-- aurait ete plus precis, mais `MotifRefusObservation.depuisSql` rend `null`
-- sur une valeur inconnue (meme fichier, lignes 41-49) et l'ecran afficherait
-- alors un refus sans raison (entree_observation_page.dart:191-193). Aucun
-- fichier Dart n'est touche par ce lot ; ce choix est ce qui le permet.
--
-- SIGNATURE INCHANGEE : `create or replace` de meme signature, donc aucun drop
-- et aucun droit detruit. Les deux instructions de droits sont tout de meme
-- reecrites a l'identique de 0033:1075-1076 et 0036:401-402 : s'en remettre a
-- ce qu'un `replace` conserve serait s'en remettre a un souvenir. La fonction
-- reste `stable` : elle ne fait que lire. `agent_ro` n'apparait que dans le
-- revoke.
--
-- ============================================================================
-- ET POURQUOI IL Y A UNE SECTION B QUE PERSONNE N'AVAIT DEMANDEE
-- ============================================================================
--
-- En voulant MESURER le cas « deuxieme visite ouverte alors que le quota de 2
-- n'est pas atteint », il a fallu fermer la premiere visite. C'est la que
-- public.sortir_observation (0033_tc_vues_rpc.sql:1198-1230) s'est revelee
-- INCAPABLE DE S'EXECUTER, pour deux raisons independantes, mesurees :
--
--   1. Elle ecrit `duration_seconds` (0033:1210). Or cette colonne est
--      GENEREE ALWAYS depuis 0032 :
--        CASE WHEN left_at IS NULL THEN NULL
--             ELSE GREATEST(0, EXTRACT(epoch FROM (left_at - entered_at))::int)
--        END
--      Postgres refuse categoriquement. Sortie reelle de l'appel :
--        ERROR: column "duration_seconds" can only be updated to DEFAULT
--        DETAIL: Column "duration_seconds" is a generated column.
--
--   2. Elle ecrit `fin_de_visite = 'utilisateur'` (0033:1211). Cette valeur
--      n'existe nulle part ailleurs dans le produit : la contrainte
--      guardian_session_visit_fin_de_visite_check n'admet que
--      'sortie_volontaire', 'quota_atteint', 'seance_terminee',
--      'revocation_serveur' et 'deconnexion', et l'enum Dart FinDeVisite
--      (lib/core/tc_observation/guardian_session_visit.dart:57-71) nomme
--      exactement les cinq memes. Sortie reelle, une fois le point 1 ecarte :
--        ERROR: new row for relation "guardian_session_visit" violates check
--        constraint "guardian_session_visit_fin_de_visite_check"
--
-- CE QUE CELA COUTE, ET POURQUOI CE N'EST PAS UN LOT SEPARE. La sortie
-- volontaire est le SEUL chemin qui ferme un intervalle d'observation. Tant
-- qu'elle leve, l'intervalle de la premiere visite reste ouvert ; et
-- `guardian_visit_ouvert_uidx` (0032_tc_catalogue.sql:478-480) n'admet qu'un
-- intervalle ouvert par (seance, observateur). La deuxieme visite ne peut donc
-- meme pas NAITRE : entrer_observation echoue sur l'index unique. Mesure :
--   ERROR: duplicate key value violates unique constraint
--   "guardian_visit_ouvert_uidx"
-- Corriger le seul jeton aurait donc livre un lot dont le cas principal reste
-- inatteignable, et dont la preuve ne peut pas etre produite. La regle produit
-- -- « il peut revenir apres » -- passe par cette fonction.
--
-- CORRECTION : ne plus ecrire la colonne generee (elle se calcule seule, et
-- mieux : elle plancherait a zero), et nommer la fin avec le mot que la
-- contrainte et le Dart connaissent tous les deux. Aucune signature, aucun
-- droit, aucune autre ligne ne bougent. `create or replace` sur signature
-- identique CONSERVE les droits poses en 0033:1232-1233 ; ils sont tout de
-- meme reposes, pour la meme raison qu'en section A.

-- ============================================================================
-- A. La question posee par budget_observation
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
  v_restant int;
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
  -- CETTE VALEUR PORTE MAINTENANT DEUX ROLES : elle borne la duree, comme
  -- depuis 0036, et elle DIT LAQUELLE DES DEUX QUESTIONS se pose. `is not
  -- null` s'y lit « une visite est en cours ».
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
  -- Calcul repris mot pour mot de 0036 section C : il n'est pas touche.
  v_reste_v := case
                 when v_max_pv is null then v_reste_t
                 else greatest(0, v_max_pv - coalesce(v_ouverte, 0))
               end;
  v_restant := least(v_reste_t, v_reste_v);

  -- ==========================================================================
  -- LA QUESTION, CHOISIE PAR L'ETAT DE LA VISITE.
  --
  -- Le quota de VISITES ne se demande que lorsqu'il s'agit d'en ouvrir une
  -- nouvelle, c'est-a-dire quand aucun intervalle n'est ouvert. Ce n'est pas un
  -- desserrement : une visite ne nait que dans entrer_observation, qui appelle
  -- cette fonction AVANT son insertion (0033:1152-1161), donc a un moment ou
  -- `v_ouverte` est nul et ou le quota est bel et bien exige. Une fois la
  -- visite ouverte, la compter contre elle-meme ne protegeait rien : elle
  -- avait deja passe la porte.
  --
  -- Le temps, lui, est exige dans les DEUX cas, par `v_restant`, qui vaut le
  -- minimum du reste total et du reste de la visite. Une visite ouverte dont
  -- les deux minutes sont consommees est donc refusee, et refusee AVANT que
  -- autoriser_jeton_video ne tente d'inscrire un jeton de duree nulle.
  --
  -- Les trois conditions sont ecrites en EXIGENCE POSITIVE de ce qui doit etre
  -- vrai pour entrer -- politique allumee, quota non atteint, temps restant --
  -- et non en detection de fautes : un `if` qui ne se declenche pas sur une
  -- valeur absente laisserait passer.
  -- ==========================================================================
  if not (v_pol->>'observation_activee')::boolean then
    v_peut := false; v_motif := 'policy_desactivee';
  elsif v_ouverte is null and v_visites >= v_max_v then
    v_peut := false; v_motif := 'quota_visites_atteint';
  elsif v_restant <= 0 then
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
    -- LE MINIMUM DES DEUX RESTES, comme 0036 l'a pose. C'est ce nombre que le
    -- client affiche en compte a rebours (port_politique_observation.dart:
    -- 85-87) ET celui qui borne le jeton signe (0033:1733) : une seule verite,
    -- la meme des deux cotes, decidee ici.
    'restant_secondes', v_restant,
    -- Laquelle des deux questions a ete repondue. Cle neuve et purement
    -- informative : aucun client ne la lit aujourd'hui, et un client qui
    -- l'ignore lit le meme budget qu'avant. Elle existe pour qu'un journal ou
    -- une console d'exploitation puisse distinguer un refus d'entree d'une fin
    -- de visite sans avoir a rededuire l'etat.
    'visite_en_cours', (v_ouverte is not null),
    'peut_entrer', v_peut,
    'motif_refus', v_motif
  );
end;
$$;

-- Droits : a l'identique de 0033:1075-1076 et 0036:401-402. `agent_ro`
-- n'apparait que dans le revoke. La fonction est `stable`, mais elle lit sous
-- `security definer` ce que l'appelant a le droit de lire, et pas davantage :
-- un agent qui la lirait lirait le quota d'un tuteur qui n'est pas lui.
revoke execute on function public.budget_observation(uuid) from public, anon, agent_ro;
grant execute on function public.budget_observation(uuid) to authenticated;

-- ============================================================================
-- B. La sortie d'observation, rendue executable
--
-- Corps recopie a l'identique de 0033:1204-1229, moins la ligne qui ecrit la
-- colonne generee, et avec la fin de visite nommee par une valeur qui existe.
-- Rien d'autre ne change : meme ordre, meme journalisation, meme retour.
-- ============================================================================

create or replace function public.sortir_observation(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_visite public.guardian_session_visit;
begin
  -- `duration_seconds` n'est PAS ecrite : elle est generee a partir de
  -- `left_at` et `entered_at` (0032), et `returning *` la rend donc deja
  -- calculee pour la journalisation ci-dessous.
  update public.guardian_session_visit v
     set left_at = now(),
         fin_de_visite = 'sortie_volontaire'
   where v.id = (
     select id from public.guardian_session_visit
      where session_id = p_session_id and observateur_profile_id = auth.uid() and left_at is null
      order by entered_at desc limit 1
   )
  returning * into v_visite;

  if not found then
    return jsonb_build_object('ferme', false);
  end if;

  perform public.log_sensitive_access(
    'observation_sortie', 'guardian_session_visit', v_visite.id::text,
    jsonb_build_object('session_id', p_session_id, 'duration_seconds', v_visite.duration_seconds)
  );

  return jsonb_build_object('ferme', true, 'duration_seconds', v_visite.duration_seconds);
end;
$$;

-- Droits : a l'identique de 0033:1232-1233. La fonction est volatile (elle
-- ecrit) : `agent_ro` n'apparait que dans le revoke, jamais dans le grant.
revoke execute on function public.sortir_observation(uuid) from public, anon, agent_ro;
grant execute on function public.sortir_observation(uuid) to authenticated;

-- ============================================================================
-- Controle de sortie -- modele 0030_tc_socle.sql:218-230. Une migration qui ne
-- prend pas doit echouer bruyamment, jamais passer en silence. Chaque controle
-- est ecrit en EXIGENCE POSITIVE : un `if valeur <> attendue` ne se declenche
-- pas quand la ligne manque, puisque NULL n'est pas vrai.
-- ============================================================================
do $$
declare
  v_oid    oid;
  v_nb     int;
  v_source text;
begin
  -- La fonction existe, et une seule de ce nom : une surcharge rendrait
  -- l'appel de autoriser_jeton_video ambigu.
  v_oid := to_regprocedure('public.budget_observation(uuid)')::oid;
  if v_oid is null then
    raise exception '0039 incomplete : public.budget_observation(uuid) est absente';
  end if;

  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'budget_observation';
  if v_nb <> 1 then
    raise exception '0039 incomplete : % fonction(s) budget_observation, 1 attendue', v_nb;
  end if;

  -- Elle ne fait que lire : `stable` est ce qui le dit au planificateur.
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 's' then
    raise exception '0039 incomplete : budget_observation n''est plus stable';
  end if;

  -- Elle doit rester security definer : sans cela elle ne lirait plus rien
  -- sous la RLS de l'appelant.
  if not (select p.prosecdef from pg_catalog.pg_proc p where p.oid = v_oid) then
    raise exception '0039 incomplete : budget_observation n''est plus security definer';
  end if;

  -- Le search_path vide est ce qui rend les objets schema-qualifies
  -- obligatoires, et donc la fonction insensible au chemin de l'appelant.
  -- Postgres stocke `set search_path = ''` sous la forme litterale
  -- `search_path=""` dans proconfig (constate, pas suppose).
  if not exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid = v_oid and p.proconfig @> array['search_path=""']
  ) then
    raise exception '0039 incomplete : budget_observation n''a plus search_path vide';
  end if;

  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid;

  -- Le quota de visites ne doit plus etre exige que lorsque aucune visite
  -- n'est ouverte. C'est la correction entiere, exigee par sa presence.
  if v_source not like '%v_ouverte is null and v_visites >= v_max_v%' then
    raise exception '0039 incomplete : le quota de visites ne se garde pas sur l''absence d''intervalle ouvert';
  end if;

  -- Le temps, lui, est exige dans les deux cas : c'est ce qui interdit un
  -- jeton de duree nulle.
  if v_source not like '%v_restant <= 0%' then
    raise exception '0039 incomplete : le temps restant ne refuse pas l''emission';
  end if;

  -- Les acquis de 0036 doivent survivre : le plafond par visite est lu, et le
  -- restant est le minimum des deux restes. Les deux sont exiges separement.
  if v_source not like '%max_seconds_per_visit%' then
    raise exception '0039 incomplete : budget_observation ne lit plus le plafond par visite (acquis 0036)';
  end if;
  if v_source not like '%least(v_reste_t, v_reste_v)%' then
    raise exception '0039 incomplete : restant_secondes n''est plus le minimum des deux restes (acquis 0036)';
  end if;

  -- EXECUTE arrive par DEUX chemins : verifier chaque role SEPAREMENT, jamais
  -- presumer qu'un revoke de public/anon a touche authenticated.
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0039 incomplete : anon garde EXECUTE sur budget_observation';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0039 incomplete : authenticated n''a pas EXECUTE sur budget_observation';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0039 incomplete : agent_ro a EXECUTE sur budget_observation';
  end if;

  -- public.autoriser_jeton_video n'est pas touchee par ce lot, mais elle est
  -- la raison d'etre de la correction : si elle disparaissait ou changeait de
  -- signature, la correction ne servirait plus rien et il faut le savoir ici.
  if to_regprocedure('public.autoriser_jeton_video(uuid, uuid, text, text)') is null then
    raise exception '0039 incomplete : public.autoriser_jeton_video(uuid, uuid, text, text) est absente';
  end if;

  -- ==========================================================================
  -- B. La sortie d'observation
  -- ==========================================================================
  v_oid := to_regprocedure('public.sortir_observation(uuid)')::oid;
  if v_oid is null then
    raise exception '0039 incomplete : public.sortir_observation(uuid) est absente';
  end if;

  -- Elle ecrit : elle doit rester volatile, c'est ce qui interdit agent_ro.
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 'v' then
    raise exception '0039 incomplete : sortir_observation n''est plus volatile';
  end if;

  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid;

  -- Elle doit nommer la fin par une valeur que la contrainte admet.
  if v_source not like '%fin_de_visite = ''sortie_volontaire''%' then
    raise exception '0039 incomplete : sortir_observation ne nomme pas une fin de visite valide';
  end if;

  -- Et ne plus ecrire la colonne generee. Controle en exigence positive de
  -- l'absence : c'est l'ecriture qui est la faute, et elle est nommee.
  if v_source like '%set duration_seconds%' or v_source like '%duration_seconds =%' then
    raise exception '0039 incomplete : sortir_observation ecrit encore la colonne generee duration_seconds';
  end if;

  -- La preuve qui compte : la valeur ecrite doit passer la contrainte de la
  -- table. On la demande a la contrainte elle-meme plutot qu'a une liste
  -- recopiee ici, qui pourrait diverger.
  if not exists (
    select 1 from pg_catalog.pg_constraint c
     where c.conrelid = 'public.guardian_session_visit'::regclass
       and c.conname = 'guardian_session_visit_fin_de_visite_check'
       and pg_catalog.pg_get_constraintdef(c.oid) like '%''sortie_volontaire''%'
  ) then
    raise exception '0039 incomplete : la contrainte de fin de visite n''admet pas sortie_volontaire';
  end if;

  -- Les trois roles, un par un, ici aussi.
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0039 incomplete : anon garde EXECUTE sur sortir_observation';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0039 incomplete : authenticated n''a pas EXECUTE sur sortir_observation';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0039 incomplete : agent_ro a EXECUTE sur une fonction volatile';
  end if;
end $$;
