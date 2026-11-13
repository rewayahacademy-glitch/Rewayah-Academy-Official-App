-- POINT-DE-SEANCE (lot 6 du plan ; directeur, 13/11/2026 : « le cahier me
-- fatigue » ; charte, partie 5 ; moteur, regle 35 ; arbitrages n. 96, 97,
-- 104, 105, 107).
--
-- Fichier SANS mot d'effacement. Additif et REJOUABLE : tables et index crees
-- seulement s'ils manquent, fonctions remplacees a signature egale, reglages
-- poses sans ecraser. Collable en un bloc.
--
-- AUCUN effet sur la paie : ce fichier ne lit ni n'ecrit `lesson_reports`, ne
-- touche aucune fonction `pai_*` ni `private.cahier_semaine_couvert`. La paie
-- d'une seance attend toujours son cahier (coupure C3 du 12/11). Le raccord
-- « le point libere la paie » est une decision a part, non codee ici.
--
-- Ce que fait le lot :
--   1. `point_seance` : une ligne par seance (qui, quand, note facultative).
--   2. `point_seance_eleves` : une ligne par eleve PRESENT (presence mesuree :
--      `private.presence_temps_reel` = 'presente'), sa reponse, s'il a ete
--      tire, et son etape du moment (`eleve_etape_en_cours.niveau_id`).
--   3. `point_seance_journal` : chaque envoi, tel quel (tout est trace).
--   4. `point_seance_lire`, `point_seance_envoyer`, `points_seance_a_faire` :
--      l'enseignant de la seance (titulaire ou remplacant). La direction lit.
--   5. `historique_seances_eleve` : le hub en lecture seule (enseignant,
--      direction, tuteur, adulte, eleve de 10 ans et plus) : chaque seance,
--      ce qui est acquis, ce qui est « A renforcer », le travail.
--
-- Ce que le lot NE fait PAS (dit au pilote) : la seance prevue et « Vu comme
-- prevu / moins / plus » (lot PLAN-DE-CLASSE absent) ; le passage tire dans
-- les donnees ; `learning_assignment` (il exige un document) ; « Stable »
-- (lot 8) ; tout message, push ou courriel (regle 35 : lot 11).
--
-- Reponses : 'a_suivi' (defaut d'un present), 'a_renforcer' (touche),
-- 'acquis' et 'pas_ecoute' (reserves a l'eleve tire, qui n'a pas de defaut).

BEGIN;

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.eleve_etape_en_cours') IS NULL
     OR pg_catalog.to_regprocedure('private.presence_temps_reel(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.dates_retenues(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'POINT-DE-SEANCE : SOCLE-PROGRAMME, PRESENCE-MINUTES ou CAHIER-C1 absent';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les reglages (la direction les change ; l'architecture ne bouge pas)
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  -- Delai pendant lequel l'enseignant peut corriger un point envoye.
  ('point_seance.modifiable_heures', pg_catalog.to_jsonb(24)),
  -- Garde-fou (REGLAGES.md) : un « A suivi » laisse par defaut compte pour
  -- une observation « Acquis » au plus N fois par semaine et par etape.
  ('point_seance.a_suivi_par_semaine', pg_catalog.to_jsonb(1)),
  -- Les seances commencees avant cet instant n'attendent aucun point.
  ('point_seance.debut', pg_catalog.to_jsonb(pg_catalog.now()))
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Les tables
-- ---------------------------------------------------------------------------
-- Sans cle etrangere vers sessions, a dessein (meme raison que
-- cahier_observations) : la fonction d'envoi est le seul ecrivain.
CREATE TABLE IF NOT EXISTS public.point_seance (
  session_id  uuid PRIMARY KEY,
  groupe_id   uuid NOT NULL,
  auteur_id   uuid NOT NULL REFERENCES public.profiles(id),
  envoye_le   timestamptz NOT NULL DEFAULT pg_catalog.now(),
  modifie_le  timestamptz,
  eleve_tire  uuid REFERENCES public.profiles(id),
  note        text CHECK (note IS NULL OR pg_catalog.char_length(note) BETWEEN 1 AND 1000)
);
CREATE INDEX IF NOT EXISTS point_seance_groupe_idx ON public.point_seance (groupe_id, envoye_le DESC);

COMMENT ON TABLE public.point_seance IS
  'POINT-DE-SEANCE (13/11/2026) : le point de fin de seance, une ligne par seance. '
  'La note est lue par l''enseignant et la direction, jamais par la famille. Aucun acces direct.';

CREATE TABLE IF NOT EXISTS public.point_seance_eleves (
  session_id  uuid NOT NULL REFERENCES public.point_seance(session_id),
  student_id  uuid NOT NULL REFERENCES public.profiles(id),
  reponse     text NOT NULL CHECK (reponse IN ('a_suivi', 'a_renforcer', 'acquis', 'pas_ecoute')),
  tire        boolean NOT NULL DEFAULT false,
  niveau_id   uuid REFERENCES public.programme_niveaux(id),
  maj_le      timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (session_id, student_id),
  -- L'eleve tire n'a pas de defaut ; les autres n'ont que « A suivi » ou
  -- « A renforcer ».
  CONSTRAINT point_seance_eleves_reponse_selon_tirage CHECK (
    (tire AND reponse IN ('acquis', 'a_renforcer', 'pas_ecoute'))
    OR (NOT tire AND reponse IN ('a_suivi', 'a_renforcer')))
);
CREATE UNIQUE INDEX IF NOT EXISTS point_seance_eleves_un_tire
  ON public.point_seance_eleves (session_id) WHERE tire;
CREATE INDEX IF NOT EXISTS point_seance_eleves_eleve_idx
  ON public.point_seance_eleves (student_id, session_id);

COMMENT ON TABLE public.point_seance_eleves IS
  'POINT-DE-SEANCE : une ligne par eleve PRESENT a la seance. a_suivi = defaut ; a_renforcer = '
  'touche ; acquis et pas_ecoute = eleve tire seulement. niveau_id = l''etape de l''eleve a '
  'l''envoi. Les absents et les presents en partie n''ont pas de ligne. Aucun acces direct.';

CREATE TABLE IF NOT EXISTS public.point_seance_journal (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  uuid NOT NULL REFERENCES public.point_seance(session_id),
  par         uuid NOT NULL REFERENCES public.profiles(id),
  le          timestamptz NOT NULL DEFAULT pg_catalog.now(),
  reponses    jsonb NOT NULL,
  note        text
);
CREATE INDEX IF NOT EXISTS point_seance_journal_session_idx
  ON public.point_seance_journal (session_id, le);

COMMENT ON TABLE public.point_seance_journal IS
  'POINT-DE-SEANCE : chaque envoi du point, tel qu''il a ete enregistre. Ajout seul. Aucun acces direct.';

ALTER TABLE public.point_seance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_seance_eleves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_seance_journal ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.point_seance, public.point_seance_eleves, public.point_seance_journal
  FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Les faits lus : seance tenue, presents, eleve tire
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.point_seance_reglage_int(p_cle text, p_defaut int)
RETURNS int
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'number'
                 THEN greatest((c.value #>> '{}')::numeric::int, 0) END
       FROM public.app_config c WHERE c.key = p_cle),
    p_defaut);
$function$;

-- Une seance est « tenue » quand elle est close, ou en cours et son heure de
-- fin passee. Une seance annulee ou non tenue n'attend aucun point.
CREATE OR REPLACE FUNCTION private.point_seance_tenue(p_session uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((
    SELECT s.groupe_id IS NOT NULL
           AND (s.status = 'ended'
                OR (s.status = 'in_progress' AND s.ended_at <= pg_catalog.now()))
      FROM public.sessions s
     WHERE s.id = p_session AND s.deleted_at IS NULL), false);
$function$;

-- Les presents (presence mesuree), dans l'ordre des eleves de la classe.
CREATE OR REPLACE FUNCTION private.point_seance_presents(p_session uuid)
RETURNS TABLE (student_id uuid, rang int)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT x.profile_id,
         (pg_catalog.row_number() OVER (ORDER BY x.entree NULLS LAST, x.profile_id))::int
    FROM (
      SELECT sp.profile_id,
             (SELECT pg_catalog.min(m.joined_at) FROM public.groupe_membres m
               WHERE m.groupe_id = s.groupe_id AND m.student_id = sp.profile_id) AS entree
        FROM public.sessions s
        JOIN public.session_participants sp
          ON sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL
        JOIN public.profiles p ON p.id = sp.profile_id AND p.deleted_at IS NULL
       WHERE s.id = p_session AND s.deleted_at IS NULL
         AND (SELECT t.statut FROM private.presence_temps_reel(s.id, sp.profile_id) t) = 'presente'
    ) x;
$function$;

-- L'eleve tire (charte, partie 5) : le premier present, dans l'ordre des
-- eleves de la classe, qui a attendu le plus longtemps depuis son dernier
-- tirage. « Pas eu le temps de l'ecouter » ne compte pas comme un tirage :
-- l'eleve reste en tete. Un absent garde sa place et passe a son retour. Pas
-- de tirage a la toute premiere seance tenue de la classe.
CREATE OR REPLACE FUNCTION private.point_seance_tirer(p_session uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pr.student_id
    FROM public.sessions s
    CROSS JOIN private.point_seance_presents(s.id) pr
   WHERE s.id = p_session
     AND EXISTS (SELECT 1 FROM public.sessions a
                  WHERE a.groupe_id = s.groupe_id AND a.deleted_at IS NULL
                    AND a.status = 'ended' AND a.started_at < s.started_at)
   ORDER BY (SELECT pg_catalog.max(a.started_at)
               FROM public.point_seance_eleves e
               JOIN public.sessions a ON a.id = e.session_id
              WHERE e.student_id = pr.student_id AND e.tire AND e.reponse <> 'pas_ecoute'
                AND a.started_at < s.started_at) NULLS FIRST,
            pr.rang
   LIMIT 1;
$function$;

REVOKE ALL ON FUNCTION private.point_seance_reglage_int(text, int),
  private.point_seance_tenue(uuid), private.point_seance_presents(uuid),
  private.point_seance_tirer(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 4. La page de l'enseignant : lire
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.point_seance_etat(p_session uuid, p_peut_ecrire boolean)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  s public.sessions%ROWTYPE;
  pt public.point_seance%ROWTYPE;
  v_tenue boolean := private.point_seance_tenue(p_session);
  v_heures int := private.point_seance_reglage_int('point_seance.modifiable_heures', 24);
  v_jusqua timestamptz;
  v_tire uuid;
  v_eleves jsonb;
  v_hors jsonb;
BEGIN
  SELECT * INTO s FROM public.sessions x WHERE x.id = p_session AND x.deleted_at IS NULL;
  SELECT * INTO pt FROM public.point_seance x WHERE x.session_id = p_session;

  IF pt.session_id IS NOT NULL THEN
    v_jusqua := pt.envoye_le + pg_catalog.make_interval(hours => v_heures);
    v_tire := pt.eleve_tire;
    -- Un point envoye garde ses eleves : la liste ne bouge plus.
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'student_id', e.student_id,
             'prenom', p.first_name,
             'etape', n.nom_humain,
             'tire', e.tire,
             'reponse', e.reponse)
             ORDER BY e.tire DESC, p.first_name, e.student_id), '[]'::jsonb)
      INTO v_eleves
      FROM public.point_seance_eleves e
      JOIN public.profiles p ON p.id = e.student_id
      LEFT JOIN public.programme_niveaux n ON n.id = e.niveau_id
     WHERE e.session_id = p_session;
  ELSIF v_tenue THEN
    v_tire := private.point_seance_tirer(p_session);
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'student_id', pr.student_id,
             'prenom', p.first_name,
             'etape', n.nom_humain,
             'tire', pr.student_id IS NOT DISTINCT FROM v_tire,
             'reponse', CASE WHEN pr.student_id IS NOT DISTINCT FROM v_tire THEN NULL ELSE 'a_suivi' END)
             ORDER BY (pr.student_id IS NOT DISTINCT FROM v_tire) DESC, p.first_name, pr.student_id),
             '[]'::jsonb)
      INTO v_eleves
      FROM private.point_seance_presents(p_session) pr
      JOIN public.profiles p ON p.id = pr.student_id
      LEFT JOIN public.eleve_etape_en_cours f ON f.student_id = pr.student_id
      LEFT JOIN public.programme_niveaux n ON n.id = f.niveau_id;
  ELSE
    v_eleves := '[]'::jsonb;
  END IF;

  -- Ceux qui ne figurent pas au point : absents et presents en partie.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'student_id', sp.profile_id, 'prenom', p.first_name, 'presence', t.statut)
           ORDER BY p.first_name, sp.profile_id), '[]'::jsonb)
    INTO v_hors
    FROM public.session_participants sp
    JOIN public.profiles p ON p.id = sp.profile_id AND p.deleted_at IS NULL
    CROSS JOIN LATERAL private.presence_temps_reel(p_session, sp.profile_id) t
   WHERE sp.session_id = p_session AND sp.role = 'student' AND sp.deleted_at IS NULL
     AND v_tenue
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_eleves) x
                      WHERE x ->> 'student_id' = sp.profile_id::text);

  RETURN pg_catalog.jsonb_build_object(
    'session_id', s.id,
    'groupe_id', s.groupe_id,
    'classe', (SELECT g.libelle FROM public.groupes g WHERE g.id = s.groupe_id),
    'debut', s.started_at,
    'fin', s.ended_at,
    'tenue', v_tenue,
    'envoye', pt.session_id IS NOT NULL,
    'envoye_le', pt.envoye_le,
    'modifie_le', pt.modifie_le,
    'modifiable_jusqua', v_jusqua,
    'peut_envoyer', coalesce(p_peut_ecrire AND v_tenue
                             AND (pt.session_id IS NULL OR pg_catalog.now() <= v_jusqua), false),
    'eleve_tire', v_tire,
    'note', pt.note,
    'eleves', v_eleves,
    'hors_point', v_hors);
END;
$function$;

REVOKE ALL ON FUNCTION private.point_seance_etat(uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE OR REPLACE FUNCTION public.point_seance_lire(p_session_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_enseignant boolean;
BEGIN
  v_enseignant := coalesce(
    public.app_role() = 'teacher'
    AND private.c29_enseignant_effectif_session(p_session_id) = v_user, false);
  IF NOT coalesce(v_user IS NOT NULL AND p_session_id IS NOT NULL AND public.app_account_valid()
                  AND (v_enseignant OR public.app_role() = 'admin')
                  AND EXISTS (SELECT 1 FROM public.sessions s
                               WHERE s.id = p_session_id AND s.deleted_at IS NULL
                                 AND s.groupe_id IS NOT NULL), false) THEN
    RAISE EXCEPTION 'point de seance refuse' USING errcode = '42501';
  END IF;
  RETURN private.point_seance_etat(p_session_id, v_enseignant);
END;
$function$;

COMMENT ON FUNCTION public.point_seance_lire(uuid) IS
  'POINT-DE-SEANCE : la page du point de fin de seance. Les presents (presence mesuree), l''eleve '
  'tire, les reponses deja donnees, le delai de correction. Enseignant de la seance (titulaire ou '
  'remplacant) ; direction en lecture.';

-- ---------------------------------------------------------------------------
-- 5. Envoyer (et corriger pendant le delai)
-- ---------------------------------------------------------------------------
-- p_reponses : objet { "<student_id>": "a_renforcer" | "a_suivi" | "acquis" |
-- "pas_ecoute" }. Un present sans cle recoit « A suivi » (le defaut), sauf
-- l'eleve tire : sans reponse pour lui, le point ne s'envoie pas.
CREATE OR REPLACE FUNCTION public.point_seance_envoyer(
  p_session_id uuid,
  p_reponses jsonb DEFAULT '{}'::jsonb,
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  s public.sessions%ROWTYPE;
  pt public.point_seance%ROWTYPE;
  v_note text := nullif(pg_catalog.btrim(coalesce(p_note, '')), '');
  v_rep jsonb := coalesce(p_reponses, '{}'::jsonb);
  v_heures int := private.point_seance_reglage_int('point_seance.modifiable_heures', 24);
  v_tire uuid;
  v_nouveau boolean;
  r record;
  v_reponse text;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND p_session_id IS NOT NULL AND public.app_account_valid()
                  AND public.app_role() = 'teacher'
                  AND private.c29_enseignant_effectif_session(p_session_id) = v_user, false) THEN
    RAISE EXCEPTION 'point de seance refuse' USING errcode = '42501';
  END IF;
  IF pg_catalog.jsonb_typeof(v_rep) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'point_seance_reponse_inconnue' USING errcode = '22023';
  END IF;
  IF v_note IS NOT NULL AND pg_catalog.char_length(v_note) > 1000 THEN
    RAISE EXCEPTION 'point_seance_note_trop_longue' USING errcode = '22023';
  END IF;

  -- Un seul envoi a la fois pour une seance.
  SELECT * INTO s FROM public.sessions x
   WHERE x.id = p_session_id AND x.deleted_at IS NULL FOR UPDATE;
  IF NOT private.point_seance_tenue(p_session_id) THEN
    RAISE EXCEPTION 'point_seance_seance_non_tenue' USING errcode = '22023';
  END IF;

  SELECT * INTO pt FROM public.point_seance x WHERE x.session_id = p_session_id;
  v_nouveau := pt.session_id IS NULL;
  IF NOT v_nouveau
     AND pg_catalog.now() > pt.envoye_le + pg_catalog.make_interval(hours => v_heures) THEN
    RAISE EXCEPTION 'point_seance_delai_depasse' USING errcode = '22023';
  END IF;

  IF v_nouveau THEN
    v_tire := private.point_seance_tirer(p_session_id);
    IF NOT EXISTS (SELECT 1 FROM private.point_seance_presents(p_session_id)) THEN
      RAISE EXCEPTION 'point_seance_aucun_present' USING errcode = '22023';
    END IF;
  ELSE
    v_tire := pt.eleve_tire;
  END IF;

  -- Jamais une reponse pour un eleve qui n'est pas au point (absent, present
  -- en partie, eleve d'une autre classe).
  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_object_keys(v_rep) k
     WHERE NOT EXISTS (
       SELECT 1 FROM private.point_seance_presents(p_session_id) pr
        WHERE v_nouveau AND pr.student_id::text = k
       UNION ALL
       SELECT 1 FROM public.point_seance_eleves e
        WHERE NOT v_nouveau AND e.session_id = p_session_id AND e.student_id::text = k)) THEN
    RAISE EXCEPTION 'point_seance_eleve_absent' USING errcode = '22023';
  END IF;

  IF v_nouveau THEN
    INSERT INTO public.point_seance (session_id, groupe_id, auteur_id, eleve_tire, note)
    VALUES (p_session_id, s.groupe_id, v_user, v_tire, v_note);
  ELSE
    UPDATE public.point_seance
       SET modifie_le = pg_catalog.now(), note = v_note
     WHERE session_id = p_session_id;
  END IF;

  FOR r IN
    SELECT pr.student_id,
           (SELECT f.niveau_id FROM public.eleve_etape_en_cours f
             WHERE f.student_id = pr.student_id) AS niveau_id
      FROM private.point_seance_presents(p_session_id) pr
     WHERE v_nouveau
    UNION ALL
    SELECT e.student_id, e.niveau_id
      FROM public.point_seance_eleves e
     WHERE NOT v_nouveau AND e.session_id = p_session_id
  LOOP
    v_reponse := v_rep ->> r.student_id::text;
    IF r.student_id IS NOT DISTINCT FROM v_tire THEN
      IF v_reponse IS NULL OR v_reponse NOT IN ('acquis', 'a_renforcer', 'pas_ecoute') THEN
        RAISE EXCEPTION 'point_seance_eleve_tire_sans_reponse' USING errcode = '22023';
      END IF;
    ELSE
      v_reponse := coalesce(v_reponse, 'a_suivi');
      IF v_reponse NOT IN ('a_suivi', 'a_renforcer') THEN
        RAISE EXCEPTION 'point_seance_reponse_inconnue' USING errcode = '22023';
      END IF;
    END IF;
    INSERT INTO public.point_seance_eleves (session_id, student_id, reponse, tire, niveau_id)
    VALUES (p_session_id, r.student_id, v_reponse,
            r.student_id IS NOT DISTINCT FROM v_tire, r.niveau_id)
    ON CONFLICT (session_id, student_id)
    DO UPDATE SET reponse = EXCLUDED.reponse, maj_le = pg_catalog.now()
     WHERE public.point_seance_eleves.reponse IS DISTINCT FROM EXCLUDED.reponse;
  END LOOP;

  INSERT INTO public.point_seance_journal (session_id, par, reponses, note)
  SELECT p_session_id, v_user,
         coalesce(pg_catalog.jsonb_object_agg(e.student_id::text, e.reponse), '{}'::jsonb), v_note
    FROM public.point_seance_eleves e
   WHERE e.session_id = p_session_id;

  RETURN private.point_seance_etat(p_session_id, true);
END;
$function$;

COMMENT ON FUNCTION public.point_seance_envoyer(uuid, jsonb, text) IS
  'POINT-DE-SEANCE : envoie le point de fin de seance, ou le corrige pendant le delai '
  '(point_seance.modifiable_heures). Enseignant de la seance seul. Refuse : seance non tenue, '
  'eleve tire sans reponse, reponse pour un eleve qui n''est pas present, delai depasse.';

-- ---------------------------------------------------------------------------
-- 6. Les points a faire (rattrapage : l'application a ete fermee)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.points_seance_a_faire()
RETURNS TABLE (session_id uuid, groupe_id uuid, classe text, debut timestamptz, fin timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_user uuid := auth.uid();
  v_debut timestamptz;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_account_valid()
                  AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'points de seance refuses' USING errcode = '42501';
  END IF;
  BEGIN
    SELECT (c.value #>> '{}')::timestamptz INTO v_debut
      FROM public.app_config c WHERE c.key = 'point_seance.debut';
  EXCEPTION WHEN OTHERS THEN
    v_debut := NULL;
  END;
  RETURN QUERY
    SELECT s.id, s.groupe_id, g.libelle, s.started_at, s.ended_at
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id
     WHERE s.deleted_at IS NULL
       AND s.started_at >= coalesce(v_debut, '-infinity'::timestamptz)
       AND s.started_at > pg_catalog.now() - interval '60 days'
       AND private.point_seance_tenue(s.id)
       AND private.c29_enseignant_effectif_session(s.id) = v_user
       AND NOT EXISTS (SELECT 1 FROM public.point_seance pt WHERE pt.session_id = s.id)
       AND EXISTS (SELECT 1 FROM private.point_seance_presents(s.id))
     ORDER BY s.started_at
     LIMIT 50;
END;
$function$;

COMMENT ON FUNCTION public.points_seance_a_faire() IS
  'POINT-DE-SEANCE : les seances tenues de l''enseignant connecte (titulaire ou remplacant) qui '
  'attendent encore leur point, les plus anciennes d''abord. Depuis point_seance.debut.';

-- ---------------------------------------------------------------------------
-- 7. Le hub : l'historique des seances d'un eleve, et ce que le serveur en deduit
-- ---------------------------------------------------------------------------
-- Ce que le serveur deduit seul, par etape (pas encore par objectif : le plan
-- de la classe n'existe pas) :
--   * acquis : chaque « Acquis » touche compte ; un « A suivi » laisse par
--     defaut compte au plus `point_seance.a_suivi_par_semaine` fois par
--     semaine et par etape ;
--   * a_renforcer : la derniere reponse de l'eleve sur l'etape est « A
--     renforcer » (« A renforcer » puis « A suivi » : plus rien) ;
--   * deux_de_suite : ses deux dernieres reponses sur l'etape sont « A
--     renforcer » (condition de la regle 14 ; enseignant et direction seuls) ;
--   * travail : « cible » apres un « A renforcer », « relire » sinon.
-- « Pas eu le temps de l'ecouter » n'ecrit aucune observation. Une absence ou
-- une presence partielle n'est jamais un « A renforcer ».
CREATE OR REPLACE FUNCTION public.historique_seances_eleve(p_eleve_id uuid, p_limite int DEFAULT 30)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_groupe uuid;
  v_famille boolean;
  v_ecole boolean;
  v_limite int := least(greatest(coalesce(p_limite, 30), 1), 100);
  v_par_semaine int := private.point_seance_reglage_int('point_seance.a_suivi_par_semaine', 1);
  v_etape uuid;
  v_seances jsonb;
  v_synthese jsonb;
BEGIN
  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL
   ORDER BY m.joined_at DESC, m.groupe_id
   LIMIT 1;

  v_famille := coalesce(
       (public.app_role() = 'student' AND p_eleve_id = v_user)
    OR (public.app_role() = 'guardian' AND p_eleve_id = v_user
        AND EXISTS (SELECT 1 FROM public.student_profiles sp
                     WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                       AND sp.deleted_at IS NULL))
    OR (public.app_role() = 'guardian'
        AND EXISTS (SELECT 1 FROM public.profiles p
                     WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                       AND p.household_id IS NOT NULL
                       AND p.household_id = public.app_household_id())), false);
  v_ecole := coalesce(
       public.app_role() = 'admin'
    OR (v_groupe IS NOT NULL AND private.cahier_c1_peut_lire_classe(v_groupe)), false);

  -- L'enfant de 6 a 9 ans ne lit pas l'historique avec son compte : son
  -- tuteur le lit (charte, partie 10). Meme regle que les dates du lot 1.
  IF NOT coalesce(v_user IS NOT NULL AND p_eleve_id IS NOT NULL AND public.app_account_valid()
                  AND (v_famille OR v_ecole)
                  AND NOT (NOT v_ecole AND private.dates_retenues(p_eleve_id, v_groupe)), false) THEN
    RAISE EXCEPTION 'historique des seances refuse' USING errcode = '42501';
  END IF;

  SELECT f.niveau_id INTO v_etape FROM public.eleve_etape_en_cours f WHERE f.student_id = p_eleve_id;

  SELECT coalesce(pg_catalog.jsonb_agg(l.ligne ORDER BY l.debut DESC), '[]'::jsonb)
    INTO v_seances
    FROM (
      SELECT s.started_at AS debut,
             pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
               'session_id', s.id,
               'debut', s.started_at,
               'classe', g.libelle,
               'presence', (SELECT t.statut FROM private.presence_temps_reel(s.id, p_eleve_id) t),
               'point', pt.session_id IS NOT NULL,
               -- La famille lit « A suivi » ou « A renforcer », et rien d'autre.
               'reponse', CASE
                 WHEN e.reponse IS NULL THEN NULL
                 WHEN v_ecole THEN e.reponse
                 WHEN e.reponse = 'a_renforcer' THEN 'a_renforcer'
                 WHEN e.reponse = 'pas_ecoute' THEN NULL
                 ELSE 'a_suivi' END,
               'etape', n.nom_humain,
               'travail', CASE WHEN e.reponse IS NULL THEN NULL
                               WHEN e.reponse = 'a_renforcer' THEN 'cible' ELSE 'relire' END,
               'tire', CASE WHEN v_ecole THEN e.tire END,
               'note', CASE WHEN v_ecole THEN pt.note END)) AS ligne
        FROM public.session_participants sp
        JOIN public.sessions s ON s.id = sp.session_id AND s.deleted_at IS NULL
        JOIN public.groupes g ON g.id = s.groupe_id
        LEFT JOIN public.point_seance pt ON pt.session_id = s.id
        LEFT JOIN public.point_seance_eleves e ON e.session_id = s.id AND e.student_id = p_eleve_id
        LEFT JOIN public.programme_niveaux n ON n.id = e.niveau_id
       WHERE sp.profile_id = p_eleve_id AND sp.role = 'student' AND sp.deleted_at IS NULL
         AND private.point_seance_tenue(s.id)
       ORDER BY s.started_at DESC
       LIMIT v_limite
    ) l;

  WITH obs AS (
    SELECT e.reponse, e.niveau_id, s.started_at,
           pg_catalog.date_trunc('week', s.started_at AT TIME ZONE coalesce(g.timezone_iana, 'UTC')) AS semaine,
           pg_catalog.row_number() OVER (PARTITION BY e.niveau_id ORDER BY s.started_at DESC) AS recul
      FROM public.point_seance_eleves e
      JOIN public.sessions s ON s.id = e.session_id AND s.deleted_at IS NULL
      JOIN public.groupes g ON g.id = s.groupe_id
     WHERE e.student_id = p_eleve_id AND e.reponse <> 'pas_ecoute'
       AND e.niveau_id IS NOT DISTINCT FROM v_etape
  ),
  defauts AS (
    SELECT least(pg_catalog.count(*), v_par_semaine)::int AS n
      FROM obs WHERE reponse = 'a_suivi' GROUP BY semaine
  )
  SELECT pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'etape', (SELECT n.nom_humain FROM public.programme_niveaux n WHERE n.id = v_etape),
           'points', (SELECT pg_catalog.count(*)::int FROM obs),
           'acquis', (SELECT pg_catalog.count(*)::int FROM obs WHERE reponse = 'acquis')
                     + coalesce((SELECT pg_catalog.sum(d.n)::int FROM defauts d), 0),
           'a_renforcer', coalesce((SELECT o.reponse = 'a_renforcer' FROM obs o WHERE o.recul = 1), false),
           'a_renforcer_depuis', (SELECT o.started_at FROM obs o
                                   WHERE o.recul = 1 AND o.reponse = 'a_renforcer'),
           'travail', (SELECT CASE WHEN o.reponse = 'a_renforcer' THEN 'cible' ELSE 'relire' END
                         FROM obs o WHERE o.recul = 1),
           'deux_de_suite', CASE WHEN v_ecole THEN
             coalesce((SELECT pg_catalog.count(*) = 2 FROM obs o
                        WHERE o.recul <= 2 AND o.reponse = 'a_renforcer'), false) END))
    INTO v_synthese;

  RETURN pg_catalog.jsonb_build_object(
    'eleve_id', p_eleve_id,
    'lecteur', CASE WHEN v_ecole THEN 'academie' ELSE 'famille' END,
    'synthese', v_synthese,
    'seances', v_seances);
END;
$function$;

COMMENT ON FUNCTION public.historique_seances_eleve(uuid, int) IS
  'POINT-DE-SEANCE : l''historique des seances d''un eleve, ecrit par le systeme (presence mesuree '
  'et points de fin de seance), et ce que le serveur en deduit (acquis, a renforcer, travail). '
  'Enseignant de la classe, remplacant dans sa fenetre, direction : tout, note comprise. Tuteur du '
  'foyer, adulte, eleve de 10 ans et plus : sans note ni tirage. Refuse au compte d''un enfant de 6 a 9 ans.';

REVOKE ALL ON FUNCTION public.point_seance_lire(uuid),
  public.point_seance_envoyer(uuid, jsonb, text), public.points_seance_a_faire(),
  public.historique_seances_eleve(uuid, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.point_seance_lire(uuid),
  public.point_seance_envoyer(uuid, jsonb, text), public.points_seance_a_faire(),
  public.historique_seances_eleve(uuid, int) TO authenticated;

-- ---------------------------------------------------------------------------
-- 8. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  t text;
  f text;
BEGIN
  FOREACH t IN ARRAY ARRAY['public.point_seance', 'public.point_seance_eleves', 'public.point_seance_journal'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = t::pg_catalog.regclass) THEN
      RAISE EXCEPTION 'POINT-DE-SEANCE : RLS absente sur %', t;
    END IF;
    IF pg_catalog.has_table_privilege('authenticated', t, 'SELECT')
       OR pg_catalog.has_table_privilege('authenticated', t, 'INSERT')
       OR pg_catalog.has_table_privilege('authenticated', t, 'UPDATE')
       OR pg_catalog.has_table_privilege('anon', t, 'SELECT') THEN
      RAISE EXCEPTION 'POINT-DE-SEANCE : droits directs inattendus sur %', t;
    END IF;
  END LOOP;
  FOREACH f IN ARRAY ARRAY['public.point_seance_lire(uuid)', 'public.point_seance_envoyer(uuid,jsonb,text)',
                           'public.points_seance_a_faire()', 'public.historique_seances_eleve(uuid,int)'] LOOP
    IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'POINT-DE-SEANCE : droits inattendus sur %', f;
    END IF;
  END LOOP;
  FOREACH f IN ARRAY ARRAY['private.point_seance_etat(uuid,boolean)', 'private.point_seance_tirer(uuid)',
                           'private.point_seance_presents(uuid)', 'private.point_seance_tenue(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'POINT-DE-SEANCE : fonction privee ouverte : %', f;
    END IF;
  END LOOP;
END
$postflight$;

COMMIT;
