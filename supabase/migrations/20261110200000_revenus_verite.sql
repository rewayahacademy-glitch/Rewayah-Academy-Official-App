-- REVENUS-VERITE, points 2, 3, 4 et 6 (pilote, 06/11/2026 ; PLAN-LOTS 22 j).
--
-- Instructions destructives : aucune (ni effacement de lignes, ni retrait d'objet, ni vidage). Un INSERT de reglage (ON CONFLICT DO
-- NOTHING), une fonction de controle et son declencheur crees, une lecture
-- publique remplacee (CREATE OR REPLACE, meme signature :
-- mes_revenus_enseignant), une lecture publique creee
-- (apercu_paie_enseignant), droits, commentaires et verifications.
--
-- La regle de paie en vigueur (DECISION-TARIFS-2026-10-18, paie du 19/10,
-- redite le 06/11) : l'enseignant est paye par seance, par eleve present et
-- par heure (taux enfant, taux adulte de la politique) ; un absent n'est
-- jamais paye ; aucun minimum garanti. Le montant d'une seance est ecrit une
-- seule fois par `private.pai_due_seance` dans `tresorerie_mouvements`
-- (remuneration_due) : rien ici ne le recalcule, tout le relit.
--
-- 1. `public.mes_revenus_enseignant(date)` (preflight md5 ci-dessous) :
--    * retire `regle.base`, `regle.plafond` (fourchette du modele abandonne le
--      18-19/10) et `siegesEligibles` (qui comptait les absents), par classe
--      et au total. `regle` reste : nul quand aucune regle ne s'applique au
--      mois (l'ecran dit « pas encore publies »), sinon
--      {"parElevePresent": vrai|faux} ;
--    * ajoute `seances` : chaque seance du mois dont l'enseignant connecte est
--      l'enseignant effectif (PAIE-REMPLACANT), relue dans
--      `private.pai_releve_seances` (source du releve de la direction, la meme
--      que la paie), avec sa duree payee, son montant ecrit (0 quand aucun
--      eleve n'etait present, nul quand la direction doit encore trancher) et
--      chaque eleve inscrit : present ou absent (`private.presence_temps_reel`,
--      source de `pai_eleves_presents`), et ce qu'il a rapporte ; `attente`
--      dit pourquoi un versement attend : 'cahier' (cahier de la semaine
--      manquant, montant montre) ou 'direction' (duree a trancher, montant
--      nul). La part d'un
--      eleve present est le montant ecrit de la seance partage a parts egales
--      entre les presents, le reste des centimes aux premiers dans l'ordre du
--      prenom : la somme des parts vaut toujours le montant ecrit ;
--    * ajoute `versement` : la fenetre du jour de paie du mois, lue dans le
--      reglage `paie.fenetre_versement` (defaut : du 1er au 10 du mois
--      suivant), bornee a la longueur du mois.
-- 2. `paie.fenetre_versement` : reglage de `app_config`
--    {"jourDebut": 1, "jourFin": 10}, modifiable par la direction (policies
--    d'`app_config` : administration seulement), verifie par un declencheur
--    (deux entiers, 1 <= debut <= fin <= 28).
-- 3. `public.apercu_paie_enseignant(jsonb, text, integer)` : l'apercu de la
--    page Politique commerciale, selon la regle par eleve present : pour un
--    brouillon, un type de classe et un nombre d'eleves presents, le taux par
--    eleve present, ce que rapporte une heure, et ce que rapporte un absent
--    (toujours 0). `apercu_politique_enseignant` (base + occupation +
--    plafond) n'est plus appelee par l'application ; elle reste en base :
--    la retirer demanderait de retirer un objet.
BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : la fonction remplacee est bien celle du depot.
--    md5(prosrc) de la base rejouee (20261018130000 + commentaire
--    20261102300000) ; le pilote compare a la production avant l'installation.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5 FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure;
  RAISE NOTICE 'REVENUS-VERITE preflight : md5(prosrc) mes_revenus_enseignant = %', v_md5;
  IF v_md5 IS DISTINCT FROM '56a1d64499261533fd7479e80a34b4bf' THEN
    RAISE EXCEPTION 'REVENUS-VERITE : mes_revenus_enseignant differe du depot (md5 %), rien n''est change', v_md5;
  END IF;
  IF pg_catalog.to_regprocedure('public.apercu_paie_enseignant(jsonb,text,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'REVENUS-VERITE : apercu_paie_enseignant existe deja';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le reglage du jour de paie
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.paie_valider_fenetre_versement()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_debut integer;
  v_fin integer;
BEGIN
  IF NEW.key IS DISTINCT FROM 'paie.fenetre_versement' THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'object'
     OR pg_catalog.jsonb_typeof(NEW.value -> 'jourDebut') IS DISTINCT FROM 'number'
     OR pg_catalog.jsonb_typeof(NEW.value -> 'jourFin') IS DISTINCT FROM 'number' THEN
    RAISE EXCEPTION 'jour de paie : {"jourDebut": n, "jourFin": n} attendu' USING ERRCODE = '22023';
  END IF;
  v_debut := (NEW.value ->> 'jourDebut')::numeric::integer;
  v_fin := (NEW.value ->> 'jourFin')::numeric::integer;
  IF (NEW.value ->> 'jourDebut')::numeric <> v_debut OR (NEW.value ->> 'jourFin')::numeric <> v_fin
     OR v_debut < 1 OR v_fin > 28 OR v_debut > v_fin THEN
    RAISE EXCEPTION 'jour de paie : deux jours entiers, 1 <= debut <= fin <= 28' USING ERRCODE = '22023';
  END IF;
  NEW.value := pg_catalog.jsonb_build_object('jourDebut', v_debut, 'jourFin', v_fin);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_paie_fenetre_versement
BEFORE INSERT OR UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION private.paie_valider_fenetre_versement();

INSERT INTO public.app_config (key, value)
VALUES ('paie.fenetre_versement', '{"jourDebut": 1, "jourFin": 10}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Les revenus de l'enseignant connecte
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
    'allocationInternet', NULL);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. L'apercu de la direction, par eleve present
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.apercu_paie_enseignant(p_politique jsonb, p_public text, p_presents integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
  v_capacite integer;
  v_taux bigint;
BEGIN
  IF NOT private.fac_lecteur_politique() THEN
    RAISE EXCEPTION 'apercu reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_public IS NULL OR p_public NOT IN ('enfants', 'adultes', 'debutants') THEN
    RAISE EXCEPTION 'type de classe inconnu' USING ERRCODE = '22023';
  END IF;
  v := private.fac_politique_lue(p_politique);
  v_capacite := CASE p_public WHEN 'adultes' THEN v.capacite_adulte
                              WHEN 'debutants' THEN v.capacite_debutant
                              ELSE v.capacite_enfant END;
  v_taux := CASE p_public WHEN 'adultes' THEN v.taux_eleve_heure_adulte_mineur
                          ELSE v.taux_eleve_heure_enfant_mineur END;
  IF v_taux IS NULL THEN
    RAISE EXCEPTION 'cette version ne porte pas de taux par eleve present' USING ERRCODE = '22023';
  END IF;
  IF v_capacite IS NULL OR v_capacite < 1 OR p_presents IS NULL
     OR p_presents < 0 OR p_presents > v_capacite THEN
    RAISE EXCEPTION 'eleves presents hors bornes' USING ERRCODE = '22023';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'type', p_public,
    'capacite', v_capacite,
    'presents', p_presents,
    'tauxEleveHeure', private.bf1_montant(v_taux, v.devise),
    'montantHeure', private.bf1_montant(v_taux * p_presents, v.devise),
    'montantAbsent', private.bf1_montant(0, v.devise));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Droits et commentaires
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  v_oid := 'private.paie_valider_fenetre_versement()'::pg_catalog.regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
    END IF;
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure,
    'public.apercu_paie_enseignant(jsonb,text,integer)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;

  COMMENT ON FUNCTION public.mes_revenus_enseignant(date) IS
    'BF1-01, FAC-E-02, PAIE-REMPLACANT, REVENUS-VERITE : revenus de l''enseignant connecte, lus dans tresorerie_mouvements (remuneration_due) pour les seances dont il est l''enseignant effectif ; par classe, par seance et par eleve (present ou absent, part du montant ecrit), et la fenetre du jour de paie (paie.fenetre_versement). Ni base, ni plafond, ni sieges. Garde: teacher + compte valide; perimetre auth.uid(). DEFINER: tresorerie fermee a l''enseignant. date=2026-11-06.';
  COMMENT ON FUNCTION public.apercu_paie_enseignant(jsonb, text, integer) IS
    'REVENUS-VERITE : apercu de la Politique commerciale, paie par eleve present et par heure (taux du brouillon, type de classe, eleves presents) ; un absent rapporte 0. Garde: private.fac_lecteur_politique (direction, comptabilite). date=2026-11-06.';
  COMMENT ON FUNCTION public.apercu_politique_enseignant(jsonb, integer, integer) IS
    'FAC-A-01 : apercu du modele abandonne (base garantie, occupation, plafond). Plus appele par l''application depuis REVENUS-VERITE (06/11/2026) : remplace par apercu_paie_enseignant.';
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure,
    'public.apercu_paie_enseignant(jsonb,text,integer)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'REVENUS-VERITE : DEFINER, volatilite ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.paie_valider_fenetre_versement()'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.pai_due_seance(uuid,public.politiques_commerciales)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'REVENUS-VERITE : le calcul de la paie doit rester au serveur';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'paie.fenetre_versement') THEN
    RAISE EXCEPTION 'REVENUS-VERITE : reglage paie.fenetre_versement absent';
  END IF;
END;
$postflight$;

COMMIT;
