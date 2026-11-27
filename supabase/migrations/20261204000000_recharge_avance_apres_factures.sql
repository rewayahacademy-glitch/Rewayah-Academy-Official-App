-- RECHARGE-AVANCE-APRES-FACTURES (directeur, 27/11/2026, capture de Hallowx : « je ne comprends pas comment les
-- remises sont calculees »).
--
-- Defaut prouve en production : la facture de decembre est emise le 24/11 et reste a financer (elle est dans la
-- dette), mais les mois payes d'avance commencaient aussi en decembre (mois courant + 1). Payer « la dette et
-- 12 mois » faisait payer decembre deux fois (50,60 $ dans la dette, puis decembre 2026 a novembre 2027).
--
-- Correction : les mois d'avance commencent apres le dernier mois deja facture (facture non annulee), apres tout
-- engagement deja ouvert, et jamais avant le mois suivant. Rien d'autre ne change : memes offres, memes prix,
-- meme verification au paiement (`rch_ligne_valide` relit `rch_options`).
--
-- Aucune suppression.

CREATE OR REPLACE FUNCTION private.rch_options(p_profil uuid)
RETURNS TABLE (nb_mois integer, formule text, montant bigint, dette bigint, avance bigint,
               mois_debut date, avance_detail jsonb)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_m0 date := private.fac_mois_courant();
  v_etat text := private.rch_etat(p_profil);
  v_d bigint := (private.rch_dette(p_profil) ->> 'totalMineur')::bigint;
  v_debut date;
  v_fin_eng date;
  v_fin_fac date;
  v_a jsonb;
  n integer;
BEGIN
  IF v_d > 0 THEN
    RETURN QUERY SELECT 0, 'libre'::text, v_d, v_d, 0::bigint, NULL::date, NULL::jsonb;
  END IF;
  IF v_etat = 'en_classe' THEN
    -- Les mois payes d'avance commencent le mois suivant, apres tout engagement deja ouvert.
    SELECT max((e.mois_debut + pg_catalog.make_interval(months => e.nb_mois))::date) INTO v_fin_eng
      FROM public.engagements_prepaiement e WHERE e.profile_id = p_profil;
    -- Et apres le dernier mois deja facture : une facture emise est dans la dette, jamais payee deux fois.
    SELECT max((x.mois + interval '1 month')::date) INTO v_fin_fac
      FROM public.factures_mensuelles x WHERE x.profile_id = p_profil AND x.statut <> 'annulee';
    v_debut := greatest((v_m0 + interval '1 month')::date, coalesce(v_fin_eng, v_m0), coalesce(v_fin_fac, v_m0));
    FOR n IN 1..12 LOOP
      v_a := private.rch_prix_avance(p_profil, v_debut, n);
      EXIT WHEN v_a IS NULL;
      RETURN QUERY SELECT n, v_a ->> 'formule', v_d + (v_a ->> 'totalMineur')::bigint, v_d,
                          (v_a ->> 'totalMineur')::bigint, v_debut, v_a;
    END LOOP;
  ELSIF v_etat = 'avant_premier_mois' THEN
    -- Avant le premier mois reel : un mois seulement, sans engagement (le mois couvert n'est pas connu).
    v_a := private.rch_prix_avance(p_profil, v_m0, 1);
    IF v_a IS NOT NULL THEN
      RETURN QUERY SELECT 1, 'mois'::text, v_d + (v_a ->> 'totalMineur')::bigint, v_d,
                          (v_a ->> 'totalMineur')::bigint, NULL::date, (v_a - 'debut' - 'fin');
    END IF;
  END IF;
END;
$function$;
