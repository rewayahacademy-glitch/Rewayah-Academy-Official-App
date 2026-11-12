-- SOCLE-PROGRAMME (lot 1 de la charte pedagogique, 12/11/2026).
-- Plan : docs/current/pedagogie/PLAN-DE-CONSTRUCTION.md, « Lot 1 » ; valeurs :
-- docs/current/pedagogie/REGLAGES.md, tableaux 1 et 1 bis ; bilan du lot :
-- docs/current/pedagogie/lots/LOT-1-SOCLE-PROGRAMME.md.
--
-- Fichier ADDITIF, sans aucun mot d'effacement (zero instruction de retrait :
-- les retraits sont pour le lot 10). Numero propose par l'agent du lot, a
-- confirmer par le garde-cap (plage 20261123900000 a 20261123999999, libre au
-- 12/11 dans RESERVATIONS-MIGRATIONS.md et dans toutes les branches distantes).
--
-- Ce que fait ce fichier :
--   1. Le programme des bases en donnees, fidele aux decisions : un niveau
--      (`programme_cycles`, code stable `bases`, duree prevue et date limite par
--      tranche d'age : 37/28/24/15 et 48/36/31/20 semaines) et ses quatre etapes
--      (`programme_niveaux`, codes stables BASES-1 a BASES-4) avec objectifs,
--      matiere principale et matiere secondaire par tranche d'age, duree prevue
--      et repere (`durees[tranche].limite` = repere du tableau 1 bis, plus jamais
--      une date ferme). La somme des reperes egale la date limite du niveau ;
--      la publication le verifie en base.
--   2. Publier une version archive la precedente ; un index interdit deux
--      versions publiees.
--   3. Le fait unique « etape en cours » par eleve (`eleve_etape_en_cours`),
--      pose seul a l'entree en classe et pour les eleves deja presents ; les
--      gestes existants de la direction (decider_placement,
--      progression_promouvoir) le corrigent par un declencheur. Chaque classe
--      recoit seule l'etape 1 des bases si elle n'a pas d'etape.
--   4. `private.etape_eleve` lit ce fait d'abord (meme signature) : toutes ses
--      lectures rendent la meme etape. `public.etape_eleve_lecture` est LA
--      lecture unique de l'etape de l'eleve, pour tous les roles.
--   5. Le point d'accroche du lot 2 (fermetures, pauses) : la colonne
--      `recul_jours`, lue a un seul endroit (`private.date_limite_effective`).
--
-- A l'installation, sans geste de la direction : la version en brouillon (s'il
-- y en a une et qu'elle se laisse completer) est completee puis publiee, sinon
-- une version neuve est creee et publiee ; auteur = l'auteur du brouillon, ou a
-- defaut le plus ancien compte de la direction. Sur une base sans direction (CI,
-- base nue), rien n'est seme : `private.semer_programme_bases(auteur)` le fait
-- quand on l'appelle.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.eleve_etape_en_cours') IS NOT NULL THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.etape_eleve(uuid, uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.vitesse_eleve(timestamptz, integer, date, timestamptz)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.preremplir_bases_programme(uuid)') IS NULL
     OR pg_catalog.to_regclass('private.sourates_des_bases') IS NULL
     OR pg_catalog.to_regclass('public.sourates_validees') IS NULL
     OR pg_catalog.to_regclass('public.classe_position_reprise') IS NULL THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : C1, C2, SUIVI-ELEVE, FORMULE-VITESSE-UNIQUE ou SOURATES absent';
  END IF;
  -- creer_version_programme doit etre celle de C2 (copie du contenu, garde positive).
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.creer_version_programme(uuid)'::pg_catalog.regprocedure),
       'objectifs, plage_support, durees') = 0 THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : creer_version_programme n''est pas celle de CAHIER-C2';
  END IF;
  -- Aucune base ne doit deja porter deux versions publiees (l'index plus bas les refuserait).
  IF (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'publiee') > 1 THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : plusieurs versions publiees, a arbitrer avant installation';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le niveau d'une version, et ce que l'etape porte de plus
-- ---------------------------------------------------------------------------
ALTER TABLE public.programme_niveaux
  ADD COLUMN cycle_code text CHECK (cycle_code IS NULL OR pg_catalog.btrim(cycle_code) <> ''),
  ADD COLUMN matieres jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(matieres) = 'object');

COMMENT ON COLUMN public.programme_niveaux.cycle_code IS
  'SOCLE-PROGRAMME : le code stable du niveau de l''etape (programme_cycles.code). Nul = '
  'etape d''avant la charte, sans niveau declare.';
COMMENT ON COLUMN public.programme_niveaux.matieres IS
  'SOCLE-PROGRAMME : par code de cohortes_age, {principale, secondaire} (texte, secondaire '
  'nulle quand il n''y en a pas encore).';
COMMENT ON COLUMN public.programme_niveaux.durees IS
  'CAHIER-C2, precise par SOCLE-PROGRAMME : par code de cohortes_age, {prevue, limite} en '
  'semaines ; prevue = duree prevue de l''etape, limite = REPERE de l''etape (REGLAGES.md, '
  'tableau 1 bis), jamais une date ferme : la date ferme est celle du niveau (programme_cycles).';

CREATE TABLE public.programme_cycles (
  version_id uuid NOT NULL REFERENCES public.programme_versions(id),
  code text NOT NULL CHECK (pg_catalog.btrim(code) <> ''),
  nom_humain text NOT NULL CHECK (pg_catalog.btrim(nom_humain) <> ''),
  ordre int NOT NULL,
  durees jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(durees) = 'object'),
  PRIMARY KEY (version_id, code)
);

COMMENT ON TABLE public.programme_cycles IS
  'SOCLE-PROGRAMME (12/11/2026) : le niveau d''une version du programme (code stable, nom), '
  'avec par tranche d''age la duree prevue et la date limite du niveau en semaines '
  '({prevue, limite}). La somme des reperes de ses etapes egale sa date limite (controle a la '
  'publication). Aucune ecriture directe.';

ALTER TABLE public.programme_cycles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.programme_cycles FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.programme_cycles TO authenticated;
CREATE POLICY programme_cycles_lecture ON public.programme_cycles
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- ---------------------------------------------------------------------------
-- 2. Le fait unique « etape en cours »
-- ---------------------------------------------------------------------------
-- Sans cle etrangere vers profiles, a dessein : un compte efface par le service
-- d'authentification ne doit jamais etre bloque par ce fait.
CREATE TABLE public.eleve_etape_en_cours (
  student_id uuid PRIMARY KEY,
  niveau_id uuid NOT NULL REFERENCES public.programme_niveaux(id),
  etape_entree_id uuid NOT NULL REFERENCES public.programme_niveaux(id),
  cohorte text REFERENCES public.cohortes_age(code),
  entree_etape_le date NOT NULL,
  entree_niveau_le date NOT NULL,
  date_limite_niveau date,
  recul_jours int NOT NULL DEFAULT 0 CHECK (recul_jours >= 0),
  origine text NOT NULL CHECK (origine IN ('classe', 'decision')),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CHECK (entree_etape_le >= entree_niveau_le)
);

COMMENT ON TABLE public.eleve_etape_en_cours IS
  'SOCLE-PROGRAMME (12/11/2026, arbitrage n. 1) : UN fait par eleve. niveau_id = son etape, '
  'dans SA version (il finit son etape dans sa version) ; etape_entree_id = l''etape par '
  'laquelle il est entre dans le niveau ; cohorte = tranche figee a l''entree dans le niveau '
  '(un anniversaire ne change pas la date limite) ; date_limite_niveau = entree + reperes des '
  'etapes restantes ; recul_jours = recul pour fermetures et pauses (lot 2, 0 aujourd''hui). '
  'Ecrit par les seuls declencheurs et fonctions de ce lot. Aucun acces direct.';
COMMENT ON COLUMN public.eleve_etape_en_cours.recul_jours IS
  'SOCLE-PROGRAMME : point d''accroche du lot 2 (CALENDRIER-ET-PAUSES). Jours de recul de la '
  'date limite pour fermetures et pauses accordees ; lu par private.date_limite_effective seul.';

ALTER TABLE public.eleve_etape_en_cours ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.eleve_etape_en_cours FROM PUBLIC, anon, authenticated, service_role;

-- Le reglage de l'age ou l'eleve voit sa date limite (REGLAGES.md, partie 6 : 10 ans).
INSERT INTO public.app_config (key, value)
VALUES ('programme.age_voit_date_limite', pg_catalog.to_jsonb(10))
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Le contenu des bases, une seule fois
-- ---------------------------------------------------------------------------
-- Les quatre etapes (programme-rewayah §2, charte 3.1). Objectifs : ceux de
-- EVALUATIONS.md partie 4 (en vigueur) ; repris de C2 quand ils etaient fideles.
-- Durees : REGLAGES.md tableau 1 bis, {prevue, limite = repere}. Matieres :
-- charte 3.1 et EVALUATIONS.md 4.1 (6-9 ans : le livre seul jusqu'a la chadda ;
-- 10 ans et plus : Al-Fatiha des la premiere semaine, puis le meme ordre ; le
-- livre valide, le Coran devient la matiere principale).
CREATE FUNCTION private.contenu_bases()
RETURNS TABLE (
  ordre int,
  code text,
  nom text,
  description text,
  objectifs text[],
  plage jsonb,
  durees jsonb,
  matieres jsonb
)
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH txt AS (
    SELECT
      'Al-Fatiha, puis An-Nâs, Al-Falaq et Al-Ikhlâs, puis les paroles de la prière et les ablutions, puis les autres invocations'::text AS suite_enfant,
      'Al-Fatiha dès la première semaine, puis An-Nâs, Al-Falaq et Al-Ikhlâs, puis les paroles de la prière et les ablutions, puis les autres invocations'::text AS suite_10,
      'La révision de la lecture, les invocations et l''adab'::text AS apres_livre
  )
  SELECT e.ordre, e.code, e.nom, e.description, e.objectifs, e.plage, e.durees, e.matieres
    FROM txt CROSS JOIN LATERAL (VALUES
      (1, 'BASES-1', 'Les lettres',
       'Les lettres de l''alphabet, seules et dans le mot.',
       ARRAY['Reconnaît chaque lettre dans le désordre',
             'Prononce chaque lettre depuis son point de sortie',
             'Distingue les lettres qui se ressemblent',
             'Reconnaît une lettre au début, au milieu et à la fin d''un mot'],
       '{"support": "livre_rewayah"}'::jsonb,
       '{"enfant_6_9": {"prevue": 8, "limite": 10}, "enfant_10_13": {"prevue": 6, "limite": 8},
         "ado_14_17": {"prevue": 5, "limite": 6}, "adulte_18_plus": {"prevue": 3, "limite": 4}}'::jsonb,
       pg_catalog.jsonb_build_object(
         'enfant_6_9', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les lettres', 'secondaire', NULL),
         'enfant_10_13', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les lettres', 'secondaire', txt.suite_10),
         'ado_14_17', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les lettres', 'secondaire', txt.suite_10),
         'adulte_18_plus', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les lettres', 'secondaire', txt.suite_10))),
      (2, 'BASES-2', 'Lire avec les voyelles',
       'Jusqu''à la chadda.',
       ARRAY['Lit une lettre avec chacune des trois voyelles',
             'Lit les voyelles longues et le soukoun',
             'Lit le tanwin',
             'Lit la chadda',
             'Lit un mot de plusieurs syllabes sans épeler'],
       '{"support": "livre_rewayah"}'::jsonb,
       '{"enfant_6_9": {"prevue": 14, "limite": 19}, "enfant_10_13": {"prevue": 11, "limite": 14},
         "ado_14_17": {"prevue": 9, "limite": 13}, "adulte_18_plus": {"prevue": 6, "limite": 8}}'::jsonb,
       pg_catalog.jsonb_build_object(
         'enfant_6_9', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les voyelles, jusqu''à la chadda', 'secondaire', NULL),
         'enfant_10_13', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les voyelles, jusqu''à la chadda', 'secondaire', txt.suite_10),
         'ado_14_17', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les voyelles, jusqu''à la chadda', 'secondaire', txt.suite_10),
         'adulte_18_plus', pg_catalog.jsonb_build_object('principale', 'Le livre de lecture de Rewayah : les voyelles, jusqu''à la chadda', 'secondaire', txt.suite_10))),
      (3, 'BASES-3', 'Lire dans le Coran',
       'La fin du livre, puis le Mushaf.',
       ARRAY['Lit les dernières pages du livre sans épeler',
             'Lit une page du Mushaf en suivant ses signes',
             'Lit d''un rythme régulier, sans revenir en arrière'],
       '{"support": "livre_rewayah"}'::jsonb,
       '{"enfant_6_9": {"prevue": 8, "limite": 10}, "enfant_10_13": {"prevue": 6, "limite": 8},
         "ado_14_17": {"prevue": 5, "limite": 6}, "adulte_18_plus": {"prevue": 3, "limite": 4}}'::jsonb,
       pg_catalog.jsonb_build_object(
         'enfant_6_9', pg_catalog.jsonb_build_object('principale', 'La fin du livre de lecture, puis le Mushaf', 'secondaire', txt.suite_enfant),
         'enfant_10_13', pg_catalog.jsonb_build_object('principale', 'La fin du livre de lecture, puis le Mushaf', 'secondaire', txt.suite_10),
         'ado_14_17', pg_catalog.jsonb_build_object('principale', 'La fin du livre de lecture, puis le Mushaf', 'secondaire', txt.suite_10),
         'adulte_18_plus', pg_catalog.jsonb_build_object('principale', 'La fin du livre de lecture, puis le Mushaf', 'secondaire', txt.suite_10))),
      (4, 'BASES-4', 'Les sourates courtes, d''Al-Masad à Az-Zalzalah',
       'Les 13 sourates, d''Al-Masad (111) à Az-Zalzalah (99) ; les 17 sourates des bases comptent à toute étape.',
       ARRAY['Récite chaque sourate de l''étape de mémoire, sans erreur de mot',
             'Récite en respectant les voyelles et les lettres longues',
             'S''arrête aux fins de versets',
             'Garde les sourates déjà apprises'],
       '{"support": "mushaf"}'::jsonb,
       '{"enfant_6_9": {"prevue": 7, "limite": 9}, "enfant_10_13": {"prevue": 5, "limite": 6},
         "ado_14_17": {"prevue": 5, "limite": 6}, "adulte_18_plus": {"prevue": 3, "limite": 4}}'::jsonb,
       pg_catalog.jsonb_build_object(
         'enfant_6_9', pg_catalog.jsonb_build_object('principale', 'Le Coran : les sourates courtes, d''Al-Masad à Az-Zalzalah', 'secondaire', txt.apres_livre),
         'enfant_10_13', pg_catalog.jsonb_build_object('principale', 'Le Coran : les sourates courtes, d''Al-Masad à Az-Zalzalah', 'secondaire', txt.apres_livre),
         'ado_14_17', pg_catalog.jsonb_build_object('principale', 'Le Coran : les sourates courtes, d''Al-Masad à Az-Zalzalah', 'secondaire', txt.apres_livre),
         'adulte_18_plus', pg_catalog.jsonb_build_object('principale', 'Le Coran : les sourates courtes, d''Al-Masad à Az-Zalzalah', 'secondaire', txt.apres_livre)))
    ) AS e(ordre, code, nom, description, objectifs, plage, durees, matieres);
$function$;

-- Le niveau des bases : durees decidees le 14/10 (REGLAGES.md, tableau 1).
CREATE FUNCTION private.durees_niveau_bases()
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT '{"enfant_6_9": {"prevue": 37, "limite": 48}, "enfant_10_13": {"prevue": 28, "limite": 36},
           "ado_14_17": {"prevue": 24, "limite": 31}, "adulte_18_plus": {"prevue": 15, "limite": 20}}'::jsonb;
$function$;

-- Une version brouillon peut-elle recevoir le contenu des bases sans rien
-- retirer ? Oui si toutes ses lignes portent un code des bases, ou si une seule
-- ligne n'en porte pas et que BASES-1 manque (elle devient BASES-1).
CREATE FUNCTION private.version_bases_convertible(p_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH etrangeres AS (
    SELECT pg_catalog.count(*) AS n
      FROM public.programme_niveaux n
     WHERE n.version_id = p_version_id
       AND n.code_technique NOT IN (SELECT c.code FROM private.contenu_bases() c)
  )
  SELECT e.n = 0
         OR (e.n = 1 AND NOT EXISTS (SELECT 1 FROM public.programme_niveaux n
                                      WHERE n.version_id = p_version_id AND n.code_technique = 'BASES-1'))
    FROM etrangeres e;
$function$;

-- Ecrit le contenu des bases dans un brouillon : la ligne etrangere unique
-- devient BASES-1, chaque etape est mise a jour ou ajoutee, le niveau aussi.
CREATE FUNCTION private.remplir_version_bases(p_version_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_statut text;
  c record;
BEGIN
  SELECT statut INTO v_statut FROM public.programme_versions WHERE id = p_version_id FOR UPDATE;
  IF v_statut IS DISTINCT FROM 'brouillon' THEN
    RAISE EXCEPTION 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  END IF;
  IF NOT private.version_bases_convertible(p_version_id) THEN
    RAISE EXCEPTION 'version_non_convertible: des etapes etrangeres aux bases y figurent';
  END IF;

  UPDATE public.programme_niveaux n
     SET code_technique = 'BASES-1'
   WHERE n.version_id = p_version_id
     AND n.code_technique NOT IN (SELECT b.code FROM private.contenu_bases() b);

  FOR c IN SELECT * FROM private.contenu_bases() LOOP
    UPDATE public.programme_niveaux n
       SET nom_humain = c.nom, cycle = 'Les bases', cycle_code = 'bases', ordre = c.ordre,
           description = c.description, objectifs = c.objectifs, plage_support = c.plage,
           durees = c.durees, matieres = c.matieres
     WHERE n.version_id = p_version_id AND n.code_technique = c.code;
    IF NOT FOUND THEN
      INSERT INTO public.programme_niveaux
        (version_id, code_technique, nom_humain, cycle, cycle_code, ordre, description,
         objectifs, plage_support, durees, matieres)
      VALUES
        (p_version_id, c.code, c.nom, 'Les bases', 'bases', c.ordre, c.description,
         c.objectifs, c.plage, c.durees, c.matieres);
    END IF;
  END LOOP;

  INSERT INTO public.programme_cycles (version_id, code, nom_humain, ordre, durees)
  VALUES (p_version_id, 'bases', 'Les bases', 1, private.durees_niveau_bases())
  ON CONFLICT (version_id, code) DO UPDATE
    SET nom_humain = EXCLUDED.nom_humain, ordre = EXCLUDED.ordre, durees = EXCLUDED.durees;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Publication : coherence des reperes, archivage de la precedente
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.programme_socle_publication()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ecart text;
BEGIN
  IF NEW.statut = 'publiee' AND OLD.statut IS DISTINCT FROM 'publiee' THEN
    -- Pour chaque niveau de la version et chaque tranche active : somme des
    -- durees prevues des etapes = duree prevue du niveau ; somme des reperes =
    -- date limite du niveau.
    SELECT cy.nom_humain || ' (' || co.code || ')' INTO v_ecart
      FROM public.programme_cycles cy
     CROSS JOIN public.cohortes_age co
     WHERE cy.version_id = NEW.id AND co.actif
       AND (
         (cy.durees -> co.code ->> 'prevue') IS NULL
         OR (cy.durees -> co.code ->> 'limite') IS NULL
         OR (SELECT coalesce(pg_catalog.sum((n.durees -> co.code ->> 'prevue')::numeric), -1)
               FROM public.programme_niveaux n
              WHERE n.version_id = NEW.id AND n.cycle_code = cy.code)
            IS DISTINCT FROM (cy.durees -> co.code ->> 'prevue')::numeric
         OR (SELECT coalesce(pg_catalog.sum((n.durees -> co.code ->> 'limite')::numeric), -1)
               FROM public.programme_niveaux n
              WHERE n.version_id = NEW.id AND n.cycle_code = cy.code)
            IS DISTINCT FROM (cy.durees -> co.code ->> 'limite')::numeric
       )
     LIMIT 1;
    IF v_ecart IS NOT NULL THEN
      RAISE EXCEPTION 'programme_incoherent: %', v_ecart
        USING errcode = 'P0001',
              hint = 'La somme des reperes des etapes doit egaler la date limite du niveau, pour chaque tranche d''age.';
    END IF;
    -- Une seule version publiee : la precedente est archivee.
    UPDATE public.programme_versions
       SET statut = 'archivee'
     WHERE statut = 'publiee' AND id <> NEW.id;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER programme_versions_socle_publication
  BEFORE UPDATE OF statut ON public.programme_versions
  FOR EACH ROW EXECUTE FUNCTION private.programme_socle_publication();

CREATE UNIQUE INDEX programme_versions_une_publiee_uidx
  ON public.programme_versions ((true)) WHERE statut = 'publiee';

-- ---------------------------------------------------------------------------
-- 5. Les calculs de l'etape, chacun a un seul endroit
-- ---------------------------------------------------------------------------
-- L'etape publiee qui porte le meme code (identite stable) ; l'etape elle-meme
-- si sa version est publiee ; nulle sinon.
CREATE FUNCTION private.etape_publiee_equivalente(p_niveau_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT n2.id
    FROM public.programme_niveaux n1
    JOIN public.programme_niveaux n2 ON n2.code_technique = n1.code_technique
    JOIN public.programme_versions v ON v.id = n2.version_id AND v.statut = 'publiee'
   WHERE n1.id = p_niveau_id
   LIMIT 1;
$function$;

-- La premiere etape du niveau des bases, dans la version publiee.
CREATE FUNCTION private.etape_par_defaut()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT n.id
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee'
   WHERE n.cycle_code = 'bases'
   ORDER BY n.ordre
   LIMIT 1;
$function$;

-- La tranche d'age de l'eleve : son profil, sinon « adulte » dans une classe d'adultes.
CREATE FUNCTION private.cohorte_effective(p_student_id uuid, p_groupe_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT sp.cohorte FROM public.student_profiles sp WHERE sp.profile_id = p_student_id),
    (SELECT 'adulte_18_plus' FROM public.groupes g WHERE g.id = p_groupe_id AND g.type_public = 'adulte'));
$function$;

-- Date limite du niveau pour une entree a l'etape [p_niveau_id] le [p_entree] :
-- l'entree plus les reperes des etapes restantes (celle-ci comprise) du meme
-- niveau, pour la tranche. Une entree a l'etape 1 donne la date du niveau
-- (somme des reperes = date limite du niveau). Nulle si une valeur manque.
CREATE FUNCTION private.date_limite_depuis(p_niveau_id uuid, p_cohorte text, p_entree date)
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
           WHEN p_cohorte IS NULL OR p_entree IS NULL OR n.cycle_code IS NULL THEN NULL
           WHEN pg_catalog.bool_and((r.durees -> p_cohorte ->> 'limite') IS NOT NULL) THEN
             (p_entree + pg_catalog.make_interval(
                weeks => pg_catalog.sum((r.durees -> p_cohorte ->> 'limite')::int)::int))::date
         END
    FROM public.programme_niveaux n
    JOIN public.programme_niveaux r
      ON r.version_id = n.version_id AND r.cycle_code = n.cycle_code AND r.ordre >= n.ordre
   WHERE n.id = p_niveau_id
   GROUP BY n.cycle_code;
$function$;

-- La date limite d'un eleve, telle qu'elle vaut aujourd'hui : la date posee a
-- l'entree dans le niveau (ou, si la tranche manquait alors, recalculee avec la
-- tranche d'aujourd'hui), reculee de recul_jours (lot 2). Seul point de lecture.
CREATE FUNCTION private.date_limite_effective(p_student_id uuid)
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (coalesce(
            f.date_limite_niveau,
            private.date_limite_depuis(
              f.etape_entree_id,
              coalesce(f.cohorte, private.cohorte_effective(f.student_id, NULL)),
              f.entree_niveau_le))
          + f.recul_jours)::date
    FROM public.eleve_etape_en_cours f
   WHERE f.student_id = p_student_id;
$function$;

-- Pose l'etape d'un eleve s'il n'en a pas : sa derniere decision de niveau
-- publiee, sinon l'etape de sa classe (meme code, version publiee), sinon
-- l'etape 1 des bases. Ne remplace jamais un fait existant (l'etape est celle
-- de l'eleve, pas celle de la classe).
CREATE FUNCTION private.poser_etape_eleve(p_student_id uuid, p_groupe_id uuid, p_quand timestamptz)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_niveau uuid;
  v_quand timestamptz;
  v_origine text;
  v_cohorte text;
BEGIN
  IF p_student_id IS NULL
     OR EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = p_student_id) THEN
    RETURN;
  END IF;

  SELECT h.niveau_id, h.created_at INTO v_niveau, v_quand
    FROM public.progression_historique h
    JOIN public.programme_niveaux n ON n.id = h.niveau_id
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee'
   WHERE h.student_id = p_student_id
   ORDER BY h.created_at DESC
   LIMIT 1;
  IF v_niveau IS NOT NULL THEN
    v_origine := 'decision';
  ELSE
    SELECT private.etape_publiee_equivalente(g.programme_niveau_id) INTO v_niveau
      FROM public.groupes g WHERE g.id = p_groupe_id;
    v_niveau := coalesce(v_niveau, private.etape_par_defaut());
    v_quand := coalesce(p_quand, pg_catalog.now());
    v_origine := 'classe';
  END IF;
  IF v_niveau IS NULL THEN
    RETURN; -- aucun programme publie : rien n'est suppose
  END IF;

  v_cohorte := private.cohorte_effective(p_student_id, p_groupe_id);
  INSERT INTO public.eleve_etape_en_cours
    (student_id, niveau_id, etape_entree_id, cohorte, entree_etape_le, entree_niveau_le,
     date_limite_niveau, origine)
  VALUES
    (p_student_id, v_niveau, v_niveau, v_cohorte, v_quand::date, v_quand::date,
     private.date_limite_depuis(v_niveau, v_cohorte, v_quand::date), v_origine)
  ON CONFLICT (student_id) DO NOTHING;
END;
$function$;

-- Chaque classe non terminee sans etape recoit l'etape 1 des bases ; chaque
-- membre actif sans etape recoit la sienne, datee de son entree en classe.
CREATE FUNCTION private.rattacher_classes_et_eleves()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_defaut uuid := private.etape_par_defaut();
  m record;
  v_n integer := 0;
BEGIN
  IF v_defaut IS NULL THEN
    RETURN 0;
  END IF;
  UPDATE public.groupes SET programme_niveau_id = v_defaut
   WHERE ended_at IS NULL AND programme_niveau_id IS NULL;
  FOR m IN
    SELECT gm.student_id, gm.groupe_id, gm.joined_at
      FROM public.groupe_membres gm
      JOIN public.groupes g ON g.id = gm.groupe_id AND g.ended_at IS NULL
     WHERE gm.left_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f WHERE f.student_id = gm.student_id)
  LOOP
    PERFORM private.poser_etape_eleve(m.student_id, m.groupe_id, m.joined_at);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Les declencheurs : classe neuve, entree en classe, decision de la direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.socle_classe_neuve()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.programme_niveau_id IS NULL THEN
    NEW.programme_niveau_id := private.etape_par_defaut();
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupes_socle_etape_par_defaut
  BEFORE INSERT ON public.groupes
  FOR EACH ROW EXECUTE FUNCTION private.socle_classe_neuve();

CREATE FUNCTION private.socle_entree_en_classe()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.left_at IS NULL THEN
    PERFORM private.poser_etape_eleve(NEW.student_id, NEW.groupe_id, NEW.joined_at);
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupe_membres_socle_etape
  AFTER INSERT ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION private.socle_entree_en_classe();

-- Une decision de niveau publiee (diagnostic, promotion, reevaluation,
-- correction) devient l'etape en cours. Dans le meme niveau : la date limite ne
-- change pas, sauf diagnostic ou correction de placement (recalculee sur les
-- etapes restantes depuis l'entree dans le niveau). Nouveau niveau : nouvelle
-- entree, tranche d'aujourd'hui.
CREATE FUNCTION private.socle_decision_niveau()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cycle text;
  f public.eleve_etape_en_cours%ROWTYPE;
  v_cycle_actuel text;
  v_groupe uuid;
  v_cohorte text;
  v_jour date := NEW.created_at::date;
BEGIN
  SELECT n.cycle_code INTO v_cycle
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee'
   WHERE n.id = NEW.niveau_id;
  IF NOT FOUND THEN
    RETURN NEW; -- decision sur un brouillon : sans effet, comme avant
  END IF;

  SELECT m.groupe_id INTO v_groupe FROM public.groupe_membres m
   WHERE m.student_id = NEW.student_id AND m.left_at IS NULL LIMIT 1;
  v_cohorte := private.cohorte_effective(NEW.student_id, v_groupe);

  SELECT * INTO f FROM public.eleve_etape_en_cours WHERE student_id = NEW.student_id FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO public.eleve_etape_en_cours
      (student_id, niveau_id, etape_entree_id, cohorte, entree_etape_le, entree_niveau_le,
       date_limite_niveau, origine)
    VALUES
      (NEW.student_id, NEW.niveau_id, NEW.niveau_id, v_cohorte, v_jour, v_jour,
       private.date_limite_depuis(NEW.niveau_id, v_cohorte, v_jour), 'decision');
    RETURN NEW;
  END IF;

  SELECT n.cycle_code INTO v_cycle_actuel FROM public.programme_niveaux n WHERE n.id = f.niveau_id;
  IF v_cycle IS NOT NULL AND v_cycle = v_cycle_actuel THEN
    IF NEW.type_mouvement IN ('diagnostic_initial', 'correction') THEN
      UPDATE public.eleve_etape_en_cours
         SET niveau_id = NEW.niveau_id, etape_entree_id = NEW.niveau_id,
             entree_etape_le = greatest(v_jour, f.entree_niveau_le),
             date_limite_niveau = private.date_limite_depuis(
               NEW.niveau_id, coalesce(f.cohorte, v_cohorte), f.entree_niveau_le),
             origine = 'decision', maj_le = pg_catalog.now()
       WHERE student_id = NEW.student_id;
    ELSE
      UPDATE public.eleve_etape_en_cours
         SET niveau_id = NEW.niveau_id,
             entree_etape_le = greatest(v_jour, f.entree_niveau_le),
             origine = 'decision', maj_le = pg_catalog.now()
       WHERE student_id = NEW.student_id;
    END IF;
  ELSE
    UPDATE public.eleve_etape_en_cours
       SET niveau_id = NEW.niveau_id, etape_entree_id = NEW.niveau_id, cohorte = v_cohorte,
           entree_etape_le = v_jour, entree_niveau_le = v_jour,
           date_limite_niveau = private.date_limite_depuis(NEW.niveau_id, v_cohorte, v_jour),
           recul_jours = 0, origine = 'decision', maj_le = pg_catalog.now()
     WHERE student_id = NEW.student_id;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER progression_historique_socle_etape
  AFTER INSERT ON public.progression_historique
  FOR EACH ROW EXECUTE FUNCTION private.socle_decision_niveau();

-- ---------------------------------------------------------------------------
-- 7. private.etape_eleve lit le fait d'abord (meme signature, meme resultat)
-- ---------------------------------------------------------------------------
-- Avec un fait : l'etape de l'eleve dans sa version (publiee ou archivee),
-- duree prevue de l'etape pour sa tranche, date limite du NIVEAU en semaines et
-- en date (charte : la seule date ferme), depuis = entree dans l'etape.
-- Sans fait (aucun programme publie a son entree) : l'ancienne regle de C2,
-- gardee jusqu'au lot 10.
CREATE OR REPLACE FUNCTION private.etape_eleve(p_student_id uuid, p_groupe_id uuid)
RETURNS TABLE (
  niveau_id uuid,
  etape_nom text,
  etape_ordre int,
  cycle text,
  objectifs text[],
  cohorte text,
  duree_prevue_semaines int,
  date_limite_semaines int,
  depuis timestamptz,
  date_limite date
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  WITH f AS (
    SELECT * FROM public.eleve_etape_en_cours x WHERE x.student_id = p_student_id
  ),
  decision AS (
    SELECT h.niveau_id, h.created_at
      FROM public.progression_historique h
     WHERE h.student_id = p_student_id
     ORDER BY h.created_at DESC
     LIMIT 1
  ),
  choisie AS (
    SELECT CASE WHEN dv.statut = 'publiee' THEN d.niveau_id ELSE g.programme_niveau_id END AS niveau_id,
           CASE WHEN dv.statut = 'publiee' THEN d.created_at END AS depuis
      FROM public.groupes g
      LEFT JOIN decision d ON true
      LEFT JOIN public.programme_niveaux dn ON dn.id = d.niveau_id
      LEFT JOIN public.programme_versions dv ON dv.id = dn.version_id
     WHERE g.id = p_groupe_id
  )
  SELECT n.id,
         n.nom_humain,
         n.ordre,
         n.cycle,
         n.objectifs,
         c.coh,
         (n.durees -> c.coh ->> 'prevue')::int,
         (cy.durees -> c.coh ->> 'limite')::int,
         f.entree_etape_le::timestamptz,
         private.date_limite_effective(p_student_id)
    FROM f
    JOIN public.programme_niveaux n ON n.id = f.niveau_id
    LEFT JOIN public.programme_cycles cy ON cy.version_id = n.version_id AND cy.code = n.cycle_code
   CROSS JOIN LATERAL (
     SELECT coalesce(f.cohorte, private.cohorte_effective(p_student_id, p_groupe_id)) AS coh
   ) c
  UNION ALL
  SELECT n.id,
         n.nom_humain,
         n.ordre,
         n.cycle,
         n.objectifs,
         sp.cohorte,
         (n.durees -> sp.cohorte ->> 'prevue')::int,
         (n.durees -> sp.cohorte ->> 'limite')::int,
         ch.depuis,
         CASE WHEN ch.depuis IS NOT NULL AND (n.durees -> sp.cohorte ->> 'limite') IS NOT NULL
              THEN (ch.depuis + pg_catalog.make_interval(
                      weeks => (n.durees -> sp.cohorte ->> 'limite')::int))::date
         END
    FROM choisie ch
    JOIN public.programme_niveaux n ON n.id = ch.niveau_id
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee'
    LEFT JOIN public.student_profiles sp ON sp.profile_id = p_student_id
   WHERE NOT EXISTS (SELECT 1 FROM f);
$function$;

COMMENT ON FUNCTION private.etape_eleve(uuid, uuid) IS
  'SOCLE-PROGRAMME (12/11/2026) : l''etape en cours d''un eleve, lue dans le fait unique '
  'eleve_etape_en_cours (date limite = celle du niveau) ; sans fait, l''ancienne regle de '
  'CAHIER-C2 (retiree au lot 10). Appelee par etapes_eleves_classe, rythme_classe, '
  'suivi_pedagogique_eleve, lire_resultats_evaluations. Aucun droit direct.';

-- ---------------------------------------------------------------------------
-- 8. LA lecture unique de l'etape de l'eleve, pour tous les roles
-- ---------------------------------------------------------------------------
-- Garde (positive) : l'eleve lui-meme ; le titulaire de son propre profil eleve ;
-- le tuteur du foyer de l'eleve ; l'enseignant titulaire de sa classe active ou
-- l'enseignant effectif d'une seance de cette classe (fenetre de CAHIER-C1) ; la
-- direction. 42501 sinon. Rend NULL quand l'eleve n'a pas encore d'etape.
-- L'eleve lui-meme, si sa tranche s'arrete avant `programme.age_voit_date_limite`
-- (10 ans), ne recoit ni la date limite ni le rythme : son tuteur les recoit.
CREATE FUNCTION public.etape_eleve_lecture(p_eleve_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_groupe uuid;
  v_famille boolean;
  v_ecole boolean;
  f public.eleve_etape_en_cours%ROWTYPE;
  n public.programme_niveaux%ROWTYPE;
  v_cy public.programme_cycles%ROWTYPE;
  v_version public.programme_versions%ROWTYPE;
  v_coh text;
  v_age_voit int;
  v_masque boolean;
  v_date_limite date;
  v_chemin jsonb;
  v_sourates jsonb;
  v_page int;
BEGIN
  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL
   ORDER BY m.joined_at DESC, m.groupe_id
   LIMIT 1;

  v_famille := coalesce(
       (public.app_role() = 'student' AND p_eleve_id = v_user)
    OR (public.app_role() = 'guardian' AND p_eleve_id = v_user
        AND EXISTS (SELECT 1 FROM public.student_profiles sp
                     WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                       AND sp.deleted_at IS NULL))
    OR (public.app_role() = 'guardian'
        AND EXISTS (SELECT 1 FROM public.profiles p
                     WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                       AND p.household_id IS NOT NULL
                       AND p.household_id = public.app_household_id())), false);
  v_ecole := coalesce(
       public.app_role() = 'admin'
    OR (v_groupe IS NOT NULL AND private.cahier_c1_peut_lire_classe(v_groupe)), false);

  IF NOT coalesce(v_user IS NOT NULL AND p_eleve_id IS NOT NULL AND public.app_account_valid()
                  AND (v_famille OR v_ecole), false) THEN
    RAISE EXCEPTION 'etape de l''eleve refusee' USING errcode = '42501';
  END IF;

  SELECT * INTO f FROM public.eleve_etape_en_cours WHERE student_id = p_eleve_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT * INTO n FROM public.programme_niveaux WHERE id = f.niveau_id;
  SELECT * INTO v_version FROM public.programme_versions WHERE id = n.version_id;
  SELECT * INTO v_cy FROM public.programme_cycles
   WHERE version_id = n.version_id AND code = n.cycle_code;
  v_coh := coalesce(f.cohorte, private.cohorte_effective(p_eleve_id, v_groupe));

  SELECT coalesce((SELECT (c.value #>> '{}')::int FROM public.app_config c
                    WHERE c.key = 'programme.age_voit_date_limite'), 10)
    INTO v_age_voit;
  v_masque := coalesce(public.app_role() = 'student' AND p_eleve_id = v_user, false)
              AND (v_coh IS NULL
                   OR coalesce((SELECT a.age_max_inclus < v_age_voit FROM public.cohortes_age a
                                 WHERE a.code = v_coh), true));
  v_date_limite := private.date_limite_effective(p_eleve_id);

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'code', e.code_technique,
           'ordre', e.ordre,
           'nom', e.nom_humain,
           'objectifs', pg_catalog.to_jsonb(e.objectifs),
           'matiere_principale', e.matieres -> v_coh ->> 'principale',
           'matiere_secondaire', e.matieres -> v_coh ->> 'secondaire',
           'duree_prevue_semaines', (e.durees -> v_coh ->> 'prevue')::int,
           'repere_semaines', (e.durees -> v_coh ->> 'limite')::int,
           'statut', CASE WHEN e.ordre < n.ordre THEN 'franchie'
                          WHEN e.id = n.id THEN 'en_cours'
                          ELSE 'a_venir' END) ORDER BY e.ordre), '[]'::jsonb)
    INTO v_chemin
    FROM public.programme_niveaux e
   WHERE e.version_id = n.version_id
     AND ((n.cycle_code IS NOT NULL AND e.cycle_code = n.cycle_code)
          OR (n.cycle_code IS NULL AND e.id = n.id));

  SELECT pg_catalog.jsonb_build_object(
           'validees', pg_catalog.count(v.student_id)::int,
           'total', pg_catalog.count(*)::int,
           'liste', pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                      'ordre', b.ordre, 'numero', b.numero, 'nom', s.nom_translittere,
                      'nom_arabe', s.nom_arabe, 'validee', v.student_id IS NOT NULL)
                    ORDER BY b.ordre))
    INTO v_sourates
    FROM private.sourates_des_bases b
    JOIN public.sourate s ON s.numero = b.numero
    LEFT JOIN public.sourates_validees v ON v.student_id = p_eleve_id AND v.sourate_numero = b.numero;

  IF v_groupe IS NOT NULL THEN
    SELECT r.page::int INTO v_page FROM public.classe_position_reprise r WHERE r.groupe_id = v_groupe;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'eleve_id', p_eleve_id,
    'etape', pg_catalog.jsonb_build_object(
      'code', n.code_technique,
      'ordre', n.ordre,
      'nom', n.nom_humain,
      'objectifs', pg_catalog.to_jsonb(n.objectifs),
      'matiere_principale', n.matieres -> v_coh ->> 'principale',
      'matiere_secondaire', n.matieres -> v_coh ->> 'secondaire',
      'duree_prevue_semaines', (n.durees -> v_coh ->> 'prevue')::int,
      'repere_semaines', (n.durees -> v_coh ->> 'limite')::int,
      'entree_le', f.entree_etape_le,
      'semaines_ecoulees', CASE WHEN v_masque THEN NULL
                                ELSE pg_catalog.floor((pg_catalog.now()::date - f.entree_etape_le) / 7.0)::int END,
      'rythme', CASE WHEN v_masque THEN NULL
                     ELSE private.vitesse_eleve(f.entree_etape_le::timestamptz,
                                                (n.durees -> v_coh ->> 'prevue')::int,
                                                v_date_limite, pg_catalog.now()) END),
    'niveau', pg_catalog.jsonb_build_object(
      'code', n.cycle_code,
      'nom', coalesce(v_cy.nom_humain, n.cycle),
      'cohorte', v_coh,
      'duree_prevue_semaines', (v_cy.durees -> v_coh ->> 'prevue')::int,
      'date_limite_semaines', CASE WHEN v_masque THEN NULL ELSE (v_cy.durees -> v_coh ->> 'limite')::int END,
      'entree_le', f.entree_niveau_le,
      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_date_limite END,
      'date_limite_visible', NOT v_masque),
    'chemin', v_chemin,
    'sourates', v_sourates,
    'page_reprise', v_page,
    'version', pg_catalog.jsonb_build_object('numero', v_version.numero_version,
                                             'statut', v_version.statut));
END;
$function$;

COMMENT ON FUNCTION public.etape_eleve_lecture(uuid) IS
  'SOCLE-PROGRAMME (12/11/2026) : LA lecture de l''etape de l''eleve (etape en cours, chemin de '
  'son niveau pour sa tranche avec objectifs et matieres, dates d''entree, duree prevue, reperes, '
  'date limite du niveau, sourates des bases, page de reprise). Eleve, titulaire de son profil, '
  'tuteur du foyer, enseignant de sa classe (fenetre CAHIER-C1), direction. Date limite et rythme '
  'retenus pour l''eleve de moins de 10 ans qui lit pour lui-meme. 42501 sinon ; NULL sans etape.';

-- ---------------------------------------------------------------------------
-- 9. Les gestes existants suivent le nouveau contenu (signatures identiques)
-- ---------------------------------------------------------------------------
-- La copie d'une version emporte aussi le niveau, cycle_code et matieres.
CREATE OR REPLACE FUNCTION public.creer_version_programme(p_source_version_id uuid default null)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_numero int;
BEGIN
  -- Garde positive de production (0067, SEC-ROLE / F86), mot pour mot.
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    RAISE EXCEPTION 'creation de version de programme reservee a l''administration';
  END IF;

  IF p_source_version_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.programme_versions WHERE id = p_source_version_id
  ) THEN
    RAISE EXCEPTION 'version source introuvable';
  END IF;

  SELECT coalesce(max(numero_version), 0) + 1 INTO v_numero FROM public.programme_versions;

  INSERT INTO public.programme_versions (statut, numero_version, cree_par)
  VALUES ('brouillon', v_numero, auth.uid())
  RETURNING id INTO v_id;

  IF p_source_version_id IS NOT NULL THEN
    INSERT INTO public.programme_niveaux
      (version_id, code_technique, nom_humain, cycle, ordre, description,
       objectifs, plage_support, durees, cycle_code, matieres)
    SELECT v_id, code_technique, nom_humain, cycle, ordre, description,
           objectifs, plage_support, durees, cycle_code, matieres
    FROM public.programme_niveaux
    WHERE version_id = p_source_version_id;
    INSERT INTO public.programme_cycles (version_id, code, nom_humain, ordre, durees)
    SELECT v_id, code, nom_humain, ordre, durees
    FROM public.programme_cycles
    WHERE version_id = p_source_version_id;
  END IF;

  PERFORM public.log_sensitive_access(
    'programme_version_creee', 'programme_versions', v_id::text,
    jsonb_build_object('numero_version', v_numero, 'source_version_id', p_source_version_id)
  );

  RETURN v_id;
END;
$function$;

-- La proposition des bases d'un geste : desormais le contenu decide (reperes du
-- tableau 1 bis, matieres, niveau), et plus le decoupage x 1,3 de C2.
CREATE OR REPLACE FUNCTION public.preremplir_bases_programme(p_version_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_statut text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'modification du programme reservee a l''administration'
      USING errcode = '42501';
  END IF;

  SELECT statut INTO v_statut FROM public.programme_versions
   WHERE id = p_version_id FOR UPDATE;
  IF v_statut IS NULL THEN
    RAISE EXCEPTION 'version introuvable';
  END IF;
  IF v_statut <> 'brouillon' THEN
    RAISE EXCEPTION 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  END IF;
  IF EXISTS (SELECT 1 FROM public.programme_niveaux WHERE version_id = p_version_id) THEN
    RAISE EXCEPTION 'version_non_vide: la proposition ne remplit qu''une version sans etape';
  END IF;

  PERFORM private.remplir_version_bases(p_version_id);

  PERFORM public.log_sensitive_access(
    'programme_bases_preremplies', 'programme_versions', p_version_id::text,
    pg_catalog.jsonb_build_object('etapes', 4)
  );
  RETURN 4;
END;
$function$;

COMMENT ON FUNCTION public.preremplir_bases_programme(uuid) IS
  'SOCLE-PROGRAMME (12/11/2026) : insere dans un brouillon vide le contenu decide des bases '
  '(quatre etapes, objectifs en vigueur, matieres, durees prevues et reperes du tableau 1 bis, '
  'niveau et sa date limite). Remplace la proposition de CAHIER-C2.';

-- ---------------------------------------------------------------------------
-- 10. Le semis : completer et publier le programme, sans geste de la direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.semer_programme_bases(p_auteur uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_version uuid;
  v_numero int;
BEGIN
  -- Deja publie avec son niveau : rien a faire (rejouable).
  SELECT v.id INTO v_version
    FROM public.programme_versions v
   WHERE v.statut = 'publiee'
     AND EXISTS (SELECT 1 FROM public.programme_cycles c WHERE c.version_id = v.id AND c.code = 'bases');
  IF v_version IS NOT NULL THEN
    RETURN v_version;
  END IF;
  IF p_auteur IS NULL THEN
    RAISE EXCEPTION 'semer_programme_bases : un auteur (compte de la direction) est requis';
  END IF;

  -- Le brouillon le plus recent, s'il se laisse completer ; sinon une version neuve.
  SELECT v.id INTO v_version
    FROM public.programme_versions v
   WHERE v.statut = 'brouillon'
   ORDER BY v.numero_version DESC
   LIMIT 1;
  IF v_version IS NOT NULL AND NOT private.version_bases_convertible(v_version) THEN
    v_version := NULL;
  END IF;
  IF v_version IS NULL THEN
    SELECT coalesce(max(numero_version), 0) + 1 INTO v_numero FROM public.programme_versions;
    INSERT INTO public.programme_versions (statut, numero_version, cree_par)
    VALUES ('brouillon', v_numero, p_auteur)
    RETURNING id INTO v_version;
  END IF;

  PERFORM private.remplir_version_bases(v_version);

  UPDATE public.programme_versions
     SET statut = 'publiee', publiee_at = pg_catalog.now(), publiee_par = p_auteur
   WHERE id = v_version;
  RETURN v_version;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 11. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.contenu_bases() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.durees_niveau_bases() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.version_bases_convertible(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.remplir_version_bases(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.programme_socle_publication() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.etape_publiee_equivalente(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.etape_par_defaut() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.cohorte_effective(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.date_limite_depuis(uuid, text, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.date_limite_effective(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.poser_etape_eleve(uuid, uuid, timestamptz) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.rattacher_classes_et_eleves() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_classe_neuve() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_entree_en_classe() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_decision_niveau() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.semer_programme_bases(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.etape_eleve_lecture(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.etape_eleve_lecture(uuid) TO authenticated;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.eleve_etape_en_cours FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION public.etape_eleve_lecture(uuid) FROM agent_ro';
    EXECUTE 'GRANT SELECT ON public.programme_cycles TO agent_ro';
  END IF;
END
$agent$;

-- ---------------------------------------------------------------------------
-- 12. Installation : semer, publier, rattacher les classes et les eleves
-- ---------------------------------------------------------------------------
DO $semis$
DECLARE
  v_auteur uuid;
  v_version uuid;
  v_eleves integer;
BEGIN
  SELECT v.cree_par INTO v_auteur
    FROM public.programme_versions v
   WHERE v.statut = 'brouillon'
   ORDER BY v.numero_version DESC LIMIT 1;
  IF v_auteur IS NULL THEN
    SELECT p.id INTO v_auteur
      FROM public.profiles p
     WHERE p.role = 'admin' AND p.deleted_at IS NULL
     ORDER BY p.created_at
     LIMIT 1;
  END IF;
  IF v_auteur IS NULL
     AND NOT EXISTS (SELECT 1 FROM public.programme_versions WHERE statut = 'publiee') THEN
    RAISE NOTICE 'SOCLE-PROGRAMME : aucun compte de la direction, programme non seme (base nue)';
    RETURN;
  END IF;
  v_version := private.semer_programme_bases(v_auteur);
  v_eleves := private.rattacher_classes_et_eleves();
  RAISE NOTICE 'SOCLE-PROGRAMME : version publiee %, % eleve(s) rattache(s)', v_version, v_eleves;
END
$semis$;

-- ---------------------------------------------------------------------------
-- 13. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.eleve_etape_en_cours'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'public.programme_cycles'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : RLS absente sur une table neuve';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.eleve_etape_en_cours', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.eleve_etape_en_cours', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.programme_cycles', 'INSERT')
     OR pg_catalog.has_table_privilege('anon', 'public.programme_cycles', 'SELECT') THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : acces direct ouvert sur une table neuve';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.etape_eleve_lecture(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.etape_eleve_lecture(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.semer_programme_bases(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.poser_etape_eleve(uuid, uuid, timestamptz)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.date_limite_effective(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.creer_version_programme(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.preremplir_bases_programme(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.creer_version_programme(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : droits des fonctions incorrects';
  END IF;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.creer_version_programme(uuid)'::pg_catalog.regprocedure),
       'coalesce(public.app_role() = ''admin'' and public.app_account_valid(), false)') = 0 THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : creer_version_programme sans la garde positive';
  END IF;
  -- Les reperes du contenu decide font exactement la date du niveau, tranche par tranche.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_each(private.durees_niveau_bases()) t(coh, v)
     WHERE (SELECT pg_catalog.sum((c.durees -> t.coh ->> 'limite')::int) FROM private.contenu_bases() c)
           <> (t.v ->> 'limite')::int
        OR (SELECT pg_catalog.sum((c.durees -> t.coh ->> 'prevue')::int) FROM private.contenu_bases() c)
           <> (t.v ->> 'prevue')::int) THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : la somme des reperes ne fait pas la date du niveau';
  END IF;
END
$postflight$;

COMMIT;
