-- REVENUS-VERITE, point 5 « Autres revenus » (pilote, 06/11/2026 ; PLAN-LOTS
-- 22 j ; arbitrage du garde-cap du 06/11).
--
-- Instructions destructives : aucune (ni effacement de lignes, ni retrait
-- d'objet, ni vidage). Une table creee (RLS activee, aucun droit client : tout
-- passe par des fonctions DEFINER), deux aides privees, trois fonctions
-- publiques creees, trois fonctions publiques remplacees (CREATE OR REPLACE,
-- meme signature), droits, commentaires et verifications.
--
-- Ce qui existait : l'aide Internet, montant de la politique commerciale
-- (`allocation_internet_mineur`, « une seule aide par enseignant eligible »),
-- sans aucune donnee d'eligibilite ; `mes_revenus_enseignant` rendait
-- `allocationInternet` toujours nul. Aucune prime ni mission n'avait de
-- support serveur (D6 : rien d'autre trouve, INVENTAIRE-NON-BRANCHE compris).
--
-- Ce que la migration pose :
-- 1. `public.revenus_enseignant_autres` : une ligne par revenu attribue par
--    la direction a un enseignant pour un mois : nature (`aide_internet`,
--    `prime`, `mission`), libelle, montant en unite mineure, devise de la
--    politique du mois. Payable avec la paie du mois. Une erreur s'annule
--    (`annule_le`, jamais d'effacement). Idempotence par cle.
--    L'aide Internet devient explicite : la direction l'attribue a
--    l'enseignant eligible, le montant de la politique est propose.
-- 2. `public.autre_revenu_attribuer` et `public.autre_revenu_annuler` :
--    direction seule (role admin, compte valide), journalisees
--    (`log_sensitive_access`).
-- 3. `public.autres_revenus_lister(p_enseignant, p_mois)` : direction et
--    comptabilite ; rend `peutAttribuer` (capacite lue par l'ecran) et le
--    montant d'aide Internet de la politique.
-- 4. `mes_revenus_enseignant` : `autres`, `totalAutres`, et
--    `allocationInternet` = somme des aides Internet attribuees du mois.
-- 5. `releve_paie_mensuel` et `releve_paie_seances` : les autres revenus
--    comptent dans le montant a payer (`montant`, `total`), detailles a part
--    (`montantAutres`, `autres`) ; un enseignant qui n'a que ceux-la figure au
--    releve.
BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : les fonctions remplacees sont celles du depot (md5(prosrc)
--    de la base rejouee ; le pilote compare a la production).
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT x.sig, x.attendu, pg_catalog.md5(p.prosrc) AS lu
      FROM (VALUES
        ('public.mes_revenus_enseignant(date)', '366daf7c783c2391f7b9f30aa610d2af'),
        ('public.releve_paie_mensuel(date)', 'c461c6b6b0b4abf822c56e362b6faf41'),
        ('public.releve_paie_seances(date,uuid)', '44d6d34e603d91d84d185e14cd0a5e15')) AS x(sig, attendu)
      LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(x.sig)
  LOOP
    RAISE NOTICE 'AUTRES-REVENUS preflight : % md5(prosrc) = %', r.sig, r.lu;
    IF r.lu IS DISTINCT FROM r.attendu THEN
      RAISE EXCEPTION 'AUTRES-REVENUS : % differe du depot (md5 %), rien n''est change', r.sig, r.lu;
    END IF;
  END LOOP;
  IF pg_catalog.to_regclass('public.revenus_enseignant_autres') IS NOT NULL THEN
    RAISE EXCEPTION 'AUTRES-REVENUS : la table existe deja';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La table
-- ---------------------------------------------------------------------------
CREATE TABLE public.revenus_enseignant_autres (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  enseignant_id uuid NOT NULL REFERENCES public.profiles(id),
  mois date NOT NULL CHECK (mois = pg_catalog.date_trunc('month', mois)::date),
  nature text NOT NULL CHECK (nature IN ('aide_internet', 'prime', 'mission')),
  libelle text NOT NULL CHECK (pg_catalog.char_length(pg_catalog.btrim(libelle)) BETWEEN 1 AND 120
                               AND libelle !~ '[[:cntrl:]]'),
  montant_minor bigint NOT NULL CHECK (montant_minor > 0 AND montant_minor <= 10000000),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  cle_idempotence text NOT NULL UNIQUE CHECK (pg_catalog.char_length(cle_idempotence) BETWEEN 8 AND 120),
  attribue_par uuid NOT NULL REFERENCES public.profiles(id),
  attribue_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  annule_le timestamptz,
  annule_par uuid REFERENCES public.profiles(id),
  CHECK ((annule_le IS NULL) = (annule_par IS NULL))
);
CREATE INDEX revenus_enseignant_autres_mois
  ON public.revenus_enseignant_autres (mois, enseignant_id) WHERE annule_le IS NULL;
ALTER TABLE public.revenus_enseignant_autres ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.revenus_enseignant_autres FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.revenus_enseignant_autres IS
  'REVENUS-VERITE point 5 : autres revenus d''un enseignant pour un mois (aide Internet, prime, mission), attribues par la direction, payables avec la paie du mois. Annulation par annule_le, jamais d''effacement. Aucun droit client : lecture et ecriture par fonctions DEFINER gardees. date=2026-11-06.';

-- ---------------------------------------------------------------------------
-- 2. Aides privees : les lignes non annulees d'un mois
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.autres_revenus_du(p_enseignant uuid, p_mois date)
RETURNS SETOF public.revenus_enseignant_autres
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT a.* FROM public.revenus_enseignant_autres a
   WHERE a.enseignant_id = p_enseignant
     AND a.mois = pg_catalog.date_trunc('month', p_mois)::date
     AND a.annule_le IS NULL;
$function$;

CREATE FUNCTION private.autres_revenus_mois(p_mois date)
RETURNS SETOF public.revenus_enseignant_autres
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT a.* FROM public.revenus_enseignant_autres a
   WHERE a.mois = pg_catalog.date_trunc('month', p_mois)::date
     AND a.annule_le IS NULL;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Les gestes et la lecture de la direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.autre_revenu_attribuer(p_enseignant uuid, p_mois date, p_nature text,
                                              p_libelle text, p_montant_minor bigint, p_cle text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_mois date;
  v_courant date;
  v_devise text;
  v_ligne public.revenus_enseignant_autres;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_enseignant IS NULL OR p_mois IS NULL OR p_nature IS NULL OR p_libelle IS NULL
     OR p_montant_minor IS NULL OR p_cle IS NULL THEN
    RAISE EXCEPTION 'autre revenu : champ manquant' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = p_enseignant AND p.role = 'teacher') THEN
    RAISE EXCEPTION 'autre revenu : enseignant inconnu' USING ERRCODE = '22023';
  END IF;
  -- Idempotence : la meme cle rend la meme ligne (double appui).
  SELECT a.* INTO v_ligne FROM public.revenus_enseignant_autres a WHERE a.cle_idempotence = p_cle;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', v_ligne.id, 'deja', true);
  END IF;
  v_mois := pg_catalog.date_trunc('month', p_mois)::date;
  v_courant := pg_catalog.date_trunc('month', (pg_catalog.now() AT TIME ZONE private.bf1_fuseau_comptable()))::date;
  -- Payable a la fin du mois : le mois en cours, le precedent (pas encore
  -- verse), ou un mois a venir ; jamais un mois deja ancien.
  IF v_mois < (v_courant - interval '1 month')::date THEN
    RAISE EXCEPTION 'autre revenu : mois deja passe' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce((private.fac_politique_au(v_mois)).devise, 'USD');
  INSERT INTO public.revenus_enseignant_autres (enseignant_id, mois, nature, libelle, montant_minor,
                                                devise, cle_idempotence, attribue_par)
  VALUES (p_enseignant, v_mois, p_nature, pg_catalog.btrim(p_libelle), p_montant_minor, v_devise,
          p_cle, v_uid)
  RETURNING * INTO v_ligne;
  PERFORM public.log_sensitive_access('autre_revenu_attribue', 'revenus_enseignant_autres',
    v_ligne.id::text, pg_catalog.jsonb_build_object('enseignant', p_enseignant, 'mois', v_mois,
      'nature', p_nature, 'montant_minor', p_montant_minor, 'devise', v_devise));
  RETURN pg_catalog.jsonb_build_object('id', v_ligne.id, 'deja', false);
END;
$function$;

CREATE FUNCTION public.autre_revenu_annuler(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_ligne public.revenus_enseignant_autres;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  UPDATE public.revenus_enseignant_autres a
     SET annule_le = pg_catalog.now(), annule_par = v_uid
   WHERE a.id = p_id AND a.annule_le IS NULL
  RETURNING * INTO v_ligne;
  IF NOT FOUND THEN
    IF NOT EXISTS (SELECT 1 FROM public.revenus_enseignant_autres a WHERE a.id = p_id) THEN
      RAISE EXCEPTION 'autre revenu inconnu' USING ERRCODE = 'P0002';
    END IF;
    RETURN pg_catalog.jsonb_build_object('id', p_id, 'deja', true);
  END IF;
  PERFORM public.log_sensitive_access('autre_revenu_annule', 'revenus_enseignant_autres',
    p_id::text, pg_catalog.jsonb_build_object('enseignant', v_ligne.enseignant_id, 'mois', v_ligne.mois));
  RETURN pg_catalog.jsonb_build_object('id', p_id, 'deja', false);
END;
$function$;

CREATE FUNCTION public.autres_revenus_lister(p_enseignant uuid, p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_mois date;
  v_pol public.politiques_commerciales;
BEGIN
  IF NOT private.pai_releve_autorise() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_enseignant IS NULL OR p_mois IS NULL THEN
    RAISE EXCEPTION 'mois et enseignant requis' USING ERRCODE = '22023';
  END IF;
  v_mois := pg_catalog.date_trunc('month', p_mois)::date;
  v_pol := private.fac_politique_au(v_mois);
  RETURN pg_catalog.jsonb_build_object(
    'mois', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'devise', coalesce(v_pol.devise, 'USD'),
    'peutAttribuer', coalesce(public.app_role() = 'admin', false),
    'aideInternetPolitique', CASE WHEN v_pol.allocation_internet_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(v_pol.allocation_internet_mineur, v_pol.devise) END,
    'lignes', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', a.id, 'nature', a.nature, 'libelle', a.libelle,
               'montant', private.bf1_montant(a.montant_minor, a.devise),
               'attribueLe', a.attribue_le)
               ORDER BY a.attribue_le, a.id)
        FROM private.autres_revenus_du(p_enseignant, v_mois) a), '[]'::jsonb));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Les revenus de l'enseignant (REVENUS-VERITE, 20261110200000, plus les
--    autres revenus)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mes_revenus_enseignant(p_mois date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_regle public.regles_remuneration_enseignant%ROWTYPE;
  v_pol public.politiques_commerciales;
  v_par_eleve boolean;
  v_devises integer;
  v_devise text;
  v_classes jsonb;
  v_seances jsonb;
  v_minutes bigint;
  v_capacite bigint;
  v_total bigint;
  v_moyen bigint;
  v_fenetre jsonb;
  v_suivant date;
  v_jours integer;
  v_autres jsonb;
  v_total_autres bigint;
  v_internet bigint;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'teacher'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'revenus reserves a l''enseignant connecte' USING ERRCODE = '42501';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month',
    coalesce(p_mois, (pg_catalog.now() AT TIME ZONE v_zone)::date))::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  v_pol := private.fac_politique_au(v_mois);
  v_par_eleve := v_pol.version IS NOT NULL
    AND v_pol.taux_eleve_heure_enfant_mineur IS NOT NULL AND v_pol.taux_eleve_heure_adulte_mineur IS NOT NULL;
  IF NOT v_par_eleve THEN
    SELECT r.* INTO v_regle FROM public.regles_remuneration_enseignant r
     WHERE r.date_effet < (v_mois + interval '1 month')::date
       AND (r.enseignant_id = v_uid OR r.enseignant_id IS NULL)
     ORDER BY (r.enseignant_id IS NOT NULL) DESC, r.date_effet DESC, r.cree_le DESC
     LIMIT 1;
  END IF;

  SELECT count(DISTINCT p.devise), min(p.devise) INTO v_devises, v_devise
    FROM private.bf1_prestations(v_uid, v_debut, v_fin) p;
  IF v_devises > 1
     OR (v_devises = 1 AND NOT v_par_eleve AND v_regle.id IS NOT NULL AND v_devise <> v_regle.devise)
     OR (v_devises = 1 AND v_par_eleve AND v_devise <> v_pol.devise) THEN
    RAISE EXCEPTION 'revenus en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, CASE WHEN v_par_eleve THEN v_pol.devise ELSE v_regle.devise END);

  -- Par classe : seances payees du mois (inchange, sans les sieges).
  WITH par_classe AS (
    SELECT g.id, g.libelle, g.type_public, g.seuil_max,
           (g.teacher_id IS DISTINCT FROM v_uid) AS remplacement,
           sum(p.minutes)::bigint AS minutes, sum(p.montant)::bigint AS montant
      FROM private.bf1_prestations(v_uid, v_debut, v_fin) p
      JOIN public.groupes g ON g.id = p.groupe
     GROUP BY g.id, g.libelle, g.type_public, g.seuil_max, g.teacher_id
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'classeId', c.id, 'classe', c.libelle,
           'type', CASE c.type_public WHEN 'adulte' THEN 'adultes' ELSE 'enfants' END,
           'minutesAssurees', c.minutes, 'capacite', c.seuil_max,
           'tauxHoraireEffectif', private.bf1_montant(
             CASE WHEN c.minutes > 0 THEN least(
               coalesce(v_regle.taux_minor_par_heure, pg_catalog.round(c.montant * 60.0 / c.minutes)::bigint),
               pg_catalog.round(c.montant * 60.0 / c.minutes)::bigint) ELSE 0 END, v_devise),
           'montantEstime', private.bf1_montant(c.montant, v_devise),
           'enRemplacement', c.remplacement)
           ORDER BY c.libelle, c.id), '[]'::jsonb),
         coalesce(sum(c.minutes), 0), coalesce(sum(c.seuil_max), 0), coalesce(sum(c.montant), 0)
    INTO v_classes, v_minutes, v_capacite, v_total
    FROM par_classe c;

  v_moyen := CASE WHEN v_minutes > 0 THEN least(
    coalesce(v_regle.taux_minor_par_heure, pg_catalog.round(v_total * 60.0 / v_minutes)::bigint),
    pg_catalog.round(v_total * 60.0 / v_minutes)::bigint) ELSE 0 END;

  -- Par seance et par eleve : la source du releve de la direction.
  -- Le montant est celui ECRIT par pai_due_seance (tresorerie_mouvements),
  -- montre meme quand le versement attend le cahier de la semaine (la
  -- direction le voit nul dans son releve, `pai_releve_seances` ; ici
  -- `attente` = 'cahier' le dit). Sans montant ecrit et avec une reprise
  -- ouverte : `attente` = 'direction', montant nul. Sinon (aucun present) : 0.
  WITH seances AS (
    SELECT r.seance, r.groupe, r.debut, r.minutes, m.montant_minor AS montant,
           CASE WHEN NOT r.en_attente THEN NULL
                WHEN m.id IS NULL THEN 'direction' ELSE 'cahier' END AS attente,
           g.libelle, g.type_public, (g.teacher_id IS DISTINCT FROM v_uid) AS remplacement
      FROM private.pai_releve_seances(v_debut, v_fin) r
      JOIN public.groupes g ON g.id = r.groupe
      LEFT JOIN public.tresorerie_mouvements m
        ON m.source_type = 'prestation' AND m.source_id = r.seance::text
       AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
     WHERE r.enseignant = v_uid
  ), eleves AS (
    SELECT sp.session_id AS seance, sp.profile_id AS eleve, p.first_name AS prenom,
           (t.statut IN ('presente', 'partielle')) AS present
      FROM seances s
      JOIN public.session_participants sp
        ON sp.session_id = s.seance AND sp.role = 'student' AND sp.deleted_at IS NULL
      JOIN public.profiles p ON p.id = sp.profile_id
      CROSS JOIN LATERAL private.presence_temps_reel(sp.session_id, sp.profile_id) t
  ), rangs AS (
    SELECT e.*,
           count(*) FILTER (WHERE e.present) OVER (PARTITION BY e.seance) AS presents,
           CASE WHEN e.present THEN pg_catalog.row_number() OVER (
             PARTITION BY e.seance, e.present ORDER BY e.prenom, e.eleve) END AS rang
      FROM eleves e
  ), parts AS (
    SELECT r.seance, r.eleve, r.prenom, r.present,
           CASE WHEN NOT r.present OR s.montant IS NULL OR r.presents = 0 THEN 0::bigint
                ELSE s.montant / r.presents
                     + CASE WHEN r.rang <= s.montant % r.presents THEN 1 ELSE 0 END END AS part
      FROM rangs r JOIN seances s ON s.seance = r.seance
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'seanceId', s.seance,
           'debut', s.debut,
           'classeId', s.groupe, 'classe', s.libelle,
           'type', CASE s.type_public WHEN 'adulte' THEN 'adultes' ELSE 'enfants' END,
           'enRemplacement', s.remplacement,
           'minutes', s.minutes,
           'attente', s.attente,
           'montant', CASE WHEN s.attente = 'direction' THEN NULL
                           ELSE private.bf1_montant(coalesce(s.montant, 0), v_devise) END,
           'eleves', coalesce((
             SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                      'eleveId', x.eleve, 'prenom', x.prenom, 'present', x.present,
                      'montant', CASE WHEN s.attente = 'direction' THEN NULL
                                      ELSE private.bf1_montant(x.part, v_devise) END)
                      ORDER BY x.present DESC, x.prenom, x.eleve)
               FROM parts x WHERE x.seance = s.seance), '[]'::jsonb))
           ORDER BY s.debut DESC, s.seance), '[]'::jsonb)
    INTO v_seances
    FROM seances s;

  -- Le jour de paie : du jourDebut au jourFin du mois suivant.
  v_fenetre := coalesce((SELECT c.value FROM public.app_config c WHERE c.key = 'paie.fenetre_versement'),
                        '{"jourDebut": 1, "jourFin": 10}'::jsonb);
  v_suivant := (v_mois + interval '1 month')::date;
  v_jours := extract(day FROM (v_suivant + interval '1 month' - interval '1 day'))::integer;

  -- Autres revenus (REVENUS-VERITE point 5) : aide Internet, primes et
  -- missions attribuees par la direction pour ce mois, non annulees.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', a.id, 'nature', a.nature, 'libelle', a.libelle,
           'montant', private.bf1_montant(a.montant_minor, a.devise))
           ORDER BY a.attribue_le, a.id), '[]'::jsonb),
         coalesce(sum(a.montant_minor), 0),
         sum(a.montant_minor) FILTER (WHERE a.nature = 'aide_internet')
    INTO v_autres, v_total_autres, v_internet
    FROM private.autres_revenus_du(v_uid, v_mois) a;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'regle', CASE WHEN v_par_eleve THEN pg_catalog.jsonb_build_object('parElevePresent', true)
                  WHEN v_regle.id IS NULL THEN NULL
                  ELSE pg_catalog.jsonb_build_object('parElevePresent', false) END,
    'classes', v_classes,
    'seances', v_seances,
    'total', pg_catalog.jsonb_build_object(
      'minutesAssurees', v_minutes, 'capacite', v_capacite,
      'tauxHoraireMoyen', private.bf1_montant(v_moyen, v_devise)),
    'totalEstime', private.bf1_montant(v_total, v_devise),
    'versement', pg_catalog.jsonb_build_object(
      'du', pg_catalog.to_char(v_suivant + (least((v_fenetre ->> 'jourDebut')::integer, v_jours) - 1), 'YYYY-MM-DD'),
      'au', pg_catalog.to_char(v_suivant + (least((v_fenetre ->> 'jourFin')::integer, v_jours) - 1), 'YYYY-MM-DD')),
    'autres', v_autres,
    'totalAutres', private.bf1_montant(v_total_autres, v_devise),
    'allocationInternet', CASE WHEN v_internet IS NULL THEN NULL
                               ELSE private.bf1_montant(v_internet, v_devise) END);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Le releve de la direction (20261102200000, plus les autres revenus)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.releve_paie_mensuel(p_mois date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_devise text;
  v_devises integer;
  v_enseignants jsonb;
  v_total bigint;
BEGIN
  IF NOT private.pai_releve_autorise() THEN
    RAISE EXCEPTION 'releve de paie reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month',
    coalesce(p_mois, (pg_catalog.now() AT TIME ZONE v_zone)::date))::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  SELECT count(DISTINCT d.devise), min(d.devise) INTO v_devises, v_devise
    FROM (SELECT r.devise FROM private.pai_releve_seances(v_debut, v_fin) r WHERE r.devise IS NOT NULL
          UNION ALL
          SELECT a.devise FROM private.autres_revenus_mois(v_mois) a) d;
  IF v_devises > 1 THEN
    RAISE EXCEPTION 'releve de paie en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, (private.fac_politique_au(v_mois)).devise);

  WITH r AS (SELECT * FROM private.pai_releve_seances(v_debut, v_fin)),
  par_enseignant AS (
    SELECT r.enseignant,
           count(*) FILTER (WHERE NOT r.en_attente)::integer AS tenues,
           count(*) FILTER (WHERE r.en_attente)::integer AS en_attente,
           coalesce(sum(r.minutes) FILTER (WHERE NOT r.en_attente), 0)::bigint AS minutes,
           coalesce(sum(r.minutes * r.presents) FILTER (WHERE NOT r.en_attente), 0)::bigint AS minutes_eleves,
           coalesce(sum(r.montant), 0)::bigint AS montant,
           pg_catalog.array_agg(DISTINCT r.groupe) AS groupes
      FROM r GROUP BY r.enseignant
  ),
  -- REVENUS-VERITE point 5 : les autres revenus du mois (aide Internet,
  -- primes, missions), payables avec la paie ; un enseignant qui n'a que
  -- ceux-la figure aussi au releve.
  autres AS (
    SELECT a.enseignant_id AS enseignant, sum(a.montant_minor)::bigint AS montant
      FROM private.autres_revenus_mois(v_mois) a GROUP BY a.enseignant_id
  ),
  tous AS (
    SELECT coalesce(e.enseignant, x.enseignant) AS enseignant,
           coalesce(e.tenues, 0) AS tenues, coalesce(e.en_attente, 0) AS en_attente,
           coalesce(e.minutes, 0) AS minutes, coalesce(e.minutes_eleves, 0) AS minutes_eleves,
           coalesce(e.montant, 0) AS montant_seances, coalesce(x.montant, 0) AS montant_autres,
           coalesce(e.montant, 0) + coalesce(x.montant, 0) AS montant,
           coalesce(e.groupes, ARRAY[]::uuid[]) AS groupes
      FROM par_enseignant e FULL JOIN autres x ON x.enseignant = e.enseignant
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'enseignantId', e.enseignant,
           'prenom', p.first_name, 'nom', p.last_name,
           'seancesTenues', e.tenues, 'seancesEnAttente', e.en_attente,
           'minutes', e.minutes, 'minutesEleves', e.minutes_eleves,
           'montant', private.bf1_montant(e.montant, v_devise),
           'montantSeances', private.bf1_montant(e.montant_seances, v_devise),
           'montantAutres', private.bf1_montant(e.montant_autres, v_devise),
           'classes', (SELECT coalesce(pg_catalog.jsonb_agg(g.libelle ORDER BY g.libelle), '[]'::jsonb)
                         FROM public.groupes g WHERE g.id = ANY (e.groupes)))
           ORDER BY p.last_name, p.first_name, e.enseignant), '[]'::jsonb),
         coalesce(sum(e.montant), 0)
    INTO v_enseignants, v_total
    FROM tous e
    JOIN public.profiles p ON p.id = e.enseignant;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'enseignants', v_enseignants,
    'total', private.bf1_montant(v_total, v_devise));
END;
$function$;

CREATE OR REPLACE FUNCTION public.releve_paie_seances(p_mois date, p_enseignant uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_devise text;
  v_devises integer;
  v_prof public.profiles;
  v_seances jsonb;
  v_total bigint;
  v_autres jsonb;
  v_total_autres bigint;
BEGIN
  IF NOT private.pai_releve_autorise() THEN
    RAISE EXCEPTION 'releve de paie reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_mois IS NULL OR p_enseignant IS NULL THEN
    RAISE EXCEPTION 'mois et enseignant requis' USING ERRCODE = '22023';
  END IF;
  SELECT p.* INTO v_prof FROM public.profiles p WHERE p.id = p_enseignant;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'enseignant inconnu' USING ERRCODE = 'P0002';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month', p_mois)::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  SELECT count(DISTINCT d.devise), min(d.devise) INTO v_devises, v_devise
    FROM (SELECT r.devise FROM private.pai_releve_seances(v_debut, v_fin) r
           WHERE r.enseignant = p_enseignant AND r.devise IS NOT NULL
          UNION ALL
          SELECT a.devise FROM private.autres_revenus_du(p_enseignant, v_mois) a) d;
  IF v_devises > 1 THEN
    RAISE EXCEPTION 'releve de paie en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, (private.fac_politique_au(v_mois)).devise);

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'seanceId', r.seance, 'classeId', r.groupe, 'classe', g.libelle,
           'debut', r.debut, 'minutes', r.minutes,
           'elevesPresents', r.presents, 'elevesInscrits', r.inscrits,
           'montant', CASE WHEN r.en_attente THEN NULL
                           ELSE private.bf1_montant(coalesce(r.montant, 0), v_devise) END,
           'enAttente', r.en_attente)
           ORDER BY r.debut, r.seance), '[]'::jsonb),
         coalesce(sum(r.montant), 0)
    INTO v_seances, v_total
    FROM private.pai_releve_seances(v_debut, v_fin) r
    JOIN public.groupes g ON g.id = r.groupe
   WHERE r.enseignant = p_enseignant;

  -- REVENUS-VERITE point 5 : les autres revenus du mois, payables avec la
  -- paie, comptes dans le total.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', a.id, 'nature', a.nature, 'libelle', a.libelle,
           'montant', private.bf1_montant(a.montant_minor, a.devise),
           'attribueLe', a.attribue_le)
           ORDER BY a.attribue_le, a.id), '[]'::jsonb),
         coalesce(sum(a.montant_minor), 0)
    INTO v_autres, v_total_autres
    FROM private.autres_revenus_du(p_enseignant, v_mois) a;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'enseignant', pg_catalog.jsonb_build_object(
      'enseignantId', v_prof.id, 'prenom', v_prof.first_name, 'nom', v_prof.last_name),
    'seances', v_seances,
    'autres', v_autres,
    'totalSeances', private.bf1_montant(v_total, v_devise),
    'totalAutres', private.bf1_montant(v_total_autres, v_devise),
    'total', private.bf1_montant(v_total + v_total_autres, v_devise));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Droits et commentaires
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.autres_revenus_du(uuid,date)'::pg_catalog.regprocedure,
    'private.autres_revenus_mois(date)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.autre_revenu_attribuer(uuid,date,text,text,bigint,text)'::pg_catalog.regprocedure,
    'public.autre_revenu_annuler(uuid)'::pg_catalog.regprocedure,
    'public.autres_revenus_lister(uuid,date)'::pg_catalog.regprocedure,
    'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure,
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;

  COMMENT ON FUNCTION public.autre_revenu_attribuer(uuid, date, text, text, bigint, text) IS
    'REVENUS-VERITE point 5 : la direction attribue a un enseignant un autre revenu du mois (aide Internet, prime, mission), payable avec la paie. Garde: admin + compte valide. Idempotence par cle. Journal log_sensitive_access. date=2026-11-06.';
  COMMENT ON FUNCTION public.autre_revenu_annuler(uuid) IS
    'REVENUS-VERITE point 5 : la direction annule un autre revenu (annule_le, jamais d''effacement). Garde: admin + compte valide. Journal log_sensitive_access. date=2026-11-06.';
  COMMENT ON FUNCTION public.autres_revenus_lister(uuid, date) IS
    'REVENUS-VERITE point 5 : les autres revenus d''un enseignant pour un mois, la capacite peutAttribuer (admin) et l''aide Internet de la politique. Garde: private.pai_releve_autorise (admin, comptable). date=2026-11-06.';
  COMMENT ON FUNCTION public.mes_revenus_enseignant(date) IS
    'BF1-01, FAC-E-02, PAIE-REMPLACANT, REVENUS-VERITE : revenus de l''enseignant connecte, lus dans tresorerie_mouvements (remuneration_due) pour les seances dont il est l''enseignant effectif ; par classe, par seance et par eleve, la fenetre du jour de paie, et les autres revenus du mois (aide Internet, primes, missions). Garde: teacher + compte valide; perimetre auth.uid(). date=2026-11-06.';

  FOREACH v_oid IN ARRAY ARRAY[
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-06. B2.5, PAIE-REMPLACANT, REVENUS-VERITE point 5 : releve mensuel de la paie des enseignants, seances (tresorerie_mouvements, remuneration_due, enseignant effectif) plus autres revenus du mois (aide Internet, primes, missions) ; garde: admin ou accountant + compte valide ; lecture seule.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.autres_revenus_du(uuid,date)'::pg_catalog.regprocedure,
    'private.autres_revenus_mois(date)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'AUTRES-REVENUS : aide privee % exposee ou mal declaree', v_oid;
    END IF;
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.autre_revenu_attribuer(uuid,date,text,text,bigint,text)'::pg_catalog.regprocedure,
    'public.autre_revenu_annuler(uuid)'::pg_catalog.regprocedure,
    'public.autres_revenus_lister(uuid,date)'::pg_catalog.regprocedure,
    'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure,
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'AUTRES-REVENUS : DEFINER, search_path ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.revenus_enseignant_autres'::pg_catalog.regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'public.revenus_enseignant_autres', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.revenus_enseignant_autres', 'SELECT') THEN
    RAISE EXCEPTION 'AUTRES-REVENUS : la table doit rester fermee aux clients, RLS activee';
  END IF;
END;
$postflight$;

COMMIT;
