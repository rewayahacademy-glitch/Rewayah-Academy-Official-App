# Politique de confidentialité et Praxis : proposition de texte (étape 12, niveau C)

- **Statut : PROPOSITION, à valider par le directeur.** Écrit par BE-PIECE le 17/11/2026, sur ordre du pilote. Ce
  n'est pas un texte validé, ni un avis d'avocat. **La politique publiée n'est pas touchée** : aucune clé de
  `assets/i18n/*.i18n.json`, aucun fichier de `lib/` ne change dans cette PR.
- **Pourquoi ce texte** : `SECRETAIRE-IA.md` §11 (« Données ») et `SECURITE-PRAXIS.md` §6 (« La politique de
  confidentialité mentionne l'assistant, validée par le directeur ») exigent qu'elle dise, **avant** que Praxis lise
  le message d'une personne réelle, qu'un assistant numérique lit les messages pour y répondre.
- **Quand il se publie** : le jour où le directeur allume Praxis, pas avant. Une politique de confidentialité ne décrit
  que des traitements réels (RGPD art. 12 et 13) : même règle que pour le relevé de connexion
  (`TEXTES-VALIDES/INFORMATION-RELEVE-QUALITE.md`, « ces trois blocs ne sont PAS dans l'application »). Avec le texte :
  montée de `VersionsJuridiques.version` (`lib/features/juridique/textes_juridiques.dart`, `2026-11-v1` aujourd'hui) et
  avis de modification aux personnes déjà inscrites.

## 0. Faux, bloqué ou non prouvé (en premier)

Ce texte **ne peut pas être publié tel quel** : six faits manquent ou sont faux dans le dépôt aujourd'hui. Chacun est
marqué `[À CONFIRMER]` dans les textes plus bas ou arbitré au §3.

1. **Le fournisseur d'IA n'est nommé nulle part dans le dépôt.** Praxis est utilisé depuis le chat Claude du
   directeur (ordre du pilote, 17/11) : les messages qu'il lit passent donc par ce fournisseur. Son nom exact, le
   contrat (ou les conditions du plan), l'usage de ces messages pour entraîner des modèles, leur durée de conservation
   chez lui, et le pays de traitement ne sont **pas connus ici**. Le texte dit « un fournisseur d'intelligence
   artificielle » ; il doit le **nommer** (comme la politique nomme Cloudflare) et dire si les messages quittent
   l'Union européenne (le point 6 actuel ne parle d'aucun transfert).
2. **La base légale n'est pas décidée.** Proposition : l'intérêt légitime de l'académie à répondre vite aux familles.
   Je ne suis pas juriste : le directeur tranche (intérêt légitime, ou exécution du contrat d'abonnement).
3. **Le droit de s'opposer n'a aucun mécanisme.** Le serveur ne sait pas exclure **une famille** de la lecture de
   Praxis. Le texte proposé **ne promet donc pas** d'exclusion. Si le directeur veut l'offrir, il faut d'abord un
   lot serveur (liste d'exclusion lue par `praxis_fil_refus`), puis une phrase de plus (§3, décision B).
4. **La durée de conservation du journal de Praxis n'est pas décidée.** `private.praxis_journal` est à ajout seul,
   sans purge : il garde le **texte que Praxis a lui-même envoyé** (3 000 signes au plus), l'outil, le résultat, l'heure
   et l'identifiant de la conversation, **jamais le texte d'une personne**. La politique dit « le temps nécessaire,
   pas davantage » : une durée chiffrée doit être décidée, et une purge écrite, avant que ce texte dise « 180 jours »
   ou autre chose.
5. **La mention « Assistant de l'académie · IA » n'existe pas encore dans les conversations** (case non cochée du
   §6 de `SECURITE-PRAXIS.md`, « Pilote Messagerie »). Le texte dit que Praxis est **indiqué comme tel** : il n'est
   vrai qu'une fois l'affichage livré. Ne pas publier avant.
6. **Les candidats ne sont lus aujourd'hui par aucun outil** (les conversations de candidature sont fermées à Praxis :
   cause `type_ferme`), ni les paiements (`profilPaiement`), ni les pièces d'identité. Le texte le dit parce que c'est
   vrai **aujourd'hui** ; il change **avant** toute extension de PX-2 (règle du relevé : « si une de ces règles change
   dans le code, ce texte change avant »).

## 1. Où vit la politique et où le texte s'insère

- Les textes : `assets/i18n/{fr,en,ar}.i18n.json`, clé `juridique.confidentialite` (titre, résumé, introduction, puis
  `s1` à `s10`, chacune avec `titre` et une liste `blocs`). Rendu : `lib/features/juridique/textes_juridiques.dart`.
- Endroits touchés (quatre ajouts, aucune phrase existante modifiée) :

| Point | Titre actuel | Ajout |
| :--- | :--- | :--- |
| `s3` | Pourquoi nous les utilisons | une ligne de liste |
| `s4` | Qui voit quoi | un bloc : l'assistant numérique |
| `s6` | Où sont vos informations | un bloc : le fournisseur d'intelligence artificielle |
| `s8` | Vos droits | une phrase après la liste, avant « Écrivez-nous » |

- Le point 2 (« Ce que nous recueillons ») ne change pas : l'assistant ne recueille rien de plus que ce que les
  conversations contiennent déjà ; il **lit** ce que la messagerie garde.
- Typographie à l'intégration : espace insécable avant « : ? ! ; » (tests `ponctuation_fr_test` et
  `typographie_fr_test`) ; isolats `⁨…⁩` autour des paramètres en arabe ; aucun tiret long.

## 2. Les textes

Vocabulaire : `mots-rewayah` (l'académie, la direction, Classe, vouvoiement). « Praxis » reste en lettres latines
dans les trois langues.

### Français

**`s3`, une ligne de liste**

- Répondre plus vite à vos messages, avec l'aide d'un assistant numérique (point 4).

**`s4`, un bloc**

Un assistant numérique, appelé Praxis, aide l'académie à répondre aux familles. Il est indiqué comme tel dans les conversations (« Assistant de l'académie · IA »). Il lit les messages des conversations entre une famille et l'académie, pour y répondre ou préparer une réponse, et il peut publier des annonces pour les familles. Il ne lit aucune conversation où un enfant participe ou a écrit, ni les candidatures, ni les pièces d'identité, ni les paiements. Il n'écrit jamais à un enfant et n'envoie aucun courriel. Il travaille sous la responsabilité de la direction, qui peut l'arrêter à tout moment : une personne de l'équipe peut reprendre toute conversation, et l'assistant se tait alors.

**`s6`, un bloc**

Pour lire et répondre, l'assistant s'appuie sur un fournisseur d'intelligence artificielle, `[NOM ET PAYS DE TRAITEMENT : À CONFIRMER]`. Les messages qu'il lit lui sont transmis pour cette seule raison, et `[NON-UTILISATION POUR ENTRAÎNER SES MODÈLES, DURÉE CHEZ LUI : À CONFIRMER SELON LE CONTRAT]`. Base légale : notre intérêt légitime à répondre rapidement aux familles `[À CONFIRMER]`. Nous gardons une trace de ce que l'assistant a envoyé, jamais du texte des messages que vous écrivez `[DURÉE : À DÉCIDER]`.

**`s8`, une phrase**

Ces droits valent aussi pour ce que l'assistant lit et écrit.

### English

**`s3`, one list line**

- To answer your messages faster, with the help of a digital assistant (point 4).

**`s4`, one block**

A digital assistant, called Praxis, helps the academy answer families. It is shown as such in conversations ("Academy assistant · AI"). It reads the messages of conversations between a family and the academy, to answer them or prepare an answer, and it can publish announcements for families. It does not read any conversation in which a child takes part or has written, nor applications, identity documents or payments. It never writes to a child and sends no email. It works under the responsibility of the management, which can stop it at any time: a member of the team can take over any conversation, and the assistant then stays silent.

**`s6`, one block**

To read and answer, the assistant relies on an artificial intelligence provider, `[NAME AND COUNTRY OF PROCESSING: TO CONFIRM]`. The messages it reads are passed to it for that reason only, and `[NO USE TO TRAIN ITS MODELS, RETENTION PERIOD AT THE PROVIDER: TO CONFIRM FROM THE CONTRACT]`. Legal basis: our legitimate interest in answering families quickly `[TO CONFIRM]`. We keep a record of what the assistant sent, never of the text of the messages you write `[PERIOD: TO DECIDE]`.

**`s8`, one sentence**

These rights also apply to what the assistant reads and writes.

### العربية

**`s3`، سطر في القائمة**

- الرد على رسائلكم بسرعة أكبر، بمساعدة مساعد رقمي (البند ٤).

**`s4`، فقرة**

يساعد مساعد رقمي، اسمه Praxis، الأكاديمية على الرد على الأسر. ويظهر بهذه الصفة في المحادثات («مساعد الأكاديمية · ذكاء اصطناعي»). يقرأ رسائل المحادثات بين الأسرة والأكاديمية ليرد عليها أو يُعدّ ردًّا، ويمكنه نشر إعلانات للأسر. ولا يقرأ أي محادثة يشارك فيها طفل أو كتب فيها، ولا طلبات الترشح، ولا وثائق الهوية، ولا المدفوعات. ولا يكتب إلى طفل أبدًا ولا يرسل أي بريد إلكتروني. ويعمل تحت مسؤولية الإدارة التي تستطيع إيقافه في أي وقت: يمكن لأحد أعضاء الفريق استئناف أي محادثة، ويصمت المساعد حينها.

**`s6`، فقرة**

لكي يقرأ ويرد، يعتمد المساعد على مزوّد للذكاء الاصطناعي، `[الاسم وبلد المعالجة: يُؤكَّد]`. وتُنقل إليه الرسائل التي يقرؤها لهذا السبب وحده، و`[عدم استخدامها لتدريب نماذجه، ومدة بقائها لديه: يُؤكَّد حسب العقد]`. الأساس القانوني: مصلحتنا المشروعة في الرد السريع على الأسر `[يُؤكَّد]`. ونحتفظ بأثر لما أرسله المساعد، لا لنص الرسائل التي تكتبونها `[المدة: تُحدَّد]`.

**`s8`، جملة**

تسري هذه الحقوق أيضًا على ما يقرؤه المساعد ويكتبه.

## 3. Décisions que seul le directeur peut prendre

| | Décision | Ma proposition |
| :-: | :--- | :--- |
| A | Nom du fournisseur, pays de traitement, contrat (non-entraînement, durée de conservation chez lui) | À lire dans les conditions du plan utilisé pour le chat de Praxis ; aucune valeur n'est inventée ici |
| B | Offrir ou non un droit de s'opposer à la lecture par l'assistant | Ne pas l'offrir avant d'avoir le mécanisme serveur ; sinon une promesse fausse (« Vérité d'abord ») |
| C | Durée de conservation du journal de Praxis | À décider, puis purge écrite ; 180 jours serait cohérent avec le relevé de connexion, **sans que rien ne l'impose** |
| D | Base légale | Intérêt légitime ; à confirmer par un juriste |
| E | Quand publier | Le jour où le directeur allume Praxis, avec la montée de version et l'avis de modification ; jamais avant |

## 4. Ce qui reste à faire une fois validé (hors de cette PR)

1. Intégrer les quatre ajouts dans `assets/i18n/{fr,en,ar}.i18n.json` (`juridique.confidentialite.s3`, `s4`, `s6`, `s8`),
   déclarer les clés dans `tool/libelles_sources.json`, régénérer (`dart run slang` deux fois, `build_runner`).
2. Monter `VersionsJuridiques.version`, la date, et envoyer l'avis de modification.
3. Copier le texte validé, mot pour mot, dans `TEXTES-VALIDES/` (règle du 07/11).
4. Livrer l'affichage « Assistant de l'académie · IA » (Pilote Messagerie) **avant** la publication.
