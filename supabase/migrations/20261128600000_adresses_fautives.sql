-- ADRESSES-FAUTIVES (directeur, 16/11/2026) : corriger le courriel de 15 reponses de formulaire dont
-- l'adresse porte une faute evidente dans le domaine (gamil, gmial, gmail.coma, ...) : le domaine
-- devient gmail.com, la partie avant l'arobase ne change jamais.
--
-- Ce fichier n'ecrit aucune adresse : les 15 lignes sont reconnues par l'empreinte md5 de leur
-- courriel actuel (liste ci-dessous, relevee le 16/11/2026 sur la production). Il ne touche que des
-- reponses actives, pas encore rattachees a une candidature. mail.com, email.com et mmmm.com ne sont
-- pas dans la liste : ils ne sont jamais touches.
--
-- Pour chaque ligne reconnue :
--  * si une AUTRE reponse active, libre, du meme genre porte deja l'adresse corrigee, la ligne n'est
--    PAS corrigee (deux reponses au meme courriel : plus aucun rattachement automatique par adresse) ;
--    un NOTICE le dit, la direction tranche (reponse remplacee ou non) ;
--  * sinon : courriel corrige, une ligne de journal de type `correction` (champs, ancienne adresse,
--    domaine avant, domaine apres, decision du directeur). L'ancienne valeur est gardee dans le JOURNAL
--    et non dans courriel_brut : la contrainte formulaires_reponses_un_courriel interdit d'avoir a la
--    fois courriel et courriel_brut (courriel_brut ne garde qu'une valeur illisible) ;
--  * puis le rapprochement dans l'autre sens (private.formulaires_rapprocher_reponse) : si la personne
--    a deja une candidature en cours en Salle d'examen avec ce courriel, la reponse s'y rattache.
-- Aucune invitation n'est emise par ce fichier : la file des courriels ne bouge pas (voir le suivi).
--
-- Rejouable : une ligne deja corrigee n'est plus reconnue (son courriel a change) ; le second passage
-- ne fait rien. Ce fichier ne contient aucun mot d'effacement ni de transaction.
--
-- Pour les scenarios, la liste d'empreintes peut etre remplacee dans la session par le reglage
-- rewayah.correction_adresses_md5 (empreintes separees par des virgules) ; non pose en production.

DO $correction$
DECLARE
  v_defaut constant text[] := ARRAY[
    '143a068f927899533466333e40cdb040',
    '4a50568e943c6a99fbe25dd2cffc0009',
    '5223b2baeec7201a29fe8eceb7189843',
    '530482fb2ac6ecaa14d1d130fe134678',
    '9f43d0d355e0603d34302312216e8c29',
    'a3a89afeffada4212b114a934983b853',
    'a7f79690015defeb4432f7d0d0d35377',
    'ad9484d2f39f4e31149301f4f60f7ebb',
    'c49c2efde145566e43128eb63b2a93b4',
    'd4d725a933b09f919791a669d63415cb',
    'db3425ae0330ed094c93dcbdc21164de',
    'ddc3aa2234fb2c281c3d054d145613cb',
    'e5bcf932fa3cb45663808d21f1e40a77',
    'fbaa5fc72162a0fc0a53963a22880f45',
    'fead3d6ff445def8e8dfd2c7ae001ae2'
  ];
  v_reglage text := nullif(pg_catalog.current_setting('rewayah.correction_adresses_md5', true), '');
  v_hash text[];
  r record;
  v_neuf text;
  v_corrigees integer := 0;
  v_ignorees integer := 0;
BEGIN v_hash := CASE WHEN v_reglage IS NULL THEN v_defaut
                 ELSE pg_catalog.string_to_array(pg_catalog.regexp_replace(v_reglage, '\s', '', 'g'), ',') END;
  FOR r IN
    SELECT f.id, f.courriel, f.courriel_brut, f.genre
      FROM public.formulaires_reponses f
     WHERE f.etat = 'active' AND f.candidature_id IS NULL AND f.courriel IS NOT NULL
       AND pg_catalog.md5(pg_catalog.lower(pg_catalog.btrim(f.courriel))) = ANY (v_hash)
     ORDER BY f.id
     FOR UPDATE
  LOOP
    -- La regle : le domaine devient gmail.com, la partie locale ne change pas.
    v_neuf := pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.btrim(r.courriel)), '@[^@]*$', '@gmail.com');
    IF v_neuf = r.courriel OR v_neuf !~ '^[^@\s]+@gmail\.com$' THEN
      v_ignorees := v_ignorees + 1;
      CONTINUE;
    END IF;
    IF EXISTS (SELECT 1 FROM public.formulaires_reponses x
                WHERE x.id <> r.id AND x.etat = 'active' AND x.candidature_id IS NULL
                  AND x.genre = r.genre AND x.courriel = v_neuf) THEN
      RAISE NOTICE 'ADRESSES-FAUTIVES : une autre reponse active porte deja l''adresse corrigee de la reponse %, ligne non corrigee', r.id;
      v_ignorees := v_ignorees + 1;
      CONTINUE;
    END IF;
    UPDATE public.formulaires_reponses
       SET courriel = v_neuf,
           modifie_le = pg_catalog.clock_timestamp()
     WHERE id = r.id;
    INSERT INTO public.formulaires_journal (reponse_id, type, auteur_id, details)
    VALUES (r.id, 'correction', NULL, pg_catalog.jsonb_build_object(
      'champs', pg_catalog.jsonb_build_array('courriel'),
      'motif', 'faute evidente dans le domaine de l''adresse',
      'courrielAvant', r.courriel,
      'domaineAvant', pg_catalog.substr(r.courriel, pg_catalog.strpos(r.courriel, '@') + 1),
      'domaineApres', 'gmail.com',
      'decision', 'directeur, 16/11/2026',
      'auteur', 'systeme'));
    PERFORM private.formulaires_rapprocher_reponse(r.id, NULL);
    v_corrigees := v_corrigees + 1;
  END LOOP;
  RAISE NOTICE 'ADRESSES-FAUTIVES : % reponses corrigees, % ignorees', v_corrigees, v_ignorees;
END;
$correction$;
