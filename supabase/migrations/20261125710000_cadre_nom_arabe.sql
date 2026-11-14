-- NOM-ARABE (directeur, 14/11/2026) : dans le texte arabe du cadre religieux et
-- pedagogique de l'enseignant (teacher_religious_framework, version 2026-11-07,
-- locale ar), le nom de l'academie est ecrit « أكاديمية رواية » (4 fois) : c'est
-- faux. Le nom est « أكاديمية الرواية » (registre de marque, M-27 du 20/10/2026).
-- Ce fichier publie le texte arabe corrige ; aucun autre mot ne change.
--
-- Mecanisme suivi, et pourquoi la ligne est corrigee sur place :
--   * contract_texts est unique par (contract_kind, version, locale) et n'a
--     qu'une ligne en vigueur (is_current) par (contract_kind, locale) ;
--   * une acceptation du cadre (contract_acceptances) porte (profile_id,
--     contract_kind, version), SANS empreinte ni langue ; la policy
--     contract_acceptances_cadre_religieux_candidat et envoyer_reponses
--     n'exigent que version = contract_required_versions ('2026-11-07') ;
--   * l'ecran (lib/core/candidature/texte_cadre.dart) ne montre le texte que si
--     sa version est la version requise.
--   Une nouvelle version obligerait chaque candidat deja engage a se reengager
--   (et casserait l'ecran tant que la version requise ne suit pas). On garde
--   donc la version 2026-11-07 et on corrige la ligne ar en place, corps et
--   sha256 ensemble, comme 20261011072525 l'a fait pour teacher_nda : la
--   contrainte contract_texts_check (sha256 = empreinte du corps) reste vraie,
--   is_current reste vrai, les acceptations deja signees restent valides. Le
--   francais (le texte qui fait foi), l'anglais, l'espagnol et le portugais ne
--   sont pas touches.
--
-- Empreintes, recalculees a part par tool/cadre_texte_publie.py ar depuis
-- docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-ENSEIGNANT.md corrige :
--   avant : 2338 octets, md5 9a08209e4c75c05a901e0efb706997c3, sha256 2623d7ef94165c86… ;
--   apres : 2354 octets, md5 701eea01c392fc802329942cb20d42e5, sha256 b0bb7668e35135c3….
-- Aucune empreinte entiere ici : la CI refuse toute chaine de 64 signes
-- hexadecimaux sous supabase/migrations (garde anti-secret R2) ; 16 signes et le
-- md5 suffisent a reconnaitre ces textes-la.
--
-- Aucun mot d'effacement (compte : 0), aucune transaction de premier niveau
-- ecrite a la main (le fichier est transactionnel a l'application). Rejouable :
-- deja corrige, il ne change rien et le postflight le verifie.

DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  SELECT pg_catalog.md5(t.body) INTO v_md5 FROM public.contract_texts t
   WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
     AND t.locale = 'ar' AND t.is_current;
  IF v_md5 IS NULL THEN
    RAISE EXCEPTION 'NOM-ARABE : aucun cadre arabe 2026-11-07 en vigueur (20261118000100 non installe ?), arret';
  END IF;
  IF v_md5 NOT IN ('9a08209e4c75c05a901e0efb706997c3', '701eea01c392fc802329942cb20d42e5') THEN
    RAISE EXCEPTION 'NOM-ARABE : le cadre arabe en vigueur n''est ni le texte publie le 07/11 ni le texte corrige (md5 %), arret', v_md5;
  END IF;
  IF (SELECT r.version FROM public.contract_required_versions r
       WHERE r.contract_kind = 'teacher_religious_framework') IS DISTINCT FROM '2026-11-07' THEN
    RAISE EXCEPTION 'NOM-ARABE : la version requise du cadre religieux n''est pas 2026-11-07, arret';
  END IF;
END;
$preflight$;

UPDATE public.contract_texts t
   SET body = pg_catalog.replace(t.body, 'أكاديمية رواية', 'أكاديمية الرواية'),
       sha256 = pg_catalog.encode(extensions.digest(pg_catalog.convert_to(
                  pg_catalog.replace(t.body, 'أكاديمية رواية', 'أكاديمية الرواية'), 'UTF8'), 'sha256'), 'hex')
 WHERE t.contract_kind = 'teacher_religious_framework'
   AND t.version = '2026-11-07'
   AND t.locale = 'ar'
   AND t.is_current
   AND pg_catalog.md5(t.body) = '9a08209e4c75c05a901e0efb706997c3';

DO $postflight$
DECLARE
  v_ar text;
BEGIN
  SELECT pg_catalog.md5(t.body) INTO v_ar FROM public.contract_texts t
   WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
     AND t.locale = 'ar' AND t.is_current;
  IF v_ar IS DISTINCT FROM '701eea01c392fc802329942cb20d42e5' THEN
    RAISE EXCEPTION 'NOM-ARABE : le cadre arabe en vigueur n''est pas le texte corrige (md5 %), arret', v_ar;
  END IF;
  IF EXISTS (SELECT 1 FROM public.contract_texts t
              WHERE t.contract_kind = 'teacher_religious_framework'
                AND (t.body LIKE '%أكاديمية رواية%'
                     OR t.sha256 <> pg_catalog.encode(extensions.digest(
                          pg_catalog.convert_to(t.body, 'UTF8'), 'sha256'), 'hex'))) THEN
    RAISE EXCEPTION 'NOM-ARABE : un texte du cadre porte encore l''ancien nom ou une empreinte fausse, arret';
  END IF;
  IF pg_catalog.left((SELECT t.sha256 FROM public.contract_texts t
       WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
         AND t.locale = 'ar' AND t.is_current), 16) IS DISTINCT FROM 'b0bb7668e35135c3' THEN
    RAISE EXCEPTION 'NOM-ARABE : empreinte du cadre arabe inattendue, arret';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.contract_texts t
       WHERE t.contract_kind = 'teacher_religious_framework' AND t.is_current) <> 5 THEN
    RAISE EXCEPTION 'NOM-ARABE : il faut exactement cinq langues du cadre en vigueur, arret';
  END IF;
END;
$postflight$;
