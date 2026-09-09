# Matrice de couverture des spécifications d'origine
## Vérification ligne par ligne avant le début du codage

Ce document reprend `spcs V00.md`, `specs de app_ra.md` et `init_prompt.txt` élément par élément et indique où chaque point est traité. Trois symboles.

**Couvert** : traité dans un document livré, référence donnée.
**Reporté V1** : écarté du MVP-0 par une décision explicite, référence donnée.
**Écart trouvé** : élément de vos specs que j'avais classé à tort, ou pas encore traité du tout. C'est la partie qui compte dans ce document.

---

## Correction de portée : tranchée

Quatre points avaient été reportés à tort. Trois sont maintenant réglés.

| Élément | Décision |
| :--- | :--- |
| `ADM-03` Séquestre des téléchargements | **Dans le MVP-0**, confirmé. Voir docs/produit/parcours-utilisateurs.md |
| `CTR-03` Grille d'audit du Contrôleur | **Dans le MVP-0**, confirmé. Voir docs/produit/parcours-utilisateurs.md |
| Moteur de formulaires dynamiques à cartes cliquables | **Sur toute l'application**, confirmé. Voir ADR-013 |
| Grille d'examen anonyme et calcul d'imputabilité | Reste dans le doute : voir la question encore ouverte sur le "système d'objectifs élèves" en fin de document |

---

## A. Directives de design et d'ergonomie (`spcs V00.md` §1)

| Exigence d'origine | Statut | Référence |
| :--- | :--- | :--- |
| Charte graphique, sept couleurs nommées | Couvert, corrigé pour le contraste | Audit 1.2, docs/architecture/etape-2-core-flutter.md §1 |
| Bento Grid, gaps 16 à 24px, rayons 20px | Couvert | docs/architecture/etape-2-core-flutter.md §2, `BentoTile` |
| Cibles tactiles massives, micro-interactions d'enfoncement | Couvert | Audit 1.2, `Pressable` |
| **Aucune ouverture automatique de caméra ou de micro, clic volontaire obligatoire** | **Écart trouvé** | Mes maquettes de salle affichaient le micro déjà actif à l'entrée. Ce n'est pas conforme à votre règle d'origine. Correction ci-dessous |

### Correction : micro et caméra désactivés à l'entrée, sans exception

Vos specs sont explicites et je ne les avais pas respectées à la lettre dans les maquettes de salle. Règle corrigée : **à l'entrée en séance, ni le micro ni la caméra ne publient quoi que ce soit**, quel que soit le rôle, quel que soit l'âge. Un seul tap sur le micro démarre la parole. C'est cohérent avec l'ADR-009 qui traitait déjà la caméra ainsi ; le micro suit la même règle, ce que je n'avais pas explicité.

Cela ne change aucun schéma ni aucune policy, seulement l'état initial du token média et le rendu des boutons au premier affichage de `ELV-03` et `ENS-03`.

---

## B. Écrans ÉLÈVE (`spcs V00.md` §2.1)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `ELV-01` Connexion QR et PIN | Couvert | Maquette, PARCOURS §2 |
| `ELV-02` Dashboard mode enfant | Couvert | Maquette, PARCOURS §2 |
| `ELV-03` Salle et split-screen | Couvert, corrigé ci-dessus | Maquette, PARCOURS §2 |
| `ELV-04` Bibliothèque coranique | Couvert | Maquette, PARCOURS §2 |
| **`ELV-05` Suivi pédagogique élève, anonymisation de l'évaluateur** | **Écart trouvé** | Je n'ai spécifié que `TUT-06`, la version tuteur. La version élève n'existe nulle part dans mes documents |

### Écart : `ELV-05` manquant côté élève

Vos specs distinguent deux consultations du même historique pédagogique : celle du tuteur, déjà traitée en `TUT-06`, et celle de l'élève lui-même, avec une règle propre, `show_evaluator_identity = false`. Je n'avais traité que la première.

Pour un élève en mode enfant, cet écran n'a probablement aucune utilité, un enfant de 6 ans ne consulte pas un historique. Pour un élève en mode standard, y compris un adulte autonome, il en a une. Je propose de le traiter comme une troisième section de la barre basse déjà prévue pour ce mode, plutôt qu'un écran séparé, et de masquer l'identité de l'enseignant qui a rédigé chaque évaluation, uniquement quand l'évaluation vient d'un tiers extérieur au cours régulier, par exemple une évaluation du Contrôleur. Le rapport de son propre enseignant régulier n'a pas de raison d'être anonymisé à ses propres yeux, mais je vous laisse trancher ce point précis.

---

## C. Écrans ENSEIGNANT (`spcs V00.md` §2.2)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `ENS-01` Portail KYC et onboarding | Couvert en texte, non maquetté | PARCOURS §3, suit le registre de `TUT-00c` |
| `ENS-02` Dashboard journée et matching | Couvert | Maquette, PARCOURS §3 |
| `ENS-03` Salle enseignant | Couvert, corrigé ci-dessus | Maquette, PARCOURS §3 |
| `ENS-04` Cahier de transmission | Couvert | Maquette, PARCOURS §3 |
| `ENS-05` Portefeuille et paramètres de payout | Reporté V1, avec l'ensemble du module finance | ADR-003, confirmé par votre propre arbitrage |

Rien d'omis ici en dehors du micro et de la caméra déjà corrigés.

---

## D. Écrans TUTEUR (`spcs V00.md` §2.3)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `TUT-01` Dashboard famille | Couvert | Maquette, PARCOURS §1 |
| `TUT-02` Gestion du foyer et appairage | Couvert | Maquette, PARCOURS §1 |
| `TUT-03` Rechargement express, Flutterwave Push USSD | Reporté V1, avec la finance. Flutterwave lui-même écarté, ADR-007 | ADR-003, ADR-007 |

Deux écrans que j'ai ajoutés sans équivalent direct dans vos specs, `TUT-04` disponibilités et `TUT-05` réglages par enfant, restent nécessaires : sans eux, `[TUT-01]` et le matching inversé n'ont rien à afficher. Ce ne sont pas des oublis de votre part, ce sont des conséquences mécaniques de fonctionnalités que vous avez décrites ailleurs sans leur donner d'écran.

---

## E. Écrans CONTRÔLEUR (`spcs V00.md` §2.4)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `CTR-01` Planning global d'infiltration | Couvert en texte, non maquetté | PARCOURS §4 |
| `CTR-02` Infiltration inopinée visio | Couvert et renforcé | Maquette, ADR-011 |
| `CTR-03` Grille d'audit dynamique | **Reporté à tort**, voir correction de portée en tête de document | À rouvrir selon votre réponse |

---

## F. Écrans COMPTABLE (`spcs V00.md` §2.5)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `CPT-01`, `CPT-02`, `CPT-03` | Reportés V1, avec l'ensemble du module finance | ADR-003, confirmé par votre arbitrage |

Rien à corriger ici, ces trois écrans sont financiers par nature et votre arbitrage sur la finance les couvre sans ambiguïté.

---

## G. Écrans ADMIN (`spcs V00.md` §2.6)

| Écran d'origine | Statut | Référence |
| :--- | :--- | :--- |
| `ADM-01` Centre de commande | Couvert | Maquette, PARCOURS §5 |
| `ADM-02` Validation KYC et filtrage genre | Couvert, y compris la règle RLS de filtrage par genre | Maquette, PARCOURS §5, audit 1.3 |
| `ADM-03` Séquestre des téléchargements | **Reporté à tort**, voir correction de portée en tête de document | À rouvrir selon votre réponse |
| `ADM-04` Journal d'audit immuable | Couvert au niveau schéma et règle, non maquetté en écran dédié | Étape 1 §2 et §9, mentionné dans PARCOURS §5 |

---

## H. Matrice de routage inter-écrans (`spcs V00.md` §3)

| Règle d'origine | Statut |
| :--- | :--- |
| KYC soumis vers validation Admin | Couvert, PARCOURS matrice de routage |
| Approbation vers activation du compte | Couvert |
| Rejoindre ou lancer vers pre-flight | Couvert |
| Quitter le cours vers cahier de transmission, obligatoire | Couvert |
| **Export de 2 lignes ou plus vers séquestre Admin** | Absent de ma matrice actuelle, puisque `ADM-03` avait été reporté à tort. Revient si le séquestre revient au MVP-0 |
| PIN sur PC vers switch de session rapide | Couvert, `ELV-01` |
| Match sur créneau libre, association thread-safe | Couvert, contrainte C2 de l'Étape 1 |

---

## I. Points des 8 domaines fonctionnels non repris ailleurs (`specs de app_ra.md`)

Ces points ne sont pas des écrans mais des règles transverses. Vérification une par une.

| Exigence | Statut |
| :--- | :--- |
| Identifiants immuables `[ROLE_NIVEAU]-[INITIALES][SEQ]/[AA]` | Couvert, Étape 1 §6 |
| Niqab accepté sur la photo publique | À réconcilier avec l'ADR-012. La photo de profil enfant et la photo publique d'un enseignant ou d'un profil adulte sont deux choses distinctes dans vos specs, la seconde n'a pas encore de règle propre. Écart mineur, traité ci-dessous |
| Stockage UTC natif, conversion dynamique | Couvert, Étape 1 §2, PARCOURS modèle de navigation |
| Pauses 30 min, gestion des prières avec compensation de minutes | Couvert pour l'affichage dans `ENS-02`. **La mécanique de compensation elle-même, comment une prière décale ou non le cours suivant, n'est pas encore spécifiée en détail** |
| Alertes de décalage horaire, DST, 30 jours avant | Mentionné dans l'audit comme dérivé de la récurrence correcte, jamais détaillé comme mécanisme concret : qui reçoit l'alerte, sous quelle forme |
| Pre-flight check, rapport partagé | Mentionné comme condition d'activation du bouton de lancement, jamais détaillé : quels tests exactement, quel contenu dans le rapport |
| Heartbeat WebSocket 10s | Remplacé par les webhooks serveur LiveKit, Audit 1.4, ADR-001 |
| Fallback audio-only en cas de dégradation | Couvert, Audit 1.4, ADR-001 |
| Formulaires dynamiques à cartes cliquables, UI sans saisie | **Reporté à tort**, voir correction de portée en tête de document |
| Export Excel avec sélecteur de colonnes par cases à cocher | Lié à `ADM-03` et aux exports, reporté à tort avec le séquestre |
| Soft delete `deleted_at` | Couvert, Étape 1 §1 et §2 |
| `FamilyLiveMonitoringCard` | Couvert, `TUT-01` |
| Bandeau d'annonces unidirectionnel | Couvert, mentionné dans `ELV-02` mode standard et `ENS-02` |

### Écart : photo publique d'un profil adulte ou enseignant, distincte de la photo enfant

L'ADR-012 traite la photo de l'enfant, gérée par le parent, jamais exposée hors du foyer. Vos specs d'origine parlent aussi d'une photo publique, avec niqab accepté, pour les profils où une visibilité existe, probablement l'enseignant vu par sa hiérarchie ou un élève adulte autonome vu dans un cours de groupe. Ce n'est pas la même règle et je ne l'ai pas encore écrite. À trancher : un enseignant a-t-il une photo de profil visible des familles avant le premier cours, par exemple sur sa fiche dans le feed de matching, ou reste-t-il identifié par son seul prénom jusqu'à la première rencontre en direct ?

---

## Ce qu'il reste pour clore ce contrôle

Deux réponses seulement, les trois autres sont tranchées.

1. Le "système de création d'objectifs pour les élèves" que vous avez reporté : est-ce la grille d'examen anonyme et l'imputabilité de vos specs d'origine, ou une fonctionnalité différente que vous avez en tête et qui n'est décrite nulle part encore ?
2. Un enseignant a-t-il une photo publique visible par les familles avant le premier cours ?
