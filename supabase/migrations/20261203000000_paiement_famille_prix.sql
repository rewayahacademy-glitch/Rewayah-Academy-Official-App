-- PAIEMENT-FAMILLE-PRIX (directeur et pilote, 23/11/2026) : le prix d'une famille a plusieurs profils,
-- corrige et explique. Decisions : `docs/current/PAIEMENT/FAMILLE-SCENARIOS-2026-11-23.md` §6 (points 1,
-- 2, 3, 5, 6), defauts D1, D2, D3, D4, D5, S12. Rien n'est recree : on corrige l'existant
-- (`fac_mensualite`, `fac_rang_attendu`, `fac_prix_prepaiement`, `rch_offres`, `recharge_beneficiaires`,
-- `recharge_verifier_montants`, l'engagement de prepaiement), dans le meme circuit de paiement.
--
-- 1. D1, prorata : le denominateur est le nombre de seances que l'horaire recurrent de la classe donne sur
--    le mois ENTIER (plus seulement les seances deja creees). Une classe creee le 14 avec un eleve entre le 14
--    ne paie plus le mois plein. Le numerateur : les seances de l'horaire a partir de l'entree. La ligne de
--    prorata garde la date d'entree et « x seances sur y » pour l'expliquer a la famille.
-- 2. Rang : un profil a bourse, acces offert ou prix special ne prend AUCUN rang (sa facture n'en porte pas) ;
--    les profils qui paient gardent leur rang entre eux. Le rang attendu d'un mois pas encore facture suit
--    l'ordre d'inscription (profiles.created_at), comme l'emission de la nuit.
-- 3. Politique v2.2.0 (une version publiee est immuable : on en insere une nouvelle, copie de v2.1.0) : le 3e
--    inscrit et les suivants ont 15 % au lieu de 17 % ; le 2e reste a 8 %, le plafond de cumul a 25 %. Son
--    jour d'effet est le plus tard du 1er decembre 2026 et du jour d'installation : jamais retroactive, les
--    factures deja emises ne changent pas.
-- 4. Offres de 1 a 12 mois, au choix : 1 et 2 mois sans remise de prepaiement, 3 a 11 mois le taux
--    trimestriel de la politique, 12 mois le taux annuel ; remise de rang incluse, plafond de cumul applique ;
--    montants lus dans la politique, jamais en dur. La dette (factures a financer, ou la premiere facture pas
--    encore emise, au prorata) est TOUJOURS payee d'abord et montree a part : une offre = dette + N mois.
--    Aucune offre pour un profil sans classe ni creneau choisi ; avant son premier mois reel (creneau choisi,
--    classe sans enseignant) : un mois seulement. L'engagement de prepaiement accepte 1 a 12 mois et ne porte
--    que la part « avance » (jamais la dette), ce qui garde le remboursement juste. Les mois couverts sont FIGES au
--    recapitulatif : l'engagement prend exactement ces mois, et `recharge_payer` refuse avant le prestataire
--    (« le montant a changé, vérifiez à nouveau ») si la dette ou les mois ont change depuis la verification.
--    Le remboursement compte les mois commences au prix mensuel normal de la famille (remise de rang comprise ;
--    seule la remise de prepaiement est retiree), garde dans l'engagement (`prix_mensuel_mineur`).
-- 4 bis. Rang : une seule regle partout (apercu, offre, facture) : l'ordre d'inscription (`profiles.created_at`, puis
--    l'identifiant), sans les profils a bourse, acces offert ou prix special (`fac_rang_inscription`).
-- 5. Contrat d'explication : `recharge_beneficiaires` rend, par profil et par offre, le prix, chaque remise
--    appliquee, chaque remise non appliquee avec son code, le prorata, les mois de dette et les mois couverts.
--    `recharge_verifier_montants` n'accepte que ces offres (un profil une seule fois par recapitulatif) et
--    garde le nombre de mois ; aucun montant libre.
--
-- REECRITURE DE CHECK (seule exception admise aux mots de suppression) : cinq contraintes CHECK sont
-- supprimees puis recreees, avec les memes noms, pour ouvrir `nb_mois` de 1 a 12 et la formule `avance` :
-- engagements_prepaiement_check, _formule_check, _nb_mois_check ; recharges_recap_lignes_formule_check ;
-- commandes_recharge_allocations_formule_check. Aucune ligne n'est supprimee ni modifiee.
--
-- Aucun DELETE, aucun TRUNCATE. Rejouable : colonnes IF NOT EXISTS, contraintes recreees, fonctions OR REPLACE,
-- version de politique ON CONFLICT DO NOTHING, remplacements de texte exactement une fois ou erreur.

-- ---------------------------------------------------------------------------
-- 0. Preflight.
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.1.0') THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : la politique v2.1.0 manque';
  END IF;
  IF pg_catalog.to_regprocedure('private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.fac_emettre_facture(uuid,date,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.fn115c_montant_propose(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.recharge_payer(uuid,uuid)') IS NULL
     OR pg_catalog.to_regclass('public.demandes_horaires_famille') IS NULL
     OR pg_catalog.to_regclass('public.groupe_creneaux') IS NULL THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : un objet attendu manque';
  END IF;
END;
$preflight$;

-- Outil de la migration (detruit avec la session) : remplace [p_ancre] par [p_neuf] dans la definition
-- actuelle de [p_fonction], exactement une fois, puis rafraichit l'empreinte F86 de son commentaire.
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n = 0 AND pg_catalog.strpos(v_def, p_neuf) > 0 THEN
    RETURN;  -- deja remplace : rejeu sans effet
  END IF;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : ancre trouvee % fois dans % : %', v_n, p_fonction, pg_catalog.left(p_ancre, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- Rafraichit l'empreinte F86 d'une fonction recreee en entier.
CREATE OR REPLACE FUNCTION pg_temp.empreinte(p_fonction regprocedure)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_com text := pg_catalog.obj_description(p_fonction, 'pg_proc');
BEGIN
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1. Tables : l'engagement de 1 a 12 mois, la dette et le nombre de mois des lignes de paiement.
-- ---------------------------------------------------------------------------
ALTER TABLE public.engagements_prepaiement DROP CONSTRAINT IF EXISTS engagements_prepaiement_check;
ALTER TABLE public.engagements_prepaiement DROP CONSTRAINT IF EXISTS engagements_prepaiement_formule_check;
ALTER TABLE public.engagements_prepaiement DROP CONSTRAINT IF EXISTS engagements_prepaiement_nb_mois_check;
ALTER TABLE public.engagements_prepaiement
  ADD CONSTRAINT engagements_prepaiement_formule_check CHECK (formule IN ('avance', 'trimestriel', 'annuel')),
  ADD CONSTRAINT engagements_prepaiement_nb_mois_check CHECK (nb_mois BETWEEN 1 AND 12),
  ADD CONSTRAINT engagements_prepaiement_check CHECK (
    formule = CASE WHEN nb_mois >= 12 THEN 'annuel' WHEN nb_mois >= 3 THEN 'trimestriel' ELSE 'avance' END);

-- Le prix mensuel NORMAL (tarif moins la remise de rang, sans la remise de prepaiement) que la famille avait au
-- moment de payer : le remboursement des mois commences le relit (decision DECISION-TARIFS point 3).
ALTER TABLE public.engagements_prepaiement
  ADD COLUMN IF NOT EXISTS prix_mensuel_mineur bigint CHECK (prix_mensuel_mineur > 0);

ALTER TABLE public.recharges_recap_lignes DROP CONSTRAINT IF EXISTS recharges_recap_lignes_formule_check;
ALTER TABLE public.recharges_recap_lignes
  ADD CONSTRAINT recharges_recap_lignes_formule_check
    CHECK (formule IN ('libre', 'mois', 'avance', 'trimestriel', 'annuel')),
  ADD COLUMN IF NOT EXISTS nb_mois smallint CHECK (nb_mois BETWEEN 1 AND 12),
  ADD COLUMN IF NOT EXISTS dette_mineur bigint NOT NULL DEFAULT 0 CHECK (dette_mineur >= 0),
  ADD COLUMN IF NOT EXISTS mois_debut date,
  ADD COLUMN IF NOT EXISTS prix_mensuel_mineur bigint;

ALTER TABLE public.commandes_recharge_allocations DROP CONSTRAINT IF EXISTS commandes_recharge_allocations_formule_check;
ALTER TABLE public.commandes_recharge_allocations
  ADD CONSTRAINT commandes_recharge_allocations_formule_check
    CHECK (formule IN ('libre', 'mois', 'avance', 'trimestriel', 'annuel')),
  ADD COLUMN IF NOT EXISTS nb_mois smallint CHECK (nb_mois BETWEEN 1 AND 12),
  ADD COLUMN IF NOT EXISTS dette_mineur bigint NOT NULL DEFAULT 0 CHECK (dette_mineur >= 0),
  ADD COLUMN IF NOT EXISTS mois_debut date,
  ADD COLUMN IF NOT EXISTS prix_mensuel_mineur bigint;

COMMENT ON COLUMN public.recharges_recap_lignes.dette_mineur IS
  'PAIEMENT-FAMILLE-PRIX : la part du montant qui paie la dette (factures a financer, premiere facture au prorata) ; le reste est l''avance de nb_mois mois.';
COMMENT ON COLUMN public.commandes_recharge_allocations.dette_mineur IS
  'PAIEMENT-FAMILLE-PRIX : la part du montant qui paie la dette ; l''engagement de prepaiement ne porte que le reste.';

-- ---------------------------------------------------------------------------
-- 2. Politique v2.2.0 : 15 % au 3e inscrit et suivants.
-- ---------------------------------------------------------------------------
INSERT INTO public.politiques_commerciales
SELECT (pg_catalog.jsonb_populate_record(NULL::public.politiques_commerciales,
          pg_catalog.to_jsonb(p) || pg_catalog.jsonb_build_object(
            'version', 'v2.2.0',
            'date_effet', greatest(DATE '2026-12-01', private.fac_aujourdhui()),
            'remises_par_rang',
              '[{"a_partir_du_rang":2,"pour_mille":80},{"a_partir_du_rang":3,"pour_mille":150}]'::jsonb,
            'publiee_par', NULL,
            'publiee_le', pg_catalog.clock_timestamp()))).*
  FROM public.politiques_commerciales p
 WHERE p.version = 'v2.1.0'
   AND greatest(DATE '2026-12-01', private.fac_aujourdhui()) > (SELECT max(q.date_effet) FROM public.politiques_commerciales q)
ON CONFLICT DO NOTHING;
INSERT INTO public.politique_part_enseignant
  (politique_version, part_enfant_pour_mille, part_adulte_pour_mille, decision_ref)
SELECT 'v2.2.0', x.part_enfant_pour_mille, x.part_adulte_pour_mille,
       pg_catalog.left(x.decision_ref || ' ; reprise pour v2.2.0 (PAIEMENT-FAMILLE-PRIX, decision du directeur du 23/11/2026)', 300)
  FROM public.politique_part_enseignant x
 WHERE x.politique_version = 'v2.1.0'
   AND EXISTS (SELECT 1 FROM public.politiques_commerciales p WHERE p.version = 'v2.2.0')
ON CONFLICT DO NOTHING;
INSERT INTO public.repartitions_paiement
  (politique_version, base_eleves_enfants, base_eleves_adultes, postes)
SELECT 'v2.2.0', r.base_eleves_enfants, r.base_eleves_adultes, r.postes
  FROM public.repartitions_paiement r
 WHERE r.politique_version = 'v2.1.0'
   AND EXISTS (SELECT 1 FROM public.politiques_commerciales p WHERE p.version = 'v2.2.0')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Aides de calcul (privees).
-- ---------------------------------------------------------------------------
-- Le taux (pour mille) de la remise de rang, ou nul (politique en montants, v1, ou rang sans palier).
CREATE OR REPLACE FUNCTION private.rch_remise_pour_mille(p public.politiques_commerciales, p_rang integer)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT (r ->> 'pour_mille')::integer
    FROM pg_catalog.jsonb_array_elements(p.remises_par_rang) AS r
   WHERE r ? 'pour_mille' AND p_rang IS NOT NULL
     AND (r ->> 'a_partir_du_rang')::integer <= p_rang
   ORDER BY (r ->> 'a_partir_du_rang')::integer DESC
   LIMIT 1;
$function$;

-- Les seances que l'horaire recurrent de la classe donne sur le mois ENTIER (existantes ou non), a l'heure
-- locale de la classe.
CREATE OR REPLACE FUNCTION private.rch_seances_mois(p_groupe uuid, p_mois date)
RETURNS TABLE (debut timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT ((d::date + pg_catalog.make_interval(hours => c.hour_local::integer))::timestamp
            AT TIME ZONE g.timezone_iana)
    FROM public.groupes g
    JOIN public.groupe_creneaux c ON c.groupe_id = g.id
   CROSS JOIN pg_catalog.generate_series(p_mois::timestamp,
                (p_mois + interval '1 month' - interval '1 day')::timestamp, interval '1 day') AS d
   WHERE g.id = p_groupe
     AND pg_catalog.date_part('isodow', d) = c.weekday;
$function$;

-- Le prorata expliquable d'un profil pour un mois : date d'entree, seances restantes, seances du mois.
CREATE OR REPLACE FUNCTION private.rch_prorata_info(p_profil uuid, p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adh public.groupe_membres := private.fac_adhesion(p_profil, p_mois);
  v_o integer;
  v_e integer;
BEGIN
  IF v_adh.id IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT count(*)::integer, (count(*) FILTER (WHERE s.debut >= v_adh.joined_at))::integer
    INTO v_o, v_e
    FROM private.rch_seances_mois(v_adh.groupe_id, p_mois) s;
  RETURN pg_catalog.jsonb_build_object(
    'entreeLe', pg_catalog.to_char((v_adh.joined_at AT TIME ZONE private.bf1_fuseau_comptable())::date, 'YYYY-MM-DD'),
    'seancesRestantes', v_e,
    'seancesDuMois', v_o);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. D1 (prorata sur l'horaire du mois entier) et rang sans bourse.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.fac_mensualite(
  p_profil uuid, p_mois date, p public.politiques_commerciales,
  p_rang integer, p_premier boolean)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_tarif bigint := coalesce(private.fac_tarif_profil(p_profil, p), 0);
  v_remise bigint;
  v_base bigint;
  v_lignes jsonb;
  v_adh public.groupe_membres;
  v_o integer;
  v_e integer;
  v_prorata bigint := 0;
  v_bourse public.bourses_eleves := private.fac_bourse(p_profil, p_mois);
  v_eng public.engagements_prepaiement;
  v_part bigint;
  v_info jsonb := '{}'::jsonb;
BEGIN
  v_lignes := pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nature', 'tarif', 'montant', private.bf1_montant(v_tarif, p.devise), 'rang', NULL));
  IF v_bourse.id IS NOT NULL THEN
    IF v_bourse.montant_mineur IS NOT NULL THEN
      -- Lot A, 02/11/2026 : prix special en montant mensuel hors taxes.
      v_base := CASE WHEN v_bourse.devise = p.devise
                     THEN least(v_bourse.montant_mineur, v_tarif) ELSE v_tarif END;
    ELSE
      v_remise := -((v_tarif * v_bourse.pour_mille + 500) / 1000);
      v_base := greatest(v_tarif + v_remise, 0);
    END IF;
    -- Lot A : « remise » dit a la famille ce qu'est la ligne (acces offert,
    -- prix special) ; « nature » reste « bourse » pour les lecteurs, et la
    -- ligne d'une bourse de la politique ne change pas.
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', 'bourse', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', NULL)
      || CASE WHEN v_bourse.nature = 'bourse' THEN '{}'::jsonb
              ELSE pg_catalog.jsonb_build_object('remise', v_bourse.nature) END);
  ELSE
    v_remise := CASE WHEN p_rang IS NULL THEN NULL ELSE private.fac_remise_montant(p, p_rang, v_tarif) END;
    v_base := greatest(v_tarif + coalesce(v_remise, 0), 0);
    IF v_remise IS NOT NULL THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nature', 'remise_rang', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', p_rang));
    END IF;
    SELECT e.* INTO v_eng FROM public.engagements_prepaiement e
     WHERE e.profile_id = p_profil AND e.devise = p.devise
       AND p_mois >= e.mois_debut
       AND p_mois < (e.mois_debut + pg_catalog.make_interval(months => e.nb_mois))::date
     ORDER BY e.cree_le LIMIT 1;
    IF v_eng.id IS NOT NULL THEN
      v_part := private.fac_part_engagement(v_eng, p_mois);
      IF v_part <> v_base THEN
        v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'nature', 'remise_prepaiement', 'montant', private.bf1_montant(v_part - v_base, p.devise), 'rang', NULL));
      END IF;
      v_base := v_part;
    END IF;
  END IF;

  IF p_premier AND v_eng.id IS NULL THEN
    v_adh := private.fac_adhesion(p_profil, p_mois);
    IF p.essais_max > 0 THEN
      -- Une politique avec essais garde le calcul sur les seances existantes (les seances d'essai se
      -- reperent par leur identifiant).
      SELECT count(*) FILTER (WHERE TRUE),
             count(*) FILTER (WHERE s.started_at >= coalesce(v_adh.joined_at, '-infinity'::timestamptz)
                                AND s.id NOT IN (SELECT e.session_id
                                                   FROM private.fac_seances_essai(p_profil, p.essais_max) e))
        INTO v_o, v_e
        FROM public.sessions s
       WHERE s.groupe_id = v_adh.groupe_id AND s.deleted_at IS NULL
         AND s.status NOT IN ('canceled', 'canceled_late')
         AND s.started_at >= p_mois AND s.started_at < (p_mois + interval '1 month');
    ELSE
      -- D1 (23/11/2026) : l'horaire recurrent de la classe sur le mois ENTIER, pas les seances deja creees.
      SELECT count(*), (count(*) FILTER (WHERE s.debut >= coalesce(v_adh.joined_at, '-infinity'::timestamptz)))
        INTO v_o, v_e
        FROM private.rch_seances_mois(v_adh.groupe_id, p_mois) s;
      v_info := pg_catalog.jsonb_build_object(
        'entree_le', pg_catalog.to_char((v_adh.joined_at AT TIME ZONE private.bf1_fuseau_comptable())::date, 'YYYY-MM-DD'),
        'seances_restantes', v_e, 'seances_du_mois', v_o);
    END IF;
    IF v_o = 0 THEN
      v_prorata := -v_base;
    ELSIF v_e < v_o THEN
      v_prorata := (v_base * v_e / v_o) - v_base;
    END IF;
    IF v_prorata <> 0 THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nature', 'prorata', 'montant', private.bf1_montant(v_prorata, p.devise), 'rang', NULL) || v_info);
    END IF;
  END IF;
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'total', v_base + v_prorata);
END;
$function$;

-- LE rang d'un profil (une seule regle, partout : apercu, offre, facture) : l'ordre d'inscription
-- (profiles.created_at, a egalite l'identifiant), sans les profils a bourse, acces offert ou prix special. Nul pour
-- un profil a bourse. Sont comptes les AUTRES profils du foyer, eux-memes sans bourse ce mois-la, plus anciens que lui
-- et qui paient : inscrits dans une classe (hors essai gratuit), ou deja factures ce mois-la avec un rang.
CREATE OR REPLACE FUNCTION private.fac_rang_inscription(p_profil uuid, p_mois date)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN (private.fac_bourse(p_profil, p_mois)).id IS NOT NULL THEN NULL
    ELSE 1 + (SELECT count(*)::integer
                FROM public.profiles pr
                JOIN public.profiles q ON q.household_id = pr.household_id AND q.id <> pr.id
                JOIN public.student_profiles sq ON sq.profile_id = q.id AND sq.deleted_at IS NULL
               WHERE pr.id = p_profil AND q.deleted_at IS NULL
                 AND (private.fac_bourse(q.id, p_mois)).id IS NULL
                 AND NOT private.fac_en_essai(q.id, private.fac_politique_au(p_mois))
                 AND (q.created_at, q.id) < (pr.created_at, pr.id)
                 AND (EXISTS (SELECT 1 FROM public.factures_mensuelles f
                               WHERE f.profile_id = q.id AND f.mois = p_mois AND f.statut <> 'annulee'
                                 AND f.rang_familial IS NOT NULL)
                      OR EXISTS (SELECT 1 FROM public.groupe_membres m
                                  JOIN public.groupes g ON g.id = m.groupe_id
                                 WHERE m.student_id = q.id AND m.left_at IS NULL
                                   AND g.ended_at IS NULL AND g.etat = 'active')))
  END;
$function$;

-- Le rang attendu : celui de la facture deja emise, sinon celui que la regle donne.
CREATE OR REPLACE FUNCTION private.fac_rang_attendu(p_profil uuid, p_mois date)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN (private.fac_bourse(p_profil, p_mois)).id IS NOT NULL THEN NULL
    ELSE coalesce(
      (SELECT f.rang_familial FROM public.factures_mensuelles f
        WHERE f.profile_id = p_profil AND f.mois = p_mois AND f.statut <> 'annulee'),
      private.fac_rang_inscription(p_profil, p_mois))
  END;
$function$;

-- L'emission d'une facture prend le MEME rang que l'apercu : l'ordre d'inscription, jamais l'ordre de paiement.
SELECT pg_temp.remplacer('private.fac_emettre_facture(uuid,date,uuid)'::regprocedure,
$a$  v_rang := 1 + (SELECT count(*) FROM public.factures_mensuelles f
                  WHERE f.household_id = v_foyer AND f.mois = p_mois AND f.statut <> 'annulee');$a$,
$b$  -- PAIEMENT-FAMILLE-PRIX : une seule regle de rang (l'ordre d'inscription, sans les profils a bourse, acces offert
  -- ou prix special), la meme que l'apercu et que les offres.
  v_rang := private.fac_rang_inscription(p_profil, p_mois);$b$);

-- ---------------------------------------------------------------------------
-- 5. Le prix de N mois payes d'avance, avec son explication.
-- ---------------------------------------------------------------------------
-- p_debut : le premier mois couvert. Rend nul quand rien ne se vend (pas de politique, prix nul, bourse qui
-- ne couvre pas tous les mois). `lignes` s'additionnent exactement a `totalMineur`.
CREATE OR REPLACE FUNCTION private.rch_prix_avance(p_profil uuid, p_debut date, p_nb integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.politiques_commerciales := private.fac_politique_au(p_debut);
  v_tarif bigint;
  b public.bourses_eleves;
  v_rang integer;
  v_pm integer;
  v_pre_pm integer;
  v_unite bigint;
  v_remise_f bigint;
  v_pre bigint;
  v_cap bigint;
  v_red bigint := 0;
  v_brut bigint;
  v_total bigint;
  v_lignes jsonb;
  v_non jsonb := '[]'::jsonb;
  v_formule text;
  v_code text;
  v_prix_unite bigint;
BEGIN
  IF p_nb IS NULL OR p_nb NOT BETWEEN 1 AND 12 OR p.version IS NULL THEN
    RETURN NULL;
  END IF;
  v_tarif := coalesce(private.fac_tarif_profil(p_profil, p), 0);
  IF v_tarif <= 0 THEN
    RETURN NULL;
  END IF;
  v_pre_pm := CASE WHEN p_nb >= 12 THEN p.prepaiement_annuel_pour_mille
                   WHEN p_nb >= 3 THEN p.prepaiement_trimestriel_pour_mille END;
  b := private.fac_bourse(p_profil, p_debut);
  IF b.id IS NOT NULL THEN
    -- Prix special, acces offert ou bourse : le prix du mois est celui de la facture, sans rang ni remise de
    -- prepaiement (non cumulable). La bourse doit couvrir tous les mois payes.
    IF b.mois_fin < (p_debut + pg_catalog.make_interval(months => p_nb - 1))::date THEN
      RETURN NULL;
    END IF;
    v_unite := CASE WHEN b.montant_mineur IS NOT NULL
                    THEN CASE WHEN b.devise = p.devise THEN least(b.montant_mineur, v_tarif) ELSE v_tarif END
                    ELSE greatest(v_tarif - ((v_tarif * b.pour_mille + 500) / 1000), 0) END;
    IF v_unite <= 0 THEN
      RETURN NULL;
    END IF;
    v_code := CASE b.nature WHEN 'prix_special' THEN 'prix_special_non_cumulable'
                            WHEN 'acces_offert' THEN 'acces_offert_non_cumulable'
                            ELSE 'bourse_non_cumulable' END;
    v_total := v_unite * p_nb;
    v_lignes := pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'code', 'prix', 'montant', private.bf1_montant(v_tarif * p_nb, p.devise), 'nbMois', p_nb));
    IF v_total <> v_tarif * p_nb THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'code', CASE b.nature WHEN 'bourse' THEN 'bourse' ELSE b.nature END,
        'montant', private.bf1_montant(v_total - v_tarif * p_nb, p.devise)));
    END IF;
    v_non := pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('type', 'remise_famille', 'code', v_code));
    IF v_pre_pm IS NOT NULL OR p_nb < 3 THEN
      v_non := v_non || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'type', 'remise_prepaiement', 'code', v_code));
    END IF;
    v_formule := 'libre';
    v_rang := NULL;
    v_prix_unite := v_unite;
  ELSE
    v_rang := private.fac_rang_attendu(p_profil, p_debut);
    v_unite := -coalesce(private.fac_remise_montant(p, v_rang, v_tarif), 0);
    v_pm := private.rch_remise_pour_mille(p, v_rang);
    v_remise_f := v_unite * p_nb;
    v_pre := CASE WHEN v_pre_pm IS NULL THEN 0 ELSE (v_tarif * p_nb * v_pre_pm + 500) / 1000 END;
    v_cap := CASE WHEN p.cumul_max_pour_mille IS NULL THEN NULL
                  ELSE (v_tarif * p_nb * p.cumul_max_pour_mille) / 1000 END;
    IF v_cap IS NOT NULL AND v_remise_f + v_pre > v_cap THEN
      v_red := v_remise_f + v_pre - v_cap;
    END IF;
    v_brut := v_tarif * p_nb - (v_remise_f + v_pre - v_red);
    -- Un prepaiement de 3 mois et plus s'arrondit au dollar (comme avant) ; 1 et 2 mois restent exacts : ils
    -- egalent la somme des factures.
    v_total := CASE WHEN v_pre_pm IS NOT NULL THEN ((v_brut + 50) / 100) * 100 ELSE v_brut END;
    v_lignes := pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'code', 'prix', 'montant', private.bf1_montant(v_tarif * p_nb, p.devise), 'nbMois', p_nb));
    IF v_remise_f > 0 THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'code', 'remise_famille', 'montant', private.bf1_montant(-v_remise_f, p.devise),
        'rang', v_rang, 'pourMille', v_pm));
    ELSIF v_rang = 1 THEN
      v_non := v_non || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'type', 'remise_famille', 'code', 'premier_inscrit'));
    END IF;
    IF v_pre > 0 THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'code', 'remise_prepaiement', 'montant', private.bf1_montant(-v_pre, p.devise), 'pourMille', v_pre_pm));
    ELSIF p_nb < 3 AND p.prepaiement_trimestriel_pour_mille IS NOT NULL THEN
      v_non := v_non || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'type', 'remise_prepaiement', 'code', 'moins_de_trois_mois'));
    END IF;
    IF v_red > 0 THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'code', 'plafond', 'montant', private.bf1_montant(v_red, p.devise), 'pourMille', p.cumul_max_pour_mille));
      v_non := v_non || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'type', 'remise', 'code', 'plafond_atteint', 'montant', private.bf1_montant(v_red, p.devise),
        'pourMille', p.cumul_max_pour_mille));
    END IF;
    IF v_total <> v_brut THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'code', 'arrondi', 'montant', private.bf1_montant(v_total - v_brut, p.devise)));
    END IF;
    v_formule := CASE WHEN p_nb >= 12 THEN 'annuel' WHEN p_nb >= 3 THEN 'trimestriel' ELSE 'avance' END;
    v_prix_unite := v_tarif - v_unite;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'totalMineur', v_total, 'unitaireMineur', v_prix_unite, 'devise', p.devise, 'nbMois', p_nb, 'formule', v_formule,
    'debut', pg_catalog.to_char(p_debut, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((p_debut + pg_catalog.make_interval(months => p_nb - 1))::date, 'YYYY-MM-DD'),
    'rang', v_rang, 'tarif', private.bf1_montant(v_tarif, p.devise), 'politique', p.version,
    'lignes', v_lignes, 'nonAppliquees', v_non);
END;
$function$;

-- Le prix d'un trimestre ou d'une annee (ancienne fonction, meme contrat) : nul sous bourse, prix special ou
-- acces offert (non cumulable).
CREATE OR REPLACE FUNCTION private.fac_prix_prepaiement(p_profil uuid, p_mois date, p_nb_mois integer)
RETURNS bigint
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF (private.fac_bourse(p_profil, p_mois)).id IS NOT NULL THEN
    RETURN NULL;
  END IF;
  RETURN (private.rch_prix_avance(p_profil, p_mois, p_nb_mois) ->> 'totalMineur')::bigint;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. L'etat du profil, sa dette, ses offres.
-- ---------------------------------------------------------------------------
-- en_classe : inscrit dans une classe avec enseignant (inscription en cours, pas une classe quittee) ;
-- avant_premier_mois : creneau choisi, ou classe encore sans enseignant ; aucun_creneau : ni classe ni creneau
-- choisi.
CREATE OR REPLACE FUNCTION private.rch_etat(p_profil uuid)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_etat text;
BEGIN
  SELECT g.etat INTO v_etat
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id
   WHERE m.student_id = p_profil AND m.left_at IS NULL AND g.ended_at IS NULL
   ORDER BY m.joined_at DESC, m.id
   LIMIT 1;
  IF FOUND THEN
    RETURN CASE WHEN v_etat = 'active' THEN 'en_classe' ELSE 'avant_premier_mois' END;
  END IF;
  IF EXISTS (SELECT 1 FROM public.demandes_horaires_famille d
              WHERE d.eleve_id = p_profil AND d.etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')) THEN
    RETURN 'avant_premier_mois';
  END IF;
  RETURN 'aucun_creneau';
END;
$function$;

-- La dette d'un profil : les factures a financer, plus la facture du mois en cours si elle n'est pas encore
-- emise (prorata compris), moins son solde. Chaque mois est explique.
CREATE OR REPLACE FUNCTION private.rch_dette(p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_m0 date := private.fac_mois_courant();
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_mois_courant());
  v_devise text := coalesce((SELECT w.currency FROM public.profiles pr JOIN public.wallets w ON w.household_id = pr.household_id
                              WHERE pr.id = p_profil), (private.fac_politique_au(private.fac_aujourdhui())).devise);
  f public.factures_mensuelles;
  v_calc jsonb;
  v_mois jsonb := '[]'::jsonb;
  v_brut bigint := 0;
  v_solde bigint := private.fac_solde_profil(p_profil);
  v_total bigint;
BEGIN
  FOR f IN SELECT * FROM public.factures_mensuelles x
            WHERE x.profile_id = p_profil AND x.statut = 'a_financer'
            ORDER BY x.mois, x.emise_le LOOP
    v_mois := v_mois || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'mois', pg_catalog.to_char(f.mois, 'YYYY-MM-DD'),
      'montant', private.bf1_montant(f.total_mineur, f.devise),
      'apercu', false,
      'lignes', f.lignes,
      'prorata', CASE WHEN f.lignes @> '[{"nature":"prorata"}]'::pg_catalog.jsonb
                      THEN private.rch_prorata_info(p_profil, f.mois) END));
    v_brut := v_brut + f.total_mineur;
  END LOOP;
  -- La premiere facture, pas encore emise : le serveur la calcule comme il l'emettra (prorata compris).
  IF v_pol.version IS NOT NULL AND private.rch_etat(p_profil) = 'en_classe'
     AND (private.fac_adhesion(p_profil, v_m0)).id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.factures_mensuelles x
                      WHERE x.profile_id = p_profil AND x.mois = v_m0 AND x.statut <> 'annulee')
     AND NOT private.fac_en_essai(p_profil, v_pol) THEN
    v_calc := private.fac_mensualite(p_profil, v_m0, v_pol, private.fac_rang_attendu(p_profil, v_m0),
      NOT EXISTS (SELECT 1 FROM public.factures_mensuelles x WHERE x.profile_id = p_profil AND x.statut <> 'annulee'));
    IF (v_calc ->> 'total')::bigint > 0 THEN
      v_mois := v_mois || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'mois', pg_catalog.to_char(v_m0, 'YYYY-MM-DD'),
        'montant', private.bf1_montant((v_calc ->> 'total')::bigint, v_pol.devise),
        'apercu', true,
        'lignes', v_calc -> 'lignes',
        'prorata', CASE WHEN v_calc -> 'lignes' @> '[{"nature":"prorata"}]'::pg_catalog.jsonb
                        THEN private.rch_prorata_info(p_profil, v_m0) END));
      v_brut := v_brut + (v_calc ->> 'total')::bigint;
    END IF;
  END IF;
  v_total := greatest(v_brut - v_solde, 0);
  RETURN pg_catalog.jsonb_build_object(
    'totalMineur', v_total, 'total', private.bf1_montant(v_total, v_devise),
    'solde', private.bf1_montant(v_solde, v_devise), 'mois', v_mois);
END;
$function$;

-- Vrai quand une ligne de recapitulatif est encore une offre du serveur : meme montant, memes mois d'avance, meme
-- dette, memes mois couverts (la dette ou le mois ont pu changer entre la verification et le paiement).
CREATE OR REPLACE FUNCTION private.rch_ligne_valide(
  p_profil uuid, p_montant bigint, p_nb integer, p_dette bigint, p_debut date)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  RETURN EXISTS (SELECT 1 FROM private.rch_options(p_profil) o
                  WHERE o.montant = p_montant AND o.nb_mois = coalesce(p_nb, 0)
                    AND o.dette = p_dette AND o.mois_debut IS NOT DISTINCT FROM p_debut);
END;
$function$;

-- Les offres d'un profil : dette seule (nb_mois 0), puis dette + N mois (1 a 12). Montants et mois lus du
-- serveur ; un seul chemin pour ce que l'ecran propose et ce que la verification accepte.
CREATE OR REPLACE FUNCTION private.rch_options(p_profil uuid)
RETURNS TABLE (nb_mois integer, formule text, montant bigint, dette bigint, avance bigint,
               mois_debut date, avance_detail jsonb)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_m0 date := private.fac_mois_courant();
  v_etat text := private.rch_etat(p_profil);
  v_d bigint := (private.rch_dette(p_profil) ->> 'totalMineur')::bigint;
  v_debut date;
  v_fin_eng date;
  v_a jsonb;
  n integer;
BEGIN
  IF v_d > 0 THEN
    RETURN QUERY SELECT 0, 'libre'::text, v_d, v_d, 0::bigint, NULL::date, NULL::jsonb;
  END IF;
  IF v_etat = 'en_classe' THEN
    -- Les mois payes d'avance commencent le mois suivant, apres tout engagement deja ouvert.
    SELECT max((e.mois_debut + pg_catalog.make_interval(months => e.nb_mois))::date) INTO v_fin_eng
      FROM public.engagements_prepaiement e WHERE e.profile_id = p_profil;
    v_debut := greatest((v_m0 + interval '1 month')::date, coalesce(v_fin_eng, v_m0));
    FOR n IN 1..12 LOOP
      v_a := private.rch_prix_avance(p_profil, v_debut, n);
      EXIT WHEN v_a IS NULL;
      RETURN QUERY SELECT n, v_a ->> 'formule', v_d + (v_a ->> 'totalMineur')::bigint, v_d,
                          (v_a ->> 'totalMineur')::bigint, v_debut, v_a;
    END LOOP;
  ELSIF v_etat = 'avant_premier_mois' THEN
    -- Avant le premier mois reel : un mois seulement, sans engagement (le mois couvert n'est pas connu).
    v_a := private.rch_prix_avance(p_profil, v_m0, 1);
    IF v_a IS NOT NULL THEN
      RETURN QUERY SELECT 1, 'mois'::text, v_d + (v_a ->> 'totalMineur')::bigint, v_d,
                          (v_a ->> 'totalMineur')::bigint, NULL::date, (v_a - 'debut' - 'fin');
    END IF;
  END IF;
END;
$function$;

-- Les montants proposes (ancien contrat : formule, montant), maintenant lus des offres.
CREATE OR REPLACE FUNCTION private.rch_offres(p_profil uuid)
RETURNS TABLE (formule text, montant bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT o.formule, o.montant FROM private.rch_options(p_profil) o WHERE o.montant > 0 ORDER BY o.montant;
$function$;

-- Le bloc d'explication d'un profil : etat, tarif, rang, dette mois par mois, offres avec leurs lignes.
CREATE OR REPLACE FUNCTION private.rch_explication(p_profil uuid, p_devise text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_m0 date := private.fac_mois_courant();
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_mois_courant());
BEGIN
  RETURN pg_catalog.jsonb_build_object(
    'etat', private.rch_etat(p_profil),
    'tarif', CASE WHEN v_pol.version IS NULL THEN NULL
                  ELSE private.bf1_montant(coalesce(private.fac_tarif_profil(p_profil, v_pol), 0), p_devise) END,
    'rang', private.fac_rang_attendu(p_profil, v_m0),
    'dette', private.rch_dette(p_profil) - 'totalMineur',
    'options', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'nbMois', o.nb_mois,
               'formule', o.formule,
               'montant', private.bf1_montant(o.montant, p_devise),
               'dette', private.bf1_montant(o.dette, p_devise),
               'avance', private.bf1_montant(o.avance, p_devise),
               'moisCouverts', CASE WHEN o.mois_debut IS NULL OR o.nb_mois = 0 THEN NULL
                 ELSE pg_catalog.jsonb_build_object(
                   'debut', pg_catalog.to_char(o.mois_debut, 'YYYY-MM-DD'),
                   'fin', pg_catalog.to_char((o.mois_debut + pg_catalog.make_interval(months => o.nb_mois - 1))::date, 'YYYY-MM-DD'),
                   'nbMois', o.nb_mois) END,
               'rang', o.avance_detail -> 'rang',
               'lignes', coalesce(o.avance_detail -> 'lignes', '[]'::jsonb),
               'nonAppliquees', coalesce(o.avance_detail -> 'nonAppliquees', '[]'::jsonb))
             ORDER BY o.montant)
        FROM private.rch_options(p_profil) o WHERE o.montant > 0), '[]'::jsonb));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Ce que l'ecran lit : les profils, leurs offres et leurs explications.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.recharge_beneficiaires()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_devise text;
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  v_devise := private.rch_devise(public.app_household_id());
  IF v_devise IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', x.id, 'prenom', x.first_name, 'cleAvatar', x.avatar_storage_key,
             'solde', private.bf1_montant(private.fac_solde_profil(x.id), v_devise),
             'montantsProposes', (SELECT coalesce(pg_catalog.jsonb_agg(private.bf1_montant(o.montant, v_devise)
                                    ORDER BY o.montant), '[]'::jsonb) FROM private.rch_offres(x.id) o),
             'formules', (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                             'montant', private.bf1_montant(o.montant, v_devise), 'formule', o.formule)
                             ORDER BY o.montant), '[]'::jsonb) FROM private.rch_offres(x.id) o),
             'montantSuggere', CASE WHEN (private.rch_dette(x.id) ->> 'totalMineur')::bigint > 0
                                    THEN private.bf1_montant((private.rch_dette(x.id) ->> 'totalMineur')::bigint, v_devise) END)
             || private.rch_explication(x.id, v_devise)
           ORDER BY x.first_name, x.id)
      FROM (SELECT p.id, p.first_name, sp.avatar_storage_key
              FROM public.profiles p
              JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
             WHERE p.deleted_at IS NULL AND p.household_id = public.app_household_id()) x), '[]'::jsonb);
END;
$function$;

-- Le recapitulatif : seules les offres du serveur passent (montant ET, si fourni, nombre de mois) ; un profil
-- une seule fois ; les lignes suivent l'ordre d'inscription, comme l'emission des factures.
CREATE OR REPLACE FUNCTION public.recharge_verifier_montants(p_choix jsonb)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid := public.app_household_id();
  v_devise text;
  v_id uuid;
  v_total bigint := 0;
  v_rang integer := 0;
  v_c jsonb;
  v_profil uuid;
  v_montant bigint;
  v_nb integer;
  v_o record;
  v_vus uuid[] := ARRAY[]::uuid[];
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  IF p_choix IS NULL OR pg_catalog.jsonb_typeof(p_choix) <> 'array'
     OR pg_catalog.jsonb_array_length(p_choix) NOT BETWEEN 1 AND 20 THEN
    RAISE EXCEPTION 'choix invalides' USING ERRCODE = '22023';
  END IF;
  v_devise := private.rch_devise(v_foyer);
  IF v_devise IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  INSERT INTO public.recharges_recapitulatifs (titulaire, household_id, devise, total_mineur, expire_le)
  VALUES (auth.uid(), v_foyer, v_devise, 1, pg_catalog.clock_timestamp() + interval '1 hour')
  RETURNING id INTO v_id;
  FOR v_c IN
    SELECT x.j
      FROM pg_catalog.jsonb_array_elements(p_choix) AS x(j)
      LEFT JOIN public.profiles pr
        ON pr.id = (CASE WHEN pg_catalog.jsonb_typeof(x.j -> 'profilId') = 'string'
                          AND (x.j ->> 'profilId') ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
                         THEN (x.j ->> 'profilId')::uuid END)
     ORDER BY pr.created_at NULLS LAST, pr.id
  LOOP
    BEGIN
      v_profil := (v_c ->> 'profilId')::uuid;
      v_montant := (v_c ->> 'mineur')::bigint;
      v_nb := CASE WHEN v_c ? 'nbMois' AND pg_catalog.jsonb_typeof(v_c -> 'nbMois') <> 'null'
                   THEN (v_c ->> 'nbMois')::integer END;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'choix invalide' USING ERRCODE = '22023';
    END;
    IF v_profil IS NULL OR NOT private.rch_beneficiaire(v_profil) THEN
      RAISE EXCEPTION 'profil hors du foyer' USING ERRCODE = '42501';
    END IF;
    IF v_profil = ANY (v_vus) THEN
      RAISE EXCEPTION 'profil en double' USING ERRCODE = '22023';
    END IF;
    v_vus := v_vus || v_profil;
    SELECT o.* INTO v_o FROM private.rch_options(v_profil) o
     WHERE o.montant = v_montant AND o.montant > 0 AND (v_nb IS NULL OR o.nb_mois = v_nb);
    IF (v_c ->> 'devise') IS DISTINCT FROM v_devise OR v_o.formule IS NULL THEN
      RAISE EXCEPTION 'montant non propose' USING ERRCODE = '22023';
    END IF;
    v_rang := v_rang + 1;
    INSERT INTO public.recharges_recap_lignes
      (recapitulatif_id, rang, profile_id, montant_mineur, formule, nb_mois, dette_mineur, mois_debut,
       prix_mensuel_mineur)
    VALUES (v_id, v_rang, v_profil, v_montant, v_o.formule,
            CASE WHEN v_o.nb_mois > 0 THEN v_o.nb_mois END, v_o.dette, v_o.mois_debut,
            (v_o.avance_detail ->> 'unitaireMineur')::bigint);
    v_total := v_total + v_montant;
  END LOOP;
  UPDATE public.recharges_recapitulatifs SET total_mineur = v_total WHERE id = v_id;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_id,
    'total', private.bf1_montant(v_total, v_devise),
    'lignes', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'beneficiaireId', l.profile_id, 'prenom', p.first_name,
                 'cleAvatar', sp.avatar_storage_key, 'formule', l.formule,
                 'nbMois', l.nb_mois,
                 'dette', private.bf1_montant(l.dette_mineur, v_devise),
                 'moisCouverts', CASE WHEN l.mois_debut IS NULL OR l.nb_mois IS NULL THEN NULL
                   ELSE pg_catalog.jsonb_build_object(
                     'debut', pg_catalog.to_char(l.mois_debut, 'YYYY-MM-DD'),
                     'fin', pg_catalog.to_char((l.mois_debut + pg_catalog.make_interval(months => l.nb_mois - 1))::date, 'YYYY-MM-DD'),
                     'nbMois', l.nb_mois) END,
                 'montant', private.bf1_montant(l.montant_mineur, v_devise)) ORDER BY l.rang)
                 FROM public.recharges_recap_lignes l
                 JOIN public.profiles p ON p.id = l.profile_id
                 LEFT JOIN public.student_profiles sp ON sp.profile_id = l.profile_id
                WHERE l.recapitulatif_id = v_id));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. La commande reprend le nombre de mois et la dette ; le paiement confirme ouvre l'engagement d'avance.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.recharge_payer(uuid,uuid)'::regprocedure,
$a$    INSERT INTO public.commandes_recharge_allocations (commande_id, rang, profile_id, montant_mineur, formule)
    SELECT v_c.id, l.rang, l.profile_id, l.montant_mineur, l.formule$a$,
$b$    INSERT INTO public.commandes_recharge_allocations
      (commande_id, rang, profile_id, montant_mineur, formule, nb_mois, dette_mineur, mois_debut,
       prix_mensuel_mineur)
    SELECT v_c.id, l.rang, l.profile_id, l.montant_mineur, l.formule, l.nb_mois, l.dette_mineur, l.mois_debut,
           l.prix_mensuel_mineur$b$);
-- Avant la commande (donc avant Stripe) : chaque ligne doit encore etre une offre du serveur, avec les memes
-- mois et la meme dette. Sinon rien ne part : la famille verifie de nouveau.
SELECT pg_temp.remplacer('public.recharge_payer(uuid,uuid)'::regprocedure,
$a$    INSERT INTO public.commandes_recharge
      (id, reference, recapitulatif_id$a$,
$b$    IF EXISTS (SELECT 1 FROM public.recharges_recap_lignes l
                WHERE l.recapitulatif_id = v_r.id
                  AND NOT private.rch_ligne_valide(l.profile_id, l.montant_mineur, l.nb_mois, l.dette_mineur, l.mois_debut)) THEN
      RAISE EXCEPTION 'le montant a changé, vérifiez à nouveau' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.commandes_recharge
      (id, reference, recapitulatif_id$b$);
SELECT pg_temp.remplacer('public.recharge_payer(uuid,uuid)'::regprocedure,
$a$'formule', a.formule, 'mois', private.fac_mois_courant()) ORDER BY a.rang)$a$,
$b$'formule', a.formule, 'nbMois', a.nb_mois, 'mois', private.fac_mois_courant()) ORDER BY a.rang)$b$);

SELECT pg_temp.remplacer('public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure,
$a$        IF a.formule IN ('trimestriel', 'annuel') THEN
          INSERT INTO public.engagements_prepaiement
            (profile_id, formule, mois_debut, nb_mois, total_mineur, devise, commande_id)
          VALUES (a.profile_id, a.formule, v_suivant, CASE a.formule WHEN 'trimestriel' THEN 3 ELSE 12 END,
                  a.montant_mineur, v_c.devise, v_c.id);
        END IF;$a$,
$b$        -- PAIEMENT-FAMILLE-PRIX : N mois (1 a 12) payes d'avance ouvrent un engagement sur EXACTEMENT les mois
        -- figes au recapitulatif (jamais « le mois suivant maintenant ») ; il ne porte que la part « avance »
        -- (jamais la dette). Un surplus eventuel reste au solde du profil, visible.
        IF a.formule IN ('avance', 'trimestriel', 'annuel') AND a.nb_mois IS NOT NULL
           AND a.mois_debut IS NOT NULL AND a.montant_mineur > a.dette_mineur THEN
          INSERT INTO public.engagements_prepaiement
            (profile_id, formule, mois_debut, nb_mois, total_mineur, devise, commande_id, prix_mensuel_mineur)
          VALUES (a.profile_id,
                  CASE WHEN a.nb_mois >= 12 THEN 'annuel' WHEN a.nb_mois >= 3 THEN 'trimestriel' ELSE 'avance' END,
                  a.mois_debut, a.nb_mois, a.montant_mineur - a.dette_mineur, v_c.devise, v_c.id,
                  a.prix_mensuel_mineur);
        END IF;$b$);

-- Remboursement d'un engagement apres le delai : les mois commences au prix mensuel NORMAL (le prix que la famille
-- avait, remise de rang comprise ; seule la remise de la formule de prepaiement est retiree : DECISION-TARIFS
-- point 3), le reste rendu, sur la part « avance » seulement (la dette paie un mois deja consomme).
SELECT pg_temp.remplacer('private.fn115c_montant_propose(uuid,uuid)'::regprocedure,
$a$      v_montant := GREATEST(v_paye - v_mois * v_mensuel - v_rendu - v_en_cours, 0);$a$,
$b$      v_montant := GREATEST(v_e.total_mineur - v_mois * coalesce(v_e.prix_mensuel_mineur, v_mensuel)
                            - v_rendu - v_en_cours, 0);$b$);

-- ---------------------------------------------------------------------------
-- 9. Droits et empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.rch_remise_pour_mille(public.politiques_commerciales,integer)'::regprocedure,
    'private.rch_seances_mois(uuid,date)'::regprocedure,
    'private.rch_prorata_info(uuid,date)'::regprocedure,
    'private.rch_prix_avance(uuid,date,integer)'::regprocedure,
    'private.rch_etat(uuid)'::regprocedure,
    'private.rch_dette(uuid)'::regprocedure,
    'private.rch_options(uuid)'::regprocedure,
    'private.rch_ligne_valide(uuid,bigint,integer,bigint,date)'::regprocedure,
    'private.fac_rang_inscription(uuid,date)'::regprocedure,
    'private.rch_explication(uuid,text)'::regprocedure,
    'private.rch_offres(uuid)'::regprocedure,
    'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure,
    'private.fac_rang_attendu(uuid,date)'::regprocedure,
    'private.fac_prix_prepaiement(uuid,date,integer)'::regprocedure,
    'private.fac_emettre_facture(uuid,date,uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  PERFORM pg_temp.empreinte('public.recharge_beneficiaires()'::regprocedure);
  PERFORM pg_temp.empreinte('public.recharge_verifier_montants(jsonb)'::regprocedure);
  PERFORM pg_temp.empreinte('public.recharge_payer(uuid,uuid)'::regprocedure);
  PERFORM pg_temp.empreinte('public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure);
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 10. Postflight.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_beneficiaires()'::regprocedure,
    'public.recharge_verifier_montants(jsonb)'::regprocedure,
    'public.recharge_payer(uuid,uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : la confirmation Stripe doit rester au serveur';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND (p.proname LIKE 'fac\_%' OR p.proname LIKE 'rch\_%')
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : aide privee executable par un client';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.fac_emettre_facture(uuid,date,uuid)'::regprocedure),
                       'PAIEMENT-FAMILLE-PRIX') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure),
                       'PAIEMENT-FAMILLE-PRIX') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.fn115c_montant_propose(uuid,uuid)'::regprocedure),
                       'v_e.total_mineur - v_mois') = 0 THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : un remplacement de texte manque';
  END IF;
  IF EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.1.0')
     AND NOT EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.2.0') THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : v2.2.0 non inseree (une version occupe deja la date)';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.politiques_commerciales a, public.politiques_commerciales b
     WHERE a.version = 'v2.1.0' AND b.version = 'v2.2.0'
       AND (pg_catalog.to_jsonb(a) - ARRAY['version','date_effet','remises_par_rang','publiee_par','publiee_le'])
           IS DISTINCT FROM
           (pg_catalog.to_jsonb(b) - ARRAY['version','date_effet','remises_par_rang','publiee_par','publiee_le'])) THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : v2.2.0 differe de v2.1.0 ailleurs que par les remises de rang';
  END IF;
  IF EXISTS (SELECT 1 FROM public.politiques_commerciales WHERE version = 'v2.2.0'
               AND remises_par_rang <> '[{"a_partir_du_rang":2,"pour_mille":80},{"a_partir_du_rang":3,"pour_mille":150}]'::jsonb) THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-PRIX : remises de rang de v2.2.0 inattendues';
  END IF;
END;
$postflight$;
