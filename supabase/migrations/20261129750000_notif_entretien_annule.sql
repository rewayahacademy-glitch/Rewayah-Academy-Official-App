-- BE-1i NOTIF-ENTRETIEN-ANNULE (pilote, 16/11/2026) : « prevenir l'intervieweur » du lot ENTRETIEN-SUIT-LE-DOSSIER.
--
-- Quand un refus, un retrait ou une pause annule l'entretien ouvert d'une candidature (migration
-- 20261129460000), les personnes qui menaient cet entretien (participants actifs) recoivent une notification
-- `entretien_annule` dans l'application, destination /admin/personnes/candidatures. L'auteur du geste n'est pas
-- prevenu de son propre geste. Aucun nom, aucun motif : la cause (refus, retrait ou pause) et la reference.
--
-- UN SEUL MOT D'EFFACEMENT DANS CE FICHIER : le retrait de la contrainte notifications_evenement_check, section 1,
-- pour la reecrire (seule exception admise, supabase/CLAUDE.md : la reecriture d'un CHECK). La liste est celle de
-- PRODUCTION lue par le pilote le 16/11/2026 a 23 h 51 UTC (schema seul, 61 valeurs) plus `entretien_annule`
-- (62). Le depot n'en a que 60 (`annonce_direction` manque dans le depot, ecart deja releve dans
-- 20261129600000_praxis_socle.sql). Gardes de la migration, qui s'arrete sans rien changer :
--   * si une valeur de la contrainte en place n'est pas dans la nouvelle liste (aucun evenement n'est retire) ;
--   * si une ligne existante de notifications porte un evenement absent de la nouvelle liste.
-- Additif pour le reste : aucune autre table touchee ; une fonction retouchee par ancrage
-- (private.candidatures_entretien_suit, section 2). Sans BEGIN/COMMIT de premier niveau.
--
-- Un echec de la notification n'annule JAMAIS l'annulation de l'entretien : la notification est posee dans un
-- sous-bloc, comme private.notification_bienvenue_equipe (l'erreur est dite en avertissement, journalisee dans
-- PUSH-1 s'il est installe).
-- Les entretiens deja annules par le rattrapage de 20261129460000 ne donnent aucune notification.
-- Aucun courriel : aucun texte de courriel n'est decide pour cet evenement.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.candidatures_entretien_suit()') IS NULL THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : installer d''abord 20261129460000_entretien_suit_le_dossier.sql';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check') THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : la contrainte notifications_evenement_check est absente';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La contrainte des evenements : production + entretien_annule
-- ============================================================
DO $contrainte$
DECLARE
  v_nouvelle text[] := ARRAY[
    'demande_recue','classe_validee','enseignant_affecte','demande_close','remplacement_propose','remplacement_pris',
    'demande_presentation','controle_mission_attribuee','controle_mission_non_controlee','classe_changee',
    'paiement_relance','acces_suspendu_paiement','acces_retabli_paiement','classe_creee','enseignant_change',
    'eleve_inscrit','eleve_retire','creneau_change','seance_annulee','seance_deplacee','enseignante_absente',
    'classe_supprimee','remplacement_avertissement','remplacement_pre_alerte','remplacement_inutile',
    'titulaire_en_retard','remplacant_arrive','paiement_recu','seance_terminee','remboursement_effectue',
    'litige_ouvert','litige_clos','seance_reportee','message_academie_eleve','admission_recue',
    'candidature_enseignant_a_examiner','demande_horaire_recue','creneau_personnalise_demande',
    'piece_identite_deposee','signalement_eleve_recu','suppression_compte_demandee',
    'remplacement_personne_en_salle','paiement_echoue','versement_coordonnees_a_valider',
    'versement_coordonnees_validees','remboursement_demande','remboursement_echec','cahier_en_retard',
    'bienvenue_equipe','entretien_reserve','entretien_rappel','entretien_tenu','entretien_a_replanifier',
    'retenu_entretien','pause_repondue','fermeture_annoncee','fermeture_levee','fermeture_conflit',
    'tout_est_pret','message_candidat_recu','annonce_direction',
    'entretien_annule'];
  v_def text;
  v_en_place text[];
  v_manque text;
  v_ligne text;
BEGIN
  IF pg_catalog.cardinality(v_nouvelle) <> 62
     OR (SELECT pg_catalog.count(DISTINCT e) FROM pg_catalog.unnest(v_nouvelle) AS e) <> 62 THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : la liste attendue compte 62 valeurs distinctes';
  END IF;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  -- Les valeurs en place : ARRAY['x'::text, ...] ou '{x,y}'::text[], selon le fichier qui a pose la contrainte.
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_en_place
    FROM pg_catalog.regexp_matches(v_def, '''([a-z_]+)''::text', 'g') WITH ORDINALITY AS r(m, ord);
  IF v_en_place IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_en_place
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_en_place IS NULL OR pg_catalog.cardinality(v_en_place) < 10 OR NOT ('demande_recue' = ANY (v_en_place)) THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : liste des evenements illisible dans %', v_def;
  END IF;
  SELECT pg_catalog.string_agg(e, ', ') INTO v_manque
    FROM pg_catalog.unnest(v_en_place) AS e WHERE NOT (e = ANY (v_nouvelle));
  IF v_manque IS NOT NULL THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : la contrainte en place porte des evenements absents de la liste : %', v_manque;
  END IF;
  SELECT pg_catalog.string_agg(DISTINCT n.evenement, ', ') INTO v_ligne
    FROM public.notifications n WHERE NOT (n.evenement = ANY (v_nouvelle));
  IF v_ligne IS NOT NULL THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : des notifications existantes portent des evenements absents de la liste : %', v_ligne;
  END IF;

  ALTER TABLE public.notifications DROP CONSTRAINT notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL OR v_def NOT LIKE '%''entretien_annule''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_nouvelle) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$contrainte$;

-- ============================================================
-- 2. Le declencheur de 20261129460000 previent ceux qui menaient l'entretien
-- ============================================================
DO $retouche$
DECLARE
  v_def text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef('private.candidatures_entretien_suit()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'BE-1i') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''suitLeDossier'', true));',
      '''suitLeDossier'', true));
  -- BE-1i : ceux qui menaient l''entretien sont prevenus (sauf l''auteur du geste). Un echec de la
  -- notification n''annule jamais l''annulation de l''entretien.
  BEGIN
    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    SELECT ep.profile_id, NULL, ''entretien_annule'',
           pg_catalog.jsonb_build_object(''session_id'', v_session, ''cause'', v_cause,
                                         ''reference'', NEW.reference, ''portee'', ''direction''),
           ''/admin/personnes/candidatures''
      FROM public.entretien_participants ep
     WHERE ep.session_id = v_session AND ep.retire_le IS NULL
       AND ep.profile_id IS DISTINCT FROM auth.uid();
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING ''entretien_annule : notification non posee (SQLSTATE %), annulation poursuivie'', SQLSTATE;
    IF pg_catalog.to_regprocedure(''private.push1_journaliser(text,text,text)'') IS NOT NULL THEN
      BEGIN
        EXECUTE ''SELECT private.push1_journaliser($1, $2, $3)''
          USING ''notification:entretien_annule'', NEW.id::text, SQLSTATE;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END IF;
  END;', 'suit.notification');
    EXECUTE v_def;
  END IF;
END
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidatures_entretien_suit()'::regprocedure),
                       'BE-1i') = 0
     OR pg_catalog.has_function_privilege('authenticated', 'private.candidatures_entretien_suit()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.candidatures_entretien_suit()'::regprocedure, 'EXECUTE')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'private.candidatures_entretien_suit()'::regprocedure
                       AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'NOTIF-ENTRETIEN-ANNULE : le declencheur n''a pas la forme attendue';
  END IF;
END
$postflight$;
