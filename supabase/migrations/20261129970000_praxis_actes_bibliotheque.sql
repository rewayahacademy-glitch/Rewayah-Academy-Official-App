-- PX-BD-BIBLIOTHEQUE (pilote, 17/11/2026, plan PLAN-BRAS-DROIT.md, decisions DB1 a DB9, consigne du directeur de 14 h 05 :
-- « ce n'est pas le directeur qui depose un fichier, c'est Praxis qui REDIGE le support avec lui dans le chat, puis le DEPOSE et le
-- CONFIGURE ») : les premiers ACTES du catalogue de Praxis en mode chat, sur la Bibliotheque.
--
-- CE QUE CE FICHIER OUVRE (quatre actes, tous de la CLE DE CHAT seulement, sous l'identite de la direction emettrice, via le pont de
-- PX-BD-0) :
--   * support_lister   (A) : lire le catalogue des supports (identifiant, titre, type, rayon, ordre, visibilite, etapes, tranches, REVISION,
--                            etat) pour trouver quoi modifier ; aucune donnee de personne ;
--   * support_modifier (A) : corriger les champs de la fiche d'un support (titre, description, visibilite, tranches, etapes, lecture, ecole...) ;
--   * support_deplacer (A) : ranger un support (rayon, ordre, etapes du programme) ;
--   * support_retirer  (S) : retirer = MASQUER (`archived_at`), jamais effacer ; lot prepare, code lu en aal2.
--
-- CE QUE CE FICHIER N'OUVRE PAS : `support_deposer` (creer le document a partir d'un contenu redige). Il exige de PRODUIRE un fichier et de
-- l'ecrire dans le coffre R2, ce qu'aucune fonction SQL ne sait faire : il sera porte par la fonction Edge du connecteur, dans une PR
-- suivante, apres la decision sur le FORMAT (BIBLIOTHEQUE-CHAT.md, §3 : PDF genere cote serveur ou page HTML, avec le risque de la
-- ecriture arabe vocalisee). Aucun acte « publier », aucun acte « visibilite publique » : la visibilite offerte au chat est inscrits,
-- groupe assigne ou enseignant seul.
--
-- Chaque adaptateur est la SEULE validation de ses parametres (cles connues, bornes, valeurs d'une liste fermee) ; la regle metier reste dans
-- les fonctions de la direction (`library_mettre_a_jour`, `library_retirer`), appelees telles quelles : UNE logique pour les humains et pour
-- Praxis, aucune copie. `p_a_sec` vrai : valider et rendre le RESUME sans rien ecrire.
--
-- PREFLIGHT : le pont de PX-BD-0 (20261129960000) est present, son empreinte est celle attendue, l'ancre ACTES-ANCRE y figure UNE fois ; le
-- catalogue ne contient pas deja ces actes. FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Sans BEGIN ni COMMIT de premier
-- niveau.

DO $preflight$
DECLARE
  v_def text;
  v_ancre constant text := '    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l''acte';
BEGIN
  IF pg_catalog.to_regprocedure('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)') IS NULL
     OR pg_catalog.to_regclass('private.praxis_actes') IS NULL
     OR pg_catalog.to_regprocedure('public.library_mettre_a_jour(uuid, jsonb, integer)') IS NULL
     OR pg_catalog.to_regprocedure('public.library_retirer(uuid, text, integer)') IS NULL THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : une dependance est absente (le pont de PX-BD-0, ou les fonctions de la Bibliotheque)';
  END IF;
  v_def := pg_catalog.pg_get_functiondef('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure);
  IF pg_catalog.md5(v_def) <> '3650343d5675d696d6e6989460e5e893'
     AND pg_catalog.strpos(v_def, 'support_lister') = 0 THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : le pont a change (md5 %), rien n''est change', pg_catalog.md5(v_def);
  END IF;
  IF pg_catalog.strpos(v_def, 'support_lister') = 0
     AND (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre) <> 1 THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : l''ancre du pont est absente ou en double';
  END IF;
  IF EXISTS (SELECT 1 FROM private.praxis_actes a WHERE a.acte LIKE 'support\_%' ESCAPE '\') THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le catalogue : quatre lignes. La description est CE QUE LE MODELE LIT : elle dit les valeurs par defaut et ce qu'il doit demander.
-- ---------------------------------------------------------------------------
INSERT INTO private.praxis_actes (acte, niveau, description, lot_max) VALUES
  ('support_lister', 'A',
   'Lit les supports de la Bibliotheque : id, titre, type, rayon, ordre, visibilite, etapes, tranches, revision, retire. Filtres facultatifs : recherche (texte du titre), rayon (cours ou plus_loin), retires (vrai pour voir les retires), limite (50 au plus). A faire AVANT toute modification : il donne l id et la revision.', 1),
  ('support_modifier', 'A',
   'Corrige la fiche d un support : id et revision (pris dans support_lister) obligatoires ; facultatifs : titre (200 signes), titre_court (60), description (4000), edition, organisme, conditions_attribution, visibilite (inscrits par defaut, groupe_assigne ou enseignant_seul), politique_hors_ligne (jamais, sur_demande, automatique), tranches (enfant_6_9, enfant_10_13, ado_14_17, adulte_18_plus), etapes, lecture_coran (hafs, warsh, qalun, shuba), ecole_priere. Un champ absent ne change pas.', 1),
  ('support_deplacer', 'A',
   'Range un support : id et revision (pris dans support_lister) obligatoires ; facultatifs : rayon (cours = Documents des cours, plus_loin = Pour aller plus loin), ordre (0 a 100000, plus petit = plus haut), etapes (etapes du programme, 20 au plus). Un champ absent ne change pas.', 1),
  ('support_retirer', 'S',
   'Retire un support : il est MASQUE aux inscrits, jamais efface. id et revision (pris dans support_lister) et motif (3 a 500 signes, dit a la direction) obligatoires. Se prepare, la direction lit le code dans l application, puis tu confirmes.', 20);

-- ---------------------------------------------------------------------------
-- 2. Les adaptateurs. Chacun : cles connues seulement, valeurs bornees, resume a sec, appel de la fonction de la direction telle quelle.
-- ---------------------------------------------------------------------------

-- 2.1 Lister.
CREATE FUNCTION private.praxis_acte_support_lister(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_recherche text := nullif(pg_catalog.btrim(coalesce(p ->> 'recherche', '')), '');
  v_rayon text := p ->> 'rayon';
  v_retires boolean;
  v_limite integer;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (ARRAY['recherche', 'rayon', 'retires', 'limite']))
     OR (p ? 'recherche' AND pg_catalog.jsonb_typeof(p -> 'recherche') <> 'string')
     OR (v_recherche IS NOT NULL AND pg_catalog.length(v_recherche) > 60)
     OR (p ? 'rayon' AND (pg_catalog.jsonb_typeof(p -> 'rayon') <> 'string' OR v_rayon NOT IN ('cours', 'plus_loin')))
     OR (p ? 'retires' AND pg_catalog.jsonb_typeof(p -> 'retires') <> 'boolean')
     OR (p ? 'limite' AND (pg_catalog.jsonb_typeof(p -> 'limite') <> 'number' OR (p ->> 'limite') !~ '^[0-9]{1,2}$'
         OR (p ->> 'limite')::integer NOT BETWEEN 1 AND 50)) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_retires := coalesce((p ->> 'retires')::boolean, false);
  v_limite := coalesce((p ->> 'limite')::integer, 25);
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', 'Lire les supports de la Bibliotheque');
  END IF;
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object('supports', coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', t.id, 'titre', t.title, 'type', t.resource_type::text, 'rayon', t.rayon, 'ordre', t.ordre,
             'visibilite', t.access_policy::text, 'etapes', pg_catalog.to_jsonb(t.etapes),
             'tranches', pg_catalog.to_jsonb(t.tranches), 'revision', t.revision, 'retire', t.archived_at IS NOT NULL,
             'publie', t.current_version_id IS NOT NULL) ORDER BY t.rayon, t.ordre, t.title, t.id)
      FROM (SELECT r.* FROM public.library_resource r
             WHERE (r.archived_at IS NOT NULL) = v_retires
               AND (v_rayon IS NULL OR r.rayon = v_rayon)
               AND (v_recherche IS NULL OR r.title ILIKE '%' || pg_catalog.replace(pg_catalog.replace(v_recherche, '%', ''), '_', '') || '%')
             ORDER BY r.rayon, r.ordre, r.title, r.id LIMIT v_limite) t), '[]'::jsonb));
END;
$f$;

-- 2.2 Modifier la fiche.
CREATE FUNCTION private.praxis_acte_support_modifier(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_cles constant text[] := ARRAY['id', 'revision', 'titre', 'titre_court', 'description', 'edition', 'organisme', 'conditions_attribution',
                                  'visibilite', 'politique_hors_ligne', 'tranches', 'etapes', 'lecture_coran', 'ecole_priere'];
  v_id uuid;
  v_titre text;
  v_mod jsonb := '{}'::jsonb;
  v_rendu jsonb;
  v_n integer;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (v_cles))
     OR pg_catalog.jsonb_typeof(p -> 'id') IS DISTINCT FROM 'string' OR (p ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     OR pg_catalog.jsonb_typeof(p -> 'revision') IS DISTINCT FROM 'number' OR (p ->> 'revision') !~ '^[1-9][0-9]{0,8}$'
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p - ARRAY['id', 'revision', 'tranches', 'etapes']) e
                 WHERE pg_catalog.jsonb_typeof(e.value) <> 'string')
     OR (p ? 'tranches' AND (pg_catalog.jsonb_typeof(p -> 'tranches') <> 'array' OR pg_catalog.jsonb_array_length(p -> 'tranches') NOT BETWEEN 1 AND 4
         OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p -> 'tranches') x
                     WHERE pg_catalog.jsonb_typeof(x) <> 'string'
                        OR (x #>> '{}') <> ALL (ARRAY['enfant_6_9', 'enfant_10_13', 'ado_14_17', 'adulte_18_plus']))))
     OR (p ? 'etapes' AND (pg_catalog.jsonb_typeof(p -> 'etapes') <> 'array' OR pg_catalog.jsonb_array_length(p -> 'etapes') > 20
         OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p -> 'etapes') x
                     WHERE pg_catalog.jsonb_typeof(x) <> 'string' OR (x #>> '{}') !~ '^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$')))
     OR (p ? 'visibilite' AND (p ->> 'visibilite') <> ALL (ARRAY['inscrits', 'groupe_assigne', 'enseignant_seul']))
     OR (p ? 'politique_hors_ligne' AND (p ->> 'politique_hors_ligne') <> ALL (ARRAY['jamais', 'sur_demande', 'automatique']))
     OR (p ? 'lecture_coran' AND (p ->> 'lecture_coran') <> ALL (ARRAY['hafs', 'warsh', 'qalun', 'shuba'])) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_id := (p ->> 'id')::uuid;
  -- Les cles du chat vers celles de la fiche. Un champ absent ne change pas ; vide, il est retire.
  v_mod := (SELECT coalesce(pg_catalog.jsonb_object_agg(m.fiche, p -> m.chat), '{}'::jsonb)
              FROM (VALUES ('titre', 'titre'), ('titre_court', 'titreCourt'), ('description', 'description'), ('edition', 'edition'),
                           ('organisme', 'organisme'), ('conditions_attribution', 'conditionsAttribution'), ('visibilite', 'visibilite'),
                           ('politique_hors_ligne', 'politiqueHorsLigne'), ('tranches', 'tranches'), ('etapes', 'etapes'),
                           ('lecture_coran', 'lectureCoran'), ('ecole_priere', 'ecolePriere')) AS m(chat, fiche)
             WHERE p ? m.chat);
  SELECT pg_catalog.count(*)::integer INTO v_n FROM pg_catalog.jsonb_object_keys(v_mod);
  IF v_n = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'rien_a_changer');
  END IF;
  SELECT r.title INTO v_titre FROM public.library_resource r WHERE r.id = v_id AND r.archived_at IS NULL;
  IF v_titre IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'support_introuvable');
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', pg_catalog.format('Modifier « %s » : %s', pg_catalog.left(v_titre, 60),
      (SELECT pg_catalog.string_agg(k, ', ' ORDER BY k) FROM pg_catalog.jsonb_object_keys(v_mod) k)));
  END IF;
  v_rendu := public.library_mettre_a_jour(v_id, v_mod, (p ->> 'revision')::integer);
  IF v_rendu ->> 'resultat' = 'EcritureEnConflit' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'revision_changee', 'revision', v_rendu -> 'revision');
  END IF;
  RETURN pg_catalog.jsonb_build_object('ok', true, 'revision', v_rendu -> 'revision');
END;
$f$;

-- 2.3 Deplacer.
CREATE FUNCTION private.praxis_acte_support_deplacer(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_id uuid;
  v_titre text;
  v_mod jsonb := '{}'::jsonb;
  v_rendu jsonb;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (ARRAY['id', 'revision', 'rayon', 'ordre', 'etapes']))
     OR pg_catalog.jsonb_typeof(p -> 'id') IS DISTINCT FROM 'string' OR (p ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     OR pg_catalog.jsonb_typeof(p -> 'revision') IS DISTINCT FROM 'number' OR (p ->> 'revision') !~ '^[1-9][0-9]{0,8}$'
     OR (p ? 'rayon' AND (pg_catalog.jsonb_typeof(p -> 'rayon') <> 'string' OR (p ->> 'rayon') <> ALL (ARRAY['cours', 'plus_loin'])))
     OR (p ? 'ordre' AND (pg_catalog.jsonb_typeof(p -> 'ordre') <> 'number' OR (p ->> 'ordre') !~ '^[0-9]{1,6}$' OR (p ->> 'ordre')::integer > 100000))
     OR (p ? 'etapes' AND (pg_catalog.jsonb_typeof(p -> 'etapes') <> 'array' OR pg_catalog.jsonb_array_length(p -> 'etapes') > 20
         OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p -> 'etapes') x
                     WHERE pg_catalog.jsonb_typeof(x) <> 'string' OR (x #>> '{}') !~ '^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$'))) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF NOT (p ? 'rayon' OR p ? 'ordre' OR p ? 'etapes') THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'rien_a_changer');
  END IF;
  v_id := (p ->> 'id')::uuid;
  SELECT r.title INTO v_titre FROM public.library_resource r WHERE r.id = v_id AND r.archived_at IS NULL;
  IF v_titre IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'support_introuvable');
  END IF;
  v_mod := (SELECT coalesce(pg_catalog.jsonb_object_agg(k.cle, p -> k.cle), '{}'::jsonb)
              FROM (VALUES ('rayon'), ('ordre'), ('etapes')) AS k(cle) WHERE p ? k.cle);
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', pg_catalog.format('Ranger « %s » : %s', pg_catalog.left(v_titre, 60),
      (SELECT pg_catalog.string_agg(k, ', ' ORDER BY k) FROM pg_catalog.jsonb_object_keys(v_mod) k)));
  END IF;
  v_rendu := public.library_mettre_a_jour(v_id, v_mod, (p ->> 'revision')::integer);
  IF v_rendu ->> 'resultat' = 'EcritureEnConflit' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'revision_changee', 'revision', v_rendu -> 'revision');
  END IF;
  RETURN pg_catalog.jsonb_build_object('ok', true, 'revision', v_rendu -> 'revision');
END;
$f$;

-- 2.4 Retirer (masquer, jamais effacer).
CREATE FUNCTION private.praxis_acte_support_retirer(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_id uuid;
  v_titre text;
  v_motif text;
  v_rendu jsonb;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (ARRAY['id', 'revision', 'motif']))
     OR pg_catalog.jsonb_typeof(p -> 'id') IS DISTINCT FROM 'string' OR (p ->> 'id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     OR pg_catalog.jsonb_typeof(p -> 'revision') IS DISTINCT FROM 'number' OR (p ->> 'revision') !~ '^[1-9][0-9]{0,8}$'
     OR pg_catalog.jsonb_typeof(p -> 'motif') IS DISTINCT FROM 'string'
     OR pg_catalog.length(pg_catalog.btrim(p ->> 'motif')) NOT BETWEEN 3 AND 500 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_id := (p ->> 'id')::uuid;
  v_motif := pg_catalog.btrim(p ->> 'motif');
  SELECT r.title INTO v_titre FROM public.library_resource r WHERE r.id = v_id AND r.archived_at IS NULL;
  IF v_titre IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'support_introuvable');
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', pg_catalog.format('Retirer « %s » (masque, jamais efface). Motif : %s',
      pg_catalog.left(v_titre, 60), pg_catalog.left(v_motif, 80)));
  END IF;
  v_rendu := public.library_retirer(v_id, v_motif, (p ->> 'revision')::integer);
  IF v_rendu ->> 'resultat' = 'EcritureEnConflit' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'revision_changee', 'revision', v_rendu -> 'revision');
  END IF;
  RETURN pg_catalog.jsonb_build_object('ok', true, 'revision', v_rendu -> 'revision');
END;
$f$;

-- ---------------------------------------------------------------------------
-- 3. Le pont : une branche par acte, a l'ancre. Rien d'autre ne change.
-- ---------------------------------------------------------------------------
DO $pont$
DECLARE
  v_f constant regprocedure := 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l''acte';
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, 'support_lister') = 0 THEN
    EXECUTE pg_catalog.replace(v_def, v_ancre,
      '    ELSIF p_acte = ''support_lister'' THEN v_res := private.praxis_acte_support_lister(p_params, p_a_sec);' || pg_catalog.chr(10) ||
      '    ELSIF p_acte = ''support_modifier'' THEN v_res := private.praxis_acte_support_modifier(p_params, p_a_sec);' || pg_catalog.chr(10) ||
      '    ELSIF p_acte = ''support_deplacer'' THEN v_res := private.praxis_acte_support_deplacer(p_params, p_a_sec);' || pg_catalog.chr(10) ||
      '    ELSIF p_acte = ''support_retirer'' THEN v_res := private.praxis_acte_support_retirer(p_params, p_a_sec);' || pg_catalog.chr(10) || v_ancre);
  END IF;
END;
$pont$;

-- ---------------------------------------------------------------------------
-- 4. Proprietaire, droits, empreintes.
-- ---------------------------------------------------------------------------
ALTER FUNCTION private.praxis_acte_support_lister(jsonb, boolean) OWNER TO postgres;
ALTER FUNCTION private.praxis_acte_support_modifier(jsonb, boolean) OWNER TO postgres;
ALTER FUNCTION private.praxis_acte_support_deplacer(jsonb, boolean) OWNER TO postgres;
ALTER FUNCTION private.praxis_acte_support_retirer(jsonb, boolean) OWNER TO postgres;

DO $droits$
DECLARE
  v_f text;
  v_role text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['private.praxis_acte_support_lister(jsonb, boolean)', 'private.praxis_acte_support_modifier(jsonb, boolean)',
                             'private.praxis_acte_support_deplacer(jsonb, boolean)', 'private.praxis_acte_support_retirer(jsonb, boolean)'] LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_f);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_f, v_role);
      END IF;
    END LOOP;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.praxis_acte_support_lister(jsonb, boolean) IS
  'PX-BD-BIBLIOTHEQUE: guard_type=INTERNAL_ACTE; acte A du chat : lit le catalogue des supports (revision comprise) ; appele par le pont seul. date=2026-11-17.';
COMMENT ON FUNCTION private.praxis_acte_support_modifier(jsonb, boolean) IS
  'PX-BD-BIBLIOTHEQUE: guard_type=INTERNAL_ACTE; acte A du chat : corrige la fiche d un support par library_mettre_a_jour ; visibilite limitee a inscrits, groupe_assigne, enseignant_seul ; appele par le pont seul. date=2026-11-17.';
COMMENT ON FUNCTION private.praxis_acte_support_deplacer(jsonb, boolean) IS
  'PX-BD-BIBLIOTHEQUE: guard_type=INTERNAL_ACTE; acte A du chat : range un support (rayon, ordre, etapes) par library_mettre_a_jour ; appele par le pont seul. date=2026-11-17.';
COMMENT ON FUNCTION private.praxis_acte_support_retirer(jsonb, boolean) IS
  'PX-BD-BIBLIOTHEQUE: guard_type=INTERNAL_ACTE; acte S du chat : retire (masque, jamais efface) un support par library_retirer ; appele par le pont seul. date=2026-11-17.';

DO $postflight$
DECLARE
  v_f regprocedure;
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.praxis_actes a WHERE a.acte LIKE 'support\_%' ESCAPE '\') <> 4 THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : le catalogue doit contenir exactement quatre actes support_*';
  END IF;
  FOREACH v_f IN ARRAY ARRAY[
    'private.praxis_acte_support_lister(jsonb, boolean)'::regprocedure, 'private.praxis_acte_support_modifier(jsonb, boolean)'::regprocedure,
    'private.praxis_acte_support_deplacer(jsonb, boolean)'::regprocedure, 'private.praxis_acte_support_retirer(jsonb, boolean)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : DEFINER, proprietaire ou ACL invalide pour %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure),
                       'private.praxis_acte_support_retirer') = 0 THEN
    RAISE EXCEPTION 'PX-BD-BIBLIOTHEQUE : le pont n''a pas recu les quatre branches';
  END IF;
END
$postflight$;
