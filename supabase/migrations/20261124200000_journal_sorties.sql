-- HORS-SALLE-2 (directeur, 12/11/2026 au soir) : le journal des sorties de
-- l'application d'un eleve pendant une seance, consigne au rapport (nombre,
-- frequence, de quand a quand), et le delai de sortie de la salle reglable par
-- la direction.
--
-- Le cadre (docs/current/salle/DROIT-RELEVE-QUALITE.md, par. 10 point 3) :
--   * eleve qui n'est pas « autonome », ou dont le type ne se lit pas : aucune
--     ligne sans un accord EN COURS d'un tuteur de SON foyer, pour CET enfant ;
--     l'enfant ne peut pas accepter pour lui-meme ;
--   * eleve adulte autonome : son propre accord (sans reponse de sa part, rien
--     n'est ecrit ; un retrait arrete l'ecriture) ;
--   * le journal est eteint par defaut (salle.sorties.journal_actif = faux) ;
--     les textes de l'accord sont des propositions a valider par le directeur
--     avant de l'allumer (docs/current/TEXTES-VALIDES/ACCORD-JOURNAL-SORTIES.md).
--
-- Ce qui est garde : la seance, l'eleve, l'heure de sortie, l'heure de retour
-- (posees par le serveur, jamais par le client), et si la sortie a mene a la
-- sortie de la salle. Aucun motif, aucune application, aucune donnee
-- d'appareil.
--
-- Additive, rejouable, dans une transaction. Aucun mot d'effacement : la
-- duree de conservation reste a decider par le directeur, et la fonction qui
-- l'appliquera viendra avec sa decision.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Les reglages de la direction
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('salle.sorties.journal_actif', 'false'::jsonb),
  ('salle.sorties.delai_secondes', '30'::jsonb),
  ('salle.sorties.accord_version', '"sorties-2026-11-v1"'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- La direction ecrit app_config directement (policies de 0001) : la forme de
-- ces trois valeurs est verifiee ici, a l'ecriture.
CREATE OR REPLACE FUNCTION private.sorties_config_valide()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.key = 'salle.sorties.journal_actif'
     AND pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'boolean' THEN
    RAISE EXCEPTION 'salle.sorties.journal_actif : vrai ou faux' USING ERRCODE = '22023';
  END IF;
  IF NEW.key = 'salle.sorties.delai_secondes'
     AND NOT coalesce(pg_catalog.jsonb_typeof(NEW.value) = 'number'
                      AND (NEW.value #>> '{}') ~ '^[0-9]+$'
                      AND (NEW.value #>> '{}')::integer BETWEEN 5 AND 600, false) THEN
    RAISE EXCEPTION 'salle.sorties.delai_secondes : un nombre entier de 5 a 600' USING ERRCODE = '22023';
  END IF;
  IF NEW.key = 'salle.sorties.accord_version'
     AND NOT coalesce(pg_catalog.jsonb_typeof(NEW.value) = 'string'
                      AND pg_catalog.length(NEW.value #>> '{}') BETWEEN 1 AND 80, false) THEN
    RAISE EXCEPTION 'salle.sorties.accord_version : une chaine de 1 a 80 caracteres' USING ERRCODE = '22023';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER app_config_sorties_valide
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW
  WHEN (NEW.key LIKE 'salle.sorties.%')
  EXECUTE FUNCTION private.sorties_config_valide();

-- ---------------------------------------------------------------------------
-- 2. L'accord, par eleve (modele : accords_publication, 20261110330000)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.accords_journal_sorties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- L'eleve concerne.
  eleve_id uuid NOT NULL REFERENCES public.profiles(id),
  -- Qui a accepte : un tuteur du foyer, ou l'eleve autonome pour lui-meme.
  accepte_par uuid NOT NULL REFERENCES public.profiles(id),
  version text NOT NULL CHECK (pg_catalog.length(version) BETWEEN 1 AND 80),
  accepte_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retire_le timestamptz NULL,
  retire_par uuid NULL REFERENCES public.profiles(id),
  CONSTRAINT accords_journal_sorties_retrait_apres
    CHECK (retire_le IS NULL OR retire_le >= accepte_le),
  CONSTRAINT accords_journal_sorties_retrait_signe
    CHECK ((retire_le IS NULL) = (retire_par IS NULL))
);
-- Un seul accord en cours par eleve.
CREATE UNIQUE INDEX IF NOT EXISTS accords_journal_sorties_en_cours_uidx
  ON public.accords_journal_sorties (eleve_id) WHERE retire_le IS NULL;

ALTER TABLE public.accords_journal_sorties ENABLE ROW LEVEL SECURITY;
-- Aucun droit direct : lecture et ecriture par les fonctions ci-dessous.
REVOKE ALL ON public.accords_journal_sorties FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.accords_journal_sorties IS
  'HORS-SALLE-2 (12/11/2026) : accord pour noter les sorties de l''application d''un eleve pendant '
  'une seance. Par eleve : un tuteur de son foyer (eleve non autonome) ou l''eleve autonome lui-meme. '
  'Version du texte, date ; retire par retire_le, jamais efface. Ecrit par accepter_accord_sorties '
  'et retirer_accord_sorties seulement ; aucun droit direct.';

-- ---------------------------------------------------------------------------
-- 3. Le journal
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_sorties_app (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  eleve_id uuid NOT NULL REFERENCES public.profiles(id),
  -- L'accord qui a permis la ligne.
  accord_id uuid NOT NULL REFERENCES public.accords_journal_sorties(id),
  sortie_le timestamptz NOT NULL,
  retour_le timestamptz NOT NULL,
  -- Vrai quand l'absence a mene a la sortie de la salle (delai depasse).
  sortie_salle boolean NOT NULL DEFAULT false,
  note_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT journal_sorties_app_ordre CHECK (retour_le > sortie_le)
);
CREATE INDEX IF NOT EXISTS journal_sorties_app_seance_idx
  ON public.journal_sorties_app (session_id, eleve_id, retour_le);

ALTER TABLE public.journal_sorties_app ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.journal_sorties_app FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.journal_sorties_app IS
  'HORS-SALLE-2 (12/11/2026) : chaque sortie de l''application d''un eleve pendant une seance, '
  'de quand a quand (heures posees par le serveur) et si elle a mene a la sortie de la salle. '
  'Ecrit par noter_sortie_app, lu par sorties_seance ; aucun droit direct. Duree de conservation : '
  'a decider par le directeur.';

-- ---------------------------------------------------------------------------
-- 4. Les aides privees
-- ---------------------------------------------------------------------------

-- Le type de l'eleve, ou NULL quand il ne se lit pas (pas de fiche eleve).
CREATE OR REPLACE FUNCTION private.sorties_type_eleve(p_eleve uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT sp.student_type::text
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.profile_id
   WHERE sp.profile_id = p_eleve
     AND sp.deleted_at IS NULL
     AND p.deleted_at IS NULL
     AND p.role = 'student';
$function$;

-- Le journal est-il allume par la direction ?
CREATE OR REPLACE FUNCTION private.sorties_journal_actif()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                    WHERE c.key = 'salle.sorties.journal_actif'), false);
$function$;

-- La version du texte en cours.
CREATE OR REPLACE FUNCTION private.sorties_version_courante()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT c.value #>> '{}' FROM public.app_config c
   WHERE c.key = 'salle.sorties.accord_version';
$function$;

-- L'appelant peut-il donner ou retirer l'accord pour cet eleve ?
--   * un tuteur, pour un eleve de son foyer qui n'est pas autonome (ou dont le
--     type ne se lit pas) ;
--   * l'eleve autonome, pour lui-meme.
-- Un enfant ne decide jamais pour lui-meme.
CREATE OR REPLACE FUNCTION private.sorties_peut_decider(p_eleve uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    auth.uid() IS NOT NULL
    AND p_eleve IS NOT NULL
    AND public.app_account_valid()
    AND EXISTS (SELECT 1 FROM public.profiles e
                 WHERE e.id = p_eleve AND e.role = 'student' AND e.deleted_at IS NULL)
    AND (
      (public.app_role() = 'guardian'
       AND auth.uid() <> p_eleve
       AND public.est_du_foyer(p_eleve)
       AND private.sorties_type_eleve(p_eleve) IS DISTINCT FROM 'autonomous')
      OR
      (public.app_role() = 'student'
       AND auth.uid() = p_eleve
       AND private.sorties_type_eleve(p_eleve) = 'autonomous')
    ), false);
$function$;

-- L'accord qui permet d'ecrire pour cet eleve maintenant, ou NULL : en cours,
-- a la version en cours, et donne par la bonne personne AUJOURD'HUI (un tuteur
-- encore dans le foyer pour un eleve non autonome ; l'eleve lui-meme s'il est
-- autonome). Un eleve devenu autonome decide de nouveau pour lui-meme.
CREATE OR REPLACE FUNCTION private.sorties_accord_valide(p_eleve uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT a.id
    FROM public.accords_journal_sorties a
   WHERE a.eleve_id = p_eleve
     AND a.retire_le IS NULL
     AND a.version = private.sorties_version_courante()
     AND CASE
           WHEN private.sorties_type_eleve(p_eleve) = 'autonomous'
             THEN a.accepte_par = p_eleve
           ELSE a.accepte_par <> p_eleve
                AND EXISTS (
                  SELECT 1 FROM public.profiles g
                    JOIN public.profiles e ON e.id = a.eleve_id
                   WHERE g.id = a.accepte_par
                     AND g.role = 'guardian'
                     AND g.deleted_at IS NULL
                     AND e.household_id IS NOT NULL
                     AND g.household_id = e.household_id)
         END
   LIMIT 1;
$function$;

-- ---------------------------------------------------------------------------
-- 5. L'accord : lire, donner, retirer
-- ---------------------------------------------------------------------------

-- Ce que la page de l'accord montre : l'etat du journal, la version du texte,
-- et une entree par eleve sur lequel l'appelant decide (ses enfants non
-- autonomes pour un tuteur ; lui-meme pour un eleve autonome).
CREATE OR REPLACE FUNCTION public.accords_sorties()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND public.app_account_valid()
                  AND public.app_role() IN ('guardian', 'student'), false) THEN
    RAISE EXCEPTION 'accord du journal des sorties reserve au tuteur et a l''eleve autonome'
      USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'journalActif', private.sorties_journal_actif(),
    'versionCourante', private.sorties_version_courante(),
    'eleves', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'eleveId', e.id,
               'prenom', e.first_name,
               'autonome', private.sorties_type_eleve(e.id) = 'autonomous',
               'enCours', v.id IS NOT NULL,
               'version', v.version,
               'accepteLe', v.accepte_le)
             ORDER BY e.first_name, e.id)
        FROM public.profiles e
        LEFT JOIN LATERAL (
          SELECT a.id, a.version, a.accepte_le
            FROM public.accords_journal_sorties a
           WHERE a.id = private.sorties_accord_valide(e.id)) v ON true
       WHERE e.role = 'student'
         AND e.deleted_at IS NULL
         AND (e.id = v_moi OR (e.household_id IS NOT NULL
                               AND e.household_id = public.app_household_id()))
         AND private.sorties_peut_decider(e.id)), '[]'::jsonb));
END;
$function$;

-- Donner l'accord pour un eleve, a la version affichee.
CREATE OR REPLACE FUNCTION public.accepter_accord_sorties(p_eleve uuid, p_version text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_courante text;
BEGIN
  IF NOT private.sorties_peut_decider(p_eleve) THEN
    RAISE EXCEPTION 'accord du journal des sorties : refuse pour cet eleve'
      USING ERRCODE = '42501';
  END IF;
  -- Journal eteint : aucun accord n'est recueilli sur un texte non valide.
  IF NOT private.sorties_journal_actif() THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'journal_eteint');
  END IF;
  v_courante := private.sorties_version_courante();
  IF v_courante IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'texte_indisponible');
  END IF;
  IF p_version IS DISTINCT FROM v_courante THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'version_perimee', 'versionCourante', v_courante);
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('accord_sorties:' || p_eleve::text, 0));
  -- Deja donne par cette personne a cette version : rien de nouveau (rejouable).
  IF NOT EXISTS (SELECT 1 FROM public.accords_journal_sorties a
                  WHERE a.eleve_id = p_eleve AND a.retire_le IS NULL
                    AND a.version = v_courante AND a.accepte_par = v_moi) THEN
    UPDATE public.accords_journal_sorties
       SET retire_le = pg_catalog.clock_timestamp(), retire_par = v_moi
     WHERE eleve_id = p_eleve AND retire_le IS NULL;
    INSERT INTO public.accords_journal_sorties (eleve_id, accepte_par, version)
    VALUES (p_eleve, v_moi, v_courante);
    PERFORM public.log_sensitive_access('accord_sorties_donne', 'accords_journal_sorties',
      p_eleve::text, pg_catalog.jsonb_build_object('version', v_courante));
  END IF;
  RETURN public.accords_sorties();
END;
$function$;

-- Retirer l'accord : la ligne garde sa date de retrait ; le releve s'arrete.
-- Les lignes passees restent lisibles.
CREATE OR REPLACE FUNCTION public.retirer_accord_sorties(p_eleve uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF NOT private.sorties_peut_decider(p_eleve) THEN
    RAISE EXCEPTION 'accord du journal des sorties : refuse pour cet eleve'
      USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM public.accords_journal_sorties a
              WHERE a.eleve_id = p_eleve AND a.retire_le IS NULL) THEN
    UPDATE public.accords_journal_sorties
       SET retire_le = pg_catalog.clock_timestamp(), retire_par = v_moi
     WHERE eleve_id = p_eleve AND retire_le IS NULL;
    PERFORM public.log_sensitive_access('accord_sorties_retire', 'accords_journal_sorties',
      p_eleve::text, '{}'::jsonb);
  END IF;
  RETURN public.accords_sorties();
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Noter une sortie
-- ---------------------------------------------------------------------------
-- L'appelant est l'eleve lui-meme, ou (D6) un tuteur de son foyer quand
-- l'eleve suit la seance depuis l'appareil du tuteur : p_eleve le nomme alors.
-- Rien ne leve d'erreur visible : sans droit, sans accord, journal eteint ou
-- hors seance, la fonction rend {"note": false} et l'ecran de l'eleve ne
-- montre jamais rien. Le serveur pose les heures : retour = maintenant,
-- sortie = maintenant moins p_secondes, borne a 1 s au moins et a la duree
-- ecoulee depuis le debut de la seance au plus.
CREATE OR REPLACE FUNCTION public.noter_sortie_app(
  p_session_id uuid,
  p_secondes integer,
  p_sortie_salle boolean,
  p_eleve uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_eleve uuid;
  v_debut timestamptz;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_ecoule integer;
  v_secondes integer;
  v_accord uuid;
  v_non jsonb := pg_catalog.jsonb_build_object('note', false);
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND p_session_id IS NOT NULL
                  AND public.app_account_valid(), false) THEN
    RETURN v_non;
  END IF;
  v_eleve := coalesce(p_eleve, v_moi);
  IF v_eleve = v_moi THEN
    IF NOT coalesce(public.app_role() = 'student', false) THEN
      RETURN v_non;
    END IF;
  ELSIF NOT coalesce(public.app_role() = 'guardian' AND public.est_du_foyer(v_eleve), false) THEN
    RETURN v_non;
  END IF;
  IF NOT private.sorties_journal_actif() THEN
    RETURN v_non;
  END IF;
  -- Participant eleve de cette seance, seance en cours.
  SELECT s.started_at INTO v_debut
    FROM public.sessions s
    JOIN public.session_participants sp
      ON sp.session_id = s.id AND sp.profile_id = v_eleve
     AND sp.role = 'student' AND sp.deleted_at IS NULL
   WHERE s.id = p_session_id
     AND s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND v_maintenant >= s.started_at
     AND v_maintenant <= s.ended_at
           + pg_catalog.make_interval(mins => public.app_config_int('grace_after_end_minutes', 15));
  IF v_debut IS NULL THEN
    RETURN v_non;
  END IF;
  v_ecoule := pg_catalog.floor(extract(epoch FROM v_maintenant - v_debut))::integer;
  IF v_ecoule < 1 THEN
    RETURN v_non;
  END IF;
  v_accord := private.sorties_accord_valide(v_eleve);
  IF v_accord IS NULL THEN
    RETURN v_non;
  END IF;
  v_secondes := greatest(1, least(coalesce(p_secondes, 1), v_ecoule));
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('journal_sorties:' || p_session_id::text || ':' || v_eleve::text, 0));
  -- Plafond : 200 lignes par seance et par eleve.
  IF (SELECT pg_catalog.count(*) FROM public.journal_sorties_app j
       WHERE j.session_id = p_session_id AND j.eleve_id = v_eleve) >= 200 THEN
    RETURN v_non;
  END IF;
  -- Pas de doublon dans la meme seconde.
  IF EXISTS (SELECT 1 FROM public.journal_sorties_app j
              WHERE j.session_id = p_session_id AND j.eleve_id = v_eleve
                AND j.retour_le > v_maintenant - interval '1 second') THEN
    RETURN v_non;
  END IF;
  INSERT INTO public.journal_sorties_app
    (session_id, eleve_id, accord_id, sortie_le, retour_le, sortie_salle)
  VALUES
    (p_session_id, v_eleve, v_accord,
     v_maintenant - pg_catalog.make_interval(secs => v_secondes),
     v_maintenant, coalesce(p_sortie_salle, false));
  RETURN pg_catalog.jsonb_build_object('note', true);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Lire le journal d'une seance
-- ---------------------------------------------------------------------------
-- La regle de lecture de presence_seance_v (20261102900000), sans le
-- controleur : la direction lit tout ; l'enseignant de la seance (titulaire ou
-- remplacant effectif) ses eleves ; le tuteur les enfants de son foyer ;
-- l'eleve les siennes. Jamais les lignes d'un autre foyer.
CREATE OR REPLACE FUNCTION public.sorties_seance(p_session_id uuid)
RETURNS TABLE (
  eleve_id uuid,
  prenom text,
  sortie_le timestamptz,
  retour_le timestamptz,
  duree_secondes integer,
  sortie_salle boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_moi uuid := auth.uid();
  v_role public.app_role := public.app_role();
BEGIN
  IF NOT coalesce(v_moi IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'journal des sorties : compte requis' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT j.eleve_id, p.first_name::text, j.sortie_le, j.retour_le,
         pg_catalog.floor(extract(epoch FROM j.retour_le - j.sortie_le))::integer,
         j.sortie_salle
    FROM public.journal_sorties_app j
    JOIN public.sessions s ON s.id = j.session_id AND s.deleted_at IS NULL
    JOIN public.profiles p ON p.id = j.eleve_id
   WHERE j.session_id = p_session_id
     AND coalesce(
           v_role = 'admin'
           OR (v_role = 'teacher'
               AND (s.teacher_id = v_moi
                    OR private.c29_enseignant_effectif_session(s.id) = v_moi))
           OR (v_role = 'guardian' AND j.eleve_id <> v_moi AND public.est_du_foyer(j.eleve_id))
           OR (v_role = 'student' AND j.eleve_id = v_moi),
         false)
   ORDER BY j.sortie_le, j.id;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. Le delai, lu par tout participant : regles_academie() gagne trois cles
--    (meme signature, meme type jsonb ; corps de 0043 recopie a l'identique).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.regles_academie()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  select case
    when public.compte_en_parcours() then jsonb_build_object(
      'capacite_enfant',      public.app_config_int('groupe.capacite_enfant', 5),
      'capacite_adulte',      public.app_config_int('groupe.capacite_adulte', 6),
      'minimum_lancement',    public.app_config_int('groupe.minimum_lancement', 3),
      'seances_par_semaine',  public.app_config_int('groupe.seances_par_semaine', 3),
      'duree_minutes_enfant', public.app_config_int('seance.duree_minutes_enfant', 60),
      'duree_minutes_adulte', public.app_config_int('seance.duree_minutes_adulte', 90),
      'pause_minutes_enfant', public.app_config_int('seance.pause_minutes_enfant', 6),
      'pause_minutes_adulte', public.app_config_int('seance.pause_minutes_adulte', 0),
      -- HORS-SALLE-2 : le delai hors de l'application avant la sortie de la
      -- salle, et l'etat du journal des sorties (sans aucune donnee).
      'sorties_delai_secondes', public.app_config_int('salle.sorties.delai_secondes', 30),
      'sorties_journal_actif', private.sorties_journal_actif(),
      'sorties_accord_version', private.sorties_version_courante()
    )
    else null
  end;
$function$;

-- ---------------------------------------------------------------------------
-- 9. Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.sorties_config_valide()'::pg_catalog.regprocedure,
    'private.sorties_type_eleve(uuid)'::pg_catalog.regprocedure,
    'private.sorties_journal_actif()'::pg_catalog.regprocedure,
    'private.sorties_version_courante()'::pg_catalog.regprocedure,
    'private.sorties_peut_decider(uuid)'::pg_catalog.regprocedure,
    'private.sorties_accord_valide(uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accords_sorties()'::pg_catalog.regprocedure,
    'public.accepter_accord_sorties(uuid,text)'::pg_catalog.regprocedure,
    'public.retirer_accord_sorties(uuid)'::pg_catalog.regprocedure,
    'public.noter_sortie_app(uuid,integer,boolean,uuid)'::pg_catalog.regprocedure,
    'public.sorties_seance(uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;
  -- regles_academie : les droits de 0043, redits.
  REVOKE EXECUTE ON FUNCTION public.regles_academie() FROM PUBLIC, anon;
  GRANT EXECUTE ON FUNCTION public.regles_academie() TO authenticated, agent_ro;
END;
$droits$;

COMMENT ON FUNCTION public.noter_sortie_app(uuid, integer, boolean, uuid) IS
  'HORS-SALLE-2 : note une sortie de l''application de l''eleve (lui-meme, ou depuis l''appareil '
  'de son tuteur, D6). Journal allume, accord en cours a la version en cours, seance en cours ; '
  'heures posees par le serveur ; 200 lignes au plus par seance et par eleve. Rend {"note": bool}, '
  'jamais d''erreur visible.';
COMMENT ON FUNCTION public.sorties_seance(uuid) IS
  'HORS-SALLE-2 : les sorties de l''application d''une seance que l''appelant a le droit de lire '
  '(direction ; enseignant de la seance ; tuteur, ses enfants ; eleve, les siennes).';

-- ---------------------------------------------------------------------------
-- 10. Verification
-- ---------------------------------------------------------------------------
DO $verification$
DECLARE
  v_fn text;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY[
    'public.accords_sorties()',
    'public.accepter_accord_sorties(uuid,text)',
    'public.retirer_accord_sorties(uuid)',
    'public.noter_sortie_app(uuid,integer,boolean,uuid)',
    'public.sorties_seance(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_fn, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_fn, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_fn, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_fn, 'EXECUTE') THEN
      RAISE EXCEPTION 'HORS-SALLE-2 : droits inattendus sur %', v_fn;
    END IF;
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
              FROM pg_catalog.pg_proc p WHERE p.oid = v_fn::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'HORS-SALLE-2 : % doit etre SECURITY DEFINER a search_path vide', v_fn;
    END IF;
  END LOOP;
  FOREACH v_fn IN ARRAY ARRAY[
    'private.sorties_type_eleve(uuid)',
    'private.sorties_journal_actif()',
    'private.sorties_version_courante()',
    'private.sorties_peut_decider(uuid)',
    'private.sorties_accord_valide(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_fn, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_fn, 'EXECUTE') THEN
      RAISE EXCEPTION 'HORS-SALLE-2 : % expose', v_fn;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.regles_academie()', 'EXECUTE') THEN
    RAISE EXCEPTION 'HORS-SALLE-2 : regles_academie ouverte a anon';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.accords_journal_sorties'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
              WHERE c.oid = 'public.journal_sorties_app'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HORS-SALLE-2 : RLS inactive';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.journal_sorties_app', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.journal_sorties_app', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.accords_journal_sorties', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.accords_journal_sorties', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.journal_sorties_app', 'SELECT') THEN
    RAISE EXCEPTION 'HORS-SALLE-2 : droit direct de table inattendu';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'journal_sorties_app'
         AND column_name IN ('session_id', 'eleve_id', 'accord_id', 'sortie_le',
                             'retour_le', 'sortie_salle')) <> 6
     OR (SELECT pg_catalog.count(*) FROM information_schema.columns
          WHERE table_schema = 'public' AND table_name = 'accords_journal_sorties'
            AND column_name IN ('eleve_id', 'accepte_par', 'version', 'accepte_le',
                                'retire_le', 'retire_par')) <> 6 THEN
    RAISE EXCEPTION 'HORS-SALLE-2 : colonnes manquantes';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.app_config
       WHERE key IN ('salle.sorties.journal_actif', 'salle.sorties.delai_secondes',
                     'salle.sorties.accord_version')) <> 3 THEN
    RAISE EXCEPTION 'HORS-SALLE-2 : reglages absents';
  END IF;
END;
$verification$;

COMMIT;
