-- 0032_tc_catalogue_durcissement_grants.sql
-- Correction relevee par get_advisors juste apres 0032 : par defaut, PostgreSQL
-- accorde EXECUTE a PUBLIC sur toute fonction nouvellement creee. Le declencheur
-- de calcul d'empreinte n'a jamais ete pense pour etre appele directement (son
-- type de retour `trigger` l'en empecherait de toute facon), mais il doit suivre
-- la meme discipline que le reste du chantier : jamais d'EXECUTE laisse ouvert
-- sans revue explicite.

revoke execute on function public.tc_session_feedback_calculer_empreinte() from public, anon, authenticated;
