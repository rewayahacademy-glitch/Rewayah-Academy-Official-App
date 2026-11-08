-- ROSTER-REMPLACANT (08/11/2026) : le remplacant d'une seance lit le roster de la Classe.
--
-- Constat (pilote, 08/11) : en production `public.groupe_roster_enseignant(uuid)` ne laisse
-- passer que `g.teacher_id = auth.uid()`. Le remplacant actif d'une seance ne voit donc pas la
-- position de reprise ni le travail a preparer des eleves, alors que CAHIER-C1 le couvre
-- (`private.cahier_c1_peut_lire_classe`). DECISION-REMPLACEMENT : un seul circuit.
--
-- Ce que fait la migration : la garde `g.teacher_id = auth.uid()` devient
-- `private.cahier_c1_peut_lire_classe(g.id)`, le MEME predicat que CAHIER-C1, appele et non
-- recopie. Le role `teacher` et le compte valide restent exiges : la branche « direction » de
-- ce predicat (role admin) ne s'ouvre donc pas ici, la direction ne lit pas ce roster
-- aujourd'hui et ne le lira pas (ADR-008 : jamais groupe_detail, admin-only).
-- Pour un enseignant : le titulaire de la Classe (identique a avant), ou l'enseignant effectif
-- d'une seance de la Classe non passee depuis plus d'un jour.
--
-- Signature, colonnes, droits, volatilite : INCHANGES. Aucune table, aucune politique. Sans mot
-- d'effacement.

DO $preflight$
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.groupe_roster_enseignant(uuid)'::pg_catalog.regprocedure))
       <> '20212f9b34187cef242bc98ce2fa57a2' THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : groupe_roster_enseignant a change depuis la relecture, migration a revoir';
  END IF;
  IF pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : CAHIER-C1 absent (private.cahier_c1_peut_lire_classe)';
  END IF;
  -- Le predicat appele est celui relu : 2d884d815e696c98f82ff2aeb0adb9a1 est l'empreinte du REJEU
  -- des migrations du depot ; a recaler sur la production par le garde-cap avant l'installation.
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('private.cahier_c1_peut_lire_classe(uuid)'::pg_catalog.regprocedure))
       <> '2d884d815e696c98f82ff2aeb0adb9a1' THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : cahier_c1_peut_lire_classe a change depuis la relecture, migration a revoir';
  END IF;
END
$preflight$;

create or replace function public.groupe_roster_enseignant(p_groupe_id uuid)
returns table (
  student_id      uuid,
  first_name      text,
  immutable_id    text,
  level           text,
  riwaya          text,
  interface_mode  public.interface_mode,
  curriculum_path text,
  current_unit    text,
  active_goals    text[],
  resume_page     int,
  resume_sourate  int,
  resume_verset   int
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    case when public.agent_identite_masquee() then p.immutable_id else p.first_name end,
    p.immutable_id,
    sp.level,
    sp.riwaya,
    sp.interface_mode,
    prog.cycle,
    prog.nom_humain,
    coalesce(goals.objectifs, '{}'),
    pos.page_mushaf,
    pos.sourate,
    pos.verset
  from public.groupe_membres m
    join public.groupes g on g.id = m.groupe_id
    join public.profiles p on p.id = m.student_id
    join public.student_profiles sp on sp.profile_id = p.id
    left join lateral (
      select pn.cycle, pn.nom_humain
        from public.progression_historique ph
        join public.programme_niveaux pn on pn.id = ph.niveau_id
       where ph.student_id = p.id
       order by ph.created_at desc
       limit 1
    ) prog on true
    left join lateral (
      select srp.page_mushaf, srp.sourate, srp.verset
        from public.student_reading_position srp
       where srp.student_profile_id = p.id
       order by srp.updated_at desc
       limit 1
    ) pos on true
    left join lateral (
      select array(
        select la.purpose
          from public.learning_assignment la
         where (la.student_id = p.id or (la.student_id is null and la.group_id = g.id))
           and la.status in ('a_faire', 'en_cours')
         order by la.due_at nulls last, la.starts_at
         limit 3
      ) as objectifs
    ) goals on true
  where m.groupe_id = p_groupe_id
    and m.left_at is null
    and p.deleted_at is null
    and private.cahier_c1_peut_lire_classe(g.id)
    and public.app_role() = 'teacher'
    and public.app_account_valid();
$$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.groupe_roster_enseignant(uuid)'::pg_catalog.regprocedure),
                       'private.cahier_c1_peut_lire_classe') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.groupe_roster_enseignant(uuid)'::pg_catalog.regprocedure),
                          'g.teacher_id = auth.uid()') > 0 THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : la garde n''est pas celle de CAHIER-C1';
  END IF;
  -- Nouvelle empreinte (relevee au rejeu ; une fin de ligne alteree la ferait echouer ici).
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.groupe_roster_enseignant(uuid)'::pg_catalog.regprocedure))
       <> '057fa957e5266bc5aa0ae3b3c26e9342' THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : l''empreinte de la fonction installee n''est pas celle attendue';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.groupe_roster_enseignant(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ROSTER-REMPLACANT : droits d''execution inattendus';
  END IF;
END
$postflight$;
