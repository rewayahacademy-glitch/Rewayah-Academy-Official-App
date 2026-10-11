CREATE OR REPLACE FUNCTION public.agent_pre_request()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_id uuid;
  v_profil_observe uuid;
BEGIN
  v_id := public.agent_jeton_id();
  IF v_id IS NULL THEN
    RETURN;
  END IF;

  IF auth.jwt() ->> 'sub' IS DISTINCT FROM v_id::text THEN
    RAISE EXCEPTION 'jeton agent refuse'
      USING ERRCODE = '42501';
  END IF;

  SELECT p.id
    INTO v_profil_observe
    FROM public.jetons_agent t
    JOIN public.profiles p ON p.id = t.profil_observe
   WHERE t.id = v_id
     AND t.revoque_le IS NULL
     AND t.expire_le > pg_catalog.now()
     AND p.deleted_at IS NULL
     AND p.account_status IN ('active', 'provisional_active')
     AND p.role = t.parcours;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'jeton agent refuse'
      USING ERRCODE = '42501';
  END IF;

  -- Transaction-local compatibility for existing auth.uid()-bounded policies.
  -- auth.jwt() still exposes the signed token's opaque subject and claims.
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    v_profil_observe::text,
    true
  );
END;
$function$

