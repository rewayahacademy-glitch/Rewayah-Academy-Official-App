-- MINEUR-FANTOME, cloture des demandes (07/11/2026, migration 20261110340000 §5) :
-- quand un profil eleve est supprime (private.suppr_retirer, ici par son
-- titulaire), ses demandes encore ouvertes sont closes, jamais effacees.
--   1. demandes_horaires_famille « envoyee » -> « retiree », motif « profil supprimé ».
--   2. intentions_horaire « enregistree » -> « retiree », retiree_par = l'acteur,
--      retrait_motif « profil supprimé ».
--   3. demandes_presentation « en_attente » -> « refusee », repondu_par = l'acteur.
--   4. demandes_creneau_personnalise « en_attente_quota » -> « retiree » ;
--      « offre_ouverte » (d'un second enfant supprime) ne bouge pas : son lien
--      avec l'offre serait perdu.
--   5. Une demande deja close (« refusee ») ne bouge pas ; aucune ligne effacee.
--   6. Les demandes d'un autre enfant du foyer ne bougent pas.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque
-- controle reussi ecrit une ligne "CLOTURE OK" ; un echec leve 'CLOTURE ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('f5000000-0000-4000-8000-000000000001', 'cloture-tuteur@example.test'),
  ('f5000000-0000-4000-8000-000000000002', 'cloture-enfant@example.test'),
  ('f5000000-0000-4000-8000-000000000003', 'cloture-frere@example.test'),
  ('f5000000-0000-4000-8000-000000000004', 'cloture-soeur@example.test');

SELECT set_config('request.jwt.claim.sub', 'f5000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'f5000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Amina', 'Diallo', 'female', 'Europe/Paris', false);
RESET ROLE;
UPDATE public.candidatures SET etape = 'confirmee'
 WHERE profile_id = 'f5000000-0000-4000-8000-000000000001' AND type_code = 'famille';
UPDATE public.profiles SET account_status = 'active'
 WHERE id = 'f5000000-0000-4000-8000-000000000001';

UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'f5000000-0000-4000-8000-000000000001', 'gender', 'male'), created_at = now()
 WHERE id IN ('f5000000-0000-4000-8000-000000000002', 'f5000000-0000-4000-8000-000000000003',
              'f5000000-0000-4000-8000-000000000004');

SELECT set_config('request.jwt.claims',
  '{"sub":"f5000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt',
  '{"sub":"f5000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);

SELECT public.creer_profil_enfant('f5000000-0000-4000-8000-000000000002',
  'f5000000-0000-4000-8000-000000000001', 'Yanis', 'Diallo', 9);
SELECT public.creer_profil_enfant('f5000000-0000-4000-8000-000000000003',
  'f5000000-0000-4000-8000-000000000001', 'Sami', 'Diallo', 11);
SELECT public.creer_profil_enfant('f5000000-0000-4000-8000-000000000004',
  'f5000000-0000-4000-8000-000000000001', 'Lina', 'Diallo', 13);

-- Les demandes, posees comme les ecrirait l'application.
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, created_by)
VALUES ('f5aaaaaa-0000-4000-8000-000000000001', 'enfant', 'francais', 'Europe/Paris',
        ARRAY[3]::smallint[], 18, 60, 'brouillon', 'f5000000-0000-4000-8000-000000000001');

-- Une demande deja refusee d'abord (une seule demande active par eleve).
INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, etat)
VALUES
  ('f5bbbbbb-0000-4000-8000-000000000002', 'f5000000-0000-4000-8000-000000000002',
   'enfant', 'francais', 'Europe/Paris', ARRAY[4]::smallint[], ARRAY[18]::smallint[], 'personnalisee', 'envoyee');
UPDATE public.demandes_horaires_famille SET etat = 'refusee', motif = 'complet'
 WHERE id = 'f5bbbbbb-0000-4000-8000-000000000002';

INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, etat)
VALUES
  ('f5bbbbbb-0000-4000-8000-000000000001', 'f5000000-0000-4000-8000-000000000002',
   'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], ARRAY[18]::smallint[], 'personnalisee', 'envoyee'),
  ('f5bbbbbb-0000-4000-8000-000000000003', 'f5000000-0000-4000-8000-000000000003',
   'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], ARRAY[18]::smallint[], 'personnalisee', 'envoyee');
INSERT INTO public.intentions_horaire
  (id, eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
VALUES ('f5cccccc-0000-4000-8000-000000000001', 'f5000000-0000-4000-8000-000000000002',
        'f5aaaaaa-0000-4000-8000-000000000001', 'Europe/Paris', 18, ARRAY[3]::smallint[],
        'f5000000-0000-4000-8000-000000000001');

INSERT INTO public.demandes_presentation (id, eleve_id, foyer_id)
SELECT 'f5dddddd-0000-4000-8000-000000000001', 'f5000000-0000-4000-8000-000000000002', p.household_id
  FROM public.profiles p WHERE p.id = 'f5000000-0000-4000-8000-000000000001';

INSERT INTO public.demandes_creneau_personnalise
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heure_locale, etat, offre_id)
VALUES
  ('f5eeeeee-0000-4000-8000-000000000001', 'f5000000-0000-4000-8000-000000000002',
   'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 'en_attente_quota', NULL),
  ('f5eeeeee-0000-4000-8000-000000000002', 'f5000000-0000-4000-8000-000000000004',
   'enfant', 'francais', 'Europe/Paris', ARRAY[3]::smallint[], 18, 'offre_ouverte',
   'f5aaaaaa-0000-4000-8000-000000000001');

-- Le titulaire supprime les profils de Yanis et de Lina (Sami reste).
SET LOCAL ROLE authenticated;
SELECT public.tuteur_supprimer_profil_enfant('f5000000-0000-4000-8000-000000000002');
SELECT public.tuteur_supprimer_profil_enfant('f5000000-0000-4000-8000-000000000004');
RESET ROLE;

DO $cloture$
DECLARE
  v_t constant uuid := 'f5000000-0000-4000-8000-000000000001';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'f5000000-0000-4000-8000-000000000002'
                   AND deleted_at IS NOT NULL) THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : le profil n''est pas supprime';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.demandes_horaires_famille
                  WHERE id = 'f5bbbbbb-0000-4000-8000-000000000001'
                    AND etat = 'retiree' AND motif = 'profil supprimé') THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : la demande horaire envoyee n''est pas retiree avec « profil supprimé »';
  END IF;
  RAISE NOTICE 'CLOTURE OK : demande horaire envoyee -> retiree, motif « profil supprimé »';

  IF NOT EXISTS (SELECT 1 FROM public.intentions_horaire
                  WHERE id = 'f5cccccc-0000-4000-8000-000000000001'
                    AND etat = 'retiree' AND retiree_at IS NOT NULL AND retiree_par = v_t
                    AND retrait_motif = 'profil supprimé') THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : l''intention n''est pas retiree par le titulaire avec « profil supprimé »';
  END IF;
  RAISE NOTICE 'CLOTURE OK : intention -> retiree, par le titulaire, motif « profil supprimé »';

  IF NOT EXISTS (SELECT 1 FROM public.demandes_presentation
                  WHERE id = 'f5dddddd-0000-4000-8000-000000000001'
                    AND statut = 'refusee' AND repondu_le IS NOT NULL AND repondu_par = v_t) THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : la demande de presentation n''est pas close';
  END IF;
  RAISE NOTICE 'CLOTURE OK : demande de presentation -> refusee, par le titulaire';

  IF NOT EXISTS (SELECT 1 FROM public.demandes_creneau_personnalise
                  WHERE id = 'f5eeeeee-0000-4000-8000-000000000001'
                    AND etat = 'retiree' AND retiree_at IS NOT NULL) THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : la demande de creneau en attente n''est pas retiree';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.demandes_creneau_personnalise
                  WHERE id = 'f5eeeeee-0000-4000-8000-000000000002'
                    AND etat = 'offre_ouverte' AND offre_id IS NOT NULL) THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : la demande de creneau a offre ouverte a bouge';
  END IF;
  RAISE NOTICE 'CLOTURE OK : creneau en attente -> retiree ; offre_ouverte inchangee';

  IF NOT EXISTS (SELECT 1 FROM public.demandes_horaires_famille
                  WHERE id = 'f5bbbbbb-0000-4000-8000-000000000002'
                    AND etat = 'refusee' AND motif = 'complet') THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : une demande deja refusee a bouge';
  END IF;
  IF (SELECT count(*) FROM public.demandes_horaires_famille
       WHERE eleve_id = 'f5000000-0000-4000-8000-000000000002') <> 2
     OR (SELECT count(*) FROM public.intentions_horaire
          WHERE eleve_id = 'f5000000-0000-4000-8000-000000000002') <> 1
     OR (SELECT count(*) FROM public.demandes_presentation
          WHERE eleve_id = 'f5000000-0000-4000-8000-000000000002') <> 1
     OR (SELECT count(*) FROM public.demandes_creneau_personnalise
          WHERE eleve_id = 'f5000000-0000-4000-8000-000000000002') <> 1
     OR (SELECT count(*) FROM public.demandes_creneau_personnalise
          WHERE eleve_id = 'f5000000-0000-4000-8000-000000000004') <> 1 THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : une ligne a ete effacee';
  END IF;
  RAISE NOTICE 'CLOTURE OK : demande deja refusee inchangee, aucune ligne effacee';

  IF NOT EXISTS (SELECT 1 FROM public.demandes_horaires_famille
                  WHERE id = 'f5bbbbbb-0000-4000-8000-000000000003' AND etat = 'envoyee') THEN
    RAISE EXCEPTION 'CLOTURE ROUGE : la demande du frere a bouge';
  END IF;
  RAISE NOTICE 'CLOTURE OK : la demande de l''autre enfant du foyer reste envoyee';
END
$cloture$;

ROLLBACK;
