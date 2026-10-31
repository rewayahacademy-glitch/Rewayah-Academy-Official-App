-- La seance s'ouvre aussi quand le serveur delivre le jeton video a
-- l'enseignant effectif, a partir de son heure de debut (consigne du pilote
-- du 31/10/2026 et sa decision du meme jour sur la PR #100).
--
-- Depuis 20261030120000, seule l'arrivee de l'enseignant constatee par le
-- webhook LiveKit `participant_joined` fait passer la seance de `planned` a
-- `in_progress`. Si ce webhook se perd, la seance reste planifiee pendant
-- qu'on y enseigne.
--
-- 1. `autoriser_jeton_video`, apres avoir delivre le jeton, fait le meme
--    passage (`planned` -> `preflight` -> `in_progress`, seul chemin de la
--    machine d'etats de 0001) quand le jeton part a l'enseignant EFFECTIF de
--    la seance (`private.c29_enseignant_effectif_session`, titulaire ou
--    remplacant designe), et seulement a partir de `started_at` : avant
--    l'heure, rien ne change d'etat (decision du pilote). La fin de fenetre
--    (fin plus `grace_after_end_minutes`) est deja verifiee avant tout jeton.
--    Le titulaire remplace ne recoit deja aucun jeton ; la condition est
--    reecrite en exigence positive pour qu'il n'ouvre rien meme si ce refus
--    changeait. Un eleve, un tuteur, la direction n'ouvrent jamais rien.
--
--    Idempotent : chaque passage ne s'applique qu'a son statut de depart ;
--    une seance deja `in_progress` (par le webhook ou un jeton precedent),
--    close ou annulee ne change pas. Le webhook et le jeton peuvent arriver
--    tous les deux, dans n'importe quel ordre. Le jeton passe avant le
--    statut : une erreur du passage est dite par un avertissement, le jeton
--    est rendu.
--
-- 2. Un enseignant qui a obtenu le jeton sans entrer (aucun `joined` du
--    titulaire ni de l'enseignant effectif dans `session_events`) finit en
--    `teacher_absent`, jamais en `tech_failure` (decision du pilote) :
--    `tech_failure` reste reserve a un enseignant entre dont la seance a
--    echoue techniquement.
--    * la machine d'etats admet `in_progress` -> `teacher_absent`, et
--      seulement sans aucun `joined` de l'enseignant ;
--    * la cloture automatique (`private.ses_cloturer_seances_echues`) ferme
--      une seance `in_progress` sans arrivee de l'enseignant en
--      `teacher_absent` au lieu de `tech_failure`.
--    La paie ne compte que `ended` et `tech_failure` : une telle seance
--    n'est jamais payee.
--
-- 3. Ce que ce fichier ne fait PAS, dit ici : le temps paye
--    (`finance_started_at`) est toujours pose par le declencheur de
--    tresorerie `x217_marquer_temps_session` au passage en `in_progress`.
--    Le passage par le jeton le pose donc a l'heure du jeton (jamais avant
--    `started_at`). Le lot PRESENCE (minutes reellement connectees, decision
--    du 31/10 dans 08) n'existe pas encore ; changer ce declencheur est hors
--    de cette PR (paie).
--
-- Aucun mot de suppression dans ce fichier. Chaque corps est remplace a
-- l'identique ailleurs ; chaque bloc refuse de continuer s'il ne trouve pas
-- son point d'ancrage exactement une fois. Les droits ne changent pas.

BEGIN;

-- 1. Ouverture par le jeton.
DO $jeton$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre text := $a$  perform public.log_sensitive_access(
    'video_token_issued',$a$;
  v_avant text := $a$
  -- Ouverture par le jeton (02/11/2026) : le jeton part a l'enseignant
  -- effectif, l'heure de debut est atteinte, la seance commence. Meme
  -- passage que le webhook `participant_joined` ; idempotent.
  if v_role = 'teacher'
     and p_profile_id = coalesce(private.c29_enseignant_effectif_session(p_session_id),
                                 v_seance.teacher_id)
     and v_seance.status in ('planned', 'preflight')
     -- Jamais avant l'heure (decision du pilote, 31/10/2026).
     and now() >= v_seance.started_at then
    begin
      update public.sessions set status = 'preflight'
       where id = p_session_id and status = 'planned';
      update public.sessions set status = 'in_progress'
       where id = p_session_id and status = 'preflight';
    exception when others then
      -- Le jeton passe avant le statut : l'echec est dit, pas leve.
      raise warning 'seance % : ouverture par le jeton impossible : %', p_session_id, sqlerrm;
    end;
  end if;

$a$;
BEGIN
  IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
    RAISE EXCEPTION 'autoriser_jeton_video : le corps a change, migration a revoir';
  END IF;
  IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_ancre) + 1), v_ancre) <> 0 THEN
    RAISE EXCEPTION 'autoriser_jeton_video : ancrage ambigu, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre, v_avant || v_ancre);
END;
$jeton$;

-- 2 a. Machine d'etats : `in_progress` -> `teacher_absent`, sans arrivee de
--      l'enseignant seulement.
DO $machine$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.guard_session_state_transition()'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre text := $a$(old.status = 'in_progress' and new.status in ('ended', 'tech_failure'))$a$;
  v_apres text := $a$(old.status = 'in_progress' and new.status in ('ended', 'tech_failure')) or
    -- 02/11/2026 : seance ouverte (par le jeton) ou l'enseignant n'est jamais
    -- entre. Jamais apres une arrivee : `tech_failure` reste a l'enseignant
    -- entre.
    (old.status = 'in_progress' and new.status = 'teacher_absent'
     and not exists (
       select 1 from public.session_events e
        where e.session_id = new.id
          and e.event_type = 'joined'
          and e.profile_id in (new.teacher_id,
                coalesce(private.c29_enseignant_effectif_session(new.id), new.teacher_id))))$a$;
BEGIN
  IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
    RAISE EXCEPTION 'guard_session_state_transition : le corps a change, migration a revoir';
  END IF;
  IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_ancre) + 1), v_ancre) <> 0 THEN
    RAISE EXCEPTION 'guard_session_state_transition : ancrage ambigu, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre, v_apres);
END;
$machine$;

-- 2 b. Cloture automatique : `in_progress` sans arrivee -> `teacher_absent`.
DO $cloture$
DECLARE
  v_f pg_catalog.regprocedure :=
    'private.ses_cloturer_seances_echues(timestamp with time zone)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre text := $a$      ELSIF v_s.status = 'in_progress' THEN
        v_cible := 'tech_failure';
      ELSE
        v_cible := 'teacher_absent';
      END IF;$a$;
  v_apres text := $a$      ELSE
        -- 02/11/2026 : planifiee, preparee ou ouverte (par le jeton), sans
        -- arrivee de l'enseignant : absence de l'enseignant, jamais une panne.
        v_cible := 'teacher_absent';
      END IF;$a$;
BEGIN
  IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
    RAISE EXCEPTION 'ses_cloturer_seances_echues : le corps a change, migration a revoir';
  END IF;
  IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_ancre) + 1), v_ancre) <> 0 THEN
    RAISE EXCEPTION 'ses_cloturer_seances_echues : ancrage ambigu, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre, v_apres);
END;
$cloture$;

-- Postflight : les trois corps sont en place, droits inchanges.
DO $postflight$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), 'Ouverture par le jeton (02/11/2026)') = 0 THEN
    RAISE EXCEPTION 'postflight : l''ouverture par le jeton manque';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'postflight : autoriser_jeton_video est ouverte a anon';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.guard_session_state_transition()'::pg_catalog.regprocedure),
       'new.status = ''teacher_absent''') = 0 THEN
    RAISE EXCEPTION 'postflight : la machine d''etats n''admet pas l''absence apres ouverture';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'private.ses_cloturer_seances_echues(timestamp with time zone)'::pg_catalog.regprocedure),
       'v_cible := ''tech_failure''') <> 0 THEN
    RAISE EXCEPTION 'postflight : la cloture produit encore tech_failure sans arrivee';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.ses_cloturer_seances_echues(timestamp with time zone)', 'EXECUTE') THEN
    RAISE EXCEPTION 'postflight : la cloture est ouverte au client';
  END IF;
END;
$postflight$;

COMMIT;
