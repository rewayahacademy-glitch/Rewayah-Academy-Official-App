-- 0018 — 0017 a oublie de fermer l'execution par defaut a `public`/`anon`
--
-- `get_advisors` (security) a releve que les sept fonctions de 0017 restaient
-- executables par `anon` et `authenticated` via PostgREST, faute d'un
-- `revoke` explicite avant le `grant` -- la meme faute que celle deja
-- corrigee dans 0008 pour `attribuer_eleve`. Chaque fonction verifie deja
-- `app_role() = 'admin'` en interne, mais l'ouverture par defaut est le vrai
-- trou (meme lecon que l'audit de 0014/AGT-01) : on la ferme explicitement.
--
-- `guard_groupe_membre_cap()` est une fonction de declencheur : elle n'a
-- besoin d'aucun droit d'execution direct, le declencheur l'invoque avec les
-- droits de son proprietaire.

revoke execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint) from public, anon;
revoke execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint) from public, anon;
revoke execute on function public.ajouter_eleve_groupe(uuid, uuid, text) from public, anon;
revoke execute on function public.retirer_eleve_groupe(uuid, uuid, text) from public, anon;
revoke execute on function public.cloturer_groupe(uuid, text) from public, anon;
revoke execute on function public.groupes_admin() from public, anon;
revoke execute on function public.groupe_detail(uuid) from public, anon;

revoke execute on function public.guard_groupe_membre_cap() from public, anon, authenticated, agent_ro;
