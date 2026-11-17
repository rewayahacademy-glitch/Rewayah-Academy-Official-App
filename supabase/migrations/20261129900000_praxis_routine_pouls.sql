-- PRAXIS-ROUTINE (etape 15, mode autonome) : le POULS. Praxis repond seul par une tache planifiee horaire (voir
-- docs/current/BUREAU-EQUIPE/PRAXIS/ROUTINE-PRAXIS.md). Le directeur doit VOIR que la routine tourne : date du dernier tir,
-- son issue, ses compteurs. Rien d'autre ne change dans le garde-fou.
--
-- Additif :
--  * une table privee `private.praxis_tirs` (une ligne par tir termine, ajout seul, aucun droit en dehors de la fonction) ;
--  * UNE porte neuve pour l'outil `terminer` : `public.praxis_terminer(...)`, executable par le seul service_role, qui n'accepte
--    que les cles d'usage `routine` (une cle `chat` ne peut pas se faire passer pour la routine : refus `hors_portee`) ;
--  * `public.direction_praxis_etat()` remplacee par CREATE OR REPLACE a signature identique, apres controle de son empreinte
--    (production et depot ont la meme) : elle rend en plus `derniereRoutine` (NULL tant qu'aucun tir n'a ete note).
-- Rien n'est allume par cette migration : `praxis.actif`, `autonome` et `donnees_reelles` restent ce qu'ils sont. Aucun mot d'effacement.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.praxis_journal') IS NULL OR pg_catalog.to_regclass('private.praxis_cles') IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-ROUTINE : le socle de Praxis est absent ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.direction_praxis_etat()'::pg_catalog.regprocedure)
     IS DISTINCT FROM '4aa58fbf27509a84d4ee12c909f57cc9' THEN
    RAISE EXCEPTION 'PRAXIS-ROUTINE : la definition de public.direction_praxis_etat n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'private.praxis_porte(text,boolean)'::pg_catalog.regprocedure)
     IS DISTINCT FROM '9d01bca4bbc66f6f26e8c55f7ad71874' THEN
    RAISE EXCEPTION 'PRAXIS-ROUTINE : la definition de private.praxis_porte n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.praxis_tirs') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.praxis_terminer(text,text,integer,integer,integer,integer,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'PRAXIS-ROUTINE : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Les tirs : une ligne par tir termine. Aucune donnee de personne : des compteurs et une note courte de la routine.
CREATE TABLE private.praxis_tirs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  termine_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  issue text NOT NULL CHECK (issue IN ('ok', 'rien_a_faire', 'erreur')),
  fils_lus integer NOT NULL CHECK (fils_lus BETWEEN 0 AND 200),
  messages_envoyes integer NOT NULL CHECK (messages_envoyes BETWEEN 0 AND 200),
  passes_equipe integer NOT NULL CHECK (passes_equipe BETWEEN 0 AND 200),
  refus integer NOT NULL CHECK (refus BETWEEN 0 AND 1000),
  note text CHECK (note IS NULL OR pg_catalog.length(note) <= 200)
);
ALTER TABLE private.praxis_tirs ENABLE ROW LEVEL SECURITY;
CREATE INDEX praxis_tirs_recent_idx ON private.praxis_tirs (termine_le DESC, id DESC);
REVOKE ALL ON TABLE private.praxis_tirs FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. L'outil `terminer` : la routine note la fin de son tir. Refus finaux comme les autres outils (porte, journal).
CREATE FUNCTION public.praxis_terminer(p_cle text, p_issue text, p_lus integer, p_envoyes integer, p_passes integer,
                                       p_refus integer, p_note text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'terminer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  -- Seule une cle de routine note un tir : une cle de chat n'a pas de tir a terminer.
  IF v_p.usage IS DISTINCT FROM 'routine' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'terminer', 'hors_portee', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  IF p_issue IS NULL OR p_issue NOT IN ('ok', 'rien_a_faire', 'erreur')
     OR p_lus IS NULL OR p_lus NOT BETWEEN 0 AND 200
     OR p_envoyes IS NULL OR p_envoyes NOT BETWEEN 0 AND 200
     OR p_passes IS NULL OR p_passes NOT BETWEEN 0 AND 200
     OR p_refus IS NULL OR p_refus NOT BETWEEN 0 AND 1000
     OR (p_note IS NOT NULL AND pg_catalog.length(p_note) > 200) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'terminer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  INSERT INTO private.praxis_tirs (cle_id, issue, fils_lus, messages_envoyes, passes_equipe, refus, note)
  VALUES (v_p.cle_id, p_issue, p_lus, p_envoyes, p_passes, p_refus, p_note);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'terminer', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;
ALTER FUNCTION public.praxis_terminer(text, text, integer, integer, integer, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.praxis_terminer(text, text, integer, integer, integer, integer, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_terminer(text, text, integer, integer, integer, integer, text) TO service_role;

-- 3. L'etat de la direction : le meme, plus le dernier tir (NULL tant qu'aucun).
CREATE OR REPLACE FUNCTION public.direction_praxis_etat()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT pg_catalog.jsonb_build_object(
    'actif', r.actif,
    'autonome', r.autonome,
    'envoisParHeure', r.envois_par_heure,
    'appelsParHeure', r.appels_par_heure,
    'modifieLe', r.modifie_le,
    'essaiFils', pg_catalog.to_jsonb(r.essai_fils),
    'donneesReelles', r.donnees_reelles,
    'derniereRoutine', (
      SELECT pg_catalog.jsonb_build_object(
               'termineLe', t.termine_le, 'issue', t.issue, 'filsLus', t.fils_lus,
               'messagesEnvoyes', t.messages_envoyes, 'passesEquipe', t.passes_equipe,
               'refus', t.refus, 'note', t.note)
        FROM private.praxis_tirs t ORDER BY t.termine_le DESC, t.id DESC LIMIT 1),
    'cles', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'prefixe', c.prefixe, 'usage', c.usage,
               'emiseLe', c.emise_le, 'expireLe', c.expire_le, 'derniereUtilisationLe', c.derniere_utilisation_le,
               'revoqueeLe', c.revoquee_le, 'motifRevocation', c.motif_revocation,
               -- L'etat vient de la base (son horloge), jamais d'une comparaison faite sur le poste (meme regle que jetons_agent_actifs).
               'etat', CASE WHEN c.revoquee_le IS NOT NULL THEN 'revoquee'
                            WHEN c.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'active' END)
             ORDER BY c.emise_le DESC, c.id)
        FROM (SELECT * FROM private.praxis_cles x ORDER BY x.emise_le DESC, x.id LIMIT 100) c), '[]'::jsonb))
    FROM private.praxis_reglages r);
END;
$function$;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.praxis_terminer(text,text,integer,integer,integer,integer,text)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'private.praxis_tirs', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_tirs', 'SELECT')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_etat()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_etat()', 'EXECUTE')
     OR (SELECT pg_catalog.count(*) FROM private.praxis_tirs) <> 0
     OR (SELECT r.actif FROM private.praxis_reglages r) IS NOT FALSE
     OR (SELECT r.autonome FROM private.praxis_reglages r) IS NOT FALSE THEN
    RAISE EXCEPTION 'PRAXIS-ROUTINE : droits ou etat inattendus apres installation';
  END IF;
END
$postflight$;
