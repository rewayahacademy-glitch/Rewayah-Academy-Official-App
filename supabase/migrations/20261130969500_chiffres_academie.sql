-- CHIFFRES-ACADEMIE (directeur, 20/11/2026) : la page « Les chiffres de l'academie ».
--
-- UNE lecture legere qui rend tous les chiffres de la page en un appel : public.chiffres_academie().
-- Elle ne rend QUE des agregats (des nombres) : jamais un nom, une adresse, un identifiant de personne.
-- Reservee a la direction active (garde positive), SECURITY DEFINER, search_path vide.
-- Migration additive : une table d'une ligne et une fonction neuves ; aucun index.
--
-- NE PAS DRAINER LA BASE (directeur, 20/11/2026). Deux etages :
--   * EN DIRECT, a chaque appel : un seul passage sur public.candidatures (quelques blocs) pour ce qui bouge a la minute
--     (recus, aujourd'hui, sept jours, par jour).
--   * MEMORISE, recalcule au plus une fois toutes les 10 minutes : tout le reste, dont ce qui lit les reponses JSON
--     (juz, riwayat, langues, ijaza) et les seances. Le resultat vit dans app_private.chiffres_cache (une ligne, RLS
--     activee, aucune politique, aucun droit pour un client). La fonction le recalcule elle-meme quand il a plus de
--     10 minutes ; sinon elle le rend tel quel. Deux onglets ou deux personnes ne doublent donc pas le cout. Un verrou
--     consultatif, demande sans attendre, evite deux recalculs en meme temps : le second appelant rend l'ancien
--     resultat sans attendre (ou, au tout premier appel, calcule pour lui-meme sans rien ecrire).
--   La reponse dit l'heure du calcul memorise (memorise_le).
--
-- LES JOURS se comptent a l'heure de La Mecque (l'horloge de l'academie) : « aujourd'hui » commence a
-- minuit a La Mecque ; « cette semaine » = les 7 derniers jours, aujourd'hui compris ; la tendance compare
-- ces 7 jours aux 7 jours d'avant.
--
-- LES SOURCES, chiffre par chiffre :
--   candidats.recus            candidatures de type enseignant (toutes issues)                         [direct]
--   candidats.aujourd_hui      ... recues depuis minuit a La Mecque                                    [direct]
--   candidats.sept_jours       ... recues sur les 7 derniers jours ; sept_jours_avant : les 7 d'avant  [direct]
--   candidats.par_jour         7 nombres, du plus ancien jour a aujourd'hui                            [direct]
--   candidats.pays             pays de residence distincts (candidatures.pays_residence)               [memorise]
--   candidats.hommes / femmes  candidatures.genre                                                      [memorise]
--   declarations.*             la derniere reponse ENVOYEE (pas un brouillon) de chaque candidature d'enseignant [memorise] :
--     repondants               nombre de candidatures qui ont une reponse envoyee
--     coran_entier             niveauMemorisationDeclare = coran_entier
--     juz_min                  minimum certain des juz declares : coran_entier 30, juz_N N, de_10_a_29_juz 10,
--                              moins_10_juz 1, aucune 0 (les anciennes tranches comptent pour leur borne basse)
--     ijaza                    ijazaPresentable = oui
--     riwayat                  valeurs distinctes du tableau riwayat
--     langues                  valeurs distinctes du tableau languesExplication, hors « autre »
--   academie.* [memorise] :
--     enseignants              profils de role teacher, compte actif (active ou provisional_active), non supprimes
--     eleves                   profils eleves non supprimes dont le compte n'est ni supprime ni desactive
--     eleves_en_classe         eleves distincts membres d'une classe ouverte (groupe_membres sans sortie)
--     familles                 foyers non supprimes
--     classes                  classes ouvertes (groupes sans date de fin)
--     langues_cours            langues de cours actives
--   seances.* [memorise] :
--     tenues                   seances de classe terminees (sessions.status = ended, rattachees a une classe)
--     minutes                  somme des durees de ces seances, en minutes
--     sept_jours               ... terminees sur les 7 derniers jours ; sept_jours_avant : les 7 d'avant

DO $garde$
BEGIN
  IF pg_catalog.to_regprocedure('public.chiffres_academie()') IS NOT NULL
     OR pg_catalog.to_regclass('app_private.chiffres_cache') IS NOT NULL THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : deja installe ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regprocedure('public.app_account_valid()') IS NULL
     OR pg_catalog.to_regprocedure('public.app_role()') IS NULL
     OR pg_catalog.to_regnamespace('app_private') IS NULL
     OR pg_catalog.to_regclass('public.candidatures') IS NULL
     OR pg_catalog.to_regclass('public.candidature_reponses') IS NULL THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : dependances absentes ; rien n''est modifie';
  END IF;
END
$garde$;

-- Le resultat memorise : une seule ligne. Aucun client ne la lit : seule la fonction (SECURITY DEFINER) y touche.
CREATE TABLE app_private.chiffres_cache (
  id          boolean     PRIMARY KEY DEFAULT true CHECK (id),
  calcule_le  timestamptz NOT NULL,
  valeurs     jsonb       NOT NULL CHECK (pg_catalog.jsonb_typeof(valeurs) = 'object')
);
ALTER TABLE app_private.chiffres_cache ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON app_private.chiffres_cache FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE app_private.chiffres_cache IS
  'CHIFFRES-ACADEMIE : les chiffres couteux, recalcules au plus toutes les 10 minutes par public.chiffres_academie(). Une ligne, des nombres seulement.';

CREATE FUNCTION public.chiffres_academie()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $fn$
DECLARE
  v_jour   date;         -- aujourd'hui a La Mecque
  v_debut0 timestamptz;  -- minuit a La Mecque, aujourd'hui
  v_debut7 timestamptz;  -- debut des 7 derniers jours
  v_debut14 timestamptz; -- debut des 7 jours d'avant
  v_direct jsonb;
  v_cache jsonb;
  v_cache_le timestamptz;
  v_verrou boolean := false;
  v_candidats jsonb;
  v_declarations jsonb;
  v_academie jsonb;
  v_seances jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;

  v_jour    := (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date;
  v_debut0  := (v_jour::timestamp) AT TIME ZONE 'Asia/Riyadh';
  v_debut7  := ((v_jour - 6)::timestamp) AT TIME ZONE 'Asia/Riyadh';
  v_debut14 := ((v_jour - 13)::timestamp) AT TIME ZONE 'Asia/Riyadh';

  -- EN DIRECT : un seul passage sur les candidatures.
  SELECT pg_catalog.jsonb_build_object(
           'recus', pg_catalog.count(*),
           'aujourd_hui', pg_catalog.count(*) FILTER (WHERE c.recue_le >= v_debut0),
           'sept_jours', pg_catalog.count(*) FILTER (WHERE c.recue_le >= v_debut7),
           'sept_jours_avant', pg_catalog.count(*) FILTER (WHERE c.recue_le >= v_debut14 AND c.recue_le < v_debut7),
           'par_jour', pg_catalog.jsonb_build_array(
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 6),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 5),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 4),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 3),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 2),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour - 1),
              pg_catalog.count(*) FILTER (WHERE (c.recue_le AT TIME ZONE 'Asia/Riyadh')::date = v_jour)))
    INTO v_direct
    FROM public.candidatures c
   WHERE c.type_code = 'enseignant';

  -- MEMORISE : rendu tel quel s'il a moins de 10 minutes.
  SELECT k.valeurs, k.calcule_le INTO v_cache, v_cache_le FROM app_private.chiffres_cache k WHERE k.id;

  -- Un seul recalcul memorise a la fois. Le verrou se DEMANDE sans attendre : qui ne l'obtient pas rend l'ancien
  -- resultat tel quel. S'il n'y a encore aucun resultat (tout premier appel), il calcule pour lui-meme et n'ecrit
  -- rien : un appel concurrent n'attend donc jamais, ni le verrou ni la ligne.
  IF v_cache IS NULL OR v_cache_le < pg_catalog.now() - interval '10 minutes' THEN
    v_verrou := pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtext('chiffres_academie'));
  END IF;

  IF v_verrou OR v_cache IS NULL THEN

    SELECT pg_catalog.jsonb_build_object(
             'pays', pg_catalog.count(DISTINCT c.pays_residence),
             'hommes', pg_catalog.count(*) FILTER (WHERE c.genre = 'male'),
             'femmes', pg_catalog.count(*) FILTER (WHERE c.genre = 'female'))
      INTO v_candidats
      FROM public.candidatures c
     WHERE c.type_code = 'enseignant';

    WITH derniere AS MATERIALIZED (
      SELECT DISTINCT ON (r.candidature_id) r.reponses
        FROM public.candidature_reponses r
        JOIN public.candidatures c ON c.id = r.candidature_id AND c.type_code = 'enseignant'
       WHERE NOT r.brouillon
       ORDER BY r.candidature_id, r.soumis_le DESC, r.id DESC
    ), memo AS MATERIALIZED (
      SELECT d.reponses ->> 'niveauMemorisationDeclare' AS m,
             d.reponses ->> 'ijazaPresentable' AS ijaza,
             CASE WHEN pg_catalog.jsonb_typeof(d.reponses -> 'riwayat') = 'array'
                  THEN d.reponses -> 'riwayat' ELSE '[]'::jsonb END AS riwayat,
             CASE WHEN pg_catalog.jsonb_typeof(d.reponses -> 'languesExplication') = 'array'
                  THEN d.reponses -> 'languesExplication' ELSE '[]'::jsonb END AS langues
        FROM derniere d
    )
    SELECT pg_catalog.jsonb_build_object(
             'repondants', (SELECT pg_catalog.count(*) FROM memo),
             'coran_entier', (SELECT pg_catalog.count(*) FROM memo WHERE m = 'coran_entier'),
             'juz_min', (SELECT coalesce(pg_catalog.sum(CASE
                                 WHEN m = 'coran_entier' THEN 30
                                 WHEN m ~ '^juz_([1-9]|1[0-9]|2[0-9])$' THEN pg_catalog.substr(m, 5)::integer
                                 WHEN m = 'de_10_a_29_juz' THEN 10
                                 WHEN m = 'moins_10_juz' THEN 1
                                 ELSE 0 END), 0) FROM memo),
             'ijaza', (SELECT pg_catalog.count(*) FROM memo WHERE ijaza = 'oui'),
             'riwayat', (SELECT pg_catalog.count(DISTINCT v.x)
                           FROM memo CROSS JOIN LATERAL pg_catalog.jsonb_array_elements_text(memo.riwayat) AS v(x)),
             'langues', (SELECT pg_catalog.count(DISTINCT v.x)
                           FROM memo CROSS JOIN LATERAL pg_catalog.jsonb_array_elements_text(memo.langues) AS v(x)
                          WHERE v.x <> 'autre'))
      INTO v_declarations;

    v_academie := pg_catalog.jsonb_build_object(
      'enseignants', (SELECT pg_catalog.count(*) FROM public.profiles p
                       WHERE p.role = 'teacher' AND p.deleted_at IS NULL
                         AND p.account_status IN ('active', 'provisional_active')),
      'eleves', (SELECT pg_catalog.count(*) FROM public.student_profiles sp
                   JOIN public.profiles p ON p.id = sp.profile_id
                  WHERE sp.deleted_at IS NULL AND p.deleted_at IS NULL AND p.account_status <> 'disabled'),
      'eleves_en_classe', (SELECT pg_catalog.count(DISTINCT gm.student_id)
                             FROM public.groupe_membres gm
                             JOIN public.groupes g ON g.id = gm.groupe_id
                            WHERE gm.left_at IS NULL AND g.ended_at IS NULL),
      'familles', (SELECT pg_catalog.count(*) FROM public.households h WHERE h.deleted_at IS NULL),
      'classes', (SELECT pg_catalog.count(*) FROM public.groupes g WHERE g.ended_at IS NULL),
      'langues_cours', (SELECT pg_catalog.count(*) FROM public.langues_cours l WHERE l.actif));

    SELECT pg_catalog.jsonb_build_object(
             'tenues', pg_catalog.count(*),
             'minutes', coalesce(pg_catalog.sum(
                          CASE WHEN s.ended_at > s.started_at
                               THEN pg_catalog.floor(EXTRACT(EPOCH FROM (s.ended_at - s.started_at)) / 60)::bigint
                               ELSE 0 END), 0),
             'sept_jours', pg_catalog.count(*) FILTER (WHERE s.ended_at >= v_debut7),
             'sept_jours_avant', pg_catalog.count(*) FILTER (WHERE s.ended_at >= v_debut14 AND s.ended_at < v_debut7))
      INTO v_seances
      FROM public.sessions s
     WHERE s.status = 'ended' AND s.deleted_at IS NULL AND s.groupe_id IS NOT NULL;

    v_cache := pg_catalog.jsonb_build_object(
      'candidats', v_candidats, 'declarations', v_declarations, 'academie', v_academie, 'seances', v_seances);
    v_cache_le := pg_catalog.now();

    IF v_verrou THEN
      INSERT INTO app_private.chiffres_cache AS k (id, calcule_le, valeurs)
      VALUES (true, v_cache_le, v_cache)
      ON CONFLICT (id) DO UPDATE SET calcule_le = EXCLUDED.calcule_le, valeurs = EXCLUDED.valeurs;
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'genere_le', pg_catalog.now(),
    'memorise_le', v_cache_le,
    'candidats', v_direct || (v_cache -> 'candidats'),
    'declarations', v_cache -> 'declarations',
    'academie', v_cache -> 'academie',
    'seances', v_cache -> 'seances');
END
$fn$;

COMMENT ON FUNCTION public.chiffres_academie() IS
  'CHIFFRES-ACADEMIE (20/11/2026) : tous les chiffres de la page de la direction en un appel. Agregats seulement. Direction active. Chiffres couteux memorises 10 minutes.';

REVOKE ALL ON FUNCTION public.chiffres_academie() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.chiffres_academie() TO authenticated;

-- Controle final : la fonction et la table sont telles qu'attendues, et leurs droits ne sont pas trop larges.
DO $controle$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.chiffres_academie()');
  v_role text;
BEGIN
  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : fonction absente apres creation';
  END IF;
  IF (SELECT NOT p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']
        FROM pg_catalog.pg_proc p WHERE p.oid = v_oid) THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : reglages inattendus sur la fonction';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('public', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : droits d''execution inattendus';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'app_private.chiffres_cache'::regclass) THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : RLS absente sur la table memorisee';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'agent_ro', 'public'] LOOP
    IF pg_catalog.has_table_privilege(v_role, 'app_private.chiffres_cache', 'SELECT')
       OR pg_catalog.has_table_privilege(v_role, 'app_private.chiffres_cache', 'INSERT')
       OR pg_catalog.has_table_privilege(v_role, 'app_private.chiffres_cache', 'UPDATE') THEN
      RAISE EXCEPTION 'CHIFFRES-ACADEMIE : la table memorisee est ouverte a %', v_role;
    END IF;
  END LOOP;
END
$controle$;
