-- 0002 : ajout du statut de compte « en attente de KYC »
--
-- Ecart constate entre l'ADR-014 et la migration 0001 : l'ADR definit quatre
-- statuts de compte, dont `en_attente_kyc`, et la base n'en portait que trois
-- (`active`, `provisional_active`, `disabled`). Toute nouvelle inscription
-- naissait donc `active`, alors que l'ADR-014 exige l'inverse : aucun acces
-- avant validation du dossier.
--
-- Cette migration ajoute la valeur manquante. Le changement de valeur par
-- defaut est dans 0003 : Postgres refuse d'utiliser une valeur d'enumere dans
-- la transaction qui vient de l'ajouter. Deux fichiers, donc deux transactions.
--
-- Pas de bloc begin/commit ici, volontairement, pour la meme raison.

alter type public.account_status add value if not exists 'pending_kyc' before 'active';
