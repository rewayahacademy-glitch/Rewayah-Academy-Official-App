-- HORLOGE-ET-LIEU, partie A (architecte pedagogique, 12/11/2026, sur delegation
-- du directeur ; decision : docs/current/pedagogie/HORLOGE-ET-LIEU.md, H1 et H4 ;
-- lot : docs/current/pedagogie/lots/LOT-HORLOGE-ET-LIEU.md).
--
-- L'heure de l'academie est celle de La Mecque (`Asia/Riyadh`, UTC+3, sans
-- changement d'heure). Tout creneau de classe est defini dans ce fuseau. Les
-- classes qui existent sont converties SANS QU'AUCUN INSTANT NE BOUGE : une
-- seance a 19 h a Paris en novembre est la meme seance, a 21 h a La Mecque.
--
-- 1. Reglage `fuseau_academie` de `app_config` (jamais ecrit en dur ailleurs) et
--    `private.fuseau_academie()`.
-- 2. Journal `private.conversions_horloge` : une ligne par classe convertie et par
--    transaction. Il n'est ecrit que par `private.convertir_classe_vers_academie`
--    (aucun EXECUTE a personne). Il sert de seul « drapeau » : un declencheur sait
--    qu'une ecriture est la conversion elle-meme quand la ligne de CETTE
--    transaction et de CETTE classe dit exactement ce changement-la (anciennes et
--    nouvelles valeurs identiques). Aucun utilisateur ne peut l'ecrire ; il est
--    local a la transaction ; un vrai changement de creneau notifie comme avant.
-- 3. Cinq declencheurs reconnaissent la conversion et se taisent : les deux
--    notifieurs (aucune notification), les deux verificateurs d'affectation
--    (rien de nouveau a verifier : aucun instant ne change), et la
--    materialisation (aucune seance creee ni deplacee).
-- 4. `private.convertir_classe_vers_academie(uuid)` : photographie des seances
--    avant et apres (nombre et empreinte, dans la meme transaction, sinon
--    exception), controle que chaque seance a venir tombe exactement sur une
--    occurrence calculee a La Mecque (sinon exception, rien n'est converti), refus a
--    moins de 28 jours d'un changement d'heure de l'ancien fuseau, refus d'une
--    heure sans equivalent entier a La Mecque.
-- 5. `private.convertir_classes_hors_academie()` : tache de nuit pour le client
--    deja en production, dont les fonctions gardent leur signature et leur sens
--    (heure murale dans le fuseau recu) : une classe nee a Paris est convertie la nuit
--    suivante. Une classe refusee est signalee (WARNING) et reessayee.
-- 6. Conversion des classes existantes, dans CETTE migration, avec un arret net
--    au moindre ecart.
-- 7. `public.mon_horloge()` rend aussi l'horloge de l'academie (cle `academie`).
--
-- FICHIER SANS EFFACEMENT : des fonctions remplacees par leur copie complete,
-- des objets crees ; aucun objet retire, aucune ligne effacee.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Preflight : les six fonctions remplacees doivent etre exactement celles
--    relevees en production et dans le depot le 12/11/2026 (empreintes de
--    prosrc). Une retouche faite depuis ne peut pas etre ecrasee en silence.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_attendu constant jsonb := pg_catalog.jsonb_build_object(
    'private.notifier_classe_groupes()',                      '7e54a6044b1890df22955f691184f350',
    'private.notifier_classe_creneaux()',                     '02fe152f51935601ac1272d251cfdba8',
    'app_private.verifier_horaire_classe_avec_enseignant()',  'f8a20f9d9182472803f2d33a40b25a62',
    'app_private.verifier_creneau_classe_avec_enseignant()',  '43e9bdbd33da23ec862fe8d45238555b',
    'public.tc_materialiser_apres_creation_groupe()',         '068b8f1708d659db1f248a075520a730',
    'public.mon_horloge()',                                   '0c3d78a0653b591286ccd424ee6ad5df');
  v_f text;
  v_empreinte text;
BEGIN
  FOR v_f IN SELECT k FROM pg_catalog.jsonb_object_keys(v_attendu) AS k LOOP
    SELECT pg_catalog.md5(p.prosrc) INTO v_empreinte
      FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure;
    IF v_empreinte IS DISTINCT FROM (v_attendu ->> v_f) THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : % a change depuis le releve (empreinte %), migration refusee',
        v_f, v_empreinte;
    END IF;
  END LOOP;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le reglage de la direction : le fuseau de reference de l'academie
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
VALUES ('fuseau_academie', pg_catalog.to_jsonb('Asia/Riyadh'::text))
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.fuseau_academie()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
BEGIN
  SELECT pg_catalog.btrim(c.value #>> '{}') INTO v_fuseau
    FROM public.app_config c WHERE c.key = 'fuseau_academie';
  -- Valeur absente ou fuseau inconnu : la valeur decidee le 12/11/2026, jamais
  -- une valeur inventee.
  IF v_fuseau IS NULL OR v_fuseau = '' OR NOT app_private.fuseau_connu(v_fuseau) THEN
    RETURN 'Asia/Riyadh';
  END IF;
  RETURN v_fuseau;
END;
$function$;

COMMENT ON FUNCTION private.fuseau_academie() IS
  'HORLOGE-ET-LIEU (12/11/2026) : le fuseau de reference de l''academie (app_config.fuseau_academie, defaut Asia/Riyadh). DEFINER, search_path vide, aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 2. Le journal des conversions (le seul « drapeau »)
-- ---------------------------------------------------------------------------
CREATE TABLE private.conversions_horloge (
  txid          bigint      NOT NULL,
  groupe_id     uuid        NOT NULL,
  convertie_le  timestamptz NOT NULL,
  fuseau_avant  text        NOT NULL,
  fuseau_apres  text        NOT NULL,
  weekday_avant smallint    NOT NULL,
  hour_avant    smallint    NOT NULL,
  weekday_apres smallint    NOT NULL,
  hour_apres    smallint    NOT NULL,
  creneaux      jsonb       NOT NULL,
  nb_seances    integer     NOT NULL,
  empreinte_seances text    NOT NULL,
  PRIMARY KEY (txid, groupe_id)
);
ALTER TABLE private.conversions_horloge ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.conversions_horloge FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON TABLE private.conversions_horloge IS
  'HORLOGE-ET-LIEU (12/11/2026) : une ligne par classe convertie vers le fuseau de l''academie, avec les anciennes et nouvelles valeurs. Ecrite seulement par private.convertir_classe_vers_academie ; lue par les declencheurs pour reconnaitre la conversion (meme transaction, meme classe, memes valeurs). RLS sans politique.';

-- Cette ecriture de groupes est-elle exactement la conversion de CETTE
-- transaction ? (anciennes et nouvelles valeurs de la classe)
CREATE FUNCTION private.conversion_horloge_groupe(
  p_groupe uuid,
  p_weekday_avant integer, p_hour_avant integer, p_fuseau_avant text,
  p_weekday_apres integer, p_hour_apres integer, p_fuseau_apres text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM private.conversions_horloge c
     WHERE c.txid = pg_catalog.txid_current()
       AND c.convertie_le = pg_catalog.transaction_timestamp()
       AND c.groupe_id = p_groupe
       AND c.weekday_avant = p_weekday_avant AND c.hour_avant = p_hour_avant
       AND c.fuseau_avant = p_fuseau_avant
       AND c.weekday_apres = p_weekday_apres AND c.hour_apres = p_hour_apres
       AND c.fuseau_apres = p_fuseau_apres);
$function$;

-- Cette ecriture d'un creneau est-elle exactement la conversion ? Un cote nul
-- (creneau ecrit par l'ancre : INSERT sans « avant », effacement de l'ancre
-- par son declencheur : sans « apres ») ne compare que l'autre cote.
CREATE FUNCTION private.conversion_horloge_creneau(
  p_groupe uuid,
  p_weekday_avant integer, p_hour_avant integer,
  p_weekday_apres integer, p_hour_apres integer)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM private.conversions_horloge c
      CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(c.creneaux) AS e
     WHERE c.txid = pg_catalog.txid_current()
       AND c.convertie_le = pg_catalog.transaction_timestamp()
       AND c.groupe_id = p_groupe
       AND (p_weekday_avant IS NULL
            OR ((e ->> 'wd0')::integer = p_weekday_avant AND (e ->> 'h0')::integer = p_hour_avant))
       AND (p_weekday_apres IS NULL
            OR ((e ->> 'wd1')::integer = p_weekday_apres AND (e ->> 'h1')::integer = p_hour_apres)));
$function$;

REVOKE ALL ON FUNCTION private.conversion_horloge_groupe(uuid, integer, integer, text, integer, integer, text)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.conversion_horloge_creneau(uuid, integer, integer, integer, integer)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fuseau_academie() FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Les cinq declencheurs reconnaissent la conversion (copies completes ; seule
--    difference : la reconnaissance de la conversion)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notifier_classe_groupes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- L'etat final : une classe fermee (ou effacee) dans la meme transaction
    -- ne se dit pas.
    IF EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = NEW.id AND g.ended_at IS NULL) THEN
      PERFORM private.notifier_classe(NEW.id, 'classe_creee');
    END IF;
    RETURN NULL;
  END IF;

  -- UPDATE
  IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL THEN
    PERFORM private.notifier_classe(
      NEW.id, 'classe_supprimee',
      p_enseignants := ARRAY[OLD.teacher_id]);
    RETURN NULL;
  END IF;
  IF NEW.ended_at IS NOT NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = NEW.id AND g.ended_at IS NULL) THEN
    RETURN NULL;
  END IF;

  IF OLD.teacher_id IS DISTINCT FROM NEW.teacher_id THEN
    IF OLD.teacher_id IS NULL THEN
      PERFORM private.notifier_classe(NEW.id, 'enseignant_affecte');
    ELSE
      PERFORM private.notifier_classe(
        NEW.id, 'enseignant_change',
        p_enseignants := ARRAY[OLD.teacher_id]);
    END IF;
  END IF;

  -- HORLOGE-ET-LIEU : la conversion vers l'heure de l'academie ne deplace aucun
  -- instant, elle ne se dit a personne. Tout autre changement de creneau se dit
  -- comme avant.
  IF (OLD.weekday, OLD.hour_local, OLD.timezone_iana)
     IS DISTINCT FROM (NEW.weekday, NEW.hour_local, NEW.timezone_iana)
     AND NOT private.conversion_horloge_groupe(
           NEW.id, OLD.weekday, OLD.hour_local, OLD.timezone_iana,
           NEW.weekday, NEW.hour_local, NEW.timezone_iana) THEN
    PERFORM private.notifier_classe(NEW.id, 'creneau_change');
  END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION private.notifier_classe_creneaux()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid := CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN NEW.groupe_id ELSE OLD.groupe_id END;
BEGIN
  -- HORLOGE-ET-LIEU : une ecriture de creneau qui est la conversion elle-meme
  -- (meme transaction, meme classe, memes valeurs) ne se dit a personne.
  IF private.conversion_horloge_creneau(
       v_groupe,
       CASE WHEN TG_OP <> 'INSERT' THEN OLD.weekday END,
       CASE WHEN TG_OP <> 'INSERT' THEN OLD.hour_local END,
       CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN NEW.weekday END,
       CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN NEW.hour_local END) THEN
    RETURN NULL;
  END IF;
  IF private.classe_ouverte_et_ancienne(v_groupe) THEN
    PERFORM private.notifier_classe(v_groupe, 'creneau_change');
  END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION app_private.verifier_horaire_classe_avec_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Seule une Classe active, non close, qui a son enseignant est controlee : une
  -- Classe en attente se deplace comme avant (elle n'a personne a verifier).
  IF NOT coalesce(NEW.teacher_id IS NOT NULL AND NEW.etat = 'active' AND NEW.ended_at IS NULL, false) THEN
    RETURN NULL;
  END IF;
  -- HORLOGE-ET-LIEU : la conversion vers l'heure de l'academie ne deplace aucun
  -- instant ; il n'y a rien de nouveau a verifier. Elle est controlee a part,
  -- dans private.convertir_classe_vers_academie.
  IF private.conversion_horloge_groupe(
       NEW.id, OLD.weekday, OLD.hour_local, OLD.timezone_iana,
       NEW.weekday, NEW.hour_local, NEW.timezone_iana) THEN
    RETURN NULL;
  END IF;
  -- Le predicat lit les tables : l'horaire nouveau y est deja. Il ecarte la
  -- Classe de ses propres collisions ; un refus (P0001, memes messages que
  -- l'affectation) annule l'ecriture, avant la materialisation des seances.
  PERFORM app_private.verifier_affectation_enseignant_base(NEW.id, NEW.teacher_id, true);
  PERFORM app_private.verifier_horaire_contre_seances_planifiees(NEW.id);
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION app_private.verifier_creneau_classe_avec_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  SELECT g.* INTO v_g FROM public.groupes g WHERE g.id = NEW.groupe_id;
  IF NOT coalesce(FOUND AND v_g.teacher_id IS NOT NULL AND v_g.etat = 'active' AND v_g.ended_at IS NULL, false) THEN
    RETURN NULL;
  END IF;
  -- HORLOGE-ET-LIEU : un creneau ecrit par la conversion vers l'heure de
  -- l'academie ne deplace aucun instant ; rien de nouveau a verifier.
  IF private.conversion_horloge_creneau(
       NEW.groupe_id,
       CASE WHEN TG_OP = 'UPDATE' THEN OLD.weekday END,
       CASE WHEN TG_OP = 'UPDATE' THEN OLD.hour_local END,
       NEW.weekday, NEW.hour_local) THEN
    RETURN NULL;
  END IF;
  -- Le creneau d'ancrage (celui de groupes.weekday / hour_local, que
  -- groupes_creneau_ancre ecrit avec la Classe) est deja couvert par
  -- groupes_horaire_verifie_enseignant : on ne le rejoue pas. Le critere est la
  -- LIGNE (l'ancre de la Classe), et non la profondeur d'appel : un creneau
  -- ecrit depuis un autre declencheur, qui n'est pas l'ancre, est controle.
  -- Duree par creneau (30/10) : sauf si seule sa duree change.
  IF NEW.weekday = v_g.weekday AND NEW.hour_local = v_g.hour_local
     AND (TG_OP = 'INSERT' OR OLD.duree_minutes IS NOT DISTINCT FROM NEW.duree_minutes) THEN
    RETURN NULL;
  END IF;
  PERFORM app_private.verifier_affectation_enseignant_base(NEW.groupe_id, v_g.teacher_id, true);
  PERFORM app_private.verifier_horaire_contre_seances_planifiees(NEW.groupe_id);
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.tc_materialiser_apres_creation_groupe()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- HORLOGE-ET-LIEU : la conversion vers l'heure de l'academie ne cree ni ne
  -- deplace aucune seance (les creneaux ne sont pas encore tous convertis a ce
  -- moment ; la cloche de nuit ne voit que des instants identiques).
  IF TG_OP = 'UPDATE'
     AND private.conversion_horloge_groupe(
           NEW.id, OLD.weekday, OLD.hour_local, OLD.timezone_iana,
           NEW.weekday, NEW.hour_local, NEW.timezone_iana) THEN
    RETURN NEW;
  END IF;
  IF NEW.ended_at IS NULL
     AND NEW.teacher_id IS NOT NULL
     AND NEW.etat = 'active' THEN
    PERFORM public.materialiser_seances_groupe(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. La conversion d'une classe
-- ---------------------------------------------------------------------------
-- p_maintenant : l'instant de reference (le test le fixe ; l'appel normal
-- laisse now()). Rend un resume jsonb, ou NULL si la classe n'existe plus, est
-- close, ou est deja au fuseau de l'academie.
CREATE FUNCTION private.convertir_classe_vers_academie(
  p_groupe_id uuid,
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_academie text := private.fuseau_academie();
  v_g public.groupes%ROWTYPE;
  v_changement timestamptz;
  v_map jsonb := '[]'::jsonb;
  v_attendu jsonb;
  v_c record;
  v_inst timestamptz;
  v_local timestamp;
  v_wd1 integer;
  v_h1 integer;
  v_n_avant integer;
  v_emp_avant text;
  v_n_apres integer;
  v_emp_apres text;
  v_hors integer;
  v_restants jsonb;
  v_pret jsonb;
  v_trouve boolean;
  v_ancre_wd1 integer;
  v_ancre_h1 integer;
  v_final jsonb;
BEGIN
  SELECT * INTO v_g FROM public.groupes
   WHERE id = p_groupe_id AND ended_at IS NULL
   FOR UPDATE;
  IF NOT FOUND OR v_g.timezone_iana = v_academie THEN
    RETURN NULL;
  END IF;

  -- Pas a moins de 28 jours d'un changement d'heure de l'ancien fuseau : des
  -- seances deja generees pourraient se trouver de part et d'autre.
  v_changement := (private.fuseau_info(v_g.timezone_iana, p_maintenant) ->> 'prochain_changement')::timestamptz;
  IF v_changement IS NOT NULL AND v_changement < p_maintenant + interval '28 days' THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : la classe % est a moins de 28 jours d''un changement d''heure (%, %) : conversion refusee',
      p_groupe_id, v_g.timezone_iana, v_changement
      USING ERRCODE = 'P0001';
  END IF;

  -- Les creneaux : ceux de la table, plus l'ancre si elle y manquait.
  FOR v_c IN
    SELECT s.jour, s.heure
      FROM (SELECT gc.weekday::integer AS jour, gc.hour_local::integer AS heure
              FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
            UNION
            SELECT v_g.weekday::integer, v_g.hour_local::integer) s
     ORDER BY s.jour, s.heure
  LOOP
    v_inst := public.instant_creneau_reference(v_c.jour, v_c.heure, v_g.timezone_iana, 0, p_maintenant);
    v_local := v_inst AT TIME ZONE v_academie;
    IF pg_catalog.date_part('minute', v_local) <> 0 OR pg_catalog.date_part('second', v_local) <> 0 THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : le creneau jour % heure % (%) n''a pas d''heure pleine a % : conversion refusee',
        v_c.jour, v_c.heure, v_g.timezone_iana, v_academie
        USING ERRCODE = 'P0001';
    END IF;
    v_wd1 := pg_catalog.date_part('isodow', v_local)::integer;
    v_h1 := pg_catalog.date_part('hour', v_local)::integer;
    v_map := v_map || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'wd0', v_c.jour, 'h0', v_c.heure, 'wd1', v_wd1, 'h1', v_h1));
    IF v_c.jour = v_g.weekday AND v_c.heure = v_g.hour_local THEN
      v_ancre_wd1 := v_wd1;
      v_ancre_h1 := v_h1;
    END IF;
  END LOOP;

  -- Deux creneaux d'une meme classe ne peuvent pas arriver sur la meme case.
  IF (SELECT pg_catalog.count(DISTINCT ((e ->> 'wd1'), (e ->> 'h1')))
        FROM pg_catalog.jsonb_array_elements(v_map) e)
     <> pg_catalog.jsonb_array_length(v_map) THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : deux creneaux de la classe % tombent a la meme heure a % : conversion refusee',
      p_groupe_id, v_academie USING ERRCODE = 'P0001';
  END IF;

  -- Chaque seance a venir doit tomber exactement sur une occurrence calculee
  -- au fuseau de l'academie ; sinon rien n'est converti (une seule seance
  -- decalee ferait un doublon ou un chevauchement).
  SELECT pg_catalog.count(*) INTO v_hors
    FROM public.sessions s
   WHERE s.groupe_id = p_groupe_id
     AND s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND s.started_at > p_maintenant
     AND NOT EXISTS (
       SELECT 1
         FROM pg_catalog.jsonb_array_elements(v_map) e
         CROSS JOIN pg_catalog.generate_series(0, 52) k
        WHERE public.instant_creneau_reference(
                (e ->> 'wd1')::integer, (e ->> 'h1')::integer, v_academie, k, p_maintenant) = s.started_at);
  IF v_hors > 0 THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : % seance(s) a venir de la classe % ne tombent pas sur une occurrence a % : conversion refusee',
      v_hors, p_groupe_id, v_academie USING ERRCODE = 'P0001';
  END IF;

  -- Les creneaux attendus apres conversion, avec leur duree propre.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'wd1', (e ->> 'wd1')::integer, 'h1', (e ->> 'h1')::integer,
           'duree', (SELECT gc.duree_minutes
                       FROM public.groupe_creneaux gc
                      WHERE gc.groupe_id = p_groupe_id
                        AND gc.weekday = (e ->> 'wd0')::integer
                        AND gc.hour_local = (e ->> 'h0')::integer))
         ORDER BY (e ->> 'wd1')::integer, (e ->> 'h1')::integer), '[]'::jsonb)
    INTO v_attendu
    FROM pg_catalog.jsonb_array_elements(v_map) e;

  -- La photographie des seances (toutes, passees comprises) avant.
  SELECT pg_catalog.count(*),
         coalesce(pg_catalog.md5(pg_catalog.string_agg(
           s.id::text || '|' || s.started_at::text || '|' || s.ended_at::text || '|' || s.status::text
           || '|' || coalesce(s.teacher_id::text, '') || '|' || (s.deleted_at IS NOT NULL)::text,
           ',' ORDER BY s.started_at, s.id)), '')
    INTO v_n_avant, v_emp_avant
    FROM public.sessions s WHERE s.groupe_id = p_groupe_id;

  -- Le journal : il dit aux declencheurs que ce qui suit est la conversion.
  INSERT INTO private.conversions_horloge
    (txid, groupe_id, convertie_le, fuseau_avant, fuseau_apres,
     weekday_avant, hour_avant, weekday_apres, hour_apres,
     creneaux, nb_seances, empreinte_seances)
  VALUES
    (pg_catalog.txid_current(), p_groupe_id, pg_catalog.transaction_timestamp(),
     v_g.timezone_iana, v_academie,
     v_g.weekday, v_g.hour_local,
     coalesce(v_ancre_wd1, v_g.weekday), coalesce(v_ancre_h1, v_g.hour_local),
     v_map, v_n_avant, v_emp_avant);

  -- La classe d'abord : l'ancre et son creneau suivent par le declencheur de
  -- l'ancre ; les autres creneaux ensuite, dans un ordre qui evite toute
  -- collision passagere.
  UPDATE public.groupes
     SET timezone_iana = v_academie,
         weekday = coalesce(v_ancre_wd1, v_g.weekday)::smallint,
         hour_local = coalesce(v_ancre_h1, v_g.hour_local)::smallint
   WHERE id = p_groupe_id;

  v_restants := (SELECT coalesce(pg_catalog.jsonb_agg(e), '[]'::jsonb)
                   FROM pg_catalog.jsonb_array_elements(v_map) e
                  WHERE NOT ((e ->> 'wd0')::integer = v_g.weekday AND (e ->> 'h0')::integer = v_g.hour_local));
  WHILE pg_catalog.jsonb_array_length(v_restants) > 0 LOOP
    v_trouve := false;
    FOR v_pret IN SELECT e FROM pg_catalog.jsonb_array_elements(v_restants) e LOOP
      -- Libre : aucune autre ligne, pas encore deplacee, n'occupe la case visee.
      IF NOT EXISTS (
           SELECT 1 FROM public.groupe_creneaux gc
            WHERE gc.groupe_id = p_groupe_id
              AND gc.weekday = (v_pret ->> 'wd1')::integer
              AND gc.hour_local = (v_pret ->> 'h1')::integer
              AND NOT ((v_pret ->> 'wd0')::integer = (v_pret ->> 'wd1')::integer
                       AND (v_pret ->> 'h0')::integer = (v_pret ->> 'h1')::integer)) THEN
        UPDATE public.groupe_creneaux gc
           SET weekday = (v_pret ->> 'wd1')::smallint,
               hour_local = (v_pret ->> 'h1')::smallint
         WHERE gc.groupe_id = p_groupe_id
           AND gc.weekday = (v_pret ->> 'wd0')::integer
           AND gc.hour_local = (v_pret ->> 'h0')::integer;
        v_restants := (SELECT coalesce(pg_catalog.jsonb_agg(e), '[]'::jsonb)
                         FROM pg_catalog.jsonb_array_elements(v_restants) e
                        WHERE e <> v_pret);
        v_trouve := true;
        EXIT;
      END IF;
    END LOOP;
    IF NOT v_trouve THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : creneaux de la classe % en cycle, conversion refusee', p_groupe_id
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  -- Un creneau attendu que l'ancre n'a pas pu poser (case alors occupee) :
  -- on le pose maintenant, avec sa duree.
  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
  SELECT p_groupe_id, (a ->> 'wd1')::smallint, (a ->> 'h1')::smallint, (a ->> 'duree')::smallint
    FROM pg_catalog.jsonb_array_elements(v_attendu) a
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;

  -- Controle apres : les creneaux sont exactement ceux attendus, avec leur duree.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'wd1', gc.weekday, 'h1', gc.hour_local, 'duree', gc.duree_minutes)
         ORDER BY gc.weekday, gc.hour_local), '[]'::jsonb)
    INTO v_final
    FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id;
  IF v_final IS DISTINCT FROM v_attendu THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : les creneaux de la classe % ne sont pas ceux attendus apres conversion (% au lieu de %)',
      p_groupe_id, v_final, v_attendu USING ERRCODE = 'P0001';
  END IF;

  -- Controle apres : aucune seance n'a bouge, ni en nombre ni en contenu.
  SELECT pg_catalog.count(*),
         coalesce(pg_catalog.md5(pg_catalog.string_agg(
           s.id::text || '|' || s.started_at::text || '|' || s.ended_at::text || '|' || s.status::text
           || '|' || coalesce(s.teacher_id::text, '') || '|' || (s.deleted_at IS NOT NULL)::text,
           ',' ORDER BY s.started_at, s.id)), '')
    INTO v_n_apres, v_emp_apres
    FROM public.sessions s WHERE s.groupe_id = p_groupe_id;
  IF v_n_apres <> v_n_avant OR v_emp_apres <> v_emp_avant THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : les seances de la classe % ont change pendant la conversion (% avant, % apres)',
      p_groupe_id, v_n_avant, v_n_apres USING ERRCODE = 'P0001';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'groupe_id', p_groupe_id, 'fuseau_avant', v_g.timezone_iana, 'fuseau_apres', v_academie,
    'creneaux', v_map, 'seances', v_n_avant);
END;
$function$;

REVOKE ALL ON FUNCTION private.convertir_classe_vers_academie(uuid, timestamptz)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.convertir_classe_vers_academie(uuid, timestamptz) IS
  'HORLOGE-ET-LIEU (12/11/2026) : convertit une classe vivante vers le fuseau de l''academie sans deplacer aucun instant (photographie des seances avant et apres, controle des occurrences, refus a moins de 28 jours d''un changement d''heure). Appelee par la migration et par la tache de nuit seulement. DEFINER, search_path vide, aucun EXECUTE client.';

-- La tache de nuit : pour le client deja en production, qui cree encore des
-- classes a l'heure murale du fuseau recu. Une classe refusee est signalee et
-- reessayee la nuit suivante ; elle n'arrete pas les autres.
CREATE FUNCTION private.convertir_classes_hors_academie(
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_academie text := private.fuseau_academie();
  v_groupe uuid;
  v_n integer := 0;
BEGIN
  FOR v_groupe IN
    SELECT g.id FROM public.groupes g
     WHERE g.ended_at IS NULL AND g.timezone_iana IS DISTINCT FROM v_academie
     ORDER BY g.id
  LOOP
    BEGIN
      IF private.convertir_classe_vers_academie(v_groupe, p_maintenant) IS NOT NULL THEN
        v_n := v_n + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'horloge : classe % non convertie (%, %)', v_groupe, SQLSTATE, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

REVOKE ALL ON FUNCTION private.convertir_classes_hors_academie(timestamptz)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.convertir_classes_hors_academie(timestamptz) IS
  'HORLOGE-ET-LIEU (12/11/2026) : tache de nuit, convertit les classes nees a l''heure murale d''un autre fuseau (ancien client). Une classe refusee est signalee en WARNING et reessayee. DEFINER, search_path vide, aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 5. Conversion des classes existantes (arret net au moindre ecart)
-- ---------------------------------------------------------------------------
DO $conversion$
DECLARE
  v_academie text := private.fuseau_academie();
  v_groupe uuid;
  v_n integer := 0;
  v_reste integer;
BEGIN
  FOR v_groupe IN
    SELECT g.id FROM public.groupes g
     WHERE g.ended_at IS NULL AND g.timezone_iana IS DISTINCT FROM v_academie
     ORDER BY g.id
  LOOP
    PERFORM private.convertir_classe_vers_academie(v_groupe);
    v_n := v_n + 1;
  END LOOP;
  SELECT pg_catalog.count(*) INTO v_reste
    FROM public.groupes g
   WHERE g.ended_at IS NULL AND g.timezone_iana IS DISTINCT FROM v_academie;
  IF v_reste <> 0 THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : % classe(s) vivante(s) restent hors du fuseau de l''academie', v_reste;
  END IF;
  RAISE NOTICE 'HORLOGE-ET-LIEU : % classe(s) vivante(s) convertie(s) vers %', v_n, v_academie;
END
$conversion$;

-- ---------------------------------------------------------------------------
-- 6. La tache de nuit planifiee (pg_cron absente : rien, comme les autres)
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $c$SELECT cron.schedule('horloge_academie', '47 2 * * *',
      'SELECT private.convertir_classes_hors_academie()')$c$;
  ELSE
    RAISE NOTICE 'HORLOGE-ET-LIEU : pg_cron absente, rien n''est planifie';
  END IF;
END
$planification$;

-- ---------------------------------------------------------------------------
-- 7. L'horloge de l'academie dans mon_horloge (copie complete, une cle de plus)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mon_horloge()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'horloge non autorisee' USING ERRCODE = '42501';
  END IF;
  -- Le meme ordre que public.mon_fuseau(), sans son repli sur Paris : un
  -- profil sans fuseau ne recoit pas une ville inventee.
  SELECT nullif(pg_catalog.btrim(h.timezone), '') INTO v_fuseau
    FROM public.households h
   WHERE h.id = public.app_household_id() AND h.deleted_at IS NULL;
  IF v_fuseau IS NULL THEN
    SELECT nullif(pg_catalog.btrim(tp.timezone_iana), '') INTO v_fuseau
      FROM public.teacher_profiles tp
     WHERE tp.profile_id = auth.uid() AND tp.deleted_at IS NULL;
  END IF;
  -- HORLOGE-ET-LIEU : `academie` est l'horloge de reference de l'ecole
  -- (La Mecque), montree en second apres l'heure de la personne.
  RETURN pg_catalog.jsonb_build_object(
    'maintenant', pg_catalog.now(),
    'moi', private.fuseau_info(v_fuseau),
    'academie', private.fuseau_info(private.fuseau_academie()));
END;
$function$;

-- L'empreinte F86 de mon_horloge suit sa nouvelle definition.
DO $empreinte$
DECLARE
  v_ancien text := pg_catalog.obj_description('public.mon_horloge()'::pg_catalog.regprocedure, 'pg_proc');
  v_nouveau text;
BEGIN
  IF v_ancien IS NOT NULL THEN
    v_nouveau := pg_catalog.regexp_replace(
      v_ancien, 'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mon_horloge()'::pg_catalog.regprocedure)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.mon_horloge() IS %L', v_nouveau);
  END IF;
END
$empreinte$;

-- ---------------------------------------------------------------------------
-- 8. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
  v_r text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.fuseau_academie()',
    'private.conversion_horloge_groupe(uuid,integer,integer,text,integer,integer,text)',
    'private.conversion_horloge_creneau(uuid,integer,integer,integer,integer)',
    'private.convertir_classe_vers_academie(uuid,timestamp with time zone)',
    'private.convertir_classes_hors_academie(timestamp with time zone)']
  LOOP
    FOREACH v_r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
      IF pg_catalog.has_function_privilege(v_r, v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
        RAISE EXCEPTION 'HORLOGE-ET-LIEU : % peut executer %', v_r, v_f;
      END IF;
    END LOOP;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.mon_horloge()'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.mon_horloge()'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de mon_horloge changes';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.conversions_horloge'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : RLS absente sur private.conversions_horloge';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.conversions_horloge', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.conversions_horloge', 'SELECT') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : private.conversions_horloge lisible par un client';
  END IF;
END
$postflight$;

COMMIT;
