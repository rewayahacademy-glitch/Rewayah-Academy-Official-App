-- HORLOGE-ET-LIEU, partie B : la ville de chacun (decision H5 et H6 ; migrations
-- 20261123940200 a 20261123943000).
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque controle
-- reussi ecrit une ligne "HLB OK" ; un echec leve 'HLB ROUGE : ...'.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d3000000-0000-4000-8000-000000000001', 'hlb-admin@example.test'),
  ('d3000000-0000-4000-8000-0000000000e1', 'hlb-e1@example.test'),
  ('d3000000-0000-4000-8000-0000000000e2', 'hlb-e2@example.test'),
  ('d3000000-0000-4000-8000-0000000000e3', 'hlb-e3@example.test'),
  ('d3000000-0000-4000-8000-000000000b01', 'hlb-g1@example.test'),
  ('d3000000-0000-4000-8000-000000000b02', 'hlb-g2@example.test'),
  ('d3000000-0000-4000-8000-000000000c01', 'hlb-s1@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('d3000000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
  ('d3000000-0000-4000-8000-0000000000f2', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id, access_until)
VALUES
  ('d3000000-0000-4000-8000-000000000001', 'HLBADMIN00000001', 'admin', 'Fixture', 'Direction', 'active', 'female', NULL, NULL),
  ('d3000000-0000-4000-8000-0000000000e1', 'HLBTEACHER000E01', 'teacher', 'Fixture', 'Enseignante', 'provisional_active', 'female', NULL, NULL),
  ('d3000000-0000-4000-8000-0000000000e2', 'HLBTEACHER000E02', 'teacher', 'Fixture', 'Enseignant', 'provisional_active', 'male', NULL, NULL),
  ('d3000000-0000-4000-8000-0000000000e3', 'HLBTEACHER000E03', 'teacher', 'Fixture', 'Enseignante3', 'provisional_active', 'female', NULL, NULL),
  ('d3000000-0000-4000-8000-000000000b01', 'HLBGUARD00000B01', 'guardian', 'Fixture', 'Tuteur1', 'active', 'male', 'd3000000-0000-4000-8000-0000000000f1', NULL),
  ('d3000000-0000-4000-8000-000000000b02', 'HLBGUARD00000B02', 'guardian', 'Fixture', 'Tuteur2', 'active', 'male', 'd3000000-0000-4000-8000-0000000000f2', NULL),
  ('d3000000-0000-4000-8000-000000000c01', 'HLBSTUD000000C01', 'student', 'Fixture', 'Eleve1', 'active', 'female', 'd3000000-0000-4000-8000-0000000000f1', NULL);
UPDATE public.households SET primary_guardian_id = 'd3000000-0000-4000-8000-000000000b01' WHERE id = 'd3000000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = 'd3000000-0000-4000-8000-000000000b02' WHERE id = 'd3000000-0000-4000-8000-0000000000f2';
-- Le cas connu : une enseignante enregistree en Guinee a l'heure de Paris ; un
-- enseignant enregistre en France a l'heure de Paris (rien a dire).
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES ('d3000000-0000-4000-8000-0000000000e1', 'Guinée', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
       ('d3000000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
       ('d3000000-0000-4000-8000-0000000000e3', 'Guinée', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);
-- Les disponibilites de l'enseignante (7 x 24, a l'heure de Paris, comme la production).
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT 'd3000000-0000-4000-8000-0000000000e1'::uuid, j, h, 'Europe/Paris'
  FROM pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(0, 23) AS h;

CREATE FUNCTION pg_temp.en_tant(p_uid uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE sql AS $f$
  SELECT set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('test.uid', p_uid::text, true),
         set_config('request.jwt.claims', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role) ::jsonb || coalesce(pg_catalog.jsonb_build_object('household_id', p_foyer), '{}'::jsonb))::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role) ::jsonb || coalesce(pg_catalog.jsonb_build_object('household_id', p_foyer), '{}'::jsonb))::text, true);
$f$;

-- =====================================================================
-- (1) La recherche des villes
-- =====================================================================
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000b01', 'guardian', 'd3000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
DO $r$
DECLARE
  v_n integer;
  v_premiere record;
BEGIN
  -- Par le debut du nom, sans accent ni majuscule.
  SELECT * INTO v_premiere FROM public.rechercher_villes('mak');
  IF v_premiere.nom IS DISTINCT FROM 'Makkah' OR v_premiere.fuseau_iana <> 'Asia/Riyadh' OR v_premiere.pays_code <> 'SA' THEN
    RAISE EXCEPTION 'HLB ROUGE : « mak » : %', pg_catalog.to_json(v_premiere);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.rechercher_villes('NAJRAN')) OR NOT EXISTS (SELECT 1 FROM public.rechercher_villes('najrān')) THEN
    RAISE EXCEPTION 'HLB ROUGE : la recherche ne passe pas les accents et les majuscules';
  END IF;
  -- Par le nom arabe (pays arabes).
  IF NOT EXISTS (SELECT 1 FROM public.rechercher_villes('الرياض') WHERE nom = 'Riyadh') THEN
    RAISE EXCEPTION 'HLB ROUGE : Riyad introuvable par son nom arabe';
  END IF;
  -- Plusieurs villes de meme nom : la region les distingue, la plus grande d'abord.
  SELECT pg_catalog.count(*) INTO v_n FROM public.rechercher_villes('springfield', NULL, 30);
  IF v_n < 2 OR NOT EXISTS (SELECT 1 FROM public.rechercher_villes('springfield') WHERE region IS NOT NULL) THEN
    RAISE EXCEPTION 'HLB ROUGE : les villes homonymes (% trouvees) ne se distinguent pas par leur region', v_n;
  END IF;
  -- Le pays filtre ; jamais plus de 30 lignes ; moins de deux lettres : rien.
  IF EXISTS (SELECT 1 FROM public.rechercher_villes('par', 'FR') WHERE pays_code <> 'FR')
     OR (SELECT pg_catalog.count(*) FROM public.rechercher_villes('a', NULL, 500)) <> 0
     OR (SELECT pg_catalog.count(*) FROM public.rechercher_villes('sa', NULL, 500)) > 30 THEN
    RAISE EXCEPTION 'HLB ROUGE : filtre de pays, plafond de 30 lignes ou recherche trop courte';
  END IF;
  -- Les propositions : par le decalage de l'appareil.
  IF NOT EXISTS (SELECT 1 FROM public.villes_proposees(180) WHERE nom = 'Riyadh')
     OR NOT EXISTS (SELECT 1 FROM public.villes_proposees(210) WHERE pays_code = 'IR')
     OR NOT EXISTS (SELECT 1 FROM public.villes_proposees(330) WHERE pays_code = 'IN')
     OR NOT EXISTS (SELECT 1 FROM public.villes_proposees(345) WHERE pays_code = 'NP')
     OR (SELECT pg_catalog.count(*) FROM public.villes_proposees(60, 500)) > 20
     OR EXISTS (SELECT 1 FROM public.villes_proposees(9999)) THEN
    RAISE EXCEPTION 'HLB ROUGE : les propositions par decalage (180 Riyad, 210 Iran, 330 Inde, 345 Nepal, plafond de 20)';
  END IF;
  RAISE NOTICE 'HLB OK : recherche par debut de nom (accents, majuscules, arabe, homonymes, pays, plafond de 30) et propositions par decalage (Riyad, Iran, Inde, Nepal)';
END
$r$;
-- Un compte non connecte ne cherche pas ; la table n'est lisible par personne.
RESET ROLE;
SET LOCAL ROLE anon;
DO $r2$
BEGIN
  BEGIN
    PERFORM public.rechercher_villes('paris');
    RAISE EXCEPTION 'HLB ROUGE : un anonyme a cherche une ville';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$r2$;
RESET ROLE;
SET LOCAL ROLE authenticated;
DO $r3$
BEGIN
  BEGIN
    PERFORM 1 FROM public.villes_ref;
    RAISE EXCEPTION 'HLB ROUGE : villes_ref est lisible par un client';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO public.villes_ref (id, nom, pays_code, fuseau_iana, latitude, longitude) VALUES (1, 'x', 'FR', 'Europe/Paris', 1, 1);
    RAISE EXCEPTION 'HLB ROUGE : un client a ecrit dans villes_ref';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM 1 FROM public.lieux;
    RAISE EXCEPTION 'HLB ROUGE : lieux est lisible par un client';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'HLB OK : un anonyme ne cherche pas ; un client ne lit ni n''ecrit villes_ref, ne lit pas lieux';
END
$r3$;
RESET ROLE;

-- =====================================================================
-- (2) L'etape pour les inscrits : requise, reportable trois fois, jamais plus
-- =====================================================================
SET LOCAL ROLE authenticated;
DO $e$
DECLARE
  v jsonb;
BEGIN
  v := public.mon_lieu_a_fournir();
  IF NOT (v ->> 'requis')::boolean OR (v ->> 'reports_restants')::integer <> 3 OR (v ->> 'reports_max')::integer <> 3 THEN
    RAISE EXCEPTION 'HLB ROUGE : etat de depart du tuteur : %', v;
  END IF;
  FOR i IN 1..3 LOOP
    v := public.reporter_ma_ville();
  END LOOP;
  IF (v ->> 'reports_restants')::integer <> 0 OR NOT (v ->> 'requis')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : apres trois reports : %', v;
  END IF;
  BEGIN
    PERFORM public.reporter_ma_ville();
    RAISE EXCEPTION 'HLB ROUGE : un quatrieme report a ete accepte';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    IF SQLERRM <> 'reports_epuises' THEN RAISE EXCEPTION 'HLB ROUGE : mauvais refus : %', SQLERRM; END IF;
  END;
  RAISE NOTICE 'HLB OK : l''etape est requise, reportable trois fois, le quatrieme report est refuse';
END
$e$;
RESET ROLE;

-- =====================================================================
-- (3) Choisir sa ville (tuteur) : le serveur recopie tout, le client n'envoie qu'un identifiant
-- =====================================================================
SET LOCAL ROLE authenticated;
DO $c$
DECLARE
  v_paris bigint;
  v_conakry bigint;
  v jsonb;
  l record;
BEGIN
  RESET ROLE;
  SELECT id INTO v_paris FROM public.villes_ref WHERE nom_recherche = 'paris' AND pays_code = 'FR' ORDER BY milliers DESC LIMIT 1;
  SELECT id INTO v_conakry FROM public.villes_ref WHERE nom_recherche = 'conakry' AND pays_code = 'GN' ORDER BY milliers DESC LIMIT 1;
  IF v_paris IS NULL OR v_conakry IS NULL THEN
    RAISE EXCEPTION 'HLB ROUGE : Paris ou Conakry manque a la liste';
  END IF;
  PERFORM set_config('hlb.paris', v_paris::text, true);
  PERFORM set_config('hlb.conakry', v_conakry::text, true);
  SET LOCAL ROLE authenticated;
  -- Une ville inconnue : refus net.
  BEGIN
    PERFORM public.enregistrer_ma_ville(-1);
    RAISE EXCEPTION 'HLB ROUGE : une ville inconnue est acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  v := public.enregistrer_ma_ville(v_conakry);
  IF v ->> 'ville' <> 'Conakry' OR v ->> 'pays_code' <> 'GN' OR v ->> 'fuseau_iana' <> 'Africa/Conakry'
     OR (v ->> 'disponibilites_a_relire')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : reponse du tuteur : %', v;
  END IF;
  RESET ROLE;
  -- Le fuseau du foyer a suivi, dans la meme transaction ; les coordonnees viennent de la liste.
  IF (SELECT h.timezone FROM public.households h WHERE h.id = 'd3000000-0000-4000-8000-0000000000f1') <> 'Africa/Conakry' THEN
    RAISE EXCEPTION 'HLB ROUGE : le fuseau du foyer n''a pas suivi la ville';
  END IF;
  SELECT l2.ville, l2.latitude, l2.longitude, v2.latitude AS la, v2.longitude AS lo INTO l
    FROM public.lieux l2 JOIN public.villes_ref v2 ON v2.id = l2.ville_id
   WHERE l2.foyer_id = 'd3000000-0000-4000-8000-0000000000f1';
  IF l.latitude IS DISTINCT FROM l.la OR l.longitude IS DISTINCT FROM l.lo THEN
    RAISE EXCEPTION 'HLB ROUGE : les coordonnees ne sont pas celles de la liste';
  END IF;
  -- L'etape n'est plus requise ; mon_horloge dit que la ville est choisie.
  SET LOCAL ROLE authenticated;
  IF (public.mon_lieu_a_fournir() ->> 'requis')::boolean
     OR NOT (public.mon_horloge() ->> 'lieu_choisi')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : la ville choisie n''est pas reconnue';
  END IF;
  -- Le lieu se lit : la ville et ses coordonnees, a la personne seule.
  v := public.mon_lieu();
  IF v ->> 'ville' <> 'Conakry' OR v -> 'latitude' IS NULL OR (v ->> 'verifie')::boolean OR v ->> 'source' <> 'foyer' THEN
    RAISE EXCEPTION 'HLB ROUGE : mon_lieu du tuteur : %', v;
  END IF;
  -- Changer d'avis : la ligne est remplacee, pas dupliquee.
  PERFORM public.enregistrer_ma_ville(v_paris);
  RESET ROLE;
  IF (SELECT pg_catalog.count(*) FROM public.lieux WHERE foyer_id = 'd3000000-0000-4000-8000-0000000000f1') <> 1
     OR (SELECT h.timezone FROM public.households h WHERE h.id = 'd3000000-0000-4000-8000-0000000000f1') <> 'Europe/Paris' THEN
    RAISE EXCEPTION 'HLB ROUGE : changer de ville a duplique la ligne ou oublie le fuseau';
  END IF;
  RAISE NOTICE 'HLB OK : le tuteur choisit sa ville (identifiant seul), le serveur recopie nom, pays, fuseau et coordonnees, le fuseau du foyer suit, l''etape n''est plus requise, changer de ville remplace la ligne';
END
$c$;

-- =====================================================================
-- (4) La ville n'est lue que par la personne, son foyer et la direction
-- =====================================================================
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000b02', 'guardian', 'd3000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
DO $p$
DECLARE
  v jsonb;
BEGIN
  -- Un autre foyer n'a aucune ville (la sienne est a fournir) et ne lit pas celle du premier.
  IF public.mon_lieu() IS NOT NULL OR NOT (public.mon_lieu_a_fournir() ->> 'requis')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : un autre foyer voit la ville du premier, ou n''est pas invite a choisir la sienne';
  END IF;
  -- Un tuteur ne lit pas le lieu d'un enseignant, ni ne le verifie.
  BEGIN
    PERFORM public.lire_lieu_enseignant('d3000000-0000-4000-8000-0000000000e1');
    RAISE EXCEPTION 'HLB ROUGE : un tuteur lit le lieu d''un enseignant';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.verifier_lieu_enseignant('d3000000-0000-4000-8000-0000000000e1');
    RAISE EXCEPTION 'HLB ROUGE : un tuteur verifie le lieu d''un enseignant';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM * FROM public.incoherences_lieu_direction();
    RAISE EXCEPTION 'HLB ROUGE : un tuteur lit les incoherences';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM * FROM public.lieux_enseignants_direction();
    RAISE EXCEPTION 'HLB ROUGE : un tuteur lit les villes des enseignants';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'HLB OK : un autre foyer ne lit pas la ville du premier ; un tuteur ne lit ni ne verifie le lieu d''un enseignant, ne lit pas les incoherences';
END
$p$;
RESET ROLE;
-- Un eleve ou un compte sans role de ville ne choisit rien.
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000c01', 'student', 'd3000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
DO $p2$
BEGIN
  IF public.mon_lieu() IS NOT NULL OR (public.mon_lieu_a_fournir() ->> 'requis')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : un eleve se voit demander une ville ou en lit une';
  END IF;
  BEGIN
    PERFORM public.enregistrer_ma_ville(current_setting('hlb.paris')::bigint);
    RAISE EXCEPTION 'HLB ROUGE : un eleve a choisi une ville';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'HLB OK : un eleve (enfant) n''a rien a saisir et ne choisit rien : il herite de la ville de son foyer';
END
$p2$;
RESET ROLE;

-- =====================================================================
-- (5) L'enseignant : sa ville, son pays, son fuseau ; ses disponibilites gardent leurs instants
-- =====================================================================
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-0000000000e1', 'teacher');
SET LOCAL ROLE authenticated;
DO $t$
DECLARE
  v jsonb;
  v_n_avant integer;
BEGIN
  v := public.mon_lieu_a_fournir();
  IF NOT (v ->> 'requis')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : l''enseignante sans ville n''est pas invitee a la choisir';
  END IF;
  RESET ROLE;
  SELECT pg_catalog.count(*) INTO v_n_avant FROM public.weekly_availability WHERE profile_id = 'd3000000-0000-4000-8000-0000000000e1';
  SET LOCAL ROLE authenticated;
  v := public.enregistrer_ma_ville(current_setting('hlb.conakry')::bigint);
  IF NOT (v ->> 'disponibilites_a_relire')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : changer de fuseau ne demande pas a l''enseignante de relire ses disponibilites';
  END IF;
  RESET ROLE;
  IF (SELECT tp.timezone_iana || '/' || tp.country FROM public.teacher_profiles tp WHERE tp.profile_id = 'd3000000-0000-4000-8000-0000000000e1') <> 'Africa/Conakry/GN' THEN
    RAISE EXCEPTION 'HLB ROUGE : fuseau et pays de l''enseignante apres la ville';
  END IF;
  -- Aucune ligne de disponibilite n'a ete touchee : chacune garde son fuseau (donc son instant).
  IF (SELECT pg_catalog.count(*) FROM public.weekly_availability
       WHERE profile_id = 'd3000000-0000-4000-8000-0000000000e1' AND timezone_iana = 'Europe/Paris') <> v_n_avant THEN
    RAISE EXCEPTION 'HLB ROUGE : les disponibilites ont change avec la ville (elles gardent leurs instants)';
  END IF;
  RAISE NOTICE 'HLB OK : la ville d''une enseignante met a jour son fuseau et son pays (code ISO), lui dit de relire ses % disponibilites, sans en toucher une', v_n_avant;
END
$t$;
RESET ROLE;

-- =====================================================================
-- (6) La direction : lire, verifier, signaler (sans rien corriger)
-- =====================================================================
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
DO $d$
DECLARE
  v jsonb;
  v_avant text;
  v_apres text;
BEGIN
  v := public.lire_lieu_enseignant('d3000000-0000-4000-8000-0000000000e1');
  IF v ->> 'ville' <> 'Conakry' OR (v ->> 'verifie')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : la direction lit mal le lieu : %', v;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.lieux_enseignants_direction() WHERE ville = 'Conakry' AND NOT verifie) THEN
    RAISE EXCEPTION 'HLB ROUGE : la liste des villes des enseignants';
  END IF;
  PERFORM public.verifier_lieu_enseignant('d3000000-0000-4000-8000-0000000000e1');
  IF NOT (public.lire_lieu_enseignant('d3000000-0000-4000-8000-0000000000e1') ->> 'verifie')::boolean THEN
    RAISE EXCEPTION 'HLB ROUGE : la verification n''est pas enregistree';
  END IF;
  -- Verifier la ville d'un enseignant qui n'en a pas choisi : refus.
  BEGIN
    PERFORM public.verifier_lieu_enseignant('d3000000-0000-4000-8000-0000000000e2');
    RAISE EXCEPTION 'HLB ROUGE : verification d''une ville inexistante';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  -- La liste des comptes de la direction ne porte ni coordonnees ni ville.
  IF EXISTS (SELECT 1 FROM public.lieux_enseignants_direction() l WHERE pg_catalog.to_jsonb(l) ? 'latitude') THEN
    RAISE EXCEPTION 'HLB ROUGE : des coordonnees dans la liste de la direction';
  END IF;
  RAISE NOTICE 'HLB OK : la direction lit le lieu d''un enseignant, le verifie, voit la liste de leurs villes ; verifier une ville absente est refuse';

  -- Changer de ville retire la verification.
  RESET ROLE;
  PERFORM pg_temp.en_tant('d3000000-0000-4000-8000-0000000000e1', 'teacher');
  SET LOCAL ROLE authenticated;
  PERFORM public.enregistrer_ma_ville(current_setting('hlb.paris')::bigint);
  RESET ROLE;
  IF EXISTS (SELECT 1 FROM public.lieux WHERE profil_id = 'd3000000-0000-4000-8000-0000000000e1' AND verifie_le IS NOT NULL) THEN
    RAISE EXCEPTION 'HLB ROUGE : la verification a survecu au changement de ville';
  END IF;
  RAISE NOTICE 'HLB OK : un enseignant qui change de ville perd la verification de la direction';
END
$d$;
RESET ROLE;

-- Les incoherences : l'enseignante 3 est « Guinee a l'heure de Paris » comme en
-- production, sans ville ; elle est signalee, rien n'est corrige.
CREATE TEMP TABLE hlb_avant AS
SELECT (SELECT pg_catalog.count(*) FROM public.lieux) AS lieux,
       (SELECT pg_catalog.md5(pg_catalog.string_agg(tp::text, '|' ORDER BY tp.profile_id)) FROM public.teacher_profiles tp) AS enseignants,
       (SELECT pg_catalog.md5(pg_catalog.string_agg(h::text, '|' ORDER BY h.id)) FROM public.households h) AS foyers;
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
DO $i$
DECLARE
  v_n integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.incoherences_lieu_direction()
                  WHERE profil_id = 'd3000000-0000-4000-8000-0000000000e3' AND type = 'pays_fuseau'
                    AND detail = 'pays GN, fuseau Europe/Paris') THEN
    RAISE EXCEPTION 'HLB ROUGE : le cas connu (Guinee, Europe/Paris) n''est pas signale : %',
      (SELECT pg_catalog.json_agg(pg_catalog.to_json(x)) FROM public.incoherences_lieu_direction() x);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.incoherences_lieu_direction()
                  WHERE profil_id = 'd3000000-0000-4000-8000-0000000000e3' AND type = 'sans_ville') THEN
    RAISE EXCEPTION 'HLB ROUGE : l''enseignante sans ville n''est pas signalee';
  END IF;
  -- L'enseignant France / Paris est coherent (hors « sans ville ») ; le foyer 2 sans ville est signale.
  IF EXISTS (SELECT 1 FROM public.incoherences_lieu_direction()
              WHERE profil_id = 'd3000000-0000-4000-8000-0000000000e2' AND type <> 'sans_ville') THEN
    RAISE EXCEPTION 'HLB ROUGE : un enseignant coherent est signale a tort';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.incoherences_lieu_direction()
                  WHERE profil_id = 'd3000000-0000-4000-8000-000000000b02' AND type = 'sans_ville') THEN
    RAISE EXCEPTION 'HLB ROUGE : le foyer sans ville n''est pas signale';
  END IF;
  RESET ROLE;
  -- Un fuseau different de celui de la ville est signale, sans rien corriger.
  UPDATE public.households SET timezone = 'Asia/Tokyo' WHERE id = 'd3000000-0000-4000-8000-0000000000f1';
  SET LOCAL ROLE authenticated;
  IF NOT EXISTS (SELECT 1 FROM public.incoherences_lieu_direction()
                  WHERE profil_id = 'd3000000-0000-4000-8000-000000000b01' AND type = 'fuseau_different_ville') THEN
    RAISE EXCEPTION 'HLB ROUGE : un fuseau different de celui de la ville n''est pas signale';
  END IF;
  RESET ROLE;
  RAISE NOTICE 'HLB OK : le cas connu (Guinee, Europe/Paris) est signale, ainsi que les personnes sans ville et un fuseau different de celui de la ville ; un enseignant coherent ne l''est pas';
END
$i$;
RESET ROLE;
-- La fonction n'a corrige ni modifie quoi que ce soit (seul le fuseau du foyer a ete change par le test).
DO $i2$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM public.lieux) <> (SELECT lieux FROM hlb_avant)
     OR (SELECT pg_catalog.md5(pg_catalog.string_agg(tp::text, '|' ORDER BY tp.profile_id)) FROM public.teacher_profiles tp)
        <> (SELECT enseignants FROM hlb_avant) THEN
    RAISE EXCEPTION 'HLB ROUGE : les signalements ont modifie des donnees';
  END IF;
  RAISE NOTICE 'HLB OK : les signalements ne corrigent rien (lieux et enseignants inchanges)';
END
$i2$;

-- =====================================================================
-- (7) Droits et mon_horloge sans ville choisie
-- =====================================================================
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000b02', 'guardian', 'd3000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
DO $h$
BEGIN
  IF (public.mon_horloge() ->> 'lieu_choisi')::boolean OR public.mon_horloge() -> 'moi' ->> 'fuseau' <> 'Europe/Paris' THEN
    RAISE EXCEPTION 'HLB ROUGE : mon_horloge sans ville choisie : %', public.mon_horloge();
  END IF;
  RAISE NOTICE 'HLB OK : mon_horloge dit « ville pas choisie » (le fuseau par defaut n''est pas un choix) et garde le fuseau connu';
END
$h$;
RESET ROLE;
DO $f$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['private.pays_depuis_texte(text)', 'private.proprietaire_lieu()', 'private.lieu_de_profil(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HLB ROUGE : % executable par un client', v_f;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY['public.enregistrer_ma_ville(bigint)', 'public.mon_lieu()', 'public.mon_lieu_a_fournir()',
    'public.reporter_ma_ville()', 'public.lire_lieu_enseignant(uuid)', 'public.verifier_lieu_enseignant(uuid)',
    'public.lieux_enseignants_direction()', 'public.incoherences_lieu_direction()', 'public.rechercher_villes(text,text,integer)',
    'public.villes_proposees(integer,integer)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HLB ROUGE : % executable par anon', v_f;
    END IF;
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'HLB ROUGE : % n''est pas DEFINER a search_path vide', v_f;
    END IF;
  END LOOP;
  RAISE NOTICE 'HLB OK : aucun EXECUTE pour anon, fonctions internes fermees, DEFINER a search_path vide partout';
END
$f$;

-- =====================================================================
-- (8) Apercu d'une offre a l'inscription : « 18:00 a Paris » se lit 17:00 ou
-- 16:00 a Conakry selon la saison, et change au prochain changement d'heure de Paris
-- =====================================================================
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, publiee_at, publiee_par, created_by)
SELECT 'd3000000-0000-4000-8000-00000000a001', 'enfant', (SELECT code FROM public.langues_cours ORDER BY code LIMIT 1),
       'Europe/Paris', ARRAY[3]::smallint[], 18, 45, 'publiee', pg_catalog.now(),
       'd3000000-0000-4000-8000-000000000001', 'd3000000-0000-4000-8000-000000000001';
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, created_by)
SELECT 'd3000000-0000-4000-8000-00000000a002', 'enfant', (SELECT code FROM public.langues_cours ORDER BY code LIMIT 1),
       'Europe/Paris', ARRAY[4]::smallint[], 18, 45, 'brouillon', 'd3000000-0000-4000-8000-000000000001';
SELECT pg_temp.en_tant('d3000000-0000-4000-8000-000000000b02', 'guardian', 'd3000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
DO $o$
DECLARE
  v_conakry jsonb := public.apercu_offre_horaire('d3000000-0000-4000-8000-00000000a001', 'Africa/Conakry');
  v_paris jsonb := public.apercu_offre_horaire('d3000000-0000-4000-8000-00000000a001', 'Europe/Paris');
  v_brouillon jsonb := public.apercu_offre_horaire('d3000000-0000-4000-8000-00000000a002', 'Africa/Conakry');
BEGIN
  IF (v_conakry ->> 'meme')::boolean
     OR v_conakry ->> 'heure_apres' IS NULL
     OR v_conakry ->> 'maintenant' = v_conakry ->> 'heure_apres'
     OR (v_conakry ->> 'jour_maintenant')::int <> 3 THEN
    RAISE EXCEPTION 'HLB ROUGE : apercu d''une offre de Paris lue a Conakry : %', v_conakry;
  END IF;
  IF NOT (v_paris ->> 'meme')::boolean OR v_paris ->> 'maintenant' <> '18:00' THEN
    RAISE EXCEPTION 'HLB ROUGE : l''offre lue a Paris ne doit pas bouger : %', v_paris;
  END IF;
  IF v_brouillon IS NOT NULL THEN
    RAISE EXCEPTION 'HLB ROUGE : une offre non publiee ne doit rien montrer : %', v_brouillon;
  END IF;
  RAISE NOTICE 'HLB OK : l''apercu d''une offre dit l''heure chez soi puis apres le changement d''heure (Conakry %, puis %), rien pour Paris, rien pour un brouillon',
    v_conakry ->> 'maintenant', v_conakry ->> 'heure_apres';
END
$o$;
RESET ROLE;
DO $f$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.apercu_offre_horaire(uuid,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HLB ROUGE : apercu_offre_horaire executable par anon';
  END IF;
  RAISE NOTICE 'HLB OK : apercu_offre_horaire fermee a anon';
END
$f$;

ROLLBACK;
