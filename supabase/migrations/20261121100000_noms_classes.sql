-- NOMS-CLASSES (08/11/2026, lot confie a B par le pilote).
--
-- Decision du directeur du 25/10/2026 (BOUCLE-1_PLAN_2026-10-24.md §5) : les
-- classes sont nommees automatiquement par le systeme, depuis une bibliotheque
-- de noms versionnee dans le depot (supabase/donnees/noms_classes.json) : des
-- noms de personnalites islamiques et historiques, simples a prononcer ; des noms
-- feminins pour les classes feminines, masculins pour les classes masculines. La
-- direction ne saisit pas de nom ; elle peut le changer apres coup. Chaque nom
-- sert a une seule classe active a la fois.
--
-- Liste PROPOSEE, a valider par le directeur avant l'installation en production
-- (sa decision du 25/10). Les valeurs ci-dessous sont celles du fichier de
-- donnees, une a une ; test/tool/noms_classes_coherence_test.dart le verifie.
--
-- Ce que fait le fichier :
-- 1. private.noms_classes : la banque (genre, rang, nom en fr et en ar), RLS
--    active sans policy, aucun droit client.
-- 2. public.groupes.nom_banque_id : le nom de la banque porte par la classe
--    (vide pour un nom saisi ou change par la direction). Un index unique partiel
--    garantit qu'un nom de la banque sert a une seule classe active
--    (ended_at IS NULL).
-- 3. private.nom_classe_choisir(genre) : le premier nom libre de la banque, dans
--    l'ordre des rangs. Classe de femmes : noms feminins ; classe d'hommes : noms
--    masculins ; classe mixte ou de genre inconnu : les deux listes, en
--    alternance. Un nom est pris s'il est porte par une classe active, ou si une
--    classe active a deja ce libelle (casse ignoree). REPLI explicite quand tout
--    est pris : « Classe N », N le plus petit entier libre parmi les classes
--    actives ; jamais un blocage.
-- 4. Declencheur BEFORE INSERT sur public.groupes : un libelle vide ou absent
--    recoit le nom choisi (verrou consultatif de transaction : deux creations
--    simultanees ne prennent pas le meme nom). Un libelle fourni est garde tel
--    quel (ancien client, ou nom choisi par la direction).
-- 5. Declencheur BEFORE UPDATE OF libelle : quand la direction change le nom, la
--    classe ne porte plus le nom de la banque (nom_banque_id vide), qui redevient
--    libre.
-- 6. creer_classe_depuis_regroupement accepte un libelle vide (retouche par
--    ancres, md5 preflight) ; creer_classe_creneaux_admin n'a rien a changer (elle
--    passe p_libelle tel quel, le declencheur nomme).
--
-- Aucun BEGIN/COMMIT au premier niveau ; aucun mot d'effacement ; aucune donnee
-- reelle ; aucun texte d'erreur SQL recopie dans un WARNING.

-- PREFLIGHT (modele de 20261121000100) : md5(prosrc) des deux fonctions de
-- creation de classe, relus le 08/11 sur une base neuve rejouee depuis main
-- 13fc04c09 (stub_auth puis toutes les migrations) :
--   creer_classe_depuis_regroupement(uuid,uuid,text) : derniere definition par
--     20261021210100_c11bis_affectation_verifiee.sql, retouchee ici ;
--   creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint) :
--     derniere definition par 20261120200500_fuseaux_connus.sql, NON modifiee
--     ici ; son empreinte prouve qu'elle passe toujours p_libelle tel quel a
--     l'INSERT, que le declencheur nomme.
--   SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
--    WHERE p.oid = '<signature>'::regprocedure;
-- Le pilote relit ces deux empreintes en production avant d'installer ; si
-- l'une differe, la migration s'arrete et est a revoir.
DO $preflight$
DECLARE
  v_regr text;
  v_creneaux text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_regr FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure;
  SELECT pg_catalog.md5(p.prosrc) INTO v_creneaux FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)'::regprocedure;
  IF v_regr IS DISTINCT FROM 'a69c21022e0b3ba76313292d211ff600' THEN
    RAISE EXCEPTION 'NOMS-CLASSES : creer_classe_depuis_regroupement a change (md5 %), migration a revoir', v_regr;
  END IF;
  IF v_creneaux IS DISTINCT FROM '31bb69b63fd48597d0ef24fd5012a2f9' THEN
    RAISE EXCEPTION 'NOMS-CLASSES : creer_classe_creneaux_admin a change (md5 %), migration a revoir', v_creneaux;
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_attribute a
       WHERE a.attrelid = 'public.groupes'::regclass AND NOT a.attisdropped
         AND a.attname IN ('libelle', 'genre_public', 'etat', 'ended_at')) <> 4 THEN
    RAISE EXCEPTION 'NOMS-CLASSES : public.groupes n''a pas libelle, genre_public, etat et ended_at';
  END IF;
  IF pg_catalog.to_regclass('private.noms_classes') IS NOT NULL THEN
    RAISE EXCEPTION 'NOMS-CLASSES : private.noms_classes existe deja';
  END IF;
END;
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'NOMS-CLASSES : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1. La banque.
-- ---------------------------------------------------------------------------
CREATE TABLE private.noms_classes (
  id smallint PRIMARY KEY,
  genre text NOT NULL CHECK (genre IN ('femmes', 'hommes')),
  rang smallint NOT NULL CHECK (rang >= 1),
  nom_fr text NOT NULL CHECK (pg_catalog.btrim(nom_fr) <> ''),
  nom_ar text NOT NULL CHECK (pg_catalog.btrim(nom_ar) <> ''),
  UNIQUE (genre, rang),
  UNIQUE (nom_fr),
  UNIQUE (nom_ar)
);
ALTER TABLE private.noms_classes OWNER TO postgres;
ALTER TABLE private.noms_classes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.noms_classes FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE private.noms_classes IS
  'NOMS-CLASSES (decision du directeur du 25/10/2026) : la banque des noms de classes, '
  'copie de supabase/donnees/noms_classes.json (version 1). Aucun droit client.';

INSERT INTO private.noms_classes (id, genre, rang, nom_fr, nom_ar) VALUES
  (1, 'femmes', 1, 'Khadija', 'خديجة'),
  (2, 'femmes', 2, 'Aïcha', 'عائشة'),
  (3, 'femmes', 3, 'Fatima', 'فاطمة'),
  (4, 'femmes', 4, 'Maryam', 'مريم'),
  (5, 'femmes', 5, 'Assia', 'آسية'),
  (6, 'femmes', 6, 'Hajar', 'هاجر'),
  (7, 'femmes', 7, 'Sarah', 'سارة'),
  (8, 'femmes', 8, 'Soumaya', 'سمية'),
  (9, 'femmes', 9, 'Hafsa', 'حفصة'),
  (10, 'femmes', 10, 'Zaynab', 'زينب'),
  (11, 'femmes', 11, 'Rouqayya', 'رقية'),
  (12, 'femmes', 12, 'Safiya', 'صفية'),
  (13, 'femmes', 13, 'Sawda', 'سودة'),
  (14, 'femmes', 14, 'Maymouna', 'ميمونة'),
  (15, 'femmes', 15, 'Asma', 'أسماء'),
  (16, 'femmes', 16, 'Noussayba', 'نسيبة'),
  (17, 'femmes', 17, 'Roufayda', 'رفيدة'),
  (18, 'femmes', 18, 'Halima', 'حليمة'),
  (19, 'femmes', 19, 'Amina', 'آمنة'),
  (20, 'femmes', 20, 'Baraka', 'بركة'),
  (21, 'femmes', 21, 'Khawla', 'خولة'),
  (22, 'femmes', 22, 'Chifa', 'الشفاء'),
  (23, 'femmes', 23, 'Loubaba', 'لبابة'),
  (24, 'femmes', 24, 'Ramla', 'رملة'),
  (25, 'femmes', 25, 'Oumama', 'أمامة'),
  (26, 'femmes', 26, 'Nafissa', 'نفيسة'),
  (27, 'femmes', 27, 'Zoubayda', 'زبيدة'),
  (28, 'femmes', 28, 'Arwa', 'أروى'),
  (29, 'femmes', 29, 'Salma', 'سلمى'),
  (30, 'femmes', 30, 'Atika', 'عاتكة'),
  (31, 'femmes', 31, 'Roumayssa', 'الرميصاء'),
  (32, 'femmes', 32, 'Layla', 'ليلى'),
  (33, 'femmes', 33, 'Habiba', 'حبيبة'),
  (34, 'femmes', 34, 'Khansa', 'الخنساء'),
  (35, 'femmes', 35, 'Chayma', 'الشيماء'),
  (36, 'femmes', 36, 'Fakhita', 'فاختة'),
  (37, 'femmes', 37, 'Bilqis', 'بلقيس'),
  (38, 'femmes', 38, 'Hawa', 'حواء'),
  (39, 'femmes', 39, 'Jamila', 'جميلة'),
  (40, 'femmes', 40, 'Barira', 'بريرة'),
  (41, 'hommes', 1, 'Ibrahim', 'إبراهيم'),
  (42, 'hommes', 2, 'Ismaïl', 'إسماعيل'),
  (43, 'hommes', 3, 'Ishaq', 'إسحاق'),
  (44, 'hommes', 4, 'Yaqoub', 'يعقوب'),
  (45, 'hommes', 5, 'Youssouf', 'يوسف'),
  (46, 'hommes', 6, 'Moussa', 'موسى'),
  (47, 'hommes', 7, 'Haroun', 'هارون'),
  (48, 'hommes', 8, 'Daoud', 'داود'),
  (49, 'hommes', 9, 'Souleymane', 'سليمان'),
  (50, 'hommes', 10, 'Younous', 'يونس'),
  (51, 'hommes', 11, 'Nouh', 'نوح'),
  (52, 'hommes', 12, 'Idriss', 'إدريس'),
  (53, 'hommes', 13, 'Houd', 'هود'),
  (54, 'hommes', 14, 'Salih', 'صالح'),
  (55, 'hommes', 15, 'Chouaïb', 'شعيب'),
  (56, 'hommes', 16, 'Zakariya', 'زكريا'),
  (57, 'hommes', 17, 'Yahya', 'يحيى'),
  (58, 'hommes', 18, 'Issa', 'عيسى'),
  (59, 'hommes', 19, 'Ayyoub', 'أيوب'),
  (60, 'hommes', 20, 'Ilyas', 'إلياس'),
  (61, 'hommes', 21, 'Abou Bakr', 'أبو بكر'),
  (62, 'hommes', 22, 'Omar', 'عمر'),
  (63, 'hommes', 23, 'Othmane', 'عثمان'),
  (64, 'hommes', 24, 'Ali', 'علي'),
  (65, 'hommes', 25, 'Bilal', 'بلال'),
  (66, 'hommes', 26, 'Hamza', 'حمزة'),
  (67, 'hommes', 27, 'Khalid', 'خالد'),
  (68, 'hommes', 28, 'Saad', 'سعد'),
  (69, 'hommes', 29, 'Zayd', 'زيد'),
  (70, 'hommes', 30, 'Anas', 'أنس'),
  (71, 'hommes', 31, 'Mouadh', 'معاذ'),
  (72, 'hommes', 32, 'Oussama', 'أسامة'),
  (73, 'hommes', 33, 'Salmane', 'سلمان'),
  (74, 'hommes', 34, 'Ammar', 'عمار'),
  (75, 'hommes', 35, 'Abbas', 'العباس'),
  (76, 'hommes', 36, 'Jaafar', 'جعفر'),
  (77, 'hommes', 37, 'Talha', 'طلحة'),
  (78, 'hommes', 38, 'Zoubayr', 'الزبير'),
  (79, 'hommes', 39, 'Moussab', 'مصعب'),
  (80, 'hommes', 40, 'Souhayb', 'صهيب'),
  (81, 'hommes', 41, 'Hassane', 'حسان'),
  (82, 'hommes', 42, 'Tariq', 'طارق'),
  (83, 'hommes', 43, 'Malik', 'مالك')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Le nom porte par la classe.
-- ---------------------------------------------------------------------------
ALTER TABLE public.groupes
  ADD COLUMN nom_banque_id smallint REFERENCES private.noms_classes (id);
COMMENT ON COLUMN public.groupes.nom_banque_id IS
  'NOMS-CLASSES : le nom de la banque porte par la classe ; vide quand la direction a '
  'saisi ou change le nom. Un nom de la banque sert a une seule classe active.';
CREATE UNIQUE INDEX groupes_nom_banque_actif_uniq
  ON public.groupes (nom_banque_id)
  WHERE ended_at IS NULL AND nom_banque_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Le choix, avec repli.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.nom_classe_choisir(p_genre text, OUT o_id smallint, OUT o_nom text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer := 1;
BEGIN
  SELECT b.id, b.nom_fr INTO o_id, o_nom
    FROM private.noms_classes b
   WHERE (CASE p_genre WHEN 'femmes' THEN b.genre = 'femmes'
                       WHEN 'hommes' THEN b.genre = 'hommes'
                       ELSE true END)
     AND NOT EXISTS (SELECT 1 FROM public.groupes g
                      WHERE g.ended_at IS NULL
                        AND (g.nom_banque_id = b.id
                             OR pg_catalog.lower(pg_catalog.btrim(g.libelle)) = pg_catalog.lower(b.nom_fr)))
   ORDER BY b.rang, b.genre
   LIMIT 1;
  IF o_id IS NOT NULL THEN
    RETURN;
  END IF;
  -- Repli : tous les noms du genre sont pris par des classes actives.
  WHILE EXISTS (SELECT 1 FROM public.groupes g
                 WHERE g.ended_at IS NULL
                   AND pg_catalog.lower(pg_catalog.btrim(g.libelle)) = 'classe ' || v_n::text) LOOP
    v_n := v_n + 1;
  END LOOP;
  o_id := NULL;
  o_nom := 'Classe ' || v_n::text;
END;
$function$;
ALTER FUNCTION private.nom_classe_choisir(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.nom_classe_choisir(text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.nom_classe_choisir(text) IS
  'NOMS-CLASSES : le premier nom libre de la banque pour un genre de classe (femmes, hommes ; '
  'mixte ou inconnu : les deux listes) ; repli « Classe N » quand tout est pris. Aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 4. et 5. Les declencheurs.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.groupes_nommer_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id smallint;
  v_nom text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF coalesce(pg_catalog.btrim(NEW.libelle), '') = '' THEN
      PERFORM pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended('noms-classes', 0));
      SELECT c.o_id, c.o_nom INTO v_id, v_nom
        FROM private.nom_classe_choisir(NEW.genre_public) AS c;
      NEW.libelle := v_nom;
      NEW.nom_banque_id := v_id;
    END IF;
    RETURN NEW;
  END IF;
  -- UPDATE OF libelle : un nom change par la direction libere celui de la banque.
  IF NEW.nom_banque_id IS NOT NULL
     AND NEW.libelle IS DISTINCT FROM OLD.libelle
     AND NOT EXISTS (SELECT 1 FROM private.noms_classes b
                      WHERE b.id = NEW.nom_banque_id AND b.nom_fr = NEW.libelle) THEN
    NEW.nom_banque_id := NULL;
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.groupes_nommer_trg() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.groupes_nommer_trg()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.groupes_nommer_trg() IS
  'NOMS-CLASSES : nomme une classe creee sans libelle (banque, puis repli) ; libere le nom de la '
  'banque quand la direction renomme la classe.';

-- Le prefixe « 00 » fait passer ce declencheur avant les autres BEFORE INSERT,
-- qui voient donc deja le libelle.
CREATE TRIGGER groupes_00_nommer_ins
  BEFORE INSERT ON public.groupes
  FOR EACH ROW EXECUTE FUNCTION private.groupes_nommer_trg();
CREATE TRIGGER groupes_00_nommer_upd
  BEFORE UPDATE OF libelle ON public.groupes
  FOR EACH ROW EXECUTE FUNCTION private.groupes_nommer_trg();

-- ---------------------------------------------------------------------------
-- 6. « Créer la classe » depuis un regroupement : le libelle devient facultatif.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure,
  'OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '''') = '''' THEN',
  'OR p_cle_idempotence IS NULL THEN');
SELECT pg_temp.remplacer('public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure,
  '(NULL, ''en_attente_enseignant'', v_type, v_quota, btrim(p_libelle),',
  '(NULL, ''en_attente_enseignant'', v_type, v_quota, nullif(btrim(p_libelle), ''''),');

DO $postflight$
DECLARE
  v_f integer;
  v_h integer;
BEGIN
  SELECT pg_catalog.count(*) FILTER (WHERE genre = 'femmes'),
         pg_catalog.count(*) FILTER (WHERE genre = 'hommes')
    INTO v_f, v_h FROM private.noms_classes;
  IF v_f < 40 OR v_h < 40 THEN
    RAISE EXCEPTION 'NOMS-CLASSES : banque incomplete (% feminins, % masculins)', v_f, v_h;
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.noms_classes'::regclass) THEN
    RAISE EXCEPTION 'NOMS-CLASSES : RLS absente sur private.noms_classes';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.groupes'::regclass
         AND t.tgname IN ('groupes_00_nommer_ins', 'groupes_00_nommer_upd')) <> 2 THEN
    RAISE EXCEPTION 'NOMS-CLASSES : declencheurs absents';
  END IF;
END;
$postflight$;
