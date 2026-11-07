-- SCENARIOS-ISOLES (07/11/2026) : la CI rejoue tous les scenarios sur la meme
-- base. Un scenario qui valide ses fixtures (sans ROLLBACK final) inclut ce
-- fichier en tete et _lignes_retablir.sql a la fin : la base revient a l'etat
-- de la photographie (lignes ajoutees retirees, lignes modifiees ou retirees
-- remises comme avant), et les suivants comptent sur une base propre.
-- Meme modele que _acl_photo.sql / _acl_retablir.sql.
--
-- Photographie : pour chaque table de public, private et auth, chaque ligne
-- (sa cle primaire et son contenu en jsonb).
-- Garde : ce fichier ne sert qu'aux bases de test. Il refuse de s'executer sans
-- le marqueur de stub_auth.sql (auth.uid() lit le reglage test.uid, ce que ne
-- fait jamais l'auth.uid() de Supabase) ou avec plus de 10 000 comptes : une
-- erreur de chemin ne retire jamais rien d'une vraie base.
do $garde_base_de_test$
begin
  if pg_catalog.strpos(coalesce((select p.prosrc from pg_catalog.pg_proc p
                                  where p.oid = pg_catalog.to_regprocedure('auth.uid()')), ''),
                       'test.uid') = 0
     or (select pg_catalog.count(*) from auth.users) > 10000 then
    raise exception 'SCENARIOS-ISOLES : base qui n''est pas une base de test (marqueur de stub_auth.sql absent ou plus de 10 000 comptes) : rien n''est fait';
  end if;
end
$garde_base_de_test$;

create temp table lignes_avant_scenario (tbl oid, cle text, ligne jsonb);

create function pg_temp.cle_lignes(p_tbl oid) returns text
language sql stable as $$
  select coalesce(
    (select 'row(' || string_agg(pg_catalog.format('t.%I', a.attname), ', ' order by k.n) || ')::text'
       from pg_catalog.pg_index i
       cross join lateral unnest(i.indkey) with ordinality k(attnum, n)
       join pg_catalog.pg_attribute a on a.attrelid = i.indrelid and a.attnum = k.attnum
      where i.indrelid = p_tbl and i.indisprimary),
    't::text')
$$;

create function pg_temp.tables_lignes() returns setof oid
language sql stable as $$
  select c.oid
    from pg_catalog.pg_class c
   where c.relkind = 'r'
     and c.relnamespace in ('public'::regnamespace, 'private'::regnamespace, 'auth'::regnamespace)
$$;

-- Les colonnes qu'on peut ecrire (ni generees, ni identite ALWAYS), avec un prefixe.
create function pg_temp.colonnes_lignes(p_tbl oid, p_prefixe text) returns text
language sql stable as $$
  select string_agg(p_prefixe || pg_catalog.format('%I', a.attname), ', ' order by a.attnum)
    from pg_catalog.pg_attribute a
   where a.attrelid = p_tbl and a.attnum > 0 and not a.attisdropped
     and a.attgenerated = '' and a.attidentity <> 'a'
$$;

do $lignes_photo$
declare
  v_tbl oid;
begin
  for v_tbl in select pg_temp.tables_lignes() loop
    execute pg_catalog.format(
      'insert into lignes_avant_scenario select %s, %s, pg_catalog.to_jsonb(t) from %s t',
      v_tbl, pg_temp.cle_lignes(v_tbl), v_tbl::regclass);
  end loop;
end
$lignes_photo$;
create index on lignes_avant_scenario (tbl, cle);
