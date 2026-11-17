-- PX-BD-0 (pilote, 17/11/2026, plan docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-BRAS-DROIT.md, decisions DB1 a DB9) : le SOCLE des actes de
-- Praxis en mode CHAT. Ce fichier ne donne a Praxis AUCUN acte : le catalogue est VIDE. Chaque lot qui suit ajoute des actes par une migration
-- (une ligne de private.praxis_actes, un adaptateur private.praxis_acte_<nom>, une branche du pont), relue par le pilote contre
-- SECURITE-PRAXIS.md (R15).
--
-- Ce que le socle pose :
--   1. private.praxis_actes : le catalogue ferme des actes (nom, niveau A ou S, description, taille de lot) ;
--   2. private.praxis_confirmations : un LOT prepare, son resume, son code a six chiffres, ses essais, son resultat ;
--   3. private.praxis_executions : un acte execute (plafonds par heure, idempotence, trace) ;
--   4. private.praxis_identite(emetteur, aal) : les revendications de la direction qui a emis la cle ;
--   5. private.praxis_executer_acte(...) : LE PONT BORNE (DB1). Il fixe, pour la duree d'UN appel, l'identite de la direction qui a emis la cle,
--      appelle l'adaptateur de l'acte par un branchement STATIQUE (R1 : aucun SQL dynamique), puis RESTAURE l'identite d'origine, y compris sur
--      erreur. Il n'est appelable par aucun role client ; seules les portes praxis_* l'appellent ;
--   6. les quatre outils de Praxis (service_role seul, CLE DE CHAT SEULEMENT) : praxis_actes (lister), praxis_agir (acte A, immediat),
--      praxis_acte_preparer (acte S : valide, resume, genere le code, n'EXECUTE RIEN), praxis_acte_confirmer (acte S : le code, puis les actes) ;
--   7. les deux portes de la direction (administrateur valide, aal2) : voir les codes en attente (le code n'est visible QUE la), annuler.
--
-- Garanties (chacune a son scenario, scenarios_praxis_actes_socle.sql) :
--   * une cle de ROUTINE est refusee par chaque outil, avant tout (chat_seulement) ;
--   * Praxis n'obtient jamais de jeton : le pont emprunte l'identite de la personne qui a emis la cle, ne la garde pas, et la trace dit
--     « via Praxis » ; un acte de S ne s'execute qu'avec le code lu par la direction en aal2 dans l'application (DB2) : le modele ne peut ni le
--     deviner ni le lire ; un code vaut pour UN lot entier (un seul code pour toutes les lignes du lot) ;
--   * plafonds : 10 actes S et 60 actes A par heure et par cle (DB9) ; un lot de S qui depasserait est refuse des la preparation ;
--   * trois mauvais codes verrouillent le lot ET la cle pour l'heure pour toute nouvelle preparation ;
--   * le jeton expire en cinq minutes, ne sert qu'une fois, et les parametres sont ceux de l'empreinte : rien ne peut etre change entre la
--     preparation et la confirmation ;
--   * rien n'est execute tant que « donnees reelles » est ferme ou que le mode essai est actif.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Sans BEGIN ni COMMIT de premier niveau. Rien n'est installe sans le feu vert du
-- pilote (R14, R15).

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.praxis_porte(text, boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_noter(uuid, uuid, text, text, uuid, uuid[], text, timestamptz)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_essai()') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_empreinte(text)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text, text, text, jsonb)') IS NULL
     OR pg_catalog.to_regclass('private.praxis_reglages') IS NULL THEN
    RAISE EXCEPTION 'PX-BD-0 : une dependance de Praxis est absente (porte, journal, essai, empreinte, reglages)';
  END IF;
  IF pg_catalog.to_regclass('private.praxis_actes') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-BD-0 : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les tables
-- ---------------------------------------------------------------------------
CREATE TABLE private.praxis_actes (
  acte text PRIMARY KEY CHECK (acte ~ '^[a-z][a-z0-9_]{2,59}$'),
  niveau text NOT NULL CHECK (niveau IN ('A', 'S')),
  -- La description est ce que le MODELE lit : elle dit les valeurs par defaut et ce qu'il doit demander (1200 signes au plus).
  description text NOT NULL CHECK (pg_catalog.length(description) BETWEEN 1 AND 1200),
  lot_max smallint NOT NULL DEFAULT 1 CHECK (lot_max BETWEEN 1 AND 50),
  CONSTRAINT praxis_actes_a_sans_lot CHECK (niveau = 'S' OR lot_max = 1)
);
COMMENT ON TABLE private.praxis_actes IS
  'PX-BD-0 : le catalogue FERME des actes que Praxis peut accomplir en mode chat. Ecrit par migration seulement. Vide a l installation du socle.';

CREATE TABLE private.praxis_confirmations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cle_id uuid NOT NULL,
  emetteur uuid NOT NULL,
  acte text NOT NULL REFERENCES private.praxis_actes (acte),
  lot jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(lot) = 'array' AND pg_catalog.jsonb_array_length(lot) BETWEEN 1 AND 50),
  empreinte text NOT NULL,
  resume jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resume) = 'array'),
  code text CHECK (code IS NULL OR code ~ '^[0-9]{6}$'),
  code_affiche_le timestamptz,
  essais smallint NOT NULL DEFAULT 0 CHECK (essais BETWEEN 0 AND 3),
  etat text NOT NULL DEFAULT 'en_attente' CHECK (etat IN ('en_attente', 'confirmee', 'annulee', 'verrouillee', 'expiree')),
  resultat jsonb,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp() + interval '5 minutes',
  confirmee_le timestamptz,
  -- Un code vit tant que le lot attend ; il est vide des que le lot n'attend plus.
  CONSTRAINT praxis_confirmations_code_vivant CHECK ((etat = 'en_attente') = (code IS NOT NULL))
);
CREATE INDEX praxis_confirmations_cle_idx ON private.praxis_confirmations (cle_id, cree_le DESC);
COMMENT ON TABLE private.praxis_confirmations IS
  'PX-BD-0 : un lot d actes S prepare par Praxis, avec son code a six chiffres (visible de la seule direction en aal2). Aucun droit pour aucun role client.';

CREATE TABLE private.praxis_executions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cle_id uuid NOT NULL,
  emetteur uuid NOT NULL,
  acte text NOT NULL,
  niveau text NOT NULL CHECK (niveau IN ('A', 'S')),
  confirmation uuid,
  cle_idempotence uuid,
  ok boolean,
  cause text,
  resultat jsonb,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE UNIQUE INDEX praxis_executions_idem_idx ON private.praxis_executions (cle_id, cle_idempotence) WHERE cle_idempotence IS NOT NULL;
CREATE INDEX praxis_executions_plafond_idx ON private.praxis_executions (cle_id, niveau, cree_le DESC);
COMMENT ON TABLE private.praxis_executions IS
  'PX-BD-0 : un acte accompli par Praxis (plafonds par heure, idempotence, trace). Aucun droit pour aucun role client.';

ALTER TABLE private.praxis_actes ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.praxis_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.praxis_executions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_actes, private.praxis_confirmations, private.praxis_executions FROM PUBLIC;
DO $droits_tables$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON TABLE private.praxis_actes, private.praxis_confirmations, private.praxis_executions FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits_tables$;

-- ---------------------------------------------------------------------------
-- 2. L'identite de la direction qui a emis la cle, et le pont borne
-- ---------------------------------------------------------------------------
-- Les revendications d'une direction ACTIVE. Rend NULL pour tout autre compte : un pont ne prete jamais l'identite d'un enseignant, d'un tuteur
-- ni d'un compte suspendu. `aal` ne vaut `aal2` que pour un lot S dont le code a ete lu en aal2 dans l'application.
CREATE FUNCTION private.praxis_identite(p_emetteur uuid, p_aal text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
  SELECT pg_catalog.jsonb_build_object(
           'sub', p.id::text, 'role', 'authenticated', 'aal', p_aal,
           'app_metadata', pg_catalog.jsonb_build_object('role', p.role::text), 'via', 'praxis')
    FROM public.profiles p
   WHERE p.id = p_emetteur AND p_aal IN ('aal1', 'aal2')
     AND p.role = 'admin'::public.app_role AND p.deleted_at IS NULL
     AND p.account_status IN ('active'::public.account_status, 'provisional_active'::public.account_status)
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp());
$f$;

-- LE PONT. Un branchement STATIQUE : chaque acte a sa branche, ajoutee par migration (ancre ci-dessous). `p_a_sec` vrai : l'adaptateur
-- valide et rend le RESUME sans rien ecrire. L'identite d'origine est restauree sur toute issue.
CREATE FUNCTION private.praxis_executer_acte(p_cle uuid, p_emetteur uuid, p_acte text, p_params jsonb, p_aal text, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_revendications jsonb;
  v_anciennes text := coalesce(pg_catalog.current_setting('request.jwt.claims', true), '');
  v_ancien_sub text := coalesce(pg_catalog.current_setting('request.jwt.claim.sub', true), '');
  v_res jsonb;
BEGIN
  IF p_cle IS NULL OR p_emetteur IS NULL OR p_acte IS NULL OR p_params IS NULL
     OR pg_catalog.jsonb_typeof(p_params) IS DISTINCT FROM 'object' OR p_a_sec IS NULL THEN
    RAISE EXCEPTION 'acte invalide' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.praxis_actes a WHERE a.acte = p_acte) THEN
    RAISE EXCEPTION 'acte inconnu' USING ERRCODE = '22023';
  END IF;
  v_revendications := private.praxis_identite(p_emetteur, p_aal);
  IF v_revendications IS NULL THEN
    RAISE EXCEPTION 'emetteur sans identite de direction' USING ERRCODE = '42501';
  END IF;
  PERFORM pg_catalog.set_config('request.jwt.claims', v_revendications::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_emetteur::text, true);
  BEGIN
    -- La trace « via Praxis » : une ligne du journal d'audit AU NOM de la direction, avant l'acte.
    IF NOT p_a_sec THEN
      PERFORM public.log_sensitive_access('praxis_acte', 'praxis_actes', p_acte,
        pg_catalog.jsonb_build_object('via', 'praxis', 'cle', p_cle, 'niveau_aal', p_aal));
    END IF;
    IF FALSE THEN
      NULL;
    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l'acte
    ELSE
      RAISE EXCEPTION 'acte sans adaptateur' USING ERRCODE = '22023';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM pg_catalog.set_config('request.jwt.claims', v_anciennes, true);
    PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_ancien_sub, true);
    RAISE;
  END;
  PERFORM pg_catalog.set_config('request.jwt.claims', v_anciennes, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_ancien_sub, true);
  RETURN v_res;
END;
$f$;

-- ---------------------------------------------------------------------------
-- 3. Les outils de Praxis (service_role seul, cle de chat seulement)
-- ---------------------------------------------------------------------------

-- 3.1 Lister les actes que le catalogue ouvre.
CREATE FUNCTION public.praxis_actes(p_cle text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'actes', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF v_p.usage IS DISTINCT FROM 'chat' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'actes', 'chat_seulement', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'chat_seulement');
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'actes', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('actes', coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('acte', a.acte, 'niveau', a.niveau,
             'description', a.description, 'lotMax', a.lot_max) ORDER BY a.acte)
      FROM private.praxis_actes a), '[]'::jsonb));
END;
$f$;

-- 3.2 Un acte de niveau A : immediat, journalise, plafonne, idempotent.
CREATE FUNCTION public.praxis_agir(p_cle text, p_acte text, p_params jsonb, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_a private.praxis_actes;
  v_ex private.praxis_executions;
  v_id uuid;
  v_res jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle, true);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF v_p.usage IS DISTINCT FROM 'chat' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'chat_seulement', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'chat_seulement');
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_acte IS NULL OR p_cle_idempotence IS NULL OR p_params IS NULL
     OR pg_catalog.jsonb_typeof(p_params) IS DISTINCT FROM 'object' OR pg_catalog.length(p_params::text) > 4000 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT a.* INTO v_a FROM private.praxis_actes a WHERE a.acte = p_acte;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'acte_inconnu', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'acte_inconnu');
  END IF;
  IF v_a.niveau <> 'A' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'acte_sensible', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'acte_sensible');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-actes:' || v_p.cle_id::text, 0));
  -- Rejeu : la meme cle d'idempotence rend le resultat deja ecrit, sans rien refaire.
  SELECT x.* INTO v_ex FROM private.praxis_executions x WHERE x.cle_id = v_p.cle_id AND x.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'rejoue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', coalesce(v_ex.ok, false), 'rejoue', true, 'resultat', v_ex.resultat, 'cause', v_ex.cause);
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_executions x
       WHERE x.cle_id = v_p.cle_id AND x.niveau = 'A' AND x.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 60 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'plafond_actes', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_actes');
  END IF;
  INSERT INTO private.praxis_executions (cle_id, emetteur, acte, niveau, cle_idempotence)
  VALUES (v_p.cle_id, v_p.emise_par, p_acte, 'A', p_cle_idempotence) RETURNING id INTO v_id;
  BEGIN
    v_res := private.praxis_executer_acte(v_p.cle_id, v_p.emise_par, p_acte, p_params, 'aal1', false);
    UPDATE private.praxis_executions SET ok = true, resultat = v_res WHERE id = v_id;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'ok', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'resultat', v_res);
  EXCEPTION WHEN OTHERS THEN
    -- Une cause fermee : le code SQL, jamais le message de la base.
    UPDATE private.praxis_executions SET ok = false, cause = SQLSTATE WHERE id = v_id;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'agir', 'refuse', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'refuse', 'code', SQLSTATE);
  END;
END;
$f$;

-- 3.3 Preparer un LOT d'actes S : valide chaque ligne A SEC, rend le resume, genere le code. N'execute RIEN.
CREATE FUNCTION public.praxis_acte_preparer(p_cle text, p_acte text, p_lot jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_a private.praxis_actes;
  v_n integer;
  v_i integer;
  v_une jsonb;
  v_sec jsonb;
  v_resume jsonb := '[]'::jsonb;
  v_code text;
  v_oct bytea;
  v_id uuid;
  v_expire timestamptz;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle, true);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF v_p.usage IS DISTINCT FROM 'chat' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'chat_seulement', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'chat_seulement');
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_acte IS NULL OR p_lot IS NULL OR pg_catalog.jsonb_typeof(p_lot) IS DISTINCT FROM 'array'
     OR pg_catalog.length(p_lot::text) > 16000 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT a.* INTO v_a FROM private.praxis_actes a WHERE a.acte = p_acte;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'acte_inconnu', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'acte_inconnu');
  END IF;
  IF v_a.niveau <> 'S' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'acte_simple', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'acte_simple');
  END IF;
  v_n := pg_catalog.jsonb_array_length(p_lot);
  IF v_n < 1 OR v_n > v_a.lot_max THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'lot_taille', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'lot_taille', 'max', v_a.lot_max);
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-actes:' || v_p.cle_id::text, 0));
  -- Trois mauvais codes verrouillent la cle pour l'heure : plus aucune preparation.
  IF EXISTS (SELECT 1 FROM private.praxis_confirmations c
              WHERE c.cle_id = v_p.cle_id AND c.etat = 'verrouillee' AND c.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'cle_verrouillee', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'cle_verrouillee');
  END IF;
  -- Cinq lots en attente au plus : un lot de plus n'a de sens que si un code a ete donne ou si le delai est passe.
  UPDATE private.praxis_confirmations SET etat = 'expiree', code = NULL
   WHERE cle_id = v_p.cle_id AND etat = 'en_attente' AND expire_le <= pg_catalog.clock_timestamp();
  IF (SELECT pg_catalog.count(*) FROM private.praxis_confirmations c WHERE c.cle_id = v_p.cle_id AND c.etat = 'en_attente') >= 5 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'trop_en_attente', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'trop_en_attente');
  END IF;
  -- Le plafond d'actes S, DES la preparation : un code n'est jamais montre pour un lot qui ne pourrait pas partir.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_executions x
       WHERE x.cle_id = v_p.cle_id AND x.niveau = 'S' AND x.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') + v_n > 10 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'plafond_actes', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_actes');
  END IF;
  -- Chaque ligne est validee A SEC, sous l'identite de la direction, en aal1 : l'adaptateur ne ressort que son resume.
  FOR v_i IN 0 .. v_n - 1 LOOP
    v_une := p_lot -> v_i;
    IF pg_catalog.jsonb_typeof(v_une) IS DISTINCT FROM 'object' THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'parametre', NULL, NULL, NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre', 'indice', v_i);
    END IF;
    BEGIN
      v_sec := private.praxis_executer_acte(v_p.cle_id, v_p.emise_par, p_acte, v_une, 'aal1', true);
    EXCEPTION WHEN OTHERS THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'refuse', NULL, NULL, NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'refuse', 'code', SQLSTATE, 'indice', v_i);
    END;
    IF v_sec IS NULL OR pg_catalog.jsonb_typeof(v_sec -> 'resume') IS DISTINCT FROM 'string' THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'refuse', NULL, NULL, NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'refuse', 'indice', v_i, 'detail', coalesce(v_sec ->> 'erreur', 'sans_resume'));
    END IF;
    v_resume := v_resume || pg_catalog.jsonb_build_array(pg_catalog.left(v_sec ->> 'resume', 200));
  END LOOP;
  v_oct := extensions.gen_random_bytes(4);
  v_code := pg_catalog.lpad(((pg_catalog.get_byte(v_oct, 0)::bigint * 16777216 + pg_catalog.get_byte(v_oct, 1)::bigint * 65536
                + pg_catalog.get_byte(v_oct, 2)::bigint * 256 + pg_catalog.get_byte(v_oct, 3)::bigint) % 1000000)::text, 6, '0');
  INSERT INTO private.praxis_confirmations (cle_id, emetteur, acte, lot, empreinte, resume, code)
  VALUES (v_p.cle_id, v_p.emise_par, p_acte, p_lot, private.praxis_empreinte(p_acte || ':' || p_lot::text), v_resume, v_code)
  RETURNING id, expire_le INTO v_id, v_expire;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_preparer', 'ok', NULL, ARRAY[v_id], NULL, v_debut);
  -- Le code n'est JAMAIS rendu : seule la direction, connectee en aal2, le lit dans l'application.
  RETURN pg_catalog.jsonb_build_object('ok', true, 'jeton', v_id, 'nb', v_n, 'resume', v_resume, 'expireLe', v_expire,
    'etape_suivante', 'La direction lit le code dans l''application (section Praxis), puis te le dit : appelle alors confirmer avec le jeton et ce code.');
END;
$f$;

-- 3.4 Confirmer un lot : le jeton ET le code lu en aal2 dans l'application. Execute exactement le lot de l'empreinte.
CREATE FUNCTION public.praxis_acte_confirmer(p_cle text, p_jeton uuid, p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_c private.praxis_confirmations;
  v_n integer;
  v_i integer;
  v_res jsonb;
  v_resultats jsonb := '[]'::jsonb;
  v_valides integer := 0;
  v_exec uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle, true);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF v_p.usage IS DISTINCT FROM 'chat' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'chat_seulement', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'chat_seulement');
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_jeton IS NULL OR p_code IS NULL OR p_code !~ '^[0-9]{6}$' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-actes:' || v_p.cle_id::text, 0));
  SELECT c.* INTO v_c FROM private.praxis_confirmations c WHERE c.id = p_jeton AND c.cle_id = v_p.cle_id FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'jeton_inconnu', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'jeton_inconnu');
  END IF;
  -- Un lot deja confirme rend son resultat : jamais une seconde execution.
  IF v_c.etat = 'confirmee' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'rejoue', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true, 'resultats', v_c.resultat);
  END IF;
  IF v_c.etat <> 'en_attente' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', v_c.etat, NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_c.etat);
  END IF;
  IF v_c.expire_le <= pg_catalog.clock_timestamp() THEN
    UPDATE private.praxis_confirmations SET etat = 'expiree', code = NULL WHERE id = v_c.id;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'expiree', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'expiree');
  END IF;
  -- Le code n'a de sens que s'il a ete MONTRE a la direction, en aal2, dans l'application.
  IF v_c.code_affiche_le IS NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'code_non_affiche', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'code_non_affiche');
  END IF;
  IF v_c.code IS NULL OR p_code <> v_c.code THEN
    IF v_c.essais + 1 >= 3 THEN
      UPDATE private.praxis_confirmations SET essais = 3, etat = 'verrouillee', code = NULL WHERE id = v_c.id;
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'verrouillee', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'verrouillee');
    END IF;
    UPDATE private.praxis_confirmations SET essais = essais + 1 WHERE id = v_c.id;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'code_faux', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'code_faux', 'restants', 3 - (v_c.essais + 1));
  END IF;
  -- L'empreinte : le lot a executer est EXACTEMENT celui qui a ete prepare et montre.
  IF v_c.empreinte <> private.praxis_empreinte(v_c.acte || ':' || v_c.lot::text) THEN
    UPDATE private.praxis_confirmations SET etat = 'annulee', code = NULL WHERE id = v_c.id;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'empreinte', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'empreinte');
  END IF;
  v_n := pg_catalog.jsonb_array_length(v_c.lot);
  IF (SELECT pg_catalog.count(*) FROM private.praxis_executions x
       WHERE x.cle_id = v_p.cle_id AND x.niveau = 'S' AND x.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') + v_n > 10 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'plafond_actes', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_actes');
  END IF;
  -- Le code est bon : chaque ligne part sous l'identite de la direction EN AAL2 (le code a ete lu en aal2 dans l'application).
  FOR v_i IN 0 .. v_n - 1 LOOP
    INSERT INTO private.praxis_executions (cle_id, emetteur, acte, niveau, confirmation)
    VALUES (v_p.cle_id, v_p.emise_par, v_c.acte, 'S', v_c.id) RETURNING id INTO v_exec;
    BEGIN
      v_res := private.praxis_executer_acte(v_p.cle_id, v_p.emise_par, v_c.acte, v_c.lot -> v_i, 'aal2', false);
      UPDATE private.praxis_executions SET ok = true, resultat = v_res WHERE id = v_exec;
      v_valides := v_valides + 1;
      v_resultats := v_resultats || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('indice', v_i, 'ok', true, 'resultat', v_res));
    EXCEPTION WHEN OTHERS THEN
      UPDATE private.praxis_executions SET ok = false, cause = SQLSTATE WHERE id = v_exec;
      v_resultats := v_resultats || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object('indice', v_i, 'ok', false, 'code', SQLSTATE));
    END;
  END LOOP;
  UPDATE private.praxis_confirmations
     SET etat = 'confirmee', code = NULL, resultat = v_resultats, confirmee_le = pg_catalog.clock_timestamp()
   WHERE id = v_c.id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'acte_confirmer', 'ok', NULL, ARRAY[v_c.id], NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'nb', v_n, 'reussis', v_valides, 'resultats', v_resultats);
END;
$f$;

-- ---------------------------------------------------------------------------
-- 4. Les portes de la direction (administrateur valide, aal2) : le code ne se lit QUE la.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.direction_praxis_confirmations()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_c private.praxis_confirmations;
  v_liste jsonb := '[]'::jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  UPDATE private.praxis_confirmations SET etat = 'expiree', code = NULL
   WHERE emetteur = auth.uid() AND etat = 'en_attente' AND expire_le <= pg_catalog.clock_timestamp();
  FOR v_c IN SELECT c.* FROM private.praxis_confirmations c
              WHERE c.emetteur = auth.uid() AND c.etat = 'en_attente' ORDER BY c.cree_le, c.id LOOP
    IF v_c.code_affiche_le IS NULL THEN
      UPDATE private.praxis_confirmations SET code_affiche_le = pg_catalog.clock_timestamp() WHERE id = v_c.id;
      PERFORM public.log_sensitive_access('praxis_code_affiche', 'praxis_confirmations', v_c.id::text,
        pg_catalog.jsonb_build_object('acte', v_c.acte, 'nb', pg_catalog.jsonb_array_length(v_c.lot)));
    END IF;
    v_liste := v_liste || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'id', v_c.id, 'acte', v_c.acte, 'nb', pg_catalog.jsonb_array_length(v_c.lot), 'resume', v_c.resume,
      'code', v_c.code, 'expireLe', v_c.expire_le));
  END LOOP;
  RETURN v_liste;
END;
$f$;

CREATE FUNCTION public.direction_praxis_confirmation_annuler(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_n integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'lot invalide' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_confirmations SET etat = 'annulee', code = NULL
   WHERE id = p_id AND emetteur = auth.uid() AND etat = 'en_attente';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 1 THEN
    PERFORM public.log_sensitive_access('praxis_lot_annule', 'praxis_confirmations', p_id::text, '{}'::jsonb);
  END IF;
  RETURN pg_catalog.jsonb_build_object('annule', v_n = 1);
END;
$f$;

-- ---------------------------------------------------------------------------
-- 5. Proprietaire, droits, empreintes
-- ---------------------------------------------------------------------------
ALTER FUNCTION private.praxis_identite(uuid, text) OWNER TO postgres;
ALTER FUNCTION private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean) OWNER TO postgres;
ALTER FUNCTION public.praxis_actes(text) OWNER TO postgres;
ALTER FUNCTION public.praxis_agir(text, text, jsonb, uuid) OWNER TO postgres;
ALTER FUNCTION public.praxis_acte_preparer(text, text, jsonb) OWNER TO postgres;
ALTER FUNCTION public.praxis_acte_confirmer(text, uuid, text) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_confirmations() OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_confirmation_annuler(uuid) OWNER TO postgres;

DO $droits$
DECLARE
  v_prives text[] := ARRAY['private.praxis_identite(uuid, text)', 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'];
  v_outils text[] := ARRAY['public.praxis_actes(text)', 'public.praxis_agir(text, text, jsonb, uuid)',
                           'public.praxis_acte_preparer(text, text, jsonb)', 'public.praxis_acte_confirmer(text, uuid, text)'];
  v_portes text[] := ARRAY['public.direction_praxis_confirmations()', 'public.direction_praxis_confirmation_annuler(uuid)'];
  v_f text;
  v_role text;
BEGIN
  FOREACH v_f IN ARRAY v_prives || v_outils || v_portes LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_f);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_f, v_role);
      END IF;
    END LOOP;
  END LOOP;
  FOREACH v_f IN ARRAY v_outils LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_f);
  END LOOP;
  FOREACH v_f IN ARRAY v_portes LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_f);
  END LOOP;
END;
$droits$;

DO $empreintes$
DECLARE
  v_def text[][] := ARRAY[
    ARRAY['public.direction_praxis_confirmations()', 'ROLE_POSITIVE_ADMIN',
          'PX-BD-0 : les lots d actes en attente de la direction qui a emis la cle, avec leur code a six chiffres ; aal2 ; le code ne se lit que la.'],
    ARRAY['public.direction_praxis_confirmation_annuler(uuid)', 'ROLE_POSITIVE_ADMIN',
          'PX-BD-0 : annule un lot en attente de la direction qui a emis la cle ; aal2.']];
  i integer;
  f regprocedure;
BEGIN
  FOR i IN 1 .. pg_catalog.array_length(v_def, 1) LOOP
    f := v_def[i][1]::regprocedure;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
      'F86 candidate allowlist: signature=' || v_def[i][1] || '; md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
      || '; guard_type=' || v_def[i][2] || '; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-17. '
      || v_def[i][3] || ' Must-pass: supabase/tests/scenarios_praxis_actes_socle.sql.');
  END LOOP;
END;
$empreintes$;
COMMENT ON FUNCTION private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean) IS
  'PX-BD-0: guard_type=INTERNAL_PONT; LE PONT BORNE (DB1) : emprunte l identite de la direction emettrice pour UN acte du catalogue, branchement statique, restaure l identite sur toute issue ; aucun droit client. date=2026-11-17.';
COMMENT ON FUNCTION private.praxis_identite(uuid, text) IS
  'PX-BD-0: guard_type=INTERNAL_PURE; les revendications d une direction ACTIVE (NULL pour tout autre compte). date=2026-11-17.';

DO $postflight$
DECLARE
  v_f regprocedure;
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.praxis_actes) <> 0 THEN
    RAISE EXCEPTION 'PX-BD-0 : le catalogue des actes doit etre VIDE a l installation du socle';
  END IF;
  FOREACH v_f IN ARRAY ARRAY[
    'private.praxis_identite(uuid, text)'::regprocedure,
    'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure,
    'public.praxis_actes(text)'::regprocedure, 'public.praxis_agir(text, text, jsonb, uuid)'::regprocedure,
    'public.praxis_acte_preparer(text, text, jsonb)'::regprocedure, 'public.praxis_acte_confirmer(text, uuid, text)'::regprocedure,
    'public.direction_praxis_confirmations()'::regprocedure,
    'public.direction_praxis_confirmation_annuler(uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-BD-0 : DEFINER, proprietaire ou ACL invalide pour %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.praxis_identite(uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_identite(uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_agir(text, text, jsonb, uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_agir(text, text, jsonb, uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_confirmations()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_confirmations()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX-BD-0 : droits d execution inattendus';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.praxis_confirmations', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_confirmations', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_executions', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_actes', 'SELECT') THEN
    RAISE EXCEPTION 'PX-BD-0 : une table des actes est lisible par un role client';
  END IF;
END
$postflight$;
