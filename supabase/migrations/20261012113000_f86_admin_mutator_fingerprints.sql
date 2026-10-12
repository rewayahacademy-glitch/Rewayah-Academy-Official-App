BEGIN;

-- Les empreintes ont ete calculees par la revue Claude sur le rejeu PG16.
COMMENT ON FUNCTION public.clore_regle(uuid, text) IS
  'F86 candidate allowlist: signature=public.clore_regle(uuid,text); md5_functiondef=23aa85aa637e93ad3d27de78f0c157dd; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';

COMMENT ON FUNCTION public.decider_demande(uuid, boolean, text) IS
  'F86 candidate allowlist: signature=public.decider_demande(uuid,boolean,text); md5_functiondef=ec9fe0b06d004bd701071201e3ad9707; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';

COMMENT ON FUNCTION public.maj_eleve_pedagogie(uuid, text, text) IS
  'F86 candidate allowlist: signature=public.maj_eleve_pedagogie(uuid,text,text); md5_functiondef=d520a13d7d56c740fdadc8291b7b0ac6; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';

COMMENT ON FUNCTION public.poser_regle(uuid, text, integer, text) IS
  'F86 candidate allowlist: signature=public.poser_regle(uuid,text,integer,text); md5_functiondef=a3c7d8e4a47b497ca8089389114eba8e; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';

COMMIT;
