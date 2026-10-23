-- 0009 : `ADM-04`, le journal d'audit.
--
-- Perimetre fixe par docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md section 5
-- (« Lecture seule. Filtres par acteur, par type d'evenement, par periode.
-- Aucun bouton d'action, aucune exception ») et par
-- docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md section 3 (« Cartes / Cartes / Tableau
-- dense, c'est sa forme naturelle »).
--
-- Aucune table, aucune colonne, aucune policy : `audit_logs` existe depuis
-- l'etape 1, elle est deja remplie, deja append-only, et deja lisible par
-- l'administration. Ce fichier n'ajoute que **trois lectures**.
--
-- Trois choix portes ici, pas dans le Dart :
--
--   1. **La chaine de hachage devient verifiable.** `audit_logs` porte
--      `prev_hash` et `hash` depuis 0001, et `log_sensitive_access` paie un
--      `lock table` a chaque ecriture pour les tenir. Jusqu'a aujourd'hui
--      personne ne les relisait : le cout etait paye, la garantie jamais
--      constatee. `verifier_chaine_audit()` recalcule le condensat depuis les
--      colonnes stockees et compare. Mesure faite sur la base reelle avant
--      d'ecrire cette migration : 34 entrees sur 34 se recalculent, 34 maillons
--      sur 34 se chainent.
--
--   2. **La verification ne voyage pas avec la liste.** Un `lag()` pose sur une
--      liste FILTREE comparerait chaque entree a la precedente *du filtre*, pas
--      a la precedente de la chaine : le journal se dirait rompu des le premier
--      filtre pose. La verification porte donc sur la fenetre non filtree, dans
--      sa propre fonction, et la liste ne calcule aucun condensat -- sans quoi
--      chaque page couterait un sha256 par ligne.
--
--   3. **Ces trois lectures sont reservees a `admin`, alors que la policy
--      `audit_logs_read` de 0001 autorise aussi `controller`.** Ce n'est pas un
--      retrecissement : un controleur lit `audit_logs` exactement comme avant,
--      par la table. Mais ces fonctions sont `security definer`, donc elles
--      passent au dessus de la RLS, et elles resolvent l'identite de l'acteur
--      par `profiles` -- or `profiles_family_select` ne laisse un controleur
--      voir que les profils de SON foyer. Ouvrir ces fonctions au controleur
--      lui donnerait les noms de tout le personnel. La porte reste donc a
--      l'administration, et la policy d'origine n'est pas touchee.
--
-- Ce qui n'est PAS fait, et pourquoi : **la consultation du journal ne
-- s'inscrit pas au journal.** `log_sensitive_access` prend un `lock table` en
-- `share row exclusive` : journaliser une lecture paginee et filtree ferait
-- prendre ce verrou a chaque page, serialisant les lectures du journal contre
-- toutes les ecritures du produit, et noierait les evenements metier sous les
-- traces de leur propre consultation. Question 27 du registre de
-- `decisions.md` : c'est a l'operateur de trancher si une trace de
-- consultation doit exister, et sous quelle forme.

begin;

-- ============================================================
-- 1. Ce que la liste affiche
-- ============================================================

-- Le journal, le plus recent d'abord, filtre et pagine.
--
-- Les colonnes de sortie sont nommees differemment de celles d'`audit_logs`
-- (`entree_id` et non `id`, `survenu_le` et non `created_at`) : dans une
-- fonction plpgsql `returns table`, un nom de sortie masque la colonne de meme
-- nom, et la moindre reference non qualifiee devient ambigue.
--
-- La pagination est un keyset sur `(created_at, id)`, pas un `offset` : un
-- journal append-only recoit des lignes pendant qu'on le parcourt, et un
-- `offset` ferait sauter ou rejouer une entree a chaque page. C'est aussi le
-- couple de la cle primaire, et l'ordre exact que `log_sensitive_access`
-- emploie pour chainer.
create function public.journal_audit(
  p_acteur uuid default null,
  p_action text default null,
  p_depuis timestamptz default null,
  p_limite int default 50,
  p_avant_date timestamptz default null,
  p_avant_id bigint default null
)
returns table (
  entree_id bigint,
  survenu_le timestamptz,
  acteur uuid,
  role_acteur text,
  nom_acteur text,
  type_evenement text,
  table_visee text,
  ligne_visee text,
  details jsonb
)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 200 then
    raise exception 'limite hors bornes';
  end if;

  -- Les deux bornes du keyset voyagent ensemble ou pas du tout. Separees, la
  -- comparaison de lignes vaudrait NULL et la page suivante serait vide : un
  -- journal qui s'arrete au bout d'une page ressemble a un journal qui finit.
  if (p_avant_date is null) <> (p_avant_id is null) then
    raise exception 'curseur incomplet';
  end if;

  return query
  select
    a.id,
    a.created_at,
    a.actor,
    a.actor_role,
    -- Le nom complet quand le profil existe encore, l'identifiant immuable
    -- sinon. Un acteur supprime garde sa ligne de journal : c'est tout
    -- l'interet d'un journal immuable, et l'ecran ne doit pas la rendre
    -- anonyme pour autant.
    coalesce(
      nullif(trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')), ''),
      p.immutable_id
    ),
    a.action,
    a.table_name,
    a.row_id,
    a.payload
  from public.audit_logs a
  left join public.profiles p on p.id = a.actor
  where (p_acteur is null or a.actor = p_acteur)
    and (p_action is null or a.action = p_action)
    and (p_depuis is null or a.created_at >= p_depuis)
    and (
      p_avant_date is null
      or (a.created_at, a.id) < (p_avant_date, p_avant_id)
    )
  order by a.created_at desc, a.id desc
  limit p_limite;
end;
$$;

revoke execute on function public.journal_audit(uuid, text, timestamptz, int, timestamptz, bigint)
  from public, anon;
grant execute on function public.journal_audit(uuid, text, timestamptz, int, timestamptz, bigint)
  to authenticated;

-- ============================================================
-- 2. Ce que les filtres proposent
-- ============================================================

-- Les valeurs reellement presentes dans le journal, acteurs et types
-- d'evenements, chacune avec son nombre.
--
-- **Une seule fonction pour les deux listes**, et un `jsonb` plutot que deux
-- `returns table` : l'ecran les affiche cote a cote et les recharge ensemble,
-- deux appels ne serviraient qu'a les desynchroniser.
--
-- Les valeurs viennent du journal, jamais d'une liste ecrite en dur : un filtre
-- qui propose un type d'evenement que la base n'a jamais enregistre offre a
-- l'administration un chemin vers un ecran vide.
create function public.journal_audit_filtres()
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_resultat jsonb;
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  select jsonb_build_object(
    'total', (select count(*) from public.audit_logs),
    'premiere', (select min(x.created_at) from public.audit_logs x),
    'actions', coalesce((
      select jsonb_agg(
        jsonb_build_object('action', t.action, 'n', t.n)
        order by t.n desc, t.action asc
      )
      from (
        select a.action, count(*) as n
        from public.audit_logs a
        group by a.action
      ) t
    ), '[]'::jsonb),
    'acteurs', coalesce((
      select jsonb_agg(
        jsonb_build_object('id', u.actor, 'nom', u.nom, 'role', u.role, 'n', u.n)
        order by u.n desc, u.nom asc
      )
      from (
        select
          a.actor,
          count(*) as n,
          -- Le role LE PLUS RECENT, pas un role au hasard : un membre du
          -- personnel promu garde ses anciennes lignes avec son ancien role,
          -- et grouper par (acteur, role) le ferait apparaitre deux fois dans
          -- un filtre qui designe une personne.
          (array_agg(a.actor_role order by a.created_at desc, a.id desc))[1] as role,
          coalesce(
            nullif(trim(coalesce(max(p.first_name), '') || ' ' || coalesce(max(p.last_name), '')), ''),
            max(p.immutable_id),
            a.actor::text
          ) as nom
        from public.audit_logs a
        left join public.profiles p on p.id = a.actor
        where a.actor is not null
        group by a.actor
      ) u
    ), '[]'::jsonb)
  ) into v_resultat;

  return v_resultat;
end;
$$;

revoke execute on function public.journal_audit_filtres() from public, anon;
grant execute on function public.journal_audit_filtres() to authenticated;

-- ============================================================
-- 3. Ce qui rend le journal verifiable
-- ============================================================

-- Recalcule la chaine de hachage sur les `p_limite` dernieres entrees.
--
-- La formule est celle de `log_sensitive_access` (0001), a l'identique et pour
-- cause : toute divergence ferait passer un journal intact pour rompu.
--
--   condensat = sha256(acteur || role || action || table || ligne || payload)
--   hash      = sha256(prev_hash || condensat)
--
-- Les six morceaux du condensat sont TOUS stockes en colonnes : `auth.uid()`
-- dans `actor`, `public.app_role()` dans `actor_role`, le reste tel quel. Le
-- `coalesce(..., '')` reproduit celui de l'ecriture -- une colonne nulle y
-- valait la chaine vide, pas NULL.
--
-- `payload::text` se recalcule a l'identique parce que la colonne est `jsonb` :
-- le rendu est canonique, donc le meme a l'ecriture et a la lecture. Avec une
-- colonne `json`, l'espacement d'origine aurait survecu et la comparaison
-- aurait echoue sur des entrees pourtant saines.
--
-- Deux controles distincts par entree, et il faut les deux :
--
--   * **le condensat** dit que la ligne n'a pas ete modifiee ;
--   * **le maillon** (`prev_hash` = hash de l'entree precedente) dit qu'aucune
--     ligne n'a ete retiree entre les deux. Une suppression laisse les
--     condensats intacts et ne se voit QUE la.
create function public.verifier_chaine_audit(p_limite int default 200)
returns table (
  verifiees int,
  rompues int,
  premiere_rompue bigint,
  rompue_le timestamptz
)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.app_role() <> 'admin' then
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
$$;

revoke execute on function public.verifier_chaine_audit(int) from public, anon;
grant execute on function public.verifier_chaine_audit(int) to authenticated;

commit;
