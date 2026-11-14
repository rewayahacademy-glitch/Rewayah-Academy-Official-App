-- SOCLE-PROGRAMME (lot 1 de la charte pedagogique, 12/11/2026).
-- Plan : docs/current/pedagogie/PLAN-DE-CONSTRUCTION.md, « Lot 1 » ; valeurs :
-- docs/current/pedagogie/REGLAGES.md, tableaux 1 et 1 bis ; bilan du lot :
-- docs/current/pedagogie/lots/LOT-1-SOCLE-PROGRAMME.md.
--
-- A COLLER EN UNE SEULE FOIS dans l'editeur SQL, de la premiere a la derniere
-- ligne. Ce fichier n'est PAS rejouable (le preflight refuse une seconde
-- installation) et ne porte ni BEGIN ni COMMIT : ne jamais le decouper, ne
-- jamais en rejouer un morceau.
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
--      matiere principale et matiere secondaire par tranche d'age, et par
--      tranche une duree prevue et une DATE LIMITE D'ETAPE en semaines
--      (`durees[tranche]` = {prevue, limite}, tableau 1 bis ; decision du
--      directeur du 14/10, correction de l'architecte du 12/11 : la date limite
--      est par etape). La somme des etapes egale le niveau (37/28/24/15 prevues,
--      48/36/31/20 de date limite) ; la publication le verifie en base.
--   2. Publier une version archive la precedente ; un index interdit deux
--      versions publiees. Regle 4 de programme-rewayah (directeur) : une version
--      publiee ne se modifie plus et l'eleve finit son etape dans sa version ;
--      la publication ne deplace donc personne. Le changement de version se fait
--      au passage d'etape (etape de meme code dans la version publiee courante,
--      sinon refus `programme_code_absent`).
--   3. Le fait unique « etape en cours » par eleve (`eleve_etape_en_cours`),
--      pose seul a l'entree en classe, une fois une version publiee (un eleve
--      debutant entre a l'etape 1 ; jamais « l'etape de la classe ») ; les
--      gestes existants de la direction (decider_placement,
--      progression_promouvoir) le posent ou le corrigent par un declencheur.
--      Une classe NEUVE recoit seule l'etape 1 des bases ; les classes et les
--      eleves DEJA presents ne sont pas touches a l'installation.
--   4. `private.etape_eleve` lit ce fait d'abord (meme signature) : toutes ses
--      lectures rendent la meme etape. `public.etape_eleve_lecture` est LA
--      lecture unique de l'etape de l'eleve, pour tous les roles.
--   5. La date limite d'une etape part de l'entree de l'eleve dans l'etape ;
--      la fin du niveau (somme des etapes restantes) n'est qu'un horizon. Point
--      d'accroche du lot 2 (fermetures, pauses) : la colonne `recul_jours`, lue
--      a un seul endroit (`private.dates_etape`).
--
-- A l'installation, ce fichier ne PUBLIE rien, ne pose aucun niveau sur une
-- classe et ne cree aucun fait d'eleve (decision de l'architecte, 13/11) :
-- publier est un geste de la direction, et un eleve finit son etape dans sa
-- version. Il complete seulement le brouillon le plus recent quand celui-ci est
-- VIDE de contenu (aucun objectif, aucune duree : la ligne vide de production) ;
-- un brouillon deja rempli par la direction n'est jamais touche. Les gestes qui
-- suivent sont ceux de la direction : publier la version (ecran Programmes),
-- placer les eleves deja en cours (ecran Diagnostics).


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
  -- La lecture unique ecarte les sourates retirees : CORRIGER-SOURATE (20261123820000) doit etre installee avant.
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns k
                  WHERE k.table_schema = 'public' AND k.table_name = 'sourates_validees'
                    AND k.column_name = 'retiree_le') THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : CORRIGER-SOURATE (20261123820000) absent (colonne retiree_le)';
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
  'semaines ; prevue = duree prevue de l''etape, limite = date limite de l''etape, comptee '
  'depuis l''entree de l''eleve dans l''etape (REGLAGES.md, tableau 1 bis ; decision du 14/10).';

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
  '({prevue, limite}). La somme des durees et des dates limites de ses etapes egale ces valeurs '
  '(controle a la publication). Aucune ecriture directe.';

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
  cohorte text REFERENCES public.cohortes_age(code),
  entree_etape_le date NOT NULL,
  entree_niveau_le date NOT NULL,
  recul_jours int NOT NULL DEFAULT 0 CHECK (recul_jours >= 0),
  origine text NOT NULL CHECK (origine IN ('classe', 'decision')),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CHECK (entree_etape_le >= entree_niveau_le)
);

COMMENT ON TABLE public.eleve_etape_en_cours IS
  'SOCLE-PROGRAMME (12/11/2026, arbitrage n. 1) : UN fait par eleve. niveau_id = son etape, '
  'dans SA version (il finit son etape dans sa version) ; entree_etape_le = depart de la date '
  'limite de l''etape ; cohorte = tranche figee a l''entree dans le niveau (un anniversaire ne '
  'change pas la date limite en cours) ; recul_jours = recul pour fermetures et pauses (lot 2, '
  '0 aujourd''hui). '
  'Ecrit par les seuls declencheurs et fonctions de ce lot. Aucun acces direct.';
COMMENT ON COLUMN public.eleve_etape_en_cours.recul_jours IS
  'SOCLE-PROGRAMME : point d''accroche du lot 2 (CALENDRIER-ET-PAUSES). Jours de recul de la '
  'date limite pour fermetures et pauses accordees ; lu par private.dates_etape seul.';

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
-- Durees : REGLAGES.md tableau 1 bis, {prevue, limite} de l'etape. Matieres :
-- charte 3.1 et EVALUATIONS.md 4.1 (6-9 ans : le livre seul jusqu'a la chadda ;
-- 10 ans et plus : Al-Fatiha des la premiere semaine, puis le meme ordre ; le
-- livre valide, le Coran devient la matiere principale).
-- Sources, case par case (.claude/skills/programme-rewayah/SKILL.md) :
--   6-9 ans, etapes 1 et 2 : aucune matiere secondaire (ligne 46 : « le livre
--   seul jusqu'a la chadda ») ; etape 3 : la suite de la ligne 46 (Al-Fatiha,
--   An-Nas, Al-Falaq, Al-Ikhlas, paroles de la priere et ablutions, invocations) ;
--   10 ans et plus, etapes 1 a 3 : ligne 47 (Al-Fatiha des la premiere semaine)
--   puis « le meme ordre » (EVALUATIONS.md 4.1, ligne 138) ;
--   etape 4, 10 ans et plus : ligne 48 (revision de la lecture, invocations,
--   adab), precedee des paroles de la priere et des ablutions tant qu'elles ne
--   sont pas confirmees (exigees a l'examen, EVALUATIONS.md 4.6) ;
--   etape 4, 6-9 ans : la suite de la ligne 46 (An-Nas, Al-Falaq, Al-Ikhlas
--   « environ 2 semaines chacune », puis les paroles de la priere et les
--   ablutions, puis les autres invocations), que l'enfant n'a pas finie a
--   l'etape 3 (Al-Fatiha 3 semaines + 3 x 2 semaines > 8 semaines de l'etape
--   3), avec la ligne 48 (revision de la lecture, adab).
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
      'Les paroles de la prière et les ablutions tant qu''elles ne sont pas confirmées, puis la révision de la lecture, les invocations et l''adab'::text AS apres_livre,
      'La suite des sourates commencées (An-Nâs, Al-Falaq, Al-Ikhlâs), puis les paroles de la prière et les ablutions, puis les invocations ; avec la révision de la lecture et l''adab'::text AS apres_livre_enfant
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
         'enfant_6_9', pg_catalog.jsonb_build_object('principale', 'Le Coran : les sourates courtes, d''Al-Masad à Az-Zalzalah', 'secondaire', txt.apres_livre_enfant),
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

-- L'etape qui porte le meme code stable que [p_niveau_id] dans la version
-- [p_version_id] (identite stable entre les versions) ; nulle si ce code n'y
-- existe pas. Appelee a la publication d'une version.
CREATE FUNCTION private.etape_publiee_equivalente(p_niveau_id uuid, p_version_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT n2.id
    FROM public.programme_niveaux n1
    JOIN public.programme_niveaux n2
      ON n2.code_technique = n1.code_technique AND n2.version_id = p_version_id
   WHERE n1.id = p_niveau_id
   LIMIT 1;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Publication : coherence des durees, archivage de la precedente
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
    -- Une version publiee porte le niveau des bases complet (ses quatre etapes,
    -- son niveau et ses durees), et aucune etape hors d'un niveau.
    IF NOT EXISTS (SELECT 1 FROM public.programme_cycles cy
                    WHERE cy.version_id = NEW.id AND cy.code = 'bases')
       OR (SELECT pg_catalog.count(*) FROM public.programme_niveaux n
            WHERE n.version_id = NEW.id AND n.cycle_code = 'bases')
          < (SELECT pg_catalog.count(*) FROM private.contenu_bases())
       OR EXISTS (SELECT 1 FROM public.programme_niveaux n
                   WHERE n.version_id = NEW.id AND n.cycle_code IS NULL) THEN
      RAISE EXCEPTION 'programme_sans_bases: version %', NEW.numero_version
        USING errcode = 'P0001',
              hint = 'Une version publiee doit porter le niveau des bases complet, sans etape hors d''un niveau : partez de la version publiee ou du preremplissage des bases.';
    END IF;
    -- Pour chaque niveau de la version et chaque tranche active : somme des
    -- durees prevues des etapes = duree prevue du niveau ; somme des dates
    -- limites des etapes = date limite du niveau.
    SELECT cy.nom_humain || ', ' || co.nom_humain INTO v_ecart
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
              hint = 'La somme des durees et des dates limites des etapes doit egaler celles du niveau, pour chaque tranche d''age.';
    END IF;
    -- Regle 4 de programme-rewayah : la publication ne deplace ni classe ni
    -- eleve ; ils finissent leur etape dans leur version (voir
    -- `etapes_sur_ancienne_version` pour le compte, a l'usage de la direction).
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

-- Les dates d'un eleve, telles qu'elles valent aujourd'hui : la date limite de
-- son etape (entree dans l'etape + date limite de l'etape pour sa tranche) et
-- l'horizon du niveau (entree dans l'etape + dates limites de cette etape et des
-- suivantes du meme niveau), toutes deux reculees de recul_jours (lot 2).
-- Seul point de calcul. Nulles si une valeur manque (jamais supposees).
CREATE FUNCTION private.dates_etape(p_student_id uuid)
RETURNS TABLE (date_limite date, date_limite_semaines int, horizon date)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH f AS (
    SELECT x.*, n.version_id, n.cycle_code, n.ordre, n.durees,
           coalesce(x.cohorte, private.cohorte_effective(x.student_id, NULL)) AS coh
      FROM public.eleve_etape_en_cours x
      JOIN public.programme_niveaux n ON n.id = x.niveau_id
     WHERE x.student_id = p_student_id
  )
  SELECT ((f.entree_etape_le + f.recul_jours)
            + pg_catalog.make_interval(weeks => (f.durees -> f.coh ->> 'limite')::int))::date,
         (f.durees -> f.coh ->> 'limite')::int,
         (SELECT CASE WHEN f.cycle_code IS NOT NULL
                       AND pg_catalog.bool_and((r.durees -> f.coh ->> 'limite') IS NOT NULL)
                      THEN ((f.entree_etape_le + f.recul_jours)
                              + pg_catalog.make_interval(
                                  weeks => pg_catalog.sum((r.durees -> f.coh ->> 'limite')::int)::int))::date END
            FROM public.programme_niveaux r
           WHERE r.version_id = f.version_id AND r.cycle_code = f.cycle_code AND r.ordre >= f.ordre)
    FROM f;
$function$;

-- L'eleve voit-il ses dates ? Vrai si sa tranche est connue et que son age
-- maximum atteint `programme.age_voit_date_limite` (10), ou pour une tranche
-- d'adultes ; faux si la tranche est inconnue. Independant de qui lit.
CREATE FUNCTION private.eleve_voit_dates(p_cohorte text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_cohorte IS NOT NULL
         AND coalesce((SELECT a.age_max_inclus IS NULL
                              OR a.age_max_inclus >= coalesce(
                                   (SELECT (c.value #>> '{}')::int FROM public.app_config c
                                     WHERE c.key = 'programme.age_voit_date_limite'), 10)
                         FROM public.cohortes_age a WHERE a.code = p_cohorte), false);
$function$;

-- Faut-il retenir les dates pour cet appel ? Seulement quand l'eleve lit pour
-- lui-meme (role eleve) et ne voit pas ses dates. Une seule regle, appelee par
-- etape_eleve_lecture et suivi_pedagogique_eleve.
CREATE FUNCTION private.dates_retenues(p_student_id uuid, p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(public.app_role() = 'student' AND p_student_id = auth.uid(), false)
         AND NOT private.eleve_voit_dates(coalesce(
               (SELECT f.cohorte FROM public.eleve_etape_en_cours f WHERE f.student_id = p_student_id),
               private.cohorte_effective(p_student_id, p_groupe_id)));
$function$;

-- Pose l'etape d'un eleve s'il n'en a pas : sa derniere decision de niveau
-- publiee ; sinon, s'il est debutant (niveau declare vide, « debut_lettres » ou
-- « lettres_avec_aide »), l'etape 1 des bases, datee de son entree en classe.
-- Jamais « l'etape de la classe » (correction de l'architecte, 12/11) ; un eleve
-- qui declare deja lire attend l'entretien de lecture : la decision de la
-- direction (decider_placement) pose alors son etape. Ne remplace jamais un
-- fait existant.
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
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut IN ('publiee', 'archivee')
   WHERE h.student_id = p_student_id
   ORDER BY h.created_at DESC
   LIMIT 1;
  IF v_niveau IS NOT NULL THEN
    v_niveau := coalesce(private.etape_publiee_equivalente(
      v_niveau, (SELECT v.id FROM public.programme_versions v WHERE v.statut = 'publiee')), v_niveau);
    v_origine := 'decision';
  ELSIF coalesce((SELECT sp.niveau_declare IS NULL OR sp.niveau_declare IN ('debut_lettres', 'lettres_avec_aide')
                    FROM public.student_profiles sp WHERE sp.profile_id = p_student_id), true) THEN
    v_niveau := private.etape_par_defaut();
    v_quand := coalesce(p_quand, pg_catalog.now());
    v_origine := 'classe';
  END IF;
  IF v_niveau IS NULL THEN
    RETURN; -- aucun programme publie, ou eleve qui attend son entretien de lecture
  END IF;

  v_cohorte := private.cohorte_effective(p_student_id, p_groupe_id);
  INSERT INTO public.eleve_etape_en_cours
    (student_id, niveau_id, cohorte, entree_etape_le, entree_niveau_le, origine)
  VALUES
    (p_student_id, v_niveau, v_cohorte, v_quand::date, v_quand::date, v_origine)
  ON CONFLICT (student_id) DO NOTHING;
END;
$function$;

-- OUTIL DE RATTACHEMENT, jamais appele a l'installation (decision de
-- l'architecte, 13/11) : appele a la main ou par les scenarios, il donne a chaque
-- classe non terminee sans etape l'etape 1 des bases, et a chaque membre actif
-- sans etape la sienne, datee du JOUR DE L'APPEL (un changement vaut pour la
-- suite, jamais pour le passe). Un eleve qui entre en classe ensuite garde sa
-- date d'entree (declencheur d'entree en classe).
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
    PERFORM private.poser_etape_eleve(m.student_id, m.groupe_id, pg_catalog.now());
    IF EXISTS (SELECT 1 FROM public.eleve_etape_en_cours f WHERE f.student_id = m.student_id) THEN
      v_n := v_n + 1;
    END IF;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Les declencheurs : classe neuve, entree en classe, decision de la direction
-- ---------------------------------------------------------------------------
-- Classe neuve : l'etape 1 des bases. Etape d'une classe changee : l'etape de
-- meme code dans la version publiee courante (passage d'etape de la classe) ;
-- un code absent refuse le changement. Une etape de brouillon n'est jamais posee.
CREATE FUNCTION private.socle_classe_neuve()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cible uuid;
  v_code text;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.programme_niveau_id IS NULL THEN
    NEW.programme_niveau_id := private.etape_par_defaut();
  ELSIF NEW.programme_niveau_id IS NOT NULL
        AND (TG_OP = 'INSERT' OR NEW.programme_niveau_id IS DISTINCT FROM OLD.programme_niveau_id) THEN
    v_cible := private.etape_publiee_equivalente(
      NEW.programme_niveau_id, (SELECT v.id FROM public.programme_versions v WHERE v.statut = 'publiee'));
    IF v_cible IS NULL
       AND EXISTS (SELECT 1 FROM public.programme_versions v WHERE v.statut = 'publiee') THEN
      SELECT n.code_technique INTO v_code FROM public.programme_niveaux n WHERE n.id = NEW.programme_niveau_id;
      RAISE EXCEPTION 'programme_code_absent: %', v_code
        USING errcode = 'P0001',
              hint = 'Cette etape n''existe plus dans la version publiee du programme.';
    END IF;
    NEW.programme_niveau_id := coalesce(v_cible, NEW.programme_niveau_id);
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupes_socle_etape_par_defaut
  BEFORE INSERT OR UPDATE OF programme_niveau_id ON public.groupes
  FOR EACH ROW EXECUTE FUNCTION private.socle_classe_neuve();

-- Entree en classe : pose l'etape s'il n'y en a pas. Retour en classe apres une
-- sortie (aucune adhesion active depuis au moins un jour) : le fait est garde
-- (rien de valide n'est perdu), la date d'entree dans l'etape devient le jour du
-- retour, pour que le temps passe hors de toute classe ne compte pas. Un
-- transfert (sortie et entree le meme jour) ne change rien.
CREATE FUNCTION private.socle_entree_en_classe()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_sortie timestamptz;
BEGIN
  IF NEW.left_at IS NOT NULL THEN
    RETURN NEW;
  END IF;
  IF EXISTS (SELECT 1 FROM public.eleve_etape_en_cours WHERE student_id = NEW.student_id) THEN
    SELECT pg_catalog.max(m.left_at) INTO v_sortie
      FROM public.groupe_membres m
     WHERE m.student_id = NEW.student_id AND m.id <> NEW.id AND m.left_at IS NOT NULL;
    IF v_sortie IS NOT NULL AND NEW.joined_at - v_sortie >= interval '1 day' THEN
      UPDATE public.eleve_etape_en_cours
         SET entree_etape_le = greatest(NEW.joined_at::date, entree_etape_le),
             maj_le = pg_catalog.now()
       WHERE student_id = NEW.student_id;
    END IF;
  ELSE
    PERFORM private.poser_etape_eleve(NEW.student_id, NEW.groupe_id, NEW.joined_at);
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupe_membres_socle_etape
  AFTER INSERT ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION private.socle_entree_en_classe();

-- Une decision de niveau publiee (diagnostic, promotion, reevaluation,
-- correction) devient l'etape en cours, datee du jour de la decision : la date
-- limite de la nouvelle etape part de la. Nouveau niveau : nouvelle entree dans
-- le niveau, tranche d'aujourd'hui.
CREATE FUNCTION private.socle_decision_niveau()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cycle text;
  v_statut text;
  v_code text;
  v_cible uuid;
  f public.eleve_etape_en_cours%ROWTYPE;
  v_cycle_actuel text;
  v_groupe uuid;
  v_cohorte text;
  v_jour date := NEW.created_at::date;
BEGIN
  SELECT n.cycle_code, v.statut, n.code_technique INTO v_cycle, v_statut, v_code
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id
   WHERE n.id = NEW.niveau_id;
  IF v_statut IS NULL OR v_statut NOT IN ('publiee', 'archivee') THEN
    RETURN NEW; -- decision sur un brouillon : sans effet, comme avant
  END IF;
  -- Passage d'etape : l'eleve entre dans l'etape de meme code de la version
  -- publiee courante ; un code absent refuse le passage (jamais en silence).
  v_cible := private.etape_publiee_equivalente(
    NEW.niveau_id, (SELECT v.id FROM public.programme_versions v WHERE v.statut = 'publiee'));
  IF v_cible IS NULL THEN
    RAISE EXCEPTION 'programme_code_absent: %', v_code
      USING errcode = 'P0001',
            hint = 'Cette etape n''existe plus dans la version publiee du programme : choisissez une etape de la version publiee.';
  END IF;
  SELECT n.cycle_code INTO v_cycle FROM public.programme_niveaux n WHERE n.id = v_cible;

  SELECT m.groupe_id INTO v_groupe FROM public.groupe_membres m
   WHERE m.student_id = NEW.student_id AND m.left_at IS NULL LIMIT 1;
  v_cohorte := private.cohorte_effective(NEW.student_id, v_groupe);

  SELECT * INTO f FROM public.eleve_etape_en_cours WHERE student_id = NEW.student_id FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO public.eleve_etape_en_cours
      (student_id, niveau_id, cohorte, entree_etape_le, entree_niveau_le, origine)
    VALUES
      (NEW.student_id, v_cible, v_cohorte, v_jour, v_jour, 'decision');
    RETURN NEW;
  END IF;

  SELECT n.cycle_code INTO v_cycle_actuel FROM public.programme_niveaux n WHERE n.id = f.niveau_id;
  -- Reevaluation ou certification sur l'etape EN COURS (meme code) : rien ne
  -- change, ni l'etape, ni la date d'entree, ni la date limite.
  IF EXISTS (SELECT 1 FROM public.programme_niveaux a
              WHERE a.id = f.niveau_id AND a.code_technique = v_code) THEN
    RETURN NEW;
  END IF;
  IF v_cycle IS NOT NULL AND v_cycle = v_cycle_actuel THEN
    UPDATE public.eleve_etape_en_cours
       SET niveau_id = v_cible,
           entree_etape_le = greatest(v_jour, f.entree_niveau_le),
           origine = 'decision', maj_le = pg_catalog.now()
     WHERE student_id = NEW.student_id;
  ELSE
    UPDATE public.eleve_etape_en_cours
       SET niveau_id = v_cible, cohorte = v_cohorte,
           entree_etape_le = v_jour, entree_niveau_le = v_jour,
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
-- duree prevue et date limite de l'etape pour sa tranche (en semaines, et en
-- date depuis l'entree dans l'etape), depuis = entree dans l'etape.
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
    SELECT CASE WHEN dv.statut IN ('publiee', 'archivee') THEN d.niveau_id ELSE g.programme_niveau_id END AS niveau_id,
           CASE WHEN dv.statut IN ('publiee', 'archivee') THEN d.created_at END AS depuis
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
         (n.durees -> c.coh ->> 'limite')::int,
         f.entree_etape_le::timestamptz,
         (SELECT d.date_limite FROM private.dates_etape(p_student_id) d)
    FROM f
    JOIN public.programme_niveaux n ON n.id = f.niveau_id
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
    JOIN public.programme_versions v ON v.id = n.version_id AND v.statut IN ('publiee', 'archivee')
    LEFT JOIN public.student_profiles sp ON sp.profile_id = p_student_id
   WHERE NOT EXISTS (SELECT 1 FROM f)
     -- Des qu'une version est publiee, un eleve sans fait n'a pas d'etape (il
     -- attend l'entretien de lecture) : jamais « l'etape de la classe ».
     AND NOT EXISTS (SELECT 1 FROM public.programme_versions pv WHERE pv.statut = 'publiee');
$function$;

COMMENT ON FUNCTION private.etape_eleve(uuid, uuid) IS
  'SOCLE-PROGRAMME (12/11/2026) : l''etape en cours d''un eleve, lue dans le fait unique '
  'eleve_etape_en_cours (date limite de l''etape depuis l''entree dans l''etape) ; sans fait, l''ancienne regle de '
  'CAHIER-C2 (retiree au lot 10). Appelee par etapes_eleves_classe, rythme_classe, '
  'suivi_pedagogique_eleve, lire_resultats_evaluations. Aucun droit direct.';

-- ---------------------------------------------------------------------------
-- 8. LA lecture unique de l'etape de l'eleve, pour tous les roles
-- ---------------------------------------------------------------------------
-- Garde (positive) : l'eleve lui-meme ; le titulaire de son propre profil eleve ;
-- le tuteur du foyer de l'eleve ; l'enseignant titulaire de sa classe active ou
-- l'enseignant effectif d'une seance de cette classe (garde partagee de
-- CAHIER-C1 : le remplacant devient enseignant effectif a l'acceptation, et lit
-- jusqu'a 24 heures apres la fin prevue de la seance) ; la direction. 42501 sinon.
-- Rend NULL sans etape ni classe ; {"attente": "entretien_de_lecture"} pour un
-- eleve en classe qui a declare savoir lire et attend la decision de la direction,
-- seulement quand une version est publiee (sans version publiee, rien n'attend).
-- `eleve_voit_dates` (independant de l'appelant) : vrai si la tranche de l'eleve
-- est connue et que son age maximum atteint `programme.age_voit_date_limite` (10),
-- ou si c'est une tranche d'adultes ; faux si la tranche est inconnue.
-- L'eleve lui-meme, quand `eleve_voit_dates` est faux, ne recoit aucun nombre de
-- semaines, ni date limite, ni horizon, ni rythme : son tuteur les recoit.
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
  v_voit boolean;
  v_masque boolean;
  v_dates record;
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
    IF v_groupe IS NOT NULL
       AND EXISTS (SELECT 1 FROM public.programme_versions pv WHERE pv.statut = 'publiee')
       AND EXISTS (SELECT 1 FROM public.student_profiles sp
                    WHERE sp.profile_id = p_eleve_id
                      AND sp.niveau_declare IS NOT NULL
                      AND sp.niveau_declare NOT IN ('debut_lettres', 'lettres_avec_aide')) THEN
      RETURN pg_catalog.jsonb_build_object('eleve_id', p_eleve_id, 'attente', 'entretien_de_lecture');
    END IF;
    RETURN NULL;
  END IF;
  SELECT * INTO n FROM public.programme_niveaux WHERE id = f.niveau_id;
  SELECT * INTO v_version FROM public.programme_versions WHERE id = n.version_id;
  SELECT * INTO v_cy FROM public.programme_cycles
   WHERE version_id = n.version_id AND code = n.cycle_code;
  v_coh := coalesce(f.cohorte, private.cohorte_effective(p_eleve_id, v_groupe));

  -- Tranche connue et age maximum au seuil ou au-dela, ou tranche d'adultes
  -- (age maximum nul) ; tranche inconnue : faux.
  v_voit := private.eleve_voit_dates(v_coh);
  v_masque := private.dates_retenues(p_eleve_id, v_groupe);
  SELECT * INTO v_dates FROM private.dates_etape(p_eleve_id);

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'code', e.code_technique,
           'ordre', e.ordre,
           'nom', e.nom_humain,
           'objectifs', pg_catalog.to_jsonb(e.objectifs),
           'matiere_principale', e.matieres -> v_coh ->> 'principale',
           'matiere_secondaire', e.matieres -> v_coh ->> 'secondaire',
           'duree_prevue_semaines', CASE WHEN v_masque THEN NULL ELSE (e.durees -> v_coh ->> 'prevue')::int END,
           'date_limite_semaines', CASE WHEN v_masque THEN NULL ELSE (e.durees -> v_coh ->> 'limite')::int END,
           'statut', CASE WHEN e.ordre < n.ordre THEN 'precedente'
                          WHEN e.id = n.id THEN 'en_cours'
                          ELSE 'a_venir' END) ORDER BY e.ordre), '[]'::jsonb)
    INTO v_chemin
    FROM public.programme_niveaux e
   WHERE (n.cycle_code IS NULL AND e.id = n.id)
      -- Etapes passees et etape en cours : la version de l'eleve.
      OR (n.cycle_code IS NOT NULL AND e.version_id = n.version_id
          AND e.cycle_code = n.cycle_code AND e.ordre <= n.ordre)
      -- Etapes a venir : la version publiee courante (celle ou il entrera).
      OR (n.cycle_code IS NOT NULL AND e.cycle_code = n.cycle_code AND e.ordre > n.ordre
          AND e.version_id = coalesce(
                (SELECT v.id FROM public.programme_versions v WHERE v.statut = 'publiee'),
                n.version_id));

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
    -- Une sourate retiree (CORRIGER-SOURATE, 20261123820000) garde sa ligne : elle ne compte pas.
    LEFT JOIN public.sourates_validees v
      ON v.student_id = p_eleve_id AND v.sourate_numero = b.numero AND v.retiree_le IS NULL;

  IF v_groupe IS NOT NULL THEN
    SELECT r.page::int INTO v_page FROM public.classe_position_reprise r WHERE r.groupe_id = v_groupe;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'eleve_id', p_eleve_id,
    'eleve_voit_dates', v_voit,
    'etape', pg_catalog.jsonb_build_object(
      'code', n.code_technique,
      'ordre', n.ordre,
      'nom', n.nom_humain,
      'objectifs', pg_catalog.to_jsonb(n.objectifs),
      'matiere_principale', n.matieres -> v_coh ->> 'principale',
      'matiere_secondaire', n.matieres -> v_coh ->> 'secondaire',
      'duree_prevue_semaines', CASE WHEN v_masque THEN NULL ELSE (n.durees -> v_coh ->> 'prevue')::int END,
      'date_limite_semaines', CASE WHEN v_masque THEN NULL ELSE (n.durees -> v_coh ->> 'limite')::int END,
      'entree_le', CASE WHEN v_masque THEN NULL ELSE f.entree_etape_le END,
      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_dates.date_limite END,
      'semaines_ecoulees', CASE WHEN v_masque THEN NULL
                                ELSE pg_catalog.floor((pg_catalog.now()::date - f.entree_etape_le) / 7.0)::int END,
      'rythme', CASE WHEN v_masque THEN NULL
                     ELSE private.vitesse_eleve(f.entree_etape_le::timestamptz,
                                                (n.durees -> v_coh ->> 'prevue')::int,
                                                v_dates.date_limite, pg_catalog.now()) END),
    'niveau', pg_catalog.jsonb_build_object(
      'code', n.cycle_code,
      'nom', coalesce(v_cy.nom_humain, n.cycle),
      'cohorte', v_coh,
      'duree_prevue_semaines', CASE WHEN v_masque THEN NULL ELSE (v_cy.durees -> v_coh ->> 'prevue')::int END,
      'date_limite_semaines', CASE WHEN v_masque THEN NULL ELSE (v_cy.durees -> v_coh ->> 'limite')::int END,
      'entree_le', CASE WHEN v_masque THEN NULL ELSE f.entree_niveau_le END,
      'horizon', CASE WHEN v_masque THEN NULL ELSE v_dates.horizon END,
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
  'son niveau pour sa tranche avec objectifs, matieres, durees prevues et dates limites, date '
  'd''entree, date limite de l''etape, horizon du niveau, sourates des bases, page de reprise). '
  'Eleve, titulaire de son profil, tuteur du foyer, enseignant de sa classe (fenetre CAHIER-C1), '
  'direction. Date limite, horizon et rythme '
  'retenus pour l''eleve de moins de 10 ans qui lit pour lui-meme. 42501 sinon ; NULL sans etape.';

-- Pour la direction, apres une publication : combien d'eleves et de classes
-- sont encore sur une etape d'une version archivee (ils la finissent, rien n'est
-- bloque ; ils passeront a la version publiee au passage d'etape).
CREATE FUNCTION public.etapes_sur_ancienne_version()
RETURNS TABLE (eleves integer, classes integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT (SELECT pg_catalog.count(*)::int
              FROM public.eleve_etape_en_cours f
              JOIN public.programme_niveaux n ON n.id = f.niveau_id
              JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'archivee'
              JOIN public.profiles p ON p.id = f.student_id AND p.deleted_at IS NULL
             WHERE EXISTS (SELECT 1 FROM public.groupe_membres m
                             JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
                            WHERE m.student_id = f.student_id AND m.left_at IS NULL)),
           (SELECT pg_catalog.count(*)::int
              FROM public.groupes g
              JOIN public.programme_niveaux n ON n.id = g.programme_niveau_id
              JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'archivee'
             WHERE g.ended_at IS NULL);
END;
$function$;

-- L'etape de chaque classe de l'enseignant, lue dans sa version, publiee ou
-- archivee (jamais un brouillon) : une classe ne perd plus son etape a la
-- publication d'une version suivante. Signature, droits et colonnes inchanges.
CREATE OR REPLACE FUNCTION public.mes_classes_details()
RETURNS TABLE (
  groupe_id uuid,
  etape_ordre integer,
  etape_nom text,
  langue text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT g.id,
         n.ordre,
         n.nom_humain,
         l.nom_humain
    FROM public.groupes g
    LEFT JOIN (public.programme_niveaux n
               JOIN public.programme_versions v
                 ON v.id = n.version_id AND v.statut IN ('publiee', 'archivee'))
           ON n.id = g.programme_niveau_id
    LEFT JOIN public.langues_cours l ON l.code = g.langue_code
   WHERE g.teacher_id = auth.uid()
     AND g.ended_at IS NULL
     AND public.app_role() = 'teacher'
     AND public.app_account_valid()
$function$;

-- L'ancienne lecture de l'eleve et de sa famille (plus appelee par les ecrans,
-- retiree au lot 10) applique la meme regle : l'eleve de moins de 10 ans qui lit
-- pour lui-meme ne recoit ni duree, ni date, ni rythme. Signature, garde,
-- colonnes et droits inchanges (CREATE OR REPLACE garde l'ACL).
CREATE OR REPLACE FUNCTION public.suivi_pedagogique_eleve(p_eleve_id uuid)
RETURNS TABLE (
  etape_nom text,
  etape_ordre int,
  cycle text,
  objectifs text[],
  duree_prevue_semaines int,
  date_limite date,
  depuis timestamptz,
  semaines_ecoulees int,
  rythme text,
  page_reprise int,
  page_reprise_le timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_user uuid := auth.uid();
  v_groupe uuid;
  v_masque boolean;
BEGIN
  IF NOT coalesce(
    v_user IS NOT NULL AND p_eleve_id IS NOT NULL AND public.app_account_valid()
    AND (
      -- L'eleve lui-meme.
      (public.app_role() = 'student' AND p_eleve_id = v_user)
      -- Le titulaire de son propre profil eleve (0052).
      OR (public.app_role() = 'guardian' AND p_eleve_id = v_user
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                         AND sp.deleted_at IS NULL))
      -- Le tuteur du foyer de l'eleve : son enfant seulement.
      OR (public.app_role() = 'guardian'
          AND EXISTS (SELECT 1 FROM public.profiles p
                       WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                         AND p.household_id IS NOT NULL
                         AND p.household_id = public.app_household_id()))
    ), false) THEN
    RAISE EXCEPTION 'suivi pedagogique refuse' USING errcode = '42501';
  END IF;

  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL;
  IF v_groupe IS NULL THEN
    RETURN;
  END IF;
  v_masque := private.dates_retenues(p_eleve_id, v_groupe);

  RETURN QUERY
    WITH e AS (
      SELECT * FROM private.etape_eleve(p_eleve_id, v_groupe)
    ),
    calcul AS (
      SELECT e.*,
             CASE WHEN e.depuis IS NOT NULL
                  THEN pg_catalog.floor(
                         EXTRACT(epoch FROM pg_catalog.now() - e.depuis) / 604800)::int
             END AS semaines
        FROM e
    )
    SELECT c.etape_nom,
           c.etape_ordre,
           c.cycle,
           c.objectifs,
           CASE WHEN v_masque THEN NULL ELSE c.duree_prevue_semaines END,
           CASE WHEN v_masque THEN NULL ELSE c.date_limite END,
           CASE WHEN v_masque THEN NULL ELSE c.depuis END,
           CASE WHEN v_masque THEN NULL ELSE c.semaines END,
           CASE WHEN v_masque THEN NULL
                ELSE private.vitesse_eleve(c.depuis, c.duree_prevue_semaines, c.date_limite, pg_catalog.now()) END,
           r.page::int,
           r.presentee_le
      FROM calcul c
      LEFT JOIN public.classe_position_reprise r ON r.groupe_id = v_groupe;
END;
$function$;

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

-- La proposition des bases d'un geste : desormais le contenu decide (durees et
-- dates limites d'etape du tableau 1 bis, matieres, niveau), et plus le
-- decoupage x 1,3 de C2.
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
  '(quatre etapes, objectifs en vigueur, matieres, durees prevues et dates limites du tableau 1 bis, '
  'niveau et sa date limite). Remplace la proposition de CAHIER-C2.';

-- ---------------------------------------------------------------------------
-- 10. Completer un brouillon VIDE, jamais publier
-- ---------------------------------------------------------------------------
-- Le brouillon le plus recent recoit le contenu des bases s'il se laisse completer
-- sans rien retirer (voir version_bases_convertible) ET s'il est vide de contenu :
-- aucune de ses etapes n'a d'objectif ni de duree. Un brouillon que la direction a
-- deja rempli n'est jamais touche. Ne publie rien, ne touche ni classe ni eleve.
-- Rend l'identifiant du brouillon complete, ou NULL quand il n'y a rien a faire.
CREATE FUNCTION private.completer_brouillon_bases()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_version uuid;
BEGIN
  SELECT v.id INTO v_version
    FROM public.programme_versions v
   WHERE v.statut = 'brouillon'
   ORDER BY v.numero_version DESC
   LIMIT 1;
  IF v_version IS NULL THEN
    RETURN NULL;
  END IF;
  IF NOT private.version_bases_convertible(v_version)
     OR EXISTS (SELECT 1 FROM public.programme_niveaux n
                 WHERE n.version_id = v_version
                   AND (pg_catalog.cardinality(n.objectifs) > 0
                        OR n.durees <> '{}'::jsonb)) THEN
    RETURN NULL;
  END IF;
  PERFORM private.remplir_version_bases(v_version);
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
REVOKE ALL ON FUNCTION private.etape_publiee_equivalente(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.etape_par_defaut() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.cohorte_effective(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.dates_etape(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_voit_dates(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.dates_retenues(uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.poser_etape_eleve(uuid, uuid, timestamptz) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.rattacher_classes_et_eleves() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_classe_neuve() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_entree_en_classe() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.socle_decision_niveau() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.completer_brouillon_bases() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.etape_eleve_lecture(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.etape_eleve_lecture(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.etapes_sur_ancienne_version() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.etapes_sur_ancienne_version() TO authenticated;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.eleve_etape_en_cours FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION public.etape_eleve_lecture(uuid) FROM agent_ro';
  END IF;
END
$agent$;

-- ---------------------------------------------------------------------------
-- 12. Installation : completer un brouillon vide, rien d'autre
-- ---------------------------------------------------------------------------
DO $completer$
DECLARE
  v_version uuid;
BEGIN
  v_version := private.completer_brouillon_bases();
  IF v_version IS NULL THEN
    RAISE NOTICE 'SOCLE-PROGRAMME : aucun brouillon vide a completer ; rien n''est publie, aucune classe ni aucun eleve n''est touche';
  ELSE
    RAISE NOTICE 'SOCLE-PROGRAMME : brouillon % complete, NON publie ; aucune classe ni aucun eleve n''est touche', v_version;
  END IF;
END
$completer$;

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
     OR pg_catalog.has_function_privilege('authenticated', 'private.completer_brouillon_bases()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.poser_etape_eleve(uuid, uuid, timestamptz)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.dates_etape(uuid)', 'EXECUTE')
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
  -- Les durees et dates limites des etapes font exactement celles du niveau, tranche par tranche.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_each(private.durees_niveau_bases()) t(coh, v)
     WHERE (SELECT pg_catalog.sum((c.durees -> t.coh ->> 'limite')::int) FROM private.contenu_bases() c)
           <> (t.v ->> 'limite')::int
        OR (SELECT pg_catalog.sum((c.durees -> t.coh ->> 'prevue')::int) FROM private.contenu_bases() c)
           <> (t.v ->> 'prevue')::int) THEN
    RAISE EXCEPTION 'SOCLE-PROGRAMME : la somme des etapes ne fait pas le niveau';
  END IF;
END
$postflight$;

