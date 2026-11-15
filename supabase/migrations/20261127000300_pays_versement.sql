-- PAYS-VERSEMENT (directeur, 15/11/2026).
--
-- Probleme vu sur le terrain : a la question « pays du compte de versement »,
-- des candidats choisissent leur propre pays, que l'academie ne prend pas en
-- charge, alors qu'un proche de confiance vit souvent dans un pays pris en
-- charge. Apres l'envoi, ils ne pouvaient plus corriger cette reponse et la
-- direction ne pouvait pas leur redemander.
--
-- Ce que fait cette migration (rien d'autre) :
--
-- A. Un element de complement de plus, `pays_versement` (« Pays et compte de
--    versement »), en salle 1 et en salle 2, ajoute par ANCRE sur
--    private.candidature_complement_codes (la liste est une fonction, il n'y a
--    aucun CHECK a reecrire). Rejouable : la marque PAYS-VERSEMENT evite un
--    second remplacement.
--
-- B. Une RPC, public.modifier_mon_pays_versement(p_pays), SECURITY DEFINER,
--    limitee a la candidature du titulaire (private.candidature_du_titulaire),
--    candidature en cours en prequalification, verifications ou confirmee. Elle :
--      1. refuse un code qui n'est pas dans private.pays_iso_3166 (le meme
--         controle que le questionnaire) ;
--      2. ecrit un NOUVEAU document de reponses envoye (source candidat) =
--         dernier document + nouveau pays, sans les operateurs (ils dependent
--         du pays) ; l'historique reste ;
--      3. remet les coordonnees de versement actives du candidat « a valider »
--         (valide_le et valide_par a nul) quand le pays change ;
--      4. recalcule le paiement (private.paiement_recalculer, cause reponses) :
--         la candidature passe d'en_examen a paiement_non_disponible ou
--         l'inverse selon le referentiel, JAMAIS en refus ;
--      5. journalise (candidature_evenements, type controle, avec l'ancien et le
--         nouveau pays) et rend le bloc candidature relu.
--    Meme pays que l'actuel : aucun changement, rendu tel quel.
--    Aucun calcul financier : le serveur ne fait que lire le referentiel.
--
-- Il n'existe aujourd'hui aucun verrou « la direction a bloque les
-- modifications » (RETOURS-TERRAIN-INSCRIPTIONS, lecon L2). La limite posee ici
-- est l'etat de la candidature ; un verrou serait une decision a part.
--
-- Aucun mot d'effacement, aucun BEGIN ni COMMIT.

-- ---------------------------------------------------------------------------
-- A. L'element de complement.
-- ---------------------------------------------------------------------------
DO $codes$
DECLARE
  v_oid regprocedure := 'private.candidature_complement_codes(text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_av1 constant text := E'''accord_publication'']::text[]';
  v_ap1 constant text := E'''accord_publication'', ''pays_versement'']::text[] -- PAYS-VERSEMENT';
  v_av2 constant text := E'ARRAY[''piece_identite'', ''cadre_religieux'', ''contrat'', ''avis'']::text[]';
  v_ap2 constant text := E'ARRAY[''piece_identite'', ''cadre_religieux'', ''contrat'', ''avis'', ''pays_versement'']::text[] -- PAYS-VERSEMENT';
  v_n1 integer;
  v_n2 integer;
  v_commentaire text;
BEGIN
  IF pg_catalog.strpos(v_def, 'PAYS-VERSEMENT') > 0 THEN
    RAISE NOTICE 'PAYS-VERSEMENT : candidature_complement_codes deja etendue, rien a faire';
    RETURN;
  END IF;
  v_n1 := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_av1, '')))
          / pg_catalog.length(v_av1);
  v_n2 := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_av2, '')))
          / pg_catalog.length(v_av2);
  IF v_n1 <> 1 OR v_n2 <> 1 THEN
    RAISE EXCEPTION 'PAYS-VERSEMENT : ancres de candidature_complement_codes trouvees % et % fois au lieu de 1 et 1', v_n1, v_n2;
  END IF;
  v_commentaire := pg_catalog.obj_description(v_oid::oid, 'pg_proc');
  EXECUTE pg_catalog.replace(pg_catalog.replace(v_def, v_av1, v_ap1), v_av2, v_ap2);
  IF v_commentaire IS NOT NULL AND v_commentaire LIKE '%md5_functiondef=%' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      pg_catalog.regexp_replace(v_commentaire, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END IF;
END;
$codes$;

-- ---------------------------------------------------------------------------
-- B. Le candidat corrige lui-meme son pays de versement.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.modifier_mon_pays_versement(p_pays text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.candidature_du_titulaire(true);
  v_pays text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_pays, '')));
  v_c public.candidatures;
  v_doc public.candidature_reponses;
  v_avant text;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'reserve au titulaire d''une candidature en cours' USING ERRCODE = '42501';
  END IF;
  IF v_pays !~ '^[A-Z]{2}$'
     OR NOT EXISTS (SELECT 1 FROM private.pays_iso_3166 x WHERE x.code = v_pays) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'pays_invalide');
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.issue <> 'en_cours' OR v_c.etape NOT IN ('prequalification', 'verifications', 'confirmee') THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modification_impossible');
  END IF;
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = v_id AND r.source = 'candidat' AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  IF v_doc.id IS NULL THEN
    -- Aucune reponse envoyee : le pays se choisit dans le questionnaire.
    RETURN pg_catalog.jsonb_build_object('erreur', 'aucune_reponse_envoyee');
  END IF;
  v_avant := v_doc.reponses ->> 'paysVersement';
  IF v_avant IS NOT DISTINCT FROM v_pays THEN
    RETURN pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature',
                                         'inchange', true);
  END IF;
  INSERT INTO public.candidature_reponses
    (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
  VALUES (v_id, v_doc.questionnaire_version,
          (v_doc.reponses - 'operateurs') || pg_catalog.jsonb_build_object('paysVersement', v_pays),
          'candidat', false, pg_catalog.clock_timestamp());
  -- Le pays change : les coordonnees deja saisies ne valent plus, la direction
  -- les revalide.
  UPDATE public.versement_coordonnees
     SET valide_le = NULL, valide_par = NULL
   WHERE profile_id = v_uid AND active AND valide_le IS NOT NULL;
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
  VALUES (v_id, 'controle', v_uid, pg_catalog.jsonb_build_object(
    'controle', 'pays_versement_modifie', 'paysAvant', v_avant, 'paysApres', v_pays));
  PERFORM private.paiement_recalculer(v_id, 'reponses');
  RETURN pg_catalog.jsonb_build_object('candidature', public.etat_dossier() -> 'candidature');
END;
$function$;
REVOKE ALL ON FUNCTION public.modifier_mon_pays_versement(text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.modifier_mon_pays_versement(text) TO authenticated;
COMMENT ON FUNCTION public.modifier_mon_pays_versement(text) IS
  'PAYS-VERSEMENT : le candidat change son pays de versement apres l''envoi (sa candidature en cours seulement) ; nouveau document de reponses sans operateurs, coordonnees a revalider, paiement recalcule, jamais de refus.';
