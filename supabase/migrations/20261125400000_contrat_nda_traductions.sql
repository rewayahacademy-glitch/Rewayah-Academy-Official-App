-- LANGUES (directeur, 14/11/2026) : les traductions de courtoisie, en arabe et
-- en anglais, du contrat d'enseignant teacher_nda version 2026-10-jur.
--
-- Le texte SIGNE reste le francais : la ligne fr n'est pas touchee, son sha256
-- (empreinte commencant par 5114057583bd85a0) reste celui de la signature. Les deux lignes ajoutees ici sont lues
-- par l'application pour etre montrees sous le texte francais, avec la mention
-- « la version francaise fait foi ». Aucune signature ne les utilise : tout ce
-- qui signe (completer_contract_acceptance, signer_contrat, la policy
-- contract_acceptances_self_insert) filtre sur locale = 'fr'.
--
-- La forme des textes suit celle du texte francais en base : 0092 le publie,
-- puis 20261011072525 en retire les sauts de ligne de debut et de fin et
-- recalcule l'empreinte ; les deux traductions n'ont donc, elles non plus,
-- aucun saut de ligne en tete ni en queue.
--
-- Verifie dans le depot avant d'ecrire ce fichier :
--   * contract_texts_locale_check accepte ar et en (20261118000200) ;
--   * contract_texts_contract_kind_check accepte teacher_nda (20261118000000) ;
--   * la policy de lecture contract_texts_published_read est USING (is_current),
--     toutes langues (20261118000000) : les nouvelles lignes se lisent sans la
--     changer ;
--   * l'index unique contract_texts_one_current_per_locale est par (kind, locale) :
--     une ligne ar et une ligne en en vigueur n'entrent pas en conflit avec fr ;
--   * aucun trigger sur contract_texts ; le CHECK sha256 = digest(body) est
--     satisfait en calculant l'empreinte dans l'INSERT, comme 0092.
--
-- Le texte francais est reconnu par les 16 premiers signes de son empreinte, pas
-- par l'empreinte entiere : la CI refuse toute chaine de 64 signes hexadecimaux
-- sous supabase/migrations (garde anti-secret R2). 64 bits suffisent a reconnaitre
-- ce texte-la plutot qu'un autre.
--
-- Rejouable : ON CONFLICT DO NOTHING. Sans BEGIN ni COMMIT (le fichier est
-- transactionnel a l'application). Aucune suppression, aucune modification.

DO $preflight$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.contract_texts t
     WHERE t.contract_kind = 'teacher_nda'
       AND t.version = '2026-10-jur'
       AND t.locale = 'fr'
       AND t.is_current
       AND pg_catalog.left(t.sha256, 16) = '5114057583bd85a0'
  ) THEN
    RAISE EXCEPTION 'CONTRAT-TRADUCTIONS : le texte francais teacher_nda 2026-10-jur en vigueur n''a pas l''empreinte attendue, arret (les traductions suivent ce texte-la, pas un autre)';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_policy p
     WHERE p.polrelid = 'public.contract_texts'::regclass
       AND p.polname = 'contract_texts_published_read'
       AND p.polcmd = 'r'
       AND pg_catalog.pg_get_expr(p.polqual, p.polrelid) = 'is_current'
  ) THEN
    RAISE EXCEPTION 'CONTRAT-TRADUCTIONS : la policy de lecture de contract_texts n''est pas USING (is_current), arret';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint c
     WHERE c.conrelid = 'public.contract_texts'::regclass
       AND c.conname = 'contract_texts_locale_check'
       AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''ar''%'
       AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''en''%'
  ) THEN
    RAISE EXCEPTION 'CONTRAT-TRADUCTIONS : contract_texts_locale_check n''accepte pas ar et en, arret';
  END IF;
END;
$preflight$;

WITH traductions(locale, body) AS (
  VALUES
    ('ar', $contrat_ar$ما نقوم به.
يُسجَّل كل درس صوتيًا. لا تُسجَّل الصورة. ويمكن أيضًا لشخص من الأكاديمية مكلَّف بالمراقبة أن يتابع الدرس مباشرة: يرى الدرس ويسمعه دون أن يُرى أو يُسمع. ولا يسجّل شيئًا. ثم يرسل تقريرًا إلى الأكاديمية. وتذكّر القاعة بذلك باستمرار.

لماذا.
لحماية الأطفال والمعلمين. إذا أبلغ أحد عن مشكلة، يمكننا التحقق مما حدث. وهو أيضًا دليل لك إذا اشتكت أسرة دون حق.

من يمكنه الاستماع إلى التسجيل.
فقط الأشخاص في الأكاديمية المكلَّفون بالجودة والحماية، ولسبب محدد فقط، مثل بلاغ. يُسجَّل كل استماع في سجل. يمكنك أن تسأل هل استُمع إلى تسجيل، ولماذا.

إلى متى.
30 يومًا، ثم يُحذف. إذا وُجد بلاغ، يُحتفظ بالتسجيل حتى نهاية الفحص.

إذا رفضت.
لا يمكننا أن نعهد إليك بطلاب، لأن هذا الإجراء يحمي الأطفال. نخبرك بذلك قبل توقيعك.

لا ترى أبدًا بيانات اتصال أسرة: لا الاسم الكامل، ولا البريد الإلكتروني، ولا الهاتف.

زيارات المراقبة.
لحماية الطلاب وضمان جودة الدروس، قد يتابع شخص من الأكاديمية دروسك مباشرةً دون إبلاغك بوقت ذلك. يرى الدرس ويسمعه. لا يتكلم، ولا يسجّل شيئًا، ولا ينشر شيئًا. يكتب تقريرًا للإدارة. تصلك كل شهر خلاصة، ويمكنك الاعتراض عليها. تُحفظ التقارير 12 شهرًا. تشرح سياسة المراقبة كل شيء، وهي مرفقة بهذا العقد ومتاحة في مساحتك. بتوقيعك تؤكد أنك استلمتها.

أوافق على أن تعالج الأكاديمية كوني أدرّس القرآن، وهو ما قد يكشف ديني، من أجل إدارة عقدي ودروسي.$contrat_ar$::text),
    ('en', $contrat_en$What we do.
Every class is recorded in audio. The image is not recorded. A person from the Academy in charge of review may also follow a class live: they see and hear the class, without being seen or heard. They record nothing. They then send a report to the Academy. The room reminds of this permanently.

Why.
To protect children and Teachers. If someone reports a problem, we can check what happened. It is also evidence for you if a family complains wrongly.

Who may listen to the recording.
Only the persons of the Academy in charge of quality and protection, and only for a specific reason, for example a report. Each listening is entered in a log. You may ask whether a recording has been listened to, and why.

How long.
30 days, then erased. If there is a report, the recording is kept until the end of the review.

If you refuse.
We cannot entrust students to you, because this measure protects children. We tell you before your signature.

You shall never see a family's contact details: neither full name, nor email, nor phone.

Review visits.
To protect students and guarantee the quality of classes, a person from the Academy may observe your classes live, without warning you of the time. They see and hear the class. They do not speak, record nothing and publish nothing. They write a report for the administration. You receive a summary each month. You may dispute it. Reports are kept for 12 months. The review policy, attached to this contract and available in your space, explains everything. By signing, you confirm having received it.

I agree that the Academy processes the fact that I teach the Quran, which may reveal my religion, to manage my contract and my classes.$contrat_en$::text)
)
INSERT INTO public.contract_texts (
  contract_kind, version, locale, body, sha256, is_current
)
SELECT
  'teacher_nda',
  '2026-10-jur',
  traductions.locale,
  traductions.body,
  pg_catalog.encode(extensions.digest(pg_catalog.convert_to(traductions.body, 'UTF8'), 'sha256'), 'hex'),
  true
FROM traductions
ON CONFLICT (contract_kind, version, locale) DO NOTHING;

DO $postflight$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM public.contract_texts t
       WHERE t.contract_kind = 'teacher_nda' AND t.version = '2026-10-jur'
         AND t.locale IN ('fr', 'ar', 'en') AND t.is_current) <> 3 THEN
    RAISE EXCEPTION 'CONTRAT-TRADUCTIONS : il faut exactement fr, ar et en en vigueur pour teacher_nda 2026-10-jur, arret';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.contract_texts t
     WHERE t.contract_kind = 'teacher_nda' AND t.version = '2026-10-jur'
       AND t.locale = 'fr' AND t.is_current
       AND pg_catalog.left(t.sha256, 16) = '5114057583bd85a0'
  ) THEN
    RAISE EXCEPTION 'CONTRAT-TRADUCTIONS : le texte francais signe a change, arret';
  END IF;
END;
$postflight$;
