-- HORLOGE-ET-LIEU, partie B : controle d'effectif apres le chargement des villes.
-- Les six morceaux (20261123942100 a 20261123942150) apportent 34215 villes. Un
-- morceau oublie ou coupe se voit ici, avant que quiconque cherche sa ville.
-- Avec la VARIANTE DE SECOURS (villes de plus de 50 000 habitants, un seul
-- fichier), ce controle n'est pas rejoue : la variante porte le sien.
-- Fichier sans effacement.

BEGIN;

DO $controle$
DECLARE
  v_n bigint;
  v_inconnus bigint;
  v_arabes bigint;
BEGIN
  SELECT pg_catalog.count(*) INTO v_n FROM public.villes_ref;
  IF v_n <> 34215 THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : % villes chargees au lieu de 34215 : un morceau manque ou est incomplet', v_n;
  END IF;
  -- Tout fuseau de la liste est connu de la base (sans quoi le fuseau d'une
  -- personne serait refuse plus tard).
  SELECT pg_catalog.count(*) INTO v_inconnus
    FROM public.villes_ref v WHERE NOT app_private.fuseau_connu(v.fuseau_iana);
  IF v_inconnus <> 0 THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : % villes ont un fuseau inconnu de la base', v_inconnus;
  END IF;
  -- Les villes de La Mecque (Makkah), de Medine (Madinah) et de Riyad sont la.
  IF (SELECT pg_catalog.count(*) FROM public.villes_ref
       WHERE pays_code = 'SA' AND nom_recherche IN ('makkah', 'riyadh', 'madinah')) <> 3 THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : les villes saoudiennes attendues manquent';
  END IF;
  SELECT pg_catalog.count(*) INTO v_arabes FROM public.villes_ref WHERE nom_ar IS NOT NULL;
  RAISE NOTICE 'HORLOGE-ET-LIEU : % villes chargees, % avec un nom arabe', v_n, v_arabes;
END
$controle$;

COMMIT;
