-- COURRIELS-80 (15/11/2026) : ordre du directeur, après la panne du 15/11 :
-- « oui, pour les e-mails (seuil) » (proposition : passer de 40 à 80 courriels
-- non essentiels par heure, pour écouler les 941 liens d'inscription restés en
-- file). Le plafond par jour (courriels.non_essentiels_par_jour = 900) ne change
-- pas : il reste la borne. Rejouable. Aucun mot d'effacement.

UPDATE public.app_config
   SET value = pg_catalog.to_jsonb(80), updated_at = pg_catalog.now()
 WHERE key = 'courriels.non_essentiels_par_heure'
   AND value IS DISTINCT FROM pg_catalog.to_jsonb(80);
