-- K4 (Boucle 1, etape 4), consigne du pilote du 30/10/2026 :
-- docs/current/K4-RESTE-2026-10-30.md, n° 16 et n° 13.
--
-- 1. N° 16 : rien ne faisait passer une seance de `planned` a `in_progress`
--    (seule `private.ses_cloturer_seances_echues` ecrivait un statut, apres
--    la fin). Desormais, l'arrivee de l'enseignant dans la salle, constatee
--    par le webhook LiveKit `participant_joined`, fait passer la seance par
--    `preflight` puis `in_progress` (la machine d'etats de 0001 n'admet que
--    ce chemin).
--
--    Pourquoi le webhook de l'enseignant, et non le premier jeton ni
--    `room_started` :
--    * `in_progress` ouvre le temps paye : `x217_marquer_temps_session` pose
--      `finance_started_at` a ce moment. Un jeton est delivre jusqu'a
--      `join_window_minutes` avant le debut, peut etre redemande, et ne
--      prouve pas que l'enseignant est entre (la signature peut echouer, la
--      connexion aussi) ;
--    * `room_started` ne nomme personne : la salle s'ouvre a l'arrivee du
--      premier participant, qui peut etre un eleve en avance ;
--    * `participant_joined` est signe par LiveKit, horodate par le serveur,
--      porte l'identite inscrite dans le jeton par la base, et c'est deja la
--      preuve de presence que lit la cloture automatique (meme regle :
--      l'enseignant titulaire ou l'enseignant effectif).
--    Limite dite : si les webhooks n'arrivent pas en production, la seance
--    reste `planned`, comme la presence (lecture a faire :
--    `livekit_webhook_deliveries`).
--
--    Le passage ne peut jamais faire perdre la presence : il est fait dans un
--    sous-bloc ; une erreur (machine d'etats, declencheur) est consignee dans
--    le journal de reception et la presence reste ecrite.
--
-- 2. N° 13 (journal des pistes) : le journal de reception garde desormais
--    l'identite du participant (`detail.profile_id`) pour tout evenement,
--    donc pour `track_published` et `track_unpublished` ; la fonction Edge
--    `livekit-webhook` y ajoute la description de la piste (`detail.piste`).
--    Aucune table nouvelle (§33 : pas d'evenement brut comme ligne du
--    metier).
--
-- Aucun mot de suppression dans ce fichier. Le corps est remplace a l'identique
-- ailleurs ; le bloc refuse de continuer s'il ne trouve pas un passage tel
-- quel. La fonction ne porte pas d'empreinte F86.

BEGIN;

DO $webhook$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.enregistrer_webhook_livekit(text,text,text,uuid,timestamp with time zone,jsonb)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_avant_1 text := $a$values (p_event_id, p_event_type, p_room_name, coalesce(p_detail, '{}'::jsonb))$a$;
  v_apres_1 text := $a$values (p_event_id, p_event_type, p_room_name,
          coalesce(p_detail, '{}'::jsonb)
          || case when p_profile_id is null then '{}'::jsonb
                  else jsonb_build_object('profile_id', p_profile_id) end)$a$;
  v_avant_2 text := $a$  values (v_session_id, p_profile_id, v_type, coalesce(p_server_ts, now()), v_source);
$a$;
  v_apres_2 text := $a$  values (v_session_id, p_profile_id, v_type, coalesce(p_server_ts, now()), v_source);

  -- K4 n° 16 (30/10/2026) : l'enseignant entre, la seance commence. Meme
  -- regle de presence que la cloture automatique (titulaire ou effectif).
  -- Une seance deja commencee, close ou annulee ne change pas.
  if v_type = 'joined' and exists (
    select 1 from public.sessions s
     where s.id = v_session_id
       and s.deleted_at is null
       and s.status in ('planned', 'preflight')
       and p_profile_id in (s.teacher_id,
             coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id))
  ) then
    begin
      update public.sessions set status = 'preflight'
       where id = v_session_id and status = 'planned';
      update public.sessions set status = 'in_progress'
       where id = v_session_id and status = 'preflight';
    exception when others then
      -- La presence passe avant le statut : l'echec est consigne, pas leve.
      raise warning 'seance % : passage en cours impossible : %', v_session_id, sqlerrm;
      update public.livekit_webhook_deliveries
         set detail = detail || jsonb_build_object('statut_seance_erreur', sqlerrm)
       where event_id = p_event_id;
    end;
  end if;
$a$;
BEGIN
  IF pg_catalog.strpos(v_def, v_avant_1) = 0 OR pg_catalog.strpos(v_def, v_avant_2) = 0 THEN
    RAISE EXCEPTION 'enregistrer_webhook_livekit : le corps a change, migration a revoir';
  END IF;
  IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_avant_2) + 1), v_avant_2) <> 0 THEN
    RAISE EXCEPTION 'enregistrer_webhook_livekit : passage ambigu, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(pg_catalog.replace(v_def, v_avant_1, v_apres_1), v_avant_2, v_apres_2);
END;
$webhook$;

-- Postflight : le nouveau corps est en place, droits inchanges (0010 :
-- service_role seul).
DO $postflight$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.enregistrer_webhook_livekit(text,text,text,uuid,timestamp with time zone,jsonb)'::pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), 'K4 n° 16') = 0 THEN
    RAISE EXCEPTION 'postflight : le passage en cours manque';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'postflight : enregistrer_webhook_livekit est ouverte au client';
  END IF;
END;
$postflight$;

COMMIT;
