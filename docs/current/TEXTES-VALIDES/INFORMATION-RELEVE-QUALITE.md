# Information sur le relevé de qualité de connexion (`salle.releve`)

- **Version** : `2026-11-11`
- **Statut** : **texte écrit par le lot RESEAU-PREUVE, sur délégation du directeur du 11/11/2026
  (« Je te laisse décider toi-même », puis « c'est toi qui joue ce rôle car ces lois sont publiques et
  accessibles […] on applique ce qui est là ») ; à faire confirmer par le directeur.** Ce n'est pas un
  texte validé par le directeur lui-même, ni un avis d'avocat.
- **Historique du 11/11/2026** : proposé le matin (180 jours, toute la classe) ; « validé par
  délégation » par le pilote en début d'après-midi dans une version à deux ans ; récrit en fin
  d'après-midi : retour à 180 jours, et **rien n'est gardé pour un élève mineur**
  (`docs/current/salle/DROIT-RELEVE-QUALITE.md` §10, point 3). Les phrases ont donc changé depuis la
  version que le pilote avait adoptée : elles disent ce que le serveur fait aujourd'hui.
- **Ce que le texte doit dire pour rester vrai** : trois mots d'état (bonne, faible, perdue) et le
  micro ; l'enseignant et les élèves adultes seulement ; rien pour un élève mineur ; ni son, ni image,
  ni adresse ; 180 jours ; la direction seule lit ; le droit de demander ses données et de s'opposer.
  Si une de ces règles change dans le code, ce texte change avant.
- **Où il est affiché** :
  - dans la salle, dans la lecture « En savoir plus » du bandeau « Visite de contrôle possible », à la
    suite du texte existant et sous son propre titre (`lib/features/salle_seance/information_controle.dart`,
    clés `salle.releve.*`) : les élèves (Interface guidée, élève mineur, élève adulte) ;
  - dans la politique de confidentialité de l'application, point 5 (`juridique.confidentialite.s5`),
    avec la base légale et le droit de s'opposer : tout le monde, enseignants et tuteurs compris.
  - **Les enseignants ne le lisent pas dans la salle** (ils n'ont pas la lecture « En savoir plus » sur
    leur bandeau, décision du 02/10/2026) : pour eux, la politique de confidentialité seulement.
- **Règle** : l'application affiche ces textes mot pour mot. Un test compare les clés à ce fichier
  (`test/features/salle_seance/information_releve_test.dart`) : on ne change l'un qu'avec l'autre.

---

## Français

### À l'élève adulte (`salle.releve.adulte`)

Titre : La connexion pendant la séance

Pendant une séance, l'application note si la connexion de l'enseignant et celle de chaque élève adulte sont bonnes, faibles ou perdues, et si leur micro est ouvert à ce moment-là. Elle n'enregistre ni le son ni l'image, et ne garde pas l'adresse de la connexion. Pour un élève mineur, elle ne garde rien. Ce relevé sert à comprendre ce qui s'est passé quand une séance est contestée. Il est gardé 180 jours, puis effacé. Seule la direction peut le lire. Vous pouvez demander à la direction les données qui vous concernent, et vous opposer à ce relevé.

### À l'élève mineur hors Interface guidée (`salle.releve.mineur`)

Pendant une séance, l'application note si la connexion de ton enseignant est bonne, faible ou perdue, et si son micro est ouvert à ce moment-là. Elle n'enregistre ni le son ni l'image. Sur ta connexion à toi, elle ne garde rien. Ce relevé est gardé 180 jours, puis effacé. Seule la direction peut le lire.

### À l'enfant, en Interface guidée (`salle.releve.guidee`)

Titre : Ta connexion pendant le cours

Pendant le cours, l'application regarde si ta connexion marche bien. Elle n'enregistre ni ta voix ni ton image, et elle ne garde rien sur ta connexion.

### Aux enseignants (aucune clé : pas affiché dans la salle)

Pendant une séance, l'application note si votre connexion est bonne, faible ou perdue, et si votre micro est ouvert à ce moment-là. Elle fait de même pour les élèves adultes, et ne garde rien pour un élève mineur. Elle n'enregistre ni le son ni l'image, et ne garde pas l'adresse de votre connexion. Ce relevé sert à comprendre ce qui s'est passé quand une séance est contestée. Il est gardé 180 jours, puis effacé. Seule la direction peut le lire. Vous pouvez demander à la direction les données qui vous concernent, et vous opposer à ce relevé. Il ne sert jamais à vous noter.

### Dans la politique de confidentialité, point 5 (`juridique.confidentialite.s5.blocs`, trois blocs ajoutés)

Le relevé de connexion. Pendant une séance, l'application note si la connexion de l'enseignant et celle de chaque élève adulte sont bonnes, faibles ou perdues, et si leur micro est ouvert à ce moment-là. Elle ne garde ni le son, ni l'image, ni l'adresse de la connexion. Ce relevé se fait automatiquement, vous n'avez rien à fournir. Pour un élève mineur, elle ne garde rien.

Ce relevé sert à vérifier ce qui s'est passé quand une séance est contestée. Base légale : notre intérêt légitime à répondre, faits à l'appui, à une contestation. Seule la direction peut le lire, et chaque lecture est notée. Il est gardé 180 jours, puis effacé. Il ne sert jamais à noter une personne, et aucune décision automatique n'en est tirée.

Vous pouvez vous opposer à ce relevé : écrivez-nous, nous vous répondrons.

---

## Arabe

Traduction du lot, non relue par une personne arabophone.

### `salle.releve.adulte`

العنوان : الاتصال أثناء الحصة

أثناء الحصة، يدوّن التطبيق هل اتصال المعلم واتصال كل طالب بالغ جيد أم ضعيف أم مقطوع، وهل الميكروفون مفتوح في تلك اللحظة. لا يسجّل الصوت ولا الصورة، ولا يحتفظ بعنوان الاتصال. أما الطالب القاصر فلا يحتفظ بشيء عنه. يفيد هذا السجل في فهم ما حدث حين يُعترض على حصة. يُحفظ 180 يومًا ثم يُحذف. لا يقرؤه إلا الإدارة. يمكنك أن تطلب من الإدارة البيانات التي تخصك، وأن تعترض على هذا السجل.

### `salle.releve.mineur`

أثناء الحصة، يدوّن التطبيق هل اتصال معلمك جيد أم ضعيف أم مقطوع، وهل ميكروفونه مفتوح في تلك اللحظة. لا يسجّل الصوت ولا الصورة. أما اتصالك أنت فلا يحتفظ بشيء عنه. يُحفظ هذا السجل 180 يومًا ثم يُحذف. لا يقرؤه إلا الإدارة.

### `salle.releve.guidee`

العنوان : اتصالك أثناء الحصة

أثناء الحصة، ينظر التطبيق هل اتصالك يعمل جيدًا. لا يسجّل صوتك ولا صورتك، ولا يحتفظ بشيء عن اتصالك.

---

## Reste à faire

- La confirmation du directeur.
- **Les enseignants dans la salle** : leur version n'y est pas affichée. Les textes n'imposent pas
  l'endroit, mais ils veulent l'information « au moment où les données en question sont obtenues »
  (RGPD, art. 13(1)) : la politique de confidentialité y répond ; un lien dans la salle y répondrait
  mieux. Proposition : ouvrir « En savoir plus » à l'enseignant avec ce seul texte. C'est revenir sur
  le choix du 02/10/2026 (« l'enseignant n'a pas de lien ») : au directeur de le dire.
- **L'avis de modification de la politique de confidentialité** (loi P-39.1, art. 8.2) : une annonce
  de la direction dans l'application avant d'installer le relevé.
- **La version des textes juridiques** (`2026-11-v1`) n'a pas été changée : elle sert à l'accord des
  candidats, et la monter sans changer le réglage du serveur le même jour bloque leur inscription
  (erreur déjà payée le 06/11). À faire par le pilote à la publication.
- Le site public a sa propre copie de la politique de confidentialité : elle n'a pas ces mentions.
