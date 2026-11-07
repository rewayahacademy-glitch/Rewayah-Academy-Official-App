-- REVENUS (07/11/2026, file du garde-cap transmise par le pilote) : l'ecran
-- des revenus de l'enseignant dit la presence de chaque eleve telle que la
-- paie la compte, et si une seance est payee.
--
-- Fichier SANS mot d'effacement (regle B5) : le pilote l'installe.
--
-- Retouche PAR ANCRES (regle B4, pg_temp.remplacer) de
-- public.mes_revenus_enseignant(date), rien d'autre. Aucune regle de calcul
-- ne change : les montants restent ceux ecrits par private.pai_due_seance,
-- et un eleve « partielle » etait deja compte present et paye (la CTE
-- `eleves` et private.pai_eleves_presents prennent 'presente' et
-- 'partielle'). Deux champs s'AJOUTENT a la reponse (regle B6 : l'ancien
-- client les ignore, 'present' ne change pas) :
--   * par eleve, 'presence' : 'presente', 'partielle' ou 'absente' (toute
--     autre valeur de private.presence_temps_reel, non payee, se dit
--     'absente', comme 'present' la dit faux) ;
--   * par seance, 'payable' : vrai quand au moins un eleve est present ou
--     present en partie. Le client n'affiche alors aucun montant pour une
--     seance non payee.
--
-- Preflight : md5(pg_get_functiondef) de production 323c74a9aa713523745ac42ab3a0705c,
-- relu le 07/11/2026 en lecture seule, identique a la base rejouee depuis le
-- depot ; chaque ancre presente exactement une fois.
-- Rejeu : la retouche deja la (marqueur 'payable'), rien n'est reapplique.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
do $preflight$
declare
  v_def text := pg_catalog.pg_get_functiondef('public.mes_revenus_enseignant(date)'::regprocedure);
begin
  if pg_catalog.md5(v_def) <> '323c74a9aa713523745ac42ab3a0705c'
     and pg_catalog.strpos(v_def, '''payable''') = 0 then
    raise exception 'REVENUS : mes_revenus_enseignant a change depuis la lecture du 07/11 (md5 %), rien n''est change',
      pg_catalog.md5(v_def);
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. Retouches par ancres (sautees au rejeu)
-- ---------------------------------------------------------------------------
create or replace function pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
returns void
language plpgsql
as $function$
declare
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
begin
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  if v_n <> p_n then
    raise exception '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  end if;
  execute pg_catalog.replace(v_def, p_avant, p_apres);
end;
$function$;

do $retouches$
declare
  v_f constant pg_catalog.regprocedure := 'public.mes_revenus_enseignant(date)'::regprocedure;
begin
  if pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), '''payable''') > 0 then
    raise notice 'REVENUS : retouches deja presentes, rien n''est reapplique';
    return;
  end if;

  -- 2.1 La presence lue, gardee a cote du booleen paye.
  perform pg_temp.remplacer(v_f,
    $a$(t.statut IN ('presente', 'partielle')) AS present$a$,
    $b$(t.statut IN ('presente', 'partielle')) AS present, t.statut AS statut$b$, 1);

  perform pg_temp.remplacer(v_f,
    $a$SELECT r.seance, r.eleve, r.prenom, r.present,$a$,
    $b$SELECT r.seance, r.eleve, r.prenom, r.present, r.statut,$b$, 1);

  -- 2.2 Par eleve : 'presence'.
  perform pg_temp.remplacer(v_f,
    $a$'eleveId', x.eleve, 'prenom', x.prenom, 'present', x.present,$a$,
    $b$'eleveId', x.eleve, 'prenom', x.prenom, 'present', x.present,
                      'presence', CASE WHEN x.statut = 'partielle' THEN 'partielle'
                                       WHEN x.present THEN 'presente'
                                       ELSE 'absente' END,$b$, 1);

  -- 2.3 Par seance : 'payable', au moins un eleve paye.
  perform pg_temp.remplacer(v_f,
    $a$'minutes', s.minutes,$a$,
    $b$'minutes', s.minutes,
           'payable', EXISTS (SELECT 1 FROM parts x WHERE x.seance = s.seance AND x.present),$b$, 1);
end;
$retouches$;

-- Droits inchanges (create or replace les conserve) ; reaffirmes par prudence.
alter function public.mes_revenus_enseignant(date) owner to postgres;
revoke all on function public.mes_revenus_enseignant(date) from public, anon, service_role;
grant execute on function public.mes_revenus_enseignant(date) to authenticated;

comment on function public.mes_revenus_enseignant(date) is
  'BF1-01, FAC-E-02, PAIE-REMPLACANT, REVENUS-VERITE, REVENUS : revenus de l''enseignant connecte, lus dans tresorerie_mouvements (remuneration_due) pour les seances dont il est l''enseignant effectif ; par classe, par seance (payable) et par eleve (presence : presente, partielle ou absente), la fenetre du jour de paie, et les autres revenus du mois (aide Internet, primes, missions). Garde: teacher + compte valide; perimetre auth.uid(). date=2026-11-07.';

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
do $postflight$
declare
  v_def text := pg_catalog.pg_get_functiondef('public.mes_revenus_enseignant(date)'::regprocedure);
begin
  if pg_catalog.strpos(v_def, '''payable''') = 0
     or pg_catalog.strpos(v_def, '''presence''') = 0
     or pg_catalog.strpos(v_def, 't.statut AS statut') = 0
     or pg_catalog.strpos(v_def, 'private.bf1_montant(x.part, v_devise)') = 0
     or pg_catalog.strpos(v_def, 'remuneration_due') = 0 then
    raise exception 'REVENUS postflight : retouches ou calcul absents';
  end if;
  if pg_catalog.has_function_privilege('anon', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
     or pg_catalog.has_function_privilege('service_role', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
     or not pg_catalog.has_function_privilege('authenticated', 'public.mes_revenus_enseignant(date)', 'EXECUTE') then
    raise exception 'REVENUS postflight : droits EXECUTE incorrects';
  end if;
  if not exists (
       select 1 from pg_catalog.pg_proc p
        where p.oid = 'public.mes_revenus_enseignant(date)'::regprocedure
          and p.prosecdef
          and p.proconfig @> array['search_path=""']::text[]
          and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') then
    raise exception 'REVENUS postflight : SECURITY DEFINER, search_path ou proprietaire incorrect';
  end if;
end;
$postflight$;

COMMIT;
