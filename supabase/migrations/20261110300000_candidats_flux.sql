-- CANDIDATS-FLUX (PLAN-LOTS §7 rang 22 k, 06/11/2026). Fichier SANS mot
-- d'effacement : le pilote l'installe (B5). Additif (B6) : l'ancien code de
-- production continue de marcher avec lui.
--
-- Ce fichier :
--   1. reglage de la direction `courriels.non_essentiels_par_jour` (300 par
--      defaut, de 1 a 2000), valide par un declencheur ; modifiable par la
--      direction comme les autres reglages de `app_config` (RLS
--      app_config_admin_update, journal app_config_history).
--   2. `courriels_reserver` (ancres) : la file etale d'elle-meme les envois
--      NON essentiels sur les jours suivants. Sur 24 heures glissantes, au plus
--      `courriels.non_essentiels_par_jour` envois non essentiels sont reserves ;
--      au-dela ils restent « en_attente » et partent les jours suivants. Les
--      messages ESSENTIELS sont reserves d'abord, sans aucun plafond : ils ne
--      sont jamais retardes par le plafond. Sont essentiels pour la file : une
--      categorie essentielle, et deux messages individuels de la categorie
--      `recrutement` (private.courriel_hors_plafond, voir plus bas).
--   3. `prevenir_par_courriel` (ancres) : une invitation par adresse, jamais
--      deux (cle `lien_inscription:<adresse>`, au lieu de
--      `candidat_prevenu:<id de la reponse>`) ; les desinscrits du recrutement
--      sont exclus et ne restent pas comptes « a prevenir » ; le message porte
--      la langue du candidat (celle du message d'attente du 25/10 a cette
--      adresse, sinon l'arabe si le nom ou le formulaire est ecrit en arabe,
--      sinon le francais par le declencheur courriel_langue) ; limite par appel
--      portee de 500 a 2000, puisque la file etale l'envoi.
--   4. `apercu_prevenir_par_courriel` (ancres) : compte les desinscrits a part.
--   5. `etat_file_courriels()` : ce que la direction lit sous « Prevenir » (le
--      reglage, les envois non essentiels des 24 dernieres heures, ceux qui
--      attendent, et le nombre de jours qu'il faudra).
--   6. Langues des cours (PLAN-LOTS §7 rang 22 m, arbitrage du garde-cap du
--      06/11 vers 10:50 UTC sur la consigne du directeur du 06/11, qui remplace
--      celle du 22/10 « l'arabe n'est pas une langue de cours ») : ajout seul
--      dans `langues_cours` de `man` « Malinke (mandinka) », `ar` « Arabe » et
--      `pt` « Portugais » (la production n'a que poular, francais, english,
--      lu le 06/11) ; a l'import, `mnk` (« الماندينكا ») est ramene a `man`
--      (table de libelles, mise a jour d'une valeur) et l'arabe de la colonne
--      F reste une langue d'explication (`formulaires_lire`, ancre).
--
-- Ecart releve en production le 06/11 (lecture seule) : la categorie de
-- courriel `recrutement` y est NON essentielle (essentielle = false, modifiee
-- le 25/10/2026 a 10:34 UTC hors migration : lettre personnelle avec
-- desinscription en un clic) ; le depot la seme essentielle
-- (20261023120000_courriels_sortants.sql). Ce fichier ne change pas la
-- categorie. Il exempte nommement du plafond les deux messages individuels de
-- cette categorie (compte_enseignant_valide, invitation_enseignant), pour
-- qu'ils ne soient jamais retardes ; le scenario le prouve dans l'etat de la
-- production (b3).
--
-- Lecteurs de `langues_cours` (B1, recensement du 06/11) : aucune colonne
-- changee ; trois lignes ajoutees, que liront les offres horaires, les
-- demandes des familles, les profils eleves et enseignants et le
-- questionnaire des candidats (private.questionnaire_langues : une langue du
-- referentiel n'est plus proposee comme hors referentiel).
--
-- B1 (colonnes) : aucune colonne rendue facultative ni changee de sens.
-- Lecteurs de la cle d'idempotence `candidat_prevenu:` : aucun (recherche sur
-- supabase/, lib/, test/ du 06/11 ; seul le fichier 20261024010000 l'ecrit).
--
-- Preflight du 06/11/2026 (lecture seule de la production) : md5(prosrc) de
-- courriels_reserver = ba451e9361dff09bfd791230419bed23, courriel_enfiler =
-- 8d930d3760830b79bbc1617542b669b5 (non modifiee ici), prevenir_par_courriel =
-- 20266d31abf25e26f4538372de68302b, apercu_prevenir_par_courriel =
-- b33ae59f46bced56b932a9e6b76b9c7e : identiques au depot rejoue (main 8a5a5a08
-- plus 20261024000000 et 20261024010000, deja installes en production sous ces
-- versions). Le bloc preflight ci-dessous refuse toute autre definition.
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

-- ---------------------------------------------------------------------------
-- 0. Preflight : les definitions remplacees sont celles relevees.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT e.signature, e.attendu, pg_catalog.md5(p.prosrc) AS lu
      FROM (VALUES
        ('public.courriels_reserver(integer)', 'ba451e9361dff09bfd791230419bed23'),
        ('public.prevenir_par_courriel(integer)', '20266d31abf25e26f4538372de68302b'),
        ('public.apercu_prevenir_par_courriel()', 'b33ae59f46bced56b932a9e6b76b9c7e'),
        ('private.formulaires_lire(text,text,text,jsonb,text)', '693acdcd8f28214654377d822f8ca1ca')
      ) AS e(signature, attendu)
      LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.lu IS DISTINCT FROM v.attendu THEN
      RAISE EXCEPTION 'CANDIDATS-FLUX : % differe de la definition relevee (md5 % au lieu de %), migration a revoir',
        v.signature, v.lu, v.attendu;
    END IF;
  END LOOP;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le reglage, et sa validation.
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('courriels.non_essentiels_par_jour', '300'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.courriels_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.key = 'courriels.non_essentiels_par_jour' THEN
    -- Un entier de 1 a 2000 : la limite d'envoi de Google Workspace est
    -- d'environ 2000 messages par jour, tous messages confondus.
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
       OR (NEW.value #>> '{}') !~ '^[1-9][0-9]{0,3}$'
       OR (NEW.value #>> '{}')::integer > 2000 THEN
      RAISE EXCEPTION 'reglage des courriels : un entier de 1 a 2000 est attendu' USING ERRCODE = '22023';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.courriels_reglages_valider() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER app_config_courriels
  BEFORE INSERT OR UPDATE OF value ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.courriels_reglages_valider();

-- Le compte des 24 dernieres heures lit la date de reservation.
CREATE INDEX IF NOT EXISTS courriels_sortants_reserve_le
  ON public.courriels_sortants (reserve_le)
  WHERE reserve_le IS NOT NULL;

-- Qui passe hors plafond. Une categorie essentielle, toujours. En production,
-- la categorie `recrutement` est NON essentielle depuis le 25/10/2026 (lettre
-- personnelle avec desinscription en un clic ; reglage pose hors migration,
-- releve le 06/11) ; or elle porte aussi deux messages individuels, adresses a
-- une seule personne a la suite d'un geste qui la concerne : « votre compte
-- enseignant est valide » (D2) et l'invitation d'un enseignant (I1). Ceux-la
-- ne sont jamais retardes par le plafond. Le plafond ne retient donc que les
-- envois en nombre : message d'attente, invitation des formulaires, nouvelles.
CREATE FUNCTION private.courriel_hors_plafond(p_essentielle boolean, p_modele text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT coalesce(p_essentielle, false)
      OR p_modele IN ('compte_enseignant_valide', 'invitation_enseignant');
$function$;
REVOKE ALL ON FUNCTION private.courriel_hors_plafond(boolean, text) FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.courriel_hors_plafond(boolean, text) IS
  'CANDIDATS-FLUX (06/11/2026) : vrai pour un message que le plafond courriels.non_essentiels_par_jour ne retarde jamais (categorie essentielle, ou message individuel compte_enseignant_valide / invitation_enseignant).';

-- ---------------------------------------------------------------------------
-- 2. La file : essentiels d'abord, non essentiels sous plafond (ancres).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

SELECT pg_temp.remplacer('public.courriels_reserver(integer)',
  $a$DECLARE
  v_ids uuid[];
BEGIN$a$,
  $b$DECLARE
  v_ids uuid[];
  -- CANDIDATS-FLUX (06/11/2026) : plafond des envois non essentiels.
  v_lot integer := LEAST(GREATEST(coalesce(p_lot, 20), 1), 100);
  v_par_jour integer;
  v_partis integer;
  v_place integer;
BEGIN$b$, 1);

SELECT pg_temp.remplacer('public.courriels_reserver(integer)',
  $a$  WITH choisis AS (
    SELECT s.id FROM public.courriels_sortants s
     WHERE (s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
        OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes')
     ORDER BY s.prochaine_tentative
     LIMIT LEAST(GREATEST(coalesce(p_lot, 20), 1), 100)
     FOR UPDATE SKIP LOCKED
  ), pris AS (
    UPDATE public.courriels_sortants s
       SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
      FROM choisis WHERE s.id = choisis.id
    RETURNING s.id
  )
  SELECT pg_catalog.array_agg(pris.id) INTO v_ids FROM pris;
$a$,
  $b$  -- CANDIDATS-FLUX (06/11/2026) : les messages essentiels d'abord, sans
  -- plafond ; ils ne sont jamais retardes par les envois non essentiels.
  WITH choisis AS (
    SELECT s.id FROM public.courriels_sortants s
     WHERE ((s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
        OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes'))
       AND EXISTS (SELECT 1 FROM public.courriel_categories c
                    WHERE c.code = s.categorie AND private.courriel_hors_plafond(c.essentielle, s.modele))
     ORDER BY s.prochaine_tentative
     LIMIT v_lot
     FOR UPDATE SKIP LOCKED
  ), pris AS (
    UPDATE public.courriels_sortants s
       SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
      FROM choisis WHERE s.id = choisis.id
    RETURNING s.id
  )
  SELECT pg_catalog.array_agg(pris.id) INTO v_ids FROM pris;

  -- Puis les non essentiels, au plus `courriels.non_essentiels_par_jour` sur
  -- 24 heures glissantes : le reste attend, en file, les jours suivants. Un
  -- seul travailleur compte a la fois (deux appels simultanes ne depassent pas
  -- le plafond a deux). Une ligne reprise apres une panne garde sa date de
  -- reservation la plus recente : elle compte une fois.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('courriels_non_essentiels_par_jour'));
  v_par_jour := GREATEST(coalesce(public.app_config_int('courriels.non_essentiels_par_jour', 300), 300), 0);
  SELECT pg_catalog.count(*)::integer INTO v_partis
    FROM public.courriels_sortants s
    JOIN public.courriel_categories c ON c.code = s.categorie
   WHERE NOT private.courriel_hors_plafond(c.essentielle, s.modele)
     AND s.reserve_le > pg_catalog.now() - interval '24 hours';
  v_place := LEAST(v_lot - coalesce(pg_catalog.cardinality(v_ids), 0), v_par_jour - v_partis);
  IF v_place > 0 THEN
    WITH choisis AS (
      SELECT s.id FROM public.courriels_sortants s
       WHERE ((s.statut = 'en_attente' AND s.prochaine_tentative <= pg_catalog.now())
          OR (s.statut = 'envoi' AND s.reserve_le < pg_catalog.now() - interval '10 minutes'))
         AND NOT EXISTS (SELECT 1 FROM public.courriel_categories c
                          WHERE c.code = s.categorie AND private.courriel_hors_plafond(c.essentielle, s.modele))
       ORDER BY s.prochaine_tentative, s.cree_le, s.id
       LIMIT v_place
       FOR UPDATE SKIP LOCKED
    ), pris AS (
      UPDATE public.courriels_sortants s
         SET statut = 'envoi', reserve_le = pg_catalog.now(), tentatives = s.tentatives + 1
        FROM choisis WHERE s.id = choisis.id
      RETURNING s.id
    )
    SELECT coalesce(v_ids, '{}'::uuid[]) || coalesce(pg_catalog.array_agg(pris.id), '{}'::uuid[])
      INTO v_ids FROM pris;
  END IF;
$b$, 1);

-- ---------------------------------------------------------------------------
-- 3. Prevenir : une invitation par adresse, desinscrits exclus, langue.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.prevenir_par_courriel(integer)',
  $a$  IF p_limite IS NULL OR p_limite < 1 OR p_limite > 500 THEN
    RAISE EXCEPTION 'limite invalide : de 1 a 500' USING ERRCODE = '22023';$a$,
  $b$  -- CANDIDATS-FLUX (06/11/2026) : la file etale l'envoi, la limite par appel
  -- peut couvrir toutes les personnes a prevenir.
  IF p_limite IS NULL OR p_limite < 1 OR p_limite > 2000 THEN
    RAISE EXCEPTION 'limite invalide : de 1 a 2000' USING ERRCODE = '22023';$b$, 1);

SELECT pg_temp.remplacer('public.prevenir_par_courriel(integer)',
  $a$    SELECT DISTINCT ON (r.courriel) r.id, r.courriel, r.recue_le, l.classeur
$a$,
  $b$    SELECT DISTINCT ON (r.courriel) r.id, r.courriel, r.recue_le, l.classeur, r.nom_affiche
$b$, 1);

-- Le passage « deja en file » de la boucle : la cle par adresse compte aussi
-- (une invitation annulee ne repart pas) ; les desinscrits sont exclus.
SELECT pg_temp.remplacer('public.prevenir_par_courriel(integer)',
  $a$       AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                          AND s.statut <> 'annule')
     ORDER BY r.courriel, r.recue_le ASC, r.id ASC$a$,
  $b$       AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                          AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || r.courriel))
       AND NOT EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                        WHERE d.adresse = r.courriel AND d.categorie = 'recrutement')
     ORDER BY r.courriel, r.recue_le ASC, r.id ASC$b$, 1);

SELECT pg_temp.remplacer('public.prevenir_par_courriel(integer)',
  $a$     AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                      WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                        AND s.statut <> 'annule');$a$,
  $b$     AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                      WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = r.courriel
                        AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || r.courriel))
     AND NOT EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                      WHERE d.adresse = r.courriel AND d.categorie = 'recrutement');$b$, 1);

SELECT pg_temp.remplacer('public.prevenir_par_courriel(integer)',
  $a$      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'date_reponse', v_r.recue_le,
        'formulaire', v_formulaire)),
      'candidat_prevenu:' || v_r.id::text,$a$,
  $b$      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'date_reponse', v_r.recue_le,
        'formulaire', v_formulaire,
        -- La langue du candidat : celle du message d'attente deja recu a cette
        -- adresse, sinon l'arabe si son nom ou le formulaire est ecrit en
        -- arabe ; absente, le declencheur courriel_langue met le francais.
        'langue', coalesce(
          (SELECT s.langue FROM public.courriels_sortants s
            WHERE s.destinataire_adresse = v_r.courriel AND s.modele = 'attente_candidat'
              AND s.langue IS NOT NULL
            ORDER BY s.cree_le DESC LIMIT 1),
          CASE WHEN coalesce(v_r.nom_affiche, '') || ' ' || coalesce(v_r.classeur, '')
                    ~ '[؀-ۿ]' THEN 'ar' END))),
      -- Une invitation par adresse, jamais deux (S3).
      'lien_inscription:' || v_r.courriel,$b$, 1);

-- ---------------------------------------------------------------------------
-- 4. L'apercu : les desinscrits a part.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.apercu_prevenir_par_courriel()',
  $a$           EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = k.courriel) AS inscrit,$a$,
  $b$           EXISTS (SELECT 1 FROM auth.users u WHERE pg_catalog.lower(u.email) = k.courriel) AS inscrit,
           EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                    WHERE d.adresse = k.courriel AND d.categorie = 'recrutement') AS desinscrit,$b$, 1);

SELECT pg_temp.remplacer('public.apercu_prevenir_par_courriel()',
  $a$                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = k.courriel
                          AND s.statut <> 'annule')) AS prevenu$a$,
  $b$                        WHERE s.modele = 'lien_inscription' AND s.destinataire_adresse = k.courriel
                          AND (s.statut <> 'annule' OR s.cle_idempotence = 'lien_inscription:' || k.courriel))) AS prevenu$b$, 1);

SELECT pg_temp.remplacer('public.apercu_prevenir_par_courriel()',
  $a$           'aPrevenir', pg_catalog.count(DISTINCT c.courriel) FILTER (WHERE NOT c.inscrit AND NOT c.prevenu),$a$,
  $b$           'aPrevenir', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND NOT c.desinscrit),
           'desinscrits', pg_catalog.count(DISTINCT c.courriel)
                          FILTER (WHERE NOT c.inscrit AND NOT c.prevenu AND c.desinscrit),$b$, 1);

-- ---------------------------------------------------------------------------
-- 5. L'etat de la file, lu par la direction sous « Prevenir ».
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.etat_file_courriels()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_par_jour integer;
  v_partis integer;
  v_attente integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'etat de la file reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  v_par_jour := GREATEST(coalesce(public.app_config_int('courriels.non_essentiels_par_jour', 300), 300), 1);
  SELECT pg_catalog.count(*)::integer INTO v_partis
    FROM public.courriels_sortants s
    JOIN public.courriel_categories c ON c.code = s.categorie
   WHERE NOT private.courriel_hors_plafond(c.essentielle, s.modele)
     AND s.reserve_le > pg_catalog.now() - interval '24 hours';
  SELECT pg_catalog.count(*)::integer INTO v_attente
    FROM public.courriels_sortants s
    JOIN public.courriel_categories c ON c.code = s.categorie
   WHERE NOT private.courriel_hors_plafond(c.essentielle, s.modele)
     AND s.statut IN ('en_attente', 'envoi');
  -- Des compteurs seulement : aucune adresse.
  RETURN pg_catalog.jsonb_build_object(
    'parJour', v_par_jour,
    'partis24h', v_partis,
    'enAttente', v_attente,
    'joursEstimes', CASE WHEN v_attente = 0 THEN 0
                         ELSE ((v_attente + GREATEST(v_partis - v_par_jour, 0)
                                + v_par_jour - 1) / v_par_jour) END);
END;
$function$;
REVOKE ALL ON FUNCTION public.etat_file_courriels() FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.etat_file_courriels() FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION private.courriels_reglages_valider() FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION private.courriel_hors_plafond(boolean, text) FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.etat_file_courriels() TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. Langues des cours (rang 22 m).
-- ---------------------------------------------------------------------------
INSERT INTO public.langues_cours (code, nom_humain, ordre) VALUES
  ('man', 'Malinké (mandinka)', 4),
  ('ar', 'Arabe', 5),
  ('pt', 'Portugais', 6)
ON CONFLICT (code) DO NOTHING;

-- La reprise que prescrit le commentaire de teacher_profiles.languages apres
-- l'ajout d'une langue au referentiel : une saisie libre (« Arabe », une
-- enseignante en production le 06/11) se range sous son code ; une saisie
-- toujours libre ne change pas (scenario ens_l8, cas 8).
UPDATE public.teacher_profiles SET languages = languages WHERE languages <> '{}';

-- Le malinke et le mandinka : une seule langue, `man`.
UPDATE private.formulaires_libelles SET valeur = 'man'
 WHERE champ = 'langue' AND valeur = 'mnk';
INSERT INTO private.formulaires_libelles (champ, libelle, valeur)
SELECT 'langue', private.formulaires_texte(v.libelle), v.valeur
  FROM (VALUES ('المالينكي', 'man'), ('mnk', 'man'), ('man', 'man'), ('mandinka', 'man'),
               ('malinké', 'man'), ('malinke', 'man')) AS v(libelle, valeur)
ON CONFLICT DO NOTHING;

-- L'arabe de la colonne F reste une langue d'explication.
SELECT pg_temp.remplacer('private.formulaires_lire(text,text,text,jsonb,text)',
  $a$          IF v_o ->> 'valeur' = 'ar' THEN
            v_av := v_av || 'arabe_retire'::text;
          ELSIF NOT ((v_o ->> 'valeur') = ANY (v_langues)) THEN$a$,
  $b$          -- CANDIDATS-FLUX (06/11/2026, rang 22 m) : l'arabe est une langue de
          -- cours, il reste dans la liste ; `mnk` arrive deja ramene a `man`.
          IF NOT ((v_o ->> 'valeur') = ANY (v_langues)) THEN$b$, 1);

-- ---------------------------------------------------------------------------
-- Empreintes F86.
-- ---------------------------------------------------------------------------
DO $empreintes$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  f := 'public.etat_file_courriels()'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=etat_file_courriels(); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-06. '
    || 'CANDIDATS-FLUX : compteurs de la file des courriels non essentiels (reglage, partis sur 24 h, en attente, jours estimes), aucune adresse. Must-pass: supabase/tests/scenarios_candidats_flux.sql.');
  FOREACH f IN ARRAY ARRAY['public.courriels_reserver(integer)'::regprocedure,
                           'public.prevenir_par_courriel(integer)'::regprocedure,
                           'public.apercu_prevenir_par_courriel()'::regprocedure] LOOP
    v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    ELSE
      v_com := v_com || ' md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || ';';
    END IF;
    IF pg_catalog.strpos(v_com, 'CANDIDATS-FLUX') = 0 THEN
      v_com := v_com || ' CANDIDATS-FLUX (06/11/2026) : plafond des non essentiels, invitation par adresse. Must-pass: supabase/tests/scenarios_candidats_flux.sql.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END LOOP;
END;
$empreintes$;

-- ---------------------------------------------------------------------------
-- Postflight.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF (SELECT c.value FROM public.app_config c WHERE c.key = 'courriels.non_essentiels_par_jour') IS NULL THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX : reglage courriels.non_essentiels_par_jour absent';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.courriels_reserver(integer)'::regprocedure),
                       'courriels.non_essentiels_par_jour') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.prevenir_par_courriel(integer)'::regprocedure),
                          '''lien_inscription:'' || v_r.courriel') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.prevenir_par_courriel(integer)'::regprocedure),
                          'candidat_prevenu:') <> 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.apercu_prevenir_par_courriel()'::regprocedure),
                          'desinscrits') = 0 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX : un remplacement manque';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'public.courriels_reserver(integer)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.courriels_reserver(integer)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.etat_file_courriels()'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.etat_file_courriels()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.courriels_reglages_valider()'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.prevenir_par_courriel(integer)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.prevenir_par_courriel(integer)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX : droits d''execution inattendus';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.langues_cours WHERE code IN ('man', 'ar', 'pt')) <> 3
     OR EXISTS (SELECT 1 FROM private.formulaires_libelles WHERE champ = 'langue' AND valeur = 'mnk')
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
          'private.formulaires_lire(text,text,text,jsonb,text)'::regprocedure), 'arabe_retire') <> 0 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX : langues des cours incompletes (man, ar, pt, mnk ramene, arabe garde)';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.etat_file_courriels()'::regprocedure,
                              'public.courriels_reserver(integer)'::regprocedure,
                              'public.prevenir_par_courriel(integer)'::regprocedure,
                              'public.apercu_prevenir_par_courriel()'::regprocedure)
                AND (NOT p.prosecdef
                     OR NOT coalesce(p.proconfig @> ARRAY['search_path=""'], false)
                     OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '')
                        NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%')) THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX : DEFINER, search_path ou empreinte F86 invalide';
  END IF;
END;
$postflight$;
