-- PE (19/10/2026) : code de conduite de l'enseignant, version definitive.
--
-- Le directeur a valide le texte le 19/10/2026. Le code de conduite n'est plus
-- provisoire : la version requise passe de '2026-10-cond' a '2026-10-19'.
--
-- Effet : un enseignant qui avait accepte l'ancienne version doit accepter la
-- nouvelle. Son ancienne acceptation reste en place (ligne immuable de
-- `contract_acceptances`) ; la policy d'insertion
-- `contract_acceptances_code_conduite_enseignant` n'accepte desormais que la
-- nouvelle version, lue par `code_conduite_version_requise()`.
--
-- Migration additive : une seule ecriture, par INSERT ... ON CONFLICT. Aucune
-- suppression, aucun retrait de table ou de fonction.
BEGIN;

INSERT INTO public.contract_required_versions (contract_kind, version, changed_at)
VALUES ('teacher_conduct_code', '2026-10-19', pg_catalog.now())
ON CONFLICT (contract_kind) DO UPDATE
  SET version = EXCLUDED.version,
      changed_at = EXCLUDED.changed_at;

DO $postflight$
BEGIN
  IF (SELECT r.version
        FROM public.contract_required_versions r
       WHERE r.contract_kind = 'teacher_conduct_code') IS DISTINCT FROM '2026-10-19' THEN
    RAISE EXCEPTION 'PE v2 : la version requise du code de conduite n''est pas 2026-10-19';
  END IF;
  IF public.code_conduite_version_requise() IS DISTINCT FROM '2026-10-19' THEN
    RAISE EXCEPTION 'PE v2 : code_conduite_version_requise() ne rend pas 2026-10-19';
  END IF;
  IF (SELECT count(*) FROM public.contract_required_versions) < 2 THEN
    RAISE EXCEPTION 'PE v2 : une version requise a disparu';
  END IF;
END;
$postflight$;

COMMIT;
