-- BE-2a-2 (pilote, 16/11/2026) : le role `associe`, seul dans sa migration.
--
-- Une personne sans compte, invitee par la direction, recoit ce role : elle ne voit RIEN par defaut (aucune
-- politique de securite par ligne n'est ecrite par exclusion sur le role, relevé du 16/11 : 206 politiques) et
-- n'agit que par une mission (BE-2a-1). `ALTER TYPE ... ADD VALUE` ne peut pas servir dans la transaction qui
-- l'ajoute : tout ce qui utilise le role est dans la migration suivante (20261129780000).
--
-- FICHIER SANS EFFACEMENT DE DONNEES : aucun mot d'effacement. Un rejeu ne change rien.
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'associe';
