-- GUIDE-ARABE-NATIF (21/11/2026) : le guide de l'enseignant reecrit directement en arabe et en anglais, sans passer par le
-- francais (directeur, 21/11/2026 : « tu l'ecris comme si tu etais un arabe, qui a eu l'idee du guide et tu l'as ecrit sans
-- passer par la version francaise. En suite tu fais de meme pour l'anglais »). Memes faits que la version francaise validee
-- le 20/11/2026, meme decoupage en 14 parties (codes p1 a p14 inchanges : les avis et commentaires restent attaches).
--
-- LIVRE ICI : une version 2026-11-21 de l'arabe et de l'anglais dans private.lettre_candidats_parties. Rien n'est remplace :
-- la version 2026-11-20 reste en base ; public.lire_lettre_candidats() rend deja la version la plus recente de chaque langue.
-- Le francais reste en 2026-11-20. Texte engendre depuis docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-{ar,en}.md par
-- le meme decoupage que partiesDuDepot() (test/features/candidature/faux_port_lettre.dart) ; ne pas retoucher a la main.
--
-- MOTS D'EFFACEMENT : ZERO. Aucune fonction remplacee. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.lettre_candidats_parties') IS NULL THEN
    RAISE EXCEPTION 'GUIDE-ARABE-NATIF : le guide (20261130970000) n''est pas installe ; rien n''est modifie';
  END IF;
  IF EXISTS (SELECT 1 FROM private.lettre_candidats_parties t WHERE t.version = '2026-11-21' AND t.langue IN ('ar', 'en')) THEN
    RAISE EXCEPTION 'GUIDE-ARABE-NATIF : deja installe ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.lettre_candidats_parties t WHERE t.langue = 'fr' AND t.version = '2026-11-20') <> 14 THEN
    RAISE EXCEPTION 'GUIDE-ARABE-NATIF : la version francaise attendue (14 parties) est absente ; rien n''est modifie';
  END IF;
END
$preflight$;

-- ar : 14 parties, version 2026-11-21.
INSERT INTO private.lettre_candidats_parties (langue, version, rang, code, titre, corps) VALUES
('ar', '2026-11-21', 1, 'p1',
 $lettre_texte$لماذا وصلك هذا الدليل$lettre_texte$,
 $lettre_texte$السلام عليكم ورحمة الله وبركاته.

قال رسول الله ﷺ: «خيركم من تعلّم القرآن وعلّمه» (رواه البخاري). ولأهل القرآن مكانة لا تخفى، ومن يعلّمه يوصل كلام الله إلى قلب طفل.

نعم، هذا العمل له مكافأة، ولا حرج في ذلك. لكن الأجر الحقيقي عند الله. فاجعل هذه النية حاضرة وأنت تقرأ ما يلي.

وصلك هذا الدليل لأنك تقدّمت بنفسك للتدريس في أكاديمية الرواية، ووافقت على شروطنا.

تقدّمت دون أن تعرف اسمنا، ولا المكافأة، ولا من يقف وراء الأكاديمية. لم نُعلن شيئًا من ذلك، وكان هذا عن قصد. ومع ذلك أقبلت. وهذا مسّ قلوبنا.

ومن رسائلكم فهمنا شيئًا مهمًّا: بعضكم يظن أنه هو من يحتاج إلينا. والصحيح عكس ذلك تمامًا. نحن من نحتاج إليكم. يحتاج إليكم أطفال لا يجدون حلقة قرآن قريبة منهم، وتحتاج إليكم أسرهم، وتحتاج إليكم الأمة. ووجودكم معنا شرف لنا قبل أن يكون فرصة لكم.

لذلك من حقكم علينا أن نصارحكم بكل شيء: من نحن، وكم ستكسب، وكم ساعة ستعطي، وماذا ننتظر منك، وما الصعب في هذا العمل.

اقرأ إلى آخر سطر. وعندها ستعرف هل تواصل معنا أم لا، وكلا القرارين محترم.$lettre_texte$),
('ar', '2026-11-21', 2, 'p2',
 $lettre_texte$من نحن$lettre_texte$,
 $lettre_texte$نحن **أكاديمية الرواية** (Rewayah Academy).

والأكاديمية شركة مسجّلة رسميًّا باسم **Rewayah Academy Ltd** في إنجلترا وويلز، برقم **16624644**، ومقرّها: 71-75 Shelton Street, Covent Garden, London WC2H 9JQ، المملكة المتحدة. ويمكن لأي أحد أن يتحقق من ذلك في السجل العام للشركات البريطانية (Companies House).

بدأت الأكاديمية قبل ثلاث سنوات تقريبًا، وكان كل واحد منا قبلها يعلّم القرآن منذ سنوات.

أغلب طلابنا مسلمون يعيشون في بلدان يكون فيها المسلمون أقلية، بعيدًا عن البلاد التي تجد فيها حلقة القرآن في كل حيّ.

وطوال هذه السنوات الثلاث كانت المشكلة نفسها تتكرر: طالب يريد أن يتعلّم، ولا نجد له المعلّم المناسب. فإما أن نعتذر منه، وإما أن نطلب منه الانتظار.

هذه المرة قلبنا الترتيب: **نجمع المعلّمين أولًا، ثم نفتح الباب للطلاب**. ولا نَعِد أسرة بشيء قبل أن يكون المعلّمون جاهزين.

فوجّهنا نداءً إلى أهل القرآن من الرجال والنساء، فاستجاب حتى الآن أكثر من 2000 شخص، حتى إن خادمنا توقّف في اليوم الأول من كثرة المسجّلين. وما زالت الطلبات تصل كل يوم، من الخليج وإفريقيا وأوروبا، من أكثر من 50 جنسية. وأنت واحد منهم.

### كيف ندرّس

لا نستعمل Zoom ولا Meet ولا WhatsApp. للأكاديمية تطبيقها الخاص، وفيه قاعة درس بالفيديو.

الطالب عندنا ينضمّ إلى **فصل**، مثل فصلك أيام الثانوية أو الجامعة: مواعيد ثابتة، وطلاب معروفون، وأدوات، ومعلّم واحد. حتى الجرس الذي يعلن نهاية الحصة موجود.

الرجال يدرّسون الأولاد والرجال، والنساء يدرّسن البنات والنساء. والاستثناء الوحيد: إذا كانت الحصة ستضيع، قد يقدّمها في ذلك اليوم بديل من الجنس الآخر (انظر الجزء 6).$lettre_texte$),
('ar', '2026-11-21', 3, 'p3',
 $lettre_texte$ماذا ستدرّس$lettre_texte$,
 $lettre_texte$التطبيق مخصّص لشيء واحد: **القرآن**.

يبدأ الطالب المبتدئ بـ**الأساسيات**، وهي أربع مراحل:
1. الحروف.
2. القراءة بالحركات.
3. القراءة من المصحف.
4. الفاتحة وقصار السور، من الناس إلى الزلزلة.


ويتعلّم في أثناء ذلك أحكام التجويد الميسّرة: يقلّد أولًا، ثم يعرف اسم الحكم. ويتعلّم الصغار كذلك أذكار الصلاة والوضوء.

وفي آخر الأساسيات يجتاز اختبارًا، ثم يواصل مع القرآن: ختمًا بالقراءة، أو حفظًا.

لن تضع المنهج بنفسك؛ الأكاديمية تحدد المراحل والأهداف والمواعيد حصةً حصة. أما طريقة الشرح فلك، وأنت صاحب القرار في فصلك.

**لغة الشرح.** تشرح بلغة طلابك: الفرنسية أو الإنجليزية أو العربية أو الفولانية (البولار) أو البرتغالية أو غيرها. والفصل الذي يتكلم طلابه العربية يدرّسه معلّم يتكلم العربية. لكن كثيرًا من طلابنا لا يفهمون العربية بعد، فإن كنت تُحسن لغة أخرى إلى جانبها، فُتحت لك فصول أكثر.

**وماذا عن بقية العلوم؟** الفقه والعقيدة والسيرة المفصّلة لا تُدرَّس هنا. للأكاديمية منصّة أخرى للعلوم الشرعية، تعمل حاليًّا بالفرنسية والفولانية فقط، وسنعرّفكم بها حين تُفتح لكل البلدان.$lettre_texte$),
('ar', '2026-11-21', 4, 'p4',
 $lettre_texte$المكافأة$lettre_texte$,
 $lettre_texte$القاعدة واحدة: **مكافأتك تكون على كل طالب**. كلما زاد عدد طلابك زادت مكافأتك، ومن لم يكن له طلاب فلا مكافأة له.

ومما يدفعه كل طالب، يعود إليك قرابة النصف:
- **47 %** في فصل الكبار؛
- **نحو 45 %** في فصل الأطفال.

|  | فصل الأطفال (من 6 إلى 17 سنة) | فصل الكبار |
| --- | --- | --- |
| الحصص | 3 في الأسبوع، مدة كل حصة ساعة | 3 في الأسبوع، مدة كل حصة ساعة ونصف |
| الاستراحة داخل الحصة | 5 دقائق | 10 دقائق |
| ساعاتك | 3 ساعات في الأسبوع، أي نحو 13 ساعة في الشهر | 4 ساعات ونصف في الأسبوع، أي نحو 19 ساعة ونصف في الشهر |
| عدد الطلاب في الفصل | من 3 إلى 5، ولا يتجاوز 5 أبدًا | من 3 إلى 6، ولا يتجاوز 6 أبدًا |
| ما يدفعه الطالب في الشهر | 55 $ | 65 $ |
| نصيبك عن كل طالب في الشهر | نحو 24 $ | نحو 30 $ |
| فصل صغير (3 طلاب) | نحو 72 $ في الشهر | نحو 90 $ في الشهر |
| فصل مكتمل | 5 × 24 $ = نحو 120 $ في الشهر | 6 × 30 $ = نحو 180 $ في الشهر |


المبالغ بالدولار الأمريكي، وهي محسوبة على أساس حضور الطلاب كل الحصص.

وقد تمنح الأكاديمية بعض الأسر تخفيضًا: لأن لها أكثر من طفل مسجّل، أو لأن أحد أفرادها مسلم جديد، أو لغير ذلك. **وهذه التخفيضات لا تُنقص من نصيبك شيئًا**، فالأكاديمية تتحمّلها وحدها.

### أقل مكافأة وأعلاها

عن **فصل واحد**، توقّع ما بين **70 $ و180 $ في الشهر**، أي نحو 9 $ في الساعة إذا كان الفصل مكتملًا، ونحو 5 $ إذا كان فيه 3 طلاب.

ويمكن أن تُسند إليك عدة فصول، إذا سمحت أوقاتك وتوفّرت فصول تناسبك. مثال ذلك: فصلان مكتملان للأطفال وفصل مكتمل للكبار، أي 120 + 120 + 180 = 420 $ في الشهر، مقابل 10 ساعات ونصف من التدريس في الأسبوع.

وهذا مثال للتوضيح، لا وعد. فقد تمرّ عليك شهور دون فصل، أي دون مكافأة (انظر الجزء 7).

### لماذا 47 % للكبار و45 % للأطفال؟

مع الكبير، يكاد كل العمل يجري في الحصة نفسها. أما مع الطفل، فتتابعه الأكاديمية بعد الحصة أيضًا، ليعرف والداه أين وصل ويعيناه في البيت. وهذه المتابعة لها كلفة.

### ولماذا لا يكون أكثر؟

لأن تشغيل الأكاديمية مكلف. فبالنصف الآخر تدفع: خوادم قاعة الفيديو، والتطبيق ومن يطوّرونه، ورسوم البطاقات البنكية، وتحويل مكافآتكم، والمحاسبة، والإدارة، ومتابعة الأطفال، والضرائب المفروضة على كل شركة.

وسترى هذا التوزيع بالنسب المئوية في حسابك داخل التطبيق، فليس عندنا ما نخفيه.$lettre_texte$),
('ar', '2026-11-21', 5, 'p5',
 $lettre_texte$كيف ومتى تصلك المكافأة$lettre_texte$,
 $lettre_texte$بعد كل حصة يحسب التطبيق ما استحققته، وتراه في حسابك.

ويُحوَّل إليك مجموع الشهر **قبل اليوم الخامس من الشهر الذي يليه**، بتحويل دولي (Wise) أو بوسيلة أخرى بحسب بلدك، والأكاديمية تتحمّل رسوم التحويل. وفي بعض البلدان تمنع البنوك هذه التحويلات؛ فإن كان هذا حالك أخبرناك، وبحثنا معك عن وسيلة مسموح بها.

وإذا استلمت فصلًا في منتصف الشهر، فمكافأتك عن الحصص الباقية من ذلك الشهر فقط، لا عن الشهر كله.

### ما الذي يزيد مكافأتك أو ينقصها

لن يكسب معلّمان المبلغ نفسه، وهذه الأسباب:
- **عدد الطلاب.** فصل فيه 3 طلاب يكسبك أقل من فصل فيه 5.
- **عدد الفصول** التي تدرّسها.
- **غياب الطلاب.** إذا غاب طالب عن حصة، تأخذ نصف نصيبك عنه في تلك الحصة، لا النصيب كله. أردنا بذلك أن يحرص كل معلّم على حضور طلابه.
- **ترك الطلاب للفصل.** إذا خرج طلابك واحدًا بعد آخر، نقصت مكافأتك معهم. فالطالب يبقى حيث يتقدّم ويشعر بالتقدير. وليس كل انسحاب بسببك، لكنه احتمال حقيقي، فضعه في حسابك قبل أن تلتزم.
- **عطلة الطالب.** يمكن للأسرة أن توقف طفلها شهرًا، ولا مكافأة لك عنه في ذلك الشهر.
- **إغلاق الأكاديمية.** لا دروس في آخر رمضان وأيام عيد الفطر (نحو 20 يومًا)، ولا حول عيد الأضحى (10 أيام). وما دامت لا دروس، فلا مكافأة.
- **غيابك أنت.** الحصة التي يقدّمها البديل، مكافأتها للبديل.
- **خلاصة آخر الحصة.** في نهاية الدرس تسجّل ببضع لمسات ما درسه الفصل وأين توقّف، وهذا لا يأخذ 20 ثانية. وما دامت الخلاصة غير مسجّلة، تبقى مكافأة الشهر معلّقة.$lettre_texte$),
('ar', '2026-11-21', 6, 'p6',
 $lettre_texte$الالتزام بالموعد، والبديل، والغياب$lettre_texte$,
 $lettre_texte$الأكاديمية لا تتساهل في الانضباط، وهذا سببه:

نحن حازمون مع الأسر؛ فالطالب الذي يغيب يدفع شهره كاملًا ويعوّض ما فاته وحده. فلا بد أن نفي نحن أيضًا بما علينا: **في موعد الحصة يكون في القاعة معلّم. دائمًا.**

### إذا تأخرت

هذا ما يفعله التطبيق، دقيقة بعد دقيقة:
1. **قبل الحصة بـ20 دقيقة** تُفتح القاعة، فتدخل وتستعد.
2. **في الموعد نفسه**، إن لم تكن قد دخلت، يصلك تذكير.
3. **بعد 3 دقائق** يصلك تنبيه: إن لم تدخل، ستُسند الحصة إلى غيرك.
4. **بعد 8 دقائق** تكون الحصة قد فاتتك، ويصل نداء إلى كل المعلّمين المتصلين.
5. يقبل أحدهم ويدخل القاعة، غالبًا في أقل من دقيقة. والغاية أن يجد الطلاب معلّمهم **بعد 11 دقيقة من الموعد على الأكثر**.


وإذا قبل أكثر من معلّم في اللحظة نفسها، يختار التطبيق أولًا من كان من جنس الفصل (رجلًا لفصل الرجال، وامرأة لفصل النساء)، ثم من يتكلم لغة الطلاب، وإلا فأول من يكون متاحًا. فقد يدرّس رجل فصل نساء، أو العكس، في تلك الحصة وحدها.

**ومكافأة تلك الحصة كلها للبديل، 100 %**، ولا تأخذ أنت عنها شيئًا.

### ما يبقى لك، وما قد تخسره

أن يحلّ بديل مكانك مرة واحدة لا يُفقدك فصلك؛ يبقى الفصل لك، ولا يستطيع البديل دخوله بعد انتهاء حصته.

لكن إن تكرر ذلك وصلتك إنذارات، وإن استمر انتقل الفصل إلى غيرك.

### إذا احتجت إلى الغياب

سفر، أو مناسبة عائلية، أو مرض، عافانا الله وإياكم: كل هذا يحدث لأي أحد. أبلغ الإدارة **قبلها**، مع تاريخ غيابك وتاريخ رجوعك.

يتولّى فصلك بديل خلال هذه المدة، وله مكافأة حصصه، وعند رجوعك يعود إليك فصلك.

وإن لم ترجع في التاريخ الذي حدّدته، فقدت ذلك الفصل، لكنك لا تفقد مكانك في الأكاديمية: تبقى معنا، وتُعلن أنك متاح، وقد يُسند إليك فصل آخر لاحقًا.

### إذا كنت أنت البديل

لك مكافأة عن كل حصة تقدّمها بديلًا، وتتجمّع هذه المكافآت في حسابك، ثم تُحوَّل إليك حين تبلغ حدًّا أدنى تحدّده الإدارة، حتى لا نرسل تحويلات ببضعة دولارات.$lettre_texte$),
('ar', '2026-11-21', 7, 'p7',
 $lettre_texte$بعد المقابلة: ما الذي يحدث في الواقع$lettre_texte$,
 $lettre_texte$يظن كثير منكم: «أجتاز المقابلة، وفي الغد يكون عندي فصل». **ليس الأمر كذلك.** هذه هي المراحل:
1. **يُقبل ملفك وتنجح في المقابلة.** يُفتح لك حساب المعلّم، وتحصل على رقم تسجيل رسمي، ومن هنا يمكن أن يُسند إليك فصل.
2. **تتدرّب على التطبيق.** تريك الأكاديمية كيف تعمل قاعة الدرس.
3. **تنتظر فصلًا.** قد تكون أيامًا، وقد تكون شهورًا.
4. **يُسند إليك فصل.** تصلك رسالة، ويظهر الفصل في الصفحة الرئيسية.


### لماذا الانتظار؟

لا نُسند الفصول اعتباطًا؛ لا بد أن يتوافق كل شيء بينك وبين الطلاب المسجّلين:
- **اليوم والساعة**: الطلاب يختارون الموعد، ويجب أن تكون متفرّغًا فيه؛
- **اللغة**: أن تتكلم لغة الطلاب؛
- **الجنس**: رجل للأولاد والرجال، وامرأة للبنات والنساء؛
- **الخبرة**: تعليم أطفال مبتدئين غير تعليم الكبار، وغير التحفيظ.


مثال: سجّل هذا الأسبوع اثنا عشر طالبًا: ثماني بنات صغيرات يتكلمن الفرنسية ويدرسن مساءً بتوقيت أوروبا، وأربعة رجال يتكلمون الإنجليزية ويدرسون صباحًا. فنحتاج إلى معلّمات يتكلمن الفرنسية ومتفرغات مساءً، وإلى معلّم يتكلم الإنجليزية ومتفرغ صباحًا. أما المعلّم المتميّز الذي لا تنطبق عليه أيّ من الحالتين، فسينتظر التسجيلات القادمة.

وتُفتح الفصول على مدار السنة، لا في أول الشهر فقط.

**نصيحتنا: لا تترك شيئًا من أجلنا.** حافظ على عملك، وواصل دراستك، وتابع بريدك والتطبيق، وأكثِر من الدعاء.

### وإذا لم يكفِ الطلاب 2000 معلّم؟

هذا وارد، بل هو المتوقع في البداية؛ لا نستطيع أن نعطي كل واحد فصلًا من الآن.

فإن قُبلت ولم يُسند إليك فصل، تبقى معنا، ويمكنك:
- **أن تكون بديلًا**: تدرّس مكان معلّم مريض أو غائب أو متأخر، ولك مكافأة عن كل حصة؛
- **أن تنتظر** حتى يُفتح فصل جديد أو يشغر فصل.


### وماذا عن الدروس الفردية؟

يسألنا كثيرون عن دروس فردية: معلّم لطالب واحد. والأكاديمية تدرس إضافتها إلى جانب الفصول، دون أي موعد محدّد.

وقد جرّبنا هذه الطريقة من قبل، فظهرت لنا حدودها، وهي أصعب بكثير مما يظن الناس، على المعلّم والطالب معًا. ولن نفتحها إلا حين نتأكد أننا نُحسن تقديمها.$lettre_texte$),
('ar', '2026-11-21', 8, 'p8',
 $lettre_texte$لماذا نطلب هويتك وصورتك$lettre_texte$,
 $lettre_texte$سأل عدد منكم عن هذا، وهو سؤال في محلّه. وهذا جوابنا بصراحة.

في الإنترنت كل أصناف الناس، ونحن نستقبل طلابًا من سن السادسة.

فكّر فيما يصل إليه المعلّم: يرى وجه الطفل بالفيديو، ويسمع صوته، ويعرف اسمه وعمره ومواعيده، ويكلّمه ثلاث مرات في الأسبوع، والطفل يثق به.

والآن تخيّل أن هذا المكان يُعطى لأي أحد. هذا ما قد يقع:
- **من يكذب في هويته.** باسم مزوّر وشهادة مزوّرة، ولا يمكن الوصول إليه يوم تقع مشكلة.
- **من يطلب الأطفال لا القرآن.** وهؤلاء موجودون؛ يكسبون ثقة الطفل شيئًا فشيئًا، ثم يحاولون الانفراد به بعيدًا عن والديه.
- **من يصوّر أو يسجّل.** صورة الطفل وصوته قد تُنسخ وتُحفظ وتُنشر.
- **من طُرد من مكان آخر** بسبب سلوك خطير، ثم يعود باسم آخر.
- **من يجتاز المقابلة ثم يجعل غيره يدرّس** مكانه.
- **من يريد أن يزرع أفكارًا دخيلة** في عقول الأطفال باسم القرآن.


حالة واحدة من هذه تعني طفلًا مجروحًا، وأسرة محطّمة، وثقة تنهار في الأكاديمية كلها، ويدفع الثمن معها المعلّمون الصادقون، أي أنتم.

وهناك القانون كذلك: طلابنا في بلدان كثيرة، وقوانين حماية الطفل فيها تُلزمنا أن نعرف بدقة لمن نسلّم الطفل. والبنك يشترط اسمك الحقيقي ليحوّل إليك مكافأتك.

**ماذا نفعل بوثائقك؟** لا تطّلع عليها إلا الإدارة، ولا تُعرض أبدًا على الطلاب ولا على الأسر. وإن سحبت طلبك، يمكنك أن تطلب حذفها.

**وما نطلبه منك في المقابل:** لا تطلب من طالب رقم هاتفه أو أي وسيلة للتواصل معه، ولا تتواصل معه خارج التطبيق، ولا تصوّر الفصل ولا تسجّله. وهذه قاعدة لا استثناء فيها.

الوالد يأتمننا على أغلى ما يملك، وأن تُعرّف بنفسك هو أول خطوة في بناء الثقة. ولو كنت مكانه لطلبت الشيء نفسه.$lettre_texte$),
('ar', '2026-11-21', 9, 'p9',
 $lettre_texte$ما نشترطه، وما هو صعب$lettre_texte$,
 $lettre_texte$### من رفضناهم حتى الآن

الأكاديمية سنّية على منهج أهل السنة والجماعة، ولا تُخفي ذلك، وتدافع عن قيمها. ومن يعاديها فلا مكان له بيننا.

ولم نرفض حتى الآن إلا صنفين من الطلبات:
- من لم يوقّع **الالتزام الديني**، وهو نص يطلب احترام القرآن والسنة وجميع صحابة النبي ﷺ، وفي مقدّمتهم الخلفاء الراشدون الأربعة، والسلف الصالح؛
- من كان مظهره مخالفًا بوضوح لأحكام الشرع: قَصّة شعر محرّمة، أو لباس لا يراعي الضوابط الشرعية.


ولماذا؟ لأن الطفل يتعلّم من معلّمه بعينه قبل أذنه. وأطفالنا في تلك البلدان يكبرون وسط كل أفكار هذا العصر؛ هم أمل الغد، وهم في الوقت نفسه سريعو التأثّر. وحسن اختيار من يعلّمهم هو أول ما علينا.

### صعوبة ستواجهها

نعرف هذه الأسر منذ سنوات، ولا بد أن ننبّهك إلى أمر.

كثير منها ينظر إلى الدرس كأنه سلعة اشتراها؛ فالأسرة تعدّ نفسها زبونًا، والمعلّم في نظرها بائع، والزبون يظن أنه دائمًا على حق. وستلمس ذلك في طريقة كلامهم وكتابتهم ومطالبهم.

ونحن نعلم أن هذا خطأ، فلمعلّم القرآن حرمته. لكنهم لم يتعلّموا ذلك بعد، ولم يعلّمهم إياه أحد.

وهنا يأتي دورك: أن تعلّمهم ذلك بالحكمة والموعظة الحسنة، وبالصبر. فأنت هنا لست معلّمًا فحسب، بل أنت قبل ذلك داعية.

مثال: يكتب إليك أبٌ بجفاء: «أنا أدفع، فيجب أن يتقدّم ابني أسرع». لك أن تغضب وتردّ عليه بمثل أسلوبه، ولك أن تُريه بهدوء أين وصل ابنه، وما الذي يراجعه معه في البيت، وتدعوه إلى أن يستمع إليه وهو يقرأ. في الأولى تخسر طالبًا، وفي الثانية كثيرًا ما تكسب أسرة كاملة.

رأينا هذا مرارًا: حين يكون المعلّم أحكم من الطالب وأصبر، تستقيم الأمور في النهاية. فإن كان هذا الصبر ثقيلًا عليك من الآن، فهذا العمل ليس لك، وخير لك أن تعرف ذلك اليوم.$lettre_texte$),
('ar', '2026-11-21', 10, 'p10',
 $lettre_texte$الأكاديمية ترى ما يجري في الفصل$lettre_texte$,
 $lettre_texte$نفضّل أن نخبرك بهذا من البداية، لا بعد ذلك.

**التطبيق يسجّل دخولك وخروجك**، ودخول الطلاب وخروجهم، فلا تحتاج إلى دفتر حضور؛ التطبيق يتولّى ذلك عنك.

**ويقيس جودة اتصالك أثناء الحصة**: جيد، أو ضعيف، أو منقطع، دون أن يحتفظ بالصوت ولا بالصورة. فإذا اشتكت أسرة من حصة، عرفت الأكاديمية مصدر المشكلة، ولم تُتّهم ظلمًا.

**وقد تحدث زيارة رقابية دون إشعار.** يدخل أحد أعضاء الإدارة القاعة دون أن تراه، ودون ميكروفون ولا كاميرا. وإذا كانت المدرّسة امرأة، فالزائر دائمًا امرأة من الفريق، ولا يدخل رجل أبدًا. ولا يهمّ الزائر إلا أمر واحد: هل يعمل المعلّم فعلًا مع طلابه؟

**ولا يمكنك أن تدرّس حصتين في الوقت نفسه**، فالزائر يرى ذلك. وإذا غادرت القاعة أكثر من 30 ثانية أثناء الحصة، أخرجك التطبيق وأبلغ الإدارة.

وفيما عدا ذلك أنت حرّ: لا تفرض عليك الأكاديمية ركنًا معيّنًا في البيت، ولا جلسة معيّنة، ولا خلفية. كل ما تطلبه أمران: مكان هادئ واتصال جيد، فبدونهما يتضرّر الطلاب.$lettre_texte$),
('ar', '2026-11-21', 11, 'p11',
 $lettre_texte$براكسيس، مساعدنا$lettre_texte$,
 $lettre_texte$أنتم أكثر من 2000، تتكلمون عشرات اللغات، وتعيشون في كل المناطق الزمنية، ورسائلكم تصل ليلًا ونهارًا. ولا يستطيع فريقنا أن يردّ على كل واحد بالسرعة المطلوبة.

لذلك أنشأنا **براكسيس** (Praxis)، وهو مساعد يعمل بالذكاء الاصطناعي. ليس إنسانًا، ولن يدّعي يومًا أنه إنسان.
- **ما يفعله**: يجيب عن الأسئلة المتكررة، ويوضّح، ويخبرك أين وصل طلبك.
- **ما لا يفعله**: لا يقرّر شيئًا؛ لا يقبل أحدًا ولا يرفضه، ولا يُسند فصلًا، ولا علاقة له بالمكافآت.
- **من يوجّهه**: الإدارة، ولا يعمل إلا فيما تكلّفه به.


أين وصل اليوم؟ بدأنا تجربته فأخطأ في بعض الردود، فأوقفناه مؤقتًا، ونحن نراجع إجاباته لنضبطه قبل أن نعيده. وربما وصلت بعضكم رسالة منه.

وحين يعود، إن لم يكفك جوابه فاذكر ذلك في رسالتك، وسيتابع معك أحد أعضاء الفريق.$lettre_texte$),
('ar', '2026-11-21', 12, 'p12',
 $lettre_texte$إن لم يناسبك هذا$lettre_texte$,
 $lettre_texte$لك أن تنسحب متى شئت، دون أن تذكر سببًا.

أكاديمية الرواية شركة إنجليزية، والقانون يُلزمها باحترام حقك في الانسحاب. يمكنك أن تسحب طلبك، وأن تطلب حذف حسابك وبياناتك، ولن تصلك بعد ذلك أي رسالة من الأكاديمية. وإن غيّرت رأيك، يمكنك أن تستعيد طلبك بنفسك خلال 7 أيام من سحبه.

ولذلك اكتب إلى **support@rewayahacademy.com**.$lettre_texte$),
('ar', '2026-11-21', 13, 'p13',
 $lettre_texte$أسئلتكم$lettre_texte$,
 $lettre_texte$**سجّلت، فهل أصبحت معلّمًا في الأكاديمية؟** ليس بعد. أنت الآن مرشّح، وبقيت دراسة ملفك ثم المقابلة.

**هل أدفع شيئًا لأُقبل أو لأتدرّب؟** لا، لا شيء أبدًا. وإن طلب منك أحد مالًا باسمنا فهو محتال، فأخبرنا.

**كم سأنتظر حتى يُسند إليّ فصل؟** لا نعلم، ولن نعطيك موعدًا قد لا نفي به. فالأمر متعلّق بمن يسجّل من الطلاب، وبأوقاتك ولغتك وخبرتك.

**في أي ساعة ستكون حصصي؟** في الساعة التي يختارها طلاب الفصل، وهي ثابتة كل أسبوع. ولن يُسند إليك فصل إلا إذا ناسبك موعده. ويعرض التطبيق كل موعد بتوقيتك، ثم بتوقيت مكة المكرمة، وهو توقيت الأكاديمية.

**كم سأكسب بالتحديد؟** نحو 24 $ في الشهر عن كل طفل، ونحو 30 $ في الشهر عن كل كبير، إذا حضروا كل الحصص. اضرب في عدد طلابك، تعرف مكافأة شهرك.

**غاب طالب، فهل لي مكافأة عنه؟** نصفها: تأخذ نصف نصيبك عنه في تلك الحصة.

**تأخرت مرة فدرّس بديل مكاني، فهل فقدت فصلي؟** لا. فقدت مكافأة تلك الحصة فقط، ولا تفقد الفصل إلا إذا تكرر ذلك بعد إنذارات.

**ماذا أحتاج لأدرّس؟** اتصالًا جيدًا بالإنترنت، وحاسوبًا أو جهازًا لوحيًّا فيه كاميرا وميكروفون، ومكانًا هادئًا. ولا تحتاج إلى تثبيت شيء غير تطبيق الأكاديمية.

**هل يمكنني أن أدرّس في مكان آخر أيضًا؟** نعم، ما دامت ساعاتك هناك لا تتعارض مع ساعات الأكاديمية. الممنوع هو أن تدرّس حصتين في اللحظة نفسها.

**هل يمكن أن تتغير هذه المبالغ؟** نعم، قد تراجعها الإدارة، لكنك ستُبلَّغ قبل ذلك، ولن يُمسّ أي شهر عملت فيه.$lettre_texte$),
('ar', '2026-11-21', 14, 'p14',
 $lettre_texte$لتأخذ قرارك$lettre_texte$,
 $lettre_texte$**واصل معنا إذا** قبلت أن تكون مكافأتك على كل طالب، وأن تنتظر فصلك الأول وقد يطول ذلك، وأن تلتزم بموعد كل حصة، وأن تعرّف بنفسك، وأن تصبر على أسر لم تعرف بعد قدر معلّم القرآن.

**ولا تواصل إذا** كنت تبحث عن دخل ثابت من أول يوم، أو لا تستطيع الالتزام بمواعيد منتظمة، أو لا تتبنّى الالتزام الديني للأكاديمية.

وفي الحالتين، جزاك الله خيرًا على استجابتك لندائنا.

إدارة أكاديمية الرواية

#Ra_staff$lettre_texte$);

-- en : 14 parties, version 2026-11-21.
INSERT INTO private.lettre_candidats_parties (langue, version, rang, code, titre, corps) VALUES
('en', '2026-11-21', 1, 'p1',
 $lettre_texte$Why this guide reached you$lettre_texte$,
 $lettre_texte$Assalamu alaykum wa rahmatullahi wa barakatuh.

The Prophet ﷺ said: « خيركم من تعلّم القرآن وعلّمه », "The best of you are those who learn the Qur'an and teach it" (al-Bukhari). The people of the Qur'an hold a special place. When you teach it, you carry the words of Allah to a child's heart.

Yes, this work is paid, and there is nothing wrong with that. But the real reward is with Allah. Keep that intention in mind as you read.

This guide reached you because you applied, on your own, to teach at Rewayah Academy, and you accepted our conditions.

You applied without knowing our name, the pay, or the people behind the academy. We kept all of that quiet on purpose. You came anyway. That touched us.

Your messages taught us something. Some of you think you are the ones who need us. It is the other way round. We need you. Children who have no Qur'an class near them need you. Their families need you. The whole Ummah needs you. Having you with us is an honour for us.

So we owe you the whole truth: who we are, how much you will earn, how many hours you will give, what we expect from you, and what is hard in this work.

Read to the very end. Then you will know whether you want to continue with us. Both answers deserve respect.$lettre_texte$),
('en', '2026-11-21', 2, 'p2',
 $lettre_texte$Who we are$lettre_texte$,
 $lettre_texte$We are **Rewayah Academy**.

We are a registered company: **Rewayah Academy Ltd**, registered in England and Wales under number **16624644**. Our office is at 71-75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom. Anyone can check this on the UK public company register (Companies House).

The academy started almost three years ago. Before that, each of us had been teaching the Qur'an for years.

Most of our students are Muslims who live in countries where Muslims are a minority. They are far from the places where you find a Qur'an class in every neighbourhood.

For three years, the same problem kept coming back. A student wanted to learn, and we did not have the right teacher. So we had to say no, or ask them to wait.

This time we do it the other way round: **teachers first, then students**. We promise nothing to a family until our teachers are ready.

So we called on the men and women of the Qur'an. More than 2,000 people have answered so far. On the first day, so many came that our server went down. New applications still arrive every day, from the Gulf, from Africa, from Europe, from more than 50 nationalities. You are one of them.

### How we teach

No Zoom, no Meet, no WhatsApp. The academy has its own app, with its own video classroom.

Here, a student joins **a class**. Think of a class at your school or university: fixed hours, the same students, its own tools, one teacher. We even have the bell that rings at the end of the lesson.

Men teach boys and men. Women teach girls and women. There is one exception: to save a lesson, a substitute of the other gender may teach that day (see part 6).$lettre_texte$),
('en', '2026-11-21', 3, 'p3',
 $lettre_texte$What you will teach$lettre_texte$,
 $lettre_texte$The app has one purpose: **the Qur'an**.

A beginner starts with **the basics**, in four steps:
1. The letters.
2. Reading with the vowel marks.
3. Reading from the Mushaf.
4. Al-Fatiha and the short surahs, from An-Nas to Az-Zalzalah.


Along the way, the student learns the simple rules of tajwid: first by copying, then by learning the name of the rule. The youngest also learn the words of the prayer and how to make wudu.

At the end of the basics, the student takes an exam. Then they continue with the Qur'an: reading all of it, or memorising it.

You do not have to write the programme. The academy sets the steps, the goals and the dates, lesson by lesson. How you explain is up to you. In your class, you decide.

**The teaching language.** You explain in your students' language: French, English, Arabic, Pulaar, Portuguese, and others. A class of Arabic speakers gets an Arabic-speaking teacher. But many of our students do not understand Arabic yet. If you speak another language as well, more classes open to you.

**What about other subjects?** Fiqh, aqidah and detailed seerah are not taught here. The academy has another platform for Islamic studies. For now it works only in French and Pulaar. We will tell you about it when it opens to everyone.$lettre_texte$),
('en', '2026-11-21', 4, 'p4',
 $lettre_texte$Your pay$lettre_texte$,
 $lettre_texte$One rule: **you are paid for each student**. More students, more pay. No students, no pay.

Of what each student pays, almost half goes to you:
- **47%** in an adult class;
- **about 45%** in a children's class.

|  | Children's class (ages 6 to 17) | Adult class |
| --- | --- | --- |
| Lessons | 3 a week, 1 hour each | 3 a week, 1 hour 30 each |
| Break in the lesson | 5 minutes | 10 minutes |
| Your hours | 3 hours a week, about 13 hours a month | 4 hours 30 a week, about 19 hours 30 a month |
| Students in the class | 3 to 5, never more than 5 | 3 to 6, never more than 6 |
| What the student pays each month | $55 | $65 |
| Your share, per student, each month | about $24 | about $30 |
| Small class (3 students) | about $72 a month | about $90 a month |
| Full class | 5 x $24 = about $120 a month | 6 x $30 = about $180 a month |


Amounts are in US dollars. They assume the students come to every lesson.

The academy sometimes gives a family a discount: several children enrolled, a new Muslim, and other cases. **These discounts never touch your share.** The academy pays for them itself.

### The lowest and the highest

For **one** class, expect between **$70 and $180 a month**. Per hour, that is about $9 for a full class and about $5 for a class of 3.

You can have several classes, if your hours allow it and there are classes for you. For example: two full children's classes and one full adult class make 120 + 120 + 180 = $420 a month, for 10 hours 30 of teaching a week.

This example is not a promise. You may also go months without a class, and so without pay (see part 7).

### Why 47% for adults and 45% for children?

With an adult, almost everything happens during your lesson. With a child, the academy adds follow-up after the lesson, so the parents know where their child is and can help at home. That follow-up has a cost.

### Why not more?

Because the academy is expensive to run. With the other half, it pays for the video classroom servers, the app and the people who build it, card payment fees, sending your pay, accounting, administration, following up the children, and the taxes every company must pay.

You will see this split, in percentages, in your teacher account. We have nothing to hide.$lettre_texte$),
('en', '2026-11-21', 5, 'p5',
 $lettre_texte$How and when you get paid$lettre_texte$,
 $lettre_texte$After each lesson, the app works out what you have earned. You can see it in your account.

Your total for the month is sent to you **by the 5th of the next month at the latest**, by international transfer (Wise) or another method that works in your country. The academy pays the transfer fees. In a few countries, banks block these transfers. If that is your case, we will tell you, and we will look with you for a permitted method.

If you get a class in the middle of a month, you are paid for the lessons left in that month, not for the whole month.

### What makes your pay go up or down

Two teachers do not earn the same. Here is why.
- **The number of students.** A class of 3 earns less than a class of 5.
- **The number of classes** you have.
- **Student absences.** If a student misses a lesson, you get half of your share for that student for that lesson, not the full share. We chose this so that everyone cares about keeping their students present.
- **Students leaving.** If your students leave the class one by one, your pay goes down with them. A student stays where they make progress and feel respected. Not every departure will be your fault. But it is a real risk, so think about it before you commit.
- **Student holidays.** A family can pause a student for a month. During that month, you are not paid for that student.
- **Academy closures.** No lessons at the end of Ramadan and during Eid al-Fitr (about 20 days), or around Eid al-Adha (10 days). No lessons, no pay.
- **Your own absences.** A lesson taught by a substitute is paid to the substitute.
- **The end-of-lesson note.** At the end of the lesson, you record in a few taps what the class covered and where it stopped. It takes less than 20 seconds. Until that note is in, the month's pay waits.$lettre_texte$),
('en', '2026-11-21', 6, 'p6',
 $lettre_texte$Being on time, being replaced, being away$lettre_texte$,
 $lettre_texte$The academy does not accept a lack of punctuality. Here is why.

We are strict with families. A student who misses a lesson still pays for the month and catches up alone. So we must keep our side: **when the lesson starts, there is a teacher in the room. Always.**

### If you are late

This is what the app does, minute by minute.
1. **20 minutes before the lesson**, the room opens. You can go in and get ready.
2. **At the start time**, if you are not in, you get a reminder.
3. **3 minutes later**, a warning: if you do not come in, the lesson will be given to someone else.
4. **8 minutes later**, it is too late for this lesson. An alert goes to every teacher who is online.
5. A substitute accepts and enters the room, usually in less than a minute. The goal: the students have their teacher **no later than 11 minutes after the start time**.


If several teachers accept at the same moment, the app first picks someone of the same gender as the class (a man for men, a woman for women), then someone who speaks the class's language. Otherwise, the first one available. So a man may teach a women's class, or the other way round, for that lesson only.

**The pay for that lesson goes to the substitute, 100%.** You get nothing for it.

### What you keep, what you risk

Being replaced once does not cost you your class. It stays yours. The substitute cannot enter it again after their lesson.

But if it happens again and again, you get warnings. If it continues, the class goes to someone else.

### If you need to be away

A trip, a family event, an illness, may Allah protect us: it happens to everyone. Tell the management **beforehand**, with the day you leave and the day you come back.

A substitute takes your class while you are away and is paid for those lessons. When you come back, your class is yours again.

If you do not come back on the day you gave, you lose that class. You do not lose your place at the academy: you stay with us, you say you are available, and another class can be given to you later.

### If you are the substitute

Every lesson you teach as a substitute is paid. These earnings add up in your account. They are sent to you once they reach a minimum amount set by the management, so we avoid transfers of a few dollars.$lettre_texte$),
('en', '2026-11-21', 7, 'p7',
 $lettre_texte$After the interview: what really happens$lettre_texte$,
 $lettre_texte$Many of you think: "I pass the interview, and the next day I have a class." **No.** These are the steps.
1. **Your file is accepted and the interview goes well.** You get access to the teacher account and an official ID number. From then on, a class can be given to you.
2. **You are trained on the app.** The academy shows you how the classroom works.
3. **You wait for a class.** A few days, or several months.
4. **A class is given to you.** You get a message, and the class appears on your home page.


### Why do you have to wait?

We do not give classes at random. Everything must match between you and the students who enrol:
- **day and time**: students choose a time, and you must be free then;
- **language**: you must speak the students' language;
- **gender**: a man for boys and men, a woman for girls and women;
- **experience**: young beginners, adults and memorisation are not the same job.


An example. Twelve students enrol this week: eight little girls who speak French, in the evening in Europe, and four men who speak English, in the morning. So we need French-speaking women teachers free in the evening, and an English-speaking man free in the morning. An excellent teacher who fits neither case will wait for the next enrolments.

Classes open all year round, not only at the start of the month.

**Our advice: do not leave anything for us.** Keep your job, continue your studies, check your email and the app. And make du'a.

### What if there are not enough students for 2,000 teachers?

That can happen. At the start, it is even likely. We cannot give everyone a class right away.

If you are accepted and have no class, you stay with us. You can:
- **be a substitute**: teach for a teacher who is ill, away or late, and be paid for every lesson;
- **wait** for a class to open or become free.


### What about one-to-one lessons?

Many people ask us for one-to-one lessons: one teacher for one student. The academy is looking at offering them, alongside classes. We give no date.

We have tried this model before. It showed its limits, and it is much harder than people think, for the teacher and for the student. We will only open it once we know how to do it well.$lettre_texte$),
('en', '2026-11-21', 8, 'p8',
 $lettre_texte$Why we ask for your ID and your photo$lettre_texte$,
 $lettre_texte$Several of you have asked about this. It is a fair question. Here is a straight answer.

The internet has all kinds of people. And we have students as young as 6.

Think about what a teacher sees. They see the child's face on video. They hear the child's voice. They know the child's name, age and timetable. They talk with the child three times a week, and the child trusts them.

Now imagine that place given to just anyone. This is what can happen:
- **Someone who lies about who they are.** A fake name, a fake certificate, and no one to find on the day there is a problem.
- **Someone who is after children, not the Qur'an.** Such people exist. They win a child's trust little by little, then try to talk to the child alone, away from the parents.
- **Someone who films or takes pictures.** A child's image and voice can be copied, kept and shared.
- **Someone who was sent away elsewhere** for serious behaviour, and comes back under another name.
- **Someone who passes the interview, then has another person teach** in their place.
- **Someone who wants to slip other ideas** into children's minds, in the name of the Qur'an.


Just one of these cases means a hurt child, a broken family, and trust in the whole academy gone. Honest teachers, meaning you, would pay the price too.

There is also the law. Our students live in many countries. Child protection laws require us to know exactly who we are trusting a child to. And to send you your pay, the bank requires your real name.

**What we do with your documents.** Only the management sees them. They are never shown to students or families. If you withdraw your application, you can ask for them to be deleted.

**What we ask of you in return.** Never ask a student for their number or any other way to reach them. Never contact a student outside the app. Do not film or photograph the class. This rule has no exceptions.

A parent trusts us with what they hold most dear. Showing who you are is the first step of trust. If you were that parent, you would ask for it too.$lettre_texte$),
('en', '2026-11-21', 9, 'p9',
 $lettre_texte$What we require, and what is hard$lettre_texte$,
 $lettre_texte$### Who we have turned down so far

The academy is Sunni, openly, on the way of Ahl as-Sunnah. It stands by its values. Anyone who works against them has no place among us.

So far, we have turned down only two kinds of applications:
- people who did not sign **the religious commitment**. This text asks you to respect the Qur'an, the Sunnah, all the Companions of the Prophet ﷺ, first of all the four rightly guided caliphs, and the righteous early generations;
- people whose appearance clearly went against the rules of the religion: a haircut forbidden in Islam, or clothing that does not respect those rules.


Why? Because a child learns first by watching their teacher. Our children grow up surrounded by every idea of this age. They are the hope of tomorrow, and they are easily shaken. Choosing their teacher well is our first duty.

### The difficulty you will face

We have known these families for years. We must warn you about one thing.

Many families see a lesson as something they bought. They feel like customers, and to them the teacher is a seller. And a customer thinks they are always right. You will feel it in how they speak, write and complain.

We know this is wrong. The teacher of the Qur'an deserves respect (له حرمته). But they do not know it yet. No one has taught them.

It is up to you to teach them, with wisdom and kind words (بالحكمة والموعظة الحسنة), and with patience. Here you are not only a teacher. You are first of all a caller to Allah (داعية).

An example. A father writes to you sharply: "I pay, so my son must move faster." You can take offence and answer in the same tone. Or you can calmly show him where his son is, what he should revise at home, and invite him to listen to his son recite. In the first case, you lose a student. In the second, you often win a whole family.

We have seen it many times: when the teacher is wiser and more patient than the student, things work out in the end. If this patience already feels heavy to you, this work is not for you. It is better to know that today.$lettre_texte$),
('en', '2026-11-21', 10, 'p10',
 $lettre_texte$The academy sees what happens in class$lettre_texte$,
 $lettre_texte$We would rather tell you now than later.

**The app records when you come in and go out**, and the same for the students. So you do not keep any attendance register: the app does it for you.

**It measures your connection during the lesson**: good, weak or lost. It keeps no sound and no image. If a family complains about a lesson, the academy knows where the problem came from, and you are not blamed unfairly.

**A spot check can happen without notice.** A member of the management enters the room. You do not see them, and they have no microphone and no camera. When a woman is teaching, the visit is always made by a woman from the team, never by a man. The visitor looks at one thing: is the teacher really working with the students?

**You cannot teach two lessons at the same time.** The visitor sees it. And if you leave the room for more than 30 seconds during your lesson, the app takes you out and tells the management.

For everything else, you are free. The academy does not choose a room in your home for you, a position, or a background. It asks for two things: a quiet place and a good connection. Without them, the students suffer.$lettre_texte$),
('en', '2026-11-21', 11, 'p11',
 $lettre_texte$Praxis, our assistant$lettre_texte$,
 $lettre_texte$There are more than 2,000 of you. You speak dozens of languages, you live in every time zone, and your messages arrive day and night. Our team cannot answer each of you fast enough.

So we created **Praxis**, an artificial intelligence assistant. Praxis is not a person, and will never pretend to be one.
- **What Praxis does**: answers common questions, explains things, and tells you where a request stands.
- **What Praxis does not do**: decide anything. Praxis does not accept or turn down anyone, does not give classes, and does not touch pay.
- **Who directs Praxis**: the management. Praxis only acts on a task the management gives.


Where are we today? We started testing Praxis. It made some mistakes, so we paused it. We are studying its answers to adjust it, then we will start it again. Some of you may already have received a message from it.

When it is back, if its answer is not enough for you, say so in your message: a member of the team will take over.$lettre_texte$),
('en', '2026-11-21', 12, 'p12',
 $lettre_texte$If this is not for you$lettre_texte$,
 $lettre_texte$You are free to leave at any time, without giving a reason.

Rewayah Academy is an English company. The law requires it to respect your right to withdraw. You can withdraw your application and ask for your account and your data to be deleted. After that, you will receive no more messages from the academy. If you change your mind, you can restore your application yourself within 7 days of withdrawing it.

To do this, write to **support@rewayahacademy.com**.$lettre_texte$),
('en', '2026-11-21', 13, 'p13',
 $lettre_texte$Your questions$lettre_texte$,
 $lettre_texte$**I have registered. Am I already a teacher at the academy?** Not yet. You are a candidate. Your file still has to be reviewed, then comes the interview.

**Do I have to pay to be accepted or to be trained?** No. Nothing, ever. If anyone asks you for money in our name, it is a fraud: tell us.

**How long will I wait for a class?** We do not know, and we will not give you a date we might not keep. It depends on the students who enrol, your hours, your language and your experience.

**What time will my lessons be?** At the time chosen by the students of the class, the same every week. You will only be given a class if its time suits you. The app shows every time in your own time zone, then in Makkah time, which is the academy's clock.

**How much will I earn, exactly?** About $24 a month for each child and about $30 a month for each adult, if they come to every lesson. Count your students, multiply, and you have your month.

**A student is absent. Am I paid for them?** Half. You get half of your share for that student for that lesson.

**I was late once and someone replaced me. Have I lost my class?** No. You lost the pay for that lesson. You only lose the class if it keeps happening, after warnings.

**What do I need to teach?** A good internet connection, a computer or a tablet with a camera and a microphone, and a quiet place. Nothing to install except the academy's app.

**Can I teach somewhere else at the same time?** Yes, as long as your other hours do not clash with the academy's. What is not allowed is teaching two lessons at the same moment.

**Can the amounts change?** Yes, the management can review them. You will be told beforehand, and a month you have already worked will never be touched.$lettre_texte$),
('en', '2026-11-21', 14, 'p14',
 $lettre_texte$To decide$lettre_texte$,
 $lettre_texte$**Continue with us if** you accept being paid for each student, possibly waiting a long time for your first class, being on time for every lesson, showing who you are, and being patient with families who do not yet know the rank of the Qur'an teacher.

**Do not continue if** you are looking for a fixed income right away, if you cannot keep a regular timetable, or if the academy's religious commitment is not yours.

Either way, may Allah reward you for answering our call.

The management of Rewayah Academy

#Ra_staff$lettre_texte$);

DO $controle$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.lettre_candidats_parties t WHERE t.version = '2026-11-21' AND t.langue = 'ar') <> 14
     OR (SELECT pg_catalog.count(*) FROM private.lettre_candidats_parties t WHERE t.version = '2026-11-21' AND t.langue = 'en') <> 14 THEN
    RAISE EXCEPTION 'GUIDE-ARABE-NATIF : il faut 14 parties par langue';
  END IF;
  IF EXISTS (SELECT 1 FROM private.lettre_candidats_parties n
              WHERE n.version = '2026-11-21' AND n.langue IN ('ar', 'en')
                AND NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties f
                                 WHERE f.langue = 'fr' AND f.version = '2026-11-20' AND f.code = n.code AND f.rang = n.rang)) THEN
    RAISE EXCEPTION 'GUIDE-ARABE-NATIF : les codes doivent etre ceux de la version francaise';
  END IF;
END
$controle$;
