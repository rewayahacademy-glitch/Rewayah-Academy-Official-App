-- 0033_tc_vues_rpc_durcissement_grants.sql
-- Corrections relevees par get_advisors juste apres 0033.
--
-- 1. materialiser_seances_groupe(uuid) : voulue service_role SEULEMENT (elle
--    n'a aucune garde de role interne -- elle fait confiance a l'appelant pour
--    etre le service, pas un utilisateur). 0033 l'avait revoquee de public,
--    anon et agent_ro, mais PAS de `authenticated` : Supabase accorde EXECUTE
--    a `authenticated` sur toute fonction neuve par un chemin independant de
--    PUBLIC (le meme motif que feedback_double_chemin_execute_supabase, mais
--    pour authenticated plutot qu'anon). Sans ce correctif, n'importe quel
--    compte connecte pouvait materialiser les seances de n'importe quel
--    groupe en appelant la RPC directement.
--
-- 2. guard_session_participant_cap() / guard_session_overlap() : declencheurs
--    (`returns trigger`), jamais appelables utilement hors d'un declencheur --
--    mais restaient executables par `anon` depuis leur creation initiale
--    (0001/0005), jamais corrige. Meme discipline que 0030_..._search_path et
--    0032_..._grants : un declencheur n'a jamais besoin d'EXECUTE pour se
--    declencher (l'invocation par declencheur ne passe pas par le controle de
--    droit normal), donc le revoquer est toujours sans risque.
--
-- Aucune des deux corrections n'est une regression : aucun chemin legitime du
-- depot n'appelle ces fonctions directement (materialiser_seances_groupe est
-- appelee par les deux nouveaux declencheurs, en `security definer`, qui n'ont
-- pas besoin d'EXECUTE non plus, et les deux gardiens ne s'appellent que par
-- declencheur).

revoke execute on function public.materialiser_seances_groupe(uuid) from authenticated;

revoke execute on function public.guard_session_participant_cap() from public, anon, authenticated;
revoke execute on function public.guard_session_overlap() from public, anon, authenticated;
