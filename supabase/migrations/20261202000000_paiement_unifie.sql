-- PAIEMENT-UNIFIE (directeur et pilote, 23/11/2026) : lots P2 (preparation), P4, P5 et P6 de
-- `docs/current/PAIEMENT/STRATEGIE-PAIEMENT-2026-11-23.md`. Rien n'est recree : on corrige et on branche
-- l'existant. Aucune table. Aucun mot de suppression.
--
-- Tout ce qui est nouveau dort derriere trois reglages `app_config`, que la direction ou le pilote
-- allume le jour voulu (aucun paiement Stripe reel n'a encore abouti : fermer des acces avant cette
-- preuve serait imprudent) :
--   paiement.taxe_stripe_active          faux  Stripe Tax : le total paye peut depasser le prix (P2) ;
--   paiement.premier_avant_cours         faux  le premier paiement est demande a l'entree en classe et
--                                              ferme l'acces s'il n'arrive pas (P4, P6) ;
--   paiement.delai_jours                 3     delai avant que la place soit liberee (P6).
--
-- 1. Deux aides privees, qui DEDUISENT l'etat des tables existantes (factures, credits, suspensions,
--    remises) : `fac_deja_paye` et `fac_etat_paiement` (a_payer, paye, en_retard, exonere).
-- 2. P4 : `private.acces_paye` dit « jamais paye » (apres le delai, reglage allume) ; le jeton de
--    l'eleve passe par la meme porte.
-- 3. P6 : la suspension de la nuit attend le delai pour une premiere facture ; l'entree en classe
--    emet la premiere facture et previent la famille (reglage allume).
-- 4. P2 : `recharge_evenement_stripe` accepte un total superieur au prix quand la taxe s'ajoute
--    (reglage allume, taxe plafonnee a 30 %) ; le credit reste le prix hors taxes de la commande.
-- 5. P5 : la fiche de l'eleve rend son etat de paiement ; `demander_paiement_maintenant`, la seule
--    fonction nouvelle, emet la facture du mois et previent la famille.

-- ---------------------------------------------------------------------------
-- 0. Reglages.
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('paiement.taxe_stripe_active', 'false'::jsonb),
  ('paiement.premier_avant_cours', 'false'::jsonb),
  ('paiement.delai_jours', '3'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 1. L'etat de paiement d'un eleve, deduit de l'existant.
-- ---------------------------------------------------------------------------
-- Vrai quand un paiement confirme a deja credite l'eleve, ou qu'une facture non nulle a deja ete
-- financee (une facture a 0, accordee par une remise, n'est pas un paiement).
CREATE OR REPLACE FUNCTION private.fac_deja_paye(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.wallet_entries e
                  WHERE e.beneficiaire_id = p_profil AND e.reference_type = 'credit')
      OR EXISTS (SELECT 1 FROM public.factures_mensuelles f
                  WHERE f.profile_id = p_profil AND f.statut = 'financee' AND f.total_mineur > 0);
$function$;

-- L'etat, en quatre mots : `en_retard` (acces suspendu, ou premiere facture non payee apres le
-- delai quand le reglage est allume), `exonere` (acces offert ou remise de 100 % ce mois-ci),
-- `a_payer` (une facture attend, ou rien n'a encore ete paye), `paye`.
CREATE OR REPLACE FUNCTION private.fac_etat_paiement(p_profil uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN private.fac_eleve_suspendu(p_profil) THEN 'en_retard'
    WHEN coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                    WHERE c.key = 'paiement.premier_avant_cours'), false)
         AND NOT private.fac_deja_paye(p_profil)
         AND NOT private.fac_bourse_couvre(p_profil, private.fac_mois_courant())
         AND EXISTS (SELECT 1 FROM public.factures_mensuelles f
                      WHERE f.profile_id = p_profil AND f.statut = 'a_financer' AND f.total_mineur > 0
                        AND f.emise_le < pg_catalog.clock_timestamp()
                              - pg_catalog.make_interval(days => coalesce((
                                  SELECT (c.value #>> '{}')::integer FROM public.app_config c
                                   WHERE c.key = 'paiement.delai_jours'), 3)))
      THEN 'en_retard'
    WHEN private.fac_bourse_couvre(p_profil, private.fac_mois_courant()) THEN 'exonere'
    WHEN EXISTS (SELECT 1 FROM public.factures_mensuelles f
                  WHERE f.profile_id = p_profil AND f.statut = 'a_financer' AND f.total_mineur > 0)
      THEN 'a_payer'
    WHEN private.fac_deja_paye(p_profil) THEN 'paye'
    ELSE 'a_payer'
  END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. P4 : la porte unique.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.acces_paye(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  -- Un eleve suspendu pour paiement n'a pas d'acces (FAC-F) ; ni celui dont la premiere facture reste
  -- impayee passe le delai (P4). `fac_etat_paiement` lit les deux ; l'appel a `fac_eleve_suspendu`
  -- reste explicite pour la lecture de cette porte.
  SELECT NOT private.fac_eleve_suspendu(p_profil)
     AND private.fac_etat_paiement(p_profil) <> 'en_retard';
$function$;

-- Remplace [p_ancre] par [p_neuf] dans la definition actuelle de [p_fonction], une seule fois (meme
-- methode que 20261104900000), puis rafraichit l'empreinte F86 de son commentaire.
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PAIEMENT-UNIFIE : ancre trouvee % fois dans %', v_n, p_fonction;
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

-- Le jeton de l'eleve passe par la meme porte : suspendu OU premiere facture impayee passe le delai.
SELECT pg_temp.remplacer('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure,
$a$  if v_role = 'student' and private.fac_eleve_suspendu(p_profile_id) then$a$,
$b$  if v_role = 'student' and (private.fac_eleve_suspendu(p_profile_id)
                             or not private.acces_paye(p_profile_id)) then$b$);

-- ---------------------------------------------------------------------------
-- 3. P6 : le moment du premier paiement.
-- ---------------------------------------------------------------------------
-- La suspension de la nuit attend le delai (reglage `paiement.delai_jours`) pour une premiere facture :
-- la famille a le temps de payer apres l'avis. Une famille qui a deja paye n'est pas concernee.
SELECT pg_temp.remplacer('private.fac_traiter_relances(date)'::regprocedure,
$a$         OR private.fac_eleve_suspendu(f.profile_id) THEN$a$,
$b$         OR private.fac_eleve_suspendu(f.profile_id)
         OR (NOT private.fac_deja_paye(f.profile_id)
             AND f.emise_le >= pg_catalog.clock_timestamp()
                   - pg_catalog.make_interval(days => coalesce((
                       SELECT (c.value #>> '{}')::integer FROM public.app_config c
                        WHERE c.key = 'paiement.delai_jours'), 3))) THEN$b$);

-- L'entree dans une classe (la famille a choisi ses creneaux) emet la premiere facture et previent la
-- famille : « derniere etape : payer ». Reglage `paiement.premier_avant_cours` ; une erreur ici ne
-- bloque jamais l'entree en classe.
CREATE OR REPLACE FUNCTION private.fac_premier_paiement_a_l_entree()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.left_at IS NOT NULL
     OR NOT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                       WHERE c.key = 'paiement.premier_avant_cours'), false) THEN
    RETURN NEW;
  END IF;
  BEGIN
    IF NOT private.fac_deja_paye(NEW.student_id)
       AND NOT private.fac_bourse_couvre(NEW.student_id, private.fac_mois_courant())
       AND private.fac_emettre_facture(NEW.student_id, private.fac_mois_courant(), NULL) THEN
      PERFORM private.fac_financer_profil(NEW.student_id);
      IF private.fac_etat_paiement(NEW.student_id) = 'a_payer'
         AND EXISTS (SELECT 1 FROM public.factures_mensuelles f
                      WHERE f.profile_id = NEW.student_id AND f.statut = 'a_financer'
                        AND f.total_mineur > 0) THEN
        PERFORM private.fac_notifier_paiement(NEW.student_id, 'paiement_relance',
          pg_catalog.jsonb_build_object('premier', true,
            'remboursement_jours', (private.fac_politique_au(private.fac_mois_courant())).remboursement_delai_jours,
            'delai_jours', coalesce((
            SELECT (c.value #>> '{}')::integer FROM public.app_config c
             WHERE c.key = 'paiement.delai_jours'), 3)));
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupe_membres_premier_paiement
  AFTER INSERT ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION private.fac_premier_paiement_a_l_entree();

-- ---------------------------------------------------------------------------
-- 4. P2 : la taxe de Stripe Tax s'ajoute au prix, jamais au credit.
-- ---------------------------------------------------------------------------
-- Reglage eteint : le total paye est exactement celui de la commande, comme avant. Reglage allume :
-- le total peut le depasser de la taxe (30 % au plus), jamais lui etre inferieur ; le credit de la
-- famille reste le prix hors taxes arrete par le serveur.
SELECT pg_temp.remplacer(
  'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure,
$a$    ELSIF p_montant IS DISTINCT FROM v_c.total_mineur
          OR pg_catalog.upper(coalesce(p_devise, '')) <> v_c.devise THEN$a$,
$b$    ELSIF p_montant IS NULL OR p_montant < v_c.total_mineur
          OR (p_montant > v_c.total_mineur
              AND (NOT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                                  WHERE c.key = 'paiement.taxe_stripe_active'), false)
                   OR p_montant > v_c.total_mineur + (v_c.total_mineur * 3) / 10))
          OR pg_catalog.upper(coalesce(p_devise, '')) <> v_c.devise THEN$b$);

-- ---------------------------------------------------------------------------
-- 5. P5 : la fiche de l'eleve dit son etat de paiement.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.fiche_eleve_direction(uuid)'::regprocedure,
$a$    'progression', v_progression);$a$,
$b$    'progression', v_progression,
    'paiement', pg_catalog.jsonb_build_object(
      'etat', private.fac_etat_paiement(p_eleve_id),
      'deja_paye', private.fac_deja_paye(p_eleve_id),
      'facture', (SELECT pg_catalog.jsonb_build_object(
                    'mois', pg_catalog.to_char(f.mois, 'YYYY-MM-DD'),
                    'total_mineur', f.total_mineur, 'devise', f.devise,
                    'statut', f.statut, 'emise_le', f.emise_le)
                    FROM public.factures_mensuelles f
                   WHERE f.profile_id = p_eleve_id AND f.statut <> 'annulee'
                   ORDER BY f.mois DESC LIMIT 1),
      'remise', (SELECT pg_catalog.jsonb_build_object(
                   'nature', b.nature, 'pour_mille', b.pour_mille,
                   'montant_mineur', b.montant_mineur, 'devise', b.devise,
                   'mois_fin', pg_catalog.to_char(b.mois_fin, 'YYYY-MM-DD'))
                   FROM public.bourses_eleves b
                  WHERE b.profile_id = p_eleve_id AND b.retiree_le IS NULL
                    AND b.mois_fin >= private.fac_mois_courant() LIMIT 1)));$b$);

-- ---------------------------------------------------------------------------
-- 6. P5 : « demander le paiement maintenant », la seule fonction nouvelle.
-- ---------------------------------------------------------------------------
-- Emet la facture du mois de l'eleve (idempotent), la finance si un credit ou une remise la couvre,
-- puis previent la famille s'il reste quelque chose a payer. Refus : 42501 pas la direction ; 22023
-- eleve introuvable.
CREATE FUNCTION public.demander_paiement_maintenant(p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_mois date := private.fac_mois_courant();
  v_emise boolean;
  v_avertis integer := 0;
  v_etat text;
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'demande de paiement reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_profil IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
        WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = '22023';
  END IF;
  v_emise := private.fac_emettre_facture(p_profil, v_mois, auth.uid());
  PERFORM private.fac_financer_profil(p_profil);
  v_etat := private.fac_etat_paiement(p_profil);
  IF v_etat IN ('a_payer', 'en_retard')
     AND EXISTS (SELECT 1 FROM public.factures_mensuelles f
                  WHERE f.profile_id = p_profil AND f.statut = 'a_financer' AND f.total_mineur > 0) THEN
    v_avertis := private.fac_notifier_paiement(p_profil, 'paiement_relance',
      pg_catalog.jsonb_build_object('premier', NOT private.fac_deja_paye(p_profil),
        'remboursement_jours', (private.fac_politique_au(private.fac_mois_courant())).remboursement_delai_jours,
        'delai_jours', coalesce((
        SELECT (c.value #>> '{}')::integer FROM public.app_config c
         WHERE c.key = 'paiement.delai_jours'), 3)));
  END IF;
  PERFORM public.log_sensitive_access('paiement_demande', 'profiles', p_profil::text,
    pg_catalog.jsonb_build_object('mois', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
      'facture_emise', v_emise, 'destinataires', v_avertis, 'etat', v_etat));
  RETURN pg_catalog.jsonb_build_object('etat', v_etat, 'facture_emise', v_emise, 'avertis', v_avertis);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Droits et empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.fac_deja_paye(uuid)', 'private.fac_etat_paiement(uuid)',
    'private.fac_premier_paiement_a_l_entree()', 'private.acces_paye(uuid)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', v_f);
  END LOOP;
END;
$droits$;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.fac_deja_paye(uuid), private.fac_etat_paiement(uuid), private.fac_premier_paiement_a_l_entree() FROM agent_ro';
  END IF;
END;
$agent$;

ALTER FUNCTION public.demander_paiement_maintenant(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.demander_paiement_maintenant(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_paiement_maintenant(uuid) TO authenticated;
DO $empreinte$
DECLARE
  v_oid regprocedure := 'public.demander_paiement_maintenant(uuid)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-23. PAIEMENT-UNIFIE P5 : demander le paiement maintenant.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$empreinte$;

-- ---------------------------------------------------------------------------
-- 8. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.demander_paiement_maintenant(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.demander_paiement_maintenant(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.fac_etat_paiement(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.fac_deja_paye(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PAIEMENT-UNIFIE : droits invalides';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.acces_paye(uuid)'::regprocedure),
                       'fac_eleve_suspendu') = 0 THEN
    RAISE EXCEPTION 'PAIEMENT-UNIFIE : acces_paye ne lit plus les suspensions';
  END IF;
  IF (SELECT count(*) FROM public.app_config WHERE key IN ('paiement.taxe_stripe_active',
       'paiement.premier_avant_cours', 'paiement.delai_jours')) <> 3 THEN
    RAISE EXCEPTION 'PAIEMENT-UNIFIE : reglages absents';
  END IF;
END;
$postflight$;
