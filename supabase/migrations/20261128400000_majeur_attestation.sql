-- MAJEUR (directeur, 16/11/2026) : « Il faut ajouter une consigne qui demande si le candidat a
-- plus de 18 ans. S'il a plus de 18 ans, il peut continuer ; sinon, il ne peut pas continuer. »
--
-- Ce fichier ne contient aucun mot d'effacement, ni BEGIN ni COMMIT seul sur une ligne :
-- l'enveloppe de la page ouvre la transaction.
--
-- Additif (B6) : deux colonnes facultatives sur candidatures, une fonction neuve, des champs
-- ajoutes aux lectures. L'ancien code de production continue de marcher ; une seule regle
-- change pour lui, voulue : l'envoi des reponses de la salle 1 est refuse sans attestation vraie
-- (erreur rendue `majorite_requise`). Aucune politique RLS, aucune machine a etats, aucun geste
-- de la direction ne change.
--
-- 1. candidatures.majorite_declaree (vrai : 18 ans ou plus ; faux : moins de 18 ans) et
--    majorite_attestee_le (l'instant de la declaration). Nulles ensemble : pas encore de
--    declaration. Une candidature d'enseignant seulement : les demandes de famille et d'eleve
--    adulte ne sont pas du recrutement.
-- 2. public.attester_majorite(boolean) : ecrite par le candidat seul (titulaire de la candidature
--    en cours, compte valide), jamais pour quelqu'un d'autre. Trace dans candidature_evenements
--    (type `engagement`). Une declaration « moins de 18 ans » met la candidature en pause tout de
--    suite (une version de plus, un evenement `pause` sans auteur, motif « Age ») ; rien n'est
--    supprime. Une declaration deja faite n'est pas changee par le candidat : la rejouer ne
--    change rien, dire l'inverse est refuse (`declaration_deja_faite`).
-- 3. private.candidature_etat_candidat : la cle `majorite` {declaree, attesteeLe} rejoint
--    l'etat du candidat (etat_dossier().candidature). `envoiBloque` ne change pas.
-- 4. envoyer_reponses_salle_examen : `majorite_requise` sans attestation vraie, avant tout
--    examen des reponses.
-- 5. Direction : lire_candidature rend `majorite` ; le filtre `majorite` (attestee, non_attestee,
--    moins_18) rejoint la liste et les voisins, par les aides private.be_*.
--
-- Lecteurs recenses (B1) : aucune colonne existante ne change de sens. Les fonctions retouchees
-- (envoyer_reponses_salle_examen, lire_candidature, lister_candidatures, voisins_candidature,
-- candidature_etat_candidat, be_filtre_valider, be_predicat) ne sont lues que par
-- lib/core/candidature/*_supabase.dart (champs ajoutes, facultatifs) et par les scenarios
-- supabase/tests/scenarios_cand_*.sql. Aucun index : les colonnes ne servent qu'au filtre de la
-- liste, deja borne a la portee de genre du lecteur.

ALTER TABLE public.candidatures
  ADD COLUMN majorite_declaree boolean NULL,
  ADD COLUMN majorite_attestee_le timestamptz NULL;
ALTER TABLE public.candidatures
  ADD CONSTRAINT candidatures_majorite_forme
  CHECK ((majorite_declaree IS NULL) = (majorite_attestee_le IS NULL));
COMMENT ON COLUMN public.candidatures.majorite_declaree IS
  'MAJEUR : vrai = le candidat atteste avoir 18 ans ou plus, faux = il declare avoir moins de 18 ans, nul = pas encore declare. Ecrite par public.attester_majorite seule.';

-- ============================================================
-- 1. Outil d'ancre (B4)
-- ============================================================

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'MAJEUR : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 2. L'attestation par le candidat
-- ============================================================

CREATE FUNCTION public.attester_majorite(p_majeur boolean)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(true);
  v_c public.candidatures;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'attestation reservee au titulaire d''une candidature en cours' USING ERRCODE = '42501';
  END IF;
  IF p_majeur IS NULL THEN
    RAISE EXCEPTION 'declaration attendue : vrai (18 ans ou plus) ou faux (moins de 18 ans)'
      USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF NOT coalesce(v_c.type_code = 'enseignant', false) THEN
    RAISE EXCEPTION 'attestation reservee aux candidatures d''enseignant' USING ERRCODE = '42501';
  END IF;

  IF v_c.majorite_declaree IS NOT NULL THEN
    -- Deja faite : la meme declaration rejouee ne change rien ; l'inverse est refuse.
    IF v_c.majorite_declaree IS DISTINCT FROM p_majeur THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'declaration_deja_faite');
    END IF;
  ELSE
    IF p_majeur THEN
      UPDATE public.candidatures
         SET majorite_declaree = true, majorite_attestee_le = v_maintenant
       WHERE id = v_c.id;
    ELSE
      UPDATE public.candidatures
         SET majorite_declaree = false, majorite_attestee_le = v_maintenant,
             en_pause = true, version = version + 1, derniere_activite = v_maintenant
       WHERE id = v_c.id;
    END IF;
    INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
    VALUES (v_c.id, 'engagement', v_uid,
            pg_catalog.jsonb_build_object('engagement', 'majorite', 'majeur', p_majeur));
    IF NOT p_majeur THEN
      INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, motif_interne, details)
      VALUES (v_c.id, 'pause', NULL,
              'Âge : la personne a déclaré avoir moins de 18 ans.',
              pg_catalog.jsonb_build_object('cause', 'age', 'auteur', 'systeme'));
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'majorite', (SELECT pg_catalog.jsonb_build_object(
                   'declaree', c.majorite_declaree,
                   'attesteeLe', private.cand_instant(c.majorite_attestee_le))
                   FROM public.candidatures c WHERE c.id = v_c.id),
    'candidature', public.etat_dossier() -> 'candidature');
END;
$function$;

ALTER FUNCTION public.attester_majorite(boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.attester_majorite(boolean) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.attester_majorite(boolean) TO authenticated;

-- ============================================================
-- 3. Retouches par ancre
-- ============================================================

DO $retouches$
DECLARE
  f_envoi regprocedure := 'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure;
  f_lire regprocedure := 'public.lire_candidature(uuid)'::regprocedure;
  f_liste regprocedure := 'public.lister_candidatures(jsonb,text,integer)'::regprocedure;
  f_voisins regprocedure := 'public.voisins_candidature(text,jsonb,text)'::regprocedure;
  f_etat regprocedure := 'private.candidature_etat_candidat()'::regprocedure;
  f_valider regprocedure := 'private.be_filtre_valider(jsonb)'::regprocedure;
  f_predicat regprocedure := 'private.be_predicat(public.candidatures,jsonb,uuid)'::regprocedure;
  v_def text;
  v_cles_avant text := '''heureMin'', ''heureMax'', ''joursMin'', ''pieceEnAttente'', ''responsable'']);';
  v_cles_apres text := '''heureMin'', ''heureMax'', ''joursMin'', ''pieceEnAttente'', ''responsable'',' || E'\n'
    || '                            ''majorite'']);';
  v_ou_avant text := '''pieceEnAttente'', ''responsable''])' || E'\n' || '           OR private.be_predicat(';
  v_ou_apres text := '''pieceEnAttente'', ''responsable'', ''majorite''])' || E'\n' || '           OR private.be_predicat(';
BEGIN
  -- L'envoi des reponses : refuse sans attestation vraie, avant tout examen.
  v_def := pg_catalog.pg_get_functiondef(f_envoi);
  v_def := pg_temp.remplacer(v_def, '  v_q := private.questionnaire_courant(v_c.type_code);',
    '  IF v_c.majorite_declaree IS DISTINCT FROM true THEN' || E'\n'
    || '    RETURN pg_catalog.jsonb_build_object(''erreur'', ''majorite_requise'');' || E'\n'
    || '  END IF;' || E'\n'
    || '  v_q := private.questionnaire_courant(v_c.type_code);', 'envoi.questionnaire');
  EXECUTE v_def;

  -- L'etat du candidat : la cle majorite.
  v_def := pg_catalog.pg_get_functiondef(f_etat);
  v_def := pg_temp.remplacer(v_def, '    ''paiement'', private.paiement_etat(v_c.id),',
    '    ''paiement'', private.paiement_etat(v_c.id),' || E'\n'
    || '    -- MAJEUR : l''attestation « 18 ans ou plus », nulle tant qu''elle n''est pas faite.' || E'\n'
    || '    ''majorite'', pg_catalog.jsonb_build_object(' || E'\n'
    || '      ''declaree'', v_c.majorite_declaree,' || E'\n'
    || '      ''attesteeLe'', private.cand_instant(v_c.majorite_attestee_le)),', 'etat.paiement');
  EXECUTE v_def;

  -- Le dossier de la direction : la cle majorite.
  v_def := pg_catalog.pg_get_functiondef(f_lire);
  v_def := pg_temp.remplacer(v_def,
    '    ''responsableNom'', private.be_nom_membre(v_c.responsable_id),',
    '    ''responsableNom'', private.be_nom_membre(v_c.responsable_id),' || E'\n'
    || '    ''majorite'', pg_catalog.jsonb_build_object(' || E'\n'
    || '      ''declaree'', v_c.majorite_declaree,' || E'\n'
    || '      ''attesteeLe'', private.cand_instant(v_c.majorite_attestee_le)),', 'lire.responsableNom');
  EXECUTE v_def;

  -- La liste et les voisins : la cle de filtre majorite (cle connue, puis predicat commun).
  v_def := pg_catalog.pg_get_functiondef(f_liste);
  v_def := pg_temp.remplacer(v_def, v_cles_avant, v_cles_apres, 'liste.cles');
  v_def := pg_temp.remplacer(v_def, v_ou_avant, v_ou_apres, 'liste.ou');
  EXECUTE v_def;
  v_def := pg_catalog.pg_get_functiondef(f_voisins);
  v_def := pg_temp.remplacer(v_def, v_cles_avant, v_cles_apres, 'voisins.cles');
  v_def := pg_temp.remplacer(v_def, v_ou_avant, v_ou_apres, 'voisins.ou');
  EXECUTE v_def;

  -- Les valeurs du filtre et son predicat (aides communes de la liste et des voisins).
  v_def := pg_catalog.pg_get_functiondef(f_valider);
  v_def := pg_temp.remplacer(v_def, '  IF (p_filtre ->> ''langueExplication'' IS NOT NULL',
    '  IF p_filtre ->> ''majorite'' IS NOT NULL' || E'\n'
    || '     AND p_filtre ->> ''majorite'' NOT IN (''attestee'', ''non_attestee'', ''moins_18'') THEN' || E'\n'
    || '    RAISE EXCEPTION ''valeur de filtre de candidatures invalide'' USING ERRCODE = ''22023'';' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF (p_filtre ->> ''langueExplication'' IS NOT NULL', 'valider.langue');
  EXECUTE v_def;
  v_def := pg_catalog.pg_get_functiondef(f_predicat);
  v_def := pg_temp.remplacer(v_def, '  IF v_piece IS NOT NULL THEN',
    '  IF p_filtre ->> ''majorite'' = ''attestee'' AND c.majorite_declaree IS NOT TRUE THEN' || E'\n'
    || '    RETURN false;' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF p_filtre ->> ''majorite'' = ''non_attestee'' AND c.majorite_declaree IS NOT NULL THEN' || E'\n'
    || '    RETURN false;' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF p_filtre ->> ''majorite'' = ''moins_18'' AND c.majorite_declaree IS NOT FALSE THEN' || E'\n'
    || '    RETURN false;' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF v_piece IS NOT NULL THEN', 'predicat.piece');
  EXECUTE v_def;
END;
$retouches$;

-- Une cle `majorite` seule filtre aussi : la liste ne demande les reponses que pour les autres cles.
-- (be_predicat lit les reponses seulement si une cle de reponse est posee : aucun changement.)

-- ============================================================
-- 4. Empreintes F86 et controle final
-- ============================================================

DO $f86$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure,
    'public.lire_candidature(uuid)'::regprocedure,
    'public.lister_candidatures(jsonb,text,integer)'::regprocedure,
    'public.voisins_candidature(text,jsonb,text)'::regprocedure
  ] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'MAJEUR') = 0 THEN
        v_com := v_com || ' MAJEUR (16/11/2026) : attestation 18 ans ou plus (envoi refuse sans elle, cle majorite, filtre majorite).';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.attester_majorite(boolean) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.attester_majorite(boolean); md5_functiondef=%s; guard_type=POSITIVE_CANDIDATE_SELF; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. MAJEUR : titulaire d une candidature d enseignant en cours au compte valide, sinon 42501 ; argument 22023 ; ecrit la declaration (vrai ou faux) une seule fois, rejouee identique sans effet, l inverse refuse declaration_deja_faite ; trace (engagement) ; moins de 18 ans : pause immediate (evenement pause, cause age) ; jamais pour une autre personne. Must-pass: supabase/tests/scenarios_majeur.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef('public.attester_majorite(boolean)'::regprocedure))));
END;
$f86$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure),
       'majorite_requise') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_etat_candidat()'::regprocedure),
          'attesteeLe') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure),
          'majorite') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure),
          '''majorite''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.voisins_candidature(text,jsonb,text)'::regprocedure),
          '''majorite''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.be_predicat(public.candidatures,jsonb,uuid)'::regprocedure),
          'non_attestee') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.be_filtre_valider(jsonb)'::regprocedure),
          'non_attestee') = 0 THEN
    RAISE EXCEPTION 'MAJEUR : retouche absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.attester_majorite(boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.attester_majorite(boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.attester_majorite(boolean)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.attester_majorite(boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'MAJEUR : droits inattendus';
  END IF;
END;
$postflight$;
