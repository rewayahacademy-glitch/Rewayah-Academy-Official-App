-- COM-LISTER-FILS-ECONOME (15/11/2026) : la liste des fils de la messagerie
-- (public.com_lister_fils) faisait 657 appels en 1 h 30 a 1,5 s chacun, soit
-- 85 % du temps de la base, pour 90 fils et 139 messages.
--
-- Cause mesuree (Postgres 16, 100 Classes, 500 eleves, 90 fils) : pour chaque
-- fil, private.com_fil_json appelle private.com_paires(type, objet), dont la
-- sous-requete « membres » calculait private.com_est_mineur() pour CHAQUE
-- membre de CHAQUE Classe active, alors que chaque branche de com_paires
-- ne lit que les membres de la Classe (ou l'eleve) demandee, et les autres
-- types d'objet n'en lisent aucun. Environ 15 ms par fil, donc environ 1 s
-- pour 90 fils.
--
-- Seconde cause, mesuree sur la meme fixture : public.com_lister_fils filtrait
-- `x.fil IS NOT NULL` sur une sous-requete dont la colonne `fil` est
-- l'appel a private.com_fil_json. Postgres remonte la sous-requete dans la
-- requete du dessus (la fonction est STABLE) : com_fil_json etait donc
-- evalue DEUX fois par fil, une pour le filtre, une pour l'agregat. Un
-- `OFFSET 0` ferme la sous-requete : une seule evaluation par fil, meme
-- resultat (549 ms -> 346 ms pour 90 fils, a elle seule).
--
-- Changement 1 : la sous-requete « membres » est bornee a l'objet demande
-- ((type classe ET Classe demandee) OU (type eleve ET eleve demande)). Toutes
-- les lectures de « membres » (les branches de « cibles » et le contrôle
-- d'acces paye final) portaient deja exactement ce meme predicat : le resultat
-- de com_paires est donc identique pour tout argument. Rien d'autre ne change :
-- ni com_fil_json, ni les gardes, ni les droits (com_paires est une fonction
-- du schema private, SECURITY INVOKER, sans droit pour authenticated, anon,
-- service_role ni agent_ro).
--
-- Changement 2 : public.com_lister_fils ajoute `OFFSET 0` a sa sous-requete,
-- rien d'autre : meme SECURITY DEFINER, meme search_path vide, meme
-- proprietaire, memes droits (verifies avant et apres), meme garde, memes
-- lignes, meme ordre, meme JSON. Son empreinte F86 (md5_functiondef du
-- commentaire de la fonction) est recalculee.
--
-- Rejouable : CREATE OR REPLACE ; pour com_lister_fils, rien a faire s'il
-- porte deja `OFFSET 0`. La pre-verification de com_paires accepte l'ancien corps
-- (md5 de prosrc 0e4630c47f23184b097768c9b21fe85c) et le nouveau
-- (99c56abad2ba63b29818bbee82d03d76) et arrete la migration pour tout autre
-- (la fonction a change depuis le depot). Sans BEGIN ni COMMIT de premier
-- niveau. Aucun mot d'effacement.

DO $pre$
DECLARE
  v_md5 text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.com_paires(text,uuid)'::regprocedure;
  IF v_md5 IS DISTINCT FROM '0e4630c47f23184b097768c9b21fe85c'
     AND v_md5 IS DISTINCT FROM '99c56abad2ba63b29818bbee82d03d76' THEN
    RAISE EXCEPTION 'com_lister_fils econome : corps inattendu de private.com_paires (md5 %), la fonction a change depuis le depot', v_md5;
  END IF;
END
$pre$;

CREATE OR REPLACE FUNCTION private.com_paires(p_type text, p_objet_id uuid)
 RETURNS TABLE(a_nature text, a_id uuid, b_nature text, b_id uuid)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  WITH membres AS (
    -- Eleves actifs d'une Classe active, avec leur enseignant valide.
    SELECT g.id AS groupe_id, g.teacher_id, s.id AS eleve_id, s.household_id,
           private.com_est_mineur(s.id) AS mineur
    FROM public.groupes g
    JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
    JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
    WHERE g.ended_at IS NULL
      -- Economie (15/11/2026) : les branches ci-dessous ne lisent que les
      -- membres de la Classe demandee (type classe) ou l'eleve demande (type
      -- eleve) ; les autres types n'en lisent aucun. Calculer com_est_mineur
      -- pour chaque membre de chaque Classe, a chaque appel, coutait environ
      -- 15 ms par fil. Meme resultat.
      AND ((p_type = 'classe' AND g.id = p_objet_id)
           OR (p_type = 'eleve' AND s.id = p_objet_id))
  ), cibles AS (
    -- Classe : chaque foyer d'un eleve mineur, chaque eleve adulte, avec
    -- l'enseignant ; foyer et Administration ; enseignant et Administration.
    SELECT 'foyer' AS a_nature, mb.household_id AS a_id, 'profil' AS b_nature, mb.teacher_id AS b_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT 'profil', g.teacher_id, 'equipe', NULL
      FROM public.groupes g WHERE p_type = 'classe' AND g.id = p_objet_id AND g.ended_at IS NULL
    -- Eleve : mineur, son foyer avec son enseignant et avec l'Administration ;
    -- adulte, lui-meme avec son enseignant.
    UNION
    SELECT 'foyer', mb.household_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND NOT mb.mineur
    -- Dossier (identifiant = profil du titulaire du dossier) : enseignant
    -- ou foyer du tuteur, avec l'Administration.
    UNION
    SELECT CASE p.role WHEN 'teacher' THEN 'profil' ELSE 'foyer' END,
           CASE p.role WHEN 'teacher' THEN p.id ELSE p.household_id END,
           'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'dossier' AND p.id = p_objet_id AND p.deleted_at IS NULL
        AND p.role IN ('teacher', 'guardian')
    -- Remplacement : titulaire et remplacant, chacun avec l'Administration.
    UNION
    SELECT 'profil', x.enseignant_id, 'equipe', NULL
      FROM public.remplacements_seance r
      CROSS JOIN LATERAL (VALUES (r.enseignant_titulaire_id), (r.enseignant_remplacant_id))
        AS x(enseignant_id)
      WHERE p_type = 'remplacement' AND r.id = p_objet_id AND x.enseignant_id IS NOT NULL
    -- Profil de paiement (CPT-BR-11) : le beneficiaire enseignant et l'equipe.
    UNION
    SELECT 'profil', p.id, 'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'profilPaiement' AND p.id = p_objet_id AND p.role = 'teacher'
    -- Candidature (MESSAGES-CANDIDAT) : le candidat enseignant et l'equipe,
    -- tant que la candidature est en cours, hors pause, avant la salle des
    -- prets ; lisible par le candidat ou par la direction de son cote.
    UNION
    SELECT 'profil', cd.profile_id, 'equipe', NULL
      FROM public.candidatures cd
      WHERE p_type = 'candidature' AND cd.id = p_objet_id
        AND cd.type_code = 'enseignant' AND cd.profile_id IS NOT NULL
        AND cd.issue = 'en_cours' AND NOT cd.en_pause AND cd.etape <> 'confirmee'
        AND private.com_candidature_lisible(cd.id, auth.uid())
  )
  SELECT c.a_nature, c.a_id, c.b_nature, c.b_id
  FROM cibles c
  WHERE c.a_id IS NOT NULL
    AND (p_type = 'candidature' OR (CASE c.a_nature
          WHEN 'foyer' THEN private.com_foyer_valide(c.a_id)
          ELSE private.com_profil_valide(c.a_id, NULL) AND NOT private.com_est_mineur(c.a_id)
        END
    AND (c.b_nature = 'equipe'
         OR (private.com_profil_valide(c.b_id, 'teacher') AND c.b_id <> c.a_id))
    -- Lot (B), 02/11/2026 : avec l'enseignant, seulement si un eleve concerne
    -- (l'adulte lui-meme, ou un eleve du foyer dans cette Classe ou cet eleve)
    -- a un acces paye.
    AND (c.b_nature = 'equipe'
         OR (c.a_nature = 'profil' AND private.acces_paye(c.a_id))
         OR (c.a_nature = 'foyer' AND EXISTS (
               SELECT 1 FROM membres mb
                WHERE mb.household_id = c.a_id
                  AND ((p_type = 'classe' AND mb.groupe_id = p_objet_id)
                       OR (p_type = 'eleve' AND mb.eleve_id = p_objet_id))
                  AND private.acces_paye(mb.eleve_id))))));
$function$;

DO $lister$
DECLARE
  v_oid oid := 'public.com_lister_fils()'::regprocedure;
  v_def text;
  v_nouveau text;
  v_avant pg_catalog.pg_proc%ROWTYPE;
  v_apres pg_catalog.pg_proc%ROWTYPE;
  v_ancien_md5 text;
  v_ancien_commentaire text;
  v_pied constant text :=
    E'f.partie_b_nature, f.partie_b_id)\n  ) x\n  WHERE x.fil IS NOT NULL;';
BEGIN
  v_def := pg_catalog.pg_get_functiondef(v_oid);
  IF pg_catalog.strpos(v_def, E'f.partie_b_id)\n    OFFSET 0\n  ) x') > 0 THEN
    RAISE NOTICE 'com_lister_fils econome : OFFSET 0 deja present, rien a faire';
    RETURN;
  END IF;
  -- Le corps attendu : celui de la messagerie du candidat (com_appelant_msg),
  -- avec sa sous-requete a filtrer sur « fil ».
  IF pg_catalog.strpos(v_def, 'private.com_appelant_msg()') = 0
     OR pg_catalog.strpos(v_def, v_pied) = 0
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.regexp_matches(v_def, 'com_fil_json', 'g')) <> 1 THEN
    RAISE EXCEPTION 'com_lister_fils econome : corps inattendu de public.com_lister_fils (la fonction a change depuis le depot)';
  END IF;
  SELECT * INTO v_avant FROM pg_catalog.pg_proc WHERE oid = v_oid;
  v_ancien_md5 := pg_catalog.md5(v_def);
  v_ancien_commentaire := pg_catalog.obj_description(v_oid, 'pg_proc');

  v_nouveau := pg_catalog.replace(v_def, v_pied,
    E'f.partie_b_nature, f.partie_b_id)\n    OFFSET 0\n  ) x\n  WHERE x.fil IS NOT NULL;');
  IF v_nouveau = v_def THEN
    RAISE EXCEPTION 'com_lister_fils econome : remplacement sans effet';
  END IF;
  EXECUTE v_nouveau;

  -- Rien d'autre n'a bouge : proprietaire, DEFINER, search_path, droits,
  -- volatilite, resultat.
  SELECT * INTO v_apres FROM pg_catalog.pg_proc WHERE oid = v_oid;
  IF v_apres.proowner <> v_avant.proowner
     OR v_apres.prosecdef IS DISTINCT FROM v_avant.prosecdef
     OR v_apres.proconfig IS DISTINCT FROM v_avant.proconfig
     OR v_apres.proacl IS DISTINCT FROM v_avant.proacl
     OR v_apres.provolatile <> v_avant.provolatile
     OR v_apres.prorettype <> v_avant.prorettype
     OR NOT v_apres.prosecdef
     OR v_apres.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[] THEN
    RAISE EXCEPTION 'com_lister_fils econome : proprietaire, SECURITY DEFINER, search_path, droits ou volatilite modifies';
  END IF;

  -- L'empreinte F86 du commentaire suit le nouveau corps.
  IF v_ancien_commentaire IS NOT NULL
     AND pg_catalog.strpos(v_ancien_commentaire, 'md5_functiondef=' || v_ancien_md5) > 0 THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.com_lister_fils() IS %L',
      pg_catalog.replace(v_ancien_commentaire,
        'md5_functiondef=' || v_ancien_md5,
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  ELSE
    RAISE EXCEPTION 'com_lister_fils econome : empreinte F86 du commentaire absente ou perimee';
  END IF;
END
$lister$;

DO $post$
DECLARE
  f regprocedure;
  p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  SELECT * INTO p FROM pg_catalog.pg_proc x
   WHERE x.oid = 'private.com_paires(text,uuid)'::regprocedure;
  IF pg_catalog.md5(p.prosrc) <> '99c56abad2ba63b29818bbee82d03d76' THEN
    RAISE EXCEPTION 'com_lister_fils econome : corps de com_paires non installe';
  END IF;
  -- Inchange : invoker, stable, search_path vide, aucun droit hors proprietaire.
  IF p.prosecdef OR p.provolatile <> 's'
     OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[] THEN
    RAISE EXCEPTION 'com_lister_fils econome : attributs de com_paires modifies';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'com_lister_fils econome : droit EXECUTE ouvert sur com_paires';
  END IF;
  -- Les RPC de la messagerie gardent leurs droits : authenticated seul.
  FOREACH f IN ARRAY ARRAY[
    'public.com_lister_fils()'::regprocedure,
    'public.com_lire_fil(uuid)'::regprocedure,
    'public.com_conversations_pour_objet(text,uuid)'::regprocedure,
    'public.com_ouvrir_conversation(text,uuid,text)'::regprocedure,
    'public.com_fil_pour_objet(text,uuid)'::regprocedure
  ] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'com_lister_fils econome : droits EXECUTE modifies pour %', f;
    END IF;
  END LOOP;
END
$post$;
