-- La seance s'ouvre aussi quand le serveur delivre le jeton video a
-- l'enseignant effectif (consigne du pilote du 31/10/2026, PR
-- claude/seance-ouverte-jeton).
--
-- Depuis 20261030120000, seule l'arrivee de l'enseignant constatee par le
-- webhook LiveKit `participant_joined` fait passer la seance de `planned` a
-- `in_progress`. Si ce webhook se perd, la seance reste planifiee pendant
-- qu'on y enseigne.
--
-- Desormais `autoriser_jeton_video`, apres avoir delivre le jeton, fait le
-- meme passage (`planned` -> `preflight` -> `in_progress`, seul chemin de la
-- machine d'etats de 0001) quand le jeton part a l'enseignant EFFECTIF de la
-- seance (`private.c29_enseignant_effectif_session`, titulaire ou remplacant
-- designe), dans la fenetre d'entree : la fonction la verifie deja avant
-- tout jeton (jusqu'a la fin plus `grace_after_end_minutes`), et l'ouverture
-- exige en plus `join_window_minutes` avant le debut au plus tot, meme si
-- `join_opens_at` a ete avancee (en production elle vaut exactement cela). Le titulaire remplace ne recoit deja aucun
-- jeton (refus « non inscrit a cette seance ») ; la condition est reecrite
-- ici en exigence positive pour qu'il n'ouvre rien meme si ce refus changeait.
--
-- Idempotent : chaque passage ne s'applique qu'a son statut de depart ; une
-- seance deja `in_progress` (par le webhook ou un jeton precedent), close ou
-- annulee ne change pas. Le webhook et le jeton peuvent arriver tous les deux,
-- dans n'importe quel ordre : le second ne trouve plus de ligne a passer.
--
-- Le jeton passe avant le statut : le passage est fait dans un sous-bloc ;
-- une erreur (machine d'etats, declencheur) est dite par un avertissement et
-- le jeton est rendu.
--
-- Ce que ce choix change, dit ici (la migration du 30/10 avait ecarte le
-- jeton pour ces raisons) :
--   * `in_progress` ouvre le temps paye (`x217_marquer_temps_session`) : il
--     peut desormais s'ouvrir des le jeton, jusqu'a `join_window_minutes`
--     avant le debut, avant l'entree reelle dans la salle ;
--   * un enseignant qui obtient le jeton sans jamais entrer laisse une seance
--     `in_progress` que la cloture automatique ferme en `tech_failure` (revue
--     de la direction, aucune paie automatique), et non plus en
--     `teacher_absent`.
--
-- Aucun mot de suppression dans ce fichier. Le corps est remplace a
-- l'identique ailleurs ; le bloc refuse de continuer s'il ne trouve pas son
-- point d'ancrage une seule fois. Les droits ne changent pas.

BEGIN;

DO $jeton$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre text := $a$  perform public.log_sensitive_access(
    'video_token_issued',$a$;
  v_avant text := $a$
  -- Ouverture par le jeton (02/11/2026) : le jeton part a l'enseignant
  -- effectif, dans la fenetre deja verifiee plus haut, la seance commence.
  -- Meme passage que le webhook `participant_joined` ; idempotent.
  if v_role = 'teacher'
     and p_profile_id = coalesce(private.c29_enseignant_effectif_session(p_session_id),
                                 v_seance.teacher_id)
     and v_seance.status in ('planned', 'preflight')
     -- Jamais plus tot que la fenetre normale, meme si `join_opens_at` a ete
     -- avancee : le temps paye ne s'ouvre pas des jours a l'avance.
     and now() >= v_seance.started_at - make_interval(mins => v_fenetre) then
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

-- Postflight : le nouveau corps est en place, la fonction reste fermee au
-- client (create-room-token l'appelle sous service_role).
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
END;
$postflight$;

COMMIT;
