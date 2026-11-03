-- A3-bis (02/11/2026) : le remplacement sans perte de seance.
--
-- Decision du directeur du 02/11 (« OUI »), relayee par le pilote.
-- Fichier SANS mot d'effacement (B5) : le pilote l'installe. Migration
-- additive (B6) : deux reglages, deux fonctions retouchees par ancre
-- (pg_temp.remplacer, B4), rien de retire.
--
-- ORDRE DE DEPLOIEMENT : le modele d'e-mail « remplacement_personne_en_salle »
-- (supabase/functions/_shared/courriel/modeles_*.ts) doit etre deploye avec la
-- fonction Edge courriels-envoi AVANT cette migration ; sinon la premiere
-- alerte enfilee echoue a l'envoi (« modele inconnu »).
--
-- Ce qui change dans private.remplacement_auto_passer
-- (20261102500000_remplacement_auto.sql, aucune autre migration ne la retouche) :
-- 1. Jamais ecarter le titulaire sans remplacant pret. A T+perte, l'absence
--    automatique (absence_declaree, origine auto) n'est posee que si un
--    enseignant pret est encore candidat, dans la meme transaction que
--    remplacement_pris. Sinon rien n'est pose : le titulaire garde son jeton
--    (remplacement_titulaire_ecarte ne lit que cette absence), la preparation
--    reste ouverte (se_declarer_pret_remplacement l'accepte jusqu'a la fin
--    prevue), et un enseignant qui se declare pret plus tard est pris au
--    passage suivant. Pour cela, la pre-alerte (etape a) vaut desormais
--    jusqu'a la fin prevue de la seance, et non plus seulement jusqu'a
--    T+perte ; l'avertissement du titulaire, lui, ne part qu'avant T+perte.
--    Consequence assumee : prendre_remplacement, qui exige une absence, ne
--    sert plus qu'apres une absence declaree par une personne ; sans elle, le
--    remplacant passe par « se declarer pret ».
-- 2. Alerte a la direction. A T+remplacement.alerte_direction_minutes (3,
--    fiche du directeur), si ni le titulaire ni le remplacant pris n'a rejoint
--    la salle : un e-mail a chaque compte de la direction, par
--    courriel_enfiler, cle 'a3bis-alerte:<seance>:<destinataire>' (une seule
--    fois par seance et par personne). Destinataires : la meme source que
--    l'avis « titulaire_en_retard » d'A3 et que FN-115b, les comptes admin
--    actifs (role admin, non supprimes, compte actif, acces en cours) ; leur
--    adresse par courriel_adresse_profil. Aucune adresse dans le depot.
--    Pas de notification dans l'application (choix du pilote du 02/11) :
--    elle demanderait d'elargir notifications_evenement_check, donc un fichier
--    a mots d'effacement, colle par le directeur.
-- 3. Seance creee tard. Si created_at est a moins de
--    remplacement.seance_tardive_minutes de started_at, l'etape c ne pose ni
--    absence ni prise automatique. L'alerte a la direction part quand meme.
--    Valeur 15 : reglage technique propose par l'agent, NON tranche par le
--    directeur ; modifiable dans Configuration > Regles.
--
-- 4. public.motif_refus_salle (20261104100000) : le titulaire remplace par un
--    collegue (prise posee avec l'absence) lit « acces_perdu », et non plus
--    le refus generique (decision du directeur du 03/11 : « l'autre ne peut
--    plus rentrer mais voit un message clair de ce qui l'empeche »).
--
-- private.reglages_remplacement_valider (20261104200000) accepte les deux
-- nouvelles cles : un entier de 0 a 999, sans contrainte d'ordre.
--
-- Lecteurs (B1) : aucune colonne ne change de sens. Les deux cles nouvelles
-- sont lues par cette fonction et par l'ecran Regles
-- (lib/core/admin/service_configuration.dart, clesRemplacementA3bis).
-- Mots de suppression dans ce fichier : aucun.

BEGIN;

INSERT INTO public.app_config (key, value) VALUES
  ('remplacement.alerte_direction_minutes', '3'::jsonb),
  -- Reglage technique propose par l'agent, non tranche par le directeur.
  ('remplacement.seance_tardive_minutes', '15'::jsonb)
ON CONFLICT (key) DO NOTHING;

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

-- ---------------------------------------------------------------------------
-- 1. La validation des reglages accepte les deux nouvelles cles.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$  IF NEW.key NOT IN ('remplacement.avertissement_minutes',
                     'remplacement.perte_acces_minutes',
                     'remplacement.debut_remplacant_minutes') THEN$a$,
  $b$  IF NEW.key NOT IN ('remplacement.avertissement_minutes',
                     'remplacement.perte_acces_minutes',
                     'remplacement.debut_remplacant_minutes',
                     -- A3-bis (02/11/2026).
                     'remplacement.alerte_direction_minutes',
                     'remplacement.seance_tardive_minutes') THEN$b$, 1);

SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$  NEW.value := pg_catalog.to_jsonb(v_n::integer);
$a$,
  $b$  NEW.value := pg_catalog.to_jsonb(v_n::integer);
  -- A3-bis : ces deux delais n'ont pas d'ordre impose avec les trois autres.
  IF NEW.key IN ('remplacement.alerte_direction_minutes',
                 'remplacement.seance_tardive_minutes') THEN
    RETURN NEW;
  END IF;
$b$, 1);

-- ---------------------------------------------------------------------------
-- 2. Le passage de chaque minute.
-- ---------------------------------------------------------------------------
-- 2a. Les deux reglages et le compteur des alertes.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$  v_erreurs integer := 0;
$a$,
  $b$  v_erreurs integer := 0;
  -- A3-bis (02/11/2026).
  v_alerte integer := private.remplacement_reglage('remplacement.alerte_direction_minutes');
  v_tardive integer := private.remplacement_reglage('remplacement.seance_tardive_minutes');
  v_alertes integer := 0;
  v_dir record;
$b$, 1);

-- 2a bis. Etape a : la pre-alerte vaut jusqu'a la fin prevue, et non plus
--    jusqu'a T+perte. Sans elle, une seance sans pre-alerte a T+perte (passage
--    manque, seance ouverte par un eleve) ne pourrait plus etre remplacee :
--    l'absence n'est plus posee sans remplacant pret, et
--    se_declarer_pret_remplacement exige une pre-alerte.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$       AND s.started_at + pg_catalog.make_interval(mins => v_perte) > p_maintenant
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p WHERE p.session_id = s.id)$a$,
  $b$       AND s.ended_at > p_maintenant
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p WHERE p.session_id = s.id)$b$, 1);

-- 2a ter. L'avertissement du titulaire (« il vous reste N minutes ») n'a de
--    sens qu'avant T+perte ; plus tard, seule la pre-alerte part.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$      INSERT INTO public.notifications (destinataire, evenement, params, destination)
      VALUES (v_s.teacher_id, 'remplacement_avertissement',
              pg_catalog.jsonb_build_object('session_id', v_s.id, 'groupe_id', v_s.groupe_id,
                'minutes', (v_perte - v_avert)::text),
              '/enseignant/journee');
$a$,
  $b$      IF (SELECT x.started_at FROM public.sessions x WHERE x.id = v_s.id)
           + pg_catalog.make_interval(mins => v_perte) > p_maintenant THEN
        INSERT INTO public.notifications (destinataire, evenement, params, destination)
        VALUES (v_s.teacher_id, 'remplacement_avertissement',
                pg_catalog.jsonb_build_object('session_id', v_s.id, 'groupe_id', v_s.groupe_id,
                  'minutes', (v_perte - v_avert)::text),
                '/enseignant/journee');
      END IF;
$b$, 1);

-- 2b. Etape c : une seance creee tard n'est pas retiree automatiquement.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$make_interval(mins => v_perte) <= p_maintenant$a$,
  $b$make_interval(mins => v_perte) <= p_maintenant
       -- A3-bis : seance creee moins de v_tardive minutes avant son debut.
       AND s.created_at < s.started_at - pg_catalog.make_interval(mins => v_tardive)$b$, 1);

-- 2c. Etape c : l'absence n'est posee qu'avec un remplacant pret et candidat.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$      INSERT INTO public.remplacements_seance
        (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence, origine)
      VALUES (v_s.id, 'absence_declaree'$a$,
  $b$      -- A3-bis (02/11/2026) : jamais ecarter le titulaire sans remplacant
      -- pret. Sans enseignant pret et candidat, rien n'est pose : le
      -- titulaire peut encore entrer, la preparation reste ouverte.
      SELECT p.enseignant_id INTO v_pret FROM public.remplacements_preparation p
       WHERE p.session_id = v_s.id AND p.evenement = 'pret';
      IF v_pret IS NULL OR NOT private.remplacement_candidat(v_s.id, v_pret) THEN
        CONTINUE;
      END IF;
      INSERT INTO public.remplacements_seance
        (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence, origine)
      VALUES (v_s.id, 'absence_declaree'$b$, 1);

-- 2d. Etape d : l'alerte a la direction, puis le bilan du passage.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$  RETURN pg_catalog.jsonb_build_object($a$,
  $b$  -- d. A3-bis (02/11/2026) : T + alerte_direction, ni le titulaire ni le
  --    remplacant pris n'a rejoint la salle. Un e-mail a chaque compte de
  --    la direction, une seule fois par seance (cle d'idempotence). Aucun
  --    verrou : rien n'est ecrit dans la seance.
  FOR v_s IN
    SELECT s.id, s.teacher_id, s.started_at, g.libelle, g.timezone_iana,
           pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')) AS enseignant
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      LEFT JOIN public.profiles t ON t.id = s.teacher_id
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
       AND s.teacher_id IS NOT NULL
       AND s.started_at + pg_catalog.make_interval(mins => v_alerte) <= p_maintenant
       AND s.ended_at > p_maintenant
       AND NOT private.remplacement_titulaire_entre(s.id)
       AND NOT EXISTS (
         SELECT 1 FROM public.remplacements_seance r
           JOIN public.session_events e ON e.session_id = r.session_id
                                       AND e.profile_id = r.enseignant_remplacant_id
                                       AND e.event_type = 'joined'
          WHERE r.session_id = s.id AND r.evenement = 'remplacement_pris')
     ORDER BY s.started_at, s.id
  LOOP
    BEGIN
      FOR v_dir IN
        SELECT p.id, h.timezone
          FROM public.profiles p
          LEFT JOIN public.households h ON h.id = p.household_id
         WHERE p.role = 'admin' AND p.deleted_at IS NULL AND p.account_status = 'active'
           AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
      LOOP
        IF public.courriel_enfiler(
             'classes', 'remplacement_personne_en_salle',
             public.courriel_adresse_profil(v_dir.id), v_dir.id,
             pg_catalog.jsonb_build_object(
               'session_id', v_s.id,
               'classe', v_s.libelle,
               'enseignant', nullif(v_s.enseignant, ''),
               'debut_local', pg_catalog.to_char(
                 v_s.started_at AT TIME ZONE coalesce(v_dir.timezone, v_s.timezone_iana, 'UTC'),
                 'YYYY-MM-DD"T"HH24:MI:SS')),
             'a3bis-alerte:' || v_s.id::text || ':' || v_dir.id::text) IS NOT NULL THEN
          v_alertes := v_alertes + 1;
        END IF;
      END LOOP;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'alerte a la direction pour la seance % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'alertes_direction', v_alertes,$b$, 1);

-- ---------------------------------------------------------------------------
-- 2e. Le motif du refus de la salle (decision du directeur du 03/11 : « l'autre
--     ne peut plus rentrer mais voit un message clair de ce qui l'empeche »).
--     public.motif_refus_salle (20261104100000) dit « acces_perdu » au seul
--     titulaire que remplacement_titulaire_ecarte designe : le DERNIER
--     evenement est son absence automatique. Avec A3-bis, l'absence et la
--     prise sont posees ensemble : le dernier evenement est la prise, et le
--     titulaire remplace retombait sur le refus generique. Le motif vaut
--     desormais aussi pour le titulaire dont un remplacant a pris la seance
--     et qui n'est plus l'enseignant effectif.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.motif_refus_salle(uuid,uuid,uuid)',
  $a$     and private.remplacement_titulaire_ecarte(p_session_id, p_profile_id) then$a$,
  $b$     and (private.remplacement_titulaire_ecarte(p_session_id, p_profile_id)
          -- A3-bis (03/11/2026) : remplace par un collegue qui a pris la seance.
          or (exists (select 1 from public.remplacements_seance r
                       where r.session_id = p_session_id
                         and r.evenement = 'remplacement_pris'
                         and r.enseignant_titulaire_id = p_profile_id)
              and private.c29_enseignant_effectif_session(p_session_id)
                  is distinct from p_profile_id)) then$b$, 1);

ALTER FUNCTION private.remplacement_auto_passer(timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacement_auto_passer(timestamptz)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.remplacement_auto_passer(timestamptz) IS
  'A3 et A3-bis : chaque minute, pre-alerte, remplacement inutile, absence automatique SEULEMENT avec un remplacant pret et candidat (jamais pour une seance creee tard), alerte e-mail a la direction si personne n''est dans la salle. N''annule jamais. Reglages remplacement.*.';

-- ---------------------------------------------------------------------------
-- 3. Verifications.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_passer text := pg_catalog.pg_get_functiondef('private.remplacement_auto_passer(timestamptz)'::regprocedure);
  v_valider text := pg_catalog.pg_get_functiondef('private.reglages_remplacement_valider()'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_passer, 'IF v_pret IS NULL OR NOT private.remplacement_candidat(v_s.id, v_pret) THEN') = 0
     OR pg_catalog.strpos(v_passer, 'a3bis-alerte:') = 0
     OR pg_catalog.strpos(v_passer, 'make_interval(mins => v_tardive)') = 0
     OR pg_catalog.strpos(v_passer, 'alertes_direction') = 0 THEN
    RAISE EXCEPTION 'A3-bis : remplacement_auto_passer incomplet';
  END IF;
  -- L'absence automatique vient apres le test du remplacant pret.
  IF pg_catalog.strpos(v_passer, 'IF v_pret IS NULL OR NOT private.remplacement_candidat')
     > pg_catalog.strpos(v_passer, 'VALUES (v_s.id, ''absence_declaree''') THEN
    RAISE EXCEPTION 'A3-bis : l''absence est posee avant le test du remplacant pret';
  END IF;
  IF pg_catalog.strpos(v_valider, 'remplacement.alerte_direction_minutes') = 0
     OR pg_catalog.strpos(v_valider, 'remplacement.seance_tardive_minutes') = 0 THEN
    RAISE EXCEPTION 'A3-bis : la validation des reglages ignore les nouvelles cles';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.motif_refus_salle(uuid,uuid,uuid)'::regprocedure),
       'A3-bis (03/11/2026) : remplace par un collegue') = 0
     OR pg_catalog.has_function_privilege('authenticated',
          'public.motif_refus_salle(uuid,uuid,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
          'public.motif_refus_salle(uuid,uuid,uuid)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'A3-bis : motif_refus_salle incomplet, ou expose';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'remplacement.alerte_direction_minutes')
     OR NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'remplacement.seance_tardive_minutes') THEN
    RAISE EXCEPTION 'A3-bis : reglages absents';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.remplacement_auto_passer(timestamptz)'::regprocedure
                    AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('authenticated',
          'private.remplacement_auto_passer(timestamptz)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
          'private.remplacement_auto_passer(timestamptz)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'A3-bis : DEFINER, search_path ou droits invalides';
  END IF;
END;
$postflight$;

COMMIT;
