-- 0067 — les gardes de rôle doivent échouer lorsque le rôle JWT est absent.
begin;

-- Les gardes « role <> attendu OR not compte_valide » évaluent NULL quand
-- le jeton ne porte aucun rôle et que le compte existe. En PL/pgSQL, IF NULL
-- ne prend pas la branche : l'appelant franchit alors le contrôle de rôle.
-- pg_get_functiondef permet une correction additive qui préserve chaque
-- signature, attribut de sécurité, corps métier et ACL historique.
do $migration$
declare
  v record;
  v_definition text;
  v_corrigee text;
  v_modifiees integer := 0;
begin
  for v in
    select p.oid, p.proname
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.proname = any (array[
        'prendre_eleve',
        'attribuer_eleve',
        'creer_jeton_agent',
        'revoquer_jeton_agent',
        'creer_groupe',
        'modifier_groupe',
        'ajouter_eleve_groupe',
        'retirer_eleve_groupe',
        'cloturer_groupe',
        'creer_version_programme',
        'ajouter_niveau_programme',
        'modifier_niveau_programme',
        'supprimer_niveau_programme',
        'publier_version_programme'
      ])
      and p.prosrc ~* 'if[[:space:]]+public\.app_role\(\)[[:space:]]*<>[[:space:]]*''[^'']+''[[:space:]]+or[[:space:]]+not[[:space:]]+public\.app_account_valid\(\)[[:space:]]+then'
  loop
    v_definition := pg_catalog.pg_get_functiondef(v.oid);
    v_corrigee := pg_catalog.regexp_replace(
      v_definition,
      'if[[:space:]]+public\.app_role\(\)[[:space:]]*<>[[:space:]]*''([^'']+)''[[:space:]]+or[[:space:]]+not[[:space:]]+public\.app_account_valid\(\)[[:space:]]+then',
      'if not coalesce(public.app_role() = ''\1'' and public.app_account_valid(), false) then',
      'gi'
    );
    if v_definition = v_corrigee then
      raise exception 'SEC-ROLE : garde négative non remplacée dans %', v.proname;
    end if;
    execute v_corrigee;
    v_modifiees := v_modifiees + 1;
  end loop;

  if v_modifiees <> 14 then
    raise exception 'SEC-ROLE : 14 fonctions attendues, % corrigées', v_modifiees;
  end if;
end
$migration$;

commit;
