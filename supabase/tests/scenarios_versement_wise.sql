-- FINANCE-ENSEIGNANT (lot 9, 06/11/2026) : la paie par fichier Wise.
-- Migrations 20261110700000 (coordonnees, modele, export) et 20261110710000
-- (versements notes).
--   1. l'enseignant enregistre SES coordonnees ; champ requis manquant refuse ;
--      virgule refusee (CSV sain) ; relecture masquee sauf 4 caracteres ;
--   2. un tuteur, anon, un enseignant qui lit les coordonnees d'un autre sont
--      refuses ; aucun acces direct aux tables ;
--   3. remplacement et retrait : l'ancienne ligne reste, inactive ;
--   4. le modele du directeur est pose par defaut ; une version nouvelle se
--      pose par la direction seule ; l'Etat n'est demande qu'aux US et au CA ;
--   5. export : montant = du du releve moins verse ; enseignant sans
--      coordonnees a part ; journalise ; colonnes dans l'ordre du modele.
-- Le releve de paie est REMPLACE dans la transaction par une version fixe
-- (annulee au ROLLBACK) : ce scenario prouve l'export, pas le calcul du du,
-- deja prouve par les scenarios de la paie.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'VERSEMENT-WISE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'VERSEMENT-WISE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fa000000-0000-4000-8000-0000000000' || p)::uuid $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated, service_role, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'vw-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','ac','b1','b2','b3','d1']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.id('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'VW', (CASE WHEN x.role = 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','VW-ADM-0001','admin',NULL,'Direction','female'),
   ('ac','VW-CPT-0001','accountant',NULL,'Karima','female'),
   ('b1','VW-ENS-0001','teacher',NULL,'Mamadou','male'),
   ('b2','VW-ENS-0002','teacher',NULL,'Fatou','female'),
   ('b3','VW-ENS-0003','teacher',NULL,'Ousmane','male'),
   ('d1','VW-TUT-0001','guardian','f1','Amina','female')) AS x(id, mat, role, foyer, prenom, genre);



INSERT INTO public.teacher_profiles(profile_id, country)
SELECT pg_temp.id('b1'), 'GN' WHERE NOT EXISTS (SELECT 1 FROM public.teacher_profiles WHERE profile_id = pg_temp.id('b1'));

-- Le releve fixe du mois (remplace pour la transaction seulement).
CREATE OR REPLACE FUNCTION public.releve_paie_mensuel(p_mois date DEFAULT NULL)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $f$
  SELECT pg_catalog.jsonb_build_object('debut', '2026-10-01', 'devise', 'USD', 'enseignants',
    pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('enseignantId', 'fa000000-0000-4000-8000-0000000000b1',
        'prenom', 'Mamadou', 'nom', 'VW', 'montant', pg_catalog.jsonb_build_object('mineur', 5174, 'devise', 'USD')),
      pg_catalog.jsonb_build_object('enseignantId', 'fa000000-0000-4000-8000-0000000000b2',
        'prenom', 'Fatou', 'nom', 'VW', 'montant', pg_catalog.jsonb_build_object('mineur', 2587, 'devise', 'USD')),
      pg_catalog.jsonb_build_object('enseignantId', 'fa000000-0000-4000-8000-0000000000b3',
        'prenom', 'Ousmane', 'nom', 'VW', 'montant', pg_catalog.jsonb_build_object('mineur', 1000, 'devise', 'USD'))));
$f$;

-- ------------------------------------------------------------------
-- 1. L'enseignant enregistre
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.mes_coordonnees_versement() ->> 'enregistre')::boolean
  AND public.mes_coordonnees_versement() ->> 'paysProfil' = 'GN'
  AND (public.mes_coordonnees_versement() -> 'champs')::text LIKE '%"swift"%',
  '1 : rien d''enregistre ; pays du profil et champs requis rendus');
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Mamadou Diallo',
  '0012345678901', NULL, NULL, 'GN', 'Conakry', 'Quartier Kaloum', NULL, NULL, true, NULL, NULL)$$,
  '1 : un champ requis manquant (SWIFT) est refuse');
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Diallo, Mamadou',
  '0012345678901', NULL, 'ECOCGNGN', 'GN', 'Conakry', 'Kaloum', NULL, NULL, true, NULL, NULL)$$,
  '1 : une virgule dans un texte est refusee (CSV sain)');
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('XOF', 'Mamadou Diallo',
  '0012345678901', NULL, 'ECOCGNGN', 'GN', 'Conakry', 'Kaloum', NULL, NULL, true, NULL, NULL)$$,
  '1 : une devise non proposee est refusee');
SELECT pg_temp.vrai((public.enregistrer_mes_coordonnees_versement('usd', 'Mamadou Diallo',
  '0012 3456 7890 1', 'GN00IGNORE', 'ecoc gn gn', 'gn', 'Conakry', 'Quartier Kaloum', 'X', NULL, true, NULL, NULL)
  ->> 'complet')::boolean, '1 : enregistrement complet (espaces et casse normalises)');
SELECT pg_temp.vrai(public.mes_coordonnees_versement() -> 'coordonnees' ->> 'numeroCompte' = '••••8901'
  AND public.mes_coordonnees_versement() -> 'coordonnees' ->> 'swift' = '••••GNGN'
  AND public.mes_coordonnees_versement()::text NOT LIKE '%0012345678901%',
  '1 : relecture masquee sauf les 4 derniers caracteres');
RESET ROLE;
SELECT pg_temp.vrai((SELECT iban IS NULL AND code_postal = 'X' AND swift = 'ECOCGNGN' AND adresse_pays = 'GN'
                       FROM public.versement_coordonnees WHERE profile_id = pg_temp.id('b1') AND active),
  '1 : hors des champs du modele rien n''est garde (pas d''IBAN) ; code postal facultatif garde');

-- ------------------------------------------------------------------
-- 2. Refus
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.mes_coordonnees_versement() ->> 'enregistre')::boolean,
  '2 : un autre enseignant ne voit pas les coordonnees du premier');
SELECT pg_temp.refus('SELECT * FROM public.versement_coordonnees', '2 : aucune lecture directe');
SELECT pg_temp.refus($$SELECT public.versement_export_wise(DATE '2026-10-01')$$,
  '2 : un enseignant n''exporte pas');
SELECT pg_temp.refus('SELECT public.versement_coordonnees_direction()', '2 : un enseignant ne lit pas la liste');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.mes_coordonnees_versement()', '2 : un tuteur est refuse');
SELECT pg_temp.refus($$SELECT public.versement_export_wise(DATE '2026-10-01')$$, '2 : un tuteur n''exporte pas');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.mes_coordonnees_versement()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.versement_export_wise(date)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.versement_coordonnees', 'SELECT')
  AND NOT has_table_privilege('service_role', 'public.versement_coordonnees', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.versement_journal', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.versement_wise_colonnes', 'INSERT'),
  '2 : anon sans fonctions ; aucun droit direct, service_role compris');

-- ------------------------------------------------------------------
-- 3. Remplacement et retrait
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Fatou Sow', '11112222', NULL, 'BICISNDX',
  'SN', 'Dakar', 'Plateau', NULL, NULL, true, NULL, NULL);
SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Fatou Sow', '33334444', NULL, 'BICISNDX',
  'SN', 'Dakar', 'Plateau', NULL, NULL, true, NULL, NULL);
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.mon_journal_coordonnees_versement()) = 2,
  '3 : journal : deux enregistrements');
SELECT pg_temp.vrai(NOT (public.mes_coordonnees_versement() ->> 'valide')::boolean,
  '3 : tout changement attend la validation de la direction');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.versement_coordonnees WHERE profile_id = pg_temp.id('b2')) = 2
  AND (SELECT count(*) FROM public.versement_coordonnees WHERE profile_id = pg_temp.id('b2') AND active) = 1,
  '3 : remplacement : l''ancienne ligne reste, inactive');
SELECT pg_temp.qui(pg_temp.id('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Ousmane Ba', '55556666', NULL, 'BMCEMAMC',
  'MA', 'Rabat', 'Agdal', NULL, NULL, true, NULL, NULL);
SELECT pg_temp.vrai(NOT (public.retirer_mes_coordonnees_versement() ->> 'enregistre')::boolean,
  '3 : retrait : plus de coordonnees actives');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.versement_coordonnees WHERE profile_id = pg_temp.id('b3')) = 1,
  '3 : retrait : la ligne reste');
SELECT pg_temp.refus('UPDATE public.versement_journal SET lignes = 0', '3 : le journal est en ajout seul');

-- ------------------------------------------------------------------
-- 4. Modele Wise (pose par defaut : modele du directeur du 06/11)
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT count(*) FROM public.versement_wise_colonnes WHERE version = 1) = 17,
  '4 : le modele du directeur est pose par defaut (17 colonnes)');
SELECT pg_temp.qui(pg_temp.id('ac'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.poser_modele_wise('[{"enTete":"name","source":"champ","champ":"titulaire"}]'::jsonb)$$,
  '4 : le comptable ne pose pas le modele');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.poser_modele_wise('[{"enTete":"Na,me","source":"champ","champ":"titulaire"}]'::jsonb)$$,
  '4 : un en-tete avec virgule est refuse');
RESET ROLE;
-- Etat et code postal : l'Etat n'est demande qu'aux Etats-Unis et au Canada.
SELECT pg_temp.qui(pg_temp.id('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Ousmane Ba', '55556666', NULL,
  'CHASUS33', 'US', 'Austin', 'Main Street', NULL, NULL, true, NULL, NULL)$$,
  '4 : adresse aux Etats-Unis sans Etat : refusee');
SELECT pg_temp.vrai((public.enregistrer_mes_coordonnees_versement('USD', 'Ousmane Ba', '55556666', NULL,
  'CHASUS33', 'US', 'Austin', 'Main Street', '73301', 'tx', true, NULL, NULL) ->> 'complet')::boolean,
  '4 : avec l''Etat et le code postal : complet');
SELECT pg_temp.vrai(NOT (public.retirer_mes_coordonnees_versement() ->> 'enregistre')::boolean,
  '4 : retrait de nouveau');
RESET ROLE;
SELECT pg_temp.vrai((SELECT adresse_etat IS NULL FROM public.versement_coordonnees
                      WHERE profile_id = pg_temp.id('b1') AND active),
  '4 : en Guinee, aucun Etat garde');

-- ------------------------------------------------------------------
-- 5. Export
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
-- Compte au nom d'un tiers : lien et accord exiges.
SELECT pg_temp.qui(pg_temp.id('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Aminata Sow', '33334444', NULL,
  'BICISNDX', 'SN', 'Dakar', 'Plateau', NULL, NULL, false, 'parent', false)$$,
  '5 : compte d''un tiers sans accord : refuse');
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Aminata Sow', '33334444', NULL,
  'BICISNDX', 'SN', 'Dakar', 'Plateau', NULL, NULL, false, NULL, true)$$,
  '5 : compte d''un tiers sans lien : refuse');
SELECT pg_temp.vrai(NOT (public.enregistrer_mes_coordonnees_versement('USD', 'Aminata Sow', '33334444', NULL,
  'BICISNDX', 'SN', 'Dakar', 'Plateau', NULL, NULL, false, 'parent', true) ->> 'valide')::boolean,
  '5 : compte de la mere de Fatou enregistre, pas encore valide');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants
                      WHERE destinataire_profil = pg_temp.id('b2') AND modele = 'coordonnees_versement_changees') = 3,
  '5 : un courriel a Fatou par changement (trois enregistrements)');

-- Pays ou Wise ne verse pas : lu dans le referentiel (la donnee est posee ici).
UPDATE public.referentiel_paiement SET etat = 'indisponible'
 WHERE pays = 'YE' AND methode = 'virement_bancaire';
UPDATE public.teacher_profiles SET country = 'YE' WHERE profile_id = pg_temp.id('b3');
INSERT INTO public.teacher_profiles(profile_id, country)
SELECT pg_temp.id('b3'), 'YE' WHERE NOT EXISTS (SELECT 1 FROM public.teacher_profiles WHERE profile_id = pg_temp.id('b3'));
SELECT pg_temp.qui(pg_temp.id('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.enregistrer_mes_coordonnees_versement('USD', 'Ousmane Ba', '77778888', NULL,
  'YNBKYESA', 'YE', 'Sanaa', 'Al Tahrir', NULL, NULL, true, NULL, NULL)$$,
  '5 : compte au Yemen (indisponible au referentiel) : refuse');
SELECT pg_temp.vrai((public.enregistrer_mes_coordonnees_versement('USD', 'Ali Ba', '99990000', NULL,
  'RJHISARI', 'SA', 'Riyad', 'Al Olaya', NULL, NULL, false, 'frere_soeur', true) ->> 'enregistre')::boolean,
  '5 : enseignant au Yemen, compte d''un proche en Arabie saoudite : accepte');
SELECT public.retirer_mes_coordonnees_versement();
RESET ROLE;

-- La direction valide Mamadou ; Fatou reste a valider.
SELECT pg_temp.qui(pg_temp.id('ac'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.valider_coordonnees_versement('fa000000-0000-4000-8000-0000000000b1',
  (SELECT x.id FROM public.versement_coordonnees x LIMIT 1))$$, '5 : le comptable ne valide pas');
RESET ROLE;
SELECT set_config('test.c1', (SELECT id::text FROM public.versement_coordonnees
                                WHERE profile_id = pg_temp.id('b1') AND active), true);
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.valider_coordonnees_versement('fa000000-0000-4000-8000-0000000000b1',
  gen_random_uuid())$$, '5 : valider une ligne qui n''est plus l''active : refuse');
SELECT pg_temp.vrai(public.valider_coordonnees_versement(pg_temp.id('b1'), current_setting('test.c1')::uuid),
  '5 : la direction valide les coordonnees lues');
SELECT pg_temp.vrai(
  (SELECT x ->> 'lienTitulaire' = 'parent' AND x ->> 'titulaire' = 'Aminata Sow'
          AND NOT (x ->> 'valide')::boolean AND x ->> 'numeroMasque' = '••••4444'
     FROM pg_catalog.jsonb_array_elements(public.versement_coordonnees_direction() -> 'enseignants') x
    WHERE x ->> 'prenom' = 'Fatou'),
  '5 : la direction lit le titulaire, le lien et le numero masque avant de valider');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.versement_journal
                             WHERE objet = 'coordonnees_validees' AND profile_id = pg_temp.id('b1')
                               AND auteur = pg_temp.id('a1'))
  AND EXISTS (SELECT 1 FROM public.courriels_sortants
               WHERE destinataire_profil = pg_temp.id('b1') AND modele = 'coordonnees_versement_validees'),
  '5 : validation journalisee, courriel a Mamadou');

-- Un versement deja note pour Mamadou : 2 000 sur 5 174.
SELECT public.versement_paie_noter(pg_temp.id('b1'), 2000, 'USD', DATE '2026-11-02', 'virement_bancaire',
  'TX-1', DATE '2026-10-01', NULL, gen_random_uuid());
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('ac'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT set_config('test.export', public.versement_export_wise(DATE '2026-10-15')::text, true);
RESET ROLE;
SELECT pg_temp.vrai((current_setting('test.export')::jsonb -> 'colonnes') = '["name","recipientEmail","paymentReference","referenceNumber","receiverType","amountCurrency","amount","sourceCurrency","targetCurrency","type","accountNumber","BIC","addressCountryCode","addressCity","addressFirstLine","addressState","addressPostCode"]'::jsonb,
  '5 : les 17 colonnes du modele du directeur, dans l''ordre');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(current_setting('test.export')::jsonb -> 'lignes') = 1,
  '5 : une ligne (Mamadou, valide) ; Fatou attend la validation');
SELECT pg_temp.vrai((current_setting('test.export')::jsonb -> 'lignes' -> 0) =
  '["Mamadou Diallo","vw-b1@test.invalid","Rewayah paie 2026-10","VW-ENS-0001","PERSON","target","31.74","USD","USD","SwiftCode","0012345678901","ECOCGNGN","GN","Conakry","Quartier Kaloum","","X"]'::jsonb,
  '5 : ligne de Mamadou : reste 31.74 (51.74 moins 20.00), courriel, reference, matricule, frais a l''academie');
SELECT pg_temp.vrai(
  (SELECT x ->> 'raison' FROM pg_catalog.jsonb_array_elements(current_setting('test.export')::jsonb -> 'manquants') x
    WHERE x ->> 'nom' = 'Fatou VW') = 'a_valider'
  AND (SELECT x ->> 'raison' FROM pg_catalog.jsonb_array_elements(current_setting('test.export')::jsonb -> 'manquants') x
    WHERE x ->> 'nom' = 'Ousmane VW') = 'aucune'
  AND (current_setting('test.export')::jsonb -> 'total' ->> 'mineur')::bigint = 3174,
  '5 : a part : Fatou (a valider), Ousmane (aucune) ; total 31.74');
SELECT pg_temp.vrai((SELECT lignes = 1 AND manquants = 2 AND mois = DATE '2026-10-01' AND total_minor = 3174
                       AND auteur = pg_temp.id('ac')
                       FROM public.versement_journal WHERE objet = 'export_wise'),
  '5 : export journalise (qui, mois, lignes, manquants, total)');
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.versement_exports_direction()) = 1
  AND (SELECT count(*) FROM pg_catalog.jsonb_array_elements(public.versement_coordonnees_direction() -> 'enseignants') x
        WHERE (x ->> 'complet')::boolean) = 2
  AND public.versement_coordonnees_direction()::text NOT LIKE '%0012345678901%',
  '5 : la direction lit les exports et qui est complet, sans aucun numero');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.poser_modele_wise('[{"enTete":"name","source":"champ","champ":"titulaire"},
  {"enTete":"amount","source":"montant"},{"enTete":"receiverType","source":"fixe","valeurFixe":"PERSON"}]'::jsonb) = 3
  AND (public.versement_export_wise(DATE '2026-10-01') -> 'colonnes') = '["name","amount","receiverType"]'::jsonb,
  '5 : un modele nouveau fait foi, l''ancien reste');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.versement_wise_colonnes) = 20, '5 : version 1 gardee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 30,
  'au moins 30 controles ont passe');
\o
SELECT 'VERSEMENT-WISE : scenarios verts' AS resultat;
ROLLBACK;
