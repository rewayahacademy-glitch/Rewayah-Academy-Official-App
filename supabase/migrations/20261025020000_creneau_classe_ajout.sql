-- B2.2 bis (c), « ajouter un creneau » (plan de nuit du pilote, 24/10/2026).
--
-- Constat : une Classe peut porter plusieurs creneaux par semaine
-- (`groupe_creneaux`), mais l'ecran Classes de la direction n'en ecrit qu'un,
-- l'ancre (`groupes.weekday` / `hour_local`). La direction ecrit deja
-- `groupe_creneaux` sous son role (politique `groupe_creneaux_admin`), et le
-- declencheur `groupe_creneaux_verifie_enseignant` y repasse le predicat
-- d'affectation (memes refus, meme SQLSTATE que `modifier_groupe`). Rien ne
-- materialise alors les seances du nouveau creneau avant la cloche.
--
-- `ajouter_creneau_classe_admin(classe, jour, heure)` : la direction ajoute un
-- creneau a une Classe active ; le predicat passe (ou refuse, rien d'ecrit) ;
-- les seances du creneau sont materialisees aussitot ; rend le nombre de
-- seances creees. Un creneau deja present ne change rien (0).
--
-- Aucune suppression.

BEGIN;

CREATE OR REPLACE FUNCTION public.ajouter_creneau_classe_admin(
  p_groupe_id uuid, p_weekday integer, p_hour_local integer)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
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

REVOKE ALL ON FUNCTION public.ajouter_creneau_classe_admin(uuid, integer, integer) FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION public.ajouter_creneau_classe_admin(uuid, integer, integer) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION public.ajouter_creneau_classe_admin(uuid, integer, integer) TO authenticated;

COMMENT ON FUNCTION public.ajouter_creneau_classe_admin(uuid, integer, integer) IS
  'B2.2 bis (c) : la direction ajoute un creneau hebdomadaire a une Classe ; predicat d''affectation, puis materialisation.';

COMMIT;
