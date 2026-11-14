-- MESSAGERIE-PUSH (14/11/2026, ordre du pilote apres #477) : a chaque message
-- d'un candidat, la direction de SON cote (CAND-Q07) est prevenue par une
-- notification « a faire », un push et un courriel, par le circuit existant
-- (PUSH-1 : private.push1_ajouter, puis les declencheurs de
-- public.notifications : push_depuis_notification, courriel_depuis_notification).
-- Cote candidat, rien ne change (pending_kyc : l'avis dans l'application suffit).
--
-- FICHIER A MOT D'EFFACEMENT (decision du directeur relayee par le pilote le
-- 14/11 : la reecriture d'un CHECK est autorisee) : deux contraintes CHECK se
-- remplacent (retrait puis ajout de la meme). Le serveur Supabase demande une
-- seconde confirmation que l'application n'affiche pas : le fichier se colle
-- dans l'editeur SQL, APRES 20261125800000. Aucune donnee n'est supprimee.
-- Sans BEGIN ni COMMIT de premier niveau ; chaque bloc est atomique.
--
-- Methode des contraintes : celle de 20261123961000 (la liste en place est LUE,
-- la valeur nouvelle y est ajoutee, rien d'autre n'est retire ni ajoute) ;
-- un rejeu ne change rien.
--
-- Contenu :
--   1. evenement « message_candidat_recu » dans notifications_evenement_check ;
--   2. destination « /admin/operations/communications/messages[/<fil>] » dans
--      notifications_destination_check (le fil s'ouvre directement) ;
--   3. « a faire » (geste_requis) : notification_geste_requis, par ancre ;
--   4. push (categorie admissions, etiquette messages_candidats : le telephone
--      garde UNE alerte « N messages de candidats ») et courriel (portee
--      direction) ;
--   5. l'emetteur : apres un message, si l'auteur est le candidat de la
--      candidature du fil, chaque direction active de son cote ; une seule
--      notification ouverte par fil et par personne (push1_ajouter, source =
--      le fil) : dix messages d'affilee ne font qu'un push ;
--   6. la cloture : la lecture du fil par cette personne (com_lectures, que
--      com_marquer_lu et com_envoyer_message ecrivent) pose geste_fait_le de
--      SA notification ; le message suivant en ouvre une nouvelle.
-- Un echec n'empeche jamais l'envoi du message : journal private.notifications_echecs.
-- Jamais un mineur : seuls des comptes « admin » actifs sont destinataires.
-- Aucun nom ni texte dans params : le detail se lit dans l'application.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.com_signaux') IS NULL THEN
    RAISE EXCEPTION 'messagerie push : installer d''abord 20261125800000_messagerie_temps_reel.sql';
  END IF;
  IF pg_catalog.to_regprocedure('private.push1_ajouter(uuid,text,jsonb,text,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.push1_journaliser(text,text,text)') IS NULL
     OR pg_catalog.to_regclass('private.push_evenements') IS NULL
     OR pg_catalog.to_regclass('private.notification_courriel') IS NULL THEN
    RAISE EXCEPTION 'messagerie push : PUSH-1 (20261112000100, 20261112000200) n''est pas installe';
  END IF;
  IF pg_catalog.to_regprocedure('private.com_candidature_lisible(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'messagerie push : MESSAGES-CANDIDAT (20261119400100) n''est pas installe';
  END IF;
END
$preflight$;

-- 1. L'evenement -------------------------------------------------------------
DO $evenement$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'messagerie push : notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''message_candidat_recu''%' THEN
    RAISE NOTICE 'messagerie push : evenement deja dans la contrainte';
    RETURN;
  END IF;
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_liste
    FROM pg_catalog.regexp_matches(v_def, '''([a-z0-9_]+)''::text', 'g')
         WITH ORDINALITY AS r(m, ord);
  IF v_liste IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_liste
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z0-9_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_liste IS NULL OR pg_catalog.cardinality(v_liste) < 10
     OR NOT ('demande_recue' = ANY (v_liste)) THEN
    RAISE EXCEPTION 'messagerie push : liste des evenements illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['message_candidat_recu'];
  IF EXISTS (SELECT 1 FROM public.notifications n WHERE NOT (n.evenement = ANY (v_nouvelle))) THEN
    RAISE EXCEPTION 'messagerie push : une notification porte un evenement absent de la nouvelle liste, rien n''est change';
  END IF;
  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));
END
$evenement$;

-- 2. La destination ----------------------------------------------------------
DO $destination$
DECLARE
  v_def text;
  v_corps text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_destination_check';
  IF v_def IS NULL OR v_def NOT LIKE 'CHECK %' THEN
    RAISE EXCEPTION 'messagerie push : notifications_destination_check est absente ou illisible';
  END IF;
  IF v_def LIKE '%communications/messages%' THEN
    RAISE NOTICE 'messagerie push : destination deja dans la contrainte';
    RETURN;
  END IF;
  -- Le corps de la contrainte en place, garde tel quel ; la forme nouvelle
  -- s'y ajoute par un OU.
  v_corps := pg_catalog.substr(v_def, pg_catalog.length('CHECK ') + 1);
  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (%s OR destination ~ %L)',
    v_corps,
    '^/admin/operations/communications/messages(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})?$');
END
$destination$;

-- 3. « A faire » -------------------------------------------------------------
DO $geste$
DECLARE
  v_f regprocedure := 'private.notification_geste_requis(text,jsonb)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''cahier_en_retard'')';
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, '''message_candidat_recu''') > 0 THEN
    RAISE NOTICE 'messagerie push : geste deja requis';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'messagerie push : ancre de notification_geste_requis trouvee % fois (attendu 1)', v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''cahier_en_retard'',' || pg_catalog.chr(10)
    || '           -- MESSAGERIE-PUSH (14/11/2026) : repondre au candidat.' || pg_catalog.chr(10)
    || '           ''message_candidat_recu'')');
  IF NOT private.notification_geste_requis('message_candidat_recu', '{}'::jsonb)
     OR NOT private.notification_geste_requis('cahier_en_retard', '{}'::jsonb) THEN
    RAISE EXCEPTION 'messagerie push : notification_geste_requis mal retouchee';
  END IF;
END
$geste$;

-- 4. Push et courriel --------------------------------------------------------
INSERT INTO private.push_evenements (evenement, categorie, tag)
VALUES ('message_candidat_recu', 'admissions', 'messages_candidats')
ON CONFLICT (evenement) DO UPDATE SET categorie = EXCLUDED.categorie, tag = EXCLUDED.tag;

INSERT INTO private.notification_courriel (evenement, portee, courriel, push)
VALUES ('message_candidat_recu', 'direction', true, true)
ON CONFLICT (evenement, portee) DO UPDATE SET courriel = EXCLUDED.courriel, push = EXCLUDED.push;

-- 4 bis. Le courriel part dans la categorie « recrutement » (sa raison dit
-- « vous etes en relation avec notre recrutement ») et non « classes ».
-- public.courriel_depuis_notification retouchee par ancre (une fois).
DO $categorie$
DECLARE
  v_f regprocedure := 'public.courriel_depuis_notification()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := 'ELSE ''classes'' END';
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, '''message_candidat_recu''') > 0 THEN
    RAISE NOTICE 'messagerie push : categorie du courriel deja posee';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'messagerie push : ancre de courriel_depuis_notification trouvee % fois (attendu 1)', v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    'WHEN NEW.evenement = ''message_candidat_recu'' THEN ''recrutement''' || pg_catalog.chr(10)
    || '      ' || v_ancre);
END
$categorie$;

-- 5. L'emetteur --------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push1_depuis_message_candidat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_candidature uuid;
  v_dir record;
BEGIN
  BEGIN
    -- Le fil d'une candidature dont l'auteur est le candidat lui-meme.
    SELECT f.objet_id INTO v_candidature
      FROM public.com_fils f
      JOIN public.candidatures c ON c.id = f.objet_id
     WHERE f.id = NEW.fil_id
       AND f.type_objet = 'candidature'
       AND c.profile_id = NEW.auteur_id;
    IF v_candidature IS NULL THEN
      RETURN NULL;
    END IF;
    FOR v_dir IN
      SELECT pr.id
        FROM public.profiles pr
       WHERE pr.role = 'admin'
         AND pr.account_status = 'active'
         AND pr.deleted_at IS NULL
         AND (pr.access_until IS NULL OR pr.access_until > pg_catalog.now())
         AND pr.id <> NEW.auteur_id
         AND private.com_candidature_lisible(v_candidature, pr.id)
    LOOP
      PERFORM private.push1_ajouter(
        v_dir.id, 'message_candidat_recu',
        pg_catalog.jsonb_build_object('portee', 'direction', 'fil_id', NEW.fil_id),
        '/admin/operations/communications/messages/' || NEW.fil_id::text,
        NEW.fil_id::text);
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('message_candidat_recu', NEW.fil_id::text, SQLSTATE);
    RAISE WARNING 'messagerie push : notification non posee (%)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;

-- 6. La cloture --------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push1_clore_message_candidat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    UPDATE public.notifications n
       SET geste_fait_le = pg_catalog.now()
     WHERE n.destinataire = NEW.profile_id
       AND n.evenement = 'message_candidat_recu'
       AND n.params ->> 'source_id' = NEW.fil_id::text
       AND n.geste_requis
       AND n.geste_fait_le IS NULL;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('message_candidat_recu:lu', NEW.fil_id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.push1_depuis_message_candidat(),
  private.push1_clore_message_candidat()
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.push1_depuis_message_candidat(), '
         || 'private.push1_clore_message_candidat() FROM agent_ro';
  END IF;
END
$agent_ro$;

-- Apres le signal du temps reel (ordre alphabetique des declencheurs) :
-- « com_messages_signal » puis « com_messages_z_push_candidat ».
CREATE OR REPLACE TRIGGER com_messages_z_push_candidat
  AFTER INSERT ON public.com_messages
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_message_candidat();

CREATE OR REPLACE TRIGGER com_lectures_z_clore_candidat
  AFTER INSERT OR UPDATE OF lu_jusqu_au ON public.com_lectures
  FOR EACH ROW EXECUTE FUNCTION private.push1_clore_message_candidat();

-- Postflight ---------------------------------------------------------------
DO $postflight$
BEGIN
  IF (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
       WHERE c.conrelid = 'public.notifications'::regclass
         AND c.conname = 'notifications_evenement_check') NOT LIKE '%''message_candidat_recu''%' THEN
    RAISE EXCEPTION 'messagerie push : evenement absent de la contrainte';
  END IF;
  IF (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
       WHERE c.conrelid = 'public.notifications'::regclass
         AND c.conname = 'notifications_destination_check') NOT LIKE '%communications/messages%' THEN
    RAISE EXCEPTION 'messagerie push : destination absente de la contrainte';
  END IF;
  IF NOT private.notification_avec_courriel('message_candidat_recu', 'direction')
     OR NOT private.notification_avec_push('message_candidat_recu', 'direction') THEN
    RAISE EXCEPTION 'messagerie push : courriel ou push non ouvert pour la direction';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.push1_depuis_message_candidat()', 'execute')
     OR pg_catalog.has_function_privilege('anon', 'private.push1_clore_message_candidat()', 'execute') THEN
    RAISE EXCEPTION 'messagerie push : un emetteur est executable par un client';
  END IF;
END
$postflight$;
