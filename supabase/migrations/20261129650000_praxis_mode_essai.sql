-- PX-4 MODE ESSAI (pilote, 17/11/2026) : l'essai a blanc du directeur ne doit lire AUCUNE conversation reelle tant que la politique de
-- confidentialite n'est pas publiee. Un reglage `essai_fils` (liste de fils, 10 au plus) dans private.praxis_reglages ; VIDE = pas de mode
-- essai (comportement inchange).
--   * private.praxis_essai()                : la liste.
--   * public.direction_praxis_regler_essai(uuid[]) : la porte du directeur (administrateur valide, aal2) ; ecrit la liste ; chaque fil
--       doit exister ; une liste vide met fin au mode essai ; une ligne d'audit (praxis_regle_essai).
--   * private.praxis_fil_refus : un fil hors liste est refuse `hors_essai` AVANT toute lecture (un fil inexistant aussi : pas de fuite).
--       Couvre praxis_fil, praxis_ecrire et le filtre de praxis_boite / praxis_rendre_compte.
--   * praxis_boite et praxis_rendre_compte : le parcours est BORNE a la liste (pas aux 200 fils les plus recents), et le compte rendu
--       ne rend que les envois de ces fils.
--   * praxis_annoncer : refusee `essai` (une annonce atteint des personnes reelles) ; la refus est journalise.
--   * direction_praxis_etat : rend aussi `essaiFils`.
-- Les types de fil, les cotes, les mineurs, les plafonds restent exiges : le mode essai RESTREINT, il ne donne aucun droit de plus.
-- Les fonctions remplacees le sont par CREATE OR REPLACE a signature identique (droits conserves) apres verification de l'empreinte
-- de leur definition courante. FICHIER SANS EFFACEMENT. Additif. Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.praxis_reglages) THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : private.praxis_reglages est vide';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'private.praxis_fil_refus(uuid,public.gender[])'::pg_catalog.regprocedure) IS DISTINCT FROM 'e8617f1d68e2e0e64eaa57b0f9c936eb' THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : la definition de private.praxis_fil_refus n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_boite(text,text,integer)'::pg_catalog.regprocedure) IS DISTINCT FROM '836e10d05885cc4207af8ce8b1ad481b' THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : la definition de public.praxis_boite n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_rendre_compte(text,integer)'::pg_catalog.regprocedure) IS DISTINCT FROM 'fcb9c00602a883dded19c0a71e0ff027' THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : la definition de public.praxis_rendre_compte n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_annoncer(text,text[],text,text,uuid)'::pg_catalog.regprocedure) IS DISTINCT FROM '80bca197735fec86c19a00ab3729c1e7' THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : la definition de public.praxis_annoncer n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.direction_praxis_etat()'::pg_catalog.regprocedure) IS DISTINCT FROM '45ddc3c126af1cbc255a145f2e340e03' THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : la definition de public.direction_praxis_etat n''est pas celle attendue ; rien n''est modifie';
  END IF;
END
$preflight$;

ALTER TABLE private.praxis_reglages
  ADD COLUMN essai_fils uuid[] NOT NULL DEFAULT '{}'::uuid[]
  CONSTRAINT praxis_reglages_essai_fils_borne CHECK (pg_catalog.cardinality(essai_fils) <= 10 AND NOT (pg_catalog.array_position(essai_fils, NULL) IS NOT NULL));

CREATE FUNCTION private.praxis_essai()
RETURNS uuid[]
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce((SELECT r.essai_fils FROM private.praxis_reglages r), '{}'::uuid[]);
$f$;

CREATE OR REPLACE FUNCTION private.praxis_fil_refus(p_fil uuid, p_cotes public.gender[])
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  f public.com_fils%ROWTYPE;
BEGIN
  -- MODE ESSAI (PX-4) : quand le directeur a nomme des conversations d'essai, TOUT autre fil, existant ou non, est refuse avant meme
  -- d'etre lu (aucune fuite d'existence). Vide = pas de mode essai.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0
     AND NOT coalesce(p_fil = ANY (private.praxis_essai()), false) THEN
    RETURN 'hors_essai';
  END IF;
  SELECT x.* INTO f FROM public.com_fils x WHERE x.id = p_fil;
  IF NOT FOUND THEN RETURN 'fil_inconnu'; END IF;
  IF f.partie_b_nature IS DISTINCT FROM 'equipe' THEN RETURN 'hors_academie'; END IF;
  IF NOT (f.type_objet = ANY (private.praxis_types_fil()))
     OR (f.type_objet = 'dossier' AND f.partie_a_nature IS DISTINCT FROM 'foyer') THEN
    RETURN 'type_ferme';
  END IF;
  IF f.partie_a_nature = 'profil' AND private.com_est_mineur(f.partie_a_id) THEN RETURN 'mineur'; END IF;
  IF f.partie_a_nature = 'foyer' AND EXISTS (
       SELECT 1 FROM public.profiles g
        WHERE g.household_id = f.partie_a_id AND g.role = 'guardian'::public.app_role AND g.deleted_at IS NULL
          AND private.com_est_mineur(g.id)) THEN
    RETURN 'mineur';
  END IF;
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = f.id AND private.com_est_mineur(m.auteur_id)) THEN
    RETURN 'mineur';
  END IF;
  IF NOT private.praxis_fil_dans_cotes(f.id, p_cotes) THEN RETURN 'cote'; END IF;
  RETURN NULL;
END;
$f$;

CREATE OR REPLACE FUNCTION public.praxis_boite(p_cle text, p_filtre text DEFAULT 'attend', p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_fils jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('attend', 'non_lu', 'tout') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  WITH recents AS (
    SELECT f.* FROM public.com_fils f
     WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
       AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR f.id = ANY (private.praxis_essai()))
     ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id
     LIMIT 200
  ), base AS (
    SELECT f.id, f.type_objet, f.partie_a_nature, f.partie_a_id,
           d.auteur_id AS dernier_auteur, d.texte AS dernier_texte, d.envoye_le AS dernier_le,
           (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m
             WHERE m.fil_id = f.id AND (m.auteur_id = private.praxis_profil() OR private.praxis_est_equipe(m.auteur_id, f.id))) AS derniere_academie
      FROM recents f
      JOIN LATERAL (SELECT m.auteur_id, m.texte, m.envoye_le FROM public.com_messages m
                     WHERE m.fil_id = f.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1) d ON true
     WHERE private.praxis_fil_refus(f.id, v_p.cotes) IS NULL
  ), calc AS (
    SELECT b.*,
           private.praxis_est_partie_a(b.dernier_auteur, b.id) AS attend,
           (SELECT pg_catalog.count(*) FROM public.com_messages m
             WHERE m.fil_id = b.id AND private.praxis_est_partie_a(m.auteur_id, b.id)
               AND m.envoye_le > coalesce(b.derniere_academie, '-infinity'::timestamptz))::integer AS sans_reponse
      FROM base b
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', c.id, 'type', c.type_objet,
           'interlocuteur', CASE c.partie_a_nature
              WHEN 'profil' THEN private.praxis_auteur_json(c.partie_a_id, c.id)
              ELSE pg_catalog.jsonb_build_object('role', 'famille') END,
           'dernier_auteur', private.praxis_auteur_json(c.dernier_auteur, c.id),
           -- Tout texte qui n'est pas de Praxis (prenoms compris, messages de l'equipe compris) est une DONNEE de tiers.
           'contenu_tiers', CASE WHEN c.dernier_auteur = private.praxis_profil() THEN NULL
              ELSE pg_catalog.jsonb_build_object(
                'prenoms', CASE c.partie_a_nature
                  WHEN 'profil' THEN (SELECT pg_catalog.jsonb_build_array(p.first_name) FROM public.profiles p WHERE p.id = c.partie_a_id)
                  ELSE coalesce((SELECT pg_catalog.jsonb_agg(g.first_name ORDER BY g.first_name, g.id) FROM public.profiles g
                                  WHERE g.household_id = c.partie_a_id AND g.role = 'guardian'::public.app_role
                                    AND g.deleted_at IS NULL), '[]'::jsonb) END,
                'dernier_message', pg_catalog.left(c.dernier_texte, 300)) END,
           'attente_heures', CASE WHEN c.attend
              THEN (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.dernier_le) / 3600)::integer END,
           'sans_reponse', c.sans_reponse,
           'repris_par_equipe', EXISTS (SELECT 1 FROM public.com_messages m
             WHERE m.fil_id = c.id AND private.praxis_est_equipe(m.auteur_id, c.id)
               AND m.envoye_le > coalesce((SELECT pg_catalog.max(x.envoye_le) FROM public.com_messages x
                                            WHERE x.fil_id = c.id AND x.auteur_id = private.praxis_profil()),
                                          'infinity'::timestamptz))
         ) ORDER BY c.dernier_le DESC), '[]'::jsonb)
    INTO v_fils
    FROM (SELECT * FROM calc c2
           WHERE p_filtre = 'tout' OR (p_filtre = 'attend' AND c2.attend) OR (p_filtre = 'non_lu' AND c2.sans_reponse > 0)
           ORDER BY c2.dernier_le DESC LIMIT p_limite) c;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('fils', v_fils);
END;
$f$;

CREATE OR REPLACE FUNCTION public.praxis_rendre_compte(p_cle text, p_heures integer DEFAULT 24)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_envois jsonb;
  v_refus integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_heures IS NULL OR p_heures NOT BETWEEN 1 AND 168 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'outil', j.outil, 'fil', j.fil_id, 'extrait', pg_catalog.left(j.texte_envoye, 300), 'heure', j.cree_le)
           ORDER BY j.cree_le DESC), '[]'::jsonb) INTO v_envois
    FROM (SELECT * FROM private.praxis_journal x
           WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue = 'ok'
             AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR x.fil_id = ANY (private.praxis_essai()))
             AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures)
           ORDER BY x.cree_le DESC LIMIT 50) j;
  SELECT pg_catalog.count(*)::integer INTO v_refus FROM private.praxis_journal x
   WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue <> 'ok' AND x.issue <> 'rejoue'
     AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('envoye', v_envois, 'refuses', v_refus,
    'laisse_en_attente', (SELECT pg_catalog.count(*)::integer FROM (
        SELECT f.id FROM public.com_fils f
         WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
           AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR f.id = ANY (private.praxis_essai()))
         ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id LIMIT 200) r
        WHERE private.praxis_fil_refus(r.id, v_p.cotes) IS NULL
          AND private.praxis_est_partie_a((SELECT m.auteur_id FROM public.com_messages m
                WHERE m.fil_id = r.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1), r.id)));
END;
$f$;

CREATE OR REPLACE FUNCTION public.praxis_annoncer(p_cle text, p_publics text[], p_titre text, p_texte text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_titre text := pg_catalog.btrim(coalesce(p_titre, ''));
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_publics text[];
  v_cotes public.gender[];
  v_praxis uuid := private.praxis_profil();
  v_existante record;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_cle_idempotence IS NULL OR p_publics IS NULL OR pg_catalog.cardinality(p_publics) NOT BETWEEN 1 AND 10
     OR v_texte = '' OR pg_catalog.length(v_titre) > 120 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 3000 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- MODE ESSAI (PX-4) : tant que des conversations d'essai sont nommees, aucune annonce (elle touche des personnes reelles).
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  v_cotes := v_p.cotes;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  SELECT a.id INTO v_existante FROM public.com_annonces a
   WHERE a.auteur_id = v_praxis AND a.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'rejoue', NULL, ARRAY[v_existante.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existante.id, 'rejoue', true);
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.outil = 'annoncer' AND j.issue = 'ok'
         AND j.cree_le > pg_catalog.clock_timestamp() - interval '24 hours') >= 2 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'plafond_annonces', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_annonces');
  END IF;
  BEGIN
    v_publics := private.com_annonce_publics_valides(p_publics);
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'public', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'public');
  END;
  -- §3.4 : aucun public qui contient des mineurs. Le public `eleves` s'adresse aux eleves (dont des mineurs) : refuse,
  -- Praxis s'adresse aux familles (`familles`). Les destinataires calcules par la messagerie excluent deja tout mineur ou
  -- age inconnu (com_est_mineur) : le controle suivant est une garde de plus, jamais vrai aujourd'hui.
  IF 'eleves' = ANY (v_publics) OR EXISTS (SELECT 1 FROM private.com_annonce_personnes(v_publics, v_cotes) x
              WHERE private.com_est_mineur(x.profile_id)) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'mineur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'mineur');
  END IF;
  BEGIN
    v_r := private.com_annonce_envoyer_interne(v_praxis, v_cotes, v_publics, v_titre, v_texte, NULL, false,
                                               p_cle_idempotence);
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'refusee', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'refusee');
  END;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'ok', NULL, ARRAY[(v_r ->> 'id')::uuid],
                               pg_catalog.left(v_titre || pg_catalog.chr(10) || v_texte, 3000), v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'destinataires', v_r -> 'destinataires');
END;
$f$;

CREATE OR REPLACE FUNCTION public.direction_praxis_etat()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT pg_catalog.jsonb_build_object(
    'actif', r.actif,
    'autonome', r.autonome,
    'envoisParHeure', r.envois_par_heure,
    'modifieLe', r.modifie_le,
    'essaiFils', pg_catalog.to_jsonb(r.essai_fils),
    'cles', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'prefixe', c.prefixe, 'usage', c.usage,
               'emiseLe', c.emise_le, 'expireLe', c.expire_le, 'derniereUtilisationLe', c.derniere_utilisation_le,
               'revoqueeLe', c.revoquee_le, 'motifRevocation', c.motif_revocation,
               -- L'etat vient de la base (son horloge), jamais d'une comparaison faite sur le poste (meme regle que jetons_agent_actifs).
               'etat', CASE WHEN c.revoquee_le IS NOT NULL THEN 'revoquee'
                            WHEN c.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'active' END)
             ORDER BY c.emise_le DESC, c.id)
        FROM (SELECT * FROM private.praxis_cles x ORDER BY x.emise_le DESC, x.id LIMIT 100) c), '[]'::jsonb))
    FROM private.praxis_reglages r);
END;
$f$;

CREATE FUNCTION public.direction_praxis_regler_essai(p_essai_fils uuid[])
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_liste uuid[];
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_essai_fils IS NULL OR pg_catalog.array_position(p_essai_fils, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'liste de conversations d essai invalide' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(DISTINCT x ORDER BY x), '{}'::uuid[]) INTO v_liste FROM pg_catalog.unnest(p_essai_fils) x;
  IF pg_catalog.cardinality(v_liste) > 10 THEN
    RAISE EXCEPTION 'dix conversations d essai au plus' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) x WHERE NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.id = x)) THEN
    RAISE EXCEPTION 'conversation d essai inconnue' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages SET essai_fils = v_liste, modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle_essai', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('essaiFils', v_liste));
  RETURN pg_catalog.jsonb_build_object('essaiFils', pg_catalog.to_jsonb(v_liste));
END;
$f$;

REVOKE ALL ON FUNCTION private.praxis_essai() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.direction_praxis_regler_essai(uuid[]) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_regler_essai(uuid[]) TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_regler_essai(uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_regler_essai(uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_regler_essai(uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_regler_essai(uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_essai()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.praxis_essai()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.praxis_fil_refus(uuid,public.gender[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_etat()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_boite(text,text,integer)', 'EXECUTE')
     OR (SELECT r.essai_fils FROM private.praxis_reglages r) <> '{}'::uuid[] THEN
    RAISE EXCEPTION 'PRAXIS-ESSAI : droits ou etat incorrects apres installation';
  END IF;
END
$postflight$;
