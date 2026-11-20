-- PE-D1 MESSAGERIE-FIABLE (parcours enseignant, plan section 4.1), 20/11/2026.
--
-- CONSTAT : une conversation se lit d'un bloc (`public.com_lire_fil`, tous ses messages), et le serveur ne rend pas la
-- cle d'envoi d'un message (`com_messages.cle_idempotence`) : l'application rapproche sa bulle locale du message confirme
-- par le TEXTE, et une bulle en echec reste a l'ecran meme quand le message est en fait arrive.
--
-- AJOUT UNIQUE : public.com_lire_fil_page(p_fil_id, p_avant, p_limite), en lecture seule.
--   * Les droits sont ceux de `com_lire_fil` : meme appelant (`private.com_appelant_msg`), meme passage
--     `private.com_fil_json` (appele tel quel, JAMAIS retouche). Un fil refuse ou absent rend NULL.
--   * Le fil rendu a la forme de `com_lire_fil`, mais `messages` n'en garde qu'une page : les `p_limite` messages
--     (1 a 200, 50 par defaut) qui precedent le message `p_avant` (le plus ancien deja montre), ou les derniers si
--     `p_avant` est NULL ; toujours du plus ancien au plus recent, dans l'ordre de `com_fil_json`.
--   * `plus_anciens` dit s'il reste des messages avant la page.
--   * Chaque message DE L'APPELANT porte sa `cle_idempotence` (celle qu'il a lui-meme envoyee) ; jamais celle d'un autre.
--   * Un `p_avant` que le fil ne montre pas a l'appelant rend une page vide, sans `plus_anciens`.
--
-- Rien d'autre : aucune table, aucune donnee, aucune fonction existante n'est modifiee ; aucun mot d'effacement.
-- Scenario : supabase/tests/scenarios_com_lire_fil_page.sql.

DO $garde$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_fil_json(uuid,uuid,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.com_appelant_msg()') IS NULL THEN
    RAISE EXCEPTION 'com_lire_fil_page : private.com_fil_json ou private.com_appelant_msg absente';
  END IF;
  IF pg_catalog.to_regprocedure('public.com_lire_fil_page(uuid,uuid,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'com_lire_fil_page : la fonction existe deja';
  END IF;
END
$garde$;

CREATE FUNCTION public.com_lire_fil_page(p_fil_id uuid, p_avant uuid DEFAULT NULL, p_limite integer DEFAULT 50)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  moi record;
  v_json jsonb;
  v_limite integer := LEAST(GREATEST(coalesce(p_limite, 50), 1), 200);
  v_rang bigint;
  v_page jsonb;
  v_avant bigint;
BEGIN
  SELECT * INTO moi FROM private.com_appelant_msg();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fil_id IS NULL THEN RETURN NULL; END IF;
  v_json := private.com_fil_json(p_fil_id, moi.id, moi.role, moi.foyer);
  IF v_json IS NULL THEN RETURN NULL; END IF;
  -- Le rang du message `p_avant` dans le fil tel que l'appelant le voit.
  IF p_avant IS NOT NULL THEN
    SELECT e.n INTO v_rang
      FROM pg_catalog.jsonb_array_elements(v_json -> 'messages') WITH ORDINALITY AS e(m, n)
     WHERE (e.m ->> 'id') = p_avant::text;
    IF v_rang IS NULL THEN
      RETURN v_json || pg_catalog.jsonb_build_object('messages', '[]'::jsonb, 'plus_anciens', false);
    END IF;
  END IF;
  WITH avant AS (
    SELECT e.m, e.n
      FROM pg_catalog.jsonb_array_elements(v_json -> 'messages') WITH ORDINALITY AS e(m, n)
     WHERE v_rang IS NULL OR e.n < v_rang
  ), page AS (
    SELECT a.m, a.n FROM avant a ORDER BY a.n DESC LIMIT v_limite
  )
  SELECT coalesce(pg_catalog.jsonb_agg(
           p.m || coalesce((SELECT pg_catalog.jsonb_build_object('cle_idempotence', c.cle_idempotence)
                              FROM public.com_messages c
                             WHERE c.id = (p.m ->> 'id')::uuid AND c.fil_id = p_fil_id AND c.auteur_id = moi.id),
                           '{}'::jsonb)
           ORDER BY p.n), '[]'::jsonb),
         (SELECT pg_catalog.count(*) FROM avant)
    INTO v_page, v_avant
    FROM page p;
  RETURN v_json || pg_catalog.jsonb_build_object('messages', v_page, 'plus_anciens', v_avant > v_limite);
END;
$function$;

REVOKE ALL ON FUNCTION public.com_lire_fil_page(uuid, uuid, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.com_lire_fil_page(uuid, uuid, integer) FROM anon;
GRANT EXECUTE ON FUNCTION public.com_lire_fil_page(uuid, uuid, integer) TO authenticated;

COMMENT ON FUNCTION public.com_lire_fil_page(uuid, uuid, integer) IS
  'PE-D1 (20/11/2026) : une page des messages d''un fil, droits de com_lire_fil (private.com_fil_json), cle '
  'd''idempotence des seuls messages de l''appelant, plus_anciens. Lecture seule.';

-- Controle final.
DO $controle$
DECLARE
  v_f regprocedure := 'public.com_lire_fil_page(uuid,uuid,integer)'::regprocedure;
BEGIN
  IF NOT (SELECT p.prosecdef FROM pg_catalog.pg_proc p WHERE p.oid = v_f) THEN
    RAISE EXCEPTION 'com_lire_fil_page : SECURITY DEFINER attendu';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'com_lire_fil_page : search_path vide attendu';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'com_lire_fil_page : droits inattendus (anon refuse, authenticated autorise)';
  END IF;
END
$controle$;
