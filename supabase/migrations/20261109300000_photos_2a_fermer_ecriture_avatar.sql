-- PHOTOS-2a (04/11/2026, PLAN-LOTS §11, point 2) : fermer la seconde porte
-- d'ecriture de la photo d'un eleve.
--
-- Depuis 0005 (I6), `authenticated` garde un droit UPDATE sur la colonne
-- `student_profiles.avatar_storage_key`. Le tuteur s'en servait pour poser la
-- photo d'un enfant par une ecriture directe de la table. PHOTOS-1
-- (20261107300000) a ouvert les deux portes nommees, `poser_photo_eleve`
-- (le tuteur, enfant mineur de son foyer) et `poser_ma_photo` (chaque adulte,
-- dont l'eleve adulte), qui verifient la cle (dossier de la personne, pas de
-- remontee) et le droit. Le client passe a ces portes dans ce meme lot : la
-- colonne n'a plus de raison d'etre ecrite en direct.
--
-- Seul ce droit de colonne est retire. Les autres droits de colonne de 0005 et
-- des lots suivants (interface_mode, camera_policy, langue_cours,
-- niveau_declare, objectif, cohorte, onboarding_fait_le) restent tels quels.
-- Les fonctions SECURITY DEFINER ecrivent toujours la colonne : elles
-- s'executent en proprietaire.
--
-- Preflight en production (04/11/2026, lecture seule) : le droit UPDATE de
-- `authenticated` sur avatar_storage_key existe au niveau colonne seulement ;
-- aucun droit UPDATE de table pour authenticated, anon ou PUBLIC ;
-- photos_personnes, poser_ma_photo, poser_photo_eleve, photo_visible et
-- photo_adulte_moi presentes.
--
-- Ni suppression d'objet, ni effacement de ligne, ni vidage de table.

REVOKE UPDATE (avatar_storage_key) ON public.student_profiles FROM authenticated;

-- Postflight : la porte directe est fermee, les deux portes nommees restent
-- ouvertes a authenticated, les autres reglages restent modifiables.
DO $postflight$
BEGIN
  IF pg_catalog.has_column_privilege('authenticated', 'public.student_profiles',
                                     'avatar_storage_key', 'UPDATE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : authenticated ecrit encore avatar_storage_key';
  END IF;
  IF pg_catalog.has_column_privilege('anon', 'public.student_profiles',
                                     'avatar_storage_key', 'UPDATE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : anon ecrit avatar_storage_key';
  END IF;
  IF NOT pg_catalog.has_column_privilege('authenticated', 'public.student_profiles',
                                         'interface_mode', 'UPDATE')
     OR NOT pg_catalog.has_column_privilege('authenticated', 'public.student_profiles',
                                            'camera_policy', 'UPDATE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : un reglage du foyer a perdu son droit';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated',
           'public.poser_photo_eleve(uuid, text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
           'public.poser_ma_photo(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
           'public.photos_personnes(uuid[])', 'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : une porte nommee de la photo est fermee';
  END IF;
END
$postflight$;
