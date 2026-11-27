-- PROSPECTION-V3, jour 1 (lundi 30/11/2026). « Vas-y » du directeur, 27/11/2026.
-- 1. Les 79 lettres longues mises en pause au 31/12 par le pilote (categorie direction, sans lien de
--    desinscription, ancien texte) sont annulees : elles ne partiront jamais.
-- 2. 100 lettres courtes (79 premieres lettres et 21 relances uniques de la vague du 22/11), categorie
--    `nouvelles` (non essentielle) par courriel_enfiler : jeton de desinscription, et rien n'est enfile pour
--    une adresse desinscrite. Langue = langue du texte. Heure d'envoi posee ligne par ligne (paquets de
--    taille aleatoire, heures ouvrables du destinataire). Une lettre sur cinq environ sans image (temoin).
-- Version compacte (27/11/2026) : chaque texte n'est ecrit qu'une fois (textes de docs/prospection/v3/lettres.py),
-- la lettre est composee ici ; le contenu envoye est le meme que celui de la premiere version de ce fichier.
-- Aucune suppression. Rejouable : la cle d'idempotence empeche un doublon.
DO $prospection$
DECLARE
  v_n integer;
  v_id uuid;
  r record;
BEGIN
  SELECT count(*) INTO v_n FROM public.courriels_sortants
   WHERE origine = 'manuel' AND modele = 'message_libre' AND categorie = 'direction'
     AND statut = 'en_attente' AND prochaine_tentative = '2026-12-31 08:00:00+00';
  IF v_n NOT IN (0, 79) THEN
    RAISE EXCEPTION 'prospection-v3 : % lettres en pause au lieu de 79, rien n''est fait', v_n;
  END IF;
  UPDATE public.courriels_sortants
     SET statut = 'annule', derniere_erreur = 'remplacee par la prospection v3 (directeur, 27/11/2026)'
   WHERE origine = 'manuel' AND modele = 'message_libre' AND categorie = 'direction'
     AND statut = 'en_attente' AND prochaine_tentative = '2026-12-31 08:00:00+00';

  FOR r IN
    WITH textes(cle, langue, type, sujet_a, sujet_b, texte) AS (VALUES
    ('fr', 'fr', 'lettre', $t$Pour vos élèves qui ne peuvent pas venir$t$, $t$Quand une famille ne peut pas suivre vos cours$t$, $t$Assalamu alaykum wa rahmatullah,

Vous enseignez le Coran sur place, et c’est le meilleur cadre quand il est possible. Mais certaines familles ne peuvent pas suivre : plus de place, des horaires impossibles, ou la mosquée trop loin.

Pour elles, Rewayah Academy propose des cours de Coran en direct, en ligne, en petite classe, avec le même enseignant trois fois par semaine. Nous ne remplaçons pas vos cours : nous allons là où ils ne peuvent pas aller.

Une famille vous vient à l’esprit ? Transmettez-lui ce lien :
{lien}

Le Prophète ﷺ a dit : « Celui qui indique le bien est comme celui qui le fait. » (at-Tirmidhî)$t$),
    ('fr_qc', 'fr', 'lettre', $t$Pour vos élèves qui ne peuvent pas venir$t$, $t$Quand une famille ne peut pas venir à vos cours de fin de semaine$t$, $t$Assalamu alaykum wa rahmatullah,

Vos cours de Coran de fin de semaine sont précieux. Mais certaines familles ne peuvent pas y venir : groupes complets, horaire qui ne convient pas, ou route trop longue l’hiver.

Pour elles, Rewayah Academy offre un complément en ligne : des cours de Coran en direct, en petite classe, avec le même enseignant trois fois par semaine. Nous ne remplaçons pas vos cours : nous rejoignons ceux qu’ils ne peuvent pas rejoindre.

Une famille vous vient à l’esprit ? Transmettez-lui ce lien :
{lien}

Le Prophète ﷺ a dit : « Celui qui indique le bien est comme celui qui le fait. » (at-Tirmidhî)$t$),
    ('en_uk', 'en', 'lettre', $t$For the families who can’t make it to your madrasah$t$, $t$When a child can’t get a place at your madrasah$t$, $t$Assalamu alaykum wa rahmatullah,

Your madrasah teaches the Qur’an in person, and that is the best way whenever it is possible. But you will know families who can’t make it: the classes are full, the evening times clash with work or school, or they live too far away.

Rewayah Academy is there for them: live online Qur’an classes in small groups, with the same teacher three times a week. We don’t replace your madrasah; we reach the children it can’t.

If a family comes to mind, simply pass on this link:
{lien}

The Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)$t$),
    ('en_na', 'en', 'lettre', $t$When a family can’t join your weekend school$t$, $t$For the families your program can’t fit$t$, $t$Assalamu alaykum,

Your center gives children something precious: learning the Qur’an together, in person. Still, some families can’t take part: the program is full, the schedule doesn’t work for them, or the drive is simply too long.

That’s where Rewayah Academy can help: live online Qur’an classes in small groups, with one dedicated teacher, three sessions a week. We complement what you do on site, for the families who can’t be there.

If a family comes to mind, just share this link with them:
{lien}

The Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)$t$),
    ('en_oc', 'en', 'lettre', $t$For the families who can’t make it to your madrasa$t$, $t$When a child misses out on a place$t$, $t$Assalamu alaykum wa rahmatullah,

Your centre teaches the Qur’an face to face, and nothing beats that when it’s possible. But some families miss out: the classes are full, the times don’t suit, or they live too far out.

Rewayah Academy is there for them: live online Qur’an classes in small groups, with the same teacher three times a week. We don’t replace your classes; we reach the children who can’t get to them.

If a family comes to mind, simply pass on this link:
{lien}

The Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)$t$),
    ('en_eu', 'en', 'lettre', $t$For the students who cannot come to your classes$t$, $t$When a family cannot attend your Qur’an classes$t$, $t$Assalamu alaykum wa rahmatullah,

You teach the Qur’an in person, and that is the best way when it is possible. But some families in your community cannot attend: there are no places left, the times do not fit, or the mosque is too far.

For them, Rewayah Academy offers live online Qur’an classes, in small groups, with the same teacher three times a week. We do not replace your classes; we reach those who cannot come to them.

If a family comes to mind, you only need to send them this link:
{lien}

The Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)$t$),
    ('ar', 'ar', 'lettre', $t$لطلابكم الذين لا يستطيعون الحضور$t$, $t$حين لا تجد أسرةٌ مكانًا في حلقاتكم$t$, $t$السلام عليكم ورحمة الله وبركاته،

جزاكم الله خيرًا على ما تبذلونه في تعليم أبناء الجالية كتاب الله، والتعليم الحضوري خير ما يكون إذا تيسّر. غير أنكم تعرفون أسرًا لا تستطيع الحضور: لامتلاء الأماكن، أو لتعارض المواعيد، أو لبعد المسافة.

ولهذه الأسر تقدّم أكاديمية الرواية دروسًا مباشرة في القرآن عن بُعد، في فصول صغيرة، مع المعلّم نفسه، ثلاث مرات في الأسبوع. لسنا بديلًا عن حلقاتكم، وإنما نصل إلى من لا تصل إليه.

فإن خطرت ببالكم أسرة في هذه الحال، فيكفي أن ترسلوا إليها هذا الرابط:
{lien}

قال رسول الله ﷺ: «الدَّالُّ عَلَى الخَيْرِ كَفَاعِلِهِ» (رواه الترمذي).$t$),
    ('relance_fr', 'fr', 'relance', $t$En une phrase$t$, $t$En une phrase$t$, $t$Assalamu alaykum,

Je vous ai écrit il y a quelques jours ; en une phrase : pour les familles de votre communauté qui ne peuvent pas suivre vos cours sur place, Rewayah Academy propose des cours de Coran en ligne, en complément. Le lien à leur transmettre :
{lien}$t$),
    ('relance_en', 'en', 'relance', $t$In one sentence$t$, $t$In one sentence$t$, $t$Assalamu alaykum,

I wrote to you a few days ago; in one sentence: for the families in your community who can’t attend your classes in person, Rewayah Academy offers live online Qur’an classes as a complement. The link to pass on:
{lien}$t$),
    ('relance_ar', 'ar', 'relance', $t$في سطر واحد$t$, $t$في سطر واحد$t$, $t$السلام عليكم ورحمة الله وبركاته،

كتبت إليكم قبل أيام، وخلاصة رسالتي: للأسر التي لا تستطيع حضور حلقاتكم، تقدّم أكاديمية الرواية دروسًا في القرآن عن بُعد، مكمّلةً لما تقومون به. وهذا الرابط لمن أردتم أن ترسلوه إليه:
{lien}$t$)
    ), langues(langue, signature, raison, alt) AS (VALUES
    ('fr', $t$BarakAllahu fikum,
Abdoulaye Mouhidine Sow
Directeur, Rewayah Academy$t$, $t$Vous recevez ce message parce que votre organisation enseigne le Coran et l’annonce publiquement.$t$, $t$Pour vos élèves qui ne peuvent pas venir. « Celui qui indique le bien est comme celui qui le fait. » Hadith rapporté par at-Tirmidhî, n° 2670. Rewayah Academy.$t$),
    ('en', $t$JazakAllahu khayran,
Abdoulaye Mouhidine Sow
Director, Rewayah Academy$t$, $t$You are receiving this message because your organisation teaches the Qur’an and says so publicly.$t$, $t$For the students who cannot come. “The one who guides to good is like the one who does it.” Hadith narrated by at-Tirmidhi, no. 2670. Rewayah Academy.$t$),
    ('ar', $t$بارك الله فيكم،
عبد الله محي الدين صو
مدير أكاديمية الرواية$t$, $t$وصلكم هذا البريد لأن مؤسستكم تعلّم القرآن وتعلن ذلك.$t$, $t$لطلابكم الذين لا يستطيعون الحضور. «الدال على الخير كفاعله» رواه الترمذي (2670). أكاديمية الرواية.$t$)
    ), plan(adresse, cle, segment, variante, image, temoin, quand, ref) AS (VALUES
    ('info@manawatumuslims.org.nz', 'en_oc', 'en_oc', 1, true, false, '2026-11-29T21:24:00+00:00'::timestamptz, 'manawatu-muslim-association-madrasah'),
    ('admin@iqra.school.nz', 'en_oc', 'en_oc', 0, true, false, '2026-11-29T21:24:32+00:00'::timestamptz, 'iqra-school-auckland'),
    ('uklatrust@gmail.com', 'relance_en', 'en_oc', 0, false, true, '2026-11-29T21:24:54+00:00'::timestamptz, 'umar-bin-khattab-learning'),
    ('info@umma.org.au', 'relance_en', 'en_oc', 1, false, true, '2026-11-30T02:07:00+00:00'::timestamptz, 'umma-centre-doncaster-east'),
    ('info@mwa.org.au', 'en_oc', 'en_oc', 0, true, false, '2026-11-30T02:07:45+00:00'::timestamptz, 'muslim-women-australia-lakemba'),
    ('enquiries@noorulislam.org.uk', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T10:08:00+00:00'::timestamptz, 'noor-ul-islam-madrassa'),
    ('iksbschule@gmail.com', 'ar', 'ar', 1, true, false, '2026-11-30T10:08:42+00:00'::timestamptz, 'islamische-kulturstiftung-basel-al'),
    ('info@igw-hessen.de', 'ar', 'ar', 0, true, false, '2026-11-30T10:08:58+00:00'::timestamptz, 'islamische-gemeinde-wiesbaden-e'),
    ('info@miconline.org.uk', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T10:10:09+00:00'::timestamptz, 'didsbury-mosque-quran-school'),
    ('icmalmo@mosken.se', 'en_eu', 'en_eu', 1, true, false, '2026-11-30T10:11:05+00:00'::timestamptz, 'islamic-center-i-malmo'),
    ('info@islamiccentre.ie', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T10:11:54+00:00'::timestamptz, 'islamic-centre-ireland-islamic'),
    ('bureau@acmp.one', 'fr', 'fr', 1, true, false, '2026-11-30T10:12:32+00:00'::timestamptz, 'centre-cultuel-et-culturel'),
    ('info@alhuda-hannover.de', 'ar', 'ar', 1, true, false, '2026-11-30T10:12:54+00:00'::timestamptz, 'al-huda-moschee-hannover'),
    ('ngo.alsanabil@gmail.com', 'ar', 'ar', 0, true, false, '2026-11-30T10:13:33+00:00'::timestamptz, 'al-sanabil-ry-arabian'),
    ('info@ige-erlangen.de', 'ar', 'ar', 0, false, true, '2026-11-30T10:14:04+00:00'::timestamptz, 'islamische-gemeinde-erlangen-e'),
    ('info@askf.dk', 'ar', 'ar', 1, true, false, '2026-11-30T10:14:30+00:00'::timestamptz, 'arabisk-sprog-og-kultur'),
    ('education@wimbledonmosque.org', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T10:15:39+00:00'::timestamptz, 'wimbledon-mosque-madrasa-londres'),
    ('isoc@soas.ac.uk', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T10:16:15+00:00'::timestamptz, 'soas-islamic-society-londres'),
    ('isoc@swansea-societies.co.uk', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T10:16:24+00:00'::timestamptz, 'swansea-university-islamic-society'),
    ('info@masjidalmuhsinin.de', 'relance_ar', 'ar', 0, false, false, '2026-11-30T10:16:24+00:00'::timestamptz, 'masjid-almuhsinin-leverkusen'),
    ('info@uppsalamoske.se', 'ar', 'ar', 1, false, true, '2026-11-30T10:16:48+00:00'::timestamptz, 'uppsala-moske-uppsala'),
    ('info@bbf-verein.de', 'ar', 'ar', 1, true, false, '2026-11-30T10:16:48+00:00'::timestamptz, 'bbf-verein-arabisch-schule'),
    ('muslim@csc.tcd.ie', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T10:18:05+00:00'::timestamptz, 'trinity-college-dublin-muslim'),
    ('onderwijs@moskeewageningen.nl', 'relance_en', 'en_eu', 0, false, false, '2026-11-30T10:22:00+00:00'::timestamptz, 'moskee-wageningen-wageningen'),
    ('eid.bristol@gmail.com', 'relance_en', 'en_uk', 1, false, false, '2026-11-30T11:39:00+00:00'::timestamptz, 'greenbank-masjid-bristol'),
    ('islam@imperial.ac.uk', 'en_uk', 'en_uk', 0, false, true, '2026-11-30T11:39:27+00:00'::timestamptz, 'imperial-college-islamic-society'),
    ('school@edmosque.org', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T11:41:14+00:00'::timestamptz, 'edinburgh-central-mosque-cours'),
    ('mail@attaqwa.co.uk', 'relance_en', 'en_uk', 1, false, false, '2026-11-30T11:41:15+00:00'::timestamptz, 'masjid-at-taqwa-leicester'),
    ('info@imanonline.de', 'ar', 'ar', 0, true, false, '2026-11-30T11:42:16+00:00'::timestamptz, 'iman-zentrum-e-v'),
    ('coran@mosqueedemontreuil.fr', 'fr', 'fr', 0, true, false, '2026-11-30T11:42:35+00:00'::timestamptz, 'grande-mosquee-de-montreuil'),
    ('info@alsalamcenter.se', 'ar', 'ar', 0, false, true, '2026-11-30T11:44:20+00:00'::timestamptz, 'al-salam-moske-helsingborg'),
    ('info@alfaruq.de', 'ar', 'ar', 0, true, false, '2026-11-30T11:45:18+00:00'::timestamptz, 'islamisches-zentrum-essen-alfaruq'),
    ('info@masjidat-taqwa.co.uk', 'relance_en', 'en_uk', 1, false, false, '2026-11-30T11:45:30+00:00'::timestamptz, 'masjid-at-taqwa-bradford'),
    ('info@goldenmosque.org', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T11:46:09+00:00'::timestamptz, 'golden-mosque-lantern-academy'),
    ('info@arabische-schule-nour.ch', 'ar', 'ar', 1, true, false, '2026-11-30T11:47:00+00:00'::timestamptz, 'arabische-schule-nour-zurich'),
    ('info@masjidomar.de', 'ar', 'ar', 1, true, false, '2026-11-30T11:48:12+00:00'::timestamptz, 'masjid-omar-ibnualkatab-arabische'),
    ('wembleycentralmasjid@gmail.com', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T11:48:58+00:00'::timestamptz, 'wembley-central-masjid-madrasah'),
    ('info@iccuk.org', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T11:49:12+00:00'::timestamptz, 'london-central-mosque-islamic'),
    ('info@leedsisoc.com', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T11:49:30+00:00'::timestamptz, 'leeds-university-union-islamic'),
    ('info@islamischegemeinde-halle.de', 'ar', 'ar', 0, true, false, '2026-11-30T11:49:50+00:00'::timestamptz, 'islamisches-kulturcenter-halle-saale'),
    ('info@ikvsh.ch', 'en_eu', 'en_eu', 0, true, false, '2026-11-30T11:50:30+00:00'::timestamptz, 'islamischer-kulturverein-schaffhausen-ne'),
    ('info@kmab.org.uk', 'en_uk', 'en_uk', 0, false, true, '2026-11-30T11:51:34+00:00'::timestamptz, 'masjid-al-falaah-birmingham'),
    ('info@sanabel-schule.de', 'ar', 'ar', 1, true, false, '2026-11-30T11:52:52+00:00'::timestamptz, 'sanabel-e-v-sanabel'),
    ('charity@islamiccentre.org', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T11:53:06+00:00'::timestamptz, 'islamic-centre-leicester-madrassa'),
    ('isoclbu@gmail.com', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T11:54:35+00:00'::timestamptz, 'leeds-beckett-university-islamic'),
    ('info@al-nour.de', 'ar', 'ar', 0, true, false, '2026-11-30T11:54:45+00:00'::timestamptz, 'islamisches-zentrum-al-nour'),
    ('info@islamischer-bund.de', 'ar', 'ar', 0, true, false, '2026-11-30T11:55:00+00:00'::timestamptz, 'islamischer-bund-essen-e'),
    ('admission@darulhadis.org.uk', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T11:58:00+00:00'::timestamptz, 'darul-hadis-latifiah-hifz'),
    ('plymouthisoc@gmail.com', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T11:58:04+00:00'::timestamptz, 'university-of-plymouth-islamic'),
    ('info@tayyibun.com', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T12:02:00+00:00'::timestamptz, 'tayyibun-institute-children-s'),
    ('info@hayatzentrum.de', 'ar', 'ar', 1, true, false, '2026-11-30T12:02:23+00:00'::timestamptz, 'hayat-zentrum-e-v'),
    ('kontakt@wakffyn.dk', 'ar', 'ar', 0, true, false, '2026-11-30T12:21:00+00:00'::timestamptz, 'wakf-fyn-amalskole-odense'),
    ('baerum@islamskole.no', 'en_eu', 'en_eu', 1, true, false, '2026-11-30T12:21:52+00:00'::timestamptz, 'islamskole-brum-brum'),
    ('kontakt@alahibba.de', 'ar', 'ar', 1, true, false, '2026-11-30T12:22:40+00:00'::timestamptz, 'alahibba-moschee-alahibba-arabische'),
    ('islamic@royalholloway.su', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T12:22:48+00:00'::timestamptz, 'royal-holloway-islamic-society'),
    ('contact@mosquee-creteil.fr', 'relance_fr', 'fr', 0, false, false, '2026-11-30T12:23:10+00:00'::timestamptz, 'mosquee-sahaba-creteil'),
    ('admin@taiyabahmasjid.com', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T12:23:55+00:00'::timestamptz, 'taiyabah-masjid-madrasah-bolton'),
    ('info@abmreading.org', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T12:24:40+00:00'::timestamptz, 'abu-bakr-masjid-islamic'),
    ('salam.ev@web.de', 'ar', 'ar', 0, true, false, '2026-11-30T12:24:54+00:00'::timestamptz, 'salam-e-v-arabische'),
    ('info@almustafacentre.org.uk', 'relance_en', 'en_uk', 1, false, true, '2026-11-30T12:24:54+00:00'::timestamptz, 'al-mustafa-centre-al'),
    ('info@alamanah.de', 'ar', 'ar', 1, false, true, '2026-11-30T12:26:20+00:00'::timestamptz, 'deutsch-algerischer-kulturverein-al'),
    ('info@suleymaniye.org', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T12:27:04+00:00'::timestamptz, 'suleymaniye-mosque-london-madrasah'),
    ('ifb-ev@t-online.de', 'ar', 'ar', 0, true, false, '2026-11-30T12:27:32+00:00'::timestamptz, 'al-furqan-moschee-muhlheim'),
    ('mosqueedebayonne@gmail.com', 'relance_fr', 'fr', 1, false, true, '2026-11-30T12:27:36+00:00'::timestamptz, 'mosquee-de-bayonne-bayonne'),
    ('gambiacat@yahoo.es', 'en_eu', 'en_eu', 0, true, false, '2026-11-30T12:30:32+00:00'::timestamptz, 'gambia-asociacion-en-catalunya'),
    ('info@zbek.de', 'ar', 'ar', 1, true, false, '2026-11-30T12:31:38+00:00'::timestamptz, 'ibrahim-al-khalil-moschee'),
    ('info@belfastislamiccentre.org.uk', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T15:41:00+00:00'::timestamptz, 'belfast-islamic-centre-ecole'),
    ('admin@eic.org.uk', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T15:41:30+00:00'::timestamptz, 'european-islamic-center-oldham'),
    ('info@majlisedawatulhaq.org.uk', 'en_uk', 'en_uk', 0, false, true, '2026-11-30T15:42:28+00:00'::timestamptz, 'majlise-dawatul-haq-madrasah'),
    ('isoc@socs.universityofgalway.ie', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T15:44:16+00:00'::timestamptz, 'university-of-galway-islamic'),
    ('info@banburymadnimasjid.com', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T15:44:21+00:00'::timestamptz, 'banbury-madni-masjid-islamic'),
    ('islamic@qub.ac.uk', 'en_uk', 'en_uk', 1, false, true, '2026-11-30T15:45:10+00:00'::timestamptz, 'queen-s-university-belfast'),
    ('office@faizanemadina.org', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T15:46:48+00:00'::timestamptz, 'masjid-faizan-e-madina'),
    ('academy@swanseamosque.com', 'en_uk', 'en_uk', 1, false, true, '2026-11-30T15:47:54+00:00'::timestamptz, 'swansea-mosque-academy-swansea'),
    ('su-islamic@le.ac.uk', 'en_uk', 'en_uk', 0, true, false, '2026-11-30T15:48:14+00:00'::timestamptz, 'university-of-leicester-islamic'),
    ('info@hayesmuslimcentre.org.uk', 'relance_en', 'en_uk', 0, false, false, '2026-11-30T15:48:20+00:00'::timestamptz, 'hayes-muslim-centre-madrasah'),
    ('contact@kclisoc.org', 'en_uk', 'en_uk', 1, true, false, '2026-11-30T15:51:40+00:00'::timestamptz, 'king-s-college-london'),
    ('info@madinahcollege.uk', 'relance_en', 'en_uk', 0, false, true, '2026-11-30T15:53:50+00:00'::timestamptz, 'madinah-college-london-londres'),
    ('convertconnect@masjidtoronto.com', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:03:00+00:00'::timestamptz, 'mac-masjid-toronto-new'),
    ('info@mac-quebec.org', 'fr_qc', 'fr_qc', 1, true, false, '2026-11-30T19:03:46+00:00'::timestamptz, 'mac-centre-communautaire-de'),
    ('info@centrebadr.net', 'relance_fr', 'fr_qc', 0, false, false, '2026-11-30T19:04:24+00:00'::timestamptz, 'centre-islamique-badr-saint'),
    ('msamcgill@ssmu.ca', 'fr_qc', 'fr_qc', 1, true, false, '2026-11-30T19:04:40+00:00'::timestamptz, 'muslim-students-association-of'),
    ('weekendschool@isnacanada.com', 'relance_en', 'en_na', 1, false, false, '2026-11-30T19:06:03+00:00'::timestamptz, 'isna-canada-weekend-school'),
    ('info@alrawdah.ca', 'fr_qc', 'fr_qc', 0, false, true, '2026-11-30T19:06:35+00:00'::timestamptz, 'mosquee-al-rawdah-montreal'),
    ('info@ummahsociety.ca', 'en_na', 'en_na', 1, false, true, '2026-11-30T19:08:00+00:00'::timestamptz, 'ummah-society-ummah-masjid'),
    ('services@iccbrossard.com', 'relance_fr', 'fr_qc', 0, false, false, '2026-11-30T19:08:48+00:00'::timestamptz, 'centre-culturel-islamique-de'),
    ('info@bictoronto.com', 'en_na', 'en_na', 1, false, true, '2026-11-30T19:08:50+00:00'::timestamptz, 'bosnian-islamic-centre-toronto'),
    ('info@aaocanada.ca', 'en_na', 'en_na', 0, false, true, '2026-11-30T19:08:50+00:00'::timestamptz, 'afghan-association-of-ontario'),
    ('account@sabeelulfaoz.org', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:09:48+00:00'::timestamptz, 'islamic-association-of-indianapolis'),
    ('jamiomar@jamiomar.org', 'en_na', 'en_na', 0, false, true, '2026-11-30T19:10:20+00:00'::timestamptz, 'jami-omar-masjid-ottawa'),
    ('office@thewellspringschools.org', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:10:28+00:00'::timestamptz, 'nycmc-wellspring-schools-queens'),
    ('nislamnews@yahoo.com', 'en_na', 'en_na', 1, true, false, '2026-11-30T19:13:03+00:00'::timestamptz, 'nigerian-islamic-society-of'),
    ('namiccenter@gmail.com', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:13:11+00:00'::timestamptz, 'nigerian-american-muslim-integrated'),
    ('info@hadischool.org', 'en_na', 'en_na', 1, true, false, '2026-11-30T19:14:40+00:00'::timestamptz, 'hadi-school-of-excellence'),
    ('info@masjidhalton.com', 'relance_en', 'en_na', 0, false, true, '2026-11-30T19:14:54+00:00'::timestamptz, 'halton-islamic-association-rahmah'),
    ('bosnianislamiccenterstl@gmail.com', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:16:04+00:00'::timestamptz, 'bosnian-islamic-center-of'),
    ('principal@myannoor.org', 'en_na', 'en_na', 1, true, false, '2026-11-30T19:19:30+00:00'::timestamptz, 'annoor-islamic-school-wichita'),
    ('nmcdv@yahoo.com', 'en_na', 'en_na', 0, true, false, '2026-11-30T19:20:15+00:00'::timestamptz, 'nigerian-muslim-council-of'),
    ('info@manarahfoundation.org', 'en_na', 'en_na', 1, true, false, '2026-11-30T19:21:03+00:00'::timestamptz, 'manarah-islamic-academy-whitehall'),
    ('convertcare@kanatamuslims.ca', 'en_na', 'en_na', 1, true, false, '2026-11-30T19:25:45+00:00'::timestamptz, 'kanata-muslim-association-convert')
    )
    SELECT p.adresse, t.langue, p.quand, 'prospection-v3:' || p.adresse AS cle_idem,
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'sujet', CASE WHEN p.variante = 0 THEN t.sujet_a ELSE t.sujet_b END,
        'corps', pg_catalog.replace(t.texte, '{lien}',
                   'https://rewayahacademy.com/' || t.langue || '/familles?ref=' || p.ref)
                 || pg_catalog.chr(10) || pg_catalog.chr(10) || l.signature,
        'langue_source', t.langue, 'raison', l.raison, 'campagne', 'prospection-v3',
        'type', t.type, 'segment', p.segment, 'temoin_sans_image', p.temoin,
        'image', CASE WHEN p.image THEN pg_catalog.jsonb_build_object(
                   'src', 'https://rewayahacademy.com/fr/assets/courriel-prospection-' || t.langue || '.png',
                   'alt', l.alt, 'largeur', 600, 'hauteur', 315) END)) AS donnees
      FROM plan p JOIN textes t ON t.cle = p.cle JOIN langues l ON l.langue = t.langue
  LOOP
    v_id := public.courriel_enfiler('nouvelles', 'message_libre', r.adresse, NULL, r.donnees, r.cle_idem, 'manuel', NULL);
    IF v_id IS NOT NULL THEN
      UPDATE public.courriels_sortants SET langue = r.langue, prochaine_tentative = r.quand WHERE id = v_id;
    END IF;
  END LOOP;
END;
$prospection$;
