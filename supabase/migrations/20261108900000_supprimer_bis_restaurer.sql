-- SUPPRIMER-bis, partie serveur (garde-cap, 03/11/2026, 19:46 UTC) : la
-- reversibilite que la fiche PLAN-LOTS §12 exige (« reversible pendant le
-- delai de conservation »), absente de 20261108600000 (PR 198).
--
-- Ce que cette migration ajoute :
--   1. le journal des retraits garde l'etat d'avant (statut du compte, fin
--      d'acces, bannissement) et la restauration (quand, par qui) : colonnes
--      AJOUTEES a private.retraits_comptes ;
--   2. private.suppr_retirer note cet etat, et un compte restaure puis retire
--      de nouveau reprend sa ligne du journal (une ligne par profil, l'index
--      unique reste) ; private.suppr_anonymiser et suppr_anonymiser_echus
--      ignorent un retrait restaure ;
--   3. public.direction_restaurer_comptes(ids) : la direction en double
--      verification (aal2), 200 au plus, un resultat par identifiant. Seul un
--      retrait non encore anonymise se restaure : le profil revient dans les
--      listes, le compte retrouve son statut, sa fin d'acces et son
--      bannissement d'avant, une ligne d'audit est ecrite. L'eleve n'est PAS
--      remis dans ses classes : le retour le dit, la direction le reaffecte ;
--   4. public.retraits_comptes_lister(etat, curseur, limite) : la direction
--      en aal2, paginee par curseur (DECISION-LISTES), sans total : nom,
--      matricule, role, retrait, echeance, source, motif, anonymisation,
--      restauration.
--
-- Le tuteur ne restaure pas lui-meme un profil d'enfant qu'il a retire :
-- reglage PROPOSE (garde-cap, 03/11), rien n'est ecrit ailleurs ; il contacte
-- la direction.
--
-- Les retraits poses avant cette migration n'ont pas d'etat d'avant
-- (journal vide en production au 03/11, 19:44 UTC, selon le pilote) : leur
-- restauration est refusee (`etat_avant_inconnu`), jamais devinee.
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun mot d'effacement dans ce fichier.
-- Des colonnes ajoutees, trois fonctions remplacees a signature et droits
-- egaux, deux fonctions creees.

BEGIN;

-- 1. L'etat d'avant et la restauration -------------------------------------
ALTER TABLE private.retraits_comptes
  ADD COLUMN statut_avant public.account_status,
  ADD COLUMN acces_avant timestamptz,
  ADD COLUMN banni_avant timestamptz,
  ADD COLUMN restaure_le timestamptz,
  ADD COLUMN restaure_par uuid REFERENCES public.profiles(id);
ALTER TABLE private.retraits_comptes
  ADD CONSTRAINT retraits_comptes_restaure CHECK (
    (restaure_le IS NULL) = (restaure_par IS NULL)
    AND (restaure_le IS NULL OR anonymise_le IS NULL)
    AND (restaure_le IS NULL OR restaure_le >= retire_le));
COMMENT ON TABLE private.retraits_comptes IS
  'SUPPRIMER (03/11/2026) : un retrait de compte par la direction ou par un tuteur, son etat d''avant, son anonymisation a l''echeance ou sa restauration par la direction (SUPPRIMER-bis). Delai : app_config compte.anonymisation_delai_jours, 30 jours PROPOSE, en attente du juriste (CAND-Q21).';

-- 2. Le retrait note l'etat d'avant ------------------------------------------
CREATE OR REPLACE FUNCTION private.suppr_retirer(p_profil uuid, p_acteur uuid, p_source text, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_p public.profiles%ROWTYPE;
  v_delai integer;
  v_seances jsonb;
  v_retrait uuid;
  v_echeance timestamptz;
  v_banni timestamptz;
  v_avec_ban boolean;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = p_profil FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'introuvable');
  END IF;
  IF v_p.deleted_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'deja_retire');
  END IF;
  IF p_profil = p_acteur THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'soi_meme');
  END IF;
  IF v_p.role::text IN ('admin', 'controller', 'accountant') THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse', 'raison', 'compte_direction');
  END IF;

  -- Un enseignant qui a encore des seances a venir : on les nomme.
  SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'session_id', s.id, 'debut', s.started_at, 'groupe_id', s.groupe_id) ORDER BY s.started_at)
    INTO v_seances
    FROM public.sessions s
   WHERE s.teacher_id = p_profil
     AND s.deleted_at IS NULL
     AND s.status = 'planned'
     AND s.started_at > v_maintenant;
  IF v_seances IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'refuse',
      'raison', 'seances_a_venir', 'seances', v_seances);
  END IF;

  -- Un eleve quitte ses classes ; la classe reste ouverte pour les autres.
  UPDATE public.groupe_membres gm
     SET left_at = v_maintenant, left_by = p_acteur, left_reason = 'compte retire'
   WHERE gm.student_id = p_profil AND gm.left_at IS NULL;

  UPDATE public.profiles
     SET deleted_at = v_maintenant, account_status = 'disabled', access_until = v_maintenant
   WHERE id = p_profil;

  -- Plus de connexion : le compte est banni ; le bannissement d'avant est
  -- garde pour une restauration (colonne lue au catalogue).
  v_avec_ban := EXISTS (SELECT 1 FROM information_schema.columns c
                         WHERE c.table_schema = 'auth' AND c.table_name = 'users' AND c.column_name = 'banned_until');
  IF v_avec_ban THEN
    EXECUTE pg_catalog.format('SELECT u.banned_until FROM auth.users u WHERE u.id = %L', p_profil) INTO v_banni;
    EXECUTE pg_catalog.format('UPDATE auth.users SET banned_until = ''infinity''::timestamptz WHERE id = %L', p_profil);
  END IF;

  v_delai := greatest(0, coalesce((SELECT (a.value #>> '{}')::integer FROM public.app_config a
                                     WHERE a.key = 'compte.anonymisation_delai_jours'), 30));
  v_echeance := v_maintenant + pg_catalog.make_interval(days => v_delai);
  -- Un profil restaure puis retire de nouveau reprend sa ligne (une par
  -- profil) ; le journal d'audit garde chaque retrait et chaque restauration.
  INSERT INTO private.retraits_comptes AS r (profile_id, role_au_retrait, source, acteur, motif, retire_le,
      anonymiser_le, statut_avant, acces_avant, banni_avant)
  VALUES (p_profil, v_p.role::text, p_source, p_acteur, nullif(pg_catalog.btrim(p_motif), ''), v_maintenant,
      v_echeance, v_p.account_status, v_p.access_until, v_banni)
  ON CONFLICT (profile_id) DO UPDATE
     SET role_au_retrait = excluded.role_au_retrait, source = excluded.source, acteur = excluded.acteur,
         motif = excluded.motif, retire_le = excluded.retire_le, anonymiser_le = excluded.anonymiser_le,
         anonymise_le = NULL, restaure_le = NULL, restaure_par = NULL,
         statut_avant = excluded.statut_avant, acces_avant = excluded.acces_avant,
         banni_avant = excluded.banni_avant
   WHERE r.restaure_le IS NOT NULL
  RETURNING r.id INTO v_retrait;
  IF v_retrait IS NULL THEN
    RAISE EXCEPTION 'retrait deja journalise pour ce profil' USING ERRCODE = '55000';
  END IF;

  PERFORM public.log_sensitive_access('compte_retire', 'retraits_comptes', v_retrait::text,
    pg_catalog.jsonb_build_object('profil_id', p_profil, 'source', p_source, 'role', v_p.role::text));
  RETURN pg_catalog.jsonb_build_object('id', p_profil, 'statut', 'retire',
    'retrait_id', v_retrait, 'anonymiser_le', v_echeance);
END;
$function$;

-- Un retrait restaure ne s'anonymise jamais.
CREATE OR REPLACE FUNCTION private.suppr_anonymiser(p_retrait uuid)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_r private.retraits_comptes%ROWTYPE;
BEGIN
  SELECT r.* INTO v_r FROM private.retraits_comptes r WHERE r.id = p_retrait FOR UPDATE;
  IF NOT FOUND OR v_r.anonymise_le IS NOT NULL OR v_r.restaure_le IS NOT NULL THEN
    RETURN false;
  END IF;
  PERFORM private.cpt_anonymiser(v_r.profile_id);
  UPDATE private.retraits_comptes SET anonymise_le = pg_catalog.clock_timestamp() WHERE id = p_retrait;
  PERFORM public.log_sensitive_access('compte_anonymise', 'retraits_comptes', p_retrait::text,
    pg_catalog.jsonb_build_object('profil_id', v_r.profile_id, 'source', v_r.source));
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION private.suppr_anonymiser_echus()
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_n integer := 0;
BEGIN
  FOR v_id IN
    SELECT r.id FROM private.retraits_comptes r
     WHERE r.anonymise_le IS NULL AND r.restaure_le IS NULL
       AND r.anonymiser_le <= pg_catalog.clock_timestamp()
     ORDER BY r.anonymiser_le
     LIMIT 500
  LOOP
    BEGIN
      IF private.suppr_anonymiser(v_id) THEN
        v_n := v_n + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'SUPPRIMER : anonymisation du retrait % en echec : %', v_id, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- 3. La restauration -----------------------------------------------------------
-- Rend un tableau { id, statut: 'restaure' | 'refuse', raison?, classes_quittees? }.
CREATE FUNCTION public.direction_restaurer_comptes(p_ids uuid[])
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_r private.retraits_comptes%ROWTYPE;
  v_res jsonb;
  v_classes integer;
  v_resultats jsonb := '[]'::jsonb;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'restauration reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  IF p_ids IS NULL OR pg_catalog.cardinality(p_ids) = 0 THEN
    RAISE EXCEPTION 'selection_vide' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.cardinality(p_ids) > 200 THEN
    RAISE EXCEPTION 'selection_trop_grande' USING ERRCODE = '22023';
  END IF;

  FOR v_id IN SELECT DISTINCT x FROM pg_catalog.unnest(p_ids) AS x WHERE x IS NOT NULL ORDER BY 1 LOOP
    BEGIN
      SELECT r.* INTO v_r FROM private.retraits_comptes r WHERE r.profile_id = v_id FOR UPDATE;
      IF NOT FOUND OR v_r.restaure_le IS NOT NULL THEN
        v_res := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'refuse', 'raison', 'aucun_retrait');
      ELSIF v_r.anonymise_le IS NOT NULL THEN
        v_res := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'refuse', 'raison', 'deja_anonymise');
      ELSIF v_r.statut_avant IS NULL THEN
        v_res := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'refuse', 'raison', 'etat_avant_inconnu');
      ELSE
        UPDATE public.profiles
           SET deleted_at = NULL, account_status = v_r.statut_avant, access_until = v_r.acces_avant
         WHERE id = v_id;
        IF EXISTS (SELECT 1 FROM information_schema.columns c
                    WHERE c.table_schema = 'auth' AND c.table_name = 'users' AND c.column_name = 'banned_until') THEN
          EXECUTE pg_catalog.format('UPDATE auth.users SET banned_until = %L::timestamptz WHERE id = %L',
            v_r.banni_avant, v_id);
        END IF;
        UPDATE private.retraits_comptes
           SET restaure_le = v_maintenant, restaure_par = auth.uid()
         WHERE id = v_r.id;
        -- Les classes quittees au retrait : la direction reaffecte l'eleve.
        SELECT pg_catalog.count(*)::integer INTO v_classes
          FROM public.groupe_membres gm
         WHERE gm.student_id = v_id AND gm.left_at = v_r.retire_le AND gm.left_reason = 'compte retire';
        PERFORM public.log_sensitive_access('compte_restaure', 'retraits_comptes', v_r.id::text,
          pg_catalog.jsonb_build_object('profil_id', v_id, 'classes_quittees', v_classes));
        v_res := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'restaure',
          'classes_quittees', v_classes, 'classes_a_reaffecter', v_classes > 0);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_res := pg_catalog.jsonb_build_object('id', v_id, 'statut', 'refuse', 'raison', 'erreur');
    END;
    v_resultats := v_resultats || pg_catalog.jsonb_build_array(v_res);
  END LOOP;
  RETURN v_resultats;
END;
$function$;

-- 4. La liste des retraits -----------------------------------------------------
-- p_etat : 'en_cours' (ni anonymise ni restaure, par defaut), 'anonymises',
-- 'restaures', 'tous'. Plus recent d'abord ; curseur (retire_le, id) de la
-- derniere ligne lue ; 50 par page par defaut, 100 au plus ; pas de total.
CREATE FUNCTION public.retraits_comptes_lister(
  p_etat text DEFAULT 'en_cours',
  p_apres_le timestamptz DEFAULT NULL,
  p_apres_id uuid DEFAULT NULL,
  p_limite integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_limite integer := least(greatest(coalesce(p_limite, 50), 1), 100);
  v_lignes jsonb;
  v_n integer;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'liste reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  IF coalesce(p_etat, 'en_cours') NOT IN ('en_cours', 'anonymises', 'restaures', 'tous') THEN
    RAISE EXCEPTION 'etat_inconnu' USING ERRCODE = '22023';
  END IF;
  IF (p_apres_le IS NULL) <> (p_apres_id IS NULL) THEN
    RAISE EXCEPTION 'curseur_incomplet' USING ERRCODE = '22023';
  END IF;

  SELECT pg_catalog.jsonb_agg(l.ligne ORDER BY l.retire_le DESC, l.id DESC), pg_catalog.count(*)::integer
    INTO v_lignes, v_n
    FROM (
      SELECT r.id, r.retire_le,
             pg_catalog.jsonb_build_object(
               'retrait_id', r.id, 'profile_id', r.profile_id, 'matricule', p.immutable_id,
               'nom', pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)),
               'role', r.role_au_retrait, 'source', r.source, 'motif', r.motif,
               'retire_le', r.retire_le, 'anonymiser_le', r.anonymiser_le,
               'anonymise_le', r.anonymise_le, 'restaure_le', r.restaure_le,
               'restaurable', r.anonymise_le IS NULL AND r.restaure_le IS NULL AND r.statut_avant IS NOT NULL) AS ligne
        FROM private.retraits_comptes r
        JOIN public.profiles p ON p.id = r.profile_id
       WHERE (CASE coalesce(p_etat, 'en_cours')
                WHEN 'en_cours' THEN r.anonymise_le IS NULL AND r.restaure_le IS NULL
                WHEN 'anonymises' THEN r.anonymise_le IS NOT NULL
                WHEN 'restaures' THEN r.restaure_le IS NOT NULL
                ELSE true END)
         AND (p_apres_le IS NULL OR (r.retire_le, r.id) < (p_apres_le, p_apres_id))
       ORDER BY r.retire_le DESC, r.id DESC
       LIMIT v_limite + 1
    ) l;

  v_lignes := coalesce(v_lignes, '[]'::jsonb);
  IF v_n > v_limite THEN
    v_lignes := v_lignes - v_limite;
    RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'suivant', pg_catalog.jsonb_build_object(
      'apres_le', v_lignes -> (v_limite - 1) ->> 'retire_le',
      'apres_id', v_lignes -> (v_limite - 1) ->> 'retrait_id'));
  END IF;
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'suivant', NULL);
END;
$function$;

-- Droits ----------------------------------------------------------------------
ALTER FUNCTION public.direction_restaurer_comptes(uuid[]) OWNER TO postgres;
ALTER FUNCTION public.retraits_comptes_lister(text, timestamptz, uuid, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.direction_restaurer_comptes(uuid[]) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.retraits_comptes_lister(text, timestamptz, uuid, integer) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.direction_restaurer_comptes(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.retraits_comptes_lister(text, timestamptz, uuid, integer) TO authenticated;
COMMENT ON FUNCTION public.direction_restaurer_comptes(uuid[]) IS
  'SUPPRIMER-bis (03/11/2026) : la direction en double verification restaure des retraits non encore anonymises (200 au plus), un resultat par identifiant ; l''eleve n''est pas remis dans ses classes.';
COMMENT ON FUNCTION public.retraits_comptes_lister(text, timestamptz, uuid, integer) IS
  'SUPPRIMER-bis (03/11/2026) : la direction en double verification lit les retraits, par curseur (retire_le, id), sans total.';

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur : on lit le catalogue.
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.direction_restaurer_comptes(uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.retraits_comptes_lister(text,timestamptz,uuid,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_restaurer_comptes(uuid[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_restaurer_comptes(uuid[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.retraits_comptes_lister(text,timestamptz,uuid,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.suppr_retirer(uuid,uuid,text,text)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'private.retraits_comptes', 'SELECT') THEN
    RAISE EXCEPTION 'SUPPRIMER-bis : droits incorrects';
  END IF;
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = 'private.suppr_anonymiser_echus()'::pg_catalog.regprocedure),
                       'restaure_le IS NULL') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'private.suppr_retirer(uuid,uuid,text,text)'::pg_catalog.regprocedure),
                          'statut_avant') = 0 THEN
    RAISE EXCEPTION 'SUPPRIMER-bis : le retrait ne garde pas son etat d''avant, ou un retrait restaure s''anonymiserait';
  END IF;
END;
$postflight$;

COMMIT;
