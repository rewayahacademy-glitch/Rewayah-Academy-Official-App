-- ADMISSION lot C (decision du directeur du 27/10/2026,
-- docs/current/DECISION-ADMISSION-2026-10-27.md §3, §4, §7 ; fiche
-- docs/current/FICHE-ADMISSION-LOT-C-2026-10-30.md) : les listes de la
-- direction pour les familles et les eleves adultes, quatre gestes et leurs
-- e-mails. Le moteur des gestes de CAND-L2A1 est reutilise tel quel : on
-- ajoute des regles et des enveloppes, on ne le reecrit pas.
--
-- Rien n'est supprime ni vide a l'application (regle du pilote du
-- 30/10/2026) : aucune contrainte n'est elargie, les regles existantes ne
-- changent pas.
--
-- 1. (sans objet : les conditions existantes suffisent.)
-- 2. Trois regles propres a l'admission, appelees seulement par les gestes
--    ci-dessous, qui verifient la population : `accepter_admission` (de recue
--    ou « a completer » a confirmee), `preciser_admission` (de recue a
--    prequalification, « a completer » : la paire que la contrainte
--    `candidatures_etat_coherent` admet deja), `rouvrir_admission` (de
--    refusee a en cours ; le delai de sept jours est verifie par
--    annuler_refus_admission).
-- 3. Le moteur ne borne plus au genre de la direction les demandes des
--    familles et des eleves adultes (fiche, Q1 : aucune piece d'identite
--    n'y est relue). Les enseignants restent bornes.
-- 4. Gestes de la direction, chacun avec son e-mail par la file :
--    accepter_admission, refuser_admission, demander_precisions_admission,
--    annuler_refus_admission, annuler_admission, contacter_admission. Accepter rend le compte
--    actif ; les profils des enfants sont crees ensuite par l'application du
--    tuteur, a sa premiere ouverture, par la fonction Edge existante (le
--    compte d'un enfant exige la cle de service), a partir de la demande et
--    sans rien ressaisir : lier_apprenant_profil range les reponses.
-- 5. Lectures : lister_demandes_admission (la direction : une liste par
--    population, la plus ancienne d'abord, recherche, pagination, compteur
--    « a traiter ») ; ma_demande_admission (le titulaire : l'etat de sa
--    demande et les precisions demandees) ; mes_apprenants_demande rend aussi
--    ce qu'il faut pour creer les profils.

BEGIN;

-- 2. Les regles -----------------------------------------------------------

INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition,
   motif_requis, modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  -- Accepter : de recue, ou « a completer », a confirmee.
  ('accepter_admission', 1, 40, ARRAY['direction'], ARRAY['recue', 'prequalification'], NULL,
   ARRAY['en_cours'], 'interdite', NULL, '{}', NULL, false, 'transition',
   '{"etape": "confirmee", "etat": null}'::jsonb, '{}', false),
  -- Demander des precisions depuis recue : la demande passe « a completer ».
  ('preciser_admission', 1, 41, ARRAY['direction'], ARRAY['recue'], NULL, ARRAY['en_cours'],
   'interdite', NULL, ARRAY['direction'], NULL, false, 'transition',
   '{"etape": "prequalification", "etat": "a_completer"}'::jsonb, '{}', false),
  -- Annuler un refus d'admission (le delai est verifie par le geste).
  ('rouvrir_admission', 1, 42, ARRAY['direction'], ARRAY['recue', 'prequalification'], NULL,
   ARRAY['refusee'], 'interdite', NULL, ARRAY['direction'], NULL, false, 'transition',
   '{"issue": "en_cours", "issue_modele": null}'::jsonb, '{}', false),
  -- Annuler une acceptation (fiche, Q2) : la demande revient a recue ; le
  -- delai de sept jours et la regle « aucun enfant en classe » sont verifies
  -- par le geste.
  ('annuler_admission', 1, 43, ARRAY['direction'], ARRAY['confirmee'], NULL, ARRAY['en_cours'],
   'interdite', NULL, ARRAY['direction'], NULL, false, 'transition',
   '{"etape": "recue", "etat": null}'::jsonb, '{}', false);

-- 3. Le genre de la direction ne borne pas les admissions ---------------

DO $portee$
DECLARE
  v_f pg_catalog.regprocedure :=
    'private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_avant text := 'IF p_categorie = ''direction'' AND v_c.genre IS DISTINCT FROM v_genre THEN';
  v_apres text := 'IF p_categorie = ''direction'' AND v_c.genre IS DISTINCT FROM v_genre'
                  || ' AND v_c.type_code NOT IN (''famille'', ''eleve_adulte'') THEN';
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'candidature_geste_ouvrir : la borne de genre a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END;
$portee$;

-- Un refus d'admission n'a qu'une porte de reouverture, annuler_refus_admission
-- (sept jours) : le geste des enseignants, rouvrir_candidat, refuse les
-- familles et les eleves adultes (pilote, 30/10/2026). L'empreinte F86 suit.
DO $une_porte$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.rouvrir_candidat(uuid,text,integer,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_avant text := '  v_o := private.candidature_geste_ouvrir(p_id, ''rouvrir'', ''direction'', v_uid,';
  v_garde text := '  IF EXISTS (SELECT 1 FROM public.candidatures c WHERE c.id = p_id'
    || ' AND c.type_code IN (''famille'', ''eleve_adulte'')) THEN' || E'\n'
    || '    RETURN pg_catalog.jsonb_build_object(''erreur'', ''geste_admission'','
    || ' ''utiliser'', ''annuler_refus_admission'');' || E'\n'
    || '  END IF;' || E'\n';
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'rouvrir_candidat : l''appel du moteur a change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_garde || v_avant);
  v_com := pg_catalog.obj_description(v_f, 'pg_proc');
  IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
      pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
  END IF;
END;
$une_porte$;

-- 4. Le lien d'un apprenant a son profil d'eleve -------------------------

ALTER TABLE public.candidature_apprenants
  ADD COLUMN IF NOT EXISTS profil_eleve_id uuid NULL REFERENCES public.profiles(id);
CREATE UNIQUE INDEX IF NOT EXISTS candidature_apprenants_profil_unique
  ON public.candidature_apprenants (profil_eleve_id) WHERE profil_eleve_id IS NOT NULL;

-- 5. Les gestes -----------------------------------------------------------

-- La garde commune des gestes d'admission : la direction active, une
-- demande de famille ou d'eleve adulte.
CREATE FUNCTION private.admission_garde(p_id uuid)
RETURNS public.candidatures
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des admissions reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF NOT FOUND OR v_c.type_code NOT IN ('famille', 'eleve_adulte') THEN
    RAISE EXCEPTION 'demande d''admission introuvable' USING ERRCODE = 'P0002';
  END IF;
  RETURN v_c;
END;
$function$;

-- L'e-mail d'un geste, par la file, jamais dans le corps du geste : une
-- adresse absente n'empeche pas la decision.
CREATE FUNCTION private.admission_courriel(
  p_c public.candidatures, p_modele text, p_donnees jsonb, p_cle text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adresse text := public.courriel_adresse_profil(p_c.profile_id);
BEGIN
  IF v_adresse IS NULL OR p_c.profile_id IS NULL THEN
    RETURN;
  END IF;
  PERFORM public.courriel_enfiler(
    'inscription', p_modele, v_adresse, p_c.profile_id,
    coalesce(p_donnees, '{}'::jsonb) || pg_catalog.jsonb_build_object('reference', p_c.reference),
    p_cle, 'auto', auth.uid());
END;
$function$;

-- Accepter : la demande passe a confirmee, le compte devient actif, l'e-mail
-- « Votre demande est acceptee » part.
CREATE FUNCTION public.accepter_admission(
  p_id uuid, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_o jsonb;
BEGIN
  v_o := private.candidature_geste_ouvrir(p_id, 'accepter_admission', 'direction', auth.uid(),
                                          p_version_attendue, p_cle_idempotence, NULL, NULL);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'accepter_admission',
    (v_o ->> 'variante')::smallint, 'direction', auth.uid(), NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('aNotifier', 'admission_acceptee'));
  -- La demande est confirmee : le compte peut devenir actif (la regle de
  -- forme du compte, CAND-L1B, le permet desormais).
  UPDATE public.profiles p
     SET account_status = 'active'
   WHERE p.id = v_c.profile_id AND p.account_status = 'pending_kyc';
  -- Une acceptation annulee puis redonnee rend leurs profils aux enfants.
  UPDATE public.profiles p
     SET account_status = 'active'
    FROM public.candidature_apprenants a
   WHERE a.candidature_id = v_c.id AND p.id = a.profil_eleve_id
     AND p.account_status = 'disabled';
  PERFORM private.admission_courriel(v_c, 'admission_acceptee', '{}'::jsonb,
    'admission_acceptee:' || v_c.id::text || ':' || p_cle_idempotence);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'accepter_admission', auth.uid(),
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Refuser : le geste existant (motif interne, modele de message), puis
-- l'e-mail « Nous ne pouvons pas donner suite ».
CREATE FUNCTION public.refuser_admission(
  p_id uuid, p_motif text, p_modele text, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_r jsonb;
BEGIN
  v_r := private.candidature_geste_groupe(p_id, 'refuser', auth.uid(), p_version_attendue,
                                          p_cle_idempotence, p_motif, p_modele, NULL);
  IF v_r ? 'candidature' THEN
    PERFORM private.admission_courriel(v_c, 'admission_refusee',
      pg_catalog.jsonb_build_object('modele', p_modele),
      'admission_refusee:' || v_c.id::text || ':' || p_cle_idempotence);
  END IF;
  RETURN v_r;
END;
$function$;

-- Annuler un refus, dans les sept jours : la demande revient en cours.
CREATE FUNCTION public.annuler_refus_admission(
  p_id uuid, p_motif text, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_o jsonb;
BEGIN
  -- Sept jours apres le refus, le geste ne vaut plus (decision, §4).
  IF v_c.issue = 'refusee' AND v_c.derniere_activite <= pg_catalog.now() - interval '7 days' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'transition_interdite', 'geste', 'rouvrir_admission');
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'rouvrir_admission', 'direction', auth.uid(),
                                          p_version_attendue, p_cle_idempotence, p_motif, NULL);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'rouvrir_admission', (v_o ->> 'variante')::smallint,
    'direction', auth.uid(), p_motif, NULL, '{}'::jsonb, '{}'::jsonb);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'rouvrir_admission', auth.uid(),
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Annuler une acceptation, dans les sept jours (fiche, Q2) : la demande
-- revient a traiter, le compte repasse en attente, les profils des enfants
-- sont mis de cote (`disabled`, jamais effaces) ; refuse si un enfant de la
-- demande est deja dans une classe. Aucun e-mail : la direction ecrit si elle
-- le veut (« Ecrire »).
CREATE FUNCTION public.annuler_admission(
  p_id uuid, p_motif text, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_acceptee timestamptz;
  v_o jsonb;
BEGIN
  SELECT pg_catalog.max(e.cree_le) INTO v_acceptee
    FROM public.candidature_evenements e
   WHERE e.candidature_id = p_id AND e.etape_apres = 'confirmee';
  IF v_c.etape = 'confirmee'
     AND (v_acceptee IS NULL OR v_acceptee <= pg_catalog.now() - interval '7 days') THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'transition_interdite', 'geste', 'annuler_admission');
  END IF;
  IF EXISTS (SELECT 1
               FROM public.candidature_apprenants a
               JOIN public.groupe_membres m ON m.student_id = a.profil_eleve_id
              WHERE a.candidature_id = p_id AND m.left_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'enfant_en_classe', 'geste', 'annuler_admission');
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'annuler_admission', 'direction', auth.uid(),
                                          p_version_attendue, p_cle_idempotence, p_motif, NULL);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  UPDATE public.profiles p
     SET account_status = 'pending_kyc'
   WHERE p.id = v_c.profile_id AND p.account_status = 'active';
  UPDATE public.profiles p
     SET account_status = 'disabled'
    FROM public.candidature_apprenants a
   WHERE a.candidature_id = p_id AND p.id = a.profil_eleve_id
     AND p.account_status = 'active';
  PERFORM private.candidature_geste_appliquer(p_id, 'annuler_admission',
    (v_o ->> 'variante')::smallint, 'direction', auth.uid(), p_motif, NULL, '{}'::jsonb, '{}'::jsonb);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'annuler_admission', auth.uid(),
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Demander des precisions : la demande passe « a completer » ; le message de
-- la direction part par e-mail et se lit sur la page d'attente.
CREATE FUNCTION public.demander_precisions_admission(
  p_id uuid, p_message text, p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_message text := pg_catalog.btrim(p_message);
  v_o jsonb;
BEGIN
  IF coalesce(pg_catalog.length(v_message), 0) NOT BETWEEN 1 AND 1000 THEN
    RAISE EXCEPTION 'precisions : un message de 1 a 1000 signes' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'preciser_admission', 'direction', auth.uid(),
                                          p_version_attendue, p_cle_idempotence, v_message, NULL);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'preciser_admission',
    (v_o ->> 'variante')::smallint, 'direction', auth.uid(), v_message, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('aNotifier', 'admission_precisions', 'precisions', v_message));
  PERFORM private.admission_courriel(v_c, 'admission_precisions',
    pg_catalog.jsonb_build_object('precisions', v_message),
    'admission_precisions:' || v_c.id::text || ':' || p_cle_idempotence);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'preciser_admission', auth.uid(),
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Contacter : un message libre de la direction, par e-mail, sans changer
-- l'etat ; trace au journal d'acces.
CREATE FUNCTION public.contacter_admission(
  p_id uuid, p_sujet text, p_message text, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures := private.admission_garde(p_id);
  v_sujet text := pg_catalog.btrim(p_sujet);
  v_message text := pg_catalog.btrim(p_message);
BEGIN
  IF coalesce(pg_catalog.length(v_sujet), 0) NOT BETWEEN 1 AND 120
     OR coalesce(pg_catalog.length(v_message), 0) NOT BETWEEN 1 AND 4000
     OR coalesce(pg_catalog.length(p_cle_idempotence), 0) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'contact : un sujet (1 a 120 signes), un message (1 a 4000) et une cle'
      USING ERRCODE = '22023';
  END IF;
  IF public.courriel_adresse_profil(v_c.profile_id) IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'adresse_inconnue');
  END IF;
  PERFORM public.courriel_enfiler(
    'inscription', 'message_libre', public.courriel_adresse_profil(v_c.profile_id), v_c.profile_id,
    pg_catalog.jsonb_build_object('sujet', v_sujet, 'corps', v_message),
    'admission_contact:' || v_c.id::text || ':' || p_cle_idempotence, 'manuel', auth.uid());
  PERFORM public.log_sensitive_access('admission_contact', 'candidatures', v_c.id::text,
    pg_catalog.jsonb_build_object('sujet', v_sujet));
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$function$;

-- 6. Les lectures -------------------------------------------------------

-- La liste d'une population (famille ou eleve_adulte), la plus ancienne
-- d'abord ; recherche par nom, e-mail ou reference ; 50 par page ; le
-- compteur « a traiter » compte les demandes en cours.
CREATE FUNCTION public.lister_demandes_admission(
  p_type text, p_recherche text DEFAULT NULL, p_page integer DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_recherche text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_recherche, ''))), '');
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_lignes jsonb;
  v_total integer;
  v_a_traiter integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'listes des admissions reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_type NOT IN ('famille', 'eleve_adulte') THEN
    RAISE EXCEPTION 'population inconnue : famille ou eleve_adulte' USING ERRCODE = '22023';
  END IF;
  WITH filtrees AS (
    SELECT c.*, public.courriel_adresse_profil(c.profile_id) AS courriel
      FROM public.candidatures c
     WHERE c.type_code = p_type
       AND (v_recherche IS NULL
            OR pg_catalog.strpos(pg_catalog.lower(c.nom_complet), v_recherche) > 0
            OR pg_catalog.strpos(pg_catalog.lower(c.reference), v_recherche) > 0
            OR pg_catalog.strpos(coalesce(pg_catalog.lower(public.courriel_adresse_profil(c.profile_id)), ''),
                                 v_recherche) > 0)
  )
  SELECT
    coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', f.id,
      'reference', f.reference,
      'nom', f.nom_complet,
      'courriel', f.courriel,
      'recueLe', f.recue_le,
      'etape', f.etape,
      'etat', f.etat,
      'issue', f.issue,
      'version', f.version,
      'derniereActivite', f.derniere_activite,
      'apprenants', (
        SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'prenom', a.prenom, 'age', a.age, 'genre', a.genre,
                 'estTitulaire', a.est_titulaire, 'niveau', a.niveau_declare,
                 'objectif', a.objectif, 'moments', a.moments, 'langue', a.langue_code)
                 ORDER BY a.rang), '[]'::jsonb)
          FROM public.candidature_apprenants a WHERE a.candidature_id = f.id)
    ) ORDER BY (f.issue = 'en_cours') DESC, f.recue_le, f.id)
    FILTER (WHERE f.rang_page = v_page), '[]'::jsonb),
    pg_catalog.count(*)::integer
    INTO v_lignes, v_total
    FROM (SELECT x.*, ((pg_catalog.row_number() OVER (
                   ORDER BY (x.issue = 'en_cours') DESC, x.recue_le, x.id) - 1) / 50 + 1)
                   AS rang_page
            FROM filtrees x) f;
  SELECT pg_catalog.count(*)::integer INTO v_a_traiter
    FROM public.candidatures c
   WHERE c.type_code = p_type AND c.issue = 'en_cours' AND c.etape = 'recue';
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'total', v_total,
    'aTraiter', v_a_traiter, 'page', v_page, 'parPage', 50);
END;
$function$;

-- Le titulaire relit l'etat de sa demande et, quand la direction en a
-- demande, les precisions attendues (le dernier message).
CREATE FUNCTION public.ma_demande_admission()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
           'etape', c.etape,
           'etat', c.etat,
           'issue', c.issue,
           'precisions', CASE WHEN c.etat = 'a_completer' THEN (
             SELECT e.details ->> 'precisions'
               FROM public.candidature_evenements e
              WHERE e.candidature_id = c.id AND e.details ? 'precisions'
              ORDER BY e.cree_le DESC
              LIMIT 1) END)
    FROM public.candidatures c
   WHERE c.profile_id = auth.uid() AND c.type_code IN ('famille', 'eleve_adulte')
   LIMIT 1;
$function$;

-- Les apprenants de sa demande, avec ce qu'il faut pour creer les profils
-- apres l'acceptation : identifiant, genre, reponses, profil deja lie.
-- `nom_famille` : le nom du titulaire, donne aux profils des enfants.
-- `profil_probable` : un eleve du foyer au meme prenom, lie a aucun
-- apprenant. La creation d'un profil n'est pas idempotente (DB-FOY-06) : si la
-- reponse s'est perdue, l'application lie ce profil au lieu d'en creer un
-- second.
CREATE OR REPLACE FUNCTION public.mes_apprenants_demande()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', a.id,
           'prenom', a.prenom,
           'age', a.age,
           'genre', a.genre,
           'est_titulaire', a.est_titulaire,
           'niveau', a.niveau_declare,
           'objectif', a.objectif,
           'moments', a.moments,
           'langue', a.langue_code,
           'profil_eleve_id', a.profil_eleve_id,
           'nom_famille', (SELECT p.last_name FROM public.profiles p WHERE p.id = c.profile_id),
           'profil_probable', CASE WHEN a.profil_eleve_id IS NULL AND NOT a.est_titulaire THEN (
             SELECT e.id
               FROM public.profiles e
               JOIN public.profiles t ON t.id = c.profile_id
              WHERE e.household_id = t.household_id AND e.role = 'student'
                AND e.deleted_at IS NULL
                AND pg_catalog.lower(e.first_name) = pg_catalog.lower(a.prenom)
                AND NOT EXISTS (SELECT 1 FROM public.candidature_apprenants l
                                 WHERE l.profil_eleve_id = e.id)
              ORDER BY e.created_at, e.id
              LIMIT 1) END) ORDER BY a.rang), '[]'::jsonb)
    FROM public.candidature_apprenants a
    JOIN public.candidatures c ON c.id = a.candidature_id
   WHERE c.profile_id = auth.uid()
     AND c.type_code IN ('famille', 'eleve_adulte');
$function$;

-- Apres l'acceptation, le tuteur lie un enfant de sa demande au profil que
-- la fonction Edge vient de creer : genre et reponses y sont ranges, une
-- seule fois. Le profil doit etre un eleve de son foyer.
CREATE FUNCTION public.lier_apprenant_profil(p_apprenant_id uuid, p_profil_eleve_id uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_a public.candidature_apprenants;
  v_c public.candidatures;
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'session active requise' USING ERRCODE = '42501';
  END IF;
  SELECT a.* INTO v_a FROM public.candidature_apprenants a WHERE a.id = p_apprenant_id FOR UPDATE;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_a.candidature_id;
  IF NOT FOUND OR v_c.profile_id IS DISTINCT FROM auth.uid() OR v_c.etape <> 'confirmee'
     OR v_a.est_titulaire THEN
    RAISE EXCEPTION 'apprenant introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_a.profil_eleve_id IS NOT NULL THEN
    IF v_a.profil_eleve_id = p_profil_eleve_id THEN
      RETURN;
    END IF;
    RAISE EXCEPTION 'apprenant deja lie' USING ERRCODE = '23505';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.profiles e
         JOIN public.profiles t ON t.id = auth.uid()
        WHERE e.id = p_profil_eleve_id AND e.role = 'student' AND e.deleted_at IS NULL
          AND e.household_id = t.household_id) THEN
    RAISE EXCEPTION 'profil d''eleve hors du foyer' USING ERRCODE = '42501';
  END IF;
  UPDATE public.candidature_apprenants SET profil_eleve_id = p_profil_eleve_id WHERE id = v_a.id;
  UPDATE public.profiles SET gender = v_a.genre WHERE id = p_profil_eleve_id AND gender IS NULL;
  UPDATE public.student_profiles s
     SET niveau_declare = coalesce(s.niveau_declare, v_a.niveau_declare),
         objectif = coalesce(s.objectif, v_a.objectif),
         langue_cours = coalesce(s.langue_cours, v_a.langue_code)
   WHERE s.profile_id = p_profil_eleve_id;
  PERFORM public.log_sensitive_access('admission_apprenant_lie', 'candidature_apprenants',
    v_a.id::text, pg_catalog.jsonb_build_object('profil_eleve_id', p_profil_eleve_id));
END;
$function$;

-- 7. Droits et empreintes ------------------------------------------------

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.admission_garde(uuid)'::pg_catalog.regprocedure,
    'private.admission_courriel(public.candidatures,text,jsonb,text)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accepter_admission(uuid,integer,text)'::pg_catalog.regprocedure,
    'public.refuser_admission(uuid,text,text,integer,text)'::pg_catalog.regprocedure,
    'public.annuler_refus_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.annuler_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.demander_precisions_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.contacter_admission(uuid,text,text,text)'::pg_catalog.regprocedure,
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure,
    'public.ma_demande_admission()'::pg_catalog.regprocedure,
    'public.mes_apprenants_demande()'::pg_catalog.regprocedure,
    'public.lier_apprenant_profil(uuid,uuid)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-30. Admission lot C.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid::text IN ('ma_demande_admission()', 'mes_apprenants_demande()',
                                'lier_apprenant_profil(uuid,uuid)')
           THEN 'TITULAIRE_SELF' ELSE 'ADMIN_ONLY' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accepter_admission(uuid,integer,text)'::pg_catalog.regprocedure,
    'public.refuser_admission(uuid,text,text,integer,text)'::pg_catalog.regprocedure,
    'public.annuler_refus_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.annuler_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.demander_precisions_admission(uuid,text,integer,text)'::pg_catalog.regprocedure,
    'public.contacter_admission(uuid,text,text,text)'::pg_catalog.regprocedure,
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure,
    'public.ma_demande_admission()'::pg_catalog.regprocedure,
    'public.mes_apprenants_demande()'::pg_catalog.regprocedure,
    'public.lier_apprenant_profil(uuid,uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'ADMISSION-C : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
