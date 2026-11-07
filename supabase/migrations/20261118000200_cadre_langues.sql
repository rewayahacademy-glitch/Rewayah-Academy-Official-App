-- CADRE-LANGUES (07/11/2026), numero reserve 20261118000200 au nom de l'agent H.
-- Le cadre religieux et pedagogique de l'enseignant (teacher_religious_framework,
-- version 2026-11-07) publie aussi en anglais, en espagnol et en portugais, les
-- langues de l'application et du site public (decision K-41), sur ordre du
-- directeur du 07/11/2026. Source unique :
-- docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-TRADUCTIONS.md (sha256 du fichier
-- 43a5291d91b0dbdde8138de5bae97b2f12f5034e2cef8ad25d54feee7207c5de) ;
-- le texte de chaque langue est celui de sa section, SANS le statut ni les
-- corrections du relecteur, normalise par tool/cadre_texte_publie.py (en|es|pt)
-- exactement comme le francais et l'arabe : aucun mot change. Normalisation :
--   (1) dans un paragraphe, un retour a la ligne devient une espace ;
--   (2) le titre perd ses « ** » et forme le premier paragraphe ;
--   (3) chaque element de liste garde sa ligne, « - » devient « • » ;
--   (4) paragraphes separes par une ligne vide, sans espace final.
-- en : 2010 octets, md5 77f001ec3be51f363ada03dc5afc8df3, sha256 498431db51501cce5222acb57f8ed1384f93ffdc4b140df75dfe224f31c69367.
-- es : 2018 octets, md5 af45760a0e8bea02797fbaf24ee96b16, sha256 65b5159a09d95943ea0f1c48f0b06b838e1a0725d1acf92bf6090475b5d22908.
-- pt : 2077 octets, md5 904a94c477f10d6fd0dc05628145b792, sha256 b4efa26440b91631c7bda9421fc993a7e534b4dcfa66f89116e6b1908d94f4f7.
-- (fr et ar ne changent pas : fr md5 57f6f3ba3d7095c4672cb9ac60b6269a, ar md5 9a08209e4c75c05a901e0efb706997c3.)
-- La sha256 de chaque ligne est calculee EN SQL depuis le corps ; la contrainte
-- contract_texts_check garantit qu'elle est bien celle du corps.
--
-- A INSTALLER APRES 20261118000000 (schema) et 20261118000100 (publication), que
-- le preflight exige. contract_required_versions ne change pas.
--
-- Ce fichier remplace contract_texts_locale_check par la meme regle, plus large
-- (fr, ar, en, es, pt) : il contient donc UN mot d'effacement, celui de la
-- suppression de l'ancienne regle (compte : 1 ; aucune ligne n'est effacee).
-- FICHIER A MOT D'EFFACEMENT : PAGE COLLEE PAR LE DIRECTEUR, jamais apply_migration.
-- Sans BEGIN ni COMMIT de premier niveau. Rejouable : deja applique, il remet la
-- meme regle, ne change aucune ligne et le postflight le verifie.
--
-- LECTURE PREALABLE de la contrainte en place (le preflight la refait) :
--   SELECT pg_catalog.pg_get_constraintdef(oid) FROM pg_catalog.pg_constraint
--    WHERE conrelid = 'public.contract_texts'::regclass
--      AND conname = 'contract_texts_locale_check';
--   -- attendu apres 20261118000000 : CHECK ((locale = ANY (ARRAY['fr'::text, 'ar'::text])))
-- Le preflight lit les langues citees dans la definition, sous quelque forme que
-- ce soit (ARRAY[...] ou '{...}'::text[]) ; il n'accepte que {fr, ar} (a elargir) ou
-- {fr, ar, en, es, pt} (deja elargi), refuse toute autre, et refuse s'il existe
-- deja une ligne d'une autre langue. Le postflight compare le md5 de chaque corps
-- publie aux valeurs ci-dessus, recalculees a part par le script.

DO $preflight$
DECLARE
  v_def text;
  v_langues text[];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.contract_texts'::regclass
                    AND c.conname = 'contract_texts_contract_kind_check'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_religious_framework%') THEN
    RAISE EXCEPTION 'CADRE-LANGUES : 20261118000000 n''est pas installe (schema), arret';
  END IF;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.contract_texts'::regclass AND c.conname = 'contract_texts_locale_check';
  IF v_def IS NULL OR v_def NOT LIKE 'CHECK ((locale %' THEN
    RAISE EXCEPTION 'CADRE-LANGUES : contract_texts_locale_check absente ou inattendue (%), arret', v_def;
  END IF;
  SELECT pg_catalog.array_agg(m[1] ORDER BY m[1]) INTO v_langues
    FROM pg_catalog.regexp_matches(v_def, '\m([a-z]{2})\M', 'g') AS m;
  IF v_langues IS DISTINCT FROM ARRAY['ar', 'fr']
     AND v_langues IS DISTINCT FROM ARRAY['ar', 'en', 'es', 'fr', 'pt'] THEN
    RAISE EXCEPTION 'CADRE-LANGUES : langues de contract_texts_locale_check inattendues (% dans %), arret', v_langues, v_def;
  END IF;
  IF EXISTS (SELECT 1 FROM public.contract_texts t WHERE t.locale NOT IN ('fr', 'ar', 'en', 'es', 'pt')) THEN
    RAISE EXCEPTION 'CADRE-LANGUES : une ligne de contract_texts a une langue hors fr, ar, en, es, pt, arret';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.contract_texts t
       WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
         AND t.locale IN ('fr', 'ar') AND t.is_current) <> 2 THEN
    RAISE EXCEPTION 'CADRE-LANGUES : 20261118000100 n''est pas installe (cadre fr et ar), arret';
  END IF;
  IF (SELECT r.version FROM public.contract_required_versions r
       WHERE r.contract_kind = 'teacher_religious_framework') IS DISTINCT FROM '2026-11-07' THEN
    RAISE EXCEPTION 'CADRE-LANGUES : la version requise du cadre religieux n''est pas 2026-11-07, arret';
  END IF;
  IF EXISTS (SELECT 1 FROM public.contract_texts t
              WHERE t.contract_kind = 'teacher_religious_framework'
                AND t.is_current AND t.version <> '2026-11-07') THEN
    RAISE EXCEPTION 'CADRE-LANGUES : une autre version du cadre religieux est deja en vigueur, arret';
  END IF;
END;
$preflight$;

ALTER TABLE public.contract_texts DROP CONSTRAINT IF EXISTS contract_texts_locale_check;
ALTER TABLE public.contract_texts ADD CONSTRAINT contract_texts_locale_check
  CHECK (locale IN ('fr', 'ar', 'en', 'es', 'pt'));

INSERT INTO public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
SELECT v.kind, v.version, v.locale, v.body,
       pg_catalog.encode(extensions.digest(pg_catalog.convert_to(v.body, 'UTF8'), 'sha256'), 'hex'),
       true
  FROM (VALUES
    ('teacher_religious_framework', '2026-11-07', 'en', $cadre_en$Teacher's religious, educational and professional commitment

Rewayah Academy is an institution for teaching the Quran and the values of Islam. It teaches the Quran and the Sunnah of the Prophet Muhammad ﷺ according to the understanding of his Companions, may Allah be pleased with them, and of the righteous predecessors (as-salaf as-salih) who followed them in goodness: this is the way of Ahl as-Sunnah.

The academy and each of its teachers respect and honour:

• the Quran and the authentic Sunnah of the Prophet ﷺ;
• all the Companions of the Prophet ﷺ, and first among them the four rightly guided caliphs: Abu Bakr as-Siddiq, Umar ibn al-Khattab, Uthman ibn Affan and Ali ibn Abi Talib, may Allah be pleased with them;
• the righteous predecessors (as-salaf as-salih) and their understanding of the religion.

By continuing my application, I confirm that I adhere to this framework. I commit to respecting it in my teaching, my words, my communications and my conduct, during lessons and in any activity carried out on behalf of Rewayah Academy, and to making no remark that disparages any of the Companions of the Prophet ﷺ.

I confirm that the information and statements I have provided as part of my application are sincere and accurate. I understand that any significant false statement, any serious breach of my commitments, or any conduct incompatible with this framework or with the academy's educational and professional obligations may lead to the rejection of my application, the suspension of my participation or the end of my collaboration, depending on the situation and the applicable rules.

Rewayah Academy reserves the right to take any appropriate action, including legal action as permitted by applicable law, where verifiable facts justify it, while respecting the rights of each party.

I confirm that I have understood these requirements and I accept that they constitute a condition of my application and, where applicable, of my collaboration with Rewayah Academy.$cadre_en$),
    ('teacher_religious_framework', '2026-11-07', 'es', $cadre_es$Compromiso religioso, pedagógico y profesional del docente

Rewayah Academy es una institución de enseñanza del Corán y de los valores del islam. Enseña el Corán y la Sunna del Profeta Muhammad ﷺ según la comprensión de sus Compañeros, que Allah esté complacido con ellos, y de los piadosos predecesores (as-salaf as-salih) que los siguieron en el bien: este es el camino de Ahl as-Sunna.

La academia y cada uno de sus docentes respetan y honran:

• el Corán y la Sunna auténtica del Profeta ﷺ;
• a todos los Compañeros del Profeta ﷺ, y en primer lugar a los cuatro califas bien guiados: Abu Bakr as-Siddiq, Umar ibn al-Jattab, Uthman ibn Affan y Ali ibn Abi Talib, que Allah esté complacido con ellos;
• a los piadosos predecesores (as-salaf as-salih) y su comprensión de la religión.

Al continuar mi candidatura, confirmo que me adhiero a este marco. Me comprometo a respetarlo en mi enseñanza, mis palabras, mis comunicaciones y mi conducta, durante las clases y en toda actividad realizada en nombre de Rewayah Academy, y a no hacer ningún comentario que menosprecie a ninguno de los Compañeros del Profeta ﷺ.

Confirmo que la información y las declaraciones aportadas en mi candidatura son sinceras y exactas. Entiendo que toda declaración falsa sustancial, todo incumplimiento grave de mis compromisos o toda conducta incompatible con este marco o con las obligaciones pedagógicas y profesionales de la academia puede conllevar el rechazo de mi candidatura, la suspensión de mi participación o el fin de mi colaboración, según la situación y las normas aplicables.

Rewayah Academy se reserva el derecho de adoptar cualquier medida apropiada, incluido el inicio de las acciones legales permitidas por la legislación aplicable, cuando hechos verificables lo justifiquen, respetando los derechos de cada parte.

Confirmo que he comprendido estas exigencias y acepto que constituyen una condición de mi candidatura y, en su caso, de mi colaboración con Rewayah Academy.$cadre_es$),
    ('teacher_religious_framework', '2026-11-07', 'pt', $cadre_pt$Compromisso religioso, pedagógico e profissional do professor

A Rewayah Academy é uma instituição de ensino do Alcorão e dos valores do Islam. Ensina o Alcorão e a Sunna do Profeta Muhammad ﷺ segundo a compreensão dos seus Companheiros, que Allah esteja satisfeito com eles, e dos piedosos predecessores (as-salaf as-salih) que os seguiram no bem: este é o caminho de Ahl as-Sunna.

A academia e cada um dos seus professores respeitam e honram:

• o Alcorão e a Sunna autêntica do Profeta ﷺ;
• todos os Companheiros do Profeta ﷺ e, em primeiro lugar, os quatro califas bem guiados: Abu Bakr as-Siddiq, Umar ibn al-Khattab, Uthman ibn Affan e Ali ibn Abi Talib, que Allah esteja satisfeito com eles;
• os piedosos predecessores (as-salaf as-salih) e a sua compreensão da religião.

Ao prosseguir com a minha candidatura, confirmo que adiro a este quadro de referência. Comprometo-me a respeitá-lo no meu ensino, nas minhas palavras, nas minhas comunicações e na minha conduta, durante as aulas e em qualquer atividade realizada em nome da Rewayah Academy, e a não fazer nenhum comentário que menospreze qualquer um dos Companheiros do Profeta ﷺ.

Confirmo que as informações e declarações fornecidas na minha candidatura são sinceras e exatas. Compreendo que qualquer declaração falsa substancial, qualquer falta grave aos meus compromissos ou qualquer conduta incompatível com este quadro de referência ou com as obrigações pedagógicas e profissionais da academia pode levar à recusa da minha candidatura, à suspensão da minha participação ou ao fim da minha colaboração, conforme a situação e as regras aplicáveis.

A Rewayah Academy reserva-se o direito de tomar qualquer medida adequada, incluindo iniciar os procedimentos legais permitidos pela legislação aplicável, quando factos verificáveis o justifiquem, respeitando os direitos de cada parte.

Confirmo que compreendi estas exigências e aceito que constituem uma condição da minha candidatura e, se for o caso, da minha colaboração com a Rewayah Academy.$cadre_pt$)
  ) AS v(kind, version, locale, body)
ON CONFLICT (contract_kind, version, locale) DO NOTHING;

DO $postflight$
DECLARE
  v_attendu constant jsonb := '{"fr": "57f6f3ba3d7095c4672cb9ac60b6269a", "ar": "9a08209e4c75c05a901e0efb706997c3", "en": "77f001ec3be51f363ada03dc5afc8df3", "es": "af45760a0e8bea02797fbaf24ee96b16", "pt": "904a94c477f10d6fd0dc05628145b792"}';
  l text;
  v_md5 text;
BEGIN
  FOREACH l IN ARRAY ARRAY['fr', 'ar', 'en', 'es', 'pt'] LOOP
    SELECT pg_catalog.md5(t.body) INTO v_md5 FROM public.contract_texts t
     WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
       AND t.locale = l AND t.is_current;
    IF v_md5 IS DISTINCT FROM v_attendu ->> l THEN
      RAISE EXCEPTION 'CADRE-LANGUES : le texte % publie n''est pas celui du fichier valide (md5 %)', l, v_md5;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.contract_texts'::regclass
                    AND c.conname = 'contract_texts_locale_check'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''en''%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''es''%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''pt''%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''fr''%'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''ar''%') THEN
    RAISE EXCEPTION 'CADRE-LANGUES : contract_texts_locale_check ne porte pas les cinq langues';
  END IF;
  IF (SELECT r.version FROM public.contract_required_versions r
       WHERE r.contract_kind = 'teacher_religious_framework') IS DISTINCT FROM '2026-11-07' THEN
    RAISE EXCEPTION 'CADRE-LANGUES : version requise du cadre religieux absente ou differente';
  END IF;
END;
$postflight$;
