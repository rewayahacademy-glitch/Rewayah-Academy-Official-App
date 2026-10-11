CREATE OR REPLACE FUNCTION public.verifier_chaine_audit(p_limite integer DEFAULT 200)
 RETURNS TABLE(verifiees integer, rompues integer, premiere_rompue bigint, rompue_le timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 5000 then
    raise exception 'limite hors bornes';
  end if;

  return query
  with fenetre as (
    -- Une entree de plus que demande : la plus ancienne de la fenetre ne sert
    -- qu'a fournir son hash a la suivante. Sans elle, la premiere entree
    -- verifiee n'aurait aucun predecesseur et son maillon passerait sans etre
    -- controle.
    select a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name,
           a.row_id, a.payload, a.prev_hash, a.hash
    from public.audit_logs a
    order by a.created_at desc, a.id desc
    limit p_limite + 1
  ),
  chainee as (
    select f.*,
           lag(f.hash) over (order by f.created_at, f.id) as hash_precedent,
           row_number() over (order by f.created_at desc, f.id desc) as rang
    from fenetre f
  ),
  controle as (
    select
      c.id,
      c.created_at,
      c.hash = encode(extensions.digest(convert_to(
        c.prev_hash || encode(extensions.digest(convert_to(
          coalesce(c.actor::text, '') || coalesce(c.actor_role, '') || c.action ||
          c.table_name || coalesce(c.row_id, '') || c.payload::text, 'UTF8'),
        'sha256'), 'hex'), 'UTF8'), 'sha256'), 'hex')
      -- `hash_precedent` n'est nul que pour la plus ancienne ligne de la
      -- fenetre, et celle-la est ecartee par le `rang` -- sauf quand le journal
      -- entier tient dans la fenetre, ou la toute premiere entree de la base
      -- n'a legitimement aucun predecesseur.
      and (c.hash_precedent is null or c.prev_hash = c.hash_precedent) as intacte
    from chainee c
    where c.rang <= p_limite
  )
  select
    count(*)::int,
    count(*) filter (where not k.intacte)::int,
    min(k.id) filter (where not k.intacte),
    min(k.created_at) filter (where not k.intacte)
  from controle k;
end;
$function$

