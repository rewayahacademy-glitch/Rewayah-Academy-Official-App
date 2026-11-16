-- IMAGES-MESSAGERIE (16/11/2026), partie serveur, 4/5 : les coeurs (« J'aime »).
--
-- aimer_message(p_message) et ne_plus_aimer_message(p_message) : la personne ne
-- pose et ne retire que SON coeur. Participation verifiee (elle lit le fil du
-- message). Appels repetes sans effet : un coeur deja donne reste donne, un coeur
-- deja retire reste retire. Les deux rendent l'etat vrai apres l'appel :
-- { coeurs : nombre, aime_par_moi : booleen }.
--
-- Refus : CoeurNonAutorise (42501) ; message ou fil illisible = meme refus.
-- Les autres parties du fil sont prevenues par le signal « message » du temps
-- reel (com_signaux) : leur ecran relit le fil et voit le nouveau compte.
--
-- FICHIER SANS MOT D'EFFACEMENT, sans BEGIN ni COMMIT de premier niveau.
-- S'installe apres 20261128200000.

CREATE OR REPLACE FUNCTION private.com_coeur_poser(p_message_id uuid, p_donne boolean)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_fil uuid;
  v_droits record;
  v_change boolean := false;
  v_n integer;
  v_qui uuid;
BEGIN
  SELECT m.fil_id INTO v_fil FROM public.com_messages m WHERE m.id = p_message_id;
  SELECT * INTO v_droits FROM private.com_image_droits(v_fil);
  IF v_fil IS NULL OR v_droits.p_lire IS NOT TRUE THEN
    RAISE EXCEPTION 'CoeurNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_donne THEN
    INSERT INTO public.com_message_coeurs AS c (message_id, auteur)
    VALUES (p_message_id, v_droits.p_moi)
    ON CONFLICT (message_id, auteur) DO UPDATE
      SET retire_le = NULL, cree_le = pg_catalog.clock_timestamp()
      WHERE c.retire_le IS NOT NULL;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_change := v_n > 0;
  ELSE
    UPDATE public.com_message_coeurs c
       SET retire_le = pg_catalog.clock_timestamp()
     WHERE c.message_id = p_message_id AND c.auteur = v_droits.p_moi AND c.retire_le IS NULL;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_change := v_n > 0;
  END IF;
  IF v_change THEN
    BEGIN
      FOR v_qui IN SELECT d FROM private.com_destinataires_signal(v_fil, v_droits.p_moi) AS d LOOP
        PERFORM private.com_signal_poser(v_qui, v_fil, 'message');
      END LOOP;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'coeurs messagerie : signal non pose (%)', SQLSTATE;
    END;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'coeurs', (SELECT pg_catalog.count(*) FROM public.com_message_coeurs c
                WHERE c.message_id = p_message_id AND c.retire_le IS NULL),
    'aime_par_moi', EXISTS (SELECT 1 FROM public.com_message_coeurs c
                             WHERE c.message_id = p_message_id AND c.auteur = v_droits.p_moi
                               AND c.retire_le IS NULL));
END;
$function$;

CREATE OR REPLACE FUNCTION public.aimer_message(p_message uuid)
RETURNS jsonb LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT private.com_coeur_poser(p_message, true);
$function$;

CREATE OR REPLACE FUNCTION public.ne_plus_aimer_message(p_message uuid)
RETURNS jsonb LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT private.com_coeur_poser(p_message, false);
$function$;

REVOKE ALL ON FUNCTION private.com_coeur_poser(uuid, boolean) FROM PUBLIC, anon, authenticated, service_role;
DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.aimer_message(uuid)', 'public.ne_plus_aimer_message(uuid)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', f);
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.com_coeur_poser(uuid, boolean) FROM agent_ro';
  END IF;
END
$acl$;
