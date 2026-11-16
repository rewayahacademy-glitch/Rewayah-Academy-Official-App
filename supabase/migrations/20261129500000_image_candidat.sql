-- IMAGE-CANDIDAT (16/11/2026) : un candidat envoie une image dans le fil de sa
-- candidature, et un message « [image] » sans image n'est montre a personne.
--
-- Constat de production (capture du directeur, 16/11, 16:04 UTC) : dans le dossier d'un
-- candidat, la bulle du candidat affichait « [image] » sans photo ; aucune ligne
-- com_message_images ; POST message-image-depot -> 403.
--
-- CAUSE (un defaut, pas une regle de conception) : le candidat enseignant est un compte
-- `pending_kyc`. MESSAGES-CANDIDAT (20261119400100) lui ouvre la messagerie par
-- private.com_appelant_msg() et laisse private.com_appelant() fermee. Les fonctions
-- d'images (20261129100000 et 20261129100100), ecrites ensuite, ont ete branchees sur les
-- anciennes portes :
--   * message_image_demander, _lire_depot, _confirmer, _annuler : public.app_account_valid()
--     est faux pour un compte pending_kyc (il n'accepte que active et provisional_active) :
--     ImageNonAutorise, soit le 403 ;
--   * private.com_image_droits : private.com_appelant() ne rend rien pour un candidat : ni
--     lecture ni ecriture, donc ni depot, ni miniatures a signer, ni coeurs.
-- Le contrat (docs/current/IMAGES-MESSAGERIE.md §2) dit « partie du fil, avec les droits de
-- com_lire_fil » : le candidat est partie de son fil, il n'etait pas exclu.
--
-- CORRECTIF, par ancre (comme 20261129100400 et 20261129200000) :
--   1. les quatre fonctions de depot acceptent aussi le candidat de MESSAGES-CANDIDAT
--      (private.com_appelant_candidat() : pending_kyc, candidature d'enseignant) ;
--   2. private.com_image_droits lit private.com_appelant_msg(), la meme porte que les huit
--      fonctions de la messagerie : valide d'abord, a defaut le candidat. Rien d'autre n'est
--      ouvert : le droit de lire et d'ecrire vient toujours de com_fil_json ;
--   3. private.com_fil_json (lue par com_lire_fil ET com_lister_fils, comptes des non lus
--      compris) ne rend jamais un message dont le texte n'est que « [image] » (le texte de
--      remplissage du client) quand AUCUNE ligne d'image ne s'y rattache, a personne, auteur
--      compris (sa bulle locale porte l'echec). Quel que soit l'etat de la ligne : une image
--      confirmee puis purgee (« supprimee » avec confirmee_le, apres 90 jours) garde son
--      message et sa ligne « image retiree » (#519) ; le depot annule ou refuse
--      (« supprimee » sans confirmee_le) est deja ecarte par 20261129200000. Le mot « Image »
--      des premiers essais n'est PAS masque : une personne peut l'ecrire.
--
-- Retouche par ancre : proprietaire, droits, volatilite et search_path gardes ; rejouable ;
-- une ancre trouvee un autre nombre de fois qu'attendu arrete la migration. FICHIER SANS
-- MOT D'EFFACEMENT, sans BEGIN ni COMMIT. S'installe apres 20261129400000 (lp1_liste_enseignants, sans lien avec celle-ci).

CREATE FUNCTION pg_temp.retoucher(
  p_f regprocedure, p_ancre text, p_nouveau text, p_fois integer, p_deja text)
RETURNS void LANGUAGE plpgsql AS $r$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, p_deja) > 0 THEN
    RAISE NOTICE 'image candidat : % porte deja la retouche', p_f;
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> p_fois THEN
    RAISE EXCEPTION 'image candidat : ancre trouvee % fois (attendu %) dans % : %', v_n, p_fois, p_f, p_ancre;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = p_f;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_nouveau);
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = p_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'image candidat : proprietaire, droits ou attributs modifies pour %', p_f;
  END IF;
END
$r$;

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_appelant_msg()') IS NULL
     OR pg_catalog.to_regprocedure('private.com_appelant_candidat()') IS NULL THEN
    RAISE EXCEPTION 'image candidat : installer d''abord 20261119400100_messages_candidat.sql';
  END IF;
  IF pg_catalog.to_regprocedure('public.message_image_demander(uuid,text,bigint,text,bigint,integer,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.com_image_droits(uuid)') IS NULL THEN
    RAISE EXCEPTION 'image candidat : installer d''abord les migrations 202611291000xx';
  END IF;
END
$preflight$;

-- 1. Les quatre fonctions de depot -------------------------------------------------
SELECT pg_temp.retoucher(
  'public.message_image_demander(uuid,text,bigint,text,bigint,integer,integer,text)'::regprocedure,
  'IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR v_moi IS NULL THEN',
  'IF (coalesce(public.app_account_valid(), false) IS NOT TRUE'
    || ' AND NOT EXISTS (SELECT 1 FROM private.com_appelant_candidat())) OR v_moi IS NULL THEN',
  1, 'com_appelant_candidat');
SELECT pg_temp.retoucher(f, 'IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR auth.uid() IS NULL THEN',
  'IF (coalesce(public.app_account_valid(), false) IS NOT TRUE'
    || ' AND NOT EXISTS (SELECT 1 FROM private.com_appelant_candidat())) OR auth.uid() IS NULL THEN',
  1, 'com_appelant_candidat')
FROM unnest(ARRAY[
  'public.message_image_lire_depot(uuid)'::regprocedure,
  'public.message_image_confirmer(uuid,text,text,text,text)'::regprocedure,
  'public.message_image_annuler(uuid)'::regprocedure]) AS f;

-- 2. Les droits sur un fil : la porte de la messagerie ----------------------------
SELECT pg_temp.retoucher(
  'private.com_image_droits(uuid)'::regprocedure,
  'SELECT * INTO moi FROM private.com_appelant();',
  'SELECT * INTO moi FROM private.com_appelant_msg();',
  1, 'com_appelant_msg');

-- 3. « [image] » sans image n'est montre a personne -------------------------------
SELECT pg_temp.retoucher(
  'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure,
  'OR (ix.etat = ''supprimee'' AND ix.confirmee_le IS NULL)))',
  'OR (ix.etat = ''supprimee'' AND ix.confirmee_le IS NULL)))'
    || ' AND NOT (pg_catalog.btrim(m.texte) = ''[image]'''
    || ' AND NOT EXISTS (SELECT 1 FROM public.com_message_images iy'
    || ' WHERE iy.message_id = m.id))',
  2, 'iy.message_id');

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.message_image_demander(uuid,text,bigint,text,bigint,integer,integer,text)'::regprocedure),
       'com_appelant_candidat') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_image_droits(uuid)'::regprocedure),
       'com_appelant_msg') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
       'iy.message_id') = 0 THEN
    RAISE EXCEPTION 'image candidat : retouche absente apres installation';
  END IF;
END
$postflight$;
