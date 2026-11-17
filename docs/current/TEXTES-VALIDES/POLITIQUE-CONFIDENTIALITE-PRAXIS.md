# Politique de confidentialité : l'assistant Praxis (texte arbitré)

- **Statut : arbitré par le pilote le 17/11/2026 à 8 h 30 UTC, complété à 8 h 40 (autres fournisseurs, ordre du directeur)**, sur délégation écrite du directeur (« pour le texte à
  valider c'est toi seul le juriste ici, tu arbitres, et tu me montres un aperçu »). Base de travail : la proposition de
  BE-PIECE (`BUREAU-EQUIPE/PRAXIS/CONFIDENTIALITE-PRAXIS.md`), dont les six points ouverts sont tranchés au §1.
- **Ce texte n'est pas un avis d'avocat.** Il décrit ce que fait le code, et rien de plus.
- **Il se publie le jour où Praxis lit pour la première fois le message d'une personne réelle, pas avant** (RGPD,
  articles 12 et 13 : on ne décrit que des traitements réels). À la publication : montée de `VersionsJuridiques.version`
  et avis de modification aux personnes déjà inscrites.
- **Deux conditions à tenir avant la publication**, sinon le texte serait faux :
  1. le compte Claude qui fait tourner Praxis a le réglage « utiliser mes conversations pour améliorer les modèles »
     **désactivé** ;
  2. la mention « Assistant de l'académie · IA » est visible sur le profil de Praxis (étape 10 de la checklist Praxis).

## 1. Les arbitrages

| Point ouvert | Arbitrage | Raison |
| :--- | :--- | :--- |
| Fournisseur d'IA | **Anthropic PBC (Claude)**, seul utilisé aujourd'hui ; **Google LLC (Gemini) et OpenAI (ChatGPT)** nommés comme fournisseurs possibles, aux mêmes conditions (directeur, 17/11 à 8 h 30 : « tu dois aussi mentionner les autres comme gemini, open ai ») | On nomme celui qui est employé, comme la politique nomme Cloudflare. Les deux autres sont nommés d'avance pour qu'un changement de fournisseur ne surprenne personne. **Règle** : le texte dit toujours lequel est utilisé ; en changer impose de mettre la phrase à jour le jour même, avec les mêmes garanties (pas d'entraînement, 30 jours au plus, clauses types) |
| Transfert hors Union européenne | Oui, vers les États-Unis, sous les clauses contractuelles types de la Commission européenne | Anthropic traite aux États-Unis |
| Entraînement des modèles | Les messages ne servent pas à entraîner les modèles | Vrai seulement avec le réglage désactivé : condition 1 |
| Durée chez le fournisseur | Au plus 30 jours, puis effacement | Durée annoncée par le fournisseur quand l'entraînement est désactivé |
| Base légale | **Intérêt légitime** : répondre vite et de façon fiable aux familles et aux candidats | Une réponse rapide sert la personne. Le droit de s'opposer (ci-dessous) équilibre ce choix |
| Droit de s'opposer | Promis sous cette forme : « demandez à parler à l'équipe, une personne reprend la conversation et l'assistant se tait » | Ce mécanisme existe déjà (passage de main, A6). Aucune exclusion automatique n'est promise, faute de code |
| Journal de Praxis | Conservé **12 mois**, puis effacé | Durée de preuve raisonnable. **Dette** : la purge automatique n'existe pas encore et doit être écrite avant la publication |
| Candidats | **Mentionnés**, parce que Praxis doit leur répondre (directeur, 17/11 : « les candidats sont des centaines ») | Vrai seulement quand les conversations de candidature seront ouvertes à Praxis (lot serveur à faire) |
| Enfants | Jamais lus, jamais écrits | Règle de sécurité R7, vérifiée par le serveur |

## 2. Le texte, en français

Les ajouts entrent dans la politique existante (`juridique.confidentialite`), sans modifier une phrase déjà publiée.

**Point 3, « Pourquoi nous les utilisons » : une ligne de liste**

- Répondre plus vite à vos messages, avec l'aide d'un assistant numérique (voir le point 4).

**Point 4, « Qui voit quoi » : un bloc**

Un assistant numérique, appelé Praxis, aide l'académie à répondre aux familles et aux candidats dans la messagerie de l'application. Son profil indique qu'il s'agit d'une intelligence artificielle. Il lit les messages des conversations avec l'académie pour y répondre ou préparer une réponse. Il ne lit aucune conversation où un enfant participe, ni les pièces d'identité, ni les paiements. Il n'écrit jamais à un enfant et n'envoie aucun courriel. Il travaille sous la responsabilité de la direction, qui peut l'arrêter à tout moment.

**Point 6, « Où sont vos informations » : un bloc**

Pour lire et répondre, l'assistant s'appuie sur un fournisseur d'intelligence artificielle. Aujourd'hui, il s'agit d'Anthropic PBC (Claude), entreprise établie aux États-Unis. L'académie peut aussi recourir, aux mêmes conditions, à Google LLC (Gemini) ou à OpenAI (ChatGPT), établies aux États-Unis ; le fournisseur utilisé est toujours indiqué ici. Les messages que l'assistant lit sont transmis au fournisseur pour cette seule raison. Ils ne servent pas à entraîner ses modèles et sont effacés chez lui au plus tard après 30 jours. Ce transfert hors de l'Union européenne est encadré par les clauses contractuelles types de la Commission européenne. Nous gardons pendant 12 mois une trace de ce que l'assistant a envoyé, jamais du texte des messages que vous écrivez. La base légale est notre intérêt légitime à vous répondre rapidement.

**Point 8, « Vos droits » : une phrase après la liste**

Vous pouvez à tout moment demander à parler à l'équipe : une personne reprend la conversation et l'assistant ne vous répond plus dans celle-ci.

## 3. Arabe et anglais

À écrire à l'intégration avec la compétence `mots-rewayah`, même sens, même longueur. « Praxis », « Anthropic PBC », « Google LLC », « OpenAI », « Claude », « Gemini » et « ChatGPT »
restent en lettres latines. Les trois langues sont publiées le même jour.

## 4. Ce qui reste à faire avant la publication

1. Le directeur désactive l'entraînement sur le compte Claude de Praxis (condition 1).
2. L'affichage du profil de Praxis, avec la mention IA (étape 10).
3. La purge du journal à 12 mois (petit lot serveur).
4. L'ouverture des conversations de candidature à Praxis (lot serveur), sinon on retire « et aux candidats ».
5. L'intégration dans `assets/i18n` (fr, en, ar), la montée de version, l'avis de modification.
