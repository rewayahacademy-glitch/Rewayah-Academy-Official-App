-- ADRESSES-FAUTIVES (directeur, 16/11/2026) : migration 20261128600000_adresses_fautives.sql, rejouee ici
-- (commande psql d'inclusion, chemin relatif a la racine du depot) sur des donnees inventees.
--
-- Les vraies adresses ne sont jamais ecrites : le scenario pose le reglage de session
-- rewayah.correction_adresses_md5 avec les empreintes de fausses adresses inventees.
-- Cas couverts : (a) le domaine devient gmail.com, la partie locale ne change pas, courriel_brut garde
-- l'ancienne adresse gardee au journal, journal de type correction ; (b) une adresse hors liste (mail.com) n'est jamais
-- touchee ; (c) une reponse deja rattachee ou passee en historique n'est pas touchee ; (d) une ligne dont l'adresse
-- corrigee est deja portee par une autre reponse active libre du meme genre est laissee, avec la sienne ;
-- (e) une personne qui a deja une candidature en cours avec cette adresse y est rattachee ; (f) rejouer ne
-- change rien ; (g) les autres champs de la ligne ne bougent pas.
-- Chaque controle leve 'ADRESSES ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE, depuis la racine du
-- depot ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ADRESSES ROUGE : %', p_label; END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('adresses-fautives-' || p)::uuid $$;
CREATE FUNCTION pg_temp.ligne(p_cle text) RETURNS public.formulaires_reponses
LANGUAGE sql AS $$ SELECT r.* FROM public.formulaires_reponses r WHERE r.id = pg_temp.id('r-' || p_cle) $$;

-- Un compte de direction (auteur du lot), un lot, des candidates.
INSERT INTO auth.users (id, email) VALUES (pg_temp.id('dir'), 'adresses-dir@test.invalid'),
  (pg_temp.id('u-e'), 'eva@gmail.com');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('dir'), 'ADR-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
       (pg_temp.id('u-e'), 'ADR-ENS-0005', 'teacher', 'Eva', 'Fictive', 'pending_kyc', 'female');
INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES (pg_temp.id('lot'), 'adresses-fautives-lot-1', pg_temp.id('dir'), 'classeur', 'onglet',
        pg_catalog.md5('lot'), '{}', '{}');
-- a : domaine fautif (gamil) ; b : domaine fautif a rallonge (gmail.coma) ; c : mail.com (hors liste) ;
-- d : domaine fautif deja rattachee ; e : domaine fautif, la personne a deja une candidature ;
-- f : domaine fautif, une autre reponse libre porte deja l'adresse corrigee ; g : domaine fautif, passee en historique.
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
  telephone, contenu_empreinte, etat, candidature_id)
SELECT pg_temp.id('r-' || v.k), 'adresses-fautives|' || v.k, pg_temp.id('lot'), now(), v.g::gender, 'Nom ' || v.k,
       v.c, v.t, pg_catalog.md5(v.k), v.e, NULL
FROM (VALUES
  ('a', 'male',   'amine@gamil.com',     '+221700000001', 'active'),
  ('b', 'male',   'bilal@gmail.coma',    '+221700000002', 'active'),
  ('c', 'male',   'chaib@mail.com',      '+221700000003', 'active'),
  ('d', 'male',   'driss@gimil.com',     '+221700000004', 'active'),
  ('e', 'female', 'eva@gamil.com',       '+221700000005', 'active'),
  ('f', 'female', 'fatou@gmai.com',      '+221700000006', 'active'),
  ('f2','female', 'fatou@gmail.com',     '+221700000007', 'active'),
  ('g', 'male',   'ghali@gmial.com',     '+221700000008', 'active')
) AS v(k, g, c, t, e);
-- g : passee en historique (remplacee par une autre ligne).
UPDATE public.formulaires_reponses SET etat = 'historique', remplacee_par = pg_temp.id('r-f2') WHERE id = pg_temp.id('r-g');
-- d : rattachee a une candidature.
INSERT INTO auth.users (id, email) VALUES (pg_temp.id('u-d'), 'driss-compte@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('u-d'), 'ADR-ENS-0004', 'teacher', 'Driss', 'Fictif', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES (pg_temp.id('c-d'), 'enseignant', pg_temp.id('u-d'), 'male', 'Driss', 'prequalification', 'a_completer', 'en_cours', 'lien_public'),
       (pg_temp.id('c-e'), 'enseignant', pg_temp.id('u-e'), 'female', 'Eva', 'prequalification', 'a_completer', 'en_cours', 'lien_public');
UPDATE public.formulaires_reponses SET candidature_id = pg_temp.id('c-d'), rattachement = 'courriel', rattachee_le = now()
 WHERE id = pg_temp.id('r-d');
-- e : la candidature d'Eva porte son courriel (celui du compte, l'adresse corrigee).
INSERT INTO public.candidature_contacts (candidature_id, courriel) VALUES (pg_temp.id('c-e'), 'eva@gmail.com');

SELECT set_config('rewayah.correction_adresses_md5',
  (SELECT string_agg(md5(a), ',') FROM unnest(ARRAY['amine@gamil.com', 'bilal@gmail.coma', 'driss@gimil.com',
     'eva@gamil.com', 'fatou@gmai.com', 'ghali@gmial.com']) AS a), false);
SELECT set_config('test.avant_a', (SELECT concat_ws('|', nom_affiche, telephone, contenu_empreinte, recue_le::text)
  FROM pg_temp.ligne('a')), true);

\i supabase/migrations/20261128600000_adresses_fautives.sql

SELECT pg_temp.vrai((SELECT courriel FROM pg_temp.ligne('a')) = 'amine@gmail.com'
  AND (SELECT courriel FROM pg_temp.ligne('b')) = 'bilal@gmail.com',
  'a1 : le domaine devient gmail.com, la partie avant l''arobase ne change pas (gamil, gmail.coma)');
SELECT pg_temp.vrai((SELECT courriel_brut IS NULL FROM pg_temp.ligne('a'))
  AND (SELECT j.details ->> 'courrielAvant' FROM public.formulaires_journal j WHERE j.reponse_id = pg_temp.id('r-a') AND j.type = 'correction') = 'amine@gamil.com'
  AND (SELECT j.details ->> 'courrielAvant' FROM public.formulaires_journal j WHERE j.reponse_id = pg_temp.id('r-b') AND j.type = 'correction') = 'bilal@gmail.coma',
  'a2 : l''ancienne adresse est gardee dans le journal (courriel_brut reste vide : une seule des deux colonnes peut etre posee)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.formulaires_journal j WHERE j.reponse_id = pg_temp.id('r-a')
    AND j.type = 'correction' AND j.auteur_id IS NULL
    AND j.details @> '{"champs": ["courriel"], "domaineAvant": "gamil.com", "domaineApres": "gmail.com", "decision": "directeur, 16/11/2026"}'::jsonb) = 1,
  'a3 : une ligne de journal « correction » (champs, domaine avant et apres, decision du directeur)');
SELECT pg_temp.vrai((SELECT concat_ws('|', nom_affiche, telephone, contenu_empreinte, recue_le::text) FROM pg_temp.ligne('a'))
  = current_setting('test.avant_a'),
  'g1 : le nom, le telephone, l''empreinte du contenu et la date de la ligne ne bougent pas');
SELECT pg_temp.vrai((SELECT courriel FROM pg_temp.ligne('c')) = 'chaib@mail.com'
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_journal j WHERE j.reponse_id = pg_temp.id('r-c')),
  'b1 : mail.com (hors liste) n''est jamais touche');
SELECT pg_temp.vrai((SELECT courriel FROM pg_temp.ligne('d')) = 'driss@gimil.com'
  AND (SELECT courriel FROM pg_temp.ligne('g')) = 'ghali@gmial.com',
  'c1 : une reponse deja rattachee ou en historique n''est pas touchee');
SELECT pg_temp.vrai((SELECT courriel FROM pg_temp.ligne('f')) = 'fatou@gmai.com'
  AND (SELECT courriel FROM pg_temp.ligne('f2')) = 'fatou@gmail.com'
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_journal j WHERE j.reponse_id = pg_temp.id('r-f')),
  'd1 : quand une autre reponse libre du meme genre porte deja l''adresse corrigee, la ligne est laissee telle quelle');
SELECT pg_temp.vrai((SELECT courriel FROM pg_temp.ligne('e')) = 'eva@gmail.com'
  AND (SELECT candidature_id FROM pg_temp.ligne('e')) = pg_temp.id('c-e')
  AND (SELECT rattachement FROM pg_temp.ligne('e')) = 'courriel',
  'e1 : la personne qui a deja une candidature en cours avec cette adresse y est rattachee (par courriel)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements ev WHERE ev.candidature_id = pg_temp.id('c-e')
    AND ev.type = 'import' AND ev.details ->> 'cle' = 'courriel') = 1,
  'e2 : le rattachement est trace sur la candidature');

-- Rejouer ne change plus rien.
SELECT set_config('test.journal', (SELECT count(*)::text FROM public.formulaires_journal), true);
\i supabase/migrations/20261128600000_adresses_fautives.sql
SELECT pg_temp.vrai((SELECT count(*)::text FROM public.formulaires_journal) = current_setting('test.journal')
  AND (SELECT courriel FROM pg_temp.ligne('a')) = 'amine@gmail.com',
  'f1 : rejouee, la migration ne change rien (aucun journal de plus)');

-- Sans reglage de session, la liste de la migration ne reconnait aucune de ces fausses adresses.
SELECT set_config('rewayah.correction_adresses_md5', '', false);
SELECT set_config('test.journal', (SELECT count(*)::text FROM public.formulaires_journal), true);
\i supabase/migrations/20261128600000_adresses_fautives.sql
SELECT pg_temp.vrai((SELECT count(*)::text FROM public.formulaires_journal) = current_setting('test.journal')
  AND (SELECT courriel FROM pg_temp.ligne('f')) = 'fatou@gmai.com'
  AND (SELECT courriel FROM pg_temp.ligne('d')) = 'driss@gimil.com',
  'h1 : sans reglage de session (la production), les fausses adresses du scenario ne sont pas reconnues');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 11, 'z : au moins 11 controles passes');
DO $$ BEGIN RAISE NOTICE 'ADRESSES : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
