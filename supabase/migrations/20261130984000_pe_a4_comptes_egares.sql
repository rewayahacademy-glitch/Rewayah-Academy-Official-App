-- PE-A4 COMPTES-EGARES (ordre du directeur, 22/11/2026 : « transfere les comptes egares dans l'espace eleves
-- vers enseignant (seulement ceux que je n'ai pas acceptes) » ; RETOURS-TERRAIN R23 et R29 ;
-- PARCOURS-ENSEIGNANT/SUIVI.md ligne PE-A4).
--
-- Des candidats enseignants ont cree un compte famille ou eleve adulte par erreur. Ce fichier :
--
--   1. private.convertir_compte_en_candidat_enseignant(p_profile uuid, p_motif text) : fait passer UN compte
--      famille non accepte dans l'etat d'un compte qui aurait choisi « Enseigner » au depart, c'est-a-dire
--      l'etat que fabrique public.inscrire_candidat (20261022000600, lien public) :
--        * profiles : role teacher, statut pending_kyc, sans foyer (private.creer_profil_inscription_interne
--          ('teacher', ...) ne cree aucun foyer), une fiche teacher_profiles vide ;
--        * une candidature `enseignant` en Salle d'examen « a completer » (prequalification, a_completer,
--          en_cours), source lien_public, du genre du compte, au nom du compte, avec son contact (courriel
--          du compte) et l'evenement `creee` ;
--        * le rapprochement avec le formulaire papier importe : la fonction du circuit normal,
--          private.formulaires_rapprocher_inscription (meme courriel, meme genre, une seule ligne active et
--          libre : rattachement et pre-remplissage du brouillon ; telephone seul : proposition a la direction).
--      Ce qui est clos, jamais efface :
--        * la demande famille ou eleve adulte passe a l'issue `retiree`, avec l'evenement de transition et le
--          motif interne ; ses apprenants restent tels quels ;
--        * le foyer cree a l'inscription reste en base, sans membre (le compte n'y est plus rattache) ;
--        * la fiche eleve du titulaire (student_profiles du compte lui-meme, creee pour « moi » ou pour le
--          parent qui suit des cours) est marquee retiree (deleted_at), comme le fait la direction pour un
--          eleve retire : un candidat enseignant n'est l'eleve de personne.
--      Refus nommes (rien n'est ecrit) : pe_a4_motif_requis, pe_a4_compte_introuvable, pe_a4_compte_retire,
--      pe_a4_pas_un_compte_famille, pe_a4_compte_accepte, pe_a4_demande_absente, pe_a4_demande_acceptee,
--      pe_a4_autre_candidature, pe_a4_ligne_suivie_existe, pe_a4_foyer_habite, pe_a4_classe, pe_a4_seance,
--      pe_a4_paiement, pe_a4_courriel_absent, pe_a4_genre_absent.
--      Ce que la conversion NE fabrique PAS : l'accord de confidentialite du candidat
--      (candidat_accords_confidentialite) et le telephone du contact. La personne ne les a jamais donnes ;
--      on n'invente ni un accord ni un numero.
--      Aucun courriel : public.inscrire_candidat n'en enfile aucun non plus (seul Supabase Auth envoie la
--      confirmation d'adresse, deja faite pour ces comptes).
--   2. L'application aux 18 references de l'ordre (par reference, jamais par identifiant), tout ou rien,
--      journalisee par public.log_sensitive_access. Sur une base sans aucune de ces references (CI, banc
--      local), elle ne fait rien. Rejouable : un compte deja converti par ce lot est passe.
--   3. Postflight : les 18 sont des candidats enseignants a l'etape d'entree, aucune demande famille ouverte
--      pour eux ; les 4 references exclues (CAND-00001, 00002, 00628, 00645) sont inchangees.
--
-- Fonction privee : aucun droit d'execution pour aucun role client (PUBLIC, anon, authenticated,
-- service_role, agent_ro). Le geste du bureau (« Ce compte est un candidat enseignant ») l'appellera plus tard
-- derriere une porte de la direction ; ce fichier n'en ouvre aucune.
--
-- MOTS D'EFFACEMENT : ZERO. Sans BEGIN ni COMMIT de premier niveau. Ecriture sur des donnees de personnes :
-- ordre ecrit du directeur du 22/11/2026, liste des 18 references fournie par le pilote.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.formulaires_rapprocher_inscription(uuid,text,text,public.gender,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_compte_conforme(uuid)') IS NULL
     OR pg_catalog.to_regclass('public.candidature_apprenants') IS NULL
     OR pg_catalog.to_regclass('public.formulaires_reponses') IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.candidature_types t WHERE t.code = 'enseignant' AND t.role_compte = 'teacher')
     OR NOT EXISTS (SELECT 1 FROM public.candidature_types t WHERE t.code = 'famille' AND t.role_compte = 'guardian')
     OR NOT EXISTS (SELECT 1 FROM public.candidature_types t WHERE t.code = 'eleve_adulte' AND t.role_compte = 'guardian') THEN
    RAISE EXCEPTION 'PE-A4 : installer d''abord CAND-L1B, CAND-L3 et les admissions (lots B et C)';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La conversion d'un compte
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.convertir_compte_en_candidat_enseignant(p_profile uuid, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_auteur uuid := auth.uid();
  v_p public.profiles;
  v_demande public.candidatures;
  v_courriel text;
  v_nom text;
  v_cid uuid;
  v_ref text;
  v_lien jsonb;
  v_eleve_retire boolean := false;
BEGIN
  IF v_motif = '' OR pg_catalog.length(v_motif) > 2000 THEN
    RAISE EXCEPTION 'pe_a4_motif_requis' USING ERRCODE = '22023',
      DETAIL = 'PE-A4 : un motif de 1 a 2000 signes est requis.';
  END IF;

  -- Le compte, verrouille : rien ne l'active ni ne l'affecte pendant la conversion.
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = p_profile FOR UPDATE;
  IF v_p.id IS NULL THEN
    RAISE EXCEPTION 'pe_a4_compte_introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_p.deleted_at IS NOT NULL OR v_p.account_status = 'disabled' THEN
    RAISE EXCEPTION 'pe_a4_compte_retire' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : un compte retire ou desactive ne se convertit pas.';
  END IF;
  IF v_p.role IS DISTINCT FROM 'guardian'::public.app_role THEN
    RAISE EXCEPTION 'pe_a4_pas_un_compte_famille' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : seul un compte famille ou eleve adulte (role guardian) se convertit.';
  END IF;
  -- Accepter une admission rend le compte actif (admission lot C) : un compte actif a ete accepte.
  IF v_p.account_status IS DISTINCT FROM 'pending_kyc'::public.account_status THEN
    RAISE EXCEPTION 'pe_a4_compte_accepte' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le compte n''est plus en attente ; il a ete accepte.';
  END IF;

  -- La demande : la seule candidature du compte, famille ou eleve adulte, en cours, jamais acceptee.
  IF (SELECT pg_catalog.count(*) FROM public.candidatures c WHERE c.profile_id = p_profile) <> 1 THEN
    RAISE EXCEPTION 'pe_a4_autre_candidature' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le compte porte plus d''une candidature, ou aucune ; a traiter a la main.';
  END IF;
  SELECT c.* INTO v_demande FROM public.candidatures c
   WHERE c.profile_id = p_profile AND c.type_code IN ('famille', 'eleve_adulte')
   FOR UPDATE;
  IF v_demande.id IS NULL THEN
    RAISE EXCEPTION 'pe_a4_demande_absente' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : la candidature du compte n''est pas une demande famille ou eleve adulte.';
  END IF;
  IF v_demande.etape = 'confirmee' OR v_demande.issue <> 'en_cours' THEN
    RAISE EXCEPTION 'pe_a4_demande_acceptee' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : la demande est acceptee, refusee ou retiree ; elle ne se convertit pas.';
  END IF;

  -- Le foyer : personne d'autre que le titulaire (aucun enfant cree, aucun co-tuteur).
  IF v_p.household_id IS NOT NULL AND EXISTS (
       SELECT 1 FROM public.profiles x WHERE x.household_id = v_p.household_id AND x.id <> p_profile) THEN
    RAISE EXCEPTION 'pe_a4_foyer_habite' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le foyer du compte a d''autres membres.';
  END IF;

  -- Ni classe, ni seance, ni paiement, a aucun titre (eleve ou enseignant), meme termines.
  IF EXISTS (SELECT 1 FROM public.groupe_membres g WHERE g.student_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.teacher_student_assignments a
                 WHERE a.student_id = p_profile OR a.teacher_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.groupes g WHERE g.teacher_id = p_profile) THEN
    RAISE EXCEPTION 'pe_a4_classe' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le compte a (ou a eu) une classe.';
  END IF;
  IF EXISTS (SELECT 1 FROM public.session_participants s WHERE s.profile_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.sessions s WHERE s.teacher_id = p_profile) THEN
    RAISE EXCEPTION 'pe_a4_seance' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le compte a (ou a eu) une seance.';
  END IF;
  IF EXISTS (SELECT 1 FROM public.paiements_saisis x WHERE x.profile_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.paiements_soumis x WHERE x.profile_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.engagements_prepaiement x WHERE x.profile_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.remboursements_paiement x WHERE x.profile_id = p_profile)
     OR EXISTS (SELECT 1 FROM public.commandes_recharge x
                 WHERE x.titulaire = p_profile OR x.household_id = v_p.household_id)
     OR EXISTS (SELECT 1 FROM public.factures_mensuelles x
                 WHERE x.profile_id = p_profile OR x.household_id = v_p.household_id) THEN
    RAISE EXCEPTION 'pe_a4_paiement' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : le compte ou son foyer a un paiement, une commande ou une facture.';
  END IF;

  -- Le contact : l'adresse du compte, normalisee comme a l'inscription du candidat.
  SELECT pg_catalog.lower(pg_catalog.btrim(u.email)) INTO v_courriel FROM auth.users u WHERE u.id = p_profile;
  IF v_courriel IS NULL OR v_courriel = '' THEN
    RAISE EXCEPTION 'pe_a4_courriel_absent' USING ERRCODE = '23514';
  END IF;
  IF v_p.gender IS NULL THEN
    RAISE EXCEPTION 'pe_a4_genre_absent' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : une candidature enseignant porte le genre du compte.';
  END IF;
  -- Une ligne « pour suivi » (import, sans compte) du meme courriel : inscrire_candidat la reprendrait ;
  -- ici, la direction tranche a la main (les dates de reception se croiseraient).
  IF EXISTS (SELECT 1 FROM public.candidatures c
               JOIN public.candidature_contacts k ON k.candidature_id = c.id
              WHERE c.type_code = 'enseignant' AND c.profile_id IS NULL AND c.issue = 'en_cours'
                AND k.courriel = v_courriel) THEN
    RAISE EXCEPTION 'pe_a4_ligne_suivie_existe' USING ERRCODE = '23514',
      DETAIL = 'PE-A4 : une candidature enseignant importee attend deja ce courriel ; a rattacher par la direction.';
  END IF;

  -- 1. La demande est close, jamais effacee (l'issue d'abord : la forme du compte est verifiee a chaque pas).
  UPDATE public.candidatures c
     SET issue = 'retiree', version = c.version + 1, derniere_activite = pg_catalog.clock_timestamp()
   WHERE c.id = v_demande.id;
  INSERT INTO public.candidature_evenements
    (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, issue_avant, issue_apres,
     auteur_id, motif_interne, details)
  VALUES (v_demande.id, 'transition', v_demande.etape, v_demande.etape, v_demande.etat, v_demande.etat,
          'en_cours', 'retiree', v_auteur, v_motif,
          pg_catalog.jsonb_build_object('geste', 'convertir_en_candidat_enseignant', 'auteur', 'direction',
                                        'cause', 'compte_enseignant_cree_par_erreur', 'lot', 'PE-A4'));

  -- 2. La fiche eleve du titulaire est retiree (le compte n'est plus eleve) ; le foyer reste, sans membre.
  UPDATE public.student_profiles s
     SET deleted_at = pg_catalog.clock_timestamp()
   WHERE s.profile_id = p_profile AND s.deleted_at IS NULL;
  v_eleve_retire := FOUND;

  -- 3. Le compte : celui de private.creer_profil_inscription_interne('teacher', ...).
  UPDATE public.profiles p
     SET role = 'teacher', household_id = NULL, updated_at = pg_catalog.now()
   WHERE p.id = p_profile;
  INSERT INTO public.teacher_profiles (profile_id) VALUES (p_profile)
  ON CONFLICT (profile_id) DO NOTHING;

  -- 4. La candidature enseignant : celle de inscrire_candidat (lien public, sans ligne suivie).
  v_nom := pg_catalog.btrim(pg_catalog.btrim(v_p.first_name) || ' ' || pg_catalog.btrim(v_p.last_name));
  INSERT INTO public.candidatures
    (type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
  VALUES ('enseignant', p_profile, v_p.gender, v_nom, 'prequalification', 'a_completer', 'en_cours',
          'lien_public',
          CASE WHEN v_p.langue_communication IN ('fr', 'ar', 'en') THEN v_p.langue_communication END)
  RETURNING id, reference INTO v_cid, v_ref;
  INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
  VALUES (v_cid, v_courriel, NULL);
  INSERT INTO public.candidature_evenements
    (candidature_id, type, etape_apres, etat_apres, issue_apres, auteur_id, motif_interne, details)
  VALUES (v_cid, 'creee', 'prequalification', 'a_completer', 'en_cours', v_auteur, v_motif,
          pg_catalog.jsonb_build_object('geste', 'convertir_en_candidat_enseignant', 'transition', 5,
                                        'auteur', 'direction', 'porte', 'conversion', 'lot', 'PE-A4',
                                        'depuis', v_demande.reference));

  -- 5. Le formulaire papier : le rapprochement du circuit normal (courriel confirme : lien et pre-remplissage).
  v_lien := private.formulaires_rapprocher_inscription(v_cid, v_courriel, NULL, v_p.gender, v_auteur);

  PERFORM public.log_sensitive_access('compte_converti_candidat_enseignant', 'profiles', p_profile::text,
    pg_catalog.jsonb_build_object(
      'lot', 'PE-A4', 'motif', v_motif,
      'demande', v_demande.reference, 'demande_type', v_demande.type_code,
      'candidature', v_ref, 'foyer_laisse', v_p.household_id,
      'fiche_eleve_retiree', v_eleve_retire,
      'formulaire_lie', coalesce((v_lien ->> 'courriel')::boolean, false),
      'prerempli', v_lien -> 'prerempli'));

  RETURN pg_catalog.jsonb_build_object(
    'profil', p_profile, 'demande', v_demande.reference, 'candidature', v_ref,
    'formulaireLie', coalesce((v_lien ->> 'courriel')::boolean, false),
    'prerempli', coalesce(v_lien -> 'prerempli', '[]'::jsonb),
    'ficheEleveRetiree', v_eleve_retire);
END;
$function$;

ALTER FUNCTION private.convertir_compte_en_candidat_enseignant(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.convertir_compte_en_candidat_enseignant(uuid, text) FROM PUBLIC;
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles r WHERE r.rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.convertir_compte_en_candidat_enseignant(uuid, text) FROM %I', v_role);
    END IF;
  END LOOP;
END
$droits$;
COMMENT ON FUNCTION private.convertir_compte_en_candidat_enseignant(uuid, text) IS
  'PE-A4 (22/11/2026) : un compte famille ou eleve adulte non accepte devient un candidat enseignant (etat de inscrire_candidat, lien public) ; la demande est retiree avec le motif, jamais effacee ; refus nommes pe_a4_*. Aucun droit client.';

-- ---------------------------------------------------------------------------
-- 2. L'application aux 18 references de l'ordre du 22/11/2026, et 3. le postflight
-- ---------------------------------------------------------------------------
DO $application$
DECLARE
  c_motif CONSTANT text := 'compte enseignant cree par erreur dans l''espace eleve (ordre du directeur du 22/11/2026, PE-A4)';
  c_refs CONSTANT text[] := ARRAY[
    'CAND-00040', 'CAND-00146', 'CAND-00165', 'CAND-00205', 'CAND-00226', 'CAND-00258',
    'CAND-00303', 'CAND-00326', 'CAND-00420', 'CAND-00425', 'CAND-00436', 'CAND-00451',
    'CAND-00463', 'CAND-00478', 'CAND-00481', 'CAND-00492', 'CAND-00554', 'CAND-00617'];
  c_exclues CONSTANT text[] := ARRAY['CAND-00001', 'CAND-00002', 'CAND-00628', 'CAND-00645'];
  v_ref text;
  v_c public.candidatures;
  v_res jsonb;
  v_avant text;
  v_apres text;
  v_n integer := 0;
  v_deja integer := 0;
BEGIN
  -- Base sans aucune de ces references (CI, banc local) : rien a faire.
  IF NOT EXISTS (SELECT 1 FROM public.candidatures c WHERE c.reference = ANY (c_refs || c_exclues)) THEN
    RAISE NOTICE 'PE-A4 : aucune des references de l''ordre dans cette base, rien a convertir';
    RETURN;
  END IF;

  -- L'empreinte des 4 exclues, avant (compte, demande, fiche eleve, foyer).
  SELECT pg_catalog.md5(coalesce(pg_catalog.string_agg(pg_catalog.concat_ws('|',
           c.reference, c.type_code, c.etape, c.etat, c.issue, c.version, c.profile_id,
           p.role, p.account_status, p.household_id, p.deleted_at,
           (SELECT s.deleted_at FROM public.student_profiles s WHERE s.profile_id = p.id)),
           ';' ORDER BY c.reference), ''))
    INTO v_avant
    FROM public.candidatures c LEFT JOIN public.profiles p ON p.id = c.profile_id
   WHERE c.reference = ANY (c_exclues);

  FOREACH v_ref IN ARRAY c_refs LOOP
    SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = v_ref;
    IF v_c.id IS NULL THEN
      RAISE EXCEPTION 'PE-A4 : reference % introuvable ; rien n''est converti', v_ref;
    END IF;
    IF v_c.type_code NOT IN ('famille', 'eleve_adulte') THEN
      RAISE EXCEPTION 'PE-A4 : % n''est pas une demande famille ou eleve adulte ; rien n''est converti', v_ref;
    END IF;
    -- Rejeu : deja converti par ce lot.
    IF v_c.issue = 'retiree'
       AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_c.profile_id AND p.role = 'teacher')
       AND EXISTS (SELECT 1 FROM public.candidature_evenements e
                    WHERE e.candidature_id = v_c.id AND e.details ->> 'lot' = 'PE-A4') THEN
      v_deja := v_deja + 1;
      CONTINUE;
    END IF;
    BEGIN
      v_res := private.convertir_compte_en_candidat_enseignant(v_c.profile_id, c_motif);
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'PE-A4 : % refusee (%) ; rien n''est converti', v_ref, SQLERRM;
    END;
    v_n := v_n + 1;
    RAISE NOTICE 'PE-A4 : % -> % (formulaire lie : %)', v_ref, v_res ->> 'candidature', v_res ->> 'formulaireLie';
  END LOOP;

  -- Postflight des 18.
  IF (SELECT pg_catalog.count(*)
        FROM public.candidatures d
        JOIN public.profiles p ON p.id = d.profile_id
        JOIN public.candidatures e ON e.profile_id = p.id AND e.type_code = 'enseignant'
       WHERE d.reference = ANY (c_refs)
         AND d.issue = 'retiree'
         AND p.role = 'teacher' AND p.account_status = 'pending_kyc'
         AND p.household_id IS NULL AND p.deleted_at IS NULL
         AND EXISTS (SELECT 1 FROM public.teacher_profiles t WHERE t.profile_id = p.id)
         AND NOT EXISTS (SELECT 1 FROM public.student_profiles s WHERE s.profile_id = p.id AND s.deleted_at IS NULL)
         AND e.etape = 'prequalification' AND e.etat = 'a_completer' AND e.issue = 'en_cours'
         AND EXISTS (SELECT 1 FROM public.candidature_contacts k WHERE k.candidature_id = e.id AND k.courriel IS NOT NULL)) <> 18 THEN
    RAISE EXCEPTION 'PE-A4 : postflight, les 18 ne sont pas tous candidats enseignants a l''etape d''entree';
  END IF;
  IF EXISTS (SELECT 1 FROM public.candidatures d
               JOIN public.candidatures o ON o.profile_id = d.profile_id
              WHERE d.reference = ANY (c_refs)
                AND o.type_code IN ('famille', 'eleve_adulte') AND o.issue = 'en_cours') THEN
    RAISE EXCEPTION 'PE-A4 : postflight, une demande famille reste ouverte pour l''un des 18';
  END IF;

  -- Postflight des 4 exclues : inchangees.
  SELECT pg_catalog.md5(coalesce(pg_catalog.string_agg(pg_catalog.concat_ws('|',
           c.reference, c.type_code, c.etape, c.etat, c.issue, c.version, c.profile_id,
           p.role, p.account_status, p.household_id, p.deleted_at,
           (SELECT s.deleted_at FROM public.student_profiles s WHERE s.profile_id = p.id)),
           ';' ORDER BY c.reference), ''))
    INTO v_apres
    FROM public.candidatures c LEFT JOIN public.profiles p ON p.id = c.profile_id
   WHERE c.reference = ANY (c_exclues);
  IF v_avant IS DISTINCT FROM v_apres THEN
    RAISE EXCEPTION 'PE-A4 : postflight, une reference exclue a change';
  END IF;
  IF EXISTS (SELECT 1 FROM public.candidatures c JOIN public.candidatures e ON e.profile_id = c.profile_id
              WHERE c.reference = ANY (c_exclues) AND e.type_code = 'enseignant') THEN
    RAISE EXCEPTION 'PE-A4 : postflight, une reference exclue porte une candidature enseignant';
  END IF;

  RAISE NOTICE 'PE-A4 : % comptes convertis, % deja convertis', v_n, v_deja;
END
$application$;

-- ---------------------------------------------------------------------------
-- 3 bis. Postflight de la fonction : DEFINER, search_path vide, aucun droit client
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f CONSTANT pg_catalog.regprocedure :=
    'private.convertir_compte_en_candidat_enseignant(uuid,text)'::pg_catalog.regprocedure;
  v_role text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'PE-A4 : la fonction n''est pas SECURITY DEFINER a search_path vide, ou pas a postgres';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['public', 'anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF (v_role = 'public' OR EXISTS (SELECT 1 FROM pg_catalog.pg_roles r WHERE r.rolname = v_role))
       AND pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PE-A4 : % peut executer la conversion', v_role;
    END IF;
  END LOOP;
END
$postflight$;
