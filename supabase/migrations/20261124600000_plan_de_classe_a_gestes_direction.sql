-- PLAN-DE-CLASSE, partie A (lot 5 de la charte, 13/11/2026) : ce qui manque a la
-- direction pour se servir du socle du programme (migration 20261123900000).
-- Additive : aucune suppression, aucune migration existante modifiee.
--
--   1. donner_niveau_classe : une etape du programme publie pour une classe deja
--      ouverte ; les membres sans etape la recoivent par le mecanisme du lot 1
--      (private.poser_etape_eleve), jamais en double ni remplacee.
--   2. dater_entree_etape / decider_placement_depuis : un eleve deja en cours a
--      commence a une date passee (jamais future, jamais sous un plancher reglable).
--   3. eleves_sans_etape / rattacher_eleves_et_classes : qui n'a pas d'etape et
--      pourquoi, et le geste de rattachement du lot 1 pour la direction.
--   4. etat_publication_brouillon / repartir_des_bases_programme : dire pourquoi un
--      brouillon ne se publie pas (le serveur essaie, puis annule) et repartir des
--      bases d'un seul geste.
-- Toutes reservees a la direction, SECURITY DEFINER a search_path vide, rien pour
-- anon ni PUBLIC, chaque ecriture tracee au journal.

-- Preflight : ce que cette migration utilise vraiment doit exister, tout vient du
-- lot 1 (20261123900000, socle du programme). 20261123850000 et 20261123905000
-- ne sont pas utilisees ici (elles se posent avant, dans l'ordre du lot 1).
DO $preflight$
BEGIN
  IF to_regprocedure('private.rattacher_classes_et_eleves()') IS NULL
     OR to_regprocedure('private.poser_etape_eleve(uuid, uuid, timestamptz)') IS NULL
     OR to_regprocedure('private.dates_etape(uuid)') IS NULL
     OR to_regprocedure('private.cohorte_effective(uuid, uuid)') IS NULL
     OR to_regprocedure('private.contenu_bases()') IS NULL
     OR to_regprocedure('private.durees_niveau_bases()') IS NULL
     OR to_regprocedure('public.preremplir_bases_programme(uuid)') IS NULL
     OR to_regclass('public.eleve_etape_en_cours') IS NULL
     OR to_regclass('public.programme_cycles') IS NULL THEN
    RAISE EXCEPTION 'PLAN-DE-CLASSE A : installez d''abord 20261123900000 (lot 1, socle du programme) : il manque ce que cette migration utilise';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 0. Un seul endroit pour fixer la date d'entree dans l'etape
-- ---------------------------------------------------------------------------
-- Le jour de reference de l'academie : le jour de La Mecque (decision de
-- l'architecte, 13/11). UN seul endroit nomme, facile a rebrancher sur la
-- fonction de jour du lot 2 quand elle sera dans main.
CREATE OR REPLACE FUNCTION private.jour_academie()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date;
$function$;

-- Le plus ancien jour de debut accepte : un reglage (valeur reglable, defaut dix
-- ans avant aujourd'hui). L'academie enseignait avant l'application : un eleve
-- deja en cours a presque toujours commence AVANT la creation de son compte.
INSERT INTO public.app_config (key, value)
VALUES ('programme.date_debut_plancher_annees', pg_catalog.to_jsonb(10))
ON CONFLICT (key) DO NOTHING;

-- Lecture SURE du reglage : un entier de 1 a 50, sinon dix ans. Jamais d'erreur
-- brute : 0, negatif, texte, decimal, booleen, enorme ou nul donnent dix ans.
CREATE OR REPLACE FUNCTION private.plancher_date_debut()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (private.jour_academie()
          - pg_catalog.make_interval(years => coalesce(
              (SELECT CASE
                        WHEN pg_catalog.jsonb_typeof(c.value) = 'number'
                         AND (c.value #>> '{}')::numeric BETWEEN 1 AND 50
                         AND (c.value #>> '{}')::numeric = pg_catalog.trunc((c.value #>> '{}')::numeric)
                        THEN (c.value #>> '{}')::int
                      END
                 FROM public.app_config c
                WHERE c.key = 'programme.date_debut_plancher_annees'), 10)))::date;
$function$;

-- Un eleve que la direction peut placer : un eleve, ou un adulte titulaire qui
-- est lui-meme eleve autonome (role « guardian », sa propre fiche d'eleve : la
-- marque du schema est student_profiles.titulaire_profile_id = son id, type
-- autonome). Jamais un tuteur qui n'est pas eleve, jamais un compte supprime.
CREATE OR REPLACE FUNCTION private.eleve_placable(p_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = p_id
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.role = 'student'
            OR (p.role = 'guardian'
                AND EXISTS (SELECT 1 FROM public.student_profiles sp
                             WHERE sp.profile_id = p.id
                               AND sp.titulaire_profile_id = p.id
                               AND sp.student_type = 'autonomous'))));
$function$;

-- Bornes : jamais dans le futur (jour de La Mecque), jamais sous le plancher
-- reglable. Aucune reference a la date d'inscription du compte. Une date reposee
-- REMPLACE celle qu'on avait posee. L'entree dans le niveau n'est pas collante :
-- quand elle coincide avec l'entree dans l'etape (l'eleve est entre dans le niveau
-- par cette etape), elle suit la nouvelle date ; sinon (il y est monte d'une etape
-- precedente) elle reste, abaissee seulement si la nouvelle date la precede.
-- recul_jours (lot 2) est conserve tel quel. Rend l'ancienne date d'entree.
CREATE OR REPLACE FUNCTION private.fixer_entree_etape(p_student_id uuid, p_date date)
RETURNS date
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  f public.eleve_etape_en_cours%ROWTYPE;
  v_plancher date := private.plancher_date_debut();
BEGIN
  IF p_date IS NULL THEN
    RAISE EXCEPTION 'date_obligatoire' USING errcode = 'P0001';
  END IF;
  IF p_date > private.jour_academie() THEN
    RAISE EXCEPTION 'date_future' USING errcode = 'P0001',
      hint = 'Un eleve ne peut pas avoir commence apres aujourd''hui.';
  END IF;
  IF p_date < v_plancher THEN
    RAISE EXCEPTION 'date_sous_plancher: %', v_plancher USING errcode = 'P0001',
      hint = 'Ce jour est plus ancien que le plus ancien jour accepte (reglage programme.date_debut_plancher_annees).';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = p_student_id AND p.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'eleve_introuvable' USING errcode = 'P0001';
  END IF;
  SELECT * INTO f FROM public.eleve_etape_en_cours WHERE student_id = p_student_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'eleve_sans_etape' USING errcode = 'P0001',
      hint = 'Placez d''abord l''eleve a une etape.';
  END IF;
  UPDATE public.eleve_etape_en_cours
     SET entree_etape_le = p_date,
         entree_niveau_le = CASE WHEN f.entree_niveau_le = f.entree_etape_le
                                 THEN p_date
                                 ELSE least(f.entree_niveau_le, p_date) END,
         maj_le = pg_catalog.now()
   WHERE student_id = p_student_id;
  RETURN f.entree_etape_le;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 1. Donner une etape a une classe deja ouverte
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.donner_niveau_classe(p_groupe_id uuid, p_niveau_id uuid, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ancien uuid;
  v_ended timestamptz;
  v_statut text;
  v_cycle text;
  m record;
  v_places integer := 0;
  v_attente integer := 0;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  IF coalesce(pg_catalog.btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'motif_obligatoire' USING errcode = 'P0001';
  END IF;
  SELECT g.programme_niveau_id, g.ended_at INTO v_ancien, v_ended
    FROM public.groupes g WHERE g.id = p_groupe_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe_introuvable' USING errcode = 'P0001';
  END IF;
  IF v_ended IS NOT NULL THEN
    RAISE EXCEPTION 'classe_close' USING errcode = 'P0001';
  END IF;
  SELECT v.statut, n.cycle_code INTO v_statut, v_cycle
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id
   WHERE n.id = p_niveau_id;
  IF v_statut IS DISTINCT FROM 'publiee' OR v_cycle IS NULL THEN
    RAISE EXCEPTION 'niveau_non_publie' USING errcode = 'P0001',
      hint = 'Choisissez une etape de la version publiee du programme.';
  END IF;

  UPDATE public.groupes SET programme_niveau_id = p_niveau_id WHERE id = p_groupe_id;

  -- Les membres sans etape la recoivent par le mecanisme du lot 1 : un debutant
  -- entre a l'etape 1 (jamais « l'etape de la classe »), un eleve qui declare
  -- deja lire attend l'entretien ; un eleve qui a deja son etape n'est pas touche.
  FOR m IN
    SELECT gm.student_id FROM public.groupe_membres gm
     WHERE gm.groupe_id = p_groupe_id AND gm.left_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f WHERE f.student_id = gm.student_id)
  LOOP
    PERFORM private.poser_etape_eleve(m.student_id, p_groupe_id, pg_catalog.now());
    IF EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f WHERE f.student_id = m.student_id) THEN
      v_places := v_places + 1;
    ELSE
      v_attente := v_attente + 1;
    END IF;
  END LOOP;

  PERFORM public.log_sensitive_access(
    'classe_niveau_donne', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('ancien_niveau_id', v_ancien, 'niveau_id', p_niveau_id,
                                  'motif', p_motif, 'eleves_places', v_places,
                                  'eleves_en_attente', v_attente));
  RETURN pg_catalog.jsonb_build_object('eleves_places', v_places, 'eleves_en_attente', v_attente);
END;
$function$;

-- L'etape d'une classe et l'etat de ses membres, pour la fiche de la classe.
CREATE OR REPLACE FUNCTION public.niveau_classe_direction(p_groupe_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_niveau uuid;
  r jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  SELECT g.programme_niveau_id INTO v_niveau FROM public.groupes g WHERE g.id = p_groupe_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT pg_catalog.jsonb_build_object(
           'niveau_id', v_niveau,
           'etape_nom', (SELECT n.nom_humain FROM public.programme_niveaux n WHERE n.id = v_niveau),
           'etape_ordre', (SELECT n.ordre FROM public.programme_niveaux n WHERE n.id = v_niveau),
           'version_numero', (SELECT v.numero_version FROM public.programme_niveaux n
                                JOIN public.programme_versions v ON v.id = n.version_id
                               WHERE n.id = v_niveau),
           'programme_publie', EXISTS (SELECT 1 FROM public.programme_versions v WHERE v.statut = 'publiee'),
           'membres', (SELECT pg_catalog.count(*) FROM public.groupe_membres gm
                        WHERE gm.groupe_id = p_groupe_id AND gm.left_at IS NULL),
           'membres_sans_etape', (SELECT pg_catalog.count(*) FROM public.groupe_membres gm
                                   WHERE gm.groupe_id = p_groupe_id AND gm.left_at IS NULL
                                     AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f
                                                      WHERE f.student_id = gm.student_id)))
    INTO r;
  RETURN r;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Un eleve deja en cours a commence a une date passee
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.dater_entree_etape(p_student_id uuid, p_date date, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ancienne date;
  v_limite date;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  IF coalesce(pg_catalog.btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'motif_obligatoire' USING errcode = 'P0001';
  END IF;
  v_ancienne := private.fixer_entree_etape(p_student_id, p_date);
  SELECT d.date_limite INTO v_limite FROM private.dates_etape(p_student_id) d;
  PERFORM public.log_sensitive_access(
    'entree_etape_datee', 'eleve_etape_en_cours', p_student_id::text,
    pg_catalog.jsonb_build_object('ancienne_entree', v_ancienne, 'nouvelle_entree', p_date,
                                  'motif', p_motif));
  RETURN pg_catalog.jsonb_build_object('entree_etape_le', p_date, 'date_limite', v_limite);
END;
$function$;

-- Le placement du diagnostic, avec la date a laquelle l'eleve a vraiment commence.
-- Memes refus et meme trace que decider_placement (main, 0021, laisse intacte :
-- elle n'accepte que le role « student »), plus un cas : l'adulte titulaire qui
-- est lui-meme eleve autonome (private.eleve_placable). Le code place d'abord
-- (le declencheur du lot 1 pose l'etape), puis date, dans la meme transaction :
-- une date refusee annule tout, aucun placement a moitie.
CREATE OR REPLACE FUNCTION public.decider_placement_depuis(
  p_student_id uuid, p_niveau_id uuid, p_motif text, p_depuis date)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_ancienne date;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  IF coalesce(pg_catalog.btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'un motif est requis pour decider un placement';
  END IF;
  IF NOT private.eleve_placable(p_student_id) THEN
    RAISE EXCEPTION 'cet eleve n''existe pas ou son compte n''est pas valide';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.programme_niveaux WHERE id = p_niveau_id) THEN
    RAISE EXCEPTION 'ce niveau de programme n''existe pas';
  END IF;
  IF EXISTS (SELECT 1 FROM public.progression_historique WHERE student_id = p_student_id) THEN
    RAISE EXCEPTION 'cet eleve a deja un niveau decide : passez par Progression pour le modifier';
  END IF;
  INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
  VALUES (p_student_id, p_niveau_id, 'diagnostic_initial', auth.uid(), p_motif)
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access(
    'placement_decide', 'progression_historique', v_id::text,
    pg_catalog.jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'motif', p_motif));
  IF p_depuis IS NOT NULL THEN
    v_ancienne := private.fixer_entree_etape(p_student_id, p_depuis);
    PERFORM public.log_sensitive_access(
      'entree_etape_datee', 'eleve_etape_en_cours', p_student_id::text,
      pg_catalog.jsonb_build_object('ancienne_entree', v_ancienne, 'nouvelle_entree', p_depuis,
                                    'motif', p_motif, 'avec_placement', v_id));
  END IF;
  RETURN v_id;
END;
$function$;

-- Ce que donnerait un jour de debut, AVANT de confirmer : la date limite de
-- l'etape qui en resulte, calculee par le serveur (le client ne la recalcule
-- pas), et si elle est deja passee. Lecture seule. [p_niveau_id] nul : l'etape en
-- cours de l'eleve (datation) ; donne : l'etape du placement a decider.
CREATE OR REPLACE FUNCTION public.apercu_date_limite(
  p_student_id uuid, p_date date, p_niveau_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  f public.eleve_etape_en_cours%ROWTYPE;
  v_niveau uuid;
  v_coh text;
  v_sem int;
  v_limite date;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  SELECT * INTO f FROM public.eleve_etape_en_cours WHERE student_id = p_student_id;
  v_niveau := coalesce(p_niveau_id, f.niveau_id);
  IF v_niveau IS NULL OR p_date IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('date_limite', NULL, 'semaines', NULL, 'deja_passee', false);
  END IF;
  v_coh := coalesce(f.cohorte, private.cohorte_effective(p_student_id,
             (SELECT gm.groupe_id FROM public.groupe_membres gm
               WHERE gm.student_id = p_student_id AND gm.left_at IS NULL LIMIT 1)));
  SELECT (n.durees -> v_coh ->> 'limite')::int INTO v_sem
    FROM public.programme_niveaux n WHERE n.id = v_niveau;
  IF v_sem IS NOT NULL THEN
    v_limite := ((p_date + coalesce(f.recul_jours, 0)) + pg_catalog.make_interval(weeks => v_sem))::date;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'date_limite', v_limite, 'semaines', v_sem,
    'deja_passee', v_limite IS NOT NULL AND v_limite < private.jour_academie());
END;
$function$;

-- Le jour de reference de l'academie (La Mecque), rendu par le serveur : le
-- calendrier de la direction borne sur CE jour, jamais sur celui de l'appareil.
CREATE OR REPLACE FUNCTION public.jour_academie_direction()
RETURNS date
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  RETURN private.jour_academie();
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Qui n'a pas d'etape, et pourquoi ; le rattachement
-- ---------------------------------------------------------------------------
-- raison : aucun_programme (rien de publie), attente_entretien (declare deja lire :
-- la direction decide son etape), debutant_a_rattacher (debutant : le
-- rattachement lui donne l'etape 1).
CREATE OR REPLACE FUNCTION public.eleves_sans_etape()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_publie boolean := EXISTS (SELECT 1 FROM public.programme_versions v WHERE v.statut = 'publiee');
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  v_masque := coalesce(public.agent_identite_masquee(), false);
  RETURN pg_catalog.jsonb_build_object(
    'programme_publie', v_publie,
    'classes_sans_niveau', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'groupe_id', g.id, 'nom', g.libelle,
               'membres', (SELECT pg_catalog.count(*) FROM public.groupe_membres gm
                            WHERE gm.groupe_id = g.id AND gm.left_at IS NULL))
             ORDER BY g.libelle, g.id)
        FROM public.groupes g
       WHERE g.ended_at IS NULL AND g.programme_niveau_id IS NULL), '[]'::jsonb),
    'eleves', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'student_id', x.student_id,
               'identifiant', x.immutable_id,
               'prenom', CASE WHEN v_masque THEN NULL ELSE x.first_name END,
               'nom', CASE WHEN v_masque THEN NULL ELSE x.last_name END,
               'groupe_id', x.groupe_id, 'classe', x.libelle,
               'raison', CASE
                           WHEN NOT v_publie THEN 'aucun_programme'
                           WHEN x.niveau_declare IS NULL
                                OR x.niveau_declare IN ('debut_lettres', 'lettres_avec_aide')
                             THEN 'debutant_a_rattacher'
                           ELSE 'attente_entretien' END,
               'inscrit_le', x.created_at)
             ORDER BY x.created_at, x.student_id)
        FROM (
          SELECT DISTINCT ON (gm.student_id)
                 gm.student_id, gm.groupe_id, g.libelle, p.immutable_id, p.first_name,
                 p.last_name, p.created_at, sp.niveau_declare
            FROM public.groupe_membres gm
            JOIN public.groupes g ON g.id = gm.groupe_id AND g.ended_at IS NULL
            JOIN public.profiles p ON p.id = gm.student_id AND p.deleted_at IS NULL
            LEFT JOIN public.student_profiles sp ON sp.profile_id = gm.student_id
           WHERE gm.left_at IS NULL
             AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f WHERE f.student_id = gm.student_id)
           ORDER BY gm.student_id, gm.joined_at DESC
        ) x), '[]'::jsonb));
END;
$function$;

-- Le rattachement du lot 1 (private.rattacher_classes_et_eleves), tel quel :
-- etape 1 des bases pour chaque classe ouverte sans etape, et pour chaque
-- debutant membre sans etape, datee du jour. Un eleve qui declare deja lire
-- n'est pas touche : il attend la decision de la direction.
CREATE OR REPLACE FUNCTION public.rattacher_eleves_et_classes()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_classes integer;
  v_eleves integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.programme_versions v WHERE v.statut = 'publiee') THEN
    RAISE EXCEPTION 'aucun_programme_publie' USING errcode = 'P0001',
      hint = 'Publiez d''abord une version du programme.';
  END IF;
  SELECT pg_catalog.count(*) INTO v_classes FROM public.groupes
   WHERE ended_at IS NULL AND programme_niveau_id IS NULL;
  v_eleves := private.rattacher_classes_et_eleves();
  PERFORM public.log_sensitive_access(
    'programme_rattachement', 'groupes', 'toutes',
    pg_catalog.jsonb_build_object('classes', v_classes, 'eleves', v_eleves));
  RETURN pg_catalog.jsonb_build_object('classes', v_classes, 'eleves', v_eleves);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. L'impasse du brouillon
-- ---------------------------------------------------------------------------
-- Le serveur essaie de publier le brouillon dans une sous-transaction, relit le
-- refus des controles de publication, puis ANNULE tout : aucune regle recopiee,
-- aucun effet. Rend {peut_publier, raison, detail} ; raison : incomplet,
-- incoherent, sans_bases, non_brouillon, introuvable, autre.
CREATE OR REPLACE FUNCTION public.etat_publication_brouillon(p_version_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_statut text;
  v_msg text;
  v_raison text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  SELECT statut INTO v_statut FROM public.programme_versions WHERE id = p_version_id;
  IF v_statut IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('peut_publier', false, 'raison', 'introuvable');
  END IF;
  IF v_statut <> 'brouillon' THEN
    RETURN pg_catalog.jsonb_build_object('peut_publier', false, 'raison', 'non_brouillon');
  END IF;
  BEGIN
    UPDATE public.programme_versions
       SET statut = 'publiee', publiee_at = pg_catalog.now(), publiee_par = auth.uid()
     WHERE id = p_version_id;
    RAISE EXCEPTION 'essai_annule' USING errcode = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    v_msg := SQLERRM;
  END;
  IF v_msg = 'essai_annule' THEN
    RETURN pg_catalog.jsonb_build_object('peut_publier', true);
  END IF;
  v_raison := CASE
    WHEN v_msg LIKE 'programme_incomplet:%' THEN 'incomplet'
    WHEN v_msg LIKE 'programme_incoherent:%' THEN 'incoherent'
    WHEN v_msg LIKE 'programme_sans_bases%' THEN 'sans_bases'
    ELSE 'autre' END;
  RETURN pg_catalog.jsonb_build_object(
    'peut_publier', false, 'raison', v_raison,
    'detail', CASE WHEN v_msg LIKE '%: %'
                   THEN pg_catalog.substr(v_msg, pg_catalog.strpos(v_msg, ': ') + 2) END);
END;
$function$;

-- Un brouillon « des bases » jamais modifie : exactement les quatre etapes et le
-- niveau que remplir_version_bases ecrit, rien de plus, rien de change.
CREATE OR REPLACE FUNCTION private.version_bases_intacte(p_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (SELECT pg_catalog.count(*) FROM public.programme_niveaux n WHERE n.version_id = p_version_id)
           = (SELECT pg_catalog.count(*) FROM private.contenu_bases())
     AND NOT EXISTS (
       SELECT 1 FROM private.contenu_bases() c
         LEFT JOIN public.programme_niveaux n
           ON n.version_id = p_version_id AND n.code_technique = c.code
        WHERE n.id IS NULL
           OR (n.nom_humain, n.cycle, n.cycle_code, n.ordre, n.description, n.objectifs,
               n.plage_support, n.durees, n.matieres)
              IS DISTINCT FROM
              (c.nom, 'Les bases', 'bases', c.ordre, c.description, c.objectifs,
               c.plage, c.durees, c.matieres))
     AND EXISTS (
       SELECT 1 FROM public.programme_cycles cy
        WHERE cy.version_id = p_version_id AND cy.code = 'bases'
          AND cy.durees = private.durees_niveau_bases());
$function$;

-- Repartir des bases d'un geste : une version neuve et VIDE (meme quand un
-- brouillon rempli a la main existe : il n'est ni modifie ni efface), remplie du
-- contenu decide des bases. Ne publie rien. Idempotent : si un brouillon « des
-- bases » jamais modifie existe deja, il est rendu au lieu d'en creer un autre.
CREATE OR REPLACE FUNCTION public.repartir_des_bases_programme()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING errcode = '42501';
  END IF;
  SELECT v.id INTO v_id
    FROM public.programme_versions v
   WHERE v.statut = 'brouillon' AND private.version_bases_intacte(v.id)
   ORDER BY v.numero_version DESC
   LIMIT 1;
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;
  v_id := public.creer_version_programme(NULL);
  PERFORM public.preremplir_bases_programme(v_id);
  RETURN v_id;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.fixer_entree_etape(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.jour_academie() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_placable(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.version_bases_intacte(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.plancher_date_debut() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.donner_niveau_classe(uuid, uuid, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.niveau_classe_direction(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.dater_entree_etape(uuid, date, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.decider_placement_depuis(uuid, uuid, text, date) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.eleves_sans_etape() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.rattacher_eleves_et_classes() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.etat_publication_brouillon(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.apercu_date_limite(uuid, date, uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.jour_academie_direction() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.repartir_des_bases_programme() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.donner_niveau_classe(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.niveau_classe_direction(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.dater_entree_etape(uuid, date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decider_placement_depuis(uuid, uuid, text, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.eleves_sans_etape() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rattacher_eleves_et_classes() TO authenticated;
GRANT EXECUTE ON FUNCTION public.etat_publication_brouillon(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apercu_date_limite(uuid, date, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jour_academie_direction() TO authenticated;
GRANT EXECUTE ON FUNCTION public.repartir_des_bases_programme() TO authenticated;
