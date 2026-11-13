# Accord du journal des sorties de l'application

**Statut : PROPOSITION, à valider par le directeur.** Rédigé le 13/11/2026 par l'agent du lot
HORS-SALLE-2 (demande du directeur du 12/11/2026 au soir : « Toutes ses sorties de l'app doivent
être consignées sur le rapport : leur nombre total, fréquence, de quand jusqu'à quand. » ; règle du
11/11/2026 : rien n'est gardé pour un élève mineur sans l'accord d'un tuteur de son foyer,
`docs/current/salle/DROIT-RELEVE-QUALITE.md`, §10 point 3).

Le journal est **éteint** (`salle.sorties.journal_actif` = faux, réglage de la direction). Tant
qu'il l'est, la page de l'accord n'est proposée à personne et le serveur refuse tout accord. Il ne
s'allume qu'après la validation de ces textes par le directeur.

L'application affiche ces textes **mot pour mot** (clés `journalSorties.texte.*`) ; le test
`test/features/journal_sorties/texte_accord_sorties_test.dart` compare les clés à ce fichier, en
français et en arabe. Une version du texte est gardée avec chaque accord
(`salle.sorties.accord_version`, aujourd'hui `sorties-2026-11-v1`) : changer un mot demande une
nouvelle version, et les accords donnés sur l'ancienne ne valent plus.

Ce que les textes disent est vrai dans le code (`supabase/migrations/20261124200000_journal_sorties.sql`) :
heure de sortie, heure de retour et drapeau de la sortie de la salle, posés par le serveur ; ni motif,
ni application, ni donnée d'appareil ; lecture par le parent, l'élève lui-même, l'enseignant de la
séance (titulaire ou remplaçant) et la direction ; retrait au même endroit, qui arrête l'écriture.
**Ce qu'ils ne disent pas, parce que rien n'est décidé : la durée de conservation** (à décider par
le directeur ; aucune fonction d'effacement n'existe encore).

Aucune loi n'est citée dans le texte montré aux familles.

## Pour le parent (une carte par enfant mineur du foyer)

### Français

Les sorties de l'application pendant le cours

Ce qui est noté : chaque fois que votre enfant quitte l'application pendant une séance, l'heure où il la quitte, l'heure où il revient, et si cette absence l'a fait sortir de la salle. Rien d'autre : ni ce qu'il fait ailleurs, ni son écran, ni son image, ni sa voix.

Pourquoi : suivre l'attention de votre enfant pendant le cours, pour vous et pour son enseignant.

Qui peut le lire : vous, votre enfant, l'enseignant de la séance et la direction. Jamais les autres élèves ni leurs familles.

Vous pouvez retirer votre accord à tout moment, ici même. Dès que vous le retirez, plus rien n'est noté.

Sans votre accord, rien n'est noté et rien ne change pour le cours. Un élève qui reste trop longtemps hors de l'application sort de la salle, avec ou sans accord : cela ne garde rien.

Case, jamais précochée : J'accepte que les sorties de l'application de {prenom} pendant les séances soient notées.

### العربية

الخروج من التطبيق أثناء الدرس

ما يُسجَّل: في كل مرة يخرج فيها طفلك من التطبيق أثناء الحصة، وقت خروجه، ووقت عودته، وهل أدّى هذا الغياب إلى خروجه من القاعة. لا شيء غير ذلك: لا ما يفعله في مكان آخر، ولا شاشته، ولا صورته، ولا صوته.

لماذا: لمتابعة انتباه طفلك أثناء الدرس، لك ولمعلّمه.

من يمكنه قراءته: أنت، وطفلك، ومعلّم الحصة، والإدارة. ولا يقرؤه أبدًا الطلاب الآخرون ولا عائلاتهم.

يمكنك سحب موافقتك في أي وقت، من هنا. بمجرد سحبها، لا يُسجَّل أي شيء بعد ذلك.

دون موافقتك، لا يُسجَّل أي شيء ولا يتغيّر شيء في الدرس. الطالب الذي يبقى خارج التطبيق مدة طويلة يخرج من القاعة، بموافقة أو دونها: وهذا لا يحفظ أي شيء.

الخانة، غير مُعلَّمة مسبقًا: أوافق على تسجيل خروج {prenom} من التطبيق أثناء الحصص.

## Pour l'élève adulte autonome (pour lui-même)

Sans réponse de sa part, rien n'est noté (l'option la plus protectrice : son choix passe par le même
mécanisme que l'accord du parent ; un retrait vaut opposition).

### Français

Les sorties de l'application pendant le cours

Ce qui est noté : chaque fois que vous quittez l'application pendant une séance, l'heure où vous la quittez, l'heure où vous revenez, et si cette absence vous a fait sortir de la salle. Rien d'autre : ni ce que vous faites ailleurs, ni votre écran, ni votre image, ni votre voix.

Pourquoi : suivre votre attention pendant le cours, pour vous et pour votre enseignant.

Qui peut le lire : vous, l'enseignant de la séance et la direction. Jamais les autres élèves ni leurs familles.

Vous pouvez retirer votre accord à tout moment, ici même. Dès que vous le retirez, plus rien n'est noté.

Sans votre accord, rien n'est noté et rien ne change pour le cours. Si vous restez trop longtemps hors de l'application, vous sortez de la salle, avec ou sans accord : cela ne garde rien.

Case, jamais précochée : J'accepte que mes sorties de l'application pendant les séances soient notées.

### العربية

الخروج من التطبيق أثناء الدرس

ما يُسجَّل: في كل مرة تخرج فيها من التطبيق أثناء الحصة، وقت خروجك، ووقت عودتك، وهل أدّى هذا الغياب إلى خروجك من القاعة. لا شيء غير ذلك: لا ما تفعله في مكان آخر، ولا شاشتك، ولا صورتك، ولا صوتك.

لماذا: لمتابعة انتباهك أثناء الدرس، لك ولمعلّمك.

من يمكنه قراءته: أنت، ومعلّم الحصة، والإدارة. ولا يقرؤه أبدًا الطلاب الآخرون ولا عائلاتهم.

يمكنك سحب موافقتك في أي وقت، من هنا. بمجرد سحبها، لا يُسجَّل أي شيء بعد ذلك.

دون موافقتك، لا يُسجَّل أي شيء ولا يتغيّر شيء في الدرس. إذا بقيت خارج التطبيق مدة طويلة، تخرج من القاعة، بموافقة أو دونها: وهذا لا يحفظ أي شيء.

الخانة، غير مُعلَّمة مسبقًا: أوافق على تسجيل خروجي من التطبيق أثناء الحصص.
