-- CALENDRIER-ET-PAUSES (lot 2 de la charte, 12/11/2026). Migration 20261123910000.
-- Plan : docs/current/pedagogie/PLAN-DE-CONSTRUCTION.md, « Lot 2 » ;
-- valeurs : REGLAGES.md partie 2 ; fiche : docs/current/pedagogie/lots/LOT-2-CALENDRIER-ET-PAUSES.md.
--
-- Ce que fait ce fichier (additif ; AUCUN mot d'effacement) :
--   1. calendrier_ecole : fermetures, rencontres de recitation, dates d'evaluation,
--      autres dates ; saisies par la direction, jamais calculees ;
--   2. pauses_eleve : pause d'un mois (mois civil entier) et pause d'exception ;
--   3. private.recul_jours_calcule : LE SEUL endroit ou le recul de la date limite
--      est calcule (fermetures + pauses, sans double compte) ; il alimente
--      eleve_etape_en_cours.recul_jours, point d'accroche du lot 1, lu par
--      private.dates_etape (inchangee) ;
--   4. les gestes serveur de la direction, du tuteur et de l'eleve adulte ;
--   5. la generation des seances ne cree plus de seance un jour de fermeture
--      publiee (aucune seance existante n'est touchee) ;
--   6. les lectures propres « en pause » et « jour ferme » pour le moteur (lot 7).
--
-- Ce que ce fichier ne fait PAS : aucun argent (facturation, remboursement, prix,
-- mois non facture : reserve du directeur, A-HARMONISER-REGLES-ARGENT-ET-ARRET.md) ;
-- aucune annonce (lot 7). La notification de la reponse de la direction a une
-- demande de pause exige l'evenement « pause_repondue » : il entre dans la
-- contrainte des notifications par le fichier SEPARE 20261123911000 (il contient
-- le seul mot d'effacement du lot, que le directeur colle dans l'editeur SQL).
-- Sans lui, la decision est enregistree et la notification est simplement omise
-- (journal d'avertissement).
--
-- Depend du lot 1 (20261123900000) : eleve_etape_en_cours, private.dates_etape,
-- private.cohorte_effective, etape_eleve_lecture.
-- ---------------------------------------------------------------------------
-- 0. Preflight : le lot 1 est installe
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.eleve_etape_en_cours') IS NULL
     OR pg_catalog.to_regprocedure('private.dates_etape(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cohorte_effective(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.etape_eleve_lecture(uuid)') IS NULL THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : installer d''abord 20261123900000_socle_programme.sql (lot 1)';
  END IF;
  IF pg_catalog.to_regclass('public.calendrier_ecole') IS NOT NULL
     OR pg_catalog.to_regclass('public.pauses_eleve') IS NOT NULL THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les reglages (REGLAGES.md, partie 2) : app_config, jamais des constantes
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  -- Pause : demandee au moins 7 jours avant le debut du mois (DECIDE 30/09).
  ('pause.preavis_jours', pg_catalog.to_jsonb(7)),
  -- Au plus 2 mois de pause sur 12 mois glissants sans accord particulier (ARBITRE).
  ('pause.max_mois_fenetre', pg_catalog.to_jsonb(2)),
  ('pause.fenetre_mois', pg_catalog.to_jsonb(12)),
  -- La direction repond sous 3 jours (ARBITRE).
  ('pause.delai_reponse_jours', pg_catalog.to_jsonb(3)),
  -- Fermeture du Ramadan : 20 jours au plus (DECIDE 30/09).
  ('calendrier.ramadan_jours_max', pg_catalog.to_jsonb(20)),
  -- Fermeture de l'Aid al-Adha : du 9 au 18 Dhu al-Hijja inclus = 10 jours (DECIDE 30/09).
  ('calendrier.aid_adha_jours_max', pg_catalog.to_jsonb(10))
ON CONFLICT (key) DO NOTHING;

-- Les bornes de ces reglages (la direction les change dans app_config).
CREATE FUNCTION private.calendrier_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  IF NEW.key NOT IN ('pause.preavis_jours', 'pause.max_mois_fenetre', 'pause.fenetre_mois',
                     'pause.delai_reponse_jours', 'calendrier.ramadan_jours_max',
                     'calendrier.aid_adha_jours_max') THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
     OR (NEW.value #>> '{}') !~ '^[0-9]{1,3}$' THEN
    RAISE EXCEPTION 'reglage % : un nombre entier est attendu', NEW.key USING errcode = '22023';
  END IF;
  v_n := (NEW.value #>> '{}')::integer;
  IF NOT (CASE NEW.key
            WHEN 'pause.preavis_jours' THEN v_n BETWEEN 0 AND 60
            WHEN 'pause.max_mois_fenetre' THEN v_n BETWEEN 0 AND 12
            WHEN 'pause.fenetre_mois' THEN v_n BETWEEN 1 AND 24
            WHEN 'pause.delai_reponse_jours' THEN v_n BETWEEN 1 AND 30
            WHEN 'calendrier.ramadan_jours_max' THEN v_n BETWEEN 1 AND 40
            WHEN 'calendrier.aid_adha_jours_max' THEN v_n BETWEEN 1 AND 20
          END) THEN
    RAISE EXCEPTION 'reglage % : valeur hors bornes', NEW.key USING errcode = '22023';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_calendrier_pauses
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_reglages_valider();

-- ---------------------------------------------------------------------------
-- 2. Le calendrier de l'ecole
-- ---------------------------------------------------------------------------
CREATE TABLE public.calendrier_ecole (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('fermeture', 'rencontre', 'evaluation', 'autre')),
  -- Une fermeture porte sa categorie : le Ramadan et l'Aid ont chacun leur maximum.
  categorie text CHECK (categorie IN ('ramadan', 'aid_al_adha', 'autre')),
  titre text NOT NULL CHECK (pg_catalog.btrim(titre) <> '' AND pg_catalog.length(titre) <= 120),
  du date NOT NULL,
  au date NOT NULL,
  portee text NOT NULL DEFAULT 'ecole' CHECK (portee IN ('ecole', 'tranche', 'classe')),
  cohorte text REFERENCES public.cohortes_age(code),
  groupe_id uuid REFERENCES public.groupes(id),
  publie boolean NOT NULL DEFAULT false,
  publie_le timestamptz,
  cree_par uuid,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  maj_par uuid,
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT calendrier_ecole_dates CHECK (au >= du AND au - du <= 365),
  CONSTRAINT calendrier_ecole_portee_coherente CHECK (
       (portee = 'ecole' AND cohorte IS NULL AND groupe_id IS NULL)
    OR (portee = 'tranche' AND cohorte IS NOT NULL AND groupe_id IS NULL)
    OR (portee = 'classe' AND groupe_id IS NOT NULL AND cohorte IS NULL)),
  CONSTRAINT calendrier_ecole_categorie_coherente CHECK (
       (type = 'fermeture' AND categorie IS NOT NULL)
    OR (type <> 'fermeture' AND categorie IS NULL))
);

COMMENT ON TABLE public.calendrier_ecole IS
  'CALENDRIER-ET-PAUSES (12/11/2026) : l''annee de l''ecole, saisie par la direction, jamais calculee '
  '(l''application ne calcule pas le calendrier lunaire). Type : fermeture, rencontre de recitation, '
  'date d''evaluation, autre. Portee : toute l''ecole, une tranche d''age, une classe. Seules les '
  'lignes publiees agissent et se lisent. Aucune ecriture directe (fonctions calendrier_ecole_*).';

CREATE INDEX calendrier_ecole_publie_idx ON public.calendrier_ecole (au) WHERE publie;

ALTER TABLE public.calendrier_ecole ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.calendrier_ecole FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.calendrier_ecole TO authenticated;
CREATE POLICY calendrier_ecole_direction ON public.calendrier_ecole
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- Une fermeture du Ramadan ou de l'Aid ne depasse pas son maximum (reglage).
CREATE FUNCTION private.calendrier_ecole_valider()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_max integer;
BEGIN
  NEW.maj_le := pg_catalog.now();
  IF NEW.type = 'fermeture' AND NEW.categorie IN ('ramadan', 'aid_al_adha') THEN
    v_max := public.app_config_int(
      CASE NEW.categorie WHEN 'ramadan' THEN 'calendrier.ramadan_jours_max'
                         ELSE 'calendrier.aid_adha_jours_max' END,
      CASE NEW.categorie WHEN 'ramadan' THEN 20 ELSE 10 END);
    IF (NEW.au - NEW.du + 1) > v_max THEN
      RAISE EXCEPTION 'calendrier_fermeture_trop_longue' USING errcode = '22023',
        detail = pg_catalog.format('%s jours au plus', v_max);
    END IF;
  END IF;
  IF NEW.publie AND NEW.publie_le IS NULL THEN
    NEW.publie_le := pg_catalog.now();
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER calendrier_ecole_valider
  BEFORE INSERT OR UPDATE ON public.calendrier_ecole
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_ecole_valider();

-- ---------------------------------------------------------------------------
-- 3. Les pauses d'un eleve
-- ---------------------------------------------------------------------------
-- Sans cle etrangere vers profiles, a dessein (comme eleve_etape_en_cours) : un
-- compte efface par le service d'authentification ne doit jamais etre bloque.
CREATE TABLE public.pauses_eleve (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  type text NOT NULL CHECK (type IN ('mois', 'exception')),
  debut date NOT NULL,
  fin date NOT NULL,
  statut text NOT NULL CHECK (statut IN ('demandee', 'acceptee', 'refusee', 'annulee')),
  -- Qui a accepte : le systeme (dans la regle) ou la direction (au-dela, ou exception).
  acceptation text CHECK (acceptation IN ('automatique', 'direction')),
  -- Motif de l'exception (maladie soudaine, interruption accordee) ; nul pour un mois.
  motif text CHECK (motif IS NULL OR pg_catalog.length(pg_catalog.btrim(motif)) BETWEEN 3 AND 500),
  motif_decision text CHECK (motif_decision IS NULL OR pg_catalog.length(pg_catalog.btrim(motif_decision)) BETWEEN 3 AND 500),
  demandee_par uuid,
  demandee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  repondre_avant date,
  decidee_par uuid,
  decidee_par_nom text,
  decidee_le timestamptz,
  CONSTRAINT pauses_eleve_dates CHECK (fin >= debut AND fin - debut <= 365),
  CONSTRAINT pauses_eleve_mois_entier CHECK (
    type <> 'mois'
    OR (debut = pg_catalog.date_trunc('month', (debut)::timestamp)::date
        AND fin = (pg_catalog.date_trunc('month', (debut)::timestamp) + interval '1 month - 1 day')::date)),
  CONSTRAINT pauses_eleve_exception_motivee CHECK (
    type <> 'exception'
    OR (motif IS NOT NULL AND statut IN ('acceptee', 'annulee')
        AND decidee_par IS NOT NULL AND decidee_par_nom IS NOT NULL AND acceptation = 'direction')),
  CONSTRAINT pauses_eleve_acceptation_coherente CHECK (
    (statut = 'acceptee') = (acceptation IS NOT NULL) OR statut IN ('annulee'))
);

COMMENT ON TABLE public.pauses_eleve IS
  'CALENDRIER-ET-PAUSES (12/11/2026) : pause d''un mois (mois civil entier, demandee au moins 7 jours '
  'avant, 2 mois sur 12 mois glissants sans accord particulier) et pause d''exception (maladie soudaine, '
  'interruption temporaire accordee : motif, date de fin, nom de la direction). Pedagogie seulement : la '
  'date limite de l''etape recule de la duree de la pause ; la place est gardee. Rien d''argent. '
  'pause_seances est la pause de 5 minutes pendant une seance : sans rapport. '
  'Aucune ecriture directe (fonctions pause_*).';

-- Un seul mois de pause (demandee ou acceptee) par eleve et par mois.
CREATE UNIQUE INDEX pauses_eleve_un_mois_uniq ON public.pauses_eleve (student_id, debut)
  WHERE type = 'mois' AND statut IN ('demandee', 'acceptee');
CREATE INDEX pauses_eleve_eleve_idx ON public.pauses_eleve (student_id, debut DESC);
CREATE INDEX pauses_eleve_a_traiter_idx ON public.pauses_eleve (demandee_le) WHERE statut = 'demandee';

ALTER TABLE public.pauses_eleve ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pauses_eleve FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.pauses_eleve TO authenticated;
CREATE POLICY pauses_eleve_direction ON public.pauses_eleve
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- ---------------------------------------------------------------------------
-- 4. Les faits : jour ferme, en pause
-- ---------------------------------------------------------------------------
-- Une fermeture vise-t-elle cette classe ? Ecole : oui. Classe : la sienne.
-- Tranche : seulement si TOUS les membres actifs de la classe sont de cette
-- tranche (sinon la classe garde son cours : les autres eleves n'ont pas de
-- fermeture ; l'eleve de la tranche garde pourtant le recul de sa date limite).
CREATE FUNCTION private.fermeture_vise_classe(p_portee text, p_cohorte text, p_groupe_id uuid, p_classe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE p_portee
    WHEN 'ecole' THEN true
    WHEN 'classe' THEN p_groupe_id IS NOT DISTINCT FROM p_classe_id
    WHEN 'tranche' THEN
      EXISTS (SELECT 1 FROM public.groupe_membres m
               WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL)
      AND NOT EXISTS (SELECT 1 FROM public.groupe_membres m
                       LEFT JOIN public.student_profiles sp ON sp.profile_id = m.student_id
                      WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL
                        AND sp.cohorte IS DISTINCT FROM p_cohorte)
    ELSE false END;
$function$;

-- Le fait « jour ferme » pour une classe : une fermeture publiee couvre ce jour.
CREATE FUNCTION private.jour_ferme_pour_classe(p_jour date, p_classe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.type = 'fermeture'
       AND p_jour BETWEEN ce.du AND ce.au
       AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, p_classe_id));
$function$;

-- Le fait « en pause » a une date (pause acceptee seulement). Pour le moteur
-- (lot 7) : un eleve en pause n'est compte absent a aucune seance.
CREATE FUNCTION private.eleve_en_pause(p_student_id uuid, p_jour date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.pauses_eleve p
     WHERE p.student_id = p_student_id AND p.statut = 'acceptee'
       AND p_jour BETWEEN p.debut AND p.fin);
$function$;

-- Le fait « en pause tel mois » : le mois civil entier est couvert par des pauses
-- acceptees. Lecture seule ; aucune facturation n'y est branchee (reserve du
-- directeur, A-HARMONISER-REGLES-ARGENT-ET-ARRET.md).
CREATE FUNCTION private.eleve_en_pause_mois(p_student_id uuid, p_mois date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_mois IS NOT NULL AND NOT EXISTS (
    SELECT 1
      FROM pg_catalog.generate_series(0, (pg_catalog.date_trunc('month', (p_mois)::timestamp) + interval '1 month - 1 day')::date
                                         - pg_catalog.date_trunc('month', (p_mois)::timestamp)::date) g
     WHERE NOT private.eleve_en_pause(p_student_id, (pg_catalog.date_trunc('month', (p_mois)::timestamp)::date + g)));
$function$;

-- ---------------------------------------------------------------------------
-- 5. Le recul de la date limite : un seul endroit
-- ---------------------------------------------------------------------------
-- Jours fermes (fermetures publiees qui visent l'eleve) et jours de pause
-- (pauses acceptees), REUNIS en un seul ensemble de jours : une fermeture qui
-- tombe pendant une pause ne compte qu'une fois. Ne comptent que les jours de
-- l'etape en cours : de l'entree dans l'etape a la date limite, elle-meme
-- reculee (un point fixe : chaque jour ajoute peut en faire entrer un autre).
-- Sans durees (tranche inconnue), pas de date limite : recul nul.
CREATE FUNCTION private.recul_jours_calcule(p_student_id uuid, p_entree date, p_niveau_id uuid, p_cohorte text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_coh text;
  v_semaines integer;
  v_groupe uuid;
  v_r integer := 0;
  v_n integer;
BEGIN
  IF p_student_id IS NULL OR p_entree IS NULL OR p_niveau_id IS NULL THEN
    RETURN 0;
  END IF;
  v_coh := coalesce(p_cohorte, private.cohorte_effective(p_student_id, NULL));
  SELECT (n.durees -> v_coh ->> 'limite')::integer INTO v_semaines
    FROM public.programme_niveaux n WHERE n.id = p_niveau_id;
  IF v_coh IS NULL OR v_semaines IS NULL THEN
    RETURN 0;
  END IF;
  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
   WHERE m.student_id = p_student_id AND m.left_at IS NULL
   ORDER BY m.joined_at DESC, m.groupe_id
   LIMIT 1;

  FOR i IN 1 .. 400 LOOP
    SELECT pg_catalog.count(*)::integer INTO v_n
      FROM (
        SELECT (ce.du + g.n) AS d
          FROM public.calendrier_ecole ce
         CROSS JOIN LATERAL pg_catalog.generate_series(0, ce.au - ce.du) AS g(n)
         WHERE ce.publie AND ce.type = 'fermeture'
           AND (ce.portee = 'ecole'
                OR (ce.portee = 'tranche' AND ce.cohorte = v_coh)
                OR (ce.portee = 'classe' AND ce.groupe_id = v_groupe))
        UNION
        SELECT (p.debut + g.n) AS d
          FROM public.pauses_eleve p
         CROSS JOIN LATERAL pg_catalog.generate_series(0, p.fin - p.debut) AS g(n)
         WHERE p.student_id = p_student_id AND p.statut = 'acceptee'
      ) j
     WHERE j.d >= p_entree AND j.d <= p_entree + (v_semaines * 7 + v_r);
    EXIT WHEN v_n = v_r;
    v_r := v_n;
  END LOOP;
  RETURN v_r;
END;
$function$;

COMMENT ON FUNCTION private.recul_jours_calcule(uuid, date, uuid, text) IS
  'CALENDRIER-ET-PAUSES : LE calcul du recul de la date limite de l''etape (jours de fermeture publiee '
  'et de pause acceptee reunis sans double compte, de l''entree dans l''etape a sa date limite reculee). '
  'Seul appelant : le declencheur eleve_etape_en_cours_recul.';

-- recul_jours n'est plus une valeur saisie : le declencheur la derive a chaque
-- ecriture du fait (creation, changement d'etape, recalcul force).
CREATE FUNCTION private.eleve_etape_recul_deriver()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  NEW.recul_jours := private.recul_jours_calcule(NEW.student_id, NEW.entree_etape_le, NEW.niveau_id, NEW.cohorte);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER eleve_etape_en_cours_recul
  BEFORE INSERT OR UPDATE ON public.eleve_etape_en_cours
  FOR EACH ROW EXECUTE FUNCTION private.eleve_etape_recul_deriver();

-- Un recalcul force, pour les eleves vises (le declencheur ci-dessus derive la valeur).
CREATE FUNCTION private.recul_recalculer_cible(p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.eleve_etape_en_cours f
     SET recul_jours = f.recul_jours
   WHERE p_portee = 'ecole'
      OR (p_portee = 'tranche'
          AND coalesce(f.cohorte, private.cohorte_effective(f.student_id, NULL)) = p_cohorte)
      OR (p_portee = 'classe'
          AND EXISTS (SELECT 1 FROM public.groupe_membres m
                       WHERE m.groupe_id = p_groupe_id AND m.student_id = f.student_id AND m.left_at IS NULL));
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

CREATE FUNCTION private.calendrier_ecole_recalculer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.publie AND NEW.type = 'fermeture' THEN
      PERFORM private.recul_recalculer_cible(NEW.portee, NEW.cohorte, NEW.groupe_id);
    END IF;
  ELSE
    IF (OLD.publie AND OLD.type = 'fermeture') THEN
      PERFORM private.recul_recalculer_cible(OLD.portee, OLD.cohorte, OLD.groupe_id);
    END IF;
    IF (NEW.publie AND NEW.type = 'fermeture') THEN
      PERFORM private.recul_recalculer_cible(NEW.portee, NEW.cohorte, NEW.groupe_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER calendrier_ecole_recul
  AFTER INSERT OR UPDATE ON public.calendrier_ecole
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_ecole_recalculer();

CREATE FUNCTION private.pauses_eleve_recalculer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.eleve_etape_en_cours f
     SET recul_jours = f.recul_jours
   WHERE f.student_id = NEW.student_id;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER pauses_eleve_recul
  AFTER INSERT OR UPDATE ON public.pauses_eleve
  FOR EACH ROW EXECUTE FUNCTION private.pauses_eleve_recalculer();

-- Les eleves deja presents : leur recul est calcule des l'installation (nul tant
-- qu'aucune fermeture ni pause n'est publiee).
UPDATE public.eleve_etape_en_cours SET recul_jours = recul_jours;

-- ---------------------------------------------------------------------------
-- 6. La generation des seances respecte les fermetures (minimum sur)
-- ---------------------------------------------------------------------------
-- Une fermeture publiee : materialiser_seances_groupe ne CREE plus de seance ce
-- jour-la. Aucune seance existante n'est supprimee, annulee ni deplacee (leur
-- sort est une decision de la direction : voir la fiche du lot). Remplacement
-- exact, compte et idempotent, comme 20261030100000 ; si le texte de la fonction
-- a change, la migration s'arrete et le dit.
CREATE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, p_apres) > 0 THEN
    RETURN;  -- deja remplace (rejeu)
  END IF;
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

SELECT pg_temp.remplacer('public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure,
  $a$      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$a$,
  $b$      -- CALENDRIER-ET-PAUSES (12/11/2026) : aucune seance n'est creee un jour de
      -- fermeture publiee ; les seances deja creees ne sont pas touchees.
      IF private.jour_ferme_pour_classe((v_debut AT TIME ZONE v_g.timezone_iana)::date, p_groupe_id) THEN
        CONTINUE;
      END IF;

      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$b$, 1);

-- L'empreinte F86 de la fonction suit son nouveau corps.
DO $empreinte$
DECLARE
  v_f CONSTANT pg_catalog.regprocedure := 'public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure;
  v_com text := pg_catalog.obj_description(v_f, 'pg_proc');
BEGIN
  IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
      pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
  END IF;
END
$empreinte$;

-- ---------------------------------------------------------------------------
-- 7. La lecture unique de l'etape montre le recul (lot 1, ajout d'une cle)
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.etape_eleve_lecture(uuid)'::pg_catalog.regprocedure,
  $a$      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_dates.date_limite END,$a$,
  $b$      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_dates.date_limite END,
      'recul_jours', CASE WHEN v_masque THEN NULL ELSE f.recul_jours END,$b$, 1);

-- ---------------------------------------------------------------------------
-- 8. Le calendrier : gestes de la direction et lecture unique
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.calendrier_ecole_enregistrer(
  p_id uuid, p_type text, p_categorie text, p_titre text, p_du date, p_au date,
  p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_id uuid;
  v_categorie text;
  v_portee text := coalesce(p_portee, 'ecole');
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  IF p_type IS NULL OR p_type NOT IN ('fermeture', 'rencontre', 'evaluation', 'autre')
     OR p_titre IS NULL OR pg_catalog.btrim(p_titre) = '' OR pg_catalog.length(p_titre) > 120 THEN
    RAISE EXCEPTION 'calendrier_evenement_invalide' USING errcode = '22023';
  END IF;
  IF p_du IS NULL OR p_au IS NULL OR p_au < p_du OR p_au - p_du > 365 THEN
    RAISE EXCEPTION 'calendrier_dates_invalides' USING errcode = '22023';
  END IF;
  IF v_portee NOT IN ('ecole', 'tranche', 'classe')
     OR (v_portee = 'tranche' AND (p_cohorte IS NULL
         OR NOT EXISTS (SELECT 1 FROM public.cohortes_age a WHERE a.code = p_cohorte)))
     OR (v_portee = 'classe' AND (p_groupe_id IS NULL
         OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id))) THEN
    RAISE EXCEPTION 'calendrier_portee_invalide' USING errcode = '22023';
  END IF;
  v_categorie := CASE WHEN p_type = 'fermeture' THEN coalesce(p_categorie, 'autre') END;
  IF v_categorie IS NOT NULL AND v_categorie NOT IN ('ramadan', 'aid_al_adha', 'autre') THEN
    RAISE EXCEPTION 'calendrier_evenement_invalide' USING errcode = '22023';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.calendrier_ecole
      (type, categorie, titre, du, au, portee, cohorte, groupe_id, cree_par, maj_par)
    VALUES
      (p_type, v_categorie, pg_catalog.btrim(p_titre), p_du, p_au, v_portee,
       CASE WHEN v_portee = 'tranche' THEN p_cohorte END,
       CASE WHEN v_portee = 'classe' THEN p_groupe_id END, v_user, v_user)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.calendrier_ecole
       SET type = p_type, categorie = v_categorie, titre = pg_catalog.btrim(p_titre),
           du = p_du, au = p_au, portee = v_portee,
           cohorte = CASE WHEN v_portee = 'tranche' THEN p_cohorte END,
           groupe_id = CASE WHEN v_portee = 'classe' THEN p_groupe_id END,
           maj_par = v_user
     WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
    END IF;
  END IF;
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.calendrier_ecole_publier(p_id uuid, p_publie boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_id uuid;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  IF p_id IS NULL OR p_publie IS NULL THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  UPDATE public.calendrier_ecole
     SET publie = p_publie,
         publie_le = CASE WHEN p_publie THEN pg_catalog.now() ELSE publie_le END,
         maj_par = v_user
   WHERE id = p_id
  RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
END;
$function$;

-- Combien d'eleves une portee vise (pour dire a la direction ce que sa saisie change).
CREATE FUNCTION private.calendrier_eleves_vises(p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.count(*)::integer
    FROM public.eleve_etape_en_cours f
   WHERE p_portee = 'ecole'
      OR (p_portee = 'tranche'
          AND coalesce(f.cohorte, private.cohorte_effective(f.student_id, NULL)) = p_cohorte)
      OR (p_portee = 'classe'
          AND EXISTS (SELECT 1 FROM public.groupe_membres m
                       WHERE m.groupe_id = p_groupe_id AND m.student_id = f.student_id AND m.left_at IS NULL));
$function$;

-- La liste de la direction : tout le calendrier, publie ou non, avec ce que
-- chaque fermeture change (eleves vises, seances deja prevues ce jour-la).
CREATE FUNCTION public.calendrier_ecole_liste()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', ce.id, 'type', ce.type, 'categorie', ce.categorie, 'titre', ce.titre,
             'du', ce.du, 'au', ce.au, 'jours', ce.au - ce.du + 1,
             'portee', ce.portee, 'cohorte', ce.cohorte, 'groupe_id', ce.groupe_id,
             'groupe_libelle', g.libelle,
             'publie', ce.publie, 'publie_le', ce.publie_le,
             'eleves_vises', CASE WHEN ce.type = 'fermeture'
                                  THEN private.calendrier_eleves_vises(ce.portee, ce.cohorte, ce.groupe_id) END,
             'seances_deja_prevues', CASE WHEN ce.type = 'fermeture' THEN (
                SELECT pg_catalog.count(*)::integer
                  FROM public.sessions s
                  JOIN public.groupes sg ON sg.id = s.groupe_id AND sg.ended_at IS NULL
                 WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
                   AND s.started_at >= pg_catalog.now()
                   AND (s.started_at AT TIME ZONE sg.timezone_iana)::date BETWEEN ce.du AND ce.au
                   AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, sg.id)) END)
           ORDER BY ce.du, ce.au, ce.titre)
      FROM public.calendrier_ecole ce
      LEFT JOIN public.groupes g ON g.id = ce.groupe_id), '[]'::jsonb);
END;
$function$;

-- LA lecture du calendrier, pour chacun : les evenements PUBLIES qui le
-- concernent, passes recents et a venir. Eleve : les siens. Tuteur : ceux de son
-- foyer (p_eleve_id pour un seul enfant). Enseignant : ceux de ses classes.
-- Direction : tous. Ni cohorte ni classe ne sont rendues a la famille.
CREATE FUNCTION public.calendrier_ecole_lecture(p_eleve_id uuid DEFAULT NULL, p_jours_passes integer DEFAULT 30)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_role public.app_role := public.app_role();
  v_eleves uuid[];
  v_cohortes text[];
  v_classes uuid[];
  v_detail boolean := false;
  v_aujourdhui date := (pg_catalog.now() AT TIME ZONE 'UTC')::date;
  v_depuis date := (pg_catalog.now() AT TIME ZONE 'UTC')::date - greatest(0, least(coalesce(p_jours_passes, 30), 366));
  v_tous boolean := false;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
  END IF;

  IF v_role = 'admin' THEN
    v_tous := true;
    v_detail := true;
  ELSIF v_role = 'teacher' THEN
    IF p_eleve_id IS NOT NULL THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
    v_detail := true;
    SELECT coalesce(pg_catalog.array_agg(g.id), '{}') INTO v_classes
      FROM public.groupes g WHERE g.teacher_id = v_user AND g.ended_at IS NULL;
    SELECT coalesce(pg_catalog.array_agg(DISTINCT sp.cohorte), '{}') INTO v_cohortes
      FROM public.groupe_membres m
      JOIN public.student_profiles sp ON sp.profile_id = m.student_id
     WHERE m.groupe_id = ANY (v_classes) AND m.left_at IS NULL AND sp.cohorte IS NOT NULL;
  ELSIF v_role = 'student' THEN
    IF p_eleve_id IS NOT NULL AND p_eleve_id <> v_user THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
    v_eleves := ARRAY[v_user];
  ELSIF v_role = 'guardian' THEN
    SELECT coalesce(pg_catalog.array_agg(x.id), '{}') INTO v_eleves
      FROM (
        SELECT p.id FROM public.profiles p
          JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
         WHERE p.role = 'student' AND p.deleted_at IS NULL
           AND p.household_id IS NOT NULL AND p.household_id = public.app_household_id()
        UNION
        SELECT sp.profile_id FROM public.student_profiles sp
         WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user AND sp.deleted_at IS NULL
      ) x
     WHERE p_eleve_id IS NULL OR x.id = p_eleve_id;
    IF p_eleve_id IS NOT NULL AND NOT (p_eleve_id = ANY (v_eleves)) THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
  ELSE
    RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
  END IF;

  IF v_eleves IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(DISTINCT private.cohorte_effective(e, NULL))
                    FILTER (WHERE private.cohorte_effective(e, NULL) IS NOT NULL), '{}')
      INTO v_cohortes FROM pg_catalog.unnest(v_eleves) AS e;
    SELECT coalesce(pg_catalog.array_agg(DISTINCT m.groupe_id), '{}') INTO v_classes
      FROM public.groupe_membres m
      JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
     WHERE m.student_id = ANY (v_eleves) AND m.left_at IS NULL;
  END IF;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(
             pg_catalog.jsonb_build_object(
               'id', ce.id, 'type', ce.type, 'categorie', ce.categorie, 'titre', ce.titre,
               'du', ce.du, 'au', ce.au, 'portee', ce.portee,
               'passe', ce.au < v_aujourdhui,
               'en_cours', v_aujourdhui BETWEEN ce.du AND ce.au)
             || CASE WHEN v_detail THEN pg_catalog.jsonb_build_object(
                  'cohorte', ce.cohorte, 'groupe_id', ce.groupe_id) ELSE '{}'::jsonb END
             ORDER BY ce.du, ce.au, ce.titre)
      FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.au >= v_depuis
       AND (v_tous
            OR ce.portee = 'ecole'
            OR (ce.portee = 'tranche' AND ce.cohorte = ANY (v_cohortes))
            OR (ce.portee = 'classe' AND ce.groupe_id = ANY (v_classes)))), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 9. La pause : portes, regles, gestes
-- ---------------------------------------------------------------------------
-- Qui demande pour qui : le tuteur du foyer pour un enfant ; l'eleve adulte
-- (autonome) pour lui-meme. Jamais un enfant. Exigence positive : un NULL ferme.
CREATE FUNCTION private.pause_famille_peut(p_eleve_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    p_eleve_id IS NOT NULL AND auth.uid() IS NOT NULL AND public.app_account_valid()
    AND (
      (public.app_role() = 'guardian'
       AND EXISTS (SELECT 1 FROM public.profiles p
                     JOIN public.student_profiles sp ON sp.profile_id = p.id
                    WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                      AND sp.deleted_at IS NULL AND sp.student_type = 'minor'
                      AND p.household_id IS NOT NULL AND p.household_id = public.app_household_id()))
      OR ((public.app_role() = 'student' OR public.app_role() = 'guardian')
          AND p_eleve_id = auth.uid()
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = p_eleve_id AND sp.student_type = 'autonomous'
                         AND sp.deleted_at IS NULL))), false);
$function$;

-- « Aujourd'hui » dans le fuseau du foyer de l'eleve (UTC sans foyer).
CREATE FUNCTION private.aujourdhui_foyer(p_eleve_id uuid)
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (pg_catalog.now() AT TIME ZONE coalesce(
            (SELECT h.timezone FROM public.profiles p
               JOIN public.households h ON h.id = p.household_id
              WHERE p.id = p_eleve_id), 'UTC'))::date;
$function$;

-- Ce mois depasse-t-il le plafond (n mois sur m mois glissants, accord particulier
-- de la direction au-dela) ? On regarde chaque fenetre glissante qui contient ce
-- mois ; seules les pauses d'un mois acceptees comptent (une pause d'exception
-- ne compte pas : une maladie n'use pas le droit de la famille).
CREATE FUNCTION private.pause_depasse_plafond(p_eleve_id uuid, p_debut date)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fenetre integer := public.app_config_int('pause.fenetre_mois', 12);
  v_max integer := public.app_config_int('pause.max_mois_fenetre', 2);
  v_debut date;
  v_fin date;
  v_n integer;
BEGIN
  FOR k IN 0 .. v_fenetre - 1 LOOP
    v_debut := (p_debut - pg_catalog.make_interval(months => v_fenetre - 1 - k))::date;
    v_fin := (v_debut + pg_catalog.make_interval(months => v_fenetre))::date;
    SELECT pg_catalog.count(*)::integer INTO v_n
      FROM public.pauses_eleve p
     WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.statut = 'acceptee'
       AND p.debut >= v_debut AND p.debut < v_fin;
    IF v_n + 1 > v_max THEN
      RETURN true;
    END IF;
  END LOOP;
  RETURN false;
END;
$function$;

-- Le nom de la personne de la direction (copie au moment du geste).
CREATE FUNCTION private.nom_direction(p_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
    FROM public.profiles p WHERE p.id = p_id;
$function$;

-- La notification de la reponse de la direction (jamais a un mineur : le tuteur
-- est le destinataire d'un enfant ; l'adulte recoit la sienne). Un echec ne
-- bloque jamais la decision.
CREATE FUNCTION private.pause_notifier_reponse(p_pause_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.pauses_eleve%ROWTYPE;
  v_type public.student_type;
  v_foyer uuid;
  v_role public.app_role;
  v_prenom text;
  r record;
BEGIN
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id;
  IF NOT FOUND OR p.statut NOT IN ('acceptee', 'refusee') THEN
    RETURN;
  END IF;
  SELECT sp.student_type, pr.household_id, pr.role, pr.first_name
    INTO v_type, v_foyer, v_role, v_prenom
    FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
   WHERE sp.profile_id = p.student_id;
  IF v_type IS NULL THEN
    RETURN;
  END IF;
  FOR r IN
    SELECT x.id, x.destination FROM (
      SELECT pr.id, '/tuteur'::text AS destination
        FROM public.profiles pr
       WHERE v_type = 'minor' AND v_foyer IS NOT NULL AND pr.household_id = v_foyer
         AND pr.role = 'guardian' AND pr.deleted_at IS NULL
      UNION ALL
      SELECT pr.id, CASE pr.role WHEN 'guardian' THEN '/tuteur' ELSE '/eleve' END
        FROM public.profiles pr
       WHERE v_type = 'autonomous' AND pr.id = p.student_id AND pr.deleted_at IS NULL
         AND pr.role IN ('student', 'guardian')
    ) x
  LOOP
    BEGIN
      INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
      VALUES (r.id, v_foyer, 'pause_repondue',
              pg_catalog.jsonb_build_object(
                'decision', p.statut,
                'mois', pg_catalog.to_char(p.debut, 'YYYY-MM'),
                'prenom', CASE WHEN v_type = 'minor' THEN v_prenom END),
              r.destination);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'pause_repondue : notification non posee (SQLSTATE %), decision enregistree', SQLSTATE;
    END;
  END LOOP;
END;
$function$;

CREATE FUNCTION public.pause_demander(p_eleve_id uuid, p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_debut date;
  v_fin date;
  v_aujourdhui date;
  v_preavis integer := public.app_config_int('pause.preavis_jours', 7);
  v_delai integer := public.app_config_int('pause.delai_reponse_jours', 3);
  v_direction boolean;
  v_id uuid;
BEGIN
  IF NOT private.pause_famille_peut(p_eleve_id) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  IF p_mois IS NULL THEN
    RAISE EXCEPTION 'pause_mois_invalide' USING errcode = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('pause:' || p_eleve_id::text, 0));

  v_debut := pg_catalog.date_trunc('month', (p_mois)::timestamp)::date;
  v_fin := (pg_catalog.date_trunc('month', (p_mois)::timestamp) + interval '1 month - 1 day')::date;
  v_aujourdhui := private.aujourdhui_foyer(p_eleve_id);
  IF v_debut - v_aujourdhui < v_preavis THEN
    RAISE EXCEPTION 'pause_preavis' USING errcode = '22023',
      detail = pg_catalog.format('%s jours avant le debut du mois', v_preavis);
  END IF;
  IF EXISTS (SELECT 1 FROM public.pauses_eleve p
              WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.debut = v_debut
                AND p.statut IN ('demandee', 'acceptee')) THEN
    RAISE EXCEPTION 'pause_deja_demandee' USING errcode = '23505';
  END IF;

  v_direction := private.pause_depasse_plafond(p_eleve_id, v_debut);
  INSERT INTO public.pauses_eleve
    (student_id, type, debut, fin, statut, acceptation, demandee_par, repondre_avant)
  VALUES
    (p_eleve_id, 'mois', v_debut, v_fin,
     CASE WHEN v_direction THEN 'demandee' ELSE 'acceptee' END,
     CASE WHEN v_direction THEN NULL ELSE 'automatique' END,
     v_user,
     CASE WHEN v_direction THEN v_aujourdhui + v_delai END)
  RETURNING id INTO v_id;

  RETURN pg_catalog.jsonb_build_object(
    'id', v_id, 'statut', CASE WHEN v_direction THEN 'demandee' ELSE 'acceptee' END,
    'debut', v_debut, 'fin', v_fin,
    'repondre_avant', CASE WHEN v_direction THEN v_aujourdhui + v_delai END);
END;
$function$;

CREATE FUNCTION public.pause_annuler(p_pause_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.pauses_eleve%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id FOR UPDATE;
  IF NOT FOUND
     OR NOT (private.pause_famille_peut(p.student_id)
             OR coalesce(public.app_role() = 'admin', false)) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  IF p.statut NOT IN ('demandee', 'acceptee') OR p.debut <= private.aujourdhui_foyer(p.student_id) THEN
    RAISE EXCEPTION 'pause_non_annulable' USING errcode = '22023';
  END IF;
  UPDATE public.pauses_eleve SET statut = 'annulee' WHERE id = p.id;
END;
$function$;

CREATE FUNCTION public.pause_decider(p_pause_id uuid, p_accepter boolean, p_motif text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  p public.pauses_eleve%ROWTYPE;
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING errcode = '42501';
  END IF;
  IF p_accepter IS NULL THEN
    RAISE EXCEPTION 'pause_decision_invalide' USING errcode = '22023';
  END IF;
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pause_introuvable' USING errcode = '22023';
  END IF;
  IF p.statut <> 'demandee' THEN
    RAISE EXCEPTION 'pause_deja_decidee' USING errcode = '22023';
  END IF;
  IF NOT p_accepter AND pg_catalog.length(v_motif) < 3 THEN
    RAISE EXCEPTION 'pause_motif_requis' USING errcode = '22023';
  END IF;
  IF p_accepter AND p.debut < private.aujourdhui_foyer(p.student_id) THEN
    -- Le mois a commence sans reponse : l'eleve est reste inscrit, la pause n'est plus acceptable.
    RAISE EXCEPTION 'pause_debut_passe' USING errcode = '22023';
  END IF;
  UPDATE public.pauses_eleve
     SET statut = CASE WHEN p_accepter THEN 'acceptee' ELSE 'refusee' END,
         acceptation = CASE WHEN p_accepter THEN 'direction' END,
         motif_decision = CASE WHEN v_motif = '' THEN NULL ELSE v_motif END,
         decidee_par = v_user, decidee_par_nom = private.nom_direction(v_user),
         decidee_le = pg_catalog.now()
   WHERE id = p.id;
  PERFORM private.pause_notifier_reponse(p.id);
END;
$function$;

CREATE FUNCTION public.pause_exception_accorder(p_eleve_id uuid, p_debut date, p_fin date, p_motif text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_debut date;
  v_id uuid;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING errcode = '42501';
  END IF;
  IF p_eleve_id IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
        WHERE sp.profile_id = p_eleve_id AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'pause_eleve_introuvable' USING errcode = '22023';
  END IF;
  IF pg_catalog.length(v_motif) < 3 THEN
    RAISE EXCEPTION 'pause_motif_requis' USING errcode = '22023';
  END IF;
  v_debut := coalesce(p_debut, private.aujourdhui_foyer(p_eleve_id));
  IF p_fin IS NULL OR p_fin < v_debut OR p_fin - v_debut > 365 THEN
    RAISE EXCEPTION 'pause_dates_invalides' USING errcode = '22023';
  END IF;
  -- Sans preavis, mais jamais dans le passe : les absences deja survenues restent des absences.
  IF v_debut < private.aujourdhui_foyer(p_eleve_id) THEN
    RAISE EXCEPTION 'pause_debut_passe' USING errcode = '22023';
  END IF;
  INSERT INTO public.pauses_eleve
    (student_id, type, debut, fin, statut, acceptation, motif, demandee_par,
     decidee_par, decidee_par_nom, decidee_le)
  VALUES
    (p_eleve_id, 'exception', v_debut, p_fin, 'acceptee', 'direction', v_motif, v_user,
     v_user, private.nom_direction(v_user), pg_catalog.now())
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$function$;

-- LA lecture des pauses d'un eleve (famille, direction) : la regle, les mois
-- proposes, les pauses et leur etat.
CREATE FUNCTION public.pauses_eleve_lecture(p_eleve_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin boolean := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  v_aujourdhui date;
  v_preavis integer := public.app_config_int('pause.preavis_jours', 7);
  v_premier date;
BEGIN
  IF NOT (v_admin OR private.pause_famille_peut(p_eleve_id)) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  v_aujourdhui := private.aujourdhui_foyer(p_eleve_id);
  v_premier := (pg_catalog.date_trunc('month', (v_aujourdhui + v_preavis)::timestamp)::date);
  IF v_premier < v_aujourdhui + v_preavis THEN
    v_premier := (v_premier + interval '1 month')::date;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'eleve_id', p_eleve_id,
    'prenom', (SELECT pr.first_name FROM public.profiles pr WHERE pr.id = p_eleve_id),
    'aujourdhui', v_aujourdhui,
    'regle', pg_catalog.jsonb_build_object(
      'preavis_jours', v_preavis,
      'plafond_mois', public.app_config_int('pause.max_mois_fenetre', 2),
      'fenetre_mois', public.app_config_int('pause.fenetre_mois', 12),
      'delai_reponse_jours', public.app_config_int('pause.delai_reponse_jours', 3)),
    'mois_accordes', (
      SELECT pg_catalog.count(*)::integer FROM public.pauses_eleve p
       WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.statut = 'acceptee'
         AND p.debut >= (pg_catalog.date_trunc('month', (v_aujourdhui)::timestamp)
                         - pg_catalog.make_interval(months => public.app_config_int('pause.fenetre_mois', 12) - 1))::date),
    'mois_proposes', (
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'mois', m.debut,
               'a_la_direction', private.pause_depasse_plafond(p_eleve_id, m.debut),
               'etat', (SELECT p.statut FROM public.pauses_eleve p
                         WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.debut = m.debut
                           AND p.statut IN ('demandee', 'acceptee')))
             ORDER BY m.debut)
        FROM (SELECT (v_premier + pg_catalog.make_interval(months => k))::date AS debut
                FROM pg_catalog.generate_series(0, 11) k) m),
    'pauses', coalesce((
      SELECT pg_catalog.jsonb_agg(
               pg_catalog.jsonb_build_object(
                 'id', p.id, 'type', p.type, 'debut', p.debut, 'fin', p.fin, 'statut', p.statut,
                 'demandee_le', p.demandee_le, 'repondre_avant', p.repondre_avant,
                 'decidee_le', p.decidee_le, 'motif_decision', p.motif_decision,
                 'annulable', p.statut IN ('demandee', 'acceptee') AND p.debut > v_aujourdhui)
               || CASE WHEN v_admin THEN pg_catalog.jsonb_build_object(
                    'motif', p.motif, 'decidee_par_nom', p.decidee_par_nom,
                    'acceptation', p.acceptation) ELSE '{}'::jsonb END
               ORDER BY p.debut DESC, p.demandee_le DESC)
        FROM (SELECT * FROM public.pauses_eleve x WHERE x.student_id = p_eleve_id
               ORDER BY x.debut DESC, x.demandee_le DESC LIMIT 24) p), '[]'::jsonb));
END;
$function$;

-- La file de la direction : les demandes a traiter (au-dela du plafond) et les
-- decisions recentes (pauses d'exception comprises).
CREATE FUNCTION public.pauses_a_traiter()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pauses reservees a la direction' USING errcode = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'a_traiter', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', p.id, 'eleve_id', p.student_id,
               'eleve_nom', pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')),
               'cohorte', sp.cohorte, 'debut', p.debut, 'fin', p.fin,
               'demandee_le', p.demandee_le, 'repondre_avant', p.repondre_avant,
               'en_retard', p.repondre_avant < private.aujourdhui_foyer(p.student_id),
               'mois_accordes', (
                 SELECT pg_catalog.count(*)::integer FROM public.pauses_eleve a
                  WHERE a.student_id = p.student_id AND a.type = 'mois' AND a.statut = 'acceptee'
                    AND a.debut >= (pg_catalog.date_trunc('month', (p.debut)::timestamp)
                                    - pg_catalog.make_interval(months => public.app_config_int('pause.fenetre_mois', 12) - 1))::date
                    AND a.debut < p.debut + interval '12 months'))
             ORDER BY p.repondre_avant, p.demandee_le)
        FROM public.pauses_eleve p
        JOIN public.profiles pr ON pr.id = p.student_id
        LEFT JOIN public.student_profiles sp ON sp.profile_id = p.student_id
       WHERE p.statut = 'demandee'), '[]'::jsonb),
    'recentes', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', r.id, 'eleve_id', r.student_id, 'eleve_nom', r.nom, 'type', r.type,
               'debut', r.debut, 'fin', r.fin, 'statut', r.statut, 'motif', r.motif,
               'motif_decision', r.motif_decision, 'decidee_par_nom', r.decidee_par_nom,
               'decidee_le', r.decidee_le) ORDER BY r.decidee_le DESC)
        FROM (SELECT p.*, pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')) AS nom
                FROM public.pauses_eleve p JOIN public.profiles pr ON pr.id = p.student_id
               WHERE p.decidee_le IS NOT NULL
               ORDER BY p.decidee_le DESC LIMIT 20) r), '[]'::jsonb));
END;
$function$;

-- Choisir un eleve pour une pause d'exception : recherche par nom, 20 au plus.
CREATE FUNCTION public.pauses_eleves_recherche(p_q text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_q text := pg_catalog.btrim(coalesce(p_q, ''));
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pauses reservees a la direction' USING errcode = '42501';
  END IF;
  IF pg_catalog.length(v_q) < 2 THEN
    RETURN '[]'::jsonb;
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', x.id, 'nom', x.nom, 'cohorte', x.cohorte, 'matricule', x.immutable_id) ORDER BY x.nom)
      FROM (SELECT pr.id, pr.immutable_id, sp.cohorte,
                   pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')) AS nom
              FROM public.profiles pr
              JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
             WHERE pr.deleted_at IS NULL
               AND (pr.first_name || ' ' || pr.last_name) ILIKE '%' || pg_catalog.replace(
                     pg_catalog.replace(pg_catalog.replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%'
             ORDER BY pr.first_name, pr.last_name LIMIT 20) x), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 10. La reponse a une demande de pause n'est ni un courriel ni un push (lot 7)
-- ---------------------------------------------------------------------------
INSERT INTO private.notification_courriel (evenement, portee, courriel, push)
VALUES ('pause_repondue', '*', false, false)
ON CONFLICT (evenement, portee) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 11. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.calendrier_reglages_valider() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_ecole_valider() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_vise_classe(text, text, uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.jour_ferme_pour_classe(date, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_en_pause(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_en_pause_mois(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.recul_jours_calcule(uuid, date, uuid, text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_etape_recul_deriver() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.recul_recalculer_cible(text, text, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_ecole_recalculer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pauses_eleve_recalculer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_eleves_vises(text, text, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_famille_peut(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.aujourdhui_foyer(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_depasse_plafond(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.nom_direction(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_notifier_reponse(uuid) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.calendrier_ecole_enregistrer(uuid, text, text, text, date, date, text, text, uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_publier(uuid, boolean) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_liste() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_lecture(uuid, integer) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_demander(uuid, date) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_annuler(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_decider(uuid, boolean, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_exception_accorder(uuid, date, date, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_eleve_lecture(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_a_traiter() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_eleves_recherche(text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_enregistrer(uuid, text, text, text, date, date, text, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_publier(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_liste() TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_lecture(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_demander(uuid, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_annuler(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_decider(uuid, boolean, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_exception_accorder(uuid, date, date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_eleve_lecture(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_a_traiter() TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_eleves_recherche(text) TO authenticated;

DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.calendrier_ecole FROM agent_ro';
    EXECUTE 'REVOKE ALL ON public.pauses_eleve FROM agent_ro';
  END IF;
END
$agent$;

-- ---------------------------------------------------------------------------
-- 12. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.calendrier_ecole'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.pauses_eleve'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : RLS absente sur une table neuve';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.calendrier_ecole', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.calendrier_ecole', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.pauses_eleve', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.pauses_eleve', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.calendrier_ecole', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.pauses_eleve', 'SELECT') THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : ecriture ou lecture directe ouverte sur une table neuve';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.pause_demander(uuid, date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.calendrier_ecole_lecture(uuid, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.pause_decider(uuid, boolean, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.recul_jours_calcule(uuid, date, uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.eleve_en_pause(uuid, date)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.pause_demander(uuid, date)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : droits des fonctions incorrects';
  END IF;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure),
       'private.jour_ferme_pour_classe') = 0
     OR pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.etape_eleve_lecture(uuid)'::pg_catalog.regprocedure),
       '''recul_jours''') = 0 THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : un remplacement n''est pas passe';
  END IF;
END
$postflight$;
