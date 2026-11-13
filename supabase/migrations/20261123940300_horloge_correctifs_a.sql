-- HORLOGE-ET-LIEU : corrections de la partie A, demandees par l'architecte
-- pedagogique apres la revue independante de la tete bd47382a1 (13/11/2026).
--
-- 1. Le changement d'heure d'un cours se lit sur le premier des DEUX fuseaux
--    (celui de la personne, celui de la classe) : une personne a Conakry dont la
--    classe est restee a Paris voit son heure locale bouger (I5).
-- 2. public.fuseau_vue(fuseau) : decalage, prochain changement d'heure de
--    n'importe quel fuseau, pour que l'ecran calcule l'heure locale d'un
--    creneau depuis son fuseau d'origine, sans base de fuseaux cote client.
-- 3. B2 : l'ancien client ne peut plus deplacer un cours de deux heures. Pour
--    une classe a l'heure de La Mecque, ajouter_creneau_classe_admin,
--    modifier_creneau_classe_admin et modifier_groupe SANS fuseau explicite sont
--    REFUSES sans rien modifier (erreur « RechargerPourModifierUnHoraire »). Un
--    appel qui ne deplace aucune heure (renommer, changer le seuil, changer la
--    duree d'un creneau sans le deplacer) reste accepte : aucune heure n'y est
--    interpretee.
--    Trois fonctions nouvelles recoivent le fuseau de l'heure saisie et
--    convertissent : ajouter_creneau_classe_fuseau, modifier_creneau_classe_fuseau,
--    modifier_groupe_fuseau.
-- 4. Annonces du changement d'heure : envoyees a 10 h, heure locale de la
--    personne (tache horaire), jamais entre 21 h et 8 h ; classe sans
--    enseignant incluse ; params `sens` (ete, hiver, classe) et `academie`
--    pour que le texte soit vrai ; une classe que la tache de nuit refuse de
--    convertir previent la direction, une fois.
-- 5. public.changements_heure_a_venir_direction : les changements d'heure a
--    venir PAR FUSEAU des familles et des enseignants (combien de personnes,
--    quelle date, quel decalage). transitions_fuseau_a_venir (par classe) est
--    vide depuis que toutes les classes sont a La Mecque : l'ecran lit celle-ci.
--
-- FICHIER SANS EFFACEMENT : fonctions creees ou remplacees (CREATE OR REPLACE),
-- aucune retiree, aucune ligne effacee.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Controle d'entree : les cinq fonctions deja en base que cette migration
--    remplace doivent etre exactement celles relevees en production le
--    13/11/2026 (empreinte md5 de prosrc, identique dans le depot). Une retouche
--    faite depuis ne peut pas etre ecrasee en silence.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_attendu constant jsonb := pg_catalog.jsonb_build_object(
    'public.ajouter_creneau_classe_admin(uuid,integer,integer)',
      'd66e96fd9b3b01913444fff0b0f5b0ba',
    'public.ajouter_creneau_classe_admin(uuid,integer,integer,integer)',
      'd9cf2a7fcc36d8238574e9b6ced9d649',
    'public.modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,integer,text)',
      '035396c8caa9f328769ed9f8bc3d8d69',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
      '1a05cc650211b0bd2570320dca13e4e3',
    'private.push_depuis_notification()',
      '5532bb238ac7bc754b646a335dd442aa');
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
-- 1. Le changement d'heure d'un cours : le premier des deux fuseaux
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.changement_heure_cours(
  p_fuseau_personne text,
  p_fuseau_creneau text,
  p_weekday integer,
  p_hour integer,
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS TABLE (
  transition timestamptz,
  date_changement text,
  jour_avant integer,
  heure_avant text,
  jour_apres integer,
  heure_apres text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_t_personne timestamptz;
  v_t_creneau timestamptz;
  v_transition timestamptz;
  v_avant timestamptz;
  v_apres timestamptz;
BEGIN
  IF p_fuseau_personne IS NULL OR p_fuseau_creneau IS NULL
     OR NOT app_private.fuseau_connu(p_fuseau_personne)
     OR NOT app_private.fuseau_connu(p_fuseau_creneau) THEN
    RETURN;
  END IF;
  -- L'heure locale d'un cours bouge quand le fuseau de la personne change
  -- d'heure, ET quand le fuseau dans lequel le creneau est defini en change
  -- (une classe restee a Paris, vue de Conakry) : le premier des deux compte.
  v_t_personne := (private.fuseau_info(p_fuseau_personne, p_maintenant) ->> 'prochain_changement')::timestamptz;
  v_t_creneau := (private.fuseau_info(p_fuseau_creneau, p_maintenant) ->> 'prochain_changement')::timestamptz;
  v_transition := LEAST(v_t_personne, v_t_creneau);
  IF v_transition IS NULL THEN
    RETURN;
  END IF;
  SELECT pg_catalog.max(o.debut) FILTER (WHERE o.debut < v_transition),
         pg_catalog.min(o.debut) FILTER (WHERE o.debut >= v_transition)
    INTO v_avant, v_apres
    FROM (SELECT public.instant_creneau_reference(p_weekday, p_hour, p_fuseau_creneau, k, p_maintenant) AS debut
            FROM pg_catalog.generate_series(-1, 60) AS k) o;
  IF v_avant IS NULL OR v_apres IS NULL THEN
    RETURN;
  END IF;
  jour_avant := pg_catalog.date_part('isodow', v_avant AT TIME ZONE p_fuseau_personne)::integer;
  heure_avant := pg_catalog.to_char(v_avant AT TIME ZONE p_fuseau_personne, 'HH24:MI');
  jour_apres := pg_catalog.date_part('isodow', v_apres AT TIME ZONE p_fuseau_personne)::integer;
  heure_apres := pg_catalog.to_char(v_apres AT TIME ZONE p_fuseau_personne, 'HH24:MI');
  IF jour_avant = jour_apres AND heure_avant = heure_apres THEN
    RETURN;
  END IF;
  transition := v_transition;
  date_changement := pg_catalog.to_char(v_transition AT TIME ZONE p_fuseau_personne, 'YYYY-MM-DD');
  RETURN NEXT;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Le fuseau d'un creneau, pour l'ecran
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.fuseau_vue(p_fuseau text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'fuseau non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RAISE EXCEPTION 'fuseau inconnu' USING ERRCODE = '22023';
  END IF;
  RETURN private.fuseau_info(p_fuseau);
END;
$function$;

REVOKE ALL ON FUNCTION public.fuseau_vue(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fuseau_vue(text) TO authenticated;
COMMENT ON FUNCTION public.fuseau_vue(text) IS
  'HORLOGE-ET-LIEU (13/11/2026) : decalage, prochain changement d''heure et suivant d''un fuseau connu, pour que l''ecran calcule l''heure locale d''un creneau. Aucune donnee personnelle. Compte valide exige. DEFINER, search_path vide.';

-- ---------------------------------------------------------------------------
-- 3. B2 : plus aucune interpretation devinee d'une heure saisie
-- ---------------------------------------------------------------------------
-- Le garde : refuse, pour une classe a l'heure de La Mecque, tout appel sans
-- fuseau explicite. Il ne dit rien a qui n'est pas la direction (la fonction
-- appelante refuse alors comme avant) et se tait quand une fonction « _fuseau »
-- a elle-meme converti l'heure (reglage local a la transaction, que ni le client
-- ni PostgREST ne peuvent poser).
CREATE FUNCTION private.refuser_heure_sans_fuseau(p_groupe_id uuid, p_fuseau_explicite boolean)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RETURN;
  END IF;
  IF p_fuseau_explicite OR pg_catalog.current_setting('horloge.fuseau_explicite', true) = 'on' THEN
    RETURN;
  END IF;
  IF EXISTS (SELECT 1 FROM public.groupes g
              WHERE g.id = p_groupe_id AND g.ended_at IS NULL
                AND g.timezone_iana = private.fuseau_academie()) THEN
    RAISE EXCEPTION 'RechargerPourModifierUnHoraire'
      USING ERRCODE = 'P0001',
            HINT = 'Rechargez l''application pour modifier un horaire.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION private.refuser_heure_sans_fuseau(uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.refuser_heure_sans_fuseau(uuid, boolean) IS
  'HORLOGE-ET-LIEU (13/11/2026) : refuse la modification d''un horaire de classe a l''heure de La Mecque sans fuseau explicite. DEFINER, search_path vide, aucun EXECUTE client.';

-- La conversion d'une heure saisie dans un fuseau vers le fuseau de la classe :
-- le jour et l'heure du prochain creneau, lus dans le fuseau de la classe. Une
-- heure sans equivalent entier est refusee (Inde, Iran, Nepal).
CREATE FUNCTION private.horaire_vers_fuseau_classe(
  p_groupe_id uuid, p_weekday integer, p_hour integer, p_fuseau text,
  OUT o_weekday integer, OUT o_hour integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_classe text;
  v_instant timestamptz;
  v_local timestamp;
BEGIN
  IF p_weekday IS NULL OR p_hour IS NULL OR p_weekday NOT BETWEEN 1 AND 7
     OR p_hour NOT BETWEEN 0 AND 23 OR p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau) THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT g.timezone_iana INTO v_classe FROM public.groupes g
   WHERE g.id = p_groupe_id AND g.ended_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0002';
  END IF;
  IF p_fuseau = v_classe THEN
    o_weekday := p_weekday;
    o_hour := p_hour;
    RETURN;
  END IF;
  v_instant := public.instant_creneau_reference(p_weekday, p_hour, p_fuseau, 0, pg_catalog.now());
  v_local := v_instant AT TIME ZONE v_classe;
  IF pg_catalog.date_part('minute', v_local) <> 0 THEN
    RAISE EXCEPTION 'HeureSansEquivalentEntier' USING ERRCODE = '22023';
  END IF;
  o_weekday := pg_catalog.date_part('isodow', v_local)::integer;
  o_hour := pg_catalog.date_part('hour', v_local)::integer;
END;
$function$;
REVOKE ALL ON FUNCTION private.horaire_vers_fuseau_classe(uuid, integer, integer, text)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.horaire_vers_fuseau_classe(uuid, integer, integer, text) IS
  'HORLOGE-ET-LIEU (13/11/2026) : convertit un jour et une heure saisis dans un fuseau vers le fuseau de la classe (prochain creneau). Refuse une heure sans equivalent entier. DEFINER, search_path vide, aucun EXECUTE client.';

-- Les quatre fonctions de l'ancien client, avec le garde (copies completes : seule
-- la ligne du garde est ajoutee).
CREATE OR REPLACE FUNCTION public.ajouter_creneau_classe_admin(p_groupe_id uuid, p_weekday integer, p_hour_local integer)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  -- HORLOGE-ET-LIEU : une classe a l'heure de La Mecque ne se modifie plus sans fuseau explicite.
  PERFORM private.refuser_heure_sans_fuseau(p_groupe_id, false);
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR p_weekday IS NULL OR p_hour_local IS NULL
     OR p_weekday NOT BETWEEN 1 AND 7 OR p_hour_local NOT BETWEEN 0 AND 23 THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_g FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
  VALUES (p_groupe_id, p_weekday, p_hour_local)
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_ajoute', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local));

  RETURN public.materialiser_seances_groupe(p_groupe_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.ajouter_creneau_classe_admin(p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_duree_minutes integer)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  -- HORLOGE-ET-LIEU : une classe a l'heure de La Mecque ne se modifie plus sans fuseau explicite.
  PERFORM private.refuser_heure_sans_fuseau(p_groupe_id, false);
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_groupe_id IS NULL OR p_weekday IS NULL OR p_hour_local IS NULL
     OR p_weekday NOT BETWEEN 1 AND 7 OR p_hour_local NOT BETWEEN 0 AND 23
     OR NOT coalesce(p_duree_minutes IS NULL OR p_duree_minutes BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_g FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ClasseIndisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local, duree_minutes)
  VALUES (p_groupe_id, p_weekday, p_hour_local, p_duree_minutes)
  ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_ajoute', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'duree_minutes', p_duree_minutes));

  RETURN public.materialiser_seances_groupe(p_groupe_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.modifier_creneau_classe_admin(p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_nouveau_weekday integer, p_nouvelle_heure integer, p_nouvelle_duree integer, p_motif text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_ancienne_duree smallint;
  v_n integer;
BEGIN
  -- HORLOGE-ET-LIEU : une classe a l'heure de La Mecque ne se modifie plus sans fuseau explicite.
  PERFORM private.refuser_heure_sans_fuseau(p_groupe_id,
    coalesce(p_weekday = p_nouveau_weekday AND p_hour_local = p_nouvelle_heure, false));
  v_g := private.classe_creneau_garde(p_groupe_id, p_motif);
  IF p_nouveau_weekday IS NULL OR p_nouvelle_heure IS NULL
     OR p_nouveau_weekday NOT BETWEEN 1 AND 7 OR p_nouvelle_heure NOT BETWEEN 0 AND 23
     OR NOT coalesce(p_nouvelle_duree IS NULL OR p_nouvelle_duree BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'CreneauParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT gc.duree_minutes INTO v_ancienne_duree
    FROM public.groupe_creneaux gc
   WHERE gc.groupe_id = p_groupe_id
     AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CreneauIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  IF p_weekday = p_nouveau_weekday AND p_hour_local = p_nouvelle_heure THEN
    IF v_ancienne_duree IS NOT DISTINCT FROM p_nouvelle_duree THEN
      RETURN 0;
    END IF;
    -- La duree seule : le declencheur de groupe_creneaux repasse le predicat
    -- de l'enseignant et le controle contre ses seances deja generees, puis
    -- les seances a venir prennent la nouvelle duree (elles ne sont pas
    -- annulees : meme jour, meme heure). Un chevauchement arrete tout.
    UPDATE public.groupe_creneaux gc
       SET duree_minutes = p_nouvelle_duree
     WHERE gc.groupe_id = p_groupe_id
       AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
    v_n := app_private.aligner_seances_a_venir_sur_la_classe(p_groupe_id);
  ELSE
    IF EXISTS (SELECT 1 FROM public.groupe_creneaux gc
                WHERE gc.groupe_id = p_groupe_id
                  AND gc.weekday = p_nouveau_weekday AND gc.hour_local = p_nouvelle_heure) THEN
      RAISE EXCEPTION 'CreneauExistant' USING ERRCODE = '23505';
    END IF;

    -- D'abord l'annulation : l'enseignant redevient libre a l'ancien horaire,
    -- et le predicat du nouveau creneau ne bute pas sur ses propres seances.
    PERFORM private.annuler_seances_creneau(p_groupe_id, p_weekday, p_hour_local, p_motif);

    IF v_g.weekday = p_weekday AND v_g.hour_local = p_hour_local THEN
      -- L'ancre : le declencheur de 0043 deplace la ligne (avec son ancienne
      -- duree), le predicat de la classe repasse, et la cloche de 0055 genere
      -- les seances ; puis la nouvelle duree est posee (le predicat repasse)
      -- et les seances qui viennent d'etre generees la prennent.
      UPDATE public.groupes
         SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure
       WHERE id = p_groupe_id;
      UPDATE public.groupe_creneaux gc
         SET duree_minutes = p_nouvelle_duree
       WHERE gc.groupe_id = p_groupe_id
         AND gc.weekday = p_nouveau_weekday AND gc.hour_local = p_nouvelle_heure
         AND gc.duree_minutes IS DISTINCT FROM p_nouvelle_duree;
    ELSE
      UPDATE public.groupe_creneaux gc
         SET weekday = p_nouveau_weekday, hour_local = p_nouvelle_heure,
             duree_minutes = p_nouvelle_duree
       WHERE gc.groupe_id = p_groupe_id
         AND gc.weekday = p_weekday AND gc.hour_local = p_hour_local;
    END IF;

    v_n := public.materialiser_seances_groupe(p_groupe_id);
    PERFORM app_private.aligner_seances_a_venir_sur_la_classe(p_groupe_id);
  END IF;

  PERFORM public.log_sensitive_access(
    'classe_creneau_modifie', 'groupes', p_groupe_id::text,
    pg_catalog.jsonb_build_object('weekday', p_weekday, 'hour_local', p_hour_local,
      'duree_minutes', v_ancienne_duree,
      'nouveau_weekday', p_nouveau_weekday, 'nouvelle_heure', p_nouvelle_heure,
      'nouvelle_duree', p_nouvelle_duree,
      'motif', pg_catalog.btrim(p_motif)));
  RETURN v_n;
END;
$function$;

CREATE OR REPLACE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint DEFAULT NULL::smallint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actifs int;
begin
  -- HORLOGE-ET-LIEU : une classe a l'heure de La Mecque ne se modifie plus sans fuseau explicite.
  PERFORM private.refuser_heure_sans_fuseau(p_groupe_id,
    p_timezone_iana IS NOT NULL
    OR EXISTS (SELECT 1 FROM public.groupes g
                WHERE g.id = p_groupe_id AND g.weekday = p_weekday AND g.hour_local = p_hour_local));
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  if p_timezone_iana is not null then
    if not app_private.fuseau_connu(p_timezone_iana) then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle,
      seuil_max = p_seuil_max,
      weekday = p_weekday,
      hour_local = p_hour_local,
      timezone_iana = coalesce(p_timezone_iana, timezone_iana),
      couleur_jeton = coalesce(p_couleur_jeton, couleur_jeton)
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$;

-- Les trois fonctions nouvelles : elles recoivent le fuseau de l'heure saisie.
CREATE FUNCTION public.ajouter_creneau_classe_fuseau(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer, p_duree_minutes integer, p_fuseau text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_h record;
  v_n integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_h FROM private.horaire_vers_fuseau_classe(p_groupe_id, p_weekday, p_hour_local, p_fuseau);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'on', true);
  v_n := public.ajouter_creneau_classe_admin(p_groupe_id, v_h.o_weekday, v_h.o_hour, p_duree_minutes);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'off', true);
  RETURN v_n;
END;
$function$;

CREATE FUNCTION public.modifier_creneau_classe_fuseau(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer,
  p_nouveau_weekday integer, p_nouvelle_heure integer, p_nouvelle_duree integer,
  p_motif text, p_fuseau text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_h record;
  v_n integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'CreneauNonAutorise' USING ERRCODE = '42501';
  END IF;
  -- Le creneau a deplacer est designe par ses valeurs dans le fuseau de la
  -- classe (celles que l'ecran lit dans groupe_creneaux) ; le nouveau est saisi
  -- dans p_fuseau.
  SELECT * INTO v_h FROM private.horaire_vers_fuseau_classe(p_groupe_id, p_nouveau_weekday, p_nouvelle_heure, p_fuseau);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'on', true);
  v_n := public.modifier_creneau_classe_admin(
    p_groupe_id, p_weekday, p_hour_local, v_h.o_weekday, v_h.o_hour, p_nouvelle_duree, p_motif);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'off', true);
  RETURN v_n;
END;
$function$;

CREATE FUNCTION public.modifier_groupe_fuseau(
  p_groupe_id uuid, p_libelle text, p_seuil_max smallint,
  p_weekday smallint, p_hour_local smallint, p_fuseau text,
  p_couleur_jeton smallint DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_h record;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'modification de groupe reservee a l''administration';
  END IF;
  SELECT * INTO v_h FROM private.horaire_vers_fuseau_classe(p_groupe_id, p_weekday::integer, p_hour_local::integer, p_fuseau);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'on', true);
  PERFORM public.modifier_groupe(
    p_groupe_id, p_libelle, p_seuil_max, v_h.o_weekday::smallint, v_h.o_hour::smallint, NULL::text, p_couleur_jeton);
  PERFORM pg_catalog.set_config('horloge.fuseau_explicite', 'off', true);
END;
$function$;

REVOKE ALL ON FUNCTION public.ajouter_creneau_classe_fuseau(uuid, integer, integer, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.modifier_creneau_classe_fuseau(uuid, integer, integer, integer, integer, integer, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.modifier_groupe_fuseau(uuid, text, smallint, smallint, smallint, text, smallint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ajouter_creneau_classe_fuseau(uuid, integer, integer, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.modifier_creneau_classe_fuseau(uuid, integer, integer, integer, integer, integer, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.modifier_groupe_fuseau(uuid, text, smallint, smallint, smallint, text, smallint) TO authenticated;
COMMENT ON FUNCTION public.ajouter_creneau_classe_fuseau(uuid, integer, integer, integer, text) IS
  'HORLOGE-ET-LIEU (13/11/2026) : ajoute un creneau saisi dans un fuseau explicite ; le serveur convertit vers le fuseau de la classe. Direction seule. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.modifier_creneau_classe_fuseau(uuid, integer, integer, integer, integer, integer, text, text) IS
  'HORLOGE-ET-LIEU (13/11/2026) : deplace un creneau (le nouveau est saisi dans un fuseau explicite) ; le serveur convertit. Direction seule. DEFINER, search_path vide.';
COMMENT ON FUNCTION public.modifier_groupe_fuseau(uuid, text, smallint, smallint, smallint, text, smallint) IS
  'HORLOGE-ET-LIEU (13/11/2026) : modifie le nom, le seuil et le creneau d''ancrage d''une classe (creneau saisi dans un fuseau explicite) ; le serveur convertit. Direction seule. DEFINER, search_path vide.';

-- ---------------------------------------------------------------------------
-- 4. Les annonces : 10 h locale, classe sans enseignant, texte vrai
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.annoncer_changements_heure(
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r record;
  v_palier text;
  v_n integer := 0;
  v_pose integer;
  v_info jsonb;
  v_sens text;
  v_academie text := private.fuseau_academie();
BEGIN
  FOR v_r IN
    WITH classes AS (
      -- Une classe vivante, avec ou sans enseignant (etat « en_attente_enseignant » :
      -- ses familles sont inscrites, aucun enseignant n'est encore affecte) : les
      -- familles sont prevenues dans tous les cas.
      SELECT g.id, g.timezone_iana AS fuseau_classe, g.type_public, g.teacher_id, g.libelle
        FROM public.groupes g
       WHERE g.ended_at IS NULL AND g.etat IN ('active', 'en_attente_enseignant')
    ),
    personnes AS (
      -- L'enseignant de la classe, quand elle en a un, a son fuseau.
      SELECT c.id AS groupe_id, c.teacher_id AS destinataire, NULL::uuid AS foyer,
             'classe'::text AS portee, coalesce(tp.timezone_iana, c.fuseau_classe) AS fuseau
        FROM classes c
        LEFT JOIN public.teacher_profiles tp ON tp.profile_id = c.teacher_id
       WHERE c.teacher_id IS NOT NULL
      UNION
      -- Les tuteurs du foyer de chaque eleve inscrit : toujours, jamais l'enfant.
      SELECT c.id, t.id, h.id, 'foyer', coalesce(h.timezone, c.fuseau_classe)
        FROM classes c
        JOIN public.groupe_membres gm ON gm.groupe_id = c.id AND gm.left_at IS NULL
        JOIN public.profiles s ON s.id = gm.student_id AND s.deleted_at IS NULL
        JOIN public.households h ON h.id = s.household_id AND h.deleted_at IS NULL
        JOIN public.profiles t ON t.deleted_at IS NULL AND t.role = 'guardian'
                              AND (t.id = h.primary_guardian_id OR t.household_id = h.id)
      UNION
      -- Un eleve d'une classe d'adultes : lui-meme.
      SELECT c.id, s.id, s.household_id, 'soi', coalesce(h.timezone, c.fuseau_classe)
        FROM classes c
        JOIN public.groupe_membres gm ON gm.groupe_id = c.id AND gm.left_at IS NULL
        JOIN public.profiles s ON s.id = gm.student_id AND s.deleted_at IS NULL
        LEFT JOIN public.households h ON h.id = s.household_id AND h.deleted_at IS NULL
       WHERE c.type_public = 'adulte'
    ),
    -- Une personne, une ligne par classe (l'eleve adulte avant le tuteur). Seules
    -- les personnes pour qui il est 10 h, heure locale, sont servies : la tache
    -- passe chaque heure, aucune annonce ne part entre 21 h et 8 h.
    destinataires AS (
      SELECT DISTINCT ON (p.groupe_id, p.destinataire)
             p.groupe_id, p.destinataire, p.foyer, p.portee, p.fuseau
        FROM personnes p
       WHERE app_private.fuseau_connu(p.fuseau)
         AND pg_catalog.date_part('hour', p_maintenant AT TIME ZONE p.fuseau) = 10
       ORDER BY p.groupe_id, p.destinataire,
                CASE p.portee WHEN 'soi' THEN 1 WHEN 'foyer' THEN 2 ELSE 3 END
    ),
    creneaux AS (
      SELECT c.id AS groupe_id, c.fuseau_classe, c.libelle,
             s.jour, s.heure
        FROM classes c
        CROSS JOIN LATERAL (
          SELECT gc.weekday::integer AS jour, gc.hour_local::integer AS heure
            FROM public.groupe_creneaux gc WHERE gc.groupe_id = c.id
          UNION
          SELECT g.weekday::integer, g.hour_local::integer FROM public.groupes g WHERE g.id = c.id
        ) s
    )
    SELECT d.groupe_id, d.destinataire, d.foyer, d.portee, d.fuseau, cr.fuseau_classe,
           pg_catalog.min(ch.transition) AS transition,
           pg_catalog.min(ch.date_changement) AS date_changement,
           cr.libelle,
           pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'jour_avant', ch.jour_avant, 'avant', ch.heure_avant,
             'jour_apres', ch.jour_apres, 'apres', ch.heure_apres)
             ORDER BY ch.jour_avant, ch.heure_avant) AS changements
      FROM destinataires d
      JOIN creneaux cr ON cr.groupe_id = d.groupe_id
      CROSS JOIN LATERAL private.changement_heure_cours(
        d.fuseau, cr.fuseau_classe, cr.jour, cr.heure, p_maintenant) ch
     GROUP BY d.groupe_id, d.destinataire, d.foyer, d.portee, d.fuseau, cr.fuseau_classe, cr.libelle
  LOOP
    -- Le palier : 14 jours avant (des qu'on entre dans la fenetre), puis la
    -- veille (les dernieres 24 heures).
    v_palier := CASE
      WHEN p_maintenant >= v_r.transition - interval '1 day' AND p_maintenant < v_r.transition THEN 'j1'
      WHEN p_maintenant >= v_r.transition - interval '14 days' AND p_maintenant < v_r.transition THEN 'j14'
      ELSE NULL END;
    CONTINUE WHEN v_palier IS NULL;

    INSERT INTO private.annonces_changement_heure (destinataire, groupe_id, transition, palier)
    VALUES (v_r.destinataire, v_r.groupe_id, v_r.transition, v_palier)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS v_pose = ROW_COUNT;
    CONTINUE WHEN v_pose = 0;

    -- Le sens du changement chez la personne : « ete » (ses horloges avancent),
    -- « hiver » (elles reculent), « classe » quand c'est le fuseau de la classe
    -- qui change et pas le sien.
    v_info := private.fuseau_info(v_r.fuseau, p_maintenant);
    v_sens := CASE
      WHEN (v_info ->> 'prochain_changement')::timestamptz = v_r.transition THEN
        CASE WHEN (v_info ->> 'decalage_apres')::integer > (v_info ->> 'decalage_secondes')::integer
             THEN 'ete' ELSE 'hiver' END
      ELSE 'classe' END;

    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    VALUES (
      v_r.destinataire, v_r.foyer, 'creneau_change',
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'groupe_id', v_r.groupe_id,
        'portee', v_r.portee,
        'fuseau', v_r.fuseau,
        'classe', nullif(pg_catalog.btrim(v_r.libelle), ''),
        'motif', 'changement_heure',
        'sens', v_sens,
        'academie', v_r.fuseau_classe = v_academie,
        'palier', v_palier,
        'date_changement', v_r.date_changement,
        'changements', v_r.changements)),
      CASE v_r.portee
        WHEN 'soi' THEN '/eleve'
        WHEN 'foyer' THEN '/tuteur/classes/' || v_r.groupe_id::text
        ELSE '/enseignant/classes' END);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. La tache de nuit : une classe refusee previent la direction, une fois
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.convertir_classes_hors_academie(
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
  v_raison text;
  v_cause text;
  v_libelle text;
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
      v_raison := SQLERRM;
      RAISE WARNING 'horloge : classe % non convertie (%, %)', v_groupe, SQLSTATE, v_raison;
      -- Un simple avertissement dans les journaux ne suffit pas : la direction
      -- le sait, une fois par classe et par cause (l'evenement `creneau_change`
      -- porte le marqueur `conversion_refusee`, sans nouvelle contrainte). Le
      -- texte de l'erreur SQL et les identifiants ne partent JAMAIS dans la
      -- notification (ni dans le courriel qui la reprend) : une cause fermee,
      -- `proche`, `demi_heure` ou `autre`.
      v_cause := CASE
        WHEN v_raison LIKE '%28 jours%' THEN 'proche'
        WHEN v_raison LIKE '%heure pleine%' THEN 'demi_heure'
        ELSE 'autre' END;
      SELECT g.libelle INTO v_libelle FROM public.groupes g WHERE g.id = v_groupe;
      INSERT INTO public.notifications (destinataire, evenement, params, destination)
      SELECT a.id, 'creneau_change',
             pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
               'groupe_id', v_groupe,
               'classe', nullif(pg_catalog.btrim(v_libelle), ''),
               'motif', 'conversion_refusee',
               'cause', v_cause)),
             '/admin/operations/planning'
        FROM public.profiles a
       WHERE a.role = 'admin' AND a.deleted_at IS NULL
         AND a.account_status IN ('active', 'provisional_active')
         AND NOT EXISTS (
           SELECT 1 FROM public.notifications n
            WHERE n.destinataire = a.id AND n.evenement = 'creneau_change'
              AND n.params ->> 'motif' = 'conversion_refusee'
              AND n.params ->> 'groupe_id' = v_groupe::text
              AND n.params ->> 'cause' = v_cause);
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. La planification : chaque heure, pour servir les personnes dont il est 10 h
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $c$SELECT cron.schedule('horloge_annonces', '7 * * * *',
      'SELECT private.annoncer_changements_heure()')$c$;
  ELSE
    RAISE NOTICE 'HORLOGE-ET-LIEU : pg_cron absente, rien n''est planifie';
  END IF;
END
$planification$;

-- ---------------------------------------------------------------------------
-- 7. Les changements d'heure a venir, par fuseau des familles et des enseignants
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.changements_heure_a_venir_direction(p_jours integer DEFAULT 60)
RETURNS TABLE (
  fuseau text,
  transition_utc timestamptz,
  jours_restants integer,
  decalage_avant_secondes integer,
  decalage_apres_secondes integer,
  familles integer,
  enseignants integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a l''administration' USING ERRCODE = '42501';
  END IF;
  IF p_jours IS NULL OR p_jours NOT BETWEEN 1 AND 366 THEN
    RAISE EXCEPTION 'p_jours hors bornes' USING ERRCODE = '22023';
  END IF;
  RETURN QUERY
  WITH par_fuseau AS (
    SELECT z.fuseau AS tz,
           pg_catalog.count(*) FILTER (WHERE z.nature = 'famille')::integer AS nb_familles,
           pg_catalog.count(*) FILTER (WHERE z.nature = 'enseignant')::integer AS nb_enseignants
      FROM (
        SELECT h.timezone AS fuseau, 'famille'::text AS nature
          FROM public.households h
         WHERE h.deleted_at IS NULL AND h.timezone IS NOT NULL
           AND EXISTS (SELECT 1 FROM public.profiles p
                        WHERE p.household_id = h.id AND p.role = 'guardian'
                          AND p.deleted_at IS NULL AND p.account_status = 'active')
        UNION ALL
        SELECT tp.timezone_iana, 'enseignant'
          FROM public.teacher_profiles tp
          JOIN public.profiles p ON p.id = tp.profile_id
         WHERE tp.deleted_at IS NULL AND tp.timezone_iana IS NOT NULL
           AND p.deleted_at IS NULL AND p.account_status IN ('active', 'provisional_active')
      ) z
     GROUP BY z.fuseau
  ), infos AS (
    SELECT f.tz, f.nb_familles, f.nb_enseignants, private.fuseau_info(f.tz) AS info
      FROM par_fuseau f
     WHERE app_private.fuseau_connu(f.tz)
  )
  SELECT i.tz,
         (i.info ->> 'prochain_changement')::timestamptz,
         pg_catalog.ceil(EXTRACT(epoch FROM ((i.info ->> 'prochain_changement')::timestamptz - pg_catalog.now())) / 86400)::integer,
         (i.info ->> 'decalage_secondes')::integer,
         (i.info ->> 'decalage_apres')::integer,
         i.nb_familles,
         i.nb_enseignants
    FROM infos i
   WHERE i.info ->> 'prochain_changement' IS NOT NULL
     AND (i.info ->> 'prochain_changement')::timestamptz <= pg_catalog.now() + pg_catalog.make_interval(days => p_jours)
   ORDER BY 2, 1;
END;
$function$;

REVOKE ALL ON FUNCTION public.changements_heure_a_venir_direction(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.changements_heure_a_venir_direction(integer) TO authenticated;
COMMENT ON FUNCTION public.changements_heure_a_venir_direction(integer) IS
  'HORLOGE-ET-LIEU (13/11/2026) : les changements d''heure a venir par fuseau des familles et des enseignants (combien de personnes, quelle date, quel decalage). Direction seule. DEFINER, search_path vide.';

-- ---------------------------------------------------------------------------
-- 7 bis. Le push de l'annonce : son propre texte (I1)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push_depuis_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_categorie text;
  v_tag text;
BEGIN
  BEGIN
    IF NOT private.notification_avec_push(NEW.evenement, NEW.params ->> 'portee')
       OR NOT private.push_compte_autorise(NEW.destinataire) THEN
      RETURN NULL;
    END IF;
    SELECT e.categorie, e.tag INTO v_categorie, v_tag
      FROM private.push_evenements e WHERE e.evenement = NEW.evenement;
    v_categorie := coalesce(v_categorie, 'classes');
    IF EXISTS (SELECT 1 FROM public.push_preferences pp
                WHERE pp.profile_id = NEW.destinataire AND pp.categorie = v_categorie
                  AND NOT pp.actif)
       OR NOT EXISTS (SELECT 1 FROM public.abonnements_push a
                       WHERE a.profile_id = NEW.destinataire AND a.retire_le IS NULL) THEN
      RETURN NULL;
    END IF;
    INSERT INTO public.push_sortants (notification_id, destinataire, evenement, portee, destination, tag)
    -- HORLOGE-ET-LIEU (I1, 13/11/2026) : l'annonce d'un changement d'heure et le
    -- refus d'une conversion portent leur propre « portee » de push (le texte du push
    -- la lit : vrai et sans prenom), sans nouvel evenement ni nouvelle contrainte.
    VALUES (NEW.id, NEW.destinataire, NEW.evenement,
            CASE
              WHEN NEW.evenement = 'creneau_change' AND NEW.params ->> 'motif' = 'changement_heure'
                THEN 'heure_' || coalesce(nullif(NEW.params ->> 'sens', ''), 'classe')
              WHEN NEW.evenement = 'creneau_change' AND NEW.params ->> 'motif' = 'conversion_refusee'
                THEN 'conversion_refusee'
              ELSE NEW.params ->> 'portee'
            END,
            NEW.destination, v_tag)
    ON CONFLICT (notification_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('push:' || NEW.evenement, NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
  v_r text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.refuser_heure_sans_fuseau(uuid,boolean)',
    'private.horaire_vers_fuseau_classe(uuid,integer,integer,text)']
  LOOP
    FOREACH v_r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
      IF pg_catalog.has_function_privilege(v_r, v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
        RAISE EXCEPTION 'HORLOGE-ET-LIEU : % peut executer %', v_r, v_f;
      END IF;
    END LOOP;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
    'public.fuseau_vue(text)',
    'public.ajouter_creneau_classe_fuseau(uuid,integer,integer,integer,text)',
    'public.modifier_creneau_classe_fuseau(uuid,integer,integer,integer,integer,integer,text,text)',
    'public.modifier_groupe_fuseau(uuid,text,smallint,smallint,smallint,text,smallint)',
    'public.changements_heure_a_venir_direction(integer)']
  LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de %', v_f;
    END IF;
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
              FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : % n''est pas DEFINER a search_path vide', v_f;
    END IF;
  END LOOP;
END
$postflight$;

COMMIT;
