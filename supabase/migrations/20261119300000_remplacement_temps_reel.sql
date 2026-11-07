-- REMPLACEMENT-TEMPS-REEL (lot 5 du plan des trois salles, 07/11/2026). Plage
-- reservee par le pilote : 20261119300000-20261119399999.
--
-- Regle unique : docs/current/DECISION-REMPLACEMENT-2026-11-07.md. « Tout le
-- monde est alerte. Parmi ceux qui acceptent dans les premieres secondes, le
-- serveur retient le mieux place selon une liste de preferences ; a egalite,
-- le premier arrive. »
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement.
-- Sans BEGIN ni COMMIT de premier niveau.
--
-- Ce qui change, et rien d'autre :
-- 1. L'alerte (declencheur remplacements_seance_notifier_enseignants ; le
--    courriel et l'appareil suivent la notification), les offres
--    (offres_remplacement), la pre-alerte (private.remplacement_candidat) et
--    la prise passent par l'eligibilite SANS genre qui existe deja
--    (private.remplacant_eligible_sans_genre) : toute l'equipe (actif, piece
--    approuvee). Exception datee a la separation femmes-hommes, pour le
--    remplacement seulement (une seance). public.remplacement_enseignant_
--    compatible garde son sens : la direction y lit « genre compatible ».
-- 2. Deux reglages dans app_config : remplacement.preferences (liste ordonnee
--    des criteres, ["genre", "langue"] ; liste vide : le premier arrive) et
--    remplacement.fenetre_priorite_secondes (8, de 5 a 10).
-- 3. Un journal prive des acceptations (une par absence et par enseignant),
--    sans acces client, append-only.
-- 4. UNE fonction de rang (private.remplacement_rang) et UNE fonction de choix
--    (private.remplacement_choisir), sous le verrou de la seance : un rang 1
--    est retenu aussitot ; sinon, a la fin de la fenetre ouverte par la
--    premiere acceptation, le meilleur rang, puis le premier arrive. Le choix
--    ecrit « remplacement_pris » dans remplacements_seance : les avis
--    existants partent (« Un autre enseignant a pris ce cours »).
-- 5. public.prendre_remplacement (meme signature, memes droits) enregistre
--    l'acceptation, appelle le choix et rend acceptee, dejaPrise ou enAttente
--    (fin de la fenetre, en tete ou non). Preflight md5 du corps de
--    production.
-- 6. La fin de fenetre est tranchee par l'appel du client a la fin du compte a
--    rebours (prendre_remplacement est idempotent : choix paresseux), et,
--    en filet seulement, par une tache pg_cron chaque minute (si le client a
--    quitte avant la fin du compte a rebours).

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.remplacements_acceptations') IS NOT NULL THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : deja installee';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.prendre_remplacement(uuid,uuid)'::regprocedure)
     <> '01041c96214557b0d7c7815898e3365c' THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : prendre_remplacement a change depuis le depot';
  END IF;
  IF pg_catalog.to_regprocedure('private.remplacant_libre_a_l_heure(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : une dependance manque';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les reglages
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('remplacement.preferences', '["genre", "langue"]'::jsonb),
  ('remplacement.fenetre_priorite_secondes', '8'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Toute l'equipe : l'alerte, les offres et la pre-alerte sans filtre de genre
-- ---------------------------------------------------------------------------
-- public.remplacement_enseignant_compatible garde son sens (le genre de la
-- classe) : la direction s'en sert pour dire « genre compatible »
-- (remplacants_possibles_seance) et pour sa designation. Les trois fonctions
-- qui alertent, proposent et pre-alertent l'equipe appellent desormais
-- l'eligibilite sans genre qui existe deja (private.remplacant_eligible_sans_
-- genre : compte actif, piece approuvee, classe active). Remplacement par
-- ancre, un appel par fonction, corps de production verifie par md5. Les
-- offres demandent en plus que l'enseignant soit libre a l'heure
-- (private.remplacant_libre_a_l_heure) : on ne propose jamais ce que
-- prendre_remplacement refusera.
DO $ancre_genre$
DECLARE
  c_ancre CONSTANT text := 'public.remplacement_enseignant_compatible(';
  c_neuf CONSTANT text := 'private.remplacant_eligible_sans_genre(';
  c_ancre_offres CONSTANT text := 'OR public.remplacement_enseignant_compatible(s.id, v_moi))';
  c_neuf_offres CONSTANT text :=
    'OR (private.remplacant_eligible_sans_genre(s.id, v_moi) AND private.remplacant_libre_a_l_heure(s.id, v_moi)))';
  v_cible record;
  v_avant record;
  v_def text;
  v_apres text;
  v_com text;
BEGIN
  IF pg_catalog.to_regprocedure('private.remplacant_eligible_sans_genre(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.remplacant_libre_a_l_heure(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : private.remplacant_eligible_sans_genre manque';
  END IF;
  FOR v_cible IN
    SELECT * FROM (VALUES
      ('public.remplacements_seance_notifier_enseignants()'::regprocedure, 'a0af54011ece2051531bb47cb95a93f5',
       c_ancre, c_neuf),
      ('public.offres_remplacement()'::regprocedure, '1ff6a8ccff9a8c9e0186bd6a136980d3',
       c_ancre_offres, c_neuf_offres),
      ('private.remplacement_candidat(uuid,uuid)'::regprocedure, '7bf8d6d53129937f29dd453dceba92d6',
       c_ancre, c_neuf)
    ) AS t(f, md5_prod, ancre, neuf)
  LOOP
    SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, pg_catalog.md5(p.prosrc) AS empreinte
      INTO v_avant FROM pg_catalog.pg_proc p WHERE p.oid = v_cible.f;
    IF v_avant.empreinte <> v_cible.md5_prod THEN
      RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : % a change depuis le depot (md5 %)', v_cible.f, v_avant.empreinte;
    END IF;
    v_def := pg_catalog.pg_get_functiondef(v_cible.f);
    -- L'ancre generale doit aussi n'apparaitre qu'une fois : aucun autre
    -- appel au filtre de genre ne reste dans la fonction.
    IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
       / pg_catalog.length(c_ancre) <> 1
       OR (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_cible.ancre, '')))
          / pg_catalog.length(v_cible.ancre) <> 1 THEN
      RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : ancre introuvable ou multiple dans %', v_cible.f;
    END IF;
    EXECUTE pg_catalog.replace(v_def, v_cible.ancre, v_cible.neuf);
    v_apres := pg_catalog.pg_get_functiondef(v_cible.f);
    IF pg_catalog.replace(v_apres, v_cible.neuf, v_cible.ancre) <> v_def THEN
      RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : % differe ailleurs que par l''appel', v_cible.f;
    END IF;
    -- L'empreinte F86 du commentaire suit la definition.
    v_com := pg_catalog.obj_description(v_cible.f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_cible.f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
          'md5_functiondef=' || pg_catalog.md5(v_apres)));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_cible.f AND p.prosecdef = v_avant.prosecdef
                      AND p.proowner = v_avant.proowner
                      AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                      AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
      RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : % : proprietaire, DEFINER, search_path ou droits modifies', v_cible.f;
    END IF;
  END LOOP;
END
$ancre_genre$;

-- ---------------------------------------------------------------------------
-- 3. Le journal des acceptations
-- ---------------------------------------------------------------------------
CREATE TABLE private.remplacements_acceptations (
  absence_id uuid NOT NULL REFERENCES public.remplacements_seance(id),
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  enseignant_id uuid NOT NULL REFERENCES public.profiles(id),
  rang smallint NOT NULL CHECK (rang >= 1),
  cle_idempotence uuid NOT NULL,
  recu_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (absence_id, enseignant_id)
);
CREATE INDEX remplacements_acceptations_session_idx
  ON private.remplacements_acceptations (session_id, recu_le);
REVOKE ALL ON private.remplacements_acceptations FROM PUBLIC;
-- Aucune modification : le declencheur refuse toute mise a jour ; aucun role
-- client n'a de droit sur la table (aucune suppression possible hors postgres).
CREATE TRIGGER remplacements_acceptations_immuable
  BEFORE UPDATE ON private.remplacements_acceptations
  FOR EACH ROW EXECUTE FUNCTION public.remplacements_seance_immutable();
COMMENT ON TABLE private.remplacements_acceptations IS
  'REMPLACEMENT-TEMPS-REEL (07/11/2026) : chaque « J''accepte » d''une absence, avec son rang ; '
  'lu par private.remplacement_choisir. Append-only, aucun acces client.';

-- ---------------------------------------------------------------------------
-- 4. Les reglages lus, le rang, le choix
-- ---------------------------------------------------------------------------
-- La fenetre, de 5 a 10 secondes. Un reglage absent, illisible ou hors
-- bornes ne bloque rien : le defaut (8 s), avec un WARNING.
CREATE FUNCTION private.remplacement_fenetre()
RETURNS interval
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v integer;
BEGIN
  BEGIN
    v := private.remplacement_reglage('remplacement.fenetre_priorite_secondes');
  EXCEPTION WHEN OTHERS THEN
    v := NULL;
  END;
  IF v IS NULL OR v NOT BETWEEN 5 AND 10 THEN
    RAISE WARNING 'REMPLACEMENT-TEMPS-REEL : remplacement.fenetre_priorite_secondes invalide, defaut 8 s';
    v := 8;
  END IF;
  RETURN pg_catalog.make_interval(secs => v);
END;
$function$;

-- La liste ordonnee des criteres. Une liste absente, illisible ou portant un
-- critere inconnu ne bloque rien : le defaut (["genre","langue"]), avec un
-- WARNING. Il n'y a jamais de second circuit.
CREATE FUNCTION private.remplacement_preferences()
RETURNS text[]
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_brut jsonb;
  v text[];
BEGIN
  SELECT c.value INTO v_brut FROM public.app_config c WHERE c.key = 'remplacement.preferences';
  IF v_brut IS NOT NULL AND pg_catalog.jsonb_typeof(v_brut) = 'array'
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_brut) e(x)
                      WHERE pg_catalog.jsonb_typeof(e.x) <> 'string'
                         OR e.x #>> '{}' NOT IN ('genre', 'langue')) THEN
    SELECT coalesce(pg_catalog.array_agg(x ORDER BY o), '{}'::text[]) INTO v
      FROM pg_catalog.jsonb_array_elements_text(v_brut) WITH ORDINALITY AS e(x, o);
    RETURN v;
  END IF;
  RAISE WARNING 'REMPLACEMENT-TEMPS-REEL : remplacement.preferences invalide, defaut ["genre","langue"]';
  RETURN ARRAY['genre', 'langue']::text[];
END;
$function$;

-- Le rang d'un enseignant pour une seance : 1 + la somme, pour chaque critere
-- non rempli, de 2^(nombre de criteres apres lui). Avec ["genre", "langue"] :
-- genre et langue (1), genre seul (2), langue seule (3), ni l'un ni l'autre
-- (4). Liste vide : tout le monde au rang 1, le premier arrive l'emporte.
-- Une classe mixte, ou sans langue connue, remplit le critere.
CREATE FUNCTION private.remplacement_rang(p_session_id uuid, p_teacher_id uuid)
RETURNS smallint
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_prefs text[] := private.remplacement_preferences();
  v_n integer := pg_catalog.cardinality(v_prefs);
  v_genre text;
  v_langue text;
  v_sexe public.gender;
  v_langues text[];
  v_rang integer := 1;
  v_ok boolean;
  i integer;
BEGIN
  SELECT g.genre_public, g.langue_code INTO v_genre, v_langue
    FROM public.sessions s JOIN public.groupes g ON g.id = s.groupe_id
   WHERE s.id = p_session_id;
  SELECT p.gender, coalesce(tp.languages, '{}'::text[]) INTO v_sexe, v_langues
    FROM public.profiles p LEFT JOIN public.teacher_profiles tp ON tp.profile_id = p.id
   WHERE p.id = p_teacher_id;
  FOR i IN 1 .. coalesce(v_n, 0) LOOP
    v_ok := CASE v_prefs[i]
      WHEN 'genre' THEN v_genre IS NULL OR v_genre NOT IN ('hommes', 'femmes')
                        OR (v_genre = 'hommes' AND v_sexe = 'male')
                        OR (v_genre = 'femmes' AND v_sexe = 'female')
      WHEN 'langue' THEN v_langue IS NULL OR v_langue = ANY (v_langues)
    END;
    IF NOT coalesce(v_ok, false) THEN
      v_rang := v_rang + (2 ^ (v_n - i))::integer;
    END IF;
  END LOOP;
  RETURN v_rang::smallint;
END;
$function$;

-- LE choix, pour l'absence ouverte [p_absence_id]. L'appelant tient le verrou
-- de la seance (SELECT ... FOR UPDATE). Rend le remplacant retenu, ou NULL
-- tant que la fenetre court.
CREATE FUNCTION private.remplacement_choisir(p_absence_id uuid)
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_absence public.remplacements_seance%ROWTYPE;
  v_dernier uuid;
  v_meilleur private.remplacements_acceptations%ROWTYPE;
  v_ouverture timestamptz;
BEGIN
  SELECT * INTO v_absence FROM public.remplacements_seance WHERE id = p_absence_id;
  IF NOT FOUND OR v_absence.evenement <> 'absence_declaree' THEN
    RETURN NULL;
  END IF;
  -- L'absence doit etre le dernier evenement de la seance : sinon, deja prise.
  SELECT r.id INTO v_dernier FROM public.remplacements_seance r
   WHERE r.session_id = v_absence.session_id ORDER BY r.cree_le DESC, r.id DESC LIMIT 1;
  IF v_dernier IS DISTINCT FROM p_absence_id THEN
    RETURN NULL;
  END IF;
  SELECT * INTO v_meilleur FROM private.remplacements_acceptations a
   WHERE a.absence_id = p_absence_id
   ORDER BY a.rang, a.recu_le, a.enseignant_id LIMIT 1;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT min(a.recu_le) INTO v_ouverture FROM private.remplacements_acceptations a
   WHERE a.absence_id = p_absence_id;
  IF v_meilleur.rang > 1 AND pg_catalog.clock_timestamp() < v_ouverture + private.remplacement_fenetre() THEN
    RETURN NULL;
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES (v_absence.session_id, 'remplacement_pris', v_absence.enseignant_titulaire_id,
          v_meilleur.enseignant_id, v_meilleur.enseignant_id, v_meilleur.cle_idempotence);
  PERFORM public.log_sensitive_access('replacement_claimed', 'remplacements_seance',
    v_absence.session_id::text,
    pg_catalog.jsonb_build_object('session_id', v_absence.session_id, 'rang', v_meilleur.rang));
  RETURN v_meilleur.enseignant_id;
END;
$function$;

-- Le filet : chaque absence encore ouverte (son evenement est le dernier de
-- la seance) dont la fenetre est finie est tranchee. Chaque absence est
-- isolee : une erreur sur l'une laisse un WARNING (seance, SQLSTATE ; jamais
-- le message d'erreur) et n'empeche pas les autres.
CREATE FUNCTION private.remplacement_fenetres_passer()
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_a record;
  v_n integer := 0;
  v_fenetre interval := private.remplacement_fenetre();
BEGIN
  FOR v_a IN
    SELECT a.absence_id, a.session_id
      FROM private.remplacements_acceptations a
     WHERE a.absence_id = (
             SELECT r.id FROM public.remplacements_seance r
              WHERE r.session_id = a.session_id
              ORDER BY r.cree_le DESC, r.id DESC LIMIT 1)
     GROUP BY a.absence_id, a.session_id
    HAVING min(a.recu_le) + v_fenetre <= pg_catalog.clock_timestamp()
       AND min(a.recu_le) > pg_catalog.clock_timestamp() - interval '1 day'
  LOOP
    BEGIN
      PERFORM 1 FROM public.sessions s WHERE s.id = v_a.session_id FOR UPDATE;
      IF private.remplacement_choisir(v_a.absence_id) IS NOT NULL THEN
        v_n := v_n + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'REMPLACEMENT-TEMPS-REEL : filet, seance % non tranchee (SQLSTATE %)',
        v_a.session_id, SQLSTATE;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. prendre_remplacement : l'acceptation, puis le choix unique
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prendre_remplacement(p_session_id uuid, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_existing public.remplacements_seance%ROWTYPE;
  v_moi uuid := auth.uid();
  v_rang smallint;
  v_tete uuid;
  v_ouverture timestamptz;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = v_moi AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'remplacement_pris' THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  -- A3 (31/10/2026) : une absence reste a prendre jusqu'a la fin prevue de
  -- la seance, seance prevue, en preparation ou deja ouverte.
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL
     OR v_session.status NOT IN ('planned', 'preflight', 'in_progress')
     OR v_session.ended_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  -- REMPLACEMENT-TEMPS-REEL : toute l'equipe peut accepter ; le genre et la
  -- langue ne font que le rang.
  IF NOT private.remplacant_eligible_sans_genre(p_session_id, v_moi) THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  -- Le titulaire ne prend jamais sa propre absence ; un enseignant n'est
  -- jamais pris pendant son propre cours (R12, memes refus que la direction).
  IF v_session.teacher_id = v_moi THEN
    RAISE EXCEPTION 'RemplacantIncompatible' USING ERRCODE = '22023';
  END IF;
  IF NOT private.remplacant_libre_a_l_heure(p_session_id, v_moi) THEN
    RAISE EXCEPTION 'RemplacantOccupe' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF NOT FOUND OR v_existing.evenement <> 'absence_declaree' THEN
    IF FOUND AND v_existing.enseignant_remplacant_id = v_moi
       AND v_existing.evenement = 'remplacement_pris' THEN
      RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
    END IF;
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  -- REMPLACEMENT-TEMPS-REEL (07/11/2026) : l'acceptation, avec son rang ; un
  -- second appel (fin du compte a rebours) n'ecrit rien de plus.
  v_rang := private.remplacement_rang(p_session_id, v_moi);
  INSERT INTO private.remplacements_acceptations
    (absence_id, session_id, enseignant_id, rang, cle_idempotence)
  VALUES (v_existing.id, p_session_id, v_moi, v_rang, p_cle_idempotence)
  ON CONFLICT (absence_id, enseignant_id) DO NOTHING;
  IF private.remplacement_choisir(v_existing.id) IS NOT NULL THEN
    SELECT * INTO v_existing FROM public.remplacements_seance
     WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
    IF v_existing.enseignant_remplacant_id = v_moi THEN
      RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
    END IF;
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  SELECT min(a.recu_le) INTO v_ouverture
    FROM private.remplacements_acceptations a WHERE a.absence_id = v_existing.id;
  -- En tete : celui que le choix retiendrait maintenant, dans le meme ordre
  -- que remplacement_choisir (rang, puis premier arrive). A rang egal, celui
  -- qui arrive apres n'est pas en tete.
  SELECT a.enseignant_id INTO v_tete FROM private.remplacements_acceptations a
   WHERE a.absence_id = v_existing.id
   ORDER BY a.rang, a.recu_le, a.enseignant_id LIMIT 1;
  RETURN jsonb_build_object('etat', 'enAttente', 'sessionId', p_session_id,
    'finFenetre', v_ouverture + private.remplacement_fenetre(),
    'enTete', v_tete = v_moi);
END;
$function$;

-- L'empreinte F86 du commentaire de prendre_remplacement suit sa definition.
DO $empreinte_prendre$
DECLARE
  f CONSTANT regprocedure := 'public.prendre_remplacement(uuid,uuid)'::regprocedure;
  v_com text := pg_catalog.obj_description(f, 'pg_proc');
BEGIN
  IF v_com LIKE '%md5_functiondef=%' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
      pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))));
  END IF;
END
$empreinte_prendre$;

-- ---------------------------------------------------------------------------
-- 6. Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v text;
  r text;
BEGIN
  FOREACH v IN ARRAY ARRAY[
    'private.remplacement_fenetre()', 'private.remplacement_preferences()',
    'private.remplacement_rang(uuid,uuid)', 'private.remplacement_choisir(uuid)',
    'private.remplacement_fenetres_passer()'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v);
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v, r);
      END IF;
    END LOOP;
  END LOOP;
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON private.remplacements_acceptations FROM %I', r);
    END IF;
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 7. Le filet planifie
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $c$SELECT cron.schedule('remplacement_fenetres', '* * * * *',
      'SELECT private.remplacement_fenetres_passer()')$c$;
  ELSE
    RAISE NOTICE 'REMPLACEMENT-TEMPS-REEL : pg_cron absente, rien n''est planifie';
  END IF;
END
$planification$;

-- ---------------------------------------------------------------------------
-- 8. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.remplacements_seance_notifier_enseignants()'::regprocedure,
                              'public.offres_remplacement()'::regprocedure,
                              'private.remplacement_candidat(uuid,uuid)'::regprocedure,
                              'public.prendre_remplacement(uuid,uuid)'::regprocedure)
                AND p.prosrc LIKE '%remplacement_enseignant_compatible(%') THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : le genre filtre encore l''alerte ou la prise';
  END IF;
  IF private.remplacement_preferences() <> ARRAY['genre', 'langue']
     OR private.remplacement_fenetre() <> interval '8 seconds' THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : reglages inattendus';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'authenticated')
     AND (pg_catalog.has_function_privilege('authenticated', 'private.remplacement_choisir(uuid)', 'EXECUTE')
          OR NOT pg_catalog.has_function_privilege('authenticated', 'public.prendre_remplacement(uuid,uuid)', 'EXECUTE')) THEN
    RAISE EXCEPTION 'REMPLACEMENT-TEMPS-REEL : droits inattendus';
  END IF;
END
$postflight$;
