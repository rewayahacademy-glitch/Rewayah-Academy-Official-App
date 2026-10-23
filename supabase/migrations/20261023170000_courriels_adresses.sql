-- COURRIELS-3 (directeur, 23/10/2026) : les adresses d'envoi suivent la liste
-- « Envoyer des e-mails en tant que » du compte staff@ : la facturation part de
-- invoices@ (avec un s), les demandes et inscriptions de inscriptions@. Une
-- adresse absente de cette liste ferait partir le message au nom de staff@.
BEGIN;

UPDATE public.courriel_categories
   SET expediteur_adresse = 'invoices@rewayahacademy.com',
       repondre_a = 'invoices@rewayahacademy.com',
       modifie_le = pg_catalog.now()
 WHERE code = 'facturation';

UPDATE public.courriel_categories
   SET expediteur_adresse = 'inscriptions@rewayahacademy.com',
       repondre_a = 'inscriptions@rewayahacademy.com',
       modifie_le = pg_catalog.now()
 WHERE code = 'inscription';

COMMIT;
