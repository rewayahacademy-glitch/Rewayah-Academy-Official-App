-- HARMONISATION-A, dette 2 (08/11/2026, plan valide par le garde-cap) : la
-- pre-alerte « Je suis pret » passe par le rang et la fenetre, comme
-- l'absence (DECISION-REMPLACEMENT-2026-11-07 : il n'y a plus de second
-- circuit). Aucun mot d'effacement.
--
-- !! A INSTALLER APRES LE DEPLOIEMENT VERCEL DU TRAIN QUI LA PORTE, JAMAIS
-- !! AVANT : se_declarer_pret_remplacement peut desormais repondre
-- !! « enAttente », que seul le client de ce meme lot sait attendre. Un client
-- !! ancien ne doit jamais la recevoir (consigne du garde-cap, 08/11/2026).
--
-- 1. private.remplacements_prets_candidats : chaque « Je suis pret », avec son
--    rang (journal append-only, aucun acces client). L'index unique de
--    remplacements_preparation (une seule ligne « pret ») ne change pas.
-- 2. private.remplacement_ordre : LA fonction d'ordre et de fenetre, partagee
--    par l'absence et la pre-alerte. Meilleur rang, puis premier arrive, puis
--    identifiant ; on tranche aussitot pour un rang 1, sinon a la fin de la
--    fenetre ouverte par le premier arrive.
-- 3. private.remplacement_choisir (absence) et le « en tete » de
--    public.prendre_remplacement passent par elle ; comportement identique.
-- 4. private.remplacement_choisir_pret : le choix de la pre-alerte ; il ecrit
--    la ligne unique « pret » existante, que remplacement_auto_passer et
--    offres_remplacement lisent comme avant.
-- 5. public.se_declarer_pret_remplacement (meme signature, memes droits) :
--    inscrit le candidat avec son rang, puis tranche ; rend « retenu »,
--    « dejaRetenu », « fermee », ou « enAttente » (finFenetre, enTete).
-- 6. private.remplacement_fenetres_passer, le filet de chaque minute, tranche
--    aussi les pre-alertes dont la fenetre est finie (chaque seance isolee).
--
-- Preflight md5 du corps de production de chaque fonction remplacee.
-- Rejeu : stub_auth, toutes les migrations, puis
-- supabase/tests/scenarios_harmonisation_a_pret_par_rang.sql.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regclass('private.remplacements_prets_candidats') IS NOT NULL THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : deja installee';
  END IF;
  FOR v IN
    SELECT * FROM (VALUES
      ('public.se_declarer_pret_remplacement(uuid)', '49ef757b9a2ee45b84554acacef172dc'),
      ('private.remplacement_choisir(uuid)', '3cd109d1990b7c0b7c9ec0a104470e2d'),
      ('public.prendre_remplacement(uuid,uuid)', 'f5f7aeb962959def168f4fa11d57c9ac'),
      ('private.remplacement_fenetres_passer()', '1bacff1c90feb0915e639229f6ffa41b')
    ) AS t(f, md5_prod)
  LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL
       OR (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
            WHERE p.oid = pg_catalog.to_regprocedure(v.f)) <> v.md5_prod THEN
      RAISE EXCEPTION 'HARMONISATION-A (pret) : % absente ou changee depuis le depot', v.f;
    END IF;
  END LOOP;
  IF pg_catalog.to_regprocedure('private.remplacement_rang(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.remplacement_fenetre()') IS NULL
     OR pg_catalog.to_regprocedure('private.remplacement_candidat(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : une dependance manque';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le journal des « Je suis pret »
-- ---------------------------------------------------------------------------
CREATE TABLE private.remplacements_prets_candidats (
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  enseignant_id uuid NOT NULL REFERENCES public.profiles(id),
  rang smallint NOT NULL CHECK (rang >= 1),
  recu_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (session_id, enseignant_id)
);
CREATE INDEX remplacements_prets_candidats_session_idx
  ON private.remplacements_prets_candidats (session_id, recu_le);
REVOKE ALL ON private.remplacements_prets_candidats FROM PUBLIC;
CREATE TRIGGER remplacements_prets_candidats_immuable
  BEFORE UPDATE ON private.remplacements_prets_candidats
  FOR EACH ROW EXECUTE FUNCTION public.remplacements_seance_immutable();
COMMENT ON TABLE private.remplacements_prets_candidats IS
  'HARMONISATION-A (08/11/2026) : chaque « Je suis pret » d''une pre-alerte, avec son rang ; '
  'lu par private.remplacement_choisir_pret. Append-only, aucun acces client.';

-- ---------------------------------------------------------------------------
-- 2. LA fonction d'ordre et de fenetre
-- ---------------------------------------------------------------------------
-- Pour des candidats (enseignant, rang, arrivee) : le meilleur (rang, puis
-- premier arrive, puis identifiant), son rang, la fin de la fenetre ouverte
-- par le premier arrive, et si l'on peut trancher maintenant (rang 1, ou
-- fenetre finie). Aucun candidat : meilleur nul, tranche faux.
CREATE FUNCTION private.remplacement_ordre(
  p_enseignants uuid[], p_rangs smallint[], p_recus timestamptz[],
  OUT meilleur uuid, OUT meilleur_rang smallint, OUT fin_fenetre timestamptz, OUT tranche boolean
)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  SELECT u.e, u.r INTO meilleur, meilleur_rang
    FROM ROWS FROM (pg_catalog.unnest(p_enseignants), pg_catalog.unnest(p_rangs),
                    pg_catalog.unnest(p_recus)) AS u(e, r, t)
   ORDER BY u.r, u.t, u.e LIMIT 1;
  fin_fenetre := (SELECT pg_catalog.min(x) FROM pg_catalog.unnest(p_recus) AS x)
                 + private.remplacement_fenetre();
  tranche := meilleur IS NOT NULL
             AND (meilleur_rang = 1 OR pg_catalog.clock_timestamp() >= fin_fenetre);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. L'absence : le choix et le « en tete » passent par l'ordre commun
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.remplacement_choisir(p_absence_id uuid)
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_absence public.remplacements_seance%ROWTYPE;
  v_dernier uuid;
  v_o record;
  v_cle uuid;
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
  -- HARMONISATION-A : l'ordre et la fenetre communs (absence et pre-alerte).
  SELECT o.* INTO v_o
    FROM (SELECT pg_catalog.array_agg(a.enseignant_id) AS e, pg_catalog.array_agg(a.rang) AS r,
                 pg_catalog.array_agg(a.recu_le) AS t
            FROM private.remplacements_acceptations a WHERE a.absence_id = p_absence_id) c
    CROSS JOIN LATERAL private.remplacement_ordre(c.e, c.r, c.t) o;
  IF NOT coalesce(v_o.tranche, false) THEN
    RETURN NULL;
  END IF;
  SELECT a.cle_idempotence INTO v_cle FROM private.remplacements_acceptations a
   WHERE a.absence_id = p_absence_id AND a.enseignant_id = v_o.meilleur;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES (v_absence.session_id, 'remplacement_pris', v_absence.enseignant_titulaire_id,
          v_o.meilleur, v_o.meilleur, v_cle);
  PERFORM public.log_sensitive_access('replacement_claimed', 'remplacements_seance',
    v_absence.session_id::text,
    pg_catalog.jsonb_build_object('session_id', v_absence.session_id, 'rang', v_o.meilleur_rang));
  RETURN v_o.meilleur;
END;
$function$;

-- prendre_remplacement : seul le « en tete » de l'attente change, par ancre.
DO $ancre_prendre$
DECLARE
  c_f CONSTANT regprocedure := 'public.prendre_remplacement(uuid,uuid)'::regprocedure;
  c_ancre CONSTANT text :=
       E'  SELECT min(a.recu_le) INTO v_ouverture\n'
    || E'    FROM private.remplacements_acceptations a WHERE a.absence_id = v_existing.id;\n'
    || E'  -- En tete : celui que le choix retiendrait maintenant, dans le meme ordre\n'
    || E'  -- que remplacement_choisir (rang, puis premier arrive). A rang egal, celui\n'
    || E'  -- qui arrive apres n''est pas en tete.\n'
    || E'  SELECT a.enseignant_id INTO v_tete FROM private.remplacements_acceptations a\n'
    || E'   WHERE a.absence_id = v_existing.id\n'
    || E'   ORDER BY a.rang, a.recu_le, a.enseignant_id LIMIT 1;\n'
    || E'  RETURN jsonb_build_object(''etat'', ''enAttente'', ''sessionId'', p_session_id,\n'
    || E'    ''finFenetre'', v_ouverture + private.remplacement_fenetre(),\n'
    || E'    ''enTete'', v_tete = v_moi);\n';
  c_neuf CONSTANT text :=
       E'  -- En tete : celui que le choix retiendrait maintenant (HARMONISATION-A :\n'
    || E'  -- l''ordre et la fenetre communs, private.remplacement_ordre).\n'
    || E'  SELECT o.meilleur, o.fin_fenetre INTO v_tete, v_ouverture\n'
    || E'    FROM (SELECT pg_catalog.array_agg(a.enseignant_id) AS e, pg_catalog.array_agg(a.rang) AS r,\n'
    || E'                 pg_catalog.array_agg(a.recu_le) AS t\n'
    || E'            FROM private.remplacements_acceptations a WHERE a.absence_id = v_existing.id) c\n'
    || E'    CROSS JOIN LATERAL private.remplacement_ordre(c.e, c.r, c.t) o;\n'
    || E'  RETURN jsonb_build_object(''etat'', ''enAttente'', ''sessionId'', p_session_id,\n'
    || E'    ''finFenetre'', v_ouverture,\n'
    || E'    ''enTete'', v_tete = v_moi);\n';
  v_avant record;
  v_def text;
  v_apres text;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = c_f;
  v_def := pg_catalog.pg_get_functiondef(c_f);
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
     / pg_catalog.length(c_ancre) <> 1 THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : ancre introuvable ou multiple dans prendre_remplacement';
  END IF;
  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);
  v_apres := pg_catalog.pg_get_functiondef(c_f);
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : prendre_remplacement differe ailleurs que par le « en tete »';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = c_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : prendre_remplacement : droits ou reglages modifies';
  END IF;
END
$ancre_prendre$;

-- ---------------------------------------------------------------------------
-- 4. La pre-alerte : le choix
-- ---------------------------------------------------------------------------
-- Pour la seance [p_session_id] dont l'appelant tient le verrou : rend le
-- « pret » retenu (deja retenu, ou retenu maintenant), ou NULL tant que la
-- fenetre court ou que la pre-alerte est close.
CREATE FUNCTION private.remplacement_choisir_pret(p_session_id uuid)
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_deja uuid;
  v_o record;
BEGIN
  SELECT p.enseignant_id INTO v_deja FROM public.remplacements_preparation p
   WHERE p.session_id = p_session_id AND p.evenement = 'pret';
  IF v_deja IS NOT NULL THEN
    RETURN v_deja;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p
                  WHERE p.session_id = p_session_id AND p.evenement = 'pre_alerte')
     OR EXISTS (SELECT 1 FROM public.remplacements_preparation p
                 WHERE p.session_id = p_session_id AND p.evenement = 'remplacement_inutile')
     OR EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = p_session_id) THEN
    RETURN NULL;
  END IF;
  SELECT o.* INTO v_o
    FROM (SELECT pg_catalog.array_agg(c.enseignant_id) AS e, pg_catalog.array_agg(c.rang) AS r,
                 pg_catalog.array_agg(c.recu_le) AS t
            FROM private.remplacements_prets_candidats c WHERE c.session_id = p_session_id) c
    CROSS JOIN LATERAL private.remplacement_ordre(c.e, c.r, c.t) o;
  IF NOT coalesce(v_o.tranche, false) THEN
    RETURN NULL;
  END IF;
  INSERT INTO public.remplacements_preparation (session_id, evenement, enseignant_id)
  VALUES (p_session_id, 'pret', v_o.meilleur);
  PERFORM public.log_sensitive_access('replacement_ready', 'remplacements_preparation',
    p_session_id::text,
    pg_catalog.jsonb_build_object('session_id', p_session_id, 'rang', v_o.meilleur_rang));
  RETURN v_o.meilleur;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. « Je suis pret »
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.se_declarer_pret_remplacement(p_session_id uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_moi uuid := auth.uid();
  v_retenu uuid;
  v_o record;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  -- Verrou par seance : deux « pret » simultanes se suivent ici.
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  -- Deja tranche : retenu ou deja retenu, comme avant.
  SELECT p.enseignant_id INTO v_retenu FROM public.remplacements_preparation p
   WHERE p.session_id = p_session_id AND p.evenement = 'pret';
  IF v_retenu IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('etat',
      CASE WHEN v_retenu = v_moi THEN 'retenu' ELSE 'dejaRetenu' END);
  END IF;
  IF v_session.id IS NULL
     OR v_session.deleted_at IS NOT NULL
     OR v_session.status NOT IN ('planned', 'preflight', 'in_progress')
     OR v_session.ended_at <= pg_catalog.now()
     OR NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p
                     WHERE p.session_id = p_session_id AND p.evenement = 'pre_alerte')
     OR EXISTS (SELECT 1 FROM public.remplacements_preparation p
                 WHERE p.session_id = p_session_id AND p.evenement = 'remplacement_inutile')
     OR EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = p_session_id)
     OR NOT private.remplacement_candidat(p_session_id, v_moi) THEN
    RETURN pg_catalog.jsonb_build_object('etat', 'fermee');
  END IF;
  -- HARMONISATION-A : le candidat est inscrit avec son rang (un second appel,
  -- a la fin du compte a rebours, n'ecrit rien de plus), puis on tranche.
  INSERT INTO private.remplacements_prets_candidats (session_id, enseignant_id, rang)
  VALUES (p_session_id, v_moi, private.remplacement_rang(p_session_id, v_moi))
  ON CONFLICT (session_id, enseignant_id) DO NOTHING;
  v_retenu := private.remplacement_choisir_pret(p_session_id);
  IF v_retenu IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('etat',
      CASE WHEN v_retenu = v_moi THEN 'retenu' ELSE 'dejaRetenu' END);
  END IF;
  SELECT o.* INTO v_o
    FROM (SELECT pg_catalog.array_agg(c.enseignant_id) AS e, pg_catalog.array_agg(c.rang) AS r,
                 pg_catalog.array_agg(c.recu_le) AS t
            FROM private.remplacements_prets_candidats c WHERE c.session_id = p_session_id) c
    CROSS JOIN LATERAL private.remplacement_ordre(c.e, c.r, c.t) o;
  RETURN pg_catalog.jsonb_build_object('etat', 'enAttente', 'sessionId', p_session_id,
    'finFenetre', v_o.fin_fenetre, 'enTete', v_o.meilleur = v_moi);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Le filet : il tranche aussi les pre-alertes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.remplacement_fenetres_passer()
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
  -- HARMONISATION-A : les pre-alertes encore ouvertes, sans « pret » retenu,
  -- dont la fenetre est finie. Chaque seance est isolee.
  FOR v_a IN
    SELECT c.session_id
      FROM private.remplacements_prets_candidats c
     WHERE NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p
                        WHERE p.session_id = c.session_id
                          AND p.evenement IN ('pret', 'remplacement_inutile'))
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = c.session_id)
     GROUP BY c.session_id
    HAVING min(c.recu_le) + v_fenetre <= pg_catalog.clock_timestamp()
       AND min(c.recu_le) > pg_catalog.clock_timestamp() - interval '1 day'
  LOOP
    BEGIN
      PERFORM 1 FROM public.sessions s WHERE s.id = v_a.session_id FOR UPDATE;
      IF private.remplacement_choisir_pret(v_a.session_id) IS NOT NULL THEN
        v_n := v_n + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'HARMONISATION-A : filet, pre-alerte % non tranchee (SQLSTATE %)',
        v_a.session_id, SQLSTATE;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Droits : rien de neuf n'est ouvert au client
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v text;
  r text;
BEGIN
  FOREACH v IN ARRAY ARRAY[
    'private.remplacement_ordre(uuid[],smallint[],timestamp with time zone[])',
    'private.remplacement_choisir_pret(uuid)'] LOOP
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
      EXECUTE pg_catalog.format('REVOKE ALL ON private.remplacements_prets_candidats FROM %I', r);
    END IF;
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 8. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated',
          'public.se_declarer_pret_remplacement(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.remplacement_choisir_pret(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.remplacement_ordre(uuid[],smallint[],timestamp with time zone[])', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated',
          'private.remplacements_prets_candidats', 'SELECT') THEN
    RAISE EXCEPTION 'HARMONISATION-A (pret) : droits inattendus';
  END IF;
END
$postflight$;
