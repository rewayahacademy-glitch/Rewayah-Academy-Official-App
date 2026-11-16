-- PX-1 : les deux outils de Praxis qui ECRIVENT, apres le socle (20261129600000) et la retouche de la messagerie
-- (20261129610000, installee seule). Ils n'ecrivent QUE par les fonctions internes a auteur explicite :
--   * praxis_ecrire  -> private.com_envoyer_message_interne (controle humain a FAUX, apres tous les controles ci-dessous) ;
--   * praxis_annoncer -> private.com_annonce_envoyer_interne (courriel TOUJOURS faux, cotes = les deux).
-- Aucune copie de logique : memes paires (private.com_paires), memes non-lus, memes notifications que pour une personne.
--
-- Les refus de praxis_ecrire, dans cet ordre (chacun est un scenario) : cle (cle_refusee, eteint, autonome_requis),
-- parametre, longueur (1 500 signes), rejeu (meme cle d'idempotence : le meme message, rien d'ecrit), fil (fil_inconnu,
-- hors_academie, mineur), candidature (fils de candidature fermes a Praxis en PX-1 : com_paires y lit auth.uid()),
-- fil_ferme (la paire n'est pas autorisee), repris_par_equipe (R8), plafond_fil (3 messages de suite sans reponse de la
-- personne, R9), plafond (par heure, reglage praxis.envois_par_heure, R9). Praxis n'a AUCUN outil pour creer un fil, ajouter
-- un participant ou choisir un destinataire (R7) : le seul parametre est l'identifiant d'un fil existant de l'academie.
--
-- Praxis ecrit sous le role `accountant` de son profil : private.com_envoyer_message_interne ne lit le role que pour le
-- plafond des fils de candidature (ferme ici). Le compte n'est pas une partie du fil : l'auteur d'un message de
-- l'academie est rendu « administration » par private.com_fil_json (affichage, domaine de la messagerie).
--
-- FICHIER SANS EFFACEMENT. Additif. Sans BEGIN/COMMIT de premier niveau.

CREATE FUNCTION public.praxis_ecrire(p_cle text, p_fil uuid, p_texte text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_refus text;
  v_f public.com_fils%ROWTYPE;
  v_praxis uuid := private.praxis_profil();
  v_existant record;
  v_derniere_praxis timestamptz;
  v_derniere_autre timestamptz;
  v_plafond integer;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_cle_idempotence IS NULL OR v_texte = '' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 1500 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'longueur', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- Le verrou du fil (comme la porte humaine), puis le verrou des envois de Praxis (les plafonds se lisent au journal).
  SELECT f.* INTO v_f FROM public.com_fils f WHERE f.id = p_fil FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'fil_inconnu', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'fil_inconnu');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  -- Rejeu : le meme message, rien d'ecrit.
  SELECT m.id, m.envoye_le INTO v_existant FROM public.com_messages m
   WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis AND m.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'rejoue', p_fil, ARRAY[v_existant.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existant.id, 'envoye_le', v_existant.envoye_le, 'rejoue', true);
  END IF;
  v_refus := private.praxis_fil_refus(p_fil);
  IF v_refus IS NULL AND v_f.type_objet = 'candidature' THEN
    v_refus := 'candidature';
  END IF;
  IF v_refus IS NULL AND NOT EXISTS (
       SELECT 1 FROM private.com_paires(v_f.type_objet, v_f.objet_id) q
        WHERE q.a_nature = v_f.partie_a_nature AND q.a_id = v_f.partie_a_id
          AND q.b_nature = v_f.partie_b_nature AND q.b_id IS NOT DISTINCT FROM v_f.partie_b_id) THEN
    v_refus := 'fil_ferme';
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_praxis FROM public.com_messages m
     WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis;
    IF v_derniere_praxis IS NOT NULL AND EXISTS (
         SELECT 1 FROM public.com_messages m JOIN public.profiles pr ON pr.id = m.auteur_id
          WHERE m.fil_id = p_fil AND pr.role = 'admin'::public.app_role
            AND NOT EXISTS (SELECT 1 FROM private.comptes_officiels o WHERE o.profile_id = m.auteur_id)
            AND m.envoye_le > v_derniere_praxis) THEN
      v_refus := 'repris_par_equipe';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_autre FROM public.com_messages m
     WHERE m.fil_id = p_fil AND NOT private.praxis_est_academie(m.auteur_id);
    IF (SELECT pg_catalog.count(*) FROM public.com_messages m
         WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis
           AND m.envoye_le > coalesce(v_derniere_autre, '-infinity'::timestamptz)) >= 3 THEN
      v_refus := 'plafond_fil';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    v_plafond := coalesce((SELECT (a.value #>> '{}')::integer FROM public.app_config a
                            WHERE a.key = 'praxis.envois_par_heure'), 30);
    IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
         WHERE j.outil = 'ecrire' AND j.issue = 'ok'
           AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= v_plafond THEN
      v_refus := 'plafond';
    END IF;
  END IF;
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  -- Tous les controles sont faits : l'interne n'a plus a rejouer le test humain (p_controle_humain = faux).
  v_r := private.com_envoyer_message_interne(v_praxis, 'accountant', NULL, p_fil, v_texte, p_cle_idempotence, false);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'ok', p_fil, ARRAY[(v_r ->> 'id')::uuid], v_texte,
                               v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'envoye_le', v_r -> 'envoye_le');
END;
$f$;

CREATE FUNCTION public.praxis_annoncer(p_cle text, p_publics text[], p_titre text, p_texte text, p_cle_idempotence uuid)
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
  v_cotes public.gender[] := ARRAY['male', 'female']::public.gender[];
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

REVOKE ALL ON FUNCTION
  public.praxis_ecrire(text, uuid, text, uuid), public.praxis_annoncer(text, text[], text, text, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.praxis_ecrire(text, uuid, text, uuid), public.praxis_annoncer(text, text[], text, text, uuid)
  TO service_role;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.praxis_ecrire(text,uuid,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_ecrire(text,uuid,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_annoncer(text,text[],text,text,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_ecrire(text,uuid,text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS : droits des outils d''ecriture incorrects';
  END IF;
END
$postflight$;
