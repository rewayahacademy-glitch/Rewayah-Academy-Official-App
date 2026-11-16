-- CONVERSATIONS-PARTOUT (16/11/2026, ordre du pilote) : rattrapage de
-- `com_message_images.confirmee_le`.
--
-- La migration 20261129200000 a ajoute la colonne et la pose desormais a la
-- confirmation. Les images confirmees AVANT elle n'ont pas de date : la regle
-- « un message dont l'image est supprimee SANS confirmee_le est rendu a
-- personne » les confondrait avec un depot annule le jour ou la purge de 90
-- jours les passerait a `supprimee`. On leur donne donc la seule date connue,
-- celle du depot (`cree_le`).
--
-- Rejouable : ne touche que les lignes confirmees sans date ; un second
-- passage ne change rien. Une seule ecriture, sur une colonne d'etat
-- technique (aucune donnee de personne). FICHIER SANS MOT D'EFFACEMENT, sans
-- BEGIN ni COMMIT de premier niveau. S'installe apres 20261129200000.

UPDATE public.com_message_images
   SET confirmee_le = cree_le
 WHERE etat = 'confirmee'
   AND confirmee_le IS NULL;

DO $controle$
DECLARE
  v_restantes bigint;
BEGIN
  SELECT pg_catalog.count(*) INTO v_restantes
    FROM public.com_message_images i
   WHERE i.etat = 'confirmee' AND i.confirmee_le IS NULL;
  IF v_restantes > 0 THEN
    RAISE EXCEPTION 'images rattrapage : % image(s) confirmee(s) sans confirmee_le', v_restantes;
  END IF;
END
$controle$;
