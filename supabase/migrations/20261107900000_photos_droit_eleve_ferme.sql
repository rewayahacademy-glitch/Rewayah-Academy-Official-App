-- PHOTOS-2a (03/11/2026, PLAN-LOTS §11) : la photo d'un eleve ne s'ecrit plus
-- que par la porte nommee de PHOTOS-1.
--
-- 0005 (I6) donnait a `authenticated` le droit d'ecrire trois colonnes de
-- `student_profiles` : `interface_mode`, `camera_policy` et
-- `avatar_storage_key`. Le tuteur y posait la cle de photo de son enfant par
-- une ecriture directe (`majReglages`). Depuis PHOTOS-1, la photo d'un eleve
-- se pose par `public.poser_photo_eleve(uuid, text)` (le tuteur, pour un
-- enfant mineur de son foyer) ou `public.poser_ma_photo(text)` (l'eleve
-- adulte, sur lui-meme), qui verifient le foyer, l'age et le dossier de la
-- cle. Le client passe par ces fonctions dans la meme PR (point obligatoire
-- de PHOTOS-2, decision du pilote du 03/11).
--
-- Seul le droit sur `avatar_storage_key` est retire : `interface_mode` et
-- `camera_policy` restent ecrits par le foyer comme avant. Les fonctions de
-- PHOTOS-1 sont SECURITY DEFINER et ne dependent pas de ce droit.
--
-- Rien n'est supprime ni efface : un droit de colonne retire, une
-- verification.

REVOKE UPDATE (avatar_storage_key) ON public.student_profiles FROM authenticated;

-- Verification finale : le droit est ferme, les deux autres restent, et la
-- porte nommee est toujours ouverte au client.
DO $verif$
BEGIN
  IF has_column_privilege('authenticated', 'public.student_profiles',
                          'avatar_storage_key', 'UPDATE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : authenticated peut encore ecrire avatar_storage_key';
  END IF;
  IF NOT has_column_privilege('authenticated', 'public.student_profiles',
                              'interface_mode', 'UPDATE')
     OR NOT has_column_privilege('authenticated', 'public.student_profiles',
                                 'camera_policy', 'UPDATE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : un reglage du foyer a perdu son droit d''ecriture';
  END IF;
  IF NOT has_function_privilege('authenticated',
                                'public.poser_photo_eleve(uuid, text)',
                                'EXECUTE') THEN
    RAISE EXCEPTION 'PHOTOS-2a : poser_photo_eleve n''est pas ouverte au client';
  END IF;
END
$verif$;
