-- PX-1 : RETOUCHE DE LA MESSAGERIE, seule, installee seule (arbitrage AR-2 / AR-6 du pilote, 16/11/2026, accord du Pilote
-- Messagerie : « VAS-Y »). Deux fonctions internes a AUTEUR EXPLICITE, extraites par ancrage des deux portes humaines :
--   * private.com_envoyer_message_interne(auteur, role, foyer, fil, texte, cle, controle_humain), extraite de
--     public.com_envoyer_message ;
--   * private.com_annonce_envoyer_interne(auteur, cotes, publics, titre, texte, programmee_le, courriel, cle), extraite de
--     public.com_annonce_envoyer.
-- Les CORPS SONT DEPLACES MOT POUR MOT (a deux remplacements pres, dits ci-dessous). Les portes humaines gardent leur
-- appelant, leur validation et leurs refus, puis appellent l'interne : comportement humain inchange (scenarios de la
-- messagerie et des annonces rejoues avant et apres, listes dans la PR).
--
-- Ce qui change dans les corps :
--   message : `moi.id`, `moi.role`, `moi.foyer` deviennent les parametres ; le test `peut_ecrire` de
--             private.com_fil_json (appele, jamais retouche) ne se fait que si `p_controle_humain` est vrai. Il n'est passe
--             a FAUX que par public.praxis_ecrire, apres ses propres controles (fil de l'academie, mineur, repris par
--             l'equipe, plafonds), sous le verrou du fil.
--   annonce : `v_moi` est `p_auteur`, `v_cotes` est `p_cotes` (la porte humaine passe private.com_annonce_cotes()).
-- private.com_annonce_distribuer, com_appelant*, com_fil_json, com_paires, tous les declencheurs : NON touches.
--
-- Les deux fonctions internes n'ont AUCUN EXECUTE pour PUBLIC, anon, authenticated, service_role, agent_ro : seules des
-- fonctions DEFINER du meme proprietaire les appellent.
--
-- FICHIER SANS EFFACEMENT. Sans BEGIN/COMMIT de premier niveau. Une ancre trouvee une seule fois, sinon la migration echoue.

CREATE FUNCTION pg_temp.remplacer_bloc(p_def text, p_debut text, p_fin text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_i integer;
  v_j integer;
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_debut, ''))) / pg_catalog.length(p_debut);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PRAXIS-COM : ancre de debut % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_fin, ''))) / pg_catalog.length(p_fin);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PRAXIS-COM : ancre de fin % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  v_i := pg_catalog.strpos(p_def, p_debut);
  v_j := pg_catalog.strpos(p_def, p_fin) + pg_catalog.length(p_fin);
  IF v_j <= v_i THEN
    RAISE EXCEPTION 'PRAXIS-COM : ancres de % dans le mauvais ordre', p_nom;
  END IF;
  RETURN pg_catalog.substr(p_def, 1, v_i - 1) || p_apres || pg_catalog.substr(p_def, v_j);
END;
$f$;

CREATE FUNCTION private.com_envoyer_message_interne(p_auteur uuid, p_role text, p_foyer uuid, p_fil_id uuid,
                                                    p_texte text, p_cle_idempotence uuid, p_controle_humain boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_json jsonb;
  v_id uuid;
  v_le timestamptz;
BEGIN
  PERFORM 1 FROM public.com_fils f WHERE f.id = p_fil_id FOR UPDATE;
  IF p_controle_humain THEN
    v_json := private.com_fil_json(p_fil_id, p_auteur, p_role, p_foyer);
    IF v_json IS NULL OR NOT coalesce((v_json ->> 'peut_ecrire')::boolean, false) THEN
      RAISE EXCEPTION 'COM-BACK-1 fil indisponible' USING ERRCODE = '42501';
    END IF;
  END IF;
  IF (v_json -> 'objet' ->> 'type') = 'candidature' AND p_role <> 'admin'
     AND NOT EXISTS (SELECT 1 FROM public.com_messages x
                      WHERE x.fil_id = p_fil_id AND x.auteur_id = p_auteur
                        AND x.cle_idempotence = p_cle_idempotence)
     AND (SELECT pg_catalog.count(*) FROM public.com_messages x
           WHERE x.fil_id = p_fil_id AND x.auteur_id = p_auteur
             AND x.envoye_le > pg_catalog.clock_timestamp() - interval '24 hours') >= 30 THEN
    RAISE EXCEPTION 'COM-CAND plafond de 30 messages par jour atteint' USING ERRCODE = '53400';
  END IF;
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)
  VALUES (p_fil_id, p_auteur, p_cle_idempotence, pg_catalog.btrim(p_texte))
  ON CONFLICT (fil_id, auteur_id, cle_idempotence) DO NOTHING
  RETURNING id, envoye_le INTO v_id, v_le;
  IF v_id IS NULL THEN
    SELECT m.id, m.envoye_le INTO v_id, v_le FROM public.com_messages m
    WHERE m.fil_id = p_fil_id AND m.auteur_id = p_auteur AND m.cle_idempotence = p_cle_idempotence;
  ELSE
    UPDATE public.com_fils SET dernier_message_le = v_le WHERE id = p_fil_id;
    INSERT INTO public.com_lectures (fil_id, profile_id, lu_jusqu_au)
    VALUES (p_fil_id, p_auteur, v_le)
    ON CONFLICT (fil_id, profile_id) DO UPDATE
      SET lu_jusqu_au = greatest(public.com_lectures.lu_jusqu_au, EXCLUDED.lu_jusqu_au);
    PERFORM public.log_sensitive_access('com_envoyer_message', 'com_messages', v_id::text, '{}'::jsonb);
  END IF;
  RETURN pg_catalog.jsonb_build_object('id', v_id, 'envoye_le', v_le);
END;
$function$;

CREATE FUNCTION private.com_annonce_envoyer_interne(p_auteur uuid, p_cotes public.gender[], p_publics text[],
                                                    p_titre text, p_texte text, p_programmee_le timestamptz,
                                                    p_courriel boolean, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := p_auteur;
  v_publics text[];
  v_cotes public.gender[];
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_titre text := pg_catalog.btrim(coalesce(p_titre, ''));
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_ligne public.com_annonces%ROWTYPE;
  v_nb integer;
BEGIN
  IF p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES cle absente' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_ligne FROM public.com_annonces a
   WHERE a.auteur_id = v_moi AND a.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
      'etat', CASE WHEN v_ligne.diffusee_le > v_maintenant THEN 'planifiee' ELSE 'publiee' END,
      'le', v_ligne.diffusee_le,
      'destinataires', (SELECT e.destinataires FROM public.com_annonce_envois e
                         WHERE e.annonce_id = v_ligne.id));
  END IF;
  v_publics := private.com_annonce_publics_valides(p_publics);
  IF v_texte = '' OR pg_catalog.length(v_texte) > 5000 OR pg_catalog.length(v_titre) > 120 THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES annonce invalide' USING ERRCODE = '22023';
  END IF;
  -- Le titre est facultatif : sans titre, le debut de la premiere ligne.
  IF v_titre = '' THEN
    v_titre := pg_catalog.btrim(pg_catalog.left(pg_catalog.split_part(v_texte, pg_catalog.chr(10), 1), 80));
  END IF;
  IF p_programmee_le IS NOT NULL
     AND (p_programmee_le < v_maintenant + interval '5 minutes'
          OR p_programmee_le > v_maintenant + interval '14 days') THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES date de diffusion hors bornes' USING ERRCODE = '22023';
  END IF;
  v_cotes := p_cotes;
  IF pg_catalog.cardinality(v_cotes) = 0 THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES cote inconnu' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.com_annonces
    (auteur_id, audience, groupe_id, titre, texte, diffusee_le, programmee, cle_idempotence)
  VALUES (v_moi, 'toutes', NULL, v_titre, v_texte,
          coalesce(p_programmee_le, v_maintenant), p_programmee_le IS NOT NULL, p_cle_idempotence)
  RETURNING * INTO v_ligne;

  INSERT INTO public.com_annonce_destinataires (annonce_id, profile_id)
  SELECT v_ligne.id, x.profile_id FROM private.com_annonce_personnes(v_publics, v_cotes) x;
  GET DIAGNOSTICS v_nb = ROW_COUNT;
  IF v_nb = 0 THEN
    -- Un public vide ne s'envoie pas : tout est annule.
    RAISE EXCEPTION 'ANNONCES-SIMPLES aucun destinataire' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.com_annonce_envois (annonce_id, publics, cotes, destinataires, courriel)
  VALUES (v_ligne.id, v_publics, v_cotes, v_nb, coalesce(p_courriel, false));

  PERFORM public.log_sensitive_access('com_annonce_envoyer', 'com_annonces', v_ligne.id::text,
    pg_catalog.jsonb_build_object('publics', v_publics, 'destinataires', v_nb,
                                  'courriel', coalesce(p_courriel, false)));

  IF p_programmee_le IS NULL THEN
    PERFORM private.com_annonce_distribuer(v_ligne.id);
  END IF;

  RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
    'etat', CASE WHEN v_ligne.programmee THEN 'planifiee' ELSE 'publiee' END,
    'le', v_ligne.diffusee_le,
    'destinataires', v_nb);
END;
$function$;

REVOKE ALL ON FUNCTION
  private.com_envoyer_message_interne(uuid, text, uuid, uuid, text, uuid, boolean),
  private.com_annonce_envoyer_interne(uuid, public.gender[], text[], text, text, timestamptz, boolean, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Les portes humaines appellent l'interne (ancrage : du debut a la fin du bloc deplace).
DO $retouche$
DECLARE
  v_f regprocedure;
  v_def text;
  v_com text;
BEGIN
  v_f := 'public.com_envoyer_message(uuid,text,uuid)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'com_envoyer_message_interne') = 0 THEN
    v_def := pg_temp.remplacer_bloc(v_def,
      $a$  PERFORM 1 FROM public.com_fils f WHERE f.id = p_fil_id FOR UPDATE;$a$,
      $a$  RETURN pg_catalog.jsonb_build_object('id', v_id, 'envoye_le', v_le);$a$,
      '  RETURN private.com_envoyer_message_interne(moi.id, moi.role, moi.foyer, p_fil_id, p_texte, p_cle_idempotence, true);',
      'com_envoyer_message');
    EXECUTE v_def;
    v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
    END IF;
  END IF;

  v_f := 'public.com_annonce_envoyer(text[],text,text,timestamptz,boolean,uuid)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'com_annonce_envoyer_interne') = 0 THEN
    v_def := pg_temp.remplacer_bloc(v_def,
      $a$  IF p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES cle absente' USING ERRCODE = '22023';$a$,
      $a$    'destinataires', v_nb);$a$,
      '  RETURN private.com_annonce_envoyer_interne(v_moi, private.com_annonce_cotes(), p_publics, p_titre, p_texte, p_programmee_le, p_courriel, p_cle_idempotence);',
      'com_annonce_envoyer');
    EXECUTE v_def;
    v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
    END IF;
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.com_envoyer_message(uuid,text,uuid)'::regprocedure),
                       'com_envoyer_message_interne') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
          'public.com_annonce_envoyer(text[],text,text,timestamptz,boolean,uuid)'::regprocedure),
          'com_annonce_envoyer_interne') = 0
     OR pg_catalog.has_function_privilege('authenticated',
          'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role',
          'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.com_annonce_envoyer_interne(uuid,public.gender[],text[],text,text,timestamptz,boolean,uuid)'::regprocedure,
          'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-COM : retouche absente ou fonction interne ouverte';
  END IF;
END
$postflight$;
