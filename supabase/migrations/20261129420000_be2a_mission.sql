-- BE-2a-1 (pilote, 16/11/2026, cahier CAHIER-BE-2A-MISSION.md §2.1 a §2.5) : une MISSION donne a une personne
-- (qui a deja un compte, quel que soit son role de personnel) un petit nombre de gestes sur les candidatures, dans un
-- perimetre, pour une duree, retirable, sans toucher a son compte.
--
-- ECART AU CAHIER, a lire : le cahier dit de brancher `candidature_geste_ouvrir`. Ce n'est pas assez. Chaque porte
-- publique de geste et chaque lecture commence par `public.app_role() = 'admin' AND public.app_account_valid()` : un
-- porteur de mission non administrateur serait refuse a la porte, avant d'atteindre le moteur. Et
-- `private.cand_lecteur()` (administrateur seulement) est lu par 19 migrations et par des fonctions qui n'ont que lui
-- pour garde (mes_entretiens, lire_entretien...) : il n'est PAS touche. A la place :
--   * `private.mission_acteur()` : la direction (cand_lecteur) OU un porteur de mission active ; meme forme de retour ;
--   * la garde de 13 portes de gestes et de 5 lectures est retouchee par ancrage (une ancre trouvee une seule fois par
--     fonction, sinon la migration echoue) : `(admin OU porteur de mission) ET compte valide` ;
--   * le moteur (`candidature_geste_ouvrir`) exige le droit de mission pour le geste ET le dossier.
-- Tout le reste reste reserve a la direction : import, lots (executer_lot_candidats), entretiens (lecture), paiement,
-- enseignants, historique, photo, PIECE D'IDENTITE (jamais lisible par une mission), mise en pause, refus, dispense.
-- Les gestes qu'une mission peut contenir sont donc limites a ceux dont la porte est ouverte ici
-- (`private.mission_gestes_ouverts()`), plus `lire` et `voir_contact` : aucun geste coche sans porte qui l'execute.
--
-- Le journal : `private.mission_journal` (accord, retrait, geste ouvert, geste refuse hors mission). Le geste accepte y
-- est ecrit a l'ouverture du geste par le moteur (evenement `geste_ouvert`, avec `mission_id`) ; si la porte refuse
-- ensuite (controles, version), la ligne reste et dit seulement que le moteur a ouvert, pas que le geste a abouti.
-- La table est a ajout seul par construction (aucune porte ne la modifie), non par declencheur : ce fichier n'emploie
-- aucun des trois mots d'effacement.
--
-- FICHIER SANS EFFACEMENT. Additif : trois tables, des fonctions neuves, des retouches par ancrage. Sans BEGIN/COMMIT
-- de premier niveau. Doit suivre 20261129410000 (valider_piece_candidat retouchee) : meme ancre de garde, inchangee.
--
-- LIMITES : `perimetre.liste` est refuse (vague 3) ; la langue du dossier est celle du dernier questionnaire envoye
-- (private.candidature_langues) ; un dossier sans questionnaire n'a aucune langue : il sort d'un perimetre a langues.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_n integer, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION 'BE-2a : ancre % trouvee % fois (% attendue)', p_nom, v_n, p_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- Les fonctions retouchees portent leur empreinte dans leur commentaire (md5_functiondef, controle F86) : elle est
-- recalculee apres chaque retouche. Les aides de ce lot portent le prefixe mission_, non cand_ : neuf aides cand_
-- exactement sont attendues par les scenarios de CAND-L1 (aucune de plus).
CREATE FUNCTION pg_temp.empreinte(p_f regprocedure)
RETURNS void
LANGUAGE plpgsql
AS $f$
DECLARE
  v_com text := coalesce(pg_catalog.obj_description(p_f, 'pg_proc'), '');
BEGIN
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f, v_com);
  END IF;
END;
$f$;

-- 1. Les tables
CREATE TABLE private.missions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  nom text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(nom)) BETWEEN 1 AND 80),
  gestes text[] NOT NULL CHECK (pg_catalog.cardinality(gestes) BETWEEN 1 AND 40),
  cree_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_creation uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  archivee_le timestamptz,
  archivee_par uuid REFERENCES public.profiles (id),
  motif_archive text,
  cle_archive uuid,
  UNIQUE (cree_par, cle_creation),
  CONSTRAINT missions_archive_complete CHECK (
    (archivee_le IS NULL AND archivee_par IS NULL AND motif_archive IS NULL AND cle_archive IS NULL)
    OR (archivee_le IS NOT NULL AND archivee_par IS NOT NULL AND cle_archive IS NOT NULL
        AND pg_catalog.length(pg_catalog.btrim(motif_archive)) BETWEEN 1 AND 240))
);
ALTER TABLE private.missions ENABLE ROW LEVEL SECURITY;

CREATE TABLE private.mission_attributions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  mission_id uuid NOT NULL REFERENCES private.missions (id),
  profile_id uuid NOT NULL REFERENCES public.profiles (id),
  accorde_par uuid NOT NULL REFERENCES public.profiles (id),
  debut timestamptz NOT NULL,
  fin timestamptz,
  perimetre jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(perimetre) = 'object'),
  cle_accord uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retiree_le timestamptz,
  retiree_par uuid REFERENCES public.profiles (id),
  motif_retrait text,
  cle_retrait uuid,
  UNIQUE (accorde_par, cle_accord),
  CONSTRAINT mission_attributions_dates CHECK (fin IS NULL OR fin > debut),
  CONSTRAINT mission_attributions_retrait_complet CHECK (
    (retiree_le IS NULL AND retiree_par IS NULL AND motif_retrait IS NULL AND cle_retrait IS NULL)
    OR (retiree_le IS NOT NULL AND retiree_par IS NOT NULL AND cle_retrait IS NOT NULL
        AND pg_catalog.length(pg_catalog.btrim(motif_retrait)) BETWEEN 1 AND 240))
);
ALTER TABLE private.mission_attributions ENABLE ROW LEVEL SECURITY;
CREATE UNIQUE INDEX mission_attributions_active_unique
  ON private.mission_attributions (mission_id, profile_id) WHERE retiree_le IS NULL;
CREATE INDEX mission_attributions_porteur_idx
  ON private.mission_attributions (profile_id) WHERE retiree_le IS NULL;

CREATE TABLE private.mission_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mission_id uuid REFERENCES private.missions (id),
  attribution_id uuid REFERENCES private.mission_attributions (id),
  evenement text NOT NULL CHECK (evenement IN ('mission_creee', 'mission_archivee', 'accord', 'retrait',
                                               'geste_ouvert', 'geste_refuse')),
  acteur_id uuid REFERENCES public.profiles (id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(payload) = 'object')
);
ALTER TABLE private.mission_journal ENABLE ROW LEVEL SECURITY;
CREATE INDEX mission_journal_mission_idx ON private.mission_journal (mission_id, cree_le);

REVOKE ALL ON TABLE private.missions, private.mission_attributions, private.mission_journal
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Les fonctions de droit (privees : aucun EXECUTE pour les roles de l'API)
CREATE FUNCTION private.mission_gestes_ouverts()
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT ARRAY['lire', 'voir_contact',
               'demander_complement', 'admettre_verifications', 'confirmer_moyen_paiement',
               'infirmer_moyen_paiement', 'debloquer_versement', 'definir_responsable', 'consigner_prevenu',
               'rattacher', 'planifier_entretien', 'consigner_entretien_tenu', 'consigner_entretien_non_tenu',
               'valider_piece', 'rouvrir', 'retirer']::text[];
$function$;

-- Vrai : la session est la direction active (administrateur valide, non supprime).
CREATE FUNCTION private.mission_est_direction()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM private.cand_lecteur());
$function$;

-- Vrai : la session porte au moins une attribution active d'une mission non archivee, avec un compte valide.
CREATE FUNCTION private.mission_porteuse()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid()
    AND EXISTS (
      SELECT 1
        FROM private.mission_attributions a
        JOIN private.missions m ON m.id = a.mission_id
        JOIN public.profiles h ON h.id = a.profile_id
       WHERE a.profile_id = auth.uid() AND a.retiree_le IS NULL
         AND a.debut <= pg_catalog.clock_timestamp()
         AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp())
         AND m.archivee_le IS NULL
         AND h.deleted_at IS NULL AND h.account_status = 'active'::public.account_status
         AND h.gender IS NOT NULL), false);
$function$;

-- Le droit d'une mission seule : le geste est dans une mission active de la session et le dossier est dans le
-- perimetre (meme cote que la personne, langue commune si `langues`, etape si `etapes`, dossier liste si `dossiers`).
-- Exigence positive : NULL vaut faux.
CREATE FUNCTION private.mission_droit_dossier(p_candidature uuid, p_geste text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid() AND EXISTS (
    SELECT 1
      FROM private.mission_attributions a
      JOIN private.missions m ON m.id = a.mission_id
      JOIN public.profiles h ON h.id = a.profile_id
      JOIN public.candidatures c ON c.id = p_candidature
     WHERE a.profile_id = auth.uid() AND a.retiree_le IS NULL
       AND a.debut <= pg_catalog.clock_timestamp()
       AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp())
       AND m.archivee_le IS NULL AND p_geste = ANY (m.gestes)
       AND h.deleted_at IS NULL AND h.account_status = 'active'::public.account_status
       AND h.gender IS NOT NULL AND c.genre = h.gender
       AND (a.perimetre -> 'langues' IS NULL
            OR ARRAY(SELECT pg_catalog.jsonb_array_elements_text(a.perimetre -> 'langues'))
               && private.candidature_langues(c.id))
       AND (a.perimetre -> 'etapes' IS NULL
            OR c.etape = ANY (ARRAY(SELECT pg_catalog.jsonb_array_elements_text(a.perimetre -> 'etapes'))))
       AND (a.perimetre -> 'dossiers' IS NULL
            OR a.perimetre -> 'dossiers' @> pg_catalog.to_jsonb(c.id::text))), false);
$function$;

-- Le droit unique du cahier (§2.3). La direction court-circuite les missions : son cote, ou l'exception
-- super-admin, ou les types sans genre (famille, eleve_adulte), comme le moteur de gestes ; aucune lecture de
-- mission_attributions. Sinon, la mission.
CREATE FUNCTION private.mission_droit(p_candidature uuid, p_geste text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    CASE WHEN private.mission_est_direction()
         THEN EXISTS (SELECT 1 FROM private.cand_lecteur() l
                        JOIN public.candidatures c ON c.id = p_candidature
                       WHERE l.genre IS NOT NULL
                         AND (l.super_admin OR c.genre = l.genre OR c.type_code IN ('famille', 'eleve_adulte')))
         ELSE private.mission_droit_dossier(p_candidature, p_geste) END, false);
$function$;

-- Pour les lectures ligne a ligne : la direction garde sa regle de lecture (le cote, deja dans la fonction appelante) ;
-- seule une mission est bornee ici par son perimetre.
CREATE FUNCTION private.mission_permis(p_candidature uuid, p_geste text)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT private.mission_est_direction() OR private.mission_droit_dossier(p_candidature, p_geste);
$function$;

-- Qui agit : la direction (cand_lecteur) ou, a defaut, un porteur de mission. Meme forme que cand_lecteur ; le contact
-- n'est jamais donne par ici a une mission (il se juge par dossier : voir_contact).
CREATE FUNCTION private.mission_acteur()
RETURNS TABLE (profile_id uuid, genre public.gender, super_admin boolean, contact boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT l.profile_id, l.genre, l.super_admin, l.contact FROM private.cand_lecteur() l
  UNION ALL
  SELECT p.id, p.gender, false, false
    FROM public.profiles p
   WHERE p.id = auth.uid() AND p.deleted_at IS NULL
     AND NOT private.mission_est_direction() AND private.mission_porteuse();
$function$;

-- Le perimetre : cles connues seulement, `cote` ecrit par le serveur (jamais choisi), `liste` reservee.
CREATE FUNCTION private.mission_perimetre_valide(p_perimetre jsonb, p_genre public.gender)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  v_p jsonb := coalesce(p_perimetre, '{}'::jsonb);
  v_cle text;
  v_out jsonb := pg_catalog.jsonb_build_object('cote', p_genre::text);
BEGIN
  IF pg_catalog.jsonb_typeof(v_p) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'perimetre invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  FOR v_cle IN SELECT k FROM pg_catalog.jsonb_object_keys(v_p) AS k LOOP
    IF v_cle NOT IN ('cote', 'langues', 'etapes', 'dossiers') THEN
      RAISE EXCEPTION 'perimetre invalide : cle % inconnue ou reservee', v_cle USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF v_p ? 'cote' AND v_p ->> 'cote' IS DISTINCT FROM p_genre::text THEN
    RAISE EXCEPTION 'perimetre invalide : le cote est celui de la personne, il ne se choisit pas'
      USING ERRCODE = '22023';
  END IF;
  IF v_p ? 'langues' THEN
    IF pg_catalog.jsonb_typeof(v_p -> 'langues') IS DISTINCT FROM 'array'
       OR pg_catalog.jsonb_array_length(v_p -> 'langues') = 0
       OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_p -> 'langues') e
                   WHERE pg_catalog.jsonb_typeof(e) <> 'string' OR (e #>> '{}') !~ '^[a-z][a-z0-9_]{1,39}$') THEN
      RAISE EXCEPTION 'perimetre invalide : langues' USING ERRCODE = '22023';
    END IF;
    v_out := v_out || pg_catalog.jsonb_build_object('langues', v_p -> 'langues');
  END IF;
  IF v_p ? 'etapes' THEN
    IF pg_catalog.jsonb_typeof(v_p -> 'etapes') IS DISTINCT FROM 'array'
       OR pg_catalog.jsonb_array_length(v_p -> 'etapes') = 0
       OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_p -> 'etapes') e
                   WHERE pg_catalog.jsonb_typeof(e) <> 'string'
                     OR (e #>> '{}') NOT IN ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee')) THEN
      RAISE EXCEPTION 'perimetre invalide : etapes' USING ERRCODE = '22023';
    END IF;
    v_out := v_out || pg_catalog.jsonb_build_object('etapes', v_p -> 'etapes');
  END IF;
  IF v_p ? 'dossiers' THEN
    IF pg_catalog.jsonb_typeof(v_p -> 'dossiers') IS DISTINCT FROM 'array'
       OR pg_catalog.jsonb_array_length(v_p -> 'dossiers') = 0
       OR pg_catalog.jsonb_array_length(v_p -> 'dossiers') > 500
       OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_p -> 'dossiers') e
                   WHERE pg_catalog.jsonb_typeof(e) <> 'string'
                     OR (e #>> '{}') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') THEN
      RAISE EXCEPTION 'perimetre invalide : dossiers' USING ERRCODE = '22023';
    END IF;
    IF (SELECT pg_catalog.count(*) FROM public.candidatures c
         WHERE c.id::text IN (SELECT pg_catalog.jsonb_array_elements_text(v_p -> 'dossiers')) AND c.genre = p_genre)
       <> (SELECT pg_catalog.count(DISTINCT e) FROM pg_catalog.jsonb_array_elements_text(v_p -> 'dossiers') e) THEN
      RAISE EXCEPTION 'perimetre invalide : dossier inconnu ou de l''autre cote' USING ERRCODE = '22023';
    END IF;
    v_out := v_out || pg_catalog.jsonb_build_object('dossiers', v_p -> 'dossiers');
  END IF;
  RETURN v_out;
END;
$function$;

-- Les capacites d'un porteur de mission, de la forme de public.capacites_candidatures() : ses gestes, rien d'autre.
CREATE FUNCTION private.mission_capacites()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH g AS (
    SELECT coalesce(pg_catalog.array_agg(DISTINCT x), '{}'::text[]) AS a
      FROM private.mission_attributions at
      JOIN private.missions m ON m.id = at.mission_id,
           LATERAL pg_catalog.unnest(m.gestes) AS x
     WHERE at.profile_id = auth.uid() AND at.retiree_le IS NULL
       AND at.debut <= pg_catalog.clock_timestamp()
       AND (at.fin IS NULL OR at.fin > pg_catalog.clock_timestamp())
       AND m.archivee_le IS NULL
  ), k AS (
    SELECT g.a, ('lire' = ANY (g.a)) AS lire, ('voir_contact' = ANY (g.a)) AS contact,
           ('demander_complement' = ANY (g.a)) AS complement,
           ('admettre_verifications' = ANY (g.a)) AS admettre,
           ('confirmer_moyen_paiement' = ANY (g.a)) AS confirmer,
           ('infirmer_moyen_paiement' = ANY (g.a)) AS infirmer,
           ('debloquer_versement' = ANY (g.a)) AS debloquer,
           ('retirer' = ANY (g.a)) AS retrait,
           ('rouvrir' = ANY (g.a)) AS rouvrir,
           ('definir_responsable' = ANY (g.a)) AS responsable,
           ('consigner_prevenu' = ANY (g.a)) AS prevenu,
           ('rattacher' = ANY (g.a)) AS rattacher,
           ('planifier_entretien' = ANY (g.a)) AS planifier,
           ('consigner_entretien_tenu' = ANY (g.a) OR 'consigner_entretien_non_tenu' = ANY (g.a)) AS consigner,
           ('valider_piece' = ANY (g.a)) AS piece
      FROM g
  )
  SELECT pg_catalog.jsonb_build_object(
    'peutLire', k.lire,
    'peutVoirContact', k.lire AND k.contact,
    'peutLireHorsGenre', false,
    'genreLecteurConnu', true,
    'peutDecider', (k.complement OR k.admettre OR k.confirmer OR k.infirmer OR k.debloquer OR k.retrait OR k.rouvrir
                    OR k.responsable OR k.prevenu OR k.rattacher OR k.planifier OR k.consigner OR k.piece),
    'peutImporter', false,
    'doubleVerificationRequise', false,
    'peutMenerEntretien', (k.planifier OR k.consigner),
    'peutPoserFondateur', false,
    'peutChoisirParticipants', k.planifier,
    'fondateursExiges', 'null'::jsonb,
    'peutEcrireReferentiel', false,
    'gestes', pg_catalog.jsonb_build_object(
      'demanderComplement', k.complement, 'cloreComplement', k.complement,
      'admettreVerifications', k.admettre, 'confirmerMoyenPaiement', k.confirmer,
      'infirmerMoyenPaiement', k.infirmer, 'debloquerVersement', k.debloquer,
      'mettreEnPause', false, 'leverPause', false, 'refuser', false,
      'consignerRetrait', k.retrait, 'rouvrir', k.rouvrir, 'definirResponsable', k.responsable,
      'agirEnLot', false, 'inviter', false, 'consignerPrevenu', k.prevenu, 'garderPourSuivi', false,
      'rattacher', k.rattacher, 'planifierEntretien', k.planifier, 'consignerEntretien', k.consigner,
      'dispenserEntretien', false, 'pieceACorriger', false, 'validerPiece', k.piece,
      'restreindre', false, 'leverRestriction', false, 'noterIndisponibilite', false,
      'leverIndisponibilite', false),
    'gestesGroupables', '[]'::jsonb,
    'listes', pg_catalog.jsonb_build_object(
      'modelesRefus', '[]'::jsonb, 'modelesPause', '[]'::jsonb, 'complementSalleExamen', '[]'::jsonb,
      'complementSalleVerification', '[]'::jsonb, 'canauxRetrait', '[]'::jsonb,
      'codesClotureComplement', '[]'::jsonb, 'canauxPrevenu', '[]'::jsonb, 'modelesPrevenu', '[]'::jsonb))
  FROM k;
$function$;

REVOKE ALL ON FUNCTION
  private.mission_gestes_ouverts(), private.mission_est_direction(), private.mission_porteuse(),
  private.mission_droit_dossier(uuid, text), private.mission_droit(uuid, text), private.mission_permis(uuid, text),
  private.mission_acteur(), private.mission_perimetre_valide(jsonb, public.gender), private.mission_capacites()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 3. Les portes publiques, reservees a la direction active en double verification (comme les capacites de controle)
CREATE FUNCTION public.creer_mission(p_nom text, p_gestes text[], p_cle uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_nom text := pg_catalog.btrim(coalesce(p_nom, ''));
  v_gestes text[];
  v_ex private.missions%ROWTYPE;
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR pg_catalog.length(v_nom) NOT BETWEEN 1 AND 80 OR p_gestes IS NULL THEN
    RAISE EXCEPTION 'parametres de mission invalides' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(x ORDER BY x), '{}'::text[]) INTO v_gestes
    FROM (SELECT DISTINCT pg_catalog.unnest(p_gestes) AS x) d;
  IF pg_catalog.cardinality(v_gestes) = 0
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_gestes) g
                 WHERE g IS NULL OR g <> ALL (private.mission_gestes_ouverts())
                    OR (g NOT IN ('lire', 'voir_contact') AND NOT EXISTS (
                          SELECT 1 FROM private.candidature_gestes_regles r
                           WHERE r.geste = g AND 'direction' = ANY (r.auteurs)))) THEN
    RAISE EXCEPTION 'geste de mission inconnu ou sans porte ouverte aux missions' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('mission-creer:' || p_cle::text, 0));
  SELECT m.* INTO v_ex FROM private.missions m WHERE m.cree_par = auth.uid() AND m.cle_creation = p_cle;
  IF FOUND THEN
    IF v_ex.nom = v_nom AND v_ex.gestes = v_gestes THEN
      RETURN v_ex.id;
    END IF;
    RAISE EXCEPTION 'cle de mission deja utilisee' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.missions (nom, gestes, cree_par, cle_creation)
  VALUES (v_nom, v_gestes, auth.uid(), p_cle) RETURNING id INTO v_id;
  INSERT INTO private.mission_journal (mission_id, evenement, acteur_id, payload)
  VALUES (v_id, 'mission_creee', auth.uid(), pg_catalog.jsonb_build_object('nom', v_nom, 'gestes', v_gestes));
  PERFORM public.log_sensitive_access('mission_creee', 'private.missions', v_id::text,
    pg_catalog.jsonb_build_object('nom', v_nom, 'gestes', v_gestes));
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.archiver_mission(p_id uuid, p_motif text, p_cle uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_row private.missions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_cle IS NULL OR pg_catalog.length(v_motif) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'parametres d''archivage invalides' USING ERRCODE = '22023';
  END IF;
  SELECT m.* INTO v_row FROM private.missions m WHERE m.id = p_id FOR UPDATE;
  IF NOT FOUND OR v_row.archivee_le IS NOT NULL THEN
    RETURN false;
  END IF;
  UPDATE private.missions
     SET archivee_le = pg_catalog.clock_timestamp(), archivee_par = auth.uid(), motif_archive = v_motif,
         cle_archive = p_cle
   WHERE id = p_id;
  INSERT INTO private.mission_journal (mission_id, evenement, acteur_id, payload)
  VALUES (p_id, 'mission_archivee', auth.uid(), pg_catalog.jsonb_build_object('motif', v_motif));
  PERFORM public.log_sensitive_access('mission_archivee', 'private.missions', p_id::text,
    pg_catalog.jsonb_build_object('motif', v_motif));
  RETURN true;
END;
$function$;

CREATE FUNCTION public.accorder_mission(p_profile_id uuid, p_mission_id uuid, p_perimetre jsonb,
                                        p_debut timestamptz, p_fin timestamptz, p_cle uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
  v_debut timestamptz := coalesce(p_debut, pg_catalog.clock_timestamp());
  v_perimetre jsonb;
  v_ex private.mission_attributions%ROWTYPE;
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR p_mission_id IS NULL OR p_cle IS NULL
     OR (p_fin IS NOT NULL AND (p_fin <= v_debut OR p_fin <= pg_catalog.clock_timestamp())) THEN
    RAISE EXCEPTION 'parametres de mission invalides' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.missions m WHERE m.id = p_mission_id AND m.archivee_le IS NULL) THEN
    RAISE EXCEPTION 'mission inconnue ou archivee' USING ERRCODE = '22023';
  END IF;
  SELECT p.gender INTO v_genre FROM public.profiles p
   WHERE p.id = p_profile_id AND p.deleted_at IS NULL AND p.account_status = 'active'::public.account_status
     AND p.role IN ('teacher'::public.app_role, 'controller'::public.app_role, 'accountant'::public.app_role);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'compte de personnel indisponible' USING ERRCODE = '22023';
  END IF;
  IF v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du compte inconnu : une mission se porte du cote de la personne' USING ERRCODE = '22023';
  END IF;
  v_perimetre := private.mission_perimetre_valide(p_perimetre, v_genre);

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('mission-accorder:' || p_cle::text, 0));
  SELECT a.* INTO v_ex FROM private.mission_attributions a WHERE a.accorde_par = auth.uid() AND a.cle_accord = p_cle;
  IF FOUND THEN
    IF v_ex.profile_id = p_profile_id AND v_ex.mission_id = p_mission_id AND v_ex.perimetre = v_perimetre
       AND (p_debut IS NULL OR v_ex.debut = p_debut) AND v_ex.fin IS NOT DISTINCT FROM p_fin THEN
      RETURN v_ex.id;
    END IF;
    RAISE EXCEPTION 'cle d''accord deja utilisee' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM private.mission_attributions a
              WHERE a.mission_id = p_mission_id AND a.profile_id = p_profile_id AND a.retiree_le IS NULL) THEN
    RAISE EXCEPTION 'attribution active deja presente : la retirer d''abord' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.mission_attributions (mission_id, profile_id, accorde_par, debut, fin, perimetre, cle_accord)
  VALUES (p_mission_id, p_profile_id, auth.uid(), v_debut, p_fin, v_perimetre, p_cle) RETURNING id INTO v_id;
  INSERT INTO private.mission_journal (mission_id, attribution_id, evenement, acteur_id, payload)
  VALUES (p_mission_id, v_id, 'accord', auth.uid(),
          pg_catalog.jsonb_build_object('profil', p_profile_id, 'perimetre', v_perimetre, 'debut', v_debut,
                                        'fin', p_fin));
  PERFORM public.log_sensitive_access('mission_accordee', 'private.mission_attributions', v_id::text,
    pg_catalog.jsonb_build_object('profil', p_profile_id, 'mission', p_mission_id, 'perimetre', v_perimetre,
                                  'debut', v_debut, 'fin', p_fin));
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.retirer_mission(p_attribution_id uuid, p_motif text, p_cle uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_row private.mission_attributions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_attribution_id IS NULL OR p_cle IS NULL OR pg_catalog.length(v_motif) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'parametres de retrait invalides' USING ERRCODE = '22023';
  END IF;
  SELECT a.* INTO v_row FROM private.mission_attributions a WHERE a.id = p_attribution_id FOR UPDATE;
  IF NOT FOUND OR v_row.retiree_le IS NOT NULL THEN
    RETURN false;
  END IF;
  UPDATE private.mission_attributions
     SET retiree_le = pg_catalog.clock_timestamp(), retiree_par = auth.uid(), motif_retrait = v_motif,
         cle_retrait = p_cle
   WHERE id = p_attribution_id;
  INSERT INTO private.mission_journal (mission_id, attribution_id, evenement, acteur_id, payload)
  VALUES (v_row.mission_id, p_attribution_id, 'retrait', auth.uid(),
          pg_catalog.jsonb_build_object('profil', v_row.profile_id, 'motif', v_motif));
  PERFORM public.log_sensitive_access('mission_retiree', 'private.mission_attributions', p_attribution_id::text,
    pg_catalog.jsonb_build_object('profil', v_row.profile_id, 'motif', v_motif));
  RETURN true;
END;
$function$;

CREATE FUNCTION public.lister_missions()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', m.id, 'nom', m.nom, 'gestes', pg_catalog.to_jsonb(m.gestes), 'creeLe', m.cree_le,
             'archiveeLe', m.archivee_le,
             'porteurs', (SELECT pg_catalog.count(*) FROM private.mission_attributions a
                           WHERE a.mission_id = m.id AND a.retiree_le IS NULL
                             AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp()))) ORDER BY m.cree_le, m.id)
      FROM private.missions m), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.lister_attributions(p_filtre jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_profil uuid;
  v_actives boolean;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object'
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(v_filtre) k WHERE k NOT IN ('profil', 'actives')) THEN
    RAISE EXCEPTION 'filtre invalide : profil et actives seulement' USING ERRCODE = '22023';
  END IF;
  v_profil := (v_filtre ->> 'profil')::uuid;
  v_actives := (v_filtre ->> 'actives')::boolean;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', a.id, 'missionId', a.mission_id, 'mission', m.nom, 'profil', a.profile_id,
             'perimetre', a.perimetre, 'debut', a.debut, 'fin', a.fin, 'retireeLe', a.retiree_le,
             'motifRetrait', a.motif_retrait,
             'active', a.retiree_le IS NULL AND a.debut <= pg_catalog.clock_timestamp()
                       AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp()) AND m.archivee_le IS NULL)
           ORDER BY a.cree_le DESC, a.id)
      FROM private.mission_attributions a JOIN private.missions m ON m.id = a.mission_id
     WHERE (v_profil IS NULL OR a.profile_id = v_profil)
       AND (v_actives IS NULL OR v_actives = (a.retiree_le IS NULL AND a.debut <= pg_catalog.clock_timestamp()
                       AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp()) AND m.archivee_le IS NULL))),
    '[]'::jsonb);
END;
$function$;

REVOKE ALL ON FUNCTION
  public.creer_mission(text, text[], uuid), public.archiver_mission(uuid, text, uuid),
  public.accorder_mission(uuid, uuid, jsonb, timestamptz, timestamptz, uuid),
  public.retirer_mission(uuid, text, uuid), public.lister_missions(), public.lister_attributions(jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.creer_mission(text, text[], uuid), public.archiver_mission(uuid, text, uuid),
  public.accorder_mission(uuid, uuid, jsonb, timestamptz, timestamptz, uuid),
  public.retirer_mission(uuid, text, uuid), public.lister_missions(), public.lister_attributions(jsonb)
  TO authenticated;

-- 4. Le branchement, par ancrage (jamais une copie entiere)

-- 4.1 Le moteur de gestes : l'acteur, le droit de mission, le journal.
DO $retouche$
DECLARE
  v_f regprocedure := 'private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
BEGIN
  IF pg_catalog.strpos(v_def, 'private.mission_acteur()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, 'FROM private.cand_lecteur() l;', 'FROM private.mission_acteur() l;', 1,
      'geste.acteur');
    v_def := pg_temp.remplacer(v_def,
      '  v_idem := private.candidature_idempotence_lue(p_cle, v_c.id, p_geste, p_auteur);',
      '  -- BE-2a : hors de la direction, le geste ne vaut que dans une mission active, pour ce dossier.
  IF p_categorie = ''direction'' AND NOT private.mission_est_direction()
     AND NOT private.mission_droit_dossier(v_c.id, p_geste) THEN
    INSERT INTO private.mission_journal (evenement, acteur_id, payload)
    VALUES (''geste_refuse'', p_auteur,
            pg_catalog.jsonb_build_object(''candidature'', v_c.id, ''geste'', p_geste));
    RETURN pg_catalog.jsonb_build_object(''erreur'', ''hors_mission'', ''geste'', p_geste);
  END IF;
  v_idem := private.candidature_idempotence_lue(p_cle, v_c.id, p_geste, p_auteur);', 1, 'geste.droit');
    v_def := pg_temp.remplacer(v_def,
      '  RETURN pg_catalog.jsonb_build_object(''ok'', true, ''transition'', v_r.transition, ''variante'', v_r.variante);',
      '  IF p_categorie = ''direction'' AND NOT private.mission_est_direction() THEN
    INSERT INTO private.mission_journal (mission_id, attribution_id, evenement, acteur_id, payload)
    SELECT a.mission_id, a.id, ''geste_ouvert'', p_auteur,
           pg_catalog.jsonb_build_object(''candidature'', v_c.id, ''geste'', p_geste)
      FROM private.mission_attributions a JOIN private.missions m ON m.id = a.mission_id
     WHERE a.profile_id = p_auteur AND a.retiree_le IS NULL AND p_geste = ANY (m.gestes)
       AND a.debut <= pg_catalog.clock_timestamp() AND (a.fin IS NULL OR a.fin > pg_catalog.clock_timestamp())
       AND m.archivee_le IS NULL
     ORDER BY a.cree_le, a.id LIMIT 1;
  END IF;
  RETURN pg_catalog.jsonb_build_object(''ok'', true, ''transition'', v_r.transition, ''variante'', v_r.variante);',
      1, 'geste.journal');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
END;
$retouche$;

-- 4.2 La garde de 13 portes de gestes : (administrateur OU porteur de mission) ET compte valide.
DO $retouche$
DECLARE
  v_sig text;
  v_f regprocedure;
  v_def text;
  v_avant text := 'public.app_role() = ''admin'' AND public.app_account_valid()';
  v_apres text := '(public.app_role() = ''admin'' OR private.mission_porteuse()) AND public.app_account_valid()';
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.admettre_salle_verification(uuid,integer,text)',
    'public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)',
    'public.consigner_entretien(uuid,text,text,integer,text)',
    'public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)',
    'public.consigner_retrait_candidat(uuid,text,date,text,integer,text)',
    'public.debloquer_versement_candidat(uuid,integer,text,text)',
    'public.definir_responsable_candidat(uuid,uuid,integer,text)',
    'public.demander_complement_candidat(uuid,text[],text,integer,text)',
    'public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)',
    'public.planifier_entretien(uuid,timestamp with time zone,integer,uuid[],integer,text)',
    'public.rattacher_formulaire_candidat(uuid,uuid,integer,text)',
    'public.rouvrir_candidat(uuid,text,integer,text)',
    'public.valider_piece_candidat(uuid,integer,text)'] LOOP
    v_f := v_sig::regprocedure;
    v_def := pg_catalog.pg_get_functiondef(v_f);
    IF pg_catalog.strpos(v_def, 'private.mission_porteuse()') = 0 THEN
      v_def := pg_temp.remplacer(v_def, v_avant, v_apres, 1, 'porte.garde ' || v_sig);
      EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
    END IF;
  END LOOP;
END;
$retouche$;

-- 4.3 Les lectures : la garde, l'acteur, le perimetre.
DO $retouche$
DECLARE
  v_f regprocedure;
  v_def text;
  v_avant text := 'public.app_role() = ''admin'' AND public.app_account_valid()';
  v_apres text := '(public.app_role() = ''admin'' OR private.mission_porteuse()) AND public.app_account_valid()';
  v_portee text := '(v_super OR c.genre = v_genre)';
  v_portee_apres text := '(v_super OR c.genre = v_genre) AND ((SELECT private.mission_est_direction())
                                                              OR private.mission_droit_dossier(c.id, ''lire''))';
  v_courriel text := 'OR EXISTS (SELECT 1 FROM public.candidature_contacts k';
  v_courriel_apres text := 'OR (((SELECT private.mission_est_direction()) OR private.mission_droit_dossier(c.id, ''voir_contact''))
                AND EXISTS (SELECT 1 FROM public.candidature_contacts k';
BEGIN
  -- lire_candidature
  v_f := 'public.lire_candidature(uuid)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'private.mission_porteuse()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, v_avant, v_apres, 1, 'lire.garde');
    v_def := pg_temp.remplacer(v_def, 'FROM private.cand_lecteur() l;', 'FROM private.mission_acteur() l;', 1, 'lire.acteur');
    v_def := pg_temp.remplacer(v_def, 'IF NOT (v_super OR v_c.genre = v_genre) THEN',
      'IF NOT (v_super OR v_c.genre = v_genre) OR NOT private.mission_permis(v_c.id, ''lire'') THEN', 1, 'lire.portee');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
  -- lister_candidatures : la garde, l'acteur, trois portees, la recherche par courriel
  v_f := 'public.lister_candidatures(jsonb,text,integer)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'private.mission_porteuse()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, v_avant, v_apres, 1, 'liste.garde');
    v_def := pg_temp.remplacer(v_def, 'FROM private.cand_lecteur() l;', 'FROM private.mission_acteur() l;', 1, 'liste.acteur');
    v_def := pg_temp.remplacer(v_def, v_portee, v_portee_apres, 3, 'liste.portee');
    v_def := pg_temp.remplacer(v_def, v_courriel, v_courriel_apres, 1, 'liste.courriel');
    v_def := pg_temp.remplacer(v_def, 'AND k.courriel = pg_catalog.lower(v_recherche))',
                                      'AND k.courriel = pg_catalog.lower(v_recherche)))', 1, 'liste.courriel.fin');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
  -- voisins_candidature
  v_f := 'public.voisins_candidature(text,jsonb,text)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'private.mission_porteuse()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, v_avant, v_apres, 1, 'voisins.garde');
    v_def := pg_temp.remplacer(v_def, 'FROM private.cand_lecteur() l;', 'FROM private.mission_acteur() l;', 1, 'voisins.acteur');
    v_def := pg_temp.remplacer(v_def, v_portee, v_portee_apres, 1, 'voisins.portee');
    v_def := pg_temp.remplacer(v_def, 'IF NOT (v_super OR v_cible.genre = v_genre) THEN',
      'IF NOT (v_super OR v_cible.genre = v_genre) OR NOT private.mission_permis(v_cible.id, ''lire'') THEN', 1,
      'voisins.cible');
    v_def := pg_temp.remplacer(v_def, v_courriel, v_courriel_apres, 1, 'voisins.courriel');
    v_def := pg_temp.remplacer(v_def, 'AND k.courriel = pg_catalog.lower(v_recherche))',
                                      'AND k.courriel = pg_catalog.lower(v_recherche)))', 1, 'voisins.courriel.fin');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
  -- lire_contact_candidature : le contact se juge par dossier (voir_contact), en plus du dossier lisible.
  v_f := 'public.lire_contact_candidature(uuid)'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'private.mission_porteuse()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, v_avant, v_apres, 1, 'contact.garde');
    v_def := pg_temp.remplacer(v_def, 'FROM private.cand_lecteur() l;', 'FROM private.mission_acteur() l;', 1, 'contact.acteur');
    v_def := pg_temp.remplacer(v_def, 'IF NOT coalesce(v_nomme, false) THEN',
      'IF NOT (coalesce(v_nomme, false)
          OR (NOT private.mission_est_direction() AND private.mission_droit_dossier(p_id, ''voir_contact''))) THEN', 1,
      'contact.nomme');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
  -- capacites_candidatures : un porteur de mission recoit ses gestes, rien d'autre.
  v_f := 'public.capacites_candidatures()'::regprocedure;
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, 'private.mission_capacites()') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '  RETURN pg_catalog.jsonb_build_object(
    ''peutLire'', v_lire,',
      '  IF NOT v_admin AND private.mission_porteuse() THEN
    RETURN private.mission_capacites();
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    ''peutLire'', v_lire,', 1, 'capacites.mission');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
END;
$retouche$;

-- 4.4 La liste des gestes calcules (lister_enseignants la lit) : seuls les gestes de la mission d'un porteur.
DO $retouche$
DECLARE
  v_f regprocedure := 'private.lp_gestes(public.candidatures,boolean)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
BEGIN
  IF pg_catalog.strpos(v_def, 'mission_droit_dossier') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '       AND ''direction'' = ANY (r.auteurs)',
      '       AND ''direction'' = ANY (r.auteurs)
       AND ((SELECT private.mission_est_direction()) OR private.mission_droit_dossier(c.id, r.geste))', 1, 'lp.gestes');
    EXECUTE v_def;
  PERFORM pg_temp.empreinte(v_f);
  END IF;
END;
$retouche$;

DO $postflight$
DECLARE
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.admettre_salle_verification(uuid,integer,text)', 'public.valider_piece_candidat(uuid,integer,text)',
    'public.lire_candidature(uuid)', 'public.lister_candidatures(jsonb,text,integer)',
    'public.voisins_candidature(text,jsonb,text)', 'public.lire_contact_candidature(uuid)'] LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_sig::regprocedure), 'private.mission_porteuse()') = 0 THEN
      RAISE EXCEPTION 'BE-2a : garde non retouchee : %', v_sig;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.mission_droit(uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.mission_acteur()', 'EXECUTE')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.missions'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.mission_attributions'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.mission_journal'::regclass) THEN
    RAISE EXCEPTION 'BE-2a : droits ou RLS incorrects';
  END IF;
END
$postflight$;
