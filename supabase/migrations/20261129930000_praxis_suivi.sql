-- PX-SUIVI : quand Praxis ne sait pas, il DEMANDE A L'EQUIPE, la direction repond dans l'application, et Praxis REVIENT vers la
-- personne (docs/current/BUREAU-EQUIPE/PRAXIS/STRATEGIE-MEMBRE.md §3 et §5, directeur 17/11/2026 : « c'est un membre, pas un chatbot »).
--
-- Additif, aucune fonction existante n'est remplacee :
--  * une table privee `private.praxis_questions` (RLS, aucun droit direct) : la question RESUMEE PAR PRAXIS (300 signes au plus,
--    jamais le texte de la personne), la reponse de la direction (1 500 au plus), qui a repondu et quand, et quand Praxis l'a utilisee ;
--  * trois outils (service_role seul) : `praxis_demander_equipe` (une question OUVERTE par conversation au plus, 20 questions par cle
--    et par heure, 100 ouvertes au plus, conversation ouverte a Praxis par la porte existante `praxis_fil_refus`),
--    `praxis_reponses_equipe` (les reponses non encore utilisees, des SEULES conversations encore ouvertes a Praxis) et
--    `praxis_question_traitee` (Praxis marque la question utilisee apres avoir ecrit) ;
--  * deux portes de la direction : `direction_praxis_questions` (lecture, ouvertes d'abord) et `direction_praxis_repondre`
--    (ecriture, direction active, MFA aal2 comme les autres gestes de Praxis, une seule reponse par question, journalisee).
-- Rien n'est allume par cette migration. Aucun mot d'effacement.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.praxis_journal') IS NULL OR pg_catalog.to_regclass('private.praxis_cles') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_porte(text,boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_fil_refus(uuid,public.gender[])') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_noter(uuid,uuid,text,text,uuid,uuid[],text,timestamptz)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'PX-SUIVI : le socle de Praxis est absent ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.praxis_questions') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.praxis_demander_equipe(text,uuid,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-SUIVI : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Les questions. Pas de cle etrangere vers com_fils (une conversation retiree ne doit jamais bloquer ni etre bloquee par une
-- question) ; la cle de Praxis et le profil qui repond sont des references, comme au journal.
CREATE TABLE private.praxis_questions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  fil_id uuid NOT NULL,
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  question text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(question)) BETWEEN 1 AND 300 AND pg_catalog.length(question) <= 300),
  posee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  reponse text CHECK (reponse IS NULL OR (pg_catalog.length(pg_catalog.btrim(reponse)) BETWEEN 1 AND 1500 AND pg_catalog.length(reponse) <= 1500)),
  repondue_le timestamptz,
  repondue_par uuid REFERENCES public.profiles (id),
  utilisee_le timestamptz,
  CONSTRAINT praxis_questions_reponse_coherente
    CHECK ((reponse IS NULL) = (repondue_le IS NULL) AND (reponse IS NULL) = (repondue_par IS NULL)),
  CONSTRAINT praxis_questions_utilisee_apres_reponse CHECK (utilisee_le IS NULL OR repondue_le IS NOT NULL)
);
ALTER TABLE private.praxis_questions ENABLE ROW LEVEL SECURITY;
-- Une seule question OUVERTE (sans reponse) par conversation.
CREATE UNIQUE INDEX praxis_questions_une_ouverte_par_fil ON private.praxis_questions (fil_id) WHERE repondue_le IS NULL;
CREATE INDEX praxis_questions_recentes_idx ON private.praxis_questions (posee_le DESC, id);
CREATE INDEX praxis_questions_a_utiliser_idx ON private.praxis_questions (repondue_le) WHERE repondue_le IS NOT NULL AND utilisee_le IS NULL;
REVOKE ALL ON TABLE private.praxis_questions FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Outil `demander_equipe`.
CREATE FUNCTION public.praxis_demander_equipe(p_cle text, p_fil uuid, p_question text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_refus text;
  v_id uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_question IS NULL OR pg_catalog.length(pg_catalog.btrim(p_question)) NOT BETWEEN 1 AND 300
     OR pg_catalog.length(p_question) > 300 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  -- La conversation doit etre ouverte a Praxis par la porte existante (inconnue, hors academie, type ferme, mineur, cote, essai...).
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  -- Plafonds : 20 questions par cle et par heure, 100 questions ouvertes au plus.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_questions q
       WHERE q.cle_id = v_p.cle_id AND q.posee_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 20 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'plafond', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond');
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_questions q WHERE q.repondue_le IS NULL) >= 100 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'trop_ouvertes', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'trop_ouvertes');
  END IF;
  BEGIN
    INSERT INTO private.praxis_questions (fil_id, cle_id, question)
    VALUES (p_fil, v_p.cle_id, pg_catalog.btrim(p_question))
    RETURNING id INTO v_id;
  EXCEPTION WHEN unique_violation THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'question_ouverte', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'question_ouverte');
  END;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'ok', p_fil, ARRAY[v_id], pg_catalog.btrim(p_question), v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_id);
END;
$f$;

-- 3. Outil `reponses_equipe` : les reponses de la direction que Praxis n'a pas encore utilisees, des conversations qui lui sont
-- encore ouvertes (les autres restent a l'equipe). La reponse est ECRITE PAR LA DIRECTION : c'est le fait a transmettre, pas
-- le texte d'un tiers ; la question est celle que Praxis a lui-meme ecrite.
CREATE FUNCTION public.praxis_reponses_equipe(p_cle text, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_liste jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.j ORDER BY x.le), '[]'::jsonb) INTO v_liste
    FROM (SELECT r.repondue_le AS le,
                 pg_catalog.jsonb_build_object('id', r.id, 'fil', r.fil_id, 'question', r.question,
                   'reponse_de_la_direction', r.reponse, 'repondue_le', r.repondue_le) AS j
            FROM (SELECT q.* FROM private.praxis_questions q
                   WHERE q.repondue_le IS NOT NULL AND q.utilisee_le IS NULL
                   ORDER BY q.repondue_le, q.id LIMIT 200) r
           WHERE private.praxis_fil_refus(r.fil_id, v_p.cotes) IS NULL
           ORDER BY r.repondue_le, r.id LIMIT p_limite) x;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('reponses', v_liste);
END;
$f$;

-- 4. Outil `question_traitee` : Praxis marque la question utilisee, une fois, apres avoir ecrit a la personne.
CREATE FUNCTION public.praxis_question_traitee(p_cle text, p_question uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_fil uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'question_traitee', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_question IS NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'question_traitee', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  UPDATE private.praxis_questions q SET utilisee_le = pg_catalog.clock_timestamp()
   WHERE q.id = p_question AND q.repondue_le IS NOT NULL AND q.utilisee_le IS NULL
   RETURNING q.fil_id INTO v_fil;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'question_traitee', 'inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'inconnue');
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'question_traitee', 'ok', v_fil, ARRAY[p_question], NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;

-- 5. Direction : la liste, ouvertes d'abord (les plus anciennes en tete), puis les repondues (les plus recentes en tete).
CREATE FUNCTION public.direction_praxis_questions(p_limite integer DEFAULT 100)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_liste jsonb;
  v_total integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'limite invalide' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_total FROM private.praxis_questions;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', x.id, 'filId', x.fil_id, 'question', x.question, 'poseeLe', x.posee_le,
           'reponse', x.reponse, 'repondueLe', x.repondue_le,
           'repondueParPrenom', (SELECT p.first_name FROM public.profiles p WHERE p.id = x.repondue_par),
           'utiliseeLe', x.utilisee_le)
         ORDER BY (x.repondue_le IS NOT NULL), CASE WHEN x.repondue_le IS NULL THEN x.posee_le END, x.repondue_le DESC, x.id), '[]'::jsonb)
    INTO v_liste
    FROM (SELECT * FROM private.praxis_questions q
           ORDER BY (q.repondue_le IS NOT NULL), CASE WHEN q.repondue_le IS NULL THEN q.posee_le END, q.repondue_le DESC, q.id
           LIMIT p_limite) x;
  RETURN pg_catalog.jsonb_build_object('questions', v_liste, 'total', v_total);
END;
$f$;

-- 6. Direction : repondre (une seule fois). MFA aal2 comme les autres gestes de Praxis. Le texte n'est pas journalise a l'audit.
CREATE FUNCTION public.direction_praxis_repondre(p_id uuid, p_texte text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_texte text;
  v_existe boolean;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_texte IS NULL THEN
    RAISE EXCEPTION 'reponse invalide' USING ERRCODE = '22023';
  END IF;
  v_texte := pg_catalog.btrim(p_texte);
  IF pg_catalog.length(v_texte) NOT BETWEEN 1 AND 1500 THEN
    RAISE EXCEPTION 'la reponse doit faire de 1 a 1500 signes' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_questions q
     SET reponse = v_texte, repondue_le = pg_catalog.clock_timestamp(), repondue_par = auth.uid()
   WHERE q.id = p_id AND q.repondue_le IS NULL;
  IF NOT FOUND THEN
    SELECT EXISTS (SELECT 1 FROM private.praxis_questions q WHERE q.id = p_id) INTO v_existe;
    RETURN pg_catalog.jsonb_build_object('erreur', CASE WHEN v_existe THEN 'deja_repondue' ELSE 'inconnue' END);
  END IF;
  PERFORM public.log_sensitive_access('praxis_repond_question', 'private.praxis_questions', 'praxis',
    pg_catalog.jsonb_build_object('id', p_id));
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;

-- 7. Droits : les trois outils au seul service_role, les deux portes aux seuls comptes connectes (la fonction verifie la direction).
ALTER FUNCTION public.praxis_demander_equipe(text, uuid, text) OWNER TO postgres;
ALTER FUNCTION public.praxis_reponses_equipe(text, integer) OWNER TO postgres;
ALTER FUNCTION public.praxis_question_traitee(text, uuid) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_questions(integer) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_repondre(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.praxis_demander_equipe(text, uuid, text), public.praxis_reponses_equipe(text, integer),
  public.praxis_question_traitee(text, uuid), public.direction_praxis_questions(integer), public.direction_praxis_repondre(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_demander_equipe(text, uuid, text), public.praxis_reponses_equipe(text, integer),
  public.praxis_question_traitee(text, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.direction_praxis_questions(integer), public.direction_praxis_repondre(uuid, text) TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_reponses_equipe(text,integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_question_traitee(text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_reponses_equipe(text,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_reponses_equipe(text,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_question_traitee(text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_question_traitee(text,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_questions(integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_questions(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_questions(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'private.praxis_questions', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_questions', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.praxis_questions', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.praxis_questions'::pg_catalog.regclass)
     OR (SELECT pg_catalog.count(*) FROM private.praxis_questions) <> 0
     OR (SELECT r.actif FROM private.praxis_reglages r) IS NOT FALSE
     OR (SELECT r.autonome FROM private.praxis_reglages r) IS NOT FALSE THEN
    RAISE EXCEPTION 'PX-SUIVI : droits ou etat inattendus apres installation';
  END IF;
END
$postflight$;
