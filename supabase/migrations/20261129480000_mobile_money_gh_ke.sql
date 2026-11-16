-- MOBILE-MONEY-GH-KE (pilote, 16/11/2026) : le referentiel des moyens de versement gagne la monnaie mobile du
-- Ghana et du Kenya, sur les pages publiques de wise.com lues le 16/11/2026 (envoi en GHS vers ces
-- portefeuilles ; KES vers M-Pesa), meme decision que le virement bancaire de ces deux pays (20261128600100).
--
--   Ghana : MTN MoMo (mtn_momo), AirtelTigo (airteltigo), Telecel (telecel) ;
--   Kenya : M-Pesa (m_pesa).
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Sans BEGIN/COMMIT de premier niveau.
-- Additif : quatre operateurs au catalogue ferme (referentiel_paiement_operateurs), quatre lignes confirmees
-- (source decision_directeur, verifie_le 16/11/2026), rien n'est retire ni modifie.
--
-- Le recalcul des candidatures du Ghana et du Kenya passe par le chemin de BE-VERSEMENT
-- (20261128200100) : le declencheur du referentiel (private.paiement_ligne_effets) ramenerait a
-- `a_completer` TOUTE candidature du pays en paiement_non_disponible quand une ligne passe confirme (conception
-- de CAND-L6, L6-9), meme si son propre moyen ne croise toujours pas : elle recevrait l'avis « paiement
-- possible » a tort. Ici le declencheur est donc suspendu le temps des quatre insertions, dans la seule
-- transaction de ce fichier (un echec le rend a l'etat d'avant, et l'ordre ALTER est annule avec elle), et le
-- fichier fait lui-meme ce que le declencheur fait, avec le drapeau de la transition 9 passe SEULEMENT pour un
-- dossier paiement_non_disponible dont le calcul est desormais `compatible` : journal du referentiel, audit,
-- compteurs. Un second passage ne change rien (les lignes existent, rien n'est recalcule).

DO $preflight$
BEGIN
  IF NOT private.paiement_afrique_ouverte() THEN
    RAISE EXCEPTION 'MOBILE-MONEY-GH-KE : l''Afrique n''est pas ouverte (decision du 06/11 absente)';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.referentiel_paiement l
       WHERE l.pays IN ('GH', 'KE') AND l.methode = 'virement_bancaire' AND l.operateur IS NULL
         AND l.etat = 'confirme') <> 2 THEN
    RAISE EXCEPTION 'MOBILE-MONEY-GH-KE : le virement bancaire du Ghana et du Kenya doit etre confirme (PAYS-DECISIONS)';
  END IF;
  IF (SELECT l.tgenabled FROM pg_catalog.pg_trigger l
       WHERE l.tgrelid = 'public.referentiel_paiement'::regclass AND l.tgname = 'referentiel_paiement_effets') <> 'O' THEN
    RAISE EXCEPTION 'MOBILE-MONEY-GH-KE : le declencheur referentiel_paiement_effets n''est pas actif a l''entree';
  END IF;
END
$preflight$;

-- ============================================================
-- 1. Le catalogue ferme des operateurs
-- ============================================================
INSERT INTO public.referentiel_paiement_operateurs (code, methode, nom, actif)
VALUES ('mtn_momo', 'mobile_money', 'MTN MoMo', true),
       ('airteltigo', 'mobile_money', 'AirtelTigo', true),
       ('telecel', 'mobile_money', 'Telecel', true),
       ('m_pesa', 'mobile_money', 'M-Pesa', true)
ON CONFLICT (code, methode) DO NOTHING;

-- ============================================================
-- 2. Les quatre lignes, et le recalcul par le chemin de BE-VERSEMENT
-- ============================================================
DO $lignes$
DECLARE
  v_def record;
  v_ligne public.referentiel_paiement;
  v_c record;
  v_pays record;
  v_res jsonb;
  v_resultats jsonb;
  v_par_pays jsonb := '{}'::jsonb;
  v_premiere jsonb := '{}'::jsonb;
  v_nouvelles uuid[] := ARRAY[]::uuid[];
  v_ramene boolean;
  v_examinees integer := 0;
  v_ramenees integer := 0;
BEGIN
  ALTER TABLE public.referentiel_paiement DISABLE TRIGGER referentiel_paiement_effets;

  -- Phase 1 : les quatre lignes, toutes avant le moindre recalcul (aucun etat intermediaire).
  FOR v_def IN
    SELECT * FROM (VALUES
      ('GH', 'mtn_momo', 'GHS', 'MTN MoMo'),
      ('GH', 'airteltigo', 'GHS', 'AirtelTigo'),
      ('GH', 'telecel', 'GHS', 'Telecel'),
      ('KE', 'm_pesa', 'KES', 'M-Pesa')) AS x(pays, operateur, devise, nom)
  LOOP
    IF EXISTS (SELECT 1 FROM public.referentiel_paiement l
                WHERE l.pays = v_def.pays AND l.methode = 'mobile_money' AND l.operateur = v_def.operateur) THEN
      CONTINUE;
    END IF;
    INSERT INTO public.referentiel_paiement
      (pays, methode, operateur, prestataire, devise, type_decaissement, etat, source, source_ref, verifie_le, notes)
    VALUES (v_def.pays, 'mobile_money', v_def.operateur, 'wise', v_def.devise, 'payout_portefeuille',
            'confirme', 'decision_directeur',
            'pages publiques wise.com lues le 16/11/2026 (envoi en GHS vers ces portefeuilles ; KES vers M-Pesa)',
            DATE '2026-11-16',
            'Décision du directeur du 16/11/2026 : l''envoi vers ' || v_def.nom || ' est possible (pages publiques de wise.com lues le 16/11/2026 : envoi en '
              || v_def.devise || ' vers ce portefeuille).')
    RETURNING * INTO v_ligne;
    v_nouvelles := v_nouvelles || v_ligne.id;
    IF NOT v_premiere ? v_ligne.pays THEN
      v_premiere := v_premiere || pg_catalog.jsonb_build_object(v_ligne.pays, v_ligne.id);
    END IF;
  END LOOP;

  -- Phase 2 : chaque candidature du pays est recalculee UNE fois, comme BE-VERSEMENT : le drapeau de la
  -- transition 9 n'est passe que pour un dossier paiement_non_disponible devenu compatible.
  FOR v_pays IN SELECT k AS pays FROM pg_catalog.jsonb_object_keys(v_premiere) AS k ORDER BY 1 LOOP
    v_resultats := '[]'::jsonb;
    FOR v_c IN
      SELECT c.id, c.genre, c.etat FROM public.candidatures c
       WHERE c.issue = 'en_cours' AND c.profile_id IS NOT NULL
         AND c.etape IN ('prequalification', 'verifications', 'confirmee')
         AND private.paiement_declaration(c.id) ->> 'paysVersement' = v_pays.pays
       ORDER BY c.id
    LOOP
      v_ramene := v_c.etat = 'paiement_non_disponible' AND private.paiement_etat(v_c.id) = 'compatible';
      v_res := private.paiement_recalculer(v_c.id, 'referentiel', NULL, NULL,
                                           (v_premiere ->> v_pays.pays)::uuid, v_ramene);
      v_examinees := v_examinees + 1;
      IF v_res ->> 'effet' = 'a_completer' THEN
        v_ramenees := v_ramenees + 1;
      END IF;
      v_resultats := v_resultats || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'genre', v_c.genre::text, 'effet', v_res ->> 'effet'));
    END LOOP;
    v_par_pays := v_par_pays || pg_catalog.jsonb_build_object(v_pays.pays, v_resultats);
  END LOOP;

  -- Phase 3 : ce que fait le declencheur, ligne par ligne : le journal du referentiel et l'audit.
  FOR v_ligne IN
    SELECT l.* FROM public.referentiel_paiement l WHERE l.id = ANY (v_nouvelles) ORDER BY l.pays, l.operateur
  LOOP
    v_resultats := coalesce(v_par_pays -> v_ligne.pays, '[]'::jsonb);
    INSERT INTO public.referentiel_paiement_journal
      (ligne_id, avant, apres, auteur_id, cle_idempotence, empreinte, impact)
    VALUES (v_ligne.id, NULL, pg_catalog.to_jsonb(v_ligne), NULL, NULL, NULL,
            private.paiement_compteurs(v_resultats, NULL)
            || pg_catalog.jsonb_build_object('parGenre', pg_catalog.jsonb_build_object(
                 'female', private.paiement_compteurs(v_resultats, 'female'),
                 'male', private.paiement_compteurs(v_resultats, 'male'))));
    PERFORM public.log_sensitive_access('referentiel_paiement_ecriture', 'referentiel_paiement',
      v_ligne.id::text, pg_catalog.jsonb_build_object(
        'pays', v_ligne.pays, 'methode', v_ligne.methode, 'operateur', v_ligne.operateur,
        'etatAvant', NULL, 'etatApres', v_ligne.etat, 'voie', 'directe'));
  END LOOP;

  ALTER TABLE public.referentiel_paiement ENABLE TRIGGER referentiel_paiement_effets;
  RAISE NOTICE 'MOBILE-MONEY-GH-KE : % lignes ecrites, % candidatures examinees, % ramenees a a_completer',
    pg_catalog.cardinality(v_nouvelles), v_examinees, v_ramenees;
END;
$lignes$;

-- ============================================================
-- 3. Postflight
-- ============================================================
DO $postflight$
BEGIN
  IF (SELECT l.tgenabled FROM pg_catalog.pg_trigger l
       WHERE l.tgrelid = 'public.referentiel_paiement'::regclass AND l.tgname = 'referentiel_paiement_effets') <> 'O' THEN
    RAISE EXCEPTION 'MOBILE-MONEY-GH-KE : le declencheur referentiel_paiement_effets n''a pas ete remis en service';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.referentiel_paiement l
       WHERE l.methode = 'mobile_money' AND l.etat = 'confirme' AND l.source = 'decision_directeur'
         AND l.verifie_le = DATE '2026-11-16'
         AND ((l.pays = 'GH' AND l.operateur IN ('mtn_momo', 'airteltigo', 'telecel'))
              OR (l.pays = 'KE' AND l.operateur = 'm_pesa'))) <> 4 THEN
    RAISE EXCEPTION 'MOBILE-MONEY-GH-KE : les quatre lignes confirmees ne sont pas toutes la';
  END IF;
END
$postflight$;
