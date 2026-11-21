-- GUIDE-PRAXIS-SANS-ETAT (21/11/2026) : la partie 11 du guide ne dit plus si Praxis est actif ou en pause (directeur,
-- 21/11/2026 : « ne mentionne pas son etat car ca varie d'un moment a l'autre et on ne peut pas a chaque fois modifier le
-- guide pour suivre »). Le paragraphe « Ou en est-il aujourd'hui ? » est retire ; la phrase sur la reprise par l'equipe reste.
--
-- LIVRE ICI : le corps de la partie p11 remplace, dans la version servie de chaque langue (fr 2026-11-20, ar et en 2026-11-21),
-- seulement si son empreinte est celle attendue. Texte de l'academie, aucune donnee de personne. Engendre depuis
-- docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-{fr,en,ar}.md ; ne pas retoucher a la main.
--
-- MOTS D'EFFACEMENT : ZERO. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t
                  WHERE t.langue = 'fr' AND t.version = '2026-11-20' AND t.code = 'p11' AND pg_catalog.md5(t.corps) = '69c0003b6cefafeb1d47c76180cb29fe') THEN
    RAISE EXCEPTION 'GUIDE-PRAXIS-SANS-ETAT : la partie 11 (fr) n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t
                  WHERE t.langue = 'en' AND t.version = '2026-11-21' AND t.code = 'p11' AND pg_catalog.md5(t.corps) = 'ff152c25c054b8763b49fcc749ce3485') THEN
    RAISE EXCEPTION 'GUIDE-PRAXIS-SANS-ETAT : la partie 11 (en) n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t
                  WHERE t.langue = 'ar' AND t.version = '2026-11-21' AND t.code = 'p11' AND pg_catalog.md5(t.corps) = '29c3b8258660fa7141459445141cf10e') THEN
    RAISE EXCEPTION 'GUIDE-PRAXIS-SANS-ETAT : la partie 11 (ar) n''est pas celle attendue ; rien n''est modifie';
  END IF;
END
$preflight$;

UPDATE private.lettre_candidats_parties SET corps = $lettre_texte$Vous êtes plus de 2 000. Vous parlez des dizaines de langues, vous vivez sous tous les fuseaux horaires, et vos messages arrivent jour et nuit. Notre équipe ne peut pas répondre à chacun assez vite.

Nous avons donc créé **Praxis**, un assistant d'intelligence artificielle. Ce n'est pas une personne, et il ne se fera jamais passer pour une personne.
- **Ce qu'il fait** : il répond aux questions qui reviennent, il donne des précisions, il vous dit où en est une démarche.
- **Ce qu'il ne fait pas** : il ne décide rien. Il n'accepte ni ne refuse personne, il ne donne pas de classe, il ne touche pas à la paie.
- **Qui le dirige** : la direction. Il n'agit que si elle lui confie une mission.


Si sa réponse ne vous suffit pas, dites-le dans votre message : un membre de l'équipe prendra la suite.$lettre_texte$
 WHERE langue = 'fr' AND version = '2026-11-20' AND code = 'p11' AND pg_catalog.md5(corps) = '69c0003b6cefafeb1d47c76180cb29fe';

UPDATE private.lettre_candidats_parties SET corps = $lettre_texte$There are more than 2,000 of you. You speak dozens of languages, you live in every time zone, and your messages arrive day and night. Our team cannot answer each of you fast enough.

So we created **Praxis**, an artificial intelligence assistant. Praxis is not a person, and will never pretend to be one.
- **What Praxis does**: answers common questions, explains things, and tells you where a request stands.
- **What Praxis does not do**: decide anything. Praxis does not accept or turn down anyone, does not give classes, and does not touch pay.
- **Who directs Praxis**: the management. Praxis only acts on a task the management gives.


If its answer is not enough for you, say so in your message: a member of the team will take over.$lettre_texte$
 WHERE langue = 'en' AND version = '2026-11-21' AND code = 'p11' AND pg_catalog.md5(corps) = 'ff152c25c054b8763b49fcc749ce3485';

UPDATE private.lettre_candidats_parties SET corps = $lettre_texte$أنتم أكثر من 2000، تتكلمون عشرات اللغات، وتعيشون في كل المناطق الزمنية، ورسائلكم تصل ليلًا ونهارًا. ولا يستطيع فريقنا أن يردّ على كل واحد بالسرعة المطلوبة.

لذلك أنشأنا **براكسيس** (Praxis)، وهو مساعد يعمل بالذكاء الاصطناعي. ليس إنسانًا، ولن يدّعي يومًا أنه إنسان.
- **ما يفعله**: يجيب عن الأسئلة المتكررة، ويوضّح، ويخبرك أين وصل طلبك.
- **ما لا يفعله**: لا يقرّر شيئًا؛ لا يقبل أحدًا ولا يرفضه، ولا يُسند فصلًا، ولا علاقة له بالمكافآت.
- **من يوجّهه**: الإدارة، ولا يعمل إلا فيما تكلّفه به.


وإن لم يكفك جوابه فاذكر ذلك في رسالتك، وسيتابع معك أحد أعضاء الفريق.$lettre_texte$
 WHERE langue = 'ar' AND version = '2026-11-21' AND code = 'p11' AND pg_catalog.md5(corps) = '29c3b8258660fa7141459445141cf10e';

DO $controle$
BEGIN
  IF EXISTS (SELECT 1 FROM private.lettre_candidats_parties t
              WHERE t.code = 'p11' AND ((t.langue = 'fr' AND t.version = '2026-11-20') OR (t.langue IN ('ar', 'en') AND t.version = '2026-11-21'))
                AND (t.corps LIKE '%pause%' OR t.corps LIKE '%paused%' OR t.corps LIKE '%أوقفناه%')) THEN
    RAISE EXCEPTION 'GUIDE-PRAXIS-SANS-ETAT : la partie 11 parle encore d''une pause';
  END IF;
END
$controle$;
