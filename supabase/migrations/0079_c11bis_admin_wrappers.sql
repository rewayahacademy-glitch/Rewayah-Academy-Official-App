-- 0079 — mutations C-11 bis bornées, idempotentes et fermées sans source C-04.
BEGIN;

CREATE OR REPLACE FUNCTION public.creer_classe_depuis_regroupement_c11bis(
  p_regroupement_id text,
  p_cle_idempotence uuid,
  p_libelle text,
  p_genre_classe text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe_id uuid;
  v_regroupement_id text;
  v_genre text;
  v_statut text := 'creee';
  v_eleves integer;
BEGIN
  IF NOT coalesce(
       public.app_role() = 'admin' AND public.app_account_valid(),
       false
     )
     OR p_regroupement_id IS NULL
     OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '') = ''
     OR p_genre_classe IS NULL
     OR p_genre_classe NOT IN ('hommes', 'femmes', 'indetermine') THEN
    RAISE EXCEPTION 'creation de classe reservee a l''administration';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'classe-idempotence:' || p_cle_idempotence::text, 0
    )
  );

  SELECT c.groupe_id, c.regroupement_id, g.genre_public
    INTO v_groupe_id, v_regroupement_id, v_genre
    FROM public.demandes_horaires_creation_classe c
    LEFT JOIN public.groupes g ON g.id = c.groupe_id
   WHERE c.cle_idempotence = p_cle_idempotence;

  IF FOUND THEN
    IF v_regroupement_id IS DISTINCT FROM p_regroupement_id
       OR v_genre IS DISTINCT FROM p_genre_classe THEN
      RAISE EXCEPTION 'cle idempotence deja utilisee';
    END IF;
    v_statut := 'deja_creee';
  ELSE
    v_groupe_id := public.creer_classe_depuis_regroupement(
      p_regroupement_id,
      p_cle_idempotence,
      p_libelle
    );

    UPDATE public.groupes
       SET genre_public = p_genre_classe
     WHERE id = v_groupe_id
       AND etat = 'en_attente_enseignant'
       AND teacher_id IS NULL
    RETURNING genre_public INTO v_genre;

    IF NOT FOUND OR v_genre IS DISTINCT FROM p_genre_classe THEN
      RAISE EXCEPTION 'classe creee sans genre confirme';
    END IF;
  END IF;

  SELECT count(*)::integer INTO v_eleves
    FROM public.groupe_membres gm
   WHERE gm.groupe_id = v_groupe_id
     AND gm.left_at IS NULL;

  RETURN pg_catalog.jsonb_build_object(
    'statut', v_statut,
    'classe_id', v_groupe_id,
    'libelle', (SELECT g.libelle FROM public.groupes g WHERE g.id = v_groupe_id),
    'genre_classe', v_genre,
    'eleves_integres', v_eleves,
    -- Le raccord enseignant reste fermé jusqu'à la décision C-04 sur la source
    -- de titre public et à la validation des contrôles de collision.
    'peut_affecter_enseignant', false
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe_c11bis(
  p_groupe_id uuid,
  p_teacher_profile_id uuid
)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(
       public.app_role() = 'admin' AND public.app_account_valid(),
       false
     )
     OR p_groupe_id IS NULL
     OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes
   WHERE id = p_groupe_id
   FOR UPDATE;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;
  IF v_groupe.teacher_id IS NOT NULL THEN
    RETURN 'deja_affecte';
  END IF;
  IF v_groupe.etat <> 'en_attente_enseignant' THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- teacher_profiles ne porte pas le titre public C-05 et aucune règle
  -- serveur de collisions C-07 n'est encore complète. Refus explicite plutôt
  -- qu'une affectation qui ne peut pas prouver sa compatibilité.
  RAISE EXCEPTION 'compatibilite enseignant non verifiable : source titre public absente';
END;
$function$;

REVOKE ALL ON FUNCTION public.creer_classe_depuis_regroupement_c11bis(text, uuid, text, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_classe_depuis_regroupement_c11bis(text, uuid, text, text)
  TO authenticated;

REVOKE ALL ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid, uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid, uuid)
  TO authenticated;

COMMIT;
