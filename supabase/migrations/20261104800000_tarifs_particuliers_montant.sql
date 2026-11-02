-- Lot (A), fichier 1 sur 2 (02/11/2026) : un prix special peut se dire en
-- montant mensuel au lieu d'une reduction en pour mille (ordre du pilote du
-- 02/11). La colonne pour_mille accepte donc l'absence de valeur ; le fichier 2
-- (20261104900000_tarifs_particuliers.sql) exige qu'une remise porte
-- exactement un des deux (pour mille ou montant) et corrige chaque lecteur.
--
-- Seul dans son fichier, colle par le directeur depuis la page du pilote.
BEGIN;
ALTER TABLE public.bourses_eleves ALTER COLUMN pour_mille DROP NOT NULL;
COMMIT;
