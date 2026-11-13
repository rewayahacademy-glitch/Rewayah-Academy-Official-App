-- HORLOGE-ET-LIEU, partie B (architecte pedagogique, 12/11/2026 ; decision H5 et H6,
-- docs/current/pedagogie/HORLOGE-ET-LIEU.md) : le lieu de chacun.
--
-- Chaque foyer (par son adulte) et chaque enseignant indique sa ville : une ligne de
-- `public.lieux`, qui est AUSSI le marqueur « ville choisie » (le fuseau par
-- defaut « Europe/Paris » des foyers et des enseignants n'a jamais ete un choix).
-- On enregistre le nom de la ville, le pays, le fuseau et les coordonnees du
-- CENTRE de la ville : jamais une adresse, jamais la position de l'appareil.
--
-- 1. public.lieux : une ligne par foyer ou par enseignant. RLS sans politique, aucun
--    droit client : on ne la lit et on ne l'ecrit que par les fonctions ci-dessous.
-- 2. public.enregistrer_ma_ville(ville) : le serveur recopie le nom, le pays, le
--    fuseau et les coordonnees de la ligne choisie ; le client n'envoie qu'un
--    identifiant. Il met a jour le fuseau du foyer ou de l'enseignant (et son pays)
--    dans la meme transaction. Les disponibilites de l'enseignant gardent leurs
--    instants (chaque ligne porte son fuseau) ; la reponse dit qu'il doit les relire.
-- 3. public.mon_lieu() : la lecture de la personne seule (et pour PRIERE-1, qui la
--    lira au lieu de ressaisir) ; private.lieu_de_profil : la lecture des fonctions
--    serveur ; public.lire_lieu_enseignant : la direction seule.
-- 4. public.mon_lieu_a_fournir() et public.reporter_ma_ville() : l'etape pour les
--    inscrits, avec un nombre de reports limite (reglage `lieu_reports_max`, 3).
-- 5. Direction : public.verifier_lieu_enseignant, public.lieux_enseignants_direction,
--    public.incoherences_lieu_direction (pays, fuseau et ville qui ne concordent
--    pas : elle SIGNALE, elle ne corrige rien).
-- 6. public.mon_horloge() rend aussi `lieu_choisi` (copie complete, une cle de plus).
--
-- FICHIER SANS EFFACEMENT : des objets crees, une fonction remplacee par sa copie
-- complete, aucune ligne effacee.

BEGIN;

DO $preflight$
DECLARE
  v_empreinte text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_empreinte
    FROM pg_catalog.pg_proc p WHERE p.oid = 'public.mon_horloge()'::pg_catalog.regprocedure;
  IF v_empreinte IS DISTINCT FROM 'f5a07a6164894efcc7e38e9e8ae00a90' THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : public.mon_horloge() a change depuis la partie A (empreinte %), migration refusee', v_empreinte;
  END IF;
END
$preflight$;

INSERT INTO public.app_config (key, value)
VALUES ('lieu_reports_max', '3'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Les noms francais des pays : pour reconnaitre le pays d'un enseignant ecrit en
-- texte libre (« Guinee »), seulement pour le signalement des incoherences.
CREATE TABLE private.pays_noms_fr (
  code      text PRIMARY KEY CHECK (code ~ '^[A-Z]{2}$'),
  nom       text NOT NULL,
  nom_norm  text GENERATED ALWAYS AS (private.normaliser_recherche(nom)) STORED
);
ALTER TABLE private.pays_noms_fr ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.pays_noms_fr FROM PUBLIC, anon, authenticated, service_role;
INSERT INTO private.pays_noms_fr (code, nom) VALUES
  ('AF', 'Afghanistan'),
  ('AX', 'Îles Åland'),
  ('AL', 'Albanie'),
  ('DZ', 'Algérie'),
  ('AS', 'Samoa américaines'),
  ('AD', 'Andorre'),
  ('AO', 'Angola'),
  ('AI', 'Anguilla'),
  ('AQ', 'Antarctique'),
  ('AG', 'Antigua-et-Barbuda'),
  ('AR', 'Argentine'),
  ('AM', 'Arménie'),
  ('AW', 'Aruba'),
  ('AU', 'Australie'),
  ('AT', 'Autriche'),
  ('AZ', 'Azerbaïdjan'),
  ('BS', 'Bahamas'),
  ('BH', 'Bahreïn'),
  ('BD', 'Bangladesh'),
  ('BB', 'Barbade'),
  ('BY', 'Biélorussie'),
  ('BE', 'Belgique'),
  ('BZ', 'Belize'),
  ('BJ', 'Bénin'),
  ('BM', 'Bermudes'),
  ('BT', 'Bhoutan'),
  ('BO', 'Bolivie'),
  ('BQ', 'Pays-Bas caribéens'),
  ('BA', 'Bosnie-Herzégovine'),
  ('BW', 'Botswana'),
  ('BV', 'Île Bouvet'),
  ('BR', 'Brésil'),
  ('IO', 'Territoire britannique de l''océan Indien'),
  ('BN', 'Brunei'),
  ('BG', 'Bulgarie'),
  ('BF', 'Burkina Faso'),
  ('BI', 'Burundi'),
  ('CV', 'Cap-Vert'),
  ('KH', 'Cambodge'),
  ('CM', 'Cameroun'),
  ('CA', 'Canada'),
  ('KY', 'Îles Caïmans'),
  ('CF', 'République centrafricaine'),
  ('TD', 'Tchad'),
  ('CL', 'Chili'),
  ('CN', 'Chine'),
  ('CX', 'Île Christmas'),
  ('CC', 'Îles Cocos'),
  ('CO', 'Colombie'),
  ('KM', 'Comores'),
  ('CG', 'Congo'),
  ('CD', 'République démocratique du Congo'),
  ('CK', 'Îles Cook'),
  ('CR', 'Costa Rica'),
  ('CI', 'Côte d''Ivoire'),
  ('HR', 'Croatie'),
  ('CU', 'Cuba'),
  ('CW', 'Curaçao'),
  ('CY', 'Chypre'),
  ('CZ', 'Tchéquie'),
  ('DK', 'Danemark'),
  ('DJ', 'Djibouti'),
  ('DM', 'Dominique'),
  ('DO', 'République dominicaine'),
  ('EC', 'Équateur'),
  ('EG', 'Égypte'),
  ('SV', 'Salvador'),
  ('GQ', 'Guinée équatoriale'),
  ('ER', 'Érythrée'),
  ('EE', 'Estonie'),
  ('SZ', 'Eswatini'),
  ('ET', 'Éthiopie'),
  ('FK', 'Îles Malouines'),
  ('FO', 'Îles Féroé'),
  ('FJ', 'Fidji'),
  ('FI', 'Finlande'),
  ('FR', 'France'),
  ('GF', 'Guyane française'),
  ('PF', 'Polynésie française'),
  ('TF', 'Terres australes françaises'),
  ('GA', 'Gabon'),
  ('GM', 'Gambie'),
  ('GE', 'Géorgie'),
  ('DE', 'Allemagne'),
  ('GH', 'Ghana'),
  ('GI', 'Gibraltar'),
  ('GR', 'Grèce'),
  ('GL', 'Groenland'),
  ('GD', 'Grenade'),
  ('GP', 'Guadeloupe'),
  ('GU', 'Guam'),
  ('GT', 'Guatemala'),
  ('GG', 'Guernesey'),
  ('GN', 'Guinée'),
  ('GW', 'Guinée-Bissau'),
  ('GY', 'Guyana'),
  ('HT', 'Haïti'),
  ('HM', 'Îles Heard-et-MacDonald'),
  ('VA', 'Vatican'),
  ('HN', 'Honduras'),
  ('HK', 'Hong Kong'),
  ('HU', 'Hongrie'),
  ('IS', 'Islande'),
  ('IN', 'Inde'),
  ('ID', 'Indonésie'),
  ('IR', 'Iran'),
  ('IQ', 'Irak'),
  ('IE', 'Irlande'),
  ('IM', 'Île de Man'),
  ('IL', 'Israël'),
  ('IT', 'Italie'),
  ('JM', 'Jamaïque'),
  ('JP', 'Japon'),
  ('JE', 'Jersey'),
  ('JO', 'Jordanie'),
  ('KZ', 'Kazakhstan'),
  ('KE', 'Kenya'),
  ('KI', 'Kiribati'),
  ('KP', 'Corée du Nord'),
  ('KR', 'Corée du Sud'),
  ('KW', 'Koweït'),
  ('KG', 'Kirghizistan'),
  ('LA', 'Laos'),
  ('LV', 'Lettonie'),
  ('LB', 'Liban'),
  ('LS', 'Lesotho'),
  ('LR', 'Libéria'),
  ('LY', 'Libye'),
  ('LI', 'Liechtenstein'),
  ('LT', 'Lituanie'),
  ('LU', 'Luxembourg'),
  ('MO', 'Macao'),
  ('MG', 'Madagascar'),
  ('MW', 'Malawi'),
  ('MY', 'Malaisie'),
  ('MV', 'Maldives'),
  ('ML', 'Mali'),
  ('MT', 'Malte'),
  ('MH', 'Îles Marshall'),
  ('MQ', 'Martinique'),
  ('MR', 'Mauritanie'),
  ('MU', 'Maurice'),
  ('YT', 'Mayotte'),
  ('MX', 'Mexique'),
  ('FM', 'Micronésie'),
  ('MD', 'Moldavie'),
  ('MC', 'Monaco'),
  ('MN', 'Mongolie'),
  ('ME', 'Monténégro'),
  ('MS', 'Montserrat'),
  ('MA', 'Maroc'),
  ('MZ', 'Mozambique'),
  ('MM', 'Birmanie'),
  ('NA', 'Namibie'),
  ('NR', 'Nauru'),
  ('NP', 'Népal'),
  ('NL', 'Pays-Bas'),
  ('NC', 'Nouvelle-Calédonie'),
  ('NZ', 'Nouvelle-Zélande'),
  ('NI', 'Nicaragua'),
  ('NE', 'Niger'),
  ('NG', 'Nigéria'),
  ('NU', 'Niue'),
  ('NF', 'Île Norfolk'),
  ('MK', 'Macédoine du Nord'),
  ('MP', 'Îles Mariannes du Nord'),
  ('NO', 'Norvège'),
  ('OM', 'Oman'),
  ('PK', 'Pakistan'),
  ('PW', 'Palaos'),
  ('PS', 'Palestine'),
  ('PA', 'Panama'),
  ('PG', 'Papouasie-Nouvelle-Guinée'),
  ('PY', 'Paraguay'),
  ('PE', 'Pérou'),
  ('PH', 'Philippines'),
  ('PN', 'Îles Pitcairn'),
  ('PL', 'Pologne'),
  ('PT', 'Portugal'),
  ('PR', 'Porto Rico'),
  ('QA', 'Qatar'),
  ('RE', 'La Réunion'),
  ('RO', 'Roumanie'),
  ('RU', 'Russie'),
  ('RW', 'Rwanda'),
  ('BL', 'Saint-Barthélemy'),
  ('SH', 'Sainte-Hélène'),
  ('KN', 'Saint-Christophe-et-Niévès'),
  ('LC', 'Sainte-Lucie'),
  ('MF', 'Saint-Martin (partie française)'),
  ('PM', 'Saint-Pierre-et-Miquelon'),
  ('VC', 'Saint-Vincent-et-les-Grenadines'),
  ('WS', 'Samoa'),
  ('SM', 'Saint-Marin'),
  ('ST', 'Sao Tomé-et-Principe'),
  ('SA', 'Arabie saoudite'),
  ('SN', 'Sénégal'),
  ('RS', 'Serbie'),
  ('SC', 'Seychelles'),
  ('SL', 'Sierra Leone'),
  ('SG', 'Singapour'),
  ('SX', 'Saint-Martin (partie néerlandaise)'),
  ('SK', 'Slovaquie'),
  ('SI', 'Slovénie'),
  ('SB', 'Îles Salomon'),
  ('SO', 'Somalie'),
  ('ZA', 'Afrique du Sud'),
  ('GS', 'Géorgie du Sud et îles Sandwich du Sud'),
  ('SS', 'Soudan du Sud'),
  ('ES', 'Espagne'),
  ('LK', 'Sri Lanka'),
  ('SD', 'Soudan'),
  ('SR', 'Suriname'),
  ('SJ', 'Svalbard et Jan Mayen'),
  ('SE', 'Suède'),
  ('CH', 'Suisse'),
  ('SY', 'Syrie'),
  ('TW', 'Taïwan'),
  ('TJ', 'Tadjikistan'),
  ('TZ', 'Tanzanie'),
  ('TH', 'Thaïlande'),
  ('TL', 'Timor oriental'),
  ('TG', 'Togo'),
  ('TK', 'Tokelau'),
  ('TO', 'Tonga'),
  ('TT', 'Trinité-et-Tobago'),
  ('TN', 'Tunisie'),
  ('TR', 'Turquie'),
  ('TM', 'Turkménistan'),
  ('TC', 'Îles Turques-et-Caïques'),
  ('TV', 'Tuvalu'),
  ('UG', 'Ouganda'),
  ('UA', 'Ukraine'),
  ('AE', 'Émirats arabes unis'),
  ('GB', 'Royaume-Uni'),
  ('US', 'États-Unis'),
  ('UM', 'Îles mineures éloignées des États-Unis'),
  ('UY', 'Uruguay'),
  ('UZ', 'Ouzbékistan'),
  ('VU', 'Vanuatu'),
  ('VE', 'Venezuela'),
  ('VN', 'Viêt Nam'),
  ('VG', 'Îles Vierges britanniques'),
  ('VI', 'Îles Vierges des États-Unis'),
  ('WF', 'Wallis-et-Futuna'),
  ('EH', 'Sahara occidental'),
  ('YE', 'Yémen'),
  ('ZM', 'Zambie'),
  ('ZW', 'Zimbabwe')
ON CONFLICT (code) DO NOTHING;

-- Le code ISO d'un pays ecrit en code (« FR ») ou en nom francais (« Guinee »),
-- ou NULL.
CREATE FUNCTION private.pays_depuis_texte(p_texte text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT i.code FROM private.pays_iso_3166 i WHERE i.code = upper(pg_catalog.btrim(p_texte))),
    (SELECT n.code FROM private.pays_noms_fr n WHERE n.nom_norm = private.normaliser_recherche(p_texte)));
$function$;

-- ---------------------------------------------------------------------------
-- 1. Le lieu
-- ---------------------------------------------------------------------------
CREATE TABLE public.lieux (
  id           uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  foyer_id     uuid         NULL UNIQUE REFERENCES public.households (id) ON DELETE CASCADE,
  profil_id    uuid         NULL UNIQUE REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT lieux_un_seul_proprietaire CHECK ((foyer_id IS NULL) <> (profil_id IS NULL)),
  ville_id     bigint       NOT NULL REFERENCES public.villes_ref (id),
  ville        text         NOT NULL,
  pays_code    char(2)      NOT NULL,
  fuseau_iana  text         NOT NULL,
  latitude     numeric(6,3) NOT NULL,
  longitude    numeric(7,3) NOT NULL,
  saisi_par    uuid         NOT NULL,
  cree_le      timestamptz  NOT NULL DEFAULT pg_catalog.now(),
  maj_le       timestamptz  NOT NULL DEFAULT pg_catalog.now(),
  verifie_par  uuid         NULL,
  verifie_le   timestamptz  NULL
);
ALTER TABLE public.lieux ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.lieux FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON TABLE public.lieux IS
  'HORLOGE-ET-LIEU (12/11/2026) : la ville d''un foyer ou d''un enseignant (centre de la ville, jamais une adresse) ; sa presence dit que la ville a ete CHOISIE. RLS sans politique, aucun droit client : on ne passe que par les fonctions du lieu.';

CREATE TABLE private.lieux_reports (
  profil_id  uuid        PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  reports    smallint    NOT NULL DEFAULT 0 CHECK (reports >= 0),
  dernier_le timestamptz NOT NULL DEFAULT pg_catalog.now()
);
ALTER TABLE private.lieux_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.lieux_reports FROM PUBLIC, anon, authenticated, service_role;

-- Qui est le proprietaire du lieu de l'appelant : (role, foyer). Le role et le
-- foyer se lisent dans le jeton.
CREATE FUNCTION private.proprietaire_lieu(OUT p_role text, OUT p_foyer uuid)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  p_role := public.app_role()::text;
  p_foyer := public.app_household_id();
  IF p_role = 'guardian' AND p_foyer IS NOT NULL THEN
    RETURN;
  ELSIF p_role = 'teacher' THEN
    p_foyer := NULL;
    RETURN;
  END IF;
  p_role := NULL;
  p_foyer := NULL;
END;
$function$;

-- Le lieu d'un profil (le foyer d'un tuteur, ou la ligne d'un enseignant), pour les
-- fonctions serveur (PRIERE-1, annonces). Aucun EXECUTE client.
CREATE FUNCTION private.lieu_de_profil(p_profil uuid)
RETURNS public.lieux
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT l.*
    FROM public.lieux l
   WHERE l.profil_id = p_profil
      OR l.foyer_id = (SELECT p.household_id FROM public.profiles p
                        WHERE p.id = p_profil AND p.role = 'guardian'::public.app_role)
   LIMIT 1;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Choisir sa ville
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.enregistrer_ma_ville(p_ville_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_foyer uuid;
  v_v public.villes_ref%ROWTYPE;
  v_ancien text;
  v_id uuid;
  v_relire boolean := false;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'ville non autorisee' USING ERRCODE = '42501';
  END IF;
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'la ville se choisit par un tuteur ou un enseignant' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_v FROM public.villes_ref WHERE id = p_ville_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ville inconnue' USING ERRCODE = '22023';
  END IF;

  IF v_role = 'guardian' THEN
    SELECT h.timezone INTO v_ancien FROM public.households h WHERE h.id = v_foyer AND h.deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'foyer introuvable' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.lieux (foyer_id, ville_id, ville, pays_code, fuseau_iana, latitude, longitude, saisi_par)
    VALUES (v_foyer, v_v.id, v_v.nom, v_v.pays_code, v_v.fuseau_iana, v_v.latitude, v_v.longitude, v_uid)
    ON CONFLICT (foyer_id) DO UPDATE
      SET ville_id = EXCLUDED.ville_id, ville = EXCLUDED.ville, pays_code = EXCLUDED.pays_code,
          fuseau_iana = EXCLUDED.fuseau_iana, latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude, saisi_par = EXCLUDED.saisi_par,
          maj_le = pg_catalog.now(), verifie_par = NULL, verifie_le = NULL
    RETURNING id INTO v_id;
    UPDATE public.households SET timezone = v_v.fuseau_iana WHERE id = v_foyer;
  ELSE
    SELECT tp.timezone_iana INTO v_ancien FROM public.teacher_profiles tp
     WHERE tp.profile_id = v_uid AND tp.deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'profil enseignant introuvable' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.lieux (profil_id, ville_id, ville, pays_code, fuseau_iana, latitude, longitude, saisi_par)
    VALUES (v_uid, v_v.id, v_v.nom, v_v.pays_code, v_v.fuseau_iana, v_v.latitude, v_v.longitude, v_uid)
    ON CONFLICT (profil_id) DO UPDATE
      SET ville_id = EXCLUDED.ville_id, ville = EXCLUDED.ville, pays_code = EXCLUDED.pays_code,
          fuseau_iana = EXCLUDED.fuseau_iana, latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude, saisi_par = EXCLUDED.saisi_par,
          maj_le = pg_catalog.now(), verifie_par = NULL, verifie_le = NULL
    RETURNING id INTO v_id;
    UPDATE public.teacher_profiles
       SET timezone_iana = v_v.fuseau_iana, country = v_v.pays_code
     WHERE profile_id = v_uid;
    -- Les disponibilites gardent leurs instants (chaque ligne porte son fuseau) :
    -- rien n'est converti ; l'enseignant doit les relire.
    v_relire := v_ancien IS DISTINCT FROM v_v.fuseau_iana
      AND EXISTS (SELECT 1 FROM public.weekly_availability w WHERE w.profile_id = v_uid);
  END IF;

  -- Le journal ne porte ni coordonnees ni nom de ville : l'identifiant et le pays.
  PERFORM public.log_sensitive_access(
    'lieu_enregistre', 'lieux', v_id::text,
    pg_catalog.jsonb_build_object('role', v_role, 'ville_id', v_v.id, 'pays', v_v.pays_code));

  RETURN pg_catalog.jsonb_build_object(
    'ville', v_v.nom, 'pays_code', v_v.pays_code, 'fuseau_iana', v_v.fuseau_iana,
    'disponibilites_a_relire', v_relire);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Lire son lieu
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.mon_lieu()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_role text;
  v_foyer uuid;
  v_l public.lieux%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'lieu non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT l.* INTO v_l FROM public.lieux l
   WHERE (v_role = 'guardian' AND l.foyer_id = v_foyer)
      OR (v_role = 'teacher' AND l.profil_id = auth.uid());
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'ville_id', v_l.ville_id, 'ville', v_l.ville, 'pays_code', v_l.pays_code,
    'fuseau_iana', v_l.fuseau_iana, 'latitude', v_l.latitude, 'longitude', v_l.longitude,
    'verifie', v_l.verifie_le IS NOT NULL, 'source', CASE v_role WHEN 'guardian' THEN 'foyer' ELSE 'enseignant' END);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. L'etape pour les inscrits : requise, et reportable un nombre limite de fois
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.mon_lieu_a_fournir()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_role text;
  v_foyer uuid;
  v_max integer := public.app_config_int('lieu_reports_max', 3);
  v_pris integer;
  v_a_un boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'lieu non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('requis', false, 'reports_restants', 0, 'reports_max', v_max);
  END IF;
  SELECT EXISTS (SELECT 1 FROM public.lieux l
                  WHERE (v_role = 'guardian' AND l.foyer_id = v_foyer)
                     OR (v_role = 'teacher' AND l.profil_id = auth.uid()))
    INTO v_a_un;
  IF v_a_un THEN
    RETURN pg_catalog.jsonb_build_object('requis', false, 'reports_restants', 0, 'reports_max', v_max);
  END IF;
  SELECT coalesce(pg_catalog.max(r.reports), 0) INTO v_pris
    FROM private.lieux_reports r WHERE r.profil_id = auth.uid();
  RETURN pg_catalog.jsonb_build_object(
    'requis', true, 'reports_restants', greatest(v_max - v_pris, 0), 'reports_max', v_max);
END;
$function$;

CREATE FUNCTION public.reporter_ma_ville()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_etat jsonb;
BEGIN
  v_etat := public.mon_lieu_a_fournir();
  IF NOT (v_etat ->> 'requis')::boolean THEN
    RETURN v_etat;
  END IF;
  IF (v_etat ->> 'reports_restants')::integer <= 0 THEN
    RAISE EXCEPTION 'reports_epuises' USING ERRCODE = 'P0001',
      DETAIL = 'la ville doit etre choisie maintenant';
  END IF;
  INSERT INTO private.lieux_reports (profil_id, reports, dernier_le)
  VALUES (auth.uid(), 1, pg_catalog.now())
  ON CONFLICT (profil_id) DO UPDATE
    SET reports = private.lieux_reports.reports + 1, dernier_le = pg_catalog.now();
  RETURN public.mon_lieu_a_fournir();
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. La direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.lire_lieu_enseignant(p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_l public.lieux%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''administration' USING ERRCODE = '42501';
  END IF;
  SELECT l.* INTO v_l FROM public.lieux l WHERE l.profil_id = p_profil;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'ville_id', v_l.ville_id, 'ville', v_l.ville, 'pays_code', v_l.pays_code,
    'fuseau_iana', v_l.fuseau_iana, 'latitude', v_l.latitude, 'longitude', v_l.longitude,
    'verifie', v_l.verifie_le IS NOT NULL, 'verifie_le', v_l.verifie_le, 'saisi_le', v_l.maj_le);
END;
$function$;

CREATE FUNCTION public.verifier_lieu_enseignant(p_profil uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''administration' USING ERRCODE = '42501';
  END IF;
  UPDATE public.lieux SET verifie_par = auth.uid(), verifie_le = pg_catalog.now()
   WHERE profil_id = p_profil;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'cet enseignant n''a pas encore choisi sa ville' USING ERRCODE = '22023';
  END IF;
  PERFORM public.log_sensitive_access('lieu_verifie', 'lieux', p_profil::text, '{}'::jsonb);
END;
$function$;

-- Les villes des enseignants, pour la liste de la direction : la ville, le pays, et
-- si elle est verifiee. Jamais de coordonnees.
CREATE FUNCTION public.lieux_enseignants_direction()
RETURNS TABLE (profil_id uuid, ville text, pays_code text, verifie boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''administration' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT l.profil_id, l.ville, l.pays_code::text, l.verifie_le IS NOT NULL
    FROM public.lieux l WHERE l.profil_id IS NOT NULL;
END;
$function$;

-- Les incoherences, signalees a la direction et jamais corrigees seules.
CREATE FUNCTION public.incoherences_lieu_direction()
RETURNS TABLE (profil_id uuid, role text, prenom text, nom text, type text, detail text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''administration' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  WITH personnes AS (
    -- Chaque enseignant et chaque tuteur actif, avec son fuseau enregistre et son lieu.
    SELECT p.id AS pid, 'teacher'::text AS r, p.first_name AS pn, p.last_name AS nm,
           tp.timezone_iana AS fuseau, tp.country AS pays_texte,
           (SELECT l FROM public.lieux l WHERE l.profil_id = p.id) AS lieu
      FROM public.profiles p
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id AND tp.deleted_at IS NULL
     WHERE p.role = 'teacher' AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
    UNION ALL
    SELECT p.id, 'guardian', p.first_name, p.last_name, h.timezone, NULL::text,
           (SELECT l FROM public.lieux l WHERE l.foyer_id = h.id)
      FROM public.profiles p
      JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
     WHERE p.role = 'guardian' AND p.deleted_at IS NULL AND p.account_status = 'active'
  )
  SELECT x.pid, x.r, x.pn, x.nm, x.t, x.d
    FROM (
      SELECT q.pid, q.r, q.pn, q.nm, 'sans_ville'::text AS t,
             'aucune ville choisie ; fuseau enregistre : ' || coalesce(q.fuseau, 'aucun') AS d
        FROM personnes q WHERE (q.lieu).id IS NULL
      UNION ALL
      SELECT q.pid, q.r, q.pn, q.nm, 'fuseau_different_ville',
             'fuseau enregistre ' || coalesce(q.fuseau, 'aucun') || ', fuseau de la ville ' || (q.lieu).fuseau_iana
        FROM personnes q WHERE (q.lieu).id IS NOT NULL AND q.fuseau IS DISTINCT FROM (q.lieu).fuseau_iana
      UNION ALL
      SELECT q.pid, q.r, q.pn, q.nm, 'pays_different_ville',
             'pays enregistre ' || q.pays_texte || ', pays de la ville ' || (q.lieu).pays_code
        FROM personnes q
       WHERE q.r = 'teacher' AND (q.lieu).id IS NOT NULL
         AND private.pays_depuis_texte(q.pays_texte) IS DISTINCT FROM (q.lieu).pays_code::text
      UNION ALL
      -- Le pays et le fuseau enregistres ne vont pas ensemble (aucune ville de ce pays
      -- n'est dans ce fuseau) : le cas d'une enseignante enregistree en Guinee a l'heure de Paris.
      SELECT q.pid, q.r, q.pn, q.nm, 'pays_fuseau',
             'pays ' || private.pays_depuis_texte(q.pays_texte) || ', fuseau ' || q.fuseau
        FROM personnes q
       WHERE q.r = 'teacher' AND q.fuseau IS NOT NULL
         AND private.pays_depuis_texte(q.pays_texte) IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM public.villes_ref v
                          WHERE v.pays_code = private.pays_depuis_texte(q.pays_texte)
                            AND v.fuseau_iana = q.fuseau)
    ) x
   ORDER BY x.t, x.nm, x.pn, x.pid;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. mon_horloge : `lieu_choisi` (copie complete, une cle de plus)
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
  v_role text;
  v_foyer uuid;
  v_choisi boolean := false;
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
  -- HORLOGE-ET-LIEU (partie B) : la ville a-t-elle ete CHOISIE ? Le fuseau par
  -- defaut (Paris) n'est pas un choix : sans ville choisie, l'ecran affiche l'heure
  -- de l'appareil et le dit.
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NOT NULL THEN
    SELECT EXISTS (SELECT 1 FROM public.lieux l
                    WHERE (v_role = 'guardian' AND l.foyer_id = v_foyer)
                       OR (v_role = 'teacher' AND l.profil_id = auth.uid()))
      INTO v_choisi;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'maintenant', pg_catalog.now(),
    'moi', private.fuseau_info(v_fuseau),
    'academie', private.fuseau_info(private.fuseau_academie()),
    'lieu_choisi', v_choisi);
END;
$function$;

DO $empreinte$
DECLARE
  v_ancien text := pg_catalog.obj_description('public.mon_horloge()'::pg_catalog.regprocedure, 'pg_proc');
BEGIN
  IF v_ancien IS NOT NULL THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.mon_horloge() IS %L',
      pg_catalog.regexp_replace(v_ancien, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mon_horloge()'::pg_catalog.regprocedure))));
  END IF;
END
$empreinte$;

-- ---------------------------------------------------------------------------
-- 7. Droits
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.pays_depuis_texte(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.proprietaire_lieu() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.lieu_de_profil(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.enregistrer_ma_ville(bigint) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mon_lieu() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mon_lieu_a_fournir() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reporter_ma_ville() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.lire_lieu_enseignant(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.verifier_lieu_enseignant(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.lieux_enseignants_direction() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.incoherences_lieu_direction() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.enregistrer_ma_ville(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mon_lieu() TO authenticated;
GRANT EXECUTE ON FUNCTION public.mon_lieu_a_fournir() TO authenticated;
GRANT EXECUTE ON FUNCTION public.reporter_ma_ville() TO authenticated;
GRANT EXECUTE ON FUNCTION public.lire_lieu_enseignant(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verifier_lieu_enseignant(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lieux_enseignants_direction() TO authenticated;
GRANT EXECUTE ON FUNCTION public.incoherences_lieu_direction() TO authenticated;

COMMENT ON FUNCTION public.enregistrer_ma_ville(bigint) IS
  'HORLOGE-ET-LIEU (12/11/2026) : l''appelant (tuteur ou enseignant) choisit sa ville ; le serveur recopie nom, pays, fuseau et coordonnees ; met a jour le fuseau du foyer ou de l''enseignant. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.mon_lieu() IS
  'HORLOGE-ET-LIEU (12/11/2026) : le lieu de l''appelant seul (son foyer, ou lui-meme enseignant), coordonnees comprises ; NULL sans ville choisie. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.mon_lieu_a_fournir() IS
  'HORLOGE-ET-LIEU (12/11/2026) : la ville est-elle a fournir (tuteur ou enseignant sans ville), et combien de reports restent. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.reporter_ma_ville() IS
  'HORLOGE-ET-LIEU (12/11/2026) : reporte l''etape de la ville (au plus lieu_reports_max fois). DEFINER, search_path vide.';
COMMENT ON FUNCTION public.incoherences_lieu_direction() IS
  'HORLOGE-ET-LIEU (12/11/2026) : pays, fuseau et ville qui ne concordent pas, pour la direction seule ; ne corrige rien. DEFINER, search_path vide.';

DO $postflight$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.pays_depuis_texte(text)', 'private.proprietaire_lieu()', 'private.lieu_de_profil(uuid)']
  LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : % est executable par un client', v_f;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
    'public.enregistrer_ma_ville(bigint)', 'public.mon_lieu()', 'public.mon_lieu_a_fournir()',
    'public.reporter_ma_ville()', 'public.lire_lieu_enseignant(uuid)', 'public.verifier_lieu_enseignant(uuid)',
    'public.lieux_enseignants_direction()', 'public.incoherences_lieu_direction()']
  LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.lieux', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.lieux', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.lieux', 'INSERT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.lieux'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.lieux_reports'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : public.lieux doit etre fermee (RLS, aucun droit client)';
  END IF;
END
$postflight$;

COMMIT;
