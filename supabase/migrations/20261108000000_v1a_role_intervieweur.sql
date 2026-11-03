-- V1-a (03/11/2026, garde-cap et pilote) : le role des intervieweurs en salle.
--
-- Plusieurs personnes du personnel menent un meme entretien (fondateurs et
-- experts, choisis par la direction ; demande du directeur du 03/11). En
-- salle, chacun entre sous son nom, parle et se montre, sans canal de donnees
-- (aucun outil de cours) : un role a lui, `intervieweur`. `admin_visible`
-- ne convenait pas : il entre sous l'identite unique « Administration
-- Rewayah ».
--
-- Seul dans son fichier (garde-cap, 03/11) : une valeur d'enum ajoutee ne
-- s'emploie pas dans la transaction qui la cree. Les fonctions qui
-- l'emploient sont dans 20261108000001. Installe par le pilote.
--
-- Mots de suppression de ce fichier : 0.

ALTER TYPE public.participant_role ADD VALUE IF NOT EXISTS 'intervieweur';
