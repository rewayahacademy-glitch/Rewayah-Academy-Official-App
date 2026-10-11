CREATE OR REPLACE FUNCTION public.unite_curriculum(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resultat jsonb;
begin
  -- Les migrations 0020 a 0024 ne sont pas appliquees sur toutes les bases.
  -- Une reference statique a `progression_historique` empecherait la creation
  -- de cette fonction ; le SQL dynamique garde par `to_regclass` rend `null`
  -- tant que la table est absente, et la vraie unite des qu'elle arrive.
  if to_regclass('public.progression_historique') is null
     or to_regclass('public.programme_niveaux') is null then
    return null;
  end if;

  -- `code_technique` voyage, mais l'interface a l'interdiction explicite de
  -- l'employer comme titre : il ne se dit qu'en sous-texte technique discret
  -- (`0020_programme_pedagogique.sql`). `nom_humain` est le libelle a afficher.
  execute $dyn$
    select jsonb_build_object(
             'niveau_id',      n.id,
             'nom_humain',     n.nom_humain,
             'code_technique', n.code_technique,
             'cycle',          n.cycle,
             'ordre',          n.ordre,
             'depuis',         h.created_at,
             'type_mouvement', h.type_mouvement
           )
      from public.progression_historique h
      join public.programme_niveaux n on n.id = h.niveau_id
     where h.student_id = $1
     order by h.created_at desc
     limit 1
  $dyn$
  into v_resultat
  using p_student_id;

  return v_resultat;
exception
  -- Une colonne absente ne doit pas faire echouer le preremplissage du cahier :
  -- l'unite est un enrichissement, pas la donnee qui porte l'ecran.
  when undefined_column or undefined_table then
    return null;
end;
$function$

