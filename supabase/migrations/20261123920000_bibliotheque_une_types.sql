-- LOT 3 · BIBLIOTHEQUE-UNE, fichier 1 sur 2 : les trois types neufs du catalogue.
--
-- Le catalogue unique (un seul `library_resource` pour toute l'application)
-- couvre, en plus des types existants (quran, structured_text, pdf, image,
-- lesson), l'audio, la video et le lien externe. « Document » (PDF, texte) reste
-- porte par `pdf` et `structured_text` : la famille « document » de l'ecran est
-- l'union de ces deux types, aucune valeur ne la double.
--
-- FICHIER SEPARE : une valeur d'enum ajoutee ne peut pas etre employee dans la
-- transaction qui l'ajoute. Le fichier 20261123921000 s'en sert et doit donc
-- venir apres que celui-ci est valide.
--
-- Additif ; aucune suppression, aucun effacement, aucune table touchee.
-- Aucune transaction de premier niveau : `ALTER TYPE ... ADD VALUE` n'en veut
-- pas sur les anciens serveurs ; l'installateur enveloppe au besoin.
ALTER TYPE public.library_resource_type ADD VALUE IF NOT EXISTS 'audio';
ALTER TYPE public.library_resource_type ADD VALUE IF NOT EXISTS 'video';
ALTER TYPE public.library_resource_type ADD VALUE IF NOT EXISTS 'external_link';
