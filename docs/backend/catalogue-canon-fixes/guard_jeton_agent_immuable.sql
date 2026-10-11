CREATE OR REPLACE FUNCTION public.guard_jeton_agent_immuable()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if new.id is distinct from old.id
     or new.libelle is distinct from old.libelle
     or new.prefixe is distinct from old.prefixe
     or new.empreinte is distinct from old.empreinte
     or new.profil_observe is distinct from old.profil_observe
     or new.parcours is distinct from old.parcours
     or new.identite_masquee is distinct from old.identite_masquee
     or new.expire_le is distinct from old.expire_le
     or new.cree_par is distinct from old.cree_par
     or new.cree_le is distinct from old.cree_le
  then
    raise exception 'la portee d un jeton agent est figee a l emission'
      using errcode = '42501';
  end if;

  -- Une revocation ne se defait pas : rendre un jeton revoque ferait mentir
  -- toute trace deja ecrite.
  if old.revoque_le is not null and new.revoque_le is null then
    raise exception 'un jeton agent revoque ne se reactive pas'
      using errcode = '42501';
  end if;

  return new;
end;
$function$

