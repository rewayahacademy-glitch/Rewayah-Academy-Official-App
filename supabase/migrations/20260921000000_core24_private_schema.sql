-- Core24 : namespace interne partage par les fonctions serveur protegees.
-- Ce fichier precede la migration Presence qui y declare ses fonctions.
begin;

create schema if not exists core24_private;
revoke all on schema core24_private from public, anon, authenticated, agent_ro;

commit;
