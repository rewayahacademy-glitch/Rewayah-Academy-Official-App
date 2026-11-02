-- Lot C1 (02/11/2026) : creer, cloturer, recreer une classe.
--
-- FICHIER SANS MOT D'EFFACEMENT (B5) : le pilote l'installe. Additif (B6) :
-- aucune signature ne change, aucun objet n'est renomme ni retire ; l'ancien
-- client lit les memes messages (le texte de chaque refus est garde, seul son
-- DETAIL s'enrichit).
--
-- 1. FN-103 : cloturer_groupe annule aussi les seances 'planned' et
--    'preflight' de la classe qui n'ont pas ete lancees et ne sont pas
--    finies (ended_at > now()), y compris celle dont l'heure de debut est
--    passee (classe close pendant sa seance). Avant, seules les seances a
--    venir (started_at > now()) passaient a 'canceled' : la seance en cours
--    gardait l'enseignant dans sessions_no_teacher_overlap et une nouvelle
--    classe au meme horaire etait refusee. Le cas 'in_progress' n'est PAS
--    touche : D1 du directeur (02/11/2026) : une seance in_progress va a son
--    terme. Rattrapage pour les classes deja closes, dans la meme regle.
-- 2. guard_session_state_transition admet 'preflight' -> 'canceled' pour la
--    seule seance d'une classe close (sans quoi le point 1 leverait
--    « transition de session non autorisee »). Aucune autre transition ne
--    change.
-- 3. UX-020 : le refus de chevauchement nomme la classe et l'heure en
--    conflit, dans son DETAIL (le message, lu par les clients, ne change pas) :
--    - app_private.verifier_affectation_enseignant_base, refus
--      « chevauchement avec une classe ou affectation active » : DETAIL JSON
--      {"classe", "jour", "heure", "fuseau"} (horaire recurrent de l'autre
--      classe ; classe nulle pour un eleve suivi seul) ;
--    - app_private.verifier_horaire_contre_seances_planifiees, refus
--      « chevauchement avec une séance existante » : la phrase d'avant, puis un
--      espace et un JSON {"classe", "date", "jour", "heure", "minute",
--      "fuseau"} (la seance datee) ; pour deux creneaux de la meme classe,
--      {"creneaux_propres": true} ;
--    - public.creer_classe_creneaux_admin : un 23P01 a la materialisation
--      (seance deja planifiee de l'enseignant) devient ce refus nomme (3c).
--
-- Lecteurs recenses (B1, aucune colonne ne change de sens ; le DETAIL change) :
--   SQL   : supabase/tests/scenarios_classes_duree_bout_en_bout.sql (G1, LIKE
--           '%autre Classe%' : garde, la phrase reste en tete) ;
--           scenarios_classes_duree_affectation.sql (pg_temp.detail : seul le
--           refus d'indisponibilite, inchange) ; aucun autre test ne lit ce
--           DETAIL. Les fonctions qui appellent le predicat
--           (creer_groupe, creer_classe_creneaux_admin, reaffecter_classe,
--           modifier_groupe_horaire...) laissent passer l'exception telle quelle.
--   Edge  : aucune fonction ne lit ces refus.
--   Dart  : lib/core/admin/creation_classe_refusee.dart (lit le DETAIL depuis
--           ce lot ; un DETAIL sans JSON donne la phrase d'avant) ;
--           lib/core/admin/plafond_classes.dart (autre refus, inchange).
--
-- Chaque fonction est retouchee par ancre (pg_temp.remplacer, B4) : la
-- migration s'arrete si une ancre n'est pas trouvee exactement le nombre de
-- fois dit. Les empreintes F86 eventuelles suivent ; un postflight verifie.

BEGIN;

CREATE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- 1. FN-103 : la cloture annule aussi la seance en cours non lancee.
SELECT pg_temp.remplacer('public.cloturer_groupe(uuid,text)',
  $a$and s.status = 'planned' and s.started_at > now();$a$,
  $b$and s.status in ('planned', 'preflight') and s.ended_at > now();$b$, 1);

-- 2. La seule transition ajoutee : preflight -> canceled, classe close.
SELECT pg_temp.remplacer('public.guard_session_state_transition()',
  $a$    (old.status = 'preflight' and new.status in ('in_progress', 'teacher_absent', 'student_absent')) or$a$,
  $b$    (old.status = 'preflight' and new.status in ('in_progress', 'teacher_absent', 'student_absent')) or
    -- C1 (02/11/2026) : une seance non lancee d'une classe close (FN-103).
    (old.status = 'preflight' and new.status = 'canceled'
     and exists (select 1 from public.groupes g
                  where g.id = new.groupe_id and g.ended_at is not null)) or$b$, 1);

-- 3a. Le predicat : le nom et l'horaire de la classe en conflit.
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$SELECT DISTINCT busy.weekday, busy.hour_local, busy.timezone_iana, busy.duree
$a$,
  $b$SELECT DISTINCT busy.weekday, busy.hour_local, busy.timezone_iana, busy.duree, busy.nom
$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$g.timezone_iana,
               slots.duree
        FROM public.groupes g
        CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) slots
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
        UNION$a$,
  $b$g.timezone_iana,
               slots.duree, g.libelle AS nom
        FROM public.groupes g
        CROSS JOIN LATERAL app_private.creneaux_de_classe(g.id) slots
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
        UNION$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$v_duree_individuelle AS duree
$a$,
  $b$v_duree_individuelle AS duree, NULL::text AS nom
$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)',
  $a$RAISE EXCEPTION 'chevauchement avec une classe ou affectation active';$a$,
  $b$RAISE EXCEPTION 'chevauchement avec une classe ou affectation active'
              USING DETAIL = pg_catalog.json_build_object(
                'classe', v_busy.nom,
                'jour', v_busy.weekday,
                'heure', v_busy.hour_local,
                'fuseau', v_busy.timezone_iana)::text;$b$, 1);

-- 3b. Les seances deja planifiees : la seance datee en conflit.
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$  v_propre boolean;
$a$,
  $b$  v_propre boolean;
  v_c1_nom text;
  v_c1_debut timestamptz;
  v_c1_fuseau text;
$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$USING DETAIL = 'deux creneaux de cette Classe se chevauchent';$a$,
  $b$USING DETAIL = 'deux creneaux de cette Classe se chevauchent '
        || pg_catalog.json_build_object('creneaux_propres', true)::text;$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$SELECT s.groupe_id IS NOT DISTINCT FROM p_groupe_id INTO v_propre$a$,
  $b$SELECT s.groupe_id IS NOT DISTINCT FROM p_groupe_id, og.libelle, s.started_at,
         coalesce(og.timezone_iana, v_g.timezone_iana)
    INTO v_propre, v_c1_nom, v_c1_debut, v_c1_fuseau$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$  ORDER BY (s.groupe_id IS NOT DISTINCT FROM p_groupe_id) DESC
  LIMIT 1;$a$,
  $b$  LEFT JOIN public.groupes og ON og.id = s.groupe_id
  ORDER BY (s.groupe_id IS NOT DISTINCT FROM p_groupe_id) DESC
  LIMIT 1;$b$, 1);
SELECT pg_temp.remplacer('app_private.verifier_horaire_contre_seances_planifiees(uuid)',
  $a$ELSE 'ce creneau chevauche une seance a venir de cet enseignant dans une autre Classe ou hors Classe' END;$a$,
  $b$ELSE 'ce creneau chevauche une seance a venir de cet enseignant dans une autre Classe ou hors Classe' END
        || ' ' || pg_catalog.json_build_object(
             'classe', v_c1_nom,
             'date', pg_catalog.to_char(v_c1_debut AT TIME ZONE v_c1_fuseau, 'YYYY-MM-DD'),
             'jour', pg_catalog.date_part('isodow', v_c1_debut AT TIME ZONE v_c1_fuseau)::integer,
             'heure', pg_catalog.date_part('hour', v_c1_debut AT TIME ZONE v_c1_fuseau)::integer,
             'minute', pg_catalog.date_part('minute', v_c1_debut AT TIME ZONE v_c1_fuseau)::integer,
             'fuseau', v_c1_fuseau)::text;$b$, 1);

-- 3c. creer_classe_creneaux_admin : l'enseignant pose, la materialisation
-- heurtait sessions_no_teacher_overlap (23P01, texte technique) quand une
-- seance deja planifiee de cet enseignant (par exemple la seance lancee d'une
-- classe close) couvrait un creneau : verifier_horaire_contre_seances_planifiees
-- ne joue qu'au changement d'horaire, et la classe n'avait pas encore
-- d'enseignant a son premier appel. Sur 23P01, l'enseignant est pose seul
-- (classe encore en attente, aucune seance generee) et le controle nomme est
-- rejoue : il leve le refus nomme ; s'il ne trouve rien, l'erreur d'origine
-- repart telle quelle. Tout est annule par le refus.
SELECT pg_temp.remplacer('public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)',
  $a$  UPDATE public.groupes
     SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = v_id;$a$,
  $b$  BEGIN
    UPDATE public.groupes
       SET teacher_id = p_teacher_profile_id, etat = 'active'
     WHERE id = v_id;
  EXCEPTION WHEN exclusion_violation THEN
    -- C1 (02/11/2026) : le refus nomme la classe et l'heure (UX-020).
    UPDATE public.groupes SET teacher_id = p_teacher_profile_id WHERE id = v_id;
    PERFORM app_private.verifier_horaire_contre_seances_planifiees(v_id);
    RAISE;
  END;$b$, 1);

-- Rattrapage (FN-103) : les seances non lancees et non finies des classes
-- deja closes.
UPDATE public.sessions s
   SET status = 'canceled', updated_at = pg_catalog.now()
  FROM public.groupes g
 WHERE g.id = s.groupe_id AND g.ended_at IS NOT NULL
   AND s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
   AND s.ended_at > pg_catalog.now();

-- Empreintes F86 : celles qui existent suivent le nouveau corps.
DO $empreintes$
DECLARE
  v_f pg_catalog.regprocedure;
  v_com text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'public.cloturer_groupe(uuid,text)'::pg_catalog.regprocedure,
    'public.guard_session_state_transition()'::pg_catalog.regprocedure,
    'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::pg_catalog.regprocedure,
    'app_private.verifier_horaire_contre_seances_planifiees(uuid)'::pg_catalog.regprocedure,
    'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure
  ] LOOP
    v_com := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
    END IF;
  END LOOP;
END;
$empreintes$;

DO $postflight$
DECLARE
  v_src text;
BEGIN
  v_src := pg_catalog.pg_get_functiondef('public.cloturer_groupe(uuid,text)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_src, $x$s.status in ('planned', 'preflight') and s.ended_at > now()$x$) = 0 THEN
    RAISE EXCEPTION 'C1 : cloturer_groupe sans la nouvelle annulation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.cloturer_groupe(uuid,text)'::pg_catalog.regprocedure
                    AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', 'public.cloturer_groupe(uuid,text)'::pg_catalog.regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.cloturer_groupe(uuid,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'C1 : cloturer_groupe a perdu DEFINER, search_path ou ses droits';
  END IF;
  v_src := pg_catalog.pg_get_functiondef('public.guard_session_state_transition()'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_src, $x$(old.status = 'preflight' and new.status = 'canceled'$x$) = 0 THEN
    RAISE EXCEPTION 'C1 : la garde des transitions sans preflight -> canceled';
  END IF;
  v_src := pg_catalog.pg_get_functiondef('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_src, $x$'classe', v_busy.nom$x$) = 0
     OR pg_catalog.strpos(v_src, 'chevauchement avec une classe ou affectation active') = 0 THEN
    RAISE EXCEPTION 'C1 : le predicat ne nomme pas la classe en conflit';
  END IF;
  v_src := pg_catalog.pg_get_functiondef('app_private.verifier_horaire_contre_seances_planifiees(uuid)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_src, $x$'classe', v_c1_nom$x$) = 0
     OR pg_catalog.strpos(v_src, 'creneaux_propres') = 0
     OR pg_catalog.strpos(v_src, 'dans une autre Classe ou hors Classe') = 0 THEN
    RAISE EXCEPTION 'C1 : le controle des seances planifiees ne nomme pas la seance en conflit';
  END IF;
  v_src := pg_catalog.pg_get_functiondef('public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_src, 'EXCEPTION WHEN exclusion_violation THEN') = 0 THEN
    RAISE EXCEPTION 'C1 : creer_classe_creneaux_admin sans le refus nomme sur 23P01';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure
                    AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', 'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'C1 : creer_classe_creneaux_admin a perdu DEFINER, search_path ou ses droits';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'app_private.verifier_horaire_contre_seances_planifiees(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'C1 : un controle interne est executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
