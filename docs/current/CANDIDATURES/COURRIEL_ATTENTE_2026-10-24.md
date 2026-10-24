# Courriel d'attente aux candidats enseignants (B3.1)

Décidé par le pilotage le 24/10/2026 (`docs/orchestration/PILOTAGE-BOUCLES-2026-10-24.md`,
Boucle 3). Texte validé par le directeur le 24/10 (soir) avec deux ajouts : **il n'y a rien à payer**, et
**le message part en trois langues** (la plupart des candidats ne lisent pas le français).

## Envoi

- Expéditeur : `recrutement@rewayahacademy.com` (catégorie `recrutement`, non essentielle :
  lien de désinscription en un clic).
- Destinataires : les personnes des formulaires Google (feuille des candidats), une fois par
  adresse, adresses exclues respectées par `courriel_enfiler`, clé d'idempotence
  `candidat_attente:<adresse>` : jamais deux fois.
- Cadence : environ 200 par jour sur trois jours, pour rester loin des limites de Workspace et
  des filtres anti-pourriel. D'abord une copie au directeur sur une adresse test.
- Mise en oeuvre : un modèle `attente_candidat` dans `supabase/functions/_shared/courriel/`
  (déployé par la fusion dans `main`), puis une page de collage pour la mise en file (SQL
  fabriqué depuis la feuille, collé par le directeur dans la base de production).

## Langues (décision du directeur, 24/10)

Un seul courriel, trois parties l'une sous l'autre : arabe, français, anglais. Chaque partie est
courte et dit la même chose. Aucune donnée de langue n'est nécessaire dans la feuille.

## Objet

طلبكم للتدريس في أكاديمية رواية · Votre candidature à Rewayah Academy · Your application to Rewayah Academy

## Corps, partie française

Assalamou alaykoum wa rahmatoullah,

Vous avez rempli notre formulaire pour enseigner le Coran à Rewayah Academy. Nous vous
remercions de votre confiance et nous vous devons une réponse claire.

Vous êtes près de six cents à avoir répondu. Nous lisons chaque candidature une par une, et nous
n'ouvrons les classes qu'avec des enseignants que nous avons rencontrés. Cela prend du temps, et
nous préférons le prendre plutôt que de mal faire.

Ce qui va se passer :

1. D'ici trois semaines, vous recevrez un courriel personnel de notre part, dans tous les cas.
2. Si votre profil correspond à nos besoins du moment, ce courriel contiendra une invitation à
   créer votre compte dans l'application Rewayah, puis un entretien en visio avec la direction.
3. Si ce n'est pas le cas pour l'instant, nous vous le dirons aussi, et nous garderons votre
   candidature pour les prochaines ouvertures, sauf si vous préférez qu'on l'efface.

Il n'y a rien à payer, ni aujourd'hui ni plus tard : enseigner à Rewayah Academy est un
travail rémunéré, jamais une formation payante.

Vous n'avez rien à faire aujourd'hui. Inutile de nous écrire pour demander où en est votre
dossier : c'est nous qui reviendrons vers vous, à cette adresse.

Si vous ne souhaitez plus enseigner avec nous, un clic sur le lien en bas de ce message suffit,
sans justification.

Qu'Allah vous récompense pour votre démarche.

La direction
Rewayah Academy

## Corps, partie arabe (en premier dans le courriel)

السلام عليكم ورحمة الله وبركاته،

لقد ملأتم استمارتنا للتدريس في أكاديمية رواية. نشكركم على ثقتكم، ونحن مدينون لكم بجواب واضح.

عددكم يقارب ستمائة. نقرأ كل طلب على حدة، ولا نفتح الفصول إلا مع معلّمين قابلناهم. هذا يأخذ وقتًا،
ونفضّل أن نأخذه على أن نخطئ.

ما سيحدث:

١. خلال ثلاثة أسابيع ستصلكم رسالة شخصية منا، في كل الأحوال.
٢. إن كان ملفكم يناسب حاجتنا الحالية، ستحمل الرسالة دعوة لإنشاء حسابكم في تطبيق رواية، ثم مقابلة
   بالفيديو مع الإدارة.
٣. وإن لم يكن كذلك الآن، سنخبركم أيضًا، ونحتفظ بطلبكم للفتح القادم، إلا إذا فضّلتم حذفه.

لا يوجد أي مبلغ تدفعونه، لا اليوم ولا لاحقًا: التدريس في أكاديمية رواية عمل بأجر، وليس تكوينًا
مدفوعًا.

لا شيء عليكم فعله اليوم. لا داعي لمراسلتنا للسؤال عن ملفكم: نحن من سيعود إليكم على هذا العنوان.

إن لم تعودوا ترغبون في التدريس معنا، تكفي نقرة على الرابط أسفل الرسالة، دون تبرير.

جزاكم الله خيرًا على مبادرتكم.

الإدارة
أكاديمية رواية

## Corps, partie anglaise (en dernier)

Assalamu alaykum wa rahmatullah,

You filled in our form to teach Quran at Rewayah Academy. Thank you for your trust; we owe you a
clear answer.

Nearly six hundred of you replied. We read every application one by one, and we only open
classes with teachers we have met. This takes time, and we would rather take it than do it badly.

What happens next:

1. Within three weeks, you will receive a personal email from us, in every case.
2. If your profile matches our current needs, that email will invite you to create your account
   in the Rewayah app, then to a video interview with the management.
3. If not for now, we will tell you too, and keep your application for the next openings, unless
   you prefer that we delete it.

There is nothing to pay, now or later: teaching at Rewayah Academy is paid work, never a paid
training.

There is nothing to do today. No need to write to ask about your file: we will come back to you,
at this address.

If you no longer wish to teach with us, one click on the link at the bottom of this message is
enough, no explanation needed.

May Allah reward you for reaching out.

The management
Rewayah Academy
