-- 0031_participant_role_admin.sql
-- Teaching Core -- palier 3, seul dans son fichier.
--
-- PostgreSQL refuse d'UTILISER une valeur d'enum ajoutee dans la meme transaction
-- (55P04 unsafe_new_enum_value_usage). Toute policy, check ou vue qui NOMME l'une
-- des deux valeurs ci-dessous doit vivre dans une migration ULTERIEURE (0033) :
-- ne jamais fusionner ce fichier avec 0032 ou 0033.
--
-- Regles rappelees (voir 0030) : jamais de `grant execute` a `agent_ro` sur une
-- fonction volatile ou d'ecriture ; la RLS borne les LIGNES, jamais les COLONNES.
-- Aucune des deux ne s'applique ici : ce fichier ne touche qu'un type.

alter type public.participant_role add value 'admin_masked';
alter type public.participant_role add value 'admin_visible';
