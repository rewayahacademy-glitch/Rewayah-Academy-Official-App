# Système UX/UI Rewayah — la constitution

> Version 1.0, 7 septembre 2026. Écrit avant l'étape 5, après que le premier
> rendu visuel de l'application ait été jugé daté par l'opérateur.
> **Aucun écran ne se construit plus sans passer par ces documents.**

## 1. Pourquoi ce corpus existe

Jusqu'ici, chaque écran a été spécifié dans le plan de son étape, puis construit.
Ça a produit des écrans corrects un par un et un ensemble qui ne ressemble pas à
un produit : un seul fond plat partout, des couleurs de marque posées en aplats
saturés, aucune échelle d'élévation, aucune règle de mouvement, et une
typographie française qui date le produit d'une décennie.

Le défaut n'est pas dans les écrans. Il est dans l'absence de **langage** au
dessus d'eux. Un agent qui reçoit « fais l'écran ADM-01 » et n'a pas de langage
invente : un rayon de 20, une carte, un bouton, et l'écran suivant en invente
d'autres. C'est exactement ce que produit le vibe coding, et c'est réparable une
seule fois : maintenant, tant que le produit est jeune.

**Règle qui gouverne tout le reste : aucun écran ne s'implémente s'il n'est pas
inscrit dans `08-catalogue-ecrans.md`.** Si un écran manque au catalogue, on
l'ajoute au catalogue d'abord, et on discute de sa fiche avant d'ouvrir un
fichier `.dart`.

## 2. Le principe directeur

> **Même langage visuel, charge cognitive différente.**

Un enfant de six ans et un comptable emploient le même produit, les mêmes
couleurs, les mêmes composants, le même mouvement. Ils ne voient pas la même
densité d'information. La différence se joue sur la quantité de décisions
offertes, jamais sur l'ADN visuel.

Corollaire, déjà tenu par le code : **le mode d'interface ne duplique pas
l'arborescence** (`etape-2-core-flutter.md` section 3). Une deuxième
arborescence finit toujours par diverger en silence.

## 3. La hiérarchie des sources de vérité

Le design ne décide jamais du métier. Le parcours utilisateur ne contredit
jamais la règle métier. Quand deux documents divergent, c'est celui du haut qui
gagne, et l'autre se corrige.

```
        RÈGLES MÉTIER            decisions.md, ADR-001 à ADR-018
               │
               ▼
        MODÈLE DE DONNÉES        etape-0-1-fondations.md, supabase/migrations/
               │
      ┌────────┴────────┐
      ▼                 ▼
 PARCOURS          MODÈLE DE SÉCURITÉ    parcours-utilisateurs.md / RLS
      │                 │
      └────────┬────────┘
               ▼
        SYSTÈME UX/UI            docs/design/  (ce dossier)
               │
               ▼
        FICHE D'ÉCRAN            08-catalogue-ecrans.md
               │
               ▼
        IMPLÉMENTATION FLUTTER   lib/
```

Un défaut visuel se corrige dans `docs/design/`. Un défaut de règle se corrige
dans `decisions.md`, jamais dans l'écran qui l'a révélé.

## 4. Les huit documents

| Fichier | Répond à |
| :--- | :--- |
| `01-systeme-visuel.md` | À quoi ça ressemble : surfaces, élévation, rayons, densité, rythme, usage des couleurs, échelle typographique |
| `02-regles-ux.md` | Comment ça se comporte : une fonction par écran, dévoilement progressif, hiérarchie des actions, états, erreurs, destructif, notifications |
| `03-architecture-information.md` | Qui voit quoi et par où : rôles et capacités, cinq niveaux de charge, zones, navigation, profondeur |
| `04-systeme-mouvement.md` | Comment ça bouge : durées, courbes, les six motifs, réduction du mouvement |
| `05-regles-responsive.md` | Comment ça s'adapte : trois gabarits, un seul système de composants, tableaux, RTL |
| `06-accessibilite.md` | Utilisable par qui : contraste mesuré, cibles, échelle dynamique, lecteur d'écran, mode accessibilité |
| `07-catalogue-composants.md` | Avec quoi : les composants existants, ceux à construire, et les dix états obligatoires |
| `08-catalogue-ecrans.md` | Le registre des écrans, leur fiche, et la règle qui interdit d'en inventer un |

Les valeurs de jetons (hex, noms de police, icônes, règles islamiques,
copywriting) restent dans **`docs/produit/design-tokens.md`**, source unique. Les
documents de ce dossier nomment les jetons, ils ne recopient jamais leurs valeurs :
deux tableaux d'hex finiraient par diverger, et le mauvais serait recopié.

## 5. Le comité, avant d'ouvrir un fichier

Cinq questions, dans cet ordre, sur toute nouvelle fonctionnalité. Une réponse
« je ne sais pas » arrête le travail au lieu de le lancer.

1. **UX** : est-ce compréhensible sans explication ?
2. **UI** : est-ce cohérent avec ce qui existe déjà, ou est-ce que j'invente ?
3. **Produit** : est-ce réellement utile à ce rôle, à cette fréquence ?
4. **Accessibilité** : utilisable au doigt, au clavier, au lecteur d'écran, en
   arabe, à 200 % de taille de texte ?
5. **Flutter** : implémentable avec les composants existants, ou faut-il en
   ajouter un au catalogue d'abord ?

## 6. Les interdits

Repris de la note de refonte, à l'exception de ceux qui sont déjà des ADR et qui
sont listés en section 7 comme acquis.

- Ne pas inventer un écran absent du catalogue.
- Ne pas déduire une règle métier d'un choix de design.
- Ne pas transformer un rôle en application séparée.
- Ne pas écrire `if (role == ...)` dans un widget : la lecture passe par une
  capacité, jamais par un rôle en dur (`03-architecture-information.md` §2).
- Ne pas traiter le mode d'interface comme un rôle.
- Ne pas faire confiance au client pour une restriction : le routeur est une
  commodité, la RLS est la barrière (`etape-2-core-flutter.md` §3).
- Ne pas afficher une donnée brute d'erreur à l'utilisateur.
- Ne pas ajouter une couleur, une police, un rayon ou une durée hors des jetons.
- Ne pas animer une interaction fréquente au delà de 200 ms.
- Ne pas construire un écran sans ses états vide, chargement, erreur et hors ligne.

## 7. Ce que la note de refonte demandait, et qui existe déjà

À lire avant de « corriger » quoi que ce soit : plusieurs recommandations de la
note sont déjà tranchées dans ce dépôt, parfois dans l'autre sens, et pour des
raisons écrites.

| Recommandation de la note | État réel | Où |
| :--- | :--- | :--- |
| « Contradiction majeure : qui pose les créneaux, la famille ou l'enseignant ? » | **Tranchée, et ce n'est ni l'un ni l'autre exactement.** Une seule table `weekly_availability` pour les deux rôles ; la famille pose ses créneaux, l'enseignant prend **un élève**, pas un créneau, et le garde. Le créneau n'est que l'heure du rendez-vous qui en découle | ADR-017 |
| « Le mot niveau est trop restrictif » | Retenu, sans dette : le MVP-0 n'a pas d'entité niveau. Le groupe existe par `session_participants` en plusieurs-à-plusieurs, jamais par `session.student_id` | ADR-004 |
| « Une séance doit porter participants, observateurs, contenu, présence, audit » | Fait : `session_participants` M:N, contrôleur `hidden`, journal d'audit | ADR-004, ADR-011 |
| « Le mode enfant doit être un mode d'accessibilité, pas un rôle » | Fait, sous le nom **mode d'interface**, porté par le profil et pas par le rôle, seuil dans `app_config` | ADR-009, ADR-016 |
| « Les appareils sont un objet métier de premier ordre » | Fait : deux appareils par foyer, un seul en séance, garanti en base | ADR-010 |
| « Les disponibilités portent un fuseau, la base travaille en UTC » | Fait, et le piège a déjà coûté cher : `instant_creneau()` datait sa semaine par fuseau, sept jours d'écart pour le même rendez-vous | ADR-017, `etape-4-journal.md` L8 |
| « Le dashboard admin est un centre d'intervention, pas un tableau analytique » | Fait : cinq signaux, chacun mène directement à son écran d'action | `ADM-01`, `parcours-utilisateurs.md` |
| « Pas de Text-to-SQL pour l'agent IA » | Sans objet en MVP-0 : il n'y a pas d'agent IA dans le périmètre | ADR-003 |
| « Messagerie contextuelle, pas un chat générique » | **Pas encore construit, et pas encore spécifié.** Inscrit au registre des questions ouvertes pour que le premier écran de messagerie ne parte pas en chat générique | `decisions.md`, question 18 |
| « Modèle d'événements explicite » | Partiel : `audit_logs` existe et est alimenté, la liste nommée des événements n'est pas figée | `decisions.md`, question 19 |

## 8. Ce que la refonte change vraiment

Trois choses, et elles sont toutes dans `01-systeme-visuel.md` :

1. **Le fond général passe du rose poussiéreux au crème**, et cesse d'être la
   seule surface du produit. Trois surfaces au lieu d'une, avec une échelle
   d'élévation.
2. **Les couleurs de marque cessent d'être posées en aplats saturés.** Chaque
   famille reçoit une teinte douce et une encre foncée, de la même teinte. Un
   avertissement devient un fond ambre pâle avec du texte brun, pas un pavé
   `#FFB703`.
3. **La typographie française change**, l'arabe ne change pas.

La palette de marque, elle, est **conservée** : les cinq couleurs d'origine sont
toutes encore là, avec leurs rôles précisés. Aucune teinte nouvelle n'est
introduite.

## 9. Ordre de travail

La note de refonte proposait dix étapes. Six d'entre elles sont ce dossier, et
elles sont faites. L'ordre restant :

```
[fait] Audit du code et des specs existantes
[fait] Architecture des rôles et de l'information   03
[fait] Système visuel                                01
[fait] Système de composants                         07
[fait] Système de mouvement                          04
[fait] Système responsive et web                     05
[fait] Catalogue d'écrans                            08
[à faire] Lot T : jetons, thème, typographie          → lib/core/theme/
[à faire] Lot C : composants du catalogue             → lib/core/widgets/
[à faire] Lot R : reprise des écrans déjà construits  → lib/features/
```

Le lot T se fait en premier et se fait **entièrement** : reprendre les écrans
avant les jetons obligerait à les reprendre deux fois.
