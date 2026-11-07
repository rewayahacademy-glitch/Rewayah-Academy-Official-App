-- CADRE-MIGRATIONS, fichier 2 sur 2 (publication), 07/11/2026. Lot valide
-- par le garde-cap (plan des trois salles, salle 1), numero reserve au nom de
-- l'agent E. A installer APRES 20261118000000_cadre_contract_texts_schema.sql
-- (page collee), que le preflight exige, et APRES le deploiement de
-- l'application CADRE-ECRAN (ordre du pilote).
--
-- Publie le cadre religieux et pedagogique de l'enseignant
-- (teacher_religious_framework), version 2026-11-07, valide par le directeur
-- le 07/11/2026 : docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-ENSEIGNANT.md.
--
-- Le corps (body) de chaque langue est le texte du fichier valide, en TEXTE
-- BRUT comme teacher_nda (arbitrage du garde-cap du 07/11 : pas de Markdown
-- en base), produit par tool/cadre_texte_publie.py. Normalisation, sans
-- aucun mot change :
--   (1) dans un paragraphe, un retour a la ligne devient une espace ;
--   (2) le titre perd ses « ** » et forme le premier paragraphe ;
--   (3) chaque element de liste garde sa ligne, « - » devient « • » ;
--   (4) paragraphes separes par une ligne vide, sans espace final.
-- fr : 2055 octets, sha256 acf60aea…12a7 ;
-- ar : 2338 octets, sha256 2623d7ef…9845.
-- (Empreintes coupees en deux dans le code et abregees ici : la CI refuse
-- toute chaine de 64 caracteres hexadecimaux d'un seul tenant.)
-- La sha256 est calculee EN SQL depuis le corps
-- (encode(extensions.digest(convert_to(body, 'UTF8'), 'sha256'), 'hex')),
-- et comparee en postflight aux deux valeurs ci-dessus, recalculees a part
-- par le script : une difference d'un seul octet arrete la migration. Ces
-- valeurs sont aussi ecrites dans la section « Publication » du fichier
-- valide.
--
-- AUCUN mot d'effacement (compte : 0). Sans BEGIN ni COMMIT de premier
-- niveau. Rejouable : deja publie a l'identique, il ne change rien ; une
-- autre version deja requise, ou un autre texte sous la meme cle, l'arrete.
--
-- cadre_religieux_acceptable('2026-11-07') depend de la personne connectee
-- (une candidature d'enseignant en cours) : elle ne peut pas rendre vrai dans
-- une migration, ou personne n'est connecte. Le postflight verifie sa
-- condition de version (la version requise est 2026-11-07) ; le scenario
-- supabase/tests/scenarios_cadre_publication.sql verifie qu'elle rend vrai
-- pour un candidat.

DO $preflight$
DECLARE
  v_requise text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.contract_texts'::regclass
                    AND c.conname = 'contract_texts_contract_kind_check'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_religious_framework%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                     WHERE c.conrelid = 'public.contract_texts'::regclass
                       AND c.conname = 'contract_texts_locale_check'
                       AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''ar''%') THEN
    RAISE EXCEPTION 'CADRE : 20261118000000_cadre_contract_texts_schema.sql n''est pas installe (page a coller d''abord), arret';
  END IF;
  SELECT r.version INTO v_requise FROM public.contract_required_versions r
   WHERE r.contract_kind = 'teacher_religious_framework';
  IF v_requise IS NOT NULL AND v_requise <> '2026-11-07' THEN
    RAISE EXCEPTION 'CADRE : une autre version du cadre religieux est deja requise (%), arret', v_requise;
  END IF;
  IF EXISTS (SELECT 1 FROM public.contract_texts t
              WHERE t.contract_kind = 'teacher_religious_framework'
                AND t.is_current AND t.version <> '2026-11-07') THEN
    RAISE EXCEPTION 'CADRE : une autre version du cadre religieux est deja en vigueur, arret';
  END IF;
END;
$preflight$;

INSERT INTO public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
SELECT v.kind, v.version, v.locale, v.body,
       pg_catalog.encode(extensions.digest(pg_catalog.convert_to(v.body, 'UTF8'), 'sha256'), 'hex'),
       true
  FROM (VALUES
    ('teacher_religious_framework', '2026-11-07', 'fr', $cadre_fr$Engagement religieux, pédagogique et professionnel de l'enseignant

Rewayah Academy est une institution d'enseignement du Coran et des valeurs de l'islam. Elle enseigne le Coran et la Sunna du Prophète Muhammad ﷺ, selon la compréhension de ses Compagnons, qu'Allah les agrée, et des pieux prédécesseurs (as-salaf as-sâlih) qui les ont suivis dans le bien : c'est la voie d'Ahl as-Sunna.

L'académie et chacun de ses enseignants respectent et honorent :

• le Coran et la Sunna authentique du Prophète ﷺ ;
• tous les Compagnons du Prophète ﷺ, et en premier lieu les quatre califes bien guidés : Abou Bakr as-Siddîq, Omar ibn al-Khattâb, Othman ibn Affân et Ali ibn Abî Tâlib, qu'Allah les agrée ;
• les pieux prédécesseurs (as-salaf as-sâlih) et leur compréhension de la religion.

En poursuivant ma candidature, je confirme adhérer à ce cadre. Je m'engage à le respecter dans mes enseignements, mes paroles, mes communications et mon comportement, pendant les cours et dans toute activité menée au nom de Rewayah Academy, et à ne tenir aucun propos qui dénigre l'un des Compagnons du Prophète ﷺ.

Je confirme que les informations et déclarations fournies dans le cadre de ma candidature sont sincères et exactes. Je comprends que toute fausse déclaration substantielle, tout manquement grave à mes engagements ou tout comportement incompatible avec ce cadre ou avec les obligations pédagogiques et professionnelles de l'académie peut entraîner le refus de ma candidature, la suspension de ma participation ou la fin de ma collaboration, selon la situation et les règles applicables.

Rewayah Academy se réserve le droit de prendre toute mesure appropriée, y compris d'engager les démarches légales permises par la législation applicable, lorsque des faits vérifiables le justifient, dans le respect des droits de chaque partie.

Je confirme avoir compris ces exigences et j'accepte qu'elles constituent une condition de ma candidature et, le cas échéant, de ma collaboration avec Rewayah Academy.$cadre_fr$),
    ('teacher_religious_framework', '2026-11-07', 'ar', $cadre_ar$التزام المعلّم الديني والتربوي والمهني

أكاديمية رواية مؤسسة لتعليم القرآن الكريم وقيم الإسلام. وهي تعلّم القرآن وسنة النبي محمد ﷺ على فهم أصحابه رضي الله عنهم، والسلف الصالح الذين اتبعوهم بإحسان: وهذا هو منهج أهل السنة.

وتلتزم الأكاديمية وكل معلّم من معلّميها باحترام وتوقير:

• القرآن الكريم والسنة الصحيحة للنبي ﷺ؛
• جميع أصحاب النبي ﷺ، وفي مقدمتهم الخلفاء الراشدون الأربعة: أبو بكر الصديق، وعمر بن الخطاب، وعثمان بن عفان، وعلي بن أبي طالب، رضي الله عنهم؛
• السلف الصالح وفهمهم للدين.

بمواصلتي لترشّحي، أؤكد التزامي بهذا الإطار. وأتعهّد باحترامه في تعليمي وكلامي وتواصلي وسلوكي، أثناء الدروس وفي كل نشاط أقوم به باسم أكاديمية رواية، وألا أتفوّه بأي كلام فيه انتقاص لأحد من أصحاب النبي ﷺ.

وأؤكد أن المعلومات والإقرارات التي قدّمتها في إطار ترشّحي صادقة وصحيحة. وأدرك أن أي تصريح كاذب جوهري، أو أي إخلال جسيم بالتزاماتي، أو أي سلوك يتعارض مع هذا الإطار أو مع الواجبات التربوية والمهنية للأكاديمية، قد يؤدي إلى رفض ترشّحي أو تعليق مشاركتي أو إنهاء تعاوني، بحسب الحالة والقواعد المعمول بها.

وتحتفظ أكاديمية رواية بحقها في اتخاذ أي إجراء مناسب، بما في ذلك الشروع في الإجراءات القانونية التي يسمح بها القانون المعمول به، متى بررت ذلك وقائع يمكن التحقق منها، مع احترام حقوق كل طرف.

وأؤكد أنني فهمت هذه المتطلبات، وأقبل أن تكون شرطًا لترشّحي، ولتعاوني مع أكاديمية رواية عند الاقتضاء.$cadre_ar$)
  ) AS v(kind, version, locale, body)
ON CONFLICT (contract_kind, version, locale) DO NOTHING;

INSERT INTO public.contract_required_versions (contract_kind, version, changed_at)
VALUES ('teacher_religious_framework', '2026-11-07', pg_catalog.now())
ON CONFLICT (contract_kind) DO NOTHING;

DO $postflight$
DECLARE
  v_fr text;
  v_ar text;
BEGIN
  SELECT t.sha256 INTO v_fr FROM public.contract_texts t
   WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
     AND t.locale = 'fr' AND t.is_current;
  SELECT t.sha256 INTO v_ar FROM public.contract_texts t
   WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
     AND t.locale = 'ar' AND t.is_current;
  IF v_fr IS DISTINCT FROM ('acf60aea3a0fe1f12348ffa6fc20a19f' || '63eb28e117340eb82713cc8c521312a7') THEN
    RAISE EXCEPTION 'CADRE : le texte francais publie n''est pas celui du fichier valide (sha256 %)', v_fr;
  END IF;
  IF v_ar IS DISTINCT FROM ('2623d7ef94165c86771c6aa9ba3dac13' || 'df0c1c763d2be1ac06f420d805009845') THEN
    RAISE EXCEPTION 'CADRE : le texte arabe publie n''est pas celui du fichier valide (sha256 %)', v_ar;
  END IF;
  IF (SELECT r.version FROM public.contract_required_versions r
       WHERE r.contract_kind = 'teacher_religious_framework') IS DISTINCT FROM '2026-11-07' THEN
    RAISE EXCEPTION 'CADRE : version requise du cadre religieux absente ou differente';
  END IF;
END;
$postflight$;
