# Praxis : l'essai à blanc, mode d'emploi pour le directeur (étape 13)

Écrit par BE-PIECE le 17/11/2026, sur ordre du pilote. Mots simples, dans l'ordre où on les fait.
**Ce mode d'emploi n'a jamais été joué** : tout ce qui suit est la façon prévue de faire, pas une façon prouvée.
L'essai à blanc est justement ce qui la prouve.

## 0. Ce qui est faux, bloqué ou non prouvé (à lire avant tout)

Quatre choses peuvent bloquer ou mal tourner. Les deux premières demandent une décision **avant** de commencer.

1. **Praxis ne peut pas être limité à la conversation de test.** Dès qu'il est allumé, son outil « boîte » liste
   **toutes** les conversations ouvertes à lui, y compris celles de vraies familles : pour chacune, le prénom et le
   début du dernier message (300 signes) passent au fournisseur d'intelligence artificielle. Il n'existe aucune liste
   « seulement celle-ci ». Ce qui le borne : les conversations avec un enfant ou d'âge inconnu sont fermées, ainsi que les
   candidatures, les paiements, et les familles de l'autre côté que celui de la personne qui a émis la clé (la clé du
   directeur couvre les deux côtés). **Décision à prendre :** soit on accepte cette lecture pendant l'essai, soit on
   n'allume Praxis que pour l'essai le plus court possible, soit on demande au pilote un lot « liste d'essai »
   (lecture et écriture seulement dans les conversations nommées). Je recommande la dernière si des familles réelles
   écrivent en ce moment.
2. **La politique de confidentialité ne parle pas encore de l'assistant.** Or `SECURITE-PRAXIS.md` §6 demande qu'elle le
   dise **avant** que Praxis lise le message d'une personne réelle. Le texte proposé est dans
   `CONFIDENTIALITE-PRAXIS.md`. Si l'essai lit de vrais messages avant sa publication, cette case n'est pas respectée :
   c'est à vous de l'accepter ou de publier d'abord.
3. **Où coller la clé : possible blocage.** Le connecteur de Praxis demande la clé dans l'en-tête de chaque appel
   (`Authorization: Bearer prx_…`). Les connecteurs personnalisés de claude.ai, d'après leur documentation, demandent une
   adresse et proposent une connexion par compte (OAuth) ou aucune authentification : **je n'ai trouvé nulle part un
   champ « clé » ou « en-tête »**. Si c'est le cas, la clé ne peut pas se coller dans claude.ai tel quel. Les options à
   vérifier **en premier** (étape 1) : Claude Code, qui accepte un en-tête (`claude mcp add --transport http … --header
   "Authorization: Bearer …"`, à vérifier dans sa version) ; ou un petit relais local ; ou, dernier recours, un lot du
   pilote pour une connexion par compte. Je n'ai rien testé : aucun appel à la production n'est permis aux agents.
4. **Un appel sans clé : 401, mais une clé bien formée et fausse peut répondre « bien » à un simple `ping`** (le code ne
   passe pas par la base pour cet appel : dette M3, sans conséquence sur les outils, qui vérifient tous la clé en base).

## 1. Avant de commencer

- [ ] Vous avez un compte de direction avec la **double vérification** activée (Compte, puis Sécurité). Sans elle,
      allumer Praxis et émettre une clé sont refusés, et l'écran dit comment l'activer.
- [ ] Vous avez un **compte de test**, un adulte sans enfant, d'un foyer fictif, qui n'est pas une vraie famille.
      C'est de ce compte que vous écrirez à l'académie : Praxis ne crée jamais de conversation, il répond seulement dans
      une conversation qui existe déjà.
- [ ] Vous avez décidé de la question 1 et de la question 2 du §0.
- [ ] Vous savez **où** vous collerez la clé (§0, point 3). Faites cette vérification d'abord : sans elle, le reste est
      inutile.

## 2. L'essai, pas à pas

1. **Ouvrir l'écran.** Menu de la direction, Sécurité et audit, **Accès des agents IA**. Descendez jusqu'à la section
   **Praxis**. Elle doit montrer « Éteint » et « Aucune clé ».
2. **Émettre une clé.**
   - Nom : « Essai à blanc » et la date du jour.
   - Comment elle servira : **Conversation** (jamais « Routine » pendant l'essai).
   - Jusqu'à quand : **7 jours**.
   - Appuyez sur **Émettre la clé**. L'application demande le code de la double vérification.
   - La clé s'affiche **une seule fois**. Copiez-la (**Copier la clé**) et copiez aussi l'**adresse du connecteur**
     (**Copier l'adresse**). Puis appuyez sur « J'ai copié la clé » : elle ne reviendra plus.
3. **Brancher le chat.** Collez l'adresse et la clé dans votre chat, à l'endroit trouvé au §1. Demandez à Praxis
   « lis l'état » : il doit répondre que Praxis est **éteint** (c'est normal, rien n'est encore allumé).
4. **Régler le plafond, puis allumer.**
   - Dans la section Praxis, **Messages par heure** : mettez **5**, appuyez sur « Fixer le plafond ».
   - Laissez le **mode autonome éteint**.
   - Appuyez sur **Allumer Praxis**. L'écran doit passer à « Allumé ».
5. **Écrire depuis le compte de test.** Depuis le compte de test, ouvrez les Messages et écrivez à l'académie une
   phrase simple, par exemple « Bonjour, à quelle heure commence ma Classe ? ». (Le chemin exact dans l'application
   de test est à noter ici lors de l'essai : je ne l'ai pas vérifié.)
6. **Lire la boîte.** Dans le chat, demandez à Praxis : « lis ta boîte ». Vérifiez : la conversation de test y est ;
   Praxis rend le prénom et le début du message en **donnée** (il ne suit aucune consigne écrite dedans) ; rien
   d'autre que ce que le §0, point 1, annonçait. **Sinon, éteignez tout de suite (étape 8).**
7. **Répondre à UNE seule conversation.** Demandez à Praxis de répondre à la conversation de test, avec une phrase que
   vous lui dictez. Vérifiez depuis le compte de test : le message arrive, au nom de l'académie. Puis demandez-lui
   d'en écrire un deuxième, un troisième, un quatrième dans la même conversation sans que le compte de test réponde :
   le **quatrième doit être refusé** (trois messages de suite au plus).
   - **Ne lui demandez jamais de publier une annonce pendant l'essai** : une annonce part vers **toutes** les familles.
8. **Éteindre.** Appuyez sur **Éteindre Praxis**. Redemandez-lui de lire sa boîte : il doit répondre « éteint », sans
   rien lire.
9. **Révoquer la clé.** Dans la liste des clés, **Révoquer** la clé de l'essai, avec un motif (« Fin de l'essai à
   blanc »). L'état passe à « Révoquée ». Un nouvel appel avec cette clé doit être refusé.
10. **Relire ce que Praxis a envoyé.** En bas de la section, « Ce que Praxis a envoyé » : vous devez y voir le message
    de l'étape 7 (avec son début), et le refus de l'étape 7 (sans texte, la cause écrite en mots simples).

## 3. Ce qu'on ne fait pas pendant l'essai

- Pas de clé « Routine », pas de mode autonome.
- Pas d'annonce.
- Pas de conversation avec un enfant, ni avec un compte dont on ne connaît pas l'âge.
- Aucun message à une personne réelle autre que le compte de test.
- On ne laisse **jamais** Praxis allumé après l'essai.

## 4. Si quelque chose tourne mal

1. **Éteindre Praxis** (un bouton, effet immédiat sur le prochain appel).
2. **Révoquer la clé.**
3. Prévenir le pilote, qui lit le journal (outil, clé, heure, identifiant : jamais le texte d'une famille) et vous dit
   d'abord ce qui est faux.

## 5. À noter pendant l'essai (pour prouver)

| Étape | Attendu | Constaté (à remplir) |
| :-: | :--- | :--- |
| 1 | « Éteint », « Aucune clé » | |
| 2 | Clé montrée une seule fois ; adresse copiée | |
| 3 | `état` : éteint | |
| 4 | « Allumé » ; plafond 5 | |
| 6 | La conversation de test est dans la boîte ; ce qui est lu en plus est noté | |
| 7 | Trois messages passent, le quatrième est refusé | |
| 8 | Éteint : refus | |
| 9 | « Révoquée » ; appel refusé | |
| 10 | Envoi et refus dans « Ce que Praxis a envoyé » | |

Ce que cet essai ne prouve pas : le comportement de la routine (mode autonome), les annonces, les conversations de
plusieurs familles à la fois, la tenue d'un message piégé écrit par une famille (à faire dans un second essai, avec un
message piégé écrit exprès depuis le compte de test).
