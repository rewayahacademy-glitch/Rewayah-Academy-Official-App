# 00 — Bible Frontend V2 (contrat)

> **Statut : NORME OBLIGATOIRE DU FRONTEND, adoptée le 11 septembre 2026(ADR-019).**
> Source : `D:\RA _APP\docs de lancement\REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`,
> version 2.0, remise par l'opérateur comme deuxième et dernière passe de refonte
> après que le rendu mobile déployé ait été jugé « plus nul que du générique ».
>
> **Ce fichier est la copie intégrale et inchangée du texte reçu.** Il devient le
> document 0 du corpus `docs/design/` : lu avant `README.md`. La table de
> correspondance chapitre par chapitre — ce qui est déjà couvert, ce qui est
> tranché autrement pour une raison écrite, ce qui reste un écart ouvert et dans
> quel lot il se ferme — vit dans `README.md` section 9, pas ici : ce fichier ne
> se réécrit jamais, la correspondance évolue au fil des lots.
>
> Trois couches portent ce contrat, de la plus faible à la plus forte : la
> mémoire d'agent (ne survit qu'à une session Claude Code), les documents
> versionnés de ce dossier plus `CLAUDE.md` et `decisions.md` (survivent au
> changement d'outil : OpenCode, Hermes et Jules lisent le dépôt, pas la mémoire
> de Claude Code), et les règles machine de `tool/verifier_jetons.dart` plus les
> suites de tests (survivent à l'inattention — c'est la seule couche qui empêche
> au lieu de demander). Un chapitre outillable qui resterait seulement documenté
> est un chapitre qui finira par être violé.

---

# REWAYAH — FRONTEND / UI/UX / INTERACTION BIBLE V2
## Contrat d'exécution pour Claude Code — Flutter, Android, iOS, Web/Desktop

**Version:** 2.0
**Statut:** NORME OBLIGATOIRE DU FRONTEND
**Nature:** Design System + UX Governance + Interaction Contract + Adaptive Product Experience
**Application:** Rewayah
**Stack cible:** Flutter cross-platform
**Agent d'exécution:** Claude Code

---

# 0. STATUT ET AUTORITÉ DU DOCUMENT

Ce fichier est un **contrat d'exécution frontend**.

Claude Code doit considérer les règles de cette Bible comme des contraintes obligatoires pour toute décision frontend, UI, UX, interaction, responsive et présentation des données.

## 0.1 Hiérarchie des sources de vérité

L'ordre de priorité est :

1. Contraintes de sécurité, conformité et confidentialité.
2. Spécifications métier officielles existantes de Rewayah.
3. Contrats backend/API/data models existants.
4. Présente Bible Frontend V2 pour toute décision d'expérience utilisateur et d'implémentation UI.
5. Design tokens, composants et conventions déjà présents dans le projet.
6. Documentation officielle Flutter / Material 3 / standards d'accessibilité.
7. Préférence utilisateur explicite validée dans le projet.
8. Jamais une intuition personnelle de Claude.

**Règle absolue :** si une spécification métier existante contredit une préférence visuelle, la règle métier prévaut.

**Règle absolue :** Claude ne doit jamais inventer une règle métier absente des spécifications. Il doit cependant appliquer les meilleures pratiques UX reconnues pour représenter correctement cette règle.

## 0.2 Interdiction d'improvisation

Claude ne doit jamais, sans justification et validation appropriée :

- supprimer une capacité métier ;
- masquer une action critique ;
- fusionner deux fonctions différentes pour « simplifier » ;
- changer la hiérarchie d'une information métier ;
- remplacer un composant partagé existant par un composant local ;
- inventer une couleur ;
- inventer un spacing ;
- inventer une taille de texte ;
- inventer un comportement de navigation ;
- inventer une stratégie responsive ;
- créer un nouveau pattern lorsque le design system possède déjà un pattern équivalent.

**Simplifier signifie réduire la charge cognitive, pas supprimer des fonctionnalités.**

## 0.3 Obligation de justification

Chaque dérogation doit être documentée dans le code ou le journal de décision :

- règle concernée ;
- raison de la dérogation ;
- impact ;
- alternative écartée ;
- portée exacte de l'exception.

Aucune exception silencieuse.

---

# 1. NORTH STAR UX DE REWAYAH

Rewayah est une application d'apprentissage du Coran et de gestion pédagogique dont le noyau d'expérience repose sur deux piliers :

1. **Classe en direct**
   - visioconférence ;
   - outils pédagogiques pour l'enseignant ;
   - document partagé interactif ;
   - Coran intégré nativement ;
   - bibliothèque documentaire ;
   - synchronisation des actions de l'enseignant avec les élèves.

2. **Présence et assiduité**
   - détection et gestion des états de présence ;
   - absence ;
   - retard ;
   - déconnexion / reconnexion ;
   - finalisation ;
   - historique et représentation pédagogique claire.

## 1.1 Principe de priorité

Dans une séance de cours :

**Contenu pédagogique primaire > contrôle pédagogique > chrome UI > configuration secondaire.**

Dans le lecteur Coran :

**Coran > focus de l'enseignant > navigation documentaire > contrôles secondaires.**

Dans la présence :

**État actuel > compréhension de l'état > justification > historique > configuration.**

---

# 2. USER ROLES ET CAPABILITIES

Claude doit utiliser les rôles définis par les spécifications existantes. Ne jamais déduire un rôle uniquement à partir de l'UI.

L'autorisation finale provient du système d'autorisation métier.

## 2.1 Principes

Un rôle n'est pas une permission unique.

Une capability peut dépendre simultanément de :

- rôle ;
- âge ;
- contexte de séance ;
- statut du compte ;
- statut de la session ;
- permissions de la classe ;
- permissions du document ;
- politique de confidentialité ;
- état réseau ;
- état du média.

## 2.2 UX adaptée aux rôles

L'interface doit être adaptée au besoin du rôle sans dupliquer inutilement le système de routage.

### Enfant

Priorité :

- lisibilité ;
- cibles tactiles très grandes ;
- faible densité ;
- forte réduction du chrome ;
- audio / feedback ;
- orientation pédagogique ;
- navigation minimale.

### Élève adulte

Priorité :

- lecture ;
- suivi de cours ;
- progression ;
- autonomie ;
- reprise rapide ;
- accès aux documents.

### Tuteur / parent

Priorité :

- visibilité ;
- progression ;
- cours ;
- présence ;
- informations essentielles.

### Enseignant

Priorité :

- contrôle du cours ;
- document partagé ;
- gestion des apprenants ;
- présence ;
- communication ;
- efficacité opérationnelle.

### Admin

Priorité :

- densité maîtrisée ;
- recherche ;
- tableaux ;
- filtres ;
- actions massives ;
- gestion avancée.

---

# 3. ARCHITECTURE D'INFORMATION

La structure des écrans doit être définie avant leur codage.

## 3.1 Chaque écran doit appartenir à un domaine fonctionnel

Exemples de domaines :

- Authentification ;
- Accueil / Dashboard ;
- Cours ;
- Classe en direct ;
- Bibliothèque ;
- Lecteur ;
- Progression ;
- Présence ;
- Profil ;
- Paramètres ;
- Administration.

Les spécifications existantes sont l'autorité pour le nommage final et l'arbre complet des écrans.

## 3.2 Data vs configuration

Ne jamais mélanger dans une même zone :

- données fréquemment consultées ;
- préférences ;
- configuration ;
- administration ;
- actions destructives.

### Données

Doivent vivre dans :

- écran de contenu ;
- dashboard ;
- page métier ;
- cartes / listes ;
- panneaux contextuels.

### Préférences

Doivent vivre dans :

- Profil ;
- Paramètres ;
- sous-pages de configuration.

### Filtres de contexte

Doivent rester proches du contenu qu'ils filtrent.

### Actions critiques

Doivent être proches de l'objet concerné ou dans un menu d'actions contextuel, avec confirmation adaptée si nécessaire.

---


# 3 BIS. ROUTAGE ET CONTINUITÉ DE SESSION

Le projet utilise un système de routage déclaratif cohérent, idéalement centralisé dans un routeur unique déjà défini par l'architecture du projet.

Ne pas créer plusieurs systèmes de navigation concurrents.

Les règles d'authentification, d'autorisation, de rôle et d'état du compte doivent être appliquées au niveau approprié du routage et des guards existants.

Ne jamais considérer la seule présence d'un token comme suffisante pour autoriser l'accès à une destination.

Les routes de salle de cours en direct qui sont définies comme éphémères par les spécifications ne doivent pas devenir des destinations partageables ordinaires.

Une sortie de session ne doit pas provoquer une perte silencieuse du contexte restaurable.

# 4. ARCHITECTURE DE NAVIGATION

## 4.1 Principe adaptatif

La navigation ne doit pas être déterminée par `Platform.isAndroid`, `Platform.isIOS` ou `isTablet` seuls.

Le layout doit être déterminé par **l'espace disponible**.

Le pattern de navigation doit pouvoir passer d'une NavigationBar à une NavigationRail ou à une navigation latérale lorsque l'espace augmente.

## 4.2 Mobile

Pour les destinations de haut niveau réellement prioritaires :

- NavigationBar / Bottom Navigation ;
- nombre de destinations limité ;
- ordre stable ;
- destination active clairement identifiable.

Ne jamais mettre dans la navigation principale :

- une préférence ;
- une option rare ;
- une fonction administrative isolée ;
- une action ponctuelle ;
- un réglage système.

## 4.3 Tablet

Utiliser une navigation plus persistante lorsque la largeur le justifie :

- NavigationRail ;
- rail étendu si pertinent ;
- contenu principal conservé comme zone dominante.

## 4.4 Desktop/Web

Utiliser selon le contexte :

- NavigationRail ;
- navigation latérale ;
- sidebar persistante ;
- top-level destinations.

Le menu ne doit pas réduire inutilement l'espace accordé au contenu principal.

---

# 5. CONTAINER DECISION MATRIX

Claude doit choisir le conteneur en fonction de la nature de l'action.

## 5.1 Page complète

Utiliser une page lorsque :

- l'information constitue un objectif principal ;
- l'utilisateur doit se concentrer ;
- la tâche est multi-étapes ;
- la tâche a besoin de navigation propre ;
- le contenu doit être partageable / restaurable / deep-linkable ;
- le contenu exige un grand espace vertical ou horizontal.

Exemples :

- profil détaillé ;
- bibliothèque ;
- lecteur ;
- historique de présence ;
- paramètres complexes.

## 5.2 Bottom Sheet

Utiliser une Bottom Sheet lorsque :

- le contexte courant doit rester visible ;
- l'utilisateur sélectionne ou ajuste quelque chose temporairement ;
- la tâche est courte ;
- la sélection s'applique immédiatement ou quasi immédiatement.

Exemples :

- filtres simples ;
- options d'affichage ;
- sélection courte ;
- actions secondaires.

## 5.3 Dialog

Utiliser un Dialog lorsque :

- l'action est critique ;
- la confirmation doit être explicite ;
- l'information exige l'attention immédiate ;
- le contexte ne peut pas attendre ;
- l'utilisateur doit faire un choix avant de continuer.

Éviter les Dialogs pour les tâches longues.

## 5.4 Menu / Popup contextuel

Utiliser un menu contextuel pour :

- actions secondaires ;
- options simples ;
- actions peu fréquentes ;
- choix contextuels attachés à un objet.

## 5.5 Card / Progressive Disclosure

Utiliser une Card extensible pour :

- détails secondaires ;
- informations optionnelles ;
- explications ;
- historique ;
- données supplémentaires dont la lecture n'est pas indispensable immédiatement.

## 5.6 Interdictions

Ne pas utiliser :

- un Dialog comme page miniature ;
- une Bottom Sheet pour une tâche complexe ;
- une Card pour cacher une capacité critique ;
- un dropdown pour remplacer un processus multi-étapes ;
- un écran entier pour une action ponctuelle triviale.

---

# 6. ZONING PHYSIQUE

Chaque écran doit être cartographié avant implémentation.

## 6.1 Zone AppBar / Header

Autorisé :

- navigation ;
- contexte ;
- titre ;
- action primaire ;
- action contextuelle ;
- identité ;
- statut bref.

Interdit :

- formulaires complexes ;
- longues listes ;
- plusieurs actions critiques concurrentes ;
- informations secondaires massives.

## 6.2 Zone de contenu principal

Doit contenir l'objet principal de la tâche.

Le contenu primaire doit avoir la plus grande priorité visuelle.

## 6.3 Zone secondaire

Peut contenir :

- metadata ;
- informations auxiliaires ;
- outils secondaires ;
- navigation contextuelle.

## 6.4 Zone d'action basse

Autorisé :

- action primaire persistante si nécessaire ;
- CTA contextuel ;
- navigation secondaire.

Ne pas y empiler toutes les actions disponibles.

## 6.5 Desktop à deux ou trois panneaux

Quand l'espace le permet :

```text
Navigation | Contenu primaire | Contexte / outils
```

Le panneau de contexte doit rester secondaire.

---

# 7. DESIGN TOKENS — RÈGLE ABSOLUE

## 7.1 Aucun hardcoding visuel dans les widgets

Interdit dans les écrans et composants métier :

- `Color(0xFF...)` ;
- HEX ;
- RGB manuel ;
- `fontSize: ...` arbitraire ;
- `fontWeight: ...` arbitraire ;
- spacing arbitraire ;
- radius arbitraire ;
- shadow arbitraire.

Les valeurs primitives doivent vivre dans les foundations / theme / token layer.

## 7.2 Couleurs

Utiliser prioritairement :

```dart
Theme.of(context).colorScheme
```

et les rôles sémantiques du thème.

Exemples de rôles :

- primary ;
- onPrimary ;
- primaryContainer ;
- onPrimaryContainer ;
- secondary ;
- onSecondary ;
- surface ;
- onSurface ;
- surfaceContainer* ;
- outline ;
- error ;
- onError.

Les couleurs métier supplémentaires doivent être exposées via un thème contrôlé, par exemple `ThemeExtension`, et jamais comme constantes locales dispersées.

## 7.3 Light et Dark

Il doit exister un véritable :

- `lightTheme` ;
- `darkTheme`.

Aucun composant ne doit connaître directement la palette Light ou Dark.

Le composant demande un rôle sémantique.

### Interdictions

- fond sombre dans un composant supposé neutre ;
- texte clair codé en dur ;
- shadow importée d'un ancien thème ;
- opacity arbitraire répétée partout ;
- contraste différent selon la page sans justification.

## 7.4 Tonalités et états

Les états :

- default ;
- hover ;
- focus ;
- pressed ;
- selected ;
- dragged ;
- disabled ;
- loading ;
- error ;
- success

doivent être dérivés du système de thème / composants.

---

# 8. TYPOGRAPHIE

La typographie passe par `TextTheme`.

Utiliser les rôles sémantiques plutôt que des tailles arbitraires :

- display ;
- headline ;
- title ;
- body ;
- label.

Exemples :

- titre de page → rôle headline approprié ;
- titre de section → rôle title ;
- corps → rôle body ;
- bouton → rôle label.

Toute exception doit être justifiée au niveau du composant design system.

---

# 9. SPACING, GRID ET DENSITÉ

Le système doit utiliser une échelle cohérente de spacing.

Base recommandée :

- 4 ;
- 8 ;
- 12 ;
- 16 ;
- 20 ;
- 24 ;
- 32 ;
- 40 ;
- 48 ;
- 64.

Claude ne doit pas créer systématiquement des valeurs telles que 13, 17, 19 ou 27 sans nécessité documentée.

Le spacing doit être basé sur le rôle :

- padding de page ;
- gap entre sections ;
- gap entre composants ;
- padding interne ;
- densité de tableau.

La densité doit diminuer lorsque l'utilisateur est un enfant ou lorsque la lisibilité prime.

---

# 10. SHAPE SYSTEM

Les formes doivent venir du système de thème / composant.

Utiliser les niveaux M3 de manière cohérente :

- ExtraSmall ;
- Small ;
- Medium ;
- Large ;
- ExtraLarge ;
- Full lorsque pertinent.

Ne pas utiliser un même rayon pour toute l'application.

## 10.1 Principes

- champs et petits contrôles → shapes petits ;
- cards → shapes intermédiaires ;
- surfaces immersives / dialogs / sheets → shapes plus grands ;
- avatar → shape full ;
- composants critiques → forme stable et prévisible.

## 10.2 M3 Expressive

L'expressivité est un accent, pas une obligation universelle.

Plus expressive :

- interfaces enfants ;
- moments pédagogiques ;
- cartes de progression ;
- surfaces de découverte.

Plus sobre :

- tableaux ;
- paramètres ;
- administration ;
- paiement ;
- actions destructives ;
- workflows à forte charge cognitive.

Une forme expressive ne doit jamais réduire :

- lisibilité ;
- affordance ;
- accessibilité ;
- cohérence ;
- densité utile.

---

# 11. COMPOSANTS ET RÉUTILISATION

Avant de créer un widget :

1. rechercher s'il existe déjà dans le projet ;
2. rechercher un composant M3 standard approprié ;
3. vérifier les composants partagés ;
4. seulement ensuite proposer une extension.

Un composant métier réutilisable doit être créé au niveau approprié.

Exemple de hiérarchie :

```text
Foundations
  ↓
Primitives
  ↓
Components
  ↓
Patterns
  ↓
Feature Components
  ↓
Screens
```

Ne pas enfouir du design system dans une page unique.

---


# 11 BIS. BIBLIOTHÈQUE DE COMPOSANTS PARTAGÉS EXISTANTS

Lorsque les composants suivants existent dans le projet, ils doivent être considérés comme les implémentations de référence et réutilisés avant toute création locale :

- `Pressable` : interaction standard de type tap/click ;
- `BentoTile` : conteneurs / grilles lorsque le pattern Bento fait partie du design system ;
- `ChoiceCardGroup` : choix structurés lorsque prévu par les spécifications ;
- `AudioLabel` : interfaces enfant nécessitant une aide audio ou une lecture accessible ;
- `PermanentNotice` : notices persistantes lorsqu'elles sont requises par la spécification ;
- `AvatarTile` : représentation d'identité avec fallback approprié.

Claude doit vérifier les interfaces réelles de ces composants avant de les utiliser.

## Pressable

Pour les interactions utilisateur ordinaires, `Pressable` doit remplacer les implémentations ad hoc par `GestureDetector` ou `InkWell` lorsque sa responsabilité couvre le même besoin.

Les comportements de scale, feedback tactile, focus, hover et pressed doivent rester centralisés dans le composant partagé.

Le haptic feedback ne doit pas être forcé sur toutes les plateformes ni sur toutes les interactions. Il doit respecter le composant, la plateforme et l'accessibilité.

`GestureDetector` reste acceptable pour une interaction gestuelle qui n'est pas sémantiquement un bouton ou une action pressable standard : dessin, geste de navigation, interaction pointer/drag ou autre cas explicitement justifié.

## BentoTile

Ne pas utiliser Bento comme décoration universelle.

Les variantes et gaps doivent respecter le design system existant.

## ChoiceCardGroup

Utiliser ce pattern lorsque plusieurs choix doivent être présentés comme décisions de produit ou de configuration.

Ne pas transformer un choix simple en formulaire inutilement complexe.

## AudioLabel

Pour les interfaces enfant, le recours à des libellés / aides audio doit suivre les besoins réels du produit et les règles d'accessibilité.

## PermanentNotice

Si une notice est définie comme permanente par les spécifications, ne pas ajouter au niveau UI une logique locale permettant de la supprimer arbitrairement.

## AvatarTile

Les données privées et les URLs sensibles doivent suivre les règles de sécurité du backend et du projet.

# 12. ÉTATS D'INTERACTION

Tout composant interactif doit prévoir les états pertinents :

- default ;
- hovered ;
- focused ;
- pressed ;
- selected ;
- disabled ;
- loading ;
- error ;
- success ;
- unavailable.

L'état doit être perceptible :

- visuellement ;
- sémantiquement ;
- au clavier ;
- au lecteur d'écran lorsque pertinent.

---

# 13. ACCESSIBILITÉ

L'accessibilité est une contrainte fonctionnelle.

## 13.1 Cibles

Minimum général adulte recommandé : 44 logical pixels / points selon le contexte.

Mode enfant : utiliser des cibles sensiblement plus grandes lorsque cela améliore la sécurité d'interaction.

La taille réelle doit rester compatible avec les contraintes du composant, du système et du device.

## 13.2 Text scaling

L'interface doit survivre à un agrandissement du texte.

Interdit :

- hauteur fixe fragile ;
- texte coupé ;
- overflow masqué pour « faire tenir » ;
- boutons non adaptatifs.

## 13.3 Semantics

Chaque contrôle important doit avoir :

- nom accessible ;
- rôle clair ;
- état ;
- valeur lorsque pertinente ;
- action compréhensible.

## 13.4 Clavier

Web/Desktop :

- ordre de focus cohérent ;
- focus visible ;
- navigation clavier ;
- Escape pour sortir des surfaces modales lorsque pertinent ;
- piège de focus correctement géré dans les Dialogs ;
- raccourcis cohérents.

## 13.5 Motion

Respecter les préférences de réduction de mouvement lorsque disponibles.

Une animation ne doit jamais être requise pour comprendre une information critique.

---

# 14. RTL / L10N / I18N

Rewayah doit être structurellement capable de gérer RTL et LTR.

Interdit lorsque le comportement peut être directionnel :

- `left` / `right` codés en dur ;
- icônes directionnelles non adaptées ;
- ordre des contrôles non réfléchi en RTL.

Préférer :

- start / end ;
- `EdgeInsetsDirectional` ;
- `AlignmentDirectional` ;
- comportements conscients de la direction.

Tester au minimum :

- arabe ;
- français ;
- anglais.

Prévoir les textes plus longs, nombres, dates, heures, pluriels et contenus mixtes arabe/latin.

---

# 15. RESPONSIVE / ADAPTIVE SYSTEM

Le layout est déterminé par l'espace disponible.

## 15.1 Principes

Le responsive doit adapter :

- navigation ;
- nombre de colonnes ;
- largeur du contenu ;
- densité ;
- disposition des panneaux ;
- visibilité des outils secondaires ;
- taille des Dialogs ;
- position des contrôles.

## 15.2 Largeurs

Utiliser des familles de largeurs plutôt qu'une logique rigide de device :

- compact ;
- medium ;
- expanded ;
- large / extra-large selon les besoins du produit.

Les seuils exacts doivent être centralisés dans une configuration du design system et jamais dupliqués dans les pages.

## 15.3 Content max width

Sur desktop, ne pas étirer indéfiniment le contenu de lecture ou les formulaires.

Utiliser des largeurs maximales cohérentes.

---

# 16. MOTION

Les transitions doivent :

- indiquer la relation spatiale ;
- confirmer une action ;
- révéler une conséquence ;
- réduire l'incertitude.

Éviter les animations décoratives répétitives.

Les animations critiques doivent être :

- courtes ;
- cohérentes ;
- interruption-safe ;
- accessibles.

---

# 17. NOTIFICATIONS ET FEEDBACK

## SnackBar

Pour :

- feedback bref ;
- confirmation non critique ;
- résultat d'une action ;
- information temporaire.

## Banner

Pour :

- problème contextuel persistant ;
- information importante nécessitant visibilité ;
- état réseau ;
- état système affectant plusieurs actions.

## Badge

Pour :

- contenu non lu ;
- compteurs ;
- statut nécessitant une attention légère.

## Dialog

Pour :

- confirmation critique ;
- action destructive ;
- interruption nécessaire.

Ne pas utiliser un SnackBar pour une information que l'utilisateur doit obligatoirement voir et comprendre.

---


# 17 BIS. FEEDBACK TACTILE ET INTERACTION MULTI-PLATEFORME

Le feedback tactile est une capacité adaptative.

Règles :

- ne pas supposer qu'un haptic existe sur Web/Desktop ;
- ne pas imposer une intensité uniforme à toutes les actions ;
- réserver les feedbacks tactiles forts aux actions qui bénéficient réellement d'une confirmation ;
- ne pas utiliser l'haptique comme substitut à une information visuelle ou sémantique ;
- respecter les différences de plateforme.

# 18. EMPTY / LOADING / ERROR / OFFLINE

Chaque écran métier doit définir :

- normal ;
- loading ;
- empty ;
- error ;
- degraded/offline lorsque pertinent.

## Empty

Doit expliquer :

1. ce qui manque ;
2. pourquoi c'est vide ;
3. ce que l'utilisateur peut faire.

Inclure une action primaire lorsque pertinente.

## Loading

Utiliser un skeleton fidèle à la structure réelle de l'écran lorsqu'une attente substantielle est attendue.

Éviter le spinner seul au centre pour tout le contenu.

## Error

Une erreur doit être récupérable lorsque possible.

Afficher :

- problème compréhensible ;
- conséquence ;
- action de récupération ;
- détails techniques seulement si nécessaires.

## Offline

Ne pas désactiver arbitrairement toute navigation.

Les fonctions réseau peuvent :

- se mettre en attente ;
- utiliser un cache ;
- afficher leur dégradation ;
- demander une reconnexion.

Toutes les opérations mises en file doivent respecter les règles métier d'idempotence et de cohérence.

---

# 19. LIVE CLASSROOM — MODÈLE UX

La salle de cours n'est pas un écran vidéo ordinaire.

Elle est composée de sous-systèmes :

```text
Live Session
├── Media
├── Shared Document Stage
├── Teacher Controls
├── Attendance
├── Participant Context
└── Session State
```

Chaque sous-système doit pouvoir se dégrader indépendamment lorsque techniquement possible.

Exemples :

- vidéo indisponible → document encore utilisable ;
- document indisponible → vidéo encore utilisable ;
- connexion faible → afficher la dégradation sans détruire les fonctions locales ;
- reconnexion → restaurer l'état cohérent.

---

# 20. LIVE CLASSROOM — HIÉRARCHIE VISUELLE

## Mobile portrait

Priorité :

1. média actif selon le contexte ;
2. contenu partagé / pédagogique ;
3. action essentielle ;
4. contrôles secondaires.

Ne jamais laisser une toolbar permanente couvrir une zone importante du Coran.

## Mobile landscape

Autoriser une disposition plus riche :

- vidéo ;
- document ;
- contrôles contextuels.

## Tablet

Permettre un véritable split lorsque l'espace le permet.

## Desktop

Pattern privilégié :

```text
┌──────────────┬──────────────────────────────┐
│              │                              │
│ VIDEO /      │     SHARED DOCUMENT STAGE   │
│ TEACHER TOOLS│                              │
│              │                              │
├──────────────┴──────────────────────────────┤
│ SESSION / CONTROLS / PARTICIPANTS           │
└─────────────────────────────────────────────┘
```

L'implémentation exacte dépend des contraintes techniques et des spécifications existantes.

---

# 21. SHARED DOCUMENT STAGE

Le document partagé est un **espace pédagogique interactif**, pas un simple fichier affiché.

Il doit être traité comme un sous-système possédant son propre état.

Nom architectural recommandé :

`SharedDocumentStage`

## 21.1 Fonctionnalités attendues

Le stage doit pouvoir gérer selon les spécifications :

- document courant ;
- type de document ;
- bibliothèque ;
- page ;
- verset ;
- focus ;
- pointer ;
- annotation éventuelle ;
- zoom ;
- navigation précédente / suivante ;
- mode page ;
- mode focus ;
- mode immersif.

## 21.2 Priorité

Le document devient le **contenu primaire** lorsque la pédagogie de la séance porte sur celui-ci.

---

# 22. READER IMMERSIVE MODE

Le mode immersif est obligatoire pour les expériences de lecture où le document constitue la tâche principale, particulièrement sur mobile.

## 22.1 Règle fondamentale

Le Coran ne doit pas être traité comme une petite Card entourée de contrôles.

En mode lecture :

```text
CONTENT > CHROME
```

## 22.2 Mobile

Le mode immersif doit pouvoir utiliser presque toute la surface disponible.

Les contrôles secondaires :

- se masquent ;
- peuvent être révélés par une interaction familière ;
- n'obstruent pas durablement le texte.

## 22.3 Contrôles visibles

Lorsqu'ils sont révélés :

- retour ;
- position ;
- navigation minimale ;
- action liée au contexte ;
- bouton de sortie du mode immersif si nécessaire.

Les contrôles avancés doivent être secondaires et ne doivent pas rester superposés au texte en permanence.

## 22.4 Desktop

Les contrôles peuvent être plus persistants lorsque l'espace le permet.

---

# 23. QURAN READER — PRINCIPE STRUCTUREL

Le Coran intégré dans Rewayah ne doit pas être modélisé comme un PDF.

Il doit être traité comme un contenu structuré :

```text
Quran
├── Mushaf
├── Edition / Script
├── Chapter
├── Juz
├── Page
├── Verse
├── Word
└── Layout Metadata
```

La couche UI ne doit pas dépendre d'un fichier PDF.

Le rendu doit être découplé du modèle de données.

## 23.1 Mushaf / pagination

La pagination dépend du Mushaf choisi.

Le système doit conserver la relation entre :

- Mushaf ;
- page ;
- verset ;
- éventuellement ligne / mot.

Les références externes sur les APIs Quran montrent notamment que plusieurs Mushafs disposent de mappings page/verset différents et que certaines représentations sont conçues pour obtenir un rendu fidèle du Mushaf.

---

# 24. QURAN READER — ÉTATS PERSONNELS VS PARTAGÉS

Cette distinction est obligatoire.

## 24.1 Shared Classroom State

Exemples :

- document sélectionné par l'enseignant ;
- page présentée ;
- verset ciblé ;
- focus pédagogique ;
- pointer ;
- annotation partagée ;
- mode d'affichage pédagogique.

## 24.2 Student Personal State

Exemples :

- dernière position de lecture ;
- page personnelle ;
- verset personnel ;
- scroll offset si pertinent ;
- zoom personnel ;
- préférences de lecture ;
- dernier point confirmé.

## 24.3 Règle critique

Une action partagée de l'enseignant ne doit pas détruire silencieusement le progrès personnel de l'élève.

---

# 25. TEACHER FOLLOW MODE

L'élève doit pouvoir suivre la position de l'enseignant lorsque le cours l'exige.

État recommandé :

`FOLLOWING_TEACHER`

Lorsque l'élève quitte temporairement cette position :

`FOLLOWING_TEACHER` → `STUDENT_EXPLORING`

L'UI doit alors pouvoir proposer :

`Retour au point de l'enseignant`

Lorsque l'élève utilise cette action :

`STUDENT_EXPLORING` → `FOLLOWING_TEACHER`

Ne pas imposer une téléportation silencieuse si cela détruit l'action locale de l'élève.

---

# 26. TEACHER DOCUMENT CONTROLS

Les outils doivent être organisés selon la fréquence d'usage.

## Niveau 1 — contrôle pédagogique immédiat

- page précédente ;
- page suivante ;
- aller à une page ;
- pointer / focus ;
- affichage approprié.

## Niveau 2 — interaction pédagogique

- verse focus ;
- annotation si supportée ;
- mode de lecture ;
- affichage détaillé.

## Niveau 3 — configuration

- préférences ;
- édition ;
- options avancées.

## Règle

Le professeur ne doit jamais avoir besoin d'ouvrir trois menus pour effectuer une action qu'il répète toutes les minutes.

Inversement, les outils rares ne doivent pas saturer la barre principale.

---

# 27. RESUME / RESTAURATION DE POSITION

La reprise de lecture est une fonctionnalité de premier ordre.

Le système doit distinguer :

- document ouvert ;
- document réellement consulté ;
- dernière position confirmée.

Une position peut comprendre :

```text
document_id
edition_id
mushaf_id
page_number
chapter_number
verse_number
word_position lorsque pertinent
scroll_offset lorsque pertinent
zoom_level
timestamp
```

L'état exact dépend du modèle métier existant.

## 27.1 Règle de restauration

À la prochaine ouverture :

1. restaurer le contexte documentaire ;
2. restaurer la position ;
3. restaurer les préférences compatibles ;
4. afficher un accès explicite à la reprise ;
5. éviter de réinitialiser inutilement l'utilisateur à la première page.

---

# 28. RESUME UX

La reprise doit pouvoir être exposée directement dans les points d'entrée appropriés :

```text
Continuer
Sourate ...
Page ...
Verset ...
[Reprendre]
```

Ne pas cacher une fonction aussi fréquente dans Paramètres.

---

# 29. ATTENDANCE UX

Les règles métier d'assiduité existantes sont l'autorité.

La Bible impose principalement leur **représentation UX**.

## 29.1 États possibles à représenter

Selon le moteur métier, une UX robuste peut devoir représenter des états tels que :

- scheduled ;
- waiting ;
- joining ;
- present ;
- late ;
- disconnected ;
- reconnecting ;
- reconnected ;
- left ;
- absent ;
- excused ;
- pending confirmation ;
- manually overridden ;
- finalized.

Ne jamais inventer ou supprimer un état métier existant.

## 29.2 Machine à états

L'interface doit représenter les transitions, pas seulement une couleur finale.

Exemple :

```text
Present
  ↓
Network lost
  ↓
Reconnecting
  ↓
Reconnected
  ↓
Present
```

## 29.3 Information de contexte

Quand une information est nécessaire à la compréhension de l'état, présenter :

- état actuel ;
- heure utile ;
- contexte ;
- action possible ;
- historique lorsque nécessaire.

Une simple couleur ne doit jamais être l'unique représentation d'un état critique.

---

# 30. ATTENDANCE — ENSEIGNANT

L'enseignant doit comprendre rapidement :

- qui est présent ;
- qui est en retard ;
- qui est absent ;
- qui a perdu la connexion ;
- ce qui est provisoire ;
- ce qui est finalisé.

Les détails doivent être consultables sans surcharger la vue principale.

---

# 31. ATTENDANCE — ÉLÈVE

L'élève doit comprendre :

- son état ;
- si une reconnexion est nécessaire ;
- si une action est requise ;
- si le cours est encore actif.

Ne pas afficher des détails administratifs inutiles.

---

# 32. GRACEFUL DEGRADATION

Chaque sous-système doit définir son comportement en cas de défaillance.

### Media failure

Conserver autant que possible les fonctions pédagogiques non dépendantes du média.

### Document failure

Conserver la séance et les fonctions indépendantes.

### Attendance service failure

Ne pas présenter un état final faux si la source de vérité n'est pas disponible.

### Network failure

Afficher la dégradation clairement.

### Reconnection

Restaurer l'état métier et visuel autant que possible sans recréer inutilement tout l'écran.

---

# 33. SÉCURITÉ ET CONFIDENTIALITÉ UX

Les données sensibles ne doivent apparaître que dans les contextes autorisés.

Ne pas afficher :

- email ;
- téléphone ;
- données personnelles ;
- métadonnées privées

simplement parce qu'elles sont disponibles dans le backend.

La disponibilité d'une donnée dans une API n'est pas une autorisation d'affichage.

---

# 34. MEDIA UX

Caméra et microphone doivent respecter les politiques métier.

Pour la séance :

- état clair ;
- état off facilement compréhensible ;
- permission système séparée de l'état applicatif ;
- feedback de connexion ;
- récupération lors d'erreur.

Une caméra interdite par policy ne doit pas être simplement « cachée par hasard ».

Le comportement doit être déterministe.

---

# 35. NAVIGATION DANS LA CLASSE

La salle de cours doit protéger la continuité de la session.

Avant de quitter :

- avertir seulement lorsque nécessaire ;
- distinguer navigation temporaire et sortie définitive ;
- préserver les états restaurables ;
- éviter de détruire une session active par un simple tap accidentel.

---

# 36. TASK DEPTH — MAXIMUM 3 ACTIONS LORSQUE LE CONTEXTE LE PERMET

Pour les objectifs fréquents, viser :

```text
Entrée
→ destination
→ action
```

La limite de trois actions n'est pas une excuse pour supprimer des fonctionnalités.

Elle doit être atteinte via :

- bons points d'entrée ;
- contexte ;
- raccourcis ;
- actions primaires ;
- navigation adaptée ;
- progressive disclosure.

Chaque tâche fréquente doit avoir un chemin documenté.

---

# 37. DESIGN DES FORMULAIRES

Éviter les formulaires inutilement longs.

Principes :

- regrouper logiquement ;
- utiliser le bon type de champ ;
- valider au moment approprié ;
- afficher les erreurs près du champ ;
- conserver les valeurs valides ;
- éviter les resets accidentels ;
- utiliser la navigation clavier sur desktop.

---

# 38. TABLES ET DATA-DENSE UI

Pour l'administration :

- hiérarchiser les colonnes ;
- rendre les actions contextuelles ;
- conserver une densité lisible ;
- éviter la couleur comme seul indicateur ;
- prévoir tri et filtres conformément aux spécifications ;
- permettre un affichage adapté aux petits écrans.

Sur mobile, une table desktop ne doit pas être compressée artificiellement en une ligne illisible.

---

# 39. PERFORMANCE PERÇUE

La perception de vitesse est une partie de l'UX.

Obligatoire lorsque pertinent :

- skeleton fidèle ;
- conservation du layout ;
- cache ;
- restauration d'état ;
- pagination ;
- lazy loading ;
- images optimisées ;
- éviter les reconstructions inutiles ;
- ne pas charger tout un catalogue pour afficher un seul élément.

Mais la performance ne doit jamais dégrader la cohérence métier ou l'exactitude du Coran.

---

# 40. ÉTAT UI VS ÉTAT MÉTIER

Chaque state doit être classé.

### Business State

Exemples :

- présence ;
- session ;
- document partagé ;
- droits ;
- progression.

### UI State

Exemples :

- menu ouvert ;
- sheet ouverte ;
- focus visuel ;
- scrollbar ;
- mode compact.

### Personal Preference

Exemples :

- thème ;
- préférence de zoom ;
- préférences de lecture.

Ne pas stocker arbitrairement un état métier dans une variable d'UI locale.

---

# 41. RESTAURATION D'ÉTAT

Lorsqu'une application est interrompue puis reprise, restaurer lorsque pertinent :

- route ;
- session ;
- document ;
- position ;
- sélection ;
- mode d'affichage ;
- formulaire non soumis lorsque sûr.

Ne pas restaurer aveuglément :

- un état expiré ;
- une permission devenue invalide ;
- une session terminée ;
- une action déjà consommée.

---

# 42. ANTI-PARESSE / ANTI-SIMPLIFICATION

Claude doit considérer comme une violation :

> « J'ai simplifié l'écran en retirant cette fonction. »

si la fonction existe dans les spécifications et n'est pas réellement supprimée par une décision produit.

## 42.1 Remplacer la suppression par :

- progressive disclosure ;
- regroupement ;
- toolbar contextuelle ;
- menu secondaire ;
- adaptive layout ;
- mode focus ;
- mode immersif.

## 42.2 Avant de supprimer un élément

Claude doit se demander :

1. Est-il métier ?
2. Est-il critique ?
3. Est-il fréquent ?
4. Existe-t-il déjà ailleurs ?
5. Est-il contextuel ?
6. Peut-il être révélé progressivement ?
7. Son absence casse-t-elle un parcours ?

Si oui, ne pas supprimer sans validation.

---

# 43. ANTI-HALLUCINATION FRONTEND

Claude ne doit jamais inventer :

- une route métier ;
- une permission ;
- un statut ;
- une source de données ;
- une structure de document ;
- une action backend ;
- une règle de présence.

Lorsqu'une information n'est pas connue :

1. rechercher dans les fichiers/specs du projet ;
2. rechercher dans les composants existants ;
3. rechercher les contrats backend existants ;
4. seulement ensuite proposer une hypothèse explicitement marquée ;
5. ne jamais transformer l'hypothèse en règle silencieuse.

---

# 44. PROTOCOLE AVANT CODAGE

Avant d'écrire le code d'un nouvel écran :

## Étape 1 — comprendre

Identifier :

- rôle ;
- objectif ;
- contexte ;
- données ;
- actions ;
- états ;
- contraintes.

## Étape 2 — rechercher

Chercher :

- spec métier ;
- route existante ;
- composant existant ;
- token existant ;
- pattern existant.

## Étape 3 — zoning

Produire textuellement :

```text
SCREEN
├── Header
├── Primary Content
├── Secondary Content
├── Actions
└── Responsive Variants
```

## Étape 4 — interaction

Documenter :

- tap ;
- long press si pertinent ;
- hover ;
- keyboard ;
- focus ;
- loading ;
- error ;
- recovery.

## Étape 5 — validation

Le zoning et le modèle d'interaction doivent être validés avant implémentation lorsqu'une validation utilisateur est prévue dans le workflow.

## Étape 6 — implémentation

Seulement après accord.

---

# 45. COMMENTAIRES DE CONFORMITÉ

Le code doit documenter les décisions structurantes.

Exemple :

```dart
// [M3-COLOR]
// Uses semantic ColorScheme roles.
// No hardcoded color is permitted in feature UI.
//
// [A11Y]
// Focusable control with accessible semantics.
//
// [RESPONSIVE]
// Compact navigation pattern selected from available width.
//
// [QURAN-STAGE]
// Shared document state is separated from personal reading state.
```

Ne pas mettre de longs commentaires évidents partout.

Les commentaires doivent expliquer les règles importantes.

---

# 46. QA GATE — UN ÉCRAN N'EST PAS TERMINÉ TANT QUE

Claude doit vérifier :

## Architecture

- [ ] route correcte ;
- [ ] rôle correct ;
- [ ] bonne source de données ;
- [ ] aucune règle métier inventée.

## Design

- [ ] ColorScheme utilisé ;
- [ ] TextTheme utilisé ;
- [ ] spacing conforme ;
- [ ] shape conforme ;
- [ ] states définis ;
- [ ] aucune couleur hardcodée ;
- [ ] aucune taille arbitraire non justifiée.

## Responsive

- [ ] compact ;
- [ ] medium ;
- [ ] expanded ;
- [ ] orientation pertinente ;
- [ ] desktop ;
- [ ] navigation adaptée.

## Accessibility

- [ ] semantics ;
- [ ] focus ;
- [ ] clavier ;
- [ ] touch targets ;
- [ ] text scaling ;
- [ ] contraste ;
- [ ] reduced motion si pertinent.

## UX

- [ ] empty ;
- [ ] loading ;
- [ ] error ;
- [ ] offline ;
- [ ] recovery ;
- [ ] feedback ;
- [ ] max-depth des tâches fréquentes.

## Dark / Light

- [ ] Light réellement cohérent ;
- [ ] Dark réellement cohérent ;
- [ ] aucun mélange de surfaces ;
- [ ] aucun texte illisible ;
- [ ] aucun composant reposant sur une couleur d'un autre thème.

## États métier

- [ ] états transitoires ;
- [ ] erreurs ;
- [ ] reconnexion ;
- [ ] restauration ;
- [ ] permissions.

---

# 47. QA SPÉCIALE LIVE CLASSROOM

Pour chaque modification de la salle :

- [ ] mobile portrait ;
- [ ] mobile landscape ;
- [ ] tablet ;
- [ ] desktop ;
- [ ] vidéo active ;
- [ ] vidéo indisponible ;
- [ ] document actif ;
- [ ] document indisponible ;
- [ ] réseau faible ;
- [ ] déconnexion ;
- [ ] reconnexion ;
- [ ] enseignant ;
- [ ] élève ;
- [ ] sortie de session ;
- [ ] restauration.

---

# 48. QA SPÉCIALE QURAN READER

Vérifier :

- [ ] vrai contenu structuré ;
- [ ] Mushaf correct ;
- [ ] pagination cohérente ;
- [ ] RTL ;
- [ ] rendu sans PDF ;
- [ ] navigation page ;
- [ ] focus verset ;
- [ ] actions enseignant ;
- [ ] état partagé séparé de l'état personnel ;
- [ ] suivi enseignant ;
- [ ] sortie temporaire du suivi ;
- [ ] retour vers enseignant ;
- [ ] zoom ;
- [ ] mode immersif ;
- [ ] contrôles masquables ;
- [ ] restauration de position ;
- [ ] aucune destruction du progrès personnel par une action partagée.

---

# 49. QA SPÉCIALE ATTENDANCE

Vérifier selon les états définis par le métier :

- [ ] arrivée ;
- [ ] présent ;
- [ ] retard ;
- [ ] déconnexion ;
- [ ] reconnexion ;
- [ ] départ ;
- [ ] absence ;
- [ ] exception ;
- [ ] override ;
- [ ] finalisation.

L'affichage doit rester compréhensible même lorsque plusieurs élèves ont simultanément des états différents.

---

# 50. SELF-REVIEW OBLIGATOIRE DE CLAUDE

Avant de déclarer une feature terminée, Claude doit répondre silencieusement à cette liste :

1. Ai-je utilisé un composant existant ?
2. Ai-je inventé quelque chose ?
3. Ai-je supprimé quelque chose ?
4. Ai-je mis une donnée dans un mauvais endroit ?
5. Ai-je utilisé un hardcode visuel ?
6. Le layout fonctionne-t-il en Light et Dark ?
7. Que se passe-t-il sans données ?
8. Que se passe-t-il pendant le chargement ?
9. Que se passe-t-il si le réseau tombe ?
10. Que se passe-t-il si l'utilisateur revient ?
11. Que se passe-t-il au clavier ?
12. Que voit l'enfant ?
13. Que voit l'enseignant ?
14. Qu'est-ce qui est partagé ?
15. Qu'est-ce qui est personnel ?
16. Le contenu primaire est-il réellement prioritaire ?
17. Ai-je caché une capacité critique ?
18. La tâche fréquente est-elle trop profonde ?
19. Est-ce que le responsive est réellement adaptatif ?
20. Quel scénario d'erreur n'ai-je pas traité ?

---

# 51. PRINCIPLE DE NON-RÉGRESSION

Toute nouvelle feature doit préserver :

- navigation existante ;
- composants partagés ;
- tokens ;
- accessibilité ;
- dark mode ;
- light mode ;
- responsive ;
- état métier ;
- confidentialité ;
- restauration.

Une amélioration visuelle qui casse une fonctionnalité métier est une régression.

---

# 52. RÈGLE DE SOBRIÉTÉ INTELLIGENTE

Le design doit être :

- clair ;
- moderne ;
- expressif lorsque pertinent ;
- professionnel ;
- cohérent ;
- pédagogique.

Mais l'esthétique ne doit jamais prendre le dessus sur :

- exactitude ;
- lisibilité ;
- vitesse d'interaction ;
- compréhension ;
- accessibilité ;
- contenu religieux.

Pour le Coran en particulier :

**le texte et la lisibilité priment sur l'ornement.**

---

# 53. RÈGLE DE VÉRITÉ DU CORAN

Toute représentation du Coran doit privilégier l'exactitude du contenu et du rendu.

Interdit :

- reformater arbitrairement le texte pour « faire joli » ;
- couper un verset de façon ambiguë ;
- modifier le texte ;
- substituer un rendu approximatif lorsque les données fiables existent ;
- utiliser un fichier PDF comme substitut au modèle de contenu structuré lorsque le produit est conçu pour une lecture interactive.

La sélection d'une représentation du Mushaf et de ses ressources doit suivre les spécifications de Rewayah et les sources autorisées du projet.

---

# 54. PRINCIPLE DE CONTINUITÉ PÉDAGOGIQUE

Une action d'interface doit préserver la continuité du cours.

L'enseignant ne devrait pas devoir :

- reconstruire manuellement le contexte ;
- retrouver une page ;
- rechercher un élève ;
- rouvrir un outil complexe

pour une action répétitive.

L'élève doit pouvoir reprendre :

- la session ;
- le document ;
- son point de lecture ;
- son contexte pédagogique

avec un minimum de friction.

---

# 55. PRINCIPLE « PROGRESSIVE DISCLOSURE, NOT PROGRESSIVE HIDING »

Ne pas cacher une fonction simplement pour réduire l'encombrement.

La bonne progression est :

```text
Essentiel
↓
Contextuel
↓
Avancé
```

et non :

```text
Essentiel
↓
Menu
↓
Sous-menu
↓
Sous-menu
↓
Fonction
```

Les fonctions importantes doivent rester découvrables.

---

# 56. DÉCISIONS PAR CONTEXTE — EXEMPLES CANONIQUES

## « L'élève veut lire le Coran »

→ ouvrir le lecteur.

## « L'élève veut seulement ajuster le zoom »

→ contrôle contextuel / sheet appropriée.

## « L'enseignant veut pointer un verset »

→ outil direct dans le contexte de la séance.

## « L'enseignant veut modifier une préférence durable »

→ paramètres ou configuration appropriée.

## « L'utilisateur quitte une session critique »

→ confirmation seulement si une conséquence réelle existe.

## « Aucun cours n'est disponible »

→ Empty State utile, jamais écran blanc.

---

# 57. RÈGLE DE CONTEXTE

Une action doit apparaître là où son contexte est déjà compris.

Exemple :

- action du document → lecteur ;
- action de séance → salle de cours ;
- réglage global → paramètres ;
- préférence de lecture → lecteur ou paramètres selon fréquence ;
- configuration administrative → administration.

Éviter de déplacer une fonction vers un menu global si elle est intrinsèquement contextuelle.

---

# 58. RÈGLE DE COMPATIBILITÉ DES PLATEFORMES

Flutter partage le code, mais l'expérience n'a pas besoin d'être visuellement identique au pixel sur toutes les tailles.

La cohérence recherchée est :

**même modèle mental + même hiérarchie + adaptation de présentation.**

Ne pas forcer le desktop à imiter un téléphone.

Ne pas forcer le téléphone à afficher une UI desktop compressée.

---

# 59. SOURCES ET RÉFÉRENCES DE CONCEPTION

Les décisions doivent être alignées en priorité sur les documentations officielles et standards de référence.

## Flutter

- ThemeData / ColorScheme :
  https://api.flutter.dev/flutter/material/ThemeData-class.html
  https://api.flutter.dev/flutter/material/ThemeData/colorScheme.html
  https://api.flutter.dev/flutter/material/ThemeData/ThemeData.from.html

- Material 3 dans Flutter :
  https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html

- Adaptive / Responsive :
  https://docs.flutter.dev/ui/adaptive-responsive/general
  https://docs.flutter.dev/ui/adaptive-responsive/large-screens

## Material Design

- https://m3.material.io/
- https://m3.material.io/foundations/layout/understanding-layout
- https://m3.material.io/components/navigation-bar/overview
- https://m3.material.io/components/navigation-rail/overview
- https://m3.material.io/foundations/accessible-design/overview

## W3C / WCAG

- https://www.w3.org/TR/WCAG22/
- https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/

## Quran Foundation

- Page Layout :
  https://api-docs.quran.com/docs/tutorials/fonts/page-layout/

- Font Rendering :
  https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/

- Mushaf Fonts and Images :
  https://api-docs.quran.com/legal/mushaf-fonts-and-images/

Ces ressources ne remplacent pas les spécifications officielles de Rewayah.

---

# 60. PROTOCOLE FINAL D'EXÉCUTION

Claude doit suivre cette boucle :

```text
RECEIVE TASK
    ↓
IDENTIFY ROLE
    ↓
IDENTIFY BUSINESS FEATURE
    ↓
SEARCH EXISTING SPECS
    ↓
SEARCH EXISTING COMPONENTS
    ↓
IDENTIFY SOURCE OF TRUTH
    ↓
MODEL BUSINESS STATE
    ↓
MODEL UI STATE
    ↓
DEFINE SCREEN ZONING
    ↓
DEFINE INTERACTIONS
    ↓
DEFINE RESPONSIVE VARIANTS
    ↓
DEFINE EMPTY / LOADING / ERROR / OFFLINE
    ↓
DEFINE ACCESSIBILITY
    ↓
VALIDATE ZONING WHEN REQUIRED
    ↓
IMPLEMENT
    ↓
SELF-REVIEW
    ↓
QA GATE
    ↓
DELIVER
```

## 60.1 Condition de sortie

Une feature frontend est « terminée » uniquement si :

- elle respecte les specs métier ;
- elle respecte cette Bible ;
- elle utilise les composants appropriés ;
- elle gère ses états ;
- elle est responsive ;
- elle fonctionne en Light et Dark ;
- elle respecte l'accessibilité ;
- elle ne détruit pas un état existant ;
- elle n'introduit pas d'improvisation silencieuse ;
- elle a passé la checklist de non-régression.

---

# 61. RÈGLE ULTIME

**Claude est l'implémenteur. Il n'est pas l'autorité produit.**

Son objectif n'est pas de produire le moins de code possible.

Son objectif est de produire la meilleure expérience conforme aux spécifications de Rewayah, au design system, aux standards de plateforme et aux contraintes d'accessibilité, sans supprimer de capacité métier et sans inventer de comportement.

Lorsqu'une interface semble trop complexe, Claude doit chercher à **mieux structurer** avant de chercher à **supprimer**.

Lorsqu'une interface semble trop dense, Claude doit chercher à **adapter la présentation** avant de supprimer une fonctionnalité.

Lorsqu'une interface semble difficile à comprendre, Claude doit chercher à **améliorer la hiérarchie et le contexte** avant de cacher une fonction.

Lorsqu'une décision est ambiguë, Claude doit revenir à la source de vérité, documenter l'incertitude et choisir la solution la plus cohérente avec ce contrat.

**FIN DE LA BIBLE FRONTEND / UI/UX / INTERACTION REWAYAH V2**
