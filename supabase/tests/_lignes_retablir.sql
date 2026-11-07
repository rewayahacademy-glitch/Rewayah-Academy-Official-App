-- SCENARIOS-ISOLES (07/11/2026) : remet la base dans l'etat de
-- _lignes_photo.sql. Pour chaque table : les lignes ajoutees sont retirees,
-- les lignes modifiees reprennent leur contenu d'avant, les lignes retirees
-- reviennent. Les declencheurs et les cles etrangeres sont suspendus le temps
-- du retablissement (session_replication_role = replica, superutilisateur :
-- la CI se connecte en postgres) : un journal immuable ou une cascade ne
-- bloquent pas le menage, et l'ordre des tables n'importe pas.
reset role;
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

set session_replication_role = replica;
do $lignes_retablir$
declare
  v_tbl oid;
  v_cle text;
  v_n bigint;
  v_bilan text := '';
begin
  for v_tbl in select pg_temp.tables_lignes() loop
    v_cle := pg_temp.cle_lignes(v_tbl);
    execute pg_catalog.format(
      'delete from %s t where not exists (select 1 from lignes_avant_scenario a where a.tbl = %s and a.cle = %s)',
      v_tbl::regclass, v_tbl, v_cle);
    execute pg_catalog.format(
      'update %1$s t set (%2$s) = (select %3$s from pg_catalog.jsonb_populate_record(null::%1$s, a.ligne) r)'
      ' from lignes_avant_scenario a where a.tbl = %4$s and a.cle = %5$s and a.ligne is distinct from pg_catalog.to_jsonb(t)',
      v_tbl::regclass, pg_temp.colonnes_lignes(v_tbl, ''), pg_temp.colonnes_lignes(v_tbl, 'r.'), v_tbl, v_cle);
    get diagnostics v_n = row_count;
    if v_n > 0 then v_bilan := v_bilan || pg_catalog.format(' %s modifiees=%s', v_tbl::regclass, v_n); end if;
    execute pg_catalog.format(
      'insert into %1$s (%2$s) overriding system value select %3$s from lignes_avant_scenario a'
      ' cross join lateral pg_catalog.jsonb_populate_record(null::%1$s, a.ligne) r'
      ' where a.tbl = %4$s and not exists (select 1 from %1$s t where %5$s = a.cle)',
      v_tbl::regclass, pg_temp.colonnes_lignes(v_tbl, ''), pg_temp.colonnes_lignes(v_tbl, 'r.'), v_tbl, v_cle);
    get diagnostics v_n = row_count;
    if v_n > 0 then v_bilan := v_bilan || pg_catalog.format(' %s retirees=%s', v_tbl::regclass, v_n); end if;
  end loop;
  if v_bilan <> '' then
    raise notice 'SCENARIOS-ISOLES : remis comme avant :%', v_bilan;
  end if;
end
$lignes_retablir$;
set session_replication_role = origin;
drop table lignes_avant_scenario;
