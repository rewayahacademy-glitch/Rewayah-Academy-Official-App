-- COURRIEL-ENTRETIEN (pilote, 16/11/2026, plaintes du matin, RETOURS-TERRAIN R22) : le courriel « Votre
-- candidature est retenue pour un entretien » invitait a choisir un creneau alors qu'aucun moment d'entretien
-- n'etait ouvert (les entretiens sont suspendus) : 6 courriels sont partis le 16/11 entre 18:15 et 18:25 UTC.
--
-- Le serveur dit la verite du moment : a l'admission en salle de verification (admettre_salle_verification), il
-- calcule `creneauxOuverts` et le pose dans les donnees du courriel. Les modeles (fr, ar ; en, es et pt partent
-- du francais) n'invitent a choisir que si la cle vaut vrai ; sinon ils disent que l'academie ecrira quand les
-- moments seront ouverts et que la personne n'a rien a faire pour l'instant.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : une fonction privee de lecture, une
-- retouche par ancrage de admettre_salle_verification (jamais une copie entiere). Sans BEGIN/COMMIT de premier
-- niveau.
--
-- `private.entretien_creneaux_ouverts_pour(c)` reprend exactement ce que le candidat verrait dans l'application
-- (creneaux_entretien_disponibles) : meme cote que la candidature, ni reserve ni annule, a plus de 30 minutes,
-- une langue d'entretien en commun avec les langues du candidat, tenable (participants autorises, fondateurs).
--
-- LIMITE, a decider : « Nous vous ecrirons des que les moments seront ouverts » est une promesse que rien
-- n'execute encore : ouvrir un creneau (ouvrir_creneau_entretien) n'ecrit a personne. Les 6 courriels deja partis
-- n'ont pas ete renvoyes (accord du pilote requis).

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COURRIEL-ENTRETIEN : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

CREATE FUNCTION private.entretien_creneaux_ouverts_pour(c public.candidatures)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM public.entretien_creneaux k
     WHERE k.cote = c.genre
       AND k.session_id IS NULL AND k.annule_le IS NULL
       AND k.debut > pg_catalog.now() + interval '30 minutes'
       AND k.langues && private.candidature_langues(c.id)
       AND private.entretien_creneau_tenable(k.id) IS NULL);
$function$;
ALTER FUNCTION private.entretien_creneaux_ouverts_pour(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_creneaux_ouverts_pour(public.candidatures)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $retouche$
DECLARE
  v_f regprocedure := 'public.admettre_salle_verification(uuid,integer,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, 'creneauxOuverts') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '      ''{}''::jsonb, ''retenu_entretien:'' || p_id::text || '':'' || p_cle_idempotence, ''auto'', v_uid);',
      '      pg_catalog.jsonb_build_object(''creneauxOuverts'', private.entretien_creneaux_ouverts_pour(v_c)),
      ''retenu_entretien:'' || p_id::text || '':'' || p_cle_idempotence, ''auto'', v_uid);',
      'courriel.donnees');
    EXECUTE v_def;
  END IF;
  v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
    IF pg_catalog.strpos(v_com, 'COURRIEL-ENTRETIEN') = 0 THEN
      v_com := v_com || ' COURRIEL-ENTRETIEN (16/11/2026) : le courriel retenu_entretien porte creneauxOuverts (un moment est-il ouvert pour cette personne), pour que le texte n''invite a choisir qu''a bon escient. Must-pass aussi : supabase/tests/scenarios_courriel_entretien.sql.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::regprocedure),
                       'creneauxOuverts') = 0
     OR pg_catalog.has_function_privilege('authenticated',
          'private.entretien_creneaux_ouverts_pour(public.candidatures)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'COURRIEL-ENTRETIEN : retouche absente ou fonction privee ouverte';
  END IF;
END
$postflight$;
