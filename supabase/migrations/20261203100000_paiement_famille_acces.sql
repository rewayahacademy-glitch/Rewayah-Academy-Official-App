-- PAIEMENT-FAMILLE-ACCES (directeur et pilote, 23/11/2026) : points D6 et D7 de
-- `docs/current/PAIEMENT/FAMILLE-SCENARIOS-2026-11-23.md` (§6, points 7 et 8). Aucun mot de suppression,
-- aucune migration modifiee : les fonctions sont recreees (CREATE OR REPLACE) ou retouchees a un passage ancre.
--
-- D6, « un compte = une personne » : l'acces a une Classe ou a une seance se juge sur le profil CONNECTE.
--   * si ce profil a sa propre place d'eleve dans la seance (ou la Classe), seul SON paiement compte ;
--     un tuteur-eleve impaye ne passe plus grace au paiement de son enfant, et ne peut pas non plus
--     « observer » sa propre classe pour la suivre sans payer ;
--   * sinon, un tuteur accompagne un enfant de son foyer (observateur masque, jamais compte comme eleve,
--     donc jamais dans les presents payes : `pai_eleves_presents` ne compte que le role `student`),
--     seulement si CET enfant a un acces paye. Un enfant qui entre depuis l'appareil de son tuteur
--     (`autoriser_jeton_video_eleve`) est juge sur son propre paiement : inchange, deja correct.
--   * `entrer_observation` : l'enfant accompagne n'est jamais le tuteur lui-meme, et un tuteur qui a sa
--     place d'eleve ne la remplace plus par une place d'observateur.
--   * Une seule connexion a la fois par profil : l'identite LiveKit du jeton est l'identifiant du profil
--     (`autoriser_jeton_video` : `v_identite := p_profile_id::text`, signee par create-room-token). Un second
--     appareil du meme profil porte la meme identite : LiveKit coupe la premiere connexion. Rien a changer.
-- D7, frais d'une contestation bancaire perdue : a la FAMILLE (le payeur), jamais au solde d'un enfant.
--   * table `dettes_famille` (RLS) ; `remboursement_evenement_stripe` y ecrit les frais au lieu d'une ligne
--     d'ajustement negative au rang 1, donc plus de `fac_rouvrir_si_negatif` pour les frais : aucun cours deja
--     paye n'est coupe ;
--   * tant qu'une dette est ouverte, la famille ne peut ni ajouter un enfant, ni demander une nouvelle classe,
--     ni prepayer (au-dela de ce qui est du) ; payer ce qui est du reste permis ;
--   * `ma_dette_famille()` (le tuteur la lit, avec son motif) et `regler_dette_famille(...)` (direction seule,
--     tracee).

-- ---------------------------------------------------------------------------
-- 0. Retouche d'une fonction par un passage ancre (meme methode que 20261202000000).
-- ---------------------------------------------------------------------------
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  -- Rejouable : deja retouchee, rien a faire.
  IF pg_catalog.strpos(v_def, p_neuf) > 0 THEN
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES : ancre trouvee % fois dans %', v_n, p_fonction;
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

-- ---------------------------------------------------------------------------
-- 1. D6 : l'acces se juge sur le profil connecte et sa propre place.
-- ---------------------------------------------------------------------------
-- Une seance. Place propre : seul son paiement compte. Sinon un tuteur accompagne un enfant du foyer
-- (autre profil que lui) qui est dans la seance et dont l'acces est paye.
CREATE OR REPLACE FUNCTION private.acces_paye_seance_pour(p_session uuid, p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM private.acces_eleves_seance(p_session) e(id) WHERE e.id = p_profil)
      THEN private.acces_paye(p_profil)
    ELSE EXISTS (
      SELECT 1
        FROM private.acces_eleves_seance(p_session) e(id)
        JOIN public.profiles c ON c.id = e.id AND c.deleted_at IS NULL
        JOIN public.profiles moi ON moi.id = p_profil
       WHERE moi.role = 'guardian' AND moi.household_id IS NOT NULL
         AND c.household_id = moi.household_id AND c.id <> moi.id
         AND private.acces_paye(c.id))
  END;
$function$;

-- Une Classe : meme regle.
CREATE OR REPLACE FUNCTION private.acces_paye_groupe_pour(p_groupe uuid, p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM public.groupe_membres m
                  WHERE m.groupe_id = p_groupe AND m.left_at IS NULL AND m.student_id = p_profil)
      THEN private.acces_paye(p_profil)
    ELSE EXISTS (
      SELECT 1
        FROM public.groupe_membres m
        JOIN public.profiles c ON c.id = m.student_id AND c.deleted_at IS NULL
        JOIN public.profiles moi ON moi.id = p_profil
       WHERE m.groupe_id = p_groupe AND m.left_at IS NULL
         AND moi.role = 'guardian' AND moi.household_id IS NOT NULL
         AND c.household_id = moi.household_id AND c.id <> moi.id
         AND private.acces_paye(c.id))
  END;
$function$;

-- L'appelant, hors de toute seance (ressources ouvertes a tous les inscrits) : s'il est lui-meme eleve,
-- son propre paiement ; sinon un tuteur avec un enfant de son foyer a acces paye.
CREATE OR REPLACE FUNCTION private.acces_paye_appelant()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN public.app_role() IN ('student', 'guardian')
      THEN CASE
        WHEN EXISTS (SELECT 1 FROM public.student_profiles sp
                      WHERE sp.profile_id = auth.uid() AND sp.deleted_at IS NULL)
          THEN private.acces_paye(auth.uid())
        ELSE EXISTS (
          SELECT 1
            FROM public.student_profiles sp
            JOIN public.profiles c ON c.id = sp.profile_id AND c.deleted_at IS NULL
            JOIN public.profiles moi ON moi.id = auth.uid()
           WHERE sp.deleted_at IS NULL
             AND moi.role = 'guardian' AND moi.household_id IS NOT NULL
             AND c.household_id = moi.household_id AND c.id <> moi.id
             AND private.acces_paye(c.id))
      END
    ELSE true END;
$function$;

-- Droits inchanges (CREATE OR REPLACE les garde) ; reaffirmes.
ALTER FUNCTION private.acces_paye_seance_pour(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION private.acces_paye_groupe_pour(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION private.acces_paye_appelant() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.acces_paye_seance_pour(uuid, uuid), private.acces_paye_groupe_pour(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.acces_paye_appelant() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.acces_paye_appelant() TO authenticated;

-- Entrer en observation : l'enfant accompagne n'est pas le tuteur ; un tuteur qui a sa place d'eleve
-- dans la seance ne la remplace pas par une place d'observateur.
-- (L'enfant accompagne : de preference un enfant dont l'acces est paye, pour que le journal de visite
-- nomme celui qu'on accompagne vraiment.)
SELECT pg_temp.remplacer('public.entrer_observation(uuid,text)'::regprocedure,
$a$       and public.est_du_foyer(m.student_id)
     limit 1;$a$,
$b$       and public.est_du_foyer(m.student_id)
       and m.student_id <> auth.uid()
     order by private.acces_paye(m.student_id) desc
     limit 1;$b$);

SELECT pg_temp.remplacer('public.entrer_observation(uuid,text)'::regprocedure,
$a$  -- 4. Politique du groupe -- guardian_observer seulement.$a$,
$b$  -- PAIEMENT-FAMILLE-ACCES (23/11/2026), D6 : un tuteur qui est aussi eleve de cette seance y entre
  -- comme eleve, sur son propre paiement, jamais comme observateur.
  if v_role = 'guardian_observer'
     and exists (select 1 from private.acces_eleves_seance(p_session_id) e(id) where e.id = auth.uid()) then
    return jsonb_build_object('autorise', false, 'motif_refus', 'place_eleve');
  end if;

  -- 4. Politique du groupe -- guardian_observer seulement.$b$);

-- ---------------------------------------------------------------------------
-- 2. D7 : la dette de la famille.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dettes_famille (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES public.households(id),
  commande_id uuid REFERENCES public.commandes_recharge(id),
  litige_id text UNIQUE REFERENCES public.litiges_paiement(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  motif text NOT NULL CHECK (motif IN ('frais_contestation_perdue')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  reglee_le timestamptz,
  reglee_par uuid REFERENCES public.profiles(id),
  regle_motif text,
  CHECK ((reglee_le IS NULL) = (regle_motif IS NULL))
);
CREATE INDEX IF NOT EXISTS dettes_famille_ouvertes ON public.dettes_famille (household_id) WHERE reglee_le IS NULL;
ALTER TABLE public.dettes_famille ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.dettes_famille FROM PUBLIC, anon, authenticated;
-- Le tuteur de la famille lit les siennes ; la direction et la comptabilite toutes. Aucune ecriture par l'API.
DO $politique$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'dettes_famille'
                    AND policyname = 'dettes_famille_lecture') THEN
    CREATE POLICY dettes_famille_lecture ON public.dettes_famille
      FOR SELECT TO authenticated
      USING (coalesce(
               (SELECT public.app_role()) IN ('admin', 'accountant')
               OR ((SELECT public.app_role()) = 'guardian' AND household_id = (SELECT public.app_household_id())),
               false)
             AND (SELECT public.app_account_valid()));
  END IF;
END;
$politique$;
GRANT SELECT ON public.dettes_famille TO authenticated;
COMMENT ON TABLE public.dettes_famille IS
  'D7 (23/11/2026) : dette de la famille (frais d''une contestation bancaire perdue). Bloque les nouveaux achats et inscriptions du foyer, jamais les cours deja payes. Ecrite par remboursement_evenement_stripe, reglee par regler_dette_famille.';

CREATE OR REPLACE FUNCTION private.dette_famille_ouverte(p_household uuid)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(sum(d.montant_mineur), 0)::bigint
    FROM public.dettes_famille d
   WHERE d.household_id = p_household AND d.reglee_le IS NULL;
$function$;

-- Les frais d'une contestation perdue vont a la famille, plus au solde du rang 1.
SELECT pg_temp.remplacer(
  'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)'::regprocedure,
$a$        SELECT a.profile_id INTO v_premier FROM public.commandes_recharge_allocations a
         WHERE a.commande_id = v_c.id ORDER BY a.rang LIMIT 1;
        v_w := private.fac_portefeuille(v_c.household_id, v_c.devise);
        INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id)
        VALUES (v_w.id, -v_frais, v_c.devise, 'adjustment', v_c.id, v_premier);
        PERFORM private.fac_rouvrir_si_negatif(v_premier, 'litige');$a$,
$b$        -- D7 (23/11/2026) : les frais vont a la FAMILLE (le payeur), jamais au solde d'un enfant : aucune
        -- facture rouverte, aucun cours deja paye coupe. Ils bloquent les nouveaux achats du foyer.
        INSERT INTO public.dettes_famille (household_id, commande_id, litige_id, montant_mineur, devise, motif)
        VALUES (v_c.household_id, v_c.id, v_l.id, v_frais, v_c.devise, 'frais_contestation_perdue')
        ON CONFLICT (litige_id) DO NOTHING;
        PERFORM public.log_sensitive_access('dette_famille_creee', 'dettes_famille', v_l.id,
          pg_catalog.jsonb_build_object('household_id', v_c.household_id, 'frais_mineur', v_frais));$b$);

-- La famille lit sa dette et son motif.
CREATE OR REPLACE FUNCTION public.ma_dette_famille()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve au tuteur du foyer' USING ERRCODE = '42501';
  END IF;
  v_foyer := public.app_household_id();
  RETURN pg_catalog.jsonb_build_object(
    'ouverte', private.dette_famille_ouverte(v_foyer) > 0,
    'total_mineur', private.dette_famille_ouverte(v_foyer),
    'lignes', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'id', d.id, 'montant_mineur', d.montant_mineur, 'devise', d.devise,
                 'motif', d.motif, 'cree_le', d.cree_le) ORDER BY d.cree_le)
                 FROM public.dettes_famille d
                WHERE d.household_id = v_foyer AND d.reglee_le IS NULL), '[]'::jsonb));
END;
$function$;

-- La direction reconnait le reglement d'une dette (virement recu, geste commercial) : tracee, motif obligatoire.
CREATE OR REPLACE FUNCTION public.regler_dette_famille(p_dette uuid, p_motif text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_d public.dettes_famille;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_motif IS NULL OR pg_catalog.length(pg_catalog.btrim(p_motif)) < 5 THEN
    RAISE EXCEPTION 'motif obligatoire' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_d FROM public.dettes_famille WHERE id = p_dette FOR UPDATE;
  IF v_d.id IS NULL THEN
    RAISE EXCEPTION 'dette introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_d.reglee_le IS NOT NULL THEN
    RETURN;
  END IF;
  UPDATE public.dettes_famille
     SET reglee_le = pg_catalog.clock_timestamp(), reglee_par = auth.uid(), regle_motif = pg_catalog.btrim(p_motif)
   WHERE id = v_d.id;
  PERFORM public.log_sensitive_access('dette_famille_reglee', 'dettes_famille', v_d.id::text,
    pg_catalog.jsonb_build_object('household_id', v_d.household_id, 'montant_mineur', v_d.montant_mineur));
END;
$function$;

-- Le blocage des nouveaux achats : un declencheur par porte, independant du corps des fonctions metier.
CREATE OR REPLACE FUNCTION private.dette_famille_bloque()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid;
BEGIN
  IF TG_TABLE_NAME = 'profiles' THEN
    IF NEW.role = 'student' THEN
      v_foyer := NEW.household_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'demandes_horaires_famille' THEN
    SELECT p.household_id INTO v_foyer FROM public.profiles p WHERE p.id = NEW.eleve_id;
  ELSIF TG_TABLE_NAME = 'recharges_recap_lignes' THEN
    -- Prepaiement : une ligne au-dela de ce qui est du. Payer ce qui est du reste permis.
    IF NEW.montant_mineur > private.fac_reste_a_payer(NEW.profile_id) THEN
      SELECT r.household_id INTO v_foyer FROM public.recharges_recapitulatifs r WHERE r.id = NEW.recapitulatif_id;
    END IF;
  END IF;
  IF v_foyer IS NOT NULL AND private.dette_famille_ouverte(v_foyer) > 0 THEN
    RAISE EXCEPTION 'DETTE_FAMILLE : une dette de la famille bloque ce nouvel achat tant qu''elle n''est pas reglee'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$function$;

DO $t$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger WHERE tgname = 'profiles_dette_famille' AND tgrelid = 'public.profiles'::regclass) THEN
    CREATE TRIGGER profiles_dette_famille BEFORE INSERT ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION private.dette_famille_bloque();
  END IF;
END;
$t$;
DO $t$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger WHERE tgname = 'demandes_horaires_dette_famille' AND tgrelid = 'public.demandes_horaires_famille'::regclass) THEN
    CREATE TRIGGER demandes_horaires_dette_famille BEFORE INSERT ON public.demandes_horaires_famille
      FOR EACH ROW EXECUTE FUNCTION private.dette_famille_bloque();
  END IF;
END;
$t$;
DO $t$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger WHERE tgname = 'recap_lignes_dette_famille' AND tgrelid = 'public.recharges_recap_lignes'::regclass) THEN
    CREATE TRIGGER recap_lignes_dette_famille BEFORE INSERT ON public.recharges_recap_lignes
      FOR EACH ROW EXECUTE FUNCTION private.dette_famille_bloque();
  END IF;
END;
$t$;

-- ---------------------------------------------------------------------------
-- 3. Droits et empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.dette_famille_ouverte(uuid)', 'private.dette_famille_bloque()'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', v_f);
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
    'public.ma_dette_famille()', 'public.regler_dette_famille(uuid,text)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role', v_f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_f);
  END LOOP;
END;
$droits$;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.dette_famille_ouverte(uuid), private.dette_famille_bloque(), public.ma_dette_famille(), public.regler_dette_famille(uuid,text) FROM agent_ro';
  END IF;
END;
$agent$;

DO $empreinte$
DECLARE
  v_oid regprocedure;
  v_type text;
BEGIN
  FOR v_oid, v_type IN SELECT * FROM (VALUES
      ('public.ma_dette_famille()'::regprocedure, 'ROLE_POSITIVE_GUARDIAN'),
      ('public.regler_dette_famille(uuid,text)'::regprocedure, 'ROLE_POSITIVE_ADMIN')) AS x(f, t) LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-23. PAIEMENT-FAMILLE-ACCES D7 : dette de la famille.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)), v_type));
  END LOOP;
END;
$empreinte$;

-- ---------------------------------------------------------------------------
-- 4. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)'::regprocedure),
                       'dettes_famille') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)'::regprocedure),
                       'fac_rouvrir_si_negatif(v_premier') > 0 THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES : les frais ne vont pas a la famille';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.entrer_observation(uuid,text)'::regprocedure), 'place_eleve') = 0 THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES : entrer_observation sans la place d''eleve';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.dettes_famille'::regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'public.dettes_famille', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.dettes_famille', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.dettes_famille', 'SELECT') THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES : dettes_famille mal fermee';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.ma_dette_famille()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.regler_dette_famille(uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_dette_famille()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.dette_famille_ouverte(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.acces_paye_seance_pour(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.acces_paye_appelant()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES : droits invalides';
  END IF;
END;
$postflight$;
