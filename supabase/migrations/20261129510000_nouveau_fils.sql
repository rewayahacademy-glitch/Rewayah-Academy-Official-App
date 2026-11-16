-- NOUVEAU-FILS (16/11/2026, directeur : avec 30 a 100 arrivees par heure ou par jour, voir
-- d'un coup d'oeil quelle conversation vient d'arriver, SPEC-LISTE-PERSONNES §2.1 bis) : le
-- panneau des conversations affiche un badge « Nouveau » (composant lib/core/widgets/badge_nouveau.dart).
--
-- Regle, calculee ici et rendue en booleen : une conversation est « nouvelle » si
--   1. elle a moins de 7 jours (com_fils.cree_le), ET
--   2. aucun membre de l'equipe n'a de ligne dans com_lectures pour elle.
-- « Membre de l'equipe » = la notion deja en base : private.com_est_partie(..., 'equipe', NULL),
-- c'est-a-dire l'Administration (et le Comptable pour un fil de profil de paiement). Aucune
-- notion nouvelle. Une lecture d'une personne qui n'est pas de l'equipe ne compte pas.
-- Une conversation sans message mais creee depuis moins de 7 jours est nouvelle (l'ecran dit
-- « aucun message »).
--
-- Le booleen n'est rendu vrai qu'a un membre de l'equipe : une famille, un enseignant ou un
-- candidat recoit toujours `false` et ne peut donc pas apprendre si l'equipe a lu son fil.
--
-- CHANGEMENT UNIQUE : private.com_fil_json (lue par com_lire_fil ET com_lister_fils) rend une
-- cle de plus, « nouveau », placee avant « messages ». Retouche par ancre, une fois ; les
-- cles existantes ne changent pas ; proprietaire, droits, volatilite et search_path sont
-- gardes et verifies. Aucune table, aucune vue, aucune fonction creee ; aucune donnee ecrite ;
-- aucun droit accorde. Rejouable : rien a faire si la cle est deja la.
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier niveau.
-- S'installe par apply_migration, APRES 20261129500000.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_fil_json(uuid,uuid,text,uuid)') IS NULL THEN
    RAISE EXCEPTION 'nouveau fils : private.com_fil_json absente';
  END IF;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
       'lu_par_autres_le') = 0 THEN
    RAISE EXCEPTION 'nouveau fils : installer d''abord 20261125860000_messagerie_lu.sql';
  END IF;
END
$preflight$;

DO $fil$
DECLARE
  v_f regprocedure := 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''messages'', coalesce((';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, '''nouveau'',') > 0 THEN
    RAISE NOTICE 'nouveau fils : com_fil_json porte deja la cle nouveau';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'nouveau fils : ancre de com_fil_json trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''nouveau'', (' || pg_catalog.chr(10)
    || '      private.com_est_partie(p_moi, p_role, p_foyer, f.type_objet, ''equipe'', NULL)' || pg_catalog.chr(10)
    || '      AND f.cree_le > pg_catalog.now() - pg_catalog.make_interval(days => 7)' || pg_catalog.chr(10)
    || '      AND NOT EXISTS (' || pg_catalog.chr(10)
    || '        SELECT 1 FROM public.com_lectures l' || pg_catalog.chr(10)
    || '          JOIN public.profiles r ON r.id = l.profile_id' || pg_catalog.chr(10)
    || '         WHERE l.fil_id = f.id' || pg_catalog.chr(10)
    || '           AND private.com_est_partie(r.id, r.role::text, r.household_id, f.type_objet, ''equipe'', NULL))),' || pg_catalog.chr(10)
    || '    ' || v_ancre);
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'nouveau fils : proprietaire, droits ou attributs de com_fil_json modifies';
  END IF;
END
$fil$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                       '''nouveau'',') = 0 THEN
    RAISE EXCEPTION 'nouveau fils : la cle nouveau est absente de com_fil_json';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                       'lu_par_autres_le') = 0 THEN
    RAISE EXCEPTION 'nouveau fils : lu_par_autres_le a disparu de com_fil_json';
  END IF;
END
$postflight$;
