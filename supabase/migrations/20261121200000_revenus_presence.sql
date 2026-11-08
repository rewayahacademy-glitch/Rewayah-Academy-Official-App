-- REVENUS-2 (08/11/2026, reprise de la branche claude/revenus sur main 84eb99dc ;
-- numero 20261121200000, posterieur a toute migration de main, au lieu de
-- 20261110220000 qui tombait dans la plage de REVENUS-VERITE et avant des
-- versions deja en production).
-- Revue du garde-cap (08/11, option i) : aucun champ 'payable' ; l'ecran
-- montre le montant que le serveur a ecrit, et « aucun montant » quand il
-- est nul ou absent. Aucune notion nouvelle.
-- REVENUS (07/11/2026, demande du pilote) : l'ecran des revenus de
-- l'enseignant dit la presence de chaque eleve telle que la paie la compte.
--
-- Fichier SANS mot d'effacement (regle B5) : le pilote l'installe.
--
-- Retouche PAR ANCRES (regle B4, pg_temp.remplacer) de
-- public.mes_revenus_enseignant(date), rien d'autre. Aucune regle de calcul
-- ne change : les montants restent ceux ecrits par private.pai_due_seance,
-- et un eleve « partielle » etait deja compte present et paye
-- (private.pai_eleves_presents, 20261102900000_presence_minutes.sql:197,
-- et la CTE `eleves` de 20261110200000 prennent 'presente' et
-- 'partielle' ; regle du pilote sur delegation du directeur, 08 §5 bis,
-- 31/10/2026). Des champs s'AJOUTENT a la reponse (regle B6 : l'ancien
-- client les ignore, 'present' ne change pas) :
--   * par eleve, 'presence' : 'presente', 'partielle' ou 'absente' (toute
--     autre valeur de private.presence_temps_reel, non payee, se dit
--     'absente', comme 'present' la dit faux) ;
--   * en tete, 'totalARecevoir' : la somme des montants deja ecrits des
--     seances sans attente (ni cahier de la semaine manquant, ni duree a
--     trancher par la direction), et 'totalAttenteCahier' : la somme des
--     montants des seances qui attendent le cahier, montree a part ; aucune
--     regle redite, seulement le champ 'attente' deja rendu ;
--   * par Classe, 'montantARecevoir', sur la meme regle : la somme des
--     lignes de Classe vaut 'totalARecevoir'.
--   'totalEstime' et 'montantEstime' restent rendus tels quels (B6).
--
-- Preflight : md5(pg_get_functiondef) de production 323c74a9aa713523745ac42ab3a0705c,
-- relu le 07/11/2026 en lecture seule, identique a la base rejouee depuis le
-- depot ; chaque ancre presente exactement une fois. Remesure le 08/11 sur
-- une base rejouee depuis main 84eb99dc (stub_auth + toutes les migrations,
-- Postgres 17) : 323c74a9aa713523745ac42ab3a0705c, identique. Aucune
-- migration de main ne redefinit la fonction apres 20261110210000.
-- A verifier en production par le pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef(
--            'public.mes_revenus_enseignant(date)'::regprocedure));
--   attendu : 323c74a9aa713523745ac42ab3a0705c
-- Une ancre qui ne tient plus fait echouer le fichier (RAISE dans
-- pg_temp.remplacer) ; les retouches sont dans un seul bloc DO, donc tout
-- ou rien.
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.
-- Rejeu : la retouche deja la (marqueur 'totalARecevoir'), rien n'est
-- reapplique.

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
do $preflight$
declare
  v_def text := pg_catalog.pg_get_functiondef('public.mes_revenus_enseignant(date)'::regprocedure);
begin
  if pg_catalog.md5(v_def) <> '323c74a9aa713523745ac42ab3a0705c'
     and pg_catalog.strpos(v_def, '''totalARecevoir''') = 0 then
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
  if pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), '''totalARecevoir''') > 0 then
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

  -- 2.4 Les deux totaux, et le montant a recevoir de chaque Classe.
  perform pg_temp.remplacer(v_f,
    $a$  v_internet bigint;$a$,
    $b$  v_internet bigint;
  v_a_recevoir bigint;
  v_attente_cahier bigint;$b$, 1);

  perform pg_temp.remplacer(v_f,
    $a$  -- Le jour de paie : du jourDebut au jourFin du mois suivant.$a$,
    $b$  -- REVENUS : a recevoir = montants ecrits des seances sans attente ; a
  -- part, ce qui attend le cahier de la semaine. Par Classe, la meme somme.
  SELECT coalesce(sum((x #>> '{montant,mineur}')::bigint)
                    FILTER (WHERE x -> 'attente' = 'null'::jsonb), 0),
         coalesce(sum((x #>> '{montant,mineur}')::bigint)
                    FILTER (WHERE x ->> 'attente' = 'cahier'), 0)
    INTO v_a_recevoir, v_attente_cahier
    FROM pg_catalog.jsonb_array_elements(v_seances) x;
  SELECT coalesce(pg_catalog.jsonb_agg(c.v || pg_catalog.jsonb_build_object('montantARecevoir',
           private.bf1_montant(coalesce((
             SELECT sum((x #>> '{montant,mineur}')::bigint)
               FROM pg_catalog.jsonb_array_elements(v_seances) x
              WHERE x ->> 'classeId' = c.v ->> 'classeId'
                AND x -> 'attente' = 'null'::jsonb), 0)::bigint, v_devise))
           ORDER BY c.o), '[]'::jsonb)
    INTO v_classes
    FROM pg_catalog.jsonb_array_elements(v_classes) WITH ORDINALITY AS c(v, o);

  -- Le jour de paie : du jourDebut au jourFin du mois suivant.$b$, 1);

  perform pg_temp.remplacer(v_f,
    $a$    'totalEstime', private.bf1_montant(v_total, v_devise),$a$,
    $b$    'totalEstime', private.bf1_montant(v_total, v_devise),
    'totalARecevoir', private.bf1_montant(v_a_recevoir, v_devise),
    'totalAttenteCahier', private.bf1_montant(v_attente_cahier, v_devise),$b$, 1);
end;
$retouches$;

-- Droits inchanges (create or replace les conserve) ; reaffirmes par prudence.
alter function public.mes_revenus_enseignant(date) owner to postgres;
revoke all on function public.mes_revenus_enseignant(date) from public, anon, service_role;
grant execute on function public.mes_revenus_enseignant(date) to authenticated;

comment on function public.mes_revenus_enseignant(date) is
  'BF1-01, FAC-E-02, PAIE-REMPLACANT, REVENUS-VERITE, REVENUS : revenus de l''enseignant connecte, lus dans tresorerie_mouvements (remuneration_due) pour les seances dont il est l''enseignant effectif ; a recevoir (montants ecrits des seances sans attente) et en attente du cahier, par classe, par seance et par eleve (presence : presente, partielle ou absente), la fenetre du jour de paie, et les autres revenus du mois (aide Internet, primes, missions). Garde: teacher + compte valide; perimetre auth.uid(). date=2026-11-08.';

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
do $postflight$
declare
  v_def text := pg_catalog.pg_get_functiondef('public.mes_revenus_enseignant(date)'::regprocedure);
begin
  if pg_catalog.strpos(v_def, '''presence''') = 0
     or pg_catalog.strpos(v_def, 't.statut AS statut') = 0
     or pg_catalog.strpos(v_def, '''totalARecevoir''') = 0
     or pg_catalog.strpos(v_def, '''totalAttenteCahier''') = 0
     or pg_catalog.strpos(v_def, '''montantARecevoir''') = 0
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

