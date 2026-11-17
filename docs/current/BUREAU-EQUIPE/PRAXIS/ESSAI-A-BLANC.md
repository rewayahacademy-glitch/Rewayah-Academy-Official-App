# Praxis : l'essai à blanc, mode d'emploi pour le directeur (étape 13)

Écrit par BE-PIECE le 17/11/2026, sur ordre du pilote. Mots simples, dans l'ordre où on les fait.
**Ce mode d'emploi n'a jamais été joué** : tout ce qui suit est la façon prévue de faire, pas une façon prouvée.
L'essai à blanc est justement ce qui la prouve.

## 0. Ce qui est faux, bloqué ou non prouvé (à lire avant tout)

Quatre choses peuvent bloquer ou mal tourner. Mise à jour du 17/11/2026 après l'arbitrage du pilote : le **mode essai**
(lot PX-4, PR serveur #588 puis écran #589) répond au point 1, **à condition d'être fusionné et installé**. Tant qu'il ne
l'est pas, ne rien allumer.

1. **Praxis ne peut pas lire que la conversation de test sans le mode essai.** Sans lui, dès que Praxis est allumé,
   son outil « boîte » liste **toutes** les conversations ouvertes à lui, y compris celles de vraies familles : le prénom
   et le début du dernier message (300 signes) passent au fournisseur d'intelligence artificielle. **Règle de l'essai :
   on ne l'allume qu'avec le mode essai**, c'est-à-dire avec la liste des conversations d'essai remplie (dix au plus). Tant
   que la liste n'est pas vide, Praxis ne voit **que** ces conversations, n'écrit que dans celles-là et **ne peut publier
   aucune annonce**. Le mode essai ne donne aucun droit de plus : les conversations d'un enfant, d'âge inconnu, les
   candidatures et les paiements restent fermés. **Comment on les choisit :** l'écran montre la liste de vos
   conversations, telle que vos Messages la montrent (même titre, même pastille), avec une case à cocher et une
   recherche : vous n'avez aucune référence à taper. Si vous n'avez pas encore de conversation de test, créez-la d'abord
   avec un compte de test (le message du §2, étape 5, se fait donc **avant** l'étape 4).
2. **La politique de confidentialité ne parle pas encore de l'assistant.** `SECURITE-PRAXIS.md` §6 demande qu'elle le dise
   **avant** que Praxis lise le message d'une personne réelle. Le texte proposé est dans `CONFIDENTIALITE-PRAXIS.md`
   (cinq décisions pour vous, rien n'est publié). **Tant qu'elle n'est pas publiée, le mode essai est la seule façon
   d'allumer Praxis**, et l'essai ne lit que le compte de test.
3. **Où coller la clé.** Le connecteur de Praxis lit la clé dans l'en-tête de chaque appel (`Authorization: Bearer prx_…`).
   Deux voies, la première est la sûre :
   - **Claude Code (voie sûre, documentée)** : `claude mcp add --transport http praxis <adresse du connecteur> --header
     "Authorization: Bearer ${PRAXIS_CLE}"`, avec la clé placée dans la variable `PRAXIS_CLE` (jamais écrite dans un
     fichier du dépôt). Source : documentation de Claude Code, page MCP.
   - **claude.ai (web) et Claude Desktop : à vérifier.** « Ajouter un connecteur personnalisé » a, d'après la
     documentation, une section **« Request headers »** (bêta, pas forcément présente sur tous les comptes) : y saisir
     l'en-tête `Authorization` avec la valeur `Bearer prx_…` (l'espace compris). **Si la section n'apparaît pas sur votre
     compte, ne cherchez pas d'autre moyen : utilisez Claude Code.**
   - **Jamais la clé dans l'adresse** (après un `?`) : déconseillé par la documentation et interdit par la spécification
     MCP ; Praxis ne la lirait de toute façon pas là.
   - Une connexion par compte (OAuth) n'est pas nécessaire maintenant ; si la section manque un jour, c'est un lot à part.
   Rien de cela n'a été joué : aucun appel à la production n'est permis aux agents.
4. **Un appel sans clé : 401, mais une clé bien formée et fausse peut répondre « bien » à un simple `ping`** (le code ne
   passe pas par la base pour cet appel : dette M3, sans conséquence sur les outils, qui vérifient tous la clé en base).

## 1. Avant de commencer

- [ ] Vous avez un compte de direction avec la **double vérification** activée (Compte, puis Sécurité). Sans elle,
      allumer Praxis et émettre une clé sont refusés, et l'écran dit comment l'activer.
- [ ] Vous avez un **compte de test**, un adulte sans enfant, d'un foyer fictif, qui n'est pas une vraie famille.
      C'est de ce compte que vous écrirez à l'académie : Praxis ne crée jamais de conversation, il répond seulement dans
      une conversation qui existe déjà.
- [ ] Le **mode essai est installé** (PR #588 fusionnée et migration installée par le pilote) et l'écran #589 fusionné.
      Sinon, ne rien allumer.
- [ ] Vous savez **où** vous collerez la clé (§0, point 3) : Claude Code d'abord. Faites cette vérification d'abord : sans
      elle, le reste est inutile.

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
3. **Brancher le chat.** Avec Claude Code, la commande du §0 (point 3) ; sur claude.ai, seulement si la section « Request
   headers » existe. Demandez à Praxis
   « lis l'état » : il doit répondre que Praxis est **éteint** (c'est normal, rien n'est encore allumé).
4. **Nommer la conversation d'essai, régler le plafond, puis allumer.**
   - Dans la section Praxis, **Conversations d'essai** : cherchez et **cochez la conversation de test** (une seule),
     puis « Enregistrer les conversations d'essai ». La phrase doit dire « Praxis ne voit que 1 conversation et ne
     publie aucune annonce ». **N'allumez pas avant d'avoir vu cette phrase.**
   - Dans la section Praxis, **Messages par heure** : mettez **5**, appuyez sur « Fixer le plafond ».
   - Laissez le **mode autonome éteint**.
   - Appuyez sur **Allumer Praxis**. L'écran doit passer à « Allumé ».
5. **Écrire depuis le compte de test.** Depuis le compte de test, ouvrez les Messages et écrivez à l'académie une
   phrase simple, par exemple « Bonjour, à quelle heure commence ma Classe ? ». (Le chemin exact dans l'application
   de test est à noter ici lors de l'essai : je ne l'ai pas vérifié.)
6. **Lire la boîte.** Dans le chat, demandez à Praxis : « lis ta boîte ». Vérifiez : la conversation de test y est ;
   Praxis rend le prénom et le début du message en **donnée** (il ne suit aucune consigne écrite dedans) ; **elle est
   la seule** : toute autre conversation, même réelle, est invisible (demandez-lui de lire une autre conversation que vous n'avez
   pas cochée : réponse « hors de l'essai »). **Sinon, éteignez tout de suite (étape 8).**
7. **Répondre à UNE seule conversation.** Demandez à Praxis de répondre à la conversation de test, avec une phrase que
   vous lui dictez. Vérifiez depuis le compte de test : le message arrive, au nom de l'académie. Puis demandez-lui
   d'en écrire un deuxième, un troisième, un quatrième dans la même conversation sans que le compte de test réponde :
   le **quatrième doit être refusé** (trois messages de suite au plus).
   - Demandez-lui aussi de publier une annonce : elle doit être **refusée** (« mode essai, aucune annonce »). C'est le
     seul moment où l'on demande une annonce, et c'est pour la voir refusée.
8. **Éteindre.** Appuyez sur **Mettre fin à l'essai**, puis sur **Éteindre Praxis**. Redemandez-lui de lire sa boîte : il doit répondre « éteint », sans
   rien lire.
9. **Révoquer la clé.** Dans la liste des clés, **Révoquer** la clé de l'essai, avec un motif (« Fin de l'essai à
   blanc »). L'état passe à « Révoquée ». Un nouvel appel avec cette clé doit être refusé.
10. **Relire ce que Praxis a envoyé.** En bas de la section, « Ce que Praxis a envoyé » : vous devez y voir le message
    de l'étape 7 (avec son début), et le refus de l'étape 7 (sans texte, la cause écrite en mots simples).

## 3. Ce qu'on ne fait pas pendant l'essai

- Pas de clé « Routine », pas de mode autonome.
- Aucune annonce publiée (une seule demandée, pour la voir refusée).
- Jamais Praxis allumé avec la liste des conversations d'essai vide.
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
| 4 | Phrase « ne voit que 1 conversation » ; puis « Allumé » ; plafond 5 | |
| 6 | La conversation de test est seule dans la boîte ; une autre conversation, non cochée : « hors de l'essai » | |
| 7 | Trois messages passent, le quatrième est refusé ; l'annonce est refusée « mode essai » | |
| 8 | Éteint : refus | |
| 9 | « Révoquée » ; appel refusé | |
| 10 | Envoi et refus dans « Ce que Praxis a envoyé » | |

Ce que cet essai ne prouve pas : le comportement de la routine (mode autonome), les annonces, les conversations de
plusieurs familles à la fois, la tenue d'un message piégé écrit par une famille (à faire dans un second essai, avec un
message piégé écrit exprès depuis le compte de test).
