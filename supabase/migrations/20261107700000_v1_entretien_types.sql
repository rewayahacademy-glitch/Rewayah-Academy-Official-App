-- V1, visio d'entretien, partie serveur (PLAN-LOTS §3 point 3, garde-cap et
-- pilote, 03/11/2026). Premier des deux fichiers : les deux types seuls,
-- aucune fonction qui les emploie, aucune donnee touchee. Fichier B5 (numero
-- reserve par garde-cap) : colle par le directeur depuis la page du pilote,
-- avant 20261107700001.
--
-- 1. `participant_role` gagne `candidat` : le candidat convoque a un
--    entretien entre dans la salle avec son propre role. Comme `student`, il
--    passerait par les controles d'eleve (camera lue dans student_profiles,
--    donc refusee ; suspension pour paiement ; decompte de paie par eleve
--    present). Une valeur d'enum ajoutee ne s'emploie pas dans la transaction
--    qui la cree : les fonctions qui s'en servent sont dans le fichier
--    suivant (20261107700001), comme 0031 l'a fait pour admin_masked.
--
-- 2. B5 (la seule suppression du lot, accord du pilote du 03/11) : la CHECK de
--    `sessions.session_type`, en ligne dans 0001 (`sessions_session_type_check`,
--    'standard' et 'child'), ne s'elargit pas : une contrainte de plus ne fait
--    que restreindre. Elle est remplacee, dans la meme transaction, par la
--    meme contrainte qui admet aussi 'entretien' et 'reunion'. Aucune donnee
--    n'est touchee ; aucune ligne n'est jamais sans contrainte.
--
-- Mots de suppression de ce fichier : 1 (la contrainte remplacee, ci-dessous).

ALTER TYPE public.participant_role ADD VALUE IF NOT EXISTS 'candidat';

ALTER TABLE public.sessions DROP CONSTRAINT sessions_session_type_check;
ALTER TABLE public.sessions ADD CONSTRAINT sessions_session_type_check
  CHECK (session_type IN ('standard', 'child', 'entretien', 'reunion'));

COMMENT ON CONSTRAINT sessions_session_type_check ON public.sessions IS
  'V1 (03/11/2026) : standard et child (cours) ; entretien (candidat convoque par la direction) et '
  'reunion (direction), exclus de la paie, de la presence, de la cloture et des vues de Classe '
  '(20261107700001).';
