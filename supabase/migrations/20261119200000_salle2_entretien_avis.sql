-- SALLE-2-ENTRETIEN (plan des trois salles, lot 3, feu vert du directeur du
-- 07/11/2026 ; plage reservee par le garde-cap : 20261119200000-20261119299999).
--
-- Les avis de l'entretien, a chaque etape : le moment reserve, le rappel la
-- veille, le rappel 15 minutes avant, puis l'issue (tenu : l'academie ecrit
-- la suite ; non tenu : choisir un autre moment). Notification dans
-- l'application ET courriel (categorie « recrutement ») au candidat ;
-- notification dans l'application aux personnes qui menent l'entretien, et
-- courriel 15 minutes avant.
--
-- Rien n'est remplace : aucun CREATE OR REPLACE, aucune fonction existante
-- touchee. Une tache planifiee (pg_cron, chaque minute) lit les entretiens et
-- envoie ce qui est du ; un journal prive (une ligne par seance et par sorte
-- d'avis) rend chaque envoi unique, quel que soit le nombre de passages.
--
-- Mots d'effacement : le seul est le remplacement des deux CHECK de
-- public.notifications (retrait puis pose), inevitable pour en elargir la
-- liste. Ce fichier passe donc par la page collee du directeur.
--
-- Ce fichier porte l'union des trois lots du 07/11 (H : SALLE-3-ACCUEIL,
-- valeur 'bienvenue_equipe' ; E : SALLE-1-TOUT-ICI, 'retenu_entretien' et
-- '/attente' ; A : SALLE-2-ENTRETIEN), sur la base de PUSH-1 (20261112000000).
-- Il exige PUSH-1 installe et refuse une valeur hors de cette union. Il
-- accepte l'etat laisse par H (20261119000000, qui ajoute sa valeur au CHECK
-- en place) dans n'importe quel ordre, et lit le CHECK sous ses deux formes
-- (ARRAY['x'::text, ...] ou '{x,...}'::text[]). Le CHECK pose ici a la forme
-- '{x,...}'::text[].

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_evt text;
  v_dest text;
BEGIN
  IF pg_catalog.to_regclass('private.entretien_avis_envoyes') IS NOT NULL THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : deja installee';
  END IF;
  IF pg_catalog.to_regclass('public.entretiens') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_adresse_profil(uuid)') IS NULL THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : V1-a ou la file des courriels manque';
  END IF;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_evt FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_dest FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  -- PUSH-1 d'abord : ses valeurs doivent etre en place.
  -- Le CHECK s'ecrit sous deux formes selon le fichier qui l'a pose :
  -- ARRAY['x'::text, ...] ou '{x,...}'::text[] ; les deux sont lues.
  IF v_evt IS NULL OR v_evt !~ '[''{,]cahier_en_retard[''},]'
     OR v_dest IS NULL OR v_dest !~ '[''{,]/compte/paiements-recus[''},]' THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : installer PUSH-1 (20261112000000) avant ce fichier';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les CHECK de public.notifications : base PUSH-1, plus l'union H + E + A
-- ---------------------------------------------------------------------------
-- Toute valeur en place doit appartenir a l'union : un elargissement venu
-- d'ailleurs, inconnu de ce fichier, arrete l'installation au lieu d'etre
-- retire en silence.
DO $union$
DECLARE
  v_evt_union text[] := ARRAY[
    -- PUSH-1 (20261112000000), mot pour mot.
    'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
    'remplacement_propose', 'remplacement_pris', 'demande_presentation',
    'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
    'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
    'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
    'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
    'classe_supprimee',
    'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
    'titulaire_en_retard', 'remplacant_arrive',
    'paiement_recu',
    'seance_terminee',
    'remboursement_effectue', 'litige_ouvert', 'litige_clos',
    'seance_reportee',
    'message_academie_eleve',
    'admission_recue', 'candidature_enseignant_a_examiner', 'demande_horaire_recue',
    'creneau_personnalise_demande', 'piece_identite_deposee', 'signalement_eleve_recu',
    'suppression_compte_demandee', 'remplacement_personne_en_salle', 'paiement_echoue',
    'versement_coordonnees_a_valider', 'versement_coordonnees_validees',
    'remboursement_demande', 'remboursement_echec', 'cahier_en_retard',
    -- E (SALLE-1-TOUT-ICI) : retenu pour un entretien.
    'retenu_entretien',
    -- A (SALLE-2-ENTRETIEN).
    'entretien_reserve', 'entretien_rappel', 'entretien_tenu', 'entretien_a_replanifier',
    -- H (SALLE-3-ACCUEIL, 20261119000000) : la bienvenue dans l'equipe.
    'bienvenue_equipe'
  ];
  v_dest_union text[] := ARRAY[
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages', '/tuteur/foyer/recharge',
    '/eleve', '/tuteur', '/enseignant/classes', '/enseignant/journee',
    '/admin/operations/planning',
    '/admin/finance',
    '/tuteur/suivi', '/eleve/suivi',
    '/admin/personnes/candidatures', '/admin/personnes/demandes', '/admin/operations/demandes',
    '/admin/personnes/dossiers', '/admin/alertes', '/admin/personnes/suppressions',
    '/admin/finance/paiements', '/comptable/tresorerie/paiements-familles',
    '/comptable/paiements/beneficiaires', '/compte/paiements-recus',
    -- E.
    '/attente',
    -- A.
    '/attente/entretien'
    -- H : aucune nouvelle destination ('/enseignant/journee' existe deja).
  ];
  v_def text;
  v_valeur text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  -- Les deux formes du CHECK : '{x,y}'::text[] ou ARRAY['x'::text, ...].
  FOR v_valeur IN
    SELECT pg_catalog.unnest(pg_catalog.string_to_array(
             (pg_catalog.regexp_match(v_def, '''\{([^}]*)\}'''))[1], ','))
    UNION ALL
    SELECT (pg_catalog.regexp_matches(v_def, '''([a-z_]+)''', 'g'))[1] LOOP
    IF NOT v_valeur = ANY (v_evt_union) THEN
      RAISE EXCEPTION 'SALLE-2-ENTRETIEN : evenement en place hors de l''union : %', v_valeur;
    END IF;
  END LOOP;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  FOR v_valeur IN
    SELECT pg_catalog.unnest(pg_catalog.string_to_array(
             (pg_catalog.regexp_match(v_def, '''\{([^}]*)\}'''))[1], ','))
    UNION ALL
    SELECT (pg_catalog.regexp_matches(v_def, '''(/[a-z/-]*)''', 'g'))[1] LOOP
    IF NOT v_valeur = ANY (v_dest_union) THEN
      RAISE EXCEPTION 'SALLE-2-ENTRETIEN : destination en place hors de l''union : %', v_valeur;
    END IF;
  END LOOP;

  EXECUTE 'ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check';
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement = ANY (%L::text[]))',
    v_evt_union);
  EXECUTE 'ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check';
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK ('
    'destination = ANY (%L::text[]) OR destination ~ %L)',
    v_dest_union,
    '^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$');
END
$union$;

-- ---------------------------------------------------------------------------
-- 2. Le journal des avis envoyes (prive, aucun droit client)
-- ---------------------------------------------------------------------------
CREATE TABLE private.entretien_avis_envoyes (
  session_id uuid NOT NULL REFERENCES public.entretiens(session_id),
  sorte text NOT NULL CHECK (sorte IN ('reserve', 'veille', 'quinze', 'tenu', 'a_replanifier')),
  envoye_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (session_id, sorte)
);
REVOKE ALL ON private.entretien_avis_envoyes FROM PUBLIC;
COMMENT ON TABLE private.entretien_avis_envoyes IS
  'SALLE-2-ENTRETIEN (07/11/2026) : un avis par seance d''entretien et par sorte (reserve, veille, '
  'quinze, tenu, a_replanifier), pose par private.entretien_avis_passer ; rend chaque envoi unique.';

-- ---------------------------------------------------------------------------
-- 3. L'envoi des avis dus
-- ---------------------------------------------------------------------------
-- L'heure locale d'un compte, pour les messages : `debut_local` et `fuseau`
-- (lus par les modeles de courriel, `quandLocal`). Sans fuseau connu (un
-- compte sans fiche enseignant), rien : le message se passe d'heure plutot
-- que d'en dire une fausse.
CREATE FUNCTION private.entretien_heure_locale(p_profil uuid, p_debut timestamptz)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT pg_catalog.jsonb_build_object(
              'debut_local', pg_catalog.to_char(p_debut AT TIME ZONE tp.timezone_iana, 'YYYY-MM-DD"T"HH24:MI'),
              'fuseau', tp.timezone_iana)
       FROM public.teacher_profiles tp WHERE tp.profile_id = p_profil),
    '{}'::jsonb);
$function$;

-- Un avis au candidat : notification dans l'application et courriel.
CREATE FUNCTION private.entretien_avis_candidat(
  p_candidat uuid, p_session uuid, p_sorte text, p_evenement text, p_debut timestamptz,
  p_fin timestamptz, p_destination text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_params jsonb := pg_catalog.jsonb_build_object(
    'session_id', p_session, 'debut', p_debut, 'fin', p_fin, 'sorte', p_sorte,
    'portee', 'soi')
    || private.entretien_heure_locale(p_candidat, p_debut);
BEGIN
  INSERT INTO public.notifications (destinataire, evenement, params, destination)
  VALUES (p_candidat, p_evenement, v_params, p_destination);
  PERFORM public.courriel_enfiler('recrutement', p_evenement,
    public.courriel_adresse_profil(p_candidat), p_candidat,
    v_params || pg_catalog.jsonb_build_object('destination', p_destination),
    'entretien:' || p_session::text || ':' || p_sorte || ':candidat');
END;
$function$;

-- Un avis aux personnes qui menent l'entretien (participants actifs) :
-- notification dans l'application, et courriel si [p_courriel].
CREATE FUNCTION private.entretien_avis_participants(
  p_session uuid, p_sorte text, p_evenement text, p_debut timestamptz, p_fin timestamptz,
  p_reference text, p_courriel boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_params jsonb := pg_catalog.jsonb_build_object(
    'session_id', p_session, 'debut', p_debut, 'fin', p_fin, 'sorte', p_sorte,
    'reference', p_reference, 'participant', true, 'portee', 'direction');
  v_p uuid;
BEGIN
  FOR v_p IN SELECT ep.profile_id FROM public.entretien_participants ep
              WHERE ep.session_id = p_session AND ep.retire_le IS NULL LOOP
    INSERT INTO public.notifications (destinataire, evenement, params, destination)
    VALUES (v_p, p_evenement, v_params || private.entretien_heure_locale(v_p, p_debut),
            '/admin/personnes/candidatures');
    IF p_courriel THEN
      PERFORM public.courriel_enfiler('recrutement', p_evenement || '_direction',
        public.courriel_adresse_profil(v_p), v_p,
        v_params || private.entretien_heure_locale(v_p, p_debut)
          || pg_catalog.jsonb_build_object('destination', '/admin/personnes/candidatures'),
        'entretien:' || p_session::text || ':' || p_sorte || ':' || v_p::text);
    END IF;
  END LOOP;
END;
$function$;

-- Le passage : tout ce qui est du a [p_maintenant]. Rend le nombre d'avis
-- poses. Chaque avis n'est envoye qu'une fois (journal, cle primaire).
CREATE FUNCTION private.entretien_avis_passer(p_maintenant timestamptz)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_e record;
  v_n integer := 0;
  v_sorte text;
BEGIN
  FOR v_e IN
    SELECT e.session_id, e.candidat_id, e.issue, e.planifie_le, e.consigne_le,
           s.started_at, s.ended_at, c.reference
      FROM public.entretiens e
      JOIN public.sessions s ON s.id = e.session_id AND s.deleted_at IS NULL
      JOIN public.candidatures c ON c.id = e.candidature_id
     WHERE c.issue = 'en_cours'
       AND (e.issue IS NULL OR e.consigne_le > p_maintenant - interval '7 days')
       AND s.started_at > p_maintenant - interval '30 days'
  LOOP
    IF v_e.issue IS NULL THEN
      -- Reserve (par le candidat ou planifie par la direction).
      INSERT INTO private.entretien_avis_envoyes (session_id, sorte)
      VALUES (v_e.session_id, 'reserve') ON CONFLICT DO NOTHING;
      IF FOUND THEN
        PERFORM private.entretien_avis_candidat(v_e.candidat_id, v_e.session_id, 'reserve',
          'entretien_reserve', v_e.started_at, v_e.ended_at, '/attente/entretien');
        PERFORM private.entretien_avis_participants(v_e.session_id, 'reserve', 'entretien_reserve',
          v_e.started_at, v_e.ended_at, v_e.reference, false);
        v_n := v_n + 1;
      END IF;
      -- La veille : seulement si l'entretien a ete fixe plus de 24 heures avant.
      IF v_e.started_at <= p_maintenant + interval '24 hours'
         AND v_e.started_at > p_maintenant + interval '1 hour'
         AND v_e.planifie_le <= v_e.started_at - interval '24 hours' THEN
        INSERT INTO private.entretien_avis_envoyes (session_id, sorte)
        VALUES (v_e.session_id, 'veille') ON CONFLICT DO NOTHING;
        IF FOUND THEN
          PERFORM private.entretien_avis_candidat(v_e.candidat_id, v_e.session_id, 'veille',
            'entretien_rappel', v_e.started_at, v_e.ended_at, '/attente/entretien');
          PERFORM private.entretien_avis_participants(v_e.session_id, 'veille', 'entretien_rappel',
            v_e.started_at, v_e.ended_at, v_e.reference, false);
          v_n := v_n + 1;
        END IF;
      END IF;
      -- 15 minutes avant.
      IF v_e.started_at <= p_maintenant + interval '15 minutes'
         AND v_e.started_at > p_maintenant THEN
        INSERT INTO private.entretien_avis_envoyes (session_id, sorte)
        VALUES (v_e.session_id, 'quinze') ON CONFLICT DO NOTHING;
        IF FOUND THEN
          PERFORM private.entretien_avis_candidat(v_e.candidat_id, v_e.session_id, 'quinze',
            'entretien_rappel', v_e.started_at, v_e.ended_at, '/attente/entretien');
          PERFORM private.entretien_avis_participants(v_e.session_id, 'quinze', 'entretien_rappel',
            v_e.started_at, v_e.ended_at, v_e.reference, true);
          v_n := v_n + 1;
        END IF;
      END IF;
    ELSE
      -- L'issue est consignee : au candidat seulement, jamais l'avis ni le
      -- compte rendu.
      v_sorte := CASE WHEN v_e.issue = 'tenu' THEN 'tenu' ELSE 'a_replanifier' END;
      INSERT INTO private.entretien_avis_envoyes (session_id, sorte)
      VALUES (v_e.session_id, v_sorte) ON CONFLICT DO NOTHING;
      IF FOUND THEN
        PERFORM private.entretien_avis_candidat(v_e.candidat_id, v_e.session_id, v_sorte,
          CASE WHEN v_sorte = 'tenu' THEN 'entretien_tenu' ELSE 'entretien_a_replanifier' END,
          v_e.started_at, v_e.ended_at, '/attente/entretien');
        v_n := v_n + 1;
      END IF;
    END IF;
  END LOOP;
  RETURN v_n;
END;
$function$;

ALTER FUNCTION private.entretien_heure_locale(uuid, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_heure_locale(uuid, timestamptz) FROM PUBLIC;
ALTER FUNCTION private.entretien_avis_candidat(uuid, uuid, text, text, timestamptz, timestamptz, text) OWNER TO postgres;
ALTER FUNCTION private.entretien_avis_participants(uuid, text, text, timestamptz, timestamptz, text, boolean) OWNER TO postgres;
ALTER FUNCTION private.entretien_avis_passer(timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_avis_candidat(uuid, uuid, text, text, timestamptz, timestamptz, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.entretien_avis_participants(uuid, text, text, timestamptz, timestamptz, text, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.entretien_avis_passer(timestamptz) FROM PUBLIC;
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.entretien_avis_passer(timestamptz) FROM %I', v_role);
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.entretien_avis_candidat(uuid, uuid, text, text, timestamptz, timestamptz, text) FROM %I', v_role);
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.entretien_avis_participants(uuid, text, text, timestamptz, timestamptz, text, boolean) FROM %I', v_role);
      EXECUTE pg_catalog.format('REVOKE ALL ON private.entretien_avis_envoyes FROM %I', v_role);
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.entretien_heure_locale(uuid, timestamptz) FROM %I', v_role);
    END IF;
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 4. La tache planifiee, chaque minute
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('entretien_avis', '* * * * *',
      'SELECT private.entretien_avis_passer(pg_catalog.clock_timestamp())')$cron$;
  ELSE
    RAISE NOTICE 'SALLE-2-ENTRETIEN : pg_cron absente, rien n''est planifie';
  END IF;
END
$planification$;

-- ---------------------------------------------------------------------------
-- 5. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_evt text;
  v_dest text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_evt FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_dest FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  IF v_evt NOT LIKE '%entretien_reserve%' OR v_evt NOT LIKE '%cahier_en_retard%'
     OR v_evt NOT LIKE '%retenu_entretien%' OR v_evt NOT LIKE '%demande_recue%' THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : evenements incomplets : %', v_evt;
  END IF;
  IF v_dest NOT LIKE '%/attente/entretien%' OR v_dest NOT LIKE '%/compte/paiements-recus%'
     OR v_dest NOT LIKE '%/tuteur/classes/%' THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : destinations incompletes : %', v_dest;
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.entretien_avis_passer(timestamptz)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.entretien_avis_passer(timestamptz)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE-2-ENTRETIEN : envoi des avis ouvert au client';
  END IF;
END
$postflight$;
